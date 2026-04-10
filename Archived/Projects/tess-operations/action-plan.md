---
project: tess-operations
type: action-plan
domain: software
status: active
created: 2026-02-26
updated: 2026-02-27
skill_origin: action-architect
tags:
  - tess
  - openclaw
  - operations
---

# tess-operations — Action Plan

## Overview

Transform Tess from Telegram relay to active chief-of-staff operator. Four validated specs, phased activation with gate-based progression. Total cost envelope: $34–80/month (chief-of-staff + services), rising to $75–115/month after feed-intel ownership transition.

**Critical path:** Week 0 (upgrade) → Week 1 (chief-of-staff MVP, 3-day gate) → parallel Phase 0s → phased service activation → email send (M5.1) → **[2-week stabilization hold]** → iMessage send (M6.2). Estimated total timeline: 8-12 weeks minimum from M0 start to M6 completion.

**Business Advisor lens:**
- ROI is operational leverage — Tess absorbs monitoring, triage, and briefing work that currently requires manual attention or goes undone
- Cost drivers are LLM inference (Haiku 4.5 voice) and frequency (heartbeat every 30 min). Mechanic (qwen3-coder local) absorbs ~40% of tasks at zero marginal cost
- Kill-switch and per-job token budgets provide cost containment. Provider-level cap at $100/month is the hard ceiling
- Risk is proportional: read-only phases first, write operations gated behind approval contract, iMessage send deferred until email send is proven

---

## M0 — Infrastructure Foundation (Week 0)

**Goal:** Upgrade OpenClaw and establish the infrastructure prerequisites that all subsequent milestones depend on.

**Success criteria:**
- OpenClaw v2026.2.25 running stable on Studio Mac
- Global kill-switch operational
- Dead Man's Switch monitoring both gateway and job-ran signals
- `tess-state.md` operational state file created and populated

### M0.1 — OpenClaw Upgrade (TOP-001)

Upgrade to v2026.2.25 using the peer-reviewed runbook (`Projects/openclaw-colocation/design/upgrade-v2026-2-24.md`, retargeted to v2026.2.25). This is a prerequisite for everything — heartbeat DM delivery, prompt caching, session cleanup, stale-lock recovery, `exec safeBinTrustedDirs`.

### M0.2 — Global Kill-Switch & Dead Man's Switch (TOP-002, TOP-003, TOP-004)

Implement `~/.openclaw/maintenance` file-flag check in all cron/heartbeat entry points. Register Tess's heartbeat with external monitor (Uptime Robot free tier or equivalent). Failure condition: no heartbeat signal for 2 hours. Action: SMS/push alert to operator (NOT auto-restart — operator diagnoses first). Create `_openclaw/state/tess-state.md` with last-known-good state, active cron jobs, last heartbeat time, critical system status.

### M0.3 — macOS Version Verification (TOP-005)

Verify Studio Mac is running macOS 26.2+ (`sw_vers`). CVE-2025-43530 (TCC bypass via AppleScript/VoiceOver) must be patched before any Apple services TCC grants. This is a checkpoint, not implementation work — but it gates Apple Phase 0.

### M0.4 — Ops Metrics v1 Harness (TOP-050)

Append-only structured run log for all cron jobs (`job_id`, `start_time`, `end_time`, `status`, `tokens_in/out`, `cost_estimate`). Simple weekly report generator aggregating daily cost, alert count, false-positive rate, job success rate. Gate evaluations (TOP-014, TOP-030, TOP-035, TOP-041) require a "metrics evidence bundle" — computed values against thresholds. Without this, gates are subjective.

### M0.5 — Cron Guardrails Infrastructure (TOP-051)

Shared infrastructure for all cron jobs: single-flight lock mechanism (file lock), max wall time per job type with automatic kill, missed-run behavior (run on wake if within N hours, skip if older), jitter for non-time-sensitive jobs. All cron tasks (TOP-009, TOP-010, TOP-011, TOP-044, TOP-045) depend on this.

**Gate log standardization:** Gate results are written to `_openclaw/state/gates/<milestone>-<YYYY-MM-DD>.md`. Format: date range, metrics computed (from ops harness), pass/fail per criterion, overall determination. On failure: **specific hypothesis for the failure and next experiment** required before re-evaluation.

---

## M1 — Chief-of-Staff MVP (Week 1)

**Goal:** Establish the minimum viable operational loop: heartbeat awareness, morning briefing, vault health monitoring, pipeline monitoring.

**Success criteria (3-day gate — ALL must pass):**
- Briefing utility: morning briefing read and acted on ≥2 of 3 days
- Alert accuracy: false-positive alert rate <25%
- Cost ceiling: total daily Tess cost ≤$3/day averaged over 3 days
- Stability: self-healing restarts succeed on first attempt ≥80%
- Prompt tuning: at least one prompt revision applied during 3 days

**Gate failure policy:** Extend evaluation 2 days. Two consecutive failures → descope to briefing-only and diagnose.

### M1.1 — Heartbeat Configuration (TOP-006, TOP-007, TOP-008)

Configure voice agent (Haiku 4.5) heartbeat at 30-min intervals during waking hours (15 hrs/day). Configure mechanic agent (qwen3-coder) heartbeat at 60-min intervals 24/7. Implement cheap-checks-first pattern: shell scripts for binary checks, LLM only when signal detected. Enforce HEARTBEAT.md 10-entry scope cap.

### M1.2 — Morning Briefing (TOP-009)

Build 7 AM daily briefing cron job. Content: vault status, pipeline health, active project status, overnight alerts. Calendar and reminders data are NOT included in Week 1 — those require Google/Apple service integration (M3). Per-job token ceiling: 15k. Deliver via Telegram.

### M1.3 — Vault Health & Pipeline Monitoring (TOP-010, TOP-011, TOP-013)

Nightly vault health check (mechanic, 10k token ceiling). Hourly pipeline monitoring (mechanic, 5k token ceiling). Implement alerting rules: 2 consecutive briefing failures → Telegram alert; failed restarts → immediate alert; per-job ceiling breach → alert + kill; research staleness → weekly flag. Alert dedup policy: one alert per condition per 30 minutes, dedup keys per service. Escalation ladder: warn → critical → kill-switch recommendation.

### M1.4 — Per-Job Token Budgets & Cost Monitoring (TOP-012)

Implement per-job token ceilings per chief-of-staff §11 table. Truncate-and-log on ceiling hit. Weekly cost report including heartbeat breakdown.

### M1.5 — Week 1 Gate Evaluation (TOP-014)

Run 3-day evaluation against gate criteria. Log results. If gate passes, unlock M2/M3/M4 Phase 0s. If gate fails, follow failure policy.

---

## Approval Contract Protocol (TOP-049 — after Week 1 gate, before Phase 2)

**Goal:** Implement the shared approval protocol that all Phase 2+ write operations depend on. This is the governance backbone — without it, each consuming task would implement its own approval flow.

**Prerequisites:** TOP-002 (kill-switch operational), TOP-014 (Week 1 gate passed).

**Scope:**
- AID-* schema (approval_id, action_type, service, target, summary, original_context, risk_level, preview, expires_at)
- Telegram inline approve/deny UI
- Discord #approvals mirror with message ID correlation
- Wrapper enforcement hooks (AID-* token gate — blocks unauthorized sends at the wrapper level)
- Acceptance tests: approve path, deny path, 48h expiry, retry, anti-spam batching (>3 pending → bundle), 5-min cooldown, audit trail logging

**Timing:** Can be implemented in parallel with M2 Phase 0 setup and M3 Phase 1 read-only work. Must be complete before any M4 Phase 2 task begins.

---

## M2 — Service Prerequisites (Phase 0s — parallel after Week 1 gate)

**Goal:** Set up all infrastructure for Google, Apple, and Discord integrations. No operational capabilities yet — just plumbing.

**Success criteria:**
- Google OAuth authenticated and verified as openclaw user
- Apple cross-user execution wrapper tested and TCC grants confirmed
- Discord server created, both bots online, config validated

### M2.1 — Google Services Phase 0 (TOP-015, TOP-016, TOP-017, TOP-018)

Install gws (`@googleworkspace/cli`). Create Google Cloud project with Gmail/Calendar/Drive APIs. Run headless credential export flow (Danny authenticates via `gws auth login`, exports credential file to openclaw user). Evaluate pre-built agent skills for adoption. Create Gmail label taxonomy and filters. Create staging calendars. Create Drive folder structure. Verify access end-to-end.

### M2.2 — Apple Services Phase 0 (TOP-019, TOP-020, TOP-021, TOP-022, TOP-023)

Create sudoers entry for openclaw → danny with scoped binary list. Create `apple-cmd.sh` wrapper script. Install CLIs (remindctl, memo, ical-buddy) as Danny in GUI terminal. Grant TCC permissions interactively. Verify cross-user execution via wrapper. Verify GUI session dependency for AppleScript tools — include GUI canary test (AppleScript `tell app "System Events"` + `memo notes` via wrapper) to confirm headless paths won't silently fail. Create Reminders list architecture. Create iCloud Drive Agent workspace. Create config files (imessage-allowlist.txt, shortcuts-allowlist.txt).

### M2.3 — Communications Phase 0 — Discord Setup (TOP-024, TOP-025, TOP-026)

Create "Tess Ops" Discord server (private). Create channel/category structure (12 channels, 5 categories). Create tess-bot and mechanic-bot in Discord Developer Portal with least-privilege permissions. Invite bots, collect IDs. Store tokens as environment variables. Add Discord config to openclaw.json. Run config schema validation. Test posting to all channels.

---

## M3 — Read-Only Service Integration (Phase 1s — parallel after Phase 0 gates)

**Goal:** Add read-only data from Google and Apple services into the morning briefing and operational awareness. Discord starts receiving dual delivery.

**Success criteria (3-day gates per service):**
- Google Phase 1: email summary marked useful by operator ≥2/3 days, calendar events accurate (zero missed in 3-day spot check), auth stable (zero token failures)
- Apple Phase 1: Reminders section useful (≥2/3 days), calendar matches reality, zero TCC failures, wrapper success ≥95%
- Comms Phase 1: 3 consecutive days of successful dual delivery (Telegram + Discord), Discord auto-reconnects gracefully

### M3.1 — Google Phase 1 — Read-Only Email + Calendar (TOP-027)

Add email context to morning briefing (unread count, flagged items, today's calendar — all with `-label:@Risk/High` invariant). Add auth health check to mechanic heartbeat (`gws auth status`). Per-job token ceiling for email triage: 15k.

### M3.2 — Apple Phase 1 — Read-Only Reminders + Calendar (TOP-028)

Add Reminders snapshot to morning briefing via wrapper. Add Apple Calendar read to briefing (icalBuddy). TCC health check in mechanic heartbeat (every 30 min). All read-only — no mutations.

### M3.3 — Communications Phase 1 — Dual Delivery (TOP-029)

Enable dual delivery: briefings + heartbeat alerts to both Telegram and Discord. Morning briefing → Telegram (short, actionable) + Discord #briefings (full, structured). Heartbeat alerts → Telegram + Discord #mechanic. Discord gateway health check via mechanic canary message.

### M3.4 — Phase 1 Gate Evaluations (TOP-030)

Run 3-day evaluations for each service against gate criteria. Log results. Unlock Phase 2 for passing services.

---

## M4 — Active Operations (Phase 2s — after Phase 1 gates)

**Goal:** Enable write operations behind the approval contract. Email triage automation, Reminders write, Notes read, service output mirroring to Discord.

**Success criteria (3-day gates):**
- Google Phase 2: triage accurate, drafts useful, @Risk/High false-positive rate acceptable
- Apple Phase 2: task routing accuracy ≥80%, false-positive <20%, Notes search relevant ≥2/3 queries, zero data loss
- Comms Phase 2: ≥90% service outputs archived to Discord, approval mirrors within 30 seconds, delivery success ≥95%

### M4.1 — Google Phase 2 — Email Triage + Drafts (TOP-031)

Automated email triage via label state machine. Draft creation (never auto-sent). `-label:@Risk/High` invariant enforced in all query paths. Approval contract integration for future sends.

### M4.2 — Apple Phase 2 — Reminders Write + Notes Read (TOP-032, TOP-033)

Add reminders to Inbox/Agent lists autonomously. Complete reminders with approval. Notes search and read. Notes export (one-at-a-time, operator-initiated, approval-gated). Volume guardrail enforced.

### M4.3 — Communications Phase 2 — Service Output Mirroring (TOP-034)

All service outputs mirrored to relevant Discord channels. Approval mirrors in #approvals with message ID correlation and reply-based fallback. Audit log entries to #audit-log from both tess-bot and mechanic-bot.

### M4.4 — Phase 2 Gate Evaluations (TOP-035)

Run 3-day evaluations against gate criteria. Log results. Unlock Phase 3.

---

## M5 — Advanced Operations (Phase 3s — after Phase 2 gates)

**Goal:** Enable approval-gated sends, calendar staging, contact enrichment, iMessage read, multi-agent Discord, cross-context routing.

**Success criteria (3-day gates):**
- Google Phase 3: approval → cooldown → send cycle works, cancel during cooldown works, audit trail complete
- Apple Phase 3: contact enrichment marked useful by operator for ≥2 meeting preps, iMessage search returns relevant context ≥2/3 queries, zero Full Disk Access failures, zero prompt-injection-as-instruction incidents
- Comms Phase 3: all agents have Discord bots online ≥99%, cross-context delivery ≥95%, #dispatch-log captures all bridge results

### M5.1 — Google Phase 3 — Calendar Staging + Email Send (TOP-036, TOP-037)

Calendar staging to Agent — Staging calendar. Promotion to Primary via approval contract. Email send with technical enforcement (wrapper-level AID-* token gate, 5-min cooldown, 3/hour rate limit, 10/day cap). Security event logging for unauthorized send attempts.

### M5.2 — Apple Phase 3 — Contacts + iMessage Read (TOP-038, TOP-039)

Contact search and enrichment for meeting prep. iMessage history search (Full Disk Access required — verify BlueBubbles availability as recommended by OpenClaw docs). Prompt injection defense: iMessage content is read context only, never instruction source.

### M5.3 — Communications Phase 3 — Multi-Agent + Cross-Context (TOP-040)

Feed-intel bot created (if feed-intel is independent agent). Multi-agent Discord presence with per-bot channel restrictions. Cross-context routing: local bridge (shared-secret auth, idempotency keys, disk queue) as primary; crossContextRoutes (#22725) as future enhancement if merged.

### M5.4 — Phase 3 Gate Evaluations (TOP-041)

Run 3-day evaluations. Google Phase 3 gate is the critical path — iMessage send (M6) requires email send stable 2+ weeks.

---

## M6 — Extended Capabilities (Phase 4s — after Phase 3 gates + stabilization)

**Goal:** Drive operations and iMessage send (both high-sensitivity, deferred until earlier phases prove the governance model).

**Success criteria:**
- Google Phase 4: Drive scope upgrade decision made based on concrete use case data
- Apple Phase 4: iMessage send operational with strict allowlist, approval → cooldown → send → audit cycle verified

### M6.1 — Google Phase 4 — Drive Operations (TOP-042)

Evaluate `drive.file` vs full `drive` scope based on operational data from Phases 1-3. Only upgrade if concrete use case requires it. Path-level allowlist before scope change.

### M6.2 — Apple Phase 4 — iMessage Send (TOP-043)

**Prerequisite:** Google email send (M5.1) running stable for 2+ weeks. Strict sender allowlist (3-5 contacts initially). Max 3 messages/hour, 10/day. Full message text in Telegram approval. 5-min cooldown. No group messages. No attachments without approval. Gradual allowlist expansion.

---

## M7 — Feed-Intel Ownership Transition (after Week 1 gate + Phase B prerequisites)

**Goal:** Migrate feed-intel pipeline ownership from standalone cron to Tess operational scope.

**Success criteria:**
- All 7 machine-checkable health signals operational
- Runtime config contract enforced (5 source types, validation on parse failure)
- Cost within $1.50/day hard cap
- Morning briefing reads feed-intel digest + status line

**Prerequisite:** Chief-of-staff Week 1 gate passed (3 days stable). Feed-intel-framework project (separate project, currently TASK phase) completes Milestone 2 — pipeline migration. See `Projects/feed-intel-framework/project-state.yaml` for status.

### M7.1 — Feed-Intel Phase A — Monitoring Only (TOP-044)

Add feed-intel health signals to mechanic heartbeat. Morning briefing reads digest file + status line. No ownership of cron jobs yet — monitoring and reporting only.

### M7.1b — Feed-Intel Parallel Verification (TOP-052)

3-day parallel run: feed-intel capture/attention running via both launchd (existing) and OpenClaw cron (new) simultaneously. Compare outputs for parity. Discrepancies >5% → pause and debug. Parity confirmed before proceeding to full ownership transfer. This prevents silent regressions during the migration.

### M7.2 — Feed-Intel Phase B — Full Ownership (TOP-045)

Transfer cron job ownership. Feed-intel runs with separate session isolation (`sessionTarget: "isolated"`), separate cost cap ($1.50/day), and separate pause flag (not global maintenance) — cascade to core chief-of-staff operations is prevented by design. Implement runtime config contract (§3.6), feedback verb contract (§3.7), cron guardrails (§3.8), cost caps (§3.9). Explicit Telegram delivery with `sessionTarget: "isolated"` payloads. 3 consecutive failures → auto-pause.

---

## M8 — Intelligence Layer (Week 2+ — after M1 gate, parallel with M3+)

**Goal:** Enable the intelligence and research capabilities that differentiate Tess from a monitoring bot.

**Success criteria:**
- Overnight research produces output with ≥3 concrete actions per session, ≥2x/week
- Session prep/debrief: operator marks 0/1 per session, target ≥3/5 sessions marked useful
- Weekly connections brainstorm produces at least one actionable suggestion operator follows up on

### M8.1 — Overnight Research Sessions (TOP-046)

Haiku 4.5, 2-3x/week, 50k token ceiling. Competitive intelligence, account intelligence, builder ecosystem radar. Output to vault working directory for Crumb review.

### M8.2 — Session Prep & Debrief (TOP-047)

Pre-session context assembly (20k token ceiling). Post-session debrief logging. Triggered by Crumb session start/end signals.

### M8.3 — Weekly Connections Brainstorm (TOP-048)

Sonnet 4.5 (highest-quality model for creative work), weekly, 100k token ceiling. Relationship and networking suggestions based on calendar, contacts, and account intelligence. Requires M5.2 (contacts) for full effectiveness — initial version uses available data.

---

## Milestone Dependencies

```
M0 ──→ M1 ──┬──→ M2 (parallel: M2.1, M2.2, M2.3)
             │     │
             │     ├──→ M3 (parallel: M3.1, M3.2, M3.3) ──→ Approval Contract (TOP-049)
             │     │     │
             │     │     ├──→ M4 (parallel: M4.1, M4.2, M4.3) — requires TOP-049
             │     │     │     │
             │     │     │     ├──→ M5 (parallel: M5.1, M5.2, M5.3)
             │     │     │     │     │
             │     │     │     │     ├──→ M6.1 (Drive)
             │     │     │     │     └──→ M6.2 (iMessage send — requires M5.1 stable 2+ weeks)
             │     │     │
             │     │     └──→ M8 (intelligence — parallel with M3+, full effectiveness at M5.2)
             │
             ├──→ M7 (feed-intel — requires M1 gate + FIF M2 complete, independent of M2-M6)
             │     TOP-044 (monitor) → TOP-052 (3-day parallel verify) → TOP-045 (ownership)
             │
             └──→ M8.1, M8.2 (can start immediately after M1 gate with limited data)
```

**Governance rule:** Never advance more than two service families (Google, Apple, Comms) through Phase 1+ simultaneously. Phase 0 setup (M2) can run all three in parallel because it's infrastructure plumbing, not operational work.

## Rollback Tiers

| Tier | Trigger | Action | Recovery |
|------|---------|--------|----------|
| 0 — Emergency | Any crisis | `touch ~/.openclaw/maintenance`. If system unresponsive: manually `pkill -f openclaw` all Tess/OpenClaw processes. | Diagnose root cause. Fix. Then `rm ~/.openclaw/maintenance` to resume. |
| 1 — Selective | Single capability misbehaving | `openclaw cron remove <job-id>` or disable specific wrapper | Other capabilities unaffected. Re-enable after fix. |
| 2 — Service | Entire service integration failing | Remove service config section from openclaw.json + restart | Other services unaffected. Re-enable after fix. |
| 3 — Discord | Discord-specific issues | `channels.discord.enabled: false` + restart | Telegram-only operation. Discord history preserved. |
| 4 — Full | Combined cost >$120/month or net negative value | Remove all cron jobs, revert HEARTBEAT.md, disable hooks | Manual review of all cost drivers. Incremental re-enablement starting at M1 (briefing-only) after root cause analysis. |

### Mismutation Remediation (per-service "undo" recipes)

When rollback is triggered by "service did the wrong thing" rather than "service is down":

| Service | Common Mismutation | Remediation |
|---------|-------------------|-------------|
| Gmail | Mislabeled emails (wrong triage category) | Query recipe: `label:@Agent/DONE after:YYYY/MM/DD before:YYYY/MM/DD` → bulk re-label via `gws gmail users messages modify` |
| Reminders | Task misfiled to wrong list | Manual review via `remindctl list <list-name>`; move individual items back |
| Calendar | Stale staging holds not cleaned up | `gws calendar events list --params '{"calendarId":"<staging-id>"}'` → delete holds older than 48h |
| Discord | Wrong channel routing | Review `#audit-log` to identify misposts; delete via bot if needed; correct routing config |

---

## Appendix: Spec Traceability

| Spec | Phase | Milestone | Task IDs |
|------|-------|-----------|----------|
| **Chief-of-staff** | Week 0 (prerequisites) | M0 | TOP-001 to TOP-005 |
| | Week 1 (MVP: heartbeat, briefing, monitoring) | M1 | TOP-006 to TOP-014 |
| | Week 2+ (intelligence layer) | M8 | TOP-046 to TOP-048 |
| | Feed-intel ownership transition | M7 | TOP-044, TOP-045 |
| **Google services** | Phase 0 (OAuth, labels, calendars, Drive) | M2.1 | TOP-015 to TOP-018 |
| | Phase 1 (read-only email + calendar in briefing) | M3.1 | TOP-027 |
| | Phase 2 (email triage + drafts) | M4.1 | TOP-031 |
| | Phase 3 (calendar staging + email send) | M5.1 | TOP-036, TOP-037 |
| | Phase 4 (Drive scope decision) | M6.1 | TOP-042 |
| **Apple services** | Phase 0 (sudoers, wrapper, CLIs, TCC) | M2.2 | TOP-019 to TOP-023 |
| | Phase 1 (read-only reminders + calendar) | M3.2 | TOP-028 |
| | Phase 2 (reminders write + notes read) | M4.2 | TOP-032, TOP-033 |
| | Phase 3 (contacts + iMessage read) | M5.2 | TOP-038, TOP-039 |
| | Phase 4 (iMessage send) | M6.2 | TOP-043 |
| **Communications** | Phase 0 (Discord server + bots) | M2.3 | TOP-024 to TOP-026 |
| | Phase 1 (dual delivery) | M3.3 | TOP-029 |
| | Phase 2 (service output mirroring) | M4.3 | TOP-034 |
| | Phase 3 (multi-agent + cross-context) | M5.3 | TOP-040 |
| **Cross-cutting** | Approval Contract protocol | Between M1–M4 | TOP-049 |
| | Ops Metrics v1 harness | M0 | TOP-050 |
| | Cron guardrails infrastructure | M0 | TOP-051 |
| | Feed-intel parallel verification | M7 | TOP-052 |

**Out of scope for this plan:** Frontier ideas beyond those promoted to baseline (anticipatory session prep, dead man's switch). These are tracked in `design/tess-frontier-ideas.md` for future planning cycles.
