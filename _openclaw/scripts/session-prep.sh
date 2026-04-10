#!/usr/bin/env bash
# session-prep.sh — Assemble Crumb session context injection file
#
# Source: tess-operations TOP-047 (session prep & debrief)
# Design: Projects/tess-operations/design/session-prep-design.md
#
# Reads vault files for a project, writes a structured context file to
# _openclaw/inbox/session-context-<project>-<date>.md in the §14 schema.
#
# Usage:
#   bash session-prep.sh <project-name>
#   bash session-prep.sh tess-operations
#
# Output: writes the file and prints a summary to stdout for Tess to deliver.

set -eu

VAULT_ROOT="/Users/tess/crumb-vault"
TODAY=$(date +%Y-%m-%d)

# === Argument validation ===
if [[ $# -lt 1 ]]; then
    echo "Usage: session-prep.sh <project-name>"
    exit 1
fi

PROJECT="$1"
PROJECT_DIR="$VAULT_ROOT/Projects/$PROJECT"

if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "ERROR: Project not found: $PROJECT"
    echo "Available projects:"
    ls "$VAULT_ROOT/Projects/" | head -20
    exit 1
fi

# === Output file ===
OUTPUT_DIR="$VAULT_ROOT/_openclaw/inbox"
OUTPUT_FILE="$OUTPUT_DIR/session-context-${PROJECT}-${TODAY}.md"
mkdir -p "$OUTPUT_DIR"

# === Read project-state.yaml ===
STATE_FILE="$PROJECT_DIR/project-state.yaml"
if [[ -f "$STATE_FILE" ]]; then
    phase=$(grep '^phase:' "$STATE_FILE" | head -1 | sed 's/^phase: *//')
    active_task=$(grep '^active_task:' "$STATE_FILE" | head -1 | sed 's/^active_task: *//')
    next_action=$(grep '^next_action:' "$STATE_FILE" | head -1 | sed 's/^next_action: *//')
    domain=$(grep '^domain:' "$STATE_FILE" | head -1 | sed 's/^domain: *//')
else
    phase="unknown"
    active_task="null"
    next_action="unknown"
    domain="unknown"
fi

# === Read run-log (last entry) ===
RUN_LOG="$PROJECT_DIR/progress/run-log.md"
last_session_date=""
last_session_summary=""
last_session_handoff=""

if [[ -f "$RUN_LOG" ]]; then
    # Run-log is reverse chronological (newest first). Read from the top.
    # Skip YAML frontmatter and archive lines — find first ## heading.
    first_heading=$(grep -n '^## ' "$RUN_LOG" | head -1)
    if [[ -n "$first_heading" ]]; then
        heading_line=$(echo "$first_heading" | cut -d: -f1)
        last_session_date_full=$(echo "$first_heading" | sed 's/^[0-9]*:## //' | head -c 120)
        last_session_date=$(echo "$last_session_date_full" | sed 's/ —.*//')

        # Find the next ## heading to bound the block (or EOF)
        next_heading_line=$(sed -n "$((heading_line + 1)),\$p" "$RUN_LOG" | grep -n '^## ' | head -1 | cut -d: -f1)
        if [[ -n "$next_heading_line" ]]; then
            end_line=$((heading_line + next_heading_line - 1))
        else
            end_line=$((heading_line + 50))
        fi
        session_block=$(sed -n "${heading_line},${end_line}p" "$RUN_LOG")

        # Extract summary from the heading suffix (after "— ") — this is the most reliable source
        # Headings like "## 2026-03-15 — Multi-project session: ops fixes, research batch"
        heading_summary=$(echo "$last_session_date_full" | sed 's/^[0-9-]* — //')
        if [[ "$heading_summary" != "$last_session_date_full" && -n "$heading_summary" ]]; then
            last_session_summary="$heading_summary"
        fi
        # If heading has no suffix, try **Context:** line
        if [[ -z "$last_session_summary" ]]; then
            last_session_summary=$(echo "$session_block" | grep -m1 '^\*\*Context:\*\*' | sed 's/^\*\*Context:\*\* *//' | head -c 200)
        fi
        # Fallback: first non-empty, non-heading line after the heading
        if [[ -z "$last_session_summary" ]]; then
            last_session_summary=$(echo "$session_block" | sed -n '2,$p' | grep -v '^#\|^$\|^---' | head -1 | head -c 200)
        fi

        # Handoff: look for uncompleted items or explicit handoff section
        last_session_handoff=$(echo "$session_block" | sed -n '/### Handoff\|### Next\|### Open items/,/^###/p' | grep -v '^###\|^$' | head -5)
        if [[ -z "$last_session_handoff" ]]; then
            # Fallback: next_action from project-state serves as handoff
            last_session_handoff=""
        fi
    fi
fi

# === Read tasks.md (active + next pending) ===
TASKS_FILE="$PROJECT_DIR/tasks.md"
active_tasks=""
pending_tasks=""

if [[ -f "$TASKS_FILE" ]]; then
    # Active task from project-state
    if [[ -n "$active_task" && "$active_task" != "null" ]]; then
        active_tasks=$(grep "|.*$active_task.*|" "$TASKS_FILE" | head -1 | sed 's/^|//;s/|$//' | tr -s ' ')
    fi
    # Next 3 pending tasks
    pending_tasks=$(grep '| *pending *|' "$TASKS_FILE" | head -3 | while IFS='|' read -r _ id desc state rest; do
        id=$(echo "$id" | tr -d ' ')
        desc=$(echo "$desc" | sed 's/^ *//;s/ *$//' | head -c 80)
        echo "- $id: $desc"
    done)
fi

# === Cross-project deps ===
DEPS_FILE="$VAULT_ROOT/_system/docs/cross-project-deps.md"
blockers=""
if [[ -f "$DEPS_FILE" ]]; then
    # Only show rows where this project is blocked (status = blocked/at-risk)
    blocking_rows=$(grep -i "$PROJECT" "$DEPS_FILE" | grep -iE 'blocked|at-risk' | grep -iv '^#\|^---\|^$' | head -5) || true
    if [[ -n "$blocking_rows" ]]; then
        blockers=$(echo "$blocking_rows" | while IFS='|' read -r _ id desc _ _ _ status _; do
            id=$(echo "$id" | tr -d ' ')
            desc=$(echo "$desc" | sed 's/^ *//;s/ *$//')
            status=$(echo "$status" | tr -d ' ')
            echo "- $id: $desc ($status)"
        done)
    fi
fi

# === Vault check warnings ===
VCHECK_FILE="$VAULT_ROOT/_system/logs/vault-check-output.log"
vcheck_warnings=""
if [[ -f "$VCHECK_FILE" ]]; then
    vcheck_warnings=$(grep -i "$PROJECT" "$VCHECK_FILE" | head -5)
fi

# === Dispatch results in inbox ===
dispatch_results=""
if [[ -d "$OUTPUT_DIR" ]]; then
    dispatch_files=$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.md" ! -name "session-context-*" -newer "$OUTPUT_DIR" -mtime -7 2>/dev/null | head -5) || true
    if [[ -n "$dispatch_files" ]]; then
        matching_files=$(echo "$dispatch_files" | xargs grep -li "$PROJECT" 2>/dev/null | head -3) || true
        if [[ -n "$matching_files" ]]; then
            dispatch_results=$(echo "$matching_files" | while read -r f; do basename "$f"; done | sed 's/^/- /')
        fi
    fi
fi

# === FIF digest items ===
FIF_DIGEST_DIR="$HOME/openclaw/feed-intel-framework/state/digests"
feed_intel=""
if [[ -d "$FIF_DIGEST_DIR" ]]; then
    recent_digests=$(find "$FIF_DIGEST_DIR" -name "*.md" -mtime -1 2>/dev/null | head -5) || true
    if [[ -n "$recent_digests" && -n "$domain" && "$domain" != "unknown" ]]; then
        # Keyword match on domain and project name
        matching_items=$(echo "$recent_digests" | xargs grep -li "$domain\|$PROJECT" 2>/dev/null | head -3) || true
        if [[ -n "$matching_items" ]]; then
            feed_intel=$(echo "$matching_items" | while read -r f; do basename "$f"; done | sed 's/^/- /')
        fi
    fi
fi

# === Write session-context file ===
cat > "$OUTPUT_FILE" << ENDFILE
---
type: session-context
project: $PROJECT
created: $TODAY
skill_origin: tess-session-prep
---

## Current State
- **Phase:** $phase
- **Active task:** $active_task
- **Next action:** $next_action

## Last Session
- **Date:** ${last_session_date:-unknown}
- **Summary:** ${last_session_summary:-No summary available.}
$(if [[ -n "$last_session_handoff" ]]; then echo "- **Handoff:**"; echo "$last_session_handoff"; fi)

## Blockers
${blockers:-None.}

## Recent Dispatch Results
${dispatch_results:-None.}

## Relevant Feed Intel
${feed_intel:-None.}

## Vault Check Status
${vcheck_warnings:-Clean.}

## Suggested First Command
$(if [[ -n "$active_task" && "$active_task" != "null" ]]; then
    echo "Resume $active_task — read acceptance criteria in tasks.md, then implement."
elif [[ -n "$next_action" && "$next_action" != "null" ]]; then
    # Strip quotes from next_action
    clean_next=$(echo "$next_action" | tr -d '"')
    echo "$clean_next"
else
    echo "Check project-state.yaml and tasks.md for next steps."
fi)
ENDFILE

# === Print summary for Tess to deliver ===
cat << SUMMARY
**Session prep ready: $PROJECT**

Phase: $phase | Active: ${active_task:-none}
Next: ${next_action:-see project-state.yaml}

File: \`_openclaw/inbox/session-context-${PROJECT}-${TODAY}.md\`
SUMMARY
