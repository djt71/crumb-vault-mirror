#!/bin/bash
# session-startup.sh -- Claude Code SessionStart hook
# Runs mechanical startup steps automatically; outputs structured data
# for Claude to handle judgment-based steps (rotation, overlay loading,
# audit recommendations).
#
# Called by: .claude/settings.json SessionStart hook
# Fires on: new sessions AND --resume sessions

set -uo pipefail

VAULT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "=== Session Startup (automated) ==="
echo ""

# --- Step 1: git pull ---
echo "--- git pull ---"
if git -C "$VAULT_ROOT" pull 2>&1; then
    echo ""
else
    echo "WARNING: git pull failed (non-blocking)"
    echo ""
fi

# --- Step 1b: backup retention prune (agentic-sunset AS-018 fold-in) ---
# launchd can't list the iCloud backup dir (TCC), so the prune inside
# vault-backup.sh is a no-op when run from launchd. This hook runs in the
# user GUI context, which can list it — retention lives here instead.
BACKUP_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/crumb-backups"
PRUNE_LIST=$(ls -t "$BACKUP_DIR"/crumb-vault-*.tar.gz 2>/dev/null | tail -n +31) || true
if [ -n "$PRUNE_LIST" ]; then
    PRUNE_COUNT=$(echo "$PRUNE_LIST" | wc -l | tr -d ' ')
    echo "$PRUNE_LIST" | while IFS= read -r f; do rm -f "$f"; done
    echo "--- backup prune: removed $PRUNE_COUNT tarball(s) beyond 30 ---"
    echo ""
fi

# --- Step 2: vault-check.sh ---
# SKIPPED at startup -- vault-check runs on every commit via pre-commit hook.
# Running it here added ~26s to startup (bash YAML parsing across 100+ files).
# Reintroduce when vault-check is rewritten in Python (see S9 / backlog).
VAULT_CHECK_OUTPUT=""
echo "--- vault-check: deferred to pre-commit hook ---"
echo ""

# --- Step 3: Obsidian CLI availability ---
echo "--- Obsidian CLI ---"
if command -v obsidian &>/dev/null && obsidian vault 2>/dev/null; then
    echo "Obsidian CLI: available"
else
    echo "Obsidian CLI: not available (use native file tools)"
fi
echo ""

# --- Structured data for Claude's judgment steps ---
echo "--- Startup context for Claude ---"

# Stale summary count (extracted from vault-check output)
STALE_COUNT=$(echo "$VAULT_CHECK_OUTPUT" | grep -oE '[0-9]+ stale' | head -1 | grep -oE '[0-9]+') || true
echo "stale_summaries: ${STALE_COUNT:-0}"

# Session-log current month (for rotation check)
if [ -f "$VAULT_ROOT/_system/logs/session-log.md" ]; then
    CURRENT_MONTH_LINE=$(grep "^\*\*Current month:\*\*" "$VAULT_ROOT/_system/logs/session-log.md" 2>/dev/null) || true
    echo "session_log_month: ${CURRENT_MONTH_LINE#\*\*Current month:\*\* }"
else
    echo "session_log_month: no session-log.md found"
fi

# Active run-logs (for rotation check)
echo "active_run_logs:"
while IFS= read -r -d '' rl; do
    rl_month=$(grep -oE '## Session: [0-9]{4}-[0-9]{2}' "$rl" 2>/dev/null | tail -1 | grep -oE '[0-9]{4}-[0-9]{2}') || true
    echo "  - ${rl#$VAULT_ROOT/}: ${rl_month:-unknown}"
done < <(find "$VAULT_ROOT/Projects" -name "run-log*.md" -type f -print0 2>/dev/null) || true

# Last full audit date (from session-log or run-log entries mentioning "audit")
LAST_AUDIT=$(grep -rh "full audit\|vault audit\|, audit,\|, audit$" "$VAULT_ROOT/_system/logs/session-log"*.md "$VAULT_ROOT/Projects"/*/progress/run-log*.md 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort -r | head -1) || true
echo "last_full_audit: ${LAST_AUDIT:-unknown}"

# Overlay index existence
if [ -f "$VAULT_ROOT/_system/docs/overlays/overlay-index.md" ]; then
    echo "overlay_index: exists"
else
    echo "overlay_index: not yet created"
fi

# Today's date for comparison
echo "today: $(date +%Y-%m-%d)"

echo ""
echo "=== Startup complete -- Claude handles rotation/audit/overlay decisions ==="

# --- Build pre-formatted Startup Summary for Claude to display verbatim ---

# Vault-check result
if [ -z "$VAULT_CHECK_OUTPUT" ]; then
    VC_STATUS="deferred to pre-commit hook"
else
    VC_ERRORS=$(echo "$VAULT_CHECK_OUTPUT" | grep -oE 'Errors:[[:space:]]*[0-9]+' | grep -oE '[0-9]+') || true
    VC_WARNINGS=$(echo "$VAULT_CHECK_OUTPUT" | grep -oE 'Warnings:[[:space:]]*[0-9]+' | grep -oE '[0-9]+') || true
    VC_ERRORS="${VC_ERRORS:-0}"
    VC_WARNINGS="${VC_WARNINGS:-0}"
    if [ "$VC_ERRORS" -eq 0 ] && [ "$VC_WARNINGS" -eq 0 ]; then
        VC_STATUS="pass -- 0 errors, 0 warnings"
    else
        VC_STATUS="fail -- $VC_ERRORS errors, $VC_WARNINGS warnings"
    fi
fi

# Obsidian CLI status
if command -v obsidian &>/dev/null && obsidian vault &>/dev/null; then
    OBS_STATUS="available"
else
    OBS_STATUS="unavailable"
fi

# Rotation check
TODAY_MONTH=$(date +%Y-%m)
ROTATION_NOTES=""

# Session-log rotation
if [ -f "$VAULT_ROOT/_system/logs/session-log.md" ]; then
    SL_MONTH=$(grep "^\*\*Current month:\*\*" "$VAULT_ROOT/_system/logs/session-log.md" 2>/dev/null \
        | head -1 | grep -oE '[0-9]{4}-[0-9]{2}') || true
    if [ -n "$SL_MONTH" ] && [ "$SL_MONTH" != "$TODAY_MONTH" ]; then
        ROTATION_NOTES="session-log needs rotation ($SL_MONTH -> $TODAY_MONTH)"
    fi
fi

# Run-log rotation (skip already-rotated archives like run-log-2026-02.md)
while IFS= read -r -d '' rl; do
    rl_base=$(basename "$rl")
    # Skip archived monthly run-logs — they'll always have old month headings
    if [[ "$rl_base" =~ ^run-log-[0-9]{4}-[0-9]{2}\.md$ ]]; then
        continue
    fi
    # Skip run-logs with status: archived in frontmatter
    if head -10 "$rl" | grep -q "^status: archived"; then
        continue
    fi
    rl_m=$(grep -oE '## Session: [0-9]{4}-[0-9]{2}' "$rl" 2>/dev/null | tail -1 | grep -oE '[0-9]{4}-[0-9]{2}') || true
    if [ -n "$rl_m" ] && [ "$rl_m" != "$TODAY_MONTH" ]; then
        rl_short="${rl#$VAULT_ROOT/}"
        if [ -n "$ROTATION_NOTES" ]; then
            ROTATION_NOTES="$ROTATION_NOTES; $rl_short needs rotation ($rl_m -> $TODAY_MONTH)"
        else
            ROTATION_NOTES="$rl_short needs rotation ($rl_m -> $TODAY_MONTH)"
        fi
    fi
done < <(find "$VAULT_ROOT/Projects" -name "run-log*.md" -type f -print0 2>/dev/null) || true

if [ -z "$ROTATION_NOTES" ]; then
    ROTATION_NOTES="none needed"
fi

# Overlay index
if [ -f "$VAULT_ROOT/_system/docs/overlays/overlay-index.md" ]; then
    OVERLAY_STATUS="loaded"
else
    OVERLAY_STATUS="not yet created"
fi

# Audit recommendation
AUDIT_REC="not due"
if [ -z "$LAST_AUDIT" ]; then
    AUDIT_REC="recommended -- last full audit unknown"
else
    # Calculate days since last audit
    if date -j -f "%Y-%m-%d" "$LAST_AUDIT" "+%s" &>/dev/null; then
        AUDIT_EPOCH=$(date -j -f "%Y-%m-%d" "$LAST_AUDIT" "+%s")
        NOW_EPOCH=$(date "+%s")
        DAYS_SINCE=$(( (NOW_EPOCH - AUDIT_EPOCH) / 86400 ))
        if [ "$DAYS_SINCE" -ge 7 ]; then
            AUDIT_REC="recommended -- last audit $DAYS_SINCE days ago ($LAST_AUDIT)"
        fi
    fi
fi

# claude-ai-context.md staleness check (2-day threshold)
CONTEXT_STALE=""
CONTEXT_FILE="$VAULT_ROOT/_system/docs/claude-ai-context.md"
if [ -f "$CONTEXT_FILE" ]; then
    CONTEXT_UPDATED=$(grep -oE '^updated: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$CONTEXT_FILE" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}') || true
    if [ -n "$CONTEXT_UPDATED" ] && date -j -f "%Y-%m-%d" "$CONTEXT_UPDATED" "+%s" &>/dev/null; then
        CONTEXT_EPOCH=$(date -j -f "%Y-%m-%d" "$CONTEXT_UPDATED" "+%s")
        NOW_EPOCH=$(date "+%s")
        CONTEXT_AGE=$(( (NOW_EPOCH - CONTEXT_EPOCH) / 86400 ))
        if [ "$CONTEXT_AGE" -ge 2 ]; then
            CONTEXT_STALE="stale ($CONTEXT_AGE days since $CONTEXT_UPDATED) — update at session end"
        fi
    fi
fi

# Stale summaries
STALE="${STALE_COUNT:-0}"
if [ "$STALE" -ge 3 ]; then
    STALE_LINE="$STALE -- recommend full audit"
else
    STALE_LINE="$STALE"
fi

echo ""
echo "=== DISPLAY THIS BLOCK VERBATIM AS YOUR FIRST OUTPUT ==="
echo ""
echo "**Startup Summary**"
echo "- **vault-check:** $VC_STATUS"
echo "- **Obsidian CLI:** $OBS_STATUS"
echo "- **Rotation:** $ROTATION_NOTES"
echo "- **Overlay index:** $OVERLAY_STATUS"
echo "- **Audit:** $AUDIT_REC"
if [ -n "$CONTEXT_STALE" ]; then
    echo "- **claude-ai-context.md:** $CONTEXT_STALE"
fi
echo "- **Stale summaries:** $STALE_LINE"

# Knowledge brief removed from session-start (no context to target against).
# AKM retrieval continues via skill-activation and new-content triggers.
