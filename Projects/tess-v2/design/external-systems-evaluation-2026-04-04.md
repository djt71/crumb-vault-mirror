---
project: tess-v2
type: design-input
domain: software
skill_origin: inbox-processor
created: 2026-04-04
updated: 2026-04-04
tags:
  - orchestration
  - external-systems
  - architecture
---

# Session Summary: External Systems Evaluation & Tess-v2/Crumb Mapping

**Date:** April 4, 2026
**Scope:** Evaluated 10 external systems/concepts against the Crumb/Tess-v2 architecture. Identified converging patterns, gaps, and proposed solutions.
**Downstream:** This evaluation directly prompted Amendment Z (Interactive Dispatch & Orchestrator Authority). See `design/spec-amendment-Z-interactive-dispatch.md`.
**Related:** `design/services-vs-roles-analysis.md` (Paperclip evaluation, 2026-03-31 — same hierarchy, sub-orchestrator extension). `design/pedro-autopilot-extraction-2026-04-04.md` (6 patterns mapped to Z).

---

## Systems Evaluated

| # | System | Source | Category |
|---|--------|--------|----------|
| 1 | MiroFish | 666ghj/MiroFish | Multi-agent simulation engine |
| 2 | LangSmith Trace Loop | LangChain conceptual guide | Agent observability & improvement |
| 3 | Slate V1 (Thread Weaving) | Random Labs / YC S24 | Swarm-native coding agent |
| 4 | Karpathy's Wiki Pattern | Andrej Karpathy (X post) | LLM-maintained knowledge base |
| 5 | Cabinet | runcabinet.com | AI-first knowledge base / startup OS |
| 6 | Swarm Wiki (X poster) | @gkisokay community | Multi-agent wiki with Hermes review gate |
| 7 | Pedro's Autopilot | Pedro Franchesci (Brex CEO) | Personal CEO agent system |
| 8 | Subconscious Agent | @gkisokay guide | Self-improving agent loop |
| 9 | Gkisokay Model Stack | @gkisokay | 5-model, 4-role LLM layering |
| 10 | Compound Engineering Plugin | EveryInc/compound-engineering-plugin | Software engineering workflow tool |

---

## Feature Mapping: External Systems → Tess-v2 / Crumb

| Feature / Pattern | External System(s) | Tess-v2 / Crumb Equivalent | Status |
|---|---|---|---|
| **Markdown-on-disk as shared memory** | Karpathy, Cabinet, Swarm Wiki, Subconscious | Obsidian vault (~1,400 files, 8 domains) | ✅ Implemented |
| **Separate orchestrator from executor** | Slate, Swarm Wiki, Pedro, Gkisokay stack | Kimi K2.5 (orchestrator) + Nemotron (executor) | ✅ Implemented |
| **Quality gate before knowledge persists** | Swarm Wiki (Hermes gate), Subconscious (approval gate) | Staging → promotion, Ralph loops, confidence tiers | ✅ Implemented |
| **Scheduled compounding loops** | Pedro (autopilot), Subconscious (cron), Swarm Wiki (compiler) | LaunchAgent services (FIF, Attention Manager, etc.) | ✅ Implemented |
| **Structured outcome logging** | LangSmith (traces), Subconscious (artifact writers) | run_history SQLite table (just built by Crumb) | ✅ Implemented |
| **Native tool calling / structured output** | Gemma 4, Qwen 3.6-Plus | Contract runner typed check validation | ✅ Implemented |
| **Compound engineering / self-improvement** | Subconscious Agent, Compound Engineering Plugin | Compound reflections at phase transitions, solutions/ docs | ✅ Implemented |
| **Peer review / adversarial challenge** | Subconscious (debate/critique), Plugin (adversarial reviewer) | Peer review gauntlet (multi-LLM), code-review skill | ✅ Implemented |
| **Per-agent briefings from live KB** | Swarm Wiki (wiki/briefings/), Pedro (program summaries) | AKM session-start serendipity engine | ✅ Partial — serves different purpose (surprising connections vs. operational context) |
| **Signal injection pipeline** | Pedro (screens email, Slack, Docs, WhatsApp) | Feed Intel Framework (X, RSS adapters) | ✅ Partial — FIF covers feeds, not personal comms. TV2-036 (email triage) extends into personal comms. |
| **People + Programs declarative context** | Pedro (25 people, named programs) | Contract-based service definitions | ⚠️ Gap — services defined, but no higher-level declarative priority filter |
| **Plan-before-execute enforcement** | Slate (kernel dispatches bounded workers), LangSmith (trace decisions) | Amendment Y (just filed): two-turn harness, plan schema | ✅ Just addressed |
| **Episodic summaries for context reconstruction** | Slate (Thread Weaving episodes), LangSmith (enriched traces) | project-state.yaml + next_action field | ~~⚠️ Gap~~ **Superseded by Amendment Z** — session report schema (Z2) and interactive dispatch queue (Z1) replace next_action as the machine-readable state transfer mechanism. next_action remains as human-readable summary. |
| **Automated cluster analysis of failures** | LangSmith (Insights Agent), Compound Plugin (#480) | Manual via compound reflection | ⚠️ Gap — deferred, implement when run_history has enough data. Amendment Z adds session reports as second data source. |
| **Track-based learning schema** | Compound Plugin (bug vs. knowledge tracks) | Freeform solutions/ docs | ⚠️ Gap — low-effort improvement, deferred by choice |
| **Cross-model code review** | Gkisokay stack (Codex + Claude Code), Pedro (Crab Trap) | Single-executor model (Nemotron or Claude Code) | ⚠️ Gap — **trigger updated:** Claude Code plugin for Codex and subscription token tooling exist now. Not blocked on API access; blocked on experiment decision. |
| **Crab Trap (policy proxy)** | Pedro (HTTP proxy with adversarial LLM) | Not implemented | ⚠️ Gap — needed when Tess runs unsupervised on external actions |
| **Conditional reviewer routing** | Compound Plugin (diff-aware persona dispatch) | Fixed two-reviewer panel | ⚠️ Gap — **trigger updated:** Codex integration more accessible than assumed. Feasible sooner; still deferred until review noise/cost becomes a pain point. |
| **Auto-compiler for wiki indexing** | Karpathy (LLM auto-maintains index), Swarm Wiki (wiki-compile.py) | Human-curated vault organization + QMD/AKM | ⚠️ Gap — potential Tess scheduled contract |
| **Embedded HTML apps in KB** | Cabinet (index.html renders inline) | Separate crumbos.dev for Mission Control | 🔵 Not needed — current approach works |
| **Multi-agent social simulation** | MiroFish / OASIS | N/A | 🔵 Different category — potential marketing test tool |

---

## Five Converging Patterns (Identified Across All Systems)

Every system evaluated independently converges on these same architectural primitives:

| Pattern | Evidence |
|---|---|
| **1. Separate strategy from execution** | Slate (kernel vs. workers), Pedro (autopilot vs. agents), Gkisokay (judgment model vs. execution model), Tess (Kimi vs. Nemotron) |
| **2. Episodic memory over raw transcripts** | Slate (Thread Weaving), LangSmith (enriched traces), Subconscious (artifact writers), Tess (compound reflections + run_history) |
| **3. Right model for the job** | Gkisokay (5 models, 4 roles), Pedro (OpenClaw + multiple models), Gemma 4 + Qwen 3.6 releases, Tess (cloud/local split) |
| **4. Structured observability as improvement primitive** | LangSmith (traces), Subconscious (persistent state), Pedro (signal injection), Tess (run_history SQLite, just built) |
| **5. Mechanical enforcement over behavioral instructions** | LangSmith (evals), Subconscious (guardrails), Pedro (Crab Trap), Tess (contract runner, Ralph loops, Amendment Y) |

---

## Model Landscape Update (April 2, 2026)

| Model | Key Specs | Relevance to Tess |
|---|---|---|
| **Gemma 4 26B MoE** | 3.8B active params, Apache 2.0, native tool calling, 256K context | Benchmarked (TV2-046): NO SWITCH. Ties tool-call, loses throughput at 64K+. |
| **Gemma 4 31B Dense** | Fits on 96GB unified memory unquantized, #3 open models on Arena | Benchmarked (TV2-046): NO SWITCH. Tool-call 0.8, throughput 2-4x slower. |
| **Qwen 3.6-Plus** | 1M context, beats Claude 4.5 Opus on Terminal-Bench 2.0, free preview | Designated cloud orchestrator backup (AD-011 upgrade). Scored 74 vs Kimi's 76 |
| **GLM-5** | Strong benchmarks but fabricated output in TC-04 eval | ❌ Disqualified — same fabrication pattern as DeepSeek V3.2 |
| **MiniMax M2.7** | $0.30/$1.20, 97% skill adherence, 1495 ELO | Untested — worth pulling through TV2-Cloud battery |

---

## Actions Taken This Session

| Action                            | Status             | Detail                                                                               |
| --------------------------------- | ------------------ | ------------------------------------------------------------------------------------ |
| run_history SQLite table          | ✅ Built & deployed | 195 lines, 21 tests, zero new deps. All 5 LaunchAgent services now recording.        |
| `tess history` CLI subcommand     | ✅ Built & deployed | Filters by service, outcome, time range. `--summary` for gate decisions.             |
| Amendment Y (plan-before-execute) | ✅ Filed & pushed   | Y1: Layer 1 directive, Y2: two-turn dispatch, Y3: planning-specific Layer 2          |
| Cloud orchestrator re-eval        | ✅ Complete         | Kimi 76, Qwen 3.6+ 74, GLM-5 66 (disqualified). Kimi holds seat.                     |
| Hermes PR #4467 outcome           | ✅ Resolved         | Closed without merge; fix cherry-picked via #4645 by another contributor.            |
| Compound engineering plugin eval  | ✅ Evaluated        | Keep building own, cherry-pick patterns. Three enhancements identified, implemented. |

---

## Proposed Next Actions (Sequenced)

| Priority | Action | Trigger | Effort | Annotations |
|---|---|---|---|---|
| **Now** | Use `tess history --summary --since 48` for April 3 gate decision | Gate deadline | Zero — already built | |
| ~~**Phase 4**~~ | ~~Make project-state.yaml + next_action more machine-readable~~ | ~~Context reconstruction tax~~ | ~~~2 hours~~ | **Superseded by Amendment Z.** Session report (Z2) and dispatch queue (Z1) replace next_action as machine interface. |
| **Phase 4** | Benchmark MiniMax M2.7 via TV2-Cloud battery | Untested model with strong agent benchmarks | Half-day | |
| **Phase 4+** | Implement Crab Trap policy proxy | When Tess runs unsupervised on external-facing contracts | ~1 day | |
| **Phase 4+** | Add Codex as secondary executor behind contract runner | ~~When Codex API access drops~~ **Experiment decision** — Claude Code plugin for Codex and subscription token tooling exist now | ~1 day | **Trigger lowered.** |
| **Phase 4+** | Cross-model code review (Codex produces, Claude reviews or vice versa) | ~~After Codex executor is wired in~~ **Experiment decision** — integration paths exist | Design exploration | **Trigger lowered.** |
| **Phase 4+** | Conditional reviewer routing in code-review skill | ~~When review noise/cost becomes a pain point~~ **Experiment decision** — Codex integration more accessible | Half-day | **Trigger lowered.** |
| **Phase 4+** | Automated cluster analysis over run_history | When enough structured run data exists to make it meaningful | Half-day | Amendment Z adds session reports as second data source. |
| **Phase 4+** | Auto-compiler Tess contract for vault re-indexing | When vault growth exceeds manual curation capacity | Design exploration | |
| **Deferred** | Track-based schema for solutions/ docs | When freeform solutions become hard to search | ~30 min | |
