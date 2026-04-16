---
project: tess-v2
type: tasks
domain: software
skill_origin: action-architect
status: active
created: 2026-03-28
updated: 2026-03-28-r2
---

# Tess v2 — Tasks

Supersedes the preliminary task list in specification.md §15. Task IDs are renumbered; the spec's original TV2-001–TV2-019 are retired.

## Phase 0: Foundation

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|-------------------|
| TV2-001 | Migration inventory — catalog all OpenClaw cron jobs, scripts, state files, configs, credentials | done | — | low | research | Inventory table in design/ classifies every item as migrate/rebuild/drop. Each service includes: primary trigger, input sources, output destinations, current failure modes, baseline output metrics. Inventory confirmed exhaustive against running launchd services and cron entries. Migration plan (M5) updated if inventory reveals services beyond the 6 defined categories. |
| TV2-002 | Build llama.cpp + download candidate GGUFs (Qwen3.5 27B Q4+Q6, GLM-4.7-Flash, Nemotron, Qwen3.5 35B MoE, Qwen3-coder 30B) | done | — | low | code | llama.cpp compiles on Mac Studio. Qwen3.5 27B Q4_K_M serves via OpenAI-compatible API with correct tool-calling chat template. All candidate GGUFs downloaded. |
| TV2-003 | Build benchmark harness — benchmark-model.sh, SQLite schema, scoring logic | done | — | low | code | `benchmark-model.sh <gguf>` runs throughput tests at 4 context lengths and quality battery, writes results to SQLite scorecard. Script handles thermal cooldown between runs. |
| TV2-004 | Author quality test battery — 21 prompts across 5 categories with expected outputs and scoring rubrics | done | — | low | research | 21 prompts authored (5 tool-call, 5 routing, 5 structured-output, 3 multi-step, 3 guardrail). Each has expected-output schema. At least one model validates the harness end-to-end. |

## Phase 1: Platform Evaluation

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|-------------------|
| TV2-005 | Install + configure Hermes Agent on Mac Studio — Telegram, local LLM endpoint | done | TV2-002 | medium | code | Hermes running. Responds to Telegram messages. Connected to local LLM via OpenAI-compatible API (validates A1). |
| TV2-006 | Evaluate Hermes against 11 criteria (§12.1) | done | TV2-005 | medium | research | Scorecard with 1–5 rating per criterion. Documented test methodology for each. No criterion below 3/5 required for GO. |
| TV2-007 | 72-hour Hermes stability soak test | done | TV2-005 | low | research | Nemotron 71h (100% load success, zero unplanned restarts, memory plateauing 31.4/96GB). Kimi 48h on v0.6.0 (consistent delivery, zero gateway errors, think-block fix shipped). v0.4.0→v0.6.0 upgrade resolved cron persistence and tool-call formatting. |
| TV2-008 | Hermes go/no-go decision | done | TV2-006, TV2-007 | high | decision | **GO.** Average 3.70/5, minimum 3/5 (both pass). Operator approved 2026-04-01. Decision document: design/hermes-go-decision.md. Conditions: think-block patch required (#4467), OpenRouter streaming stall mitigation, Hermes memory capacity monitoring. Phase 3 fully unblocked. |

## Phase 2: Local LLM Evaluation

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|-------------------|
| TV2-009 | Qwen3.5 27B setup — llama.cpp server with correct chat template, verified tool-calling | done | TV2-002 | medium | code | Server responds to tool-calling requests with parseable output. NOT using Ollama pipeline (C4). Chat template explicitly configured. |
| TV2-010 | Benchmark harness — Qwen3.5 27B Q4_K_M + Q6_K | done | TV2-003, TV2-004, TV2-009 | medium | research | SQLite scorecards for both quants. Throughput at 4 context lengths, quality scores, context ceiling. Both evaluated against `viable` thresholds. Run with soak test paused or with soak load documented as baseline noise. Context ceiling tests run in isolation. |
| TV2-011 | Benchmark harness — GLM-4.7-Flash + Nemotron + Qwen3.5 35B MoE + Qwen3-Coder | done | TV2-003, TV2-004, TV2-002 | medium | research | SQLite scorecards for all candidates. Same battery as TV2-010. Comparative data against Qwen3.5 27B. Soak test paused for clean results. |
| TV2-012 | MLX backend comparison | skipped | TV2-003, TV2-004, TV2-009 | medium | research | SKIPPED: Nemotron exceeds all throughput thresholds by >50% (57-86 tok/s vs 20/10 thresholds). Skip condition met. |
| TV2-013 | Orchestration tests — Nemotron Cascade 2 (7 tests + needle-in-haystack) | done | TV2-011 | medium | research | 7 orchestration tests + 3 needle probes. CRITICAL gates (1,7): 5/5. Avg correctness: 4.0/5 (at threshold). No test below 3. Needle: 3/3 PASS (32K/64K/128K). Known pattern: model defers to tool calls instead of final answer on eval tasks (orch-05, orch-06). 128K needle answer leaked to reasoning_content only. |
| TV2-014 | Orchestration tests — comparative (if needed) | skipped | TV2-011 | medium | research | SKIPPED: Single model selected (Nemotron). No comparative needed. |
| TV2-015 | Single vs. dual model decision | done | TV2-010, TV2-011 | medium | decision | Single model: Nemotron Cascade 2 30B-A3B Q4_K_M. Decision document: design/model-selection-decision.md. Dual stack not justified — no candidate combination meets threshold. |
| TV2-016 | Local LLM go/no-go decision | done | TV2-013, TV2-015 | high | decision | CONDITIONAL GO: Nemotron for Tier 1+2, cloud escalation mandatory for Tier 3 (guardrails). Production serving profile v1 frozen. Decision document: design/local-llm-decision.md. Conditional on: soak test pass, Gate 3 architecture, system prompt fix for eval-class tasks. |

## Pre-Phase 3: Integration Validation

**Gated by TV2-008 (Hermes GO) and TV2-016 (Local LLM GO). Bridge between evaluation and architecture.**

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|-------------------|
| TV2-041 | Joint Hermes + local model integration test | done | TV2-008, TV2-016 | medium | research | One complete dispatch cycle: Hermes sends request to selected local model, model returns structured output, Hermes parses response correctly. End-to-end latency measured. If fails, integration gap discovered before Phase 3 design. |

## Phase 3: Architecture Design

**Gated by TV2-041 (integration validated) — must know platform and model stack work together.**

### Core Architecture

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|-------------------|
| TV2-017 | State machine design — contract lifecycle + Ralph loop + three-gate integration | done | TV2-008, TV2-016 | high | research | State diagram exists with all transitions defined. Mid-loop escalation behavior specified. Contract immutability rules documented. State machine covers: dispatch → execute → evaluate → promote/dead-letter. Validated against 3 scenarios: mid-loop escalation, contract timeout during promotion, concurrent contracts targeting same path. |
| TV2-018 | Confidence-aware escalation — three-gate hybrid detailed design | done | TV2-008, TV2-016, TV2-017 | high | research | Three gates defined (deterministic boundary, structured confidence, risk policy). Gate 3 (AD-009) validated: tests confirm credential, destructive, and external-comms tasks deterministically force escalation regardless of confidence. Confidence field schema specified. Calibration procedure documented. Evaluator perspective separation addressed. Validation test plan exists. Validated against 3 scenarios: confidently-wrong local model decision, credential-touching task, first-instance task class — each traced through all three gates. |
| TV2-019 | Contract schema — finalize YAML, versioning, validation tooling | done | TV2-017 | medium | code | Complete YAML schema (closed per Amendment V). Three check types with blocking/advisory semantics. Semver versioning with migration path. Validation tooling design (7 check categories). 3 example contracts (V1 deterministic, V3 judgment, V2 side-effecting). Cross-references to TV2-017/018/023. Amendments T/U/V/W/X integrated. design/contract-schema.md (679 lines). |

### Execution Architecture

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|-------------------|
| TV2-020 | Ralph loop implementation spec | done | TV2-019 | medium | research | 10 sections, 454 lines. Iteration budget enforcement (runner-tracked, immutable contracts). Cumulative failure context with compaction at 2K tokens. Hard stop: runner evaluates, executor cannot self-terminate. Partial completion: ESCALATED with partial_results. Lenient parsing pipeline for return envelope. Convergence tracking integration with Gate 4. Sequence diagram. design/ralph-loop-spec.md. |
| TV2-021a | Draft service interfaces from migration inventory | done | TV2-001 | medium | research | Draft interface for each service: inputs, outputs, monitoring surfaces, overlay requirements, rollback procedure, idempotency requirements (run ID convention, dedup semantics, overlapping-run prevention). Can start during evaluations. |
| TV2-021b | Finalize service interfaces with contract templates | done | TV2-021a, TV2-008, TV2-016, TV2-019 | medium | research | 1550 lines. All 16 services (14 + 3 Scout sub-services) finalized. Contract templates valid against v1.0.0 schema (8 V1, 4 V2, 4 V3). Executor assignments: 12 Tier 1, 4 Tier 3 with named fallbacks. Token budgets: ~346 invocations/day, 87% local, baseline $9.90/month. Email triage dominates cloud cost ($5.76/month). design/service-interfaces.md. |
| TV2-022 | Staging/promotion lifecycle design | done | TV2-019 | high | research | 681 lines. Staging directory lifecycle, SQLite write-lock table (per-file, PK path+contract_id), SHA-256 hash conflict detection, 12-step atomic promotion with crash recovery annotations at every step, manifest-driven resume. Rollback: `.rollback/` with 24h window, operator-initiated. Write-locks (ROUTING) vs promotion lock (flock, PROMOTING) clearly separated. 3 scenario walkthroughs. design/staging-promotion-design.md. |

### Infrastructure Architecture

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|-------------------|
| TV2-023 | System prompt architecture (§10b) | done | TV2-008, TV2-013, TV2-016 | medium | research | Prompt composition spec with: layer ordering (header/service/overlay/vault/failure), token budgets per layer (16K local, 32K frontier, max 3 overlays), compaction priority order. |
| TV2-024 | Credential management design | done | TV2-008, TV2-016, TV2-018, TV2-021b | medium | research | macOS Keychain single store (`tess.v2.{service}.{type}` naming). Runner-mediated retrieval, env var injection per session. OAuth refresh LaunchAgent (900s check, 600s threshold). Mid-contract expiry: tool-class failure, refresh+retry, circuit breaker at 3 failures/hour. Audit log (type only, never values). Three-layer never-in-vault enforcement. Gate 3 forces credential mutations through escalation. 23-entry credential inventory. design/credential-management.md. |
| TV2-025 | Observability infrastructure design (§18) | done | TV2-021b | medium | research | 508 lines. `~/.tess/logs/` with 7 log files + per-service logs. Symlink convention (`_tess/logs/` → external). Health digest template (8 sections, daily 06:00, vault + Telegram). Dead-letter queue: `~/.tess/dead-letter/`, 14 entry conditions, YAML schema, CLI review interface. 12-surface alert thresholds with fatigue prevention. Contract ledger + escalation log schemas. design/observability-design.md. |
| TV2-042 | Local model runtime failover design | done | TV2-016 | medium | research | Health check frequency and timeout defined. Automatic restart policy (attempt once, then fallback). Fallback mode: Tier 1+2 route to OpenRouter during outage. Duration limit: >4h down → alert Danny, reduce to critical services only. Cost impact of 24-hour outage modeled. LLM server included in soak test monitoring. |

### Operational Policies

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|-------------------|
| TV2-026 | Escalation storm / load shedding policy | done | TV2-018 | medium | research | 2-of-4 trigger detection (>30% escalation rate, >$2/hr cost, >20% low-confidence, >25 queue depth over 2h window). Three-level shedding (L1 advisory shed → L2 queue triage → L3 dispatch suspend). Gradual recovery with 15min hold per level. Danny escalation at 4h persistence. Cross-system interactions with TV2-027/028/042. design/escalation-storm-policy.md (287 lines). |
| TV2-027 | Queue poisoning / scheduler fairness policy | done | TV2-017 | medium | research | 4 priority classes (critical/standard/background/deferred). Per-class max-age (15min–72h). Pathological contract detection (retry loop, resource overconsumption, time-in-system). 40% per-service slot cap, round-robin, age-based priority boost. Dead-letter queue with 9 entry conditions and retention policy. design/queue-fairness-policy.md (243 lines). |
| TV2-028 | Bursty cost model refinement | done | TV2-018 | low | research | Steady-state $10.80–17.10/month. Worst-case single contract $0.79 (V3 full escalation + quality retry). 3-tier daily alerts ($1.50/$3.00/$5.00). Hard daily cap $5.00, monthly $75. Budget cap enforcement: suspend cloud dispatches, local-only operation. Escalation chain overhead ~6% vs direct Tier 3. design/bursty-cost-model.md (284 lines). |
| TV2-029 | Confidence calibration drift monitoring plan | done | TV2-018 | low | research | 7-day rolling window drift detection (15–25pp thresholds). 6 re-calibration triggers (automatic/manual/scheduled). 5-step procedure: battery → production comparison → threshold update → dry-run → deploy. DEGRADED-LOCAL data segregated. Alert taxonomy mapped to §7.5. design/calibration-drift-plan.md (224 lines). |
| TV2-030 | Value density metric design | done | TV2-025 | low | research | Revenue-weighted completions / total completions (7-day rolling primary). 14 services classified (5 maintenance/0.0, 5 mixed/0.3-0.6, 6 revenue/1.0). Stagnation thresholds calibrated to heartbeat volume: <10% warning, <8% for 3 days alert. Health digest integration. Observational only — surfaces signal, doesn't re-prioritize. design/value-density-metric.md. |

## Phase 4: Migration

**Gated by M4 completion. Sequence per §14.2: low-risk → critical.**

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|-------------------|
| TV2-031a | Initialize external repo + project structure | done | TV2-008, TV2-019 | low | code | Git repo at agreed path. Base project structure. repo_path recorded in project-state.yaml. |
| TV2-031b | Implement contract runner + Ralph loop controller | done | TV2-031a, TV2-019, TV2-020 | medium | code | Contract runner loads contract YAML, dispatches to executor, enforces iteration budget and hard stops. Ralph loop controller injects failure context between iterations. Passes on sample contract. |
| TV2-031c | Implement staging/promotion engine | done | TV2-031a, TV2-022 | high | code | Staging directory lifecycle (create/cleanup). Write-lock table. Hash-based conflict detection. Atomic promotion. Passes concurrent promotion collision tests from TV2-022 design. |
| TV2-031d | Implement dispatch envelope validator | done | TV2-031a, TV2-023 | medium | code | Validates dispatch envelopes against §10b prompt architecture. Enforces token budgets per layer. Rejects malformed envelopes. Passes on sample envelopes. |
| TV2-032 | Migrate heartbeats | done | TV2-031b, TV2-031c, TV2-031d, TV2-021b | low | code | Heartbeats running on new platform. Parallel run 48h. Zero missed signals. Timing within ±10% of OpenClaw cadence. Rollback tested: re-enable OpenClaw service within 5min. |
| TV2-033 | Migrate vault gardening | done | TV2-031b, TV2-031c, TV2-031d, TV2-021b | low | code | Vault gardening on new platform. Parallel run 48h. Same files processed, same transformations applied (diff comparison). Rollback tested. |
| TV2-034 | Migrate feed-intel pipeline | done | TV2-032, TV2-033 | medium | code | Feed-intel on new platform. Parallel run 72h. Classification accuracy ≥95% vs OpenClaw on sampled items. Zero data loss. Correct routing for all tier levels. Rollback tested. **GATE PASSED** (50h/72h early call): 210 contract executions (3 capture, 3 attention, 204 feedback), 0 soak-period failures. Same Node+SQLite = identical classification. Tier distribution confirmed. |
| TV2-035 | Migrate daily attention + overnight research | done | TV2-032, TV2-033 | medium | code | Both services on new platform. Parallel run 72h. Scheduling triggers at correct times. Output completeness ≥ OpenClaw (section-by-section comparison). Rollback tested. **GATE PASSED** (50h/72h early call): 105 contract executions (102 daily-attention, 3 overnight-research), 0 failures. Correct scheduling confirmed. Same underlying scripts = output parity. |
| TV2-036 | Migrate email triage | cancelled | TV2-034, TV2-035 | high | code | **CANCELLED 2026-04-10.** Operator decision: shutting down all automated email triage (both OpenClaw and Tess). Both LaunchAgents unloaded. |
| TV2-037 | Migrate morning briefing | cancelled | TV2-036 | high | code | **CANCELLED 2026-04-10.** Upstream dependency TV2-036 cancelled — morning briefing consumed email triage output, no longer viable without redesign. |
| TV2-043 | Migrate Opportunity Scout pipeline | done | TV2-034, TV2-035 | medium | code | All 3 Scout services (daily-pipeline, feedback-poller, weekly-heartbeat) on new platform. Parallel run 72h. Daily digest delivery at correct time. Feedback commands functional. Scoring parity ≥90% on sampled items. Rollback tested. **GATE PASSED 2026-04-15** after Nemotron truncation fix (ef93e1a: LIMIT 10, finish_reason guard): C1 3/3 clean runs Apr 13/14/15, digests delivered (5/3/1 items, tg msg 63/66/67), C2/C3 proven at Apr 12 eval, zero dead-letters post-fix. |
| TV2-044 | Migrate connections brainstorm | done | TV2-032, TV2-033 | low | code | Connections brainstorm on new platform. Parallel run 48h. Same output quality (manual review). Rollback tested. **GATE PASSED** (50h/48h): 3 runs, 0 failures, idempotency confirmed. |
| TV2-046 | Benchmark Gemma 4 models against Nemotron Cascade 2 | done | TV2-032, TV2-033 | low | research | **NO SWITCH.** 26B MoE: ties tool-call (1.0), loses throughput at 64K+ (69 vs 86 tok/s). 31B Dense: loses both (tool-call 0.8, throughput 2-4x slower). AD-012 confirmed. Decision doc: eval-results/gemma4-benchmark-2026-04-03.md. |

## Phase 4a: Vault Semantic Search (Amendment AA)

**Gated by TV2-047 (QMD index fix). Three parallel tracks. See `design/spec-amendment-AA-vault-semantic-search.md` for full design.**

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|-------------------|
| TV2-047 | Fix QMD index LaunchAgent — resolve PATH issue via launchd EnvironmentVariables, verify daily update runs | done | — | low | code | `com.crumb.qmd-index` completes with exit 0. QMD index freshness < 24h. Verified via `launchctl print` and index timestamp. |
| TV2-048 | Implement vault-search.sh — QMD wrapper with mode/limit params, output schema (path/title/score/excerpt/index_timestamp/low_confidence), logging to akm-feedback.jsonl, error handling, 3s/5s/10s timeout support | done | TV2-047 | low | code | Script returns valid output schema for hybrid/bm25/semantic modes. Error schema on QMD unavailable. Logs to akm-feedback.jsonl with trigger type. Handles zero-result and low-confidence cases. |
| TV2-049 | Register vault_search as Hermes orchestrator tool — tool config YAML, system prompt addition to orchestrator Layer 2, integration test (Tess calls tool, gets results) | done | TV2-048 | medium | code | Tess's orchestrator can call vault_search via Hermes tool-calling. Results parsed correctly. 3-call-per-triage limit enforced. Safety directive present in system prompt. |
| TV2-050 | Add `dispatch` trigger to knowledge-retrieve.sh — query construction from contract desc + search_hints, configurable budget param, fail-open on error, integration tests | done | TV2-047 | medium | code | `--trigger dispatch` produces knowledge brief from contract description + hints. Fail-open: non-zero exit → warning logged, empty brief returned. Budget param works. |
| TV2-051 | Integrate dispatch-time enrichment into contract runner — call knowledge-retrieve.sh during envelope assembly, inject into Layer 5 with file-path metadata for dedup, fail-open on error | done | TV2-050, TV2-031b, TV2-054 | medium | code | Runner calls enrichment script for contracts with `search_hints`. Enrichment injected into Layer 5 with surfaced file paths in metadata. QMD failure does not block dispatch. Contracts without `search_hints` behave exactly as before. |
| TV2-052 | Expose vault_search to Claude Code executor — tool definition in Layer 2 for Claude Code executor profile, overlap handling directive ("check Layer 5 before searching") | done | TV2-048 | low | code | Claude Code executor system prompt includes vault_search tool definition and overlap avoidance directive. Safety reference-material policy present. |
| TV2-053 | Proof case: connections-brainstorm — add search_hints to contract, validate dispatch enrichment quality, test orchestrator tool during evaluation, compare output with/without, test empty-result and low-confidence scenarios | done | TV2-051, TV2-049 | low | code | Enriched brainstorm output references vault content beyond the 2 static read_paths. Orchestrator evaluation uses vault_search to verify claims. Empty-result behavior validated. Quality comparison documented. |
| TV2-054 | Add `search_hints` to contract schema (v1.1.0 minor bump) — field definition, validation constraints (max 5 items, ≤200 chars, operator-authored), migration note | done | TV2-019 | low | code | Schema updated. Validation rejects >5 items or >200 char hints. Existing contracts pass validation unchanged. Migration note documents backward compatibility. |
| TV2-055 | Proof case: interactive ad-hoc query — simulate Amendment Z book-scan scenario, Tess handles via orchestrator tool without Claude Code dispatch, validate quality and latency, test zero-result query | done | TV2-049 | low | code | Tess returns index-level synthesis from vault_search excerpts. No Claude Code dispatch required. Latency < 5s. Zero-result query returns appropriate "limited content" response. |

## Pre-Phase 4b: Scaling Evaluation

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|-------------------|
| TV2-045 | Paperclip integration spike — evaluate as role/coordination layer | done | TV2-031b | medium | research | **DEFER.** Stage 0 bail: no generic adapter exists (Bash/HTTP/webhook). All 7 adapters are runtime-specific (claude-local, codex-local, etc.). tess-v2's contract runner doesn't fit any adapter shape. Integration requires custom adapter → paradigm mismatch. Dashboard is the only genuine add; everything else overlaps or conflicts. No scaling triggers firing. Decision document: design/paperclip-spike-decision-2026-04-12.md. Next state-check: ~2026-07-12. |

## Phase 4b: Validation & Cutover

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|-------------------|
| TV2-056 | Apply scout wrapper pattern to 8 remaining services | done | TV2-043 | medium | code | Surfaced by TV2-038 Phase 2 (2026-04-15): 9 of 15 migrated services have contracts validating stale Apr 2–5 artifacts because wrappers only write to stdout (captured as `execution-log.yaml`), not to the per-service named file the contract checks. Scout's TV2-043 remediation (Apr 9) established the fix pattern: wrappers use `LOG_FILE="${STAGING_PATH:-.}/{name}.yaml"` and `cat <<YAML \| tee "$LOG_FILE"`. Applied to 8 wrappers: run-vault-check.sh, vault-gc.sh, fif-capture.sh, fif-attention.sh, fif-feedback-health.sh, daily-attention.sh, overnight-research.sh, connections-brainstorm.sh. Also fixed overnight-research NO_OP regex (case-sensitive miss on "no reactive items"). Strengthened 8 contracts with `content_contains` and `content_not_contains` checks. Skipped TV2-036 email-triage (cancelled). Commits: `d8bad52` (initial propagation) + `02be7b7` (must-fix follow-up: ANT-F5 tier_distribution in fif-attention paused heredoc; ANT-F1+CDX-F1 tee-failure masking in run-vault-check.sh). Code review: `Projects/tess-v2/reviews/2026-04-15-code-review-manual.md` (Opus 4.6 + Codex GPT-5.3, 17 findings total, 0 CRITICAL, 2 must-fix applied, 3 should-fix deferred). Tag: `code-review-2026-04-15-tv2-056`. Blocks TV2-038 Phase 5 re-collection. |
| TV2-038 | Full parallel operation validation | todo | TV2-043, TV2-044, TV2-056 | high | research | All migrated services running on both platforms ≥48h. Comparison report per service. Cost tracking active — pro-rated cost ≤$75/month ceiling. ≥70% of routing decisions at Tier 1+2 (local/free). No missed outputs. Vault authority verified: no writes bypass staging/promotion. Evaluator separation verified: executors cannot self-promote. State reconciliation: no orphaned jobs, state artifacts, or credential gaps vs OpenClaw. Migration inventory revalidated against running launchd services — any services added since TV2-001 cataloged and either migrated or explicitly deferred. *(TV2-037 dependency removed — email triage cancelled 2026-04-10. TV2-056 dependency added 2026-04-15: Phase 2 re-collection must use strengthened contracts.)* |
| TV2-057a | State-machine semantic fix (Class C) | in_progress | TV2-038 | medium | code | Per `tv2-057-promotion-integration-note.md` §4, §6. Add `COMPLETED` to `TerminalOutcome` in `ralph.py`. Add contract classification predicate — **placeholder implementation: hardcoded Class C service-name allowlist with explicit `# TODO(TV2-057b): replace with canonical_outputs schema field check once 057b lands`**; predicate is designed as a seam so 057b swaps the implementation without callsite changes. Runner transitions Class C STAGED → COMPLETED immediately with no-op promotion; no writes to canonical vault paths, no lock acquisition, no `PromotionEngine` invocation. Class A (622 rows) and test (56 rows) untouched by live behavior. Tests: unit test for STAGED→COMPLETED transition on Class C, regression test that Class A still lands STAGED, integration test running a Class C contract end-to-end. **Backfill sequencing (operator-directed 2026-04-15):** historical backfill migration script (bulk update 5787 rows: 5763 Class C + 24 Class B merged per note §5 → `outcome='completed'`) ships as a **separate, reviewable commit** and is **held from execution until TV2-038 Phase 5 re-collection completes (earliest 2026-04-17 18:00Z)** — prevents Phase 5 gate verdicts from being computed against post-backfill data. Backfill commit is landed in the same PR but not run until Phase 5 closes; migration script tested against a DB copy before live run. *Independently shippable before any promotion code — see note §1.4.* **Status 2026-04-15:** Code landed in commits `bd0482a` (classifier + COMPLETED enum + downgrade + tests, 455 pass) and `037c363` (backfill script + runbook). Backfill HELD pending TV2-038 Phase 5 close (≥2026-04-17 18:00Z). Allowlist corrected vs brief: `fif-feedback`, `scout-feedback` (not `-health`/`-poller` suffixes). Backfill row count 5807 (preview validated against DB copy, sentinel-marked). Runbook: `Projects/tess-v2/design/tv2-057a-backfill-runbook.md`. Will close to `done` after backfill executes. |
| TV2-057b | Schema + Amendment landing | todo | TV2-057a | medium | design+code | Resolve Option C C1-vs-C2 inheritance sub-question (note §2.2): runtime resolution at contract-load vs. generation-time bake-in. Add `canonical_outputs` structured field to `service-interfaces.md` for Class A services (vault-health, daily-attention, connections-brainstorm). Update `contract.py` schema accordingly. Close Open Question #1 in `staging-promotion-design.md` §13. Land §3.4.2 Amendment to `staging-promotion-design.md` with explicit dispatch-modes section per note §3. Audit deliverable: confirm/refute which Class A wrappers currently write directly to canonical paths bypassing `_staging/` (note §4.4 landmine); `vault-health` → `vault-health-notes.md` is the first audit target. Result documented as input to TV2-057d scope. No runtime behavior change. |
| TV2-057c | Write-lock acquisition at run-entry (Class A only) | todo | TV2-057b | medium | code | Wire `WriteLockTable.acquire_locks()` into `_cmd_run` before Ralph loop, for Class A contracts only. Use `BEGIN IMMEDIATE` transaction with all-or-nothing semantics per design §3.4. Resolve R1-vs-R2 retry sub-question (note §3.2.1): in-invocation spin-retry vs. exit-and-wait-for-next-cadence. Lock-denied handled as retryable per chosen model. Locks released on all terminal paths (STAGED-to-promotion, ESCALATED, DEAD_LETTER). Tests: contention between concurrent LaunchAgent invocations, hash-at-lock-time capture, lock-denied retry behavior matches chosen semantics, overlap detection via GLOB. No promotion yet. |
| TV2-057d | Promotion wiring for Class A (per-service migration) | todo | TV2-057c | high | code | **Not a blanket flip.** Per note §6.D and §4.4 landmine. Likely itself milestone-shaped: per-service (vault-health, daily-attention, connections-brainstorm) — audit current write path, stop direct-to-canonical writes where applicable, ensure staging artifact is produced, wire `build_manifest()` + `promote()` into post-STAGED path, implement caller responsibilities (§5.2 steps 9–12: ledger COMPLETED update, lock release, staging cleanup), verify parity with pre-change behavior for ≥2 cadence cycles, cut over. Handle `PromotionResult.success=False` with `conflicts[]` — transition to QUALITY_FAILED or abort per §4.5. Rollback procedure documented before any cutover. `vault-health` first per audit in TV2-057b. |
| TV2-057e | Crash-recovery subcommand + startup sweep | todo | TV2-057d | medium | code | `tess recover` subcommand wrapping `PromotionEngine.recover_promotion()`. Iterates in-progress manifests in `_staging/*/.promotion-manifest.json`, dispatches to recovery per §8.1. Decide invocation model: startup sweep (every `tess run` entry runs a cheap scan) vs. periodic LaunchAgent (`com.tess.v2.promotion-recovery`) — rationale documented. Tests: crash-injection at each phase transition (pending, backing_up, copying, verifying, completed) confirms idempotent resume. Orphaned manifest detection + TTL cleanup per §7.4. |
| TV2-057f | Class A pre-promotion-era backfill disposition | todo | TV2-057d | low | code | Per-service investigation of 622 Class A staged rows (vault-health 13, daily-attention 596, connections-brainstorm 13). For each row: does canonical destination exist and match any `_staging/` remnant? Where safe, update `outcome='staged'` → `outcome='completed'` with pre-promotion-era annotation. Where canonical state is ambiguous or staging remnant is present, retain as `staged` with annotation. No bulk flip — per-service. Audit log written to `Projects/tess-v2/design/tv2-057f-backfill-audit.md`. Separate from TV2-057a backfill (which was bulk-safe because Class C rows had nothing to promote). |
| TV2-039 | Production cutover decision | todo | TV2-038 | high | decision | Decision document. All services pass validation. Rollback procedure documented and tested. Danny approves. Cost under $50/month target. |
| TV2-040 | OpenClaw decommission for migrated services | todo | TV2-039 | high | code | Migrated OpenClaw services disabled. New platform sole operator. No service interruption >30min for non-critical, zero interruption for critical. Includes migrating needed `_openclaw/` vault directories to `_tess/` (state files, scripts, inbox, research output — inventory during execution). |

## Summary

| Phase | Tasks | Risk Profile |
|-------|-------|-------------|
| Phase 0: Foundation | TV2-001 – TV2-004 (4) | Low |
| Phase 1: Platform Eval | TV2-005 – TV2-008 (4) | Medium, 1 high (go/no-go) |
| Phase 2: LLM Eval | TV2-009 – TV2-016 (8) | Medium, 1 high (go/no-go) |
| Pre-Phase 3: Integration | TV2-041 (1) | Medium |
| Phase 3: Architecture | TV2-017 – TV2-030, TV2-042 (16) | Mixed — 3 high + failover design |
| Phase 4: Implementation + Migration | TV2-031a–d, TV2-032 – TV2-037, TV2-043 – TV2-044 (12) | Escalating (low → high), scaffold high |
| Phase 4a: Vault Semantic Search | TV2-047 – TV2-055 (9) | Low–medium, parallelizable |
| Pre-Phase 4b: Scaling Eval | TV2-045 (1) | Medium |
| Phase 4b: Cutover | TV2-038 – TV2-040, TV2-056, TV2-057a–f (10) | High |
| **Total** | **64 tasks** | |

## Tier-2 Peer Review Item Mapping

All 9 Tier-2 items from external review round 2 are addressed:

| Tier-2 Item | Task |
|-------------|------|
| State machine integration | TV2-017 |
| Value density metric | TV2-030 |
| Escalation storm / load shedding | TV2-026 |
| Queue poisoning / scheduler fairness | TV2-027 |
| Confidence calibration drift | TV2-029 |
| Evaluator perspective separation | TV2-018 (folded into escalation design) |
| Bursty cost model | TV2-028 |
| Contract schema versioning | TV2-019 (versioning included) |
| Task graph dependency corrections | Addressed by this action plan (refined dependency graph) |
