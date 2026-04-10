#!/bin/bash
# drive-sync.sh — Sync vault content to Google Drive
# Runs as danny (Google account owner).
# Schedule: hourly cron (baseline) + post-commit hook (event-triggered)
# Perplexity Computer depends on fresh vault data for daily operational awareness.
#
# Two sync targets:
#   1. NotebookLM: operator/architecture docs → .txt (NLM can't read .md)
#   2. Perplexity Computer: knowledge-level vault artifacts → .md
#
# Uses rclone sync --checksum for content-based sync.
# One-way push only — never pulls from Drive. No git conflict risk.

set -eu

VAULT_ROOT="/Users/tess/crumb-vault"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REMOTE="gdrive"
RCLONE_CONFIG="/Users/danny/.config/rclone/rclone.conf"
LOG="/tmp/drive-sync.log"

# Ensure log file is writable by both tess (post-commit) and danny (cron)
touch "$LOG" 2>/dev/null || true
chmod 666 "$LOG" 2>/dev/null || true

export RCLONE_CONFIG

# NotebookLM config
NLM_DRIVE_DIR="crumb-docs"
NLM_STAGING="/tmp/drive-sync-staging-nlm"
NLM_DIRS="architecture operator llm-orientation"

# Perplexity Computer config
COMPUTER_DRIVE_DIR="crumb-vault"
COMPUTER_FILTER="${SCRIPT_DIR}/drive-sync-computer-filter.txt"

log() {
    echo "$(date -Iseconds) $1" >> "$LOG"
}

# Verify rclone is available
if ! command -v rclone &>/dev/null; then
    log "ERROR: rclone not found"
    exit 1
fi

# Verify remote is configured
if ! rclone listremotes 2>/dev/null | grep -q "^${REMOTE}:$"; then
    log "ERROR: rclone remote '${REMOTE}' not configured. Run: rclone config"
    exit 1
fi

log "START drive-sync"

# ============================================================
# Target 1: NotebookLM (.md → .txt, curated directories)
# ============================================================
log "  NotebookLM sync: staging .md → .txt"

rm -rf "$NLM_STAGING"
mkdir -p "$NLM_STAGING"

for dir in $NLM_DIRS; do
    src="${VAULT_ROOT}/_system/docs/${dir}"
    if [ -d "$src" ]; then
        find "$src" -type d | while read -r d; do
            rel="${d#$src}"
            mkdir -p "${NLM_STAGING}/${dir}${rel}"
        done
        find "$src" -name "*.md" -type f | while read -r f; do
            rel="${f#$src/}"
            cp "$f" "${NLM_STAGING}/${dir}/${rel%.md}.txt"
        done
    else
        log "  WARN: ${src} does not exist, skipping"
    fi
done

rclone sync "$NLM_STAGING/" "${REMOTE}:${NLM_DRIVE_DIR}/" \
    --checksum \
    --log-file "$LOG" \
    --log-level NOTICE

rm -rf "$NLM_STAGING"
log "  NotebookLM sync: done"

# ============================================================
# Target 2: Perplexity Computer (.md preserved, filter-based)
# ============================================================

if [ ! -f "$COMPUTER_FILTER" ]; then
    log "  ERROR: Computer filter file not found at ${COMPUTER_FILTER}"
else
    log "  Computer sync: vault → Drive (filtered, .md preserved)"

    rclone sync "$VAULT_ROOT/" "${REMOTE}:${COMPUTER_DRIVE_DIR}/" \
        --filter-from "$COMPUTER_FILTER" \
        --checksum \
        --log-file "$LOG" \
        --log-level NOTICE

    log "  Computer sync: done"
fi

log "DONE drive-sync"
