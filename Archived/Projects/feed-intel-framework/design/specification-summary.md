---
type: summary
project: feed-intel-framework
domain: software
skill_origin: null
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

# Feed Intelligence Framework — Specification Summary

## Core Content

The Feed Intelligence Framework generalizes x-feed-intel's single-source X/Twitter pipeline into a multi-source content intelligence system supporting 6 adapters: X (existing), YouTube, Reddit, Hacker News, RSS/Blogs, and arxiv. Each platform plugs into shared infrastructure via a standardized adapter contract, with independent per-source daily Telegram digests and a clean lifecycle for adding/removing sources without modifying shared code.

The architecture preserves x-feed-intel's **two-clock model**: a **capture clock** (per-adapter schedules, retries OK) runs extractors and normalizers to accumulate items in a durable SQLite queue, and a single **attention clock** (daily orchestrated run at 07:00) performs triage across all sources sequentially, then a separate delivery scheduler sends per-source digests at staggered times. Error isolation ensures one adapter's triage failure doesn't abort the run — completed sources still produce digests.

Content is normalized to a **unified content format** with source-prefixed `canonical_id` (e.g., `x:123`, `yt:abc`), and triaged through a shared triage engine with per-source prompt preambles. Three **content tiers** (lightweight/standard/heavy) handle varying content types — lightweight for X posts and HN titles, standard for Reddit and arxiv abstracts, heavy for YouTube transcripts with a two-step summarize-then-triage pipeline. The vault router detects cross-source collisions via `url_hash` and merges rather than duplicates.

Cost is managed through per-adapter spending caps, a framework-wide monthly soft ceiling ($15/month), an aggregate daily ceiling ($1.00/day), and heavy-tier-specific throttling. Projected monthly total across all 6 sources: $4.51–$8.41 with 20% headroom.

## Key Decisions

- **Adapter contract:** Manifest (YAML config) + extractor (pull_curated/pull_discovery) + normalizer + triage prompt preamble + topic config. Adding a source requires no shared infrastructure changes.
- **Per-source digests, not combined:** Enables independent evaluation of each source's signal quality and easy add/drop decisions. Each digest has its own delivery time, cadence (daily/weekly), and feedback controls.
- **Migration approach (§8.1):** 5-stage restartable procedure — quiesce pipeline, DB schema migration (id_aliases populated before canonical_id rewrite), cursor state migration, vault file rename + comprehensive wikilink update, verification (8 checks), re-enable. Lockfile guard and full rollback procedure included.
- **Phase 1b split:** 1b.1 is framework extraction + X migration with feature-parity gate. 1b.2 is RSS adapter. No second variable until the first is stable.
- **Research promotion (§5.11):** Hybrid model — research process flags `promotion_candidate: true`, operator confirms via existing `save` command, routes to KB review with `save_reason: "research-promoted"`. No new feedback commands needed.
- **Cross-source dedup:** Explicitly out of scope for Phase 1. Within-source dedup by `canonical_id`; cross-source collision detection by `url_hash` at the vault router level. Phase 3 adds cross-source signal correlation.
- **Adapter health:** >3 consecutive failures in 24 hours triggers degraded state — triage skipped, digest shows status line, one-time Telegram alert. Optional `health_check()` hook for silent failure detection.

## Interfaces & Dependencies

- **x-feed-intel spec (v0.4.1)** — Canonical reference for X adapter; this spec governs the shared layer
- **YouTube Data API v3** — OAuth 2.0 + API key, 10K quota units/day free. Unofficial transcript library for heavy-tier processing (circuit breaker on >80% error rate)
- **Reddit API** — OAuth 2.0 script app. Hard Phase 0 gate on current API terms; RSS feed fallback if blocked
- **Hacker News** — Official API (public) + Algolia HN Search API (public, 10K req/hr)
- **arxiv API** — OAI-PMH + Atom feed, public, 1 req/3s courtesy limit
- **RSS feeds** — feedparser or equivalent, no auth for public feeds
- **SQLite (WAL mode)** — State store with multi-source schema (posts, cost_log, feedback, topic_weights, adapter_runs, adapter_state, digest_messages, id_aliases)
- **Telegram bot** — Per-source notification delivery + reply-based feedback protocol (6 commands: promote, ignore, save, add-topic, expand, investigate)
- **Web UI** — Express API + React SPA + Vite + Tailwind on Mac Studio, Cloudflare Tunnel + Access for external auth. Paper design workflow (§5.12.8) for operator visual review. Split-pane layout, dark mode from day one. Primary reading and feedback surface; Telegram transitions to notification-only with 2-week overlap (§5.12.7). Shared service layer between web UI and Telegram listener (§5.12.3)
- **launchd** — macOS service scheduling for capture clock, attention clock, delivery scheduler, feedback listener, cloudflared daemon
- **Vault directories:** `_openclaw/feeds/` (items, digests, kb-review, research, investigate), `_openclaw/config/operator_priorities.md`
- **Cloudflare** — Tunnel + Access for web UI authentication (~$10/yr domain)

## Next Actions

- **M1 (in progress):** Framework core infrastructure — shared layer extraction
- **M2:** X adapter migration — 5-stage restartable procedure with feature parity gate
- **M3 (parallel with M-Web after M2):** RSS adapter — validates adapter contract
- **M-Web (parallel with M3 after M2):** Web presentation layer — primary digest surface, feedback actions, cost dashboard, investigate action skeleton
- **M4:** YouTube adapter — heavy-tier content system validation
- **M5:** HN, Reddit, arxiv — incremental, order by expected signal value
- **Deferred items from peer review:** FK consistency stance, environment config management, run-level token budgets, `source_instances` queryability, vault router tier-aware promotion
