---
project: tess-v2
domain: software
type: reference
status: active
created: 2026-03-28
updated: 2026-03-28
skill_origin: null
tags:
  - design-input
---

# Tess v2 — Conversation Analysis (2026-03-27)

**Source:** Danny/Opus conversation, 2026-03-27
**Purpose:** Extract architectural patterns and design decisions for tess-v2 specification

---

## Key Insight: Spec-Based + Eval-Based Building Are Complementary

Crumb's current four-phase workflow (SPECIFY → PLAN → TASK → IMPLEMENT) is spec-based: it defines *how* to build and *what* to build upfront. Eval-based building defines *when you're done* and *whether it's good* through measurable success criteria with mechanical enforcement.

These are not competing approaches — they operate on different axes. Specs prescribe process. Evals verify outcomes. Crumb already has eval points at each phase transition gate (peer review, approval). The integration is: formalize those gates as **contracts with mechanical stop conditions**, enabling autonomous execution without human approval at every step.

**Practical integration for tess-v2:**
- Specs still define the work (SPECIFY/PLAN phases produce the blueprint)
- Contracts derived from specs define completion criteria (tests, artifact checks, verification rules)
- Contracts are embedded as hard termination gates — the executing agent cannot stop until the contract is satisfied
- Phase transition gates become eval checkpoints: does the output of this phase satisfy its contract?

This is what enables the shift from "Danny approves each step in Claude Code" to "Tess dispatches contracts and agents execute autonomously."

---

## Architectural Patterns for tess-v2 Specification

### Pattern 1: Contract-Based Execution Model

Each task dispatched by Tess carries a **contract** — a machine-readable specification of what must be true before the task is considered complete.

A contract includes:
- **Tests:** Deterministic pass/fail criteria (test suites, assertion checks, file existence)
- **Artifact verification:** Expected outputs exist, are well-formed, pass schema validation
- **Behavioral verification:** Screenshots, output sampling, or structured checks where applicable
- **Stop condition:** The agent is mechanically prevented from terminating until all contract items are satisfied

Contracts are derived from the spec-based workflow's action plans — they are the eval layer on top of the spec layer. The action plan says "build X with Y approach." The contract says "X is done when these 5 things are true."

**Provenance:** This pattern emerged from the conversation's analysis of eval-based building. Danny's existing action plans already contain the content of contracts; the integration adds mechanical enforcement.

### Pattern 2: Ralph Loops (Focused Iteration with Accumulated Context)

The execution primitive for contract-based work: a focused loop where an agent iterates on a single task with accumulated failure context until the contract is satisfied.

Mechanics:
- One contract per session (fresh context, no cross-task contamination)
- Each iteration feeds back the previous output/failure as context
- Hard stop when contract passes — the loop terminates
- If the loop exceeds a retry budget without satisfying the contract, escalate to Tess

This prevents the context bloat that degrades long-running agent sessions. Each contract runs in isolation. Tess orchestrates the sequence, not the agent.

**Provenance:** Named after the "Ralph Wiggum loop" pattern — a bash-level iteration loop (`while :; do cat PROMPT.md | claude ; done`) where the agent keeps trying until tests pass. The conversation identified that Crumb's contract + fresh-session model is already building toward this pattern.

### Pattern 3: Overlay Injection at Dispatch

When Tess dispatches a contract to an executor, she passes not just the task and contract but also **relevant overlays** that shape how the executor reasons during implementation.

Examples:
- Security overlay → executor applies security lens during implementation
- Cost-optimization overlay → executor minimizes resource usage
- Domain-specific overlay → executor has domain context for decisions

This extends Crumb's existing overlay system (currently used in interactive Claude Code sessions) into the orchestration layer. Overlays become dispatch metadata, not just session configuration.

**Transaction:** Tess's orchestration overlays inform *what* work gets done and in *what* order. The executor's injected overlays inform *how* that work gets done. Both layers apply the same principles at different stages.

### Pattern 4: Service Formalization

Tess's operational functions should be explicitly classified as **services** — background agents with defined contracts, input interfaces, output interfaces, and health checks.

Current Tess functions that are already service-like:
- Feed-intel pipeline (always running, pull/aggregate/deliver)
- Email triage (scheduled, classify/route)
- Morning briefing (scheduled, compile/deliver)
- Apple data snapshots (scheduled, capture/store)
- Vault gardening (periodic, scan/fix/file)

Formalization means each service has:
- A defined contract (what does "healthy operation" look like?)
- Input interface (what triggers it, what data does it consume?)
- Output interface (what artifacts does it produce, where do they go?)
- Health check (how do you know it's working?)
- Failure mode (what happens when it breaks?)

This transforms Tess from "a bag of cron jobs" to "named infrastructure with defined behavior."

### Pattern 5: Sycophancy-Aware Task Framing

How Tess frames tasks for executors affects output quality:
- **Investigation tasks:** Use neutral prompts ("walk through the logic and report findings") not confirmation-seeking prompts ("find the bug")
- **Quality evaluation:** Consider adversarial patterns (finder → adversary → referee) for high-stakes evaluation, but evaluate complexity cost before committing

This is a prompt engineering discipline for the orchestration layer, not an architectural decision. Note as a design consideration for Tess's task framing logic.

---

## Concepts Validated (Not New to Crumb)

- **Context control is paramount** — aligns with Crumb's Ceremony Budget Principle and source document budget
- **CLAUDE.md as routing table** — Crumb already does this; worth periodic audit
- **Periodic rule/skill consolidation** — maps to existing audit skill
- **Persona agents are inferior to overlays** — validates Crumb's existing overlay architecture
- **Fresh context per task beats long-running sessions** — validates the contract-per-session model
