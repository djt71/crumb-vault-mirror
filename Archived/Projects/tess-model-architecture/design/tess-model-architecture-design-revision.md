---
type: design-revision
project: tess-model-architecture
domain: software
status: active
created: 2026-02-22
updated: 2026-02-22
source: claude-ai-session
tags:
  - local-llm
  - tess
  - openclaw
  - model-selection
  - tiering
---

# Design Revision: Revert Tiering Inversion

**Date:** 2026-02-22
**Source:** claude.ai session reviewing tess-local-llm-research-thread.md
**Affects:** §4 (Personality-First Tiering), §5 (Coder Model Justification), §6–7 (Peer Review Syntheses), Status & Decisions section

## Decision

Revert the personality-first tiering inversion established in the research thread. The architecture returns to **local-first for all traffic**, with cloud as escalation — not front-line.

## Rationale

The tiering inversion made Tess dependent on Anthropic API availability for every user-facing Telegram interaction. On reflection, the operator does not consider the persona fidelity improvement worth that dependency. The SOUL.md's second register is a quality goal, not a hard architectural requirement. A degraded-but-present Tess running locally is preferable to a high-fidelity Tess that goes mute when the API is down.

## What Changes

### Tiering architecture

| Aspect | Research thread (§4) | Revised |
|--------|---------------------|---------|
| User-facing traffic | Cloud (Haiku 4.5) | Local model |
| Mechanical/plumbing | Local (qwen3-coder:30b) | Local model (same or different) |
| Research/synthesis | Cloud (Sonnet 4.5) | Cloud (Sonnet 4.5) — escalation only |
| Anthropic dependency | Every interaction | Occasional escalation |
| Routing requirement | Route by audience (human clock vs machine clock) — CRITICAL blocker | Route to cloud on explicit escalation only — simpler problem |

### Model selection criteria

The coder-variant-first criterion (§5) was conditional on the tiering inversion — the local model's job was narrowed to mechanical schema execution, so IF scores dominated selection. With local handling everything including conversation, selection criteria shift:

- **Primary:** Balanced instruction-following + natural language quality
- **Secondary:** Tool-calling fidelity, structured output reliability
- **Tertiary:** Persona adherence (SOUL.md voice, tone calibration)

General instruct models (e.g., `qwen3:32b` dense) should be evaluated alongside coder variants. The coder variant may still win empirically, but the justification from §5 no longer holds as stated.

### Design contracts

The two-contract framework (ChatGPT R1 contribution) survives but changes shape:

- **Mechanical Contract:** Mostly intact. A single local model must satisfy deterministic tool calling, schema adherence, latency targets, uptime, context stability, and confirmation echo compliance. No change.
- **Persona Contract:** Demoted from "cloud model must satisfy" to "best-effort quality target for local model selection." Still defines what good looks like (SOUL.md fidelity, second register, judgment, ambiguity handling), but failure to fully satisfy is acceptable — it's a quality gradient, not a go/no-go gate.
- **Both contracts apply to the same model** rather than being split across two. This is a harder bar for one model but a simpler architecture overall.

### Routing

The critical-path blocker (research thread step 1: "can OpenClaw route by audience?") is substantially reduced. Base architecture no longer requires per-interaction routing between local and cloud. Routing simplifies to:

- Default: all traffic → local model
- Escalation: explicit research/synthesis tasks → cloud (Sonnet 4.5)
- Fallback: if local model fails → cloud retry (optional, not required)

This may still need investigation for the escalation path, but it's no longer the blocking prerequisite for everything else.

### Small-specialists pattern

With local handling all traffic and the persona constraint relaxed, the option of multiple small specialized models (7B–13B range, each tuned for a task domain) becomes architecturally viable again. This was the operator's original intuition before the persona-driven inversion. Worth exploring as a design option during model selection — could outperform a single 30B generalist on a per-task basis with comparable or lower total memory footprint.

This is a design option to evaluate, not a decision. The single-generalist approach may still win on simplicity and routing overhead.

### Risk register updates

| Risk | Change |
|------|--------|
| Anthropic API down → Tess goes mute | **Severity drops from HIGH to LOW.** Local-first means API outage only affects escalation tasks, not core operation. Limited Mode protocol becomes less critical. |
| OpenClaw can't route by task type | **Severity drops from CRITICAL to MEDIUM.** Base architecture doesn't require audience-based routing. Still relevant for cloud escalation path. |
| Haiku 4.5 can't carry SOUL.md second register | **Removed.** No longer selecting a cloud persona carrier. |
| Local model persona degradation | **New, MEDIUM.** Local model will deliver flatter persona than a frontier cloud model. Accepted as a known tradeoff. SOUL.md remains the voice target; gap is tolerated, not ignored. |
| Memory contention on shared 96GB | **Unchanged.** Still need empirical validation, especially if evaluating multiple small models. |
| Thermal throttling | **Unchanged.** |

### Next steps revision

Research thread next steps were ordered around the routing blocker. Revised priority:

1. **Re-evaluate model candidates.** Expand beyond coder variants to include general instruct models. Build a comparison matrix: qwen3-coder:30b vs qwen3:32b (dense) vs candidates in the small-specialist range (7B–13B). Include both mechanical benchmarks (tool calling, JSON validity, latency) and conversational quality (SOUL.md adherence using existing 10+ interaction sample).
2. **Revise design contracts.** Merge into a single unified contract that a local model must satisfy, with mechanical requirements as hard gates and persona requirements as scored quality targets.
3. **Build memory budget table.** Same as before — actual measurements under defined load shape. If evaluating multiple small models, measure concurrent footprint.
4. **Evaluate small-specialists vs single-generalist.** Compare: (a) one 30B model handling everything, (b) two or three smaller models with task-type routing. Assess quality, memory, routing complexity, operational overhead.
5. **Local model benchmark harness.** Expanded to include conversational quality scoring alongside mechanical benchmarks.
6. **Cloud escalation path.** Define when and how tasks escalate to Sonnet 4.5. Simpler than the original routing spec but still needs explicit criteria.
7. **Draft openclaw.json config.** Simpler now — single local primary, cloud escalation, no audience-based splitting.

### What survives unchanged

- No thinking model for Tess (hard blocker + architectural mismatch — unchanged)
- GLM-4.7-flash quarantined (Ollama template issues — unchanged)
- Manual config addition over `ollama launch openclaw` (preserve hardened config — unchanged)
- Confirmation echo as system safety invariant (unchanged)
- KV cache quantization strategy (unchanged, though q4_0 rationale weakens slightly since local model now produces user-facing text — may want q8_0 for quality)
- Persona evaluation rubric dimensions (repurposed for local model scoring)
