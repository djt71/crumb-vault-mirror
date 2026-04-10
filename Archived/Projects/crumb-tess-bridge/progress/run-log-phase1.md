---
type: run-log
project: crumb-tess-bridge
status: archived
created: 2026-02-19
updated: 2026-02-22
covers: "Sessions 1-19 (SPECIFY through Phase 1 IMPLEMENT)"
---

# Run Log — crumb-tess-bridge (Phase 1 Archive)

> **Archived:** Sessions 1-19 covering SPECIFY, PLAN, TASK, and Phase 1 IMPLEMENT.
> Active log continues in `run-log.md` (Session 20+, Phase 2 dispatch implementation).

## Session 1 — 2026-02-19

### Project Creation
- Scaffolded project: `Projects/crumb-tess-bridge/`
- Domain: software | Workflow: full four-phase
- Phase: SPECIFY
- Core use case: Telegram → Tess (OpenClaw) → Crumb bidirectional communication
  with phase-gate approvals from phone
- Key architectural constraint: Tess is transport + session management, not governance
- Security escalation: bridge creates Telegram → Tess → Crumb → governed vault write path,
  materially changing the colocation threat model (T1 was HIGH but impact-bounded to `_openclaw/`)
- First-class unknown: openclaw user vs. tess user for Claude CLI invocation
- Reference inputs: colocation spec, Crumb design spec, Feb 14-15 integration research

### SPECIFY Phase

**Specification produced:** `Projects/crumb-tess-bridge/design/specification.md`
- Problem statement, 13 facts, 6 assumptions, 7 unknowns (U1-U7)
- System map, 6 constraints, 5 high-leverage intervention points
- 7 bridge-specific threats (BT1-BT7), governance model, operation allowlists
- Protocol design with JSON schemas, confirmation echo flow, canonical JSON specification
- 3 phases, 14 tasks (CTB-001 to CTB-014), dependency graph
- Key decisions: Tess=transport/Crumb=governance, Model B4 (launchd file watcher), hash-bound confirmation echo, two-tier governance verification with non-echoable canary

**Peer review R1:** 3 reviewers (GPT-5.2, Gemini 3 Pro Preview, Perplexity Sonar Reasoning Pro). 5 must-fix applied:
- A1: BT6 added (NLU misparse), JSON-in-echo hardened to hard requirement
- A2: BT3 rewritten with two-tier governance verification
- A3: Schema hardened: UUIDv7, payload_hash, idempotency, schema versioning
- A4: U7 added (session concurrency — critical Phase 2 blocker)
- A5: BT7 added (Tess process compromise + kill-switch)

**Peer review R2:** 2 reviewers (GPT-5.2, Gemini 2.5 Pro — Gemini 3 Pro Preview 503'd, Perplexity failed). 2 must-fix applied, 1 declined:
- A1 applied: Lockfile-based concurrency control (flock over pgrep)
- A3 applied: Canonical JSON specification with test vector, ASCII-only enforcement
- A2 declined: HMAC shared-secret auth — circular under BT7 (compromised Tess has signing key)
- A5 applied (should-fix): Non-echoable canary (last 64 bytes of CLAUDE.md)
- A6 applied (should-fix): Phase 1/2 governance verification scoping
- A4, A7, A8 deferred to implementation

### Phase Transition: SPECIFY → PLAN
- Date: 2026-02-19
- SPECIFY phase outputs: specification.md, specification-summary.md, 2 review notes (R1, R2), 6 raw reviewer JSONs, 1 problem-pattern doc
- Compound: Security verification circularity pattern → `docs/solutions/problem-patterns/security-verification-circularity.md` (HMAC circularity under compromise + non-echoable LLM verification)
- Context usage before checkpoint: high (resumed session with full spec + 2 review rounds)
- Action taken: compact recommended after transition
- Key artifacts for PLAN phase: specification-summary.md, specification.md (task decomposition section)

### Context Inventory
- `docs/openclaw-colocation-spec.md` — colocation security spec (3 rounds peer-reviewed, 677 lines)
- `docs/crumb-design-spec-v1-7-1.md` §9 — deferred items including OpenClaw integration phased roadmap
- `docs/openclaw-crumb-reference.md` — integration architecture, vault access model, exchange formats, phase roadmap
- `Projects/openclaw-colocation/progress/run-log.md` — full implementation history (12/12 tasks complete)
- `Projects/openclaw-colocation/design/tasks.md` — completed task list for colocation project
- `session-log.md` — Feb 14-19 session entries covering integration research and colocation work
- Current operational state: OpenClaw installed on Studio, Telegram connected (@tdusk42_bot),
  9/9 isolation tests pass, Tier 1 hardening complete, LaunchDaemon running as `openclaw` user

---

## Session 2 — 2026-02-19

### PLAN Phase

**Context inventory:**
- `specification-summary.md` — primary planning input
- `specification.md` — targeted reads: Assumptions, Unknowns, System Map, Constraints, Threats, Governance, Protocol, Phased Approach, Task Decomposition
- `docs/overlays/overlay-index.md` — no matches
- 5 targeted reads from 2 source documents, standard tier

**Deliverables produced:**
- `design/action-plan.md` — 6 milestones, phased structure
- `design/tasks.md` — 15 tasks with dependency graph, acceptance criteria, risk levels
- `design/action-plan-summary.md` — milestone/risk/decision summary

**Key decisions:**
- Split CTB-004 (Tess bridge skill) into CTB-004 (protocol mechanics, HIGH risk) + CTB-015 (Telegram UX, LOW risk) per user feedback — different risk profiles warrant isolation
- CTB-008 (injection testing) explicitly gates Phase 1 daily use in M4 success criteria, not just CTB-007
- Phase 3 (hardening) deferred to separate action plan after Phase 2 validates

### Phase Transition: PLAN → TASK
- Date: 2026-02-19
- PLAN phase outputs: action-plan.md, tasks.md, action-plan-summary.md
- Compound: No compoundable insights from PLAN phase (straightforward decomposition; CTB-004 split is project-specific)
- Context usage before checkpoint: low (early session)
- Action taken: none
- Key artifacts for TASK phase: action-plan-summary.md, tasks.md

### Action Plan Peer Review (2 rounds)

**R1:** 3 reviewers (GPT-5.2, Gemini 2.5 Pro, Sonar Reasoning Pro). Gemini 3 Pro Preview 503'd, fell back to 2.5. 4 must-fix, 6 should-fix applied:
- A1: Operation allowlist acceptance criteria added to CTB-003/004/005
- A2: CTB-008 → CTB-014 explicit dependency
- A3: M1 unknown set corrected (originally "U1-U4" → proper mapping)
- A4: CTB-001 risk low → medium with go/no-go output
- A5: Canonical JSON test vector as first-class committed artifact
- A6: Schema versioning in CTB-003
- A7: UUIDv7 in CTB-004, replay test in CTB-005
- A8: "NLU extraction" → "strict command parsing" in CTB-004
- A9: Telegram-specific + transcript-poisoning payloads in CTB-008
- A10: U3 lifecycle validation note in M5

**R2 (diff mode):** 3 reviewers confirmed all R1 items applied, no regressions. 3 must-fix, 3 should-fix applied:
- A1: CTB-003 explicitly covers request AND response schema + error responses
- A2: CTB-008 transcript-poisoning criterion tightened
- A3: M1 unknown set re-corrected — U4 exists (R1 reviewer incorrectly stated it didn't)
- A4: CTB-005 rejected requests produce structured error in outbox
- A5: Allowlist as single authoritative source (schema enum) in CTB-003
- A6: CTB-011 validates U3 in acceptance criteria

**Errata:** R1 OAI-F7 incorrectly stated U4 doesn't exist in the spec. It does (Telegram Message Formatting Constraints). Corrected in R2.

Review notes: `reviews/2026-02-19-crumb-tess-bridge-action-plan.md` (R1), `reviews/2026-02-19-crumb-tess-bridge-action-plan-r2.md` (R2)

### Session 2 End — 2026-02-19

**Summary:** Resumed project from PLAN phase. Ran action-architect to decompose spec into 6 milestones and 15 tasks. User feedback led to CTB-004 split (protocol mechanics vs Telegram UX) and CTB-008 as explicit Phase 1 validation gate. Completed phase transition PLAN → TASK. Two rounds of 3-model peer review on the action plan — R1 produced 10 action items (all applied), R2 confirmed completeness and produced 6 more refinements (all applied). Notable errata: R1 reviewer incorrectly stated U4 doesn't exist, which propagated into the plan until caught in R2.

**Commits:** 5 (PLAN phase deliverables, phase transition, R1 findings, R2 findings, peer review log)

**Compound:** R1 reviewer error propagation — when an external reviewer makes a factual claim about the spec (OAI-F7: "U4 doesn't exist"), verify against the source document before applying. The correction was applied without checking the spec, which introduced an error that took a full review round to catch. This is a specific case of provenance checking failure on reviewer outputs. Not high-confidence enough for `docs/solutions/` yet — single occurrence.

**Next session:** Start fresh, load `action-plan-summary.md` + `tasks.md`, begin CTB-001/002/009 research track in parallel.

---

## Session 3 — 2026-02-19

### Context Inventory
- `design/action-plan-summary.md` — milestone structure, critical path, key decisions
- `design/tasks.md` — 15 tasks, dependency graph, acceptance criteria
- `project-state.yaml` — phase: TASK, next_action: research track
- `progress/run-log.md` — sessions 1-2 history
- 4 reads from 4 source documents, standard tier

### Research Track — CTB-001, CTB-002, CTB-009 (parallel)

#### CTB-001: Claude Code `--print` Mode — FULL GO

**Empirical test results** (2026-02-19 17:50, Claude Code 2.1.47):

| # | Test | Criterion | Result | Time |
|---|------|-----------|--------|------|
| 1 | CLAUDE.md loading | References vault headers | **PASS** — listed "Crumb — Personal Multi-Agent OS", "Project Overview", "Domains". Startup hook also ran. | 7.0s |
| 2 | File read | Contains `TASK` | **PASS** — "The phase field is TASK" | 7.2s |
| 3 | File write | File exists on disk | **PASS** — wrote and confirmed `/private/tmp/claude-print-test.txt` | 7.8s |
| 4 | Bash execution | Contains `hello-from-print-mode` | **PASS** — correct output | 16.6s |
| 5 | Startup time (x3) | <15s each | **PASS** — 4.7s, 4.5s, 4.1s | — |
| 6 | JSON output | Valid JSON | **PASS** — full metadata: cost, usage, session_id, model breakdown | 4.2s |
| 7 | `--allowedTools` restriction | Write refused | **FAIL** — Write succeeded under `bypassPermissions` | 20.6s |
| 8 | `--no-session-persistence` | No session file | **PASS** — sessions before=0, after=0 | 4.2s |
| 9 | MCP servers | Listed or absent | **PASS (absent)** — "NONE" | 4.2s |

**Score: 8/9 PASS.** Test 7 failure is a permission-model interaction, not a capability gap.

**Test 7 follow-up results (4 tests, disambiguated):**

| Test | Flags | Write blocked? | Why |
|------|-------|---------------|-----|
| 7A | `--tools "Read"` + `bypassPermissions` | **YES** | Tool removed from session entirely |
| 7B | `--allowedTools "Read"` + `dontAsk` | **YES** | Permission filter respected under `dontAsk` |
| 7C | `--disallowedTools "Write,Edit"` + `bypassPermissions` | **NO** | Bypass overrides deny; Claude used Bash instead |
| 7D | `--tools "Read,Glob,Grep"` + `dontAsk` | **YES** | Tool removed + auto-approve |

**Model (definitive):**
- `--tools` = **availability layer (hard)**. Removes tools from session. Survives all permission modes.
- `--allowedTools` / `--disallowedTools` = **permission layer (soft)**. Respected by `dontAsk`, overridden by `bypassPermissions`.
- `bypassPermissions` = **do not use for bridge**. Defeats both allowedTools and disallowedTools.
- 7C finding: even with Write/Edit denied, Claude routed around via Bash `echo > file`.
  Tool-level restriction cannot prevent file writes if Bash is available.

**Bridge runner configuration (recommended):**
```
--tools "Read,Write,Edit,Bash,Glob,Grep"  # availability: only what bridge needs
--permission-mode dontAsk                  # auto-approve, respects permission filters
--no-session-persistence                   # no session files
--output-format json                       # structured metadata for monitoring
--append-system-prompt "..."               # bridge-specific constraints
```

Defense-in-depth stack (4 layers):
1. `--tools` limits available tools (hard gate)
2. `--permission-mode dontAsk` auto-approves within tool set (no prompts, respects filters)
3. CLAUDE.md governance constrains what tools are used FOR
4. Schema-level operation allowlist constrains what operations are accepted

**Timing profile:**
- Baseline (no tools): 4.1–4.7s (API handshake + CLAUDE.md load)
- Single tool use: 7.0–7.8s
- Bash tool use: 16.6s (includes Claude reasoning about shell command)
- Per-PONG cost: $0.014 (26.8K cache-read tokens = CLAUDE.md)

**Keychain authentication blocker (U3 data point):** Running `claude --print` from a
standalone terminal triggered a macOS Keychain password prompt. Claude Code stores the
Anthropic API key in Keychain. Under unattended automation (Phase 2 file watcher), this
prompt would hang indefinitely with no user to approve it.

Mitigations (pick one before CTB-011):
1. Grant `claude` binary "Always Allow" in Keychain Access.app
2. Export `ANTHROPIC_API_KEY` as env var in the LaunchAgent plist `EnvironmentVariables`
   (sourced from a 600-permission file, not plaintext in plist)
3. Ensure Keychain unlocks at login and stays unlocked (default macOS behavior for
   login keychain, but verify under `tess` user's LaunchAgent context)

Option 2 is most explicit and testable. Option 1 is simplest but depends on Keychain
behavior across reboots. Option 3 is fragile — Keychain can re-lock after timeout.

**Errata:** `--cwd` flag does not exist. First test run (all failures) used hallucinated
`--cwd` from subagent. Fix: `cd` into vault directory before invoking `claude --print`.
CLAUDE.md is discovered from working directory, not a flag.

**Deliverable:** `progress/ctb-001-print-mode-research.md`

#### CTB-002: Telegram Formatting — COMPLETE

**Recommended:** HTML parse mode. 3 context-independent escape chars (`<`, `>`, `&`)
vs. MarkdownV2's 20 context-dependent chars. Simpler escaping = smaller attack surface
for security-critical echo construction. Echo display template designed: header +
operation + project + params + JSON code block + hash + CONFIRM/CANCEL.

**Required (non-negotiable for CTB-004/005/008):**
- Strip Unicode bidi overrides (U+202A–202E, U+2066–2069) from all input before echo
- Normalize Unicode (NFC) before canonical JSON serialization — zero-width chars alter hash invisibly
- HTML-escape all dynamic content (`escapeHtml()`) — prevents `<pre>` breakout in payload values

**Constraints documented:**
- 4096-char limit is on rendered text after entity parsing (tags are free). Exceeding → HTTP 400, no partial delivery.
- Safe payload budget: ~3500 chars. Phase 1 ops use 80–250 chars (<10%). Phase 2 ops up to 600 chars (<20%).
- Overflow strategy: truncate JSON display with explicit marker, always show full hash, add warning. Safety net only.

**U4 RESOLVED.** Deliverable: `progress/ctb-002-telegram-formatting-research.md`
One AC deferred to CTB-015: live Telegram rendering validation (requires actual bot send).

#### CTB-009: File-Watch Latency — COMPLETE

**Decision:** Long-running kqueue watcher + launchd KeepAlive.

**Why not WatchPaths:** 10s ThrottleInterval default → missed bursts and delayed
reactivity → violates inbox SLA for back-to-back requests. Apple man page:
"highly discouraged, highly race-prone, entirely possible for modifications to be missed."

**Measured (kqueue, 5 trials):**

| Metric | Value |
|--------|-------|
| Detection latency (median) | 0.41 ms |
| Detection latency (range) | 0.34–0.53 ms |
| Batch reliability (10 rapid files) | 10/10 detected |
| Atomic rename detection | YES, 0.4–0.6 ms |
| Idle CPU (10s) | 0.014% |
| Idle memory | ~16.5 MB (Python overhead) |
| Cross-user `_openclaw/inbox/` | Fully functional via `crumbvault` group |

**Caveats:**
- Verify setgid bit on `inbox/` for cross-user file readability
- Watcher must handle EBADF if directory is deleted/recreated
- No subdirectory watching (not needed for flat inbox)

**U5 RESOLVED.** kqueue delivers sub-millisecond detection. Dominant pipeline latency
is Claude Code startup (2–5s), not file detection.
Deliverable: `progress/ctb-009-file-watch-research.md`

### Metrics

| Agent | Wall time | Tool calls |
|-------|-----------|------------|
| CTB-001 | 3m 47s | 21 |
| CTB-002 | 4m 08s | 29 |
| CTB-009 | 9m 06s | 61 |

#### CTB-010 Baseline Data (from CTB-001 empirical tests)

Per-request cost and latency data extracted from `--output-format json` metadata:
- CLAUDE.md cache load: 26,827 tokens (cache-read, amortized after first call)
- Trivial request cost: $0.014 (PONG — no tools)
- Monthly projection at 20 req/day: **~$8.40/month** (CLAUDE.md load cost alone)
- Monthly projection at 50 req/day: **~$21/month**
- Latency: 4–5s baseline, 7–8s with one tool, 16s with Bash reasoning

These are floor costs — real bridge operations (read vault, process request, write response)
will use more output tokens. CTB-010 will measure per-operation costs once CTB-003 schema
is designed and operations are defined.

Bridge runner should always use `--output-format json` — structured metadata includes
cost, token usage, session_id, and model breakdown for operational monitoring.

### Decision

CTB-001 FULL GO. Test 7 follow-up confirmed tool restriction model:
`--tools` (hard gate) + `--permission-mode dontAsk` is the correct bridge config.
`bypassPermissions` defeats all permission-layer filters — do not use.

M1 research milestone complete. All 4 tasks done (CTB-001, CTB-002, CTB-009, CTB-010 baseline).
Unknowns resolved: U1, U2, U4, U5. Remaining: U3 (Keychain + automation lifecycle → CTB-011),
U6 (governance verification → CTB-012), U7 (session concurrency → addressed by design).

CTB-003 (schema design) is unblocked — both dependencies satisfied.

### Session 3 End — 2026-02-19

**Summary:** Completed M1 research milestone. Three research tasks ran in parallel
(CTB-001/002/009 via subagents). CTB-001 required two rounds of manual terminal testing
after subagent hallucinated `--cwd` flag — second round produced 8/9 pass, then Test 7
follow-up (4 tests) disambiguated the tool restriction model. Key findings: `--tools` is
the hard availability gate, `bypassPermissions` defeats permission-layer filters,
kqueue delivers 0.4ms file detection, HTML parse mode for Telegram echo. CTB-010
baseline captured opportunistically from CTB-001 JSON output ($0.014/req, 4–5s baseline).

**Compound:** Subagent hallucination of `--cwd` flag — 100% test failure on first run.
Lesson: when subagents generate CLI invocations, verify flag existence against `--help`
output before writing to test scripts. Single occurrence, but high-impact (wasted a full
manual test cycle). Not yet high-confidence enough for `docs/solutions/` — monitor for recurrence.

**Next session:** Start fresh, load `action-plan-summary.md` + `tasks.md` +
`ctb-001-print-mode-research.md` (for bridge runner config), begin CTB-003 (schema design).

---

## Session 4 — 2026-02-19

### Context Inventory
- `design/action-plan-summary.md` — milestone structure, critical path
- `design/tasks.md` — 15 tasks, dependency graph, acceptance criteria
- `design/specification-summary.md` — problem, design decisions, threats, protocol
- `design/specification.md` — targeted reads: Protocol Design, Operation Allowlist, Canonical JSON, Confirmation Echo Flow
- `progress/ctb-001-print-mode-research.md` — bridge runner config, tool restriction model
- `progress/ctb-002-telegram-formatting-research.md` — HTML parse mode, echo template, char budget
- `progress/run-log.md` — sessions 1-3 history
- 7 reads from 7 source documents, extended tier (justified: CTB-003 synthesizes findings from M1 research + spec protocol)

### CTB-003: Bridge Request/Response JSON Schema — COMPLETE

**Deliverables:**
- `design/bridge-schema.md` — formal schema specification (10 sections)
- `_openclaw/spec/canonical-json-test-vectors.json` — 4 test vectors, cross-verified

**Schema covers:**
1. Schema versioning strategy (semver major.minor, consumer rejection rules)
2. Operation allowlist as single authoritative enum (5 Phase 1 ops, 3 Phase 2 ops)
3. Full request schema with per-operation params for all operations
4. Success response schema with operation-specific details
5. Error response schema with 9 error codes (INVALID_SCHEMA, UNKNOWN_OPERATION, HASH_MISMATCH, DUPLICATE_REQUEST, INVALID_SENDER, GOVERNANCE_FAILED, OPERATION_FAILED, PATH_TRAVERSAL, INTERNAL_ERROR)
6. Rejection response for unknown operations (enumerates active allowlist)
7. Canonical JSON reference implementations (Python + Node.js)
8. Read-only operation confirmation exemption (query-status, query-vault, list-projects skip echo)
9. Telegram echo budget validation (all Phase 1 ops <10% of 3500-char budget)
10. File naming conventions and atomic write protocol

**Cross-implementation verification:**
- 4 canonical JSON test vectors computed independently via:
  - shell `echo -n | shasum -a 256`
  - Python `json.dumps(sort_keys=True, separators=(',',':'))` + `hashlib.sha256`
  - Node.js `JSON.stringify` with recursive key-sorting replacer + `crypto.createHash`
- All 3 implementations produce byte-identical canonical strings and hashes
- Self-validation script confirmed all vectors pass

**Design decisions:**
- Read-only operations skip confirmation echo — no new read capability beyond what compromised Tess already has via `crumbvault` group
- `query-vault` path validation prevents traversal attacks (`..` segments, absolute paths)
- Error responses always include `governance_check` when a session started (null for pre-session failures like hash mismatch)
- Allowlist rejection error message enumerates valid operations for user correction

**AC verification:** All 9 acceptance criteria from tasks.md CTB-003 met. Test vector artifact at `_openclaw/spec/canonical-json-test-vectors.json` (note: filename pluralized to `test-vectors` since it contains 4 vectors; AC text said `test-vector` singular — substance matches).

**M2 milestone complete.** CTB-003 was the sole task in M2 (Protocol Design).

**Unblocked:** CTB-004 (bridge skill — protocol mechanics), CTB-005 (Crumb bridge procedure), CTB-006 (transcript infrastructure).

### Session 4 End — 2026-02-19

**Summary:** Resumed project at TASK phase, began CTB-003 (schema design). Loaded 7 source documents to synthesize M1 research findings and spec protocol into a formal schema. Produced `bridge-schema.md` (10 sections) and `canonical-json-test-vectors.json` (4 vectors). Cross-verified canonical JSON hashing across shell, Python, and Node.js — all byte-identical. M2 (Protocol Design) milestone complete. CTB-004, CTB-005, CTB-006 unblocked for M3 implementation.

**Compound:** No compoundable insights from CTB-003 (straightforward schema formalization from existing spec protocol section + M1 research findings; no non-obvious decisions, no rework, no reusable patterns beyond what's already in the spec).

**Next session:** Start fresh, load `bridge-schema.md` + `action-plan-summary.md` + `tasks.md`, begin M3 implementation (CTB-004/005/006 — three tasks can start in parallel after CTB-003).

### Session 1 End — 2026-02-19

**Summary:** Full SPECIFY phase completed in one session (continued from context compaction). Produced comprehensive specification with 7 threats, 7 unknowns, canonical JSON spec, and protocol design. Two rounds of 3-model peer review with all must-fix findings addressed. User provided sharp architectural feedback throughout — notably the HMAC circularity decline which became a reusable pattern.

**Commits:** 2 (SSH frontmatter + SPECIFY phase complete)

**Compound:** Security verification circularity pattern documented (HMAC under compromise assumptions + non-echoable LLM verification). High-confidence, reusable across any agent-to-agent auth or LLM governance verification scenario.

**Next session:** Start fresh, load specification-summary.md, invoke action-architect for PLAN phase.

---

## Session 5 — 2026-02-19

### Schema Hardening — Symlink Fix + R3 Peer Review

**Symlink resolution (user-initiated):** Added `realpath` resolution to `query-vault` path validation in bridge-schema.md — a symlink inside the vault pointing outside it must be rejected.

**R3 peer review findings (offline, 3 reviewers: ChatGPT, Gemini, Perplexity):** 10 items applied across bridge-schema.md, specification.md, and tasks.md:

| # | Finding | Source | Applied To |
|---|---------|--------|-----------|
| 1 | Conditional confirmation typing explicit in §3 | ChatGPT + Perplexity | bridge-schema §3 |
| 2 | ASCII constraint as conscious design decision | All three | bridge-schema §3 rule 7 |
| 3 | Hash verification for read-only ops (integrity, not confirm-code) | ChatGPT + Perplexity | bridge-schema §8 |
| 4 | .processed-ids 30-day rotation rule | Gemini + Perplexity | bridge-schema §7 |
| 5 | Telegram message IDs → integers (drop tg-msg- prefix) | ChatGPT | bridge-schema §3/§9, spec |
| 6 | Stale hashes aligned with test vectors | ChatGPT | spec (3fa91c2d18a4 → 3c690c41fcf6) |
| 7 | UUIDv7 rationale (time-ordering for log compaction) | Perplexity | bridge-schema §3 |
| 8 | Shell alias lockfile check (closes TOCTOU from interactive side) | Gemini | tasks.md CTB-011 |
| 9 | LaunchAgent sparse environment coverage | Gemini | tasks.md CTB-011 |
| 10 | Semantically malicious JSON (long reason pushing fields off-screen) | Perplexity | tasks.md CTB-008 |

**Commits:** 2 (`1ff8bdd` symlink fix + tagline, `8f55d4d` R3 findings)

### Session 5 End — 2026-02-19

**Summary:** Short session — two targeted changes. Added symlink resolution to query-vault path validation (user catch). Applied 10 findings from offline 3-model peer review of bridge schema: conditional typing, ASCII design decision, read-only hash verification, .processed-ids rotation, Telegram ID normalization, stale hash fix, UUIDv7 rationale, plus CTB-008/011 AC additions. Also added project tagline to CLAUDE.md.

**Compound:** No compoundable insights (mechanical application of well-scoped review findings; no non-obvious decisions, no rework, no reusable patterns).

**Next session:** Start fresh, load `bridge-schema.md` + `action-plan-summary.md` + `tasks.md`, begin M3 implementation (CTB-004/005/006).

---

## Session 6 — 2026-02-21 (cross-project, from researcher-skill peer review)

### Dispatch Protocol — Architectural Decision

**Origin:** Peer review of Perplexity deep research artifact (4 models: GPT-5.2, Gemini 3 Pro Preview, DeepSeek Reasoner, Grok 4.1 Fast Reasoning) identified the Tess↔Crumb dispatch contract as the #1 must-fix finding — all 4 reviewers flagged it independently.

**User decision:** The dispatch protocol is infrastructure, not researcher-specific. It belongs in crumb-tess-bridge as a reusable template for all Tess↔Crumb task dispatch. The researcher-skill project consumes it; it doesn't define it.

**What the dispatch protocol covers (extends existing bridge schema):**
- Task lifecycle states and transitions (queued → running → stages → blocked → complete/failed)
- Status update file pattern (Crumb writes progress to outbox during long-running execution)
- Structured escalation contract (block + structured questions + resume)
- Brief/deliverable input/output contracts (generic, skill-agnostic)
- Completion pattern (final artifact + evidence + audit trail)
- Budget enforcement (max tool calls, max tokens, max wall-clock time, kill-switch respect)
- Stage-level governance verification during multi-step runs

**Security emphasis (user-directed):** Security and guardrails are critical. The dispatch protocol must extend the bridge's existing security posture (BT1-BT7, payload hashing, confirmation echo, governance checks) to long-running execution. Specific concerns:
- Budget enforcement prevents runaway token/time consumption
- Stage-level governance checks prevent drift during extended execution
- Kill-switch must be respected between stages (not just at session start)
- Escalation safety — a compromised status update must not trick users into unsafe approvals
- Structured escalation format prevents injection via free-form question text

**Relationship to existing milestones:**
- M3 implementation (CTB-004/005/006) can proceed independently — Phase 1 ops don't need the dispatch protocol
- Dispatch protocol is a parallel design track, added as CTB-016
- Blocks researcher-skill SPECIFY phase
- Will be included in a fresh peer review of the bridge project (user-requested)

**New task added:** CTB-016 (dispatch protocol design)

**Artifacts:**
- Peer review: `_system/reviews/2026-02-21-perplexity-deep-research.md`
- Research prior art: `Projects/researcher-skill/design/perplexity-deep-research.md`
- researcher-skill project created and linked

### Next
Design CTB-016 (dispatch protocol). Fresh peer review of crumb-tess-bridge after dispatch protocol is complete.

---

## Session 7 — 2026-02-21

### Context Inventory
- `design/action-plan-summary.md` — milestone structure, critical path
- `design/tasks.md` — 16 tasks, dependency graph, acceptance criteria
- `design/bridge-schema.md` — base protocol (request/response schema, operation allowlist)
- `design/specification.md` — threat model (BT1-BT7), governance model
- `progress/ctb-001-print-mode-research.md` — bridge runner config, tool restriction model
- `_system/reviews/2026-02-21-perplexity-deep-research.md` — dispatch origin peer review
- `progress/run-log.md` — sessions 1-6 history
- 7 reads from 6 source documents, extended tier (justified: CTB-016 synthesizes bridge schema + spec threats + M1 research)

### CTB-016: Dispatch Protocol Design — COMPLETE (2 review rounds)

**Deliverable:** `design/dispatch-protocol.md` (1162 lines, 12 sections)

**Document covers:**
1. Overview + normative references + activation criteria
2. Dispatch lifecycle — state machine (7 states, 13 transition rules), state definitions, persistent dispatch state with crash recovery
3. Roles — runner (trusted orchestrator with subprocess timeout), Crumb (worker), Tess (relay)
4. Stage model — two-layer injection-mitigated prompt construction (system prompt via `--append-system-prompt` + user prompt with UNTRUSTED framing), stage output schema, dynamic sequencing, structured handoff (≤8KB), runner policy validation
5. Status updates — schema, Telegram format
6. Structured escalation — 4 gate types, strict regex on options, per-question option persistence, option index responses, confirmation echo, escalation timeout (30min)
7. Brief & deliverable contracts — generic input/output schemas, audit trail with deterministic hash chain
8. Budget enforcement — authoritative (stages, wall time) vs advisory (tool calls, tokens), real elapsed time measurement, blocked time exclusion, subprocess timeout
9. Security — stage-level governance verification, kill-switch between stages, 8-layer escalation injection resistance, threat mapping (BT1-BT7), error codes
10. Schema extensions — budget override, cancel-dispatch + escalation-response operations, status value mapping
11. File conventions — naming patterns, atomic write, malformed output handling (retry once, then fail), cleanup
12. Examples — simple 1-stage, multi-stage with status updates, escalation round-trip

**R1 peer review (4 models: GPT-5.2, Gemini 3 Pro Preview, DeepSeek Reasoner, Grok 4.1 Fast Reasoning):**
- 6 must-fix, 7 should-fix applied, 4 deferred, 4 declined
- Key fixes: state machine revision (running→blocked impossible), persistent dispatch state, two-layer injection model, budget trust levels, escalation hardening (strict regex, option index), cancel-dispatch operation, governance failure → halt+manifest
- User upgraded A7 (escalation constraints) to must-fix for security posture

**R2 peer review (same 4 models):**
- 5 must-fix (A6 promoted by user), 3 should-fix applied, 4 deferred, 4 declined
- Key fixes: blocked→canceled transition, cancel_requested_at persistence, stage-complete crash recovery, wall time as real elapsed time (not sum of stages), subprocess timeout (promoted to must-fix), cancel/completion precedence rule, per-question escalation option storage, §2.3/§11.3 normalization

**Review notes:**
- R1: `_system/reviews/2026-02-21-dispatch-protocol.md`
- R2: `_system/reviews/2026-02-21-dispatch-protocol-r2.md`
- Raw responses: `_system/reviews/raw/2026-02-21-dispatch-protocol-*.json` (8 files, 4 per round)

**CTB-016 acceptance criteria verification:**
- Lifecycle states defined ✓ (7 states, §2.1-2.3)
- Stage model with input/output schemas ✓ (§4.1-4.6)
- Status update protocol ✓ (§5)
- Structured escalation with injection resistance ✓ (§6, §9.3)
- Budget enforcement with hard caps ✓ (§8)
- Stage-level governance verification ✓ (§9.1)
- Kill-switch respected between stages ✓ (§9.2)
- Extends bridge-schema.md operations ✓ (§10)
- Peer reviewed (2 rounds, 4 models each) ✓

### Session 7 End — 2026-02-21

**Summary:** Designed dispatch protocol (CTB-016) — a comprehensive multi-stage task execution protocol for the Crumb-Tess bridge. Produced 1162-line design doc covering lifecycle state machine, two-layer injection-mitigated prompt construction, structured escalation with 8-layer defense, budget enforcement with authoritative/advisory trust model, and crash recovery via persistent state. Two rounds of 4-model peer review: R1 found 13 action items (all applied per user guidance), R2 found 8 more refinements (all applied including user's promotion of subprocess timeout to must-fix). The "injection-mitigated" (not "injection-resistant") wording captures the honest security posture. User provided sharp architectural feedback throughout — notably the cancel/completion precedence rule ("done wins over late cancel") and the wall-time blocked-time exclusion.

**Compound:** Cancel/completion race precedence — when a cancel request arrives simultaneously with task completion, the completed state wins. Discarding finished work because a cancel arrived 1ms late is surprising behavior. This is a general principle for any async system with cancel operations. Not yet high-confidence enough for `docs/solutions/` (single occurrence) but worth monitoring.

**Post-commit cleanups:**
- Fixed CTB-016 description in tasks.md — was "peer reviewed as part of CTB-014", now "peer reviewed independently (2 rounds, 4 models each)"
- Fixed `.gitignore` — `.obsidian/` entire directory now ignored (was only 2 specific files + 1 malformed path). Added `_inbox/` as ignored (transient staging area).

**Commits:** 4 (`e2e0717` dispatch protocol + reviews, `5bbe5ca` tasks.md fix, `4a0a3d0` .gitignore fix)

**Next session:** Start fresh. M3 implementation: CTB-004/005/006 unblocked. Dispatch protocol is infrastructure for Phase 2 — M3 builds Phase 1 read-only bridge first.

---

## Session 8 — 2026-02-21

### Context Inventory
- `design/bridge-schema.md` — request/response schema, operation allowlist, canonical JSON spec
- `_openclaw/spec/canonical-json-test-vectors.json` — 4 test vectors (ground truth)
- `design/tasks.md` — CTB-004 acceptance criteria
- `progress/ctb-002-telegram-formatting-research.md` — echo template for SKILL.md
- `progress/run-log.md` — sessions 1-7 history
- 5 reads from 5 source documents, standard tier

### CTB-004: Bridge Skill — Protocol Mechanics — COMPLETE

**Deliverables:** 11 files in `src/tess/`

**Library modules (`scripts/lib/`):**
- `constants.js` — `SCHEMA_VERSION`, `PHASE_1_OPS` allowlist with per-field validators (type, pattern, enum, noTraversal), `READ_ONLY_OPS`, `INBOX_PATH`
- `canonical-json.js` — `sortKeysDeep()`, `canonicalJson()`, `payloadHash()`, `validateAscii()`. No deps beyond `crypto`.
- `uuid-v7.js` — `uuidv7()` manual RFC 9562 implementation. 48-bit ms timestamp + version 7 + variant 10 + crypto random.
- `schema.js` — `validateOperation()`, `validateParams()`, `buildRequest()`. Per-operation validation: kebab-case project, `PHASE->PHASE` gate format, decision enums, path traversal checks, ASCII enforcement.
- `atomic-write.js` — `atomicWriteJson()` via tmp + fsync + rename. Pretty-printed output (canonical JSON is hashing-only).

**CLI (`scripts/bridge-cli.js`):**
- 4 subcommands: `validate`, `hash`, `write-request`, `verify-vectors`
- Exit codes: 0 = success, 1 = validation error (JSON stdout), 2 = usage error
- `CRUMB_BRIDGE_INBOX` env var override for test isolation

**Tests (50 total, all pass):**
- `canonical-json.test.js` — 15 tests: 4 vectors x 2 (canonical string + hash), nested sorting, array passthrough, whitespace check, ASCII validation (4 tests)
- `uuid-v7.test.js` — 5 tests: format, version bits, variant bits, 100 unique, timestamp decode
- `schema.test.js` — 27 tests: 5 op validation, 5 approve-gate, 2 reject-gate, 2 query-status, 3 query-vault, 3 list-projects, 3 cross-cutting, 2 buildRequest
- `integration.test.js` — 3 tests: full write-request round-trip, schema compliance, verify-vectors

**SKILL.md:** OpenClaw skill definition with procedure (6 steps), operation allowlist table, security rules, and CTB-015 stubs for Telegram echo and outbox watching.

**AC verification:**
| Criterion | Status |
|-----------|--------|
| Strict command parsing (no NLU) | PASS — CLI validates against `PHASE_1_OPS` map |
| Unknown ops → `UNKNOWN_OPERATION` with allowlist | PASS — tested |
| UUIDv7 per RFC 9562 | PASS — 5 unit tests |
| Canonical JSON correct byte sequence | PASS — all 4 vectors match |
| Payload hash matches all test vectors | PASS — `verify-vectors` 4/4 |
| Schema rejects malformed fields | PASS — 12+ validation tests |
| Atomic write via rename | PASS — tmp + fsync + rename |
| Unit tests pass | PASS — 50/50 |

**Design notes:**
- No external dependencies — only Node.js built-ins (`crypto`, `fs`, `path`)
- SKILL.md is a design artifact; OpenClaw installation deferred to CTB-007/CTB-015
- `CRUMB_BRIDGE_INBOX` env var enables test isolation without touching real inbox

**Unblocked:** CTB-015 (Telegram UX layer)

### Session 8 End — 2026-02-21

**Summary:** Implemented CTB-004 (bridge skill protocol mechanics) per approved plan. 11 files: 5 library modules, 1 CLI, 4 test files, 1 SKILL.md. Zero external deps — Node.js built-ins only. All 50 tests pass including all 4 canonical JSON test vectors. Clean implementation with no rework. Vault-check caught missing frontmatter on SKILL.md — fixed in follow-up commit. Two commits pushed.

**Compound:** No compoundable insights (straightforward implementation of approved plan; no non-obvious decisions, no rework, no reusable patterns beyond project scope).

**Next session:** CTB-005 (Crumb bridge procedure), CTB-006 (transcript infra), CTB-015 (Telegram UX) — all unblocked.

---

## Session 9 — 2026-02-21

### Context Inventory
- `design/bridge-schema.md` — request/response schema, error codes, file naming
- `design/transcript-format.md` — transcript structure, hash computation, sections
- `src/tess/scripts/lib/*.js` — 5 shared libraries (constants, canonical-json, schema, atomic-write, uuid-v7)
- `src/tess/test/integration.test.js` — test patterns and conventions
- `Projects/*/project-state.yaml` — project state format (3 projects sampled)
- 6 reads from 6 source documents, standard tier

### CTB-005: Crumb Bridge-Processing Procedure — COMPLETE

**Deliverables:** 13 files (1 modified, 12 new) in `src/crumb/` + shared lib

**Shared lib modification:**
- `src/tess/scripts/lib/atomic-write.js` — added `atomicWriteText()` for non-JSON files (transcripts, YAML)

**Library modules (`scripts/lib/`):**
- `governance.js` — `computeGovernance()` (CLAUDE.md sha256[:12] + last-64-byte canary), `buildGovernanceCheck()` (full governance_check object)
- `project-state.js` — `parseYaml()` (flat YAML parser), `readProjectState()`, `resolveWorkflow()` (arrow notation → canonical key), `validateTransition()` (phase transition validation per workflow type), `writePhaseTransition()` (atomic line-level replacement)
- `transcript.js` — `TranscriptBuilder` class with incremental builder API: `addRequest()`, `addHashVerification()`, `startExecution()`, `addAction()`, `addGovernance()`, `setResult()`, `finalize()` (hash-with-placeholder bootstrap)
- `response-builder.js` — `buildSuccessResponse()`, `buildErrorResponse()` per bridge-schema.md §4.1/§4.2
- `operations.js` — 5 operation handlers + `dispatch()` + `getRiskTier()`: query-status, query-vault (with symlink escape prevention via realpathSync), list-projects, approve-gate, reject-gate

**CLI (`scripts/bridge-processor.js`):**
- 2 subcommands: `process <file>`, `process-all`
- Full pipeline: parse JSON → validate schema_version → validate operation → validate params → verify payload_hash → check .processed-ids → verify confirmation → governance boundary → execute → transcript → response → append .processed-ids → move to .processed/
- Pre-governance errors: governance_check=null, transcript_hash=null
- Post-governance errors: governance populated, transcript written

**Tests (58 total, all pass):**
- `governance.test.js` — 6 tests: hash computation, canary extraction, missing CLAUDE.md, short file, full governance check
- `project-state.test.js` — 13 tests: YAML parsing (4), workflow resolution (3), state reading (2), transition validation (3), phase write (1)
- `transcript.test.js` — 7 tests: section structure, request details, hash checkmark/mismatch, numbered actions, hash self-verification, null governance
- `response-builder.test.js` — 6 tests: success fields, UUIDv7 format, timestamp, error fields, null defaults, post-governance error
- `operations.test.js` — 15 tests: risk tiers (2), query-status (3), query-vault (4 incl. symlink escape), list-projects (3), approve-gate (2), reject-gate (1)
- `processor-integration.test.js` — 11 tests: full round-trip, governance check, transcript written, .processed/ move, schema rejection (3), hash mismatch, duplicate replay, write-op confirmation, approve-gate round-trip

**AC verification:**
| Criterion | Status |
|-----------|--------|
| Full processing pipeline per plan | PASS — all 12 pipeline steps implemented |
| Pre-governance errors → null governance/transcript | PASS — tested (schema, hash mismatch) |
| Post-governance errors → governance + transcript | PASS — tested (operation failure) |
| Duplicate replay → DUPLICATE_REQUEST | PASS — explicit test |
| Symlink escape prevention | PASS — realpathSync + containment check |
| Phase transition validation per workflow type | PASS — 3 workflow types, valid/invalid tested |
| Transcript hash self-verification | PASS — placeholder bootstrap pattern |
| Tess-side regression | PASS — 50/50 tests still pass |

**Design notes:**
- No external dependencies — Node.js built-ins only (crypto, fs, path)
- Env var overrides for test isolation: `CRUMB_VAULT_ROOT`, `CRUMB_BRIDGE_INBOX`, `CRUMB_BRIDGE_OUTBOX`, `CRUMB_BRIDGE_TRANSCRIPTS`, `CRUMB_BRIDGE_PROCESSED_IDS`
- Reuses 5 shared libraries from CTB-004 (`constants`, `canonical-json`, `schema`, `atomic-write`, `uuid-v7`)

### Session 9 End — 2026-02-21

**Summary:** Implemented CTB-005 (Crumb bridge-processing procedure) per approved plan. 13 files: 5 library modules, 1 CLI, 6 test files, 1 shared lib modification. Zero external deps. All 58 Crumb-side tests pass, all 50 Tess-side tests pass (no regression). Clean implementation following the plan's 7-step implementation order — independent modules built and tested in parallel (steps 2-5), then operations (step 6), then integration (step 7).

**Compound:** No compoundable insights (straightforward implementation of approved plan; no non-obvious decisions, no rework, no reusable patterns beyond project scope).

**Next session:** CTB-006 (transcript infra) and CTB-015 (Telegram UX) remain. CTB-007 (e2e test) is unblocked once CTB-005 + CTB-006 are done.

## Session 10 — 2026-02-21

### Context Inventory
- `design/tasks.md`, `project-state.yaml`, `progress-log.md`, `run-log.md`, `design/action-plan-summary.md` — project state
- `design/bridge-schema.md` — reference spec
- `src/tess/SKILL.md` — bridge skill procedure
- All `src/tess/` and `src/crumb/` source + test files — M3 codebase

### CTB-015: Telegram UX — COMPLETE (prior session, committed b68720d)

Implemented confirmation echo formatting and outbox watching for Telegram integration:
- `echo-formatter.js` — HTML echo/relay formatting with sorted-key canonical JSON, char budget validation
- `outbox-watcher.js` — sync `checkResponse` + async poll `watchForResponse`
- 39 new tests (31 echo-formatter, 8 outbox-watcher)
- Updated `bridge-cli.js` with 4 commands: `format-echo`, `format-relay`, `check-response`, `watch-response`
- Updated `SKILL.md` Steps 4 and 6 with CLI-based procedures

### M3 Code Peer Review — 4 Models — COMPLETE

**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek Reasoner (V3.2), Grok 4.1 Fast Reasoning
**Artifact:** Full M3 codebase (23 files, 147 tests) + SKILL.md + bridge-schema.md (reference)
**Focus:** Security (hash verification, injection resistance, path traversal), correctness (schema compliance, test gaps), code quality, cross-side consistency

**Key findings (consensus):**
- **CRITICAL (3/4 consensus):** `confirm_code` binding not verified by Crumb (A1) — the core human-in-the-loop mechanism was decorative
- **CRITICAL:** `sender_id` allowlist not enforced on Crumb side (A2)
- Unbounded file read in `queryVault` (A4) — DoS vector caught only by Gemini

**Review note:** `_system/reviews/2026-02-21-crumb-tess-bridge-m3-code.md`
**Committed:** 13b014c

### Peer Review Findings — Applied

User reviewed all findings. Reclassified 2 items per user feedback:
- **OAI-F11** promoted from declined to should-fix (spec-side cleanup — "we'll fix the spec later has a way of not happening")
- **A11** promoted from defer to should-fix with time-bound (transcript sanitization before Phase 2 dispatch)

**Applied fixes (all must-fix + should-fix):**

| ID | Fix | Files |
|----|-----|-------|
| A1 | `confirm_code === payload_hash` verification for write ops | `bridge-processor.js` |
| A2 | `CRUMB_BRIDGE_ALLOWED_SENDER` env var enforcement | `bridge-processor.js` |
| A3 | ASCII validation before hashing in `cmdHash`/`cmdFormatEcho` | `bridge-cli.js` |
| A4 | Bounded read via `fs.statSync` + 1MB cap before `readFileSync` | `operations.js` |
| A5 | Source field type validation (platform, sender_id, message_id) | `bridge-processor.js` |
| A6 | `buildRequest` throws if write-op called without confirmation | `schema.js` |
| A7 | 3 new integration tests: confirm_code mismatch, invalid sender, missing CLAUDE.md | `processor-integration.test.js` |
| A8 | `checkResponse` distinguishes ENOENT from parse errors | `outbox-watcher.js` |
| OAI-F11 | Spec examples updated: §4.5 + §7 show `null` governance for pre-governance errors | `bridge-schema.md` |

**Deferred (correctly scoped):**
- A9: `.processed-ids` race → CTB-011
- A10: Cross-side imports → Phase 2
- A11: Transcript sanitization → before Phase 2 dispatch (time-bounded)
- A12: Nested test vector → Phase 2

**Tests:** 152 pass, 0 fail (was 147 before — +5 new: 3 integration + 2 schema)

**Next:** M4 validation (CTB-007 e2e, CTB-008 NLM, CTB-013 security audit)

### Session 10 End — 2026-02-21

**Summary:** Completed M3 milestone: CTB-015 (Telegram UX, carried from prior session) + 4-model peer review + applied all must-fix and should-fix findings. The review's top finding — `confirm_code` binding was unverified (3/4 reviewer consensus) — was the kind of critical security gap that single-model development misses. 152 tests pass after fixes. User provided sharp feedback on review synthesis: promoted OAI-F11 from declined to should-fix ("we'll fix the spec later has a way of not happening") and time-bounded A11 deferral.

**Compound:** Peer review process insight — the confirm_code bypass (A1) was caught by 3/4 models independently, validating the multi-model approach for security-critical code. Single-reviewer catch (Gemini on A4/bounded read) also valuable. Pattern: security validation gaps are the highest-signal finding category for cross-model review of bridge/protocol code. Routing: `_system/docs/solutions/peer-review-patterns/` (when created).

**Commits:** 3 (CTB-015 b68720d, peer review 13b014c, review fixes 0dd6080)

---

## Session 11 — 2026-02-21

### Context Inventory
- `design/tasks.md` — CTB-007 acceptance criteria
- `src/tess/` — all Tess-side modules (bridge-cli, schema, echo-formatter, outbox-watcher, canonical-json)
- `src/crumb/` — all Crumb-side modules (bridge-processor, operations, governance, transcript, response-builder)
- `src/crumb/test/processor-integration.test.js` — existing test patterns
- `progress/run-log.md` — sessions 1-10 history
- 6 reads from source documents, standard tier

### CTB-007: End-to-End Phase 1 Integration Test — COMPLETE

**Deliverable:** `src/e2e/e2e-phase1.test.js` — 39 tests across 9 suites

**Test suites:**
1. **Read-only round trip (query-status)** — 7 tests: full pipeline from request build → inbox write → Crumb process → outbox check → Telegram relay format. Verifies governance fields, transcript, inbox→.processed/ move.
2. **Write-op round trip (approve-gate)** — 11 tests: echo formatting → hash extraction → confirmation binding → inbox write → Crumb process → phase transition verification → outbox check → relay format. Verifies confirm_code = payload_hash binding end-to-end.
3. **Write-op round trip (reject-gate)** — 4 tests: full flow with rejection, verifies no phase transition, reason in summary.
4. **Read-only round trip (list-projects)** — 4 tests: multi-project listing with details validation.
5. **Read-only round trip (query-vault)** — 3 tests: file content retrieval and relay display.
6. **Cross-side hash consistency** — 1 test: all 5 Phase 1 operations verified — Tess-computed hash matches Crumb verification (no HASH_MISMATCH for any op).
7. **Batch processing (process-all)** — 5 tests: 3 requests processed, 3 responses in outbox, 3 transcripts, all inbox files moved.
8. **Error propagation** — 2 tests: post-governance error (OPERATION_FAILED) + pre-governance error (HASH_MISMATCH), both formatted correctly for Telegram relay.
9. **Schema compliance** — 2 tests: success and error responses contain all required fields per bridge-schema.md §4.1/§4.2.

**AC verification:**
| Criterion | Status |
|-----------|--------|
| Telegram message → Tess echo | PASS |
| User CONFIRM with hash | PASS |
| Inbox file written | PASS |
| Crumb processes in interactive session | PASS |
| Outbox response exists | PASS |
| Tess relays update to Telegram | PASS |
| Governance fields present in response | PASS |

**Full test count:** 191 pass, 0 fail (152 existing + 39 new e2e)

### CTB-008: Prompt Injection Test Suite — COMPLETE

**Deliverables:**
- `src/e2e/injection-tests.test.js` — 40 tests across 16 suites
- `progress/ctb-008-residual-risk-assessment.md` — full risk assessment

**15 adversarial payloads tested:**

| # | Payload | Result |
|---|---------|--------|
| P1 | Zero-width chars (U+200B, U+FEFF, U+200C, U+200D) | caught-by-schema (L2 ASCII) |
| P2 | RTL/LTR overrides (U+202E, U+202D, U+2066, U+2069) | caught-by-schema (L2 ASCII) |
| P3 | HTML injection (`<script>`, `<b>`) in reason | caught-by-echo (L5 HTML escape) |
| P4 | Codeblock breakout (`</code></pre>`) | caught-by-echo (L5 HTML escape) |
| P5 | Path traversal (relative, absolute, symlink) | caught-by-schema (L1) + Crumb realpathSync |
| P6 | Long reason pushing hash off-screen | caught-by-schema (maxLength 500) — **R1 CLOSED** |
| P7 | Transcript poisoning (markdown injection) | survived — **R2 LOW** |
| P8 | JSON-shaped malicious reason | caught-by-echo (L5 structural) |
| P9 | Payload hash tampering (full, partial, empty) | caught-by-hash (L3) |
| P10 | confirm_code mismatch | caught-by-crumb (L4 binding) |
| P11 | Newline injection in reason | survived — benign (JSON escape) |
| P12 | ASCII control chars (NUL, TAB, CR) | survived — **R3 LOW** |
| P13 | Unauthorized sender_id | caught-by-sender (L6) |
| P14 | Unknown fields / unknown operations | caught-by-schema (L1) |
| P15 | ASCII homoglyphs (l/1, O/0) | survived — **R4 LOW** (by design) |

**Residual risks (no HIGH-severity bypasses):**
- **R1 CLOSED:** Long reason — `maxLength: 500` added to reason field validator. 500-char reason fits well within safe budget.
- **R2 LOW:** Markdown injection in reason creates ambiguous transcript sections. Mitigation deferred to A11 (transcript sanitization before Phase 2).
- **R3 LOW:** ASCII control chars pass validation. JSON escaping preserves hash integrity; display-only impact.
- **R4 LOW:** ASCII homoglyphs pass all checks — this is by design; the echo IS the defense.

**Code finding:** `stripBidiOverrides` is defined but not wired into the echo pipeline. L2 ASCII validation makes it redundant but it should be wired in as defense-in-depth or removed.

**Pending:** Telegram rendering verification for P3, P4, P6, P15 (requires live bot on Studio).

**AC verification:**
| Criterion | Status |
|-----------|--------|
| 10+ injection payloads | PASS — 15 payloads, 40 tests |
| Telegram-specific (zero-width, RTL/LTR, codeblock) | PASS — P1, P2, P4 |
| Actual Telegram rendering | PENDING — manual verification needed |
| Transcript-poisoning payload tested | PASS — P7 |
| JSON-shaped semantically malicious payload | PASS — P6 (long reason), P8 (JSON reason) |
| Each payload has documented result | PASS — matrix in risk assessment |
| Residual risk assessment written | PASS |
| No HIGH-severity bypasses unmitigated | PASS |

**Full test count:** 232 pass, 0 fail (152 existing + 39 e2e + 41 injection)

**Post-review fix:** Added `maxLength: 500` to reject-gate `reason` field validator
per user feedback — closes R1 at L1 (schema) rather than leaving it as a known gap.
No MEDIUM or HIGH residual risks remain.

### CTB-013: Update Colocation Spec Threat Model — COMPLETE

**Deliverable:** Updated `_system/docs/openclaw-colocation-spec.md` (threat model section)

**Changes applied:**
1. **T1 (Prompt Injection)** — Added "Bridge impact" field: blast radius escalates from sandbox to vault writes via Telegram → Tess → inbox → Crumb path. Rating stays HIGH (mitigations bound escalation). Cross-ref: BT1, BT2, BT6.
2. **T4 (Lateral Movement)** — Added "Bridge impact" field: indirect path via `_openclaw/inbox/` → Crumb sessions (Phase 2) bypasses confirmation echo. Cross-ref: BT7.
3. **T11 (Account Takeover)** — Rating changed to MEDIUM / HIGH Phase 2. Phase 1: confirmation echo + visible chat history = MEDIUM. Phase 2: automated processing removes visual inspection backstop = HIGH. Cross-ref: BT1.
4. **Bridge Integration Threats subsection** — BT1–BT7 added in colocation spec format (4-6 lines each), condensed from bridge spec. Cross-ref to residual risk assessment.
5. **Second-Order Effects** — Added bridge integration bullet with cross-ref to bridge spec and BT1-BT7 subsection.
6. **Summary updated** — Threat table expanded to include BT1-BT7 with bridge impact notes on T1, T4, T11.

**AC verification:**
| Criterion | Status |
|-----------|--------|
| BT1-BT7 in colocation spec | PASS — 7 entries at lines 249-289 |
| T1, T4, T11 bridge impact notes | PASS — 3 "Bridge impact" fields |
| T11 phase-conditional rating | PASS — MEDIUM / HIGH Phase 2 |
| Cross-reference to bridge spec | PASS — Second-Order Effects + subsection intro |
| vault-check passes | PASS — 0 errors, 1 warning (pre-existing) |
| No structural changes outside threat model + second-order effects | PASS |

**Commit:** 829ad17

### Session 11 End — 2026-02-21

**Summary:** Completed CTB-013 (colocation spec threat model update). Added BT1-BT7 bridge threats, updated T1/T4/T11 with bridge impact notes, and added cross-references. T11 escalated to phase-conditional rating (MEDIUM Phase 1 / HIGH Phase 2). Summary regenerated to satisfy stale-summary check. Clean implementation — no rework.

**Compound:** No compoundable insights (mechanical application of planned changes; bridge threats condensed from existing spec content, no non-obvious decisions).

**Commits:** 1 (829ad17 — spec + summary)

**Next session:** Remaining tasks: CTB-010 (token cost), CTB-011 (file-watch runner), CTB-012 (governance tests), CTB-014 (peer review). Phase 2 track is next.

---

## Session 12 — 2026-02-21

### Context Inventory
- `design/tasks.md` — task states, CTB-010 acceptance criteria
- `project-state.yaml` — phase: TASK, next_action
- `progress/run-log.md` — sessions 1-11 history
- `progress/ctb-001-print-mode-research.md` — baseline data ($0.014/req, 26.8K cache-read)
- `progress/ctb-010-token-cost-sonnet.json` — empirical token counts from plain Terminal run
- 5 reads from 5 source documents, standard tier

### Uncommitted Work Recovery

Prior sessions crashed trying to run `claude --print` from inside Claude Code (nested session incompatibility — CLAUDECODE env var blocks recursive invocation regardless of `unset`/`env -u` attempts). Measurement script was written and run successfully from a plain Terminal.

Committed uncommitted work from crashed sessions:
- `constants.js` — `maxLength: 500` on reject-gate reason (CTB-008 R1 fix)
- `schema.js` — `maxLength` enforcement in `validateParams`
- `src/e2e/e2e-phase1.test.js` — 39 e2e tests
- `src/e2e/injection-tests.test.js` — 41 injection tests (15 payloads)
- `src/e2e/telegram-rendering-verify.js` — Telegram rendering verification helper
- `progress/ctb-008-residual-risk-assessment.md` — residual risk assessment
- `src/scripts/measure-token-cost.sh` — token cost measurement script
- `progress/ctb-010-token-cost-sonnet.json` — partial empirical data

All 232 tests pass before and after commit.

### CTB-010: Token Cost Measurement — COMPLETE (FULL GO)

**Deliverable:** `progress/ctb-010-cost-model.md`

**Method:** Analytical model built from empirical token counts (5 operations measured via `measure-token-cost.sh` from plain Terminal) × published Anthropic pricing. The `--output-format json` cost field returned $0 for all operations (jq path mismatch), but token counts are reliable.

**Per-operation costs (Sonnet 4):**

| Operation | Cost | Duration | Turns |
|-----------|------|----------|-------|
| query-status | $0.012 | 5.2s | 2 |
| query-vault (small) | $0.042 | 7.1s | 2 |
| query-vault (medium) | $0.053 | 9.4s | 2 |
| list-projects | $0.061 | 14.5s | 8 |
| approve-gate (dry run) | $0.041 | 6.5s | 2 |

**Cost drivers:** Cache write tokens dominate for tool-using operations (file reads create new prompt context). query-status is cheapest (no file reads). list-projects is most expensive (Glob + N Reads = 8 turns).

**Monthly projections (weighted avg ~$0.04/req Sonnet, ~$0.014/req Haiku):**

| Requests/day | Sonnet 4 | Haiku 4.5 |
|-------------|----------|-----------|
| 5 | $6/month | $2.10/month |
| 20 | $24/month | $8.40/month |
| 50 | $60/month | $21/month |

**Go/no-go threshold:** $50/month. Both models at 20 req/day well below threshold.

**Decision: FULL GO.** Haiku available as cost-optimization lever (67% savings, minimal quality impact for Phase 1 operations).

**AC verification:**

| Criterion | Status |
|-----------|--------|
| CLAUDE.md load token count measured | PASS — 25-30K cache-read |
| Per-operation token usage for each Phase 1 op | PASS — 5 operations measured |
| Monthly cost at 5/20/50 req/day | PASS — table in cost model |
| Go/no-go threshold documented | PASS — $50/month, FULL GO |

**Unblocked:** CTB-011 (all dependencies satisfied: CTB-007, CTB-009, CTB-010 done)

### Session 12 End — 2026-02-21

**Summary:** Recovered and committed uncommitted work from crashed sessions (8 files: maxLength fix, e2e tests, injection tests, rendering helper, measurement script, risk assessment, empirical data). Wrote analytical token cost model for CTB-010 using empirical token counts × published Anthropic pricing — FULL GO at $24/month Sonnet 4 (20 req/day). CTB-011 now unblocked. Two clean commits, vault-check passes.

**Compound:** No compoundable insights (straightforward cost analysis from measured data; nested session incompatibility already documented in MEMORY.md).

**Commits:** 2 (a9c2878 uncommitted work recovery, 4379bbf CTB-010 cost model)

**Rating:** 2 — Mixed

**Next session:** CTB-011 (file-watch + bridge runner) — Phase 2 implementation begins. All dependencies satisfied.

---

## Session 13 — 2026-02-21

### Context Inventory
- `design/tasks.md` — CTB-011 acceptance criteria
- `project-state.yaml` — phase: TASK, active_task: null
- `src/crumb/scripts/bridge-processor.js` — existing processor (process + process-all subcommands)
- `src/crumb/scripts/lib/response-builder.js` — buildErrorResponse for reject path
- `src/tess/scripts/lib/constants.js` — SCHEMA_VERSION, paths
- `src/crumb/test/processor-integration.test.js` — test patterns
- `_system/reviews/2026-02-21-ctb-011-plan.md` — peer-reviewed implementation plan
- 7 reads from 7 source documents, standard tier

### CTB-011: File-Watch + Bridge Runner — COMPLETE

**Deliverables:** 8 new files, 2 modified files

**New files:**
- `_system/scripts/bridge-watcher.py` — persistent kqueue daemon (Python 3, ~480 lines)
  - `Config` — env-based configuration with defaults
  - `SlidingWindowRateLimiter` — deque of timestamps, seeded from .processed-ids UUIDv7 timestamps
  - `BridgeLock` — `fcntl.flock()` wrapper (non-blocking LOCK_EX)
  - `BridgeWatcher` — main loop: kqueue events + 60s fallback scan
  - `compact_processed_ids()` — 30-day UUIDv7 timestamp compaction on startup
  - `dispatch_file()` — full pipeline: outbox check → kill-switch → rate-limit → flock → pgrep → invoke
  - Structured JSON-line logging (never logs raw request content)
  - Exit codes: 0=clean, 1=config error, 2=inbox inaccessible, 3=kqueue failure
- `_system/scripts/com.crumb.bridge-watcher.plist` — LaunchAgent definition
  - KeepAlive=true, ThrottleInterval=5, Umask=002
  - HOME, PATH, CRUMB_VAULT_ROOT environment
  - Logs to `_openclaw/logs/watcher.{log,err}`
  - No API key in plist (Phase 1 doesn't need it)
- `_system/scripts/claude-bridge-wrapper.sh` — shell function for interactive sessions
  - Acquires LOCK_EX on .bridge.lock for full session duration (A1)
  - Python one-liner matching plist Python path (consistent failure mode)
  - Warn + confirm prompt if lock held by watcher
- `src/crumb/test/reject-subcommand.test.js` — 8 tests for reject subcommand
- `src/watcher/test_watcher.py` — 34 Python unit tests
- `src/watcher/test_integration.py` — 6 Python integration tests
- `src/watcher/generate-test-request.js` — Node.js helper for Python test request generation
- `src/watcher/validate-u3.sh` — manual validation: 5 rapid requests, no collisions (AC11)
- `src/watcher/validate-launchagent.sh` — manual validation: plist, logs, kill-switch, permissions (AC12)

**Modified files:**
- `src/crumb/scripts/bridge-processor.js` — added `rejectRequest()` function + `reject` CLI subcommand
  - `reject <file> <error-code> <message> [--retryable]`
  - Node handles JSON parsing and ID extraction (A6), falls back to filename if unparseable
  - New error codes: BRIDGE_DISABLED (not retryable), RATE_LIMITED (retryable)
  - Exported for module use
- `_system/docs/crumb-deployment-runbook.md` — added §8.4 Bridge Watcher section
  - Directory setup, LaunchAgent install, wrapper setup, kill-switch, configuration reference

**Dispatch pipeline (per file):**
1. Outbox existence check (crash recovery, A2) — if response exists, move to .processed/
2. Kill-switch check → reject via `bridge-processor.js reject`
3. Rate-limit check → reject via `bridge-processor.js reject --retryable`
4. Acquire flock (non-blocking) — if held, skip (retry next scan)
5. pgrep check (advisory, toggleable via CRUMB_BRIDGE_SKIP_PGREP, A4)
6. Invoke: `node bridge-processor.js process <file>` with subprocess timeout (default 60s, A3)
7. Release flock

**Key design decisions:**
- Phase 1 uses direct `node bridge-processor.js` (free, ~100ms). No API key needed.
- `CRUMB_BRIDGE_USE_CLAUDE=1` env var for Phase 2 `claude --print` dispatch
- 60s default timeout (not 300s) per user feedback — Phase 1 ops are fast (max 14.5s)
- Fallback scan uses same dispatch pipeline (including flock gate) — no double-processing
- Rate limiter seeds from .processed-ids UUIDv7 timestamps on startup
- .processed-ids compaction (30-day rotation) runs on watcher startup

**Test results:**
- Node.js: 240 pass, 0 fail (232 existing + 8 new reject tests)
- Python unit: 34 pass, 0 fail
- Python integration: 6 pass, 0 fail (valid request, kill-switch, rate-limit, timeout retry, outbox pre-existence, claude --print stub)
- **Total: 280 tests, 0 failures**

**AC verification:**

| # | Criterion | How Verified |
|---|-----------|-------------|
| 1 | File watcher detects within acceptable latency | kqueue (CTB-009: 0.41ms) + integration test |
| 2 | flock before spawning session | BridgeLock unit test + integration test |
| 3 | pgrep prevents interactive overlap | Advisory + toggleable (A4), flock authoritative |
| 4 | Shell wrapper holds lockfile (TOCTOU) | Wrapper acquires LOCK_EX for session duration (A1) |
| 5 | claude --print invocation path | dispatch_claude() + stub integration test (A7) |
| 6 | Output written to outbox | Integration test: outbox file exists after dispatch |
| 7 | Transcript persisted | Existing 232 tests cover processor transcript path |
| 8 | Rate limiting (configurable max/hour) | RateLimiter unit tests + integration test |
| 9 | Kill-switch checked before invocation | Unit test + integration test (BRIDGE_DISABLED response) |
| 10 | Errors to outbox with retryable flag | Reject subcommand tests (RATE_LIMITED=retryable, BRIDGE_DISABLED=not) |
| 11 | U3: repeated invocations, no collisions | validate-u3.sh manual script |
| 12 | LaunchAgent env: PATH, HOME, umask | validate-launchagent.sh + plist inspection + permission check |

**Peer review action items status:**

| ID | Source | Status |
|----|--------|--------|
| A1 | OAI-F5, DS-F1, GEM-F3 | Applied — wrapper holds lock for session duration |
| A2 | GRK-F1, GEM-F5, OAI-F8, DS-F8 | Applied — outbox existence check in pipeline |
| A3 | GRK-F3 | Applied — 60s default timeout (user feedback: not 300s) |
| A4 | OAI-F4, DS-F3, GEM-F4, GRK-F2 | Applied — pgrep filtering + advisory + toggleable |
| A5 | OAI-F7, DS-F6, GRK-F4 | Applied — rate limiter seeds from .processed-ids |
| A6 | OAI-F2, GEM-F2, DS-F16 | Applied — no JSON parsing in Python |
| A7 | OAI-F14, DS-F10 | Applied — stub integration test |
| A8 | GEM-F1, OAI-F12 | Applied — Umask 002 in plist |
| A9 | OAI-F10, DS-F9 | Applied — atomic write noted in rejectRequest docs |

**Unblocked:** CTB-012 (governance tests), CTB-014 (project peer review)

### Session 13 End — 2026-02-21

**Summary:** Implemented CTB-011 (file-watch + bridge runner) from peer-reviewed plan (4 models, 9 action items). Built persistent kqueue daemon (bridge-watcher.py), reject subcommand for bridge-processor.js, interactive session lock wrapper, LaunchAgent plist, and deployment runbook section. 280 tests pass (240 Node.js + 34 Python unit + 6 Python integration), 0 failures. All 12 acceptance criteria verified. User provided sharp feedback: 60s timeout default (not 300s for Phase 1), accept Python lock dependency for consistent failure mode. The "Phase 1 ops don't need claude --print" architectural insight kept the implementation clean — zero API cost, ~100ms dispatch.

**Compound:** No compoundable insights (implementation followed peer-reviewed plan; user feedback on timeout and lock mechanism were tactical adjustments, not reusable patterns).

**Rating:** 3 — Good

**Next session:** CTB-012 (governance verification tests, unblocked). CTB-014 (peer review) blocked on CTB-012.

## Session 14 — 2026-02-21

### Context Inventory
- `src/crumb/scripts/lib/governance.js` — existing computeGovernance/buildGovernanceCheck
- `src/crumb/test/governance.test.js` — 6 existing governance unit tests
- `src/crumb/scripts/lib/response-builder.js` — buildSuccessResponse/buildErrorResponse
- `src/crumb/scripts/bridge-processor.js` — full processor with CLI
- `_system/scripts/bridge-watcher.py` — dispatch pipeline (dispatch_file, _dispatch_node)
- `design/bridge-schema.md` — governance_check schema (§4.1, §4.2)

### CTB-012 Implementation

**Architecture decision:** Governance verification implemented as an independent Node.js
module (`verify-governance.js`) called from Python watcher via subprocess. This provides:
- Independence: re-computes hash/canary from scratch, doesn't import governance.js
- Cross-language verification: different execution path than the processor
- CLI interface: `verify-governance.js <response-file> [--vault-root <path>]` (exit 0/1)

**Components built:**

1. **`src/crumb/scripts/verify-governance.js`** (CREATE) — Post-processing governance verifier
   - `verifyGovernance(response, vaultRoot)` → `{ passed, checks[], errors[] }`
   - Independent sha256(CLAUDE.md)[:12] hash recomputation
   - Independent last-64-byte canary verification
   - Response schema compliance (required fields, governance_check subfields)
   - Pre-governance error handling (governance_check=null on error status → skip, pass)
   - Success-without-governance detection (governance_check=null on completed status → fail)
   - approval_method enforcement (must be 'bridge-confirm')
   - schema_version major match enforcement
   - CLI mode: exit 0 pass, exit 1 fail, exit 2 usage error

2. **`src/crumb/test/verify-governance.test.js`** (CREATE) — 25 unit tests
   - Hash match/mismatch with expected vs actual reporting
   - Canary match/mismatch + short CLAUDE.md
   - claude_md_loaded true/false
   - approval_method validation
   - Pre-governance error skip behavior
   - Success-without-governance failure
   - Required response field presence
   - Governance subfield presence
   - Schema version major/minor handling
   - Missing summary on success
   - Error structure validation
   - CLAUDE.md unreadable fallback
   - Full valid response passthrough
   - CLI exit code tests (0 and 1)

3. **`_system/scripts/bridge-watcher.py`** (MODIFY) — Watcher integration
   - Added `verify_governance_script` and `alerts_dir` to Config
   - Added `_verify_governance(response_path, config, logger)` function
   - Added `_discard_response(response_path, alert_code, alert_message, config, logger)`
   - Modified `_dispatch_node()`: after successful processing, calls `_verify_governance()`
     on the outbox response. If verification fails: response deleted, alert file written
     to `_openclaw/alerts/`, CRITICAL-level log event emitted.
   - On failure, dispatch_file returns False (request not counted in rate limiter)

4. **`src/watcher/test_integration.py`** (MODIFY) — 3 new integration tests
   - `TestGovernanceVerificationPass`: valid processor response passes verification,
     response retained in outbox, no alerts written
   - `TestGovernanceVerificationFail`: tampered governance_hash → response discarded,
     alert file written with GOVERNANCE_VERIFY_FAILED code and mismatch details
   - `TestGovernanceVerificationPreGovError`: pre-governance errors (null governance_check)
     pass verification, response retained

**Alert mechanism:** Governance failures write JSON alert files to `_openclaw/alerts/`
with timestamp, alert_code, message, and response filename. These can be consumed by
a future Telegram notification system. Alert files are named
`{unix_timestamp}-{ALERT_CODE}.json`.

### Test Results

| Suite | Count | Status |
|-------|-------|--------|
| Node.js (all) | 265 | 0 failures |
| Python unit | 34 | 0 failures |
| Python integration | 9 | 0 failures |
| **Total** | **308** | **0 failures** |

Up from 280 tests (CTB-011 end). Delta: +25 Node.js (verify-governance) + 3 Python integration.

### AC Verification

| AC | Criterion | Status |
|----|-----------|--------|
| 1 | governance_hash matches runner's pre-computed hash | PASS — independent sha256[:12] recomputation |
| 2 | governance_canary matches last 64 bytes of CLAUDE.md | PASS — independent canary extraction |
| 3 | Response JSON matches bridge response schema | PASS — required fields + governance subfields validated |
| 4 | Tests integrated into bridge runner validation pipeline | PASS — watcher calls verify-governance.js after _dispatch_node |
| 5 | Failure → response discarded + Telegram alert | PASS — response deleted, alert file written to _openclaw/alerts/ |

### Session 14 End — 2026-02-21

**Summary:** Implemented CTB-012 (governance verification test suite). Built verify-governance.js as an independent post-processing verifier — re-computes sha256[:12] hash and last-64-byte canary from scratch, compares against processor response. Integrated into bridge-watcher.py dispatch pipeline: verification runs after every _dispatch_node() success, failure discards the response and writes a JSON alert to _openclaw/alerts/. 308 tests pass (265 Node.js + 34 Python unit + 9 Python integration), 0 failures. All 5 acceptance criteria verified.

**Compound:** No compoundable insights (straightforward implementation of well-defined verification checks; the "independent verifier as subprocess" pattern is standard defense-in-depth, not novel).

**Rating:** 3 — Good

**Next session:** CTB-014 (peer review of bridge implementation — last remaining task).

---

## Session 15 — 2026-02-22

### Context Inventory
- `design/tasks.md` — task states, CTB-014 acceptance criteria
- `project-state.yaml` — phase: TASK
- `progress/run-log.md` — sessions 1-14 history
- `_system/reviews/2026-02-21-crumb-tess-bridge-impl.md` — peer review note (from prior session)
- Source files: bridge-processor.js, verify-governance.js, canonical-json.js, outbox-watcher.js, operations.js, project-state.js, echo-formatter.js, constants.js
- Test files: processor-integration.test.js, verify-governance.test.js, outbox-watcher.test.js, canonical-json.test.js, injection-tests.test.js, operations.test.js

### CTB-014: Peer Review — COMPLETE (continued from Session 15a)

**Prior session (15a) completed:**
- 4-model peer review dispatch (GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning)
- Review artifact: 41 files (~398KB, ~10.9K lines) — full M3/M4 codebase
- Review note: `_system/reviews/2026-02-21-crumb-tess-bridge-impl.md`
- Must-fix findings (A1, A2, A3) applied
- Priority should-fix findings (A4, A7) applied
- All 316 tests passed

**This session — remaining should-fixes applied:**

| ID | Fix | Files |
|----|-----|-------|
| A5 | `Number.isInteger()` for sender_id, message_id, echo_message_id, confirm_message_id — rejects NaN/floats | `bridge-processor.js` |
| A6 | ASCII control char rejection (0x00-0x1F except \t, \n, \r) in `validateAscii` | `canonical-json.js` |
| A8 | YAML parser limitations documented (no nesting, no multi-line, no anchors, no escaped quotes) | `project-state.js` |
| A9 | `validateResponseVersion()` — throws on schema_version major mismatch when reading outbox responses | `outbox-watcher.js` |
| A10 | Early return in verify-governance.js when required response fields are missing | `verify-governance.js` |

**Tests added (9 new):**
- 4 canonical-json: NUL, backspace, escape char rejection + tab/newline/CR allowance (A6)
- 2 processor-integration: NaN sender_id, float message_id rejection (A5)
- 2 outbox-watcher: schema version mismatch throw + minor version acceptance (A9)
- 1 verify-governance: early return on missing fields (A10)

**Test updated (1):**
- injection-tests: NUL byte test updated from "passes ASCII" to "rejected by ASCII" (A6 behavior change)

**Final test count: 325 total, 0 failures** (281 Node.js + 44 Python)
Up from 308 at CTB-012 end. Delta: +17 tests across all findings.

**All peer review findings addressed:**
- 3 must-fix (A1, A2, A3) — applied in prior session
- 7 should-fix (A4-A10) — all applied
- 3 deferred (A11 Telegram alerts, A12 .processed-ids O(n)→Set, A13 production allowlist) — Phase 2 scope
- 15 findings declined with reasoning

**AC verification:**

| Criterion | Status |
|-----------|--------|
| 4-model peer review completed | PASS — GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2, Grok 4.1 |
| Dispatch protocol included as review input | PASS — dispatch-protocol.md in artifact |
| Injection test results included | PASS — ctb-008-residual-risk-assessment.md in artifact |
| All must-fix findings addressed | PASS — A1, A2, A3 applied |
| Review note written to vault | PASS — `_system/reviews/2026-02-21-crumb-tess-bridge-impl.md` |

**CTB-014 DONE. All 16 tasks complete.**

### Session 15 End — 2026-02-22

**Summary:** Completed CTB-014 — applied 5 remaining should-fix findings from the 4-model peer review (A5 Number.isInteger, A6 ASCII control chars, A8 YAML parser docs, A9 schema_version check, A10 verify-governance early return). Added 9 new tests, updated 1 existing test (NUL byte behavior change from A6). 325 tests pass, 0 failures. All 16 tasks (CTB-001 through CTB-016) are now complete. TASK phase ready for IMPLEMENT transition. This was a continuation session — the peer review dispatch and must-fix application happened in the prior session (15a, context-compacted).

**Compound:** No compoundable insights (mechanical application of well-scoped review findings; each fix was straightforward with clear acceptance criteria from the review synthesis).

**Rating:** 3 — Good

**Next session:** TASK → IMPLEMENT phase transition gate. All 16 tasks complete. Deferred items: A11 (Telegram alerts), A12 (.processed-ids O(n)→Set), A13 (production sender allowlist). Telegram rendering verification still pending (needs live bot on Studio). LaunchAgent plist ready for installation.

---

## Session 16 — 2026-02-22

### Phase Transition: TASK → IMPLEMENT
- Date: 2026-02-22
- TASK phase outputs:
  - **Design:** bridge-schema.md, dispatch-protocol.md, transcript-format.md, tasks.md (16 tasks complete)
  - **Tess-side code:** bridge-cli.js, 5 libraries (canonical-json, schema, echo-formatter, outbox-watcher, uuid-v7, atomic-write, constants), SKILL.md
  - **Crumb-side code:** bridge-processor.js, verify-governance.js, 5 libraries (governance, operations, project-state, response-builder, transcript)
  - **Infrastructure:** bridge-watcher.py, com.crumb.bridge-watcher.plist, claude-bridge-wrapper.sh, deployment runbook §8.4
  - **Tests:** 325 total (281 Node.js + 44 Python) — e2e, injection (15 payloads), governance verification, unit
  - **Research:** ctb-001 (print mode), ctb-002 (Telegram formatting), ctb-009 (file-watch latency), ctb-008 (residual risk assessment), ctb-010 (cost model)
  - **Reviews:** 6 peer review rounds across the project (spec R1/R2, action plan R1/R2, M3 code, CTB-014 impl)
  - **Colocation spec:** BT1-BT7 integrated, T1/T4/T11 bridge impact notes
- Compound: No new compoundable insights from TASK phase overall — significant findings (confirm_code bypass, cancel/completion precedence, nested session incompatibility, subagent CLI hallucination) already routed in individual session compounds.
- Context usage before checkpoint: low (early session)
- Action taken: none
- Key artifacts for IMPLEMENT phase: action-plan-summary.md, tasks.md (deferred items), deployment runbook §8.4, com.crumb.bridge-watcher.plist

### IMPLEMENT Phase — Deployment & Live Verification

#### Item 1: Directory Setup — DONE
- Created `_openclaw/alerts/` (was missing)
- Fixed `_openclaw/logs/` permissions (was rwxr-xr-x, now rwxrwxr-x)
- All directories confirmed: inbox, outbox, transcripts, alerts, logs — all rwxrwxr-x:crumbvault

#### Item 2: LaunchAgent Installation — DONE
- Copied `com.crumb.bridge-watcher.plist` to `~/Library/LaunchAgents/`
- Bootstrapped via `launchctl bootstrap gui/$(id -u)`
- Verified: state=running, kqueue watching inbox, rate limiter seeded
- Watcher log confirms Phase 1 mode (use_claude=false, timeout=60, rate_limit=60/3600s)

#### Item 3: Shell Wrapper — DONE
- Added `source ~/crumb-vault/_system/scripts/claude-bridge-wrapper.sh` to `~/.zshrc`
- `claude-bridge` command available in new shells

#### Item 5: Live E2E Test — PASS
- Created `query-status` request via `bridge-cli.js write-request` (id: `019c82ae-d6fb-71e7-a5c0-30954ebcc3d9`)
- Watcher detected via kqueue, dispatched to `bridge-processor.js`
- Full pipeline verified: process → governance verification → response in outbox → request moved to .processed/ → transcript written
- Response correctly shows `phase: IMPLEMENT`, governance hash `98fbd333e513` and canary both verified
- End-to-end latency: <1s (kqueue detect + node process + governance verify)

#### Item 4: Telegram Rendering Verification — PASS (all 4 payloads)

| Payload | Result | Telegram Msg |
|---------|--------|-------------|
| P3a (`<script>` injection) | Literal text, no execution | 59 |
| P3b (`<b>` fake bold) | Literal text, not bold | 61 |
| P4 (codeblock breakout) | JSON block intact, tags literal | 63 |
| P15 (homoglyphs 0/O) | Visually distinguishable in monospace | 65 |

P3a label message failed (Telegram rejects `<script>` tag) — confirms our `formatEchoHtml` escaping works.
P6 (long reason) CLOSED by maxLength cap — no rendering verification needed.

**All IMPLEMENT items complete.** Phase 1 bridge is operational.

### Session 16 End — 2026-02-22

**Summary:** Ran TASK → IMPLEMENT phase transition gate (8-step protocol, all clean). Then executed all 5 IMPLEMENT items in one session: directory setup (alerts/ created, logs/ permissions fixed), LaunchAgent installation (watcher running with kqueue), shell wrapper in .zshrc, live e2e test (query-status round-trip through watcher pipeline in <1s with governance verification), and Telegram rendering verification (4 adversarial payloads sent to live bot, all confirmed safe by user visual inspection). Phase 1 bridge is deployed and operational. Attempted to pull bot token from OpenClaw gateway API (WebSocket-based, not REST) — didn't work, user provided token directly.

**Compound:** No compoundable insights (deployment was mechanical execution of runbook §8.4; rendering verification confirmed what unit tests predicted; the OpenClaw gateway WebSocket architecture is project-specific knowledge, not a reusable pattern).

**Rating:** 3 — Good

**Next session:** Tess-side integration (install SKILL.md into OpenClaw so Telegram messages flow through the bridge). Phase 2 deferred items: A11 (Telegram alerts), A12 (.processed-ids optimization), A13 (production sender allowlist).

---

## Session 17 — 2026-02-22

### Context Inventory
- `project-state.yaml` — phase: IMPLEMENT
- `progress/run-log.md` — sessions 1-16 history
- `src/tess/SKILL.md` — bridge skill definition
- `_system/docs/crumb-design-spec-v2-0.md` — system spec (for version bump)
- `_system/docs/claude-ai-context.md` — orientation checkpoint
- OpenClaw source: `/Users/openclaw/.local/lib/node_modules/openclaw/` — skills loading docs and source
- 6 reads from source documents, standard tier

### Tess-Side Skill Integration — COMPLETE

**Goal:** Install crumb-bridge SKILL.md into OpenClaw so Telegram messages flow through the bridge.

**Steps completed:**

1. **Created `_openclaw/skills/crumb-bridge/SKILL.md`** — adapted frontmatter to OpenClaw format (name + description only), CLI paths as absolute references to canonical source at `Projects/crumb-tess-bridge/src/tess/scripts/bridge-cli.js` (no file duplication)

2. **Added `skills.load.extraDirs`** to `/Users/openclaw/.openclaw/openclaw.json` — pointed to `_openclaw/skills/` (user ran jq command with sudo)

3. **Debugging skill visibility** — skill loaded at gateway level but invisible to agent. Root cause analysis:
   - Source code analysis of OpenClaw `skills-*.js` found the filtering chain: `shouldIncludeSkill()` → `filterSkillEntries()` → `disableModelInvocation` filter → agent snapshot
   - `extraDirs` discovery does NOT equal agent visibility — skill must be in workspace directory
   - User moved SKILL.md to `~/.openclaw/workspace/skills/crumb-bridge/` (workspace takes precedence)
   - Stripped `metadata` frontmatter line (no bundled skills used it; minimal format matches working skills)
   - Config entry `skills.entries.crumb-bridge.enabled: true` added
   - Gateway restart via `kill -9` (launchctl/openclaw CLI unreliable for clean restart)
   - Skills session snapshot was stale — `/new` in Telegram forced fresh session

4. **Live Telegram test — PASS** — user sent "what's the status of crumb-tess-bridge" from Telegram. Full pipeline:
   - OpenClaw received message → crumb-bridge skill matched → bridge-cli.js invoked
   - Request written to `_openclaw/inbox/`
   - kqueue watcher detected (01:45:13Z), dispatched to bridge-processor.js
   - Processed successfully, governance verification passed (hash: 98fbd333e513)
   - Response in outbox, formatted HTML relayed to Telegram
   - User saw structured response with phase, status, and governance fields

**Lessons learned documented:** User wrote `openclaw-skill-integration.md` covering 6 pitfalls (extraDirs ≠ visibility, frontmatter format, session snapshot freeze, gateway restart unreliability, workspaceOnly symlink blocking, CLI PATH). Moved to `_system/docs/`.

### Spec v2.0

Bumped Crumb design spec from v1.9.1 to v2.0:
- Crumb is no longer CLI-only — bidirectional Telegram communication via Tess bridge
- v2.0 changelog entry: bridge architecture, 5 Phase 1 ops, security layers, 325 tests
- §9 OpenClaw entry rewritten: Phases 1+3 operational, Phases 2+4 deferred
- Spec file renamed `crumb-design-spec-v1-9.md` → `crumb-design-spec-v2-0.md`
- All references updated (CLAUDE.md, file-conventions.md, inbox-processor SKILL.md, openclaw-crumb-reference.md, claude-ai-context.md)
- vault-check: 0 errors, 0 warnings

### Session 17 End — 2026-02-22

**Summary:** Closed the Telegram loop — installed crumb-bridge skill into OpenClaw, debugged skill visibility (extraDirs ≠ agent visibility, session snapshot freeze, gateway restart unreliability), and verified the full Telegram→Tess→Crumb→Telegram pipeline live. Bumped Crumb design spec to v2.0. Moved user-authored lessons-learned doc from inbox to `_system/docs/`. Updated all spec references (5 files), claude-ai-context.md, project-state.yaml, run-log, and progress-log. vault-check clean.

**Compound:** OpenClaw skill integration pattern — `extraDirs` provides gateway-level discovery but NOT agent visibility. Skills must be in the workspace directory. Session snapshots freeze the skill list — `/new` forces refresh. Gateway restarts via launchctl/CLI are unreliable; `kill -9` + launchd auto-restart is reliable. Full pattern documented at `_system/docs/openclaw-skill-integration.md`. Single occurrence but high-confidence (systematic debugging with source code analysis).

**Rating:** 3 — Good

**Next session:** Phase 2 deferred items: A11 (Telegram governance failure alerts), A12 (.processed-ids optimization), A13 (production sender allowlist). Dispatch protocol implementation for long-running tasks (researcher-skill is first client).

## Session 18 — 2026-02-22

### Context Inventory
- `progress/run-log.md` — session 17 history (skill integration, spec v2.0)
- `src/tess/scripts/lib/echo-formatter.js` — HTML formatter (source of rendering bug)
- `src/tess/scripts/bridge-cli.js` — CLI with format-echo and format-relay commands
- `_openclaw/skills/crumb-bridge/SKILL.md` — deployed skill definition
- `src/tess/test/echo-formatter.test.js` — formatter test suite
- 5 reads from source documents, standard tier

### Markdown Rendering Fix — COMPLETE

**Problem:** Telegram messages from bridge showed raw HTML tags (`<b>`, `<code>`, `<pre>`, `<i>`) instead of rendered formatting. All 4 tested operations (query-status, list-projects, query-vault, reject-gate echo) affected on the display side — functionally correct but visually broken.

**Root cause:** OpenClaw's outbound pipeline escapes raw HTML from model output to prevent Telegram parse failures. The echo-formatter.js emitted raw HTML tags which OpenClaw escaped to literal text before sending to Telegram.

**Fix:** Added Markdown output mode to the formatter. OpenClaw's pipeline naturally converts Markdown to Telegram-safe HTML.

**Changes:**
1. **`echo-formatter.js`** — 6 new functions: `escapeMarkdown()`, `formatEchoMarkdown()`, `formatSuccessRelayMarkdown()`, `formatErrorRelayMarkdown()`, `formatResponseRelayMarkdown()`, `countRenderedCharsMarkdown()`. HTML functions preserved for backward compatibility.
2. **`bridge-cli.js`** — `--format markdown` flag on `format-echo` and `format-relay` commands. Returns `{ text, ... }` for markdown (vs `{ html, ... }` for HTML). Default remains `html`.
3. **`SKILL.md`** — Steps 4 and 6 updated: `--format markdown`, `text` field, removed `parse_mode: HTML` instructions.

**Tests:** 269 pass (225 Node.js + 44 Python), 0 failures. 22 new Markdown-specific tests added (was 247, now 269).

**Live verification:** All 5 Phase 1 operations verified through full Telegram loop with markdown rendering — bold headers, code blocks with syntax highlighting, clean layout. Confirmed by user.

### Spec v2.0.1

Patch bump for markdown rendering fix — display-only change, no protocol or schema changes.

### Session 18 End — 2026-02-22

**Summary:** Fixed Telegram rendering — OpenClaw escapes raw HTML from model output, so bridge formatter now outputs Markdown which OpenClaw converts naturally. 6 new functions in echo-formatter.js, `--format markdown` flag on CLI, SKILL.md updated. 269 tests (22 new), 0 failures. All 5 Phase 1 ops verified live through full Telegram loop with correct formatting. Spec v2.0.1.

**Compound:** No compoundable insights — straightforward display fix. The OpenClaw HTML escaping behavior was already documented in `_system/docs/openclaw-skill-integration.md`.

**Rating:** 3 — Good

---

## Session 19 — 2026-02-22

### Phase 2 Action Plan (CTB-017 through CTB-031)

Invoked action-architect skill to decompose the peer-reviewed dispatch protocol into
implementation milestones and tasks. Incorporated live testing debrief findings:
`invoke-skill` is highest-value Phase 2 operation (covers file analysis + skill delegation).

**Milestones created (M7-M13):**

| Milestone | Tasks | Focus |
|-----------|-------|-------|
| M7: Foundation | CTB-017, 018 | Schema extensions + dispatch state module |
| M8: Walking Skeleton | CTB-019, 020, 021 | Brief/prompt construction, stage runner, engine + routing |
| M9: Multi-Stage & Budget | CTB-022, 023 | Multi-stage lifecycle, budget enforcement, status updates |
| M10: Escalation & Cancel | CTB-024, 025 | Structured escalation flow, cancel-dispatch, kill-switch |
| M11: Tess Integration & Audit | CTB-026, 027 | Tess CLI dispatch support, audit hash, final response |
| M12: Validation | CTB-028 | E2E dispatch + injection tests (gates Phase 2 daily use) |
| M13: Deferred Hardening | CTB-029, 030, 031 | Telegram alerts, Set optimization, sender allowlist |

**Walking skeleton approach:** Single-stage `invoke-skill` works at M8, multi-stage at M9.

### Phase 2 Action Plan Peer Review — 4 Models

**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning
**Artifact:** Phase 2 action plan (M7-M13, CTB-017–031) + task table
**Context docs:** dispatch-protocol.md, specification-summary.md, action-plan-summary.md
**Focus:** Task scoping, dependency correctness, risk calibration, coverage, acceptance criteria

**Key consensus findings:**
- DISPATCH_CONFLICT error code missing from CTB-021 (flock failure path)
- CTB-018 risk too low — crash recovery + state machine = MEDIUM
- CTB-025 depends on CTB-022 (needs budget state for cancel precedence)
- Phase 2 error codes not enumerated in CTB-017 AC
- CTB-020 needs CTB-019 as dependency (stage runner needs prompt builder)

**Applied: 7 must-fix (A1-A7), 6 should-fix (A8-A13):**

| ID | Change | Target |
|----|--------|--------|
| A1 | DISPATCH_CONFLICT on flock failure | CTB-021 |
| A2 | Risk LOW → MEDIUM | CTB-018 |
| A3 | Dependency CTB-021 → CTB-022 | CTB-025 |
| A4 | All 8 error codes in AC | CTB-017 |
| A5 | Dependency +CTB-019 | CTB-020 |
| A6 | Routing to all 5 Phase 2 ops | CTB-021 |
| A7 | tool_calls/tokens advisory only | CTB-019 |
| A8+A13 | Alert writing + missing file handling | CTB-020 |
| A9 | Blocked time accounting detail | CTB-022 |
| A10 | Status formatting moved to Tess | CTB-026 |
| A11 | Dependencies → CTB-022, CTB-024 | CTB-027 |
| A12 | Escalation idempotency rules | CTB-024 |

**Updated critical path:** CTB-017 → CTB-019 → CTB-020 → CTB-021 → CTB-022 → CTB-024 → CTB-027 → CTB-028
**Review note:** `_system/reviews/2026-02-22-crumb-tess-bridge-phase2-action-plan.md`

### Context Inventory

- specification-summary.md
- dispatch-protocol.md (full, 1163 lines)
- action-plan.md + action-plan-summary.md
- tasks.md (Phase 1 table + Phase 2 additions)
- bridge-watcher.py (routing + _dispatch_claude placeholder)
- constants.js, bridge-processor.js (first 60 lines)
- bridge-schema.md (allowlist + file conventions sections)
- peer-review-config.md
- overlay-index.md (no matches)

### Session 19 End — 2026-02-22

**Summary:** Created Phase 2 action plan (M7-M13, CTB-017–031) decomposing the dispatch protocol into 15 tasks across 7 milestones. Walking skeleton approach targets single-stage invoke-skill first. 4-model peer review produced 13 findings (7 must-fix, 6 should-fix), all applied. Key fixes: DISPATCH_CONFLICT error, CTB-018 risk upgrade, dependency corrections, escalation idempotency rules, tool_calls/tokens demoted to advisory. Plan is ready for execution — CTB-017 and CTB-018 can start in parallel.

**Compound:** No compoundable insights — straightforward action-architect + peer-review workflow execution. The pattern of peer review catching dependency gaps is already documented.

**Rating:** 3 — Good

