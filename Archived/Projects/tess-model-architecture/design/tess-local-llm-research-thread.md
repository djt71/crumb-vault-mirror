---
type: research
project: tess-model-architecture
domain: software
status: active
created: 2026-02-21
updated: 2026-02-22
source: claude-ai-session
tags:
  - local-llm
  - ollama
  - tess
  - openclaw
  - model-selection
routed_from: _inbox/
unverified_citations:
  - "GitHub #4567 (§7 R1 pushback) — Grok's 85% JSON validity claim, flagged as unverifiable in R1 synthesis"
  - "GitHub #5123 (§8 Next Steps) — cited as unresolved OpenClaw issue on dynamic task-type routing, not verified"
  - "OpenClaw v1.2 (§8 Next Steps) — version reference and docs claims not independently confirmed"
---

# Tess Local LLM Setup — Research Thread

**Date:** 2026-02-21
**Participants:** Danny (operator), Claude (Opus 4.6 via claude.ai)
**Context:** Nailing down the local LLM configuration for Tess (OpenClaw) on Mac Studio M3 Ultra 96GB, co-hosted with Crumb.
**Peer review:** R1 completed by DeepSeek V3.2-Thinking, Gemini 3 Pro Preview, GPT-5.2, Perplexity Pro, Grok 3.5. R2 completed by same panel. Syntheses appended.

> **Scope note:** This thread tracks (1) local model options and constraints, and (2) how those constraints interact with Tess's persona and routing architecture. External model details are best-effort, snapshot-in-time as of Feb 2026; design decisions are specific to this OpenClaw/Tess stack. "Community consensus" claims are anecdotal (GitHub discussions, forum posts) and unverified on our hardware unless stated otherwise. These numbers are a Feb 2026 snapshot; re-check before reusing.

---

## 1. Opening — Establishing Context

**Danny:** ok new research to be done. we need to nail down the local LLM setup for tess (openclaw).

**Claude:** I'll need to get up to speed on where things stand with the OpenClaw/Tess local LLM setup. Let me check what we've discussed previously.

*[Searched past conversations for OpenClaw/Tess local LLM context, Mac Studio hardware specs, and previous model recommendations]*

Good — I've got solid context from our previous work. Let me now do fresh research since that strategy doc is about a week old and the local LLM landscape moves fast.

*[Conducted web searches across Ollama docs, OpenClaw integration guides, community discussions, model benchmarks, and Mac Studio performance reports]*

Here's where things stand and what's shifted since we did the strategy doc on Feb 15:

**What hasn't changed:**
- Your hardware: Mac Studio M3 Ultra 96GB, co-hosting Crumb + OpenClaw
- The architecture: Ollama serving local models, OpenClaw connecting via OpenAI-compatible API
- The principle: cloud-first Phase 1 with logging, local model transition at Phase 1.5
- The known gotchas: `num_ctx` silent truncation, `reasoning: false` requirement, cooldown bug, sub-agent routing bug, gateway stability issues

**What HAS changed or solidified:**

**1. `ollama launch openclaw` is now the official path.** Ollama shipped this in their Feb 2026 release. It handles provider config, model discovery, and gateway startup automatically. This simplifies setup considerably — you don't need to hand-edit `openclaw.json` for the Ollama provider block. You can still override manually afterward, but the onboarding friction dropped substantially.

**2. The model landscape has a new contender: `qwen3-coder-next`.** This is an 80B total / ~3.9B active hybrid Mamba-Transformer MoE model with 256K native context (though community reports suggest effective stability closer to ~100K due to RoPE scaling limits — irrelevant for our 64K target, but the model table shouldn't overstate capability). It uses a hybrid architecture: Mamba (state space model) layers for efficient long-sequence processing + Transformer attention layers for complex reasoning, reducing KV cache requirements compared to a pure Transformer of equivalent size. It was released ~2 weeks ago and is explicitly trained for agentic coding with 800K executable tasks + RL. It's non-thinking mode only (no `<think>` blocks), which actually *helps* for OpenClaw since the `developer` role / reasoning mismatch bug goes away. The catch: 48GB base + KV cache + other processes puts it near the ceiling on shared 96GB; promotion is gated on measured headroom (≥20GB). **Prerequisite:** Flash Attention support must be validated in the Ollama Metal backend for efficient long-context inference at 64K+.

**3. The community points toward a stable pairing.** Multiple anecdotal reports (GitHub discussions, Clawdbook, forum posts — unverified on our hardware) point to: `qwen3-coder:32b` (or the 30B MoE variant) as primary, `glm-4.7-flash` as backup/alternative. Both are 30B-A3B MoE architecture, ~19-21GB at Q4_K_M base.

**Model comparison (snapshot, Feb 2026):**

| Model | Params / Arch | Est. Q4_K_M size | Native context | Tool calling | Notes |
|-------|---------------|------------------|----------------|--------------|-------|
| `qwen3-coder:30b` | 30B MoE, ~3.3B active | ~19GB | 256K (effective ~100K per community reports) | Strong (reports of good tool calling; not yet validated on our stack) | Non-thinking only. Well-tested in community. |
| `qwen3-coder-next` | 80B hybrid Mamba-Transformer MoE, ~3.9B active | ~48GB | 256K (same RoPE caveat) | Strong (agentic RL training, 800K tasks) | Non-thinking only. Hybrid Mamba arch reduces KV cache vs pure Transformer. Memory-tight on shared 96GB — gated on empirical validation. Requires Flash Attention validation. |
| `glm-4.7-flash` | 30B MoE, ~3B active | ~19GB | 128-200K | Strong (high τ²-Bench scores) | Ollama chat template issues (Unsloth warns against). Quarantined. |
| `qwen3:32b` | 32B dense | ~20GB | 40K | Good but weaker than coder variants | Supports thinking mode. Dense: more consistent, but smaller context window (40K). General instruct — better conversational range, worse tool fidelity. |

**4. GLM-4.7-Flash has an Ollama chat template warning.** Unsloth's docs explicitly say they don't recommend running GLM-4.7-Flash GGUFs with Ollama due to potential chat template compatibility issues — they recommend llama.cpp or LM Studio directly. Some community members report it working fine via Ollama, but it's a known risk. This is relevant because our strategy doc had it as the backup.

**5. The `openai-completions` vs `openai-responses` API format matters.** One community member on GitHub confirmed a critical gotcha: use `openai-completions` provider format, not `openai-responses` — the latter calls `/v1/responses` which hangs. Your current `openclaw.json` doesn't have a model provider block yet (you're on cloud Anthropic only right now), but this needs to be right when you add one.

**Decisions we need to nail down:**

Here's what I think we actually need to resolve:

**A. Primary local model: `qwen3-coder:30b` vs `qwen3-coder-next`**

`qwen3-coder:30b` — 30B total, 3.3B active, ~19GB Q4_K_M. Fits comfortably on your 96GB with plenty of room for 64K context KV cache + all the other processes. Well-validated by community with OpenClaw. Non-thinking mode only. 256K native context.

`qwen3-coder-next` — 80B total, ~3.9B active (hybrid Mamba-Transformer MoE), ~48GB Q4_K_M. Better benchmarks, more agentic training. But 48GB base + KV cache for 64K context totals ~53-57GB (see memory budget below), leaving ~19-23GB for Crumb sessions, Obsidian, Docker, etc. — borderline against the 20GB headroom target on shared 96GB hardware.

**Preliminary memory budget (estimates — validate empirically in step 3):**

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

*\*Hybrid Mamba-Transformer: Mamba layers use fixed-size state (~negligible per-token cost) instead of KV cache, so effective KV cache is lower than a pure Transformer of equivalent total size. Actual reduction depends on Mamba-to-Transformer layer ratio — validate empirically.*
*†System baseline: macOS (~6GB) + Obsidian (~3GB) + Docker (~3GB) + OpenClaw gateway (~1GB) + Claude Code terminal (~1GB) + misc (~4GB) = ~18GB conservative estimate.*

My recommendation: **`qwen3-coder:30b`**. The 80B model is genuinely better, but your Studio is a shared machine. The 30B model leaves 52-57GB of headroom; the 80B model leaves only 23-26GB — barely meeting the 20GB target with q4_0 KV quantization and failing it with q8_0. Headroom matters more than squeezing a marginal quality improvement out of the always-on agent. If you had 192GB, different story.

**B. Backup model: `glm-4.7-flash` viability**

Given the Ollama template issues, you have three options: run it via Ollama anyway and accept the risk, run it via LM Studio alongside Ollama (adds complexity), or skip it and use cloud Haiku 4.5 as the fallback. The original strategy had Haiku as the API fallback already, so GLM-4.7-flash was really positioned as an *alternative* local primary, not a true backup.

My recommendation: **Drop GLM-4.7-flash for now.** Use `qwen3-coder:30b` as local primary, `anthropic/claude-haiku-4-5` as cloud fallback. You can always revisit GLM when the Ollama template issues are resolved. Simpler stack.

**C. Setup path: `ollama launch openclaw` vs manual config**

Given you already have OpenClaw onboarded and running with cloud Anthropic, the question is whether to re-run the launch command or manually add the Ollama provider to your existing `openclaw.json`.

My recommendation: **Manual config addition.** You already have a hardened `openclaw.json` from OC-009. Running `ollama launch openclaw` would potentially overwrite your gateway config and security settings. Better to surgically add the Ollama provider block.

**D. Context window and KV cache strategy**

OpenClaw needs 64K minimum. With `qwen3-coder:30b` at Q4_K_M (~19GB) on 96GB unified memory, you have plenty of room. But you should also consider KV cache quantization (`OLLAMA_KV_CACHE_TYPE=q8_0`) to reduce memory pressure further, since this is a shared machine.

**E. How much of Tess's persona runs locally vs in the cloud?** This turns out to be the defining architectural question — it drives model selection, routing design, and cost structure. See §3–4.

Want me to dig deeper into any of these, or does the direction look right and we should move to drafting the actual config changes?

---

## 2. Thinking Model Question

**Danny:** hmm. do we want a thinking model for tess?

**Claude:** Good question. Let me think through what Tess (OpenClaw) actually *does* versus what benefits from thinking.

**Hard constraint first:** Using thinking models via Ollama with OpenClaw is currently operationally unsafe due to the `developer` role mismatch bug — when `reasoning: true`, OpenClaw sends prompts using the `developer` role, which Ollama doesn't support, causing silent failures or garbled output. This is a hard blocker, not a taste preference.

**Even if that bug is fixed, the architectural argument holds:**

**What Tess handles:**
- Heartbeats, cron jobs, vault-check automations
- Message triage and responses via Telegram
- Quick captures, reminder execution
- Daily briefings
- Deferred directive execution
- Vault status queries

**Where thinking helps:** Tasks requiring multi-step reasoning, weighing tradeoffs, complex judgment calls — basically the kind of work where you want the model to "show its work" internally before committing to an action.

**Where thinking hurts:** Latency. A thinking model generates a chain-of-thought before every response. For a heartbeat or a quick capture, that's wasted time and tokens. For an always-on agent responding to Telegram messages, you want snappy responses — not 30 seconds of internal deliberation before saying "noted, added to inbox."

**The practical constraints on your stack:**
- The `developer` role mismatch bug means thinking mode + Ollama = silent failures or garbled output. Setting `reasoning: false` was already in our strategy doc as a required workaround.
- `qwen3-coder:30b` is non-thinking mode only anyway — it doesn't generate `<think>` blocks. Same for `qwen3-coder-next`. Per their model cards, these variants ship without thinking mode support.
- The base `qwen3:30b` (non-coder variant) *does* support thinking mode, but it's worse at tool calling than the coder variant, which is the whole point for an agent.

**My take:** No thinking model as Tess's default. The vast majority of OpenClaw agent tasks are structured, tool-driven operations where reliability and speed beat depth of reasoning. That said, thinking isn't universally bad — there may be low-frequency, high-stakes tasks (e.g., complex triage decisions, ambiguous directive interpretation) where slower chain-of-thought is worth the latency. Those tasks are better routed to cloud (Haiku/Sonnet) where thinking is handled properly, rather than running a thinking-capable local model for all traffic just to cover edge cases.

Thinking is Crumb's domain. Tess should be fast, reliable, and obedient to tool schemas. The coder variants score highest on structured output and instruction-following benchmarks for this model class, which is exactly the profile we need.

Does that track with how you're thinking about it, or is there a specific use case you had in mind where you'd want Tess to reason more deeply?

---

## 3. Document Review — Tess Identity & Architecture

**Danny:** *[Uploaded `tess-crumb-deliverables.zip` and `tess-crumb-architecture.png`]*

take a look at the attached docs and analyze

**Claude:** *[Extracted and reviewed all documents: IDENTITY.md, SOUL.md, tess-crumb-comparison-user.md, tess-crumb-boundary-reference.md, tess-crumb-diagram.jsx, and the architecture diagram]*

The documents are well-structured and internally consistent. The IDENTITY.md, SOUL.md, comparison doc, and boundary reference all tell the same story from different angles without contradicting each other. The architecture diagram matches what the docs describe. This is solid design work.

**How this changes the local LLM conversation:**

Looking at what Tess actually needs to *do* versus what she needs to *be*, there's an important distinction the SOUL.md makes explicit:

Tess has two registers. The default is pure operator — short, direct, tool-driven. That's 90% of her workload and maps perfectly to `qwen3-coder:30b` in non-thinking mode. Fast tool calls, structured output, reliable schema adherence.

But then there's the **second register** (as defined in SOUL.md) — reaching for past decisions, philosophical parallels, and historical context when a problem needs *reframing*, not just executing. This register demands multi-hop retrieval, narrative consistency across days, and tonal judgment (when to shift from operator to advisor mode). It's what makes Tess more than a dispatcher.

This is where it gets honest: **a local 30B MoE model with 3B active parameters is not going to nail that second register.** It'll follow style instructions mechanically, but the nuanced personality work — humor that lands, vault precedent surfaced at the right moment, tone shifts calibrated to context — requires frontier-model language capability.

**The specific failure mode:** If we force Tess's persona through a local 30B MoE, she'll follow style instructions (short sentences, no emoji, dry tone) but exhibit brittle judgment, inconsistent humor, and shallow precedent use. The danger is that this will *feel* like Tess — because it matches the surface — while drifting on the deeper commitments in SOUL.md. Surface compliance without depth is worse than obviously flat output, because you won't notice the drift until it's already undermined trust in the character.

**So the real question is: how much does the second register matter to you for always-on Telegram interactions?**

Because the tiered routing we designed handles this if you're willing to accept a split:

- **Tier 1 (local `qwen3-coder:30b`):** Handles the operator register — inbox triage, lookups, automation, status checks, quick captures, heartbeats, cron jobs. This is the bulk of the volume.
- **Tier 2 (cloud Haiku 4.5):** Handles the harder message responses where tone and judgment matter — the stuff where you'd actually *notice* if Tess's personality fell flat.
- **Tier 3 (cloud Sonnet 4.5):** Research delegation, complex synthesis.

The alternative would be running the local model for *everything* and accepting the persona degradation described above — surface compliance with SOUL.md instructions, without the depth that makes the character work.

**My recommendation stays the same but with a sharper reason:** `qwen3-coder:30b` for the operational bulk, cloud fallback for anything that needs Tess to actually *be Tess*. The SOUL.md essentially argues for this split — it describes a character that requires frontier-model-tier language capability to execute well, and an operational mode that a local coder model handles fine.

The open question is: **can OpenClaw route by task complexity automatically, or do you need to manually assign which tasks go local vs cloud?** Because if the routing is purely model-level (primary + fallback), then everything hits local first and only falls back on failure — which means Tess's personality lives or dies on the local model's ability to execute the SOUL.md. If you can route by *task type* (heartbeats → local, message responses → cloud), that's a much better architecture for what these docs describe.

What's your read?

---

## 4. Personality-First Tiering Decision

**Danny:** the personality aspect of tess is important. i'd be willing to re-arrange the tiering and introduce cloud models as front-line to achieve that.

**Claude:** That makes sense — the SOUL.md isn't decoration, it's core to what makes Tess useful as a daily companion. If she sounds like a generic bot 90% of the time, the whole point of the persona work is lost.

Let me think through what a personality-first tiering looks like.

**The inversion:**

Instead of "local first, cloud fallback," we flip it: **cloud first for anything user-facing, local for anything mechanical.**

The split becomes about *audience*, not complexity:

**Tier 1 — Cloud (Haiku 4.5): Everything Danny sees.** Any message that generates a response you'll read in Telegram. Inbox triage summaries, status checks, message responses, decision support, comms drafting, the daily briefing. This is where the SOUL.md needs to land. Haiku is cheap enough for this volume and good enough to carry the personality.

**Tier 2 — Local (`qwen3-coder:30b`): Everything Danny doesn't see.** Heartbeats, cron job execution, vault-check automations, file operations, bridge relay mechanics, monitoring pings, structured data extraction, tool-chain orchestration. The plumbing. No personality needed — just reliable tool calling and structured output.

**Tier 3 — Cloud (Sonnet 4.5): Reserved for quality-critical output.** Research delegation, complex synthesis, anything that feeds into the vault via the bridge where accuracy matters more than speed.

**What this buys you:**
- Tess's voice is consistent in every interaction you have with her
- The local model does what it's actually good at — mechanical, structured, tool-driven work
- API costs stay manageable because Haiku is dirt cheap and the high-volume mechanical tasks are offloaded to local
- You're not fighting the local model to be something it isn't

**What this costs you:**
- You're dependent on Anthropic API availability for every Telegram interaction. If the API goes down, Tess goes mute for user-facing responses (local can still run background tasks)
- Haiku token costs are low but nonzero — you're paying for every message instead of running most of them free
- Latency on user-facing responses includes the API round-trip instead of local inference

**The practical question is whether OpenClaw can route this way.** Specifically, can you assign different models to different agent behaviors or task types? From what I've seen in the config, you can set per-agent model overrides and define a primary + fallback at the defaults level. But routing by "is this user-facing or mechanical" might require either separate agent definitions or some custom routing logic.

Want me to dig into the OpenClaw config model to figure out how to wire this split? That's the implementation question that determines whether this architecture is clean or hacky.

---

## 5. Why a Coder Model?

**Danny:** let me rephrase, why are we so focused on a coding specialized model as primary?

**Claude:** That's a fair challenge. The reasoning is conditional — it depends on the tiering decision we just made:

1. **If Tess's local model were user-facing**, a coder-specialized model would be the *wrong* choice. You'd want a general instruct model (`qwen3:32b`, `glm-4.7-flash`) optimized for natural language, tone, and personality.
2. **Once we committed to cloud-first for all user-visible text**, the local model's job narrowed to schema-faithful tool execution and file operations.
3. **Given that narrower job**, coder models re-emerge as the right fit — they score higher on instruction following (IF) benchmarks and tool-calling fidelity than general models at the same size.

The coder model isn't chosen because Tess writes code. It's chosen because OpenClaw's agent workload is structured JSON function calls, parameter passing, and multi-step tool chains — and coder models are more obedient to structured instructions than general instruct models. We're treating IF scores as the primary metric for local model selection: higher IF = better schema obedience, which is what Tess-local needs.

**Escape hatch:** If API costs or Anthropic dependence become intolerable and we're forced back to "local-first for everything," we should re-open the coder vs general-model decision and accept a flatter Tess in exchange for independence. That's a documented fallback, not a failure.

---

*Below this line is authored synthesis, not transcript.*

---

## 6. Peer Review Synthesis (R1)

**Reviewers:** DeepSeek V3.2-Thinking, Gemini 3 Pro Preview, GPT-5.2, Perplexity Pro, Grok 3.5

### Universal Agreement (high confidence — all five reviewers converge on these)

- **Routing is the blocking prerequisite.** All five reviewers flagged OpenClaw's ability to route by task type / agent as the keystone risk. Resolve before model selection matters.
- **Personality-first tiering inversion is the right call.** Universal agreement that cloud-first for user-facing / local for mechanical is sound.
- **The coder model is justified *because* personality moved to cloud.** The conditional dependency is correct.
- **Memory estimates need to be empirical, not qualitative.** The "probably too tight" analysis for the 80B model isn't decision-grade.
- **GLM-4.7-flash should be quarantined, not abandoned.** Gate re-entry behind: confirmed Ollama template compatibility, validated tool calling, long-context behavior tested.
- **Model keepalive is important.** Use `OLLAMA_KEEP_ALIVE=-1` (or `ollama run --keep-alive -1`) to lock the model in memory and avoid cold-start latency.

### Majority Agreement (four of five)

- **30B model is the right starting point; 80B should be gated, not ruled out.** The decision should be conditional with enforceable promotion criteria.
- **The decision record should be conditional, not absolute.** "If X passes gates, promote" rather than "confirmed."
- **Fallback behavior for API outages needs a documented answer**, even if provisional.

### Notable Divergence

- **Gemini alone pushed hard for the 80B model as primary.** The other four either supported 30B or framed it as conditional. Gemini's memory math was the least rigorous — it claimed "~40GB remaining is plenty" without accounting for KV cache, Docker, Obsidian, macOS overhead, or concurrent Crumb sessions.
- **ChatGPT proposed the "two contracts" abstraction** — the strongest single reframing idea. See below.
- **Perplexity focused on document maintainability** — separating snapshot-in-time model facts from durable design decisions. Applied to this doc's preamble.

### Key Reviewer Contributions

**DeepSeek:** Bridge confirmation echo must be respected by local model — no auto-confirming high-risk operations. Structured task logging (already in Phase 1 plan) covers the observability need.

**Gemini:** Instruction Following (IF) scores are the right lens for local model selection — coder models score higher on IF than general models at the same size. This isn't about writing code; it's about schema obedience. KV cache quantization at `q4_0` (more aggressive than `q8_0`) is viable for structured tool output where natural language nuance doesn't matter.

**ChatGPT:** Define **two contracts** instead of "picking a best model":
1. **Mechanical Contract (Local):** deterministic tool calling, schema adherence, low latency, high uptime
2. **Persona Contract (Cloud):** voice fidelity, judgment, safe ambiguity handling

Then model selection becomes a satisfaction test against the contract. Future model swaps are cheap — test against the contract instead of re-running the full analysis. This should be codified as a vault reference doc.

**Perplexity:** The persona failure mode needs to be explicit: forcing the SOUL.md through a local model produces surface compliance without depth — brittle judgment, inconsistent humor, shallow precedent use. This *feels* like Tess while drifting on deeper commitments, which is worse than obviously flat output. Also: separate "external facts" from "system-specific conclusions" in the doc for maintainability.

**Grok:** Reviewed R1 (pre-synthesis). Independently converged on most structural improvements already applied in R2 (scope preamble, model table, risk register, conditional decisions, escape hatch, attribution softening), providing cross-reviewer validation that R2 changes weren't over-fitted to any single reviewer. Unique additions: (1) flag intentionality language when attributing design choices to model authors — use "per model card" or "docs describe" instead of "by design from Qwen"; (2) consolidate SOUL.md concept repetitions — define "second register" once and backreference, keep voice-calibration prose in SOUL.md rather than repeating in the research thread; (3) proposed eventual doc split into stable "Local Model Design Decision" doc + transient "Research Log" (deferred until routing PoC resolves).

### What Claude (Opus) Pushed Back On (R1)

- **Gemini's 80B recommendation:** The 80B and 30B models have similar active parameter counts (3.3B vs 3.9B). The quality improvement comes primarily from more expert networks and the hybrid Mamba-Transformer architecture, not dramatically more parameters per token. For structured tool calling (the local model's only job), the marginal improvement doesn't justify the memory risk on shared hardware (see memory budget in §1).
- **DeepSeek's "Crumb sessions could spike memory" concern:** Somewhat overstated. Claude Code runs via API — the local footprint is Node.js + terminal, not GPU-scale inference. Obsidian is the bigger memory hog.
- **Haiku 4.5 as persona carrier:** None of the reviewers questioned whether Haiku is actually *good enough* to carry the SOUL.md persona. Haiku is the smallest Claude model. The second register (see §4) may need Sonnet-tier capability to land properly. This remains an open question — test before committing.

---

## 7. Peer Review Synthesis (R2)

**Reviewers:** DeepSeek V3.2-Thinking, Gemini 3 Pro Preview, GPT-5.2, Perplexity Pro, Grok 3.5

### Universal Agreement (R2)

- **R2 is decision-grade.** All five reviewers confirmed the doc has moved from exploratory research to a concrete, conditional design with clear next steps. No fatal flaws identified.
- **Routing PoC remains the critical-path blocker.** Everything else is contingent. No reviewer disagreed.
- **Design Contracts abstraction is strong and should be the evaluation framework going forward.** Future model swaps become conformance tests, not rewrites.
- **API-down degradation needs to be a named protocol with explicit behavior.** The current "degrade to local with indicator" is too hand-wavy for a HIGH-severity risk.
- **Haiku persona evaluation needs predefined pass/fail criteria before testing.** Without a rubric, the persona test becomes vibes-based, which defeats the purpose.

### Majority Agreement (R2) (3+ reviewers)

- **Confirmation echo should be elevated to a Mechanical Contract invariant** (GPT, DeepSeek, Grok). It's a system safety property, not an implementation detail. The local model must never auto-confirm destructive bridge operations.
- **Memory gate needs a defined load shape** (GPT, Grok, DeepSeek). "Under load" must mean: 64K context + 10 sequential tool calls + concurrent Obsidian + Docker + OpenClaw gateway active. Otherwise the headroom gate is too easy to accidentally satisfy in a sterile test.
- **The doc should eventually split into stable decision doc + transient research log** (Perplexity, Grok, GPT). Timing differs — GPT and Grok suggest sooner, Perplexity and existing plan say defer until after routing PoC.

### Unique R2 Contributions (ranked by signal)

**GPT-5.2 — "Two clocks" routing abstraction.** The system implicitly operates on two clocks: a *human clock* (Telegram interactions, persona continuity) and a *machine clock* (heartbeats, cron, checks). The tiering inversion aligns with this, but only if routing is keyed on clock source, not complexity. Formalizing `channel=human` vs `channel=machine` as a first-class routing attribute resolves edge cases where a "simple" human message still needs persona, and a "complex" machine task still must stay local. This is cleaner than complexity-based routing because the routing decision becomes obvious without judgment calls.

**GPT-5.2 — Routing needs spec-grade acceptance criteria.** "Routing PoC" is currently a placeholder. It should define pass/fail in one paragraph: what constitutes "route by audience" (Telegram-visible vs background), at what granularity (per agent, per tool, per task type, per message channel), and what the minimum viable fallback is if native routing can't do it.

**DeepSeek — Mixed-task routing as a PoC test case.** A single user request can span both mechanical and persona work (e.g., "Check the vault for my last meeting with X and tell me if we resolved Y" — vault lookup is mechanical, the summary needs persona). The routing PoC must test whether OpenClaw can support sub-task delegation, not just pure-type routing.

**DeepSeek → GPT — Bridge confirmation echo elevated to contract.** DeepSeek identified it as a test case in R1; GPT correctly elevated it to a Mechanical Contract invariant in R2. If the local model can auto-confirm destructive bridge operations, it doesn't matter how well it handles tool schemas.

**Perplexity — Haiku/Sonnet as mixed tier, not binary upgrade.** Instead of "Haiku provisional, upgrade to Sonnet if it fails," consider a mixed cloud persona tier: Haiku for routine persona interactions, Sonnet only for second-register / high-stakes messages. This is a third routing dimension (mechanical / routine-persona / deep-persona) that plays naturally with the two-clocks model.

**Perplexity — Transcript vs authored analysis boundary.** Sections 1–5 are literal transcript; §6+ is authored synthesis. A future reader could mistake Claude's in-conversation speculation as system truth. Applied: horizontal rule and heading added before §6.

**Perplexity — KV quantization rationale in Mechanical Contract.** Aggressive KV cache quantization (q4_0) trades language nuance for memory savings. This is acceptable *because* the local model doesn't speak directly to the user — its output is structured JSON, not natural language. That tradeoff should be explicit in the contract.

**Grok — Thermal throttling risk.** Sustained inference on M3 Ultra under concurrent load (Ollama + Docker + Obsidian + Crumb) could throttle. No other reviewer flagged this. MEDIUM severity — easy to test, easy to mitigate (fan profiles, session limits), but invisible until you hit it.

**Grok — Effective context vs native context.** 256K native may only be stable to ~100K due to RoPE scaling limits. Doesn't break our 64K target, but the model table shouldn't overstate capability. Caveat applied to model table.

**Grok — Q5_K as intermediate quant option.** ~22GB, ~2-3% accuracy uplift over Q4_K_M per Bartowski GGUF tests. On 96GB shared hardware with the 30B model, that's a near-free improvement. Added to benchmark harness test matrix.

### What Claude (Opus) Pushed Back On (R2)

- **Grok's 85% JSON validity claim for qwen3-coder:30b** (citing "GitHub #4567") could not be independently verified. If accurate, 85% would be concerning for a model whose entire job is deterministic tool calling. Do not anchor on this — validate empirically in the benchmark harness.
- **Grok's suggestion to split the doc now** contradicts the existing (and sound) decision to defer until routing PoC resolves. The decisions may change depending on PoC outcome, and premature extraction creates a maintenance burden.
- **DeepSeek's "Owner: Danny / Tess"** on work items — Tess can't own work items pre-deployment. All pre-PoC work is Danny's.
- **Gemini's "emergency persona"** for API-down fallback is a nice concept but lower priority than getting the named degradation protocol right. Don't over-engineer the fallback before the primary architecture works.

---

## Status & Decisions

### Design Contracts (per ChatGPT R1 reframing)

**Mechanical Contract (Local model must satisfy):**
- Deterministic tool calling with valid JSON output
- Schema adherence across OpenClaw's 40+ tool inventory
- Low latency (target: <5s response for heartbeats/cron tasks)
- High uptime (model stays loaded, no cold starts)
- Stable under 64K context with KV cache quantization
- **Never emits a confirm for destructive operations without the operator's explicit confirmation token** (bridge confirmation echo — system safety invariant, not implementation detail)

*Note on KV cache quantization:* Aggressive quantization (q4_0) trades natural language nuance for memory savings. This is acceptable because the local model's output is structured JSON and tool calls, not user-facing prose. The Persona Contract covers language quality separately.

**Persona Contract (Cloud model must satisfy):**
- Faithful execution of SOUL.md voice, including second register
- Judgment on when to shift tone (operator → precedent mode)
- Safe ambiguity handling — asks for clarification rather than guessing
- Consistent character across multi-day interaction history

### Decisions Made

- **No thinking model for Tess.** Hard blocker (developer role mismatch bug) + architectural mismatch (latency tax on always-on ops). Even if the bug is fixed, the design argument holds.
- **Personality-first tiering: cloud front-line for user-facing, local for mechanical.** The SOUL.md requires frontier-model capability to execute faithfully; the local model handles plumbing only. Routing keyed on *clock source* (human clock vs machine clock), not task complexity — see GPT's R2 contribution.
- **Coder model family for local.** Conditional on the tiering inversion — if we ever revert to local-first, re-evaluate. IF scores are the primary selection metric: higher IF = better schema obedience.
- **Manual config addition** preferred over `ollama launch openclaw` (preserve hardened `openclaw.json` from OC-009).

### Conditional Decisions (gated, not confirmed)

**Primary local model = `qwen3-coder:30b` (Q4_K_M baseline, Q5_K preferred if benchmarks confirm)**
Promote to `qwen3-coder-next` (80B hybrid Mamba-Transformer) only if ALL of:
- Can hold 64K context with target KV cache quantization (q4_0 or q8_0)
- Keeps ≥20GB unified memory headroom under defined load shape (see below) — preliminary estimate: ~23GB (q8_0) / ~26GB (q4_0), borderline
- Sustained throughput ≥20 tok/s for tool-calling workloads
- No instability during concurrent Crumb sessions + Obsidian + Docker
- No >5% performance drop vs. 30B on benchmark harness tasks
- Flash Attention validated in Ollama Metal backend for efficient 64K+ context inference

**Defined load shape for memory gate validation:**
64K context + 10 sequential tool calls + concurrent Obsidian + Docker running + OpenClaw gateway active. Headroom measured under this load, not sterile conditions.

**GLM-4.7-flash = quarantined**
Re-enter consideration only if ALL of:
- Ollama chat template compatibility confirmed on our stack
- Tool calling validated against OpenClaw's tool inventory
- Long-context behavior tested at 64K+

**Cloud persona model = Haiku 4.5 (provisional)**
May need upgrade to Sonnet 4.5 if Haiku can't carry the SOUL.md's second register. Test before committing at scale. Consider mixed tier (Haiku for routine persona, Sonnet for second-register) rather than all-or-nothing upgrade — see Perplexity R2 contribution.

### Persona Evaluation Rubric (pre-test, per DeepSeek + GPT R2)

Before running the Haiku vs Sonnet persona test, define pass criteria using 5–10 representative Telegram interactions that exercise the second register. Minimum evaluation dimensions:
- Second register invoked appropriately (2/3 cases minimum)
- Asks clarifying question when ambiguous rather than guessing
- No generic bot filler (stock phrases, hedging patterns, emoji)
- Dry humor lands in at least 1/3 of appropriate opportunities
- Vault precedent surfaced at the right moment when available
- Tone shift calibrated to context (operator → advisor transition)

### Risk Register

| Risk | Severity | Status | Mitigation |
|------|----------|--------|------------|
| **OpenClaw can't route by task type / agent** | CRITICAL | Unverified | Routing specification (not just PoC) is step 1. Define acceptance criteria: route by audience (human clock vs machine clock), at per-agent or per-channel granularity minimum, with fallback to `tess-voice` + `tess-mechanic` split if native routing insufficient. Test mixed-task delegation (single request spanning both tiers). |
| **Anthropic API down → Tess goes mute** | HIGH | Protocol drafted | **Limited Mode** protocol: after 3 retries on 503/timeout, switch to local model with explicit Telegram banner: "Tess is in limited local mode — responses may be flatter." Scope reduction: captures/triage/status only, no advice voice, no multi-step decisions. Default is "some Tess" rather than silence. Revert automatically on API recovery. |
| **Memory contention on shared 96GB** | MEDIUM | Unvalidated | Build memory budget table with actual measurements under defined load shape. Gate 80B promotion behind empirical validation. Use `OLLAMA_KV_CACHE_TYPE=q4_0` and `OLLAMA_KEEP_ALIVE=-1`. |
| **`openai-completions` vs `openai-responses` hang** | MEDIUM | Anecdotal (single GitHub report; status in current release unknown) | Hard test in integration plan — not lore. Identify which component hangs, reproduce, document. |
| **KV cache silent truncation (`num_ctx` defaults to 2048-4096)** | HIGH | Known bug | Custom Modelfile with explicit `PARAMETER num_ctx 65536`. Do not rely on OpenClaw's `contextWindow` config propagating. |
| **Haiku 4.5 can't carry SOUL.md second register** | MEDIUM | Untested | Test persona fidelity using predefined rubric (see above) before committing. May need Sonnet 4.5 for second-register tier, or mixed Haiku+Sonnet cloud tier, changing cost calculus. |
| **Thermal throttling under sustained concurrent load** | MEDIUM | Unvalidated | Test with sustained inference + concurrent Crumb session + Docker + Obsidian. Mitigate with fan control profiles or session limits if throttling detected. |

### Next Steps (ordered by dependency)

1. **Routing specification.** Define acceptance criteria for OpenClaw routing in one paragraph: what constitutes "route by audience" (human clock vs machine clock), at what granularity (per agent, per channel, per task type), and the minimum viable fallback. Then prove it works. Test cases must include: pure-type routing (heartbeat → local, message → cloud), mixed-task delegation (single request spanning both tiers), and sub-task delegation (cloud agent calling local model as a tool for vault lookup). Investigate per-agent model overrides, separate agent definitions, `tess-voice` / `tess-mechanic` split, or custom routing hooks. From OpenClaw v1.2 docs, `agents.[name].model` works for static assignment, but dynamic task-type routing may need custom plugins or routing hooks (community discussion, unresolved as of Feb 21). This blocks everything else.
2. **Codify the two contracts** as a one-page vault reference doc. This becomes the evaluation framework for any future model swap.
3. **Build the memory budget table** — actual numbers for both 30B (Q4_K_M and Q5_K) and 80B models with target context length and KV cache quantization on the Studio, measured under the defined load shape. Measure: peak RSS, KV cache size at 64K context, model load time, swap usage. Use `htop` and Activity Monitor during benchmarks.
4. **Persona fidelity test.** Send representative Telegram interactions through Haiku 4.5 and Sonnet 4.5 with SOUL.md loaded. Evaluate against predefined rubric (see Persona Evaluation Rubric above). Determine whether Haiku, Sonnet, or a mixed tier is needed.
5. **Local model benchmark harness.** 10 tool-call tasks (including OpenClaw-specific tools: vault writes, bridge echoes, confirmation echo compliance) + 3 long-context tasks on `qwen3-coder:30b` (both Q4_K_M and Q5_K). Record: tool JSON validity rate, median latency, peak unified memory, failure modes, thermal behavior under sustained load. Include bridge confirmation echo test: verify model does not auto-confirm destructive operations.
6. **Document the Limited Mode protocol** as a formal degradation spec: triggers (3 retries on 503/timeout), user notification (Telegram banner), scope reduction (captures/triage/status only), reversion logic (automatic on API recovery).
7. **Draft `openclaw.json` config changes** for the tiered model architecture.
8. **Split this thread** into a stable "Local Model Design Decision" doc (durable: contracts, decisions, conditional gates, risk register) + a "Research Log" (transient: model landscape, community reports, benchmark snapshots). Deferred until routing spec resolves and model benchmarks are in — right now the thread *is* the research log, and the Status section is the proto-decision doc. The decision doc links back to this thread as its evidence base.

### Reference Documents

- `IDENTITY.md` — Tess persona definition
- `SOUL.md` — Core truths, boundaries, voice calibration, response patterns (defines "second register" — backreference here, not repeated)
- `tess-crumb-comparison-user.md` — Role comparison and design philosophy
- `tess-crumb-boundary-reference.md` — Operational routing guide
- `tess-crumb-diagram.jsx` — Interactive architecture diagram (React)
- `tess-crumb-architecture.png` — Architecture overview image
- Previous strategy doc: `Local_LLM_Strategy_UPDATED.md` (Feb 15, 2026)
- Previous integration reference: `openclaw-crumb-final-reference-UPDATED.md` (Feb 15, 2026)
- Ollama Feb 2026 release notes (for `ollama launch openclaw`)
