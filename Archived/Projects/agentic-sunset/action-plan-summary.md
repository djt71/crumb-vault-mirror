---
type: action-plan-summary
project: agentic-sunset
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: action-plan.md
source_updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - action-plan
  - summary
---

# agentic-sunset — Action Plan Summary

23 atomic tasks (AS-010…AS-032) across 7 milestones mapping 1:1 to teardown-design phases A–G. Supersedes spec provisional IDs AS-001–009.

**M1 Pre-flight** (010–012): restore snapshot; pause healthchecks check *before anything stops* (hard gate); verify drive-sync stale-source risk.
**M2 Daemon teardown** (013–016): bootout 14 agentic labels + Ollama, plists to git-tracked archive; 24h quiet verification.
**M3 Plumbing** (017–019): fix drive-sync path + crontab duplicate (can run early — urgent); relabel backup jobs with no-gap verification; simplified log-only vault-health, cron-lib relocated.
**M4 Durability** (020–022): README-ARCHIVED breadcrumbs ×7; operator-assisted reboot resurrection test; operator-assisted sudo check of tess-user residuals.
**M5 Upstream** (023–024): daily-attention → scheduled Claude agent writing same `_system/daily/` artifact (or documented decline); upstream-migration doc.
**M6 Vault surgery** (025–029): CLAUDE.md diff (high risk — operator approves before write); archive `_openclaw/`/`_staging/TV2-*`/`_tess/` sparing dashboard-read paths; gitignore churn → clean tree; skills + memory cleanup.
**M7 Close** (030–032): tess-v2 + tess-danny-migration → DONE, XD sweep; 7-day soak; final compound + archival proposals.

**Gates:** AS-011 blocks all teardown; AS-025 is the only stop-and-ask (CLAUDE.md); AS-021/022 need operator hands (reboot, sudo). Everything reversible: plists git-archived, repos/models untouched, checks paused not deleted.
