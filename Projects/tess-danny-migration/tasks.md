---
type: tasks
project: tess-danny-migration
domain: software
status: active
created: 2026-06-08
updated: 2026-06-08
---

# Tess → Danny Migration — Atomic Tasks

Decomposed from [[tess-to-danny-migration-runbook]] (the action plan). Phases P0–P7
map to milestones M2–M7 in [[progress-log]]. IDs: `TDM-NNN`.

**Execution discipline:** This is a copy-and-verify migration — no `tess`-side
deletion until M6 gates are green over the soak window. Risk-tiered approval applies
(high-risk tasks: stop and confirm before running). The teardown milestone (M7)
follows [[infrastructure-teardown-discipline]]: trace the consumer graph before
disabling any `tess` producer.

> **Sizing note:** Several tasks are single mechanical operations that touch many
> files (e.g. TDM-022 path rewrite ≈392 files). The ≤5-file rule is a context-budget
> proxy for *code* tasks; for a scripted sweep the logical change is atomic. Footprint
> is flagged where it exceeds the proxy.

## Gating decisions (pre-execution — all resolved 2026-06-08)

| id | description | state | depends_on | risk | domain | acceptance_criteria |
|---|---|---|---|---|---|---|
| TDM-001 | Keep/drop map for launchd agents under faithful-copy policy | **done** | — | med | software | ✅ [[agent-keep-drop-map]] — 21 KEEP + ollama(brew) + dashboard(keep-file/unloaded); DROP 3 (2 disabled email-triage + nemotron-load 1040×fail). Dual-gen KEEPs intentional. **CalendarInterval fires on 26.5 → TDM-041 voided.** |
| TDM-002 | Decide cloudflared tunnel strategy | **done** | — | med | software | ✅ **Reuse UUID `6d7aca42-…`** — copy 3 files (`cert.pem`, `<UUID>.json`, `config.yml`) to danny `.cloudflared`; ingress `mc.crumbos.dev` unchanged, no DNS change. NOTE: tunnel fronts the *stopped* dashboard (dormant monitoring stack — see coupling flag below). |
| TDM-003 | Build secret manifest, consumer-mapped | **done** | — | low | software | ✅ [[secret-manifest]] — Tier A (11 keychain items, manual re-key) / A′ (gh + Claude Code re-auth) / B (file-based, copies with rsync). Shrinks TDM-030 scope. |

## M2 · P0 Freeze & pre-flight

| id | description | state | depends_on | risk | domain | acceptance_criteria |
|---|---|---|---|---|---|---|
| TDM-010 | Commit + push every repo (vault + 7 openclaw repos) to clean working trees | todo | — | med | software | `git status` is clean and `git push` succeeded for vault and each repo with a remote; YES/NO: any uncommitted tracked changes remain? = NO |
| TDM-011 | Snapshot keychain item inventory to `~/migration-keychain-manifest.txt` | todo | TDM-003 | low | software | File exists and contains every secret name from TDM-003 |
| TDM-012 | Capture running-services baseline (`launchctl list` filtered) to `~/migration-services-before.txt` | todo | — | low | software | File lists all currently-loaded Crumb/hermes/openclaw agents with PID/status |
| TDM-013 | Grant `danny` admin (add to admin group) | todo | — | med | software | `groups danny` includes `admin`; danny can run `sudo` |
| TDM-014 | Bootout all `tess` Crumb launchd agents to freeze writers during copy | todo | TDM-012 | med | software | `launchctl list` shows zero Crumb/hermes/openclaw agents loaded under tess; no agent writes to vault/repos after this point |

## M3 · P1 Bulk copy + P2 Path rewrite

| id | description | state | depends_on | risk | domain | acceptance_criteria |
|---|---|---|---|---|---|---|
| TDM-020 | `rsync -aHAX` all data trees tess→`/Users/danny/` excluding `venv/`, `__pycache__/`, `node_modules/` (vault, mirror, quartz, research-library, crumb-apps, openclaw, models, llama.cpp, sd-env, llm-eval, + dotdirs) | todo | TDM-014 | med | software | Every in-scope tree exists under `/Users/danny/`; file counts match source minus excluded dirs; rsync exit 0 |
| TDM-021 | `chown` copied trees to `danny` (`danny:staff`; group `crumbvault` for vault/mirror/research-library/.google_workspace_mcp) | todo | TDM-020 | high | software | No copied file is owned by `tess`; group-owned trees retain group `crumbvault`; danny can read+write all |
| TDM-022 | Path rewrite `/Users/tess`→`/Users/danny` across text files (≈392: 329 vault + 63 repo), excluding `.git/`, `node_modules/`, `venv/` [footprint: many files, one scripted op] | todo | TDM-021 | high | software | `grep -rI --exclude-dir=.git "/Users/tess" /Users/danny/{crumb-vault,openclaw,...}` returns zero matches; no binary/`.git` object modified |
| TDM-023 | Rewrite shell profiles (`.zshrc`, `.zprofile`) and `obsidian.json` to danny paths | todo | TDM-021 | med | software | Profiles source danny paths; `obsidian.json` registers vault at `/Users/danny/crumb-vault`; YES/NO: any `/Users/tess` left in these files? = NO |
| TDM-024 | Rename `.claude` memory dir `-Users-tess-crumb-vault`→`-Users-danny-crumb-vault` and rewrite its path references | todo | TDM-021 | med | software | New dir name exists; memory `*.md` contain no `/Users/tess` or old dir key; MEMORY.md index intact |
| TDM-025 | Verify zero path stragglers outside `.git` across all migrated trees | todo | TDM-022, TDM-023, TDM-024 | low | software | A full `grep -rI --exclude-dir=.git "/Users/tess" /Users/danny` over migrated trees returns zero matches (or only intentional historical-log references, itemized) |

## M4 · P3 Secrets + P4 Runtime rebuild

| id | description | state | depends_on | risk | domain | acceptance_criteria |
|---|---|---|---|---|---|---|
| TDM-030 | Re-add the **15 Tier-A** keychain items ([[secret-manifest]]) to danny's login keychain (Tier B rides the rsync — do not hand-add) | todo | TDM-011, TDM-021 | high | software | All 15 Tier-A names resolve via `security find-generic-password` under danny; YES/NO: any Tier-A item missing? = NO |
| TDM-031 | Re-auth Tier-A′ + tunnel: `gh auth login`, Claude Code sign-in, Google OAuth token refresh (only if `token_cache.json` refresh fails), cloudflared (UUID reuse — copy 3 files per TDM-002) | todo | TDM-021, TDM-002 | med | software | `gh auth status` ok; cloudflared `<UUID>.json`+`cert.pem` present; Claude Code authenticated; MCP google-workspace returns without auth error |
| TDM-032 | Recreate `.hermes/hermes-agent` venv under danny (`python -m venv` + editable install) | todo | TDM-021 | med | software | `venv/bin/python` shebang points to `/Users/danny`; `hermes_cli` imports without error |
| TDM-033 | Recreate openclaw repo venvs + `npm ci` for node services | todo | TDM-021 | med | software | Each repo with `requirements.txt` has a working danny venv; each `package.json` repo has `node_modules`; smoke import/build per repo succeeds |
| TDM-034 | Verify model/ollama paths resolve under danny (`models/`, `.ollama/`, llama.cpp) | todo | TDM-020 | low | software | Ollama lists models; llama-server model path exists under `/Users/danny`; no path points at `/Users/tess` |

## M5 · P5 launchd standup

| id | description | state | depends_on | risk | domain | acceptance_criteria |
|---|---|---|---|---|---|---|
| TDM-040 | Stage rewritten plists, applying the [[agent-keep-drop-map]] (exclude the 3 DROPs; carry `com.crumb.dashboard` unloaded) | todo | TDM-001, TDM-022 | med | software | Staged set = 21 KEEP + dashboard(unloaded); every staged plist references `/Users/danny`; the 3 DROP agents absent |
| TDM-041 | ~~Convert 4 CalendarInterval → StartInterval~~ **VOID** — CalendarInterval fires normally on macOS 26.5 (verified `runs=11, exit 0`); forced conversion is needless churn. Re-open only if danny's session shows different sleep/wake firing behavior. | **void** | TDM-040 | low | software | N/A — superseded by 26.5 live evidence ([[agent-keep-drop-map]]) |
| TDM-042 | Install staged plists to danny `~/Library/LaunchAgents` and `bootstrap` from danny's GUI session | todo | TDM-041, TDM-030, TDM-032, TDM-033 | high | software | All KEEP agents appear in danny's `launchctl list`; none in `idle_error` on first load |
| TDM-043 | Migrate Ollama via `brew services` (not a copied plist) | todo | TDM-034 | med | software | `brew services list` shows ollama running under danny; no hand-copied ollama plist in LaunchAgents |

## M6 · P6 Verification gates (all must pass before M7)

| id | description | state | depends_on | risk | domain | acceptance_criteria |
|---|---|---|---|---|---|---|
| TDM-050 | Service list under danny matches baseline minus pruned dupes | todo | TDM-042, TDM-043 | low | software | Diff of danny `launchctl list` vs TDM-012 baseline accounts for every delta (KEEP present, DROP absent) |
| TDM-051 | Gateway, dashboard, and cloudflared tunnel healthy | todo | TDM-042 | med | software | Gateway log clean start; dashboard reachable; tunnel hostname serves 200 |
| TDM-052 | `vault-check.sh` and `session-startup.sh` pass as danny | todo | TDM-025, TDM-042 | low | software | Both scripts exit 0 with no errors when run in danny's session |
| TDM-053 | A scheduled agent fires on interval; Telegram bots respond | todo | TDM-042, TDM-030 | med | software | At least one scheduled agent logs a successful fire; approval + awareness bots reply to a test message |
| TDM-054 | git push works as danny; feed pipeline e2e; Obsidian opens vault | todo | TDM-030, TDM-031 | med | software | `git push` from vault succeeds as danny; one representative pipeline runs end-to-end; Obsidian opens `/Users/danny/crumb-vault` |

## M7 · P7 Retire tess (post-soak, after M6 green ≥48–72h)

| id | description | state | depends_on | risk | domain | acceptance_criteria |
|---|---|---|---|---|---|---|
| TDM-060 | Consumer-graph trace: confirm nothing under danny depends on a `tess`-side path before disabling tess producers (teardown discipline 2) | todo | TDM-050 | med | software | A trace note confirms zero danny services read `/Users/tess`; YES/NO: any live consumer of a tess path? = NO |
| TDM-061 | Permanently disable tess agents; archive tess plists to `tess-retired/` | todo | TDM-060 | high | software | tess `~/Library/LaunchAgents` Crumb plists moved to archive; `launchctl list` under tess shows none loaded |
| TDM-062 | Reclaim space: archive or remove tess-side data copies | todo | TDM-061 | high | software | tess-side migrated trees removed/archived per operator decision; disk reclaimed; rollback window formally closed |
| TDM-063 | Final docs pass + regenerate `claude-ai-context.md` + commit from danny | todo | TDM-062 | low | software | No doc names tess as operator; `claude-ai-context.md` reflects danny paths; final commit pushed from danny |

## Dependency summary

- **Decisions (TDM-001/002/003) gate execution** — resolve first.
- **M2 → M3 → M4 → M5 → M6 are strictly sequential** (freeze → copy → secrets/runtime → standup → verify).
- **M7 is soak-gated** — do not start until M6 has been green for the agreed window.
- Highest-risk tasks: TDM-021 (chown), TDM-022 (rewrite), TDM-030 (keychain), TDM-042 (bootstrap), TDM-061/062 (irreversible teardown).

## Flags raised during M1 gating (carry into execution)
- **Dormant monitoring stack:** `com.crumb.dashboard` (stopped 2026-06-01) + its
  `com.crumb.cloudflared` tunnel (fronts the stopped dashboard at `mc.crumbos.dev`)
  + telemetry feeders (`system-stats`, `telemetry-rollup`). Faithful-copy default =
  carry forward dormant. **Optional consolidation:** drop the whole stack during the
  move instead of replicating a decommissioned-but-running tunnel. Operator's call —
  not blocking; defaults to carry.
- **`com.tess.nemotron-load`:** recommended DROP (1040× exit 127). ML-adjacent soak
  loader — operator may override to carry-and-fix. Defaults to DROP per keep/drop map.
