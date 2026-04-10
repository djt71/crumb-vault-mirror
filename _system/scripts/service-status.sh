#!/usr/bin/env bash
# service-status.sh — Queries launchd for defined service set, writes JSON.
# Runs via launchd every 60 seconds.
# Output: _system/logs/service-status.json
set -eu

VAULT_ROOT="${VAULT_ROOT:-/Users/tess/crumb-vault}"
OUTPUT="$VAULT_ROOT/_system/logs/service-status.json"
TMP_OUTPUT="${OUTPUT}.tmp"

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Defined service set (user-domain LaunchAgents)
SERVICES=(
  "ai.openclaw.gateway"
  "ai.openclaw.bridge.watcher"
  "ai.openclaw.fif.attention"
  "ai.openclaw.fif.capture"
  "ai.openclaw.fif.feedback"
  "ai.openclaw.awareness-check"
  "ai.openclaw.health-ping"
  "ai.openclaw.vault-health"
  "com.crumb.dashboard"
  "com.crumb.cloudflared"
  "com.tess.health-check"
  "com.tess.vault-backup"
  "com.tess.backup-status"
)

# Build JSON array of service statuses
entries=""
for label in "${SERVICES[@]}"; do
  # launchctl list output: PID\tLastExitStatus\tLabel
  line=$(launchctl list | grep -E "\\b${label}$" 2>/dev/null || true)

  if [ -z "$line" ] && [ "$label" = "ai.openclaw.gateway" ]; then
    # Gateway runs as LaunchDaemon (system domain) — check via port probe
    if nc -z -w2 127.0.0.1 18789 2>/dev/null; then
      gw_pid=$(pgrep -f "openclaw.*gateway" 2>/dev/null | head -1)
      pid="${gw_pid:-null}"
      exit_status="0"
      state="\"running\""
    else
      pid="null"
      exit_status="null"
      state="\"not_loaded\""
    fi
  elif [ -z "$line" ]; then
    pid="null"
    exit_status="null"
    state="\"not_loaded\""
  else
    raw_pid=$(echo "$line" | awk '{print $1}')
    raw_exit=$(echo "$line" | awk '{print $2}')

    if [ "$raw_pid" = "-" ]; then
      pid="null"
    else
      pid="$raw_pid"
    fi
    exit_status="$raw_exit"

    if [ "$pid" != "null" ]; then
      state="\"running\""
    elif [ "$exit_status" = "0" ]; then
      state="\"idle_ok\""
    else
      state="\"idle_error\""
    fi
  fi

  entry=$(cat << ENTRY
    {
      "label": "$label",
      "pid": $pid,
      "last_exit_status": $exit_status,
      "state": $state
    }
ENTRY
  )

  if [ -n "$entries" ]; then
    entries="$entries,
$entry"
  else
    entries="$entry"
  fi
done

# Write atomically via temp file
cat > "$TMP_OUTPUT" << ENDJSON
{
  "timestamp": "$timestamp",
  "services": [
$entries
  ]
}
ENDJSON

mv "$TMP_OUTPUT" "$OUTPUT"
