#!/usr/bin/env bash
# last30days-validation.sh — B2B signal quality validation
#
# Runs 4 industry/competitor queries through last30days and captures
# output for gate evaluation. Gate: ≥3 of 4 produce actionable signal.
#
# Source: tess-operations TOP-047 / overnight-research-design.md
#
# Usage: sudo -u openclaw env HOME=/Users/openclaw bash /Users/tess/crumb-vault/_openclaw/scripts/last30days-validation.sh
#   OR:  bash last30days-validation.sh  (if running as openclaw already)

set -eu

SCRIPT_DIR="/Users/openclaw/.claude/skills/last30days/scripts"
ENGINE="$SCRIPT_DIR/last30days.py"
OUTPUT_DIR="/tmp/last30days-validation-$(date +%Y-%m-%d)"
TIMEOUT_SECS=600

mkdir -p "$OUTPUT_DIR"

# --- Validation queries (industry/competitor only, no customer accounts) ---
declare -a QUERIES=(
    "BlueCat Networks"
    "EfficientIP DDI"
    "Infoblox DNS security"
    "IPAM network automation"
)

echo "=== last30days B2B Validation ==="
echo "Date: $(date +%Y-%m-%d)"
echo "Output dir: $OUTPUT_DIR"
echo "Queries: ${#QUERIES[@]}"
echo ""

pass_count=0
fail_count=0

for query in "${QUERIES[@]}"; do
    slug=$(echo "$query" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    outfile="$OUTPUT_DIR/${slug}.md"
    logfile="$OUTPUT_DIR/${slug}.log"

    echo "--- [$((pass_count + fail_count + 1))/${#QUERIES[@]}] $query ---"
    echo "  Started: $(date +%H:%M:%S)"

    # Run with timeout; capture stdout to .md, stderr to .log
    # macOS has no `timeout` — use perl one-liner as portable substitute
    # --include-web enables Brave/Parallel/OpenRouter web search alongside social sources
    perl -e 'alarm shift; exec @ARGV' "$TIMEOUT_SECS" \
        python3 "$ENGINE" "$query" --emit md --include-web \
        > "$outfile" 2> "$logfile" && exit_code=0 || exit_code=$?

    end_time=$(date +%H:%M:%S)
    output_lines=$(wc -l < "$outfile" | tr -d ' ')
    output_bytes=$(wc -c < "$outfile" | tr -d ' ')

    if [[ $exit_code -eq 0 && $output_bytes -gt 200 ]]; then
        echo "  Finished: $end_time | OK | ${output_lines} lines, ${output_bytes} bytes"
        pass_count=$((pass_count + 1))
    elif [[ $exit_code -eq 124 ]]; then
        echo "  Finished: $end_time | TIMEOUT (${TIMEOUT_SECS}s) | ${output_lines} lines"
        fail_count=$((fail_count + 1))
    else
        echo "  Finished: $end_time | FAIL (exit $exit_code) | ${output_bytes} bytes"
        # Check stderr for clues
        if [[ -s "$logfile" ]]; then
            echo "  stderr: $(head -3 "$logfile" | tr '\n' ' ')"
        fi
        fail_count=$((fail_count + 1))
    fi
    echo ""
done

# --- Summary ---
total=$((pass_count + fail_count))
echo "=== Validation Summary ==="
echo "Pass: $pass_count / $total"
echo "Fail: $fail_count / $total"
echo ""

if [[ $pass_count -ge 3 ]]; then
    echo "GATE: PASS (≥3 of $total queries produced output)"
    echo "Next: evaluate signal quality in output files before final adoption decision."
else
    echo "GATE: FAIL (<3 of $total queries produced output)"
    echo "Next: review output files and stderr logs. Consider last30days as supplement only."
fi

echo ""
echo "Output files: $OUTPUT_DIR/"
ls -lh "$OUTPUT_DIR/"
