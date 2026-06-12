---
project: firekeeper-books
domain: creative
type: reference
skill_origin:
status: active
created: 2026-04-07
updated: 2026-06-12
tags:
  - learning-plan-tracker
  - ai-art
---

# AI Art Learning Plan Inventory

Trackable commitments for the [[ai-art-learning-plan]]. This is the **behavior layer** — see the plan doc for the meaning layer. Pattern: [[behavior-vs-meaning-in-routine-design]].

This file gets rewritten at each phase transition. Items below reflect the **current active phase**.

## Current Phase

**M-1B: Local Pipeline Spike** — started 2026-06-12, budget 3 logged sessions (~6–9 hours). See spec §10 for the full gate definition.

**Context:** The original Phase 1/2 plan (Midjourney) stalled in April — the tool never cleared Danny's quality bar. The plan's tool assumptions are superseded: local generation (Draw Things on the Mac Studio, batch panels + style LoRA) replaces cloud prompting. The learning goal is unchanged — art direction aptitude and a style system worthy of the edition — but the practice loop is now panels-and-curation, not prompt-and-pray. The 2026-04-07 compressed-sprint entry stands as the record of the first drift detection; this rewrite is the second.

## Spike Sessions (M-1B)

- **Session 1:** Draw Things install + candidate models pulled (license-checked for commercial use — open item H) + first batch panels on scene 1 (the creation). Log hours in `progress/time-log.md` under a new M-1B heading. — [cadence: once]
- **Session 2:** Batch panels scenes 2–3 (Arctic ice, creature in the Alps) using adapted `03c` prompts; curate keepers; note what's working against the Coulthart/Wrightson bar. — [cadence: once]
- **Session 3:** Refinement pass on best candidates (img2img/inpaint); write go/iterate/stop decision to `design/spike-findings.md`. — [cadence: once]

## Per-Session Discipline (every session)

- Time-log entry (start/stop) — the catalog thesis depends on this number
- Save keeper candidates + their generation settings (model, seed, params) — reproducibility is the point of going local
- One-line benchmark verdict: closer to or further from the Coulthart/Wrightson bar than last session?

## Phase Transition Watch

- **Gate decision after session 3** (hard stop — iterate verdict buys at most 2 more sessions, once).
- On **Go**: rewrite this file for M0 (style LoRA training + design prototype items).
- On **Stop**: rewrite this file as closed; spike findings feed the strategic rethink.

## Carry-Forward

- Anti-pattern study (from Phase 1): the "obviously AI" failure-mode eye matters *more* with open disclosure — curation quality is the public proof of work.
