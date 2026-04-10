#!/usr/bin/env bash
# vault-health.sh — Nightly vault health check
#
# Source: tess-operations TOP-010
# Replaces: OpenClaw cron job (mechanic agent, sandbox can't read vault paths)
#
# Three checks, all pure bash (zero LLM invocations):
#   1. vault-check.sh — frontmatter, staleness, conventions (exit 0=clean, 1=warn, 2=error)
#   2. git status — uncommitted changes (interrupted session indicator)
#   3. stale project-state — files unmodified for 14+ days
#
# Delivery: Direct curl to Telegram Bot API.
#   - Errors → Telegram alert
#   - Warnings only → write to vault-health-notes.md (morning briefing picks up)
#   - Clean → silent
#
# Schedule: Nightly at 2 AM ET via launchd CalendarInterval.
#
# Infrastructure: sources cron-lib.sh for kill-switch, locking, metrics, wall-time.

set -eu

# === Infrastructure ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/cron-lib.sh"

cron_init "vault-health" --wall-time 600 --jitter 30

# === Configuration ===
TELEGRAM_BOT_TOKEN="${TESS_AWARENESS_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="7754252365"
VAULT_CHECK_SCRIPT="$VAULT_ROOT/_system/scripts/vault-check.sh"
HEALTH_NOTES_FILE="$BRIDGE_DIR/state/vault-health-notes.md"

# === Logging ===
LOG_FILE="$BRIDGE_DIR/logs/vault-health.log"

log() {
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"
}

# === Telegram Delivery ===
send_telegram() {
    local message="$1"

    if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
        log "ERROR: TESS_AWARENESS_BOT_TOKEN not set"
        echo "ERROR: TESS_AWARENESS_BOT_TOKEN not set" >&2
        return 1
    fi

    local response http_code body
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        --connect-timeout 10 \
        --max-time 15 \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d parse_mode="HTML" \
        --data-urlencode text="$message" \
        2>/dev/null)

    http_code=$(echo "$response" | tail -1 | sed 's/HTTP_CODE://')
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "200" ]]; then
        log "OK: Telegram sendMessage HTTP 200"
        cron_mark_alert
        return 0
    else
        log "ERROR: Telegram sendMessage HTTP $http_code — $body"
        echo "ERROR: Telegram sendMessage returned HTTP $http_code" >&2
        return 1
    fi
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

    # Extract specific error/warning lines
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
        # Extract project names from paths
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

# === Write warnings to notes file (for morning briefing) ===
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
    # Initialize result vars
    VAULT_CHECK_EXIT=0
    VAULT_CHECK_ERRORS=0
    VAULT_CHECK_WARNINGS=0
    VAULT_CHECK_FINDINGS=""
    GIT_STATUS_CLEAN=true
    GIT_STATUS_OUTPUT=""
    STALE_PROJECTS=""
    STALE_PROJECT_COUNT=0

    # Run all checks
    check_vault
    check_git_status
    check_stale_projects

    # Determine overall status
    local has_errors=false
    local has_warnings=false

    [[ "$VAULT_CHECK_ERRORS" -gt 0 ]] && has_errors=true
    [[ "$VAULT_CHECK_WARNINGS" -gt 0 ]] && has_warnings=true
    [[ "$GIT_STATUS_CLEAN" == "false" ]] && has_warnings=true
    [[ "$STALE_PROJECT_COUNT" -gt 0 ]] && has_warnings=true

    # Build health notes content (all findings for morning briefing)
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

    # Act on results
    if [[ "$has_errors" == "true" ]]; then
        # Summary-only Telegram — details stay in health notes
        local summary="vault-check: ${VAULT_CHECK_ERRORS} error(s), ${VAULT_CHECK_WARNINGS} warning(s)"
        if [[ "$GIT_STATUS_CLEAN" == "false" ]]; then
            summary="${summary}
git: ${GIT_STATUS_OUTPUT}"
        fi
        if [[ "$STALE_PROJECT_COUNT" -gt 0 ]]; then
            summary="${summary}
stale projects: ${STALE_PROJECT_COUNT}"
        fi
        local message
        message=$(printf "<b>Vault Health — Errors Found</b>\n\n%s\n\nSee vault-health-notes.md for details." "$summary")

        write_health_notes "$notes_content"
        send_telegram "$message" || true
        log "ALERT: errors found"
        cron_finish 1
    elif [[ "$has_warnings" == "true" ]]; then
        write_health_notes "$notes_content"
        log "OK: warnings only — written to health notes"
        cron_finish 0
    else
        # Clean — remove stale notes file if it exists
        rm -f "$HEALTH_NOTES_FILE" 2>/dev/null || true
        log "OK: vault clean"
        cron_finish 0
    fi
}

main
