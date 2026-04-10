---
project: mission-control
type: specification
domain: software
skill_origin: external-session
status: reviewed
review_round: 2
review_date: 2026-03-07
created: 2026-03-07
updated: 2026-03-30
tags:
  - dashboard
  - web
  - tess
  - openclaw
  - architecture
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Mission Control Dashboard — Specification

**Class:** system
**Workflow:** four-phase (SPECIFY → PLAN → TASK → IMPLEMENT)
**Review status:** Peer reviewed by 4 models in round 1 (20 amendments applied). Round 2 deep research review by ChatGPT GPT-5.2 and Perplexity (12 additional amendments). Gemini round 2 discarded (hallucinated architecture). Synthesis at `reviews/2026-03-07-peer-review-synthesis.md`, addendum at `reviews/2026-03-07-round2-addendum.md`.
**Amendment S (2026-03-30):** Intelligence Feed Density Redesign — Surface-inspired dense list layout, multi-axis filter bar, raw score display, shared tier config, primary-surface read-state model. Adds M3.1 milestone scope. References: [S-1] tier config, [S-2] read state, [S-3] dense list, [S-4] AI summaries (deferred).

## 1. Problem Statement

Danny operates a multi-agent personal OS (Crumb + Tess + Claude.ai) spanning eight life domains, ~25 customer accounts, multiple software projects, and an always-on intelligence pipeline. Operational visibility is fragmented across: Telegram messages (Tess briefings, alerts, dispatches), terminal sessions (Claude Code), Healthchecks.io (uptime pings), vault files (run-logs, project states), and manual memory. There is no single surface where Danny can answer "what needs me?" without checking multiple systems.

The consequences are concrete:

- Attention items leak. Overlay-informed commitments (Life Coach goals, Career Coach actions, Business Advisor recommendations) evaporate into session log prose with no tracking.
- Operational awareness requires active checking. Is the FIF pipeline healthy? Is Tess in Limited Mode? Did last night's research dispatch complete? These questions require opening terminals, grepping logs, or waiting for Telegram alerts.
- Intelligence outputs are consumed in low-fidelity channels. Weekly competitive briefs, connections brainstorms, and research results arrive as Telegram messages — truncated, non-interactive, hard to review in batch.
- Feedback loops are incomplete. AKM logs surfacing events but nothing consumes them. Feed-intel triage decisions are logged but trend analysis requires manual JSONL parsing. Dispatch learning is recorded but not visualized.
- Cross-domain awareness doesn't exist. No surface spans Tess operations, feed intelligence, customer engagement, personal goals, and vault health simultaneously.

The mission control dashboard is a multi-page web UI providing unified operational visibility, attention management, intelligence consumption, and — progressively — feedback, approval, and control capabilities across the entire Crumb ecosystem.

## 2. Facts

- F1. **Tess-operations is in TASK phase** (M0+M1 deployed, 16/54 tasks done). Chief-of-staff MVP operational: heartbeat, morning briefing, vault health, pipeline monitoring. Feed-intel ownership transition pending M1 gate.
- F2. **Feed-intel-framework is in production soak** (2026-03-05 through 2026-03-09). All 3 FIF services live. M-Web (web presentation layer) is specced as 12 tasks (FIF-W01–W12) with Express + React + Vite + Tailwind stack.
- F3. **A2A is in IMPLEMENT phase with M1/M2 deployed live** (as of 2026-03-07). Delivery abstraction (A2A-001), feedback infrastructure (A2A-003), and compound insight orchestration are operational — not theoretical. A2A-015.1/015.2/015.3 (mission control scaffolding + read UI + feedback adapter), A2A-019 (approval + status), A2A-024 (full control) are sketched Phase 2-3 tasks superseded by this project. Channel-agnostic delivery layer uses `deliver(intent, content, artifact_path?)` interface.
- F4. **Delivery abstraction already supports multiple channels.** Five intents defined: notify, present, approve, feedback, converse. Telegram is the first adapter. The dashboard would be the second.
- F5. **Web design preference overlay defines Observatory mode** for dashboards: full-width widget grid, serif headers, analog-feeling readouts, functional status color, sparklines, one accent color. The "warm light background" preference applies to reading-centric content (blogs, articles, long-form digests), not necessarily dashboards. Dark mode is the established convention for operational dashboards (status color distinction, reduced eye strain during extended use). The aesthetic direction (dark/light/hybrid) is an open design exploration for Phase 0. [R2-1]
- F6. **Design taste profile prescribes a visual design phase** before implementation: "Sketch the dashboard widget vocabulary... and sketch how each would look in the 'analog observatory' style" (step 5 of Concrete Next Steps).
- F7. **FIF M-Web is specced as a standalone app.** This spec proposes absorbing it — the Intelligence page's Pipeline section replaces M-Web, eliminating a separate codebase. The M-Web design sprint (FIF-W01) becomes the dashboard design sprint.
- F8. **QMD provides hybrid search** (BM25 + semantic) across 4 vault collections (~730 docs, ~4,950 chunks). Runs locally on Metal. No external API calls.
- F9. **AKM feedback log** (`akm-feedback.jsonl`) records every surfacing event but has no consumer (audit finding F3). The dashboard can close this loop.
- F10. **Healthchecks.io monitors Mac Studio health** via 15-minute dead man's switch pings. API is publicly queryable for check status.
- F11. **FIF SQLite state DB** contains all signal data, triage results, source metadata, and cost telemetry.
- F12. **Dispatch state files** in `_openclaw/state/dispatch/` record full lifecycle for every bridge dispatch including timing, tokens, cost, and outcome.
- F13. **Ops metrics harness** (TOP-050) provides append-only structured run logs with job_id, start/end times, status, token usage, tool calls, exit codes, alerts, and cost estimates.
- F14. **Approval Contract schema** (TOP-049, chief-of-staff §9b) defines AID-* objects with approval_id, action_type, service, target, summary, original_context, risk_level, preview, expires_at. Telegram is currently the single approval surface.
- F15. **No structured personal task/goal tracking exists in the vault.** Overlay outputs (Life Coach, Career Coach, Business Advisor, Financial Advisor) produce prose insights during sessions, not discrete trackable items.
- F16. **Cloudflare Tunnel + Access** is the recommended hosting pattern for authenticated web services on the Mac Studio (referenced in A2A spec, FIF M-Web spec, and tess-operations).
- F17. **The customer-intelligence project** is active (ACT phase) with account dossiers, comms strategies, and value cards in progress. Project directory is excluded from the vault mirror (contains customer data).
- F18. **Tess's persistent context model** (`_openclaw/state/tess-context.md`) tracks active projects, priorities, and state with tiered staleness (soft >24h, hard >72h).
- F19. **Observatory mode interaction principles are defined.** 4-6 panel groupings per page, 3-7 widgets per section (Hick's Law). Default views immediately legible without configuration (Tesler's Law). Widget refresh invisible, <400ms for user actions (Doherty Threshold).

## 3. Assumptions

- A1. **React + Vite + Tailwind is the right frontend stack.** Server-rendered HTML (Express/EJS) or HTMX would reduce initial complexity but hit a ceiling at the interaction patterns this dashboard requires: live-updating status indicators, drill-down card expansion, filtered/sorted attention item lists, tabbed page sections, and progressive write capabilities (feedback buttons, approval actions, quick-add forms). These are component-state problems that React handles natively. The alternative — bolting client-side JS onto server-rendered pages piecemeal — creates the same complexity with worse tooling. React also provides the most transferable frontend skill for the operator's ongoing software engineering education. The complexity cost is real but justified by the interaction model. (Validate: prototype confirms the stack handles Observatory mode typography and layout requirements.) [A14]
- A2. **A thin Express API layer (BFF) is the right data aggregation pattern.** Reads from existing data sources (SQLite, filesystem, Healthchecks.io API, QMD), serves normalized JSON to the frontend. Gives Tess and future agents a programmatic interface to the same data. (Validate: API complexity stays manageable with ≤20 endpoints at launch.)
- A3. **M-Web absorption is net-positive.** Eliminating a separate codebase outweighs the scope increase to this project. The Intelligence page's Pipeline section inherits M-Web's design and the shared service layer (FIF-W11) becomes an API adapter. **Kill-switch:** If the merged dashboard cannot deliver the Pipeline section to M-Web's core feature parity (digest display, signal rendering, pipeline health, feedback actions) by end of Phase 1 M3, M-Web reverts to standalone development. The dashboard retains Ops and Attention pages; feed intelligence is built separately and linked from the nav. [A11]
- A4. **Observatory mode will pass visual validation.** The warm-light, serif-header, analog-readout aesthetic is untested at dashboard density. The design phase exists to validate or reject this. (Validate: visual design phase produces mockups that pass the design gate checklist §9.1 before any React code is written.)
- A5. **The `attention-item` note type is the right persistence model for personal tracking.** Vault-native markdown notes with frontmatter, readable by Obsidian, scannable by the API layer. (Validate: the schema handles all three item kinds — system, relational, personal — without becoming unwieldy.)
- A6. **Six pages is the right granularity.** Intelligence and Feed Intelligence are merged into a single Intelligence page with Pipeline and Production sections. Pages may further merge or split during the design phase. (Validate: visual mockups confirm each page has enough content to justify existence and not so much that it's overwhelming. Design phase must mock the merged Intelligence layout and evaluate density. Decision checkpoint at end of Phase 0: commit to 6 pages or split back to 7.) [A5]
- A7. **HTML/CSS is the primary design approach for Phase 0.** Static HTML pages with real typography (ET Book / Source Serif), real color palettes, and representative data test the aesthetic at true browser rendering fidelity. These artifacts are directly reusable in Phase 1 implementation. Figma or equivalent available as optional complement for exploratory layout iteration, not required. [R2-2]
- A8. **The dashboard launches as a read-dominant surface.** Phases 1-3 are read-dominant. The only write operations are: attention-item creation via quick-add (Phase 1), and attention-item status updates (Phase 2). All other write capabilities (feedback, approval, dispatch initiation) are Phase 4+ and must be thin facades over A2A-defined operations (§8.5). This distinction affects security posture — write endpoints require input validation and vault-write safety checks that read endpoints do not. [A7]

## 4. Unknowns

- U1. **Observatory mode viability at dashboard density.** Will warm backgrounds, serif typography, and analog-style widgets work at the information density a 6-page operational dashboard requires? The design phase resolves this. May result in aesthetic pivots.
- ~~U2. **Design tool selection.**~~ Resolved: HTML/CSS mockups are the primary design approach for Phase 0. Produces artifacts directly reusable in Phase 1. Figma remains available for optional exploratory layout iteration, not required. [R2-2]
- U3. **Accent color.** The taste profile suggests deep teal, burgundy, or rich amber. Selection requires seeing candidates against real panel layouts.
- U4. **Aesthetic mode selection.** The taste profile defines Library (warm/light, reading-centric) and Observatory (dashboard/metrics) as separate modes. The design phase must explore whether the dashboard uses dark mode for operational pages (Ops, Agent Activity, Finance), light mode for reading-heavy content (Intelligence Production, digest detail views), a hybrid approach (dark chrome + light content panels), or a unified aesthetic. This is the primary aesthetic question for Phase 0. [R2-1]
- U5. **WebSocket vs polling for live data.** Ops page health indicators and dispatch lifecycle want near-real-time updates. SSE (server-sent events) is simpler than WebSocket. Polling is simplest but introduces latency. Resolve during PLAN based on data freshness requirements per page.
- U6. **Attention item capture UX.** How do overlay-informed action items get created? Session-end hook (automated), manual quick-add on dashboard, Tess-generated from awareness checks, or all three? The interaction model needs design. Session-end hook is deferred to Phase 5 but the mechanism should be sketched in PLAN.
- ~~U7. **Feed intelligence read-state scope.**~~ Resolved (2026-03-30): **Primary surface model.** Dashboard owns read state via `seen_at` column in FIF SQLite. Telegram, morning briefings, and other surfaces present items but do not write read state. Items surfaced in notification channels still appear as "new" on the dashboard. Rationale: dashboard is the triage surface (inbox-zero model); notification channels are push/surfacing channels, not queue-clearing channels. Avoids multi-surface sync complexity while preserving the daily scan workflow. [S-2]

## 5. System Map

### 5.1 Context

```
┌─────────────────────────────────────────────────────────────┐
│                      Danny (Operator)                       │
│                                                             │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐              │
│   │ Telegram  │   │Dashboard │   │Claude.ai │              │
│   │ (mobile)  │   │ (web)    │   │(sessions)│              │
│   └────┬─────┘   └────┬─────┘   └────┬─────┘              │
│        │              │              │                      │
└────────┼──────────────┼──────────────┼──────────────────────┘
         │              │              │
    ┌────▼─────┐   ┌────▼─────┐       │
    │   Tess   │   │  Express │       │ (vault commits)
    │(OpenClaw)│◄──│  API/BFF │       │
    └────┬─────┘   └────┬─────┘       │
         │              │              │
    ┌────▼──────────────▼──────────────▼──┐
    │            Data Sources              │
    │                                      │
    │  ┌────────┐  ┌──────┐  ┌─────────┐  │
    │  │FIF     │  │Vault │  │Health-  │  │
    │  │SQLite  │  │Files │  │checks.io│  │
    │  └────────┘  └──────┘  └─────────┘  │
    │  ┌────────┐  ┌──────┐  ┌─────────┐  │
    │  │Dispatch│  │Ops   │  │  QMD    │  │
    │  │State   │  │Metrics│  │(search) │  │
    │  └────────┘  └──────┘  └─────────┘  │
    │  ┌────────┐  ┌──────┐               │
    │  │AKM     │  │Tess  │               │
    │  │Feedback│  │Memory│               │
    │  └────────┘  └──────┘               │
    └──────────────────────────────────────┘
```

### 5.2 Relationship to Existing Projects

| Project | Relationship | Nature |
|---------|-------------|--------|
| feed-intel-framework | Absorbs M-Web (FIF-W01–W12) | Intelligence page Pipeline section replaces standalone M-Web app |
| agent-to-agent-communication | Implements A2A-015.1/015.2/015.3, A2A-019, A2A-024 | Dashboard is the mission control surface designed in the A2A spec |
| tess-operations | Consumes operational data; becomes Tess delivery channel | Ops, Intelligence, Agent Activity pages read tess-ops outputs |
| active-knowledge-memory | Consumes feedback log; provides search backend | Knowledge page shows AKM health; QMD powers dashboard search |
| customer-intelligence | Consumes account dossiers and intelligence outputs | Customer/Career page surfaces account data |
| crumb-tess-bridge | Reads dispatch state files | Agent Activity page shows dispatch lifecycle |

### 5.3 Dependencies

**Upstream (this project requires):**
- FIF production soak complete (data source stability)
- Cloudflare Tunnel + Access operational on Mac Studio (hosting)
- Visual design phase completion (design gate before implementation)

**Parallel (can proceed alongside):**
- A2A Phase 1 (delivery abstraction, feedback infra)
- tess-operations M2+ (Google/Apple integration enriches dashboard data)
- TOP-049 (Approval Contract — enables approval surface on Attention page)

**Downstream (consumes this project's output):**
- A2A Phase 2 delivery adapter (web UI adapter wraps dashboard API)
- Tess delivery routing (present/approve intents route to dashboard)

### 5.4 Constraints

- C1. **Solo operator.** Single user. No multi-user auth complexity. Cloudflare Access handles authentication.
- C2. **Single machine.** Mac Studio hosts everything — API, frontend, and all data sources are local.
- C3. **Visual design gate.** No React code before the design phase produces mockups passing the gate checklist (§9.1). Observatory mode is a hypothesis to be validated, not a commitment.
- C4. **Read-dominant, minimal writes for operator-owned primitives.** Phases 1-3 are read-dominant. The only write operations are: attention-item creation via quick-add (Phase 1), and attention-item status updates (Phase 2). All other write capabilities (feedback, approval, dispatch initiation) are Phase 4+ and must be thin facades over A2A-defined operations (§8.5). This distinction affects security posture — write endpoints require input validation and vault-write safety checks that read endpoints do not. [A7]
- C5. **File-based data sources.** Most data lives in files (markdown, JSONL, SQLite) on the local filesystem. The API layer reads from these directly — no intermediate database.
- C6. **Ceremony Budget Principle.** Infrastructure overhead must earn its place. No Redis, no Postgres, no Docker, no message queues. Express + SQLite reads + filesystem access.
- C7. **Customer-intelligence data never exposed publicly.** No public route ever exposes customer-intelligence data. API endpoints serving customer data must verify Cloudflare Access headers. This is a hard constraint, not a default. [A9]

## 6. Page Architecture

Six pages, each a focused operational surface. The Attention page is the landing page. [A5]

### 6.0 Panel Data Availability [A10]

Each panel described in §6.1-6.6 falls into one of three categories:

- **Available now** — data source exists today and can be read by an API adapter
- **Derivable now** — data exists but requires light parsing, aggregation, or computation by the adapter
- **Blocked on upstream** — data source does not yet exist; depends on another project's completion

Panels in the 'blocked' category are placeholders in the UI showing 'Coming soon — requires [dependency]'. They do not masquerade as functional panels.

The PLAN phase will produce a per-panel availability matrix. The design phase must mock panels using real data density for 'available' and 'derivable' panels, and show the placeholder treatment for 'blocked' panels.

### 6.1 Attention / Inbox (Landing Page)

**Purpose:** "What needs Danny?" Cross-domain command queue.

**Item taxonomy:**
- **System items** (`kind: system`) — dispatch approvals, alerts needing human decision, gate evaluations due, pipeline issues. Programmatic sources, well-defined actions.
- **Relational items** (`kind: relational`) — customer comms needing response, follow-through commitments (post-meeting actions), relationship cadence alerts, networking follow-ups. Time-sensitive, action is "go do a human thing."
- **Personal/growth items** (`kind: personal`) — Life Coach commitments, Career Coach positioning actions, Business Advisor lifecycle actions, Financial Advisor deadlines, reflection prompts. Lower urgency, higher importance (Eisenhower quadrant II).

**Data sources:** Bridge dispatch files (pending approvals), vault attention-item notes, FIF signals flagged for review, vault-check warnings, stale relationship alerts (future: Google/Apple integration), overlay-generated items (future: session-end hook).

**Layout:**
- Top strip: counts by urgency (Now / Soon / Ongoing / Awareness)
- Main area: grouped cards sorted by urgency then age. Each card shows title, source domain tag, age, urgency, and action buttons appropriate to item type.
- Filters: by domain, urgency, action type, source, kind. Default: all open, urgency-sorted.
- Quick-add input: create an attention item manually with domain/urgency tags.
- Completed/dismissed feed: collapsible section at bottom for throughput awareness and undo.

**Switchable views:**
- Triage (default): urgency-first sort
- Domain: grouped by life domain
- Source: grouped by origin (system / overlay / manual)

### 6.2 Ops / Infrastructure

**Purpose:** "Is the house on fire?" System health and operational efficiency.

**Data sources:** `/tmp/tess-health-check.state` (health check state), `_system/logs/health-check.log` (health check log), Healthchecks.io API, `_system/logs/system-stats.json` (periodic system metrics dump), `_system/logs/service-status.json` (periodic launchd status dump), vault-check output, ops metrics harness (TOP-050). [A12, R2-3]

**Layout:**
- KPI strip: Tess status (Normal/Limited), OpenClaw gateway (up/down + uptime), FIF services (3× green/amber/red), Healthchecks.io aggregate, Mac Studio resources (CPU/RAM/disk)
- Service grid: one card per launchd service with status dot, last run, last result. Click to expand log entries.
- 24-hour timeline: service events — heartbeats, alerts, mode transitions, maintenance windows. Color-coded dots.
- Operational efficiency panel: signal-to-noise per cron job, cost per human action, false positive rate (from self-optimization loop — blocked on upstream).
- Cost burn: daily/weekly spend vs ceiling, per-job breakdown.
- LLM Status: one card per provider/model (Anthropic Opus, Anthropic Sonnet, Anthropic Haiku, Mistral, local qwen3-coder). Each card shows: success rate (rolling 1h), p95 latency, call count today, degradation timestamp when applicable. Data source: ops metrics harness (TOP-050 structured run logs) + dispatch telemetry, aggregated by model/provider. Green/amber/red derived from empirical health, not provider status pages. Gray/stale state for models with no recent calls. Section order: above Cost Burn (operational priority over informational cost context). Future enrichment: show provider status page state alongside empirical health. [AP-19]
- Operational tempo indicator: current Tess mode (active/quiet/pre-meeting) with reasoning (blocked on upstream: tempo adaptation).
- Degradation indicators: API latency trends, model quality scores, data freshness (blocked on upstream: degradation-aware routing).

**New data source scripts** (created as part of Phase 1 M2): [A12]
- `_system/scripts/system-stats.sh` — runs via launchd every 60 seconds, dumps CPU load, memory usage, and disk utilization to `_system/logs/system-stats.json`. The API reads this file — it never shells out to system utilities per request.
- `_system/scripts/service-status.sh` — runs on the same schedule, queries `launchctl list` for the defined service set and writes structured JSON to `_system/logs/service-status.json`.

### 6.3 Intelligence (merged) [A5]

**Purpose:** Content intelligence consumption, pipeline health, and Tess's analytical production. Absorbs M-Web.

Two sections within one page:

**Pipeline section** (former Feed Intelligence):

**Data sources:** FIF SQLite state DB, `signals.jsonl` (assumed — validate exists and is stable before building adapter; if absent, derive time-series from FIF SQLite state DB). [R2-3]

**Tier configuration:** Tier mapping is defined in a single shared config (`tier-config.ts` or equivalent), consumed by both the BFF (for filter grouping, color mapping, and faceted count queries) and the frontend (via `/api/config` endpoint). The FIF pipeline's categorical `triage_json.priority` field (high/medium/low) is the tier source; the config maps these to display labels and status colors. Config shape: `{ "T1": { "priorities": ["high"], "status_color": "ok" }, "T2": { "priorities": ["medium"], "status_color": "warn" }, "T3": { "priorities": ["low"], "status_color": "tertiary" } }`. [S-1]

**Future: numeric scoring.** The FIF pipeline currently produces categorical priority/confidence (high/medium/low), not numeric relevance scores. When a numeric reranker score is added to the FIF pipeline, the tier config will evolve to score-range-based derivation (e.g., `{ "T1": { "min_score": 90, ... } }`), the score will replace the tier badge as the left-margin display element, and tier boundaries will drive retroactive reclassification. Until then, tier badges (T1/T2/T3) serve as the left-margin scanline element. [S-1, S-5]

**Read state — primary surface model:** The dashboard is the authoritative triage surface for feed intelligence read state. A `seen_at` timestamp column in FIF SQLite records when an item was marked as read. Only explicit dashboard interaction (clicking an item or batch-mark actions) writes `seen_at`. Other surfaces (Telegram via Tess, morning briefings, research dispatches) present items but do not mark them read. This ensures items surfaced in notification channels still appear as "new" on the dashboard for triage. Visual treatment: unread items use bold title weight; read items use normal weight — zero additional UI elements. Schema change deferred to M3.1 Phase 2 (read/unread infrastructure); design decision locked now to prevent accidental schema divergence. [S-2]

**Layout:**
- KPI strip: signals today/this week (sparkline), per-source breakdown (X/RSS/YouTube), triage distribution (T1/T2/T3 with counts), cost today vs ceiling, YouTube API quota. Time-bucketed counts (1h/4h/1d/1w) showing feed velocity — deferred to M3.1 Phase 2.
- Multi-axis filter bar: four stacked rows of chip-style toggles, each showing item count per value. Rows: **Tier** (All, T1, T2, T3), **Source** (All, X, RSS, HN, Reddit, arXiv, YouTube), **Topic** (All + derived topic tags from FIF SQLite), **Format** (All, Article, Paper, Thread, Video, Discussion). An "ALL" button clears all filters. Filter by tier label, display raw numeric score, color by tier boundary from shared config. Faceted counts powered by a BFF endpoint querying FIF SQLite with tier derived at query time. [S-1]
- Dense signal list (primary content area): flat list layout — one row per item, no card chrome (no borders, border-radius, box-shadow, or padding containers). Each row: **tier badge** (left margin, T1/T2/T3 label, background colored by tier status color from shared config; future: numeric score badge when FIF pipeline adds reranker scores [S-5]) | **title + thesis** (inline on one line — bold title followed by lighter ~80-char truncated description, separated by a dash) | **source label + relative timestamp** (right-aligned). Text-only source labels (e.g., "X", "RSS", "HN") — no favicons, avatars, thumbnails, or source logos. Images break the scanline rhythm and fight the tier-badge pattern. Rows separated by subtle bottom divider (`--border-subtle`). Target density: ~24 items per viewport at standard screen height. Click row to expand inline detail panel. [S-3]
- Signal detail panel: expanded view of selected signal (inline expansion, not separate panel). For researched items, shows enriched context. "Investigate" button stages research dispatch.
- Triage actions: each signal row supports skip (immediate — removes from view), delete (immediate — removes inbox file), and promote (queued — flags for next feed-pipeline skill run). Actions accessible via row hover/focus controls. See §8.7.
- Quick-filter presets: **New** (unseen items — requires read state, deferred to M3.1 Phase 2), **Starred** (operator-bookmarked items — requires star/bookmark state, deferred). These are intent-based workflow shortcuts, not raw filter values.
- View mode toggle: compact (title + score only) vs. standard (title + thesis + metadata). Deferred to M3.1 Phase 2.
- Rendering strategy: render all rows in the DOM (no virtual scroll, no pagination). At current volume (~107 items), lightweight rows are negligible for DOM performance. Revisit if filtered views regularly exceed 300 items.
- Pipeline health: circuit breaker status, last capture/attention/feedback run times, error rates, stale backlog count.
- Tuning panel: weekly feedback analysis — topic weight trends, promotion/ignore rates, Tess's tuning recommendations (blocked on upstream: feed-intel feedback analysis).

**Deferred — AI-generated thesis summaries (M3.1 Phase 3):** The inline description text is currently a truncated snippet from the source. A future enhancement adds a summarization pass at ingest or batch post-processing to generate distilled one-liner thesis statements (e.g., "Open-source signing unlocks Apple releases off-macOS" instead of truncated excerpt). High value but high compute cost — requires either per-item LLM call at ingest or batch processing. Not in M3.1 Phase 1 scope. [S-4]

**Production section** (former Intelligence page):

**Data sources:** `_openclaw/inbox/` (research briefs, intelligence briefs, brainstorm files, feed-intel tuning recommendations), vault knowledge notes produced by research dispatches.

**Layout:**
- Overnight research briefs: queue of pending items, completed briefs awaiting review, promote/dismiss rate over time.
- Weekly Intelligence Brief: latest competitive + account intelligence. Historical briefs browsable. Trend indicators on competitor activity.
- Connections Brainstorm: weekly cross-domain pattern detection output. Featured card when new.
- Builder Ecosystem Radar: weekly builder community scan, filtered for relevance.
- KB Gardening findings: cross-reference suggestions, tag gap analysis, source currency alerts.

### 6.4 Customer / Career

**Purpose:** Account operational surface and professional development tracking.

**Data sources:** Customer-intelligence dossiers, A2A Workflow 3 outputs (pre-call briefs), relationship cadence data (blocked on upstream: Google/Apple integration), career-coach and business-advisor attention items.

**Privacy constraints:** [A9]
- The dashboard reads customer-intelligence data only when running on the Mac Studio behind Cloudflare Access with authenticated session.
- No public route ever exposes customer-intelligence data. This is a hard constraint (C7).
- API endpoints serving customer data must verify Cloudflare Access headers before responding.
- PII fields (personal contact details, private communications) are omitted from the web UI unless explicitly surfaced per-field. Default display: account name, engagement status, last touch date, dossier completeness score, and comms cadence — but not raw dossier content.

**Layout:**
- Account dashboard: accounts with health indicators (dossier completeness, last touch, engagement status).
- Relationship heat map: contacts with last-touch dates, cadence targets, stale-relationship flags. Color: green (within cadence) / amber (approaching) / red (overdue). (Blocked on upstream: Google/Apple integration.)
- Pre-brief panel: upcoming meetings with prep status (not started / in progress / ready / partial). Adversarial pre-briefs rendered with facts/hypotheses/responses structure. (Blocked on upstream: A2A Workflow 3.)
- Career positioning tracker: active career-coach action items, skill development milestones, stakeholder relationship status.
- Comms cadence: communication patterns and follow-through status.

### 6.5 Agent Activity

**Purpose:** Agent operational status, dispatch lifecycle, and cost tracking.

**Data sources:** Dispatch state files, ops metrics harness, feedback ledger, dispatch learning log, tess-context.md, Tess memory files.

**Layout:**
- Agent status cards: Tess Voice (model, status, last interaction, session count), Tess Mechanic (model, status, last heartbeat, cron schedule), Crumb (last session time, active project).
- Dispatch log: recent dispatches with lifecycle status (queued → running → stage-complete → blocked → complete). Filterable by agent, status, project. Shows correlation ID, duration, token usage, cost.
- Cost dashboard: token usage over time by model (Haiku voice, qwen3-coder mechanic, Sonnet dispatches, Opus code review). Daily/weekly/monthly. Budget vs actual per line item from chief-of-staff §11.
- Context model: current state of tess-context.md, staleness indicator, what Tess thinks the priorities are.
- Session cards: Anticipatory Session prep files and post-session debrief summaries (blocked on upstream: TOP-047). Session velocity trends over time.

### 6.6 Knowledge / Vault

**Purpose:** Vault health, knowledge retrieval effectiveness, and project velocity.

**Data sources:** vault-check.sh output, QMD collection stats, akm-feedback.jsonl, project-state.yaml files, MOC files, batch-book-pipeline telemetry.

**Layout:**
- Vault health KPIs: total notes, MOC coverage, vault-check pass/fail, last check time.
- AKM panel: QMD collection stats (doc count, chunk count, last index update), surfacing hit rate (rolling 10 sessions), items surfaced today, trigger performance (latency by type, SLO compliance), feedback analysis (most-surfaced sources, never-surfaced sources — dead knowledge candidates). At least one actionable path: a "review stale sources" link that creates an attention item prompting the operator to evaluate low-performing sources during their next Crumb session. [A18]
- Project health: active projects with velocity indicators (last commit, last run-log entry, days since next_action changed). Stall detection flags.
- Vault structure: tag distribution (which kb/ tags growing/stagnant), MOC sizes, Sources/ growth.
- Vault Gardening: proactive quality management panels — dead knowledge (QMD sources never surfaced across N sessions, with titles and "archive" action links), orphan detection (notes with no inbound wikilinks, no MOC reference, no tags), stale source candidates (time-sensitive content not referenced in 6+ months), tag hygiene (tags on only 1-2 notes, tags with no MOC parent, distribution skew), QMD collection health (growth rates, chunk density, parsing anomalies). Each finding produces either an attention item or a direct action link — generalizes the "review stale sources" pattern. Dead knowledge and orphan detection are Phase 2 scope; stale source and tag hygiene are derivable from existing data; semantic duplicate detection is Phase 3+ batch enrichment. [AP-20]
- Batch-book-pipeline: processing progress, success rates by template type, queue depth.
- Decision journal: browsable decisions filterable by project/domain, "what would change your mind" conditions with status (blocked on upstream: decision journal implementation).

### 6.7 Future Pages [R2-11]

Six pages in Phases 1-3. Two additional pages planned for future phases, potentially reaching 8. The nav rail and design system must accommodate future page growth.

**Personal Finance page** (future — Phase 3+):
- Portfolio overview (401k, brokerage positions, performance)
- Property value tracking (Zillow/Redfin estimates, neighborhood trends)
- Finance news / market signals (potentially a new FIF adapter source)
- Budget/cash flow indicators
- Financial attention items (tax deadlines, rebalancing triggers, insurance)
- Maps to Financial Advisor overlay outputs
- **Architectural note:** This page requires external API data sources (broker APIs, property value APIs, finance RSS) that don't exist in the vault today. This is a different class of adapter than local file reads. The FIF adapter pattern can potentially handle finance news feeds.

**Home Dashboard page** (future — Phase 3+):
- Home maintenance schedule (HVAC, seasonal tasks, recurring items)
- Car maintenance (oil changes, tire rotation, inspection, mileage)
- Active home projects (renovation, contractor follow-ups, purchases)
- Chore cadence tracking
- Household inventory / warranty tracking
- Depends on Apple Reminders integration (tess-ops) for structured task data
- Starts as attention items via manual quick-add, evolves into dedicated schema if patterns emerge (compound engineering principle)

These pages strengthen the case for content-aware aesthetic treatment (R2-1): a finance page with portfolio charts is pure dashboard territory (dark-friendly), while reading finance news articles is Library mode (light-friendly).

### 6.8 Search [A19]

Global search lives in the nav shell header. It queries QMD across all four collections and surfaces results in a unified dropdown/overlay with collection badges, relevance scores, and snippets. The Knowledge page's AKM panel provides the same results with additional filtering (collection-specific views, date range, tag filters). Both share the same API endpoint (`GET /api/search?q=...`) and the same result card component. There is one search implementation, not two.

## 7. New Vault Primitive: attention-item

A new note type enabling structured cross-domain task and goal tracking.

### 7.1 Schema [A2]

```yaml
---
type: attention-item
attention_id: <uuid-v4>              # UUID v4 — collision-safe across independent writers [AP-1]
kind: [system | relational | personal]
domain: [career | financial | health | creative | spiritual | relationships | software | learning]
source_overlay: [life-coach | career-coach | business-advisor | financial-advisor | null]
source_system: [dispatch | fif | ops | vault-check | approval | awareness-check | null]
source_ref: [correlation_id | dispatch_id | signal_id | null]
created_by: [crumb-session | dashboard | tess | manual]
status: [open | in-progress | done | deferred | dismissed]
urgency: [now | soon | ongoing | awareness]
action_type: [approve | review | respond | reflect | track | null]
related_entity: [account_id | project_name | null]
created: YYYY-MM-DD
due: YYYY-MM-DD              # optional
deferred_until: YYYY-MM-DD   # optional, for deferred items [R2-7]
schema_version: 1            # [R2-10]
updated: YYYY-MM-DD
tags:
  - attention
  - [domain tag]
---

# [Title]

[Description — what needs to happen and why]

Context: [[source-session-log-or-note]]
```

**File naming:** `attention-<attention_id>.md`

**File location:**
- System items (Tess-generated): `_inbox/attention/`
- Personal/relational items (session-end hook, manual): `_inbox/attention/`
- All attention items use a single directory for aggregator simplicity. Inbox-processor routes resolved items to `Archived/attention/YYYY-MM/` after cleanup.

**Dedup rules:** Same `source_ref` within 24 hours → update existing item instead of creating new. The aggregator deduplicates by `attention_id` (unique) and by `source_ref` (prevents the same event from creating multiple items).

**Mutation precedence:** Source of truth is the file on disk. Last writer wins. Dashboard and Obsidian edits are equivalent — both modify the file directly. The API reads current state on each request.

**Write atomicity:** [R2-4] All vault writes use the temp-file-then-atomic-rename pattern (write to `<filename>.tmp`, then `rename()` to final path). This prevents partial writes from being visible to Obsidian's file watcher or other readers. PLAN must document how Obsidian's file-watching behavior interacts with atomic renames on macOS (APFS).

### 7.2 Capture Ownership Model [A3]

| Item kind | Writer | Trigger |
|-----------|--------|---------|
| System (dispatch) | Tess | Dispatch enters `blocked` state or completes with review-needed flag |
| System (pipeline) | Tess | FIF health check detects anomaly requiring human judgment |
| System (ops) | Tess | Awareness-check or heartbeat finds condition requiring human decision |
| System (approval) | Tess | AID-* approval request created (future: TOP-049) |
| Relational (comms) | Tess / A2A workflow | Follow-through engine detects commitment; cadence tracker detects staleness |
| Personal (overlay) | Crumb session-end hook | Overlay was active and operator confirms action items (Phase 5) |
| Personal (manual) | Dashboard / Obsidian | Operator creates directly |

Single writer per item kind eliminates double-capture risk. The `/attention` aggregator reads from all locations but never writes — it is read-only.

- **Session-end hook:** Deferred to Phase 5. When a Crumb session ends and an overlay was active, prompt: "Any action items from this session?" Creates attention-item notes from confirmed items. Mechanism to be designed in PLAN.
- **Dashboard quick-add:** Web form on the Attention page — title, domain, urgency, kind, optional due date. Writes an attention-item note to `_inbox/attention/`. Available in Phase 1.
- **Tess-generated:** When Tess's awareness check, morning briefing, or intelligence layer identifies something needing human judgment, it writes an attention-item note to `_inbox/attention/`.
- **Manual:** Create attention-item notes directly in Obsidian, as with any vault note.

### 7.3 Lifecycle

Items transition: open → in-progress → done/deferred/dismissed. The dashboard is the primary interaction surface for these transitions, but the notes are vault-native — they can also be edited in Obsidian or processed by the inbox-processor.

Attention items are not project tasks. Project tasks live in project task lists and follow the four-phase workflow. Attention items track cross-domain commitments, personal goals, and operational items that don't belong to any single project.

**Archival policy:** [A17] Attention items in `done` or `dismissed` status for >30 days are moved to `Archived/attention/YYYY-MM/` by a periodic cleanup job (monthly, mechanic cron). Items in `deferred` status are not auto-archived — they remain active until explicitly resolved. The cleanup job logs what it archives. Archived items are not indexed by the attention aggregator.

**Staleness nudge:** [R2-7] Open items untouched (no `updated` change) for >14 days trigger a Tess nudge via the awareness-check mechanism. The nudge creates no new items — it surfaces the stale item in the next morning briefing with a prompt: "This attention item has been open 14+ days. Still relevant?" Operator can then act, defer with a new `deferred_until` date, or dismiss. Deferred items resurface when `deferred_until` arrives.

**Schema evolution:** [R2-10] The API adapter handles backward compatibility by defaulting missing fields for older schema versions. Tess's mechanic can include a schema-version check in the monthly archival job, flagging items with outdated versions.

**Persistence decision:** [R2-8] Vault-native markdown is the source of truth (preserves Obsidian editability, compound engineering principle, existing vault patterns). The API layer may maintain a lightweight SQLite index that rebuilds from vault scans if the performance budget (§8.3) is exceeded. The index is a cache, not a second source of truth. Until performance measurement indicates otherwise, direct filesystem reads are sufficient.

## 8. Technical Architecture

### 8.1 Stack

```
Frontend:  React + Vite + Tailwind CSS
Backend:   Express.js (BFF — backend for frontend)
Data:      Direct reads from existing sources (SQLite, filesystem, APIs)
Search:    QMD (local hybrid BM25 + semantic)
Hosting:   Mac Studio, Cloudflare Tunnel + Access
Auth:      Cloudflare Access (SSO/email-based, single user)
Monitor:   /api/health endpoint + launchd service + Tess mechanic check
```

[A14] **Why React over simpler alternatives.** Server-rendered HTML (Express/EJS) or HTMX would reduce initial complexity but hit a ceiling at the interaction patterns this dashboard requires: live-updating status indicators, drill-down card expansion, filtered/sorted attention item lists, tabbed page sections, and progressive write capabilities (feedback buttons, approval actions, quick-add forms). These are component-state problems that React handles natively. The alternative — bolting client-side JS onto server-rendered pages piecemeal — creates the same complexity with worse tooling. React also provides the most transferable frontend skill for the operator's ongoing software engineering education. The complexity cost is real but justified by the interaction model.

### 8.2 Repository Structure

```
crumb-dashboard/
├── packages/
│   ├── api/                    Express BFF
│   │   ├── routes/             /attention, /ops, /intel, /customer, /agents, /vault, /search
│   │   ├── adapters/           data source connectors
│   │   │   ├── fif-sqlite.js   FIF state DB reader
│   │   │   ├── vault-fs.js     vault filesystem scanner
│   │   │   ├── healthchecks.js Healthchecks.io API client
│   │   │   ├── dispatch.js     bridge dispatch state reader
│   │   │   ├── ops-metrics.js  structured run log parser
│   │   │   ├── system-stats.js system metrics JSON reader
│   │   │   ├── akm.js          feedback JSONL parser + QMD wrapper
│   │   │   ├── attention.js    attention-item note aggregator
│   │   │   └── search.js       QMD query wrapper
│   │   ├── health.js           /api/health endpoint
│   │   └── server.js
│   └── web/                    React + Vite + Tailwind
│       ├── src/
│       │   ├── pages/          one per dashboard page
│       │   ├── components/     shared widget library
│       │   ├── layouts/        shell, nav rail
│       │   └── hooks/          data fetching, refresh
│       └── vite.config.js
├── package.json                monorepo root (workspace)
└── README.md
```

### 8.3 API Design Principles

- **Read-dominant at launch.** Most endpoints are GET. Phase 1 write endpoints are `POST /attention` (quick-add) and feed triage actions (skip, delete, promote-queue — §8.7). Phase 2 adds attention-item status updates. All other writes are Phase 4+ (§8.6). [A7]
- **Source-of-truth persistence.** The filesystem and SQLite databases are the only persistent stores. The API maintains no separate database. However, in-process memoization with short TTLs (5-10 seconds, aligned to refresh intervals) is permitted to avoid redundant filesystem reads within a single refresh cycle. This is in-memory cache that dies with the process — not a persistent shadow store. [A13]
- **Performance budget.** Direct filesystem reads are the default. If measured latency for any page exceeds 400ms (Doherty Threshold) at normal data volumes, introduce a lightweight derived index for the offending adapter. The threshold is measured, not assumed — don't pre-optimize. Log adapter response times during Phase 1 to establish baselines. [A16]
- **Rendering safety.** [R2-5] All markdown content rendered in the frontend must be sanitized (e.g., DOMPurify) to strip unexpected HTML, scripts, and event handlers. File path access is constrained to vault directories — the API never serves arbitrary filesystem paths. Agent-produced content is treated as untrusted input for rendering purposes.
- **Adapter pattern.** Each data source has an isolated adapter module. Adapters handle parsing, normalization, and error handling. Routes compose adapters.
- **Attention aggregator.** The `/attention` endpoint queries all adapters that produce attention items, normalizes them into a common schema, merges, deduplicates by `attention_id` and `source_ref`, and sorts by urgency then age.

### 8.4 Dashboard Self-Monitoring [A4]

The dashboard is a monitored service:

- **Health endpoint:** `GET /api/health` returns JSON with API uptime, last successful data source read per adapter, and error count. Tess's mechanic adds this to the hourly pipeline monitoring check (extends TOP-011).
- **Process management:** Express server runs as a launchd service (`com.crumb.dashboard`) with auto-restart on crash. Service definition created during Phase 1 M1 (scaffolding).
- **Error logging:** API errors logged to `_system/logs/dashboard-api.log`. Rotation follows existing log conventions.
- **Alert on failure:** If the health endpoint is unreachable for 2 consecutive mechanic checks, Tess alerts via Telegram.

### 8.5 Data Refresh Strategy

Per-page refresh approach (not global polling):

| Page | Refresh | Rationale |
|------|---------|-----------|
| Attention | 60s auto + manual | Primary triage surface; moderate freshness needed |
| Ops | 30s auto + manual | Health monitoring; stale data misleads |
| Intelligence | Manual (pull) | Digests and briefs consumed at operator pace |
| Customer | Manual (pull) | Account data changes slowly |
| Agent Activity | 60s auto + manual | Dispatch lifecycle benefits from near-real-time during active work |
| Knowledge | Manual (pull) | Vault metrics change on session boundaries, not continuously |

Auto-refresh pauses when the browser tab is not visible (prevents unnecessary load).

### 8.6 Feed Triage Actions (Phase 1)

Feed signals on the Intelligence page's Pipeline section support three triage actions: **skip**, **delete**, and **promote**. These are operator-initiated decisions that replace the LLM permanence evaluation performed by the feed-pipeline Crumb skill.

**Schema ownership:** A `dashboard_actions` table in the FIF SQLite database provides the queue. This table is owned by the dashboard — FIF core tables (`posts`, `adapter_runs`, `cost_log`) remain read-only from the dashboard's perspective.

```sql
CREATE TABLE dashboard_actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  canonical_id TEXT NOT NULL UNIQUE,  -- one action per item
  action TEXT NOT NULL CHECK(action IN ('promote', 'skip', 'delete')),
  metadata TEXT,               -- optional JSON (e.g., {"kb_tag": "kb/software-dev"})
  created_at TEXT NOT NULL,    -- ISO 8601
  consumed_at TEXT             -- set by feed-pipeline skill after processing
);
```

**Action semantics:**

| Action | Immediate? | What happens |
|--------|-----------|--------------|
| Skip | Yes | Row written to `dashboard_actions`. Item hidden from triage view. Inbox file (if present) left for TTL expiry. |
| Delete | Yes | Row written to `dashboard_actions`. Inbox file deletion is best-effort — the row is authoritative, orphaned files are caught by TTL cron. Item hidden from triage view. |
| Promote | Queued | Row written to `dashboard_actions` with `action='promote'`. Feed-pipeline skill picks up on next run: skips permanence evaluation (Q1-Q3 — human already decided), runs full promotion workflow (source_id generation, frontmatter construction, signal-note write, MOC registration, knowledge retrieval, project cross-posting, calibration logging). Sets `consumed_at` after successful processing. |

**One action per item:** `UNIQUE(canonical_id)` enforces that each signal can have at most one triage action. Attempting a different action on an already-actioned item returns 409 Conflict. The operator must undo the existing action first (`DELETE /api/intel/:id/undo/:action`). This prevents contradictory state (e.g., skip + promote on the same item).

**Undo:** All three actions support undo (removes the `dashboard_actions` row if `consumed_at IS NULL`). For promote, undo is available until the feed-pipeline skill processes the item and sets `consumed_at`.

**Data flow:**

```
FIF pipeline  →  SQLite posts table (FIF-owned, read-only from dashboard)
Dashboard     →  SQLite dashboard_actions table (dashboard-owned, read by feed-pipeline skill)
Feed-pipeline →  reads dashboard_actions JOIN posts → full promotion workflow → sets consumed_at
```

**Design rationale:**
- Separate table (Option B) chosen over new `queue_status` value (Option A) to maintain clean schema ownership boundary. FIF owns `posts`; dashboard owns `dashboard_actions`. If FIF refactors, the JOIN contract on `canonical_id` is the only coupling surface.
- Feed-pipeline skill remains single owner of promotion logic — no duplication in Express endpoints, no drift risk.
- Consistent with C4 (read-dominant Phases 1-3): the dashboard's Intel writes are status flags, not vault file operations.
- Batch processing aligns with existing feed-pipeline workflow.

**Frontend requirements:** Signal list rows show skip/delete/promote action controls on hover/focus. For promote, the operator can optionally override the kb/ tag (pre-populated from FIF triage tags mapped through canonical lookup). A "promote queue" indicator shows count of pending promotions. Consumed promotions show "promoted" status with link to the resulting signal-note (once the skill has processed them). [S-3]

**Endpoints:**
- `POST /api/intel/:canonical_id/skip` — writes skip action, returns updated item state
- `DELETE /api/intel/:canonical_id` — writes delete action, removes inbox file if present, returns confirmation
- `POST /api/intel/:canonical_id/promote` — accepts optional `{kb_tag?}`, writes promote action, returns queued confirmation

### 8.7 Future: Dashboard as Delivery Adapter [A8]

When A2A Phase 2 lands, the dashboard becomes a delivery channel. All write endpoints in Phase 4+ must be thin facades over A2A-defined operations, not independent logic:

- `POST /feedback` — writes through to the existing feedback-ledger.yaml using A2A correlation IDs
- `POST /approval/:id/approve` and `/deny` — translates to an A2A approve call on the canonical AID record
- `POST /dispatch` — creates a bridge inbox file conforming to the dispatch protocol schema (Phase 5)

The dashboard never maintains independent state for approvals, feedback, or dispatches. It reads from and writes to the same canonical sources that Tess uses. This prevents duplicate state machines and ensures all actions flow through A2A's learning and audit layers.

The delivery adapter integration follows the A2A-001 pattern: Tess routes `present` intent items to both Telegram and a dashboard delivery queue. The dashboard polls the queue (or subscribes via SSE).

**Idempotency:** [R2-6] The canonical approval state lives in the AID-* record file. Both Telegram and dashboard read from and write to this record. The dashboard must check current status before executing an action — if already approved/denied/expired, the dashboard shows the resolved state and does not re-execute. PLAN must define idempotency keys and replay safety rules for the approval surface, even though Phase 4 is distant — the contract must be compatible across both surfaces.

## 9. Design System

### 9.1 Design Phase (Gate Before Implementation)

**Deliverables:**
1. **Widget vocabulary** — visual definition of each widget archetype: status indicator, sparkline metric, timeline, gauge/meter, attention item card (one per kind: system, relational, personal), approval card, signal card, agent status card, search result card. Rendered in the Observatory aesthetic.
2. **Color system** — background tones (warm off-white/cream), status palette (functional green/amber/red), accent color (selected from deep teal / burgundy / rich amber candidates), text colors.
3. **Typography scale** — serif for headers and body (ET Book or Source Serif Pro), monospace for data values (JetBrains Mono or IBM Plex Mono), small sans-serif for functional chrome (nav labels, metadata tags).
4. **Panel component** — the containing element for widgets. Subtle borders, padding, warm background, card-style containment.
5. **Page mockups** — at least two pages (Attention + Ops recommended) fully mocked at real data density. Merged Intelligence page mocked with both Pipeline and Production sections.
6. **Nav shell** — left rail with page icons, badge counts, status dots. Header with page title, refresh timestamp, global search bar.
7. **Empty / error / stale state patterns** [R2-9] — visual treatment for four states: empty (first use or no data), stale (data older than expected refresh interval), error (adapter failure or unreachable source), partial (some adapters responding, others not). Each state needs a distinct, recognizable visual treatment.

**Tool:** HTML/CSS is the primary approach. Static HTML pages with real typography, real color palettes, and representative data. Artifacts are directly reusable in Phase 1. Figma available as optional complement. [R2-2]

**Gate checklist** (all must pass): [A6]
1. All widget archetypes from above are represented in mockups
2. Typography matches taste profile (serif body, monospace data, sans-serif chrome)
3. Color palette is chosen (background, status colors, accent)
4. At least two pages fully mocked at real data density (not placeholder text)
5. Attention page can be scanned and "what needs me?" answered in <10 seconds
6. Ops page can answer "is the house on fire?" in <5 seconds
7. Pages respect 4-6 sections / 3-7 widgets per section guidance
8. Interactions are conventional (Jakob's Law) — navigation, filtering, drill-down use familiar patterns
9. Refresh/staleness states are designed (not deferred)
10. Mobile viewport tested for Attention and Ops — critical info readable without horizontal scroll
11. Empty, stale, and error states have defined visual treatments [R2-9]
12. Aesthetic direction decided and documented (dark / light / hybrid / toggle) [R2-1]

**Decision checkpoint:** By end of Phase 0, commit to 6 pages or split Intelligence back to 7 based on mock evaluation. [A5]

### 9.2 Observatory Mode Principles (from taste profile)

- Background aesthetic is an open exploration: warm light (cream/parchment) for reading-centric content, dark mode for operational dashboards, or hybrid — resolved in Phase 0 [R2-1]
- Full screen width — no narrow centered columns
- Serif panel headers; small sans-serif for metadata chrome
- Analog-feeling readouts where data warrants (gauges, meters, dials) — but not as skeuomorphic decoration
- Sparklines, trend indicators, small multiples
- Functional color for status: green/amber/red (or warm equivalents)
- One strong accent color for interactive elements
- High data-ink ratio (Tufte): no decorative gridlines, no 3D effects, no gradient fills
- Direct labeling over legends (Cleveland-McGill)
- Information density welcome if well-structured
- Minimum text size: 13px (0.8125rem) universal floor across all contexts, viewports, and components. Dark backgrounds require slightly larger text for equivalent readability. Data-tier text (service values, LLM stats, monospace readouts) at 14px (0.875rem) minimum. Two-tier minimum: 13px chrome, 14px data. [AP-21]

### 9.3 Interaction Principles (from taste profile)

- 4-6 panel groupings per page, 3-7 widgets per section (Hick's Law)
- Widget controls sized generously; read-only indicators smaller (Fitts's Law)
- Default views immediately legible without configuration (Tesler's Law)
- Widget refresh invisible; data staleness indicator over loading spinners; <400ms user-initiated actions (Doherty Threshold)
- Novel aesthetics + familiar interactions = delight; novel aesthetics + novel interactions = confusion (Jakob's Law)

## 10. Build Order

### Phase 0: Design (no code)

Visual design phase. Produce the design system deliverables (§9.1) via HTML/CSS mockups. Explore aesthetic direction (dark/light/hybrid). Validate Observatory mode. Gate checklist must pass. Two sub-milestones: (0a) aesthetic exploration, (0b) formal deliverables. [R2-1, R2-2, R2-12]

**Depends on:** nothing (can start immediately)
**Produces:** approved design system, widget vocabulary, page mockups, 6-vs-7 page decision, aesthetic direction decision (dark/light/hybrid)

### Phase 1: Foundation + Attention-lite + Ops + Intelligence Pipeline (read-dominant) [A1]

Stand up the monorepo, Express API, React shell with nav. Build the three highest-value surfaces.

- M1: Project scaffolding, Cloudflare Tunnel + Access, nav shell, launchd service definition, `/api/health` endpoint, system-stats and service-status scripts [A4, A12]
- M2: Ops page (Healthchecks.io adapter, vault-check adapter, system-stats reader, service-status reader, health-check log parser, ops metrics adapter)
- M3: Intelligence page — Pipeline section (FIF SQLite adapter, signal rendering, digest view, pipeline health). M-Web parity gate: if Pipeline section doesn't reach M-Web core feature parity by end of M3, M-Web reverts to standalone. [A11]
- M4: Attention-lite page (attention aggregator reading from: pending dispatch files, FIF health flags, vault-check warnings, Healthchecks.io stale pings; plus quick-add write endpoint for manual items) [A1]

**Depends on:** Phase 0 (design gate), FIF production soak complete
**Produces:** deployed dashboard with three functional pages + quick-add

### Phase 1 Retrospective (mandatory) [A20]

After Phase 1 deployment, pause for a 1-week usage period and retrospective before committing to Phase 2 scope. Questions to answer: Is the dashboard being used daily? Which pages get the most attention? Is the Attention-lite page providing enough value to justify full attention-item infrastructure in Phase 2? Would stopping here and iterating on Phase 1 pages be more valuable than adding new pages?

### Phase 2: Full Attention + Knowledge (read-dominant, plus attention-item writes)

Expand the Attention page with the full attention-item primitive and build the Knowledge/Vault page.

- M5: Full attention-item schema, expanded vault scanner (system + relational + personal items), Attention page with all views and filters
- M6: Knowledge page (QMD adapter, AKM feedback parser, vault-check integration, project health scanner)
- M7: Attention-item status updates (second write endpoint)

**Depends on:** Phase 1 deployed + retrospective
**Produces:** Attention as full landing page, Knowledge health visibility, attention-item lifecycle management

### Phase 3: Agent Activity + Customer/Career + Intelligence Production (read-only)

Build the remaining pages from Tess operational data.

- M8: Intelligence page — Production section (inbox scanner for research/brainstorm/intel files)
- M9: Agent Activity page (dispatch state adapter, cost aggregation, session cards)
- M10: Customer/Career page (dossier scanner, privacy-constrained display, relationship data when Google integration lands)

**Depends on:** Phase 2 deployed; Production section benefits from tess-ops M8 (intelligence layer)
**Produces:** complete 6-page dashboard (read-dominant)

### Phase 4: Feedback + Approval (A2A facade writes)

Dashboard becomes an interactive surface. All writes are thin facades over A2A-defined operations. [A8]

- M11: Feedback endpoints (write to feedback-ledger.yaml via A2A correlation IDs)
- M12: Approval surface (render AID-* items, approve/deny via A2A canonical AID records; depends on TOP-049)
- M13: Dashboard delivery adapter (Tess routes present/approve intents to dashboard)

**Depends on:** A2A-003 (feedback infra), TOP-049 (Approval Contract), A2A-015.3 (delivery adapter)
**Produces:** dashboard as active feedback and approval channel

### Phase 5: Control Plane (future)

Dashboard as dispatch initiation and workflow configuration surface. Maps to A2A-024.

- M14: Dispatch initiation (select workflow, fill parameters, submit via bridge inbox)
- M15: Workflow configuration and monitoring
- M16: Session-end attention-item capture hook

**Depends on:** A2A Phase 2-3 completion
**Produces:** full mission control — read, review, decide, act

## 11. Relationship to M-Web

FIF M-Web (FIF-W01–W12) is absorbed into this project:

| M-Web Task | Dashboard Equivalent |
|------------|---------------------|
| FIF-W01 (paper design sprint) | Phase 0 design phase (expanded to full dashboard) |
| FIF-W02–W04 (Express API, auth, data layer) | Phase 1 M1 + FIF SQLite adapter |
| FIF-W05–W08 (digest UI, signal rendering) | Phase 1 M3 (Intelligence page — Pipeline section) |
| FIF-W09–W10 (loading/error states, theming) | Theming infrastructure deferred to Phase 0 aesthetic decision [R2-1] |
| FIF-W11 (shared service layer) | API adapter pattern (shared between web API and Telegram listener) |
| FIF-W12 (test suite) | Per-phase test coverage |

The Intelligence page's Pipeline section delivers everything M-Web promised, plus integration with the broader dashboard ecosystem (nav, search, attention item routing, feedback).

**Kill-switch:** [A11] If the Pipeline section cannot reach M-Web core feature parity by end of Phase 1 M3, M-Web reverts to standalone development.

## 12. Cost and Resource Estimate

### Infrastructure Cost

| Component | Monthly Cost |
|-----------|-------------|
| Cloudflare Tunnel + Access | $0 (free tier) |
| Healthchecks.io API calls | $0 (existing free tier) |
| QMD queries | $0 (local, Metal GPU) |
| Hosting | $0 (Mac Studio, already running) |

### Development Effort

| Phase | Estimated Sessions | Notes |
|-------|-------------------|-------|
| Phase 0 (Design) | 4-8 | Sub-milestones: (0a) aesthetic exploration — 2-3 competing directions (dark, light, hybrid) for the same page; (0b) formal deliverables — widget vocabulary, color system, typography, panel components, page mockups per gate checklist. HTML/CSS primary approach eliminates design tool learning curve but aesthetic exploration scope increased. [R2-1, R2-2, R2-12] |
| Phase 1 (Foundation + Attention-lite + Ops + Intel Pipeline) | 8-12 | Heaviest phase — scaffolding + 3 pages + quick-add |
| Phase 2 (Full Attention + Knowledge) | 4-6 | Attention aggregator is the complex piece |
| Phase 3 (Agent + Customer + Intel Production) | 4-6 | Mostly applying established patterns |
| Phase 4 (Feedback + Approval) | 3-5 | Depends on A2A/tess-ops progress |
| Phase 5 (Control Plane) | 3-5 | Future — scope depends on A2A Phase 3 |

Total estimated: 22-36 Crumb sessions for Phases 0-3 (functional read-dominant dashboard). Phases 4-5 are A2A-gated and estimated separately.

## 13. Exclusions

- **Real-time streaming telemetry.** This is not a spacecraft. Polling/SSE at 30-60s intervals is sufficient for operational awareness.
- **Multi-user access control.** Single operator. Cloudflare Access handles auth. No RBAC, no user management.
- **Mobile-native app.** Responsive web only. No React Native, no Electron. **Desktop is the primary target for Phases 0-3.** Mobile must be usable for triage on Attention and Ops — no horizontal scrolling, critical KPIs readable, action buttons tappable. Other pages degrade gracefully (single-column stack, reduced widget density). Feature parity on mobile is not a goal. Telegram remains the mobile-optimized interaction surface for urgent items. [A15]
- **Automated action execution.** The dashboard surfaces information and accepts decisions. It does not autonomously execute actions (that's Tess's domain via the bridge).
- **Calendar/email integration UI.** The dashboard shows data derived from Google/Apple integration (via Tess), but does not directly connect to Google or Apple APIs. Tess owns those integrations.
- **Obsidian plugin.** The dashboard is a web app, not an Obsidian plugin. It reads vault files but does not embed in Obsidian.
- **Public-facing pages.** This is a private operational tool. No public routes, no SEO, no marketing. No public route ever exposes customer-intelligence data. [A9]
- **Predetermined aesthetic commitment.** Aesthetic direction (dark, light, hybrid, or toggle) is resolved in Phase 0. The design phase explores all approaches. No commitment to either direction pre-Phase 0. [R2-1]

## 14. Open Questions

1. ~~**Design tool choice.**~~ Resolved: HTML/CSS mockups are the primary approach. Figma available as optional complement. [R2-2]
2. **Accent color selection.** Deep teal, burgundy, or rich amber — requires visual mockups against real panel layouts.
3. **Attention-item capture: session-end hook design.** How does the hook detect that an overlay was active and action items were identified? Does it prompt always, or only when specific conditions are met? Needs design sketch in PLAN; implementation is Phase 5.
4. **Tess context refresh from dashboard.** Should the dashboard be able to trigger a Tess context refresh (tess-context.md)? This is a write operation that may be premature for early phases.
5. **A2A delivery adapter protocol.** The exact mechanism for Tess to route delivery intent items to the dashboard (SSE subscription? file-based queue? API push?) needs alignment with A2A implementation decisions. Recommendation: file-based queue (`_openclaw/state/delivery/`) with well-defined JSON schema, consistent with existing patterns.
6. **AKM session-end read-file diff.** The dashboard consumes akm-feedback.jsonl for visualization. Should it also implement the session-end read-file diff that was designed but never built (AKM audit F3)? Or is that a separate AKM maintenance task?
7. ~~**Vault-native vs API-native attention items.**~~ Resolved: vault-native markdown is the source of truth. API layer may maintain lightweight SQLite index as cache if performance budget exceeded. See §7.3. [R2-8]

## 15. Success Criteria

- **SC-1.** The operator opens the dashboard instead of checking Telegram for morning orientation within 2 weeks of Phase 1 deployment.
- **SC-2.** Attention page surfaces items that would otherwise have been missed (at least 1 item per week that wasn't caught via existing channels).
- **SC-3.** Intelligence page Pipeline section is preferred over Telegram for digest consumption within 1 week of Phase 1 deployment.
- **SC-4.** AKM feedback data is visible on the Knowledge page — closing the write-only gap (audit finding F3). At minimum: hit rate over rolling 10 sessions, most-surfaced sources, never-surfaced sources. At least one actionable path exists from insights to operator action (e.g., "review stale sources" creates an attention item). [A18]
- **SC-5.** No operational blind spots: any system state previously requiring terminal/log access is visible on the dashboard.
- **SC-6.** Observatory mode aesthetic passes the design gate checklist — or an alternative aesthetic is selected that the operator prefers.
- **SC-7.** Dashboard adds no new unmonitored components. The dashboard itself is a monitored service — Tess alerts if the API health endpoint is unreachable. If the dashboard goes down, Tess's existing Telegram channels continue to function (graceful degradation). [A4]

## 16. Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|------------|
| Observatory mode fails visual validation | Delays implementation while aesthetic pivots | Medium | Design phase + gate checklist catch this. Budget 2-4 iterations. If Observatory fails, fall back to Library-lite dashboard aesthetic. |
| Scope creep from 6-page ambition | Phases 2-3 drag out; never reaches completion | Medium | Phase 1 delivers standalone value (Attention-lite + Ops + Intel Pipeline). Phase 1 retrospective gate prevents premature expansion. [A20] |
| Design tool learning curve | Phase 0 takes longer than expected | Medium | Gate deliverables can be produced in any tool (Figma, HTML/CSS, etc). Tool is a means, not an end. |
| FIF SQLite schema changes during soak | Intelligence page Pipeline section breaks | Low | FIF is in production soak with stable schema. Adapter pattern isolates changes. |
| M-Web absorption delays FIF web delivery | FIF users get no web UI while dashboard is built | Medium | Kill-switch: if Pipeline section can't reach M-Web parity by end of Phase 1 M3, M-Web reverts to standalone. [A11] |
| A2A delivery adapter design diverges | Dashboard's write capabilities don't align with A2A | Medium | Phases 1-3 are read-dominant and A2A-independent. Phase 4 writes are explicitly A2A facades. [A8] |
| attention-item notes create vault clutter | Too many small notes in the vault | Low | Archival policy: 30-day cleanup for done/dismissed items. Volume at expected scale (dozens/month) is manageable. [A17] |
| Mobile experience is poor | Dashboard not useful on phone | Medium | Design phase tests mobile viewport for Attention + Ops. Desktop is primary; mobile is triage-capable, not feature-complete. [A15] |
| Dependency blur across projects | Dashboard becomes where upstream gaps are papered over | Medium | Panel availability matrix (§6.0) forces honesty. Blocked panels show placeholders, not aspirational content. [A10] |

---

*This specification was drafted in a claude.ai session (2026-03-07), peer reviewed by 4 models (Gemini 3, DeepSeek V3.2, GPT-5.2, Perplexity) in round 1 (20 amendments), then reviewed again with deep research by ChatGPT and Perplexity in round 2 (12 additional amendments; Gemini round 2 discarded for hallucinating). R2 amendments applied by Crumb session 2026-03-07. It synthesizes exploration across the vault mirror, tess-operations specs, agent-to-agent-communication spec, active-knowledge-memory audit, feed-intel-framework action plan, web design preference overlay, and design taste profile.*
