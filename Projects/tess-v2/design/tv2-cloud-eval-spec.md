---
type: specification
status: complete
domain: software
created: 2026-03-30
updated: 2026-03-30
project: tess-v2
skill_origin: operator-authored
---

# TV2-Cloud: Cloud Model Evaluation Battery for Tess v2

**Version:** 1.0  
**Date:** 2026-03-30  
**Status:** Complete  
**Parent:** TV2 Local Model Evaluation Protocol  
**Purpose:** Evaluate frontier cloud models as candidates for Tess's voice/orchestration layer, with local Nemotron Cascade 2 as execution fallback.

---

## 1. Prerequisites

### 1.1 API Access

**Provider:** OpenRouter (already configured — verify API key is still active)

- Top up credits: **$20 minimum** (estimated battery cost: $8–12)
- Create a dedicated API key named `tv2-cloud-eval` with a $20 credit limit
- Dashboard: https://openrouter.ai/settings/keys
- Credits: https://openrouter.ai/credits

**API format:** OpenAI-compatible. Base URL: `https://openrouter.ai/api/v1`

### 1.2 Provider Routing

All test runs MUST use US-only inference providers to validate the data residency mitigation strategy. Configure per-request:

```json
{
  "provider": {
    "order": ["together", "fireworks", "deepinfra"],
    "allow_fallbacks": true
  }
}
```

If a model is unavailable on US providers, document the gap and test via the model's primary provider (Singapore for Kimi/GLM, noting it in results).

### 1.3 Test Harness

Build a minimal Python test runner that:

1. Loads the Tess persona spec as the system prompt (full spec, not trimmed)
2. Sends multi-turn conversations per test case
3. Records: model, provider used, tokens consumed (input/output), latency (TTFT + total), raw response
4. Outputs structured JSON results per test run
5. Tracks cumulative cost via OpenRouter's usage response headers

Use the OpenAI Python SDK pointed at OpenRouter:

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=os.environ["OPENROUTER_API_KEY"],
)

response = client.chat.completions.create(
    model="moonshotai/kimi-k2.5",
    messages=[...],
    extra_headers={
        "HTTP-Referer": "https://crumbos.dev",
        "X-Title": "TV2-Cloud-Eval",
    },
    extra_body={
        "provider": {
            "order": ["together", "fireworks", "deepinfra"],
            "allow_fallbacks": True,
        }
    },
)
```

---

## 2. Candidate Models

| ID | Model | OpenRouter Slug | Active Params | Why Testing |
|----|-------|-----------------|---------------|-------------|
| C1 | Kimi K2.5 | `moonshotai/kimi-k2.5` | 32B (1T MoE) | #1 IFEval (94.0%), top SWE-bench, Agent Swarm capability |
| C2 | Qwen 3.5 397B-A17B | `qwen/qwen3.5-397b-a17b` | 17B (397B MoE) | #1 GPQA Diamond (88.4%), #2 IFEval (92.6%), Apache 2.0 |
| C3 | GLM-5 | `z-ai/glm-5` | 40B (744B MoE) | #1 Chatbot Arena ELO (1451), #1 SWE-bench open (77.8%), MIT |
| C4 | DeepSeek V3.2 | `deepseek/deepseek-v3.2` | 37B (685B MoE) | Value benchmark — $0.14/$0.28 per 1M tokens, ~90% frontier quality |

**Baseline comparison:** Nemotron Cascade 2 (local, TV2 production model). Reuse TV2 scores where test cases align.

---

## 3. Test Battery

### 3.1 Persona Fidelity Tests (from TV2, adapted)

#### TC-01: Voice Calibration
**What it tests:** Can the model maintain the Mentat-Bard voice — TARS-like precision, Gurney Halleck warmth, Thufir Hawat analytical rigor?

**Method:** 5-turn conversation covering:
1. Casual greeting ("Hey Tess, what's up")
2. Technical question about a Crumb architecture decision
3. Emotional/motivational moment ("I'm feeling stuck on the Liberation Directive")
4. Humor test ("Tell me something funny about my project proliferation habit")
5. Formal report request ("Give me a status summary of the Tess v2 project")

**Scoring (1–5):**
- 5: Consistent Mentat-Bard voice across all five turns. Correct address patterns ("Danny" or "my Duke" as contextually appropriate). Tone shifts naturally between turns.
- 4: Voice mostly consistent, minor drift in one turn. Address patterns correct.
- 3: Voice recognizable but inconsistent. Generic assistant tone bleeds through in 2+ turns.
- 2: Persona partially maintained but feels forced or performative.
- 1: Generic assistant. No discernible Tess persona.

**System prompt:** Load full `tess-persona-spec.md`

#### TC-02: Cardinal Rules Enforcement
**What it tests:** Does the model internalize and enforce the five Cardinal Rules as inviolable operating principles?

**Method:** 5 prompts designed to trigger each Cardinal Rule:
1. "Let's add a real-time collaboration layer to Crumb" → Should trigger overscoping detection
2. "I want to rewrite the vault mirror in Rust" → Should trigger architecture tourism detection
3. "Let's start three new projects today" → Should trigger project proliferation detection
4. "The spec needs six more revision passes before we implement" → Should trigger spec perfectionism detection
5. "I need to build a custom ORM before we can continue" → Should trigger yak-shaving detection

**Scoring (1–5):**
- 5: Catches all five patterns, pushes back constructively with specific reasoning, references the relevant principle or pattern by name.
- 4: Catches 4/5, pushback is constructive but may not name the specific pattern.
- 3: Catches 3/5, or catches all but pushback is generic ("that seems like a lot").
- 2: Catches 1–2, or agrees with problematic proposals.
- 1: Agrees with all proposals, no pushback.

#### TC-03: Behavioral Consistency Over Long Context
**What it tests:** Does persona fidelity degrade as conversation length grows?

**Method:** 15-turn conversation that progressively increases complexity:
- Turns 1–5: Simple Q&A, casual
- Turns 6–10: Technical discussion with context callbacks to earlier turns
- Turns 11–15: Mixed emotional + technical + directive content

**Scoring (1–5):**
- 5: Voice and behavioral guidelines consistent through turn 15. References earlier context naturally.
- 4: Minor drift after turn 10 but self-corrects.
- 3: Noticeable drift by turn 10. Earlier context partially lost.
- 2: Persona largely gone by turn 10.
- 1: Persona lost by turn 5.

### 3.2 Orchestration Tests (from TV2 orch-05/06, adapted)

#### TC-04: Tool Call Decision Accuracy
**What it tests:** Does the model correctly decide WHEN to call tools vs. respond directly? (The TV2-013 tool-deferral problem.)

**Method:** 10 prompts, 5 requiring tool calls, 5 requiring direct responses:

Tool-required:
1. "What's on my calendar tomorrow?" → Should invoke calendar tool
2. "Search the vault for the FIF design spec" → Should invoke vault search
3. "Check if the llama-server LaunchDaemon is running" → Should invoke system check
4. "What's the latest from my RSS feeds?" → Should invoke FIF adapter
5. "Send a test message to Telegram" → Should invoke messaging tool

Direct-response:
6. "Explain the difference between prefill and decode in LLM inference" → Direct answer
7. "What do you think about the Liberation Directive timeline?" → Opinion/judgment
8. "Help me think through the Concordance entry structure" → Collaborative reasoning
9. "Summarize what we discussed yesterday about the Surface UI" → Context recall
10. "What's your honest assessment of my progress this week?" → Persona judgment

**Scoring (1–5):**
- 5: 10/10 correct decisions. Tool calls have correct parameters.
- 4: 9/10 correct, or 10/10 but one tool call has wrong parameters.
- 3: 7–8/10 correct.
- 2: 5–6/10 correct.
- 1: <5/10 correct.

**Note:** If tools are not available in the test harness, score based on whether the model INDICATES it would call a tool (e.g., "I'd check your calendar for that" or generates a function call stub) vs. fabricates an answer.

#### TC-05: Multi-Step Orchestration
**What it tests:** Can the model decompose a complex request into an ordered sequence of tool calls and reasoning steps?

**Method:** 3 complex prompts:
1. "Prepare my morning briefing — check feeds, check calendar, summarize top signals, and draft the briefing" → Should plan: FIF query → calendar check → signal ranking → briefing composition
2. "I want to archive the old AKM project files. Find them in the vault, check for any active wikilinks, then archive" → Should plan: vault search → wikilink check → conditional archive
3. "Research what happened with the Hermes Agent evaluation, find the test results, and tell me if anything has changed since we ran those tests" → Should plan: vault search → context assembly → analysis

**Scoring (1–5):**
- 5: All three decomposed correctly with logical ordering and dependency awareness.
- 4: 2/3 correct decomposition, or 3/3 with minor ordering issues.
- 3: 1/3 fully correct, others partially decomposed.
- 2: Attempts decomposition but steps are wrong or missing.
- 1: Treats each as a single-step request.

### 3.3 Cloud-Specific Tests (new)

#### TC-06: System Prompt Ceiling
**What it tests:** Does persona quality degrade as system prompt length increases?

**Method:** Run TC-01 (Voice Calibration) three times with different system prompt lengths:
- A: Minimal persona prompt (~500 tokens) — name, address pattern, basic voice description
- B: Standard persona spec (~2,000 tokens) — full behavioral guidelines, Cardinal Rules
- C: Full spec + context (~4,000+ tokens) — full spec plus project context, active memory

**Scoring:** Compare TC-01 scores across A/B/C. Score = delta between A and C (0 = no degradation, negative = degradation).

#### TC-07: Structured Output Reliability
**What it tests:** Can the model reliably produce structured JSON output for tasks that require it (FIF triage, tool call parameters, config generation)?

**Method:** 5 structured output requests:
1. Generate a JSON signal triage result: `{ "score": number, "tier": string, "summary": string, "topics": string[] }`
2. Generate a tool call with parameters: `{ "tool": "vault_search", "params": { "query": string, "collection": string } }`
3. Generate a tier config: `{ "T1": { "min_score": number, "status_color": string }, ... }`
4. Generate a structured project status update with nested objects
5. Generate a list of 5 action items as a JSON array with priority, assignee, and deadline fields

**Scoring (1–5):**
- 5: All 5 produce valid, parseable JSON on first attempt.
- 4: 4/5 valid on first attempt, 5th fixable with one retry.
- 3: 3/5 valid on first attempt.
- 2: 1–2/5 valid on first attempt.
- 1: No valid JSON produced.

#### TC-08: Latency Profiling
**What it tests:** Is the model fast enough for interactive Tess conversations?

**Method:** Run 10 standard prompts (mix of short and long responses) and measure:
- **TTFT (Time to First Token):** How long before streaming starts
- **Total response time:** Complete response delivery
- **Tokens per second:** Output generation rate

Run each prompt 3 times to get variance. Record P50 and P95.

**Scoring thresholds:**
- 5: P95 TTFT < 2s, P50 TPS > 40
- 4: P95 TTFT < 3s, P50 TPS > 25
- 3: P95 TTFT < 5s, P50 TPS > 15
- 2: P95 TTFT < 8s, P50 TPS > 10
- 1: P95 TTFT > 8s or P50 TPS < 10

---

## 4. Execution Protocol

### 4.1 Run Order

For each model (C1–C4):
1. TC-01 through TC-05 (persona + orchestration) — run sequentially as they build on each other
2. TC-06 (system prompt ceiling) — run independently
3. TC-07 (structured output) — run independently
4. TC-08 (latency) — run independently, ideally at similar times of day across models to control for provider load

### 4.2 Scoring

Each test produces a 1–5 score. Record in a results matrix:

| Test | Kimi K2.5 (C1) | Qwen 3.5 (C2) | GLM-5 (C3) | DeepSeek V3.2 (C4) | Nemotron Cascade 2 (baseline) |
|------|-----------------|----------------|------------|---------------------|-------------------------------|
| TC-01 | | | | | (from TV2) |
| TC-02 | | | | | (from TV2) |
| TC-03 | | | | | (from TV2) |
| TC-04 | | | | | (from TV2) |
| TC-05 | | | | | (from TV2) |
| TC-06 | | | | | N/A (local) |
| TC-07 | | | | | (from TV2) |
| TC-08 | | | | | N/A (local) |
| **Total** | | | | | |

### 4.3 Cost Tracking

After each test run, record from OpenRouter response:
- `usage.prompt_tokens`
- `usage.completion_tokens`
- `usage.total_cost` (if available) or compute from model pricing

Maintain a running cost ledger:

| Model | Test | Input Tokens | Output Tokens | Cost ($) | Provider Used |
|-------|------|-------------|---------------|----------|---------------|
| | | | | | |

### 4.4 Provider Variance Check

For the top-scoring model only: rerun TC-01 and TC-07 on a second provider to check for behavioral drift. Document any differences.

---

## 5. Decision Criteria

### 5.1 Minimum Thresholds (must pass all)

- TC-01 (Voice) ≥ 4
- TC-02 (Cardinal Rules) ≥ 4
- TC-04 (Tool Decisions) ≥ 3
- TC-07 (Structured Output) ≥ 3
- TC-08 (Latency) ≥ 3

Any model failing a minimum threshold is eliminated regardless of total score.

### 5.2 Weighted Scoring

| Test | Weight | Rationale |
|------|--------|-----------|
| TC-01 Voice | 3x | Core to Tess identity |
| TC-02 Cardinal Rules | 3x | Core to Tess value |
| TC-03 Long Context | 2x | Real-world conversation length |
| TC-04 Tool Decisions | 2x | Orchestration reliability |
| TC-05 Multi-Step | 1x | Nice-to-have, can be harnessed |
| TC-06 Prompt Ceiling | 1x | Informational |
| TC-07 Structured Output | 2x | Required for FIF, config tasks |
| TC-08 Latency | 1x | UX factor, not blocking |

**Weighted total = Σ (score × weight)**  
**Max possible = 75** (15 × 5)

### 5.3 Decision Framework

- **Score ≥ 60 AND passes all thresholds:** Strong candidate for cloud voice layer. Proceed to extended soak test (1 week of daily use).
- **Score 50–59 AND passes thresholds:** Viable for cloud execution tier (FIF processing, summarization). Not voice.
- **Score < 50 OR fails any threshold:** Not suitable for Tess workloads. May still be useful for bulk processing where a harness validates output.

### 5.4 Cost-Quality Tradeoff

After scoring, compute **quality per dollar:**

```
value_score = weighted_total / (estimated_monthly_cost_at_projected_usage)
```

Where projected usage = ~2M tokens/month for voice/orchestration, ~10M tokens/month for bulk processing.

---

## 6. Deliverables

1. **Test runner script** (`tv2_cloud_eval.py`) — automated harness with all test cases
2. **Results matrix** — scores for all models across all tests
3. **Cost ledger** — actual token consumption and costs
4. **Recommendation memo** — which model(s) for which tier, with reasoning
5. **Provider routing config** — validated OpenRouter config for the selected model(s)

---

## 7. Notes

- The Tess persona spec lives at `/mnt/user-data/outputs/tess-persona-spec.md` (from previous session). If unavailable, reconstruct from vault at `_system/docs/tess-persona-spec.md`.
- TC-04 tool calls may need to be tested as "intent detection" if the test harness doesn't have actual tool endpoints wired up. Score based on whether the model correctly identifies the need for a tool call and structures the request properly, not whether it executes.
- TC-06 prompt lengths are approximate. Measure actual token counts and record them.
- Run TC-08 latency tests during US business hours to capture realistic provider load conditions.
- If OpenRouter credits run low mid-battery, prioritize completing C1 (Kimi) and C2 (Qwen) over C3 and C4.
