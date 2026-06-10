---
type: action-plan
project: vault-optimization
domain: software
skill_origin: action-architect
status: active
created: 2026-06-10
updated: 2026-06-10
source: specification.md
source_updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - action-plan
---

# vault-optimization — Action Plan

Decomposition of spec tasks VO-001–009 (9 lines) into 27 atomic tasks
(VO-010–036), per the approved optimization design (D1–D6). Atomic IDs start at
VO-010 to avoid collision with spec group IDs (agentic-sunset precedent); each
task description carries its spec group in brackets.

**Calibration note:** agentic-sunset decomposed 9 spec tasks → 23 atomic (2.6x);
this plan is 3.0x — consistent with the captured teardown pattern (~2–3 atomic
tasks per "scrap N things" spec line).

**Spec-tension resolution (encoded throughout):** the spec has VO-005/006/007
"executing" prunes while VO-008 owns batched deletion. Resolution per design D4:
M3 tasks produce *changesets* (definitions, remediation maps, rewrite drafts);
**all** deletions and edits execute under M4's batch discipline (B0 gate first).
Spec ACs for VO-005/006/007 are verified at their corresponding batch
checkpoints (B3–B6).

**Inventory baseline (regenerated 2026-06-10 at TASK start, per D1):** 2,511 md
files · 20 skills · 4 agents · 8 overlays · 20 scripts · 6 protocols · 25
solution docs · 12 project dirs · 10 live plists · Archived/ 147M, Projects/
42M, Sources/ 12M, _system/ 5.1M, _attachments/ 4.7M, Domains/ 560K.

## M1 — Decision Baseline

### Phase: ADR acceptance (VO-010)

Accept the v3 identity ADR — the single decision governing every downstream
disposition. Operator session; decision gate proceed/re-plan.

**Success criteria:** ADR `status: accepted`, all acceptance boxes checked, 4
open questions answered, gate outcome logged. **Dependencies:** none. May run
during AS M3–M5.

## M2 — Analysis Corpus (read-only; parallel with AS M3–M5)

### Phase: Keep-set manifest (VO-011–017)

Manifest skeleton from the regenerated baseline, then four type-scoped evidence
passes (skills+agents, scripts+plists, overlays+protocols, docs+projects) under
the five-category rubric, the Appendix A ownership matrix freeze with AS
concurrence, and the mandatory operator review of every no-evidence deletion.

### Phase: Operating note draft (VO-018)

First half of the deliverable-#2 split (PLAN gate decision): draft once identity
and keep-set are known; finalized at VO-036.

### Phase: Consumer graphs + storage policy (VO-019–022)

Nine-surface consumer-graph survey (split vault-internal / system surfaces),
Archived/ enumeration with canonical-exception extraction list, and the storage
policy doc carrying the three-outcome distinction and the explicit
git-history-rewrite decision.

**Success criteria:** manifest covers 100% of baseline with zero "unknown" rows;
every delete row has a recorded-command consumer list; Appendix A frozen with AS
concurrence; storage policy written; operating-note draft exists.
**Dependencies:** VO-010.

## M3 — Changesets (definition only; no mutations)

### Phase: Primitive + docs changesets (VO-023–024)

B4/B5 changeset (prune lists, per-item remediation maps, trigger-condition
description rewrites for every kept skill, gotchas only where a failure is on
record) and B3 changeset (docs cluster map, delete-unless-canonical
dispositions, A11 taxonomy cleanup).

### Phase: Ceremony classification + changeset (VO-025–026)

Every step of the four ceremonies (phase gates, context-checkpoint, session-end,
intake) classified load-bearing / zombie / mergeable with a named
consumer/enforcer. **A10 metrics defined here (no longer deferred):**
per-ceremony mandatory-step counts before/after, zombie count must reach 0,
every kept step must name its consumer — reported as a checklist diff so no
phase-gate semantics are silently lost. Then the B6 changeset (protocol
rewrites + CLAUDE.md second-pass diff *proposal*; application is stop-and-ask
and post-AS-025).

**Success criteria:** every batch B3–B6 has an approved changeset; ceremony
metrics recorded. **Dependencies:** M2 complete (VO-026 additionally on AS-025).

## M4 — Execution (VO-008 batch model; every batch gated on B0)

### Phase: Backup gate (VO-027 / B0)

Git remote is the authoritative restore source (PLAN gate decision);
restore-drill on a throwaway clone before any deletion. Hard gate.

### Phase: Weight batches (VO-028–029 / B1–B2)

Archived/ exception-extraction + deletion (147M), then _attachments orphans,
non-md heavyweights, and dead logs (producer-alive check).

### Phase: Surface batches (VO-030–033 / B3–B6)

Docs consolidation, then scripts/protocols/overlays, then skills/agents +
description rewrites, then ceremony edits. B4/B5 (VO-031/032) are **blocked
until Appendix A is frozen and AS M6 sign-off exists in the AS run-log
(XD-027)**; B6 (VO-033) additionally requires AS-025 complete and stop-and-ask
per CLAUDE.md edit.

Each batch: remediate consumers → delete/edit → vault-check green → atomic
commit. Partial-pass rule: finish or revert the batch before stopping. Abort =
revert + re-survey. Every high-risk batch starts with an explicit operator go
(risk-tiered approval).

**Success criteria:** all batches committed green; deletions enumerated in
run-log; clean tree. **Dependencies:** M3 complete + per-batch gates above.

## M5 — Validation & Close

### Phase: Soak + validation (VO-034–035)

Soak window (defined per A10, instantiated at VO-034): **14 calendar days AND
≥8 working sessions from the B6 commit, whichever is satisfied later** — an
explicit end-condition per teardown-discipline #1. Pass criteria: zero urgent
git restores; no repeated workaround (the same removed primitive needed twice =
fail); all six Tier-1 representative workflows (design D6) pass at least once.

### Phase: Close-out (VO-036)

Validation record written, operating note finalized against soak reality,
operator sign-off. Project complete when all six spec end-state deliverables
exist.

**Success criteria:** soak end-condition met with pass criteria green; operator
sign-off in run-log. **Dependencies:** M4 complete.

## Risk & Gate Summary

- High-risk (stop-and-ask before starting): VO-027, VO-028, VO-031, VO-032.
- Cross-project gates: VO-031/032 ← Appendix A frozen + AS M6 (XD-027);
  VO-026/033 ← AS-025.
- Interruptibility (liberation directive): every M4 batch is an atomic commit
  checkpoint; the project yields to revenue prompts at any checkpoint with no
  half-applied state.
- Footprint note: tasks are scoped to ≤5 *edited* files; bulk-deletion batches
  (B1–B5) are measured by remediation-edit count per commit, not deleted-file
  count — deletions are enumerated in the run-log instead.
