#!/usr/bin/env bash
# ops-metrics-rollup.sh — Aggregate ops-metrics.jsonl into ops-metrics.json
#
# Source: mission-control MC-060 (LLM telemetry investigation)
#
# Reads the append-only JSONL written by cron-lib.sh and produces
# the JSON file that the dashboard ops-metrics.ts adapter expects.
#
# Output shape:
#   { jobs: [{name, runs, successes, failures, totalCost, lastRun}],
#     totalCostToday, totalCostWeek, costCeiling, lastUpdated }
#
# Schedule: Called by dashboard API startup hook or launchd interval.
# No lock needed — atomic write via temp+rename.

set -eu

VAULT_ROOT="/Users/tess/crumb-vault"
METRICS_JSONL="$VAULT_ROOT/_openclaw/logs/ops-metrics.jsonl"
OUTPUT_FILE="$VAULT_ROOT/_system/logs/ops-metrics.json"
COST_CEILING=5.00

if [[ ! -f "$METRICS_JSONL" ]]; then
    echo "No ops-metrics.jsonl found" >&2
    exit 1
fi

now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
today=$(date -u +"%Y-%m-%d")
week_ago_epoch=$(( $(date +%s) - 604800 ))
week_ago_iso=$(date -u -j -f "%s" "$week_ago_epoch" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "@$week_ago_epoch" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

# jq does all the heavy lifting in a single pass
jq -n -c \
    --arg today "$today" \
    --arg week_ago "$week_ago_iso" \
    --arg now "$now_iso" \
    --argjson ceiling "$COST_CEILING" \
    --slurpfile entries "$METRICS_JSONL" '

# Group entries by job_id
($entries | group_by(.job_id)) as $groups |

# Build per-job summaries
[
  $groups[] | {
    name: .[0].job_id,
    runs: length,
    successes: [.[] | select(.status == "success")] | length,
    failures: [.[] | select(.status == "failure")] | length,
    totalCost: ([.[].cost_estimate] | add // 0),
    lastRun: (sort_by(.end_time) | last | .end_time)
  }
] as $jobs |

# Cost aggregations
($entries | [.[] | select(.start_time | startswith($today))] | [.[].cost_estimate] | add // 0) as $costToday |
($entries | [.[] | select(.start_time > $week_ago)] | [.[].cost_estimate] | add // 0) as $costWeek |

{
  jobs: $jobs,
  totalCostToday: $costToday,
  totalCostWeek: $costWeek,
  costCeiling: $ceiling,
  lastUpdated: $now
}
' > "${OUTPUT_FILE}.tmp"

mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
