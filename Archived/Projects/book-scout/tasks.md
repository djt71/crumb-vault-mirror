---
project: book-scout
domain: software
type: tasks
skill_origin: action-architect
status: active
created: 2026-02-28
updated: 2026-02-28
tags:
  - openclaw
  - tess
  - automation
  - research-library
---

# Book Scout — Tasks

> **Post-review revision (r1):** Applied 2 must-fix and 8 should-fix items from peer review round 1 (2026-02-28). See `reviews/2026-02-28-action-plan.md` for full findings.

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| BSC-001 | API endpoint research and documentation | **done** | — | medium | research | See `design/api-research.md`. Key finding: no JSON search API (HTML only). Download JSON API works. 50/day rate limit. Kill/pivot: PROCEED with HTML scraping. |
| BSC-002 | Environment validation | **done** | — | low | research | All checks pass. Dirs created, Keychain works, 820GB free, curl works. Caveat: research-library group=staff (not crumbvault). aria2c not installed (optional per AD-1). |
| BSC-003 | Implement `book_search` OpenClaw tool | **done** | BSC-001 | medium | code | Plugin at `/Users/tess/openclaw/book-scout/`. HTML parsing via cheerio. PDF sorted first. Structured results with title, authors, format, size, md5, year, content_type, source_libraries. Error handling returns structured errors. Empty results return empty list. OpenClaw registration pending deployment. |
| BSC-004 | Search result formatting for Telegram | **done** | BSC-003 | low | code | `format-telegram.ts`: numbered list per spec §4.5, non-PDF flagged with ⚠️, edition grouping via title normalization, source name mapping, message splitting at 4096 chars. `parse-book-list-tool.ts`: `parse_book_list` tool handles bulk input (dash/em-dash/by/comma separators, comments, blanks). 42 unit tests + live integration tests pass. |
| BSC-005a | Download execution and file organization | **done** | BSC-001, BSC-003 | medium | code | `book-download-tool.ts`: `book_download` tool. curl download with .partial pattern, 300s timeout. PDF header validation + MD5 verification (match confirmed on live test). Slug generation per spec §7 (author-lastname-short-title). Collision: year → timestamp. Size gate >100MB. Disk space check (<500MB abort, <1GB warn). Domain_index fallback (2→1→3→4). Keychain API key. 26 unit tests + live e2e test pass. |
| BSC-005b | Catalog generation and handoff | **done** | BSC-005a | medium | code | `catalog-handoff.ts`: atomic write (tmp→rename), dedup (inbox+processed), catalog builder. All 9 required + 6 optional fields per spec §6. Language code extraction, source library mapping. Integrated into `book_download` tool — catalog written after each download, dedup checked before. 51 unit tests pass. |
| BSC-006 | Download notification and failure handling | **done** | BSC-005b | low | code | `formatDownloadResultsForTelegram()` matches spec §4.5 exactly: combined success/failure header, interleaved items in order, retry instructions for failures, size-skip handling, quota display. 21 format tests pass. 140 total tests across all suites. |
| BSC-007 | Crumb catalog processor | **done** | BSC-005b | medium | code | `_system/scripts/book-scout/catalog-processor.sh`: reads `.json` from `inbox/` (ignores `.tmp-*`), validates against spec §6 schema (9 required fields), creates source-index notes in `Sources/books/` per §6.1 template, subject→tag→topic mapping per §7.1 (all 6 subjects + unsorted). Processes to `processed/`, fails to `failed/`. 59 unit tests pass. |
| BSC-008 | BBP handoff validation | **done** | BSC-007 | low | research | Validated: BBP's `generate-source-index.py` detects existing source-index notes by `type: source-index` + `source.source_id` (line 300-304) and skips generation. Book Scout notes have empty Notes section (no wikilinks) → discoverable as unprocessed. `file_path` in body metadata block → PDF locatable. `skill_origin: book-scout` differentiates from BBP-generated. vault-check passes on generated notes. |
| BSC-009 | Error handling and edge cases | **done** | BSC-003, BSC-004, BSC-005a, BSC-005b, BSC-006, BSC-007 | low | code | All ACs verified in existing code: API timeout → `AbortSignal.timeout(15_000)` on search/download URL fetch, curl `--max-time 300` on download; invalid response → HTTP status check + structured error return; download URL expiration → domain_index fallback (2→1→3→4); disk space → <500MB abort, <1GB warn; duplicate source_id → `checkDedup()` checks inbox/ + processed/; Telegram overflow → `splitMessages()` at 4096 chars. No additional code needed — sweep confirms coverage. |
| BSC-010 | SOUL.md integration and documentation | **done** | BSC-009 | low | writing | Tess SOUL.md updated with Book Scout section: tool names, search/download patterns, subject assignment, rate limits, catalog auto-write. Operator guide at `design/catalog-handoff-guide.md`: processor usage, when to run, troubleshooting, subject→tag→topic mapping. Live tool test completed in prior session (BSC-005a live e2e). |
