---
type: specification-summary
project: vault-optimization
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: specification.md
source_updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - specification
  - summary
---

# vault-optimization — Specification Summary

Define the vault's core functionality by refreshing and **accepting the proposed Crumb v3 identity ADR** ("durable knowledge store + reasoning substrate, not an automation platform"), then optimize the vault down to that core across four operator-confirmed axes: primitive surface (20 skills / 4 agents / 8 overlays / 20 scripts / 6 protocols), docs & staleness, workflow ceremony, and storage weight (`Archived/` ≈70% of the 211 MB working tree).

**Key operator decisions (2026-06-10):** v3 ADR is the baseline; all four axes in scope; **aggressive deletion** — git history is the archive (history rewrite itself stays a separate, default-out decision). agentic-sunset retains M6/M7 vault surgery (AS-025–032); VO sequences behind it on shared surfaces via a **joint-surface contract** (ownership matrix, VO-002 Appendix A) — VO-005/007 gate on the matrix being frozen + AS M6 closure sign-off (XD-027).

**Tasks (9):** VO-001 accept ADR (with proceed/re-plan decision gate) → VO-002 keep-set manifest under a five-category evidence rubric (operator review mandatory for all no-evidence deletions) + ownership matrix → VO-003 mechanical consumer-graph survey + VO-004 storage policy (3-outcome distinction: working tree / navigation / repo size) → VO-005 primitive pruning / VO-006 docs consolidation (delete-unless-canonical rule) / VO-007 ceremony reduction → VO-008 batched execution (backup restore-drill first; atomic commit checkpoints; per-batch consumer remediation; abort/revert rules) → VO-009 functional validation + soak (Tier-1 workflows must pass to close).

**End state (completion contract):** accepted ADR · core-functionality operating note with future-addition decision rubric (canonical maintenance entrypoint) · keep-set manifest · storage policy · reduced primitive surface with trigger-condition descriptions · functional validation record.

**Evidence base:** SkillsBench (focused 2–3 skills beat exhaustive), Anthropic skill-design guidance (descriptions = trigger conditions), system health assessment (maintenance gravity), infrastructure-teardown-discipline (consumer-graph sweeps, end-conditions).

**Review:** round-1 peer review 2026-06-10 (GPT-5.4, Gemini 3.1 Pro, DeepSeek V4 Pro, Grok 4.3) — 4 must-fix + 5 should-fix amendments applied same day (`reviews/2026-06-10-specification.md`); re-review skipped by operator decision (amendments follow panel consensus).

**Workflow:** software, full four-phase. Highest-risk task: VO-008 execution (irreversible deletions — gated on restore-drill, batch checkpoints, consumer-graph completeness).
