---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/crumb-tess-bridge/design/specification.md
artifact_type: spec
artifact_hash: 501d1d51
prompt_hash: ec065806
base_ref: null
project: crumb-tess-bridge
domain: software
skill_origin: peer-review
created: 2026-02-19
updated: 2026-02-19
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - perplexity/sonar-reasoning-pro
config_snapshot:
  curl_timeout: 120
  max_tokens: "8192 (OpenAI, Google) / 65536 (Perplexity)"
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 69678
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-19-crumb-tess-bridge-spec-openai.json
  google:
    http_status: 200
    latency_ms: 38022
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-19-crumb-tess-bridge-spec-google.json
  perplexity:
    http_status: 200
    latency_ms: 94730
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-19-crumb-tess-bridge-spec-perplexity.json
tags:
  - review
  - peer-review
---

# Peer Review: Crumb–Tess Bridge Specification

**Artifact:** Projects/crumb-tess-bridge/design/specification.md
**Mode:** full
**Reviewed:** 2026-02-19
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, Sonar Reasoning Pro
**Review prompt:** Structured review of security-critical inter-agent bridge spec. Reviewers evaluated correctness, completeness, internal consistency, feasibility, clarity, and security posture. Specific attention to threat model, execution model (U1/B4), confirmation echo protocol, and Author Notes AN1-AN3.

---

## OpenAI (GPT-5.2)

- [F1]
- [Severity]: STRENGTH
- [Finding]: Clear separation of duties ("Tess is transport, Crumb is governance") and preservation of the filesystem boundary as the primary trust boundary (especially in B4).
- [Why]: This is the most important architectural choice for preventing OpenClaw/Tess from becoming a de facto privileged orchestrator. It also avoids fragile cross-user command execution designs (sudo/setuid).
- [Fix]: None. Keep this as a non-negotiable invariant and restate it as a MUST in the protocol section (not only in assumptions/governance narrative).

- [F2]
- [Severity]: CRITICAL
- [Finding]: Confirmation echo is treated as the primary security control, but the spec still allows Tess to "parse" natural language into an operation + params. This is an NLU misparse / ambiguity hazard (AN1) and can produce "valid JSON that is wrong," which the user might rubber-stamp.
- [Why]: The attacker model isn't only "other senders" or "compromised account." It's also *operator error induced by ambiguity* and *LLM extraction errors*. Echo-confirm reduces risk, but the system is still vulnerable to "looks right at a glance" approvals—especially on a phone.
- [Fix]: Make "structured command first" the default interaction:
  - Require either (a) user sends explicit slash-commands that map 1:1 to operations (e.g., `/approve_gate project=... gate=...`) or (b) Tess must respond with clarifying questions until all required fields are explicit and unambiguous.
  - Add a protocol rule: Tess may not create a request from free-form text unless it can deterministically fill all required fields and passes a strict validator (no fuzzy matching of gate names/projects).
  - Add a new threat entry (e.g., BT6 "NLU Misparse / Ambiguous Intent") with mitigations (strict command grammar, required-field prompts, no defaults for high-impact fields).

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: JSON-in-echo is mentioned as a mitigation but not specified as a hard requirement, and the example echo UI is a human-friendly summary, not the literal payload.
- [Why]: BT2 ("echo bypass") is exactly where you want a cryptographic/protocol-grade invariant: "what you confirm equals what is sent." A summary can be manipulated by formatting tricks, omission, truncation, or UI rendering differences.
- [Fix]: Make JSON-in-echo (or canonicalized field list) a MUST:
  - Tess's echo message must include the *exact canonical payload* (or a canonical subset) that will be written to inbox, plus a deterministic digest (see F4).
  - Use a canonical serialization (stable key ordering, UTF-8, no insignificant whitespace) and display a short hash (e.g., `payload_sha256[:12]`) in the echo; confirmation must include that code (e.g., `CONFIRM 3FA91C2D18A4`).
  - For Telegram usability, show: (1) a concise human summary, (2) the canonical fields block, (3) the short confirmation code.

- [F4]
- [Severity]: CRITICAL
- [Finding]: No end-to-end binding between (a) the echoed content, (b) what is written into `_openclaw/inbox/`, and (c) what Crumb processes. Also, "CONFIRM" is not tied to a specific request other than Tess's in-memory pending state.
- [Why]: Without binding, you can get race/replay/confusion issues: multiple pending requests, restart windows, or a malicious/buggy Tess skill writing a different payload than what was shown. This is a classic "TOCTOU + UI confirmation mismatch" class.
- [Fix]: Add a hard handshake:
  - Tess generates `id` and `payload_hash` at echo time and displays `confirm_code`.
  - User must reply `CONFIRM <confirm_code>`.
  - Tess writes the exact payload including `payload_hash` to inbox.
  - Crumb recomputes hash and rejects if mismatch.
  - Include `echo_message_id` + `confirm_message_id` and require they be present for any operation requiring confirmation.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Operation allowlist is a good start, but the allowlist is defined at a high level and doesn't define parameter constraints, normalization rules, or denial behavior (e.g., unknown project names, gate identifiers).
- [Why]: The "blast radius" is bounded by *both* operation type and parameter space. If `query-vault` allows arbitrary paths, it becomes a vault exfiltration primitive; if `invoke-skill` accepts arbitrary args, it becomes an indirect "do anything" mechanism.
- [Fix]: Define per-operation parameter schemas with strict constraints:
  - `query-vault`: restrict to vault-relative paths, disallow `..`, disallow globbing, and consider a further allowlist ("only within /Projects/<project>/…").
  - `approve-gate`: gate must match an enumerated gate list pulled from project state (no free text).
  - `invoke-skill`: restrict to a small enumerated set of skills, and define per-skill arg schema.
  - Add explicit rejection responses with error codes.

- [F6]
- [Severity]: CRITICAL
- [Finding]: BT4 notes transcript poisoning but the current directory permissions imply Tess can write to `_openclaw/transcripts/`. The spec says "Crumb writes its own transcripts directly (not through Tess)" but that doesn't prevent Tess from forging or editing transcript files.
- [Why]: This undermines auditability and can mislead the operator during incident response ("it says Crumb did X"). In a security-critical bridge, logs must be tamper-evident with respect to the less-trusted component.
- [Fix]: Make transcripts tamper-evident and/or move them out of Tess-writable paths:
  - Preferred: write authoritative transcripts under the primary user outside `_openclaw/` (vault run-log or a protected log dir) and only export a *copy* or *pointer* into `_openclaw/outbox/`.
  - Alternatively: `_openclaw/transcripts/` owned by primary user, writable only by primary user, readable by openclaw (POSIX perms/ACLs).
  - Add signing: Crumb includes `transcript_sha256` in the response; Tess relays it; operator can verify later.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: B4 (file watcher under primary user) is recommended, but the spec understates the security implications of an always-on automation component running as the primary user that triggers Claude Code sessions.
- [Why]: This becomes a new always-on "execution bridge" in the primary user context. Even if it only reads `_openclaw/inbox/`, it is still a daemonized privileged automator whose correctness is now security-critical.
- [Fix]: Treat the watcher/runner as a security boundary component:
  - Minimal, non-LLM code path: a tiny runner that only validates schema + invokes `claude --print` with fixed arguments.
  - Hard rate limits and concurrency limits at the runner level (not only Tess).
  - A kill switch: a single file flag owned by primary user (e.g., `~/.crumb/bridge_disabled`) that prevents processing.
  - Ensure the runner ignores any file not matching strict naming + schema + hash binding (see F4).

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: U5 notes `launchd WatchPaths` may be slow; feasibility of "near-real-time" depends heavily on the watcher choice, but the spec doesn't commit to measurable SLOs.
- [Why]: If latency is minutes, the phone-approval UX degrades and operators will work around it (often in unsafe ways, e.g., expanding permissions or pushing toward persistent sessions).
- [Fix]: Add explicit targets and acceptance criteria:
  - Define SLO: e.g., "P95 detection < 2s; P95 end-to-end approve-gate < 60s under normal load."
  - Make CTB-009 include measurements on the actual Mac Studio under typical load and file system (APFS).
  - Consider `fswatch`/kqueue-based small watcher over `WatchPaths` if needed.

- [F9]
- [Severity]: CRITICAL
- [Finding]: Governance verification (BT3) relies primarily on self-checking by the same potentially-degraded session; the alternative sentinel/hash idea (AN3) is good but not fully specified (what exactly is being attested?).
- [Why]: The core risk is "looks governed but isn't." Self-reporting is weak assurance. You need an external, deterministic attestation that the session ran in the expected governed environment.
- [Fix]: Adopt a lightweight attestation that is mostly external and cheap (recommended over complex schemes):
  - Runner (non-LLM) computes and injects `claude_md_sha256` and `vault_root` path into the prompt, and independently records them alongside request id.
  - Crumb response must echo back `claude_md_sha256` and a fixed "governance banner" string that is stored in CLAUDE.md (a canary).
  - Additionally, runner verifies that `claude` executed with expected working directory and that `.claude/` and `CLAUDE.md` existed and were readable at invocation time.
  - If you want stronger: write a small preamble file generated by runner that Crumb must read and quote (proves tool access + correct FS context).
  - Keep self-check, but treat it as supplementary.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: The spec's Phase 1 security posture claim ("Identical to current colocation spec… No new attack surface beyond what's already approved") is directionally true but slightly overstated because Tess's Telegram connectivity changes *trigger conditions* and social/operational exposure.
- [Why]: Even if the filesystem boundary is unchanged, you've added a remote-triggered workflow that can generate inbox files and influence Crumb actions once a session starts. That's a meaningful operational change, and it should be reflected precisely.
- [Fix]: Rephrase Phase 1 posture to: "No new cross-user execution and no automatic Crumb execution; however, remote messages now influence queued requests. Risk bounded by allowlist + confirmation + interactive execution."

- [F11]
- [Severity]: MINOR
- [Finding]: Internal consistency issue: The sample Telegram echo includes an emoji and formatting, but earlier "machine-readable JSON in echo" is discussed as a mitigation; examples should reflect the intended hardened protocol.
- [Why]: Implementers copy examples. If examples show summaries, the system will drift toward summaries.
- [Fix]: Update examples to show the canonical echo block + hash-bound confirmation code (while still allowing a short human summary above it).

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: Replay and idempotency are not addressed: what happens if Tess resends a request, or the watcher processes the same file twice, or outbox responses are duplicated?
- [Why]: Duplicate approvals or duplicated "start-task" can cause state corruption or repeated costly runs.
- [Fix]: Add idempotency rules:
  - `id` must be globally unique (UUIDv7).
  - Crumb maintains a processed-ids log (in vault) and refuses duplicates.
  - Inbox files are moved to an archive/processed directory atomically after success/failure.
  - Responses include `request_id` and a `result_hash`.

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: Telegram pairing-mode trust (A5) is treated as a key control but without an explicit "what if Telegram account is compromised" operational mitigation beyond "fundamental trust assumption."
- [Why]: For this bridge, compromised Telegram == remote control of vault writes within allowlist. That's acceptable only if you provide an operational kill path and strong friction for high-risk ops.
- [Fix]: Add operational mitigations:
  - Require a second factor for high-risk ops: a rotating passphrase or TOTP-like code included in confirmation (even if attacker has Telegram session).
  - Provide immediate kill switch: disable bot, rotate bot token, or local disable flag for runner (see F7).
  - Add "high-risk mode" that requires interactive approval only (bridge can request but not execute).

- [F14]
- [Severity]: STRENGTH
- [Finding]: Phased approach is appropriate: Phase 1 validates protocol and UX without adding always-on primary-user automation; Phase 2 adds automation only after U2/U3/U5/U6 are resolved.
- [Why]: This is the right way to avoid committing to an execution model before understanding Claude Code automation behavior and watcher latency.
- [Fix]: None; keep the gating prerequisites strict and add explicit "go/no-go" criteria for moving to Phase 2.

- [F15]
- [Severity]: SIGNIFICANT
- [Finding]: The spec assumes Phase 2 can reuse the Phase 1 schema unchanged (A2), but Phase 2 introduces new needs: richer error codes, progress updates, and possibly multi-step interactions.
- [Why]: If you don't plan for extensibility now, you'll end up with ad-hoc fields that weaken validation and increase injection/misparse surface.
- [Fix]: Version the schema now:
  - Add `"schema_version": "1.0"`.
  - Add structured `"error": {code, message, retryable}` in responses.
  - Add `"requires_confirmation": true/false` computed deterministically from operation.
  - Add optional `"progress": {stage, pct}` for long tasks.

- [F16]
- [Severity]: CRITICAL
- [Finding]: (AN1) Yes—JSON-in-echo (or canonical fields + hash) should be a hard protocol requirement, and BT1/BT2 should be extended with an explicit Tess misparse threat.
- [Why]: Misparse is one of the most likely failure modes in real usage; it's independent of external attackers.
- [Fix]: Add BT6 "NLU misparse / ambiguity" + mandate strict command grammar or interactive disambiguation + canonical echo with hash-bound confirm.

- [F17]
- [Severity]: SIGNIFICANT
- [Finding]: (AN2) B4 automated-async likely satisfies the core use case for phone-based approvals (which are naturally asynchronous), but it should be framed explicitly as async with measurable latency targets; synchronous "chatty" interactions should be deferred.
- [Why]: Approvals/status checks don't require streaming interactivity; they require reliability and clarity. Trying to force real-time increases complexity and attack surface (persistent session/daemon).
- [Fix]: Update wording: "Phase 2: automated async approvals (near-real-time SLO X). Phase 4 (future): synchronous interactive mode if needed." Add SLOs and a "don't build persistent session unless…" decision criterion.

- [F18]
- [Severity]: SIGNIFICANT
- [Finding]: (AN3) A sentinel/hash attestation is worth *some* added complexity, but prefer a minimal external attestation over elaborate signing frameworks.
- [Why]: BT3 is existential for this system: if governance silently degrades, the bridge defeats the whole premise. Lightweight attestation meaningfully reduces this risk.
- [Fix]: Implement minimal attestation: runner-computed `claude_md_sha256` + canary string from CLAUDE.md echoed in response + runner-side checks of working directory and file readability; optionally add transcript hash and store authoritative logs outside Tess-writable paths.

---

## Google (Gemini 3 Pro Preview)

### Review Summary
This is a high-quality, security-conscious specification that correctly identifies the primary risks of bridging a governed system (Crumb) with an external transport (Tess). The reliance on the filesystem as a privilege boundary (Model B4) is a strong architectural decision. However, the specification faces a **CRITICAL** feasibility risk regarding the concurrency of Claude Code sessions (Interactive vs. Bridge) and a **SIGNIFICANT** logical gap in the "Confirmation Echo" trust model if Tess's runtime is compromised.

- **[F1]**
- **[Severity]:** CRITICAL
- **[Finding]:** Database/State Lock Concurrency Risk (Missing from Unknowns).
- **[Why]:** The spec treats Bridge sessions and Interactive sessions as logically distinct, but they share the same physical resources: `~/.claude/` config, SQLite history databases, and the vault filesystem. Claude Code (CLI) is not designed as a multi-user server; it typically holds a lock on its state database. If a bridge request triggers a session (Model B4) while the human user is actively working in an interactive terminal session, one of the two will likely crash, hang, or corrupt the history database.
- **[Fix]:** Add a `U7` Unknown: "Concurrency behavior of Claude Code." The "Bridge Runner" script (Phase 2) must check for active interactive sessions (e.g., `pgrep -f claude`) and either queue the request or fail fast if the user is working interactively.

- **[F2]**
- **[Severity]:** SIGNIFICANT
- **[Finding]:** Weak Governance Verification (Addressing AN3).
- **[Why]:** Relying on the LLM (Crumb) to self-report "Governance checks passed" (BT3) is circular. If the model is misaligned or the context loading failed subtly (e.g., prompt injection during load), the model can hallucinate a successful check.
- **[Fix]:** Implement the "Sentinel/Hash" approach mentioned in AN3.
    1.  The **Bridge Runner script** (shell, not LLM) calculates the SHA-256 of `CLAUDE.md` before invoking the CLI.
    2.  The runner injects this hash as a variable into the CLI call (e.g., via `--message "... [HASH: xyz]"`).
    3.  Crumb must echo this hash in the JSON response.
    4.  Tess verifies the hash matches the known state on disk before reporting success to Telegram.

- **[F3]**
- **[Severity]:** SIGNIFICANT
- **[Finding]:** NLU Misparsing Vector & Echo Requirements (Addressing AN1).
- **[Why]:** As noted in AN1, natural language echoes are dangerous. If the user says "Delete the logs," and Tess parses this as `approve-gate` (due to hallucination) but echoes "Okay, I'll handle the logs," the user might confirm. The "Confirmation Echo" is the *only* line of defense against NLU failure.
- **[Fix]:** Make JSON-in-echo a **hard protocol requirement**. The Echo message must contain a code block with the *exact* JSON payload that will be written to `_openclaw/inbox/`. The user instruction must be: "Review the JSON payload below. Reply CONFIRM only if the 'operation' and 'params' match your intent."

- **[F4]**
- **[Severity]:** SIGNIFICANT
- **[Finding]:** "Trusting the Compromised Transport" Logical Fallacy (Refining BT1/BT2).
- **[Why]:** The Threat Model assumes Tess is honest but the User might be spoofed (BT1), or the User is honest but Tess is tricked by Injection (BT2). It misses the vector where **Tess's process is compromised**. If the `openclaw` user is compromised, the attacker controls the logic generating the Echo. They can display a benign Echo to Telegram but write a malicious payload to `_openclaw/inbox/`.
- **[Fix]:** Acknowledge this residual risk. Since Tess is the *only* transport, there is no out-of-band verification possible. The mitigation is strictly the "Allowlist" (limiting blast radius) and the "Transcript" (post-incident forensics). Update BT2 to reflect that a compromised Tess completely bypasses the Echo protection.

- **[F5]**
- **[Severity]:** MINOR
- **[Finding]:** Telegram Message Length Handling (U4).
- **[Why]:** The spec mentions the 4096 limit but doesn't define the behavior for truncation. If the `transcript` or `details` field pushes the JSON payload over the limit, the message will fail to send, leaving the system in an unknown state (task done, user uninformed).
- **[Fix]:** The Tess bridge skill must implement "Smart Chunking."
    1.  Send the Status/Summary.
    2.  Send the JSON Payload (Echo) as a separate message.
    3.  If the transcript is long, upload it as a `.txt` or `.md` file attachment (Telegram Document) rather than a text message.

- **[F6]**
- **[Severity]:** STRENGTH
- **[Finding]:** Model B4 (Filesystem as Boundary).
- **[Why]:** Using `launchd` and file watchers eliminates the need for `sudo`, `setuid`, or complex socket daemons. It leverages the OS's native permission model effectively. This is the strongest security decision in the spec.
- **[Fix]:** N/A (Keep this design). Regarding AN2: Yes, this model is sufficient for phone-based approvals. The latency (1-5 seconds for file watch + 10-30 seconds for context load) is acceptable for "Async Approval," provided the user gets a "Working..." status update immediately.

- **[F7]**
- **[Severity]:** MINOR
- **[Finding]:** Pairing Mode Specificity (A5).
- **[Why]:** "Pairing mode" is vague. If it relies on a shared secret sent once, a leaked history exposes it.
- **[Fix]:** Explicitly state that the Tess Bridge Skill must hardcode the **Telegram User ID (integer)** of the authorized operator in the environment variables (e.g., `ALLOWED_TELEGRAM_ID=12345678`). The bot must drop all updates from `update.message.from.id != ALLOWED_TELEGRAM_ID` immediately, prior to any parsing.

### Review of Author Notes (AN)

*   **AN1 (JSON in Echo):** **Required.** Natural language summaries mask critical parsing errors. The security model relies on the user verifying the *instruction*, not the *intent*.
*   **AN2 (Model B4 Usability):** **Approved.** For the stated use cases (Gate Approvals, Status Checks, Delegation), sub-minute latency is acceptable. Real-time chat is not the goal; "Remote Control" is. B4 fits this perfectly.
*   **AN3 (Sentinel/Hash):** **Recommended.** It adds robustness against "silent failure" where the LLM loads but the context is empty. The shell-based runner calculating the hash provides an anchor outside the probabilistic model.

---

## Perplexity (Sonar Reasoning Pro)

# Bridge Specification Review

## Summary

The Crumb-Tess Bridge specification is a well-structured security-critical design for enabling phone-based task delegation to a sandbox-isolated AI agent system. The document demonstrates mature threat modeling, clear architecture documentation, and deliberate phased delivery. However, it contains **three critical gaps** in governance assurance, **two unresolved architectural uncertainties**, and **insufficient grounding in macOS IPC security best practices**. The Author Notes identify real vulnerabilities that warrant elevation to the main threat model.

- [F1]: Governance Verification Strategy Is Insufficient Against Silent Degradation
- [Severity]: CRITICAL
- [Finding]: BT3 proposes self-check for governance verification. A degraded session might not self-check accurately. The audit trail records "governance verified" when governance actually failed.
- [Why]: For a system where the entire security posture depends on governance fidelity (C6), self-reporting is not acceptable as the primary verification mechanism.
- [Fix]: Implement two-tier verification: in-session self-check + out-of-session external verification via sentinel/hash. If self-check passes but external verification fails, discard the response entirely.

- [F2]: AN1 Identifies Real Threat Not in BT1-BT5 Threat Model
- [Severity]: CRITICAL
- [Finding]: Tess's NLU could misparse the user's message. The confirmation echo shows the misparse, not the original intent. This is distinct from prompt injection and compromised accounts.
- [Why]: Even with single-user pairing, elliptical phrasing, tokenization artifacts, and edge cases in schema validation can trigger extraction errors.
- [Fix]: Elevate to a new threat entry. Require JSON-in-echo as hard protocol requirement. Log original user message alongside parsed request in inbox.

- [F3]: B4 Use Case Match Unvalidated
- [Severity]: SIGNIFICANT
- [Finding]: Spec recommends B4 but provides no UX latency requirement, no latency target, and no testing plan. 5-minute latency would be a fundamental UX mismatch.
- [Why]: User expecting 30-second response will experience 5 minutes as "bridge doesn't work."
- [Fix]: Add explicit UX requirement (<60 sec from confirmation to completion notification). Resolve U5 before committing to Phase 2.

- [F4]: Confirmation Timeout Exploitable for Time-Based Injection
- [Severity]: SIGNIFICANT
- [Finding]: 5-minute timeout window doesn't specify late-confirmation behavior. Attacker could exploit window for time-based injection relying on user's muscle memory.
- [Why]: Late confirmation could process stale request in changed context.
- [Fix]: Clarify: if request timed out, reject late confirmation; require new request.

- [F5]: Tess Compromise Surface Underestimated
- [Severity]: SIGNIFICANT
- [Finding]: Threat model doesn't enumerate what a compromised Tess controls: read vault files, write to inbox/outbox, poison transcripts, inject fake bridge requests.
- [Why]: Tess is a 24/7 process. Compromise doesn't require Telegram account — just an exploit in OpenClaw code, supply chain, or custom skill.
- [Fix]: Add BT6 "Tess Process Compromise (HIGH)" with full enumeration of attacker capabilities.

- [F6]: macOS IPC Security Context Missing for B4
- [Severity]: SIGNIFICANT
- [Finding]: File-watch-based IPC has TOCTOU vulnerabilities. File can be modified between detection and read.
- [Why]: Attacker could modify inbox file between watcher detection and Claude Code reading it.
- [Fix]: Atomic-read semantics: watcher renames file to `.processing` state before reading. Completed files moved to archive directory.

- [F7]: U2 (Claude Code --print) Unverified
- [Severity]: SIGNIFICANT
- [Finding]: Phase 2 design depends on `--print` mode but U2 is unresolved. Spec recommends Phase 2 before validating the foundational assumption.
- [Why]: If `--print` doesn't load CLAUDE.md or support tools, the entire bridge is unsafe.
- [Fix]: Make CTB-001 a prerequisite gate. Do not finalize Phase 2 design until U2 resolved.

- [F8]: Phase 2 Allowlist Expansion Lacks Risk Justification
- [Severity]: MINOR
- [Finding]: Phase 2 adds HIGH-risk operations (start-task, invoke-skill) without explaining why they're safe to enable.
- [Why]: Threat model applies equally to both phases.
- [Fix]: Explicitly justify expansion. Consider deferring `invoke-skill` to Phase 3.

- [F9]: Transcript Persistence Security Incomplete
- [Severity]: MINOR
- [Finding]: No retention policy, access control, or integrity guarantees for transcripts.
- [Why]: Unbounded transcripts leak vault state to openclaw user over time.
- [Fix]: Define retention (90 days), set permissions (primary user only), implement immutability.

- [F10]: AN3 Governance Verification Deferred — Should Be Phase 2 Requirement
- [Severity]: MINOR
- [Finding]: Sentinel/hash approach presented as optional but is fundamental to solving BT3.
- [Why]: Phase 2 would ship with known insufficient control.
- [Fix]: Require sentinel/hash for Phase 2, not Phase 3.

- [F11]: Colocation Spec Dependency Hidden
- [Severity]: MINOR
- [Finding]: Reviewers cannot validate whether assumptions about Tier 1 isolation are correct without the colocation spec.
- [Fix]: Include key assumptions from colocation spec inline.

- [F12]: Phase 1→2 Transition Criteria Undefined
- [Severity]: MINOR
- [Finding]: No explicit go/no-go criteria for moving from Phase 1 to Phase 2.
- [Fix]: Add criteria: 5 consecutive CTB-007 passes, injection tests clean, 10 real bridge requests at 100% correctness.

- [F13]: Token Cost Projection Missing
- [Severity]: MINOR
- [Finding]: No cost estimate in spec. Per-request cost unknown.
- [Fix]: Run CTB-010 early and include results in spec update.

- [F14]: launchd Capabilities Unverified
- [Severity]: MINOR
- [Finding]: Cannot verify current launchd WatchPaths behavior or alternatives.
- [Fix]: Verify in CTB-011 before implementation.

### Strengths: S1 (comprehensive threat modeling), S2 (clear phased delivery), S3 (explicit author self-critique), S4 (governance-first philosophy), S5 (clear system map).

---

## Synthesis

### Consensus Findings

**1. Governance self-check is insufficient — sentinel/hash external verification required (3/3 reviewers)**
- OAI-F9 (CRITICAL), GEM-F2 (SIGNIFICANT), PPLX-F1 (CRITICAL)
- All three reviewers independently flag BT3's self-check as circular and recommend the AN3 sentinel/hash approach. The consensus is strong: runner-computed CLAUDE.md hash, injected into the session, echoed in response, verified externally. Self-check remains supplementary, not primary.

**2. JSON-in-echo must be a hard protocol requirement — not a mitigation note (3/3 reviewers)**
- OAI-F2/F3/F16 (CRITICAL/SIGNIFICANT/CRITICAL), GEM-F3 (SIGNIFICANT), PPLX-F2 (CRITICAL)
- Unanimous agreement. The confirmation echo must show the exact parsed JSON payload, not a natural-language summary. OAI goes further: add hash-bound confirmation codes (CONFIRM + payload_sha256[:12]).

**3. NLU misparsing needs its own threat entry — distinct from prompt injection (3/3 reviewers)**
- OAI-F2/F16 (CRITICAL), GEM-F3 (SIGNIFICANT), PPLX-F2 (CRITICAL)
- All agree AN1 identifies a real threat. The vector is operator error + LLM extraction errors, independent of external attackers. OAI recommends structured slash-commands as the primary interaction mode.

**4. Tess process compromise missing from threat model (2/3 reviewers)**
- GEM-F4 (SIGNIFICANT), PPLX-F5 (SIGNIFICANT)
- Both Gemini and Perplexity flag that a compromised Tess (via skill exploit, supply chain, or dependency vulnerability) is a distinct vector from a compromised Telegram account. OAI addresses it indirectly through F6 (transcript tampering) and F7 (runner hardening).

**5. Echo-to-inbox payload binding / TOCTOU (2/3 reviewers)**
- OAI-F4 (CRITICAL), PPLX-F6 (SIGNIFICANT)
- OAI flags that CONFIRM isn't bound to a specific request. Perplexity flags file-level TOCTOU between watcher detection and Claude reading the file. Both recommend atomic-rename semantics for inbox processing.

**6. B4 latency needs measurable SLOs (2/3 reviewers)**
- OAI-F8 (SIGNIFICANT), PPLX-F3 (SIGNIFICANT)
- Both recommend explicit latency targets (OAI: "P95 < 2s detection, < 60s e2e"; Perplexity: "< 60 sec from confirmation to completion notification").

**7. Transcript tamper-evidence (2/3 reviewers)**
- OAI-F6 (CRITICAL), PPLX-F9 (MINOR)
- OAI strongly recommends moving authoritative transcripts outside `_openclaw/` (Tess-writable). PPLX suggests retention policy + permissions.

### Unique Findings

**GEM-F1: Claude Code session concurrency risk (CRITICAL)**
Only Gemini caught this. Bridge sessions and interactive sessions share `~/.claude/` resources — SQLite history, config, state locks. If both run simultaneously, crashes or corruption are likely. **Genuine insight** — this is a real operational risk for Phase 2 and should be captured as a new Unknown (U7).

**OAI-F12: Replay and idempotency (SIGNIFICANT)**
Only OAI addresses what happens with duplicate requests, watcher re-processing, or outbox duplication. Recommends UUIDv7 IDs, processed-ids log, and atomic inbox archival. **Genuine insight** — the spec doesn't address idempotency at all.

**OAI-F15: Schema versioning (SIGNIFICANT)**
Only OAI flags that A2 (protocol reuse across phases) will need extension points. Recommends `schema_version`, structured errors, `requires_confirmation` field, and progress reporting. **Genuine insight** — versioning now prevents breaking changes later.

**OAI-F13: Second factor for high-risk ops (SIGNIFICANT)**
Only OAI suggests a rotating passphrase or TOTP for high-risk operations even within a confirmed Telegram session. **Interesting but likely overkill for Phase 1** — the confirmation echo + operation allowlist already provide substantial friction. Worth revisiting for Phase 2 task delegation.

**GEM-F7: Hardcode Telegram User ID (MINOR)**
Gemini recommends hardcoding the operator's Telegram User ID in the bridge skill as an additional filter beyond pairing mode. **Practical suggestion** — simple to implement and adds defense-in-depth.

**PPLX-F4: Timeout late-confirmation logic (SIGNIFICANT)**
Only Perplexity details the time-based injection vector via late confirmation. **Genuine insight** — the spec defines timeout but not late-confirmation rejection behavior.

### Contradictions

**Transcript location: inside vs. outside `_openclaw/`**
- OAI strongly recommends authoritative transcripts OUTSIDE `_openclaw/` (in the governed vault) because the `openclaw` user can tamper with anything inside `_openclaw/`.
- Perplexity recommends fixing permissions within `_openclaw/transcripts/` (primary user writable only).
- Both approaches solve the tampering problem differently. OAI's is more robust (tamper-proof by directory location); PPLX's is simpler (same directory structure, stricter permissions).
- **Flag for human judgment:** OAI's approach is architecturally cleaner but requires Crumb to write bridge transcripts to a new location. Crumb already writes to run-log (inside the governed vault), which serves as the authoritative record regardless. The question is whether `_openclaw/transcripts/` needs to be tamper-proof or just tamper-evident.

**Structured commands vs. natural language with disambiguation**
- OAI recommends slash-commands as primary interaction mode (e.g., `/approve_gate project=... gate=...`)
- No other reviewer requires this — they recommend JSON-in-echo as sufficient protection against misparsing.
- **Flag for human judgment:** Slash-commands are more secure but reduce the natural-language UX that makes Telegram interaction valuable (especially with voice input). JSON-in-echo with hash-bound confirmation may be sufficient without forcing command syntax.

### Action Items

**Must-fix (before advancing to PLAN):**

- **A1.** Add BT6 "NLU Misparse / Ambiguous Intent" threat entry. Elevate JSON-in-echo from mitigation note to hard protocol requirement. Update confirmation echo examples to show JSON payload + confirmation code.
  - Source: OAI-F2, OAI-F3, OAI-F16, GEM-F3, PPLX-F2 (5 findings across 3 reviewers)

- **A2.** Implement sentinel/hash governance verification as a Phase 2 requirement (not Phase 3 deferral). Runner computes CLAUDE.md SHA-256, injects into session, Crumb echoes back, runner verifies externally. Self-check becomes supplementary.
  - Source: OAI-F9, OAI-F18, GEM-F2, PPLX-F1, PPLX-F10 (5 findings across 3 reviewers)

- **A3.** Add echo-to-inbox payload binding: Tess generates payload hash at echo time, user confirms with `CONFIRM <hash_prefix>`, Crumb recomputes and rejects on mismatch. Add idempotency via UUIDv7 IDs + processed-ids log.
  - Source: OAI-F4, OAI-F12 (2 findings)

- **A4.** Add U7: "Claude Code session concurrency — can bridge and interactive sessions coexist?" Runner must check for active sessions and queue or fail-fast.
  - Source: GEM-F1 (1 finding, but CRITICAL and clearly valid)

- **A5.** Add BT7 "Tess Process Compromise" threat entry with full enumeration of attacker capabilities (vault read, inbox/outbox write, transcript poisoning).
  - Source: GEM-F4, PPLX-F5 (2 findings)

**Should-fix (before PLAN or early in PLAN):**

- **A6.** Define per-operation parameter schemas with constraints (path validation for `query-vault`, enumerated gates for `approve-gate`, restricted skill set for `invoke-skill`). Add rejection responses with error codes.
  - Source: OAI-F5

- **A7.** Add explicit Phase 2 latency SLO: "P95 end-to-end < 60 seconds." Make CTB-009 a Phase 2 prerequisite gate (not just a research task).
  - Source: OAI-F8, PPLX-F3

- **A8.** Refine Phase 1 security posture claim: replace "identical to colocation spec" with "no new cross-user execution; remote messages influence queued requests; risk bounded by allowlist + confirmation + interactive execution."
  - Source: OAI-F10

- **A9.** Clarify late-confirmation rejection: expired requests return "Request expired, send a new request." No processing of late confirmations.
  - Source: PPLX-F4

- **A10.** Add schema versioning (`schema_version: "1.0"`), structured error responses, and extensibility points for Phase 2.
  - Source: OAI-F15

- **A11.** Add atomic-read semantics for inbox processing: watcher renames to `.processing` before reading, moves to `.completed` after execution.
  - Source: PPLX-F6

- **A12.** Treat the Phase 2 bridge runner as a security boundary component: minimal non-LLM code, hard rate + concurrency limits, kill-switch file flag.
  - Source: OAI-F7

**Defer:**

- **A13.** Second factor (TOTP/passphrase) for high-risk operations. Revisit for Phase 2 task delegation if confirmation echo + allowlist prove insufficient.
  - Source: OAI-F13

- **A14.** Transcript retention policy (90 days) and permission hardening. Address in Phase 3 hardening.
  - Source: PPLX-F9

- **A15.** Hardcode Telegram User ID as additional filter. Simple to implement but pairing mode + confirmation echo already provide the check. Add during CTB-004 implementation if convenient.
  - Source: GEM-F7

- **A16.** Explicit Phase 1→2 go/no-go criteria (5 consecutive test passes, 10 real requests). Useful but belongs in the PLAN phase action plan, not the spec.
  - Source: PPLX-F12

- **A17.** Token cost projections. CTB-010 is already in the task list; results will update the spec.
  - Source: PPLX-F13

### Considered and Declined

- **OAI-F6 (move transcripts outside `_openclaw/`):** `constraint` — Crumb already writes to its own run-log as the authoritative record. The `_openclaw/transcripts/` copy is for Tess's relay convenience, not the audit trail. Transcript hash in the response (per A3) makes tampering detectable. Moving transcripts would break the clean `_openclaw/` boundary model.

- **PPLX-F7 (CTB-001 as prerequisite gate for Phase 2):** `constraint` — CTB-001 is already listed as a Phase 2 prerequisite in the spec's "Prerequisites" section. The spec does not recommend proceeding with Phase 2 before U2 is resolved. The finding is correct in spirit but the spec already addresses it.

- **PPLX-F11 (include colocation spec inline):** `overkill` — The bridge spec is already 500+ lines. Inlining the colocation spec's Tier 1 summary would bloat it further. A cross-reference link is sufficient. The colocation spec is in the same vault and already peer-reviewed.

- **PPLX-F8 (defer `invoke-skill` to Phase 3):** `out-of-scope` — The Phase 2 allowlist is already framed as "additive" and subject to further scoping during PLAN phase. Per-operation parameter schemas (A6) address the underlying concern. Deferring an entire operation type is a PLAN-phase decision.

- **OAI-F11 (update echo examples):** `constraint` — Covered by A1 (update confirmation echo examples to show JSON + confirmation code). Not a separate action item.
