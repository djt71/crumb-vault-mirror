---
project: book-scout
domain: software
type: summary
skill_origin: systems-analyst
created: 2026-02-28
updated: 2026-02-28
source_updated: 2026-02-28
tags:
  - openclaw
  - tess
  - automation
  - research-library
---

# Book Scout — Specification Summary

## Core Content

Book Scout gives Tess the ability to search, download, and catalog books from Anna's Archive on Danny's behalf via Telegram. Danny sends a query (topic, title, or bulk list), Tess searches the API and presents candidates, Danny approves, and Tess downloads the files to `/Users/tess/research-library/` organized by subject. After download, Tess writes a catalog JSON to `_openclaw/tess_scratch/catalog/inbox/`, which Crumb processes into a source-index note in `Sources/books/`. These notes integrate with the vault's knowledge graph and serve as the handoff point for batch-book-pipeline's digest processing.

The architecture is deliberately simple: two OpenClaw tools (`book_search`, `book_download`), inline downloads via curl with constraints (100 MB size cap, 5 min timeout, .partial file pattern, max 10 per batch), and a file-based catalog handoff with a robust protocol (atomic writes, dedup, processing states, cleanup). No separate download service, no bridge dependency. The project is gated on Anna's Archive API key arrival (donation in progress), with explicit kill/pivot criteria if M0 research reveals the API doesn't exist or can't support the design.

## Key Decisions

- **AD-1:** Inline download with constraints (no separate launchd service) — occasional-use personal library doesn't justify the infrastructure. Size cap, timeout, .partial files, batch limits.
- **AD-2:** File-based catalog handoff via `tess_scratch/catalog/` with robust protocol (atomic writes, dedup, inbox/processed/failed states) — avoids reopening the bridge project (DONE phase, hard-coded operation allowlist)
- **AD-3:** Research library under tess user (`/Users/tess/research-library/`) — no cross-user permission complexity
- **Format preference:** PDF preferred — filter/rank search results to prioritize PDF; flag non-PDF formats for operator decision. Aligns with BBP (PDF-only processing).
- **Tool implementation:** Native OpenClaw tool (Node.js), consistent with x-feed-intel/FIF patterns
- **Download client:** curl baseline, aria2c as optional upgrade
- **Source-index schema:** Canonical file-conventions.md schema with `domain: learning`, `skill_origin: book-scout`. Subject→tag mapping defined.

## Interfaces / Dependencies

- **Anna's Archive JSON API** — external, donation-gated, response schema unknown until M0 research. Kill criteria defined for BSC-001.
- **OpenClaw** — tool registration (existing pattern from FIF)
- **Vault** — source-index note creation per file-conventions.md §Source Index Notes (schema reconciled in spec §6.1)
- **batch-book-pipeline** — downstream, independent; handoff via source-index note existence
- **crumb-tess-bridge** — explicitly NOT a dependency (AD-2)
- **_openclaw/tess_scratch/catalog/** — new subdirectory tree (inbox/processed/failed) for catalog handoff

## Next Actions

1. ~~Peer review the specification~~ Done — round 1 complete, must-fix and should-fix items applied (r1)
2. Wait for API key arrival (blocks M0 research)
3. BSC-002 (environment validation) can proceed immediately
4. After M0: advance to PLAN phase
