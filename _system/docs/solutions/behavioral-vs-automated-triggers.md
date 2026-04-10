---
type: pattern
domain: software
status: active
track: pattern
created: 2026-03-08
updated: 2026-04-04
tags:
  - system-design
  - reliability
  - compound-insight
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Behavioral vs. Automated Triggers

## Pattern

System behaviors that depend on Claude remembering to do something (behavioral triggers) are unreliable under task momentum. System behaviors enforced by hooks, skill procedure steps, or pre-commit checks (automated triggers) are reliable.

## Evidence

**AKM knowledge retrieval (2026-03-08, attention-manager project):**

The Active Knowledge Memory system has two trigger types:
- `session-start` — automated via `session-startup.sh` hook. Fires every session. **Reliable.**
- `skill-activation` — behavioral. CLAUDE.md says: "when starting work on an IMPLEMENT task, run `knowledge-retrieve.sh --trigger skill-activation`". **Failed silently** during an entire session of attention-manager implementation (AM-001, AM-002, AM-003). Zero invocations out of three opportunities. Only caught because the operator tested for it.

The failure mode is **silent** — no error, no warning, no degraded output. The session produced good work without the KB context. The gap was invisible until explicitly probed.

## Design Heuristic

1. **Match the enforcement mechanism to the enforcement point.** Nudges before action (PreToolUse hooks), hard gates at commit time (vault-check pre-commit), behavioral obligations only for things that genuinely require judgment. Each mechanism has a natural scope — don't use a commit-time gate for something that needs to fire at skill activation, and don't use a behavioral trigger for something that can be mechanically enforced.
2. **The root cause is salience, not discipline.** Behavioral triggers fail because they lack salience at the moment of execution — task context dominates working memory. Framing this as "Claude needs to remember" leads to more behavioral instructions. Framing it as "the instruction lacks salience at execution time" leads to mechanical enforcement at the right moment.
3. **Silent failures are worse than loud ones.** A behavioral trigger that fails with no signal cannot be corrected. Design triggers so that skipping them is either impossible (automated) or visible (logged).
4. **PreToolUse hooks are the preferred enforcement mechanism** for skill-time obligations. They fire at maximum salience (right before skill execution), require zero behavioral compliance, and are universal (one hook covers all skills).
5. **vault-check pre-commit rules are the preferred enforcement mechanism** for post-execution obligations. They catch drift that hooks missed — context inventory completeness, subagent provenance, code review at milestones. Warnings at commit time are the last line of defense before state persists.

## Scope

Applies to any system behavior where Claude is the executor:
- Knowledge retrieval at task pickup
- Overlay loading at skill activation
- Compound evaluation at phase transitions (currently enforced via Context Checkpoint Protocol — good example of behavioral → procedural promotion)
- Session-end logging (enforced via CLAUDE.md + memory — partially behavioral, partially procedural)
- Subagent provenance check (CLAUDE.md line 185) — trust boundary, not skill-time

## Behavioral Obligation Inventory (2026-03-08)

Full audit of CLAUDE.md and skill procedures. Tiered by silent-failure risk.

### Tier 1: Silent failure + high value

| Obligation | Location | Enforcement | Status |
|---|---|---|---|
| Knowledge retrieval at skill activation | researcher, learning-plan, attention-manager, CLAUDE.md | PreToolUse hook on Skill | **Fixed** (phase 1) |
| Subagent provenance check | CLAUDE.md line 185 | vault-check §30 (warning) | **Partial** — commit-time warning; PostToolUse on Agent still open |
| Input validation before skill execution | CLAUDE.md line 60 | PreToolUse hook (required_inputs, critical_inputs) | **Fixed** (phase 2) |
| Context inventory to run-log | CLAUDE.md line 55 | vault-check §29 (warning) | **Partial** — commit-time warning; PostToolUse on Skill still open |
| Feed-pipeline project cross-post | feed-pipeline Step 5.9 | None | **Open** — mid-procedure; needs PostToolUse or vault-check rule |

### Tier 2: Visible failure but skippable

| Obligation | Location | Enforcement | Status |
|---|---|---|---|
| Code-review test gate | code-review Step 1 | None | Open — broken code dispatched to reviewers |
| Mermaid syntax validation | mermaid Step 4 | None | Open — user sees render failure |
| Excalidraw JSON validation | excalidraw Step 5 | None | Open — user sees file won't open |
| Researcher telemetry | researcher Step 5.2 | None | Open — noticed at audit time |

### Tier 3: Legitimate behavioral (judgment-dependent)

Inbox compound check, peer-review diff mode, partial dispatch recovery, MOC one-liner confirmation — these require human judgment or user interaction. Behavioral is the correct enforcement model.

### Enforcement Mechanism Map

| Hook point | Covers |
|---|---|
| PreToolUse on Skill | KB retrieval (done), input validation (done), reminders (done), query hints (done) |
| PostToolUse on Skill | Context inventory, telemetry, cross-posts |
| PostToolUse on Agent | Subagent provenance check |
| Pre-commit (vault-check) | Code review at milestones (§23), context inventory completeness (§29), subagent provenance (§30) |

## Fix Applied

**Phase 1 — Skill Preflight Hook (2026-03-08):**
- `PreToolUse` hook on the `Skill` tool fires `_system/scripts/skill-preflight.sh` before every skill invocation
- For KB-eligible skills: runs `knowledge-retrieve.sh --trigger skill-activation` and injects the brief as `additionalContext` — Claude sees it in reasoning context at the moment of skill execution
- For non-eligible skills (sync, checkpoint, mermaid, etc.): fast path, no subprocess, immediate exit
- Active project inferred mechanically from most recently modified `project-state.yaml` with an active phase (3-day staleness guard)
- Universal — covers all current and future skills without per-skill modification
- Registered in `.claude/settings.json` hooks config

**Phase 2 — Reminders, Input Validation, Query Hints (2026-03-08):**
- `skill-preflight-map.yaml` maps 16 skills with: `kb_eligible`, `query_hints`, `reminders`, `required_inputs`, `critical_inputs`
- **Query hints** solve the subject/domain mismatch: static per-skill keywords appended to BM25 args (e.g., attention-manager gets `attention focus priority cognitive time management`)
- **Reminders** surface procedural obligations as `additionalContext` at skill execution time (e.g., "Validate syntax before delivering" for mermaid)
- **Input validation:** `required_inputs` = warn and proceed; `critical_inputs` = deny with actionable message telling Claude why and what to do
- Skills not in the map default to `kb_eligible: true` with no extras — forward-compatible

**Phase 3 — vault-check Post-Execution Rules (2026-03-08):**
- Check 29 (Context Inventory Completeness): warns when run-log session blocks mention skill invocations but lack context inventory
- Check 30 (Subagent Provenance Check): warns when session blocks mention subagent delegation but lack provenance assessment
- These are commit-time safety nets — they catch drift that hooks missed, not replace hooks

**Known limitation (resolved):** Skills whose subject matter diverges from their project domain produced thin BM25 results. Fixed by `query_hints` in phase 2.

**Superseded:** Per-skill "Step 0: Knowledge Retrieval" approach. The attention-manager SKILL.md retains Step 0 during the parallel-run validation period (AM-004 soak). Will be removed once the hook-based retrieval is confirmed equivalent or better.

## Related

- Ceremony Budget Principle: behavioral triggers that get dropped are ceremony that suppresses adoption
- Context Checkpoint Protocol: example of promoting behavioral discipline to procedural enforcement
- AKM weight tuning (same session): book/chapter digests made timeless (no decay), PW boost changed to multiplicative
