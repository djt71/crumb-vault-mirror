---
type: knowledge-note
domain: software
status: active
project: pydantic-ai-adoption
skill_origin: researcher
created: 2026-03-15
updated: 2026-03-15
tags:
  - kb/software-dev
  - kb/software-dev/architecture
topics:
  - moc-crumb-architecture
source:
  source_id: pydantic-ai-analysis-v1-68
  title: "Pydantic AI: Full Platform Analysis (v1.68.0)"
  source_type: other
  date_ingested: 2026-03-15
note_type: digest
scope: whole
---

# Pydantic AI: Full Platform Analysis

**Context:** Evaluation of Pydantic AI as a potential component-level adoption candidate for the Crumb/Tess ecosystem. This is not an adoption recommendation — it's a map of the territory to inform future decisions.

**Version reviewed:** Pydantic AI v1.68.0, released March 13, 2026. V2 expected April 2026.
**Sources reviewed March 15, 2026:**
- Primary docs: ai.pydantic.dev (multi-agent patterns, graph overview, durable execution, A2A, MCP overview, evals overview, models overview)
- GitHub: pydantic/pydantic-ai — 15.4k stars, 1.7k forks, 160 contributors, 418 open issues, PR numbers in #4500-4600 range
- PyPI: pydantic-ai 1.68.0 package metadata
- Version policy: ai.pydantic.dev/version-policy/ — V1 stability since Sept 2025, V2 April 2026 earliest, 6-month V1 security fix commitment post-V2
- Upgrade guide: ai.pydantic.dev/changelog/ — breaking change history across V1 releases
- Community: DEV Community tutorials, GitHub issues for multi-agent patterns

---

## 1. What Pydantic AI Actually Is

Pydantic AI is a Python agent framework built by the Pydantic team (the same people behind the validation layer used by OpenAI's SDK, Anthropic's SDK, LangChain, LlamaIndex, CrewAI, and others). Their pitch is explicit: "Why use the derivative when you can go straight to the source?"

It's not just an agent framework — it's a *platform* comprising four independently usable packages:

| Package | Purpose | Standalone? |
|---------|---------|-------------|
| `pydantic-ai` | Agent framework (core) | Yes |
| `pydantic-graph` | Typed finite state machine library | Yes — no dependency on pydantic-ai |
| `pydantic-evals` | Evaluation/testing framework for AI systems | Yes |
| `fasta2a` | Agent2Agent protocol server (built on Starlette) | Yes — framework-agnostic |

This modular packaging is important in principle — you can use `pydantic-evals` to test agents built with any framework, and `pydantic-graph` has no dependency on `pydantic-ai`. However, the runtime independence is weaker than the packaging suggests: `pip install pydantic-evals` pulls in `pydantic-ai-slim`, `pydantic-graph`, `logfire-api`, `opentelemetry-api`, and 20+ other packages (verified March 15, 2026). The components are usable independently but not installable independently — the dependency tree is shared.

---

## 2. Core Architecture: The Agent Model

An agent in Pydantic AI is defined by:

- **Model:** Provider-agnostic. Supports OpenAI, Anthropic, Google, xAI, Bedrock, Cerebras, Cohere, Groq, Hugging Face, Mistral, OpenRouter, and Outlines (for local models). Different agents in the same system can use different models.
- **Dependencies (`deps_type`):** Typed dependency injection. Dependencies are dataclasses or Pydantic models passed into agent runs, available to all tools via `RunContext`.
- **Tools:** Functions decorated with `@agent.tool` that receive `RunContext` (with typed deps and usage tracking). Tool parameter descriptions are extracted from docstrings automatically.
- **Output type:** Pydantic-validated structured output. Union types are supported — each union member becomes a separate output tool, so the model can signal different outcomes (e.g., `FlightDetails | Failed`).
- **Instructions:** System prompts, either static or dynamic (computed at runtime from deps/context).

Key design decisions:

- **Agents are stateless and designed to be global.** You define them at module level, not per-request. State lives in deps and message history, not in the agent object.
- **Message history is explicit.** You pass `message_history` between runs to maintain conversation continuity. No hidden state.
- **Usage tracking is first-class.** `UsageLimits` (request_limit, total_tokens_limit, tool_calls_limit) are mechanical kill-switches, not soft guidelines.

### What This Means for Crumb/Tess

The stateless-global-agent pattern maps cleanly to how Crumb sessions already work: each session instantiates a context, the agent definition is stable, and state flows through the session context rather than living inside the agent. The explicit message history management is analogous to what you'd need for Project Notebooks — carrying conversation context across interactions without relying on hidden state.

---

## 3. Multi-Agent Patterns (Five Levels)

Pydantic AI defines a clean hierarchy of multi-agent complexity:

### Level 1: Single Agent
Standard single-agent workflows. Most of the framework documentation covers this.

### Level 2: Agent Delegation
One agent calls another agent *inside a tool function*, then takes back control when the delegate finishes. This is the most compositional pattern — delegate agents are just regular agents invoked as function calls.

Key mechanics:
- Usage from the delegate propagates to the parent via `ctx.usage`
- Delegate agents can use different models than the parent
- Dependencies can be shared (same `deps_type`) or the delegate can have a subset
- UsageLimits on the parent apply globally, preventing runaway delegation chains

**Crumb/Tess mapping:** This is the within-session delegation pattern. If Crumb needs to spin up a sub-agent for a focused task (structured extraction, review pass, domain-specific analysis), delegation gives you typed contracts on input/output with automatic cost tracking. Your current Tess→Crumb relationship is *not* this pattern — it's asynchronous and loosely coupled, which is correct for your use case.

### Level 3: Programmatic Hand-Off
Multiple agents called in succession, with application code or a human deciding what runs next. Agents don't share deps. Message history can optionally flow between agents.

**Crumb/Tess mapping:** This is your multi-model peer review gauntlet. You route an artifact through Claude, Gemini, DeepSeek, ChatGPT, and Perplexity with application-level control over sequencing. Pydantic AI's programmatic hand-off would formalize this with shared `RunUsage` tracking across the whole pipeline.

### Level 4: Graph-Based Control Flow (pydantic-graph)
A typed finite state machine for complex workflows. Nodes are dataclasses with a `run` method that returns the next node type (enforced by return type annotations). The graph validates edges at construction time using type hints.

Features:
- **State persistence:** State is recorded after each node run, enabling pause/resume
- **Human-in-the-loop:** Graphs can be iterated manually (`GraphRun.next(node)`) for approval gates
- **Dependency injection:** Graph-level deps available to all nodes
- **Mermaid diagram generation:** Automatic visualization from the graph definition

The docs are refreshingly honest here: *"Don't use a nail gun unless you need a nail gun."* They explicitly warn against reaching for graphs when simpler patterns suffice.

**Crumb/Tess mapping:** Your overnight batch review workflow (review → apply must-change/should-change → commit per file → summary for review) is exactly the kind of multi-step process with approval gates that `pydantic-graph` was built for. The state persistence would let the workflow survive crashes and restarts — currently handled by your LaunchDaemon + healthchecks.io infrastructure. The question is whether moving that resilience from the infrastructure layer to the framework layer gains you anything. It might, if the graph also gives you typed state transitions and automatic Mermaid visualization of your workflows for documentation.

### Level 5: Deep Agents
Autonomous agents combining planning, file operations, task delegation, sandboxed code execution, context management (conversation summarization for long sessions), and durable execution. Pydantic AI provides the building blocks but doesn't prescribe composition — community packages like `pydantic-deep` fill that gap.

**Crumb/Tess mapping:** This is essentially what you've built. Crumb is a deep agent. The difference is you composed your own building blocks rather than using theirs.

---

## 4. MCP Integration (Model Context Protocol)

Pydantic AI supports MCP as both client and server in three ways:

1. **Native MCP client:** Connects directly to local and remote MCP servers
2. **FastMCP client:** Uses the FastMCP library for broader compatibility
3. **Built-in MCP tool:** Some model providers can connect to MCP servers directly

Agents can also *be* MCP servers, exposing their capabilities to other MCP clients.

**Crumb/Tess mapping:** This is a strong adoption candidate *in principle*. Your tess-operations infrastructure (gws CLI for Google, TCC grants for Apple, Discord bots) is a collection of bespoke service integrations. As MCP servers proliferate for these services, swapping bespoke integrations for MCP-based ones would reduce your maintenance surface. However: the MCP feasibility research brief (evaluating whether quality MCP servers actually exist for Google Workspace, Apple, and Discord) has been scoped but not executed. The "MCP is winning" thesis is widely held but the server ecosystem for these specific services is unverified. Also note: Pydantic AI's MCP client is one option — FastMCP standalone is a viable alternative that doesn't require adopting any Pydantic AI dependency.

---

## 5. Agent2Agent (A2A) Protocol

Pydantic AI includes `fasta2a`, a framework-agnostic A2A server implementation built on Starlette. A2A is Google's open standard for inter-agent communication.

The architecture is clean:
- **TaskManager** coordinates
- **Broker** queues and schedules tasks
- **Worker** executes tasks
- **Storage** persists tasks and conversation context

You bring your own Storage, Broker, and Worker implementations. The protocol handles conversation threading via `context_id` — multiple tasks can share a conversation context.

Exposing a Pydantic AI agent as an A2A server is trivial: `app = agent.to_a2a()`.

**Crumb/Tess mapping:** This is a future-facing capability. If A2A gains traction as the standard for inter-agent communication, having your agents A2A-compatible means they could interoperate with agents built on other frameworks. Not immediately useful, but worth noting as the Tess two-agent split (voice on Haiku, mechanic on local qwen3-coder) could eventually benefit from a standardized communication protocol rather than the current file-based queue system.

---

## 6. Durable Execution

Pydantic AI integrates with three durable execution systems:
- **Temporal** (workflow orchestration)
- **DBOS** (database-backed execution)
- **Prefect** (data pipeline orchestration)

These are not custom implementations — they use Pydantic AI's public interface, so they also serve as reference implementations for integrating with other durable systems.

The value proposition: agents that survive API failures, application crashes, and restarts without losing progress. Full support for streaming and MCP.

**Crumb/Tess mapping:** Your current durability comes from the LaunchDaemon infrastructure + healthchecks.io monitoring + the file-based queue system. Pydantic AI's durable execution would move that resilience into the agent execution layer itself. Whether this is better depends on your failure modes — if most failures are transient API issues (model provider timeouts, rate limits), framework-level durability is probably cleaner than infrastructure-level restart-and-retry. If failures are more systemic (machine restarts, daemon crashes), your current approach is more appropriate.

---

## 7. Pydantic Evals

A code-first evaluation framework for systematically testing AI systems. Design philosophy from the docs: *"Anyone who claims to know exactly how your evals should be defined can safely be ignored."*

Components:
- **Datasets:** Collections of test cases with inputs, expected outputs, and metadata
- **Evaluators:** Built-in (exact match, instance checks), LLM-as-judge, custom, span-based (evaluating tool calls and execution flow via OpenTelemetry traces), and report-level
- **Experiments:** Runs of datasets through your system with evaluation
- **Integration:** Results viewable in terminal, saved to disk, or displayed in Logfire

Span-based evaluation is the standout feature: you can assert not just on *what* the agent produced, but *how* it got there — which tools were called, in what order, with what parameters.

**Crumb/Tess mapping:** This is potentially high-value, though not as independent as the packaging suggests (see §1 — installing pydantic-evals pulls in the full pydantic-ai-slim dependency tree). Your current testing approach for Crumb is milestone-based (soak gates, retrospective gates). Pydantic Evals could formalize the "did the agent behave correctly" question with reproducible test cases. The span-based evaluation is especially relevant for the autonomous-operations work where you need to verify not just the outcome but the decision path (e.g., did the idempotency predicate fire correctly?). **Caveat:** Span-based evaluation requires OTel instrumentation of the execution context. Whether Claude Code tool calls produce OTel-compatible spans is unverified — this needs a spike before committing to span-based evals as the primary value proposition.

---

## 8. Model Support and Local Model Compatibility

Supported providers: OpenAI, Anthropic, Google, xAI, Bedrock, Cerebras, Cohere, Groq, Hugging Face, Mistral, OpenRouter, and Outlines.

The **Outlines** integration is the local-model story. Outlines provides structured generation for local models, and Pydantic AI wraps it as a model provider. For models served via OpenAI-compatible APIs (like vLLM, which you'd use for qwen3-coder:30b), the OpenAI provider works directly by pointing it at your local endpoint.

The **fallback model** feature allows chaining providers: if the primary model fails, it falls back to the next. Per-model settings can be customized for each fallback.

**Crumb/Tess mapping:** Your tess-mechanic on local qwen3-coder:30b via Ollama would likely work through the OpenAI-compatible interface (Ollama exposes an OpenAI-compatible API). The fallback model feature could formalize what you'd do if the local model is unavailable — fall back to a cloud model. Not critical, but a nice-to-have.

---

## 9. Observability (Logfire)

Pydantic Logfire is their observability platform, built on OpenTelemetry. For multi-agent systems, it provides:
- Which agent handled which part of a request
- Delegation decisions (when and why one agent called another)
- End-to-end latency broken down by agent
- Token usage and costs per agent
- What happened inside tool calls (database queries, HTTP requests, etc.)

Since it's OTel-based, you can use any OTel-compatible backend if you don't want Logfire specifically.

**Crumb/Tess mapping:** Your Mission Control dashboard (crumbos.dev) is your observability layer. If you adopted Pydantic AI components, the OTel instrumentation would give you structured telemetry data that could feed into Mission Control, potentially replacing some of the bespoke monitoring you've built.

---

## 10. Assessment: Component-Level Adoption Candidates

Applying the framework we discussed — adopt commodity layers, keep differentiating layers bespoke — here's how the components stack-rank for your ecosystem:

### High Relevance (clear use case, reduces maintenance)

**Pydantic Evals** — Independent of the agent framework. Could formalize your testing approach for autonomous-operations and other Crumb subsystems. Span-based evaluation is directly applicable to verifying agent behavior. Low adoption cost, high diagnostic value.

**MCP Client** — As MCP servers mature for Google, Apple, and Discord services, replacing bespoke integrations with MCP-based ones reduces your maintenance burden. The Pydantic AI MCP client is well-designed, but you could also use FastMCP directly without adopting Pydantic AI.

**UsageLimits / Structured Output Validation** — Mechanical enforcement of token/request/tool-call budgets on agent runs. Typed, validated structured outputs. These are commodity problems you may be solving with hand-rolled validation — but the actual maintenance burden of existing code has not been measured. If hand-rolled solutions are stable and low-maintenance, the adoption cost (25-package dependency tree, learning curve, version coupling) may exceed the savings. Measure before adopting.

### Medium Relevance (useful in specific scenarios)

**Agent Delegation** — For within-session sub-agent patterns. Not a replacement for Tess→Crumb async orchestration, but useful if Crumb needs to spin up specialized sub-agents during a session. Worth a spike when the need arises.

**pydantic-graph** — For structured, multi-step workflows with approval gates (overnight batch reviews, deployment pipelines). The typed state transitions and Mermaid visualization are nice. But your current hand-rolled workflows work, so the adoption trigger is "next time I need to build a new multi-step workflow, evaluate whether pydantic-graph earns its keep vs. hand-rolling."

**Durable Execution (Temporal/DBOS/Prefect)** — For long-running agent tasks that need to survive failures. Depends on whether your failure modes are transient (API issues → framework-level durability helps) or systemic (daemon crashes → infrastructure-level durability is better).

### Low Relevance (interesting but premature)

**A2A Protocol** — Future-facing. Worth watching as the protocol matures, but no immediate use case unless you need Tess agents to interoperate with external agent systems.

**Logfire** — You have Mission Control. Adding another observability platform creates more surface area, not less. The OTel instrumentation is the valuable piece; the observability *platform* is not.

**Deep Agents / Graph-Based Orchestration** — You've already built your deep agent. Rewriting it on Pydantic AI's primitives would be a lateral move, not an upgrade.

---

## 11. What's Missing / Caveats

Things to be eyes-open about:

**Relative youth.** Pydantic AI is younger than LangGraph and CrewAI in terms of community and battle-testing. The Pydantic team has serious engineering credibility, but the agent framework specifically hasn't been through as many production cycles.

**Logfire coupling.** The observability story leans heavily on their own commercial product. The OTel escape hatch is real, but the documentation and examples are Logfire-first. If you adopt and later want to switch observability, the instrumentation code is standard OTel, but you'll be swimming against the current of the documentation.

**Synchronous delegation.** Agent delegation is synchronous — the parent blocks until the delegate returns. Your Tess→Crumb architecture is fundamentally asynchronous (fire-and-forget via file queues, results delivered via Telegram). Pydantic AI's delegation model doesn't address this async orchestration pattern at all.

**No vault/knowledge-base primitive.** Pydantic AI has no analog to your Obsidian vault as shared memory. Their agents are stateless with explicit message passing. Vault-as-memory is a differentiating pattern that no framework provides.

**Graph API is still evolving.** The Beta API for pydantic-graph (steps, joins, reducers, decisions, parallel execution) is explicitly marked as beta. Core graph functionality is stable, but the ergonomic improvements are still in flux.

---

## 12. Bottom Line

Pydantic AI is one of the most architecturally sound agent frameworks available. The design philosophy — type safety, composability, mechanical enforcement, honest documentation — aligns unusually well with how you build systems. (This assessment is based on deep evaluation of Pydantic AI specifically, not a systematic comparison against LangGraph, CrewAI, or other frameworks. The superlative reflects architectural alignment with Crumb/Tess principles, not a comprehensive market survey.)

But the adoption question isn't "is it good" — it's "does it earn its ceremony budget." The answer, component by component:

- **Pydantic Evals:** Strongest candidate, but not as independent as it appears. Installing pydantic-evals pulls in pydantic-ai-slim, pydantic-graph, logfire-api, and 22 other packages. The value proposition (span-based evaluation of agent decision paths) is real and has no direct pytest equivalent — but the dependency footprint is substantial. Verify OTel compatibility with your execution context before committing. Wait for V2 (expected April 2026) if timing allows.
- **MCP Client:** Yes, as MCP servers mature — but evaluate FastMCP standalone as an alternative that doesn't require Pydantic AI adoption.
- **UsageLimits / Output Validation:** Promising commodity candidates, contingent on measured maintenance burden of existing code. If hand-rolled solutions are stable, the adoption cost may exceed the savings.
- **Everything else:** Wait for a concrete trigger. Don't adopt preemptively.

The Ceremony Budget Principle remains the right lens: each component earns its place when the maintenance cost of the bespoke alternative exceeds the adoption cost of the framework component. Evaluate per-component, not per-framework.
