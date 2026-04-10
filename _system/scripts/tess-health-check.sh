#!/usr/bin/env bash
# tess-health-check.sh — Limited Mode entry/exit monitor
#
# Pings Anthropic API every 5 minutes. On 3 consecutive failures,
# swaps voice agent to local model (Limited Mode). On recovery,
# swaps back. Sends Telegram notifications.
#
# Designed for TMA-004 Limited Mode Protocol.
# Run via launchd (see design/com.tess.health-check.plist).
#
# COMPATIBILITY: Must work with /bin/bash 3.2 (macOS system bash).
# Do NOT use bash 4+ features (associative arrays, &>> redirection,
# nameref, mapfile, etc.).
#
# PERMISSIONS: Runs as tess under launchd. Uses `sudo -u openclaw`
# (NOPASSWD via sudoers) for openclaw file operations. Gateway restart
# (launchctl kickstart system/) requires a dedicated sudoers entry:
#
#   tess ALL=(root) NOPASSWD: /bin/launchctl kickstart -k system/ai.openclaw.gateway
#   tess ALL=(root) NOPASSWD: /bin/launchctl kickstart system/ai.openclaw.gateway

set -eu

# --- Configuration ---
ENV_FILE="${TESS_HEALTHCHECK_ENV:-/Users/tess/.config/tess/health-check.env}"
STATE_FILE="/tmp/tess-health-check.state"
LOG_FILE="/Users/tess/crumb-vault/_system/logs/health-check.log"
OPENCLAW_CONFIG="/Users/openclaw/.openclaw/openclaw.json"
OPENCLAW_WORKSPACE="/Users/openclaw/.openclaw/workspace"
GATEWAY_SERVICE="system/ai.openclaw.gateway"

NORMAL_MODEL="anthropic/claude-haiku-4-5"
FALLBACK_MODEL="ollama/tess-mechanic:30b"
MAX_FAILURES=3
MIN_RECOVERY=2
ESCALATION_HOURS=4

# --- Load credentials ---
# Anthropic API key from env file
if [[ ! -f "$ENV_FILE" ]]; then
  echo "$(date -Iseconds) ERROR: env file not found: $ENV_FILE" >> "$LOG_FILE"
  exit 1
fi
# shellcheck source=/dev/null
source "$ENV_FILE"

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "$(date -Iseconds) ERROR: ANTHROPIC_API_KEY not set in $ENV_FILE" >> "$LOG_FILE"
  exit 1
fi

# Telegram credentials from Keychain (shared with x-feed-intel)
TELEGRAM_BOT_TOKEN=$(security find-generic-password -a x-feed-intel -s x-feed-intel.telegram-bot-token -w 2>/dev/null) || true
TELEGRAM_CHAT_ID=$(security find-generic-password -a x-feed-intel -s x-feed-intel.telegram-chat-id -w 2>/dev/null) || true

# Validate Keychain lookups (bash 3.2 compatible — no associative arrays)
for var in TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID; do
  if [[ -z "${!var:-}" ]]; then
    case "$var" in
      TELEGRAM_BOT_TOKEN) svc="x-feed-intel.telegram-bot-token" ;;
      TELEGRAM_CHAT_ID)   svc="x-feed-intel.telegram-chat-id" ;;
    esac
    echo "$(date -Iseconds) ERROR: $var not found in Keychain (service: $svc)" >> "$LOG_FILE"
    exit 1
  fi
done

# --- Helper: write a file as the openclaw user ---
# Copies $1 (temp file owned by tess) to $2 (target owned by openclaw).
# Makes source world-readable so openclaw can read it, then cleans up.
write_as_openclaw() {
  local src="$1" dst="$2"
  chmod 644 "$src"
  sudo -u openclaw bash -c "export HOME=/Users/openclaw && cp '$src' '$dst'"
  rm -f "$src"
}

# --- State management ---
init_state() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "mode=normal" > "$STATE_FILE"
    echo "failures=0" >> "$STATE_FILE"
    echo "recovery_count=0" >> "$STATE_FILE"
    echo "entered_limited=" >> "$STATE_FILE"
    echo "last_escalation=" >> "$STATE_FILE"
  fi
}

read_state() {
  # shellcheck source=/dev/null
  source "$STATE_FILE"
}

write_state() {
  cat > "$STATE_FILE" <<EOF
mode=$mode
failures=$failures
recovery_count=${recovery_count:-0}
entered_limited=$entered_limited
last_escalation=$last_escalation
EOF
}

# --- Logging ---
log() {
  echo "$(date -Iseconds) $1" >> "$LOG_FILE"
}

# --- Port check (no sudo required) ---
check_gateway_port() {
  nc -z -w 5 127.0.0.1 18789 2>/dev/null
}

# --- Anthropic API health check ---
check_anthropic() {
  # Minimal completion request — cheapest possible probe
  local response
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 30 \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"ping"}]}' \
    "https://api.anthropic.com/v1/messages" 2>/dev/null) || http_code="000"

  case "$http_code" in
    200) return 0 ;;  # Success
    400) return 0 ;;  # Bad request = API is up, config issue
    401|403) return 0 ;;  # Auth error = API is up, credential issue
    *)   return 1 ;;  # 429 (long), 500, 503, timeout, connection refused
  esac
}

# --- Telegram notification ---
send_telegram() {
  local text="$1"
  curl -s -o /dev/null \
    --max-time 10 \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${text}" \
    -d "parse_mode=HTML" 2>/dev/null || log "WARN: Telegram notification failed"
}

# --- Config swap ---
enter_limited_mode() {
  log "ACTION: entering Limited Mode"

  # 1. Swap voice primary model in openclaw.json
  local tmp_config
  tmp_config=$(mktemp)
  sudo -u openclaw bash -c "export HOME=/Users/openclaw && cat '$OPENCLAW_CONFIG'" | \
    jq --arg fallback "$FALLBACK_MODEL" \
    '(.agents.list[] | select(.id == "voice") | .model.primary) = $fallback' \
    > "$tmp_config"

  if [[ ! -s "$tmp_config" ]]; then
    log "ERROR: jq config swap produced empty file — aborting"
    rm -f "$tmp_config"
    return 1
  fi

  # Validate JSON before applying (v2026.2.25 hardened config validation on startup)
  if ! jq . "$tmp_config" >/dev/null 2>&1; then
    log "ERROR: jq config swap produced invalid JSON — aborting"
    rm -f "$tmp_config"
    return 1
  fi

  sudo -u openclaw bash -c "export HOME=/Users/openclaw && cp '$OPENCLAW_CONFIG' '${OPENCLAW_CONFIG}.pre-limited'"
  write_as_openclaw "$tmp_config" "$OPENCLAW_CONFIG"

  # 2. Swap SOUL.md to Limited Mode prompt in workspace
  if [[ -f "$OPENCLAW_WORKSPACE/SOUL.md" ]]; then
    sudo -u openclaw bash -c "export HOME=/Users/openclaw && cp '$OPENCLAW_WORKSPACE/SOUL.md' '$OPENCLAW_WORKSPACE/SOUL.md.normal'"
  fi
  local tmp_soul
  tmp_soul=$(mktemp)
  cat > "$tmp_soul" <<'LIMITEDSOUL'
You are Tess, operating in limited local mode. Your cloud connection is temporarily unavailable.

ALLOWED:
- Capture and acknowledge incoming messages
- Triage requests by urgency (flag anything time-sensitive)
- Answer direct factual questions from vault content
- Run read-only vault queries
- Report system status when asked

NOT ALLOWED:
- Give advice or make recommendations
- Use humor, personality, or second register
- Execute multi-step plans or complex decisions
- Initiate destructive operations or state changes
- Compose original content (drafts, summaries with judgment)

Keep responses short and factual. Acknowledge what you captured.
If something needs the full Tess, say so: "Captured — I'll handle this properly when cloud is restored."
LIMITEDSOUL
  write_as_openclaw "$tmp_soul" "$OPENCLAW_WORKSPACE/SOUL.md"

  # 3. Restart gateway (requires sudoers NOPASSWD entry — see file header)
  sudo launchctl kickstart -k "$GATEWAY_SERVICE" 2>/dev/null || {
    log "ERROR: launchctl kickstart failed — check sudoers NOPASSWD entry for tess"
  }
  sleep 5

  # 4. Verify gateway is back
  if check_gateway_port; then
    log "ACTION: gateway restarted successfully in Limited Mode"
  else
    log "ERROR: gateway did not restart after Limited Mode swap"
  fi

  # 5. Send notification
  send_telegram "⚠ Tess is in limited local mode — cloud connection unavailable.
I can capture messages and check vault content, but responses will be flat and I can't give advice or run complex tasks.
I'll let you know when full mode is restored."

  # 6. Update state
  mode="limited"
  entered_limited="$(date +%s)"
  last_escalation=""
  write_state
  log "STATE: Limited Mode active"
}

exit_limited_mode() {
  log "ACTION: exiting Limited Mode"

  # 1. Swap voice primary model back
  local tmp_config
  tmp_config=$(mktemp)
  sudo -u openclaw bash -c "export HOME=/Users/openclaw && cat '$OPENCLAW_CONFIG'" | \
    jq --arg normal "$NORMAL_MODEL" \
    '(.agents.list[] | select(.id == "voice") | .model.primary) = $normal' \
    > "$tmp_config"

  if [[ ! -s "$tmp_config" ]]; then
    log "ERROR: jq config restore produced empty file — aborting"
    rm -f "$tmp_config"
    return 1
  fi

  # Validate JSON before applying (v2026.2.25 hardened config validation on startup)
  if ! jq . "$tmp_config" >/dev/null 2>&1; then
    log "ERROR: jq config restore produced invalid JSON — aborting"
    rm -f "$tmp_config"
    return 1
  fi

  write_as_openclaw "$tmp_config" "$OPENCLAW_CONFIG"

  # 2. Restore SOUL.md
  if [[ -f "$OPENCLAW_WORKSPACE/SOUL.md.normal" ]]; then
    sudo -u openclaw bash -c "export HOME=/Users/openclaw && cp '$OPENCLAW_WORKSPACE/SOUL.md.normal' '$OPENCLAW_WORKSPACE/SOUL.md'"
    sudo -u openclaw bash -c "export HOME=/Users/openclaw && rm -f '$OPENCLAW_WORKSPACE/SOUL.md.normal'"
    log "ACTION: SOUL.md restored from backup"
  else
    log "WARN: SOUL.md.normal not found — cannot restore identity doc"
  fi

  # Clean up pre-limited backup
  sudo -u openclaw bash -c "export HOME=/Users/openclaw && rm -f '${OPENCLAW_CONFIG}.pre-limited'"

  # 3. Restart gateway (requires sudoers NOPASSWD entry — see file header)
  sudo launchctl kickstart -k "$GATEWAY_SERVICE" 2>/dev/null || {
    log "ERROR: launchctl kickstart failed — check sudoers NOPASSWD entry for tess"
  }
  sleep 5

  # 4. Verify
  if check_gateway_port; then
    log "ACTION: gateway restarted successfully in Normal Mode"
  else
    log "ERROR: gateway did not restart after Normal Mode restore"
  fi

  # 5. Calculate duration
  local duration_s=$(( $(date +%s) - entered_limited ))
  local duration_m=$(( duration_s / 60 ))

  # 6. Send notification
  send_telegram "✓ Cloud restored — full mode active. Limited mode duration: ${duration_m}m."

  # 7. Update state
  mode="normal"
  failures=0
  recovery_count=0
  entered_limited=""
  last_escalation=""
  write_state
  log "STATE: Normal Mode restored (was limited for ${duration_m}m)"
}

# --- Escalation check ---
check_escalation() {
  if [[ "$mode" != "limited" || -z "$entered_limited" ]]; then
    return
  fi

  local now
  now=$(date +%s)
  local duration_h=$(( (now - entered_limited) / 3600 ))

  if (( duration_h >= ESCALATION_HOURS )); then
    local last_esc="${last_escalation:-0}"
    local since_esc=$(( (now - last_esc) / 3600 ))

    if (( last_esc == 0 || since_esc >= ESCALATION_HOURS )); then
      local total_m=$(( (now - entered_limited) / 60 ))
      local remaining_m=$(( total_m - (duration_h * 60) ))
      send_telegram "⚠ Limited mode active for ${duration_h}h${remaining_m}m. Anthropic API has not recovered.
Manual investigation may be needed.
Last health check: $(date -Iseconds) — FAIL"
      last_escalation="$now"
      write_state
      log "ESCALATION: Limited Mode active for ${duration_h}h"
    fi
  fi
}

# --- Main ---
main() {
  mkdir -p "$(dirname "$LOG_FILE")"
  init_state
  read_state

  if check_anthropic; then
    # API is reachable
    if [[ "$mode" == "limited" ]]; then
      recovery_count=$(( ${recovery_count:-0} + 1 ))
      write_state
      if (( recovery_count >= MIN_RECOVERY )); then
        log "CHECK: Anthropic API reachable ($recovery_count/$MIN_RECOVERY) — recovering from Limited Mode"
        exit_limited_mode
      else
        log "CHECK: Anthropic API reachable (recovery $recovery_count/$MIN_RECOVERY — waiting for confirmation)"
      fi
    else
      failures=0
      recovery_count=0
      write_state
    fi
  else
    # API unreachable
    failures=$(( failures + 1 ))
    recovery_count=0
    log "CHECK: Anthropic API unreachable (failure $failures/$MAX_FAILURES)"
    write_state

    if [[ "$mode" == "normal" ]] && (( failures >= MAX_FAILURES )); then
      enter_limited_mode
    elif [[ "$mode" == "limited" ]]; then
      check_escalation
    fi
  fi
}

main "$@"
