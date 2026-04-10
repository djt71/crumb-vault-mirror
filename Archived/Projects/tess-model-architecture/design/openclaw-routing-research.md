---
type: research
project: tess-model-architecture
domain: software
created: 2026-02-22
updated: 2026-02-22
source: claude-ai-session
tags:
  - openclaw
  - routing
  - model-selection
  - multi-agent
  - bugs
unverified_citations:
  - "GitHub #14279 — heartbeat.model override ignored, filed against v2026.2.9"
  - "GitHub #13009 — heartbeat ignores heartbeat.model when session has modelOverride"
  - "GitHub #6671 — sub-agent model override not working for custom providers"
  - "GitHub #12246 — feature request for per-channel model overrides"
  - "GitHub #13008 — discussion on per-turn model routing"
  - "VelvetShark multi-model routing guide — community cost optimization patterns"
  - "OpenClaw docs: docs.openclaw.ai/concepts/multi-agent — multi-agent routing reference"
  - "OpenClaw docs: docs.openclaw.ai/gateway/heartbeat — heartbeat config reference"
---

# OpenClaw Routing Capabilities — Research Findings

**Date:** 2026-02-22
**Context:** Routing is the CRITICAL-path blocker for the tess-model-architecture project. The tiered architecture (cloud primary for persona, local for mechanical) requires OpenClaw to route different task types to different models. This research establishes what's possible, what's broken, and the recommended path.

## 1. Config Surface — What OpenClaw Supports

OpenClaw's `openclaw.json` provides five model routing mechanisms:

### Per-agent model (`agents.list[].model`)
Each agent in a multi-agent setup gets its own primary model. This is the most reliable routing mechanism — each agent is a fully separate entity with its own model, workspace, sessions, and auth profiles.

```json
{
  "agents": {
    "list": [
      { "id": "voice", "model": "anthropic/claude-haiku-4-5" },
      { "id": "mechanic", "model": "ollama/qwen3-coder:30b" }
    ]
  }
}
```

### Heartbeat model override (`agents.defaults.heartbeat.model`)
Documented to allow a separate model for periodic heartbeat runs.

```json
{
  "agents": {
    "defaults": {
      "heartbeat": {
        "every": "30m",
        "model": "ollama/qwen3-coder:30b"
      }
    }
  }
}
```

### Sub-agent model override (`agents.defaults.subagents.model`)
Documented to allow spawned sub-agents to use a different (usually cheaper) model.

### Multi-agent bindings
Route incoming messages to specific agents based on channel, peer, accountId, guildId, teamId. Precedence: peer > guildId > teamId > accountId > channel > default agent.

```json
{
  "bindings": [
    { "agentId": "voice", "match": { "channel": "telegram" } },
    { "agentId": "mechanic", "match": { "channel": "none" } }
  ]
}
```

### Model fallback chains
Primary model + ordered fallbacks, including cross-provider. If Anthropic is down, fall back to a different provider.

```json
{
  "model": {
    "primary": "anthropic/claude-haiku-4-5",
    "fallbacks": [
      "ollama/qwen3-coder:30b"
    ]
  }
}
```

### Runtime model switching (`/model`)
Slash command to switch models per session at runtime. Ephemeral — lost on restart.

## 2. Known Bugs — Model Override Failures

Three GitHub issues confirm that model override mechanisms are unreliable in recent versions:

### Bug: heartbeat.model ignored at runtime
- **Issue:** GitHub #14279 (filed Feb 9, 2026, against v2026.2.9)
- **Symptom:** `heartbeat.model` config field is documented but ignored. Heartbeats always use the main session's default model.
- **Impact:** Cannot route heartbeats to a cheaper/local model via config alone.
- **Workaround documented:** Use cron jobs with `--session isolated` — model overrides work correctly in isolated sessions.

### Bug: heartbeat.model overridden by session modelOverride
- **Issue:** GitHub #13009
- **Symptom:** When the active session has a `modelOverride` set (e.g., from a `/model` switch), the heartbeat inherits it instead of using its configured `heartbeat.model`. Root cause identified in source: `resolveReplyDirectives()` unconditionally overwrites the heartbeat model with the session's `modelOverride` — no `isHeartbeat` guard exists.
- **Impact:** Even if the heartbeat model config worked, a `/model` switch in the TUI would silently override it.
- **Workaround:** Manually edit `~/.openclaw/agents/main/sessions/sessions.json` to remove `modelOverride` fields after every `/model` switch. Fragile.

### Bug: sub-agent model override not working for custom providers
- **Issue:** GitHub #6671 (filed ~3 weeks ago)
- **Symptom:** `agents.defaults.subagents.model` is ignored. Sub-agents fall back to the main agent's model. Custom providers (including Ollama via OpenAI-compatible API) don't appear in `openclaw models list`. The `sessions_spawn` response shows `"modelApplied": true` but transcripts confirm the wrong model was used.
- **Impact:** Cannot route sub-agent work to a local model via config.
- **Workaround:** Shell scripts calling the local model endpoint directly via curl, bypassing OpenClaw's model routing entirely.

### Feature gap: no per-channel model overrides
- **Issue:** GitHub #12246 (feature request, Feb 9, 2026)
- **Status:** Open. Model can be set at agent, heartbeat, and subagent level, but not per-channel in config. Only available via ephemeral `/model` session override.

### Community discussion: per-turn model routing
- **Issue:** GitHub #13008 (discussion, not implemented)
- **Status:** Active discussion about cost-aware per-turn routing by task type. Not yet a feature. Community consensus: existing agent-level routing + manual `/model` switching is the current practical ceiling.

## 3. Version Relevance

Our installation: v2026.2.17. Upgrade queued: v2026.2.21 (blocked on bundler corruption #22841).

Bugs were filed against v2026.2.3 through v2026.2.9. Some may be fixed in v2026.2.17 or the upcoming v2026.2.21 — **this needs empirical verification on our stack.** Check the v2026.2.17 and v2026.2.21 changelogs for references to these issue numbers before assuming they're still broken.

## 4. Recommended Architecture: Two-Agent Split

Given the model override bugs, the most reliable routing approach is **two separate agents** rather than relying on per-task model overrides within a single agent.

### Proposed: `tess-voice` + `tess-mechanic`

| Agent | Model | Handles | Channel binding |
|-------|-------|---------|----------------|
| `tess-voice` | `anthropic/claude-haiku-4-5` (or Sonnet — pending persona eval) | All user-facing Telegram interactions, message triage, status queries, daily briefing, directive execution, vault queries with summarization | `telegram` |
| `tess-mechanic` | `ollama/qwen3-coder:30b` | Heartbeats, cron jobs, vault-check automation, file operations, bridge relay mechanics, structured data extraction | No channel binding (background only) |

### Why two agents instead of model overrides

1. **Sidesteps all three bugs.** Each agent has its own primary model at the agent level, which is the most reliable routing mechanism. No dependency on `heartbeat.model` or `subagents.model` overrides.
2. **Clean separation of concerns.** Each agent has its own workspace, sessions, memory, and SOUL.md. `tess-voice` loads the full persona; `tess-mechanic` gets a minimal operational identity.
3. **Independent fallback chains.** `tess-voice` falls back to `ollama/qwen3-coder:30b` (Limited Mode) if API is down. `tess-mechanic` falls back to cloud if local model crashes. Different failure modes, different mitigations.
4. **Aligned with OpenClaw's multi-agent architecture.** The docs, community guides, and agent teams feature all point toward multi-agent as the intended pattern for different-model-per-role setups. This is swimming with the current, not against it.

### Open questions for the spec / peer review

1. **Can `tess-voice` delegate sub-tasks to `tess-mechanic`?** The research found a proposed `message_agent(agent_id, content)` broker tool pattern but it's described as a future extension, not current capability. If agents can't delegate to each other, `tess-voice` would need to handle some mechanical work itself (or call Ollama directly as a tool endpoint). This is the key integration question.
2. **Shared memory / vault access.** Both agents need read access to the vault. With the `crumbvault` group already set up (OC-010), filesystem access is handled. But do both agents share session memory, or is memory per-agent? If per-agent, `tess-voice` won't know what `tess-mechanic` did in background tasks unless state is externalized (to vault files, which is already the Crumb pattern).
3. **Single gateway or two?** The docs say "the Gateway can host one agent (default) or many agents side-by-side." A single gateway hosting both agents is simpler operationally. Verify this works with mixed providers (Anthropic + Ollama).
4. **Heartbeat ownership.** If `tess-mechanic` owns heartbeats, it needs a way to surface findings to `tess-voice` for user-facing delivery. Or `tess-mechanic` handles heartbeats silently and only writes to vault/inbox when action is needed, which `tess-voice` picks up on next interaction.
5. **SOUL.md per agent.** `tess-voice` gets the full SOUL.md + IDENTITY.md. What does `tess-mechanic` get? Minimal operational identity focused on reliability and schema compliance — no persona, no humor, no second register. This needs to be defined.
6. **Bug verification.** Test `heartbeat.model` and `subagents.model` overrides on v2026.2.17 before committing to the two-agent split. If the bugs are fixed, a single-agent architecture with model overrides is simpler and may be preferable.

## 5. Alternative: OpenRouter Auto

OpenRouter offers `openrouter/openrouter/auto` which automatically routes based on prompt complexity — simple prompts to cheap models, complex to capable. This is a zero-config option but:

- No control over which model handles which task
- Routing decisions are opaque
- Can't guarantee persona consistency (different models on different turns)
- Adds a third-party dependency (OpenRouter) on top of Anthropic

**Not recommended for Tess** given the persona fidelity requirements, but worth noting as a community pattern.

## Sources

- OpenClaw multi-agent docs: `docs.openclaw.ai/concepts/multi-agent`
- OpenClaw heartbeat docs: `docs.openclaw.ai/gateway/heartbeat`
- GitHub #14279: heartbeat.model override ignored
- GitHub #13009: heartbeat ignores configured model when session has modelOverride
- GitHub #6671: sub-agent model override not working for custom providers
- GitHub #12246: feature request for per-channel model overrides
- GitHub #13008: discussion on per-turn cost-aware routing
- VelvetShark: multi-model routing guide (community)
- OpenRouter: OpenClaw integration docs
- Medium (Bibek Poudel): OpenClaw architecture deep-dive
- SitePoint: OpenClaw 4-week production lessons
