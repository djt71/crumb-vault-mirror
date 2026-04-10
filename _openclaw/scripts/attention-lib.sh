#!/usr/bin/env bash
# attention-lib.sh — Shared library for autonomous attention operations
#
# Source: autonomous-operations AO-001
# Provides: DB init, path normalization, alias resolution, CRUD for all tables
#
# Usage:
#   source "/Users/tess/crumb-vault/_openclaw/scripts/attention-lib.sh"
#   attn_init_db
#   attn_log_cycle "ok" "/path/to/artifact.md" "/path/to/sidecar.json" ...

set -eu

# === Constants ===
readonly ATTN_VAULT_ROOT="/Users/tess/crumb-vault"
readonly ATTN_DATA_DIR="$ATTN_VAULT_ROOT/_openclaw/data"
readonly ATTN_DB="$ATTN_DATA_DIR/attention-replay.db"
readonly ATTN_SCHEMA="$ATTN_DATA_DIR/attention-schema.sql"
readonly ATTN_QUARANTINE_DIR="$ATTN_DATA_DIR/quarantine"
readonly ATTN_SCHEMA_VERSION=1

# Canonical domains and action classes
readonly ATTN_VALID_DOMAINS="software career learning health financial relationships creative spiritual"
readonly ATTN_VALID_ACTION_CLASSES="do decide plan track review wait"

# === Database Init ===
# Initializes the database if it doesn't exist or is empty.
# Sets PRAGMA user_version. Safe to call multiple times (idempotent).
attn_init_db() {
    mkdir -p "$ATTN_DATA_DIR"

    # Check if schema version matches
    if [[ -f "$ATTN_DB" ]]; then
        local current_version
        current_version=$(sqlite3 "$ATTN_DB" "PRAGMA user_version;" 2>/dev/null || echo "0")
        if [[ "$current_version" -eq "$ATTN_SCHEMA_VERSION" ]]; then
            return 0  # Already initialized at correct version
        fi
        if [[ "$current_version" -gt "$ATTN_SCHEMA_VERSION" ]]; then
            echo "ERROR: DB schema version ($current_version) is newer than expected ($ATTN_SCHEMA_VERSION)" >&2
            return 1
        fi
        # current_version < ATTN_SCHEMA_VERSION — future migration path
    fi

    # Apply schema (CREATE IF NOT EXISTS is safe for re-runs)
    sqlite3 "$ATTN_DB" < "$ATTN_SCHEMA"
    sqlite3 "$ATTN_DB" "PRAGMA user_version = $ATTN_SCHEMA_VERSION;"
    sqlite3 "$ATTN_DB" "PRAGMA journal_mode = WAL;"
}

# === Path Normalization ===
# Normalizes a vault path: vault-relative, forward slashes, no trailing slash, no leading ./
# Usage: normalized=$(attn_normalize_path "Projects/foo/../bar/spec.md")
attn_normalize_path() {
    local path="$1"

    # Strip vault root prefix if present
    path="${path#$ATTN_VAULT_ROOT/}"
    # Strip leading ./
    path="${path#./}"
    # Strip trailing /
    path="${path%/}"
    # Collapse // to /
    while [[ "$path" == *"//"* ]]; do
        path="${path//\/\//\/}"
    done

    echo "$path"
}

# === Object ID Generation ===
# For items with a source_path: normalize the path.
# For items without: synthetic:<domain>/<title-slug>
attn_make_object_id() {
    local source_path="${1:-}"
    local domain="${2:-}"
    local title="${3:-}"

    if [[ -n "$source_path" ]]; then
        attn_normalize_path "$source_path"
    else
        # Generate synthetic ID
        local slug
        slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' '-' | sed 's/--*/-/g; s/^-//; s/-$//')
        echo "synthetic:${domain}/${slug}"
    fi
}

# === Alias Resolution ===
# Resolves an object_id through the alias table. Returns the final ID.
# Follows chains: old->new->newer (max 10 hops to prevent loops).
attn_resolve_id() {
    local id="$1"
    local hops=0
    local max_hops=10

    while [[ "$hops" -lt "$max_hops" ]]; do
        local new_id
        new_id=$(sqlite3 "$ATTN_DB" "SELECT new_id FROM aliases WHERE old_id = '$(echo "$id" | sed "s/'/''/g")' LIMIT 1;" 2>/dev/null || echo "")
        if [[ -z "$new_id" ]]; then
            break
        fi
        id="$new_id"
        hops=$((hops + 1))
    done

    echo "$id"
}

# === Alias Management ===
# Registers a rename. Both paths are normalized before storage.
attn_add_alias() {
    local old_path="$1"
    local new_path="$2"

    local old_id
    old_id=$(attn_normalize_path "$old_path")
    local new_id
    new_id=$(attn_normalize_path "$new_path")

    sqlite3 "$ATTN_DB" "INSERT OR IGNORE INTO aliases (old_id, new_id) VALUES ('$(echo "$old_id" | sed "s/'/''/g")', '$(echo "$new_id" | sed "s/'/''/g")');"
}

# === Cycle Logging ===
# Logs a cycle (daily run) to the database. Returns the cycle_id.
# Usage: cycle_id=$(attn_log_cycle "ok" "/path/artifact.md" "/path/sidecar.json" "hash" "model" 1500 800 '[]')
attn_log_cycle() {
    local status="$1"
    local artifact_path="${2:-}"
    local sidecar_path="${3:-}"
    local prompt_hash="${4:-}"
    local model="${5:-}"
    local input_tokens="${6:-0}"
    local output_tokens="${7:-0}"
    local parse_warnings="${8:-[]}"
    local error="${9:-}"

    sqlite3 "$ATTN_DB" "INSERT INTO cycles (status, artifact_path, sidecar_path, prompt_hash, model, input_tokens, output_tokens, parse_warnings, error)
        VALUES ('$status', '$(echo "$artifact_path" | sed "s/'/''/g")', '$(echo "$sidecar_path" | sed "s/'/''/g")', '$(echo "$prompt_hash" | sed "s/'/''/g")', '$(echo "$model" | sed "s/'/''/g")', $input_tokens, $output_tokens, '$(echo "$parse_warnings" | sed "s/'/''/g")', '$(echo "$error" | sed "s/'/''/g")');
        SELECT last_insert_rowid();"
}

# === Item Logging ===
# Logs an attention item for a cycle. Handles domain/action_class validation.
# Returns: item_id on success, empty string on duplicate/error (logged to warnings).
# Usage: item_id=$(attn_log_item "$cycle_id" "$object_id" "$source_path" "$domain" "$title" "$action_class" "$urgency" "$raw_json")
attn_log_item() {
    local cycle_id="$1"
    local object_id="$2"
    local source_path="${3:-}"
    local domain="$4"
    local title="$5"
    local action_class="$6"
    local urgency="${7:-}"
    local raw_json="${8:-}"

    local warnings=""

    # Validate domain — fallback to 'software' with warning
    if ! echo "$ATTN_VALID_DOMAINS" | grep -qw "$domain"; then
        warnings="unrecognized domain '$domain', defaulted to 'software'"
        domain="software"
    fi

    # Validate action_class — fallback to 'review' with warning
    if ! echo "$ATTN_VALID_ACTION_CLASSES" | grep -qw "$action_class"; then
        warnings="${warnings:+$warnings; }unrecognized action_class '$action_class', defaulted to 'review'"
        action_class="review"
    fi

    # Resolve through aliases
    object_id=$(attn_resolve_id "$object_id")

    # Check recurrence: has this object_id appeared in a prior cycle?
    local prior
    prior=$(sqlite3 "$ATTN_DB" "SELECT item_id, recurrence_count, urgency, first_seen_ts FROM items WHERE object_id = '$(echo "$object_id" | sed "s/'/''/g")' ORDER BY cycle_id DESC LIMIT 1;" 2>/dev/null || echo "")

    local is_recurrence=0
    local recurrence_count=0
    local first_seen_ts=""
    local last_seen_ts
    last_seen_ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [[ -n "$prior" ]]; then
        is_recurrence=1
        local prior_count
        prior_count=$(echo "$prior" | cut -d'|' -f2)
        recurrence_count=$((prior_count + 1))
        first_seen_ts=$(echo "$prior" | cut -d'|' -f4)

        # Urgency non-decreasing: if model returned lower, use prior
        local prior_urgency
        prior_urgency=$(echo "$prior" | cut -d'|' -f3)
        if [[ -n "$prior_urgency" && -n "$urgency" ]]; then
            local prior_rank=$(_attn_urgency_rank "$prior_urgency")
            local new_rank=$(_attn_urgency_rank "$urgency")
            if [[ "$new_rank" -lt "$prior_rank" ]]; then
                warnings="${warnings:+$warnings; }urgency downgrade blocked: kept '$prior_urgency' over model's '$urgency'"
                urgency="$prior_urgency"
            fi
        fi
    else
        first_seen_ts="$last_seen_ts"
    fi

    # Escape single quotes for SQL
    local esc_oid esc_sp esc_title esc_urgency esc_raw
    esc_oid=$(echo "$object_id" | sed "s/'/''/g")
    esc_sp=$(echo "$source_path" | sed "s/'/''/g")
    esc_title=$(echo "$title" | sed "s/'/''/g")
    esc_urgency=$(echo "$urgency" | sed "s/'/''/g")
    esc_raw=$(echo "$raw_json" | sed "s/'/''/g")

    # Insert — on UNIQUE conflict, skip and log warning
    local result
    result=$(sqlite3 "$ATTN_DB" "INSERT INTO items (cycle_id, object_id, source_path, domain, title, action_class, urgency, is_recurrence, recurrence_count, first_seen_ts, last_seen_ts, raw_json)
        VALUES ($cycle_id, '$esc_oid', '$esc_sp', '$domain', '$esc_title', '$action_class', '$esc_urgency', $is_recurrence, $recurrence_count, '$first_seen_ts', '$last_seen_ts', '$esc_raw');
        SELECT last_insert_rowid();" 2>&1)

    if echo "$result" | grep -qi "unique constraint"; then
        warnings="${warnings:+$warnings; }duplicate object_id '$object_id' in cycle $cycle_id"
        echo ""  # Return empty — caller handles
    else
        echo "$result"
    fi

    # Append warnings to cycle parse_warnings if any
    if [[ -n "$warnings" ]]; then
        _attn_append_warning "$cycle_id" "$warnings"
    fi
}

# === Internal: Urgency Rank (bash 3.2 compatible) ===
_attn_urgency_rank() {
    case "$1" in
        low)      echo 1 ;;
        medium)   echo 2 ;;
        high)     echo 3 ;;
        critical) echo 4 ;;
        *)        echo 0 ;;
    esac
}

# === Internal: Append Warning ===
_attn_append_warning() {
    local cycle_id="$1"
    local warning="$2"
    local esc_warning
    esc_warning=$(echo "$warning" | sed 's/"/\\"/g' | sed "s/'/''/g")

    # Get current warnings, append, update
    local current
    current=$(sqlite3 "$ATTN_DB" "SELECT parse_warnings FROM cycles WHERE cycle_id = $cycle_id;" 2>/dev/null || echo "[]")
    local updated
    updated=$(echo "$current" | jq -c --arg w "$warning" '. + [$w]' 2>/dev/null || echo "[\"$esc_warning\"]")
    sqlite3 "$ATTN_DB" "UPDATE cycles SET parse_warnings = '$(echo "$updated" | sed "s/'/''/g")' WHERE cycle_id = $cycle_id;"
}

# === Query Helpers ===

# Get items from recent cycles (for dedup context injection).
# Returns JSON array of items from last N cycles.
attn_recent_items() {
    local lookback_cycles="${1:-3}"
    local max_items="${2:-20}"

    sqlite3 -json "$ATTN_DB" "
        SELECT i.object_id, i.title, i.urgency, i.domain,
               date(c.ts) as last_seen,
               COUNT(*) OVER (PARTITION BY i.object_id) as times_seen
        FROM items i
        JOIN cycles c ON i.cycle_id = c.cycle_id
        WHERE c.cycle_id IN (
            SELECT cycle_id FROM cycles
            WHERE status = 'ok'
            ORDER BY cycle_id DESC
            LIMIT $lookback_cycles
        )
        GROUP BY i.object_id
        ORDER BY c.ts DESC
        LIMIT $max_items;" 2>/dev/null || echo "[]"
}

# Get cycle count
attn_cycle_count() {
    sqlite3 "$ATTN_DB" "SELECT COUNT(*) FROM cycles;" 2>/dev/null || echo "0"
}

# Get item count for a cycle
attn_item_count() {
    local cycle_id="$1"
    sqlite3 "$ATTN_DB" "SELECT COUNT(*) FROM items WHERE cycle_id = $cycle_id;" 2>/dev/null || echo "0"
}

# === CLI Entry Point ===
# Supports: init, add_alias, recent, stats
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        init)
            attn_init_db
            echo "Database initialized: $ATTN_DB (version $ATTN_SCHEMA_VERSION)"
            ;;
        add_alias)
            if [[ $# -lt 3 ]]; then
                echo "Usage: attention-lib.sh add_alias <old_path> <new_path>" >&2
                exit 1
            fi
            attn_init_db
            attn_add_alias "$2" "$3"
            echo "Alias registered: $2 → $3"
            ;;
        recent)
            attn_init_db
            attn_recent_items "${2:-3}" "${3:-20}"
            ;;
        stats)
            attn_init_db
            echo "Cycles: $(sqlite3 "$ATTN_DB" "SELECT COUNT(*) FROM cycles;") | Items: $(sqlite3 "$ATTN_DB" "SELECT COUNT(*) FROM items;") | Aliases: $(sqlite3 "$ATTN_DB" "SELECT COUNT(*) FROM aliases;")"
            ;;
        *)
            echo "Usage: attention-lib.sh {init|add_alias|recent|stats}" >&2
            exit 1
            ;;
    esac
fi
