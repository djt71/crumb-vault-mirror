#!/usr/bin/env bash
# vault-gc.sh — Centralized garbage collection for accumulating files
#
# Handles:
#   - Age-based purge of transient directories (dispatch, transcripts, relayed, etc.)
#   - Log/JSONL truncation to last N lines
#   - Code review raw JSON cleanup (30-day TTL)
#   - Inbox .processed safety net (session-end should clear, this catches stragglers)
#
# Designed to run daily via LaunchAgent. Safe to run manually.
# Follows existing conventions: set -eu, summary report, absolute paths.

set -eu

VAULT_ROOT="${VAULT_ROOT:-/Users/tess/crumb-vault}"

# Counters
total_deleted=0
total_truncated=0

log() {
  echo "[vault-gc] $1"
}

# --- Age-based purge ---
# Usage: purge_aged <directory> <days> <description> [<pattern>]
# Pattern defaults to "*" (all files). Directories are skipped.
purge_aged() {
  local dir="$1"
  local days="$2"
  local desc="$3"
  local pattern="${4:-*}"

  if [ ! -d "$dir" ]; then
    return
  fi

  local count=0
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    rm -f "$file"
    count=$((count + 1))
  done < <(find "$dir" -maxdepth 1 -name "$pattern" -type f -mtime +"$days" 2>/dev/null)

  if [ "$count" -gt 0 ]; then
    log "$desc: purged $count files older than ${days}d"
    total_deleted=$((total_deleted + count))
  fi
}

# --- Log truncation ---
# Usage: truncate_log <file> <max_lines>
# Keeps the last N lines. Atomic: write temp, then move.
truncate_log() {
  local file="$1"
  local max_lines="$2"

  if [ ! -f "$file" ]; then
    return
  fi

  local current_lines
  current_lines=$(wc -l < "$file")

  if [ "$current_lines" -le "$max_lines" ]; then
    return
  fi

  local tmpfile="${file}.gc-tmp"
  tail -n "$max_lines" "$file" > "$tmpfile"
  mv "$tmpfile" "$file"

  local trimmed=$((current_lines - max_lines))
  log "$(basename "$file"): truncated $trimmed lines (kept last $max_lines)"
  total_truncated=$((total_truncated + 1))
}

# ============================================================
# 1. Transient directories — 14-day TTL
# ============================================================

purge_aged "$VAULT_ROOT/_openclaw/outbox/relayed"   14 "outbox/relayed"
purge_aged "$VAULT_ROOT/_openclaw/dispatch"          14 "dispatch"
purge_aged "$VAULT_ROOT/_openclaw/transcripts"       14 "transcripts"

# ============================================================
# 2. Inbox .processed — 1-day TTL (safety net for session-end)
# ============================================================

purge_aged "$VAULT_ROOT/_openclaw/inbox/.processed"  1  "inbox/.processed"

# ============================================================
# 3. Code review raw JSON — 30-day TTL across all projects
# ============================================================

for review_dir in "$VAULT_ROOT"/Projects/*/reviews/raw; do
  [ -d "$review_dir" ] || continue
  project=$(echo "$review_dir" | sed "s|$VAULT_ROOT/Projects/||;s|/reviews/raw||")
  purge_aged "$review_dir" 30 "reviews/raw ($project)"
done

# ============================================================
# 4. BBP telemetry — 90-day TTL (operational records, keep longer)
# ============================================================

# ============================================================
# 4. Feed inbox TTL — 14-day TTL (feed-intel items only)
# ============================================================

purge_aged "$VAULT_ROOT/_openclaw/inbox" 14 "feed inbox" "feed-intel-*.md"

# ============================================================
# 5. Log truncation — keep last 1000 lines
# ============================================================

# OpenClaw operational logs
truncate_log "$VAULT_ROOT/_openclaw/logs/watcher.log"           1000
truncate_log "$VAULT_ROOT/_openclaw/logs/ops-metrics.jsonl"     1000
truncate_log "$VAULT_ROOT/_openclaw/logs/health-ping.log"       1000
truncate_log "$VAULT_ROOT/_openclaw/logs/health-ping-stderr.log" 500

# System logs
truncate_log "$VAULT_ROOT/_system/logs/mirror-sync.log"         1000
truncate_log "$VAULT_ROOT/_system/logs/akm-feedback.jsonl"      1000

# ============================================================
# Summary
# ============================================================

if [ "$total_deleted" -gt 0 ] || [ "$total_truncated" -gt 0 ]; then
  log "done: $total_deleted files purged, $total_truncated logs truncated"
else
  log "done: nothing to clean"
fi
