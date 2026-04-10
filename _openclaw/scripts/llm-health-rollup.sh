#!/usr/bin/env bash
# llm-health-rollup.sh — Generate llm-health.json from available sources
#
# Source: mission-control MC-060 (LLM telemetry investigation)
#
# Builds LLM health status from:
#   1. OpenClaw gateway logs — model/provider from "embedded run start" entries (if any)
#   2. ops-metrics.jsonl — job success/failure rates as proxy for model health
#   3. Known model inventory — static entries for models we know are configured
#
# Output shape (matches dashboard llm-health.ts adapter):
#   { models: [{provider, model, callCount, successRate, p95LatencyMs, lastCall, degradationNotes}],
#     lastUpdated }
#
# Limitation: OpenClaw gateway logs don't include per-call token counts or latency.
# callCount and successRate are derived from job-level metrics, not API calls.
# p95LatencyMs is null until per-call telemetry exists.

set -eu

VAULT_ROOT="/Users/tess/crumb-vault"
METRICS_JSONL="$VAULT_ROOT/_openclaw/logs/ops-metrics.jsonl"
GATEWAY_LOG_DIR="/tmp/openclaw"
OUTPUT_FILE="$VAULT_ROOT/_system/logs/llm-health.json"
FIF_DB="$VAULT_ROOT/../openclaw/feed-intel-framework/state/pipeline.db"

now_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
today=$(date -u +"%Y-%m-%d")

# === Source 1: Gateway logs — scan for model references ===
gateway_models="[]"
today_log="$GATEWAY_LOG_DIR/openclaw-${today}.log"
if [[ -f "$today_log" ]]; then
    # Look for any model/provider references in structured log entries
    gateway_models=$(grep -i '"model"\|"provider"\|embedded.run' "$today_log" 2>/dev/null \
        | jq -s '[.[] | select(."1" | test("embedded run"; "i")) // empty] | length' 2>/dev/null || echo "0")
fi

# === Source 2: ops-metrics.jsonl — derive model health from job stats ===
cron_health="[]"
if [[ -f "$METRICS_JSONL" ]]; then
    week_ago_epoch=$(( $(date +%s) - 604800 ))
    week_ago_iso=$(date -u -j -f "%s" "$week_ago_epoch" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "@$week_ago_epoch" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

    cron_health=$(jq -n -c \
        --arg week_ago "$week_ago_iso" \
        --slurpfile entries "$METRICS_JSONL" '
        $entries | [.[] | select(.start_time > $week_ago)] |
        if length == 0 then {total: 0, successes: 0, failures: 0, lastRun: null}
        else {
            total: length,
            successes: ([.[] | select(.status == "success")] | length),
            failures: ([.[] | select(.status == "failure")] | length),
            lastRun: (sort_by(.end_time) | last | .end_time)
        } end
    ')
fi

# === Source 3: FIF database — check if pipeline is active ===
fif_active=false
fif_last_run=""
fif_runs=0
if [[ -f "$FIF_DB" ]] && command -v sqlite3 &>/dev/null; then
    fif_runs=$(sqlite3 "$FIF_DB" "SELECT COUNT(*) FROM cost_log WHERE run_at >= datetime('now', '-7 days');" 2>/dev/null || echo "0")
    fif_last_run=$(sqlite3 "$FIF_DB" "SELECT MAX(run_at) FROM cost_log;" 2>/dev/null || echo "")
    [[ "$fif_runs" -gt 0 ]] && fif_active=true
fi

# === Build model health entries ===
# Known model inventory with health derived from available signals
jq -n -c \
    --arg now "$now_iso" \
    --argjson cron_health "$cron_health" \
    --argjson fif_active "$fif_active" \
    --arg fif_last_run "$fif_last_run" \
    --argjson fif_runs "$fif_runs" '

def success_rate: if .total == 0 then 1.0 else (.successes / .total * 100 | round / 100) end;

[
    # Tess voice agent — Haiku via OpenClaw
    {
        provider: "anthropic",
        model: "claude-haiku-4-5-20251001",
        callCount: ($cron_health.total // 0),
        successRate: ($cron_health | success_rate),
        p95LatencyMs: null,
        lastCall: ($cron_health.lastRun // null),
        degradationNotes: (
            if ($cron_health.failures // 0) > 0
            then ["\($cron_health.failures) job failure(s) in last 7 days"]
            else [] end
        )
    },
    # FIF pipeline — Sonnet via Anthropic API
    (if $fif_active then {
        provider: "anthropic",
        model: "claude-sonnet-4-6",
        callCount: $fif_runs,
        successRate: 1.0,
        p95LatencyMs: null,
        lastCall: (if $fif_last_run != "" then $fif_last_run else null end),
        degradationNotes: []
    } else empty end)
] as $models |

{
    models: $models,
    lastUpdated: $now
}
' > "${OUTPUT_FILE}.tmp"

mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
