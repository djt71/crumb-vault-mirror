---
type: run-log
project: mission-control
status: archived
created: 2026-03-07
updated: 2026-03-13
covers: "2026-03-13 down to 2026-03-09 — Session 7 (MC-072 + Ops polish) through MC-065 feed-pipeline dashboard entry path. Sessions run newest-first."
---

# Mission Control — Run Log Archive (03a)

> **Archive 1 of 3.** Covers 2026-03-09 to 2026-03-13: session 7 (MC-072 + Ops polish) back through MC-065 feed-pipeline dashboard entry path. Continues in [[run-log-2026-03b]] (2026-03-09 MC-028 adapter tests back through 2026-03-07 MC-055) and [[run-log-2026-03c]] (2026-03-07 MC-010 Design gate review onward). Active log: [[run-log]].

## 2026-03-13 (session 7) — MC-072 + Ops polish (LLM labels, git count fix)

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `packages/api/src/adapters/akm-feedback.ts` — AKM adapter (consumed list)
- `packages/web/src/pages/KnowledgePage.tsx` — AKM panel UI (consumed section, font fix)
- `packages/web/src/types/knowledge.ts` — shared types
- `packages/api/src/adapters/llm-provider-status.ts` — LLM status page labels
- `packages/api/src/adapters/git-status.ts` — git commit counting
- `vitest.config.ts` — root-level test config
- `_system/scripts/akm-read-tracker.sh` — PostToolUse hook
- `_system/scripts/akm-session-feedback.sh` — session-end feedback script
- `.claude/settings.json` — hook registration

### Work Done

**MC-072 complete (vault instrumentation + dashboard adapter + UI):**
- PostToolUse hook on Read tracks vault file reads per session
- Session-end script computes paths_hit/paths_miss automatically
- Adapter parses consumption data: per-source utilization, overall consumption rate, never-consumed detection
- UI: consumption rate + dead weight KPIs, utilization column, Consumed + Never Consumed expandable sections
- Live verification: 60% consumption rate across 11 measured sessions, 183 never-consumed sources

**Follow-up polish (operator-requested):**
- Consumed section: always visible (disabled button + placeholder when empty)
- Font bump on consumption summary line (0.75rem → 0.875rem)
- Vitest root config: exclude `e2e/` to fix Playwright/Vitest collision (302/302 tests pass)

**LLM Status labels (Ops page):**
- Anthropic: added Claude.ai, renamed to Claude Code / Claude API
- OpenAI: added ChatGPT (Conversations), renamed Chat Completions → API, dropped unused Responses
- DeepSeek: added Chat (web chat service)
- Component display name mapping layer for clean labels

**Git commit count fix (Ops page):**
- `--since=2026-03-13` returns 0 for today — git treats bare dates as "from this moment"
- Fixed by anchoring to midnight: `--since=2026-03-13T00:00:00`
- Today count went from 0 → 7 (correct)

### Test Summary
- 302 tests passing (37 files), both packages build clean
- E2e smoke test no longer collides with Vitest runner

### Code Review

**akm-read-tracker.sh:** Clean hook script — vault path filtering, dedup via grep, system log exclusion. Fire-and-forget with early exits.

**akm-session-feedback.sh:** Reads surfaced paths from JSONL, compares against session reads file. Uses jq for JSON extraction, awk for floating-point division. Idempotent — clears tracking file after write.

**llm-provider-status.ts:** Display name mapping is a simple Record lookup with fallback to raw name. Clean separation — config specifies status page component names, mapping translates to display names.

**git-status.ts:** One-line fix. The `T00:00:00` suffix is the standard fix for git's date parsing behavior.

**Risk:** Low across all changes. Additive adapter/UI changes, config-only label changes, one-line date fix.

### Compound
- **git `--since` with bare dates is a known gotcha.** `--since=YYYY-MM-DD` means "from the current time on that date" — for today's date, that's "from now," which matches nothing. Always anchor with `T00:00:00` for midnight. This applies to any dashboard or script using `git rev-list --count --since`.
- **Status page component names ≠ product names.** Provider status pages use internal component names (e.g., "Conversations" for ChatGPT, "Chat Completions" for OpenAI API). A display name mapping layer keeps the dashboard readable without coupling to upstream naming conventions.

### Model Routing
- All work on Opus (session default). No Sonnet delegation — interactive UI iteration with operator feedback loop.

---

## 2026-03-13 (session 6) — MC-072 AKM consumption tracking

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `_system/logs/akm-feedback.jsonl` — AKM feedback entries (session-end had empty paths_hit/paths_miss)
- `_system/scripts/knowledge-retrieve.sh` — knowledge retrieval engine
- `_system/docs/protocols/session-end-protocol.md` — §6b hit-rate measurement spec
- `packages/api/src/adapters/akm-feedback.ts` — dashboard AKM adapter
- `packages/web/src/pages/KnowledgePage.tsx` — AKM panel UI
- `packages/web/src/types/knowledge.ts` — shared types
- `.claude/settings.json` — hook registration

### Work Done

**MC-072 complete — three deliverables:**

**1. Instrumentation (vault-side):**
- `_system/scripts/akm-read-tracker.sh` — PostToolUse hook on Read tool. Extracts file_path from hook input JSON, tracks vault reads in `_system/logs/.akm-session-reads`. Filters: vault paths only, excludes `_system/logs/`, `.claude/`, `.git/`. Dedup via `grep -qxF`.
- `_system/scripts/akm-session-feedback.sh` — Session-end script. Reads today's surfaced paths from JSONL, compares against session reads file, computes paths_hit/paths_miss/hit_rate, appends structured session-end entry, clears tracking file.
- PostToolUse hook registered in `.claude/settings.json` (matcher: "Read")
- Session-start cleanup added to `session-startup.sh` (truncates tracking file)
- Updated session-end protocol §6b to reference the automated script instead of behavioral instructions

**2. Dashboard adapter (akm-feedback.ts):**
- Separate parsing for retrieval entries vs session-end entries (typed discriminated union)
- Per-source consumption counts from paths_hit across all session-end entries
- `AkmSourceStats` expanded: `times_consumed`, `utilization` (consumed/surfaced ratio)
- Aggregate metrics: `consumption_sessions`, `overall_consumption_rate`, `total_consumed`, `total_surfaced_all`
- Never-consumed detection: sources surfaced 1+ times but never in paths_hit (top 15 returned)
- `dead_weight_count`: total never-consumed source count
- Legacy session-end entries (string paths_miss) excluded from consumption metrics

**3. Dashboard UI (KnowledgePage.tsx AkmPanel):**
- Two new KPIs: consumption rate (warns if <20%) and never-consumed count (warns if >10)
- Summary line: "X/Y surfaced items consumed across N measured sessions"
- Most Surfaced table: +Consumed column, +Util. column (warns if 0% with 3+ surfacings)
- Expandable "Never Consumed" section with source table

**Live verification:**
- 11 valid session-end entries in historical data → 60% overall consumption rate
- 183 never-consumed sources identified across all time
- Scripts tested: read tracker dedup, path filtering, session-end JSONL write

### Test Summary
- 302 tests passing (10 knowledge adapter tests, 4 new: consumption metrics, legacy format, never-consumed detection)
- Both packages build clean
- Live API verified with new fields

### Code Review — MC-072

**Instrumentation design:** PostToolUse hook → tracking file → session-end script is the right pattern. Behavioral-only §6b was unreliable (evidenced by months of empty paths_hit). The hook approach is fully automated with no behavioral dependency.

**Adapter:** Discriminated union for entry types is type-safe. Legacy entry exclusion (string paths_miss) prevents garbage data from corrupting metrics.

**Risk:** Low. Additive changes to adapter + UI. Hook script is fire-and-forget with early exits. Session-end script is idempotent.

### Compound
- **Hooks > behavioral instructions for structured data collection.** §6b as a behavioral instruction produced unreliable data for months. Converting to a PostToolUse hook + session-end script makes it mechanical and trustworthy. Pattern applies to any session-scoped telemetry that needs reliable accumulation.

### Model Routing
- All work on Opus (session default). No Sonnet delegation — cross-cutting implementation spanning bash scripts, TypeScript adapter, React UI, and hook registration.

---

## 2026-03-13 (session 5) — Vault Health move to Ops, AKM consumption task

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `packages/web/src/pages/OpsPage.tsx` — ops page layout
- `packages/web/src/components/ops/Timeline.tsx` — removed timeline component
- `packages/web/src/components/ops/VaultHealth.tsx` — new vault health component
- `packages/web/src/pages/KnowledgePage.tsx` — knowledge page (vault check removed)
- `packages/api/src/routes/vault.ts` — vault API (vault-check-summary removed)
- `packages/api/src/routes/nav-summary.ts` — nav summary (knowledge status simplified)
- `packages/api/src/adapters/vault-check-summary.ts` — deleted
- `packages/web/src/index.css` — timeline CSS replaced with vault health CSS
- `Projects/mission-control/tasks.md` — MC-072 added

### Work Done

**Vault Health relocated from Knowledge to Ops page:**
- Operator decision: vault health is operational, not knowledge — belongs on Ops
- Replaced 24h Timeline component (questionable value) with VaultHealth panel
- KPI-style display matching Knowledge page pattern: result (PASS/WARNINGS/FAIL), errors count, warnings count, last run age
- Color-coded counts: green when 0, red for errors > 0, yellow for warnings > 0
- Expandable detail list for individual warning/error lines
- Ops API already fetched `vaultCheck` — just wasn't rendered

**Cleanup:**
- Removed VaultCheckPanel from Knowledge page
- Deleted `vault-check-summary.ts` adapter (Knowledge-side duplicate of Ops `vault-check.ts`)
- Removed `VaultCheckSummaryData` type from knowledge types
- Simplified Knowledge nav-summary status to project health only (stalled projects)
- Removed 3 vault-check-summary tests from knowledge.test.ts (298 tests pass, down from 304)
- Deleted Timeline.tsx CSS (~110 lines), replaced with VaultHealth CSS (~70 lines)

**MC-072 captured:**
- AKM consumption tracking — `paths_hit`/`paths_miss` fields exist in JSONL but are always empty
- `session_read` echoes `session_surfaced` (all hit rates = 1.0) — no real differentiation
- Task covers both instrumentation (session-end comparison of surfaced vs Read calls) and dashboard display (per-source utilization rate, never-consumed sources)

### Code Review — Vault Health relocation

**Scope:** 8 files changed, 1 deleted, 1 new component

**VaultHealth.tsx:** Clean KPI layout using ops types. `formatAge` handles null/recent/minutes/hours. Result derived from `passed` + `warnings.length`. All three color states (ok/warn/error) applied via CSS classes.

**Deletion safety:** `vault-check-summary.ts` had no consumers after removal from vault.ts and nav-summary.ts. The Ops page uses the existing `vault-check.ts` adapter which reads the same log file. No data loss.

**Nav-summary:** Knowledge status simplified from vault-check + project-health to project-health only. Vault-check errors now surface through Ops page status (already wired via `rollUpStatus`).

**Risk:** Low. Panel relocation with no new data sources. Ops adapter was already fetching vault-check data.

### Compound
- **Vault health as operational concern is the right framing.** The 24h timeline was a phase 0 design artifact that never proved useful — service events are better tracked through Healthchecks.io and the service grid. Vault-check results are directly actionable ops data.

### Model Routing
- All work on Opus (session default). No Sonnet delegation — interactive UI iteration.

---

## 2026-03-13 (session 4) — M6 Knowledge page, QMD automation, unlinked sources queue

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `project-state.yaml` — project state
- `tasks.md` — task definitions (MC-040–043, MC-071)
- `packages/api/src/routes/vault.ts` — vault API routes
- `packages/api/src/routes/vault-link.ts` — unlinked sources endpoint
- `packages/api/src/routes/search.ts` — QMD search endpoint
- `packages/api/src/routes/nav-summary.ts` — nav summary (knowledge status wiring)
- `packages/api/src/adapters/qmd.ts` — QMD status adapter
- `packages/api/src/adapters/akm-feedback.ts` — AKM feedback adapter
- `packages/api/src/adapters/vault-check-summary.ts` — vault-check summary adapter
- `packages/api/src/adapters/project-health.ts` — project health adapter
- `packages/api/src/adapters/vault-gardening.ts` — vault gardening adapter
- `packages/api/src/adapters/knowledge.test.ts` — knowledge adapter tests
- `packages/web/src/pages/KnowledgePage.tsx` — knowledge page frontend
- `packages/web/src/hooks/useKnowledgeData.ts` — knowledge data hook
- `packages/web/src/types/knowledge.ts` — knowledge type definitions
- `packages/web/src/index.css` — knowledge page styles
- `com.crumb.qmd-index.plist` — QMD daily indexing launchd agent

### Work Done

**M6 Knowledge page (MC-040/041/042/043 done):**
- 5 adapters: QMD (shells out to `qmd status`, parses text), AKM feedback (JSONL parse with `surfaced ?? []` null guard), vault-check summary (text log parser), project health (scans `project-state.yaml` files, stall detection >7d), vault gardening (live filesystem scan — orphan sources, stale sources >180d, tag distribution)
- `GET /api/vault` returns all 5 in parallel; individual endpoints `/qmd`, `/akm`, `/vault-check`, `/projects`, `/gardening`
- `GET /api/search?q=...` wired to QMD across all collections
- Knowledge page frontend: 5 panels (QmdPanel, AkmPanel, VaultCheckPanel, ProjectHealthPanel, GardeningPanel) with KPI rows, expandable tables, tag distribution bars
- Nav-summary wired for Knowledge page status (vault-check errors + stalled projects)
- 11 adapter unit tests — all pass (304 total tests pass)

**QMD daily indexing:**
- LaunchAgent `com.crumb.qmd-index` — runs `qmd update && qmd embed` daily at 5:30am
- Installed and verified with manual kickstart

**Unlinked sources inbox-queue feature:**
- Renamed "Orphan Sources" → "Unlinked Sources" throughout (these are durable KB artifacts missing MOC wikilinks, not dead knowledge)
- `POST /api/vault/link-sources` scans source-index files for `topics` frontmatter, checks if MOC has wikilink, writes queue file to `_inbox/moc-link-queue-YYYY-MM-DD.md`
- Queue file has `type: action-request`, `action: link-sources-to-mocs` frontmatter with full instructions for Crumb to add annotation-quality entries
- UI button "Link all to MOCs" with queue-based success message
- Tested: 182 sources queued across 6 MOCs (moc-history, moc-writing, moc-religion, moc-philosophy, moc-crumb-architecture, moc-business)

**MC-071 done (previous session):**
- Nav-summary attention status rewired from old vault-item aggregator to daily plan + goals
- Removed HealthStrip "stale data detected" false positive

### Code Review — M6 Knowledge page + unlinked sources

**Scope:** 14 files changed (2105 added, 11 removed)

**Adapters:**
- All follow `{data, error, stale}` triple contract
- QMD adapter uses `execFile` with timeout — handles missing binary gracefully
- AKM adapter guards against `surfaced: null` entries (11 of 199 in prod data)
- Vault gardening does full filesystem scan with wikilink extraction — O(n²) backlink check acceptable at current vault size (~1600 files)
- Project health stall detection uses 7-day threshold against `updated` frontmatter field

**vault-link.ts:**
- Recursive MD file collector with stack-based iteration (no recursion depth risk)
- Frontmatter parser handles both inline `topics: [a, b]` and block-style YAML arrays
- MOC lookup searches all `Domains/*/` subdirs — handles multi-domain MOC placement
- Queue file includes full annotation instructions (wikilink format, CORE/DELTAS section conventions)
- Returns `{queued, already_linked, mocs_affected, inbox_file}`

**Frontend:**
- Manual-pull pattern (no auto-polling) — operator clicks refresh
- GardeningPanel accepts `onRefresh` prop for post-link refresh
- Knowledge page CSS uses existing design system tokens

**Risk:** Low. All adapters read-only. vault-link writes only to `_inbox/` (standard intake surface). No schema changes.

### Compound
- **Unlinked sources count (182) is high.** Many sources have `topics` pointing to MOCs but were never wikilinked in the MOC CORE sections. The inbox-queue approach lets Crumb handle these with full annotation quality rather than batch-inserting bare wikilinks.
- **QMD automation closes a gap.** Index was manually run; daily 5:30am schedule ensures search results stay fresh with minimal operator attention.

### Model Routing
- All work on Opus (session default). No Sonnet delegation — full M6 build with operator interaction.

---

## 2026-03-13 (session 3) — MC-069 Quick Add repurpose, UI polish, footer tagline

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `project-state.yaml` — project state
- `tasks.md` — task definitions
- `packages/api/src/adapters/daily-attention.ts` — daily plan adapter (append logic)
- `packages/api/src/routes/attention.ts` — attention API routes
- `packages/web/src/pages/AttentionPage.tsx` — page layout
- `packages/web/src/components/attention/QuickAdd.tsx` — quick add component
- `packages/web/src/components/attention/GoalsPanel.tsx` — goals panel
- `packages/web/src/components/attention/DailyPlanPanel.tsx` — daily plan panel
- `packages/web/src/components/NavRail.tsx` — nav rail
- `packages/web/src/App.tsx` — app shell
- `packages/web/src/index.css` — styles

### Work Done

**MC-069 done (Quick Add repurpose):**
- `appendFocusItem()` added to `daily-attention.ts` — appends `- [ ] **Title**` block to Focus section with optional Domain/Action/Goal sub-fields, updates heading item count, mtime conflict detection
- `POST /api/attention/daily/focus` route — validates title, maps errors (409 conflict, 404 no daily file, 400 invalid domain/action)
- `QuickAdd.tsx` rewritten — posts to new endpoint, selectors changed from urgency/kind to action (do/decide/review) and goal (fetched from goals API, active goals only)
- Quick Add moved to top of Attention page, wired to refresh Daily Plan panel on success
- Deleted dead components: UrgencyStrip.tsx, AttentionCard.tsx, FilterBar.tsx, CompletedFeed.tsx, useAttentionData.ts
- 5 adapter tests + 4 route tests added. All 273 tests pass.

**UI polish (operator-directed):**
- Action tags lowercase in both Quick Add dropdown and Daily Plan badges
- Domain Balance table font bumped from 0.8125rem to 0.9375rem
- Domain Balance bottom border added (teal, matching top separator)
- Nav badge moved to left side of icon (was overlapping status dot on right)
- Avatar hover preview: 200px enlarged image using 400x400 source (was fuzzy from 96x96)
- Add Goal button moved above Completed section in Goals panel
- Removed bottom separator from goals panel (last section on page)
- Focus item titles switched from Source Serif to Inter (matches page font)
- Escalated items (title starts with "Escalation:" or 5+ carry days) get bold weight + warning color
- Goal IDs (G1, G2, etc.) bumped from 0.75rem to 0.875rem to match description text

**App footer:**
- Tagline at bottom of every page: "Crumb + Tess — a personal multi-agent OS. One vault, many agents, one operator. The work persists."
- Gold color (#d4a854), centered, small Inter font

**Task updates:**
- MC-069 marked done
- MC-070 marked done
- MC-071 created: rewire nav-summary attention status to daily plan + goals (follow-up for stale HealthStrip false positive)

### Code Review — MC-069 + UI polish

**Scope:** 16 files changed in crumb-dashboard (426 added, 335 removed), 1 vault file (tasks.md)

**appendFocusItem (daily-attention.ts):**
- Line-based Focus section detection + boundary finding — same pattern as toggleDailyItem
- Item count update in heading regex — handles singular/plural
- Trailing blank line cleanup before insertion prevents double-spacing
- writeVaultFile imported at top level (cleaned up dynamic import in toggleDailyItem)

**Route (attention.ts):**
- POST /daily/focus follows existing pattern (ECONFLICT→409, ENOENT→404, validation→400)
- Title required, domain/action/goal optional — matches daily plan format

**Frontend:**
- QuickAdd fetches active goals on mount for goal selector — non-critical fetch (catch swallowed)
- Escalation detection uses title prefix + carry_days threshold — covers both attention-manager patterns

**Risk:** Low. No schema changes. appendFocusItem writes to the same daily file that toggleDailyItem already writes to. Dead code deletion is clean — no remaining imports.

### Compound
- **Service restart after build is a recurring friction point.** The 404 on Quick Add was caused by running old dist/. Consider adding a file watcher or post-build hook to auto-restart the launchd service. Low priority but would eliminate a class of "it's broken" reports.
- **Nav-summary attention logic is now stale.** The old attention aggregator (vault-item scanner) drives the HealthStrip but the page no longer shows those items. MC-071 captures this.

### Model Routing
- All work on Opus (session default). No Sonnet delegation — interactive design iteration with operator throughout.

---

## 2026-03-13 (session 2) — Attention page overhaul: Goals panel, recurring goals, cleanup

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `project-state.yaml` — project state
- `tasks.md` — task definitions for MC-069, MC-070
- `packages/api/src/routes/attention.ts` — attention API routes
- `packages/api/src/adapters/daily-attention.ts` — daily plan adapter
- `packages/api/src/adapters/goals.ts` — new goals adapter
- `packages/web/src/pages/AttentionPage.tsx` — attention page layout
- `packages/web/src/components/attention/GoalsPanel.tsx` — new goals component
- `_system/docs/goal-tracker.yaml` — goal tracker data

### Work Done

**Attention page cleanup:**
- Removed UrgencyStrip — redundant with Ops page and Daily Plan
- Removed Active Items list, FilterBar, CompletedFeed, `useAttentionData` hook
- Page reduced to: Daily Plan + Goals + Quick Add
- Removed old `POST /api/attention` vault-attention-item endpoint and tests
- Section dividers: teal color `rgba(92,184,164,0.25)`, 2px, applied within Daily Plan and between panels
- Font alignment: Quick Add input changed from Source Serif to Inter

**MC-070 (Goals panel):**
- `goals.ts` adapter: YAML parser/serializer for `goal-tracker.yaml`. Separate regex for quoted/unquoted values (fixes `""` parse bug). Read/write with mtime conflict detection.
- API routes: `GET /api/attention/goals`, `POST /api/attention/goals` (sequential ID assignment), `PATCH /api/attention/goals/:id` (status/progress update)
- `GoalsPanel.tsx`: Goal cards with ID, description, domain badge, days-left indicator, overdue/urgent styling. Collapsible completed section. Inline add form (description, domain, horizon, target date).
- `useGoals.ts` hook: fetch, add, complete, retire operations

**Recurring goals:**
- `horizon` field redefined: `none` = one-time, `weekly/monthly/quarterly/yearly` = recurring cadence
- Completing recurring goal: `advanceDate()` moves target_date forward by interval, resets progress, keeps status `active`
- Visibility window matches cadence (weekly=7d, monthly=30d, quarterly=90d, yearly=365d) — goal hidden until window before next target
- Toast confirmation: "Completed — next due Mar 23" with 3s fade animation
- Retire button (×) on recurring cards — permanently sets status to `retired`
- Existing goals (G1-G3) updated to `horizon: none`

**Goal completion cascade:**
- PATCH goals/:id with `status: completed` checks off related daily plan Focus items matching `- Goal: G<n>`
- DailyPlanPanel exposed via `forwardRef`/`useImperativeHandle` for refresh after cascade

**Task updates:**
- MC-069 created: Quick Add repurpose for daily focus items only
- MC-070 created: Goals panel (this work)
- MC-036 updated: `item_mode` field for recurring vs one-shot items
- MC-039 updated: recurring item UI + promote-from-Deferred action

### Code Review — Attention page overhaul + Goals panel

**Scope:** 5 modified + 3 new files in crumb-dashboard, 2 modified in vault

**Goals adapter (goals.ts):**
- YAML parser uses separate quoted/unquoted regex — handles `""`, `"quoted value"`, and bare values correctly
- `advanceDate` uses `Date` setMonth/setDate — handles month-end rollover correctly (JS Date auto-adjusts)
- mtime conflict detection on all write operations — consistent with daily-attention adapter pattern

**API routes (attention.ts):**
- Old `POST /` and related imports cleanly removed
- Cascade is best-effort (try/catch) — goal update succeeds even if daily plan toggle fails
- `UpdateResult` return type distinguishes renewed vs completed for UI feedback
- Validation catches domain/horizon/target_date errors at adapter level, route maps to 400

**Frontend (GoalsPanel.tsx):**
- `isRecurringVisible` filter based on cadence-matched window — clean separation of display logic
- Toast state with 3s timeout + CSS fade animation — no external dependencies
- Retire sends `status: retired` — same PATCH endpoint, different payload
- forwardRef on DailyPlanPanel for cascade refresh — minimal coupling

**Risk:** Low. No schema changes, no external calls. Goal tracker YAML serializer is the main fragility point — tested with roundtrip in tests.

### Compound
- **YAML mini-parser fragility:** Regex-based YAML parsing works for the fixed goal-tracker schema but breaks on edge cases (values containing quotes, multi-line strings). Acceptable for this narrow use case but would not generalize. If goal-tracker schema evolves, consider a proper YAML library.
- **Recurring goal visibility window = cadence:** This means a weekly goal with a 7-day window is always visible within its period. If completed on the target date, it immediately re-enters the window for the next period. This is correct behavior — if you want a break, complete early. May need adjustment if users find it surprising.

### Model Routing
- All work on Opus (session default). No Sonnet delegation — interactive design discussion throughout, cross-referencing multiple adapters and components.

---

## 2026-03-13 — MC-066 feed-pipeline sync-back + MC-067 Daily Attention panel + table rendering fix

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `project-state.yaml` — project state
- `tasks.md` — task definitions for MC-066, MC-067
- `packages/api/src/adapters/fif-sqlite.ts` — signal query with dashboard_actions JOIN
- `packages/api/src/adapters/dashboard-actions.ts` — action recording functions
- `packages/api/src/routes/attention.ts` — attention API routes
- `packages/web/src/pages/AttentionPage.tsx` — attention page layout
- `.claude/skills/feed-pipeline/SKILL.md` — feed pipeline skill procedure

### Work Done

**MC-066 done (feed-pipeline sync-back):**
- `fif-sqlite.ts`: Signal query JOIN changed from `consumed_at IS NULL` to unrestricted; WHERE clause updated to `(da.id IS NULL OR (da.consumed_at IS NULL AND da.action NOT IN ('skip', 'delete')))` — consumed actions now hide items from signal list
- `dashboard-actions.ts`: Added `recordSyncBack()` — writes rows with `consumed_at` pre-set (INSERT OR IGNORE for idempotency)
- Feed-pipeline SKILL.md: Added sync-back sqlite3 commands at Step 3 (Tier 2 extraction), Step 5 (auto-promote, new step 8), and Step 6 (review queue). Fixed pre-existing duplicate step numbering.
- Tests: Updated consumed-action test (now expects hidden), added 3 sync-back tests. 25/25 pass.

**MC-067 done (Daily Attention panel):**
- `daily-attention.ts` adapter: Parses `_system/daily/YYYY-MM-DD.md` — extracts Focus items with checkbox state, title, why_now, domain, action, source, goal, carry_days. Sections extracted: Domain Balance, Carry-Forward, Deferred, Goal Alignment. Carry-day matching uses bidirectional title/key check + "Why now" text fallback.
- `toggleDailyItem()`: Checkbox write-back with mtime conflict detection (stat before/after read, 409 on change).
- Routes: `GET /api/attention/daily` + `PATCH /api/attention/daily/:date/items/:index` with input validation.
- `DailyPlanPanel.tsx`: Renders at top of Attention page. Interactive focus cards with custom checkbox, domain/goal/action badges, carry-forward indicator, expandable "Why now". Collapsible sections for supplementary content. Optimistic checkbox toggle with revert on failure.
- `useDailyAttention.ts`: Fetch-on-mount hook (no polling) with manual refresh and optimistic toggleItem.
- Tests: 6 adapter tests (valid parse, missing file, malformed markdown, checked/unchecked, carry-forward, no-frontmatter). All pass.

**Table rendering fix (post-MC-067 polish):**
- Added `MarkdownBlock` component with markdown table parser → proper HTML `<table>` rendering
- Inline formatting: bold, italic, wikilinks
- Replaced raw `<pre>` blocks in Domain Balance and CollapsibleSection content
- Added section dividers (`border-subtle` top borders) between headline, focus list, domain balance, and collapsible sections

**Non-MC work:**
- Fixed `daily-attention.sh` file permissions: added `chmod 644` after both `mktemp`/`mv` atomic writes (artifact + sidecar). Root cause: first autonomous cron run (TOP-056) created files with `mktemp` default 600 instead of group-readable 644.

### Code Review — MC-066 + MC-067

**Scope:** 13 new/modified files in crumb-dashboard + 4 vault files

**MC-066 (fif-sqlite.ts query change):**
- JOIN now includes all dashboard_actions rows — correct, consumed items need to be filtered
- WHERE logic: `da.id IS NULL` (no action) OR unconsumed non-skip/delete — clean
- `recordSyncBack()` uses INSERT OR IGNORE — idempotent, won't overwrite dashboard-originated actions

**MC-067 (daily-attention.ts adapter):**
- Line-based section extraction avoids multiline regex pitfalls — good
- Carry-day matching: bidirectional title check + why_now fallback covers phrasing mismatches
- `toggleDailyItem()` mtime conflict detection: stat before read, stat after read, reject if changed — correct pattern
- Checkbox toggle finds nth match via regex exec loop — handles any number of items

**Frontend (DailyPlanPanel.tsx):**
- Optimistic toggle with revert on failure — responsive UX
- MarkdownBlock: focused parser for tables + inline formatting, no external dependency
- Table row hover uses `--accent-muted` — consistent with design system

**Risk:** Low. No schema changes, no external calls. All changes are additive.

### Compound
- **`mktemp` + `mv` = 600 permissions:** Atomic write pattern using `mktemp`/`mv` silently produces owner-only files. Any cron script using this pattern needs explicit `chmod` after `mv`. This was masked during development because Claude Code's Write tool uses normal umask. Only surfaced on first autonomous cron run. Applies to all `_openclaw/scripts/` using the atomic write pattern — check `awareness-check.sh` and any future cron scripts.
- No cross-domain patterns to promote. Table rendering fix is a standard markdown-to-HTML concern.

## 2026-03-12 (session 2) — Phase 1 retro, Ops page overhaul, LLM provider status

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `project-state.yaml` — project state
- `progress/phase-1-retro.md` — Phase 1 retrospective (created)
- `packages/web/src/pages/OpsPage.tsx` — Ops page layout
- `packages/web/src/components/ops/KpiStrip.tsx` — KPI strip + gauge row
- `packages/web/src/components/ops/LlmStatus.tsx` — LLM status section
- `packages/web/src/components/ops/Timeline.tsx` — 24h timeline
- `packages/api/src/adapters/llm-provider-status.ts` — new provider status adapter
- `packages/api/src/adapters/git-status.ts` — new git status adapter
- `packages/api/src/adapters/backup-status.ts` — new backup status adapter

### Work Done

**MC-028 closed (parity gate pass):** Verified 3-day operator usage trial. SC-1 PASS (after retro fixes), SC-3 PASS, SC-5 PARTIAL (upstream data gaps only).

**MC-035 done (Phase 1 retrospective):**
- Created `progress/phase-1-retro.md` — full retro covering timeline, usage assessment, per-page analysis, success criteria, PC-7/PC-9 decisions.
- Three operator decisions confirmed: selective Phase 2 reorder (MC-066 → MC-067 → M6 → M5 gated → M7), MC-066 ship now, SC-1 PASS.

**Ops page overhaul (collaborative review):**
- KpiStrip consolidated with GaugeRow — removed CPU/Memory/Disk text KPIs (duplicated by gauges), removed backup tiles (TCC-broken from LaunchAgent)
- GPU gauge replaced with rich GitGauge: branch, dirty/untracked counts, today/week commit counts, 3-entry commit log
- Timeline: green baseline spanning full track, "All clear" green text when no events
- NavRail: Crumb T.C. avatar replacing clock icon (96px source, 52px display)
- Service status: removed defunct xfi cards, added `com.tess.backup-status`

**LLM provider status (new feature):**
- Created `llm-provider-status.ts` adapter polling 4 providers via status page APIs
- Anthropic, OpenAI, DeepSeek: Statuspage.io `summary.json` (page indicator + components)
- Google Gemini: `incidents.json` (custom — infer from active incidents)
- 5-minute in-memory cache, 8s fetch timeout, parallel fetches
- Overall status uses worst-of page indicator vs component derivation — catches active incidents even when components still read "operational"
- Replaced FIF call-health cards (redundant) with provider operational status cards
- Cards clickable → open provider's full status page in new tab
- DeepSeek bilingual component name fix (`API 服务 (API Service)`)

**Bug fixes:**
- `dashboard-actions.ts`: added `'research'` to `removeAction` type (pre-existing TS error from MC-068)
- Backup adapter: initial `fs.readdir` hung in launchd context (TCC); migrated to snapshot pattern, then removed tiles entirely
- Run-log code review heading format fixed for vault-check §23

### Code Review — Ops page overhaul + LLM provider status

**Scope:** 15 modified files + 3 new files in crumb-dashboard, 1 modified in vault

**Adapter layer (llm-provider-status.ts):**
- Fetches are wrapped in AbortController with 8s timeout — good
- Cache TTL 5 min reasonable for status page polling
- `deriveOverall` correctly uses worst-of page indicator vs component status
- Google incidents filter checks both product ID and title matches — defensive
- Error paths return `unknown` with empty components rather than throwing — adapter contract preserved

**Frontend (LlmStatus.tsx):**
- Clean separation: ProviderCard handles rendering, parent handles data flow
- `<a>` tag with `target="_blank" rel="noopener noreferrer"` — correct
- Status mapping: `partial_outage` → yellow (matches Statuspage.io visual), only `major_outage` → red

**Risk:** External HTTP calls from API server (new pattern — all other adapters read local files). Mitigated by timeout + cache + graceful fallback.

### Compound
- **TCC sandbox pattern confirmed:** `fs.readdir` on iCloud paths hangs in LaunchAgent context, not just fails. `execFile('/bin/ls')` also fails. Only reliable pattern: bash script in interactive shell writes snapshot, Node reads file. This is the same pattern as Apple data snapshots.
- **Status page API pattern:** Statuspage.io `summary.json` > `components.json` — the page-level indicator reflects active incidents before individual components are updated. Always use summary for accurate overall status.
- **Routing:** No compound patterns to promote. TCC finding reinforces existing snapshot architecture doc.

### Model Routing
- All work on Opus (session default). No Sonnet delegation — cross-referencing mockup CSS, status page APIs, adapter patterns, and existing component code throughout.

### Next
- MC-066: feed-pipeline sync-back (next task, approved to ship)
- MC-067: Daily Attention panel (Phase 2 start, gated experiment)

---

## 2026-03-12 — MC-028 parity gate eval, 5 UX fixes, MC-068 research button

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `packages/web/src/components/intel/SignalDigest.tsx` — signal card rendering + triage actions
- `packages/web/src/components/intel/PipelineHealthPanel.tsx` — circuit breaker display
- `packages/api/src/adapters/fif-sqlite.ts` — signal data extraction (title fallback)
- `packages/api/src/adapters/dashboard-actions.ts` — triage action recording + schema
- `packages/api/src/routes/intel.ts` — triage endpoints
- `packages/web/src/index.css` — card styling
- `Projects/tess-operations/design/overnight-research-design.md` — TOP-046 design note

### Work Done

**MC-028 parity gate evaluation:**
3-day operator trial (Mar 9-11) evaluated. Operator used dashboard for signal triage and provided detailed UX feedback — 5 issues identified. Gate verdict: CONDITIONAL PASS — primary usage criterion met, UX issues fixed in same session.

**5 UX fixes (from operator triage feedback):**
1. **Linkify text content** — added `Linkify` component to detect URLs in signal text (summary, why_now, reasoning, excerpt) and render as clickable links. Safe React approach (no dangerouslySetInnerHTML).
2. **Card boundaries** — moved `border-bottom` from `.signal-card` to `.signal-card-wrapper` so separators persist across all card states (queued, fading).
3. **Queued info text** — added "Promoted on next feed-pipeline run" hint on queued cards.
4. **X post title fallback** — when `title` and `platform_specific.title` are null, falls back to first 80 chars of `excerpt` with ellipsis. X posts now show content preview instead of `x:2031...` IDs.
5. **Circuit breaker recovery state** — `circuitState()` now considers last run status. If last run succeeded but 7-day rate is high, shows "Recovering" (yellow) instead of "Open" (red). Fixes misleading X curated "Open" display.

**Pre-existing test fixes:** 5 tests broken by Mar 11 LOW filter change — test data missing `priority` field in `triage_json`. Fixed in both `fif-sqlite.test.ts` and `intel.test.ts`.

**MC-068 — Research triage action:**
Full implementation: `POST /api/intel/:canonical_id/research` endpoint, schema migration (CHECK constraint updated to include 'research', auto-migrates preserving data), `getPendingResearchCount()`, magnifying glass icon button on signal cards, amber RESEARCH badge, "Queued for overnight research" hint, cancel/undo support. 3 new unit tests. Mirrors promote pattern.

**Overnight research design amendments (operator decisions):**
- Model: Opus 4.6 (was Sonnet) — research items need architectural judgment
- Throttle: removed 1-item-per-night cap, process full queue each run
- Wall-time: 30 min (was 10 min)
- Output: auto-promote to `Sources/Signals/` as signal-notes (~90% of items), not intermediate briefs
- Added "Applicability" section to output format for Crumb/Tess connection assessment

### Decisions
- MC-028 gate: conditional pass with fixes applied (not deferred to follow-up tasks)
- No topic weight feedback from dashboard actions — operator wants triage diversity preserved
- Research items auto-promote to signal-notes (operator: "9/10 times it ends up as a KB article")
- Opus for overnight research, not Sonnet — judgment quality over cost optimization
- XD-016 (TOP-046 blocked on MC-068) now unblocked

### Acceptance Criteria Check (MC-068)
- [x] `POST /api/intel/:canonical_id/research` writes research action to `dashboard_actions`
- [x] Optional metadata JSON (notes field)
- [x] 409 Conflict if item already has a different action
- [x] 404 for unknown canonical_id
- [x] Magnifying glass icon button on signal cards
- [x] "RESEARCH" badge + "Queued for overnight research" hint on queued cards
- [x] Cancel button (undo)
- [x] `researchQueueCount` in GET /api/intel response
- [x] Unit tests: 3 new (queue, 404, conflict)
- [x] All 124 tests pass (118 API + 6 web)

### Compound Evaluation
- **Pattern: operator feedback during soak/gate periods is high-signal for UX iteration.** Danny's 5 triage notes produced more actionable improvements than the original spec's UX requirements. Gate evaluation sessions should always include "what friction did you hit?" as a structured question, not just pass/fail criteria.
- **Pattern: research-then-promote as a single action.** When the research output IS the promoted artifact (not a separate intermediate), you eliminate a handoff. Applied to overnight research design — signal-note is the end product, not a brief that feeds another pipeline.

### Model Routing
- All work in main session (Opus). No Sonnet delegation — code generation + design decisions requiring architectural judgment throughout.

### Code Review — MC-068, MC-028
- **Scope:** MC-068 (research triage action) + MC-028 (parity gate — 5 UX fixes + adapter tests)
- **Reviewer:** Self (implementation session — peer review at milestone boundary)
- **Tests:** 124 pass (118 API + 6 web), up from 120 (4 new tests)

---

## 2026-03-11 — LOW items filtered from intel page, build metadata added

**Summary:** Filtered LOW priority signals from dashboard intel page SQL query and KPI component. Added `build_command` and `services` to `project-state.yaml` for session-end build verification protocol. Dashboard rebuilt and restarted.

**Changes (crumb-dashboard repo):**
- `fif-sqlite.ts`: Added `json_extract(triage_json, '$.priority') IN ('high', 'medium')` to both signal query branches
- `PipelineKpis.tsx`: Removed T3 counter, simplified tier counting to T1/T2 only

## 2026-03-09 — MC-056/057/058 cross-project tasks

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `_openclaw/staging/m1/mechanic-HEARTBEAT.md` — mechanic agent heartbeat checks
- `packages/api/src/routes/health.ts` — dashboard health endpoint
- `packages/web/src/components/NavRail.tsx` — nav rail with 6 page entries
- `packages/api/src/routes/customer.ts` — customer route (stub)
- `packages/api/src/routes/nav-summary.ts` — nav-summary controller

### Work Done

**MC-056 — Tess mechanic health monitoring:**
Added check #10 to `mechanic-HEARTBEAT.md`: `GET /api/health` on port 3100. Consecutive-failure tracking via `/tmp/crumb-dashboard-health-fail` marker file — first failure creates marker silently, second consecutive failure triggers Telegram alert with restart recommendation. Fills the ≤10 check cap from TOP-008.

**MC-057 — Playwright smoke test:**
Installed `@playwright/test` + Chromium. Created `playwright.config.ts` and `e2e/smoke.spec.ts` with 3 tests: health endpoint returns 200 with ok status, nav rail renders 6 page icons with correct labels, all 6 routes load without JS errors. Added `npm run test:e2e` script. All 3 tests pass.

**MC-058 — Cloudflare Access verification middleware:**
Built `verifyCfAccessHeaders()` in `packages/api/src/middleware/cf-access.ts` using `jose` for JWT verification against Cloudflare's JWKS endpoint. Config via `CF_ACCESS_TEAM_DOMAIN` and `CF_ACCESS_AUD` env vars, with `jwksUrl` override for testing. Fail-closed: missing config or headers → 403. Applied to `/api/customer` routes. Added `hasCfAccessHeader()` helper used by nav-summary to conditionally include customer data (structural prep for MC-050). 8 unit tests with local JWKS server (missing header, invalid token, wrong audience, valid token, expired token, plus 3 header-presence tests). All 120 project tests pass.

### Decisions
- MC-056: Used temp file marker for consecutive-failure tracking rather than persistent state — mechanic is stateless per-run, temp file is the lightest approach
- MC-058: `jose` over `jsonwebtoken` — modern, no native deps, built-in JWKS support
- MC-058: `jwksUrl` config override keeps middleware testable without mocking
- active_task advanced to MC-035 (Phase 1 retro, blocked on MC-028 parity gate ~03-12)

### Compound Evaluation
- **Pattern:** Test infrastructure should be set up at project scaffold time, not bolted on later. Playwright needed separate install + config + browser download — would have been cheaper if done with MC-013 (Vite scaffold). Consider adding E2E scaffold to future project templates.
- **No cross-domain compound insights.**

### Model Routing
- All work in main session (Opus). No Sonnet delegation — all tasks involved code generation requiring architectural judgment (middleware design, test infrastructure setup).

---

## 2026-03-09 — MC-028 adapter tests + parity gate start

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `packages/api/src/adapters/fif-sqlite.test.ts` — existing 5 tests
- `packages/api/src/adapters/pipeline-health.test.ts` — existing 6 tests
- `packages/api/src/adapters/fif-sqlite.ts` — dashboard_actions LEFT JOIN logic
- `packages/api/src/adapters/dashboard-actions.ts` — action recording

### Work Done

**Adapter tests (MC-028 part 2):**
Added 4 tests to fif-sqlite.test.ts covering `dashboard_actions` integration:
1. Filters out skipped and deleted signals from signal list
2. Shows `dashboard_action='promote'` on queued signals
3. Ignores consumed promote actions (treats as no-action)
4. Returns signals without actions normally

All 15 tests pass (9 fif-sqlite + 6 pipeline-health).

**Triage button 404 fix:**
Dashboard triage action buttons (skip/delete/promote) returned HTTP 404 for all source types. Root cause: server process (PID 60233) started March 7 — before MC-062/063/064 triage routes were built on March 9. Routes existed in compiled JS but the Node process was running stale code. Fix: `launchctl kickstart -k` to restart the service. All three actions + undo verified via curl.

**Parity gate (MC-028 part 1):**
3-day operator usage trial begins today (2026-03-09). Pass criteria: operator uses Pipeline section for signal triage instead of Telegram + Crumb session for 3 consecutive days; page load + manual refresh under 400ms. Gate result to be documented after trial completes (~2026-03-12).

### Decisions
- MC-028 stays `todo` until parity gate trial completes — tests are done, gate is in progress
- No code changes needed for the gate; it's a usage evaluation

### Compound Evaluation
- **Pattern:** Dashboard and skill systems operating on the same data need bidirectional sync, not just one-way. MC-065 built dashboard→skill; MC-066 captures skill→dashboard. Generalizable to any pair of systems sharing a data source with independent processing paths.
- **Operational:** Server restarts after code deploys are not automated — launchd keeps the old process running indefinitely. Consider a post-build hook or deploy script for crumb-dashboard. Not urgent enough for a task; note for Phase 1 retro (MC-035).

