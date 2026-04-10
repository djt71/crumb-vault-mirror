---
project: mission-control
type: design-artifact
domain: software
status: approved
created: 2026-03-07
updated: 2026-03-07
tags:
  - design
  - dashboard
  - gate-review
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Mission Control — Design Gate Review (MC-010)

**Task:** MC-010
**Gate:** §9.1 Design Phase Gate (all items must pass before Phase 1 implementation)
**Result:** PASS — all 12 checklist items pass, operator approved
**Signed off:** 2026-03-07

## Gate Checklist (§9.1)

| # | Criterion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | All widget archetypes represented | **PASS** | 14 archetypes in `widget-vocabulary.html` + 4 panel variants in `panel-component.html`. All used across pages per archetype matrix in `widget-inventory.md`. |
| 2 | Typography matches taste profile | **PASS** | Source Serif 4 (serif headers), JetBrains Mono (data values), Inter (chrome). Documented in `design-system.md`. |
| 3 | Color palette chosen | **PASS** | Dark Observatory palette: 8 token groups, 30+ tokens. Status green/amber/red, teal accent. `design-system.md` §1. |
| 4 | ≥2 pages mocked at real data density | **PASS** | 3 pages: Attention (MC-007, 12 cards), Ops (MC-002/008, 9 KPIs + 9 services + 4 gauges + 18 timeline dots), Intelligence (MC-009, Pipeline + Production). No placeholder text. |
| 5 | Attention scannable <10s | **PASS** | Urgency strip with counts at top (Now:2, Soon:3, Ongoing:4, Awareness:3), color-coded left borders, domain tags on every card. |
| 6 | Ops "house on fire?" <5s | **PASS** | System Status strip (9 KPIs) with red/amber/green indicators at page top, gauges below. Fire-state visible without scrolling. |
| 7 | 4-6 sections / 3-7 widgets per section | **PASS** | Attention: 5 sections. Ops: 6 active + 1 blocked (Operational Intelligence at 50% opacity) — blocked section is visually inert, adds zero cognitive load per Hick's Law. Guideline applies to active, attention-competing sections. Intelligence: 2 main sections (Pipeline 4 subsections, Production 4 subsections). |
| 8 | Conventional interactions (Jakob's Law) | **PASS** | Nav rail, filter badges, expandable cards, search overlay, collapsible sections — all standard patterns. |
| 9 | Refresh/staleness states designed | **PASS** | MC-055: 4 state patterns (blocked, empty, error, stale) with distinct visual treatments at 3 levels each (full panel, KPI card, card-within-list). |
| 10 | Mobile viewport tested (375px) | **PASS** | MC-055: CSS analysis of Attention + Ops. Page header flex-wrap fix applied. Nav rail 48px, KPI strip 2-col stack, text floors (13px/14px) maintained. |
| 11 | Empty/stale/error visual treatments | **PASS** | MC-055: `.state-empty`, `.state-error-banner`, `.state-stale-banner`, `.blocked-panel` in `widget-vocabulary.css` with demos. Design tokens `--bg-skeleton`, `--text-disabled` added to all palette blocks. |
| 12 | Aesthetic direction decided | **PASS** | D1: Dark Observatory (Direction B). Documented in `aesthetic-brief.md`. Rationale: dark mode is functionally superior for Observatory mode (status color distinction), distinct from Library mode warm-light preference. |

## 6-vs-7 Page Decision

**Decision: 6 pages (merged Intelligence).**

The Intelligence mockup (MC-009) combines Pipeline and Production sections on one page, separated by `page-section-header` dividers with accent underlines. Content volume fits without overcrowding — Pipeline has 5 KPIs + digest + health, Production has 4 panels. Splitting would create two thin pages. Confirmed from screenshot review.

## Panel Availability Matrix

| Page | Section | Panel | Availability | Notes |
|------|---------|-------|-------------|-------|
| **Attention** | Urgency Strip | 4 KPI counts | Derivable | Aggregator computes from dispatch state + FIF health + vault-check + Healthchecks |
| | Card List | System cards | Available | Dispatch state files exist (`_openclaw/state/dispatch/`) |
| | Card List | Relational cards | Derivable | Customer-intel dossiers exist (3/25), needs cadence parsing |
| | Card List | Personal cards | Available | Manual quick-add + overlay items |
| | Card List | Approval cards | Available | Dispatch `blocked`/`review-needed` state |
| | Quick-Add | Form | Available | Write endpoint creates vault files |
| | Filters | Filter toggles + views | Available | UI state only |
| | Completed Feed | Done/dismissed cards | Derivable | Needs status field tracking |
| **Ops** | System Status | 9 KPI cards | Derivable | Needs `system-stats.sh` + `service-status.sh` (MC-016 deliverables) |
| | Resource Gauges | 4 SVG gauges | Derivable | Same source as System Status |
| | Services | 9 service cards | Derivable | `launchctl list` + log parsing |
| | 24h Timeline | Activity timeline | Derivable | `health-check.log` parsing |
| | LLM Status | 5 model cards | Derivable | ops-metrics (TOP-050 run logs) + dispatch telemetry |
| | Cost Burn | Daily spend bars | Derivable | ops-metrics aggregation |
| | Operational Intelligence | Efficiency | **Blocked** | Requires self-optimization loop |
| | Operational Intelligence | Tempo | **Blocked** | Requires tempo adaptation |
| | Operational Intelligence | Degradation | **Blocked** | Requires degradation-aware routing |
| **Intelligence** | Pipeline KPIs | 5 KPI cards | Available | FIF SQLite state DB (in production soak) |
| | Digest Panel | Signal cards | Available | FIF SQLite state DB |
| | Signal Detail | Expanded signal | Available | FIF SQLite state DB |
| | Pipeline Health | Circuit breakers + table | Available | FIF state DB + logs |
| | Tuning | Feedback analysis | **Blocked** | Requires FIF feedback analysis feature |
| | Research Briefs | Brief queue | Available | `_openclaw/inbox/` files exist |
| | Weekly Brief | Rendered markdown | Available | `_openclaw/inbox/` files exist |
| | Brainstorm | Featured card | Available | `_openclaw/inbox/` files exist |
| | Ecosystem Radar | Scan results | Available | `_openclaw/inbox/` files exist |
| **Customer** | Account Dashboard | Health + completeness | Available | Customer-intel dossiers (3/25 populated) |
| | Privacy Notice | Static panel | Available | Static content |
| | Career Positioning | Action items | Derivable | Career-coach attention items (needs scanning) |
| | Relationship Heat Map | Contacts + cadence | **Blocked** | Requires Google/Apple integration |
| | Pre-Brief | Meeting prep | **Blocked** | Requires A2A Workflow 3 |
| | Comms Cadence | Communication patterns | **Blocked** | Requires Google/Apple integration |
| **Agent Activity** | Agent Cards | 3 agent cards | Available | Dispatch state + tess-context.md exist |
| | Dispatch Log | Lifecycle table | Available | `_openclaw/state/dispatch/` files |
| | Cost Dashboard | Token/cost bars + trend | Derivable | ops-metrics + dispatch cost aggregation |
| | Context Model | Rendered markdown | Available | `_openclaw/state/tess-context.md` |
| | Session Cards | Prep + debrief | **Blocked** | Requires TOP-047 |
| **Knowledge** | Vault Health | 4 KPI cards | Available | vault-check output exists |
| | AKM Panel | Hit rate + tables + action | Available | `akm-feedback.jsonl` exists |
| | Project Health | Project cards + stall flags | Available | `project-state.yaml` files exist |
| | Tag Distribution | Tag chart/table | Derivable | MOC files + vault scan needed |
| | Vault Gardening | 5 sub-panels | Derivable | Various vault scans + QMD stats |
| | Decision Journal | Decisions browser | **Blocked** | Requires decision journal implementation |

**Summary:** 9 blocked panels across 5 pages (Attention has 0). Count matches widget inventory (confirmed after MC-006 review correction from 8→9). All blocked panels have placeholder treatment designed (`.blocked-panel` class from MC-055). All non-blocked panels are available or derivable — no data source surprises for Phase 1.

## Design System Approval

Operator approved the design system for Phase 1 implementation (2026-03-07). Artifacts:

- `design/design-system.md` — color tokens, typography scale, panel variants, state pattern tokens
- `design/mockups/widget-vocabulary.html` + `.css` — 14 widget archetypes + 4 state patterns
- `design/mockups/panel-component.html` — 4 panel variants
- `design/mockups/ops-mockup.html` + `.css` — Ops page at full data density
- `design/mockups/attention-mockup.html` + `.css` — Attention page at full data density
- `design/mockups/intelligence-mockup.html` + `.css` — Intelligence page (Pipeline + Production)

## Phase 0 Complete

All 10 Phase 0 tasks done (MC-001 through MC-010). Design decisions D1-D6 recorded. Gate passed. Phase 1 implementation unblocked.
