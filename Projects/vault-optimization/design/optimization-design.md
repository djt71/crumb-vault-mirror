---
type: design
project: vault-optimization
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: ../specification.md
source_updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - design
---

# vault-optimization — Optimization Design

Technical design for executing VO-001–009. The spec defines *what* and the
acceptance criteria; this doc defines *how*: schemas, search protocols, batch
mechanics, and sequencing. Soak/ceremony success metrics are deliberately
deferred to TASK per review item A10.

## Design Principles

1. **Mechanical over recalled** — every disposition and consumer list comes from
   recorded commands, reproducible from the run-log.
2. **Analysis is cheap, deletion is gated** — VO-001–004 produce only documents;
   nothing irreversible happens before the VO-008 backup gate.
3. **One manifest, one truth** — all dispositions live in a single artifact
   (`keep-set-manifest.md`); no side lists.
4. **Batches are sessions** — a batch must be remediated, deleted, verified, and
   committed within one session (partial-pass rule from the spec).

## D1 — Evidence & Manifest Design (VO-002)

### Baseline regeneration (run at TASK start, snapshot into manifest header)

```
find . -name "*.md" -not -path "./.git/*" | wc -l
ls .claude/skills .claude/agents
grep -c '^|' _system/docs/overlays/overlay-index.md        # overlay rows
ls _system/scripts/ _system/docs/protocols/ _system/docs/solutions/
du -sh Archived Projects Sources _system _attachments Domains
ls ~/Library/LaunchAgents/                                  # live service surface
```

### Evidence sources (per type, from spec methodology)

| Type | Primary evidence | Commands |
|---|---|---|
| Skills (20) | invocation traces | `grep -l "skill-name"` over `_system/logs/session-log*.md`, `Projects/*/progress/run-log*.md`; `git log --oneline --grep="skill-name"` |
| Agents (4) | spawn traces | same log grep; agents are dispatch arms of their parent skills — disposition follows the parent skill |
| Scripts (20) | structural reference OR execution | grep over `~/Library/LaunchAgents/*.plist`, `.claude/settings*.json` (hooks), other scripts; execution traces in `_system/logs/*.log` |
| Overlays (8) | activation traces | log grep for overlay name; overlay-index presence alone is *not* evidence of use |
| Protocols (6) | constitutional reference | grep CLAUDE.md, skills, hooks; a protocol referenced only by decommissioned surfaces is superseded |
| Docs/solutions | backlinks, MOC presence, canonical status | `obsidian backlinks`, grep for wikilinks, `git log -1 --format=%ci -- <path>` |
| Project records | open dependency or active reference | `_system/docs/cross-project-deps.md`, project-state phase, run-log recency |

Timebox: ~10 min per item, bounds search effort only — a timeout never
auto-converts to delete (spec rule). Session-log archives and git history are
the long-tail evidence base; the orphaned `~/.tess/state/session_reports.db`
may be *read* as supplementary skill-usage evidence (it is not being kept alive
for this purpose).

### Manifest schema (`Projects/vault-optimization/keep-set-manifest.md`)

One section per type; one row per item:

| Column | Values |
|---|---|
| item | name/path |
| rubric | proven-active · structural-necessity · contingency-keep · superseded · no-evidence |
| evidence | citation (log line, plist name, backlink count, commit) — never blank |
| disposition | keep · keep-dormant · merge-into:X · delete |
| owner | VO / AS / joint / blocked-until-AS-M6 (from Appendix A) |
| operator-review | required+signed for every no-evidence delete; `—` otherwise |

Scope boundary: the manifest covers **primitive surface + `_system/` docs +
project records**. KB content (`Sources/`, `Domains/`, knowledge notes) is
Tier-1 *data*, not surface — out of manifest scope; only its weight is touched,
via the VO-004 storage policy. *(Operator confirmed at PLAN gate, 2026-06-10.)*

### Appendix A — joint-surface ownership matrix (schema)

Frozen before VO-005/007 entry; AS concurrence noted in both run-logs.

| Surface | Proposed owner | Gate |
|---|---|---|
| CLAUDE.md | AS (AS-025 first), VO-007 second pass | AS-025 complete |
| `.claude/skills`, `.claude/agents` | joint — AS-028 removes sunset-tied, VO-005 optimizes remainder | AS M6 sign-off |
| Harness memory (`~/.claude/.../memory/`) | AS (AS-029) | analysis-only for VO |
| `_openclaw/`, `_tess/`, `_staging/` | AS (AS-026/027) | VO never touches |
| `_system/scripts/`, protocols, overlays | VO | Appendix A frozen |
| `_system/docs/` + solutions | VO (VO-006) | — |
| `Archived/`, `_attachments/` | VO (VO-004/008) | backup gate |
| Live plists (10 incl. dashboard stack) | dashboard stack: operator-kept (assumption A3); rest: per manifest | new decision required to touch dashboard stack |

## D2 — Consumer-Graph Survey Protocol (VO-003)

For every `delete` row, run all of (record commands + hits in survey doc
`design/consumer-graph-survey.md`):

1. **Wikilinks:** `obsidian backlinks path=<item>` + `grep -rn "\[\[<basename>" --include="*.md" .`
2. **Plain-text paths:** `grep -rn "<path-or-name>" --include="*.md" .` and over `.claude/`, `_system/scripts/`
3. **Hooks/settings:** `.claude/settings.json`, `.claude/settings.local.json`
4. **Plists:** `grep -l "<name>" ~/Library/LaunchAgents/*.plist`
5. **Backup/sync filters:** `drive-sync-computer-filter.txt`, exclusion lists in `vault-backup.sh`, `mirror-sync.sh`, `vault-gc.sh`
6. **Obsidian config:** `.obsidian/` (workspace pins, plugin settings)
7. **Dashboard/web:** dashboard + vault-web config (read-only check — stack is operator-kept)
8. **Memory files:** grep `~/.claude/projects/-Users-danny-crumb-vault/memory/` (remediation is AS-029's surface; VO records and hands off)
9. **Naming conventions:** scripts that glob (e.g., `session-log-*.md`, `run-log*.md` rotation patterns)

Output per item: consumer list (possibly empty) + remediation action per
consumer, batched with the deletion (D4).

## D3 — Storage Policy Design (VO-004)

Policy doc structure (`design/storage-policy.md`), with the spec's three-outcome
distinction stated up front:

- **(a) Working tree:** `Archived/` deletion scope (147 MB, ~70%) — enumerate
  contents first; anything matching VO-006's canonical-reference/compound-provenance
  exception is *moved out* before the directory is deleted. `_attachments/`
  orphan sweep reuses inbox-processor's orphan detection. Non-md top-N:
  `find . -not -path "./.git/*" -type f -size +1M -exec du -h {} + | sort -rh | head -20`.
- **(b) Navigation surface:** dead MOC sections, Archived/-as-category taxonomy
  references (A11) — counted, then removed in VO-006.
- **(c) Repo/clone size:** does **not** improve without history rewrite. Default:
  out of scope; the policy records the explicit operator decision either way (U4).
- **Log rotation:** `_system/logs/` non-md artifacts (JSON status files, launchd
  logs) get a producer-alive check — files written by decommissioned producers
  are deletion candidates with their producers.

## D4 — Execution Batch Design (VO-008)

### Batch 0 — backup verification (gate; no deletions before it passes)

Backup chain to verify: `vault-backup.sh` (com.tess.vault-backup),
`drive-sync.sh` (com.crumb.drive-sync), `mirror-sync.sh`, plus git remote.
Procedure: confirm last-run freshness (`backup-status.json`, log tails) →
restore-drill a sample set (≥1 file per top-level dir incl. one ignored-path
check) onto a throwaway clone → record procedure + results in run-log.
**Authoritative restore source: git remote** (operator decision at PLAN gate,
2026-06-10 — matches the "git history is the archive" premise). Drive/mirror
verified as secondary freshness checks only.

### Batch order (lowest consumer-risk first, weight-greedy)

| # | Batch | Source | Precondition |
|---|---|---|---|
| B1 | `Archived/` deletion + exception extraction | VO-004 | B0 green, survey done |
| B2 | `_attachments/` orphans + non-md heavyweights + dead logs | VO-004 | B0 |
| B3 | `_system/docs/` + solutions consolidation | VO-006 | survey done |
| B4 | Scripts / protocols / overlays pruning | VO-005 | Appendix A frozen + AS M6 |
| B5 | Skills / agents pruning + description rewrite | VO-005 | AS M6 + AS-028 concurrence |
| B6 | Ceremony reduction edits (protocol rewrites; CLAUDE.md second pass) | VO-007 | AS-025 complete; stop-and-ask per edit |

Each batch: remediate consumers → delete → `vault-check.sh` green → atomic
commit (`vault-optimization: VO-008 B<n> — <summary>`). Abort = revert batch,
re-survey (spec rule). B4/B5 deliberately last: they change skill-routing
behavior, and description re-tests (VO-009) should run against the final surface.

## D5 — Per-Axis Approach Notes (VO-005/006/007)

- **VO-005 primitives:** disposition from manifest; for every *kept* skill,
  rewrite `description` as trigger conditions (Anthropic guidance; SkillsBench
  argues for a focused set, so merges beat borderline keeps). Add gotchas
  sections only where a real failure is on record (failure-log, run-logs).
- **VO-006 docs:** delete-unless-canonical rule from spec; cluster `_system/docs/`
  by consumer (constitutional / skill-referenced / solutions / orphan) before
  judging; A11 taxonomy cleanup executes here.
- **VO-007 ceremony:** for each kept workflow ceremony (phase gates,
  context-checkpoint, session-end, intake), classify every step:
  **load-bearing** (enforced by hook/vault-check or consumed downstream) ·
  **zombie** (producer without live consumer — e.g., the flagged
  `session_reports.db` write) · **mergeable**. Zombies are cut, mergeables
  merged, load-bearing kept — "optimize, don't just shrink." Metrics at TASK (A10).

## D6 — Validation & Soak Design (VO-009)

Representative Tier-1 workflows (from accepted ADR) to execute against the
pruned vault: (1) a full phase transition with checkpoint protocol, (2)
inbox-processor run, (3) peer-review or deliberation dispatch, (4) KB query +
signal scan, (5) session-end sequence, (6) skill-routing spot-checks on
rewritten descriptions. Soak window length + end-condition metrics defined at
TASK (A10); design constraint: explicit end-condition per teardown-discipline #1,
pass = zero urgent git restores, no repeated workarounds.

**Deliverable gap to fix at TASK:** the spec's end-state deliverable #2
(core-functionality operating note + future-addition rubric) has no producing
task. Proposed: draft it in VO-002 (identity + keep-set known), finalize in
VO-009 (validated against soak reality).

## Sequencing vs agentic-sunset

```
now ──► VO-001 (ADR acceptance, operator session)
     ─► VO-002/003/004 analysis docs        [parallel with AS M3–M5]
     ─► Appendix A frozen + AS M6 sign-off  [XD-027 gate]
     ─► VO-005/006/007 design-complete edits
     ─► VO-008 B0→B6                        [B6 also gated on AS-025]
     ─► VO-009 soak ─► close
```

## PLAN Gate Decisions (operator, 2026-06-10 — all resolved)

1. Manifest scope excludes KB content (`Sources/`, `Domains/`) — **confirmed**.
2. Authoritative restore source for the B0 drill — **git remote**; Drive/mirror secondary.
3. Batch order — **as designed** (B1 `Archived/` first, primitives B4/B5, ceremony B6).
4. Operating-note production — **split confirmed**: VO-002 draft, VO-009 finalize; action-architect encodes at TASK.
