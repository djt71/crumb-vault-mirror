---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Session Lifecycle

Covers the four skills that bookend every session: startup, mid-session checkpointing, vault sync, and periodic audit. These compose into a repeatable session frame.

## Skills in This Workflow

### /startup
**Invoke:** automatic via session-startup hook, or `/startup` for formatted display
**Inputs:** `_system/scripts/session-startup.sh`, overlay index, run-logs, compound insight files
**Outputs:** formatted startup summary, log rotation if due, compound insight routing prompts
**What happens:**
- Runs startup script; displays verbatim summary block
- Flags stale summaries (3+), overdue full audit (7+ days), pending captures
- Routes pending compound insights: present each, prompt route / defer / dismiss

### /checkpoint
**Invoke:** phase transitions, before session end, when context >70%, project switches
**Inputs:** active run-log or session-log, `/context` output
**Outputs:** progress snapshot written to log, context health report
**What happens:**
- Writes current progress to run-log (project) or session-log (non-project)
- Checks context usage; compacts at >70%, clears at >85%
- Confirms all critical work is on disk before any context management

### /sync
**Invoke:** session end, after major milestones, before risky operations
**Inputs:** git repository state
**Outputs:** git commit, optional push, optional cloud backup trigger
**What happens:**
- Reviews `git status`; stages specific files (no `git add -A`)
- Creates conventional commit summarizing session work
- Pushes to remote and/or triggers backup if requested

### /audit
**Invoke:** automatic lightweight scan at session start; full audit on request or when startup flags it
**Inputs:** vault directory structure, summary files, run-log, failure-log (full audit only)
**Outputs:** findings report logged to run-log; stale summaries regenerated; issues flagged for review
**What happens:**
- Staleness scan: checks summary freshness, overlay index load, rotation status
- Full audit (weekly): spot-checks summaries, reviews solution docs, scans failure-log for patterns, checks KB health
- Monthly: adds skill activation review, CLAUDE.md drift check, hallucination spot-check

## Typical Flow

```
/startup → [session work] → /checkpoint (phase transitions or context pressure)
         → [more work]    → /checkpoint → /sync (session end)
```

Audit sits orthogonally: the lightweight staleness scan fires inside `/startup` every session. A full `/audit` runs when startup recommends it (7+ days elapsed or 3+ stale summaries) or when the operator requests it explicitly. Audit does not block the startup → work → sync flow — it runs before work begins or as a dedicated session.
