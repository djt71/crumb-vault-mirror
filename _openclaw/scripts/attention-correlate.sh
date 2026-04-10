#!/usr/bin/env bash
# attention-correlate.sh — Vault-change correlation engine
#
# Source: autonomous-operations AO-004
# Correlates attention items with vault changes (git commits + mtime)
# to infer which items the operator acted on.
#
# Signals:
#   Primary: git log --follow for commits to source_path within window
#   Secondary: filesystem mtime within window (catches uncommitted edits)
#
# Domain-aware windows:
#   software, career → 48 hours
#   all others       → 7 days
#
# Usage:
#   bash attention-correlate.sh              # normal run (from daily-attention.sh or standalone)
#   bash attention-correlate.sh --dry-run    # show what would be correlated, no DB writes
#   bash attention-correlate.sh --backfill   # process ALL uncorrelated items (ignore window check)

set -eu

source "/Users/tess/crumb-vault/_openclaw/scripts/attention-lib.sh"

# === Constants ===
VAULT_ROOT="/Users/tess/crumb-vault"
WINDOW_48H=$((48 * 3600))
WINDOW_7D=$((7 * 86400))

# === Argument parsing ===
DRY_RUN=false
BACKFILL=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --backfill) BACKFILL=true; shift ;;
        *) echo "ERROR: Unknown flag: $1" >&2; exit 1 ;;
    esac
done

# === Init ===
attn_init_db

start_epoch=$(date +%s)
now_epoch=$(date +%s)

# === Query uncorrelated items ===
# Items that have NO entry in actions with any of the four correlation sources.
# This ensures idempotency: once correlated, never re-processed.
uncorrelated_items=$(sqlite3 "$ATTN_DB" "
    SELECT i.item_id, i.object_id, i.source_path, i.domain,
           c.ts as cycle_ts, c.cycle_id
    FROM items i
    JOIN cycles c ON i.cycle_id = c.cycle_id
    WHERE c.status = 'ok'
      AND NOT EXISTS (
          SELECT 1 FROM actions a
          WHERE a.item_id = i.item_id
            AND a.action_source IN (
                'git_commit_correlation',
                'mtime_correlation',
                'vault_change_correlation',
                'no_source_path'
            )
      )
    ORDER BY c.ts ASC;
")

if [[ -z "$uncorrelated_items" ]]; then
    elapsed=$(($(date +%s) - start_epoch))
    echo "No uncorrelated items to process. (${elapsed}s)"
    exit 0
fi

# Count items
total_items=$(echo "$uncorrelated_items" | wc -l | tr -d ' ')
echo "Processing $total_items uncorrelated items..."

# === Correlation loop ===
acted_on=0
not_acted_on=0
uncorrelated=0
skipped_open=0
processed=0

while IFS='|' read -r item_id object_id source_path domain cycle_ts cycle_id; do
    [[ -z "$item_id" ]] && continue

    # Convert cycle_ts to epoch
    cycle_epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "$cycle_ts" +%s 2>/dev/null || echo "0")
    if [[ "$cycle_epoch" == "0" ]]; then
        # Try alternate format without T/Z
        cycle_epoch=$(TZ=UTC date -j -f "%Y-%m-%d %H:%M:%S" "${cycle_ts//T/ }" +%s 2>/dev/null || echo "0")
    fi
    if [[ "$cycle_epoch" == "0" ]]; then
        echo "WARNING: Cannot parse cycle_ts '$cycle_ts' for item $item_id — skipping" >&2
        continue
    fi

    # --- Pathless items: classify immediately (no window needed) ---
    if [[ -z "$source_path" || "$object_id" == synthetic:* ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  [dry-run] item=$item_id oid=$object_id → uncorrelated (no source_path)"
        else
            sqlite3 "$ATTN_DB" "INSERT OR IGNORE INTO actions (item_id, action_type, action_source, details_json)
                VALUES ($item_id, 'uncorrelated', 'no_source_path',
                    '{\"reason\": \"no source_path or synthetic object_id\"}');"
        fi
        uncorrelated=$((uncorrelated + 1))
        processed=$((processed + 1))
        continue
    fi

    # Determine correlation window based on domain
    case "$domain" in
        software|career) window_duration=$WINDOW_48H ;;
        *)               window_duration=$WINDOW_7D ;;
    esac

    window_end=$((cycle_epoch + window_duration))

    # Skip items whose window hasn't closed yet (unless backfilling)
    if [[ "$BACKFILL" != "true" && "$now_epoch" -lt "$window_end" ]]; then
        skipped_open=$((skipped_open + 1))
        continue
    fi

    # Format window timestamps for git log (UTC for consistent --since/--until)
    cycle_date=$(TZ=UTC date -j -f "%s" "$cycle_epoch" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)
    window_end_date=$(TZ=UTC date -j -f "%s" "$window_end" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

    # --- Primary signal: git commits to source_path ---
    full_path="$VAULT_ROOT/$source_path"
    git_changes=""

    if [[ -e "$full_path" || -d "$(dirname "$full_path")" ]]; then
        git_changes=$(cd "$VAULT_ROOT" && git log --follow --oneline \
            --since="$cycle_date" --until="$window_end_date" \
            -- "$source_path" 2>/dev/null || echo "")
    fi

    if [[ -n "$git_changes" ]]; then
        commit_count=$(echo "$git_changes" | wc -l | tr -d ' ')
        first_commit=$(echo "$git_changes" | tail -1 | cut -d' ' -f1)
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  [dry-run] item=$item_id path=$source_path → acted_on (git: $commit_count commits)"
        else
            details=$(jq -n -c \
                --arg commits "$commit_count" \
                --arg first "$first_commit" \
                --arg window "${window_duration}s" \
                '{signal: "git_commit", commit_count: ($commits|tonumber), first_commit: $first, window: $window}')
            sqlite3 "$ATTN_DB" "INSERT OR IGNORE INTO actions (item_id, action_type, action_source, details_json)
                VALUES ($item_id, 'acted_on', 'git_commit_correlation',
                    '$(echo "$details" | sed "s/'/''/g")');"
        fi
        acted_on=$((acted_on + 1))
        processed=$((processed + 1))
        continue
    fi

    # --- Secondary signal: filesystem mtime ---
    mtime_match=false
    if [[ -e "$full_path" ]]; then
        file_mtime=$(stat -f %m "$full_path" 2>/dev/null || echo "0")
        if [[ "$file_mtime" -ge "$cycle_epoch" && "$file_mtime" -le "$window_end" ]]; then
            mtime_match=true
        fi
    fi

    if [[ "$mtime_match" == "true" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "  [dry-run] item=$item_id path=$source_path → acted_on (mtime)"
        else
            details=$(jq -n -c \
                --arg mtime "$file_mtime" \
                --arg window "${window_duration}s" \
                '{signal: "mtime", file_mtime: ($mtime|tonumber), window: $window}')
            sqlite3 "$ATTN_DB" "INSERT OR IGNORE INTO actions (item_id, action_type, action_source, details_json)
                VALUES ($item_id, 'acted_on', 'mtime_correlation',
                    '$(echo "$details" | sed "s/'/''/g")');"
        fi
        acted_on=$((acted_on + 1))
        processed=$((processed + 1))
        continue
    fi

    # --- No signal: not acted on ---
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [dry-run] item=$item_id path=$source_path → not_acted_on"
    else
        details=$(jq -n -c \
            --arg window "${window_duration}s" \
            --arg checked_git "true" \
            --arg checked_mtime "true" \
            '{signal: "none", window: $window, checked_git: ($checked_git|test("true")), checked_mtime: ($checked_mtime|test("true"))}')
        sqlite3 "$ATTN_DB" "INSERT OR IGNORE INTO actions (item_id, action_type, action_source, details_json)
            VALUES ($item_id, 'not_acted_on', 'vault_change_correlation',
                '$(echo "$details" | sed "s/'/''/g")');"
    fi
    not_acted_on=$((not_acted_on + 1))
    processed=$((processed + 1))

done <<< "$uncorrelated_items"

# === Summary ===
elapsed=$(($(date +%s) - start_epoch))
echo "Correlation complete in ${elapsed}s:"
echo "  Processed: $processed | Acted on: $acted_on | Not acted on: $not_acted_on | Uncorrelated: $uncorrelated"
echo "  Skipped (window open): $skipped_open"

if [[ "$elapsed" -gt 30 ]]; then
    echo "WARNING: Runtime exceeded 30s threshold (${elapsed}s)" >&2
fi
