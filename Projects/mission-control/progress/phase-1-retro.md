---
type: retrospective
domain: software
project: mission-control
status: active
created: 2026-03-12
updated: 2026-03-12
skill_origin: null
---

# Mission Control — Phase 1 Retrospective

## Timeline

| Date | Work | Milestone |
|------|------|-----------|
| Mar 7 | Spec (peer-reviewed, 32 amendments), action plan (59 tasks, 24 amendments) | SPECIFY + PLAN |
| Mar 7 | Phase 0 design system: aesthetic brief, 3 mockups, widget inventory, gate (10/10) | M0 |
| Mar 7 | Monorepo, Express API, React shell, nav, polling infra, CF Tunnel (8/8) | M1 |
| Mar 7-8 | 7 Ops adapters, full Ops page, 24h timeline, cost burn (5/5) | M2 |
| Mar 8 | FIF SQLite adapter, pipeline health, Intel page Pipeline section (4/5) | M3 |
| Mar 8 | Attention aggregator (multi-source), quick-add, full frontend (6/6) | M4 |
| Mar 9 | dashboard_actions table, skip/delete/promote endpoints + UI, feed-pipeline entry path (5/5) | M3b |
| Mar 9 | Cross-project amendments, vault registration, Tess mechanic integration, Playwright, CF Access, prod build (7/7) | Cross-project |
| Mar 9-11 | **Operator usage trial** — 3 days signal triage via dashboard | Parity gate |
| Mar 12 | 5 UX fixes from operator feedback, MC-068 research triage action, parity gate pass | M3 gate + M3b |

**Total:** 6 implementation sessions across 6 days. 56 of 58 Phase 1 tasks done (MC-035 retro + MC-066 sync-back remain).

## Daily Usage Assessment

**Operator usage pattern (Mar 9-12, 4 days observed):**

The dashboard is used daily for signal triage. The operator opens Intel Pipeline to review signals, makes skip/promote/research decisions, and moves on. This replaced the previous workflow of reading Telegram digests + opening a Crumb session to process items.

**Morning orientation:** Not yet replacing terminal checks for Ops status — the operator still checks Telegram for mechanic/awareness alerts first, then optionally checks Ops page. Dashboard is additive for Intel, not yet primary for Ops.

**Usage frequency:** At least daily for Intel. Ops page checked when something seems off, not as routine morning view.

## Per-Page Attention Analysis

| Page | Usage Level | Notes |
|------|-------------|-------|
| Intelligence Pipeline | **Primary** | Daily triage. Operator's main interaction surface. 5 UX fixes driven by real usage. |
| Ops | Occasional | Checked when investigating issues, not routine. KPI strip useful for quick status. |
| Attention-lite | Low | Quick-add used a few times. Cards render but the page isn't part of daily routine yet. |
| Knowledge | Not built | Phase 2 |
| Agent Activity | Not built | Phase 3 |
| Customer/Career | Not built | Phase 3 |

## Attention-lite Value Evaluation

The Attention page works mechanically — aggregator pulls from 5 sources, quick-add creates items, cards render with urgency sorting. But the operator reports there's simply not much useful content on it in its current state. Attention-lite is intentionally thin: auto-generated items from system sources (dispatch, vault-check, Healthchecks, FIF health, quick-add). There's no curated content, no daily plan, no relational or personal items. The operator's attention management still runs through Crumb sessions (attention-manager skill) and Telegram alerts.

**Assessment:** Low adoption reflects thin content, not a flawed concept. The page has nothing worth opening for yet. MC-067 (Daily Attention panel) is the real test — rendering the operator's curated daily plan would give the page substance and a daily anchor. If adoption doesn't follow MC-067, then M5 (full schema expansion) is the wrong investment.

## Success Criteria Status

### SC-1: Operator opens dashboard instead of Telegram for morning orientation
**Status: PASS (after retro-driven improvements).** Initial assessment was partial — Ops page wasn't compelling enough for morning checks. Retro session produced improvements (consolidated system status, git gauge with commit activity, fixed timeline baseline, removed duplication) that made the page worth opening daily. Operator confirms: "I'll use it as a status check each morning now, no doubt."

### SC-3: Intelligence Pipeline preferred over Telegram for digest consumption
**Status: PASS.** Parity gate confirmed this. Operator used Pipeline section for 3 consecutive days for signal triage. UX feedback indicates genuine use (you don't file 5 UX issues for a tool you're not using).

### SC-5: No operational blind spots
**Status: PARTIAL.** Dashboard covers: system stats, service status, Healthchecks, FIF pipeline health, LLM health (proxy metrics), vault-check, signal triage. Gaps: per-call LLM telemetry (MC-060 investigation done, no upstream data available), cost burn is FIF-only (no OpenClaw gateway telemetry).

**Assessment:** The blind spots that remain are upstream data availability issues, not dashboard gaps. The dashboard displays everything it can access.

## PC-7: React Component Testing Decision

**Current state:** 6 web tests (all SafeMarkdown). No React component tests for pages or widgets.

**Recommendation: Continue deferring.** Rationale:
- 118 API adapter tests cover the data layer thoroughly — this is where bugs would be costly
- The frontend is a rendering layer over well-tested adapters
- Component testing ceremony (render + assert on DOM) has a poor cost/value ratio for an operator-only dashboard
- The operator IS the test suite — 5 UX issues found in 3 days of use, all fixed immediately
- If the dashboard eventually has other users or grows more complex, revisit

## PC-9: SSE Upgrade Decision

**Recommendation: Stay on polling.** Rationale:
- 30-60s refresh intervals are fine for operational awareness
- No operator complaint about data staleness
- Intel page uses manual pull (not even polling) and that's the primary page
- SSE adds WebSocket infrastructure complexity for no current benefit
- Revisit only if real-time alerting moves to the dashboard (currently Telegram's job)

## What Worked

1. **Spec-first with peer review** — 32 spec amendments and 24 plan amendments caught issues before any code was written. The panel availability matrix (§6.0) prevented building adapters for unavailable data.
2. **Parity gate with operator trial** — forcing 3 days of real usage before passing the gate produced actionable UX feedback that spec review couldn't.
3. **Adapter pattern** — `{data, error, stale}` triple is clean and consistent. 7 Ops adapters + 2 Intel adapters all follow the same contract. Adding new data sources is mechanical.
4. **Speed** — 6 days from project creation to full Phase 1 with 124 tests, production deployment, and operator validation. The design phase (mockups, design system) paid off by eliminating frontend iteration during implementation.

## What Didn't Work

1. **Ops page as morning orientation** — designed to be the first page opened, but Intelligence became the daily driver. The Ops page needs a stronger "glance and go" value proposition, or morning orientation needs to be reconceived.
2. **Attention page adoption** — built but not useful in its current state. Attention-lite's auto-generated items aren't compelling enough to open the page. Needs curated content (MC-067 daily plan) before assessing adoption.
3. **MC-066 (sync-back) still open** — feed-pipeline → dashboard sync-back was deprioritized during the triage action sprint. 19 promote items are queued but won't sync status back to the dashboard until this ships. Low priority but creates a visible gap (promoted items still show as "queued" in the UI).
4. **Test coverage asymmetry** — 118 API tests vs 6 web tests. Acceptable for now (see PC-7) but the gap will grow with Phase 2.

## Remaining Phase 1 Work

| Task | State | Priority | Recommendation |
|------|-------|----------|----------------|
| MC-066 | todo | low | Ship before Phase 2 — it's a small task and resolves the visible "queued forever" gap |
| MC-035 | in-progress | — | This document |

## Phase 2 Scope Assessment

The spec defines Phase 2 as:
- **M5:** Full attention-item schema + expanded vault scanner + aggregator expansion
- **M6:** Knowledge page (QMD, AKM feedback, vault-check, project health, gardening)
- **M7:** Attention status updates (PATCH endpoint + inline UI)

**Should we pause and deepen Phase 1 instead?**

Arguments for pause:
- Intel Pipeline is the primary value driver — deepening it (better filtering, saved searches, trend analysis) could compound more than adding new pages
- Attention page isn't being used — building M5 on top of unused infrastructure is speculative
- Ops page isn't achieving SC-1 — morning orientation may need a different approach

Arguments for Phase 2:
- MC-067 (Daily Attention panel) could be the catalyst that makes the Attention page a daily destination
- Knowledge page (M6) is genuinely new capability — vault gardening and AKM feedback have no current surface
- The adapter pattern is proven — new pages are additive, not risky

**Recommendation: Selective Phase 2.**

1. **MC-066** first (close the sync-back gap)
2. **MC-067** (Daily Attention panel) — test whether a daily anchor makes the Attention page stick, before committing to M5's full schema expansion
3. **M6 (Knowledge page)** — genuinely new value, independent of Attention adoption
4. **M5 (Full attention schema) gated on MC-067 results** — if Daily Attention panel doesn't drive adoption, reconsider M5 scope
5. **M7 (Status updates)** after M5, if M5 proceeds

This reorders Phase 2 to front-load the highest-signal experiment (MC-067) and the highest-value new page (M6), while gating the largest investment (M5) on evidence.

## Decisions (Operator Confirmed 2026-03-12)

- [x] **Phase 2 scope: selective reorder.** MC-066 → MC-067 → M6 → M5 (gated on MC-067) → M7.
- [x] **MC-066: ship now** before starting Phase 2 work.
- [x] **SC-1: PASS** after retro-driven Ops page improvements. No further fix needed.
