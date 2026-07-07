---
type: solution
domain: software
status: active
track: pattern
created: 2026-07-07
updated: 2026-07-07
skill_origin: compound
confidence: medium
linkage: discovery-only
durability: durable
valid_as_of: 2026-07-07
tags:
  - solution
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Deliberation Panel Pattern

Design preserved from the retired **deliberation** skill (retired 2026-07-07, skills-library review §C-4; full machinery in git history: `.claude/skills/deliberation/SKILL.md` + `.claude/agents/deliberation-dispatch.md`, deleted in the same commit as this doc's creation). Confidence is **medium**: the design executed successfully across 36 recorded runs, but nearly all were H1–H4 hypothesis-testing artifacts for the multi-agent-deliberation project — operational validation outside the experiment was minimal.

## Problem

Single-model review gives one perspective; naive multi-model review gives N unanchored opinions. When evaluating a *decision or opportunity* (not an artifact's correctness), you want genuinely diverse evaluative stances, a way to surface and resolve dissent, and operator ratings untainted by knowing which model said what.

## The Pattern

1. **Role overlays + persona bias per evaluator.** Each external evaluator gets a unique prompt assembled from: a role overlay (evaluative lens), a companion context doc, an explicit `persona_bias` declaration, and a shared structured assessment schema. Diversity is *designed in*, not hoped for.
2. **Concurrent dispatch with random stagger.** Workers sleep `random.uniform(0, 2)`s before their first API call — avoids synchronized rate-limit collisions when hitting multiple providers at once.
3. **Version tracking + config hash.** Each record stores evaluator/model versions and the first 8 chars of the sha256 of the panel config — results stay interpretable after config changes.
4. **Two-pass dissent protocol.** On split verdicts, a second pass shares *structured fields only* (verdicts + key reasons, not full prose) across the panel boundary — evaluators reconsider against the dissent without anchoring on another model's rhetoric.
5. **Blinded rating capture.** The operator rates assessments before evaluator identities are revealed — calibrates which models/roles actually earn trust, free of brand bias.
6. **Batch mode + synthesis.** A batch manifest tracks a multi-artifact run; a synthesis step aggregates records into cross-artifact findings.

## Where the Parts Live

- Panel config / evaluator registry: `_system/docs/deliberation-config.md` (retained)
- Assessment schema: `_system/schemas/deliberation/assessment-schema.yaml` (retained)
- Historical records (36): `_system/data/deliberations/` (retained)
- Skill + dispatch agent: git history only (retired 2026-07-07)

## When to Revive

A recurring operational need to evaluate decisions/opportunities with a panel — e.g., a revived opportunity pipeline. Revive as a **peer-review panel mode** (role overlays + verdict scales as a dispatch variant) rather than a standalone skill: the dispatch machinery was ~90% shared with peer-review-dispatch, and the review found three near-identical dispatch agents to be the cluster's largest maintenance cost. The genuinely novel pieces worth carrying over are items 1, 4, and 5 above.
