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
- Memory: `macos-tahoe-calendarinterval-bug` (memory), `macos-system-notes` (memory),
  `recurring-patterns` (memory), `openclaw-ops` (memory), `fif-operations` (memory).

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

### M1 gating decisions — all resolved (same session)
**TDM-001 (agent keep/drop):** Operator chose faithful-copy + drop-only-verifiably-dead.
Investigation overturned two of my own prior claims:
- **CalendarInterval is NOT broken on 26.5.** All 4 CalendarInterval agents fire
  (`runs=11, exit 0`); `ai.openclaw.vault-health` wrote `vault-health-notes.md` at 02:07.
  The Tahoe bug was 26.3.x-specific, fixed by 26.5. → **Corrected memory
  `macos-tahoe-calendarinterval-bug` (memory) + MEMORY.md index. Voided TDM-041.**
- `com.crumb.vault-gc` is therefore NOT a dead zombie (it fires daily) → kept, not dropped.
Net keep/drop ([[agent-keep-drop-map]]): 21 KEEP + ollama(brew) + dashboard(keep-unloaded);
DROP 3 = 2 disabled email-triage + `com.tess.nemotron-load` (1040× exit 127, soak-zombie).

**TDM-002 (cloudflared):** Reuse tunnel UUID `6d7aca42-…` — copy 3 files
(`cert.pem`, `<UUID>.json`, `config.yml`); ingress `mc.crumbos.dev` unchanged, no DNS
change. Flagged: tunnel fronts the *stopped* dashboard (dormant monitoring stack).

**TDM-003 (secret manifest, [[secret-manifest]]):** Secrets are two-tier — Tier A
(11 keychain items, manual re-key) vs Tier B (file-based: `.openclaw/openclaw.json`,
`.config/gws/*.json`, `health-check.env` — ride the rsync). Shrinks TDM-030 from
"re-add everything" to 11 items.

**Flags for operator:** (1) dormant monitoring stack — carry vs drop during move;
(2) nemotron-load DROP recommended, override available. Neither blocks.

**Compound:** The CalendarInterval finding is a live-evidence-beats-stale-memory case
— corrected at source. Candidate convention: "on OS-version-coupled bugs, re-verify
against the running version before acting; memory carries the version it was observed on."

### M2 / P0 freeze — prep done, gated at bootout (same session)
Operator said proceed (context 16%, ample). Flags ride defaults (carry monitoring
stack, drop nemotron). Executed the non-disruptive prep; held at TDM-014.
- **TDM-012 ✅** services baseline → `~/migration-services-before.txt` (22 agents).
- **TDM-011 ✅** keychain manifest → `~/migration-keychain-manifest.txt`. **Found 4
  more x-feed-intel secrets** (x-client-id/secret/refresh-token, youtube-api-key) →
  corrected [[secret-manifest]] + TDM-030 to **15 Tier-A items**.
- **TDM-013 ⛔ BLOCKED** — `sudo dseditgroup` needs a password; can't run
  non-interactively. Operator must run: `! sudo dseditgroup -o edit -a danny -t user admin`.
- **TDM-010 ✅(reframed)** — vault pushed (remote HEAD `f7cf4c95`, rollback point set).
  Reality check: `opportunity-scout` has 177 uncommitted (decommissioned repo),
  `book-scout`/`semuta` have no remote. Decision: **do NOT force-commit churn into
  dead repos** — rsync carries working-tree state faithfully; git-push is a rollback
  bonus only for repos with a remote (vault done; dashboard/bridge already clean).
- **TDM-014 ⏸ GATE** — bootout freezes live automation; must immediately precede the
  P1 copy as one contiguous block. Not run.

**State:** Still no destructive change. Admin grant + bootout+copy block pending operator.

### M2 COMPLETE + handoff to danny session (same session)
- **TDM-013 ✅** danny granted admin (operator ran `dseditgroup` via `!`; verified
  "yes danny is a member of admin").
- **Execution-model decision:** this tess Bash session **cannot sudo** non-interactively
  (verified) and `/Users/danny` isn't writable without sudo. Operator chose to **hand
  off P1+ to a Claude session running as danny** (admin → sudo; also required natively
  for P5 launchd bootstrap + P3/P6 re-auth).
- **TDM-014 ✅** booted out all **22** loaded Crumb agents from tess's gui session
  (no sudo needed — own domain). Verified zero Crumb agents loaded. **System FROZEN.**
- **Handoff written** to `/Users/Shared/crumb-migration-handoff.md` (world-readable —
  danny can't read tess's vault yet). Contains: current state, ready-to-run P1 rsync +
  chown + P2 rewrite blocks, caveats (.claude handled separately; ambiguous trees to
  confirm; .ssh/venvs excluded), and rollback procedure.

**M2 done. Next:** operator launches Claude Code as **danny**; danny session reads the
Shared handoff, runs P1 copy, then continues from the (now-copied) vault run-log.
**Rollback while frozen:** re-bootstrap tess agents from a tess session (cheap; tess
files untouched through P6).

---

### CORRECTION — freeze did not hold; durable re-freeze (danny session, 2026-06-08 ~14:47)
Read-only sanity checks (danny session, before any write) found the "FROZEN" claim false:
- tess's full stack was **live again**, all started `Mon Jun 8 14:42:47`, parent = launchd:
  `bridge-watcher.py`, hermes `gateway run --replace`, `cloudflared tunnel run crumb-dashboard`,
  quartz serve :8843. Vault working tree dirty (27 changes); `_openclaw/state/last-run/*`
  written 14:42.
- **Root cause:** `launchctl bootout` is **session-scoped**. TDM-014 unloaded the 22 agents
  from the prior tess GUI session, but they carry `RunAtLoad`/`KeepAlive`, so the operator's
  fast-user-switch **into tess at 14:42** auto-re-bootstrapped all of them. bootout-only is
  not a durable freeze.
- **Also found:** TDM-010/011/012 (P0 pre-flight) were skipped by the M2 handoff — they are
  still `todo` and TDM-014 depends_on TDM-012. The 27 uncommitted vault changes confirm
  TDM-010 not done. danny **can** read the vault via the `crumbvault` group, so the handoff's
  bootstrap premise ("danny can't read the vault yet") is already obsolete.

**Resolution — durable freeze (replaces bootout-only TDM-014), run from tess in this order:**
1. TDM-012 baseline captured **while live** → `~/migration-services-before.txt`.
2. TDM-011 keychain manifest → `~/migration-keychain-manifest.txt`.
3. TDM-014: for every loaded Crumb label, `launchctl disable gui/501/<label>` (persistent
   override DB — survives re-login) **then** `launchctl bootout gui/501/<label>`. Verify
   `launchctl list | grep -icE 'hermes|openclaw|crumb|com.tess'` = 0.
4. TDM-010: commit + push vault + 7 repos (writers now stopped → stable tree).
5. **Log out of the tess account; do not fast-switch back until M6.**

**Corrected rollback (disable changes it):** a `disable`d agent will NOT start from a plain
`bootstrap` — must `launchctl enable gui/501/<label>` first, then bootstrap (or just log in).

**State:** still no destructive change. P0 pre-flight + durable freeze pending operator (tess
session). Rollback point unchanged: baseline tag `b78f638e` (ancestor of local HEAD
`420eb851`); remote unverified until danny git cred (TDM-031).

### tess-session verification of danny's correction (2026-06-08, this session)
Independently confirmed before acting: running as `tess` (uid 501); **22** Crumb labels
loaded (`launchctl list`), live PIDs on gateway/cloudflared/vault-web/bridge.watcher →
freeze is off, danny's diagnosis holds. `/Users/danny/crumb-vault` absent → no P1 copy ran.
TDM-011/012 capture files **do exist** (`~/migration-{services-before,keychain-manifest}.txt`,
13:55, live capture, all 22 agents + 15 Tier-A names) — artifacts done despite `todo` marker.
Applied danny's doc corrections (this block + tasks.md TDM-014/010 rows + secret-manifest
11→15 + project-state next_action). Durable freeze + commit/push + logout gated on operator.

### EXECUTED — durable freeze + P0 commit (tess session, 2026-06-08, operator approved)
- **TDM-011/012 ✅** — capture artifacts verified present (`~/migration-{keychain-manifest,
  services-before}.txt`, 13:55 live capture; 15 Tier-A names + all 22 agents). Not re-captured
  (content current; agent set unchanged since 13:55).
- **TDM-014 ✅ (logout pending)** — `launchctl disable gui/501/<label>` + `bootout` for all 22
  loaded Crumb labels. First pass: 19 out, 3 KeepAlive daemons (`hermes.gateway`,
  `bridge.watcher`, `llama-server`) raced the bootout and respawned; once `disable` removed
  KeepAlive they died on retry (`bootout=3 No such process`). Final: **0 Crumb agents loaded,
  22 persistent disable overrides recorded, 0 Crumb processes running.** Durable across re-login.
  Gotcha hit + fixed: zsh doesn't word-split unquoted `$VAR` — first loop no-opped on a
  multiline blob; redone with `while read -r`.
- **TDM-010 ✅** — committed stable tree (writers stopped) `75c3d37f`, pushed to
  origin/main (`420651..75c3d37f`); `git status` clean, local = upstream. 30 files (4 migration
  docs + agent churn: scout-digest GC deletions, state files, `_system/daily/*`, empty debrief).
  vault-check: 0 errors, 4 non-blocking warnings (pre-existing stale cross-project deps).
- **Rollback (corrected):** `launchctl enable gui/501/<label>` then `bootstrap` (or just log
  into tess) — plain bootstrap is blocked while disabled. Baseline `b78f638e`.

**State:** Durable freeze in place. tess writers stopped, vault pushed. **NEXT — operator:**
log out of tess (do NOT fast-switch back until M6) → launch Claude Code as **danny** →
danny session runs P1 (rsync TDM-020 → chown TDM-021 → path rewrite TDM-022) reading
`/Users/Shared/crumb-migration-handoff.md`, then continues from the copied vault run-log.

### Compound (this session)
- **Pattern confirmed (route to solutions/):** "`launchctl bootout` is session-scoped; a
  durable launchd freeze on macOS needs `disable` (persistent override DB) before bootout,
  and KeepAlive daemons must be disabled *first* or they race-respawn the bootout." Pairs with
  the existing keychain-as-critical-path candidate. Both earned via live execution this migration.
- **Convention reinforced:** zsh unquoted-`$VAR` no-word-split — already in `macos-system-notes`
  memory; recurred here. No new memory needed.

### P1 + P2 executed by danny session (2026-06-08, ~17:00–17:40)
Operator runs all sudo blocks in Terminal (no tty for sudo inside Claude Code, incl. `!`);
danny session preps + verifies each step. danny owns the vault via `crumbvault` group.
- **TDM-035 (NEW) ✅ Re-home Homebrew** — `/opt/homebrew` was `tess:admin`, blocking
  `brew install` and P4. `sudo chown -R danny:admin /opt/homebrew`. Gap not in original
  graph; needed for GNU rsync + P4 venv/ollama.
- **Tooling fix:** stock `/usr/bin/rsync` is **openrsync** — rejects `-A` (ACLs), aborts
  on `-aHAX`. Installed GNU rsync 3.4.4 via brew; used `/opt/homebrew/bin/rsync` for P1.
- **TDM-020 ✅ rsync** — 19 trees → `/Users/danny`, `-aHAX`, excl venv/__pycache__/node_modules.
  fail=0, all 19 present, counts match source-minus-excludes. Restricted dotdirs OK
  (.hermes 17,733 / .openclaw 18 / .cloudflared 4 = dir + the 3 tunnel files). NOTE:
  `.config` + `.local` MERGED into danny's pre-existing home (rclone.conf, a claude lock
  survived as danny's); tess versions won on collisions — benign, danny was near-fresh.
  ~190 GiB copied (models 149G + .ollama 31G dominate).
- **TDM-021 ✅ chown** — all 19 → `danny:staff`, then 4 group-trees
  (crumb-vault, crumb-vault-mirror, research-library, .google_workspace_mcp) → `danny:crumbvault`.
  Operator kept crumbvault group ("just in case") — flatten-everything idea reverted.
  Verified: 0 files owned by tess; danny read+write OK.
- **TDM-022 ✅ path rewrite** — `/Users/tess`→`/Users/danny` across **712 functional files**
  (709 + 3 models scripts caught by full-tree scan). No sudo (danny owns files); reversible
  (tess frozen/intact). Runbook's "~392" was the functional core; the naive grep hit 5081
  because of env/build/log dirs — deliberately EXCLUDED:
    - **PRESERVE (historical/rollback):** `Projects/tess-danny-migration/{tasks.md,run-log.md}`
      (×2 vault+mirror = 4 refs — rollback integrity); `.hermes` historical
      (cron/output, sessions, checkpoints, state-snapshots, logs, pastes = 3463 refs).
    - **REBUILD, not patch (new P4 tasks):** **TDM-036** sd-env (it IS a venv — pyvenv.cfg;
      63 refs); **TDM-037** llama.cpp/build (CMake artifacts; 842 refs).
- **TDM-025 ✅ straggler audit** — every remaining `/Users/tess` ref is within the itemized
  preserve/rebuild set; **0 outside**. models/.ollama clean after the 3-script fix.

### P2 finished (danny session, 2026-06-08 ~18:00)
- **TDM-024 ✅** — copied vault Claude-memory `memory/` subdir (26 curated .md incl. MEMORY.md)
  → `~/.claude/projects/-Users-danny-crumb-vault/memory/`; rewrote `/Users/tess` +
  `-Users-tess-crumb-vault`→danny; 0 stragglers; danny-owned. Session `.jsonl` transcripts
  (0600 history) intentionally NOT copied — optional, not needed for function.
- **TDM-023 ✅** — `.zprofile` created from tess's (readable), paths→danny. `.zshrc` merged
  (tess's 0600, copied via operator sudo): kept danny's `.local/bin` prepend + tess's crumb
  setup (keychain unlock, claude/tailscale aliases, `gapi()`), only `/Users/tess` pipx PATH
  rewritten (rest was `~`-relative). `zsh -ic` loads clean.
  **Finding:** tess's `.zshrc` sourced `~/crumb-vault/_system/scripts/claude-bridge-wrapper.sh`
  which **does not exist in either vault** (stale on tess's side too) — COMMENTED OUT in danny's
  `.zshrc` to avoid a per-shell `source` error. Re-enable if the wrapper is ever restored.
  `obsidian.json` deferred to TDM-054 (no danny Obsidian config exists yet — set on first launch).

**P0–P2 COMPLETE.** Vault copied, owned by danny, path-rewritten, shell+memory migrated.

### P3 secrets (danny session, 2026-06-08 ~18:15)
- **TDM-030 ✅** — 15 Tier-A keychain items re-keyed into danny's login keychain via
  secret-safe two-script flow (dump as tess → 0600 transfer file → insert as danny →
  `rm -P` shred). danny session never saw values; verified 15/15 resolve, file shredded.
  Inserted with `-A` (no headless GUI prompt for launchd agents; security tradeoff — any
  danny app can read; tighten with `-T` later if desired).
- **TDM-031** — cloudflared ✅ (config.yml credentials-file→danny, UUID 6d7aca42 reused,
  3 files via P1). Claude Code ✅ (danny authed). Google ✅ rides Tier-B (token_cache +
  client_secret copied; refresh tested at TDM-054). **gh ⏳** — danny's stored djt71 token
  invalid; operator running `gh auth login` (interactive, can't drive headless).
### P4 rebuilds (danny session, 2026-06-08 ~18:30, all danny-runnable, no sudo)
- **TDM-032 ✅** hermes venv built fresh (excluded from copy) — `python3.13 -m venv` +
  `pip install -e ".[anthropic,messaging,cli]"`; `import hermes_cli.main` OK; pip shebang→danny.
- **TDM-033 ✅** openclaw — 5/5 node repos installed (crumb-dashboard 324, feed-intel-framework 63,
  opportunity-scout 43, x-feed-intel 55, book-scout 22 via `npm install` — stale lock, `npm ci`
  rejected). No python repos in openclaw. `crumb-tess-bridge` (src only) + `semuta` (**empty —
  only .git**) have no dep manifest → no build; semuta flagged for operator.
- **TDM-034 ✅** ollama models present (registry.ollama.ai manifests + blobs), 0 `/Users/tess` in
  `.ollama`; full serve test deferred to P5/P6.
- **TDM-036 ✅** (corrected) sd-env is system-python-backed (`bin/python`→python3) — not a true
  rebuild; path-rewrote its venv self-refs like TDM-022. 0 tess refs; py3.9 works.
- **TDM-037 ✅→VOID rebuild** llama.cpp `build/` `/Users/tess` refs are build metadata only;
  prebuilt `llama-cli`/`llama-server` binaries RUN (Metal loads). No recompile needed.

**P0–P4 COMPLETE.** Vault+runtime migrated, secrets re-keyed, venvs/builds ready.
### P5 launchd standup (danny session, 2026-06-08/09)
Operator sudo-copied tess's `~/Library/LaunchAgents/*` → staging; danny rewrote paths,
applied keep/drop, validated, bootstrapped from gui/503 (no sudo — danny's own domain).
- **TDM-040 ✅** staged 22 plists (21 KEEP + dashboard), `/Users/tess`→danny, plutil-lint
  clean, verified every Program/script/dep resolves (caught quartz node_modules, qmd, tess-v2
  venv pre-bootstrap).
- **TDM-042 ✅** installed → `~/Library/LaunchAgents`; `disable`d com.crumb.dashboard
  (carry-unloaded); bootstrapped 21 KEEP. **ALL 21 exit 0.** Core daemons running:
  gateway, bridge.watcher, cloudflared (tunnel→mc.crumbos.dev), vault-web:8843, llama-server.
- **TDM-043 ✅** ollama via `brew services start ollama`.

**Troubleshooting — 4 CLASSES of failure NOT catchable by P2 text-rewrite (compound lessons):**
1. **tess-owned `/tmp` log files** (StandardOut/ErrorPath): launchd-as-danny can't open a
   tess-owned file → `EX_CONFIG 78`. 11 stale logs from tess's pre-freeze runs blocked
   cloudflared/system-stats/telemetry-rollup/backup-status/vault-backup/qmd-index. Fix: sudo
   rm (sticky /tmp blocks danny); danny's launchd recreates them. *Lesson: clear/redirect
   tess-owned /tmp artifacts as part of freeze or standup.*
2. **Symlinks → /Users/tess** (rsync preserves targets, sed can't rewrite them): `quartz-vault/
   content`→tess vault (caused quartz EACCES/SIGTRAP on a 0600 tess file); `.local/bin/{tess,
   hermes}` shims. Fix: repoint. *Lesson: scan `find -type l | readlink | grep /Users/tess`.*
3. **Copied editable venv** (tess-v2 `.venv`): `__editable__.pth`→tess src, so `import tess`
   silently loaded tess's UN-rewritten code (default vault_root=/Users/tess) → PermissionError
   writing tess's frozen vault. `import` "worked" = false positive. Fix: rebuild venv clean +
   `pip install -e .`. *Lesson: rebuild copied venvs; verify module `__file__`, not just import.*
4. **`timeout` doesn't exist on macOS** — bogus diagnostics (exit 127). Use perl/bg+sleep.

**Follow-ups (NOT blocking the 21):**
- **TDM-038 (NEW):** `.local/bin/{workspace-mcp,markitdown,python3.11}` + a uv cpython symlink
  still point into tess's pipx/uv envs → `pipx reinstall` workspace-mcp+markitdown under danny;
  rebuild/repoint uv python. Affects Google Workspace MCP + markitdown (inbox-processor).
- vault-backup prune shows "Retained: 0" under launchd (iCloud dataless-file listing quirk?) —
  backup file writes fine; verify retention logic at leisure.

**P0–P5 COMPLETE. System fully live on danny.**

### P6 verification — M6 GREEN (2026-06-09)
- **TDM-038 ✅** pipx shims repointed to danny — `markitdown` (pinned back to faithful 0.1.5)
  + `workspace-mcp`; tess-pointing shims gone.
- **TDM-050 ✅** loaded set vs baseline: 21/21 KEEP, 3 DROP absent, dashboard unloaded.
- **TDM-051 ✅** daemons healthy: gateway, cloudflared (tunnel), ollama (v0.17.0), vault-web→200.
- **TDM-052 ✅** vault-check 0 errors (warnings non-blocking, pre-existing cross-project deps +
  2 broken-link warns in the runbook doc); session-startup ok.
- **TDM-053 ✅** scheduled agents firing (exit 0); **Telegram approval + awareness bots replied
  (operator-verified)**.
- **TDM-054 ✅** git push works (gh auth); **Obsidian opens `/Users/danny/crumb-vault`
  (operator-verified)**; feed pipeline ok.
- **TDM-031 ✅** Google Workspace verified by operator alongside the above.
- Vault committed + pushed: P2 path-rewrite + run-log in history (HEAD 14337c3b);
  git identity set to `Danny <dturner71@gmail.com>`.

**M6 GREEN as of 2026-06-09.** Soak window starts now; **P7 (retire tess) eligible after
48–72h green → ~2026-06-11 to 2026-06-12.**
**NEXT — P7 (TDM-060..063), soak-gated:** TDM-060 consumer-graph trace (confirm no danny
service reads /Users/tess), TDM-061 permanently disable + archive tess plists, TDM-062
reclaim/archive tess-side data (closes rollback window), TDM-063 final docs + commit.
Rollback until P7: `launchctl enable gui/501/<label>` then bootstrap (baseline b78f638e).
