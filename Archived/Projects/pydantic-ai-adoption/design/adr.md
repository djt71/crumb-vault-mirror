---
type: adr
domain: software
status: active
project: pydantic-ai-adoption
skill_origin: researcher
created: 2026-03-15
updated: 2026-03-15
---

# Crumb/Tess Infrastructure Evolution: Architecture Decision Record

**Date:** March 15, 2026
**Status:** Partial decision — see confidence levels below
**Context:** Synthesis of three converging research threads: AI agent orchestration framework evaluation, Pydantic AI deep analysis (v1.68.0), and Cloudflare burst compute/multi-agent scaling exploration.
**Review source:** Pydantic AI documentation at ai.pydantic.dev, fetched March 15, 2026, reflecting v1.68.0 (released March 13, 2026). GitHub repository (pydantic/pydantic-ai): 15.4k stars, 1.7k forks, 160 contributors, ~4,600 PRs. V1 API stability commitment since September 2025.
**Related artifacts:**
- `pydantic-ai-analysis.md` — Full Pydantic AI platform analysis (v1.68.0)
- `cloud-agent-infra-landscape-2026q1` — Cloud agent infrastructure landscape research (completed)
- `brief-cloudflare-sandbox` — Cloudflare Sandbox SDK research brief (questions defined, research not executed)
- `brief-mcp-feasibility` — MCP adoption feasibility research brief (questions defined, research not executed)
- Distributed Agent Experiment design sketch (draft, dependent on unexecuted briefs)

---

## Part 1: Decided (High Confidence)

These decisions are grounded in direct evaluation of the framework, honest assessment of current architecture, and alignment with established design principles.

### 1.1 Local Core Preservation

Everything that makes Crumb/Tess unique stays exactly where it is:

- **Tess** as always-on orchestrator (LaunchDaemon on Mac Studio M3 Ultra)
- **Crumb** (Claude Code) as session-based deep work executor
- **Obsidian vault** (~1,400 files, 8 life domains) as shared memory
- **Telegram** as delivery channel
- **Ceremony Budget Principle** as the governance framework
- **Overnight batch workflows**, soak gates, retrospective gates
- **Two-agent split** (tess-voice on Haiku 4.5, tess-mechanic on local qwen3-coder:30b)
- **Mission Control dashboard** (crumbos.dev via Cloudflare Tunnel)
- **healthchecks.io** for external monitoring

No framework provides vault-as-memory, ceremony budgets, or the specific orchestration logic that governs Crumb/Tess. These are differentiating, not commodity. They stay bespoke.

### 1.2 Pydantic AI: Library, Not Framework

Pydantic AI is adopted as a library of maintained components, not as an agent framework. The distinction is load-bearing: we use components that reduce maintenance without buying into orchestration opinions or runtime ownership.

**What Pydantic AI is in this architecture:** The typed plumbing layer between application logic and model APIs. It handles structured I/O, validation, tool routing, retry logic, usage tracking, and output contracts.

**What it does not own:** Control flow, orchestration, state management, agent lifecycle. Tess and Crumb continue to own all of that.

**What runs on top of it:** Claude Code (Crumb) remains the primary execution environment. Pydantic AI components are generally imported as a library within that context, not adopted as a runtime. This is analogous to adopting `httpx` or `pydantic` itself. **Exception:** Pydantic Evals runs as a standalone Python process outside Claude Code for reproducibility and independence from session state (see specification §3.3). This is specific to the testing use case and does not set precedent for other components.

### 1.3 Component-Level Adoption Posture

Each Pydantic AI component earns its place independently under the Ceremony Budget Principle. Adoption has ceremony too — new dependency, learning curve, integration work — so each component must demonstrably reduce more maintenance than it introduces.

**Components to evaluate (in priority order):**

| Component | What It Would Replace | Adoption Trigger | Current Confidence |
|-----------|----------------------|------------------|--------------------|
| **Pydantic Evals** | Ad-hoc testing of agent behavior | See §1.5 below | High — clear gap, but dependency footprint higher than expected (see §1.5) |
| **UsageLimits** | Hand-rolled token/request budgets | Next agent work needing cost control | Medium — need to measure actual maintenance burden of existing code first (see §1.6) |
| **Structured Output Validation** | Hand-rolled response validation | Next agent work needing typed output | Medium — same caveat as above |
| **MCP Client** | Bespoke per-service integrations | See Part 2 (Directional) | Low — dependent on MCP server maturity |
| **Agent Delegation** | N/A (new capability) | When within-session sub-agents are needed | Low — no current use case |
| **Durable Execution** | Hand-rolled retry/crash-recovery | When transient API failures recur | Low — current infrastructure-level approach works |

**Components explicitly not adopted:**

- **Pydantic AI's orchestration patterns** — Tess owns orchestration
- **Multi-agent coordination** — our architecture is deliberately async and loosely coupled; their delegation model is synchronous
- **Logfire** — we have Mission Control; OTel instrumentation from Pydantic AI could potentially feed into Mission Control, but Logfire itself adds surface area
- **pydantic-graph** — evaluate only if a new multi-step workflow justifies the dependency

### 1.4 Alternatives Considered

Pydantic AI was evaluated in depth as the primary component source; individual alternatives were identified but not comparatively evaluated. The selection rationale is ecosystem coherence — shared type system, unified dependency tree, consistent API patterns across components — not best-in-class standing for any individual component.

Known alternatives by component:

| Component | Standalone Alternative | Tradeoff vs. Pydantic AI |
|-----------|----------------------|--------------------------|
| **Evals** | `pytest` + custom assertions; promptfoo (Node.js); DeepEval | pytest lacks span-based evaluation without significant custom work. promptfoo is mature but Node.js-native. DeepEval is Python-native with pytest integration but less type-safety emphasis. |
| **MCP Client** | FastMCP standalone; Anthropic MCP SDK | FastMCP is the lightest path to MCP — no agent framework dependency. Pydantic AI actually wraps FastMCP as `FastMCPToolset`, so the underlying implementation is the same. Anthropic SDK is lower-level. |
| **Structured Output** | Raw Pydantic (`model_validate`); Instructor | Raw Pydantic is one line of code if you're calling model APIs yourself. Instructor is purpose-built for structured LLM output extraction. Both are lighter than adopting pydantic-ai for this alone. |
| **UsageLimits** | Hand-rolled counters | If current counters are low-maintenance (§1.6 measurement pending), the adoption cost may exceed savings. |
| **Burst compute** (directional) | Modal (Python-native serverless, seconds-not-minutes cold start); Fly.io; parallel Claude Code sessions | Modal deserves evaluation — lower ceremony for Python workloads than Cloudflare Sandbox, no Dockerfile required. |

**Adoption checkpoint:** For any component where adoption is triggered, spend 30 minutes confirming the ecosystem benefit outweighs the capability gap of the standalone alternative for that specific case. The ecosystem posture is a default, not a mandate.

### 1.5 Pydantic Evals as First Adoption Target

Pydantic Evals addresses a real gap (formalized testing of agent behavior, not just outcomes) and is the most directly useful component. However, it is not as independent as initially assessed.

**Dependency reality:** `pip install pydantic-evals` (verified March 15, 2026 in isolated venv) installs 25 packages, including `pydantic-ai-slim` (the core agent framework), `pydantic-graph`, `logfire-api`, `opentelemetry-api`, `httpx`, and `genai-prices`. This is not a lightweight standalone test library — it pulls in the full Pydantic AI ecosystem minus model-specific provider packages. The adoption cost is higher than "add a test framework"; it's "add the Pydantic AI dependency tree to get the test framework."

This doesn't invalidate the recommendation — the eval capabilities are real — but the cost calculus should reflect the actual footprint, not the aspirational independence.

**Scope definition:** The initial target is autonomous-operations decision path verification. Specifically:

- Test cases for the idempotency predicate logic (the class of bug ChatGPT surfaced in AO-004)
- Test cases for the signal assembly tiered approach (tags guaranteed, domain concepts priority fill)
- Span-based evaluation to verify tool call sequences, not just final outputs

This is a scoped extension of the autonomous-operations project, not a new project. Deliverable: a Pydantic Evals dataset and evaluator suite for AO decision paths, runnable from Crumb.

**OTel instrumentation prerequisite:** Span-based evaluation — the standout feature — requires OpenTelemetry instrumentation of the execution context to capture tool-call traces. Whether Claude Code tool calls produce OTel-compatible spans needs verification. Basic evals (datasets + custom evaluators + LLM-as-judge) work without instrumentation. Full span-based evals may require non-trivial instrumentation work. Estimate this effort as part of adoption, not after.

**V2 timing caveat:** Pydantic AI V2 is planned for April 2026 — weeks away. Decision gate (not a passive wait):

1. **Monitor** for V2 release announcement
2. **If V2 ships before adoption begins:** Review migration guide for Evals-specific breaking changes, then adopt V2 directly
3. **If V2 doesn't ship within 4 weeks:** Adopt Evals on V1, pin to v1.68.x, and budget a migration pass when V2 lands
4. **Factors beyond calendar:** Assess migration surface (how much Evals API changes), urgency of AO testing gap (is the lack of formal testing causing real problems now?), and V2 ETA confidence (is "April" slipping?)

The Evals package has historically been more stable than the agent/model APIs — breaking changes in the upgrade guide have targeted agent output types, model response handling, and streaming interfaces, not evaluation primitives.

### 1.6 Unmeasured Assumption: Commodity Code Maintenance Burden

The original framing assumed that hand-rolled token budgets, output validation, and retry logic impose meaningful maintenance burden. This assumption has not been measured.

Before adopting UsageLimits, structured output validation, or other "commodity replacement" components, quantify:

- How often does existing hand-rolled validation/budget code require changes?
- How many bugs have originated in this code?
- How much time does maintenance consume per quarter?

If the answer is "near zero," the adoption cost (dependency, learning curve, integration) may exceed the savings. The Ceremony Budget Principle applies to adoption, not just to building.

### 1.7 Dependency and Supply Chain Risk

Adopting external components in a single-tenant personal OS handling data across 8 life domains carries risks beyond ceremony cost:

**Dependency footprint:** `pydantic-evals` alone installs 25 packages (verified March 15, 2026), including `pydantic-ai-slim`, `pydantic-graph`, `logfire-api`, `opentelemetry-api`, and `httpx`. Each transitive dependency is a potential attack surface, maintenance burden, and breaking-change vector.

**Vendor concentration:** Adopting multiple components from one young framework creates a single point of failure. If the Pydantic AI team's priorities shift toward Logfire monetization, or if V2 introduces unexpected breaking changes, all adopted components are affected simultaneously.

**Mitigation:**
- **Version pinning:** Pin all Pydantic AI packages to exact versions. Upgrade deliberately, not automatically.
- **Dependency audit:** Before final adoption, run `pip audit` / `safety check` on the dependency tree.
- **Exit strategy:** Evaluate de-adoption cost for each component. Evals: could revert to pytest + custom helpers with moderate effort. MCP: could switch to FastMCP standalone. The exit cost should be proportional to the adoption benefit.
- **Bus factor threshold:** Monitor the project's health signals (contributor count, issue response time, release cadence). If the project shows signs of stalling, trigger de-adoption evaluation.

### 1.8 Architectural Constraint: Synchronous Components in an Async System

Pydantic AI's agent patterns (delegation, multi-agent coordination) are synchronous — the caller blocks until the delegate returns. Crumb/Tess is fundamentally asynchronous: Tess dispatches via file queues, Crumb executes independently, results arrive via Telegram.

**Constraint:** Pydantic AI component adoption must be restricted to stateless, request-response calls within existing async boundaries. Components that would introduce synchronous blocking into the orchestration flow (agent delegation chains, graph-based coordination) are not adopted. If a future use case requires within-session sub-agents, evaluate whether Pydantic AI's synchronous delegation model is compatible with the session's execution context before adopting.

This is not a passing observation — it is a load-bearing architectural constraint that governs which components can be safely adopted.

---

## Part 2: Directional (Lower Confidence)

These are explored directions supported by initial research, but dependent on unexecuted research briefs and workloads that don't yet exist. They are hypotheses, not decisions.

### 2.1 Cloudflare Sandbox for Burst Compute

**Thesis:** For parallelizable workloads that hit the single-user ceiling, Cloudflare Sandbox containers running Pydantic AI agents could provide model-agnostic, pay-per-use burst compute.

**Explored pattern:** Tess dispatches → Cloudflare Worker → Sandbox container (Python, Pydantic AI agent, typed deps/output, UsageLimits, AI Gateway for model routing) → results to R2 → Tess retrieves → vault integration.

**Supporting evidence:**
- Cloudflare Sandbox containers support Python as a first-class runtime (full Linux environment, Python pre-installed, custom Dockerfile for dependencies)
- Cold start is ~2-3 minutes for first container, sub-second for warm containers, acceptable for batch workloads running minutes per task
- Pay-per-CPU-time billing (idle I/O waiting is free) is economical for agent workloads
- Danny already has Cloudflare infrastructure (crumbos.dev via Tunnel)

**What's missing before this becomes a decision:**
- **The Sandbox SDK spike has not been executed.** Brief defined, questions scoped, no hands-on validation.
- **No workload currently demands parallelization.** Competitive intel isn't running at 25-account scale. Book pipeline isn't actively processing. Multi-model peer review runs fine sequentially. Per the Ceremony Budget Principle, infrastructure for workloads that don't exist yet is premature.
- **Tess dispatch protocol is undesigned.** Authentication, payload structure, completion notification, error handling — all undefined.
- **Container cold start with Pydantic AI payload is untested.** The 2-3 minute number is for base containers; adding pydantic-ai and dependencies to the image may increase it.

**Trigger to revisit:** A concrete, recurring workload that is actively blocked by serial execution on the Mac Studio. When that workload exists, execute the Sandbox SDK spike with a single container type and validate the dispatch-execute-retrieve loop before scaling.

### 2.2 MCP as Integration Protocol

**Thesis:** MCP (Model Context Protocol) is becoming the standard integration protocol for agent tool access. Adopting it across local and cloud layers would reduce per-service integration maintenance.

**Supporting evidence:**
- MCP adoption across Cloudflare, OpenAI, Anthropic, Perplexity, and Pydantic AI
- Pydantic AI's MCP client is well-documented and supports local/remote servers
- The current bespoke integration surface (gws CLI, TCC grants, Discord bots) is growing

**Feasibility validated (mcp-workspace-integration project, March 2026):**
- **Google Workspace:** Community MCP server (`taylorwilsdon/google_workspace_mcp` v1.14.3, 1.8k stars, 94 tools) adopted for Crumb interactive sessions. Replaced bespoke `gws` CLI.
- **Crumb (Claude Code):** MCP tools work natively — Gmail, Calendar, Drive, Contacts, Docs, Sheets all validated.
- **Tess (OpenClaw):** MCP not supported — OpenClaw v2026.3.13 has no external MCP server mechanism. Tess uses direct REST API with shared OAuth tokens from the MCP credential store instead.
- **Architecture:** Hybrid — MCP for interactive, direct REST API for unattended automation. Token lifecycle shared via credential file.
- **Remaining services (Apple, Discord):** Not evaluated. Apple ecosystem uses snapshot architecture (no API). Discord uses OpenClaw native plugin.

---

## Design Principles Preserved

- **Ceremony Budget Principle:** Applied to adoption as well as building. Each component earns its place when adoption cost < maintenance savings. Measured, not assumed.
- **Mechanical enforcement over behavioral instructions:** UsageLimits, typed output validation, and hard kill-switches preferred over behavioral prompting.
- **Spec-first development:** New agent types validated through evals before deployment.
- **Compound engineering:** Structure emerges from actual content. Infrastructure follows workloads, not the reverse.
- **Differentiating vs. commodity:** Vault-as-memory, ceremony budgets, orchestration logic = differentiating (bespoke). Output validation, retry logic, tool plumbing, cost tracking = commodity (adopt if maintenance burden is measured and significant).

---

## Implementation Sequence

### Active Decision Gates

1. **Monitor for V2 release** (expected April 2026). This is an active gate, not a passive wait:
   - If V2 ships → review migration guide for Evals-specific changes → adopt Evals on V2
   - If V2 doesn't ship within 4 weeks → adopt Evals on V1, pin to v1.68.x, budget migration pass
   - Decision factors: migration surface, AO testing gap urgency, V2 ETA confidence

2. **Empirical spike before committing** (prerequisite to Evals adoption): Install pydantic-evals, write one test case for an AO decision path, confirm it runs. Verify whether OTel spans from Claude Code tool calls are compatible with span-based evaluation. If span-based eval is impractical, re-evaluate whether pydantic-evals justifies its 25-package dependency tree over pytest + custom helpers.

### Near-Term Execution

3. **Adopt Pydantic Evals** (on V2 if available, V1 pinned if not) scoped to autonomous-operations decision path verification. Run dependency audit (`pip audit`) before final adoption.

4. **Measure maintenance burden** of existing hand-rolled validation/budget/retry code. This is a validation gate: before adopting UsageLimits, structured output validation, or other "commodity replacement" components, quantify the actual maintenance cost of what's being replaced. Run concurrently with Evals adoption — Evals fills a gap (new capability), not a replacement.

### Trigger-Based Investigations

5. **Execute MCP feasibility brief** when the next bespoke integration needs maintenance or extension. Evaluate per-service: does an MCP server exist that's more maintainable? Also evaluate FastMCP standalone as an alternative to Pydantic AI's MCP client.

6. **Execute Cloudflare Sandbox SDK spike** when a concrete, recurring workload is actively blocked by serial execution on the Mac Studio.

7. **Evaluate pydantic-graph, durable execution, A2A, fasta2a** only when specific triggers arise. Not on the roadmap.
