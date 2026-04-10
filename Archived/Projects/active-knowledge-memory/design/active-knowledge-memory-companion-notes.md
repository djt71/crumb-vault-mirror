# Active Knowledge Memory — Companion Notes

## Purpose

This document is **analysis input for the SPECIFY phase**, not a design or architecture proposal. It synthesizes external reviews of the problem statement, identifies verified gaps in the current system, and catalogs ideas worth evaluating. Nothing here should constrain the solution space — the SPECIFY phase should run in its entirety and reach its own conclusions.

## Source

Problem statement reviewed by four external models (2026-03-01):

- Perplexity Sonar Reasoning Pro — given problem statement + Crumb design spec v2.1
- Gemini — given problem statement
- DeepSeek — given problem statement + research literature
- ChatGPT — given problem statement + Crumb design spec v2.1

All four analyses reviewed, critiqued, and synthesized in claude.ai session with Danny.

## Gap Identification (Verified Against Current Spec)

These gaps were identified across multiple analyses and confirmed against the codebase and spec. They describe the current state of the system — what exists and what doesn't — not proposed solutions.

- **Compound step is write-only toward the KB.** It routes new patterns into `solutions/` and tags notes `#kb/*`, but there's no read-path that surfaces existing knowledge during work. (Perplexity)
- **Systems analyst only reads from `_system/docs/solutions/`.** It doesn't mine `Sources/` or `Domains/` for concept-level matches to a current problem. (Perplexity)
- **Vault snapshot is KB-blind.** It sees project state (~600 token YAML), not knowledge notes or MOCs. Confirmed by reading snapshot source code. (Perplexity, confirmed in session)
- **No standard mechanism for Tess to flag knowledge connections.** The bridge protocol handles task dispatch, not advisory knowledge surfacing. (Perplexity)
- **No single mechanical definition of "active focus."** ~6 projects in various phases, but nothing tells a surfacing system which context to prioritize right now. (ChatGPT)

## Concepts Worth Evaluating During SPECIFY

These ideas emerged across the analyses. They represent the hypothesis space — possible approaches and considerations — not recommendations. SPECIFY should evaluate them on their merits against the problem statement and desired outcomes, and may well arrive at different or better solutions.

### On retrieval targets

The MOC layer isn't just for human browsing — it could serve as a compression layer for machine retrieval. One MOC provides the context of ~15 notes at one note's token cost. Whether the retrieval target should be individual notes, MOCs, or both depending on context is an open question. (Gemini)

### On starting simple

Tag proximity, MOC proximity, and wikilink proximity are all queryable today without any new infrastructure. A version of knowledge surfacing built purely on existing vault relationships might be a viable starting point worth evaluating before investing in heavier approaches. (DeepSeek)

### On session activity as a relevance signal

Distinct from the knowledge base itself, a record of which notes were referenced and which connections were made during past sessions could be a useful relevance signal. The vault doesn't currently track this. Whether the signal value justifies the engineering cost is an open question. (DeepSeek)

### On retrieval approaches

Multiple analyses converged on the observation that keyword-based search and semantic/conceptual search have complementary strengths — one finds exact terms, the other finds conceptual matches across different vocabulary. How to combine them (or whether simpler approaches suffice at current vault scale) is worth evaluating. (DeepSeek, ChatGPT)

### On when to surface knowledge

One analysis framed surfacing as event-driven rather than continuous: specific moments (session start, task context change, new content arrival) trigger retrieval, each with a hard budget on how many items to surface and a relevance threshold. This constrains the "when" without over-specifying the "how," and directly addresses the risk of surfacing too much. (ChatGPT)

### On composability

Multiple analyses agreed this should plug into existing phases and skills rather than introduce new workflows. The capability is cross-cutting — it augments SPECIFY, PLAN, TASK, and session startup rather than living alongside them. (Perplexity, ChatGPT)

### On what "working" looks like

One analysis proposed concrete success criteria: reduced re-derivation of known ideas, a useful hit rate (at least 1 of N surfaced items is relevant most of the time), low annoyance (you don't start ignoring the system), and improvement over time via feedback. Whether these are the right criteria is for SPECIFY to decide, but having testable acceptance criteria is important. (ChatGPT)

## Critical Constraint: Maintenance Gravity

This emerged from ChatGPT's review of the overall Crumb v2.1 spec and applies directly to this project.

The system's biggest threat isn't architectural — it's that the ceremony required to keep it running becomes burdensome enough that it stops being used, or gets used in a partial way that creates shadow workflows. Whatever gets built must reduce friction, not add it. Every mechanism needs to pass the test: *does this make the system more pleasant to use, or does it add another thing to maintain?*

This constraint isn't in the problem statement currently. **SPECIFY should consider whether to adopt it as a first-class design requirement.**

## Ideas Flagged as Potentially Conflicting with Requirements

These came up in multiple analyses and may warrant explicit consideration during SPECIFY to ensure the solution doesn't drift from the problem statement's intent.

### Temporal decay applied uniformly to the KB

Both Gemini and DeepSeek proposed ranking recent notes higher than older ones. This may conflict with the problem statement's emphasis on personal writing as the highest-value material. Philosophical insights, original thinking, and conceptual frameworks don't decay in relevance. A note written six months ago could be the most relevant thing to surface during today's design work. Any relevance model may need to distinguish between content categories rather than applying uniform decay.

### Building graph infrastructure that mirrors existing vault structure

Multiple analyses proposed building knowledge graph infrastructure. But the vault already has graph structure — wikilinks, MOC membership, and `topics` fields are all relationship edges. Whether additional graph infrastructure is needed, or whether the existing vault relationships can be queried directly, is worth evaluating honestly.

### Infrastructure artifacts stored in the vault

One analysis proposed storing index data in `_system/docs/`. This may conflict with the vault's role as source of truth for human-meaningful content. Where infrastructure artifacts live relative to the vault is a design decision SPECIFY should address explicitly.

## A Note on the Analyses Themselves

All four external reviews jumped from problem statement to architecture and implementation. This is the nature of the exercise — when you ask a model to analyze a problem, it wants to solve it. The hypothesis space they mapped is useful input, but the SPECIFY phase exists precisely to evaluate this space rigorously rather than inherit conclusions from upstream.
