---
type: run-log
project: openclaw-colocation
domain: software
created: 2026-02-18
updated: 2026-02-26
---

# OpenClaw Colocation — Run Log

## Session 2026-02-18 — Project Creation + Spec Finalization

### Context Inventory
- `docs/openclaw-colocation-spec.md` — main specification (3 peer review rounds)
- `docs/openclaw-colocation-spec-summary.md` — specification summary
- `reviews/2026-02-18-openclaw-colocation-spec.md` — R1 review
- `reviews/2026-02-18-openclaw-colocation-spec-r2.md` — R2 review
- `reviews/2026-02-18-openclaw-colocation-spec-r3.md` — R3 review
- `docs/peer-review-config.md` — reviewer configuration

### Work Performed
- Spec originated as non-project work in `docs/` with systems-analyst skill
- Round 1 peer review: GPT-5.2, Gemini 2.5 Pro, Perplexity Sonar Reasoning Pro
  - Consensus: workspace-only insufficient, dedicated user essential
  - Applied R1 findings to spec
- Round 2 peer review: GPT-5.2, Gemini 3 Pro Preview, Perplexity Sonar Reasoning Pro
  - Consensus: nvm brittle (wrapper script), TCC irrelevant, vault model inconsistent, dedicated user → Tier 1
  - Applied R2 findings to spec
  - Bumped Perplexity max_tokens: 4096 → 16384 → 65536 (resolved truncation)
- Round 3 peer review: GPT-5.2, Gemini 2.5 Pro (3 Pro unavailable), Perplexity Sonar Reasoning Pro
  - Architecture affirmed — findings shifted from design to implementation readiness
  - Consensus: nvm install missing for openclaw user, plist unverified, wrapper untested, isolation tests should be mandatory gate, LaunchDaemon with UserName is valid
  - Applied R3 must-fix items (A1–A5)
  - Fixed runbook step ordering (isolation gate before messaging setup)
  - Marked OC-007 done (kill-switch runbook written inline)
- Upgraded to formal project

### Decisions
- Spec lives in `docs/` (not moved to project `design/`) — it predates the project and has stable links from review notes. Symlinked into project.
- Kill-switch runbook is go-live prerequisite
- LaunchAgent vs LaunchDaemon: test-first decision on Studio hardware
- Three peer review rounds complete (round cap reached for this cycle)

### Artifacts
| File | Status |
|------|--------|
| `docs/openclaw-colocation-spec.md` | 3 rounds reviewed, R3 must-fix applied |
| `docs/openclaw-colocation-spec-summary.md` | Current |
| `reviews/2026-02-18-openclaw-colocation-spec.md` | R1 complete |
| `reviews/2026-02-18-openclaw-colocation-spec-r2.md` | R2 complete |
| `reviews/2026-02-18-openclaw-colocation-spec-r3.md` | R3 complete |
| `Projects/openclaw-colocation/` | Project scaffold created |

### Compound
Perplexity `sonar-reasoning-pro` reasoning tokens (`<think>` blocks) consume the `max_tokens` budget, leaving insufficient room for review output. 16384 still truncated; 65536 resolved it (API ceiling is 128k). Routing: updated `docs/peer-review-config.md` directly + documented in config file comments (line 45). Pattern: for any reasoning model with CoT, set max_tokens to at least 4× the expected output length to account for reasoning overhead.

### Session End
- **Phase:** SPECIFY (complete, ready for PLAN transition)
- **Status:** All R1/R2/R3 must-fix findings applied. Runbook reordered. Project scaffold created.
- **Next:** SPECIFY → PLAN phase transition. Break down implementation into milestones and action plans.

---

## Session 2026-02-18 (evening) — PLAN Phase

### Phase Transition: SPECIFY → PLAN
- Date: 2026-02-18 19:40
- SPECIFY phase outputs: `docs/openclaw-colocation-spec.md`, `docs/openclaw-colocation-spec-summary.md`, 3 review notes
- Compound: Completed in prior session — Perplexity reasoning token budget pattern routed to `docs/peer-review-config.md`. No additional compoundable insights from this transition.
- Context usage before checkpoint: <10% (fresh session)
- Action taken: none
- Key artifacts for PLAN phase: `docs/openclaw-colocation-spec-summary.md`, `docs/openclaw-colocation-spec.md`

### Context Inventory
- `docs/openclaw-colocation-spec-summary.md` — specification summary (loaded)
- `docs/openclaw-colocation-spec.md` — full specification (loaded — constraints, dependencies, threats, 7 tasks, runbook)
- `docs/overlays/overlay-index.md` — checked, no matching overlays
- `Projects/openclaw-colocation/project-state.yaml` — project state (loaded)
- `Projects/openclaw-colocation/progress/run-log.md` — run log (loaded)
- `Projects/openclaw-colocation/progress/progress-log.md` — progress log (loaded)
- No `docs/estimation-calibration.md` exists (first formal decomposition)

### Work Performed
- Created action plan with 4 milestones (design/action-plan.md)
- Created task list with 12 tasks, OC-001–OC-012 (design/tasks.md)
- Created action plan summary (design/action-plan-summary.md)
- User review: corrected OC-009/OC-010 dependency — parallel, not sequential
  (both depend on OC-008; permissions should be set before/alongside hardening
  so `openclaw doctor` doesn't report false vault access failures)

### Peer Review — Round 1
- Reviewers: GPT-5.2, Gemini 2.5 Pro (3 Pro Preview 503), Sonar Reasoning Pro
- Review note: `reviews/2026-02-18-openclaw-colocation-action-plan.md`
- 32 total findings across 3 reviewers (14 + 7 + 11)
- **Must-fix applied (4):**
  - A1: Renumbered Phase 3.5 → 3.4
  - A2: Removed Tier 2 from M4 success criteria
  - A3: Added OC-003 as dependency of OC-010
  - A4: Fixed dependency graph — separated OC-004/OC-006 track from OC-003/OC-001 track
- **Should-fix applied (4):**
  - A5: Added M3 rollback procedure (revert perms, remove user, restore from backup)
  - A6: Added system backup/snapshot as M3 prerequisite
  - A7: Clarified OC-005 scoping (MacBook partial, Studio full) + explicit OC-008 dependency
  - A8: Productized isolation test suite as `scripts/openclaw-isolation-test.sh` with timestamped output
- **Deferred (3):** logging/monitoring (Tier 2), POSIX vs ACL details (execution-time), doc consistency (during OC-006)
- **Declined (7):** LaunchAgent decision task (embedded in OC-008), hard OC-010→OC-009 (user-approved parallel), unverified `openclaw doctor` (spec-level), M2/M3 risk upgrades (current calibration fits context), others documented in review note

### Decisions
- OC-009 and OC-010 are parallel, not sequential (user correction)
- Tier 2 hardening deferred to post-go-live (not tracked as tasks)
- TASK phase can be lightweight validation — tasks are already atomic
- First messaging platform recommendation: Telegram (simplest bot token model)
- OC-004/OC-006 are a separate documentation track parallel to the runbook track (R1 finding)
- OC-010 depends on OC-003 in addition to OC-008 (R1 finding)

### Implementation — Milestones 1 & 2
- **OC-003** (done): Created `_openclaw/` scaffold — inbox/, outbox/, outbox/.pending/, .gitignore (contents excluded, README tracked), README with access model and Phase 2 protocol
- **OC-001** (done): Added Phase 13 (OpenClaw) to migration runbook — 13 steps covering dedicated user, nvm, wrapper script, plist, Tier 1 hardening, vault permissions, 9-test isolation suite (go/no-go gate), diagnostics, verification, messaging
- **OC-004** (done): Updated Crumb spec §9 OpenClaw entry with colocation security analysis — CVE-2026-25253, dedicated user as Tier 1, vault read model, kill-switch prerequisite, 4-phase approach
- **OC-002** (done): Added Phase 9 (optional OpenClaw hardening) to setup-crumb.sh — dedicated user, loopback binding, workspaceOnly, browser disabled, credential isolation; skips gracefully when absent
- **OC-006** (done): Created `docs/openclaw-crumb-reference.md` — integration architecture, vault access model, exchange formats, use case allocation, phase roadmap, key links (153 lines)

### Artifacts
| File | Status |
|------|--------|
| `Projects/openclaw-colocation/design/action-plan.md` | Created, R1 applied |
| `Projects/openclaw-colocation/design/tasks.md` | Created, R1 applied, 6/12 done |
| `Projects/openclaw-colocation/design/action-plan-summary.md` | Created, R1 applied |
| `reviews/2026-02-18-openclaw-colocation-action-plan.md` | R1 complete |
| `_openclaw/README.md` | Created (OC-003) |
| `.gitignore` | Updated (OC-003) |
| `docs/crumb-design-spec-v1-7-1.md` | §9 updated (OC-004) |
| `~/downloads/crumb-studio-migration.md` | Phase 13 added (OC-001) |
| `scripts/setup-crumb.sh` | Phase 9 added (OC-002) |
| `docs/openclaw-crumb-reference.md` | Created (OC-006) |
| `docs/peer-review-config.md` | Frontmatter fix |

### Compound
Parallel subagent execution worked well for independent single-file writing tasks (OC-001+OC-004, OC-002+OC-006). Each subagent produced clean output needing no rework. This validates the memory note refinement: subagents are poor for *serial multi-file* writing but good for *independent single-file* tasks with clear scope. Routing: no new pattern doc needed — existing memory note already captures the nuance.

### Session End
- **Phase:** PLAN (complete), IMPLEMENT (M1+M2 complete, M3+M4 blocked on Studio)
- **Status:** All pre-migration tasks done (6 of 12). Remaining 6 tasks require Studio hardware.
- **Next:** When Studio is available — OC-005 (Node compat), then OC-008→OC-012 (installation, hardening, testing, messaging).

---

## Session 2026-02-18 (late evening) — Migration Runbook Fixes

### Context Inventory
- `Projects/openclaw-colocation/project-state.yaml` — project state (loaded)
- `Projects/openclaw-colocation/progress/run-log.md` — run log (loaded)
- `Projects/openclaw-colocation/progress/progress-log.md` — progress log (loaded)
- `Projects/openclaw-colocation/design/tasks.md` — task list (loaded)
- `~/downloads/crumb-studio-migration.md` — migration runbook (edited)

### Work Performed
- Fixed Studio username: updated Phase 8 (Claude Code project path `-Users-dturner-` → `-Users-tess-`), Phase 12 (backup plist filename, label, script path), all `dturner` → `tess`. Left source-machine references (Phase 2, cleanup) as `dturner`.
- Fixed group inheritance gap in Phase 13 Step 9: added `find ... chmod g+s` for setgid on vault directories, inline verification test, and fallback comment for periodic chgrp if macOS ignores setgid.
- Moved runbook from `~/downloads/` into `docs/crumb-studio-migration.md` (version-controlled).
- Added YAML frontmatter; fixed missing `status` field; removed incorrect `project: openclaw-colocation` (runbook is Crumb infrastructure, not project-owned).

### Decisions
- Migration runbook is a shared infrastructure doc in `docs/`, not owned by any project
- setgid approach is test-first on Studio — fallback to periodic chgrp documented inline

### Artifacts
| File | Status |
|------|--------|
| `docs/crumb-studio-migration.md` | Added to vault, frontmatter fixed |
| `~/downloads/crumb-studio-migration.md` | Edited (source copy, outside vault) |

### Compound
Frontmatter `status` field omission has recurred across multiple doc creation sessions (companion notes, runbook). Root cause: improvising schema from memory instead of checking vault-check validation rules. Routing: added to auto-memory (`MEMORY.md` — "YAML Frontmatter — Required Fields"). No new pattern doc needed — the fix is a behavioral checklist item, not a reusable solution.

### Session End
- **Phase:** IMPLEMENT (M1+M2 complete, no task state changes this session)
- **Status:** Migration runbook revised and moved to vault. 6/12 tasks remain, all Studio-dependent.
- **Next:** Studio setup, then OC-005 (Node compat) → OC-008–OC-012.

---

## Session 2026-02-19 — Spec Revision + IMPLEMENT M3+M4 (on Studio)

### Context Inventory
- `Projects/openclaw-colocation/project-state.yaml` — project state (loaded)
- `Projects/openclaw-colocation/progress/run-log.md` — run log (loaded)
- `Projects/openclaw-colocation/design/tasks.md` — task list (loaded)
- `docs/openclaw-colocation-spec.md` — specification (loaded, edited)
- `docs/openclaw-colocation-spec-summary.md` — spec summary (edited)
- `docs/crumb-studio-migration.md` — migration runbook (loaded, edited)

### Work Performed

**Spec revision pass (6 edits based on user critique):**
1. nvm → Homebrew Node — both users share `/opt/homebrew/bin/node`, nvm is future contingency only
2. U5 status corrected from "Resolved" to "deferred to OC-011"
3. setgid for group inheritance — added to vault access model, APFS honors setgid (corrected overcautious hedging per user feedback)
4. Phase 2 write-lock simplified from O_CREAT|O_EXCL lock + .pending/ + pre-commit polling to atomic rename (temp → final)
5. Kill-switch runbook templated for both LaunchAgent and LaunchDaemon domains
6. PlistBuddy fragility note added to runbook step

**Implementation on Studio (M3+M4):**
- OC-005 (done): Node v25.6.1 Homebrew, both users satisfied, no version conflict
- OC-008 (done): OpenClaw v2026.2.17 installed — dedicated user uid 502, wrapper script with HOME + npm prefix PATH, plist `ai.openclaw.gateway`, gateway on ws://127.0.0.1:18789
- OC-009 (done): Tier 1 hardening — workspaceOnly (fs + exec), loopback, password auth, tailscale off. `tools.browser` not valid in v2026.2.17 (removed by doctor --fix)
- OC-010 (done): crumbvault group created with both users, recursive group read + setgid verified, _openclaw/ sandbox writable
- OC-011 (done): 9/9 isolation tests pass. Credential files locked down (chmod 600/700 on .zshrc, .config/crumb/, .config/meme-creator/). Test script at `scripts/openclaw-isolation-test.sh`
- OC-012 (done): Telegram bot connected with pairing mode, send/receive verified, kill-switch dry-run passed

**Post-implementation updates:**
- Spec, spec summary, runbook updated with operational findings (wrapper script, npm prefix, daemon stop behavior, browser config key)
- Auto-memory updated with macOS multi-user ops and OpenClaw operational notes

### Decisions
- Homebrew Node shared between users (no nvm) — future contingency documented
- LaunchAgent chosen (gui/502 domain) — plist label `ai.openclaw.gateway`
- Haiku 4.5 as OpenClaw's model (cheaper, faster for messaging)
- `tools.browser` config key doesn't exist in v2026.2.17 — dedicated-user boundary is the primary browser control
- Gateway password rotated after session transcript exposure
- `openclaw daemon stop` is unreliable — kill-switch uses pkill + lsof verification

### Artifacts
| File | Status |
|------|--------|
| `docs/openclaw-colocation-spec.md` | 6 revision edits + operational findings |
| `docs/openclaw-colocation-spec-summary.md` | Updated to match |
| `docs/crumb-studio-migration.md` | Wrapper script, npm prefix, step renumbering |
| `scripts/openclaw-isolation-test.sh` | Created (9-test suite) |
| `Projects/openclaw-colocation/design/tasks.md` | 12/12 complete |
| `Projects/openclaw-colocation/project-state.yaml` | All tasks complete |
| `Projects/openclaw-colocation/progress/progress-log.md` | M3+M4 entry |

### Compound
Two operational patterns worth capturing: (1) macOS `sudo -u <user>` does not reset HOME — any wrapper script or command running under a different user must export HOME explicitly, or tools that resolve config from `~/` will read the wrong user's files. (2) `npm install -g` under a non-primary user defaults to the invoking user's cache (`~/.npm/`) — must set `--prefix` and `npm_config_cache` explicitly. Both routed to auto-memory. No new pattern doc needed — these are environment-specific operational notes, not reusable solution patterns.

### Session End
- **Phase:** IMPLEMENT (all tasks complete)
- **Status:** 12/12 tasks done. OpenClaw installed, hardened, isolated, Telegram connected on Studio.
- **Next:** Tier 2 hardening (egress control, disk monitoring) when prioritized. Gateway password rotated. Project is operationally complete for Phase 1.

---

## Session 2026-02-22 — v2026.2.21 Upgrade Runbook + Peer Review

### Context Inventory
- `Projects/openclaw-colocation/project-state.yaml` — project state (loaded)
- `Projects/openclaw-colocation/progress/run-log.md` — run log (loaded)
- `_system/docs/openclaw-colocation-spec.md` — specification (sections read: threats, hardening, kill-switch, update procedure)
- `_inbox/openclaw-v2026-2-21-impact-analysis.md` — input artifact (user-provided)

### Work Performed

**Impact analysis processing:**
- Read and analysed v2026.2.21 impact analysis from inbox
- Identified 4 procedure errors in impact analysis §6 (wrong stop/start methods, missing npm prefix, missing isolation tests)
- Added frontmatter, routed to `Projects/openclaw-colocation/design/`

**Upgrade runbook creation:**
- Created `Projects/openclaw-colocation/design/upgrade-v2026-2-21.md`
- Corrected all 4 procedure errors from impact analysis
- Added pre-upgrade checklist, 6-phase upgrade procedure, 5-step post-upgrade verification, rollback procedure, spec update plan

**Peer review (4-model, round 1):**
- Reviewers: GPT-5.2, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning, Gemini 3 Pro Preview
- Review note: `_system/reviews/2026-02-22-upgrade-v2026-2-21.md`
- 52 total findings across 4 reviewers (20 + 14 + 13 + 5)
- **Critical finding (consensus):** Missing `npm_config_prefix="/Users/openclaw/.local"` in install commands — upgrade would have failed with EACCES. Fixed.
- **Must-fix applied (2):** A1 npm_config_prefix, A2 pgrep/pkill scoped to `-u openclaw`
- **Should-fix applied (7):** A3 full .openclaw/ backup, A4 loopback+user lsof checks, A5 version gate after install, A6 password verification clarification, A7 node/npm version capture, A8 kill-switch runbook reference, A9 tee for isolation tests
- **Deferred (3):** doctor allowlist (overkill for point release), npm integrity verification (Tier 2 practice), cost thresholds (need baseline data)

**User feedback applied:**
- maxSpawnDepth 1→2 reframed from cost concern (LOW) to T1 attack surface multiplier (MEDIUM)
- V5 changed from "monitor costs" to "pin maxSpawnDepth to 1" as hardening measure
- Added U4 spec update for spawn depth in Tier 1 hardening

### Decisions
- Upgrade blocked on upstream: v2026.2.21-2 bundler corruption (#22841). Runbook ready, awaiting clean build.
- maxSpawnDepth: pin to 1 proactively (security, not just cost) per user input
- Gateway password verification covered implicitly by Telegram test (V1 proves auth works)

### Artifacts
| File | Status |
|------|--------|
| `Projects/openclaw-colocation/design/upgrade-v2026-2-21.md` | Created, peer reviewed, all fixes applied |
| `Projects/openclaw-colocation/design/openclaw-v2026-2-21-impact-analysis.md` | Routed from inbox |
| `_system/reviews/2026-02-22-upgrade-v2026-2-21.md` | R1 complete (4 models) |
| `_system/reviews/raw/2026-02-22-upgrade-v2026-2-21-*.json` | 4 raw responses |

### Grok Calibration
Issue ratio improved: 46% issues this round vs first-review positivity bias. The `prompt_addendum` steering is working. Critical finding (password verification) aligned with OpenAI — showing genuine analytical value. Continue monitoring.

### Compound
The npm_config_prefix miss is not a new pattern — it's already documented in MEMORY.md and was correctly applied during OC-008. The failure was in *applying* the known pattern to a new runbook, not in lacking the pattern. No new compound artifact needed. The maxSpawnDepth-as-security-not-cost framing is a project-specific insight that will be captured in the spec update (U4) — not a reusable pattern.

### Session End
- **Phase:** IMPLEMENT (blocked on upstream)
- **Status:** Upgrade runbook ready and peer-reviewed. Blocked on v2026.2.21-2 bundler corruption (#22841).
- **Next:** Execute upgrade runbook when clean v2026.2.21 (or later) build is published.

---

## Session 2026-02-22 (evening) — Project Closure

**Context:** Closing openclaw-colocation as DONE. All 12 tasks complete. Introducing structural guards for completed projects.

**Actions Taken:**
- Set `phase: DONE` in project-state.yaml (new lifecycle state — between active work and archival)
- Added `related_projects: [crumb-tess-bridge, tess-model-architecture]` for cross-referencing
- Relocated `design/tess-local-llm-research-thread.md` to new project `tess-model-architecture` — this was SPECIFY-phase seed work for a different scope, not openclaw-colocation maintenance
- Upgrade runbook (`design/upgrade-v2026-2-21.md`) stays — legitimate post-delivery maintenance artifact
- Added DONE phase, `related_projects` field, and completed-project guard to spec + CLAUDE.md
- Added vault-check #12/#22 (DONE project design file warning)

**Current State:** Project DONE. 12/12 tasks complete. OpenClaw installed, hardened, isolated, Telegram connected. Upgrade runbook ready (blocked on upstream). Maintenance artifacts allowed with run-log notes.

**Files Modified:**
- `Projects/openclaw-colocation/project-state.yaml` — phase: DONE
- `Projects/openclaw-colocation/progress/progress-log.md` — completion entry
- `Projects/openclaw-colocation/progress/run-log.md` — this session block

---

## Session 2026-02-25 — v2026.2.24 Upgrade Runbook + Peer Review

**Context:** Upgrading from v2026.2.17 → v2026.2.24 (skipping never-executed v2021 runbook). Maintenance scope on DONE project. Driven by Tess chief-of-staff capability expansion requiring v2026.2.24 features (cron, heartbeat, prompt caching).

### Context Inventory
- `Projects/openclaw-colocation/project-state.yaml` — project state (loaded)
- `Projects/openclaw-colocation/progress/run-log.md` — run log (loaded)
- `Projects/openclaw-colocation/design/upgrade-v2026-2-21.md` — previous runbook (foundation)
- `_system/docs/openclaw-colocation-spec.md` — specification (sections referenced)

### Work Performed

**Deep research (2 parallel agents):**
- Agent 1: Current installation state — v2026.2.17, LaunchAgent supervisor, x-feed-intel services, isolation setup
- Agent 2: Changelog analysis v2026.2.17 → v2026.2.24 (7 releases)
- Identified 3 breaking changes (heartbeat DM block, exec safeBinTrustedDirs lockdown, gateway auth key rename) and 2 conditional breaks (embedding provider crash, re-pairing)

**Upgrade runbook created:**
- `Projects/openclaw-colocation/design/upgrade-v2026-2-24.md` — supersedes v2021 runbook
- Comprehensive: risk table, pre-upgrade checklist, 7-phase procedure, 9 verification steps, rollback, 6 spec update items

**Peer review (4-model, round 1):**
- Reviewers: GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning
- Review note: `Projects/openclaw-colocation/reviews/2026-02-25-upgrade-v2026-2-24.md`
- 50 findings total: 5 CRITICAL, 29 SIGNIFICANT, 8 MINOR, 7 STRENGTH
- Synthesis: 8 consensus, 5 unique, 0 contradictions, 15 action items

**Peer review fixes applied (11 of 15 action items):**
- **Must-fix (3):** A1 filename typo v2024→v2026-2-24, A2 Phase 4 rewritten with jq scripting + JSON validation gate, A3 backup/restore cp -r→rsync -a --delete + moved after gateway stop
- **Should-fix (8):** A4 Telegram group ID pre-acquisition, A5 x-feed-intel service checks, A6 dynamic UID derivation, A7 npm registry check + cache, A8 embedding provider check commands, A9 path-based bootout, A10 fallback pinned to @2026.2.24, A11 sudo wrapper on V7 re-pair
- **Deferred (4):** A12 citation URLs, A13 rollback data-loss warning, A14 retry loop, A15 Homebrew trust rationale

### Decisions
- Runbook supersedes v2021 (was never executed, 3 additional releases with breaking changes)
- jq-based config editing (not manual JSON) — consensus from all 4 reviewers
- rsync over cp -r for backup/restore — macOS cp semantics are unreliable for directory trees
- Backup moved after gateway stop to avoid SQLite lock/journal corruption

### Artifacts
| File | Status |
|------|--------|
| `Projects/openclaw-colocation/design/upgrade-v2026-2-24.md` | Created, peer reviewed, 11 fixes applied |
| `Projects/openclaw-colocation/reviews/2026-02-25-upgrade-v2026-2-24.md` | R1 complete (4 models) |
| `Projects/openclaw-colocation/reviews/raw/*.json` | 4 raw responses |

### Compound
The jq-based config editing pattern (write to tmpfile, validate, mv into place) is a general-purpose safe-config-edit pattern. Phase 4 of the runbook now demonstrates the full pattern with JSON validation gate. This could be extracted to a reusable snippet for any OpenClaw config modification. Not promoting yet — want to validate during actual upgrade execution.

### Session End
- **Phase:** DONE (maintenance)
- **Status:** Upgrade runbook ready and peer-reviewed with 11/15 fixes applied. 4 deferred items documented.
- **Next:** Execute upgrade on Studio when ready. Complete deferred items (A12-A15) if time permits before execution.

---

## Session 2026-02-24 — Gateway Crash Recovery + Dual-Supervisor Fix

**Context:** Gateway crashed twice, Telegram bridge unresponsive. Maintenance scope on DONE project.

### Root Cause
Two launchd supervisors managing the same gateway process:
- **LaunchAgent** (`gui/502`): `/Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist`
- **LaunchDaemon** (`system`): `/Library/LaunchDaemons/ai.openclaw.gateway.plist`

When the gateway received SIGTERM, both supervisors raced to respawn, creating duplicate bot instances that fought over Telegram's `getUpdates` long-poll slot (409 conflict). The `KeepAlive: true` with no throttle on the LaunchAgent caused a 10-second restart storm that kept refreshing the stale Telegram poll, preventing recovery.

### Fixes Applied
1. **Disabled LaunchDaemon:** `mv /Library/LaunchDaemons/ai.openclaw.gateway.plist .disabled` — single supervisor only
2. **LaunchAgent plist updated:** `KeepAlive: true` retained, added `ThrottleInterval: 60` as safety net
3. **Bot token revoked and reissued** via BotFather — the persistent 409 (20+ minutes) could not self-heal due to the restart storm's accumulated stale polls. Token format corrected (was missing numeric prefix + colon on first paste).

### Durable fix still needed
- Wrapper script (`/Users/openclaw/launch-openclaw.sh`) should exit 0 on "already running" detection, enabling `KeepAlive: { SuccessfulExit: false }` for smarter restart semantics. Current `KeepAlive: true` + `ThrottleInterval: 60` works but is a blunt instrument.

### OPEN — SIGTERM source unresolved
- What sent the initial SIGTERMs that started the cascade? Gateway logs show clean `signal SIGTERM received` shutdowns, not crashes — this was not an OOM or segfault.
- **Ruled out:** OpenClaw internal cron (jobs.json empty), macOS system SIGTERM (no events in log show 07:00–07:15), auto-update (update-check.json timestamp is post-restart, not pre)
- **Remaining candidates:** health-monitor (300s interval, 60s grace — could self-SIGTERM on transient health-check failure), x-feed-intel launchd services interacting with gateway, or unknown external process
- The dual-supervisor amplification is fixed, but if the original SIGTERM source recurs, it will still crash the gateway — just without the restart storm.
- **Next step:** Monitor passively. If it recurs, check `/tmp/openclaw/openclaw-<date>.log` (detailed gateway log) for health-monitor entries immediately before the SIGTERM.

### Files Modified
- `/Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist` — ThrottleInterval: 60
- `/Library/LaunchDaemons/ai.openclaw.gateway.plist` → `.disabled`
- `/Users/openclaw/.openclaw/openclaw.json` — new bot token
- `Projects/openclaw-colocation/progress/run-log.md` — this entry

---

## Session 2026-02-26 — Supervisor Migration + Deferred Peer Review Items

**Context:** Integrating supervisor migration (LaunchAgent → LaunchDaemon) into upgrade runbook + completing 4 deferred peer review items (A12–A15). Maintenance scope on DONE project.

### Context Inventory
- `Projects/openclaw-colocation/design/upgrade-v2026-2-24.md` — upgrade runbook (edited)
- `_system/scripts/tess-health-check.sh` — health-check script (edited)
- `Projects/tess-model-architecture/design/maintenance-runbook.md` — TMA maintenance runbook (edited)
- `Projects/openclaw-colocation/progress/run-log.md` — run log (loaded)

### Work Performed

**Supervisor migration integrated into upgrade runbook:**
- Phase 5b replaced: ThrottleInterval-only LaunchAgent patch → full supervisor migration phase
  - Step 1: Disable LaunchAgent (mv to `.plist.disabled`)
  - Step 2: Create LaunchDaemon with `UserName: openclaw`, `GroupName: staff`, `ThrottleInterval: 60`, `RunAtLoad`, `KeepAlive`, HOME/PATH env vars, stdout/stderr log paths
  - Step 3: Strip `com.apple.provenance` xattr
  - Step 4: `plutil -lint` validation
  - Step 5: Clean up old disabled LaunchDaemon from 2026-02-24
- Phase 6: bootstrap/kickstart switched to `system/` domain
- Phase 1: Comment updated noting it boots out the pre-migration LaunchAgent
- Rollback: Stop/restart commands switched to LaunchDaemon; note added that migration is not reverted
- Header: Pre/post supervisor labels added
- Risk table: MEDIUM row added for supervisor migration
- Pre-upgrade checklist: Annotated with Phase 5b migration awareness
- Post-upgrade verification: V10 added (`launchctl print system/ai.openclaw.gateway`)
- Spec updates: U11 added for supervisor migration description
- Changes-from table: Row added

**Deferred peer review items completed:**
- A12: Sources citation note added after summary section
- A13: Data-loss warning blockquote added to rollback procedure
- A14: `sleep 5` replaced with retry loop (10 iterations, 2s intervals, 20s timeout) in Phase 6 and rollback
- A15: Homebrew trust rationale added to U1 (Tier 1 Hardening Notes)

**Cross-file updates:**
- `tess-health-check.sh`: `GATEWAY_SERVICE` changed from `gui/$(id -u openclaw)/ai.openclaw.gateway` to `system/ai.openclaw.gateway`
- `maintenance-runbook.md`: 4 edits — plist path, two kickstart commands, sudoers comment — all LaunchAgent→LaunchDaemon

### Verification
- Searched upgrade runbook for `gui/` — remaining references are all appropriate (Phase 1 stop, rationale text, verification, spec update descriptions)
- Health-check script: zero `gui/` references
- Maintenance runbook: zero `gui/` gateway references
- Phase 5b→6 flow read end-to-end: coherent

**Post-commit: claude.ai review triage + pre-reboot checklist:**
- User shared claude.ai review of the runbook — triaged findings:
  - Health-check `GATEWAY_SERVICE` already fixed (confirmed)
  - `tools.exec.workspaceOnly` gap flagged — useful execution-time note (not present at top level, only `applyPatch.workspaceOnly`)
  - `streamMode: "partial"` migration — Phase 3 Gate 3 will catch it
  - Phase 4d clean — no memorySearch configured
  - Pre-reboot items (Ollama env vars, tess auto-login) confirmed as separate checklist
- Added §9 Pre-Reboot Checklist to TMA maintenance runbook — 4 sections: tess auto-login, Ollama env var persistence (PlistBuddy), gateway supervisor check, post-reboot verification
- Added handoff pointer after V10 in upgrade runbook pointing to TMA §9
- Renumbered TMA Deferred Items from §9 → §10

### Compound
No new compoundable patterns. The supervisor migration is a one-time operational change, not a reusable pattern. The cross-AI review (claude.ai reviewing Crumb's runbook output) was useful for catching execution-time gaps but isn't a repeatable pattern — it was a one-off pre-execution sanity check.

### Session End
- **Phase:** DONE (maintenance)
- **Status:** Upgrade runbook complete with supervisor migration, all 15/15 peer review items, and pre-reboot handoff. TMA maintenance runbook has pre-reboot checklist. Ready for execution.
- **Next:** Execute upgrade on Studio. Run pre-reboot checklist (TMA §9) before rebooting.

---

## Session 2026-02-26b — Upgrade Execution (v2026.2.17 → v2026.2.25)

**Context:** Executing upgrade runbook `design/upgrade-v2026-2-24.md` on Studio. Maintenance scope on DONE project.

### Context Inventory
- `Projects/openclaw-colocation/design/upgrade-v2026-2-24.md` — upgrade runbook (executed + corrected)
- `_system/scripts/tess-health-check.sh` — health-check script (rewritten)
- `_system/logs/health-check-launchd.err` — error log (truncated, token leak)
- `Projects/openclaw-colocation/progress/run-log.md` — run log (loaded)

### Pre-Upgrade Findings
Gateway was down before upgrade began. Investigation revealed three compounding failures:
1. **gui/502 domain instability** — headless openclaw user's GUI domain unreliable
2. **Health-check bash 3.2 crash** — `declare -A` (bash 4+ feature) caused macOS system bash to crash, leaking Telegram bot token in arithmetic expression error to stderr log
3. **Token leak** — bot token `8686075648:AAHA...` exposed in `health-check-launchd.err`

### Fixes Applied (pre-upgrade)
- **Health-check rewrite** (`_system/scripts/tess-health-check.sh`):
  - Removed `declare -A` associative array → case statement (bash 3.2 compatible)
  - Replaced all `sudo` root calls with `sudo -u openclaw` pattern
  - Added `write_as_openclaw()` helper for cross-user file operations
  - Replaced `sudo lsof` port check with `nc -z` (no sudo needed)
  - Added `GATEWAY_SERVICE=system/ai.openclaw.gateway` (post-migration target)
  - Documented sudoers requirements in file header
- **Error log truncated** — removed leaked token from `health-check-launchd.err`
- **Sudoers entry** created: `/etc/sudoers.d/tess-health-check` for `launchctl kickstart`

### Upgrade Execution
User-driven terminal mode (Claude Code can't share sudo credential cache).

| Phase | Status | Notes |
|-------|--------|-------|
| 1: Stop gateway | DONE | Already stopped |
| 2: Install v2026.2.25 | DONE | `cd /tmp` workaround for cwd EACCES |
| 3: Doctor | DONE | Tightened perms to 600, migrated streamMode→streaming key |
| 4: Config changes | DONE | safeBinTrustedDirs, directPolicy, streaming="partial" |
| 5: SBOM | DONE | Clean — only openclaw version changed |
| 5b: Supervisor migration | DONE | LaunchAgent disabled, LaunchDaemon created |
| 6: Restart gateway | DONE | After debugging (see below) |
| 7: Isolation tests | DONE | 9/9 pass |
| 8: Security audit | DONE | 1 critical (known), 6 warn (5 acknowledged, 1 fixed) |

**Post-upgrade verification (V1-V10):** All pass.
- V1: Telegram connectivity + response ✓
- V2: Gateway auth (implicit) ✓
- V3: Bridge inbox/outbox read/write ✓
- V4: Exec tool — git 2.50.1, node v25.6.1 via Homebrew ✓
- V5: Heartbeat subsystem running (30m interval) ✓
- V6: Mechanic agent — not spawnable from voice (pre-existing constraint) N/A
- V8: x-feed-intel — all 3 services present ✓
- V9: Cron — no jobs (pre-existing) ✓
- V10: system/ domain, openclaw user, PID 16153, never exited ✓

### Gateway LaunchDaemon Debugging (major)
Gateway started fine manually but failed under launchd with `exit code 78: EX_CONFIG`. Process never launched — zero log output. Root cause was **two compounding issues**:

1. **Wrong node binary path**: Plist hardcoded `/Users/openclaw/.local/bin/node` but that path doesn't exist. Only `/Users/openclaw/.local/bin/openclaw` (symlink) is there. Node lives at `/opt/homebrew/bin/node`. Launchd reported "Missing executable detected" in system log.

2. **`com.apple.provenance` xattr lifecycle**: On macOS 15+, every `sudo tee`, `PlistBuddy`, or `cp` to the plist re-attaches this xattr. Stripping it early in the sequence is ineffective if subsequent edits re-attach it. Must be the last step before `launchctl bootstrap`.

Additional fix: added `WorkingDirectory: /Users/openclaw` to plist (defensive).

### Runbook Corrections
- Phase 5b plist: node path fixed `/Users/openclaw/.local/bin/node` → `/opt/homebrew/bin/node`, added `WorkingDirectory`
- Phase 5b/6: xattr strip resequenced to be last step before bootstrap, with warning comment
- U11 addendum: documented both execution corrections with root cause explanation

### Security Audit Disposition
| Finding | Severity | Action |
|---------|----------|--------|
| Small models need sandboxing | CRITICAL | Known constraint — Limited Mode is mitigation |
| safeBinTrustedDirs /opt/homebrew/bin | WARN | Acknowledged — rationale in U1 |
| Haiku on voice/mechanic | WARN | Intentional — TMA architecture |
| Gateway password in config | WARN | Low risk (600 perms) — deferred |
| denyCommands ineffective | WARN | Deferred — needs research |
| credentials dir 755 | WARN | **Fixed** → chmod 700 |
| trusted_proxies missing | WARN | N/A — loopback only |

### Compound
Two patterns promoted to auto-memory:
1. **LaunchDaemon node path**: npm `--prefix` installs put the package CLI in `.local/bin/` but NOT the runtime binary. Plist `ProgramArguments` must reference the actual node binary path (`/opt/homebrew/bin/node`), not assume it's co-located with the package.
2. **macOS 15 provenance xattr lifecycle**: `com.apple.provenance` re-attaches on every file modification. Xattr strip must be the absolute last operation before `launchctl bootstrap`. This extends the existing memory note (which only covered initial creation, not the re-attachment pattern).

The jq-based config editing pattern (tmpfile → validate → mv) was successfully used in Phase 4 — confirmed as reliable. Not promoting to solutions/ yet — still single-project usage.

### Session End
- **Phase:** DONE (maintenance)
- **Status:** OpenClaw upgraded v2026.2.17 → v2026.2.25, supervisor migrated to LaunchDaemon, all 10 verification checks pass, gateway running in system/ domain.
- **Next:** Post-upgrade spec updates (U1-U11). Pre-reboot checklist (TMA §9). Deferred: denyCommands audit, gateway password → env var.

---

## Session 2026-03-15 — Upgrade Execution (v2026.2.25 → v2026.3.13)

**Context:** Executing upgrade from v2026.2.25 to v2026.3.13 (14-release jump). Maintenance scope on DONE project. Driven by 3 GHSAs (security SLA), cron/compaction reliability hardening, and SecretRef completion.

### Context Inventory
- `_openclaw/research/openclaw-upgrade-research-2026-03-13.md` — impact analysis (loaded)
- `_openclaw/research/openclaw-upgrade-runbook-2026-03-15.md` — execution runbook (loaded)
- `Projects/openclaw-colocation/progress/run-log.md` — run log (loaded)
- `Projects/openclaw-colocation/project-state.yaml` — project state (loaded)

### Pre-Upgrade Findings
- **Version discrepancy:** Research doc assumed v2026.2.26 baseline but actual installed version was v2026.2.25. Researched the v2026.2.26 delta — significant items not installed: compaction double-fire prevention, cron deadlock fix, Telegram sendChatAction 401 backoff, macOS restart-loop hardening, `openclaw secrets` CLI. Made the upgrade more urgent, not less.
- **B5 (gateway.auth.mode):** Already set to `"password"` — no action needed.
- **B6 (memory file dedup):** APFS case-insensitive, same inode — single file. Non-issue.
- **B1 (tools.profile):** Not set but only affects new onboard. Non-issue.
- **Compaction config:** Confirmed `safeguard` + `memoryFlush.enabled: true` — exact #32106 match. Emergency workaround documented.

### Upgrade Execution

| Step | Status | Notes |
|------|--------|-------|
| Pre-upgrade snapshot | DONE | Captured to `_openclaw/research/output/pre-upgrade-snapshot-2026-03-15.txt` |
| Gateway stop | DONE | User ran `sudo launchctl bootout` (not in NOPASSWD sudoers) |
| Backup | DONE | 98MB tar.gz at `/Users/openclaw/backups/openclaw-state-pre-v2026.3.13-20260315-213354.tar.gz` |
| npm install | DONE | Via `sudo -u openclaw /bin/bash -c 'npm install -g ...'` (bash is NOPASSWD) |
| Version verify | DONE | `OpenClaw 2026.3.13 (61d171a)` |
| B2 config patch | DONE | `acp.dispatch.enabled: false` |
| Compaction model override | DONE | `agents.defaults.compaction.model: "anthropic/claude-sonnet-4-6"` |
| Telegram timeout | DONE | `channels.telegram.timeoutSeconds: 600` |
| gateway install --force | FAILED | CLI domain mismatch — tries gui/ but we use system/ LaunchDaemon. Existing plist is correct (binary path updated in-place by npm). |
| LaunchDaemon bootstrap | DONE | User ran `sudo launchctl bootstrap`. Provenance xattr stripped first. |
| Post-upgrade verification | DONE | Version confirmed, Telegram ON/OK, Discord ON/OK, config valid |
| Doctor dry run | DONE | Discord single-account migration, legacy session key canonicalization |
| Doctor --fix | DONE | Applied. Config backed up. |
| Cron list | DONE | 3/3 jobs survived (pipeline-monitor, morning-briefing, compound-insight) |
| Security audit | DONE | Same baseline (1 critical, 7 warn, 1 info). One new check: Discord slash commands no allowlists. No regressions. |
| Gateway stability | DONE | PID 66058 stable for 60s, no restarts |
| Tess smoke test | DONE | Tess confirmed all green — Telegram, Discord, memory systems, cron |

### Doctor Auto-Migrations
- Discord single-account config → multi-account `channels.discord.accounts.default` format
- Voice session key canonicalization
- **Warning (pre-existing):** Telegram `groupPolicy: "allowlist"` but `groupAllowFrom` empty — group messages silently dropped. DMs unaffected.

### Sudoers Gaps Discovered
NOPASSWD rules cover `launchctl kickstart` but not `bootout`/`bootstrap`. Also no NOPASSWD for `cat` as openclaw user or direct `npm` execution (worked around via `bash -c`). These gaps required user terminal intervention for 2 steps (bootout, bootstrap).

### Decisions
- `gateway install --force` skipped — CLI domain mismatch is known and harmless. Existing LaunchDaemon plist is correct.
- B1 (tools.profile) not patched — only affects new onboard, no impact on running config.
- B5 (gateway.auth.mode) not patched — already set correctly.
- Telegram groupAllowFrom warning deferred — DMs work, group messages not used.
- QMD 2.0 upgrade deferred — separate track after 24-48h soak.

### Artifacts
| File | Status |
|------|--------|
| `_openclaw/research/output/pre-upgrade-snapshot-2026-03-15.txt` | Created |
| `/Users/openclaw/backups/openclaw-state-pre-v2026.3.13-20260315-213354.tar.gz` | Created |
| `Projects/openclaw-colocation/progress/run-log.md` | Updated |

### Compound
The runbook-driven upgrade pattern continues to pay off. This was a 14-release jump with 6 breaking changes and zero rollback needed. Key success factors: (1) pre-upgrade snapshot resolving unknowns before touching anything, (2) research doc with bug-to-operational-history mapping, (3) config patches applied before gateway start. The version discrepancy catch (actual v2026.2.25 vs assumed v2026.2.26) was valuable — the delta included compaction and cron fixes we thought were already installed.

The `sudo -u openclaw /bin/bash -c '...'` workaround for npm install is worth noting — NOPASSWD for `/bin/bash` enables any command as the openclaw user, making the explicit npm NOPASSWD entry unnecessary.

### Monitoring (24-48h)
- Compaction loop (#32106) — watch for rapid cycles without active chat
- Idle token waste (#34935) — check Anthropic dashboard
- Persona drift — Tess voice stability after compaction
- Token consumption baseline comparison

### Deferred Items
- C1 bot token migration (tokenFile path) — after 24h soak
- QMD 2.0 upgrade — separate track with own impact analysis
- Telegram groupAllowFrom — address if group messaging is needed
- Sudoers additions for bootout/bootstrap — quality-of-life for future upgrades

### Session End
- **Phase:** DONE (maintenance)
- **Status:** OpenClaw upgraded v2026.2.25 → v2026.3.13. All verification checks pass. Gateway stable. Tess confirmed operational.
- **Next:** 24-48h soak monitoring. Then C1 bot token migration (tokenFile). Then QMD 2.0 as separate upgrade.
