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
task description carries its spec group in brackets. **Per-task binary
acceptance criteria and dependency edges live in `tasks.md`** — this plan
carries milestone-level structure; tasks.md is the AC source of truth (embed
both artifacts in any future peer review of this plan).

**Calibration note:** agentic-sunset decomposed 9 spec tasks → 23 atomic (2.6x);
this plan is 3.0x — consistent with the captured teardown pattern (~2–3 atomic
tasks per "scrap N things" spec line). Source:
`_system/docs/estimation-calibration.md` (agentic-sunset + vault-optimization
rows).

**Deferred review items, dispositions:** A10 closed at VO-025/VO-034 (metrics
below); A11 folded into the B3 docs changeset (VO-024); A12 (vault-only vs
harness-memory coordination wording) folded into the Appendix A ownership
matrix at spec amendment time — the matrix carries harness memory as
analysis-only for VO (AS-029 owns remediation).

**Spec-tension resolution (encoded throughout):** the spec has VO-005/006/007
"executing" prunes while VO-008 owns batched deletion. Resolution per design D4:
M3 tasks produce *changesets* (definitions, remediation maps, rewrite drafts);
**all** deletions and edits execute under M4's batch discipline (B0 gate first).
Spec ACs for VO-005/006/007 are verified at their corresponding batch
checkpoints (B3–B6).

**Inventory baseline (regenerated 2026-06-10 at TASK start, per D1):** 2,511 md
files · 20 skills · 4 agents · 8 overlays · 20 scripts · 6 protocols · 25
solution docs · 12 project dirs · 10 live plists · Archived/ 147M, Projects/
42M, Sources/ 12M, _system/ 5.1M, _attachments/ 4.7M, Domains/ 560K. Evidence:
regeneration commands + output recorded in `progress/run-log.md` (2026-06-10
TASK entry); command set defined in design D1. Cross-project gate references
(XD-027, AS-025, AS M6) resolve via `_system/docs/cross-project-deps.md` and
the agentic-sunset run-log. "vault-check" throughout means
`_system/scripts/vault-check.sh` exiting 0 (CLEAN).

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

**Concurrency note:** all M2 tasks are read-only analysis and safe in parallel
with AS M3–M5; the one exception is VO-016 (Appendix A freeze), which requires
active AS concurrence and should be timed with an AS session boundary.

## M3 — Changesets (definition only; no mutations)

### Phase: Primitive + docs changesets (VO-023–024)

B4/B5 changesets (VO-023) and B3 changeset (VO-024). **Each batch gets its own
named changeset pack** — B3 docs pack, B4 scripts/protocols/overlays pack, B5
skills/agents pack, B6 ceremony pack — and each pack carries a disposition
list, a per-item remediation map, and its own approval record. Pack contents:
prune lists, trigger-condition description rewrites for every kept skill, and
gotchas only where a failure is on record ("on record" = a linked failure-log
or run-log entry).

**Spec-AC traceability (changeset/execution split):** VO-006 ACs close at the
B3 checkpoint (canonical-doc dispositions applied + zero dead wikilinks);
VO-005 ACs close across B4+B5 (prune counts + trigger-condition descriptions +
consumer remediation); VO-007 ACs close at B6 (protocol rewrites applied +
ceremony metric deltas recorded).

### Phase: Ceremony classification + changeset (VO-025–026)

Every step of the four ceremonies (phase gates, context-checkpoint, session-end,
intake) classified load-bearing / zombie / mergeable with a named
consumer/enforcer. **A10 metrics defined here (no longer deferred):**
per-ceremony mandatory-step counts before/after, zombie count must reach 0,
every kept step must name its consumer — reported as a checklist diff so no
phase-gate semantics are silently lost. Then the B6 changeset (protocol
rewrites + CLAUDE.md second-pass diff *proposal*; application is stop-and-ask
and post-AS-025). **VO-026 completes only when the CLAUDE.md diff proposal is
frozen and tagged `pending-AS-025-release`** — VO-033 may apply exactly that
frozen diff or must re-open VO-026.

**Success criteria:** every batch B3–B6 has an approved changeset pack;
ceremony metrics recorded; **M3-close drift diff run** — baseline regenerated
and diffed against the M2 snapshot, any new in-scope item dispositioned in the
manifest before M4 entry. **Dependencies:** M2 complete (VO-026 additionally on
AS-025).

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

**Batch cycle:** batch-open checks → remediate consumers → delete/edit →
vault-check green + functional fast-pass → atomic commit. Partial-pass rule:
finish or revert the batch before stopping. Abort = revert + re-survey. Every
high-risk batch starts with an explicit operator go (risk-tiered approval).

**Batch-open checks (every batch, A1/A2):**
1. *Changeset staleness check* — re-validate this batch's changeset pack and
   consumer lists against the current tree; if any referenced path changed
   since drafting (including mutations by earlier batches), refresh the pack
   before executing.
2. *Drift diff* — regenerate the in-scope inventory and diff against the last
   snapshot; any new/changed in-scope item gets a manifest row + disposition
   before the batch runs. Any manifest row whose evidence status changed after
   operator review goes back to the operator before execution.

**Cross-batch integrity rule (A1):** if a later batch (or any check) reveals
that an earlier committed batch deleted something a surviving consumer needs:
forward-fix commit restoring the artifact from git history + consumer-survey
update + re-run of the affected batch's verification. If the defect cannot be
fixed forward without altering already-committed batches: halt M4, restore
from git remote (the authoritative source per B0), and re-enter M3 with the
corrected survey.

**Sub-batch rule (A6):** a batch too large for one session splits into
numbered sub-batches before execution, each with its own full batch cycle
(open checks → remediate → delete → green → commit); the partial-pass rule
applies per sub-batch. VO-029 (B2) executes as three sub-batches by risk
profile: attachment orphans, non-md heavyweights, dead logs — each with its
own evidence standard (orphan check / size audit / producer-alive check).

**Functional fast-pass (A7):** after each batch's vault-check, run an
abbreviated spot-check of the Tier-1 workflows whose surfaces the batch
touched (e.g., B5 → skill-routing spot-check; B6 → one ceremony dry-run). The
full six-workflow validation stays at VO-035 — the fast-pass localizes
functional breakage to the commit that caused it.

**Risk-tier rationale:** VO-029 and VO-033 are medium (not stop-and-ask)
because both execute operator-approved artifacts with per-item evidence — the
storage policy (VO-022) and the frozen B6 changeset (VO-026) — and B6's
CLAUDE.md edits are individually stop-and-ask anyway.

**Success criteria:** all batches committed green with batch-open checks
logged; deletions enumerated in run-log; clean tree. **Dependencies:** M3
complete + per-batch gates above.

## M5 — Validation & Close

### Phase: Soak + validation (VO-034–035)

Soak window (defined per A10, instantiated at VO-034): **end of soak =
max(B6-commit + 14 calendar days, B6-commit + 8 working sessions)**, where a
*working session* is a day with at least one logged vault work session
(session-log or run-log entry). An explicit end-condition per
teardown-discipline #1. Pass criteria: zero urgent git restores; no repeated
workaround — the same removed primitive *needed* twice = fail, where "needed"
means restored, manually recreated, or worked around in a documented way that
compensates for its removal; all six Tier-1 representative workflows (design
D6) pass at least once.

**Soak failure protocol (A3):** a single primitive restore → fix-forward
(restore from git history, manifest row flipped to keep, run-log entry); a
repeated-workaround failure or a Tier-1 blocker → revert the offending batch
commit(s) and re-enter M3 with the corrected changeset. Either path restarts
the soak clock for the affected surface only; a second failure of any kind
restarts the full soak window.

### Phase: Close-out (VO-036)

Validation record written, operating note finalized against soak reality,
operator sign-off. Project complete when all six spec end-state deliverables
exist: (1) accepted v3 ADR, (2) core-functionality operating note with
future-addition rubric, (3) keep-set manifest incl. joint-surface contract,
(4) storage policy, (5) reduced primitive surface with trigger-condition
descriptions, (6) functional validation record.

**Success criteria:** soak end-condition met with pass criteria green; operator
sign-off in run-log. **Dependencies:** M4 complete.

## Risk & Gate Summary

- High-risk (stop-and-ask before starting): VO-027, VO-028, VO-031, VO-032.
- Cross-project gates: VO-031/032 ← Appendix A frozen + AS M6 (XD-027);
  VO-026/033 ← AS-025.
- Interruptibility (liberation directive): every M4 batch is an atomic commit
  checkpoint; the project yields to revenue prompts at any checkpoint with no
  half-applied state.
- Footprint note: tasks are scoped to ≤5 *authored/edited* files; bulk-deletion
  batches (B1–B5) are measured by remediation-edit count per commit, not
  deleted-file count — deletions are enumerated in the run-log instead.
  Analysis tasks that aggregate large findings into one canonical file
  (manifest, survey, policy) count that file once.

## Peer Review

Round-1 panel review 2026-06-10 (`reviews/2026-06-10-action-plan.md`): 4/4
reviewers, no CRITICAL findings; 2 must-fix (cross-batch integrity rule, drift
control) + 9 should-fix amendments applied same day — batch-open checks,
sub-batch rule, functional fast-pass, soak failure protocol, frozen-B6-pack
state, per-batch changeset packs, traceability map, citation pass, definitional
tightening. Grok calibration watch review 2: 0 fabrications (tally in
peer-review-config.md).
