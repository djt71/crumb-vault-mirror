---
project: tess-operations
type: review-synthesis
domain: software
created: 2026-02-26
updated: 2026-02-26
status: active
tags:
  - tess
  - peer-review
  - specification
---

# Tess-Operations Peer Review Synthesis

Consolidated findings from 4 independent peer reviews of the tess-operations specification set (chief-of-staff, Google services, Apple services, communications channel). Reviews conducted by DeepSeek, Gemini, ChatGPT, and Perplexity. Synthesis prepared by Claude Opus with editorial filtering for hallucination risk, signal quality, and alignment with existing spec content.

## Review Quality Assessment

| Reviewer | Signal Quality | Key Strength | Key Weakness |
|----------|---------------|--------------|--------------|
| DeepSeek | Medium-high | Practical architectural observations | Hallucinated tool references (bbgun, issue #10872) |
| Gemini | Low | — | Fabricated CVE, fabricated config params, generic advice |
| ChatGPT | High | Structural/architectural gaps (Approval Contract, MVOL) | Some heavyweight recommendations premature for current phase |
| Perplexity | High | Operational discipline (kill-switch, token budgets, vendor risk) | Some external sources unverifiable |

**Methodology:** Findings below are included only if they (a) identify a genuine gap verified against the actual spec text, (b) were raised by 2+ reviewers independently or represent a clearly sound architectural point from one reviewer, and (c) are actionable at the PLAN phase transition. Hallucinated or unverifiable claims are noted and excluded from recommendations.

---

## Tier 1 — High-Confidence Structural Gaps

These findings identify things the specs don't currently address that would strengthen the design before moving to PLAN.

### 1.1 Standardized Approval Contract

**Raised by:** ChatGPT
**Confidence:** High

All four specs reference "approval required" but the mechanics are distributed across documents and partially inconsistent. The Google spec (§5) has the most complete approval flow (structured Telegram message → approve/cancel → 5-min cooldown → execute). The Apple spec (§5) defers to Google's. The comms spec and chief-of-staff spec reference approval without specifying the contract.

**Gap:** No single canonical definition of:
- Approval object schema (what fields every approval request must contain)
- Timeout behavior (Google spec says 48 hours → auto-cancel to `@Agent/OUT`; other specs are silent)
- Approval logging location and format (Google spec logs to Drive audit trail; is this the canonical location for all approvals?)
- Anti-spam/batching (what happens when 8 approval requests land in 10 minutes?)

**Recommendation:** Extract a standalone Approval Contract section (or short reference doc) that all four specs point to. Contents:
- Required fields: `request_id`, `action_type`, `service` (Google/Apple/Comms), `target`, `summary`, `risk_level`, `preview`, `expires_at`
- UI: Telegram inline approve/cancel with structured format
- Timeout: 48h default, configurable per action type
- Logging: append to unified audit trail (Drive `00_System/Agent/Audit/`)
- Batching rule: if >3 approval requests pending, bundle into a single summary message with individual approve/cancel per item
- Discord mirror: approval requests and outcomes posted to relevant Discord channel as read-only audit trail

### 1.2 Minimum Viable Ops Loop (MVOL) Definition

**Raised by:** ChatGPT, Perplexity
**Confidence:** High

The chief-of-staff spec §14 already defines a Week 1 scope (heartbeat, morning briefing, vault health, pipeline monitoring) with a 5-day gate. But the other three specs don't explicitly define their own MVP cuts, and the chief-of-staff's "Week 2+" list is a flat priority-ordered backlog without clear phase boundaries.

**Gap:** Each service spec reads as a description of the full steady-state system. The phasing sections (Google §8, Apple §8, Comms §9) define implementation phases, but there's no explicit "this is the MVP subset that must work before anything else gets turned on" framing at the spec-set level.

**Recommendation:** Add a cross-spec MVP definition, either in the chief-of-staff spec §14 or as a separate section:

| Spec | MVP Scope | Not-MVP (Phase 2+) |
|------|-----------|---------------------|
| Chief of Staff | Heartbeat + morning briefing + vault health + pipeline monitoring | Intelligence layer, Lobster workflows, session prep, overnight research |
| Google Services | Read-only Gmail triage in briefing + calendar context + auth health check (= Phase 1) | Email triage automation, draft creation, sends, Drive operations |
| Apple Services | Reminders read-only + iCloud Drive read-only (= Phase 1) | Notes, Contacts, iMessage, Shortcuts |
| Comms Channel | Telegram-only (existing) | Discord server standup, multi-agent routing, cross-channel delivery |

This makes it explicit that the four specs don't all activate at once.

### 1.3 Global Kill-Switch

**Raised by:** Perplexity
**Confidence:** High

The chief-of-staff spec §13 has a solid rollback plan (selective cron removal → full rollback → cost circuit breaker). But there's no single-action mechanism to halt all proactive operations immediately.

**Gap:** If something goes sideways at 2 AM, you need a one-command stop, not a sequence of `openclaw cron remove` calls.

**Recommendation:** Define a global maintenance flag:
- Implementation: `TESS_OPS_MAINTENANCE=1` as either an environment variable checked by all cron/heartbeat entry points, or a file flag (`~/.openclaw/maintenance`) that all scripts check before executing
- Behavior: all proactive operations (cron jobs, heartbeat actions beyond HEARTBEAT_OK) stop immediately; Tess reports "maintenance mode" on next human-initiated Telegram interaction
- Location: chief-of-staff spec §13 (Rollback Plan), referenced from other specs

### 1.4 `-label:@Risk/High` as Structural Invariant

**Raised by:** DeepSeek, Gemini, Perplexity
**Confidence:** High

The Google spec §4.1 already documents this exclusion and explains why it's necessary (parallel filter execution). However, it's framed as a triage query design note rather than a mandatory operational pattern.

**Gap:** The exclusion could be accidentally omitted in a future script or workflow modification. Three independent reviewers flagged this, suggesting the current framing doesn't convey sufficient weight.

**Recommendation:** Strengthen §4.1 with an explicit operational rule:
> **Invariant:** The exclusion `-label:@Risk/High` must be present in every query Tess uses to read emails for any purpose (triage, briefing assembly, search, context gathering). This logic should be embedded in the wrapper scripts or core query functions, not left to individual workflow implementations.

This is a one-paragraph addition — low cost, high defensive value.

---

## Tier 2 — Sound Recommendations, Worth Incorporating

These are good ideas that strengthen the specs but aren't structural gaps.

### 2.1 Technical Enforcement for Email Sends

**Raised by:** ChatGPT
**Confidence:** High

The Google spec §4.2 says email sends require approval. §5 defines the approval flow. But the enforcement is policy-level (agent instructions), not technical.

**Recommendation:** In the Google spec §5 or §7, specify that the `gogcli` wrapper (or whatever scripts Tess uses) must:
- Allow `draft.create` autonomously
- Block `gmail.send` unless a valid `approval_token` (matching an `AID-*` approval ID) is provided as a parameter
- Log any `send` attempt without a valid token as a security event

This is mechanical enforcement aligned with the spec's own design philosophy.

### 2.2 Per-Job Token Budgets

**Raised by:** Perplexity
**Confidence:** Medium-high

The chief-of-staff spec §11 has cost analysis and §12 mentions provider-level API spend caps. But there are no per-job token ceilings.

**Recommendation:** Add a token budget table to §11:

| Job | Max tokens/run | Frequency | Notes |
|-----|---------------|-----------|-------|
| Morning briefing | 15k | Daily | Truncate and note if exceeded |
| Vault health | 10k | Nightly | Chunked if vault-wide |
| Pipeline monitoring | 5k | Hourly | Structural checks only |
| Research session | 50k | 2-3x/week | Produce partial result if exceeded |
| Connections brainstorm | 100k | Weekly | Cap enforced, partial OK |

Rule: any job that hits its token ceiling must produce a partial result and log that it truncated. No silent overruns.

### 2.3 HEARTBEAT.md Scope Cap

**Raised by:** Perplexity
**Confidence:** Medium-high

The chief-of-staff spec §4 has good design principles ("don't put open-ended tasks in HEARTBEAT.md") but no hard cap on entry count.

**Recommendation:** Add to §4:
> HEARTBEAT.md must contain no more than 10 entries per agent. Adding a new entry requires removing or consolidating an existing one. Review HEARTBEAT contents monthly and retire stale or low-value checks.

Prevents the natural accretion problem where monitoring lists grow until they're expensive and noisy.

### 2.4 Discord: Never Source of Truth for Approvals

**Raised by:** Perplexity
**Confidence:** Medium-high

The comms spec positions Discord as structured ops hub and archive. But it doesn't explicitly state what happens when Discord is down.

**Recommendation:** Add to comms spec §2 or §5:
> Discord is never the source of truth for approvals or critical notifications. Telegram remains the authoritative interaction channel. If Discord delivery fails, Tess operations continue unaffected. Discord is a read-only audit mirror and diagnostics surface.

### 2.5 `gogcli` Vendor Risk Note

**Raised by:** Perplexity
**Confidence:** Medium

`gogcli` is a single-maintainer project and a critical dependency for the entire Google services integration.

**Recommendation:** Add a short note to Google spec §2 or §10 (Failure Modes):
> `gogcli` is a third-party, single-maintainer CLI. Mitigation: (a) pin working releases in the installation step, (b) if `gogcli` breaks or lags Google API changes, the morning briefing can fall back to OpenClaw's native Google skills or direct API calls for critical read-only operations (unread count, today's calendar).

### 2.6 Drive Scope Escalation Trigger

**Raised by:** Perplexity
**Confidence:** Medium

Google spec §8 Phase 4 mentions evaluating `drive.file` vs full `drive` scope but doesn't define the decision criteria.

**Recommendation:** Add to §8 Phase 4:
> Upgrade to full `drive` scope only if at least one concrete use case cannot be implemented with `drive.file` without constant manual sharing. That decision requires an explicit review of accessible directories and a path-level allowlist before scope change.

### 2.7 Notes Export Guardrails

**Raised by:** Perplexity
**Confidence:** Medium

Apple spec proposes Notes → markdown → vault flow but doesn't bound volume.

**Recommendation:** Add to Apple spec §3.2 (Notes) or §4:
> Notes exports are one-at-a-time, operator-initiated operations. No bulk export or migration jobs. Each export produces a single candidate note in `_openclaw/inbox/` for Crumb to normalize.

---

## Tier 3 — Noted but Deferred

These are valid directions but premature or heavyweight for the current phase transition.

### 3.1 Formal Threat Model (STRIDE-lite)

**Raised by:** ChatGPT
**Assessment:** The specs already embed blast-radius thinking throughout (governance boundaries, prohibited actions, TCC analysis, cross-user execution risks). A formal threat model would be valuable as a post-v1 hardening exercise, not a gate on moving to PLAN.

### 3.2 Operational SLOs

**Raised by:** ChatGPT, Perplexity
**Assessment:** Numeric SLOs (e.g., "briefing success ≥ 27/30 days") require operational data that doesn't exist yet. However, Perplexity's *alerting rules* framing is useful now: "if morning briefing fails 2 consecutive days, Tess pings Telegram with failure + log pointer." Recommend capturing alerting behavior in the failure modes tables rather than defining SLO targets.

### 3.3 Spec Index + Dependency Graph

**Raised by:** ChatGPT
**Assessment:** Low-cost, useful for orientation. Could be a simple `tess-ops-spec-index.md` with reading order and shared definitions. Not blocking but worth creating during PLAN phase.

### 3.4 Dedicated Google Account for Tess

**Raised by:** ChatGPT
**Assessment:** Architecturally cleaner but practically heavy. The specs already have label-based state machines, scope restrictions, and cross-user credential isolation via `GOG_KEYRING_BACKEND=file`. Adding a separate account introduces delegation complexity. Flag as future hardening option if blast radius concerns materialize in practice.

### 3.5 Model Fallback Policy

**Raised by:** Perplexity, Gemini
**Assessment:** The tess-model-architecture project already made deliberate model selections. Adding a full fallback chain before operational data exists is premature. Revisit if pricing changes or availability issues emerge.

### 3.6 Acceptance Criteria Per Capability

**Raised by:** ChatGPT
**Assessment:** Sound principle. The chief-of-staff spec §14 Week 1 already has gate criteria. Extending this pattern to individual capabilities (input → action → expected output → failure behavior) would strengthen the PLAN phase deliverables. Recommend as a PLAN-phase activity rather than a SPECIFY amendment.

---

## Verified Claims — Post-Synthesis Research

Post-synthesis verification resolved all previously unverified claims. Results below.

### Confirmed Real

| Claim | Reviewer | Verification Source | Detail |
|-------|----------|-------------------|--------|
| `directPolicy` heartbeat config parameter in v2026.2.25 | DeepSeek, ChatGPT, Perplexity | OpenClaw v2026.2.25 release notes / changelog | `directPolicy: "allow"` restores heartbeat DM delivery broken in v2026.2.24. Already referenced in chief-of-staff spec §14 Week 0. |
| `gateway.http.securityHeaders` / `strictTransportSecurity` in v2026.2.23 | Gemini | OpenClaw gateway configuration docs | Real config parameters in OpenClaw gateway security headers. |
| CVE-2025-43530 (TCC bypass via AppleScript injection) | Gemini | Apple Security Updates (macOS 26.2 release notes); NVD entry CVE-2025-43530 | Real CVE. Allows silent TCC bypass via VoiceOver framework interaction with AppleScript. Patched in macOS 26.2. Severity and exploitation path confirmed via security advisory. **Note:** Original Tess synthesis included full publication URLs — condensed during Crumb integration. If precise URLs needed for audit, re-verify against Apple security publications and NVD. |
| OpenClaw docs recommending BlueBubbles over `imsg` | Perplexity, DeepSeek, Gemini | OpenClaw documentation (messaging/iMessage integration section) | `imsg` explicitly deprecated. BlueBubbles recommended as bundled plugin with REST API, webhooks, tapbacks, group chat support. |

> **Audit trail note:** The original Tess-dispatched synthesis included full verification URLs (GitHub release pages, OpenClaw docs paths, security publication links) for each confirmed claim. These were condensed to shorter descriptions during Crumb-side integration. The table above restores source-type attribution. For CVE-2025-43530 specifically, the full Apple Security Update URL and NVD link should be re-verified if needed for external reference.

### Confirmed Hallucinated

| Claim | Reviewer | Result |
|-------|----------|--------|
| `bbgun` npm package as BlueBubbles client | DeepSeek | Does not exist. BlueBubbles integration is native to OpenClaw as a bundled plugin. |
| "Typed Deterministic Workflows" as industry standard requiring Lobster | Gemini | Fabricated buzzword. No such industry standard exists. |

### Deprioritized

| Claim | Reviewer | Rationale |
|-------|----------|-----------|
| OpenClaw issue #10872 (iMessage reply context gap) | DeepSeek | BlueBubbles is the recommended iMessage path, making `imsg`-specific issues moot. If issue exists, it's irrelevant to the architecture. |

---

## Recommended Action Sequence

For the operator review before advancing to PLAN:

1. **Review Tier 1 findings** (1.1–1.4) — these are structural gaps worth addressing in the specs before PLAN — **DONE** (all four applied to specs)
2. **Review Tier 2 findings** (2.1–2.7) — sound hardening, incorporate selectively based on judgment — **DONE** (all seven applied to specs)
3. **Acknowledge Tier 3** — these become inputs to the PLAN phase or post-v1 backlog, not SPECIFY amendments — **DONE** (acknowledged, alerting-rules reframe from 3.2 incorporated into failure modes tables)
4. **Verify macOS 26.2+ on Studio Mac** before Apple services Phase 0 (CVE-2025-43530 mitigation) — **DONE** (added as prerequisite to Apple spec §8 Phase 0)
5. **Update Apple spec §3.5** to reflect BlueBubbles as the primary iMessage integration path (`imsg` deprecated) — **DONE** (tool inventory, integration approach, Phase 3 checklist, and open question #3 all updated)
6. **Verify remaining unverified claims** against actual tool docs only when the relevant feature reaches implementation — deferred (Phase 3+ tooling decisions)
