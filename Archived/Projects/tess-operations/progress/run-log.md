---
project: tess-operations
type: run-log
created: 2026-02-26
updated: 2026-03-26
---

# tess-operations — Run Log

> **Archive:** [[run-log-2026-02]] — Project creation, SPECIFY (5 specs + peer review), PLAN (action-architect + peer review), TASK M0-M1 deployment + validation (2026-02-26 through 2026-02-28)
> **Archive:** [[run-log-2026-03a]] — M2-M4 deployment: email triage soak, approval contract, Reminders write, Notes read, Discord mirroring, Phase 2 gate (2026-03-06 through 2026-03-14)

---

## 2026-03-29 — TOP-057: Overnight Research Streams Fixed

### Context Inventory
1. `_openclaw/scripts/overnight-research.sh` — the broken script
2. `Projects/tess-operations/design/overnight-research-design.md` — §Watchlist Model, §last30days Integration
3. FIF DB schema (`posts` table, `triage_json` structure)
4. `_system/scripts/session-startup.sh` — reference for DB-direct query pattern

### Fixes Applied (4 data sources)

1. **FIF digests → DB-direct query.** Replaced file-based digest reading with SQLite query against `posts` table for HIGH/MEDIUM items triaged in last 7 days. Removes implicit coupling to FIF's overflow file write mechanism (the root cause). Same pattern already used by FIF dashboard and session startup hook.

2. **Dossier path corrected.** `Projects/customer-intelligence/dossiers/` → `Domains/Career/accounts/*/dossier.md`. Removed dead `STAGING_DIR` fallback. Account name extracted from parent directory.

3. **Signal-notes path corrected.** `_system/signal-notes/` → `Sources/signals/`.

4. **last30days source selection fixed.** Problem was sources, not query terms — Reddit/Polymarket/TikTok return noise for B2B queries. Competitive stream now uses `--search web` (Brave web+news only). Builder stream uses `--search web,hn,reddit` (HN and Reddit are relevant for dev ecosystem). Query terms also improved per design doc watchlist model (added specific competitor names, ecosystem terms).

### Additional Changes
- `gather_last30days()` accepts optional third arg for per-stream `--search` flags
- `gather_fif_digest_matches()` (reactive helper) also switched to DB-direct
- `FIF_DIGEST_DIR` constant removed (no longer referenced)
- Scheduled streams re-enabled (Sunday competitive, Wednesday builder)

### Verification
- `bash -n` syntax check: PASS
- Dry-run competitive: 4 sections gathered (FIF signal, dossiers, signal notes, last30days web), 13.4 KB context
- Dry-run builder: 3 sections gathered (FIF signal, projects, last30days web+hn+reddit), 9.3 KB context
- Dry-run reactive: clean exit (no items queued — expected)

### TOP-058: Account-Prep Pipeline Scan — DONE

Added §8b to `_openclaw/staging/m1/morning-briefing-prompt.md`. Scans `_openclaw/state/account-prep/` for YAML pipeline state files. Reports non-terminal pipelines (`synthesized` as ready-to-deliver, others as in-progress). Flags stale `synthesized` items (>24h) prominently. Skips silently when no pending pipelines exist.

### TOP-059: Pending Signals Addressed — DONE

**Signal 1 — Sycophancy (Olson/Fanous, 2025):**
The signal recommended embedding persistent decision context so agents have something to "stand on" when challenged. `tess-context.md` had the right sections (`Standing Decisions`, `Open Commitments`) but they're operator-seeded and empty. Fix: added a new "Decision Context" section that's auto-refreshable by the morning briefing. Populated with 8 established principles from vault sources:
- Liberation Directive (revenue, portfolio, ship)
- Ceremony Budget Principle (friction reduction > new capability)
- Vault authority (AD-001), spec-first (AD-003), parallel operation (AD-002)
- Evidence before commitment (SOUL.md)

SOUL.md updated to reference Decision Context when facing pushback: "hold your position and cite the principle."

**Signal 2 — Reasoning degradation (Jo, 2026):**
The paper showed structured reasoning degrades 100% → 0-30% in complex production prompts due to instruction dilution. SOUL.md is ~435 lines — any reasoning framework added late would be diluted. Fix: added a reasoning-primacy paragraph to "How You Operate" (early in SOUL.md, before Voice/Boundaries/formatting). Key instruction: "Think through the problem fully before committing to an answer — once you've written a conclusion, you can't reason past it." Positioned to leverage primacy effect per the paper's findings.

Morning briefing refresh procedure updated to maintain Decision Context section from vault sources.

**Pending signals cleared from project-state.yaml:** Both signals addressed.

### Status
All 3 blocking tasks complete (TOP-057, TOP-058, TOP-059). Project ready for DONE transition.
First live overnight research run: tonight (Sunday = competitive rotation).

---

---

## 2026-03-26 — DONE transition blocked: 3 new issues found

**Context:** Gate evaluations for FIF and A2A-018 revealed tess-operations gaps. Two empty research briefs deleted (competitive Mar 22, builder Mar 25). Investigation traced failures to overnight research scheduled streams.

**Root cause diagnosis — scheduled streams have 4 broken data sources:**
1. **FIF digest files:** `writeFileDigest` in `src/digest/index.ts` only fires on overflow (`posts.length > max_items_inline`). After LOW items removed from digests (Mar 10), counts dropped below threshold. No files written since Mar 8. Overnight research reads these files → empty context.
2. **Dossier path:** Script expects `Projects/customer-intelligence/dossiers/`. Actual: `Domains/Career/accounts/*/dossier.md`. Path was never updated after customer-intelligence restructured.
3. **Signal-notes path:** Script expects `_system/signal-notes/`. Actual: `Sources/signals/`. Directory was renamed.
4. **last30days query quality:** Generic queries ("competitive intelligence DDI DNS security IPAM") return Polymarket sports bets and Reddit noise instead of B2B trade press. Needs specific watchlist terms per the design doc §Watchlist Model.

**Action taken:** Disabled scheduled streams in `overnight-research.sh` with diagnostic comment. Reactive stream (mark-for-research via Mission Control) unaffected — queries FIF DB directly, bypasses all 4 broken paths.

**A2A-018 gap:** Morning briefing doesn't scan `_openclaw/state/account-prep/` for `synthesized` pipelines. Both synthetic dispatches stuck — Tess never delivered briefs.

**New tasks created:**
- TOP-057: Fix overnight research scheduled streams (4 data sources)
- TOP-058: Add account-prep pipeline scan to morning briefing
- TOP-059: Address pending signals (sycophancy + reasoning degradation)

**Compound:** The digest file gap is a design-implementation mismatch — the file write was an overflow mechanism but another pipeline (overnight research) assumed it was a persistent archive. This pattern recurs: "Feature A has a side effect that Feature B depends on; refactoring A breaks B silently." The fix should be explicit: either always write digest files (make the contract explicit) or have overnight research query the DB directly (remove the implicit coupling). The DB-direct approach is more robust — it's the same pattern FIF dashboard and startup hook already use.

---

## 2026-03-20i — TOP-045 done + TOP-052 dropped (FINAL TASK)

### Work completed

1. **TOP-052 (feed-intel parallel verification) — DROPPED.** Parallel verification is unnecessary ceremony — running both simultaneously risks SQLite conflicts, and all other Tess cron jobs work via launchd (proven pattern). Switchover + soak built into TOP-045 is sufficient.

2. **TOP-045 (feed-intel ownership transfer) — DONE.**

   **Discovery:** FIF jobs were already running under tess launchd — `ai.openclaw.fif.{capture,attention,feedback}` are LaunchAgents in tess's GUI domain, created by `openclaw cron add`. They run `node` directly via `~/.config/fif/run.sh` wrapper, not through the OpenClaw gateway.

   **Built-in guardrails verified:**
   - Cost tracking: `cost_log` table recording per-adapter costs. Daily costs $0.15-$0.33 (well under $1.50/day cap).
   - Adapter degraded state: `src/health/index.ts` — 3 consecutive failures → degraded mode (skip triage + Telegram alert), auto-recovery on success.
   - Liveness checks: per-adapter `liveness_max_gap_minutes` in manifests.
   - Feedback listener: running continuously (PID active), processing Telegram replies.
   - Runtime config: adapter manifests loaded at cycle boundaries.

   **Added: FIF-specific pause flag:**
   - `~/.config/fif/pause` — touch to halt, rm to resume
   - Checked in `run.sh` wrapper before sourcing credentials or exec'ing node
   - Also respects global `~/.openclaw/maintenance` flag
   - Tested: pause flag → exit 0 with log message; remove flag → normal execution

**ALL TASKS RESOLVED: 53 done + 4 dropped = 57/57. Project ready for DONE transition.**

### Compound evaluation
- **"Transfer" that was already done:** The FIF jobs were created by `openclaw cron add` which generates LaunchAgents — they were already running under tess, just with OpenClaw-branded plist names. The actual work for "ownership transfer" was: verify built-in guardrails are active + add a pause flag. This pattern recurs: infrastructure work often discovers the hard part is already done, and the remaining work is verification + a thin integration layer.

---

## 2026-03-20h — TOP-042 done + TOP-056 closed + TOP-041 done

### Work completed

1. **TOP-042 (Drive scope decision) — no action needed.** Full `drive` scope already granted by workspace MCP OAuth flow. Current usage bounded to `00_System/Agent/` folder tree.

2. **TOP-056 (daily attention cron) — CLOSED.** All AC met:
   - 10 consecutive days of artifacts (Mar 11-20)
   - Pre-7AM generation confirmed (Mar 15 at 06:30, Mar 17-19 at 00:05-00:07)
   - Carry-forward counts accurate with escalation at 5+ days
   - Domain balance section present in every artifact
   - 5/5 source paths validated (no hallucinated links)
   - Briefing section populated with real data (0 "No daily plan" occurrences)
   - Sidecar JSON generated daily (Mar 14-20) with validated schema

3. **TOP-041 (Phase 3 gate) — PASS.** Apple Phase 3 dropped; Google + Comms Phase 3 passed on e2e testing.

**Project status: 55/56 resolved (52 done + 3 dropped). 1 dependency chain remains: TOP-052 → TOP-045.**

---

## 2026-03-20g — TOP-042 done (Drive scope decision — no action needed)

### Work completed
**TOP-042 — Decision: accept current scopes, no action required.**

Full `drive` scope is already granted by the workspace MCP OAuth flow. The spec's concern (§2.4) about deliberate scope expansion is moot — the MCP server requests broad scopes at consent time. Current usage is bounded to `00_System/Agent/` folder tree (audit docs, research staging). Single-user account with no external sharing. Risk is acceptable without restriction.

No scope change, no path-level allowlist, no risk review needed. Decision logged.

---

## 2026-03-20f — TOP-038/039/043 dropped + TOP-041 done (Phase 3 gate — PASS)

### Context inventory
- `Projects/tess-operations/action-plan.md` — M5 Phase 3 gate criteria
- `_openclaw/state/gates/phase2-gate-2026-03-20.md` — prior gate format
- `_openclaw/logs/calendar-staging.log`, `email-send.log`, `google-security.log`, `discord-bridge.log` — deployment evidence

### Work completed

1. **TOP-038/039/043 dropped by operator decision:**
   - TOP-038 (contact search): Google Contacts via MCP covers the need. No Apple-specific integration required.
   - TOP-039 (iMessage read): BlueBubbles server adds maintenance burden and prompt injection surface for limited value.
   - TOP-043 (iMessage send): Multi-gate approval pipeline for texting is overkill. Email send covers outbound needs.
   - Impact: TOP-041 dependencies reduced from 5 to 3 (TOP-036/037/040, all done). Gate unblocked immediately.

2. **TOP-041 (Phase 3 Gate) — PASS:**
   - Google Phase 3: PASS — email send 5-gate enforcement e2e verified (2 full cycles), calendar staging e2e verified (2 full cycles), domain denylist tested (7/7), rate limiting tested (2/2), audit trail complete across 4 surfaces.
   - Apple Phase 3: DROPPED — no longer evaluated.
   - Comms Phase 3: PASS — per-bot channel restrictions enforced (bridge + direct), cross-context bridge e2e verified (shared-secret, idempotency, disk queue, forum channel handling).

Gate record: `_openclaw/state/gates/phase3-gate-2026-03-20.md`

### Key decisions
- **Dropping 3 tasks was higher leverage than implementing them.** The iMessage integration (TOP-039/043) would have added: BlueBubbles server dependency, Full Disk Access management, prompt injection defense surface, Apple-specific allowlist infrastructure — all for texting 1-2 people. The ceremony-to-value ratio was inverted. Contact search (TOP-038) was already covered by Google Contacts MCP. This aligns with the Ceremony Budget Principle (CLAUDE.md): reducing ceremony > adding capability.
- **Phase 3 gate passed on same-day deployment:** All services were deployed and comprehensively tested in this session. The underlying infrastructure (approval contract, Discord webhooks, Gmail API) has weeks of production stability. The new scripts are thin wrappers over proven infrastructure.

### Compound evaluation
- **Task pruning as project acceleration:** Dropping 3 tasks immediately unblocked a gate that was the critical path. The project went from "4 tasks blocked, 2 needing external dependencies" to "4 tasks remaining, all unblocked." This is a pattern worth noting: when tasks were specced months ago, re-evaluating them against current operational reality can reveal that the problem they solve is already solved by different means.

### Model routing
- Main session: Opus

---

## 2026-03-20e — TOP-048 done (Weekly connections brainstorm)

### Context inventory
- `Projects/tess-operations/design/tess-chief-of-staff-spec.md` — §8.4 connections brainstorm, §10 model config, §11 token budgets
- `_openclaw/scripts/daily-attention.sh` — pattern reference for direct Anthropic API cron
- `_openclaw/scripts/overnight-research.sh` — pattern reference for data gathering

### Work completed

1. **`connections-brainstorm.sh` — weekly cross-domain synthesis:**
   - Option A architecture: bash gathers all context, single Sonnet API call, bash writes artifact
   - Data sources: active projects (10), calendar (14 days), strategic priorities, signal notes, research, insights, account intel (dossiers), feed-intel digests (7 days), Apple Notes
   - Output: `_openclaw/inbox/brainstorm-<date>.md` with frontmatter (`type: connections-brainstorm`, `status: pending-review`)
   - Prompt: 6 focus areas (relationship opportunities, cross-domain patterns, timing advantages, knowledge sharing, builder community, one surprising idea)
   - Token budget: ~5k input, 8k max output. Cost: ~$0.07/week on Sonnet 4.6
   - Idempotency: skips if any `brainstorm-*.md` exists in inbox within last 7 days
   - Telegram notification with section count after generation

2. **LaunchAgent deployed:** `com.tess.connections-brainstorm` — daily poll (86400s StartInterval), script idempotency handles weekly cadence. Installed and loaded.

3. **First live run — W12 brainstorm:**
   - 4 cross-domain connections, relationship opportunities, timing advantages generated
   - Quality check: specific references to vault artifacts (ECL insight, A2A-018 gate, opportunity-scout soak, compiled-memory paper), actionable suggestions
   - Cost: $0.07 (4907 in / 3794 out on Sonnet 4.6)

### Key decisions
- **Sonnet 4.6 over Opus:** Spec says Sonnet for "synthesis quality at weekly cost." First run confirms quality is sufficient — cross-domain connections are specific and actionable. $0.07/week vs ~$0.50+ on Opus.
- **Daily LaunchAgent with script idempotency:** StartCalendarInterval is broken on macOS Tahoe (memory note). Daily poll + script-level week check achieves weekly cadence without cron complexity.
- **Output to inbox (not vault):** Brainstorms go to `_openclaw/inbox/` for operator review before any vault action. Prevents unsupervised vault mutations from creative output.

### Compound evaluation
- **Contacts data will dramatically improve output:** Current run has no contact data (TOP-038 blocked on Apple soak). Calendar attendee extraction works but yields only email addresses. Once contact search is available, the "Relationship Opportunities" section will have names, roles, and interaction history to work with. The architecture is ready — data sources just need to expand.

### Model routing
- Main session: Opus (implementation + testing)
- One Explore subagent for spec research
- Brainstorm itself: Sonnet 4.6 (cron — $0.07)

---

## 2026-03-20d — TOP-040 done (Multi-agent Discord and cross-context routing)

### Context inventory
- `Projects/tess-operations/design/tess-comms-channel-spec.md` — §4 multi-agent, §5.3 cross-context bridge
- `_openclaw/scripts/discord-post.sh` — extended with channel restrictions + forum support
- `_openclaw/config/discord-webhooks.json` — webhook URLs and channel types
- `_openclaw/config/discord-channels.json` — channel ID map
- `_openclaw/scripts/awareness-check.sh` — extended with bridge drain (check 8)

### Work completed

1. **Per-bot channel allowlist (`config/discord-bot-channels.json`):**
   - Tess: morning-briefing, session-prep, weekly-review, approvals, email-triage, calendar, reminders, sandbox, audit-log
   - Mechanic: mechanic, vault-ops, dispatch-log, audit-log
   - Feed-intel: feed-intel (prepared for TOP-045 ownership transfer)
   - Enforced in both discord-post.sh (direct calls) and discord-bridge.sh (queued calls)

2. **discord-post.sh extended:**
   - Channel restriction enforcement: validates `--username` against bot allowlist before posting. Compound usernames (e.g., "Tess Approvals") resolve to base bot ("tess"). Blocked posts log and exit 0 (graceful — prevents silent channel leak).
   - Forum channel support: detects channel type from `discord-webhooks.json`, adds `thread_name` (first line of message, max 100 chars) for forum webhooks. Fixes "must have thread_name" error.

3. **Cross-context bridge (`discord-bridge.sh`):**
   - `enqueue` — validates shared secret → validates bot→channel allowlist → checks idempotency key → writes JSON to disk queue. Returns idempotency key.
   - `drain` — iterates queue, posts via discord-post.sh, moves to processed dir. Prunes processed files older than 7 days.
   - `status` — reports pending and processed counts.
   - Shared secret: 256-bit random hex at `config/discord-bridge-secret.txt` (640 perms).
   - Idempotency: filename-based dedup — checks both queue and processed dirs.
   - Disk queue: `state/discord-bridge-queue/` persists messages across Discord downtime.

4. **Awareness-check check 8:** Drains bridge queue every 30 min. For near-real-time, callers can invoke drain immediately after enqueue.

5. **Feed-intel bot config:** Entry in bot-channels.json. Actual Discord Developer Portal bot creation deferred to TOP-045 (feed-intel ownership transfer) — no bot needed until feed-intel pipeline is running through Tess.

6. **E2e verified (9 tests):**
   - T1: Valid enqueue → queue file created
   - T2: Idempotency — duplicate key skipped
   - T3: Invalid secret → rejected
   - T4: Tess→mechanic channel → blocked
   - T5: Mechanic→mechanic channel → allowed
   - T6: Queue drain → both messages delivered (forum fix resolved morning-briefing failure)
   - T7: discord-post.sh direct — Tess→mechanic blocked
   - T8: discord-post.sh direct — Tess→approvals allowed
   - T9: Compound username "Tess Approvals" → resolved to base bot "tess"

### Key decisions
- **File-based bridge over HTTP service:** The spec suggested a loopback HTTP service, but a file-based queue achieves the same properties (shared-secret, idempotency, disk durability) without a running daemon. The bridge is a script, not a service — lower operational complexity. If OpenClaw adds native `crossContextRoutes` (issue #22725), the bridge becomes obsolete and can be removed.
- **Graceful exit 0 on channel restriction:** Blocked posts exit 0 (not 1) to prevent caller failure cascades. The restriction is logged. This matches discord-post.sh's existing pattern for missing webhooks.
- **Forum channel auto-detection:** Rather than requiring callers to know channel types, discord-post.sh reads `channel_types` from the webhooks config. Forum channels get `thread_name` automatically. This is transparent to all callers (bridge, approval-request, cron jobs).

### Compound evaluation
- **Forum channel thread_name pattern:** Discord forum webhooks require `thread_name` — this wasn't handled in the original TOP-034 discord-post.sh because only text channels had webhooks at that time. When the morning-briefing forum webhook was tested via the bridge, it surfaced the bug. Pattern: any new webhook for a forum channel needs the `channel_types` entry in `discord-webhooks.json` to be marked as `"forum"`.

### Model routing
- Main session: Opus (multi-component implementation + security design)
- One Explore subagent for spec research
- No delegation

---

## 2026-03-20c — TOP-037 done (Email send with technical enforcement)

### Context inventory
- `Projects/tess-operations/design/tess-google-services-spec.md` — §5 approval flow, §5.1 rate limits, §7.4 send enforcement
- `Projects/tess-operations/design/tess-chief-of-staff-spec.md` — §9b approval contract, cooldown spec
- `_openclaw/scripts/approval-request.sh`, `approval-executor.sh`, `approval-check.sh` — existing approval infrastructure
- `_openclaw/scripts/calendar-staging.sh` — pattern reference (just built in TOP-036)
- `_openclaw/lib/gws-token.sh` — extended with Gmail draft/send helpers

### Work completed

1. **`email-send.sh` — defense-in-depth email send with 5 execution gates:**
   - `draft` — autonomous draft creation. Builds MIME message (python3 `email.mime`), base64url-encodes, creates via Gmail API. Returns draft_id.
   - `send` — requests approval. Pre-flight checks: domain denylist, rate limit, recipient count (max 3). Creates SEND_EMAIL approval with 5-min cooldown, medium risk. Returns AID.
   - `execute` — 5 sequential gates before sending:
     - Gate 1: AID approval validation (approval-check --validate-only)
     - Gate 2: Re-fetch draft (verify it still exists, hasn't been modified)
     - Gate 3: Domain denylist re-check at execution time (defense against approval-time bypass)
     - Gate 4: Rate limit re-check at execution time
     - Gate 5: Recipient count re-check
   - After all gates pass: `gws_gmail_send_draft` → record in rate tracker → mark executed

2. **`gws-token.sh` extended with 3 Gmail helpers:**
   - `gws_gmail_create_draft` — POST create draft from base64url MIME
   - `gws_gmail_send_draft` — POST send existing draft by ID
   - `gws_gmail_get_draft` — GET draft details (headers, snippet, payload)

3. **Domain denylist (`config/email-domain-denylist.txt`):**
   - Government TLDs: `.gov`, `.mil`, `.gov.uk`, `.gov.au`, `.gov.ca`, `.gc.ca`, `.gov.in`, `.gov.br`
   - Financial: chase.com, bankofamerica.com, wellsfargo.com, citibank.com, capitalone.com, usbank.com, pnc.com, tdbank.com, regions.com
   - Financial regulators: sec.gov, finra.org, fdic.gov, occ.treas.gov, cfpb.gov
   - Case-insensitive matching. TLD patterns (`.gov`) match any subdomain. Editable at runtime.
   - Blocks at both send-request time AND execution time (double-check pattern).

4. **Rate limiting (`state/email-send-rate.json`):**
   - File-based sliding window: array of epoch timestamps for each send
   - Hourly limit: 3/hour. Daily limit: 10/day. Max recipients: 3/email.
   - Auto-prunes entries older than 24h on each `record_send` call.

5. **Security logging (`logs/google-security.log`):**
   - All security events: DOMAIN_DENIED, RATE_LIMIT, UNAUTHORIZED_SEND, SEND_OK, SEND_FAILED
   - Telegram alerts for denylist blocks and rate limit blocks
   - Separate from operational `email-send.log`

6. **Approval executor wired** — `email-send` case dispatches to `email-send.sh execute`

7. **Acceptance tests (all pass):**
   - T1–T7: Domain denylist (7/7 — .gov, .mil, chase.com, case-insensitive, allowed domains)
   - T8–T9: Rate limiting (passes at 0, blocks at 3/hour)
   - Draft creation: real API call, draft verified
   - Send request: approval created with correct fields (SEND_EMAIL, medium, 300s cooldown)
   - Denylist blocking: .gov draft blocked at send-request time with security event + alert
   - Full execute: draft → send → approve → cooldown elapsed → execute → email delivered (self-send)
   - Executor path: full cycle through approval-executor.sh dispatch

### Key decisions
- **5 gates at execution, not just approval check:** The spec says AID-* gate + rate limits. Implementation adds domain denylist re-check and draft re-fetch as defense against: (1) denylist edited after approval, (2) draft modified between approval and execution, (3) race conditions in rate limiting.
- **Domain denylist as config file, not hard-coded:** Operator can add/remove domains without code changes. Takes effect immediately (read on every check). Government and financial pre-populated.
- **Draft-based send flow:** All sends go through the draft → approve → send-draft pipeline. No direct compose+send path. This ensures the operator can always review the draft in Gmail before approving, and the draft ID provides an audit trail.
- **Separate security log:** `google-security.log` captures only security-relevant events (blocks, unauthorized attempts, successful sends). Distinct from operational `email-send.log` which captures all activity including drafts.
- **Self-send test pattern:** Used `dturner71@gmail.com` as recipient for e2e test — self-sends are harmless and prove the full API path works without sending to external addresses.

### Compound evaluation
- **Double-check pattern (request-time + execution-time validation):** When approval and execution are separated by a cooldown window, re-validate all safety invariants at execution time. The world can change during the cooldown — denylist updated, rate limit hit by another path, draft modified. This pattern applies to any high-risk gated operation. Already used by calendar-staging (re-fetch event at execution) — now codified as a deliberate pattern.
- **2-week stability clock starts:** TOP-043 (iMessage send) requires "Google email send stable 2+ weeks." Clock starts today (2026-03-20). Earliest iMessage eligibility: 2026-04-03.

### Model routing
- Main session: Opus (high-risk implementation + security design + testing)
- One Explore subagent for spec research
- No Sonnet delegation — email send is the highest-risk task in the project

---

## 2026-03-20b — TOP-036 done (Calendar staging and approval-to-Primary promotion)

### Context inventory
- `Projects/tess-operations/design/tess-google-services-spec.md` — §3.3 three-calendar architecture, §5 approval integration
- `_openclaw/lib/gws-token.sh` — extended with calendar CRUD+move helpers
- `_openclaw/scripts/reminder-write.sh` — pattern reference for approval-gated operations
- `_openclaw/scripts/approval-executor.sh` — extended with `cal-promote` case
- `_openclaw/scripts/approval-request.sh` — used for promote approval flow
- `_openclaw/config/google-calendars.json` — calendar ID enum

### Work completed

1. **`calendar-staging.sh` — full staging lifecycle script:**
   - `create` — creates event on Agent — Staging calendar (autopilot, no approval). Returns event_id.
   - `promote` — fetches event details, creates approval request with CAL_PROMOTE action type. Returns AID.
   - `execute` — called by approval-executor after approval. Validates approval, verifies event still exists on staging, moves atomically to Primary via Calendar API `move` endpoint.
   - `cleanup` — scans staging calendar for holds older than 48h, deletes them. Warns for holds within 6h of expiry. Best-effort (exit 0 on API failure).
   - `list` — lists current staging holds (id, summary, start time, created).

2. **`gws-token.sh` extended with 4 calendar helpers:**
   - `gws_calendar_create_event` — POST create
   - `gws_calendar_get_event` — GET single event
   - `gws_calendar_move_event` — POST move (atomic cross-calendar)
   - `gws_calendar_delete_event` — DELETE with HTTP status code return

3. **`approval-executor.sh` — `cal-promote` case added.** Same pattern as reminder-add/complete: dispatch to `calendar-staging.sh execute`, Telegram confirmation, Discord #audit-log entry.

4. **`awareness-check.sh` — check 7 added.** Runs `calendar-staging.sh cleanup` every 30 min (waking hours). Non-fatal — cleanup errors are logged but don't block other checks.

5. **E2e verified (2 full cycles):**
   - Test 1: create staging hold → promote → manual approve → execute → event on Primary, staging empty, approval marked executed
   - Test 2: create → promote → approve → approval-executor dispatches → event on Primary, Telegram + Discord notifications sent
   - Cleanup: confirmed no-op when staging is empty
   - Test events cleaned from Primary after verification

### Key decisions
- **Calendar API `move` endpoint over create+delete:** Atomic operation that preserves event metadata (attendees, reminders, attachments) and avoids partial-failure states. Single API call vs two.
- **Zero cooldown for CAL_PROMOTE:** Calendar holds are low-risk (they're already on a calendar the operator created). Same reasoning as Reminders.
- **Cleanup in awareness-check, not a separate cron:** 30-min check frequency is sufficient for 48h expiry. No need for a dedicated LaunchAgent.
- **Silent `reminders: {useDefault: false}` on staging events:** Prevents notification spam from staging holds — they're proposals, not commitments.

### Compound evaluation
- **Calendar API `move` as the promotion primitive:** The Google Calendar API's `move` endpoint is purpose-built for cross-calendar transfers. It preserves the event ID, which means any approval payload referencing the event ID remains valid after promotion. This is cleaner than the create+delete pattern used by some calendar integration libraries. Same endpoint works for future features (move back from Primary to Staging for "un-promote").

### Model routing
- Main session: Opus (implementation + testing)
- One Explore subagent for spec/infrastructure research

---

## 2026-03-20 — TOP-035 done (Phase 2 gate evaluation — PASS with conditions)

### Context inventory
- `Projects/tess-operations/action-plan.md` — M4 Phase 2 gate criteria (lines 167-174)
- `Projects/tess-operations/tasks.md` — TOP-031/032/033/034 acceptance criteria
- `_openclaw/state/gates/phase1-gate-2026-03-12.md` — prior gate format reference
- `_system/logs/ops-metrics.json` — job success rates and cost data
- `_system/logs/llm-health.json` — model reliability metrics
- `_system/logs/health-check.log` — API availability evidence
- `_openclaw/state/delivery-log.yaml` — dual delivery records Mar 17–20
- `_openclaw/state/apple-notes-tess.json`, `apple-reminders.json`, `apple-calendar.txt` — Apple snapshot data
- `_openclaw/state/approvals/` — approval records (empty)
- `_openclaw/config/email-triage-tuning.md` — operator calibration feedback

### Work completed

**TOP-035 (Phase 2 Gate Evaluation) — DONE:**

Evaluated 4-day window (Mar 17–20) against Phase 2 gate criteria from action-plan.md:

1. **Google Phase 2 (email triage, TOP-031): PASS** — Soak passed 2026-03-14 (106 emails, 0 failures, 0 invariant violations). 2 operator calibration corrections addressed. @Risk/High invariant holding, zero false positives. API transient failures (39/251 overall) are infrastructure noise, not triage errors. Draft creation deferred by design (Phase 2a = triage-only).

2. **Apple Phase 2 (Reminders write + Notes read, TOP-032/033): CONDITIONAL PASS** — Infrastructure validated (8/8 tests), Notes snapshot operational, zero data loss, zero TCC failures. But zero real-world reminder writes — no approval records exist. Soak condition: ≥3 real reminder operations through approval flow before Phase 3 Apple tasks proceed.

3. **Comms Phase 2 (Discord mirroring, TOP-034): PASS** — 100% dual delivery (telegram + discord) across Mar 17–20. 10 dual-delivery entries in log. Approval mirror e2e verified at deployment. Zero dropped Discord deliveries. Graceful degradation operational.

Gate record: `_openclaw/state/gates/phase2-gate-2026-03-20.md`

### Key decisions
- **Conditional pass pattern (reused from TOP-030):** Apple Reminders has validated infrastructure but zero production usage. Rather than blocking Google and Comms Phase 3 work, the gate passes with a soak condition scoped only to Apple Phase 3 tasks. This avoids holding unrelated downstream work.
- **Draft creation N/A (not a failure):** The action-plan criterion "drafts useful" assumed TOP-031 would include draft generation. Implementation chose Phase 2a (triage-only) first — classification must validate before drafts. The criterion is deferred, not failed.
- **API failures are infrastructure, not triage errors:** The 84.5% overall success rate (39 failures) sounds concerning but all failures correlate with "Anthropic API unreachable" episodes in health-check.log. Triage accuracy when the API is reachable has zero reported errors.

### Compound evaluation
- **Pattern: zero-usage conditional pass.** When infrastructure is fully validated (tests pass, deployment clean) but production usage hasn't occurred, a conditional pass with a minimum-usage soak is more honest than either a full pass (no data) or a block (infrastructure is ready). The soak condition is lightweight — it auto-clears as normal operations generate data points. Applicable to any future service where deployment and usage are decoupled.

### Model routing
- Main session: Opus (gate evaluation requires cross-spec reasoning, evidence synthesis, judgment calls — same as TOP-030)
- One Explore subagent for spec/gate-criteria research (saved main context from loading full action-plan)
- No Sonnet delegation — gate evaluation is reasoning-tier

---

## 2026-03-16d — TOP-034 done (Discord service output mirroring)

### Context inventory
- `Projects/tess-operations/design/tess-comms-channel-spec.md` — §5 delivery patterns, §5.2 approval mirror
- `_openclaw/config/discord-webhooks.json` — webhook URLs
- `_openclaw/config/discord-channels.json` — channel IDs
- `_openclaw/scripts/approval-request.sh` — extended with Discord mirror
- `_openclaw/scripts/approval-respond.sh` — extended with Discord edit + audit-log

### Work completed

1. **TOP-034 (Service output mirroring to Discord) — DONE:**
   - `discord-post.sh` — generic webhook posting library:
     - `post <channel-slug> <message>` — returns Discord message ID on stdout
     - `edit <channel-slug> <message-id> <new-content>` — edits existing message
     - Loads webhook URLs from `discord-webhooks.json`
     - Graceful skip (exit 0) for channels without webhooks — never blocks operations
     - 2000-char Discord limit enforced with truncation
   - Approval contract Discord integration:
     - `approval-request.sh` → posts audit mirror to #approvals, stores `discord_message_id`
     - `approval-respond.sh` → edits #approvals message with decision, posts to #audit-log
     - `approval-executor.sh` → posts execution entry to #audit-log
   - Webhooks created for #approvals and #audit-log (user via Discord UI)
   - Config updated: `discord-webhooks.json` now has 5 webhooks (morning-briefing, mechanic, opportunity-scout, approvals, audit-log)

2. **E2e verified:** Approval request → #approvals mirror with message ID → approve → #approvals edited to show decision → #audit-log entry posted. All three Discord API calls succeed.

### Key decisions
- **Webhooks over bot API:** Webhooks are stateless, don't require bot tokens in this session context, support edit-by-message-ID natively (`PATCH /webhooks/{id}/{token}/messages/{msg_id}`). Bot tokens are in OpenClaw config (not accessible from tess user).
- **Graceful degradation:** Channels without webhooks are silently skipped (exit 0, logged). This means existing cron scripts can add `discord-post.sh` calls without breaking if webhooks aren't configured yet. New webhooks can be added incrementally.
- **discord-post.sh as shared library:** Any script can source it. Morning briefing, email triage, vault health, etc. can add Discord posting by adding one `discord-post.sh post <channel> <message>` call alongside their existing `send_telegram` call. Additional webhooks created as needed.

### Compound evaluation
- **Webhook-based Discord posting is a reusable primitive:** `discord-post.sh` + `discord-webhooks.json` config gives any script Discord posting in one line. The graceful-skip pattern means scripts don't need to know which channels have webhooks — they just call and the library handles it. This pattern should be documented for future cron job authors.
- **TOP-035 unblocked:** All 4 Phase 2 gate dependencies (TOP-031/032/033/034) are now done. Phase 2 gate evaluation can begin.

### Model routing
- Session ran on Opus. No delegation.

---

## 2026-03-16c — TOP-032 done (Reminders write operations)

### Context inventory
- `Projects/tess-operations/design/tess-apple-services-spec.md` — §3.1 Reminders capabilities
- `_openclaw/bin/apple-cmd.sh` — cross-user wrapper (TOP-020)
- `_openclaw/scripts/apple-snapshot.sh` — read-side snapshot (TOP-033)
- `_openclaw/scripts/approval-request.sh` — extended with --payload
- `_openclaw/scripts/approval-check.sh` — extended with --validate-only

### Work completed

1. **TOP-032 (Reminders write operations) — DONE:**
   - `reminder-write.sh` — unified add/complete script with approval routing:
     - `add` to Inbox/Agent: autonomous (direct execution via apple-cmd.sh)
     - `add` to other lists (Personal, Work, Groceries): approval-gated with payload
     - `complete`: always approval-gated with payload
     - `execute AID`: called by approval-executor after approval, validates then executes
   - `approval-executor.sh` — generic approved-action dispatcher:
     - Scans for approved + cooldown-elapsed + not-yet-executed approvals with payloads
     - Dispatches to the appropriate handler (`reminder-write.sh execute`)
     - Sends Telegram execution confirmation or failure alert
     - Wired into awareness-check.sh as check 6
   - Extended `approval-request.sh` with `--payload` flag for storing execution context
   - Extended `approval-check.sh` with `--validate-only` flag — validates without marking executed

2. **Design fix: action-before-mark pattern:**
   - Original approval-check.sh marked `executed_at` before the action ran — if action failed, approval was burned
   - Fix: `--validate-only` checks without side effects, action runs, then full check marks executed
   - This pattern applies to all future gated operations (email send, calendar staging, iMessage)

3. **8/8 acceptance tests pass:**
   - T1-T2: autonomous routing (Inbox/Agent) — correct path, sudo fails in test context (expected)
   - T3-T4: gated routing + payload storage for non-standard lists
   - T5: complete always gated
   - T6-T7: validate-only vs full mark — executed_at only set on full check
   - T8: TOP-049 backward compatibility regression

### Key decisions
- **Executor is generic, not Reminders-specific:** `approval-executor.sh` dispatches any payload type — future services (email send, calendar staging) just add their handler to the case statement
- **Zero cooldown for Reminders:** Reminders are low-risk, so cooldown set to 0. Email send and iMessage retain 5-min default per spec.
- **Task routing deferred:** The "life-admin vs project at ≥80% accuracy" criterion is a classification decision in Tess's prompt (email triage, voice conversation), not a script. The routing infrastructure is ready — Tess decides Reminder vs vault inbox.

### Compound evaluation
- **Action-before-mark pattern:** When a gated action has side effects (writes to Apple services, sends email), validate the approval before acting but don't mark executed until the action succeeds. This prevents approval burn on transient failures. Applies to all approval-gated operations going forward.
- **Generic executor with payload dispatch:** The approval contract's `payload` field + `approval-executor.sh` case dispatch means new gated operations only need: (1) create approval with payload, (2) add a case to the executor. No new infrastructure per service.

### Model routing
- Session ran on Opus. No delegation — integrated work across approval contract and new domain scripts.

---

## 2026-03-16b — TOP-049 done (Approval Contract protocol)

### Context inventory
- `Projects/tess-operations/tasks.md` — task definitions and AC
- `Projects/tess-operations/design/tess-chief-of-staff-spec.md` — §9b Approval Contract spec
- `_openclaw/scripts/awareness-check.sh` — integration target
- `_openclaw/scripts/email-triage.sh` — reference for Telegram delivery pattern
- `_openclaw/scripts/cron-lib.sh` — shared infrastructure

### Work completed

1. **TOP-049 (Approval Contract protocol) — DONE:**
   - 5 scripts built in `_openclaw/scripts/`:
     - `approval-request.sh` — create AID-XXXXX, write JSON, send Telegram with inline keyboard buttons
     - `approval-respond.sh` — process approve/deny, update status, edit original Telegram message
     - `approval-check.sh` — wrapper enforcement gate (status + expiry + cooldown + double-exec protection)
     - `approval-poll.sh` — poll dedicated approval bot for inline button callbacks (getUpdates)
     - `approval-expiry.sh` — sweep pending approvals past 48h, auto-cancel, batch notification
   - State storage: `_openclaw/state/approvals/AID-XXXXX.json` (one file per approval)
   - Audit trail: `_openclaw/logs/approval-audit.log` (JSONL, append-only)
   - Security log: `_openclaw/logs/approval-security.log` (malformed AIDs, unauthorized execution attempts)
   - Anti-spam: >3 pending approvals triggers batch summary notification
   - Wired into `awareness-check.sh` as checks 4 (poll) and 5 (expiry)
   - **Architecture decision:** Option A — dedicated approval bot (separate from OpenClaw gateway bot) to avoid getUpdates conflict. Token not yet configured (BotFather step pending).
   - **10/10 acceptance tests pass:** approve path, double-exec block, deny path, expiry, expired-check, pending-check, malformed AID, non-existent AID, idempotent re-respond, anti-spam batching.

2. **Bug fix:** `date -jf` timezone parsing — macOS BSD date treats `Z` suffix as literal, parses time in local timezone. All approval scripts now use `TZ=UTC date -jf` for correct epoch conversion.

### Key decisions
- **Dedicated approval bot (Option A):** Avoids conflict with OpenClaw gateway's Telegram long-polling. Both bots post to the same chat (7754252365). Gateway bot handles conversations, approval bot handles approval lifecycle. Token to be configured via BotFather → macOS Keychain (`tess-approval-bot-token`).
- **Discord #approvals mirror deferred to TOP-034:** The AC mentions it but TOP-034 is the service output mirroring task — better to implement all Discord mirroring in one pass.
- **`executed_at` as double-execution guard:** Initially missed — `approved` status alone isn't sufficient since the status doesn't change to "executed". Added explicit `executed_at` null-check before allowing execution.

### Compound evaluation
- **`TZ=UTC date -jf` pattern:** Any macOS script parsing UTC ISO timestamps must use `TZ=UTC` prefix with BSD `date -jf`. The `Z` suffix is matched as a literal character, not interpreted as timezone. 4-hour offset (EDT) caused cooldown check to fail. Joins the `date +%-H` octal padding note as a macOS date gotcha.
- **Filesystem-based approval state:** JSON files + polling is simpler and more debuggable than a database for this use case. Each approval is independently inspectable (`jq . AID-xxxxx.json`). No daemon required — awareness-check polls every 30 min which is adequate for approval latency.

### Remaining prerequisite
- Create approval bot via BotFather, store token: `security add-generic-password -a tess-bot -s tess-approval-bot-token -w "<TOKEN>"`. Then set env var `TESS_APPROVAL_BOT_TOKEN` in the tess LaunchAgent environment.

### Model routing
- Session ran on Opus. No delegation — high-risk infrastructure requiring security judgment and integration design.

---

## 2026-03-16 — TOP-033 done, TOP-047 done, TOP-056 cron fix, daily-attention wikilink fix

### Context inventory
- `Projects/tess-operations/tasks.md` — task definitions
- `Projects/tess-operations/design/session-prep-design.md` — TOP-047 design
- `_openclaw/scripts/daily-attention.sh` — TOP-056 script
- `_openclaw/scripts/session-prep.sh` — TOP-047 fn1
- `_openclaw/scripts/awareness-check.sh` — debrief integration target

### Work completed

1. **TOP-033 (Apple Notes read/search):** Marked done — operator confirmed "Tess" folder created, snapshot operational.

2. **TOP-056 cron fix (StartCalendarInterval bug):**
   - Root cause: `StartCalendarInterval` triggers not firing on macOS 26.3.1 (Tahoe) despite machine never sleeping (`sleep = 0`). All 3 agents using `StartCalendarInterval` had `runs = 0`. All agents using `StartInterval` worked fine (awareness-check: 22 runs, email-triage: 15 runs).
   - Fix: converted plist from `StartCalendarInterval` (Hour:6, Minute:30) to `StartInterval` (1800s) + `RunAtLoad`. Script already had idempotency guard (`[ -f "$OUTPUT_FILE" ]`).
   - Deployed: bootout → xattr strip → bootstrap. Verified: `runs = 1`, exit code 0 (hit idempotency guard on first fire). Staging copy updated.
   - Note: `fif.attention` and `fif.capture` plists have the same bug — not fixed this session (separate project scope).

3. **TOP-056 wikilink fix:** Prompt template Source field now explicitly requires exact vault-relative paths from context brackets. Mar 12–15 artifacts had broken wikilinks (`[[goal-tracker]]` instead of `_system/docs/goal-tracker.yaml`). Mar 16 self-corrected but prompt now enforces it.

4. **TOP-047 fn1 (session-prep.sh) — validated + improved:**
   - Script existed but was untested. Ran against tess-operations and agent-to-agent-communication.
   - Fixed: summary extraction (heading suffix), blocker filtering (only blocked/at-risk rows), date display (clean date), suggested first command (active task → actionable, else next_action).

5. **TOP-047 fn3 (session-debrief.sh) — built:**
   - New script: cursor-based detection of new run-log entries per project, Telegram HTML notification with session date/summary/key decisions/commits.
   - Idempotent via cursor files in `_openclaw/state/last-run/debrief-<project>`. Skips entries older than yesterday.
   - Wired into awareness-check.sh as Check 3 (runs every 30 min).
   - Tested: fires correctly, cursor prevents duplicates, all-projects scan works.

6. **TOP-047 marked done.** All 3 functions operational: fn1 (session prep), fn2 (meeting prep — already done), fn3 (debrief).

### Key decisions
- **StartCalendarInterval abandoned for tess LaunchAgents:** macOS Tahoe appears to have a bug where CalendarInterval triggers never fire. All future tess agents should use `StartInterval` + idempotency guard pattern.
- **Debrief integrated into awareness-check rather than standalone cron:** Reduces LaunchAgent proliferation. 30-min polling is adequate for a notification-only function.

### Compound evaluation
- **macOS Tahoe StartCalendarInterval bug:** Documented pattern — `StartCalendarInterval` triggers have `runs = 0` while `StartInterval` works fine on same machine, same xattr state, same user domain. Should be captured as a known platform issue. Affects `fif.attention` and `fif.capture` (separate project scope).

### Model routing
- Session ran on Opus. No delegation to Sonnet — all work was infrastructure debugging and bash scripting requiring judgment calls (root cause analysis, design decisions).

---

## 2026-03-15 — Multi-project session: ops fixes, research batch, feed pipeline, A2A-014, AKM decay tuning

### Infrastructure Fixes
- **Telegram briefing failure:** Gateway restarted (`launchctl kickstart -k system/ai.openclaw.gateway`). Telegram provider had silently died after Mar 14 18:15 UTC. Root cause: provider connection death + `bestEffort: true` masking + `delivery.to` bug in v2026.2.25. DM pairing re-established.
- **Daily attention UTC bug:** Fixed `today()` in `crumb-dashboard/packages/api/src/adapters/daily-attention.ts` — was using `toISOString()` (UTC), causing daily plan to vanish at 8 PM ET. Now uses `America/New_York` timezone. Committed `eb385b9`, pushed to crumb-dashboard.
- **Overnight research staging gate:** Changed `overnight-research.sh` so ALL streams stage to `_openclaw/research/output/` instead of writing directly to `Sources/research/`. Added research output count to `session-startup.sh`. Reviewed and promoted 27 overnight briefs, routed 2 meeting preps to `Domains/Career/accounts/`, discarded 1.
- **Tess SOUL.md updated:** Critic gate added to Quality Review section. Deployed to openclaw home. Group write permissions set on `/Users/openclaw/.openclaw/` for future deployments.

### Research Batch (cloud agent infrastructure)
- Processed `cloud-agent-infra-landscape.md` from `_inbox/` → `Sources/research/`
- 4 parallel researcher dispatches (background agents):
  - Cloudflare Sandbox SDK → proceed to spike (~$25/mo, AI tokens dominate)
  - MCP Feasibility → layer alongside bridge, Phase 1 < 1hr
  - Perplexity Search API → proceed to impl ($0.005/query)
  - Distributed Agent Experiment → use KV not R2, Workflows for orchestration
- OpenClaw upgrade runbook dispatched → `_openclaw/research/openclaw-upgrade-runbook-2026-03-15.md`
- Runbook reviewed: fixed #43406 status (downgraded to OPEN — unconfirmed fix) and memoryFlush config path in emergency procedure

### Feed Pipeline Run
- 11 inbox items + 5 dashboard-queued → 12 signal-notes promoted, 1 Tier 2 action extracted
- MOC moc-signals updated (12 new Core entries + synthesis section written)
- Calibration logged, FIF sync-back complete

### A2A-014: Critic Skill (DONE)
- Built `.claude/skills/critic/SKILL.md` — declares `review.adversarial.standard` capability
- Created `_system/schemas/briefs/review-brief.yaml` — shared schema
- Test run against `cloudflare-sandbox-burst-compute.md`: REVISE recommendation (C-1: token estimates 3-5x low, 3 significant, 2 minor, 4/5 citations verified)
- Updated routing: reviews colocate next to artifact (Sources/, staging, or project reviews/)
- Capabilities index rebuilt (8 capabilities)
- Tess orchestration wired: critic gate in Quality Review section of SOUL.md

### Inbox Processing
- `_inbox/`: PIIA analysis → `Domains/Career/`, osc spec v2 → `Projects/opportunity-scout/design/`, upgrade research → `_openclaw/research/` (reactive queue), wisdom-library deferred
- `_openclaw/outbox/`: 3 items deleted (stale, not needed)

### AO-002 Soak Check
- 3 of 5 required live runs complete, all passing (status: ok, 6-7 items/cycle)
- Parse warnings are urgency-enforcement guardrails firing correctly, not failures
- 2 more clean runs needed (Mar 16-17) to close acceptance criterion

### Compound Evaluation
- **Research staging gate pattern:** overnight research output now stages for operator review before vault entry. Reduces unreviewed content in vault, adds visibility to session startup. Applicable to any future automated content pipeline.
- **Critic colocated routing:** reviews live next to artifacts they review. Simpler than centralized `_system/reviews/`. Promotes discoverability via Obsidian backlinks.

### Late Session: Dashboard + AKM Tuning
- **Dashboard gardening panel:** Unlinked sources KPI now shows only stale (>30d) count. Added age buckets (recent/settling/stale) with breakdown. 62 "unlinked" was accurate but misleading — actual stale count is 0.
- **AKM decay model retuned:** Added "reference" tier (730d half-life) for software-dev, dns, networking, security. Moved history + psychology to timeless. Fast tier now only customer-engagement + training-delivery. Action-plan doc updated.

### Model Routing
- All work on Opus (main session). 4 research dispatches used Opus subagents. No Sonnet delegation this session — all tasks required judgment-class reasoning.

---

## 2026-03-17 — Signal: Codex subagent API surface confirmed stable

**Phase:** IMPLEMENT (cross-project signal)

Anthropic published official docs for Claude Code subagent/custom agent support. The `--agents` CLI flag for session-scoped agents and `permissionMode` field are documented and stable.

**Impact on TOP tasks:**
- **TOP-049 (Codex integration):** API surface confirmed — `--agents` accepts JSON with frontmatter fields. Can proceed with integration work.
- **TOP-032 (subagent spawn mechanics):** Constraint documented — subagents cannot spawn other subagents. Chain pattern (main → subagent → return → next) is the supported model.

See compound insight: [[Sources/insights/codex-subagent-custom-agent-validation|codex-subagent-custom-agent-validation]]

---

## 2026-03-19 — Signal: Sycophancy as systemic agent failure mode

**Phase:** IMPLEMENT (cross-project signal)

**Signal:** [[sycophancy-are-you-sure-problem]] — Frontier models change answers ~60% of the time when challenged, even when correct. RLHF training rewards agreement over accuracy.

**Applicability:** Tess's context model (tess-context.md) currently carries project state pointers but not Danny's decision frameworks, risk tolerance, or domain constraints. Without embedded context, Tess has nothing to "stand on" when challenged — she'll defer rather than push back. This matters for autonomous operations where Tess makes consequential triage decisions.

**Action:** Evaluate at next project session. Advisory — not pre-approved for implementation.

---

## 2026-03-19 — Signal: Prompt complexity kills structured reasoning in production

**Phase:** IMPLEMENT (cross-project signal)

**Signal:** [[prompt-complexity-dilutes-structured-reasoning]] — STAR reasoning framework: 100% accuracy isolated → 0-30% in 60+ line production prompts. Competing instructions force conclusion-first output, reversing reasoning order.

**Applicability:** Tess agent configurations combine reasoning frameworks with operational instructions, format rules, and style guidelines. If structured reasoning degrades under prompt complexity, Tess's production prompts may be silently undermining reasoning quality. Testing in isolated conditions doesn't surface this — must validate in full production context.

**Action:** Evaluate at next project session. Advisory — not pre-approved for implementation.
