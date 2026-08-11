---
type: specification
skill_origin: systems-analyst
project: agentic-sunset
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - specification
  - decommission
  - infrastructure
  - kb/software-dev
related_projects:
  - tess-v2
  - tess-danny-migration
  - mission-control
  - feed-intel-framework
  - opportunity-scout
---

# Specification: agentic-sunset

## Problem Statement

The self-built agentic infrastructure layer (Tess v2 scheduled services, Hermes gateway, OpenClaw bridge/dispatch, local LLM servers) has drifted from Crumb's original intent and accumulated maintenance gravity far out of proportion to delivered value — and produced zero revenue against the liberation directive's own metric. ~90% of its function is now available natively in Claude.AI and Claude Code (scheduled cloud agents, connectors, web research). Decommission the layer, migrate the functions worth keeping upstream, and return Crumb to its core: an interactive, vault-backed personal OS.

## Operator Decisions (locked 2026-06-10)

1. **Dashboard stack stays.** `com.crumb.dashboard`, `com.crumb.vault-web`, `com.crumb.cloudflared` keep running — may be repurposed or retried later.
2. **Disable + archive, never delete.** Services unloaded and plists retired; repos, data, Hermes install, and local models stay on disk (per existing teardown discipline; reversible, costs only disk).
3. **Plumbing kept, simplified.** Vault backup, drive-sync, vault-gc, vault-health survive as plain scheduled scripts under one clean label generation. Telemetry/awareness/health-ping wrappers go.
4. **Formal project**, software domain, full four-phase workflow.

## Facts

- 25 launchd plists exist across **three overlapping label generations** (`ai.openclaw.*`, `com.tess.*`, `com.tess.v2.*`) plus `com.crumb.*`; live daemons right now: Hermes gateway, `com.tess.llama-server`, Ollama (homebrew), OpenClaw bridge watcher, cloudflared, vault-web, dashboard.
- FIF and opportunity-scout were already decommissioned (2026-05-28); overnight-research and connections-brainstorm followed (2026-06-01). Their repos/plists were retained for reversibility.
- tess-danny-migration is P0–P6 complete (M6 green 2026-06-09); P7 (retire `tess`-user plists) is soak-gated for ~2026-06-11/12. This project supersedes P7 — retirement folds into the broader teardown.
- The crontab still calls `/Users/tess/crumb-vault/_system/scripts/drive-sync.sh` — a stale pre-migration path — while a `com.crumb.drive-sync` plist also exists (duplicate scheduling).
- `com.crumb.apple-snapshot` is failing (exit 127).
- Hermes Agent requires an out-of-tree KeepAlive patch reapplied after every update — standing maintenance cost.
- `_system/docs/solutions/infrastructure-teardown-discipline.md` (high confidence, 3× recurrence) governs: (1) end-condition/owner, (2) sweep consumers with producers, (3) never track toolchain-rewritten files.
- Liberation directive v2.1: revenue is the metric; ceremony budget applies retroactively — infrastructure that enabled zero revenue gets no further investment.

## Assumptions (validate during PLAN/IMPLEMENT)

- A1: Claude.AI / scheduled Claude agents can cover daily-attention and periodic-digest needs at acceptable parity. *(Validated by AS-005 before or shortly after local jobs stop.)*
- A2: Ollama serves nothing outside this layer. *(Check before unload — it's homebrew-managed and may have other consumers.)*
- A3: The dashboard stack stays healthy when Tess/Hermes services stop; panels reading their output degrade visibly but don't crash. *(Inventory task maps dashboard data dependencies.)*
- A4: Telegram alerting flows only through this layer; alerting need shifts to push notifications / Gmail MCP.
- A5: Vault backup and drive-sync scripts have no remaining `tess`-era path or keychain dependencies beyond the known crontab line.

## Unknowns

- U1: Which dashboard panels consume Tess service status / FIF data, and what they show when feeds stop.
- U2: Which shared libs in `_openclaw/scripts/` (e.g., `cron-lib.sh`) the surviving plumbing scripts source — what must stay un-archived.
- U3: Whether the `hc-ping.com` dead-man's switch has server-side alerts that will fire when health-ping stops (consumer sweep, discipline 2).
- U4: Whether the `tess` macOS user account itself should be deleted or merely left dormant (operator decision at closeout).

## System Map

**Components**
- *Scrap (disable + archive):* Hermes gateway + llama-server (+ Ollama pending A2), bridge watcher, all `ai.openclaw.*` jobs, `com.tess.*`/`com.tess.v2.*` agentic jobs (daily-attention, awareness-check, health-ping, backup-status, telemetry-rollup, system-stats, qmd-index†, vault-rebuild†), `_openclaw/` dispatch machinery, `_staging/TV2-*`, `_tess/`. († disposition confirmed by inventory — may be plumbing.)
- *Keep, simplified:* vault backup, drive-sync, vault-gc, vault-health → one `com.crumb.*` generation.
- *Keep, as-is:* dashboard, vault-web, cloudflared.
- *Migrate upstream:* daily attention, awareness/digest-type work, research → Claude.AI / scheduled Claude agents / deep-research skill.
- *Untouched core:* vault, workflows, skills (minus agent-dispatch surfaces), overlays, compound engineering, semuta.

**Dependencies & constraints**
- Vault backup must never lapse — plumbing consolidation (AS-004) cannot leave a window with no backup job. Hard constraint.
- CLAUDE.md, skill definitions, and overlay index edits are **Ask First** per behavioral boundaries — AS-006 gates on operator approval.
- Everything is disable+archive ⇒ no irreversible step in the whole project except optional `tess` user deletion (deferred, operator-owned).

**Levers**
- The service inventory (AS-001) is the single high-leverage artifact: every subsequent task executes dispositions recorded there. One table, mechanically applied.

**Second-order effects**
- Stopped producers turn their watchers into false signals (teardown discipline #2): hc-ping server-side alerts, dashboard health panels, awareness checks watching feed freshness. Each producer's consumers are swept in the same pass.
- Memory files (`openclaw-ops`, `fif-operations`, tess project memories) and `claude-ai-context.md` go stale the moment teardown lands — updated in AS-008.
- Git-tracked churn files (`_openclaw/state/*`, `_staging/*` execution logs) stop churning — current dirty working tree largely self-resolves; gitignore what remains toolchain-written.

## Domain Classification & Workflow Depth

- **Domain:** software. **Class:** system (operates on launchd/repos), but **no external repo** — this project produces no code, only teardown + vault artifacts. Repo gate skipped.
- **Workflow:** full four-phase (SPECIFY → PLAN → TASK → IMPLEMENT). Rationale: touches live services, three other projects, CLAUDE.md, and system config — the discipline is the point; this is exactly the class of work that created zombies when done ad hoc.

## Task Decomposition

| ID | Task | Tags | Risk | Depends on |
|---|---|---|---|---|
| AS-001 | **Inventory freeze + consumer-graph map.** `design/service-inventory.md`: every launchd label (all generations), crontab entry, and live daemon → disposition (scrap / keep-plumbing / keep-dashboard), plus consumers/watchers of each output (discipline 2). Resolves A2, A3, U1–U3. | #research | low | — |
| AS-002 | **Disable agentic daemons.** Bootout + disable per inventory: Hermes gateway, llama-server, bridge watcher, `ai.openclaw.*`, agentic `com.tess.*`/`com.tess.v2.*`. Retire plists to archive dir. Sweep consumers (hc-ping checks, dashboard watchers) in same pass. | #code | medium | AS-001 |
| AS-003 | **Hermes/OpenClaw runtime archive.** Mark `~/.hermes`, `~/openclaw/*` repos, models as archived (README-ARCHIVED breadcrumbs, no deletion). Verify nothing respawns on reboot. | #code | low | AS-002 |
| AS-004 | **Plumbing consolidation.** backup/drive-sync/vault-gc/vault-health under single clean `com.crumb.*` generation; fix stale crontab path; resolve drive-sync duplicate scheduling; fix or retire apple-snapshot (127). No backup-coverage gap. | #code | medium | AS-001 |
| AS-005 | **Upstream migration.** Stand up scheduled Claude agent(s) for daily attention (if still wanted) and any digest/research cadence worth keeping; alerting via push notification/Gmail. Document parity + gaps in `design/upstream-migration.md`. Validates A1. | #decision #code | low | AS-002 |
| AS-006 | **Vault + CLAUDE.md surgery.** Prune Bridge Dispatch section and dead routing references (operator approves diff first); archive `_openclaw/` operational state, `_staging/TV2-*`, `_tess/` (sparing libs identified in U2); gitignore toolchain-written files. | #writing | medium | AS-002, AS-004 |
| AS-007 | **Project closeouts.** tess-v2 → DONE; tess-danny-migration → DONE (P7 superseded — note in run-log); mission-control → run-log note (kept running, project paused); propose archival moves to operator (archival is user-initiated). | #writing | low | AS-002–AS-006 |
| AS-008 | **Skills + memory cleanup.** Retire/mark-dormant feed-pipeline skill and Tess-dispatch surfaces (vault-query dispatch mode, deliberation dispatch, bridge-dispatch protocol); update memory files and claude-ai-context.md. | #writing | low | AS-006 |
| AS-009 | **Soak + close.** 7-day observation: backups run, drive-sync green, no alert noise, dashboard up, clean working tree reachable. Then compound reflection + close. End-condition declared per discipline 1. | #decision | low | all |

## Success Criteria

1. `launchctl list` shows only the 11 keep-labels under one `com.crumb.*` generation — plumbing ×6 (vault-backup, backup-status, drive-sync, vault-gc, vault-health, system-stats) + dashboard/publishing ×5 (dashboard, cloudflared, vault-web, vault-rebuild, qmd-index) — plus unrelated system agents. Zero `ai.openclaw.*`, `ai.hermes.*`, `com.tess.*` labels loaded; crontab empty. *(Amended 2026-06-10 after PLAN investigation: Quartz publishing stack is 3 extra labels within the kept dashboard stack; backup-status + system-stats kept as dashboard feeders.)*
2. No new false-signal alerts (Telegram, hc-ping, dashboard) for 7 consecutive days post-teardown.
3. Vault backup and drive-sync verified green throughout — no coverage gap at any point.
4. Daily-attention (and any retained digest) running upstream via Claude.AI/scheduled agents, or explicitly declined and documented.
5. CLAUDE.md, skills, memory, and project states contain no references to live agentic infra; vault-check passes; working tree reaches clean.
6. Every disable is reversible: plists archived, repos/models on disk, restore path documented in run-log.
