---
project: mission-control
type: specification-summary
source_updated: 2026-03-30
domain: software
status: active
created: 2026-03-07
updated: 2026-04-05
tags:
  - dashboard
  - web
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Mission Control Dashboard — Specification Summary

## Problem
Operational visibility is fragmented across Telegram, terminal, Healthchecks.io, vault files, and manual memory. No single surface answers "what needs me?" Attention items leak, intelligence is consumed in low-fidelity channels, feedback loops are incomplete, and cross-domain awareness doesn't exist.

## Solution
A multi-page web dashboard providing unified operational visibility, attention management, intelligence consumption, and — progressively — feedback, approval, and control capabilities across the Crumb ecosystem.

## Stack & Architecture
- **Frontend:** React + Vite + Tailwind CSS
- **Backend:** Express.js (BFF — backend for frontend)
- **Data:** Direct reads from existing sources (SQLite, filesystem, APIs). No intermediate database.
- **Hosting:** Mac Studio, Cloudflare Tunnel + Access (single-user auth)
- **Monorepo:** `crumb-dashboard/packages/{api,web}`

## Six Pages (Phases 1-3) + Two Future Pages
1. **Attention / Inbox** (landing) — "What needs Danny?" Cross-domain command queue. Three item kinds: system, relational, personal. Four urgencies: now/soon/ongoing/awareness. Switchable views: triage, domain, source. Quick-add.
2. **Ops / Infrastructure** — "Is the house on fire?" Service health, KPI strip, 24h timeline, cost burn, system resources. Includes LLM Status panel: one card per provider/model (Anthropic Opus/Sonnet/Haiku, Mistral, local qwen3-coder) showing success rate, p95 latency, call count, degradation timestamp — derived from ops metrics harness, not provider status pages. Section appears above Cost Burn. [AP-19]
3. **Intelligence** (merged) — Pipeline section (FIF SQLite adapter, dense signal list with multi-axis filter bar, tier badges, shared tier config, pipeline health, triage actions) + Production section (research briefs, weekly intel, connections brainstorm). Amendment S (2026-03-30): Surface-inspired density redesign, primary-surface read-state model.
4. **Customer / Career** — Account dossiers, relationship heat map, pre-brief panel, career positioning. Privacy-constrained (C7).
5. **Agent Activity** — Agent status cards, dispatch log, cost dashboard, context model, session cards.
6. **Knowledge / Vault** — Vault health, AKM panel, project health, tag distribution, vault gardening (dead knowledge, orphan detection, stale sources, tag hygiene).
7-8. **Future:** Personal Finance + Home Dashboard (Phase 3+).

## Amendment S: Intelligence Page Density Redesign (2026-03-30)
- **Shared tier config [S-1]:** `tier-config.ts` defines T1/T2/T3 mappings (priority → display label, status color). Consumed by BFF (filter grouping, faceted counts) and frontend via `/api/config`. Currently categorical (high/medium/low); future evolution to numeric score ranges when FIF adds a reranker.
- **Multi-axis filter bar [S-1]:** Four stacked rows of chip-style toggles with per-value item counts. Rows: Tier (All, T1, T2, T3), Source (All, X, RSS, HN, Reddit, arXiv, YouTube), Topic (derived from FIF SQLite), Format (All, Article, Paper, Thread, Video, Discussion). "ALL" button clears all filters. Faceted counts from BFF querying FIF SQLite.
- **Dense signal list layout [S-3]:** Flat list — one row per item, no card chrome (no borders, border-radius, box-shadow, or padding containers). Each row: tier badge (left margin, colored by tier status color; future: numeric score badge) | title + thesis inline (bold title + ~80-char truncated description, separated by dash) | source label + relative timestamp (right-aligned). Text-only source labels — no favicons, avatars, or thumbnails. Subtle bottom divider. Target: ~24 items per viewport. Click to expand inline detail panel.
- **Read-state model [S-2]:** Dashboard is the authoritative triage surface. A `seen_at` timestamp column in FIF SQLite records when an item was marked read — written only by explicit dashboard interaction. Telegram and morning briefings surface items but do not write read state; items appear as "new" on dashboard until triaged. Visual treatment: unread = bold title, read = normal weight. Schema change deferred to M3.1 Phase 2; design decision locked now.
- **Design-phase gates:** M3.1 splits into three sub-phases — Phase 1 (filter bar + dense list + triage actions), Phase 2 (read/unread state + time-bucketed counts + compact view toggle), Phase 3 (AI-generated thesis summaries — deferred, high compute cost).
- **AI summaries deferred [S-4]:** Current inline description is a truncated snippet. Future: per-item LLM summarization pass generating distilled one-liner thesis statements. High value, high cost — not in M3.1 Phase 1 scope.

## New Vault Primitive: attention-item
- Vault-native markdown notes with YAML frontmatter (schema_version: 1)
- Fields: attention_id (UUID v4), kind, domain, source_overlay/system, status, urgency, action_type, related_entity, due, deferred_until
- Location: `_inbox/attention/`, archived to `Archived/attention/YYYY-MM/`
- **Capture ownership model [A3]:** Single writer per item kind eliminates double-capture. System items → Tess. Relational → Tess or A2A workflow. Personal/overlay → Crumb session-end hook (Phase 5). Manual → Dashboard or Obsidian. The `/attention` aggregator is read-only.
- **Staleness nudge [R2-7]:** Open items untouched >14 days → Tess surfaces in next morning briefing with "still relevant?" prompt. No new items created; operator acts, defers with new `deferred_until`, or dismisses.
- **Vault-native persistence [R2-8]:** Vault markdown is source of truth (Obsidian-editable, compound engineering principle). API layer may maintain a lightweight SQLite cache if performance budget (400ms Doherty Threshold) is exceeded. Cache is not a second source of truth.
- Write atomicity: temp-file-then-atomic-rename pattern. Dedup: same source_ref within 24h → update existing.

## Build Order (5 phases, 16 milestones)
- **Phase 0:** Design (4-8 sessions). HTML/CSS mockups primary approach. Sub-milestones: 0a aesthetic exploration (dark/light/hybrid competing directions), 0b formal deliverables (widget vocabulary, color, typography, panels, page mockups). 12-item gate checklist must pass. No React code until gate clears (C3).
- **Phase 1:** Foundation + Attention-lite + Ops + Intel Pipeline (8-12 sessions). M1 scaffolding, M2 Ops, M3 Intel Pipeline (M-Web parity gate + M3.1 density scope), M4 Attention-lite + quick-add.
- **Phase 1 Retrospective** (mandatory) — 1-week usage period before Phase 2.
- **Phase 2:** Full Attention + Knowledge (4-6 sessions). M5 full attention schema, M6 Knowledge page, M7 attention-item status updates.
- **Phase 3:** Agent Activity + Customer/Career + Intel Production (4-6 sessions). M8-M10.
- **Phase 4:** Feedback + Approval via A2A facades (3-5 sessions). M11-M13.
- **Phase 5:** Control Plane (3-5 sessions). M14-M16, including session-end attention-item capture hook.
- **Total:** 22-36 sessions for Phases 0-3 (functional read-dominant dashboard).

## Key Constraints
- C1: Solo operator, single user
- C2: Single machine (Mac Studio)
- C3: Visual design gate — no React code before Phase 0 passes
- C4: Read-dominant Phases 1-3; writes are attention-item quick-add (P1), feed triage actions (P1), and attention status updates (P2)
- C5: File-based data sources (markdown, JSONL, SQLite)
- C6: Ceremony Budget Principle — no Redis, Postgres, Docker, message queues
- C7: Customer-intelligence data never exposed publicly

## Data Refresh Strategy
- Ops: 30s auto + manual
- Attention, Agent Activity: 60s auto + manual
- Intelligence, Customer, Knowledge: manual pull
- Auto-refresh pauses when tab not visible

## Key Decisions Made
- HTML/CSS mockups as primary Phase 0 approach [R2-2]
- Dark/light/hybrid is an open design exploration, not predetermined [R2-1]
- Vault-native persistence for attention items; SQLite cache only if performance budget exceeded [R2-8]
- M-Web absorbed into Intelligence page Pipeline section (kill-switch at M3)
- Phase 1 retrospective gate before Phase 2 expansion [A20]
- Write atomicity via temp-file-then-rename [R2-4]
- Markdown sanitization with DOMPurify [R2-5]
- Approval idempotency contract for dual-surface (Telegram + dashboard) [R2-6]
- Feed triage: skip/delete immediate, promote queued for feed-pipeline skill. Separate `dashboard_actions` table in FIF SQLite (clean schema ownership). Promotion logic stays in feed-pipeline skill. [§8.6]
- Dashboard is primary-surface read-state owner for feed intelligence; other surfaces do not write seen_at [S-2]
- LLM Status panel placed above Cost Burn in Ops page [AP-19]
- Single writer per attention-item kind; aggregator is read-only [A3]

## Dependencies
- **Upstream:** FIF production soak complete, Cloudflare Tunnel + Access operational, Phase 0 design gate
- **Parallel:** A2A Phase 1, tess-ops M2+, TOP-049
- **Related projects:** feed-intel-framework, agent-to-agent-communication, tess-operations, active-knowledge-memory, customer-intelligence, crumb-tess-bridge

## Success Criteria
- SC-1: Dashboard replaces Telegram for morning orientation within 2 weeks of Phase 1
- SC-2: Attention page surfaces ≥1 missed item/week
- SC-3: Intel Pipeline preferred over Telegram for digests within 1 week
- SC-4: AKM feedback data visible on Knowledge page with actionable path
- SC-5: No operational blind spots requiring terminal/log access
- SC-6: Observatory mode passes design gate (or alternative selected)
- SC-7: Dashboard is a monitored service — Tess alerts on failure
