#!/usr/bin/env bash
# cron-lib.sh — Shared infrastructure for all Tess operational cron jobs
#
# Sources:
#   tess-operations chief-of-staff spec §13 (kill-switch)
#   tess-operations chief-of-staff spec §11 (per-job token budgets)
#   tess-operations action-plan M0.4 (ops metrics), M0.5 (cron guardrails)
#
# Usage:
#   source "/Users/tess/crumb-vault/_openclaw/scripts/cron-lib.sh"
#   cron_init "morning-briefing" --wall-time 900
#   # ... do work ...
#   cron_set_tokens 1500 800
#   cron_set_cost "0.03"
#   cron_finish 0

set -eu

# === Constants ===
readonly VAULT_ROOT="/Users/tess/crumb-vault"
readonly OC_HOME="/Users/openclaw"
readonly OC_CONFIG_DIR="$OC_HOME/.openclaw"
readonly BRIDGE_DIR="$VAULT_ROOT/_openclaw"
readonly KILL_SWITCH_FILE="$OC_CONFIG_DIR/maintenance"
readonly LOCK_DIR="/tmp/openclaw-cron-locks"
readonly METRICS_LOG="$BRIDGE_DIR/logs/ops-metrics.jsonl"
readonly LAST_RUN_DIR="$BRIDGE_DIR/state/last-run"

# === Internal State ===
_CRON_JOB_ID=""
_CRON_START_TIME=""
_CRON_START_EPOCH=""
_CRON_WALL_TIME_PID=""
_CRON_TOKENS_IN=0
_CRON_TOKENS_OUT=0
_CRON_TOOL_CALLS=0
_CRON_COST_ESTIMATE="0.00"
_CRON_ALERT_EMITTED=false
_CRON_INITIALIZED=false
_CRON_FINISHED=false

# === Kill-Switch ===
# Checks for ~/.openclaw/maintenance file. Exits 0 if in maintenance.
# Can be called standalone (e.g., from heartbeat entry points).
check_kill_switch() {
    if [[ -f "$KILL_SWITCH_FILE" ]]; then
        echo "MAINTENANCE_MODE: kill-switch active at $KILL_SWITCH_FILE" >&2
        if [[ "$_CRON_INITIALIZED" == "true" ]]; then
            _log_metrics "maintenance" 0
            _release_lock
        fi
        exit 0
    fi
}

# === Single-Flight Lock ===
# Uses mkdir for atomic lock acquisition. Detects and recovers stale locks via PID check.
_acquire_lock() {
    local lock_path="$LOCK_DIR/$_CRON_JOB_ID"
    mkdir -p "$LOCK_DIR"

    if ! mkdir "$lock_path" 2>/dev/null; then
        local pid_file="$lock_path/pid"
        if [[ -f "$pid_file" ]]; then
            local old_pid
            old_pid=$(cat "$pid_file")
            if ! kill -0 "$old_pid" 2>/dev/null; then
                # Stale lock — previous process died
                rm -rf "$lock_path"
                if mkdir "$lock_path" 2>/dev/null; then
                    echo $$ > "$lock_path/pid"
                    return 0
                fi
            fi
        fi
        echo "LOCK_HELD: $lock_path (another instance running)" >&2
        return 1
    fi

    echo $$ > "$lock_path/pid"
    return 0
}

_release_lock() {
    local lock_path="$LOCK_DIR/$_CRON_JOB_ID"
    rm -rf "$lock_path" 2>/dev/null || true
}

# === Wall Time ===
# Spawns a background watchdog that kills the main process after max_seconds.
_set_wall_time() {
    local max_seconds=$1
    if [[ "$max_seconds" -gt 0 ]]; then
        local main_pid=$$
        (
            sleep "$max_seconds"
            echo "WALL_TIME_EXCEEDED: ${max_seconds}s for $_CRON_JOB_ID — killing pid $main_pid" >&2
            kill -TERM "$main_pid" 2>/dev/null
        ) &
        _CRON_WALL_TIME_PID=$!
    fi
}

_clear_wall_time() {
    if [[ -n "$_CRON_WALL_TIME_PID" ]]; then
        kill "$_CRON_WALL_TIME_PID" 2>/dev/null || true
        wait "$_CRON_WALL_TIME_PID" 2>/dev/null || true
        _CRON_WALL_TIME_PID=""
    fi
}

# === Missed-Run Detection ===
# Returns 0 if the job should run, 1 if it should skip.
# max_age_hours: if last run was more than this many hours ago, skip the catch-up.
_check_missed_run() {
    local max_age_hours=${1:-0}

    # No max age — always run
    [[ "$max_age_hours" -eq 0 ]] && return 0

    mkdir -p "$LAST_RUN_DIR"
    local last_run_file="$LAST_RUN_DIR/$_CRON_JOB_ID"

    if [[ ! -f "$last_run_file" ]]; then
        return 0  # First run — proceed
    fi

    local last_epoch
    last_epoch=$(cat "$last_run_file")
    local now_epoch
    now_epoch=$(date +%s)
    local age_hours=$(( (now_epoch - last_epoch) / 3600 ))

    if [[ "$age_hours" -gt "$max_age_hours" ]]; then
        echo "MISSED_RUN_SKIP: last run ${age_hours}h ago, max catch-up ${max_age_hours}h — skipping" >&2
        return 1
    fi

    return 0
}

_record_last_run() {
    mkdir -p "$LAST_RUN_DIR"
    date +%s > "$LAST_RUN_DIR/$_CRON_JOB_ID"
}

# === Jitter ===
# Adds random delay up to max_seconds. Reduces thundering herd on non-time-sensitive jobs.
_apply_jitter() {
    local max_seconds=$1
    if [[ "$max_seconds" -gt 0 ]]; then
        local jitter=$(( RANDOM % max_seconds ))
        sleep "$jitter"
    fi
}

# === Metrics Logging ===
# Appends a JSONL entry to the ops metrics log.
_log_metrics() {
    local status=$1
    local exit_code=${2:-0}
    local end_time
    end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local end_epoch
    end_epoch=$(date +%s)
    local wall_time_seconds=$(( end_epoch - _CRON_START_EPOCH ))

    mkdir -p "$(dirname "$METRICS_LOG")"

    jq -n -c \
        --arg job_id "$_CRON_JOB_ID" \
        --arg start_time "$_CRON_START_TIME" \
        --arg end_time "$end_time" \
        --arg status "$status" \
        --argjson tokens_in "$_CRON_TOKENS_IN" \
        --argjson tokens_out "$_CRON_TOKENS_OUT" \
        --argjson tool_calls "$_CRON_TOOL_CALLS" \
        --argjson exit_code "$exit_code" \
        --argjson alert_emitted "$_CRON_ALERT_EMITTED" \
        --argjson cost_estimate "$_CRON_COST_ESTIMATE" \
        --argjson wall_time_seconds "$wall_time_seconds" \
        '{job_id: $job_id, start_time: $start_time, end_time: $end_time, status: $status, tokens_in: $tokens_in, tokens_out: $tokens_out, tool_calls: $tool_calls, exit_code: $exit_code, alert_emitted: $alert_emitted, cost_estimate: $cost_estimate, wall_time_seconds: $wall_time_seconds}' \
        >> "$METRICS_LOG"
}

# === Cleanup Trap ===
# Handles unexpected exit: logs metrics as "interrupted", releases lock.
_cron_cleanup() {
    local exit_code=$?
    _clear_wall_time
    if [[ "$_CRON_INITIALIZED" == "true" && "$_CRON_FINISHED" == "false" ]]; then
        _CRON_FINISHED=true
        _log_metrics "interrupted" "$exit_code"
        _release_lock
        _CRON_INITIALIZED=false
    fi
}

# Signal handler for TERM/INT — runs cleanup then actually exits.
# Without this, bash continues execution after the trap handler.
_cron_signal_handler() {
    _cron_cleanup
    exit 143  # 128 + 15 (SIGTERM)
}

# ===========================================================================
# Public API
# ===========================================================================

# Initialize cron job context.
# Checks kill-switch, missed-run, acquires lock, applies jitter, sets wall time.
#
# Usage: cron_init "job-id" --wall-time 900 [--jitter 30] [--max-catchup-hours 4]
#
# Options:
#   --wall-time SECONDS       Max execution time before forced kill (0 = no limit)
#   --jitter SECONDS          Random delay before starting (0 = no jitter)
#   --max-catchup-hours HOURS Skip if last run was more than N hours ago (0 = always run)
cron_init() {
    _CRON_JOB_ID="$1"
    shift

    # Validate job-id: alphanumeric, hyphens, underscores only — no path traversal
    if [[ ! "$_CRON_JOB_ID" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
        echo "cron_init: invalid job-id '$_CRON_JOB_ID' (must match ^[a-z0-9][a-z0-9_-]*$)" >&2
        return 1
    fi

    local wall_time=0
    local jitter=0
    local max_catchup=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --wall-time) wall_time="$2"; shift 2 ;;
            --jitter) jitter="$2"; shift 2 ;;
            --max-catchup-hours) max_catchup="$2"; shift 2 ;;
            *) echo "cron_init: unknown option $1" >&2; return 1 ;;
        esac
    done

    # 1. Kill-switch
    check_kill_switch

    # 2. Missed-run check (before lock — don't hold lock just to skip)
    if ! _check_missed_run "$max_catchup"; then
        exit 0
    fi

    # 3. Acquire single-flight lock
    if ! _acquire_lock; then
        exit 0
    fi

    # 4. Jitter (after lock — holds lock during jitter to prevent races)
    _apply_jitter "$jitter"

    # 5. Record start time
    _CRON_START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    _CRON_START_EPOCH=$(date +%s)
    _CRON_INITIALIZED=true

    # 6. Wall time watchdog
    _set_wall_time "$wall_time"

    # 7. Cleanup trap — EXIT for abnormal exits, signal handler for TERM/INT
    trap _cron_cleanup EXIT
    trap _cron_signal_handler TERM INT
}

# Set token usage (call before cron_finish).
cron_set_tokens() {
    _CRON_TOKENS_IN=${1:-0}
    _CRON_TOKENS_OUT=${2:-0}
}

# Set tool call count.
cron_set_tool_calls() {
    _CRON_TOOL_CALLS=${1:-0}
}

# Set cost estimate (string, e.g. "0.03").
cron_set_cost() {
    _CRON_COST_ESTIMATE="${1:-0.00}"
}

# Mark that an alert was emitted during this run.
cron_mark_alert() {
    _CRON_ALERT_EMITTED=true
}

# Finish the cron job: log metrics, release lock, record last-run, exit.
# Usage: cron_finish [exit_code]
cron_finish() {
    local exit_code=${1:-0}

    # Guard: if signal handler already cleaned up, just exit
    if [[ "$_CRON_FINISHED" == "true" ]]; then
        exit "$exit_code"
    fi

    _CRON_FINISHED=true
    _clear_wall_time

    local status="success"
    [[ "$exit_code" -ne 0 ]] && status="failure"

    _log_metrics "$status" "$exit_code"
    _record_last_run
    _release_lock
    _CRON_INITIALIZED=false

    trap - EXIT TERM INT
    exit "$exit_code"
}
