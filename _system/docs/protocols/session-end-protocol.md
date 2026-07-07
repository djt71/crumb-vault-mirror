---
type: reference
domain: null
status: active
created: 2026-02-24
updated: 2026-07-04
tags:
  - protocol
  - session-management
---

# Session-End Protocol

Run the full sequence in one pass at session end. Do NOT prompt the user step-by-step.

## Procedure

### 1. Log with Compound Evaluation

- **Project sessions:** log to run-log.md
- **Non-project sessions:** log to `_system/logs/session-log.md` using the format below
  (skip if session was only a greeting or single-question lookup)

### 2. Project State Refresh (project sessions only)

Read `project-state.yaml` and verify `next_action` is consistent with the session's
outcomes — tasks completed, code committed, gates passed/failed, blockers resolved
or introduced. If stale, update:

- `next_action` — must reflect the actual current state, not what it said at session start
- `active_task` — clear if completed, set if a new task is in progress
- `updated` — current date

This is the most common drift vector: code gets committed but `next_action` still says
"pending commit." The next session inherits stale orientation and wastes time reconciling.

### 3. Failure Log (autonomous, conditional)

If the session went clearly poorly — repeated errors, dead ends, significant
rework, or user frustration — write a failure-log entry to
`_system/docs/failure-log.md` with diagnosis. This is Crumb's autonomous
assessment, not a user-prompted rating.

### 4. Code Review Sweep (conditional)

If this is a project session with `repo_path` and code tasks were completed:

1. Check run-log for code review entries matching each completed task ID
2. If any are missing:
   - Run Tier 1 review now (preferred), OR
   - Log explicit skip with reason: `Code Review — Skipped ({TASK_ID}): {reason}`
3. vault-check §23 validates this at commit time as a WARNING — this step is the behavioral prompt to act before the structural check fires

### 5. Build Verification (conditional)

If this is a project session with `repo_path` and `build_command` in `project-state.yaml`,
and source files were modified during the session (`.ts`, `.tsx`, `.js`, `.jsx`, or other
compiled source in the repo):

1. `cd` to `repo_path` and run `build_command`. Verify exit 0.
   - On failure: fix the build error before proceeding. Do not commit broken source.
2. If `services` is declared, restart each launchd service:
   ```bash
   launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/<label>.plist
   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/<label>.plist
   ```
   Log restarts to run-log.
3. If build was not needed (no source files changed), skip silently.

**Self-healing:** If `repo_path` exists and has a build step (`tsconfig.json` or `build`
script in `package.json`) but `build_command` is missing from `project-state.yaml`, add it
now and log the addition. Same for `services` — if launchd plists reference the repo path
but aren't listed in project-state, add them. This catches projects created before these
fields existed, or sessions where project creation step 3b/3c was missed.

This step ensures compiled artifacts (`dist/`) match committed source. Tests run via
`ts-node` hit source directly and will not catch a stale `dist/`.

### 6. QMD Index Update (conditional)

If `qmd` is available (`command -v qmd`), run `qmd update` to re-index changed
files. Failure is non-blocking — log a warning and continue. (Consumer:
`knowledge-retrieve.sh` via the skill-preflight hook.)

### 7. Commit & Push

Check `git diff --stat HEAD` for uncommitted changes:

- **Log-only delta** (all changed files match `**/run-log*.md`, `**/session-log.md`,
  `**/progress-log.md`, `**/claude-ai-context.md`,
  `**/project-state.yaml`, `**/tasks.md`):
  Lightweight commit: `chore: session-end log — [description]`
- **Substantial delta** (any files outside the log/progress set):
  Flag to user: "Uncommitted work detected beyond session logs — [list files]."
  Commit with descriptive message covering all changes.
- **No changes:** Skip commit and push. Log note: "No uncommitted changes — skipping commit."

Commit safety rules (absorbed from the retired sync skill, 2026-07-07):
- Review the staged diff for sensitive content (credentials, API keys, tokens) before committing
- Stage specific files — never `git add -A` (avoids accidentally committing sensitive or unintended files)

Then `git push` (skip if no commit was made).

## Non-Project Session-Log Format

All four fields required — vault-check validates. Every entry gets exactly one of the 8 domains — pick the dominant one. No "cross-cutting" or "other."

```
## YYYY-MM-DD HH:MM — [Brief description]

**Domain:** [software · career · learning · health · financial · relationships · creative · spiritual · lifestyle]
**Summary:** [2-3 sentences: what was discussed, what was produced, any decisions made]
**Compound:** [insight summary and routing destination, OR "No compoundable insights"]
**Promote:** [no | declined — [brief reason] | project proposed: [name]]
```

## References

- Spec §6 (CLAUDE.md session management)
- Spec §4.8 (failure log)
