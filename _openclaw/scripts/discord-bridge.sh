#!/usr/bin/env bash
# discord-bridge.sh — Cross-context bridge for Telegram → Discord posting
#
# Source: tess-operations TOP-040 (multi-agent Discord and cross-context routing)
# Spec: tess-comms-channel-spec.md §5.3, §8.4
#
# Provides a structured interface for Telegram interactive sessions to post
# to Discord channels. Includes:
#   - Shared-secret authentication
#   - Idempotency keys (prevent duplicate posts)
#   - Disk-based queue (durability when Discord is down)
#   - Per-bot channel restriction enforcement
#
# Usage:
#   discord-bridge.sh enqueue --channel <slug> --message <text> --bot <name> \
#                              --secret <token> [--idempotency-key <key>]
#   discord-bridge.sh drain                        # Process queue via discord-post.sh
#   discord-bridge.sh status                       # Show queue depth
#
# The drain subcommand is called by awareness-check.sh every 30 minutes.
# For near-real-time posting, callers can run drain immediately after enqueue.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="/Users/tess/crumb-vault"
BRIDGE_DIR="$VAULT_ROOT/_openclaw"
QUEUE_DIR="$BRIDGE_DIR/state/discord-bridge-queue"
PROCESSED_DIR="$QUEUE_DIR/processed"
SECRET_FILE="$BRIDGE_DIR/config/discord-bridge-secret.txt"
BOT_CHANNELS_FILE="$BRIDGE_DIR/config/discord-bot-channels.json"
LOG_FILE="$BRIDGE_DIR/logs/discord-bridge.log"

# === Logging ===
log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

# === Validate shared secret ===
validate_secret() {
    local provided="$1"

    if [[ ! -f "$SECRET_FILE" ]]; then
        log "ERROR: secret file not found at $SECRET_FILE"
        return 1
    fi

    local expected
    expected=$(cat "$SECRET_FILE" 2>/dev/null | tr -d '[:space:]')

    if [[ "$provided" != "$expected" ]]; then
        log "SECURITY: invalid bridge secret — access denied"
        return 1
    fi

    return 0
}

# === Validate bot → channel allowlist ===
validate_channel() {
    local bot="$1" channel="$2"
    local bot_key
    bot_key=$(echo "$bot" | tr '[:upper:]' '[:lower:]')

    if [[ ! -f "$BOT_CHANNELS_FILE" ]]; then
        log "WARN: bot channels config not found — allowing all"
        return 0
    fi

    if jq -r --arg bot "$bot_key" '(.[$bot] // []) | .[]' "$BOT_CHANNELS_FILE" 2>/dev/null | grep -qx "$channel"; then
        return 0
    fi

    log "BLOCKED: bot '$bot' not allowed in channel '$channel'"
    return 1
}

# === Subcommand routing ===
subcmd="${1:-}"
shift || true

case "$subcmd" in

# ─── ENQUEUE ──────────────────────────────────────────────────────────────
enqueue)
    CHANNEL=""
    MESSAGE=""
    BOT=""
    SECRET=""
    IDEM_KEY=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --channel) CHANNEL="$2"; shift 2 ;;
            --message) MESSAGE="$2"; shift 2 ;;
            --bot) BOT="$2"; shift 2 ;;
            --secret) SECRET="$2"; shift 2 ;;
            --idempotency-key) IDEM_KEY="$2"; shift 2 ;;
            *) echo "ERROR: Unknown flag: $1" >&2; exit 1 ;;
        esac
    done

    if [[ -z "$CHANNEL" || -z "$MESSAGE" || -z "$BOT" || -z "$SECRET" ]]; then
        echo "Usage: discord-bridge.sh enqueue --channel <slug> --message <text> --bot <name> --secret <token> [--idempotency-key <key>]" >&2
        exit 1
    fi

    # Gate 1: Shared secret
    if ! validate_secret "$SECRET"; then
        echo "ERROR: invalid bridge secret" >&2
        exit 1
    fi

    # Gate 2: Channel allowlist
    if ! validate_channel "$BOT" "$CHANNEL"; then
        echo "ERROR: bot '$BOT' not allowed in channel '$CHANNEL'" >&2
        exit 1
    fi

    # Generate idempotency key if not provided
    if [[ -z "$IDEM_KEY" ]]; then
        IDEM_KEY="$(date +%s)-$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 8)"
    fi

    # Idempotency check: skip if already queued or processed
    mkdir -p "$QUEUE_DIR" "$PROCESSED_DIR"
    if [[ -f "$QUEUE_DIR/$IDEM_KEY.json" || -f "$PROCESSED_DIR/$IDEM_KEY.json" ]]; then
        log "DEDUP: idempotency key '$IDEM_KEY' already exists — skipping"
        echo "$IDEM_KEY"
        exit 0
    fi

    # Write to queue
    jq -n -c \
        --arg channel "$CHANNEL" \
        --arg message "$MESSAGE" \
        --arg bot "$BOT" \
        --arg idem_key "$IDEM_KEY" \
        --arg enqueued_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        '{channel: $channel, message: $message, bot: $bot, idempotency_key: $idem_key, enqueued_at: $enqueued_at}' \
        > "$QUEUE_DIR/$IDEM_KEY.json"

    log "ENQUEUED: $IDEM_KEY → #$CHANNEL (bot: $BOT)"
    echo "$IDEM_KEY"
    ;;

# ─── DRAIN (process queue) ───────────────────────────────────────────────
drain)
    mkdir -p "$QUEUE_DIR" "$PROCESSED_DIR"

    queue_files=("$QUEUE_DIR"/*.json)
    if [[ ! -f "${queue_files[0]:-}" ]]; then
        exit 0  # Empty queue — nothing to do
    fi

    processed=0
    failed=0

    for queue_file in "$QUEUE_DIR"/*.json; do
        [[ ! -f "$queue_file" ]] && continue

        channel=$(jq -r '.channel' "$queue_file")
        message=$(jq -r '.message' "$queue_file")
        bot=$(jq -r '.bot' "$queue_file")
        idem_key=$(jq -r '.idempotency_key' "$queue_file")

        # Post via discord-post.sh
        msg_id=$(bash "$SCRIPT_DIR/discord-post.sh" post "$channel" "$message" --username "$bot" 2>/dev/null) || {
            log "ERROR: drain failed for $idem_key → #$channel"
            failed=$((failed + 1))
            continue
        }

        # Record result and move to processed
        jq --arg msg_id "${msg_id:-}" --arg drained_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
            '. + {discord_message_id: $msg_id, drained_at: $drained_at}' \
            "$queue_file" > "$PROCESSED_DIR/$idem_key.json"
        rm "$queue_file"

        log "DRAINED: $idem_key → #$channel (msg_id: ${msg_id:-none})"
        processed=$((processed + 1))
    done

    if [[ "$processed" -gt 0 || "$failed" -gt 0 ]]; then
        log "DRAIN: processed=$processed failed=$failed"
    fi

    # Prune processed files older than 7 days
    find "$PROCESSED_DIR" -name "*.json" -mtime +7 -delete 2>/dev/null || true
    ;;

# ─── STATUS ──────────────────────────────────────────────────────────────
status)
    mkdir -p "$QUEUE_DIR" "$PROCESSED_DIR"
    pending=$(find "$QUEUE_DIR" -maxdepth 1 -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
    processed=$(find "$PROCESSED_DIR" -maxdepth 1 -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
    echo "pending: $pending, processed (7d): $processed"
    ;;

*)
    echo "Usage: discord-bridge.sh {enqueue|drain|status} [args...]" >&2
    exit 1
    ;;
esac
