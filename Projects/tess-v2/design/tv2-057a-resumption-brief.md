---
project: tess-v2
type: resumption-brief
domain: software
status: active
created: 2026-04-15
updated: 2026-04-15
task: TV2-057a
phase: 4b
source: tv2-057-promotion-integration-note.md; design session 2026-04-15 (session 3)
tags:
  - resumption
  - state-machine
  - class-c
---

# TV2-057a — Resumption Brief

> **Purpose.** Carry TV2-057a implementation to a fresh session without requiring replay of the design-decision thread. Reads standalone — no prior-thread context required.

## 1. What this task is

Add `COMPLETED` to `TerminalOutcome` in `ralph.py`. Add a classification predicate that identifies side-effect-only contracts (Class C per `tv2-057-promotion-integration-note.md` §1). When the predicate returns True, `run_ralph_loop` downgrades the terminal outcome from STAGED → COMPLETED. No canonical-vault writes. No lock acquisition. No `PromotionEngine` invocation.

Historical backfill of 5787 rows ships in the same PR as a separate commit but is **held from execution** until TV2-038 Phase 5 re-collection closes (earliest 2026-04-17 18:00Z).

## 2. Why this is shippable alone

~90% of staged run-history rows are Class C — side-effect-only contracts (Telegram/SQLite/HTTP pings) that have no canonical file to promote. They've been stuck in STAGED because the state machine conflates "awaiting promotion" with "terminal for services that have nowhere to promote to." This fix is a state-machine refactor over already-executed behavior — no canonical writes, safest piece of the TV2-057 milestone. See note §1.4.

## 3. Repo + code anchors

**Tree:** `/Users/tess/crumb-apps/tess-v2`
**SHA to verify against before editing:** `02be7b789d0bccecf718fe32483464cff22db0f3` (HEAD at design time, 2026-04-15 18:43 -0400, tip of TV2-056 must-fix commit). **First action in fresh session:** run `git rev-parse HEAD` — if it's drifted, re-verify the line numbers below before editing.

**Touch points (line numbers anchored to SHA above):**
- `src/tess/ralph.py:27` — `TerminalOutcome` enum (currently `STAGED`, `ESCALATED`, `DEAD_LETTER`)
- `src/tess/ralph.py:286` — where `outcome=TerminalOutcome.STAGED` is set in `run_ralph_loop` (confirm — may be multiple sites)
- `src/tess/cli.py:235` — `_print_result_summary` (handle COMPLETED branch)
- `src/tess/cli.py:649` — `_cmd_run` (exit code: COMPLETED treated as success, same as STAGED)
- `src/tess/cli.py:702` — `_record_to_history` call site (COMPLETED rows written here)

**Schema reference:** `~/.tess/state/run-history.db`. Columns relevant to this task: `outcome`, `dead_letter_reason`. See §7 below for the annotation decision.

## 4. Classification predicate

**Location:** new file `src/tess/classifier.py` (keeps ralph.py clean).

**Signature:**
```python
def is_side_effect_contract(contract: Contract) -> bool:
    """Class C classifier — contracts with no canonical vault file to promote.

    Placeholder implementation using a hardcoded service-name allowlist.
    Designed as a seam: TV2-057b replaces the body (reads from
    canonical_outputs schema field) without changing the signature or
    callsites. DO NOT add logic here that isn't reducible to the
    canonical_outputs check 057b will implement.
    """
    # TODO(TV2-057b): replace allowlist with `len(contract.canonical_outputs) == 0`
    # check once the schema field lands. See tv2-057-promotion-integration-note.md §2.
```

**Allowlist (13 services, deduplicated):**
```
awareness-check
backup-status
email-triage
fif-attention
fif-capture
fif-feedback-health
health-ping
overnight-research
scout-daily-pipeline
scout-feedback-poller
scout-weekly-heartbeat
vault-gc
```

Wait — that's 12. Let me list again including Class B folded to C per note §5:

Class C original (10): awareness-check, backup-status, email-triage, fif-attention, fif-feedback-health, health-ping, scout-daily-pipeline, scout-feedback-poller, scout-weekly-heartbeat, vault-gc.
Class B folded (2): fif-capture, overnight-research.

**Final allowlist (12 services, no duplicates):**
- awareness-check
- backup-status
- email-triage
- fif-attention
- fif-capture
- fif-feedback-health
- health-ping
- overnight-research
- scout-daily-pipeline
- scout-feedback-poller
- scout-weekly-heartbeat
- vault-gc

**Services NOT in allowlist (Class A — must remain STAGED, not COMPLETED):**
- vault-health
- daily-attention
- connections-brainstorm
- morning-briefing (cancelled, but exclude defensively in case contract re-enters)

Cross-verify against `contracts/*.yaml` service names before finalizing — service-name mismatches are a real risk.

## 5. Integration point in ralph.py

After the Ralph loop finishes and outcome is set to `STAGED`, before returning the `RalphResult`, check `is_side_effect_contract(contract)`. If True, downgrade outcome to `COMPLETED`. The downgrade must happen inside `run_ralph_loop` (the state machine authority), not in `_cmd_run` (which should remain state-machine-unaware).

**Verify in fresh session:** `run_ralph_loop` may set STAGED in more than one place (convergence pass, early-exit-on-success path, etc.). The downgrade must cover every STAGED-setting site. If there's a clean single-return convergence, downgrade once at the return. If there are multiple sites, refactor to a single "finalize outcome" helper first.

## 6. Test strategy

**New unit tests:**
- `tests/test_classifier.py` — each Class C service → True; each Class A service (vault-health, daily-attention, connections-brainstorm) → False; unknown service name → False (safe default: unknown services stay STAGED).
- `tests/test_ralph.py` (add to existing) — Class C contract → COMPLETED; Class A contract → STAGED; ESCALATED/DEAD_LETTER paths unaffected for both classes.

**Integration test:**
- Run an `awareness-check` contract end-to-end using the test fixture infrastructure. Assert `run_history.outcome == 'completed'` for the new row. Verify exit code 0.

**Regression check before landing:**
- Run full `pytest` suite (433 tests per TV2-056 baseline). Any test that asserts `outcome=='staged'` for a Class C service is legitimately broken by this change — update the assertion, don't mask.

## 7. Backfill annotation decision (resolve as first verification, NOT during implementation)

Two options for annotating the 5787 backfilled rows so future operators can identify them:

| Option | Mechanism | Cost |
|---|---|---|
| **A. Sentinel in `dead_letter_reason`** | Set `dead_letter_reason = 'tv2-057a-backfill'` on backfilled rows (normally null on success rows). | No schema change. Overloads an existing nullable field with a meaning it wasn't designed for. Reversible: `UPDATE ... SET dead_letter_reason=NULL WHERE dead_letter_reason='tv2-057a-backfill'`. |
| **B. New column** | `ALTER TABLE run_history ADD COLUMN outcome_annotation TEXT`. Write `'tv2-057a-backfill'` there; future 057f backfill reuses the column with a different sentinel. | Schema migration with its own review surface. Existing read paths must tolerate the new column (SQLAlchemy or raw queries — check how the codebase handles schema reads). |

**Lean:** A, on the grounds that this is a one-time operation and the alternative (schema migration for an ephemeral backfill) is tail-wagging-dog. But decide in Verification 0 (§9) after reading how the codebase handles `run_history` schema evolution — if there's already a versioned migration pattern, B may be cheap; if not, A wins on pragmatics.

**Do not defer this to mid-Commit-2.** It must be resolved before the backfill script is written.

## 8. Commit structure

**Commit 1 — code landing (safe to merge + run immediately):**
- `ralph.py`: add `COMPLETED` to enum; downgrade STAGED → COMPLETED at outcome-finalize site if predicate returns True
- `classifier.py` (new): `is_side_effect_contract` with hardcoded allowlist + TODO marker
- `cli.py`: COMPLETED branch in `_print_result_summary`; COMPLETED → exit code 0
- Tests: unit + integration per §6

**Commit 2 — backfill script (landed in same PR, held from execution):**
- `scripts/tv2_057a_backfill.py` (or canonical scripts path the repo uses): dry-run by default; `--execute` flag; logs affected row count; uses annotation mechanism per §7 decision.
- `Projects/tess-v2/design/tv2-057a-backfill-runbook.md`: prereq = Phase 5 closed (≥2026-04-17 18:00Z); procedure = DB copy → dry-run → execute → verify count.

**Hold condition:** Phase 5 re-collection of TV2-038 must complete before the backfill runs against live `run_history`. Running it earlier would cause Phase 5 gate verdicts to be computed against post-backfill data, which breaks the Phase 5 evaluation's assumptions about what STAGED means.

## 9. Pre-writing verifications (order matters)

0. **Read SQLite schema-migration pattern in repo** (if any). Decide A vs. B in §7 based on findings. Record decision in commit message + brief.
1. **Verify HEAD SHA matches `02be7b789d0bccecf718fe32483464cff22db0f3`** or re-confirm line numbers in §3.
2. **Map every STAGED-setting site in `ralph.py`.** One site = clean downgrade at the site. Multiple sites = refactor to single finalize helper first.
3. **Enumerate existing tests asserting `outcome=='staged'`** for Class C services. Count them before starting — the fresh session should expect to touch this many tests.
4. **Cross-verify allowlist against `contracts/*.yaml`** `service:` fields. One mismatch = one untested bug.

## 10. Do-not list

- Do not modify the classifier to read from `canonical_outputs` — that's 057b.
- Do not run the backfill script against live `run_history` until Phase 5 is confirmed closed.
- Do not touch `PromotionEngine`, `WriteLockTable`, or any promotion machinery — that's 057c/d.
- Do not add schema migration infrastructure beyond what §7 resolution requires.
- Do not extend the allowlist with services not already catalogued as Class C/B in `tv2-057-promotion-integration-note.md` §1.2. If a new service needs classification, it goes to 057b's canonical_outputs schema, not to the placeholder allowlist.

## 11. Done criteria

- Commit 1 landed, tests green, `pytest` at 433+ passing.
- Commit 2 landed, script dry-run tested against a DB copy, runbook written.
- Backfill **not** yet executed. Runbook waits on Phase 5 confirmation.
- `tasks.md` TV2-057a state → `done` only after backfill completes (which is post-Phase-5).
- For intermediate "code landed, backfill held" state, tasks.md can stay `in_progress` with a note, or a sub-state like `code-landed-awaiting-phase5`. Pick one convention and use it.

## 12. What changes in `tasks.md` + `project-state.yaml` when done

- `tasks.md` TV2-057a: `in_progress` → `done` (after backfill)
- `project-state.yaml` `active_task`: `TV2-057a` → null (or next sub-task)
- `project-state.yaml` `next_action`: update tally (45/57 → 46/57) and point at TV2-057b (if starting immediately) or TV2-038 Phase 5 (if waiting for the gate)

---

**Entry point for fresh session:** read this file, then `Projects/tess-v2/design/tv2-057-promotion-integration-note.md` §1, §4, §6 if the taxonomy or Class-C reasoning is unclear. Tasks.md TV2-057a row is the authoritative work statement; this brief is the how-to.
