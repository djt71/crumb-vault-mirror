---
type: specification
domain: software
skill_origin: systems-analyst
status: draft
created: 2026-02-19
updated: 2026-02-19
project: crumb-tess-bridge
tags:
  - openclaw
  - security
  - integration
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Crumb–Tess Bridge Specification

## Problem Statement

Crumb is session-bound: it only operates when a human starts a Claude Code terminal session. This means phase-gate approvals, status checks, and task delegation can only happen at a keyboard. The user needs to approve gates, monitor progress, and delegate work from a phone via Telegram, using Tess (the OpenClaw agent at @tdusk42_bot) as the transport layer. Building this bridge creates a new attack surface — a path from Telegram → Tess → Crumb → governed vault writes — that materially changes the threat model established in the colocation spec.

## Facts

- F1. Crumb runs as interactive Claude Code sessions, not a daemon. No persistent process exists to receive messages (colocation spec F13).
- F2. Tess runs as OpenClaw (Node.js gateway) under a dedicated `openclaw` macOS user, always-on via LaunchDaemon with `UserName` key, bound to `ws://127.0.0.1:18789`.
- F3. Tess is connected to Telegram via @tdusk42_bot with pairing mode enabled.
- F4. The colocation spec's Tier 1 hardening is complete: dedicated user, `workspaceOnly`, loopback binding, 9/9 isolation tests pass.
- F5. The `_openclaw/` sandbox exists with inbox/outbox structure. OpenClaw has OS-level write access to `_openclaw/` and read access to the vault via the `crumbvault` group.
- F6. Claude Code CLI supports `--print` mode for non-interactive single-prompt execution and exits after completion.
- F7. Claude Code CLI supports `--resume` for continuing a previous conversation, and `--continue` for continuing the most recent conversation.
- F8. The colocation spec's exchange format uses `{type}-{NNN}.json` files with atomic rename (temp → final) to prevent partial-write corruption.
- F9. Claude Code reads `CLAUDE.md` and `.claude/` on every session start, providing governance automatically.
- F10. The `openclaw` user cannot read credential files (`~/.config/crumb/.env`, `~/.ssh/`, `~/.zshrc`) — verified by isolation tests.
- F11. OpenClaw supports custom skills that can execute shell commands, read/write files, and call external APIs.
- F12. Telegram messages have a 4096-character limit per message. Longer content must be split or sent as documents.
- F13. Telegram supports voice messages natively. Tess will accept voice input via STT transcription (e.g., Whisper) as a primary interaction modality alongside typed text.

## Assumptions

- A1. **Tess's role is transport + session management, not governance.** She relays the user's decisions; she does not make approval decisions. Crumb's CLAUDE.md governance applies whenever Crumb executes. (Validate: confirm this boundary holds under all planned interaction patterns)
- A2. **The message protocol designed for async file exchange (Phase 1) will be reused for real-time CLI invocation (Phase 2).** Phase 2 changes the transport, not the message semantics. (Validate: confirm no protocol changes are needed when switching from file polling to CLI pipe)
- A3. **A confirmation-echo pattern provides sufficient authentication for Phase 1.** Tess echoes back what she's about to relay and waits for explicit user confirmation before acting. (Validate: test against prompt injection scenarios — does an attacker's injected instruction survive the echo-confirm round trip?)
- A4. **Claude Code's `--print` mode is suitable for processing bridge requests.** It can load CLAUDE.md, read vault state, execute a scoped task, and return structured output. (Validate: test `--print` with representative bridge requests — context loading, output format, error handling)
- A5. **The user is the only approved sender in Telegram pairing mode.** No other accounts can message Tess. (Validate: confirm pairing mode is enforced and no other senders are approved)
- A6. **Structured per-round summaries with full transcript persisted to vault provide the right Telegram visibility.** Summaries go to Telegram; full transcripts go to `_openclaw/outbox/` for vault integration. (Validate: test readability of structured summaries within Telegram's 4096-char limit)

## Unknowns

### U1. Crumb Execution Model (CRITICAL — first-class design question)

Crumb has no persistent process. How does it receive and execute bridge requests? Four candidate models, each with different security, cost, and complexity profiles:

| Model | Description | Pros | Cons | Security Impact |
|-------|-------------|------|------|-----------------|
| **A. Persistent session** | `claude` CLI in tmux, always running | Simplest conceptually; immediate response | Token cost of warm session; context fills up; idle behavior unknown; needs monitoring/restart | Persistent session is a persistent attack surface |
| **B. On-demand spawn** | Tess starts new `claude` session per request, exits after | No idle cost; fresh context each time | Startup latency (CLAUDE.md + vault load); the `openclaw` → `tess` user execution boundary | Each session is isolated; smaller blast radius per request |
| **C. Daemon wrapper** | Service keeps Claude Code alive, accepts requests via socket/file-watch | Professional service model; managed lifecycle | Building a gateway for Crumb — duplicates what OpenClaw already is; highest implementation complexity | New always-on attack surface; socket/file-watch is an entry point |
| **D. Direct API** | Tess calls Anthropic API with CLAUDE.md injected as system prompt | Sidesteps "Claude Code needs to be running" entirely | Reimplements Crumb's governance in Tess's context; no access to Claude Code tools, skills, file operations; fragile and duplicative | Governance fidelity depends on how accurately the system prompt reproduces CLAUDE.md behavior |

**Recommendation:** Model B (on-demand spawn) for Phase 2. It aligns with Crumb's existing session-bound model, provides natural isolation between requests, and avoids the cost/complexity of persistent processes. The startup latency is a trade-off worth accepting for the security benefit. Model A is a viable alternative if latency proves unacceptable.

**The user execution boundary problem (Model B):** The `openclaw` user runs Tess. The primary user owns the vault and Claude Code credentials. For Model B, Tess needs a controlled path to invoke `claude` CLI as the primary user. Options:

- **B1. `sudo` with strict allowlist:** `/etc/sudoers.d/openclaw-claude` grants `openclaw` the ability to run exactly one command as the primary user: `claude --print`. No other commands. Requires careful sudoers syntax to prevent argument injection.
- **B2. Setuid wrapper script:** A root-owned setuid script that drops to the primary user and execs `claude --print` with sanitized arguments. Avoids sudoers but setuid scripts are inherently risky.
- **B3. Local socket/pipe:** A lightweight daemon running as the primary user that accepts requests from `openclaw` via a Unix socket. Tess writes to the socket; the daemon invokes `claude` as the primary user. Adds a component but cleanly separates privilege.
- **B4. launchd per-user service:** A LaunchAgent for the primary user that watches `_openclaw/inbox/` for new files and spawns `claude --print` to process them. No cross-user execution needed — file exchange IS the boundary. This is essentially automated async — not synchronous real-time, but with low enough latency to feel responsive.

**Recommendation:** B4 for Phase 2 — it eliminates the cross-user execution problem entirely by keeping Claude Code in the primary user's domain and using the filesystem as the boundary. The `_openclaw/inbox/` watch provides automated-async response without cross-user privilege escalation. B3 is the fallback if file-watch latency is unacceptable.

**Important framing note:** Phase 2 with B4 is *automated async*, not synchronous real-time CLI invocation. Tess writes to inbox; a file watcher (running as the primary user) detects the new file and spawns `claude --print`. The round-trip latency depends on file-watch mechanism (U5) plus Claude Code session time, likely seconds to low minutes. True synchronous Tess↔Crumb message passing within a single exchange would require solving session persistence (Model A or C), which is deferred.

### U2. Claude Code `--print` Mode Capabilities and Limitations

Does `--print` mode fully load CLAUDE.md governance, support tool use (Read, Write, Edit, Bash), and handle multi-turn reasoning? Or is it a single-prompt-in/text-out mode? This determines whether bridge requests can trigger meaningful Crumb work or only simple queries.

### U3. Claude Code Session Lifecycle Under Automation

How does Claude Code behave when invoked programmatically? Specific questions:
- Does `--print` mode support the full tool suite or a restricted subset?
- Can `--resume` reliably continue a session started by `--print`?
- What happens when context fills during an automated session? Is there a graceful degradation path?
- What's the startup time for `--print` with a full CLAUDE.md + vault context load?

### U4. Telegram Message Formatting Constraints

Structured update messages need to fit within Telegram's 4096-character limit while remaining readable. What markdown subset does Telegram render? How do code blocks, tables, and long outputs behave? This affects the transcript relay format.

### U5. File-Watch Latency for Near-Real-Time Response

If using Model B4 (launchd file watcher), what's the practical latency between Tess writing to `_openclaw/inbox/` and the file-watch triggering a Claude Code session? launchd's `WatchPaths` has historically been slow (polling-based). Alternatives: `fswatch`, `kqueue`-based watcher, or OpenClaw's built-in scheduler.

### U6. Token Cost of Bridge Sessions

Each bridge request spawns a Claude Code session that loads CLAUDE.md + vault context. What's the per-request token overhead? At what request frequency does this become cost-prohibitive? This affects whether Model B is viable for high-frequency interactions.

### U7. Claude Code Session Concurrency (CRITICAL — Phase 2 blocker)

Bridge sessions and interactive sessions share the same physical resources: `~/.claude/` config, SQLite history databases, and the vault filesystem. Claude Code is not designed as a multi-session server — it may hold locks on its state database. If a bridge request triggers a session (Model B4) while the user is actively working in an interactive terminal session, one of the two could crash, hang, or corrupt the history database.

**Resolution required before Phase 2.** The bridge runner must enforce single-session execution via a lockfile mechanism:

1. **Primary control: `flock`-based lockfile.** The bridge runner acquires an exclusive lock on `~/.crumb/bridge_session.lock` before spawning any Claude Code session. If the lock is held, the runner queues the request and sends a Telegram notification: "Bridge request queued — session active. Will process when session ends."
2. **Advisory check: `pgrep -f claude`** as a supplementary signal for detecting interactive sessions that don't use the lockfile. If `pgrep` detects an active session, the runner treats it as lock-held (fail-fast, don't queue indefinitely).
3. **Interactive sessions** are not instrumented with the lockfile (Claude Code CLI is not modified). The lockfile guarantees at most one *bridge* session; `pgrep` prevents bridge sessions from overlapping with interactive sessions. This is a TOCTOU-resilient design for the bridge side — the small race window between `pgrep` check and `flock` acquisition is acceptable because the bridge runner controls both steps atomically (check pgrep, then flock, then spawn).

This is a prerequisite for CTB-011.

## System Map

### Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        Mac Studio                                │
│                                                                  │
│  User (phone)                                                    │
│    │                                                             │
│    ▼                                                             │
│  Telegram API ──────────────────────────┐                        │
│                                         ▼                        │
│  ┌────────────────────────────────────────────┐                  │
│  │  Tess (OpenClaw)          [openclaw user]   │                  │
│  │  - Receives Telegram messages               │                  │
│  │  - Confirmation echo + wait for confirm     │                  │
│  │  - Formats bridge requests                  │                  │
│  │  - Writes to _openclaw/inbox/               │  Both phases     │
│  │  - Watches _openclaw/outbox/ for responses  │                  │
│  │  - Relays structured updates to Telegram    │                  │
│  └─────────────┬──────────────────────────────┘                  │
│                │                                                 │
│                ▼                                                 │
│  ┌─────────────────────────────────────┐                         │
│  │  _openclaw/                          │                         │
│  │  ├── inbox/   (Tess → Crumb)        │  Filesystem boundary    │
│  │  ├── outbox/  (Crumb → Tess)        │                         │
│  │  └── transcripts/ (full session logs)│                         │
│  └─────────────┬───────────────────────┘                         │
│                │                                                 │
│                ▼                                                 │
│  ┌────────────────────────────────────────────┐                  │
│  │  Crumb (Claude Code)   [primary user]        │                  │
│  │  - Reads bridge requests from inbox         │                  │
│  │  - Executes under full CLAUDE.md governance │                  │
│  │  - Writes results to outbox                 │                  │
│  │  - Writes full transcript to transcripts/   │                  │
│  │  - Governed vault writes as normal          │                  │
│  └─────────────────────────────────────────────┘                 │
│                                                                  │
│  ┌─────────────────────────────────────┐                         │
│  │  ~/crumb-vault/                      │                         │
│  │  (Crumb-governed, normal operations) │                         │
│  └─────────────────────────────────────┘                         │
└──────────────────────────────────────────────────────────────────┘
```

### Dependencies

- **Bridge → Colocation spec:** All Tier 1 hardening is a prerequisite. The bridge builds on the isolation guarantees.
- **Bridge → `_openclaw/` sandbox:** The existing inbox/outbox structure is the Phase 1 transport.
- **Bridge → Claude Code CLI:** `--print` mode (and potentially `--resume`) is the Phase 2 execution mechanism.
- **Bridge → Telegram API:** Message formatting, character limits, and bot capabilities constrain the UX.
- **Bridge → OpenClaw skills:** Tess needs a custom skill to implement the bridge protocol (message parsing, confirmation echo, request formatting, transcript relay).
- **Crumb governance → CLAUDE.md:** Bridge-invoked sessions must load CLAUDE.md identically to interactive sessions. If governance doesn't load, the bridge is unsafe.

### Constraints

- C1. **User isolation boundary:** The `openclaw` and primary macOS users are separate accounts. Cross-user execution requires explicit privilege design.
- C2. **No persistent Crumb process:** Crumb is session-bound. Any bridge must either make Crumb session-aware or work within the session-per-request model.
- C3. **Telegram 4096-char message limit:** Structured updates must be concise. Long transcripts must be chunked or sent as files.
- C4. **Token cost per session:** Each Claude Code invocation loads CLAUDE.md + vault context. High-frequency bridge requests compound token costs.
- C5. **Solo operator:** Security model must be maintainable by one person. Complexity that requires ongoing monitoring without automation is a liability.
- C6. **Governance fidelity:** Bridge-invoked Crumb sessions MUST have identical governance to interactive sessions. Any divergence is a security gap, not a convenience trade-off.

### High-Leverage Intervention Points

1. **Confirmation echo** — The single highest-impact security control for Phase 1. Every bridge action is previewed in Telegram before execution. The user sees exactly what will happen and explicitly confirms. This catches prompt injection, misinterpretation, and unintended scope.

2. **File-exchange as privilege boundary** — Using `_openclaw/inbox/` as the transport means Tess never needs to invoke `claude` directly. The filesystem IS the security boundary. Crumb processes requests in its own user context with full governance. No cross-user execution needed for Phase 1.

3. **Message schema design** — A well-designed request/response schema that's reusable across Phase 1 (file exchange) and Phase 2 (CLI pipe) prevents throwaway work and ensures protocol consistency.

4. **Transcript persistence** — Full transcripts persisted to vault provide an audit trail, enable session reconstruction, and give the user complete visibility even when Telegram summaries are condensed.

5. **Scoped operation allowlist** — Rather than open-ended "do anything" bridge requests, an explicit allowlist of permitted operations (approve gate, check status, query vault, start task) bounds the attack surface at the protocol level.

### Second-Order Effects

- **Threat model escalation:** The colocation spec rated T1 (prompt injection) as HIGH but impact-bounded to `_openclaw/`. This bridge creates the path: Telegram message → Tess skill → `_openclaw/inbox/` → Crumb session → governed vault writes. A successful prompt injection that survives the confirmation echo now has write access to the full vault. The blast radius increases from "sandbox contamination" to "vault corruption."
- **Governance bypass risk:** If Crumb is invoked via `--print` and CLAUDE.md doesn't fully load, or if the session doesn't have access to skills/tools, governance could be silently degraded. This is not a graceful-failure scenario — it's a "looks like it's working but isn't governed" scenario, which is worse than a hard failure.
- **Session state fragmentation:** Bridge-spawned sessions are separate from interactive sessions. Project state changes made via bridge (e.g., approving a gate) must be durable in the vault so the next interactive session sees them. This is already how Crumb works (vault is source of truth), but it needs explicit testing.
- **Cost amplification:** Each bridge request is a full Claude Code session. A pattern of frequent small queries (e.g., "what's the status?" every hour) could accumulate significant API costs. Rate limiting or batching may be needed.
- **Operational complexity:** Adding a file-watch daemon, bridge skill, message schema, and transcript pipeline to the existing Crumb + OpenClaw stack increases the surface area a solo operator must maintain.

## Threat Model (Bridge-Specific)

### BT1. Prompt Injection via Telegram Surviving Confirmation Echo (HIGH)

**Vector:** Attacker gains access to the approved Telegram account (SIM swap, session theft, or compromise of the user's phone) and sends a crafted message. The confirmation echo shows the request; the attacker confirms it.
**Impact:** Full governed vault writes via Crumb. Attacker can modify specs, create files, alter project state.
**Mitigation:** Confirmation echo (catches injection from *other* senders but not from a compromised approved account). Phase 1: scope limited to approvals + status queries — even a compromised account can only approve/reject, not inject arbitrary work. Phase 2: rate limiting, operation allowlist, anomaly detection (unusual request patterns).
**Residual risk:** If the approved Telegram account is compromised, the attacker has the same bridge capabilities as the user. This is the fundamental trust assumption of the system.

### BT2. Confirmation Echo Bypass via Injection (MEDIUM)

**Vector:** A prompt injection crafted to manipulate Tess's echo formatting — e.g., the injected instruction looks benign in the echo but executes differently when relayed to Crumb. Also covers the case where Tess's process is compromised and displays a benign echo while writing a different payload to inbox.
**Impact:** Tess relays a different action than what the user confirmed.
**Mitigation:** Echo displays the exact JSON payload (hard protocol requirement — see BT6). Hash-bound confirmation code (`payload_sha256[:12]`) ties the user's CONFIRM to a specific payload. Crumb recomputes the hash on read and rejects mismatches. This creates an end-to-end binding: echo → confirmation → inbox payload.
**Residual risk:** If Tess's process is fully compromised (BT7), the attacker controls both the echo and the inbox write — they can display a matching echo+hash for a malicious payload. The confirmation echo protects against injection and misparsing but not against a compromised transport. The operation allowlist bounds blast radius in this scenario.
**Note:** Unicode homoglyphs and zero-width characters in JSON are mitigated by the Canonical JSON Specification (see Protocol Design section) — ASCII-only values are enforced with a validation error, eliminating the homoglyph/zero-width vector entirely.

### BT3. Governance Degradation in Automated Sessions (HIGH)

**Vector:** Claude Code's `--print` mode doesn't fully load CLAUDE.md, or loads it but doesn't enforce tool restrictions, risk tiers, or phase gates. Bridge-spawned sessions appear to work but operate with degraded governance.
**Impact:** Vault writes without proper approval gates, context rules, or risk-tiered checks. Silent governance bypass. This is the most dangerous failure mode — "looks like it's working but isn't governed" creates false confidence.
**Mitigation:** Two-tier governance verification. Mandatory for automated invocations (Phase 2+). Phase 1 interactive runs emit `governance_hash` in responses but do not require pre-injected expected hash (the human operator is the verifier).

**Phase 2 automated verification:**

1. **External verification (primary — runner-side, not LLM):** Before invoking `claude --print`, the bridge runner script computes `sha256(CLAUDE.md)` and verifies that `CLAUDE.md` and `.claude/` exist and are readable. The runner injects only a fresh nonce (`bridge_nonce`) into the session prompt — NOT the expected hash. The session must return both `governance_hash` (self-computed from CLAUDE.md it loaded) and the last 64 bytes of CLAUDE.md as `governance_canary`. The runner verifies: (a) `governance_hash` matches its own pre-computed hash of CLAUDE.md on disk, and (b) `governance_canary` matches the actual last 64 bytes of the file. This is non-echoable — the session must read the file to produce the canary, it cannot simply echo a value the runner provided. Mismatch on either → discard response, report governance failure to Telegram.

2. **In-session self-check (supplementary):** The session confirms CLAUDE.md loaded, project state readable, and tool access matches expectations. Crumb reads CLAUDE.md to compute `governance_hash` and extract `governance_canary` (last 64 bytes). This check is LLM-asserted and therefore supplementary to the runner-side verification.

3. **Output schema validation (runner-side):** The runner validates that the response JSON matches the expected bridge response schema. Malformed responses — even from a session that claims governance passed — are rejected.

**Phase 1 interactive verification:** Crumb emits `governance_hash` and `governance_canary` in bridge responses. The human operator can spot-check these values but no automated runner enforces them. The protocol fields are present from Phase 1 to avoid schema divergence when Phase 2 activates automated verification.

**Residual risk:** If CLAUDE.md is present and readable but the session only partially loads it (e.g., context window fills before risk-tier logic is parsed), the hash check passes but governance is still degraded. The canary (last 64 bytes) detects terminal truncation. Remaining residual: partial loading that skips middle sections. Accepted as low-probability given CLAUDE.md's current size (~200 lines).

### BT4. Transcript Injection / Log Poisoning (MEDIUM)

**Vector:** A compromised Tess skill writes fabricated transcripts to `_openclaw/transcripts/`, making it appear that Crumb took actions it didn't. Or manipulates outbox messages to show false results.
**Impact:** Operator makes decisions based on fabricated transcripts. Erosion of trust in the audit trail.
**Mitigation:** Crumb writes its own transcripts directly (not through Tess). Tess writes to `outbox/`; Crumb writes to `transcripts/`. Cross-reference: Crumb's vault commit history serves as the authoritative record of what actually happened.
**Residual risk:** If `_openclaw/transcripts/` is writable by the `openclaw` user (it is, since it's inside `_openclaw/`), Tess can still append fabricated entries. Mitigation: Crumb also logs to its own run-log (inside the governed vault, outside `_openclaw/`).

### BT5. Denial of Service via Bridge Flooding (LOW)

**Vector:** Compromised Telegram account sends high-frequency requests, each spawning a Claude Code session.
**Impact:** API cost spike; potential resource exhaustion on Studio.
**Mitigation:** Rate limiting in the bridge skill (max N requests per hour). Cooldown after failed confirmation. Per-session cost cap if Claude Code supports it.
**Residual risk:** Low — rate limiting is straightforward and the confirmation echo adds a natural throttle.

### BT6. NLU Misparse / Ambiguous Intent (HIGH)

**Vector:** Tess's NLU extracts the wrong operation, parameters, or scope from the user's message — due to ambiguous phrasing, LLM extraction errors, or (with voice input) compounded STT transcription errors. The user sees the misparsed result in the confirmation echo but rubber-stamps it without careful review — especially likely on a phone where quick "CONFIRM" taps are the norm.
**Impact:** User confirms a different action than intended. Vault state changes that don't match the user's actual request. Unlike prompt injection (external attacker), this is operator error induced by system ambiguity.
**Mitigation:**
1. **JSON-in-echo is a hard protocol requirement** (not a mitigation note). The confirmation echo MUST display the exact parsed JSON payload that will be written to `_openclaw/inbox/`. Natural-language summaries are prohibited in the echo for operations requiring confirmation.
2. **Hash-bound confirmation:** Tess computes `payload_sha256[:12]` at echo time and displays it as a confirmation code. User must reply `CONFIRM <code>` (not bare `CONFIRM`). Tess rejects confirmation if the code doesn't match. Crumb recomputes the hash on read and rejects mismatches.
3. **Strict field validation:** Tess may not create a request from free-form text unless all required schema fields can be deterministically filled. If any field is ambiguous, Tess must send a clarifying question before echoing.
4. **Original message preserved:** The raw user message (text or STT transcript) is logged alongside the parsed request in the inbox file for forensic context.
**Residual risk:** Even with JSON-in-echo, users may not carefully read the payload on a phone. The hash-bound confirmation code adds a mechanical check (wrong code = wrong payload), but a user who copies the code without reading the payload still approves the misparsed action.

### BT7. Tess Process Compromise (HIGH)

**Vector:** Exploit in OpenClaw code, a malicious custom skill, a supply-chain attack on a Node.js dependency, or privilege escalation from the `openclaw` user allows an attacker to execute arbitrary code in Tess's context.
**Impact:** Attacker gains full control of the `openclaw` user's capabilities:
- Read access to all vault files (via `crumbvault` group membership)
- Write access to `_openclaw/inbox/` — can inject arbitrary bridge requests
- Write access to `_openclaw/outbox/` — can forge responses
- Write access to `_openclaw/transcripts/` — can poison the audit trail
- Ability to trigger unlimited Crumb sessions via bridge (Phase 2) without user confirmation
- Access to OpenClaw credentials (`/Users/openclaw/.openclaw/`)
**Mitigation:**
1. **Operation allowlist bounds blast radius** — even forged requests are limited to the allowed operations.
2. **Crumb validates request schema** — malformed or unexpected payloads are rejected.
3. **Crumb logs to its own run-log** (inside the governed vault, outside `_openclaw/`) — this is the authoritative audit trail, not `_openclaw/transcripts/`.
4. **Transcript hash in response** — Crumb includes `transcript_sha256` in the outbox response. Tampering with the transcript after Crumb writes it is detectable.
5. **Phase 2 bridge runner rate limits** — hard cap on requests per hour at the runner level (not just in Tess), preventing unlimited session spawning.
6. **Kill-switch file** — `~/.crumb/bridge_disabled` owned by primary user; if present, the bridge runner refuses all requests regardless of inbox contents.
**Residual risk:** A compromised Tess with write access to `_openclaw/inbox/` can inject requests that bypass the confirmation echo entirely (the echo only protects the Telegram→Tess path, not Tess→inbox). The operation allowlist and Crumb's schema validation are the backstops. This risk is inherent to "always-on transport agent with vault read access and sandbox write access."
**Note:** This threat subsumes BT4 (transcript poisoning) — BT4 is a subset of what a compromised Tess can do. BT4 is retained as a separate entry because transcript tampering can also occur from non-compromise sources (bugs, race conditions).

## Governance Model

### Core Principle: Tess is Transport, Crumb is Governance

```
                     ┌─────────────────┐
                     │  User (phone)    │
                     │  - Initiates     │
                     │  - Confirms      │
                     │  - Approves      │
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │  Tess (OpenClaw) │
                     │  TRANSPORT ONLY  │
                     │  - Parse message │
                     │  - Echo + confirm│
                     │  - Format request│
                     │  - Relay response│
                     │  NO governance   │
                     │  NO vault writes │
                     │  (except sandbox)│
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │  Crumb (Claude)  │
                     │  FULL GOVERNANCE │
                     │  - CLAUDE.md     │
                     │  - Risk tiers    │
                     │  - Phase gates   │
                     │  - Vault writes  │
                     │  - Audit trail   │
                     └─────────────────┘
```

**What this means in practice:**

- Tess NEVER interprets the user's intent. She formats it as a structured request and relays it.
- Tess NEVER decides whether an action is safe. She echoes it and waits for user confirmation.
- Crumb ALWAYS applies full CLAUDE.md governance to every bridge request, identical to interactive sessions.
- If Crumb determines a request is high-risk, it writes a "needs-interactive-approval" response to the outbox. Tess relays this to Telegram. The user can approve or defer to the next terminal session.
- Phase gate approvals via bridge are logged to run-log just like interactive approvals.

### Operation Allowlist (Phase 1)

| Operation | Description | Risk | Confirmation Required |
|-----------|-------------|------|-----------------------|
| `approve-gate` | Approve a phase transition gate | Medium | Yes (echo shows gate details) |
| `reject-gate` | Reject/defer a phase transition | Low | Yes |
| `query-status` | Read project state, phase, current task | Low | No (read-only) |
| `query-vault` | Read a specific vault file or summary | Low | No (read-only) |
| `list-projects` | List active projects and their phases | Low | No (read-only) |

### Operation Allowlist (Phase 2 — additive)

| Operation | Description | Risk | Confirmation Required |
|-----------|-------------|------|-----------------------|
| `start-task` | Begin a specific task from the task list | High | Yes (echo shows task + AC) |
| `invoke-skill` | Run a named skill with arguments | High | Yes (echo shows skill + args) |
| `quick-fix` | Execute a scoped, low-risk change | Medium | Yes (echo shows change) |

Operations not on the allowlist are rejected by the bridge protocol. The user can always do anything from an interactive terminal session.

## Protocol Design

### Message Schema (shared across Phase 1 and Phase 2)

**Bridge Request** (`_openclaw/inbox/`):

```json
{
  "schema_version": "1.0",
  "id": "01953e8a-7b2c-7d4f-8a1e-3f5b6c8d9e0a",
  "timestamp": "2026-02-19T15:30:00Z",
  "operation": "approve-gate",
  "params": {
    "project": "crumb-tess-bridge",
    "gate": "SPECIFY->PLAN",
    "decision": "approved"
  },
  "payload_hash": "3c690c41fcf6",
  "confirmed": true,
  "confirmation": {
    "echo_message_id": 12345,
    "confirm_message_id": 12347,
    "confirm_code": "3c690c41fcf6"
  },
  "original_message": "approve the specify gate for crumb-tess-bridge",
  "source": {
    "platform": "telegram",
    "sender_id": 123456789,
    "message_id": 67890
  }
}
```

**Schema rules:**
- `id` is UUIDv7 (time-ordered, globally unique). Crumb maintains a `_openclaw/.processed-ids` log and rejects duplicates (idempotency).
- `payload_hash` is `sha256(canonical_json(operation + params))[:12]`. See Canonical JSON Specification below.
- `confirmation.confirm_code` must match `payload_hash`. Crumb recomputes and rejects on mismatch.
- `original_message` preserves the raw user text (or STT transcript) for forensic context.
- `source.sender_id` is the Telegram integer user ID (not username), verified against the hardcoded allowed ID.
- After processing, inbox files are atomically moved to `_openclaw/inbox/.processed/` (not deleted).

**Bridge Response** (`_openclaw/outbox/`):

```json
{
  "schema_version": "1.0",
  "id": "01953e8a-9d1e-7f3a-bc2d-4e6f7a8b9c0d",
  "request_id": "01953e8a-7b2c-7d4f-8a1e-3f5b6c8d9e0a",
  "timestamp": "2026-02-19T15:30:45Z",
  "status": "completed",
  "summary": "Phase gate SPECIFY → PLAN approved. Run-log updated. Project state advanced to PLAN.",
  "details": {
    "files_modified": ["project-state.yaml", "progress/run-log.md"],
    "next_action": "Load action-architect skill for PLAN phase"
  },
  "governance_check": {
    "governance_hash": "a1b2c3d4e5f6",
    "governance_canary": "<last 64 bytes of CLAUDE.md>",
    "claude_md_loaded": true,
    "project_state_read": true,
    "risk_tier": "medium",
    "approval_method": "bridge-confirm"
  },
  "transcript_hash": "f6e5d4c3b2a1",
  "transcript_path": "_openclaw/transcripts/01953e8a-7b2c-transcript.md"
}
```

**Response rules:**
- `governance_check.governance_hash` is the session's self-computed `sha256(CLAUDE.md)[:12]`. In Phase 2, the bridge runner independently verifies this against its own pre-computed hash. `governance_canary` is the last 64 bytes of CLAUDE.md — a non-echoable proof that the session actually read the file (see BT3).
- `transcript_hash` is `sha256(transcript_content)[:12]`, enabling tamper detection.
- On error: `"status": "error"`, `"error": {"code": "GOVERNANCE_FAILED", "message": "...", "retryable": false}`.

### Canonical JSON Specification

The `payload_hash` is the integrity binding between echo, confirmation, and execution. Tess (Node.js) and Crumb's runner (Python/Shell) must produce identical byte sequences for the same logical payload. This section is normative.

**Canonical input:** An object containing exactly two keys: `"operation"` and `"params"`. All other request fields are excluded from the hash.

**Serialization rules:**
1. Keys sorted lexicographically at all nesting levels (recursive)
2. No insignificant whitespace (no spaces after `:` or `,`, no newlines)
3. ASCII-only string values — reject any string containing non-ASCII codepoints (U+0080+) with a validation error before hashing. This eliminates Unicode normalization as an attack/mismatch vector.
4. Strings use minimal escaping per RFC 8259 §7 (only `\"`, `\\`, and control characters `\uXXXX`)
5. No trailing commas, no comments, no duplicate keys
6. Integers rendered without leading zeros or decimal points; no floating-point values in the hash input (all numeric values in the schema are integers)
7. Encoding: UTF-8 (trivially ASCII given rule 3)

**Hash computation:** `sha256(canonical_bytes)[:12]` — first 12 hex characters (48 bits) of the SHA-256 digest of the canonical byte sequence.

**Tess echoes the exact canonical string it hashed** — the JSON shown in the confirmation echo is the byte-identical input to `sha256()`. This ensures the user sees exactly what will be hashed.

**Test vector:**

```
Input (logical):
  operation: "approve-gate"
  params: { project: "crumb-tess-bridge", gate: "SPECIFY → PLAN", decision: "approved" }

Note: "→" (U+2192) is non-ASCII — rejected by rule 3. Tess must use ASCII:
  params: { project: "crumb-tess-bridge", gate: "SPECIFY->PLAN", decision: "approved" }

Canonical string:
  {"operation":"approve-gate","params":{"decision":"approved","gate":"SPECIFY->PLAN","project":"crumb-tess-bridge"}}

SHA-256: (implementers compute and verify against this string)
payload_hash (first 12 hex chars): (implementers verify)
```

**Implementation note:** Both Node.js (`JSON.stringify` with sorted keys) and Python (`json.dumps(obj, sort_keys=True, separators=(',', ':'))`) produce compliant output when ASCII-only values are enforced. The test vector serves as the cross-implementation validation — both sides must produce identical hash output for the test input before the bridge is considered operational.

**Transcript** (`_openclaw/transcripts/`):

Full Claude Code session output for audit. Written by Crumb, not Tess. Includes governance verification, all tool calls, all file modifications, and the response payload. Crumb also logs bridge operations to its own run-log (inside the governed vault, outside `_openclaw/`) — this is the authoritative audit trail.

### Confirmation Echo Flow

```
User (Telegram) → "approve the specify gate for crumb-tess-bridge"
      │
Tess (parses) → Extracts: operation=approve-gate, project=crumb-tess-bridge, gate=SPECIFY→PLAN
      │  Computes payload_hash = sha256(canonical_json(operation+params))[:12] = "3c690c41fcf6"
      │
Tess (echoes) → Telegram message:
      │  ┌────────────────────────────────────────────────┐
      │  │ Bridge Request — Confirm?                       │
      │  │                                                 │
      │  │ Parsed payload:                                 │
      │  │ ```json                                         │
      │  │ {                                               │
      │  │   "operation": "approve-gate",                  │
      │  │   "params": {                                   │
      │  │     "project": "crumb-tess-bridge",             │
      │  │     "gate": "SPECIFY->PLAN",                    │
      │  │     "decision": "approved"                      │
      │  │   }                                             │
      │  │ }                                               │
      │  │ ```                                             │
      │  │                                                 │
      │  │ Reply: CONFIRM 3c690c41fcf6                     │
      │  │ Or: CANCEL                                      │
      │  └────────────────────────────────────────────────┘
      │
User → "CONFIRM 3c690c41fcf6"
      │
Tess → Validates confirm_code matches payload_hash
      │  Writes bridge request to _openclaw/inbox/{uuid}.json
      │  (confirmed: true, with echo + confirm message IDs for audit trail)
      │
[Crumb processes — Phase 1: next interactive session; Phase 2: on-demand spawn]
      │
Crumb → Recomputes payload_hash, verifies match
      │  Checks request ID against .processed-ids (idempotency)
      │  Runs governance verification (BT3 two-tier check)
      │  Executes operation under full CLAUDE.md governance
      │  Writes response to _openclaw/outbox/{uuid}-response.json
      │  Writes transcript to _openclaw/transcripts/{uuid}-transcript.md
      │  Moves inbox file to _openclaw/inbox/.processed/
      │
Tess (watches outbox) → Reads response, verifies governance_hash, formats update:
      │  ┌────────────────────────────────────────────────┐
      │  │ Gate Approved                                   │
      │  │                                                 │
      │  │ SPECIFY → PLAN for crumb-tess-bridge            │
      │  │ Files: project-state.yaml, run-log.md           │
      │  │ Next: Load action-architect for PLAN             │
      │  │                                                 │
      │  │ Transcript: {uuid}-transcript.md                │
      │  └────────────────────────────────────────────────┘
```

**Late confirmation handling:** If the user sends `CONFIRM <code>` after the request has expired (Phase 2: 5-minute timeout), Tess rejects it: "Request expired or already processed. Send a new request." No processing of late confirmations — fail-closed.

### Confirmation Timeout Behavior

When Tess sends a confirmation echo and the user does not respond:

- **Phase 1:** No timeout needed. The unconfirmed request is never written to `_openclaw/inbox/`. Tess holds the pending state in memory. If Tess restarts (daemon cycle), pending unconfirmed requests are lost — this is safe (fail-closed).
- **Phase 2:** Unconfirmed requests expire after **5 minutes**. Tess sends a timeout notification to Telegram: "Request expired (no confirmation within 5 min). Resend to retry." No file is written to inbox. No Claude Code session is spawned. The timeout prevents: (a) resource leaks from queued-but-never-confirmed requests, (b) stale requests executing long after the user's intent has changed.
- **Repeated non-response:** After 3 consecutive expired requests within 1 hour, Tess sends a single alert: "Multiple requests timed out. Bridge is still active — send a new request when ready." No automatic disable.

### Telegram Update Format

Structured updates for Telegram, designed for readability within the 4096-char limit:

```
[STATUS] Operation description

Project: project-name
Phase: CURRENT → NEXT (if applicable)

What happened:
- bullet point summary of changes
- files modified

What's next:
- next action or decision needed

📋 Transcript: br-NNN-transcript.md
```

For multi-step operations (Phase 2), per-round summaries follow the same format, posted at each decision point.

## Phased Approach

### Phase 1: Async File Exchange

**Goal:** Validate the message protocol, governance model, and transcript visibility using the existing `_openclaw/` file exchange. No cross-user execution needed.

**Scope:** Approvals + status queries only. Crumb processes bridge requests during the next interactive terminal session (human-triggered, not automated).

**Deliverables:**
1. Bridge request/response JSON schema
2. OpenClaw bridge skill for Tess (message parsing, confirmation echo, request formatting, outbox watching, Telegram relay)
3. Crumb bridge-processing procedure (read inbox, execute, write outbox + transcript)
4. Transcript format and persistence to `_openclaw/transcripts/`
5. Updated `_openclaw/` directory structure (add `transcripts/`)

**Security posture:** No new cross-user execution and no automatic Crumb execution. Remote messages now influence queued requests in `_openclaw/inbox/`. Risk bounded by operation allowlist + hash-bound confirmation echo + interactive-only execution (human must start the Crumb session that processes bridge requests).

**Limitation:** Not real-time. The user sends a bridge request from Telegram; it sits in `_openclaw/inbox/` until the next interactive Crumb session processes it. Useful for non-urgent approvals and status checks. The user can also process bridge requests as the first action in any new terminal session.

### Phase 2: Near-Real-Time Processing

**Goal:** Bridge requests are processed automatically without requiring the user to start a terminal session. Uses Model B4 (launchd file watcher) to spawn Claude Code sessions on demand.

**Scope:** Full Phase 1 operations + task delegation, skill invocation.

**Deliverables:**
1. File-watch mechanism (launchd `WatchPaths` or `fswatch`) for `_openclaw/inbox/`
2. Bridge runner script (runs as primary user, invokes `claude --print` with bridge request context)
3. Session lifecycle management (startup, execution, transcript capture, cleanup)
4. Governance verification (self-check on session start, output validation)
5. Rate limiting and cost monitoring
6. Error handling and Telegram error reporting

**Security changes:**
- New always-on component (file watcher + bridge runner) running as primary user
- Claude Code sessions spawned without human presence — governance verification is critical
- Operation allowlist expanded to include task delegation and skill invocation
- Rate limiting prevents cost/resource exhaustion

**Prerequisites:**
- Phase 1 protocol validated and stable
- U2 resolved (Claude Code `--print` capabilities confirmed)
- U3 resolved (session lifecycle under automation understood)
- U5 resolved (file-watch latency acceptable)
- U6 resolved (token cost per bridge session acceptable)
- U7 resolved (session concurrency behavior understood; runner handles active-session detection)

### Phase 3: Hardening and Operational Maturity

**Goal:** Production-grade reliability, monitoring, and security hardening.

**Scope:** Everything needed for confident daily use without supervision.

**Deliverables:**
1. Monitoring: bridge request/response latency, success rate, token cost per request
2. Alerting: governance verification failures, rate limit hits, malformed requests
3. Cost dashboard: cumulative bridge token spend, per-operation breakdown
4. Operational runbook: bridge troubleshooting, restart procedures, kill-switch extension
5. Colocation spec update: revised threat model incorporating bridge attack surface
6. Peer review of the full bridge implementation

## Domain Classification and Workflow

- **Domain:** software
- **Workflow:** SPECIFY → PLAN → TASK → IMPLEMENT (full four-phase)
- **Rationale:** This is a security-critical system integration with new attack surfaces, cross-user execution design, and protocol design. It requires full rigor. The colocation spec (predecessor) used three-phase because it was infrastructure; this project has more moving parts and higher governance risk.

## Task Decomposition

| ID | Task | Type | Risk | Dependencies | Acceptance Criteria |
|----|------|------|------|--------------|---------------------|
| CTB-001 | Resolve U2: Test Claude Code `--print` mode capabilities | `#research` | Low | None | Document: does `--print` load CLAUDE.md, support tools, handle multi-turn? Results written to run-log |
| CTB-002 | Resolve U4: Test Telegram message formatting constraints | `#research` | Low | None | Document: markdown rendering, character limits, code block behavior in Telegram. Results in run-log |
| CTB-003 | Design bridge request/response JSON schema | `#writing` | Medium | CTB-001 | Schema documented in spec or standalone doc. Covers all Phase 1 operations. Validated against Telegram 4096-char limit for responses |
| CTB-004 | Build OpenClaw bridge skill for Tess | `#code` | High | CTB-003 | Skill implements: message parsing, confirmation echo, request formatting, inbox write (atomic rename), outbox watching, Telegram relay. Unit tests for echo formatting |
| CTB-005 | Build Crumb bridge-processing procedure | `#code` | High | CTB-003 | Crumb can: read inbox, validate schema, execute operation, write outbox + transcript. Governance verification on every execution |
| CTB-006 | Create `_openclaw/transcripts/` directory and format | `#writing` | Low | CTB-003 | Directory exists, transcript format documented, `.gitignore` updated |
| CTB-007 | End-to-end Phase 1 integration test | `#code` | Medium | CTB-004, CTB-005, CTB-006 | User sends Telegram message → Tess echoes → user confirms → request in inbox → Crumb processes interactively → response in outbox → Tess relays to Telegram. Full round trip works |
| CTB-008 | Prompt injection test suite for confirmation echo | `#research` | High | CTB-004 | 10+ injection payloads tested against echo. Document: which survive echo, which are caught, residual risks |
| CTB-009 | Resolve U5: Test file-watch latency options | `#research` | Low | None | Compare launchd WatchPaths vs fswatch vs kqueue. Document latency, reliability, resource usage |
| CTB-010 | Resolve U6: Measure token cost per bridge session | `#research` | Low | CTB-001 | Document: CLAUDE.md load cost, per-operation token usage, projected monthly cost at various request frequencies |
| CTB-011 | Build file-watch + bridge runner for Phase 2 | `#code` | High | CTB-007, CTB-009, CTB-010, U2+U3 resolved | File watcher triggers bridge runner on inbox changes. Runner invokes `claude --print`, captures output, writes outbox + transcript. Rate limiting enforced |
| CTB-012 | Governance verification test suite | `#code` | High | CTB-011 | Automated tests confirm: CLAUDE.md loaded, tools available, risk tiers enforced, output matches expected schema. Tests run on every bridge session |
| CTB-013 | Update colocation spec threat model | `#writing` | Medium | CTB-007 (Phase 1 validated) | Colocation spec updated with bridge-specific threats (BT1-BT5). Threat ratings revised |
| CTB-014 | Peer review of bridge implementation | `#research` | Medium | CTB-012, CTB-013 | 3-model peer review of bridge spec + implementation. All must-fix findings addressed |

### Dependency Graph

```
CTB-001 ──┬── CTB-003 ──┬── CTB-004 ──┬── CTB-007 ──── CTB-013 ──── CTB-014
CTB-002 ──┘             ├── CTB-005 ──┤             │
                        └── CTB-006 ──┘             ├── CTB-011 ── CTB-012 ── CTB-014
CTB-009 ────────────────────────────────────────────┤
CTB-010 ────────────────────────────────────────────┘
CTB-008 ── (parallel with CTB-007, depends on CTB-004)
```

**Phase 1 critical path:** CTB-001 → CTB-003 → CTB-004 + CTB-005 + CTB-006 → CTB-007
**Phase 2 critical path:** CTB-009 + CTB-010 → CTB-011 → CTB-012 → CTB-014

## Author Notes for Peer Review

### R1 Resolution Notes

The following items were raised in the original spec (pre-R1) and have been resolved based on round 1 peer review findings. They are preserved here for R2 reviewers as context on what changed and why.

### AN1. NLU Misparsing → Resolved: BT6 Added (R1: A1, consensus 3/3)

**Original concern:** BT1 missed the simpler vector of Tess misparsing the user's own messages. JSON-in-echo was a mitigation note, not a hard requirement. Voice input (F13) compounds the risk.

**Resolution:** Added BT6 (NLU Misparse / Ambiguous Intent, rated HIGH) as a standalone threat entry. JSON-in-echo is now a **hard protocol requirement** — natural-language summaries are prohibited in the echo for operations requiring confirmation. Hash-bound confirmation codes (`payload_sha256[:12]`) tie CONFIRM to a specific payload. Strict field validation requires all schema fields to be deterministically filled before echoing. Original message preserved for forensic context.

**R2 reviewer question:** Is the BT6 mitigation package (JSON-in-echo + hash-bound confirmation + strict field validation + original message preservation) sufficient? Are there edge cases where the hash-bound confirmation doesn't protect against misparsing?

### AN2. Phase 2 "Automated Async" Framing → Confirmed Sound (R1: consensus)

**Original concern:** B4 is automated async, not synchronous real-time. Could mislead during implementation.

**Resolution:** R1 reviewers confirmed B4 is the right choice. The spec now uses "automated async" framing consistently. True synchronous messaging is explicitly deferred. No spec changes needed beyond terminology cleanup already applied.

### AN3. Governance Verification → Resolved and Strengthened (R1: A2 + R2: A5, A6)

**Original concern:** Self-check alone is insufficient because a degraded session might not self-check accurately.

**R1 resolution:** Two-tier governance verification model added to BT3.

**R2 refinement (A5):** R2 reviewers (OAI-F3) identified that the original two-tier model had a circularity: the runner injected `expected_governance_hash` and checked the response contained it, but the model could simply echo the injected value without reading CLAUDE.md. Fixed: the runner now injects only a nonce, and requires the session to return `governance_canary` (last 64 bytes of CLAUDE.md) — a value the session must read the file to produce. This is non-echoable.

**R2 refinement (A6):** R2 reviewers (OAI-F6) flagged that the runner-centric BT3 mechanism conflicts with Phase 1 (which has no runner). Fixed: two-tier verification is mandatory for automated invocations (Phase 2+). Phase 1 interactive runs emit `governance_hash` and `governance_canary` in responses for protocol consistency, but no automated runner enforces them.

### AN4. Session Concurrency → Resolved: Lockfile (R1: A4 + R2: A1, consensus 2/2)

**Original concern:** Bridge and interactive sessions share `~/.claude/` resources. Proposed `pgrep -f claude` detection.

**R2 resolution:** Both R2 reviewers independently identified TOCTOU race condition in `pgrep`. U7 now specifies `flock`-based lockfile (`~/.crumb/bridge_session.lock`) as primary mechanism with `pgrep` as advisory signal for interactive sessions.

### AN5. Tess Process Compromise — HMAC Declined (R1: A5 + R2: A2 declined)

**Original concern:** Compromised Tess can forge confirmation and inject directly to inbox.

**R2 reviewers proposed:** HMAC-SHA256 shared-secret authentication between Tess and runner.

**User declined:** The shared secret must be readable by the `openclaw` user for Tess to sign. A compromised Tess has the signing key — HMAC is circular under BT7 assumptions. Third-party inbox writes are already prevented by filesystem permissions. The real BT7 mitigations remain: operation allowlist + Crumb's governance verification + runner-side rate limiting + kill-switch file. This is accepted residual risk: a compromised always-on transport agent with sandbox write access can inject schema-valid requests within the allowlist. The allowlist is the blast-radius bound.
