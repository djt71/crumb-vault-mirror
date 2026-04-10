---
project: mission-control
type: design-artifact
domain: software
status: active
created: 2026-03-07
updated: 2026-03-07
tags:
  - design
  - dashboard
  - web
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Mission Control — Widget Inventory

**Task:** MC-006
**Source:** Spec §6.1-6.6, ops-mockup.html, widget-vocabulary.html, design-system.md

## Summary

| Metric | Value |
|--------|-------|
| Total widget instances | 97 (structural count — see note) |
| Widget archetypes used | 14 (all from widget vocabulary) + 4 panel variants (design system) |
| Custom SVG gauges | 4 / 4 budget allocated (all Ops page) |
| Blocked panels (placeholder) | 9 (across Ops, Intelligence, Customer, Agent Activity, Knowledge) |
| Pages | 6 + Nav Shell |

*Structural count: variable-count widgets (attention cards ×N, signal cards ×N, search result cards ×N, dossier completeness bars ×N, project cards ×N) are counted as one archetype slot each. Runtime widget count will be higher depending on data volume. The 97 figure represents distinct widget placements that each need implementation, not the number of elements rendered at any given time.*

## Analog Readout Budget

**Selected (4/4):**

| # | Widget | Page | Section | Rationale |
|---|--------|------|---------|-----------|
| 1 | CPU Load gauge | Ops | Resource Gauges | Core resource percentage with ok/warn/error threshold coloring |
| 2 | Memory gauge | Ops | Resource Gauges | Core resource percentage with ok/warn/error threshold coloring |
| 3 | Disk gauge | Ops | Resource Gauges | Core resource percentage with ok/warn/error threshold coloring |
| 4 | GPU gauge | Ops | Resource Gauges | Core resource percentage with ok/warn/error threshold coloring |

*GPU gauge note: present in ops-mockup.html (MC-002) but not mentioned in spec §6.2 data sources ("CPU/RAM/disk") or MC-016 acceptance criteria ("CPU load, memory usage, disk utilization"). Keeping it — Mac Studio M3 Ultra GPU is worth monitoring. MC-016 scope needs updating to include GPU utilization collection in `system-stats.sh`.*

**Candidates not selected:**

| Widget | Page | Treatment Instead | Rationale |
|--------|------|-------------------|-----------|
| FIF cost vs ceiling | Intelligence | Progress bar in KPI card | Additive fill toward ceiling — bar is more natural than arc |
| YT API quota | Intelligence | KPI card (fraction) | Simple daily quota, numeric display sufficient |
| Dossier completeness | Customer | Progress bar (per account) | Many instances — gauge doesn't scale to N accounts |
| Budget vs actual | Agent Activity | Cost panel (bar rows) | Matches Ops cost burn pattern — consistency over novelty |
| MOC coverage | Knowledge | KPI card (percentage) | Single number, no threshold coloring needed |

## Inventory by Page

### Nav Shell (cross-cutting)

| Section | Widget Name | Widget Type | Data Source | Custom/Standard |
|---------|-------------|-------------|-------------|-----------------|
| Nav Rail | Page nav items (×6) | Nav item + icon | — (static) | standard |
| Nav Rail | Attention badge | Nav badge | `GET /api/nav-summary` | standard |
| Nav Rail | Page status dots (×6) | Status indicator (6px) | `GET /api/nav-summary` (adapter error roll-up) | standard |
| Header | Search bar | Form input | — (user input) | standard |
| Search Overlay | Search result cards (×N) | Search result card | `GET /api/search` (QMD) | standard |

### 1. Attention / Inbox

| Section | Widget Name | Widget Type | Data Source | Custom/Standard |
|---------|-------------|-------------|-------------|-----------------|
| Urgency Strip | Now count | KPI card | attention aggregator | standard |
| Urgency Strip | Soon count | KPI card | attention aggregator | standard |
| Urgency Strip | Ongoing count | KPI card | attention aggregator | standard |
| Urgency Strip | Awareness count | KPI card | attention aggregator | standard |
| Card List | System attention cards (×N) | Attention card (system) | dispatch state, FIF health, vault-check, Healthchecks.io | standard |
| Card List | Relational attention cards (×N) | Attention card (relational) | customer-intel cadence, follow-through items | standard |
| Card List | Personal attention cards (×N) | Attention card (personal) | manual quick-add, overlay items, AKM stale sources | standard |
| Card List | Approval cards (×N) | Approval card | dispatch state (`blocked` / `review-needed`) | standard |
| Quick-Add | Quick-add form | Form input (title + dropdowns) | user input → `POST /api/attention` | standard |
| Filters | Filter toggles (domain, urgency, kind, source, action) | Badge (interactive) | UI state | standard |
| Filters | View switcher (triage / domain / source) | Tabs | UI state | standard |
| Completed Feed | Done/dismissed cards (×N) | Attention card (muted) | attention aggregator (done/dismissed status) | standard |

### 2. Ops / Infrastructure

| Section | Widget Name | Widget Type | Data Source | Custom/Standard |
|---------|-------------|-------------|-------------|-----------------|
| System Status | Tess Status | KPI card + status indicator | `/tmp/tess-health-check.state` | standard |
| System Status | Gateway | KPI card + status indicator | `service-status.json` | standard |
| System Status | FIF Capture | KPI card + status indicator | `service-status.json` | standard |
| System Status | FIF Attention | KPI card + status indicator | `service-status.json` | standard |
| System Status | FIF Feedback | KPI card + status indicator | `service-status.json` | standard |
| System Status | Healthchecks | KPI card + status indicator | Healthchecks.io API | standard |
| System Status | CPU Load | KPI card + sparkline | `system-stats.json` | standard |
| System Status | Memory | KPI card | `system-stats.json` | standard |
| System Status | Disk | KPI card | `system-stats.json` | standard |
| Resource Gauges | CPU Load gauge | Gauge | `system-stats.json` | **custom SVG gauge** |
| Resource Gauges | Memory gauge | Gauge | `system-stats.json` | **custom SVG gauge** |
| Resource Gauges | Disk gauge | Gauge | `system-stats.json` | **custom SVG gauge** |
| Resource Gauges | GPU gauge | Gauge | `system-stats.json` | **custom SVG gauge** |
| Services | Tess Voice | Service card | `service-status.json` | standard |
| Services | Tess Mechanic | Service card | `service-status.json` | standard |
| Services | OpenClaw Gateway | Service card | `service-status.json` | standard |
| Services | FIF Capture | Service card | `service-status.json` | standard |
| Services | FIF Attention | Service card | `service-status.json` | standard |
| Services | FIF Feedback | Service card | `service-status.json` | standard |
| Services | Awareness Check | Service card | `service-status.json` | standard |
| Services | Health Check | Service card | `health-check.log` | standard |
| Services | Vault Check | Service card | vault-check output | standard |
| 24-Hour Timeline | Activity timeline | Timeline | `health-check.log`, service events | standard |
| LLM Status | Anthropic Haiku | Service card (LLM variant) | ops-metrics (TOP-050), dispatch telemetry | standard |
| LLM Status | Anthropic Sonnet | Service card (LLM variant) | ops-metrics, dispatch telemetry | standard |
| LLM Status | Anthropic Opus | Service card (LLM variant) | ops-metrics, dispatch telemetry | standard |
| LLM Status | Local qwen3-coder | Service card (LLM variant) | ops-metrics, dispatch telemetry | standard |
| LLM Status | Mistral Devstral | Service card (LLM variant) | ops-metrics, dispatch telemetry | standard |
| Cost Burn | Daily API spend (6 bar rows) | Cost panel (standard panel + progress bars) | ops-metrics | standard |
| Operational Efficiency | Signal-to-noise, cost per action, false positive rate | Standard panel | self-optimization loop | standard (blocked: upstream) |
| Operational Tempo | Tess mode indicator + reasoning | Standard panel | — | standard (blocked: tempo adaptation) |
| Degradation | API latency trends, model quality, data freshness | Standard panel | — | standard (blocked: degradation-aware routing) |

### 3. Intelligence

**Pipeline section:**

| Section | Widget Name | Widget Type | Data Source | Custom/Standard |
|---------|-------------|-------------|-------------|-----------------|
| Pipeline KPIs | Signals today + sparkline | KPI card + sparkline | FIF SQLite state DB | standard |
| Pipeline KPIs | Signals this week | KPI card | FIF SQLite state DB | standard |
| Pipeline KPIs | Per-source breakdown (X/RSS/YT) | KPI card | FIF SQLite state DB | standard |
| Pipeline KPIs | Triage distribution (T1/T2/T3) | KPI card | FIF SQLite state DB | standard |
| Pipeline KPIs | Cost today vs ceiling | KPI card + progress bar | FIF SQLite state DB | standard |
| Digest Panel | Signal cards (×N) | Signal card | FIF SQLite state DB | standard |
| Signal Detail | Expanded signal + research context | Signal card (expanded) | FIF SQLite state DB | standard |
| Pipeline Health | Circuit breaker status (×3 services) | Status indicator + label | pipeline-health adapter | standard |
| Pipeline Health | Run times + error rates | Data table | pipeline-health adapter | standard |
| Tuning | Feedback analysis, topic weights, tuning recs | Standard panel | — | standard (blocked: FIF feedback analysis) |

**Production section:**

| Section | Widget Name | Widget Type | Data Source | Custom/Standard |
|---------|-------------|-------------|-------------|-----------------|
| Research Briefs | Brief queue cards (×N) | Signal card (variant) | `_openclaw/inbox/` research briefs | standard |
| Weekly Brief | Latest intelligence brief | Standard panel (rendered markdown) | `_openclaw/inbox/` intelligence briefs | standard |
| Brainstorm | Connections featured card | Signal card (variant) | `_openclaw/inbox/` brainstorm files | standard |
| Ecosystem Radar | Builder scan results | Standard panel | `_openclaw/inbox/` scan output | standard |

### 4. Customer / Career

| Section | Widget Name | Widget Type | Data Source | Custom/Standard |
|---------|-------------|-------------|-------------|-----------------|
| Account Dashboard | Account list with health indicators | Data table + status indicators | customer-intel dossiers | standard |
| Account Dashboard | Dossier completeness (×N accounts) | Progress bar | customer-intel dossiers | standard |
| Account Dashboard | Engagement status | Status indicator | customer-intel dossiers | standard |
| Account Dashboard | Privacy notice | Standard panel (static) | — | standard |
| Relationship Heat Map | Contacts with cadence + stale flags | — (placeholder) | — | standard (blocked: Google/Apple integration) |
| Pre-Brief | Meeting prep with adversarial briefs | — (placeholder) | — | standard (blocked: A2A Workflow 3) |
| Career Positioning | Action items + skill milestones | Attention card (personal variant) | career-coach attention items | standard |
| Comms Cadence | Communication patterns + follow-through | — (placeholder) | — | standard (blocked: Google/Apple integration) |

### 5. Agent Activity

| Section | Widget Name | Widget Type | Data Source | Custom/Standard |
|---------|-------------|-------------|-------------|-----------------|
| Agent Cards | Tess Voice | Agent status card | `_openclaw/state/dispatch/`, `tess-context.md` | standard |
| Agent Cards | Tess Mechanic | Agent status card | `_openclaw/state/dispatch/` | standard |
| Agent Cards | Crumb | Agent status card | session state (run-log, project-state) | standard |
| Dispatch Log | Dispatch lifecycle table | Data table | `_openclaw/state/dispatch/` files | standard |
| Cost Dashboard | Token/cost by model (bar rows) | Cost panel (standard panel + progress bars) | ops-metrics, dispatch costs | standard |
| Cost Dashboard | Usage trend | Sparkline | ops-metrics | standard |
| Context Model | Tess priorities + staleness | Standard panel (rendered markdown) | `_openclaw/state/tess-context.md` | standard |
| Session Cards | Prep files + debrief summaries | Standard panel | — | standard (blocked: TOP-047) |

### 6. Knowledge / Vault

| Section | Widget Name | Widget Type | Data Source | Custom/Standard |
|---------|-------------|-------------|-------------|-----------------|
| Vault Health | Total notes | KPI card | vault-check output | standard |
| Vault Health | MOC coverage | KPI card | vault-check output | standard |
| Vault Health | Vault-check status | KPI card + status indicator | vault-check output | standard |
| Vault Health | Last check time | KPI card | vault-check output | standard |
| AKM Panel | Hit rate (rolling 10 sessions) + sparkline | KPI card + sparkline | `akm-feedback.jsonl` | standard |
| AKM Panel | Most-surfaced sources | Data table | `akm-feedback.jsonl` | standard |
| AKM Panel | Never-surfaced sources (dead knowledge) | Data table | `akm-feedback.jsonl` | standard |
| AKM Panel | "Review stale sources" action | Action link → `POST /api/attention` | `akm-feedback.jsonl` | standard |
| Project Health | Project cards (×N active) | Service card (variant) | `project-state.yaml` files | standard |
| Project Health | Stall detection flags | Status indicator | `project-state.yaml` (days since `next_action` change) | standard |
| Project Health | BBP enriched card (progress + queue) | Service card (variant) + progress bar | batch-book-pipeline state files | standard |
| Tag Distribution | Tag usage chart/table | Data table | MOC files, vault tag scan | standard |
| Vault Gardening | Dead knowledge list + archive links | Data table + action links | QMD surfacing stats | standard |
| Vault Gardening | Orphan detection panel | Data table | vault scan (no inbound links/MOC/tags) | standard |
| Vault Gardening | Stale source candidates | Data table | vault timestamps (>6 months unreferenced) | standard |
| Vault Gardening | Tag hygiene panel | Data table | vault-check tag stats | standard |
| Vault Gardening | QMD collection health | KPI card | QMD stats (growth, chunks, anomalies) | standard |
| Decision Journal | Browsable decisions + conditions | Standard panel | — | standard (blocked: decision journal impl) |

## Instance Count by Page

| Page | Instances | Custom SVG | Blocked |
|------|-----------|------------|---------|
| Nav Shell | 5 | 0 | 0 |
| Attention | 12 | 0 | 0 |
| Ops | 32 | 4 | 3 |
| Intelligence | 14 | 0 | 1 |
| Customer | 8 | 0 | 3 |
| Agent Activity | 8 | 0 | 1 |
| Knowledge | 18 | 0 | 1 |
| **Total** | **97** | **4** | **9** |

*Note: Blocked instances appear as placeholder panels ("Coming soon — requires [dependency]") per §6.0. They are counted in the total because they occupy layout space and need the empty-state treatment designed in MC-055.*

## Archetype Usage by Page

| Archetype | Attn | Ops | Intel | Cust | Agents | Know | Nav |
|-----------|------|-----|-------|------|--------|------|-----|
| KPI card | 4 | 9 | 5 | — | — | 5 | — |
| Service card | — | 14 | — | — | — | N | — |
| Standard panel | — | 4 | 4 | 4 | 3 | 3 | — |
| Gauge (SVG) | — | 4 | — | — | — | — | — |
| Status indicator | — | 9+ | 3 | 1 | — | 1 | 6 |
| Sparkline | — | 1 | 1 | — | 1 | 1 | — |
| Timeline | — | 1 | — | — | — | — | — |
| Attention card | 4 | — | — | 1 | — | — | — |
| Signal card | — | — | 4 | — | — | — | — |
| Agent status card | — | — | — | — | 3 | — | — |
| Search result card | — | — | — | — | — | — | N |
| Approval card | 1 | — | — | — | — | — | — |
| Progress bar | — | 6 | 1 | N | 1 | 1 | — |
| Badge | 3 | — | 2 | — | — | — | 1 |
| Data table | — | — | 1 | 1 | 1 | 6 | — |
| Form input | 1 | — | — | — | — | — | 1 |

*All 14 widget vocabulary archetypes + 4 panel variants are used. No new custom archetypes needed beyond the existing vocabulary.*

## References

- `design/mockups/widget-vocabulary.html` — archetype definitions (14 types)
- `design/mockups/widget-vocabulary.css` — new archetype styles
- `design/mockups/ops-mockup.html` — Ops page instance reference
- `design/mockups/ops-mockup.css` — existing archetype styles + design tokens
- `design/design-system.md` — panel variants, color tokens, typography
- `design/specification.md` §6.1-6.6 — per-page layout and data sources
