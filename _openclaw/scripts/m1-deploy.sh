#!/usr/bin/env bash
# m1-deploy.sh — Deploy M1 Chief-of-Staff MVP configuration
#
# Source: tess-operations action-plan M1 (TOP-006 through TOP-013, TOP-053)
#
# This script configures:
#   1. Voice agent heartbeat — DISABLED for M1 (cost optimization) — TOP-006
#   2. Mechanic agent heartbeat (60 min, 24/7) — TOP-007
#   3. HEARTBEAT.md entries for both agents — TOP-008
#   4. Morning briefing cron job (7 AM daily) — TOP-009
#   5. Nightly vault health check — TOP-010
#   6. Hourly pipeline monitoring — TOP-011
#   7. Token budget configuration — TOP-012
#   8. Alerting rules via job prompts — TOP-013
#   9. Awareness-check cron job (30 min, waking hours, local model) — TOP-053
#
# Prerequisites:
#   - OpenClaw v2026.2.25 running (TOP-001 ✓)
#   - Global kill-switch infrastructure (TOP-002 ✓)
#   - cron-lib.sh in place (TOP-051 ✓)
#
# Usage: Run as openclaw user or via sudo
#   sudo -u openclaw bash /Users/tess/crumb-vault/_openclaw/scripts/m1-deploy.sh
#
# The script is idempotent — safe to re-run.

set -eu

# === Constants ===
export HOME="/Users/openclaw"
export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
VAULT_ROOT="/Users/tess/crumb-vault"
STAGING_DIR="$VAULT_ROOT/_openclaw/staging/m1"
OC="openclaw"

# === Color helpers ===
green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
red() { printf "\033[31m%s\033[0m\n" "$1"; }

# === Step 0: Verify prerequisites ===
echo "=== Step 0: Prerequisites ==="

VERSION=$($OC --version 2>/dev/null || echo "unknown")
if [[ "$VERSION" != *"2026.2.25"* ]]; then
    red "FAIL: OpenClaw version is '$VERSION', expected 2026.2.25"
    exit 1
fi
green "OpenClaw v$VERSION ✓"

# Check gateway
if ! nc -z -w3 127.0.0.1 18789 2>/dev/null; then
    red "FAIL: Gateway not responding on port 18789"
    exit 1
fi
green "Gateway alive ✓"

# Check staging files exist
for f in voice-HEARTBEAT.md mechanic-HEARTBEAT.md morning-briefing-prompt.md vault-health-prompt.md pipeline-monitoring-prompt.md awareness-check-prompt.md; do
    if [[ ! -f "$STAGING_DIR/$f" ]]; then
        red "FAIL: Missing staging file: $STAGING_DIR/$f"
        exit 1
    fi
done
green "Staging files present ✓"

echo ""

# === Step 1: Discover agent IDs ===
echo "=== Step 1: Discover agent configuration ==="

# List agents to find voice and mechanic IDs
echo "Current agents:"
$OC cron status 2>/dev/null || true
echo ""

# The agent IDs are in openclaw.json — check what's configured
OC_CONFIG="$HOME/.openclaw/openclaw.json"
echo "Configured agents:"
jq -r '.agents.list[]? | "\(.name // .id): model=\(.model // "default"), heartbeat=\(.heartbeat.every // "not set")"' "$OC_CONFIG" 2>/dev/null || echo "Could not read agent config"
echo ""

# Prompt operator to confirm agent IDs before proceeding
echo "---"
echo "VERIFY: Confirm the voice and mechanic agent IDs from the output above."
echo "Expected: voice agent (Haiku 4.5) and mechanic agent (qwen3-coder)."
echo ""
read -p "Voice agent ID [voice]: " VOICE_AGENT
VOICE_AGENT=${VOICE_AGENT:-voice}
read -p "Mechanic agent ID [mechanic]: " MECHANIC_AGENT
MECHANIC_AGENT=${MECHANIC_AGENT:-mechanic}
echo ""
green "Using agents: voice=$VOICE_AGENT, mechanic=$MECHANIC_AGENT"

echo ""

# === Step 2: Deploy HEARTBEAT.md files (TOP-008) ===
echo "=== Step 2: Deploy HEARTBEAT.md files ==="

# Find agent workspace directories
VOICE_WORKSPACE=$(jq -r ".agents.list[]? | select(.name == \"$VOICE_AGENT\" or .id == \"$VOICE_AGENT\") | .workspace // empty" "$OC_CONFIG" 2>/dev/null)
MECHANIC_WORKSPACE=$(jq -r ".agents.list[]? | select(.name == \"$MECHANIC_AGENT\" or .id == \"$MECHANIC_AGENT\") | .workspace // empty" "$OC_CONFIG" 2>/dev/null)

# Default workspace paths if not found in config
VOICE_WORKSPACE=${VOICE_WORKSPACE:-"$HOME/.openclaw/agents/$VOICE_AGENT"}
MECHANIC_WORKSPACE=${MECHANIC_WORKSPACE:-"$HOME/.openclaw/agents/$MECHANIC_AGENT"}

echo "Voice workspace: $VOICE_WORKSPACE"
echo "Mechanic workspace: $MECHANIC_WORKSPACE"

mkdir -p "$VOICE_WORKSPACE" "$MECHANIC_WORKSPACE"

cp "$STAGING_DIR/voice-HEARTBEAT.md" "$VOICE_WORKSPACE/HEARTBEAT.md"
green "Voice HEARTBEAT.md deployed ✓"

cp "$STAGING_DIR/mechanic-HEARTBEAT.md" "$MECHANIC_WORKSPACE/HEARTBEAT.md"
green "Mechanic HEARTBEAT.md deployed ✓"

echo ""

# === Step 3: Configure heartbeat intervals (TOP-006, TOP-007) ===
echo "=== Step 3: Configure heartbeat intervals ==="

# Check current heartbeat config
echo "Current heartbeat config:"
jq '.agents.defaults.heartbeat // "not set"' "$OC_CONFIG" 2>/dev/null
echo ""

# Voice agent: DISABLED for M1 (cost optimization)
# All monitoring migrated to mechanic heartbeat + awareness-check cron job (TOP-053)
# The voice HEARTBEAT.md is a stub explaining the migration.

echo "Disabling voice heartbeat (cost optimization — monitoring moved to mechanic + awareness cron)..."
# Pre-validate agent exists in config
if ! jq -e --arg agent "$VOICE_AGENT" '.agents.list[]? | select(.name == $agent or .id == $agent)' "$OC_CONFIG" >/dev/null 2>&1; then
    red "FAIL: agent '$VOICE_AGENT' not found in $OC_CONFIG"
    exit 1
fi
tmp=$(mktemp)
jq --arg agent "$VOICE_AGENT" '
  .agents.list = [.agents.list[]? | if (.name == $agent or .id == $agent) then .heartbeat.every = "0" else . end]
' "$OC_CONFIG" > "$tmp" 2>/dev/null && mv "$tmp" "$OC_CONFIG" || { yellow "WARN: Could not set via jq — may need manual config"; rm -f "$tmp"; }
# Post-verify
if jq -e --arg agent "$VOICE_AGENT" '.agents.list[]? | select(.name == $agent or .id == $agent) | .heartbeat.every == "0"' "$OC_CONFIG" >/dev/null 2>&1; then
    green "Voice heartbeat: disabled ✓"
else
    yellow "WARN: Voice heartbeat value not confirmed in config — verify manually"
fi

echo "Setting mechanic heartbeat to 60m..."
if ! jq -e --arg agent "$MECHANIC_AGENT" '.agents.list[]? | select(.name == $agent or .id == $agent)' "$OC_CONFIG" >/dev/null 2>&1; then
    red "FAIL: agent '$MECHANIC_AGENT' not found in $OC_CONFIG"
    exit 1
fi
tmp=$(mktemp)
jq --arg agent "$MECHANIC_AGENT" '
  .agents.list = [.agents.list[]? | if (.name == $agent or .id == $agent) then .heartbeat.every = "60m" else . end]
' "$OC_CONFIG" > "$tmp" 2>/dev/null && mv "$tmp" "$OC_CONFIG" || { yellow "WARN: Could not set via jq — may need manual config"; rm -f "$tmp"; }
if jq -e --arg agent "$MECHANIC_AGENT" '.agents.list[]? | select(.name == $agent or .id == $agent) | .heartbeat.every == "60m"' "$OC_CONFIG" >/dev/null 2>&1; then
    green "Mechanic heartbeat: 60m ✓"
else
    yellow "WARN: Mechanic heartbeat value not confirmed in config — verify manually"
fi

echo ""

# === Step 4: Register cron jobs (TOP-009, TOP-010, TOP-011) ===
echo "=== Step 4: Register cron jobs ==="

# Check if jobs already exist
EXISTING_JOBS=$($OC cron list --json 2>/dev/null | jq -r '.[].name // empty' 2>/dev/null || echo "")

# --- Morning Briefing (TOP-009) ---
if echo "$EXISTING_JOBS" | grep -q "morning-briefing"; then
    yellow "morning-briefing already exists — skipping (use 'openclaw cron edit' to update)"
else
    echo "Adding morning-briefing cron job..."
    BRIEFING_PROMPT=$(cat "$STAGING_DIR/morning-briefing-prompt.md")
    $OC cron add \
        --name "morning-briefing" \
        --agent "$VOICE_AGENT" \
        --cron "0 7 * * *" \
        --tz "America/New_York" \
        --message "$BRIEFING_PROMPT" \
        --session isolated \
        --timeout-seconds 900 \
        --announce \
        --stagger "5m" \
        && green "morning-briefing registered ✓" \
        || red "FAIL: could not register morning-briefing"
fi

# --- Vault Health Check (TOP-010) ---
if echo "$EXISTING_JOBS" | grep -q "vault-health"; then
    yellow "vault-health already exists — skipping"
else
    echo "Adding vault-health cron job..."
    VAULT_PROMPT=$(cat "$STAGING_DIR/vault-health-prompt.md")
    $OC cron add \
        --name "vault-health" \
        --agent "$MECHANIC_AGENT" \
        --cron "0 2 * * *" \
        --tz "America/New_York" \
        --message "$VAULT_PROMPT" \
        --session isolated \
        --timeout-seconds 600 \
        --best-effort-deliver \
        --stagger "5m" \
        && green "vault-health registered ✓" \
        || red "FAIL: could not register vault-health"
fi

# --- Pipeline Monitoring (TOP-011) ---
if echo "$EXISTING_JOBS" | grep -q "pipeline-monitor"; then
    yellow "pipeline-monitor already exists — skipping"
else
    echo "Adding pipeline-monitor cron job..."
    PIPELINE_PROMPT=$(cat "$STAGING_DIR/pipeline-monitoring-prompt.md")
    $OC cron add \
        --name "pipeline-monitor" \
        --agent "$MECHANIC_AGENT" \
        --cron "0 * * * *" \
        --tz "America/New_York" \
        --message "$PIPELINE_PROMPT" \
        --session isolated \
        --timeout-seconds 300 \
        --best-effort-deliver \
        --stagger "5m" \
        && green "pipeline-monitor registered ✓" \
        || red "FAIL: could not register pipeline-monitor"
fi

# --- Awareness Check (TOP-053) ---
if echo "$EXISTING_JOBS" | grep -q "awareness-check"; then
    yellow "awareness-check already exists — skipping (use 'openclaw cron edit' to update)"
else
    echo "Adding awareness-check cron job (mechanic + direct Telegram delivery, 30 min waking hours)..."
    AWARENESS_PROMPT=$(cat "$STAGING_DIR/awareness-check-prompt.md")
    # Mechanic agent is unbound from Telegram channels. --model override is broken
    # in isolated sessions (#9556/#14279 bug family). Use --to <chatId> for direct
    # delivery, bypassing agent channel bindings entirely.
    $OC cron add \
        --name "awareness-check" \
        --agent "$MECHANIC_AGENT" \
        --cron "*/30 7-23 * * *" \
        --tz "America/New_York" \
        --message "$AWARENESS_PROMPT" \
        --session isolated \
        --timeout-seconds 300 \
        --to "7754252365" \
        --best-effort-deliver \
        --stagger "5m" \
        && green "awareness-check registered ✓" \
        || red "FAIL: could not register awareness-check"
fi

echo ""

# === Step 5: Register health-ping cron (TOP-003 deployment) ===
echo "=== Step 5: Health ping cron (via launchd — runs as tess) ==="
echo "The health-ping script runs externally via launchd, not openclaw cron."
echo "Create ~/Library/LaunchAgents/ai.openclaw.health-ping.plist for tess user."
echo "(This step requires running as tess, not openclaw.)"
echo ""

# === Step 6: Verify deployment ===
echo "=== Step 6: Verification ==="

echo "Cron jobs:"
$OC cron list 2>/dev/null || yellow "Could not list cron jobs (gateway may need restart)"
echo ""

echo "Heartbeat config:"
jq '.agents.list[]? | {name: (.name // .id), heartbeat: .heartbeat}' "$OC_CONFIG" 2>/dev/null || echo "Could not read config"
echo ""

echo "HEARTBEAT.md files:"
ls -la "$VOICE_WORKSPACE/HEARTBEAT.md" 2>/dev/null && green "Voice HEARTBEAT.md ✓" || red "Voice HEARTBEAT.md missing"
ls -la "$MECHANIC_WORKSPACE/HEARTBEAT.md" 2>/dev/null && green "Mechanic HEARTBEAT.md ✓" || red "Mechanic HEARTBEAT.md missing"
echo ""

# === Step 7: Restart gateway to pick up config changes ===
echo "=== Step 7: Gateway restart ==="
echo "Config changes require a gateway restart to take effect."
read -p "Restart gateway now? [y/N]: " RESTART
if [[ "$RESTART" == "y" || "$RESTART" == "Y" ]]; then
    $OC gateway restart 2>/dev/null || {
        yellow "openclaw gateway restart failed — trying launchctl"
        sudo launchctl kickstart -k system/ai.openclaw.gateway 2>/dev/null || red "FAIL: could not restart gateway"
    }
    sleep 5
    if nc -z -w3 127.0.0.1 18789 2>/dev/null; then
        green "Gateway restarted and responsive ✓"
    else
        red "Gateway not responding after restart — check logs"
    fi
else
    yellow "Skipped — restart manually when ready: openclaw gateway restart"
fi

echo ""
echo "=== M1 Deployment Complete ==="
echo ""
echo "Next steps:"
echo "  1. Verify mechanic heartbeat fires: wait for next 60-min interval, check Telegram"
echo "  2. Test morning briefing: openclaw cron run morning-briefing"
echo "  3. Test vault health: openclaw cron run vault-health"
echo "  4. Test pipeline monitor: openclaw cron run pipeline-monitor"
echo "  5. Test awareness check: openclaw cron run awareness-check"
echo "  6. Monitor for 5 days (TOP-014 gate evaluation)"
echo ""
echo "Note: Voice heartbeat is DISABLED for M1 (cost optimization)."
echo "Voice agent fires only for Telegram conversations and scheduled cron jobs."
echo ""
echo "Rollback: openclaw cron rm <job-name>"
