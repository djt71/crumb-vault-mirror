---
type: recommendation
domain: software
project: tess-operations
status: draft
created: 2026-02-27
updated: 2026-02-27
tags:
  - cost-optimization
  - heartbeat
  - openclaw
  - tess
---

# Recommendation: Voice Heartbeat Cost Optimization

## Problem

The voice agent heartbeat is the single largest cost driver in the tess-operations plan, estimated at $15–45/month — roughly 50–65% of the entire chief-of-staff budget. It runs Haiku 4.5 every 30 minutes during waking hours (8 AM–11 PM ET), producing ~900 API calls/month. Most ticks return HEARTBEAT_OK with minimal value generated.

## Findings

### OpenClaw supports a heartbeat model override — but it's broken

The `agents.defaults.heartbeat.model` field is documented at `docs.openclaw.ai/gateway/heartbeat` and allows specifying a different model for heartbeat runs than the agent's primary model. The config structure:

```json
{
  "agents": {
    "defaults": {
      "heartbeat": {
        "every": "30m",
        "model": "ollama/tess-mechanic:30b"
      }
    }
  }
}
```

However, three open GitHub issues confirm this feature is broken in the current v2026.2.x release line:

- **#9556** — heartbeat.model override silently ignored; heartbeat uses primary model regardless of config. Reproduced at both `agents.defaults` and per-agent `agents.list[]` levels.
- **#14279** (2026-02-11) — same behavior confirmed. Workaround identified: `openclaw cron` with `--session isolated` correctly respects model overrides.
- **#22133** (2026-02-20) — worse: when the override *does* activate, it bleeds into the main session, replacing the primary model and dropping the context window, causing a compounding feedback loop.

**Conclusion:** The native heartbeat.model override cannot be used until these bugs are resolved upstream. It is unsafe to attempt — #22133 shows it can corrupt the main voice session.

### The voice heartbeat workload doesn't require a cloud model

Current voice HEARTBEAT.md checklist (6 items):

1. Check `_openclaw/inbox/` for stale items (>2 hours) → alert
2. Check `_openclaw/outbox/` for unrelayed dispatch results → relay
3. Check pipeline services running → alert
4. Check vault mirror staleness (>24h) → note
5. Check for unsummarized x-feed-intel digests → flag
6. If nothing → HEARTBEAT_OK

Items 1, 3, 4 are binary shell checks. Items 2 and 5 involve reading content and composing a message. Item 6 is a no-op. The cheap-checks-first pattern already runs shell commands before the LLM — the LLM mostly confirms "nothing wrong" and emits HEARTBEAT_OK.

### The local model infrastructure already exists

`tess-mechanic:30b` (qwen3-coder:30b with 65K context) is already loaded and warm on Ollama with `OLLAMA_KEEP_ALIVE=-1`. The mechanic agent already runs heartbeat checks every 60 minutes 24/7 at zero marginal cost. No new model installation or infrastructure is needed.

### Peer review results

Four external reviewers (DeepSeek, Gemini, ChatGPT, Perplexity) were consulted. All four confirmed the thesis that heartbeat is suitable for local inference. However:

- DeepSeek and Gemini fabricated config schemas, nonexistent tools, and fake benchmark numbers. Low signal.
- Perplexity misunderstood "voice heartbeat" as an audio pipeline. Zero signal.
- ChatGPT correctly identified the `heartbeat.model` field (verified), recommended the hybrid architecture, and was the most useful — though it did not identify the bugs that make the feature unusable.

The bug discovery (issues #9556, #14279, #22133) came from direct documentation research, not from any reviewer.

## Recommendation

### Approach: Replace voice heartbeat with local-model cron job + mechanic heartbeat expansion

Since the native `heartbeat.model` override is broken, use the confirmed workaround: `openclaw cron` with `--session isolated`, which correctly respects model overrides.

**Step 1 — Expand mechanic HEARTBEAT.md (absorb binary checks)**

Move items 1, 3, 4 from the voice heartbeat to the mechanic's HEARTBEAT.md. These are binary pass/fail checks that don't need Haiku:

- Inbox staleness (>2 hours)
- Pipeline service status
- Vault mirror staleness (>24h)

The mechanic already runs every 60 minutes 24/7 at zero cost and can alert via Telegram on failure. This is a HEARTBEAT.md edit, not an architectural change.

**Step 2 — Create a cron job for content-aware checks**

Replace voice heartbeat items 2 and 5 (outbox relay, digest summarization) with a cron job:

```
openclaw cron add \
  --name "Awareness check" \
  --cron "*/30 7-23 * * *" \
  --tz "America/Detroit" \
  --session isolated \
  --model "ollama/tess-mechanic:30b" \
  --message "Check _openclaw/outbox/ for dispatch results not yet relayed — if found, compose and send a Telegram summary. Check for new x-feed-intel digests not yet surfaced — if found, flag via Telegram. If nothing needs attention, exit silently." \
  --channel telegram
```

The `--session isolated` flag ensures the local model is used (per #14279 workaround) and prevents session bleed (per #22133). The cron guardrails from TOP-051 (single-flight lock, wall time, kill-switch) apply automatically via `cron-lib.sh`.

**Step 3 — Reduce or disable voice heartbeat**

With monitoring moved to the mechanic and content-aware checks moved to a local-model cron job, the voice agent's HEARTBEAT.md can be either:

- **Disabled** (`every: "0m"`) — voice agent only fires for Telegram conversations. Simplest, cheapest.
- **Reduced to a single lightweight check** (e.g., "if there are pending approval requests, nudge via Telegram") at a longer interval (2–4 hours) as a safety net.

Disabling is recommended for M1. A lightweight safety-net heartbeat can be added later if operational experience reveals gaps.

### Cost impact

| Component | Current estimate | After optimization |
|-----------|------------------|--------------------|
| Voice heartbeat (Haiku) | $15–45/month | $0–3/month |
| Mechanic heartbeat (local) | $0 | $0 |
| Awareness cron job (local) | N/A | $0 |
| Morning briefing (Haiku) | $1–3 | $1–3 |
| Other voice jobs (Haiku) | $6–19 | $6–19 |
| **Chief-of-staff total** | **$30–70** | **$7–25** |
| Feed-intel (unchanged) | ~$45 | ~$45 |
| **Full stack total** | **$75–115** | **$52–70** |

The $100/month provider hard cap is no longer at risk of being hit. The $120 rollback trigger has comfortable headroom.

### Tradeoffs

1. **Alert message quality:** Messages composed by qwen3-coder:30b won't be as polished as Haiku's. For operational alerts ("pipeline stopped", "inbox stale"), this is acceptable. For digest summarization, quality should be monitored during the M1 gate evaluation period.

2. **Two mechanisms instead of one:** Monitoring is now split across mechanic heartbeat + cron job instead of a single voice heartbeat. This adds a small amount of operational complexity but uses well-understood primitives (both are already in the tess-operations design).

3. **Cron vs heartbeat semantics:** Cron runs in isolated sessions (no memory of previous ticks). Heartbeat runs in the agent's main session (can remember what it already checked). For the awareness checks described, session memory is not needed — each tick is independent.

4. **Future path:** When OpenClaw fixes the heartbeat.model bugs (#9556, #14279, #22133), the cron job can be migrated back to a native heartbeat with the local model override. The mechanic HEARTBEAT.md expansion should remain regardless — it's the right home for structural checks.

## Impact on tess-operations tasks

The following tasks require amendment:

- **TOP-006** (voice heartbeat config) — Reduce scope: either disable voice heartbeat or set to a long-interval safety net. Remove monitoring checks from voice HEARTBEAT.md.
- **TOP-007** (mechanic heartbeat config) — Expand scope: add inbox staleness, pipeline status, and mirror staleness checks to mechanic HEARTBEAT.md (items migrated from voice).
- **TOP-008** (initial HEARTBEAT.md entries) — Redistribute entries per the above split.
- **New task** — Create awareness-check cron job using local model with `--session isolated`.
- **§11 cost table** in tess-chief-of-staff-spec — Update voice heartbeat estimate from $15–45 to $0–3. Update chief-of-staff total from $30–70 to $7–25. Update full stack total from $75–115 to $52–70.
- **M1 gate cost criterion** — Can be tightened from ≤$3/day to ≤$1.50/day (optional, but the headroom supports it).

## Open question

Should the awareness cron job run every 30 minutes (matching current voice heartbeat frequency) or less often? Given that the mechanic already checks structural health every 60 minutes, and outbox relay / digest summarization are not time-critical (2-hour staleness threshold on inbox items), **60-minute frequency for the cron job is likely sufficient**. This halves the number of cron executions without meaningful impact on responsiveness.

## References

- OpenClaw heartbeat docs: `docs.openclaw.ai/gateway/heartbeat`
- Bug: heartbeat.model override ignored: `github.com/openclaw/openclaw/issues/9556`
- Bug: heartbeat.model override ignored (confirmed): `github.com/openclaw/openclaw/issues/14279`
- Bug: heartbeat.model bleeds into main session: `github.com/openclaw/openclaw/issues/22133`
- tess-chief-of-staff-spec §4 (heartbeat architecture), §11 (cost analysis)
- tess-model-architecture production-config.md §2.2 (model assignments), §2.6 (caching)
- tess-operations tasks.md — TOP-006, TOP-007, TOP-008
