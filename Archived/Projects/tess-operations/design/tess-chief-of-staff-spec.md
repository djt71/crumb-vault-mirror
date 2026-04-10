---
project: tess-operations
type: specification
domain: software
skill_origin: systems-analyst
created: 2026-02-25
updated: 2026-02-26
status: active
tags:
  - tess
  - openclaw
  - operations
---

# Tess: From Relay to Chief of Staff — Capability Specification

## 1. Executive Summary

Tess currently operates as a Telegram relay with a personality: inbox triage, status checks, bridge message handling, and x-feed-intel digest delivery. That's roughly 15-20% of what OpenClaw can do as of v2026.2.24. The always-on nature is the killer feature, and it's barely being touched.

This document defines the target operating model: Tess becomes an active operator who works alongside you — anticipating needs, maintaining infrastructure, preparing intelligence, and making every Crumb session and every customer conversation more effective.

**The governance boundary:** Tess operates. Crumb governs. Tess runs scheduled work, monitors health, delivers intelligence, and processes feedback. Crumb owns architecture, specifications, vault structure, and deep synthesis. You decide what crosses the boundary.

---

## 1b. Existing Infrastructure

This spec builds on completed projects:
- **openclaw-colocation** (DONE) — Studio Mac M3 Ultra, dedicated `openclaw` user (uid 502), gateway on loopback (127.0.0.1:18789), LaunchDaemon supervisor, Tier 1 hardening, filesystem IPC bridge
- **crumb-tess-bridge** (DONE) — Filesystem-based async dispatch protocol between Crumb and Tess, 37 tasks, 897 tests, operational since 2026-02-22
- **feed-intel-framework** (TASK phase) — Pipeline codebase at `/Users/tess/openclaw/feed-intel-framework/`, M2 migration in progress
- **tess-model-architecture** (DONE) — Haiku 4.5 voice agent, qwen3-coder:30b mechanic agent, health-check with local failover

The gateway currently runs OpenClaw v2026.2.17. The upgrade to v2026.2.25 is a prerequisite (§14 Week 0) with a peer-reviewed runbook ready.

---

## 2. Current State

| Function | How It Works | Value |
|----------|-------------|-------|
| Telegram relay | Voice agent on Haiku 4.5 | Chat interface |
| Inbox triage | Reads `_openclaw/inbox/` | Routes items to you |
| Bridge dispatch | `_openclaw/inbox/` → `_openclaw/outbox/` | Async task relay |
| X-feed-intel digest | Pipeline delivers to Telegram | Content delivery |
| Quick lookups | Status checks, vault reads | Lightweight queries |
| Health-check cron | External launchd script | Failover to local model |
| Mechanic (background) | qwen3-coder:30b on Ollama | Heartbeats, cron |

The mechanic agent is barely utilized beyond heartbeats. The voice agent handles conversations but initiates nothing proactively.

### Unused OpenClaw Capabilities (v2026.2.24)

- **Cron jobs** — no scheduled jobs beyond the external health-check launchd script
- **Subagent spawning** — `/subagents spawn` available since v2026.2.17, unused
- **Skills ecosystem** — one custom skill (crumb-bridge); relevant bundled/ClawHub skills unused (`obsidian`, `github-integration`, `news-aggregator`, `agent-browser`)
- **Webhooks** — no inbound webhooks configured (`/hooks/<name>`)
- **Browser control** — CDP-managed Chrome instance available, unused
- **1M context window** — opt-in via `params.context1m: true`, unevaluated
- **Lobster workflows** — typed local-first pipeline runtime, unevaluated (see §7)

---

## 3. Target Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   TESS (Chief of Staff)                   │
│                                                           │
│  PROACTIVE LAYER (heartbeat + cron)                       │
│  ├─ Vault health check (nightly)                         │
│  ├─ Pipeline monitoring (hourly)                         │
│  ├─ Morning briefing (daily)                             │
│  ├─ Mirror sync verification (nightly)                   │
│  └─ Session prep staging (pre-session)                   │
│                                                           │
│  REACTIVE LAYER (heartbeat awareness + webhooks)          │
│  ├─ Inbox/outbox monitoring (30-min heartbeat)           │
│  ├─ Bridge dispatch relay                                │
│  ├─ Webhook event processing                             │
│  ├─ Self-healing service restarts                        │
│  └─ Telegram conversation (direct interaction)           │
│                                                           │
│  INTELLIGENCE LAYER (overnight + on-demand)               │
│  ├─ Account prep briefs                                  │
│  ├─ Competitive/industry monitoring                      │
│  ├─ Feed-intel research deep-dives                       │
│  ├─ Builder ecosystem radar                              │
│  ├─ Weekly connections brainstorm                        │
│  └─ Post-session debrief                                 │
│                                                           │
│  OPERATIONAL LAYER (Lobster workflows — if validated)     │
│  ├─ vault-health.lobster                                 │
│  ├─ pipeline-health.lobster                              │
│  ├─ session-prep.lobster                                 │
│  └─ account-brief.lobster                                │
│                                                           │
└──────────────────────┬───────────────────────────────────┘
                       │
            ┌──────────┼──────────┐
            ▼          ▼          ▼
         Crumb      Pipelines    You
       (architect)  (automated)  (human)
```

---

## 4. HEARTBEAT.md — The Awareness Layer

Heartbeat is fundamentally different from cron. Cron is clockwork — it runs whether or not anything interesting is happening. Heartbeat is awareness — it checks in, applies judgment, stays quiet if nothing matters.

**Design principle:** Don't put open-ended tasks in HEARTBEAT.md. Put concrete checks with clear thresholds. "Scan for anything interesting" wastes tokens. "Alert if inbox items are >2 hours old" is cheap and actionable.

**Cheap-checks-first pattern:** Run a lightweight shell check before involving the LLM. Shell scripts do state checks (is service running? are files newer than X?). The LLM only fires when there's actual signal to evaluate.

**Scope cap:** HEARTBEAT.md must contain no more than 12 entries per agent. Adding a new entry requires removing or consolidating an existing one. Review HEARTBEAT contents monthly and retire stale or low-value checks. This prevents the natural accretion problem where monitoring lists grow until they're expensive and noisy. Entries that delegate to a consolidated script (e.g., fif-health.sh checking 7 signals as a single binary-output call) count as one entry regardless of internal complexity — the cap governs cognitive load on the local model, not the number of underlying checks.

### HEARTBEAT.md Mechanics

HEARTBEAT.md is an OpenClaw-native feature. Each agent has a HEARTBEAT.md file in its agent directory (e.g., `~/.openclaw/agents/<agent>/HEARTBEAT.md`). The gateway evaluates it on the agent's heartbeat interval — the file content becomes the system prompt for a lightweight LLM call. The agent checks the listed conditions and responds with `HEARTBEAT_OK` (silent) or an alert message (delivered via Telegram).

**Cheap-checks-first implementation:** HEARTBEAT.md entries reference shell commands that the agent runs via exec tool before the LLM evaluates results. The LLM only fires when shell output contains signal worth interpreting. Example: `ls -t _openclaw/inbox/ | head -5` runs in exec; if the directory is empty, the LLM skips that check. This keeps HEARTBEAT_OK ticks at minimum token cost.

### Voice Agent HEARTBEAT.md

- Frequency: every 30 min during waking hours (8 AM–11 PM ET)
- Target: Telegram
- Model: Haiku 4.5
- Cost: ~$0.01-0.03 per tick if HEARTBEAT_OK (~$0.50-1.50/day)

```markdown
# Heartbeat checklist

- Check _openclaw/inbox/ for new items. If anything pending and older than 2 hours, alert Danny.
- Check _openclaw/outbox/ for completed dispatch results not yet relayed. Relay them.
- If a pipeline service (bookmark-puller, attention-clock, feedback-listener) has stopped, alert Danny.
- If the vault mirror's last commit is >24 hours stale, note it.
- If there's a new x-feed-intel digest not yet summarized, flag it.
- If nothing needs attention, reply HEARTBEAT_OK.
```

### Mechanic Agent HEARTBEAT.md

- Frequency: every 60 min, 24/7
- Target: none (silent unless alerting)
- Model: qwen3-coder:30b (local, free)

```markdown
# Heartbeat checklist

- Verify all 3 pipeline launchd services running.
- Check disk usage for feed-intel SQLite DB + vault files.
- Verify Ollama is responsive (model health).
- If any check fails, alert via Telegram.
- Reply HEARTBEAT_OK.
```

**Post-ownership-transition evolution (Phase B+):** After feed-intel migrates to OpenClaw cron jobs, the "3 pipeline launchd services" check is replaced by the machine-checkable health signals defined in the feed-intel ownership proposal §5: `last_capture_run_at`, `last_attention_run_at`, `queue_depth`, `last_successful_delivery_at`, `last_processed_feedback_at`, `error_rate_by_adapter`, `daily_token_spend`. Each has a defined threshold and alert behavior. See ownership proposal for full signal table.

---

## 5. Proactive Layer — Scheduled Operations

### 5.1 Morning Briefing

**Problem:** Every day starts with manual orientation — check project states, review overnight output, find what's pending.

**What Tess delivers at 7 AM via Telegram:**
- Project status (read run-logs for active projects, extract latest entries)
- Overnight pipeline output (digest count, high-priority flags)
- **Feed-intel status** (post-ownership-transition, Phase B+): explicitly read the latest feed-intel digest file from the previous day's attention run. Include a status line: last capture run time, items triaged, delivery confirmation, health signal status. Required because triage runs in `--session isolated` — the morning briefing agent has no context unless it reads the digest output file directly. See feed-intel ownership proposal §5.
- Bridge inbox status (pending dispatches, completed overnight)
- Vault health from overnight gardening run
- Pipeline alerts from overnight monitoring
- "This day" marker — what you were working on 1 week, 1 month, 3 months ago (single git log command, essentially free)

**Implementation:**
```
openclaw cron add \
  --name "Morning briefing" \
  --cron "0 7 * * *" \
  --tz "America/Detroit" \
  --session isolated \
  --message "Morning briefing. Read active project run-logs, check _openclaw/ for overnight activity, summarize pending items. Top 3 priorities, blockers, one recommended first action. Check git log for what was happening 1 week, 1 month, 3 months ago — include a single 'this day' line." \
  --model "anthropic/claude-haiku-4-5" \
  --announce \
  --channel telegram
```

**Community validation:** Nathan Broadbent's Reef agent runs a daily briefing at 8 AM. Radek Sienkiewicz's "50 Days" video demonstrates routing briefings to a dedicated Discord channel via Sonnet. The DataCamp CRM pattern adds calendar-aware meeting prep to the morning brief. All confirm this as the highest-leverage single cron job.

### 5.2 Nightly Vault Health

**What Tess does at 2 AM:**
- Run `vault-check.sh`, parse results
- Scan for broken wikilinks (obsidian-cli)
- Flag notes with missing required frontmatter fields
- Identify `status: active` notes unmodified for 30+ days
- Stage summary in `_openclaw/inbox/vault-health-<date>.md`
- Include in morning briefing

**Implementation:** Cron on mechanic agent (qwen3-coder, free). Delivery folded into morning briefing.

### 5.3 Pipeline Monitoring

**What Tess does hourly:**
- Verify all 3 launchd services running
- Check if daily digest was generated by expected time
- Self-healing: if a service is down and it's a known-safe restart, attempt restart and verify
- If restart succeeds: log silently to `_openclaw/logs/pipeline-watchdog.log`
- If restart fails: alert via Telegram
- Weekly: cost telemetry summary (API spend vs budget ceiling)

**Implementation:** Hourly cron on mechanic (free). Alert-only via Telegram.

**Community validation:** Nathan Broadbent's Reef agent uses this pattern for Kubernetes pods — restart, confirm fix held, only ping when the problem persists. Same pattern, applied to launchd.

### 5.4 Mirror Sync Verification

**What Tess does nightly:**
- Compare latest commit SHA in vault vs mirror repo
- If diverged, alert
- If the hook failed silently, you know within 24 hours

**Implementation:** Single cron on mechanic. Trivial.

### 5.5 Session Prep and Debrief

**Pre-session (on demand via Telegram):** You tell Tess "Prepping for feed-intel-framework." She reads the run-log, extracts last session date, last completed task, next pending task, blockers. Checks for dispatch results, relevant feed-intel items, vault-check failures. Produces a context injection file structured for Crumb consumption.

**Post-session (triggered by git commit webhook):** Tess reads the updated run-log, summarizes accomplishments, identifies handoff items, updates her HEARTBEAT.md if new monitoring conditions were created. Sends Telegram summary.

**The effect:** Crumb sessions start faster with better context. Session continuity improves without manual handoff notes.

---

## 6. Reactive Layer — Event-Driven Operations

### 6.1 Event Integration Map

Events reach Tess via two mechanisms depending on origin:

**Local events** (loopback — no networking changes needed):
The OpenClaw gateway exposes `/hooks/wake` and `/hooks/<name>` endpoints on 127.0.0.1:18789. Local processes and git hooks can POST directly. Authentication via `Authorization: Bearer <token>` header.

**External events** (GitHub — requires networking decision):
The gateway is bound to loopback with Tailscale off. External services cannot POST directly. Options:
1. **Cron-based polling** (recommended for Week 1-2) — Mechanic agent polls `gh` CLI on a schedule. Simple, no networking changes, matches existing security posture.
2. **Hookdeck CLI tunnel** — Outbound WebSocket from Studio to Hookdeck relay. No port exposure, persistent URLs, retry/dedup built in. Evaluate after polling proves the value of GitHub events.
3. **Tailscale Funnel** — Public HTTPS via Tailscale. Requires enabling Tailscale (currently off per colocation hardening). Higher blast radius change.

**Decision: Start with polling (option 1). Evaluate tunnel/Funnel at Week 2+ if polling latency is insufficient.**

| Source | Event | Mechanism | Tess Action |
|--------|-------|-----------|-------------|
| GitHub (x-feed-intel) | Push, CI failure | Cron polling (`gh`) | Alert on failure, summarize changes |
| GitHub (feed-intel-framework) | Push, CI failure | Cron polling (`gh`) | Alert on failure, summarize changes |
| GitHub (crumb-vault-mirror) | Push | Cron polling (`gh`) | Confirm mirror sync succeeded |
| x-feed-intel pipeline | Digest ready | Local hook (`/hooks/wake`) | Surface digest summary to Telegram |
| x-feed-intel pipeline | Service failure | Heartbeat detection | Alert + attempt restart if safe |
| launchd | Service crash | Heartbeat detection | Alert via heartbeat |
| Crumb session | Post-commit hook | Local hook (`/hooks/wake`) | Post-session debrief |

### 6.2 Telegram Topic Routing

**Prerequisite:** Telegram topics require a supergroup, not a 1:1 chat. If Tess currently operates via direct messages, migration steps: (1) create a Telegram group, (2) upgrade to supergroup, (3) enable topics in group settings, (4) add Tess bot to group, (5) configure OpenClaw to target group chat ID + topic thread IDs. Verify `message_thread_id` routing works with the current OpenClaw Telegram integration before building the topic structure.

Route different output types to separate Telegram topics instead of one flat chat. OpenClaw supports this natively via `message_thread_id`.

| Topic | Content |
|-------|---------|
| #tess-general | Conversation, quick lookups |
| #briefings | Morning/evening briefings, session prep |
| #alerts | Pipeline failures, vault issues, stale items |
| #intel | Feed-intel digests, account intelligence, research briefs |
| #crumb-dispatch | Bridge dispatch results, session debriefs |

Cron jobs target specific topics. Alerts don't clutter conversation.

**Community validation:** Radek Sienkiewicz's "50 Days" video (item #15 of 20 workflows) demonstrates this pattern with Discord channels. Same architectural principle.

---

## 7. Operational Layer — Lobster Workflows

**Status: UNVALIDATED.** Lobster is OpenClaw's built-in workflow engine — typed, local-first pipeline runtime with YAML definitions, approval gates, and resume tokens. Before planning around it:

1. Verify Lobster is available in v2026.2.24
2. Run a trivial test workflow
3. If not ready, achieve the same goals with shell scripts + cron

**Why Lobster matters if it works:** Deterministic execution, data flows as JSON between steps, LLM only fires when needed (cheap-checks-first formalized), resume tokens on failure, approval gates for side effects.

**Candidate workflows:**
- `vault-health.lobster` — shell checks → parse failures → LLM summarize (only on failure)
- `pipeline-health.lobster` — service checks → alert if down
- `session-prep.lobster` — read files → search vault → LLM synthesize → stage to inbox
- `account-brief.lobster` — read dossier → web search → LLM synthesize → deliver

If Lobster isn't mature, these become shell scripts calling the LLM via `openclaw invoke` at the synthesis step. Same outcome, less elegant.

---

## 8. Intelligence Layer

### 8.1 Overnight Research Sessions

Items flagged with `research` in x-feed-intel get queued for overnight processing. Tess runs an isolated session: reads the enriched context file, uses browser tool to follow links, gathers related sources, writes a structured brief. Brief staged in `_openclaw/inbox/` for Crumb review or direct reading.

**Model:** Haiku 4.5 (reasoning quality needed, cost is ~$0.01-0.05/session).

### 8.2 Competitive & Account Intelligence

**Weekly cadence, rotating through account batches:**
- Company monitoring: acquisitions, layoffs, initiatives, job postings (signals investment areas), technology mentions (DNS security, IPAM, network transformation)
- Competitor monitoring: BlueCat, EfficientIP, Men&Mice — announcements, features, partnerships, pricing
- Industry trends: DDI market, DNS security threat landscape, regulatory changes
- Dossier maintenance: surface findings alongside existing customer-intelligence dossiers, stage updates in `_openclaw/inbox/`

**Delivery:** Weekly "Intelligence Brief" delivered Sunday evening.

### 8.3 Builder Ecosystem Radar

Track builders producing tools and patterns relevant to the stack. Not a feed dump — curated for actionable patterns.

**Weekly scan targets:** builder X profiles (0xSero, Nathan Broadbent, steipete), OpenClaw Discord showcase, r/LocalLLaMA, ClawHub trending, inference provider announcements.

**Output:** Weekly "Builder Intel" brief filtered for relevance to active projects, Tess capabilities, and professional needs.

### 8.4 Connections Brainstorm (Weekly)

Read recent additions across all domains (last 7 days). Read current project states. Read recent feed-intel items. Look for unexpected connections, patterns, contradictions, ideas worth pursuing. Stage findings in `_openclaw/inbox/brainstorm-<date>.md`.

**Model choice matters:** This is not a Haiku task. Use Sonnet 4.5 or Opus for a single weekly run. Cost: a few dollars per week. Value: cross-domain pattern detection that's impossible to do manually at scale.

**Design rationale:** This is the highest-leverage non-obvious pattern in the spec. Nathan Broadbent's Reef agent runs deep analysis jobs overnight (velocity assessment at 1 AM, brainstorm at 4 AM), validating the general approach of using off-hours for creative exploration across accumulated notes.

### 8.5 Feed-Intel Feedback Analysis

Weekly: analyze feedback decisions from past 7 days. Identify which topics consistently get promoted vs ignored. Suggest topic weight adjustments, new topics, dead topics. Stage recommendations in `_openclaw/inbox/feed-intel-tuning-<date>.md`.

**Design rationale:** Self-tuning through operator behavior. The system learns what matters by observing which items you promote vs ignore, then adjusts accordingly.

### 8.6 KB Gardening

Beyond vault-check (structural health), there's content-level maintenance:

- **Cross-reference detection:** Scan KB notes weekly for topics that should be linked but aren't
- **Tag gap analysis:** Identify notes with `#kb/` tags not linked from any MOC
- **Source currency:** For notes citing external sources, check if sources have updated
- **Digest-to-KB pipeline:** When feed-intel surfaces saved items, draft skeleton KB notes for Crumb to finalize

---

## 9. Governance Boundaries

### What Tess Does (Operational)

- Run scheduled maintenance, monitoring, and intelligence gathering
- Write to `_openclaw/` directories (inbox, outbox, logs, scripts)
- Restart known-safe services after failure
- Deliver briefings, alerts, and intelligence via Telegram
- Write and maintain her own operational scripts in `_openclaw/scripts/`
- Draft skills for herself (staged for approval, never auto-installed)
- Update her HEARTBEAT.md based on operational patterns

### What Tess Does NOT Do (Governed)

- Modify governed project files (specs, plans, task lists)
- Make architectural decisions
- Push to production repos without review
- Auto-install third-party skills
- Modify Crumb's `.claude/skills/`, CLAUDE.md, or vault structure
- File content into MOCs, KB notes, or domain overviews (flag and stage only)
- Execute research promotion decisions (flag candidates, operator confirms)

### Coding Boundary

Tess writes operational code for herself (monitoring scripts, automation helpers, data processing utilities) within `_openclaw/`. She does not write governed project code. She proposes; you approve. The pattern: identify gap → draft script/skill → stage in `_openclaw/staging/` → you review → she installs within her workspace.

---

## 9b. Standardized Approval Contract

All sibling specs (Google services, Apple services, communications channel) reference "approval required" for sensitive operations. This section defines the canonical approval contract. Sibling specs inherit this contract and may extend it with service-specific fields, but must not contradict it.

### Approval Object Schema

Every approval request must contain:

| Field | Type | Description |
|-------|------|-------------|
| `approval_id` | string | Unique ID (`AID-<5-char>`) generated per request |
| `action_type` | string | Operation category: `SEND_EMAIL`, `CAL_PROMOTE`, `REMINDER_COMPLETE`, `IMESSAGE_SEND`, etc. |
| `service` | string | Originating spec: `google`, `apple`, `comms`, `chief-of-staff` |
| `target` | string | Recipient, calendar event, reminder, etc. |
| `summary` | string | 1–2 sentence description of what will happen |
| `original_context` | string | Verbatim snippet from triggering content (1–2 key sentences) — prevents summaries from sanitizing red flags |
| `risk_level` | string | `low`, `medium`, `high` |
| `preview` | string | First 2–3 lines of draft/content (where applicable) |
| `expires_at` | datetime | Default: 48 hours from creation. Configurable per action type. |

### Interaction Channel

Telegram is the single approval interaction surface. Danny taps approve/cancel via inline buttons. Discord receives a read-only audit mirror (see comms spec §5.2).

### Timeout Behavior

If an approval request is not acted on within `expires_at`, it auto-cancels. A Telegram batch summary is sent: "N approval requests expired." Expired items are logged with `status: expired`.

### Anti-Spam / Batching

If more than 3 approval requests are pending simultaneously, Tess bundles them into a single summary message with individual approve/cancel per item. This prevents approval fatigue from burst operations (e.g., 8 email triage approvals in 10 minutes).

### Approval Logging

All approval decisions are appended to the unified audit trail (`00_System/Agent/Audit/` in Drive, with local fallback to `_openclaw/logs/approval-audit.log`). Each entry records: `approval_id`, `action_type`, `status` (approved/cancelled/expired), `decided_at`, `executed_at`.

### Cooldown

Default: 5-minute cooldown between approval and execution (cancel still possible during cooldown). Cooldown may be reduced to 0 for low-risk actions (e.g., promoting a staging calendar hold) at implementation time.

---

## 10. Model Configuration

| Task Type | Agent | Model | Rationale |
|-----------|-------|-------|-----------|
| Conversation + briefings | voice | Haiku 4.5 | Persona matters, reasoning adequate |
| Research + intelligence | voice (isolated) | Haiku 4.5 | Reasoning quality, ~$0.01-0.05/session |
| Connections brainstorm | voice (isolated) | Sonnet 4.5 | Synthesis quality justifies weekly cost |
| Vault gardening | mechanic | qwen3-coder:30b | Structured tool tasks, free |
| Pipeline monitoring | mechanic | qwen3-coder:30b | Simple health checks, free |
| Service restarts | mechanic | qwen3-coder:30b | Operational, free |
| Git monitoring | mechanic | qwen3-coder:30b | Simple comparison, free |

**1M context:** Evaluate for specific tasks (deep research sessions, vault-wide analysis) per-job via `params.context1m: true`. Do not enable globally.

---

## 11. Cost Analysis

| Layer | Agent | Model | Frequency | Est. Monthly |
|-------|-------|-------|-----------|-------------|
| Voice heartbeat | voice | Haiku 4.5 | Disabled (M1) | $0 |
| Awareness check | mechanic | qwen3-coder (local) | 30 min, waking hours | $0 |
| Mechanic heartbeat | mechanic | qwen3-coder | 60 min, 24/7 | $0 |
| Morning briefing | voice | Haiku 4.5 | Daily | $1-3 |
| Vault gardening | mechanic | qwen3-coder | Nightly | $0 |
| Pipeline monitoring | mechanic | qwen3-coder | Hourly | $0 |
| Overnight research | voice | Haiku 4.5 | 2-3x/week | $1-3 |
| Account intelligence | voice | Haiku 4.5 | Weekly batches | $2-5 |
| Session prep/debrief | voice | Haiku 4.5 | Per Crumb session | $1-3 |
| Connections brainstorm | voice | Sonnet 4.5 | Weekly | $2-8 |
| **Current baseline** | voice | Haiku 4.5 | Conversation only | **$8.70** |
| **Projected chief-of-staff total** | | | | **$7-25** |
| Feed-intel operations (Phase B+) | voice (isolated) | Haiku 4.5 | Daily capture + triage + digest | ~$45 |
| **Projected total with feed-intel** | | | | **$52-70** |

Voice heartbeat is disabled for M1 — all monitoring migrated to the mechanic heartbeat (binary checks, $0) and a local-model awareness-check cron job (content-aware checks, $0). This eliminates the single largest cost driver ($15-45/month → $0). The voice agent fires only for Telegram conversations and scheduled cron jobs. See `heartbeat-cost-optimization-recommendation.md` for rationale. The native `heartbeat.model` override is broken (OpenClaw issues #9556, #14279, #22133); the `--session isolated` + `--model` cron workaround is used instead.

The mechanic absorbs a huge amount of operational work for free. The range depends on research volume. The feed-intel cost is governed separately (see feed-intel ownership proposal §3.9 — $1.50/day hard cap) and only activates after the ownership transition (Phase B). The §13 rollback plan cost ceiling accounts for the combined total.

### Per-Job Token Budgets

Provider-level API caps (§12) catch runaway spend, but per-job ceilings prevent any single run from consuming disproportionate tokens. Any job that hits its ceiling must produce a partial result and log that it truncated — no silent overruns.

| Job | Max tokens/run | Frequency | Truncation behavior |
|-----|---------------|-----------|---------------------|
| Morning briefing | 15k | Daily | Truncate lowest-priority sections, note what was dropped |
| Vault health | 10k | Nightly | Chunk if vault-wide; summarize per-chunk |
| Pipeline monitoring | 5k | Hourly | Structural checks only; skip synthesis if over budget |
| Research session | 50k | 2-3x/week | Produce partial result, flag incomplete sections |
| Connections brainstorm | 100k | Weekly | Cap enforced, partial output acceptable |
| Email triage | 15k | Daily | Process highest-priority items first, defer remainder |
| Session prep | 20k | Per session | Truncate reference material, keep action items |

---

## 12. Security Considerations

1. **Update OpenClaw** to 2026.2.24 — significant security hardening (SSRF policy, sandbox media, workspace FS normalization)
2. **Sandbox mode on** for browser-enabled tasks
3. **Review ClawHub skills before installing** — check source, check VirusTotal reports
4. **Maintain `openclaw` user isolation** — colocation setup is already sound
5. **Per-agent tool deny lists** when enabling browser/exec for cron jobs
6. **API spend caps** at provider level as safety net against runaway cron jobs

---

## 13. Failure Modes

Each autonomous capability needs a quality signal and a way to reduce scope.

| Capability | Failure Mode | Mitigation | Alert Rule |
|-----------|-------------|------------|------------|
| Morning briefing | Produces noise/garbage | You read it daily — feedback loop is immediate. Tune prompt. | 2 consecutive failures → Telegram alert with failure log pointer |
| Morning briefing | Fails to generate | Cron failure or model error | 2 consecutive days missing → Telegram alert + mechanic health flag |
| Vault gardening | Bad cross-reference suggestions | All suggestions staged for review, never auto-applied | Silent — review-gated, no alert needed |
| Competitive intelligence | Hallucinated news | Web search results carry URLs — spot-checkable | Silent — manual review cycle |
| Self-healing restarts | Restart loop / thrashing | Cap at 1 restart attempt per service per hour. After that, alert only. | Immediate Telegram alert on failed restart |
| Research sessions | Shallow or irrelevant output | Track promote/dismiss rate per research brief. Adjust prompt. | 3 consecutive sessions with 0 promoted items → flag in weekly report |
| Heartbeat | Token waste on HEARTBEAT_OK ticks | Monitor weekly cost. If heartbeat is always OK, reduce frequency. | Weekly cost report includes heartbeat breakdown |
| Cron job runaway | Unbounded token spend | Provider-level API caps + per-job timeout | Per-job ceiling breach → immediate Telegram alert + job killed |

### Rollback Plan

If the overall cost trajectory exceeds $120/month (chief-of-staff + feed-intel combined) or the signal-to-noise ratio makes Tess a distraction rather than an asset:

**0. Global kill-switch (immediate halt):** Create `~/.openclaw/maintenance` as a file flag. All cron jobs, heartbeat entry points, and wrapper scripts check for this file before executing — if present, exit immediately with `HEARTBEAT_OK` (silent). Tess reports "maintenance mode" on next human-initiated Telegram interaction. One command to halt everything: `touch ~/.openclaw/maintenance`. One command to resume: `rm ~/.openclaw/maintenance`. This is the 2 AM emergency stop.

1. **Selective rollback:** Disable individual cron jobs via `openclaw cron remove <job-id>`. Keep heartbeat (lowest cost, highest safety value) and morning briefing (highest direct value).
2. **Full rollback:** Remove all cron jobs, revert HEARTBEAT.md to pre-expansion state, disable hooks config. Tess returns to relay-only mode. No infrastructure teardown needed — cron jobs are config, not code.
3. **Cost circuit breaker:** Set provider-level API spend cap at $100/month. If reached, all cron jobs stop automatically. Manual restart required after cap review.

Rollback is low-cost because all capabilities are additive configuration on existing infrastructure. No code changes to undo, no data migrations to reverse.

---

## 14. Implementation Roadmap

### Week 0 — Prerequisite: Upgrade OpenClaw to v2026.2.25

Before any capability expansion, upgrade OpenClaw. A peer-reviewed runbook exists at `Projects/openclaw-colocation/design/upgrade-v2026-2-24.md` (retargeted to v2026.2.25). Key deliverables:
- **Security-critical patches:** CVE-2026-25253, SSRF policy, sandbox hardening, workspace FS hardlink rejection
- **Heartbeat DM delivery restored** (v2026.2.25 `directPolicy: "allow"`) — was broken in v2026.2.24
- **Prompt caching:** Cost reduction for repeated system prompts (directly impacts heartbeat economics)
- **Session cleanup:** Disk management for isolated cron sessions that would otherwise accumulate
- **Exec safeBinTrustedDirs:** Required for agents to run Homebrew binaries (git, node, python)
- **Supervisor migration:** LaunchAgent → LaunchDaemon for reboot survivability
- **Stale-lock recovery + fallback chain fixes** that affect cron reliability

**Dead Man's Switch (promoted from frontier ideas — peer review consensus: mandatory infrastructure):**
- Register Tess's heartbeat with an external uptime monitor (Uptime Robot free tier or equivalent)
- Monitor two signals: (a) gateway alive (heartbeat ping received), (b) "job ran" alive (at least one cron job completed in the expected window). A system can be "up" but frozen.
- Create `_openclaw/state/tess-state.md` recording last known good state, active cron jobs, last heartbeat time, critical system status. On recovery, Tess reads this file and assesses what she missed.
- Setup time: ~5 minutes. Cost: $0.

This is the actual first step. Everything below assumes the upgrade is complete.

### Cross-Spec MVP Matrix

The four tess-operations specs don't all activate at once. This matrix defines the minimum viable operations loop (MVOL) — what must work before anything else gets turned on — and how each spec phases in.

| Spec | MVP Scope (activates with chief-of-staff Week 1) | Not-MVP (Phase 2+) |
|------|--------------------------------------------------|---------------------|
| Chief of Staff | Heartbeat + morning briefing + vault health + pipeline monitoring | Intelligence layer, Lobster workflows, session prep, overnight research |
| Google Services | Read-only Gmail summary in briefing + calendar context + auth health check (= Google Phase 1) | Email triage automation, draft creation, sends, Drive operations |
| Apple Services | Reminders read-only + iCloud Drive read-only (= Apple Phase 1) | Notes, Contacts, iMessage, Shortcuts |
| Comms Channel | Telegram-only (existing) | Discord server standup, multi-agent routing, cross-channel delivery |

**Activation sequencing:** Chief-of-staff Week 1 gate must pass before any sibling spec moves beyond Phase 0. Google and Apple Phase 1 (read-only) can run concurrently after the Week 1 gate. Comms Discord standup is independent but lower priority than service integrations.

### Week 1 — Minimum Viable Chief of Staff

1. Write HEARTBEAT.md for voice agent (concrete checklist per §4)
2. Set up morning briefing cron job
3. Set up nightly vault-check cron job (mechanic)
4. Set up hourly pipeline monitoring (mechanic)

**Gate (3-day evaluation, all must pass to proceed):**
- **Briefing utility:** Morning briefing read and acted on ≥2 of 3 days (binary: did you reference it that day?)
- **Alert accuracy:** False-positive alert rate <25% (no more than 1 false alert in 4)
- **Cost ceiling:** Total daily Tess cost (heartbeat + cron) ≤$3/day averaged over the 3 days
- **Stability:** No unrecoverable cron failures; self-healing restarts succeed on first attempt ≥80% of the time
- **Prompt tuning:** At least one prompt revision applied during the 3 days based on output quality

If any criterion fails, extend evaluation by 2 days with targeted prompt/config adjustments. If it fails twice, descope to briefing-only and diagnose.

### Week 2+ — Priorities Informed by Week 1

Sequence determined by Week 1 results. Candidates in rough priority order:

5. **Anticipatory Session** (promoted from frontier ideas — peer review unanimous #1 value)
   - Tess pre-stages a context injection file for Crumb sessions, structured for immediate consumption
   - **Context injection schema:** required sections (current_phase, next_task, blockers, recent_dispatch_results, relevant_feed_intel, vault_check_status, suggested_first_command), max 2000 tokens, wikilink conventions matching vault paths
   - Trigger: on-demand via Telegram ("Crumb session in 15 min, feed-intel-framework") or pre-commit hook for post-session debrief
   - Output: `_openclaw/inbox/session-context-<project>-<date>.md`
   - Future enhancement: feedback loop measuring which context sections Crumb actually references (ties to Self-Optimization Loop in frontier ideas)
6. Telegram topic routing (separate output types)
7. Mirror sync verification cron
8. Evaluate Lobster — run a trivial test workflow
9. Install `obsidian` skill, test vault search operations
10. Feed-intel ownership transition — **requires Week 1 gate to pass** before Phase B begins. See feed-intel ownership proposal §6 for full phasing, §3.6-3.9 for runtime contracts and guardrails.
11. GitHub webhook configuration
12. Overnight research queue processing
13. Competitive intelligence schedule
14. Connections brainstorm (weekly)
15. Builder ecosystem radar (weekly)

Do not schedule all of these into a fixed timeline. Each builds on proven stability of the layer below it.

---

## 15. Open Questions

1. **Lobster maturity.** Is it available and stable in v2026.2.25? Determines whether operational workflows use Lobster or shell scripts.
2. **Feedback listener model.** Launchd (current), heartbeat polling, or webhook? Tradeoffs around latency vs complexity. Decision at implementation time.
3. ~~**Telegram topic support.**~~ Moved to §6.2 as a prerequisite with explicit migration steps. Verify during Week 2+ implementation.
4. **1M context evaluation.** Worth testing for research sessions and vault-wide analysis. Needs cost/quality comparison against standard context.
5. **Self-improvement governance.** If Tess writes her own skills, what's the review process? How do you prevent capability creep? Needs explicit protocol before enabling.
6. **Webhook networking upgrade path.** Polling covers Week 1-2. If GitHub event latency matters, evaluate Hookdeck CLI tunnel or Tailscale Funnel. Decision deferred to post-Week 1 based on whether polling delay is operationally significant.

---

## Appendix: Community Reference Implementations

### Nathan Broadbent / Reef (closest analog)
Source: [madebynathan.com/2026/02/03/everything-ive-done-with-openclaw-so-far/](https://madebynathan.com/2026/02/03/everything-ive-done-with-openclaw-so-far/)
- Home server, SSH access, 5,000+ note Obsidian vault, Wikibase knowledge graph
- 15 automated cron jobs: 15-min active work checks → hourly inbox/alerts → 6-hour KB maintenance → daily briefing + overnight analysis (velocity assessment at 1 AM, brainstorm at 4 AM)
- 24 custom scripts written by the agent itself
- Cost: runs on Opus, described as "too much"

### Radek Sienkiewicz / "50 Days" Video (channel architecture)
Source: YouTube video "OpenClaw after 50 days: 20 real workflows" + [companion gist](https://gist.github.com/velvet-shark/b4c6724c391f612c4de4e9a07b0a74b6)
- Workflow #15 of 20: separate Discord channels per workflow type with different models per channel
- `#monitoring` → Haiku, `#briefing` → Sonnet, `#video-research` → Opus
- Key insight: visual separation of output types without multiple agents

### DataCamp CRM Pattern (meeting prep)
Source: [datacamp.com/blog/openclaw-projects](https://www.datacamp.com/blog/openclaw-projects)
- 7 AM cron checks calendar, builds briefing on each external attendee
- "When you last talked, what you discussed, anything needing follow-up"
- Directly applicable to customer-intelligence dossiers

### Community Cost Consensus
- Heartbeats on Opus: $5-30/day (don't do this)
- Heartbeats on Haiku: $0.50-2/day (reasonable)
- Heartbeats on local: $0/day
- Cron jobs on Haiku: pennies per run

### ClawHub Security Note
VirusTotal researchers found 341 malicious skills on ClawHub stealing user data. Review source and check VirusTotal reports before installing any ClawHub skill. See §12 Security Considerations.
