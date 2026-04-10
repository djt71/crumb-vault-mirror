---
type: protocol
domain: software
status: active
created: 2026-03-19
updated: 2026-03-19
---

# Research Brief Review Protocol

Tess produces research briefs in `_openclaw/research/output/` via overnight research runs.
Crumb reviews pending briefs and triages them into action categories.

## Triage Criteria

For each brief with `status: pending-review`:

1. **Completeness** — Did Tess produce a usable brief, or did source access fail?
2. **Signal strength** — Peer-reviewed study vs. blog post vs. tweet. Weight accordingly.
3. **Project relevance** — Does this genuinely affect active project design or decisions?
4. **Actionability** — Would this change how we build something, or is it just interesting?
5. **Timing** — Is this relevant during current project phases, or background noise?

## Triage Outcomes

### PROMOTE
Signal is strong, relevant, and connected to active work.

**Actions:**
1. Write a signal note to `Sources/signals/` with standard frontmatter
2. Add advisory run-log entries to each affected project's `progress/run-log.md`
3. Add `pending_signals` entries to each affected project's `project-state.yaml` (see below)
4. Move the original brief to `_openclaw/research/reviewed/`

**Run-log entry format:**
```
## YYYY-MM-DD — Signal: [Title]

**Signal:** [[signal-note-name]] — [One-line summary]
**Applicability:** [Why this matters to this project's active work]
**Action:** Evaluate at next project session. Advisory — not pre-approved for implementation.
```

**Critical: recommendations are advisory, not prescriptive.** Signal notes capture what was
found and how it connects to active work. Crumb evaluates whether to act on recommendations
at project resume time, considering current phase, priorities, and whether the signal still
applies. This is a judgement call — not an automatic implementation trigger.

### ARCHIVE
Interesting pattern or reference, not immediately actionable for any active project.

**Actions:**
1. Move to `_openclaw/research/reviewed/` with `status: reviewed` in frontmatter
2. No signal note, no run-log entries

### DISCARD
Brief is incomplete, duplicate, or source access failed.

**Actions:**
1. Move to `_openclaw/research/reviewed/` with `status: discarded` and a one-line reason
2. No further processing

## Procedure

1. Read all briefs in `_openclaw/research/output/` with `status: pending-review`
2. Assess each against triage criteria
3. Present triage recommendations to operator (1-2 sentences per item)
4. Operator approves or overrides
5. Process approved items per triage outcome
6. Verify `_openclaw/research/output/` is empty after processing

## Mechanical Signal Tracking — `pending_signals`

When promoting a signal to a project, add an entry to `pending_signals` in `project-state.yaml`:

```yaml
pending_signals:
  - signal: signal-note-filename-without-extension
    added: YYYY-MM-DD
    summary: "One-line project-specific implication"
```

This ensures signals are visible during session reconstruction — `project-state.yaml` is always
the first file read on resume, and a non-empty `pending_signals` list is hard to skip.

**Lifecycle:**
- **Added:** during research brief review, when a signal is promoted to a project
- **Evaluated:** at project resume, Crumb reads each pending signal and assesses applicability
- **Cleared:** after evaluation, remove the entry regardless of whether the recommendation
  was adopted. The signal note and run-log entry persist as permanent record; `pending_signals`
  is a transient attention mechanism, not a backlog.

## Project Resume Integration

When resuming a project with `pending_signals` entries in `project-state.yaml`:

1. Read each pending signal's linked signal note (in `Sources/signals/`)
2. Assess in current project context: does this change active design decisions or task priorities?
3. If yes: propose specific changes (new task, design update, constraint addition) — get operator approval
4. If no: note it as reviewed in run-log, explain why it doesn't apply now
5. Clear the `pending_signals` entry after evaluation — do not leave stale entries
6. Do not auto-implement signal recommendations without project-context evaluation
