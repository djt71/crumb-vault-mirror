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
    
    # Prune old backups — keep last 30
    ls -t "$BACKUP_DIR"/crumb-vault-*.tar.gz 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null
    REMAINING=$(ls "$BACKUP_DIR"/crumb-vault-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
    echo "   Backups retained: $REMAINING"
else
    echo "ERROR: Backup failed" >&2
    exit 1
fi
