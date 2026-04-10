#!/usr/bin/env bash
# session-debrief.sh — Post-session debrief: detect new run-log entries, notify via Telegram
#
# Source: tess-operations TOP-047 fn3 (session prep & debrief)
# Design: Projects/tess-operations/design/session-prep-design.md
#
# Checks if a project's run-log has new entries since the last debrief.
# If so, extracts the latest entry heading + key decisions, sends a
# Telegram summary, and updates the cursor file.
#
# Trigger: called from awareness-check.sh or manually.
#   bash session-debrief.sh                  # check all active projects
#   bash session-debrief.sh <project-name>   # check specific project
#
# No vault file written — Telegram-only notification layer.
# The run-log already captures the session record.

set -eu

VAULT_ROOT="/Users/tess/crumb-vault"
CURSOR_DIR="$VAULT_ROOT/_openclaw/state/last-run"
TODAY=$(date +%Y-%m-%d)

# Telegram config — same bot as awareness-check
TELEGRAM_BOT_TOKEN="${TESS_AWARENESS_BOT_TOKEN:-$(security find-generic-password -a tess-bot -s tess-awareness-bot-token -w 2>/dev/null || echo "")}"
TELEGRAM_CHAT_ID="7754252365"

mkdir -p "$CURSOR_DIR"

send_telegram() {
    local text="$1"
    if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
        echo "WARNING: No bot token — skipping Telegram." >&2
        return 1
    fi
    # Truncate if needed
    if [[ ${#text} -gt 4000 ]]; then
        text="${text:0:3950}

[truncated]"
    fi
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 --max-time 15 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d parse_mode="HTML" \
        --data-urlencode text="$text" 2>/dev/null)
    if [[ "$http_code" == "200" ]]; then
        return 0
    fi
    # Retry without parse_mode
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 --max-time 15 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        --data-urlencode text="$text" 2>/dev/null)
    [[ "$http_code" == "200" ]]
}

check_project() {
    local project="$1"
    local project_dir="$VAULT_ROOT/Projects/$project"
    local run_log="$project_dir/progress/run-log.md"
    local cursor_file="$CURSOR_DIR/debrief-${project}"

    # Skip if no run-log
    [[ -f "$run_log" ]] || return 0

    # Get run-log mtime (epoch seconds)
    local log_mtime
    log_mtime=$(stat -f "%m" "$run_log" 2>/dev/null) || return 0

    # Get cursor mtime (epoch seconds), 0 if no cursor
    local cursor_mtime=0
    if [[ -f "$cursor_file" ]]; then
        cursor_mtime=$(stat -f "%m" "$cursor_file" 2>/dev/null) || cursor_mtime=0
    fi

    # Skip if run-log hasn't changed since last debrief
    if [[ "$log_mtime" -le "$cursor_mtime" ]]; then
        return 0
    fi

    # Extract latest entry heading
    local first_heading
    first_heading=$(grep -m1 '^## ' "$run_log") || return 0
    local heading_text
    heading_text=$(echo "$first_heading" | sed 's/^## //')

    # Extract date and summary from heading
    local session_date
    session_date=$(echo "$heading_text" | sed 's/ —.*//')
    local session_summary
    session_summary=$(echo "$heading_text" | sed 's/^[0-9-]* — //')
    if [[ "$session_summary" == "$heading_text" ]]; then
        session_summary=""
    fi

    # Check this entry is from today or yesterday (don't notify about old entries)
    local yesterday
    yesterday=$(date -v-1d +%Y-%m-%d)
    if [[ "$session_date" != "$TODAY" && "$session_date" != "$yesterday" ]]; then
        # Old entry — update cursor silently to avoid repeat checks
        touch "$cursor_file"
        return 0
    fi

    # Extract key decisions if present
    local heading_line
    heading_line=$(grep -n '^## ' "$run_log" | head -1 | cut -d: -f1)
    local next_heading_line
    next_heading_line=$(sed -n "$((heading_line + 1)),\$p" "$run_log" | grep -n '^## ' | head -1 | cut -d: -f1)
    local end_line
    if [[ -n "$next_heading_line" ]]; then
        end_line=$((heading_line + next_heading_line - 1))
    else
        end_line=$((heading_line + 80))
    fi
    local entry_block
    entry_block=$(sed -n "${heading_line},${end_line}p" "$run_log")

    local key_decisions=""
    key_decisions=$(echo "$entry_block" | sed -n '/### Key decisions/,/^###/p' | grep '^- ' | head -3) || true

    local completed_tasks=""
    completed_tasks=$(echo "$entry_block" | grep -oE '[A-Z]{2,4}-[0-9]{3}.*done\|[A-Z]{2,4}-[0-9]{3}.*DONE\|[A-Z]{2,4}-[0-9]{3}.*complete' | head -3) || true

    # Get recent git commits from today
    local recent_commits=""
    recent_commits=$(cd "$VAULT_ROOT" && git log --oneline --since="$session_date" --until="$session_date 23:59:59" -- "Projects/$project/" 2>/dev/null | head -5) || true

    # Build notification
    local msg="<b>Session complete: $project</b>"
    msg+="\n$session_date"
    if [[ -n "$session_summary" ]]; then
        msg+="\n$session_summary"
    fi
    if [[ -n "$key_decisions" ]]; then
        msg+="\n\n<b>Key decisions:</b>"
        while IFS= read -r line; do
            msg+="\n$line"
        done <<< "$key_decisions"
    fi
    if [[ -n "$recent_commits" ]]; then
        msg+="\n\n<b>Commits:</b>"
        while IFS= read -r line; do
            msg+="\n$line"
        done <<< "$recent_commits"
    fi

    # Send notification
    if send_telegram "$msg"; then
        echo "Debrief sent: $project ($session_date)"
    else
        echo "WARNING: Debrief delivery failed for $project" >&2
    fi

    # Update cursor
    touch "$cursor_file"
}

# === Main ===
if [[ $# -ge 1 ]]; then
    # Specific project
    check_project "$1"
else
    # All active projects
    while IFS= read -r state_file; do
        [[ -z "$state_file" ]] && continue
        local_phase=$(grep '^phase:' "$state_file" 2>/dev/null | head -1 | awk '{print $2}')
        if [[ "$local_phase" != "DONE" && "$local_phase" != "ARCHIVED" ]]; then
            project=$(basename "$(dirname "$state_file")")
            check_project "$project"
        fi
    done < <(find "$VAULT_ROOT/Projects" -name "project-state.yaml" -not -path "*/Archived/*" 2>/dev/null)
fi
