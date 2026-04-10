---
type: reference
domain: null
skill_origin: null
status: active
created: 2026-02-15
updated: 2026-02-26
tags:
  - context-management
  - protocol
  - system-config
---

# Context Checkpoint Protocol

Proactive context management prevents mid-task failures and maintains system responsiveness. At phase transitions, this protocol also serves as the primary enforcement mechanism for compound engineering — ensuring compound reflection happens reliably rather than depending on behavioral discipline.

## Proactive Triggers

Check context BEFORE these events:
- Phase transitions (SPECIFY→PLAN, PLAN→TASK, TASK→IMPLEMENT, PLAN→ACT)
- Spawning subagents (Frontend Designer, Backend Designer)
- Invoking context-heavy skills (Systems Analyst, Action Architect)
- Ending session (ensure clean state for resume)

## Reactive Triggers

Check context WHEN these occur:
- Claude reports context warnings
- Output quality degrades unexpectedly (might be context exhaustion)
- Skills fail to load reference files (out of context space)
- Session feels sluggish or repetitive

## Procedure

### 1. Verify Phase Summaries

Generate or verify `*-summary.md` exists for all phase deliverables. Summaries are the primary context vehicle for downstream phases — if they're missing or stale, later phases operate on incomplete information.

### 2. Goal Progress Check (phase transitions only)

Before reflecting on the phase, evaluate progress against the project's acceptance criteria or task completion gates:
- Which acceptance criteria from the current phase are met, partially met, or unmet?
- Are any unmet criteria blockers for the next phase, or can they carry forward?
- If criteria were modified during the phase, note the change and rationale.

Record the assessment in the phase transition log entry (step 6). This ensures goal tracking is continuous — not just "did we finish?" but "are we converging on the right outcome?"

### 3. Compound Reflection (phase transitions only)

Before managing context, evaluate the phase that just completed against the compound step trigger criteria (see compound protocol): did this phase involve non-obvious decisions, rework, reusable artifacts, or system gaps? If yes, execute the full compound step procedure (reflect → route → execute) while the phase's working context is still loaded. If no, note the skip. Either way, the result is recorded in the phase transition log entry (step 6).

This step ensures compound engineering runs reliably — the evaluation is structurally guaranteed at every phase boundary.

### 4. Check Context Usage

Run `/context` command.

### 5. Evaluate Capacity

- **< 70%:** Proceed to next phase
- **70-85%:** Run `/compact` to compress context
- **> 85%:** Run `/clear` and reconstruct from vault files

### 6. Log Phase Transition

Write to `run-log.md`:

```markdown
### Phase Transition: [CURRENT] → [NEXT]
- Date: YYYY-MM-DD HH:MM
- [CURRENT] phase outputs: [list key files created]
- Goal progress: [acceptance criteria status — met/partial/unmet with brief notes]
- Compound: [insight summary and routing destination, OR "No compoundable insights from [PHASE] phase"]
- Context usage before checkpoint: [X]%
- Action taken: [none | compact | clear+reconstruct]
- Key artifacts for [NEXT] phase: [list summary files to load]
```

Also update `project-state.yaml`:

```yaml
phase: [NEXT]
last_gate: [CURRENT]-to-[NEXT]
active_task: null          # Reset — next phase assigns tasks
next_action: "[one sentence: what to do first in the next phase]"
updated: YYYY-MM-DD HH:MM
last_committed: YYYY-MM-DD HH:MM  # Updated at every git commit
```

### 7. Commit to Git

`git add` all changed vault files and `git commit`. This moves the durability boundary from "end of session" to "end of meaningful work unit." If the session crashes after this point, all phase work and state are recoverable from git.

### 8. Update Progress Log

Update `progress-log.md` with the phase transition. This keeps the project's high-level timeline current for orientation and resume operations.

### 9. Verify Phase Outputs

Before compacting/clearing, confirm all phase deliverables are written to disk.

### 10. Load Next Phase Context

Read relevant summary files for the upcoming phase:
- For PLAN: Load `specification-summary.md`
- For TASK: Load design summaries (`frontend-design-summary.md`, `backend-design-summary.md`)
- For IMPLEMENT: Load `tasks.md` and relevant design specs

### 11. Proceed to Next Phase

## Context Positioning Guidance

Position critical information at **attention-favored locations** — the beginning and end of context. Models exhibit empirically validated "lost-in-the-middle" attention decay: constraints buried in the center of a long context get ignored. Production agents have gone off-rails after ~15 tool calls because the original constraint was lost mid-context.

Practical rules:
- **System instructions and phase constraints:** Already positioned at context start (CLAUDE.md, system prompt) — no change needed
- **Mid-session critical constraints:** When re-stating constraints after compaction or long tool sequences, place them in the next user-facing message rather than burying them in tool output
- **Tool-output token share:** Tool outputs can consume up to ~84% of context tokens in production agents. When context pressure is high, this is the primary bloat vector — prefer targeted reads over full-file reads, and use summaries when the full document isn't needed
- **Mid-phase state summaries:** After 10+ consecutive tool calls within a single phase, insert a brief "done so far / remaining" summary into the next run-log or user-facing message. This prevents lost-in-the-middle drift where the original constraint gets buried under tool output. Not required at every tool call — only when the sequence is long enough that the original task framing has scrolled out of the attention-favored window

## Context Pressure Degradation Guide

Context capacity isn't binary — output quality degrades gradually before hitting a hard wall. As context fills, trade off scope for quality:

| Context Usage | Risk | Operational Adjustment |
|---|---|---|
| **<50%** | Minimal | Full capability — overlays, extended context, thorough compound reflection |
| **50-65%** | Low | Normal operation. Begin favoring summaries over full docs for new context loads |
| **65-75%** | Moderate | Skip optional overlays unless directly requested. Use MINIMAL triage for within-project lookups. Prefer targeted partial reads over full document loads. If tool-output volume is the primary context consumer, switch to summary-only reads and offset/limit parameters for large files |
| **75-85%** | High | **Minimum Safe Checkpoint first:** write/refresh `project-state.yaml` (including `next_action`), append partial run-log session block, and git commit. Then: compact before continuing. Skip discretionary compound steps (task-level). Load only MUST-have context — no MAY-request docs. Flag to user: "Context is getting tight; I'm operating in reduced mode" |
| **>85%** | Critical | Clear and reconstruct. Do not attempt substantive work — quality is unreliable |

These are operational guidelines, not mechanical enforcement. The key insight: **graceful degradation is better than full capability followed by sudden failure.** Shedding optional context early preserves quality for the work that matters.
