---
project: book-scout
domain: software
type: action-plan
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

# Book Scout — Action Plan

> **Post-review revision (r1):** Applied 2 must-fix and 8 should-fix items from peer review round 1 (2026-02-28). See `reviews/2026-02-28-action-plan.md` for full findings.

## Milestone 0: Research & Environment Setup

**Goal:** Validate that the Anna's Archive API supports the designed flows and that the local environment is ready for tool development.

**Success criteria:**
- API endpoints documented with request/response schemas
- Search and download flows validated manually (curl) across multiple mirror domains
- Rate limits, download URL lifetime, rights metadata, and required HTTP headers documented
- Kill/pivot decision made (proceed, pivot, or cancel)
- Local environment confirmed: directories created, permissions correct (including cross-user atomic rename), Keychain access validated, disk budget documented

### Phase 0.1: API Research (BSC-001)

Critical path. The entire project depends on the API's actual shape matching assumptions A1–A6. Research with live API key using curl.

**Approach:**
1. Find API documentation (Anna's Archive docs, community references)
2. Validate search endpoint — query by title, author, topic
3. Validate download URL retrieval — document ID → downloadable URL
4. Document response schemas (exact JSON structure)
5. Test rate limits (rapid sequential queries)
6. Characterize download URL lifetime (immediate vs. time-limited)
7. Check for rights metadata in responses
8. Test multiple mirror domains (.li, .gs, .org) — capture required HTTP headers (User-Agent, Accept), confirm redirect behavior, confirm large-file download stability
9. Record minimal reproducible curl commands for search and download
10. Apply kill/pivot criteria if any blockers found

**Risk:** Medium — entire project depends on API shape. Mitigated by explicit kill/pivot criteria in spec §14.

### Phase 0.2: Environment Validation (BSC-002)

Parallel with Phase 0.1. No API dependency.

**Approach:**
1. Create `/Users/tess/research-library/` with subject subdirectories
2. Create `_openclaw/tess_scratch/catalog/` directory tree (inbox/processed/failed)
3. Verify curl works for downloads from AA (test with a known URL if available from Phase 0.1)
4. Check aria2c availability (informational only — no functional dependency unless operator opts in)
5. Document disk space baseline
6. Set file permissions (tess owns library, crumbvault group can read)
7. Test cross-user atomic rename: tess writes file, renames atomically, verify crumb user can read via crumbvault group perms
8. Validate Keychain item `book-scout.annas-archive-api-key` is readable non-interactively from agent context (no UI prompt)

**Risk:** Low.

### Milestone 0 Gate

Decision point: **proceed / pivot / cancel** based on API research findings. Present results to operator before advancing to M1.

## Milestone 1: Search Tool

**Goal:** Tess can search Anna's Archive via Telegram and present structured results to Danny.

**Success criteria:**
- `book_search` tool registered in OpenClaw
- Search by query returns structured results with metadata, PDF format prioritized
- Results formatted correctly for Telegram (single and bulk modes), non-PDF flagged
- API key read from Keychain, never logged

### Phase 1.1: Implement book_search Tool (BSC-003)

Core search implementation. Native OpenClaw tool (Node.js), following FIF/x-feed-intel tool patterns.

**Approach:**
1. Study existing OpenClaw tool registration (FIF pattern) — determine module structure
2. Implement HTTP client for AA search endpoint (based on M0 research)
3. Parse API responses into structured result objects with explicit schema fields: title, author, year, format, file_size_bytes, source_library, rights_info, aa_doc_id, md5
4. Implement PDF format prioritization — rank PDF results first per spec §8.1
5. Read API key from Keychain at invocation time
6. Handle API errors, timeouts, empty results gracefully
7. Register tool in OpenClaw config

**Risk:** Medium — first integration with AA API in code. Mitigated by M0 research validating the API shape first.

### Phase 1.2: Telegram Formatting (BSC-004)

Format search results for Telegram delivery. Depends on BSC-003 for result structure.

**Approach:**
1. Implement numbered-list format per spec §4.5
2. Handle single-query vs. bulk-list input modes with full spec §4.5 parsing rules (delimiter support for `-`/`—`/`by`/`,`, `#` comment lines, blank line handling, echo parsed count before searching)
3. Non-PDF formats clearly flagged in result display
4. Edition grouping for specific-title searches
5. Respect Telegram message length limits (split if needed)
6. Test with representative result sets

**Risk:** Low.

## Milestone 2: Download Tool

**Goal:** Tess can download approved books, organize them in the research library, and write catalog entries for Crumb.

**Success criteria:**
- `book_download` tool downloads files via curl to correct library paths with PDF header validation
- MD5 verification when available
- Catalog JSON written to `_openclaw/tess_scratch/catalog/inbox/` with atomic write protocol
- Download failures reported clearly with retry support

### Phase 2.1: Download Execution and File Organization (BSC-005a)

Core download mechanics and file management. Split from original BSC-005 per review feedback — this task handles the download pipeline, BSC-005b handles catalog generation.

**Approach:**
1. Implement download URL retrieval from AA API (doc ID → URL, using aa_doc_id from search results)
2. Implement curl-based download with .partial file pattern
3. File organization: author-lastname-short-title naming, subject directory routing
4. PDF header validation — verify first bytes are `%PDF` to catch HTML error pages saved as .pdf
5. MD5 verification against API-reported hash
6. Implement download constraints (100MB confirm gate, 5min timeout)
7. Handle filename collisions (append year when same author+short-title)

**Risk:** Medium — download pipeline with multiple validation steps. Mitigated by sequential execution and .partial file safety pattern.

### Phase 2.2: Catalog Generation and Handoff (BSC-005b)

Catalog JSON generation and file-based handoff protocol. Depends on BSC-005a for downloaded files.

**Approach:**
1. Implement catalog JSON generation per spec §6 schema
2. Implement atomic write protocol for catalog handoff (tmp → rename)
3. Implement dedup check (inbox/ and processed/ directories)
4. Enforce max 10 files per invocation
5. Sequential download with per-item progress reporting

**Risk:** Medium — atomic write and dedup logic. Mitigated by spec §4.6 defining exact protocol.

### Phase 2.3: Download Notifications (BSC-006)

Telegram-facing reporting layer for download results. Depends on BSC-005b.

**Approach:**
1. Success reporting: count, file paths, completion message
2. Failure reporting: per-item reason, retry instructions
3. Progress updates during bulk downloads ("3/10 complete...")
4. Retry command support for failed items (accepts item list)

**Risk:** Low.

## Milestone 3: Vault Integration

**Goal:** Catalog entries produced by Tess are processed into vault source-index notes, and the BBP handoff works end-to-end.

**Success criteria:**
- Crumb reads catalog JSONs and creates source-index notes in `Sources/books/`
- Notes pass vault-check
- BBP can discover and process books acquired through Book Scout

### Phase 3.1: Crumb Catalog Processor (BSC-007)

Crumb-side processing of catalog JSON into source-index notes.

**Approach:**
1. Implement catalog inbox reader (scan `inbox/`, skip `.tmp-*`)
2. Validate catalog JSON against spec §6 schema
3. Map subjects → `#kb/` tags → topics using spec §7.1 table
4. Generate source-index note from template (spec §6.1)
5. Run vault-check on created notes
6. Move processed JSONs: inbox/ → processed/, failed → failed/
7. Log results to run-log

**Risk:** Medium — schema reconciliation between catalog JSON and source-index note. Mitigated by spec §6.1 defining exact mapping.

### Phase 3.2: BBP Handoff Validation (BSC-008)

Validation that the end-to-end pipeline works: Book Scout → source-index → BBP processing.

**Approach:**
1. Verify BBP can discover source-index notes without child knowledge notes
2. Verify BBP can locate PDF via file_path in source-index body metadata
3. Run one end-to-end test: acquire book → catalog → source-index → BBP digest
4. Document any integration adjustments needed

**Risk:** Low — BBP already processes source-index notes from other sources.

## Milestone 4: Hardening

**Goal:** Production-ready error handling, edge cases covered, Tess knows how to use the tools.

**Success criteria:**
- All error scenarios handled gracefully (API timeout, disk full, duplicates, Telegram overflow)
- Tess SOUL.md updated with Book Scout capability
- Tool usage documented

### Phase 4.1: Error Handling (BSC-009)

Systematic coverage of edge cases and failure modes across all components. Depends on BSC-003, BSC-004, BSC-005a, BSC-005b, BSC-006, BSC-007.

**Approach:**
1. API failures: timeout, invalid response, rate limiting
2. Download failures: URL expiration, disk full, network interruption
3. Catalog failures: duplicate detection (same source_id already in vault)
4. Telegram: message length overflow for large result sets, progress update edge cases
5. Disk space: pre-download check, warn <1GB, abort <500MB

**Risk:** Low — mostly adding guards to existing code paths.

### Phase 4.2: SOUL.md & Documentation (BSC-010)

Update Tess's instructions and document the complete system.

**Approach:**
1. Update Tess SOUL.md with Book Scout capability description
2. Document tool invocation patterns and expected behavior
3. Document catalog handoff protocol for Crumb operators
4. Verify Tess can use tools correctly via test conversation

**Risk:** Low.

## External Code Repository

Per `project_class: system`, code lives outside the vault. Initialize during M1 Phase 1.1:
- Evaluate whether to use existing OpenClaw workspace or create `~/openclaw/book-scout/`
- Decision depends on FIF's tool registration pattern (is the tool a separate repo or part of OpenClaw config?)

## Iteration Budget

Per solution pattern "Budget Time for Live Deployment Iteration" (claude-print-automation-patterns.md): expect 4–8 iterations total across M1 and M2 for first live deployment of search and download tools. Each iteration reveals prompt-model contract gaps that mocks can't catch. Budget this explicitly — the first successful Telegram interaction is the real validation, not the unit tests.

## Dependency Graph

```
BSC-001 (API research) ──┬──► BSC-003 (search tool) ──► BSC-004 (formatting)
                         │
                         ├──► BSC-005a (download+files) ──► BSC-005b (catalog+handoff) ──► BSC-006 (notifications)
                         │                                         │
BSC-002 (env setup) ─────┘                                         ▼
                                                  BSC-007 (catalog processor) ──► BSC-008 (BBP handoff)
                                                                                        │
                                                                                        ▼
                                    BSC-009 (error handling: depends on BSC-003–007) ──► BSC-010 (docs)
```

Note: BSC-002 has no API dependency and can run in parallel with BSC-001. BSC-003 and BSC-005a can be developed in parallel after M0, but sequential is recommended since BSC-005a builds on BSC-003's API client code and consumes aa_doc_id from search results.
