---
type: reference
status: active
domain: software
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# SQLite Schema Reference

All SQLite databases used by the Feed Intel Framework (FIF) and Mission Control dashboard.

**Architecture source:** [[04-deployment]] §Storage, [[03-runtime-views]] §Feed Pipeline

---

## Databases

| Database | Path | Size | Mode | Owner |
|----------|------|------|------|-------|
| **pipeline.db** | `~/openclaw/feed-intel-framework/state/pipeline.db` | ~13 MB | WAL | FIF pipeline |
| **attention-replay.db** | `_openclaw/data/attention-replay.db` | ~4 KB | Standard | Vault (dev/test) |

`pipeline.db` is the production database. `attention-replay.db` is a development artifact.

---

## pipeline.db — Tables

### posts

Core content store. Every feed-intel item lands here.

| Column | Type | Purpose |
|--------|------|---------|
| `canonical_id` | TEXT PK | Unique item identifier (e.g., `x:123456`, `rss:abcdef`) |
| `source_type` | TEXT | Source adapter (`x`, `rss`, `yt`, `hn`, `arxiv`) |
| `url_hash` | TEXT | SHA hash of canonical URL (cross-source dedup) |
| `queue_status` | TEXT | `pending` → `triaged` → `archived` / `expired` |
| `queued_at` | TEXT | ISO 8601 — when item entered the queue |
| `triaged_at` | TEXT | ISO 8601 — when triage completed |
| `routed_at` | TEXT | ISO 8601 — when written to vault |
| `triage_json` | TEXT | JSON blob — priority, confidence, action, tags, assessment |
| `metadata_json` | TEXT | JSON blob — source-specific metadata (author, title, URL) |

**Indexes:**
- `idx_posts_source_status` — query by source + status (hot path)
- `idx_posts_deferred` — retry tracking for deferred items
- `idx_posts_queued_at` — TTL cleanup scans
- `idx_posts_url_hash` — cross-source dedup

**Row count:** ~4,465 (49% X, 44% RSS, 5% YouTube, 2% HN, <1% arXiv)

**Status distribution:** ~27% archived, ~41% triaged, ~31% expired, <1% pending

### dashboard_actions

**Owned by Mission Control dashboard.** Queue for operator triage actions.

| Column | Type | Purpose |
|--------|------|---------|
| `canonical_id` | TEXT | Item identifier (joins to `posts.canonical_id`) |
| `action` | TEXT | `promote` / `skip` / `delete` |
| `metadata` | TEXT | Optional JSON (e.g., `{"kb_tag": "kb/software-dev"}`) |
| `created_at` | TEXT | ISO 8601 — when operator acted |
| `consumed_at` | TEXT | ISO 8601 — when feed-pipeline skill processed (NULL = pending) |

**Row count:** ~1,153

**Join pattern:** `dashboard_actions.canonical_id = posts.canonical_id`

### adapter_state

Cursor checkpoints per source/component/stream.

| Column | Type | Purpose |
|--------|------|---------|
| `source_type` | TEXT | Source adapter |
| `component` | TEXT | Pipeline component (`curated`, `discovery`, `digest_items`) |
| `stream_id` | TEXT | Stream identifier (e.g., `default`, `2026-03-14`) |
| `state_json` | TEXT | JSON — cursor position, timestamps, ID mappings |

**Primary key:** `(source_type, component, stream_id)`

**Row count:** ~57

### adapter_runs

Pipeline execution history.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INTEGER PK | Auto-increment |
| `source_type` | TEXT | Source adapter |
| `run_type` | TEXT | `capture` / `triage` / `route` |
| `status` | TEXT | `success` / `partial` / `failed` |
| `items_processed` | INTEGER | Count of items in this run |
| `duration_ms` | INTEGER | Run duration in milliseconds |
| `started_at` | TEXT | ISO 8601 |
| `completed_at` | TEXT | ISO 8601 |
| `error_json` | TEXT | JSON — error details (NULL on success) |

**Index:** `idx_adapter_runs_source`

**Row count:** ~68

**Retention:** 90 days

### digest_messages

Telegram message ID ↔ digest item mapping for feedback resolution.

| Column | Type | Purpose |
|--------|------|---------|
| `telegram_message_id` | TEXT | Telegram message identifier |
| `canonical_id` | TEXT | Item identifier (joins to `posts.canonical_id`) |
| `source_type` | TEXT | Source adapter |
| `digest_date` | TEXT | Date of the digest batch |
| `short_id` | TEXT | Short label used in digest (e.g., `A01`) |

**Indexes:**
- `idx_digest_messages_telegram` — feedback reply-to matching
- `idx_digest_messages_source` — digest date lookups

**Row count:** ~118

### cost_log

LLM cost tracking per triage operation.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INTEGER PK | Auto-increment |
| `source_type` | TEXT | Source adapter |
| `model` | TEXT | LLM model used (e.g., `claude-haiku-4-5`) |
| `input_tokens` | INTEGER | Input tokens consumed |
| `output_tokens` | INTEGER | Output tokens generated |
| `estimated_cost` | REAL | Estimated cost in USD |
| `created_at` | TEXT | ISO 8601 |

**Row count:** ~47 (~$3.45 total)

**Retention:** 90 days

### feedback

Feedback commands from Telegram/dashboard. Currently unused in production.

| Column | Type | Purpose |
|--------|------|---------|
| `canonical_id` | TEXT | Item identifier |
| `feedback_type` | TEXT | Feedback classification |
| `source` | TEXT | Where feedback came from |
| `created_at` | TEXT | ISO 8601 |

**Row count:** 0

### topic_weights

Per-source topic feedback weights. Phase 3 feature, disabled in Phase 1.

**Row count:** 0

### id_aliases

Migration table for ID remapping. Empty (migration completed).

**Row count:** 0

---

## attention-replay.db — Tables

Development/testing database for attention cycle prototyping.

### cycles

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INTEGER PK | Cycle identifier |
| `model` | TEXT | LLM model used |
| `input_tokens` | INTEGER | Tokens consumed |
| `output_tokens` | INTEGER | Tokens generated |
| `status` | TEXT | Cycle status |

**Row count:** 2

### items

| Column | Type | Purpose |
|--------|------|---------|
| `item_id` | TEXT PK | Item identifier |
| `cycle_id` | INTEGER | FK to cycles |
| `domain` | TEXT | Life domain (software, career, learning, etc.) |
| `action_class` | TEXT | `do` / `decide` / `plan` / `track` / `review` / `wait` |
| `object_id` | TEXT | Source object identifier |
| `source_path` | TEXT | Vault file path |

**Indexes:** `idx_items_cycle_id`, `idx_items_object_id`, `idx_items_source_path`

**Row count:** 14

### actions / aliases

Audit log and ID remapping tables. Both empty.

---

## Ownership Boundaries

| Table | Owner | Dashboard Access | Feed-Pipeline Access |
|-------|-------|-----------------|---------------------|
| `posts` | FIF pipeline | Read-only | Read-only |
| `dashboard_actions` | **Dashboard** | Read-write | Read + set `consumed_at` |
| `adapter_state` | FIF pipeline | Read-only | — |
| `adapter_runs` | FIF pipeline | Read-only (status display) | — |
| `digest_messages` | FIF pipeline | Read-only (delivery tracking) | — |
| `cost_log` | FIF pipeline | Read-only (cost display) | — |
| `feedback` | FIF pipeline | — | — |
| `topic_weights` | FIF pipeline | — | — |

**Join contract:** `canonical_id` is the common key between `posts` and `dashboard_actions`.

**No foreign key constraints declared** — referential integrity is enforced at the application level.

---

## Retention Policy

| Table | Retention | Trigger |
|-------|-----------|---------|
| `posts` (expired/archived) | 30 days post-status-change | Pruned by TTL cleanup |
| `adapter_runs` | 90 days | Pruned by TTL cleanup |
| `cost_log` | 90 days | Pruned by TTL cleanup |
| `feedback` | Indefinite | — |
| `topic_weights` | Indefinite | — |

---

## Concurrency

`pipeline.db` uses WAL (Write-Ahead Log) mode. This allows:
- FIF pipeline writes (capture, triage, routing) concurrent with
- Dashboard API reads (Express BFF, read-only connection)
- Feed-pipeline skill sync-back writes (`consumed_at` updates)
