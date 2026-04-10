---
type: explanation
status: active
domain: software
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# How Crumb Thinks

Crumb is an AI orchestrator that treats your personal knowledge system like a software project — with specs, phase gates, and mechanical enforcement. This explains the mental model behind that approach.

**Architecture source:** [[00-architecture-overview]], [[05-cross-cutting-concepts]]

---

## Spec-First, Always

Every substantial piece of work starts with a specification. Not because process is good, but because specifications are the cheapest way to catch bad ideas.

Writing a spec forces clarity before commitment. It answers "what are we building and why?" before anyone writes a line of code or creates a vault artifact. The spec becomes the contract: downstream work is evaluated against it, not against the operator's evolving sense of what they wanted.

This applies to software projects (full four-phase: SPECIFY → PLAN → TASK → IMPLEMENT), knowledge work (three-phase: SPECIFY → PLAN → ACT), and even personal goals (two-phase: CLARIFY → ACT). The phases scale down but the principle doesn't — know what you're doing before you do it.

---

## Phase Gates as Quality Control

Crumb never skips phases. Each transition requires a checkpoint: log what was done, evaluate what was learned, verify context isn't degraded, update project state. This is the Context Checkpoint Protocol, and it runs at every phase boundary.

The gates aren't bureaucracy. They're the mechanism that prevents a common failure mode: starting execution before the design is solid, then discovering halfway through that the requirements were wrong. Phase gates catch this early, when the cost of correction is low.

If reality diverges from the spec mid-execution, the answer isn't to push through — it's to update the spec first, then resume. The spec stays authoritative.

---

## Compound Engineering

The most valuable insight Crumb produces isn't the immediate deliverable — it's the pattern recognition that happens alongside the work.

At every phase transition, Crumb performs a compound evaluation: looking across the current project, recent vault activity, and known solution patterns for insights that are more valuable than the specific task. These might be:

- A convention that should be documented because it keeps recurring
- A solution pattern that worked here and would work elsewhere
- A primitive gap (missing skill, overlay, or protocol) that would reduce friction
- A cross-domain connection between unrelated areas of the vault

Compound insights are routed to where they'll have lasting value: conventions update existing docs, patterns go to `_system/docs/solutions/`, primitive gaps enter the proposal flow. The individual session ends, but the learning persists.

---

## Ceremony Budget

Not everything deserves full ceremony. Crumb calibrates response depth to the request:

- **FULL:** New phase, new task, scope change — full skill/overlay/context loading
- **ITERATION:** Refining current work — load only what the change needs
- **MINIMAL:** Quick fix, lookup, clarification — just do it

The Ceremony Budget Principle goes further: before proposing new capabilities, Crumb evaluates whether existing friction can be reduced first. Reducing ceremony is higher leverage than adding capability. New primitives increase operational surface and must justify their maintenance cost.

This is why Crumb doesn't create a new skill for every recurring task, or add a new overlay for every domain. The right amount of structure is the minimum that earns its keep.

---

## Mechanical Enforcement

Crumb doesn't rely on discipline to maintain quality — it relies on automation. vault-check runs 30 deterministic validation checks on every commit. If frontmatter is wrong, a binary lacks a companion note, or a `#kb/` tag is non-canonical, the commit is blocked.

This is intentional. Mechanical enforcement is cheaper than vigilance. It means the vault stays structurally sound even when the operator (or Crumb) is rushing, tired, or handling a large batch of changes.

The enforcement is tiered: errors block commits, warnings are advisory. This prevents false-positive friction while maintaining hard constraints where they matter.

---

## The Vault as Single Source of Truth

Crumb holds no authoritative state in memory. Everything — project state, decisions, context, patterns, knowledge — lives in the vault. Chat history is ephemeral and disposable. The vault is permanent.

This means any session can be abandoned and resumed from vault state alone. It means the operator can review exactly what Crumb knows and has decided. It means there's no hidden context or accumulated drift — just files on disk, git-tracked, validated, searchable.

The design constraint is simple: if it matters, it's in the vault. If it's in the vault, it persists. If it persists, it compounds.
