---
project: tess-operations
type: review-synthesis
domain: software
created: 2026-02-27
updated: 2026-02-27
status: active
tags:
  - tess
  - peer-review
  - action-plan
  - tasks
---

# Action Plan & Task List — Peer Review Synthesis

Consolidated findings from 4 independent peer reviews of `action-plan.md` and `tasks.md`, plus an independent review by the synthesis author. Reviews conducted by DeepSeek, Gemini, ChatGPT, and Perplexity. Synthesis prepared by Claude Opus with editorial filtering for signal quality, redundancy with already-resolved items, and alignment with the current (post-amendment) spec state.

## Overall Assessment

All four reviewers endorse the plan as implementable. The milestone structure, gate-based progression, risk-aware sequencing, and rollback tiers are unanimously praised. The disagreements are on implementation details, missing tasks, and operational tightening — not on structure or direction.

## Review Quality Assessment

| Reviewer | Signal Quality | Key Strength | Key Weakness |
|----------|---------------|--------------|--------------|
| DeepSeek | Medium | Feed-intel parallel run verification, credential access catch | 3 of 5 "gaps" were already resolved in post-amendment specs; reviewing stale state |
| Gemini | Low | — | Pure summary of the plan with no new findings; every point restates existing content |
| ChatGPT | High | Approval Contract as missing deliverable, measurement harness, sudoers security, "protocol layer" framing | Voice heartbeat recommendation is better as Week 1 calibration than upfront change |
| Perplexity | High | Gate log standardization, max parallel streams cap, email denylist, Drive risk review | Task mapping appendix is nice-to-have, not essential |

---

## Tier 1 — Address Before Implementation Begins

### 1.1 Approval Contract as First-Class Task

**Raised by:** Claude Opus (independent review), ChatGPT
**Gap:** The plan repeatedly references "approval contract integration" as a dependency for Phase 2+ write operations (email triage, calendar staging, email send, iMessage send), but no task defines or implements the approval contract itself. It's treated as policy scattered across consuming tasks, creating a risk that each task implements its own approval flow slightly differently.

**Recommended change:** Add a new task (e.g., TOP-002a or insert between M0 and M1) that implements the Approval Contract as a protocol:

- Define schema: `approval_id` (AID-*), `action_type`, `service`, `target`, `summary`, `original_context`, `risk_level`, `preview`, `expires_at`
- Implement Telegram approve/deny UI (inline buttons per comms spec §5.2)
- Implement Discord #approvals mirror with message ID correlation
- Implement wrapper enforcement hooks (the AID-* token gate that TOP-037/TOP-043 depend on)
- Acceptance tests: approve path, deny path, expiry path (48h), retry path, anti-spam batching (>3 pending → bundle), 5-min cooldown, logging/audit trail

This should be complete before any Phase 2 task begins. All consuming tasks (TOP-031, TOP-032, TOP-036, TOP-037, TOP-043) should declare a dependency on it.

### 1.2 Measurement Harness for Gate Criteria

**Raised by:** ChatGPT
**Gap:** Gate criteria include specific numeric thresholds ("false-positive rate <25%", "cost ≤$3/day averaged over 5 days", "wrapper success ≥95%") but no mechanism to produce those numbers reliably. Without a structured log and report generator, gate evaluations become subjective.

**Recommended change:** Add an "Ops Metrics v1" task in M0 or early M1:

- Append-only run log with: `job_id`, `start_time`, `end_time`, `status`, `tokens_in`, `tokens_out`, `tool_calls`, `exit_code`, `alert_emitted`, `cost_estimate`
- Simple weekly report generator (script or cron job) that aggregates: daily cost, alert count, false-positive count, job success rate
- Gate evaluation tasks (TOP-014, TOP-030, TOP-035, TOP-041) updated to require "metrics evidence bundle" — a single markdown report per gate with computed values against thresholds

This makes gates evidence-based, not subjective.

### 1.3 Gate Log Standardization

**Raised by:** Perplexity
**Gap:** Every gate section says "Run 5-day evaluations. Log results." but doesn't define where results go, what format they take, or what happens on failure beyond the generic policy.

**Recommended change:**

- Define standardized gate log location: `_openclaw/state/gates/<milestone>-<YYYY-MM-DD>.md`
- Define gate log format: date range, metrics computed (from §1.2 harness), pass/fail per criterion, overall determination, and — critically — if any criterion fails: **specific hypothesis for the failure and next experiment** to address it
- Restate gate thresholds directly in each gate section (M3.4, M4.4, M5.4) rather than only at the milestone header. This prevents skipping gates under time pressure.

### 1.4 Sudoers Binary Scoping

**Raised by:** ChatGPT
**Gap:** TOP-019 allows `cp` and `cat` in the sudoers entry for `openclaw → danny`. Both are security footguns: `cp` enables copying arbitrary files as Danny if arguments aren't tightly controlled; `cat` enables reading any file Danny owns.

**Recommended change:**

- Remove `cp` and `cat` from the allowed binaries list unless there is a specific, documented, audited use case
- If `cat` is needed for reading specific files (e.g., config files), replace with a wrapper that reads only from an allowlisted set of paths
- Pin all allowed binaries to absolute paths (e.g., `/opt/homebrew/bin/remindctl`, not just `remindctl`)
- Update TOP-019 acceptance criteria: "`sudo -l -U openclaw` shows exactly the scoped binary list with absolute paths; no `cp`, no `cat` unless justified in design doc"

### 1.5 M7 Dependency Graph Correction

**Raised by:** Claude Opus (independent review)
**Gap:** The visual dependency graph shows M7 (feed-intel ownership) hanging off M4 (Phase 2s). But the action plan text, the feed-intel ownership proposal, and the task table all agree that M7's prerequisite is only the Week 1 gate (M1) plus feed-intel framework M2 migration being complete. M7 should not wait for Google/Apple/Discord Phase 2 completion.

**Recommended change:** Fix the dependency graph:

```
M0 ──→ M1 ──→ M2 (parallel: M2.1, M2.2, M2.3)
                │
                ├──→ M3 (parallel: M3.1, M3.2, M3.3)
                │     │
                │     ├──→ M4 (parallel: M4.1, M4.2, M4.3)
                │     │     │
                │     │     ├──→ M5 (parallel: M5.1, M5.2, M5.3)
                │     │     │     │
                │     │     │     ├──→ M6.1 (Drive)
                │     │     │     └──→ M6.2 (iMessage send — requires M5.1 stable 2+ weeks)
                │     │     │
                │     │
                ├──→ M7 (feed-intel — requires M1 gate + FIF M2 complete)
                │
                └──→ M8 (intelligence — parallel with M3+, full effectiveness at M5.2)
```

Feed-intel Phase A (monitoring, TOP-044) can start immediately after the M1 gate passes. It's independent of the Google/Apple/Discord track.

### 1.6 Cron Guardrails as First-Class Task

**Raised by:** Claude Opus (independent review), ChatGPT
**Gap:** The feed-intel ownership proposal has detailed cron guardrails (§3.8), but the generic cron infrastructure that all jobs should use (single-flight lock, max runtime + kill policy, jitter) isn't a discrete task. It's currently scattered as prose across multiple spec sections.

**Recommended change:** Add a task in M0 or early M1:

- Implement single-flight lock mechanism (file lock or equivalent) — shared by all cron jobs
- Define max wall time per job type with automatic kill
- Define missed-run behavior (run on wake if within N hours, skip if older)
- This task becomes a dependency for all cron job tasks (TOP-009, TOP-010, TOP-011, TOP-044, TOP-045)

---

## Tier 2 — Incorporate Into the Plan

### 2.1 TOP-009 Scoping (Morning Briefing)

**Raised by:** Claude Opus (independent review)
**Issue:** TOP-009 description includes "calendar (read sources), reminders snapshot" but those aren't available until M3 (Phase 1 read-only integration). In Week 1, the morning briefing should only include vault status, pipeline health, project status, and overnight alerts.

**Fix:** Update TOP-009 description and acceptance criteria to reflect Week 1 available data. TOP-027 and TOP-028 already handle adding Google/Apple data — this is a description cleanup.

### 2.2 TOP-012 Dependency Direction

**Raised by:** Claude Opus (independent review)
**Issue:** TOP-012 (per-job token budgets) depends on TOP-009/010/011, but token budgets should be in place *before* or *alongside* the jobs they're budgeting. Without them, there's a window where overruns aren't caught.

**Fix:** Remove TOP-012's dependency on TOP-009/010/011. Make TOP-012 a dependency *of* those tasks, or make them concurrent. Budget enforcement should be infrastructure, not an afterthought.

### 2.3 Feed-Intel Parallel Run Verification

**Raised by:** DeepSeek
**Issue:** The feed-intel ownership proposal explicitly calls for a 3-day parallel run (launchd + cron) before cutover. Neither the action plan nor the task list includes this as a discrete step. TOP-045 jumps straight to full ownership.

**Fix:** Add a subtask between TOP-044 (monitoring) and TOP-045 (full ownership):

- Run feed-intel capture/attention via both launchd and OpenClaw cron for 3 days
- Compare outputs for parity; if discrepancies >5%, pause and debug
- Only after parity is confirmed does TOP-045 (full ownership transfer) proceed

### 2.4 Max Parallel Streams Cap

**Raised by:** Perplexity
**Issue:** The plan allows all three service families (Google, Apple, Comms) to advance through phases simultaneously. For a solo practitioner with 25 active customer accounts, this risks cognitive overload and quality degradation.

**Fix:** Add a governance rule to the action plan: "Never advance more than two service families a phase at a time." Phase 0 setup (M2) can run all three in parallel because it's infrastructure plumbing. But Phase 1+ operational work should be capped at two concurrent streams.

### 2.5 Email Send Domain Denylist

**Raised by:** Perplexity
**Issue:** TOP-037 (email send) has rate limits and approval gating, but no denylist to prevent worst-case errors (sending to bank/government addresses, cold outreach domains).

**Fix:** Add to TOP-037 acceptance criteria: "Hard-coded domain denylist active for first 3 months. Denylist includes: government domains, financial institution domains, and any domain not in existing contact history. Send to denylisted domain → blocked + alert, even with valid approval."

### 2.6 Drive Scope Written Risk Review

**Raised by:** Perplexity
**Issue:** TOP-042 (Drive scope decision) has "only upgrade if concrete use case requires it" and "path-level allowlist before scope change," but no explicit risk review step.

**Fix:** Add to TOP-042 acceptance criteria: "Written risk review completed before scope upgrade. Review covers: spoofed email attachment risk, data exfiltration paths, vault scope boundaries, and rollback plan. Review filed in run-log."

### 2.7 Anticipatory Session Task

**Raised by:** Claude Opus (independent review)
**Issue:** The chief-of-staff spec §14 now has Anticipatory Session as item #5 in Week 2+ (promoted from frontier ideas per peer review synthesis). But no task implements it. TOP-047 (session prep/debrief) is related but doesn't reference the specific schema (required sections, max 2000 tokens, wikilink conventions, output path).

**Fix:** Either update TOP-047 to reference the Anticipatory Session schema from §14, or add a new task specifically for it. The schema is defined: `current_phase`, `next_task`, `blockers`, `recent_dispatch_results`, `relevant_feed_intel`, `vault_check_status`, `suggested_first_command`.

### 2.8 Runbook Retargeting Task

**Raised by:** Claude Opus (independent review)
**Issue:** TOP-001 references a "peer-reviewed runbook" but that runbook targets v2026.2.24. The upgrade is to v2026.2.25, which has breaking changes (directPolicy default flip, branding from `bot.molt` to `ai.openclaw`, new security hardening).

**Fix:** Add a subtask or note to TOP-001: "Review v2026.2.25 changelog delta vs v2026.2.24 runbook. Verify breaking changes are addressed: directPolicy default, branding migration, safeBinTrustedDirs config."

---

## Tier 3 — Note for Implementation Phase

### 3.1 Voice Heartbeat Frequency Calibration

**Raised by:** ChatGPT
**Note:** 30-minute voice heartbeat for 15 hours/day may be wasteful. Consider making voice mostly escalation-driven (mechanic does 80-90% of checks, voice wakes on alert/briefing/signal-detected). Better as a Week 1 calibration item based on actual cost data than an upfront plan change.

### 3.2 Discord Canary in Phase 0

**Raised by:** ChatGPT
**Note:** Move the Discord canary health check into M2.3 (Phase 0) rather than waiting for Phase 1 dual delivery. Hourly mechanic canary message + success check catches Discord issues before you depend on it.

### 3.3 Wrapper Enforcement Before Send Capability

**Raised by:** ChatGPT
**Note:** As soon as Gmail write scopes are granted (Phase 2), implement wrapper-level "no send" enforcement *before* the send capability is built. Include negative tests: "attempt send without approval" must be logged and blocked. Prevents accidental sends during development.

### 3.4 iMessage Contacts Constraint

**Raised by:** Perplexity
**Note:** In M6.2, add explicit constraint: "No iMessage sends to numbers not in Contacts. Allowlist entries must match a Contacts record." Prevents sends to typos or stale numbers.

### 3.5 Apple M0.3 Prerequisite in M2.2 Prose

**Raised by:** Perplexity
**Note:** Restate "Prerequisite: M0.3 (macOS 26.2+) verified" in the M2.2 section text, not just in task dependencies. Prevents skipping the OS check under time pressure.

### 3.6 `tess-state.md` Gate Level Field

**Raised by:** Perplexity
**Note:** Add "current gate level" to the tess-state.md schema (e.g., "M1 passed, M3 Google Phase 1 failed on metric X"). Makes incident review and recovery faster.

---

## Recommended Action Sequence

For Crumb to process before implementation begins:

1. **Add Approval Contract task** (§1.1) — first-class protocol deliverable, dependency for all Phase 2+ write tasks
2. **Add Ops Metrics harness task** (§1.2) — run log + report generator, dependency for gate evaluations
3. **Define gate log format and location** (§1.3) — standardized artifacts with failure-requires-hypothesis rule
4. **Review and tighten sudoers binary list** (§1.4) — remove `cp`/`cat` or constrain; pin absolute paths
5. **Fix M7 dependency graph** (§1.5) — feed-intel hangs off M1, not M4
6. **Add cron guardrails infrastructure task** (§1.6) — shared by all cron jobs
7. **Scope TOP-009 to Week 1 data** (§2.1) — no calendar/reminders until M3
8. **Fix TOP-012 dependency direction** (§2.2) — budgets before or concurrent with jobs
9. **Add feed-intel parallel run step** (§2.3) — 3-day verification between monitoring and ownership
10. **Add max parallel streams cap** (§2.4) — ≤2 service families advancing simultaneously
11. **Add email denylist to TOP-037** (§2.5) — domain denylist for first 3 months
12. **Add Drive risk review to TOP-042** (§2.6) — written review before scope upgrade
13. **Add or update Anticipatory Session task** (§2.7) — reference schema from spec §14
14. **Add runbook retargeting note to TOP-001** (§2.8) — v2026.2.24 → v2026.2.25 delta review
