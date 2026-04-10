---
type: change-spec
domain: software
status: implemented
created: 2026-02-25
updated: 2026-02-25
---

# Change Spec: Skill-Level Model Routing

**Scope:** Lightweight amendment to skill authoring conventions and CLAUDE.md. No new project required.

**Motivation:** Crumb currently runs all skill invocations at the session's model tier (typically Opus). Many skills — particularly sync, checkpoint, obsidian-cli, and diagram skills — are procedural execution work that doesn't benefit from Opus-level reasoning. A 7-file inbox processing run took 9+ minutes of Opus thinking time on work that is entirely mechanical: sentinel regex, YAML templating, file moves. Routing these to Sonnet via Task tool subagent delegation reduces cost and latency with no quality loss, since vault-check provides mechanical verification of outputs.

**Non-goals:** This does not change subagent model routing (§3.2.1), which already has its own `model` field. This also does not introduce dynamic per-invocation model selection — Crumb doesn't assess task complexity at runtime to pick a model. The routing is declared statically in the skill definition.

---

## Changes

### 1. New optional field in skill YAML frontmatter

Add `model_tier` to the skill frontmatter schema.

```yaml
---
name: sync
description: >
  Sync vault state with external systems...
model_tier: execution
---
```

**Values:**

| Value | Meaning | Maps to |
|---|---|---|
| `reasoning` | High-judgment work: analysis, specification, design, evaluation | Opus (or session default) |
| `execution` | Procedural work: file processing, templating, mechanical validation, utilities | Sonnet |

**Default behavior:** If `model_tier` is omitted, the skill inherits the session model (current behavior, backward compatible). This means existing skills work unchanged until explicitly annotated.

**Model resolution:** `model_tier` maps to concrete model strings via a single config line in CLAUDE.md. This keeps skill definitions model-agnostic — they declare *what kind of work* they do, not *which specific model* to use.

### 2. Delegation mechanism

The runtime mechanism is the Task tool's `model` parameter. When Opus loads a skill with `model_tier: execution`, it delegates the skill's procedure to a Sonnet subagent via the Task tool (`model: "sonnet"`). Opus handles: reading the skill, preparing the dispatch prompt with all required context, spawning the subagent, and reviewing results. Sonnet handles: executing the procedure.

This is concrete and works today — no future Claude Code capabilities required.

### 3. Phased rollout by context complexity

Not all execution-tier skills are equally safe to delegate. Skills are grouped by the complexity of their dispatch handoff:

**Phase 1 (immediate) — Zero-context mechanical skills:**
sync, checkpoint, startup, obsidian-cli, meme-creator. No prompting phase, no user decisions to carry. Dispatch prompt is trivial.

**Phase 2 (immediate) — Structured-input skills:**
mermaid, excalidraw, lucidchart. Input is a specification, not a conversation. Dispatch is a structured payload.

**Phase 3 (deferred) — Interactive skills with prompting phases:**
inbox-processor. The prompting phase (scan, classify, present batch table, resolve dedup, confirm routing) generates user decisions that live in conversation context. Delegation requires a dispatch manifest design to preserve those decisions across the handoff. Deferred until phases 1-2 prove out the pattern and provide real data on dispatch overhead.

### 4. Tier assignments for existing skills

| Skill | Tier | Rollout phase | Rationale |
|---|---|---|---|
| sync | `execution` | Phase 1 | Mechanical: git operations, file sync, no judgment. |
| checkpoint | `execution` | Phase 1 | Mechanical: context checkpoint procedure, file writes. |
| startup | `execution` | Phase 1 | Mechanical: vault-check, CLI probe, staleness scan. |
| obsidian-cli | `execution` | Phase 1 | Utility: CLI command execution, result formatting. |
| meme-creator | `execution` | Phase 1 | Procedural: API calls, image generation, file writes. |
| mermaid | `execution` | Phase 2 | Procedural: diagram syntax generation from spec. |
| excalidraw | `execution` | Phase 2 | Procedural: diagram JSON construction from spec. |
| lucidchart | `execution` | Phase 2 | Procedural: diagram generation, API interaction. |
| inbox-processor | *(unset)* | Phase 3 | Deferred: interactive prompting phase needs dispatch manifest design. |
| audit | `reasoning` | N/A | Judgment: evaluating document quality, staleness significance, recommending actions. |
| systems-analyst | `reasoning` | N/A | Core analysis: problem decomposition, specification authoring. |
| action-architect | `reasoning` | N/A | Design work: task decomposition, dependency analysis, risk assessment. |
| writing-coach | `reasoning` | N/A | Judgment: prose quality evaluation, voice preservation, structural editing. |
| peer-review | `reasoning` | N/A | Evaluation: cross-model review synthesis, quality assessment. |
| code-review | `reasoning` | N/A | Judgment: code quality, architectural assessment, security review. |

### 5. CLAUDE.md Model Routing section

Added after Subagent Configuration:

```markdown
## Model Routing
Skill `model_tier` maps to concrete models:
- `reasoning` → session default (Opus)
- `execution` → Sonnet (`claude-sonnet-4-6`)

When loading a skill with `model_tier: execution`, delegate the skill's procedure
to a Sonnet subagent via the Task tool (`model: "sonnet"`). Pass the skill procedure,
relevant file paths, and any required context as the subagent prompt. Review subagent
output before finalizing.

Skills without `model_tier` inherit the session model (backward compatible).

Precedence: subagent explicit `model` field > skill `model_tier` > session default.
```

### 6. Skill authoring conventions update

Added `model_tier` to the optional routing fields table and a brief note to the YAML Frontmatter section in `_system/docs/skill-authoring-conventions.md`.

---

## Implementation

1. ~~Update `_system/docs/skill-authoring-conventions.md`~~ — done
2. ~~Update CLAUDE.md — add Model Routing section~~ — done
3. ~~Add `model_tier` frontmatter to 14 existing skills per tier assignments~~ — done
4. inbox-processor left without `model_tier` — Phase 3 deferred
5. No vault-check changes needed — `model_tier` is optional and doesn't affect structural validation

---

## Risks and Mitigations

**Risk: Sonnet drops a step in a complex procedure.**
Mitigation: vault-check runs as pre-commit hook and catches schema violations, missing frontmatter fields, broken companion notes. Opus reviews subagent output before finalizing. Two verification layers.

**Risk: Model string goes stale when new models ship.**
Mitigation: Concrete model strings live in exactly one place (CLAUDE.md Model Routing section). Updating the mapping is a single-line change.

**Risk: Dispatch overhead eats into time savings.**
Mitigation: Phased rollout. Phase 1 skills have trivial dispatch (no context to package). Phase 2 skills have structured input (specification-shaped, not conversation-shaped). Real data from these phases informs whether Phase 3 is worth the dispatch complexity.

**Risk: Subagent loses conversation context needed for execution.**
Mitigation: Only applies to Phase 3 (interactive skills). Phases 1-2 are self-contained — they don't depend on conversation state. Phase 3 is explicitly deferred until a dispatch manifest pattern is designed.

---

## Resolved Questions

1. **Advisory vs enforced:** Operational via Task tool delegation. Opus reads the `model_tier` field and acts on it by spawning a Sonnet subagent. Not enforced by Claude Code infrastructure — enforced by the CLAUDE.md routing instruction.

2. **Subagent `model` field precedence:** Subagent explicit `model` field > skill `model_tier` > session default. Restated in CLAUDE.md.
