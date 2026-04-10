#!/usr/bin/env bash
# discord-post.sh — Post or edit messages to Discord channels via webhooks
#
# Source: tess-operations TOP-034 (service output mirroring)
# Spec: tess-comms-channel-spec.md §5
#
# Uses webhook URLs from _openclaw/config/discord-webhooks.json.
# Returns Discord message ID on stdout (for edit correlation).
# Gracefully skips if no webhook configured for the channel.
#
# Usage:
#   discord-post.sh post <channel-slug> <message>
#   discord-post.sh post <channel-slug> <message> --username "Tess" --embed <json>
#   discord-post.sh edit <channel-slug> <message-id> <new-content>
#
# Exit: 0 on success (or graceful skip), 1 on hard failure

set -eu

VAULT_ROOT="/Users/tess/crumb-vault"
CONFIG_DIR="$VAULT_ROOT/_openclaw/config"
WEBHOOKS_FILE="$CONFIG_DIR/discord-webhooks.json"
BOT_CHANNELS_FILE="$CONFIG_DIR/discord-bot-channels.json"
LOG_FILE="$VAULT_ROOT/_openclaw/logs/discord-post.log"

log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

# === Load webhook URL for channel ===
get_webhook_url() {
    local channel="$1"
    if [[ ! -f "$WEBHOOKS_FILE" ]]; then
        log "WARN: $WEBHOOKS_FILE not found"
        return 1
    fi
    local url
    url=$(jq -r ".webhooks[\"$channel\"] // empty" "$WEBHOOKS_FILE" 2>/dev/null)
    if [[ -z "$url" ]]; then
        return 1
    fi
    echo "$url"
}

# === Subcommand routing ===
subcmd="${1:-}"
shift || true

case "$subcmd" in

# ─── POST ────────────────────────────────────────────────────────────────
post)
    CHANNEL="${1:-}"
    MESSAGE="${2:-}"
    shift 2 || true

    if [[ -z "$CHANNEL" || -z "$MESSAGE" ]]; then
        echo "Usage: discord-post.sh post <channel-slug> <message> [--username name]" >&2
        exit 1
    fi

    USERNAME="Tess"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --username) USERNAME="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    # Per-bot channel restriction check (TOP-040)
    bot_key=$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]')
    if [[ -f "$BOT_CHANNELS_FILE" ]]; then
        allowed=$(jq -r --arg bot "$bot_key" '(.[$bot] // []) | .[]' "$BOT_CHANNELS_FILE" 2>/dev/null | grep -qx "$CHANNEL" && echo "yes" || echo "no")
        if [[ "$allowed" == "no" ]]; then
            # Check common aliases: "Tess Approvals" → "tess", "Audit Log" → skip check for generic usernames
            base_bot=$(echo "$bot_key" | sed 's/ .*//')
            allowed=$(jq -r --arg bot "$base_bot" '(.[$bot] // []) | .[]' "$BOT_CHANNELS_FILE" 2>/dev/null | grep -qx "$CHANNEL" && echo "yes" || echo "no")
            if [[ "$allowed" == "no" ]]; then
                log "BLOCKED: bot '$USERNAME' not allowed in channel '$CHANNEL'"
                exit 0  # Graceful skip — prevent silent channel leak
            fi
        fi
    fi

    WEBHOOK_URL=$(get_webhook_url "$CHANNEL") || {
        log "SKIP: no webhook for channel '$CHANNEL'"
        exit 0  # Graceful skip — not a failure
    }

    # Discord message limit: 2000 chars. Truncate if needed.
    if [[ ${#MESSAGE} -gt 1950 ]]; then
        MESSAGE="${MESSAGE:0:1950}… (truncated)"
    fi

    # Check if channel is a forum type (requires thread_name)
    is_forum="false"
    if [[ -f "$WEBHOOKS_FILE" ]]; then
        chan_type=$(jq -r ".channel_types[\"$CHANNEL\"] // \"text\"" "$WEBHOOKS_FILE" 2>/dev/null)
        [[ "$chan_type" == "forum" ]] && is_forum="true"
    fi

    if [[ "$is_forum" == "true" ]]; then
        # Forum channels: first line becomes thread title, rest is body
        thread_name=$(echo "$MESSAGE" | head -1 | head -c 100)
        [[ -z "$thread_name" ]] && thread_name="Post from $USERNAME"
        post_body=$(jq -n \
            --arg content "$MESSAGE" \
            --arg username "$USERNAME" \
            --arg thread_name "$thread_name" \
            '{content: $content, username: $username, thread_name: $thread_name}')
    else
        post_body=$(jq -n \
            --arg content "$MESSAGE" \
            --arg username "$USERNAME" \
            '{content: $content, username: $username}')
    fi

    response=$(curl -s \
        --connect-timeout 10 \
        --max-time 15 \
        -X POST "${WEBHOOK_URL}?wait=true" \
        -H "Content-Type: application/json" \
        -d "$post_body" \
        2>/dev/null)

    msg_id=$(echo "$response" | jq -r '.id // empty' 2>/dev/null)
    if [[ -n "$msg_id" ]]; then
        log "OK: posted to #$CHANNEL (msg_id: $msg_id)"
        echo "$msg_id"
    else
        error=$(echo "$response" | jq -r '.message // "unknown error"' 2>/dev/null)
        log "ERROR: post to #$CHANNEL failed: $error"
        exit 1
    fi
    ;;

# ─── EDIT ────────────────────────────────────────────────────────────────
edit)
    CHANNEL="${1:-}"
    MSG_ID="${2:-}"
    NEW_CONTENT="${3:-}"

    if [[ -z "$CHANNEL" || -z "$MSG_ID" || -z "$NEW_CONTENT" ]]; then
        echo "Usage: discord-post.sh edit <channel-slug> <message-id> <new-content>" >&2
        exit 1
    fi

    WEBHOOK_URL=$(get_webhook_url "$CHANNEL") || {
        log "SKIP: no webhook for channel '$CHANNEL' (edit)"
        exit 0
    }

    if [[ ${#NEW_CONTENT} -gt 1950 ]]; then
        NEW_CONTENT="${NEW_CONTENT:0:1950}… (truncated)"
    fi

    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 \
        --max-time 15 \
        -X PATCH "${WEBHOOK_URL}/messages/${MSG_ID}" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg content "$NEW_CONTENT" \
            '{content: $content}')" \
        2>/dev/null)

    if [[ "$http_code" == "200" ]]; then
        log "OK: edited msg $MSG_ID in #$CHANNEL"
    else
        log "ERROR: edit msg $MSG_ID in #$CHANNEL returned HTTP $http_code"
        exit 1
    fi
    ;;

*)
    echo "Usage: discord-post.sh {post|edit} [args...]" >&2
    exit 1
    ;;
esac
