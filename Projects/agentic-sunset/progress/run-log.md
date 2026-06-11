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
