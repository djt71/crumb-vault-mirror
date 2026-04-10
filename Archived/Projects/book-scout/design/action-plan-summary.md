---
project: book-scout
domain: software
type: summary
skill_origin: action-architect
status: active
created: 2026-02-28
updated: 2026-02-28
source_updated: 2026-02-28
tags:
  - openclaw
  - tess
  - automation
  - research-library
---

# Book Scout — Action Plan Summary

> **Post-review revision (r1):** BSC-005 split into BSC-005a/005b, PDF preference added to AC, acceptance criteria tightened across 6 tasks.

## Core Content

11 tasks across 4 milestones (BSC-005 split into 005a/005b per review). Critical path runs through BSC-001 (API research) — everything except BSC-002 depends on it. BSC-002 (environment setup) can run in parallel.

**M0 — Research & Environment Setup (BSC-001, BSC-002):** Validate the Anna's Archive API against spec assumptions A1–A6, document endpoints and schemas, test multiple mirror domains and download stability. Set up local directories and permissions, validate cross-user atomic rename and Keychain non-interactive access. Hard gate: proceed/pivot/cancel decision based on API findings.

**M1 — Search Tool (BSC-003, BSC-004):** Implement `book_search` as a native OpenClaw Node.js tool with explicit result schema (including aa_doc_id for download tool). PDF format prioritized in results. Format for Telegram delivery (single-query and bulk-list modes with full §4.5 parsing rules).

**M2 — Download Tool (BSC-005a, BSC-005b, BSC-006):** BSC-005a: curl-based download with .partial file safety, PDF header validation, MD5 verification, filename collision handling. BSC-005b: catalog JSON generation with atomic writes to `_openclaw/tess_scratch/catalog/inbox/`, dedup. BSC-006: Telegram notifications for success/failure with retry support.

**M3 — Vault Integration (BSC-007, BSC-008):** Crumb-side catalog processor creates source-index notes from catalog JSONs. BBP handoff validation confirms end-to-end flow works.

**M4 — Hardening (BSC-009, BSC-010):** Error handling across all components (BSC-003–007 dependencies), SOUL.md integration, documentation.

## Key Decisions

- Sequential milestones (not parallel) — each builds on the previous
- BSC-001 + BSC-002 are the only parallel-eligible pair
- BSC-005 split into 005a (download+files) and 005b (catalog+handoff) per review — original exceeded ≤5 file-change scope
- Iteration budget: expect 4–8 live calibration cycles total across M1/M2
- External code repo decision deferred to M1 (depends on FIF tool registration pattern)

## Risk Summary

- **Medium risk:** BSC-001 (API shape unknown), BSC-003 (first API integration in code), BSC-005a (download pipeline), BSC-005b (atomic write + dedup), BSC-007 (schema reconciliation)
- **Low risk:** BSC-002, BSC-004, BSC-006, BSC-008, BSC-009, BSC-010
- **Project-level risk:** M0 gate — if API doesn't support the design, kill/pivot criteria apply
