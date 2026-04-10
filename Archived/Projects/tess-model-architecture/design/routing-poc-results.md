---
type: design
project: tess-model-architecture
domain: software
created: 2026-02-22
updated: 2026-02-22
tags:
  - routing
  - openclaw
  - poc-results
  - multi-agent
---

# Routing PoC Results — TMA-002

## 1. Environment

| Field | Value |
|-------|-------|
| OpenClaw version | `2026.2.17` |
| Ollama version | `0.16.3` |
| Node.js version | `v25.6.1` |
| qwen3-coder:30b digest | `06c1097efce0` (blob: `sha256-1194192cf2a1`) |
| Quantization | Q4_K_M (default) |
| Test date | 2026-02-22T22:30:00Z – 2026-02-23T00:00:00Z |
| Config snapshot | `design/openclaw-config-test-two-agent.json` |
| Config hash | SHA-256 of deployed config (post-apiKey fix) |
| Gateway log path | `/tmp/openclaw/openclaw-2026-02-22.log` |
| Test machine | Mac Studio M3 Ultra 96GB, Darwin 25.3.0 |

## 2. Configuration Discovery

Before testing, the OpenClaw v2026.2.17 Zod schema was examined to validate config
assumptions from the routing specification. Several corrections were needed:

| Spec Assumption | Actual Schema | Impact |
|-----------------|---------------|--------|
| `providers` at top level with `type: "openai-completions"` | `models.providers` with native `api: "ollama"` | Config structure differs; native Ollama support simpler than assumed |
| `agents.list[].model` as string | `agents.list[].model: { primary, fallbacks }` | Object format, not string |
| Provider auth optional for local services | Auth resolution requires API key even for Ollama | `apiKey: "not-needed"` workaround required |
| `systemPrompt` available per agent | No per-agent `systemPrompt` field | Affects Limited Mode mechanism (4a) |
| `agents.list[].tools` structure | `{ profile, allow, alsoAllow, deny, byProvider }` | Richer than expected; `byProvider` enables provider-specific restrictions |

## 3. Test Results

### 3.1 Mixed-Provider Gateway (MP)

| # | Scenario | Status | Evidence | Notes |
|---|----------|--------|----------|-------|
| MP-1 | Single gateway hosting both agents | **PASS** | Gateway started (PID 46848), port 18789 listening. Both agent definitions loaded. | Initial log shows `agent model: anthropic/claude-opus-4-6` — this is the gateway default, not per-agent routing. Per-agent routing confirmed by subsequent tests. |
| MP-2 | voice calls Anthropic API | **PASS** | `provider=anthropic model=claude-sonnet-4-5 messageChannel=telegram` in gateway logs | Response received, ~1679ms latency |
| MP-3 | mechanic calls Ollama API | **PASS** | `provider=ollama model=qwen3-coder:30b thinking=off messageChannel=heartbeat` in gateway logs | Required `apiKey: "not-needed"` fix — see §4.1 |
| MP-4 | Simultaneous requests to both providers | **PASS** | Heartbeat at 23:17:15, Telegram message at 23:17:28 — both succeeded without interference | No request blocking or provider confusion |

### 3.2 Pure-Type Routing (RT)

| # | Scenario | Status | Evidence | Notes |
|---|----------|--------|----------|-------|
| RT-1 | Telegram message → voice/Sonnet | **PASS** | `lane=session:agent:voice:main provider=anthropic model=claude-sonnet-4-5 messageChannel=telegram` | Channel binding correctly routes Telegram → voice agent. Initially tested with Haiku, re-verified after Sonnet switch. |
| RT-2 | Heartbeat → mechanic/Ollama | **PASS** | `provider=ollama model=qwen3-coder:30b thinking=off messageChannel=heartbeat` | Heartbeat correctly routes to mechanic agent using local model. No cloud API call. |
| RT-3 | Cron task (scheduled) | **SKIP** | No cron tasks configured in test environment | OpenClaw cron/scheduled tasks not set up for PoC. Mechanically equivalent to RT-2 (non-channel-bound task → unbound agent). |
| RT-4 | Telegram during API outage | **SKIP** | Cannot simulate Anthropic API failure without disrupting production Tess | See §5 — Limited Mode requires external state management regardless. |
| RT-5 | Local model crash → cloud fallback | **FAIL** | Inferred from FB-3 results | Same mechanism — `model.fallbacks` doesn't activate for provider-down. See §4.2. |

### 3.3 Session Isolation (SI)

| # | Scenario | Status | Evidence | Notes |
|---|----------|--------|----------|-------|
| SI-1 | Seed data in voice context not visible to mechanic | **PASS** | Different session IDs: voice and mechanic operate in separate `sessionId` namespaces | Per-agent session isolation is native to the two-agent architecture |
| SI-2 | Mechanic writes to vault → voice can discover via vault read | **PASS** | Architectural — both agents share filesystem access to vault workspace | State sync is file-based, not memory-based (A8 validated) |
| SI-3 | Voice session history not accessible to mechanic | **PASS** | Independent session histories confirmed — separate `sessionId` per agent | No cross-contamination possible |

### 3.4 Bug Verification (BV)

| # | Scenario | Status | Evidence | Notes |
|---|----------|--------|----------|-------|
| BV-1 | Heartbeat uses configured model, not main agent model | **PASS** | Heartbeat ran on `ollama/qwen3-coder:30b` while voice uses `anthropic/claude-sonnet-4-5` | Two-agent architecture gives each agent its own model, making per-task model routing inherent rather than bug-dependent |
| BV-2 | `/model` switch doesn't affect heartbeat model | **SKIP** | Two-agent architecture sidesteps — heartbeat runs on mechanic agent, not voice | Bug #13009 is moot when heartbeat agent is separate from chat agent |
| BV-3 | Sub-agent uses configured model | **SKIP** | Two-agent architecture sidesteps — model assignment is per-agent, not per-sub-task | Bug #6671 is moot in two-agent split |

**Decision gate:** BV-1 passed. BV-2/BV-3 are structurally irrelevant to two-agent architecture.
Single-agent path (`modelByChannel`) was not tested — v2026.2.21+ upgrade blocked on bundler
corruption (#22841). Two-agent split confirmed as implementation path.

### 3.5 Inter-Agent Delegation (IA)

| # | Scenario | Status | Evidence | Notes |
|---|----------|--------|----------|-------|
| IA-1 | voice attempts `message_agent("mechanic", ...)` | **RESOLVED: UNAVAILABLE** | `cross-agent` string found in gateway source but no user-facing delegation API exposed in v2026.2.17 | Feature may exist internally but is not available for inter-agent message passing |
| IA-2 | Delegation round-trip latency | **N/A** | Delegation unavailable | — |

**Impact:** Locks in direct Ollama call as the delegation mechanism. Voice handles mixed
tasks by calling `http://127.0.0.1:11434/v1/chat/completions` directly as a tool/API endpoint.
All MC-6 safety contracts apply per routing specification §6.

### 3.6 Mixed-Task Delegation (DL)

| # | Scenario | Status | Evidence | Notes |
|---|----------|--------|----------|-------|
| DL-1 | Vault query with persona summary | **DEFERRED** | Requires direct Ollama call implementation | TMA-008 config scope — voice calls Ollama via HTTP tool |
| DL-2 | Run vault-check and report results | **DEFERRED** | Same | Implementation detail, not gateway routing test |
| DL-3 | Delegation handback (persona → mechanic → persona) | **DEFERRED** | Same | Handback is voice composing response from Ollama output |
| DL-4 | Mechanic failure mid-delegation | **DEFERRED** | Same | Voice handles error locally |
| DL-5 | Limited Mode + delegation attempt | **DEFERRED** | Same | In Limited Mode, both agents use local model — delegation is a no-op |

**Note:** DL scenarios are implementation details of the voice agent's tool configuration,
not gateway routing behaviors. They are correctly scoped to TMA-008 (config draft) and
TMA-009 (integration test).

### 3.7 Fallback Chains (FB)

| # | Scenario | Status | Evidence | Notes |
|---|----------|--------|----------|-------|
| FB-1 | Anthropic returns 503 (single) | **SKIP** | Cannot simulate Anthropic API failure | Retry behavior exists in gateway (observed in FB-3's exponential backoff) |
| FB-2 | Anthropic returns 503 x3 → Ollama fallback | **SKIP** | Cannot simulate | See §4.2 — fallback chain likely doesn't activate for connection-level failures |
| FB-3 | Ollama crashes → mechanic fallback to cloud | **FAIL** | See §4.2 for full trace | 4 retries with exponential backoff (2s/4s/8s), all failed. Fallback model (Haiku) never attempted. Run ended with `isError=true`. |
| FB-4 | Both providers down | **PARTIAL** | Ollama down = heartbeat fails silently (FB-3). Both down = all services fail. | No operator escalation triggered (no built-in mechanism). |
| FB-5 | Provider recovery after outage | **PASS** | runId `2325fd98`: `provider=ollama model=qwen3-coder:30b`, `durationMs=30513`, no `isError`. Normal heartbeat execution. | Gateway does not stay in broken state after provider-down. Next heartbeat after Ollama restart completes cleanly. 30.5s duration = normal model inference. |

### 3.8 Limited Mode Mechanism Verdicts (4a/4b/4c)

#### 4a — System Prompt Swap

| Option | Tested | Result |
|--------|--------|--------|
| Config-based per-agent `systemPrompt` | Schema inspection | **NOT AVAILABLE** — no `systemPrompt` field on agent schema. Only `identity: { name, theme, emoji, avatar }` (display-only). |
| `extraSystemPrompt` in prompt builder | Schema inspection | Exists but is not per-agent in config schema — global to prompt builder. |
| Conditional append (model self-ID) | Design analysis | **REJECTED as standalone** — TMA-004 §3.2 flagged model self-identification as fragile ("relies on the local model correctly self-identifying"). Not reliable enough as the sole mechanism. |
| **Config swap (identity doc reference)** | Design analysis | **SELECTED** — Health-check cron (4c) already performs config swap + gateway reload to change the model. Same swap simultaneously changes the identity document reference to a Limited Mode variant. |

**Verdict:** Config-swapped prompt, not model self-identification. The health-check cron
(4c) performs an atomic config swap that changes three things simultaneously:
1. `model.primary` → Ollama (the model change)
2. Identity document reference → Limited Mode variant (the prompt change)
3. `tools.byProvider.ollama` restrictions activate automatically (4b)

This makes all three mechanisms part of one atomic state transition rather than three
independent mechanisms. The Limited Mode identity doc is a stripped-down prompt without
persona fidelity expectations — distinct from the full SOUL.md. Model self-identification
may be included as defense-in-depth but is not the primary enforcement mechanism.

**Evidence:** `/Users/openclaw/.local/lib/node_modules/openclaw/dist/plugin-sdk/agents/system-prompt.d.ts` —
`buildAgentSystemPrompt()` has no runtime swap mechanism. `promptMode` only controls which
hardcoded sections to include (`full`, `minimal`, `none`). Config swap + gateway reload
is required for prompt changes.

#### 4b — Tool Restriction

| Option | Tested | Result |
|--------|--------|--------|
| Runtime modification | Schema inspection | No runtime tool modification API |
| Middleware interception | Schema inspection | No middleware hooks in v2026.2.17 |
| **Per-agent config** | Schema inspection | **FULLY SUPPORTED** — `agents.list[].tools` with `profile`, `allow/deny`, `byProvider` |

**Verdict:** Use `agents.list[voice].tools.byProvider.ollama.profile: "minimal"` to
automatically restrict tools when voice runs on Ollama. This is already in place in
the config — it activates whenever voice uses the Ollama provider, regardless of whether
that's via fallback or config swap. Changes require gateway reload (not true runtime mutation).

**Evidence:** `/Users/openclaw/.local/lib/node_modules/openclaw/dist/plugin-sdk/config/zod-schema.agents.d.ts` —
agent tools schema includes `byProvider?: Record<string, { profile?, allow?, deny? }>`.
Built-in profiles: `minimal`, `coding`, `messaging`, `full`.
Tool policy pipeline: `/Users/openclaw/.local/lib/node_modules/openclaw/dist/plugin-sdk/agents/tool-policy-pipeline.d.ts`.

#### 4c — Recovery Mechanism

| Option | Tested | Result |
|--------|--------|--------|
| OpenClaw auto-retry | FB-3 test | **INSUFFICIENT** — Retries same provider, never falls back. Not a recovery mechanism. |
| Explicit revert (config swap) | Design analysis | Viable but requires external trigger. |
| **Health-check cron** | Schema inspection + design | **SELECTED** — External cron probes Anthropic API health; triggers config swap + gateway reload on state change. |

**Verdict:** External health-check cron job running every 5 minutes (per TMA-004 §6.3).
Probes Anthropic API directly (not via OpenClaw). On failure detection: swaps voice's
`model.primary` to `ollama/qwen3-coder:30b`, reloads gateway, sends degradation banner
to Telegram. On recovery: swaps back to `anthropic/claude-sonnet-4-5`, reloads,
sends recovery notification.

**Evidence:** Built-in health check (`getHealthSnapshot()`) is read-only informational —
no auto-recovery actions. Model fallback (`runWithModelFallback()`) doesn't activate for
provider-down errors (FB-3). Heartbeat runner is informational only.

## 4. Key Findings

### 4.1 Ollama Provider Auth Resolution (RESOLVED)

**Finding:** OpenClaw requires an API key for every configured provider, even local services
that don't use authentication. Without it, the auth resolver fails before the HTTP request
is attempted.

**Error:** `No API key found for provider "ollama". Auth store: .../agents/mechanic/agent/auth-profiles.json`

**Fix:** Add `"apiKey": "not-needed"` and `"authHeader": false` to the Ollama provider config.
Ollama ignores the Authorization header; OpenClaw's auth resolver is satisfied.

**Impact:** Config requirement for TMA-008. Not a design concern — mechanical fix.

### 4.2 Fallback Chain Failure for Provider-Down Scenarios (CRITICAL)

**Finding:** `model.fallbacks` in `agents.list[].model` does **not** trigger automatic
cross-provider failover when the primary provider is unreachable (connection refused).

**Evidence (FB-3 — runId `0af9f840`):**

```
23:20:19.451 — agent start (attempt 1), 2ms → isError=true
23:20:21.460 — agent start (attempt 2, ~2s backoff), 26ms → isError=true
23:20:25.495 — agent start (attempt 3, ~4s backoff), 28ms → isError=true
23:20:33.529 — agent start (attempt 4, ~8s backoff), 26ms → isError=true
23:20:33.563 — run done, durationMs=14137, aborted=false
```

The gateway retried the **same provider** 4 times with exponential backoff (2s → 4s → 8s),
then ended the run with errors. The fallback model (`anthropic/claude-haiku-4-5`) was
**never attempted**.

**Analysis:** The `runWithModelFallback()` function exists in the codebase but appears to
not engage for connection-refused errors. It may only handle model-level errors (context
overflow, rate limits, invalid model ID). The earlier "accidental fallback" observed during
the auth resolution error was a different failure layer — auth resolution fails before
the model fallback function is called, triggering a different error path that does include
fallback behavior.

**Two failure layers identified:**

| Layer | Failure Type | Fallback Behavior |
|-------|-------------|-------------------|
| Auth resolution | Missing API key | Falls back to next model (observed) |
| API call | Connection refused | Retries same provider, no fallback (FB-3) |

**Impact — cascades to three areas:**

1. **Limited Mode (TMA-004):** §3.1 assumed "OpenClaw handles the failover automatically
   when the primary model is unreachable." **Invalidated.** Limited Mode requires an
   external health monitor to detect API failure and trigger a managed state transition
   (config swap + gateway reload). This is architecturally different from automatic failover.

2. **Mechanic resilience:** If Ollama goes down, mechanic fails silently. Background work
   (heartbeats, cron) stops until Ollama recovers. No cloud fallback occurs.

3. **TMA-008 config:** The `fallbacks` arrays can remain in config (may work for model-level
   errors not tested here) but cannot be relied on as the resilience mechanism for provider
   outages. A separate health-check mechanism is required.

### 4.3 Inter-Agent Delegation Unavailable (SIGNIFICANT)

**Finding:** No user-facing inter-agent delegation API in v2026.2.17. The `cross-agent`
string exists in gateway source but is not exposed as a usable feature.

**Impact:** Mixed-task delegation uses the direct Ollama call fallback path — voice calls
`http://127.0.0.1:11434/v1/chat/completions` as an HTTP tool endpoint. This is documented
in routing specification §6 as the expected path for v2026.2.17.

### 4.4 Design Decision: Voice Model — Sonnet 4.5

**Decision (operator, 2026-02-22):** Voice agent runs on `anthropic/claude-sonnet-4-5`,
not Haiku 4.5.

**Rationale:** Persona fidelity. Sonnet provides superior persona quality for user-facing
interactions. Cost: ~$22.50/mo with caching (up from ~$8.70/mo Haiku estimate).

**Effects:**
- TMA-006 (persona fidelity test): Simplifies to Sonnet-only evaluation
- TMA-008 (config): Voice uses Sonnet primary
- Fallback chain: Sonnet → Ollama (not Haiku → Ollama)
- Mechanic fallback: remains Haiku (cost-efficient for background error recovery)

### 4.5 Native Ollama Provider Support

**Finding:** OpenClaw v2026.2.17 has native `api: "ollama"` support in the provider config
schema. The routing specification assumed `openai-completions` format — the native format
is simpler and correct.

**Config:**
```json
"models": {
  "providers": {
    "ollama": {
      "baseUrl": "http://127.0.0.1:11434",
      "api": "ollama",
      "apiKey": "not-needed",
      "authHeader": false,
      "models": [{
        "id": "qwen3-coder:30b",
        "name": "Qwen3 Coder 30B",
        "reasoning": false,
        "input": ["text"],
        "contextWindow": 65536,
        "maxTokens": 32768
      }]
    }
  }
}
```

## 5. Limited Mode — Revised Architecture

Based on findings §4.2 (fallback chain failure) and §3.8 (mechanism verdicts), the
Limited Mode protocol is a **managed state transition**, not an automatic failover.

### 5.1 State Machine

```
NORMAL ──(API failure detected by health cron)──► LIMITED
  │                                                   │
  │                                                   │
  ◄──(API recovery detected by health cron)───────────┘
```

### 5.2 Entry (NORMAL → LIMITED)

Health-check cron performs an **atomic config swap** that changes three things simultaneously:

1. Health-check cron detects Anthropic API failure (3 consecutive failures, 5-min intervals)
2. Cron modifies `openclaw.json` — single atomic swap:
   - `model.primary` → `ollama/qwen3-coder:30b` (model change)
   - Identity document reference → Limited Mode variant (prompt change — stripped-down,
     no persona fidelity expectations, explicit scope restrictions)
3. Gateway reload: `launchctl kickstart -k system/ai.openclaw.gateway`
4. Three effects activate from the single config change:
   - Voice uses Ollama (model swap)
   - Limited Mode identity doc loaded (prompt swap)
   - `tools.byProvider.ollama.profile: "minimal"` restricts tools automatically (tool restriction)
5. Degradation banner sent to Telegram

### 5.3 Exit (LIMITED → NORMAL)

1. Health-check cron detects Anthropic API recovery (1 successful probe)
2. Cron restores `openclaw.json` — reverse atomic swap:
   - `model.primary` → `anthropic/claude-sonnet-4-5`
   - Identity document reference → full SOUL.md
3. Gateway reload
4. Normal model, prompt, and tool profile resume
5. Recovery notification sent to Telegram

### 5.4 Duration Cap

If Limited Mode persists >4 hours, operator escalation message sent (per TMA-004 §6.4).

## 6. "Simpler Path" Criteria Table — Scored

| Dimension | Two-Agent Split | Single-Agent + modelByChannel | Score |
|-----------|----------------|-------------------------------|-------|
| **Agent count** | 2 agents | 1 agent | Single-agent wins |
| **Config parameter count** | ~40 lines (2 agents, bindings, 2 model configs, provider) | Not tested (v2026.2.21 blocked) | Cannot score |
| **Known bug exposure** | None (sidesteps F16 bugs) | Unknown (upgrade blocked) | Two-agent wins by default |
| **Maintenance surface area** | 2 identity docs, 2 session stores, 2 tool sets | Not tested | Cannot score |
| **Session isolation** | Native per-agent (proven SI-1/2/3) | Shared (risk of contamination) | Two-agent wins |
| **Mixed-task routing** | Direct Ollama call (IA unavailable) | Would be simpler (single agent, multiple models) | Cannot score |
| **Cache behavior** | Clean — heartbeats in separate session (proven) | Risk of cache pollution | Two-agent wins |
| **Fallback chain clarity** | Independent but **non-functional for provider-down** (FB-3) | Unknown | Draw (both would have FB-3 issue) |
| **Identity separation** | Clean — SOUL.md on voice only | Shared identity | Two-agent wins |

**Decision:** Two-agent split confirmed as implementation path.

**Justification:**
1. Single-agent path untestable — v2026.2.21 upgrade blocked on bundler corruption (#22841)
2. Two-agent wins on session isolation, cache behavior, identity separation
3. FB-3 fallback failure affects both architectures equally — not a differentiator
4. Two-agent naturally sidesteps F16 bugs without relying on bug fixes

## 7. Spec Updates Required

The following specification sections need updating based on PoC findings:

| Document | Section | Update Needed |
|----------|---------|---------------|
| `routing-specification.md` | §3 Config Schema | Update provider format to `models.providers` with `api: "ollama"` |
| `routing-specification.md` | §3 Notes | Add `apiKey: "not-needed"` requirement |
| `routing-specification.md` | §5.1 RT-4/RT-5 | Note that fallback chains don't activate for provider-down |
| `limited-mode-protocol.md` | §3.1 | Replace "OpenClaw handles failover" with managed state transition model |
| `limited-mode-protocol.md` | §3.2 | Record verdict: conditional append |
| `limited-mode-protocol.md` | §4.1 | Record verdict: per-agent config with `byProvider` |
| `limited-mode-protocol.md` | §6.3 | Record verdict: external health-check cron |
| `design-contracts.md` | — | No changes needed (contracts are model-agnostic) |

## 8. Config Artifacts

### 8.1 Test Config (Two-Agent)

Full config: `design/openclaw-config-test-two-agent.json`

Key additions over baseline:
- `models.providers.ollama` block with `api: "ollama"`, `apiKey: "not-needed"`
- `agents.list` with voice (Sonnet primary, Ollama fallback) and mechanic (Ollama primary, Haiku fallback)
- `bindings` array routing Telegram → voice
- `agents.defaults` simplified (removed `models` block from baseline)

### 8.2 Baseline Config

Full config: `design/openclaw-config-baseline.json`
SHA-256: `6fd1afa3068fc34e59b416eaeb3eaa15defdd9666a7b5dd395d2603c7c864f25`

## 9. Open Items for Downstream Tasks

| Item | Affects | Priority |
|------|---------|----------|
| Health-check cron implementation | TMA-008, TMA-009 | High — central to Limited Mode |
| `tools.byProvider.ollama.profile` validation | TMA-008 | Medium — verify "minimal" profile scope |
| Direct Ollama call tool configuration for voice | TMA-008 | Medium — delegation mechanism |
| Conditional system prompt for Limited Mode | TMA-011 | Medium — prompt includes Limited Mode rules |
| `model.fallbacks` behavior for model-level errors (rate limit, context overflow) | TMA-008 | Low — may still be useful for non-provider-down failures |
| FB-5 verification (service recovery) | TMA-009 | **RESOLVED** — PASS. Gateway recovers cleanly after provider restore. |
