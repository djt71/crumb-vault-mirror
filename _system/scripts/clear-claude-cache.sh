#!/bin/bash
# clear-claude-cache.sh -- Clear accumulated Claude Code session logs
# 
# Use when: Claude Code hangs or takes >30s to start up.
# Cause:    Session JSONL files accumulate in ~/.claude/projects/ and
#           Claude Code scans/indexes them on startup. Heavy sessions
#           (e.g., think-different with 44 profiles) produce multi-MB logs.
# Effect:   Loses ability to `claude --resume` into old sessions.
#           No impact on Crumb -- all state is in the vault, not in
#           Claude Code's conversation logs.
#
# Safe to run anytime. Preserves Claude Code's memory file.

set -euo pipefail

VAULT_NAME="-Users-dturner-crumb-vault"
PROJECT_DIR="$HOME/.claude/projects/$VAULT_NAME"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "No project cache found at $PROJECT_DIR"
    exit 0
fi

# Calculate current size
SIZE=$(du -sh "$PROJECT_DIR" | cut -f1)
FILE_COUNT=$(find "$PROJECT_DIR" -name "*.jsonl" | wc -l | tr -d ' ')

echo "Claude Code project cache: $SIZE across $FILE_COUNT session logs"

# Preserve memory directory if it exists
if [ -d "$PROJECT_DIR/memory" ]; then
    mv "$PROJECT_DIR/memory" /tmp/claude-memory-backup-$$
    HAS_MEMORY=true
else
    HAS_MEMORY=false
fi

# Clear everything
rm -rf "$PROJECT_DIR"/*

# Restore memory
if [ "$HAS_MEMORY" = true ]; then
    mv /tmp/claude-memory-backup-$$ "$PROJECT_DIR/memory"
    echo "Cleared $FILE_COUNT session logs. Memory preserved."
else
    echo "Cleared $FILE_COUNT session logs. No memory file found."
fi

echo "Done. Restart Claude Code -- startup should be near-instant."
