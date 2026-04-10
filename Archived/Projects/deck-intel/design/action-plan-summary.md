---
type: summary
project: deck-intel
domain: software
status: active
created: 2026-03-14
updated: 2026-03-14
source_updated: 2026-03-14
skill_origin: action-architect
tags:
  - summary
  - action-plan
---

# Deck Intel — Action Plan Summary

**Parent document:** action-plan.md

## Overview

3 milestones, 8 tasks. Build the skill, validate against real files, then batch test and polish.

## Milestones

- **M1 (Skill Build):** Install dependencies (PyMuPDF, LibreOffice), verify markitdown, write SKILL.md, check overlay index. 4 tasks.
- **M2 (Single File Validation):** Test against real PPTX and PDF. Validate full pipeline: extraction, image preservation, synthesis, MOC routing, deletion safety gate. 2 tasks.
- **M3 (Batch + Polish):** Batch processing test (2-3 files), refinement based on real extraction experience. 2 tasks.

## Key Decisions Made

- **Q1 resolved:** Knowledge note body uses deck-intel structure (Key Intelligence → Actionable Items → Shelf Life → Source Notes), not NLM book digest structure.
- **Q2 resolved:** Subdirectory organization deferred. Tags and search sufficient initially.
- **D6 updated:** Diagrams preserved as images in `_attachments/`, not recreated in Mermaid. diagram-capture runs in composable mode.

## Dependencies

- PyMuPDF and LibreOffice not currently installed — DI-001 handles this
- markitdown available at `/Users/tess/.local/bin/markitdown`
- diagram-capture skill exists and defines composable interface

## Risk Profile

Low overall. Skill build is well-scoped from spec. Main risk is markitdown extraction quality on real vendor decks (mitigated by validation tasks with real files).
