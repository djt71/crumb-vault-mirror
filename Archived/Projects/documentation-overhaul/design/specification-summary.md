---
type: specification-summary
project: documentation-overhaul
domain: software
status: active
created: 2026-03-14
updated: 2026-03-14
source_updated: 2026-03-14
skill_origin: systems-analyst
tags:
  - system/docs
  - system/architecture
topics:
  - moc-crumb-architecture
---

# Documentation Overhaul — Specification Summary

Three-track documentation overhaul for Crumb/Tess. Architecture docs (Arc42), operator docs (Diátaxis), and an LLM orientation tracking map.

## Three-Document Hierarchy

Design spec (intent authority) → Architecture docs (current-state authority) → Version history (chronology only). Architecture docs are the authoritative source that operator and LLM docs reference.

## Track 1: Architecture (Arc42, 6 files in `_system/docs/architecture/`)

- **00** — Overview: navigation aid + terminology index (written last)
- **01** — Context and Scope: system boundary, actors, external interfaces, constraints
- **02** — Building Blocks: subsystem decomposition, ownership map, dependencies
- **03** — Runtime Views: session lifecycle, dispatch cycles, pipeline flows (sequence diagrams)
- **04** — Deployment: host, processes, network, storage, credentials, DNS
- **05** — Cross-Cutting Concepts: observable conventions and enforced patterns (not restated principles)

Each section requires Mermaid diagrams with prose fallback summaries for NotebookLM.

## Track 2: Operator Docs (Diátaxis, in `_system/docs/operator/`)

- **tutorials/**: first-crumb-session, first-tess-interaction, mission-control-orientation
- **how-to/**: run-feed-pipeline, triage-feed-content, update-a-skill, rotate-credentials, vault-gardening, add-knowledge-to-vault (deploy-openclaw-update merged into reclassified deployment runbook)
- **reference/**: skills, overlays, vault-structure, sqlite-schema, infrastructure, tag-taxonomy
- **explanation/**: how-crumb-thinks, why-two-agents, the-vault-as-memory, feed-pipeline-philosophy

Stability gate: only write docs for subsystems with stable interfaces.

## Track 3: LLM Orientation Map (`_system/docs/llm-orientation/orientation-map.md`)

Single tracking artifact. Lists every LLM-consumed doc with location, budget, update trigger, and architecture source link. Enables gap and staleness detection. Automation candidate for Phase 3 follow-on.

## Implementation Phases

- **Phase 0**: Update file-conventions.md + vault-check.sh for new tags (prerequisite)
- **Phase 1**: 5 architecture docs (3-5 sessions). Sequence: 01 → 02 → 04 → 03 → 05 → 00
- **Phase 2**: Operator docs in 4 batches (5-8 sessions). Migration batch first (reclassify existing docs), then AI-drafted docs by priority
- **Phase 3**: Orientation map (1 session)

Total: 9-14 sessions, ~2-4 weeks.

## Consolidation Plan

12 existing docs mapped to dispositions: 6 absorbed into new docs (stub-and-archive), 6 reclassified (moved and retagged). Ops/ directory retired.

## Key Design Constraints

- NotebookLM is primary consumption mechanism — docs must be self-contained
- AI drafts, Danny reviews pass/fail (final artifacts only)
- Ceremony Budget Principle applies throughout
- Wikilinks used for vault cross-referencing (readable as text in NotebookLM)

## Key Decisions (post peer review)

- Phase 0 prerequisite for tag taxonomy (blocks Phase 1 otherwise)
- "Keep as-is" docs migrated not redrafted, checked against Diátaxis quadrant
- Authority domains explicit: intent / current state / chronology
- Staleness detection uses `updated:` frontmatter, is a heuristic not a rule
- Maintenance trigger for 05 is conditional on convention changes, not all principle changes
