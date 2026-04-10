---
type: how-to
status: active
domain: software
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# How to Triage Feed Content

**Problem:** The Mission Control dashboard has feed-intel items waiting for triage. You need to review them and decide: promote to the vault, skip, or delete.

**Architecture source:** [[03-runtime-views]] §Mission Control, [[skills-reference]] §feed-pipeline

---

## Prerequisites

- Mission Control dashboard running (Cloudflare Tunnel + Access)
- FIF pipeline has processed items into `pipeline.db`
- Browser with Cloudflare Access authentication

---

## Open the Triage Interface

Navigate to Mission Control → **Intelligence page** → **Pipeline** section.

The KPI strip at the top shows:
- Signals today and this week (with sparkline)
- Per-source breakdown (X, RSS, YouTube, HN, arXiv) with tier distribution
- Cost today vs. $1.50 ceiling
- Pipeline health status

---

## Review Signals

Signals appear as cards in the digest panel, grouped by source, tier, or topic.

Each card shows:
- Headline and source
- Tier classification (T1/T2/T3)
- Timestamp
- Action buttons

Click a card to expand: full content, enriched context, and research results (if available).

---

## Triage Actions

Three actions available per signal:

| Action | Effect | Vault Impact |
|--------|--------|-------------|
| **Skip** | Removes from view | None — no vault write |
| **Delete** | Removes from queue | None — item purged |
| **Promote** | Queues for feed-pipeline skill | Signal-note created in `Sources/signals/` on next pipeline run |

### Promote with Tag Override

When promoting, you can optionally select a `#kb/` tag from the dropdown. This overrides the auto-mapped tag from FIF triage. Use this when:
- The auto-mapped tag is wrong
- The item spans multiple domains (select the primary one)
- No auto-mapping exists

If you leave the tag empty, the feed-pipeline skill auto-maps from FIF triage tags.

---

## What Happens After Triage

1. **Skip/Delete:** Immediate — signal disappears from the dashboard. Row written to `dashboard_actions` table.

2. **Promote:** Row written to `dashboard_actions` with `action='promote'` and `consumed_at=NULL`. The signal stays visible in the dashboard (pending state) until the feed-pipeline skill processes it.

3. **Feed-pipeline processing:** Next time the operator runs the feed pipeline, Step 0 queries `dashboard_actions` for unconsumed promotions. For each:
   - Creates signal-note in `Sources/signals/`
   - Registers in MOC
   - Sets `consumed_at` → signal moves to "completed" in dashboard

---

## Batch Operations

For high-volume triage:
- Sort by tier to process all T3 items first (skip/delete in bulk)
- Filter by source to focus on one feed at a time
- Use the circuit breaker indicator — if it's active (>10 T1 items), all T1 items need manual review before any auto-promote

---

## Monitor Triage State

| Check | How |
|-------|-----|
| Pending promotions | Dashboard shows "pending" badge on promoted items |
| Processing status | `consumed_at` timestamp appears when feed-pipeline completes |
| Pipeline health | KPI strip shows adapter status, error rates, queue depth |
| Cost tracking | Daily spend displayed per-source and total |

---

## Handle Problems

| Problem | Symptom | Fix |
|---------|---------|-----|
| Signal details not loading | Blank detail panel | Check `pipeline.db` lock; dashboard shows cached view |
| Promote button unresponsive | No row in `dashboard_actions` | Refresh page; check API health endpoint |
| Promoted item stuck in "pending" | `consumed_at` never set | Run feed-pipeline skill ("process feed items") |
| Dashboard shows stale data | Counts don't match startup hook | Refresh; check API connection to `pipeline.db` |
| Cloudflare Access timeout | Re-authentication prompt | Re-authenticate; triage state persists in database |

---

**Done criteria:** All inbox items triaged (promoted, skipped, or deleted). No pending items in dashboard queue unless intentionally deferred.
