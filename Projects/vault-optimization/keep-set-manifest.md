---
type: keep-set-manifest
project: vault-optimization
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: design/optimization-design.md
source_updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - manifest
---

# vault-optimization — Keep-Set Manifest

Single source of truth for all dispositions (design principle #3 — no side
lists). Schema per design D1. Rubric categories: `proven-active` ·
`structural-necessity` · `contingency-keep` · `superseded` · `no-evidence`.
Dispositions: `keep` · `keep-dormant` · `merge-into:X` · `delete`.
Evidence cells are filled by VO-012–015 and are never blank at pass completion;
`pending` marks rows awaiting their evidence pass. Operator-review is
`required+signed` for every no-evidence delete (VO-017), `—` otherwise.

## Baseline snapshot (regenerated 2026-06-10, VO-011)

| Measure | Value | Note |
|---|---|---|
| md files (excl. .git) | 2,515 | +4 vs TASK regen (2,511); +11 vs spec snapshot |
| Skills | 20 | `.claude/skills/` |
| Agents | 4 | `.claude/agents/` |
| Overlays | 8 | per overlay-index.md rows |
| Scripts | 20 | `_system/scripts/` (incl. 1 filter .txt, 1 retired plist file) |
| Protocols | 6 | `_system/docs/protocols/` |
| Solutions | 25 | `_system/docs/solutions/` |
| Projects | 12 | `Projects/` directories |
| Live plists | 10 | `~/Library/LaunchAgents/` |
| Archived/ | 147M | deletion scope (B1) |
| Projects/ | 42M | |
| Sources/ | 12M | KB — out of manifest scope |
| _system/ | 5.1M | |
| _attachments/ | 4.7M | B2 orphan-sweep scope |
| Domains/ | 560K | KB — out of manifest scope |

**Scope boundary (PLAN gate, 2026-06-10):** manifest covers primitive surface +
`_system/` docs + project records. KB content (`Sources/`, `Domains/`, knowledge
notes) is Tier-1 data, not surface — excluded; weight handled via VO-004 storage
policy only. `_system/logs/` is weight, not surface — handled by storage policy
(D3) and B2, not manifest rows. Harness memory (`~/.claude/.../memory/`) is
AS-029's surface — analysis-only for VO (Appendix A); not a manifest section.
`_openclaw/`, `_tess/`, `_staging/` are AS-owned (AS-026/027) — VO never touches.

## Skills (20)

Evidence pass VO-012, 2026-06-10. Commands recorded in run-log: log greps over
`_system/logs/session-log*.md` + `Projects/*/progress/run-log*.md`; `git log
--grep` per name; `session_reports.db` (16 sessions, 2026-04-06→06-10,
supplementary per D1); structural refs in CLAUDE.md / settings hooks /
skill-preflight-map.yaml. Prior consolidation round on record
(session-log.md:148,157, 2026-03): obsidian-cli→vault-query and
excalidraw→mermaid already merged, lucidchart removed; **deferred-merge list**:
critic→peer-review (#8), learning-plan→systems-analyst (#11),
writing-coach→peer-review (#12), checkpoint→audit (#13). Dispositions marked
`prop:` are proposals — frozen at VO-023 (B5 pack) after VO-017/019/020.

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| action-architect | skill | proven-active | invoked 2026-06-10 (VO TASK, run-log); 15 commits, latest 2026-06-10; 8 run-log files; preflight-map entry | keep | joint (B5; AS M6 gate) | — |
| attention-manager | skill | proven-active | produced `_system/daily/2026-06-10.md` (skill_origin frontmatter, today); weekly plan session-log.md:719 (2026-04-07); critical_input goal-tracker.yaml in preflight map | keep | joint (B5; AS M6 gate) | — |
| audit | skill | proven-active | CLAUDE.md startup/staleness refs (lines 118/199/202); db 4 sessions latest 2026-06-10; 60 commits latest 2026-06-10; vault-audit-status.json producer | keep; merge target for checkpoint (#13) | joint (B5; AS M6 gate) | — |
| checkpoint | skill | proven-active | CLAUDE.md Phase-1 delegation list (line 106); db 2 sessions; 15 commits latest 2026-06-10; deferred merge →audit on record (session-log.md:157) | prop: merge-into:audit | joint (B5; AS M6 gate) | — |
| code-review | skill | proven-active | db latest 2026-04-24; CLAUDE.md milestone-boundary mandate (vault-check §23 enforces); code-review-config.md; 16 commits | keep | joint (B5; AS M6 gate) | — |
| critic | skill | proven-active (light) | registered at vault audit session-log.md:289; 14 commits latest 2026-04-11; db 0; deferred merge →peer-review on record (session-log.md:157) | prop: merge-into:peer-review | joint (B5; AS M6 gate) | — |
| deck-intel | skill | proven-active (dormant ~3mo) | KB enrichment runs session-log.md:422,428 (~2026-03); DI-007 batch validation session-log.md:691; 9 commits latest 2026-03-20; career-tied (Infoblox decks) | keep (operator work surface) | joint (B5; AS M6 gate) | — |
| deliberation | skill | proven-active | db 1 session 2026-04-17; 12 commits latest 2026-06-01; deliberation-config.md + dispatch agent present | keep | joint (B5; AS M6 gate) | — |
| diagram-capture | skill | proven-active (dormant ~3mo) | build+Mode-B validation session-log.md:418-421 (2026-03-06); composable from deck-intel/inbox-processor (SKILL.md descriptions); 3 commits latest 2026-03-14 | prop: merge-into:deck-intel OR keep — needs VO-019 composition check | joint (B5; AS M6 gate) | — |
| feed-pipeline | skill | superseded (partial) | consumes `_openclaw/inbox/` + FIF SQLite — FIF runtime decommissioned 2026-05-28, agentic layer 2026-06-10 (AS run-log); intake dir deliberately stays open (operator decision); 14 commits latest 2026-03-13; db 0 | pending — sunset-tied: AS-028 coordination required | joint (B5; AS M6 + AS-028) | — |
| inbox-processor | skill | proven-active | CLAUDE.md MarkItDown ref (line 222); inbox run session-log.md:691 (2026-04); orphan detection reused by D3 storage policy; 21 commits | keep | joint (B5; AS M6 gate) | — |
| learning-plan | skill | proven-active (light) | Step-5 enrichment session-log.md:449; 1 run-log + 1 session-log file; 2 commits latest 2026-03-06; deferred merge →systems-analyst on record (session-log.md:157) | prop: merge-into:systems-analyst | joint (B5; AS M6 gate) | — |
| mermaid | skill | proven-active + structural-necessity | CLAUDE.md default diagram skill (line 107); absorbed excalidraw 2026-03 (session-log.md:148); diagram tiers pattern in memory | keep | joint (B5; AS M6 gate) | — |
| peer-review | skill | proven-active | dispatched 2026-06-10 ×2 (spec + action-plan reviews, VO run-log); 47 commits; peer-review-config.md roster | keep; merge target for critic + writing-coach | joint (B5; AS M6 gate) | — |
| researcher | skill | proven-active (dormant ~3mo) | 6-stage dispatches w/ ledgers+confidence: session-log.md:289 (0.91), :364 (0.88), security-KB batch 6 :414; 26 commits latest 2026-03-20 | keep (KB production pipeline) | joint (B5; AS M6 gate) | — |
| startup | skill | structural-necessity | SessionStart hook (`session-startup.sh` in settings.json) + `/startup` display contract (CLAUDE.md line 202); db 3 sessions latest 2026-06-10 | keep | joint (B5; AS M6 gate) | — |
| sync | skill | proven-active + structural-necessity | CLAUDE.md Phase-1 delegation list (line 106) + session-end sequence consumer; 50 commits latest 2026-06-10 | keep | joint (B5; AS M6 gate) | — |
| systems-analyst | skill | proven-active | VO SPECIFY 2026-06-10 (run-log); CLAUDE.md skill_origin convention (line 186) + overlay-check role; preflight-map entry; 12 commits latest 2026-06-01 | keep; merge target for learning-plan (#11) | joint (B5; AS M6 gate) | — |
| vault-query | skill | structural-necessity (partial supersession) | absorbed obsidian-cli CLI patterns 2026-03 (session-log.md:148); CLAUDE.md File Access still cites "obsidian-cli skill" (stale name — B6 fix); Tess-dispatch half dark since agentic-sunset; 3 commits | pending — split evidence: CLI-patterns keep vs dispatch-surface superseded; AS-028 coordination | joint (B5; AS M6 + AS-028) | — |
| writing-coach | skill | proven-active (light) | required_context linkage session-log-2026-02.md:128; skill reformat :306; 4 commits latest 2026-04-21; deferred merge →peer-review on record (session-log.md:157) | prop: merge-into:peer-review | joint (B5; AS M6 gate) | — |

## Agents (4) — disposition follows parent skill (D1)

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| code-review-dispatch | agent | proven-active | parent code-review (db 2026-04-24); spawned at milestone reviews per code-review-config.md | follows code-review (keep) | joint (B5; AS M6 gate) | — |
| deliberation-dispatch | agent | proven-active | parent deliberation (db 2026-04-17); dispatch mechanics per deliberation-config.md | follows deliberation (keep) | joint (B5; AS M6 gate) | — |
| peer-review-dispatch | agent | proven-active | spawned 2026-06-10 (action-plan review: 4/4 reviewers, ~60k tokens, clean single-pass — VO run-log) | follows peer-review (keep) | joint (B5; AS M6 gate) | — |
| test-runner | agent | contingency-keep | no parent skill — spawned by main session for repo-backed projects; only trace session-log-2026-02; no active repo_path project currently in IMPLEMENT | pending — keep while any repo_path project active; mission-control has repo | joint (B5; AS M6 gate) | — |

## Overlays (8)

Evidence pass VO-014, 2026-06-10. Activation traces via prose-name grep over
session-logs + run-logs (hyphenated grep under-matches); structural refs =
named in a kept skill's procedure. Index presence alone not counted (D1).

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| business-advisor | overlay | proven-active | "Business Advisor" activations in 6 log files | keep | VO (B4) | — |
| career-coach | overlay | proven-active + structural-necessity | 3 log files; named in attention-manager + learning-plan procedures | keep | VO (B4) | — |
| design-advisor | overlay | proven-active + structural-necessity | 4 log files; named in mermaid procedure (tier-3 diagram aesthetic); companion dataviz doc | keep | VO (B4) | — |
| financial-advisor | overlay | proven-active (light) | 1 log file activation; no structural skill refs | keep — personal-domain lens, low cost | VO (B4) | — |
| glean-prompt-engineer | overlay | proven-active (light) | 1 log file; career/Infoblox enterprise-search lens; no structural skill refs | keep — operator work surface; re-check at VO-023 | VO (B4) | — |
| life-coach | overlay | proven-active + structural-necessity | 2 log files; named in attention-manager + learning-plan procedures; companion personal-philosophy doc | keep | VO (B4) | — |
| network-skills | overlay | proven-active + structural-necessity | 4 log files; named in deck-intel + learning-plan procedures; companion sources catalog | keep | VO (B4) | — |
| web-design-preference | overlay | proven-active | 3 log files | keep | VO (B4) | — |

## Scripts (20) — `_system/scripts/`

Evidence pass VO-013, 2026-06-10. Structural reference counts as use (D1).
Commands in run-log: per-script grep over `~/Library/LaunchAgents/*.plist`,
`.claude/settings*.json`, sibling scripts; `git log -1` per file; log greps.
`launchctl list` confirms all 10 plists loaded (cloudflared PID 684, vault-web
PID 689 live).

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| backup-status.sh | script | proven-active + structural-necessity | com.tess.backup-status plist (loaded); writes `_system/logs/backup-status.json` (current) | keep | VO (B4) | — |
| batch-moc-placement.py | script | no-evidence | one-shot MOC migration tool; 0 structural refs, 0 log mentions; last commit 2026-03-06 | prop: delete | VO (B4) | approved+signed 2026-06-10 (operator, wholesale) |
| bridge-watcher.py | script | superseded | Tess-bridge watcher — bridge decommissioned (agentic-sunset); 0 live refs; last commit 2026-02-25; companion plist already retired into scripts dir | prop: delete (AS concurrence — sunset-tied) | VO (B4) | — |
| clear-claude-cache.sh | script | no-evidence | 0 structural refs, 0 log mentions; last commit 2026-02-20 | prop: delete | VO (B4) | approved+signed 2026-06-10 (operator, wholesale) |
| com.crumb.bridge-watcher.plist | script-dir artifact | superseded | retired plist file parked in scripts dir (not in LaunchAgents); producer bridge-watcher.py superseded | prop: delete with bridge-watcher.py | VO (B4) | — |
| dns-recon.sh | script | proven-active (structural) — reclassified at VO-019 (was no-evidence; A2) | `Projects/customer-intelligence/import-workflow.md` (phase ACT) invokes it at :126 and requires its output `dns-recon.md` at :115/:159/:205/:211 — VO-013 pass missed project-doc surfaces | **keep** (A2 re-review complete; prior wholesale delete sign-off superseded) | VO | operator keep-decision 2026-06-10 (A2 re-review) |
| drive-sync-computer-filter.txt | sync filter | structural-necessity | consumed by drive-sync.sh (grep hit); allowlist patterns for Drive sync | keep (follows drive-sync.sh) | VO (B4) | — |
| drive-sync.sh | script | proven-active + structural-necessity | com.crumb.drive-sync plist (loaded); secondary backup chain (D4 B0) | keep | VO (B4) | — |
| knowledge-retrieve.sh | script | structural-necessity | called by skill-preflight.sh (PreToolUse hook chain — CLAUDE.md knowledge-retrieval automation) | keep | VO (B4) | — |
| mirror-sync.sh | script | proven-active + structural-necessity | settings.json hook; mirror-sync.log entries today (2026-06-10 16:09) | keep | VO (B4) | — |
| openclaw-isolation-test.sh | script | superseded | openclaw test artifact; runtime decommissioned; 0 refs/mentions; last commit 2026-02-20 | prop: delete (AS concurrence — sunset-tied) | VO (B4) | — |
| session-startup.sh | script | structural-necessity | SessionStart hook in settings.json (ran this session); xrefs vault-check.sh | keep | VO (B4) | — |
| setup-crumb.sh | script | contingency-keep | machine-bootstrap/rebuild script (references vault-check.sh); no runtime refs; last commit 2026-03-26 | keep (disaster-recovery path) — verify at VO-023 | VO (B4) | — |
| skill-preflight.sh | script | structural-necessity | PreToolUse hook in settings.json; consumes skill-preflight-map.yaml; calls knowledge-retrieve.sh | keep | VO (B4) | — |
| system-stats.sh | script | proven-active + structural-necessity | com.crumb.system-stats plist (loaded); writes system-stats.json (dashboard ops feed) | keep | VO (B4) | — |
| tess-health-check.sh | script | superseded | Tess runtime health-checker; health-check.log shows dead-token errors through 2026-06-01, nothing since; no plist references it; 2026-06-09 touch was mechanical path-rewrite (tess-danny-migration P2) | prop: delete (AS concurrence — sunset-tied); health-check*.log → B2 dead-logs | VO (B4) | — |
| vault-backup.sh | script | proven-active + structural-necessity | com.tess.vault-backup plist (loaded); primary local backup chain, B0 verification target (D4) | keep | VO (B4) | — |
| vault-check.sh | script | structural-necessity | pre-commit hook (settings.local.json); xref'd by session-startup.sh + setup-crumb.sh; convergence grounding for vault work | keep | VO (B4) | — |
| vault-gc.sh | script | proven-active + structural-necessity | com.crumb.vault-gc plist (loaded); absorbed feed-inbox-ttl.sh (session-log.md:148) | keep | VO (B4) | — |
| vault-search.sh | script | superseded | built for tess-v2 Phase 4a semantic search (commit 2026-04-04); runtime decommissioned; no live consumers in .claude/, protocols, or dashboard API (grep swept); 2026-06-09 touch mechanical path-rewrite | prop: delete (AS concurrence — sunset-tied); qmd provides vault search | VO (B4) | — |

## Protocols (6) — `_system/docs/protocols/`

A protocol referenced only by decommissioned surfaces is superseded (D1).

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| bridge-dispatch-protocol | protocol | superseded | serves the Tess bridge (decommissioned, agentic-sunset); live refs are CLAUDE.md "Bridge Dispatch Stage Output" §(itself an AS-025 removal target), spec v2-4, architecture docs, orientation-map — all descriptive, no live consumer | prop: delete (AS-025 coordination — CLAUDE.md § removed first) | VO (B4) | — |
| dispatch-triage-protocol | protocol | superseded | referenced only by architecture/02-building-blocks.md + one session-log mention; dispatch surface (Tess) decommissioned; zero CLAUDE.md/skill/hook refs | prop: delete | VO (B4) | — |
| hallucination-detection-protocol | protocol | contingency-keep | referenced by spec v2-4 + architecture/02 + separate-version-history; CLAUDE.md Hallucination Detection § cites spec §4.8 (not this file directly); tiered checks still operative behavior | pending — merge-into:spec-§4.8 or keep; decide at VO-024 cluster mapping | VO (B4) | — |
| inline-attachment-protocol | protocol | structural-necessity | CLAUDE.md Behavioral Boundaries names it (autonomous behavior); consumed by mermaid SKILL.md, file-conventions, spec v2-4 | keep | VO (B4) | — |
| research-brief-review-protocol | protocol | superseded | served Tess research-brief flow (decommissioned); zero live refs outside self + historical session-log + signal notes | prop: delete (AS concurrence — sunset-tied) | VO (B4) | — |
| session-end-protocol | protocol | structural-necessity | CLAUDE.md Session-End Sequence loads it (REQUIRED, autonomous); executed every session incl. today | keep | VO (B4) | — |

## Live plists (10) — `~/Library/LaunchAgents/`

Dashboard stack (cloudflared, dashboard, vault-web) is operator-kept per
assumption A3 / ADR Acceptance Refresh — new decision required to touch.

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| com.crumb.cloudflared | plist | structural-necessity | loaded, PID 684 live; tunnel for dashboard/vault-web remote access | keep — **operator-kept (A3)** | operator-kept (A3) | — |
| com.crumb.dashboard | plist | structural-necessity | loaded; runs `~/openclaw/crumb-dashboard` API server; knowledge-work viewing surface per ADR Acceptance Refresh | keep — **operator-kept (A3)**; panels face VO-002 rubric per ADR | operator-kept (A3) | — |
| com.crumb.vault-web | plist | structural-necessity | loaded, PID 689 live; serves quartz-vault static site | keep — **operator-kept (A3)** | operator-kept (A3) | — |
| com.crumb.drive-sync | plist | proven-active | loaded; runs drive-sync.sh (secondary backup) | keep | VO | — |
| com.crumb.qmd-index | plist | proven-active | loaded; runs `qmd update && qmd embed` (vault search index); consumer = interactive vault search | pending — verify consumer at VO-019/020; viewing-stack adjacency | VO | — |
| com.crumb.system-stats | plist | proven-active | loaded; feeds system-stats.json → dashboard ops panel | keep (follows dashboard A3) | VO | — |
| com.crumb.vault-gc | plist | proven-active | loaded; runs vault-gc.sh | keep | VO | — |
| com.crumb.vault-rebuild | plist | structural-necessity | loaded; runs `~/quartz-vault/rebuild.sh` — produces the site vault-web serves | pending — dashboard-stack adjacency: confirm A3 extension or separate decision | VO | — |
| com.tess.backup-status | plist | proven-active | loaded; runs backup-status.sh → backup-status.json | keep | VO | — |
| com.tess.vault-backup | plist | proven-active | loaded; runs vault-backup.sh (primary backup, B0 target) | keep | VO | — |

## Solutions (25) — `_system/docs/solutions/`

Evidence pass VO-015, 2026-06-10. Citation format: `refs=N` = count of vault
md files referencing the basename (grep, self/.git excluded); `last=` = last
commit touching the file. Solutions are compound-engineering outputs —
referenced solutions qualify as compound-provenance under the narrowed Tier 2
(ADR Acceptance Refresh). Cluster mapping + final dispositions at VO-024.

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| ai-telltale-anti-patterns | solution | proven-active | refs=8, last=2026-04-21; required_context in writing-coach (audience_external) | keep | VO (B3) | — |
| archive-conventions | solution | proven-active (light) | refs=3, last=2026-04-04 | keep | VO (B3) | — |
| atomic-rebuild-pattern | solution | proven-active | refs=7, last=2026-04-07 | keep | VO (B3) | — |
| behavior-vs-meaning-in-routine-design | solution | proven-active (light) | refs=3, last=2026-04-07 | keep | VO (B3) | — |
| behavioral-vs-automated-triggers | solution | proven-active + structural-necessity | refs=22; cited by CLAUDE.md (knowledge-retrieval automation §) | keep | VO (B3) | — |
| claude-print-automation-patterns | solution | proven-active | refs=36, last=2026-04-04; subject (--print automation) partly sunset-tied but harness knowledge durable | keep — re-check at VO-024 | VO (B3) | — |
| claude-print-cwd-sensitivity | solution | proven-active (light) | refs=2, last=2026-04-06; pairs with claude-print-automation-patterns | prop: merge-into:claude-print-automation-patterns | VO (B3) | — |
| code-review-patterns | solution | proven-active | refs=6, last=2026-04-04; code-review skill domain | keep | VO (B3) | — |
| egpu-local-compute-evaluation | solution | contingency-keep | refs=2, last=2026-04-16; one-time evaluation record (compound provenance) | pending — VO-024 | VO (B3) | — |
| foreign-tool-reveals-native-blind-spots | solution | proven-active (light) | refs=3, last=2026-04-20 | keep | VO (B3) | — |
| gate-evaluation-pattern | solution | proven-active | refs=22, last=2026-04-04 | keep | VO (B3) | — |
| haiku-soul-behavior-injection | solution | contingency-keep | refs=11 but subject = Tess soul doc (runtime decommissioned); compound provenance | pending — VO-024 (compound-provenance test) | VO (B3) | — |
| html-rendering-bookmark | solution | proven-active (light) | refs=5, last=2026-04-04 | keep | VO (B3) | — |
| infrastructure-teardown-discipline | solution | proven-active | refs=14, last=2026-06-01; governs AS + VO execution right now | keep | VO (B3) | — |
| lenient-parsing-before-evaluation | solution | proven-active | refs=7, last=2026-06-10 | keep | VO (B3) | — |
| live-soak-beats-benchmark | solution | proven-active | refs=8, last=2026-06-10; cited in VO spec (soak design) | keep | VO (B3) | — |
| lucidchart-policy-compliance | solution | superseded | refs=3; lucidchart skill removed 2026-03 (session-log.md:148) — subject no longer exists | prop: delete | VO (B3) | — |
| memory-stratification-pattern | solution | proven-active (light) | refs=3, last=2026-04-04; memory architecture still operative | keep | VO (B3) | — |
| reasoning-token-budget | solution | proven-active | refs=6, last=2026-04-21 | keep | VO (B3) | — |
| security-verification-circularity | solution | proven-active | refs=6, last=2026-04-21 | keep | VO (B3) | — |
| staged-spike-with-bail | solution | proven-active | refs=12, last=2026-06-10 | keep | VO (B3) | — |
| validation-is-convention-source | solution | proven-active | refs=10, last=2026-04-04 | keep | VO (B3) | — |
| vendor-comparison-feature-inventory | solution | proven-active (light) | refs=3, last=2026-04-21 | keep | VO (B3) | — |
| write-only-from-ledger | solution | proven-active | refs=15, last=2026-04-04; subject (FIF ledger) sunset-tied but pattern generalized | keep — re-check at VO-024 | VO (B3) | — |
| write-read-path-verification | solution | proven-active | refs=11, last=2026-04-04 | keep | VO (B3) | — |

## Docs — constitutional / root surface

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| CLAUDE.md | constitutional doc | structural-necessity | loaded every session (harness contract); contains stale "obsidian-cli skill" ref (merged into vault-query 2026-03) — B6 fix list | keep (AS-025 rewrite, then B6 second pass) | AS first (AS-025), VO second pass (B6) | — |
| _system/directives/liberation-directive.md | directive | structural-necessity | CLAUDE.md Strategic Directive § loads it; refs survive AS rewrite (VO-010 analysis) | keep | VO (B3) | — |
| Projects/index.md | navigation | proven-active | project navigation MOC; maintained alongside project creation | keep | VO (B3) | — |
| _system/docs/overlays/overlay-index.md | overlay index | structural-necessity | loaded at session start (CLAUDE.md Overlay Routing §); consumed by systems-analyst + action-architect overlay checks | keep | VO (B4) | — |

## Docs (62) — `_system/docs/` root files

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| adr-cli-native-agent-architecture | doc | no-evidence | refs=0, last=2026-02-25; ADR for CLI-native agent (Tess-era); decision provenance only | prop: delete — superseded by v3 ADR; provenance lives in git | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| adr-crumb-v3-knowledge-store-identity | doc | proven-active + structural-necessity | accepted 2026-06-10 (VO-010); identity baseline for this project | keep | VO (B3) | — |
| agent-skills-best-practices | doc | proven-active (light) | refs=3, last=2026-03-01; feeds skill-authoring | prop: merge-into:skill-authoring-conventions — VO-024 | VO (B3) | — |
| anthropic-consolidation-hypothesis | doc | proven-active (light) | refs=4, last=2026-04-21; analysis note | pending — VO-024 | VO (B3) | — |
| capture-tiers | doc | proven-active | refs=4, last=2026-04-24; intake tier definitions | keep | VO (B3) | — |
| change-spec-skill-model-routing | doc | superseded | refs=1, last=2026-02-25; executed change-spec — model routing now lives in CLAUDE.md | prop: delete (provenance in git) | VO (B3) | — |
| claude-ai-context | doc | proven-active | refs=23, last=2026-06-10 | keep | VO (B3) | — |
| claude-ai-session-prompt | doc | proven-active (light) | refs=2, last=2026-02-20; pairs with claude-ai-context | prop: merge-into:claude-ai-context — VO-024 | VO (B3) | — |
| claude-code-ssh-setup | doc | proven-active | refs=5, last=2026-06-09; ops runbook | keep | VO (B3) | — |
| code-review-config | doc | structural-necessity | refs=12; consumed by code-review skill (panel roster, dispatch config) | keep | VO (B3) | — |
| code-setup-prerequisites | doc | no-evidence | refs=0, last=2026-02-26 | prop: delete | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| compound-enhancements-spec | doc | superseded | refs=1 (its own summary), last=2026-04-04; executed spec — enhancements shipped | prop: delete (provenance in git) | VO (B3) | — |
| compound-enhancements-spec-summary | doc | superseded | refs=0; summary of executed spec | prop: delete with parent | VO (B3) | — |
| context-checkpoint-protocol | doc | structural-necessity | refs=15; CLAUDE.md Phase Transition Gate loads it (REQUIRED); executed twice 2026-06-10 | keep — B6 ceremony-diff target | VO (B3/B6) | — |
| convergence-rubrics | doc | structural-necessity | refs=9; CLAUDE.md Convergence § + Subagent Validation § consume it | keep | VO (B3) | — |
| cross-project-deps | doc | structural-necessity | refs=19, last=2026-06-10; XD gate registry (XD-027 governs this project) | keep | VO (B3) | — |
| crumb-design-spec-v2-4 | doc | structural-necessity | refs=16; CLAUDE.md cites §§ throughout (2.1, 3.5, 4.4, 4.6, 4.8, 6, 7.9) | keep | VO (B3) | — |
| crumb-studio-migration | doc | proven-active | refs=12, last=2026-06-09 | keep | VO (B3) | — |
| crumb-v2-system-health-assessment | doc | structural-necessity | refs=10; CLAUDE.md Ceremony Budget Principle cites it as provenance | keep | VO (B3) | — |
| cybersecurity-kb-capture | doc | proven-active (light) | refs=3, last=2026-03-06; KB capture conventions | pending — VO-024 (merge candidate w/ security-kb-plan) | VO (B3) | — |
| deliberation-config | doc | structural-necessity | refs=7; consumed by deliberation skill + dispatch agent | keep | VO (B3) | — |
| design-advisor-dataviz | doc | structural-necessity | refs=9; Design Advisor overlay companion (overlay-index row) | keep | VO (B3) | — |
| estimation-calibration | doc | proven-active | refs=23, last=2026-06-10 (VO calibration row added at TASK) | keep | VO (B3) | — |
| failure-log | doc | structural-necessity | refs=25; session-end protocol step 2 writes it; audit reads trends | keep | VO (B3) | — |
| feed-intel-processing-chain | doc | superseded | refs=7, last=2026-03-14; documents FIF runtime (decommissioned 2026-05-28) | prop: delete (AS concurrence — sunset-tied) | VO (B3) | — |
| feed-intel-processing-chain-diagram | doc | superseded | refs=3; diagram of decommissioned chain | prop: delete with parent | VO (B3) | — |
| feed-pipeline-calibration.jsonl | data file | superseded → **sunset-tied (VO-019 annotation)** | refs=3, last=2026-03-29; FIF runtime gone BUT kept feed-pipeline skill still appends (SKILL.md:450) + run-feed-pipeline.md:78,91 references — live write path | prop: delete **pending AS-028 feed-pipeline decision** (or strip skill calibration step first — VO-024 pack) | VO (B3; AS-028 gate) | — |
| file-conventions | doc | structural-necessity | refs=89 (highest in vault); CLAUDE.md Context Rules mandates it | keep | VO (B3) | — |
| goal-tracker.yaml | data file | structural-necessity | refs=81; critical_input for attention-manager (preflight DENY if missing) | keep | VO (B3) | — |
| kb-to-topic.yaml | data file | structural-necessity | refs=22; KB tag→MOC routing consumed at knowledge intake | keep | VO (B3) | — |
| liberation-surfaces-snapshot | doc | proven-active (light) | refs=3, last=2026-04-21; companion to liberation-directive | pending — VO-024 (staleness vs directive) | VO (B3) | — |
| mirror-config.yaml | data file | structural-necessity | consumed by mirror-sync.sh (hook chain, ran today) | keep | VO (B3) | — |
| network-kb-plan | doc | proven-active (light) | refs=1, last=2026-03-06; KB build plan (batches status inside) | pending — VO-024 (completed-plan test) | VO (B3) | — |
| network-skills-sources | doc | structural-necessity | refs=8; Network Skills overlay companion (overlay-index row) | keep | VO (B3) | — |
| openclaw-colocation-spec | doc | superseded | refs=18 (mostly historical), last=2026-02-26; openclaw runtime decommissioned | prop: delete (AS concurrence — sunset-tied) | VO (B3) | — |
| openclaw-colocation-spec-summary | doc | superseded | refs=6; summary of above | prop: delete with parent | VO (B3) | — |
| openclaw-crumb-reference | doc | superseded | refs=13 (historical), last=2026-02-23; documents decommissioned integration | prop: delete (AS concurrence; AS-029 memory rewrite may need it first — hand off) | VO (B3) | — |
| openclaw-memory-research | doc | superseded | refs=1, last=2026-02-27 | prop: delete (AS concurrence) | VO (B3) | — |
| openclaw-skill-integration | doc | superseded | refs=5, last=2026-02-22 | prop: delete (AS concurrence) | VO (B3) | — |
| peer-review-config | doc | structural-necessity | refs=36, last=2026-06-10 (Grok watch tally updated today); peer-review skill roster | keep | VO (B3) | — |
| peer-review-skill-spec | doc | superseded | refs=8, last=2026-02-20; executed spec — skill shipped 2026-02 | prop: delete (provenance in git) | VO (B3) | — |
| personal-context | doc | structural-necessity | refs=33; CLAUDE.md Overlay Routing § exempts it from budget = always-loadable operator context | keep | VO (B3) | — |
| proposal-pattern-enforcement-schema | doc | no-evidence | refs=1, last=2026-04-21; unexecuted schema proposal (matches operator feedback: don't pre-commit schema against unwritten paths) | prop: delete | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| review-safety-denylist | doc | structural-necessity | refs=13; peer-review/deliberation safety gate consumes it | keep | VO (B3) | — |
| security-kb-plan | doc | proven-active (light) | refs=1, last=2026-03-06; batches 1–5 done, batch 6 dispatched (session-log:428) | pending — VO-024 (completed-plan test) | VO (B3) | — |
| security-kb-sources | doc | proven-active (light) | refs=2; source catalog feeding security KB | keep — KB-adjacent reference | VO (B3) | — |
| separate-version-history | doc | proven-active | refs=14, last=2026-03-06; version-history policy | keep | VO (B3) | — |
| separate-version-history-archive | doc | contingency-keep | refs=2; archive companion | pending — VO-024 | VO (B3) | — |
| signals-archive-2026.jsonl | data file | contingency-keep | refs=2, last=2026-03-01; FIF signals archive data | pending — VO-022 storage policy (data, not surface) | VO (B3) | — |
| skill-authoring-conventions | doc | structural-necessity | refs=22; Primitive Creation Protocol consumes it | keep | VO (B3) | — |
| skill-preflight-map.yaml | data file | structural-necessity | consumed by skill-preflight.sh (PreToolUse hook, fires every skill call) | keep | VO (B3) | — |
| system-architecture-diagram | doc | proven-active (light) | refs=6, last=2026-03-14; predates sunset — content stale | pending — VO-024 (refresh-or-delete vs architecture/ cluster) | VO (B3) | — |
| tess-crumb-boundary-reference | doc | superseded | refs=11 (historical), last=2026-03-14; boundary with decommissioned runtime | prop: delete (AS concurrence; AS-029/030 may consume first) | VO (B3) | — |
| tess-crumb-comparison | doc | superseded | refs=11 (historical), last=2026-03-14 | prop: delete (AS concurrence) | VO (B3) | — |
| tess-v2-durable-patterns | doc | proven-active | refs=27, last=2026-06-09; the designated post-sunset knowledge carrier | keep | VO (B3) | — |
| vault-intake-map | doc | proven-active (light) | refs=3, last=2026-02-27 | pending — VO-024 (currency check vs capture-tiers) | VO (B3) | — |
| vault-intake-overview-diagram | doc | no-evidence | refs=0, last=2026-02-27 | prop: delete | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| vault-intake-overview-diagram.excalidraw | data file | no-evidence | refs=0 (only its own md wrapper); source file of above | prop: delete with wrapper | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| vault-restructure-analysis-20260220 | doc | contingency-keep | refs=5, last=2026-02-24; Feb restructure provenance — predecessor analysis to this project | pending — VO-024 (provenance test; VO spec may supersede) | VO (B3) | — |
| vault-restructure-discussion-20260220 | doc | contingency-keep | refs=5; discussion record for above | pending — VO-024 | VO (B3) | — |
| vault-startup-detection-diagram | doc | no-evidence | refs=0, last=2026-02-27 | prop: delete | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| www-design-taste-profile | doc | structural-necessity | refs=6; Web Design Preference overlay companion (taste profile) | keep | VO (B3) | — |

## Docs — `_system/docs/skill-workflows/` (15, per-file: dispositions will differ)

**Layer finding (VO-015):** zero consumers anywhere — not CLAUDE.md, not
skills/agents, not operator docs, not orientation-map, not dashboard. Created
2026-03-12 as a documentation layer; never wired into any routing. The layer is
an orphan as a whole; per-file rubrics below reflect subject status too.

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| skill-workflows/attention-manager | workflow doc | no-evidence | refs=0, last=2026-03-12 | prop: delete (layer orphan) | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| skill-workflows/code-review | workflow doc | no-evidence | refs=0, last=2026-03-12 | prop: delete (layer orphan) | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| skill-workflows/crumb-tess-bridge | workflow doc | superseded | refs=2 (historical), last=2026-04-24; bridge decommissioned | prop: delete | VO (B3) | — |
| skill-workflows/diagramming | workflow doc | no-evidence | refs=0, last=2026-03-12 | prop: delete (layer orphan) | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| skill-workflows/fif-triage-and-signals | workflow doc | superseded | refs=1, last=2026-03-12; FIF decommissioned | prop: delete | VO (B3) | — |
| skill-workflows/inbox-processing-ops | workflow doc | no-evidence | refs=0, last=2026-03-12 | prop: delete (layer orphan) | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| skill-workflows/intake-processing | workflow doc | no-evidence | refs=0, last=2026-03-12 | prop: delete (layer orphan) | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| skill-workflows/learning-plan | workflow doc | no-evidence | refs=0, last=2026-03-12 | prop: delete (layer orphan) | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| skill-workflows/overlays | workflow doc | no-evidence | refs=0, last=2026-03-12 | prop: delete (layer orphan) | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| skill-workflows/project-specification | workflow doc | no-evidence | refs=0, last=2026-03-12 | prop: delete (layer orphan) | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| skill-workflows/research-pipeline | workflow doc | no-evidence | refs=0, last=2026-04-21 | prop: delete (layer orphan) | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| skill-workflows/session-lifecycle | workflow doc | no-evidence | refs=0, last=2026-03-12 | prop: delete (layer orphan) | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| skill-workflows/tess-operations | workflow doc | superseded | refs=0, last=2026-03-12; Tess runtime decommissioned | prop: delete | VO (B3) | — |
| skill-workflows/vault-access | workflow doc | no-evidence | refs=0, last=2026-03-12 | prop: delete (layer orphan) | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |
| skill-workflows/vault-gardening | workflow doc | no-evidence | refs=0, last=2026-03-12; NB: operator/how-to/vault-gardening.md duplicates topic | prop: delete (layer orphan) | VO (B3) | approved+signed 2026-06-10 (operator, wholesale) |

## Docs — subdirectory clusters

Cluster rows: disposition applies to the whole cluster; if the evidence pass
finds split dispositions within a cluster, the row is exploded into per-file
rows at that point (manifest stays the single source of truth).

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| docs/architecture/ (6 files, arc42) | doc cluster | proven-active | last=2026-06-09 (maintained); 02-building-blocks referenced by multiple docs; content includes sunset-era components → refresh list at VO-024 | keep (content refresh at B3) | VO (B3) | — |
| docs/attachments/ (2 files) | doc cluster | superseded | tess-crumb-architecture.md+png; subject decommissioned; last=2026-03-14 | prop: delete (AS concurrence) | VO (B3) | — |
| docs/llm-orientation/orientation-map.md (1 file) | doc | proven-active | referenced by file-conventions, architecture/05, operator how-to + 2 reference docs | keep | VO (B3) | — |
| docs/operator/explanation/ (4 files) | doc cluster | proven-active | last=2026-04-11; operator-facing Diátaxis layer; why-two-agents.md sunset-stale → VO-024 refresh list | keep (content refresh at B3) | VO (B3) | — |
| docs/operator/how-to/ (10 files) | doc cluster | proven-active | last=2026-06-09 (maintained); incl. deployment runbook, vault-gardening | keep (sunset-stale entries → VO-024: run-feed-pipeline, tess-to-danny runbook) | VO (B3) | — |
| docs/operator/tutorials/ (3 files) | doc cluster | proven-active (split) | last=2026-04-11; first-crumb-session current; first-tess-interaction + mission-control-orientation partially sunset-stale | keep w/ VO-024 per-file split | VO (B3) | — |
| docs/operator/reference/ (8 files) | doc cluster | proven-active | last=2026-06-01; skills/overlays/infrastructure/tag-taxonomy references | keep (refresh after B5 description rewrites — VO-009 adjacency) | VO (B3) | — |
| docs/templates/notebooklm/ (12 files) | template cluster | structural-necessity | consumed by inbox-processor NotebookLM-export routing (sentinel contract + digest templates) | keep | VO (B3) | — |

## `_system/` — other clusters

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| _system/archive/launchagents-retired/ (14 files) | archive cluster | contingency-keep | AS teardown artifact — retired plists parked here (last=2026-06-10, active AS surface) | pending — AS owns until M7; then B2 candidate per storage policy | AS, then VO (B2) | — |
| _system/daily/ (92 files) | daily-notes cluster | proven-active | attention-manager output; written today (2026-06-10) | keep producer; rotation/retention policy at VO-022 | VO (B2 retention) | — |
| _system/perplexity/ (3 files) | task-prompt cluster | superseded | openclaw-era task prompts (morning briefing, calibration); runtime decommissioned; last=2026-04-06 | prop: delete (AS concurrence) | VO (B3) | — |
| _system/reviews/ (67 files) | review-artifact cluster | proven-active | peer-review/deliberation output archive; written 2026-06-09; review notes are provenance for applied amendments | keep; retention policy at VO-022 | VO (B2 retention) | — |
| _system/schemas/a2a/ + briefs/ + capabilities/ (7 files) | schema cluster | superseded | Tess dispatch schemas (a2a envelopes, brief schemas, capability manifest); dispatch surface decommissioned; last=2026-03-22 | prop: delete (AS concurrence — vault-query brief schema rides with vault-query decision) | VO (B3) | — |
| _system/schemas/deliberation/ (1 file) | schema | structural-necessity | assessment-schema.yaml consumed by deliberation skill dispatch | keep | VO (B3) | — |

## Project records (12) — `Projects/`

Project records are provenance — directory location is authoritative for
status (CLAUDE.md); archival is operator-initiated only, so no delete
dispositions here. Rubric reflects activity evidence.

| item | type | rubric | evidence | disposition | owner | operator-review |
|---|---|---|---|---|---|---|
| agentic-sunset | project record | proven-active | phase IMPLEMENT, last=2026-06-10; XD-027 counterpart | keep | AS (active) | — |
| customer-intelligence | project record | proven-active | phase ACT, last=2026-06-01 | keep | VO (B3) | — |
| feed-intel-framework | project record | contingency-keep | phase DONE, last=2026-06-09; runtime decommissioned — record is provenance; 4 run-log files incl. phase1 | keep record in place; formal archival deferred (operator 2026-06-10 — "for now"); run-log consolidation at VO-022 | VO (B3) | — |
| firekeeper-books | project record | proven-active (dormant 2mo) | phase ACT, last=2026-04-07 | keep | VO (B3) | — |
| mission-control | project record | proven-active | phase TASK, last=2026-06-09; repo_path project; dashboard stack = its deliverable (A3-kept) | keep | VO (B3) | — |
| obsidian-applenotes-import | project record | proven-active | phase PLAN, last=2026-06-10 (today) | keep | VO (B3) | — |
| opportunity-scout | project record | proven-active | phase TASK, last=2026-06-09 | keep | VO (B3) | — |
| semuta | project record | proven-active (dormant ~7wk) | phase PLAN, last=2026-04-20 | keep | VO (B3) | — |
| tess-danny-migration | project record | proven-active (status unclear) | phase TASK, last=2026-06-09 (P2 path-rewrite commit); purpose intersects sunset — AS coordination on whether project continues | keep; status question → AS run-log handoff | VO (B3) | — |
| tess-v2 | project record | contingency-keep | phase IMPLEMENT but closures ride AS-030 (VAL-001/002/003 superseded at VO-010) | keep; AS-030 owns closure | AS (AS-030 closures) | — |
| think-different | project record | structural-necessity (archival policy) | phase ARCHIVED in Projects/ — KB exception per CLAUDE.md (standalone KB artifacts stay) | keep | VO (B3) | — |
| vault-optimization | project record | proven-active | this project | keep | VO (this project) | — |

## Appendix A — joint-surface ownership matrix (VO-016; NOT YET FROZEN)

Schema per design D1. To be completed + frozen at VO-016 with AS concurrence
recorded in both run-logs.

| Surface | Proposed owner | Gate | Status |
|---|---|---|---|
| CLAUDE.md | AS (AS-025 first), VO-007 second pass | AS-025 complete | draft |
| `.claude/skills`, `.claude/agents` | joint — AS-028 removes sunset-tied, VO-005 optimizes remainder | AS M6 sign-off | draft |
| Harness memory (`~/.claude/.../memory/`) | AS (AS-029) | analysis-only for VO | draft |
| `_openclaw/`, `_tess/`, `_staging/` | AS (AS-026/027) | VO never touches | draft |
| `_system/scripts/`, protocols, overlays | VO | Appendix A frozen | draft |
| `_system/docs/` + solutions | VO (VO-006) | — | draft |
| `Archived/`, `_attachments/` | VO (VO-004/008) | backup gate | draft |
| Live plists (10 incl. dashboard stack) | dashboard stack: operator-kept (A3); rest: per manifest | new decision required to touch dashboard stack | draft |
