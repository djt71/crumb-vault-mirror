---
name: checkpoint
description: >
  Checkpoint current state: log progress, compact context, verify vault files.
  Use when transitioning between major phases or ending a session.
model_tier: execution
---

# Checkpoint

## Identity and Purpose

You are a session management utility that captures current state, manages context pressure, and verifies vault durability. You produce a progress snapshot and context health report. You protect against lost work by ensuring all important outputs are persisted to the vault before context management operations.

## When to Use This Skill

- After completing a workflow phase
- Before ending a session
- When switching to a different project
- After major milestones
- When context pressure is building (>70% usage)

## Procedure

### 1. Log Current State

Write current progress to `run-log.md` (project sessions) or `_system/logs/session-log.md` (non-project sessions):
- What was accomplished since last checkpoint
- Current phase and status
- Any open questions or blockers

### 2. Check Context Usage

Run `/context` to check current usage level.

### 3. Manage Context Pressure

- If >70%: run `/compact`
- If >85%: run `/clear` + reconstruct from summaries
- If ≤70%: no action needed — report current level

### 4. Verify Vault Durability

Confirm all important outputs are in the vault (not just in chat):
- All documents mentioned in the run-log exist on disk
- Summary files are current
- No critical work exists only in conversation context

### 5. Return Summary

Report:
- What was checkpointed
- Context usage before and after any management action
- Any files verified or issues found

## Context Contract

**MUST have:**
- Access to current run-log or session-log
- Ability to run `/context` command

**MAY request:**
- Project state file (to verify phase alignment)

**AVOID:**
- Loading additional context during a checkpoint — the goal is to reduce context, not add to it

**Typical budget:** Minimal — this skill reads small state files only.

## Output Quality Checklist

Before marking complete, verify:
- [ ] Progress is logged to the appropriate log file
- [ ] Context usage is checked and managed if above threshold
- [ ] All critical outputs are confirmed on disk
- [ ] Summary of checkpoint actions is provided

## Compound Behavior

Track context usage patterns at checkpoint time to calibrate future phase-scoping decisions. If checkpoints consistently trigger compaction, the upstream skill may be loading too much context.

## Convergence Dimensions

1. **Completeness** — All checkpoint steps executed; nothing skipped
2. **Durability** — All critical work verified on disk before context management
