---
project: tess-v2
type: design-artifact
domain: software
status: draft
created: 2026-04-15
updated: 2026-04-15
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

### 3.1 Vault authority (AD-001)

**Claim.** No Tess v2 write path bypasses the staging-to-canonical promotion gate for vault artifacts.

**Method.**
- Grep Tess v2 source (`/Users/tess/crumb-apps/tess-v2/`) for direct writes to `/Users/tess/crumb-vault/` paths that are **not** under `_staging/`, `_tess/logs/` (symlinked to `~/.tess/logs/`), `_system/daily/` (orchestrator-authored), or dispatch-allowed paths.
- Cross-check against `staging-promotion-design.md` §4 (promotion gates).
- Sample the last 10 promotion.log entries; verify each promotion has a staging source and hash match.

**Evidence sources:** Tess v2 source tree, `~/.tess/logs/promotion.log`, `_staging/*/execution-log.yaml`.

**Result:** ✓ / ✗ + evidence summary.

### 3.2 Evaluator separation

**Claim.** Executor agents cannot self-promote — only the promotion gate, invoked by Tess orchestrator after contract verification, moves artifacts from `_staging/` to final vault paths.

**Method.**
- Review agent system prompts and permission configs for explicit deny on direct vault writes outside staging.
- Verify promotion gate is invoked by a distinct role (orchestrator or promotion daemon), not by the executor agent itself.
- Inspect a sample of 5 recent contracts from the ledger: confirm the `promote` step was executed by the orchestrator, not the contract executor.

**Evidence sources:** Tess v2 agent configs, `service-interfaces.md` §4 (role boundaries), `contract-ledger.yaml` sample entries.

**Result:** ✓ / ✗ + evidence summary.

### 3.3 State reconciliation

**Claim.** No orphaned jobs, state artifacts, or credential gaps exist between OpenClaw and Tess v2.

**Method.**
- **Orphaned jobs:** `launchctl list` diff against `migration-inventory.md` — any running service not in the inventory is flagged.
- **Orphaned state:** Enumerate `_openclaw/state/*` and `_openclaw/data/*` files. For each, verify classification (keep / migrate / drop) and that migrated state has a Tess v2 equivalent at `~/.tess/state/` or `_tess/`.
- **Credential gaps:** Walk the 22+ credential inventory from `migration-inventory.md` §Credential Inventory. For each, verify: (a) present in Keychain OR in an approved credential file with correct chmod; (b) referenced by at least one live Tess v2 service or plist; (c) not duplicated between OpenClaw and Tess v2 paths (risk of drift).
- **`last-run/` comparison:** Compare OpenClaw `_openclaw/state/last-run/` timestamps against Tess v2 `~/.tess/state/last-run/` (or equivalent). Any OpenClaw service still writing while its Tess v2 peer is not = reverse-migration risk.

**Evidence sources:** `launchctl list`, `/Library/LaunchDaemons/`, `~/Library/LaunchAgents/`, `_openclaw/state/`, `~/.tess/state/`, Keychain (`security find-generic-password`).

**Result:** ✓ / ✗ + enumerated findings.

### 3.4 Migration inventory re-audit

**Claim.** Every service running in launchd (LaunchAgent or LaunchDaemon) is cataloged in `migration-inventory.md` with an explicit classification (migrate / rebuild / replace / keep / drop / assess).

**Method.**
- Snapshot current `launchctl list` (user + root domains).
- Diff against the 24 services in `migration-inventory.md` §Service Inventory.
- For each delta:
  - **New in launchd, not in inventory:** catalog and classify. Either create a migration task (backlog for future phase) or explicitly defer with reason.
  - **In inventory, not in launchd:** mark as decommissioned or investigate.
- Update `migration-inventory.md` with an amendment section dated 2026-04-15 listing additions and reclassifications.

**Evidence sources:** `launchctl list`, `migration-inventory.md`.

**Result:** ✓ / ✗ + delta list with classifications.

---

## 4. Gate Summary Matrix

Final section of the report — populated after Phases 2–4 complete.

| Acceptance criterion | Verdict | Evidence § |
|---|---|---|
| 1. Both platforms running ≥48h | ✓ / ✗ | §1.2 |
| 2. Comparison report per service | ✓ / ✗ | §2 (15 blocks) |
| 3. Cost ≤$75/month ceiling | ✓ / ✗ | §2 per-service rollup |
| 4. ≥70% routing at Tier 1+2 | ✓ / ✗ | §2 per-service rollup |
| 5. No missed outputs | ✓ / ✗ | §2 per-service |
| 6. Vault authority verified | ✓ / ✗ | §3.1 |
| 7. Evaluator separation verified | ✓ / ✗ | §3.2 |
| 8. State reconciliation | ✓ / ✗ | §3.3 |
| 9. Migration inventory re-audit | ✓ / ✗ | §3.4 |

**Overall TV2-038 verdict:** PASS / PASS-with-follow-ups / FAIL.

If PASS-with-follow-ups: enumerate non-blocking findings that TV2-039 cutover decision must address. If FAIL: enumerate blockers and proposed remediation path.

---

## 5. Known Caveats

- **Scout feedback-poller** (service #12) runs only on OpenClaw pending IDQ-004 LaunchAgent bootstrap. Both-platform parity is deferred to TV2-039 cutover execution. Flag, not fail.
- **Scout feedback-health** (service #14) has no OpenClaw peer — it is a Tess-native contract health check. §2 block applies only the Tess v2 columns.
- **Bursty cost model.** Per `bursty-cost-model.md`, single-day cost spikes from storm events are expected and should not fail the pro-rated monthly ceiling unless sustained. Cost rollup should use a 14-day trailing average, not raw 48h extrapolation.

---

## 6. Phase Tracking

| Phase | Deliverable | Status | Completed |
|---|---|---|---|
| 1 | Methodology doc (this file) | done | 2026-04-15 |
| 2 | Per-service data collection (initial pass, using run-history.db authoritative source) | done | 2026-04-15 |
| 2a | **TV2-056 discovered mid-Phase-2:** stale-artifact contract bug; new task created, wrappers + contracts remediated | done | 2026-04-15 |
| 3 | Cross-cutting verification (§3.1–3.3) | pending | — |
| 4 | Migration inventory re-audit (§3.4) | pending | — |
| 5 | Phase 2 re-collection post-TV2-056 + Gate summary (§4) + TV2-038 verdict | pending | gated on ≥48h of fresh contract data post-2026-04-15 wrapper deployment |
