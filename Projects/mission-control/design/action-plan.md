---
project: mission-control
type: action-plan
domain: software
status: active
skill_origin: action-architect
created: 2026-03-07
updated: 2026-03-30
tags:
  - dashboard
  - web
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Mission Control Dashboard — Action Plan

## PLAN-Phase Constraint Resolutions

These 9 items were flagged in the R2 review addendum for resolution during PLAN. Decisions recorded here; tasks reference them.

### PC-1. Aggregator Risk Mitigation
M4 builds the attention aggregator with a **single source** (dispatch pending files) and validates the aggregation pattern. M5 expands to full multi-source (system + relational + personal items) with progressive source addition — each source is a separate task. This isolates the riskiest integration point.

### PC-2. Nav Badge Refresh
`GET /api/nav-summary` endpoint created in M1. Returns per-page badge data: `{attention: {count, max_urgency}, ops: {status, error_count}, intel: {signals_today}, agents: {active_dispatches}, knowledge: {health_score}, customer: {stale_count}}`. Frontend polls every 60s, independent of per-page refresh. Badges appear on each nav rail icon.

### PC-3. Time Semantics
Convention: all backend stores and returns **UTC ISO-8601**. Frontend renders local time via `Intl.DateTimeFormat`. Canonical sort keys per page:
- **Attention:** urgency rank → created (oldest first within urgency)
- **Ops:** severity → last_event
- **Intelligence:** published → tier
- **Customer:** last_touch → engagement_status
- **Agent Activity:** last_event → status
- **Knowledge:** last_check → health_score

### PC-4. Health Header Auto-Refresh on Manual-Pull Pages
Manual-pull pages (Intelligence, Customer, Knowledge) include a health strip at top showing system status and data freshness. This strip auto-refreshes via the `/api/nav-summary` endpoint at 60s intervals. Full page content remains manual-pull. The health strip reuses the nav-summary data — no additional endpoint needed.

### PC-5. Analog Readout Budget
Maximum **4 custom SVG gauge components** across the entire dashboard. Phase 0 categorizes all readouts via the widget inventory (MC-006). Suggested candidates (not pre-committed — Phase 0 decides):
1. CPU load gauge (Ops)
2. Memory usage gauge (Ops)
3. Cost burn rate dial (Agent Activity)
4. Vault health score meter (Knowledge)

The widget inventory (MC-006) is the actual decision point — these candidates may change based on design exploration. All other metric displays use standard widgets: sparklines (inline SVG or Chart.js), progress bars (Tailwind), status indicators (colored dots/badges), and data tables. The Design Advisor overlay lens question "Does this readout earn custom treatment?" applies during Phase 0.

### PC-6. Widget Inventory
Phase 0 produces a **widget inventory table**: every widget instance across all 6 pages, listing widget type (gauge/sparkline/card/grid/timeline/table/badge/input), data source, and classification (custom SVG vs standard component). This inventory is a Phase 0 gate deliverable — the design gate cannot pass without it.

### PC-7. Testing Strategy
- **Adapter unit tests:** Required for every milestone. Each adapter gets isolated tests with fixture data. Highest testing value — these validate data contract correctness.
- **Aggregator integration tests:** M4 (single-source) and M5 (multi-source) get dedicated integration tests verifying dedup, sort order, and source merging.
- **React component tests:** Evaluate ceremony cost at Phase 1 retrospective. Defer unless trivially set up (e.g., Vitest + Testing Library already in stack).
- **E2E:** Single Playwright smoke test at M1 (nav loads, pages route, health endpoint responds). Phase 1 E2E test budget is one happy-path smoke test. Additional E2E tests require justification in the Phase 1 retro and must be added as explicit tasks. [AP-18]
- **Convention:** Tests at `packages/api/__tests__/` and `packages/web/__tests__/`.

### PC-8. Notifications (Future)
Browser notifications listed as future consideration for Phase 3+. Not tasked in this plan. The Attention page's triage model and Telegram alerts cover time-sensitive items for Phases 1-2. Evaluation point at Phase 2 completion: does the dashboard need to pull attention, or is passive display + Telegram sufficient?

### PC-9. SSE Resolution
**Decision: polling-first for all phases.** The spec's refresh intervals (30s Ops, 60s Attention/Agent) don't benefit from SSE's sub-second push latency vs its infrastructure complexity (connection management, reconnection, event types). Standard `setInterval` + `fetch` is simpler, debuggable, and sufficient.

**Upgrade path:** If Phase 1 retrospective reveals that polling creates visible lag (unlikely at 30s intervals) or excessive server load, add SSE for the Ops health status stream only. SSE infrastructure is additive — it doesn't require rearchitecting the polling approach.

---

## Cross-Cutting Conventions

These apply across all milestones:

- **Attention IDs:** `attention_id` uses UUID v4 (`crypto.randomUUID()` in Node, `uuidgen` in shell). Eliminates collision risk across independent writers (Tess, dashboard, manual, session-end hook). Human-readable context comes from filename and title, not the ID. [AP-1]
- **Write atomicity:** All vault writes use temp-file-then-atomic-rename (R2-4). Implemented as a shared `writeVaultFile()` utility in the API package during M1 (MC-018). Includes zombie `.tmp` cleanup — remove `.tmp` files older than 30 seconds before writing. [AP-8]
- **Markdown sanitization:** DOMPurify applied to all markdown rendered in the frontend (R2-5). Implemented as a shared `SafeMarkdown` component during M1 (MC-018).
- **Error handling:** Adapters return `{data, error, stale}` triples. Null data + error → error state. Data + stale=true → stale state. Frontend renders appropriate empty/error/stale treatment per PC-6/R2-9.
- **Stale detection thresholds:** Centralized named constants in `CONVENTIONS.md` / `timeSemantics.ts`: `STALE_SYSTEM_METRICS = 180s`, `STALE_ATTENTION_ITEM = 14d`, `STALE_DISPATCH = 1h`, `STALE_FIF_SIGNAL = 6h`, etc. All adapters and UI import from one source. [AP-5]
- **Adapter error roll-up for nav-summary:** `page_status = error` if any *required* adapter has error; `warning` if any is stale; `ok` otherwise. Adapters classified as required vs optional per page. A single required adapter failure marks the page as degraded. An optional adapter failure shows per-panel warning without affecting the page badge. [AP-6]
- **Privacy:** Customer-intelligence data endpoints protected by `verifyCfAccessHeaders()` Express middleware (MC-058, C7). Middleware validates CF Access JWT headers; reusable for any protected route. Auth is at the route/middleware layer, not in adapters. No customer data in nav-summary or any public-path response. [DR-A1]
- **Attention-item file lifecycle:** Only the monthly archival job (mechanic cron) moves attention-item files out of `_inbox/attention/`. The dashboard PATCH endpoint edits file content in place — it never moves, renames, or deletes files. [AP-7]
- **Shared tier configuration:** Tier boundaries (score thresholds and status colors) defined in a single shared config file (`tier-config.json` or equivalent constant), consumed by both the BFF (faceted count queries, filter grouping, color mapping via `/api/config` endpoint) and the FIF pipeline (triage routing). The raw reranker score is the authoritative field in FIF SQLite; tier is derived at query time, not stored. Changing a threshold retroactively reclassifies all items — no migration needed. Frontend fetches tier config at load time; never hardcodes boundaries. [AP-22, S-1]

---

## Milestone 0a: Aesthetic Exploration

**Phase:** 0 (Design — no code)
**Sessions:** 2-3
**Depends on:** Nothing (can start immediately)
**Overlays:** Design Advisor + companion (dataviz lens), Web Design Preference
**Success criteria:** Operator has seen 3 aesthetic directions for the same page and made a decision.

Explore dark, light, and hybrid aesthetic directions using a single HTML/CSS mockup of the Ops page (highest widget density) with CSS custom properties for colors. Dark/light/hybrid variants toggled by swapping ~12 CSS variable values — layout, typography, and widgets stay identical. Each variant uses real typography (ET Book / Source Serif), real color palettes, and representative data at expected density. Operator reviews and selects direction. [AP-9]

---

## Milestone 0b: Design System Deliverables

**Phase:** 0 (Design — no code)
**Sessions:** 2-5
**Depends on:** M0a (aesthetic direction decided)
**Overlays:** Design Advisor + companion, Web Design Preference
**Success criteria:** All 12 gate checklist items pass. Widget inventory complete. 6-vs-7 page decision made.

Produce the full design system in HTML/CSS: widget vocabulary (all archetypes), color system, typography scale, panel component, page mockups (Attention, Ops, Intelligence at real data density), nav shell, empty/error/stale state patterns. Mobile viewport tested for Attention + Ops. Widget inventory table completed. Analog readout candidates categorized.

**Gate checklist (12 items from §9.1):**
1. All widget archetypes represented in mockups
2. Typography matches taste profile
3. Color palette chosen
4. Attention, Ops, and Intelligence pages mocked at real data density [AP-11]
5. Attention page scannable in <10s
6. Ops page answers "house on fire?" in <5s
7. 4-6 sections / 3-7 widgets per section
8. Interactions use familiar patterns (Jakob's Law)
9. Refresh/staleness states designed
10. Mobile viewport tested (Attention + Ops)
11. Empty/stale/error states have visual treatments
12. Aesthetic direction documented

---

## Milestone 1: Project Scaffolding + Infrastructure

**Phase:** 1 (Foundation)
**Sessions:** 2-3
**Depends on:** M0b (design gate passed)
**Success criteria:** Monorepo builds. Express health endpoint responds. React app loads with nav shell. Dashboard accessible via Cloudflare Tunnel. launchd service running. System metrics scripts operational.

Stand up the monorepo, Express API, React shell with nav rail from Phase 0 mockup. Configure Cloudflare Tunnel + Access with reusable `verifyCfAccessHeaders()` middleware for C7 endpoints. Create launchd service. Deploy system-stats and service-status scripts. Build nav-summary endpoint and polling infrastructure. Production build + Express static serve configured for Cloudflare Tunnel access.

**External repo:** `~/openclaw/crumb-dashboard/` (repo_path to be set when scaffolding begins)

---

## Milestone 2: Ops Page

**Phase:** 1 (Foundation)
**Sessions:** 2-3
**Depends on:** M1 (scaffolding complete)
**Success criteria:** Ops page shows live system health, service status, 24h timeline, and cost data. Auto-refreshes every 30s. All adapters have unit tests. Operator can answer "is the house on fire?" from the dashboard.

Build all Ops page data adapters and frontend panels. This is the first full page — validates the adapter pattern, frontend architecture, and refresh mechanism.

---

## Milestone 3: Intelligence Pipeline Section

**Phase:** 1 (Foundation)
**Sessions:** 2-3
**Depends on:** M2 (Ops page proves adapter pattern)
**Success criteria:** Intelligence Pipeline section shows FIF signals, digest content, pipeline health. **M-Web parity gate:** Pipeline section matches M-Web core feature parity (digest display, signal rendering, pipeline health, source/tier/topic filtering). Pass criteria: operator uses Pipeline section for 3 consecutive days instead of Telegram for digests; page load + manual refresh under 400ms. If gate fails, M-Web reverts to standalone. (Note: feedback actions are Phase 4 scope — the parity gate evaluates read-only display capabilities only.) [AP-2]

Build FIF SQLite adapter, pipeline health adapter, and Intelligence page Pipeline section. This is the M-Web absorption milestone — the parity gate determines whether the merge succeeds.

---

## Milestone 4: Attention-lite Page

**Phase:** 1 (Foundation)
**Sessions:** 2-3
**Depends on:** M2 (adapter pattern proven). Note: M3 can run in parallel with M4 at operator's discretion.
**Risk flag:** Aggregator is the riskiest component (PC-1). Single-source first, then multi-source.
**Success criteria:** Attention page shows cross-source attention items with urgency counts, card layout, filters, switchable views. Quick-add creates new attention items. Aggregator correctly deduplicates and sorts.

Build the attention aggregator (single source → multi-source progression), quick-add write endpoint, and Attention page frontend. The aggregator's progressive build approach (PC-1) is critical — single-source validation before adding complexity.

---

## Phase 1 Retrospective

**Depends on:** M1-M4 deployed, 1-week usage period
**Success criteria:** Retrospective document written. Decisions recorded on: React component testing, SSE upgrade, Phase 2 scope, SC-1/SC-3/SC-5 evaluation.

Mandatory pause. Questions to answer: Is the dashboard being used daily? Which pages get attention? Is Attention-lite valuable enough to justify full attention-item infrastructure in Phase 2? Would iterating on Phase 1 pages be more valuable than adding new pages? Also: evaluate React component testing ceremony cost (PC-7) and SSE upgrade need (PC-9).

---

## Milestone 5: Full Attention Schema + Multi-Source Aggregator

**Phase:** 2 (Full Attention + Knowledge)
**Sessions:** 2-3
**Depends on:** Phase 1 retrospective complete
**Success criteria:** Aggregator handles all source types (system + relational + personal). All three item kinds display correctly. Schema validation enforces attention-item contract. Dedup + staleness indicators work.

Expand the attention aggregator from Attention-lite (system items only) to the full multi-source model. Add schema validation, expanded vault scanner, and support for all three item kinds.

---

## Milestone 6: Knowledge / Vault Page

**Phase:** 2 (Full Attention + Knowledge)
**Sessions:** 1-2
**Depends on:** M1 (scaffolding), can run in parallel with M5
**Success criteria:** Knowledge page shows vault health, AKM panel with hit rate and surfacing stats, project health indicators, search results. Search endpoint shared between nav search and Knowledge page.

Build Knowledge page adapters and frontend. Implement the shared search endpoint (QMD wrapper). Close the AKM feedback read-path gap (SC-4).

---

## Milestone 7: Attention Status Updates

**Phase:** 2 (Full Attention + Knowledge)
**Sessions:** 1
**Depends on:** M5 (full attention schema)
**Success criteria:** Operator can mark items done/deferred/dismissed from the dashboard. Status changes persist to vault files. Undo available for recent transitions.

Second write endpoint: PATCH /attention/:id. Inline status update UI on Attention page. Write atomicity per R2-4.

---

## Milestone 3.1: Intelligence Feed Density Redesign

**Phase:** 3 (Surface-inspired redesign of Pipeline section)
**Sessions:** 2-3
**Depends on:** M3 (Intelligence Pipeline section exists)
**Blocks:** M8 (Intelligence Production section builds on the redesigned layout)
**Inspiration:** Surface (quality-based content discovery dashboard) — screenshot analysis 2026-03-30
**Success criteria:** Intelligence Pipeline section uses dense list layout (~24 items/viewport vs ~5 with cards). Multi-axis filter bar with faceted counts. Raw reranker scores displayed and colored by shared tier config. Operator can scan 100+ feed items in <30 seconds without scrolling past the first two screenfuls.

Replace the card-based Signal Digest with a Surface-inspired dense list layout. Add multi-axis filtering with faceted counts. Surface raw reranker scores from FIF SQLite. Establish shared tier configuration as single source of truth for tier boundaries.

**M3.1 Phase 1 — Density + existing data (this milestone):**

| Task | Description | Type |
|------|-------------|------|
| MC-080 | Shared tier config — single TypeScript constant mapping FIF priority values (high/medium/low) to tier labels (T1/T2/T3) and status colors. Consumed by BFF endpoints and frontend. Add `/api/config` endpoint to serve config to frontend at load time. [AP-22] | Backend |
| MC-081 | BFF faceted counts endpoint — `GET /api/intel/facets` returns item counts grouped by tier, source, topic, format. Powers filter chip count badges. | Backend |
| MC-082 | Dense list layout — replace `.signal-card` grid with single-row `.signal-row` items. Tier badge (left margin, colored by tier status color), inline title + truncated thesis (~80 chars, dash-separated), source label + relative timestamp (right-aligned). Zero card chrome. Rows separated by `--border-subtle` divider. [S-3] | Frontend |
| MC-083 | Multi-axis filter bar — four stacked rows: Tier, Source, Topic, Format. Chip-style toggles with count badges. "ALL" clear-filter button. Filter state managed in URL params for shareability. | Frontend |
| MC-084 | Tier badge display — tier label (T1/T2/T3) rendered in left-margin badge, background colored by tier config status color. Future: swap to numeric score when FIF pipeline adds reranker scores [S-5]. | Frontend |
| MC-085 | Updated Intelligence mockup — HTML/CSS reflecting dense list layout, filter bar, score badges. Updates `design/mockups/intelligence-mockup.html` and `intelligence-mockup.css`. | Design |
| MC-086 | Design constraint — add "Dense list view: text-only source labels, no image elements in item rows" to design-system.md §3. | Design |

**M3.1 Phase 2 — New infrastructure (future milestone, not tasked):**
- Read/unread state: `seen_at` column in FIF SQLite, dashboard-owned writes only (primary surface model per U7/S-2). Bold/normal title weight for visual treatment.
- Time-bucketed counts: 1h/4h/1d/1w velocity display in KPI strip.
- Quick-filter presets: New (unseen), Starred (bookmarked). Depends on read state.
- View mode toggle: compact (title + score only) vs. standard (title + thesis + metadata).

**M3.1 Phase 3 — Expensive (future, not tasked):**
- AI-generated thesis summaries: LLM summarization pass at ingest or batch post-processing. Replaces truncated snippets with distilled one-liners. [S-4]

---

## Milestone 8: Intelligence Production Section

**Phase:** 3 (Agent Activity + Customer + Intel Production)
**Sessions:** 1-2
**Depends on:** M3.1 (Intelligence Pipeline section redesigned)
**Success criteria:** Production section shows research briefs, weekly intel, connections brainstorm. Both Pipeline and Production sections render on the merged Intelligence page.

Build inbox scanner adapter for research/brainstorm/intel files. Add Production section frontend to the existing Intelligence page.

---

## Milestone 9: Agent Activity Page

**Phase:** 3
**Sessions:** 2-3
**Depends on:** M1 (scaffolding)
**Success criteria:** Agent Activity page shows agent status cards, dispatch log with lifecycle, cost dashboard with per-model breakdown, context model. Dispatch log filterable by agent/status/project.

Build dispatch state adapter, ops metrics adapter (cost aggregation), tess-context adapter, and Agent Activity page frontend. Phase 3 implements dispatch-state, tess-context, and cost-aggregation adapters. Feedback ledger, dispatch learning log, and Tess memory files are future enrichments added when those data sources are consumed by other features. [AP-15]

### Deferred Enrichment: Skill & Overlay Utilization

Adds Skill Utilization, Overlay Utilization, and Agent Routing Distribution sections to the Agent Activity page. Depends on `_system/logs/skill-telemetry.jsonl` existing as a Crumb system convention (separate spec amendment — not mission-control scope).

**Skill Utilization section:**
- Table or card grid: skill name, invocation count (7d / 30d), last invoked, most common project context, trend sparkline
- Filterable by time window and project
- Highlights: skills not invoked in 30d (dead weight), skills with >5 invocations/day (workhorses)

**Overlay Utilization section:**
- Same shape: overlay name, load count (7d / 30d), last loaded, activation context (which skills triggered it)
- Key metric: "lens questions answered" count vs. "loaded but no lens output" — measures actual engagement vs. passive token cost
- Highlights: overlays loaded but never producing lens output (candidates for removal or revision)

**Agent Routing Distribution:**
- Model x skill heatmap: which skills drive which model tier
- Shows whether tiered routing (Haiku for lightweight, Opus for complex) is working as designed
- Extends the existing cost dashboard (already in M9 scope) with a per-skill cost dimension

**Agent Activity Patterns:**
- Per-agent timeline: when each agent (Tess Voice, Mechanic, Crumb) is active, what it's doing, and for how long
- Initiation chains: how often does Tess Voice dispatch to Crumb? How often does the operator initiate directly?
- Mechanic efficiency: is the hourly cron catching problems, or running 24 healthy checks in a row?
- Agent handoff frequency: dispatch volume from Tess to Crumb, with success/failure/cost per handoff
- Idle vs. active patterns: when are agents sitting unused? Are there coverage gaps?
- Data sources: `skill-telemetry.jsonl` **plus** existing M9 adapters (dispatch-state, tess-context, cost-aggregation)

**Data source:** `_system/logs/skill-telemetry.jsonl` — append-only JSONL, one line per event. Convention details (emission timing, Tess agent writes, session_id format) resolved in the Crumb spec amendment, not here.

**Task impact:** Adds 1-2 adapter tasks and 1 frontend task to M9. Not decomposed now — decompose when M9 enters active development.

**Primitive registry detection:** A vault-check rule cross-references `.claude/skills/` and `_system/docs/overlays/` against a registry list. New primitives without a registry entry produce a vault-check warning at commit time. The dashboard picks this up through the existing vault-check adapter (MC-020) — zero new infrastructure needed.

---

## Milestone 10: Customer / Career Page

**Phase:** 3
**Sessions:** 1-2
**Depends on:** M1 (scaffolding)
**Success criteria:** Customer page shows account dashboard with health indicators, dossier completeness, last touch. Privacy constraints enforced (C7). Blocked panels (relationship heat map, pre-brief) show placeholder treatment.

Build dossier scanner adapter (privacy-constrained), Customer/Career page frontend. Many panels blocked on upstream — show placeholder treatment per §6.0.

---

## Milestones 11-13: Feedback + Approval (Phase 4)

**Depends on:** A2A-003, TOP-049, A2A-015.3
**Not decomposed into tasks** — distant and dependency-gated. Scope:
- M11: Feedback endpoints (write to feedback-ledger.yaml via A2A correlation IDs)
- M12: Approval surface (render AID-* items, approve/deny via A2A canonical records, idempotency per R2-6)
- M13: Dashboard delivery adapter (Tess routes present/approve intents to dashboard)

---

## Milestones 14-16: Control Plane (Phase 5)

**Depends on:** A2A Phase 2-3 completion
**Not decomposed into tasks** — future scope. See spec §10.

---

## Milestone W1-W3: Customer Intelligence Workbench (Deferred)

**Depends on:** M1 (monorepo + API scaffold), MC-035 (Phase 1 retro evaluation)
**Not decomposed into tasks** — deferred until Phase 1 retro confirms the pattern.

Read-write working surface for SE account management, separate from Mission Control's observatory pages. Second site within the monorepo (`packages/workbench`), own tunnel subdomain, shared API layer and design system.

**Scope:**
- **W1:** Pre-meeting prep view — dossier + engagement history + FIF signals scoped to account + comms strategy + gap flags
- **W2:** Portfolio management — 25-account dashboard (staleness, engagement, completeness, last-touch), weekly review mode
- **W3:** Reactive search — cross-dossier + comms + FIF signal search scoped to customer context

**Per-account detail pages (master→detail navigation):**
- **Contacts/Personas** — LinkedIn-researched profiles per contact, linked to account. Role, influence, communication preferences, last interaction.
- **Active Opportunities** — pipeline view with status and next steps per opp. Vault-native (not Salesforce), manually maintained or Tess-assisted.
- **Comms & Product Strategies** — surface current strategy docs for the account. Playbook view: "here's the approach for this account right now."
- **Summary → Detail pattern** — main page shows portfolio summary (essentially the M10 Customer page scope), drill into per-account detail with all sections above. This master→detail navigation is the key architectural distinction from Mission Control's single-page observatory model.

Content production (comms drafting, pre-brief generation) deferred within the workbench — either bridge dispatch or context-only. Decide during workbench spec.

Audience: operator only. CF Access protected.

**Rationale for separate surface:** Mission Control is observatory-mode (read-only, attention-signal-generating). Customer work requires read-write interaction with dossiers, comms strategies, and pre-briefs. Mixing these violates the observatory design philosophy validated through spec peer review.

**Sequencing note:** Do not spec before Phase 1 retro. The workbench depends on infrastructure built in M1-M4 (Express API, adapter pattern, vault read layer, search endpoint). MC-011 monorepo setup should not pre-build for this but should avoid choices that prevent adding a third package later.

---

## Dependency Graph

```
M0a ──► M0b ──► M1 ──┬──► M2 ──► M3
                      │         ╲
                      │          ╲ (parallel optional)
                      └──► M4 ───────► Retro ──┬──► M5 ──► M7
                                               │
                                               ├──► M6
                                               │
                                               └──► M3.1 ──► M8    (Phase 3)
                                                    M9, M10         (Phase 3, independent)
```

**Default build order:** M2 (Ops) → M3 (Intelligence Pipeline) → M4 (Attention-lite). First user-visible MVP is the Ops page. First product-complete Phase 1 outcome is all three pages together. M3 and M4 are parallelizable at operator discretion. [AP-10]

**Phase 3 build order:** M3.1 (Intel Feed Density) → M8 (Intel Production). M9 and M10 are independent of M3.1 and of each other. M3.1 blocks M8 because both modify the Intelligence page — the density redesign establishes the layout that the Production section builds on.

**Critical path:** M0a → M0b → M1 → M2 → M3 (M-Web parity gate) → M4 → Retrospective → M5 → M7

**Parallelizable:** M3 and M4 can run in parallel. M5 and M6 can run in parallel. M3.1 and M9/M10 can run in parallel. M8 waits for M3.1.
