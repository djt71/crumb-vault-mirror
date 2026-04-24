#!/usr/bin/env bash
# approval-respond.sh — Process an approval response (approve/deny)
#
# Source: tess-operations TOP-049 (Approval Contract protocol)
# Spec: tess-chief-of-staff-spec.md §9b
#
# Updates approval status, logs to audit trail, edits original Telegram message
# to reflect the decision, and shows cooldown info for approved items.
#
# Usage:
#   approval-respond.sh AID-xxxxx approve
#   approval-respond.sh AID-xxxxx deny
#
# Output: new status on stdout (approved/denied)
# Exit: 0 on success, 1 on error

set -eu

VAULT_ROOT="/Users/tess/crumb-vault"
BRIDGE_DIR="$VAULT_ROOT/_openclaw"
APPROVALS_DIR="$BRIDGE_DIR/state/approvals"
AUDIT_LOG="$BRIDGE_DIR/logs/approval-audit.log"
LOG_FILE="$BRIDGE_DIR/logs/approval-contract.log"

TELEGRAM_BOT_TOKEN="${TESS_APPROVAL_BOT_TOKEN:-$(security find-generic-password -a tess-bot -s tess-approval-bot-token -w 2>/dev/null || echo "")}"
TELEGRAM_CHAT_ID="7754252365"

# === Args ===
AID="${1:-}"
ACTION="${2:-}"

if [[ -z "$AID" || -z "$ACTION" ]]; then
    echo "Usage: approval-respond.sh AID-xxxxx approve|deny" >&2
    exit 1
fi

case "$ACTION" in
    approve|deny) ;;
    *) echo "ERROR: Action must be 'approve' or 'deny'" >&2; exit 1 ;;
esac

# === Logging ===
log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

audit_log() {
    mkdir -p "$(dirname "$AUDIT_LOG")"
    echo "$1" >> "$AUDIT_LOG"
}

# === Validate approval exists ===
APPROVAL_FILE="$APPROVALS_DIR/$AID.json"
if [[ ! -f "$APPROVAL_FILE" ]]; then
    log "ERROR: $AID not found"
    echo "ERROR: Approval $AID not found" >&2
    exit 1
fi

# === Read current state ===
current_status=$(jq -r '.status' "$APPROVAL_FILE")
if [[ "$current_status" != "pending" ]]; then
    log "WARN: $AID already $current_status — ignoring $ACTION"
    echo "WARN: $AID is already $current_status" >&2
    exit 0
fi

# === Check expiry before processing ===
expires_at=$(jq -r '.expires_at' "$APPROVAL_FILE")
expires_epoch=$(TZ=UTC date -jf "%Y-%m-%dT%H:%M:%SZ" "$expires_at" +%s 2>/dev/null || echo 0)
now_epoch=$(date +%s)

if [[ "$now_epoch" -gt "$expires_epoch" ]]; then
    now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq --arg status "expired" --arg decided_at "$now_iso" \
        '.status = $status | .decided_at = $decided_at' \
        "$APPROVAL_FILE" > "$APPROVAL_FILE.tmp" \
        && mv "$APPROVAL_FILE.tmp" "$APPROVAL_FILE"
    log "EXPIRED: $AID was past expires_at ($expires_at) when response arrived"
    echo "EXPIRED: $AID has expired" >&2
    exit 1
fi

# === Update status ===
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
new_status="approved"
[[ "$ACTION" == "deny" ]] && new_status="denied"

jq --arg status "$new_status" --arg decided_at "$NOW_ISO" \
    '.status = $status | .decided_at = $decided_at' \
    "$APPROVAL_FILE" > "$APPROVAL_FILE.tmp" \
    && mv "$APPROVAL_FILE.tmp" "$APPROVAL_FILE"

log "$(echo "$new_status" | tr '[:lower:]' '[:upper:]'): $AID"

# === Audit trail ===
action_type=$(jq -r '.action_type' "$APPROVAL_FILE")
service=$(jq -r '.service' "$APPROVAL_FILE")
target=$(jq -r '.target' "$APPROVAL_FILE")

audit_entry=$(jq -n -c \
    --arg approval_id "$AID" \
    --arg action_type "$action_type" \
    --arg service "$service" \
    --arg target "$target" \
    --arg status "$new_status" \
    --arg decided_at "$NOW_ISO" \
    '{approval_id: $approval_id, action_type: $action_type, service: $service, target: $target, status: $status, decided_at: $decided_at, executed_at: null}')

audit_log "$audit_entry"

# === Telegram confirmation — edit original message ===
if [[ -n "$TELEGRAM_BOT_TOKEN" ]]; then
    msg_id=$(jq -r '.telegram_message_id // empty' "$APPROVAL_FILE")
    summary=$(jq -r '.summary' "$APPROVAL_FILE")
    risk_level=$(jq -r '.risk_level' "$APPROVAL_FILE")
    cooldown=$(jq -r '.cooldown_seconds' "$APPROVAL_FILE")

    status_emoji="✅"
    status_text="APPROVED"
    if [[ "$new_status" == "denied" ]]; then
        status_emoji="❌"
        status_text="DENIED"
    fi

    confirm_text="${status_emoji} <b>${AID} ${status_text}</b>\n"
    confirm_text+="${action_type} → <code>${target}</code>\n"
    confirm_text+="${summary}"

    if [[ "$new_status" == "approved" && "$cooldown" -gt 0 ]]; then
        cooldown_min=$(( cooldown / 60 ))
        confirm_text+="\n\n⏳ Cooldown: ${cooldown_min}min before execution"
    fi

    if [[ -n "$msg_id" ]]; then
        # Edit original message — removes inline buttons, shows result
        curl -s -o /dev/null \
            --connect-timeout 10 \
            --max-time 15 \
            -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/editMessageText" \
            -H "Content-Type: application/json" \
            -d "$(jq -n \
                --arg chat_id "$TELEGRAM_CHAT_ID" \
                --argjson message_id "$msg_id" \
                --arg text "$confirm_text" \
                '{chat_id: $chat_id, message_id: $message_id, text: $text, parse_mode: "HTML"}')" \
            2>/dev/null || log "WARN: editMessageText failed for $AID (msg_id: $msg_id)"
    else
        # Fallback: send new message
        curl -s -o /dev/null \
            --connect-timeout 10 \
            --max-time 15 \
            -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d parse_mode="HTML" \
            --data-urlencode text="$confirm_text" \
            2>/dev/null || log "WARN: confirmation message failed for $AID"
    fi
fi

echo "$new_status"
