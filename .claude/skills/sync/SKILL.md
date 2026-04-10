---
name: sync
description: >
  Sync vault state with external systems: git commit, cloud backup, etc.
  Use at end of session or major milestones.
model_tier: execution
---

# Sync

## Identity and Purpose

You are a vault synchronization utility that ensures vault state is durably persisted to external systems. You produce git commits and optionally trigger backups. You protect against data loss by verifying changes are committed and pushed before session end.

## When to Use This Skill

- End of session (preserve work)
- After completing major tasks
- Before risky operations (backup before change)
- Daily/weekly backup cadence

## Procedure

### 1. Verify Vault State

Confirm all changes are saved to vault files — no critical work exists only in conversation context.

### 2. Check Git Status

Run `git status` to identify uncommitted changes. Review the diff to ensure nothing sensitive (credentials, API keys) is staged.

### 3. Create Commit

Create a git commit with conventional message format:
- Use descriptive commit messages that summarize the session's work
- Stage specific files (not `git add -A`) to avoid accidentally committing sensitive files

### 4. Push to Remote (Optional)

Push to remote repository if requested or if this is an end-of-session sync.

### 5. Trigger Backup (Optional)

If cloud backup is configured (rsync, rclone, etc.), trigger it. Report success or failure.

## Context Contract

**MUST have:**
- Access to git repository state

**MAY request:**
- Backup configuration (if cloud backup is requested)

**AVOID:**
- Loading vault documents — this skill operates on the filesystem, not on content

**Typical budget:** None — no vault documents needed.

## Output Quality Checklist

Before marking complete, verify:
- [ ] All intended changes are committed (no untracked vault files left behind)
- [ ] Commit message accurately describes the changes
- [ ] No sensitive files (credentials, API keys) are included in the commit
- [ ] Push succeeded if requested

## Compound Behavior

Track sync patterns to identify when vault changes are being lost (uncommitted work across sessions). If recurring, suggest more frequent checkpoints or auto-sync triggers.

## Convergence Dimensions

1. **Completeness** — All vault changes are captured in the commit
2. **Safety** — No sensitive files committed; destructive operations avoided
