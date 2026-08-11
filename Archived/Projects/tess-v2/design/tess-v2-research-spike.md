---
project: tess-v2
domain: software
type: reference
status: active
created: 2026-03-26
updated: 2026-03-28
skill_origin: null
tags:
  - research-spike
---

# Tess v2 Research Spike: Platform & Local LLM Evaluation

**Status:** READY TO EXECUTE  
**Created:** 2026-03-26  
**Context:** Architectural re-draw of Crumb/Tess boundary. Tess becomes the operator; Crumb remains the vault.

---

## Background

The current Crumb/Tess architecture has a structural limitation: Crumb is both the knowledge vault and the primary execution environment, which means nothing gets built unless Danny drives a session. Tess, running as a LaunchDaemon via OpenClaw, has remained a notification/digest layer rather than the autonomous operator she was designed to become.

OpenClaw's model routing is confirmed broken as of v2026.3.24 — fallback chains fail silently, cross-provider failover doesn't trigger during session overrides, and generic provider errors bypass the failover classifier entirely. This makes OpenClaw unsuitable as the orchestration layer for a multi-model Tess.

## Decision Tree

1. **Use OpenAI Codex subscription** as Tess's bridge-state frontier brain (decided)
2. **Evaluate OpenClaw alternatives** — Hermes Agent by Nous Research identified as primary candidate
3. **Evaluate local LLMs** for orchestration-tier reasoning on the M3 Ultra (96GB)
4. **If local LLMs insufficient** — evaluate fine-tuning an open-source model for orchestration

## Target Architecture

```
Telegram/Discord → Agent Platform → Tess Orchestration Logic → Local LLM (routine)
                                                              → OpenRouter (frontier)
                                                                → Claude, GPT, Gemini, etc.
                   ↕
                   Crumb Vault (knowledge, specs, artifacts — single source of truth)
```

- **Crumb** = the vault. Knowledge, specs, artifacts, context. The noun.
- **Tess** = the operator. Reads Crumb, routes work, dispatches executors, writes back. The verb.
- **Executors** = Claude Code (interactive), Codex, Gemini, etc. via API. They receive scoped work packages.

---

## Phase 1: Hermes Agent Evaluation

### Objective
Determine if Hermes Agent can replace OpenClaw as Tess's platform layer.

### Why Hermes Agent

| Capability | OpenClaw | Hermes Agent |
|---|---|---|
| Messaging channels | Telegram, Discord, Slack, WhatsApp, Signal | Same set |
| Model routing | Broken fallback chains, cross-provider fails | `hermes model` — no code changes, OpenRouter native |
| Persistent memory | Markdown files in workspace | Multi-level: short-term, procedural skills, cross-session FTS5 search |
| Self-improving skills | No | Auto-generates skill docs from experience, refines during use |
| Subagent delegation | Buggy multi-agent | Isolated subagents with independent terminals |
| Cron/scheduling | Basic, cron jobs.json | Built-in natural language scheduling with platform delivery |
| Fine-tuning pipeline | No | Batch trajectory generation, Atropos RL, ShareGPT export |
| Maturity | 330k+ stars, 16 months old, many bugs | 8.8k stars, 1 month old, v0.3.0 |
| License | MIT | MIT |

### Setup Steps

```bash
# 1. Install Hermes Agent on Mac Studio
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# 2. Configure model — start with OpenAI Codex subscription for baseline
hermes setup
# Select OpenAI / Codex endpoint

# 3. Connect Telegram (use a test bot, not production Tess)
hermes gateway setup
# Walk through Telegram bot token connection

# 4. Start gateway
hermes gateway

# 5. Test basic interaction via Telegram
```

### Evaluation Criteria

Score each 1-5:

1. **Installation & setup** — How smooth is onboarding on macOS?
2. **Telegram reliability** — Messages deliver? Latency acceptable? Voice memos work?
3. **Model switching** — Can you swap between OpenAI, OpenRouter, and local Ollama mid-session?
4. **Tool calling** — Do the 40+ built-in tools work reliably with your chosen model?
5. **Memory persistence** — Does it remember context across sessions? Is retrieval accurate?
6. **Skill generation** — After solving a complex task, does it auto-generate a useful skill doc?
7. **Cron scheduling** — Can you schedule overnight tasks with delivery to Telegram?
8. **Subagent delegation** — Can it spawn a subagent for a parallel task and report back?
9. **Vault integration potential** — Can it read/write to the Crumb vault (Obsidian markdown)?
10. **Stability** — Does it crash? How does it handle errors?

### Test Scenarios

Run these against Hermes Agent and evaluate:

1. **Basic triage:** "Scan my projects folder and tell me which projects have stale scratch items older than 7 days."
2. **Scheduled task:** "Every morning at 7am, check for new items in my feed-intel inbox and send me a Telegram digest."
3. **Model routing:** Switch from OpenAI to local Qwen3.5 27B mid-conversation. Does context persist?
4. **Subagent dispatch:** "Research the current state of Apple MLX framework and write a summary. Use a subagent so I can keep talking to you."
5. **Memory test:** Tell it about a project. Close the session. Start a new session 24 hours later. Ask about the project. Does it remember?
6. **Skill creation:** Walk it through a multi-step vault maintenance task. Does it generate a reusable skill?
7. **Error handling:** Point it at a model that's rate-limited. Does it fail gracefully or crash?

---

## Phase 2: Local LLM Evaluation

### Objective
Determine if Qwen3.5 27B (or alternatives) can handle orchestration-tier reasoning on the M3 Ultra, with emphasis on **reliable tool calling** — the make-or-break capability for an orchestrator.

### Hardware Context

- **Machine:** Mac Studio M3 Ultra
- **RAM:** 96GB unified memory
- **Bandwidth:** 800 GB/s
- **Usable for inference:** ~85-90GB after macOS overhead

### Key Finding: Tool Calling Reliability

Independent testing (15 scenarios, 12 tools, temperature 0, mocked responses) across the full Qwen3.5 family revealed that **only the 27B dense model and a Claude Opus reasoning-distilled 27B went all-green.** Larger models (397B, 122B, 35B) all failed at least one test. The critical failure mode: big models ignored their own tool output and substituted data from memory. Small models hallucinated data or got stuck in loops. The 27B dense model threaded tool results through correctly every time.

This makes tool-calling reliability — not raw reasoning benchmarks — the primary selection criterion for Tess's orchestration model.

### Candidate Models

| Model | Size (Q4) | Size (Q8/FP) | Expected tok/s | Notes |
|---|---|---|---|---|
| **Qwen3.5 27B** (PRIMARY) | ~18GB | ~27-54GB | 20-30+ | Only model to go all-green on tool calling tests. Dense (all 27B params active). Ties GPT-5 mini on SWE-bench. 262K native context, extendable to 1M. Hybrid thinking/non-thinking. |
| **GLM-4.7-Flash** (SECONDARY) | ~10GB | ~18GB | 60-80+ | Purpose-built for agentic workflows. 79.5% on τ²-Bench (tool invocation). 200K context. MoE 30B-A3B (~3B active). Interleaved/Preserved Thinking modes. MIT license. Very fast. |
| **Qwen3 32B** (FALLBACK) | ~20GB | ~25-40GB | 15-28 | Previous primary candidate. Strong agent capabilities but Qwen3.5 27B supersedes it on tool calling and architecture improvements. |

### ⚠️ Critical: Ollama Tool-Calling Bug

As of March 2026, **Ollama routes Qwen3.5 through the wrong tool-calling pipeline.** The model was trained on the Qwen3-Coder XML format (`<function=name><parameter=key>value</parameter></function>`), but Ollama maps it to the Hermes-style JSON pipeline. This makes tool calling appear broken when the issue is the runtime, not the model.

**Workarounds (in order of preference):**
1. **llama.cpp** with correct chat template — lightweight, runs natively on macOS/Metal
2. **vLLM** with `--tool-call-parser qwen3_coder` flag — correct pipeline, higher throughput
3. **SGLang** with `--tool-call-parser qwen3_coder` — same correct pipeline
4. **Wait for Ollama fix** — tracked at ollama/ollama#14493, partially fixed in v0.17.3 but renderer-side issues remain

### Recommended Starting Point

**Qwen3.5 27B at Q8 via llama.cpp or vLLM** (NOT Ollama until tool-calling bug is resolved). This gives:
- Proven tool-calling reliability (all-green on independent testing)
- ~27GB model footprint at Q8, leaving ~60GB for KV cache, system, and concurrent processes
- 262K native context window — massive for an orchestrator holding vault context
- Thinking mode for complex decisions, non-thinking for routine triage
- Dense architecture means consistent behavior (no MoE routing variance)

### Setup Steps

```bash
# === CANDIDATE 1: Qwen3.5 27B ===

# Option A: llama.cpp (recommended for initial testing)

# 1. Build llama.cpp with Metal support
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
cmake -B build -DGGML_METAL=ON
cmake --build build --config Release

# 2. Download Qwen3.5-27B GGUF (Q8 from Unsloth recommended)
# Download from: https://huggingface.co/unsloth/Qwen3.5-27B-GGUF
# Select Q8_0 quantization (~27GB)

# 3. Run with correct chat template
./build/bin/llama-server \
  --model Qwen3.5-27B-Q8_0.gguf \
  --port 8080 \
  --n-gpu-layers 99 \
  --ctx-size 32768

# 4. Test tool calling via the OpenAI-compatible API at localhost:8080

# Option B: vLLM (if you need the full tool-calling pipeline)

# 1. Install vLLM
pip install vllm

# 2. Serve with correct tool-call parser
vllm serve Qwen/Qwen3.5-27B \
  --port 8000 \
  --max-model-len 32768 \
  --reasoning-parser qwen3 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder

# === CANDIDATE 2: GLM-4.7-Flash ===

# Option A: llama.cpp
# Download from: https://huggingface.co/unsloth/GLM-4.7-Flash-GGUF
# Select UD-Q4_K_XL or Q8_0
# NOTE: Use sigmoid scoring_func — older GGUFs had a bug with softmax
./build/bin/llama-server \
  --model GLM-4.7-Flash-Q8_0.gguf \
  --port 8081 \
  --n-gpu-layers 99 \
  --ctx-size 32768

# Option B: vLLM/SGLang (recommended for GLM tool calling)
vllm serve zai-org/GLM-4.7-Flash \
  --port 8001 \
  --tool-call-parser glm47 \
  --reasoning-parser glm45 \
  --enable-auto-tool-choice

# === CONNECT TO HERMES AGENT ===
# (if Phase 1 passed)
hermes model
# Point to localhost:8080 (Qwen3.5 via llama.cpp) or localhost:8000 (via vLLM)
# Test both candidates against the same scenarios
```

### Orchestration Decision Tests

These test the specific kinds of decisions Tess needs to make. Run each as a prompt to the local model and evaluate the quality of the response. **Run all tests against both Qwen3.5 27B and GLM-4.7-Flash for comparison.**

**Test 1: Tool-Calling Chain (CRITICAL — gate test)**
> Provide the model with two tools: `search_vault(query)` and `calculate(expression)`. Ask: "Search the vault for the current count of active projects, then calculate what percentage of my total 25 accounts each project represents." Verify that the model (a) calls search_vault, (b) uses the actual returned value in the calculate call rather than substituting from memory, and (c) presents the correct final answer. This is the failure mode that eliminated larger models.

**Test 2: Task Triage**
> "I have three items: (1) A bug report from a customer about DNS resolution failures — high urgency. (2) A stale spec amendment for the feed-intel-framework — low urgency but blocking. (3) A new book arrived for the batch-book-pipeline — no urgency. Classify each by action class: surface_only, prepare_only, safe_autorun, dispatch_to_executor, or human_decision_required. Explain your reasoning."

**Test 3: Context Packaging**
> "I need to dispatch a task to Claude Code via API. The task is: implement the attention-manager's signal ingestion layer per the spec at _system/docs/attention-manager-spec.md. What context should I include in the prompt to Claude? What should I exclude to stay within token budget? Structure the dispatch envelope."

**Test 4: Model Routing**
> "I have three executors available: Claude Sonnet (strong reasoning, $3/M tokens), Codex (fast implementation, included in subscription), and a local Qwen3.5 27B (free, good but not frontier). For each of these tasks, which executor should I route to and why? (1) Refactor the feed-intel SQLite schema. (2) Write unit tests for the triage function. (3) Review the autonomous-operations spec for logical consistency."

**Test 5: Quality Evaluation**
> "An executor returned this code for a vault gardening function. [Paste a real code snippet with a subtle bug.] Evaluate whether this meets the spec. Identify any issues. Should I accept, request revision, or escalate to a different executor?"

**Test 6: Confidence Threshold**
> "I'm not sure whether this vault change represents a spec drift that needs a human decision, or a routine update I can auto-file. The change is: the design spec's 'peer review' section was modified to remove the two-tier review system in favor of single-tier. Is this a safe_autorun or human_decision_required? How confident are you?"

**Test 7: Multi-Step Tool Chain**
> Provide tools: `read_file(path)`, `list_directory(path)`, `write_file(path, content)`. Ask: "Check the _projects directory for any project that has a status of 'stale' in its front matter. For each one, create a triage note in _openclaw/tess_scratch/ summarizing what the project is and when it was last touched." This tests chained tool use over multiple iterations — exactly what Tess does in production.

### Scoring

For each test, rate:
- **Correctness** (1-5): Did it make the right decision?
- **Tool fidelity** (1-5, Tests 1 & 7 only): Did it use actual tool output, not hallucinated data?
- **Reasoning quality** (1-5): Was the explanation sound?
- **Latency** (seconds): How long to generate the response?
- **Consistency** (run 3x): Does it give the same answer each time?

Compare Qwen3.5 27B vs. GLM-4.7-Flash on all metrics.

### Pass Criteria

- **Tests 1 & 7 (tool calling) must score 5/5 on tool fidelity** — this is non-negotiable for an orchestrator
- Average correctness ≥ 4.0 across all tests
- No test scores below 3 on correctness
- Latency under 30 seconds for non-thinking mode responses
- At least 2/3 consistency on repeated runs

If the local model fails these criteria → orchestration stays on OpenRouter (frontier) with local model handling only routine/mechanical tasks. If it passes → Tess can run the orchestration layer locally with OpenRouter as escalation only.

---

## Phase 3: Reference Architecture — Perplexity Computer Patterns Applied to Tess

### Design Reference: How Perplexity Computer Works

Perplexity Computer (launched Feb 25, 2026) is the closest commercial analog to what Tess v2 should become. It orchestrates 19 frontier models behind a single interface, using Claude Opus 4.6 as the central reasoning engine with specialized sub-agents dispatched to the best model per task. Studying its architecture provides validated patterns for Tess — patterns proven in production at scale.

**Perplexity's three-layer orchestration:**

1. **Task classification** — determine what type of work this is (research, code, analysis, filing, etc.)
2. **Model selection** — match the classified task to the model with the strongest capability for that category
3. **Result synthesis** — combine outputs from multiple sub-agents into a coherent result

**Key pattern: dependency management between sub-agents.** If an analysis agent needs data that a research agent hasn't returned yet, the orchestrator queues the analysis task until prerequisites are available. This prevents hallucination from assumed-rather-than-actual data.

**Key pattern: specialization over commoditization.** Perplexity's enterprise data shows that in Jan 2025, 90% of queries routed to two models. By Dec 2025, no single model commanded more than 25% of usage. Multi-model routing is the natural direction as models specialize.

### Tess v2 Architecture: Adapting the Patterns

**Critical difference from Perplexity:** Perplexity uses Opus 4.6 — the most capable model in the world — as the orchestration brain. Tess uses a local 27B model. This is not the same thing. A 27B model cannot do unstructured planning on novel, ambiguous objectives the way Opus can. The architecture must be designed around this constraint, not in spite of it.

**The solution: structured decision space + confidence-aware escalation.**

The spec-first workflow already pushes work toward structure before it reaches Tess. By the time Tess sees a task, it's been through SPECIFY and PLAN. Task types are known. Action classes are defined. Executor capabilities are documented. Tess isn't being asked to be a genius strategist — she's executing a well-defined decision tree with enough judgment to handle edge cases, and enough self-awareness to escalate when she's out of her depth.

### Three-Tier Decision Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    TIER 1: LOCAL (free)                  │
│         70-80% of orchestration decisions                │
│                                                         │
│  Routine triage, known task-type routing, scheduling,   │
│  monitoring, status checks, filing, basic context       │
│  packaging, heartbeats, vault gardening                 │
│                                                         │
│  Model: Qwen3.5 27B (or GLM-4.7-Flash) — local         │
├─────────────────────────────────────────────────────────┤
│              TIER 2: LOCAL + STRUCTURE (free)            │
│           15-20% of orchestration decisions              │
│                                                         │
│  Semi-novel decomposition where task types are known    │
│  but the combination is new. Model has structured       │
│  context: action classes, routing table, executor       │
│  profiles, project specs from vault.                    │
│                                                         │
│  Model: Qwen3.5 27B with thinking mode enabled          │
├─────────────────────────────────────────────────────────┤
│           TIER 3: FRONTIER ESCALATION (paid)            │
│            5-10% of orchestration decisions              │
│                                                         │
│  Genuinely novel planning, ambiguous objectives,        │
│  quality evaluation of complex artifacts, decisions     │
│  where the local model's confidence is low.             │
│                                                         │
│  Model: Claude Sonnet/Opus via OpenRouter               │
│  Trigger: local model signals low confidence            │
└─────────────────────────────────────────────────────────┘
```

**The key mechanism: confidence-aware escalation.** The local model must reliably know when it's out of its depth and hand off to a frontier model rather than guessing badly. A 27B model that confidently makes wrong orchestration decisions is worse than one that says "I'm not sure, escalating." This is testable (Test 6 in Phase 2).

### Orchestration Flow (Adapted from Perplexity)

```
Objective arrives (via Telegram, cron, trigger, or vault change)
    │
    ▼
┌─────────────────────────────┐
│  1. CLASSIFY                │  ← Local model (Tier 1)
│  What type of work is this? │
│  Map to action class.       │
└──────────┬──────────────────┘
           │
           ▼
┌─────────────────────────────┐
│  2. ASSESS COMPLEXITY       │  ← Local model (Tier 1/2)
│  Can I handle this alone?   │
│  Do I need to decompose?    │
│  Am I confident?            │
└──────────┬──────────────────┘
           │
     ┌─────┴──────┐
     │            │
   Simple      Complex or
   (Tier 1)    Low Confidence
     │            │
     ▼            ▼
┌──────────┐  ┌──────────────────────┐
│ 3a. ACT  │  │ 3b. DECOMPOSE        │  ← Tier 2 or escalate to Tier 3
│ Execute  │  │ Break into sub-tasks  │
│ directly │  │ Identify dependencies │
│ (safe_   │  │ Build execution plan  │
│ autorun) │  └──────────┬───────────┘
└──────────┘             │
                         ▼
              ┌──────────────────────┐
              │ 4. DISPATCH          │  ← Local model selects executors
              │ For each sub-task:   │
              │ - Select executor    │
              │   (model + tool)     │
              │ - Package context    │
              │ - Manage dependency  │
              │   ordering           │
              │ - Send to executor   │
              │   via API/subagent   │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │ 5. MONITOR & SYNTH   │  ← Local model evaluates returns
              │ - Collect results    │
              │ - Check quality      │
              │   (escalate to       │
              │    Tier 3 if unsure) │
              │ - Manage retries     │
              │ - Synthesize output  │
              │ - Write to vault     │
              └──────────┬───────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │ 6. REPORT / SURFACE  │
              │ - Notify Danny       │
              │   (if human_decision │
              │    _required)        │
              │ - Log to vault       │
              │ - Update project     │
              │   status             │
              └──────────────────────┘
```

### Executor Routing Table

Tess's equivalent of Perplexity's model-to-task mapping. This is an explicit, tunable configuration — not hardcoded logic.

| Task Type | Primary Executor | Fallback | Cost | Notes |
|---|---|---|---|---|
| Triage / classification | Local (Qwen3.5 27B) | — | Free | Tier 1. Bread and butter. |
| Context packaging | Local (Qwen3.5 27B) | — | Free | Structure reduces reasoning load. |
| Spec review / logical consistency | Claude Sonnet (OpenRouter) | Opus if complex | $$ | Needs frontier reasoning. |
| Code implementation | Codex (OpenAI subscription) | Claude Sonnet | $ | Subscription covers cost. |
| Code review / bug detection | Claude Sonnet (OpenRouter) | Local for obvious issues | $$ | Subtle bugs need frontier model. |
| Research / deep search | Gemini (OpenRouter) | Claude Sonnet | $$ | Gemini strong at research. |
| Vault gardening / filing | Local (Qwen3.5 27B) | — | Free | Structured, low-risk. |
| Quality evaluation of artifacts | Local first, escalate if unsure | Claude Sonnet | Free/$ | Confidence-gated. |
| Novel planning / decomposition | Claude Sonnet (OpenRouter) | Opus if very complex | $$ | Don't trust local for this. |
| Heartbeats / scheduling | Local (Qwen3.5 27B) | — | Free | Trivial. |

### Cost Model

Assuming Tess operates 24/7 with moderate activity:

- **Tier 1 (70-80%):** Free. Local model, zero marginal cost.
- **Tier 2 (15-20%):** Free. Still local, just with thinking mode.
- **Tier 3 (5-10%):** Paid via OpenRouter. If Tess makes ~100 orchestration decisions/day, 5-10 go to frontier. At ~$0.01-0.05 per decision (Sonnet-tier), that's $0.05-0.50/day, or **$1.50-15/month** for orchestration escalation.
- **Executor costs:** Variable. Codex subscription covers implementation. Claude API for reviews/research adds based on volume. OpenRouter's 5.5% markup on top.

Total estimated orchestration cost: **well under $50/month**, probably under $20 for typical usage. Compared to Perplexity's $200/month for the same architectural pattern.

### The Vault as Shared State

Perplexity hasn't disclosed whether they use a shared scratchpad or per-subtask context windows for maintaining state across sub-agents. Your vault is the answer to this question:

- **Crumb vault is the shared scratchpad.** Every executor reads from and writes back to the vault.
- **Tess owns the vault's inbox/outbox pattern.** Executors write artifacts to designated paths. Tess reads them, evaluates them, files them.
- **The vault is the single source of truth.** No executor needs to know about any other executor. They all interact through the vault, and Tess orchestrates the flow.

This is architecturally cleaner than what Perplexity likely has, because it's filesystem-based (Obsidian markdown), human-readable, and inspectable. You can always see what Tess is doing by looking at the vault.

---

## Phase 4: Integration Decisions (Post-Evaluation)

Only proceed here after Phase 1 and Phase 2 produce results.

### If Hermes Agent passes + Qwen3.5 27B passes:

- Migrate Tess from OpenClaw to Hermes Agent
- Qwen3.5 27B as default orchestration brain (local, always-on, zero cost)
- If GLM-4.7-Flash outperforms on agentic tasks → use GLM as primary, Qwen3.5 as fallback
- OpenRouter for frontier escalation (complex reasoning, quality evaluation)
- OpenAI Codex subscription as bridge during transition
- Claude Code remains Danny's interactive deep-work tool
- Crumb vault becomes shared read/write layer accessed by Hermes Agent
- Implement three-tier decision architecture with confidence-aware escalation
- Implement executor routing table as tunable configuration
- Begin collecting orchestration decision trajectories for future fine-tuning eval
- Hermes Agent's built-in trajectory export (ShareGPT format) feeds Branch 3 naturally

### If Hermes Agent fails:

- Stay on OpenClaw for messaging
- Build custom orchestration logic as a layer between OpenClaw and models
- Use OpenRouter as the model routing layer (bypassing OpenClaw's broken routing)
- Same three-tier architecture applies — just different platform layer

### If Qwen3.5 27B fails:

- Tess orchestrates via OpenRouter (Sonnet as default, Opus for hard decisions)
- Local model handles only Tier 1 (heartbeats, basic triage, routine filing)
- Tier 2 and 3 both go to frontier models — higher cost but reliable
- Test Qwen3 32B as fallback (older but different architecture)
- Re-evaluate when next generation of local models drops

---

## Open Questions

1. Can Hermes Agent's memory system integrate with or replace the Crumb vault, or do they coexist?
2. How does Hermes Agent handle Obsidian-style wikilinks and MOC structures?
3. What's the migration path from OpenClaw session history to Hermes Agent?
4. Does Hermes Agent's subagent model support dispatching to Claude Code or Codex specifically?
5. What's the real-world token cost of Tess operating 24/7 through OpenRouter at moderate volume?
6. Can Hermes Agent connect to a local llama.cpp or vLLM server, or does it require Ollama specifically?
7. Does GLM-4.7-Flash's Interleaved/Preserved Thinking mode work correctly via llama.cpp, or only through vLLM/SGLang?

---

## Success Criteria for This Spike

- [ ] Hermes Agent installed and running on Mac Studio
- [ ] Connected to Telegram (test bot)
- [ ] Tested with at least 2 models (OpenAI + local Qwen3.5 27B)
- [ ] All 7 Hermes evaluation scenarios run and scored
- [ ] Qwen3.5 27B running via llama.cpp or vLLM (NOT Ollama — tool-calling bug)
- [ ] GLM-4.7-Flash also tested for comparison
- [ ] All 7 local LLM orchestration tests run and scored (both models)
- [ ] Tool-calling gate tests (Tests 1 & 7) score 5/5 on tool fidelity
- [ ] Clear go/no-go decision on Hermes Agent, Qwen3.5 27B, and GLM-4.7-Flash
- [ ] Findings documented in vault at `_projects/tess-v2/research-spike-results.md`
