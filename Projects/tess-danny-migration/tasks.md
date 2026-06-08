---
type: tasks
project: tess-danny-migration
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

## Gating decisions (resolve before any execution — M1)

| id | description | state | depends_on | risk | domain | acceptance_criteria |
|---|---|---|---|---|---|---|
| TDM-001 | Decide canonical launchd generation per function; produce keep/drop map for the `ai.openclaw.*` / `com.tess.*` / `com.tess.v2.*` overlap (backup-status, daily-attention, health-ping, vault-health, vault-gc) | todo | — | med | software | A keep/drop table exists listing every Crumb plist with a KEEP or DROP verdict and one-line rationale; no function has two KEEPs |
| TDM-002 | Decide cloudflared tunnel strategy: reuse existing tunnel UUID (copy `cert.pem`/credentials) vs. provision fresh tunnel (new DNS/ingress) | todo | — | med | software | Decision recorded with the chosen UUID-handling steps and any DNS records that must change; YES/NO: does ingress hostname stay the same? |
| TDM-003 | Build keychain secret manifest: each item name → source (keychain vs `openclaw.json`) → which agent/service consumes it | todo | — | low | software | Manifest file lists all 14+ secret names with consumer mapping; every plist/service that reads a secret is traced to a manifest row |

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
| TDM-030 | Re-add every keychain item from the manifest to danny's login keychain | todo | TDM-011, TDM-021 | high | software | Every name in TDM-011 manifest resolves via `security find-generic-password` under danny; YES/NO: any manifest item missing? = NO |
| TDM-031 | Re-auth interactive credentials as danny: `gh auth login`, `cloudflared` (per TDM-002), Claude Code sign-in, MCP google-workspace/Gmail OAuth | todo | TDM-021, TDM-002 | med | software | `gh auth status` ok; cloudflared cert present; Claude Code authenticated; MCP tools return without auth error |
| TDM-032 | Recreate `.hermes/hermes-agent` venv under danny (`python -m venv` + editable install) | todo | TDM-021 | med | software | `venv/bin/python` shebang points to `/Users/danny`; `hermes_cli` imports without error |
| TDM-033 | Recreate openclaw repo venvs + `npm ci` for node services | todo | TDM-021 | med | software | Each repo with `requirements.txt` has a working danny venv; each `package.json` repo has `node_modules`; smoke import/build per repo succeeds |
| TDM-034 | Verify model/ollama paths resolve under danny (`models/`, `.ollama/`, llama.cpp) | todo | TDM-020 | low | software | Ollama lists models; llama-server model path exists under `/Users/danny`; no path points at `/Users/tess` |

## M5 · P5 launchd standup

| id | description | state | depends_on | risk | domain | acceptance_criteria |
|---|---|---|---|---|---|---|
| TDM-040 | Stage rewritten plists, applying the TDM-001 keep/drop map (drop pruned generations) | todo | TDM-001, TDM-022 | med | software | Staged plist set contains exactly the KEEP agents; every staged plist references `/Users/danny`; dropped agents absent |
| TDM-041 | Convert the 4 `StartCalendarInterval` plists to `StartInterval` (vault-health, qmd-index, vault-gc, vault-backup) | todo | TDM-040 | low | software | Zero staged plists contain `StartCalendarInterval`; each converted agent has an equivalent `StartInterval` |
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
