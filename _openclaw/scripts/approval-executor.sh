#!/usr/bin/env bash
# approval-executor.sh — Dispatch approved actions whose cooldown has elapsed
#
# Source: tess-operations TOP-049/TOP-032 (Approval Contract + Reminders write)
#
# Scans _openclaw/state/approvals/ for approvals that are:
#   - status: approved
#   - executed_at: null (not yet executed)
#   - cooldown elapsed (decided_at + cooldown_seconds < now)
#   - has payload (automated execution possible)
#
# Dispatches each to the appropriate handler script.
# Designed to be called from awareness-check.sh (every 30 min).
#
# Exit: 0 always (non-fatal — best-effort execution)

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="/Users/tess/crumb-vault"
BRIDGE_DIR="$VAULT_ROOT/_openclaw"
APPROVALS_DIR="$BRIDGE_DIR/state/approvals"
LOG_FILE="$BRIDGE_DIR/logs/approval-contract.log"

TELEGRAM_BOT_TOKEN="${TESS_APPROVAL_BOT_TOKEN:-$(security find-generic-password -a tess-bot -s tess-approval-bot-token -w 2>/dev/null || echo "")}"
TELEGRAM_CHAT_ID="7754252365"

log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

send_telegram() {
    local message="$1"
    [[ -z "$TELEGRAM_BOT_TOKEN" ]] && return 0
    curl -s -o /dev/null \
        --connect-timeout 10 \
        --max-time 15 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d parse_mode="HTML" \
        --data-urlencode text="$message" \
        2>/dev/null || true
}

[[ ! -d "$APPROVALS_DIR" ]] && exit 0

now_epoch=$(date +%s)
executed=0

for approval_file in "$APPROVALS_DIR"/AID-*.json; do
    [[ ! -f "$approval_file" ]] && continue

    # Quick checks: status and payload presence
    status=$(jq -r '.status' "$approval_file" 2>/dev/null) || continue
    [[ "$status" != "approved" ]] && continue

    executed_at=$(jq -r '.executed_at // empty' "$approval_file" 2>/dev/null)
    [[ -n "$executed_at" && "$executed_at" != "null" ]] && continue

    payload_cmd=$(jq -r '.payload.command // empty' "$approval_file" 2>/dev/null)
    [[ -z "$payload_cmd" ]] && continue

    # Check cooldown
    decided_at=$(jq -r '.decided_at' "$approval_file")
    cooldown_seconds=$(jq -r '.cooldown_seconds' "$approval_file")
    decided_epoch=$(TZ=UTC date -jf "%Y-%m-%dT%H:%M:%SZ" "$decided_at" +%s 2>/dev/null || echo 0)
    cooldown_end=$(( decided_epoch + cooldown_seconds ))

    if [[ "$now_epoch" -lt "$cooldown_end" ]]; then
        continue  # Cooldown not elapsed
    fi

    aid=$(jq -r '.approval_id' "$approval_file")
    action_type=$(jq -r '.action_type' "$approval_file")
    target=$(jq -r '.target' "$approval_file")
    service=$(jq -r '.service' "$approval_file")

    log "EXECUTING: $aid ($action_type/$service -> $target, payload: $payload_cmd)"

    # Dispatch to the appropriate handler
    case "$payload_cmd" in
        reminder-add|reminder-complete)
            result=$(bash "$SCRIPT_DIR/reminder-write.sh" execute "$aid" 2>&1) || {
                log "ERROR: execution failed for $aid: $result"
                send_telegram "🚨 <b>Execution failed</b>: ${aid}\n${action_type} → ${target}\n<pre>${result:0:200}</pre>"
                continue
            }
            log "OK: $aid executed successfully"
            send_telegram "✅ <b>Executed</b>: ${aid}\n${action_type} → ${target}"

            # Discord #audit-log — execution entry
            bash "$SCRIPT_DIR/discord-post.sh" post audit-log \
                "✅ **EXECUTED** — **${aid}** | ${action_type} → \`${target}\` | $(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                --username "Audit Log" 2>/dev/null || true

            executed=$((executed + 1))
            ;;
        email-send)
            result=$(bash "$SCRIPT_DIR/email-send.sh" execute "$aid" 2>&1) || {
                log "ERROR: execution failed for $aid: $result"
                send_telegram "🚨 <b>Execution failed</b>: ${aid}\n${action_type} → ${target}\n<pre>${result:0:200}</pre>"
                continue
            }
            log "OK: $aid executed successfully"
            send_telegram "✅ <b>Executed</b>: ${aid}\n📧 ${action_type} → ${target}"

            # Discord #audit-log — execution entry
            bash "$SCRIPT_DIR/discord-post.sh" post audit-log \
                "✅ **EXECUTED** — **${aid}** | ${action_type} → \`${target}\` | $(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                --username "Audit Log" 2>/dev/null || true

            executed=$((executed + 1))
            ;;
        cal-promote)
            result=$(bash "$SCRIPT_DIR/calendar-staging.sh" execute "$aid" 2>&1) || {
                log "ERROR: execution failed for $aid: $result"
                send_telegram "🚨 <b>Execution failed</b>: ${aid}\n${action_type} → ${target}\n<pre>${result:0:200}</pre>"
                continue
            }
            log "OK: $aid executed successfully"
            send_telegram "✅ <b>Executed</b>: ${aid}\n📅 ${action_type} → ${target}"

            # Discord #audit-log — execution entry
            bash "$SCRIPT_DIR/discord-post.sh" post audit-log \
                "✅ **EXECUTED** — **${aid}** | ${action_type} → \`${target}\` | $(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
                --username "Audit Log" 2>/dev/null || true

            executed=$((executed + 1))
            ;;
        *)
            log "WARN: no handler for payload command '$payload_cmd' in $aid — skipping"
            ;;
    esac
done

if [[ "$executed" -gt 0 ]]; then
    log "OK: executor dispatched $executed approval(s)"
fi
