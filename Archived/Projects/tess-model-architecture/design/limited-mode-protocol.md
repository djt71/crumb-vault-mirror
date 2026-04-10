---
type: design
project: tess-model-architecture
domain: software
created: 2026-02-22
updated: 2026-02-22
tags:
  - limited-mode
  - fallback
  - resilience
  - openclaw
---

# Limited Mode Protocol

## 1. Purpose

Limited Mode is Tess's graceful degradation state during Anthropic API outages.
It is a first-class design requirement (spec §6.5), not a risk mitigation entry.
This document specifies the trigger conditions, model swap mechanism, scope enforcement,
user notification, recovery logic, and operational boundaries.

**Design principle:** "Some Tess rather than no Tess." Limited Mode provides captures
and triage — not persona, judgment, or second register.

## 2. Trigger Conditions

### 2.1 Entry Trigger

Limited Mode activates when `tess-voice` encounters **3 consecutive failures**
from the Anthropic API on a single routing attempt.

**Qualifying failures:**
- HTTP 503 (Service Unavailable)
- HTTP 429 (Rate Limited) — only if retry-after exceeds 60 seconds
- HTTP 500 (Internal Server Error)
- Connection timeout (no response within 30 seconds)
- TCP connection refused / DNS resolution failure

**Non-qualifying events (do not trigger Limited Mode):**
- HTTP 400 (Bad Request) — config error, not outage
- HTTP 401/403 (Auth error) — credential issue, not outage
- Single transient 503 followed by successful retry — normal retry behavior
- Ollama failures — `tess-mechanic` has its own fallback chain; Limited Mode is
  `tess-voice`-specific

### 2.2 Counting Logic

The failure counter is **per routing attempt**, not per API call. OpenClaw's built-in
retry policy may fire multiple retries within a single routing attempt. The 3-consecutive
threshold counts routing-level failures (i.e., OpenClaw exhausted its retry budget
and returned an error to the agent).

The counter resets on any successful Anthropic API response.

### 2.3 State Transition

```
NORMAL ──[3x consecutive failure]──► LIMITED MODE
                                         │
                                    [health check success]
                                         │
LIMITED MODE ──[API restored]──────► NORMAL
```

There is no intermediate state. Tess is either in Normal mode (cloud primary) or
Limited Mode (local fallback). No gradual degradation.

## 3. Model Swap Mechanism

### 3.1 Fallback Activation

When Limited Mode triggers, `tess-voice` switches from its primary model
(`anthropic/claude-haiku-4-5`) to its fallback model (`ollama/qwen3-coder:30b`).

This is implemented via OpenClaw's model fallback chain (F18):

```json
{
  "id": "voice",
  "model": "anthropic/claude-haiku-4-5",
  "fallbacks": ["ollama/qwen3-coder:30b"]
}
```

**Important:** The fallback chain is OpenClaw's native mechanism. Limited Mode does NOT
require manual model switching or gateway restart. OpenClaw handles the failover
automatically when the primary model is unreachable.

### 3.2 System Prompt Swap

When `tess-voice` is operating on the local fallback model, the full SOUL.md +
IDENTITY.md system prompt is inappropriate — the local model cannot faithfully
execute the persona, and attempting to do so produces brittle judgment and
invisible drift (spec §6.5).

**Limited Mode system prompt** (replaces SOUL.md + IDENTITY.md during fallback):

```
You are Tess, operating in limited local mode. Your cloud connection is
temporarily unavailable.

ALLOWED:
- Capture and acknowledge incoming messages
- Triage requests by urgency (flag anything time-sensitive)
- Answer direct factual questions from vault content
- Run read-only vault queries
- Report system status when asked

NOT ALLOWED:
- Give advice or make recommendations
- Use humor, personality, or second register
- Execute multi-step plans or complex decisions
- Initiate destructive operations or state changes
- Compose original content (drafts, summaries with judgment)

Keep responses short and factual. Acknowledge what you captured.
If something needs the full Tess, say so: "Captured — I'll handle
this properly when cloud is restored."
```

**Implementation:** The system prompt swap requires either:
- OpenClaw config support for per-fallback system prompts (check if available), OR
- A middleware/hook that detects the active model and swaps the system prompt
  accordingly, OR
- The Limited Mode system prompt appended to SOUL.md with a conditional
  instruction: "If you are running as qwen3-coder, follow Limited Mode rules."

The first option is preferred. The third is the simplest fallback but relies on
the local model correctly self-identifying, which is fragile. TMA-002 should test
which mechanism is viable.

### 3.3 What Does Not Change

- `tess-mechanic` continues operating normally — it already runs on the local model
- Heartbeats and cron jobs are unaffected
- Vault read/write permissions remain the same
- The bridge confirmation echo (MC-6) remains enforced — Limited Mode does not
  bypass safety invariants

## 4. Scope Enforcement

### 4.1 Tool Allowlist (Limited Mode)

In Limited Mode, `tess-voice` operates with a restricted tool set. The enforcement
point is the **router/gateway level**, not model instruction alone. Model instructions
provide defense in depth; the tool allowlist provides hard enforcement.

**Allowed tools (read-only + capture):**

| Tool | Purpose | Notes |
|------|---------|-------|
| `vault_read` / `file_read` | Read vault files | Read-only access to vault content |
| `vault_search` | Search vault | Query vault index |
| `vault_list` | List vault contents | Directory listing |
| `inbox_write` | Capture to inbox | Write incoming requests/data to `_inbox/` for later processing |
| `message_send` | Send Telegram message | Required for user communication |
| `status_check` | System status | Report gateway/service health |

**Disallowed tools (blocked at gateway level):**

| Tool Category | Examples | Reason |
|---------------|----------|--------|
| Write/modify vault | `vault_write`, `file_write`, `file_edit` | No state changes during degraded mode |
| Execute commands | `bash`, `shell`, `command` | No actuation |
| External API calls | `web_fetch`, `web_search` | No external dependencies during outage |
| Bridge operations | `bridge_dispatch`, `bridge_confirm` | No destructive operations |
| Agent delegation | `message_agent` | No cross-agent calls during degraded state |
| Scheduled actions | `cron_create`, `reminder_set` | No future commitments |

**Implementation:** OpenClaw's tool configuration supports per-agent tool definitions.
During Limited Mode, the tool set must be dynamically restricted. Options:
1. OpenClaw supports runtime tool list modification (preferred)
2. Gateway middleware intercepts and rejects disallowed tool calls
3. Separate agent config with restricted tools, activated on fallback

TMA-002 should determine which mechanism is available.

### 4.2 No-Actuation Policy

Beyond the tool allowlist, Limited Mode enforces a behavioral policy:

- **No advice voice:** The local model must not give recommendations, suggestions,
  or evaluative judgments. It captures, triages, and reports facts.
- **No multi-step decisions:** If a request requires judgment across multiple
  considerations, capture it and defer: "Captured for full processing when restored."
- **No creative output:** No drafting, summarizing with interpretation, or
  composing original content.
- **No destructive operations:** Even if a destructive tool somehow passes the
  allowlist, the model must not initiate destructive actions. MC-6 (bridge
  confirmation echo) provides the hard enforcement layer regardless.

### 4.3 Scope Boundary Examples

| Request | Normal Mode | Limited Mode |
|---------|-------------|--------------|
| "What's on my calendar today?" | Full response with context | Vault read → factual answer |
| "Should I take that job offer?" | Second register, vault precedent, advice | "Captured. I'll give this proper attention when cloud is restored." |
| "Run vault-check" | Execute and report | "Captured. Vault-check deferred to full mode." (Or: mechanic handles it independently.) |
| "What did we discuss about X?" | Vault search + persona summary | Vault search → raw results, no interpretive summary |
| "Send a message to Y" | Compose + send with persona | "Captured. Message drafting deferred to full mode." |
| "What's the system status?" | Status report | Status report (allowed — factual) |

## 5. User Notification

### 5.1 Entry Notification

When Limited Mode activates, send immediately to the Telegram channel:

```
⚠ Tess is in limited local mode — cloud connection unavailable.
I can capture messages and check vault content, but responses
will be flat and I can't give advice or run complex tasks.
I'll let you know when full mode is restored.
```

**Delivery:** Single message, not repeated. The banner persists as a conversation
marker — the user can scroll up to see when Limited Mode started.

### 5.2 Recovery Notification

When Limited Mode exits (cloud restored):

```
✓ Cloud restored — full mode active. Processing any captured items now.
```

Followed by a summary of captured-but-deferred items, if any:
```
Deferred items from limited mode:
- [request 1] — captured [time]
- [request 2] — captured [time]
```

### 5.3 Duration Escalation

If Limited Mode persists for **>4 hours**, send an operator escalation message:

```
⚠ Limited mode active for [duration]. Anthropic API has not recovered.
Manual investigation may be needed.
Last health check: [timestamp] — [result]
```

This repeats every 4 hours until recovery or manual intervention.

## 6. Auto-Recovery Logic

### 6.1 Health Check

While in Limited Mode, `tess-voice` runs a periodic health check against
the Anthropic API.

| Parameter | Value |
|-----------|-------|
| Interval | Every 5 minutes |
| Method | Lightweight API call (e.g., model list endpoint or minimal completion) |
| Success criterion | HTTP 200 with valid response body |
| Failure action | Remain in Limited Mode, log health check failure |
| Success action | Exit Limited Mode, send recovery notification |

### 6.2 Recovery Sequence

On health check success:

1. Switch `tess-voice` back to primary model (`anthropic/claude-haiku-4-5`)
2. Restore full system prompt (SOUL.md + IDENTITY.md)
3. Restore full tool allowlist
4. Send recovery notification (§5.2)
5. Process deferred items queue (if any captured during Limited Mode)
6. Reset failure counter to 0

### 6.3 Health Check Implementation

**Preferred:** OpenClaw's fallback chain handles recovery automatically when the
primary model becomes reachable again. Verify in TMA-002 whether OpenClaw:
- Automatically retries the primary model on subsequent requests, or
- Requires explicit intervention to revert from fallback to primary

If OpenClaw doesn't auto-recover, implement a health check cron task on
`tess-mechanic` that pings the Anthropic API and triggers a gateway reload
on success.

### 6.4 Duration Cap

| Duration | Action |
|----------|--------|
| 0–4 hours | Normal Limited Mode operation with 5-min health checks |
| 4+ hours | Escalation message to operator (§5.3), repeated every 4 hours |
| 24+ hours | No automatic action — operator must decide whether to accept extended degradation or take manual action |

There is no automatic shutdown or mode change at any duration threshold.
Limited Mode runs indefinitely until API recovery or operator intervention.

## 7. Enforcement Architecture

```
┌─────────────────────────────────────────────────────┐
│                  OpenClaw Gateway                     │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │              tess-voice                        │   │
│  │                                                │   │
│  │  ┌──────────────┐     ┌──────────────────┐   │   │
│  │  │ Model Router  │     │ Tool Allowlist    │   │   │
│  │  │               │     │ (gateway-level)   │   │   │
│  │  │ Primary:      │     │                   │   │   │
│  │  │  Haiku 4.5    │     │ Normal: full set  │   │   │
│  │  │               │     │ Limited: read +   │   │   │
│  │  │ Fallback:     │     │   capture only    │   │   │
│  │  │  qwen3-coder  │     │                   │   │   │
│  │  └──────────────┘     └──────────────────┘   │   │
│  │                                                │   │
│  │  ┌──────────────┐     ┌──────────────────┐   │   │
│  │  │ System Prompt │     │ Scope Policy      │   │   │
│  │  │ Selector      │     │ (model instruction│   │   │
│  │  │               │     │  + gateway guard)  │   │   │
│  │  │ Normal: SOUL  │     │                   │   │   │
│  │  │ Limited: min  │     │ Defense in depth: │   │   │
│  │  └──────────────┘     │ prompt + gateway   │   │   │
│  │                        └──────────────────┘   │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │              tess-mechanic                     │   │
│  │  (unaffected by Limited Mode — runs local     │   │
│  │   model in all states)                         │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  Health Check (5-min interval)                 │   │
│  │  Runs during Limited Mode only                 │   │
│  │  Pings Anthropic API → triggers recovery       │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

**Enforcement layers (defense in depth):**
1. **Model fallback chain** — OpenClaw automatically routes to local model on API failure
2. **System prompt swap** — Limited Mode prompt replaces SOUL.md
3. **Tool allowlist** — Gateway blocks disallowed tools
4. **Scope policy in prompt** — Model instructed on behavioral boundaries
5. **MC-6 (bridge)** — Safety invariant enforced by bridge regardless of mode

Layers 1 and 3 are hard enforcement (gateway-level). Layers 2 and 4 are soft
enforcement (model instruction — can be overridden by sufficiently adversarial input,
but the hard layers catch it). Layer 5 is system-level enforcement independent of
all other layers.

## 8. Integration Points

### 8.1 With Routing Specification (TMA-001)

- Limited Mode is scenario RT-4 and FB-2 in the routing specification
- Fallback chain config (§3.1) must match the routing spec §3 config schema
- DL-5 (delegation during Limited Mode) is covered in §4.3 scope boundaries

### 8.2 With TMA-002 (Routing PoC)

TMA-002 must validate:
- Fallback chain triggers correctly on simulated API failure
- System prompt swap mechanism is viable (which of the three options from §3.2 works)
- Tool allowlist restriction mechanism is available in OpenClaw
- Recovery sequence works (primary model restored after API recovery)
- Degradation banner sends successfully via Telegram

### 8.3 With TMA-008 (Config Draft)

The production `openclaw.json` must include:
- Fallback chain for `tess-voice` (§3.1)
- Limited Mode system prompt (§3.2) — mechanism determined by TMA-002
- Tool allowlist configuration (§4.1) — mechanism determined by TMA-002
- Health check configuration (§6.1) — if not handled by OpenClaw natively

### 8.4 With TMA-009 (Integration Test)

Integration test must exercise:
- API failure simulation → Limited Mode entry → degradation banner
- Scope restriction verified (disallowed tools actually blocked)
- Auto-recovery on API restoration → recovery notification
- Duration cap escalation at 4-hour mark (can be simulated with clock manipulation)
- Binary checks: no Limited Mode response uses disallowed tools (YES/NO),
  duration cap enforced (YES/NO), state sync verified during Limited Mode (YES/NO)

## 9. Operational Notes

### 9.1 Monitoring

During production operation, log the following Limited Mode events:
- Entry timestamp + trigger cause (which failure type)
- Health check results (pass/fail + timestamp)
- Recovery timestamp
- Duration of each Limited Mode episode
- Count of deferred items
- Escalation messages sent

### 9.2 Known Limitations

- **No persona during Limited Mode.** This is by design, not a bug. The local model
  cannot faithfully execute SOUL.md. Attempting to do so produces invisible drift
  that erodes trust faster than obviously flat output.
- **No proactive behavior.** Limited Mode Tess does not initiate — she only responds.
  Background tasks (heartbeats, cron) continue via `tess-mechanic` independently.
- **Deferred item queue is not guaranteed.** If Limited Mode persists across a
  gateway restart, the in-memory deferred queue is lost. Vault-persisted captures
  (`_inbox/` writes) survive.

### 9.3 What Limited Mode Is NOT

- Not a permanent operating mode (spec §6.5)
- Not an alternative architecture
- Not a test of local model persona capability
- Not a cost optimization (it's a resilience mechanism)
