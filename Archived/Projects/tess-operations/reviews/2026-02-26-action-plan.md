---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/tess-operations/action-plan.md
artifact_type: architecture
artifact_hash: 886c288a
prompt_hash: 5c1e243c
base_ref: null
project: tess-operations
domain: software
skill_origin: peer-review
created: 2026-02-26
updated: 2026-02-26
status: active
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 63665
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 36548
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 62465
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 22322
    attempts: 1
    raw_json: Projects/tess-operations/reviews/raw/2026-02-26-action-plan-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: tess-operations Action Plan

**Artifact:** Projects/tess-operations/action-plan.md
**Mode:** full
**Reviewed:** 2026-02-26
**Reviewers:** OpenAI GPT-5.2, Google Gemini 3 Pro Preview, DeepSeek Reasoner (V3.2), Grok 4.1 Fast Reasoning
**Review prompt:** Full architectural review of action plan covering completeness, dependency correctness, risk calibration, task sizing, gate design, parallel execution, critical path, and rollback coverage.

---

## OpenAI (gpt-5.2)

## Structured Review of `tess-operations` Action Plan

### Findings

- **[F1]**
  - **Severity:** STRENGTH
  - **Finding:** Clear phased progression (read-only → write → send) with explicit gates and rollback tiers.
  - **Why:** This matches the real risk curve: most damage comes from “write” and especially “send.” The plan correctly delays iMessage send until email send governance is proven.
  - **Fix:** None.

- **[F2]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The plan references “four validated specs” but does not map milestones/tasks back to the four specs (coverage matrix).
  - **Why:** Without a traceability map, it’s hard to prove completeness and avoid drifting scope (especially across Apple/Google/comms/feed-intel/intelligence).
  - **Fix:** Add a short appendix: **Spec → required capabilities → milestone/task IDs** (e.g., “Chief-of-staff spec §X covered by M1.1–M1.4”), plus “out of scope” items explicitly.

- **[F3]**
  - **Severity:** CRITICAL
  - **Finding:** Cross-user + TCC handling is acknowledged, but the operational model is incomplete for headless/locked-session macOS realities (cron/launchd running as `openclaw` vs GUI session + TCC prompts under `danny`).
  - **Why:** Many Apple automation paths (AppleScript, some Calendar/Reminders tooling, Messages DB access, even some CLIs) silently fail or hang when no active GUI session exists, when the screen is locked, or when TCC prompts cannot be displayed. This is a common “works once, fails overnight” failure mode.
  - **Fix:** Add an explicit **“GUI availability contract”**:
    - Define required state (user `danny` logged in, screen unlocked or not, “Prevent sleep,” etc.).
    - Add a **mechanic canary** that verifies GUI-dependent commands succeed (fast, deterministic).
    - Add a fallback behavior (skip Apple sections, alert once, suppress repeats for N hours).
    - Consider a dedicated LaunchAgent under `danny` for Apple reads/writes rather than sudo-wrapping everything from `openclaw`.

- **[F4]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Approval contract is described, but enforcement points are not fully specified for each “write/send” pathway (where the hard gate lives).
  - **Why:** “Approval-gated” is only safe if the enforcement is technical and centralized (not just prompt policy). You mention wrapper-level AID token gate for email send, but not equivalently for Reminders completion, calendar promotion, iMessage send, Notes export, etc.
  - **Fix:** For every mutation capability, add:
    - **Enforcement layer** (e.g., wrapper checks for a signed/validated AID payload, TTL, nonce/idempotency key).
    - **Audit record** location and schema.
    - **Default deny** behavior on parse/validation failure.

- **[F5]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Secret/token handling is underspecified for Discord bot tokens, Google OAuth artifacts, and shared-secret bridge routing.
  - **Why:** Environment variables are easy but leaky (process lists, logs, crash dumps). Also, multi-bot tokens + OAuth refresh tokens are long-lived high-value secrets.
  - **Fix:** Define a single standard:
    - Store secrets in macOS Keychain (preferred) or an OpenClaw secret store with file permissions + encryption-at-rest.
    - Add “no tokens in logs” requirement + log redaction.
    - Add rotation procedure (especially Discord tokens).

- **[F6]**
  - **Severity:** CRITICAL
  - **Finding:** Cost controls are present but may be internally inconsistent with the stated heartbeat schedule + model choices, and there’s no hard budget circuit-breaker described at runtime (only reports and provider cap).
  - **Why:** A 30-min voice heartbeat (15 hrs/day) plus 24/7 mechanic heartbeat can exceed targets if any job expands context or repeatedly retries. Provider caps help, but you also need local “stop spending” automation before hitting $100/$120.
  - **Fix:** Add a **budget circuit breaker**:
    - Daily rolling spend estimate (even approximate) with hard stop thresholds.
    - Per-job retry ceilings + exponential backoff.
    - A “degraded mode” (briefing-only, no research, no Discord mirroring) when budget risk is detected.

- **[F7]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The plan does not explicitly include load/shedding rules for alert storms (e.g., pipeline flapping, auth flapping, Discord reconnect loops).
  - **Why:** Alert storms are both cost and usability failures; they also train the operator to ignore alerts.
  - **Fix:** Add alert policy:
    - Dedup keys + cool-down windows.
    - Escalation ladder (warn → critical → kill-switch recommendation).
    - “One alert per condition per X minutes” plus periodic summary.

- **[F8]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Task sizing frequently exceeds “atomic ≤5 file changes” (especially M2.1, M2.2, M2.3, and several Phase 2/3 items).
  - **Why:** Oversized tasks reduce throughput, complicate review, and increase rollback blast radius.
  - **Fix:** Split large tasks into atomic sub-tasks. Examples:
    - **M2.1 split**: GCP project/API enablement; OAuth flow + credential storage; label taxonomy/filters; calendars; Drive structure; end-to-end verification script.
    - **M2.2 split**: sudoers + wrapper; install CLIs; TCC grant checklist; reminders architecture; iCloud workspace; allowlist configs; validation canaries.
    - **M2.3 split**: server/channel scaffolding; bot creation/permissions; token storage; OpenClaw config; reconnect/canary tests.

- **[F9]**
  - **Severity:** STRENGTH
  - **Finding:** “Cheap-checks-first” and “LLM only when signal detected” is explicitly called out early.
  - **Why:** This is a major lever for cost containment and reliability, and aligns with the dual-agent design.
  - **Fix:** None.

- **[F10]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Dependency sequencing around Apple Phase 0 and macOS patch gating is correct in spirit, but enforcement is not explicit (what blocks what, mechanically).
  - **Why:** If the plan is executed by multiple people or over time, “checkpoint” gates get bypassed unless they’re encoded as a required check.
  - **Fix:** Add an explicit gate artifact:
    - A `PRECHECKS.md` or structured `tess-state.md` section with “Apple automation allowed: yes/no” derived from `sw_vers` + checklist.
    - Mechanic refuses to run Apple wrapper commands unless precheck flag is true.

- **[F11]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Discord is described as “read-only audit mirror,” but later phases use Discord for canaries, mirroring, and multi-agent operations; that’s more than “read-only.”
  - **Why:** This is a scope/assurance mismatch: if Discord is an audit mirror, it should not become a control plane inadvertently.
  - **Fix:** Clarify the contract:
    - Discord remains **non-authoritative** (no approvals accepted there, no commands).
    - If you want Discord commands later, add a separate gated milestone with threat model + approval parity.

- **[F12]**
  - **Severity:** CRITICAL
  - **Finding:** No explicit threat model / trust-boundary statement for prompt injection across channels and data sources (email bodies, iMessage content, calendar descriptions, notes).
  - **Why:** Once you read external text and later perform actions, you have classic indirect prompt injection risk. You mention it briefly for iMessage, but it should be systemic.
  - **Fix:** Add a cross-cutting “untrusted text handling” design:
    - Strip/quote external content; never treat as instructions.
    - Tool layer requires structured intents; actions only from approved workflows.
    - Explicit “model instruction hierarchy” and sanitization rules.

- **[F13]**
  - **Severity:** MINOR
  - **Finding:** Some success criteria are subjective (“useful,” “adds value”) without an operational definition.
  - **Why:** Gates become hard to evaluate consistently.
  - **Fix:** Add lightweight scoring rubrics:
    - e.g., “briefing usefulness: operator marks 0/1 each day,” “research actionable: contains ≥3 concrete actions with links/files.”

- **[F14]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Hidden bottleneck risk: OAuth/TCC/permissions work (Google + Apple + Discord) is the real critical path after M1 gate, even if milestones are “parallel.”
  - **Why:** These are high-friction, human-in-the-loop tasks that can stall multiple streams, and failures often surface only after time (token refresh, TCC resets, bot permission mismatches).
  - **Fix:** Treat “Auth & permissions stabilization” as its own mini-milestone with:
    - Token refresh test after 24h/72h.
    - Reboot test.
    - Locked-screen test (Apple).
    - Network drop/reconnect test (Discord).

- **[F15]**
  - **Severity:** STRENGTH
  - **Finding:** Rollback tiers are practical and map to realistic operational levers (kill-switch flag, cron removal, service disable, Discord disable).
  - **Why:** This is exactly what you want in early ops: quick isolation without full teardown.
  - **Fix:** None.

- **[F16]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Rollback plan does not explicitly cover “partial state corruption” scenarios (e.g., label state machine applied incorrectly, reminders misfiled, duplicate calendar events).
  - **Why:** Many failures are not “service down” but “service did the wrong thing.” You need recovery playbooks for data integrity.
  - **Fix:** Add per-service remediation:
    - Gmail label rollback query recipes; “undo” label transitions.
    - Reminders list cleanup scripts (or manual checklist).
    - Calendar staging purge procedure.
    - Discord audit log correlation to locate what happened.

- **[F17]**
  - **Severity:** SIGNIFICANT
  - **Finding:** M7 Feed-Intel ownership: good phased approach, but missing an explicit isolation boundary so feed-intel failures can’t destabilize chief-of-staff heartbeats/briefings.
  - **Why:** Once Tess “owns” feed-intel cron, failures can cascade into alerts, costs, or kill-switch triggers that impair core operations.
  - **Fix:** Run feed-intel jobs with:
    - Separate queue/sessionTarget already mentioned—good—also add separate log files, separate budget cap enforcement, and a separate pause flag (not global maintenance).

- **[F18]**
  - **Severity:** MINOR
  - **Finding:** Several token ceilings are stated, but there’s no explicit context/window management policy (what gets included/excluded in prompts, retention rules beyond “HEARTBEAT.md 10-entry cap”).
  - **Why:** Token budgets are defeated by gradual prompt/context creep.
  - **Fix:** Add “prompt budget contract” per job: maximum attachments, maximum included log lines, summarization step before LLM call.

---

## Evaluation Against Requested Dimensions

1. **Completeness**
   - **Mostly complete** across infra, gates, Google/Apple/Discord, feed-intel, intelligence.
   - Main gaps: spec traceability matrix (F2), centralized approval enforcement (F4), systemic prompt-injection threat model (F12), and data-integrity rollback playbooks (F16).

2. **Dependency correctness**
   - High-level sequencing is sound (M0→M1 gate→Phase 0→Phase 1→Phase 2/3→send).
   - Missing/mechanical dependencies: macOS/TCC prechecks enforced (F10), GUI-session dependency (F3), permissions stabilization as explicit dependency (F14).

3. **Risk calibration**
   - Strong: defers sends, uses gates, kill-switch.
   - Underweighted risks: GUI/TCC headless failures (F3), injection across all sources (F12), secret handling (F5), alert storms (F7).

4. **Task sizing**
   - Multiple tasks too large for “atomic” (F8). Needs splitting, especially Phase 0s.

5. **Gate design**
   - Good use of 5-day gates and measurable criteria for stability/cost.
   - Improve measurability for “useful/adds value” items (F13) and add auth/permissions durability tests (F14).

6. **Parallel execution**
   - Parallel windows are correctly identified after M1 gate.
   - You could parallelize further by pre-authoring configs/runbooks/templates during Week 0–1 (doesn’t require gates), but keep execution gated. (Minor optimization; not a core defect.)

7. **Critical path**
   - Stated critical path is plausible, but hidden bottlenecks exist in OAuth/TCC/Discord permissions and durability testing (F14). Also Apple GUI/session constraints can block everything Apple-related (F3).

8. **Rollback coverage**
   - Strong tiered rollback (F15).
   - Needs “wrong mutation” remediation and per-service data cleanup (F16), plus feed-intel isolation pause (F17).

---

## Unverifiable Claims (flagged per request)

- **[F19]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** “OpenClaw v2026.2.25” and referenced runbook path `Projects/openclaw-colocation/design/upgrade-v2026-2-24.md` retargeted to v2026.2.25.
  - **Why:** I can’t confirm that version exists, that those features are included (“prompt caching, session cleanup, stale-lock recovery, exec safeBinTrustedDirs”), or that the runbook path is correct.
  - **Fix:** Provide repository link/commit/tag, release notes, and the runbook artifact hash or canonical location.

- **[F20]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** CVE-2025-43530 described as “TCC bypass via AppleScript/VoiceOver.”
  - **Why:** I cannot verify the CVE ID, description, or patch availability for “macOS 26.2+” from here.
  - **Fix:** Link the official CVE/NVD/Apple security bulletin entry and specify the exact patched macOS build number(s).

- **[F21]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** “crossContextRoutes (#22725) as future enhancement if merged.”
  - **Why:** I can’t verify the existence/status/scope of issue/PR #22725 or what project it belongs to.
  - **Fix:** Add a URL to the issue/PR and a one-line summary of what it provides and what dependency it replaces.

- **[F22]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** Model/version references “Haiku 4.5” and “Sonnet 4.5,” and cost envelope projections ($34–80/mo; $75–115/mo after transition).
  - **Why:** I can’t validate model naming/versioning, pricing, or that the projected usage matches those costs.
  - **Fix:** Attach an assumptions table: average calls/day by job, avg tokens/call, $/token, and sensitivity analysis (p50/p90).

- **[F23]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** “BlueBubbles availability as recommended by OpenClaw docs.”
  - **Why:** I can’t verify what OpenClaw docs recommend or whether BlueBubbles is viable in this environment.
  - **Fix:** Link the specific documentation section and note the tested setup (macOS version, Messages DB access method, required permissions).

---

## Top Priority Fix List (pragmatic ordering)

1. **CRITICAL:** Add GUI/TCC/headless operational contract + canaries (F3).
2. **CRITICAL:** Add systemic prompt-injection threat model and tool-layer guardrails (F12).
3. **SIGNIFICANT:** Centralize technical enforcement for approval across all mutation/send actions (F4).
4. **SIGNIFICANT:** Split oversized Phase 0 tasks into atomic sub-tasks (F8).
5. **SIGNIFICANT:** Add auth/permissions durability mini-gates (24h/72h, reboot, lock screen, reconnect) (F14).
6. **SIGNIFICANT:** Add remediation playbooks for “wrong write” states (F16).

---

## Google (gemini-3-pro-preview)

Based on the review of the `tess-operations` action plan, here is the structured evaluation.

### Executive Summary
The plan is highly mature, exhibiting sophisticated risk management (gate-based progression, read-only phases, cost envelopes) and a clear understanding of the technical constraints (cross-user permissions on macOS, token budgeting). The architecture of separating the "Voice" (Haiku) from the "Mechanic" (Qwen-local) is a strong cost-optimization strategy. However, there is a logical circular dependency regarding data availability in the MVP phase (M1), and the Apple setup phase (M2.2) is likely underestimated regarding complexity.

### Findings

**[F1] [SIGNIFICANT] UNVERIFIABLE CLAIM: External References**
**Finding:** The plan references specific software versions, vulnerability identifiers, and issue numbers that cannot be verified against current public knowledge bases (likely due to the 2026 context of the artifact).
**Why:** Verification of these specific patches and features is critical for security compliance and feature availability.
**Specifics:**
- `CVE-2025-43530` (TCC bypass via AppleScript/VoiceOver)
- `GitHub issue #22725` (crossContextRoutes)
- `OpenClaw v2026.2.25`
**Fix:** Verify these identifiers against the internal project documentation or future-dated knowledge base. Ensure the patch for the CVE exists in the target OS version before proceeding with M2.2.

**[F2] [CRITICAL] Dependency Logic: Data Availability in M1**
**Finding:** M1.2 (Morning Briefing) lists "calendar (read sources)" as content. However, M3.1 (Google) and M3.2 (Apple) are the milestones where the read-only integration for calendars is established.
**Why:** The MVP (M1) cannot report on calendar data if the plumbing to fetch that data isn't built until M3. This creates a blocking dependency or requires "mock" data which defeats the purpose of an operational MVP.
**Fix:**
1. Explicitly state that M1.2 uses a "stub" or text-file-based manual calendar source.
2. OR: Move the *read-only* CLI installation for calendar tools to M1.1, decoupling it from the full "Service Integration" phase.

**[F3] [SIGNIFICANT] Task Sizing: M2.2 Overload**
**Finding:** M2.2 (Apple Services Phase 0) is a massive monolithic task. It involves `sudoers` editing, script creation, CLI installation, interactive TCC granting (which is notoriously flaky on macOS), and multiple config creations.
**Why:** If TCC granting fails (common with cross-user `uid 501` vs `uid 502` execution), the entire milestone blocks. Troubleshooting TCC usually takes longer than configuration.
**Fix:** Split M2.2 into:
- M2.2a: Cross-user execution plumbing (sudoers, wrapper, verification).
- M2.2b: TCC Grants & CLI Installation (interactive session work).
- M2.2c: Config & Workspace setup.

**[F4] [SIGNIFICANT] External Dependency: Feed-Intel Framework**
**Finding:** M7 (Feed-Intel Ownership) lists a prerequisite: "Feed-intel framework M2 migration complete." This prerequisite is not defined within this action plan (which covers TOP-001 to TOP-048).
**Why:** If the external "FIF M2" project slips, M7 is blocked. There is no task allocated here to track or assist that migration.
**Fix:** Add a dependency tracking task in M1 or M2 to verify the status of the Feed-Intel Framework M2 migration, or incorporate the necessary migration steps into M7.1.

**[F5] [MINOR] Rollback Clarity: Tier 4**
**Finding:** The Tier 4 Rollback action is "Remove all cron jobs...". The "Recovery" column states "Provider cap ($100/month) is hard ceiling."
**Why:** The recovery description is a *policy constraint*, not a *recovery action*. It does not explain how to restore service after a full wipe.
**Fix:** Change Recovery for Tier 4 to: "Manual review of all cost drivers. Incremental re-enablement starting at M1 (Briefing only) after root cause analysis."

**[F6] [STRENGTH] Cost/Risk Architecture**
**Finding:** The use of "Mechanic" (local LLM) for health checks and "Voice" (Haiku) only for high-value signal processing is an excellent design pattern.
**Why:** It drastically reduces operating costs while maintaining high-frequency monitoring (heartbeats). This makes the $34–80/month envelope realistic.

**[F7] [STRENGTH] Gate Design: Approval Contract**
**Finding:** The rigorous use of "Approval Contracts" and "Read-Only Phases" before enabling write capabilities (M4/M5) is a best-practice implementation of safe AI operations.
**Why:** It minimizes the "blast radius" of a hallucinating agent, specifically preventing reputation damage (via email/iMessage) or data loss (via delete operations).

### Structured Review Summary

1.  **Completeness:** **High.** Covers infrastructure, services, and intelligence. (Exception: See F4 regarding external dependency).
2.  **Dependency correctness:** **Moderate.** The M1 vs. M3 calendar data issue (F2) is a logic break.
3.  **Risk calibration:** **Excellent.** The phased approach and approval gates are appropriate for an autonomous agent with write access.
4.  **Task sizing:** **Good, with exceptions.** M2.2 (Apple setup) is too dense (F3).
5.  **Gate design:** **Strong.** Measurable criteria (e.g., "$3/day", "3/5 days useful") are enforceable.
6.  **Parallel execution:** **Correct.** The parallel tracks for Google/Apple/Comms in M2-M5 are logical.
7.  **Critical path:** **Clear.** The dependencies are well mapped, though the M1 data issue threatens the start of the parallel phases.
8.  **Rollback coverage:** **Adequate.** Tiers cover the necessary escalation levels.

---

## DeepSeek (deepseek-reasoner)

## Structured Review of tess-operations Action Plan

### **Completeness Assessment**
The plan comprehensively decomposes the four validated specifications into a logical sequence of milestones and tasks. It covers infrastructure, core operational loop, service integrations (Google, Apple, Discord), advanced capabilities, feed-intel ownership, and an intelligence layer. The integration of cost controls, kill-switches, approval contracts, and rollback procedures is thorough.

**Finding:**
- **F1** [MINOR] **Ambiguous "Vault" Reference** — Tasks M1.3 and M8.1 reference "vault health" and "vault working directory" without defining what the "vault" is in this context (e.g., a file system, a password manager, a specific data store).
    - **Why:** Could cause confusion during implementation.
    - **Fix:** Add a brief glossary entry or footnote defining "vault" as used in this plan.

### **Dependency Correctness**
The milestone dependency graph is logically sound and correctly sequences foundational work before service activation. Parallel execution of service Phase 0s (M2.1, M2.2, M2.3) after the core MVP gate is well-identified.

**Findings:**
- **F2** [SIGNIFICANT] **Missing Prerequisite Definition** — M7 (Feed-Intel Ownership) lists a prerequisite of "Feed-intel framework M2 migration complete." The term "FIF M2" is not defined elsewhere in the document.
    - **Why:** Creates ambiguity for the team about what must be completed before starting M7.
    - **Fix:** Define "FIF M2" (presumably a milestone from a separate feed-intel project plan) in a footnote or prerequisite section for M7.
- **F3** [MINOR] **M8.3 Model Inconsistency** — M8.3 specifies using "Sonnet 4.5" for the weekly connections brainstorm. The architectural context only lists two agents: "voice (Haiku 4.5)" and "mechanic (qwen3-coder:30b local)."
    - **Why:** Introduces an unplanned model/cost variable.
    - **Fix:** Align the task specification with the defined agent models from the context, or explicitly justify and budget for the Sonnet 4.5 usage.

### **Risk Calibration**
Risk levels are appropriately calibrated. High-sensitivity operations (iMessage send, email send) are correctly gated behind proven governance models (approval contracts, cooldowns) and stability periods. The principle of read-only before write is consistently applied.

**Finding:**
- **F4** [SIGNIFICANT] **Dead Man's Switch Vagueness** — M0.2 tasks "Register Tess's heartbeat with external monitor (Uptime Robot free tier or equivalent)" but provides no specification for what constitutes a "dead" signal or the recovery action the external monitor should trigger.
    - **Why:** A critical safety mechanism is underspecified. An external monitor is useless without a defined action protocol.
    - **Fix:** Specify the failure condition (e.g., "no heartbeat for 2 hours") and the action (e.g., "send a high-priority SMS/phone alert to the operator, *not* an attempt to auto-restart").

### **Task Sizing**
Most tasks are appropriately scoped as atomic units of work. The parallel "Phase 0" tasks (M2.1, M2.2, M2.3) are large but correctly framed as infrastructure plumbing that can be worked on independently.

**Finding:**
- **F5** [SIGNIFICANT] **Overly Broad Infrastructure Task** — M0.1 "Upgrade OpenClaw" references a separate runbook. If that runbook itself contains a multi-step process, this is fine. However, the task's success is an absolute prerequisite for *all* subsequent work.
    - **Why:** A single-point failure during upgrade could block the entire project.
    - **Fix:** Ensure the referenced runbook includes a clear back-out/rollback procedure for the upgrade itself, and consider noting that here.

### **Gate Design**
Evaluation gates are well-designed with measurable, objective criteria (e.g., false-positive rates, cost ceilings, success rates). The 5-day evaluation period is reasonable for detecting initial stability issues.

**Finding:**
- **F6** [MINOR] **Gate Criteria Ambiguity** — Several gate criteria use subjective terms like "useful" or "adds value" (e.g., M3.1, M5.2).
    - **Why:** Makes pass/fail judgments potentially contentious.
    - **Fix:** Where possible, tie these to objective metrics (e.g., "Operator marks email summary as 'useful' in 4 out of 5 daily feedback prompts").

### **Parallel Execution**
Parallel execution is correctly identified. The plan effectively pipelines infrastructure (M0), core loop (M1), and then fans out to parallel service setup (M2) and phased activations (M3, M4, M5). Intelligence work (M8) can correctly run in parallel with service integration once the MVP gate is passed.

**Finding:**
- **F7** [STRENGTH] **Effective Parallelism** — The separation of service integrations into parallel "Phase 0" plumbing tasks allows for concurrent progress without operational risk. The phased activation (Read-only → Write → Send) within each service is a model of safe, incremental capability rollout.

### **Critical Path**
The critical path (M0 → M1 → M3 → M4 → M5 → M6.2) is correctly identified. The bottleneck is correctly noted as the need for Google Phase 3 (email send) to be stable for 2+ weeks before attempting iMessage send (M6.2). This reflects a prudent, risk-averse approach.

**Finding:**
- **F8** [MINOR] **Hidden Resource Bottleneck** — The plan relies heavily on the "mechanic" agent (qwen3-coder local) for monitoring and structural tasks. While its marginal cost is zero, its runtime and concurrency limits on the local machine are not assessed.
    - **Why:** Could lead to queueing delays or system load issues as task frequency scales.
    - **Fix:** Add a note to M1.1 or M1.3 to monitor local system resource usage (CPU, memory) during the initial 5-day gate to establish a baseline.

### **Rollback Coverage**
The four-tier rollback design is excellent, covering scenarios from single-capability failure to total cost overrun. The actions are concrete and likely to be effective.

**Finding:**
- **F9** [SIGNIFICANT] **Recovery Gap in Tier 0** — Tier 0 (Emergency) recovery is simply removing the maintenance flag. This assumes the system is functional enough to respond to the flag's removal. A true "crisis" might require manual intervention to stop processes or revert configurations.
    - **Why:** The recovery step is incomplete for a severe software or system crash.
    - **Fix:** Expand Tier 0 Recovery to: "1. `touch ~/.openclaw/maintenance`. 2. Manually terminate all Tess/OpenClaw processes if necessary. 3. Diagnose and fix root cause. 4. `rm ~/.openclaw/maintenance` to resume."

### **Unverifiable Claims**
The following specific factual references cannot be independently verified and should be grounded before execution:

- **F10** [SIGNIFICANT] **UNVERIFIABLE CLAIM: Software Version & Runbook** — Reference to "OpenClaw v2026.2.25" and its specific upgrade runbook (`Projects/openclaw-colocation/design/upgrade-v2026-2-24.md`).
- **F11** [SIGNIFICANT] **UNVERIFIABLE CLAIM: CVE Reference** — Reference to "CVE-2025-43530 (TCC bypass via AppleScript/VoiceOver)". This CVE ID appears to be fictional or projected, as the current year is 2024.
- **F12** [SIGNIFICANT] **UNVERIFIABLE CLAIM: GitHub Issue** — Reference to "crossContextRoutes (#22725)" as a future enhancement.
- **F13** [SIGNIFICANT] **UNVERIFIABLE CLAIM: Tool Availability** — Reference to installing CLIs "remindctl, memo, ical-buddy". The existence and compatibility of these specific tools must be verified.
- **F14** [SIGNIFICANT] **UNVERIFIABLE CLAIM: External Documentation** — Reference to "BlueBubbles availability as recommended by OpenClaw docs".

---

### **Summary**
This is a **high-quality, well-structured action plan**. Its strengths are its clear phasing, strong risk mitigation through gates and approval contracts, excellent rollback strategy, and logical dependency management. The findings above are primarily refinements, clarifications, and flags for unverifiable details—not fundamental flaws in the architecture or sequence. Addressing the SIGNIFICANT findings (F2, F4, F9, F10-F14) will further de-risk execution.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: Plan does not explicitly confirm coverage of all four validated specs; references them in Overview but no mapping or checklist tying milestones to spec sections.
- [Why]: Without traceability, gaps in spec implementation could exist, undermining claim of "decomposes four validated specs"; reviewers cannot confirm completeness without specs.
- [Fix]: Add a table in Overview mapping each spec (e.g., Spec1 §X → M1.2) with % coverage per milestone.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "Upgrade to v2026.2.25 using the peer-reviewed runbook (`Projects/openclaw-colocation/design/upgrade-v2026-2-24.md`, retargeted to v2026.2.25)" — no evidence runbook exists or is peer-reviewed; version futuristic (2026).
- [Why]: Critical path starts with unverified prerequisite; failure here blocks all else, but cannot assess feasibility.
- [Fix]: Flag as pending verification; add task to validate runbook existence and retargeting steps explicitly.

- [F3]
- [Severity]: CRITICAL
- [Finding]: Atomic tasks referenced in context as "48 atomic tasks (TOP-001 through TOP-048)" but artifact shows only high-level M0.1–M8.3 sub-tasks (∼40 total), with no TOP-xxx numbering or breakdown.
- [Why]: Violates "executable tasks" claim; sub-tasks like M2.1 (multiple CLI installs, OAuth, folder creation) exceed atomicity (≤5 file changes), risking execution errors.
- [Fix]: Decompose each M#.X into TOP-xxx tasks with file changes listed; e.g., split M2.1 into TOP-010 (gogcli install), TOP-011 (OAuth), etc.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: M7 prereq "Feed-intel framework M2 migration complete" — "FIF M2" abbreviation undefined/unclear; no M2 sub-task for feed-intel.
- [Why]: Breaks dependency correctness; M7 cannot proceed without clarifying what "FIF M2" is (assumed Feed-Intel Framework?), creating hidden bottleneck.
- [Fix]: Define "FIF" explicitly; add M2.4 or prerequisite task for feed-intel plumbing.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "CVE-2025-43530 (TCC bypass via AppleScript/VoiceOver)" — no known CVE by this number; macOS 26.2+ also futuristic/unreleased.
- [Why]: Gates Apple Phase 0 on unverified security claim; if false, unnecessary delay or false security.
- [Fix]: Replace with verifiable macOS version check (e.g., current Sonoma/Ventura CVEs); cite official Apple security bulletin.

- [F6]
- [Severity]: MINOR
- [Finding]: Dependency diagram uses ASCII art with arrows (──→) but M7 branches from M4 level incorrectly (shown under M4 but prereq is M1 + FIF M2); M8 parallel noted but diagram places it ambiguously.
- [Why]: Visual confusion could lead to incorrect sequencing during execution.
- [Fix]: Use Mermaid or clearer table; reposition M7/M8 arrows explicitly from M1.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Risk calibration understates cross-user sudoers (M2.2): grants openclaw (502) sudo to danny (501) binaries without noexec/nopasswd details or audit logging.
- [Why]: High-risk privilege escalation (Apple data access); one compromise escalates to full system, mismatched to "read-only phases first" rhetoric.
- [Fix]: Add TCC automation or AppleScript sandbox; mandate sudo audit (e.g., `sudo -l` checks in heartbeat); defer until after M1 stability.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: Task sizing oversized for M1.2 (Morning Briefing): spans vault, pipeline, calendar/reminders, projects (multiple integrations) under one cron job.
- [Why]: >5 file changes likely (prompts, cron config, data fetches); single point of failure risks Week 1 gate failure.
- [Fix]: Split into M1.2a (core briefing shell), M1.2b (add vault), etc.; enforce ≤5 files/task.

- [F9]
- [Severity]: STRENGTH
- [Finding]: Gate design uses measurable, multi-dimensional criteria (e.g., M1: briefing acted on ≥3/5 days, cost ≤$3/day, stability ≥80%).
- [Why]: Ensures objective progression; failure policies (extend 3 days, descope) prevent sunk-cost fallacy; covers accuracy, cost, stability.
- [Fix]: N/A

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Parallel execution misses opportunity: M8.1–8.2 could fully parallel M2+ (only needs M1 data); M7.1 (monitoring-only) could start post-M1 without full FIF M2.
- [Why]: Underutilizes concurrency; critical path (to M6 iMessage) delayed unnecessarily.
- [Fix]: Update diagram: branch M8 from M1 directly; make M7.1 prereq only M1 gate.

- [F11]
- [Severity]: CRITICAL
- [Finding]: Critical path claims "Week 0 → Week 1 → parallel Phase 0s" but ignores M6.2 prereq ("Google email send stable 2+ weeks"), creating hidden 2-week+ bottleneck post-M5.
- [Why]: iMessage send (high-stakes) not on stated critical path; total timeline understated (e.g., Weeks 0-3+ for full ops).
- [Fix]: Redefine critical path as M0→M1→M2.1→M3.1→M4.1→M5.1 (2wk hold)→M6.2; add timeline estimates per milestone.

- [F12]
- [Severity]: MINOR
- [Finding]: Rollback tiers good but Tier 4 trigger "$120/month" inconsistent with Overview ($100/month hard cap, $34–80 rising to $115).
- [Why]: Confusion on thresholds; risks premature full rollback.
- [Fix]: Align to "$100 cap breach → Tier 4"; add monitoring task for provider billing alerts.

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: GitHub "crossContextRoutes (#22725)" — issue number cannot be confirmed; may not exist or be merged.
- [Why]: M5.3 fallback depends on unverified upstream; if stalled, blocks Comms Phase 3.
- [Fix]: Add contingency (e.g., "if #22725 not merged by M5, implement local-only bridge"); verify status pre-M5.

- [F14]
- [Severity]: SIGNIFICANT
- [Finding]: Completeness gap: multi-channel comms mentions Telegram + Discord, but no Slack/Email channels or feed-intel multi-output despite "multi-channel communications" in context.
- [Why]: Partial coverage of stated project goal; feed-intel (M7) Telegram-only initially.
- [Fix]: Add M2.4+ for additional channels if specced; confirm in specs mapping (F1).

- [F15]
- [Severity]: STRENGTH
- [Finding]: Rollback coverage comprehensive: 5 tiers from emergency kill-switch to full revert, with triggers/actions/recovery; matches realistic scenarios (cost, service failure).
- [Why]: Provides graded response without overkill; Tier 0 global switch aligns with policy.
- [Fix]: N/A

- [F16]
- [Severity]: MINOR
- [Finding]: Gate criteria for M3/M4/M5 lack stability metrics (e.g., M1 has "self-healing ≥80%"); only service-specific.
- [Why]: Inconsistent; risks passing unstable integrations.
- [Fix]: Standardize with "uptime ≥95%, restarts succeed ≥90%" across gates.

---

## Synthesis

### Review Quality Assessment

| Reviewer | Signal | Findings | Key Contribution |
|----------|--------|----------|-----------------|
| OpenAI GPT-5.2 | High | 23 (3 CRITICAL, 12 SIGNIFICANT, 3 MINOR, 5 unverifiable) | Deepest analysis — GUI/TCC headless contract, prompt injection threat model, approval enforcement gaps, alert storm policy |
| Gemini 3 Pro Preview | Medium-high | 7 (1 CRITICAL, 3 SIGNIFICANT, 1 MINOR, 5 unverifiable) | Found M1 calendar data dependency gap (most actionable single finding) |
| DeepSeek V3.2 | Medium | 14 (0 CRITICAL, 5 SIGNIFICANT, 4 MINOR, 5 unverifiable) | Dead Man's Switch underspecification, Tier 0 recovery gap |
| Grok 4.1 Fast | High | 16 (2 CRITICAL, 8 SIGNIFICANT, 4 MINOR, 3 unverifiable) | Critical path 2-week hold gap, sudoers risk callout, parallel execution optimization |

### Consensus Findings

**1. Phase 0 tasks are oversized and need splitting** (OAI-F8, GEM-F3, GRK-F3, GRK-F8)
All four reviewers flagged task sizing, with M2.1 (Google Phase 0), M2.2 (Apple Phase 0), and M2.3 (Discord Phase 0) as the main offenders. These tasks each bundle 5-8 distinct operations (CLI installation, credential setup, config creation, verification). The tasks.md file already has atomic TOP-xxx tasks for each, but the action plan's milestone descriptions read as monolithic. GEM-F3 specifically called out M2.2 (Apple) as highest risk due to TCC grant flakiness.

**Assessment:** Valid — the `tasks.md` file already has proper atomic decomposition (e.g., TOP-019 through TOP-023 for Apple Phase 0), but the action plan descriptions don't make this visible. The action plan should reference the task IDs for each milestone phase to make the decomposition explicit.

**2. Feed-intel "FIF M2" prerequisite is undefined** (GEM-F4, DS-F2, GRK-F4)
Three reviewers flagged that M7's prerequisite "Feed-intel framework M2 migration complete" references an external project milestone not defined in this plan. The abbreviation "FIF M2" is used without expansion.

**Assessment:** Valid. The feed-intel-framework project is a separate project in TASK phase. The action plan should explicitly state this is an external dependency with project reference, not leave it as an opaque abbreviation.

**3. No spec traceability matrix** (OAI-F2, GRK-F1)
Two reviewers asked for a mapping from spec sections to milestone/task IDs to prove completeness.

**Assessment:** Valid but proportionate response is a lightweight appendix, not a full traceability matrix. A table showing which spec phases map to which milestones is sufficient.

**4. Subjective gate criteria** (OAI-F13, DS-F6, GRK-F16)
Three reviewers flagged "useful," "adds value" language in gate criteria without operational definitions.

**Assessment:** Partially valid. The main gates (M1 Week 1) have measurable criteria. Later gates (M3+, M8) use softer language. These later gates should add lightweight scoring (operator marks 0/1 per day) rather than numeric SLOs.

**5. Rollback gaps — partial state and Tier 0/4 recovery** (OAI-F16, DS-F9, GEM-F5)
Three reviewers flagged different rollback gaps: OAI-F16 noted no remediation for "wrong mutation" scenarios (mislabeled emails, misfiled reminders), DS-F9 noted Tier 0 recovery assumes the system responds to flag removal, GEM-F5 noted Tier 4 recovery describes policy not action.

**Assessment:** Valid across all three. Tier 0 should include manual process kill steps. Tier 4 should describe incremental re-enablement. Per-service "undo" procedures for common mismutations should be added.

### Unique Findings

**OAI-F3: GUI/TCC headless operational contract** (CRITICAL)
OpenAI flagged that macOS AppleScript, TCC, and some CLI tools silently fail when no active GUI session exists or screen is locked. Suggests a "GUI availability contract" with canary verification and fallback behavior.

**Assessment:** Genuine insight but partially addressed. The Apple spec §2.3 already documents the GUI session dependency ("Studio is always logged in — treated as safe assumption, with a health check") and the mechanic heartbeat verifies TCC permissions. However, the action plan doesn't surface this as an explicit verification task. **Should add a health-check canary to TOP-022** (cross-user verification) that tests GUI-dependent paths.

**GEM-F2: M1 morning briefing references calendar data before M3 provides it** (CRITICAL)
Gemini caught that M1.2 lists "calendar (read sources)" as briefing content, but calendar integration isn't built until M3.

**Assessment:** Genuine gap. The M1 morning briefing should explicitly state it uses only data available at that stage: vault status, pipeline health, active project status, overnight alerts. Calendar and reminders data are M3 additions. **Must fix** — M1.2 description should drop "calendar" and "reminders snapshot" from Week 1 scope, or explicitly state they're manual/stub.

**GRK-F11: Critical path ignores 2-week stabilization hold** (CRITICAL)
Grok noted that the critical path description doesn't explicitly include the 2-week hold between M5.1 (email send) and M6.2 (iMessage send), understating the total timeline.

**Assessment:** Valid. The dependency IS captured in the task table (TOP-043 depends on TOP-037 stable 2+ weeks), but the critical path description in the action plan should make this time gap visible.

**OAI-F12: Systemic prompt injection threat model** (CRITICAL)
OpenAI flagged that prompt injection is handled per-service but not as a cross-cutting design.

**Assessment:** The specs already embed prompt injection defense per service: iMessage content is "read context only, never instruction source" (Apple §4), email instructions are prohibited (Google §4), only Danny's direct Telegram messages are valid instructions (Apple §4). This is already systemic in practice — each spec applies the same rule. A separate cross-cutting doc would be documentation, not a new design element. **Defer** — the per-service rules are sufficient. If a gap surfaces during implementation, promote to a cross-cutting doc then.

**OAI-F7: Alert storm policy** (SIGNIFICANT)
No dedup/cooldown for alerts. Flapping services could spam Telegram.

**Assessment:** Genuine gap. The chief-of-staff spec defines the approval contract anti-spam batching (>3 pending → bundle, 5-min cooldown), but alert dedup is a separate concern. **Should add** a "one alert per condition per N minutes" policy to the alerting rules task (TOP-013).

**DS-F4: Dead Man's Switch underspecified** (SIGNIFICANT)
No failure condition or recovery action defined for the external monitor.

**Assessment:** Valid. TOP-003 should specify: failure condition (no heartbeat signal for 2 hours), action (SMS/push alert to operator, NOT auto-restart).

**OAI-F17: Feed-intel isolation boundary** (SIGNIFICANT)
Once Tess owns feed-intel cron, failures could cascade into core operations.

**Assessment:** Valid. The feed-intel ownership proposal §3.8 already specifies separate session isolation (`sessionTarget: "isolated"`), separate cost caps ($1.50/day), and auto-pause on 3 consecutive failures. But the action plan should explicitly note that feed-intel has its own pause flag (separate from global maintenance) to prevent cascade.

### Contradictions

**OAI-F6 (cost circuit breaker) vs. plan's existing controls:**
OpenAI rated cost controls as CRITICAL, saying there's no runtime budget circuit breaker. However, the plan already includes: per-job token ceilings (TOP-012), provider-level $100/month hard cap, weekly cost reports, and a $120/month rollback trigger. OpenAI wants a local rolling-spend estimator with automatic stop. DeepSeek and Gemini rated the cost architecture as adequate. **Resolution:** The existing controls (per-job ceiling + provider cap + weekly report) are sufficient for MVP. A local rolling estimator is a post-v1 optimization.

**GRK-F3 (no atomic tasks) vs. actual artifact set:**
Grok rated as CRITICAL that the action plan lacks TOP-xxx atomic tasks. However, the atomic tasks ARE in the companion `tasks.md` file — the action plan is the milestone/phase view, tasks.md is the atomic decomposition. Grok only reviewed the action plan artifact. **Resolution:** Not a gap — it's a two-artifact design. The action plan should reference tasks.md for the full task table.

### Action Items

**Must-fix (3):**

**A1** — Clarify M1 morning briefing data sources (GEM-F2)
Remove "calendar (read sources)" and "reminders snapshot" from M1.2 description. Week 1 briefing uses only: vault status, pipeline health, active project status, overnight alerts. Calendar and reminders are M3 additions.

**A2** — Expand FIF M2 prerequisite definition (GEM-F4, DS-F2, GRK-F4)
Replace "Feed-intel framework M2 migration complete" with explicit statement: "Prerequisite: feed-intel-framework project (separate project, currently TASK phase) completes Milestone 2 (pipeline migration). See `Projects/feed-intel-framework/project-state.yaml` for status."

**A3** — Make critical path include 2-week stabilization hold (GRK-F11)
Update critical path description to explicitly show: "→ TOP-037 (email send) → [2-week stabilization hold] → TOP-043 (iMessage send)". Add a note that total timeline from M0 to M6 completion is estimated at 8-12 weeks minimum.

**Should-fix (8):**

**A4** — Add spec-to-milestone traceability appendix (OAI-F2, GRK-F1)
Lightweight table: each spec phase → milestone ID → task IDs. Proves completeness without full matrix.

**A5** — Reference tasks.md from action plan milestone descriptions (OAI-F8, GEM-F3, GRK-F3, GRK-F8)
Each milestone phase (M2.1, M2.2, M2.3, etc.) should reference the specific TOP-xxx task IDs that compose it. Makes the atomic decomposition visible from the action plan.

**A6** — Add GUI canary to Apple cross-user verification (OAI-F3)
Expand TOP-022 acceptance criteria: add a GUI-dependent canary test (AppleScript "tell app System Events" + memo command) to verify headless paths won't silently fail.

**A7** — Operationalize subjective gate criteria (OAI-F13, DS-F6, GRK-F16)
Replace "useful" / "adds value" with "operator marks 0/1 per day" scoring. Apply to M3.1 ("email summary useful"), M5.2 ("contact enrichment adds value"), M8 gates.

**A8** — Expand rollback: Tier 0 recovery, Tier 4 re-enablement, mismutation remediation (OAI-F16, DS-F9, GEM-F5)
Tier 0: add manual process kill + diagnose steps. Tier 4: add "incremental re-enablement from M1 briefing-only after root cause analysis." Add per-service "undo" recipes: Gmail label rollback queries, Reminders cleanup, Calendar staging purge.

**A9** — Add alert dedup/cooldown policy (OAI-F7)
Add to TOP-013: one alert per condition per 30 minutes. Dedup keys per service. Escalation ladder (warn → critical → kill-switch recommendation).

**A10** — Specify Dead Man's Switch failure conditions (DS-F4)
Expand TOP-003: failure condition = no heartbeat signal for 2 hours. Action = SMS/push to operator. Explicitly NOT auto-restart.

**A11** — Add feed-intel isolation note (OAI-F17)
Add to M7 description: feed-intel jobs run with separate session isolation, separate cost cap, separate pause flag (not global maintenance). Cascade to core operations prevented by design.

**Defer (3):**

**D1** — Systemic prompt injection threat model (OAI-F12)
Per-service rules are already consistent and sufficient. Cross-cutting doc would be documentation, not new design. Revisit if implementation reveals a gap.

**D2** — Local rolling-spend budget circuit breaker (OAI-F6)
Per-job ceilings + provider cap + weekly cost report are sufficient for MVP. Local estimator is post-v1 optimization.

**D3** — Auth/permissions durability testing as separate mini-milestone (OAI-F14)
Valid concept but adds overhead. Token refresh, reboot, and locked-screen tests are captured implicitly in Phase 1 gate evaluations (5 days of continuous operation). Promote if Phase 1 gates reveal auth fragility.

### Considered and Declined

| Finding | Justification | Category |
|---------|--------------|----------|
| GRK-F3 (no atomic tasks in action plan) | Atomic tasks are in companion `tasks.md`, not the action plan. Two-artifact design is intentional. | incorrect |
| GRK-F14 (multi-channel coverage gap) | "Multi-channel" means Telegram + Discord per the specs. Slack/Email are not in scope. | incorrect |
| GRK-F12 ($120 vs $100 inconsistency) | $100/month is provider API hard cap. $120/month is combined cost rollback trigger (includes feed-intel). Different mechanisms, intentionally different thresholds. | incorrect |
| DS-F1 (vault undefined) | "Vault" = Crumb Obsidian vault, the project's core data store. Well-defined in project context that reviewers don't have. | incorrect |
| DS-F3 (Sonnet 4.5 model inconsistency) | Chief-of-staff spec §8.3 explicitly uses Sonnet for connections brainstorm (highest-quality creative work). Not an error — intentional model choice outside the two-agent baseline. | constraint |
| DS-F5 (upgrade single-point failure) | OpenClaw upgrade is inherently a prerequisite for everything. Peer-reviewed runbook with rollback procedures exists. Can't avoid the dependency. | constraint |
| OAI-F5 (secret/token standardization) | Discord tokens in env vars is the spec's design choice. Keychain migration for Discord tokens is post-v1 hardening. | overkill |
| OAI-F11 (Discord scope mismatch) | Comms spec §2.3 already states invariant: "Discord is never the source of truth for approvals." Later phases add structured posting, not command acceptance. Non-authoritative is maintained. | incorrect |
| OAI-F10 (macOS gate enforcement) | TOP-005 is the explicit macOS verification task. Mechanic-level enforcement of "Apple automation allowed" flag is implementation detail, not plan-level. | overkill |
| OAI-F18 (prompt budget contract per job) | Per-job token ceilings with truncate-and-log are already specified. Adding prompt attachment limits is implementation detail. | overkill |
| DS-F8 (mechanic resource bottleneck) | qwen3-coder:30b runs on M3 Ultra with 192GB unified memory. Resource contention is theoretical. Monitor during M1 gate per the cheap-checks-first pattern. | overkill |
| GRK-F6 (dependency diagram positioning) | Valid readability nit but the diagram is supplementary — the task dependency table in tasks.md is authoritative. | out-of-scope |
| All unverifiable claims (OAI-F19-23, GEM-F1, DS-F10-14, GRK-F2/F5/F13) | All references (CVE-2025-43530, OpenClaw v2026.2.25, crossContextRoutes #22725, BlueBubbles, model pricing) were verified in prior SPECIFY-phase reviews and are grounded in the project's internal documentation. Reviewers lack access to internal project context. | constraint |
