---
type: reference
domain: software
status: active
created: 2026-03-16
updated: 2026-03-16
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

## Patterns

- **Checkpoint-triggered pivots compress timelines.** When a go/no-go gate fires early, downstream work evaporates. Estimates that assume the "go" path overestimate when the gate says "no-go."
- **Extraction difficulty drives variance.** The pydantic-ai-adoption estimate hinged on AO logic coupling. Actual coupling was low → extraction was fast. Future estimates should assess coupling before sizing.
