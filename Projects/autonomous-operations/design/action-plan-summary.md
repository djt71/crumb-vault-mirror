---
type: action-plan-summary
status: active
created: 2026-03-12
updated: 2026-03-12
skill_origin: action-architect
domain: software
project: autonomous-operations
source_updated: 2026-03-12
---

# Autonomous Operations — Phase 1 Action Plan Summary

## Milestones

| Milestone | Tasks | Goal | Est. Duration |
|-----------|-------|------|---------------|
| M1: Foundation | AO-001, AO-002 (parallel) | SQLite replay log + structured attention items with action_class + domain | ~1 week |
| M2: Deduplication | AO-003 | Path-based identity, dedup pre/post processing | ~2-3 sessions |
| M3: Instrumentation | AO-004, AO-005 | Vault-change correlation + proxy scoring metrics | ~1 week |
| M4: Evaluation | (gate, not task) | 14-day production operation against exit criteria | 14 days |

## Critical Path

AO-001 + AO-002 (parallel) → integration step → AO-003 (dedup) → AO-004 (correlation) → AO-005 (scoring) → 14-day evaluation.

The M1 integration step (logging parsed items to SQLite) is a hard prerequisite for AO-003.

## Key Decisions (post-peer-review)

- **Structured extraction:** Single delimited JSON block at end of response (fenced ```json). jq validation + quarantine on parse failure.
- **Object identity:** Vault-relative normalized source_path as object_id. UNIQUE(cycle_id, object_id). Alias table for renames.
- **Correlation signals:** git log (primary) + filesystem mtime (secondary). Items without source_path logged as "uncorrelated." Invoked from daily-attention.sh; standalone script for manual reruns.
- **Metrics:** "False-positive rate" redefined as "acted-on rate" — Phase 1 can't distinguish irrelevant items from deferred action. True FP labeling deferred to Phase 2. Score output prints N_window_closed for sample size transparency.
- **Domain field:** 9 canonical values per item (software, career, learning, health, financial, relationships, creative, spiritual, lifestyle). Drives 48h/7d correlation windows.
- **action_class taxonomy:** do, decide, plan, track, review, wait. Fallback to "review" on unrecognized values.
- **Operational guardrails:** PRAGMA user_version for schema versioning, <30s correlation / <10s scoring runtime thresholds, JSON output for monthly review.

## Key Risk

AO-002 prompt engineering for structured output from direct API (no tool access). Mitigation: fenced JSON block extraction via sed+jq, quarantine on failure, 5+ live test runs before declaring stable. Token budget parameterized with runtime guard.

## Total Timeline

~2 weeks implementation + 14 days evaluation = ~4-5 weeks to Phase 1 exit gate.
