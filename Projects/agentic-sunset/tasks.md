---
type: tasks
skill_origin: action-architect
project: agentic-sunset
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - tasks
  - decommission
sources:
  - action-plan.md
  - design/service-inventory.md
---

# agentic-sunset — Tasks

States: todo | in-progress | done | blocked. Supersedes spec provisional IDs AS-001–009.
Risk gates: low = auto-proceed · medium = proceed + flag · high = stop and ask.
`(op)` = requires operator hands (sudo / reboot / external account).

| id | description | state | depends_on | risk | domain | acceptance_criteria |
|---|---|---|---|---|---|---|
| AS-010 | State snapshot: capture `launchctl list`, `crontab -l`, LaunchAgents dir listing, `brew services list` → `design/restore-snapshot.md` | todo | — | low | software | Snapshot file exists with all 4 captures and is committed: YES/NO |
| AS-011 | Pause healthchecks.io check `2d06…9231` (via dashboard's API key or operator UI) before any daemon stops | todo | AS-010 | medium | software | Check status = paused, verified; zero "down" alerts received: YES/NO |
| AS-012 | Drive-sync verification: which script copy ran last, freshness of `/Users/tess/crumb-vault`, freshness of Google Drive target | todo | AS-010 | low | software | Run-log documents executing path + Drive-copy freshness with evidence: YES/NO |
| AS-013 | Bootout + disable 8 danny-side agentic daemons (hermes.gateway, llama-server, bridge.watcher, awareness-check, daily-attention, health-ping, openclaw vault-health, telemetry-rollup); plists → archive dir | todo | AS-011 | medium | software | None of the 8 labels in `launchctl list`; 8 plists in `_system/archive/launchagents-retired/`; port 8080 closed: YES/NO |
| AS-014 | Bootout + disable `com.tess.v2.*` ×5 + broken `com.crumb.apple-snapshot`; plists → archive dir | todo | AS-011 | medium | software | None of the 6 labels loaded; 6 plists archived: YES/NO |
| AS-015 | Stop + disable Ollama via `brew services` | todo | AS-013 | low | software | Port 11434 closed; `brew services` shows ollama stopped: YES/NO |
| AS-016 | 24h quiet verification: no Telegram traffic, no monitoring alerts, keep-set labels all green | todo | AS-013, AS-014, AS-015 | low | software | Run-log entry ≥24h later confirms all three: YES/NO |
| AS-017 | Fix drive-sync: repoint plist to `/Users/danny/.../drive-sync.sh`, remove stale crontab line, reload, manual run | todo | AS-012 | medium | software | Plist targets danny path; crontab empty; manual run exit 0; Drive copy fresh post-run: YES/NO |
| AS-018 | Relabel backup jobs: `com.tess.vault-backup`→`com.crumb.vault-backup`, `com.tess.backup-status`→`com.crumb.backup-status`; old plists archived; verify first scheduled fire | todo | AS-016 | medium | software | New labels loaded and fired; fresh 3 AM tarball in iCloud; `backup-status.json` fresh; old labels absent: YES/NO |
| AS-019 | Relocate `cron-lib.sh` → `_system/scripts/lib/`; create simplified log-only vault-health script + `com.crumb.vault-health` plist (no Telegram, no `_openclaw/` deps) | todo | AS-016 | medium | software | New label loaded; manual run exit 0 writing log; script greps clean for Telegram/`_openclaw`: YES/NO |
| AS-020 | README-ARCHIVED breadcrumbs (what/why/restore/date) in 7 runtime locations: `~/.hermes`, 5 `~/openclaw/*` repos, `~/crumb-apps/tess-v2` | todo | AS-016 | low | software | All 7 dirs contain README-ARCHIVED.md with the 4 required elements: YES/NO |
| AS-021 | (op) Reboot resurrection test: restart machine, verify nothing scrapped resurrects and all 11 keep-labels + dashboard + tunnel come up | todo | AS-018, AS-019, AS-020 | medium | software | Post-reboot `launchctl list` matches end-state inventory exactly; mc.crumbos.dev reachable: YES/NO |
| AS-022 | (op) tess-user residual check: sudo-enumerate `/Users/tess/Library/LaunchAgents` + tess GUI domain; disable any residuals; document | todo | AS-021 | medium | software | tess-side agents enumerated in run-log; zero active: YES/NO |
| AS-023 | Daily-attention upstream replacement: operator picks cadence/declines; create scheduled Claude agent (attention-manager → `_system/daily/{date}.md`); verify dashboard panel renders | todo | AS-016 | medium | software | Schedule exists + artifact written + panel renders it, OR decline documented: YES/NO |
| AS-024 | Write `design/upstream-migration.md`: replacement map, dropped functions with rationale, parity gaps | todo | AS-023 | low | software | Doc exists with frontmatter and covers all 5 functions from design §4: YES/NO |
| AS-025 | CLAUDE.md surgery: draft diff removing Bridge Dispatch section + dead routing references; operator approves diff before write | todo | AS-016 | high | software | Operator approved diff; CLAUDE.md greps clean for bridge-dispatch/dispatch-stage refs; vault-check passes: YES/NO |
| AS-026 | Archive `_openclaw/` → `Archived/_openclaw/` (sparing pipeline.db + dashboard-read paths per inventory); archive `_staging/TV2-*`, `_tess/` | todo | AS-019, AS-025 | medium | software | Dirs moved; dashboard intel page still loads; spared paths intact; vault-check passes: YES/NO |
| AS-027 | Gitignore toolchain-written churn files; verify working tree reaches clean after one full scheduler cycle | todo | AS-026 | low | software | `git status` clean ≥1 scheduler cycle after commit: YES/NO |
| AS-028 | Skills cleanup: retire/mark-dormant feed-pipeline; prune Tess-dispatch surfaces from vault-query + deliberation; archive bridge-dispatch protocol doc | todo | AS-026 | medium | software | No skill description references live agentic dispatch; protocol doc archived; skills load without error: YES/NO |
| AS-029 | Memory + context refresh: update openclaw-ops, fif-operations, tess-related memory files + MEMORY.md index; refresh claude-ai-context.md | todo | AS-026 | low | software | No memory file describes scrapped infra as live; claude-ai-context.md current: YES/NO |
| AS-030 | Project closeouts: tess-v2 → DONE, tess-danny-migration → DONE (P7 superseded), mission-control paused note; sweep XD table (resolve XD-026, mark mooted rows) | todo | AS-021, AS-022, AS-024, AS-027, AS-028, AS-029 | low | software | Both project-states phase DONE with closeout entries; XD-026 in Resolved; mooted rows marked: YES/NO |
| AS-031 | 7-day soak: daily check — fresh backup tarball, drive-sync green from danny path, no alerts, dashboard up, tree clean | todo | AS-030 | low | software | 7 consecutive green days logged in run-log: YES/NO |
| AS-032 | Final compound + archival proposals: route platform-absorption + dual-scheduler-drift insights (ask-first); propose project archival moves to operator | todo | AS-031 | low | software | Compound insights routed or explicitly declined; archival proposal presented: YES/NO |
