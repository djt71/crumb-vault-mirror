---
type: tutorial
status: active
domain: software
created: 2026-03-14
updated: 2026-07-03
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Tutorial: Mission Control Orientation

Orientation for the Mission Control dashboard.

**Current state (2026-07-03):** The dashboard survives the v3 ADR as a
**stripped knowledge-work surface** — runtime shed, dashboard/vault-web/
cloudflared kept. The server (`com.crumb.dashboard`) is currently **stopped**
and the mission-control project is **paused** (agentic-sunset AS-030,
2026-06-14). The plist is retained-disabled; nothing needs operator attention
while paused.

**What was stripped:** The original walkthrough covered the Intelligence page
— feed-signal KPI strip, digest cards, Skip/Delete/Promote triage, and
feed-pipeline health panels. That entire surface was decommissioned with the
feed-intel framework (FIF) and the feed-pipeline skill (agentic-sunset,
2026-06). The full original tutorial is in git history for this file
(retired 2026-07-03, vault-optimization B3).

**When mission-control resumes:** re-author this tutorial against the stripped
dashboard's actual panels (ops/knowledge widgets). Until then there is no live
surface to orient to.

**To start the dashboard manually** (if needed before formal resume): load the
retained plist per the mission-control project's run-log; authenticate via
Cloudflare Access as before.
