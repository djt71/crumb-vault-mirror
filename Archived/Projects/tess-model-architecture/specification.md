---
type: specification
project: tess-model-architecture
domain: software
skill_origin: systems-analyst
created: 2026-02-22
updated: 2026-02-22T23:30
tags:
  - local-llm
  - tess
  - openclaw
  - model-selection
  - tiering
  - routing
---

# Tess Model Architecture — Specification

## 1. Problem Statement

Tess (the OpenClaw agent) needs a model architecture that preserves her persona fidelity while running cost-effectively on shared hardware (Mac Studio M3 Ultra 96GB, co-hosting Crumb). The architecture must define which models serve which roles, how requests route between local and cloud inference, and how Tess degrades gracefully during API outages. A naive local-first approach sacrifices the persona quality defined in SOUL.md; a naive cloud-only approach creates an availability dependency with no fallback. The solution is a personality-first tiered architecture — cloud primary for user-facing interactions, local for mechanical execution, with a formally specified Limited Mode for resilience.

## 2. Decision History

This architecture went through three iterations in one day. The research thread established cloud-primary with 5-model peer review consensus. Revision 1 proposed local-first to reduce API dependency. Cost analysis showed the delta between cloud and local is negligible (~$8.70/month Haiku vs ~$6.50–10.40/month electricity). Revision 2 restored cloud-primary, incorporating the cost evidence and elevating Limited Mode from a risk entry to a design requirement.

| Date | Revision | Decision | Driver |
|------|----------|----------|--------|
| 2026-02-21 | Research thread | Cloud-primary, personality-first tiering | 5-model peer review, 2 rounds — unanimous endorsement |
| 2026-02-22 | Revision 1 | Revert to local-first | Independence from Anthropic API |
| 2026-02-22 | Cost analysis | Evidence gathering | Haiku ~$8.70/mo vs electricity ~$6.50–10.40/mo |
| 2026-02-22 | **Revision 2 (current)** | **Restore cloud-primary** | Cost delta negligible; independence mitigated by local fallback; alternative framings collapsed to same architecture |

## 3. Facts

- **F1.** Hardware: Mac Studio M3 Ultra, 96GB unified memory, shared between Crumb (Claude Code sessions), OpenClaw (Tess), Obsidian, Docker, and general macOS processes. *[Research thread §1]*
- **F2.** Tess runs as OpenClaw (Node.js gateway) under a dedicated `openclaw` macOS user, always-on via LaunchDaemon, bound to `ws://127.0.0.1:18789`. *[Crumb-Tess bridge spec F2]*
- **F3.** Ollama serves local models via OpenAI-compatible API. The `ollama launch openclaw` command (Feb 2026 release) handles provider config and model discovery. Manual config addition preferred to preserve hardened `openclaw.json`. *[Research thread §1]*
- **F4.** `qwen3-coder:30b` is a 30B MoE model (~3.3B active parameters), ~19GB at Q4_K_M quantization, 256K native context (effective ~100K per community reports, irrelevant for our 64K target). Non-thinking mode only. *[Research thread §1 model table]*
- **F5.** `qwen3-coder-next` is an 80B hybrid Mamba-Transformer MoE (~3.9B active), ~48GB at Q4_K_M. Mamba layers reduce KV cache vs pure Transformer. Memory-tight on shared 96GB. Requires Flash Attention validation in Ollama Metal backend. *[Research thread §1 model table]*
- **F6.** GLM-4.7-flash has Ollama chat template compatibility warnings (Unsloth docs). Community reports mixed. *[Research thread §1, §4]*
- **F7.** OpenClaw requires `openai-completions` provider format, not `openai-responses` (which calls `/v1/responses` and hangs). Single GitHub report; status in current release unknown. *[Research thread §1]*
- **F8.** KV cache silently truncates when `num_ctx` defaults to 2048–4096. Must set explicitly in Modelfile: `PARAMETER num_ctx 65536`. *[Research thread risk register]*
- **F9.** Haiku 4.5 pricing: $1.00/M input, $5.00/M output, $0.10/M cached input (90% savings). Projected cost with caching: ~$8.70/month for full Tess workload (~135 daily requests). *[Cost analysis]*
- **F10.** Sonnet 4.5 pricing: $3.00/M input, $15.00/M output. Projected cost with caching: ~$22.50/month. Operator comfortable with this tier. *[Cost analysis, Revision 2]*
- **F11.** Local inference electricity cost on Mac Studio: ~$6.50–10.40/month at Michigan residential rates (~$0.18/kWh, 50–80W sustained). *[Cost analysis §Key Observations]*
- **F12.** The `developer` role mismatch bug causes silent failures when `reasoning: true` with Ollama. OpenClaw sends `developer` role, which Ollama doesn't support. *[Research thread §2]*
- **F13.** Tess has two registers per SOUL.md: default operator mode (short, direct, tool-driven) and a second register (vault precedent, philosophical parallels, reframing). The second register requires frontier-model language capability. *[Research thread §3]*
- **F14.** System prompt overhead per request: ~8,500 tokens (SOUL.md + IDENTITY.md + 40 tool definitions + system instructions). Prompt caching is a 10x reduction on this fixed cost — it is what makes the cloud-primary architecture economically viable at scale. Without caching, system prompt repetition is the dominant cost ($1.15/day). With caching, the dominant cost shifts to output tokens (which can't be cached). *[Cost analysis]*
- **F15.** OpenClaw provides five model routing mechanisms: per-agent model (`agents.list[].model`), heartbeat model override, sub-agent model override, multi-agent channel bindings, and model fallback chains. Per-agent model is the most reliable — each agent is a fully separate entity with its own model, workspace, sessions, and identity. *[Routing research §1]*
- **F16.** Three confirmed bugs break single-agent model overrides: (a) `heartbeat.model` config field ignored at runtime (GitHub #14279, v2026.2.9); (b) session `modelOverride` from `/model` switch clobbers `heartbeat.model` — no `isHeartbeat` guard in `resolveReplyDirectives()` (GitHub #13009); (c) `subagents.model` override ignored for custom providers including Ollama (GitHub #6671). *[Routing research §2]*
- **F17.** Multi-agent channel bindings route incoming messages to specific agents by channel, peer, accountId, guildId, teamId. Binding `tess-voice` to `channel: telegram` and leaving `tess-mechanic` for background work is a supported config pattern. *[Routing research §1, §4]*
- **F18.** Model fallback chains support cross-provider failover in config: primary model + ordered fallbacks. This enables `tess-voice` to fall back from Anthropic to Ollama automatically. *[Routing research §1]*
- **F19.** Current installation: OpenClaw v2026.2.17. Upgrade to v2026.2.21 blocked on bundler corruption (#22841). Routing bugs were filed against v2026.2.3–v2026.2.9 — some may be fixed in v2026.2.17 or v2026.2.21 but this needs empirical verification. v2026.2.21 adds per-channel model overrides (`channels.modelByChannel`) which may enable single-agent simplification — but upgrade is currently blocked. *[Routing research §3, operator input 2026-02-22]*
- **F20.** Anthropic prompt caching: cache write costs 1.25x base input (5-min TTL) or 2x (1-hour TTL). Cache read costs 0.1x base input (90% discount). 5-min TTL refreshes on every hit. Exact prefix match required — any change to cached content invalidates it. Up to 4 cache breakpoints per request. *[Caching research §1]*
- **F21.** Heartbeats at 15–30 min intervals exceed the default 5-min cache TTL. Each heartbeat pays full cache write cost instead of a cache read, negating the caching benefit on the highest-volume request type. The two-agent split eliminates this — heartbeats run locally on `tess-mechanic`, so the cloud model's cache only needs to survive between user-initiated messages, which cluster in active-use periods. *[Caching research §2]*
- **F22.** System prompt size directly multiplies cost and reduces available context window. At 9,500 tokens, ~1.28M tokens/day input; at 3,500 tokens, ~473K tokens/day. Cost savings from compression are modest (~$2.40/month) but context window preservation is significant for multi-turn conversations. *[Caching research §3]*

## 4. Assumptions

- **A1.** The two-agent split (`tess-voice` + `tess-mechanic`) with channel bindings provides reliable audience-based routing, sidestepping the known model override bugs (F16). Per-agent model assignment (F15) is the routing mechanism. *[Validate: routing PoC, TMA-002. Partially validated by routing research — mechanism identified, empirical test pending]*
- **A2.** ~~Haiku 4.5 is sufficient to carry the SOUL.md persona for routine interactions. Sonnet 4.5 may be needed for second-register fidelity.~~ **Confirmed (TMA-006).** Haiku 4.5 passes all hard gates (PC-1 100%, PC-2 100%, PC-3 100%) and matches Sonnet on second register (PT-4 100%). Haiku outperforms Sonnet on ambiguity handling (PC-3: 100% vs 71%). Decision: **Haiku 4.5 as sole voice model.** Mixed tier unnecessary.
- **A3.** The 30B MoE model's ~3.3B active parameters provide adequate instruction-following (IF) scores for deterministic tool calling. 85% JSON validity (one unverified report) would be insufficient — target is >95%. *[Validate: local benchmark, TMA-007]*
- **A4.** `OLLAMA_KEEP_ALIVE=-1` keeps the model loaded permanently, avoiding cold-start latency. This is the intended deployment mode. *[Validate: TMA-007]*
- **A5.** ~~The 30B model at Q4_K_M leaves ~55GB headroom on 96GB unified memory under defined load shape.~~ **Confirmed (TMA-005).** Measured: 21.3 GB peak RSS at 64K context, 51+ GB available, zero swap. 80B model estimated viable at ~21 GB headroom. See `design/memory-budget.md`.
- **A6.** Prompt caching with Haiku 4.5 is available and behaves as documented (90% savings on cached input). Without caching, monthly cost rises from ~$8.70 to ~$39.60. Caching is a prerequisite for the cost model, not an optimization. *[Validate: integration test, TMA-010]*
- **A7.** ~~OpenClaw either supports Anthropic's `cache_control` parameter natively or can be configured to include it in API calls.~~ **Confirmed (TMA-010a).** OpenClaw v2026.2.17 via pi-ai v0.53.0 applies `cache_control` automatically for API key auth. Default: `cacheRetention: "short"` (5-min TTL). `"long"` (1-hour) available via config override. No config changes needed for default caching behavior.
- **A8.** All cross-agent state is file/vault based. Neither agent may rely on the other's in-memory sessions for correctness. `tess-mechanic` writes findings to a shared vault location; `tess-voice` checks at the start of each Telegram turn. This follows the existing Crumb pattern (vault as single source of truth). *[Validate: TMA-002 session isolation test, TMA-009 integration]*

## 5. Unknowns

### Critical

- **U1.** ~~Can OpenClaw route by task type / agent?~~ **Partially resolved.** Routing research (F15–F18) identifies the two-agent split as the recommended mechanism, sidestepping known model override bugs. Remaining unknowns: inter-agent delegation (U9), shared memory behavior (U10), mixed-provider gateway hosting (U11). Empirical validation on v2026.2.17 still required. *[Source: routing research §4]*
- **U2.** ~~Does the `openai-completions` vs `openai-responses` API format issue persist in the current OpenClaw release?~~ **Resolved (TMA-002/010a).** `openai-completions` format works with Anthropic provider on v2026.2.17. Gateway routes correctly, responses return as expected. The issue either doesn't apply or was fixed.
- **U13.** ~~Does OpenClaw pass `cache_control` to the Anthropic API natively?~~ **Resolved (TMA-010a).** Yes — native support via pi-ai Anthropic provider. `cache_control` applied to system prompt blocks and last user message automatically. Default 5-min TTL with API key auth. Cost model validated. See `design/api-caching-probe-results.md`.

### High

- **U3.** Can Haiku 4.5 carry the SOUL.md second register — dry humor, vault precedent surfacing, tone-shift calibration — or does that require Sonnet 4.5? No predefined rubric has been tested. *[Source: research thread §3, §6 R1 pushback]*
- **U4.** What is the actual JSON tool-call validity rate for `qwen3-coder:30b` on OpenClaw's tool inventory? One unverified report claims 85% — if accurate, this would fail the mechanical contract. *[Source: research thread §7 R2, Grok]*
- **U5.** Does the hybrid Mamba-Transformer architecture of `qwen3-coder-next` deliver meaningful KV cache savings on Apple Silicon via Ollama's Metal backend? The Mamba-to-Transformer layer ratio determines actual reduction. *[Source: research thread §1 model table note]*
- **U9.** Can `tess-voice` delegate sub-tasks to `tess-mechanic`? Routing research found a proposed `message_agent(agent_id, content)` broker tool pattern described as a future extension, not current capability. If agents can't delegate, `tess-voice` handles some mechanical work itself or calls Ollama directly as a tool endpoint. This is the key integration question for mixed-task routing. *[Source: routing research §4]*

### Medium

- **U6.** What are actual memory measurements for the 30B model under defined load shape (64K context + 10 sequential tool calls + concurrent Obsidian + Docker + OpenClaw gateway)? Current estimates are theoretical. *[Source: research thread §1 memory budget]*
- **U7.** Does sustained inference on M3 Ultra under concurrent load cause thermal throttling? No reviewer besides Grok flagged this. *[Source: research thread §7 R2, Grok]*
- **U8.** What is Q5_K's accuracy uplift over Q4_K_M for structured tool output? Bartowski GGUF tests report ~2–3% general accuracy uplift. For JSON schema adherence specifically, the delta may differ. *[Source: research thread §7 R2, Grok]*
- **U10.** Do the two agents share session memory, or is memory per-agent? If per-agent, `tess-voice` won't know what `tess-mechanic` did in background tasks unless state is externalized to vault files (which is already the Crumb pattern). *[Source: routing research §4]*
- **U11.** Can a single OpenClaw gateway host both agents with mixed providers (Anthropic + Ollama)? Docs say "the Gateway can host one agent (default) or many agents side-by-side" — verify with mixed providers empirically. *[Source: routing research §4]*
- **U12.** Are the three routing bugs (F16) fixed in v2026.2.17 or v2026.2.21? If fixed, a simpler single-agent architecture with model overrides may be preferable to the two-agent split. Check changelogs for issue references before assuming they're still broken. *[Source: routing research §3]*

## 6. Architecture Overview

### 6.1 Tiering Model

Personality-first: cloud handles everything the user sees, local handles everything the user doesn't.

| Tier | Model | Role | Traffic Type |
|------|-------|------|-------------|
| **Tier 1 — Cloud** | Haiku 4.5 (provisional) | User-facing responses, persona, judgment | Telegram messages, inbox triage, status queries, daily briefing, directive execution |
| **Tier 2 — Local** | qwen3-coder:30b (conditional) | Mechanical execution, plumbing | Heartbeats, cron, vault-check, file ops, bridge relay, structured extraction, tool-chain orchestration |
| **Tier 3 — Cloud** | Sonnet 4.5 (reserved) | Quality-critical output | Research delegation, complex synthesis, vault content requiring accuracy over speed |

### 6.2 Routing Architecture ("Two Clocks")

Per GPT-5.2 R2 contribution: the system operates on two clocks.

- **Human clock:** Telegram interactions, persona continuity, anything where Danny reads the output. Routes to Tier 1 (cloud).
- **Machine clock:** Heartbeats, cron, monitoring, file operations, structured data. Routes to Tier 2 (local).

Routing is keyed on clock source, not complexity. A "simple" human message still needs persona (Tier 1). A "complex" machine task still stays local (Tier 2). This eliminates judgment calls in the routing decision — the signal is the origin channel, not a complexity assessment.

**Mixed-task routing** (per DeepSeek R2): A single user request can span both tiers — e.g., "Check the vault for my last meeting with X and tell me if we resolved Y." The vault lookup is mechanical (Tier 2); the summary needs persona (Tier 1). The routing PoC must validate sub-task delegation across tiers.

**Three-tier persona option** (per Perplexity R2): Instead of binary Haiku/Sonnet upgrade, consider: Haiku for routine persona (Tier 1a), Sonnet for second-register interactions (Tier 1b). This adds a routing dimension — mechanical / routine-persona / deep-persona — that plays naturally with the two-clocks model. Evaluate during persona testing (TMA-006).

### 6.3 Implementation: Two-Agent Split

Routing research (F15–F18) identifies the **two-agent split** as the recommended implementation, sidestepping the known model override bugs (F16). Each agent is a fully separate entity with its own model, workspace, sessions, and identity.

| Agent | Model | Handles | Channel Binding | Identity |
|-------|-------|---------|----------------|----------|
| `tess-voice` | `anthropic/claude-haiku-4-5` | All user-facing Telegram interactions, message triage, status queries, daily briefing, directive execution, vault queries with summarization | `channel: telegram` | Full SOUL.md + IDENTITY.md |
| `tess-mechanic` | `ollama/qwen3-coder:30b` | Heartbeats, cron jobs, vault-check automation, file operations, bridge relay, structured data extraction | No channel binding (background only) | Minimal operational identity — reliability and schema compliance, no persona |

**Why two agents instead of model overrides:**
1. Sidesteps all three routing bugs (F16) — per-agent model is the most reliable mechanism
2. Clean separation of concerns — each agent has its own workspace, sessions, and memory
3. Independent fallback chains — `tess-voice` falls back to Ollama (Limited Mode); `tess-mechanic` falls back to cloud if local model crashes
4. Aligned with OpenClaw's multi-agent architecture — swimming with the current
5. **Eliminates heartbeat cache pollution** (F21) — heartbeats run locally on `tess-mechanic`, so `tess-voice`'s prompt cache only needs to survive between user-initiated messages (which cluster in active-use periods), making the default 5-min TTL sufficient without paying the 1-hour premium

**Fallback if bugs are fixed (U12):** If v2026.2.17 or v2026.2.21 resolves the model override bugs, a simpler single-agent architecture with `heartbeat.model` and `subagents.model` overrides becomes viable. Test before committing to two-agent complexity.

**Delegation fallback (mixed-task routing):** If inter-agent delegation (U9) is unavailable, `tess-voice` calls Ollama directly as a tool endpoint for mechanical sub-tasks (file reads, structured extraction, vault queries). All safety contracts — especially MC-6 (confirmation echo) — apply to local model invocations regardless of call path. This fallback degrades the separation of concerns but preserves functionality for mixed-task requests like "check the vault for X and tell me Y."

**Open design questions** (see U9–U11):
- Inter-agent delegation: validate whether `tess-voice` can call `tess-mechanic` via `message_agent()` or similar. Preferred over the direct-Ollama fallback above.
- Heartbeat findings: `tess-mechanic` handles heartbeats silently, writes to vault/inbox when action is needed. `tess-voice` picks up findings on next interaction.
- `tess-mechanic` gets a minimal identity doc focused on reliability — no humor, no second register, no persona.

### 6.4 Component Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                     Mac Studio M3 Ultra                       │
│                                                              │
│  ┌─────────────┐     ┌──────────────────────────────────┐   │
│  │   Telegram   │◄───►│  OpenClaw Gateway (port 18789)   │   │
│  │   (remote)   │     │  Single gateway, two agents      │   │
│  └─────────────┘     └──────────┬───────────────────────┘   │
│                                 │                            │
│                    channel binding: telegram                  │
│                    ┌────────────┴────────────┐               │
│                    ▼                         ▼               │
│  ┌──────────────────────────┐  ┌───────────────────────────┐│
│  │  tess-voice              │  │  tess-mechanic            ││
│  │  Model: Haiku 4.5 (cloud)│  │  Model: qwen3-coder:30b  ││
│  │  Identity: SOUL.md full  │  │  Identity: minimal ops    ││
│  │                          │  │                           ││
│  │  - Telegram responses    │  │  - Heartbeats / cron      ││
│  │  - Inbox triage          │  │  - Vault-check automation ││
│  │  - Status queries        │  │  - File operations        ││
│  │  - Daily briefing        │  │  - Bridge relay mechanics ││
│  │  - Directive execution   │  │  - Structured extraction  ││
│  │                          │  │  - Tool-chain orchestration│
│  │  Fallback: Ollama        │  │                           ││
│  │  (Limited Mode)          │  │  Fallback: cloud          ││
│  └──────────────────────────┘  └───────────────────────────┘│
│                                                              │
│       │ API failure (3x 503/timeout)                         │
│       ▼                                                      │
│  ┌────────────────────────────┐                              │
│  │  Limited Mode               │                              │
│  │  tess-voice → Ollama        │                              │
│  │  Degradation banner sent    │                              │
│  │  Scope: captures/triage     │                              │
│  │  Auto-revert on API recovery│                              │
│  └────────────────────────────┘                              │
└──────────────────────────────────────────────────────────────┘
```

### 6.5 Limited Mode (Design Requirement)

Elevated from risk register entry to first-class design requirement per Revision 2. This is what makes the cloud dependency acceptable — Tess degrades rather than going silent.

**Trigger:** 3 consecutive retries on 503/timeout from Anthropic API.

**Behavior:**
- Switch all user-facing traffic to local model
- Send Telegram banner: "Tess is in limited local mode — responses may be flatter."
- Scope reduction: captures, triage, and status queries only. No advice voice, no multi-step decisions, no second register.
- Default is "some Tess" rather than silence.

**Recovery:** Automatic on API recovery. Periodic health check (every 5 minutes) pings the API. On success, revert to cloud routing and send Telegram notification: "Cloud restored — full mode active."

**What Limited Mode is NOT:** It is not a viable permanent operating mode. Surface compliance with SOUL.md instructions without frontier-model depth produces brittle judgment, inconsistent humor, and shallow precedent use — worse than obviously flat output because the drift is invisible until trust is undermined. Limited Mode is transient resilience, not an alternative architecture.

**Accepted trade-off — Anthropic as single critical vendor:** This architecture makes Anthropic the sole provider for Tess's core value: persona, judgment, second register, and complex synthesis. During an Anthropic outage, none of these are available — Limited Mode provides captures and triage only. This is a conscious dependency, not a solved problem. The mitigation (Limited Mode + local fallback) bounds the blast radius but does not eliminate the dependency.

## 7. Design Contracts

Per ChatGPT R1 reframing: define contracts instead of "picking a best model." Model selection becomes a satisfaction test against the contract. Future model swaps are conformance tests, not rewrites.

**Standalone reference:** `design/design-contracts.md` — self-contained evaluation framework for future model swaps without reading the full spec.

### 7.1 Mechanical Contract (Local Model)

Hard gates — model must satisfy all:

| Gate | Requirement | Validation |
|------|-------------|------------|
| MC-1 | Valid JSON tool output on ≥95% of calls across OpenClaw's 40+ tool inventory | Benchmark harness (TMA-007) |
| MC-2 | Schema adherence — correct parameter types, required fields populated, no hallucinated parameters | Benchmark harness (TMA-007) |
| MC-3 | Latency <5s for heartbeat/cron tasks (model loaded, warm) | Benchmark harness (TMA-007) |
| MC-4 | Stable under 64K context with KV cache quantization (q4_0 or q8_0) | Memory validation (TMA-005) |
| MC-5 | Model stays loaded without cold starts (`OLLAMA_KEEP_ALIVE=-1`) | Operational validation |
| MC-6 | **Confirmation echo compliance** (system safety invariant — see below) | Bridge echo test suite (TMA-007) |

**MC-6 safety specification:** The bridge confirmation echo is a system safety invariant with three layers:
1. **Negative requirement:** The local model must never initiate destructive actions or synthesize new confirmation tokens. It may only echo tokens provided by the operator via the bridge.
2. **Token authority:** The bridge (Crumb side) is the single source of truth for confirmation tokens — it generates, validates, and expires them. Tess never chooses the token value.
3. **System enforcement:** The bridge/tool executor MUST reject destructive actions unless a valid, unexpired confirmation token is present, independent of model output. Model instruction and benchmark testing provide defense in depth, not primary enforcement.

**MC-6 adversarial test cases** (TMA-007): replay (reuse of expired token), paraphrasing ("yeah go ahead" instead of exact echo), partial echo (token embedded in extra text), and unprompted confirmation (model emits token without operator providing one).

**KV cache quantization note:** Aggressive quantization (q4_0) trades natural language nuance for memory savings. Acceptable because local model output is structured JSON and tool calls, not user-facing prose. The Persona Contract covers language quality separately.

### 7.2 Persona Contract (Cloud Model)

Hard gates:

| Gate | Requirement | Validation |
|------|-------------|------------|
| PC-1 | Faithful execution of SOUL.md voice, including second register | Persona rubric (TMA-006) |
| PC-2 | Judgment on when to shift tone (operator → precedent mode) | Persona rubric (TMA-006) |
| PC-3 | Safe ambiguity handling — asks clarification rather than guessing | Persona rubric (TMA-006) |
| PC-4 | Consistent character across multi-day interaction history | Longitudinal test (post-deployment) |

Soft targets (desired but not blocking):

| Target | Requirement |
|--------|-------------|
| PT-1 | No generic bot filler (stock phrases, hedging patterns, emoji) |
| PT-2 | Dry humor lands in ≥1/3 of appropriate opportunities |
| PT-3 | Vault precedent surfaced at the right moment when available |
| PT-4 | Second register invoked appropriately in ≥2/3 of qualifying cases |

## 8. Model Selection

All selections are conditional and gated. No model is "confirmed" — each must pass its contract.

### 8.1 Local: qwen3-coder:30b (Conditional)

**Baseline quantization:** Q4_K_M (~19GB). **Preferred:** Q5_K (~22GB, ~2–3% accuracy uplift per Bartowski GGUF tests) — adopt if benchmarks confirm the uplift applies to structured tool output and headroom remains sufficient.

**Promotion gate to qwen3-coder-next (80B):** ALL of the following must be satisfied:
- Holds 64K context with target KV cache quantization
- ≥20GB unified memory headroom under defined load shape (current estimate: ~23GB q8_0 / ~26GB q4_0 — borderline)
- Sustained throughput ≥20 tok/s for tool-calling workloads
- No instability during concurrent Crumb + Obsidian + Docker
- No >5% performance drop vs 30B on benchmark harness
- Flash Attention validated in Ollama Metal backend for 64K+ context

**Defined load shape for memory validation:** 64K context + 10 sequential tool calls + concurrent Obsidian + Docker running + OpenClaw gateway active. Headroom measured under this load, not sterile conditions.

### 8.2 Cloud: Haiku 4.5 (Provisional)

Provisional selection for Tier 1 user-facing traffic. May need upgrade to Sonnet 4.5 if Haiku cannot carry SOUL.md second register.

**Evaluation path:**
1. Test both Haiku and Sonnet against persona evaluation rubric (§9)
2. If Sonnet significantly outperforms Haiku on second register, operator has approved Sonnet-tier costs (~$22.50/month)
3. Mixed tier viable: Haiku for routine persona, Sonnet for second-register interactions only

**Sonnet 4.5** reserved for Tier 3 (research delegation, complex synthesis) regardless of Tier 1 outcome.

**Architecture invalidation gate:** If neither Haiku nor Sonnet satisfies all Persona Contract hard gates (PC-1 through PC-3), this architecture is invalid and must be revisited — alternative provider, different tool split, or reduced persona ambition. The spec assumes at least one Anthropic model can carry SOUL.md; TMA-006 tests that assumption.

### 8.3 GLM-4.7-flash: Quarantined

Not rejected — quarantined pending resolution of known issues. Re-enter consideration only if ALL of:
- Ollama chat template compatibility confirmed on this stack
- Tool calling validated against OpenClaw's tool inventory
- Long-context behavior tested at 64K+

### 8.4 No Thinking Model

Hard blocker: `developer` role mismatch bug (F12) causes silent failures with `reasoning: true` on Ollama. Even if the bug is fixed, the architectural argument holds — thinking mode adds latency tax inappropriate for an always-on agent. The coder model variants are non-thinking only by design.

Thinking is Crumb's domain. Tess should be fast, reliable, and obedient to tool schemas.

## 9. Persona Evaluation Rubric

Predefined pass criteria for the Haiku vs Sonnet persona test (per DeepSeek + GPT R2). Test with 5–10 representative Telegram interactions that exercise the second register.

| Dimension | Pass Criterion | Weight |
|-----------|---------------|--------|
| Second register invocation | Appropriately invoked in ≥2/3 qualifying cases | Required |
| Ambiguity handling | Asks clarifying question when ambiguous rather than guessing | Required |
| Bot filler absence | No stock phrases, hedging patterns, or emoji | Required |
| Humor calibration | Dry humor lands in ≥1/3 appropriate opportunities | Desired |
| Vault precedent | Surfaced at the right moment when available | Desired |
| Tone shift | Operator → advisor transition calibrated to context | Required |

**Scoring:** A model passes if all "Required" dimensions are met. "Desired" dimensions inform tier selection (Haiku vs Sonnet vs mixed) but don't block deployment.

## 10. Memory Budget

Preliminary estimates — validate empirically (TMA-005).

| Component | 30B (Q4_K_M) | 30B (Q5_K) | 80B (Q4_K_M) |
|-----------|-------------|------------|--------------|
| Model weights | ~19GB | ~22GB | ~48GB |
| KV cache @ 64K (q8_0) | ~3GB | ~3GB | ~6GB* |
| KV cache @ 64K (q4_0) | ~1.5GB | ~1.5GB | ~3GB* |
| Ollama runtime | ~1GB | ~1GB | ~1GB |
| **Inference total (q8_0 / q4_0)** | **~23GB / ~21.5GB** | **~26GB / ~24.5GB** | **~55GB / ~52GB** |
| System baseline† | ~18GB | ~18GB | ~18GB |
| **Total (q8_0 / q4_0)** | **~41GB / ~39.5GB** | **~44GB / ~42.5GB** | **~73GB / ~70GB** |
| **Headroom on 96GB (q8_0 / q4_0)** | **~55GB / ~56.5GB** | **~52GB / ~53.5GB** | **~23GB / ~26GB** |

*\*Hybrid Mamba-Transformer: Mamba layers use fixed-size state instead of KV cache, so effective KV cost is lower than a pure Transformer of equivalent size. Actual reduction depends on Mamba-to-Transformer layer ratio — validate empirically.*

*†System baseline: macOS (~6GB) + Obsidian (~3GB) + Docker (~3GB) + OpenClaw gateway (~1GB) + Claude Code terminal (~1GB) + misc (~4GB) = ~18GB conservative estimate.*

## 11. Cost Model

Full analysis: `design/tess-haiku-cost-analysis.md`. Key conclusions:

| Scenario | Monthly Cost |
|----------|-------------|
| Haiku 4.5 with prompt caching | ~$8.70 |
| Haiku 4.5 without caching | ~$39.60 |
| Sonnet 4.5 with caching | ~$22.50 |
| Local electricity (50–80W sustained) | ~$6.50–10.40 |

**Key insight:** Prompt caching is not optional — it's a 4.5x cost reduction. The system prompt (~8,500 tokens × ~135 daily requests) dominates input costs. Without caching, the system prompt alone costs $1.15/day.

**Cost does not justify local-first.** The delta between Haiku ($8.70/mo) and local electricity ($6.50–10.40/mo) is negligible. Cost-motivated architecture decisions should focus on prompt caching and heartbeat frequency optimization, not on which tier runs locally.

**Caching dependency:** The entire cost model assumes prompt caching is configured and active (A6, A7). The two-agent split eliminates the heartbeat cache pollution problem (F21) — heartbeats run locally, so the cloud model's cache only needs to survive between user-initiated messages. System prompt optimization (compressing SOUL.md and tool definitions) provides a secondary cost and context-window benefit (F22). See `design/prompt-caching-research.md` for full analysis.

## 12. Configuration Strategy

- **Agent architecture:** Two-agent split — `tess-voice` (cloud) and `tess-mechanic` (local) — within a single OpenClaw gateway. Channel binding routes Telegram to `tess-voice`; `tess-mechanic` handles background tasks. See §6.3 for rationale.
- **Fallback chains:** `tess-voice` primary: Haiku 4.5, fallback: `ollama/qwen3-coder:30b` (Limited Mode). `tess-mechanic` primary: `ollama/qwen3-coder:30b`, fallback: cloud (if local crashes).
- **Ollama provider:** Add manually to existing `openclaw.json` (preserve hardened config from OC-009). Use `openai-completions` format, not `openai-responses`.
- **Context window:** Custom Modelfile with `PARAMETER num_ctx 65536`. Do not rely on OpenClaw's `contextWindow` propagating.
- **KV cache:** `OLLAMA_KV_CACHE_TYPE=q4_0` (aggressive — acceptable for structured output only). Test q8_0 as alternative.
- **Model persistence:** `OLLAMA_KEEP_ALIVE=-1` to lock model in memory, avoid cold-start latency.
- **Quantization:** Start with Q4_K_M. Move to Q5_K if benchmark confirms uplift for structured tool output without memory pressure.
- **Bug verification gate (U12):** Before committing to two-agent split, test `heartbeat.model` and `subagents.model` overrides on v2026.2.17. If fixed, evaluate single-agent simplification.

## 13. Risk Register

| ID | Risk | Severity | Status | Mitigation |
|----|------|----------|--------|------------|
| R1 | OpenClaw can't route by task type / agent | CRITICAL → HIGH | Partially de-risked | Two-agent split identified as recommended mechanism (F15–F18), sidestepping model override bugs (F16). Empirical validation still required (TMA-002). Remaining sub-risks: inter-agent delegation (U9), bug verification (U12). |
| R2 | Anthropic API down → Tess goes mute | MEDIUM | Protocol drafted | Limited Mode (§6.4): local fallback + degradation banner + scope reduction + auto-recovery. Severity reduced from HIGH by local fallback design. |
| R3 | Memory contention on shared 96GB | MEDIUM | Unvalidated | Memory budget (TMA-005) with actual measurements under defined load shape. Gate 80B promotion on empirical headroom. Use q4_0 KV cache + KEEP_ALIVE=-1. |
| R4 | `openai-completions` vs `openai-responses` hang | MEDIUM | Anecdotal | Hard test in integration plan (TMA-010). Single GitHub report — identify which component hangs, reproduce, document. |
| R5 | KV cache silent truncation | HIGH | Known bug | Custom Modelfile: `PARAMETER num_ctx 65536`. Validate propagation in integration test. |
| R6 | Haiku 4.5 can't carry SOUL.md second register | MEDIUM | Untested | Persona fidelity test (TMA-006) against predefined rubric (§9). Sonnet fallback / mixed tier option. |
| R7 | Thermal throttling under sustained concurrent load | MEDIUM | Unvalidated | Test with sustained inference + concurrent processes (TMA-007). Mitigate with fan profiles or session limits. |
| R8 | Local model JSON tool-call validity below threshold | MEDIUM | Unvalidated | Benchmark harness (TMA-007) must show ≥95% validity. Unverified 85% claim (Grok) — do not anchor on this. |
| R9 | API cost exceeds budget at scale | LOW | Projected acceptable | ~$8.70/mo Haiku, ~$22.50/mo Sonnet with caching. Monitor; optimize heartbeat frequency (96/day → 48/day halves heartbeat cost). |
| R10 | Confirmation echo bypass by local model | HIGH | By design | MC-6 (Mechanical Contract): local model must never auto-confirm destructive operations. Bridge confirmation echo is a system safety invariant. |
| R11 | Persona degradation during Limited Mode | MEDIUM | Accepted | Limited Mode is transient resilience, not a permanent architecture. Scope reduction minimizes exposure. Automatic recovery limits duration. |
| R12 | Model override bugs force two-agent complexity | MEDIUM | Active workaround | Three bugs (F16) prevent single-agent model overrides. Two-agent split is the workaround. If bugs are fixed in v2026.2.17/v2026.2.21, simplification is possible. Test before committing (U12). |
| R13 | Inter-agent delegation not available | MEDIUM | Unverified | `message_agent()` broker tool is a proposed future extension, not current capability (U9). If unavailable, mixed-task routing requires `tess-voice` to call Ollama directly or handle mechanical sub-tasks itself. |
| R14 | ~~OpenClaw doesn't pass `cache_control` to Anthropic API~~ | ~~MEDIUM~~ | **Resolved (TMA-010a)** | Native support confirmed. `cache_control` applied automatically for API key auth. Risk eliminated. |

## 14. Domain & Workflow

- **Domain:** software
- **Project class:** system
- **Workflow:** SPECIFY → PLAN → TASK → IMPLEMENT (full four-phase)
- **Rationale:** Technical implementation with model selection, routing architecture, config changes, integration testing, and persona evaluation. Multiple components (Ollama, OpenClaw, Anthropic API) with cross-cutting design decisions.
- **Related projects:** openclaw-colocation, crumb-tess-bridge

## 15. Task Decomposition

**Critical path (routing):** TMA-001 → TMA-002 → TMA-010a → TMA-008 → TMA-009 → TMA-010b
**Critical path (persona):** TMA-006 → TMA-011 → TMA-008 (persona eval determines Haiku vs Sonnet, which affects config draft, cost model, and caching math)
**Parallel tracks:** TMA-003, TMA-004, TMA-005 → TMA-007

| ID | Task | Type | Risk | Dependencies | Acceptance Criteria |
|----|------|------|------|--------------|---------------------|
| TMA-001 | Write routing specification for two-agent split — define `tess-voice` and `tess-mechanic` agent configs, channel bindings, fallback chains, and acceptance criteria. Include: bug verification protocol (U12), inter-agent delegation test (U9), single-gateway mixed-provider validation (U11). | `#writing` | High | None | One-page spec with pass/fail criteria. Covers: two-agent config, channel binding, pure-type routing, mixed-task delegation, fallback chains. |
| TMA-002 | Routing PoC — validate two-agent split on v2026.2.17. First: test if routing bugs (F16) are fixed (if yes, evaluate single-agent simplification). Then: validate two-agent config with channel bindings, mixed providers (Anthropic + Ollama), and fallback chains. If upgrade to v2026.2.21+ is unblocked before or during PoC, also test single-agent with `channels.modelByChannel` (F19) — whichever path is simpler and works wins. | `#code` | Critical | TMA-001 | Per-agent model routing verified. Channel binding routes Telegram to `tess-voice`. Mixed-provider gateway works. If upgraded: single-agent + modelByChannel tested alongside two-agent; simpler working path selected. Results documented with pass/fail against TMA-001 criteria. |
| TMA-003 | Codify design contracts as vault reference doc | `#writing` | Low | None | Mechanical + Persona contracts as standalone one-page doc. Linked from this spec. Becomes the evaluation framework for future model swaps. |
| TMA-004 | Document Limited Mode protocol | `#writing` | Medium | None | Formal degradation spec: triggers, fallback behavior, scope reduction, user notification format, auto-recovery logic. |
| TMA-005 | Build memory budget table — empirical measurements | `#research` | Medium | None | Actual numbers for 30B (Q4_K_M and Q5_K) under defined load shape. Measure: peak RSS, KV cache size at 64K, model load time, swap usage. Gate 80B evaluation on results. |
| TMA-006 | Persona fidelity test — Haiku vs Sonnet | `#research` | Medium | None | 5–10 representative interactions tested against rubric (§9). Determine: Haiku only, Sonnet only, or mixed tier. Results documented with scores per dimension. |
| TMA-007 | Local model benchmark harness | `#code` | High | TMA-005 | 10 tool-call tasks (including OpenClaw tools, bridge echo compliance) + 3 long-context tasks on qwen3-coder:30b (Q4_K_M and Q5_K). Record: JSON validity rate (≥95% required), median latency, peak memory, thermal behavior. |
| TMA-008 | Draft `openclaw.json` config changes | `#code` | Medium | TMA-002, TMA-010a | Config for tiered model architecture with local fallback. Uses `openai-completions` format (validated by TMA-010a). Includes custom Modelfile with `num_ctx 65536`. Caching config informed by TMA-010a cache_control results. |
| TMA-009 | Integration test — full tiered routing | `#code` | High | TMA-002, TMA-008 | End-to-end: human-clock message → cloud model → persona response. Machine-clock task → local model → structured output. Limited Mode trigger → fallback → recovery. Verify vault-based state sync (A8): mechanic's actions discoverable by voice purely via vault/inbox state, no shared in-gateway memory. |
| TMA-010a | API + caching probe — validate Anthropic integration before config finalization. Test `openai-completions` vs `openai-responses` (U2, R4). Verify OpenClaw passes `cache_control` to Anthropic API (U13, A7). Minimal throwaway config sufficient — does not require full TMA-008 output. | `#research` | High | TMA-002 | API format validated (which endpoint works, which hangs). Cache_control passthrough confirmed or blocker identified. If caching unavailable, update cost model and flag for operator decision before proceeding. |
| TMA-010b | Token cost measurement — measure actual vs projected costs with caching active on production config. | `#research` | Medium | TMA-009 | Actual token costs measured against §11 projections. Cache hit rate validated. Cost model confirmed or revised. |
| TMA-011 | System prompt optimization — compress SOUL.md for `tess-voice` | `#writing` | Medium | TMA-006 | Compress system prompt (target: 3,500–6,000 tokens from current ~9,500). Validate against persona rubric — no degradation on Required dimensions. Define `tess-mechanic` minimal identity doc (~200–300 tokens). Sequence after persona eval (which determines Haiku vs Sonnet) and before config draft. |

### Dependency Graph

```
TMA-001 ──── TMA-002 ──── TMA-010a ──┬── TMA-008 ──── TMA-009 ──── TMA-010b
                                       │       ▲
TMA-003 (parallel)                     │       │
TMA-004 (parallel)                     │       │
TMA-005 ──── TMA-007                   │       │
TMA-006 ──── TMA-011 ─────────────────┘───────┘  (persona → prompt → config)
```

**Note:** TMA-008 has three inbound dependencies: TMA-002 (routing validated), TMA-010a (API format + caching validated), AND TMA-006 → TMA-011 (persona eval → prompt optimization). All paths must complete before the config draft is finalized. TMA-010a was split from TMA-010 per peer review — API/caching validation must gate config, not follow it.

## 16. Peer Review Attribution

This specification synthesizes contributions from a 5-model peer review panel across 2 rounds.

### Universal Contributions (all 5 reviewers)
- Routing as blocking prerequisite
- Personality-first tiering endorsement
- Conditional (not absolute) model selection
- Empirical memory validation requirement
- GLM-4.7-flash quarantine (not abandonment)

### Named Contributions
- **GPT-5.2:** "Two clocks" routing abstraction (§6.2), "two contracts" design framework (§7), routing spec-grade acceptance criteria
- **ChatGPT (R1):** Design contracts abstraction — Mechanical + Persona contracts as evaluation framework (§7)
- **DeepSeek V3.2-Thinking:** Bridge confirmation echo as system safety invariant (MC-6), mixed-task routing as PoC test case
- **Perplexity Pro:** Persona failure mode articulation, KV quantization rationale in Mechanical Contract, mixed Haiku/Sonnet tier (§6.2), transcript vs authored analysis boundary
- **Grok 3.5:** Thermal throttling risk (R7), effective vs native context caveat, Q5_K intermediate quant option, intentionality language discipline in model attribution
- **Gemini 3 Pro Preview:** IF scores as primary local model selection metric, aggressive KV cache quantization rationale

### Opus Pushbacks (documented for transparency)
- Gemini's 80B recommendation: active parameter counts are similar; marginal quality doesn't justify memory risk on shared hardware
- Grok's 85% JSON validity claim: unverified, do not anchor — validate empirically
- DeepSeek's "Owner: Danny / Tess": Tess can't own work items pre-deployment
- Gemini's "emergency persona": over-engineering the fallback before primary architecture works

## 17. Author Notes for Peer Review

### AN1. TMA-010/011 Consolidation

The original decomposition had TMA-011 (API format validation) as a standalone parallel task and TMA-010 (API format + caching + cache_control) as a later integration task. TMA-011 was a strict subset of TMA-010. Consolidated into a single TMA-010 that covers all API validation in one pass. Former TMA-012 (system prompt optimization) renumbered to TMA-011. Reviewers: confirm the merged scope is coherent and the dependency on TMA-008 is appropriate.

### AN2. R14 Severity — Cost Model vs Budget Reality

R14 (cache_control passthrough) was initially rated HIGH on the grounds that it's a 4.5x cost multiplier invalidating the cost model. Downgraded to MEDIUM because the actual blast radius is ~$40/month uncached Haiku, which falls within the operator's stated comfort range (Sonnet tier at ~$22.50/month was explicitly accepted). The cost model is technically invalidated, but the budget is not broken. Reviewers: weigh in on whether the principle of "cost model assumes caching" warrants HIGH even if the dollar impact is tolerable, or whether MEDIUM with cost-impact annotation is the right call.

### AN3. Persona Eval on the Critical Path

TMA-006 (persona eval) determines whether Haiku or Sonnet is the Tier 1 model. This affects: the cost model (§11), the caching math (different pricing tiers), and the system prompt optimization target (§TMA-011). The dependency graph correctly shows TMA-006 → TMA-011 → TMA-008 as a second critical path converging on the config draft. The routing critical path (TMA-001 → TMA-002 → TMA-008) and the persona critical path can run in parallel, but TMA-008 cannot finalize until both complete. Reviewers: confirm this dual-critical-path structure is correctly captured.

## 18. Evidence Base

| Document | Location | Role |
|----------|----------|------|
| Local LLM Research Thread | `design/tess-local-llm-research-thread.md` | Primary evidence — transcript, model comparison, 2 rounds peer review |
| Design Revision 1 (withdrawn) | `design/tess-model-architecture-design-revision.md` | Decision record — local-first proposal, withdrawn |
| Cost Analysis | `design/tess-haiku-cost-analysis.md` | Quantitative evidence — Haiku/Sonnet pricing, electricity costs |
| Design Revision 2 (current) | `design/tess-model-architecture-design-revision-2.md` | Decision record — cloud-primary restoration with rationale |
| OpenClaw Routing Research | `design/openclaw-routing-research.md` | Routing capabilities, bugs, two-agent split recommendation |
| Prompt Caching Research | `design/prompt-caching-research.md` | Cache mechanics, heartbeat TTL problem, system prompt optimization |
| SOUL.md | External (Tess repo) | Persona definition — defines second register, voice calibration |
| IDENTITY.md | External (Tess repo) | Persona definition — role boundaries, operational parameters |
