---
type: reference
domain: software
status: active
created: 2026-03-14
updated: 2026-04-11
tags:
  - system/architecture
topics:
  - moc-crumb-architecture
---

# Crumb/Tess System Architecture

This document is the entry point for the Arc42-derived architecture documentation of the Crumb/Tess personal multi-agent operating system. These docs describe **current implementation state** — what exists, how it's built, how it behaves. For design intent and principles, see the design spec.

## Sections

1. [[01-context-and-scope]] — System boundary, actors (Danny, Crumb, Tess Voice, Tess Mechanic), external interfaces, handoff model, constraints
2. [[02-building-blocks]] — 9 subsystems in 3 tiers: agents (20 skills, 4 subagents, orchestrator), lenses & patterns (8 overlays, 6 protocols, scripts), data & communication. Ownership map, dependency diagram, code mapping.
3. [[03-runtime-views]] — 6 sequence diagrams: session lifecycle, Tess dispatch, feed pipeline, Mission Control, bridge handoff, AKM surfacing
4. [[04-deployment]] — Mac Studio host; two-namespace LaunchAgent architecture (`ai.openclaw.*` legacy + `com.tess.v2.*` current, migration in progress); Crumb-side support services (`com.crumb.*`); Tailscale mesh, storage layout, credential management, DNS.
5. [[05-cross-cutting-concepts]] — Frontmatter schema, tag taxonomy (18 Level 2 kb/ tags), vault-check (~27 validations), context budgets, MOC system, compound engineering (with 2026-04-04 track/review-routing/cluster enhancements), code review tiers (Claude Opus + Codex).

## Document Hierarchy

| Document | Authority | Changes When |
|----------|-----------|-------------|
| [[crumb-design-spec-v2-4]] | Intent and principles (the "why") | Fundamental model changes |
| **Architecture docs** (this set) | Current implementation state (the "how") | System changes structurally |
| [[separate-version-history]] | Chronology (the "when") | Any notable change |

Architecture docs must be consistent with the design spec. Divergence means either the spec needs updating (intent changed) or the implementation is wrong.

## Related Documents

- [[crumb-design-spec-v2-4]] — Design intent authority
- [[separate-version-history]] — Chronological change record
- [[overlay-index]] — Overlay routing table
- [[file-conventions]] — File naming, frontmatter, and tag conventions
- [[CLAUDE.md]] — Crumb's governance surface

## Terminology Index

| Term | Definition | See |
|------|-----------|-----|
| AKM | Active Knowledge Memory — QMD-backed semantic retrieval engine. Surfaces relevant vault knowledge at session start and skill activation. | [[01-context-and-scope]], [[03-runtime-views]] §6 |
| QMD | Quantized Markdown — vector embedding format for vault content. Backend for AKM semantic search. | [[02-building-blocks]] §7 |
| FIF | Feed Intel Framework — content intelligence pipeline. Captures, triages, and routes external content to the vault. | [[03-runtime-views]] §3–§4 |
| MOC | Map of Content — navigational index for a knowledge domain. Two types: orientation (synthesis) and operational (procedural). 15 built. | [[02-building-blocks]] §7, [[05-cross-cutting-concepts]] |
| HITL | Human-in-the-loop — risk-tiered approval model. Low=auto, Medium=flag, High=stop. | [[05-cross-cutting-concepts]] |
| OpenClaw | Agent gateway platform. Runs Tess as a LaunchDaemon. Manages Telegram bindings, cron, and plugin dispatch. | [[04-deployment]] |
| Bridge | Filesystem-based handoff between Tess and Crumb via `_openclaw/inbox/` and `_openclaw/outbox/`. kqueue detection, 4-layer security. | [[01-context-and-scope]], [[03-runtime-views]] §5 |
| Skill | Procedural expertise package in `.claude/skills/`. Loaded on-demand by description match. 20 active. | [[02-building-blocks]] §2 |
| Overlay | Expert lens injected into active skills. No procedures of their own. 8 active. Routed via overlay index. | [[02-building-blocks]] §4 |
| vault-check | Deterministic bash script with ~27 mechanical validations. The system's only enforcement that can't hallucinate. Pre-commit hook. | [[05-cross-cutting-concepts]] |
| Compound | Reflection at every phase transition that routes insights to conventions, solution docs, or primitive proposals. | [[05-cross-cutting-concepts]] |
| Signal-note | Lightweight knowledge capture from feed pipeline. Lives in `Sources/signals/`. Promotion path to full knowledge-note. | [[05-cross-cutting-concepts]] |
