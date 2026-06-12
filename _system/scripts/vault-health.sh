#!/usr/bin/env bash
# vault-health.sh — Nightly vault health check (log-only)
#
# Rebuilt 2026-06-12 (agentic-sunset AS-019) from the retired bridge-layer
# version: notification delivery stripped, no bridge-layer dependencies.
# Alerting model is pull, not push — findings surface via the dashboard ops
# panel and the session-start hook, never as notifications.
#
# Three checks, all pure bash (zero LLM invocations):
#   1. vault-check.sh — frontmatter, staleness, conventions
#   2. git status — uncommitted changes (interrupted session indicator)
#   3. stale project-state — files unmodified for 14+ days
#
# Findings → _system/logs/vault-health-notes.md (removed when clean)
# Run log  → _system/logs/vault-health.log
#
# Schedule: nightly at 2 AM local via com.crumb.vault-health.

set -eu

# === Infrastructure ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/cron-lib.sh"

cron_init "vault-health" --wall-time 600 --jitter 30

# === Configuration ===
VAULT_CHECK_SCRIPT="$VAULT_ROOT/_system/scripts/vault-check.sh"
HEALTH_NOTES_FILE="$VAULT_ROOT/_system/logs/vault-health-notes.md"
LOG_FILE="$VAULT_ROOT/_system/logs/vault-health.log"

log() {
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

# === Check 1: vault-check.sh ===
check_vault() {
    local output exit_code
    output=$(bash "$VAULT_CHECK_SCRIPT" 2>&1) && exit_code=0 || exit_code=$?

    local error_count warning_count
    error_count=$(echo "$output" | sed -n 's/.*Errors:[[:space:]]*\([0-9]*\).*/\1/p')
    warning_count=$(echo "$output" | sed -n 's/.*Warnings:[[:space:]]*\([0-9]*\).*/\1/p')
    error_count=${error_count:-0}
    warning_count=${warning_count:-0}

    local findings
    findings=$(echo "$output" | grep -E "^\s+(ERROR|WARNING):" || true)

    VAULT_CHECK_EXIT=$exit_code
    VAULT_CHECK_ERRORS=$error_count
    VAULT_CHECK_WARNINGS=$warning_count
    VAULT_CHECK_FINDINGS="$findings"

    log "vault-check: exit=$exit_code errors=$error_count warnings=$warning_count"
}

# === Check 2: Git Status ===
check_git_status() {
    local output
    output=$(git -C "$VAULT_ROOT" status --short 2>/dev/null) || true

    if [[ -z "$output" ]]; then
        GIT_STATUS_CLEAN=true
        GIT_STATUS_OUTPUT=""
    else
        GIT_STATUS_CLEAN=false
        local file_count
        file_count=$(echo "$output" | wc -l | tr -d ' ')
        GIT_STATUS_OUTPUT="$file_count uncommitted file(s)"
    fi

    log "git-status: clean=$GIT_STATUS_CLEAN ${GIT_STATUS_OUTPUT:-}"
}

# === Check 3: Stale Project State ===
check_stale_projects() {
    local stale_files
    stale_files=$(find "$VAULT_ROOT/Projects" -name "project-state.yaml" -mtime +14 2>/dev/null) || true

    if [[ -z "$stale_files" ]]; then
        STALE_PROJECTS=""
        STALE_PROJECT_COUNT=0
    else
        STALE_PROJECT_COUNT=$(echo "$stale_files" | wc -l | tr -d ' ')
        STALE_PROJECTS=""
        while IFS= read -r filepath; do
            [[ -z "$filepath" ]] && continue
            local project_name
            project_name=$(echo "$filepath" | sed "s|$VAULT_ROOT/Projects/||;s|/project-state.yaml||")
            STALE_PROJECTS="${STALE_PROJECTS}${project_name}, "
        done <<< "$stale_files"
        STALE_PROJECTS="${STALE_PROJECTS%, }"
    fi

    log "stale-projects: count=$STALE_PROJECT_COUNT ${STALE_PROJECTS:-none}"
}

# === Write findings to notes file (dashboard / session-start surface) ===
write_health_notes() {
    local content="$1"
    local date_str
    date_str=$(date +"%Y-%m-%d")

    mkdir -p "$(dirname "$HEALTH_NOTES_FILE")"
    cat > "$HEALTH_NOTES_FILE" <<EOF
---
type: state
status: active
created: $date_str
updated: $date_str
---

# Vault Health Notes — $date_str

$content
EOF
    log "OK: wrote health notes to $HEALTH_NOTES_FILE"
}

# === Main ===
main() {
    VAULT_CHECK_EXIT=0
    VAULT_CHECK_ERRORS=0
    VAULT_CHECK_WARNINGS=0
    VAULT_CHECK_FINDINGS=""
    GIT_STATUS_CLEAN=true
    GIT_STATUS_OUTPUT=""
    STALE_PROJECTS=""
    STALE_PROJECT_COUNT=0

    check_vault
    check_git_status
    check_stale_projects

    local has_errors=false
    local has_warnings=false

    [[ "$VAULT_CHECK_ERRORS" -gt 0 ]] && has_errors=true
    [[ "$VAULT_CHECK_WARNINGS" -gt 0 ]] && has_warnings=true
    [[ "$GIT_STATUS_CLEAN" == "false" ]] && has_warnings=true
    [[ "$STALE_PROJECT_COUNT" -gt 0 ]] && has_warnings=true

    local notes_content=""
    if [[ "$VAULT_CHECK_ERRORS" -gt 0 ]]; then
        notes_content="${notes_content}## Errors (${VAULT_CHECK_ERRORS})
$(echo "$VAULT_CHECK_FINDINGS" | grep "ERROR:" || true)

"
    fi
    if [[ "$VAULT_CHECK_WARNINGS" -gt 0 ]]; then
        notes_content="${notes_content}## Warnings (${VAULT_CHECK_WARNINGS})
$(echo "$VAULT_CHECK_FINDINGS" | grep "WARNING:" || true)

"
    fi
    if [[ "$GIT_STATUS_CLEAN" == "false" ]]; then
        notes_content="${notes_content}## Git Status
${GIT_STATUS_OUTPUT}

"
    fi
    if [[ "$STALE_PROJECT_COUNT" -gt 0 ]]; then
        notes_content="${notes_content}## Stale Projects (14+ days)
${STALE_PROJECTS}

"
    fi

    if [[ "$has_errors" == "true" ]]; then
        write_health_notes "$notes_content"
        log "FINDINGS: ${VAULT_CHECK_ERRORS} error(s), ${VAULT_CHECK_WARNINGS} warning(s) — see health notes"
        cron_finish 1
    elif [[ "$has_warnings" == "true" ]]; then
        write_health_notes "$notes_content"
        log "OK: warnings only — written to health notes"
        cron_finish 0
    else
        rm -f "$HEALTH_NOTES_FILE" 2>/dev/null || true
        log "OK: vault clean"
        cron_finish 0
    fi
}

main
