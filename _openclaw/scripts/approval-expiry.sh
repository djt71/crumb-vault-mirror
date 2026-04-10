#!/usr/bin/env bash
# approval-expiry.sh — Sweep and expire stale pending approvals
#
# Source: tess-operations TOP-049 (Approval Contract protocol)
# Spec: tess-chief-of-staff-spec.md §9b (48h timeout, batch expiry notification)
#
# Scans _openclaw/state/approvals/ for pending approvals past expires_at.
# Auto-cancels them, logs to audit trail, edits original Telegram messages,
# and sends a batch summary notification.
#
# Designed to be called from awareness-check.sh (every 30 min).
# Also safe to run standalone for testing.
#
# Exit: 0 always (non-fatal)

set -eu

VAULT_ROOT="/Users/tess/crumb-vault"
BRIDGE_DIR="$VAULT_ROOT/_openclaw"
APPROVALS_DIR="$BRIDGE_DIR/state/approvals"
AUDIT_LOG="$BRIDGE_DIR/logs/approval-audit.log"
LOG_FILE="$BRIDGE_DIR/logs/approval-contract.log"

TELEGRAM_BOT_TOKEN="${TESS_APPROVAL_BOT_TOKEN:-$(security find-generic-password -a tess-bot -s tess-approval-bot-token -w 2>/dev/null || echo "")}"
TELEGRAM_CHAT_ID="7754252365"

log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

audit_log() {
    mkdir -p "$(dirname "$AUDIT_LOG")"
    echo "$1" >> "$AUDIT_LOG"
}

# Exit early if no approvals directory
[[ ! -d "$APPROVALS_DIR" ]] && exit 0

now_epoch=$(date +%s)
now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
expired_count=0
expired_summaries=""

for approval_file in "$APPROVALS_DIR"/AID-*.json; do
    [[ ! -f "$approval_file" ]] && continue

    status=$(jq -r '.status' "$approval_file" 2>/dev/null) || continue
    [[ "$status" != "pending" ]] && continue

    expires_at=$(jq -r '.expires_at' "$approval_file")
    expires_epoch=$(TZ=UTC date -jf "%Y-%m-%dT%H:%M:%SZ" "$expires_at" +%s 2>/dev/null || echo 0)

    if [[ "$now_epoch" -gt "$expires_epoch" ]]; then
        aid=$(jq -r '.approval_id' "$approval_file")
        action_type=$(jq -r '.action_type' "$approval_file")
        target=$(jq -r '.target' "$approval_file")
        service=$(jq -r '.service' "$approval_file")
        summary=$(jq -r '.summary' "$approval_file")

        # Mark as expired
        jq --arg status "expired" --arg decided_at "$now_iso" \
            '.status = $status | .decided_at = $decided_at' \
            "$approval_file" > "$approval_file.tmp" \
            && mv "$approval_file.tmp" "$approval_file"

        # Audit trail
        audit_entry=$(jq -n -c \
            --arg approval_id "$aid" \
            --arg action_type "$action_type" \
            --arg service "$service" \
            --arg target "$target" \
            --arg status "expired" \
            --arg decided_at "$now_iso" \
            '{approval_id: $approval_id, action_type: $action_type, service: $service, target: $target, status: $status, decided_at: $decided_at}')
        audit_log "$audit_entry"

        # Edit original Telegram message if we have a message ID
        msg_id=$(jq -r '.telegram_message_id // empty' "$approval_file")
        if [[ -n "$msg_id" && -n "$TELEGRAM_BOT_TOKEN" ]]; then
            curl -s -o /dev/null \
                --connect-timeout 10 \
                --max-time 15 \
                -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/editMessageText" \
                -H "Content-Type: application/json" \
                -d "$(jq -n \
                    --arg chat_id "$TELEGRAM_CHAT_ID" \
                    --argjson message_id "$msg_id" \
                    --arg text "⏰ <b>${aid} EXPIRED</b>\n${action_type} → ${target}\n${summary}" \
                    '{chat_id: $chat_id, message_id: $message_id, text: $text, parse_mode: "HTML"}')" \
                2>/dev/null || true
        fi

        expired_summaries+="• ${aid}: ${action_type} → ${target}\n"
        expired_count=$((expired_count + 1))
        log "EXPIRED: $aid ($action_type/$service -> $target)"
    fi
done

# Send batch expiry notification
if [[ "$expired_count" -gt 0 && -n "$TELEGRAM_BOT_TOKEN" ]]; then
    message="⏰ <b>${expired_count} approval(s) expired</b>\n\n${expired_summaries}"
    curl -s -o /dev/null \
        --connect-timeout 10 \
        --max-time 15 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d parse_mode="HTML" \
        --data-urlencode text="$message" \
        2>/dev/null || log "WARN: expiry notification failed"
fi
