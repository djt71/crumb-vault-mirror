---
type: reference
domain: software
status: active
created: 2026-03-14
updated: 2026-07-05
tags:
  - system/architecture
topics:
  - moc-crumb-architecture
---

# Crumb/Tess System Architecture

This document is the entry point for the Arc42-derived architecture documentation of the Crumb personal multi-agent operating system. These docs describe **current implementation state** — what exists, how it's built, how it behaves. For design intent and principles, see the design spec.

> **Historical naming note:** This set is still titled "Crumb/Tess" for continuity with its 2026-03/04 origin. The Tess/OpenClaw agentic layer it describes throughout was decommissioned by project agentic-sunset (2026-06-01 → 2026-06-12), reboot-verified absent 2026-06-14 — `_openclaw/` is deleted from disk. Current reality is single-agent: Crumb (Claude Code sessions) operated by danny. Historical sections are marked inline; see [[03-runtime-views]] and [[04-deployment]] for the fullest decommission framing.

## Sections

1. [[01-context-and-scope]] — System boundary, actors (Danny, Crumb; historical: Tess Voice, Tess Mechanic), external interfaces, handoff model, constraints
2. [[02-building-blocks]] — 9 subsystems in 3 tiers: agents (15 skills, 4 subagents, orchestrator), lenses & patterns (8 overlays, 4 protocols, scripts), data & communication. Ownership map, dependency diagram, code mapping.
3. [[03-runtime-views]] — 6 sequence diagrams: session lifecycle, Tess dispatch (historical), feed pipeline (historical), Mission Control (partially historical), bridge handoff (historical), AKM surfacing
4. [[04-deployment]] — Mac Studio host; single `com.crumb.*` LaunchAgent namespace (11 plists, 10 loaded — dashboard parked); the historical two-namespace `ai.openclaw.*`/`com.tess.v2.*` architecture was decommissioned by agentic-sunset (2026-06); Tailscale mesh, storage layout, credential management, DNS.
5. [[05-cross-cutting-concepts]] — Frontmatter schema, tag taxonomy (18 Level 2 kb/ tags), vault-check (26 validations), context budgets, MOC system, compound engineering (with 2026-04-04 track/review-routing/cluster enhancements), code review tiers (Claude Opus + Codex).

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
| FIF | Feed Intel Framework — content intelligence pipeline. Captures, triages, and routes external content to the vault. **Historical (decommissioned):** archived 2026-07-05; the concept moved to Claude Cowork (rented runtime) — see `cowork-feed-handoff.md`. | [[03-runtime-views]] §3–§4 |
| MOC | Map of Content — navigational index for a knowledge domain. Two types: orientation (synthesis) and operational (procedural). 15 built. | [[02-building-blocks]] §7, [[05-cross-cutting-concepts]] |
| HITL | Human-in-the-loop — risk-tiered approval model. Low=auto, Medium=flag, High=stop. | [[05-cross-cutting-concepts]] |
| OpenClaw | Agent gateway platform. Ran Tess as a LaunchDaemon. Managed Telegram bindings, cron, and plugin dispatch. **Historical (decommissioned):** decommissioned by agentic-sunset (2026-06-01 → 2026-06-12), reboot-verified absent 2026-06-14. | [[04-deployment]] |
| Bridge | Filesystem-based handoff between Tess and Crumb via `_openclaw/inbox/` and `_openclaw/outbox/`. kqueue detection, 4-layer security. **Historical (decommissioned):** `_openclaw/` deleted from disk at decommission (2026-06). `_inbox/` is the current universal intake. | [[01-context-and-scope]], [[03-runtime-views]] §5 |
| Skill | Procedural expertise package in `.claude/skills/`. Loaded on-demand by description match. 15 active. | [[02-building-blocks]] §2 |
| Overlay | Expert lens injected into active skills. No procedures of their own. 8 active. Routed via overlay index. | [[02-building-blocks]] §4 |
| vault-check | Deterministic bash script with 26 mechanical validations. The system's only enforcement that can't hallucinate. Pre-commit hook. | [[05-cross-cutting-concepts]] |
| Compound | Reflection at every phase transition that routes insights to conventions, solution docs, or primitive proposals. | [[05-cross-cutting-concepts]] |
| Signal-note | Lightweight knowledge capture from the historical feed pipeline (FIF, decommissioned 2026-07-05). Lives in `Sources/signals/`. Promotion path to full knowledge-note. | [[05-cross-cutting-concepts]] |
