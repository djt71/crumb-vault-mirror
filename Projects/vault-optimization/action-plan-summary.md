---
type: action-plan-summary
project: vault-optimization
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: action-plan.md
source_updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - action-plan
  - summary
---

# vault-optimization — Action Plan Summary

27 atomic tasks (VO-010–036) from 9 spec lines (3.0x — matches agentic-sunset
teardown calibration), in 5 milestones: **M1** ADR acceptance (VO-010, decision
gate). **M2** analysis corpus, read-only, parallel with AS M3–M5 — manifest
skeleton + 4 evidence passes + Appendix A freeze + mandatory operator review of
no-evidence deletes (VO-011–017), operating-note draft (VO-018), consumer-graph
surveys (VO-019–020), Archived/ enumeration + storage policy (VO-021–022).
**M3** changesets only, no mutations — B4/B5 primitives changeset (VO-023), B3
docs changeset (VO-024), ceremony classification with A10 metrics now defined
(step counts before/after, zombie→0, named consumer per kept step; VO-025), B6
changeset (VO-026, post-AS-025). **M4** execution under the batch model — B0
git-remote restore-drill gate (VO-027), then B1 Archived/ → B2 attachments/logs
→ B3 docs → B4 scripts/protocols/overlays → B5 skills/agents → B6 ceremony
(VO-028–033); each batch = remediate → delete → vault-check green → atomic
commit; VO-031/032 blocked on Appendix A frozen + AS M6 sign-off (XD-027).
**M5** soak (14 days AND ≥8 sessions from B6 commit) + 6 Tier-1 validation
workflows + close-out with operating-note finalize (VO-034–036).

**Key resolution:** M3 produces changesets; all mutations execute in M4 batches
— spec VO-005/006/007 ACs are verified at batch checkpoints B3–B6.

**High-risk (stop-and-ask):** VO-027, VO-028, VO-031, VO-032. Every M4 batch is
an interruptible commit checkpoint (liberation-directive compliance).
