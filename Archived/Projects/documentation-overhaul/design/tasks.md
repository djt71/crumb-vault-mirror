---
type: tasks
project: documentation-overhaul
domain: software
status: active
created: 2026-03-14
updated: 2026-03-14
skill_origin: action-architect
tags:
  - system/docs
  - system/architecture
topics:
  - moc-crumb-architecture
---

# Tasks — Documentation Overhaul

## M1: Infrastructure Prerequisites

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| DOH-001 | Update `file-conventions.md` and `vault-check.sh` to accept tags: `system/architecture`, `system/operator`, `system/llm-orientation` | done | — | low | software | Tags accepted by vault-check; pre-commit hook passes for a test file using new tags. Note: vault-check only validates `#kb/` tags — new `system/*` tags pass without vault-check.sh changes. Added System Documentation Tags section to file-conventions.md. |
| DOH-002 | Create directory structure: `_system/docs/architecture/`, `_system/docs/operator/{tutorials,how-to,reference,explanation}/`, `_system/docs/llm-orientation/` | done | — | low | software | All directories exist; `ls` confirms structure matches spec vault placement tree |

## M2: Architecture Foundation

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| DOH-003 | Create `00-architecture-overview.md` stub with frontmatter and placeholder links | done | DOH-001, DOH-002 | low | software | File exists with valid frontmatter using `system/architecture` tag; vault-check passes |
| DOH-004 | Draft `01-context-and-scope.md`: system purpose, context diagram (Mermaid + prose), actor definitions, system boundary, constraints | done | DOH-003 | medium | software | Doc has ≥1 Mermaid diagram with prose summary; scope statement present; source attribution present; vault-check passes |
| DOH-005 | Absorb-and-redirect: `system-architecture-diagram.md`, `attachments/tess-crumb-architecture.md`, actor defs from `tess-crumb-comparison.md` into 01 | done | DOH-004 | low | software | Original docs replaced with wikilink stubs; stubs have `status: archived`; content appears in 01. Note: `tess-crumb-comparison.md` is a partial absorb — ownership goes to DOH-007, personality to DOH-024. Original not retired until DOH-024 completes the final piece |
| DOH-006 | Draft `02-building-blocks.md`: L1/L2 decomposition, ownership map, dependency diagram (Mermaid + prose), code mapping | done | DOH-005 | medium | software | Doc has ownership table and dependency diagram with prose summary; scope statement present; vault-check passes |
| DOH-007 | Absorb-and-redirect: `tess-crumb-boundary-reference.md`, ownership content from `tess-crumb-comparison.md` into 02 | done | DOH-006 | low | software | `tess-crumb-boundary-reference.md` replaced with stub. `tess-crumb-comparison.md` partial absorb — ownership/routing content appears in 02. Original not retired until DOH-024 completes the final piece |
| DOH-008 | Draft `04-deployment.md`: host, process model, network topology, storage, credentials, DNS, deployment diagram (Mermaid + prose) | done | DOH-007 | medium | software | Doc has deployment diagram with prose summary; all infrastructure components listed; vault-check passes |
| DOH-009 | Draft `03-runtime-views.md`: 6 sequence diagrams (Mermaid + prose) for session lifecycle, Tess dispatch, feed pipeline, Mission Control, bridge handoff, AKM surfacing | done | DOH-008 | medium | software | All 6 named runtime flows documented with sequence diagrams and prose summaries; happy path and failure handling noted per flow; vault-check passes |
| DOH-010 | Absorb-and-redirect: `feed-intel-processing-chain.md` + `feed-intel-processing-chain-diagram.md` into 03 | done | DOH-009 | low | software | Original docs replaced with stubs; pipeline flow content appears in 03 |
| DOH-011 | Draft `05-cross-cutting-concepts.md`: vault-check rules, tag taxonomy in practice, token budgets, naming conventions, code review tiers, git patterns | done | DOH-010 | medium | software | Doc covers observable conventions not restated principles; source material cites specific files; vault-check passes |
| DOH-012 | Complete `00-architecture-overview.md`: linked TOC for 01-05, terminology index, pointers to design spec and version history | done | DOH-011 | low | software | Overview links to all 5 sections; terminology index covers AKM, QMD, FIF, MOC, HITL, OpenClaw; no duplicated section content |

## M3: Operator Documentation

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| DOH-013 | Migrate 6 "keep as-is" docs: move to operator directories, retag, check Diátaxis compliance. Files: deployment runbook, vault-gardening, git-commands, tailscale-setup, tmux-commands, updates-to-archived-project | done | DOH-001, DOH-002 | low | software | All 6 files in new locations; old locations empty; tags include `system/operator`; each fits one Diátaxis quadrant; vault-check passes (0 new errors — 12 pre-existing errors in unrelated Sources/research/ files). Ops/ retains only `notebooklm-digest-import-process.md` (DOH-029). Hardcoded path in 04-deployment.md updated. Conversational leftover removed from updates-to-an-archived-project.md. |
| DOH-013b | Expand deployment runbook to cover OpenClaw upgrade procedures (absorbs `deploy-openclaw-update.md` scope per spec reconciliation) | done | DOH-013 | medium | software | Deployment runbook in `operator/how-to/` covers OpenClaw upgrade scope; problem statement at top; done criteria at bottom; vault-check passes. Added: impact analysis table, pre-upgrade checklist, 7-step upgrade procedure, rollback, credential rotation, macOS gotchas (provenance xattr, launchd domain mismatch, HOME not reset by sudo). Scope line updated from "Crumb only" to include OpenClaw. |
| DOH-014 | Draft `reference/skills-reference.md`: scan all SKILL.md files, build structured index | done | DOH-012, DOH-013 | low | software | 22 skills indexed with name, purpose, trigger, model tier, inputs/outputs. Additional sections: model routing, workflow alignment, overlay integration, composable skills, dispatch capabilities, required context. Reconciled against `.claude/skills/` scan (22/22 match). |
| DOH-015 | Draft `reference/vault-structure-reference.md`: directory tree, path conventions, vault-check rules | done | DOH-012, DOH-013 | low | software | Full directory tree with ownership map. Path conventions (file naming, binary naming, wikilinks). Frontmatter requirements (project vs non-project). Tag taxonomy (18 canonical L2, L3 rules). Type taxonomy (key types table). vault-check 30-rule summary table with categories and levels. |
| DOH-016 | Draft `reference/infrastructure-reference.md`: hostnames, ports, tunnel config, daemon names, health-check URLs, DNS | done | DOH-012, DOH-013 | low | software | Structured tables throughout (not prose). 10-service inventory with health checks. Network (3 ports, DNS, outbound endpoints). 11-credential map with storage and rotation. Health check commands (do/don't). 9 log locations. 9 macOS platform constraints. Reconciled against 04-deployment and MEMORY.md. Uncertainty flagged for Ollama model list. |
| DOH-017 | Draft `how-to/run-feed-pipeline.md`: trigger, monitor, handle failures | done | DOH-012 | low | software | Problem statement at top; done criteria at bottom. Covers: trigger phrases, 4-step processing (dashboard promotions → scan/classify → tier 2 actions → tier 1 permanence eval), 7 health signals, 6 failure scenarios with recovery. Diátaxis how-to compliant. |
| DOH-018 | Draft `how-to/triage-feed-content.md`: Mission Control triage interface, post states, batch ops | done | DOH-012 | low | software | Problem statement at top; done criteria at bottom. Covers: dashboard access, KPI strip, signal cards, 3 triage actions (skip/delete/promote), tag override, post-triage flow, batch ops, 5 problem scenarios. Diátaxis how-to compliant. |
| DOH-019 | Draft `reference/sqlite-schema-reference.md`: all SQLite tables with schema, ownership, join patterns | done | DOH-012 | low | software | 2 databases documented. pipeline.db: 9 tables with full column schemas, indexes, row counts, retention policy. attention-replay.db: 4 tables. Ownership boundary table (FIF vs dashboard access). Join contract documented. WAL mode noted. |
| DOH-020 | Draft `tutorials/mission-control-orientation.md`: dashboard walkthrough, views, triage mechanics | done | DOH-012 | low | software | 6 sequential steps with expected outcomes. Covers: dashboard access, KPI strip, signal cards, triage actions, pipeline health, verification of promotions. |
| DOH-021 | Draft `tutorials/first-crumb-session.md`: vault state, CLAUDE.md, AKM, skill activation, run-log | done | DOH-012 | low | software | 8 sequential steps with expected outcomes. Covers: SSH → tmux → Claude Code → startup → CLAUDE.md → task → AKM → session end → detach. |
| DOH-022 | Draft `tutorials/first-tess-interaction.md`: Telegram interface, voice/mechanic split, escalation | done | DOH-012 | low | software | 6 sequential steps with expected outcomes. Covers: Telegram access, Voice vs Mechanic, capability boundaries, bridge escalation, automated messages, commands. |
| DOH-023 | Draft `explanation/how-crumb-thinks.md`: spec-first, compound engineering, ceremony budget | done | DOH-012 | low | software | Narrative prose, no procedural steps. Covers: spec-first, phase gates, compound engineering, ceremony budget, mechanical enforcement, vault as source of truth. |
| DOH-024 | Draft `explanation/why-two-agents.md`: Tess/Crumb split rationale (absorb personality model from `tess-crumb-comparison.md`). This is the final absorb — retire the original with stub-and-archive after DOH-005 (actors→01) and DOH-007 (ownership→02) completed their partial absorbs | done | DOH-012 | low | software | Narrative prose. Personality model fully absorbed (Tess Servopoulos + Gurney Halleck sources, Crumb no-persona rationale, voice contrast). `tess-crumb-comparison.md` replaced with wikilink stub pointing to 01, 02, and why-two-agents. Status set to archived. All three absorbs complete. |
| DOH-025 | Draft `explanation/the-vault-as-memory.md`: why Obsidian, AKM/QMD, limitations | done | DOH-012 | low | software | Narrative prose. Covers: why Obsidian, knowledge entry pipelines, three-layer structure (notes/MOCs/domains), AKM triggers and retrieval, compound engineering as amplifier, 5 limitations. |
| DOH-026 | Draft `explanation/feed-pipeline-philosophy.md`: content intelligence rationale, promote/skip/delete model | done | DOH-012 | low | software | Narrative prose. Covers: promote/skip/delete model, tier system rationale, permanence evaluation, circuit breaker, connection to attention management, why not full automation. |
| DOH-027 | Draft `how-to/update-a-skill.md`: edit SKILL.md, vault-check, commit, verify AKM | done | DOH-012 | low | software | Problem statement at top; done criteria at bottom. 5-step procedure: read → edit → vault-check → verify AKM → log. Peer review guidance for substantial changes. |
| DOH-028 | Draft `how-to/rotate-credentials.md`: SecretRef locations, rotation procedure, validation | done | DOH-012 | low | software | Problem statement at top; done criteria at bottom. 11 credentials mapped with storage, path, consumers. Per-type rotation procedures (env file, Keychain, GitHub PAT, OpenClaw, Telegram, TMDB). Validation checklist. |
| DOH-029 | Draft `how-to/add-knowledge-to-vault.md`: NLM pipeline, manual creation, tagging (absorb `notebooklm-digest-import-process.md`) | done | DOH-012 | low | software | Problem statement at top; done criteria at bottom. 3 methods: NLM pipeline (4 steps), manual creation (4 steps), feed pipeline promotion. NLM content absorbed. `notebooklm-digest-import-process.md` stub-and-archived. Tagging rules section. |
| DOH-030 | Draft `reference/tag-taxonomy-reference.md`: complete hierarchy, L2 canonical, L3 subtags, rules | done | DOH-012 | low | software | 18 canonical L2 tags in structured table with domain and examples. L3 open subtag examples. Subordination rule documented. System tags table. Enforcement rules. Four sync points documented. Tag-to-MOC mapping reference. |
| DOH-031 | Draft `reference/overlays-reference.md`: all overlays with activation signals, lens questions, budget | done | DOH-012 | low | software | 8 overlays indexed with activation signals, all lens questions listed per overlay, 3 companion files documented. Skills with overlay checks table. Reconciled: 8 files on disk match 8 index entries. |

## M4: LLM Orientation Map

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| DOH-032 | Build `llm-orientation/orientation-map.md`: scan vault, list all LLM docs with location, budget, trigger, architecture source | done | DOH-012 | low | software | 53 LLM-consumed documents mapped across 7 categories. Each entry has location, est. tokens, load trigger, update trigger, architecture source. Token budget summary (94.5k total inventory, ~14-20k typical session). Reconciled: 22 skills match .claude/skills/ scan, 8 overlays match overlay-index.md. |
| DOH-033 | Gap analysis: identify subsystems in architecture docs without LLM orientation coverage | done | DOH-032 | low | software | 10 subsystems with full coverage documented. 6 gaps identified: 4 deferred (Mission Control, OpenClaw config, LaunchAgent mgmt, vault-check internals), 2 fill candidates (spec summary staleness check, hooks orientation doc). Recommendations included. |

## Cleanup

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| DOH-034 | Retire `_system/docs/Ops/` directory: verify all contents migrated (DOH-013 + DOH-029), remove empty directory | done | DOH-013, DOH-029 | low | software | `Ops/` directory removed. All 5 original files accounted for: 4 migrated to operator dirs (DOH-013), 1 absorbed into add-knowledge-to-vault.md (DOH-029). Archived stub removed via `git rm -f`. |
