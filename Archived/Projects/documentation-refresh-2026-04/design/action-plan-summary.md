---
type: action-plan-summary
project: documentation-refresh-2026-04
domain: software
status: active
created: 2026-04-11
updated: 2026-04-11
source_updated: 2026-04-11
skill_origin: action-architect
tags:
  - system/docs
  - system/architecture
topics:
  - moc-crumb-architecture
---

# Documentation Refresh 2026-04 — Action Plan Summary

12 tasks across 5 milestones, ~5-6 sessions. Knowledge-work refresh — direct ACT execution, no intermediate TASK phase.

## M1: Staleness Survey Closeout (0 sessions)
1 task. Validate 4 spec unknowns via live state capture before substantive edits begin. Inline at start of first ACT session.

## M2: Architecture Refresh (3 sessions)
6 tasks. Sequential dependency chain: 01 → 02 → 04 → 03 → 05 → 00. Same order as the archived overhaul project. Building blocks (DOC-003) is the pivot — its inventory propagates into M3 and M4. Deployment (DOC-004), runtime views (DOC-005), and runbooks (DOC-009) are medium risk because they depend on verified live state.

## M3: Operator Refresh (2 sessions)
3 tasks (8 + 9 + 7 files in batches): reference, how-to, tutorials+explanation. Surgical edits. Runs after M2 completes. Can run in parallel with M4.

## M4: LLM Orientation Map Refresh (0.5 session)
1 task. Recount token budgets, drop removed skills, add new ones, verify arithmetic. Runs after M2 completes; parallel with M3.

## M5: Close-Out Consistency Check (0 sessions)
1 task. Cross-reference audit across architecture / operator / orientation map. Flags any design-spec drift for follow-on. Inline at end of last ACT session.

## Key Dependencies

- M1 → M2 (entry gate for substantive edits)
- M2 strict chain on architecture doc ordering
- M3 and M4 can run in parallel after M2
- M5 gates on M3 + M4

## Risk Profile

- 4 medium-risk tasks (DOC-003 inventory propagation, DOC-004 deployment reality, DOC-005 runtime views vs. tess-v2, DOC-009 runbook operational accuracy)
- 8 low-risk tasks
- No high-risk tasks

## Peer Review

LOW — documentation refresh within validated structure. Skipping.

## Scoping Notes

Tasks DOC-008, DOC-009, DOC-010 exceed the ≤5-file-change heuristic because they are surgical-edit batches within a single Diátaxis quadrant. Acceptable exception — any file proving to need substantive work splits into its own task mid-ACT.
