---
type: action-plan-summary
project: documentation-overhaul
domain: software
status: active
created: 2026-03-14
updated: 2026-03-14
source_updated: 2026-03-14
skill_origin: action-architect
tags:
  - system/docs
  - system/architecture
topics:
  - moc-crumb-architecture
---

# Documentation Overhaul — Action Plan Summary

35 tasks across 4 milestones, ~13-14 sessions.

## M1: Infrastructure Prerequisites (0.5 session)
2 tasks. Update tag taxonomy and create directory structure. Blocker for all downstream work.

## M2: Architecture Foundation (5 sessions)
10 tasks. Five architecture docs + overview, plus 3 absorb-and-redirect consolidations. Medium risk — these docs become the authoritative current-state source. Sequential: 01 → 02 → 04 → 03 → 05 → 00.

## M3: Operator Documentation (7-8 sessions)
20 tasks. Migration batch first (6 files moved/retagged + runbook expansion), then 4 AI-drafted batches by priority: core reference → subsystem operations → onboarding/explanation → remaining. Low risk (medium for runbook expansion). Includes 2 absorb-and-redirect consolidations. Migration (DOH-013) may run in parallel with M2.

## M4: LLM Orientation Map (1 session)
2 tasks. Build tracking map + gap analysis. Can run in parallel with M3 after M2 completes. Low risk.

## Key Dependencies
- M1 must complete before M2 (vault-check blocker)
- M2 must complete before M3 drafting and M4 (architecture is source material)
- M3.1 migration (DOH-013) is the sole exception — may run after M1, parallel with M2
- M3.1 (migration) must precede M3.2-M3.5 (drafting)
- M2 absorb tasks chained into dependency sequence (draft → absorb → next draft)
- M3 and M4 can run in parallel after M2

## Risk Profile
- 2 tasks medium risk (architecture doc drafting — factual accuracy compounds downstream)
- 1 task medium risk (runbook expansion — operational accuracy)
- 32 tasks low risk
- Primary quality gate: Danny's pass/fail review per doc
