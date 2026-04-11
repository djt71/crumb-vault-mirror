---
type: tutorial
status: active
domain: software
created: 2026-03-14
updated: 2026-04-11
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Tutorial: First Tess Interaction

Walk through interacting with Tess via Telegram — voice agent, mechanic agent, and escalation to Crumb.

**Prerequisites:** OpenClaw gateway running. Telegram bot configured. DM pairing established.

---

## Step 1: Open Telegram

Open Telegram and find the Tess bot conversation (or start a new DM with the bot).

**Expected outcome:** Chat window with Tess. If the gateway was recently restarted, send any message first to re-establish the DM pairing (pairings are in-memory only).

---

## Step 2: Send a Message

Type a question or request. Tess has two modes:

| Agent | Model | When It Activates | Capabilities |
|-------|-------|-------------------|-------------|
| **Tess Voice** | Kimi K2.5 via OpenRouter (Qwen 3.6 failover) | Default for conversations | Chat, Q&A, vault reads, lightweight reasoning |
| **Tess Mechanic** | Nemotron (local Ollama) | Cron jobs, operational checks | Scripted checks, Telegram alerts, automated health monitoring |

You're talking to Tess Voice. It can:
- Answer questions using vault knowledge
- Read vault files (within access permissions)
- Perform lightweight lookups and summaries

**Expected outcome:** Tess responds conversationally. Response time depends on model availability.

---

## Step 3: Understand What Tess Cannot Do

Tess Voice has boundaries:

- **Cannot write to the vault** (read-only access to most vault content)
- **Cannot run Crumb skills** (no spec-first workflow, no compound engineering)
- **Cannot make commits** (no git access)
- **Cannot access `~/.config/crumb/.env`** (credential isolation)

If you ask Tess to do something beyond its capabilities, it should tell you. If it doesn't, and something seems wrong, check the vault state manually.

**Expected outcome:** You understand the Voice/Mechanic split and don't expect Crumb-level capabilities from Tess.

---

## Step 4: Escalate to Crumb

When work requires vault writes, skill activation, or structured workflow, Tess can escalate to Crumb via the bridge:

1. **Tess stages a request** in `_openclaw/inbox/` (JSON file)
2. **Bridge watcher** detects the file (kqueue) and triggers dispatch
3. **Claude Code** runs with `--print` mode, processes the request under CLAUDE.md governance
4. **Response** written to `_openclaw/outbox/`
5. **Tess picks up** the response and delivers it via Telegram

**To trigger escalation:** Ask Tess something that requires vault modification. Tess recognizes the boundary and stages the bridge request.

**Expected outcome:** Tess acknowledges the escalation. After a delay (bridge processing takes 10-60s depending on complexity), you receive the result via Telegram.

---

## Step 5: Check Automated Messages

Tess Mechanic sends automated messages on schedule:

| Message Type | Schedule | Content |
|-------------|----------|---------|
| Awareness check | Every 30 min (waking hours) | System status, pending items, health alerts |
| Health ping | Every 15 min | Dead man's switch (absence = problem) |
| Email triage | Every 30 min (waking hours) | New email classifications and labels |
| Daily attention | 6:30 AM | Focus plan for the day |

**Expected outcome:** You receive periodic status messages without asking. These are informational — no action required unless they flag a problem.

---

## Step 6: Use Telegram Commands

Tess responds to specific command patterns for operational tasks. Examples:
- Feedback on feed-intel items (reply to digest messages)
- Status queries ("what's the pipeline status?")
- Quick vault lookups ("what's the latest on project X?")

**Expected outcome:** Tess processes commands and responds with structured information.

---

## What You've Learned

- Tess Voice (Kimi K2.5 via OpenRouter) handles conversation; Tess Mechanic (local Nemotron) handles automated checks
- Voice can read but not write to the vault
- Escalation to Crumb goes through the bridge (inbox → watcher → Claude Code → outbox)
- Automated messages arrive on schedule without prompting
- DM pairings are in-memory only — re-pair after gateway restart

**Next:** See [[why-two-agents]] for the rationale behind the Tess/Crumb split.
