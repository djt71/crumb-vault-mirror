---
project: tess-v2
type: run-log
period: 2026-04 onwards
created: 2026-04-10
updated: 2026-04-15
---

# tess-v2 — Run Log

**Previous log:** run-log-2026-03.md (45 sessions, Mar 28 – Apr 10. Project creation through Phase 4 implementation. Key milestones: Hermes GO + Nemotron GO decisions, Phase 3 architecture complete, 10 services migrated with gates passed, Phase 4a vault semantic search complete, Amendment Z Phase A live. TV2-036/037 cancelled Apr 10. TV2-043 Scout in re-soak.)
**Rotated:** 2026-04-10

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
