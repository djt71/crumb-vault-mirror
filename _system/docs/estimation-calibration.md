---
type: reference
domain: software
status: active
created: 2026-03-16
updated: 2026-06-10
tags:
  - system
  - estimation
---

# Estimation Calibration

Tracks estimate accuracy (planned vs actual) across projects to improve future estimation.
Maintained by action-architect skill (compound behavior).

## Data Points

| Project | Task Range | Estimated | Actual | Ratio | Notes |
|---------|-----------|-----------|--------|-------|-------|
| pydantic-ai-adoption | PAA-001–PAA-010 | 2–3 days | ~1 hour | 0.04x | Falsifiable checkpoint (PAA-006) triggered NO-GO on pydantic-evals. Pytest pivot eliminated YAML dataset + evaluator framework overhead. Bash→Python extraction was mechanical (no coupling issues). Estimate assumed pydantic-evals would pass checkpoint. |
| agentic-sunset | AS-010–AS-032 | 9 provisional tasks (spec) | 23 atomic tasks (TASK phase) | 2.6x | Spec-stage decomposition of a teardown undercounted: consumer sweeps, no-gap relabeling, operator-assisted steps (reboot/sudo), and verification waits (24h quiet, 7-day soak) each became standalone tasks once the live inventory existed. Pattern: infra teardown ≈ 2–3 tasks per "scrap N things" spec line. Actual duration TBD at close. |
| vault-optimization | VO-010–VO-036 | 9 spec tasks (VO-001–009) | 27 atomic tasks (TASK phase) | 3.0x | Decomposed *with* the agentic-sunset teardown pattern applied up front (2–3 atomic per spec line) — ratio landed inside the predicted band, so the pattern held predictively, not just retrospectively. Drivers: 4 type-scoped evidence passes, changeset/execution split (spec tension resolution), 7 batch-execution tasks. Actual at close TBD. |
| akm-refresh | AKM-001–010 | 10 tasks (spec+plan, 2026-07-07) | TBD at close | — | Registered at PLAN. Tasks cut finer than AS/VO spec lines (acceptance criteria attached at SPECIFY, peer-reviewed) — predicted expansion mild (~1.5x, intra-task splits in AKM-003/006/008), not the 2.6–3.0x infra band. Two checkpoint gates (M6 viability, A4 payload contingency) could compress instead. Test of whether finer spec cutting beats the expansion pattern. |

## Patterns

- **Checkpoint-triggered pivots compress timelines.** When a go/no-go gate fires early, downstream work evaporates. Estimates that assume the "go" path overestimate when the gate says "no-go."
- **Extraction difficulty drives variance.** The pydantic-ai-adoption estimate hinged on AO logic coupling. Actual coupling was low → extraction was fast. Future estimates should assess coupling before sizing.
