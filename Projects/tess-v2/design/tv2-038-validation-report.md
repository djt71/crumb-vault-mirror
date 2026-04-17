---
project: tess-v2
type: design-artifact
domain: software
status: draft
created: 2026-04-15
updated: 2026-04-17
task: TV2-038
phase: 4b
depends_on:
  - TV2-043
  - TV2-044
source: tasks.md acceptance criteria for TV2-038, migration-inventory.md, observability-design.md, service-interfaces.md, staging-promotion-design.md, spec §18 (observability), AD-001 (vault authority)
tags:
  - validation
  - migration
  - parallel-operation
---

# TV2-038 — Parallel Operation Validation Report

> **Purpose.** Evidence-based verification that every migrated Tess v2 service is
> production-ready relative to its OpenClaw counterpart, and that the eight
> acceptance criteria in `tasks.md` TV2-038 are satisfied before TV2-039
> cutover decision.
>
> **Status.** Draft schema — Phase 1 of 4. Data collection and verification
> populate this document across Phases 2–4.

---

## 1. Scope

### 1.1 Services in comparison scope

Services that currently run on **both platforms** and produce comparable outputs. Infrastructure (`com.crumb.*`), Danny-domain (`apple-snapshot`), and third-party (Ollama) are out of scope — they are either kept as-is or covered by the Category G/H classifications in `migration-inventory.md`.

| # | Service pair | Migration task | Cadence | Notes |
|---|---|---|---|---|
| 1 | `ai.openclaw.health-ping` ↔ `com.tess.v2.health-ping` | TV2-032 | 900s | Dead-man's-switch ping |
| 2 | `com.tess.backup-status` ↔ `com.tess.v2.backup-status` | TV2-032 | 900s | Backup monitoring |
| 3 | `ai.openclaw.vault-health` ↔ `com.tess.v2.vault-health` | TV2-033 | Daily 02:00 | Vault health notes |
| 4 | `com.crumb.vault-gc` ↔ `com.tess.v2.vault-gc` | TV2-033 | Daily 04:00 | Vault GC |
| 5 | `ai.openclaw.fif.capture` ↔ `com.tess.v2.fif-capture` | TV2-034 | Daily 06:05 | RSS + X capture |
| 6 | `ai.openclaw.fif.attention` ↔ `com.tess.v2.fif-attention` | TV2-034 | Daily 07:05 | Attention scoring |
| 7 | `ai.openclaw.fif.feedback` ↔ `com.tess.v2.fif-feedback-health` | TV2-034 | KeepAlive / 900s | Feedback listener |
| 8 | `ai.openclaw.awareness-check` ↔ `com.tess.v2.awareness-check` | TV2-035 | 1800s | Awareness alerts |
| 9 | `ai.openclaw.daily-attention` ↔ `com.tess.v2.daily-attention` | TV2-035 | 1800s | Attention plan |
| 10 | `ai.openclaw.overnight-research` ↔ `com.tess.v2.overnight-research` | TV2-035 | Daily 23:00 | Research artifacts |
| 11 | `com.scout.daily-pipeline` ↔ `com.tess.v2.scout-pipeline` | TV2-043 | Daily 07:00 | Scout digest |
| 12 | `com.scout.feedback-poller` ↔ `com.tess.v2.scout-feedback-poller` | TV2-043 | KeepAlive | Scout feedback (only OpenClaw active pending IDQ-004 cutover) |
| 13 | `com.scout.weekly-heartbeat` ↔ `com.tess.v2.scout-weekly-heartbeat` | TV2-043 | Monday 08:00 | Scout weekly heartbeat |
| 14 | *n/a* ↔ `com.tess.v2.scout-feedback-health` | TV2-043 | 900s | Contract health check (Tess-only, no OpenClaw peer) |
| 15 | `com.tess.connections-brainstorm` ↔ `com.tess.v2.connections-brainstorm` | TV2-044 | Daily 86400s | Connections brainstorm |

**Explicitly out of scope:**
- `email-triage` — cancelled 2026-04-10 (TV2-036).
- `morning-briefing` — cancelled (TV2-037, dep on 036).
- Tess v2 platform services (dispatch, contract runner, staging promotion) — validated via contract infrastructure, not a parallel comparison.

### 1.2 48h observation window

Parallel operation has been continuous since the last service migrated (2026-04-05 for Scout; earlier for all others). The 48h window is satisfied de facto. Phase 2 data collection samples the **trailing 48h** (2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC) as the canonical window. Supplementary evidence from the broader trailing 7–14 days may be cited for low-cadence services where 48h yields too few samples (weekly heartbeat, daily research).

### 1.3 What constitutes parity

| Dimension | Definition |
|---|---|
| **Output parity** | Same artifact categories produced by both platforms during the window (e.g., daily digest markdown, attention plan, research note) — not byte-identical content. Content differences are expected and acceptable if both platforms produce a qualifying output. |
| **No missed outputs** | Expected-cadence runs all executed. A service with 48h cadence and one run in the window is complete. Platform-specific dead-letters are acceptable if the other platform succeeded. **Both-platform misses = gate fail.** |
| **Tier routing** | Tess v2 contract-ledger entries in the window, fraction with `tier ∈ {1, 2}`. Target: ≥70%. |
| **Cost ceiling** | Tess v2 `cost-tracker.yaml` pro-rated to monthly: $75/month hard ceiling for gate pass; $50/month target for TV2-039 cutover approval. |

### 1.4 Phase 5 re-collection methodology (added 2026-04-17)

Phase 5 re-runs the Phase 2 data collection on a clean window (post-TV2-056 contract remediation) and confirms gate verdicts. Added after Phase 4 because (a) Phase 2 contract-gate verdicts were compromised by the stale-artifact bug fixed in TV2-056, and (b) the `outcome` field semantics changed mid-project with TV2-057a.

**Window.** `2026-04-15 23:00Z → 2026-04-17 23:00Z` (48h rolling, whole-hour boundaries, opens 17min after TV2-056 must-fix commit `02be7b7` landed at 22:43Z).

**Outcome semantics — Class A vs Class C bifurcation.**

TV2-057a (code landed 2026-04-16 00:43Z, historical backfill held pending Phase 5) split the `outcome` field into:

- `outcome='staged'` — Class A: ran successfully, produced an artifact that requires promotion from `_staging/` to its canonical vault path. Promotion is the side-effect.
- `outcome='completed'` — Class C: ran successfully, side-effect is the run itself (e.g., a ping, a pipeline trigger, a KeepAlive probe). No vault artifact to promote.

**Class mapping** (per `src/tess/classifier.py:_CLASS_C_SERVICES` at TV2-057b landing):

| Class | Services | Phase 5 success predicate |
|---|---|---|
| **Class A** (requires promotion) | `daily-attention` | `outcome = 'staged'` |
| **Class C** (side-effect is the run) | `awareness-check`, `backup-status`, `connections-brainstorm`, `email-triage`, `fif-attention`, `fif-capture`, `fif-feedback`, `health-ping`, `overnight-research`, `scout-daily-pipeline`, `scout-feedback`, `scout-weekly-heartbeat`, `vault-gc`, `vault-health` | `outcome IN ('staged', 'completed')` — union required because the window's first ~1h 43min (23:00Z → 00:43Z 2026-04-16) predates code landing, so Class C rows there are `staged` under the old semantic. Post-00:43Z all Class C rows are `completed`. Both count as success. |

**Amendment (TV2-057b, 2026-04-17):** `connections-brainstorm` and `vault-health` moved A → C. See `tv2-057-promotion-integration-note.md` §1.1 amendment. `connections-brainstorm` writes to `_openclaw/inbox/` (mirror space, not canonical — §5). `vault-health` canonical writer is still the OpenClaw plist; Tess v2 wrapper produces only staging-scoped output. Phase 5 gate-math uses the amended classification.

Services outside the 1+13 mapping (`test`, `scout-feedback-health`, `scout-feedback-poller`) retain their service-specific conventions as documented in their §2 blocks.

**AC #5 "No missed outputs" — re-stated for Phase 5.**
A service's run is **successful** if its outcome is in the success predicate for its class. A run is a **failure** if `outcome='dead_letter'`. Both-platform failures on an expected-cadence run remain a gate fail.

**Data source.** `~/.tess/state/run-history.db`, `run_history` table, filtered by `started_at` in the Phase 5 window. Cross-referenced against `_staging/TV2-*/` artifacts and OpenClaw last-run timestamps for peer parity.

---

## 2. Per-Service Reports

Populated from `~/.tess/state/run-history.db` queries, `_staging/TV2-*/` artifacts, `_openclaw/state/last-run/` timestamps, and OpenClaw output artifacts (scout digests, FIF inbox, backup-status.json, vault-health-notes.md, daily notes). Data collected 2026-04-15 via 6 parallel Explore subagents grouped by migration task family.

**Preliminary findings flagged here, detailed in service blocks:**

| # | Service | Finding | Severity |
|---|---|---|---|
| *all 9* | 9 of 15 services | Contracts validating **stale Apr 2–5 artifacts** because wrappers only wrote to stdout (captured as `execution-log.yaml`), never to the per-service named file the contract checks. **Root cause of Phase 2 apparent anomalies below.** Fixed as **TV2-056** (wrapper + contract remediation, session 2026-04-15). | **BLOCKER → fixed** |
| 5 | `fif-capture` | Originally flagged "Tess v2 captures 0 items; OpenClaw inbox growing" as BLOCKER. **Reclassified non-blocker after root-cause:** FIF's internal per-adapter cooldown skips Tess v2's 10:30 UTC run because OpenClaw's 06:05 UTC run already captured the day's items. Both platforms share the same `capture-clock.js` backend and SQLite — "both running in parallel" is architecturally "only one productive run per day" regardless of which platform triggers. The real parallel-run question is "can Tess v2 replace OpenClaw at cutover" (TV2-039 scope), not "both productive concurrently". | **non-blocker** |
| 10 | `overnight-research` | Originally flagged "Apr 13 DEAD_LETTER; Apr 14 zero-output" as BLOCKER. **Reclassified non-blocker after root-cause:** (a) wrapper's NO_OP regex was case-sensitive and missed "no reactive items" (lowercase); (b) research-log.yaml contract artifact was stale Apr 3 — same bug as #5 above. Both fixed in TV2-056. Apr 13 dead-letter was legitimate upstream failure (underlying script non-zero exit); Apr 14/15 zero-output were legitimate no-op nights (not a scheduled Competitive/Builder night + empty reactive queue). | **non-blocker → fixed** |
| 3 | `vault-health` | OpenClaw peer last-run stale 13 days (pre-window). Tess v2 clean but OpenClaw parallel operation stopped. | investigate |
| all | cost data | `cost-tracker.yaml` not deployed (TV2-028 infra absent). All "Cost" sections PENDING. | cross-cutting |
| 11 | `scout-pipeline` | Tess v2 staging timestamps (11:xx UTC) offset from OpenClaw cadence (07:00 UTC) — pipeline runs twice through its own orchestration rather than at the scheduled trigger. Not a failure; explained in Notes. | neutral |
| — | email-triage | TV2-036 was cancelled 2026-04-10 but `email-triage` has 441 run-history entries through 2026-04-15 — service still executing. State reconciliation issue for §3.3. | investigate |

**Phase 2 re-collection:** Service blocks below are written from raw `run-history.db` data (authoritative — unaffected by the contract artifact bug). Contract-gate verdicts from before TV2-056 are compromised and should be re-validated after TV2-056 lands and ≥48h of fresh data accumulates. A re-collection pass is tracked as Phase 5 in §6.

### Service 1: ai.openclaw.health-ping ↔ com.tess.v2.health-ping

**Migration task:** TV2-032
**Cadence:** 900s
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: ~192
- Tess v2 outcomes: 192 runs, all staged
- OpenClaw evidence: No last-run file inventoried for `health-ping` in `_openclaw/state/last-run/`; OpenClaw-side ping cannot be verified locally (external endpoint hc-ping.com).
- Content comparison: Tess v2 executing on cadence; OpenClaw peer parity not locally verifiable.
- Result: ✓ (Tess-side)

#### Missed outputs
- Tess v2 dead-letters: 0
- OpenClaw failures: not locally verifiable
- Both-platform misses: 0
- Result: ✓

#### Cost (Tess v2 only)
- N/A — cost-tracker not yet deployed (TV2-028). See §3.5.
- Result: PENDING

#### Tier routing (Tess v2 only)
- Contracts in window: 192
- Tier 1: 192 (100%) · Tier 2: 0 · Tier 3: 0 · Escalations: 0
- Result: ✓ (≥70% local+free; 100%)

#### Notes
- OpenClaw-side dead-man's-switch behavior (ping to hc-ping.com) not verifiable from local artifacts. Recommend TV2-039 cutover decision include external verification (curl the hc-ping status endpoint) before decommissioning OpenClaw peer.

---

### Service 2: com.tess.backup-status ↔ com.tess.v2.backup-status

**Migration task:** TV2-032
**Cadence:** 900s
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: ~192
- Tess v2 outcomes: 192 runs, all staged
- OpenClaw evidence: `_system/logs/backup-status.json` status=ok (latest 2026-04-15T21:28:05Z), vault backup age ~14h (last file 2026-04-15_0300.tar.gz)
- Content comparison: Both platforms producing backup-status outputs successfully.
- Result: ✓

#### Missed outputs
- Tess v2 dead-letters: 0
- OpenClaw failures: 0
- Both-platform misses: 0
- Result: ✓

#### Cost (Tess v2 only)
- N/A — cost-tracker not deployed. See §3.5.
- Result: PENDING

#### Tier routing (Tess v2 only)
- Contracts in window: 192
- Tier 1: 192 (100%) · Tier 2: 0 · Tier 3: 0 · Escalations: 0
- Result: ✓

#### Notes
- TimeMachine backup status is unavailable in current output but this appears to be a historical gap, not a regression introduced by migration.

---

### Service 3: ai.openclaw.vault-health ↔ com.tess.v2.vault-health

**Migration task:** TV2-033
**Cadence:** daily
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: 2
- Tess v2 outcomes: 2 staged (Apr 13 06:37 UTC, Apr 14 06:44 UTC), duration ~424–429s each
- OpenClaw evidence: last-run timestamp 2026-04-02 (**stale 13 days — pre-window**); `vault-health-notes.md` last modified 2026-04-15 but by unclear writer
- Content comparison: Tess v2 clean; OpenClaw last-run indicates peer execution stopped before window began
- Result: ✗ (parallel operation not actually parallel — OpenClaw peer dormant)

#### Missed outputs
- Tess v2 dead-letters: 0
- OpenClaw failures: peer not executing (inferred from stale last-run)
- Both-platform misses: 1 run window where only Tess v2 ran (acceptable if intentional; not if silent drift)
- Result: ✗ (investigate)

#### Cost (Tess v2 only)
- N/A — cost-tracker not deployed. See §3.5.
- Result: PENDING

#### Tier routing (Tess v2 only)
- Contracts in window: 2
- Tier 1: 2 (100%) · Escalations: 0
- Result: ✓

#### Notes
- **FINDING:** OpenClaw vault-health peer appears dormant (last-run 2026-04-02). If intentional (Tess v2 has taken over), update `migration-inventory.md` to reflect OpenClaw peer decommissioned. If unintentional, investigate silent stop. Either way, the TV2-038 claim of "running on both platforms ≥48h" is not literally satisfied for this service.

---

### Service 4: com.crumb.vault-gc ↔ com.tess.v2.vault-gc

**Migration task:** TV2-033
**Cadence:** daily 04:00
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: 2
- Tess v2 outcomes: 2 staged (Apr 13 08:30 UTC, Apr 14 08:30 UTC), duration 269ms each
- OpenClaw evidence: `com.crumb.vault-gc` plist exists; `vault-gc.log` actively written (updated 2026-04-15 04:00) with GC operations. No structured last-run file — cannot confirm window alignment.
- Content comparison: Both platforms producing GC activity; OpenClaw timing unconfirmed due to missing structured metadata.
- Result: N/A (insufficient metadata)

#### Missed outputs
- Tess v2 dead-letters: 0
- OpenClaw failures: unknown
- Both-platform misses: 0
- Result: N/A

#### Cost (Tess v2 only)
- N/A — cost-tracker not deployed.
- Result: PENDING

#### Tier routing (Tess v2 only)
- Contracts in window: 2
- Tier 1: 2 (100%) · Escalations: 0
- Result: ✓

#### Notes
- Tess v2 GC consistently fast (identical 269ms across runs). Recommend adding a last-run file convention to OpenClaw `com.crumb.vault-gc` or accepting that the service is legacy-metrics-only.

---

### Service 5: ai.openclaw.fif.capture ↔ com.tess.v2.fif-capture

**Migration task:** TV2-034
**Cadence:** daily 06:05
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: 2
- Tess v2 outcomes: 2 staged runs (Apr 13 10:30 UTC, Apr 14 10:30 UTC) — **BUT: latest execution (Apr 15 10:30) reports 0 items captured, 8 adapters skipped**
- OpenClaw evidence: 45 new items captured into `_openclaw/inbox/` since Apr 13 (113 total lifetime). OpenClaw capture active and effective.
- Content comparison: Tess v2 executing cleanly per contract but producing zero captures; OpenClaw is the sole platform doing actual capture work.
- Result: ✗ (contract staged but functional parity not achieved — Tess capture is a no-op)

#### Missed outputs
- Tess v2 dead-letters: 0 (contract-level)
- OpenClaw failures: 0
- Both-platform misses: 0 (Tess misses are hidden by contract-level success)
- Result: ✗ (semantic, not contract)

#### Cost (Tess v2 only)
- N/A — cost-tracker not deployed.
- Result: PENDING

#### Tier routing (Tess v2 only)
- Contracts in window: 2
- Tier 1: 2 (100%) · Escalations: 0
- Result: ✓

#### Notes
- **BLOCKER:** Contract-level success masks functional failure. The 8 skipped adapters suggest credential or adapter-config gaps. Investigate before TV2-039. Contract schema should include an `items_captured > 0` check or similar semantic gate to prevent this class of silent no-op.

---

### Service 6: ai.openclaw.fif.attention ↔ com.tess.v2.fif-attention

**Migration task:** TV2-034
**Cadence:** daily 07:05
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: 2
- Tess v2 outcomes: 2 staged (Apr 13 11:30 UTC, Apr 14 11:30 UTC); latest run (Apr 15 11:31) scored 5 items, 1 failed, cost_usd $0.0084
- OpenClaw evidence: No last-run marker; vault-mirrored FIF digest at `_openclaw/feeds/digests/2026-04-15.md`
- Content comparison: Tess v2 scoring active with tier breakdown (4 high, 6 medium); OpenClaw-side scoring not locally verifiable.
- Result: ✓ (Tess-side working; cost per run tiny)

#### Missed outputs
- Tess v2 dead-letters: 0
- OpenClaw failures: unknown
- Both-platform misses: 0
- Result: ✓

#### Cost (Tess v2 only)
- Per-run execution log reports cost_usd $0.0084 per run. Not the same as `cost-tracker.yaml`, but directional evidence that costs are trivially small for this service.
- Result: PENDING (still awaiting TV2-028 aggregation)

#### Tier routing (Tess v2 only)
- Contracts in window: 2
- Tier 1: 2 (100%) · Escalations: 0
- Result: ✓

#### Notes
- "Late mode" enabled in latest run — late_mode:true. Acceptable if expected; flag in tuning if unintended.

---

### Service 7: ai.openclaw.fif.feedback ↔ com.tess.v2.fif-feedback-health

**Migration task:** TV2-034
**Cadence:** KeepAlive / 900s health polling
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: ~192 (health checks)
- Tess v2 outcomes: 192 staged health checks
- OpenClaw evidence: `ai.openclaw.fif.feedback` launchd status healthy (verified via Tess-side health check: process_count=1, launchd_status=loaded)
- Content comparison: Tess v2 correctly observes OpenClaw poller as healthy.
- Result: ✓ (health-check parity; actual feedback parity deferred — see Notes)

#### Missed outputs
- Tess v2 dead-letters: 0
- OpenClaw failures: 0
- Both-platform misses: 0
- Result: ✓

#### Cost (Tess v2 only)
- N/A — cost-tracker not deployed.
- Result: PENDING

#### Tier routing (Tess v2 only)
- Contracts in window: 192
- Tier 1: 192 (100%) · Escalations: 0
- Result: ✓

#### Notes
- **STRUCTURAL:** Tess v2 side is a health-check wrapper, not an independent feedback consumer. Actual feedback poller runs on OpenClaw only. Migration of the poller itself is a pending task (analogous to scout IDQ-004 for scout-feedback-poller). Flag for TV2-039 cutover: a Tess-side FIF feedback poller needs to exist before OpenClaw's is decommissioned.

---

### Service 8: ai.openclaw.awareness-check ↔ com.tess.v2.awareness-check

**Migration task:** TV2-035
**Cadence:** 1800s
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: 96
- Tess v2 outcomes: 96 staged; latency 7–11ms per run
- OpenClaw evidence: last-run 2026-04-15T21:28:33 UTC (current, post-window)
- Content comparison: Both platforms executing on cadence; Telegram alert content parity assumed via success outcomes.
- Result: ✓

#### Missed outputs
- Tess v2 dead-letters: 0
- OpenClaw failures: 0
- Both-platform misses: 0
- Result: ✓

#### Cost (Tess v2 only)
- N/A — cost-tracker not deployed.
- Result: PENDING

#### Tier routing (Tess v2 only)
- Contracts in window: 96
- Tier 1: 96 (100%) · Escalations: 0
- Result: ✓

#### Notes
- Clean parallel run. No anomalies.

---

### Service 9: ai.openclaw.daily-attention ↔ com.tess.v2.daily-attention

**Migration task:** TV2-035
**Cadence:** 1800s
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: 96
- Tess v2 outcomes: 96 staged; avg 759ms; one 65-second latency spike at 2026-04-13T04:00:39 (isolated, recovered)
- OpenClaw evidence: last-run 2026-04-15T21:27:51 UTC (current)
- Content comparison: Daily files `_system/daily/2026-04-13.md` (121 lines), `2026-04-14.md` (111 lines), `2026-04-15.md` (114 lines) all non-empty with substantive content.
- Result: ✓

#### Missed outputs
- Tess v2 dead-letters: 0
- OpenClaw failures: 0
- Both-platform misses: 0
- Result: ✓

#### Cost (Tess v2 only)
- N/A — cost-tracker not deployed.
- Result: PENDING

#### Tier routing (Tess v2 only)
- Contracts in window: 96
- Tier 1: 96 (100%) · Escalations: 0
- Result: ✓

#### Notes
- Writer origin (Tess v2 vs OpenClaw) not determinable from git history — daily files were all created in a single housekeeping batch commit. Staging evidence confirms Tess v2 execution, which is authoritative. Single latency outlier (65s at 04:00 Apr 13) isolated — worth a follow-up scan of scheduler.log if/when deployed.

---

### Service 10: ai.openclaw.overnight-research ↔ com.tess.v2.overnight-research

**Migration task:** TV2-035
**Cadence:** daily 23:00
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: 2 (run Apr 13 23:00 delivers at Apr 14 early UTC; run Apr 14 23:00 delivers at Apr 15)
- Tess v2 outcomes: **1 DEAD_LETTER** (Apr 13 03:31, failure_class: semantic), **1 staged but zero-output** (Apr 14 03:36, items_processed=0, artifacts_produced=0, cost_usd 0.00)
- OpenClaw evidence: last-run 2026-04-15T03:36:54 UTC (post-window, 33s after Tess v2 staged run) — but no output artifacts found in `openclaw/research/output/` or vault research directories for window dates.
- Content comparison: **Neither platform produced research artifacts in the window.**
- Result: ✗ (both-platform zero-output gate failure)

#### Missed outputs
- Tess v2 dead-letters: 1 (Apr 13, semantic failure class)
- OpenClaw failures: no explicit failure, but no output artifacts produced
- Both-platform misses: 1 full day (Apr 13) + 1 productive miss (Apr 14 ran but produced nothing)
- Result: ✗

#### Cost (Tess v2 only)
- cost_usd: 0.00 per execution-log (consistent with zero-output runs)
- Result: PENDING (conceptually: free because nothing was done)

#### Tier routing (Tess v2 only)
- Contracts in window: 2
- Tier 1: 2 (100%) · Escalations: 0
- Result: ✓ (routing fine; it's the work itself that's broken)

#### Notes
- **BLOCKER:** Two consecutive days of effective research failure. Apr 13 semantic dead-letter signals upstream breakage (input data, research query logic, or tool integration); Apr 14 "success" with zero artifacts suggests the same underlying issue, possibly guarded-against by silent failure modes rather than raising. Investigate before TV2-039. Both platforms affected, which may point to a shared input/dependency (e.g., research queue empty, Perplexity auth expired, vault context stale).

---

### Service 11: com.scout.daily-pipeline ↔ com.tess.v2.scout-pipeline

**Migration task:** TV2-043
**Cadence:** daily 07:00 (OpenClaw); Tess v2 runs at ~11:xx UTC through its own orchestration
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: 2 (daily for 48h)
- Tess v2 outcomes: 2 staged (Apr 13 11:55 UTC, Apr 14 11:07 UTC); Apr 15 11:52 UTC outside window but verified clean in the C1 staging log
- OpenClaw evidence: digests delivered=true for Apr 13 (5 items, msg 63), Apr 14 (3 items, msg 66), Apr 15 (1 item, msg 67)
- Content comparison: Both platforms producing qualifying digest artifacts. TV2-043 gate closed 2026-04-15.
- Result: ✓

#### Missed outputs
- Tess v2 dead-letters: 0 (post Nemotron LIMIT 10 fix in commit ef93e1a)
- OpenClaw failures: 0
- Both-platform misses: 0
- Result: ✓

#### Cost (Tess v2 only)
- N/A — cost-tracker not deployed.
- Result: PENDING

#### Tier routing (Tess v2 only)
- Contracts in window: 2
- Tier 1: 2 (100%) · Escalations: 0
- Result: ✓

#### Notes
- Gate PASS already recorded today via IDQ-002 close. Tess v2 pipeline triggers via its own orchestration (11:xx UTC) rather than the OpenClaw-synchronized 07:00 trigger. Parity is on outputs, not schedule alignment.

---

### Service 12: com.scout.feedback-poller ↔ com.tess.v2.scout-feedback-poller

**Migration task:** TV2-043 (cutover gated on IDQ-004)
**Cadence:** KeepAlive
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- OpenClaw poller: actively running (verified via Tess-side health check).
- Tess v2 poller: pre-staged but not bootstrapped. Plist and wrapper exist at `/Users/tess/Library/LaunchAgents/com.tess.v2.scout-feedback-poller.plist` and `/Users/tess/crumb-apps/tess-v2/scripts/scout-feedback-poller-wrapper.sh`; bootstrap deferred to TV2-039 cutover execution (IDQ-004 plan).
- Content comparison: Only OpenClaw is the active poller, by design.
- Result: N/A (deferred service per IDQ-004 plan)

#### Missed outputs
- N/A — Tess v2 poller not bootstrapped by design.
- Result: ✓ (expected posture)

#### Cost (Tess v2 only)
- N/A — cost-tracker not deployed; also no Tess-side poller running yet.
- Result: PENDING

#### Tier routing (Tess v2 only)
- N/A — no Tess v2 poller runs in window.
- Result: N/A

#### Notes
- **Deferred posture per IDQ-004 plan, not a failure.** Flag for TV2-039 cutover: Tess-side poller bootstrap must execute at cutover moment, with OpenClaw poller simultaneously bootout, because Telegram `getUpdates` token is exclusive (only one poller at a time).

---

### Service 13: com.scout.weekly-heartbeat ↔ com.tess.v2.scout-weekly-heartbeat

**Migration task:** TV2-043
**Cadence:** Monday 08:00
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC (Monday Apr 13 falls in window)

#### Output parity
- Expected runs in window: 1 (Monday heartbeat); Tess v2 dry-run mode produced 2 additional non-Monday runs
- Tess v2 outcomes: heartbeat dry-runs staged Apr 13 12:30, Apr 14 12:30 (dry-run on non-Mondays by design — exercises code path without delivering). Monday heartbeat itself verified via TV2-043-C3 contract clean.
- OpenClaw evidence: weekly heartbeat delivery confirmed for 2026-W16.
- Content comparison: ✓ both platforms producing heartbeat artifacts.
- Result: ✓

#### Missed outputs
- Tess v2 dead-letters: 0
- OpenClaw failures: 0
- Result: ✓

#### Cost (Tess v2 only)
- N/A — cost-tracker not deployed.
- Result: PENDING

#### Tier routing (Tess v2 only)
- Contracts in window: 2 (dry-runs) + 1 (Monday)
- Tier 1: all (100%) · Escalations: 0
- Result: ✓

#### Notes
- Dry-run pattern on non-Mondays is a TV2-043 design decision (exercise the code path without delivering) — not a bug. Weekly heartbeat itself passed gate C3.

---

### Service 14: (no OpenClaw peer) ↔ com.tess.v2.scout-feedback-health

**Migration task:** TV2-043
**Cadence:** 900s
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: ~192 health checks
- Tess v2 outcomes: health-check execution logs present (`_staging/TV2-043-C2/execution-log.yaml` most recent 2026-04-15T21:27:52Z, service=scout-feedback, health=healthy, process_count=2, launchd_status=loaded). run_history records for this service are folded under the `scout-feedback` service name.
- OpenClaw evidence: no peer — Tess-native health check.
- Result: ✓ (Tess-native, no parity requirement)

#### Missed outputs
- Tess v2 dead-letters: 0
- Result: ✓

#### Cost (Tess v2 only)
- N/A — cost-tracker not deployed.
- Result: PENDING

#### Tier routing (Tess v2 only)
- N/A — local health introspection.
- Result: ✓ (no escalation paths)

#### Notes
- Service 14 reporting granularity: run-history.db stores these under `scout-feedback` not `scout-feedback-health`. Consider splitting the service name at the contract layer for clearer observability.

---

### Service 15: com.tess.connections-brainstorm ↔ com.tess.v2.connections-brainstorm

**Migration task:** TV2-044
**Cadence:** daily (86400s)
**Window:** 2026-04-13 00:00 UTC → 2026-04-15 00:00 UTC

#### Output parity
- Expected runs in window: 2
- Tess v2 outcomes: 2 staged (Apr 13 09:30 UTC, Apr 14 09:32 UTC)
- OpenClaw evidence: last-run 2026-04-15 11:32 EDT (fresh, ~2.5h old)
- Content comparison: Both platforms executing on schedule; brainstorm artifacts produced.
- Result: ✓

#### Missed outputs
- Tess v2 dead-letters: 0
- OpenClaw failures: 0
- Both-platform misses: 0
- Result: ✓

#### Cost (Tess v2 only)
- N/A — cost-tracker not deployed.
- Result: PENDING

#### Tier routing (Tess v2 only)
- Contracts in window: 2
- Tier 1: 2 (100%) · Escalations: 0
- Result: ✓

#### Notes
- TV2-044 gate already passed. Clean parallel run.

---

## 3. Cross-Cutting Verification

These checks are **not per-service** — they apply to the platform as a whole. Each is a single section with evidence and a ✓/✗ verdict.

### 3.5 Cost tracking infrastructure gap (TV2-028 not deployed)

**Finding.** `~/.tess/logs/cost-tracker.yaml` does not exist. The only file in `~/.tess/logs/` is `scout-feedback-poller.log`. The observability infrastructure specified in `observability-design.md` §1.2 (contract-ledger, escalation-log, cost-tracker, scheduler.log, promotion.log, credential-audit, system.log) is not yet deployed.

**Implication for TV2-038.** Acceptance criterion 3 ("Cost tracking active — pro-rated cost ≤$75/month ceiling") cannot be directly verified. Per-execution evidence (e.g., fif-attention cost_usd $0.0084 per run in execution-log) suggests costs are trivially small, but there is no aggregated monthly view.

**Proxy evidence.** All 15 services in window route 100% Tier 1 (local). Tier 1 is defined as $0/call. If the tier-1 routing holds, the cost ceiling is mechanically satisfied regardless of aggregation. But: (a) Tier 1 absolute dominance is itself worth interrogating — either the router is working as designed (local-first bias), or escalation logic isn't firing when it should. (b) Per-execution API costs from occasional tier-2 calls (fif-attention uses a paid model for scoring, per the $0.0084 number) are not being tracked.

**Recommendation.** Mark criterion 3 as **PENDING — blocked on TV2-028 observability deployment.** Either deploy TV2-028 infrastructure before TV2-039 cutover, or explicitly accept the risk and revisit post-cutover. Do not fabricate cost data.

---

### 3.1 Vault Authority (AD-001)

**Claim.** No Tess v2 write path bypasses staging-to-canonical promotion for vault artifacts.

**Method.** Read `src/tess/staging.py`, `src/tess/promotion.py`, `src/tess/runner.py`, `src/tess/dispatch.py`, `src/tess/claude_dispatch.py`, `src/tess/executors/shell.py`. Grepped for `open(`, `.write_text`, `Path.write_*` and `/Users/tess/crumb-vault/` destination paths across the source tree. Cross-checked against `staging-promotion-design.md` §4. Inspected `~/.tess/logs/` for promotion.log presence. Reviewed `cli.py _cmd_run` for the call sequence.

**Evidence**
- **Direct vault-write grep:** 2× `os.write()` calls in `promotion.py` (vault file writes, inside the promotion lock). 3× `.write_text()` calls in `executors/shell.py` (all scoped to staging directory). No direct vault writes in executors or runner outside staging. `claude_dispatch.py:114–116` embeds the constraint string "Do not modify files outside staging" in the Claude prompt. `promotion.py:244–253` validates that every source/destination stays within `staging_root` or `vault_root` respectively.
- **Promotion gate isolation:** `promotion.py` is the sole canonical-write module. It implements the atomic 12-step sequence from `staging-promotion-design.md` §5.2, verifies hashes inside the lock (`promotion.py:384–395`), and enforces the write-lock table precondition (`promotion.py:257–260`). But — **see finding below** — it is never called.
- **Claude dispatch sandbox:** The prompt communicates staging-only intent (line 114). Claude Code itself is invoked via `claude -p` (executors/claude_code.py:68–74) and inherits Claude Code's own filesystem sandboxing. No vault paths are passed as write targets in the prompt; only staging paths.
- **Promotion log sampling:** `~/.tess/logs/promotion.log` **does not exist**. Directory contains only `scout-feedback-poller.log`. Confirms TV2-028 observability gap identified in §3.5.

**Finding F3.1-1 — CRITICAL: Promotion engine is unintegrated.** `promotion.py` is a complete, well-documented module (~540 lines with hash verification, atomic copy, crash recovery, rollback). However, **no code path calls `PromotionEngine.promote()`**. `cli.py _cmd_run` dispatches to `run_ralph_loop()` which ends at the STAGED outcome; the transition STAGED → PROMOTION_PENDING → COMPLETED (per design §5.2) is not wired in. Staged artifacts remain in `_staging/` indefinitely — they never reach canonical vault paths.

**Implication.** The TV2-038 claim "no bypass" is technically satisfied (no promotion code path exists for executors to bypass), but it's satisfied vacuously. The design-intended vault authority gate is present in code but dormant. For TV2-039 cutover this is a **blocker**: OpenClaw cannot be decommissioned while Tess v2 artifacts never leave staging.

**Verdict:** ⚠ PASS-with-caveats. No write-path bypass; promotion engine unintegrated is a downstream blocker for cutover, not a security violation today.

---

### 3.2 Evaluator Separation

**Claim.** Executor agents cannot self-promote — only the orchestrator, after contract verification, promotes staged artifacts to final paths.

**Method.** Read all three executors (`shell.py`, `claude_code.py`, `nemotron.py`). Grepped for `from .promotion`, `from tess.promotion`, `PromotionEngine`, `.promote(`, `promotion.promote` across the entire Python tree. Inspected `runner.py:663–842` for test evaluation and artifact checking flow. Inspected `locks.py:126–198` for write-lock table semantics.

**Evidence**
- **Import graph:** No executor imports `promotion.py`. All three executors import only `ExecutorProtocol`, `ExecutorRequest`, `ExecutorResponse` from the runner module.
- **Promotion invocation sites:** Grep `PromotionEngine|\.promote(|promotion\.promote` returns matches **only inside `promotion.py` itself** (class definition line 185, internal recovery line 538). `PromotionEngine` is never instantiated elsewhere in the codebase.
- **Executor permission envelopes:** Claude dispatch (`claude_dispatch.py:83–117`) passes staging_path in the prompt, embeds the "do not modify files outside staging" constraint, and has no promotion-related tools. Shell executor (`shell.py:47, 66`) sets `STAGING_PATH` and `VAULT_ROOT` env vars and runs with `cwd=vault_root`; a wrapper could write absolute paths under vault_root, but (per §3.1 evidence) no wrapper does so, and the test evaluator validates staging paths for content checks.
- **Post-execution validation:** `runner.py:795–814` runs all tests after executor completion; `runner.py:39–68 resolve_path` enforces path-boundary validation with exception-on-escape. Test evaluation is mechanical against staging outputs; the runner does not defer to executor self-assessment.
- **Write-lock table:** `locks.py:143` uses `BEGIN IMMEDIATE` for all-or-nothing lock acquisition. Ancestor/descendant overlap detection (`locks.py:161–198`) prevents two contracts from claiming overlapping canonical paths. This is a **dispatch-time control** — it gates who can *eventually* promote, not the promotion act itself.

**Finding F3.2-1 — Same integration gap as F3.1-1.** Executors correctly have no access to promotion mechanisms — structurally separated. But the orchestrator doesn't actually promote either, because promotion is unintegrated. The "only orchestrator promotes" claim is aspirational rather than runtime-enforced: today, *no one* promotes.

**Finding F3.2-2 — MINOR: No explicit role-boundary guard.** Nothing prevents a future executor edit from importing `promotion.py` and calling `.promote()` directly. Recommend adding a module-level comment in `promotion.py` marking it orchestrator-only, or considering a decorator-based role check for future hardening. Low urgency.

**Verdict:** ⚠ PASS-with-caveats (structural separation clean; integration gap compounds §3.1).

---

### 3.3 State Reconciliation

**Claim.** No orphaned jobs, state artifacts, or credential gaps exist between OpenClaw and Tess v2.

**Method.** Snapshot of `launchctl list | grep -E "com\.(tess|crumb|scout|fif)|ai\.(openclaw|hermes)|homebrew"` → 43 loaded services. Cross-reference against `migration-inventory.md` (24 cataloged services + 2 cron jobs + 1 third-party). Enumerate `_openclaw/state/*` and `last-run/*`. Sample 3 credentials via `security find-generic-password -s <service>` (no value dumps).

**A.1 — Orphaned-running audit**

Services RUNNING but NOT in inventory (5 new):
- `com.tess.nemotron-load` — LLM model loader. Propose: KEEP (Category G).
- `com.tess.soak-monitor` — purpose unclear. Propose: ASSESS.
- `com.tess.llama-server` (PID 800) — alternative LLM server. Propose: ASSESS (may replace `homebrew.mxcl.ollama`).
- `com.crumb.vault-rebuild` — rebuild tool. Propose: KEEP (Category G).
- `com.crumb.vault-web` (PID 804) — vault web API. Propose: KEEP (Category G).

Services in inventory but NOT RUNNING: none.

Reconciled as expected: 38/43 (88%).

**A.2 — email-triage disposition**
- OpenClaw: `ai.openclaw.email-triage` loaded, **exit 1** (auth failure). Last-run 2026-04-15 18:28 (13h old).
- Tess v2: `com.tess.v2.email-triage` loaded, **exit 0** (healthy).

Both platforms still loaded despite TV2-036 cancellation 2026-04-10. OpenClaw plist remains. **Recommendation:** Unload `ai.openclaw.email-triage` and drop plist to stop exit-1 noise. Tess v2 replica can stay or also be unloaded per cancellation intent. Flag for TV2-040 decommission scope.

**A.3 — vault-health disposition (CORRECTS PHASE 2 §2.3 FINDING)**

Phase 2 §2.3 reported OpenClaw vault-health "last-run stale 13 days" based on raw Unix epoch timestamp 1776233217 read by the subagent. Correct conversion: **1776233217 = 2026-04-15T02:06:57Z**, not 2026-04-02. Last-run is 16 hours old, within expected daily 02:00 cadence. **OpenClaw peer is NOT dormant.** Phase 2 §2.3 verdict was based on a subagent math error; corrected here.

**A.4 — State file ownership**

| State file | Producer | Last-write | Classification | Active platform |
|---|---|---|---|---|
| `last-run/email-triage` | `ai.openclaw.email-triage` | 2026-04-15 18:28 | migrate | OpenClaw |
| `last-run/vault-health` | `ai.openclaw.vault-health` | 2026-04-15 02:06 | migrate | OpenClaw |
| `apple-calendar.txt` | `danny:apple-snapshot` | 2026-04-11 | keep | Danny |
| `email-triage-auth-failed` | `email-triage.sh` | 2026-04-12 | migrate-pattern | OpenClaw |
| `vault-health-notes.md` | `vault-health.sh` | 2026-04-15 | migrate | OpenClaw |
| `delivery-log.yaml` | Tess dispatch (OpenClaw era) | 2026-04-13 | migrate to `~/.tess/logs/` | OpenClaw |

**Summary:** OpenClaw still owns the active write path for migrating services during the overlap. Tess v2 replicas are loaded and healthy but not driving state. Expected posture during parallel operation. No conflicts detected.

**A.5 — Credential spot-check**

| Credential | Keychain present | Tess v2 source ref | Duplication |
|---|---|---|---|
| Anthropic API key | ✓ | ✓ | no |
| Tess Telegram bot token | ✓ | ✓ | no |
| Brave Search API key | ✓ | ✓ | no |

FIF env (`~/.config/fif/env.sh`) sources from Keychain at runtime — no static duplication.

**A.6 — last-run comparison**

`~/.tess/state/run-history.db` does not yet track OpenClaw-peer services for migrated workloads; the legacy `_openclaw/state/last-run/` files are the OpenClaw-side timestamps. For services where OpenClaw is still the active producer (email-triage, vault-health above), Tess v2 contract runs show in `run-history.db` but OpenClaw's last-run timestamps reflect the platform that actually drove the work. This is the expected parallel-operation posture; not a defect.

**Verdict:** ✓ PASS (with follow-ups: unload OpenClaw email-triage plist; catalog 5 new services in §3.4).

---

### 3.4 Migration Inventory Re-audit

**Claim.** Every service running in launchd is cataloged in `migration-inventory.md`.

**Method.** Snapshot `launchctl list` filtered to Crumb/Tess/OpenClaw/Scout/FIF/Hermes labels. List `~/Library/LaunchAgents/` (51 plists) and `/Library/LaunchDaemons/` (1 relevant plist: `ai.openclaw.gateway`). Cross-reference against `migration-inventory.md` §Service Inventory (Categories A–I, 24 services + 2 cron jobs + 1 third-party).

**Deltas**

New in launchd, NOT in inventory (5):
| # | Service | Purpose | Proposed classification |
|---|---|---|---|
| 27 | `com.tess.nemotron-load` | Nemotron LLM model loader | KEEP (Category G) |
| 28 | `com.tess.llama-server` | Alternative LLM server | ASSESS — may supersede Ollama |
| 29 | `com.tess.soak-monitor` | Load testing / monitoring | ASSESS — purpose unclear |
| 30 | `com.crumb.vault-rebuild` | Vault rebuild tool | KEEP (Category G) |
| 31 | `com.crumb.vault-web` | Vault web API | KEEP (Category G) |

In inventory, NOT in launchd: none.

**Other anomalies flagged:**
- `com.scout.feedback-poller` showing exit 1 — investigate whether persistent or transient. (Feedback poller is the deferred-cutover service from IDQ-004.)
- `com.crumb.qmd-index` exit 127 — binary missing, as migration-inventory.md already flags with "assess — fix or drop."

**Recommended `migration-inventory.md` amendment (dated 2026-04-15):**
- Add 5 rows to Category G
- Update header: "30 managed services/jobs inventoried across 1 LaunchDaemon, 27 tess/crumb/scout/fif LaunchAgents, 1 danny LaunchAgent, and 2 OpenClaw cron jobs."

**Verdict:** ⚠ PASS-with-caveats — 5 uncataloged services pending classification; 2 existing services with known non-zero exits (scout-feedback-poller, qmd-index).

---

## 4. Gate Summary Matrix

Populated 2026-04-15 after Phases 1–4 complete. Phase 5 (re-collection) is gated on ≥48h fresh contract data post-TV2-056.

| # | Acceptance criterion | Verdict | Evidence § |
|---|---|---|---|
| 1 | Both platforms running ≥48h | ✓ | §1.2 (continuous since 2026-04-05 for Scout, earlier for others) |
| 2 | Comparison report per service | ✓ | §2 (15 blocks populated from run-history.db) |
| 3 | Cost ≤$75/month ceiling | ⏸ PENDING | §3.5 — `cost-tracker.yaml` not deployed (TV2-028 gap) |
| 4 | ≥70% routing at Tier 1+2 | ✓ (qualified) | §2 — 100% Tier 1 across all services; requires interrogation of router decision logic (§2 notes) |
| 5 | No missed outputs | ⚠ | §2 — 1 dead-letter + 1 zero-output for `overnight-research` in window; both explained by TV2-056 wrapper bugs + legitimate no-op nights. Post-TV2-056 re-collection needed. |
| 6 | Vault authority verified | ⚠ PASS-with-caveats | §3.1 — no write-path bypass, but promotion engine unintegrated (F3.1-1, cutover blocker) |
| 7 | Evaluator separation verified | ⚠ PASS-with-caveats | §3.2 — structural separation clean; F3.2-1 (integration gap compounds §3.1); F3.2-2 (no role-boundary guard) |
| 8 | State reconciliation | ✓ | §3.3 — no orphaned state, credentials clean. Follow-ups: unload OpenClaw email-triage plist; Phase 2 §2.3 vault-health "dormant" verdict corrected (was subagent epoch-conversion error) |
| 9 | Migration inventory re-audit | ⚠ PASS-with-caveats | §3.4 — 5 new services need cataloging; 2 existing have non-zero exits |

**Overall TV2-038 verdict:** **PASS-with-follow-ups** (after Phase 5 re-collection).

### Blockers for TV2-039 cutover

These must be resolved before production cutover, in priority order:

1. **F3.1-1 / F3.2-1 — Promotion engine integration.** `PromotionEngine.promote()` is never called from the CLI. Staged artifacts never reach canonical vault paths. TV2-039 cannot decommission OpenClaw while Tess v2 artifacts are stuck in `_staging/`. File a task to wire promotion into `cli.py _cmd_run` between Ralph loop end and run-history write.
2. **Phase 5 re-collection.** TV2-056 contract strengthening landed today; 48h of fresh contract data is needed before the per-service verdicts are authoritative. Gate Phase 5 on `~/.tess/state/run-history.db` MAX(started_at) − 48h > 2026-04-15T22:43Z (must-fix commit `02be7b7` landing time in UTC). **Corrected 2026-04-17:** prior draft listed the floor as `2026-04-15T18:00Z` — that calculation dropped the `-0400` offset from the 18:43 local-time landing. Phase 5 window fixed as `2026-04-15 23:00Z → 2026-04-17 23:00Z`.
3. **IDQ-004 Tess-side feedback-poller bootstrap.** Pre-staged. Must execute during TV2-039 cutover because Telegram `getUpdates` token is exclusive.
4. **Cost-tracker deployment (TV2-028).** Acceptance criterion 3 can't be verified without it. Either deploy before TV2-039 or explicitly accept the risk.

### Non-blocking follow-ups

- Unload OpenClaw `ai.openclaw.email-triage` plist (TV2-036 was cancelled 2026-04-10 but plist still loaded with exit 1 noise).
- Amend `migration-inventory.md` with 5 new service rows (Category G) + update header count.
- Investigate `com.scout.feedback-poller` exit 1 and `com.crumb.qmd-index` exit 127.
- Interrogate router decision logic: 100% Tier 1 is comfortably above the 70% bar but suggests either a correctly biased router or an always-local default. Worth a sanity check to distinguish.
- TV2-056 should-fix items deferred from code review: vault-gc `status:` field (ANT-F4), fif-feedback-health service-name asymmetry (ANT-F3), vault-gc timestamp quoting (ANT-F6).
- Phase 2 §2.3 wording referenced "last-run stale 13 days" — this was a subagent epoch-conversion error (1776233217 parsed as 2026-04-02 instead of 2026-04-15 02:06). Corrected in §3.3 A.3. Consider adding a subagent-validation step that flags numerical timestamps in outputs before acceptance.

---

## 5. Known Caveats

- **Scout feedback-poller** (service #12) runs only on OpenClaw pending IDQ-004 LaunchAgent bootstrap. Both-platform parity is deferred to TV2-039 cutover execution. Flag, not fail.
- **Scout feedback-health** (service #14) has no OpenClaw peer — it is a Tess-native contract health check. §2 block applies only the Tess v2 columns.
- **Bursty cost model.** Per `bursty-cost-model.md`, single-day cost spikes from storm events are expected and should not fail the pro-rated monthly ceiling unless sustained. Cost rollup should use a 14-day trailing average, not raw 48h extrapolation.

---

## 5.1 Phase 5 execution playbook (added 2026-04-17)

Run these queries at or after **2026-04-17 23:00Z** against `~/.tess/state/run-history.db`. Output feeds §2 service blocks and §3 cross-cutting. Class definitions are in §1.4.

### 5.1.1 Window constants

```
START = '2026-04-15T23:00:00'
END   = '2026-04-17T23:00:00'
```

### 5.1.2 Per-service outcome/tier breakdown (feeds §2 blocks)

```sql
SELECT service, outcome, COUNT(*) AS n,
       SUM(CASE WHEN final_tier=1 THEN 1 ELSE 0 END) AS tier1,
       SUM(CASE WHEN final_tier=2 THEN 1 ELSE 0 END) AS tier2,
       SUM(CASE WHEN final_tier=3 THEN 1 ELSE 0 END) AS tier3,
       SUM(escalated) AS escalations,
       MIN(started_at) AS first_run,
       MAX(started_at) AS last_run
FROM run_history
WHERE started_at >= '2026-04-15T23:00:00' AND started_at < '2026-04-17T23:00:00'
GROUP BY service, outcome
ORDER BY service, outcome;
```

### 5.1.3 Class-bifurcated success rate (feeds AC #5 verdict per service)

```sql
SELECT
  service,
  CASE
    WHEN service = 'daily-attention' THEN 'A'
    WHEN service IN ('awareness-check','backup-status','connections-brainstorm',
                     'email-triage','fif-attention','fif-capture','fif-feedback',
                     'health-ping','overnight-research','scout-daily-pipeline',
                     'scout-feedback','scout-weekly-heartbeat','vault-gc','vault-health') THEN 'C'
    ELSE '?'
  END AS class,
  COUNT(*) AS total_runs,
  SUM(CASE
    WHEN service = 'daily-attention'
         AND outcome='staged' THEN 1
    WHEN service IN ('awareness-check','backup-status','connections-brainstorm',
                     'email-triage','fif-attention','fif-capture','fif-feedback',
                     'health-ping','overnight-research','scout-daily-pipeline',
                     'scout-feedback','scout-weekly-heartbeat','vault-gc','vault-health')
         AND outcome IN ('staged','completed') THEN 1
    ELSE 0
  END) AS successes,
  SUM(CASE WHEN outcome='dead_letter' THEN 1 ELSE 0 END) AS dead_letters
FROM run_history
WHERE started_at >= '2026-04-15T23:00:00' AND started_at < '2026-04-17T23:00:00'
GROUP BY service
ORDER BY service;
```

### 5.1.4 Dead-letter detail (feeds AC #5 "missed outputs" investigation)

```sql
SELECT service, started_at, failure_class, dead_letter_reason, duration_ms
FROM run_history
WHERE started_at >= '2026-04-15T23:00:00' AND started_at < '2026-04-17T23:00:00'
  AND outcome='dead_letter'
ORDER BY started_at;
```

### 5.1.5 Tier routing rollup (feeds AC #4)

```sql
SELECT COUNT(*) AS total_contracts,
       SUM(CASE WHEN final_tier IN (1,2) THEN 1 ELSE 0 END) AS tier_1_or_2,
       ROUND(100.0*SUM(CASE WHEN final_tier IN (1,2) THEN 1 ELSE 0 END)/COUNT(*), 1) AS pct,
       SUM(escalated) AS escalations
FROM run_history
WHERE started_at >= '2026-04-15T23:00:00' AND started_at < '2026-04-17T23:00:00';
```

### 5.1.6 Cadence expectation matrix (for each §2 block)

| Service | Class | Cadence | Expected runs/48h |
|---|---|---|---|
| health-ping | C | 900s | ~192 |
| backup-status | C | 900s | ~192 |
| fif-feedback | C | 900s | ~192 |
| scout-feedback | C | 900s | ~192 |
| awareness-check | C | 1800s | ~96 |
| daily-attention | A | 1800s | ~96 |
| vault-health | C [was A pre-057b] | daily 02:00 | 2 |
| vault-gc | C | daily 04:00 | 2 |
| fif-capture | C | daily 06:05 | 2 |
| fif-attention | C | daily 07:05 | 2 |
| overnight-research | C | daily 23:00 | 2 |
| scout-daily-pipeline | C | daily 07:00 (runs ~11:xx) | 2 |
| connections-brainstorm | C [was A pre-057b] | daily 86400s | 2 |
| scout-weekly-heartbeat | C | weekly Monday (+ dry-run non-Mondays) | 2 (dry-runs Wed+Thu in window) |
| scout-feedback-health | — | 900s | ~192 |
| email-triage | C | (cancelled 2026-04-10 but still running — §3.3) | 0 ideal, non-zero = reconciliation gap |

### 5.1.7 State reconciliation probe (feeds §3.3)

```sql
SELECT service, COUNT(*) AS runs_after_cancellation
FROM run_history
WHERE service='email-triage' AND started_at >= '2026-04-10T00:00:00'
GROUP BY service;
```

Any non-zero result confirms §3.3 A.2 reconciliation gap is still open.

### 5.1.8 Acceptance procedure

1. Run 5.1.2 → 5.1.5. Copy each service's numbers into its §2 block under "Phase 5 update" notes (don't overwrite Phase 2 numbers — append).
2. Compute AC #5 verdict per service: successes == total_runs − dead_letters (class-bifurcated).
3. If 5.1.4 returns rows, investigate each dead-letter; note whether TV2-056-adjacent or new.
4. Update §4 gate matrix row-by-row if any verdict changes from Phase 2.
5. Close Phase 6 row `5 | pending → done | 2026-04-17` and lift the TV2-057a backfill hold in the runbook.

---

## 6. Phase Tracking

| Phase | Deliverable | Status | Completed |
|---|---|---|---|
| 1 | Methodology doc (this file) | done | 2026-04-15 |
| 2 | Per-service data collection (initial pass, using run-history.db authoritative source) | done | 2026-04-15 |
| 2a | **TV2-056 discovered mid-Phase-2:** stale-artifact contract bug; new task created, wrappers + contracts remediated | done | 2026-04-15 |
| 3 | Cross-cutting verification (§3.1–3.3 + §3.5 cost gap) | done | 2026-04-15 |
| 4 | Migration inventory re-audit (§3.4) | done | 2026-04-15 |
| 5 | Phase 2 re-collection post-TV2-056 + final gate verdict confirmation | pending | gated on ≥48h of fresh contract data; earliest **2026-04-17 23:00Z** (48h after must-fix commit `02be7b7` at 2026-04-15 22:43Z, rounded to whole hour) |
