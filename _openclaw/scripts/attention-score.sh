#!/usr/bin/env bash
# attention-score.sh — Proxy scoring + exit criteria evaluation
#
# Source: autonomous-operations AO-005
# Computes Phase 1 exit metrics from the replay database.
#
# Metrics:
#   1. Context coverage: % items with non-null source_path, valid action_class, valid domain
#   2. Acted-on rate: % correlated items classified as acted_on (excludes uncorrelated)
#   3. Dedup accuracy: % cycles with zero duplicate object_id
#   4. Replay completeness: % calendar days with a logged cycle
#   5. Scoring coverage: % window-closed items with a correlation result
#
# Usage:
#   bash attention-score.sh              # human-readable + JSON output
#   bash attention-score.sh --json-only  # JSON only (for automation)

set -eu

source "/Users/tess/crumb-vault/_openclaw/scripts/attention-lib.sh"

# === Constants ===
SCORE_OUTPUT="$ATTN_DATA_DIR/attention-scores.json"
EVAL_WINDOW_DAYS=14

# === Argument parsing ===
JSON_ONLY=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json-only) JSON_ONLY=true; shift ;;
        *) echo "ERROR: Unknown flag: $1" >&2; exit 1 ;;
    esac
done

# === Init ===
attn_init_db
start_epoch=$(date +%s)

# === Check for data ===
total_cycles=$(sqlite3 "$ATTN_DB" "SELECT COUNT(*) FROM cycles WHERE status = 'ok';")
total_items=$(sqlite3 "$ATTN_DB" "SELECT COUNT(*) FROM items;")

if [[ "$total_cycles" -eq 0 ]]; then
    echo "No data: 0 successful cycles in replay database."
    exit 0
fi

# ===========================================================================
# Metric 1: Context Coverage
# ===========================================================================
# % of items with non-null source_path AND valid action_class AND valid domain

context_valid=$(sqlite3 "$ATTN_DB" "
    SELECT COUNT(*) FROM items
    WHERE source_path IS NOT NULL AND source_path != ''
      AND action_class IN ('do','decide','plan','track','review','wait')
      AND domain IN ('software','career','learning','health','financial','relationships','creative','spiritual');
")
context_total=$total_items

if [[ "$context_total" -gt 0 ]]; then
    context_rate=$(awk "BEGIN {printf \"%.4f\", $context_valid / $context_total}")
else
    context_rate="0.0000"
fi

# ===========================================================================
# Metric 2: Acted-On Rate
# ===========================================================================
# % of correlated items (acted_on + not_acted_on) that are acted_on
# Excludes uncorrelated items (no source_path)

acted_on_count=$(sqlite3 "$ATTN_DB" "
    SELECT COUNT(*) FROM actions WHERE action_type = 'acted_on';
")
not_acted_on_count=$(sqlite3 "$ATTN_DB" "
    SELECT COUNT(*) FROM actions WHERE action_type = 'not_acted_on';
")
n_correlated=$((acted_on_count + not_acted_on_count))

if [[ "$n_correlated" -gt 0 ]]; then
    acted_on_rate=$(awk "BEGIN {printf \"%.4f\", $acted_on_count / $n_correlated}")
else
    acted_on_rate="0.0000"
fi

# N_window_closed: items eligible for acted-on rate (correlated + uncorrelated)
n_uncorrelated=$(sqlite3 "$ATTN_DB" "
    SELECT COUNT(*) FROM actions WHERE action_type = 'uncorrelated';
")
n_window_closed=$((n_correlated + n_uncorrelated))

# ===========================================================================
# Metric 3: Dedup Accuracy
# ===========================================================================
# % of cycles with zero duplicate object_id warnings in parse_warnings

cycles_with_dedup_issues=$(sqlite3 "$ATTN_DB" "
    SELECT COUNT(*) FROM cycles
    WHERE status = 'ok'
      AND parse_warnings LIKE '%duplicate object_id%';
")
clean_cycles=$((total_cycles - cycles_with_dedup_issues))

if [[ "$total_cycles" -gt 0 ]]; then
    dedup_rate=$(awk "BEGIN {printf \"%.4f\", $clean_cycles / $total_cycles}")
else
    dedup_rate="0.0000"
fi

# ===========================================================================
# Metric 4: Replay Completeness
# ===========================================================================
# % of calendar days in the evaluation window with a logged cycle

first_cycle_date=$(sqlite3 "$ATTN_DB" "SELECT MIN(date(ts)) FROM cycles WHERE status = 'ok';")
today=$(date +%Y-%m-%d)

# Calculate days in window
first_epoch=$(date -j -f "%Y-%m-%d" "$first_cycle_date" +%s 2>/dev/null || echo "0")
today_epoch=$(date -j -f "%Y-%m-%d" "$today" +%s 2>/dev/null || date +%s)
days_in_window=$(( (today_epoch - first_epoch) / 86400 + 1 ))

# Cap at EVAL_WINDOW_DAYS
if [[ "$days_in_window" -gt "$EVAL_WINDOW_DAYS" ]]; then
    days_in_window=$EVAL_WINDOW_DAYS
fi
if [[ "$days_in_window" -lt 1 ]]; then
    days_in_window=1
fi

days_with_cycles=$(sqlite3 "$ATTN_DB" "
    SELECT COUNT(DISTINCT date(ts)) FROM cycles WHERE status = 'ok';
")

# Cap days_with_cycles at days_in_window
if [[ "$days_with_cycles" -gt "$days_in_window" ]]; then
    days_with_cycles=$days_in_window
fi

if [[ "$days_in_window" -gt 0 ]]; then
    replay_rate=$(awk "BEGIN {printf \"%.4f\", $days_with_cycles / $days_in_window}")
else
    replay_rate="0.0000"
fi

# ===========================================================================
# Metric 5: Scoring Coverage
# ===========================================================================
# % of window-closed items that have a correlation result (any action entry)

items_with_actions=$(sqlite3 "$ATTN_DB" "
    SELECT COUNT(DISTINCT item_id) FROM actions;
")

if [[ "$total_items" -gt 0 ]]; then
    scoring_rate=$(awk "BEGIN {printf \"%.4f\", $items_with_actions / $total_items}")
else
    scoring_rate="0.0000"
fi

# ===========================================================================
# Build JSON Output
# ===========================================================================

scored_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
elapsed=$(($(date +%s) - start_epoch))

json_output=$(jq -n \
    --arg scored_at "$scored_at" \
    --argjson elapsed "$elapsed" \
    --argjson total_cycles "$total_cycles" \
    --argjson total_items "$total_items" \
    --argjson context_valid "$context_valid" \
    --argjson context_total "$context_total" \
    --arg context_rate "$context_rate" \
    --argjson acted_on "$acted_on_count" \
    --argjson not_acted_on "$not_acted_on_count" \
    --argjson n_correlated "$n_correlated" \
    --argjson n_uncorrelated "$n_uncorrelated" \
    --argjson n_window_closed "$n_window_closed" \
    --arg acted_on_rate "$acted_on_rate" \
    --argjson clean_cycles "$clean_cycles" \
    --argjson dedup_issues "$cycles_with_dedup_issues" \
    --arg dedup_rate "$dedup_rate" \
    --argjson days_with_cycles "$days_with_cycles" \
    --argjson days_in_window "$days_in_window" \
    --arg replay_rate "$replay_rate" \
    --argjson items_with_actions "$items_with_actions" \
    --arg scoring_rate "$scoring_rate" \
    --arg first_cycle "$first_cycle_date" \
    --arg today "$today" \
    '{
        scored_at: $scored_at,
        elapsed_seconds: $elapsed,
        data_range: {first_cycle: $first_cycle, today: $today, total_cycles: $total_cycles, total_items: $total_items},
        context_coverage: {rate: ($context_rate|tonumber), valid: $context_valid, total: $context_total},
        acted_on_rate: {rate: ($acted_on_rate|tonumber), acted_on: $acted_on, not_acted_on: $not_acted_on, n_correlated: $n_correlated, n_uncorrelated: $n_uncorrelated, n_window_closed: $n_window_closed},
        dedup_accuracy: {rate: ($dedup_rate|tonumber), clean_cycles: $clean_cycles, dedup_issues: $dedup_issues, total_cycles: $total_cycles},
        replay_completeness: {rate: ($replay_rate|tonumber), days_with_cycles: $days_with_cycles, days_in_window: $days_in_window},
        scoring_coverage: {rate: ($scoring_rate|tonumber), items_with_actions: $items_with_actions, total_items: $total_items}
    }')

# Write JSON to file
mkdir -p "$(dirname "$SCORE_OUTPUT")"
echo "$json_output" > "$SCORE_OUTPUT"

# ===========================================================================
# Output
# ===========================================================================

if [[ "$JSON_ONLY" == "true" ]]; then
    echo "$json_output"
    exit 0
fi

# Human-readable summary
echo "============================================"
echo "  Attention Score — Phase 1 Exit Metrics"
echo "  $scored_at (${elapsed}s)"
echo "============================================"
echo ""
echo "Data: $total_cycles cycles, $total_items items ($first_cycle_date → $today)"
echo ""
printf "  %-22s %6s   (%d / %d)\n" "Context coverage:" "$context_rate" "$context_valid" "$context_total"
printf "  %-22s %6s   (%d acted / %d correlated, N_window_closed=%d)\n" "Acted-on rate:" "$acted_on_rate" "$acted_on_count" "$n_correlated" "$n_window_closed"
printf "  %-22s %6s   (%d clean / %d cycles)\n" "Dedup accuracy:" "$dedup_rate" "$clean_cycles" "$total_cycles"
printf "  %-22s %6s   (%d / %d days)\n" "Replay completeness:" "$replay_rate" "$days_with_cycles" "$days_in_window"
printf "  %-22s %6s   (%d / %d items)\n" "Scoring coverage:" "$scoring_rate" "$items_with_actions" "$total_items"
echo ""
echo "JSON written: $SCORE_OUTPUT"

if [[ "$elapsed" -gt 10 ]]; then
    echo "WARNING: Runtime exceeded 10s threshold (${elapsed}s)" >&2
fi
