---
project: tess-operations
type: specification
domain: software
skill_origin: systems-analyst
status: active
created: 2026-02-26
updated: 2026-02-26
tags:
  - tess
  - openclaw
  - telegram
  - discord
  - communications
  - multi-channel
  - multi-agent
---

# Tess Communications Channel — Specification

## 1. Problem Statement

Tess currently communicates exclusively via a single Telegram bot DM. This was the right starting point — Telegram was OpenClaw's default channel, the setup was trivial, and a single-user chief-of-staff agent needs exactly one real-time conversation surface.

But this design has limits that are already visible and will become acute as the system grows:

- **No structural archive.** Every output — morning briefings, approval requests, mechanic health alerts, dispatch results, ad-hoc queries — lands in the same flat chat. There is no way to browse "last week's briefings" or "all approval decisions this month" without scrolling through an undifferentiated stream.
- **No agent separation.** As the system grows beyond Tess (mechanic as independent agent, feed-intel pipeline, future agents), all outputs either share one Telegram chat or require separate bot DMs that fragment the experience.
- **No topical organization.** A morning briefing, an urgent approval request, a mechanic TCC alert, and a casual "look up this contact" reply have equal visual weight. There's no channel-level triage.
- **No persistent reference.** Telegram messages are ephemeral in practice — searchable, but not browsable by topic or date in any structured way. Outputs that should be reference material (session prep docs, weekly reviews, triage summaries) disappear into the stream.

This spec defines a dual-channel architecture: **Telegram as the real-time interaction surface** and **Discord as the structured operations hub**. It covers channel selection rationale, server architecture, multi-agent routing, cross-channel delivery patterns, and phased implementation.

**Relationship to other specs:** This is a foundational infrastructure spec. The chief-of-staff capability spec defines *what* Tess produces; this spec defines *where* those outputs are delivered and how the user interacts with them. The Google services and Apple services specs define approval flows that depend on the channel architecture described here. Cross-agent dispatch (crumb-tess-bridge) routes results through the channels defined here.

## 1b. Existing Infrastructure

This spec builds on:
- **openclaw-colocation** (DONE) — Gateway on loopback (127.0.0.1:18789), dedicated `openclaw` user, LaunchDaemon supervisor
- **tess-model-architecture** (DONE) — Haiku 4.5 voice agent, qwen3-coder:30b mechanic agent
- **Telegram bot** (operational) — `@xfeed_crumb_bot` for feed-intel; Tess bot (8526390912) for gateway voice agent, token in `/Users/openclaw/.openclaw/openclaw.json`
- **OpenClaw v2026.2.25** — Required. Discord channel support, multi-account config, `message send --channel discord` available since v2026.2.17+. The v2026.2.25 upgrade runbook is peer-reviewed and ready.
- **crumb-tess-bridge** (DONE) — Filesystem-based dispatch protocol; dispatch results will route through Discord `#dispatch-log`

**Prerequisites for this spec:** Telegram bot operational (already true), OpenClaw upgraded to v2026.2.25 (chief-of-staff §14 Week 0), Gateway stable on loopback.

---

## 2. Channel Selection Rationale

### 2.1 Requirements

The communications layer must support:

| Requirement | Description |
|---|---|
| Real-time push | Agent initiates contact — morning briefings, approval requests, urgent alerts |
| Mobile-first interaction | Quick approval taps, voice notes, on-the-go commands |
| Structured approval workflow | Tappable buttons (approve/deny), cooldown timers, audit trail |
| Topical archive | Browsable history organized by function, not chronology |
| Multi-agent identity | Visual distinction between outputs from different agents |
| Cross-device sync | Start on phone, continue on desktop |
| File exchange | Documents, images, exports between user and agents |
| Proactive scheduling | Cron-driven outputs delivered without user prompt |
| Low setup overhead | Runs behind NAT, no public endpoints, no SSL certificates |

No single channel satisfies all of these. The architecture uses two.

### 2.2 Telegram — Real-Time Interaction Surface

Telegram is the primary channel for all time-sensitive, interactive communication between Danny and Tess.

**Why Telegram wins for real-time:**

- **Inline keyboard buttons.** Tess sends structured approval requests with tappable ✅/❌ buttons below the message. The `inlineButtons` capability is configurable per-account and works in DMs. Callback data routes back to the agent as text, so the approval → cooldown → execute pipeline triggers from a single tap.
- **Long-polling = no exposed ports.** The Bot API uses grammY with long-polling. The Gateway reaches *out* to Telegram's servers — no inbound port exposure, no public IP, no domain, no SSL certificate. Critical for the colocation deployment behind a home network.
- **Official Bot API.** First-class, sanctioned bot infrastructure. No ban risk, no unofficial library fragility, no periodic re-authentication. Bot tokens don't expire.
- **Mobile notification UX.** Bot DM notifications are clean and immediate. No server/channel noise to configure around.
- **Voice notes.** Native input for mobile commands while driving or away from keyboard.
- **Reliability.** Long-polling is more stable than WebSocket-based channels. No zombie connection issues.
- **Reaction acknowledgment.** Agent sends ⏳ reaction while processing, replaced by response. Small UX win for latency-sensitive interactions.

**What Telegram doesn't do:**

- No threading model in DMs. Every message is flat.
- No topical channels. Everything is one stream.
- No structural archive. Browsing history is scrollback only.
- Messages are not end-to-end encrypted (bot API limitation). Content transits Telegram's servers.

**Telegram is the channel Danny types into.** Commands, approvals, quick queries, voice notes — all go here. Tess's immediate responses come back here.

### 2.3 Discord — Structured Operations Hub

Discord is the secondary channel for structured, persistent, browsable output from all agents.

**Why Discord wins for archive:**

- **Channel hierarchy.** Categories → channels → threads. Each agent function gets its own channel. Each output instance (a briefing, a triage batch, a dispatch result) gets its own thread. Browsable, searchable, organized.
- **Forum channels.** Thread-first channels where each post auto-creates a named thread. Ideal for morning briefings (one thread per day), session prep (one thread per meeting), email triage (one thread per batch). The channel stays clean; detail is one click in.
- **Multi-agent identity.** Each agent runs as its own Discord bot with its own username and avatar. Visual distinction is immediate — you see "Tess" posted in `#briefings` and "Mechanic" posted in `#health-checks` without reading the content.
- **Permanent URLs.** Every Discord message has a permanent link. Outputs can be cross-referenced — a briefing thread can link to the approval that triggered it.
- **Native exec approval buttons.** Discord's `execApprovals` system ships with built-in `Allow once / Always allow / Deny` button UI. More polished than Telegram's current inline buttons for exec approvals specifically.
- **Searchable by channel.** "Find all mechanic alerts from last week" = go to `#mechanic`, scroll. No mixed-stream noise.

**What Discord doesn't do well for primary interaction:**

- WebSocket gateway instability — documented zombie connection issues where the bot appears online but stops receiving events. Unacceptable for time-sensitive approvals.
- Aggressive rate limiting — can drop messages during burst output.
- Server-centric design — single-user DM workflows feel like a workaround.
- No end-to-end encryption — Discord sees all message content.
- Mobile notification model designed for multi-user servers — requires configuration to avoid noise.

**Discord is the channel Danny browses.** Review past briefings, check mechanic health history, audit approval decisions, search triage outputs. Agents post here proactively; Danny reads here on-demand.

**Availability rule:** Discord is never the source of truth for approvals or critical notifications. Telegram remains the authoritative interaction channel. If Discord delivery fails, Tess operations continue unaffected — no approval is blocked, no alert is lost, no cron job is delayed. Discord is a read-only audit mirror and diagnostics surface. Design all workflows to function with Discord unavailable.

### 2.4 Channels Evaluated and Rejected

| Channel | Reason for rejection |
|---|---|
| WhatsApp | Unofficial Baileys library, QR re-scan every ~14 days, ban risk, Meta metadata collection |
| Signal | No inline buttons, limited rich formatting, requires signal-cli (Java runtime), less mature OpenClaw integration |
| Slack | Enterprise/team tool, overkill for single-user agent |
| WebChat | No push notifications, no mobile access without tunnel, can't initiate contact. Useful as tertiary debug interface but not a comms channel |
| Matrix | Self-hosted complexity, small OpenClaw community, no advantage over Discord for this use case |

---

## 3. Discord Server Architecture

### 3.1 Server Layout

A single private Discord server ("Tess Ops") with Danny's user account and agent bot accounts as the only members.

```
🏠 Tess Ops
│
├── 📋 CATEGORY: Briefings & Planning
│   ├── #morning-briefing      [forum]   — each briefing = auto-thread
│   ├── #session-prep          [forum]   — each meeting prep = auto-thread
│   └── #weekly-review         [text]    — weekly summary posts
│
├── 🔐 CATEGORY: Approvals & Audit
│   ├── #approvals             [text]    — approval requests (mirror from Telegram)
│   └── #audit-log             [text]    — completed action log, all agents
│
├── 📬 CATEGORY: Service Outputs
│   ├── #email-triage          [forum]   — each triage batch = auto-thread
│   ├── #calendar              [text]    — unified calendar outputs
│   ├── #reminders             [text]    — reminder mutations, overdue alerts
│   └── #feed-intel            [forum]   — each digest = auto-thread
│
├── 🔧 CATEGORY: Infrastructure
│   ├── #mechanic              [text]    — heartbeat status, TCC checks, health
│   ├── #dispatch-log          [text]    — crumb↔tess bridge results
│   └── #vault-ops             [text]    — vault mutations, KB updates
│
└── 💬 CATEGORY: Interactive
    └── #sandbox               [text]    — ad-hoc queries to Tess via Discord
```

**Forum channels** (`[forum]`) are used for outputs where each instance should be self-contained and browsable: briefings, session prep, email triage, feed-intel digests. Each post auto-creates a thread with the first line as the title.

**Text channels** (`[text]`) are used for streaming outputs where threading isn't needed: mechanic heartbeats, audit log entries, calendar snapshots, reminder mutations.

**`#sandbox`** is the only interactive channel — Danny can `@tess-bot` here for longer-form queries where persistent, threaded context is more useful than Telegram's flat chat. Use cases: complex session prep iteration, multi-step research, anything where you'll want to link back to the output later.

### 3.2 Channel Naming Conventions

- Lowercase, hyphenated: `#morning-briefing`, `#email-triage`
- Category names match Tess's functional domains
- No agent-name prefixes — agent identity comes from the bot user, not the channel name
- New channels added as new agent functions come online; existing channels are stable

### 3.3 Forum Channel Configuration

Forum channels require specific Discord configuration:

- **Default sort:** Latest activity (newest threads first)
- **Thread auto-archive:** 1 week (threads remain accessible, just archived from active view)
- **Tags (optional):** Can tag forum threads by type (e.g., "routine", "escalation", "missed") — defer until usage patterns emerge

Forum thread creation via OpenClaw:

```bash
# Auto-create thread (title = first line of message)
openclaw message send --channel discord --target channel:<forumId> \
  --message "2026-02-26 Morning Briefing\n\n## Calendar\n..."

# Explicit thread creation
openclaw message thread create --channel discord --target channel:<forumId> \
  --thread-name "2026-02-26 Morning Briefing" --message "## Calendar\n..."
```

---

## 4. Multi-Agent Routing

### 4.1 Agent → Bot Mapping

Each agent in the system runs as a separate Discord bot with its own token, username, and avatar. This provides visual identity separation at the platform level — you see who posted without reading the message.

| Agent | Discord Bot | Avatar | Bound Channels | Model |
|---|---|---|---|---|
| Tess | `tess-bot` | Chief-of-staff icon | #morning-briefing, #session-prep, #weekly-review, #approvals, #email-triage, #calendar, #reminders, #sandbox | Haiku 4.5 (voice agent) |
| Mechanic | `mechanic-bot` | Wrench icon | #mechanic, #vault-ops, #dispatch-log, #audit-log | qwen3-coder (local) |
| Feed-Intel | `feedintel-bot` | Radar icon | #feed-intel | TBD (future agent) |

**Tess also retains her existing Telegram bot** for primary interaction. The Telegram bot and Discord bot are different accounts bound to the same agent via OpenClaw's multi-channel identity linking:

```json
{
  "session": {
    "identityLinks": {
      "danny": ["telegram:<telegram-user-id>", "discord:<discord-user-id>"]
    }
  }
}
```

This ensures that when Danny messages Tess on Discord `#sandbox`, the session context includes history from Telegram interactions (and vice versa). The agent recognizes Danny as the same user across both channels.

### 4.2 OpenClaw Configuration

```json
{
  "agents": {
    "list": [
      {
        "id": "tess",
        "default": true,
        "workspace": "~/.openclaw/workspace-tess"
      },
      {
        "id": "mechanic",
        "workspace": "~/.openclaw/workspace-mechanic"
      }
    ]
  },
  "bindings": [
    {
      "agentId": "tess",
      "match": { "channel": "telegram", "accountId": "tess-telegram" }
    },
    {
      "agentId": "tess",
      "match": { "channel": "discord", "accountId": "tess-discord" }
    },
    {
      "agentId": "mechanic",
      "match": { "channel": "discord", "accountId": "mechanic-discord" }
    }
  ],
  "channels": {
    "telegram": {
      "accounts": {
        "tess-telegram": {
          "botToken": "${TELEGRAM_TESS_BOT_TOKEN}",
          "dmPolicy": "allowlist",
          "allowFrom": ["<danny-telegram-id>"],
          "capabilities": {
            "inlineButtons": "dm"
          }
        }
      }
    },
    "discord": {
      "accounts": {
        "tess-discord": {
          "token": "${DISCORD_TESS_BOT_TOKEN}",
          "guilds": {
            "<guild-id>": {
              "requireMention": true,
              "channels": {
                "<morning-briefing-id>": { "allow": true, "requireMention": false },
                "<session-prep-id>": { "allow": true, "requireMention": false },
                "<weekly-review-id>": { "allow": true, "requireMention": false },
                "<approvals-id>": { "allow": true, "requireMention": false },
                "<email-triage-id>": { "allow": true, "requireMention": false },
                "<calendar-id>": { "allow": true, "requireMention": false },
                "<reminders-id>": { "allow": true, "requireMention": false },
                "<sandbox-id>": { "allow": true, "requireMention": true },
                "<audit-log-id>": { "allow": true, "requireMention": false }
              }
            }
          }
        },
        "mechanic-discord": {
          "token": "${DISCORD_MECHANIC_BOT_TOKEN}",
          "guilds": {
            "<guild-id>": {
              "requireMention": false,
              "channels": {
                "<mechanic-id>": { "allow": true },
                "<vault-ops-id>": { "allow": true },
                "<dispatch-log-id>": { "allow": true },
                "<audit-log-id>": { "allow": true, "requireMention": false }
              }
            }
          }
        }
      },
      "dm": {
        "enabled": true,
        "policy": "allowlist",
        "allowFrom": ["<danny-discord-id>"]
      },
      "execApprovals": {
        "enabled": true,
        "approvers": ["<danny-discord-id>"],
        "target": "dm"
      }
    }
  }
}
```

**Configuration verification note:** The multi-account structure above (`channels.discord.accounts` with named sub-accounts) represents the target config for multi-agent Discord support. Basic OpenClaw docs show a simpler single-bot pattern (`channels.discord.token`). Verify during Phase 0 that v2026.2.25 supports the multi-account pattern — if not, use separate config profiles or a single bot account with channel-level routing instead.

**Key configuration decisions:**

- `requireMention: false` on output channels — agents post proactively without needing @mention
- `requireMention: true` on `#sandbox` — Tess only responds when Danny explicitly addresses her, preventing accidental triggers
- `execApprovals` target is `dm` — approval button prompts go to Danny's DMs, not into a public channel (even though the server is private, this keeps the UX consistent)
- Each bot account has channel-level allowlists — mechanic-bot can't post to `#briefings`, tess-bot can't post to `#mechanic`

### 4.3 Adding New Agents

When a new agent joins the system (e.g., feed-intel becomes independent):

1. Create a Discord bot via Developer Portal (name, avatar, token)
2. Enable minimum required intents: Message Content Intent only if the bot reads user messages (interactive); skip for outbound-only bots. Server Members Intent is not needed for private single-user servers.
3. Invite bot to the Tess Ops server with Send Messages + Read Message History permissions. Apply channel-specific permission overrides post-invite to revoke permissions outside the bot's designated channels.
4. Add the agent to `agents.list` with its own workspace
5. Add a binding mapping the new Discord account to the agent
6. Add channel allowlists restricting the bot to its designated channels
7. Restart Gateway

No architecture changes needed. The server structure, routing model, and delivery patterns remain the same.

---

## 5. Cross-Channel Delivery Patterns

The core design question: how does Tess, whose primary session lives on Telegram, also deliver outputs to Discord?

### 5.1 Pattern: Cron-Based Dual Delivery

The most reliable pattern today. Scheduled outputs (morning briefings, heartbeat checks, nightly reports) are cron jobs that target both channels independently.

```json
{
  "name": "Morning Briefing",
  "schedule": { "kind": "cron", "expr": "0 7 * * *" },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Generate morning briefing. Deliver summary to Telegram. Deliver full structured briefing to Discord #morning-briefing as a forum thread titled with today's date."
  }
}
```

The cron job fires, generates the briefing content once, then delivers:
- **Telegram:** Condensed summary (key items, action-needed flags, approval requests with inline buttons)
- **Discord `#morning-briefing`:** Full structured briefing as a forum thread (calendar detail, email triage, reminders, context links)

This pattern works today with `openclaw message send --channel discord --target channel:<id>`. No cross-context routing needed because cron jobs run in isolated sessions that aren't bound to a single channel.

### 5.2 Pattern: Approval Mirror

Approval requests are the most time-sensitive output. The primary approval flow stays on Telegram (inline buttons, mobile push). Discord gets a mirror for audit purposes.

**Flow:**
1. Tess determines an action needs approval (e.g., send email, complete reminder)
2. Tess sends approval request to Telegram with inline buttons (✅ Approve / ❌ Deny)
3. Tess simultaneously posts to Discord `#approvals` with the same request details (no buttons — this is the audit copy)
4. Danny taps approve on Telegram
5. Tess executes the action
6. Tess edits the Discord `#approvals` message to reflect the decision: "✅ Approved by Danny at 09:23 — executed"

**Approval state persistence:** When Tess posts the audit mirror to Discord (step 3), the Discord message ID is captured and stored in a lightweight approval record alongside the approval ID and Telegram message ID. This enables the edit in step 6.

**Approval record schema** (stored in OpenClaw agent workspace or JSONL file):

```json
{
  "approval_id": "AID-7F3K2",
  "created_at": "2026-02-26T09:15:00Z",
  "telegram_message_id": "<msg-id>",
  "discord_channel_id": "<approvals-channel-id>",
  "discord_message_id": "<msg-id>",
  "status": "pending",
  "decided_at": null,
  "decision": null
}
```

When Danny taps approve on Telegram, Tess looks up the approval record by `approval_id`, retrieves the `discord_message_id`, and edits the Discord message. If the record is missing (e.g., storage failure, multi-session gap), Tess falls back to posting a reply in `#approvals` with the decision instead of editing the original — noisier but functional.

The Discord copy is the permanent audit record. The Telegram copy is the interaction surface. Both are timestamped.

### 5.3 Pattern: Agent-Initiated Discord Post

For on-demand outputs that originate from a Telegram conversation (Danny asks "prep me for the 2pm meeting"), Tess can post the full output to Discord while sending a summary to Telegram.

**Flow:**
1. Danny messages Tess on Telegram: "Prep me for the 2pm with Acme"
2. Tess assembles session prep (calendar, email threads, vault KB, contacts)
3. Tess replies on Telegram: "Prepped. Key items: [summary]. Full doc posted to Discord #session-prep."
4. Tess posts the full session prep to Discord `#session-prep` as a forum thread: "2026-02-26 2pm — Acme Sync"

This requires cross-context messaging (Telegram session → Discord channel). Current OpenClaw support:

- **Cron/heartbeat contexts:** Can target any channel. Works today.
- **Interactive session contexts:** Cross-context messaging is restricted by default. **Primary mechanism:** A local bridge service on loopback (`127.0.0.1`) that accepts posting requests from the Telegram session and forwards them to Discord via the Gateway. The bridge uses a shared-secret for authentication (preventing unauthorized local processes from posting) and idempotency keys (use approval/output ID) to prevent duplicate posts. Messages are queued on-disk so the Telegram session can enqueue even when Discord is temporarily down.
- **Future enhancement:** A `crossContextRoutes` config has been proposed (issue #22725) to whitelist `from: "telegram" → to: "discord"` natively. If merged, it replaces the local bridge for direct cross-context posting. Monitor the issue.
- **Degraded fallback:** If the local bridge also fails, Tess posts everything to Telegram; a lightweight hook script mirrors tagged messages to Discord asynchronously. Less elegant but functional.

### 5.4 Pattern: Discord-Only Output

Some outputs have no Telegram component — they're purely archival or infrastructure-level.

- **Mechanic heartbeat results** → `#mechanic` only (unless critical alert, which also goes to Telegram)
- **Vault operation log** → `#vault-ops` only
- **Dispatch results** → `#dispatch-log` only (unless Danny is waiting for a result, then summary to Telegram)

These are posted directly by the responsible agent (mechanic-bot) via its Discord-bound session. No cross-context routing needed.

### 5.5 Delivery Matrix

| Output Type | Telegram | Discord Channel | Discord Format |
|---|---|---|---|
| Morning briefing | Summary + action items | `#morning-briefing` | Forum thread (full structured) |
| Session prep | Summary + key points | `#session-prep` | Forum thread (full doc) |
| Approval request | Inline buttons (primary) | `#approvals` | Text (audit mirror) |
| Approval result | Confirmation message | `#approvals` | Edit to original (status update) |
| Email triage batch | Summary counts | `#email-triage` | Forum thread (full triage) |
| Calendar snapshot | Part of briefing | `#calendar` | Text (daily snapshot) |
| Reminder mutations | Confirmation | `#reminders` | Text (log entry) |
| Feed-intel digest | Summary + top items | `#feed-intel` | Forum thread (full digest) |
| Mechanic heartbeat | Only if critical alert | `#mechanic` | Text (status line) |
| Mechanic alert | ⚠️ Alert message | `#mechanic` | Text (alert + detail) |
| Vault operations | — | `#vault-ops` | Text (log entry) |
| Dispatch results | Summary if awaited | `#dispatch-log` | Text (full result) |
| Weekly review | Summary | `#weekly-review` | Text (full review) |
| Ad-hoc query response | Full response | — | — |
| Ad-hoc query (via Discord) | — | `#sandbox` thread | Full response in thread |
| Audit log entry | — | `#audit-log` | Text (structured log line) |

---

## 6. Telegram Configuration

### 6.1 Bot Setup

Tess's Telegram bot is already deployed. Key configuration to verify/update:

```json
{
  "channels": {
    "telegram": {
      "accounts": {
        "tess-telegram": {
          "botToken": "${TELEGRAM_TESS_BOT_TOKEN}",
          "dmPolicy": "allowlist",
          "allowFrom": ["<danny-telegram-id>"],
          "capabilities": {
            "inlineButtons": "dm"
          },
          "streaming": "partial",
          "linkPreview": true,
          "chunkMode": "newline",
          "retry": {
            "attempts": 3,
            "minDelayMs": 500,
            "maxDelayMs": 30000,
            "jitter": 0.1
          }
        }
      }
    }
  }
}
```

### 6.2 Inline Buttons for Approvals

Enable `inlineButtons: "dm"` to unlock structured approval UX. Approval messages arrive with tappable buttons:

```json
{
  "action": "send",
  "channel": "telegram",
  "to": "<danny-telegram-id>",
  "message": "🔐 Approval required\n\nAction: Send email reply\nTo: jane@acme.com\nSubject: Re: Q3 Review\n\nDraft preview: [summary]\n\nExpires: 5 min",
  "buttons": [
    [
      { "text": "✅ Approve", "callback_data": "approve:<id>" },
      { "text": "❌ Deny", "callback_data": "deny:<id>" }
    ]
  ]
}
```

Callback data is passed back to the agent as text: `callback_data: approve:<id>`. The agent matches the ID to the pending action, executes or cancels, and sends confirmation.

### 6.3 What Stays Telegram-Only

Some interaction types remain exclusively on Telegram with no Discord mirror:

- **Ad-hoc queries** ("What's John's phone number?", "Summarize my 3pm meeting") — quick Q&A stays in the real-time channel
- **Conversational back-and-forth** — multi-turn clarification, follow-up questions
- **Voice note input** — Telegram → transcription → agent processing → Telegram reply
- **Quick confirmations** — "Done", "Got it", status acknowledgments

The principle: if it's ephemeral and interactive, it stays on Telegram. If it's structured and reference-worthy, it goes to Discord (possibly in addition to Telegram).

---

## 7. Discord Configuration

### 7.1 Server Setup Procedure

One-time setup, approximately 30 minutes:

1. **Create server:** Discord → "Create My Own" → "For me and my friends" → name: "Tess Ops"
2. **Enable Developer Mode:** User Settings → Advanced → Developer Mode (enables right-click → Copy ID)
3. **Create categories and channels** per §3.1 layout
4. **Configure forum channels:** Set default sort order, auto-archive duration, slowmode off
5. **Copy all channel IDs** (right-click → Copy Channel ID) — needed for OpenClaw config

### 7.2 Bot Creation (Per Agent)

For each agent that needs a Discord presence:

1. Go to Discord Developer Portal → New Application
2. Name it (e.g., "Tess", "Mechanic")
3. Bot → set username, upload avatar
4. Bot → Reset Token → copy and store securely
5. Bot → enable Privileged Gateway Intents (per-bot minimum):
   - **Message Content Intent** — required only for interactive bots that read user messages (tess-bot in `#sandbox`). Outbound-only bots (mechanic-bot, feedintel-bot) do NOT need this intent — they only post, never read message content.
   - **Server Members Intent** — NOT required for any bot in a private single-user server. Only enable if member lookup functionality is explicitly needed.
6. OAuth2 → URL Generator:
   - Scopes: `bot`
   - Permissions: Send Messages, Read Message History, Embed Links, Attach Files, Add Reactions, Use External Emojis, Manage Threads (for forum posts), Read Message History
   - Install type: Guild Install
7. Copy invite URL → open in browser → select "Tess Ops" server → Authorize
8. Store bot token in environment variable on Gateway host

### 7.3 Gateway WebSocket Stability

Discord's WebSocket gateway is less stable than Telegram's long-polling. For an archive channel this is acceptable — a 30-second reconnect delay on a briefing post is invisible. But it must be configured for resilience:

```json
{
  "channels": {
    "discord": {
      "reconnect": {
        "enabled": true,
        "maxAttempts": 10,
        "backoffMs": 5000
      }
    }
  }
}
```

**Monitoring:** The mechanic heartbeat should verify Discord connectivity as part of its health check cycle. If the Discord gateway drops, mechanic alerts via Telegram (which remains stable independently).

**Zombie connection detection:** Standard WebSocket reconnect logic only handles closed connections. A "zombie" state — socket remains open but stops receiving events — results in silent failure where bots appear online but are unresponsive. To detect this, mechanic runs an application-level heartbeat: periodically send a canary message to a designated test channel (e.g., `#mechanic`) and verify receipt via a follow-up read within 10 seconds. If the canary is not received, force a Gateway restart (`openclaw gateway restart`). This supplements the WebSocket ping/pong mechanism which only tests transport-layer connectivity.

### 7.4 Rate Limiting

Discord rate-limits bots more aggressively than Telegram. For a private single-user server with 2-3 bots, this is unlikely to be a problem in practice. But design for it:

- Batch outputs where possible (one forum thread post vs. many individual messages)
- Use `textChunkLimit: 2000` and `chunkMode: "newline"` for graceful long-message splitting
- Avoid burst posting — space cron jobs at least 5 minutes apart
- If rate limits become an issue, implement a posting queue with backoff

### 7.5 Message Limits

Discord's per-message limit is 2000 characters (vs. Telegram's 4096). Long outputs will be chunked. Mitigations:

- Forum thread posts can contain multiple messages in sequence — the thread holds them together
- For structured outputs (briefings, triage), break into semantic sections rather than arbitrary character splits
- Use OpenClaw's `chunkMode: "newline"` to split on paragraph boundaries

---

## 8. Security Model

### 8.1 Server Access Control

The Discord server is private. Only Danny's personal account and agent bot accounts are members. There is no public invite link. This is enforced by:

- Server visibility: private (not discoverable)
- No vanity invite URL
- All bots created in Danny's Discord Developer Portal (tokens controlled by Danny)
- `groupPolicy: "allowlist"` on all bot configurations
- Per-channel allowlists restricting which bots can post where

### 8.1b Human Account Hardening

Bot least-privilege is insufficient if the human account is compromised. Danny's Discord account must be hardened:

- **2FA required** on Danny's Discord account (Settings → My Account → Enable Two-Factor Auth)
- **Disable "Create Invite" permission** for `@everyone` role (Server Settings → Roles → @everyone → uncheck "Create Invite"). Only Danny's account retains invite capability.
- **Delete all existing invite links** (Server Settings → Invites → delete all)
- **"Require 2FA for moderation"** enabled at server level (Server Settings → Safety Setup → enable)
- **Periodic member audit:** Members list should contain only Danny + bot accounts. Check quarterly or after any bot token rotation.

### 8.2 Bot Permissions

Principle of least privilege per bot:

| Bot | Server Permissions | Channel Restrictions |
|---|---|---|
| tess-bot | Send Messages, Read History, Embed Links, Attach Files, Add Reactions, Manage Threads | Briefings, approvals, service outputs, sandbox |
| mechanic-bot | Send Messages, Read History | Mechanic, vault-ops, dispatch-log |
| feedintel-bot | Send Messages, Read History, Manage Threads | Feed-intel only |

No bot has Administrator permission. No bot has moderation permissions (kick, ban, manage channels). Bots cannot create or delete channels.

### 8.3 Discord Privacy Considerations

Discord is not end-to-end encrypted. Discord Inc. can see all message content in the server. For Tess's use case, this means:

- Morning briefings (which may contain email subjects, calendar titles, contact names) are visible to Discord
- Approval audit logs (which contain action descriptions) are visible to Discord
- Session prep documents (which may reference customer names, project details) are visible to Discord

**Risk assessment:** This is the same privacy profile as Telegram (which also isn't E2E encrypted for bot conversations). The data in question is also available to Google (email, calendar), Apple (contacts, messages), and the LLM providers (Anthropic, OpenAI) processing the content. Discord doesn't materially worsen the privacy surface.

**Data retention:** Discord retains message data indefinitely by default — unlike Telegram Bot API which has server-side retention but no permanent archival guarantee. For a personal operations server this is desirable (persistent audit trail), but it means Discord holds a complete history of all agent outputs, approval decisions, and operational data with no automatic expiry.

**ToS compliance:** Discord permits personal servers with bot accounts for private use. The bot usage pattern here (automated posting to a private server with a single human member) is within Discord's Terms of Service. No user-facing automation (e.g., spam, impersonation, mass DMs) is involved. Review Discord's Developer ToS and Bot Policy if the server expands beyond single-user or if bot behavior changes materially.

**Mitigation:** If privacy posture needs to tighten in the future, Discord can be replaced with a self-hosted alternative (Matrix/Element with OpenClaw's Matrix extension) without changing the architectural pattern. The channel abstraction in OpenClaw means swapping Discord for Matrix requires config changes, not architecture changes. Consider periodic export to vault (yearly archive notes) for data sovereignty.

### 8.4 Cross-Context Security

Cross-context messaging (Telegram session posting to Discord) is restricted by default in OpenClaw. The primary mechanism is a local bridge service (see §5.3) running on loopback with shared-secret authentication.

If `crossContextRoutes` (issue #22725) becomes available, it replaces the local bridge:

```json
{
  "crossContextRoutes": {
    "allow": [
      { "from": "telegram", "to": "discord" }
    ]
  }
}
```

This is intentionally one-directional. Discord → Telegram cross-posting is not enabled. The only path for content to reach Telegram is through Tess's direct response or cron-based delivery.

### 8.5 Token Management

- Telegram bot tokens: stored in environment variables on Gateway host, referenced in config as `${TELEGRAM_TESS_BOT_TOKEN}`
- Discord bot tokens: stored in environment variables, referenced as `${DISCORD_TESS_BOT_TOKEN}`, `${DISCORD_MECHANIC_BOT_TOKEN}`
- Tokens never appear in config files, Git, or logs
- If a token is compromised: revoke via BotFather (Telegram) or Developer Portal (Discord), generate new token, update environment variable, restart Gateway

---

## 9. Implementation Phasing

### Phase 0 — Discord Server Setup (with chief-of-staff Phase 0)

**Objective:** Discord infrastructure exists and is ready for agent output.

- [ ] Create "Tess Ops" Discord server
- [ ] Create category and channel structure per §3.1
- [ ] Configure forum channels (sort order, auto-archive)
- [ ] Create tess-bot in Discord Developer Portal (name, avatar, token, intents, permissions)
- [ ] Create mechanic-bot in Discord Developer Portal
- [ ] Invite both bots to server
- [ ] Copy all channel IDs and guild ID
- [ ] Store bot tokens as environment variables on Gateway host
- [ ] Add Discord channel configuration to `openclaw.json`
- [ ] Add bindings mapping tess-discord and mechanic-discord accounts to agents
- [ ] Update Telegram config to enable `inlineButtons: "dm"` if not already active
- [ ] Restart Gateway, verify both bots appear online in Discord
- [ ] **Config schema validation:** After restart, run `openclaw config get --json` and verify all Discord-related keys are recognized (not silently ignored). Check: (a) `channels.discord.accounts` entries appear in output, (b) guild/channel IDs are present, (c) `requireMention`, `dmPolicy`, `execApprovals` keys are reflected. If `openclaw config validate` exists, run it. If keys are absent from config output despite being set, the multi-account schema may not be supported — fall back to single-bot pattern per §4.2 verification note.
- [ ] Test: `openclaw message send --channel discord --target channel:<mechanic-id> --message "test"` — verify message appears
- [ ] Test: Send message in `#sandbox`, verify tess-bot responds
- [ ] Test: Verify tess-bot can post to all its bound channels (iterate through channel IDs from §4.2)
- [ ] Test: Verify mechanic-bot can post to `#audit-log` (multi-agent audit routing)

**Gate:** Both bots online, messages post successfully to designated channels, config validation confirms all keys recognized, `#sandbox` interaction works. Estimated time: 1-2 hours.

### Phase 1 — Dual Delivery for Briefings + Heartbeat (with chief-of-staff Phase 1)

**Objective:** Morning briefings and mechanic heartbeats are delivered to both channels.

- [ ] Configure morning briefing cron to dual-deliver: summary to Telegram, full structured output to Discord `#morning-briefing` as forum thread
- [ ] Configure mechanic heartbeat to post status to Discord `#mechanic`
- [ ] Configure mechanic to alert both Telegram and Discord `#mechanic` on critical issues
- [ ] Test forum thread creation: verify briefings create properly titled threads
- [ ] Observe for 5 days: verify Discord gateway stability, no dropped posts, no rate limit issues

**Gate:** 5 consecutive days of successful dual delivery. Discord gateway reconnects gracefully if interrupted. No manual intervention needed.

### Phase 2 — Service Output Mirroring (with chief-of-staff Phase 2+)

**Objective:** As Google/Apple services come online, their outputs flow to Discord.

- [ ] Email triage batches → Discord `#email-triage` as forum threads
- [ ] Approval requests → mirror to Discord `#approvals` (audit copy, no buttons)
- [ ] Approval results → edit Discord `#approvals` mirror with decision
- [ ] Calendar outputs → Discord `#calendar`
- [ ] Reminder mutations → Discord `#reminders`
- [ ] Configure audit log format and posting to Discord `#audit-log`

**Gate:** Run for 5 days. Criteria: (a) ≥90% of service output events have a Discord archive entry (spot-check against audit log), (b) approval mirrors appear in Discord `#approvals` within 30 seconds of Telegram delivery, (c) zero missed audit log entries for mutation actions, (d) Discord message delivery success rate ≥95%.

### Phase 3 — Multi-Agent + Advanced Patterns

**Objective:** Additional agents have Discord presence. Cross-context messaging is native.

- [ ] If feed-intel becomes independent agent: create feedintel-bot, bind to `#feed-intel`
- [ ] Implement cross-context routing (Telegram → Discord) if `crossContextRoutes` is available
- [ ] If not available: implement webhook-based mirror as interim solution
- [ ] Enable session prep dual delivery (Telegram summary + Discord `#session-prep` thread)
- [ ] Evaluate `#sandbox` usage — is interactive Discord useful enough to keep?
- [ ] Create `#dispatch-log` posting for crumb-tess-bridge results
- [ ] Create `#vault-ops` posting for vault mutations

**Gate:** Run for 5 days. Criteria: (a) all active agents have Discord bot online ≥99% of the time (mechanic monitors), (b) cross-context delivery (Telegram → Discord) succeeds ≥95% of attempts, (c) `#sandbox` interactions produce contextually coherent responses referencing Telegram history (test 3 queries), (d) `#dispatch-log` captures all bridge dispatch results during the period.

---

## 10. Operating Patterns

### 10.1 Danny's Daily Usage

**Morning:**
- Phone buzzes with Telegram notification — Tess's morning briefing summary
- Glance at summary, tap approve/deny on any pending items
- If deeper context needed: open Discord app → `#morning-briefing` → today's thread → full detail

**During the day:**
- Quick commands via Telegram: "look up Jane's number", "add reminder: call plumber", "what's my 3pm about"
- Approval requests arrive on Telegram with buttons — tap to approve/deny
- If reviewing past triage or prep: open Discord → relevant channel → browse threads

**Evening/weekly review:**
- Open Discord → `#weekly-review` — Tess's weekly summary
- Browse `#audit-log` — what actions were taken this week
- Check `#mechanic` — any health issues flagged

### 10.2 Agent Output Behavior

Agents follow a simple rule for channel targeting:

1. **Telegram gets the notification.** Short, actionable, time-sensitive. Always fits on a phone screen.
2. **Discord gets the record.** Full, structured, reference-worthy. Browsable later.
3. **Some outputs are Discord-only.** Infrastructure logs, vault ops, dispatch results — unless escalation is needed.
4. **Some interactions are Telegram-only.** Ad-hoc Q&A, conversational clarification, voice notes.

### 10.3 Failure Modes

| Failure | Impact | Mitigation |
|---|---|---|
| Discord gateway drops | Archive posts delayed until reconnect | Mechanic detects via health check, alerts on Telegram. Auto-reconnect with backoff (§7.3). No data loss — posts queue. |
| Telegram API unreachable | Primary interaction surface down — approvals and voice input blocked | Mechanic alerts via Discord `#mechanic`. **Approvals:** Queue pending approvals; if `crossContextRoutes` or local bridge is available, post approval requests to Discord `#approvals` with emoji-reaction approval (👍/👎) as interim UX. If not available, approvals are blocked until Telegram recovers — no autonomous actions during outage. **Non-approval outputs:** Continue posting to Discord channels as normal (cron/heartbeat contexts are channel-independent). **Voice input:** Unavailable — no Discord equivalent. Danny can use `#sandbox` for text-based commands as a degraded alternative. |
| Both channels down | Complete comms failure | Gateway logs all pending outputs. Retries on reconnect. Danny can check WebChat (`localhost:18789/webchat`) as emergency fallback. |
| Discord rate limit hit | Posts delayed or dropped | Implement posting queue with backoff. Prioritize approval mirrors over routine logs. |
| Bot token revoked | Specific bot goes offline | Mechanic detects missing bot in Discord health check. Alert via remaining functional channel. Regenerate token and restart. |
| Forum thread creation fails | Discord API error on thread post (permissions, forum misconfigured) | Fallback: post as regular message in parent channel. Log failure for review. Mechanic alerts if pattern persists. |
| Identity link misconfiguration | Danny seen as different users across Telegram and Discord — session context doesn't carry | Test identity linking in Phase 0. If `identityLinks` fails, `#sandbox` interaction loses cross-channel context. Degrade gracefully: treat Discord interactions as independent sessions. |
| Inline button callback timeout | Telegram callback_data not received by agent after tap | Retry logic in Gateway (§6.1 retry config). If callback lost, Danny re-taps or sends text "approve AID-xxx". Agent accepts both callback and text approval. |
| Message chunking drops content | 2000-char Discord limit splits mid-sentence or drops trailing content | Use `chunkMode: "newline"` for paragraph-boundary splits. Verify full content posted by comparing Telegram output length to Discord chunks. |
| Cross-context webhook failure | §5.3 fallback webhook/RPC fails when `crossContextRoutes` unavailable | Degrade to hook-script mirror (§5.3 fallback). If that also fails, outputs go to Telegram only — Discord archive gap logged, backfilled manually. |

---

## 11. Cost Analysis

Discord is free for a private server with no user limit concerns. Telegram Bot API is free. The incremental cost is LLM processing for dual-delivery format adaptation.

| Function | Agent | Model | Frequency | Est. Monthly |
|----------|-------|-------|-----------|-------------|
| Briefing format adaptation (full Telegram → condensed summary + full Discord thread) | voice | Haiku 4.5 | Daily | $0.50-1 |
| Approval mirror formatting | voice | Haiku 4.5 | ~5-10/day | $0.25-0.50 |
| Session prep dual delivery | voice | Haiku 4.5 | On-demand (~3x/week) | $0.15-0.30 |
| Discord health check (gateway probe) | mechanic | qwen3-coder | Every 30 min | $0 |
| Discord bot token creation/management | — | — | One-time setup | $0 |
| **Incremental total** | | | | **$0.90-1.80/month** |

Lowest incremental cost of all sibling specs. Most Discord operations are direct `message send` API calls with no LLM processing. The only LLM cost is format adaptation for dual-delivery outputs.

---

## 12. Rollback Plan

Discord integration can be removed without affecting Telegram (the primary interaction surface). Telegram is fully independent — it operated alone before Discord was added and can revert to that state.

**Selective rollback (Discord only):**
1. Remove Discord channel config from `openclaw.json` (or set `channels.discord.enabled: false`)
2. Remove dual-delivery targets from cron job payloads — revert to Telegram-only delivery
3. Restart Gateway
4. Discord server and messages remain accessible for historical reference — no data loss
5. All time-sensitive flows (approvals, alerts, ad-hoc queries) are unaffected — they never depended on Discord

**Full rollback (both channels):**
Not applicable — Telegram is the minimum viable communication channel. Removing Telegram would leave no interaction surface. If Telegram itself needs replacement, the channel abstraction in OpenClaw means substituting another channel (Signal, Slack) is a config change, not an architecture change.

**Circuit breaker:** If Discord posting causes issues (rate limits degrading Gateway performance, WebSocket reconnect storms), disable Discord in config and restart. Single config flag: `channels.discord.enabled: false`. All outputs revert to Telegram-only delivery. Discord history is preserved.

---

## 13. Open Questions

1. **Cross-context routing availability.** The `crossContextRoutes` config (issue #22725) would make Telegram→Discord posting native. If it's not merged by Phase 2, the webhook/RPC workaround is straightforward but adds a moving part. Monitor the issue.

2. **Forum channel thread limits.** Discord has a soft limit on active threads per channel. For daily briefings, this is ~365 threads/year. Verify Discord's archiving behavior doesn't cause issues at this volume.

3. **Discord mobile notification tuning.** With agents posting proactively to multiple channels, Discord's mobile notifications could become noisy. Configuration: mute all channels except `#approvals` (if approval mirroring proves useful for mobile) or mute the entire server and use Discord purely as a desktop reference tool.

4. **`#sandbox` session isolation.** When Danny interacts with Tess in Discord `#sandbox`, does this share session state with Telegram conversations? With `identityLinks` configured, it should. Verify that context carries across channels as expected. If it doesn't, evaluate whether `#sandbox` should be an independent session or if shared context is essential.

5. **Mechanic as independent agent.** The current spec treats mechanic as a subagent within Tess's orchestration but gives it its own Discord bot. If mechanic becomes a fully independent OpenClaw agent (own workspace, own session store), the Discord routing is already correct. But the Telegram alert path changes — mechanic would need its own Telegram bot or a cross-agent messaging path. Defer until agent architecture evolves.

6. **Message retention.** Discord messages persist indefinitely by default (no auto-delete). For a private server this is fine and desirable. But if the server accumulates years of operational data, consider periodic export to vault (yearly archive notes) and whether Discord's search remains performant at scale.

---

## Appendix A: Relationship to Other Specs

| Spec | Relationship |
|---|---|
| Chief-of-staff | Parent. Defines *what* Tess produces. This spec defines *where* it's delivered. Morning briefing (§5), reactive layer (§6), and intelligence layer (§8) all route through channels defined here. |
| Google services | Sibling. Email triage, calendar outputs, and approval flows (§4-5) use the delivery patterns defined here. Audit logging (§6) posts to Discord `#audit-log`. |
| Apple services | Sibling. Reminder mutations, Notes exports, iMessage context, and contact lookups route through the delivery matrix (§5.5). |
| Feed-intel | Consumer. Feed-intel digests deliver to both Telegram (summary) and Discord `#feed-intel` (full digest thread). |
| Crumb-tess-bridge | Consumer. Dispatch results post to Discord `#dispatch-log`. Urgent results also notify via Telegram. |

## Appendix B: Discord Bot Creation Quick Reference

```bash
# === Discord Developer Portal ===
# 1. https://discord.com/developers/applications → New Application
# 2. Bot → set username and avatar
# 3. Bot → Reset Token → copy token
# 4. Bot → Privileged Gateway Intents:
#    ✅ Message Content Intent
#    ✅ Server Members Intent
# 5. OAuth2 → URL Generator:
#    Scopes: bot
#    Permissions: Send Messages, Read Message History, Embed Links,
#                 Attach Files, Add Reactions, Use External Emojis,
#                 Manage Threads, Read Message History
# 6. Copy invite URL → open → select server → Authorize

# === OpenClaw CLI ===
# Set token
openclaw config set channels.discord.accounts.<name>.token '"<token>"' --json
openclaw config set channels.discord.enabled true --json

# Verify
openclaw gateway restart
openclaw channels status --probe

# Test send
openclaw message send --channel discord --target channel:<channel-id> --message "test"

# Forum thread creation
openclaw message send --channel discord --target channel:<forum-id> \
  --message "Thread Title\n\nThread body content..."

# Pairing (if using pairing mode)
openclaw pairing list
openclaw pairing approve <CODE>
```

## Appendix C: Telegram Configuration Quick Reference

```bash
# === BotFather ===
# 1. Telegram → @BotFather → /newbot → follow prompts
# 2. Copy bot token
# 3. /setprivacy → Disable (if bot needs to see group messages)
# 4. /setjoingroups → Disable (bot is DM-only for Tess)

# === OpenClaw CLI ===
# Set token (if not already configured)
openclaw config set channels.telegram.accounts.tess-telegram.botToken '"<token>"' --json

# Enable inline buttons
openclaw config set channels.telegram.accounts.tess-telegram.capabilities.inlineButtons '"dm"' --json

# Verify
openclaw channels status --channel telegram

# Test send
openclaw message send --channel telegram --target <danny-telegram-id> --message "test"
```
