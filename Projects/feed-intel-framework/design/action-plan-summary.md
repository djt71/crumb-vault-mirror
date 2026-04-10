---
type: summary
project: feed-intel-framework
domain: software
skill_origin: action-architect
created: 2026-02-23
updated: 2026-02-25
source_updated: 2026-02-25
tags:
  - openclaw
  - tess
  - automation
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Feed Intelligence Framework — Action Plan Summary

## Plan Scope

55 tasks across 6 implementation milestones, decomposed from spec v0.3.5.
Covers Phase 1b.1 (framework extraction + X migration) through Phase 1d
(remaining adapters), plus M-Web (web presentation layer, parallel with M3/M4).
Phases 0/1a are complete via x-feed-intel. Phases 2-3 are deferred with
milestone placeholders.

## Milestones

**M1: Framework Core Infrastructure** (18 tasks, FIF-001–FIF-018)
Build the shared layer extracted from x-feed-intel: schema initialization,
adapter manifest loader, capture clock, triage engine (lightweight + standard
tiers), vault router with collision detection, per-source digests, feedback
protocol, cost telemetry + guardrails with weekly aggregate summary, queue
health with shared alert function, research promotion. Heavy-tier triage
deferred to M4.

**M2: X Adapter Migration** (11 tasks, FIF-019–FIF-029)
Staging migration environment, then refactor X pipeline as framework adapter.
Execute 5-stage migration (DB schema, cursor state, vault files + wikilinks,
verification suite, orchestrator + re-enable) with standalone rollback
procedure. Feature parity gate: 3-day operational comparison, ≥90% triage
match on 50 items, binary pass/fail.

**M3: RSS Adapter** (4 tasks, FIF-030–FIF-033)
Simplest adapter validates the adapter contract. Proves adding a source requires
no shared code changes (§14 criterion 1). Cross-source collision detection
validated with real X+RSS URL overlap. RSS Phase 0 can start after FIF-005
(manifest loader) — does not require M2 completion.

**M4: YouTube Adapter** (5 tasks, FIF-034–FIF-038)
Most complex adapter validates heavy-tier content system. Includes heavy-tier
triage engine (summarize-then-triage), transcript handling with circuit breaker
(activates at >80% error rate for 3 consecutive runs), and Phase 0 transcript
availability quantification.

**M-Web: Web Presentation Layer** (12 tasks, FIF-W01–FIF-W12, parallel with M3/M4)
Private web app replaces Telegram as primary digest surface. Express API + React
SPA + Vite + Tailwind on Mac Studio, Cloudflare Tunnel + Access for external auth.
Paper design sprint (W01) establishes design system before implementation. Split-pane
digest layout with dark mode from day one, loading/error states. Shared service
layer between web API and Telegram listener (W11). Telegram transitions to
notification-only with 2-week overlap. Web UI test suite (W12). Investigate action
(§5.13) stages deep-dive research — Tess sweep skeleton only until crumb-tess-bridge
is operational.

**M5: Remaining Adapters** (5 tasks, FIF-039–FIF-043)
HN, Reddit, arxiv — incremental rollout. Reddit has a hard Phase 0 API terms
gate. Final task validates all adapters running concurrently under framework
cost ceiling and reports per-adapter operational metrics.

## Critical Path

M1 → M2 → {M3, M-Web} → M4 → M5. After M2, M3 (RSS) and M-Web (web UI) can
proceed in parallel. The longest dependency chain runs through the migration
scripts (FIF-022 → FIF-025) and feature parity gate (FIF-029).

## High-Risk Tasks (7)

- **FIF-008:** Triage engine — critical-path for all adapters, extraction risk
- **FIF-022:** DB schema migration — alias ordering, idempotency, canonical_id rewrite
- **FIF-023:** Vault file rename + wikilink update — 6-variant regex, migration manifest
- **FIF-024:** Migration verification suite — standalone 8-check validation
- **FIF-025:** Migration orchestrator + re-enable — restartability, monitoring window
- **FIF-026:** Rollback procedure — backup restore primary, surgical reversal alternative
- **FIF-028:** Live migration execution — irreversible production data change
- All migration tasks mitigated by staging environment (FIF-020) + full backup + rollback

## Key Decisions Embedded in Plan

1. **Heavy-tier triage deferred to M4** — only needed for YouTube, not for X/RSS
2. **Sequential milestones** — no second adapter until X migration is proven
3. **RSS before YouTube** — simplest adapter first to validate contract
4. **RSS Phase 0 parallelizable** — can start after FIF-005, not gated on M2 completion
5. **HN/arxiv can overlap with M3/M4** — independent of RSS/YouTube after M2
6. **Reddit Phase 0 is independent** — can start anytime, doesn't block other adapters
7. **Backup restore is primary rollback** — surgical reversal documented as alternative only
8. **Web UI is parallel track** — M-Web after M2, parallel with M3/M4, not a sequential gate
9. **Investigate action decision gate** — skeleton built in M-Web, Tess sweep model selection deferred to tess-model-architecture production data

## Deferred Work

- **M-Manual:** Manual intake adapter — Tess as capture surface for ad-hoc URLs
  via Telegram, lightweight/skipped triage, standard vault routing. Design decision
  in `design/manual-intake-adapter-decision.md`. Activates after M2 + one non-X
  adapter proves the contract.
- **Phase 2 (M6):** Per-source enrichment — thread expansion, linked content fetch,
  account monitoring, historical trends, triage refinement
- **Phase 3 (M7):** Learning loop — weight adjustment, cross-source correlation,
  source quality scoring, topic suggestion
