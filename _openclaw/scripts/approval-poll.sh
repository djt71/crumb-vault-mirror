#!/usr/bin/env bash
# approval-poll.sh — Poll Telegram Bot API for inline button callbacks
#
# Source: tess-operations TOP-049 (Approval Contract protocol)
#
# Polls the dedicated approval bot for callback_queries (button presses).
# Parses callback data (approve_AID-xxxxx / deny_AID-xxxxx), dispatches to
# approval-respond.sh, and answers the callback query (removes loading spinner).
#
# Uses offset tracking (.last_update_id) to avoid reprocessing.
# Designed to be called from awareness-check.sh (every 30 min).
# Also safe to run standalone for testing.
#
# Exit: 0 always (non-fatal — polling is best-effort)

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="/Users/tess/crumb-vault"
BRIDGE_DIR="$VAULT_ROOT/_openclaw"
APPROVALS_DIR="$BRIDGE_DIR/state/approvals"
OFFSET_FILE="$APPROVALS_DIR/.last_update_id"
LOG_FILE="$BRIDGE_DIR/logs/approval-contract.log"

TELEGRAM_BOT_TOKEN="${TESS_APPROVAL_BOT_TOKEN:-$(security find-generic-password -a tess-bot -s tess-approval-bot-token -w 2>/dev/null || echo "")}"

log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
    # Silent skip — token not configured yet
    exit 0
fi

# Read last processed offset
offset=0
if [[ -f "$OFFSET_FILE" ]]; then
    offset=$(cat "$OFFSET_FILE")
fi

# Poll for callback_queries (non-blocking: timeout=0)
response=$(curl -s \
    --connect-timeout 10 \
    --max-time 15 \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=${offset}&timeout=0&allowed_updates=%5B%22callback_query%22%5D" \
    2>/dev/null) || { log "ERROR: getUpdates failed"; exit 0; }

# Validate response
ok=$(echo "$response" | jq -r '.ok' 2>/dev/null)
if [[ "$ok" != "true" ]]; then
    log "ERROR: getUpdates returned ok=false: $(echo "$response" | jq -r '.description // "unknown"' 2>/dev/null)"
    exit 0
fi

# Check for updates
result_count=$(echo "$response" | jq '.result | length' 2>/dev/null || echo 0)
[[ "$result_count" -eq 0 ]] && exit 0

processed=0
echo "$response" | jq -c '.result[]' 2>/dev/null | while IFS= read -r update; do
    [[ -z "$update" ]] && continue

    update_id=$(echo "$update" | jq -r '.update_id')
    callback_query_id=$(echo "$update" | jq -r '.callback_query.id // empty')
    callback_data=$(echo "$update" | jq -r '.callback_query.data // empty')

    # Always advance offset (even if we can't process this specific update)
    new_offset=$(( update_id + 1 ))
    echo "$new_offset" > "$OFFSET_FILE"

    # Skip non-callback updates
    [[ -z "$callback_query_id" ]] && continue
    [[ -z "$callback_data" ]] && continue

    # Parse callback data: approve_AID-xxxxx or deny_AID-xxxxx
    if [[ "$callback_data" =~ ^(approve|deny)_(AID-[a-z0-9]{5})$ ]]; then
        action="${BASH_REMATCH[1]}"
        aid="${BASH_REMATCH[2]}"

        log "CALLBACK: $action $aid (query_id: $callback_query_id)"

        # Process the response
        bash "$SCRIPT_DIR/approval-respond.sh" "$aid" "$action" 2>&1 || true

        # Answer the callback query (removes spinner on the button)
        answer_text="✅ Approved"
        [[ "$action" == "deny" ]] && answer_text="❌ Denied"

        curl -s -o /dev/null \
            --connect-timeout 10 \
            --max-time 15 \
            -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/answerCallbackQuery" \
            -d "callback_query_id=$callback_query_id" \
            --data-urlencode "text=$answer_text" \
            2>/dev/null || log "WARN: answerCallbackQuery failed for $callback_query_id"

        processed=$((processed + 1))
    else
        log "WARN: unknown callback data: $callback_data"

        # Still answer to dismiss the spinner
        curl -s -o /dev/null \
            --connect-timeout 10 \
            --max-time 15 \
            -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/answerCallbackQuery" \
            -d "callback_query_id=$callback_query_id" \
            -d "text=Unknown action" \
            2>/dev/null || true
    fi
done

# Note: processed count is in subshell due to pipe, so we log based on result_count
if [[ "$result_count" -gt 0 ]]; then
    log "OK: polled $result_count update(s)"
fi
