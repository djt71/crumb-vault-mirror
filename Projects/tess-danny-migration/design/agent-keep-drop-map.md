---
project: tess-danny-migration
domain: software
type: decision
status: active
created: 2026-06-08
updated: 2026-06-08
task: TDM-001
---

# TDM-001 — launchd Agent Keep/Drop Map

**Policy (operator-decided):** Faithful copy of current live state; drop ONLY
verifiably-dead agents. Dual-generation overlaps (legacy + v2) are **both KEPT** —
tess-v2 completes its legacy→v2 cutover later, on danny, as its own project.

**Key correction (2026-06-08):** The macOS-Tahoe CalendarInterval bug was specific
to ~26.3.x and is **resolved on 26.5** (this machine). All four CalendarInterval
agents fire normally (`runs=11, exit 0`). They are therefore NOT dead and are KEPT
as-is — see memory `[[macos-tahoe-calendarinterval-bug]]` (corrected). This also
voids the original TDM-041 "convert all 4 to StartInterval" rationale (see note below).

## Verdicts

### KEEP — 21 functional agents (faithful copy, both generations)

| Agent | Type | Notes |
|---|---|---|
| `ai.hermes.gateway` | KeepAlive | core — Hermes gateway |
| `ai.openclaw.bridge.watcher` | KeepAlive | core — bridge watcher |
| `ai.openclaw.awareness-check` | StartInterval | legacy live |
| `ai.openclaw.daily-attention` | StartInterval | legacy live (mid-migration w/ v2 — TV2-057d) |
| `ai.openclaw.health-ping` | StartInterval | legacy live |
| `ai.openclaw.vault-health` | **CalendarInterval (fires on 26.5)** | **canonical** — writes `vault-health-notes.md`; v2 transfer deferred to TV2-040 |
| `com.crumb.cloudflared` | KeepAlive | core — tunnel (see TDM-002) |
| `com.crumb.qmd-index` | **CalendarInterval (fires on 26.5)** | quartz index |
| `com.crumb.system-stats` | StartInterval | telemetry |
| `com.crumb.telemetry-rollup` | StartInterval | telemetry |
| `com.crumb.vault-gc` | **CalendarInterval (fires on 26.5)** | legacy GC; writes canonical `_system/logs/vault-gc.log`; coexists w/ v2 |
| `com.crumb.vault-rebuild` | StartInterval | quartz rebuild |
| `com.crumb.vault-web` | KeepAlive | core — vault web |
| `com.tess.backup-status` | StartInterval | legacy live |
| `com.tess.llama-server` | KeepAlive | ML — llama server |
| `com.tess.vault-backup` | **CalendarInterval (fires on 26.5)** | vault backup |
| `com.tess.v2.backup-status` | StartInterval | v2 canonical (in tess-v2 `services:`) |
| `com.tess.v2.daily-attention` | StartInterval | v2 live (mid-migration) |
| `com.tess.v2.health-ping` | StartInterval | v2 canonical (in tess-v2 `services:`) |
| `com.tess.v2.vault-gc` | StartInterval | v2 live |
| `com.tess.v2.vault-health` | StartInterval | v2 live (staging output; not yet canonical) |

### KEEP (special handling) — 1

| Agent | Verdict | Notes |
|---|---|---|
| `homebrew.mxcl.ollama` | KEEP via `brew services` | Not a hand-copied plist — migrate per TDM-043 |

### KEEP-FILE / DO-NOT-LOAD — 1 (faithful copy of dormant state)

| Agent | Verdict | Notes |
|---|---|---|
| `com.crumb.dashboard` | carry plist, leave unloaded | Deliberately stopped 2026-06-01 (monitoring-stack teardown, kept for reversibility per mission-control run-log). Not dead — preserve current dormant state on danny. |

### DROP — verifiably dead

| Agent | Evidence | Rationale |
|---|---|---|
| `disabled/ai.openclaw.email-triage` | in `disabled/`, TV2-036 cancelled 2026-04-10 | already disabled stub |
| `disabled/com.tess.v2.email-triage` | in `disabled/`, TV2-036 cancelled 2026-04-10 | already disabled stub |
| `com.tess.nemotron-load` | `runs=1040, last exit 127` (every run) | chronically-failing soak-test loader (`llm-eval/soak/nemotron-load.sh`); teardown-discipline class. **Operator confirm — ML-adjacent.** |

## Skip (not Crumb-owned)
`com.google.GoogleUpdater.wake`, `com.google.keystone.agent`, `com.google.keystone.xpcservice`

## Downstream impacts on tasks.md
- **TDM-041 (convert 4 CalendarInterval → StartInterval): VOID** on 26.5 — the agents
  fire correctly; forced conversion is needless churn and changes timing semantics.
  Recommend dropping TDM-041 unless danny's session exhibits different sleep/wake behavior.
- **TDM-040** staging set = the 21 KEEP + 1 special + 1 keep-file-unloaded; exclude the 3 DROPs.
- Dual-generation KEEPs are intentional — TDM-001 acceptance criterion "no function has
  two KEEPs" is superseded by the faithful-copy policy.

## Open confirm
- `com.tess.nemotron-load`: recommend DROP (1040× failure). Operator may override to
  carry-and-fix if the nemotron soak is still wanted.
