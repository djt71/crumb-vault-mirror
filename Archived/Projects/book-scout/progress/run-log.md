---
type: run-log
project: book-scout
domain: software
status: active
created: 2026-02-28
updated: 2026-03-04
---

# Book Scout — Run Log

## 2026-02-28 — Session 1: Project Creation + SPECIFY

### Context
- Draft specification found in `_inbox/book-scout-specification.md`
- Assessed as separate project from batch-book-pipeline (different domain, actors, architecture)
- User confirmed project creation, wants full spec process from square one using draft as input

### Context Inventory
1. `Projects/book-scout/design/draft-specification.md` — full draft input
2. `Projects/crumb-tess-bridge/project-state.yaml` — bridge DONE, hard-coded op allowlist
3. `Projects/feed-intel-framework/project-state.yaml` — FIF in TASK (architectural sibling)
4. `_system/docs/protocols/bridge-dispatch-protocol.md` — dispatch schema
5. `_system/docs/solutions/claude-print-automation-patterns.md` — Tess tool patterns
6. `_system/docs/file-conventions.md` — source-index note schema
7. `_system/docs/personal-context.md` — strategic priorities
8. `_system/docs/overlays/overlay-index.md` — no overlays matched

### Actions
- Created project scaffold: `Projects/book-scout/`
- Moved draft spec to `design/` as reference input
- Ran full systems-analyst skill for SPECIFY phase
- Bridge extensibility research: hard-coded allowlist requires spec + code changes for new ops
- User clarifications: API key in progress, tess user owns library, file-based catalog handoff (not bridge)

### Key Architectural Decisions
- AD-1: Inline download (no separate launchd service) — over-engineered for occasional use
- AD-2: File-based catalog handoff via tess_scratch — avoids reopening bridge project
- AD-3: Research library under tess user

### Deliverables
- `specification.md` — formal spec (10 tasks across 4 milestones, gated on API key)
- `specification-summary.md` — summary
- `design/draft-specification.md` — preserved as reference input

### Peer Review — Round 1
- 4/4 reviewers responded (GPT-5.2, Gemini 3 Pro, DeepSeek V3.2, Grok 4.1)
- Verdict: approve with conditions
- Must-fix (2): catalog handoff protocol robustness (A1), source-index schema reconciliation (A2)
- Should-fix (5): download constraints (A3), catalog JSON enrichment (A4), subject-to-tag mapping (A5), disk space threat (A6), BSC-001 kill criteria (A7)
- Deferred (3): duplicate detection, Telegram pagination, non-PDF format handling
- Declined (6): legal compliance gates (constraint), suspend spec until M0 (incorrect), bridge governance (constraint), testing/CI (out-of-scope), API deprecation (overkill), missing tasks (incorrect)
- All 7 action items (A1-A7) applied to spec as revision r1

### User Flag
- Danny wants to consider making the bridge spec more adaptable for new operations in the future (not in scope for book-scout, but potential bridge maintenance item)

### Compound Evaluation
- **Pattern: File-based handoff as bridge alternative.** When the bridge's hard-coded allowlist makes extension expensive, a file-drop protocol with atomic writes, processing states, and dedup is a viable alternative for one-directional fire-and-forget operations. This pattern may recur — any future Tess→Crumb handoff that doesn't need interactive confirmation could use the same protocol. Not yet promoted to solutions/ — needs implementation validation first.
- **Convention confirmed:** Source-index notes use `domain: learning` regardless of the originating project's domain. The note's domain reflects the *artifact's* nature, not the project that created it.
- **Convention confirmed:** `date_ingested` belongs to knowledge-note schema only, not source-index. `created` date serves the same purpose for source-index notes.

### Session Summary
- Created book-scout project (software/system, four-phase workflow)
- Ran full SPECIFY phase via systems-analyst skill
- Key architectural decisions: inline download (AD-1), file-based catalog handoff (AD-2), tess user ownership (AD-3)
- Peer review round 1: 4/4 reviewers, approve with conditions
- Applied 7 action items (2 must-fix, 5 should-fix) as spec revision r1
- Spec ready for PLAN phase, gated on API key arrival (M0)
- BSC-002 (environment validation) can proceed immediately

## 2026-02-28 — Session 2: SPECIFY → PLAN transition

### Context
- API key arrived — stored in Keychain as `book-scout.annas-archive-api-key` (account: tess)
- M0 gate cleared — all tasks now unblocked

### Phase Transition: SPECIFY → PLAN
- Date: 2026-02-28
- SPECIFY phase outputs: specification.md (r1, peer-reviewed), specification-summary.md, design/draft-specification.md (reference input)
- Compound: Completed in Session 1. No new compoundable insights from SPECIFY phase in this session.
- Context usage before checkpoint: low (<50%)
- Action taken: none
- Key artifacts for PLAN phase: specification-summary.md, specification.md (§14 task decomposition)

### Context Inventory
1. `specification-summary.md` — loaded (required)
2. `specification.md` — loaded, §4 architecture, §14 task decomposition (required)
3. `_system/docs/overlays/overlay-index.md` — checked, no overlays match
4. `_system/docs/solutions/claude-print-automation-patterns.md` — loaded (relevant: iteration budgets)
5. No estimation calibration file exists

### Actions
- Ran action-architect skill for PLAN phase
- Created: `design/action-plan.md`, `design/tasks.md`, `design/action-plan-summary.md`
- Added PDF format preference to spec §8.1 and spec summary (user request during planning)

### Peer Review — Round 1
- 4/4 reviewers responded (GPT-5.2, Gemini 3 Pro, DeepSeek V3.2, Grok 4.1)
- Verdict: approve with revisions

**Must-fix (2):**
- A1: Split BSC-005 into BSC-005a (download+files) and BSC-005b (catalog+handoff) — 4/4 consensus
- A2: Add PDF format preference to BSC-003/BSC-004 acceptance criteria — 3/4 consensus

**Should-fix (8):**
- A3: Tighten BSC-003 AC with explicit schema fields including aa_doc_id
- A4: Add bulk-list parsing rules to BSC-004 AC
- A5: Add PDF header validation to download flow
- A6: Add Keychain non-interactive access test to BSC-002
- A7: Add cross-user atomic rename test to BSC-002
- A8: Expand BSC-001 to test mirror domains, HTTP headers, redirect behavior
- A9: Add filename collision test to BSC-005a AC
- A10: Expand BSC-009 dependencies to include BSC-004/BSC-006

**Deferred (2):** Iteration budget calibration (A11), stale file cleanup (A12)
**Declined (10):** Mostly incorrect assumptions about Crumb/Tess being LLM agents (not coded parsers), or issues already resolved (API key arrived, dependencies already in tasks.md)

All 10 action items (A1-A10) applied as revision r1 to action-plan.md, tasks.md, and action-plan-summary.md.

### Compound Evaluation
- **Convention confirmed:** BSC-005 splitting pattern — when a task combines network I/O, disk I/O, and data serialization, split at the "write artifact" boundary (download+verify vs. catalog+handoff). All 4 reviewers converged on this independently. Applicable to future tool tasks that span fetch→process→emit.
- **Pattern noted:** External reviewers consistently misunderstand LLM-agent architectures — they assume coded parsers for selection handling, JSON config files for lookup tables, and explicit state files for conversation memory. ~50% of declined findings stem from this. Not yet promoted to solutions/ — needs more data points across review types.

### Session Summary
- Transitioned SPECIFY → PLAN (API key arrival cleared M0 gate)
- Ran action-architect skill: produced action-plan.md, tasks.md, action-plan-summary.md
- Added PDF format preference to spec §8.1 (user request)
- Peer review round 1: 4/4 reviewers, approve with revisions
- Applied 10 action items (2 must-fix, 8 should-fix) as revision r1
- Key change: BSC-005 split into BSC-005a/005b (4/4 consensus)
- Plan ready for TASK phase; M0 (BSC-001 + BSC-002) is next
- **Next session:** Transition PLAN → TASK, then execute M0 — BSC-001 (API research with live key) and BSC-002 (environment setup) in parallel

## 2026-02-28 — Session 3: PLAN → TASK transition + M0 execution

### Phase Transition: PLAN → TASK
- Date: 2026-02-28
- PLAN phase outputs: action-plan.md (r1), tasks.md (r1), action-plan-summary.md (r1)
- Compound: Completed in Session 2. No new compoundable insights from PLAN phase.
- Context usage before checkpoint: <50% (fresh session)
- Action taken: none
- Key artifacts for TASK phase: tasks.md (BSC-001, BSC-002 first), specification.md §4-§8

### Context Inventory
1. `specification.md` — full spec (required for task execution)
2. `design/tasks.md` — task definitions with acceptance criteria
3. `design/action-plan-summary.md` — milestone structure
4. `/tmp/annas-mcp/internal/anna/anna.go` — reference implementation (Go, HTML scraping)

### BSC-001: API Endpoint Research — COMPLETE

**Key finding: No JSON search API exists.** The spec assumed JSON search (A1) — in reality, search returns HTML. Download URL retrieval IS a JSON API and works perfectly.

**Endpoints documented:**
- Search: `GET /search?q={query}&content={type}` → HTML (requires HTML parsing)
- Download: `GET /dyn/api/fast_download.json?md5={hash}&key={key}&domain_index={n}` → JSON

**Rate limits:** 50 downloads/day, per-unique-MD5 (same MD5 doesn't re-decrement)

**Download servers:** 5 available via domain_index (0-4). domain_index=0 fails on macOS (TLS 1.3 vs LibreSSL). domain_index=1-4 all work.

**Mirror domains:** Only annas-archive.li responds; .pm and .in timeout.

**Download URL characteristics:** Direct HTTP, no CAPTCHA/session, token-based (time-limited), Accept-Ranges supported, PDF header verified.

**Assumption validation:** A1 FALSE (HTML not JSON), A2 TRUE, A3 PARTIAL, A4 TRUE, A5 TRUE, A6 TRUE.

**Kill/pivot decision: PROCEED.** One architectural change required: BSC-003 must use HTML scraping (cheerio in Node.js) instead of JSON API. All existing implementations use this approach.

**Deliverable:** `design/api-research.md`

### BSC-002: Environment Validation — COMPLETE

| Check | Result | Notes |
|---|---|---|
| Research library dirs | PASS (created) | `/Users/tess/research-library/` with 7 subject subdirs |
| Catalog handoff dirs | PASS (created) | `_openclaw/tess_scratch/catalog/{inbox,processed,failed}/` |
| Ownership/permissions | PASS (caveat) | Library group is `staff` not `crumbvault` — world-readable so functional, but note for future |
| Atomic rename test | PASS | Same-filesystem rename works as expected |
| Keychain access | PASS | Non-interactive read confirmed |
| Disk space | PASS | 820 GB available |
| aria2c | N/A | Not installed; spec says curl-first (AD-1), aria2c is optional upgrade |
| curl | PASS | 8.7.1 (LibreSSL 3.3.6) — TLS caveat for some download servers |

**Caveat noted:** Research library group is `staff` (not `crumbvault`). Currently world-readable so cross-user access works, but if permissions tighten, ACL adjustment needed. Not a blocker.

### Spec Update (r2)
- Updated §5.1: JSON search API → HTML search + JSON download URL
- Updated §8.2: Added cheerio dependency, HTML scraping approach
- Updated §9: Assumptions A1-A6 validated/invalidated, unknowns U1-U6 resolved
- Noted AA blog post confirmation: "We don't yet have a search API" (llms-txt.html)

### BSC-003: Implement book_search Tool — COMPLETE

**Architecture finding:** OpenClaw has two extension mechanisms — skills (prompt-based) and plugins (TypeScript, `api.registerTool()`). FIF/x-feed-intel are standalone apps, NOT OpenClaw plugins. Book-scout follows the plugin pattern (spec assumption A7 partially validated — HTTP-calling tools work fine, but the pattern is plugins, not the FIF adapter pattern).

**Implementation:**
- External code repo: `/Users/tess/openclaw/book-scout/` (git initialized)
- Plugin structure: `index.ts` + `openclaw.plugin.json` + `src/book-search-tool.ts`
- HTML parsing via cheerio — extracts title, authors, publisher, language, format, size, year, content_type, source_libraries, md5
- PDF results sorted first (priority: PDF > EPUB > MOBI > DJVU)
- Tested against live AA search: "meditations marcus aurelius" (10 results), "republic plato" (10 results) — all fields parsed correctly
- Error handling: HTTP errors, timeouts, empty results all return structured JSON

**Pending:** Plugin registration in `openclaw.json` (requires openclaw user config edit — deferred to deployment)

### Compound Evaluation
- **Pattern: HTML scraping as API substitute.** When an API provider has no JSON search endpoint but does have a structured HTML page, HTML scraping with cheerio (Node.js) or colly (Go) is viable for low-volume personal tools. Key mitigations: browser User-Agent, isolated parsing logic, accept fragility. All existing AA integrations follow this pattern. May apply to future external service integrations where only a web UI exists.
- **Pattern: OpenClaw plugin vs skill distinction.** Skills (SKILL.md) are prompt-based instructions teaching an agent to use existing tools. Plugins (TypeScript, `api.registerTool()`) are programmatic extensions with typed schemas. The spec's reference to "FIF adapter pattern" was incorrect — FIF is a standalone app, not a plugin. Updated spec A7 to reflect this. This distinction matters for any future OpenClaw tool work.
- **Convention: Download quota tracking via API response.** AA's `account_fast_download_info` returns quota state on every call. Per-unique-MD5 counting means repeated requests for the same file don't waste quota. The tool should surface `downloads_left` to Tess so she can inform Danny when quota is running low.
- **Operational note: macOS LibreSSL TLS 1.3 gaps.** `domain_index=0` download server requires TLS 1.3 which LibreSSL 3.3.6 can't handle. This joins the existing macOS operational notes. Workaround: use `domain_index≥1` (or install Homebrew curl with OpenSSL for TLS 1.3 support).

### Session Summary
- Transitioned PLAN → TASK (phase gate committed)
- Completed M0: BSC-001 (API research) + BSC-002 (environment validation) in parallel
- Key M0 finding: No JSON search API — HTML scraping required. Download JSON API works. 50 downloads/day.
- Updated spec to r2 with M0 findings (§5.1, §8.2, §9)
- Completed BSC-003: book_search plugin at `~/openclaw/book-scout/` with cheerio HTML parsing, tested against live site
- External code repo initialized, `repo_path` recorded in project-state
- **Next session:** BSC-004 (search result Telegram formatting), then M2 (BSC-005a/005b/006 download pipeline)

## 2026-02-28 — Session 4: M1–M2 complete (BSC-004 through BSC-006)

*(Context recovered from Session 3 continuation — ran out of context mid-session.)*

### Context Inventory
1. `specification.md` — §4.5 (Telegram interaction), §6 (catalog schema), §7 (naming/subjects)
2. `design/tasks.md` — BSC-004 through BSC-006 acceptance criteria
3. `design/api-research.md` — download API details (M0 output)
4. `/Users/tess/openclaw/book-scout/src/book-search-tool.ts` — existing code

### BSC-004: Search Result Formatting for Telegram — COMPLETE
- `src/format-telegram.ts`: numbered list per §4.5, non-PDF ⚠️ flagging, edition grouping via title normalization, source name mapping, message splitting at 4096 chars
- `src/parse-book-list-tool.ts`: `parse_book_list` tool for bulk input (dash/em-dash/by/comma separators, comments, blanks)
- Updated `book-search-tool.ts` to use formatted output + selection reference (number→md5 mapping)
- 42 unit tests + live integration tests pass

### BSC-005a: Download Execution and File Organization — COMPLETE
- `src/book-download-tool.ts`: `book_download` tool
- curl download with `.partial` pattern, 300s timeout
- PDF header validation + MD5 verification (match confirmed on live test: Enchiridion by Epictetus)
- Slug generation per §7 (author-lastname-short-title), collision resolution: year → timestamp
- Size gate >100MB, disk space check (<500MB abort, <1GB warn), domain_index fallback (2→1→3→4)
- 26 unit tests + live e2e test pass

### BSC-005b: Catalog Generation and Handoff — COMPLETE
- `src/catalog-handoff.ts`: atomic write (tmp→rename), dedup (inbox+processed), catalog builder
- All 9 required + 6 optional fields per spec §6
- Language code extraction, source library mapping
- Integrated into `book_download` tool — catalog written after each download, dedup checked before
- 51 unit tests pass

### BSC-006: Download Notification and Failure Handling — COMPLETE
- `formatDownloadResultsForTelegram()` in format-telegram.ts
- Combined success/failure header, interleaved items in order, retry instructions, size-skip handling, quota display
- 21 format tests pass. 140 total tests across all suites.

### External Repo Commits
- `07c7f93` feat: BSC-004 search result formatting for Telegram
- `926a9a6` feat: BSC-005a download execution and file organization
- `a68a59c` feat: BSC-005b catalog generation and handoff
- `c20976d` feat: BSC-006 download notification and failure handling

## 2026-02-28 — Session 5: M3–M4 complete (BSC-007 through BSC-010)

### Context Inventory
1. `specification.md` — §6.1 (source-index template), §7.1 (subject→tag→topic mapping), §4.6 (catalog handoff)
2. `design/tasks.md` — BSC-007 through BSC-010 acceptance criteria
3. `Sources/books/augustine-confessions-of-st-augustine-index.md` — existing BBP source-index (format reference)
4. `_system/scripts/batch-book-pipeline/generate-source-index.py` — BBP discovery mechanism
5. `/Users/tess/openclaw/book-scout/src/catalog-handoff.ts` — catalog schema/types

### BSC-007: Crumb Catalog Processor — COMPLETE
- `_system/scripts/book-scout/catalog-processor.sh`: bash script
- Reads `.json` from `inbox/` (ignores `.tmp-*`), validates 9 required fields
- Creates source-index notes in `Sources/books/` per §6.1 template
- Subject→tag→topic mapping per §7.1 (all 6 subjects + unsorted)
- Processes to `processed/`, fails to `failed/`
- Handles: empty inbox, duplicate index notes, unsorted (empty tags/topics)
- vault-check passes on generated notes (verified with live test)
- 59 unit tests pass

### BSC-008: BBP Handoff Validation — COMPLETE
- Validated BBP's `generate-source-index.py` detects existing source-index notes by `type: source-index` + `source.source_id` and skips generation
- Book Scout notes have empty Notes section (no wikilinks) → discoverable as unprocessed
- `file_path` in body metadata block → PDF locatable by BBP operator
- `skill_origin: book-scout` differentiates from BBP-generated notes
- Compatible: Book Scout creates index first → BBP processes PDF → digests link back to existing index

### BSC-009: Error Handling and Edge Cases — COMPLETE (sweep)
- All ACs verified in existing code across BSC-003/004/005a/005b/006/007
- No additional code needed — coverage confirmed

### BSC-010: SOUL.md Integration and Documentation — COMPLETE
- Tess SOUL.md updated with Book Scout section (tools, patterns, subject assignment, rate limits)
- Operator guide at `design/catalog-handoff-guide.md`

### Test Summary
- OpenClaw tests: 140 (42 + 26 + 51 + 21 across 4 suites)
- Vault-side tests: 59 (catalog processor)
- Total: 199 tests, all passing

### Compound Evaluation
- **Pattern: File-based handoff validated in implementation.** The tess_scratch inbox→processed→failed pattern from spec §4.6 works well. Atomic write (tmp→rename), dedup (source_id check), and schema validation form a minimal but sufficient protocol for one-directional fire-and-forget handoffs. Ready for promotion to `_system/docs/solutions/`.
- **Convention confirmed: BBP source-index coexistence.** Book Scout and BBP both create source-index notes but with different `skill_origin` values. BBP's generator respects existing notes — no overwrites. The shared `source_id` key enables this coordination without coupling.
- **Observation: bash `set -eu` + empty arrays.** `shopt -s nullglob` with no matches creates an unbound variable under `set -u`. Must check array length *before* iterating. Joins the existing bash gotcha notes.

### Session Summary
- Completed M3 (BSC-007 + BSC-008) and M4 (BSC-009 + BSC-010)
- All 10 book-scout tasks are **done**
- Total: 199 tests passing (140 OpenClaw + 59 vault-side)
- Remaining before DONE: OpenClaw plugin registration, code review
- **Next:** Register plugin in openclaw.json, run code review, transition to DONE

## 2026-02-28 — Session 6: Code Review

### Code Review — milestone BSC-001 through BSC-010
- Scope: full codebase (a565ac2..c20976d) + vault-side catalog-processor.sh
- Panel: Claude Opus 4.6, Codex GPT-5.3-Codex
- Codex tools: npm test, tsc --noEmit, node -e imports, npm ls, file reads (45 commands total)
- Findings: 3 critical, 10 significant, 3 minor, 2 strengths
- Consensus: 6 findings flagged by both reviewers (4 issues, 1 minor, 1 strength)
- Details:
  - [C1/ANT-B1+CDX-F8] CRITICAL: catalog-processor.sh — mkdir -p missing for output dirs
  - [ANT-B4] CRITICAL: catalog-processor.sh — ((PROCESSED++)) crashes under set -e when counter=0
  - [CDX-F1] CRITICAL: package.json — @sinclair/typebox not declared (tool-grounded; works via OpenClaw host)
  - [C2/ANT-B2+CDX-F9] SIGNIFICANT: catalog-processor.sh — YAML injection from unescaped title/author
  - [C3/ANT-F7+CDX-F2] SIGNIFICANT: book-download-tool.ts:285 — path traversal guard prefix bypass
  - [C4/ANT-F5+CDX-F6] SIGNIFICANT: book-download-tool.ts:241 — full-file MD5 read into memory
  - [ANT-F2] SIGNIFICANT: book-download-tool.ts:527 — unsafe Record<string, unknown> casts
  - [ANT-F3] SIGNIFICANT: book-download-tool.ts:158 — API key in URL leaks to error messages
  - [ANT-F4] SIGNIFICANT: book-download-tool.ts:210 — TOCTOU race in resolveFilePath
  - [ANT-F6] SIGNIFICANT: book-search-tool.ts:107 — scraper fragility (silent empty on HTML change)
  - [ANT-B3] SIGNIFICANT: catalog-processor.sh:164 — substring matching for tag/topic dedup
  - [CDX-F3] SIGNIFICANT: format-telegram.ts:281 — catalog status message inaccurate on write failure
  - [CDX-F4] SIGNIFICANT: book-download-tool.ts:412 — size gate bypass with unparseable sizes
- Action: 4 must-fix, 8 should-fix, 3 deferred, 7 declined
- Review note: Projects/book-scout/reviews/2026-02-28-code-review-milestone.md

### Fixes Applied — All 12 Action Items
- **A1** catalog-processor.sh: mkdir -p for output dirs
- **A2** catalog-processor.sh: YAML injection — escape title/author
- **A3** catalog-processor.sh: ((x++)) → $((x + 1)) for set -e safety
- **A4** book-download-tool.ts: path traversal guard — trailing /
- **A5** book-download-tool.ts: streaming MD5 via createReadStream
- **A6** book-download-tool.ts: API key redacted from error messages
- **A7** book-download-tool.ts: removed unsafe Record<string, unknown> casts
- **A8** package.json: @sinclair/typebox as peerDependency
- **A9** book-download-tool.ts: unparseable sizes require force_large
- **A10** book-download-tool.ts + format-telegram.ts: per-item catalog write tracking
- **A11** catalog-processor.sh: space-delimited tag/topic dedup
- **A12** book-download-tool.ts: resolveFilePath timestamp candidates (TOCTOU fix)

### Per-Task Code Review Index
All code tasks covered by milestone review above (panel: Opus + Codex, 16 findings, 12 fixes).

| Task | Type | Review Status |
|---|---|---|
| BSC-002 | research (env validation) | Code Review — Skipped BSC-002 (no code artifact) |
| BSC-003 | code | Code Review — BSC-003 covered by milestone review (findings: ANT-F6 scraper fragility) |
| BSC-004 | code | Code Review — BSC-004 covered by milestone review (no task-specific findings) |
| BSC-005a | code | Code Review — BSC-005a covered by milestone review (findings: C3 path traversal, C4 MD5 memory, ANT-F2 casts, ANT-F3 API key leak, ANT-F4 TOCTOU, CDX-F4 size gate) |
| BSC-005b | code | Code Review — BSC-005b covered by milestone review (findings: CDX-F3 catalog status message) |
| BSC-006 | code | Code Review — BSC-006 covered by milestone review (no task-specific findings) |
| BSC-007 | code | Code Review — BSC-007 covered by milestone review (findings: C1 mkdir, ANT-B4 arithmetic, C2 YAML injection, ANT-B3 dedup) |
| BSC-008 | research (BBP validation) | Code Review — Skipped BSC-008 (no code artifact) |
| BSC-009 | sweep | Code Review — Skipped BSC-009 (verification sweep, no new code) |

### Test Results
- 199/199 passing (140 TypeScript + 59 bash), zero regressions

### Commits
- External: `aa90b3e` fix: code review findings — security, correctness, robustness
- Vault: `c89edcb` fix: book-scout code review — bash fixes + review artifacts

### Compound Evaluation
- **Pattern: Codex CLI flag hallucination recurrence.** Dispatch agent tried `--last-message-file` (documented in agent spec) but the real flag is `-o`/`--output-last-message`. This is the 3rd occurrence of the CLI flag hallucination pattern (after `claude --cwd` and `codex exec --output-last-message`). The agent spec itself is now the vector — hallucinated flags in documentation propagate to every invocation. Fix: verify flags against `--help` when writing agent specs, not just during runtime.
- **Pattern: bash `((x++))` under `set -e` confirmed as recurring.** Already in MEMORY.md (`set -e` gotchas), but this is the first time it appeared in production code written by Claude. The `set -eu` + arithmetic gotcha was known but not caught during implementation. Suggests adding a linting check or MEMORY.md reference during bash code generation.
- **Convention confirmed: Two-reviewer panel value.** Consensus findings (6 issues caught by both) provide high-confidence signal. Unique findings from each reviewer are complementary — Opus catches architectural/security reasoning, Codex catches dependency/tooling issues via execution. The panel structure is validated.

### Session Summary
- Ran full code review on book-scout project (milestone scope, all 10 tasks)
- Two-reviewer panel: Claude Opus (API) + Codex (CLI), both succeeded
- Synthesized findings: 4 must-fix, 8 should-fix, 3 deferred, 7 declined
- Applied all 12 fixes, 199/199 tests passing
- Remaining before DONE: plugin registration in openclaw.json
- **Next:** Register plugin, transition to DONE

## 2026-03-01 — Session 7: Deployment + Model Routing Fix

### Context
- All 10 tasks complete, code review done
- Remaining: plugin registration, gateway deployment, transition to DONE

### Context Inventory
1. `Projects/book-scout/project-state.yaml` — project state
2. `Projects/book-scout/design/tasks.md` — all 10 tasks done
3. `_openclaw/staging/SOUL.md` — Tess SOUL.md with Book Scout section
4. `/Users/openclaw/.openclaw/openclaw.json` — gateway config
5. `/Users/openclaw/.openclaw/agents/voice/agent/auth-profiles.json` — voice agent credentials

### Deployment Issues Resolved (5)
1. **Catalog directory permissions** — `_openclaw/tess_scratch/catalog/{inbox,processed,failed}` needed `g+w` for openclaw user write access
2. **Research library permissions** — `/Users/tess/research-library/` dirs needed `chgrp crumbvault` + `g+w` + setgid
3. **Keychain cross-user access** — API key stored in tess's Keychain, duplicated to openclaw's Keychain
4. **SOUL.md deployment** — copied from `_openclaw/staging/SOUL.md` to live workspace
5. **Plugin registration** — `plugins install --link` rejected (uid ownership check in `checkPathStatAndPermissions`). Fix: copied plugin to workspace extensions dir

### Plugin Issues
- `@sinclair/typebox` peerDependency not resolved in workspace extensions (works inside OpenClaw's node_modules tree). Fix: explicit `npm install @sinclair/typebox` in plugin dir
- Plugin loads with provenance warning — `plugins.allow` configured to silence it

### Model Routing Investigation (bulk of session)
Root cause chain: **billing hiccup → OpenClaw disabled API key with cooldown → silent fallback to Ollama → Qwen hallucinating tool failures**

Diagnostic timeline:
1. Tess claiming tools "aren't available" while logs show successful tool calls — Qwen hallucination pattern
2. All `embedded run start` logs showed `provider=ollama model=tess-mechanic:30b` despite voice agent configured for Haiku
3. Initial theory: missing Anthropic provider in `models.providers` — added, but didn't fix
4. Zombie gateway process holding port 18789 — killed, new instance started, still Ollama
5. Discovered per-agent credential isolation: `agents/{id}/agent/auth-profiles.json` stores actual API keys, separate per agent
6. Voice agent's key had `disabledUntil` cooldown from a billing error — **all requests silently fell through to Ollama**
7. Also found voice agent had a DIFFERENT API key than main agent (different `sk-ant-` suffix)
8. Cleared cooldown → Haiku attempted → "credit balance too low" error (old key)
9. Topped off Anthropic account + cleared cooldown again → **Haiku live and working**

### Key Findings (documented in MEMORY.md)
- **Per-agent credential isolation**: each agent has own auth files, keys can differ
- **Billing-triggered cooldown**: `disabledUntil`/`disabledReason` in auth-profiles.json — silent, no log errors
- **Silent model fallback**: zero logged errors when primary fails — only `provider=` in run start line
- **Model ID exact match**: agent model ID must match provider models[].id exactly
- **`agent model:` startup log misleading**: shows default agent, not per-agent; config readout, not auth test
- **`config set` clobbers permissions**: `rw-r----- crumbvault` → `rw------- staff`

### Live Test
- Tess on Haiku: searched all 10 titles, returned structured results with format/size/source
- Asked correct subject assignment questions per SOUL.md instructions
- Tool calls confirmed via `toolu_` prefix in logs (Anthropic) vs `ollama_call_` (Ollama)

### Compound Evaluation
- **Pattern: OpenClaw silent-failure cascade.** Billing error → credential cooldown → silent fallback → model hallucination. Four layers of abstraction between root cause and visible symptom. No single log line connects them. Diagnostic requires correlating: (1) `provider=` in embedded run logs, (2) `disabledUntil` in per-agent auth-profiles.json, (3) billing status on Anthropic dashboard. This joins the `delivery.to` + `bestEffort` + misleading status triple-silent-failure from 2026-02-25 as a recurring OpenClaw observability gap.
- **Convention: Gateway restart playbook.** Kill via `sudo kill` + launchctl print, verify with `nc -z`, check model with grep on embedded run start. Documented in MEMORY.md for reuse.
- **Observation: `config set` is a destructive operation.** Clobbers file permissions and may introduce unwanted defaults (`contextPruning`, changed `heartbeat.every`). Treat as medium-risk, verify config after use.

### Download Credential Fix
- `book_download` tool calls `security find-generic-password` — works interactively but fails from LaunchDaemon context (login keychain not accessible in system domain)
- Env var via plist also failed: `com.apple.provenance` xattr blocks plist reload, `bootout`/`bootstrap` required but even then env var didn't propagate
- **Fix:** credential file at `/Users/openclaw/.openclaw/credentials/book-scout-api-key` (chmod 600)
- Updated `getApiKey()` with three-tier fallback: env var → credential file → Keychain
- Code change deployed to both source repo and workspace extensions copy

### Download Results
- 9/10 PDFs downloaded successfully to `/Users/tess/research-library/`
  - Fiction (5): eco-name-rose, flaubert-madame-bovary, king-shining, martel-life-pi, weir-martian
  - History (2): abouzeid-no-turning-back, weiner-legacy-ashes-history
  - Science (2): bone-mars-observers-guide, levitt-freakonomics
- 9 catalog JSONs in `_openclaw/tess_scratch/catalog/inbox/` ready for catalog processor
- Resonate (Duarte) — not in this batch, may need separate download

### Additional Findings (documented in MEMORY.md)
- **Plugin ownership check**: `checkPathStatAndPermissions` rejects cross-user plugin links — must copy to workspace extensions
- **Plugin peerDependency isolation**: peerDeps not resolved in workspace extensions, need explicit install
- **Haiku misinterprets tool errors**: re-frames structured errors as "auth" or "token" issues — always ask for exact tool response
- **LaunchDaemon Keychain access blocked**: login keychain not available in system domain — use credential files instead
- **LaunchDaemon plist reload**: kill + KeepAlive does NOT re-read plist — need full bootout + bootstrap

### Commits
- Source: `book-download-tool.ts` updated with credential file fallback (uncommitted — commit pending)

### Compound Evaluation (updated)
- **Pattern: OpenClaw silent-failure cascade.** Billing error → credential cooldown → silent fallback → model hallucination. Four layers of abstraction between root cause and visible symptom. No single log line connects them. Diagnostic requires correlating: (1) `provider=` in embedded run logs, (2) `disabledUntil` in per-agent auth-profiles.json, (3) billing status on Anthropic dashboard. This joins the `delivery.to` + `bestEffort` + misleading status triple-silent-failure from 2026-02-25 as a recurring OpenClaw observability gap.
- **Pattern: macOS daemon credential isolation.** Keychain, env vars, and process context all behave differently in LaunchDaemon (system domain) vs LaunchAgent (gui domain) vs interactive shell. A credential path that works in testing (`sudo -u openclaw security ...`) fails in production (daemon context). Only file-based credentials are reliably daemon-safe. This generalizes beyond Book Scout to any OpenClaw plugin that needs secrets.
- **Convention: Gateway restart playbook.** Kill via `sudo kill` + launchctl print, verify with `nc -z`, check model with grep on embedded run start. For plist changes: strip provenance xattr → bootout → bootstrap. Documented in MEMORY.md for reuse.
- **Convention: Three-tier credential lookup.** Env var → file → Keychain. Covers: daemon context (file), CI/automation (env var), interactive development (Keychain). Applied to `getApiKey()`, should be the pattern for future plugin credentials.
- **Observation: `config set` is a destructive operation.** Clobbers file permissions and may introduce unwanted defaults. Treat as medium-risk, verify config after use.

### Session Summary
- Deployed book-scout plugin to OpenClaw gateway (end-to-end working)
- Fixed 5 deployment prerequisites (permissions, Keychain, SOUL.md, plugin)
- Diagnosed and fixed model routing: billing cooldown + per-agent credential isolation
- Fixed download credential access: Keychain → credential file for daemon context
- 9/10 books downloaded, catalog JSONs in inbox
- 15 new operational findings documented in MEMORY.md
- **Remaining:** commit source changes, restore openclaw.json permissions, transition to DONE

## 2026-03-01 — Session 8: BBP Mass Processing + Pipeline Cleanup

### Context
- Book Scout downloaded ~90 books across 6 subject folders in research-library
- User dropped additional batch into unsorted (~100 new) and fiction (~30 new)
- Gemini batch API broken (stalled indefinitely on all preview models)
- Switched to standard mode with gemini-3.1-pro-preview

### Actions
- Processed 49 Book Scout catalog JSONs via catalog-processor.sh → 49 source-index notes
- Cancelled 10 stalled Gemini batch jobs (4 from yesterday + 6 new)
- Confirmed standard Gemini API works fine; batch API broken across all preview models
- Ran book-digest across 6 research-library directories (parallel standard mode)
- Ran fiction-digest for fiction directory
- Ran second wave: unsorted (99 valid) and fiction (33 valid) after user dropped remaining books
- Retried failures: miller (success), socrates-scholasticus (success), ikigai (empty response — content filter)
- Launched chapter-digest runs across all 6 directories (3 of 6 complete at session end, 3 still running)

### Pipeline Changes
- Removed batch API code from pipeline.py (360 lines removed)
  - Stripped: `run_batch_submit()`, `run_batch_collect()`, `--batch-api`, `--job-name`, batch pricing constants
  - Simplified: `estimate_cost()`, `process_book()` parameters
- Cleaned up batch artifact files (11 files: batch-state-*.json, batch-request-*.jsonl, pending-batches.json, bbp006-monitor.sh, bbp006-status.txt)
- Fixed bug: `usage_metadata` fields can be None → added null guards
- Fixed bug: empty Gemini response (0 output tokens) → added explicit error message

### Processing Summary
| Template | Written | Dedup Skip | Fail | Notes |
|----------|---------|------------|------|-------|
| book-digest | 92 success | 61 | 5 | beardsley (904pp), home comforts (1482pp), ikigai (content filter) permanent |
| fiction-digest | 23 success | 20 | 1 | count of monte cristo (1057pp) permanent — exceeds 1000pp API limit |
| chapter-digest | ~20+ (in progress) | — | 1 | 3/6 dirs done, 3 still running at session end |

### Unprocessable Books (hard limits)
- **>1000pp API limit**: Home Comforts (1482pp), Count of Monte Cristo (1057pp)
- **>904pp earlier limit**: beardsley-european-philosophers-descartes (904pp)
- **Content filter**: Ikigai (Gemini returns empty response consistently)
- **Image-only PDFs (~12)**: need OCR before processing

### Cross-Reference: Yesterday vs Today
- Yesterday's bbp-pdfs/nonfiction (78 files): 62 covered, 16 missing (10 image-only, 3 oversized/filtered, 1 skip, 2 retried successfully)
- Yesterday's bbp-pdfs/fiction (17 files): 14 covered, 3 missing (2 image-only, 1 oversized)
- Today added 39 new books not in yesterday's set (30 nonfiction + 9 fiction from research-library)

### Compound Evaluation
- **Convention: Gemini batch API unreliable for preview models.** Both gemini-3.1-pro-preview and gemini-3-pro-preview batch jobs stall indefinitely (PENDING/RUNNING with frozen update_time, no errors). Standard API works fine with same model. Batch mode removed from pipeline. May revisit if Google fixes batch API for GA models.
- **Convention: Gemini 1000-page hard limit.** Books >1000 pages get 400 INVALID_ARGUMENT. Separate from file size limits. Would need PDF splitting to process these.
- **Pattern: Empty Gemini response = content filter.** Some PDFs (Ikigai) consistently produce 0 output tokens with no error. Likely safety filter on the PDF content. No workaround short of using a different model.

### Session Summary
- Mass-processed 115+ books into digest notes (92 nonfiction + 23 fiction)
- Chapter-digest runs in progress (3/6 done, 3 running as background OS processes)
- Removed batch API code from pipeline (broken, unnecessary)
- Fixed 2 pipeline bugs (None token counts, empty response handling)
- Identified hard limits: 1000pp API cap, content filter blocks, image-only PDFs
- **Background processes still running at session end:** philosophy, unsorted, fiction chapter-digest runs

## 2026-03-04 — Session 9: Project Close-Out

### Context
- All 10 tasks complete, code review done, plugin deployed and working
- Source repo clean (credential-file commit already landed as `c1daf58`)
- Two close-out items from Session 7 remaining

### Actions
- Verified source repo: working tree clean, all commits pushed
- Restored `openclaw.json` permissions: `rw-r----- openclaw:crumbvault` (operator ran sudo)
- Updated project-state.yaml: phase IMPLEMENT → DONE
- Updated progress-log with IMPLEMENT and DONE phases

### Compound Evaluation
- No compoundable insights. Mechanical close-out.

### Phase Transition: IMPLEMENT → DONE
- Date: 2026-03-04
- IMPLEMENT phase outputs: deployed plugin (OpenClaw workspace extensions), 199 tests passing, code review complete, 9+ books downloaded and cataloged
- All milestones complete: M0 (API research + env), M1 (search + format), M2 (download + catalog + notifications), M3 (vault processor + BBP handoff), M4 (edge cases + SOUL.md)
- No open items remaining
- Compound: No new conventions or patterns — project was a straightforward plugin implementation following established OpenClaw extension patterns.
