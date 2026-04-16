#!/bin/bash
# vault-check.sh — External Mechanical Vault Validation
# Crumb Design Spec §7.8
#
# Twenty-four mechanical validations that cannot hallucinate, forget, or skip steps.
# Exit codes: 0 = clean, 1 = warnings (non-blocking), 2 = errors (blocking)
#
# Usage:
#   ./scripts/vault-check.sh              # Full scan (default)
#   ./scripts/vault-check.sh --pre-commit  # Scoped to staged files only
#   ./scripts/vault-check.sh --full        # Explicit full scan
#   ./scripts/vault-check.sh /path/to/vault  # Explicit vault path (full scan)
#   ./scripts/vault-check.sh --pre-commit /path/to/vault  # Scoped + explicit path
#
# Integration:
#   - Git pre-commit hook: vault-check.sh --pre-commit (fast, staged files only)
#   - Weekly audit / manual: vault-check.sh (full scan)

set -euo pipefail

# Parse flags
SCOPE="full"
VAULT_ARG=""
for arg in "$@"; do
    case "$arg" in
        --pre-commit) SCOPE="staged" ;;
        --full) SCOPE="full" ;;
        *) VAULT_ARG="$arg" ;;
    esac
done

# Determine vault root
VAULT_ROOT="${VAULT_ARG:-$(pwd)}"
if [ ! -f "$VAULT_ROOT/CLAUDE.md" ]; then
    echo "ERROR: Cannot find CLAUDE.md at $VAULT_ROOT — is this the vault root?"
    exit 2
fi

# Build staged file list (once) when in pre-commit mode
STAGED_FILES=""
if [ "$SCOPE" = "staged" ]; then
    STAGED_FILES=$(git -C "$VAULT_ROOT" diff --cached --name-only --diff-filter=ACMR 2>/dev/null) || true
    if [ -z "$STAGED_FILES" ]; then
        echo "No staged files — nothing to check."
        exit 0
    fi
    echo "Mode: pre-commit ($(echo "$STAGED_FILES" | wc -l | tr -d ' ') staged files)"
else
    echo "Mode: full scan"
fi

# Helper: check if any staged file matches a pattern (glob-style prefix + suffix)
# Usage: has_staged_match "Projects/" ".md" — true if any staged file starts with
#        prefix and ends with suffix. With empty prefix, matches suffix anywhere.
has_staged_match() {
    local prefix="${1:-}"
    local suffix="${2:-}"
    if [ "$SCOPE" = "full" ]; then
        return 0  # always "has match" in full mode
    fi
    echo "$STAGED_FILES" | grep -q "^${prefix}.*${suffix}$"
}

# Helper: iterate staged .md files matching a directory prefix.
# Calls a check function on each matching staged file.
# Uses process substitution to keep the while loop in the main shell
# (pipe would create a subshell, losing counter variable updates).
# Usage: check_staged_in_dirs "check_function" "dir1 dir2 dir3"
check_staged_in_dirs() {
    local check_fn="$1"
    shift
    local dirs="$*"
    for dir in $dirs; do
        while IFS= read -r relpath; do
            [ -z "$relpath" ] && continue
            local abspath="$VAULT_ROOT/$relpath"
            [ -f "$abspath" ] && "$check_fn" "$abspath"
        done < <(echo "$STAGED_FILES" | grep "^${dir}/.*\.md$" || true)
    done
}

# Helper: iterate staged files matching a name pattern within directories.
# Usage: check_staged_by_name "check_function" "dir1 dir2" "*-summary.md"
check_staged_by_name() {
    local check_fn="$1"
    local dirs="$2"
    local pattern="$3"
    for dir in $dirs; do
        while IFS= read -r relpath; do
            [ -z "$relpath" ] && continue
            local abspath="$VAULT_ROOT/$relpath"
            [ -f "$abspath" ] && "$check_fn" "$abspath"
        done < <(echo "$STAGED_FILES" | grep "^${dir}/.*${pattern}$" || true)
    done
}

WARNINGS=0
ERRORS=0

warn() {
    echo "  WARNING: $1"
    WARNINGS=$((WARNINGS + 1))
}

error() {
    echo "  ERROR: $1"
    ERRORS=$((ERRORS + 1))
}

# ============================================================================
# SHARED: Robust frontmatter extraction
#
# Handles: CRLF line endings, trailing whitespace on --- delimiters,
# extra --- horizontal rules in body content. Extracts ONLY the YAML block
# between the first and second --- lines.
# ============================================================================

extract_frontmatter() {
    local file="$1"
    # Strip \r globally, then use awk to grab only lines between first and
    # second --- delimiter (tolerating trailing whitespace on the delimiter).
    # Returns empty string if no valid frontmatter block found.
    # Note: awk's early `exit` closes the pipe while tr may still be writing,
    # causing SIGPIPE (exit 141) under set -o pipefail. Capture into a
    # variable with || true to prevent the script from aborting.
    local result
    result=$(tr -d '\r' < "$file" | awk '
        /^---[[:space:]]*$/ {
            count++
            if (count == 2) exit
            next
        }
        count == 1 { print }
    ') || true
    printf '%s' "$result"
}

has_frontmatter() {
    local file="$1"
    # Check if first line (after stripping \r) is a --- delimiter.
    # Captures into a variable to avoid broken-pipe failure from head closing
    # the tr pipe early, which kills the pipeline under set -euo pipefail.
    local first_line
    first_line=$(tr -d '\r' < "$file" | head -1) || true
    [[ "$first_line" =~ ^---[[:space:]]*$ ]]
}

extract_field() {
    local frontmatter="$1"
    local field="$2"
    # Extract the value of a top-level YAML field from already-extracted frontmatter.
    # Handles: "field: value", "field: null", "field:" (empty).
    # Strips surrounding quotes so 'type: "moc-orientation"' works like 'type: moc-orientation'.
    # Guard: grep returns 1 on no match; head/sed can SIGPIPE. Use || true.
    local result
    result=$(echo "$frontmatter" | grep "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//" | sed "s/^[\"']//;s/[\"']$//") || true
    printf '%s' "$result"
}

extract_field_from_file() {
    local file="$1"
    local field="$2"
    local fm
    fm=$(extract_frontmatter "$file")
    extract_field "$fm" "$field"
}

# ============================================================================
# 1. FRONTMATTER SCHEMA VALIDATION
# Iterate all .md files in Projects/, Domains/, _system/docs/. Verify YAML parses and
# required fields exist (project, domain, type, status, created, updated).
#
# Exclusions:
#   - run-log*.md and progress-log.md: operational logs, no frontmatter expected
#   - Files in .claude/: skill and agent definitions use their own schema
# ============================================================================
echo "=== 1. Frontmatter Schema Validation ==="

REQUIRED_FIELDS="project domain type status created updated"
FRONTMATTER_FILES_CHECKED=0
FRONTMATTER_FILES_WITH_ISSUES=0

check_frontmatter() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"
    local basename
    basename=$(basename "$file")

    # Skip operational log files — they don't use the standard frontmatter schema
    case "$basename" in
        run-log*.md|progress-log.md)
            return
            ;;
    esac

    if ! has_frontmatter "$file"; then
        warn "$relpath — no YAML frontmatter found"
        FRONTMATTER_FILES_WITH_ISSUES=$((FRONTMATTER_FILES_WITH_ISSUES + 1))
        FRONTMATTER_FILES_CHECKED=$((FRONTMATTER_FILES_CHECKED + 1))
        return
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    if [ -z "$frontmatter" ]; then
        warn "$relpath — empty frontmatter block"
        FRONTMATTER_FILES_WITH_ISSUES=$((FRONTMATTER_FILES_WITH_ISSUES + 1))
        FRONTMATTER_FILES_CHECKED=$((FRONTMATTER_FILES_CHECKED + 1))
        return
    fi

    # Determine which fields are required for this file's location.
    # - _system/docs/: global files, project field is optional
    # - Projects/: directory location is authoritative per §4.1.6,
    #   so status is NOT required (active = in Projects/, archived = in Archived/Projects/)
    local required="$REQUIRED_FIELDS"
    case "$relpath" in
        Projects/*)
            required="project domain type created updated"
            ;;
        _system/docs/*|Sources/*)
            required="domain type status created updated"
            ;;
        _system/daily/*)
            required="type status created updated"
            ;;
    esac

    local file_has_issues=0
    local missing_fields=""

    # Check for duplicate YAML keys (e.g., two "updated:" lines).
    # Duplicate keys are valid-ish YAML (last wins) but break Quartz and other
    # strict parsers. Detect by sorting key names and comparing adjacent lines.
    local dup_keys
    dup_keys=$(echo "$frontmatter" | grep -oE '^[a-zA-Z_][a-zA-Z0-9_-]*:' | sort | uniq -d) || true
    if [ -n "$dup_keys" ]; then
        local dup_list
        dup_list=$(echo "$dup_keys" | sed 's/:$//' | tr '\n' ',' | sed 's/,$//')
        warn "$relpath — duplicate YAML key(s): $dup_list"
        file_has_issues=1
    fi
    for field in $required; do
        # Use grep on variable directly to avoid echo|grep SIGPIPE under pipefail.
        # grep -q on a herestring avoids the pipe entirely.
        if ! grep -q "^${field}:" <<< "$frontmatter"; then
            missing_fields="${missing_fields}${field}, "
            file_has_issues=1
        fi
    done

    if [ $file_has_issues -eq 1 ]; then
        missing_fields="${missing_fields%, }"
        warn "$relpath — missing required fields: $missing_fields"
        FRONTMATTER_FILES_WITH_ISSUES=$((FRONTMATTER_FILES_WITH_ISSUES + 1))
    fi

    FRONTMATTER_FILES_CHECKED=$((FRONTMATTER_FILES_CHECKED + 1))
}

# Find .md files — scoped to staged files in pre-commit mode
if [ "$SCOPE" = "staged" ]; then
    check_staged_in_dirs check_frontmatter Projects Domains Sources _system/docs _system/daily
else
    for dir in Projects Domains Sources _system/docs _system/daily; do
        if [ -d "$VAULT_ROOT/$dir" ]; then
            while IFS= read -r -d '' file; do
                check_frontmatter "$file"
            done < <(find "$VAULT_ROOT/$dir" -name "*.md" -type f -print0 2>/dev/null)
        fi
    done
fi

echo "  Checked $FRONTMATTER_FILES_CHECKED files, $FRONTMATTER_FILES_WITH_ISSUES with issues"

# ============================================================================
# 2. SUMMARY FRESHNESS CHECK
# For every *-summary.md, compare source_updated against parent's updated.
# ============================================================================
echo ""
echo "=== 2. Summary Freshness Check ==="

SUMMARIES_CHECKED=0
SUMMARIES_STALE=0

check_summary_freshness() {
    local summary_file="$1"
    local relpath="${summary_file#$VAULT_ROOT/}"

    # Derive parent file path (remove -summary from the name)
    local parent_file="${summary_file%-summary.md}.md"

    if [ ! -f "$parent_file" ]; then
        warn "$relpath — parent file not found: ${parent_file#$VAULT_ROOT/}"
        SUMMARIES_CHECKED=$((SUMMARIES_CHECKED + 1))
        return
    fi

    local source_updated parent_updated
    source_updated=$(extract_field_from_file "$summary_file" "source_updated")
    parent_updated=$(extract_field_from_file "$parent_file" "updated")

    if [ -z "$source_updated" ]; then
        warn "$relpath — missing source_updated field"
        SUMMARIES_STALE=$((SUMMARIES_STALE + 1))
    elif [ -z "$parent_updated" ]; then
        warn "$relpath — parent missing updated field"
    elif [ "$source_updated" != "$parent_updated" ]; then
        error "$relpath — STALE (source_updated: $source_updated, parent updated: $parent_updated)"
        SUMMARIES_STALE=$((SUMMARIES_STALE + 1))
    fi

    SUMMARIES_CHECKED=$((SUMMARIES_CHECKED + 1))
}

if [ "$SCOPE" = "staged" ]; then
    # Check summaries that were staged directly
    while IFS= read -r relpath; do
        [ -z "$relpath" ] && continue
        [ -f "$VAULT_ROOT/$relpath" ] && check_summary_freshness "$VAULT_ROOT/$relpath"
    done < <(echo "$STAGED_FILES" | grep -- "-summary\.md$" || true)
    # Also check summaries whose parent was staged (parent changed → summary may be stale)
    while IFS= read -r relpath; do
        [ -z "$relpath" ] && continue
        summary_path="${VAULT_ROOT}/${relpath%.md}-summary.md"
        [ -f "$summary_path" ] && check_summary_freshness "$summary_path"
    done < <(echo "$STAGED_FILES" | grep "\.md$" | grep -v -- "-summary\.md$" || true)
else
    while IFS= read -r -d '' summary_file; do
        check_summary_freshness "$summary_file"
    done < <(find "$VAULT_ROOT" -name "*-summary.md" -type f -print0 2>/dev/null)
fi

echo "  Checked $SUMMARIES_CHECKED summaries, $SUMMARIES_STALE stale"

# ============================================================================
# 3. SUMMARY SCHEMA COMPLETENESS
# Every *-summary.md must have a source_updated field in frontmatter.
# Without this field, the summary is invisible to all staleness detection.
# ============================================================================
echo ""
echo "=== 3. Summary Schema Completeness ==="

SUMMARY_SCHEMA_CHECKED=0
SUMMARY_SCHEMA_MISSING=0

check_summary_schema() {
    local summary_file="$1"
    local relpath="${summary_file#$VAULT_ROOT/}"
    SUMMARY_SCHEMA_CHECKED=$((SUMMARY_SCHEMA_CHECKED + 1))

    if ! has_frontmatter "$summary_file"; then
        error "$relpath — summary file has no frontmatter at all"
        SUMMARY_SCHEMA_MISSING=$((SUMMARY_SCHEMA_MISSING + 1))
        return
    fi

    local local_fm
    local_fm=$(extract_frontmatter "$summary_file")
    if ! grep -q "^source_updated:" <<< "$local_fm"; then
        error "$relpath — missing required source_updated field (invisible to staleness detection)"
        SUMMARY_SCHEMA_MISSING=$((SUMMARY_SCHEMA_MISSING + 1))
    fi
}

if [ "$SCOPE" = "staged" ]; then
    check_staged_by_name check_summary_schema "Projects Domains Sources _system/docs" "-summary.md"
else
    while IFS= read -r -d '' summary_file; do
        check_summary_schema "$summary_file"
    done < <(find "$VAULT_ROOT" -name "*-summary.md" -type f -print0 2>/dev/null)
fi

echo "  Checked $SUMMARY_SCHEMA_CHECKED summary files, $SUMMARY_SCHEMA_MISSING missing source_updated"

# ============================================================================
# 4. RUN-LOG STRUCTURAL INTEGRITY
# Verify every ## Session block contains required sections.
# ### Phase Transition blocks live INSIDE session blocks — they are checked in §5.
# ============================================================================
echo ""
echo "=== 4. Run-Log Structural Integrity ==="

RUNLOGS_CHECKED=0
RUNLOGS_INCOMPLETE=0

if [ "$SCOPE" = "staged" ] && ! has_staged_match "Projects/" "run-log"; then
    echo "  Skipped (no staged run-log files)"
else

check_runlog() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"
    local in_session=0
    local session_header=""
    local has_actions=0
    local has_state=0
    local has_files=0

    # Helper: check and report on the current session block
    _check_session_block() {
        if [ $in_session -eq 1 ]; then
            if [ $has_actions -eq 0 ] || [ $has_state -eq 0 ] || [ $has_files -eq 0 ]; then
                local missing=""
                [ $has_actions -eq 0 ] && missing="${missing}Actions Taken, "
                [ $has_state -eq 0 ] && missing="${missing}Current State, "
                [ $has_files -eq 0 ] && missing="${missing}Files Modified, "
                missing="${missing%, }"
                warn "$relpath — incomplete session block '$session_header' — missing: $missing"
                RUNLOGS_INCOMPLETE=$((RUNLOGS_INCOMPLETE + 1))
            fi
        fi
    }

    while IFS= read -r line; do
        # Strip \r for CRLF tolerance
        line="${line%$'\r'}"

        # Detect session headers
        if echo "$line" | grep -q "^## Session:"; then
            _check_session_block
            in_session=1
            session_header="$line"
            has_actions=0
            has_state=0
            has_files=0
            continue
        fi

        # Any other ## heading ends the current session block
        if [ $in_session -eq 1 ] && echo "$line" | grep -q "^## "; then
            _check_session_block
            in_session=0
            continue
        fi

        # Check for required sections within a session block
        if [ $in_session -eq 1 ]; then
            echo "$line" | grep -q "^\*\*Actions Taken:\*\*" && has_actions=1
            echo "$line" | grep -q "^\*\*Current State:\*\*" && has_state=1
            echo "$line" | grep -q "^\*\*Files Modified:\*\*" && has_files=1
        fi
    done < "$file"

    # Check the last block if it was a session
    _check_session_block

    RUNLOGS_CHECKED=$((RUNLOGS_CHECKED + 1))
}

# Find all run-log files
if [ -d "$VAULT_ROOT/Projects" ]; then
    while IFS= read -r -d '' file; do
        check_runlog "$file"
    done < <(find "$VAULT_ROOT/Projects" -name "run-log*.md" -type f -print0 2>/dev/null)
fi

echo "  Checked $RUNLOGS_CHECKED run-logs, $RUNLOGS_INCOMPLETE incomplete session blocks"
fi  # end scope guard for check 4

# ============================================================================
# 5. COMPOUND STEP CONTINUITY
# Verify every ### Phase Transition block has a Compound: field.
# ============================================================================
echo ""
echo "=== 5. Compound Step Continuity ==="

TRANSITIONS_CHECKED=0
TRANSITIONS_MISSING=0

if [ "$SCOPE" = "staged" ] && ! has_staged_match "Projects/" "run-log"; then
    echo "  Skipped (no staged run-log files)"
else

check_compound_continuity() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"
    local in_transition=0
    local transition_header=""
    local has_compound=0

    # Helper: check and report on the current transition block
    _check_transition_block() {
        if [ $in_transition -eq 1 ] && [ $has_compound -eq 0 ]; then
            error "$relpath — phase transition missing Compound field: '$transition_header'"
            TRANSITIONS_MISSING=$((TRANSITIONS_MISSING + 1))
        fi
    }

    while IFS= read -r line; do
        # Strip \r for CRLF tolerance
        line="${line%$'\r'}"

        if echo "$line" | grep -q "^### Phase Transition:"; then
            _check_transition_block
            in_transition=1
            transition_header="$line"
            has_compound=0
            TRANSITIONS_CHECKED=$((TRANSITIONS_CHECKED + 1))
            continue
        fi

        # Any heading (## or ###) ends the transition block
        if [ $in_transition -eq 1 ] && echo "$line" | grep -qE "^#{2,3} "; then
            _check_transition_block
            in_transition=0
            continue
        fi

        # Look for Compound: within the transition block
        if [ $in_transition -eq 1 ]; then
            echo "$line" | grep -q "Compound:" && has_compound=1
        fi
    done < "$file"

    # Check final block
    _check_transition_block
}

if [ -d "$VAULT_ROOT/Projects" ]; then
    while IFS= read -r -d '' file; do
        check_compound_continuity "$file"
    done < <(find "$VAULT_ROOT/Projects" -name "run-log*.md" -type f -print0 2>/dev/null)
fi

echo "  Checked $TRANSITIONS_CHECKED phase transitions, $TRANSITIONS_MISSING missing Compound field"
fi  # end scope guard for check 5

# ============================================================================
# 6. SESSION-LOG COMPOUND COMPLETENESS
# For every session-log entry with a non-empty Summary, verify Compound exists.
# ============================================================================
echo ""
echo "=== 6. Session-Log Compound Completeness ==="

SESSIONLOG_CHECKED=0
SESSIONLOG_MISSING=0

if [ "$SCOPE" = "staged" ] && ! has_staged_match "_system/logs/" "session-log"; then
    echo "  Skipped (no staged session-log files)"
else

check_session_log_compounds() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"
    local in_entry=0
    local entry_header=""
    local has_summary=0
    local has_compound=0

    # Helper: check and report on the current entry
    _check_entry() {
        if [ $in_entry -eq 1 ] && [ $has_summary -eq 1 ] && [ $has_compound -eq 0 ]; then
            warn "$relpath — session entry missing Compound field: '$entry_header'"
            SESSIONLOG_MISSING=$((SESSIONLOG_MISSING + 1))
        fi
    }

    while IFS= read -r line; do
        # Strip \r for CRLF tolerance
        line="${line%$'\r'}"

        # Detect session-log entry headers (## YYYY-MM-DD HH:MM — ...)
        if echo "$line" | grep -qE "^## [0-9]{4}-[0-9]{2}-[0-9]{2}"; then
            _check_entry
            in_entry=1
            entry_header="$line"
            has_summary=0
            has_compound=0
            SESSIONLOG_CHECKED=$((SESSIONLOG_CHECKED + 1))
            continue
        fi

        # Check for Summary with non-empty content
        if echo "$line" | grep -qE "^\*\*Summary:\*\*[[:space:]]*\S"; then
            has_summary=1
        fi

        echo "$line" | grep -q "^\*\*Compound:\*\*" && has_compound=1
    done < "$file"

    # Check final entry
    _check_entry
}

# Check session-log files in _system/logs/
for file in "$VAULT_ROOT"/_system/logs/session-log*.md; do
    [ -f "$file" ] && check_session_log_compounds "$file"
done

echo "  Checked $SESSIONLOG_CHECKED session entries, $SESSIONLOG_MISSING missing Compound field"
fi  # end scope guard for check 6

# ============================================================================
# 7. PROJECT SCAFFOLD COMPLETENESS
# Every directory in Projects/ must contain project-state.yaml,
# progress/run-log.md and progress/progress-log.md. Missing files indicate
# interrupted Project Creation Protocol or manual directory creation that
# bypassed the protocol.
# ============================================================================
echo ""
echo "=== 7. Project Scaffold Completeness ==="

PROJECTS_CHECKED=0
PROJECTS_INCOMPLETE=0

if [ "$SCOPE" = "staged" ] && ! has_staged_match "Projects/" ""; then
    echo "  Skipped (no staged project files)"
elif [ -d "$VAULT_ROOT/Projects" ]; then
    for project_dir in "$VAULT_ROOT/Projects"/*/; do
        [ -d "$project_dir" ] || continue
        project_name=$(basename "$project_dir")
        PROJECTS_CHECKED=$((PROJECTS_CHECKED + 1))

        if [ ! -f "$project_dir/project-state.yaml" ]; then
            warn "Projects/$project_name — missing project-state.yaml (pre-v1.5.3 project or interrupted creation)"
            PROJECTS_INCOMPLETE=$((PROJECTS_INCOMPLETE + 1))
        fi

        if [ ! -f "$project_dir/progress/run-log.md" ]; then
            error "Projects/$project_name — missing progress/run-log.md"
            PROJECTS_INCOMPLETE=$((PROJECTS_INCOMPLETE + 1))
        fi

        if [ ! -f "$project_dir/progress/progress-log.md" ]; then
            error "Projects/$project_name — missing progress/progress-log.md"
            PROJECTS_INCOMPLETE=$((PROJECTS_INCOMPLETE + 1))
        fi
    done
fi

echo "  Checked $PROJECTS_CHECKED projects, $PROJECTS_INCOMPLETE missing scaffold files"

# ============================================================================
# 8. TASK COMPLETION EVIDENCE
# For every task with state: complete in tasks.md, verify at least one
# ## Session block in the project's run-log.md references that task ID.
# A completed task with no run-log trace indicates a skipped log write
# or unvalidated state change.
# Reports as WARNINGS (not errors) — crash recovery may legitimately
# produce this state temporarily.
# ============================================================================
echo ""
echo "=== 8. Task Completion Evidence ==="

TASKS_COMPLETE_CHECKED=0
TASKS_MISSING_EVIDENCE=0

if [ "$SCOPE" = "staged" ] && ! has_staged_match "Projects/" "tasks.md" && ! has_staged_match "Projects/" "run-log"; then
    echo "  Skipped (no staged task or run-log files)"
elif [ -d "$VAULT_ROOT/Projects" ]; then
    for project_dir in "$VAULT_ROOT/Projects"/*/; do
        [ -d "$project_dir" ] || continue
        project_name=$(basename "$project_dir")
        tasks_file="$project_dir/tasks.md"
        runlog_file="$project_dir/progress/run-log.md"

        [ -f "$tasks_file" ] || continue

        # Extract task IDs with state: complete
        # Handles YAML-style task blocks with id and state fields
        # Uses awk to find id/state pairs within task entries
        current_id=""
        while IFS= read -r line; do
            line="${line%$'\r'}"

            # Capture task ID
            if echo "$line" | grep -qE "^[[:space:]]*id:[[:space:]]"; then
                current_id=$(echo "$line" | sed 's/^[[:space:]]*id:[[:space:]]*//')
            fi

            # Check state — if complete, verify evidence
            if echo "$line" | grep -qE "^[[:space:]]*state:[[:space:]]*complete"; then
                if [ -n "$current_id" ]; then
                    TASKS_COMPLETE_CHECKED=$((TASKS_COMPLETE_CHECKED + 1))

                    if [ ! -f "$runlog_file" ]; then
                        warn "Projects/$project_name — task $current_id is complete but no run-log.md exists"
                        TASKS_MISSING_EVIDENCE=$((TASKS_MISSING_EVIDENCE + 1))
                    elif ! grep -q "$current_id" "$runlog_file" 2>/dev/null; then
                        warn "Projects/$project_name — task $current_id is complete but not referenced in run-log.md"
                        TASKS_MISSING_EVIDENCE=$((TASKS_MISSING_EVIDENCE + 1))
                    fi
                fi
                current_id=""
            fi

            # Reset on new task boundary (blank line or new task marker)
            if [ -z "$line" ]; then
                current_id=""
            fi
        done < "$tasks_file"
    done
fi

echo "  Checked $TASKS_COMPLETE_CHECKED completed tasks, $TASKS_MISSING_EVIDENCE missing run-log evidence"

# ============================================================================
# 9. KNOWLEDGE BASE TAG VALIDATION
# Enforce canonical Level 2 #kb/ tags per spec §5.5. Three-level hierarchy
# with hard cap: #kb/ → #kb/[topic] → #kb/[topic]/[subtopic].
# Level 2 tags must be in the canonical list. Level 3 subtopics are open.
# Flags any Level 2 tag not in the defined set.
# ============================================================================
echo ""
echo "=== 9. Knowledge Base Tag Validation ==="

# Canonical Level 2 tags (from spec §5.5)
CANONICAL_KB_TAGS="religion philosophy gardening history inspiration poetry writing business networking security software-dev customer-engagement training-delivery fiction biography politics psychology lifestyle"

KB_TAGS_CHECKED=0
KB_TAGS_INVALID=0

check_kb_tags() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"
    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    # Extract all kb/ tags from frontmatter lines matching "  - kb/"
    # Handles both "  - kb/topic" and "  - kb/topic/subtopic"
    local kb_tags
    kb_tags=$(echo "$frontmatter" | grep -E "^[[:space:]]*-[[:space:]]+kb/" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/^kb\///' ) || true

    [ -z "$kb_tags" ] && return

    while IFS= read -r tag_path; do
        [ -z "$tag_path" ] && continue
        KB_TAGS_CHECKED=$((KB_TAGS_CHECKED + 1))

        # Extract Level 2 (first segment before any slash)
        local level2
        level2=$(echo "$tag_path" | cut -d'/' -f1)

        # Check depth — reject anything deeper than 3 levels (kb/topic/subtopic)
        local depth
        depth=$(echo "$tag_path" | awk -F'/' '{print NF}')
        if [ "$depth" -gt 2 ]; then
            error "$relpath — kb tag exceeds 3-level cap: #kb/$tag_path"
            KB_TAGS_INVALID=$((KB_TAGS_INVALID + 1))
            continue
        fi

        # Check Level 2 against canonical list
        local found=0
        for canonical in $CANONICAL_KB_TAGS; do
            if [ "$level2" = "$canonical" ]; then
                found=1
                break
            fi
        done

        if [ $found -eq 0 ]; then
            error "$relpath — non-canonical Level 2 kb tag: #kb/$level2 (full tag: #kb/$tag_path)"
            KB_TAGS_INVALID=$((KB_TAGS_INVALID + 1))
        fi
    done <<< "$kb_tags"
}

if [ "$SCOPE" = "staged" ]; then
    check_staged_in_dirs check_kb_tags Projects Domains Sources _system/docs
else
    for dir in Projects Domains Sources _system/docs; do
        if [ -d "$VAULT_ROOT/$dir" ]; then
            while IFS= read -r -d '' file; do
                check_kb_tags "$file"
            done < <(find "$VAULT_ROOT/$dir" -name "*.md" -type f -print0 2>/dev/null)
        fi
    done
fi

echo "  Checked $KB_TAGS_CHECKED kb tags, $KB_TAGS_INVALID invalid"

# ============================================================================
# 10. PROJECT-STATE ACTIVE TASK CONSISTENCY
# If project-state.yaml specifies a non-null active_task, verify:
#   (a) tasks.md exists
#   (b) the referenced task ID exists in tasks.md
#   (c) the referenced task is NOT in state: complete
# A stale or dangling active_task indicates a missed update after task
# completion or an interrupted session.
# Reports as ERRORS — a broken invariant, not a timing issue.
# ============================================================================
echo ""
echo "=== 10. Project-State Active Task Consistency ==="

PSTATE_CHECKED=0
PSTATE_INCONSISTENT=0

if [ "$SCOPE" = "staged" ] && ! has_staged_match "Projects/" "project-state.yaml" && ! has_staged_match "Projects/" "tasks.md"; then
    echo "  Skipped (no staged project-state or tasks files)"
elif [ -d "$VAULT_ROOT/Projects" ]; then
    for project_dir in "$VAULT_ROOT/Projects"/*/; do
        [ -d "$project_dir" ] || continue
        project_name=$(basename "$project_dir")
        pstate_file="$project_dir/project-state.yaml"
        tasks_file="$project_dir/tasks.md"

        [ -f "$pstate_file" ] || continue

        # Extract active_task value
        active_task=$(grep "^active_task:" "$pstate_file" | sed 's/^active_task:[[:space:]]*//' | tr -d '\r') || true

        # Skip null or empty
        if [ -z "$active_task" ] || [ "$active_task" = "null" ]; then
            PSTATE_CHECKED=$((PSTATE_CHECKED + 1))
            continue
        fi

        PSTATE_CHECKED=$((PSTATE_CHECKED + 1))

        # (a) tasks.md must exist — projects use either root or design/ location
        if [ ! -f "$tasks_file" ] && [ -f "$project_dir/design/tasks.md" ]; then
            tasks_file="$project_dir/design/tasks.md"
        fi
        if [ ! -f "$tasks_file" ]; then
            error "Projects/$project_name — project-state.yaml references active_task $active_task but tasks.md does not exist (checked project root and design/)"
            PSTATE_INCONSISTENT=$((PSTATE_INCONSISTENT + 1))
            continue
        fi

        # (b) task ID must appear in tasks.md (supports both YAML and markdown table formats)
        if ! grep -qE "(id:[[:space:]]*${active_task}|\\|[[:space:]]*${active_task}[[:space:]]*\\|)" "$tasks_file" 2>/dev/null; then
            error "Projects/$project_name — project-state.yaml active_task $active_task not found in tasks.md"
            PSTATE_INCONSISTENT=$((PSTATE_INCONSISTENT + 1))
            continue
        fi

        # (c) task must not be complete/done
        # Supports YAML format (id: / state: fields) and markdown table (| ID | desc | state | ...)
        task_state=""
        # Try YAML format first
        task_state=$(awk -v id="$active_task" '
            $0 ~ "id:[[:space:]]*" id { found=1; next }
            found && /^[[:space:]]*state:/ {
                sub(/^[[:space:]]*state:[[:space:]]*/, "")
                print
                exit
            }
            found && /^[[:space:]]*$/ { exit }
            found && /^[[:space:]]*id:/ { exit }
        ' "$tasks_file") || true

        # If no YAML match, try markdown table: | ID | desc | state | ...
        if [ -z "$task_state" ]; then
            task_state=$(awk -F'|' -v id="$active_task" '
            {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
                if ($2 == id) {
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4)
                    gsub(/\*/, "", $4)
                    print $4
                    exit
                }
            }' "$tasks_file") || true
        fi

        if [ "$task_state" = "complete" ] || [ "$task_state" = "done" ]; then
            error "Projects/$project_name — project-state.yaml active_task $active_task is marked $task_state in tasks.md"
            PSTATE_INCONSISTENT=$((PSTATE_INCONSISTENT + 1))
        fi
    done
fi

echo "  Checked $PSTATE_CHECKED project states, $PSTATE_INCONSISTENT inconsistent"

# ============================================================================
# 11. PROJECT-STATE LAST_COMMITTED FIELD
# Verify every project-state.yaml has a last_committed field.
# Warning level — backward compatible with pre-v1.5.4 projects.
# ============================================================================
echo ""
echo "=== 11. Project-State last_committed Field ==="

LAST_COMMITTED_CHECKED=0
LAST_COMMITTED_MISSING=0

if [ "$SCOPE" = "staged" ] && ! has_staged_match "Projects/" "project-state.yaml"; then
    echo "  Skipped (no staged project-state files)"
elif [ -d "$VAULT_ROOT/Projects" ]; then
    for project_dir in "$VAULT_ROOT/Projects"/*/; do
        [ -d "$project_dir" ] || continue
        project_name=$(basename "$project_dir")
        pstate_file="$project_dir/project-state.yaml"

        [ -f "$pstate_file" ] || continue
        LAST_COMMITTED_CHECKED=$((LAST_COMMITTED_CHECKED + 1))

        if ! grep -q "^last_committed:" "$pstate_file" 2>/dev/null; then
            warn "Projects/$project_name — project-state.yaml missing last_committed field"
            LAST_COMMITTED_MISSING=$((LAST_COMMITTED_MISSING + 1))
        fi
    done
fi

echo "  Checked $LAST_COMMITTED_CHECKED project states, $LAST_COMMITTED_MISSING missing last_committed"

# ============================================================================
# 12. DONE PROJECT DESIGN FILE WARNING
# Warn when design/ files have a `created` date after the project-state.yaml
# `updated` date in projects with phase: DONE. Catches scope creep into
# completed projects — new design work should go to a new project with
# related_projects linking.
# Reports as WARNINGS (non-blocking) — legitimate maintenance is allowed.
# ============================================================================
echo ""
echo "=== 12. DONE Project Design File Warning ==="

DONE_DESIGN_CHECKED=0
DONE_DESIGN_WARNED=0

if [ "$SCOPE" = "staged" ] && ! has_staged_match "Projects/" "design/"; then
    echo "  Skipped (no staged design files)"
elif [ -d "$VAULT_ROOT/Projects" ]; then
    for project_dir in "$VAULT_ROOT/Projects"/*/; do
        [ -d "$project_dir" ] || continue
        project_name=$(basename "$project_dir")
        pstate_file="$project_dir/project-state.yaml"

        [ -f "$pstate_file" ] || continue

        # Check if phase is DONE
        phase=$(grep "^phase:" "$pstate_file" | sed 's/^phase:[[:space:]]*//' | tr -d '\r') || true
        [ "$phase" = "DONE" ] || continue

        # Get project-state updated date (YYYY-MM-DD portion only)
        pstate_updated=$(grep "^updated:" "$pstate_file" | sed 's/^updated:[[:space:]]*//' | tr -d '\r' | cut -d' ' -f1) || true
        [ -n "$pstate_updated" ] || continue

        # Check each design/ file
        if [ -d "$project_dir/design/" ]; then
            while IFS= read -r -d '' design_file; do
                [ -f "$design_file" ] || continue
                DONE_DESIGN_CHECKED=$((DONE_DESIGN_CHECKED + 1))

                # Extract created date from frontmatter
                if has_frontmatter "$design_file"; then
                    local_fm=$(extract_frontmatter "$design_file")
                    file_created=$(extract_field "$local_fm" "created") || true
                    # Normalize to YYYY-MM-DD (strip any time component)
                    file_created=$(echo "$file_created" | cut -d' ' -f1) || true

                    if [ -n "$file_created" ] && [ "$file_created" \> "$pstate_updated" ]; then
                        relpath="${design_file#$VAULT_ROOT/}"
                        warn "$relpath created after project marked DONE (file: $file_created, project updated: $pstate_updated)"
                        DONE_DESIGN_WARNED=$((DONE_DESIGN_WARNED + 1))
                    fi
                fi
            done < <(find "$project_dir/design/" -name "*.md" -type f -print0 2>/dev/null)
        fi
    done
fi

echo "  Checked $DONE_DESIGN_CHECKED design files in DONE projects, $DONE_DESIGN_WARNED warnings"

# ============================================================================
# SHARED: Pre-built file cache for Domains/
# Built once here, used by checks 17, 18, and 20. Avoids per-iteration find calls.
# Format: newline-separated "basename|full_path" pairs.
# ============================================================================
DOMAINS_FILE_CACHE=""
if [ -d "$VAULT_ROOT/Domains" ]; then
    while IFS= read -r -d '' cached_file; do
        cached_bn=$(basename "$cached_file")
        DOMAINS_FILE_CACHE="${DOMAINS_FILE_CACHE}${cached_bn}|${cached_file}
"
    done < <(find "$VAULT_ROOT/Domains" -name "*.md" -type f -print0 2>/dev/null)
fi

# ============================================================================
# 17. MOC SCHEMA VALIDATION
# For every .md file with type: moc-orientation or type: moc-operational,
# verify required MOC-specific fields exist (scope, last_reviewed,
# review_basis, notes_at_review). Verify review_basis is one of:
# delta-only, full, restructure. Also enforce global filename uniqueness
# across all Domains/*/ directories. See spec §5.6.10.
# ============================================================================
echo ""
echo "=== 17. MOC Schema Validation ==="

MOC_CHECKED=0
MOC_ISSUES=0

# Track MOC filenames for uniqueness check (newline-separated "basename|relpath" pairs)
MOC_SEEN_FILES=""

check_moc_schema() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"
    local frontmatter
    frontmatter=$(extract_frontmatter "$file")
    local file_type
    file_type=$(extract_field "$frontmatter" "type")

    # Only check MOC files
    case "$file_type" in
        moc-orientation|moc-operational) ;;
        *) return ;;
    esac

    MOC_CHECKED=$((MOC_CHECKED + 1))

    # Check required MOC fields
    local moc_required="scope last_reviewed review_basis notes_at_review"
    local moc_missing=""
    for field in $moc_required; do
        if ! grep -q "^${field}:" <<< "$frontmatter"; then
            moc_missing="${moc_missing}${field}, "
        fi
    done

    if [ -n "$moc_missing" ]; then
        moc_missing="${moc_missing%, }"
        error "$relpath — MOC missing required fields: $moc_missing"
        MOC_ISSUES=$((MOC_ISSUES + 1))
    fi

    # Validate review_basis value
    local review_basis
    review_basis=$(extract_field "$frontmatter" "review_basis")
    if [ -n "$review_basis" ]; then
        case "$review_basis" in
            delta-only|full|restructure) ;;
            *)
                error "$relpath — invalid review_basis: '$review_basis' (must be delta-only, full, or restructure)"
                MOC_ISSUES=$((MOC_ISSUES + 1))
                ;;
        esac
    fi

    # Validate body structure — required section markers (load-bearing for Check 21 and navigation)
    local required_markers="DELTAS:START DELTAS:END SYNTHESIS:START SYNTHESIS:END CORE:START CORE:END"
    local missing_markers=""
    for marker in $required_markers; do
        if ! grep -q "<!-- ${marker} -->" "$file" 2>/dev/null; then
            missing_markers="${missing_markers}${marker}, "
        fi
    done
    if [ -n "$missing_markers" ]; then
        missing_markers="${missing_markers%, }"
        error "$relpath — MOC missing required body markers: $missing_markers"
        MOC_ISSUES=$((MOC_ISSUES + 1))
    fi

    # Track filename for uniqueness (bash 3.2 compatible — no associative arrays)
    # Uses awk exact string match to avoid regex issues (dots as wildcards, prefix matching)
    local bn
    bn=$(basename "$file")
    local prev_match
    prev_match=$(echo "$MOC_SEEN_FILES" | awk -F'|' -v f="$bn" '$1==f {print; exit}') || true
    if [ -n "$prev_match" ]; then
        local prev_path="${prev_match#*|}"
        error "$relpath — duplicate MOC filename '$bn' (also at $prev_path)"
        MOC_ISSUES=$((MOC_ISSUES + 1))
    else
        MOC_SEEN_FILES="${MOC_SEEN_FILES}${bn}|${relpath}
"
    fi
}

if [ "$SCOPE" = "staged" ]; then
    check_staged_in_dirs check_moc_schema Domains
else
    if [ -d "$VAULT_ROOT/Domains" ]; then
        while IFS= read -r -d '' file; do
            check_moc_schema "$file"
        done < <(find "$VAULT_ROOT/Domains" -name "*.md" -type f -print0 2>/dev/null)
    fi
fi

echo "  Checked $MOC_CHECKED MOC files, $MOC_ISSUES issues"

# ============================================================================
# 18. TOPICS RESOLUTION
# For every .md file with a topics field in frontmatter, verify each entry
# resolves to an existing MOC file in Domains/*/. Resolution: search for
# E.md in Domains/*/. Zero matches = error. Multiple matches = error.
# Resolved file must have type: moc-orientation or moc-operational.
# See spec §5.6.10.
# ============================================================================
echo ""
echo "=== 18. Topics Resolution ==="

TOPICS_RES_CHECKED=0
TOPICS_RES_ISSUES=0

check_topics_resolution() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"

    if ! has_frontmatter "$file"; then
        return
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    # Extract topics entries (lines matching "  - moc-*" or similar under topics:)
    local topics
    topics=$(echo "$frontmatter" | awk '
        /^topics:/ { in_topics=1; next }
        in_topics && /^[[:space:]]*-[[:space:]]/ { sub(/^[[:space:]]*-[[:space:]]*/, ""); print; next }
        in_topics && /^[a-zA-Z]/ { exit }
    ') || true

    [ -z "$topics" ] && return

    while IFS= read -r topic_entry; do
        [ -z "$topic_entry" ] && continue
        TOPICS_RES_CHECKED=$((TOPICS_RES_CHECKED + 1))

        # Search for topic_entry.md in Domains/*/ using pre-built cache (no per-iteration find)
        local target_bn="${topic_entry}.md"
        local cache_matches
        cache_matches=$(echo "$DOMAINS_FILE_CACHE" | awk -F'|' -v f="$target_bn" '$1==f {print $2}') || true
        local match_count=0
        local first_match=""
        if [ -n "$cache_matches" ]; then
            match_count=$(echo "$cache_matches" | wc -l | tr -d ' ')
            first_match=$(echo "$cache_matches" | head -1)
        fi

        if [ "$match_count" -eq 0 ]; then
            error "$relpath — unresolved topic: '$topic_entry' (no file found in Domains/*/)"
            TOPICS_RES_ISSUES=$((TOPICS_RES_ISSUES + 1))
        elif [ "$match_count" -gt 1 ]; then
            error "$relpath — ambiguous topic: '$topic_entry' resolves to multiple files"
            TOPICS_RES_ISSUES=$((TOPICS_RES_ISSUES + 1))
        else
            # Verify the resolved file is a MOC type
            local resolved_file="$first_match"
            local resolved_fm
            resolved_fm=$(extract_frontmatter "$resolved_file")
            local resolved_type
            resolved_type=$(extract_field "$resolved_fm" "type")
            case "$resolved_type" in
                moc-orientation|moc-operational) ;;
                *)
                    local resolved_relpath="${resolved_file#$VAULT_ROOT/}"
                    error "$relpath — topic '$topic_entry' resolves to $resolved_relpath but its type is '$resolved_type', not a MOC"
                    TOPICS_RES_ISSUES=$((TOPICS_RES_ISSUES + 1))
                    ;;
            esac
        fi
    done <<< "$topics"
}

if [ "$SCOPE" = "staged" ]; then
    check_staged_in_dirs check_topics_resolution Projects Domains Sources _system/docs Archived
else
    for dir in Projects Domains Sources _system/docs Archived; do
        if [ -d "$VAULT_ROOT/$dir" ]; then
            while IFS= read -r -d '' file; do
                check_topics_resolution "$file"
            done < <(find "$VAULT_ROOT/$dir" -name "*.md" -type f -print0 2>/dev/null)
        fi
    done
fi

echo "  Checked $TOPICS_RES_CHECKED topic entries, $TOPICS_RES_ISSUES issues"

# ============================================================================
# 19. TOPICS REQUIREMENT FOR KB-TAGGED NOTES
# For every .md file whose frontmatter tags[] contains any entry starting
# with kb/ AND whose type is NOT moc-orientation or moc-operational:
# verify that a topics field exists and contains >=1 entry.
# SEVERITY: WARNING (promoted to error after backfill is complete)
# See spec §5.6.10.
# ============================================================================
echo ""
echo "=== 19. Topics Requirement (kb-tagged notes) ==="

TOPICS_REQ_CHECKED=0
TOPICS_REQ_MISSING=0

check_topics_requirement() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"
    local basename
    basename=$(basename "$file")

    # Skip operational logs
    case "$basename" in
        run-log*.md|progress-log.md) return ;;
    esac

    if ! has_frontmatter "$file"; then
        return
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    # Check if file has any kb/ tags in frontmatter
    local has_kb_tag=0
    if grep -q "^[[:space:]]*-[[:space:]]*kb/" <<< "$frontmatter"; then
        has_kb_tag=1
    fi

    [ $has_kb_tag -eq 0 ] && return

    # Exempt MOC files — they carry kb/ tags but are targets of topics, not members
    local file_type
    file_type=$(extract_field "$frontmatter" "type")
    case "$file_type" in
        moc-orientation|moc-operational) return ;;
    esac

    TOPICS_REQ_CHECKED=$((TOPICS_REQ_CHECKED + 1))

    # Check for topics field with at least one entry
    local topics
    topics=$(echo "$frontmatter" | awk '
        /^topics:/ { in_topics=1; next }
        in_topics && /^[[:space:]]*-[[:space:]]/ { found=1 }
        in_topics && /^[a-zA-Z]/ { exit }
        END { print found+0 }
    ') || true

    if [ "$topics" -eq 0 ]; then
        # TODO: Promote to error after backfill completes (Phase 3D)
        warn "$relpath — kb-tagged note missing required 'topics' field"
        TOPICS_REQ_MISSING=$((TOPICS_REQ_MISSING + 1))
    fi
}

if [ "$SCOPE" = "staged" ]; then
    check_staged_in_dirs check_topics_requirement Projects Domains Sources _system/docs Archived
else
    for dir in Projects Domains Sources _system/docs Archived; do
        if [ -d "$VAULT_ROOT/$dir" ]; then
            while IFS= read -r -d '' file; do
                check_topics_requirement "$file"
            done < <(find "$VAULT_ROOT/$dir" -name "*.md" -type f -print0 2>/dev/null)
        fi
    done
fi

echo "  Checked $TOPICS_REQ_CHECKED kb-tagged notes, $TOPICS_REQ_MISSING missing topics"

# ============================================================================
# 20. SOURCE-INDEX SCHEMA VALIDATION
# For every .md file with type: source-index, verify required source subfields
# exist: source_id, title, author, source_type. Also verify topics field exists
# (source-index notes have kb/ tags and must participate in MOC system).
# See file-conventions.md Source Index Notes section.
# ============================================================================
echo ""
echo "=== 20. Source-Index Schema Validation ==="

SRCIDX_CHECKED=0
SRCIDX_ISSUES=0

check_source_index_schema() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"

    if ! has_frontmatter "$file"; then
        return
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")
    local file_type
    file_type=$(extract_field "$frontmatter" "type")

    [ "$file_type" = "source-index" ] || return 0

    SRCIDX_CHECKED=$((SRCIDX_CHECKED + 1))

    # Check required source subfields (nested YAML — grep for indented keys under source:)
    local source_required="source_id title author source_type"
    local source_missing=""
    for field in $source_required; do
        if ! grep -q "^[[:space:]]*${field}:" <<< "$frontmatter"; then
            source_missing="${source_missing}source.${field}, "
        fi
    done

    if [ -n "$source_missing" ]; then
        source_missing="${source_missing%, }"
        error "$relpath — source-index missing required fields: $source_missing"
        SRCIDX_ISSUES=$((SRCIDX_ISSUES + 1))
    fi

    # Verify topics field exists (source-index notes have kb/ tags)
    local has_topics=0
    if grep -q "^topics:" <<< "$frontmatter"; then
        has_topics=1
    fi
    if [ $has_topics -eq 0 ]; then
        error "$relpath — source-index missing required 'topics' field"
        SRCIDX_ISSUES=$((SRCIDX_ISSUES + 1))
    fi
}

if [ "$SCOPE" = "staged" ]; then
    check_staged_by_name check_source_index_schema "Sources Projects" "-index.md"
else
    for dir in Sources Projects; do
        if [ -d "$VAULT_ROOT/$dir" ]; then
            while IFS= read -r -d '' file; do
                check_source_index_schema "$file"
            done < <(find "$VAULT_ROOT/$dir" -name "*-index.md" -type f -print0 2>/dev/null)
        fi
    done
fi

echo "  Checked $SRCIDX_CHECKED source-index files, $SRCIDX_ISSUES issues"

# ============================================================================
# 21. MOC SYNTHESIS DENSITY + ONE-LINER QUALITY
# For orientation MOCs: if Core has >5 entries AND Synthesis has <30 words
# of prose, report as warning. Operational MOCs are exempt (they replace
# Synthesis with Steps/Procedure).
# Also: informational warning for Core one-liners shorter than 10 characters
# after the [[...]] link (per spec §5.6.6).
# See spec §5.6.10.
# ============================================================================
echo ""
echo "=== 21. MOC Synthesis Density + One-Liner Quality ==="

SYNTH_CHECKED=0
SYNTH_WARNED=0
ONELINER_WARNED=0


check_synthesis_density() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"

    if ! has_frontmatter "$file"; then
        return
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")
    local file_type
    file_type=$(extract_field "$frontmatter" "type")

    # Only check orientation MOCs for synthesis density
    # One-liner quality applies to both orientation and operational
    case "$file_type" in
        moc-orientation|moc-operational) ;;
        *) return ;;
    esac

    # --- One-liner quality check (§5.6.6) — applies to all MOC types ---
    # Warn if any Core one-liner has <10 chars after the [[...]] link

    local thin_oneliners
    thin_oneliners=$(awk '
        /<!-- CORE:START -->/ { in_core=1; next }
        /<!-- CORE:END -->/ { in_core=0; next }
        in_core && /^\- \[\[/ {
            # Strip everything up to and including ]] (the wikilink)
            line = $0
            sub(/^.*\]\]/, "", line)
            # Strip leading separators (space, dash, pipe, em/en dash)
            gsub(/^[[:space:]|_-]*/, "", line)
            # Count remaining characters (the description text)
            if (length(line) > 0 && length(line) < 10) {
                thin_count++
            }
        }
        END { print thin_count+0 }
    ' "$file") || true


    if [ "$thin_oneliners" -gt 0 ]; then
        warn "$relpath — $thin_oneliners Core one-liner(s) have <10 chars of description after the link (§5.6.6)"
        ONELINER_WARNED=$((ONELINER_WARNED + 1))
    fi

    # --- Synthesis density check — orientation MOCs only ---
    [ "$file_type" = "moc-orientation" ] || return 0

    SYNTH_CHECKED=$((SYNTH_CHECKED + 1))

    # Count Core entries (lines matching [[...]] between CORE:START and CORE:END)
    local core_count
    core_count=$(awk '
        /<!-- CORE:START -->/ { in_core=1; next }
        /<!-- CORE:END -->/ { in_core=0; next }
        in_core && /\[\[/ { count++ }
        END { print count+0 }
    ' "$file") || true

    [ "$core_count" -gt 5 ] || return 0

    # Count words in Synthesis section (between SYNTHESIS:START and SYNTHESIS:END)
    # Excludes HTML comments and headings. Uses word count instead of sentence
    # counting to avoid false positives from abbreviations and list items.
    local synth_words
    synth_words=$(awk '
        /<!-- SYNTHESIS:START -->/ { in_synth=1; next }
        /<!-- SYNTHESIS:END -->/ { in_synth=0; next }
        in_synth && /^[^<#]/ { for(i=1;i<=NF;i++) wc++; }
        END { print wc+0 }
    ' "$file") || true

    if [ "$synth_words" -lt 30 ]; then
        warn "$relpath — orientation MOC has $core_count Core entries but Synthesis has <30 words"
        SYNTH_WARNED=$((SYNTH_WARNED + 1))
    fi
}


if [ "$SCOPE" = "staged" ]; then
    check_staged_in_dirs check_synthesis_density Domains
else
    if [ -d "$VAULT_ROOT/Domains" ]; then
        while IFS= read -r -d '' file; do
            check_synthesis_density "$file"
        done < <(find "$VAULT_ROOT/Domains" -name "*.md" -type f -print0 2>/dev/null)
    fi
fi

echo "  Checked $SYNTH_CHECKED orientation MOCs, $SYNTH_WARNED with low synthesis density, $ONELINER_WARNED with thin one-liners"

# ============================================================================
# 22. REPO PATH VALIDATION
# If project-state.yaml declares repo_path, verify:
# 1. The directory exists
# 2. It is a git repository (contains .git/)
# Warning level — advisory, not blocking.
# ============================================================================
echo ""
echo "=== 22. Repo Path Validation ==="

REPO_PATH_CHECKED=0
REPO_PATH_ISSUES=0

if [ "$SCOPE" = "staged" ] && ! has_staged_match "Projects/" "project-state.yaml"; then
    echo "  Skipped (no staged project-state files)"
elif [ -d "$VAULT_ROOT/Projects" ]; then
    for project_dir in "$VAULT_ROOT/Projects"/*/; do
        [ -d "$project_dir" ] || continue
        project_name=$(basename "$project_dir")
        pstate_file="$project_dir/project-state.yaml"

        [ -f "$pstate_file" ] || continue

        repo_path=$(awk -F': ' '/^repo_path:/{print $2}' "$pstate_file")
        [ -n "$repo_path" ] || continue
        # Expand ~ to $HOME (tilde doesn't expand inside double quotes)
        repo_path="${repo_path/#\~/$HOME}"
        REPO_PATH_CHECKED=$((REPO_PATH_CHECKED + 1))

        if [ ! -d "$repo_path" ]; then
            warn "Projects/$project_name — repo_path '$repo_path' does not exist"
            REPO_PATH_ISSUES=$((REPO_PATH_ISSUES + 1))
        elif [ ! -d "$repo_path/.git" ]; then
            warn "Projects/$project_name — repo_path '$repo_path' exists but is not a git repo"
            REPO_PATH_ISSUES=$((REPO_PATH_ISSUES + 1))
        fi
    done
fi

echo "  Checked $REPO_PATH_CHECKED repo paths, $REPO_PATH_ISSUES issues"

# ============================================================================
# 23. Code Review Gate
# ============================================================================
# Projects with repo_path should have code review entries in run-log for
# completed code tasks. Surfaces gaps as warnings — same pattern as Check 8.
# Warning level — advisory, not blocking.
#
# Amnesty: tasks completed before the enforcement date are grandfathered.
# Determined by latest run-log session date (## YYYY-MM-DD) where task ID appears.
# Tasks never mentioned in run-log are also grandfathered (pre-discipline era).
# ============================================================================
echo ""
echo "=== 23. Code Review Gate ==="

CR_ENFORCEMENT_DATE="2026-03-20"
CR_TASKS_CHECKED=0
CR_TASKS_MISSING=0
CR_TASKS_GRANDFATHERED=0

if [ "$SCOPE" = "staged" ] && ! has_staged_match "Projects/" "tasks.md" && ! has_staged_match "Projects/" "run-log"; then
    echo "  Skipped (no staged task or run-log files)"
elif [ -d "$VAULT_ROOT/Projects" ]; then
    for project_dir in "$VAULT_ROOT/Projects"/*/; do
        [ -d "$project_dir" ] || continue
        project_name=$(basename "$project_dir")
        pstate_file="$project_dir/project-state.yaml"

        [ -f "$pstate_file" ] || continue

        # Only check projects with repo_path (code projects)
        repo_path=$(awk -F': ' '/^repo_path:/{print $2}' "$pstate_file")
        [ -n "$repo_path" ] || continue

        tasks_file="$project_dir/tasks.md"
        [ -f "$tasks_file" ] || continue

        # Find run-log
        run_log="$project_dir/progress/run-log.md"
        [ -f "$run_log" ] || continue

        # Parse done tasks from markdown table
        # Format: | ID | description | state | ... |
        # State column (3rd) contains "done" or "**done**"
        while IFS='|' read -r _ task_id _ task_state _; do
            # Trim whitespace
            task_id=$(echo "$task_id" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            task_state=$(echo "$task_state" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/\*//g')

            # Skip header, separator, and non-done rows
            if [ -z "$task_id" ] || echo "$task_id" | grep -q '^-' ; then
                continue
            fi
            if [ "$task_state" != "done" ]; then
                continue
            fi

            # Amnesty: find latest run-log session date where this task appears.
            # Session headers: ## YYYY-MM-DD — ...
            # Tasks completed before enforcement date (or never in run-log) are grandfathered.
            task_session_date=$(awk -v task="$task_id" '
                /^## [0-9]{4}-[0-9]{2}-[0-9]{2}/ { current_date = substr($2, 1, 10) }
                index($0, task) > 0 { found_date = current_date }
                END { print found_date }
            ' "$run_log")

            if [ -z "$task_session_date" ] || [[ "$task_session_date" < "$CR_ENFORCEMENT_DATE" ]]; then
                CR_TASKS_GRANDFATHERED=$((CR_TASKS_GRANDFATHERED + 1))
                continue
            fi

            CR_TASKS_CHECKED=$((CR_TASKS_CHECKED + 1))

            # Check run-log for code review entry mentioning this task ID
            # Accepts: "Code Review" heading/line containing the task ID
            # Also accepts: "Code Review — Skipped" entries
            if grep -q "Code Review.*$task_id" "$run_log" 2>/dev/null; then
                : # Review entry found
            elif grep -q "Code Review.*Skipped.*$task_id\|$task_id.*Code Review.*Skipped" "$run_log" 2>/dev/null; then
                : # Explicit skip found
            else
                warn "Projects/$project_name — task $task_id completed without code review entry in run-log"
                CR_TASKS_MISSING=$((CR_TASKS_MISSING + 1))
            fi
        done < "$tasks_file"
    done
fi

echo "  Checked $CR_TASKS_CHECKED post-enforcement tasks, $CR_TASKS_MISSING missing reviews, $CR_TASKS_GRANDFATHERED grandfathered (before $CR_ENFORCEMENT_DATE)"

# ============================================================================
# 24. RUN-LOG SIZE CHECK
# Flag run-logs that exceed a line count threshold and may need rotation.
# Skips: archived run-logs (status: archived) and DONE/ARCHIVED projects.
# Warning level — advisory, not blocking.
# ============================================================================
echo ""
echo "=== 24. Run-Log Size Check ==="

RUNLOG_SIZE_CHECKED=0
RUNLOG_SIZE_WARNINGS=0
RUNLOG_SIZE_THRESHOLD=1000

if [ "$SCOPE" = "staged" ] && ! has_staged_match "Projects/" "run-log"; then
    echo "  Skipped (no staged run-log files)"
elif [ -d "$VAULT_ROOT/Projects" ]; then
    while IFS= read -r -d '' file; do
        relpath="${file#$VAULT_ROOT/}"

        # Skip archived run-logs
        if has_frontmatter "$file"; then
            fm=$(extract_frontmatter "$file")
            fm_status=$(extract_field "$fm" "status")
            [ "$fm_status" = "archived" ] && continue
        fi

        # Skip DONE/ARCHIVED projects (run-log won't grow)
        project_dir=$(dirname "$(dirname "$file")")
        pstate="$project_dir/project-state.yaml"
        if [ -f "$pstate" ]; then
            project_phase=$(awk -F': ' '/^phase:/{print $2}' "$pstate" | tr -d ' "')
            case "$project_phase" in
                DONE|ARCHIVED) continue ;;
            esac
        fi

        RUNLOG_SIZE_CHECKED=$((RUNLOG_SIZE_CHECKED + 1))
        line_count=$(wc -l < "$file" | tr -d ' ')

        if [ "$line_count" -gt "$RUNLOG_SIZE_THRESHOLD" ]; then
            warn "$relpath — $line_count lines (threshold: $RUNLOG_SIZE_THRESHOLD) — consider rotation"
            RUNLOG_SIZE_WARNINGS=$((RUNLOG_SIZE_WARNINGS + 1))
        fi
    done < <(find "$VAULT_ROOT/Projects" -name "run-log*.md" -type f -print0 2>/dev/null)
fi

echo "  Checked $RUNLOG_SIZE_CHECKED active run-logs, $RUNLOG_SIZE_WARNINGS over threshold ($RUNLOG_SIZE_THRESHOLD lines)"

# ============================================================================
# 25. SIGNAL-NOTE SCHEMA VALIDATION
# For every .md file with type: signal-note, verify required source subfields
# exist: source_id, title, author, source_type, canonical_url, date_ingested,
# provenance (with inbox_canonical_id, triage_priority, triage_confidence).
# Also verify: schema_version, topics field, at least one kb/ tag, location
# is Sources/signals/. See file-conventions.md Signal Notes section.
# ============================================================================
echo ""
echo "=== 25. Signal-Note Schema Validation ==="

SIGNOTE_CHECKED=0
SIGNOTE_ISSUES=0

check_signal_note_schema() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"

    if ! has_frontmatter "$file"; then
        return
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")
    local file_type
    file_type=$(extract_field "$frontmatter" "type")

    [ "$file_type" = "signal-note" ] || return 0

    SIGNOTE_CHECKED=$((SIGNOTE_CHECKED + 1))

    # Check location — signal-notes must live in Sources/signals/
    case "$relpath" in
        Sources/signals/*)
            ;;
        *)
            error "$relpath — signal-note must be in Sources/signals/"
            SIGNOTE_ISSUES=$((SIGNOTE_ISSUES + 1))
            ;;
    esac

    # Check schema_version
    if ! grep -q "^schema_version:" <<< "$frontmatter"; then
        error "$relpath — signal-note missing required 'schema_version' field"
        SIGNOTE_ISSUES=$((SIGNOTE_ISSUES + 1))
    fi

    # Check required source subfields
    local source_required="source_id title author source_type canonical_url date_ingested"
    local source_missing=""
    for field in $source_required; do
        if ! grep -q "^[[:space:]]*${field}:" <<< "$frontmatter"; then
            source_missing="${source_missing}source.${field}, "
        fi
    done

    if [ -n "$source_missing" ]; then
        source_missing="${source_missing%, }"
        error "$relpath — signal-note missing required fields: $source_missing"
        SIGNOTE_ISSUES=$((SIGNOTE_ISSUES + 1))
    fi

    # Check provenance subfields
    local prov_required="inbox_canonical_id triage_priority triage_confidence"
    local prov_missing=""
    for field in $prov_required; do
        if ! grep -q "^[[:space:]]*${field}:" <<< "$frontmatter"; then
            prov_missing="${prov_missing}provenance.${field}, "
        fi
    done

    if [ -n "$prov_missing" ]; then
        prov_missing="${prov_missing%, }"
        error "$relpath — signal-note missing provenance fields: $prov_missing"
        SIGNOTE_ISSUES=$((SIGNOTE_ISSUES + 1))
    fi

    # Check topics field
    if ! grep -q "^topics:" <<< "$frontmatter"; then
        error "$relpath — signal-note missing required 'topics' field"
        SIGNOTE_ISSUES=$((SIGNOTE_ISSUES + 1))
    fi

    # Check at least one kb/ tag
    if ! grep -q "kb/" <<< "$frontmatter"; then
        error "$relpath — signal-note missing required #kb/ tag"
        SIGNOTE_ISSUES=$((SIGNOTE_ISSUES + 1))
    fi
}

if [ "$SCOPE" = "staged" ]; then
    check_staged_in_dirs check_signal_note_schema Sources Projects Domains _system/docs
else
    for dir in Sources Projects Domains _system/docs; do
        if [ -d "$VAULT_ROOT/$dir" ]; then
            while IFS= read -r -d '' file; do
                check_signal_note_schema "$file"
            done < <(find "$VAULT_ROOT/$dir" -name "*.md" -type f -print0 2>/dev/null)
        fi
    done
fi

echo "  Checked $SIGNOTE_CHECKED signal-note files, $SIGNOTE_ISSUES issues"

# ============================================================================
# 26. ATTENTION-ITEM SCHEMA VALIDATION
# For every .md file with type: attention-item, verify required fields exist:
# attention_id, kind, domain, status, urgency, schema_version, created, updated.
# Validate enum values for kind, domain, urgency, status.
# Location must be _inbox/attention/.
# ============================================================================
echo ""
echo "=== 26. Attention-Item Schema Validation ==="

ATTN_CHECKED=0
ATTN_ISSUES=0

check_attention_item_schema() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"

    if ! has_frontmatter "$file"; then
        return
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")
    local file_type
    file_type=$(extract_field "$frontmatter" "type")

    [ "$file_type" = "attention-item" ] || return 0

    ATTN_CHECKED=$((ATTN_CHECKED + 1))

    # Check location — attention items must live in _inbox/attention/
    case "$relpath" in
        _inbox/attention/*)
            ;;
        *)
            error "$relpath — attention-item must be in _inbox/attention/"
            ATTN_ISSUES=$((ATTN_ISSUES + 1))
            ;;
    esac

    # Check required fields
    local attn_required="attention_id kind domain status urgency schema_version created updated"
    local attn_missing=""
    for field in $attn_required; do
        if ! grep -q "^${field}:" <<< "$frontmatter"; then
            attn_missing="${attn_missing}${field}, "
        fi
    done

    if [ -n "$attn_missing" ]; then
        attn_missing="${attn_missing%, }"
        error "$relpath — attention-item missing required fields: $attn_missing"
        ATTN_ISSUES=$((ATTN_ISSUES + 1))
    fi

    # Validate enum values
    local kind_val
    kind_val=$(extract_field "$frontmatter" "kind")
    case "$kind_val" in
        system|relational|personal) ;;
        *) error "$relpath — attention-item invalid kind: '$kind_val' (valid: system, relational, personal)"
           ATTN_ISSUES=$((ATTN_ISSUES + 1)) ;;
    esac

    local urgency_val
    urgency_val=$(extract_field "$frontmatter" "urgency")
    case "$urgency_val" in
        now|soon|ongoing|awareness) ;;
        *) error "$relpath — attention-item invalid urgency: '$urgency_val' (valid: now, soon, ongoing, awareness)"
           ATTN_ISSUES=$((ATTN_ISSUES + 1)) ;;
    esac

    local status_val
    status_val=$(extract_field "$frontmatter" "status")
    case "$status_val" in
        open|in-progress|done|deferred|dismissed) ;;
        *) error "$relpath — attention-item invalid status: '$status_val' (valid: open, in-progress, done, deferred, dismissed)"
           ATTN_ISSUES=$((ATTN_ISSUES + 1)) ;;
    esac
}

if [ "$SCOPE" = "staged" ]; then
    check_staged_in_dirs check_attention_item_schema _inbox
else
    if [ -d "$VAULT_ROOT/_inbox/attention" ]; then
        while IFS= read -r -d '' file; do
            check_attention_item_schema "$file"
        done < <(find "$VAULT_ROOT/_inbox/attention" -name "*.md" -type f -print0 2>/dev/null)
    fi
fi

echo "  Checked $ATTN_CHECKED attention-item files, $ATTN_ISSUES issues"

# ============================================================================
# 27. DAILY-ATTENTION / ATTENTION-REVIEW SCHEMA VALIDATION
# Validates daily-attention and attention-review files in _system/daily/:
# - Location: must be in _system/daily/
# - Required field: skill_origin
# - Naming: daily-attention → YYYY-MM-DD.md, attention-review → review-YYYY-MM.md
# ============================================================================
echo ""
echo "=== 27. Daily-Attention Schema Validation ==="

DAILY_ATTN_CHECKED=0
DAILY_ATTN_ISSUES=0

check_daily_attention_schema() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"
    local basename
    basename=$(basename "$file")

    if ! has_frontmatter "$file"; then
        return 0
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")
    local file_type
    file_type=$(extract_field "$frontmatter" "type")

    # Only check daily-attention and attention-review types
    case "$file_type" in
        daily-attention|attention-review) ;;
        *) return 0 ;;
    esac

    DAILY_ATTN_CHECKED=$((DAILY_ATTN_CHECKED + 1))

    # Location constraint
    case "$relpath" in
        _system/daily/*)
            ;;
        *)
            error "$relpath — $file_type must be in _system/daily/"
            DAILY_ATTN_ISSUES=$((DAILY_ATTN_ISSUES + 1))
            return 0
            ;;
    esac

    # Required field: skill_origin
    if ! grep -q "^skill_origin:" <<< "$frontmatter"; then
        error "$relpath — $file_type missing required field: skill_origin"
        DAILY_ATTN_ISSUES=$((DAILY_ATTN_ISSUES + 1))
    fi

    # Naming convention check
    if [ "$file_type" = "daily-attention" ]; then
        if ! echo "$basename" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$'; then
            warn "$relpath — daily-attention filename should match YYYY-MM-DD.md"
            DAILY_ATTN_ISSUES=$((DAILY_ATTN_ISSUES + 1))
        fi
    elif [ "$file_type" = "attention-review" ]; then
        if ! echo "$basename" | grep -qE '^review-[0-9]{4}-[0-9]{2}\.md$'; then
            warn "$relpath — attention-review filename should match review-YYYY-MM.md"
            DAILY_ATTN_ISSUES=$((DAILY_ATTN_ISSUES + 1))
        fi
    fi
}

if [ "$SCOPE" = "staged" ]; then
    check_staged_in_dirs check_daily_attention_schema _system/daily
else
    if [ -d "$VAULT_ROOT/_system/daily" ]; then
        while IFS= read -r -d '' file; do
            check_daily_attention_schema "$file"
        done < <(find "$VAULT_ROOT/_system/daily" -name "*.md" -type f -print0 2>/dev/null)
    fi
fi

echo "  Checked $DAILY_ATTN_CHECKED daily-attention files, $DAILY_ATTN_ISSUES issues"

# ============================================================================
# 28. CROSS-PROJECT DEPENDENCY VALIDATION
# Validates _system/docs/cross-project-deps.md:
# - Referenced upstream projects must exist in Projects/ or be marked "No upstream project exists"
# - Active rows with existing upstream project and "not yet scoped" for >30 days get a warning
# ============================================================================
echo ""
echo "=== 28. Cross-Project Dependency Validation ==="

XDEP_ISSUES=0
XDEP_FILE="$VAULT_ROOT/_system/docs/cross-project-deps.md"

if [ -f "$XDEP_FILE" ]; then
    # Extract Active Dependencies table rows (skip header and separator lines)
    in_active=false
    while IFS= read -r line; do
        # Detect start of Active Dependencies table
        if echo "$line" | grep -q "^## Active Dependencies"; then
            in_active=true
            continue
        fi
        # Stop at next section
        if $in_active && echo "$line" | grep -q "^## "; then
            break
        fi
        # Skip non-table lines, header row, and separator row
        if ! $in_active; then continue; fi
        echo "$line" | grep -q "^|" || continue
        echo "$line" | grep -q "^| ID" && continue
        echo "$line" | grep -q "^|--" && continue

        # Parse columns: ID | Blocked Item | Waiting On | Upstream Project | Upstream Task | Status | Notes
        upstream_project=$(echo "$line" | awk -F'|' '{print $5}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        upstream_task=$(echo "$line" | awk -F'|' '{print $6}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        notes=$(echo "$line" | awk -F'|' '{print $8}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        dep_id=$(echo "$line" | awk -F'|' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Skip rows with no upstream project (marked with em-dash or noted as no project)
        if [ "$upstream_project" = "—" ] || echo "$notes" | grep -qi "no upstream project"; then
            continue
        fi

        # Check that upstream project directory exists (handle comma-separated lists)
        IFS=',' read -ra upstream_parts <<< "$upstream_project"
        for up in "${upstream_parts[@]}"; do
            up=$(echo "$up" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [ -n "$up" ] || continue
            # Skip system-level references like "crumb (system)"
            if echo "$up" | grep -qi "(system)"; then
                continue
            fi
            if [ ! -d "$VAULT_ROOT/Projects/$up" ] && [ ! -d "$VAULT_ROOT/Archived/Projects/$up" ]; then
                warn "$dep_id — upstream project '$up' not found in Projects/ or Archived/Projects/"
                XDEP_ISSUES=$((XDEP_ISSUES + 1))
            fi
        done

        # Warn on "not yet scoped" with existing upstream project (>30 days uses file mtime)
        if echo "$upstream_task" | grep -qi "not yet scoped"; then
            # Only warn if the file hasn't been updated recently (proxy for staleness)
            file_updated=$({ grep "^updated:" "$XDEP_FILE" || true; } | head -1 | awk '{print $2}')
            if [ -n "$file_updated" ]; then
                # Calculate days since last update
                file_epoch=$(date -j -f "%Y-%m-%d" "$file_updated" "+%s" 2>/dev/null) || true
                now_epoch=$(date "+%s")
                if [ -n "$file_epoch" ]; then
                    days_old=$(( (now_epoch - file_epoch) / 86400 ))
                    if [ "$days_old" -gt 30 ]; then
                        warn "$dep_id — upstream task in '$upstream_project' still 'not yet scoped' ($days_old days since file updated)"
                        XDEP_ISSUES=$((XDEP_ISSUES + 1))
                    fi
                fi
            fi
        fi
    done < "$XDEP_FILE"

    echo "  Cross-project deps: $XDEP_ISSUES issues"
else
    echo "  Cross-project deps file not found — skipping"
fi

# ============================================================================
# 29. CONTEXT INVENTORY COMPLETENESS
# When a run-log session block mentions a skill invocation, check that a
# context inventory was written. Enforcement heuristic: nudges before action
# (PreToolUse hook), hard gates at commit time (this check).
# Severity: warning — lightweight sessions may legitimately skip inventory.
# ============================================================================
echo ""
echo "=== 29. Context Inventory Completeness ==="

CTX_INV_SESSIONS=0
CTX_INV_MISSING=0
CTX_INV_GRANDFATHERED=0
CTX_INV_ENFORCEMENT_DATE="2026-03-20"

if [ "$SCOPE" = "staged" ] && ! has_staged_match "Projects/" "run-log"; then
    echo "  Skipped (no staged run-log files)"
else

check_context_inventory() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"
    local in_session=0
    local session_header=""
    local has_skill_mention=0
    local has_context_inventory=0

    # Known skill names that indicate a skill was invoked
    local skill_pattern="attention-manager\|systems-analyst\|action-architect\|researcher\|learning-plan\|feed-pipeline\|inbox-processor\|peer-review\|code-review\|deck-intel\|writing-coach\|audit\|vault-query"

    _check_ctx_inv() {
        if [ $in_session -eq 1 ] && [ $has_skill_mention -eq 1 ]; then
            # Extract session date from header (## YYYY-MM-DD ...)
            local session_date
            session_date=$(echo "$session_header" | { grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true; } | head -1)
            if [ -n "$session_date" ] && [[ "$session_date" < "$CTX_INV_ENFORCEMENT_DATE" ]]; then
                CTX_INV_GRANDFATHERED=$((CTX_INV_GRANDFATHERED + 1))
                return
            fi
            CTX_INV_SESSIONS=$((CTX_INV_SESSIONS + 1))
            if [ $has_context_inventory -eq 0 ]; then
                warn "$relpath — session '$session_header' mentions skill invocation but has no context inventory"
                CTX_INV_MISSING=$((CTX_INV_MISSING + 1))
            fi
        fi
    }

    while IFS= read -r line; do
        line="${line%$'\r'}"

        # Every H2 heading starts a new session block
        if echo "$line" | grep -q "^## "; then
            _check_ctx_inv
            in_session=1
            session_header="$line"
            has_skill_mention=0
            has_context_inventory=0
            continue
        fi

        if [ $in_session -eq 1 ]; then
            echo "$line" | grep -qi "$skill_pattern" && has_skill_mention=1
            # Match variations: "Context Inventory", "Context loaded", "Context:"
            echo "$line" | grep -qi "context inventory\|context loaded\|\*\*Context" && has_context_inventory=1
        fi
    done < "$file"

    _check_ctx_inv
}

if [ -d "$VAULT_ROOT/Projects" ]; then
    while IFS= read -r -d '' file; do
        check_context_inventory "$file"
    done < <(find "$VAULT_ROOT/Projects" -name "run-log*.md" -type f -print0 2>/dev/null)
fi

echo "  Skill sessions: $CTX_INV_SESSIONS, missing inventory: $CTX_INV_MISSING, $CTX_INV_GRANDFATHERED grandfathered (before $CTX_INV_ENFORCEMENT_DATE)"
fi  # end scope guard for check 29

# ============================================================================
# 30. SUBAGENT PROVENANCE CHECK
# When a run-log session block mentions subagent delegation, check that a
# provenance assessment was recorded. Subagent output flows into vault
# artifacts — this is a trust boundary that needs verification.
# Severity: warning — not all subagent uses produce vault-bound output.
# ============================================================================
echo ""
echo "=== 30. Subagent Provenance Check ==="

PROVENANCE_SESSIONS=0
PROVENANCE_MISSING=0
PROVENANCE_GRANDFATHERED=0
PROVENANCE_ENFORCEMENT_DATE="2026-03-20"

if [ "$SCOPE" = "staged" ] && ! has_staged_match "Projects/" "run-log"; then
    echo "  Skipped (no staged run-log files)"
else

check_provenance() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"
    local in_session=0
    local session_header=""
    local has_subagent_mention=0
    local has_provenance=0

    _check_prov() {
        if [ $in_session -eq 1 ] && [ $has_subagent_mention -eq 1 ]; then
            # Extract session date from header (## YYYY-MM-DD ...)
            local session_date
            session_date=$(echo "$session_header" | { grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true; } | head -1)
            if [ -n "$session_date" ] && [[ "$session_date" < "$PROVENANCE_ENFORCEMENT_DATE" ]]; then
                PROVENANCE_GRANDFATHERED=$((PROVENANCE_GRANDFATHERED + 1))
                return
            fi
            PROVENANCE_SESSIONS=$((PROVENANCE_SESSIONS + 1))
            if [ $has_provenance -eq 0 ]; then
                warn "$relpath — session '$session_header' mentions subagent delegation but has no provenance assessment"
                PROVENANCE_MISSING=$((PROVENANCE_MISSING + 1))
            fi
        fi
    }

    while IFS= read -r line; do
        line="${line%$'\r'}"

        # Every H2 heading starts a new session block
        if echo "$line" | grep -q "^## "; then
            _check_prov
            in_session=1
            session_header="$line"
            has_subagent_mention=0
            has_provenance=0
            continue
        fi

        if [ $in_session -eq 1 ]; then
            echo "$line" | grep -qi "subagent\|delegated to.*agent\|Agent tool\|agent returned" && has_subagent_mention=1
            echo "$line" | grep -qi "provenance\|provenance check\|provenance: verified\|constraints verified" && has_provenance=1
        fi
    done < "$file"

    _check_prov
}

if [ -d "$VAULT_ROOT/Projects" ]; then
    while IFS= read -r -d '' file; do
        check_provenance "$file"
    done < <(find "$VAULT_ROOT/Projects" -name "run-log*.md" -type f -print0 2>/dev/null)
fi

echo "  Subagent sessions: $PROVENANCE_SESSIONS, missing provenance: $PROVENANCE_MISSING, $PROVENANCE_GRANDFATHERED grandfathered (before $PROVENANCE_ENFORCEMENT_DATE)"
fi  # end scope guard for check 30

# ============================================================================
# 31. BROKEN WIKILINK DETECTION
# Scans markdown files for [[wikilinks]] and verifies each target resolves to
# a file in the vault. Obsidian uses shortest-path matching: [[filename]]
# matches any file with that basename. Path-prefixed links are vault-relative.
# Display text is stripped: [[file|Display Name]] checks "file".
# Reports broken links as warnings (non-blocking).
# ============================================================================
echo ""
echo "=== 31. Broken Wikilink Detection ==="

BROKEN_LINK_COUNT=0
BROKEN_LINK_FILES=0
FILES_SCANNED_LINKS=0

if has_staged_match "" ".md"; then

# Build file index as sorted temp files for grep-based lookup.
# macOS ships bash 3 which lacks associative arrays.
BASENAME_INDEX=$(mktemp)
RELPATH_INDEX=$(mktemp)
trap "rm -f '$BASENAME_INDEX' '$RELPATH_INDEX'" EXIT

# Index .md files: basenames (without .md) and relative paths (without .md)
find "$VAULT_ROOT" -name '*.md' \
    -not -path '*/.git/*' -not -path '*/.obsidian/*' -not -path '*/node_modules/*' \
    -type f 2>/dev/null | while IFS= read -r filepath; do
    relpath="${filepath#$VAULT_ROOT/}"
    basename "$filepath" .md | tr '[:upper:]' '[:lower:]'
    echo "${relpath%.md}" | tr '[:upper:]' '[:lower:]' >> "$RELPATH_INDEX"
done > "$BASENAME_INDEX"

# Index non-md files: basenames (with extension) and relative paths
find "$VAULT_ROOT" -not -name '*.md' \
    -not -path '*/.git/*' -not -path '*/.obsidian/*' -not -path '*/node_modules/*' \
    -type f 2>/dev/null | while IFS= read -r filepath; do
    relpath="${filepath#$VAULT_ROOT/}"
    basename "$filepath" | tr '[:upper:]' '[:lower:]' >> "$BASENAME_INDEX"
    echo "$relpath" | tr '[:upper:]' '[:lower:]' >> "$RELPATH_INDEX"
done

# Sort for binary search
sort -u -o "$BASENAME_INDEX" "$BASENAME_INDEX"
sort -u -o "$RELPATH_INDEX" "$RELPATH_INDEX"

resolve_link() {
    local target="$1"
    local lower
    lower=$(echo "$target" | tr '[:upper:]' '[:lower:]')

    # Path-prefixed resolution (target contains /)
    if [[ "$target" == */* ]]; then
        local lookup="${lower%.md}"
        grep -qxF "$lookup" "$RELPATH_INDEX" && return 0
        grep -qxF "$lower" "$RELPATH_INDEX" && return 0
    fi

    # Shortest-path (basename) resolution
    local base="${lower%.md}"
    base="${base##*/}"
    grep -qxF "$base" "$BASENAME_INDEX" && return 0

    # Try full name (for non-md files)
    local fullbase="${lower##*/}"
    grep -qxF "$fullbase" "$BASENAME_INDEX" && return 0

    return 1
}

check_wikilinks() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"
    local file_has_broken=0

    # Skip files that contain illustrative/example wikilinks by design
    # or derived state files that echo vault-check findings
    case "$relpath" in
        _system/docs/crumb-design-spec*) return 0;;
        */reviews/*) return 0;;
        .claude/skills/*/SKILL.md) return 0;;
        _openclaw/state/vault-health-notes.md) return 0;;
    esac

    # Extract wikilinks outside of code blocks.
    # First strip fenced code blocks (```...```) and inline code (`...`),
    # then extract [[target]] and [[target|display]] patterns.
    local links
    links=$(awk '
        /^```/ { in_fence = !in_fence; next }
        in_fence { next }
        { print }
    ' "$file" 2>/dev/null \
        | sed 's/`[^`]*`//g' \
        | grep -oE '\[\[[^]]+\]\]' \
        | sed 's/^\[\[//;s/\]\]$//' | sed 's/|.*//' | sed 's/^!//' | sort -u) || true

    [ -z "$links" ] && return 0

    while IFS= read -r target; do
        [ -z "$target" ] && continue
        # Skip external links
        case "$target" in http://*|https://*) continue;; esac
        # Skip anchor-only links
        [[ "$target" == \#* ]] && continue
        # Strip anchor
        target="${target%%#*}"
        [ -z "$target" ] && continue
        # Skip template/example placeholders commonly used in documentation
        case "$target" in
            ...|filename|note-title|note-name|source_id|source-id|slug) continue;;
        esac
        # Skip single-character links (A, B, etc. — used in spec examples)
        [ ${#target} -le 1 ] && continue
        # Skip links with trailing backslash (malformed escapes)
        [[ "$target" == *'\' ]] && continue
        # Skip links to .yaml files (Obsidian doesn't resolve these but they're valid vault references)
        [[ "$target" == *".yaml" ]] && continue
        # Skip links to binary files (not tracked in git but valid in local Obsidian vault)
        case "$target" in
            *.pptx|*.pdf|*.docx|*.xlsx|*.png|*.jpg|*.jpeg|*.gif|*.mp4|*.zip) continue;;
        esac
        [[ "$target" == *"project-state" ]] && continue
        # Skip template variables (curly braces — used in specs/reviews)
        [[ "$target" == *"{"* ]] && continue
        # Skip generic documentation terms used in reviews and how-to guides
        case "$target" in
            file|wikilink|wikilinks|project-name|goal-tracker|filename.pdf|docs/file) continue;;
        esac

        if ! resolve_link "$target"; then
            if [ "$file_has_broken" -eq 0 ]; then
                file_has_broken=1
                BROKEN_LINK_FILES=$((BROKEN_LINK_FILES + 1))
            fi
            BROKEN_LINK_COUNT=$((BROKEN_LINK_COUNT + 1))
            if [ "$BROKEN_LINK_COUNT" -le 20 ]; then
                warn "$relpath — broken link: [[${target}]]"
            fi
        fi
    done <<< "$links"
}

# Scan files
if [ "$SCOPE" = "staged" ]; then
    while IFS= read -r relpath; do
        [ -z "$relpath" ] && continue
        [[ "$relpath" != *.md ]] && continue
        local_abs="$VAULT_ROOT/$relpath"
        [ -f "$local_abs" ] && check_wikilinks "$local_abs" && FILES_SCANNED_LINKS=$((FILES_SCANNED_LINKS + 1))
    done <<< "$STAGED_FILES"
else
    while IFS= read -r -d '' file; do
        check_wikilinks "$file"
        FILES_SCANNED_LINKS=$((FILES_SCANNED_LINKS + 1))
    done < <(find "$VAULT_ROOT" -name '*.md' \
        -not -path '*/.git/*' \
        -not -path '*/.obsidian/*' \
        -not -path '*/node_modules/*' \
        -not -path '*/_scratch/*' \
        -type f -print0 2>/dev/null)
fi

if [ "$BROKEN_LINK_COUNT" -gt 20 ]; then
    echo "  ... and $((BROKEN_LINK_COUNT - 20)) more broken links (showing first 20)"
fi
echo "  Checked $FILES_SCANNED_LINKS files, $BROKEN_LINK_COUNT broken links in $BROKEN_LINK_FILES files"

fi  # end scope guard for check 31

# ============================================================================
echo ""
echo "=== Solution Doc Track Schema ==="

TRACK_ISSUES=0
TRACK_CHECKED=0

check_solution_track() {
    local file="$1"
    local relpath="${file#$VAULT_ROOT/}"

    # Skip spec/summary files that live in solutions dir
    case "$(basename "$file")" in
        *-spec*) return 0;;
    esac

    TRACK_CHECKED=$((TRACK_CHECKED + 1))

    local track
    track=$(awk '/^---$/{if(++c==2)exit} c==1{print}' "$file" 2>/dev/null | { grep '^track:' || true; } | head -1 | sed 's/^track:[[:space:]]*//')

    if [ -z "$track" ]; then
        warn "$relpath — missing 'track' field (required: bug | pattern | convention)"
        TRACK_ISSUES=$((TRACK_ISSUES + 1))
        return 0
    fi

    case "$track" in
        bug|pattern|convention) ;;
        *)
            warn "$relpath — invalid track value '$track' (must be: bug | pattern | convention)"
            TRACK_ISSUES=$((TRACK_ISSUES + 1))
            ;;
    esac
}

if [ "$SCOPE" = "staged" ]; then
    while IFS= read -r relpath; do
        [ -z "$relpath" ] && continue
        [[ "$relpath" != _system/docs/solutions/*.md ]] && continue
        local_abs="$VAULT_ROOT/$relpath"
        [ -f "$local_abs" ] && check_solution_track "$local_abs"
    done <<< "$STAGED_FILES"
else
    while IFS= read -r -d '' file; do
        check_solution_track "$file"
    done < <(find "$VAULT_ROOT/_system/docs/solutions" -name '*.md' -type f -print0 2>/dev/null)
fi

echo "  Checked $TRACK_CHECKED solution docs, $TRACK_ISSUES track issues"

# ============================================================================
echo ""
echo "=== Primitive Registry ==="

# Registered skills (directory names under .claude/skills/)
REGISTERED_SKILLS="action-architect attention-manager audit checkpoint code-review critic deck-intel deliberation diagram-capture feed-pipeline inbox-processor learning-plan mermaid peer-review researcher startup sync systems-analyst vault-query writing-coach"

# Registered overlays (filenames under _system/docs/overlays/, excluding overlay-index.md)
REGISTERED_OVERLAYS="business-advisor.md career-coach.md design-advisor.md financial-advisor.md glean-prompt-engineer.md life-coach.md network-skills.md web-design-preference.md"

PRIM_ISSUES=0

# Check skills
if [ -d "$VAULT_ROOT/.claude/skills" ]; then
    for skill_dir in "$VAULT_ROOT/.claude/skills"/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name=$(basename "$skill_dir")
        if ! echo " $REGISTERED_SKILLS " | grep -q " $skill_name "; then
            warn "Unregistered skill: .claude/skills/$skill_name — add to vault-check REGISTERED_SKILLS list"
            PRIM_ISSUES=$((PRIM_ISSUES + 1))
        fi
    done
fi

# Check overlays
if [ -d "$VAULT_ROOT/_system/docs/overlays" ]; then
    for overlay_file in "$VAULT_ROOT/_system/docs/overlays"/*.md; do
        [ -f "$overlay_file" ] || continue
        overlay_name=$(basename "$overlay_file")
        [ "$overlay_name" = "overlay-index.md" ] && continue
        if ! echo " $REGISTERED_OVERLAYS " | grep -q " $overlay_name "; then
            warn "Unregistered overlay: _system/docs/overlays/$overlay_name — add to vault-check REGISTERED_OVERLAYS list"
            PRIM_ISSUES=$((PRIM_ISSUES + 1))
        fi
    done
fi

echo "  Primitive registry: $PRIM_ISSUES issues"

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "=========================================="
echo "Vault Check Summary"
echo "=========================================="
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo "RESULT: ERRORS FOUND (exit code 2)"
    echo "Fix errors before committing."
    exit 2
elif [ $WARNINGS -gt 0 ]; then
    echo ""
    echo "RESULT: WARNINGS (exit code 1)"
    echo "Non-blocking — review when convenient."
    exit 1
else
    echo ""
    echo "RESULT: CLEAN (exit code 0)"
    exit 0
fi
