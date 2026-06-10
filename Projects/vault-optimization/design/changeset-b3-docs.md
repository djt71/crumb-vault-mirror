---
type: changeset-pack
project: vault-optimization
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: keep-set-manifest.md
tags:
  - changeset
  - b3
topics:
  - moc-crumb-operations
---

# B3 Docs Changeset Pack (VO-024)

**Batch:** B3 — `_system/docs/` + solutions consolidation (executes at VO-030).
**Drafted:** 2026-06-10 against manifest baseline 2026-06-10 (HEAD b58a3e4e).
**Batch-open staleness check (amendment A1):** re-validate every disposition
against the working tree + re-diff inventory before applying; evidence-status
changes return to operator (A2).

## Approval record

| Field | Value |
|---|---|
| Pack status | **APPROVED** |
| Approved by | operator (in-conversation question gate) |
| Date | 2026-06-10 |
| Conditions/exceptions | none — approved as drafted incl. #F1/#F2/#F3 |

Items flagged for explicit operator attention at approval: #F1 (egpu
evaluation delete), #F2 (vault-intake-map delete over refresh), #F3 (A11
scoping — archival procedure survives, taxonomy mentions cleaned).

## Cluster map (VO-024 AC: every `_system/docs` + solutions row mapped)

Clusters per design D5: **constitutional** (CLAUDE.md-cited or structural) ·
**skill-referenced** (consumed by a kept skill/overlay/script/protocol) ·
**solutions** (compound-engineering corpus) · **orphan** (no live consumer).
Project records and protocols/scripts/overlays are B4/B5 scope, not here.

- **Constitutional:** CLAUDE.md (B6-owned), liberation-directive,
  overlay-index (B4-owned), crumb-design-spec-v2-4, file-conventions,
  context-checkpoint-protocol, convergence-rubrics, cross-project-deps,
  crumb-v2-system-health-assessment, failure-log, estimation-calibration,
  personal-context, skill-authoring-conventions, separate-version-history
  (+archive — see R7), capture-tiers, claude-ai-context, claude-code-ssh-setup,
  crumb-studio-migration, tess-v2-durable-patterns, adr-crumb-v3,
  Projects/index.md
- **Skill-referenced:** code-review-config, deliberation-config,
  peer-review-config, review-safety-denylist, design-advisor-dataviz,
  network-skills-sources, www-design-taste-profile, goal-tracker.yaml,
  kb-to-topic.yaml, skill-preflight-map.yaml, mirror-config.yaml,
  templates/notebooklm/ (12), security-kb-sources (KB-adjacent),
  schemas/deliberation/assessment-schema.yaml
- **Solutions (25):** 21 keep per manifest; lucidchart-policy-compliance
  delete; claude-print-cwd-sensitivity merge; egpu-local-compute-evaluation
  delete (R11, flag #F1); haiku-soul-behavior-injection keep (R12)
- **Orphan:** skill-workflows/ (15), vault-intake-overview-diagram (+.excalidraw),
  vault-startup-detection-diagram, code-setup-prerequisites,
  adr-cli-native-agent-architecture, proposal-pattern-enforcement-schema,
  system-architecture-diagram (redirect stub)
- **Superseded-by-sunset (consumer = decommissioned runtime):** openclaw-* (5),
  tess-crumb-* (2), feed-intel-processing-chain (+diagram), perplexity/ (3),
  attachments/ (2), schemas a2a/ (2) + capabilities/ (1),
  vault-intake-map (R9), liberation-surfaces-snapshot (R6),
  why-two-agents, first-tess-interaction
- **Executed-plan/provenance-in-git:** compound-enhancements-spec (+summary),
  peer-review-skill-spec, change-spec-skill-model-routing, security-kb-plan
  (R5), network-kb-plan (R5), vault-restructure-analysis + discussion (R10)
- **Doc clusters kept with refresh lists:** architecture/ (6),
  operator/explanation (3 of 4), operator/how-to (10, two flagged),
  operator/tutorials (2 of 3), operator/reference (8, post-B5 refresh),
  llm-orientation/orientation-map

## Pending-row resolutions (made at VO-024, this pack)

Manifest `pending — VO-024` rows resolved here. Evidence: Explore-agent doc
survey 2026-06-10 (provenance-checked) + targeted reads, recorded in run-log.

| # | Item | Resolution | Rationale |
|---|---|---|---|
| R1 | anthropic-consolidation-hypothesis | **keep** | compound-provenance for the consolidation/sunset decision chain — the analysis that preceded agentic-sunset; verified-claims record |
| R2 | claude-ai-session-prompt | **merge-into:claude-ai-context** | confirmed; 2-ref pair doc |
| R3 | agent-skills-best-practices | **merge-into:skill-authoring-conventions** | confirmed; feeds same consumer |
| R4 | cybersecurity-kb-capture | **keep** | upstream capture-value filter, no staleness, generalizes to any KB domain; NOT merged into security-kb-plan (which deletes) |
| R5 | security-kb-plan, network-kb-plan | **delete** | executed plans — security batches 1–5 DONE + batch 6 dispatched (session-log:428); network all 9 sources DONE 2026-03-06. Executed-spec precedent: provenance in git. Durable guidance lives in cybersecurity-kb-capture (R4) + *-kb-sources catalogs (keep) |
| R6 | liberation-surfaces-snapshot | **delete** | frozen v1.1 snapshot of the four-surface architecture; directive v2.1 deliberately dropped surface architecture; the surfaces themselves (Tess/Comet/Computer dispatch) are decommissioned — historical record lives in git |
| R7 | separate-version-history-archive | **keep** | functional version-history partition (v0.1–v1.9.1), cross-referenced from live history doc — active infrastructure, not parked content |
| R8 | system-architecture-diagram | **delete** | 16-line redirect stub, `status: archived`; content absorbed into architecture/01 (DOH-005). Remediate refs → architecture/01-context-and-scope |
| R9 | vault-intake-map | **delete** (flag #F2) | 8 documented intake paths of which 5 are decommissioned (FIF routing, Telegram digest, bridge dispatch, save command, research dispatch); live paths (_inbox/, NLM, direct KB drop) covered by spec §7 + capture-tiers (orthogonal-but-sufficient). Refresh option declined: no named consumer for the refreshed map |
| R10 | vault-restructure-analysis-20260220 + discussion | **delete** | predecessor restructure provenance; superseded by v3 ADR + this project's spec/manifest; git provenance |
| R11 | egpu-local-compute-evaluation | **delete** (flag #F1) | WATCH(30d) expired 2026-05; decision context (Tess v2 fine-tuning critical path) decommissioned; hardware evals stale out fast — re-evaluation would restart from current landscape anyway |
| R12 | haiku-soul-behavior-injection | **keep** | pattern generalizes (small-model behavioral ceiling → dedicated session prompts; system-doc = routing hints only); write-only-from-ledger precedent |
| R13 | hallucination-detection-protocol (B4 item, decision owned here) | **keep** | NOT a redundant spec copy — authoritative expansion of §4.8 with unique operative depth (falsifiability examples, confidence-promotion rules, monthly human-grounded procedure). Manifest row pending→keep |
| R14 | claude-print-automation-patterns | **keep** (re-check passed) | refs=36; durable harness knowledge independent of sunset subject |
| R15 | write-only-from-ledger | **keep** (re-check passed) | pattern generalized beyond FIF ledger subject |
| R16 | signals-archive-2026.jsonl | **delete** (AS concurrence — sunset-tied) | FIF raw signal archive; producer decommissioned (dead-producer rule, storage policy); promoted signal notes live in Sources/signals/ (KB, kept) |

## Disposition list — deletes (with per-item remediation)

Remediation classes: `none` = survey found no structural consumers;
edits execute in the same B3 commit (D4 batch discipline).

### Root docs (delete, 24 files)

| Item | Remediation |
|---|---|
| adr-cli-native-agent-architecture | none |
| change-spec-skill-model-routing | none |
| code-setup-prerequisites | none |
| compound-enhancements-spec + -summary | none |
| feed-intel-processing-chain + -diagram | architecture/03:17 — drop links, keep attribution prose |
| openclaw-colocation-spec | architecture/04:17,340 + crumb-studio-migration.md:355,672,676 — re-point kill-switch/threat-model pointers to git provenance or inline needed content |
| openclaw-colocation-spec-summary | none |
| openclaw-crumb-reference | crumb-design-spec-v2-4.md integration-reference pointer → git citation. **Order gate: confirm AS-029 memory rewrite has consumed it first (standing handoff flag)** |
| openclaw-memory-research | none |
| openclaw-skill-integration | none |
| peer-review-skill-spec | peer-review-config.md:89 initial-design-values pointer → git citation; crumb-design-spec-v2-4.md:133,3645 → git citation |
| proposal-pattern-enforcement-schema | none |
| tess-crumb-boundary-reference | moc-crumb-architecture.md:39 + architecture/01:17 + 02:17 — drop rows/links |
| tess-crumb-comparison | moc-crumb-architecture.md:40 + architecture/01:17 + 02:17 — drop rows/links |
| vault-intake-overview-diagram (+.excalidraw) | none |
| vault-startup-detection-diagram | none |
| security-kb-plan (R5) | refs are self/sibling; verify at batch open |
| network-kb-plan (R5) | refs=1, verify at batch open |
| liberation-surfaces-snapshot (R6) | check liberation-directive.md for forward pointer; drop if present |
| system-architecture-diagram (R8) | refs=6 → re-point to architecture/01-context-and-scope |
| vault-intake-map (R9) | refs=3 incl. bridge-watcher rows (which would otherwise be B4 remediation — dies here instead, note cross-batch: B4 pack updated) |
| vault-restructure-analysis-20260220 + -discussion (R10) | mutual refs + any spec citations → git citation |

### Solutions (delete 2, merge 1)

| Item | Remediation |
|---|---|
| lucidchart-policy-compliance | none (subject removed 2026-03) |
| egpu-local-compute-evaluation (R11, #F1) | refs=2 — verify at batch open |
| claude-print-cwd-sensitivity → merge-into:claude-print-automation-patterns | fold content as a section; delete source; no external refs |

### skill-workflows/ (15 files — orphan layer, delete whole directory)

Consumers = none (VO-019 path-scoped survey). 12 no-evidence rows carry
wholesale operator sign-off 2026-06-10; 3 superseded rows (crumb-tess-bridge,
fif-triage-and-signals, tess-operations) need none per D1.

### Clusters + data files (delete)

| Item | Remediation |
|---|---|
| docs/attachments/ (tess-crumb-architecture .md+.png) | moc-crumb-architecture.md:41 — drop row |
| _system/perplexity/ (3 files) | none vault-internal; **AS-029 handoff stands** (canonical-taxonomy-sync-points memory rewrite — verify done at batch open) |
| schemas/a2a/ (2 files) | _openclaw template ref is AS-owned surface, dies independently — no VO remediation |
| schemas/capabilities/manifest.yaml | none (live skills use `capabilities:` blocks by convention) |
| signals-archive-2026.jsonl (R16) | refs=2 — verify at batch open; AS concurrence noted |

**Reassignment:** `schemas/briefs/` (4 files) moves from this batch to **B5**
(A2 #3: deletion requires same-batch `brief_schema:` frontmatter strips in
kept skills — single-changeset coordination). Manifest cluster row exploded.

### Deferred (ride other gates — listed for completeness, not B3 actions)

| Item | Gate |
|---|---|
| feed-pipeline-calibration.jsonl | AS-028 feed-pipeline decision (B5); if skill keeps calibration step, file stays; if stripped, file deletes with that B5 commit |
| run-feed-pipeline.md (how-to) | follows feed-pipeline AS-028 outcome (B5-adjacent edit or delete) |
| tess-to-danny-migration runbook (how-to) | tess-danny-migration status question — AS coordination; keep until resolved |

## Merges (2)

| Source → target | Remediation |
|---|---|
| agent-skills-best-practices → skill-authoring-conventions | fold unique content; skill-authoring-conventions.md:370 wikilink becomes internal; file-conventions.md:97 example link → update to a live example |
| claude-ai-session-prompt → claude-ai-context | fold as section; delete source |

## Keep-cluster refresh lists (same B3 commit)

**architecture/ (6 files)** — strip/annotate sunset-era components:
- 01:17, 02:17 (tess-crumb-* links), 02:143 (bridge-dispatch), 02:146
  (dispatch-triage), 02:157 (Archived/ row — A11), 02:194,201
  (bridge-watcher, batch-moc "Plus:" list line)
- 03:17 (feed-intel-chain attribution), 03:300-310 (bridge-watcher runtime view)
- 04:17,340 (colocation), 04:88,94,147 (bridge-watcher+plist), 04:142
  (tess-health-check "preserved for repair" line), 04:230 (Archived/ tree — A11)
- 05:25,27 (Archived/ frontmatter rules — A11 reword, procedure survives)

**operator/explanation (4 files)** — keep cluster; **why-two-agents.md →
delete** (explains the Crumb+Tess two-agent architecture, decommissioned; AS
concurrence). Cluster row explodes.

**operator/tutorials (3 files)** — first-crumb-session keep;
**first-tess-interaction → delete** (AS concurrence);
mission-control-orientation **refresh** (strip dead panels; dashboard kept
per A3).

**operator/how-to (10 files)** — keep; vault-gardening.md **rewrite** (A11
below); run-feed-pipeline + tess-to-danny deferred (above).

**operator/reference (8 files)** — keep; content refresh after B5 description
rewrites (VO-009 adjacency, not B3 scope) — except vault-structure-reference
A11 edits (below).

## A11 — Archived/-as-category taxonomy cleanup list

**Scoping decision (operator can veto at approval, #F3):** B1 deletes the
`Archived/` directory and its contents. The **operator-initiated archival
procedure survives** — CLAUDE.md §Project Archival and spec §4.6 remain as-is;
the directory is simply recreated on the next archival (operator already
deferred feed-intel-framework archival on this premise). A11 therefore cleans
**taxonomy/navigation mentions that present Archived/ as an existing populated
location**, NOT lifecycle-procedure definitions. One exception: the
**KB-archival flow** (`Archived/KB/`) is rewritten to match aggressive
deletion — stale KB notes are deleted with git provenance, not parked
(consistent with D4's audit-skill re-scope, executed at B5).

| File | Edit |
|---|---|
| AGENTS.md:35 | reword directory row: archival target, recreated on archival (not "completed project archives" as standing content) |
| architecture/02:157 | same reword |
| architecture/04:230 | tree diagram — annotate or drop Archived/ node |
| architecture/05:25,27 | frontmatter-rules prose — keep rule (procedure survives), reword existence assumption |
| vault-structure-reference.md:41,157 | tree + project-docs section — reword as above |
| file-conventions.md:21,39,41 | keep rules (procedure survives); :433 — **rewrite**: stale KB notes deleted with git provenance (was: archived to Archived/KB/) |
| vault-gardening.md:29,42,46,72 | **rewrite KB-archival flow**: archive→delete with git provenance; purge-review trigger removed (audit-skill steps re-scoped at B5, D4) |
| archive-conventions.md (solution):146 | reactivation step references — keep (procedure survives), verify wording at batch open |
| spec v2-4 (§4.1.6, §4.6, §7.8 checks 12/14/16, tree at :226) | **no edits** — procedure definitions, mechanism survives; checks pass vacuously while directory absent |
| moc-crumb-architecture.md:37 | E2 extraction link fix (B1 cross-batch — listed for traceability) |
| learning-overview.md:31 | E1 extraction link fix (B1 cross-batch) |

## AC check (VO-024)

- Pack carries disposition list + remediation map + approval record ✓
  (approval pending operator)
- Every `_system/docs` + solutions row mapped to a cluster ✓ (cluster map)
- Superseded entries deleted-or-justified per spec retention rule ✓ (every
  keep justifies as canonical-reference or compound-provenance; deletes cite
  git provenance)
- A11 list included ✓ (with scoping decision flagged #F3)
