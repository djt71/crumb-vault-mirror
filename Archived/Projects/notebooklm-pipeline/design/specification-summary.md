---
project: notebooklm-pipeline
domain: learning
type: summary
skill_origin: systems-analyst
source_updated: 2026-02-18
created: 2026-02-18
updated: 2026-02-18
tags:
  - knowledge-management
  - notebooklm
  - pipeline
---

# Specification Summary — NotebookLM-to-Crumb Knowledge Pipeline

## Core Content

A semi-automated pipeline to flow synthesized knowledge from Google NotebookLM into Crumb's vault as connected, searchable, actionable notes. NotebookLM has no query/export API, so the pipeline is: **versioned query templates** (prompts with dual sentinel markers run by user in NLM) → **Chrome extension export** (markdown) or manual copy-paste fallback → **_inbox/ drop** → **extended inbox-processor** (sentinel detection, frontmatter, deduplication, tag, route) → **Sources/ directory** (organized by source type, cross-linked via mandatory #kb/ tags).

New `knowledge-note` document type with: `source` metadata block (stable `source_id` for deduplication, versioned `query_template`, optional `canonical_url` and `queried_at` for provenance), `note_type` field (v1: `digest | extract`; concept-map, argument-map, data-table planned for v2), and `scope` field. One query = one note.

Physical storage always `Sources/[type]/`. `domain:` drives future MOC/backlinks, not routing. Cross-domain discovery through mandatory `#kb/` tags. Low-citation sources auto-tagged `needs_review`. Dedup on `source_id + note_type + scope` with prompt-and-confirm behavior (update, version, or skip).

Templates use dual sentinel (HTML comment + plain text) for detection resilience. Promoted from project to `docs/templates/notebooklm/` after validation.

## Key Decisions

- **No full automation** — Chrome extensions + copy-paste fallback; no API
- **Dual sentinel detection** — HTML comment + plain-text line; parser accepts either
- **v1 scope: digest + extract only** — concept-map, argument-map, data-table deferred to v2
- **Source dedup with user control** — prompt on duplicate: update in-place, create version, or skip
- **Dedicated Sources/ directory** — `domain:` for MOC/backlinks, not physical routing
- **Mandatory #kb/ tags** — primary cross-domain discovery; vault-check enforced
- **Quality gate** — `needs_review` for low-citation source types
- **Template versioning + lifecycle** — version suffix, backward-compatible parser, promotion to durable location

## Interfaces/Dependencies

- **Upstream:** Google NotebookLM (consumer + AI Pro, ~50 daily query limit), Chrome extensions (verify before parser)
- **Internal:** inbox-processor (extend), file-conventions.md (new type), vault-check.sh (validate type + mandatory kb/ tags)
- **Downstream:** kb/ tag graph, domain summaries, future MOCs, project context

## Next Actions

1. Move to PLAN phase — detail implementation approach for 7 tasks (NLM-001 through NLM-007)
2. **Highest priority:** NLM-003 Phase 1 — Chrome extension verification + golden fixtures (minimum: 1 book, 1 article, 1 podcast/video, 1 messy export, 1 short output)
