---
type: run-log
project: agentic-sunset
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - run-log
---

# agentic-sunset — Run Log

## 2026-06-10 — Project creation + SPECIFY

**Trigger:** Operator returned after extended absence; directive: the agentic initiatives (OpenClaw, Hermes Agent, Tess execution layer) have bloated the system away from original intent and are to be scrapped — functionality moves up to Claude.AI where ~90% is now native.

**Context inventory (SPECIFY, systems-analyst):**
1. Explore-agent footprint survey (live, 2026-06-10) — projects, vault dirs, repos, services, liberation directive, design-spec core intent
2. `launchctl list` + crontab + LaunchAgents survey (live) — 25 plists, 3 label generations, 7 live daemons
3. `_system/docs/solutions/infrastructure-teardown-discipline.md` — governing prior art (high confidence)
4. `Projects/tess-v2/project-state.yaml` — schema reference + decommission precedent
- Overlay index checked: no overlay loaded (Network Skills anti-signals Crumb infra; Business Advisor marginal — liberation directive supplies the strategic frame). Budget: 4 docs, standard tier.
- Signal scan (`Sources/signals|insights|research`, decommission/teardown keywords): no relevant hits — matches were agent-*building* notes.

**Operator decisions (locked via 4-question gate):**
1. Dashboard stack (dashboard, vault-web, cloudflared): **keep everything** — may repurpose or retry
2. Repos/data/models/Hermes: **disable + archive** (reversible, no deletion)
3. Plumbing (backup, drive-sync, vault-gc/health): **keep, simplified** — one clean label generation; fix stale crontab path; drop telemetry/awareness/health-ping wrappers
4. Formal project **agentic-sunset**, software domain, full four-phase

**Artifacts written:** specification.md, specification-summary.md, project-state.yaml, this run-log, progress-log.md

**Bugs observed during survey (folded into spec):**
- crontab calls stale `/Users/tess/crumb-vault/_system/scripts/drive-sync.sh` (pre-migration path) while `com.crumb.drive-sync` plist also exists — duplicate scheduling
- `com.crumb.apple-snapshot` failing, exit 127

**Decisions:**
- This project **supersedes tess-danny-migration P7** (tess-plist retirement folds into AS-002); migration closes as DONE-superseded at AS-007
- No external repo (decommission produces no code) — repo gate skipped with rationale in spec
- Spec scope: MAJOR → peer review offered to operator

**Next:** operator validates spec (± peer review) → SPECIFY→PLAN gate via Context Checkpoint Protocol.

### Phase Transition: SPECIFY → PLAN
- Date: 2026-06-10
- SPECIFY phase outputs: specification.md, specification-summary.md, project-state.yaml, run-log.md, progress-log.md, cross-project-deps.md row XD-026
- Goal progress: spec complete — problem statement, facts/assumptions/unknowns, system map, 9-task decomposition, success criteria all present. Operator validated 2026-06-10; peer review explicitly declined ("proceed to plan, no peer-review").
- Compound: insight noted — **platform absorption as teardown trigger**: when the platform you build on (Claude.AI/Claude Code) natively ships a capability you self-built, that is a standing end-condition signal (complements teardown-discipline #1). Routing: propose as evidence/corollary addition to `infrastructure-teardown-discipline.md` at session end (existing-doc update, ask-first).
- Context usage before checkpoint: estimated <50% (moderate session; /context not tool-invocable — estimate)
- Action taken: none
- Key artifacts for PLAN phase: specification-summary.md (in context), infrastructure-teardown-discipline.md (loaded)

## 2026-06-10 — PLAN

**Investigation:** two parallel Explore agents (read-only): (1) full plist/script/consumer inventory — all 26 scheduled items, hc-ping URLs, shared-lib deps, ollama usage, tess-user state, apple-snapshot diagnosis; (2) dashboard-stack dependency map — adapters, data sources, panel-by-panel degradation.

**Key findings (changed the plan):**
- vault-web ≠ dashboard: it's a separate Quartz static-publishing stack (vault-web :8843 + vault-rebuild 15m + qmd-index). Kept per operator decision ("keep everything" on dashboard stack) → end state is 11 labels, not ~8. Spec success criterion 1 amended accordingly (reality-diverges → spec updated first).
- **Drive-sync stale-source risk (HIGH):** crontab AND plist both target `/Users/tess/crumb-vault/...` — Google Drive/NotebookLM may be receiving a stale vault copy. Verify Phase A, fix Phase C.
- Ollama verified vestigial (zero references in active code) → SCRAP. Live LLM was llama.cpp :8080 (Hermes-only) → SCRAP.
- healthchecks.io check 2d06…9231 must be paused BEFORE health-ping stops (false-alarm window). Dashboard plist holds a healthchecks API key usable for this.
- vault-health.sh sources _openclaw/scripts/cron-lib.sh — relocate to _system/scripts/lib/ before _openclaw archive. Other keep-set scripts self-contained.
- Dashboard intel page reads FIF pipeline.db (static SQLite) → frozen-but-functional after teardown; pipeline.db must not move. telemetry-rollup loss degrades gracefully (stale badges).
- apple-snapshot exit-127 root cause: target script doesn't exist at /Users/tess path → SCRAP.
- /Users/tess still exists; its LaunchAgents unreadable without sudo — operator-assisted check needed before closeout (P7 residual).
- AS-001 (inventory) absorbed into PLAN as design work — TASK phase renumbers.

**Artifacts:** design/service-inventory.md (disposition table + consumer-sweep list), design/teardown-design.md (7-phase sequence A–G, reversibility contract, target architecture, upstream migration), design/teardown-design-summary.md. Spec criterion 1 amended.

**Next:** operator validates design → PLAN→TASK gate → action-architect decomposition.

### Phase Transition: PLAN → TASK
- Date: 2026-06-10
- PLAN phase outputs: design/service-inventory.md, design/teardown-design.md, design/teardown-design-summary.md, spec criterion 1 amendment
- Goal progress: design complete — disposition for all 26 items, consumer-sweep list, 7-phase sequence, reversibility contract, upstream migration design. Operator validated ("good, please proceed").
- Compound: insight noted — **dual-scheduler drift**: a path migration left the same job (drive-sync) scheduled in BOTH crontab and launchd, one on the stale path; sweep *all* schedulers when migrating paths. Queued with platform-absorption insight for session-end routing (likely additions to infrastructure-teardown-discipline.md / macos-system-notes memory, ask-first).
- Context usage before checkpoint: estimated 55-60% — proceeding; favoring summaries for new loads
- Action taken: none
- Key artifacts for TASK phase: teardown-design-summary.md + service-inventory.md (both in context)

## 2026-06-10 — TASK (action-architect)

**Context inventory:** spec summary, teardown-design.md, service-inventory.md, action-plan inputs — all authored this session, in context (0 new doc loads). Estimation-calibration history read (1 doc). Knowledge brief (hook, ambient): no bearing on teardown mechanics. Signal scan: deferred to SPECIFY result (no relevant hits). No overlay.

**Artifacts:** action-plan.md (7 milestones, M1–M7 ↔ phases A–G), tasks.md (23 atomic tasks AS-010–AS-032, supersedes spec provisional AS-001–009), action-plan-summary.md. Estimation-calibration row added (9 provisional → 23 actual, 2.6x — teardown decomposition pattern noted).

**Gate structure:** AS-011 (pause healthchecks) blocks all teardown; AS-025 (CLAUDE.md) is the sole stop-and-ask; AS-021 (reboot) + AS-022 (sudo tess check) operator-assisted; AS-017 (drive-sync fix) can run early — stale-sync risk is urgent.

**Next:** TASK→IMPLEMENT gate, then M1 (AS-010–012).

### Phase Transition: TASK → IMPLEMENT
- Date: 2026-06-10
- TASK phase outputs: action-plan.md, tasks.md (AS-010–AS-032), action-plan-summary.md, estimation-calibration row
- Goal progress: decomposition complete — 23 tasks, dependency graph, binary acceptance criteria, risk gates assigned. Operator approved plan and declined peer review ("proceed").
- Compound: estimation insight (teardown 2.6x task expansion) already routed to estimation-calibration.md during TASK. No further compoundable insights.
- Context usage before checkpoint: estimated ~60-65% — proceeding; summaries only for any new loads
- Action taken: none
- Key artifacts for IMPLEMENT phase: tasks.md, service-inventory.md, teardown-design.md §1 sequencing (all in context)

## 2026-06-10 — IMPLEMENT M1 (+ AS-017 pulled forward)

**AS-010 ✓** — restore snapshot written (`design/restore-snapshot.md`): 26 plists, crontab, brew services, PIDs. **Anomaly: com.crumb.dashboard plist exists but service NOT loaded — port 3100 dead, tunnel serving 404.** The mission-control "keep" applies to an already-down service. Re-bootstrap scheduled for AS-021.

**AS-011 ⛔ blocked on operator** — healthchecks.io has one check, `tess-mac-studio-health` (15m ping, currently up). The only local key (`hcr_…`, dashboard plist) is read-only — cannot pause via API. Searched tess-v2/_openclaw/.hermes configs: no write key on disk. Operator must pause via UI or supply full-access key. M2 (daemon teardown) gated on this.

**AS-012 ✓** — drive-sync verification, worst case confirmed:
- Both crontab (hourly) and com.crumb.drive-sync plist (5am) ran the **tess copy** (`VAULT_ROOT=/Users/tess/crumb-vault`) → **Google Drive / NotebookLM / Perplexity Computer received the frozen tess vault (HEAD Jun 8, migration P0 freeze) for ~2 days.**
- Danny vault's git post-commit hook runs the danny copy (correct source) but it failed `rclone not found` — hook context lacks /opt/homebrew/bin in PATH.

**AS-017 ✓ (pulled forward per plan)** —
1. `drive-sync.sh` (danny): added `export PATH=/opt/homebrew/bin:...` for hook context.
2. Plist repointed tess→danny path, `plutil` lint OK, bootout+bootstrap clean.
3. Crontab removed entirely (`crontab -r`) — empty, duplicate scheduling gone.
4. Manual run exit 0, log clean DONE 14:03 — Drive now receives current vault.
Remaining schedulers for drive-sync: launchd 5am daily + post-commit hook (both danny source). Restore path: snapshot doc + git history of plist (plist itself outside vault — content recorded in snapshot).

**Next:** operator unblocks AS-011 → M2 (AS-013–016).

## 2026-06-10 — IMPLEMENT M2: daemon teardown

**AS-011 ✓** — operator paused `tess-mac-studio-health` via UI; API-verified `status=paused`.

**AS-013 ✓ / AS-014 ✓** — all 14 agentic labels booted out, zero failures; plists moved to `_system/archive/launchagents-retired/` (git-tracked restore path): hermes.gateway, llama-server, bridge.watcher, awareness-check, daily-attention, health-ping, openclaw vault-health, telemetry-rollup, com.tess.v2.×5, apple-snapshot.

**AS-015 ✓** — `brew services stop ollama` clean.

**Verification:** `launchctl list` shows zero scrapped labels; ports 8080/11434 closed (no listeners); keep-set intact (9 loaded: cloudflared, vault-web live; drive-sync, qmd-index, system-stats, vault-gc, vault-rebuild, tess.backup-status, tess.vault-backup scheduled). Dashboard still down per snapshot anomaly — AS-021.

**AS-016 ▶ in progress** — 24h quiet clock started 2026-06-10 ~14:15 EDT. Check 2026-06-11: no Telegram, no monitoring alerts, keep-set green. M3 relabeling (AS-018/019) and everything downstream gated on it.

**Hermes/OpenClaw layer is now fully dark.** Telegram will be silent from this point — that silence is intentional.

## 2026-06-10 — Session end

**Session scope:** project created → SPECIFY → PLAN → TASK → IMPLEMENT M1+M2 in one session, operator-gated at every transition. Drive-sync stale-source bug found and fixed same-day.

**Correction logged:** dashboard down-state is deliberate (stopped 2026-06-01, operator decision) — not a migration casualty as the restore snapshot first guessed. AS-021 amended: no auto-restart; dashboard restart is a separate operator decision.

**AS-016 handoff:** 24h quiet check due 2026-06-11 ~14:15+. A session-local one-shot (14:33) exists but dies with this session (CronCreate `durable` flag not honored in this build — flag accepted but job reports session-only); operator will prompt "run the quiet check" in tomorrow's session. Cloud /schedule was evaluated and rejected: cloud agents cannot run launchctl/local checks.

**Compound evaluation:** two insights queued for AS-032 routing (already recorded at their gates): (1) platform absorption as standing teardown trigger; (2) dual-scheduler drift — path migrations must sweep ALL schedulers (cron + launchd + git hooks), found as crontab+plist+post-commit-hook all running drive-sync with two different source paths. A third candidate from session-end: **CronCreate durable flag silently ignored** — harness quirk, routed to memory (claude-code-harness) rather than solutions.

**Session-end protocol notes:**
- Amendment Z session report: **skipped with reason** — the consumer (Tess morning briefing / session_reports.db) was decommissioned this session; writing reports nothing reads violates teardown discipline. Protocol doc update queued in AS-028.
- Code review sweep: no repo_path on this project; only code change was a 3-line PATH/source fix to `drive-sync.sh`, verified by execution (manual run + hook-triggered run both clean). Logged skip: Code Review — Skipped (AS-017): config-tier script fix, execution-verified.
- Model routing (cost observation): no Sonnet delegation this session — all skill work (systems-analyst, action-architect) ran on session model; 3 Explore subagents inherited session model. Heavy ops: two parallel investigation agents (PLAN) — quality pass, no rework.
- claude-ai-context.md refreshed (was 9 days stale, flagged at startup).
- qmd index updated; inbox .processed empty; failure log not warranted (clean session).

**Next session:** run AS-016 quiet check (operator will prompt) → if green, M3 (AS-018/019) on operator go-ahead.

## 2026-06-11 — AS-016 quiet check: NOT GREEN

**Verdict: NO** (checked 10:39–10:50 EDT, ~20.4h into the 24h window — moot, two criteria already failed).

**1. No Telegram traffic — FAIL (infrastructure live).** `openclaw-gateway` (node, PID 312) running under the separate `openclaw` user account since boot, with an ESTABLISHED TLS connection to 149.154.166.110:443 (Telegram DC range) and local listeners on 18789/18791. The M2 teardown swept only danny's gui domain; the `openclaw` user domain was never enumerated — AS-022 scoped only the `tess` user. Socket byte counts are keepalive-scale (rx 12.5KB/tx 2.4KB on current socket); operator to confirm phone-side silence. Danny-side evidence is clean: booted labels' logs end 14:04–14:12 EDT Jun 10 (watcher's final line is its own SIGTERM), ports 8080/11434 closed, no hermes/ollama processes.

**2. No monitoring alerts — FAIL.** "DOWN | tess-mac-studio-health" email delivered 16:49 EDT Jun 10 (unread, Label_25). Chain: check paused 14:11 → stray ping 14:34:20 EDT auto-resumed it (healthchecks resumes paused checks on ping; manual_resume=false) → 15m period + 2h grace → down flip 16:49 → email. Check status now `down`. Pinger unidentified: not health-ping (dead 14:12, hourly at :04), not backup-status (no curl in script), not tess-v2 health-ping (last ran 14:04). **RESOLVED 2026-06-11: operator self-identified — Danny resumed the check via the healthchecks.io UI at ~14:34.** Alert chain was operator-induced, not a rogue component. Check still needs re-pausing.

**3. Keep-set green — PASS.** 9/9 labels loaded, status 0 (cloudflared + vault-web running w/ PIDs; 7 scheduled). Zero scrapped labels in danny domain. Fresh 3 AM backup tarball (crumb-vault-2026-06-11_0300.tar.gz, 117MB) in iCloud.

**Context finding:** machine rebooted Jun 10 12:47 EDT — *before* the 14:12 teardown, so current state is not a post-teardown reboot test; AS-021 still required. The reboot is how openclaw-gateway came up (RunAtLoad in the openclaw domain, presumably).

**Minor:** backup-status.json false-negative (`vaultBackup: n/a` despite fresh tarball) — script can't list `~/Library/Mobile Documents` from launchd context (TCC). Fold fix into AS-019/M3 rework.

**Remediation proposed (operator decision):** (1) expand AS-022 to enumerate + boot BOTH tess and openclaw user domains (sudo), disable+archive the gateway plist per standing decision; (2) identify the 14:34 pinger during that sweep; (3) re-pause healthchecks check after sweep; (4) restart 24h quiet clock. AS-016 remains in-progress; M3 stays gated.

## 2026-06-11 — Gateway root cause + teardown (AS-016 remediation)

**Root cause of survivor:** `/Library/LaunchDaemons/ai.openclaw.gateway.plist` — root-owned SYSTEM-level daemon (KeepAlive, RunAtLoad, UserName=openclaw, node gateway on 18789). All prior sweeps were per-user-domain; a system daemon is invisible to them. Its internal cron (`~openclaw/.openclaw/cron/jobs.json`, active — modified 10:02 today) was sending the Telegram morning briefing (operator confirmed receipt this morning); config also had a live Discord bot (mechanic-bot), both channels enabled.

**Teardown (operator-executed via sudo, ~10:55 EDT):** `launchctl bootout system/ai.openclaw.gateway` + plist moved to `_system/archive/launchagents-retired/` (disable+archive per standing decision). Verified: zero gateway processes, ports 18789/18791 closed, zero Telegram DC sockets, /Library/LaunchDaemons clean of agentic plists. Archived plist still root-owned (chown arg got line-wrapped) — readable/committable, cosmetic fix pending. ⚠️ archived plist embeds BOOK_SCOUT_API_KEY verbatim (precedent: existing archived plists carry hc-ping URLs/token env refs; vault remote private; operator may rotate key if desired).

**AS-022 enumeration pulled forward (sudo, both users):**
- openclaw user domain (502): only Apple system services live. Dormant in `~openclaw/Library/LaunchAgents/`: `ai.openclaw.gateway.plist` (Mar 15 — newer than system copy) + `.disabled` variant. No GUI session → won't load unless openclaw logs in. Disable/archive action remains for AS-022.
- tess user: no GUI session, agents dormant. `~tess/Library/LaunchAgents/` full inventory (24 plists) incl. agentic set: ai.hermes.gateway, ai.openclaw.×5, com.tess.llama-server, **com.tess.nemotron-load (previously unknown)**, com.tess.v2.×5, homebrew.mxcl.ollama, com.crumb.telemetry-rollup — resurrection risk on any tess GUI login. Disable/archive action remains for AS-022.

**Quiet clock RESTARTED:** 24h window from 2026-06-11 ~10:55 EDT → re-check 2026-06-12 ~11:00 EDT. Expected state for green: no Telegram (briefing gap tomorrow is EXPECTED — gateway cron dead; AS-023 is the replacement), no alerts (operator to re-pause healthchecks check via UI), keep-set green.

**Compound candidate (route at AS-032):** per-user launchctl sweeps miss system-domain daemons — teardown inventories must enumerate `/Library/LaunchDaemons` + `/Library/LaunchAgents` + every user's domain, not just the operating user's.

**2026-06-11 ~11:15 EDT addenda:** (1) operator re-paused `tess-mac-studio-health` via UI — API-verified `status=paused`; (2) operator fixed archived gateway plist ownership (chown danny:staff). All AS-016 remediation items closed except the restarted 24h window itself. Quiet conditions now fully set: gateway dead, check paused, keep-set green.

## 2026-06-11 — Session end

**Session scope:** AS-016 first quiet check (NOT GREEN) → root-cause → same-day remediation: system-level `ai.openclaw.gateway` LaunchDaemon discovered (Telegram briefing + Discord bot still live), operator-executed bootout + archive, AS-022 enumeration pulled forward (both tess and openclaw users), healthchecks re-paused (API-verified), quiet clock restarted → due 2026-06-12 ~11:00 EDT.

**Compound evaluation:** one insight recorded mid-session, queued for AS-032 routing: **per-user launchctl sweeps structurally miss system-domain daemons** — teardown inventories must enumerate `/Library/LaunchDaemons` + `/Library/LaunchAgents` + every user account's domain (this machine had three: danny, tess, openclaw). Candidate destination: `infrastructure-teardown-discipline.md` (existing-doc update, ask-first). Secondary observation, no routing needed: the quiet-check pattern worked exactly as designed — the 24h gate caught a survivor that point-in-time verification missed.

**Session-end protocol notes:**
- Amendment Z session report: skipped with reason — consumer (session_reports.db) decommissioned; protocol doc update queued in AS-028 (same skip as 2026-06-10 session).
- Project state refreshed: next_action rewritten (was stale re: 14:15 due time), updated/last_committed → 2026-06-11.
- Failure log: not warranted — clean session, first-check failure was the gate doing its job.
- Code review sweep: no repo_path, no code changes (ops actions only — launchctl, file moves, API calls). N/A.
- Build verification: no repo_path. N/A.
- Model routing (cost observation): no skill invocations, no subagent delegation — entire session on session model (Fable 5) with direct tool calls; appropriate for live ops/diagnosis work. Token-notable: none (no large file loads; targeted reads only).
- Operator interactions: sudo command execution (bootout/mv/chown), healthchecks UI re-pause, Telegram briefing receipt confirmation, 14:34 ping self-identification.

**Next session:** "run the quiet check" (operator prompt, ~11:00 EDT 2026-06-12) → green → M3 (AS-018/019) on go-ahead.

## 2026-06-11 — Operator decision (cross-project, work-surfaces session): inbox consolidation

**Decision:** `_openclaw/inbox/` is **defunct** — the two-inbox era ends. `_inbox/` +
inbox-processor is the single universal intake for all work surfaces; feed-type items,
if they still arrive, become a classification inside inbox-processor, not a parallel
pipeline. Standing feedback unchanged: intake stays deliberately open (no upstream
strategic-fit filters).

**Execution lands here:** AS-026 (archive `_openclaw/` — no need to spare inbox paths
beyond dashboard-read items per existing inventory) and AS-028 (feed-pipeline
retire/dormant call — consolidation strengthens the retire case). Decision record:
`_system/docs/work-surfaces.md` § Intake (created this session, non-project), with the
companion write-boundary ADR (`_system/docs/adr-vault-write-boundary.md`) sanctioning
the AS-023 write path (`_system/daily/` is the first Class 1 drop zone — relevant to
AS-023 substrate choice and design).

## 2026-06-11 — Scheduler product verification complete (AS-023 input)

**Work:** Re-verified April 2026 Cowork + Routines claims against current primary docs
(two parallel research agents, primary-source citations). Artifact:
`design/scheduler-verification-2026-06.md`. Verdict: Cowork-scheduled tilt for AS-023
strengthens — live-vault write + vault-check fires on Cowork commits; but Cowork reads
no CLAUDE.md and fires no lifecycle hooks, so the AS-023 task prompt must be
self-contained. Routines: stable, but cloud runs can't fire local git hooks — operator
guard: never enable "unrestricted branch pushes" for crumb-vault. Pilot observation
item: whether Cowork shares the Claude Code project memory dir. Work-surfaces
verification list marked complete. (Adjacent operator action: Perplexity subscription
cancelled — roster doc updated.)

## 2026-06-12 — AS-016 quiet check (re-run): GREEN ✅

**Verdict: YES** (checked 11:38 EDT, ~24.7h into the restarted window from 2026-06-11 ~10:55 EDT).

**1. No Telegram traffic — PASS.** Zero gateway/hermes/ollama processes; zero sockets to Telegram DC ranges (149.154.*, 91.108.*); ports 18789/18791/8080/11434 closed; `/Library/LaunchDaemons` clean of agentic plists. Operator confirmed phone-side silence — no morning briefing (gap is the expected green state; AS-023 is the replacement), no other messages since teardown.

**2. No monitoring alerts — PASS.** healthchecks.io API (read-only `hcr_` key from dashboard plist env): `tess-mac-studio-health` status `paused`, last_ping unchanged at 2026-06-10T18:34:20Z (the known operator UI-resume) — nothing pinged it during the window, so no stray pinger remains. Gmail (dturner71@gmail.com, same account that received the Jun 10 DOWN email): zero healthchecks messages after 2026-06-11. Note: google-workspace MCP auth expired mid-check; degraded to claude.ai Gmail connector, which was verified able to see healthchecks mail (Jun 10 DOWN email visible).

**3. Keep-set green — PASS.** 9/9 labels loaded, status 0: cloudflared (PID 684) + vault-web (PID 689) running; drive-sync, qmd-index, system-stats, vault-gc, vault-rebuild, tess.backup-status, tess.vault-backup scheduled. Zero scrapped labels in danny domain. Fresh 3 AM tarball `crumb-vault-2026-06-12_0300.tar.gz` in iCloud crumb-backups.

**Procedure note:** deliberately did NOT touch the hc-ping URL — a GET pings the check and auto-resumes a paused check (yesterday's alert-chain mechanism). Status verified via management API only.

**AS-016 → done.** M3 (AS-018/019) now unblocked, pending operator go-ahead. AS-020/023/025 also ungated.

## 2026-06-12 — M3 execution: AS-018 swap + AS-019 vault-health rebuild

**Context inventory:** tasks.md (M3 rows), action-plan.md §M3, teardown-design.md Phase C + §3, archived `ai.openclaw.vault-health.plist` (schedule/env reference), `vault-backup.sh`, `backup-status.sh`, `_openclaw/scripts/{vault-health.sh,cron-lib.sh}`. Operator go-ahead given after AS-016 GREEN.

**AS-018 — backup relabel (swap complete, scheduled-fire confirmation pending):**
- New plists `com.crumb.vault-backup` (3 AM, +PATH/HOME env) and `com.crumb.backup-status` (900s, RunAtLoad, +env) written to `~/Library/LaunchAgents/`.
- Old `com.tess.*` pair: bootout + disable + plists moved to `_system/archive/launchagents-retired/`.
- New labels bootstrapped; `launchctl list` shows both at status 0, zero `com.tess.*` remaining anywhere in danny domain.
- Kickstart verification: `com.crumb.vault-backup` ran end-to-end via launchd → `crumb-vault-2026-06-12_1150.tar.gz` (129M) created. **First scheduled 3 AM fire confirms tomorrow** (AS-031 soak also covers).
- **TCC false-negative FIXED** (folded in per 2026-06-11 note): `vault-backup.sh` now writes marker `_system/logs/vault-backup-last.json` (filename/epoch/size) after each successful run; `backup-status.sh` falls back to the marker when the iCloud dir listing comes up empty under launchd. Verified: `backup-status.json` now reports `vaultBackup: ok` from launchd context (was `n/a` for months).
- **New finding:** the retention prune in `vault-backup.sh` (`ls -t | tail +31 | xargs rm`) is ALSO blind under launchd TCC — pruning has silently never run from launchd ("Backups retained: 0" in every log). Currently harmless: 11 tarballs / 968M (cadence gaps kept it under the 30 cap). Hardened: script now logs an explicit WARNING when the listing fails instead of a misleading count. Real fix needs a user-context prune (e.g. session-start hook) or an FDA grant — operator decision, deferred. `timeMachine: unknown` in backup-status is the same TCC class, pre-existing, untouched.

**AS-019 — vault-health rebuild: DONE ✓**
- `cron-lib.sh` git-mv'd `_openclaw/scripts/` → `_system/scripts/lib/`, de-agented: kill-switch `_system/state/maintenance` (was `~openclaw/.openclaw/`), metrics `_system/logs/ops-metrics.jsonl`, last-run `_system/state/last-run`, locks `/tmp/crumb-cron-locks`. Public API unchanged.
- New `_system/scripts/vault-health.sh`: same three checks (vault-check, git status, stale project-state 14d), log-only — Telegram delivery stripped; findings → `_system/logs/vault-health-notes.md` (removed when clean), log → `_system/logs/vault-health.log`. Pull model per design §3.
- New `com.crumb.vault-health` plist (nightly 2 AM, PATH/HOME env, WorkingDirectory vault) bootstrapped.
- Acceptance verified: label loaded (status 0); launchd-context run exit 0 (metrics: success, 414s wall — note: vault-check full scan uses ~70% of the 600s wall-time budget; bump if vault grows); both scripts grep fully clean for telegram/openclaw.
- First real run produced notes: 82 warnings / 0 errors (venv .md junk under tess-v2, run-log rotation candidates, archived-brief broken links — known full-scan noise; much of it disappears at AS-026 archive).

**Keep-set is now 10 labels** (9 + com.crumb.vault-health), matching the design end-state modulo com.crumb.dashboard (deliberately stopped). M4 (AS-020/021/022) and AS-023/024/025 remain.

**2026-06-12 addendum — retention prune fix (operator-approved, AS-018 fold-in):** prune moved to `session-startup.sh` (new Step 1b) — the hook runs in user GUI context where the iCloud dir lists fine, so no FDA grant needed. Same keep-30 policy; silent when nothing to prune. `vault-backup.sh`'s own prune left in place as a harmless second path, its zero-count message downgraded to a NOTE pointing at the hook. Verified: keep-4 dry-run selects the 7 oldest correctly, keep-30 selects 0, full hook exits 0. Drift bound: a long no-session gap accumulates extra tarballs until the next session start prunes back to 30 — acceptable.

## 2026-06-12 — AS-020/023/024/025: breadcrumbs, decline, migration doc, CLAUDE.md surgery

**Context inventory:** tasks.md, teardown-design.md (Phase D dir list, §2 reversibility, §4 replacement table), service-inventory.md (per-service "what it was"), CLAUDE.md (grep sweep), teardown-design frontmatter pattern.

**AS-020 — DONE ✓:** README-ARCHIVED.md written to all 7 runtime locations (`~/.hermes`, `~/openclaw/{feed-intel-framework, opportunity-scout, crumb-tess-bridge, x-feed-intel, book-scout}`, `~/crumb-apps/tess-v2`), each with what/why/restore/date, grep-verified. Restore paths point at the git-tracked plist archive; gateway-cron consumers (FIF, scouts) note the system-domain sudo restore path; book-scout README repeats the BOOK_SCOUT_API_KEY rotation flag. `~/openclaw/crumb-dashboard` and `~/openclaw/semuta` correctly excluded (live).

**AS-023 — DONE ✓ (decline):** operator declined a scheduled daily-attention replacement — on-demand only via attention-manager skill. Decline documented per acceptance (here + upstream-migration.md). Reversal is one-line: schedule can be created anytime; skill and artifact unchanged.

**AS-024 — DONE ✓:** `design/upstream-migration.md` written — all 5 functions from design §4 mapped (daily-attention→declined/on-demand, monitors→dropped, feed intel→Claude.AI pull, Telegram→push-notifications/Gmail MCP, research→deep-research skill), parity gaps accepted (no unattended freshness, no briefing, no digests), reversal paths noted.

**AS-025 — DONE ✓ (high-risk, diff-approved):** operator approved removing the Bridge Dispatch Stage Output section from CLAUDE.md; applied; greps clean for bridge-dispatch/dispatch-stage. Deliberately retained: `~/openclaw/[project-name]/` code-dir convention (live — semuta) and Phase-3 "dispatch manifest" (Sonnet-delegation handoff, unrelated). Protocol doc archival itself stays in AS-028. vault-check exercises at next commit.

**Remaining:** AS-021/022 (operator-assisted: reboot test, sudo dormant-plist sweep) → AS-026 (vault `_openclaw/` archive) → AS-027/028/029 → AS-030 closeouts → AS-031 soak → AS-032. AS-018 3 AM fire confirms tomorrow.

## 2026-06-12 — AS-026: vault surgery (_openclaw/_tess/_staging archived)

**Pre-move verification (what gets spared and what breaks):**
- FIF `pipeline.db` lives OUTSIDE the vault (`~/openclaw/feed-intel-framework/state/`) — untouched by this move.
- Dashboard source grep: the ONLY vault `_openclaw` reference is `FEED_INBOX_DIR = '_openclaw/inbox'` in `intel.ts`, and both usages are try/catch-wrapped ("Inbox dir missing or unreadable — not an error"). Nothing inside vault `_openclaw/` needed sparing — the design's spare-list concern resolves to the external db.
- Keep-set script audit: `vault-gc.sh` purge targets under `_openclaw` all no-op on missing dirs (`purge_aged` early-returns; log loop `[ -f ]`-guarded); `session-startup.sh` scans all guarded; `mirror-sync.sh` include patterns match-nothing harmlessly. Dead lines left in place — trimming queued under AS-028/029 cleanup.
- `vault-check.sh` wikilink exemption repointed `_openclaw/state/vault-health-notes.md` → `_system/logs/vault-health-notes.md` (file moved in AS-019).

**Execution:** checkpoint commit 92e27cc first (rollback point), then `git mv _openclaw Archived/_openclaw`, `git mv _tess Archived/_tess`, `_staging/TV2-*` ×14 → `Archived/_staging/`, empty `_staging/` removed.

**Post-move verification:** pipeline.db intact; session-startup hook exit 0 (dispatch/research/brainstorm/feed counts all degrade to 0); manual vault-gc run exit 0 ("nothing to clean"); vault-check passes at the commit gate. **Live dashboard intel render check deferred** — dashboard deliberately stopped since 2026-06-01, restart is an operator decision; code-level verification stands in (acceptance noted accordingly). Pre-existing uncommitted deletion `_openclaw/data/scout-digests/2026-05-11.md` (vault-gc's own purge) folded into the checkpoint commit.

**Ripple:** `_openclaw/inbox` (already defunct per work-surfaces) now physically gone from the live tree; feed-pipeline skill and vault-query/deliberation Tess surfaces still reference it — AS-028 scope, unchanged.

## 2026-06-12 — AS-027/028/029: gitignore churn, skills cleanup, memory refresh

**AS-027 ▶ in progress (implementation done, soak pending):** 5 churn files written by surviving com.crumb.* jobs gitignored + `git rm --cached` (vault-gc.log, vault-backup-last.json, ops-metrics.jsonl, vault-health.log, vault-health-notes.md); stale `_openclaw/*` ignore block retired (dir archived). Discovery during AS-026 commit: the move took previously-ignored `_openclaw` files out of ignore scope → `git add -A` committed 191 of them (logs, attention-replay.db 450KB). Kept deliberately — archive completeness per disable+archive doctrine; secret-pattern sweep over all 191: clean (gws-token.sh is a reader, credentials external). Clean-tree verification after tonight's full scheduler cycle → 2026-06-13.

**AS-028 — DONE ✓:** feed-pipeline skill retired → `_system/archive/skills-retired/feed-pipeline/` (git mv); bridge-dispatch-protocol.md → `_system/archive/protocols-retired/`; vault-query pruned (Tess consumer line, dispatch-brief trigger, capability-resolution block, `_openclaw/tess_scratch` output path → inline output); critic pruned (description "Tess-dispatchable", Tess-dispatched mode, review-brief parsing, `_openclaw/research/output` row) — added to scope because acceptance is description-level and critic's description violated it; deliberation needed nothing (its "dispatch" is the live external-LLM panel). Skill list reloads cleanly, 19 skills. Residuals flagged (body text, not dispatch surfaces): audit §15 Tess harness audit, learning-plan §7 Tess check-ins, researcher bridge-dispatch invocation rows — route via vault-optimization or next audit.

**AS-029 — DONE ✓:** openclaw-ops + fif-operations memory files rewritten as historical stubs (full lore preserved in git history of the memory repo files); still-live facts extracted into the stubs: GWS OAuth token store (`~/.google_workspace_mcp/credentials/`, used by workspace-mcp today) and the Keychain-not-env rule for rotating credentials; Telegram token-exclusivity lore kept as future-proofing. project-tess-v2-k2-route-retest.md deleted (mooted, per its own deletion marker). MEMORY.md index synced. claude-ai-context.md regenerated (was 2-day stale per startup hook): AS-016 green + M3/M5/M6 state, 10-label com.crumb.* roster, liberation v3, work-surfaces pointer (Perplexity cancelled), 19 skills, TCC quirk note, open-items refreshed.

**M6 status:** AS-025/026/028/029 done; AS-027 soaks overnight. Project remainder: AS-018+AS-027 confirmations (2026-06-13), AS-021/022 (operator-assisted), AS-030 closeouts, AS-031 soak, AS-032 final compound.

## 2026-06-12 — Session end

**Session scope:** AS-016 quiet re-check GREEN (Telegram silent infra+phone, hc paused w/ zero pings, keep-set 9/9) → operator go-ahead → M3 (AS-018 relabel + kickstart-verify, AS-019 vault-health rebuild), retention-prune TCC fix (session-startup hook), AS-020 breadcrumbs ×7, AS-023 decline + AS-024 migration doc, AS-025 CLAUDE.md surgery (diff-approved), AS-026 vault surgery (_openclaw/_tess/_staging archived), AS-027 gitignore implementation, AS-028 skills cleanup, AS-029 memory/context refresh. Three commits pushed (92e27cc checkpoint → afe2d7a8), all through the vault-check pre-commit gate.

**Compound evaluation:** two insights routed to operator memory mid-session (ask-first not required — memory layer, not `_system/docs/solutions/`): (1) launchd TCC iCloud asymmetry — writes succeed, directory listing blocked → marker-file pattern for status, user-context for pruning (→ macos-system-notes); (2) `git mv` out of a `.gitignore` scope un-ignores residue → next `git add -A` commits it; decide keep-vs-extend-ignore deliberately + secret-sweep (→ vault-discipline). Yesterday's system-domain-daemon insight stays queued for AS-032 routing per plan. No new primitives proposed (ceremony budget: all needs met by existing surfaces).

**Code review sweep:** skipped with reason — project has no repo_path (teardown/vault artifacts only); shell-script changes (vault-backup, backup-status, vault-health, session-startup, cron-lib) verified by execution: kickstarted launchd runs exit 0, hook exit 0, manual vault-gc exit 0.

**Cost observation:** no Sonnet delegation this session — all work main-session (Fable 5); mechanical skills (sync/checkpoint procedures) executed inline rather than as skill invocations, appropriate for a teardown session where every step needed operator-visible judgment. No token-heavy anomalies; longest single operation was the 414s vault-check full scan inside vault-health's verification run.

**Next session opener:** confirm AS-018 (3 AM tarball `crumb-vault-2026-06-13_0300.tar.gz` via com.crumb.vault-backup + backup-status.json `ok`) and AS-027 (tree clean after full scheduler cycle) — then AS-021/022 await operator (reboot, sudo).

## 2026-06-12 — AS-022: tess + openclaw dormant-plist sweep (operator sudo)

**Context inventory:** tasks.md (AS-021/022 rows), run-log 2026-06-11 enumeration section, `_system/archive/launchagents-retired/` listing (naming convention + collision check).

**Ordering note:** executed before AS-021 with operator approval, inverting the declared dependency. Rationale: tess/openclaw LaunchAgents are login-gated, not boot-gated (neither user has a GUI session), so the reboot test is unaffected — and sweeping first makes AS-021's post-reboot inventory a stronger final check.

**Enumeration (operator sudo, re-list + zero-active check):**
- tess `~/Library/LaunchAgents/`: 24 plists + `disabled/` subdir (2 more: ai.openclaw.email-triage, com.tess.v2.email-triage — both stack residue). All 26 files agentic/crumb-stack; nothing benign. Override DB: everything disabled EXCEPT `homebrew.mxcl.ollama` => enabled (would start on tess login).
- openclaw `~/Library/LaunchAgents/`: ai.openclaw.gateway.plist + .disabled variant (agentic) + 3 Google updater plists (benign). Override DB: `ai.openclaw.gateway` => enabled.
- Zero active confirmed: launchctl print user/501 + user/502 greps matched only disabled-override entries, no running services — consistent with 2026-06-11 finding.
- Oddity (no action): tess override DB contains one corrupted entry — a newline-joined list of 22 labels recorded as a single "disabled" key, residue of a past malformed `launchctl disable` call. Lives in launchd's override store, not a file; harmless.

**Action (operator sudo, ~16:09 EDT):** per-user subdirs created to avoid collisions with existing danny-domain archives: ALL tess entries (24 plists + disabled/ subdir) → `_system/archive/launchagents-retired/tess-user/`; both openclaw gateway plists → `openclaw-user/`; Google updater plists deliberately left in place. `chown -R danny:staff` applied in same command (no line-wrap repeat). Verified: tess LaunchAgents dir empty; openclaw dir holds only the 3 Google files.

**Secret sweep (pre-commit):** found live secrets embedded verbatim — Telegram bot token (Tess awareness bot) in 4 plists (awareness-check, vault-health, both email-triage) + Healthchecks API key in com.crumb.dashboard.plist. **Operator decision: redact before commit** (beyond the BOOK_SCOUT_API_KEY keep-verbatim precedent — these were live credentials headed for permanent git history). Values replaced with `REDACTED-AS-022-2026-06-12-*` placeholders; verified 0 residuals across both subdirs. hc-ping UUID URL left as-is (ping-only, same class as existing archived plists). Restore path unaffected — credentials belong in Keychain per standing lesson, never in plist env blocks.

**Acceptance:** Both users' agents enumerated in run-log (2026-06-11 + today's re-list); zero active; dormant agentic plists disabled/archived: **YES** ✓

**Resurrection surface now closed:** a tess or openclaw GUI login starts nothing — both LaunchAgents dirs are clean of agentic plists. Remaining for AS-021: post-reboot danny-domain inventory match only.

## 2026-06-14 — Session opener: AS-018 + AS-027 confirmations (06-13 session skipped)

**Context:** No session ran 2026-06-13, so the planned opener confirmations execute now; two scheduled backup cycles (06-13 03:00, 06-14 03:00) have fired in the interim — stronger evidence than the single fire the plan called for.

**AS-018 ✓ → done.** Two scheduled tarballs present in iCloud under the new label (`com.crumb.vault-backup`): `crumb-vault-2026-06-13_0300.tar.gz` (120.2 MB) + `crumb-vault-2026-06-14_0300.tar.gz` (120.2 MB). `_system/logs/backup-status.json` reports `status: ok`, latestFile = 06-14 tarball, ageHours 14. Marker file (`vault-backup-last.json`) agrees. Old `com.tess.vault-backup`/`com.tess.backup-status` labels absent from `launchctl list`. Retention holding <30 files. (Aside: TimeMachine sub-status = `unknown`/null — separate check, out of AS-018 scope; noted for AS-031 soak.)

**Keep-set inventory check:** `launchctl list` shows exactly 10 `com.crumb.*` labels — 8 scheduled jobs idle at status 0 (backup-status, drive-sync, qmd-index, system-stats, vault-backup, vault-gc, vault-health, vault-rebuild) + 2 running services (cloudflared PID, vault-web PID). `com.crumb.dashboard` correctly absent (deliberately stopped since 2026-06-01). Zero tess/openclaw/hermes/ollama/llama survivors.

**AS-027 ✓ → done.** Post-cycle the tree was NOT clean: `_system/state/last-run/vault-health` (an 11-byte epoch marker, tracked since its dir was created 06-12 12:00, rewritten every vault-health run: `1781280026`→`1781417219`) was the 6th churn file, missed in the 06-12 sweep. Fix: gitignored `_system/state/last-run/` + `git rm --cached` (kept on disk). `git check-ignore` confirms; tree reaches clean post-commit. TCC note reconfirmed: the user shell CAN list the iCloud backup dir even though launchd can't — the marker-file design remains correct.

**Risk:** low (gitignore extension + untrack of toolchain churn, within AS-027 scope). Proceed + flag.

**Remaining:** AS-021 (operator reboot resurrection test) is now the **sole** open human-gated item before AS-030. Its only check is a post-reboot `launchctl list` match against the 10-label end-state above. AS-030 closeouts unblock the moment AS-021 passes; then AS-031 soak (7 days) → AS-032.

## 2026-06-14 — AS-021: reboot resurrection test (operator) — PASS

**Trigger:** Operator rebooted the machine and returned ("just completed the reboot"). This is the sole boot-gated check.

**Method:** post-reboot `launchctl list` (danny / uid 503) reconciled against the design end-state — keep-set match + scrapped-label resurrection check + running-service liveness.

**Timing observation (recorded for completeness):** first `launchctl list` immediately on return showed **zero** `com.crumb.*` labels — GUI login agents had not finished bootstrapping. Seconds later all 10 were present. Resurrection is clean but not instantaneous; not a failure mode, just login-agent bootstrap latency. (Worth knowing for any future automated reboot check — don't sample launchctl in the first ~minute post-login.)

**Result — exact match to end-state inventory (dashboard excluded):**
- **10 `com.crumb.*` labels live**, reconciled 1:1 against the service-inventory disposition table: 8 idle scheduled jobs (system-stats `KEEP-D`, vault-backup `KEEP-P`, backup-status `KEEP-P`, vault-gc `KEEP-P`, vault-health `KEEP-P`/new, drive-sync `FIX`, vault-rebuild `KEEP-D`, qmd-index `KEEP-D`) + 2 running services (cloudflared **PID 1195**, vault-web **PID 1198**).
- **Liveness:** vault-web :8843 → HTTP 200; cloudflared holds live PID.
- **Scrapped-label resurrection check — all ABSENT:** `com.tess.*`, `com.tess.v2.*`, `ai.openclaw.*` (incl. gateway), `ai.hermes.gateway`, `homebrew.mxcl.ollama`, `com.crumb.apple-snapshot`, `com.crumb.telemetry-rollup`. The AS-022 pre-sweep held — nothing from the tess/openclaw user domains came up either (login-gated, no GUI session).
- **`com.crumb.dashboard`** correctly absent (override DB `=> disabled`; deliberately stopped since 2026-06-01 — restart remains a separate operator decision, not auto-restored).
- Harmless: `com.crumb.telemetry-rollup` still reads `=> enabled` in the override registry but its plist is archived, so it cannot load — consistent with SCRAP.

**Acceptance:** Post-reboot `launchctl list` matches end-state inventory exactly (dashboard excluded): **YES** ✓

**Gate impact:** AS-021 was the last open human-gated item. AS-030 (project closeouts: tess-v2 → DONE, tess-danny-migration → DONE/P7-superseded, mission-control paused note, XD-026 resolve) is now fully unblocked — all deps (AS-021/022/024/027/028/029) done. Then AS-031 7-day soak → AS-032 final compound + archival proposals.

## 2026-06-14 — AS-030: project closeouts + XD sweep — DONE

**Context inventory (in context, 0 new doc loads beyond targets):** tasks.md (AS-030 row + deps), the three target project-states (tess-v2, tess-danny-migration, mission-control) + their run-log tails, cross-project-deps.md (full). Risk: low (planned closeouts on reversible phase fields + a tracking table). Proceeded after operator go-ahead.

**Closeouts executed:**
- **tess-v2 → DONE** (was IMPLEMENT). Closeout entry written. The Tess execution layer it built is fully decommissioned + reboot-verified absent, so the project's subject no longer exists; the draft AC narrowing amendment is overtaken by events (no ratification needed). Durable knowledge preserved independently (23 Category A patterns + index + 3 `solutions/` extractions; repo retained). KB-bearing → stays in Projects/; archival deferred to AS-032.
- **tess-danny-migration → DONE** (was TASK, status → done). Closeout entry written. P7 (retire tess) was superseded by agentic-sunset and executed here: TDM-060 ↔ AS-012/022, TDM-061 ↔ AS-022, TDM-062 → AS-032, TDM-063 → the closeout entry. Rollback window formally closed by AS-022/AS-021 (archived, not deleted).
- **mission-control → PAUSED** (phase unchanged at TASK, status active → paused). NOT closed — the dashboard/publishing stack is kept; only `com.crumb.dashboard` is deliberately stopped (since 2026-06-01). Paused note added to project-state + run-log; restart is a standalone operator decision.

**XD table sweep (`_system/docs/cross-project-deps.md`):**
- **XD-026 → Resolved** (with resolution text + date 2026-06-14).
- **17 rows mooted** (status → `mooted`, dated note): tess-operations rows XD-001/004(FIF)/008/013/016/022/023; A2A rows XD-003/006/010/012; autonomous-operations rows XD-017/018; tess-v2 rows XD-024/025; FIF/MAD row XD-002/011. Marked in place (disable+archive ethos — not deleted), reversible.
- **XD-027 note updated** — AS-side (M6 AS-025–029 + AS-021) now satisfied; VO-031/032 gated only on VO-016. Row stays active (it's vault-optimization's gate to close).
- **6 rows left active by judgment, flagged to operator:** XD-005/007/009 ("no upstream project exists" — MC wishlist, never blocked on teardown'd infra); XD-019/020/021 (upstream mcp-workspace-integration survives — Google Workspace MCP is now native/live; dormant only because MC is paused).

**Acceptance:** Both project-states phase DONE with closeout entries; XD-026 in Resolved; mooted rows marked: **YES** ✓

**Gate impact:** Only AS-031 (7-day soak) and AS-032 (final compound + archival proposals) remain. AS-031 has nothing to *do* today beyond starting the clock — daily green check (fresh backup tarball, drive-sync green from danny path, no alerts, vault-web up, tree clean) for 7 consecutive days. First soak day = 2026-06-14 (today's evidence: AS-018 confirmed 2 backup cycles; AS-021 keep-set green; vault-web :8843 → 200). Target soak completion 2026-06-20 → then AS-032.

## AS-031 — 7-Day Soak Tracker (started 2026-06-14)

**Daily green check, 5 points:** (1) fresh backup tarball under `com.crumb.vault-backup`; (2) drive-sync green from the danny path; (3) no healthchecks alerts (check stays paused); (4) vault-web :8843 up + keep-set = 10 `com.crumb.*`; (5) working tree clean. **Target: 7 consecutive green → AS-031 done → AS-032.**

**Mechanism (chosen over `/schedule`):** `/schedule` creates *cloud* routines that cannot reach this Mac's launchd / `localhost:8843` / iCloud backup dir / local working tree — so it cannot run this soak. Driving it instead via the **session-opener** (zero new daemon — on-ethos for a teardown): each Crumb session, run the 5-point check and tick the day below. No-session days are backfilled after the fact from `_system/logs/backup-status.json` + `_system/logs/vault-backup-last.json` (the backup writes daily regardless of sessions). Check commands captured in Day 1 below. *(Alt available on request: a temporary local launchd timer, auto-removed at AS-032 — declined by default as it re-adds the exact infra this project removes + risks AS-027-style commit churn.)*

- **Day 1 — 2026-06-14 ✅ GREEN.** Backup: `status: ok`, `crumb-vault-2026-06-14_0300.tar.gz` (120.2 MB), ageHours 16, marker agrees. Drive-sync: post-commit hook ran 19:11 from danny path — NotebookLM + Computer sync DONE, no errors (`/tmp/drive-sync.log`). Alerts: healthchecks paused, none. vault-web :8843 → HTTP 200; keep-set = 10 `com.crumb.*` (reboot-verified earlier today via AS-021). Tree: clean post-commit `ac101ad4`. (TimeMachine sub-status still `unknown`/null — known separate check, out of soak scope; noted for AS-032.)
- Day 2 — 2026-06-15 — pending
- Day 3 — 2026-06-16 — pending
- Day 4 — 2026-06-17 — pending
- Day 5 — 2026-06-18 — pending
- Day 6 — 2026-06-19 — pending
- Day 7 — 2026-06-20 — pending → on 7/7 green, mark AS-031 done, advance to AS-032

## 2026-06-14 — Session-end (compound evaluation)

**Session summary:** Operator rebooted → AS-021 reboot resurrection test PASSED (10-label keep-set resurrects, nothing agentic comes back, dashboard correctly off). AS-030 closeouts executed (tess-v2 → DONE, tess-danny-migration → DONE, mission-control → paused; XD-026 resolved + 17 rows mooted). AS-031 soak started, day 1 GREEN. `claude-ai-context.md` refreshed to current state. Two commits + pushes (ac101ad4, 9d5cc303), both vault-check 0/0.

**Compound evaluation:**
1. **`/schedule` (cloud routines) cannot run local-state checks — tool-selection gotcha.** I offered, and the operator agreed to, a `/schedule` for the AS-031 soak — then caught at setup that `/schedule` creates *cloud* agents that can't reach this Mac's launchd, `localhost:8843`, the iCloud backup dir, or the local working tree (4 of the 5 soak checks). Self-corrected to a session-opener-driven check (zero new infra, on-ethos for a teardown). **Routing:** recorded to the `recurring-patterns` auto-memory (operational/tool-selection gotcha class, alongside CLI-flag-hallucination and prompt-env-mismatch). General lesson: match the scheduler's execution locus to where the state lives — cloud scheduler ⇒ repo/remote state only; local launchd/cron or session-opener ⇒ host state.
2. **`session-end-protocol.md` carries stale dead-infra steps.** Step 2 (Amendment Z `tess session-report` → `~/.tess/state/session_reports.db`) and Step 8 (`rm -f _openclaw/inbox/.processed/*`) both reference infrastructure this very project decommissioned (Tess runtime; `_openclaw/` archived to `Archived/`). The doc (updated 2026-04-06) predates the teardown. **Routing:** flag for vault-optimization / next audit — same class as the AS-028 "stale skill body-text residuals" open item (audit §15, learning-plan §7, researcher). Did NOT run those two steps this session (dead infra). Not fixing inline — out of AS scope; logged for the owning sweep.

**Code review sweep:** N/A — agentic-sunset has no `repo_path` (vault-only teardown). No code tasks this session; all changes are vault docs (YAML/markdown). Build verification: N/A (no build_command).

**Model routing:** all work main-session Opus 4.8; no Sonnet delegation — the session was judgment-dense (project-lifecycle closeouts, XD-row classification, a tool-selection correction). Appropriate. No token-heavy anomalies.

**State for next session:** AS-031 soak day 2 (2026-06-15) — run the 5-point check at session opener, tick the tracker. Only AS-031 + AS-032 remain.

## 2026-06-14 — Cross-project concurrence (vault-optimization VO-016)

Recorded from a vault-optimization session for XD-027 traceability — **not AS work**, no AS action required. VO-016 froze the joint-surface ownership matrix (`Projects/vault-optimization/keep-set-manifest.md` Appendix A).

**AS concurrence:** AS M6 (AS-025–029) complete 2026-06-12 + AS-021 reboot passed 2026-06-14 fully satisfy the AS-side gates the matrix records — CLAUDE.md (AS-025-first), skills/agents (AS-028 sunset-tied removal + AS M6 sign-off), harness memory (AS-029 ownership, VO never writes), `_openclaw/_tess/_staging` (AS-026/027, VO never touches). VO-031/032 (B4/B5 primitive batches) were gated only on VO-016; this freeze closes that gate. See `Projects/vault-optimization/progress/run-log.md` (VO-016 entry, same date). AS-031 soak tracker unaffected (day 1 already logged 2026-06-14; next check day 2 = 2026-06-15).

## 2026-06-19 — Residual cloud-side teardown gap: Gmail filters (operator-remediated)

**Trigger:** Operator — "a while back we did some automation work on my gmail inbox, I need to undo that because now I can't find anything." Presented as a personal-email problem; root cause is an **agentic-sunset teardown gap**, so it's logged here (not session-log) and feeds AS-032.

**Diagnosis:** The automation was `tess-operations` **TOP-017** (archived project), on the personal account **dturner71@gmail.com** (not the workspace `danny@dfriedrich.me`): 16 Gmail labels (`@Agent/* @Trust/* @Risk/* @Action/* P/*`) + **3 server-side Gmail filters** (`gmail.settings.basic` scope). The damage was **Filter A** — newsletters, criteria `unsubscribe OR "view in browser" OR "manage preferences"` → apply `@Agent/IN` + `@Trust/External` + **skip inbox**. The TOP-031 triage *script* that was meant to consume `@Agent/IN` died in the AS teardown, but **the filters live server-side at Google and kept running ~3 months** — force-archiving incoming mail with nothing processing it. The criteria also swept the operator's **Beacon Zen sangha Google Group** (its list footer carries an unsubscribe link → read as "newsletter") and transactional mail (a BMW open safety-recall), so genuinely-wanted mail was buried, not just promos. The 16 `@Agent` labels were already gone, so swept mail had **no label** — findable only in All Mail. Exactly the "mail went missing" failure `tess-google-services-spec §3.2` warned about.

**Remediation (operator-executed manually in Gmail UI):** (1) deleted the 3 filters; (2) bulk-restored the swept backlog to Inbox via `in:archive from:beaconzen.org -label:"Beacon Zen"` → Move to Inbox — ~67 sangha threads (Jan–Jun 2026, the no-label set; the 2023–24 `Beacon Zen`-labeled archive deliberately excluded as pre-automation) + 3 BMW recall threads. Genuine marketing (TurboTax/HelloFresh/dealers/etc.) left archived. Gray-area subscriptions (poem-a-day, Tricycle, a Perplexity research email) flagged, left to operator.

**Tooling reality (recorded):** Crumb could **diagnose but not execute** the fix. The claude.ai Gmail connector is **read-only** (write ops → `insufficient authentication scopes`); the `google-workspace` MCP has write scope but **auth is dead for both** `danny@dfriedrich.me` and `dturner71@gmail.com` (credential store revoked at teardown). Operator chose the manual route over re-authorizing — which also **keeps the personal-Gmail agent-access surface closed**, consistent with AS intent. Crumb made **zero mailbox writes** (the one batch attempt failed cleanly — no partial state).

**Compound — a teardown's blast radius includes externally-hosted state.** AS's `design/service-inventory.md` was exhaustive on *local* host state (launchd labels, crontab, daemons) but never enumerated the **cloud-side artifacts** tess-operations created on third-party services. Gmail filters are the proven case; the same risk applies to TOP-018/023/024 outputs: the **Google "Agent — Staging" / "Agent — Followups" calendars** (`google-calendars.json`), the **Drive `00_System/Agent/*` folder tree** (`google-drive-folders.json`), and the **"Tess Ops" Discord server** (12 channels). These persist regardless of the local decommission. **Routing → AS-032:** add an *external-artifact sweep* to the final closeout — verify/clean residual cloud-side config on Gmail (done), Calendar, Drive, Discord. Generalizes the 2026-06-14 scheduler-execution-locus lesson: a decommission must account for state hosted *off the machine*, not just on it. Routed to `recurring-patterns` + `project-agentic-sunset` auto-memories.

**Soak note:** AS-031 day 6 (2026-06-19) 5-point check **not run** this session (Gmail-remediation, not an AS soak opener) — backfillable from `backup-status.json` + `vault-backup-last.json`. Day 7 target 2026-06-20.

**Model routing:** all main-session Opus 4.8 — vault-archaeology + judgment-dense classification of ~200 archived threads (sangha vs. marketing vs. pre-automation). No delegation. Token-heavy op: paginating the archived-thread search (large snippet payloads), acceptable for the precision required.
