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

# Research compound insight scan
RESEARCH_DIR="$VAULT_ROOT/_openclaw/feeds/research"
COMPOUND_PENDING=0
COMPOUND_STALE=0
COMPOUND_PENDING_FILES=""
COMPOUND_STALE_FILES=""
if [ -d "$RESEARCH_DIR" ]; then
    TODAY_EPOCH=$(date "+%s")
    STALE_THRESHOLD=$((90 * 86400))
    for rf in "$RESEARCH_DIR"/*.md; do
        [ -f "$rf" ] || continue
        # Extract YAML frontmatter between --- delimiters
        head_block=$(awk 'NR==1 && /^---$/{f=1; next} f && /^---$/{exit} f' "$rf")
        # Check for compound_insight in frontmatter
        if echo "$head_block" | grep -q "^compound_insight:"; then
            # Skip if already routed or dismissed
            if echo "$head_block" | grep -qE "^\s+routed_at:|^\s+dismissed:"; then
                continue
            fi
            COMPOUND_PENDING=$((COMPOUND_PENDING + 1))
            rf_rel="${rf#$VAULT_ROOT/}"
            COMPOUND_PENDING_FILES="${COMPOUND_PENDING_FILES}  - ${rf_rel}
"
            # Check perishable staleness
            if echo "$head_block" | grep -q "^\s*durability:.*perishable"; then
                valid_date=$(echo "$head_block" | grep -oE "valid_as_of:.*[0-9]{4}-[0-9]{2}-[0-9]{2}" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}") || true
                if [ -n "$valid_date" ] && date -j -f "%Y-%m-%d" "$valid_date" "+%s" &>/dev/null; then
                    VALID_EPOCH=$(date -j -f "%Y-%m-%d" "$valid_date" "+%s")
                    AGE=$((TODAY_EPOCH - VALID_EPOCH))
                    if [ "$AGE" -ge "$STALE_THRESHOLD" ]; then
                        COMPOUND_STALE=$((COMPOUND_STALE + 1))
                        COMPOUND_STALE_FILES="${COMPOUND_STALE_FILES}  - ${rf_rel} (valid_as_of: ${valid_date})
"
                    fi
                fi
            fi
        fi
    done
fi
echo "compound_insights_pending: $COMPOUND_PENDING"
if [ "$COMPOUND_PENDING" -gt 0 ]; then
    echo "compound_insights_pending_files:"
    printf "%s" "$COMPOUND_PENDING_FILES"
fi
echo "compound_insights_stale: $COMPOUND_STALE"
if [ "$COMPOUND_STALE" -gt 0 ]; then
    echo "compound_insights_stale_files:"
    printf "%s" "$COMPOUND_STALE_FILES"
fi

# Dispatch queue scan (Amendment Z — replaces A2A-004.3)
DISPATCH_QUEUE_COUNT=0
DISPATCH_READY_COUNT=0
DISPATCH_AGE=""
DISPATCH_STALE=""
DISPATCH_ITEMS=""
DISPATCH_ORPHANS=""
TESS_DISPATCH_DIR="$VAULT_ROOT/_tess/dispatch"

if [ -f "$TESS_DISPATCH_DIR/queue.yaml" ]; then
    # Extract updated_at for freshness check
    DISPATCH_UPDATED=$(grep "^updated_at:" "$TESS_DISPATCH_DIR/queue.yaml" | head -1 | sed 's/^updated_at:[[:space:]]*//' | tr -d '"')

    # Freshness check (36h = 129600s threshold)
    if [ -n "$DISPATCH_UPDATED" ]; then
        DISPATCH_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${DISPATCH_UPDATED%%Z*}" "+%s" 2>/dev/null) || true
        if [ -n "$DISPATCH_EPOCH" ]; then
            NOW_EPOCH=$(date "+%s")
            DISPATCH_AGE=$(( (NOW_EPOCH - DISPATCH_EPOCH) / 3600 ))
            if [ "$DISPATCH_AGE" -ge 36 ]; then
                DISPATCH_STALE="STALE (last updated ${DISPATCH_AGE}h ago)"
            fi
        fi
    fi

    # Count queued interactive items and extract summaries
    DISPATCH_QUEUE_COUNT=$(grep -c "status: queued" "$TESS_DISPATCH_DIR/queue.yaml" 2>/dev/null) || true
    DISPATCH_ITEMS=$(awk '
        /^  - id:/ { id=$NF }
        /priority:/ { pri=$NF }
        /summary:/ { sub(/.*summary:[[:space:]]*"?/, ""); sub(/"$/, ""); sum=$0 }
        /status: queued/ { printf "  - [%s] %s: %s\n", toupper(pri), id, sum }
    ' "$TESS_DISPATCH_DIR/queue.yaml" 2>/dev/null) || true
fi

# Orphan detection: check claims.yaml for unresolved claims
if [ -f "$TESS_DISPATCH_DIR/claims.yaml" ]; then
    CLAIM_COUNT=$(grep -c "action: claim" "$TESS_DISPATCH_DIR/claims.yaml" 2>/dev/null) || true
    RESOLVE_COUNT=$(grep -c "action: \(release\|complete\|fail\)" "$TESS_DISPATCH_DIR/claims.yaml" 2>/dev/null) || true
    if [ "${CLAIM_COUNT:-0}" -gt "${RESOLVE_COUNT:-0}" ]; then
        DISPATCH_ORPHANS="potential orphaned claims detected"
    fi
fi

echo "dispatch_queue: $DISPATCH_QUEUE_COUNT"
if [ -n "$DISPATCH_STALE" ]; then
    echo "dispatch_stale: $DISPATCH_STALE"
fi
if [ -n "$DISPATCH_ORPHANS" ]; then
    echo "dispatch_orphans: $DISPATCH_ORPHANS"
fi

# Overnight research output pending review
RESEARCH_OUTPUT_COUNT=0
RESEARCH_OUTPUT_DIR="$VAULT_ROOT/_openclaw/research/output"
if [ -d "$RESEARCH_OUTPUT_DIR" ]; then
    for rof in "$RESEARCH_OUTPUT_DIR"/*.md; do
        [ -f "$rof" ] || continue
        RESEARCH_OUTPUT_COUNT=$((RESEARCH_OUTPUT_COUNT + 1))
    done
fi
echo "research_pending_review: $RESEARCH_OUTPUT_COUNT"

# Feed-intel tier counts from FIF SQLite (MEDIUM+ only — LOW excluded everywhere)
FEED_TOTAL=0
FEED_TIER1=0
FEED_TIER2=0
FIF_DB="$HOME/openclaw/feed-intel-framework/state/pipeline.db"
if [ -f "$FIF_DB" ] && command -v sqlite3 >/dev/null 2>&1; then
    while IFS='|' read -r tier count; do
        case "$tier" in
            high)   FEED_TIER1=$count ;;
            medium) FEED_TIER2=$count ;;
        esac
        FEED_TOTAL=$((FEED_TOTAL + count))
    done <<EOF
$(sqlite3 "$FIF_DB" "SELECT json_extract(triage_json, '\$.priority'), count(*) FROM posts WHERE queue_status='triaged' AND triaged_at >= datetime('now', '-24 hours') AND json_extract(triage_json, '\$.priority') IN ('high', 'medium') GROUP BY 1" 2>/dev/null)
EOF
fi
echo "feed_intel_inbox: $FEED_TOTAL"
if [ "$FEED_TOTAL" -gt 0 ]; then
    echo "feed_intel_tiers:"
    echo "  tier1_promote: $FEED_TIER1"
    echo "  tier2_actions: $FEED_TIER2"
fi

# Z4 lock-deny candidates (TV2-057c) — services with persistent lock
# contention. Phase B will subsume this into the planning cycle; for now the
# startup hook surfaces the count so operators notice even before Phase B is
# live.
Z4_DIR="$HOME/.tess/state/z4-candidates"
Z4_COUNT=0
Z4_LIST=""
if [ -d "$Z4_DIR" ]; then
    for zf in "$Z4_DIR"/*.json; do
        [ -f "$zf" ] || continue
        Z4_COUNT=$((Z4_COUNT + 1))
        zf_name=$(basename "$zf" .json)
        Z4_LIST="${Z4_LIST:+$Z4_LIST, }$zf_name"
    done
fi
echo "lock_deny_candidates: $Z4_COUNT"
if [ "$Z4_COUNT" -gt 0 ]; then
    echo "lock_deny_candidates_list: $Z4_LIST"
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
# Compound insights
COMPOUND_LINE=""
if [ "$COMPOUND_PENDING" -gt 0 ]; then
    COMPOUND_LINE="$COMPOUND_PENDING pending"
    if [ "$COMPOUND_STALE" -gt 0 ]; then
        COMPOUND_LINE="$COMPOUND_LINE ($COMPOUND_STALE stale perishable)"
    fi
fi

if [ -n "$CONTEXT_STALE" ]; then
    echo "- **claude-ai-context.md:** $CONTEXT_STALE"
fi
echo "- **Stale summaries:** $STALE_LINE"
if [ -n "$COMPOUND_LINE" ]; then
    echo "- **Compound insights:** $COMPOUND_LINE"
fi
if [ -n "$DISPATCH_STALE" ]; then
    echo "- **Tess dispatch:** $DISPATCH_STALE — queue is advisory only"
elif [ "$DISPATCH_QUEUE_COUNT" -gt 0 ]; then
    echo "- **Tess dispatch:** $DISPATCH_QUEUE_COUNT items queued (updated ${DISPATCH_AGE:-?}h ago)"
    if [ -n "$DISPATCH_ITEMS" ]; then
        echo "$DISPATCH_ITEMS"
    fi
fi
if [ -n "$DISPATCH_ORPHANS" ]; then
    echo "  WARNING: $DISPATCH_ORPHANS — run orphan recovery"
fi
if [ "$CAPTURE_COUNT" -gt 0 ]; then
    echo "- **Captures:** $CAPTURE_COUNT pending from Tess"
fi
if [ "$FEED_TOTAL" -gt 0 ]; then
    echo "- **Feed intel:** $FEED_TOTAL items (T1:$FEED_TIER1 T2:$FEED_TIER2)"
fi
if [ "$RESEARCH_OUTPUT_COUNT" -gt 0 ]; then
    echo "- **Research output:** $RESEARCH_OUTPUT_COUNT briefs pending review in \`_openclaw/research/output/\`"
fi
if [ "$Z4_COUNT" -gt 0 ]; then
    echo "- **Lock-deny candidates:** $Z4_COUNT ($Z4_LIST) — persistent write-lock contention, investigate"
fi

# Knowledge brief removed from session-start (no context to target against).
# AKM retrieval continues via skill-activation and new-content triggers.
