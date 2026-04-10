#!/usr/bin/env bash
# backup-status.sh — Writes backup status JSON for dashboard consumption.
# Checks vault backup (iCloud) and Time Machine.
# Runs via launchd every 15 minutes.
# Output: _system/logs/backup-status.json
set -eu

VAULT_ROOT="${VAULT_ROOT:-/Users/tess/crumb-vault}"
OUTPUT="$VAULT_ROOT/_system/logs/backup-status.json"
TMP_OUTPUT="${OUTPUT}.tmp"

BACKUP_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/crumb-backups"

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Vault backup: find latest file
vault_file="null"
vault_age="null"
vault_status="\"n/a\""
if [ -d "$BACKUP_DIR" ]; then
  latest=$(/bin/ls -1t "$BACKUP_DIR" 2>/dev/null | grep '^crumb-vault-.*\.tar\.gz$' | head -1)
  if [ -n "$latest" ]; then
    vault_file="\"$latest\""
    mtime=$(stat -f '%m' "$BACKUP_DIR/$latest" 2>/dev/null || echo "0")
    now=$(date +%s)
    age_hours=$(( (now - mtime) / 3600 ))
    vault_age="$age_hours"
    if [ "$age_hours" -gt 48 ]; then
      vault_status="\"error\""
    elif [ "$age_hours" -gt 26 ]; then
      vault_status="\"warn\""
    else
      vault_status="\"ok\""
    fi
  fi
fi

# Time Machine: query tmutil (may return empty if volume not yet mounted after boot)
tm_backup="null"
tm_age="null"
tm_status="\"unknown\""
tm_path=$(tmutil latestbackup 2>/dev/null || true)
if [ -z "$tm_path" ]; then
  # Try listbackups as fallback — latestbackup can fail if volume is still mounting
  tm_path=$(tmutil listbackups 2>/dev/null | tail -1 || true)
fi
if [ -n "$tm_path" ]; then
  # Extract timestamp: .../YYYY-MM-DD-HHMMSS.backup/...
  tm_ts=$(echo "$tm_path" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}' | head -1)
  if [ -n "$tm_ts" ]; then
    # Parse: 2026-03-12-203409 -> 2026-03-12T20:34:09
    tm_date="${tm_ts:0:10}"
    tm_time="${tm_ts:11:2}:${tm_ts:13:2}:${tm_ts:15:2}"
    tm_backup="\"${tm_date}T${tm_time}\""
    # Compute age in hours
    tm_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${tm_date}T${tm_time}" +%s 2>/dev/null || echo "0")
    if [ "$tm_epoch" -gt 0 ]; then
      now=$(date +%s)
      tm_age_hours=$(( (now - tm_epoch) / 3600 ))
      tm_age="$tm_age_hours"
      if [ "$tm_age_hours" -gt 6 ]; then
        tm_status="\"error\""
      elif [ "$tm_age_hours" -gt 2 ]; then
        tm_status="\"warn\""
      else
        tm_status="\"ok\""
      fi
    fi
  fi
fi

cat > "$TMP_OUTPUT" << ENDJSON
{
  "timestamp": "$timestamp",
  "vaultBackup": {
    "latestFile": $vault_file,
    "ageHours": $vault_age,
    "status": $vault_status
  },
  "timeMachine": {
    "latestBackup": $tm_backup,
    "ageHours": $tm_age,
    "status": $tm_status
  }
}
ENDJSON

mv "$TMP_OUTPUT" "$OUTPUT"
