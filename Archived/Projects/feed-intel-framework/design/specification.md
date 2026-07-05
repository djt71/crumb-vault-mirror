---
type: specification
skill_origin: systems-analyst
project: feed-intel-framework
domain: software
created: 2026-02-21
updated: 2026-02-25
version: 0.3.5
tags:
  - openclaw
  - tess
  - automation
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Feed Intelligence Framework — Project Specification

## 1. Problem Statement

Danny consumes content across multiple platforms — X, YouTube, Reddit, Hacker News, RSS feeds, and arxiv — related to agent architecture, agentic coding, PKM, and AI-assisted workflows. Each platform has its own bookmarking/saving mechanism, its own discovery surface, and its own signal-to-noise profile. Without a unified pipeline, content accumulates unreviewed, cross-platform signal is invisible, and triage effort is duplicated manually across sources.

The X Feed Intelligence Pipeline (x-feed-intel, v0.4.1) solved this for a single source. This spec generalizes that architecture into a multi-source framework where each platform is an adapter plugged into shared infrastructure, with independent digests per source and a clean lifecycle for adding and removing sources over time.

## 2. Objective

Build a feed intelligence framework that:

1. **Defines shared infrastructure** for content capture, normalization, dedup, triage, digest delivery, feedback, and cost tracking — source-agnostic by design
2. **Specifies an adapter contract** that any content source must implement to plug into the framework
3. **Ships source adapters** for X (existing), YouTube, Reddit, Hacker News, RSS/Blogs, and arxiv
4. **Delivers per-source daily digests** to Telegram, each with independent feedback controls
5. **Routes actionable items** into the vault via the same Crumb inbox convention
6. **Supports adapter lifecycle** — adding a new source or retiring an old one requires no changes to the shared infrastructure

## 3. Relationship to x-feed-intel

The x-feed-intel spec (v0.4.1) remains the canonical reference for the X adapter. This spec does not rewrite or supersede it. Instead:

- **Shared infrastructure** described here is extracted from x-feed-intel's architecture. Where this spec and x-feed-intel overlap, this spec is the governing document for the shared layer; x-feed-intel remains authoritative for X-specific behavior.
- **The X adapter** is the first implementation. Its existing spec covers capture, normalization, triage prompt, cost model, and phasing in full detail. Other adapters reference the same patterns but define their own source-specific behavior.
- **Migration path:** x-feed-intel Phase 1 can proceed as-is. The shared infrastructure refactor happens when the second adapter (likely RSS) is ready for implementation. At that point, the X pipeline's components are extracted into the shared layer and the X-specific parts become the X adapter. This avoids premature abstraction. See §8.1 for the detailed migration plan.

## 4. Architecture Overview

The framework preserves the two-clock architecture from x-feed-intel, generalized for N sources.

```
                    ┌──────────────────────────────────────────┐
                    │            CAPTURE CLOCK                  │
                    │  (per-adapter schedule, retries OK)       │
                    └──────────────────┬───────────────────────┘
                                       │
         ┌─────────┬─────────┬─────────┼─────────┬─────────┐
         ▼         ▼         ▼         ▼         ▼         ▼
    ┌─────────┐┌────────┐┌────────┐┌────────┐┌───────┐┌────────┐
    │ X       ││YouTube ││Reddit  ││HN      ││RSS    ││arxiv   │
    │ Adapter ││Adapter ││Adapter ││Adapter ││Adapter││Adapter │
    └────┬────┘└───┬────┘└───┬────┘└───┬────┘└──┬────┘└───┬────┘
         │         │         │         │        │         │
         ▼         ▼         ▼         ▼        ▼         ▼
    ┌──────────────────────────────────────────────────────────┐
    │                    Normalizer                             │
    │  Per-adapter normalization → unified content format       │
    └────────────────────────────┬─────────────────────────────┘
                                 │
                                 ▼
    ┌──────────────────────────────────────────────────────────┐
    │                   Dedup Store                             │
    │  Within-source dedup via source_type:canonical_id         │
    └────────────────────────────┬─────────────────────────────┘
                                 │
                                 ▼
                      ┌────────────────────┐
                      │   Durable Queue     │
                      │   (pending items)   │
                      └──────────┬─────────┘
                                 │
                    ┌────────────┴─────────────────────────────┐
                    │           ATTENTION CLOCK                  │
                    │  (single orchestrated run at digest time)  │
                    └────────────┬─────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
          ┌──────────────────┐    ┌────────────────────┐
          │  Triage Engine   │    │  Cost Telemetry     │
          │  (per-source     │    │  (per-adapter +     │
          │   prompt tuning) │    │   aggregate)        │
          └────────┬─────────┘    └─────────┬──────────┘
                   │                        │
            ┌──────┴───────┐                │
            ▼              ▼                │
  ┌───────────────┐ ┌──────────────┐        │
  │ Per-Source     │ │ Vault Router │        │
  │ Digests       │ │ (actionable, │        │
  │ (Telegram)    │ │  URL-aware)  │        │
  └───────┬───────┘ └──────────────┘        │
          │                                 │
          ▼                                 ▼
  ┌──────────────────────────────────────────────┐
  │  Each digest: items + source cost stats +     │
  │  reply-based feedback protocol                │
  └──────────────────────────────────────────────┘
```

### 4.1 Attention Clock Execution Model

The attention clock is a **single orchestrated run**, not independent per-source jobs. It operates in two phases: **triage** then **delivery**.

**Phase 1 — Triage** (runs at a fixed time, default 07:00 local):

1. Generate one vault snapshot (shared across all sources)
2. For each enabled source with pending items (round-robin order, per §5.9):
   a. Read pending items from queue for this source
   b. Run triage (source-specific preamble + shared prompt)
   c. Route qualifying items to vault
   **Error isolation:** Each source's triage is wrapped in error isolation. A crash or exception in one source's triage logs the failure to `adapter_runs` (status: `failed`) and proceeds to the next source. Completed sources still produce digests; failed sources are skipped for that day.
3. Compute per-source and aggregate cost telemetry
4. Render per-source digests (but do not send yet)

**Phase 2 — Delivery** (a separate scheduled event, not part of the triage script):

5. A delivery scheduler (separate launchd service or equivalent) sends each rendered digest at its configured `digest.time` (e.g., X at 8:00, RSS at 8:05, YouTube at 8:10). The scheduler checks for rendered digests and sends those whose `digest.time` has arrived. This decoupling prevents long-lived idle scripts between triage completion and delivery.

**Timing constraint:** All configured `digest.time` values MUST be ≥ triage start time + `triage_run_budget_minutes` (configurable, default 45). The manifest loader validates this constraint at startup; manifests with invalid `digest.time` values are rejected with an error. If triage overruns the budget, the delivery scheduler sends digests immediately upon availability, ordered by `digest.time` (primary) then adapter `id` (secondary), each marked "⏱ Late — triage overran budget" in the footer.

**Important:** `digest.time` is a *delivery timestamp for already-triaged items in that day's run*, not a triage trigger. There is exactly one attention clock run per day.

This ensures snapshot consistency (one generation, consumed by all), prevents race conditions between triage runs, and keeps scheduling simple.

**Configuration snapshot rule:** Adapter manifests are loaded once at the start of each capture clock and attention clock cycle. Enable/disable changes and manifest modifications take effect at the next cycle boundary. Running cycles use the configuration snapshot from cycle start; mid-cycle changes are ignored until the next run.

## 5. Shared Infrastructure

These components are source-agnostic. They operate on the unified content format and don't know or care which adapter produced the data.

### 5.1 Unified Content Format

The normalized format from x-feed-intel, generalized to support content of varying lengths and types.

**Canonical ID invariant:** The `canonical_id` prefix MUST equal the adapter's `id` field from its manifest. This is enforced by the normalizer contract (§6.3). Short, stable prefixes are used: `x`, `yt`, `reddit`, `hn`, `rss`, `arxiv`.

```json
{
  "canonical_id": "x:1234567890",
  "source_type": "x",
  "source_instances": [
    {
      "source": "bookmark",
      "fetched_at": "2026-02-21T14:00:00Z",
      "search_query": null
    },
    {
      "source": "search",
      "fetched_at": "2026-02-21T14:05:00Z",
      "search_query": "agentic coding"
    }
  ],
  "first_seen_at": "2026-02-21T14:00:00Z",
  "last_seen_at": "2026-02-21T14:05:00Z",
  "author": {
    "username": "handle_or_channel",
    "display_name": "Name",
    "follower_count": 12345
  },
  "content": {
    "title": null,
    "excerpt": "First 280 chars or adapter-defined summary...",
    "full_text": null,
    "content_type": "short_text | long_text | video | paper | link",
    "effective_tier": null,
    "urls": ["https://..."],
    "url_hash": null,
    "media": [],
    "duration_seconds": null,
    "needs_context": false,
    "context_hint": null
  },
  "metadata": {
    "created_at": "2026-02-21T10:30:00Z",
    "engagement": {
      "likes": 150,
      "comments": 18,
      "shares": 42,
      "saves": 30,
      "views": null
    },
    "matched_topics": ["agent-architecture"],
    "platform_url": "https://...",
    "platform_specific": {}
  }
}
```

**Changes from v0.1:**

- `canonical_id` examples now use short prefixes consistently: `x:`, `yt:`, `hn:`, `rss:`, `reddit:`, `arxiv:`.
- `content.effective_tier` — new field. Set by the normalizer to override the adapter manifest's default `content_tier` on a per-item basis. When `null`, the adapter's manifest tier is used. When set (e.g., `"lightweight"` for a YouTube video with no transcript), the triage engine uses this tier instead. See §5.3.1. **Invariant:** `effective_tier` determines the triage processing path (which tier strategy is used) and may influence `content.excerpt` generation for heavy-tier items where a summary replaces the mechanical excerpt (§5.3.1). It must not alter `canonical_id` or other core identity/normalization fields.
- `content.url_hash` — new field. SHA256 hash (first 16 chars) of the primary content URL after canonicalization using the framework-provided `canonicalize_url()` helper (§6.3). Used by the vault router for cross-source collision detection (§5.5). Populated by the normalizer for all items with a content URL. `null` only if no URL is available. **URL-first principle:** For items whose primary purpose is sharing an external link (e.g., an X post sharing a blog article, an HN link story, a Reddit link post), `url_hash` MUST be derived from the external content URL, not the platform permalink. The platform permalink is preserved in `metadata.platform_url`. This is what enables cross-source collision detection for the most common case — the same article shared across multiple platforms.
- `source_instances[].search_query` — required for discovery-sourced items. Must be populated with the query string that matched this item. `null` only for curated/subscription sources. This enables per-query feedback analysis.
- `metadata.platform_specific` — new field. An opaque JSON object for adapter-specific metadata that doesn't map to the unified schema (e.g., YouTube channel subscriber count, Reddit subreddit name, HN story domain). The framework ignores this field; triage preambles and adapter-specific tools may reference it.

**Inherited from v0.1 (unchanged):** `content.title`, `content.excerpt`, `content.full_text`, `content.content_type`, `content.duration_seconds`, `content.needs_context`, `content.context_hint`, `metadata.engagement` field mappings, `metadata.platform_url`, `metadata.matched_topics`.

### 5.2 Dedup Store

Maintains a rolling manifest of processed `canonical_id` values via the `posts` table.

**Dedup scope is within-source only.** The `canonical_id` format (`source_type:native_id`) is unique by construction — two items from different sources will never collide on `canonical_id`. The same content URL shared on X and Reddit produces two distinct `canonical_id` values (e.g., `x:123` and `reddit:456`) and is triaged independently. This is intentional: engagement context and discovery paths differ across platforms, making independent triage the correct default.

**Within-source dedup merge:** When an item with an existing `canonical_id` is captured again (e.g., via both bookmark and search within the same adapter), the existing record is updated: the new capture is appended to `source_instances`, `last_seen_at` is updated, and engagement metrics are refreshed. The triage engine sees the merged item with all instance metadata. No duplicate `posts` row is created.

**Cross-source dedup is explicitly out of scope for Phase 1.** Duplicates across sources are treated as distinct items. Cross-source correlation (using `url_hash` to detect when the same content is trending across multiple platforms) is a Phase 3 signal amplification feature, not a dedup mechanism. See §5.5 for how the vault router handles cross-source collisions at the routing level.

**`matched_topics` behavior:** Append-only across runs, as in x-feed-intel. Same rules apply.

### 5.3 Triage Engine

The triage engine is shared but source-aware. It uses a common triage output schema (identical to x-feed-intel §5.5.1) with per-source prompt tuning.

**How source-awareness works:**

1. The triage engine receives a batch of items, all from the same source (batches are never mixed across sources).
2. The system prompt includes a **source-specific scoring preamble** that adjusts assessment criteria for the content type. For example, YouTube triage weights transcript substance and production quality; HN triage weights the linked article's domain and comment quality signal.
3. The vault snapshot is shared across all sources — triage context (active projects, focus tags, operator priorities) is the same regardless of where content was discovered.
4. The output schema is identical for all sources. Downstream components (digest, vault router, feedback) don't need to know the source to process triage results.

**Source-specific prompt preambles** are defined in each adapter spec (§7). The shared triage engine loads the appropriate preamble based on `source_type` before constructing the full prompt.

**Triage output schema:** Identical to x-feed-intel §5.5.1. No changes.

**Tag definitions:** Same tag set across all sources. `crumb-architecture`, `architecture-inspiration`, `tess-operations`, `tool-discovery`, `pattern-insight`, `community-signal`, `general-interest`. These are domain tags, not source tags — a YouTube video about vault architecture gets tagged `crumb-architecture` just like an X post would. Source identity is already captured in `source_type`.

**Triage API contract (for preamble authors):** The triage engine constructs each prompt as: system prompt (shared scoring guidance + vault snapshot + source-specific preamble) + user prompt (batch of items). Each item in the batch includes: `canonical_id`, `content.title` (if present), `content.excerpt` (always present), `content.full_text` (if effective tier is standard or higher and content is available), `content.content_type`, `content.duration_seconds` (if present), `content.needs_context`, `content.context_hint` (if present), `metadata.engagement` (all available fields), and `metadata.platform_url`. Preamble authors can assume these fields are present and should calibrate their scoring guidance accordingly. The output must conform to x-feed-intel §5.5.1 triage output schema.

#### 5.3.1 Content Tiers and Triage Strategy

Different content types require different triage strategies and have different cost profiles. The framework defines three tiers:

| Tier | Content Type | Triage Input | LLM Cost Profile | Examples |
|---|---|---|---|---|
| **Lightweight** | Short text, titles + metadata | `excerpt` only | Low (~X baseline) | X posts, HN titles, RSS titles |
| **Standard** | Medium text with full body available | `excerpt` + `full_text` (bounded) | Medium (2-5× lightweight) | Reddit posts, blog entries, arxiv abstracts |
| **Heavy** | Long-form content requiring preprocessing | Summarize-then-triage two-step | High (10-20× lightweight) | YouTube transcripts, full papers, long blog posts |

**Tier resolution order:** The triage engine determines the tier for each item as follows:
1. If `content.effective_tier` is set (non-null), use it. This is the per-item override set by the normalizer.
2. Otherwise, use the adapter manifest's `content_tier` value.

This allows adapters to declare a default tier (e.g., YouTube = heavy) while falling back per-item when content is unavailable (e.g., no transcript → effective_tier = lightweight).

**Lightweight tier:** Triage operates on `excerpt` alone. This is the x-feed-intel baseline — ~4,300 input tokens per batch.

**Standard tier:** Triage operates on `excerpt` + `full_text`, but `full_text` is bounded per item (configurable via manifest `triage.full_text_token_limit`, default 2,000 tokens). If `full_text` exceeds the bound, it is mechanically truncated. Batch sizes are smaller (5-10 items) to stay within reasonable token budgets.

**Heavy tier:** A two-step process. Step 1: summarize the full content into a bounded summary using the same LLM. The summary prompt should extract **key technical claims, tools mentioned, and actionable patterns** rather than producing a generic summary — this provides better signal for the Step 2 triage. Step 2: triage on the summary using the standard triage prompt. This adds one LLM call per item but keeps triage token budgets predictable. The summary is stored in `content.excerpt` (overwriting the mechanical truncation) and persisted for digest display.

**Pre-summarization truncation:** For heavy-tier items, `full_text` is truncated to `triage.full_text_token_limit` (default 8,000 tokens) before the summarize step. This prevents a single long item (e.g., a 3-hour conference talk transcript at 30K+ tokens) from blowing the per-item LLM budget. If chapter markers or section headings are detectable in the content, the truncation preserves them to maintain structural signal.

**Per-item token cap:** If any individual item in a triage batch would exceed 12,000 input tokens after tier-appropriate processing, it is skipped from the batch, marked `queue_status = 'triage_deferred'` in the state store, and retried in the next attention clock run.

**Deferred item retry semantics:**
- Deferred items are retried in the *next* attention clock run (not within the same run), either individually or in a small batch of similarly deferred items, with more aggressive truncation.
- Deferred retries count against the source's `max_items_per_cycle`.
- If a summary was already generated and stored in `content.excerpt` during a prior attempt, the summarize step is skipped on retry (avoids duplicate LLM cost). Only the triage step is re-executed.
- A `triage_attempts` counter is tracked per item (in `posts.triage_json`). After **3** failed deferred attempts, the item is force-triaged at lightweight tier (excerpt only, ignoring `effective_tier`). If lightweight triage also fails, the item is marked `queue_status = 'triage_failed'` with reason "token cap exceeded after 3 retries" and is not retried.

**Cost telemetry for heavy tier:** The summarize step and the triage step are logged as separate `subcomponent` entries in `cost_log` (e.g., `subcomponent: "summarize"` and `subcomponent: "triage"`), enabling visibility into the cost split.

### 5.4 Vault Snapshot

Identical to x-feed-intel §5.5.0. One snapshot, shared across all source triage runs. Generated once at the start of the attention clock run (step 1 in §4.1), consumed by all per-source triage batches.

No changes to format, token budget, refresh cadence, input fallback rules, or failure mode.

### 5.5 Vault Router

Same routing logic as x-feed-intel §5.6. The routing bar, idempotency rules, and file format are unchanged. Routed files use the composite `canonical_id` in the filename: `feed-intel-{source_type}-{native_id}.md`. This prevents filename collisions across sources.

**Cross-source collision detection:** Before writing a new file, the vault router checks the `url_hash` of the item being routed against existing routed items. The lookup query is: `SELECT canonical_id, source_type FROM posts WHERE url_hash = ? AND routed_at IS NOT NULL ORDER BY routed_at ASC LIMIT 1`. The `ORDER BY routed_at ASC LIMIT 1` ensures deterministic resolution when multiple rows match (e.g., same URL routed from multiple sources over time). If a match with a different `source_type` exists:
- The existing file is preserved (first-to-route wins). The existing file's path is derived from the matched `canonical_id` using the naming convention `feed-intel-{source_type}-{native_id}.md`.
- The new source's triage data is appended to the existing file as an additional discovery note below the triage section: `## Also discovered via {source_type} ({date})` with the new triage assessment and link. The existing file's frontmatter gains an `additional_sources` list if not already present (e.g., `additional_sources: [rss]`).
- **The appending item's `routed_at` is also set** in the `posts` table (`routed_at = CURRENT_TIMESTAMP`). This maintains the invariant that `routed_at IS NOT NULL` for any item that has been routed to a primary or appended position, preventing a third source from missing the collision.
- The digest for the new source includes the item normally but notes: "Also routed via {other_source} digest on {date}."

**Current-run collision tracking:** Collision detection includes items routed earlier in the current attention clock run. The router must check both persisted state and items routed during the current run (via write-through to the `routed_at` column or in-memory tracking).

This prevents duplicate vault files for the same underlying content while preserving per-source triage decisions. The `url_hash` is the key; items without URLs (rare) are not subject to collision detection.

**Known Phase 1 simplification:** The "first-to-route wins" rule means a low-quality triage (e.g., lightweight X post) may occupy the primary position while a higher-quality triage (e.g., heavy-tier RSS blog) lands in the append section. This is accepted for Phase 1 — the append note surfaces the better triage. If this proves problematic in practice, tier-aware promotion logic (where a higher-tier triage replaces the primary position) can be added in Phase 2.

**Governance invariant:** Unchanged. Vault schema changes require a Crumb-governed spec update regardless of which adapter triggers them.

### 5.6 Per-Source Digests

Each source gets its own daily Telegram digest. The digest format is structurally identical to x-feed-intel §5.7, with the source name in the header:

```
📡 YouTube Intel — Feb 21, 2026
━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 HIGH PRIORITY (2)
...
```

**Why per-source, not combined:** The goal is to evaluate which sources are valuable over time. A combined digest obscures per-source signal quality and makes it harder to decide when to drop or add a source. Per-source digests also keep individual digest size manageable.

**Telegram message limits:** Telegram messages are capped at 4,096 characters. The digest renderer auto-splits messages that exceed this limit, sending continuation messages with "... continued (2/3)" headers. Multi-part messages are sent **synchronously** per adapter with a small delay (500ms) between parts to guarantee correct chronological order in the Telegram thread. The existing `MAX_ITEMS_INLINE` overflow to a vault-stored digest file (from x-feed-intel §5.7) also applies.

**Digest scheduling:** Digests are rendered during the triage phase of the attention clock run and delivered by the delivery scheduler at their configured `digest.time` values (see §4.1). Default: staggered across the morning (e.g., X at 8:00, RSS at 8:05, YouTube at 8:10). All triage completes before any digest is sent. Configurable per adapter via manifest `digest.time`.

**Digest cadence:** Each adapter can configure `digest.cadence` as `daily` or `weekly` in its manifest. An additional `digest.min_items` field (default: 1) allows suppressing digests below a threshold — useful for low-volume sources like arxiv where daily empty-day messages add noise. When `send_empty: false` (default) and no items meet the threshold, no digest is sent.

**Weekly digest accumulation:** Triage runs daily regardless of digest cadence — items are triaged on discovery. For weekly-cadence adapters, the framework maintains a `last_digest_cutoff_at` timestamp per adapter (stored in `adapter_state` with component: `digest`, stream_id: `default`). The weekly digest selects triaged items where `triaged_at > last_digest_cutoff_at` and `triaged_at <= current_run_time`, then advances the cutoff after successful delivery. Items triaged between weekly sends are not subject to discovery expiry TTL (they are already triaged, not pending).

**Empty days:** Sources with no new items and `send_empty: false` do not send a digest. No "No new signal today" message cluttering Telegram.

**Aggregate cost summary:** In addition to per-source cost in each digest footer, a weekly aggregate cost summary is sent as a separate message (default: Sunday evening). This gives a single view of total framework spend without cluttering daily digests. The weekly summary also includes a per-adapter **signal quality score**: `promotes / total_items` over the trailing 30 days, computed from `feedback` data. This directly supports evaluating which sources are worth keeping (Success Criterion §14.6).

**Web UI transition:** When the web presentation layer (§5.12) is deployed, per-source Telegram digests transition to notification summaries with a link to the web UI. The full digest rendering moves to the web application. The per-source digest data model is unchanged — only the rendering target changes.

### 5.7 Reply-Based Control Protocol

Identical to x-feed-intel §5.8. All commands, error handling, conditional promote flow, and feedback storage work the same way. Feedback is tagged with `source_type` in the `feedback` table so weight adjustments are per-source, per-topic.

**HTTP feedback path:** When the web presentation layer (§5.12) is deployed, feedback commands are also accepted via HTTP API (§5.12.6). Both Telegram reply and HTTP paths write to the same `feedback` table. Commands are idempotent — concurrent use of both paths is safe. The `investigate` command (§5.13) is available on both paths but designed primarily for the web UI.

### 5.8 Cost Telemetry

Extended from x-feed-intel §5.9 to track per-adapter and aggregate costs.

**Per-adapter tracking:** Each adapter logs its own capture costs (API calls, data volume) to the `cost_log` table with its `source_type`. LLM triage costs are attributed to the source being triaged. For heavy-tier adapters, the summarize and triage steps are logged as separate `subcomponent` entries for cost visibility.

**Aggregate tracking:** The telemetry module computes framework-wide MTD and projected monthly costs across all adapters. This feeds the weekly aggregate summary.

**Per-adapter spending caps:** Each adapter can define its own spending cap in its adapter manifest. Caps are enforced at the start of each capture run: if the adapter's current MTD cost (from `cost_log`) already exceeds its cap, the capture run is skipped and a warning is logged to `adapter_runs` and sent via Telegram. LLM triage costs are estimated conservatively before the call; if the estimate would exceed the cap, triage is deferred.

**Cap-exceeded behavior:** When an adapter's `spending_cap` is exceeded, both capture and triage for that adapter are paused until the next billing period (month boundary) or until the operator manually raises the cap via manifest update. Queued items expire per normal TTL rules. A Telegram alert is sent on cap breach: "⚠️ {adapter.name} spending cap exceeded ($X.XX / $Y.YY). Capture and triage paused until {next month} or cap increase."

**Framework-wide soft ceiling:** A configurable combined budget target (default: $15/month across all sources). The cost guardrail triggers when `projected_month` across all sources exceeds 90% of the combined target. When triggered:
- Adapters with `pull_discovery` implementations reduce `max_results` by 50% (applied to both global defaults and per-topic overrides — both are halved).
- **Heavy-tier lever:** Heavy-tier adapters additionally reduce `triage.max_items_per_cycle` by 50% (rounded up). This targets the actual cost driver — heavy-tier LLM processing — rather than only reducing capture volume. (Note: the per-adapter `reduce_load()` callback in D8 will provide more granular control; this is the Phase 1 blunt instrument.)
- Curated-only adapters (e.g., RSS) are **not** throttled by the framework guardrail. Their volume is inherently bounded by the feed list and they have no `max_results` to reduce.
- Reverts when `projected_month` drops below 80%.
- Digest notes when active: "⚠️ Cost guardrail active — search volume reduced."

**Guardrail timing:** Cost guardrail state is evaluated at each cycle boundary (when manifests are snapshot per §4.1). The guardrail writes a runtime override flag (e.g., `guardrail_active: true` in a framework state file) that is read at the next manifest snapshot. Guardrail adjustments apply at the next capture/attention cycle, not mid-cycle. This is consistent with the configuration snapshot rule — running cycles use the state captured at cycle start.

**Aggregate daily ceiling:** In addition to the monthly soft ceiling, a configurable daily cost ceiling (default: $1.00/day across all sources) prevents a single bad day — e.g., 3 sources with simultaneous backlogs — from consuming a disproportionate share of the monthly budget. When the current day's aggregate `cost_log` total exceeds the daily ceiling, remaining triage is deferred to the next day. Per-adapter daily caps are optional (default: null / no per-adapter daily cap).

### 5.9 Queue Health & Backlog SLOs

Same as x-feed-intel §6.4, applied per-source. Each source has independent queue SLOs:

- Max pending items: configurable per adapter (default 100)
- Max age / expiry TTLs: configurable per adapter (default from x-feed-intel: 7 days search, 30 days bookmarks/saves)
- Backlog digest: triggered per-source when that source's pending count exceeds its threshold

**Attention clock source ordering:** To prevent source starvation under heavy backlog, the attention clock processes sources in round-robin order. Each source has a configurable `triage.max_items_per_cycle` (default: 50 for lightweight, 20 for standard, 10 for heavy). If a source's pending queue exceeds this limit, the remaining items are deferred to the next attention clock run. This ensures no single source (particularly heavy-tier YouTube) monopolizes triage capacity and starves lightweight sources.

**Pipeline liveness check:** Generalized to check that each enabled adapter has completed at least one successful run within its expected interval. The expected interval is declared in the adapter manifest as `capture.liveness_max_gap_minutes` (default: derived from cron schedule + 60-minute grace period). A single liveness alert lists all stalled adapters.

**Adapter degraded state:** When an adapter has >3 consecutive failed runs (status: `failed` in `adapter_runs`) within 24 hours, the framework marks it as **degraded**. In degraded state: triage skips that source, digests include a status line ("⚠️ {adapter.name} degraded: {error_summary} since {first_failure_date}"), and Telegram sends a one-time degraded-state alert. The adapter exits degraded state automatically on its next successful run. An optional `health_check()` hook in the adapter contract allows adapters to detect silent failures (e.g., auth expired but API returns 200 with empty data) — adapters that implement it return a `{healthy: bool, reason: string}` result checked before each capture run.

### 5.10 Error Handling

Same principles as x-feed-intel §6.3. Each adapter handles its own API failures with retries and degraded-mode messaging. Adapter failures are isolated — Reddit going down doesn't affect X or YouTube capture. The attention clock skips triage for sources with zero pending items rather than sending empty triage batches.

**Failure taxonomy (applies to all adapters):**

- **Per-item reject:** A single item fails normalization or triage (e.g., malformed data, unexpected schema). The failed item is logged, skipped, and marked `queue_status = 'triage_failed'` in the state store. The batch continues. Normalization exceptions must not abort the capture batch.
- **Per-run fail:** The entire adapter run fails (e.g., API down, auth failure, network timeout). Logged as `status: 'failed'` in `adapter_runs` with error details. Items already captured in this run are preserved in the queue. Retry on next scheduled run.
- **Partial success:** Some items captured, some failed (e.g., transcript fetch succeeded for 7 of 10 videos). Logged as `status: 'partial'` in `adapter_runs`. Successfully captured items proceed normally; failed items are logged with context for diagnostics.

**Idempotency expectation:** The normalizer must be deterministic — normalizing the same raw item twice must produce the same `canonical_id` and `content` fields. This ensures that retries after partial failures don't create duplicates.

### 5.11 Research Promotion Path

The "research" feedback command dispatches deep-dive investigation on a triaged item and produces an ephemeral research summary in `_openclaw/feeds/research/`. These findings — actionable ops items, architecture patterns, external references — have no durable capture path into vault artifacts without explicit promotion. This is a framework-level concern: any adapter's research flow has the same gap.

**Trigger (dual-path):** Two paths into promotion, both operator-confirmed:

1. **Operator-initiated (primary):** Operator reads research output and requests promotion directly. Crumb converts the research note into a knowledge note in `Sources/` and adds lineage tracking to the research note's frontmatter.
2. **Automated flagging (discovery):** The research process evaluates findings and sets `promotion_candidate: true` in frontmatter when confidence is high and content has vault cross-references. The digest annotation surfaces this: `🔬 Research: {summary} — promotion candidate`. Operator confirms or dismisses.

**Promotion candidate signals (start conservative):** Flag `promotion_candidate: true` when ALL of: research confidence is high AND content has 2+ vault cross-references — plus at least one of: durable reference material, architecture patterns, multi-domain connections, or actionable items with lasting relevance. Omit or set false for purely informational findings, time-bound ops items, negative results confirming existing decisions, or content with fewer than 2 vault cross-references. **Calibration target:** If >30% of research outputs are flagged, the threshold is too loose and the digest annotation loses its signal.

**Surfacing layers (ordered by friction):**

1. **Digest annotation (load-bearing):** When research completes with `promotion_candidate: true`, the next digest includes `⭐ Promotion candidate — review for KB` next to that item. Primary discovery mechanism — surfaces in the operator's existing daily attention flow.
2. **Telegram `save` command:** Operator replies `{ID} save` to trigger full promotion directly (create index + digest in Sources/, add lineage to research note). No intermediate queue — the operator has already reviewed via the digest.
3. **Session startup scan (safety net):** Glob for `promotion_candidate: true` without `promoted_to:` in research files. Build last — only needed if layers 1-2 are insufficient.

**Promotion decision authority:** Always operator-confirmed. The research process recommends (via `promotion_candidate` flag) but never auto-promotes. This is a quality gate that stays human.

**Promotion artifact:** Promotion creates a standard `Sources/[type]/` artifact pair: a source index (`[source-id]-index.md`, type: `source-index`) and a knowledge note (`[source-id]-digest.md`, type: `knowledge-note`) adapted from research content into the standard digest schema. Both use `skill_origin: research-promotion`. Tagged `needs_review` per convention. `#kb/` tags are drawn from the research note's existing tags (canonical tags only). Source type is inferred from the original content (article, video, paper, etc.).

**Research note disposition:** Research notes stay in `_openclaw/feeds/research/` after promotion — they are part of the pipeline's operational record and compound insight routing still references them. Promoted notes get frontmatter lineage fields: `promoted_to: Sources/[type]/[source-id]` and `promoted_at: YYYY-MM-DD`. These provide dedup (don't promote twice) and traceability.

**Research doc contract:** Research summaries written to `_openclaw/feeds/research/` MUST include in frontmatter: `canonical_id`, `source_type`, `promotion_candidate` (boolean), and `research_date`. After promotion, `promoted_to` and `promoted_at` are added. The filename pattern is `feed-intel-{source_type}-{native_id}.md` (matching the routing convention). This standardization allows the framework to treat research docs uniformly across adapters.

**Adapter involvement:** The adapter contract (§6) does not require adapters to implement research — research is a shared infrastructure concern triggered by the feedback protocol. Adapters provide content; the research process operates on triaged items regardless of source.

### 5.12 Web Presentation Layer

The primary reading and interaction surface for feed intelligence is a private web application. Telegram transitions to notification-only with the reply-based control protocol (§5.7) retained as a secondary interaction path.

#### 5.12.1 Hosting and Authentication

The web server runs on the Mac Studio, colocated with the pipeline data (SQLite database, vault files). External access is provided by Cloudflare Tunnel, which exposes the local server to the internet via Cloudflare's network without port forwarding or a public IP. Authentication is handled by Cloudflare Access using email OTP — single-user, zero-trust, any-browser. Requires a registered domain (~$10/yr).

**Failure mode:** If Cloudflare Tunnel is down, the web UI is inaccessible from outside the local network. Telegram notification delivery is unaffected (uses Telegram Bot API directly). The reply-based control protocol via Telegram remains functional as a fallback for feedback commands.

#### 5.12.2 Tech Stack

Express API server with a React single-page application and Tailwind CSS. The Express backend serves the JSON API and hosts the React build as a static bundle. React handles the interactive presentation layer; the Express API is the shared data access layer consumed by both the web UI and the Telegram feedback listener.

**Rationale:** While digest data updates daily, user interactions are real-time: collapsible sections, inline actions with immediate state feedback, source filtering, investigate note composition, and date navigation. These are SPA interactions. Progressive enhancement on server-rendered templates would achieve the same result with more complexity, less maintainability, and no reusable component architecture. React + Tailwind provides a component model that scales to the planned mission control dashboard without rearchitecting the presentation layer.

**Design tooling:** The visual design system (component library, layout patterns, typography, color palette, mobile breakpoints) is designed in Paper (paper.design) before implementation. Paper's MCP server allows Claude Code to read design files directly and generate React + Tailwind components from the visual designs. Paper is used during the initial design and build sprint (~1 month, Pro tier at $20/month) and dropped after the component library is established. Subsequent iteration happens in code.

**Design constraints:**
- The existing Enlightenment-era aesthetic (ET Book, Tufte CSS influence, warm burgundy/teal palette from `digest-prototype.html`) is the starting point. Paper designs must extend this visual language, not replace it.
- Information density is a first-class requirement. This is an operational dashboard, not a marketing site. Every element earns its screen space.
- Dark mode from day one. CSS custom properties for theme switching, not a bolt-on.
- The application shell (nav, layout frame) is designed for extensibility — currently one section (Feed Intel), but structured to accommodate pipeline status, dispatch monitoring, vault health, and cost overview as future views.

**Libraries (locked):**
- React (functional components, hooks)
- react-router (client-side routing for date navigation, future dashboard views)
- Tailwind CSS (utility-first styling)
- Vite (build tooling, dev server with Express proxy)
- Express (API server)
- better-sqlite3 (server-side SQLite access, read-only connection)

**Libraries (permitted if needed during build):**
- a lightweight chart library for cost dashboard (recharts, Chart.js, or equivalent)

**Explicitly excluded:**
- Next.js, Remix, or other meta-frameworks (unnecessary complexity for a single-user app)
- CSS-in-JS solutions (Tailwind is sufficient)
- State management libraries (React context + hooks is adequate at this scale)

#### 5.12.3 Data Access

The Express server provides a JSON API that mediates all data access. The React frontend consumes this API exclusively — it never reads SQLite directly. The API server uses a read-only better-sqlite3 connection to the pipeline's SQLite database (WAL mode handles concurrency with the pipeline's write connection).

**Core API routes:**

```
GET  /api/digest/:date          — Structured digest data for a given date
GET  /api/digest/dates          — Available digest dates for navigation
GET  /api/digest/latest         — Latest digest date and data (direct response, not redirect)
POST /api/feedback              — Process feedback action (existing contract from §5.12.6)
GET  /api/costs                 — Cost telemetry summary (MTD, projected, guardrail status)
GET  /api/costs/:adapter        — Per-adapter cost detail
GET  /api/health                — Pipeline health status (stub returns { status: "ok" } initially; usable as uptime check)
```

**Rationale:** The web UI is the starting point for a mission control dashboard. Future views (pipeline health, dispatch monitoring, vault state) will require data from sources beyond the digest SQLite database. An API layer established now means adding new data sources requires new API routes — the frontend simply consumes JSON. Without it, every new data source requires changes to the rendering layer. The API also cleanly solves dual-path feedback: both the Telegram listener and the web UI write to the same `feedback` table through the same service logic, eliminating duplicated write paths.

The Telegram feedback listener must be refactored to call the same service functions that back the API routes, rather than both the web UI and the Telegram listener independently writing to SQLite. This is not a hard dependency for M-Web launch — the Telegram listener can continue writing directly during the initial build — but must be consolidated before the M-Web gate closes. A dedicated task (FIF-W11) tracks this.

#### 5.12.4 Directory Convention

Web UI code lives in `src/web/` within the framework repo:

```
src/web/
  server.ts          — Express server, API routes, static file serving
  routes/
    digest.ts        — GET /api/digest/* handlers
    feedback.ts      — POST /api/feedback handler
    costs.ts         — GET /api/costs/* handlers
    health.ts        — GET /api/health handler (stub)
  services/
    digest.ts        — Digest data access (SQLite queries, formatting)
    feedback.ts      — Feedback processing (shared with Telegram listener)
    costs.ts         — Cost telemetry queries
  client/
    src/
      App.tsx        — Root component, routing shell
      components/    — Reusable UI components (DigestItem, ActionBar, FilterBar, etc.)
      views/         — Top-level views (DigestView, CostDashboard, etc.)
      hooks/         — Custom React hooks (useDigest, useFeedback, etc.)
      styles/        — Tailwind config, theme tokens, global styles
    public/          — Static assets (favicon, fonts)
    index.html       — SPA entry point
    vite.config.ts   — Vite build config (dev proxy to Express, production output)
  design/
    paper/           — Paper design file exports (reference only, not runtime)
    tokens.md        — Design token documentation (colors, typography, spacing)
```

**Key changes from v0.3.4:**
- `views/` (EJS templates) replaced by `client/` (React app with Vite build)
- `public/` (static assets) moved under `client/`
- Added `services/` layer between routes and SQLite — shared business logic
- Added `design/` for Paper design artifacts and token documentation
- Added `vite.config.ts` for build tooling (dev proxy, production bundle)

This provides a clean extraction boundary — web UI code does not intermingle with pipeline components. Framework extraction from x-feed-intel is a directory move, not a code untangling exercise.

#### 5.12.5 Digest Presentation

The web UI renders the daily digest with:
- Priority sections (high/medium/low) with collapsible groups
- Per-item detail: author, source badge, tags, excerpt, triage rationale, confidence, engagement metrics, direct link to original
- Per-item action buttons: promote, ignore, save, add-topic, investigate
- Source filtering: show all sources or filter by source type
- Past digest browsing by date
- Cost telemetry dashboard: MTD spend per adapter, projected monthly, guardrail status, signal quality scores

The design prototype is at `Projects/x-feed-intel/design/digest-prototype.html` (Tufte CSS, ET Book typography, warm Enlightenment palette).

**Layout model:** Split-pane on desktop (≥1024px): digest item list on the left, item detail + actions on the right. Stacked single-column on mobile. The split-pane ratio is adjustable (drag handle). Rationale: the triage workflow is scan-then-act — the operator scans compact cards, selects one, reads the detail, takes an action, and moves to the next. A split-pane keeps the list visible during detail review, reducing navigation overhead across 15-20 items. Alternative considered: single-column with expandable accordion cards. Simpler, but obscures surrounding items during review and loses positional context in the list.

**Progressive disclosure:** The digest list shows compact item cards (source badge, author, headline, priority indicator, action status). Selecting an item expands the detail pane with full excerpt, triage rationale, confidence score, engagement metrics, tags, and action buttons. On mobile, selecting an item navigates to a full-screen detail view with a back gesture.

**State indicators:** Each item visually communicates its feedback status (unreviewed, promoted, ignored, saved, investigating) through color coding and iconography. Batch state is visible at a glance — the section header shows counts by status (e.g., "High Priority — 3 items, 1 promoted, 2 unreviewed").

**Loading and error states:** The SPA must handle asynchronous data gracefully:
- **Loading:** Skeleton placeholders for digest list and detail pane during initial fetch and date navigation. No blank screens.
- **API errors:** Inline error banner with retry action. Failed feedback actions show the error on the action button without clearing other UI state.
- **Stale data:** If the API is unreachable (tunnel down, server restart), show last-fetched data with a "connection lost" indicator and automatic reconnect attempt.
- **Empty states:** Clear messaging for dates with no digest ("No digest generated for this date") and for zero feedback results in filtered views.

#### 5.12.6 Feedback API

HTTP endpoint colocated with the web server:

```
POST /api/feedback
{
  "item_id": "A01",
  "command": "promote" | "ignore" | "save" | "add-topic" | "investigate",
  "argument": "optional text (topic name for add-topic, operator note for investigate)",
  "digest_date": "2026-02-23"
}
```

Writes to the same `feedback` table as the Telegram reply protocol. Commands are idempotent — both paths can operate in parallel without conflict. Response returns the updated item state for immediate UI feedback.

#### 5.12.7 Telegram Transition

When the web UI is deployed, the per-source Telegram digest (§5.6) transitions from full content to a notification summary:

```
Feed Intel — Feb 23, 2026
3 high · 8 medium · 5 low
Sources: X (12), RSS (4)
-> https://[digest-url]/2026-02-23
```

The reply-based control protocol (§5.7) continues to function — the operator can reply to the notification with `A01 promote` as a fallback. The web UI is the primary interaction surface; Telegram is notification + fallback.

**Transition period:** During the first 2 weeks after web UI deployment (the M-Web gate period), both the full Telegram digest and the notification summary are sent. This provides a fallback while the web UI stabilizes. After the gate passes (5 consecutive days of web UI as primary surface), the full Telegram digest is permanently dropped. The notification-only format becomes the sole Telegram output.

#### 5.12.8 Design Workflow

The web UI visual design is produced in Paper (paper.design) as an operator review and iteration surface. Paper provides a visual workspace where the operator can see, evaluate, and refine designs before committing them to code — catching aesthetic and layout issues early, when changes are cheap. Paper's MCP server enables bidirectional agent-design communication, bridging the design-to-code gap.

**Why Paper (not design-in-code):** The operator needs to see and react to visual designs before implementation. Code iteration on visual design is slow and expensive — you can't feel a layout by reading JSX. Paper provides the visual feedback loop: the operator sees a component, says "that's too dense" or "swap those colors," and the design updates before any code is written. This is especially valuable for establishing the initial design system, where many aesthetic decisions happen in rapid succession.

The workflow:

1. **Design system establishment:** Define the color palette, typography scale (extending the ET Book / Enlightenment palette from the digest prototype), spacing rhythm, and component treatments in Paper. The existing `digest-prototype.html` is the visual starting point — Paper extends it into a full component system. Document as design tokens in `src/web/design/tokens.md`.

2. **Component design:** Design core UI components in Paper — digest item card (compact and expanded states), action button bar, priority section headers, source filter bar, date navigator, cost dashboard widgets, application shell with nav. Design both light and dark mode variants. Design mobile breakpoints (375px, 768px, 1024px). Operator reviews each component in Paper before it moves to implementation.

3. **Agent-driven implementation:** Claude Code reads the Paper designs via MCP (`claude mcp add paper --transport http http://127.0.0.1:29979/mcp --scope user`) and generates React + Tailwind components that match the visual designs. The web-native HTML/CSS representation in Paper produces high-fidelity design-to-code translation.

4. **Iteration in code:** After the initial component library is generated and operator-approved, Paper is dropped. All subsequent design iteration happens directly in code. The design tokens document serves as the reference for visual consistency.

**Paper cost:** Pro tier, $20/month, used for approximately one month during the M-Web build sprint. No ongoing cost.

**Paper limitations (acknowledged):**
- Early-stage software; instability expected. If Paper blocks progress, fall back to designing directly in code using Claude Code's frontend-design capabilities. This is a degraded path — the operator loses the visual iteration surface and must review designs as rendered code instead.
- MCP call limit on free tier (100/week) is insufficient for active design sessions. Pro tier (1M/week) removes this constraint.
- Paper designs are reference artifacts, not runtime dependencies. The web UI has zero runtime dependency on Paper.

### 5.13 Investigate Action

A feedback command that dispatches deep-dive research on a digest item, producing an investigation brief for operator + Crumb review. Distinct from `promote` (stage for KB review) and `save` (persist as knowledge) — investigate means "there might be a project here, research it."

**Primary trigger surface:** Web UI investigate button with optional operator note. Telegram `{ID} investigate [note]` supported as secondary path but the web UI is the design driver — the operator reads context, checks triage assessment, and adds a meaningful note before triggering.

**Blocked on:** Web UI deployment (§5.12). The investigate action is not implemented until the web presentation layer exists.

#### 5.13.1 Flow

1. Operator taps Investigate on a digest item (web UI or Telegram)
2. Optional free-text note: context on what caught attention, specific question, or blank for "just look into this"
3. Feedback table records command + operator note
4. Item staged to `_openclaw/feeds/investigate/` with frontmatter:
   ```yaml
   type: investigation-request
   canonical_id: "x:1234567890"
   source_item: "feed-intel-x-1234567890.md"
   requested_at: "2026-02-23T14:30:00Z"
   operator_note: "Could this replace our current context checkpoint approach?"
   status: pending
   ```
5. Tess picks up pending requests (separate async sweep, NOT part of attention clock — investigation is unbounded in duration and must not block digest delivery)
6. Tess researches: fetches full content, pulls related pipeline history, writes structured investigation brief
7. Brief written to same file (status -> `complete`) with sections: Summary, Relevance to Current Architecture, Key Findings, Recommendation (new project / fold into {project} / capture as KB / discard), Sources Consulted
8. During Crumb session, operator + Crumb review brief. Outcomes: new project, fold into existing, capture as KB, or discard

#### 5.13.2 Operational Constraints

- **Processing model:** Separate async process. One investigation per sweep cycle. Does not share attention clock resources.
- **Volume cap:** Soft cap of 3-5 pending investigations. Telegram notification when at capacity: "Investigation queue at capacity — complete or decline existing before adding more."
- **Cost model:** Investigation uses LLM calls for assessment writing. Model selection and cost estimate TBD — must be defined before Tess sweep goes live. Expected to be more expensive per-item than triage (Sonnet-class vs Haiku).
- **Staging location:** `_openclaw/feeds/investigate/` (Tess-owned, parallel to `kb-review/`). Not `_openclaw/inbox/` — investigation requests are Tess's work queue; completed briefs route to Crumb's inbox.

#### 5.13.3 Schema Impact

`investigate` becomes a new valid `command` value in the `feedback` table. The `argument` field stores the operator note. No new tables required.

## 6. Adapter Contract

Every source adapter must implement the following contract to plug into the framework. This is the interface between the shared infrastructure and source-specific logic.

### 6.1 Adapter Manifest

Each adapter provides a YAML manifest that registers it with the framework:

```yaml
# adapters/yt.yaml
manifest_version: 1                    # Schema version — framework rejects unsupported versions

adapter:
  id: yt                               # source_type value — must be unique, used as canonical_id prefix
  name: "YouTube"                      # Display name for digests
  enabled: true                        # Master on/off switch
  content_tier: heavy                  # lightweight | standard | heavy (default for items without effective_tier)
  
capture:
  schedule:
    curated: "0 6 * * *"              # Cron for bookmark/save/subscription pulls (null if not implemented)
    discovery: "0 6 */2 * *"          # Cron for search/discovery pulls (null if not implemented)
  liveness_max_gap_minutes: 1500       # ~25 hours — alert if no successful run in this window
  retry:
    max_attempts: 3
    backoff_seconds: [30, 60, 120]

triage:
  prompt_preamble: "prompts/yt_preamble.md"
  batch_size: 5                        # Items per triage call (lower for heavy tier)
  full_text_token_limit: 8000          # Max tokens from full_text per item (pre-summarization for heavy tier)
  max_items_per_cycle: 10              # Max items triaged per attention clock run

digest:
  time: "08:10"                        # Local time (America/Detroit) — delivery time within the attention run
  cadence: daily                       # daily | weekly
  min_items: 1                         # Suppress digest if fewer than this many items
  send_empty: false
  max_items_inline: 25

queue:
  max_pending: 75
  expiry_curated_days: 30
  expiry_discovery_days: 7

cost:
  spending_cap: null                   # Per-adapter hard cap (null = no cap, rely on framework ceiling)
  
credentials:
  - name: YOUTUBE_API_KEY
    store: keychain
  - name: YOUTUBE_OAUTH_TOKEN
    store: keychain
```

**Manifest versioning:** The `manifest_version` field (top-level, required) declares the schema version of the manifest. The framework validates this field at startup. If `manifest_version` is missing, non-integer, or an unsupported version, the framework rejects the manifest, logs an error in `adapter_runs`, sends a Telegram alert, and does not load the adapter. Other adapters with valid manifests continue normally. This prevents silent misconfiguration when the manifest schema evolves.

**Adding a new source:** Create an adapter manifest, implement the extractor and normalizer functions per the contract below, write a triage prompt preamble, and register the adapter by placing the manifest in `adapters/`. The framework discovers and loads enabled adapters at startup. No changes to shared infrastructure code.

**Removing a source:** Set `enabled: false` in the manifest. The capture clock stops running that adapter. Pending items for the disabled source are expired per normal TTL rules. The adapter's digest stops sending. Historical data remains in the state store for reference. To fully remove, delete the manifest and optionally run `DELETE FROM posts WHERE source_type = '{id}'`.

**Modifying a source:** Manifest changes take effect at the next cycle boundary (per §4.1 configuration snapshot rule). Schedule changes, batch sizes, TTLs, and spending caps are all hot-reconfigurable. Changing `content_tier` may require prompt preamble updates.

### 6.2 Extractor Interface

Each adapter must implement one or both extraction functions:

**`pull_curated(state: dict) → (list[RawItem], updated_state: dict)`**
Fetches user-curated content (bookmarks, saves, subscriptions, watch later). Receives the adapter's persisted cursor state as a JSON-serializable dictionary. Returns raw platform-specific items and an updated state dictionary. The framework persists the updated state to the `adapter_state` table (§8) after a successful run.

**`pull_discovery(topic_config: dict, state: dict) → (list[RawItem], updated_state: dict)`**
Fetches content via search or discovery mechanisms. Receives the parsed topic config (as a structured dictionary with `defaults` and `topics` keys, matching the YAML schema in §6.5) and the adapter's persisted discovery cursor state. Returns raw items and updated state. Implements per-run dedup cache internally.

**Cursor state model:** The framework maintains cursor state per adapter via the `adapter_state` table, keyed by `(source_type, component, stream_id)`:
- `component` is `curated` or `discovery`
- `stream_id` is adapter-defined — e.g., a playlist ID, subreddit name, feed URL, or topic name. For simple adapters with a single stream, use `"default"`. **Guidance:** For discovery extractors with multiple topics, `stream_id` SHOULD be set to `topic.name` from the topic config. This ensures independent cursor tracking per topic and prevents slower queries from being starved by faster ones sharing a single cursor.

**Cursor persistence atomicity:** The framework persists `updated_state` to `adapter_state` only after the full capture pipeline (extraction, normalization, dedup insertion) completes successfully. On partial or failed runs, the cursor is not advanced, ensuring the next retry starts from the same point. This means some items may be re-fetched on retry; they are deduplicated by `canonical_id` on insertion.

**Disable/re-enable behavior:** When an adapter is re-enabled after being disabled, existing cursor state is preserved in `adapter_state`. The adapter resumes from its last checkpoint. Items that aged past their TTL during the disabled period are gone (expected and acceptable). If the cursor is stale (e.g., pagination token expired), the adapter should detect this and reset to a fresh state, logging a warning.

**Stale cursor threshold:** The adapter manifest can specify `capture.stale_cursor_threshold_days` (default: 7). If `adapter_state.updated_at` for any cursor is older than this threshold when the adapter runs, the adapter performs a **cold start**: the stale cursor is discarded, the adapter starts from the current date, and a warning is logged to `adapter_runs`. This prevents expensive catch-up floods when an adapter is re-enabled after a long disable period.

An adapter may implement only one of these (e.g., RSS has no search; HN Phase 1 has no curated pull). The framework calls whichever functions are implemented.

### 6.3 Normalizer Interface

Each adapter must implement:

**`normalize(raw_item) → UnifiedContent`**
Converts a platform-specific raw item into the unified content format (§5.1). The adapter is responsible for:

- Generating the `canonical_id` as `{adapter.id}:{native_id}` — prefix MUST equal the adapter's `id` field
- Mapping platform engagement metrics to the unified `engagement` fields
- Setting `content_type` appropriately
- Populating `excerpt` (always required) and `full_text` (when available)
- Setting `effective_tier` when the item should be triaged at a different tier than the adapter's default (e.g., YouTube video with no transcript → `effective_tier: "lightweight"`)
- Computing `url_hash` using the framework-provided `canonicalize_url()` helper (see below). **URL-first principle:** For items whose primary purpose is sharing an external link, `url_hash` MUST be derived from that external URL, not the platform permalink. The platform permalink is preserved in `metadata.platform_url`. This enables cross-source collision detection for articles shared across multiple platforms.
- Setting `needs_context` and `context_hint` based on source-specific heuristics
- Populating `platform_url`
- Populating `search_query` in `source_instances` for discovery-sourced items
- Populating `platform_specific` with any adapter-specific metadata not captured in the unified fields

**URL canonicalization helper:** The framework provides a `canonicalize_url(url) → str` function that all adapters MUST use for computing `url_hash`. Adapters must not implement their own canonicalization. The helper performs these steps in order:
1. Lowercase scheme and host
2. Remove default ports (`:80` for http, `:443` for https)
3. Strip known tracking parameters: `utm_*`, `fbclid`, `gclid`, `ref`, `source`, `via`, and other common trackers
4. Remove URL fragments (`#...`)
5. Sort remaining query parameters lexicographically
6. Return the canonicalized URL string

URL shortener and redirect resolution is the **extractor's** responsibility (at capture time), not the normalizer's. Extractors should resolve shortened URLs (e.g., `t.co/*`, `bit.ly/*`) to their destination before passing raw items to the normalizer. This preserves normalizer determinism while ensuring the normalizer operates on the final destination URL.

**Determinism requirement:** The normalizer must be deterministic — normalizing the same raw item twice must produce the same output. This ensures retry safety.

### 6.4 Triage Prompt Preamble

Each adapter provides a markdown file containing source-specific scoring guidance that is prepended to the shared triage prompt. This preamble tells the triage engine how to evaluate content from this source. It should address:

- What signals indicate quality for this content type
- How to interpret engagement metrics for this platform (1,000 likes on X ≠ 1,000 likes on YouTube)
- Source-specific context hints the triage engine should attend to
- Any known noise patterns to watch for
- How to handle items with `needs_context: true` for this source
- How to handle items at a lower effective_tier than the adapter's default (e.g., YouTube without transcript)

The preamble is loaded from the path specified in the adapter manifest. It has a soft budget of 200 tokens — enough for meaningful guidance without bloating the prompt.

**Missing preamble handling:** If the preamble file cannot be loaded (missing, unreadable, or empty), the framework logs an error in `adapter_runs`, sends a Telegram alert, and skips triage for that source for this cycle (treats the adapter as temporarily disabled). The framework does not fall back to no-preamble triage — the preamble is important enough that silent fallback would produce poor-quality results.

### 6.5 Topic Config

Each adapter that implements `pull_discovery` provides a topic config file (YAML) following the same structure as x-feed-intel §5.2. The schema is shared but the queries and filters are source-specific.

```yaml
# topic_configs/yt.yaml
defaults:
  max_age_days: 14
  max_results: 20

topics:
  - name: agent-architecture
    queries:
      - "building AI agents"
      - "agentic coding tutorial"
      - "multi-agent system demo"
    max_results: 20
    filters: {}  # Source-specific filter format
```

The framework passes the parsed config (as a Python dict or equivalent structured object) to `pull_discovery`. The adapter is responsible for iterating over topics, issuing queries, respecting per-topic `max_results`, and implementing per-run dedup across queries.

## 7. Source Adapter Specifications

Each adapter below defines its source-specific capture mechanics, API details, normalization rules, triage considerations, and cost profile. These are deliberately concise — the full behavioral specification for shared infrastructure lives in §5 and in the x-feed-intel spec.

**API assumptions disclaimer:** Per-source API terms, rate limits, quotas, and pricing in this section are pre-Phase-0 assumptions based on information available at spec authoring time. Each adapter's Phase 0 includes mandatory API verification. Do not treat these assumptions as authoritative — they require current verification before implementation.

### 7.1 X (Twitter) Adapter

**Reference:** x-feed-intel spec v0.4.1 (canonical). This section does not duplicate that spec.

**Adapter identity:** `id: x`

**Content tier:** Lightweight

**Capture:**
- Curated: X API v2 bookmarks (OAuth 2.0)
- Discovery: TwitterAPI.io search

**Normalization:** As defined in x-feed-intel §5.3. The `canonical_id` format changes from bare ID to `x:{post_id}` during migration (§8.1). All other normalization rules carry over. **`url_hash` rule:** If an X post shares a single external URL as its primary content (link-sharing post), `url_hash` is derived from that external URL per the URL-first principle (§6.3). For posts without an external link (original commentary, threads), `url_hash` is computed from `platform_url` (`https://x.com/{user}/status/{id}`). The tweet permalink is always preserved in `metadata.platform_url` regardless.

**Triage preamble:** Emphasizes actionability and concreteness over commentary. Engagement thresholds calibrated for X's scale. Thread awareness via `needs_context`.

**Cost profile:** $2–$4/month (see x-feed-intel §13 for full breakdown).

**Status:** Fully specified. Ready for Phase 1 implementation.

### 7.2 YouTube Adapter

**Adapter identity:** `id: yt`

**Content tier:** Heavy (default; items without transcripts fall back to `effective_tier: lightweight`)

**API: YouTube Data API v3**
- Auth: OAuth 2.0 (for subscriptions, liked videos, watch later) or API key (for search)
- Pricing: Quota-based. 10,000 units/day free. Search costs 100 units/call. List operations cost 1-5 units/call.
- Rate limits: Generous for this volume. Quota is the binding constraint, not rate.

**Transcript retrieval:**
- **Mechanism:** Third-party library (e.g., `youtube-transcript-api` for Python) that scrapes auto-generated captions from the YouTube web player.
- **Important caveat:** This is an unofficial capability, not an official API. The YouTube Data API v3 `captions` endpoint only allows transcript download for videos owned by the authenticated user. Third-party transcript retrieval depends on YouTube's web player structure and can break without notice.
- **Availability:** Auto-generated captions are available for most English-language content but not guaranteed. Technical content often has poor ASR quality for domain-specific terms (e.g., "agentic" transcribed as "a genetic"). Not all videos have captions enabled.
- **Phase 0 quantification required:** Sample 50 videos from target topic queries and measure: (a) transcript availability rate, (b) transcript quality for technical terms. If availability is below 70%, reassess the heavy-tier strategy. Document results in Phase 0 findings.
- **Per-item `transcript_status`:** The normalizer tracks transcript retrieval outcome in `platform_specific.transcript_status`: `"available"`, `"unavailable"`, `"blocked"`, `"error"`. Items with `transcript_status != "available"` set `effective_tier: "lightweight"` and triage on title + description only.
- **Robustness and circuit breaker:** Cache transcripts aggressively in the state store (transcripts don't change). Hard cap on transcript fetch attempts per run: default 50. Per-request jitter delay: 1-2 seconds between transcript fetches within a run. **Circuit breaker:** If the transcript error rate exceeds 80% across 3 consecutive capture runs, the adapter enters **transcript-disabled mode**: all future items are set to `transcript_status: "blocked"`, `effective_tier: "lightweight"`, and a Telegram alert is sent ("⚠️ YouTube transcript library appears broken — operating in lightweight-only mode"). Transcript-disabled mode persists until the operator explicitly re-enables transcripts via a manifest flag (`transcript_enabled: true`, default `true`). This prevents sustained hammering of a broken library and avoids noisy logs.

**Capture — Curated:**
- Pull liked videos and/or watch later playlist via `playlistItems.list`
- Incremental pull using cursor state (playlist position + timestamp)
- Subscriptions feed via `activities.list` for new uploads from subscribed channels

**Capture — Discovery:**
- `search.list` with topic queries
- Filters: `type=video`, `order=viewCount` or `order=relevance`, `publishedAfter` for recency
- `videoDuration` filter available (short/medium/long) — useful for filtering out shorts vs. substantive content

**Normalization:**
- `canonical_id`: `yt:{video_id}`
- `content.title`: video title
- `content.excerpt`: video description, first 280 chars
- `content.full_text`: transcript when available; `null` otherwise
- `content.effective_tier`: `null` when transcript available (uses adapter default: heavy); `"lightweight"` when transcript unavailable
- `content.content_type`: `video`
- `content.duration_seconds`: from `contentDetails.duration`
- `content.url_hash`: SHA256 hash of canonicalized `https://youtube.com/watch?v={video_id}`
- `metadata.engagement`: `views` (viewCount — primary signal), `comments` (commentCount), `likes` (from statistics, may be hidden by creator). Note: YouTube allows creators to hide like counts; `viewCount` and `commentCount` are more reliably available and should be weighted accordingly in the triage preamble.
- `metadata.platform_specific`: `{ "channel_id": "...", "channel_subscribers": N, "transcript_status": "available|unavailable|blocked|error" }`
- `needs_context`: `true` if video is part of a playlist series (detectable via playlist membership)

**Triage preamble guidance (draft):**
- Weight transcript substance over title clickbait. A video titled "INSANE AI Agent Hack" may contain a genuinely useful technique — the transcript tells the truth.
- For items without transcripts (effective_tier: lightweight), triage conservatively on title + description. Use `confidence: low` unless the title/description is highly specific.
- Weight `viewCount` and `commentCount` over `likes` — likes may be hidden and are less reliable.
- Videos under 5 minutes: often superficial or promotional. Require higher engagement thresholds.
- Videos over 30 minutes: may contain relevant segments buried in broader content. The summarize step (heavy tier) should extract the relevant portions.
- Channel authority matters more on YouTube than on X. Established practitioners (with consistent content) are higher signal than viral one-offs.
- Tutorial/demo content with how-to language in title/transcript should score higher on actionability than commentary/reaction content.
- Auto-generated transcripts may contain ASR errors for technical terms. Do not penalize posts where key terms appear garbled — the surrounding context usually clarifies intent.

**Cost profile:**
- YouTube Data API: Free tier (10,000 quota units/day) is sufficient. Estimated daily usage: ~500-1,000 units.
- Transcript retrieval: Free (unofficial, no quota cost).
- LLM triage (heavy tier): ~$0.80–$1.50/month for summarize + triage. Estimate: 5-10 videos/day.
- LLM triage (lightweight fallback for no-transcript items): ~$0.05-$0.10/month additional.
- **Monthly total: $0.85–$1.60** (almost entirely LLM cost).

**Phase 0 verification:**
- Quantify transcript availability rate (50-video sample across target topics)
- Assess transcript quality for domain-specific technical terms
- Confirm quota consumption for planned daily volume stays within free tier
- Validate that transcript library works reliably; document failure modes
- Test search result quality for topic queries — YouTube search is notoriously noisy for technical content

### 7.3 Reddit Adapter

**Adapter identity:** `id: reddit`

**Content tier:** Standard

**API: Reddit API (OAuth 2.0)**
- Auth: OAuth 2.0 via a "script" app type (personal use). Requires Reddit account.
- Pricing: Free for personal use (as of last verified information). Rate limit: 100 requests/minute (authenticated), though this may have been tightened — verify in Phase 0.
- **User-agent requirement:** Reddit actively blocks generic user-agent strings. The adapter MUST use the format: `<platform>:<app_id>:<version> (by /u/<username>)` per Reddit's API rules.
- **⚠️ Hard Phase 0 gate:** Reddit's API terms for personal-use scripts must be re-verified before any implementation begins. The policy has shifted multiple times since 2023. If the free personal-use tier is no longer available or terms are incompatible, the Reddit adapter is deferred or redesigned around alternative mechanisms (see fallback below).
- **Fallback: Reddit RSS feeds.** If API access is blocked, subreddit RSS feeds (`https://www.reddit.com/r/{subreddit}/.rss`) provide basic post data (title, author, link, snippet) without authentication. **RSS fallback contract:** Adapter `id` remains `reddit`. Manifest changes: `content_tier: lightweight`, `pull_curated` disabled (no saved posts without OAuth), `pull_discovery` reimplemented via RSS feed URLs listed in a config file (same pattern as the RSS adapter's feed list, §7.5). In fallback mode: `metadata.engagement.*` are all null, `content.full_text` is limited to whatever the RSS feed provides (usually a short summary), and saved posts are unavailable. Switching into RSS fallback mode is a PLAN-level decision (not automatic) and requires a manifest update plus one-time cursor reset.

**Capture — Curated:**
- Pull saved posts via `/user/{username}/saved` (OAuth required)
- Incremental pull using cursor state (pagination `after` token)

**Capture — Discovery:**
- Subreddit monitoring: pull recent posts from configured subreddits via `/r/{subreddit}/new` or `/r/{subreddit}/top?t=week`
- Cross-subreddit search: `/search` with topic queries, restricted to configured subreddits via `subreddit` parameter
- Filters: `sort=top`, `t=week`, minimum score threshold (client-side)

**Target subreddits (initial):**
- r/ObsidianMD
- r/ClaudeAI
- r/LocalLLaMA
- r/MachineLearning
- r/artificial
- r/ChatGPT (high noise — aggressive engagement filtering needed)

**Normalization:**
- `canonical_id`: `reddit:{post_id}` (Reddit's `t3_` prefix stripped)
- `content.title`: post title
- `content.excerpt`: first 280 chars of self-text, or the link URL + title for link posts
- `content.full_text`: full self-text for text posts. For link posts, `null` in Phase 1 (linked article fetch is a Phase 2 enrichment).
- `content.content_type`: `long_text` for self-posts, `link` for link posts
- `content.url_hash`: hash of the linked URL for link posts; hash of the Reddit permalink for self-posts
- `metadata.engagement`: `likes` (score), `comments` (num_comments), `shares` (crossposts — usually low signal), `saves` (not available via API — null)
- `metadata.platform_specific`: `{ "subreddit": "ObsidianMD", "is_self": true, "flair": "..." }`
- `needs_context`: `true` for crossposted content where the original post context matters

**Triage preamble guidance (draft):**
- Reddit post quality is bimodal: either substantive discussion or low-effort content. The score (upvotes - downvotes) is a reasonable quality proxy, especially in smaller technical subreddits.
- Self-posts with substantial text (>500 chars) are generally higher signal than link posts for triage purposes — the author invested effort.
- Link posts are harder to triage without fetching the linked content. In Phase 1, triage on title + comments count + subreddit context. Phase 2 adds linked article fetch.
- Subreddit context matters: a post in r/ObsidianMD scoring 50 upvotes is stronger signal than the same score in r/ChatGPT (10× the subscriber count, much more noise).
- Comments count is a signal of discussion depth, not just popularity. High comments with moderate score often indicates substantive debate.

**Cost profile:**
- Reddit API: Free (personal use, pending Phase 0 verification).
- LLM triage (standard tier): ~$0.30–$0.60/month.
- **Monthly total: $0.30–$0.60.**

### 7.4 Hacker News Adapter

**Adapter identity:** `id: hn`

**Content tier:** Lightweight (title + metadata triage) with optional standard-tier enrichment for linked articles in Phase 2.

**API: Hacker News API (official) + Algolia HN Search API**
- Auth: None required. Both APIs are public.
- Pricing: Free.
- Rate limits: Official API has no documented rate limit but courtesy dictates reasonable polling. Algolia HN search: 10,000 requests/hour (far more than needed).

**Capture — Curated:**
- **Deferred to Phase 2.** HN favorites (`/favorites?id={username}`) is a scrape target, not an API endpoint, and is brittle against HTML changes. Phase 1 is discovery-only. If a reliable favorites mechanism is identified (e.g., Algolia user-specific search), it can be added as a curated stream in Phase 2.

**Capture — Discovery:**
- Algolia HN Search API: `https://hn.algolia.com/api/v1/search` with topic queries
- Filters: `tags=story` (exclude comments, polls), `numericFilters=points>N` for engagement threshold
- Default sort: `search_by_date` (most recent first) to prioritize recency for daily digests
- Front page monitoring: poll `/v0/topstories.json` from official API, filter by domain/keyword match

**Normalization:**
- `canonical_id`: `hn:{item_id}`
- `content.title`: story title
- `content.excerpt`: title + domain of linked URL. HN stories are typically links with minimal self-text. The title IS the content for triage purposes at the lightweight tier.
- `content.full_text`: `null` in Phase 1. Phase 2 adds linked article fetch via `web_fetch` for items above an engagement threshold, upgrading those items to standard tier.
- `content.content_type`: `link` (most stories) or `short_text` (Show HN / Ask HN with self-text)
- `content.url_hash`: hash of the linked URL (for link posts) or HN item URL (for text posts)
- `metadata.engagement`: `likes` (points), `comments` (descendants count), `views` (not available — null)
- `metadata.platform_url`: `https://news.ycombinator.com/item?id={item_id}`
- `metadata.platform_specific`: `{ "domain": "arxiv.org", "type": "story|show_hn|ask_hn" }`
- `needs_context`: `false` (HN stories are self-contained at the title level)

**Triage preamble guidance (draft):**
- HN triage is primarily title + metadata driven. The title and source domain tell you a lot: a post from `arxiv.org` titled "Scaling Agentic Coding with..." is different signal than a Medium post with the same title.
- Points (upvotes) are a strong quality signal on HN — the community is technically sophisticated and the voting population skews toward practitioners.
- Comment count relative to points is a signal: high comments/low points often means controversial; high points/low comments often means "clearly good, nothing to debate."
- Show HN and Ask HN posts with self-text deserve standard-tier triage (read the body) — these are practitioner-generated content, not link shares. The normalizer should set `effective_tier: "standard"` for these.
- Domain filtering is valuable: filter out known low-signal domains (e.g., generic news aggregators) at the capture level.

**Cost profile:**
- APIs: Free.
- LLM triage (lightweight): ~$0.10–$0.20/month.
- Phase 2 with article fetch: add ~$0.30–$0.60/month for LLM summarization of fetched articles.
- **Monthly total: $0.10–$0.20 (Phase 1).**

### 7.5 RSS/Blogs Adapter

**Adapter identity:** `id: rss`

**Content tier:** Standard (title + excerpt for lightweight sources; full post for blogs that include content in the feed)

**Technical approach: Standard RSS/Atom feed polling**
- Auth: None for public feeds. Some newsletters may require subscriber tokens in the feed URL.
- Pricing: Free.
- Rate limits: None (you control polling frequency).
- Library: `feedparser` (Python) or equivalent.

**Capture — Curated only (no discovery):**
- RSS is inherently curated — you subscribe to specific feeds. There is no search/discovery mechanism.
- Feed list maintained in a YAML config file, same pattern as topic configs but simpler:

```yaml
# topic_configs/rss.yaml
feeds:
  - name: "Simon Willison"
    url: "https://simonwillison.net/atom/everything/"
    tags: ["ai-workflows", "tool-discovery"]
    
  - name: "Anthropic Research"
    url: "https://www.anthropic.com/research/rss"
    tags: ["agent-architecture", "claude-code"]
    
  - name: "Obsidian Roundup"
    url: "https://www.obsidianroundup.org/rss/"
    tags: ["obsidian-pkm"]
    
  # Adding a feed = adding an entry here. That's it.
```

- Each feed is polled on a configurable schedule (default: daily).
- Incremental pull using cursor state per feed (last `published` date + GUID set).

**Normalization:**
- `canonical_id`: `rss:{sha256(canonicalized_url)[:16]}` — RSS GUIDs are unreliable, so hash the canonicalized permalink (strip UTM/tracking params, normalize scheme, remove fragments) as the canonical ID. Uses the same SHA256[:16] truncation length as `url_hash` for consistency. This ensures the same article linked with different tracking parameters produces the same ID.
- `content.title`: entry title
- `content.excerpt`: first 280 chars of entry summary/description (most feeds include this)
- `content.full_text`: full entry content if included in the feed (`content:encoded` field). Many feeds include full text; some include only summaries. If summary-only, `full_text` is `null` and the normalizer sets `effective_tier: "lightweight"`.
- `content.content_type`: `long_text` (if full content available) or `link` (if summary-only)
- `content.url_hash`: hash of canonicalized entry permalink
- `metadata.engagement`: all `null` — RSS feeds don't include engagement metrics. Triage relies entirely on content quality and source reputation.
- `metadata.platform_url`: entry permalink
- `metadata.platform_specific`: `{ "feed_name": "Simon Willison", "feed_url": "https://..." }`
- `needs_context`: `false` (blog posts are self-contained)
- `metadata.matched_topics`: inherited from feed-level `tags` in the config, not from search query matching

**Triage preamble guidance (draft):**
- No engagement metrics available. Triage is purely content-driven — does this post contain actionable information for current projects?
- Source reputation is pre-filtered by the feed list itself. Danny subscribes to feeds he trusts, so the bar for inclusion is already higher than search-discovered content.
- Blog posts with code examples, architecture diagrams, or step-by-step guides score higher than opinion pieces or announcements.
- For summary-only entries (no full text in feed), triage conservatively — title + summary may not contain enough signal for confident categorization. Use `confidence: low` liberally and rely on the digest for Danny to click through.

**Cost profile:**
- Feed polling: Free.
- LLM triage: ~$0.20–$0.50/month depending on number of feeds and post frequency.
- **Monthly total: $0.20–$0.50.**

### 7.6 arxiv Adapter

**Adapter identity:** `id: arxiv`

**Content tier:** Standard (abstract-based triage)

**API: arxiv API (OAI-PMH + Atom feed)**
- Auth: None required.
- Pricing: Free.
- Rate limits: 1 request per 3 seconds (courtesy). Adequate for daily pulls.
- arxiv also provides RSS feeds per category, which can be used as an alternative capture mechanism.

**Capture — Discovery only (no curated):**
- arxiv API search: query by keyword, category, and date range
- Default sort: `sortBy=submittedDate`, `sortOrder=descending` (most recent first)
- Target categories: `cs.AI`, `cs.CL`, `cs.MA` (multi-agent systems), `cs.SE` (software engineering)
- Filters: date range (`submittedDate`), category restriction
- Volume control: arxiv publishes hundreds of papers/day in AI categories. Aggressive keyword filtering and engagement-proxy heuristics (citation count is lagged; social media mentions are noisy) are essential. Phase 1 relies on keyword precision and accepts lower recall.

**Topic config:**

```yaml
# topic_configs/arxiv.yaml
defaults:
  max_age_days: 7
  max_results: 30

topics:
  - name: agent-systems
    queries:
      - "agentic LLM"
      - "tool-use language model"
      - "multi-agent orchestration"
    categories: ["cs.AI", "cs.MA", "cs.CL"]
    max_results: 30
    
  - name: code-generation
    queries:
      - "code generation LLM"
      - "automated software engineering"
    categories: ["cs.SE", "cs.CL"]
    max_results: 20
```

**Normalization:**
- `canonical_id`: `arxiv:{paper_id}` (e.g., `arxiv:2602.12345`)
- `content.title`: paper title
- `content.excerpt`: first 280 chars of abstract
- `content.full_text`: full abstract (typically 150-300 words, well within standard tier token budgets)
- `content.content_type`: `paper`
- `content.url_hash`: hash of `https://arxiv.org/abs/{paper_id}`
- `metadata.engagement`: all `null` in Phase 1. Semantic Scholar API (free for low-volume use) could provide citation counts as a Phase 2 enrichment.
- `metadata.platform_url`: `https://arxiv.org/abs/{paper_id}`
- `metadata.platform_specific`: `{ "categories": ["cs.AI", "cs.CL"], "primary_category": "cs.AI" }`
- `needs_context`: `false`

**Triage preamble guidance (draft):**
- Triage on abstract only. Do not attempt to evaluate papers based on title alone — arxiv titles are often technical and opaque.
- Prioritize papers that describe systems, architectures, or empirical results over theoretical analysis or surveys (unless the survey directly covers an active project area).
- Author reputation is not available in the abstract. Do not attempt to infer paper quality from author names.
- "Agentic" is overloaded in current arxiv literature. Many papers use the term loosely. Look for concrete system descriptions, benchmark results, or tool implementations as quality signals.
- Papers with accompanying code repositories (often mentioned in the abstract as "code available at...") score higher on actionability.

**Cost profile:**
- arxiv API: Free.
- LLM triage (standard tier, abstract-based): ~$0.15–$0.30/month.
- **Monthly total: $0.15–$0.30.**

## 8. State Store Schema

The SQLite schema extends x-feed-intel §7.2 to support multi-source operation.

```sql
-- Core content table — extended with source_type and url_hash
CREATE TABLE posts (
  canonical_id TEXT PRIMARY KEY,       -- format: source_type:native_id
  source_type TEXT NOT NULL,           -- x | yt | reddit | hn | rss | arxiv
  url_hash TEXT,                       -- SHA256[:16] of canonicalized primary URL; nullable
  source_instances TEXT NOT NULL,      -- JSON array
  first_seen_at TEXT NOT NULL,
  last_seen_at TEXT NOT NULL,
  author_json TEXT NOT NULL,
  content_json TEXT NOT NULL,          -- includes effective_tier, platform_specific
  metadata_json TEXT NOT NULL,
  triage_json TEXT,
  triage_attempts INTEGER NOT NULL DEFAULT 0,  -- retry counter for triage_deferred items (§5.3.1)
  queue_status TEXT NOT NULL DEFAULT 'pending',
    -- pending | triaged | triage_failed | triage_deferred | expired | archived
  queued_at TEXT NOT NULL,
  triaged_at TEXT,
  routed_at TEXT                        -- set when vault file is written; used for url_hash collision lookup
);

CREATE INDEX idx_posts_source_status ON posts(source_type, queue_status);
CREATE INDEX idx_posts_queued_at ON posts(queued_at);
CREATE INDEX idx_posts_url_hash ON posts(url_hash);
CREATE INDEX idx_posts_deferred ON posts(source_type, queue_status, triage_attempts)
  WHERE queue_status = 'triage_deferred';

-- Cost tracking — extended with subcomponent for heavy-tier breakdown
CREATE TABLE cost_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  run_at TEXT NOT NULL,
  source_type TEXT NOT NULL,
  component TEXT NOT NULL,             -- curated | discovery | triage
  subcomponent TEXT,                   -- summarize | triage | null (for capture)
  item_count INTEGER NOT NULL,
  estimated_cost REAL NOT NULL,
  notes TEXT
);

CREATE INDEX idx_cost_log_source ON cost_log(source_type, run_at);

-- Feedback — extended with source_type
CREATE TABLE feedback (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  received_at TEXT NOT NULL,
  source_type TEXT NOT NULL,
  digest_date TEXT NOT NULL,
  item_id TEXT NOT NULL,
  canonical_id TEXT NOT NULL,
  command TEXT NOT NULL,                -- promote | ignore | save | add-topic | expand | investigate
  argument TEXT,                       -- topic name for add-topic; operator note for investigate
  applied INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_feedback_source ON feedback(source_type);

-- Topic weights — scoped per source
CREATE TABLE topic_weights (
  source_type TEXT NOT NULL,
  topic_name TEXT NOT NULL,
  feedback_count INTEGER NOT NULL DEFAULT 0,
  promote_count INTEGER NOT NULL DEFAULT 0,
  ignore_count INTEGER NOT NULL DEFAULT 0,
  weight_modifier REAL NOT NULL DEFAULT 1.0,  -- Phase 1: always 1.0. Phase 3: per x-feed-intel §5.8.
  last_adjusted_at TEXT,
  PRIMARY KEY (source_type, topic_name)
);

-- Phase 1 invariant: framework code MUST NOT modify weight_modifier (always 1.0).
-- Any tuning experiments must be done in an isolated branch / spec revision.

-- Adapter run log
CREATE TABLE adapter_runs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_type TEXT NOT NULL,
  run_at TEXT NOT NULL,
  component TEXT NOT NULL,             -- curated | discovery | triage | digest
  status TEXT NOT NULL,                -- success | partial | failed
    -- success: all items processed normally
    -- partial: run completed but some items failed (e.g., network errors for some API calls)
    -- failed: entire run failed (API down, auth failure, etc.)
  items_processed INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  duration_seconds REAL
);

CREATE INDEX idx_adapter_runs_source ON adapter_runs(source_type, run_at);

-- Adapter cursor state — persistent checkpoint storage for extractors and digest cutoffs
CREATE TABLE adapter_state (
  source_type TEXT NOT NULL,
  component TEXT NOT NULL,             -- curated | discovery | digest | feedback
  stream_id TEXT NOT NULL DEFAULT 'default',  -- adapter-defined: playlist ID, subreddit, feed URL, topic name, etc.
  checkpoint_json TEXT NOT NULL,       -- opaque JSON blob managed by the adapter (or digest/feedback cutoff state)
  updated_at TEXT NOT NULL,
  PRIMARY KEY (source_type, component, stream_id)
);

-- Digest message tracking — maps sent Telegram messages to digests for reply-to matching
-- One row per sent message part (multi-part digests store one row per part)
CREATE TABLE digest_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_type TEXT NOT NULL,
  telegram_message_id INTEGER NOT NULL,
  digest_date TEXT NOT NULL,
  part_index INTEGER NOT NULL DEFAULT 1,   -- 1-indexed part number within this digest
  part_count INTEGER NOT NULL DEFAULT 1,   -- total parts in this digest delivery
  sent_at TEXT NOT NULL
);

CREATE INDEX idx_digest_messages_telegram ON digest_messages(telegram_message_id);
CREATE INDEX idx_digest_messages_source ON digest_messages(source_type, digest_date);

-- Migration alias table — temporary, for Phase 1b X pipeline migration
CREATE TABLE id_aliases (
  legacy_id TEXT PRIMARY KEY,          -- bare X post ID (pre-migration format)
  canonical_id TEXT NOT NULL,          -- new format: x:{post_id}
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL             -- 45 days after migration
);
```

**Queue status values:**
- `pending` — captured, awaiting triage
- `triaged` — triage complete, included in digest
- `triage_failed` — triage attempted and failed after individual retry; included in digest as raw post with warning
- `triage_deferred` — item exceeded per-item token cap; will be retried next cycle (max 3 attempts, see §5.3.1)
- `expired` — untriaged past TTL; archived, excluded from digest
- `archived` — manually archived or post-digest cleanup

**Data retention:** `adapter_runs` and `cost_log` rows are retained for 90 days, then pruned by a scheduled cleanup job. `posts` with `queue_status` of `expired` or `archived` are retained for 30 days past status change, then pruned. `feedback` and `topic_weights` are retained indefinitely (needed for trend analysis and learning loop).

### 8.1 Migration from x-feed-intel

When the second adapter comes online (Phase 1b.1), the existing X pipeline's state store must be migrated to the multi-source schema. This migration is a standalone task during PLAN — not folded into "Phase 1b extraction" — with its own acceptance criteria.

**Pre-migration prerequisites:**

0. **Quiesce the X pipeline:**
   - `launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.*.plist` for each X pipeline service (capture, attention, feedback listener).
   - Verify no processes running: `pgrep -f "feed-intel\|x-feed-intel"` returns empty.
   - If processes persist: `pkill -f "feed-intel"` and re-verify.
   - Write a lockfile (`~/.feed-intel-migration-in-progress`) as an additional guard — the pipeline startup scripts MUST check for this lockfile and refuse to start if present. **Prerequisite dependency:** The lockfile check must be implemented and deployed in the pipeline code *before* migration is run. This is an acceptance criterion for the migration task — the guard is useless without the code that reads it.
1. **Backup:** Full SQLite database file copy (not just `VACUUM INTO` — preserve WAL state). Vault snapshot via `git add -A && git commit`. **Also back up cursor state files:** copy `capture-state.json`, `feedback-state.json`, and any other pipeline state files to a dated backup directory. These are needed for rollback.
2. **Pre-migration audit:** Verify the live X pipeline's state store schema, cursor JSON format, and table contents match the assumptions below. Specifically: confirm `posts` table columns, confirm `canonical_id` values are bare (no `x:` prefix), confirm cursor JSON structure. Document any divergences and adjust migration steps accordingly.

**Migration procedure (staged, restartable):**

Each stage is independently restartable. A migration state file (`migration-state.json`) in the pipeline's data directory tracks completion:

```json
{
  "started_at": "2026-...",
  "stages": {
    "1_db_schema": { "status": "complete", "completed_at": "..." },
    "2_cursor_state": { "status": "pending" },
    "3_vault_files": { "status": "pending" },
    "4_verification": { "status": "pending" },
    "5_reenable": { "status": "pending" }
  }
}
```

Each stage checks its status before running and skips if already complete. Operations within stages are guarded for idempotency (see per-stage notes).

**Stage 1 — DB schema migration** (single SQLite transaction):
1. Populate `id_aliases` table mapping bare IDs → prefixed IDs **before** rewriting canonical_id: `INSERT INTO id_aliases (legacy_id, canonical_id, created_at, expires_at) SELECT canonical_id, 'x:' || canonical_id, datetime('now'), datetime('now', '+45 days') FROM posts`. This preserves the original bare IDs as the source for alias mapping.
2. Add `source_type TEXT NOT NULL DEFAULT 'x'` column to `posts`, `feedback`, `cost_log`, `topic_weights`. (Idempotency: guard with `SELECT count(*) FROM pragma_table_info('posts') WHERE name='source_type'` before each ALTER.)
3. Update `canonical_id` in `posts` from `{bare_id}` to `x:{bare_id}` for all existing rows. (Idempotency: `UPDATE posts SET canonical_id = 'x:' || canonical_id WHERE canonical_id NOT LIKE 'x:%'`.)
4. Update `canonical_id` in `feedback` table to match new format. (Same idempotency guard.)
5. Add new columns: `triage_attempts INTEGER NOT NULL DEFAULT 0` on `posts`, `routed_at TEXT` on `posts`, `subcomponent TEXT` on `cost_log`. (Same column-exists guard.)
6. Create new tables: `adapter_state`, `adapter_runs` (with `IF NOT EXISTS`), `digest_messages`.
7. Create indexes with `IF NOT EXISTS`: `idx_posts_source_status`, `idx_posts_url_hash`, `idx_posts_deferred`, `idx_cost_log_source`, `idx_feedback_source`, `idx_digest_messages_telegram`, `idx_digest_messages_source`.

**Stage 2 — Cursor state migration:**
8. Validate cursor JSON format: read `capture-state.json` and `feedback-state.json`, parse JSON, verify expected keys exist (e.g., `last_bookmark_id`, `last_search_cursor` for curated/discovery). Log warnings for unexpected keys or missing fields.
9. Migrate X adapter cursor data from `capture-state.json` → `adapter_state` table entries (`source_type='x'`, `component='curated'`, `stream_id='default'`) and (`source_type='x'`, `component='discovery'`, `stream_id` per topic name). For legacy discovery cursors that were not topic-scoped, create `adapter_state` rows per topic using the shared legacy cursor value, then allow divergence over time. **Safety note:** this is safe only if cursor semantics are globally monotonic over a unified stream with topic filters applied post-fetch. If the new discovery implementation uses topic-specific queries, each topic will initially restart from the shared cursor position and diverge — causing some re-fetched (deduplicated) items but no data loss.
10. Migrate feedback listener state from `feedback-state.json` → `adapter_state` (`source_type='x'`, `component='feedback'`, `stream_id='default'`).
11. Migrate existing digest message mappings (if any) → `digest_messages` table with `source_type='x'`.
12. (Idempotency: check `SELECT count(*) FROM adapter_state WHERE source_type='x'` before each insert; skip if rows already exist.)

**Stage 3 — Vault file migration:**
13. Rename existing vault files from `feed-intel-{bare_id}.md` to `feed-intel-x-{bare_id}.md`. Log each rename to a migration manifest file (`migration-renames.json`: `[{"old": "...", "new": "...", "status": "done"}]`). (Idempotency: skip renames where target already exists and source does not.)
14. Update all Obsidian link references across the vault. External script-based renames do NOT trigger Obsidian's internal link updater. The migration script must handle all link variants using a comprehensive regex that captures:
    - Standard wikilinks: `[[feed-intel-{id}]]`
    - Display text: `[[feed-intel-{id}|display text]]`
    - Heading references: `[[feed-intel-{id}#Heading]]`
    - Block references: `[[feed-intel-{id}#^blockid]]`
    - Transclusions/embeds: `![[feed-intel-{id}]]` and `![[feed-intel-{id}|...]]`
    - With `.md` extension: `[[feed-intel-{id}.md]]`

    The regex should match `(!?\[\[)(feed-intel-)({bare_id})((?:#[^\]]*)?(?:\|[^\]]*)?\.?m?d?\]\])` and rewrite only the filename portion, preserving anchors, display text, and embed prefixes. Log each replacement to the migration manifest.

**Stage 4 — Verification:**
15. Verify all `canonical_id` values in `posts` have `x:` prefix.
16. Verify `canonical_id` count in `posts` matches pre-migration count (count parity).
17. Verify all `canonical_id` values in `feedback` have `x:` prefix and reference existing `posts` rows.
18. Verify all renamed vault files exist on disk and old filenames do not.
19. Verify wikilink grep returns zero hits for old-format filenames (using the comprehensive regex from step 14, not just `[[feed-intel-{id}]]`).
20. Verify `adapter_state` contains expected cursor entries: one curated, N discovery (one per topic), one feedback. Validate that `checkpoint_json` parses as valid JSON.
21. Verify `id_aliases` row count matches pre-migration `posts` count and all `expires_at` values are in the future.
22. Spot-check: open 3-5 vault files with known wikilinks and confirm they render correctly in Obsidian.

**Stage 5 — Re-enable:**
23. Update framework configuration to use new schema.
24. Remove lockfile (`~/.feed-intel-migration-in-progress`).
25. `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.*.plist` for each service.
26. Monitor first capture + attention cycle for errors. Verify `adapter_runs` shows successful entries.

**Alias grace period:** For 45 days after migration, the feedback protocol checks `id_aliases` when a `canonical_id` lookup fails. If a legacy ID is found in the alias table, it is transparently resolved to the new canonical ID. After the grace period, alias rows are pruned. This handles late-arriving feedback replies to pre-migration digests.

**Rollback:** If issues arise post-migration: (1) disable launchd services via `launchctl bootout`, (2) restore SQLite DB from Stage 0 backup file copy, (3) restore cursor JSON files (`capture-state.json`, `feedback-state.json`) from Stage 0 backup, (4) reverse vault file renames using the migration manifest from Stage 3 step 13, (5) reverse wikilink replacements using the same manifest, (6) remove lockfile, (7) re-enable legacy X pipeline services via `launchctl bootstrap`. The pre-extraction X pipeline is the rollback target — it continues to work independently of the framework.

## 9. Adapter Lifecycle Management

A core design goal is that adding or removing sources requires no changes to the shared infrastructure.

### 9.1 Adding a Source

1. **Write the adapter manifest** (§6.1) — YAML config file placed in `adapters/`.
2. **Implement the extractor** — `pull_curated` and/or `pull_discovery` functions per §6.2.
3. **Implement the normalizer** — `normalize` function per §6.3.
4. **Write the triage prompt preamble** — per §6.4.
5. **Write the topic config** (if discovery is implemented) — per §6.5.
6. **Run Phase 0 validation** — one-off sample pull + manual skim, same as x-feed-intel Phase 0.
7. **Set `enabled: true`** — the framework picks up the new adapter on next cycle boundary.

No shared infrastructure code changes. No schema migrations (the `source_type` column handles new values automatically). No changes to other adapters.

### 9.2 Removing a Source

1. **Set `enabled: false`** in the adapter manifest. Takes effect at next cycle boundary.
2. Pending items expire per normal TTL rules. No manual cleanup required.
3. Historical data remains in the state store indefinitely (queryable for trend analysis).
4. To fully purge: delete the manifest file and optionally run `DELETE FROM posts WHERE source_type = '{id}'`.

### 9.3 Temporarily Disabling a Source

Set `enabled: false`. Same as removal but the manifest stays in place. Re-enable by setting `enabled: true`. The pipeline resumes capture from the preserved cursor state on the next scheduled run. Any items that aged out during the disabled period are gone (expected and acceptable). If cursor state is stale (e.g., expired pagination tokens), the adapter detects this and resets, logging a warning.

## 10. Boundary Compliance

Extends x-feed-intel §8:

- **Crumb owns:** This framework spec, the x-feed-intel adapter spec, architecture decisions, vault schema, convergence review of triage logic.
- **Tess owns:** Runtime operation of all adapters, triage execution, per-source digest delivery, `_openclaw/feeds/` management, vault promotion, feedback processing, adapter lifecycle management.
- **Bridge protocol:** Unchanged. Tess writes to `_openclaw/inbox/`. Crumb reads.

**Deployment model:** Same as x-feed-intel — Tess-operated service on the Mac Studio. Adapter code and shared infrastructure live outside the vault. Only config, state artifacts, and routed items are vault-resident.

## 11. Risk Register

Inherits all risks from x-feed-intel §9, plus:

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Adapter proliferation overwhelms digest attention | Medium | Medium | Start with 2-3 adapters. Add more only after evaluating signal quality. Per-source digests make it easy to identify and drop low-value sources. |
| YouTube transcript unavailability | Medium | Medium | First-class degraded mode: per-item `transcript_status`, automatic lightweight fallback, Telegram alert on library breakage. Phase 0 quantifies availability rate. |
| YouTube transcript library breakage | Medium | Medium | Circuit breaker: if error rate > 80% for 3 consecutive runs, adapter enters transcript-disabled mode automatically. Requires operator re-enable. See §7.2. |
| YouTube auto-caption ASR quality | Medium | Low | Technical terms may be garbled. Triage preamble instructs LLM to infer from context. Heavy-tier summary extracts claims/tools, not verbatim quotes. |
| Reddit API terms change again | Medium | Medium | Hard Phase 0 gate before implementation. RSS feed fallback preserves basic coverage. Adapter disableable with one config change. |
| Reddit user-agent blocking | Medium | Low | Compliant user-agent string per Reddit API rules. Documented in adapter spec. |
| LLM costs scale linearly with sources | Low-Medium | Medium | Per-adapter cost tracking + framework-wide ceiling + heavy tier cost awareness. YouTube is the expensive one — monitor closely. |
| HN favorites scraping breaks | N/A | N/A | Deferred to Phase 2. Phase 1 is discovery-only. |
| Cross-platform content duplication | Low | Low | Accepted at triage level. Vault router uses `url_hash` to detect collisions and merge into existing file rather than creating duplicates. Phase 3 adds cross-source correlation as signal amplification. |
| Framework abstraction is premature | Medium | Medium | Ship X adapter first (already specified). Extract shared layer only when second adapter is ready. |
| Source starvation under heavy backlog | Low | Medium | Per-source `max_items_per_cycle` cap in attention clock. Round-robin processing order. |
| API deprecation (any third-party API) | Low-Medium | High | Annual Phase 0 re-verification for all adapters. Adapter architecture isolates failures — losing one source doesn't affect others. |
| Telegram message size limits | Low | Low | Auto-split messages exceeding 4,096 chars. `MAX_ITEMS_INLINE` overflow to vault-stored digest file. |
| LLM provider pricing changes | Low-Medium | Medium | Annual cost model re-baseline during Phase 0 re-verification. Per-adapter spending caps and framework ceiling provide immediate protection. |

## 12. Combined Cost Model

| Source | Monthly Est. | Hard Cap | Notes |
|---|---|---|---|
| X (bookmarks + search + triage) | $2.16–$3.81 | $5.00 (X API console) | See x-feed-intel §13 |
| YouTube (API + triage) | $0.85–$1.60 | Free API tier | Cost is almost entirely LLM |
| Reddit (API + triage) | $0.30–$0.60 | Free API tier | Pending Phase 0 API verification |
| Hacker News (API + triage) | $0.10–$0.20 | Free APIs | |
| RSS/Blogs (triage only) | $0.20–$0.50 | No API cost | |
| arxiv (API + triage) | $0.15–$0.30 | Free API | |
| **Baseline total** | **$3.76–$7.01** | | |
| **With 20% headroom** | **$4.51–$8.41** | | |

**Framework-wide soft ceiling:** $15/month. Provides ~2× headroom over projected max, accommodating volume growth, new adapters, and occasional spikes (e.g., heavy-tier outlier transcripts, burst of bookmark activity).

**Cost monitoring:** Per-source breakdown in each digest footer. Heavy-tier summarize/triage split in per-adapter reports. Weekly aggregate summary. Guardrail triggers at 90% of combined ceiling.

## 13. Phasing

### Phase 0: X Adapter + Framework Design Validation
- Proceed with x-feed-intel Phase 0 as specified
- During Phase 0, validate framework assumptions: confirm the normalized format works for X data, confirm the schema supports multi-source queries, confirm digest rendering is parameterizable by source
- Select implementation language (§7.1 of x-feed-intel — resolution carries to the framework)
- **Reddit API verification gate:** Confirm current terms for personal-use scripts. Document findings. If blocked, defer Reddit adapter and note RSS fallback option.

### Phase 1a: X Adapter (Core Pipeline)
- Implement x-feed-intel Phase 1 as specified
- Build with extraction points for shared infrastructure (don't hardcode X assumptions into shared components)
- This is the working pipeline — framework extraction happens after this works

### Phase 1b.1: Framework Extraction + X Migration
- Extract shared infrastructure from the working X pipeline into the framework layer
- Run X pipeline migration (§8.1) — staged DB migration, vault file rename + wikilink update, cursor state migration
- **Gate:** X adapter runs on new framework infrastructure with feature parity to the legacy pipeline. No RSS yet — this proves the extraction works with X alone before adding a second variable.

### Phase 1b.2: RSS Adapter
- Implement RSS adapter — simplest adapter, validates the adapter contract without heavy-tier complexity
- Framework extraction is validated when RSS plugs in without modifying shared code
- Quick win: RSS starts delivering value from curated high-quality feeds immediately

### M-Web: Web Presentation Layer (parallel with M3/M4)

**Pre-implementation (design sprint, ~3-5 days):**
- Set up Paper Pro, establish design system (palette, typography, spacing, component patterns)
- Design core components: digest item card (compact + expanded), action bar, filter bar, date nav, cost dashboard, app shell
- Design light + dark mode variants and mobile breakpoints
- Document design tokens

**Implementation:**
- Vite build tooling: dev server with Express proxy, production static bundle
- Express API server with routes: digest, feedback, costs, health stub
- React SPA: application shell with dark mode from day one, digest view with split-pane layout, all feedback actions, loading/error states
- Cloudflare Tunnel + Access authentication (§5.12.1)
- Cost telemetry dashboard view
- Investigate action: staging, Tess sweep skeleton, investigation brief template (§5.13)
- Telegram digest transition (2-week overlap period, then notification-only)
- Telegram feedback listener refactoring to shared service layer
- Web UI test suite (React Testing Library + jsdom, API route tests)

**Sequencing:** Depends on M2 (X migration) completion — reads from the migrated multi-source schema. Does NOT depend on M3 (RSS). M-Web and M3 can proceed in parallel after M2.

**Gate:** Operator uses the web UI as primary digest surface for 5 consecutive days. Telegram notification links work. All feedback commands functional via web UI. Dark mode validated across all views. Mobile layout usable. Telegram feedback listener uses shared service layer (FIF-W11).

**Tasks (FIF-W01 through FIF-W12):**

| Task | Description | Dependencies |
|------|-------------|--------------|
| FIF-W01 | Paper design sprint: design system + component library (operator review gate before W03) | None |
| FIF-W02 | Express API server: digest routes, feedback endpoint, costs routes, health stub | M2 |
| FIF-W03 | React app scaffold: Vite build tooling, shell, routing, theme system with dark mode (CSS custom properties from day one). Dev server proxies to Express; production build served as static bundle by Express. | FIF-W01 |
| FIF-W04 | Digest view: item list, detail pane, split-pane layout, loading/error states, mobile responsive | FIF-W02, FIF-W03 |
| FIF-W05 | Feedback actions: all 6 commands via API, immediate UI state updates, error handling per action | FIF-W04 |
| FIF-W06 | Cost dashboard view: per-adapter spend, projections, guardrail status | FIF-W02, FIF-W03 |
| FIF-W07 | Cloudflare Tunnel + Access setup, launchd service for cloudflared | FIF-W02 |
| FIF-W08 | Telegram transition: notification-only format, 2-week overlap, then cutover | FIF-W05 |
| FIF-W09 | Investigate action: UI flow, staging to `_openclaw/feeds/investigate/`, Tess sweep skeleton. Note: Tess sweep depends on crumb-tess-bridge dispatch infrastructure — skeleton only until bridge is operational. | FIF-W05 |
| FIF-W10 | Dark mode validation: verify all views (digest, cost, app shell) render correctly in both themes, mobile testing, gate validation | FIF-W04, FIF-W06 |
| FIF-W11 | Telegram feedback listener refactoring: migrate from direct SQLite writes to shared service layer (§5.12.3). Required before M-Web gate closes. | FIF-W02, FIF-W05 |
| FIF-W12 | Web UI test suite: React Testing Library + jsdom for components, supertest for API routes, integrated into `npm test`. Separate `test/web/` directory. | FIF-W03, FIF-W02 |

### Phase 1c: YouTube Adapter
- Implement YouTube adapter — validates the heavy-tier content system
- Run YouTube Phase 0 (transcript availability quantification, quota validation)
- This is the most complex adapter; benefits from having the framework already proven with RSS

### Phase 1d: Remaining Adapters
- HN, Reddit, arxiv adapters — in order of expected signal value (operator's call)
- Each adapter follows the standard lifecycle: manifest → extractor → normalizer → preamble → topic config → Phase 0 → enable
- Adapters can be built and enabled incrementally — no need to ship all at once

### Phase 2: Per-Source Enrichment
- Per x-feed-intel Phase 2 items, generalized:
  - Thread/series expansion (X threads, YouTube playlists, Reddit comment trees)
  - Linked content fetch (HN → article, Reddit link posts → article)
  - HN favorites (curated capture, if reliable mechanism found)
  - Account/channel monitoring
  - Historical trend analysis (cross-source: "what's been hot this week across all sources")
  - Triage refinement from accumulated feedback
  - Semantic Scholar citation counts for arxiv
  - Digest grouping for mature low-volume sources

### Phase 3: Learning Loop
- Per x-feed-intel Phase 3, generalized:
  - Per-source, per-topic weight adjustment
  - Cross-source signal correlation ("this topic is trending on X AND HN AND arxiv") using `url_hash` to detect multi-platform convergence
  - Automated source quality scoring (which sources produce the most promotes vs. ignores?)
  - Topic suggestion based on discovery patterns

## 14. Success Criteria

Inherits x-feed-intel success criteria (§11), plus:

1. A second source adapter (RSS) can be added to the framework without modifying shared infrastructure code.
2. Each enabled source delivers its own digest at its configured cadence and time.
3. Per-source cost tracking (including heavy-tier summarize/triage split) is accurate and visible in digests.
4. Disabling an adapter stops all capture and digest activity for that source within one pipeline cycle.
5. The framework-wide monthly cost stays under $15.
6. Danny can evaluate each source's signal quality independently and make informed add/drop decisions based on digest history and feedback data.
7. The vault router correctly detects cross-source URL collisions and merges rather than duplicates.
8. The web UI renders digests from all enabled sources with per-item feedback actions, and the operator uses it as the primary digest reading surface over Telegram.

## 15. Dependencies

Inherits x-feed-intel dependencies (§14), plus:

- YouTube Data API credentials (Google Cloud Console — free tier)
- Reddit API credentials (OAuth script app — requires Reddit account). **⚠️ Must re-verify API terms before implementation (Phase 0 gate).**
- `feedparser` or equivalent RSS parsing library
- arxiv API access (public, no credentials)
- YouTube transcript library (unofficial — e.g., `youtube-transcript-api`). **⚠️ Unofficial dependency; monitor for breakage.**
- Sufficient LLM budget for multi-source triage (~$4-8/month LLM costs at steady state)
- Cloudflare account + registered domain (Cloudflare Tunnel + Access for web UI authentication, ~$10/yr for domain)
- `cloudflared` daemon (Cloudflare Tunnel client, installed on Mac Studio)

## 16. Changelog

### v0.3.5 (2026-02-25) — Web UI Tech Stack Revision

Revised:
- §5.12.2: Tech stack changed from Express/EJS (server-rendered) to Express API + React SPA + Vite + Tailwind. react-router locked (not optional). Paper design tool workflow added for operator design review and iteration. Rationale: real-time interaction requirements, mission control extensibility, component reuse.
- §5.12.3: Added API abstraction layer between frontend and SQLite. Seven core routes defined. Service layer shared between web UI and Telegram feedback listener. Telegram listener refactoring required before M-Web gate (FIF-W11).
- §5.12.4: Directory convention updated for React app structure with Vite build config, services layer, and design artifacts directory.
- §5.12.5: Added layout model (split-pane desktop with rationale, stacked mobile), progressive disclosure pattern, per-item state indicators, and loading/error state requirements.
- §5.12.7: Added 2-week transition period with both full digest and notification summary before cutover.
- §13 M-Web: Expanded task list (FIF-W01–W12) to include Paper design sprint, build tooling, dark mode validation, Telegram listener refactoring, web UI test suite, and investigate UI. Added design sprint pre-implementation phase. Dark mode integrated into theme system (W03) rather than bolt-on task.

Added:
- §5.12.8: Design workflow with Paper as operator visual review surface, MCP integration for implementation bridge, design token documentation, and fallback path.

Source: claude.ai session 2026-02-25, revised by Crumb review 2026-02-25. Builds on web UI proposal (x-feed-intel/design/feed-intel-web-ui-proposal.md) and decision analysis from same session.

### v0.3.4 (2026-02-24) — Web Presentation Layer

Added:
- §5.12 (Web Presentation Layer): Cloudflare Tunnel + Access hosting, Express/EJS/Tailwind stack, direct SQLite read, src/web/ directory convention, digest rendering, feedback HTTP API, Telegram notification transition. Decisions from x-feed-intel Session 2026-02-23c.
- §5.13 (Investigate Action): Sixth feedback command for deep-dive research dispatch. Async Tess sweep, volume cap, investigation brief template. Blocked on web UI deployment.
- M-Web phase in §13: parallel track with M3/M4 after M2 completion. 8 tasks (FIF-W01–FIF-W08).
- Success criterion §14.8 (web UI as primary digest surface)
- Dependencies: Cloudflare account, domain, cloudflared daemon

Updated:
- §5.6: Web UI transition note (Telegram digest → notification-only)
- §5.7: HTTP feedback path note (dual Telegram + HTTP, investigate command)
- §8: feedback.command enum documented with investigate

Source: Web UI proposal (originally x-feed-intel/design/, referenced in place). All 7 decision points resolved 2026-02-23. Gap identified 2026-02-24: decisions never landed in framework spec.

### v0.3.3 (2026-02-23) — Migration Plan Scoped Review

Scoped 3-model follow-up review (GPT-5.2, DeepSeek V3.2, Grok 4.1) focused on §8.1 migration plan feasibility and rollback completeness. All 3 reviewers independently assessed "needs rework." Review note: `_system/reviews/2026-02-23-feed-intel-framework-migration.md`.

**Fixes applied:**
- Alias population reordered before canonical_id rewrite to preserve source data for `id_aliases`
- Migration state file (`migration-state.json`) designed with per-stage completion tracking
- All operations guarded for idempotency (column-exists checks, `IF NOT EXISTS`, `WHERE NOT LIKE 'x:%'`)
- Wikilink replacement expanded to comprehensive regex covering display text, heading/block refs, transclusions, embeds, `.md` extensions
- Cursor JSON format validation added before migration (Stage 2 step 8)
- Per-topic cursor duplication safety note: safe only if cursor semantics are globally monotonic
- Backup scope expanded to include cursor JSON files (not just DB + vault)
- Launchd quiesce made concrete: `launchctl bootout` + `pgrep` verification + lockfile guard
- Stage 4 verification expanded: count parity, referential checks, alias coverage, cursor JSON validation, comprehensive wikilink regex, spot-check step
- Rollback procedure updated: includes cursor JSON restoration and lockfile cleanup

### v0.3.2 (2026-02-23) — Peer Review Synthesis

Incorporates findings from five peer reviewers (GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast, Sonar Reasoning Pro). Full review note: `_system/reviews/2026-02-23-feed-intel-framework-specification.md`.

**Must-fix items resolved:**
- **A1:** `adapter_state.component` enum expanded to include `feedback` — governance review (G-03) introduced inconsistency by adding feedback cursor migration without updating schema comment. (§8)
- **A2:** Research promotion path added as new §5.11 — hybrid model: research process flags `promotion_candidate`, operator confirms via digest annotation or `save` command, promotes directly to `Sources/` (no intermediate queue). Operator-initiated promotion is the primary path; automated flagging is the discovery mechanism. Conservative flagging threshold (high confidence + 2+ vault cross-refs). 5/5 reviewer consensus, design resolved 2026-02-25. (§5.11)
- **A3:** Migration plan §8.1 rewritten — replaced "atomic" framing with staged, restartable 5-stage procedure: quiesce → DB migration → cursor state → vault files + wikilink update → verification → re-enable. Added pre-migration audit prerequisite, rollback procedure, and migration manifest logging. Migration captured as standalone PLAN task. (§8.1)
- **A4:** `triage_attempts INTEGER DEFAULT 0` column added to `posts` table with partial index `idx_posts_deferred` — moved from `triage_json` for efficient deferred retry queries. (§8)
- **A5:** Collision handling `routed_at` semantics tightened — appended items now set `routed_at`, collision query uses `ORDER BY routed_at ASC LIMIT 1` for deterministic resolution, collision merge updates existing file frontmatter with `additional_sources` list. (§5.5)
- **A6:** `digest_messages` table extended with `part_index` and `part_count` columns for multi-part digest feedback resolution. (§8)

**Should-fix items resolved:**
- **A7:** `effective_tier` invariant refined — now explicitly states it may influence `content.excerpt` for heavy-tier summarization while preserving core identity field immutability. (§5.1)
- **A8:** Hash truncation standardized — RSS `canonical_id` changed from `sha256[:12]` to `sha256[:16]`, matching `url_hash` convention. (§7.5)
- **A9:** Cost guardrail timing clarified — guardrail state evaluated at cycle boundary, consistent with configuration snapshot rule. Runtime override flag read at next manifest snapshot. (§5.8)
- **A10:** Attention clock failure isolation specified — each source's triage wrapped in error isolation; one adapter's crash doesn't abort the run. (§4.1)
- **A11:** Digest delivery architecture clarified — delivery is a separate scheduled event (separate launchd service), not part of the triage script. Late-mode ordering defined: primary by `digest.time`, secondary by adapter `id`. Manifest validation of `digest.time` constraint added. (§4.1)
- **A12:** Phase 1b split into 1b.1 (framework extraction + X migration, feature-parity gate) and 1b.2 (RSS adapter). Structural enforcement of "don't add a second variable until the first is stable." (§13)
- **A13:** Collision merge frontmatter strategy defined — existing file gains `additional_sources` list. (§5.5)
- **A14:** Adapter health/degraded state defined — >3 consecutive failures in 24 hours triggers degraded state with digest status line and Telegram alert. Optional `health_check()` hook for silent failure detection. (§5.9)
- **A15:** Aggregate daily cost ceiling added ($1.00/day default) to prevent multi-source backlog days from consuming disproportionate monthly budget. (§5.8)
- **New:** API assumptions disclaimer added to §7 header — per-source specs are pre-Phase-0 assumptions, not authoritative. (§7)

**Deferred to PLAN or Phase 2:**
- Run-level token/cost budget (per-adapter caps + framework ceiling may suffice for Phase 1)
- `source_instances` queryability (Phase 2 analytics)
- Research content storage in feedback schema (vault file is the durable artifact)
- Environment-specific config management (single-operator deployment)
- Weekly quality score materialization (implementation detail)
- Foreign-key consistency stance (application-level integrity standard for SQLite)

### v0.3.1 (2026-02-23) — Governance Review

Pre-PLAN governance review checking spec against Crumb conventions and x-feed-intel implementation reality.

**Fixes:**
- **G-01:** Removed `status` field from spec frontmatter — project docs don't carry status per file-conventions.md.
- **G-02:** Added `digest_messages` table to §8 schema — used by feedback listener for reply-to matching. Scoped per `source_type` for multi-source operation.
- **G-03:** Added cursor state migration sub-steps to §8.1 step 7 — explicit migration from `capture-state.json` and `feedback-state.json` into `adapter_state` table entries.
- **G-04:** Enumerated columns and indexes in §8.1 step 8 — `routed_at` on posts, `source_type`/`subcomponent` on cost_log, plus four named indexes.
- **G-05:** Updated frontmatter `updated` date.

**Verified (no action needed):**
- G-06: Vault path references (`_openclaw/config/`, `_openclaw/feeds/`) — all valid on disk.
- G-07: Cross-references to x-feed-intel spec sections — all valid.
- G-08: Implementation drift (bare canonical_id, file-based cursor state, hard-coded schedules) already accounted for in §8.1 migration plan and §13 phasing.

### v0.3 (2026-02-21) — Second Peer Review Synthesis

Incorporates findings from six reviewers (DeepSeek V3.2-Thinking, Gemini 3 Pro, ChatGPT GPT-5.2, Perplexity/Grok, Grok, Claude Opus 4.6 pre-review). Full synthesis document: `feed-intel-framework-v0_2-peer-review-synthesis.md`.

**Must-fix items resolved:**
- **CF1:** `triage_deferred` termination condition — retry counter (max 3 attempts), force lightweight triage after cap, skip re-summarization on retry. Deferred items retry next cycle, count against `max_items_per_cycle`. (§5.3.1)
- **CF2:** Attention clock two-phase model — fixed-time triage phase + delivery scheduler. `triage_run_budget_minutes` default 45. Late digest handling. `digest.time` is delivery timestamp, not triage trigger. (§4.1, §5.6)
- **CF6:** Weekly digest accumulation boundaries — `last_digest_cutoff_at` cursor in `adapter_state` (component: `digest`). Triage runs daily regardless of cadence. Triaged items exempt from discovery expiry TTL. (§5.6, §8)

**Should-fix items resolved:**
- **UF1:** X adapter (and all link-sharing adapters) `url_hash` derived from external content URL, not platform permalink. URL-first principle added as normalizer guideline. (§5.1, §6.3, §7.1)
- **CF3:** URL canonicalization — framework-provided `canonicalize_url()` helper function required for all adapters. Concrete steps documented. URL shortener resolution is extractor responsibility to preserve normalizer determinism. (§6.3)
- **CF4:** YouTube transcript circuit breaker — error rate > 80% across 3 consecutive runs triggers transcript-disabled mode. Per-request jitter delay. Hard cap 50 transcript attempts per run. Operator re-enable required. (§7.2)
- **CF5:** Cost guardrail heavy-tier lever — heavy-tier adapters reduce `max_items_per_cycle` by 50% when guardrail active. Forward reference to D8. (§5.8)
- **UF2:** Vault router lookup path — `routed_at` column added to `posts` table. Explicit collision query: `SELECT canonical_id FROM posts WHERE url_hash = ? AND routed_at IS NOT NULL`. (§5.5, §8)
- **UF3:** Collision detection includes items routed earlier in current attention clock run via write-through or in-memory tracking. (§5.5)
- **UF4:** Zombie cursor — `stale_cursor_threshold_days` (default 7) in adapter manifest. Cold start on stale cursor with warning. (§6.2)
- **UF5:** Reddit RSS fallback explicit contract — tier changes, disabled capabilities, and transition requirements documented. (§7.3)
- **UF6:** Missing preamble error handling — skip triage for cycle, log error, Telegram alert. No silent fallback. (§6.4)
- **UF7:** Cursor update atomicity — framework persists `updated_state` only after full pipeline success. (§6.2)
- **UF8:** Missing `manifest_version` — rejected with error, Telegram alert, other adapters continue. (§6.1)
- **UF11:** Telegram split-message synchronous delivery with 500ms inter-part delay. (§5.6)
- **UF12:** `effective_tier` invariant — only affects triage processing path, not normalization outputs. (§5.1)
- **UF13:** Discovery cursor `stream_id` SHOULD be `topic.name` for independent per-topic tracking. (§6.2)
- **UF14:** Cost cap exceeded behavior — capture and triage paused until month boundary or operator cap raise. Items expire per TTL. (§5.8)
- **UF15:** Per-adapter quality score (`promotes / total_items`, trailing 30 days) added to weekly aggregate summary. (§5.6)

**Housekeeping:**
- HN Algolia API URL corrected from `http` to `https`. (§7.4)
- `triage_deferred` queue status description updated to reference retry cap. (§8)
- `adapter_state.component` values expanded to include `digest` for weekly cutoff tracking. (§8)
- `topic_weights` Phase 1 invariant: `weight_modifier` MUST NOT be modified by framework code. (§8)
- Data retention policy: `adapter_runs` and `cost_log` retained 90 days; expired/archived `posts` retained 30 days; `feedback` and `topic_weights` retained indefinitely. (§8)
- Within-source dedup merge semantics made explicit (append `source_instances`, update `last_seen_at`). (§5.2)
- LLM provider pricing changes added to risk register. (§11)
- First-to-route wins documented as known Phase 1 simplification with Phase 2 promotion path. (§5.5)

**Deferred to Phase 2+:**
- Vault router tier-aware promotion (higher-tier triage replaces lower-tier primary)
- Per-adapter `reduce_load()` callback for granular guardrail behavior (D8, unchanged)
- Global topic config / topic registry
- Transcript provider abstraction interface

### v0.2 (2026-02-21) — Post-Peer-Review Consolidation

Incorporates findings from five peer reviews (DeepSeek V3.2, Gemini 3 Pro, ChatGPT GPT-5.2, Perplexity/Grok, Grok).

**Must-fix items resolved:**
- **F1:** Adapter cursor/state persistence defined — `adapter_state` table with `(source_type, component, stream_id)` key, opaque JSON checkpoint. Extractor function signatures updated to `pull_*(state) → (items, updated_state)`. (§6.2, §8)
- **F2:** Per-item tier override — `content.effective_tier` field added to unified format. Triage engine uses tier resolution order: item override → adapter manifest default. (§5.1, §5.3.1, §6.3)
- **F3:** Migration plan — atomic `canonical_id` update across all tables, vault file rename, `id_aliases` table with 45-day grace period for late feedback resolution. (§8.1)
- **F4:** YouTube transcript retrieval — elevated to first-class degraded mode with per-item `transcript_status`, automatic lightweight fallback, library breakage alerting, Phase 0 quantification requirement. (§7.2)
- **F5:** Cross-platform vault collision — `url_hash` field added to unified format and `posts` table. Vault router performs secondary URL-hash check on write; first-to-route wins, subsequent routes append discovery note. (§5.1, §5.5, §8)
- **F6:** Attention clock execution model — defined as single orchestrated run: one snapshot, sequential per-source triage, staggered digest delivery. (§4.1)
- **F7:** Canonical ID prefix consistency — short prefixes (`x`, `yt`, `hn`, `rss`, `reddit`, `arxiv`) used throughout. Invariant added: prefix MUST equal adapter `id`. (§5.1, §6.3)
- **F8:** Enable/disable race condition — configuration snapshot rule: manifests loaded at cycle start, mid-cycle changes ignored. (§4.1)

**Should-fix items resolved:**
- **S1:** Dedup Store renamed from "Global Dedup Engine" with explicit within-source scope note. (§5.2)
- **S2:** Reddit API verification elevated to hard Phase 0 gate in risk register and dependencies. RSS feed fallback documented. (§7.3, §11, §13, §15)
- **S3:** HN favorites explicitly deferred to Phase 2. (§7.4)
- **S4:** Error/failure taxonomy added — per-item reject vs per-run fail, partial success definition, normalizer determinism requirement. (§5.10, §6.3)
- **S5:** RSS URL canonicalization required before hashing for `canonical_id` and `url_hash`. (§7.5, §6.3)
- **S6:** Manifest `manifest_version` field added with framework validation. (§6.1)
- **S7:** Triage API contract paragraph added for preamble authors. (§5.3)
- **S8:** `search_query` required for discovery source instances. (§5.1, §6.3)
- **S9:** `cost_log.subcomponent` field added for heavy-tier summarize/triage cost breakdown. (§5.3.1, §5.8, §8)
- **S10:** Missing indexes added on `feedback(source_type)` and `cost_log(source_type, run_at)`. (§8)
- **S11:** Per-source `max_items_per_cycle` cap to prevent source starvation under backlog. Round-robin attention clock processing order. (§5.9)
- **S12:** Per-item token cap (12,000 tokens) with `triage_deferred` queue status for outliers. (§5.3.1, §8)
- **S13:** arxiv default sort `sortBy=submittedDate` specified. (§7.6)
- **S14:** Cost estimate includes 20% headroom buffer. (§12)
- **S15:** YouTube triage preamble updated to weight `viewCount` and `commentCount` over `likes` (likes may be hidden). (§7.2)
- **S16:** Reddit user-agent format requirement documented. (§7.3)
- **S17:** YouTube heavy-tier pre-summarization truncation rule (default 8,000 tokens). (§5.3.1)
- **S18:** Cost guardrail behavior for curated-only adapters explicitly defined (not throttled). (§5.8)
- **S19:** `adapter_runs.status` values (`success | partial | failed`) defined. (§5.10, §8)
- **S20:** Liveness check uses declarative `liveness_max_gap_minutes` from manifest instead of cron parsing. (§5.9, §6.1)
- **S21:** Digest cadence (`daily | weekly`) and `min_items` threshold added to manifest and digest spec. (§5.6, §6.1)
- **S22:** Telegram 4,096-char message limit handling documented (auto-split). (§5.6)
- **S23:** `metadata.platform_specific` escape hatch added for adapter-specific metadata. (§5.1)
- **S24:** `triage_deferred` added to queue status enum. (§8)

**New risk register entries:**
- YouTube transcript library breakage (§11)
- YouTube auto-caption ASR quality (§11)
- Reddit user-agent blocking (§11)
- Source starvation under heavy backlog (§11)
- API deprecation for third-party APIs (§11)
- Telegram message size limits (§11)

**Phasing changes:**
- Phase 1b changed from YouTube to RSS (simpler adapter for framework validation). YouTube moved to Phase 1c. (§13)
- Reddit API verification added as Phase 0 gate. (§13)

**Deferred to Phase 2+:**
- D1: HN favorites (curated capture)
- D2: Linked content fetch (HN articles, Reddit link posts)
- D3: Cross-source signal correlation (using `url_hash` for multi-platform detection) — Phase 3
- D4: Digest grouping for low-volume sources
- D5: Semantic Scholar citation counts for arxiv
- D6: Adapter SDK / base class (PLAN-phase implementation concern)
- D7: Simulation/dry-run mode for Phase 0 validation
- D8: Per-adapter `reduce_load()` callback for granular cost guardrail behavior

### v0.1 (2026-02-21) — Initial Draft

- Framework architecture extracted from x-feed-intel v0.4.1
- Adapter contract defined (manifest, extractor, normalizer, triage preamble, topic config)
- Source adapter specs for X (reference), YouTube, Reddit, HN, RSS, arxiv
- Unified content format with content tiers (lightweight/standard/heavy)
- Per-source digest model with independent scheduling
- Adapter lifecycle management (add/remove/disable)
- Extended state store schema for multi-source operation
- Combined cost model and framework-wide budget ceiling
- Phasing plan: X first → extract framework → YouTube → remaining adapters
