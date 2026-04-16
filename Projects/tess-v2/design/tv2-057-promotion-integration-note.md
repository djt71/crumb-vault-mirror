---
project: tess-v2
type: design-note
domain: software
status: draft
created: 2026-04-15
updated: 2026-04-15
task: TV2-057
phase: 4b
depends_on:
  - TV2-038
  - TV2-021b
source: staging-promotion-design.md §3.4, §5.2, §13; contract-schema.md; service-interfaces.md; src/tess/promotion.py; src/tess/cli.py; src/tess/contract.py; ~/.tess/state/run-history.db
tags:
  - promotion
  - state-machine
  - schema
  - amendment
---

# TV2-057 — Promotion Integration Design Note

> **Purpose.** Surface the decisions that must land before TV2-057 can be decomposed into implementable tasks. Reframes the original "wire `PromotionEngine.promote()` into `_cmd_run`" framing against the empirical state of contracts, services, and the 6465 staged run-history rows.
>
> **Status.** Draft for review. No code changes, no schema edits, no tasks.md entries until this note is accepted.
>
> **Non-goal.** This note does not define the decomposition into sub-tasks. Decomposition follows §6 below only after §1–§5 are accepted — the data segmentation is load-bearing and may invert the ordering.

---

## 1. Service taxonomy: promoting vs. side-effect-only

`service-interfaces.md` describes 16 services in prose `**Outputs**` rows. Mechanically parsing those rows against the definition of "produces a canonical file in the vault that TV2's promotion engine would need to move from `_staging/` to its destination" yields three classes:

### 1.1 Classes

| Class | Definition | Services |
|---|---|---|
| **A. Promoting** | Writes a file to a canonical vault path (`Projects/…`, `Domains/…`, vault root, etc.) | `vault-health`, `daily-attention`, `connections-brainstorm`, `morning-briefing` (cancelled TV2-037; **confirmed 0 rows in `run_history` — contributes nothing to the 622 Class A total**) |
| **B. Mirror-writing (ambiguous)** | Writes to `_openclaw/` mirror paths, not canonical `Projects/` | `overnight-research` (`_openclaw/research/output/`), `fif-capture` (`_openclaw/inbox/` — but SQLite is primary) |
| **C. Side-effect only** | HTTP ping, Telegram/Discord delivery, SQLite mutations, file deletions, state-file updates outside the canonical-content graph | `health-ping`, `awareness-check`, `backup-status`, `vault-gc`, `fif-attention`, `fif-feedback`, `email-triage` (cancelled), `scout-daily-pipeline`, `scout-feedback-poller`, `scout-weekly-heartbeat` |

### 1.2 Segmented row counts from `~/.tess/state/run-history.db`

Query: `SELECT service, outcome, COUNT(*) FROM run_history GROUP BY service, outcome;` — 2026-04-15 19:28 UTC snapshot, 6580 total rows (6465 staged, 87 dead_letter, 28 escalated).

| Class | Services | Staged rows | % of staged |
|---|---|---|---|
| A. Promoting | vault-health (13), daily-attention (596), connections-brainstorm (13) | **622** | **9.6%** |
| B. Mirror-writing | overnight-research (11), fif-capture (13) | 24 | 0.4% |
| C. Side-effect only | awareness-check (642), backup-status (1177), email-triage (439), fif-attention (13), fif-feedback (1190), health-ping (1278), scout-daily-pipeline (10), scout-feedback (988), scout-weekly-heartbeat (13), vault-gc (13) | **5763** | **89.1%** |
| Test/dev | test (56) | 56 | 0.9% |

### 1.3 Load-bearing finding

**~90% of staged contracts are Class C side-effect-only. They have no canonical vault file to promote.** The original "promotion engine is never called" framing implies a wiring gap. The data says something stronger: the state machine conflates two contract classes that should have different terminal paths. Class C contracts should never have been "stuck in STAGED" because they never had anywhere to promote to — they should have terminated COMPLETED (no-op promotion) the moment the executor finished.

This reframes TV2-057 from "add promotion wiring" to **"split the state machine and wire promotion for the class that needs it."** The latter framing suggests the Class C semantic fix may be smaller, independently shippable, and unblocks the 6465-row cleanup before any Class A promotion code lands.

**This finding should drive decomposition ordering, not the other way around.** §6 is deliberately sketchy.

### 1.4 Consequence: the Class C fix is independently shippable

The §1.3 reframe has an operational consequence worth stating as its own finding, not as a parenthetical in §6:

**The Class C semantic fix can ship before any promotion code is written.** Adding `COMPLETED` to `TerminalOutcome`, classifying contracts by `canonical_outputs` emptiness, transitioning Class C STAGED → COMPLETED immediately, and backfilling 5763 historical side-effect rows — all of this touches `ralph.py`, `runner.py`, `cli.py`, and `run-history` only. No writes to canonical vault paths. No locks. No `PromotionEngine`. No schema registry. It's a state-machine refactor over behavior that has already executed.

Doing this first means:
- The 6465-row "stuck in STAGED" anomaly resolves for 89% of rows before the more dangerous Class A promotion path gets touched.
- Production observability for the new terminal semantics accumulates over a soak window on Class C first, where the worst failure mode is a wrongly-labeled row (recoverable by re-running the backfill script).
- When promotion code finally lands for Class A (TV2-057.D), the state machine's terminal semantics have already been validated against ~90% of run volume.

This changes the risk profile of TV2-057 from "full-session scope with irreversible canonical-vault writes" to **"two incremental landings with a natural observation window between them."** The original framing would have bundled them, maximizing blast radius on first deploy.

---

## 2. Schema location for canonical outputs

### 2.1 Options

| Option | Location | Pros | Cons |
|---|---|---|---|
| **A. Per-contract** | `canonical_outputs: [{staging_name, destination}, …]` on each contract YAML | Self-contained; validatable at contract-load; no lookup layer | Duplicates info that's properly per-service (every vault-health contract writes to the same path) |
| **B. Per-service registry** | `canonical_outputs:` on each service definition (e.g., a Python module or YAML file keyed by `contract.service`) | Single source of truth per service; schema changes don't require rewriting all contracts | Indirection layer; runtime lookup; requires a new registry primitive |
| **C. Hybrid (recommended)** | `canonical_outputs:` on each service block in `service-interfaces.md` as a structured field next to `staging_path`; contracts inherit via their `service` field | Single source of truth; no new registry primitive (extends existing doc); forces TV2-021b to finalize its deferred open question | Inheritance mechanics have sub-choices (§2.2); requires service-interfaces.md schema tightening |

### 2.2 Open sub-question on inheritance mechanics (not resolved in this note)

If we pick Option C, the inheritance has two implementation shapes:

- **C1. Runtime resolution at contract-load time.** Contract YAML stays minimal (no `canonical_outputs:` field). `load_contract()` reads `service-interfaces.md` (or a derived JSON) and injects the destinations into the Contract object. Mid-flight service-interface changes propagate to the next contract load.
- **C2. Generation-time bake-in.** When a contract YAML is created or updated, a tool reads `service-interfaces.md` and writes the destinations into the contract YAML. Contract becomes self-contained; service-interface changes require regenerating all affected contracts.

Both are defensible and have different failure modes for "service-interface changed while a contract is in-flight." C1 picks up the new mapping mid-life (risk: promotion targets change between STAGED and PROMOTION_PENDING); C2 pins the mapping at generation (risk: stale destinations if a service moves canonical files).

**This sub-question is explicitly deferred to decomposition.** The note flags it; it does not pick.

### 2.3 Default recommendation

**Option C with sub-question C1-vs-C2 left open.** Resolves Open Question #1 in `staging-promotion-design.md` §13 ("Service interfaces must define the mapping from staging artifacts to canonical paths. This design assumes that mapping exists but does not define it.") which TV2-021b shipped without closing.

---

## 3. Router-vs-direct dispatch — explicit Amendment

### 3.1 The drift

`staging-promotion-design.md` §3.4 states: *"Lock acquisition occurs at ROUTING time, before dispatch. The orchestrator extracts the contract's target canonical paths from the contract definition and attempts to lock all of them."*

There is no orchestrator in the production path. LaunchAgent plists invoke `tess run <contract.yaml>` directly, bypassing any routing layer. The `_cmd_dispatch` CLI subcommand exists but is not on the service execution hot path.

### 3.2 The Amendment (proposed)

Amend `staging-promotion-design.md` §3.4 with an explicit section:

> **§3.4.2 Dispatch modes.** Tess v2 supports two dispatch modes:
>
> - **Routed dispatch** (original design): An orchestrator process acquires write-locks, then dispatches the contract to an executor. Lock acquisition transaction sits in the router.
> - **Direct dispatch** (current production mode): `tess run <contract.yaml>` is invoked directly by a LaunchAgent. Lock acquisition transaction sits in `_cmd_run`'s entry path, before the Ralph loop executes.
>
> In both modes, lock acquisition uses the same all-or-nothing `BEGIN IMMEDIATE` SQLite transaction with overlap detection. In direct dispatch, **every `tess run` invocation has SQLite transaction semantics on its hot path.** Concurrent LaunchAgents attempting to acquire overlapping locks contend at the SQLite transaction level — the `BEGIN IMMEDIATE` discipline is sufficient to serialize them, but lock-denied must be handled as a retryable condition, not an error, since LaunchAgents will naturally race on cadence boundaries.
>
> Path-overlap detection (§3.4.1) and lock-acquisition-failure behavior (§3.5) apply identically in both modes.

### 3.2.1 Open sub-question on lock-denied retry semantics (not resolved in this note)

"Retryable" has two defensible implementations with very different operational signatures:

- **R1. In-invocation spin-retry.** `tess run` acquires the lock inside the same invocation, blocking (with bounded timeout and backoff) until lock acquired or timeout. The LaunchAgent slot stays occupied during contention. Contention is invisible at the OS-scheduling level; surfaces only in elevated `duration_ms` on the staged row.
- **R2. Exit-and-wait-for-next-cadence.** `tess run` exits non-zero (a specific lock-denied exit code) and relies on the next LaunchAgent cadence tick to retry. Contention surfaces as repeated non-zero exits in `launchd` logs and as gaps in run-history for the lock-denied service.

R1 masks contention behind latency; R2 surfaces it behind exit-code noise. Both are defensible. Timeout ceilings differ too — R1 wants a timeout well under cadence interval; R2 is bounded by cadence itself. **This sub-question is explicitly named for decomposition (belongs to TV2-057.C), same as the C1/C2 schema sub-question in §2.2.** The note flags it; it does not pick.

### 3.3 Why this is called out explicitly

If TV2-057.x silently folds lock acquisition into `_cmd_run` as an implementation detail, the fact that every LaunchAgent invocation now executes a SQLite transaction gets rediscovered later — likely by a contention incident. Naming it in the Amendment front-loads the consequence so the implementation task (and its test plan) treats it as a known design property, not an emergent surprise.

---

## 4. State-machine semantics fix (primary finding)

### 4.1 Current behavior

`src/tess/ralph.py` defines `TerminalOutcome = {STAGED, ESCALATED, DEAD_LETTER}`. `STAGED` is terminal. All contracts that pass their tests + artifact checks land in STAGED regardless of whether they have canonical files to promote. `_cmd_run` writes one row to `run_history` with `outcome='staged'` and exits.

### 4.2 The conflation

STAGED is being used as the terminal state for two semantically distinct things:

1. **Class A/B contracts that have canonical files awaiting atomic promotion.** For these, STAGED is a genuine intermediate state — the state machine ladder in `staging-promotion-design.md` §5 describes STAGED → PROMOTION_PENDING → COMPLETED.
2. **Class C contracts with no canonical files.** For these, the executor has already produced the only real effect (Telegram delivered, SQLite row written, HTTP ping received). There is nothing to promote. STAGED is not intermediate — it is effectively terminal-by-accident.

The 5763 Class C staged rows and the 622 Class A rows are indistinguishable from the state machine's perspective. That's the semantic bug.

### 4.3 Proposed fix

Extend `TerminalOutcome` (or add a post-terminal phase) with `COMPLETED`. Class classification determines which transition the runner uses:

- **Class A/B (has canonical_outputs):** STAGED → PROMOTION_PENDING → `PromotionEngine.promote()` → COMPLETED, or → QUALITY_FAILED on conflict.
- **Class C (empty canonical_outputs):** STAGED → COMPLETED immediately (no-op promotion).

Both classes end at COMPLETED. The run-history row records the transition path. Class C contracts no longer occupy an intermediate state indefinitely.

### 4.4 Consequence for the 6465 staged rows

These are historical records, not in-flight work. The dispatched work already happened — the rows are the log. Proposed disposition:

- **Class C + Class B (5787 rows):** Bulk update `outcome='staged'` → `outcome='completed'` with a backfill note in run-history. Honest — these really were complete when they finished executing. Class B merged to Class C per §5 decision (`_openclaw/` mirror paths are not canonical; writes are side-effects).
- **Class A (622 rows):** Leave as `staged` with a "pre-promotion-era" annotation. Their staging directories in `_staging/` may or may not still exist; their canonical destinations may or may not have been manually promoted. Investigate per-row disposition in decomposition, not here.
  - **Landmine to audit:** Some Class A wrappers appear to be writing directly to canonical paths today, bypassing `_staging/` entirely. The obvious case is `vault-health` writing `vault-health-notes.md` directly via the wrapper — if this is confirmed (audit in 057.B or earlier), then turning on promotion for Class A in TV2-057.D is not merely adding a state transition — **it changes the write path for services that currently work.** That is a behavior change with rollback implications, not a wiring fix. See §6 for the consequence.
- **Test (56 rows):** Ignore or delete.

**No disposition is final until decomposition; the segmentation is what enables a clean disposition.**

---

## 5. Class B classification decision — CLOSED TO CLASS C

`overnight-research` writes to `_openclaw/research/output/`. `fif-capture` writes to `_openclaw/inbox/`. Both are under `_openclaw/`, which is a **mirror directory** — content from the OpenClaw platform is rsync'd into Tess's vault, and the mirror is not the canonical authority for those paths.

**Decision (operator-confirmed 2026-04-15):** Class B maps to Class C. No promotion. Rationale:

- `_openclaw/` is mirror, not canonical. Content is rsync'd from OpenClaw and is not the authoritative graph.
- Downstream consumers are batch/cadence-driven (overnight-research rollup into `Projects/…`; FIF classification reading inbox items). A torn read = one bad classification or one failed research rollup, recoverable on the next cadence.
- Atomic-promotion guarantees would be overkill for ephemeral inbox/output staging; the cost of the machinery exceeds the cost of the worst failure mode.

**Operational consequence:** Class B's 24 staged rows fold into Class C's backfill in §4.4 (5763 + 24 = 5787 rows to bulk-update). The A/B/C taxonomy stays intact in §1.2 as evidence of how we got here; for all subsequent decomposition, "Class B = Class C."

If a downstream consumer is identified post-TV2-057.A that requires atomic `_openclaw/` writes, this decision reopens — but the current reading of the consumer surface says no such consumer exists.

---

## 6. Decomposition sketch (not formalized; awaits §1 acceptance)

Deliberately sketchy. If the Class A/B/C split in §1 holds, the natural ordering is:

1. **TV2-057.A — Class C semantic fix.** Add `COMPLETED` to `TerminalOutcome`. Add a contract-class classification to Contract (or a predicate over `canonical_outputs`). Runner transitions Class C STAGED → COMPLETED immediately. Backfill 5787 side-effect staged rows (5763 Class C + 24 Class B merged per §5 decision). *Potentially independently shippable — unblocks 6465-row cleanup without any promotion code.*
2. **TV2-057.B — Schema + Amendment landing.** Pick Option C (§2) and commit the hybrid schema. Land the §3 Amendment. Resolve Class B classification (§5). No runtime behavior change yet.
3. **TV2-057.C — Lock acquisition.** Wire `WriteLockTable.acquire_locks()` at `_cmd_run` entry, Class A/B only. Tests: contention, hash capture, lock-denied retry.
4. **TV2-057.D — Promotion wiring.** Call `build_manifest()` + `promote()` on STAGED for Class A/B. Handle conflicts. Implement caller responsibilities (steps 9-12 of §5.2 sequence). **Not a blanket flip.** The §4.4 landmine (wrappers currently writing directly to canonical paths) means 057.D likely decomposes further into a per-service migration plan: audit which wrappers write directly, stop them writing directly, ensure staging artifact is produced, wire promotion, verify parity, cut over. `vault-health` → `vault-health-notes.md` is the obvious first audit target because it's the cleanest single-file case. This may mean 057.D is itself milestone-shaped, not a single task.
5. **TV2-057.E — Crash recovery.** `tess recover` subcommand; decide on startup-sweep invocation model.
6. **TV2-057.F — Class A backfill disposition.** Investigate 622 legacy rows per-service, decide per-class.

**Ordering is a proposal, not a plan.** §1 data suggests A is independently valuable and can ship before B–F. If operator review of §1 challenges this reading (e.g., "actually `fif-feedback` SQLite rows ARE the canonical artifact and need promotion-style atomicity"), the ordering inverts.

---

## 7. Decisions requested from operator

Before decomposition:

1. **§1 taxonomy:** Accept the A/B/C split? Any service misclassified?
2. **§2 schema location:** Accept Option C (hybrid) as the default? The C1-vs-C2 inheritance sub-question stays deferred.
3. **§3 Amendment:** Accept the §3.4.2 dispatch-modes Amendment as proposed, with the explicit callout that every `tess run` invocation has SQLite transaction semantics?
4. **§4 state machine:** Accept that Class C STAGED rows were semantically miscategorized and should backfill to COMPLETED?
5. **§5 Class B:** Defer to decomposition, or decide now? **Recommended: close this first when decomposition starts.** With only 24 staged rows across two services, the cost of deciding now (read 2 service definitions + ask: "do downstream consumers of `_openclaw/research/output/` or `_openclaw/inbox/` tolerate torn reads during a file update?") is small. The cost of carrying the ambiguity through 057.B–E is meaningful — Class B blocks lock acquisition, promotion wiring, and crash recovery for both services. **Class B is the cheapest of the deferred decisions to close; closing it early removes ambiguity from everything downstream.**
6. **§6 ordering:** Accept the sketch as a starting point, or propose alternative ordering?

On operator acceptance of §1–§5, TV2-057.A–F decomposition is drafted into `tasks.md` and the first sub-task enters active work.

---

## 8. Provenance

- Service taxonomy derived from `service-interfaces.md` `**Outputs**` row parsing (lines 27, 100, 187, 272, 366, 452, 546, 642, 728, 821, 913, 1015, 1125, 1222, 1305, 1393).
- Row counts from `~/.tess/state/run-history.db` snapshot 2026-04-15 19:28 UTC. Query: `SELECT service, outcome, COUNT(*) FROM run_history GROUP BY service, outcome;`
- Code references resolved against `tess-v2` repo at commit `02be7b789d0bccecf718fe32483464cff22db0f3` (HEAD of `/Users/tess/crumb-apps/tess-v2` as of 2026-04-15 18:43 -0400, tip of commit `TV2-056: address code-review must-fix findings`): `src/tess/promotion.py:185` (PromotionEngine class), `:214` (build_manifest), `:355` (promote), `:493` (recover_promotion); `src/tess/cli.py:649` (_cmd_run); `src/tess/ralph.py:27` (TerminalOutcome); `src/tess/contract.py:71` (ArtifactSpec); `src/tess/locks.py:96` (WriteLockTable).
- Design doc citations: `staging-promotion-design.md` §3.4 (lock acquisition at routing time), §5.2 (promotion sequence), §13 Open Question #1 (service-interface mapping deferred).
