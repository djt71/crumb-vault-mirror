#!/usr/bin/env bash
# health-ping.sh — Dead Man's Switch heartbeat for external monitoring
#
# Source: tess-operations action-plan M0.2 (TOP-003)
# Spec: chief-of-staff §14 Week 0 — Dead Man's Switch
#
# Push-model monitoring: pings an external service (health monitor heartbeat URL)
# every N minutes. If pings stop for 2 hours, external service sends SMS/push
# to operator. This script does NOT auto-restart anything.
#
# Checks two signals before pinging:
#   1. Gateway alive (HTTP 200 on loopback:18789)
#   2. Job ran recently (at least one cron job completed within expected window)
#
# Both must pass for the ping to fire. Either failure = ping stops = alert after 2h.
#
# Usage: Run via cron every 15 minutes (4x/hour, well within 2-hour failure window).
#   */15 * * * * /Users/tess/crumb-vault/_openclaw/scripts/health-ping.sh
#
# Setup:
#   1. Create health monitor account (free tier): https://uptimerobot.com
#   2. Add a "Heartbeat" monitor with 2-hour period
#   3. Set HEALTH_PING_URL below to the heartbeat URL
#   4. Configure alert contacts (SMS/push) in health monitor dashboard

set -eu

# === Configuration ===
# Health ping URL — env var takes precedence, falls back to Keychain.
# Supports any push-model monitor (Healthchecks.io, health monitor, etc.)
HEALTH_PING_URL="${TESS_HEALTH_PING_URL:-$(security find-generic-password -a health-ping -s tess-health-ping-url -w 2>/dev/null || echo "")}"

GATEWAY_HOST="127.0.0.1"
GATEWAY_PORT="18789"
GATEWAY_TIMEOUT=5

VAULT_ROOT="/Users/tess/crumb-vault"
METRICS_LOG="$VAULT_ROOT/_openclaw/logs/ops-metrics.jsonl"
# Max age (in seconds) for "job ran recently" — 4 hours (generous; heartbeat runs every 30-60 min)
JOB_MAX_AGE=14400
# Grace period (seconds) — how long after first run before missing/empty metrics is treated as failure
# Once cron jobs have been running for 24h, an empty log means something is wrong
GRACE_PERIOD=86400

LOG_FILE="$VAULT_ROOT/_openclaw/logs/health-ping.log"

# === Logging ===
log() {
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

# === Signal 1: Gateway alive ===
check_gateway() {
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout "$GATEWAY_TIMEOUT" \
        "http://${GATEWAY_HOST}:${GATEWAY_PORT}/" 2>/dev/null) || true

    if [[ "$http_code" == "200" ]]; then
        return 0
    else
        log "FAIL: gateway returned HTTP $http_code (expected 200)"
        return 1
    fi
}

# === Signal 2: Job ran recently ===
check_job_ran() {
    # Before any cron jobs exist (M1), skip this check — gateway-only monitoring
    if [[ ! -f "$METRICS_LOG" ]]; then
        return 0  # No metrics log yet — M0 phase, gateway-only check
    fi

    local last_end_epoch
    last_end_epoch=$(tail -1 "$METRICS_LOG" 2>/dev/null | \
        jq -r '.end_time // empty' 2>/dev/null) || true

    if [[ -z "$last_end_epoch" ]]; then
        # Empty or unparseable — check if the log file is old enough that we should worry
        local file_age_seconds
        file_age_seconds=$(( $(date +%s) - $(stat -f %m "$METRICS_LOG" 2>/dev/null || echo "$(date +%s)") ))
        if [[ "$file_age_seconds" -gt "$GRACE_PERIOD" ]]; then
            log "FAIL: metrics log exists but is empty/corrupt after ${GRACE_PERIOD}s grace period"
            return 1
        fi
        return 0  # Within grace period — don't fail on missing data yet
    fi

    # Convert ISO timestamp to epoch (macOS BSD date)
    local last_epoch
    last_epoch=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_end_epoch" +%s 2>/dev/null) || {
        log "WARN: could not parse last job timestamp: $last_end_epoch"
        return 0  # Parse failure — don't block on format issues
    }

    local now_epoch
    now_epoch=$(date +%s)
    local age=$(( now_epoch - last_epoch ))

    if [[ "$age" -gt "$JOB_MAX_AGE" ]]; then
        log "FAIL: last job ran ${age}s ago (max ${JOB_MAX_AGE}s)"
        return 1
    fi

    return 0
}

# === Ping external monitor ===
send_ping() {
    if [[ -z "$HEALTH_PING_URL" ]]; then
        log "SKIP: no HEALTH_PING_URL configured (set TESS_HEALTH_PING_URL env var)"
        return 0
    fi

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 \
        "$HEALTH_PING_URL" 2>/dev/null) || true

    if [[ "$http_code" == "200" ]]; then
        return 0
    else
        log "WARN: ping to health monitor returned HTTP $http_code"
        return 1
    fi
}

# === Main ===
main() {
    local gateway_ok=true
    local job_ok=true

    check_gateway || gateway_ok=false
    check_job_ran || job_ok=false

    if [[ "$gateway_ok" == "true" && "$job_ok" == "true" ]]; then
        send_ping
        # Only log periodically to avoid log bloat (every ~1 hour = 4th ping)
        local minute
        minute=$(date +%-M)
        if [[ "$minute" -lt 15 ]]; then
            log "OK: both signals healthy, ping sent"
        fi
    else
        log "ALERT_SUPPRESSED: gateway=$gateway_ok job_ran=$job_ok — NOT pinging (external monitor will alert)"
    fi
}

main
