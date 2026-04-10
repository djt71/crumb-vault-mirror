---
type: specification-summary
status: active
domain: software
project: active-knowledge-memory
source_updated: 2026-03-02
created: 2026-03-01
updated: 2026-03-03
tags:
  - kb/software-dev
  - agent-memory
  - retrieval
topics:
  - moc-crumb-architecture
  - moc-crumb-operations
---

# Active Knowledge Memory — Specification Summary

## Problem

The vault's KB is passive — content is organized, tagged, and linked but only retrievable when you already know what to look for. As the KB scales, relevant knowledge goes unused during active work because nothing connects stored knowledge to current context.

## Solution Shape

A retrieval engine called at three trigger points with three distinct interaction modalities:

| Trigger | Modality | Delivery |
|---------|----------|----------|
| Session start | Proactive | Pushed in startup output |
| Skill activation | Ambient | Loaded silently during context gathering |
| New content arrival | Batched | Logged for Tess to aggregate and deliver at natural breakpoints |

The retrieval engine takes a context signal (active focus), queries the KB, and returns a compact knowledge brief (≤5 items, ≤500 tokens). v1 uses QMD (BM25 + semantic + hybrid search, CLI mode) over vault collections. QMD ships all three search modes — no separate v2 embedding phase needed. The interface is stable; configuration evolves (mode selection, collection scoping).

## Phased Delivery

1. **Session start** — proves retrieval works
2. **Skill activation** — proves mid-session integration works
3. **New content** — proves Tess advisory path works

Each builds on the last. **QMD mode evaluation** (AKM-EVL, complete): 12 queries × 3 modes showed modes are complementary, not interchangeable. Result: per-trigger routing — session-start uses hybrid, skill-activation uses semantic, new-content uses hybrid. Mode tuning (AKM-009) applied evaluation results to configure per-trigger defaults and ranking parameters.

## Key Constraints

- Ceremony Budget Principle: no recurring manual actions during normal sessions (one-time setup and automated evaluation acceptable)
- Composability: augments existing skills/hooks, no new workflows
- Fully local retrieval: QMD with ~2GB local models, no external API calls
- Category-aware relevance: no uniform temporal decay
- Noise is the primary risk (confirmed by research + Artem's production data) — automatic feedback capture, result diversity constraints, trigger deduplication
- Personal writing boost: convention established, ranking boost auto-activates at ≥3 `type: personal-writing` notes

## Tasks (13)

Foundation: AKM-001 (focus signal), AKM-002 (brief format), AKM-003 (personal writing convention)
v1 Retrieval: AKM-004 (QMD engine), AKM-005 (session start), AKM-006 (skill activation), AKM-007 (new content)
Evaluation Gate: AKM-EVL (QMD mode comparison against real corpus)
QMD Tuning: AKM-008 (collections & indexing), AKM-009 (mode selection & ranking)
Cross-Agent: AKM-010 (Tess design), AKM-011 (Tess implementation)
Validation: AKM-012 (end-to-end)

## Project Status

**Phase: DONE** (2026-03-02). All 11 tasks complete (AKM-010/011 deferred to separate project if needed). Validated: 71% hit rate (5/7 scenarios), zero noise. Deferred items: Python extraction from bash heredoc (D1), feedback loop consumption (F3 — implemented post-audit 2026-03-03).

## Current KB State

~310 source notes, 45 biographical profiles, 13 MOCs. No personal creative/reflective writing yet. Tag distribution broadened significantly by batch-book-pipeline.
