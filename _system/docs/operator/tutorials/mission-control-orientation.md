---
type: tutorial
status: active
domain: software
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Tutorial: Mission Control Orientation

Walk through the Mission Control dashboard — views, data sources, and triage mechanics.

**Prerequisites:** Dashboard running, Cloudflare Access authenticated.

---

## Step 1: Open the Dashboard

Navigate to the Mission Control URL in your browser. Authenticate via Cloudflare Access.

**Expected outcome:** Dashboard loads with the main navigation showing available pages.

---

## Step 2: Review the Intelligence Page

Click **Intelligence** in the navigation.

**What you see:**
- **KPI strip** (top) — signal counts (today/week), per-source breakdown (X, RSS, YouTube, HN, arXiv), tier distribution (T1/T2/T3), daily cost vs. ceiling
- **Digest panel** (main area) — signal cards grouped by source, tier, or topic
- **Pipeline health** — circuit breaker status, last run timestamps, adapter error rates

**Expected outcome:** You can see how many items are waiting and their health status. If the KPI strip shows zero items, the pipeline is caught up.

---

## Step 3: Explore a Signal Card

Click any signal card in the digest panel to expand it.

**What you see:**
- Full content: headline, body excerpt, source URL
- Tier classification and triage assessment (priority, confidence, tags)
- "Why now" context from the FIF triage
- Action buttons: **Skip**, **Delete**, **Promote**

**Expected outcome:** You understand what the signal is about and can make a triage decision.

---

## Step 4: Perform a Triage Action

Pick an item and choose an action:

| Action | What happens |
|--------|-------------|
| **Skip** | Removed from view. No vault effect. |
| **Delete** | Removed from queue permanently. |
| **Promote** | Queued for feed-pipeline processing. Optionally select a `#kb/` tag override. |

**Expected outcome:** The signal card reflects your action. Promoted items show a "pending" badge until the feed-pipeline skill processes them.

---

## Step 5: Check Pipeline Health

Scroll to the **Pipeline Health** section on the Intelligence page.

**What you see:**
- Circuit breaker indicator (green = normal, red = >10 T1 items, batch review mode)
- Last capture/triage/feedback timestamps
- Per-adapter error rates
- Queue depth

**Expected outcome:** All indicators green. If any are red or amber, the corresponding adapter or stage needs attention.

---

## Step 6: Verify Promotions Were Processed

After running the feed-pipeline skill in a Crumb session ("process feed items"), return to the dashboard.

**Expected outcome:** Previously promoted items now show `consumed_at` timestamps. They move to the "completed" section or disappear from the active queue.

---

## What You've Learned

- How to read the KPI strip for pipeline status at a glance
- How to expand and evaluate individual signal cards
- The three triage actions and their effects
- How to check pipeline health
- The promote → feed-pipeline → signal-note lifecycle

**Next:** See [[run-feed-pipeline]] for the Crumb-side processing and [[triage-feed-content]] for detailed triage procedures.
