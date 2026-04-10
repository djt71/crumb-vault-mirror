#!/usr/bin/env bash
# approval-check.sh — Wrapper enforcement gate for approval-gated operations
#
# Source: tess-operations TOP-049 (Approval Contract protocol)
# Spec: tess-chief-of-staff-spec.md §9b / tess-google-services-spec.md §7.4
#
# Called by wrapper scripts before executing gated operations. Validates that
# the provided AID is approved, not expired, and cooldown has elapsed.
# On failure: logs security event, sends Telegram alert.
#
# Usage (in wrapper scripts):
#   if ! bash approval-check.sh "$AID"; then
#       echo "Action blocked — approval not valid"
#       exit 1
#   fi
#   # ... proceed with gated action ...
#
# Flags:
#   --validate-only   Check without marking executed (for pre-action validation)
#
# Exit: 0 = proceed, 1 = blocked

set -eu

VAULT_ROOT="/Users/tess/crumb-vault"
BRIDGE_DIR="$VAULT_ROOT/_openclaw"
APPROVALS_DIR="$BRIDGE_DIR/state/approvals"
AUDIT_LOG="$BRIDGE_DIR/logs/approval-audit.log"
LOG_FILE="$BRIDGE_DIR/logs/approval-contract.log"
SECURITY_LOG="$BRIDGE_DIR/logs/approval-security.log"

TELEGRAM_BOT_TOKEN="${TESS_APPROVAL_BOT_TOKEN:-$(security find-generic-password -a tess-bot -s tess-approval-bot-token -w 2>/dev/null || echo "")}"
TELEGRAM_CHAT_ID="7754252365"

VALIDATE_ONLY=false
AID=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --validate-only) VALIDATE_ONLY=true; shift ;;
        AID-*) AID="$1"; shift ;;
        *) AID="$1"; shift ;;
    esac
done

if [[ -z "$AID" ]]; then
    echo "Usage: approval-check.sh [--validate-only] AID-xxxxx" >&2
    exit 1
fi

# === Logging ===
log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

security_log() {
    mkdir -p "$(dirname "$SECURITY_LOG")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") SECURITY $1" >> "$SECURITY_LOG"
}

audit_log() {
    mkdir -p "$(dirname "$AUDIT_LOG")"
    echo "$1" >> "$AUDIT_LOG"
}

alert_telegram() {
    local message="$1"
    if [[ -n "$TELEGRAM_BOT_TOKEN" ]]; then
        curl -s -o /dev/null \
            --connect-timeout 10 \
            --max-time 15 \
            -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d parse_mode="HTML" \
            --data-urlencode text="$message" \
            2>/dev/null || true
    fi
}

# === Validate AID format ===
if [[ ! "$AID" =~ ^AID-[a-z0-9]{5}$ ]]; then
    security_log "INVALID_FORMAT: attempted check with malformed AID '$AID'"
    alert_telegram "🚨 <b>Security Event</b>: malformed approval ID attempted: <code>${AID}</code>"
    exit 1
fi

# === Check file exists ===
APPROVAL_FILE="$APPROVALS_DIR/$AID.json"
if [[ ! -f "$APPROVAL_FILE" ]]; then
    security_log "NOT_FOUND: $AID — no such approval"
    alert_telegram "🚨 <b>Security Event</b>: approval check for non-existent <code>${AID}</code>"
    exit 1
fi

# === Read approval data ===
status=$(jq -r '.status' "$APPROVAL_FILE")
action_type=$(jq -r '.action_type' "$APPROVAL_FILE")
service=$(jq -r '.service' "$APPROVAL_FILE")
target=$(jq -r '.target' "$APPROVAL_FILE")

# === Check if already executed (prevent double execution) ===
executed_at=$(jq -r '.executed_at // empty' "$APPROVAL_FILE")
if [[ -n "$executed_at" && "$executed_at" != "null" ]]; then
    security_log "DOUBLE_EXEC: $AID already executed at $executed_at. action=$action_type service=$service target=$target"
    alert_telegram "🚨 <b>Security Event</b>: double execution attempted on <code>${AID}</code> (${action_type} → ${target})"
    exit 1
fi

# === Check status ===
if [[ "$status" != "approved" ]]; then
    security_log "WRONG_STATUS: $AID is '$status' (expected 'approved'). action=$action_type service=$service target=$target"
    if [[ "$status" == "pending" ]]; then
        log "BLOCKED: $AID still pending"
    elif [[ "$status" == "denied" || "$status" == "expired" ]]; then
        alert_telegram "🚨 <b>Security Event</b>: execution attempted on ${status} approval <code>${AID}</code> (${action_type} → ${target})"
    fi
    exit 1
fi

# === Check expiry (approval could expire after being approved but before execution) ===
expires_at=$(jq -r '.expires_at' "$APPROVAL_FILE")
expires_epoch=$(TZ=UTC date -jf "%Y-%m-%dT%H:%M:%SZ" "$expires_at" +%s 2>/dev/null || echo 0)
now_epoch=$(date +%s)

if [[ "$now_epoch" -gt "$expires_epoch" ]]; then
    now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq --arg status "expired" '.status = $status' \
        "$APPROVAL_FILE" > "$APPROVAL_FILE.tmp" \
        && mv "$APPROVAL_FILE.tmp" "$APPROVAL_FILE"
    log "EXPIRED_AT_CHECK: $AID expired after approval (expires_at: $expires_at)"
    exit 1
fi

# === Check cooldown (5-min default: cancel still possible during this window) ===
decided_at=$(jq -r '.decided_at' "$APPROVAL_FILE")
cooldown_seconds=$(jq -r '.cooldown_seconds' "$APPROVAL_FILE")

if [[ -n "$decided_at" && "$decided_at" != "null" && "$cooldown_seconds" -gt 0 ]]; then
    decided_epoch=$(TZ=UTC date -jf "%Y-%m-%dT%H:%M:%SZ" "$decided_at" +%s 2>/dev/null || echo 0)
    cooldown_end=$(( decided_epoch + cooldown_seconds ))

    if [[ "$now_epoch" -lt "$cooldown_end" ]]; then
        remaining=$(( cooldown_end - now_epoch ))
        log "COOLDOWN: $AID — ${remaining}s remaining"
        echo "COOLDOWN: ${remaining}s remaining" >&2
        exit 1
    fi
fi

# === All checks passed ===
if [[ "$VALIDATE_ONLY" == "true" ]]; then
    log "VALIDATED: $AID ($action_type/$service -> $target) — validate-only, not marking executed"
    exit 0
fi

# Mark as executed
now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
jq --arg executed_at "$now_iso" '.executed_at = $executed_at' \
    "$APPROVAL_FILE" > "$APPROVAL_FILE.tmp" \
    && mv "$APPROVAL_FILE.tmp" "$APPROVAL_FILE"

# Update audit trail with execution timestamp
audit_entry=$(jq -n -c \
    --arg approval_id "$AID" \
    --arg action_type "$action_type" \
    --arg service "$service" \
    --arg target "$target" \
    --arg status "executed" \
    --arg executed_at "$now_iso" \
    '{approval_id: $approval_id, action_type: $action_type, service: $service, target: $target, status: $status, executed_at: $executed_at}')

audit_log "$audit_entry"
log "EXECUTED: $AID ($action_type/$service -> $target)"

exit 0
