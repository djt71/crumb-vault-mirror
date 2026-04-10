---
type: design
project: knowledge-navigation
domain: software
status: draft
created: 2026-02-25
updated: 2026-02-25
skill_origin: compound
confidence: medium
topics:
  - moc-crumb-architecture
tags:
  - kb/software-dev
  - obsidian
  - knowledge-navigation
---

# Obsidian Bases — Evaluation for Knowledge Navigation

Obsidian Bases (`.base` files) provide queryable views over typed-frontmatter notes. Crumb has all the prerequisites — this note evaluates Bases as the visual/discovery layer for knowledge-navigation Phase 4.

## What Bases Are

`.base` files are YAML-defined dynamic views over vault notes (core plugin, available since late 2025). A Base can filter by properties (including `type`), display as tables or cards, compute formulas, roll up linked values, and summarize across notes. Bases don't restructure files — they're views over existing notes queried via frontmatter properties.

## Crumb's Foundation

Crumb already implements the prerequisites:

- `type` frontmatter on every document (file-conventions.md taxonomy)
- vault-check.sh validates required frontmatter fields
- Templates for each document type
- Obsidian CLI queries by property already operational
- MOC architecture (knowledge-navigation Phases 1-3) organizes knowledge notes via `topics` frontmatter

## Potential Applications

| Base | Filter | Value |
|------|--------|-------|
| Project task dashboard | `type: task`, group by project | Visual task tracking |
| Knowledge base browser | `#kb/` tags, sort by updated | Knowledge discovery |
| Staleness detection | Sort by `updated`, filter age > threshold | Maintenance hygiene |
| Cross-project design index | `type: specification` | Design overview |
| MOC member view | Filter by `topics` property | Dynamic MOC display |

These overlap with functions currently served by Obsidian CLI queries and grep, but Bases provide persistent, visual, in-vault views accessible from the Obsidian GUI.

## Relevance to Knowledge Navigation

The knowledge-navigation project (Phases 1-3 complete) built MOC architecture linking knowledge notes via `topics` frontmatter. Bases could serve as the **visual layer** for MOCs — a `.base` file for each MOC that dynamically displays its member notes.

## Open Questions

- Does Crumb's hierarchical folder structure (Projects/Domains/Sources/) interact well with Bases, or does the flat-note pattern work better?
- Can agents create/update `.base` files via CLI, or is it GUI-only?
- What's the Obsidian Sync behavior for `.base` files?

## Source

@intellectronica (Eleanor Berger) — agentic Obsidian architecture pattern (2026-02-22). Also references kepano's vault template and obsidian-skills repo. Kepano confirmed "headless sync will come" — relevant to vault-mirror if Obsidian Sync gains headless mode.
