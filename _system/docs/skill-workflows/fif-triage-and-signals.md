---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# FIF Triage & Signal Processing

The Feed Intelligence Framework captures content from multiple sources (X, RSS, HN, arXiv, YouTube), runs daily triage via Haiku, and routes high-signal items to the vault. Crumb's `/feed-pipeline` skill handles the final promotion step.

## The Pipeline

1. **Capture clock (launchd, per-adapter schedules)** — adapter extractors fetch content, normalize to unified format, dedup against `pipeline.db` (SQLite), land in pending queue.
2. **Attention clock (daily, 07:00)** — triage engine (Haiku 4.5) scores pending items: priority, tags, `why_now`, recommended action, confidence. Vault snapshot (project frontmatter, `operator_priorities.md`, recent session summaries) provides context.
3. **Vault routing** — items meeting the routing bar are written to `_openclaw/inbox/` as `feed-intel-{source}-{canonical_id}.md`. Each file contains triage frontmatter, an excerpt, and the source link.
4. **Telegram digest** — all triaged items are delivered as a daily per-source digest, grouped by priority. Items get short IDs (A01, A02…) for feedback commands: `promote`, `save`, `ignore`, `add-topic`, `expand`, `research`.
5. **Dashboard triage** — the Mission Control Intelligence page shows the pipeline section. Operators can skip, delete, or queue items for promotion. Queued promotions land in the `dashboard_actions` table in `pipeline.db`.
6. **Crumb processing** — `/feed-pipeline` skill processes the inbox and dashboard queue (see below).

DB path: `~/openclaw/feed-intel-framework/state/pipeline.db` (override: `FIF_DB_PATH` env var).

## Mission Control Dashboard

The Intelligence page (Phase 1, Mission Control project) surfaces the FIF pipeline section. Operators can:
- **Skip** — immediate, no vault write
- **Delete** — immediate, removes from queue
- **Promote** — queued: writes a row to `dashboard_actions` with `action: 'promote'` and optional `kb_tag` override. The feed-pipeline skill consumes this queue.

Refresh: manual pull. Dashboard is at `repo_path: ~/openclaw/crumb-dashboard`, served via Cloudflare Tunnel + Access.

## Telegram Integration

Tess delivers one digest per source per day at staggered times. Feedback commands reply inline:
- `promote [ID]` — operator marks item for vault promotion
- `save [ID]` — routes to `_openclaw/feeds/kb-review/` for Crumb review
- `research [ID]` — dispatches bridge research job; output lands in `_openclaw/feeds/research/`
- `ignore [ID]` — dismisses item

Telegram is transitioning to notification-only as the dashboard matures (M-Web kill-switch at MC M3, 2-week overlap period).

## /feed-pipeline Skill

Invoke with: "process feed items", "feed pipeline", "promote inbox items", "clear feed backlog".

Two entry paths:
- **Dashboard path (Step 0):** Query `dashboard_actions` for `action='promote' AND consumed_at IS NULL`. Human judgment already applied — skip permanence eval, run full promotion, mark `consumed_at`.
- **Inbox path (Steps 1–6):** Glob `_openclaw/inbox/feed-intel-*.md`, classify into tiers, process operator-selected tiers. Always reports counts first before processing.

Tier routing:
- **Tier 1** (`priority: high` + `confidence: high` + `action: capture`) — permanence eval → auto-promote (1a) or review queue (1b)
- **Tier 2** (`action: test` or `add-to-spec`) — extract one-line action, route to project run-log, delete source
- **Tier 3** — no action; TTL cron purges after 14 days

Circuit breaker: >10 Tier 1 items → all route to review queue instead of auto-promote (classifier drift signal).

## Signal-Note Output

Promoted items become `Sources/signals/[source_id].md` with:
- `type: signal-note`, `skill_origin: feed-pipeline`, `topics: [moc-signals]`
- `source` block: `source_id`, `source_type`, `canonical_url`, `date_ingested`, `provenance` (including `dashboard_promote: true` for dashboard-queued items)
- `tags: [kb/[mapped-tag]]` — Crumb assigns canonical `#kb/` tags; FIF routing tags (e.g., `crumb-architecture`) are never used in vault notes

Registered in `Domains/Learning/moc-signals.md` Core section. If active projects are relevant (Q4 eval), a cross-post entry is appended to those projects' `run-log.md`. Source file deleted from inbox after promotion.

Review-queue items (Tier 1b) land in `_openclaw/inbox/review-queue-YYYY-MM-DD.md` for operator decision.
