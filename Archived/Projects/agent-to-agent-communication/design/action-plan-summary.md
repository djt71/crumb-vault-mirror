---
project: agent-to-agent-communication
type: action-plan-summary
domain: software
status: active
created: 2026-03-04
updated: 2026-03-20
source_updated: 2026-03-20
review_applied: 2026-03-04
tags:
  - tess
  - openclaw
  - agent-communication
  - architecture
---

# Agent-to-Agent Communication — Action Plan Summary

## Scope

32 tasks across 9 milestones. 21 detailed (Phase 1 + 1b), 11 sketched (Phase 2-4).

## Key Decisions

- **OQ1 resolved:** Discrete orchestration skills per workflow (not unified engine). Matches existing cron/script pattern.
- **D1 resolved:** Terminology glossary defined (correlation_id, dispatch_id, workflow, intent, capability_id). `dispatch_group_id` deferred to Phase 4 if multi-dispatch is warranted.
- **Code location:** Distributed — SOUL.md instructions, `_openclaw/state/` schemas, dispatch templates, SKILL.md frontmatter. No new code repo. Schema definitions at `_system/schemas/a2a/`. Pre-computed capabilities index at `_openclaw/state/capabilities.json`.
- **Live deployment budget:** 4-6 iterations for Workflow 1, 3-4 for Workflow 2 (per claude-print-automation-patterns.md Pattern 4).
- **SOUL.md code helper layer:** Deferred. M2 gate (A2A-005) evaluates whether deterministic operations drift. If yes → targeted bash helpers before M3. If no → proceed with prompt-only approach.
- **vault.query.facts:** New vault-query skill (A2A-007.5), not a manifest on obsidian-cli. Obsidian-cli is a utility, not a dispatch target.

## Milestones

| Milestone | Spec Tasks | Key Deliverable | Est. Sessions | Phase |
|-----------|-----------|-----------------|---------------|-------|
| M1: Foundation Infrastructure | A2A-001, 002, 003 | Delivery abstraction + context model + feedback infra | ~2-3 | 1 |
| M2: Compound Insight Workflow | A2A-004.1-3, 005 | End-to-end W1 + 3-day gate with A/B + SOUL.md drift eval | ~3-4 | 1 |
| M3: Capability Infrastructure | A2A-006, 006.5, 007, 007.5, 008, 009 | Manifest schema + validation + skill manifests + vault-query skill + resolution + quality gates | ~2-3 | 1b |
| M4: Research Pipeline | A2A-010-014 | End-to-end W2 + gate + critic skill | ~3-4 | 1b |
| M5: Mission Control Read | A2A-015.1-3 | **SUPERSEDED** by mission-control project | — | 2 |
| M6: SE Account Prep | A2A-016, 017.1-3, 018 | Dossier alignment + sequential dispatch W3 + gate | ~3-4 | 2 |
| M7: Approval Integration | A2A-019.1-2 | Approval delivery adapter + MC coordination contract | ~2 | 2 |
| M8: Operational Intelligence | A2A-020-024 | Gardening + retrospective + cost routing + stall detection | sketched | 3 |
| M9: Advanced Patterns | A2A-025 | Multi-dispatch CTB-016 amendment (conditional) | sketched | 4 |

## Critical Path

M1 → M2 build → (M3 schema work starts in parallel with M2 gate) → M2 gate → M3 resolution/gates → M4 (gate). M5/M6 can proceed after M2 gate + learning log schema defined.

M3 schema tasks (A2A-006/007/007.5) have zero logical dependency on W1 outcomes — they depend on M1 infrastructure being defined, not on W1 being evaluated. A2A-008/009 gated on M2 gate (benefits from W1 operational experience). Prioritize M3 over M5 if both unblocked.

Phase 2 unblocked: TOP-027 (calendar) DONE 2026-03-11, TOP-049 (approval contract) DONE 2026-03-16, customer-intelligence dossiers in ACT (3 live). M5 superseded by mission-control project. M6 → M7 is the Phase 2 critical path. M7 depends on M6 operational + mission-control Phase 3 for web UI.

## Task Splits

Spec tasks split for file-change scoping:
- **A2A-004** → A2A-004.1 (schema + template), A2A-004.2 (orchestration trigger), A2A-004.3 (integration + smoke test)
- **A2A-012** → A2A-012.1 (brief template + instructions), A2A-012.2 (end-to-end integration)
- **A2A-015** → A2A-015.1, A2A-015.2, A2A-015.3 — **all superseded** by mission-control
- **A2A-017** → A2A-017.1 (orchestration template + SOUL.md), A2A-017.2 (sequential dispatch), A2A-017.3 (synthesis + delivery)
- **A2A-019** → A2A-019.1 (approval delivery adapter), A2A-019.2 (MC coordination contract)

New tasks from review:
- **A2A-006.5** — Manifest validation script (dep for A2A-008)
- **A2A-007.5** — Vault-query skill declaring `vault.query.facts` capability

## Top Risks

1. Haiku insufficient for W1 judgment → A/B gate comparison mitigates
2. Live deployment iteration costs → budgeted explicitly (Pattern 4)
3. SOUL.md prompt drift / untestability → deferred code layer; M2 gate evaluates drift; validation fixtures at M3
4. Feedback cold-start → manifest cost_profile fallback; cold-start capabilities blocked from high-rigor auto-selection
5. Phase 2/3 external blockers → Phase 1/1b fully independent, no wasted work
