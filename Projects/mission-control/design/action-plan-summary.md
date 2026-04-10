---
project: mission-control
type: action-plan-summary
source_updated: 2026-03-30
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

# Mission Control Dashboard — Action Plan Summary

## Structure
- **5 phases, 10 milestones** (Phases 0-3 fully decomposed; Phases 4-5 milestone-level only)
- **59 atomic tasks** (MC-001 through MC-059, post-review amendments applied)
- **Estimated sessions:** 22-36 for Phases 0-3
- **Reviewed by:** Claude.ai (Opus 4.6) — 3 must-fix, 5 should-fix, all applied. Multi-model synthesis — 18 amendments (4 high-confidence, 4 medium-confidence, 10 single-reviewer), all applied. Dispatch review (GPT-5.2, Gemini 3, DeepSeek, Grok) — 6 net-new findings applied (2 must-fix, 4 should-fix).

## Phase 0: Design (4-8 sessions, 10 tasks)
- **M0a** (MC-001–003): Aesthetic exploration — 3 HTML/CSS candidates (dark/light/hybrid) for Ops page, operator selects direction
- **M0b** (MC-004–010): Design system deliverables — color, typography, widget vocabulary, widget inventory, page mockups (Attention, Ops, Intelligence), nav shell, empty/error/stale states, mobile viewport, design gate review (12 items)

## Phase 1: Foundation (8-12 sessions, 24 tasks)
- **M1** (MC-011–018): Monorepo, Express API, React shell, Cloudflare Tunnel, launchd, system scripts, nav-summary endpoint, conventions doc, CF Access middleware, prod build/serve
- **M2** (MC-019–023): Ops page — 6 adapters, KPI strip, service grid, 24h timeline, cost burn, 30s auto-refresh, adapter tests
- **M3** (MC-024–028): Intelligence Pipeline — FIF SQLite adapter, pipeline health, digest/signal rendering, M-Web parity gate
- **M4** (MC-029–034): Attention-lite — aggregator (single-source → multi-source per PC-1), quick-add, cards/filters/views, tests
- **Cross-project** (MC-053–054): M-Web/A2A absorption amendments, attention-item vault registration
- **Retro** (MC-035): 1-week usage (7-day minimum), SC-1/SC-3/SC-5 eval, testing/SSE decisions

## Phase 2: Full Attention + Knowledge (4-6 sessions, 10 tasks)
- **M5** (MC-036–039): Full attention-item schema, validation, expanded scanner (all kinds), multi-source aggregator, staleness indicators
- **M6** (MC-040–043): Knowledge page — QMD/AKM/vault-check/project-health adapters, shared search endpoint, frontend
- **M7** (MC-044–045): Attention status updates — PATCH endpoint, inline UI with undo

## Phase 3: Agent Activity + Customer + Intel Production + Intel Density (6-9 sessions, 14 tasks)
- **M3.1** (MC-080–086): Intelligence Feed Density Redesign — Surface-inspired dense list layout (5x density), multi-axis filter bar (Tier/Source/Topic/Format/Origin), tier badges, shared tier config, format normalization, triage_tags for topics, Saved/Discovery origin filter. Blocks M8.
- **M8** (MC-046–047): Intelligence Production section — inbox scanner, briefs/intel/brainstorm frontend. Depends on M3.1.
- **M9** (MC-048–049): Agent Activity page — dispatch/context/cost adapters, full page frontend
- **M10** (MC-050–052): Customer/Career page — dossier scanner (privacy-constrained), placeholder treatment, Phase 3 tests

## Phases 4-5: Feedback + Control (6-10 sessions, not decomposed)
- M11-M13: Feedback + approval via A2A facades — dependency-gated
- M14-M16: Control plane — future scope

## Key PLAN Decisions (R2 constraints resolved)
1. **Aggregator:** single-source first (dispatch), then progressive addition (PC-1)
2. **Nav badges:** `/api/nav-summary` at 60s, independent of page refresh (PC-2)
3. **Time:** UTC storage, local display, per-page sort keys defined (PC-3)
4. **Health strip:** auto-refreshes on manual-pull pages via nav-summary (PC-4)
5. **Analog gauges:** max 4 custom SVG; candidates suggested, Phase 0 decides (PC-5)
6. **Widget inventory:** Phase 0 gate deliverable with explicit counts (PC-6)
7. **Testing:** adapter unit tests required; aggregator integration tests at M4+; React component tests deferred to retro (PC-7)
8. **Notifications:** future consideration, Phase 3+ (PC-8)
9. **Data refresh:** polling-first, SSE deferred; upgrade path if retro reveals need (PC-9)

## Critical Path
M0a → M0b → M1 → M2 → M3 (M-Web gate) → M4 → Retro → M5 → M7

## Phase 3 Build Order
M3.1 (Intel Feed Density) → M8 (Intel Production). M9 and M10 independent.

## Post-Review Additions
- **AP-1:** attention_id switched to UUID v4 (collision-safe across writers)
- **AP-4:** Aggregator reads `_inbox/attention/` in Phase 1 (quick-add visibility)
- **AP-8:** PATCH uses mtime-based 409 Conflict detection; writeVaultFile includes .tmp cleanup
- **AP-9:** CSS variable palette toggle instead of 3 separate mockup files
- **AP-13:** Knowledge "review stale sources" wired to POST /attention
- **MC-055:** Empty/error/stale patterns + mobile viewport (split from MC-009)
- **MC-056:** Tess mechanic health monitoring integration (SC-7)
- **MC-057:** Playwright smoke test (E2E budget guardrail)
- **MC-058:** CF Access verification middleware (auth at route layer, not adapter) [DR-A1]
- **MC-059:** Production build + Express static serve [DR-A2]
- **DR-A3/A4:** M4 aggregator depends on M2 adapter pattern (MC-023); single-source integration test gate before multi-source
- **DR-A5:** Nav-summary controller wired per milestone (MC-022, MC-026, MC-033, MC-042, MC-051)
- **DR-A6:** Health strip on manual-pull pages (MC-026)

## Risk Highlights
- **MC-029/030 (aggregator):** highest-risk tasks — mitigated by single-source-first approach
- **MC-028 (M-Web parity gate):** binary decision point — fail triggers M-Web standalone revert
- **MC-010 (design gate):** blocks all implementation — operator must sign off
- **MC-014 (Cloudflare):** external dependency — validate Tunnel + Access before M1 completion
