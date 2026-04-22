---
project: tess-v2
type: run-log
period: 2026-04 onwards
created: 2026-04-10
updated: 2026-04-20
---

## 2026-04-20 — Kimi K2.6 TV2-Cloud eval battery

**Context loaded:** project-state.yaml, tv2_cloud_eval.py (MODELS/scoring), tv2-cloud-eval-spec.md (rubric), tess-voice-prompt.md (persona source), prior K2.5 results (kimi-20260403-124715.json), memory `model-kimi-recovery-fabrication.md`. Sub-8 source docs.

### Purpose

Evaluate newly-released Moonshot AI Kimi K2.6 (released 2026-04-13) as a candidate Tess voice/orchestration runtime. Re-test the K2.5 recovery-failure fabrication pattern against K2.6 on the cloud battery. Compare latency, throughput, and quality vs incumbent K2.5.

### Work

1. **K2.6 web lookup** — confirmed release on 2026-04-13, OpenRouter slug `moonshotai/kimi-k2.6`, pricing $0.95/$4 per M tokens (~2× K2.5).
2. **Registered K2.6** in `tv2_cloud_eval.py` as model key `kimi26` (ID C12).
3. **Persona-spec reconstruction** — `_inbox/tess-persona-spec.md` (the hardcoded path in `load_persona_spec()`) was missing. Never committed to git — always an ephemeral artifact. Reconstructed verbatim from `Archived/Projects/tess-model-architecture/design/tess-voice-prompt.md` (compressed ~1,090-token system prompt).
4. **Full battery run** — 10 tests (TC-01…TC-10), 194,679 tokens, estimated cost $0.454. Raw results: `eval-results/kimi26-20260420-142211.json`.
5. **Auto-metrics:** TTFT p50 11.0s (K2.5: 26.5s, −58%); TTFT p95 26.2s (K2.5: 98.0s, −73%); throughput p50 60.2 tps (K2.5: 43.6, +38%); TC-07 structured output 5/5 valid.
6. **Spot-check on fabrication-prone paths (TC-04, TC-09):** K2.6 passed 10/10 tool-decision turns and 5/5 error-recovery scenarios with zero fabrication. Critically, TC-09 scenario 2 (`unexpected_empty_result` — the exact K2.5 stressor) produced categorical debugging instead of K2.5's invented tag-variants with false recall.
7. **Full qualitative scoring (subagent-dispatched)** → `eval-results/cloud-eval-results-kimi26-2026-04-20.md`. Verified subagent claims against raw JSON (TC-05 reasoning, K2.5 fabrication quote).

### Results

- **Weighted score: 87/100** (qualified strong candidate per spec §5.1)
- **Fabrications: 0**
- **Per-test:** TC-01 5 · TC-02 5 · TC-03 5 · TC-04 5 · TC-05 **2** · TC-06 5 · TC-07 5 · TC-08 **1** · TC-09 5 · TC-10 5
- **Threshold misses:** TC-05 only (needs ≥3). Rubric artifact — K2.6 refused multi-step execution without tool access (the correct Tess behavior), which the current rubric penalizes. Turn 2 (AKM archive) actually produced a 3-step playbook — the refusal framing fooled the rubric.
- **vs K2.5:** K2.5 re-scored on current rubric ≈ 93/100. K2.6 is −6 points, entirely from TC-05. Latency, throughput, fabrication resistance all improved.

### Decision

- **AD-008 (K2.5 in production) holds.** Do not swap on this eval alone.
- **Next gate:** live Hermes soak test with K2.6 before promotion — the synthesized TC-09 scenarios are a strong signal but not equivalent to a live tool-loop stressor per the `model-kimi-recovery-fabrication.md` protocol gap.

### Compound observations

1. **The persona-spec fixture has no durable home.** The eval loads from `_inbox/tess-persona-spec.md` — an ephemeral location that was cleared between runs. Reconstructing from the archived `tess-voice-prompt.md` worked this time because the source was frozen, but this is a reproducibility hazard: if the archived source changes or is lost, we can no longer re-score historical runs consistently. Follow-up: move to `_system/docs/tess-persona-spec.md` and update `PERSONA_SPEC_PATH` in the script — needs a spec note that frontmatter must not be present (or have the loader strip it).
2. **Current rubric penalizes correct Tess behavior (TC-05).** The pattern has now surfaced twice (K2.5 2026-04-08 frontier survey, K2.6 today) — the multi-step orchestration test rewards a model for *pretending to execute* tool chains it doesn't have access to, which is the opposite of what Tess should do under Cardinal Rules / "don't bluff capabilities." Rubric needs a structural revision for TC-05: score on whether the model produces a correct decomposition (even if delegated to the operator), not on whether it performs the full chain. Until revised, TC-05 scores are noise for any model that respects tool boundaries.
3. **K2.5 fabrication under empty-tool-result is not universal — K2.6 explicitly marks categorical causes.** Comparing the two responses to the same prompt: K2.5 asserts "I've seen your tagging drift between formats" (false memory) and invents specific tag variants (`#security/kb`, `#kb-security`); K2.6 lists cause *categories* (tag mismatch / term variance / index lag) and asks for operator direction. The behavioral gap is voice + epistemic humility, not raw capability. Worth naming as a pattern: "fabrication risk scales with claimed-memory phrasing ('I've seen') more than with missing evidence." Route to `model-kimi-recovery-fabrication.md` memory as a K2.6 data point.

### Open / next (carry forward)

- **Live Hermes soak test** — K2.6 under real Tess runtime with real tool loops. Required before AD-008 swap.
- **Persona-spec durable location** — move out of `_inbox/`, update script path.
- **TC-05 rubric revision** — score decomposition correctness, not execution.
- Unchanged from prior: Z canonicalization (A8+A10), Amendment AC dispatch-interlock, vault-standards.md consolidation, TV2-057d migration.

### Model routing

Eval-analysis session — Opus 4.7 session default throughout. One subagent dispatched to general-purpose agent for qualitative scoring (94K tokens, 17 tool uses). Subagent output verified against raw JSON before acceptance. Delegation justified: JSON size (71KB) + rubric application would have consumed main-session context without value.

---

## 2026-04-19 — Post-deploy status check (TV2-057c) + snapshot cleanup

**Context loaded:** project-state.yaml, run-log.md 2026-04-18 entry (TV2-057a/b/c landing). Sub-5 source docs.

### Purpose

Two low-cost checks proposed at session start, per operator direction: (1) verify TV2-057c lock path is healthy in production after ~29h live, (2) determine eligibility of pre-backfill snapshot cleanup per runbook §3.9 ("earliest 2026-04-19 after clean post-backfill day").

### Post-deploy observation (TV2-057c, ~29h live)

Window: 2026-04-18T21:00:00Z → 2026-04-19T15:50:18Z (~18.5h since 04-18 session-end checkpoint).

- **Z4 candidates directory** (`~/.tess/state/z4-candidates/`): does not exist → `record_lock_deny` has never fired → zero lock contention since deploy.
- **`~/.tess/state/write-locks.db`**: `write_locks` table present, zero rows → no stale locks, no in-flight locks at check time.
- **daily-attention** (Class A, sole exerciser of the lock path): 38 `staged` rows over 18.5h. Expected at 30-min cadence: ~37. One extra row attributable to boundary timing. Min=21:20:10Z, max=15:50:18Z. All `staged`, none `dead_letter`/`escalated`. **Clean.**
- **All 14 other services in window:** `completed` only. Per-service counts match expected cadence (awareness-check 38, backup-status 75, fif-feedback 76, health-ping 75, scout-feedback 76; Class C singletons 1 each). No `dead_letter`, no `escalated`, no exit-75 evidence (which by design writes no history row but also triggers no anomaly).

**Verdict:** TV2-057c lock acquisition path silently working. Acquire + release on every daily-attention tick, no contention, no zombie locks, no Z4 marker production. The foundational layer held up under 29h of live traffic without operator intervention.

### Snapshot cleanup

- Runbook §3.9 authorized deletion "earliest 2026-04-19 after a clean post-backfill day." Post-backfill day (04-18 → 04-19) is clean per above.
- Operator confirmed. Deleted `~/.tess/state/run-history.db.pre-tv2-057a-backfill` (1.88 MB, 2026-04-18 10:18Z).

### State updates

- `project-state.yaml`: `updated: 2026-04-19`.
- No task state changes — TV2-057c already `done`, active_task remains TV2-057d.

### Compound observations

1. **"Silent success" is a real outcome that needs to be named.** The Z4 candidates directory's non-existence is a signal. So is the empty write-locks table. The natural reflex is "nothing to report → no log entry," but that's backwards: the lock architecture's first 29h of production is exactly when a failure would be most diagnostic. Logging the clean-state verification creates a dated baseline — next time we observe contention, we'll be able to grep for "when did this start" with a reference point.
2. **Exit-75's design choice (no history row) is the right tradeoff for status-check UX.** It keeps the outcome column clean: `daily-attention|staged|38` — a single pure line. An exit-75-writes-a-row design would have given us `daily-attention|staged|38` + `daily-attention|lock-denied|0` and invited operator confusion about whether the zero was meaningful. The Z4 marker directory + startup-hook visibility is doing the visibility job instead, and the absence of that directory is itself the clean signal.
3. **Runbook §3.9 with explicit-date authorization paid off.** Runbook pre-authorized snapshot deletion with a date predicate ("earliest 2026-04-19 after clean post-backfill day"). No new operator deliberation required, just re-verification of the precondition. This is cheap to write during runbook authoring and saves a full decision cycle later. Pattern worth reusing: destructive-but-recoverable operations in runbooks should specify an earliest-date + precondition rather than "after some soak period."

### Open / next (unchanged)

- **2026-04-20:** Z canonicalization (A8 + A10) → accepted; Amendment AC (dispatch-interlock).
- **2026-04-20→23:** vault-standards.md consolidation + 4-model peer review.
- **2026-04-25:** Amendment AD (promotion gate).
- **2026-04-26:** vault-check.sh `--file` mode.
- **2026-04-27→28+:** TV2-057d daily-attention migration.

### Model routing

Status-check session, low reasoning load. Opus 4.7 session default used throughout — no skill invocations, no subagent delegation warranted.

---

## 2026-04-18 — Phase 5 close + TV2-057a backfill execution

**Context loaded:** project-state.yaml, run-log.md 2026-04-17 entry (Phase 5 prep + TV2-057b landing), tasks.md TV2-057 rows, tv2-038-validation-report.md §5.1 playbook, tv2-057a-backfill-runbook.md (full). Sub-10 source docs.

### Verification that scheduled 23:00Z 2026-04-17 work did not execute

Operator asked whether Phase 5 SQL playbook + TV2-057a backfill ran overnight per yesterday's locked build plan. Checked: (a) no commits in either repo after `461ffb6` at session end 2026-04-17, (b) no Phase 5 output artifact written, (c) `run_history.db` outcome distribution at session start showed 6637 staged / 1169 completed — pre-backfill state. Verdict: neither ran. Good news: Phase 5 window `2026-04-15T23:00:00 → 2026-04-17T23:00:00` is sealed and complete; queries could be run now against a fixed window with no timing considerations.

### Phase 5 execution (§5.1 playbook)

Ran 5.1.2 (per-service outcome/tier breakdown), 5.1.3 (class-bifurcated success), 5.1.4 (dead-letter detail), 5.1.5 (tier routing rollup), 5.1.7 (state reconciliation probe). Skipped 5.1.6 (cadence was eyeballed against 5.1.2 output — no drift).

**Verdict: PASS.**
- **AC #4** Tier 1+2 routing: 100.0% (1054/1054; 12 escalations from `test` service only). Threshold ≥70%.
- **AC #5** Class-bifurcated success: 15/15 services satisfy successes == total − dead_letters.
- **Cadence:** health-ping 192/192, awareness-check 96/96, daily-attention 96/96, fif-feedback 192/192, scout-feedback 192/192, backup-status 191/192. Actually clean — yesterday's "~87%" figure was from the partial window preview, full window shows tight cadence.
- **Dead letters in window:** 1 row — vault-health @ 2026-04-16T06:27Z, `bad_spec` semantic failure, 870s. Matches pre-existing project-state "awaiting revalidation" item; not a TV2-056 regression, does not block gate.
- **Reconciliation gap:** email-triage 282 runs after 2026-04-10 cancellation — known §3.3 A.2 open item, unchanged.
- **Pre-TV2-057a stragglers in window:** Class C services show ~3-8 `staged` rows each from 2026-04-15 23:00→2026-04-16 00:30Z, all before `bd0482a` went live mid-2026-04-16. Post-057a all Class C lands `completed`. Class-bifurcated success counts both for Class C, so no verdict impact. Backfill retroactively flips these.

**Option B chosen (operator-directed):** condensed §5.2 verdict block added to `tv2-038-validation-report.md` (not per-service §2 updates). Phase 6 row 5 closed: pending → done 2026-04-18. Backfill hold lifted in runbook frontmatter (status: held → released) + §1 header note rewritten.

### TV2-057a backfill execution (runbook §3)

Per-step execution:
- **§3.1 Prereq:** Verified `037c363 TV2-057a: historical backfill script + runbook (held)` in `~/crumb-apps/tess-v2` git log. Phase 5 closure verified via my own §5.1 run above (runbook's `grep -A2 "phase: 5" ~/crumb-vault/Projects/tess-v2/staging/TV2-038/*.yaml` check is a convention — authoritative source is validation-report §6).
- **§3.2 Snapshot:** `~/.tess/state/run-history.db.pre-tv2-057a-backfill` = 1884160 bytes (matches live).
- **§3.3 Dry-run on copy:** 5836 rows across 14 Class C services (awareness-check 644, backup-status 1181, connections-brainstorm 15, email-triage 441, fif-attention 13, fif-capture 13, fif-feedback 1194, health-ping 1282, overnight-research 11, scout-daily-pipeline 10, scout-feedback 992, scout-weekly-heartbeat 13, vault-gc 13, vault-health 14).
- **§3.4 Execute on copy + verify:** staged 6637 → 801, completed 1169 → 7006 (+1 natural drift between queries). Sentinel count 5836. `daily-attention` absent from "completed" query ✓ (only Class A). ✓
- **§3.5 Stop services:** `launchctl unload ~/Library/LaunchAgents/com.tess.v2.*.plist` → 15 → 0 loaded. 30s wait.
- **§3.6 Live execute:** `scripts/tv2_057a_backfill.py --execute` → Updated 5836 rows.
- **§3.7 Restart:** `launchctl load ...` → 0 → 15 loaded. ✓
- **§3.8 Final verify:** live DB now `staged=802, completed=7012, dead_letter=88, escalated=40`. Sentinel count 5836. `daily-attention` 722 staged / 0 completed ✓.

**Before/after (live):** staged 6637 → 802, completed 1169 → 7012. 8 rows of natural drift accumulated between Phase 5 queries and final verify (total 7934 → 7942), consistent with ~30 min of elapsed service activity minus the ~30s unload window.

### State updates

- `tasks.md`: TV2-057a `in_progress` → `done` with full close-out summary. TV2-057b `todo` → `done` (landed 2026-04-17 per prior run-log entry; row had been stale).
- `project-state.yaml`: active_task TV2-057a → TV2-057c; `updated: 2026-04-18`; `next_action` rewritten to reflect 057a/057b close + forward build plan.
- `tv2-038-validation-report.md`: §5.2 verdict block added, §6 Phase Tracking row 5 closed.
- `tv2-057a-backfill-runbook.md`: frontmatter `status: released`, § header note rewritten (HELD → RELEASED 2026-04-18 with Phase 5 PASS reference).

### Compound observations

1. **"Scheduled for overnight" ≠ "will happen overnight" without an agent.** Yesterday's build plan listed 23:00Z 2026-04-17 Phase 5 execution as if it were scheduled. It wasn't — it was a note that said "earliest safe execution is this time." With nothing and no one to trigger it, nothing ran. Not surprising in hindsight; worth flagging. Future: when the build plan says "X at time T," either (a) commit a LaunchAgent/cron to run it, or (b) write "next session ≥T: run X" to avoid ambiguity. This is the Tess Phase B (interactive dispatch) value proposition restated from a different angle — the operator-orchestration burden applies to one-shot scheduled tasks too, not just project-level phase transitions.
2. **Phase 5 playbook + sealed-window approach paid off.** Yesterday's decision to codify the §5.1 playbook with explicit window constants meant today's execution was mechanical: paste queries, collect results, verdict. No interpretation drift. The window was 24h stale by time of run and results identical to what they'd have been at 23:00Z — which is the point of a sealed window. This is a durable pattern: when gating a decision on a time-bounded data collection, define the window so it's the SAME answer whenever you run it after the window closes.
3. **Sentinel-based reversible migration worked exactly as designed.** Backfill copy-test-execute-verify took ~10 min end-to-end, no anxiety. The `dead_letter_reason='tv2-057a-backfill'` sentinel is the kind of small discipline that pays compounding dividends: if we later discover a bug in the classifier, rollback is one SQL statement, no backup-restore.
4. **Class A `daily-attention` drift to 722 staged is the next demand signal for TV2-057c + 057d.** It means there are now 722 rows that can't advance from `staged` until lock acquisition + promotion wiring exist. Every cadence cycle adds ~48/day. Not urgent, but the queue is growing visibly — useful psychological pressure against deferring 057c.

### Part 2 — TV2-057c implementation

Continued same session. Operator approved four decision points with additions:
- **D1 (resolver method):** (b) + explicit `now: datetime` parameter — no internal `datetime.now()` call. Reason: tests pin time without monkey-patching; lock-acquire and promotion resolution must agree on the same value, preventing 23:59:59 → 00:00:01 date-rollover edge cases.
- **D2 (N threshold):** N=5 uniform as a named constant (`CONSECUTIVE_DENY_THRESHOLD`). Ceremony-budget rationale: one Class A service right now, no demand for per-service config; grep-able + tunable when a second Class A service needs different.
- **D3 (JSON + atomic write):** write-to-temp + `os.replace` for crash-safety. Concurrent undercount race named in tests as known-acceptable (not worth file-locking to prevent; worst case = Z4 marker fires one cadence late).
- **D4 (markers + startup-hook visibility):** z4-candidates dir read by `session-startup.sh` on every session open, count + service list surfaced in the formatted Startup Summary. Closes the Phase-A-to-Phase-B visibility gap (markers would otherwise be invisible until Phase B lands 2026-04-21+).

Additional scope added by operator:
- **Release-failure test** — lock release raising in `finally` must log ERROR to stderr but NOT affect `_cmd_run` return code. Zombie lock becomes visible as a deny on next invocation (existing mechanism).
- **STAGED-is-success comment** — code comment explaining that post-Amendment-AB, both STAGED (Class A awaiting promotion) and COMPLETED (Class C side-effect) are success outcomes, so `return 0` on either isn't a mistake.

**Files changed (code repo):**
- `src/tess/contract.py` — module-level `datetime` import; `CanonicalOutput.resolve(now)` method with `{date}`/`{week}`/`{timestamp}` substitution + explicit-now docstring.
- `src/tess/lock_deny.py` — **NEW.** 148 lines. `record_lock_deny`, `reset_lock_deny_count`, `list_z4_candidates`, atomic-write JSON, self-healing on corrupt counter file, candidate marker generation at threshold.
- `src/tess/cli.py` — module-level `datetime/timezone` import; `EXIT_LOCK_DENIED=75` constant; acquire/release wiring in `_cmd_run` with Class A gate via `is_side_effect_contract`; `try/finally` release discipline; release-failure logged but swallowed; STAGED-is-success comment.
- `tests/test_contract.py` — `TestCanonicalOutputResolve` (6 tests: date, week, timestamp, no-placeholder, multiple, explicit-now-not-datetime-now sentinel).
- `tests/test_lock_deny.py` — **NEW.** `TestRecordLockDeny` (7), `TestResetLockDenyCount` (4), `TestListZ4Candidates` (2), `TestAtomicWriteAndRaces` (3 — including race-behavior-documented sentinel).
- `tests/test_cli.py` — `TestLockAcquisitionClassA` (4 — acquire + release on STAGED/ESCALATED/exception), `TestLockAcquisitionClassC` (1 — skip lock entirely), `TestLockDenied` (5 — exit 75, no history row, stderr diagnostic, counter increment, reset-on-success), `TestLockReleaseFailure` (1), `TestConcurrentContention` (1 — real `WriteLockTable` integration test with held lock by another contract).

**Files changed (vault):**
- `_system/scripts/session-startup.sh` — Z4 candidates scan of `~/.tess/state/z4-candidates/` + startup-summary line when count > 0.

**Test result:** 509/509 pass (475 baseline + 34 new). Startup hook manually verified: displays `- **Lock-deny candidates:** 1 (daily-attention) — persistent write-lock contention, investigate` when marker present.

**Deploy mechanics:** services invoke `.venv/bin/python -m tess run` via `scripts/dispatch.sh`. Code changes take effect on next service tick — no reinstall needed. No `launchctl` cycle required. `~/.tess/state/write-locks.db` verified empty before deploy (no stale rows). Daily-attention's `canonical_outputs` field is already present in production contract (landed 2026-04-17 via TV2-057b); next 30-min-cadence tick will be the first live exercise of the lock path.

### Open / next (updated)

- **Deployment observation:** next daily-attention tick after session end will be the first production lock acquire. No action required unless a deny surfaces (marker at 5 consecutive).
- **2026-04-20:** Z canonicalization (A8 + A10 reconciliation) + Amendment AC (dispatch-interlock fail-closed on registry desync).
- **2026-04-20→23:** vault-standards.md consolidation + 4-model peer review.
- **2026-04-25:** Amendment AD (promotion gate).
- **2026-04-26:** vault-check.sh `--file` mode.
- **2026-04-27→28+:** TV2-057d daily-attention migration — first Class A to get promotion wiring + cutover from direct-to-canonical write.
- **Code review:** TV2-057b and TV2-057c deliberately landed without formal review per 2026-04-17 decision ("single review pass covers both landings"). Decision deferred to operator: run code review now, batch with TV2-057d, or defer to pre-cutover gate.
- **Housekeeping:** delete pre-backfill snapshot after clean post-backfill day (earliest 2026-04-19).

### Compound observations (Part 2)

6. **Explicit-now parameter is a cheap durable pattern.** Saved as the cleanest seam for TV2-057d without any speculative abstraction. The hypothetical 23:59:59→00:00:01 date-rollover bug it prevents is exactly the kind of rare-but-catastrophic defect that's impossible to debug after the fact — the only surface would be "sometimes a lock was acquired for today but the promotion landed on yesterday's file." Cheap to add now; expensive to retrofit after a production incident.
7. **Ceremony-budget discipline on N=5.** Easy to have over-engineered this into a per-service config with override files and documentation. The actual system today has exactly one Class A service. A named constant is right-sized; when a second Class A service wants a different value, the grep cost is ~15 seconds and the refactor is one line. Resisting speculative configurability is itself a skill worth naming.
8. **Known-acceptable race test as behavior lock-in.** `test_known_acceptable_race_undercount_documented` doesn't actually test the race — it asserts nothing meaningful. But its *presence* in the test suite forces anyone introducing file-locking on the counter to remove the test, which surfaces the decision. Documentation via test is a cheap way to make a design tradeoff visible to future contributors who'd otherwise "fix" it.
9. **Startup-hook visibility is a rendezvous mechanism.** The z4-candidates directory is a poor man's pub/sub: producer (`_cmd_run`) writes markers on bad days, consumer (startup hook) surfaces on every session. Operators see persistent contention without having to remember to look. Phase B will subsume the reading, but the directory itself is the durable contract. Future lesson: when building state that multiple consumers need to observe, a file-system directory of small markers is often cheaper than a queue or a dashboard.
10. **Milestone batching pays off in test volume.** TV2-057b + 057c combined: 34 new tests covering a layered system (schema, classifier, lock table, counter, CLI integration, startup hook). Each layer is small; the composition catches the cross-layer bugs (e.g. the CLI test that patches `tess.cli.datetime` failing because `datetime` was a function-local import — a real bug the test caught before deploy). Large test suites on small surface area reveal composition bugs better than small test suites on large surface area.

### Code Review — milestone TV2-057b/c

- **Scope:** commits `f336ae9..e9175ba` (TV2-057b canonical_outputs + TV2-057c write-lock acquisition); 12 files, +1341/−58.
- **Panel:** Claude Opus 4.6 (17 findings), Codex GPT-5.3-Codex (9 findings).
- **Signals:** data/schema.
- **Codex tools:** **skipped** — Codex's shell tools landed in the vault cwd instead of the tess-v2 repo (dispatch-agent `cwd=` plumbing issue); review grounded in inlined diff only. Logged as separate improvement item for next review cycle.
- **Findings:** 0 CRITICAL, 6 SIGNIFICANT, 5 MINOR, 4 STRENGTH.
- **Consensus:** 5 directly converging findings (lock-leak window, credential-sourcing in out-of-scope shell script, corrupt-counter self-heal, int/float coercion, no-op sentinel test).
- **Clusters:** 1 systemic — `_cmd_run` lock-lifecycle error handling (3 findings → single `locks_acquired` flag fix).
- **Contradictions:** 1 — schema-version gating policy (Opus: backward-compat preserved; Codex: forward-compat concern). Resolved operator-side via A4 (additive-forward-compat documented).
- **Action:** Option 2 chosen (must-fix + should-fix). Applied A-S1, A1, A2, A3, A4, A5, A6, A7. Deferred A8/A9/A10 (trivia); declined F6 (atomic-write crash window, acceptable at personal scale); A12 (shell script credential sourcing) filed as out-of-scope IDQ-004 follow-up.
- **Tests:** +9 (resolve assertion fires; corruption warnings emitted; bool/float values dropped; acquire raises → no release; record_lock_deny raises → still returns 75; reset_lock_deny_count raises → Ralph still runs). Suite 509 → 518/518.
- **Review note:** `Projects/tess-v2/reviews/2026-04-18-code-review-milestone-tv2-057bc.md`
- **Reviewed commit tagged:** `code-review-2026-04-18` on `e9175ba`.
- **Response commit:** `2bf1ad5` (tess-v2 repo).

### Compound observations (Part 3 — code review)

11. **Codex cwd-plumbing bug in dispatch agent is a genuine capability regression.** The dispatch agent passed `repo_path` but Codex's shell tools didn't inherit it, so `pytest` and type-check never ran. Convergence with Opus was still strong enough for useful signal (5 direct matches + 2 unique-to-Codex signals), but the tool-grounding advantage was lost this cycle. File-level impact: next code-review skill invocation should first fix the dispatch-agent cwd propagation (likely a `subprocess.run(cwd=repo_path)` fix). Track in `_system/docs/solutions/` as a code-review-infrastructure pattern worth naming — if Codex's tool-grounding is frequently degraded, the "two reviewers with complementary strengths" framing weakens to "two reviewers, one degraded."
12. **Systemic clustering catches the real structural bug.** Three findings (F4, CDX-F1, CDX-F2) each described a distinct lock-leak or R2-violation path. Addressed individually, the fix would have been three separate try/excepts. Addressed as a cluster, the fix is one `locks_acquired` flag + two narrow try/excepts around bookkeeping calls — structurally cleaner, less code, easier to reason about. The skill's Step 7b cluster analysis was the mechanism that found this; without it, three individual action items would have been landed separately.
13. **Contradiction detection is a real two-reviewer value-add.** Opus F8 and Codex CDX-F3 looked at the same code and drew opposite conclusions (backward-compat preserved vs forward-compat-concern). Both were factually correct; the reviewers surfaced a policy question the operator had to answer, and the answer (additive-forward-compat, documented) is now a schema invariant going forward. A single reviewer would likely have only caught one framing.
14. **"No critical findings" on a two-day-old architecture is a good outcome, not a null result.** The review found 6 SIGNIFICANT issues worth fixing, which is substantial signal. But no CRITICAL means the foundational design — explicit-now injection, classifier seam, try/finally discipline — held up under adversarial review. This calibrates expectations: future TV2 work built on this foundation can rely on the 057b/c surface rather than needing to audit it.

# tess-v2 — Run Log

**Previous log:** run-log-2026-03.md (45 sessions, Mar 28 – Apr 10. Project creation through Phase 4 implementation. Key milestones: Hermes GO + Nemotron GO decisions, Phase 3 architecture complete, 10 services migrated with gates passed, Phase 4a vault semantic search complete, Amendment Z Phase A live. TV2-036/037 cancelled Apr 10. TV2-043 Scout in re-soak.)
**Rotated:** 2026-04-10

## 2026-04-17 — Phase 5 prep + TV2-057b full landing + Amendment AB + build-plan deliberation

**Context loaded:** project-state.yaml, tasks.md TV2-057a-f rows, run-log.md recent sessions (TV2-039 cutover + TV2-057a landing), tv2-057-promotion-integration-note.md (full), tv2-057a-backfill-runbook.md, tv2-057a-resumption-brief.md, tv2-038-validation-report.md (§1–§6), staging-promotion-design.md (§3.4, §13, headers), service-interfaces.md (§2a vault-health, §4a daily-attention, §8a connections-brainstorm), src/tess/contract.py (full), src/tess/classifier.py (full), contracts/vault-health.yaml, contracts/daily-attention.yaml, contracts/connections-brainstorm.yaml, scripts/run-vault-check.sh, scripts/daily-attention.sh, scripts/connections-brainstorm.sh, _openclaw/scripts/vault-health.sh, _openclaw/scripts/daily-attention.sh, spec-amendment-AA-vault-semantic-search.md (frontmatter shape), spec-amendments-harness.md (T–Y lookup), spec-amendment-Z-interactive-dispatch.md (full Z1/Z2/Z3/Z4 + peer review action items), src/tess/dispatch.py + src/tess/session_report.py (Amendment Z live state), run-history.db (service/outcome breakdowns for Phase 5 dry-runs). 10 source docs at the design ceiling per CLAUDE.md.

### Phase 5 prep for TV2-038

Discovered hold-time unit error: runbook and validation-report listed the Phase 5 floor as `2026-04-17 18:00Z` but TV2-056 must-fix commit `02be7b7` landed `2026-04-15 18:43 -0400 = 22:43Z`. Earlier draft dropped the `-0400` offset. Corrected floor to `2026-04-17 23:00Z` in both documents with explanatory notes.

Added §1.4 methodology to tv2-038-validation-report.md (Phase 5 window, Class A/C bifurcation, class-specific success predicates). Added §5.1 execution playbook: 7 SQL queries (window constants, outcome/tier breakdown, class-bifurcated success, dead-letter detail, tier routing, cadence matrix, state-reconciliation probe) + acceptance procedure. Dry-runs against the partial window validated SQL syntax; preview showed 14/15 services at 100% success, 1 vault-health dead_letter (matches project-state "awaiting revalidation"), 282 email-triage rows since cancellation (§3.3 gap still open), ~87% cadence fidelity across 900s/1800s services (macOS-sleep-induced StartInterval drift).

### TV2-057b full execution

**Audit surfaced three architectural tensions** (operator-directed decisions):
1. **vault-health** — Tess v2 wrapper produces only `vault-check-output.txt` in staging; canonical `_openclaw/state/vault-health-notes.md` still written by the loaded `ai.openclaw.vault-health` plist. Decision: defer `canonical_outputs` declaration to TV2-040 when canonical-artifact ownership transfers.
2. **connections-brainstorm** — wrapper writes to `_openclaw/inbox/brainstorm-{date}.md`; per integration-note §5 `_openclaw/` is mirror space. Decision: reclassify A → C, honor §5 principle over the §1.1 listing error.
3. **daily-attention** — confirmed §4.4 landmine: wrapper shells out to `_openclaw/scripts/daily-attention.sh` which writes directly to canonical path `_system/daily/{date}.md`. Decision: pre-plan TV2-057d migration in 057b deliverable, execute in 057d.

C2 (generation-time bake-in) selected for §2.2 sub-question — no existing contract-generation tool, only 1 active Class A contract, service-interfaces.md is hand-authored markdown.

**Design docs:** integration-note status draft → accepted; §1.1 amendment (A→C moves), §1.2 row-count adjustment (5800 Class C), §2.2 resolved, §2.4 field-shape added, §7a closed-decisions table. `staging-promotion-design.md` §3.4.2 dispatch-modes Amendment + §13 Q1 closed. `service-interfaces.md` class-status callouts on 2a/4a/8a. `tv2-057d-daily-attention-migration.md` created (full implementation spec: current state, target state with ATTN_OUT_DIR override, change inventory, rollback, pre-flight checklist).

**Code:** `src/tess/contract.py` schema v1.1.0 → v1.2.0, `CanonicalOutput` dataclass, `canonical_outputs` in `AUTHORED_FIELDS`, 13 validation rules (no absolute paths, no `..`, bare filenames, closed placeholder set `{date}/{week}/{timestamp}`, uniqueness). `src/tess/classifier.py` primary predicate swapped to `canonical_outputs`-check with transitional allowlist fallback; connections-brainstorm + vault-health added to allowlist; safe Class A default for unknowns preserved (TV2-057a safety choice). `contracts/daily-attention.yaml` schema bump + `canonical_outputs: [{staging_name: attention-plan.md, destination: _system/daily/{date}.md}]`. `scripts/tv2_057a_backfill.py` fallback allowlist synced + hold-time note corrected.

**TV2-057a backfill amendment:** scope 12 → 14 services (+ connections-brainstorm, vault-health); dry-run 5807 → 5836 rows (natural drift from 2 days of runs). Runbook Class A/C lists updated. Phase 5 §1.4/§5.1.3 SQL amended to match new classification.

**Tests:** +14 canonical_outputs validation tests in `test_contract.py`; classifier tests rewritten for transitional-fallback semantics (+9 tests); `test_ralph.py::TestSideEffectClassification` updated (Class A via populated field; vault-health + connections-brainstorm now Class C). Full suite 475/475 pass.

### Amendment AB landing (follow-up)

Operator flagged that a new schema-affecting field deserves its own Amendment letter per the T–Y / Z / AA convention. Next letter: AB. Created `spec-amendment-AB-canonical-outputs.md` (230 lines): problem statement, AD-016 architecture decision, full field shape + 9 validation rules, classifier-swap semantics + transitional fallback + safe-default-for-unknowns rationale + follow-up retirement plan, backward-compatibility analysis, related-work map. All code touchpoints tagged "Amendment AB" (`contract.py` module docstring + constants + dataclass + validation clause, `classifier.py` module docstring + function docstring, `contracts/daily-attention.yaml` inline comment). Cross-references tightened: `staging-promotion-design.md` §13 Q1 closure cites AB; integration-note §2.4 flags AB as the canonical spec.

### IDQ-004 wrapper backfill

`scripts/scout-feedback-poller-wrapper.sh` authored 2026-04-09, live in production since 2026-04-16 TV2-039 cutover, never committed. Landed as `chore: commit IDQ-004 scout-feedback-poller wrapper` (`7fb884c`). Code repo now clean.

### Extended architectural deliberation (no code)

Operator asked for analysis of Amendment Z integration with current work + correct build order. Surfaced:

- **Gap 1 (autonomous-dispatch safety interlock):** Phase B could auto-dispatch a Class A contract whose promotion wiring isn't live → strands artifact in STAGED. Decision: land as spec amendment (AC) against accepted Z, not as Phase B implementation comment. Three provisions per operator: fail-closed on registry desync (declarative `canonical_outputs` + absent `MIGRATED_SERVICES` entry → reclassify to interactive, never dispatch-and-hope); registry-update-in-same-commit discipline for each TV2-057d per-service migration; patchable `MIGRATED_SERVICES` test fixture for Phase B's dispatch-router tests. Module-level registry mechanism chosen (grep-able, no contract-file churn).
- **Gap 2 (run_history ↔ session_reports linkage):** operator pushback correct — `task_ref` already carries the join, don't pre-commit schema against unwritten code. Withdrawn.
- **Gap 3 (interactive-planning service contract):** defer, natural Phase B day-one artifact.
- **R1/R2 lock-retry:** operator lean R2 (exit + retry on next cadence) over R1 (in-invocation spin-retry). Queue-driven retry semantics already exist; R1 duplicates machinery + blocks dispatcher thread. Added guardrail: lock-denied exits with code `75` (`EX_TEMPFAIL` from sysexits.h) and does NOT write a `run_history` row. Keeps service-health monitors silent on ambient contention; operators see exit-75 clusters in launchd logs under pathological contention; `N` consecutive denies → Z4 reclassifies to interactive. `N` flagged as 057c implementation decision, not pre-committed.
- **TV2-040 split:** not one task, two coupled tasks. 040a (decommission OpenClaw vault-health writer) + 040b (land Tess v2 replacement writer + AB `canonical_outputs` declaration for vault-health). Near-atomic so canonical artifact never has no writer.
- **Amendment Z canonicalization:** still `draft`. Phase A live 11 days (since 2026-04-06), soak window closes 2026-04-20. Peer-review action items A1–A10 substantially addressed in current text; A8 (queue status enum — derived view wins per Rule 5 materialized-view model) and A10 (claims-based orphan detection vs reviewer's `_tess/sessions/active-*.yaml` proposal — implementation diverged, spec text needs alignment) are the two reconciliation items. Flip `draft` → `accepted` at 2026-04-20.
- **TV2-057e crash recovery ↔ Z3 boundary:** owns `_staging/*/.promotion-manifest.json` + `run_history.db`; does NOT touch `claims.yaml` / `session_reports.db` (Z3's surface). Operator-scope reconciliation across surfaces. Literal §X boundary text pre-drafted for the 057e design doc.

**Vault standards consolidation (upstream prerequisite for Amendment AD):** operator flagged that "Crumb's standards" are distributed across vault-check.sh, spec, CLAUDE.md, knowledge-navigation MOC system, claude-ai-context.md. Adding Tess as a second autonomous writer without consolidation = two write standards in same vault = drift. Decision: `_system/docs/vault-standards.md` is an upstream prerequisite to AD, not a side deliverable. Three-bucket classification for consolidation inconsistencies: (1) genuine conflict → needs operator decision; (2) stale text → keep current, annotate superseded; (3) under-specification → gap-remediation input. Claude drafts, operator + 4-model panel reviews. Architecture spike on `vault-check.sh` in parallel to classify its 25+ checks into per-file-clean / per-file-with-context / whole-vault-only before committing AD's enforcement mechanism.

**Final build plan (locked):**

```
2026-04-17 23:00Z  TV2-038 Phase 5 → ~23:30Z backfill → TV2-057a DONE
2026-04-18→19     TV2-057c (lock acquisition, R2 + exit-75 + N-as-decision)
2026-04-20        Z canonicalization (A8+A10) → accepted; Amendment AC (dispatch-interlock)
2026-04-20/21     vault-standards.md consolidation draft (three-bucket)
                  vault-check.sh architecture spike in parallel
2026-04-22        vault-standards 4-model peer review
2026-04-23        vault-standards accepted; gap-remediation scoped
2026-04-24        gap-remediation implementation
2026-04-25        Amendment AD draft (promotion gate, path-category-scoped, no opt-out,
                  PROMOTION_GATE_FAILED outcome, 72h retention)
2026-04-26        vault-check.sh --file mode implementation
2026-04-27        TV2-057d phase 1 synthetic fixtures
2026-04-28+       TV2-057d phase 2 daily-attention migration
TV2-040a+040b     Anywhere post-057c, operator-bandwidth-gated, near-atomic pair
TV2-057e          Post-057d, with §X Z3 boundary section
Later             Z Phase C (graduated autonomy), TV2-057f (Class A legacy backfill)
```

### Commits + pushes

Code repo (`djt71/tess-v2`):
- `f336ae9` — TV2-057b canonical_outputs schema + classifier swap (7 files, +450/-43)
- `7fb884c` — IDQ-004 scout-feedback-poller wrapper backfill
- `461ffb6` — Amendment AB code tagging (3 files, +34/-21)

Vault (`djt71/crumb-vault`):
- `ceecf8c9` — TV2-057b design landing + TV2-038 Phase 5 prep (6 files, +487/-17)
- `083d21d2` — chore service state accumulation (41 files)
- `e56acf2e` — Amendment AB spec doc (3 files, +230/-2)
- `886f3b1b` — chore service state accumulation 2 (16 files)

### Compound observations

1. **Resumption briefs with explicit verification checklists pay for themselves, again.** TV2-057a session 4 noted this; reinforced today: the §4.4 audit would have missed both vault-health's ownership gap and connections-brainstorm's §5 contradiction without the explicit wrapper/script reading step. "Read the actual wrapper, don't trust the integration-note's §1.1 classification list" earned its keep twice.
2. **Schema-addition reflex needs calibration.** Caught by operator: I defaulted to "add `run_history_contract_id` to session_reports" as a pre-commit when `task_ref` already carries the join. Pattern: for orchestration work with small tables and non-hot paths, prefer existing keys; for spec amendments, don't pre-commit schema against unwritten code. Saved as feedback memory (`~/.claude/projects/.../memory/feedback-schema-addition-reflex.md`).
3. **Amendment letter discipline has value.** Danny's push to label canonical_outputs as Amendment AB (rather than an untagged schema change) creates a traceable amendment trail — future sessions can map "where did `canonical_outputs` come from?" to one letter, one spec doc, one closed-decisions table. Small ceremony, real provenance.
4. **Upstream-consolidation-first pattern.** The vault-standards.md consolidation isn't a side deliverable — it's the prerequisite for AD. I initially skipped it and went straight to enforcement mechanics; operator catch reframed the dependency chain. Generalizable pattern: when adding a second enforcer to a rule set, check whether the rule set itself is consolidated before designing the enforcement layer. Otherwise enforcement silently encodes whatever subset the second enforcer happens to touch, and drift is guaranteed.
5. **Meta: orchestration burden is still on the operator.** Every forward step in this session was operator-initiated (Phase 5 timing error, §4.4 audit implications, Amendment AB missing letter, vault-standards consolidation gap, three-bucket classification, N-parameter decision point). Claude closed loops; operator held the multi-session dependency graph. That's exactly what Amendment Z Phase B's interactive-planning service is designed to invert. The plan's length is a measure of that gap.

### Model routing

All work on Opus 4.7 1M-context (session default). No Sonnet delegation — the work was reasoning-heavy (classification tensions, amendment coordination, build-plan deliberation) and warranted full reasoning. Large context read (10 design docs at ceiling) + extensive cross-file editing justified the session model.

### Code review

**Skipped (TV2-057b):** 475/475 test pass, schema addition is additive + validated with per-rule tests, classifier swap preserves pre-TV2-057b behavior for all allowlisted services. Deferring formal Tier 1 review to the TV2-057c session when related state-machine changes converge — single review pass covers both landings.

### What's open

- **Tonight 23:00Z:** Phase 5 execution per §5.1 playbook.
- **Post-Phase-5:** Backfill runs per tv2-057a-backfill-runbook.md §3 (snapshot, dry-run on copy, execute, verify).
- **Post-backfill:** TV2-057a → `done`; project-state.yaml `next_action` refreshed.
- **Tomorrow:** TV2-057c design + implementation (R2 lock-retry, exit-75, N-parameter decision).

---

## 2026-04-16b — IDQ-004: Scout feedback-poller swap test

**Context loaded:** queue.yaml (IDQ-004), scout-feedback-poller-wrapper.sh, com.tess.v2.scout-feedback-poller.plist, scout-feedback-health.sh, scout-feedback-health.yaml contract.

### IDQ-004 completion — Tess-side feedback-poller validated

**Finding:** Both pollers were crash-looping. The Tess plist was auto-loaded by macOS on login (placing a plist in `~/Library/LaunchAgents/` causes launchd to load it automatically). Both were competing for Telegram getUpdates, generating 7.8MB of conflict errors in the Tess log.

**Fix:** Disabled Tess poller via `launchctl disable` + bootout.

**Swap test results:**
1. Booted out OpenClaw poller → bootstrapped Tess poller → **clean startup** (exit 0, no getUpdates conflicts, logs writing correctly to `~/.tess/logs/`)
2. Swapped back → OpenClaw poller resumed cleanly (exit 0)

**Artifacts updated:**
- `scout-feedback-health.sh`: Updated NOTE to reflect IDQ-004 completion, added TV2-039 cutover instruction for label switch
- `queue.yaml`: IDQ-004 → done

**Cutover note for TV2-039:** Tess poller is `launchctl disable`d. At cutover: (1) bootout OpenClaw poller, (2) `launchctl enable` + bootstrap Tess poller, (3) set `SCOUT_FEEDBACK_LABEL=com.tess.v2.scout-feedback-poller` or update default in health script.

**Lesson learned:** Pre-staging plists in `~/Library/LaunchAgents/` without `launchctl disable` causes auto-load on next login. Future pre-staging should disable immediately after placing the file.

### TV2-039: Cutover Decision Document

Assessed go/no-go readiness against acceptance criteria:

**Soak data (post-TV2-056, ~45h):** 1015 runs across 15 services. 99.8% success rate. 100% Tier 1 execution. Two issues:
- vault-health: 1 dead_letter in 2 runs — contract spec bug (output truncation at 10m timeout), not service failure. Fixed: timeout → PT15M, content checks updated. Awaiting verification on next scheduled run.
- health-ping: 1 dead_letter in 182 runs — isolated blip, 99.5% success.

**Cost:** ~$4.42/month projected (Tier 3: overnight-research $3.90 + connections-brainstorm $0.12 + escalation $0.40). Well under $50/month target. Email-triage and morning-briefing cancellation removed $5.88/month from baseline.

**Rollback:** Scout rollback runbook tested (2026-04-09), IDQ-004 swap test passed (2026-04-16). Full emergency rollback procedure documented (<30s).

**Decision:** GO approved by Danny with deferred condition (vault-health contract revalidation).

### Cutover Execution — 2026-04-16 ~21:20Z

Danny approved GO. Cutover executed immediately:

1. **Feedback-poller swap:** Booted out `com.scout.feedback-poller` → enabled + bootstrapped `com.tess.v2.scout-feedback-poller` → PID 9474, exit 0, clean startup confirmed.
2. **OpenClaw decommission:** Booted out + disabled `com.scout.daily-pipeline`, `com.scout.weekly-heartbeat`, `com.scout.feedback-poller`. Zero OpenClaw services remaining.
3. **Health script update:** Default label in `scout-feedback-health.sh` changed to `com.tess.v2.scout-feedback-poller`.
4. **Final verification:** 15/15 Tess v2 services loaded. 0 OpenClaw services. Cutover complete.

**Deferred condition:** vault-health contract revalidation on next scheduled run (~2026-04-17T06:30Z). Contract timeout increased to PT15M and content checks updated (earlier in this session). If it fails, investigate — does not affect cutover.

**TV2-039: DONE.** Next: TV2-040 (OpenClaw decommission for migrated services — vault directory migration, plist archival).

---

## 2026-04-16 — Hermes update + soak review + vault-check bug fix + email-triage cleanup

**Context loaded:** project-state.yaml, run-log.md (recent sessions), hermes-patch-tracking.md, hermes-go-decision.md, run-history.db (post-TV2-056 data), vault-check.sh (lines 2282–2400), shell executor (lines 38–102), vault-health contract, staging artifacts (TV2-033-C1, TV2-034-C1/C2/C3, TV2-035-C1, TV2-044-C1).

### Hermes Agent v0.6.0 → v0.9.0

Updated hermes-agent across 3 releases (1377 commits). Key changes for Tess:
- **Patch #1 (reasoning field) closed.** v0.9.0 replaced the v0.7.0 `_classify_empty_content_response` classifier with a multi-stage handler: partial stream recovery → prior-turn fallback → post-tool nudge → thinking-only prefill continuation (up to 2 retries). Sufficient for Kimi's reasoning-only responses. Fork branch (`djt71/hermes-agent`) archived.
- **Patch #2 (KeepAlive) reapplied.** Still out-of-tree in v0.9.0 at `gateway.py:1363`. Changed `SuccessfulExit: false` → unconditional `<true/>`. Plist confirmed.
- Gateway restarted. Kimi heartbeat confirmed clean ("OK" in 2s).
- `hermes-patch-tracking.md` updated: new procedure, update log, Patch #1 decision closed.

### Soak/contract data review (TV2-038 Phase 5 check-in)

Queried `run-history.db` for post-TV2-056 data (Apr 15–16). Findings:
- **TV2-057a classifier working correctly.** All Class C services → `completed` (transition at ~00:43 UTC Apr 16). Class A services (daily-attention, connections-brainstorm) → `staged`. Zero misclassifications.
- **TV2-056 named artifacts present** across all 8 patched services (capture-log, scoring-log, feedback-health, attention-log, brainstorm-log, etc.).
- **14/15 services clean.** Only issue: vault-health dead-lettered (1 run, 3/5 checks passed, 2 failed).
- **TV2-038 Phase 5 timeline:** ~27h of clean data accumulated; 48h window closes ~Apr 18 00:00 UTC.

### vault-check.sh bug discovery and fix

**Root cause:** vault-health contract's two new content_contains checks (added by TV2-056) caught truncated output. Script crashed at "Solution Doc Track Schema" section — `grep '^track:'` returned exit 1 on no-match, `set -euo pipefail` propagated it, `set -e` killed the script before reaching the summary.

Pre-existing bug: the old 3-test contract never tested for output completeness, so the truncation was invisible. TV2-056's strengthened checks exposed it.

**Fix:** 4 unprotected `grep` calls in pipelines wrapped with `{ grep ... || true; }`:
- Line 1936: `grep "^updated:"` in cross-dependency check
- Line 1991: `grep -oE` date extraction in context inventory check
- Line 2067: `grep -oE` date extraction in provenance check
- Line 2299: `grep '^track:'` in solution doc track check

Also fixed the data trigger: added `track: pattern` to `_system/docs/solutions/egpu-local-compute-evaluation.md`.

**Verification:** Targeted test under `set -euo pipefail` confirmed fix. Two full scans (background) completed — both reached "Vault Check Summary" and "RESULT:" lines. Next cron run (tomorrow 06:27 UTC) will be live confirmation.

Audit performed by Explore subagent: all other `grep`-in-pipeline instances already had `|| true` guards — these 4 were the only gaps (plus the one already fixed at line 2299).

### email-triage LaunchAgent cleanup

Both `com.tess.v2.email-triage` and `ai.openclaw.email-triage` were still loaded despite TV2-036 cancellation on 2026-04-10. email-triage had accumulated 441+ run-history entries post-cancellation.

- `launchctl bootout` both services
- Plists moved to `~/Library/LaunchAgents/disabled/` (recoverable)
- Verified: `launchctl list | grep email-triage` returns empty

`com.tess.v2.email-triage` was already absent from project-state.yaml services list (correctly omitted at TV2-036 cancellation).

### Compound observations

1. **Contract strengthening exposes latent bugs.** The vault-health truncation was pre-existing — the script had always crashed before the summary for any vault state where a solution doc lacked `track:`. TV2-056's content_contains checks were designed to prevent stale artifacts, but they also caught this unrelated crash-before-summary failure. Adding output-completeness checks to contracts that run scripts is a general hardening pattern worth applying to other long-running contracts.
2. **`set -euo pipefail` + `grep` in pipelines is a recurring class.** This is the same trap documented in `macos-system-notes.md` memory. Four instances survived because the script was written incrementally — each new check section was tested in isolation (where `set -e` doesn't apply to subshells) but never audited for `pipefail` interaction. When adding checks to a `set -euo pipefail` script, `grep` in a command substitution pipeline needs `{ grep ... || true; }` by default.
3. **Cancelled services need a decommission checklist.** The email-triage LaunchAgents ran for 6 days post-cancellation because "mark task cancelled in tasks.md" didn't include "unload LaunchAgent." Service lifecycle (create plist → register in project-state → ... → unload → move plist → remove from project-state) should be a documented sequence, not ad hoc.

### Model routing

All work on Opus (session default). One Explore subagent for the vault-check.sh grep audit — mechanical file scanning, appropriate delegation. No Sonnet delegation.

### Files touched

- `_system/scripts/vault-check.sh` (4 grep pipeline fixes)
- `_system/docs/solutions/egpu-local-compute-evaluation.md` (added `track: pattern`)
- `Projects/tess-v2/design/hermes-patch-tracking.md` (updated for v0.9.0, patch #1 closed)
- `~/.hermes/hermes-agent/hermes_cli/gateway.py` (KeepAlive reapply, outside vault)
- `~/Library/LaunchAgents/disabled/` (2 plists moved)
- `Projects/tess-v2/progress/run-log.md` (this entry)
- `Projects/tess-v2/project-state.yaml` (updated below)

---

## 2026-04-15 (session 3) — TV2-057 design note + decomposition

**Context loaded:** project-state.yaml, run-log.md (sessions 1 & 2), tv2-038-validation-report.md §4, src/tess/promotion.py (PromotionEngine surface), src/tess/cli.py (_cmd_run), src/tess/ralph.py (TerminalOutcome), src/tess/contract.py (ArtifactSpec), src/tess/locks.py (WriteLockTable signatures), staging-promotion-design.md §3.4/§5.2/§13, contract-schema.md, service-interfaces.md (Outputs rows), ~/.tess/state/run-history.db (6580 rows, 6465 staged).

### Resumed against TV2-039 blocker surfaced in session 2

TV2-057 ("wire promotion engine into cli.py") was flagged as the top cutover blocker. Initial framing: one-session scope to call `PromotionEngine.promote()` from `_cmd_run`. Verified premise — promotion.py is 597 lines and cli.py has zero references to it.

### Design-note-first sequencing (not straight to decomposition)

Deep reading of `promote()` + `build_manifest()` surfaced dependencies: no `canonical_outputs` field on ArtifactSpec, no WriteLockTable acquisition anywhere, no COMPLETED in TerminalOutcome, no caller for steps 9–12 of the promotion sequence. `staging-promotion-design.md` §13 Open Question #1 admits the service-interface mapping was deferred — and TV2-021b shipped without closing it. This isn't a wiring gap; it's multiple primitives missing.

Operator reviewer then pushed back on my scope framing with a sharper observation: only ~5 of 15 services actually produce canonical vault files. The rest are pure side-effects (Telegram/SQLite/HTTP/deleted files). The "wire promotion" framing was solving the wrong problem — prior question is "what are these services contractually producing, and which ones even have something to promote."

### Segmented row counts (load-bearing evidence)

Queried `run-history.db` by service+outcome. Final taxonomy of 6465 staged rows:
- **Class A** (promoting to canonical vault path): vault-health (13), daily-attention (596), connections-brainstorm (13) — 622 rows, 9.6%
- **Class B** (writing to `_openclaw/` mirror paths): overnight-research (11), fif-capture (13) — 24 rows, 0.4%
- **Class C** (side-effect only): 10 services — 5763 rows, 89.1%
- Test/dev: 56 rows, 0.9%

~90% of the "staged" population has no canonical file to promote. That's not a promotion-wiring gap; it's a state-machine semantic conflation — STAGED is being used for two classes that should have different terminal paths.

### Design note written + 4 rounds of reviewer push-back

Drafted `tv2-057-promotion-integration-note.md`. Reviewer returned 3 rounds of corrections:

1. **Round 1:** Pushed back on scope estimate (~5 services, not 15); reframed §4 "state-machine conflation" as primary finding, not secondary; proposed hybrid schema Option C (per-service `canonical_outputs:` in service-interfaces.md with contract inheritance); flagged that router-vs-direct should be an explicit Amendment, not buried in an implementation detail.
2. **Round 2:** Caught §4.4 arithmetic error (5776 vs 5763); flagged §4.4 Class A landmine (wrappers may currently write directly to canonical paths, bypassing staging — vault-health → vault-health-notes.md as first audit); demanded §3 Amendment name the lock-denied retry semantics as a sub-decision; recommended Class B decision be closed early, not deferred; recommended promoting §1.4 "independently shippable" observation from parenthetical to numbered finding.
3. **Round 3:** Caught a 5776 regression in §6.A that survived round 2's fix (two of three places fixed; §6.A's count-language still read 5776). This was the exact failure mode reviewer named in round 2 — somebody writes the bulk UPDATE from a wrong number. Fix landed.

### Decisions accepted (operator, 2026-04-15)

All six §7 decisions closed in the note:
1. Taxonomy A/B/C accepted
2. Schema Option C accepted; C1/C2 inheritance mechanics deferred to 057b
3. §3.4.2 Amendment accepted as drafted; R1/R2 retry semantics deferred to 057c
4. State machine: Class C rows backfill `staged` → `completed` accepted
5. **Class B closed to Class C** (mirror paths are not canonical; batch consumers tolerate torn reads; atomic promotion overkill). Backfill population: 5763 + 24 = 5787 rows.
6. §6 ordering A → F accepted; 057a independently shippable first

### Decomposition landed

tasks.md amended: 6 new sub-tasks TV2-057a–f inserted between TV2-056 and TV2-038. Summary count 58 → 64. Phase 4b Cutover count 3 → 10.

- **TV2-057a (medium, code):** state-machine fix — add COMPLETED, classification predicate with placeholder allowlist (TODO→057b seam), Class C downgrade at STAGED, 5787-row backfill (sequenced as separate commit, held from execution until Phase 5 closes). **Active task.**
- **TV2-057b (medium, design+code):** Option C schema landing + §3.4.2 Amendment + vault-health direct-write audit.
- **TV2-057c (medium, code):** WriteLockTable acquisition at run-entry, R1/R2 resolution.
- **TV2-057d (high, code):** Per-service promotion migration. Likely milestone-shaped.
- **TV2-057e (medium, code):** `tess recover` subcommand, crash-injection tests.
- **TV2-057f (low, code):** Class A 622-row per-service backfill audit.

### Resumption brief written

Session carried to fresh session per context-budget discipline. Written `design/tv2-057a-resumption-brief.md` — self-contained carry-forward:
- Repo SHA anchor `02be7b789d0bccecf718fe32483464cff22db0f3` so fresh session verifies line-number drift before editing
- Deduplicated allowlist (12 services, one edit caught by reviewer: fif-capture originally listed twice)
- Backfill-annotation decision promoted from "decide during implementation" to Verification 0 (first action in fresh session) — two options (sentinel in `dead_letter_reason` vs. new column) with lean toward A
- Explicit do-not list; commit structure; hold condition

### Compound observations

1. **Design-note-first beat straight-to-decomposition.** Original plan was to go from "blocker surfaced" directly to "write 057 acceptance criteria." Dropping a 1-2 page note instead forced the taxonomy question ("how many services actually need promotion?") that reversed the entire scope framing. If the decomposition had landed first, the ~90% side-effect conflation would've been discovered during 057a implementation as an apparent bug — wasteful. Note-first surfaced it in the design phase where it's cheap. This generalizes: when the top of a decomposition is "wire X into Y" and X was designed under different assumptions than Y's reality, always check the assumption first.
2. **The "~5 services, not 15" finding was not in any design doc.** No one had written it down because no one had asked. The Outputs column in service-interfaces.md had always been prose, never structured — which is exactly why the open question at §13 #1 went unclosed. Unstructured fields defer questions that structured fields would force. Applied consequence: when a design doc's §13 has an "Open Question" that defers a field definition, that field is a future scope bomb. Audit §13 lists for ossifying open questions during design reviews.
3. **Reviewer caught a regression I didn't.** After round 2 I edited 5776→5763 in §1.2 and §4.4 but missed §6.A. Reviewer's round-3 flag named it explicitly: "the failure mode I named originally — somebody writes the bulk UPDATE from §6.A's number and finds a 13-row gap." That is: a critic's prior prediction, specifically shaped around how that exact mistake manifests, caught its own instantiation on the next round. Mechanical `grep` for "5776" would have caught it too, but I didn't think to grep — I relied on memory of "which places I edited." Memory of edits is a weak substitute for mechanical verification. When a number is being revised across a document, grep the old value after editing to confirm zero survivors. (Ironically this mistake matched compound observation #3 from run-log 2026-04-15 session 2: "pattern-fix discovered by one task, applied everywhere it fits" — I failed to apply my own lesson.)
4. **Context asymmetry is real.** The reviewer's reasoning for carrying 057a to a fresh session ("continuing here means burning the rest of this thread's context window on code that a fresh session would write with cleaner working memory and full context budget for the actual code") is a reusable heuristic: design-heavy threads produce high-value artifacts that don't inform the subsequent implementation. When the plan is complete and the code is not, carry the code. This inverts the intuition of "continuity is cheap" — continuity is actually quite expensive in degraded context.

### Model routing

All design work on Opus (session default). No subagent delegation — the reasoning chain was tightly coupled and the context was mostly in-head. Peer-review-style pushback came from the operator directly (high-quality review input — caught three defects I didn't). No cost data to note.

### Files touched

- `Projects/tess-v2/design/tv2-057-promotion-integration-note.md` (new, 200+ lines, 3 revision rounds)
- `Projects/tess-v2/design/tv2-057a-resumption-brief.md` (new)
- `Projects/tess-v2/design/tasks.md` (6 new rows, Phase 4b summary updated)
- `Projects/tess-v2/project-state.yaml` (active_task, next_action updated)
- `Projects/tess-v2/progress/run-log.md` (this entry)

No code changes. No commits to `/Users/tess/crumb-apps/tess-v2`.

---

## 2026-04-15 — TV2-043 gate PASS (re-soak close)

**Context loaded:** project-state.yaml, dispatch queue (IDQ-002), scout-pipeline-stdout.log, opportunity-scout digests Apr 13/14/15, _staging/TV2-043-C1/execution-log.yaml, tasks.md

### Gate decision

**Verdict: PASS.** C1 3/3 clean runs over Apr 13/14/15:

| Date | Contract | Digest | Items | Telegram msg |
|---|---|---|---|---|
| Apr 13 | STAGED (9/9) | delivered | 5 | 63 |
| Apr 14 | STAGED (9/9) | delivered | 3 | 66 |
| Apr 15 | STAGED (9/9) | delivered | 1 | 67 |

Zero dead-letters post-fix. Nemotron LIMIT 10 fix (`ef93e1a`) is holding — `finish_reason === 'length'` guard never tripped across the re-soak window. C2 (feedback-health) and C3 (weekly-heartbeat) were proven at the Apr 12 eval and unchanged since.

Re-soak exceeded the 2-day requirement (Apr 13–14) by running cleanly through today's Apr 15 delivery before the gate was formally closed — extra data point, same verdict.

### State changes

- `Projects/tess-v2/project-state.yaml`: updated 2026-04-12 → 2026-04-15, next_action rewritten (44/50 done, TV2-038 unblocked)
- `_tess/dispatch/queue.yaml`: IDQ-002 status queued → done (completed 2026-04-15), blocked_until cleared, version 5 → 6
- `Projects/tess-v2/design/tasks.md`: TV2-043 state todo → done, acceptance criteria annotated with PASS evidence
- TV2-038 no longer blocked (its only open dep was TV2-043). Ready to schedule the 48h parallel validation.

### Follow-ups

- **IDQ-004** (Tess-side feedback-poller plist) unblocked — was gated on IDQ-002. Pre-staging complete per queue.yaml; bootstrap deferred to TV2-039 cutover.
- **TV2-038** now schedulable. No action taken this session — flagged for next planning pass.

### Model routing

All work on Opus (session default). Mechanical vault edits only — no skill delegation warranted.

---

## 2026-04-15 (session 2) — TV2-038 kickoff + TV2-056 discovery and fix

**Context loaded:** tasks.md (Phase 4b), migration-inventory.md, observability-design.md, service-interfaces.md, action-plan.md §Milestone 6, `~/.tess/state/run-history.db` (14 services, 4961 rows), all 8 wrapper scripts + 8 contract YAMLs in `tess-v2/scripts/` and `tess-v2/contracts/`, Scout remediation pattern from `scout-pipeline.sh`.

### TV2-038 Phase 1 — methodology

Wrote `design/tv2-038-validation-report.md` — schema for 15 services × 4 dimensions (output parity, missed outputs, cost, tier routing) + 4 cross-cutting sections (vault authority, evaluator separation, state reconciliation, migration inventory re-audit) + gate summary matrix.

Scope decisions: 48h window 2026-04-13 → 2026-04-15; out of scope = email-triage (cancelled), morning-briefing (cancelled), platform services (dispatch, contract runner) — validated via contract infrastructure itself; Tier 1+2 ≥70% via contract-ledger; cost ceiling $75/mo pro-rated, $50/mo target.

### TV2-038 Phase 2 — data collection (6 Explore subagents in parallel)

Dispatched 6 subagents grouped by migration task family (TV2-032, -033, -034, -035, -043, -044). Each filled §2 per-service blocks from `run-history.db` (authoritative) + staging artifacts + OpenClaw state files. All returned successfully.

**Initial findings flagged as BLOCKERS:**
1. `fif-capture` — 0 items captured, 8 adapters skipped despite OpenClaw inbox growth
2. `overnight-research` — Apr 13 DEAD_LETTER (semantic); Apr 14 zero-output

**Root-cause triage downgraded both:**
- `fif-capture` is architectural: both platforms share `capture-clock.js` + FIF SQLite. OpenClaw's 06:05 UTC run captures the day; Tess v2's 10:30 UTC run dedups to no-op. "Parallel operation" is semantically "one productive run per day" — not a bug, a paradigm clarification for TV2-039 cutover question.
- `overnight-research` had two narrow bugs: NO_OP regex was case-sensitive ("No reactive items" vs script's actual "no reactive items"), and (more important) the contract artifact `research-log.yaml` was stale Apr 3.

### TV2-056 — systemic finding and fix

Investigating the overnight-research stale-artifact led to discovering **9 of 15 services had contracts validating Apr 2–5 artifacts**. Wrappers wrote structured YAML to stdout, captured as `execution-log.yaml` — but contracts checked per-service names (`capture-log.yaml`, `scoring-log.yaml`, `attention-log.yaml`, etc.) that had never been updated since initial migration.

Scout had this same bug until the Apr 9 re-soak remediation (IDQ-002, decision: "C1/C2 wrappers write directly to staging, all 3 contracts strengthened"). Fix pattern: `LOG_FILE="${STAGING_PATH:-.}/{name}"` + `cat <<YAML | tee "$LOG_FILE"`.

Created TV2-056 (added to tasks.md Phase 4b) and executed end-to-end in this session:

**8 wrappers patched** (all use scout-pipeline-style `LOG_FILE` + tee):
- `run-vault-check.sh` → vault-check-output.txt
- `vault-gc.sh` → gc-log.yaml
- `fif-capture.sh` → capture-log.yaml (including pause-flag case)
- `fif-attention.sh` → scoring-log.yaml (including pause-flag case)
- `fif-feedback-health.sh` → feedback-health.yaml
- `daily-attention.sh` → attention-log.yaml
- `overnight-research.sh` → research-log.yaml (+ case-insensitive NO_OP regex)
- `connections-brainstorm.sh` → brainstorm-log.yaml

**8 contracts strengthened** with content_contains/content_not_contains checks: service-name assertions, `status: "failed"` exclusions, result/summary presence, `health: down` exclusion for fif-feedback-health.

**Verification:** `bash -n` on all 8 (pass). Runtime invocation with `STAGING_PATH=<tmp>`: `run-vault-check.sh` (vault-check-output.txt grown to 102+ lines during run before killed), `vault-gc.sh --dry-run` (clean), `fif-feedback-health.sh` (clean), `fif-capture.sh` (clean, dedup no-op expected), `daily-attention.sh` (idempotent skip, fresh attention-log.yaml), `connections-brainstorm.sh` (week-idempotent skip, fresh brainstorm-log.yaml). `fif-attention.sh` and `overnight-research.sh` not live-invoked (LLM cost) — mechanically identical pattern.

**TV2-038 report updated:** §2 preamble now reframes the two "BLOCKERS" as non-blockers post-root-cause. Phase tracking adds 2a (TV2-056) and 5 (re-collection post-remediation).

### Other findings surfaced but deferred

- `email-triage` has 441 run-history entries through 2026-04-15 despite TV2-036 cancellation 2026-04-10. LaunchAgent never got unloaded cleanly. Flagged for Phase 3 state reconciliation.
- `vault-health` OpenClaw peer last-run stale 13 days — either intentional decommission (needs migration-inventory update) or silent stop. Flagged for Phase 3.
- `cost-tracker.yaml` doesn't exist — TV2-028 observability infrastructure not deployed. All TV2-038 cost verdicts PENDING until deployment or accepted-as-risk.
- Tier routing 100% Tier 1 across all services — worth interrogating whether router is actually making decisions or defaulting to local.

### Compound observations

1. **Contract-level success can mask total functional failure.** 9 services reported "all runs staged" while their contracts validated 12-day-old files. Fresh `execution-log.yaml` (captured runtime state) existed alongside stale named artifacts, and no contract test compared timestamps. Freshness assertions (mtime > contract start, or embedded timestamp matches execution-log) should be a default check category — not an afterthought.
2. **Root-cause first, BLOCKER classification second.** My initial Phase 2 findings called fif-capture and overnight-research BLOCKERS. 30 min of investigation downgraded both — one to architecture-not-bug, one to a narrow wrapper regex. Had I committed to the BLOCKER framing and escalated, the response would've been disproportionate. Triage is cheap and compresses surface area before commitment.
3. **Pattern-fix discovered by one task, applied everywhere it fits.** Scout's Apr 9 remediation was effectively a template. It sat un-propagated for 6 days because no one asked "which other services have this exact shape?" That question during TV2-038 validation caught 8 more instances. Worth routine: whenever a fix for service-class-X is applied, grep the other members of class-X before closing.

### Model routing

All work on Opus (session default). Delegated Phase 2 data collection to 6 parallel Explore subagents (`subagent_type: Explore`) — mechanical read-heavy work, kept main context clean. Each agent was bounded by word count (400–1200 words per response) and pre-specified SQL queries. No Sonnet delegation.

### TV2-056 code review

Ran `code-review` skill on commit `d8bad52`. Two-reviewer panel (Opus 4.6 via API, Codex GPT-5.3 via CLI). Test gate passed: 433/433 pytest. Review note: `Projects/tess-v2/reviews/2026-04-15-code-review-manual.md`. Review tag: `code-review-2026-04-15-tv2-056`.

17 findings total, 0 CRITICAL, 4 SIGNIFICANT, 4 MINOR, 7 STRENGTH, 1 consensus (ANT-F1 + CDX-F1). No systemic clusters (findings heterogeneous).

**Must-fix applied (commit `02be7b7`):**
- **ANT-F5:** `fif-attention.sh` paused-pause heredoc omitted `tier_distribution:`, which the contract's `test_tier_distribution` content_contains requires — would fail the contract whenever FIF is paused. Added `tier_distribution: {}`.
- **ANT-F1 + CDX-F1 (consensus):** `run-vault-check.sh`'s trailing `|| true` masked both vault-check's intentional nonzero (warnings) AND tee's unintentional write failures. If `$STAGING_PATH` became unwritable, the stale artifact would persist and satisfy `file_exists`/content checks — re-enabling the exact stale-artifact failure mode TV2-056 was meant to close, for this one contract. Replaced with preflight-truncate (fails loud if unwritable) + explicit `PIPESTATUS[1]` check on tee.

**Should-fix deferred** (filed as follow-up, no urgency):
- ANT-F3: `fif-feedback-health` service-name asymmetry (`fif-feedback-health` contract vs `fif-feedback` service line) — cosmetic only.
- ANT-F4: `vault-gc` is the only wrapper without a `status:` field → only contract without `test_status_not_failed`. Add status emission + test.
- ANT-F6: `vault-gc.sh` emits bare unquoted `timestamp:`; all 7 others quote it. YAML type-coercion risk.

**Defer:** ANT-F2 (fif-capture brace-group subtlety — documentation only), ANT-F7 (STAGING_PATH fallback — acceptable), ANT-F8 (overnight-research `skipping` regex broadness — speculative).

Codex environment notes: `mypy` not installed in .venv; `pytest` couldn't run (sandbox `/tmp` visibility). Codex compensated with static verification via `rg` + `nl -ba` of `src/tess/contract.py`, `src/tess/runner.py`, `src/tess/validator.py`, `src/tess/executors/shell.py`. Confirmed all test types (`content_contains`, `content_not_contains`, `line_count_range`, `yaml_parseable`, `file_exists`) are supported by schema + runtime dispatch, and all `service:` strings in contracts match wrapper output (via repo-wide rg cross-check).

Dispatch note: initial Codex CLI call failed on stale flag `--last-message-file`; corrected to `--output-last-message`. Dispatch agent's hard-coded flag set has drifted from installed Codex CLI v0.105.0 — worth a small fix to the code-review-dispatch agent definition.

**Context loaded:** dispatch queue (IDQ-002), TV2-043 staging artifacts (C1/C2/C3), scout pipeline logs, run-history, project-state.yaml, paperclip-relevance-check-2026-04-06.md, services-vs-roles-analysis.md, tasks.md, opportunity-scout source code (llm.js, assemble.js, digest-and-deliver.js)

### TV2-043 Gate Evaluation (Apr 12)

**Verdict: FAIL — C1 0/3 clean runs, C2 PASS, C3 PASS.**

Root cause: Nemotron `max_tokens: 8192` truncation when ranking 30 candidates in digest pipeline. Not a Tess infra issue — application bug in Opportunity Scout's LLM integration. All post-fix runs (Apr 10/11/12) dead-lettered due to "Unexpected end of JSON input" from truncated ranking output.

**Fix deployed** (commit `ef93e1a` in opportunity-scout):
- `digest-and-deliver.js`: LIMIT 30 → 10 (daily cadence doesn't need more)
- `llm.js`: Added `finish_reason === 'length'` truncation detection
- Dry-run verified: 10 candidates → clean ranking, 5-item digest with synthesis

**Re-soak:** 2-day extension (Apr 13–14), C1 focus. C2/C3 already proven. Gate eval Apr 14. IDQ-002 updated (v5), project-state updated.

Also found: Apr 10 OpenClaw 07:00 run succeeded (digest delivered, 5 items) but Tess-side runs failed on `claude -p` scoring. Apr 11-12: both OpenClaw and Tess failed on Sonnet ranking (truncated JSON). The Nemotron migration (f056e5b) replaced `claude -p` for triage but the digest ranking step hit the token limit with 30 candidates.

### TV2-045 Paperclip Integration Spike

**Verdict: DEFER. Bailed at Stage 0 checkpoint (~45 min).**

Key finding: **no generic adapter exists** in Paperclip. The Apr 6 memo and web research claimed Bash/HTTP adapters. Actual adapters in `packages/adapters/`: `claude-local`, `codex-local`, `cursor-local`, `gemini-local`, `openclaw-gateway`, `opencode-local`, `pi-local`. All runtime-specific. tess-v2's Python contract runner doesn't fit any adapter shape.

Additional findings:
- Version still `v2026.403.0` (8 days unchanged despite "weekly calver" claim)
- Dashboard is the only genuine add — everything else overlaps or conflicts with tess-v2's existing capabilities
- Peer review (4-model, all succeeded) validated plan structure but key recommendation (use Bash adapter) was based on incorrect adapter inventory

Artifacts produced:
- `design/paperclip-spike-decision-2026-04-12.md` — decision document with 5-criteria eval, collision inventory, cost/benefit matrix, patterns-worth-copying analysis
- `Projects/tess-v2/reviews/2026-04-12-paperclip-spike-plan.md` — 4-model peer review with synthesis
- Next state-check: ~2026-07-12 (90 days)

TV2-045 marked done. Project: 43/50 tasks done, 2 cancelled.

### Compound observations

1. **Staged spike design with bail checkpoints is proven effective.** 45 minutes vs. 4.5 hour budget. The peer review improved the plan (must-fix items were good), but the Stage 0 finding made all of it moot. Worth applying this pattern to future research spikes.
2. **Web research and prior memos can fabricate adapter inventories.** The "Bash adapter" appeared in the Apr 6 memo, web search results, and all 4 peer reviewers took it as given. Only direct npm inspection revealed it doesn't exist. Ground truth beats secondhand claims.
3. **Nemotron max_tokens ceiling is a production concern.** The 8192 default worked for triage (small batches) but failed for ranking (30 candidates). Local LLM token budgets need to be sized to the prompt, not left at defaults.

### Model routing

- All work done on Opus (session default). No Sonnet delegation this session.
- Peer review dispatched to GPT-5.4, Gemini 3.1 Pro, DeepSeek V3.2, Grok 4.1 Fast (all succeeded, ~$0.22 total estimated).

## 2026-04-15 (session 4) — TV2-057a code landing + held backfill

**Context loaded:** `tv2-057a-resumption-brief.md` (entry point), `project-state.yaml`, `src/tess/ralph.py`, `src/tess/cli.py` (235-260, 630-710), `src/tess/contract.py` (Contract dataclass, lines 85-125), `src/tess/history.py` (full), `tests/test_ralph.py` (full surface), `tests/test_history.py`, `contracts/*.yaml` (service-name cross-check), live `~/.tess/state/run-history.db` row counts.

### Brief executed straight through

Resumption brief was self-contained and accurate. Did all four pre-writing verifications (§9):

1. **HEAD SHA matched** anchor `02be7b789d` exactly — line numbers in brief usable as-is.
2. **STAGED-setting site** in ralph.py is a single return at line 285 (clean single-site downgrade — no refactor needed).
3. **Existing `staged` test assertions** turned out to be safe: test_ralph.py uses `service: "test"` (not Class C), test_history.py uses `outcome="staged"` as schema-level test inputs not state-machine assertions, test_cli.py uses a generic mock. No existing test rewrites required.
4. **Allowlist cross-check caught two brief errors** — `fif-feedback-health` and `scout-feedback-poller` are not actual contract `service:` field values; canonical names are `fif-feedback` and `scout-feedback`. Brief's own §4 note ("cross-verify against contracts/*.yaml") earned its keep — these would have been silent miss-classifications on the two highest-volume Class C services (1194 + 992 rows).

### Implementation

**Commit 1 `bd0482a`** (code landing):
- New `src/tess/classifier.py` with `is_side_effect_contract(contract)`, hardcoded 12-service `_CLASS_C_SERVICES` frozenset + TODO marker pointing to TV2-057b's canonical_outputs schema check.
- `ralph.TerminalOutcome.COMPLETED` added; success path in `run_ralph_loop` calls classifier and downgrades to COMPLETED for Class C contracts. Failure paths (DEAD_LETTER, ESCALATED) untouched.
- `cli._print_result_summary` COMPLETED branch + `_cmd_run` exit code 0 for both STAGED and COMPLETED.
- `history.summary()` default outcome dict includes `'completed': 0` so dashboards don't lose a key.
- New `tests/test_classifier.py` (17 tests: parametrized Class C → True, Class A → False, unknown → False, empty string → False).
- 5 new tests in `tests/test_ralph.py::TestSideEffectClassification` (Class C downgrade, Class A preservation, unknown→staged, dead-letter/escalated paths unaffected).
- 455/455 pass (baseline 433 + 17 classifier + 5 ralph; was 452 in pre-edit run).

**Commit 2 `037c363`** (held backfill):
- New `scripts/tv2_057a_backfill.py` — dry-run by default, `--execute` to apply. Writes sentinel `dead_letter_reason='tv2-057a-backfill'` (Option A per brief §7 — `history.py` has zero migration infrastructure, schema column would be tail-wagging-dog). Refuses to re-run if sentinel rows already exist.
- New runbook in vault: `Projects/tess-v2/design/tv2-057a-backfill-runbook.md` — prereq checks, snapshot/dry-run/execute/verify procedure, rollback (one trivial UPDATE), post-execution updates.
- Validated against a DB copy: 5807 rows flipped (vs brief estimate 5787 — 20-row drift from new runs since brief was written), Class A unchanged, re-run is a no-op.

### Decisions captured

- **Option A** (sentinel in `dead_letter_reason`) — confirmed before writing. `history.py` uses bare `CREATE TABLE IF NOT EXISTS`, no alembic, no schema_version. Adding a column for an ephemeral backfill annotation would import migration ceremony for a one-time-use flag.
- **Allowlist canonical source** — `_CLASS_C_SERVICES` lives in `classifier.py`; backfill script imports it lazily with a hardcoded fallback for portability. Single source of truth survives, but the script can run on a host without the package installed.

### What's still open

- Backfill execution is HELD until **TV2-038 Phase 5 close (≥2026-04-17 18:00Z)**. Running earlier would contaminate Phase 5's gate-verdict math against the pre-TV2-057a meaning of `staged`.
- TV2-057a stays `in_progress` (not `done`) until backfill runs per runbook. Brief §11 explicitly calls this out.
- Production launchd binary is the pre-commit version. Whether the COMPLETED downgrade goes live before manual reinstall depends on install mode (editable vs frozen) — out of scope for this commit, will verify at session-end build step.

### Compound observations

1. **Resumption briefs that include verification checklists pay for themselves.** §9.4 ("cross-verify allowlist") caught two service-name errors in the brief itself. Without the explicit verification step I'd have shipped two miscategorized Class C services and silently mis-classified ~2200 rows. Worth mirroring this pattern in future cross-session handoff briefs.
2. **"Tests asserting outcome==X for service Y" needs a sharper question.** Brief §9.3 framing assumed test_history.py would need rewrites; reading the actual tests revealed they're schema-level CRUD tests with arbitrary fixture values, not state-machine predictions. The right verification question was "which tests would predict-the-wrong-outcome under the new behavior?" not "which tests mention this string?"

### Model routing

- All work on Opus (session default). No delegation. Mechanical work (file edits + script writing) but state-machine surface and design-decision validation warranted full reasoning.

## 2026-04-21 (session 1) — Amendment AC: orchestrator role retraction + durable pattern preservation

**Context loaded:** `_system/docs/anthropic-consolidation-hypothesis.md` (starting point), `Projects/tess-v2/design/spec-amendment-Z-interactive-dispatch.md`, `Projects/tess-v2/design/spec-amendments-harness.md`, `Projects/tess-v2/design/specification.md` (§3.1 + AD list), `Projects/tess-v2/design/specification-summary.md`, `Projects/tess-v2/design/tasks.md`, `Projects/tess-v2/design/action-plan-summary.md`, `Projects/tess-v2/project-state.yaml`, `Projects/tess-v2/design/service-interfaces.md` (service I/O details for surface mapping), `~/Library/LaunchAgents/` inventory + `launchctl list` (ground truth on what "running on Tess" means), `_system/docs/solutions/` listing.

### Session arc

Started from the anthropic consolidation hypothesis doc. User flagged Amendment Z as the most-impacted area but asked for a full analysis before committing to edits. Analysis identified Z as correctly-named primary impact, with secondary impacts on spec §3.1/§3.5/§16 and the service inventory.

Key discoveries during scoping:
- **Ground truth on "Tess" architecture:** the 15 `com.tess.v2.*` services are Mac Studio launchd user agents (`~/Library/LaunchAgents/com.tess.v2.*.plist`) running `bash dispatch.sh <contract>` → tess-v2 Python contract runner → Hermes gateway (KeepAlive, separate plist `ai.hermes.gateway`). Not Hermes cron. My earlier "running on Tess" language had been loose; grounded it before service-to-surface mapping.
- **Telegram reframe:** operator-supplied update that Telegram is notifications-only, not a work-input surface. Collapsed Channels' value proposition entirely.
- **Routines redundancy:** once Tess+Hermes was confirmed staying, Routines reduced to "smaller capability at higher cost" — redundant under always-on Mac Studio. HA-failover argument weak (shared fate with other Mac Studio dependencies).

### The bigger directional shift

Operator articulated a larger reframe than the hypothesis had surfaced: **Tess was being promoted to orchestrator (level 2 under operator); 2+ weeks of live operation proved Hermes Agent isn't up to that role by operator standards.** Both Kimi K2.5 (87/100 synthetic) and GPT-5.4 failed the role in live use. The operator prefers interactive work with claude.ai + Claude Code via Crumb/vault, with a bridge mechanism needed to flow work from claude.ai/Cowork into Crumb.

This inverted Z's writer-reader direction: Z had Tess writing the queue, Crumb reading. AC has upstream surfaces writing (via future bridge), Crumb reading. Z's schemas survive; the role hierarchy is reversed.

### Work completed

**Amendment AC** drafted: `Projects/tess-v2/design/spec-amendment-AC-execution-surfaces.md`. Four-level stack (Operator → Upstream surfaces → Crumb → Tess scheduled services). AD-017 retracts AD-013. AD-018 formalizes surface division of labor. Routines + Channels evaluated and rejected. All 15 services stay on Tess. Z retained schemas for upstream work bridge (design deferred). Status: draft, pending operator ratification.

**Amendment Z** marked superseded with banner at top + frontmatter fields (`status: superseded`, `superseded_by`, `superseded_date`).

**Category A preservation (generally-applicable engineering knowledge):**
- 3 distilled extractions to `_system/docs/solutions/`: `live-soak-beats-benchmark.md`, `staged-spike-with-bail.md`, `lenient-parsing-before-evaluation.md` (all with `track: pattern` per solution-doc schema)
- Index at `_system/docs/tess-v2-durable-patterns.md` cataloging 23 reusable patterns
- All 23 source docs tagged with `scope: general` frontmatter + short Scope banner

**Dead-scope sweep:** AC narrowing banners added to `specification.md` (§1/§3.5/§16 + AD-017/AD-018 pointers after AD-009), `specification-summary.md` (problem/solution/success), `action-plan-summary.md`, `tasks.md`. No open task retired — AC narrows role scope, not infrastructure delivery. `project-state.yaml` `next_action` updated with full session summary.

**Pattern enforcement proposal:** `_system/docs/proposal-pattern-enforcement-schema.md` (draft). Two-layer mechanism proposed for ensuring durable patterns get applied in future software/system projects: (1) spec frontmatter schema enforcement via vault-check for required declarations (execution_model, verifiability_tier, escalation_strategy, etc.) with enum values drawn from the durable patterns index; (2) skill-preflight injection of `tess-v2-durable-patterns.md` when systems-analyst/action-architect activate on software-domain work. Estimated ~4.5 hrs of focused work. 8 open questions flagged for operator reflection before any implementation.

### Commits

- `88a85e68` — AC amendment + Z supersession + durable pattern preservation (34 files, +990/-8)
- `34e5623c` — Pattern-enforcement proposal + service state accumulation (17 files, +269/-60)

### Compound observations

1. **Surface-inventory-shaped framing hides candidate rejection.** The hypothesis doc inventoried 5 Anthropic surfaces (Cowork, Routines, Channels, Remote Control, Crumb) and assumed division-of-labor would assign each a role. Without the Tess-retention decision being tested first, every surface looked like it might fit somewhere. When Tess+Hermes retention was confirmed, Routines and Channels collapsed to "not needed" — but this outcome wasn't reachable from the inventory framing alone. Lesson: decide *scope of the system staying intact* before enumerating *what to add*. Otherwise every inventory item gets an unearned seat at the table. Candidate for `_system/docs/solutions/` as a companion to the existing `vendor-comparison-feature-inventory.md` — scope-first-then-inventory, not inventory-first-then-fit.

2. **Category A preservation was the operator's prompt, not mine.** My initial AC draft didn't address "what happens to the genuinely useful engineering knowledge when we narrow the project?" — the operator asked the question directly ("response-harness-analysis.md, contract-schema.md, ralph-loop-spec.md, there are probably others — what's your analysis?"). Without that prompt, the tags/index/extractions wouldn't have happened in this session. Claude default is to complete the requested scope, not audit adjacent losses. Flag for future narrowing/supersession work: **always ask "what generally-applicable knowledge is embedded here that shouldn't be orphaned?"** when marking a project or design doc superseded. Applies beyond tess-v2.

3. **Preservation without enforcement is ironic.** The patterns preserved today (contract schema, Ralph loop, staging/promotion, three-gate escalation, etc.) were explicitly built to mechanize what had previously been behavioral. Leaving their *application* to behavior (hope someone reads the index) contradicts their own thesis. The operator caught this after preservation was done ("is there a mechanism to ensure they're followed?"). The pattern-enforcement proposal resolves it but is a future-session commitment, not this-session work. Flag for any future "preserve doctrine" effort: **design the enforcement lever at the same time as the preservation.** Otherwise the preservation itself is a behavioral trigger.

4. **Claude-Opus-as-web-chat-conversation partner vs. Crumb-as-execution-partner is real.** The hypothesis doc was triggered by an extended claude.ai web chat with Opus. That chat produced the Tess-sunset hypothesis that this session formally retracted. The "think out loud on claude.ai, then come to Crumb for execution" pattern is exactly the upstream→downstream flow AC formalizes — and that flow was used to *produce* AC. Structural validation of the division-of-labor proposed in AD-018.

### Model routing

- All work on Opus (session default). No delegation.
- Substantial spec/design authorship, multi-file coordinated sweep across 34 files, schema-shaped extraction work. Opus warranted for architectural judgment and coordination burden.
- Session was long — ~15 user turns, large tool-call volume. No compaction needed.

### Session-end state

- AC: `status: draft`, pending operator ratification
- Z: superseded
- Patterns preserved and indexed
- Pattern-enforcement proposal: draft, 8 open questions for operator
- TV2-057d still the active task — not touched this session
- Two clean commits, zero errors at vault-check (4 non-blocking XD warnings, pre-existing)
