---
type: run-log
project: tess-danny-migration
status: active
created: 2026-06-08
updated: 2026-06-08
last_committed: null
---

# Tess → Danny Account Migration — Run Log

> Relocate the full Crumb operation from macOS user `tess` to `danny`, run as `danny`,
> retire `tess`. Copy-and-verify strategy. Plan: [[tess-to-danny-migration-runbook]].

---

## 2026-06-08 (session 1) — Project creation, SPECIFY + PLAN

**Phase:** PLAN
**Operator:** Danny

### Context
Operator requested relocating `/crumb-vault` to user `danny`, with a deliberate
"make a plan so we don't break a bunch of stuff" framing. Initial reconnaissance
showed the request is materially larger than a folder move — the vault is coupled
to sibling data dirs, 7 external repos, agent runtime, 26 launchd agents, and a
path-keyed `.claude` memory dir.

### Decisions captured (operator-confirmed via scoping questions)
- **Scope:** full stack — vault + research-library + crumb-apps + openclaw repos
  + .hermes + .config/tess + .local + .claude + hidden state dirs + ML/model infra.
- **Run-as:** `danny` (launchd bootstrapped in danny's session).
- **Old account:** retire `tess` (clean cutover; originals retained until verified).
- **ML infra:** migrate (`models/`, `llama.cpp/`, `.ollama/`, `sd-env/`, `llm-eval/`).
- **danny admin:** grant (added to admin group before P1).

### Context inventory (loaded this session)
- Live recon: `/Users/tess` top-level dirs + sizes, 24→26 launchd plists +
  scheduling, git remotes (vault + 7 repos), keychain item names, group
  membership (`crumbvault`: openclaw/tess/danny), shell profiles, danny home state.
- Memory: [[macos-tahoe-calendarinterval-bug]], [[macos-system-notes]],
  [[recurring-patterns]], [[openclaw-ops]], [[fif-operations]].

### Work done
- Full blast-radius recon (read-only).
- Wrote execution-ready runbook: `_system/docs/operator/how-to/tess-to-danny-migration-runbook.md`
  (8 phases P0–P7, critical-risk callouts, inventory tables, verification gates, rollback).
- Created project scaffold (this run-log, project-state, progress-log, design/).

### Critical risks surfaced
1. Keychain secrets do not migrate (14 named items → manual re-key in P3). Highest risk.
2. Python venvs hardcode `/Users/tess` → recreate, don't copy.
3. launchd session-bound → bootstrap from danny's GUI login.
4. 4 plists use `StartCalendarInterval` (broken on Tahoe) → fix to `StartInterval`.
5. Re-auth: cloudflared, MCP OAuth, `gh`, Claude Code.
6. Triple agent-generation duplication (`com.tess.*` / `com.tess.v2.*` / `ai.openclaw.*`) — prune.

### State
No execution. Nothing on the system was modified beyond creating the runbook +
project scaffold (vault docs only).

### Next action
TASK phase: decompose P0–P7 into atomic tasks with acceptance criteria; resolve
open items (duplicate-agent pruning decision, cloudflared tunnel UUID strategy)
before any execution.

### Compound evaluation
- **Convention:** Account-migration runbooks belong in `_system/docs/operator/how-to/`
  alongside deployment/rotate-credentials runbooks. No new primitive needed.
- **Pattern (candidate):** "Per-user keychain secrets are the real critical path in
  macOS account migrations, not file volume" — generalizes beyond this project.
  Hold for confirmation until P3 executes successfully, then route to solutions/.

---

### Phase Transition: PLAN → TASK
- Date: 2026-06-08 13:30
- PLAN phase outputs: `tess-to-danny-migration-runbook.md` (8-phase plan, risks,
  inventory, verification gates, rollback); project scaffold (state, run-log, progress-log).
- Goal progress: PLAN acceptance criteria — **all met.** Plan captured ✅, scope
  confirmed ✅, decisions locked ✅ (full-stack incl. ML, run-as danny, retire tess,
  grant admin), critical risks enumerated ✅. No unmet blockers carried forward;
  two open items (dup-agent pruning, cloudflared UUID) deferred to TASK by design.
- Compound: Candidate pattern logged (keychain-as-critical-path); held for P3
  confirmation. No new primitive. Convention confirmed (runbook location).
- Context usage before checkpoint: <50% (estimated — light session, no compaction needed)
- Action taken: none (capacity ample)
- Key artifacts for TASK phase: `tess-to-danny-migration-runbook.md` (serves as the
  design+plan source; no separate frontend/backend design — operational project)

### TASK decomposition (same session)
- Invoked action-architect. No overlay fired (Network Skills excludes Crumb infra).
  Loaded [[infrastructure-teardown-discipline]] — directly relevant: it documents
  this exact `ai.openclaw.*`/`com.tess.*`/`com.tess.v2.*` dual-generation cruft and
  mandates a consumer-graph trace before disabling any producer. Folded both in.
- Produced `tasks.md`: 22 atomic tasks (TDM-001..063), 3 gating decisions (M1) +
  M2–M7, each with binary acceptance criteria, dependency chain, risk tiers.
- Ceremony-budget call: did NOT create a duplicate `action-plan.md` — the runbook's
  8 phases + verification gates already serve as the action plan; milestones live in
  progress-log. Decomposition's value is the atomic task table.
- Estimation calibration: 22 tasks planned; record planned-vs-actual at completion
  (not yet written to estimation-calibration.md — no actuals).
- Highest-risk tasks flagged: TDM-021 (chown), TDM-022 (path rewrite), TDM-030
  (keychain re-key), TDM-042 (launchd bootstrap), TDM-061/062 (irreversible teardown).
