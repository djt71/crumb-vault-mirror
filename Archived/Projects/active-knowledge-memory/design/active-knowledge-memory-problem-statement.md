# Active Knowledge Memory — Problem Statement

## Problem

The vault's knowledge base is growing — book digests, research notes, architecture docs, personal writing — but it's passive. Knowledge goes in, gets organized, and waits to be found. The only way to access it is to already know what you're looking for (search/grep) or to manually browse the MOC layer.

This means knowledge that's directly relevant to what you're working on right now goes unused unless you happen to remember it exists. As the KB scales (more adapters, more sources, your own writing), this gap gets worse, not better.

**The core issue:** accumulated knowledge doesn't participate in ongoing work unless you manually retrieve it.

## Desired Outcomes

1. Relevant knowledge surfaces when it's needed — during sessions, during tasks, when new content arrives — without being asked for.
2. Your own writing and thinking is treated as the highest-value material in the system.
3. Both agents can benefit from the knowledge base — Tess for awareness and flagging, Crumb for deep work and curation — respecting the existing boundary (Tess advises, Crumb curates).
4. The system scales with the KB. What works at hundreds of notes should work at thousands.
5. Connections between ideas are recognized — not just tag-level category matches, but conceptual relationships that cross domain boundaries.

## Boundary Clarification

Tess having read access to the knowledge base and flagging connections is advisory — the same as any other awareness function she performs. It doesn't violate the curation boundary. Knowledge creation, tagging, and organization remain Crumb's domain.

## Origin

Problem identified during feed-intel processing pipeline design (claude.ai session, 2026-03-01). The processing pipeline (separate project, in progress) addresses the intake gap between FIF output and the knowledge navigation layer. This project addresses the complementary gap: making stored knowledge actively useful once it's in the vault.

## Adjacent Systems

- **Knowledge Navigation** — MOCs, source-index notes, `#kb/` tag taxonomy, `topics` field enforcement. The organizational layer this builds on.
- **Feed-Intel Processing Pipeline** — automated intake from FIF output to vault. The upstream feeder.
- **Vault Snapshot** — current project-awareness context used by the triage engine. Limited to project state; no KB awareness.
- **Compound Insight Routing** — opportunistic pattern recognition during sessions. Captures durable patterns but doesn't surface existing knowledge.
- **Crumb–Tess Bridge** — dispatch protocol for cross-agent task coordination. Potential coordination mechanism.

NOTE: whatever system we deploy to index the knowedgebase needs to be appropriate to the size of the KB. it's small right now but will eventually store up to 400 book summaries alone, in addition to all the other inputs we're developint (see active projects for to have an idea of what's coming).
