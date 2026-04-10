---
type: action-plan
domain: software
status: draft
created: 2026-02-19
updated: 2026-02-22
project: crumb-tess-bridge
skill_origin: action-architect
tags:
  - openclaw
  - security
  - integration
---

# Crumb–Tess Bridge — Action Plan

## Milestone 1: Research & Unknowns Resolution

Resolve the critical unknowns that gate protocol design and Phase 2 architecture.
Three research tracks can run in parallel.

**Success criteria:** All M1 unknowns resolved with findings documented in run-log:
U1/U2/U3 (CTB-001), U4 (CTB-002), U5 (CTB-009), U6 (CTB-010). Go/no-go decision
for `--print` mode feasibility documented. U7 (session concurrency) deferred to
Phase 2 — validated during CTB-011 development.

### 1.1 Claude Code CLI Research (CTB-001)

Test `--print` mode capabilities: CLAUDE.md loading, tool access, multi-turn reasoning,
session lifecycle. This is the most critical research — it gates whether Model B4 is
viable at all.

### 1.2 Telegram Formatting Research (CTB-002)

Test Telegram's markdown rendering, code block behavior, and 4096-char limit handling.
Results feed directly into the echo display format and response relay formatting.

### 1.3 File-Watch Latency Research (CTB-009)

Compare `launchd WatchPaths` vs `fswatch` vs `kqueue` for `_openclaw/inbox/` monitoring.
Latency, reliability, and resource usage data needed for Phase 2 architecture decision.

### 1.4 Token Cost Measurement (CTB-010)

Measure per-session token overhead for bridge requests. Depends on CTB-001 results
(`--print` mode behavior). Projects monthly cost at various request frequencies.

---

## Milestone 2: Protocol Design & Schema

Design the bridge request/response JSON schema that both Tess and Crumb will implement.
This is the contract between the two systems — it must be locked before any code is written.

**Success criteria:** Schema documented in a standalone design doc. Covers all Phase 1
operations. Validated against Telegram 4096-char limit. Canonical JSON test vector
passes cross-implementation verification. Schema peer-reviewed or approved by user.

### 2.1 Bridge JSON Schema Design (CTB-003)

Design request/response schemas, canonical JSON serialization rules, and the test vector.
Incorporate findings from CTB-001 (governance_check fields) and CTB-002 (Telegram
formatting constraints for echo display).

---

## Milestone 3: Phase 1 Implementation

Build the two sides of the bridge: Tess's bridge skill (OpenClaw) and Crumb's
bridge-processing procedure. Plus the transcript infrastructure.

**Success criteria:** Both sides can produce and consume valid bridge messages.
Unit tests pass for hash computation, schema validation, echo formatting, and
relay display. Transcript directory exists with documented format.

### 3.1 OpenClaw Bridge Skill — Protocol Mechanics (CTB-004)

Build the security-critical core of the Tess bridge skill: strict command parsing
into allowlisted operations (no free-form NLU — Tess is transport, not interpreter),
canonical JSON serialization, payload hash computation, schema validation, and atomic
inbox write (via rename). This is the trust-critical path — every byte matters for
hash binding.

### 3.2 OpenClaw Bridge Skill — Telegram UX (CTB-015)

Build the user-facing formatting layer: confirmation echo display (JSON-in-echo
with hash code), outbox watching for Crumb responses, and structured Telegram relay
formatting within the 4096-char limit. Unit tests for echo formatting and relay
display. Depends on CTB-004 (uses its protocol outputs).

### 3.3 Crumb Bridge-Processing Procedure (CTB-005)

Build the Crumb-side procedure: inbox reading, schema validation, payload hash
verification, idempotency check, operation execution under governance, outbox response
writing, and transcript persistence.

### 3.4 Transcript Infrastructure (CTB-006)

Create `_openclaw/transcripts/` directory, document the transcript format, update
`.gitignore` for processed files, and create `_openclaw/inbox/.processed/` directory.

---

## Milestone 4: Phase 1 Validation

End-to-end integration testing and security validation of the confirmation echo.

**Success criteria:** Full Telegram → Tess → inbox → Crumb → outbox → Tess → Telegram
round trip works (CTB-007). Prompt injection test suite confirms no HIGH-severity
bypasses remain unmitigated (CTB-008) — this is a validation gate for Phase 1 daily use,
not just a documentation exercise. Colocation spec updated with bridge threats (CTB-013).

### 4.1 End-to-End Integration Test (CTB-007)

Full round-trip test: user sends Telegram message, Tess echoes with hash, user confirms,
request lands in inbox, Crumb processes interactively, response in outbox, Tess relays
structured update to Telegram.

### 4.2 Prompt Injection Test Suite (CTB-008)

10+ injection payloads tested against the confirmation echo, including Telegram-specific
adversarial cases (zero-width characters, RTL/LTR markers, codeblock-breaking sequences)
tested through actual Telegram rendering. At least one transcript-poisoning payload.
Document: which survive echo, which are caught by hash-bound confirmation, which are
caught by schema validation, residual risks.

### 4.3 Colocation Spec Update (CTB-013)

Update the colocation spec's threat model to incorporate bridge-specific threats (BT1-BT7).
Revise threat ratings that changed due to the bridge attack surface.

---

## Milestone 5: Phase 2 Automation

Build the automated async processing pipeline: file watcher + bridge runner +
governance verification.

**Prerequisites:** Phase 1 validated (Milestone 4 complete). Research unknowns
U2, U3, U5, U6, U7 resolved. Go/no-go decision on Phase 2 approved by user.
**Note:** U3 (session lifecycle under automation) is distinct from CTB-001's
`--print` basics — U3 covers repeated automated invocations, state persistence
across sessions, and session collision behavior. Validated during CTB-011 development.

**Success criteria:** File watcher detects inbox changes and spawns `claude --print`
sessions automatically. Bridge runner enforces rate limiting, session locking, and
governance verification. Automated governance test suite passes.

### 5.1 File-Watch + Bridge Runner (CTB-011)

Build the file watcher (chosen mechanism from CTB-009) and bridge runner script.
Runner implements: flock-based session locking, pgrep advisory check, rate limiting,
`claude --print` invocation, output capture, outbox writing, transcript persistence,
kill-switch check, and error reporting to outbox.

### 5.2 Governance Verification Test Suite (CTB-012)

Automated tests confirming: CLAUDE.md loaded (governance_hash match), canary correct,
tools available, risk tiers enforced, output matches bridge response schema.
Tests run on every bridge session as part of the runner's validation.

---

## Milestone 6: Peer Review & Hardening

Final validation of the complete bridge implementation.

**Success criteria:** 3-model peer review with all must-fix findings addressed.
Bridge is approved for daily use.

### 6.1 Peer Review of Bridge Implementation (CTB-014)

3-model peer review of the bridge specification + implementation artifacts.
All must-fix findings addressed before the bridge is considered production-ready.

---

## Milestone Dependencies

```
M1 (Research) ──→ M2 (Schema) ──→ M3 (Implementation) ──→ M4 (Validation)
                                                               │
M1.3, M1.4 ─────────────────────────────────────────────→ M5 (Automation)
                                                               │
                                                          M6 (Peer Review)
                                                               ▲
                                                          M4 + M5
```

**Critical path:** M1 → M2 → M3 → M4 → M6
**Parallel track:** M1.3/M1.4 feed into M5 (can overlap with M3/M4 work)

## Phase 3 (Hardening) — Deferred

Phase 3 deliverables (monitoring, alerting, cost dashboard, operational runbook)
are deferred until Phase 2 is validated and in daily use. They will be scoped as
a separate action plan when Phase 2 proves stable. This is intentional — hardening
before validation is premature optimization.

---
---

# Phase 2: Dispatch Protocol Implementation

**Context:** Phase 1 operational (M1-M6 complete, 325 tests, live Telegram loop verified).
Dispatch protocol designed and 2-round peer-reviewed (CTB-016). Live testing debrief
(2026-02-22) established priority: `invoke-skill` is highest-value Phase 2 operation —
covers both file analysis and skill delegation. `start-task` and `quick-fix` secondary.

**Architecture:** The dispatch engine is a Python module set alongside `bridge-watcher.py`
in `_system/scripts/`. The watcher routes Phase 1 operations to `bridge-processor.js`
(unchanged) and Phase 2 dispatch operations to the new dispatch engine. Each dispatch
stage is an isolated `claude --print` invocation with structural injection separation
(safety directives in system prompt, untrusted content in user prompt).

**Approach:** Walking skeleton — get single-stage `invoke-skill` working end-to-end first,
then layer on multi-stage, escalation, budget enforcement, and hardening.

---

## Milestone 7: Dispatch Foundation

Build the schema extensions and dispatch state management that underpin all Phase 2
dispatch operations.

**Prerequisites:** Phase 1 operational. Dispatch protocol designed and peer-reviewed.
**Success criteria:** Phase 2 operations accepted by schema validation on both sides.
Dispatch state module creates, reads, updates, and recovers state files. State machine
transitions enforce §2.3 rules. Crash recovery scan handles all non-terminal states.

### 7.1 Phase 2 Schema Extensions (CTB-017)

Add Phase 2 operations (`start-task`, `invoke-skill`, `quick-fix`, `escalation-response`,
`cancel-dispatch`) to Tess-side constants and schema validation. Bump schema version to
`1.1`. Add Phase 2 param validators per bridge-schema §2 and dispatch-protocol §10.
Extend bridge-processor.js to reject Phase 2 ops with `OPERATION_REQUIRES_DISPATCH`
(they bypass the processor, routed through the dispatch engine).

### 7.2 Dispatch State Module (CTB-018)

Python module for dispatch state persistence: create, read, update, and delete state files
in `_openclaw/dispatch/`. Implements state machine transitions with validation (§2.3 rules).
Atomic writes (tmp + rename). Crash recovery scan on startup (§2.5). Terminal state cleanup
(30-day retention). State file schema matches dispatch-protocol §2.5.

---

## Milestone 8: Walking Skeleton — Single-Stage Dispatch

Get the simplest possible dispatch working end-to-end: a 1-stage `invoke-skill` that
spawns `claude --print`, reads stage output, verifies governance, and writes a final
response. This validates the core dispatch architecture before layering on controls.

**Success criteria:** A confirmed `invoke-skill` request triggers the dispatch engine,
spawns `claude --print` with properly constructed prompts (structural injection separation),
reads and validates stage output, verifies governance, and writes a final response to
outbox. Watcher correctly routes Phase 1 ops to processor and Phase 2 ops to dispatch.

### 8.1 Brief Construction + Stage Prompt Builder (CTB-019)

Python module that constructs input briefs from bridge request params (§7.1) and builds
stage prompts with structural injection separation (§4.2): safety directives in
`--append-system-prompt`, untrusted content in user prompt. Budget defaults and hard caps
per §8.1.

### 8.2 Stage Runner + Output Validation (CTB-020)

Python module that spawns `claude --print` with constructed prompts (from CTB-019), wraps
with subprocess timeout (§3.1), reads stage output JSON from disk (written by Claude via
Write tool per prompt instructions), validates against §4.3 schema, enforces runner policy
checks (§4.6: instruction length, context file paths, handoff size). Pre-spawn CLAUDE.md
hash check and post-stage `governance_check` field validation. Governance failure writes
alert to `_openclaw/alerts/`.

### 8.3 Dispatch Engine + Watcher Routing (CTB-021)

Python orchestrator wiring dispatch state, brief construction, and stage runner into the
dispatch lifecycle. Integrates into bridge-watcher.py: Phase 1 ops route to
`_dispatch_node`, Phase 2 dispatch ops route to the dispatch engine. Single-stage dispatch
(`status: done`) works end-to-end.

---

## Milestone 9: Multi-Stage Lifecycle & Budget

Extend the dispatch engine for multi-stage execution with budget enforcement. After this
milestone, dynamic stage sequencing works: planning → execution → synthesis.

**Success criteria:** Dispatch engine follows stage output `next` declarations to spawn
subsequent stages. Handoff data flows between stages. Budget enforcement halts execution
when limits reached. Status update files written to outbox after each stage.

### 9.1 Multi-Stage Lifecycle + Budget Enforcement (CTB-022)

Extend dispatch engine: `stage-complete → running` transitions, handoff data in
next-stage prompts, budget tracking (§8.2: wall-time from `dispatch_started_at`, stage
counting), blocked time exclusion, budget warnings at ≤20%, `BUDGET_EXCEEDED` on limit.
Subprocess timeout wrapping per §3.1.

### 9.2 Status Updates (CTB-023)

Runner writes status update files to outbox after each stage (§5.2 schema). Status files
overwritten per stage (not appended). Tess-side formatting for Telegram relay (§5.3).

---

## Milestone 10: Escalation & Cancel

Add user-interaction mid-flight: structured escalation questions when a stage blocks,
and cancel-dispatch to abort between stages.

**Success criteria:** A stage declaring `status: blocked` triggers structured escalation
relay to Telegram. User answers flow back through confirmation echo. Runner resumes with
runner-resolved option text (not raw user input). Cancel-dispatch stops execution at
next stage boundary. Kill-switch checked between every stage.

### 10.1 Structured Escalation Flow (CTB-024)

Escalation schema validation (§6.2: regex on options, max 3 questions, no free-text,
strip defaults). Relay escalation to outbox for Tess. Poll inbox for escalation-response.
Resume prompt construction with runner-resolved option text (§6.5). Escalation timeout
(§6.6). Risk-gate visual warnings.

### 10.2 Cancel-Dispatch + Inter-Stage Kill-Switch (CTB-025)

Cancel-dispatch handling: inbox polling at stage boundaries, `cancel_requested_at`
persistence, cancel/completion precedence (§2.3). Kill-switch checked between every stage
and before escalation resume. `CANCELED_BY_USER` and `KILL_SWITCH` terminal states.
Partial deliverables preserved.

---

## Milestone 11: Tess Integration & Audit Trail

Complete the Tess-side support for dispatch operations and the audit trail for tamper
detection.

**Success criteria:** Tess CLI handles all Phase 2 operations with confirmation echo.
Status update polling relays progress to Telegram. Escalation questions formatted with
neutral labels. Audit hash chains all stage transcripts. Final response includes full
dispatch metadata.

### 11.1 Tess Dispatch CLI Support (CTB-026)

Extend bridge-cli.js: `start-task`, `invoke-skill`, `quick-fix` confirmation echo + write.
`escalation-response` parsing (ANSWER command → structured response with option indices).
`cancel-dispatch` confirmation. Status update polling (extend outbox-watcher). Escalation
formatting (§6.3: neutral labels, no defaults).

### 11.2 Audit Trail + Final Response (CTB-027)

Audit hash computation (§7.3: chain stage transcript hashes, deterministic). Final
response construction with dispatch metadata (§7.2: deliverables, stages_executed,
budget_used, estimated_cost_usd, transcript_paths). Dispatch state cleanup.

---

## Milestone 12: Dispatch Validation

Integration and security testing of the complete dispatch pipeline. Validation gate
for Phase 2 daily use.

**Success criteria:** E2E test demonstrates full multi-stage dispatch through the watcher.
Injection payloads in stage output and escalation don't bypass runner policy validation.
All dispatch lifecycle paths tested (complete, failed, canceled, budget exceeded,
escalation timeout, governance failure).

### 12.1 E2E Dispatch Validation + Injection Tests (CTB-028)

End-to-end dispatch through watcher pipeline with simulated stage outputs. Tests:
1-stage dispatch, 3-stage dispatch with handoff, escalation round-trip, cancel
mid-dispatch, budget exceeded, governance failure at stage boundary. Injection payloads:
malicious `next_stage.instructions`, path traversal in `context_files`, oversized handoff,
regex-bypassing escalation options. **Validation gate:** Phase 2 daily use blocked until
this passes.

---

## Milestone 13: Deferred Hardening

Address three items deferred from Phase 1 peer review (CTB-014). Independent of dispatch
implementation — can run any time.

**Success criteria:** Watcher errors produce alert files relayed to Telegram. Processed
IDs use Set for O(1) lookup. Sender allowlist validates `source.user_id`.

### 13.1 Telegram Alerts (CTB-029)

Tess polls `_openclaw/alerts/` for new files and relays to Telegram. Watcher already
writes alerts on governance failure — this task adds the Tess-side relay.

### 13.2 .processed-ids Set Optimization (CTB-030)

Replace O(n) list scan with O(1) Set lookup in bridge-watcher.py. Load into Python set
on startup, maintain in memory alongside file-append.

### 13.3 Production Sender Allowlist (CTB-031)

Sender allowlist: `source.user_id` validated against allowed-senders config. Tess-side
enforcement (before echo) + Crumb-side backstop.

---

## Phase 2 Milestone Dependencies

```
CTB-017 ──┬── CTB-019 ── CTB-020 ──┐
           │                         ├── CTB-021 ──┬── CTB-022 ──┬── CTB-024 ── CTB-027 ──┐
CTB-018 ──┘                         │              │              ├── CTB-025               │
                                     │              ├── CTB-023    │                    CTB-028
CTB-017 ── CTB-026 (parallel) ──────┘              │              │                         ▲
                                                    │              │                         │
                                                    └──────────────┴─────────────────────────┘

CTB-029, CTB-030, CTB-031 (independent — any time)
```

**Critical path:** CTB-017 → CTB-019 → CTB-020 → CTB-021 → CTB-022 → CTB-024 → CTB-027 → CTB-028
**Parallel tracks:** CTB-026 (Tess) after CTB-017. CTB-023 after CTB-021.
CTB-025 after CTB-022. CTB-029-031 independent.

## Feature Gaps Identified During Live Testing

- **File transfer/review** — sending PDFs or files via Telegram for Crumb to analyze.
  No schema operation for binary intake. Candidate for Phase 3 or separate feature spec.
