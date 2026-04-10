---
type: summary
domain: software
project: researcher-skill
skill_origin: action-architect
created: 2026-02-27
updated: 2026-02-27
source_updated: 2026-02-27
---

# Researcher Skill — Action Plan Summary

## Core Content

18 tasks across 7 milestones (6 active + 1 deferred). The plan decomposes the researcher specification into an incremental build sequence where each milestone produces a testable integration checkpoint.

**Milestone 1 (Skill Definition + Data Infrastructure):** SKILL.md + fact ledger/handoff I/O. Foundation that everything else depends on. 2 tasks, low risk.

**Milestone 2 (Input Stages + Vault Input):** Scoping + vault knowledge query + Planning stages. Brief validation → vault-aware scoping → sub-question decomposition → convergence criteria. 3 tasks, medium risk. RS-012 integrated here so M3 benefits from vault-aware scoping. RS-003 explicitly depends on RS-012.

**Milestone 3a (Research Loop + Failure Handling):** Research Loop + failure mode handling. Web search, source scoring, ledger population, graceful degradation for bad sources. 2 tasks, medium-high risk (first live validation of source quality). RS-009 moved here from Evidence Verification — the Research Loop encounters failures during live testing and needs a handler.

**Milestone 3b (Convergence + Loop Control + Escalation):** Convergence scoring + runaway loop detection + escalation gates. The intelligence layer on top of a working Research Loop. 3 tasks, medium risk. First end-to-end: Scoping → ... → converged ledger with escalation.

**Milestone 4 (Evidence Integrity):** Citation Verification + writing validation rules. Two parallel tracks (no dependency between them): RS-007 verifies quotes against stored content, RS-008 defines [^FL-NNN] citation format and 4 mechanical validation checks. RS-008 depends on RS-005 (ledger schema), not RS-007 (verification). 2 tasks, medium risk.

**Milestone 5 (Output Pipeline + Vault Output):** Synthesis + Writing + vault output + telemetry. Cross-reference evidence, produce cited deliverable with Writing Validation, route to vault, capture dispatch metrics. First full end-to-end pipeline run. 3 tasks, medium risk.

**Milestone 6 (MCP Source Tools):** Deferred until 5+ dispatches with >20% ToolLimited sources. 3 tasks.

## Key Decisions

- **Critical path:** RS-001 → RS-002 → RS-012 → RS-003 → RS-004 → RS-006 → RS-010 → RS-013 → RS-014 → RS-015 (10 tasks through stage chain). RS-005 parallel, merges at RS-004. RS-007 ∥ RS-008 parallel in M4, merge at RS-014.
- **M3 split for debuggability:** M3a (Research Loop + failure handling) establishes "search works" before M3b (convergence + escalation) adds intelligence. This was the strongest consensus finding from peer review (4/4 reviewers).
- **RS-008 unblocked from RS-007:** Writing validation rules depend on ledger schema (RS-005), not verified data (RS-007). RS-007 and RS-008 run as parallel tracks in M4.
- **Runner vs model boundary:** Runner handles deterministic computations (content_hash, byte measurement, 8KB overflow). Model handles judgment (classification, extraction, convergence assessment).
- **Partial telemetry on early termination:** RS-009 and RS-011 write telemetry snapshots for dispatches that fail/escalate before reaching the output pipeline (prevents survivor bias in metrics).
- **Live iteration budget:** Per automation patterns doc, budget 3-6 iterations for each milestone's first live test.
- **Observability as cross-cutting concern:** Every stage task includes handoff snapshot, research status file writes, and inter-stage schema validation.

## Interfaces / Dependencies

- **Upstream:** CTB-016 dispatch protocol (complete), WebSearch/WebFetch (available), vault file conventions (stable).
- **Between milestones:** M1 → M2 → M3a → M3b → M5 is the main dependency chain. M4 branches from M3a and merges at M5.
- **Parallel work:** After RS-001, three tracks can run in parallel: data layer (RS-005), stage pipeline (RS-002 → RS-012 → RS-003), and escalation (RS-011).

## Next Actions

- Peer review complete (4/4 reviewers, round 1). 3 must-fix items applied (M3 split, RS-008 dependency, acceptance criteria). 6 should-fix items applied.
- Ready to advance to TASK phase. First implementation target: Milestone 1 (RS-001, RS-005).
