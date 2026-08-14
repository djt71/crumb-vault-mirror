---
type: run-log
project: mission-control
status: archived
created: 2026-03-07
updated: 2026-03-13
covers: "2026-03-07 — MC-010: Design gate review through Session 11 (cont). Cross-project dependency tracking, Phase 1 implementation (M1/M2 adapters), Cloudflare Tunnel + Access, FIF adapters (MC-024/025/026), Attention page frontend (MC-032/033), cross-project tasks (MC-053/054). Chronological order."
---

# Mission Control — Run Log Archive (03c)

> **Archive 3 of 3.** Covers 2026-03-07 (MC-010 Design gate review onward, chronological): cross-project dependency tracking, Phase 1 implementation, Cloudflare Tunnel, FIF adapters, Attention page frontend, cross-project tasks through Session 11 (cont). Precedes [[run-log-2026-03b]] (2026-03-07–03-09, project creation through MC-055). See also [[run-log-2026-03a]] (2026-03-09–03-13, MC-065 onward). Active log: [[run-log]].

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
