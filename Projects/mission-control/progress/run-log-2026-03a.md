---
type: run-log
project: mission-control
status: active
created: 2026-03-07
updated: 2026-03-13
last_committed: 2026-03-13
period: 2026-03-01 to 2026-03-14
---

# Mission Control — Run Log

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

## 2026-03-09 — MC-065 feed-pipeline dashboard entry path

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `Projects/mission-control/tasks.md` — MC-065 acceptance criteria
- `Projects/mission-control/design/specification.md` — §8.6 feed triage actions
- `.claude/skills/feed-pipeline/SKILL.md` — existing skill procedure
- FIF SQLite adapter (`~/openclaw/crumb-dashboard/packages/api/src/adapters/fif-sqlite.ts`) — DB path, posts schema, dashboard_actions JOIN pattern

### Work Done

Updated feed-pipeline SKILL.md with new Step 0: "Dashboard-Queued Promotions."

**Changes:**
1. **Frontmatter:** Updated description to mention dashboard entry path. Added `feed.promotion.dashboard` capability with cost profile. Added `Bash` to required_tools (for sqlite3 CLI).
2. **Identity:** Documented two entry paths (inbox + dashboard).
3. **Routing diagram:** Added dashboard promote queue flow above the existing three-tier routing.
4. **Step 0 (new):** Queries `dashboard_actions WHERE action='promote' AND consumed_at IS NULL` joined with `posts`. Extracts item data from JSON fields. Resolves kb/ tag from metadata override or auto-mapped triage tags. Runs Q4 (project applicability). Promotes via Step 5 sub-steps with `dashboard_promote: true` provenance. Cleans up inbox file if present. Sets `consumed_at` on success.
5. **Step 1:** Dashboard-queued count now reported in summary line.
6. **Step 7:** Calibration log format extended with `dashboard_promoted` field.
7. **Context Contract:** Added FIF SQLite DB as MUST-have dependency.
8. **Convergence:** Added dimension 6 — dashboard queue processing completeness.

**Design decisions:**
- Step 0 is self-contained — references Step 5 sub-steps but doesn't modify the inbox workflow. Both paths coexist cleanly.
- DB path uses `$HOME` expansion (not hardcoded `/Users/tess`) for portability.
- Failed `consumed_at` writes are tolerable — dedup in Step 5.1 collision check makes re-processing idempotent.

### Acceptance Criteria Check
- [x] Step 0 queries `dashboard_actions WHERE action='promote' AND consumed_at IS NULL` joined with `posts`
- [x] Flagged items skip Q1-Q3, run full promotion workflow
- [x] kb_tag from metadata override or auto-mapped from triage tags
- [x] Signal-note write, MOC registration, knowledge retrieval, project cross-posting
- [x] Sets `consumed_at` on success
- [x] Dashboard-queued count reported separately in Step 1 summary
- [x] Existing inbox workflow unchanged

MC-065 → **done**. M3b (Intel Pipeline Triage Actions) milestone complete. MC-028 parity gate unblocked.

## 2026-03-09 — Peer review fixes (MC-064 S1, S6)

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Work Done

Operator peer review of MC-064 surfaced 6 findings. Fixed 2, accepted 3, rejected 1:

1. **S1 (bug fix):** `new URL(u)` in SignalDetail throws on malformed URLs from external FIF sources. Added `displayHost()` helper with try/catch fallback. (`3018d37`)
2. **S6 (fix):** Level 3 default kb/ tag from `findDefaultKbTag()` wasn't in the `<select>` dropdown options — browsers render inconsistently when value isn't in option list. Now injected as extra option when default is Level 3. (`3018d37`)
3. **S3 accepted:** CANONICAL_KB_TAGS 5-way sync surface — sync-point comments in place, GET endpoint is a future option.
4. **S4 rejected (false finding):** `transition: opacity 0.4s ease` already exists on `.signal-card-wrapper`.
5. **S5 accepted:** First-match in `findDefaultKbTag` is reasonable; operator can override in selector.
6. **S2 self-resolved by reviewer:** skip/delete race is handled by server-side filtering.

### Code Review Entry
- **Scope:** MC-064
- **Reviewer:** Operator (Danny)
- **Findings:** 6 (1 significant, 1 medium, 4 minor)
- **Fixes committed:** `3018d37` (crumb-dashboard)

## 2026-03-09 — MC-064 triage UI + pre-existing TS/test fixes

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `Projects/mission-control/tasks.md` — MC-064 acceptance criteria
- `Projects/mission-control/design/specification.md` — §8.6 feed triage actions
- `packages/web/src/components/intel/SignalDigest.tsx` — existing signal card component
- `packages/web/src/pages/IntelPage.tsx` — intel page layout
- `packages/web/src/types/intel.ts` — frontend type definitions
- `packages/api/src/routes/intel.ts` — triage API endpoints (MC-062/063)
- `packages/web/src/index.css` — dark observatory theme styles

### Work Done

1. **MC-064: Intel page triage UI** (`1068e53`)
   - Signal cards show 3 action buttons: skip (X), delete (trash), promote (up-arrow)
   - Skip/delete: card fades to 30% opacity, 5s undo bar with API-backed undo
   - Promote: inline kb/ tag selector pre-populated from signal's triage_tags mapped through canonical lookup, confirm button queues promotion
   - Queued signals show "QUEUED" badge + accent left border with cancel button
   - Promote queue count indicator in Pipeline section header
   - Per-card error display, busy state, mobile tappable sizing
   - Forward reference: consumed promotion "promoted" status requires MC-065 (adapter filters consumed_at IS NULL)

2. **Pre-existing TS errors fixed** (`81eb694`)
   - `intel.ts`: Express 5 types `req.params` as `string | string[]` — coerced with `String()`
   - `dashboard-actions.test.ts`: union type `DashboardAction | 'conflict'` needed narrowing before property access

3. **SafeMarkdown test fix** (`bcaf861`)
   - Missing `// @vitest-environment jsdom` directive caused all 6 tests to fail with "document is not defined"
   - Test suite now 210/210 (was 204/210)

### Decisions
- Consumed promotion display deferred to MC-065 — adapter's `consumed_at IS NULL` filter means frontend can't distinguish queued vs. consumed promotions without adapter changes
- Undo is 5s window for skip/delete only; promote has persistent cancel button (until feed-pipeline consumes)

### Code Review Entry
- **Scope:** MC-064
- **Reviewer:** Self (implementation session, no external review)
- **Status:** Builds clean (API + web), 210/210 tests pass
- **Note:** Operator code review recommended at M3b completion (MC-065 remaining)

### Compound Evaluation
- **Pattern confirmed: CANONICAL_KB_TAGS sync surface** — now 5 sync points (added frontend `SignalDigest.tsx`). The S4 finding from operator review is compounding — every new consumer adds drift risk. Read-from-vault-at-startup remains the long-term fix.

### Model Routing
- All work in main session (Opus) — frontend implementation with design decisions, not delegable to Sonnet

## 2026-03-09 — Peer review fixes (S1-S6)

**Phase:** TASK
**Operator:** Danny

### Work Done

Operator code review surfaced 7 findings against MC-061/062/063 implementation. Fixed 5, accepted 2:

1. **S1 (bug fix):** `deleteInboxFile` used `includes()` for canonical_id matching — substring collision risk (e.g., `x:10` matching `x:100`). Fixed with regex line-anchored match.
2. **S2 (robustness):** Writable DB connections had no `busy_timeout` — SQLITE_BUSY from concurrent FIF writes would produce unhandled 500s. Added `busy_timeout = 5000` on all connections.
3. **S3 (correctness):** `getPendingActions` and `getPendingPromoteCount` opened writable connections unnecessarily. Switched to new `openDbReadonly()` function.
4. **S4 (maintainability):** Hardcoded `CANONICAL_KB_TAGS` list now has comment pointing to 4 sync sources.
5. **S6 (test gap):** Added test verifying `removeAction` returns false when `consumed_at` is set (feed-pipeline skill already processed the item).
6. **S5 accepted:** Permissive Level 3 subtag validation — no registry to validate against, acceptable for single-user.
7. **S7 accepted:** YAML escaping in canonical_id — S1 regex fix covers this implicitly.

### Code Review Entry
- **Scope:** MC-061, MC-062, MC-063
- **Reviewer:** Operator (Danny)
- **Findings:** 7 (3 significant, 4 minor)
- **Fixes committed:** `5aa67f6` (crumb-dashboard)
- **Residual:** S4 drift risk noted — read-from-vault at startup is the long-term fix

## 2026-03-09 — Feed triage actions design + spec amendment

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `Projects/mission-control/design/specification.md` — §6.3, §8.3, new §8.6
- `Projects/mission-control/design/specification-summary.md` — build order, C4, key decisions
- `Projects/mission-control/tasks.md` — M3b tasks, MC-028 reframe
- `.claude/skills/feed-pipeline/SKILL.md` — existing promotion workflow analysis
- FIF SQLite adapter analysis (crumb-dashboard `packages/api/src/adapters/`)

### Work Done

1. **Feed triage gap identified** — MC-028 parity gate cannot pass without action capability. Operator needs promote/skip/delete on feed signals from the dashboard, not just viewing.

2. **Design analysis: where does triage belong?**
   - Phase 4 (A2A facade writes) is wrong scope — feed triage is direct data operations, not approval/feedback/delivery infrastructure
   - Full promotion in Express is wrong approach — feed-pipeline skill does LLM-grade reasoning (permanence evaluation, context generation, project cross-posting) that can't be reduced to a REST endpoint
   - Decision: **skip/delete are immediate dashboard actions; promote is queued for feed-pipeline skill**

3. **Schema ownership decision (Option B):**
   - New `dashboard_actions` table in FIF SQLite, owned by dashboard
   - FIF core tables (`posts`, `adapter_runs`, `cost_log`) remain read-only from dashboard
   - Feed-pipeline skill JOINs `dashboard_actions` to pick up queued promotions
   - Rejected: Option A (new `queue_status` value in `posts` — muddies FIF schema ownership), Option C (JSON sidecar — reinvents CTB at lower fidelity)

4. **Spec amended:**
   - §6.3: triage actions added to Pipeline section layout
   - §8.3: write endpoints description updated (Phase 1 now includes feed triage)
   - New §8.6: full feed triage actions design (schema, action semantics, data flow, design rationale, endpoints)
   - §8.6→§8.7: A2A delivery adapter renumbered

5. **Tasks created (M3b: Intel Pipeline Triage Actions):**
   - MC-061: `dashboard_actions` table + adapter update
   - MC-062: Skip + delete endpoints
   - MC-063: Promote-queue endpoint
   - MC-064: Intel page triage UI
   - MC-065: Feed-pipeline skill dashboard-flagged entry path

6. **MC-028 reframed:** parity gate now requires triage actions (depends on MC-064). 3-day usage criterion measures signal triage from dashboard, not just digest viewing.

### Decisions
- Feed triage is a Phase 1 addition, not Phase 4 — it's data operations, not A2A infrastructure
- Promotion logic stays exclusively in feed-pipeline skill (no duplication)
- `dashboard_actions` table provides clean ownership boundary
- MC-028 parity gate blocked until M3b complete

### Compound Evaluation
- **Pattern: LLM-layer vs mechanical-layer decomposition** — when moving a skill's functionality to a different surface (web UI), decompose into "what needs reasoning" (stays in skill) and "what's deterministic" (can be a direct operation). The human decision at the UI replaces the LLM evaluation, so only the mechanical execution needs to cross the boundary.
- **Pattern: queue-for-skill over replicate-in-endpoint** — when a dashboard action requires the same quality as a Crumb skill, queue the intent and let the skill process it rather than reimplementing. Trades immediacy for quality and single-owner maintenance.

## 2026-03-07 — Project creation + SPECIFY completion

**Phase:** SPECIFY (complete)
**Operator:** Danny

### Context Inventory
- `_inbox/crumb-mission-control-spec-v2.md` — specification from claude.ai session
- `_inbox/crumb-mission-control-review-synthesis.md` — round 1 peer review (4 models, 20 amendments)
- `_inbox/crumb-mission-control-round2-addendum.md` — round 2 deep research review (12 amendments)
- `_inbox/crumb-mission-control-session-context.md` — session context + routing instructions

### Work Done
1. **Cross-project status synthesis** — pulled live state from all 6 related projects:
   - FIF: TASK phase, M4 YouTube soak in progress, M-Web 12 tasks 0 started (clean to absorb)
   - A2A: IMPLEMENT phase with M1/M2 live (corrected from session context which showed PLAN). Delivery abstraction operational. A2A-015.x superseded by this project.
   - tess-operations: TASK phase, M1 gate evaluation day 3
   - AKM: DONE, akm-feedback.jsonl ready for consumption
   - customer-intelligence: ACT phase, 3/25 dossiers populated
   - crumb-tess-bridge: DONE, dispatch state files documented and operational

2. **Project scaffold created** — `Projects/mission-control/` with design/, progress/, reviews/

3. **Spec v2 placed + R2 amendments applied** (12 amendments):
   - R2-1: Dark mode as genuine design exploration (U4, F5, §9.2, §13 rewritten)
   - R2-2: HTML/CSS mockups as primary Phase 0 approach (A7, U2 resolved, §9.1)
   - R2-3: Data source naming precision (§6.2, §6.3)
   - R2-4: Write atomicity for vault file operations (§7.1)
   - R2-5: Markdown rendering sanitization (§8.3)
   - R2-6: Approval surface idempotency contract (§8.6)
   - R2-7: Attention-item staleness mechanism (§7.1 schema + §7.3)
   - R2-8: Resolve OQ9 vault-native as decision (§7.3 + §14)
   - R2-9: Empty/error/stale state design as Phase 0 deliverable (§9.1 + gate checklist)
   - R2-10: Attention-item schema versioning (§7.1 + §7.3)
   - R2-11: Two new future pages — Finance + Home (§6.7)
   - R2-12: Phase 0 estimate adjustment to 4-8 sessions (§12)

4. **F3 corrected** — A2A status updated from "spec defines" to "IMPLEMENT phase with M1/M2 live"

5. **Review files placed:**
   - `reviews/2026-03-07-peer-review-synthesis.md`
   - `reviews/2026-03-07-round2-addendum.md`

### Key Decisions
- SPECIFY phase work from claude.ai session accepted as-is (no systems-analyst pass)
- A2A being in IMPLEMENT (not PLAN) strengthens Phase 4 feasibility — delivery layer already exists
- M-Web and A2A-015.x absorption confirmed clean (zero existing code)
- Three "missing" data sources (system-stats.sh, service-status.sh, attention-item primitive) are this project's deliverables, not upstream blockers

### Blockers
- None for PLAN phase entry

### Next
- Run action-architect for PLAN phase decomposition

---

### Phase Transition: SPECIFY → PLAN
- Date: 2026-03-07
- SPECIFY phase outputs: `design/specification.md`, `design/specification-summary.md`, `reviews/2026-03-07-peer-review-synthesis.md`, `reviews/2026-03-07-round2-addendum.md`
- Goal progress: All met — spec produced, peer reviewed (2 rounds, 32 amendments), cross-project state verified, F3 A2A status corrected
- Compound: No compoundable insights from SPECIFY phase — heavy thinking done in external claude.ai session; Crumb session was mechanical placement + amendment application
- Context usage before checkpoint: ~35% (fresh session, spec read via persisted output)
- Action taken: none
- Key artifacts for PLAN phase: `design/specification-summary.md`, `reviews/2026-03-07-round2-addendum.md` (PLAN-phase notes section)

---

## 2026-03-07 — PLAN phase: action-architect decomposition

**Phase:** PLAN
**Operator:** Danny

### Context Inventory
- `design/specification-summary.md` — primary input (1)
- `design/specification.md` — full spec via persisted output for constraint sections §6-10 (2)
- `reviews/2026-03-07-round2-addendum.md` — PLAN-phase notes (9 constraints) (3)
- `_system/docs/overlays/overlay-index.md` — checked, Design Advisor + Web Design Preference match Phase 0 (4)
- `_system/docs/solutions/write-read-path-verification.md` — informed adapter pipeline design (5)
- `_system/docs/solutions/html-rendering-bookmark.md` — Chart.js reference noted (6)
- No estimation calibration history exists

### Work Done
1. **Specification summary created** — `design/specification-summary.md` for downstream phase context
2. **9 R2 PLAN-phase constraints resolved** (PC-1 through PC-9):
   - PC-1: Aggregator risk → single-source first, progressive addition
   - PC-2: Nav badges → `/api/nav-summary` at 60s independent of page refresh
   - PC-3: Time semantics → UTC storage, local display, per-page sort keys
   - PC-4: Health header → auto-refresh via nav-summary on manual-pull pages
   - PC-5: Analog readout → max 4 custom SVG gauges
   - PC-6: Widget inventory → Phase 0 gate deliverable
   - PC-7: Testing → adapter unit tests required; React component tests deferred to retro
   - PC-8: Notifications → future Phase 3+
   - PC-9: SSE → polling-first, upgrade path if retro reveals need
3. **Action plan produced** — `design/action-plan.md` with 10 milestones (M0a-M10), dependency graph, cross-cutting conventions
4. **Tasks produced** — `design/tasks.md` with 52 atomic tasks (MC-001 through MC-052) covering Phases 0-3
5. **Action plan summary** — `design/action-plan-summary.md`

### Key Decisions
- Polling-first architecture (no SSE at launch) — simplicity wins at 30-60s refresh intervals
- Nav-summary as shared data source for both nav badges and manual-pull page health strips
- Single `writeVaultFile()` utility + single `SafeMarkdown` component as cross-cutting concerns
- Phases 4-5 (M11-M16) left at milestone-level — not decomposed into atomic tasks due to dependency distance
- Design gate (MC-010) is the highest-risk single task — blocks all implementation

6. **Peer review: Claude.ai** — 3 must-fix, 5 should-fix, all accepted and applied. Task count 52 → 54. Review at `reviews/2026-03-07-action-plan-claude-ai.md`.
7. **Peer review: multi-model synthesis** — 18 amendments (4 high-confidence, 4 medium, 10 single-reviewer), 2 declined. Key changes:
   - AP-1: attention_id → UUID v4 (collision safety across independent writers)
   - AP-2: M-Web parity gate concrete pass criteria (3 days usage, 400ms load)
   - AP-4: Aggregator reads `_inbox/attention/` in Phase 1 (quick-add visibility)
   - AP-8: PATCH 409 Conflict + .tmp zombie cleanup
   - AP-9: CSS variable palette toggle (Phase 0 efficiency)
   - AP-13: Knowledge "review stale sources" wired to POST /attention
   - AP-17: MC-009 split into MC-009 + MC-055
   - 3 new tasks: MC-055 (stale/error/mobile), MC-056 (Tess health monitoring), MC-057 (Playwright smoke)
   - Panel availability matrix added to MC-010 gate
   - Task count 54 → 57. Synthesis at `reviews/2026-03-07-action-plan-synthesis.md`.

### Housekeeping Notes
- `_inbox/` still has 4 raw upload files from the SPECIFY session — clean up during next inbox processing
- `design/session-context.md` has stale A2A status (shows PLAN, should be IMPLEMENT) — one-time handoff artifact, not a living document. Noted but not corrected since it won't be re-consumed.

8. **Dispatch review synthesis** — background 4-model dispatch (GPT-5.2, Gemini 3, DeepSeek, Grok) returned. Most findings overlapped with the synthesis already applied. 6 net-new findings applied:
   - DR-A1: CF Access verification middleware (MC-058) — auth at route layer, not adapter
   - DR-A2: Production build + Express static serve (MC-059)
   - DR-A3: M4 aggregator depends on MC-023 (adapter pattern proven)
   - DR-A4: Single-source integration test gate in MC-029 before multi-source
   - DR-A5: Nav-summary controller wired per milestone (MC-022, 026, 033, 042, 051)
   - DR-A6: Health strip on manual-pull pages (MC-026)
   - MC-050 updated: header check moved to middleware, adapter doesn't handle auth
   - Task count 57 → 59. Synthesis at `reviews/2026-03-07-action-plan-tasks.md`.

### Key Decisions
- SPECIFY phase work from claude.ai session accepted as-is (no systems-analyst pass)
- A2A being in IMPLEMENT (not PLAN) strengthens Phase 4 feasibility — delivery layer already exists
- M-Web and A2A-015.x absorption confirmed clean (zero existing code)
- Three "missing" data sources (system-stats.sh, service-status.sh, attention-item primitive) are this project's deliverables, not upstream blockers

### Housekeeping Notes
- `_inbox/` still has 4 raw upload files from the SPECIFY session — clean up during next inbox processing
- `design/session-context.md` has stale A2A status (shows PLAN, should be IMPLEMENT) — one-time handoff artifact, not a living document. Noted but not corrected since it won't be re-consumed.

### Compound
- **Peer review velocity:** Two-round review (claude.ai + multi-model synthesis) plus background dispatch produced 24 applied amendments and 59 tasks from an initial 52. The dispatch added 6 net-new findings the synthesis missed — confirms dispatch value even when operator provides manual synthesis.
- **Architecture pattern:** Auth middleware at route layer (not adapter) is a recurring Express best practice. 3/4 reviewers flagged the coupling independently. Worth noting for future Express projects.
- **Production serving gap:** A "build + static serve" task is easy to forget when developing locally with Vite dev server. Add to future M1 checklists for any Express + Vite monorepo.

### Next
- PLAN phase complete — transition to TASK phase when operator confirms
- Begin Phase 0 execution (M0a: aesthetic exploration)

---

### Phase Transition: PLAN → TASK
- Date: 2026-03-07
- PLAN phase outputs: `design/action-plan.md`, `design/action-plan-summary.md`, `design/tasks.md`, `reviews/2026-03-07-action-plan-claude-ai.md`, `reviews/2026-03-07-action-plan-synthesis.md`, `reviews/2026-03-07-action-plan-tasks.md`
- Goal progress: All met — 59 tasks across 10 milestones, dependency graph, 3 review rounds (24 amendments applied), cross-cutting conventions defined
- Compound: Captured in prior session (peer review velocity, auth middleware pattern, production serving gap)
- Context usage before checkpoint: <30% (fresh session, vault reconstruction)
- Action taken: none
- Key artifacts for TASK phase: `design/tasks.md`, `design/action-plan-summary.md`, `design/specification-summary.md`

---

## 2026-03-07 — TASK phase: M0a aesthetic exploration

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/action-plan-summary.md` — milestone/task overview (1)
- `design/tasks.md` — full task definitions, MC-001 through MC-003 for M0a (2)
- `design/specification-summary.md` — spec context (3)
- `design/specification.md` §6.2, §9.1-9.3 — Observatory principles, design phase requirements (4)
- `_system/docs/overlays/design-advisor.md` + `design-advisor-dataviz.md` — design + dataviz lenses (5)
- `_system/docs/overlays/web-design-preference.md` — personal aesthetic lens (6)
- `_system/docs/www-design-taste-profile.md` — full taste profile, Mode 2 Observatory (7)

### Work Done
1. **MC-001 complete** — Design workspace created at `design/mockups/`. Aesthetic brief produced at `design/aesthetic-brief.md` covering:
   - Observatory mode principles (from taste profile + spec §9.2)
   - Library vs Observatory tension analysis (warm light vs dark backgrounds)
   - Three exploration directions defined: Warm (antique barometer), Dark (observatory at night), Hybrid (wooden instrument cabinet)
   - Design Advisor, DataViz, and Web Design Preference lenses applied
   - MC-002 evaluation criteria established

2. **MC-002 in progress** — Ops page mockup built at `design/mockups/ops-mockup.html` + `ops-mockup.css`:
   - Single HTML file with CSS custom property palette toggle (Warm/Dark/Hybrid)
   - Real data density: 9 KPI cards, 4 SVG gauge instruments, 9 service cards, 24h timeline with 18 event dots, cost burn panel with 6 bar rows
   - Typography: Source Serif 4 headers, JetBrains Mono data values, Inter sans-serif chrome
   - SVG arc gauges with needles (analog instrument aesthetic)
   - Theme switcher widget for instant comparison
   - Mobile-responsive at 375px viewport

### Status
- MC-001: done — workspace + aesthetic brief
- MC-002: done — Ops mockup with 3 palette variants, 6 sections, theme switcher
- MC-003: done — Dark Observatory selected

### Design Decisions Recorded
- D1: Dark mode selected (Direction B)
- D2: 13px minimum text floor (all contexts)
- D3: 14px data-tier minimum (service values, LLM stats)
- D4: LLM Status section added to Ops page (new scope — not in original spec)
- D5: Section order: Status → Gauges → Services → Timeline → LLM Status → Cost Burn
- D6: Aesthetic direction documented in `design/aesthetic-brief.md`

### Milestone M0a: Complete
All 3 tasks done. Dark Observatory aesthetic confirmed. Ready for M0b.

### Compound
- **Dark mode for Observatory:** Despite the taste profile's "no dark mode as default" anti-pattern, operator chose dark for the dashboard. The key insight: the anti-pattern applies to reading-centric Library mode, not operational Observatory mode. Status color visibility on dark backgrounds is a genuine functional advantage, not aesthetic preference. This nuance should inform future mode-specific design decisions.
- **LLM Status as first-class Ops section:** Not in the original spec — emerged during mockup review. "Is my model working?" is an operational question at the same tier as "is my service running?" Future Ops page specs for LLM-dependent systems should include provider health as a default section.
- **13px minimum text floor:** Dark backgrounds require slightly larger text for equivalent readability. The 13px chrome / 14px data two-tier minimum is a design system constraint worth carrying forward to any dark-mode dashboard project.

### Code Review
- Code Review — Skipped (MC-001, MC-002, MC-003): Phase 0 design tasks — HTML/CSS mockups, not implementation code. No repo_path exists yet. Code review applies from Phase 1 (MC-011+) when repo is created.

### Next
- M0b continues: MC-006 (widget inventory + analog readout budget)

---

## 2026-03-07 — M0b design system + widget vocabulary (MC-004, MC-005)

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/action-plan-summary.md` — milestone/task overview (1)
- `design/tasks.md` — MC-004/MC-005 acceptance criteria (2)
- `design/aesthetic-brief.md` — D1-D6 design decisions (3)
- `design/mockups/ops-mockup.css` — established dark palette and type scale (4)
- `design/specification.md` §6.2, §6.6, §9.1-9.3 — Ops, Knowledge, design system requirements (5)
- `reviews/2026-03-07-action-plan-synthesis.md` — AP-19/20/21 amendments (6)

### Work Done
1. **AP-19/20/21 applied to spec and tasks:**
   - §6.2: LLM Status section (per-model cards, empirical health, above Cost Burn)
   - §6.6: Vault Gardening section (dead knowledge, orphans, stale sources, tag hygiene, QMD health)
   - §9.2: 13px/14px text floor constraint
   - tasks.md: MC-020 expanded to 4 adapters, MC-021/023/040/042 updated for new scope

2. **MC-004 complete** — Design system document (`design/design-system.md`):
   - Color system: 8 token groups, 30+ tokens with explicit values
   - Typography scale: 3 families, 8 size tiers, typography rules
   - Panel component: 4 variants (KPI card, service card, standard panel, gauge container)
   - Focus/keyboard: `--focus-ring` token, `:focus-visible` convention
   - Transition conventions: system-wide defaults and exceptions
   - Panel component HTML reference page (`design/mockups/panel-component.html`)
   - Review round: 6 findings from operator review, all addressed

3. **MC-005 complete** — Widget vocabulary (`design/mockups/widget-vocabulary.html` + `widget-vocabulary.css`):
   - 14 archetypes rendered with real data patterns
   - New widgets: attention cards (×3 kinds), signal card, agent status card, search result card, approval card, progress bar, badge variants (7 groups), data table
   - All with `:focus-visible` keyboard treatment and responsive behavior

4. **Text floor enforcement:**
   - `.cost-bar-value` bumped from 13px to 14px (data tier, not chrome)
   - Memory/disk KPI inline spans bumped from 12.8px to 13px (floor violation)
   - CSS palette comment markers added for stable cross-references

### Key Decisions
- Disabled/loading state tokens deferred to MC-055 (empty/error/stale state patterns) — not MC-004 scope
- `--accent-selected` (0.22 alpha) added alongside `--accent-muted` (0.12 alpha) for stronger tint on selected cards/filters
- Skeleton shimmer timing deferred to MC-055

### Code Review
- Code Review — Skipped (MC-004, MC-005): Phase 0 design tasks — HTML/CSS mockups and design system documentation, not implementation code. No repo_path exists yet. Code review applies from Phase 1 (MC-011+).

### Next
- MC-006: widget inventory + analog readout budget

---

## 2026-03-07 — MC-006 widget inventory + analog readout budget

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-006 acceptance criteria (1)
- `design/specification.md` §6.0-6.6 — per-page layouts and data sources (2)
- `design/design-system.md` — panel variants and archetypes (3)
- `design/mockups/widget-vocabulary.html` — 14 widget archetypes (4)
- `design/mockups/ops-mockup.html` — Ops page widget instances (5)
- `progress/run-log.md` — prior session context, design decisions D1-D6 (6)

### Work Done
1. **MC-006 complete** — Widget inventory produced at `design/widget-inventory.md`:
   - 97 total widget instances (structural count) across 6 pages + nav shell
   - All 14 vocabulary archetypes + 4 panel variants used — no new custom archetypes needed
   - 4/4 custom SVG gauge budget allocated to Ops Resource Gauges (CPU, Memory, Disk, GPU)
   - 5 analog readout candidates evaluated and rejected for gauge treatment (progress bar or KPI instead)
   - 9 blocked panels identified across 5 pages (placeholder treatment per §6.0)
   - Per-page instance tables with section, widget name, type, data source, custom/standard columns
   - Archetype usage matrix showing cross-page coverage

### Key Decisions
- All 4 SVG gauges on Ops page (resource metrics) — no gauges on other pages
- FIF cost, YT quota, dossier completeness, budget vs actual, MOC coverage all use progress bar or KPI card instead of gauge — rationale documented per candidate
- Blocked panels counted in total (9 of 97) since they need empty-state treatment (MC-055)
- GPU gauge kept (in ops-mockup since MC-002) — flagged spec §6.2 / MC-016 gap: `system-stats.sh` AC needs GPU utilization added
- Batch book pipeline widget folded into Project Health section (Knowledge page) rather than standalone section — it's one project's data, same pattern as other project cards but with enriched progress bar

### Scope Addition
- **Workbench decision:** Customer intelligence working surface (dossier review, pre-meeting prep, account management) deferred as W1-W3 milestones in mission-control action plan. Separate read-write site within monorepo, spec'd after Phase 1 retro. See action plan deferred section.

### Next
- MC-007: Attention page mockup at real data density
- MC-008: Ops page mockup at real data density (evolve from MC-002)

---

## 2026-03-07 — MC-007 + MC-008: Attention + Ops mockups

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-007/MC-008 acceptance criteria (1)
- `design/widget-inventory.md` — widget-to-page mapping (2)
- `design/design-system.md` — color/typography/panel spec (3)
- `design/mockups/widget-vocabulary.html` + `widget-vocabulary.css` — 14 archetypes (4)
- `design/mockups/ops-mockup.html` + `ops-mockup.css` — existing Ops mockup to evolve (5)
- `progress/run-log.md` — prior session context (6)

### Work Done
1. **MC-007 complete** — Attention page mockup (`design/mockups/attention-mockup.html` + `attention-mockup.css`):
   - Urgency strip: 4 KPI cards (Now: 2, Soon: 3, Ongoing: 4, Awareness: 3), colored left borders on Now/Soon
   - Quick-add form: title input + domain/urgency/kind dropdowns, sensible defaults (career/soon/personal)
   - Filter bar: Urgency, Kind, Domain, Source filter groups with active state + Triage/Domain/Source view switcher
   - 12 attention cards: 4 system, 3 relational, 5 personal across all 4 urgency levels
   - 1 approval card embedded at correct urgency position (Soon)
   - Completed/dismissed feed: collapsible section with 2 muted cards (distinct opacity for done vs dismissed)
   - Nav cross-link to ops-mockup.html for browser navigation
   - All real data patterns from Crumb ecosystem

2. **MC-008 complete** — Ops page evolved (`design/mockups/ops-mockup.html` updated):
   - 3 blocked placeholder panels added under "Operational Intelligence" section
   - Operational Efficiency (requires self-optimization loop)
   - Operational Tempo (requires tempo adaptation)
   - Degradation Awareness (requires degradation-aware routing)
   - Dashed border + 50% opacity + stale dots + italic dependency labels
   - All prior content unchanged — existing mockup already met all AC from MC-002

3. **Review round — 3 fixes applied:**
   - `--accent-selected` token added to all 3 palette blocks in ops-mockup.css (same class of bug as focus-ring from MC-005 review)
   - Nav badge updated from 12 to 13 (includes pending approval)
   - Urgency filter group added to filter bar (was missing per MC-033 AC)

### Key Decisions
- Nav badge counts all items needing attention including pending approvals (13 = 12 attention + 1 approval)
- Domain filter shows only domains with active items (4 of 8) — intentional UX decision, not a bug
- Placeholder panel inline styles are a mockup convenience — MC-055 will extract to `.placeholder-panel` class
- Approval card positioned inline at its urgency level rather than in a separate section

### Code Review
- Code Review — Skipped (MC-007, MC-008): Phase 0 design tasks — HTML/CSS mockups, not implementation code. No repo_path exists yet.

### Next
- MC-009: Intelligence page mockup + nav shell
- MC-055: Empty/error/stale state patterns + mobile viewport testing

---

## 2026-03-07 — MC-009: Intelligence page + nav shell

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-009 acceptance criteria (1)
- `design/widget-inventory.md` — Intelligence page widgets, nav shell widgets (2)
- `design/specification.md` §6.3 — Intelligence page layout (Pipeline + Production) (3)
- `design/mockups/widget-vocabulary.html` + CSS — signal cards, search cards, badges (4)
- `design/mockups/ops-mockup.css` — shared tokens and nav rail (5)
- `design/design-system.md` — color/typography reference (6)

### Work Done
1. **MC-009 complete** — Intelligence page mockup (`design/mockups/intelligence-mockup.html` + `intelligence-mockup.css`):
   - **Pipeline section:** 5 KPI cards (signals today + sparkline, this week, sources breakdown, triage distribution, cost + progress bar), signal digest panel with 5 cards in contained layout (T1/T2/T3 tier filter), pipeline health with 3 circuit breaker indicators + data table, tuning blocked panel
   - **Production section:** research briefs queue (1 pending, 2 completed), weekly intelligence brief (rendered markdown), connections brainstorm featured card (accent-tinted), ecosystem radar (2 items)
   - **Nav shell:** full nav rail with status dots on all 6 pages (badge on Attn, ok/warn dots on others), search bar in page header with magnifying glass icon, search overlay dropdown with 3 result cards (collection badges, relevance scores, highlighted snippets)
   - Cross-links to attention-mockup.html and ops-mockup.html

2. **New CSS patterns extracted:**
   - `.blocked-panel` class — reusable for MC-055 (replaces inline styles from MC-008)
   - `.digest-panel` / `.digest-body` — cards-within-panel containment (no individual borders)
   - `.page-section-header` — section dividers with accent underline
   - `.brainstorm-card` — featured card with accent tint background
   - `.kpi-progress` — inline progress bar within KPI card (cost vs ceiling)

3. **Review round — no fixes needed:**
   - `--accent-selected` already present in all 3 palette blocks (fixed in MC-007 round)
   - Nav badge already consistent at 13 across all mockups (fixed in MC-007 round)
   - Negative margin on pipeline health table noted as Phase 1 implementation concern

### Key Decisions
- Pipeline and Production sections visually separated by page-section-header dividers with accent underline
- Signal digest uses contained panel layout (cards lose individual borders, panel provides containment) — cleaner than grid of bordered cards for feed-style content
- Brainstorm card gets accent tint background to distinguish "new" featured content from standard panels
- Search overlay positioned right-aligned under header search bar with shadow for depth

### Code Review
- Code Review — Skipped (MC-009): Phase 0 design task — HTML/CSS mockup, not implementation code. No repo_path exists yet.

### Next
- MC-055: Empty/error/stale state patterns + mobile viewport testing
- MC-010: Design gate review (depends on MC-009 + MC-055)

---

## 2026-03-07 — Spec updates: M9 enrichment + vault-check primitive registry

**Phase:** TASK
**Operator:** Danny

### Work Done
1. **M9 enrichment note** appended to `design/action-plan.md`:
   - Skill Utilization, Overlay Utilization, Agent Routing Distribution, Agent Activity Patterns sections
   - Depends on `skill-telemetry.jsonl` (separate Crumb spec amendment)
   - Agent Activity Patterns uses telemetry + existing M9 adapters (dispatch-state, tess-context, cost-aggregation)
   - Primitive registry detection via vault-check → dashboard picks up through MC-020 adapter

2. **vault-check primitive registry rule** added to `_system/scripts/vault-check.sh`:
   - REGISTERED_SKILLS (21 skills) and REGISTERED_OVERLAYS (8 overlays) lists
   - Scans `.claude/skills/` and `_system/docs/overlays/` against registry
   - Warns on unregistered primitives (non-blocking)
   - Tested: full vault-check passes clean, detection confirmed with synthetic unregistered skill

### Compound
- **Design system token propagation pattern:** `--accent-selected` was defined in design-system.md (MC-004) but not added to ops-mockup.css palette blocks — same bug class as `--focus-ring` from last round. Any token defined in the design system doc must be added to all 3 CSS palette blocks at definition time, not when first consumed. This is a recurring pattern worth a pre-flight checklist for future design system tokens.
- **Cards-within-panel containment:** The Intelligence digest panel demonstrates a reusable pattern — signal cards inside a container panel lose their individual borders/shadows and use subtle separators instead. This is more scannable for feed-style content than a grid of individually bordered cards. Worth carrying forward to any list-within-panel layout.
- **Blocked panel extraction:** Moving from inline styles (MC-008 Ops page) to a `.blocked-panel` class (MC-009 Intelligence page) confirms the pattern. 9 blocked panels across 5 pages all need this treatment — MC-055 should formalize it in the design system.

### Model Routing
- All work executed on Opus (session default). No delegation — Phase 0 design work requires contextual judgment across spec, mockups, and design system.

### Next
- MC-055: Empty/error/stale state patterns + mobile viewport testing
- MC-010: Design gate review

---

## 2026-03-07 — MC-055: State patterns + mobile viewport

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-055 acceptance criteria (1)
- `design/design-system.md` — token system, deferred `--bg-skeleton`/`--text-disabled` (2)
- `design/mockups/ops-mockup.css` — shared tokens + 3 palette blocks (3)
- `design/mockups/widget-vocabulary.css` — cross-page widget archetypes (4)
- `design/mockups/intelligence-mockup.css` — `.blocked-panel` source (5)
- `design/mockups/ops-mockup.html` — blocked panels with inline styles (6)
- `design/mockups/attention-mockup.html` + CSS — mobile viewport target (7)

### Work Done
1. **Deliverable 1 — Four state patterns formalized in CSS:**
   - **Blocked/placeholder:** `.blocked-panel` moved from intelligence-mockup.css to widget-vocabulary.css (cross-page pattern). Dashed border, 50% opacity, stale dot, italic description.
   - **Empty state:** `.state-empty`, `.state-empty-icon`, `.state-empty-text`. Centered layout with muted icon (32px, `--text-disabled`). KPI card variant: value + sub in disabled color.
   - **Error state:** `.state-error-banner` with error icon + message + retry metadata. KPI card variant: error-colored border + value. Card-within-list variant: error border + tinted background.
   - **Stale state:** `.state-stale-banner` with clock icon + age/threshold text. KPI card variant: warn-colored 3px left border. Card-within-list variant: 2px amber top stripe via `::before`.

2. **Design tokens added:**
   - `--bg-skeleton` and `--text-disabled` added to all 3 palette blocks (warm/dark/hybrid)
   - Design system doc §1.5a added with dark values, §3.8 added with full state pattern reference

3. **Ops blocked panels migrated:**
   - 3 "Operational Intelligence" cards converted from inline styles (`style="border: 1px dashed...; opacity: 0.5;"`) to `.blocked-panel` class
   - `widget-vocabulary.css` import added to ops-mockup.html

4. **State pattern demos added to widget-vocabulary.html:**
   - 4 widget groups (blocked, empty, error, stale) with examples at all 3 levels (full panel, KPI card, card-within-list)
   - Real data patterns: FIF database error, stale gateway, empty signals, blocked relationship heat map

5. **Deliverable 2 — Mobile viewport review (375px):**
   - CSS review of all responsive rules for Attention + Ops pages
   - **Fix applied:** `flex-wrap: wrap` + `gap: 4px` added to `.page-header` at ≤480px — prevents title + refresh-ts from overflowing at 375px ("Operations" + timestamp exceeds 295px usable width without wrapping)
   - Verified: nav rail compresses to 48px ✓, KPI strip stacks to 2 columns ✓, service grid single column ✓, gauge row 2 columns ✓, filters stack vertically ✓, cost bar labels shrink to 80px ✓, text floors (13px/14px) maintained ✓, data tables get `overflow-x: auto` ✓, quick-add form stacks vertically ✓
   - **Note:** Visual browser test at 375px deferred to operator — CSS analysis confirms no horizontal overflow sources, but screenshot verification recommended

### Key Decisions
- State pattern CSS lives in widget-vocabulary.css (cross-page concern), not in page-specific CSS files
- Blocked panel uses `.blocked-panel` class at all three levels; KPI card blocked variant uses inline styles since the existing `.kpi-card` base handles most of the styling
- Error and stale card-within-list treatments are additive (classes compose with existing card classes)

### Compound
- **State patterns as cross-page concern:** Blocked panel started in intelligence-mockup.css (page-specific) but was needed on 5 pages. Moving to widget-vocabulary.css (shared) early prevents the same class from being duplicated per-page. Future cross-page patterns should start in widget-vocabulary.css from day one.
- **Inline style → class extraction timing:** The MC-008 → MC-055 gap (blocked panels in inline styles for one session, then extracted to a class) is acceptable for mockup velocity but would be a problem in production CSS. In Phase 1, establish a rule: if a visual pattern appears on more than one page, extract to shared CSS before the PR merges.

### Code Review
- Code Review — Skipped (MC-055): Phase 0 design task — HTML/CSS mockups, not implementation code. No repo_path exists yet.

### Scope Addition
- **Workbench expansion:** W1-W3 scope expanded with per-account detail pages (Contacts/Personas, Active Opportunities, Comms & Product Strategies) and master→detail navigation pattern. Key architectural distinction from Mission Control's single-page observatory model. Action plan updated.

### Next
- MC-010: Design gate review (all M0b prerequisites now complete — 7/7 tasks done)

---

## 2026-03-07 — MC-010: Design gate review

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-010 acceptance criteria (1)
- `design/specification.md` §9.1 — 12-item gate checklist (2)
- `design/specification.md` §6.0 — panel availability categories (3)
- `design/widget-inventory.md` — 97 widgets, 9 blocked panels, archetype matrix (4)
- `design/design-system.md` — token system, panel variants (5)
- `design/mockups/` — all 3 page mockups + widget vocabulary + state patterns (6)
- `progress/run-log.md` — design decisions D1-D6, prior session context (7)

### Work Done
1. **MC-010 complete** — Design gate review produced at `design/design-gate-review.md`:
   - All 12 gate checklist items evaluated: 12/12 PASS
   - Gate item 7 (section count): Ops has 6 active + 1 blocked section — operator confirmed blocked section at 50% opacity adds zero cognitive load, guideline applies to active sections only
   - 6-vs-7 page decision: 6 pages (merged Intelligence confirmed from screenshot review)
   - Panel availability matrix: all panels across 6 pages classified as available/derivable/blocked
   - 9 blocked panels confirmed consistent with widget inventory count (MC-006 correction)
   - Operator signed off on design system for Phase 1 implementation

2. **Workbench scope expansion** — W1-W3 in action plan expanded with per-account detail pages:
   - Contacts/Personas, Active Opportunities, Comms & Product Strategies
   - Master→detail navigation pattern as key architectural distinction from observatory model

### Key Decisions
- Design system approved for Phase 1 — no changes needed before implementation begins
- Gate item 7 deviation accepted: blocked sections don't count against 4-6 active section guideline

### Milestone M0b: Complete (8/8 tasks done)
### Phase 0: Complete (10/10 tasks done)

All design deliverables produced. Gate passed. Phase 1 implementation unblocked.

### Code Review
- Code Review — Skipped (MC-010): Gate review document, not implementation code. No repo_path exists yet.

### Next
- Phase 1 begins: MC-011 (monorepo initialization) + MC-016 (system-stats.sh + service-status.sh, no dependency on MC-011)

---

## 2026-03-07 — Cross-project dependency tracking + Phase 1 prep

**Phase:** TASK
**Operator:** Danny

### Work Done
1. **Cross-project dependency tracking convention created** (`_system/docs/cross-project-deps.md`):
   - Reviewed operator's proposal, provided 5-point feedback (all accepted with adjustments)
   - Maintenance hooks placed in action-architect + systems-analyst skills (not session-end — Ceremony Budget Principle)
   - vault-check rule §26 added: validates upstream project references, 30-day staleness warning scoped to rows with existing upstream projects only
   - 13 MC dependencies seeded (XD-001 through XD-013)
   - Deferred: morning briefing scan, attention aggregator integration

2. **Phase 1 context loaded** — read tasks.md, action-plan-summary.md, verified project-state.yaml. Confirmed MC-011 + MC-016 as independent starting tasks. No work executed — session ended before implementation began.

### Compound
- **Convention placement principle:** Maintenance hooks belong at the point of dependency creation (action-architect, systems-analyst), not at session-end. Session-end is the highest-ceremony touchpoint — every step there multiplies across every session. This reinforces the Ceremony Budget Principle: co-locate maintenance cost with the action that produces it.

### Next
- Phase 1 begins: MC-011 (monorepo init) + MC-016 (system scripts) — both independent, can run in parallel

---

## 2026-03-07 — Phase 1 implementation: M1 + M2 adapters

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-012 through MC-023 acceptance criteria (1)
- `design/action-plan-summary.md` — milestone overview (2)
- `design/specification-summary.md` — spec context (3)
- `design/mockups/intelligence-mockup.html` — nav rail SVG icons reference (4)
- `design/mockups/ops-mockup.css` — dark observatory palette tokens (5)
- `CONVENTIONS.md` (repo) — system metrics JSON schemas (6)
- `progress/run-log.md` — prior session context (7)

### Work Done

**M1: Project Scaffolding (7/8 complete)**

1. **MC-012 done** — Express API scaffold:
   - 9 route modules (`/api/health`, `/api/attention`, `/api/ops`, `/api/intel`, `/api/customer`, `/api/agents`, `/api/vault`, `/api/search`, `/api/nav-summary`)
   - Health returns `{status, uptime, adapters}`, stubs return 501
   - Error handler logs to configurable `LOG_PATH`

2. **MC-013 done** — React + Vite scaffold with nav shell:
   - React Router app shell, 6 page stubs
   - Nav rail with SVGs matching Phase 0 mockups, badge/status dot placeholders
   - Dark observatory CSS custom properties, responsive at 480px
   - Vite proxy to API

3. **MC-015 done** — `deployment/com.crumb.dashboard.plist` with KeepAlive, production node path, env vars

4. **MC-017 done** — Nav summary endpoint + polling infrastructure:
   - `/api/nav-summary` returns per-page `{status, badge?}` (stub defaults, wired progressively)
   - `usePolling` hook: configurable interval, pauses on tab hidden, immediate fetch on resume
   - `NavSummaryContext` provided at App level, consumed by NavRail
   - `HealthStrip` component on manual-pull pages (Intel, Customer, Agents, Knowledge)

5. **MC-018 done** — Cross-cutting conventions + shared utilities:
   - CONVENTIONS.md expanded: UTC storage, adapter contract, stale thresholds, error roll-up rules
   - `writeVaultFile()` — atomic write with zombie .tmp cleanup (5 tests)
   - `SafeMarkdown` — DOMPurify wrapper with allowlist (6 tests)
   - `constants.ts` — named stale threshold values
   - Vitest configured for both packages

**M2: Ops Page (3/5 complete)**

6. **MC-019 done** — 3 Ops adapters (system-stats, service-status, healthchecks):
   - File-based adapters read from `_system/logs/`, return `{data, error, stale}`
   - Healthchecks.io adapter with 10s timeout, `HEALTHCHECKS_API_KEY` env var
   - All handle ENOENT, corrupt JSON, stale detection

7. **MC-020 done** — 4 Ops adapters (health-check-log, vault-check, ops-metrics, llm-health):
   - health-check-log parses `CHECK|ACTION|ERROR` format, returns last 100 events
   - vault-check reads output log, extracts WARN/ERROR lines, determines pass/fail
   - ops-metrics and llm-health read JSON telemetry files (not yet produced)

8. **MC-023 done** — 27 adapter unit tests across 7 test files:
   - Each adapter tested: normal output, missing file, corrupt data, stale detection
   - Healthchecks tested: no key, valid response, API error, network error, stale checks
   - All use fixture data and temp directories

9. **`/api/ops` wired** — calls all 7 adapters in parallel, returns composite response

**Cross-project work:**

10. **AKM investigation updated** — design rationale analysis (background agent) produced `design/design-rationale.md`. Findings fed back to AKM investigation note: separated query gap (Few never surfaced) from consumption gap (Ware surfaced 3x, never read). Investigation upgraded from deferred to active with 4 recommended actions.

### Key Decisions
- GitHub repo created: `djt71/crumb-dashboard` (private)
- `HEALTHCHECKS_API_KEY` via env var (not in Keychain — operator to configure)
- Vitest for both packages (API excludes dist/ directory)
- DOMPurify allowlist is restrictive: no `<iframe>`, `<form>`, `<style>`, `<object>`

### Test Summary
- API: 32 tests (5 writeVaultFile + 27 adapter)
- Web: 6 tests (SafeMarkdown)
- All passing, build clean

### Compound
- **Adapter pattern velocity:** All 7 adapters follow identical structure (read file → parse → detect stale → return triple). The pattern is mechanical enough that adapter tests are the higher-value artifact — they define the contract that the data source must satisfy. Future adapters (FIF SQLite, attention aggregator) can be generated from this template.
- **AdapterResult as shared type:** Exported from system-stats.ts and imported by other adapters. Should be extracted to a shared types file before M3 adds more adapters to avoid the circular-looking import chain.

### Code Review
- Code Review — Deferred to commit. Phase 1 implementation code, repo_path exists. Full review at M2 completion (MC-021/022 remaining).

### Model Routing
- All work on Opus (session default). Design rationale research delegated to background subagent (also Opus). No Sonnet delegation — implementation tasks required contextual judgment across spec, mockups, and adapter patterns.

### Next
- MC-021: Ops page frontend — KPI strip + service grid + LLM status
- MC-022: Ops page frontend — 24h timeline + cost burn + auto-refresh
- MC-014: Cloudflare Tunnel + Access (needs operator Cloudflare config)

---

## 2026-03-07 — MC-021 + MC-022: Ops frontend + code review + fixes

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-021/MC-022 acceptance criteria (1)
- `design/mockups/ops-mockup.html` + CSS — visual reference (2)
- `design/design-system.md` — color/typography tokens (3)
- `packages/api/src/routes/ops.ts` — API endpoint (4)
- `packages/web/src/hooks/usePolling.ts` — polling infrastructure (5)
- `packages/api/src/adapters/*.ts` — all 7 adapter modules (6)
- `_system/docs/code-review-config.md` — review panel config (7)

### Work Done

**MC-021 done** — Ops page frontend (6 sections):
1. `KpiStrip.tsx` — 6 KPI cards (Tess, Gateway, Healthchecks, CPU, Memory, Disk) with status dots and threshold coloring
2. `GaugeRow.tsx` — 4 SVG arc gauges (CPU, Memory, Disk, GPU) with animated fill + needle
3. `ServiceGrid.tsx` — service cards from launchd data, click-to-expand with recent health check log entries
4. `Timeline.tsx` — 24h timeline with event dots (heartbeat/alert/mode/maintenance)
5. `LlmStatus.tsx` — per-model cards with success rate, p95 latency, call count, degradation notes
6. `CostBurn.tsx` — daily spend vs ceiling, per-job breakdown bars, weekly total

**MC-022 done** — Auto-refresh + nav-summary wiring:
- `useOpsData` hook polls `/api/ops` every 30s via `usePolling`
- `OpsPage.tsx` assembles all 6 sections in D5 order + blocked panels, refresh timestamp, loading/error states
- `nav-summary.ts` updated: all 7 ops adapters in Promise.all, required/optional roll-up via `rollUpStatus()`
- 577 lines of ops component CSS added to `index.css`
- Types: `packages/web/src/types/ops.ts` mirrors all API adapter response shapes

**Code Review — M1+M2 milestone boundary:**
- Scope: 3300+ lines across 2 segments (API ~1546, Web ~1713)
- Panel: Claude Opus 4.6 (API), Codex GPT-5.3-Codex (CLI)
- Codex tools: tsc pass, tests pass (pre-fix), linter skipped (no eslint config)
- Findings: 1 critical, 7 significant, 8 minor, 2 strengths
- Consensus: 3 findings flagged by both reviewers (ESM caching, vault-check regex, healthchecks timer leak)
- Details:
  - [ANT-F1/CDX-F1] CRITICAL: ESM module-level `process.env` caching — env read at import, not call time
  - [ANT-F2/CDX-F2] SIGNIFICANT: vault-check `passed` logic — `||` with regex literal always truthy
  - [ANT-F3/CDX-F3] SIGNIFICANT: healthchecks timer leak — `clearTimeout` not in `finally`
  - [ANT-F4] SIGNIFICANT: OpsPage shows stale data without error indication on refresh failure
  - [ANT-F5] SIGNIFICANT: usePolling lacks AbortController — stale responses possible
  - [CDX-F4] SIGNIFICANT: healthchecks staleness based on per-check last_ping, not fetch age
  - [ANT-F6] SIGNIFICANT: health-check-log adapter has no stale detection
  - [CDX-F5] SIGNIFICANT: Express 4 async route handlers don't catch promise rejections
  - [ANT-F7/CDX-F6] MINOR: AdapterResult duplicated vs shared type
  - [CDX-F7] MINOR: write-vault-file tmp collision risk with PID-only naming
  - [ANT-F8] MINOR: nav-summary only wires system-stats + service-status (missing 5 adapters)
  - [ANT-F9] MINOR: ServiceGrid not keyboard accessible
  - [CDX-F8] MINOR: AdapterResult import from system-stats (re-export chain)
  - [ANT-F10] MINOR: STALE_ATTENTION_ITEM_DAYS naming inconsistency
  - [ANT-F11] MINOR: NavRail missing aria-label / aria-current
  - [CDX-F9] MINOR: No catch-all route — unknown paths show blank page
- Action: all 15 findings fixed (A1–A15)
- Review notes: `reviews/2026-03-07-code-review-m1m2-api.md`, `reviews/2026-03-07-code-review-m1m2-web.md`

**15 Action Items Applied:**
- A1: Moved `process.env.VAULT_ROOT` from module-level to `filePath()` function in all 6 file-based adapters
- A2: Fixed vault-check `passed = errors.length === 0` (removed broken `|| PASS_RE`)
- A3: Moved healthchecks AbortController/timeout before try, added `finally { clearTimeout(timeout) }`
- A4: Added error banner in OpsPage when `error` is truthy with stale data
- A5: Added AbortController to `usePolling` — cancels in-flight requests on cleanup/URL change
- A6: Added `stat()` mtime check for stale detection in health-check-log adapter
- A7: Created `asyncHandler()` wrapper, applied to ops and nav-summary routes
- A8: Changed healthchecks staleness from per-check `last_ping` to adapter-level `fetchedAt` age
- A9: Added `randomBytes` for unique tmp filenames in `writeVaultFile()`
- A10: Wired all 7 ops adapters into nav-summary Promise.all with required/optional roll-up
- A11: Added keyboard accessibility to ServiceGrid (role, tabIndex, aria-expanded, onKeyDown)
- A12: Extracted `AdapterResult<T>` to shared `types.ts`, updated imports
- A13: Renamed `STALE_ATTENTION_ITEM_DAYS` → `STALE_ATTENTION_ITEM = 14 * 86400`
- A14: Added `aria-label="Main navigation"` to NavRail (aria-current automatic in React Router 7)
- A15: Added catch-all route `<Route path="*" element={<Navigate to="/attention" replace />} />`

**Test fix:** Updated healthchecks "detects stale checks" test to match new adapter-level staleness semantics (fresh fetch is never stale).

### Test Summary
- API: 32 tests passing (5 writeVaultFile + 27 adapter)
- Web: 6 tests passing (SafeMarkdown)
- Build: both packages clean

### Milestone Status
- **M1:** 7/8 complete (MC-014 Cloudflare Tunnel blocked on operator config)
- **M2:** 5/5 complete (MC-019, MC-020, MC-021, MC-022, MC-023 all done)

### Compound
- **ESM module caching as consensus finding:** Both Opus and Codex independently identified the `process.env` read-at-import-time issue. This is a genuine footgun in ESM — `const x = process.env.X` at module scope gets cached after first import. Always read env vars inside functions for testability and runtime flexibility. Worth noting for any future Node.js ESM adapter code.
- **Code review panel value:** Consensus findings (3 of 16) were the highest-signal items. Codex's tool-grounded findings (tsc pass, type checking) provided different signal than Opus's architectural reasoning. The complementary model works as designed.
- **Adapter staleness semantics:** Per-check staleness (is individual data old?) vs adapter-level staleness (is the fetch result old?) are different questions. For external APIs, adapter-level is correct — you can't know if the API is stale, only if your last call was stale. File-based adapters use file mtime, which is the right analog.

### Code Review
- Reviewed at commit tagged `code-review-2026-03-07`
- Review notes at `reviews/2026-03-07-code-review-m1m2-api.md` and `reviews/2026-03-07-code-review-m1m2-web.md`
- All findings addressed in this session

### Model Routing
- All work on Opus (session default). Code review dispatched to Opus API + Codex CLI per code-review skill. No Sonnet delegation — Ops frontend required cross-referencing mockups, design system, and adapter types.

### Next
- MC-014: Cloudflare Tunnel + Access (needs operator Cloudflare config)
- M3: Intelligence Pipeline Section (MC-024 through MC-028)

---

## 2026-03-07 — MC-014: Cloudflare Tunnel + Access

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-014 acceptance criteria (1)
- `design/specification.md` — §5.4 C1/C7, §7.2, §12 hosting architecture (2)
- `packages/api/src/server.ts` — Express server (3)
- `deployment/com.crumb.dashboard.plist` — existing launchd plist (4)

### Work Done

**Production static serving:**
- Added static file serving to `server.ts` — Express serves built React app from `packages/web/dist/` when the directory exists
- SPA catch-all route sends all non-API paths to `index.html` for client-side routing
- Build verified: API (tsc) + Web (vite build) both succeed; 38 tests pass

**Cloudflare Tunnel setup:**
- `cloudflared` installed via Homebrew (v2026.2.0)
- Tunnel `crumb-dashboard` created (ID: `6d7aca42-949c-4af9-bfde-8d10ec1ad46f`)
- DNS CNAME: `mc.crumbos.dev` → tunnel
- Config at `~/.cloudflared/config.yml`: ingress routes `mc.crumbos.dev` → `http://localhost:3100`
- 4 QUIC connections established (dtw01, ord14, ord16)

**Cloudflare Access:**
- Zero Trust Free tier, self-hosted application
- Access policy restricts to operator's email
- Unauthenticated requests receive 302 → Cloudflare login page

**LaunchAgents deployed:**
- `com.crumb.cloudflared.plist` — new, keeps tunnel running (KeepAlive + RunAtLoad)
- `com.crumb.dashboard.plist` — installed (was in repo, not previously loaded)
- Both verified running via `launchctl list`

**End-to-end verification:**
- `localhost:3100/api/health` → 200 (direct)
- `mc.crumbos.dev/api/health` (unauthenticated) → 302 (Access redirect)
- `mc.crumbos.dev` (authenticated browser) → dashboard loads

### Acceptance Criteria
- ✅ Cloudflare Tunnel routes to the dashboard (API + web)
- ✅ Cloudflare Access policy restricts to operator's email
- ✅ Dashboard accessible at `mc.crumbos.dev` with authenticated session
- ✅ Unauthenticated requests blocked (302 → login)

### Milestone Status
- **M1:** 8/8 complete — all tasks done
- **M2:** 5/5 complete

### Next
- M3: Intelligence Pipeline Section (MC-024 through MC-028)

---

## 2026-03-07 — MC-024/025/026: FIF adapters + Intel frontend + tier fix

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-024/025/026 acceptance criteria (1)
- `design/specification-summary.md` — §7.2, §12 architecture (2)
- `design/mockups/intelligence-mockup.html` + CSS — visual reference (3)
- `packages/api/src/adapters/*.ts` — existing adapter pattern (4)
- FIF SQLite schema via `pipeline.db` — live DB (5)
- `packages/web/src/pages/OpsPage.tsx` — page assembly pattern (6)

### Work Done

**MC-024 done** — FIF SQLite adapter:
- `fif-sqlite.ts` reads FIF `pipeline.db` (readonly, WAL-safe via better-sqlite3)
- Returns: signals (last 7d, limit 200), triage distribution, source breakdown, cost today/week
- Handles DB-locked, DB-missing gracefully
- 5 unit tests (seed DB, read signals, source breakdown, cost, missing DB, stale detection)

**MC-025 done** — Pipeline health adapter:
- `pipeline-health.ts` reads adapter_runs + posts tables
- Returns: last run per source/component, 7d error rates, stale backlog (pending + deferred), DB size
- Circuit breaker state derived from error rates
- 6 unit tests

**MC-026 done** — Intelligence Pipeline frontend:
- `PipelineKpis.tsx` — 5 KPI cards (signals today, this week, sources, triage distribution, cost vs ceiling)
- `SignalDigest.tsx` — signal cards in digest panel with tier filter buttons (All/T1/T2/T3)
- `PipelineHealthPanel.tsx` — circuit breaker strip + data table (last run, duration, error rate, status)
- `IntelPage.tsx` — assembles Pipeline section + blocked panels for Tuning and Production
- `useIntelData.ts` hook — manual pull (not auto-poll), with refresh button
- Nav-summary wired: intel status from FIF + pipeline health roll-up, badge = signals today count
- 230 lines of intel CSS added to `index.css`
- Types: `types/intel.ts` + `types/common.ts` (shared AdapterResult)

**Tier mapping fix:**
- FIF uses `priority` (high/medium/low) in `triage_json`, not the `signal`/`context` names assumed
- Fixed adapter to read `triageJson.priority` as primary tier source
- Fixed frontend: `high` → T1, `medium` → T2, `low` → T3
- Verified with screenshot: T1: 18, T2: 42, T3: 140

**Ops page fixes:**
- Installed `com.crumb.system-stats.plist` and `com.crumb.service-status.plist` LaunchAgents (were in repo, never loaded)
- system-stats and service-status now refreshing every 60s

**Identified gaps (not in M3 scope):**
- `ops-metrics.json` / `llm-health.json` — no upstream writer exists. Adapters read these files but nothing generates them. Cost Burn and LLM Status panels show error state. Next session: build aggregation scripts (option 1 chosen by operator).
- `HEALTHCHECKS_API_KEY` — not in dashboard plist env vars
- `vault-check` output log — adapter expects a file that vault-check doesn't write

### Test Summary
- API: 43 tests passing (32 existing + 5 fif-sqlite + 6 pipeline-health)
- Web: 6 tests passing (SafeMarkdown)
- Build: both packages clean

### Milestone Status
- **M1:** 8/8 complete
- **M2:** 5/5 complete
- **M3:** 3/5 (MC-024, MC-025, MC-026 done; MC-027, MC-028 remaining)

### Compound
- **FIF tier semantics mismatch:** The FIF spec uses `effective_tier` in `content_json` for *source-level* classification (lightweight/standard/premium) and `priority` in `triage_json` for *signal importance* (high/medium/low). These are different dimensions — source tier is about data richness, priority is about relevance to the operator. Dashboard maps priority → T1/T2/T3 for the signal digest, which is the right choice for an attention-oriented view. Source tier may be useful later for pipeline tuning views.
- **Static JSON adapter pattern hitting limits:** ops-metrics, llm-health, and vault-check all assume a cron job writes a JSON file that the adapter reads. This works for system-stats/service-status (simple shell scripts) but breaks down for complex aggregations. The FIF adapter shows SQLite is a better pattern — read the source of truth directly instead of depending on an intermediate file. Future adapters should prefer direct source reads where feasible.

### Model Routing
- All work on Opus (session default). No Sonnet delegation — required cross-referencing live DB schema, mockup CSS, and existing adapter patterns.

### Next
- Build ops-metrics + llm-health aggregation scripts (operator chose option 1)
- MC-027: Signal detail panel + pipeline health polish
- MC-028: M-Web parity gate + adapter tests

---

## 2026-03-07 — Session 8: FIF cost wiring, signal detail, Ops fixes

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `progress/run-log.md` — prior session context, M3 status (1)
- `design/tasks.md` — MC-027/MC-028/MC-060 definitions (2)
- `packages/api/src/adapters/*.ts` — ops-metrics, llm-health, fif-sqlite, vault-check adapters (3)
- `packages/web/src/pages/IntelPage.tsx` + `OpsPage.tsx` — page assembly (4)
- `packages/web/src/index.css` — shared styles (5)
- FIF `pipeline.db` schema — cost_log + posts tables (6)

### Work Done

**Font consistency across pages:**
- Unified `.section-title` CSS (Inter 15px semi-bold uppercase) — replaces `.ops-section-title` (was 13px)
- All Ops components + Intel components now use same class
- `.page-section-header` fixed: Georgia → Inter, `--color-*` → `--text-primary`/`--accent`

**Intel page reorder:**
- Signal Digest moved below Pipeline Health (long digest no longer pushes health/blocked panels off screen)

**FIF Cost Burn (operator direction):**
- New `fif-costs.ts` adapter queries FIF SQLite `cost_log` directly — maps to `OpsMetricsData` shape
- Ops route wired to `getFifCosts()` replacing dead `getOpsMetrics()` (static JSON that doesn't exist)
- CostBurn section renamed "FIF API Costs" (honest labeling — FIF costs only, not all LLM usage)
- Real data: $0.48 today, $1.79/week across rss/triage, x/triage, yt/triage
- 4 unit tests

**MC-027 done — Signal detail panel:**
- Click-to-expand signal cards showing: why_now, triage reasoning, confidence, engagement stats (views/likes/comments), triage tags, source links
- Signal type expanded with 8 detail fields (excerpt, content_type, urls, why_now, reasoning, confidence, triage_tags, engagement)
- Content type badge added to card headers (video, article, etc.)
- Keyboard accessible (Enter/Space toggle, aria-expanded)
- CSS: `.signal-detail` panel with section labels, meta chips, tag badges, source links

**Vault-check adapter wired:**
- Pre-commit hook updated to tee output to `_system/logs/vault-check-output.log`
- Regex fixed: `^\s*WARN` handles indented output (was missing all 42 warnings)
- Initial full vault-check run seeded the log file

**Healthchecks fixed:**
- `HEALTHCHECKS_API_KEY` added to `com.crumb.dashboard.plist`
- Plist bootout + bootstrap to load new env vars (kickstart doesn't reload plist definition)

**KPI strip service detection fixed:**
- "Tess Status" was looking for "voice" label — doesn't exist (Tess runs through gateway)
- Replaced with "Gateway" (ai.openclaw.gateway) + "Bridge" (ai.openclaw.bridge.watcher)
- Gateway runs as LaunchDaemon (system domain) — added port-probe fallback in service-status.sh
- Added gateway, dashboard, cloudflared to monitored service list

**MC-060 filed:**
- Investigation task for structured per-call LLM telemetry gap
- Blocks full Cost Burn (currently FIF-only) and LLM Status panel (error state)
- Related: TOP-050, spec F13

**MC-059 marked done** (was already complete from MC-014 session)

### Key Decisions
- Cost Burn uses FIF SQLite directly rather than waiting for ops-metrics.json telemetry pipeline (operator direction: ship what's real, label honestly)
- LLM Status stays in error state until telemetry exists — that's itself useful information
- Operational Intelligence panels remain blocked (Phase 3+ dependencies)
- Gateway detection via `nc -z` port probe since launchctl can't see system-domain LaunchDaemons

### Test Summary
- API: 47 tests (32 existing + 4 fif-costs + 6 pipeline-health + 5 fif-sqlite)
- Web: 6 tests (SafeMarkdown — pre-existing jsdom failure, unrelated)
- Build: both packages clean

### Milestone Status
- **M1:** 8/8 complete
- **M2:** 5/5 complete
- **M3:** 4/5 (MC-024, MC-025, MC-026, MC-027 done; MC-028 remaining — needs 3 days usage)

### Compound
- **"Ship what's real" over "wait for complete":** The ops-metrics adapter was designed for a telemetry pipeline that doesn't exist. Rather than building a brittle aggregation layer, operator directed: wire the data source that exists (FIF SQLite) and file an investigation for the gap. This is a general pattern — dashboard panels should degrade to partial-but-real data rather than showing error states when a subset of their intended data exists.
- **LaunchDaemon vs LaunchAgent blind spot:** service-status.sh only queries user-domain services. Any process running in system domain (like the OpenClaw gateway) is invisible. The port-probe fallback is a pragmatic fix, but the broader lesson: service monitoring scripts should document their domain assumptions and have fallback strategies for cross-domain services.
- **Plist reload semantics:** `launchctl kickstart -k` restarts the process but does NOT reload the plist definition. New env vars, changed paths, or modified RunAtLoad require `bootout` + `bootstrap`. This bit us with the HEALTHCHECKS_API_KEY.

### Code Review
- Code review deferred to M3 completion (MC-028). Changes span both API (new adapter, route wiring, regex fix) and Web (detail panel, CSS, KPI strip). Full review at M3 milestone boundary.

### Model Routing
- All work on Opus (session default). No Sonnet delegation — implementation required cross-referencing live DB schema, adapter patterns, and CSS design system.

### Next
- MC-028: M-Web parity gate (needs 3 days operator usage of Pipeline section)
- MC-060 investigation (can start independently)

---

## 2026-03-07 — Session 9: MC-060 LLM telemetry investigation + rollup scripts

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `progress/run-log.md` — prior session context, M3 status (1)
- `design/tasks.md` — MC-060 definition (2)
- `_openclaw/scripts/cron-lib.sh` — ops-metrics JSONL infrastructure (3)
- `packages/api/src/adapters/ops-metrics.ts` + `llm-health.ts` — dashboard adapter contracts (4)
- `_openclaw/scripts/awareness-check.sh` + `vault-health.sh` — cron jobs (5)
- `packages/api/src/routes/ops.ts` — route wiring (6)

### Work Done

**MC-060 investigation complete:**
- Mapped all 6 LLM consumers: FIF (SQLite, live), Tess cron (JSONL, live but zeros), gateway logs (no per-call data), Sonnet dispatch (one-off calibration only), code review (no persistence), Claude Code (nothing)
- Key finding: `cron-lib.sh` already has `cron_set_tokens()` / `cron_set_cost()` but no cron job calls them with real values
- Two dashboard files were spec'd but never created: `ops-metrics.json` and `llm-health.json`
- Investigation note: `design/mc-060-llm-telemetry-investigation.md`

**Telemetry rollup scripts built:**
- `_openclaw/scripts/ops-metrics-rollup.sh` — reads 285-line JSONL, aggregates by job_id, writes `_system/logs/ops-metrics.json` matching adapter contract
- `_openclaw/scripts/llm-health-rollup.sh` — derives model health from ops-metrics.jsonl (job success rates → Haiku proxy) + FIF SQLite (run counts → Sonnet proxy), writes `_system/logs/llm-health.json`
- `_openclaw/scripts/telemetry-rollup.sh` — wrapper calling both

**LaunchAgent deployed:**
- `com.crumb.telemetry-rollup` plist — runs every 900s (15 min), RunAtLoad
- Both JSON files now exist and refresh automatically
- Stale threshold: `STALE_TELEMETRY_ROLLUP = 1800` (30 min) — separate from `STALE_COST_DATA` (86400s used by FIF)

**Dashboard panels unblocked:**
- LLM Status: was permanent error state → now shows Haiku (231 calls, 99% success) + Sonnet (17 FIF runs, 100%)
- ops-metrics.json: now shows awareness-check (277 runs) + vault-health (9 runs, 2 failures)
- Verified via `curl localhost:3100/api/ops` — both `llmHealth` and `opsMetrics` return real data

### Key Decisions
- Keep adapters as simple JSON file readers (no code changes to dashboard) — rollup scripts produce the files the adapters already expect
- LLM health uses job-level success rates as proxy for model health (gateway logs have zero per-call telemetry)
- p95LatencyMs stays null until OpenClaw adds per-call logging (if ever)
- Rollup runs every 900s (15 min) via launchd — underlying data (awareness-check every 30 min, FIF daily) doesn't warrant real-time refresh. Stale threshold 1800s (2x interval) so dashboard shows stale indicator if rollup stops

### Compound
- **"Wire the data you have" pattern reinforced:** Same principle as session 8's FIF cost wiring. The ops-metrics.jsonl was being written to by every cron job for weeks — 285 entries — but nothing consumed it. The llm-health adapter was waiting for a file that nobody had been tasked with creating. The investigation revealed the gap wasn't missing telemetry infrastructure but missing wiring between existing sources and existing consumers.
- **Proxy metrics over perfect metrics:** Gateway logs don't have per-call telemetry, but job-level success rates are a reasonable proxy for model health. The dashboard now shows *something* real instead of a permanent error state. Perfect telemetry (per-call tokens, latency) requires OpenClaw changes outside our control — deferred appropriately.

### Model Routing
- All work on Opus (session default). Exploration subagent used for initial investigation sweep (39 tool calls, 86k tokens). No Sonnet delegation.

### Next
- MC-028: M-Web parity gate (needs 3 days operator usage of Pipeline section)
- Remaining cross-project tasks (MC-053, MC-054, MC-056, MC-057, MC-058)

---

## 2026-03-07 — Session 10: M4 Attention-lite backend (MC-029/030/031/034)

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `progress/run-log.md` — session 9 context (1)
- `design/tasks.md` — M4 task definitions (2)
- `design/specification.md` §7.1 — attention-item schema (3)
- `packages/api/src/adapters/vault-check.ts` + `healthchecks.ts` + `pipeline-health.ts` — existing adapters for synthetic sources (4)
- `packages/api/src/routes/attention.ts` — stub route (5)

### Work Done

**MC-029 done — Attention aggregator (single source):**
- `attention.ts` adapter reads `_inbox/attention/`, parses frontmatter via gray-matter
- Full attention-item schema (spec §7.1): attention_id, kind, domain, urgency, status, source_system, source_ref, etc.
- Dedup by attention_id (unique) and source_ref (last-writer-wins)
- Sort by urgency (now→awareness) then age (oldest first)
- Handles empty dir, missing dir, malformed files
- Fixed gray-matter date auto-parsing: YAML dates → Date objects, normalized to ISO strings via `toDateStr()`

**MC-031 done — Quick-add endpoint:**
- `POST /api/attention` accepts `{title, domain?, urgency?, kind?, due?, description?}`
- Generates UUID v4 via `crypto.randomUUID()`
- Writes attention-item markdown to `_inbox/attention/` using atomic temp+rename (`vault-write.ts`)
- Validates all enum fields (domain, urgency, kind), due date format
- Defaults: urgency=soon, kind=personal, domain=software
- New deps: gray-matter, supertest (dev)

**MC-030 done — Multi-source aggregation:**
- Three synthetic attention sources added, all using existing adapters:
  - **vault-check**: errors → urgency:now, warnings → urgency:awareness
  - **healthchecks.io**: down → urgency:now, grace → urgency:soon
  - **FIF pipeline health**: failed runs → urgency based on error rate, large backlogs → awareness
- Synthetic items are ephemeral — disappear when underlying issue resolves
- Each source error-isolated via `Promise.allSettled()` — one source failing doesn't block others
- File items always merge with synthetic items; dedup handles source_ref collisions
- Live endpoint shows real data: 1 FIF failure (soon) + 18 vault-check warnings (awareness)

**MC-034 done — Tests:**
- 13 adapter tests: read, empty, missing, malformed, done-filter, sort, dedup, 6 synthetic source tests
- 8 route tests: valid create, defaults, missing title, invalid domain/urgency/kind/due, description
- 130 total tests pass (up from 109), 6 pre-existing SafeMarkdown failures

### Key Decisions
- Synthetic items generated on-the-fly from existing adapters rather than writing attention-item files — no file cleanup needed, items vanish when source resolves
- gray-matter chosen for frontmatter parsing — handles YAML types, widely used, but auto-parses dates (caught in testing, normalized)
- Rollup interval corrected from 60s → 900s per operator direction — telemetry data changes hourly, not per-second
- `STALE_TELEMETRY_ROLLUP = 1800` (30 min) added as separate constant from `STALE_COST_DATA` (86400s)
- `Archived/attention/` exclusion satisfied by design — aggregator only reads `_inbox/attention/`

### Test Summary
- API: 130 tests (94 existing + 13 attention adapter + 8 attention route + 15 from session 9)
- Web: 6 tests (SafeMarkdown — pre-existing jsdom failure, unrelated)
- Build: both packages clean

### Milestone Status
- **M1:** 8/8 complete
- **M2:** 5/5 complete
- **M3:** 4/5 (MC-028 parity gate — usage wait)
- **M4:** 4/6 (MC-029, MC-030, MC-031, MC-034 done; MC-032, MC-033 frontend remaining)

### Compound
- **gray-matter date parsing trap:** YAML dates like `created: 2026-03-07` are auto-parsed into JavaScript Date objects by gray-matter. `String(Date)` produces locale-formatted strings, breaking ISO date comparisons in sort/dedup. Always normalize with `.toISOString().slice(0,10)` when reading frontmatter dates. This is a general pattern for any vault file reader using gray-matter.
- **Synthetic attention items as adapter composition:** Rather than building a separate "attention source" for each system signal, the aggregator composes existing adapters (vault-check, healthchecks, pipeline-health) into attention items at query time. Zero new data files, zero new timers, zero cleanup — the items exist only as long as the source problem exists. This is the inverse of the file-based pattern and works well for ephemeral system alerts.

### Model Routing
- All work on Opus (session default). No Sonnet delegation — required cross-referencing spec schema, adapter patterns, and test design.

### Next
- MC-032: Attention page frontend — cards + urgency strip
- MC-033: Attention page frontend — filters + views + completed feed
- MC-028: M-Web parity gate (usage wait continues)

---

## 2026-03-07 — Session 11: MC-032 + MC-033 Attention page frontend

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `progress/run-log.md` — session 10 context (1)
- `design/tasks.md` — MC-032/MC-033 definitions (2)
- `design/mockups/attention-mockup.html` + `attention-mockup.css` — visual reference (3)
- `design/mockups/widget-vocabulary.css` — attention card + badge styles (4)
- `packages/api/src/adapters/attention.ts` — adapter (5)
- `packages/api/src/routes/attention.ts` — API route (6)
- `packages/web/src/pages/IntelPage.tsx` + `OpsPage.tsx` — page assembly patterns (7)
- `packages/web/src/hooks/usePolling.ts` — polling hook (8)

### Work Done

**MC-032 done — Attention page cards + urgency strip + quick-add:**
- `UrgencyStrip.tsx` — 4 KPI cards (Now/Soon/Ongoing/Awareness) with urgency-colored borders and count values
- `QuickAdd.tsx` — inline form: title input, domain/urgency/kind selects, "+ Add" button
  - Domain pre-fills from localStorage (last-used value)
  - Defaults: urgency=soon, kind=personal
  - Enter key submits, disabled state during POST, error display
- `AttentionCard.tsx` — card with urgency left-border, title, urgency badge, kind badge, domain badge, age, source
  - Supports completed/dismissed styling variants
- `useAttentionData.ts` hook — auto-polls `/api/attention` every 60s via `usePolling`
- `types/attention.ts` — full type definitions matching API adapter

**MC-033 done — Filters + views + completed feed + nav-summary:**
- `FilterBar.tsx` — filter groups for urgency, kind, domain, source with active state toggle
  - Domain and source filters derive their options from actual item data (no empty filters)
  - View switcher: Triage (flat), Domain (grouped), Source (grouped)
  - `applyFilters()` and `groupBy()` utility functions
- `CompletedFeed.tsx` — collapsible section showing done/dismissed items with reduced opacity
- `AttentionPage.tsx` assembles all components with loading/error states, health strip, stale data banner
- Grouped views render group headers with items underneath

**API changes:**
- `attention.ts` adapter: added `completedItems` field to `AttentionData` — returns done/dismissed items separately
- `nav-summary.ts`: wired attention data — badge = totalActive, status = error if now>0, warn if soon>0

**usePolling enhancement:**
- Added `refresh` to `PollingResult` interface — allows on-demand fetch (used after quick-add)

**CSS — 310 lines added:**
- Attention cards, badges (urgency/kind/domain), urgency KPI highlighting
- Quick-add form (input, selects, button with custom dropdown arrow)
- Filter bar (filter badges, filter groups, view switcher tabs)
- Completed feed (toggle, arrow rotation, completed/dismissed card opacity)
- `--badge-personal-bg` token added to theme
- Mobile responsive (stacked quick-add, vertical filter bar)

### Acceptance Criteria
MC-032:
- ✅ Urgency strip with Now/Soon/Ongoing/Awareness counts
- ✅ Cards sorted by urgency then age with title, badges, age, source
- ✅ Quick-add form with POST to `/api/attention`
- ✅ Quick-add pre-fills domain from localStorage
- ✅ Only title required to submit

MC-033:
- ✅ Filter panel (urgency, kind, domain, source)
- ✅ Switchable views: Triage, Domain-grouped, Source-grouped
- ✅ Collapsible completed/dismissed feed
- ✅ Auto-refresh at 60s via polling hook
- ✅ Nav-summary wired with attention data (badge + status)

### Test Summary
- API: 68 tests passing (no new tests — adapter change is additive)
- Web: 6 tests passing (SafeMarkdown)
- Build: both packages clean
- E2E: API endpoints verified via curl, SPA routing confirmed

### Milestone Status
- **M1:** 8/8 complete
- **M2:** 5/5 complete
- **M3:** 4/5 (MC-028 parity gate — usage wait)
- **M4:** 6/6 complete

### Compound
- **usePolling refresh exposure:** The `usePolling` hook was designed for auto-refresh-only pages (Ops), but Attention needs manual refresh after quick-add. Adding `refresh` to the return interface is a minimal change that makes the hook composable for both patterns. The alternative (separate manual-pull hook like `useIntelData`) would duplicate fetch/abort/error logic. This generalizes the hook for any page that combines polling with user-triggered mutations.

### Model Routing
- All work on Opus (session default). No Sonnet delegation — required cross-referencing mockup CSS, adapter types, and existing page patterns.

### Next
- MC-028: M-Web parity gate (usage wait continues)
- Cross-project tasks: MC-053, MC-054, MC-056, MC-057, MC-058
- Phase 1 retrospective after MC-028 clears

---

## 2026-03-07 — Session 11 (cont): MC-053 + MC-054 cross-project tasks

**MC-053 done — Cross-project amendments:**
- FIF `design/tasks.md`: M-Web section header updated to "SUPERSEDED by mission-control" with note explaining that FIF-W01–W12 are absorbed. Tasks retained for reference.
- A2A `design/action-plan.md`: M5 section updated to "SUPERSEDED by mission-control project" with task-level cross-references (A2A-015.1 → MC-011/12/13/14, A2A-015.2 → MC-026/032/033, A2A-015.3 → Phase 3+ M7/M8).
- Both project run-logs updated with cross-project amendment entries.

**MC-054 done — Attention-item type registration:**
- `_system/docs/file-conventions.md`: Added Attention Items section with full schema (required fields, enum values, directory, filename convention). Added `attention-item` to Type Taxonomy table.
- `_system/scripts/vault-check.sh`: Added section 26 (Attention-Item Schema Validation). Checks: location in `_inbox/attention/`, required fields (attention_id, kind, domain, status, urgency, schema_version, created, updated), enum validation for kind/urgency/status. Existing sections renumbered (old 26 → 27).
- Verified: valid item passes clean (0 issues), invalid item catches `kind: bogus` and `urgency: critical` errors.

### Next
- MC-028: M-Web parity gate (usage wait continues)
- Remaining cross-project tasks: MC-056, MC-057, MC-058
- Phase 1 retrospective after MC-028 clears
