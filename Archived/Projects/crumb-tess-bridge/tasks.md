---
type: task-list
domain: software
status: draft
created: 2026-02-19
updated: 2026-02-25
project: crumb-tess-bridge
skill_origin: action-architect
tags:
  - openclaw
  - security
  - integration
---

# Crumb–Tess Bridge — Task List

## Task Table

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|---------------------|
| CTB-001 | Research Claude Code `--print` mode capabilities | done | — | medium | research | `--print` CLAUDE.md loading behavior is documented (YES/NO per capability). Tool access matrix recorded. Session startup time measured. GO/NO-GO decision documented: proceed with B4 runner or fallback architecture required. Findings written to run-log |
| CTB-002 | Research Telegram message formatting constraints | done | — | low | research | Telegram markdown rendering rules documented. Code block behavior tested. 4096-char truncation behavior confirmed. Echo display template validated against real Telegram rendering |
| CTB-003 | Design bridge request/response JSON schema | done | CTB-001, CTB-002 | medium | design | Schema doc exists with both request AND response structures (including error responses with error code + human-readable message). All Phase 1 operations covered. Operation allowlist defined as single authoritative source (schema enum); both Tess and Crumb import from it; rejection schema for out-of-scope operations with test vector. Schema versioning strategy documented: `schema_version` required, consumers reject unknown major versions. Canonical JSON test vector committed as first-class artifact (`_openclaw/spec/canonical-json-test-vector.json`) with ≥2 vectors including edge cases; both Node.js and Crumb-side implementations produce byte-identical output. Schema validated against Telegram 4096-char limit for echo display |
| CTB-004 | Build OpenClaw bridge skill — protocol mechanics | done | CTB-003 | high | code | Skill uses strict command parsing into allowlisted operations (no free-form NLU). Unknown operations rejected with explicit error code. UUIDv7 generated for each bridge request; format matches RFC 9562 (time-ordered, sortable). Canonical JSON serialization produces correct byte sequence. Payload hash computation matches all test vectors. Schema validation rejects malformed fields. Atomic write to `_openclaw/inbox/` via rename. Unit tests pass for hash computation, schema validation, allowlist rejection, and UUIDv7 generation |
| CTB-015 | Build OpenClaw bridge skill — Telegram UX | done | CTB-004 | low | code | Confirmation echo displays exact canonical JSON + hash code in Telegram. Outbox watcher detects Crumb responses. Telegram relay formats structured updates within 4096 chars. Unit tests pass for echo formatting and relay display |
| CTB-005 | Build Crumb bridge-processing procedure | done | CTB-003 | high | code | Procedure reads inbox files. Schema validation rejects malformed requests. Out-of-scope operations rejected (Phase 1 allowlist enforced). Payload hash recomputed and verified. Duplicate request IDs rejected via `.processed-ids`; replay test: same UUIDv7 sent twice → second rejected with duplicate ID error. Rejected requests produce structured error response in outbox with error code and human-readable message (relayable to Telegram). Operation executes under CLAUDE.md governance. Response written to outbox matching response schema. Transcript written to `_openclaw/transcripts/`. Inbox file moved to `.processed/` |
| CTB-006 | Create transcript infrastructure | done | CTB-003 | low | setup | `_openclaw/transcripts/` directory exists. `_openclaw/inbox/.processed/` directory exists. Transcript format documented. `.gitignore` updated for `.processed/` contents if needed |
| CTB-007 | End-to-end Phase 1 integration test | done | CTB-015, CTB-005, CTB-006 | medium | testing | Full round trip completes: Telegram message → Tess echo → user CONFIRM with hash → inbox file written → Crumb processes in interactive session → outbox response exists → Tess relays update to Telegram. Governance fields present in response |
| CTB-008 | Prompt injection test suite for confirmation echo | done | CTB-015 | high | security | 10+ injection payloads tested, including Telegram-specific adversarial cases (zero-width characters, RTL/LTR markers, codeblock-breaking sequences) tested through actual Telegram rendering, not just local string comparison. At least one transcript-poisoning payload tested: does not corrupt transcript file format, does not cause misinterpretation by Crumb on re-read, and renders unambiguously for human review. At least one "JSON-shaped but semantically malicious" payload tested: long `reason` strings that push critical fields (hash, CONFIRM code) off-screen in the Telegram echo display (R3 finding — Perplexity). Each payload has documented result: caught-by-echo, caught-by-hash, caught-by-schema, survived. Residual risk assessment written. No HIGH-severity bypasses remain unmitigated. **Validation gate:** Phase 1 daily use is blocked until this passes |
| CTB-009 | Research file-watch latency options | done | — | low | research | Latency measured for launchd WatchPaths, fswatch, and kqueue. Reliability under load documented. Resource usage compared. Recommendation with justification written to run-log |
| CTB-010 | Measure token cost per bridge session | done | CTB-001 | low | research | CLAUDE.md load token count measured. Per-operation token usage measured for each Phase 1 operation. Monthly cost projected at 5, 20, and 50 requests/day. Go/no-go threshold documented |
| CTB-011 | Build file-watch + bridge runner for Phase 2 | done | CTB-007, CTB-009, CTB-010 | high | code | File watcher detects new inbox files within acceptable latency. Bridge runner acquires flock before spawning session. pgrep check prevents overlap with interactive sessions. Shell alias/wrapper for interactive `claude` that checks bridge lockfile before launching — closes TOCTOU gap from the interactive side (R3 finding — Gemini). `claude --print` invoked with bridge request context. Output captured and written to outbox. Transcript persisted. Rate limiting enforced (configurable max/hour). Kill-switch file checked before each invocation. Errors reported to outbox with retryable flag. U3 validated: repeated automated invocations work correctly, state persistence across sessions confirmed, no session collision with interactive sessions. LaunchAgent environment explicitly configured — Keychain access, PATH, HOME, and API key sourcing validated under sparse launchd environment (R3 finding — Gemini, extends CTB-001 Keychain finding) |
| CTB-012 | Build governance verification test suite | done | CTB-011 | high | security | Automated tests verify: governance_hash matches runner's pre-computed hash. Governance canary matches last 64 bytes of CLAUDE.md. Response JSON matches bridge response schema. Tests integrated into bridge runner validation pipeline. Failure → response discarded + Telegram alert |
| CTB-013 | Update colocation spec threat model | done | CTB-007 | medium | writing | Colocation spec's threat model includes bridge-specific threats BT1-BT7. Existing threat ratings reviewed and updated where bridge changes the risk. Cross-reference to bridge spec added |
| CTB-014 | Peer review of bridge implementation | done | CTB-008, CTB-012, CTB-013, CTB-016 | medium | review | 4-model peer review completed. Dispatch protocol (CTB-016) included as review input alongside injection test results (CTB-008). All must-fix findings addressed. Review note written to vault |
| CTB-016 | Design dispatch protocol for long-running task execution | done | CTB-003 | high | design | `design/dispatch-protocol.md` exists. Defines: task lifecycle states and transitions (queued/running/stages/blocked/complete/failed), status update file pattern (outbox progress writes during execution), structured escalation contract (block + structured questions + resume), generic brief/deliverable I/O contracts (skill-agnostic), completion pattern (artifact + evidence + audit trail). Security: budget enforcement (token/time/tool-call caps), stage-level governance verification, kill-switch respect between stages, escalation injection resistance. Schema extensions: new Phase 2 operation `dispatch-task` (or extension to `invoke-skill`) with lifecycle support, status update message schema, escalation request/response schema. Peer reviewed independently (2 rounds, 4 models each). Researcher-skill project consumes this protocol as first client. |

## Phase 2: Dispatch Protocol Implementation

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|---------------------|
| CTB-017 | Phase 2 schema extensions | done | — | medium | code | Phase 2 operations (`start-task`, `invoke-skill`, `quick-fix`, `escalation-response`, `cancel-dispatch`) added to constants.js allowlist with param validators. Schema version bumped to `1.1`. schema.js validates all Phase 2 param types (project, task_id, skill, args, description, files, dispatch_id, escalation_id, answers, budget). bridge-processor.js rejects Phase 2 ops with `OPERATION_REQUIRES_DISPATCH`. All 8 new dispatch error codes (`BUDGET_EXCEEDED`, `STAGE_FAILED`, `KILL_SWITCH`, `ESCALATION_TIMEOUT`, `GOVERNANCE_STAGE_FAILED`, `DISPATCH_CONFLICT`, `CANCELED_BY_USER`, `RUNNER_RESTART`) added to constants.js with canonical descriptions. Unit tests pass for new operation validation, rejection paths, and error code definitions |
| CTB-018 | Dispatch state module | done | — | medium | code | Python module `dispatch_state.py` exists. Creates dispatch state files in `_openclaw/dispatch/` matching §2.5 schema. State machine transitions enforce §2.3 rules (invalid transitions rejected with error). Atomic writes (tmp + rename). `crash_recovery_scan()` handles all non-terminal states per §2.5 (running → failed, queued → failed, stage-complete → failed, blocked remains resumable). Terminal state cleanup prunes files older than 30 days. Unit tests cover all 13 transition rules + crash recovery + cleanup |
| CTB-019 | Brief construction + stage prompt builder | done | CTB-017, CTB-018 | high | code | Python module constructs briefs from request params per §7.1 (operation-specific rules: start-task reads task AC, invoke-skill uses args, quick-fix uses description). Budget defaults per operation (§7.1 table) with hard caps enforced on authoritative dimensions (25 stages, 3600s wall-time); tool_calls and tokens tracked as advisory (logged in state, not enforcement boundaries per §8.1). Stage prompt builder produces two-layer prompts per §4.2: Layer 1 (system prompt via `--append-system-prompt`) contains safety directives and budget info; Layer 2 (user prompt) contains brief + untrusted previous stage context. Previous stage context explicitly framed as "UNTRUSTED." Unit tests verify brief construction for all 3 dispatch operations, budget cap enforcement, and prompt layer separation |
| CTB-020 | Stage runner + output validation | done | CTB-018, CTB-019 | high | code | Python module spawns `claude --print` with stage prompts. Subprocess timeout = `min(remaining_wall_time, 3600)` per §3.1. Reads stage output JSON from `_openclaw/outbox/{dispatch_id}-stage-{N}.json`. Validates against §4.3 schema (all required fields, valid status enum). Enforces §4.6 policy: `next_stage.instructions` ≤4000 chars ASCII-only, `context_files` vault-relative with no traversal and no sensitive paths, `handoff` ≤8KB. Pre-spawn CLAUDE.md hash check. Post-stage `governance_check` field verified against runner's hash + canary. Malformed output handling per §11.3 (one retry with repair prompt, then fail). Stage output read from disk (written by Claude via Write tool per prompt instructions), not captured from stdout; if stage output file missing after session exit with code 0, treated as malformed output per §11.3. Governance failure during dispatch writes structured alert JSON to `_openclaw/alerts/` for Tess pickup. Unit tests cover schema validation, policy rejection, governance verification, retry logic, missing file handling, and alert emission |
| CTB-021 | Dispatch engine + watcher routing | done | CTB-019, CTB-020 | medium | code | Python dispatch engine orchestrates: request validation → state creation (queued) → flock acquisition → stage spawn → output evaluation → state transition → response/next-stage. bridge-watcher.py routes: Phase 1 ops (`approve-gate`, `reject-gate`, `query-*`, `list-projects`) → `_dispatch_node`; Phase 2 ops (all 5: `start-task`, `invoke-skill`, `quick-fix`, `escalation-response`, `cancel-dispatch`) → dispatch engine. `escalation-response` and `cancel-dispatch` route to dispatch engine for correlation with active dispatches. Routing based on operation field parsed from request JSON. If flock acquisition fails or another dispatch is active, reject with `DISPATCH_CONFLICT` error. Single-stage dispatch (`status: done`) produces final response in outbox. Integration tests: `invoke-skill` request → mock `claude --print` → final response in outbox; concurrent request → `DISPATCH_CONFLICT` |
| CTB-022 | Multi-stage lifecycle + budget enforcement | done | CTB-021 | medium | code | Dispatch engine handles `status: next` → spawn next stage with handoff + summaries. Stage counter incremented. Wall-time tracked from `dispatch_started_at` (§8.2). Wall-time clock pauses when dispatch enters `blocked` state and resumes on exit; persisted fields: `dispatch_started_at`, `total_blocked_seconds` (derived from `pending_escalation.blocked_at` timestamps). Budget warnings injected at ≤20% remaining. `BUDGET_EXCEEDED` when stage or wall-time limits hit. Hard caps enforced regardless of user override. Dispatch state persisted after every transition (atomic write). Stage boundary checkpoint: check inbox for `cancel-dispatch` before spawning next stage. Tests: 3-stage dispatch with handoff, budget exceeded at stage limit, budget exceeded at wall-time limit, budget warning injection |
| CTB-023 | Status updates | done | CTB-021 | low | code | Runner writes `{dispatch_id}-status.json` to outbox after each stage (§5.2 schema). File overwritten per stage (latest status only). Fields: lifecycle_state, stage_completed, stage_current, summary, budget_remaining, estimated_completion (nullable — null unless stage count known and average stage duration computable from completed stages). Tests: status file schema validation, overwrite behavior, nullable estimated_completion |
| CTB-024 | Structured escalation flow | done | CTB-022 | high | code | Stage `status: blocked` triggers escalation. Runner validates §6.2 schema: `^[A-Za-z0-9 ,.;:!?'()-]{1,80}$` regex on options, max 3 questions, `choice`/`confirm` types only, strip `default` field. Questions + options persisted in dispatch state (`pending_escalation`). Escalation relay written to outbox for Tess. Runner polls inbox for `escalation-response` with matching dispatch_id + escalation_id. Answers resolved: option indices → runner-persisted option text (not raw user input). Resume prompt constructed per §6.5 with runner-resolved text. Escalation timeout: 30min default, `ESCALATION_TIMEOUT` on expiry. Risk-gate: `risk` type gets visual warning flag. Only first valid `escalation-response` accepted; subsequent duplicates logged and ignored. Wrong `escalation_id` → ignored with warning. Late response after timeout → ignored. Tests: schema validation (accept valid, reject regex failures), option index resolution, timeout, resume prompt construction, duplicate response handling, wrong-id rejection, late-after-timeout rejection |
| CTB-025 | Cancel-dispatch + inter-stage kill-switch | done | CTB-022 | medium | code | Stage boundary checkpoint polls inbox for `cancel-dispatch`. On receipt: `cancel_requested_at` + `cancel_request_id` persisted immediately (atomic write). Cancel/completion precedence per §2.3: if stage output `done`, completion wins; if `next` or `blocked`, cancel wins. Kill-switch (`~/.crumb/bridge_disabled`) checked before every stage spawn and before escalation resume. `CANCELED_BY_USER` response includes partial deliverables from completed stages. `KILL_SWITCH` response includes deliverables from governance-verified stages. Tests: cancel at stage boundary, cancel during blocked, cancel vs completion precedence, kill-switch detection |
| CTB-026 | Tess dispatch CLI support | done | CTB-017 | medium | code | bridge-cli.js handles Phase 2 operations: `start-task`, `invoke-skill`, `quick-fix` go through standard validate → hash → echo → confirm → write flow (using Phase 2 schema). `escalation-response` parsing: `ANSWER {dispatch_id_short} {answers}` → structured request with option indices. `cancel-dispatch` parsing: `CANCEL {dispatch_id_short}` → structured request. outbox-watcher extended to detect `-status.json` files and relay progress. echo-formatter.js formats escalation questions with neutral labels (§6.3: no default highlighting). Two-step confirmation for risk-gate escalations. Tess-side `echo-formatter.js` formats status updates for Telegram (§5.3 template). All 8 new dispatch error codes correctly formatted and relayed. Tests: all 5 Phase 2 operations validate + format correctly, ANSWER/CANCEL parsing, status update detection, status format output, error code formatting |
| CTB-027 | Audit trail + final response | done | CTB-022, CTB-024 | medium | code | Audit hash computed per §7.3: sha256(each transcript) concatenated with `\n`, sha256(concatenation)[:12]. Final response per §7.2: deliverables from all stages, stages_executed, escalations count, budget_used (stages, tool_calls, wall_time, tokens, estimated_cost_usd), transcript_paths, audit_hash, governance_check from last stage. `_openclaw/dispatch/` state file retained for 30 days. Stage output files retained for 30 days. Final responses + transcripts retained indefinitely. Tests: audit hash deterministic computation, final response schema, cleanup timing |
| CTB-028 | E2E dispatch validation + injection tests | done | CTB-022, CTB-024, CTB-025, CTB-026, CTB-027 | high | testing | E2E through watcher pipeline with mock `claude --print` (simulated stage outputs): 1-stage invoke-skill → complete, 3-stage research with handoff → complete, escalation round-trip → resume → complete, cancel mid-dispatch → partial deliverables, budget exceeded → partial deliverables, governance failure at stage 2 → halt with manifest + alert, kill-switch mid-dispatch → halt, crash recovery → failed with RUNNER_RESTART. Injection payloads: malicious `next_stage.instructions` (prompt override attempts), path traversal in `context_files` (../../.ssh/id_rsa), oversized handoff (>8KB), escalation options failing regex (backticks, slashes, unicode), fabricated governance_check. All injection payloads caught by runner policy validation. **Validation gate: Phase 2 daily use blocked until this passes** |
| CTB-029 | Telegram alerts (A11) | done | — | low | code | Tess polls `_openclaw/alerts/` for new `.json` files. Alert relayed to Telegram with severity-appropriate formatting (timestamp, error code, affected request ID, human-readable message). Old alerts cleaned up after relay. Unit tests for alert formatting. Watcher already writes alerts — this is the Tess relay side |
| CTB-030 | .processed-ids Set optimization (A12) | done | — | low | code | bridge-watcher.py loads `.processed-ids` into Python `set` on startup. In-memory set used for O(1) duplicate detection (replaces line-by-line file scan). File-append maintained for persistence. Set updated on each `record()` call. Startup loading handles malformed entries gracefully. Unit tests: O(1) lookup confirmed, set/file consistency, malformed entry handling |
| CTB-031 | Production sender allowlist (A13) | done | — | medium | code | Sender allowlist config: `CRUMB_BRIDGE_ALLOWED_SENDERS` env var (comma-separated user IDs) or config file. Tess-side: `source.user_id` validated against allowlist before echoing confirmation (pre-inbox gate). Crumb-side: bridge-processor.js validates `source.user_id` as backstop. Unknown senders rejected with `UNKNOWN_SENDER` error. Empty allowlist = allow all (backward compatible). Tests: allow known sender, reject unknown, empty list behavior, Crumb-side backstop |

## Dependency Graph

### Phase 1 (complete)

```
                    ┌── CTB-004 ── CTB-015 ──┬── CTB-007 ──┬── CTB-013 ──┐
CTB-001 ──┬── CTB-003 ──┤                        │              │              │
CTB-002 ──┘         ├── CTB-005 ─────────────┤              ├── CTB-011 ── CTB-012 ──┤
                    ├── CTB-006 ─────────────┘              │                        │
                    │                                       │                        │
                    └── CTB-016 ────────────────────────────┤                   CTB-014
                        (dispatch protocol)                 │                        ▲
                                                            │                        │
CTB-009 ────────────────────────────────────────────────────┤               CTB-016 ─┘
CTB-010 ────────────────────────────────────────────────────┘

CTB-008 ── (parallel after CTB-015, gates Phase 1 daily use) ─── CTB-014
```

### Phase 2 (dispatch implementation)

```
CTB-017 ──┬── CTB-019 ──┬── CTB-020 ──┐
           │              │              ├── CTB-021 ──┬── CTB-022 ──┬── CTB-024 ──┬── CTB-027 ──┐
CTB-018 ──┘              │              │              │              ├── CTB-025    │              │
                          │              │              ├── CTB-023    │              │              │
                          │              │              │              │              │         CTB-028
                          │              │              │              │              │              ▲
                          │              │              │              │              │              │
CTB-017 ── CTB-026 (parallel with engine work) ────────┘              │              │              │
                                                                       └──────────────┴──────────────┘

CTB-029, CTB-030, CTB-031 (independent — any time)
CTB-037 (independent — persistent service registration)

CTB-032 ──→ CTB-034 ──→ CTB-036    (quick-capture: skill → startup check → processing)
CTB-033 (independent — taxonomy update)
CTB-035 (independent — watcher defensive fix)
```

**Critical path:** CTB-017 → CTB-019 → CTB-020 → CTB-021 → CTB-022 → CTB-024 → CTB-027 → CTB-028

## Parallel Execution Opportunities

### Phase 1 (complete)

**Immediate (no dependencies):**
- CTB-001, CTB-002, CTB-009 can all start in parallel

**After CTB-003:**
- CTB-004, CTB-005, CTB-006, CTB-016 can all start in parallel

### Phase 2

**Immediate (no Phase 2 dependencies):**
- CTB-017, CTB-018 in parallel
- CTB-029, CTB-030, CTB-031 (deferred items) any time

**After CTB-017 + CTB-018:**
- CTB-019 unblocks

**After CTB-019:**
- CTB-020 unblocks (needs both CTB-018 state + CTB-019 prompts)

**After CTB-021 (engine operational):**
- CTB-022, CTB-023 can overlap (engine extensions)
- CTB-026 (Tess CLI) can overlap (only needs CTB-017)

**After CTB-022:**
- CTB-024 unblocks (escalation needs multi-stage)
- CTB-025 unblocks (inter-stage cancel/kill-switch needs multi-stage)

**After CTB-024:**
- CTB-027 unblocks (final response needs multi-stage deliverables + escalation count)

**After CTB-025 + CTB-026 + CTB-027:**
- CTB-028 (validation gate)

## Phase Mapping

| Phase | Tasks | Gate |
|-------|-------|------|
| Phase 1: Async File Exchange | CTB-001 through CTB-008, CTB-013, CTB-015 | CTB-007 passes (full round trip) AND CTB-008 passes (no HIGH-severity injection bypasses) |
| Phase 1.5: Dispatch Protocol Design | CTB-016 | Protocol designed + 2-round peer review |
| Phase 1.5: Automation | CTB-011, CTB-012 | Governance verification automated |
| Phase 1 Cross-cutting | CTB-014 | All must-fix addressed |
| Phase 2: Dispatch Foundation | CTB-017, CTB-018 | Schema + state module operational |
| Phase 2: Walking Skeleton | CTB-019, CTB-020, CTB-021 | Single-stage dispatch works e2e |
| Phase 2: Multi-Stage | CTB-022, CTB-023 | Multi-stage with budget enforcement |
| Phase 2: Escalation & Cancel | CTB-024, CTB-025 | Escalation round-trip + cancel works |
| Phase 2: Integration | CTB-026, CTB-027 | Tess CLI + audit trail complete |
| Phase 2: Validation | CTB-028 | E2E + injection tests pass — **gates Phase 2 daily use** |
| Deferred Hardening | CTB-029, CTB-030, CTB-031 | Independent — any time |
| Persistent Service | CTB-037 | Independent — watcher + dispatch engine complete |
| Quick-Capture | CTB-032, CTB-033, CTB-034, CTB-035, CTB-036 | Independent — any time after Phase 2 watcher exists |

## Persistent Service

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|---------------------|
| CTB-037 | Register bridge-watcher.py as persistent launchd service | done | — | medium | infra | `ai.openclaw.bridge.watcher` plist registered as LaunchAgent with `KeepAlive=true`. Environment: PATH (includes `~/.local/bin` for claude CLI), HOME, CRUMB_VAULT_ROOT. Logs to `_openclaw/logs/watcher.{log,err}`. KeepAlive restart verified (SIGTERM → clean shutdown → auto-restart). No duplicate processes — pre-existing `com.crumb.bridge-watcher` plist removed. `com.apple.provenance` xattr stripped before bootstrap. Single-process invariant confirmed. pgrep advisory check defers processing when interactive Claude session active |

## Quick-Capture: Lightweight Capture Path

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|-------------|-------|------------|------|--------|---------------------|
| CTB-032 | OpenClaw quick-capture skill definition | done | — | low | code | Skill file in Tess workspace with trigger patterns for capture intent. Writes `.md` to `_openclaw/inbox/` with `capture-{YYYYMMDD}-{HHMMSS}.md` naming. YAML frontmatter matches §2 schema (type, source, captured_by, captured_at, suggested_domain, suggested_tags, processing_hint). Body contains free-form markdown with URL and processing instructions. Post-write Telegram confirmation. Unit tests for frontmatter generation and filename format |
| CTB-033 | Vault taxonomy update — add `quick-capture` type | done | — | low | setup | `quick-capture` added to type taxonomy in `_system/docs/file-conventions.md`. vault-check accepts `type: quick-capture` in frontmatter validation |
| CTB-034 | Session startup capture check | done | CTB-032 | low | code | Session startup detects `capture-*.md` files in `_openclaw/inbox/`. Reports count and titles: "Tess left N items for you: [title 1], [title 2]. Process now or defer?" Deferred items remain in inbox for next session. No auto-processing |
| CTB-035 | Watcher defensive fix — short-circuit non-bridge JSON | done | — | low | code | Watcher's `_parse_operation()` (or `dispatch_file()`) short-circuits on `.json` files missing an `operation` field. Non-bridge JSON moved to `_openclaw/inbox/.unrecognized/` with warning log. Rate limit budget no longer wasted on files the processor will always reject. Unit tests for short-circuit path and `.unrecognized/` routing |
| CTB-036 | Capture processing procedure | done | CTB-034 | medium | code | Read capture → execute processing hint → route result to vault → move capture to `.processed/`. Hint handling: `research` and `review` treated identically until researcher-skill is built (fetch, synthesize, route); `file` routes directly to vault with appropriate frontmatter; `read-later` queues to reading list. `.processed/` files older than 30 days purged (align with CTB-027 retention policy). Dependency note: full `research` differentiation deferred until researcher-skill project unblocks |

## Estimation Notes

**Phase 1 actuals:** 16 tasks planned, 16 executed (CTB-001 through CTB-016). No scope
creep — good signal for this project's decomposition accuracy. However, each task was
larger than typical (averaging ~40-50 tests per task batch), and markdown rendering required
an unplanned iteration (spec v2.0 → v2.0.1). Deferred items (A11-A13) emerged from peer
review, not from missed scope.

**Phase 2 estimate:** 15 tasks (CTB-017 through CTB-031). 12 dispatch tasks + 3 deferred.
Walking skeleton approach allows early validation — if single-stage dispatch reveals
architectural issues, we catch them at CTB-021 rather than CTB-028.
