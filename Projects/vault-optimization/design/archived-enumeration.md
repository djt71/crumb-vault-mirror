---
type: design
project: vault-optimization
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: design/optimization-design.md
tags:
  - design
  - enumeration
topics:
  - moc-crumb-operations
---

# VO-021 — Archived/ Enumeration + Canonical-Exception Extraction List

Input to B1 (VO-028). Rule: **delete-unless-canonical** — everything in
`Archived/` is deleted with the directory; items on the exception list below
are *moved out first*. Spec retention rule: an exception must justify as
**canonical-reference** or **compound-provenance**.

## Enumeration commands (recorded verbatim, run 2026-06-10)

```
du -sh Archived/
find Archived -type d -maxdepth 3 | sort
find Archived -type f | wc -l                       # 6,730
find Archived -type f -name "*.md" | wc -l           # 470
git ls-files Archived | wc -l                        # 880 tracked
git ls-files -z Archived | xargs -0 du -ch | tail -1 # 14M tracked
find Archived -type f -not -name "*.md" | sed 's/.*\.//' | sort | uniq -c | sort -rn
find Archived -type f -size +1M -exec du -h {} + | sort -rh
for d in Archived/Projects/*/; do ... find "$d" -name "*.md" | wc -l ... done
grep -rn "\[\[Archived/" --include="*.md" .          # wikilink consumers
grep -rn "Archived/" --include="*.md" -l .           # path-mention consumers
git check-ignore -v Archived/Projects/batch-book-pipeline/scripts/.venv/pyvenv.cfg
```

## Weight analysis — the headline

`Archived/` = **147 MB on disk, but only 14 MB / 880 files are git-tracked.**
~133 MB is two **untracked** Python `.venv` trees (each self-ignored via the
venv tooling's own `.gitignore`):

| Tree | Size | Note |
|---|---|---|
| `batch-book-pipeline/scripts/.venv/` | 48 MB | untracked |
| `batch-book-pipeline/scripts/_system/` | 48 MB | **accidental recursive copy** of `_system/scripts/batch-book-pipeline/` incl. a second nested `.venv` |
| `pydantic-ai-adoption/evals/.venv/` | 36 MB | untracked |

Consequences for the storage policy (VO-022): deleting `Archived/` recovers
147 MB of *disk*, but the git working-tree delta is only ~14 MB / 880 files;
repo history impact of having ever tracked Archived is already modest (.git =
47 MB total) — further weakening any case for history rewrite.

Non-md inventory (6,260 files): 4,717 `.py` + `.so`/`.dist-info`/`.typed`
etc. — virtually all of it the venv trees. Remainder: 341 `.json` (mostly
multi-agent-deliberation raw responses + pydantic evals), 130 `.txt`, 57
`.yaml`, 20 `.DS_Store`, misc fixtures.

## Directory inventory (24 projects + KB)

| Project | md | total files | Note |
|---|---|---|---|
| active-knowledge-memory | 19 | 28 | |
| agent-to-agent-communication | 34 | 42 | |
| attention-manager | 8 | 14 | |
| autonomous-operations | 11 | 13 | |
| batch-book-pipeline | 33 | 3,786 | 97 MB — venv + recursive copy (above) |
| book-scout | 13 | 28 | |
| crumb-tess-bridge | 33 | 83 | capture-tiers.md:56 cites its run-log (remediate, see below) |
| deck-intel | 19 | 40 | |
| documentation-overhaul | 9 | 19 | |
| documentation-refresh-2026-04 | 8 | 9 | |
| inbox-processor | 5 | 6 | |
| knowledge-navigation | 4 | 10 | |
| mcp-workspace-integration | 7 | 8 | |
| multi-agent-deliberation | 54 | 219 | **data/ = live record store — exception E3** |
| notebooklm-pipeline | 30 | 33 | **workflow-guide = exception E1** |
| openclaw-colocation | 19 | 38 | sunset-tied (AS concurrence noted) |
| pydantic-ai-adoption | 20 | 2,123 | 36 MB venv |
| researcher-skill | 44 | 72 | |
| tess-model-architecture | 31 | 55 | sunset-tied |
| tess-operations | 31 | 33 | sunset-tied |
| vault-mirror | 3 | 4 | **design/specification = exception E2** |
| vault-mobile-access | 8 | 13 | |
| vault-restructure | 7 | 9 | |
| x-feed-intel | 21 | 41 | sunset-tied |
| KB/ | 1 | 1 | solutions-linkage-proposal — decision D1 below |
| (root) | — | 1 | stray `.DS_Store` |

Full tracked-file listing reproducible at B1-open via `git ls-files Archived`
(880 paths; count re-verified at batch open per the drift-diff rule). The
470-md listing was generated and reviewed this session; per design principle
#3 the manifest/this doc carry dispositions, not bulk listings.

## Canonical-exception extraction list

| # | Item | Justification | Live consumers (evidence) | Action before B1 delete |
|---|---|---|---|---|
| E1 | `notebooklm-pipeline/workflow-guide.md` | canonical-reference — operating guide for the **kept** NotebookLM intake path (inbox-processor NLM detection) | `Domains/Learning/learning-overview.md:31` (wikilink), `_system/docs/templates/notebooklm/README.md:39` (wikilink) | extract → `_system/docs/notebooklm-workflow-guide.md`; update both wikilinks |
| E2 | `vault-mirror/design/specification.md` | canonical-reference — documents the **live** mirror-sync mechanism (kept backup chain) | `Domains/Learning/moc-crumb-architecture.md:37` (wikilink, "when designing cross-environment sync") | extract → `_system/docs/vault-mirror-specification.md`; update wikilink |
| E3 | `multi-agent-deliberation/data/` (deliberations/ + raw/ + baseline/ + experimental-results + gate evals) | compound-provenance **and live record store** — 32 deliberation records incl. operator rating-capture (panel calibration data); the kept deliberation skill writes here | `.claude/skills/deliberation/SKILL.md:241-242` — **stale path defect**: skill says `Projects/multi-agent-deliberation/data/deliberations/`, which does not exist; actual store is the Archived/ copy. Next invocation would silently create an orphan dir | extract → `_system/data/deliberations/` (proposed home); **re-point SKILL.md paths in B5 pack (VO-023)** — flagged there |

## Decisions flagged (not extractions)

| # | Item | Situation | Proposal |
|---|---|---|---|
| D1 | `Archived/KB/solutions-linkage-proposal.md` | live wikilink from kept solution `write-read-path-verification.md:76`; but it is an **unexecuted enforcement proposal** — matches standing operator feedback against pre-committing schema to unwritten paths | delete with B1; remediate the link to a one-line past-proposal note (git provenance). **Operator confirmed 2026-06-10** (question gate) — no further B1 review needed for this item |
| D2 | `capture-tiers.md:56` → `crumb-tess-bridge/progress/run-log.md` | live doc cites an archived run-log as provenance for the quick-capture retirement | no extraction — remediate the citation to a git-history pointer in the B1 remediation step |
| D3 | Category-level `Archived/` references (AGENTS.md, file-conventions, archive-conventions solution, spec v2-4, operator docs, architecture/02+04+05, vault-structure-reference, MOCs) | taxonomy mentions of Archived/-as-location, not content consumers | A11 taxonomy cleanup list — already routed to VO-024 (B3 pack) |
| D4 | Skill procedural refs: `audit/SKILL.md` (Archived/KB purge-review steps 10/102/115/124/137), `attention-manager/SKILL.md:140` ("Skip Archived/Projects/") | procedures referencing a directory that will not exist | B5 pack (VO-023): audit loses purge-review steps (or re-scopes them to git-history review); attention-manager line dropped |

## AC check (VO-021)

- Full Archived/ listing recorded: structure, counts, weight, per-project
  inventory above; commands verbatim; tracked listing reproducible +
  re-verified at B1 open ✓
- Every exception justified as canonical-reference or compound-provenance:
  E1/E2 canonical-reference, E3 compound-provenance + live store ✓
