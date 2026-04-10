#!/usr/bin/env bash
# email-send.sh — Email send with AID-* gate, rate limits, and domain denylist
#
# Source: tess-operations TOP-037 (email send with technical enforcement)
# Spec: tess-google-services-spec.md §5, §5.1, §7.4
#
# Defense-in-depth:
#   1. AID-* approval required for all sends (wrapper-level gate)
#   2. 5-minute cooldown between approval and execution
#   3. Rate limits: 3/hour, 10/day
#   4. Domain denylist: blocked even with valid approval
#   5. Max 3 recipients per email
#   6. All sends logged to security + audit logs
#
# Draft creation is autonomous (no approval needed).
# Sends always require approval via Approval Contract.
#
# Usage:
#   email-send.sh draft --to "user@example.com" --subject "..." --body "..." [--cc "..."] [--in-reply-to "message_id"]
#   email-send.sh send <draft_id>                    # Request approval to send draft
#   email-send.sh execute <AID>                      # Called by approval-executor after approval + cooldown
#
# Exit: 0 on success, 1 on error
# Output: For draft, prints draft_id. For send, prints AID.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_ROOT="/Users/tess/crumb-vault"
BRIDGE_DIR="$VAULT_ROOT/_openclaw"
LOG_FILE="$BRIDGE_DIR/logs/email-send.log"
SECURITY_LOG="$BRIDGE_DIR/logs/google-security.log"
RATE_FILE="$BRIDGE_DIR/state/email-send-rate.json"
DENYLIST_FILE="$BRIDGE_DIR/config/email-domain-denylist.txt"

source "$BRIDGE_DIR/lib/gws-token.sh"

# Rate limits (spec §5.1)
MAX_PER_HOUR=3
MAX_PER_DAY=10
MAX_RECIPIENTS=3

# Cooldown (spec §5)
SEND_COOLDOWN=300  # 5 minutes

# Gmail label IDs (from label list)
LABEL_APPROVAL="Label_28"  # @Agent/APPROVAL
LABEL_DONE="Label_29"      # @Agent/DONE

# === Logging ===
log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

security_log() {
    mkdir -p "$(dirname "$SECURITY_LOG")"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") SECURITY $1" >> "$SECURITY_LOG"
}

send_alert() {
    local message="$1"
    local bot_token="${TESS_APPROVAL_BOT_TOKEN:-$(security find-generic-password -a tess-bot -s tess-approval-bot-token -w 2>/dev/null || echo "")}"
    [[ -z "$bot_token" ]] && return 0
    curl -s -o /dev/null \
        --connect-timeout 10 --max-time 15 \
        -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
        -d chat_id="7754252365" \
        -d parse_mode="HTML" \
        --data-urlencode text="$message" \
        2>/dev/null || true
}

# === Domain denylist check ===
# Returns 0 if domain is denied, 1 if allowed
check_domain_denied() {
    local email="$1"
    local domain="${email##*@}"
    domain=$(echo "$domain" | tr '[:upper:]' '[:lower:]')

    [[ ! -f "$DENYLIST_FILE" ]] && return 1  # No denylist = allow

    while IFS= read -r line; do
        # Skip comments and blank lines
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        line=$(echo "$line" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        [[ -z "$line" ]] && continue

        # Check for TLD match (e.g., .gov matches anything ending in .gov)
        if [[ "$line" == .* ]]; then
            if [[ "$domain" == *"$line" ]]; then
                return 0  # Denied
            fi
        else
            # Exact domain match
            if [[ "$domain" == "$line" ]]; then
                return 0  # Denied
            fi
        fi
    done < "$DENYLIST_FILE"

    return 1  # Allowed
}

# === Rate limit check ===
# Returns 0 if within limits, 1 if exceeded
check_rate_limit() {
    mkdir -p "$(dirname "$RATE_FILE")"

    if [[ ! -f "$RATE_FILE" ]]; then
        echo '{"sends":[]}' > "$RATE_FILE"
    fi

    local now_epoch
    now_epoch=$(date +%s)
    local hour_ago=$(( now_epoch - 3600 ))
    local day_ago=$(( now_epoch - 86400 ))

    # Count sends in last hour and last day
    local hour_count day_count
    hour_count=$(jq --argjson cutoff "$hour_ago" '[.sends[] | select(. > $cutoff)] | length' "$RATE_FILE")
    day_count=$(jq --argjson cutoff "$day_ago" '[.sends[] | select(. > $cutoff)] | length' "$RATE_FILE")

    if [[ "$hour_count" -ge "$MAX_PER_HOUR" ]]; then
        log "RATE_LIMIT: hourly limit reached ($hour_count/$MAX_PER_HOUR)"
        security_log "RATE_LIMIT_HOURLY: $hour_count/$MAX_PER_HOUR sends in last hour"
        echo "BLOCKED: hourly rate limit ($hour_count/$MAX_PER_HOUR)" >&2
        return 1
    fi

    if [[ "$day_count" -ge "$MAX_PER_DAY" ]]; then
        log "RATE_LIMIT: daily limit reached ($day_count/$MAX_PER_DAY)"
        security_log "RATE_LIMIT_DAILY: $day_count/$MAX_PER_DAY sends in last 24h"
        echo "BLOCKED: daily rate limit ($day_count/$MAX_PER_DAY)" >&2
        return 1
    fi

    return 0
}

# Record a successful send in rate tracker
record_send() {
    local now_epoch
    now_epoch=$(date +%s)
    local day_ago=$(( now_epoch - 86400 ))

    # Append timestamp and prune entries older than 24h
    jq --argjson ts "$now_epoch" --argjson cutoff "$day_ago" \
        '.sends = ([.sends[] | select(. > $cutoff)] + [$ts])' \
        "$RATE_FILE" > "$RATE_FILE.tmp" \
        && mv "$RATE_FILE.tmp" "$RATE_FILE"
}

# === Extract recipients from draft ===
# Returns all To/Cc/Bcc addresses, one per line
extract_recipients() {
    local draft_data="$1"
    echo "$draft_data" | jq -r '
        .message.payload.headers[]
        | select(.name == "To" or .name == "Cc" or .name == "Bcc")
        | .value' | tr ',' '\n' | sed 's/.*<//; s/>.*//' | tr -d ' ' | grep -v '^$'
}

# === Subcommand routing ===
subcmd="${1:-}"
shift || true

case "$subcmd" in

# ─── DRAFT (autonomous — no approval needed) ──────────────────────────────
draft)
    TO=""
    SUBJECT=""
    BODY=""
    CC=""
    IN_REPLY_TO=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --to) TO="$2"; shift 2 ;;
            --subject) SUBJECT="$2"; shift 2 ;;
            --body) BODY="$2"; shift 2 ;;
            --cc) CC="$2"; shift 2 ;;
            --in-reply-to) IN_REPLY_TO="$2"; shift 2 ;;
            *) echo "ERROR: Unknown flag: $1" >&2; exit 1 ;;
        esac
    done

    if [[ -z "$TO" || -z "$SUBJECT" || -z "$BODY" ]]; then
        echo "Usage: email-send.sh draft --to \"user@example.com\" --subject \"...\" --body \"...\" [--cc \"...\"] [--in-reply-to \"message_id\"]" >&2
        exit 1
    fi

    # Build MIME message and base64url-encode it
    raw_message=$(python3 -c "
import base64, sys
from email.mime.text import MIMEText

msg = MIMEText('''$BODY''', 'plain')
msg['To'] = '''$TO'''
msg['Subject'] = '''$SUBJECT'''
msg['From'] = 'dturner71@gmail.com'
cc = '''$CC'''
if cc:
    msg['Cc'] = cc
reply_to = '''$IN_REPLY_TO'''
if reply_to:
    msg['In-Reply-To'] = reply_to
    msg['References'] = reply_to

raw = base64.urlsafe_b64encode(msg.as_bytes()).decode('ascii')
print(raw)
" 2>&1) || {
        log "ERROR: MIME encoding failed"
        echo "ERROR: MIME encoding failed" >&2
        exit 1
    }

    log "DRAFTING: to=$TO subject='$SUBJECT'"

    response=$(gws_gmail_create_draft "$raw_message") || {
        log "ERROR: Gmail API draft creation failed"
        echo "ERROR: Gmail API draft creation failed" >&2
        exit 1
    }

    draft_id=$(echo "$response" | jq -r '.id // empty')
    if [[ -z "$draft_id" ]]; then
        error=$(echo "$response" | jq -r '.error.message // "unknown error"')
        log "ERROR: draft creation failed: $error"
        echo "ERROR: draft creation failed: $error" >&2
        exit 1
    fi

    log "OK: draft created (id: $draft_id, to: $TO)"
    echo "$draft_id"
    ;;

# ─── SEND (request approval to send a draft) ──────────────────────────────
send)
    DRAFT_ID="${1:-}"
    if [[ -z "$DRAFT_ID" ]]; then
        echo "Usage: email-send.sh send <draft_id>" >&2
        exit 1
    fi

    # Fetch draft details
    draft_data=$(gws_gmail_get_draft "$DRAFT_ID") || {
        log "ERROR: failed to fetch draft $DRAFT_ID"
        echo "ERROR: failed to fetch draft" >&2
        exit 1
    }

    draft_error=$(echo "$draft_data" | jq -r '.error.message // empty')
    if [[ -n "$draft_error" ]]; then
        log "ERROR: draft fetch failed: $draft_error"
        echo "ERROR: $draft_error" >&2
        exit 1
    fi

    # Extract headers
    to_addr=$(echo "$draft_data" | jq -r '.message.payload.headers[] | select(.name == "To") | .value' | head -1)
    subject=$(echo "$draft_data" | jq -r '.message.payload.headers[] | select(.name == "Subject") | .value' | head -1)
    cc_addr=$(echo "$draft_data" | jq -r '.message.payload.headers[] | select(.name == "Cc") | .value' | head -1)

    # Pre-flight: domain denylist check on all recipients
    all_recipients=$(extract_recipients "$draft_data")
    recipient_count=$(echo "$all_recipients" | grep -c '.' || true)

    if [[ "$recipient_count" -gt "$MAX_RECIPIENTS" ]]; then
        log "BLOCKED: too many recipients ($recipient_count > $MAX_RECIPIENTS)"
        security_log "RECIPIENT_LIMIT: draft $DRAFT_ID has $recipient_count recipients (max $MAX_RECIPIENTS)"
        echo "BLOCKED: too many recipients ($recipient_count, max $MAX_RECIPIENTS)" >&2
        exit 1
    fi

    while IFS= read -r recipient; do
        [[ -z "$recipient" ]] && continue
        if check_domain_denied "$recipient"; then
            domain="${recipient##*@}"
            log "BLOCKED: denied domain '$domain' for recipient '$recipient'"
            security_log "DOMAIN_DENIED: draft $DRAFT_ID, recipient $recipient, domain $domain"
            send_alert "🚨 <b>Email Send BLOCKED</b>\n\nDenied domain: <code>${domain}</code>\nRecipient: <code>${recipient}</code>\nSubject: ${subject}\nDraft: <code>${DRAFT_ID}</code>\n\n<i>Domain is on the denylist. Send rejected before approval.</i>"
            echo "BLOCKED: recipient domain '$domain' is on the denylist" >&2
            exit 1
        fi
    done <<< "$all_recipients"

    # Pre-flight: rate limit check
    if ! check_rate_limit; then
        send_alert "🚨 <b>Email Send BLOCKED</b>\n\nRate limit exceeded\nDraft: <code>${DRAFT_ID}</code>\nTo: <code>${to_addr}</code>"
        exit 1
    fi

    # Build preview
    snippet=$(echo "$draft_data" | jq -r '.message.snippet // ""' | head -c 300)

    summary="Send email to ${to_addr}"
    [[ -n "$cc_addr" ]] && summary+=", CC: ${cc_addr}"
    summary+="\nSubject: ${subject}"

    log "GATED: send draft $DRAFT_ID to $to_addr — requesting approval"

    payload=$(jq -n -c \
        --arg command "email-send" \
        --arg draft_id "$DRAFT_ID" \
        '{command: $command, draft_id: $draft_id}')

    bash "$SCRIPT_DIR/approval-request.sh" \
        --action-type SEND_EMAIL \
        --service google \
        --target "$to_addr" \
        --summary "$summary" \
        --risk-level medium \
        --cooldown "$SEND_COOLDOWN" \
        --preview "$snippet" \
        --payload "$payload"
    ;;

# ─── EXECUTE (called by approval-executor after approval + cooldown) ──────
execute)
    AID="${1:-}"
    if [[ -z "$AID" ]]; then
        echo "Usage: email-send.sh execute <AID>" >&2
        exit 1
    fi

    # === Gate 1: Approval validation ===
    if ! bash "$SCRIPT_DIR/approval-check.sh" --validate-only "$AID" 2>&1; then
        log "BLOCKED: $AID not approved or cooldown active"
        security_log "UNAUTHORIZED_SEND: $AID failed approval check"
        exit 1
    fi

    APPROVAL_FILE="$BRIDGE_DIR/state/approvals/$AID.json"
    draft_id=$(jq -r '.payload.draft_id // empty' "$APPROVAL_FILE")
    target=$(jq -r '.target' "$APPROVAL_FILE")

    if [[ -z "$draft_id" ]]; then
        log "ERROR: no draft_id in payload for $AID"
        security_log "MISSING_DRAFT: $AID has no draft_id in payload"
        echo "ERROR: no draft_id in payload" >&2
        exit 1
    fi

    # === Gate 2: Re-fetch draft and re-validate recipients ===
    # (draft could have been modified between approval request and execution)
    draft_data=$(gws_gmail_get_draft "$draft_id") || {
        log "ERROR: failed to fetch draft $draft_id for send"
        echo "ERROR: draft fetch failed" >&2
        exit 1
    }

    draft_error=$(echo "$draft_data" | jq -r '.error.message // empty')
    if [[ -n "$draft_error" ]]; then
        log "ERROR: draft $draft_id no longer exists: $draft_error"
        echo "ERROR: draft no longer exists" >&2
        exit 1
    fi

    all_recipients=$(extract_recipients "$draft_data")

    # === Gate 3: Domain denylist (re-check at execution time) ===
    while IFS= read -r recipient; do
        [[ -z "$recipient" ]] && continue
        if check_domain_denied "$recipient"; then
            domain="${recipient##*@}"
            log "BLOCKED: denied domain '$domain' at execution time for $AID"
            security_log "DOMAIN_DENIED_EXEC: $AID, recipient $recipient, domain $domain — BLOCKED even with approval"
            send_alert "🚨 <b>Email Send BLOCKED at Execution</b>\n\nDenied domain: <code>${domain}</code>\nRecipient: <code>${recipient}</code>\nApproval: <code>${AID}</code>\n\n<i>Domain denylist overrides approval. Send rejected.</i>"
            echo "BLOCKED: domain '$domain' is on denylist (overrides approval)" >&2
            exit 1
        fi
    done <<< "$all_recipients"

    # === Gate 4: Rate limit (re-check at execution time) ===
    if ! check_rate_limit; then
        log "BLOCKED: rate limit at execution time for $AID"
        security_log "RATE_LIMIT_EXEC: $AID blocked by rate limit at execution"
        send_alert "🚨 <b>Email Send BLOCKED at Execution</b>\n\nRate limit exceeded\nApproval: <code>${AID}</code>"
        exit 1
    fi

    # === Gate 5: Recipient count (re-check) ===
    recipient_count=$(echo "$all_recipients" | grep -c '.' || true)
    if [[ "$recipient_count" -gt "$MAX_RECIPIENTS" ]]; then
        log "BLOCKED: recipient count $recipient_count > $MAX_RECIPIENTS for $AID"
        security_log "RECIPIENT_LIMIT_EXEC: $AID has $recipient_count recipients"
        exit 1
    fi

    # === All gates passed — send the draft ===
    log "SENDING: draft $draft_id to $target (approved via $AID)"

    send_response=$(gws_gmail_send_draft "$draft_id") || {
        log "ERROR: Gmail API send failed for draft $draft_id"
        security_log "SEND_FAILED: $AID, draft $draft_id — API error"
        echo "ERROR: Gmail API send failed" >&2
        exit 1
    }

    # Check for API errors
    send_error=$(echo "$send_response" | jq -r '.error.message // empty')
    if [[ -n "$send_error" ]]; then
        log "ERROR: send failed: $send_error"
        security_log "SEND_FAILED: $AID, draft $draft_id — $send_error"
        echo "ERROR: send failed: $send_error" >&2
        exit 1
    fi

    message_id=$(echo "$send_response" | jq -r '.id // empty')
    log "OK: email sent (message_id: $message_id, draft: $draft_id, to: $target, approval: $AID)"
    security_log "SEND_OK: $AID, draft $draft_id, message $message_id, to $target"

    # Record in rate tracker
    record_send

    # Mark approval as executed
    bash "$SCRIPT_DIR/approval-check.sh" "$AID" >/dev/null 2>&1 || true
    ;;

*)
    echo "Usage: email-send.sh {draft|send|execute} [args...]" >&2
    exit 1
    ;;
esac
