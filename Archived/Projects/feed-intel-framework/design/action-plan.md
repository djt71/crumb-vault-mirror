---
type: action-plan
project: feed-intel-framework
domain: software
skill_origin: action-architect
status: draft
created: 2026-02-23
updated: 2026-02-25
tags:
  - openclaw
  - tess
  - automation
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Feed Intelligence Framework — Action Plan

## Overview

This action plan decomposes spec v0.3.5 into implementation milestones covering
Phase 1b.1 through Phase 1d, plus M-Web (web presentation layer). Phases 0 and
1a are complete (delivered by x-feed-intel, 32 tasks, in soak). Phases 2-3 are
deferred with milestone placeholders only.

**Boundary:** Spec and plan live in the Crumb vault. Implementation happens in
the Tess codebase (outside vault). Config, state artifacts, and routed items
are vault-resident per §10 boundary compliance.

**Implementation language:** Determined by x-feed-intel Phase 0 resolution
(§7.1 of x-feed-intel spec) — carries to the framework.

---

## Completed Prior Work

- **Phase 0 (x-feed-intel):** Design validation complete. Language selected.
  Framework assumptions validated against live X data.
- **Phase 1a (x-feed-intel):** X adapter core pipeline fully implemented (32
  tasks). Capture, triage, digest, feedback, vault routing all operational.
  Soak period passing.

---

## M1: Framework Core Infrastructure

**Spec reference:** §4 (architecture), §5 (shared infrastructure), §6 (adapter contract)
**Phase mapping:** Phase 1b.1 — shared layer extraction
**Task range:** FIF-001 through FIF-018

### Success Criteria

1. Framework project structure exists with all shared infrastructure modules
2. Schema initialization module creates all required tables in a clean SQLite database
3. Adapter manifest loader validates and rejects malformed manifests
4. Capture clock runs enabled adapters on configured schedules with configuration snapshot
5. Triage engine processes lightweight and standard tier batches with source-specific preambles
6. Vault router writes files with canonical_id naming and detects url_hash collisions
7. Digest renderer produces per-source messages with auto-split and cadence support
8. Feedback protocol operates on multi-source data with source-scoped weight adjustments
9. Cost telemetry tracks per-adapter and aggregate costs; guardrails activate at thresholds
10. Shared alert function used by all notification-emitting components
11. All components testable with mock adapters before any real adapter is connected

### Key Risks

| Risk | Level | Mitigation |
|---|---|---|
| Premature abstraction | Medium | Extract from working X code, not greenfield design |
| Triage engine regression vs x-feed-intel | Medium | Feature parity tests in M2 gate |
| Over-engineering adapter contract | Low | RSS (M3) validates contract simplicity |
| WAL performance under multi-source writes | Medium | Benchmark during M2 integration test |
| Shared dependency conflicts during extraction (launchd plist, Telegram bot) | Medium | Isolate in WP-1 scaffolding |

### Work Packages

**WP-1: Scaffolding and data layer** (FIF-001 through FIF-004)
Project structure, schema initialization, content format types, URL canonicalization,
adapter state persistence, dedup store. Foundation that all other work packages build on.

**WP-2: Adapter management** (FIF-005 through FIF-007)
Manifest loader/validator, capture clock orchestrator, adapter lifecycle
management. Controls how adapters are discovered, scheduled, and managed.

**WP-3: Triage pipeline** (FIF-008 through FIF-010)
Triage engine (lightweight + standard tiers), deferred retry logic, vault
snapshot generator. The core intelligence path — items go in, triage decisions
come out. Heavy tier deferred to M4 (YouTube).

**WP-4: Output pipeline** (FIF-011 through FIF-014)
Vault router with collision detection, per-source digest renderer, delivery
scheduler, reply-based feedback protocol. Everything downstream of triage.

**WP-5: Observability** (FIF-015 through FIF-017)
Cost telemetry with weekly aggregate summary, spending caps, framework-wide
guardrails (monthly + daily ceilings), queue health monitoring, adapter degraded
state, shared alert function.

**WP-6: Cross-cutting** (FIF-018)
Research promotion path — framework-level concern touching feedback protocol
and vault routing.

---

## M2: X Adapter Migration

**Spec reference:** §8.1 (migration plan), §6 (adapter contract), §13 (Phase 1b.1)
**Phase mapping:** Phase 1b.1 — migration + feature parity
**Task range:** FIF-019 through FIF-029
**Depends on:** M1 complete

### Success Criteria

1. Migration lockfile guard deployed and tested in pipeline startup code
2. Staging migration environment validated against live data (row/file count parity)
3. X pipeline refactored to framework adapter contract (manifest + extractor + normalizer + preamble)
4. Migration scripts execute all 5 stages with idempotency guards and restartability
5. Verification suite independently validates all 8 migration checks
6. Rollback procedure tested and documented (backup restore primary, surgical reversal alternative)
7. X adapter runs on framework infrastructure with feature parity to legacy pipeline
8. Feature parity gate passes: capture frequency, triage quality (≥90% match on 50 items), digest count ±10%, all feedback commands, cost within 10% of baseline

### Key Risks

| Risk | Level | Mitigation |
|---|---|---|
| Migration data loss | High | Full backup + rollback procedure + staging test |
| Wikilink breakage (vault files) | High | Comprehensive regex (6 variants) + verification scan |
| Alias ordering bug (id_aliases before rewrite) | High | Addressed in spec v0.3.3; test on staging copy first |
| Feature parity regression | Medium | 3-day parallel comparison; binary pass/fail gate |

### Work Packages

**WP-7: Pre-migration** (FIF-019 through FIF-021)
Migration lockfile guard in pipeline code. Staging migration environment for
development and testing. X pipeline refactored as framework adapter. All must
be complete before migration scripts run.

**WP-8: Migration scripts** (FIF-022 through FIF-026)
Five-part migration implementation: DB schema + cursor state (Stages 1-2),
vault files + wikilinks (Stage 3), verification suite (Stage 4), orchestrator +
re-enable (Stage 5), rollback procedure. Developed and tested against staging
environment (FIF-020).

**WP-9: Validation** (FIF-027 through FIF-029)
Integration test on framework, live migration execution, feature parity gate.
The gate is binary: pass → proceed to M3, fail → fix and re-gate.

---

## M-Web: Web Presentation Layer (parallel with M3/M4)

**Spec reference:** §5.12 (Web Presentation Layer), §5.12.8 (Design Workflow), §5.13 (Investigate Action)
**Phase mapping:** M-Web — parallel track after M2
**Task range:** FIF-W01 through FIF-W12
**Depends on:** M2 feature parity gate (FIF-029) passed (for API server data access). Does NOT depend on M3 — web UI is multi-source by design, renders whatever adapters are enabled. M-Web and M3 can proceed in parallel. FIF-W01 (Paper design sprint) has no M2 dependency and can start anytime.

### Success Criteria

1. Cloudflare Tunnel + Access authentication working from external browser
2. Web UI renders daily digest with split-pane layout and per-item feedback actions
3. All feedback commands (promote, ignore, save, add-topic, investigate, expand) functional via web UI
4. Dark mode validated across all views (digest, cost dashboard, app shell)
5. Telegram transitions to notification-only with 2-week overlap, then cutover
6. Operator uses web UI as primary digest surface for 5 consecutive days
7. Investigate action stages requests and Tess sweep skeleton processes them
8. Telegram feedback listener uses shared service layer (no duplicate write paths)
9. Web UI test suite passes (components + API routes) via `npm test`

### Key Risks

| Risk | Level | Mitigation |
|---|---|---|
| Paper instability blocks design sprint | Low | Fall back to designing in code; Paper is reference only, not runtime |
| Cloudflare Tunnel setup issues | Medium | Tailscale documented as fallback (Option B in proposal) |
| Investigate action crosses 3 execution contexts | Medium | Start with skeleton; Tess sweep depends on crumb-tess-bridge |
| Dual write paths (web + Telegram) cause data inconsistency | Medium | FIF-W11 consolidates to shared service layer before gate |

### Work Packages

**WP-Web-1: Design** (FIF-W01)
Paper design sprint: design system establishment, component library, dark mode variants,
mobile breakpoints, design token documentation. Operator review gate before implementation.

**WP-Web-2: Core platform** (FIF-W02, FIF-W03, FIF-W07, FIF-W12)
Express API server with all routes and services layer. React app scaffold with Vite,
routing, theme system (dark mode from day one). Cloudflare Tunnel + Access setup.
Web UI test suite infrastructure.

**WP-Web-3: Feature views** (FIF-W04, FIF-W05, FIF-W06, FIF-W09, FIF-W10)
Digest view with split-pane layout and loading/error states. All feedback actions with
immediate UI updates. Cost dashboard. Investigate action UI + staging. Dark mode validation.

**WP-Web-4: Integration** (FIF-W08, FIF-W11)
Telegram notification transition (2-week overlap). Telegram feedback listener refactoring
to shared service layer.

### Dependency Graph

```
FIF-W01 (Paper design) ──→ FIF-W03 (React scaffold)
                                  │
                    ┌─────────────┤
                    ▼             ▼
              FIF-W04        FIF-W06
            (digest view)   (cost dashboard)
                 │                │
                 ▼                │
            FIF-W05               │
          (feedback actions)      │
              │    │              │
              ▼    ▼              ▼
         FIF-W08  FIF-W09    FIF-W10
        (Telegram) (investigate) (dark mode validation)
              │
              ▼
         FIF-W11
       (listener refactor)

   FIF-W02 (Express API) ──→ FIF-W04, FIF-W06, FIF-W07, FIF-W11, FIF-W12
   FIF-W07 (Cloudflare) depends on FIF-W02 only
   FIF-W12 (test suite) depends on FIF-W02, FIF-W03
```

**Notes:**
- FIF-W01 (Paper design sprint) has no code or M2 dependencies — can start immediately.
- FIF-W02 (Express API) depends on M2 for data access but has no design dependency.
- FIF-W07 (Cloudflare) is infrastructure prep — can proceed as soon as the Express server exists.
- `services/feedback.ts` is the architectural junction point shared by web API and Telegram listener. Interface-first design before building consumers.

---

## M3: RSS Adapter

**Spec reference:** §7.5 (RSS spec), §6 (adapter contract), §13 (Phase 1b.2)
**Phase mapping:** Phase 1b.2 — adapter contract validation
**Task range:** FIF-030 through FIF-033
**Depends on:** M2 feature parity gate (FIF-029) passed for integration test and enable; RSS Phase 0 (FIF-030) can start after FIF-005 (manifest loader)

### Success Criteria

1. RSS adapter plugs into framework without any modifications to shared infrastructure code (§14 criterion 1)
2. RSS adapter delivers daily digests from curated feeds
3. Cross-source collision detection works when RSS and X share a URL
4. Weekly aggregate cost summary covers both X and RSS with per-adapter signal quality scores
5. Cost within estimate ($0.20–$0.50/month for RSS)

### Key Risks

| Risk | Level | Mitigation |
|---|---|---|
| Adapter contract too rigid | Low | RSS is simplest adapter — if it doesn't fit cleanly, contract needs revision |
| Feed quality varies | Low | Curated feed list; easy to add/drop feeds |

---

## M4: YouTube Adapter

**Spec reference:** §7.2 (YouTube spec), §5.3.1 (heavy tier), §13 (Phase 1c)
**Phase mapping:** Phase 1c — heavy-tier content system validation
**Task range:** FIF-034 through FIF-038
**Depends on:** M3 complete (framework proven with 2 adapters before adding complexity)

### Success Criteria

1. YouTube Phase 0 documents transcript availability rate and API quota usage
2. Heavy-tier triage engine (summarize-then-triage) processes YouTube transcripts
3. Circuit breaker activates when transcript error rate exceeds 80% for 3 consecutive runs
4. YouTube digest delivers with cost breakdown showing summarize/triage split
5. Cost within estimate ($0.85–$1.60/month for YouTube)

### Key Risks

| Risk | Level | Mitigation |
|---|---|---|
| Transcript library breakage | Medium | Circuit breaker + lightweight fallback |
| YouTube API quota exhaustion | Medium | Phase 0 quantification; conservative defaults |
| Heavy-tier LLM cost spikes | Medium | Per-item token cap + spending cap + daily ceiling |

---

## M5: Remaining Adapters

**Spec reference:** §7.3 (Reddit), §7.4 (HN), §7.6 (arxiv), §13 (Phase 1d)
**Phase mapping:** Phase 1d — incremental adapter rollout
**Task range:** FIF-039 through FIF-043
**Depends on:** M2 feature parity gate (FIF-029) passed; M3 recommended (contract proven). All M5 tasks transitively require M1 infrastructure via the M1 → M2 chain.

### Success Criteria

1. Each adapter plugs in without shared infrastructure changes
2. Each adapter delivers digests at configured cadence
3. Per-adapter costs within estimates
4. Framework-wide monthly cost stays under $15 ceiling (§14 criterion 5)
5. Danny can independently evaluate each source's signal quality (§14 criterion 6)

### Key Risks

| Risk | Level | Mitigation |
|---|---|---|
| Reddit API terms block implementation | Medium | Hard Phase 0 gate; RSS feed fallback documented |
| Adapter proliferation overwhelms digest attention | Medium | Start with 2-3; per-source digests make drop decisions easy |
| HN Algolia API rate limiting | Low | Courtesy limit compliance; lightweight tier keeps costs low |

### Adapter Order

Per spec §13: order by expected signal value, operator's call. Suggested:
1. **HN** — high signal, public API, lightweight tier, no auth complexity
2. **Reddit** — high signal but API uncertainty (Phase 0 gate required)
3. **arxiv** — specialized signal, public API, standard tier

---

## M6: Per-Source Enrichment (Phase 2 — Deferred)

**Spec reference:** §13 (Phase 2)

Not decomposed into tasks. Scope includes:
- Thread/series expansion (X threads, YouTube playlists, Reddit comment trees)
- Linked content fetch (HN → article, Reddit link posts → article)
- Account/channel monitoring
- Historical trend analysis (cross-source weekly report)
- Triage refinement from accumulated feedback
- Semantic Scholar citation counts for arxiv
- Digest grouping for mature low-volume sources

**Activation signal:** M5 complete + 4 weeks operational data across 3+ adapters.

---

## M7: Learning Loop (Phase 3 — Deferred)

**Spec reference:** §13 (Phase 3)

Not decomposed into tasks. Scope includes:
- Per-source, per-topic weight adjustment
- Cross-source signal correlation (trending across multiple platforms)
- Automated source quality scoring (promotes vs. ignores ratio)
- Topic suggestion based on discovery patterns

**Activation signal:** Phase 2 enrichment features stable + sufficient feedback
volume (100+ feedback interactions per adapter).

---

## M-Manual: Manual Intake Adapter (Deferred)

**Design reference:** `design/manual-intake-adapter-decision.md`

Not decomposed into tasks. Scope includes:
- Tess as capture surface (URL paste or `/intake <url>` command via Telegram)
- Normalization to unified content format with `source_type: manual`, `canonical_id: manual:sha256[:16]`
- Lightweight or skipped triage (operator-curated = high relevance)
- Standard vault router with `feed-intel-manual-{id}.md` naming
- Digest inclusion or immediate confirmation (TBD)

**Open questions:** Immediate confirmation vs. silent digest; annotation syntax (free-form vs. structured); attention clock bypass vs. batch processing.

**Activation signal:** M2 feature parity gate passed + adapter contract proven by at least one non-X adapter (M3 or M4).
