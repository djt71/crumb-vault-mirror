#!/usr/bin/env bash
# approval-request.sh — Create an approval request (AID-*) and notify via Telegram
#
# Source: tess-operations TOP-049 (Approval Contract protocol)
# Spec: tess-chief-of-staff-spec.md §9b
#
# Creates a filesystem-based approval request, sends Telegram notification with
# inline approve/deny buttons via the dedicated approval bot (Option A).
#
# Usage:
#   approval-request.sh \
#     --action-type SEND_EMAIL \
#     --service google \
#     --target "john@example.com" \
#     --summary "Reply to John's project proposal" \
#     --risk-level medium \
#     [--original-context "Hi Danny, I wanted to follow up..."] \
#     [--preview "Thanks John, I've reviewed..."] \
#     [--cooldown 300] \
#     [--expires-hours 48] \
#     [--payload '{"command":"reminder-add","title":"Buy milk","list":"Groceries"}']
#
# Output: AID-xxxxx on stdout (for caller to capture)
# Exit: 0 on success, 1 on failure

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="/Users/tess/crumb-vault"
BRIDGE_DIR="$VAULT_ROOT/_openclaw"
APPROVALS_DIR="$BRIDGE_DIR/state/approvals"
LOG_FILE="$BRIDGE_DIR/logs/approval-contract.log"

# Telegram — dedicated approval bot (separate from OpenClaw gateway bot)
TELEGRAM_BOT_TOKEN="${TESS_APPROVAL_BOT_TOKEN:-$(security find-generic-password -a tess-bot -s tess-approval-bot-token -w 2>/dev/null || echo "")}"
TELEGRAM_CHAT_ID="7754252365"

# Anti-spam threshold (§9b: >3 pending → bundle)
BATCH_THRESHOLD=3

# === Argument parsing ===
ACTION_TYPE=""
SERVICE=""
TARGET=""
SUMMARY=""
ORIGINAL_CONTEXT=""
RISK_LEVEL=""
PREVIEW=""
COOLDOWN=300  # 5 minutes default (§9b)
EXPIRES_HOURS=48  # 48 hours default (§9b)
PAYLOAD=""  # Optional JSON payload for automated execution after approval

while [[ $# -gt 0 ]]; do
    case "$1" in
        --action-type) ACTION_TYPE="$2"; shift 2 ;;
        --service) SERVICE="$2"; shift 2 ;;
        --target) TARGET="$2"; shift 2 ;;
        --summary) SUMMARY="$2"; shift 2 ;;
        --original-context) ORIGINAL_CONTEXT="$2"; shift 2 ;;
        --risk-level) RISK_LEVEL="$2"; shift 2 ;;
        --preview) PREVIEW="$2"; shift 2 ;;
        --cooldown) COOLDOWN="$2"; shift 2 ;;
        --expires-hours) EXPIRES_HOURS="$2"; shift 2 ;;
        --payload) PAYLOAD="$2"; shift 2 ;;
        *) echo "ERROR: Unknown flag: $1" >&2; exit 1 ;;
    esac
done

# === Validation ===
if [[ -z "$ACTION_TYPE" || -z "$SERVICE" || -z "$TARGET" || -z "$SUMMARY" || -z "$RISK_LEVEL" ]]; then
    echo "ERROR: Required flags: --action-type, --service, --target, --summary, --risk-level" >&2
    exit 1
fi

case "$RISK_LEVEL" in
    low|medium|high) ;;
    *) echo "ERROR: --risk-level must be low, medium, or high" >&2; exit 1 ;;
esac

case "$ACTION_TYPE" in
    SEND_EMAIL|CAL_PROMOTE|REMINDER_COMPLETE|REMINDER_ADD|IMESSAGE_SEND|NOTE_CREATE|NOTE_EDIT) ;;
    *) echo "ERROR: Unknown --action-type: $ACTION_TYPE" >&2; exit 1 ;;
esac

# === Logging ===
log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

# === Generate AID (5 random alphanumeric chars) ===
mkdir -p "$APPROVALS_DIR"
AID="AID-$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 5)"
# Collision check
while [[ -f "$APPROVALS_DIR/$AID.json" ]]; do
    AID="AID-$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 5)"
done

# === Calculate expiry ===
CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EXPIRES_EPOCH=$(( $(date +%s) + EXPIRES_HOURS * 3600 ))
EXPIRES_AT=$(date -u -r "$EXPIRES_EPOCH" +"%Y-%m-%dT%H:%M:%SZ")

# === Write approval file ===
jq -n \
    --arg approval_id "$AID" \
    --arg action_type "$ACTION_TYPE" \
    --arg service "$SERVICE" \
    --arg target "$TARGET" \
    --arg summary "$SUMMARY" \
    --arg original_context "$ORIGINAL_CONTEXT" \
    --arg risk_level "$RISK_LEVEL" \
    --arg preview "$PREVIEW" \
    --arg created_at "$CREATED_AT" \
    --arg expires_at "$EXPIRES_AT" \
    --argjson cooldown_seconds "$COOLDOWN" \
    --argjson payload "${PAYLOAD:-null}" \
    '{
        approval_id: $approval_id,
        action_type: $action_type,
        service: $service,
        target: $target,
        summary: $summary,
        original_context: $original_context,
        risk_level: $risk_level,
        preview: $preview,
        status: "pending",
        created_at: $created_at,
        expires_at: $expires_at,
        decided_at: null,
        executed_at: null,
        cooldown_seconds: $cooldown_seconds,
        telegram_message_id: null,
        payload: $payload
    }' > "$APPROVALS_DIR/$AID.json"

log "CREATED: $AID ($ACTION_TYPE/$SERVICE -> $TARGET)"

# === Anti-spam check: count pending approvals ===
pending_count=0
for f in "$APPROVALS_DIR"/AID-*.json; do
    [[ ! -f "$f" ]] && continue
    s=$(jq -r '.status' "$f" 2>/dev/null) || continue
    [[ "$s" == "pending" ]] && pending_count=$((pending_count + 1))
done

# === Telegram notification ===
if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
    log "WARN: TESS_APPROVAL_BOT_TOKEN not set — approval created but no notification sent"
    echo "$AID"
    exit 0
fi

# Risk emoji
risk_emoji="🟢"
[[ "$RISK_LEVEL" == "medium" ]] && risk_emoji="🟡"
[[ "$RISK_LEVEL" == "high" ]] && risk_emoji="🔴"

# Action type emoji
action_emoji="📋"
case "$ACTION_TYPE" in
    SEND_EMAIL) action_emoji="📧" ;;
    CAL_PROMOTE) action_emoji="📅" ;;
    REMINDER_COMPLETE|REMINDER_ADD) action_emoji="✏️" ;;
    IMESSAGE_SEND) action_emoji="💬" ;;
    NOTE_CREATE|NOTE_EDIT) action_emoji="📝" ;;
esac

# === Batched heads-up if >3 pending ===
if [[ "$pending_count" -gt "$BATCH_THRESHOLD" ]]; then
    batch_text="🔐 <b>Approval Queue</b> — ${pending_count} pending\n\n"
    batch_text+="${action_emoji} <b>${AID}</b>: ${SUMMARY}\n"
    batch_text+="   ${risk_emoji} ${RISK_LEVEL} | ${SERVICE} → <code>${TARGET}</code>\n\n"
    batch_text+="<i>Plus $(( pending_count - 1 )) other pending approval(s).</i>\n"
    batch_text+="<i>Review individually via buttons on each request.</i>"

    curl -s -o /dev/null \
        --connect-timeout 10 \
        --max-time 15 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg chat_id "$TELEGRAM_CHAT_ID" \
            --arg text "$batch_text" \
            '{chat_id: $chat_id, text: $text, parse_mode: "HTML"}')" \
        2>/dev/null || log "WARN: batch notification failed"
fi

# === Individual notification with inline buttons ===
message_text="🔐 <b>Approval Request ${AID}</b>\n\n"
message_text+="${action_emoji} <b>${ACTION_TYPE}</b> (${SERVICE})\n"
message_text+="To: <code>${TARGET}</code>\n"
message_text+="${risk_emoji} Risk: ${RISK_LEVEL}\n\n"
message_text+="${SUMMARY}"

if [[ -n "$ORIGINAL_CONTEXT" ]]; then
    ctx="${ORIGINAL_CONTEXT:0:200}"
    message_text+="\n\n<b>Context:</b> <i>${ctx}</i>"
fi

if [[ -n "$PREVIEW" ]]; then
    prev="${PREVIEW:0:300}"
    message_text+="\n\n<b>Preview:</b>\n<pre>${prev}</pre>"
fi

# Human-readable expiry
expires_local=$(date -r "$EXPIRES_EPOCH" "+%b %d %H:%M ET" 2>/dev/null || echo "$EXPIRES_AT")
message_text+="\n\n⏰ Expires: ${expires_local}"

# Send with inline keyboard
response=$(curl -s \
    --connect-timeout 10 \
    --max-time 15 \
    -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
        --arg chat_id "$TELEGRAM_CHAT_ID" \
        --arg text "$message_text" \
        --arg approve_data "approve_${AID}" \
        --arg deny_data "deny_${AID}" \
        '{
            chat_id: $chat_id,
            text: $text,
            parse_mode: "HTML",
            reply_markup: {
                inline_keyboard: [[
                    {text: "✅ Approve", callback_data: $approve_data},
                    {text: "❌ Deny", callback_data: $deny_data}
                ]]
            }
        }')" \
    2>/dev/null)

# Store Telegram message ID for later editing (confirmation/expiry)
msg_id=$(echo "$response" | jq -r '.result.message_id // empty' 2>/dev/null || echo "")
if [[ -n "$msg_id" ]]; then
    jq --arg msg_id "$msg_id" '.telegram_message_id = ($msg_id | tonumber)' \
        "$APPROVALS_DIR/$AID.json" > "$APPROVALS_DIR/$AID.json.tmp" \
        && mv "$APPROVALS_DIR/$AID.json.tmp" "$APPROVALS_DIR/$AID.json"
    log "OK: $AID notification sent (msg_id: $msg_id)"
else
    log "WARN: $AID notification sent but couldn't capture message_id"
fi

# Output AID for caller
echo "$AID"
