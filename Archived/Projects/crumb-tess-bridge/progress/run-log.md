---
type: run-log
project: crumb-tess-bridge
status: active
created: 2026-02-19
updated: 2026-02-25
---

# Run Log — crumb-tess-bridge (Phase 2)

> **Phase 1 history:** Sessions 1-19 archived in `run-log-phase1.md`
> (SPECIFY, PLAN, TASK, Phase 1 IMPLEMENT — 16 tasks, 325 tests, 6 peer reviews).
> Phase 2 begins at Session 20 with dispatch protocol implementation.

## Session 24 — 2026-02-25

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, all 37 tasks done
- run-log.md (Phase 2) — sessions 20-23
- code-review-config.md — Tier 1 local model config
- Git diff: code-review-tier2-2026-02-24..HEAD (16 files, +2172/-17)
- 4 source documents

### Phase Transition: IMPLEMENT → DONE
- Date: 2026-02-25
- IMPLEMENT phase outputs: 37 tasks complete (CTB-001–CTB-037), 897 tests green, 8 peer review rounds, 2 code reviews, bridge operational in production since 2026-02-22
- Compound: Walking skeleton approach validated for dispatch protocol (single-stage→multi-stage smooth); quick-capture .md inbox pattern reusable (3rd consumer triggers consolidation); Tier 1 code review noise profile noted (~80% noise, useful for atomicity/existence checks); test/code desync on schema evolution (required→optional). No patterns promoted — insufficient data points.
- Context usage before checkpoint: low (fresh session)
- Action taken: none
- Key artifacts: N/A (project closing)

### Test Gate Fix

`test_stage_runner.py:855` — `test_next_stage_missing_subfields` expected `context_files` to be required, but commit `59a1bcd` made it optional per §4.3/§4.6. Test updated to assert `context_files` is NOT in violations. 62 stage_runner tests green.

### Code Review (Tier 1)
- Scope: code-review-tier2-2026-02-24..HEAD — CTB-029/030/031/032/033/034/035/036 + stage_runner fixes (16 files, +2172/-17)
- Chunked: 2 chunks (Tess 1306 lines, Crumb+watcher 1186 lines)
- Model: devstral-small-2
- Chunk 1: Latency 94s | Parse: clean | Raw findings: 0 critical, 1 significant, 14 minor
- Chunk 2: Latency 36s | Parse: clean | Raw findings: 1 critical, 4 significant, 7 minor (original prompt timed out at 600s/65K ctx; succeeded with condensed prompt at 32K)
- **Merged findings after dedup and hallucination filtering:**
  - [F1] SIGNIFICANT: capture-processor.js — `appendReadingList` uses `atomicWriteText` for creation but `fs.appendFileSync` for appends. Inconsistent atomicity. Low risk (reading list, single-writer).
  - [F2] SIGNIFICANT: capture-processor.js — `moveToProcessed` uses `renameSync` without existence check. Silent overwrite if two captures share a timestamp-second. Near-zero probability.
  - [F3] MINOR: capture-processor.js — YAML key regex `/^([a-z_]+):/` won't match hyphenated keys. Works now (Tess writes underscore keys only) but fragile if format changes.
  - [F4] MINOR: test_watcher.py — Identical 15-line setUp in `TestDispatchDuplicateDetection` and `TestNonBridgeJsonShortCircuit`. DRY candidate.
  - [F5] MINOR: capture-processor.js — Magic number `100` for body truncation in reading-list snippet.
- **Discarded (false positives / noise):** 22 findings — F1-chunk1 (tags null already guarded), F3-chunk1 (off-by-one incorrect), F6-chunk2 (isSenderAllowed is backward-compatible), F9-chunk2 (CRITICAL severity inflation — internal functions always receive parseCapture output), documentation nits, over-engineering suggestions for internal code paths.
- Action: no action needed — no must-fix items. Two SIGNIFICANT findings are acknowledged low-risk tradeoffs.

## Session 23 — 2026-02-25

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, active_task: null
- tasks.md — CTB-032/033/034/036 pending (quick-capture)
- capture.js (Tess-side) — new module for CTB-032
- file-conventions.md — type taxonomy for CTB-033
- session-startup.sh — capture detection for CTB-034
- quick-capture-scope.md — design doc (read for CTB-036 context)
- bridge-cli.js, atomic-write.js, constants.js — existing Tess infra
- 8 source documents

### CTB-032: OpenClaw quick-capture skill definition — COMPLETE

**Deliverables:**
- `src/tess/scripts/lib/capture.js` — `captureFilename()` (UTC, `capture-YYYYMMDD-HHMMSS.md`), `buildCaptureFrontmatter()`, `buildCaptureContent()`, `validateCaptureParams()` (hints, domains, tags), `writeCaptureFile()` (atomic via `atomicWriteText`)
- `bridge-cli.js write-capture` — new CLI command: `--body`, `--hint`, `--domain`, `--tags`, `--source`
- `src/tess/quick-capture-skill.md` — skill definition with trigger patterns (save, capture, read-later, look-into, check-out, remember), hint guidance, procedure steps

**Tests:** 39 new (6 filename, 9 frontmatter, 4 content, 13 validation, 3 filesystem write, 4 constants).

### CTB-033: Vault taxonomy update — COMPLETE

- `quick-capture` added to type taxonomy table in `_system/docs/file-conventions.md`
- vault-check has no type allowlist — validates presence only, no script change needed

### CTB-034: Session startup capture check — COMPLETE

- `session-startup.sh` extended with capture inbox scan: detects `capture-*.md` in `_openclaw/inbox/`
- Structured data: `captures_pending` count + `captures_pending_items` (filename, first body line, hint)
- Startup summary: `**Captures:** N pending from Tess` (conditional, only when count > 0)
- Tested with sample capture file: detection, hint extraction, zero-capture clean output

### CTB-036: Capture processing procedure — COMPLETE

**Deliverables:**
- `src/crumb/scripts/lib/capture-processor.js` — 6 functions:
  - `parseCapture()` — frontmatter extraction, URL detection, structured output
  - `routeFile()` — `file` hint: writes to `_inbox/` with frontmatter for inbox-processor
  - `appendReadingList()` — `read-later` hint: checkbox entry in `_system/reading-list.md` (creates with frontmatter if missing)
  - `prepareResearchBrief()` — `research`/`review` hint: structured brief for Claude's interactive processing
  - `moveToProcessed()` — moves capture to `.processed/`
  - `purgeOldProcessed()` — purges captures >30 days (only `capture-*.md`, ignores bridge files)

**Tests:** 27 new (5 parse, 4 route-file, 5 reading-list, 4 research-brief, 4 move, 5 purge).

### Session summary

Four quick-capture tasks completed (CTB-032/033/034/036). **All 37 tasks are now done.** Test totals this session:
- 39 JS capture tests (new, Tess-side)
- 27 JS capture-processor tests (new, Crumb-side)
- 88 JS schema tests (regression clean)
- 26 JS integration tests (regression clean)
- All 9 Crumb-side test suites green

**Compound:** The quick-capture `.md` pattern (write markdown to shared inbox, detect by glob at startup, process interactively) is reusable beyond bridge captures — any cross-agent staging can use this pattern. The x-feed-intel pipeline already does this with `feed-intel-*.md`. Consolidation candidate if a third consumer emerges.

**Project status:** 37/37 tasks complete. All Phase 1, Phase 2 dispatch, deferred hardening, persistent service, and quick-capture milestones done. Project is ready for DONE phase transition pending user decision.

## Session 22 — 2026-02-25

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, active_task: null
- tasks.md — CTB-029/030/031/035 open, CTB-032-036 quick-capture pending
- bridge-watcher.py — Config class, dispatch routing, kqueue daemon
- echo-formatter.js — Telegram formatting (HTML + Markdown)
- outbox-watcher.js — outbox polling, response/status/escalation detection
- bridge-cli.js — Tess-side CLI commands
- bridge-processor.js — Crumb-side request processing
- constants.js — shared constants and sender allowlist utility
- 8 source documents

### CTB-030: .processed-ids Set optimization — COMPLETE

**Problem:** Duplicate detection via O(n) file scan (`processedIds.split('\n').includes(requestId)`) on every request.

**Deliverables:**
- `ProcessedIdSet` class in bridge-watcher.py — loads `.processed-ids` into Python `set` on startup
- `contains()` — O(1) lookup; `record()` — adds to set + appends to file; `reload()` — re-reads after compaction
- New step 0 in `dispatch_file()` — in-memory duplicate check before outbox/kill-switch/rate-limit/flock/subprocess
- Duplicate files moved to `.processed/` without wasting rate-limit budget
- All raw file-append sites in watcher upgraded to use `processed_ids.record()` when available
- Backward-compatible: `processed_ids=None` default preserves existing callers

**Tests:** 22 new tests (14 ProcessedIdSet unit, 2 dispatch integration, 1 outbox-skip, 5 existing). Total: 54 watcher tests.

### CTB-035: Watcher defensive fix — non-bridge JSON short-circuit — COMPLETE

**Problem:** Non-bridge JSON files in inbox (no `operation` field) wasted rate-limit budget and processor subprocess invocations.

**Deliverables:**
- Operation parsing moved before rate-limit check (step 2, was step 4)
- `operation is None` → file moved to `_openclaw/inbox/.unrecognized/` with warning log
- Invalid JSON also routed to `.unrecognized/` (parse failure returns None)

**Tests:** 5 new tests (missing operation, rate-limit preservation, invalid JSON, valid bridge JSON, empty JSON object).

### CTB-029: Telegram alerts relay — COMPLETE

**Problem:** Watcher writes alert JSON to `_openclaw/alerts/` on governance failures, but no Tess-side relay to Telegram.

**Deliverables:**
- `formatAlertMarkdown(alert)` in echo-formatter.js — handles both watcher alerts (`alert_code`) and dispatch governance alerts (`alert_type`). Shield emoji for governance, warning emoji for others.
- `checkAlerts()` in outbox-watcher.js — scans alerts dir, returns sorted `{filename, alert}` array
- `cleanupAlert(filename)` — removes alert file after relay
- `check-alerts`, `format-alert`, `cleanup-alert` CLI commands in bridge-cli.js

**Tests:** 6 echo-formatter tests (watcher alerts, governance alerts, edge cases), 7 outbox-watcher tests (empty dir, missing dir, sorted results, dotfile/non-json skip, malformed skip, cleanup, already-gone). Total: 83 formatter + 26 outbox-watcher tests.

### CTB-031: Production sender allowlist — COMPLETE

**Problem:** Bridge open to any Telegram user who discovers the bot. Previous A2 fix only supported single sender via `CRUMB_BRIDGE_ALLOWED_SENDER`.

**Deliverables:**
- `getAllowedSenders()` + `isSenderAllowed(senderId)` in constants.js — shared utility, `CRUMB_BRIDGE_ALLOWED_SENDERS` env var (comma-separated), empty = allow all
- Tess-side pre-inbox gate in `write-request` — rejects with `UNKNOWN_SENDER` before writing to inbox
- Crumb-side backstop in bridge-processor.js — replaces old single-sender `CRUMB_BRIDGE_ALLOWED_SENDER` check
- Error code upgraded from `INVALID_SENDER` to `UNKNOWN_SENDER` (consistent naming)

**Tests:** 10 new tests (6 getAllowedSenders, 4 isSenderAllowed). Existing processor integration test updated for new env var name and error code. Total: 88 schema + 20 processor tests.

### Session summary

Four deferred hardening tasks completed in one session. All test suites green:
- 54 Python watcher tests (27 new)
- 69 Python integration + E2E tests (unchanged, regression clean)
- 83 JS echo-formatter tests (6 new)
- 26 JS outbox-watcher tests (7 new)
- 88 JS schema tests (10 new)
- 20 JS processor integration tests (1 updated)
- 26 JS Tess integration tests (unchanged)
- 8 JS reject-subcommand tests (unchanged)

Remaining: CTB-032-036 (quick-capture lightweight capture path) — all pending.

## Session 21 — 2026-02-25

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, active_task: null
- persistent-dispatch-processing.md — design note (origin: x-feed-intel compound testing)
- tasks.md — CTB-029/030/031 open, CTB-032-036 quick-capture pending
- bridge-watcher.py — Config class, dispatch routing, kqueue daemon
- ai.openclaw.xfi.feedback.plist — reference for KeepAlive plist pattern
- 6 source documents

### CTB-037: Register bridge-watcher.py as persistent launchd service — COMPLETE

**Problem:** Dispatch processing required an active Crumb session. The watcher was running as a manual process (PID from Sunday) with no lifecycle management.

**Deliverables:**
- `~/Library/LaunchAgents/ai.openclaw.bridge.watcher.plist` — KeepAlive daemon
- Environment: PATH (includes `~/.local/bin` for claude), HOME, CRUMB_VAULT_ROOT
- Logs: `_openclaw/logs/watcher.{log,err}` (existing convention)
- `com.apple.provenance` xattr stripped before bootstrap

**Verification:**
- KeepAlive restart: SIGTERM → clean "stopped" → auto "starting" → kqueue watching (confirmed in logs)
- Single-process invariant: discovered and removed pre-existing `com.crumb.bridge-watcher` plist (dual-supervisor, spawning orphans on every kill)
- pgrep advisory: defers processing when interactive Claude session active

**Design note findings vs implementation:**
- `CRUMB_BRIDGE_USE_CLAUDE=1` — read and logged but never checked in dispatch logic. Phase 2 ops route to dispatch engine unconditionally. Not set in plist (cosmetic).
- `CRUMB_BRIDGE_PROCESS_TIMEOUT` — only applies to Phase 1 `_dispatch_node` subprocess calls. Phase 2 dispatch engine manages its own per-stage timeouts. Default 60s correct for Phase 1 ops.
- API key — Claude Code 2.1.56 uses subscription auth, no env var needed.

**Cleanup:** Removed `com.crumb.bridge-watcher.plist`, bootout'd old service, SIGKILL'd Sunday-era orphan process.

## Session 20 — 2026-02-22

### Context Inventory
- project-state.yaml — phase: IMPLEMENT
- progress-log.md — Phase 2 plan ready, CTB-017/018 ready
- action-plan-summary.md — M7 foundation, critical path
- dispatch-protocol.md — §2 (state machine, §2.3 transitions, §2.5 state file), §7 (brief), §10 (schema extensions)
- constants.js, schema.js, bridge-processor.js, operations.js — Phase 1 implementation
- bridge-watcher.py — dispatch routing
- 10 source documents total, extended tier (justified: parallel task execution needs full context)

### CTB-017: Phase 2 Schema Extensions — COMPLETE

**Deliverables:** 11 files modified

**constants.js:**
- `SCHEMA_VERSION` bumped `1.0 → 1.1`
- `PHASE_2_OPS` with 5 operations: `start-task`, `invoke-skill`, `quick-fix`, `escalation-response`, `cancel-dispatch`
- `DISPATCH_OPS` array for dispatch-triggering operations
- `BUDGET_FIELDS` constraints (max_stages 1-25, max_tool_calls 1-500, max_wall_time_seconds 1-3600, max_tokens 1-2000000)
- `UUIDV7_PATTERN`, `KEBAB_CASE_PATTERN`, `SKILL_NAME_PATTERN` regex constants

**schema.js:**
- `validateOperation()` checks both PHASE_1_OPS and PHASE_2_OPS
- `validateParams()` extended: budget object validation, answers array validation, files array validation
- `isDispatchOp()` function exported
- ASCII validation scoped to string values only (skips budget/answers/files complex types)

**bridge-processor.js:**
- Dispatch guard: Phase 2 ops → `OPERATION_REQUIRES_DISPATCH` error, file moved to .processed/, ID recorded

**operations.js:**
- Phase 2 risk tiers: start-task=high, invoke-skill=high, quick-fix=medium, escalation-response=medium, cancel-dispatch=medium

**echo-formatter.js:**
- Phase 2 operation display formatters

**Tests:** 55 new tests (308 → 363), 0 failures. Schema_version backward compatibility verified (1.0 requests still pass major version check).

### CTB-018: Dispatch State Module — COMPLETE

**Deliverables:** 2 new files

**dispatch_state.py** (`src/watcher/dispatch_state.py`):
- `DispatchState` class: create/load/transition/record_cancel_request/update_budget/to_dict
- `VALID_TRANSITIONS` set — all 13 rules from §2.3 + global kill-switch rule
- `TERMINAL_STATES` / `NON_TERMINAL_STATES` frozensets
- Atomic writes: tmp + `os.replace()`
- Escalation flow: pending_escalation with timeout (30 min default)
- Cancel recording: immediate intent without state change
- Budget consumption tracking
- Modified files deduplication

**crash_recovery_scan():** queued/running/stage-complete → failed (RUNNER_RESTART); blocked remains resumable
**cleanup_terminal_states():** 30-day retention, deletes expired terminal state files

**test_dispatch_state.py:** 82 tests covering all 15 test categories:
- Creation, load round-trip, all 13 valid transitions, invalid transitions (10), terminal immutability (6)
- Stage info recording, escalation flow, cancel recording, budget updates, modified files dedup
- Atomic writes (no tmp residue), crash recovery (8), cleanup (6), kill-switch rule (4), file not found

### Test Summary
| Suite | Tests | Status |
|-------|-------|--------|
| Node.js (schema, ops, processor, e2e, etc.) | 363 | PASS |
| Python dispatch_state | 82 | PASS |
| Python watcher unit | 34 | PASS |
| Python watcher integration | 10 | PASS |
| **Total** | **489** | **PASS** |

### Run-Log Rotation
- Archived sessions 1-19 → `run-log-phase1.md` (1489 lines, status: archived)
- Active run-log reset to session 20+ (Phase 2 only)
- Cross-reference header added to both files

### CTB-019: Brief Construction + Stage Prompt Builder — COMPLETE

**Deliverables:** 2 new files

**brief_builder.py** (`src/watcher/brief_builder.py`):
- `build_brief()` — constructs §7.1 briefs from request params
  - Operation-specific: start-task reads tasks.md for AC, invoke-skill uses args, quick-fix uses description
  - Budget defaults per operation (10/100/600/500k or 3/30/180/500k for quick-fix)
  - Hard cap enforcement: max_stages=25, max_wall_time_seconds=3600 (silently clamped)
  - Advisory cap: tool_calls=500, tokens=2000000 (clamped, tracked not enforced)
  - Partial budget override merges with defaults
- `build_system_prompt()` — Layer 1 (--append-system-prompt), safety directives only
  - 5 exact safety directives per §4.2, budget remaining, kill-switch status
  - **Zero user-supplied content** — structurally guaranteed by function signature
- `build_user_prompt()` — Layer 2 (--print argument), contains untrusted content
  - Brief section (trusted, human-readable)
  - Previous stage context (UNTRUSTED framing, summaries + handoff per stage)
  - Next stage instructions (UNTRUSTED, "evaluate critically" warning)
  - Output format requirement (stage output + transcript paths)
  - Conditional sections: omits previous stages on stage 1, omits next_stage_instructions if absent

**test_brief_builder.py:** 32 tests:
- Brief construction (14): all 3 operations, budget overrides, hard caps, advisory caps, AC extraction, fallback intent, scope correctness, unknown op
- System prompt (5): safety directives, dispatch_id, budget, kill-switch, no untrusted content
- User prompt (7): stage 1/2 structure, UNTRUSTED framing, conditional sections, output paths
- Injection separation (3): system prompt isolation, previous stage isolation, instructions isolation
- Security-critical: adversarial payloads verified to stay in user prompt only

### Test Summary (Session 20 cumulative)
| Suite | Tests | Status |
|-------|-------|--------|
| Node.js | 363 | PASS |
| Python brief_builder | 32 | PASS |
| Python dispatch_state | 82 | PASS |
| Python watcher unit | 34 | PASS |
| Python watcher integration | 10 | PASS |
| **Total** | **521** | **PASS** |

### CTB-020: Stage Runner + Output Validation — COMPLETE

**Deliverables:** 2 new files

**stage_runner.py** (`src/watcher/stage_runner.py`):
- `compute_governance()` — Python equivalent of governance.js: sha256(CLAUDE.md)[:12] hash + last-64-char canary
- `StageRunner` class — 8-step run_stage pipeline:
  1. Pre-spawn governance check
  2. Spawn `claude --print` (list args, stdin piping, no shell=True)
  3. Timeout handling (subprocess.TimeoutExpired → StageTimeout)
  4. Read stage output from disk (`{dispatch_id}-stage-{N}.json`)
  5. Schema validation (§4.3): required fields, status enum, summary ≤500, status-dependent fields
  6. Policy validation (§4.6): instructions ≤4000 ASCII-only, context_files no traversal/sensitive paths, handoff ≤8KB
  7. Governance verification (§9.1): hash + canary comparison, alert on mismatch
  8. Return validated dict
- `validate_schema()` — all §4.3 required fields, status-dependent checks (next_stage/escalation/error)
- `validate_policy()` — §4.6 mechanical checks (length, ASCII, path traversal, sensitive paths, handoff size)
- `verify_governance()` — writes structured alert JSON to `_openclaw/alerts/` on mismatch, raises GovernanceFailure
- Exception hierarchy: StageError → StageCrash, StageTimeout, MalformedOutput, StageOutputError, GovernanceFailure
- `REPAIR_PROMPT` constant for §11.3 retry (dispatch engine handles retry logic)

**test_stage_runner.py:** 62 tests:
- Governance computation (6), schema validation (12), policy validation (10)
- Governance verification (5), stage execution with mocked subprocess (8), integration (2)
- Exception classes (6), repair prompt (3), schema edge cases (5), policy edge cases (5)

### Test Summary (Session 20 cumulative)
| Suite | Tests | Status |
|-------|-------|--------|
| Node.js | 363 | PASS |
| Python stage_runner | 62 | PASS |
| Python brief_builder | 32 | PASS |
| Python dispatch_state | 82 | PASS |
| Python watcher unit | 34 | PASS |
| Python watcher integration | 10 | PASS |
| **Total** | **583** | **PASS** |

### Session 20 End — 2026-02-22

**Summary:** Completed 4 tasks (CTB-017 through CTB-020) comprising M7 Foundation and M8 prerequisites. CTB-017 (schema extensions) and CTB-018 (dispatch state) executed in parallel via worktree isolation. CTB-019 (brief/prompt builder) and CTB-020 (stage runner) followed sequentially on the critical path. Run-log rotated at Phase 1/2 boundary (1489 lines archived). Run-log rotation codified as standard practice in file-conventions.md and CLAUDE.md. All 583 tests pass (363 Node.js + 220 Python). M8 walking skeleton (CTB-021) is unblocked and ready.

**Compound:** Run-log rotation pattern is a reusable convention — codified during this session in `_system/docs/file-conventions.md` §Run-Log Rotation. Trigger: phase boundary or ~1000 lines. Archive naming by phase label. Cross-references in both directions. This is the first compound insight from Phase 2 work.

**Rating:** 3 — Good

## Session 21 — 2026-02-22

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, next_action: CTB-021
- run-log.md — Session 20 end state, M7 complete
- tasks.md — CTB-021 pending, dependencies satisfied
- crumb-design-spec-v2-0.md — deferred spec cleanup (stale session-log paths)

### Spec v2.0.2: session-log.md Path Cleanup — COMPLETE

**Deferred from Session 20:** Spec had ~20 stale references to `session-log.md` at vault root after the file was moved to `_system/logs/session-log.md`.

**Changes (crumb-design-spec-v2-0.md):**
- Version bumped v2.0.1 → v2.0.2
- §2.1 directory tree: removed stale top-level `session-log.md`, added `logs/` subdirectory under existing `_system/` tree
- §2.3 file table: path updated
- §2.3.4 format section: opening reference and rotation path updated (archives now explicitly noted as living in `_system/logs/`)
- §0.3 Quick-Start: 3 references updated
- §3.5 primitive creation: 2 references updated
- §4.1 routing + §4.1.5 project creation: 4 references updated
- §4.4 compound: 1 reference updated
- §4.7 behavioral boundaries: 1 reference updated
- §6 session management: startup rotation check, session-end sequence (4 refs), context management (1 ref) updated
- §6 CLAUDE.md template: session-end commit updated to conditional protocol (matching CLAUDE.md change from earlier this session)
- §7.8 vault-check: 1 reference updated
- §7.10 bootstrap: 1 reference updated
- vault-check: CLEAN (0 errors, 0 warnings)

### Conditional Session-End Commit Protocol — APPLIED

Updated CLAUDE.md session-end sequence step 5 to classify `git diff --stat` before committing:
- Log-only delta → lightweight commit
- Substantial delta → flag to user, descriptive commit
- No changes → skip commit
Also propagated to spec §6 CLAUDE.md template (included in v2.0.2 bump).

### CTB-021 Context Loading + Design Review

Loaded all 4 upstream modules (dispatch_state, brief_builder, stage_runner, bridge-watcher) and dispatch protocol design doc via subagents. Reviewed CTB-021 acceptance criteria against design. Resolved 4 design questions:
1. Flock held for entire dispatch lifecycle (not per-stage)
2. Follow §7.2 response format now (CTB-027 extends, doesn't restructure)
3. `escalation-response`/`cancel-dispatch` with no active dispatch → explicit error stub
4. `status: next`/`blocked` from stage output → explicit "not yet implemented" failure (not silent)

### Session 21 End — 2026-02-22

**Summary:** Cleared deferred spec cleanup (v2.0.1 → v2.0.2, ~20 stale session-log paths). Applied conditional session-end commit protocol to CLAUDE.md and spec. Loaded full CTB-021 context and completed design review with 4 resolved questions. Build is unblocked for next session.

**Compound:** Conditional commit protocol is a process refinement, not a reusable pattern — applied directly to CLAUDE.md and spec. No compoundable insights beyond what was already codified.

**Rating:** 3 — Good

## Session 22 — 2026-02-22

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, active_task: CTB-021
- run-log.md — Session 21 end state, CTB-021 design review complete
- tasks.md — CTB-021 pending, dependencies (CTB-019, CTB-020) satisfied
- dispatch-protocol.md — §2-4, §7, §9, §10, §11 (state machine, stage model, response format, security, schema, malformed handling)
- dispatch_state.py, brief_builder.py, stage_runner.py — upstream modules (CTB-018, 019, 020)
- bridge-watcher.py — Phase 1 watcher, routing target for modification
- response-builder.js, constants.js — response format and operation constants reference
- 10 source documents (extended tier, justified: full pipeline context for integration)

### CTB-021: Dispatch Engine + Watcher Routing — COMPLETE

**Deliverables:** 3 files created/modified

**dispatch_engine.py** (`src/watcher/dispatch_engine.py`):
- `DispatchEngine` class — single-stage dispatch orchestration
  - `run_dispatch()`: request validation → brief construction → state creation (queued) → conflict check → transition to running → stage spawn → output evaluation → state transitions → response writing → request cleanup
  - `handle_escalation_response()`: explicit stub error (not yet implemented)
  - `handle_cancel_dispatch()`: explicit stub error (not yet implemented)
  - `_has_active_dispatch()`: scans dispatch state files for non-terminal dispatches, excludes own ID
  - `_write_final_response()`: §7.2 response format with dispatch-specific fields (stages_executed, budget_used, audit_hash, transcript_paths)
  - `_write_error_response()`: bridge-schema-compatible error format
  - `_compute_audit_hash()`: §7.3 deterministic hash computation (graceful fallback for missing transcripts)
  - `_cleanup_request()`: move to .processed/, append to .processed-ids
  - `_atomic_write_json()`: tmp + fsync + rename
- `parse_operation()`: standalone watcher routing helper, extracts operation from request JSON
- Stage output evaluation: `done` → complete, `next`/`blocked` → explicit not-yet-implemented failure, `failed` → propagate error
- §11.3 malformed output retry: one retry with REPAIR_PROMPT on MalformedOutput, then fail
- Exception mapping: StageCrash → STAGE_FAILED, StageTimeout → BUDGET_EXCEEDED, StageOutputError → STAGE_FAILED, GovernanceFailure → GOVERNANCE_STAGE_FAILED
- Cost estimation: Sonnet 4 pricing ($3/M input, $15/M output)

**bridge-watcher.py** (`_system/scripts/bridge-watcher.py`):
- Operation-based routing replaces `config.use_claude` flag
- `_parse_operation()`: reads request JSON to extract operation field
- `_dispatch_phase2()`: lazy-loads dispatch engine module, reads request, creates engine, routes by operation type (dispatch ops → run_dispatch, escalation-response → handle_escalation_response, cancel-dispatch → handle_cancel_dispatch)
- `_reject_dispatch_conflict()`: writes DISPATCH_CONFLICT error response when flock can't be acquired for Phase 2 requests (Phase 1 ops still silently skip for retry)
- Phase 2 ops set: start-task, invoke-skill, quick-fix, escalation-response, cancel-dispatch
- Config additions: dispatch_dir, transcripts_dir, dispatch_engine_path
- Lazy import pattern: dispatch engine module loaded on first Phase 2 request to avoid import errors when module not yet deployed

**test_integration.py** — updated:
- Replaced `TestClaudeDispatchStub` (tested removed `_dispatch_claude`) with `TestPhase2OperationRouting` (tests new operation-based routing)

**Tests:** 55 new tests (276 Python total, 283 Node.js, 559 combined), 0 failures.

| Category | Tests |
|----------|-------|
| Single-stage lifecycle | 12 |
| Watcher routing | 6 |
| Conflict detection | 6 |
| Error handling | 8 |
| Response format | 6 |
| Escalation/cancel stubs | 4 |
| File management | 4 |
| Integration (full pipeline) | 5 |
| Helper functions | 4 |

### Test Summary (Session 22 cumulative)
| Suite | Tests | Status |
|-------|-------|--------|
| Node.js | 283 | PASS |
| Python dispatch_engine | 55 | PASS |
| Python stage_runner | 62 | PASS |
| Python brief_builder | 32 | PASS |
| Python dispatch_state | 82 | PASS |
| Python watcher unit | 34 | PASS |
| Python watcher integration | 11 | PASS |
| **Total** | **559** | **PASS** |

### Acceptance Criteria Verification
- [x] Python dispatch engine orchestrates: request validation → state creation (queued) → flock acquisition → stage spawn → output evaluation → state transition → response/next-stage
- [x] bridge-watcher.py routes: Phase 1 ops → `_dispatch_node`; Phase 2 ops → dispatch engine
- [x] `escalation-response` and `cancel-dispatch` route to dispatch engine for correlation with active dispatches (stub errors in walking skeleton)
- [x] Routing based on operation field parsed from request JSON
- [x] If flock acquisition fails or another dispatch is active, reject with `DISPATCH_CONFLICT` error
- [x] Single-stage dispatch (`status: done`) produces final response in outbox
- [x] Integration tests: `invoke-skill` request → mock `claude --print` → final response in outbox
- [x] Integration tests: concurrent request → `DISPATCH_CONFLICT`

### Review Fixes (Session 22 continued)
User code review flagged 5 issues, 3 fixed:
1. **Modified files API bypass** — added `update_modified_files()` to DispatchState, replaced `_data`/`_write()` hack in dispatch_engine.py
2. **Dead `_load_dispatch_engine()` code** — removed from bridge-watcher.py along with `_dispatch_engine_module` global
3. **UUIDv7 consistency** — replaced `uuid.uuid4()` with `_generate_uuidv7()` in dispatch_engine.py and bridge-watcher.py; removed `import uuid`

Deferred (intentional):
4. Double file read in watcher routing — negligible for <4KB files
5. Dead `use_claude` config field — cleanup deferred to future housekeeping

276 Python tests pass after fixes, 0 failures.

Peer review decision: skip at CTB-021 (walking skeleton mid-milestone). Next review point: after CTB-024 (M9/M10, feature-complete dispatch engine).

## Session 23 — 2026-02-22

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, active_task: CTB-022
- run-log.md — Session 22 end state, CTB-021 complete
- tasks.md — CTB-022 pending, dependency (CTB-021) satisfied
- dispatch-protocol.md — §2 (lifecycle), §4 (stage model), §8 (budget enforcement)
- dispatch_engine.py, dispatch_state.py, brief_builder.py — upstream modules
- test_dispatch_engine.py — existing 55 tests
- User code review of CTB-021 (5 observations: A-E, 1 test gap)
- 8 source documents (standard tier)

### User Code Review of CTB-021 — Findings Applied

User performed full code review of dispatch_engine.py, bridge-watcher.py, and test_dispatch_engine.py.

**Resolved in this session:**
- A. UUIDv7 operator precedence: explicit parentheses added in dispatch_engine.py and bridge-watcher.py (readability, not a bug)
- D. `started_at: None` in stage info: `_build_stage_info` now accepts and records `started_at` timestamp
- Test gap: `test_build_brief_value_error` added (ValueError from build_brief → error response)

**Noted, no action needed:**
- B. State file accumulation on conflict: acceptable at usage scale, cleanup_terminal_states handles
- C. Malformed retry overwrites stage file: by design per §11.3, minor forensics gap
- E. Stub error codes use STAGE_FAILED: temporary, replaced by CTB-024/025

### CTB-022: Multi-Stage Lifecycle + Budget Enforcement — COMPLETE

**Deliverables:** 4 files modified

**dispatch_state.py:**
- Added `total_blocked_seconds: 0` field to initial state (plumbing for blocked-time exclusion, populated by CTB-024)

**brief_builder.py:**
- Added `budget_warning: str | None = None` parameter to `build_system_prompt()`
- Warning line inserted between budget info and kill-switch status when present

**dispatch_engine.py (major refactor):**
- `run_dispatch()` converted from single-stage to multi-stage loop
- Multi-stage flow: build prompts → spawn stage → evaluate output → (status: next → collect handoff + previous stages context → budget check → cancel check → spawn next stage)
- `_compute_elapsed_wall_time(ds)`: `now - dispatch_started_at - total_blocked_seconds`
- `_compute_budget_warning(budget, remaining)`: warns at ≤20% of stages or wall-time
- `_check_cancel_inbox(dispatch_id)`: stage boundary checkpoint per §2.3
- `_write_final_response()` refactored: aggregates deliverables, metrics, transcript paths across all stages
- `_write_dispatch_error_response()`: new method for BUDGET_EXCEEDED and CANCELED_BY_USER with partial deliverables
- Per-stage timeout: `min(remaining_wall_time, 3600)` — decreases as budget consumed
- `_build_stage_info()` now accepts `started_at` parameter (review finding D)
- `_generate_uuidv7()` parentheses clarified (review finding A, also in bridge-watcher.py)
- Removed `import struct` (unused)

**test_dispatch_engine.py:**
- 75 tests (was 55), organized in 13 categories
- Removed: `test_status_next_fails_not_implemented` (behavior changed from stub to multi-stage)
- New category 9: Multi-stage lifecycle (6 tests) — 3-stage handoff, state recording, handoff passing, stage 2 failure, stage 2 crash, cost aggregation
- New category 10: Budget enforcement (5 tests) — stage limit, wall-time limit, done overrides exceeded, remaining timeout, deliverables in BUDGET_EXCEEDED
- New category 11: Budget warning (3 tests) — warning at 20%, no warning above 20%, helper unit test
- New category 12: Stage boundary cancel (4 tests) — cancel detected, no false cancel, empty inbox, missing dir
- New: `test_stage_started_at_tracked` (review finding D)
- New: `test_build_brief_value_error` (review test gap)
- Fixed: `test_quick_fix_budget_defaults` mocks elapsed time to avoid timing sensitivity

### Test Summary (Session 23 cumulative)
| Suite | Tests | Status |
|-------|-------|--------|
| Node.js | 363 | PASS |
| Python dispatch_engine | 75 | PASS |
| Python stage_runner | 62 | PASS |
| Python brief_builder | 32 | PASS |
| Python dispatch_state | 82 | PASS |
| Python watcher unit | 34 | PASS |
| Python watcher integration | 11 | PASS |
| **Total** | **659** | **PASS** |

### Acceptance Criteria Verification
- [x] `status: next` → spawn next stage with handoff + summaries
- [x] Stage counter incremented
- [x] Wall-time tracked from `dispatch_started_at` (§8.2)
- [x] Wall-time pauses in blocked state; `total_blocked_seconds` persisted (plumbing for CTB-024)
- [x] Budget warnings at ≤20% remaining
- [x] `BUDGET_EXCEEDED` when stage or wall-time limits hit
- [x] Hard caps enforced regardless of user override
- [x] Dispatch state persisted after every transition (atomic write)
- [x] Stage boundary checkpoint: check inbox for `cancel-dispatch` before spawning next stage
- [x] Tests: 3-stage dispatch with handoff, budget exceeded at stage limit, budget exceeded at wall-time limit, budget warning injection

### Session 23 End — 2026-02-22

**Summary:** Completed CTB-022 (multi-stage lifecycle + budget enforcement). Refactored dispatch_engine.py from single-stage walking skeleton to multi-stage loop with full budget enforcement. Applied 3 user code review findings from CTB-021 (UUIDv7 parens, started_at tracking, ValueError test gap). 20 new tests added (75 total dispatch_engine, 659 combined). All acceptance criteria verified. M9 milestone complete.

**Compound:** No new compoundable insights. Multi-stage loop is a straightforward extension of the walking skeleton pattern — no non-obvious decisions or reusable patterns emerged. The budget warning threshold (≤20%) is per-protocol, not a novel convention.

**Rating:** 3 — Good

## Session 24 — 2026-02-22

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, next: CTB-024
- run-log.md — sessions 20-23, CTB-017 through CTB-022 complete, 659 tests
- tasks.md — CTB-024 AC read for implementation
- dispatch-protocol.md §6 (structured escalation), §9.3 (injection resistance)
- dispatch_engine.py, dispatch_state.py, brief_builder.py — read in full

### Work Log

**Peer review application (CTB-022 follow-up):**
- Applied finding 4: stage error handlers at `current_stage > 1` now use `_write_dispatch_error_response` to preserve partial deliverables
- Added 3 tests: `test_dispatch_error_response_schema`, `test_stage_crash_at_stage_2_preserves_deliverables`, `test_stage_declared_failure_at_stage_2_preserves_deliverables`
- Tests: 78 dispatch_engine, 299 total Python — all pass

**CTB-024 implementation (structured escalation flow):**

Option A architecture: split run_dispatch into start + resume. Engine writes dispatch state + escalation relay, releases flock, returns. Watcher routes escalation-response to handle_escalation_response which resumes via shared _run_stages().

1. **dispatch_state.py changes:**
   - Added `tokens_input`/`tokens_output` to initial `worker_reported`
   - Added `blocked_seconds` kwarg to `transition()` for accumulating `total_blocked_seconds`
   - Extended `pending_escalation` clearing to blocked→failed and blocked→canceled transitions
   - Added token split tracking to `update_budget()`

2. **brief_builder.py changes:**
   - Added `escalation_resolution` parameter to `build_user_prompt()`
   - Injected as section 3 (TRUSTED, runner-resolved) between previous stages and next stage instructions

3. **dispatch_engine.py (major refactor):**
   - Added escalation validation constants (`_ESCALATION_OPTION_RE`, `_ESCALATION_TEXT_RE`, `_ESCALATION_CONTEXT_RE`, `VALID_GATE_TYPES`, `VALID_QUESTION_TYPES`)
   - Extracted `_run_stages()` — shared multi-stage loop called by both `run_dispatch()` and `handle_escalation_response()`
   - `run_dispatch()` simplified: setup → delegate to `_run_stages()`
   - `handle_escalation_response()` — full implementation: validates dispatch_id/escalation_id/timeout, resolves answers via `_resolve_escalation_answers()`, computes blocked_seconds, reconstructs ctx from dispatch state, resumes via `_run_stages()`
   - Blocked handler in `_run_stages`: validates escalation schema, persists via state transition, writes relay, returns True
   - `_write_escalation_relay()` — writes `{dispatch_id}-escalation.json` to outbox for Tess
   - `check_escalation_timeouts()` — scans dispatch dir for expired blocked dispatches
   - Three new module-level helpers:
     - `_validate_escalation()` — validates §6.2 schema, strips default, returns validated copy
     - `_resolve_escalation_answers()` — maps indices to runner-persisted option text (§6.5 step 4)
     - `_build_escalation_resolution()` — builds TRUSTED resume prompt section (§6.5 step 5)

4. **bridge-watcher.py changes:**
   - Added `_check_escalation_timeouts()` to `BridgeWatcher` class
   - Called from `_process_inbox()` on every cycle (no flock needed — blocked dispatches have no competing writers)

5. **Tests:** 46 new tests across 5 test classes:
   - `TestEscalationValidation` (18 tests) — schema validation per §6.2/§9.3
   - `TestAnswerResolution` (11 tests) — index→text mapping per §6.5
   - `TestEscalationResolutionPrompt` (2 tests) — resume prompt construction
   - `TestEscalationFlow` (12 tests) — blocked→relay→resume lifecycle integration
   - `TestEscalationTimeout` (4 tests) — watcher-driven timeout handling
   - Updated 2 existing tests (stub → real behavior)

### Test Summary (Session 24 cumulative)
| Suite | Tests | Status |
|-------|-------|--------|
| Node.js | 363 | PASS |
| Python dispatch_engine | 124 | PASS |
| Python stage_runner | 62 | PASS |
| Python brief_builder | 32 | PASS |
| Python dispatch_state | 82 | PASS |
| Python watcher unit | 34 | PASS |
| Python watcher integration | 11 | PASS |
| **Total** | **708** | **PASS** |

### Acceptance Criteria Verification
- [x] Stage `status: blocked` triggers escalation
- [x] Runner validates §6.2 schema: regex on options, max 3 questions, choice/confirm types only, strip default
- [x] Questions + options persisted in dispatch state (`pending_escalation`)
- [x] Escalation relay written to outbox for Tess
- [x] Watcher polls for `escalation-response` (via `_process_inbox` cycle routing)
- [x] Answers resolved: option indices → runner-persisted option text (not raw user input)
- [x] Resume prompt constructed per §6.5 with runner-resolved text
- [x] Escalation timeout: 30min default, `ESCALATION_TIMEOUT` on expiry
- [x] Risk-gate: `risk` type gets visual warning flag
- [x] Only first valid `escalation-response` accepted; duplicates ignored
- [x] Wrong `escalation_id` → ignored with warning
- [x] Late response after timeout → ignored
- [x] Tests: schema validation, option index resolution, timeout, resume prompt, duplicate handling, wrong-id rejection, late-after-timeout rejection

### Session 24 End — 2026-02-22

**Summary:** Applied CTB-022 peer review finding 4 (partial deliverable preservation at stage 2+). Implemented CTB-024 (structured escalation flow) — Option A architecture with start/resume split, full §6.2 schema validation, §6.5 answer resolution, 30-min timeout scanning, and escalation relay for Tess. 46 new tests, 708 total passing.

**Compound:** No compoundable insights. Option A start/resume split is straightforward consequence of flock design. `_run_stages()` extraction (shared loop with ctx dict) is conventional.

**Rating:** 3 — Good

---

## Session 25 — 2026-02-22

**Focus:** CTB-024a peer review remediation

### Context Loaded
- project-state.yaml, run-log.md, progress-log.md, tasks.md
- dispatch_engine.py (1423 lines), dispatch_state.py (451 lines), brief_builder.py (393 lines)
- bridge-watcher.py (1068 lines), test_dispatch_engine.py (~2656 lines)
- dispatch-protocol.md §6
- peer-review-config.md

### Peer Review Execution
- 4 external reviewers: GPT-5.2, Gemini 3 Pro Preview, DeepSeek Reasoner, Grok 4.1 Fast Reasoning
- All responded successfully (latency: 38s–76s)
- Gemini response truncated (MAX_TOKENS — only 1386 chars)
- Review note: `_system/reviews/2026-02-22-ctb-024.md`
- Raw responses: `_system/reviews/raw/2026-02-22-ctb-024-{reviewer}.json`

### User Cross-Reference
User provided detailed cross-reference of their own manual review against peer review findings. Key outcomes:
- Agreed on A1 (race condition) but preferred simpler re-read fix over CAS/version counter
- Identified hardcoded `escalations: 0` (F2) that all 4 reviewers missed
- Agreed with A2 (missing ID regex), A3 (trust labeling), A4 (next_stage_instructions), A5 (timezone)
- Promoted A11 (silent parse failure) from defer to at-least-logging

### CTB-024a Remediation (8 fixes)

**dispatch_engine.py:**
- A1: `check_escalation_timeouts` re-reads state via `DispatchState.load()` before transitioning (TOCTOU race fix)
- A2: Added `_ESCALATION_ID_RE` (`^[a-zA-Z0-9_-]{1,64}$`) and `_ESCALATION_QUESTION_ID_RE` (`^[a-z][a-z0-9_-]{0,31}$`) with validation in `_validate_escalation`
- A3: `_build_escalation_resolution` split trust labels — context "validated, model-provided", answers "TRUSTED, runner-resolved"
- A4: Persists `next_stage_instructions` in `pending_escalation` on block; restores on resume
- A5: Added `_parse_iso_utc()` helper; replaced 5 inline `fromisoformat + tzinfo` patterns
- A11: All `except: pass` on datetime parse failures now log warnings
- F2: `dispatch.escalations` reads `state.get("escalation_count", 0)` instead of hardcoded `0`

**dispatch_state.py:**
- F2: Added `escalation_count` field to initial state; incremented on blocked transition

**bridge-watcher.py:**
- A1: Updated stale "no competing writers" comment

**test_dispatch_engine.py (16 new tests, 140 total):**
- Cat 19: TestEscalationIdValidation (8 tests) — valid/invalid escalation_id and question id
- Cat 20: TestTimeoutResumeRace (3 tests) — resumed skips, failed skips, concurrent race
- Cat 21: TestEscalationTrustLabeling (3 tests) — answer trust, context validated, header
- Cat 22: TestEscalationCount (2 tests) — count=1 after escalation, count=0 without
- Updated existing `test_choice_resolution_format` for new trust labels

### Session 25 End — 2026-02-22

**Summary:** Ran 4-model peer review on CTB-024. User cross-referenced with their own manual review. Applied 8 remediation fixes (CTB-024a): race condition guard, ID regex validation, trust labeling, next_stage_instructions persistence, timezone helper, parse failure logging, and escalation count tracking. 16 new tests, 140 total passing. Vault-check clean.

**Compound:** Peer review missed a straightforward data accuracy issue (hardcoded `escalations: 0`) that the human reviewer caught. This aligns with emerging pattern: external LLMs are strong on structural/security analysis but miss data-flow accuracy bugs. Worth tracking in `_system/docs/solutions/peer-review-patterns/` once more data points accumulate.

**Rating:** 3 — Good

## Session 26 — 2026-02-22

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, next: CTB-025
- run-log.md — Session 25 end state, CTB-024a complete, 708 tests
- tasks.md — CTB-025 pending, dependency (CTB-022) satisfied
- dispatch-protocol.md — §2.3 (transitions, cancel precedence), §9.2 (kill-switch), §10.2 (cancel-dispatch params)
- dispatch_engine.py, dispatch_state.py — read in full
- bridge-watcher.py — Phase 2 routing, flock logic, kill-switch config
- test_dispatch_engine.py — existing 140 tests, patterns for new tests
- 8 source documents (standard tier)

### CTB-025: Cancel-Dispatch + Inter-Stage Kill-Switch — COMPLETE

**Deliverables:** 3 files modified

**dispatch_engine.py:**
- `handle_cancel_dispatch()` — replaced stub with full implementation: loads target dispatch state, records cancel intent immediately via `record_cancel_request()` (atomic write), handles each state distinctly:
  - blocked → immediate cancellation (§2.3 rule 11), CANCELED_BY_USER with partial deliverables
  - queued → failed with cancel reason (§2.3 rule 12)
  - stage-complete → canceled with partial deliverables (§2.3 rule 8)
  - terminal → error (already done)
  - not found → error
  - running → intent recorded, stage boundary will detect
- `_check_kill_switch()` — new method, checks kill_switch_path existence
- `_find_cancel_request()` — new method, scans inbox for cancel-dispatch files matching dispatch_id, returns (path, data) tuple
- `_is_cancel_requested()` — new method, checks both dispatch state (`cancel_requested_at`) and inbox (cancel file), returns (is_canceled, cancel_path, cancel_data)
- `_run_stages()` — 3 new check points:
  1. Kill-switch before every stage spawn (top of loop)
  2. Cancel + kill-switch in `next` status handler (after stage complete, before next stage)
  3. Cancel + kill-switch in `blocked` status handler (before entering blocked state)
- Cancel/completion precedence: `done` handler runs before any cancel check (completion wins); `next` and `blocked` check cancel first (cancel wins)
- Cancel file cleanup: when cancel detected at stage boundary, cancel request file moved to .processed and ID appended
- Constructor: added `kill_switch_path` parameter
- `handle_escalation_response()`: kill-switch check before calling `_run_stages()`

**bridge-watcher.py:**
- cancel-dispatch special case when flock held: returns False (leaves file in inbox for stage boundary detection) instead of DISPATCH_CONFLICT rejection
- Passes `kill_switch_path=str(config.kill_switch)` to DispatchEngine constructor

**test_dispatch_engine.py (16 new tests, 156 total):**
- Cat 22: TestCancelDispatch (7 tests) — blocked immediate, cancel records ID, queued cancel, terminal error, missing dispatch_id, stage-complete cancel, blocked preserves deliverables
- Cat 23: TestCancelCompletionPrecedence (3 tests) — done wins over cancel, next+cancel=canceled, blocked+cancel=canceled
- Cat 24: TestKillSwitch (4 tests) — before first stage, between stages, before escalation resume, no kill-switch normal operation
- Cat 25: TestCancelCleanup (2 tests) — cancel file moved to .processed, cancel request ID recorded in state
- Updated existing cat 6 (stub → edge case tests), cat 12 test naming

### Test Summary (Session 26 cumulative)
| Suite | Tests | Status |
|-------|-------|--------|
| Node.js | 363 | PASS |
| Python dispatch_engine | 156 | PASS |
| Python stage_runner | 62 | PASS |
| Python brief_builder | 32 | PASS |
| Python dispatch_state | 82 | PASS |
| Python watcher unit | 34 | PASS |
| Python watcher integration | 11 | PASS |
| **Total** | **740** | **PASS** |

### Acceptance Criteria Verification
- [x] Stage boundary checkpoint polls inbox for `cancel-dispatch`
- [x] On receipt: `cancel_requested_at` + `cancel_request_id` persisted immediately (atomic write)
- [x] Cancel/completion precedence per §2.3: `done` wins; `next`/`blocked` + cancel → canceled
- [x] Kill-switch checked before every stage spawn and before escalation resume
- [x] `CANCELED_BY_USER` response includes partial deliverables from completed stages
- [x] `KILL_SWITCH` response includes deliverables from governance-verified stages
- [x] Tests: cancel at stage boundary, cancel during blocked, cancel vs completion precedence, kill-switch detection

### Session 26 End — 2026-02-22

**Summary:** Implemented CTB-025 (cancel-dispatch + inter-stage kill-switch). Replaced cancel-dispatch stub with full implementation handling all dispatch states. Added kill-switch checks before every stage spawn and before escalation resume. Implemented cancel/completion precedence per §2.3. Updated bridge-watcher to leave cancel-dispatch in inbox when flock held. 16 new tests, 740 total passing.

**Compound:** No compoundable insights. Cancel-dispatch follows directly from §2.3 transition rules. The flock-held special case is a straightforward consequence of the inbox-scan design.

**Rating:** 3 — Good

## Session 27 — 2026-02-22

**Focus:** User code review remediation (CTB-025 + general cleanup)

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, CTB-025 complete
- run-log.md — Session 26 end state, 740 tests
- dispatch_engine.py, test_dispatch_engine.py — review targets
- .gitignore — repo hygiene
- 4 source documents (minimal tier)

### User Code Review — 4 Findings Applied

**Finding 1 — Dead `_check_cancel_inbox` method:**
- Removed dead wrapper method from dispatch_engine.py
- Removed 41 stale `@patch.object(DispatchEngine, '_check_cancel_inbox', return_value=False)` decorators from test_dispatch_engine.py
- Removed 2 direct-call tests of the dead method
- Fixed all test method signatures: removed `mock_cancel` parameter from 41 methods

**Finding 2 — Running cancel no ack response:**
- Added ack response in `handle_cancel_dispatch` running branch
- Response keyed to cancel `request_id` (not dispatch_id) with `"status": "accepted"`
- 1 new test: `test_cancel_running_dispatch_writes_ack`

**Finding 3 — `__pycache__` in git:**
- Added `__pycache__/` to `.gitignore`
- Files were untracked (not committed) — no `git rm --cached` needed

**Finding 4 — Deliverables extraction duplication:**
- Extracted `_extract_partial_deliverables(state_data)` helper
- Replaced 4 near-identical blocks in handle_escalation_response, blocked cancel, stage-complete cancel, and escalation timeout

### Test Summary (Session 27)
| Suite | Tests | Status |
|-------|-------|--------|
| Node.js | 363 | PASS |
| Python dispatch_engine | 155 | PASS |
| Python stage_runner | 62 | PASS |
| Python brief_builder | 32 | PASS |
| Python dispatch_state | 82 | PASS |
| Python watcher unit | 34 | PASS |
| Python watcher integration | 11 | PASS |
| **Total** | **739** | **PASS** |

### Session 27 End — 2026-02-22

**Summary:** Applied 4 user code review findings from CTB-025: removed dead `_check_cancel_inbox` method + 41 stale test patches, added ack response for running-state cancel-dispatch, added `__pycache__/` to .gitignore, extracted `_extract_partial_deliverables` helper to deduplicate 4 branches. Net -1 test (removed 2 dead, added 1 ack). 739 total passing.

**Compound:** No compoundable insights. All fixes are straightforward cleanup — dead code removal, missing response, .gitignore hygiene, DRY extraction. No non-obvious decisions or reusable patterns.

**Rating:** 3 — Good

## Session 28 — 2026-02-22

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, next: CTB-023, CTB-027
- run-log.md — Session 27 end state, 739 tests
- tasks.md — CTB-023 pending (low), CTB-027 pending (medium)
- dispatch-protocol.md — §5.2 (status updates), §7.2 (final response), §7.3 (audit trail)
- dispatch_engine.py — full read, existing response writing and audit hash methods
- test_dispatch_engine.py — existing 155 tests, patterns for new tests
- bridge-watcher.py — cleanup integration point
- 8 source documents (standard tier)

### CTB-023: Status Updates — COMPLETE

**Deliverables:** 2 files modified

**dispatch_engine.py:**
- `_write_status_update()` — new method, writes §5.2 status update to outbox after each stage
  - `{dispatch_id}-status.json` overwritten per stage (latest status only)
  - All §5.2 fields: schema_version, type, dispatch_id, timestamp, lifecycle_state, stage_completed, stage_current, summary (truncated to 800 chars), budget_remaining, estimated_completion
  - budget_remaining includes all 4 fields: stages, wall_time_seconds, tool_calls_reported, tokens_reported
  - estimated_completion: null after first stage, `"soon"` or `"~N minutes"` after ≥2 stages (uses average stage duration × remaining stages)
- Called in `_run_stages()` after budget update, before status evaluation

**test_dispatch_engine.py (6 new tests, category 26):**
- Status file written after stage, overwrite per stage, null estimated_completion at stage 1
- Estimated completion computed after 2+ stages, budget_remaining fields non-negative, summary truncation at 800

### CTB-027: Audit Trail + Final Response — COMPLETE

**Deliverables:** 3 files modified

**dispatch_engine.py:**
- `cleanup_stage_outputs()` — new method, 30-day retention for stage output and status files
  - Deletes `*-stage-*.json` and `*-status.json` older than 30 days
  - Preserves `*-response.json` and `*-escalation.json` indefinitely
  - Uses file mtime for age determination
- Verified existing `_compute_audit_hash()` covers §7.3 (deterministic sha256 chain)
- Verified existing `_write_final_response()` covers §7.2 (all dispatch fields)

**bridge-watcher.py:**
- Added `cleanup_stage_outputs()` and `cleanup_terminal_states()` calls to watcher cycle
- Runs on every `_process_inbox` cycle (lightweight stat-only scan)

**test_dispatch_engine.py (11 new tests, categories 27):**
- TestAuditTrailCleanup (6): old stage outputs deleted, recent preserved, response files indefinite, escalation files indefinite, status files cleaned, empty outbox
- TestAuditHashComputation (3): two transcripts deterministic, single transcript, empty transcripts
- TestFinalResponseAuditFields (2): all §7.2 fields present in multi-stage response, deliverable aggregation

### Test Summary (Session 28)
| Suite | Tests | Status |
|-------|-------|--------|
| Node.js | 363 | PASS |
| Python dispatch_engine | 172 | PASS |
| Python stage_runner | 62 | PASS |
| Python brief_builder | 32 | PASS |
| Python dispatch_state | 82 | PASS |
| Python watcher unit | 34 | PASS |
| Python watcher integration | 11 | PASS |
| **Total** | **756** | **PASS** |

## Session 29 — 2026-02-22

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, next: CTB-026
- progress-log.md — CTB-023 + CTB-027 complete, CTB-026 remaining
- bridge-cli.js, echo-formatter.js, outbox-watcher.js, constants.js, schema.js — Tess-side implementation
- dispatch-protocol.md §5.3 (status Telegram format), §6.3 (escalation relay format, ANSWER/CANCEL shorthand)
- Existing test files (echo-formatter.test.js, outbox-watcher.test.js, integration.test.js) — patterns
- 8 source documents, standard tier

### CTB-026: Tess Dispatch CLI Support — COMPLETE

**bridge-cli.js (7 new commands):**
- `parse-answer` — parses `ANSWER {dispatch_id_short} {q1} [{q2}] [{q3}]`, looks up escalation relay via `findEscalation()`, maps 1-based answers to 0-based `selected_option`, validates answer count and range, returns structured `{dispatch_id, escalation_id, answers}`. Sets `requires_confirmation: true` for risk-gate escalations.
- `parse-cancel` — parses `CANCEL {dispatch_id_short}`, resolves full dispatch_id via escalation relay. Returns warning if no relay found (skill must resolve from its own records).
- `check-status` — reads `{dispatch_id}-status.json` from outbox, returns parsed status or `{found: false}`
- `check-escalation` — scans outbox for `*-escalation.json` matching dispatch_id_short, returns relay or `{found: false}`
- `format-escalation` — formats escalation relay JSON to Markdown via `formatEscalationRelayMarkdown()`
- `format-status` — formats status update JSON to Markdown via `formatStatusUpdateMarkdown()`
- `format-dispatch-relay` — formats dispatch response/error JSON to Markdown via `formatDispatchResponseRelayMarkdown()`

**outbox-watcher.js (2 new functions):**
- `checkStatus(dispatchId)` — reads `-status.json`, returns parsed or null (ENOENT/SyntaxError → null)
- `findEscalation(dispatchIdShort)` — scans outbox for `-escalation.json` files, matches by `dispatch_id_short` field or `dispatch_id` prefix

**echo-formatter.js (4 new functions — all added in prior session, tested here):**
- `formatEscalationRelayMarkdown(relay)` — §6.3 template with neutral numbered labels, risk warning banner, ANSWER/CANCEL shorthand
- `formatStatusUpdateMarkdown(status)` — §5.3 template with stage progress, budget remaining, estimated completion
- `formatDispatchResponseRelayMarkdown(response)` — dispatch completion with deliverables (capped at 10), stages, budget, audit hash
- `formatDispatchErrorRelayMarkdown(response)` — all 8 error codes with per-code emojis, partial deliverables (capped at 5)

**Tests (53 new):**
- echo-formatter.test.js: +31 (Phase 2 echo param display ×5, Phase 2 echo format ×3, escalation relay ×4, status update ×3, dispatch response ×3, dispatch error ×4, Phase 2 getParamDisplayLines ×5, Phase 2 formatEchoMarkdown ×3, error code emoji coverage ×1)
- outbox-watcher.test.js: +8 (checkStatus ×3, findEscalation ×4, malformed file skip ×1)
- integration.test.js: +24 (parse-answer ×7, parse-cancel ×3, check-status ×2, check-escalation ×2, format-escalation ×1, format-status ×1, format-dispatch-relay ×2, Phase 2 validate+echo round-trips ×5, risk-gate confirmation ×1)

### AC Verification
- [x] bridge-cli.js handles Phase 2 operations through standard flow (validate/hash/echo/write-request already work via CTB-017 schema)
- [x] escalation-response parsing: ANSWER shorthand → structured request with option indices
- [x] cancel-dispatch parsing: CANCEL shorthand → structured request
- [x] outbox-watcher extended for -status.json + -escalation.json
- [x] echo-formatter formats escalation questions with neutral labels (§6.3)
- [x] Two-step confirmation for risk-gate (requires_confirmation flag)
- [x] Status update Telegram format (§5.3)
- [x] All 8 dispatch error codes formatted with per-code emojis
- [x] Tests: all 5 Phase 2 ops validate+format, ANSWER/CANCEL parsing, status detection, error codes

### Test Summary (Session 29)
| Suite | Tests | Status |
|-------|-------|--------|
| Node.js (tess + crumb + e2e) | 416 | PASS |
| Python dispatch_engine | 172 | PASS |
| Python stage_runner | 62 | PASS |
| Python brief_builder | 32 | PASS |
| Python dispatch_state | 82 | PASS |
| Python watcher unit | 34 | PASS |
| Python watcher integration | 11 | PASS |
| **Total** | **809** | **PASS** |

**Rating:** 3 — Good

**Compound:** No compoundable insights — CTB-026 was a straightforward CLI extension following established patterns from Phase 1. No non-obvious decisions or reusable artifacts beyond the existing codebase patterns.

## Session 30 — 2026-02-22

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, next: CTB-028
- run-log.md — Session 29 end state, 809 tests
- progress-log.md — all CTB-028 blockers resolved
- bridge-watcher.py — code review fix target
- test_ctb028_e2e_dispatch.py — user-drafted test file from _inbox/
- dispatch_engine.py, dispatch_state.py, stage_runner.py — implementation references
- peer-review-config.md — reviewer configuration
- 8 source documents (standard tier)

### User Code Review of Session 29 — 2 Findings

**Finding 1 — CLI auto-detect (non-issue):**
User asked whether `cmdFormatDispatchRelay` should auto-detect error vs success responses. Traced to `formatDispatchResponseRelayMarkdown` (echo-formatter.js:465) which already auto-detects internally. No change needed.

**Finding 2 — bridge-watcher.py cleanup try/except:**
Single try block wrapping engine construction + escalation timeout check + cleanup had misleading error message ("Escalation timeout check failed" for any failure). Split into three try/except blocks:
1. Engine construction → early `return` on failure
2. Escalation timeout check → "Escalation timeout check failed"
3. Cleanup → "Dispatch cleanup failed"

### CTB-028 Draft Review

User dropped 39-test draft (`_inbox/bridge0ctb-028-tests.py`) covering 13 categories. Internal review identified 10+ findings before external peer review:
- C1: `_validate_escalation` raises ValueError (not return-value API) — Cat 12 tests fixed
- C2: Answer indices confirmed 1-based (documented with comment)
- H1: Cat 6 test 2 renamed — alert writing is in StageRunner, not engine
- H2: Cat 4 tautological deliverables assertion → `assertGreater(len(...), 0)`
- H3: Cat 1 test 3 missing `.processed/` assertion → added
- M1: Cat 7 kill-switch state → `assertEqual(ds.state, "failed")` (not `assertIn`)
- M3: Removed unused imports
- M4: Removed unnecessary `time.sleep(0.1)`
- L2: Added `dispatch_dir.mkdir(parents=True)` to setUp
- Added `test_valid_escalation_passes` positive test (Cat 12)
- Fixed `audit_hash` assertions: `response["dispatch"]` → `response` (top-level key)

After fixes: 40 tests, all passing. File written to `src/watcher/test_ctb028_e2e_dispatch.py`.

### 4-Model Peer Review

**Reviewers:** GPT-5.2 (47s), Gemini 3 Pro Preview (50s), DeepSeek V3.2-Thinking (87s), Grok 4.1 Fast (66s)
**Review note:** `_system/reviews/2026-02-22-test-ctb028-e2e-dispatch.md`

**9 consensus findings** (2+ reviewers):
1. Injection tests mock exceptions instead of real validation (4/4)
2. Missing StageTimeout/StageCrash E2E tests (3/4)
3. Missing start-task E2E (3/4)
4. Weak assertions on budget/cancel/kill-switch (3/4)
5. Handoff boundary test doesn't test boundary (2/4)
6. Missing invalid escalation answer tests (2/4)
7. Missing concurrent/active dispatch test (2/4)
8. Missing corrupted state crash recovery (2/4)
9. audit_hash existence-only check (2/4)

**1 contradiction:** Grok rated mock fidelity as STRENGTH (for escalation/prompt-framing tests where real validation runs); other 3 flagged as SIGNIFICANT weakness (for path traversal/governance tests where mock bypasses validation). Both correct for their scope — user confirmed.

### Peer Review Remediation — All 11 Action Items Applied

**Must-fix (A1-A2):**
- A1: Added Cat 14 — StageTimeout/StageCrash/MalformedOutput E2E (4 tests)
- A2: Strengthened 5 existing tests — cancel (call_count, exact deliverable path), budget (stages_executed, call_count, deliverable count), kill-switch (state + response assertions)

**Should-fix (A3-A11):**
- A3: Added Cat 16 — start-task happy-path (1 test)
- A4: Added Cat 17 — invalid escalation answers: index 0, out-of-range, non-integer, missing (4 tests)
- A5: Handoff boundary test now constructs payload at exactly MAX_HANDOFF_BYTES
- A6: Added Cat 18 — concurrency gate: _has_active_dispatch=True → DISPATCH_CONFLICT (1 test)
- A7: Added Cat 19 — audit_hash: valid hex + varies with different transcripts (2 tests)
- A8: Added Cat 20 — corrupted crash recovery: invalid JSON, missing lifecycle_state, unknown state, empty file (4 tests)
- A9: Removed unused `stage_2_bad_gov` variable
- A10: Added Cat 21 + inline fixes — response file assertions for wrong_id and kill-switch resume
- A11: Added Cat 15 — immediate stage failure (stage 1 returns failed) (1 test)

**Deferred (A12-A16):** Mock fidelity restructuring (policy validation is in test_stage_runner.py), governance alert E2E, race conditions, token budgets (not implemented), multi-question escalation. Module docstring updated to clarify which categories test real validation vs error mapping.

### Test Summary (Session 30)
| Suite | Tests | Status |
|-------|-------|--------|
| Node.js (tess + crumb + e2e) | 416 | PASS |
| Python dispatch_engine | 172 | PASS |
| Python CTB-028 e2e | 58 | PASS |
| Python stage_runner | 62 | PASS |
| Python brief_builder | 32 | PASS |
| Python dispatch_state | 82 | PASS |
| Python watcher unit | 34 | PASS |
| Python watcher integration | 11 | PASS |
| **Total** | **867** | **PASS** |

### Session 30 End — 2026-02-22

**Summary:** Applied user Session 29 code review (1 non-issue, 1 bridge-watcher fix). Reviewed and refined user-drafted CTB-028 test suite (10+ internal findings fixed). Ran 4-model peer review (9 consensus findings, 1 contradiction). Applied all 11 action items: 2 must-fix (StageTimeout/StageCrash tests, strengthened assertions), 9 should-fix (start-task, invalid answers, boundary test, concurrency gate, audit_hash correctness, corrupted crash recovery, dead code, response assertions, immediate failure). Test count: 40 → 58 CTB-028 tests, 867 total across all suites.

**Compound:** The contradiction pattern (Grok STRENGTH vs 3 others SIGNIFICANT) on mock fidelity reinforces the emerging pattern from Session 25: the same mock approach is a strength or weakness depending on which validation boundary it crosses. This is worth documenting: *mock level determines what's tested — mock at run_stage tests engine orchestration; mock at subprocess tests the full stack including policy validation. Choose mock level to match test intent, and document it.* Not yet compoundable (need to see if this generalizes beyond this test suite).

## Session 31 — 2026-02-22

### Context Inventory
- project-state.yaml — phase: IMPLEMENT, CTB-028 pending (test suite written, peer-reviewed)
- run-log.md — Session 30 end state, 867 tests
- test_ctb028_e2e_dispatch.py — 58 tests ready to run
- All Python + Node.js test suites — full regression
- 4 source documents (minimal tier — execution only)

### CTB-028: E2E Dispatch Validation + Injection Tests — COMPLETE

**Validation gate execution:** Ran full CTB-028 test suite (58 tests) against the live dispatch engine. All 58 pass in 0.24s.

**Full regression:** Ran all Python (451 tests, 5.30s) and Node.js (416 tests, 1.58s) suites. 867/867 pass, 0 failures.

**CTB-028 test coverage (21 categories):**
- E2E lifecycle: single-stage complete, 3-stage handoff, escalation round-trip, cancel mid-dispatch, budget exceeded, governance failure, kill-switch, crash recovery
- E2E edge cases: stage failure exceptions (timeout/crash/malformed), immediate stage failure, start-task happy-path, invalid escalation answers, concurrency gate, audit hash correctness, corrupted crash recovery, escalation wrong-id response
- Injection: malicious instructions (prompt override, oversized, non-ASCII), path traversal (../../.ssh, sensitive paths), oversized handoff (>8KB), escalation options (backticks, slashes, unicode), fabricated governance

**Phase 2 daily use gate: PASSED.**

### Test Summary (Session 31)
| Suite | Tests | Status |
|-------|-------|--------|
| Node.js (tess + crumb + e2e) | 416 | PASS |
| Python dispatch_engine | 172 | PASS |
| Python CTB-028 e2e | 58 | PASS |
| Python stage_runner | 62 | PASS |
| Python brief_builder | 32 | PASS |
| Python dispatch_state | 82 | PASS |
| Python watcher unit | 34 | PASS |
| Python watcher integration | 11 | PASS |
| **Total** | **867** | **PASS** |

### Phase 2 Live Deployment — FIRST SUCCESSFUL DISPATCH

**Deployment steps:**
1. Created `_openclaw/dispatch/` (rwxrwxr-x tess:crumbvault)
2. Updated SKILL.md (source + deployed) with Phase 2 operations
3. Sent test invoke-skill (audit) from Telegram

**Live dispatch iteration (6 attempts, 4 code fixes):**

| Attempt | Failure | Fix |
|---------|---------|-----|
| 1 | Wrong routing: stale watcher → bridge-processor.js | kill -9, launchd restart |
| 2 | STAGE_FAILED: 4 missing schema fields | Explicit JSON template in brief_builder |
| 3 | STAGE_FAILED: 3 field name mismatches | Runner-side `setdefault()` for deterministic fields |
| 4 | STAGE_FAILED: deliverables as dict, not list | Coerce non-list deliverables → `[]`, preserve as `_raw_deliverables` |
| 5 | GOVERNANCE_STAGE_FAILED: canary off-by-one | Hybrid governance: verify hash only, stamp authoritative canary |
| 6 | **SUCCESS** | All fixes held |

**Code changes (3 files, all with passing tests):**
- `stage_runner.py`: runner-side defaults (5 deterministic fields), deliverables coercion, hybrid governance verification
- `brief_builder.py`: explicit stage output JSON template with all 8 required fields
- `CLAUDE.md`: "Bridge Dispatch Stage Output" section (12 lines) — dispatch schema on the guaranteed-loaded instruction surface

**Architectural insight (user):** CLAUDE.md is the guaranteed instruction surface for `claude --print`. The brief builder prompt alone was too fragile for model-interpreted fields. Adding the schema to CLAUDE.md means every spawned instance sees it in the auto-loaded file, not just in the user prompt.

**Result — dispatch ID `019c8669`:**
- `lifecycle_state: complete`, `status: done`, `governance_verified: true`
- Audit skill output: 71 signals analyzed, 5 findings (1 MEDIUM: CLAUDE.md 261 lines, 4 LOW)
- Full pipeline: Telegram → Tess → OpenClaw → Watcher → Dispatch Engine → `claude --print` → Stage Runner (schema + policy + governance) → Response → Outbox

**CLAUDE.md impact:** Now at 261 lines (past 250 ceiling). Refactoring is next priority.

**Lessons learned — codify for Phase 2 operations:**
1. Runner-side defaults for deterministic fields: never trust the model for values the runner already knows
2. Model-judgment fields need CLAUDE.md backing, not just prompt
3. Canary reproduction is unreliable (byte-boundary sensitivity); hash verification is sufficient for governance
4. Every code change to dispatch engine modules requires watcher restart (Python module caching)
5. Deliverables schema designed for file-producing tasks; analysis/read-only skills need coercion (design smell for Phase 3)

### Compound Engineering — Patterns Captured

**Trigger:** Reusable artifacts (4 patterns confirmed independently by human + system), system gap (solutions retrieval path)

**Patterns routed to `_system/docs/solutions/claude-print-automation-patterns.md`:**
1. Runner owns deterministic fields — split at content/metadata boundary
2. CLAUDE.md as durable instruction surface — structural privilege over prompt
3. Hash-verify, canary-stamp — computable vs extractable values
4. Budget time for live deployment iteration — prompt-model contract calibration

**Operational patterns routed to `_system/docs/openclaw-skill-integration.md`:**
- Pitfall 7: Python module caching requires watcher restart
- Pitfall 8: Tess polling timeout vs dispatch duration

**Design note routed to `dispatch-protocol.md` §4.3:**
- Schema variants per operation class (deliverables mismatch for analysis ops)

**System gap identified and fixed:**
- `_system/docs/solutions/` was a write-only directory — compound engineering wrote patterns there but no skill actively searched it during SPECIFY or PLAN
- Fix: added "search for prior art" step to systems-analyst Step 1 and "search for implementation patterns" step to action-architect Step 1
- Write side was already mechanical (spec §4.4 routing table); read side is now mechanical too

### Session 31 End — 2026-02-22

**Summary:** Ran CTB-028 gate (867 tests pass). Deployed Phase 2 dispatch to production. First successful end-to-end dispatch (invoke-skill audit) through Telegram after 6 iterations and 4 code fixes hardening the stage runner, brief builder, and CLAUDE.md. Captured 4 reusable automation patterns via compound engineering. Fixed solutions retrieval gap in systems-analyst and action-architect skills.

**Compound:** Four high-confidence patterns captured in `_system/docs/solutions/claude-print-automation-patterns.md` — all confirmed independently by human and system. System gap: solutions directory was write-only (compound writes, skills don't read). Fixed by adding active search steps to SPECIFY/PLAN-phase skills. The retrieval gap itself is a meta-pattern worth watching: any time compound engineering routes to a new destination, verify the read path exists, not just the write path.

## Session 32 — 2026-02-24

### Quick-Capture Scope Filing

**Source:** `_inbox/tess-quick-capture-scope.md` — scoping doc for a lightweight Tess → Crumb capture pathway via Telegram, separate from the bridge protocol's governed operations.

**Routing decision:** Filed under crumb-tess-bridge (not standalone project) because it shares infrastructure ownership: `_openclaw/inbox/` directory, bridge watcher, Tess skill surface. The ceremony mismatch (bridge = hash-bound confirmation; quick-capture = write → done) is real but not disqualifying — it's a lightweight annex, not a competing paradigm.

**Operator feedback incorporated (4 items):**
1. §3 reframed: "No Changes Required for `.md` Routing" (was "No Changes Required") — clarifies that §6's defensive watcher fix is a separate concern, now explicit task CTB-035
2. `.processed/` cleanup policy added: purge files older than 30 days, aligns with CTB-027 retention
3. `research`/`review` hint boundary note: treat identically until researcher-skill is built
4. Frontmatter added to the scope doc

**Tasks created:** CTB-032 through CTB-036 (5 tasks):
- CTB-032: OpenClaw quick-capture skill definition
- CTB-033: Vault taxonomy update (`quick-capture` type)
- CTB-034: Session startup capture check (depends on CTB-032)
- CTB-035: Watcher defensive fix — short-circuit non-bridge JSON (independent)
- CTB-036: Capture processing procedure (depends on CTB-034; researcher-skill dependency noted)

**Cross-project notes:**
- feed-intel-framework M-Manual (filed same session) covers URLs routed through the feed-intel pipeline — distinct from quick-capture's general-purpose vault routing
- researcher-skill (SPECIFY, blocked) will eventually differentiate `research` from `review` hint handling

### Code Review Prep (Tier 1)

**Test gate:**
- JS: 224/224 green (Node.js native test runner)
- Python: 1 failure — `test_next_stage_missing_subfields` in `test_stage_runner.py:855`

**Test gate waiver (operator-approved):**
- Failed test: `test_next_stage_missing_subfields` (`src/watcher/test_stage_runner.py:855`)
- Reason: Pre-existing failure, not in the review scope (review covers 175-line non-test source diff from last 2 commits). Diagnosis: test expectation bug vs. validation gap — separate fix.
- Waiver granted by operator 2026-02-24.

**Review scope:** 175-line non-test source diff (last 2 commits, excluding tests and SKILL.md). Dispatch pending — deferred to next session for fresh context window.

### Code Review (Tier 1)
- Scope: Session 31 live deployment fixes (brief_builder.py, stage_runner.py) — commits 773df09..32787a0
- Model: devstral-small-2 | Latency: 84s | Parse: clean
- Findings: 0 critical, 2 significant, 18 minor, 0 strengths
- Details:
  - [F1] SIGNIFICANT: stage_runner.py:477 — Non-dict `governance_check` from model would raise AttributeError on `.get()` call. Guard with `isinstance` check. **Fixed.**
  - [F2] MINOR: brief_builder.py:376 — Template placeholder naming (`YOUR_SUMMARY_HERE`) could be clearer. Style call, not a bug.
  - [F3] MINOR: stage_runner.py:477 — No log line at hash mismatch detection point (before verify_governance alert path).
  - [F4-F20] MINOR: 17 false positives — misunderstandings of `setdefault`, `dict.get()`, intentional canary overwrite design, duplicates.
- Signal-to-noise: ~15% (3 actionable / 20 total). Calibration note: FIF review was 58% (7/12) on a larger, more complex diff (1,338 lines). Devstral's false positive rate may scale inversely with diff complexity — less real surface area → more hallucinated findings.
- Action: F1 fixed (genuine defensive gap); F2-F3 deferred (style/operational); F4-F20 discarded (false positives)

**Process observations (operator):**
1. **repo_path gap:** Session initially searched `~/openclaw/crumb-tess-bridge/` (doesn't exist — code is vault-resident). Added `repo_path: vault://Projects/crumb-tess-bridge/src/` to project-state.yaml. Convention: `vault://` prefix for in-vault code, absolute path for external repos.
2. **Scope narrowing:** Correct this time — explicit commit range, line count verification, scope statement before dispatch. Matches the behavior that was missing in the FIF review.
3. **SKILL.md blind spot:** The 90-line SKILL.md diff (Tess prompt changes) was excluded per "non-test source" scope. SKILL files are an uncategorized type for code-review — not test, not config, but not traditional source either. Prompt engineering bugs are subtle. Skill gap to address: add SKILL/prompt file guidance to code-review skill definition.

### Code Review (Tier 2) — First Validation Run
- Scope: Session 31 live deployment fixes (brief_builder.py, stage_runner.py) — commits 773df09..32787a0
- Panel: 3/3 reviewers (OpenAI gpt-5.2, Mistral devstral-medium-latest, Anthropic claude-opus-4-6). Anthropic dispatched separately after key was configured.
- Safety gate: clean (no false positives on placeholder patterns)
- Review note: `reviews/2026-02-24-code-review-task.md`
- Tag: `code-review-tier2-2026-02-24` on commit 32787a0

**Pipeline validation results:**
- API keys: OpenAI ✓, Mistral ✓, Anthropic ✓ (added mid-session)
- Concurrent dispatch: ✓ (Mistral 14.5s, OpenAI 34.2s)
- Safety gate: ✓ (no false positives on `YOUR_SUMMARY_HERE`, `FIRST_12_HEX_...`, etc.)
- Review note frontmatter: ✓ (all required fields, finding namespaces OAI-/MST-)
- Synthesis: ✓ (all 5 sections: Consensus, Unique, Contradictions, Action Items, Considered and Declined)
- Model tags: gpt-5.2 → gpt-5.2-2025-12-11 ✓, devstral-medium-latest ✓

**Synthesis highlights:**
- 6 consensus findings (2+ reviewers): governance relaxation (3/3), deliverables coercion (3/3), setdefault conflicts (2/3), project_state_read inconsistency (2/3), test coverage (2/3), template deliverables type (2/3)
- 1 consensus strength: runner-default injection (2/3)
- Key unique: ANT-F2 (validate_schema mutates input — contract violation), ANT-F5 (hash replay risk)
- 11 action items: 3 must-fix (template `{}` → `[]`, coercion log line, extract coercion from validate_schema), 3 should-fix (identity field assertion, claude_md_loaded consistency, canary match logging), 5 deferred
- Anthropic confirmed all 3 Tier 1 findings (isinstance guard fixed, placeholder present, missing log line)

## Maintenance 2026-02-25 — Quick-Capture Skill Deployment

**Scope:** Maintenance artifact on DONE project (per CLAUDE.md Completed Project Guard).

**Problem:** User tested quick-capture via Telegram/Tess. Tess routed the request through
the bridge protocol (quick-fix JSON dispatch) instead of the quick-capture skill's lightweight
markdown path. This is exactly the anti-pattern the quick-capture design was built to prevent:
"An LLM should never generate bridge-schema JSON."

**Root cause:** The quick-capture skill definition existed in the project source
(`Projects/crumb-tess-bridge/src/tess/quick-capture-skill.md`) but was never deployed to
Tess's active skills directory (`_openclaw/skills/`). Without the skill in her rotation,
Tess fell back to the bridge protocol — the only vault-write mechanism she knew about.

The `write-capture` CLI subcommand was already implemented and functional (bridge-cli.js line 540).

**Fix applied:**
- Created `_openclaw/skills/quick-capture/SKILL.md` with OpenClaw-format frontmatter
- Description includes all trigger phrases ("save this for Crumb", "send to Crumb", etc.)
- Procedure references bridge-cli.js with absolute path
- CLI verified: `write-capture --body '...' --hint research` produces correct capture file
- Test capture written and cleaned up successfully

**Verification — 4 test rounds, all failed:**

Tess never invoked the quick-capture skill. Every attempt routed through crumb-bridge.
Three distinct failure modes identified:

1. **Conversation context anchoring** — First test: Tess wrote a `note-*.md` file
   (wrong prefix) as JSON (wrong format), moved to `.unrecognized/` by watcher.
   She was using her native file-write tool with improvised naming.

2. **Sandbox file-write limitation** — Second test: skill rewritten to use Tess's
   Write File tool with exact filename template and frontmatter schema inline.
   Write failed silently — file never reached the inbox. Tess's file-write tool
   is sandboxed and can't write to the vault path.

3. **Skill matching priority** — Third/fourth tests: skill rewritten back to CLI
   approach. Tess still routed through crumb-bridge (as `invoke-skill` → `research`).
   The quick-capture skill is not being selected by OpenClaw's skill router regardless
   of how the SKILL.md is authored.

**Root cause (revised):** Not a deployment issue — the skill file is present at
`_openclaw/skills/quick-capture/SKILL.md`. The issue is OpenClaw's skill router
prioritizing crumb-bridge over quick-capture for capture-intent messages. Needs
investigation into OpenClaw skill matching/priority mechanics.

**Workaround (confirmed working):** Bridge path processes captures reliably.
The `invoke-skill` → `research` dispatch carries the URL and gets the job done,
just through the governed path instead of lightweight staging.

**Decision: Abandon quick-capture skill in favor of bridge `capture` operation.**

Rationale: The quick-capture skill's value was structured processing hints, not ceremony
reduction. After 4 test rounds, the standalone skill approach is dead — Tess's skill
router won't select it, her file-write tool can't reach the vault, and she has no bash
access for CLI fallback. The bridge protocol is the only working write path.

The fix is to add `capture` as a first-class bridge operation type:
```json
{
  "operation": "capture",
  "params": {
    "url": "https://x.com/...",
    "hint": "research",
    "suggested_domain": "learning"
  }
}
```

This gives structured hints through the bridge's existing echo → confirm → process
infrastructure. The crumb-bridge skill already handles routing, and the watcher
already dispatches by operation type. Crumb-side processing (CTB-036) is built —
just needs wiring from the bridge operation to the same processing functions.

The `_openclaw/skills/quick-capture/` directory can be removed once the bridge
capture operation is implemented.
