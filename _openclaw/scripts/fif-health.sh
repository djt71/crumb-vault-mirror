#!/usr/bin/env bash
# fif-health.sh — Feed-intel pipeline health checker
# Called by mechanic heartbeat and morning briefing.
# Checks 7 signals per tess-feed-intel-ownership-proposal.md §5.
# Outputs alert lines or "FIF_OK" if all healthy.

set -eu

DB="/Users/tess/openclaw/feed-intel-framework/state/pipeline.db"
# Monitoring threshold from tess-feed-intel-ownership-proposal.md §3.9.
# This is the governance cap for full Tess ownership (TOP-045), not an
# active enforcement cap. TOP-044 is monitoring-only — alerts here are
# early warnings, not pause triggers. Enforcement lives in TOP-045.
DAILY_CAP="1.50"

alerts=()

# Helper: convert ISO 8601 timestamp to epoch seconds (macOS date)
iso_to_epoch() {
  local ts="${1%%.*}"
  ts="${ts%Z}"
  date -j -f "%Y-%m-%dT%H:%M:%S" "$ts" +%s 2>/dev/null || echo 0
}

hours_since() {
  local epoch="$1"
  local now
  now=$(date +%s)
  echo $(( (now - epoch) / 3600 ))
}

# Verify DB exists
if [[ ! -f "$DB" ]]; then
  echo "FIF_CRITICAL: Pipeline database not found at $DB"
  exit 0
fi

# 1. last_capture_run_at — >25 hours since last successful capture
last_capture=$(sqlite3 "$DB" "SELECT MAX(run_at) FROM adapter_runs WHERE component IN ('curated','discovery') AND status IN ('success','partial');")
if [[ -n "$last_capture" ]]; then
  capture_epoch=$(iso_to_epoch "$last_capture")
  h=$(hours_since "$capture_epoch")
  if [[ $h -gt 25 ]]; then
    alerts+=("CAPTURE_STALE: Last successful capture ${h}h ago (threshold: 25h)")
  fi
else
  alerts+=("CAPTURE_STALE: No successful capture runs found")
fi

# 2. last_attention_run_at — >25 hours since last triage
last_triage=$(sqlite3 "$DB" "SELECT MAX(triaged_at) FROM posts WHERE triaged_at IS NOT NULL;")
if [[ -n "$last_triage" ]]; then
  triage_epoch=$(iso_to_epoch "$last_triage")
  h=$(hours_since "$triage_epoch")
  if [[ $h -gt 25 ]]; then
    alerts+=("ATTENTION_STALE: Last triage ${h}h ago (threshold: 25h)")
  fi
else
  alerts+=("ATTENTION_STALE: No triaged items found")
fi

# 3. queue_depth — >50 items pending/deferred
queue_depth=$(sqlite3 "$DB" "SELECT COUNT(*) FROM posts WHERE queue_status IN ('pending','triage_deferred');")
if [[ $queue_depth -gt 50 ]]; then
  alerts+=("QUEUE_DEEP: ${queue_depth} items pending/deferred (threshold: 50)")
fi

# 4. last_successful_delivery_at — >25 hours since last vault routing
last_routed=$(sqlite3 "$DB" "SELECT MAX(routed_at) FROM posts WHERE routed_at IS NOT NULL;")
if [[ -n "$last_routed" ]]; then
  routed_epoch=$(iso_to_epoch "$last_routed")
  h=$(hours_since "$routed_epoch")
  if [[ $h -gt 25 ]]; then
    alerts+=("DELIVERY_STALE: Last vault routing ${h}h ago (threshold: 25h)")
  fi
fi

# 5. last_processed_feedback_at — >48 hours if unprocessed feedback exists
pending_fb=$(sqlite3 "$DB" "SELECT COUNT(*) FROM feedback WHERE applied = 0;")
if [[ $pending_fb -gt 0 ]]; then
  oldest_fb=$(sqlite3 "$DB" "SELECT MIN(received_at) FROM feedback WHERE applied = 0;")
  if [[ -n "$oldest_fb" ]]; then
    fb_epoch=$(iso_to_epoch "$oldest_fb")
    h=$(hours_since "$fb_epoch")
    if [[ $h -gt 48 ]]; then
      alerts+=("FEEDBACK_STALE: ${pending_fb} unprocessed feedback, oldest ${h}h ago (threshold: 48h)")
    fi
  fi
fi

# 6. error_rate_by_adapter — >3 consecutive failures per adapter
failing=$(sqlite3 "$DB" "SELECT source_type FROM (SELECT source_type, status, ROW_NUMBER() OVER (PARTITION BY source_type ORDER BY run_at DESC) as rn FROM adapter_runs) WHERE rn <= 3 AND status = 'failed' GROUP BY source_type HAVING COUNT(*) >= 3;")
if [[ -n "$failing" ]]; then
  adapters=$(echo "$failing" | tr '\n' ', ' | sed 's/,$//')
  alerts+=("ADAPTER_FAILING: 3+ consecutive failures: ${adapters}")
fi

# 7. daily_token_spend — exceeds $1.50 daily cap
daily_spend=$(sqlite3 "$DB" "SELECT COALESCE(SUM(estimated_cost), 0) FROM cost_log WHERE run_at >= date('now', 'start of day');")
over_cap=$(awk "BEGIN {print ($daily_spend > $DAILY_CAP) ? 1 : 0}")
if [[ "$over_cap" == "1" ]]; then
  alerts+=("COST_CAP: Daily spend \$${daily_spend} exceeds \$${DAILY_CAP} cap")
fi

# Output
if [[ ${#alerts[@]} -eq 0 ]]; then
  echo "FIF_OK"
else
  for alert in "${alerts[@]}"; do
    echo "$alert"
  done
fi
