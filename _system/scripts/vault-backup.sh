#!/bin/bash
# vault-backup.sh — daily snapshot of crumb-vault to iCloud
# Includes .git directory for full history recovery
# Retention: 30 backups (~1 month at daily cadence)

VAULT="$HOME/crumb-vault"
BACKUP_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/crumb-backups"
TIMESTAMP=$(date +%Y-%m-%d_%H%M)
FILENAME="crumb-vault-${TIMESTAMP}.tar.gz"

# Verify vault exists
if [ ! -d "$VAULT" ]; then
    echo "ERROR: Vault not found at $VAULT" >&2
    exit 1
fi

# Create backup directory if needed
mkdir -p "$BACKUP_DIR"

# Create compressed archive (includes .git for full history)
tar -czf "$BACKUP_DIR/$FILENAME" -C "$(dirname "$VAULT")" "$(basename "$VAULT")"

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$BACKUP_DIR/$FILENAME" | cut -f1)
    echo "✅ Backup complete: $FILENAME ($SIZE)"

    # Marker for backup-status.sh — launchd context can't list the iCloud dir (TCC),
    # so status falls back to this file when the directory listing comes up empty
    MARKER="$VAULT/_system/logs/vault-backup-last.json"
    printf '{"latestFile": "%s", "epoch": %s, "sizeBytes": %s}\n' \
        "$FILENAME" "$(date +%s)" "$(stat -f '%z' "$BACKUP_DIR/$FILENAME")" > "$MARKER"


    # Prune old backups — keep last 30. Under launchd this listing is blocked
    # (TCC on the iCloud dir) and the prune is a no-op; the session-startup
    # hook runs the same prune from user context as the reliable path.
    ls -t "$BACKUP_DIR"/crumb-vault-*.tar.gz 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null
    REMAINING=$(ls "$BACKUP_DIR"/crumb-vault-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
    if [ "$REMAINING" -eq 0 ]; then
        echo "   NOTE: dir listing blocked (launchd TCC) — prune deferred to session-start hook"
    else
        echo "   Backups retained: $REMAINING"
    fi
else
    echo "ERROR: Backup failed" >&2
    exit 1
fi
