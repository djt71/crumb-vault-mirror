---
type: action-plan-summary
project: akm-refresh
domain: software
status: active
skill_origin: action-architect
created: 2026-07-07
updated: 2026-07-07
summary_of: action-plan.md
source_updated: 2026-07-07
topics:
  - moc-crumb-architecture
tags:
  - action-plan
  - summary
  - akm
---

# akm-refresh — Action Plan Summary

**Shape:** 10 tasks (AKM-001…010), 4 milestones. Spine: M1 decision → M2 rebuild → M4 closure, with M3 (hook primitives) threading through — designs parallel to M1/M2, implementations after AKM-003. The 2-week soak window doubles as working time for M3/M4.

**Milestones:**
- **M1 — Transport & Mode Decision:** AKM-001 spike (staged, Stage-0 bail: confirm daemon exists on installed qmd via local `--help` before spending the budget) → AKM-002 design with operator approval. M6 rule: nothing passes M1–M5 → halt at design exception, operator decides.
- **M2 — Precision Trigger Rebuild:** AKM-003 wrapper implementation → AKM-004 fixture v2 + soak start. Code review at boundary.
- **M3 — Feedback-Loop Primitives:** AKM-005/007 designs (parallel; shared A4/U3 payload validation runs once; each ends at a Primitive Creation Protocol gate) → AKM-006/008 implementations. A4 contingency: clean descope by amendment. Code review at boundary.
- **M4 — Vocabulary & Closure:** AKM-009 query_hints (post-mode-decision) → AKM-010 soak execution + verdict = DONE gate input.

**Operator gates:** AKM-002 design approval (or M6 exception), AKM-005 and AKM-007 primitive approvals, AKM-010 soak verdict.

**Calibration expectation:** infra projects ran 2.6–3.0x spec→TASK expansion; these tasks are cut finer, so expect intra-task splits (AKM-003, 006, 008) rather than new workstreams. M6/A4 gates firing = compression, not failure.

**Out of plan:** R6, chronic-miss re-enable, decay retuning, chapter digests (await R3 data); A10 DeepSeek timeout (operator item).
