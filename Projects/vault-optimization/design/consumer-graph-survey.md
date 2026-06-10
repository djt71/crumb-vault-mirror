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
  - survey
topics:
  - moc-crumb-operations
---

# VO-019/020 — Consumer-Graph Survey (all 58 delete/merge rows)

Nine-surface survey per design D2. Vault-internal surfaces (VO-019) run by two
read-only Explore subagents; system surfaces (VO-020) by a third; all
load-bearing claims spot-checked in the main session (provenance check per
CLAUDE.md Subagent Validation — two agent misclassifications corrected, noted
inline). Survey input: every `prop: delete` and `prop: merge-into` manifest
row (58; merge rows included because the source file leaves the namespace).

## Commands (verbatim templates; per-item values substituted)

Vault-internal (VO-019), run per item:

```
grep -rn "\[\[<basename>" --include="*.md" /Users/danny/crumb-vault --exclude-dir=.git
grep -rln "<basename-or-filename>" --include="*.md" /Users/danny/crumb-vault --exclude-dir=.git
grep -rln "<basename-or-filename>" /Users/danny/crumb-vault/.claude /Users/danny/crumb-vault/_system/scripts
```

Scoping deviations (recorded per agent output): short/common skill names
(checkpoint, critic, learning-plan, writing-coach, diagram-capture) and all
skill-workflows/* files surveyed via path-scoped patterns only
(`skills/<name>`, `<name>/SKILL`, `<name> skill`, `skill-workflows/<name>`) —
bare-name grep would measure the live skill, not the doc. Schema files
surveyed by both path (`schemas/briefs/<name>`) and declaration
(`brief_schema: <name>`). MOC surface covered by the wikilink+filename greps
over `*moc*.md` / `*-overview.md` / `orientation-map*` (hits appear below).

System surfaces (VO-020), one OR-joined pass per surface:

```
grep -n "<pattern>" .claude/settings.json .claude/settings.local.json
grep -n "<pattern>" _system/scripts/{session-startup,skill-preflight,vault-check}.sh
grep -rn "<pattern>" ~/Library/LaunchAgents/            # 10 plists
cat _system/scripts/drive-sync-computer-filter.txt
grep -n "<pattern>" _system/scripts/{vault-backup,mirror-sync,vault-gc,drive-sync}.sh
grep -n "<pattern>" .obsidian/{workspace,app,core-plugins,community-plugins,hotkeys}.json
grep -n "<pattern>" /Users/danny/quartz-vault/quartz.config.ts   # + vault-web/qmd plists
grep -rn "<pattern>" ~/.claude/projects/-Users-danny-crumb-vault/memory/*.md
grep -rn "<glob-patterns>" _system/scripts/*.sh          # naming conventions
```

Hit classification: `structural-consumer` (live surface that breaks or
misleads post-deletion → remediation required, same batch) ·
`historical-mention` (logs/provenance, no action) · `sibling-delete`
(referencing file is itself delete-listed) · `self` (this project's
artifacts).

## ⚠️ Evidence-status changes (amendment A2 — operator re-review)

1. **dns-recon.sh: no-evidence → proven-active.** `Projects/
   customer-intelligence/import-workflow.md` (project phase ACT) invokes it
   (:126) and requires its `dns-recon.md` output (:115/:159/:205/:211).
   VO-013 missed project-doc surfaces. Manifest row reclassified, prop
   flipped to **keep**, wholesale sign-off voided for this row — **returned
   to operator.** Spot-checked in main session ✓.
2. **feed-pipeline-calibration.jsonl: superseded → sunset-tied (pending
   AS-028).** Classified "runtime gone," but the **kept** feed-pipeline
   skill still appends to it (SKILL.md:450) and the operator how-to
   references it (run-feed-pipeline.md:78,91). Deletion must ride with the
   feed-pipeline AS-028 decision (or that skill's calibration step is
   stripped first). Manifest row annotated. Spot-checked ✓.
3. **Brief schemas (`_system/schemas/briefs/`, 4 files): superseded but with
   kept-skill consumers.** `brief_schema:` capability declarations live in
   kept skills' frontmatter — researcher:13 (research-brief), critic:14,67
   (review-brief), feed-pipeline:14,26,38 (feed-pipeline-brief),
   vault-query:14 (vault-query-brief). Supersession stands (dispatch surface
   dead) but B4 deletion requires same-batch frontmatter strips in B5-owned
   files → **B4/B5 must be coordinated in the VO-023 pack** (single
   changeset or B5-before-B4 ordering for these lines). Spot-checked ✓.

Corrections to agent output (main-session judgment): (a) `compound-insight`
frontmatter-tag usage in solutions/Sources is a convention, not a schema
dependency — downgraded from structural-consumer to no-action; (b)
liberation-directive.md matches a research-brief *instance* filename, not
the schema — false positive, dropped. (c) One line-number misreport
(skill-preflight fast-path is line 44, not 457) — content verified correct.

## Per-item consumer lists

“Consumers” = structural-consumers only (remediation list). Items with
`none` had only historical/sibling/self hits — full hit detail preserved in
the agent transcripts; counts and classifications reviewed this session.

### Skills (merge rows → B5 pack)

| Item | Consumers (remediation at B5) |
|---|---|
| checkpoint → audit | orientation-map.md:41 · skills-reference.md:28,54,68,140,147 · **CLAUDE.md:106** (Phase-1 delegation list) · AGENTS.md:48 · skill-preflight.sh:44 (fast-path list) |
| critic → peer-review | orientation-map.md:43 · skills-reference.md:30,55,142 · own brief_schema line dies with merge (see A2 #3) |
| diagram-capture → deck-intel/keep | orientation-map.md:46 · skills-reference.md:33,55,95,145 · **deck-intel/SKILL.md:88 (composable-mode call — the VO-019 composition check: deck-intel is the live composer; inbox-processor names it in description only)** · skill-preflight.sh:44 |
| learning-plan → systems-analyst | orientation-map.md:49 · skills-reference.md:36,55,66,82,148 · skill-preflight-map.yaml:85 · _attachments/learning/wyner-fluent-forever-companion.md:36 (names it as consuming skill) |
| writing-coach → peer-review | orientation-map.md:57 · skills-reference.md:44,55,67,81,125,156 · skill-preflight-map.yaml:91 · AGENTS.md:46 · solutions/ai-telltale-anti-patterns.md (skill_origin + "Reference document for the writing-coach skill" — re-point to merge target) |

### Scripts (B4 pack)

| Item | Consumers (remediation at B4) |
|---|---|
| batch-moc-placement.py | none (architecture/02:201 "Plus:" list + spec v2-4 tree = descriptive; covered by the one arch-cluster edit below) |
| bridge-watcher.py | vault-intake-map.md:38,152,207 · architecture/02:194,201 · architecture/03:300-310 · architecture/04:88,94,147 · operator/how-to/crumb-deployment-runbook.md:43,469-516 |
| clear-claude-cache.sh | crumb-deployment-runbook.md:901 |
| com.crumb.bridge-watcher.plist | architecture/04:147 · crumb-deployment-runbook.md:469-516 (not in LaunchAgents — parked only ✓) |
| dns-recon.sh | **RECLASSIFIED — keep proposed** (A2 #1): customer-intelligence/import-workflow.md |
| openclaw-isolation-test.sh | none |
| tess-health-check.sh | architecture/04:142 ("preserved for possible repair" — line removed at B4) |
| vault-search.sh | none (tess-v2 design/review docs = historical) |

### Protocols (B4 pack)

| Item | Consumers |
|---|---|
| bridge-dispatch-protocol | **CLAUDE.md:219** (AS-025 removes §first — gate already in pack) · architecture/02:143 · architecture/03:17 · orientation-map.md:95,151 |
| dispatch-triage-protocol | architecture/02:146 |
| research-brief-review-protocol | none |

### Solutions (B3 pack)

| Item | Consumers |
|---|---|
| claude-print-cwd-sensitivity → merge | none (merge target carries content) |
| lucidchart-policy-compliance | none |

### Docs (B3 pack)

| Item | Consumers (remediation at B3) |
|---|---|
| adr-cli-native-agent-architecture | none |
| agent-skills-best-practices → merge | skill-authoring-conventions.md:370 (wikilink — becomes merge target) · file-conventions.md:97 (wikilink example) |
| change-spec-skill-model-routing | none |
| claude-ai-session-prompt → merge | none |
| code-setup-prerequisites | none |
| compound-enhancements-spec (+summary) | none |
| feed-intel-processing-chain (+diagram) | architecture/03:17 ("formerly [[...]]" attribution — drop links, keep attribution prose) |
| feed-pipeline-calibration.jsonl | **A2 #2 — rides with AS-028**: feed-pipeline/SKILL.md:450 · run-feed-pipeline.md:78,91 |
| openclaw-colocation-spec | architecture/04:17,340 · crumb-studio-migration.md:355,672,676 (kill-switch/threat-model pointers — re-point to git provenance or inline the needed content) |
| openclaw-colocation-spec-summary | none |
| openclaw-crumb-reference | crumb-design-spec-v2-4.md (integration-reference pointer) · standing AS-029 handoff flag (memory rewrite may consume first) |
| openclaw-memory-research / openclaw-skill-integration | none |
| peer-review-skill-spec | peer-review-config.md:89 (initial-design-values pointer → git citation) · crumb-design-spec-v2-4.md:133,3645 |
| proposal-pattern-enforcement-schema | none |
| tess-crumb-boundary-reference | moc-crumb-architecture.md:39 · architecture/01:17 · architecture/02:17 |
| tess-crumb-comparison | moc-crumb-architecture.md:40 · architecture/01:17 · architecture/02:17 |
| vault-intake-overview-diagram (.md + .excalidraw) | none |
| vault-startup-detection-diagram | none |

### skill-workflows/ (15 files, B3)

All 15: **consumers = none** (path-scoped grep). Orphan-layer finding from
VO-015 confirmed at consumer level — only self/historical/sibling hits
(crumb-tess-bridge, fif-triage-and-signals, tess-operations had
session-log/archived provenance mentions only).

### Clusters (B3)

| Item | Consumers |
|---|---|
| docs/attachments/ (tess-crumb-architecture .md+.png) | moc-crumb-architecture.md:41 (active MOC wikilink) |
| _system/perplexity/ (3 files) | none vault-internal; **memory hit → AS-029 handoff** (below) |
| schemas a2a/compound-insight | _openclaw/dispatch/templates/compound-insight.md:41 — AS-owned surface (AS-026/027 scope), dies independently; no VO remediation |
| schemas a2a/delivery-envelope | none |
| schemas briefs/ (4 files) | **A2 #3** — kept-skill frontmatter lines (B4/B5 coordination) + AS-owned _openclaw template/SOUL.md refs |
| schemas capabilities/manifest.yaml | none (live skills use `capabilities:` blocks by convention, no path ref) |

## System surfaces (VO-020) — all 7 swept

1. **Hooks/settings:** settings.json + settings.local.json — clean.
   skill-preflight.sh:44 fast-path lists `checkpoint`, `diagram-capture`;
   skill-preflight-map.yaml keys `learning-plan`:85, `writing-coach`:91 →
   B5 remediations. CLAUDE.md:106 + :219, AGENTS.md:46,48 as above.
2. **Live plists (10):** no item referenced. bridge-watcher plist confirmed
   parked-only.
3. **Backup/sync filters:** directory-level rules only — no per-item
   breakage. Notes: `_system/perplexity/` already falls to catch-all
   excludes in both drive-sync filter and mirror-sync (no filter edits
   needed at deletion); skill-workflows/attachments/schemas ride under
   `_system/docs/**`/`_system/schemas/**` includes (deletions simply stop
   syncing); drive-sync NLM_DIRS = architecture/operator/llm-orientation
   only. vault-backup.sh = full archive, no exclusions. vault-gc.sh TTLs
   only touch `_openclaw/`.
4. **Obsidian config:** workspace pins/plugins/hotkeys — clean.
5. **Dashboard/web (read-only, A3):** quartz.config.ts + vault-web/qmd-index
   plists — no item references.
6. **Harness memory → AS-029 handoff:** one substantive hit —
   `canonical-taxonomy-sync-points.md:31` instructs updating
   `_system/perplexity/crumb-vault-context.md` (delete-listed) as a taxonomy
   sync point; memory needs a rewrite when the perplexity cluster deletes.
   All other hits conceptual/historical (checkpoint/vault-search word
   matches, openclaw-colocation history, FIF "manifest" ≠ schema manifest).
   Handed off via run-log note this session.
7. **Glob/naming conventions:** no glob in any hook/backup script
   auto-processes a deletion candidate. setup-crumb.sh:96 chmod-iterates
   `_system/scripts/*.sh` (benign). `*.jsonl` in clear-claude-cache.sh
   targets Claude project dirs, not `_system/docs/` (no live match —
   and that script is itself delete-listed).

## Remediation-consumer index (for B-pack assembly)

| Consumer file | Items it must be edited for | Batch |
|---|---|---|
| `_system/docs/llm-orientation/orientation-map.md` | 5 merge skills, bridge-dispatch-protocol | B5, B4 |
| `_system/docs/operator/reference/skills-reference.md` | 5 merge skills | B5 |
| `_system/docs/architecture/01..04` (cluster — one edit pass) | bridge-watcher(+plist), tess-health-check, batch-moc/dns-recon list line, both protocols, feed-intel-chain links, openclaw-colocation-spec, tess-crumb-boundary/comparison | B3/B4 |
| `_system/docs/operator/how-to/crumb-deployment-runbook.md` | bridge-watcher(+plist), clear-claude-cache | B4 |
| `Domains/Learning/moc-crumb-architecture.md` | tess-crumb-boundary/comparison, docs/attachments cluster (+ E2 vault-mirror extraction link fix at B1) | B3/B1 |
| `_system/docs/crumb-design-spec-v2-4.md` | openclaw-crumb-reference, peer-review-skill-spec | B3 |
| `_system/docs/peer-review-config.md` | peer-review-skill-spec | B3 |
| `_system/docs/skill-authoring-conventions.md`, `file-conventions.md` | agent-skills-best-practices merge | B3 |
| `_system/docs/crumb-studio-migration.md` | openclaw-colocation-spec | B3 |
| `_system/docs/vault-intake-map.md` | bridge-watcher | B4 |
| `CLAUDE.md` (:106, :219) | checkpoint merge; bridge-dispatch (AS-025 gate) | B6 |
| `AGENTS.md` (:46, :48) | writing-coach, checkpoint merges | B5 |
| `_system/scripts/skill-preflight.sh:44` + `skill-preflight-map.yaml:85,91` | checkpoint, diagram-capture, learning-plan, writing-coach | B5 |
| Kept-skill frontmatter (researcher/critic/vault-query/feed-pipeline) | brief_schema lines (schemas deletion) | B4+B5 coordinated |
| `_system/docs/solutions/ai-telltale-anti-patterns.md` | writing-coach merge (re-point) | B5 |
| `_attachments/learning/wyner-fluent-forever-companion.md` | learning-plan merge (re-point) | B5 |
| `.claude/skills/deck-intel/SKILL.md` | diagram-capture disposition | B5 |
| `Projects/customer-intelligence/import-workflow.md` | only if operator overrides dns-recon keep | B4 |

## AC check

- **VO-019:** every delete row has a consumer list (possibly empty) ✓ —
  58/58 above; commands recorded verbatim (templates + per-item scoping
  notes) ✓
- **VO-020:** all system surfaces swept with recorded commands ✓ (7 listed —
  design D2 surfaces 3–9); memory hits handed to AS-029 via run-log note ✓
