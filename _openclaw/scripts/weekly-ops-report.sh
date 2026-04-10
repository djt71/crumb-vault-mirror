#!/usr/bin/env bash
# weekly-ops-report.sh — Generate weekly ops metrics report from JSONL log
#
# Source: tess-operations action-plan M0.4 (TOP-050)
#
# Reads _openclaw/logs/ops-metrics.jsonl and computes:
#   - Daily cost breakdown
#   - Alert count
#   - Job success rate per job_id
#   - Total wall time
#
# Usage: bash weekly-ops-report.sh [DAYS]
#   DAYS defaults to 7
#
# Output: Markdown report to stdout.
# Archive: bash weekly-ops-report.sh > _openclaw/state/reports/weekly-$(date +%Y%m%d).md

set -eu

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

VAULT_ROOT="/Users/tess/crumb-vault"
METRICS_LOG="$VAULT_ROOT/_openclaw/logs/ops-metrics.jsonl"
DAYS=${1:-7}

if [[ ! -f "$METRICS_LOG" ]]; then
    echo "No metrics log found at $METRICS_LOG"
    exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not found in PATH" >&2
    exit 1
fi

# Compute cutoff date (BSD date syntax — macOS only)
CUTOFF=$(date -v-${DAYS}d -u +"%Y-%m-%dT%H:%M:%SZ")

echo "# Tess Operations — Weekly Report"
echo ""
echo "**Period:** $(date -v-${DAYS}d +%Y-%m-%d) to $(date +%Y-%m-%d)"
echo "**Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# Filter to period
PERIOD_ENTRIES=$(jq -c "select(.start_time >= \"$CUTOFF\")" "$METRICS_LOG")

if [[ -z "$PERIOD_ENTRIES" ]]; then
    echo "No entries in the last $DAYS days."
    exit 0
fi

# Cost summary
echo "## Cost Summary"
echo ""
echo "| Date | Cost |"
echo "|------|------|"
echo "$PERIOD_ENTRIES" | jq -r '[.start_time[:10], (.cost_estimate | tostring)] | @tsv' | \
    awk -F'\t' '{costs[$1] += $2} END {for (d in costs) printf "| %s | $%.2f |\n", d, costs[d]}' | sort
echo ""

TOTAL_COST=$(echo "$PERIOD_ENTRIES" | jq -r '.cost_estimate' | \
    awk '{sum += $1} END {printf "%.2f", sum}')
echo "**Total cost:** \$$TOTAL_COST"
echo ""

# Alerts
ALERT_COUNT=$(echo "$PERIOD_ENTRIES" | jq -c 'select(.alert_emitted == true)' | wc -l | tr -d ' ')
echo "## Alerts"
echo ""
echo "**Alert count:** $ALERT_COUNT"
echo ""

# Job success rates
echo "## Job Success Rates"
echo ""
echo "| Job | Total | Success | Failure | Rate |"
echo "|-----|-------|---------|---------|------|"
echo "$PERIOD_ENTRIES" | jq -r '[.job_id, .status] | @tsv' | \
    awk -F'\t' '{
        total[$1]++
        if ($2 == "success") success[$1]++
        else fail[$1]++
    } END {
        for (j in total) {
            s = (j in success) ? success[j] : 0
            f = (j in fail) ? fail[j] : 0
            rate = (total[j] > 0) ? (s / total[j] * 100) : 0
            printf "| %s | %d | %d | %d | %.0f%% |\n", j, total[j], s, f, rate
        }
    }' | sort
echo ""

# Wall time
TOTAL_WALL=$(echo "$PERIOD_ENTRIES" | jq -r '.wall_time_seconds' | \
    awk '{sum += $1} END {printf "%d", sum}')
echo "**Total wall time:** ${TOTAL_WALL}s ($((TOTAL_WALL / 60))m)"
