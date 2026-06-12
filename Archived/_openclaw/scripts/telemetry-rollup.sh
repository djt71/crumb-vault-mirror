#!/usr/bin/env bash
# telemetry-rollup.sh — Run all telemetry rollup scripts
#
# Source: mission-control MC-060
#
# Wrapper that calls ops-metrics-rollup.sh and llm-health-rollup.sh.
# Designed for launchd timer (every 15 minutes).

set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Run both rollups — continue on error so one failure doesn't block the other
"$SCRIPT_DIR/ops-metrics-rollup.sh" 2>/dev/null || echo "ops-metrics rollup failed" >&2
"$SCRIPT_DIR/llm-health-rollup.sh" 2>/dev/null || echo "llm-health rollup failed" >&2
