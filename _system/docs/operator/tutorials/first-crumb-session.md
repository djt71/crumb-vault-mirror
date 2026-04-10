---
type: tutorial
status: active
domain: software
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Tutorial: First Crumb Session

Walk through a complete Crumb session — from SSH connection to session-end commit.

**Prerequisites:** Crumb deployed on the remote Mac per [[crumb-deployment-runbook]].

---

## Step 1: Connect

SSH into the Mac Studio and attach to tmux:

```bash
ssh studio              # or your configured alias
tmux attach             # reattach existing session, or:
tmux                    # start new session
```

**Expected outcome:** tmux session with Catppuccin Mocha status bar. Your shell is ready.

---

## Step 2: Start Claude Code

```bash
cd ~/crumb-vault
claude
```

**Expected outcome:** Claude Code launches. The session-startup hook runs automatically:

1. `git pull` — syncs latest vault state
2. `vault-check` — deferred to pre-commit hook (lightweight scan)
3. Obsidian CLI probe — confirms availability
4. Feed-intel inbox scan — reports item count and tier breakdown
5. Knowledge brief — displays 3-5 relevant AKM items based on recent vault activity

You see the formatted startup summary.

---

## Step 3: Understand CLAUDE.md

CLAUDE.md is the governance surface. Crumb loads it automatically. Key sections:

- **Workflow Routing** — determines which phases apply (software: 4-phase, knowledge: 3-phase, personal: 2-phase)
- **Risk-Tiered Approval** — what Crumb can do autonomously vs. what requires your approval
- **Context Rules** — document budget limits, frontmatter requirements
- **Behavioral Boundaries** — what's autonomous, what needs confirmation, what's never done

**Expected outcome:** You don't need to read CLAUDE.md yourself — Crumb follows it. But understanding the routing helps you predict what Crumb will do.

---

## Step 4: Give Crumb a Task

Tell Crumb what you want to work on. Examples:

- "Resume project documentation-overhaul" — Crumb reads `project-state.yaml` and run-log to reconstruct context
- "Process inbox" — triggers inbox-processor skill
- "Research X topic" — triggers researcher skill
- "Plan my day" — triggers attention-manager skill

**Expected outcome:** Crumb activates the appropriate skill, loads context from the vault, and begins working. Skills auto-activate based on trigger phrase matching.

---

## Step 5: Watch Active Knowledge Memory (AKM)

During the session, AKM surfaces relevant knowledge at three trigger points:

| Trigger | When | Items |
|---------|------|-------|
| Session start | Startup hook | 5 items |
| Skill activation | Before each skill runs | 3 items |
| New content | After creating `#kb/`-tagged notes | 5 items |

**Expected outcome:** You see knowledge briefs in the output — cross-domain connections, relevant prior work, compound insights. These are informational; no action required.

---

## Step 6: Complete Work

As Crumb works, it:
- Logs decisions and progress to `run-log.md` (project sessions) or `session-log.md` (non-project)
- Runs vault-check before committing
- Performs compound evaluation at phase transitions (identifies patterns, potential solutions)

**Expected outcome:** Work products appear in the vault. Run-log entries document what was done and why.

---

## Step 7: Session End

When you're done (or Crumb detects session end), the session-end sequence runs autonomously:

1. Log with compound evaluation
2. Failure-log if the session went poorly
3. Code review sweep for completed code tasks
4. Update `claude-ai-context.md` if project state changed
5. Build verification (if source files changed in a project with `build_command`)
6. Conditional commit (`git diff --stat HEAD` determines commit type)
7. `git push`

**Expected outcome:** Changes committed and pushed. No manual steps needed — the sequence is fully autonomous.

---

## Step 8: Detach

Detach from tmux (session persists for next time):

```bash
# Press Ctrl+A, then d
```

**Expected outcome:** tmux session remains running. Next SSH session, `tmux attach` picks up where you left off.

---

## What You've Learned

- How to connect (SSH → tmux → Claude Code)
- What happens at session startup (git pull, vault-check, AKM brief)
- How to give Crumb work (skill activation via trigger phrases)
- How AKM surfaces relevant knowledge during the session
- What happens at session end (autonomous logging, commit, push)
- How to detach without losing state

**Next:** See [[how-crumb-thinks]] for the mental model behind spec-first workflow and compound engineering.
