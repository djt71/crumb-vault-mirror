---
type: specification-summary
project: documentation-refresh-2026-04
domain: software
status: active
created: 2026-04-11
updated: 2026-04-11
source_updated: 2026-04-11
skill_origin: systems-analyst
tags:
  - system/docs
  - system/architecture
topics:
  - moc-crumb-architecture
---

# Documentation Refresh 2026-04 — Specification Summary

Content refresh of all three doc tracks from the archived `documentation-overhaul` project (2026-03-14), which have drifted over ~4 weeks of substantial system change. Structure and file locations remain authoritative — this is content, not redesign.

## Scope

- **Architecture** (`_system/docs/architecture/`, 6 files, Arc42)
- **Operator** (`_system/docs/operator/`, 24 files, Diátaxis)
- **LLM orientation map** (`_system/docs/llm-orientation/orientation-map.md`)

## Primary Drift Identified

- **Skills:** doc says 22, actual 20. Removed: excalidraw, lucidchart, meme-creator, obsidian-cli. Added: critic, deliberation.
- **Subagents:** doc says 3, actual 4. Added: deliberation-dispatch.
- **Model routing:** Tess Voice Haiku 4.5 → Kimi K2.5 / Qwen 3.6 failover; Tess Mechanic qwen3-coder → Nemotron.
- **Services:** email triage shut down 2026-04-10 — architecture 04 process model is wrong.
- **Domains:** `lifestyle` added as 9th canonical domain.
- **New subsystems to mention:** Quartz v4 vault mobile access, tess-v2 Amendment Z interactive dispatch, Mission Control M3.1 feed density redesign, compound engineering enhancements (track schema, conditional review routing), attention-manager plans integration.

## Workflow

SPECIFY → PLAN → ACT (knowledge-work, three-phase). Same as overhaul project.

## Milestones

- **M1** (0 sessions): Staleness survey closeout — validate 4 unknowns via live state checks.
- **M2** (3 sessions, 6 tasks): Architecture refresh, sequential 01 → 02 → 04 → 03 → 05 → 00.
- **M3** (2 sessions, 3 tasks): Operator refresh in batches — reference, how-to, tutorials+explanation.
- **M4** (0.5 session, 1 task): Orientation map refresh — recount tokens, update tables.
- **M5** (0 sessions): Close-out consistency check.

**Total: 12 tasks, ~5-6 sessions.** Much thinner than overhaul's 35 tasks × 14 sessions — content refresh, not greenfield drafting.

## Key Constraints

- Ceremony budget: surgical edits over rewrites; no new files unless a gap blocks accurate refresh
- Preserve three-tier authority model (design spec → architecture → version history)
- Use Edit (not Write) to preserve frontmatter
- Cross-consistency: skill counts must match across architecture, operator reference, and orientation map

## Risk Profile

- 4 tasks medium risk (building-blocks inventory, deployment process model, runtime views against tess-v2 state, how-to runbooks)
- 8 tasks low risk
- Peer review: skipped (MINOR — content refresh within validated structure)

## Out of Scope

Creating new sections or files; restructuring Diátaxis quadrants; updating the design spec; updating NotebookLM notebooks; updating CLAUDE.md or skill definitions; updating claude-ai-context.md (handled by session-end protocol).
