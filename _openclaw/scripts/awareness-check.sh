#!/usr/bin/env bash
# awareness-check.sh — Lightweight operational awareness checks
#
# Source: tess-operations TOP-014 gate eval
# Replaces: OpenClaw cron job (mechanic agent, delivery broken on v2026.2.25)
#
# Three checks, all pure bash + jq (zero LLM invocations):
#   1. Outbox relay: Find stale dispatch results (>2h), summarize with jq, relay
#   2. Feed digest freshness: Flag if newest feed file is >36h old
#   3. Session debrief: Detect new run-log entries and send Telegram summary (TOP-047 fn3)
#
# Delivery: Direct curl to Telegram Bot API — no OpenClaw delivery pipeline.
# HTTP 200 = delivered. Anything else = real error code, logged, non-zero exit.
#
# Schedule: Every 30 minutes via launchd (LaunchAgent, tess user).
# Waking hours only (07–23) — exits silently outside that window.
#
# Infrastructure: sources cron-lib.sh for kill-switch, locking, metrics, wall-time.

set -eu

# === Waking Hours Gate ===
# Check before cron_init — don't acquire lock or log metrics for off-hours skips.
hour=$(date +%-H)
if [[ "$hour" -lt 7 || "$hour" -ge 23 ]]; then
    exit 0
fi

# === Infrastructure ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/cron-lib.sh"

cron_init "awareness-check" --wall-time 120 --jitter 10

# === Configuration ===
TELEGRAM_BOT_TOKEN="${TESS_AWARENESS_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="7754252365"
OUTBOX_DIR="$BRIDGE_DIR/outbox"
OUTBOX_RELAYED_DIR="$OUTBOX_DIR/relayed"
FEEDS_DIR="$BRIDGE_DIR/feeds"
STALE_OUTBOX_MINUTES=120   # 2 hours
STALE_FEED_HOURS=36

LOG_FILE="$BRIDGE_DIR/logs/awareness-check.log"

# === Logging ===
log() {
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

# === Telegram Delivery ===
send_telegram() {
    local message="$1"

    if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
        log "ERROR: TESS_AWARENESS_BOT_TOKEN not set"
        echo "ERROR: TESS_AWARENESS_BOT_TOKEN not set" >&2
        return 1
    fi

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 \
        --max-time 15 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d parse_mode="HTML" \
        --data-urlencode text="$message" \
        2>/dev/null)

    if [[ "$http_code" == "200" ]]; then
        log "OK: Telegram sendMessage HTTP 200"
        cron_mark_alert
        return 0
    else
        log "ERROR: Telegram sendMessage returned HTTP $http_code"
        echo "ERROR: Telegram sendMessage returned HTTP $http_code" >&2
        return 1
    fi
}

# === Check 1: Outbox Relay ===
check_outbox() {
    local stale_files
    stale_files=$(find "$OUTBOX_DIR" -maxdepth 1 -type f -name "*.json" -mmin +$STALE_OUTBOX_MINUTES 2>/dev/null | head -10) || true

    [[ -z "$stale_files" ]] && return 0

    local summary=""
    local count=0
    local now_epoch
    now_epoch=$(date +%s)

    while IFS= read -r filepath; do
        [[ -z "$filepath" ]] && continue
        local filename
        filename=$(basename "$filepath")

        # Extract key fields with jq
        local status stage
        status=$(jq -r '.status // "unknown"' "$filepath" 2>/dev/null || echo "unreadable")
        stage=$(jq -r '.stage // .type // "dispatch"' "$filepath" 2>/dev/null || echo "unknown")

        local file_epoch
        file_epoch=$(stat -f %m "$filepath" 2>/dev/null || echo "$now_epoch")
        local age_hours=$(( (now_epoch - file_epoch) / 3600 ))

        summary="${summary}• ${stage} (${status}) — ${age_hours}h old
"
        count=$((count + 1))
    done <<< "$stale_files"

    if [[ "$count" -gt 0 ]]; then
        local message
        message=$(printf "🔔 <b>Outbox Relay</b> — %d stale file(s):\n\n%s\nFiles &gt;2h in <code>_openclaw/outbox/</code>" "$count" "$summary")
        if send_telegram "$message"; then
            # Move relayed files only after successful delivery
            mkdir -p -m 775 "$OUTBOX_RELAYED_DIR"
            while IFS= read -r filepath; do
                [[ -z "$filepath" ]] && continue
                mv "$filepath" "$OUTBOX_RELAYED_DIR/" 2>/dev/null || true
            done <<< "$stale_files"
            log "OK: relayed $count outbox file(s)"
        else
            return 1
        fi
    fi
}

# === Check 2: Feed Digest Freshness ===
check_feed_freshness() {
    # Find newest file in feeds/ (depth 2 covers subdirs like digests/, research/)
    local newest_epoch
    newest_epoch=$(find "$FEEDS_DIR" -maxdepth 2 -type f -exec stat -f %m {} \; 2>/dev/null | sort -rn | head -1) || true

    [[ -z "$newest_epoch" ]] && return 0

    local now_epoch
    now_epoch=$(date +%s)
    local age_hours=$(( (now_epoch - newest_epoch) / 3600 ))

    if [[ "$age_hours" -gt "$STALE_FEED_HOURS" ]]; then
        send_telegram "⚠️ Feed digest may be stale — newest file is ${age_hours}h old. Check x-feed-intel pipeline." || return 1
        log "ALERT: feed digest stale (${age_hours}h)"
    fi
}

# === Main ===
main() {
    local had_errors=false

    check_outbox || had_errors=true
    check_feed_freshness || had_errors=true

    # Check 3: Session debrief (TOP-047 fn3)
    # Runs session-debrief.sh in all-projects mode — cursor-based, only fires on new entries
    bash "$SCRIPT_DIR/session-debrief.sh" 2>&1 || log "WARNING: session-debrief had errors"

    # Check 4: Approval contract — poll for inline button callbacks (TOP-049)
    bash "$SCRIPT_DIR/approval-poll.sh" 2>&1 || log "WARNING: approval-poll had errors"

    # Check 5: Approval contract — expire stale pending approvals (TOP-049)
    bash "$SCRIPT_DIR/approval-expiry.sh" 2>&1 || log "WARNING: approval-expiry had errors"

    # Check 6: Approval executor — dispatch approved actions with payload (TOP-032+)
    bash "$SCRIPT_DIR/approval-executor.sh" 2>&1 || log "WARNING: approval-executor had errors"

    # Check 7: Calendar staging cleanup — delete holds older than 48h (TOP-036)
    bash "$SCRIPT_DIR/calendar-staging.sh" cleanup 2>&1 || log "WARNING: calendar-staging cleanup had errors"

    # Check 8: Discord bridge drain — process cross-context queue (TOP-040)
    bash "$SCRIPT_DIR/discord-bridge.sh" drain 2>&1 || log "WARNING: discord-bridge drain had errors"

    if [[ "$had_errors" == "true" ]]; then
        cron_finish 1
    else
        cron_finish 0
    fi
}

main
