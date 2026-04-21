---
type: specification-summary
status: active
created: 2026-03-12
updated: 2026-03-12
skill_origin: systems-analyst
domain: software
project: autonomous-operations
source_updated: 2026-03-12
review_rounds: 2
---

# Autonomous Operations — Phase 1 Specification Summary

## What

Extend the existing daily-attention.sh cron to produce structured, replay-logged attention items with action classification, deduplication, and a computable quality signal. Bash + direct API architecture stays — no migration.

## Why

The attention engine produces daily artifacts but can't measure whether it surfaces the right things. Without structured logging and proxy scoring, any future optimization is guesswork. Phase 1 instruments what exists so quality becomes measurable.

## Key Decisions

- **Architecture:** Bash pre/post processing around existing API call (~$0.19/run)
- **Object identity:** Path-based with alias table for renames (simplest; known limitation)
- **Replay storage:** SQLite (queryable, consistent with dashboard_actions pattern)
- **Action tracking:** Vault-change correlation via git diffs (zero-ceremony)
- **Review surface:** Daily artifact in Obsidian (validated by soak)

## Tasks (5)

| ID | Title | Risk | Depends On |
|----|-------|------|------------|
| AO-001 | Replay Log Schema + Infrastructure | low | — |
| AO-002 | Attention Item Schema + action_class | medium | — |
| AO-003 | Object Identity + Deduplication | medium | AO-002 |
| AO-004 | Vault-Change Correlation Engine | medium | AO-001, AO-002 |
| AO-005 | Proxy Scoring + Exit Criteria Evaluation | low | AO-004 |

AO-001 and AO-002 can proceed in parallel. Critical path: AO-001/AO-002 → integration step → AO-003 → AO-004 → AO-005.

## Exit Criteria

- **Context coverage ≥80%:** % of items with non-null `source_path`, valid `action_class`, and valid `domain` (7-day rolling)
- **Acted-on rate:** directional proxy for item relevance — % of window-closed correlated items classified as `acted_on`. No strict threshold for Phase 1; anomalous values (very low or very high) trigger manual spot-check. True false-positive measurement deferred to Phase 2 (requires operator dismiss action).
- **Replay completeness 100%:** % of calendar days with a logged cycle
- **Dedup accuracy:** zero same-`object_id` duplicates per cycle
- **Scoring coverage:** % of window-closed items with a correlation result

Minimum 14 days of full operation before exit evaluation. Note: items with 7-day correlation windows surfaced in the second half of the period won't have closed windows — effective sample for acted-on rate is ~7-10 days. `attention-score.sh` prints `N_window_closed` alongside all rates.

## Architectural Boundary

Crumb/Tess is the meta-layer (attention allocation, cross-domain knowledge, strategic brain). Future products get their own simple throughput loops. This spec builds meta-layer instrumentation only.

## Not In Scope

Task registry (Phase 2), safe-action execution (Phase 3), dispatch envelopes (Phase 4), sub-daily cycles, UUID migration, new review surfaces, explicit operator input for action tracking.
