---
type: specification
project: documentation-refresh-2026-04
domain: software
status: active
created: 2026-04-11
updated: 2026-04-11
skill_origin: systems-analyst
tags:
  - system/docs
  - system/architecture
topics:
  - moc-crumb-architecture
---

# Documentation Refresh 2026-04 — Specification

## Problem Statement

The three-track documentation set created by the archived `documentation-overhaul` project (2026-03-14) has drifted from current system state over four weeks of substantial change. Architecture docs, operator docs, and the LLM orientation map now misreport subsystem inventories, model routing, and active services — degrading their value as authoritative references and NotebookLM source material.

This is a content refresh within existing structure, not a redesign. File locations, conventions, and authority model from the overhaul remain authoritative.

## Why This Matters

The architecture docs are the *current-state authority* in the three-tier hierarchy (design spec → architecture → version history). When they drift, downstream operator docs, the LLM orientation map, and NotebookLM-synced notebooks all propagate the staleness. The orientation map's token budgets and document inventory are also used for session-planning calibration — stale counts produce bad context-budget decisions.

## Facts

- Archived project `documentation-overhaul` (2026-03-14) produced the canonical three-track structure: `_system/docs/architecture/` (Arc42, 6 files), `_system/docs/operator/` (Diátaxis, 4 quadrants), `_system/docs/llm-orientation/orientation-map.md`.
- Architecture docs were written 2026-03-14; only `01-context-and-scope.md` was updated since (2026-04-06 — Tailscale setup).
- Operator docs are overwhelmingly from 2026-03-14; only `skills-reference.md` (Apr 5) and `tag-taxonomy-reference.md` (Apr 7) have been updated.
- Orientation map was last updated 2026-03-14.
- Skill inventory: doc says **22**; actual is **20** (`ls .claude/skills/`).
  - Removed: `excalidraw`, `lucidchart`, `meme-creator`, `obsidian-cli`
  - Added: `critic`, `deliberation`
- Subagent inventory: doc says **3**; actual is **4**. Added: `deliberation-dispatch`.
- Overlays: 8 (matches doc).
- Model routing changed substantially:
  - Tess Voice: Haiku 4.5 → **Kimi K2.5** (cloud primary), **Qwen 3.6** failover (per 2026-03-30, 2026-04-03 evals)
  - Tess Mechanic: qwen3-coder:30b → **Nemotron** (per 2026-04-10 email triage migration commit)
  - Crumb session: Opus 4.6 1M context (explicit model policy, non-negotiable — see memory)
- Email triage service was shut down on 2026-04-10 — `TV2-036` and `TV2-037` cancelled, LaunchAgents unloaded. Architecture 04 process-model diagram and deployment process list still show it.
- Domains: `lifestyle` added as canonical 9th domain on 2026-04-06 (Q2 goals + philosophy shift commit).
- Tess-v2 project shipped major architectural work post-Mar-14: Phase 3 (state machine, escalation, prompt, failover, integration test), Phase 4 scaffold, Phase 4a vault semantic search, Amendment Z (interactive dispatch & orchestrator authority), Amendment AA, Phase A interactive dispatch core loop.
- New vault subsystem: Quartz v4 static site for iPhone vault access (2026-04-04 `vault-mobile-access` project).
- Compound-engineering subsystem was enhanced 2026-04-04: track schema, conditional review routing, cluster analysis.
- New solution patterns captured: atomic-rebuild, foreign-tool (2026-04-07).
- Mission Control shipped M3.1 Intelligence Feed Density Redesign (2026-03-30).
- Attention-manager wired plans into daily attention via inventory pattern (2026-04-07).
- New KB/lifestyle content landed: gardening, housework, home services (2026-04-07).
- Public mirror prep work landed 2026-04-10 — OAuth secret redaction, allowlist narrowing, session log.

## Assumptions (to validate during ACT)

- The archived project's three-track structure and file locations remain correct — no need to move files or redesign quadrants. _Validation: confirmed with user up front._
- No new architecture sections are needed; refresh fits within existing Arc42 sections 00–05. _Validation: gap-check during M2._
- Operator docs do not need new files — staleness is content-level, not coverage-level. _Validation: audit during M3._
- Orientation map structure (categories, columns) remains correct; only inventories and counts need updating. _Validation: M4._
- Tess-v2 Phase 4 and Amendment Z work is stable enough to document. _Validation: check `project-state.yaml` phase on docs day._

## Unknowns

- Whether the Tess-v2 interactive dispatch architecture has stabilized enough to be reflected in Runtime Views §2 (Tess dispatch) — may require checking active soak state before documenting.
- Whether the bridge-watcher service model has changed beyond kqueue detection (bridge PoC 2026-03-30).
- Exact current LaunchAgent/LaunchDaemon inventory — need live `launchctl list` to verify process model in 04-deployment.
- Whether the Crumb design spec itself needs updating (not in scope for this project — but if drift is discovered we flag for a follow-on).

## System Map

### Components (documents in scope)

**Architecture track (`_system/docs/architecture/`):**
- `00-architecture-overview.md` — terminology index, section nav
- `01-context-and-scope.md` — actors, external interfaces, model routing
- `02-building-blocks.md` — skill/overlay/subagent/script inventories
- `03-runtime-views.md` — session lifecycle, Tess dispatch, feed pipeline
- `04-deployment.md` — process model, LaunchAgents, services, model hosting
- `05-cross-cutting-concepts.md` — conventions, vault-check, context budgets

**Operator track (`_system/docs/operator/`):**
- `reference/` — 8 files (skills, overlays, vault-structure, sqlite-schema, infrastructure, tag-taxonomy, git-commands, tmux-commands)
- `how-to/` — 9 files (deployment, run-feed, triage, update-skill, rotate-credentials, vault-gardening, add-knowledge, tailscale-setup, updates-to-archived-project)
- `tutorials/` — 3 files (first-crumb-session, first-tess-interaction, mission-control-orientation)
- `explanation/` — 4 files (how-crumb-thinks, why-two-agents, vault-as-memory, feed-pipeline-philosophy)

**LLM orientation track:**
- `_system/docs/llm-orientation/orientation-map.md`

### Dependencies

- Authority flows downward: architecture refresh must complete before operator and orientation refreshes (orientation references architecture sources; operator docs should be consistent with current-state claims).
- Within architecture: 01 (actors/interfaces) → 02 (inventories) → 04 (deployment) → 03 (runtime views) → 05 (cross-cutting) → 00 (terminology). Same order as archived overhaul project.
- Vault-check tags: current frontmatter is compatible; no Phase 0 prerequisite needed this time.

### Constraints

- **Ceremony budget.** The refresh must not expand scope beyond content corrections — no new sections, no restructuring, no new files unless a gap is discovered that blocks accurate refresh.
- **NotebookLM primary consumer.** Updated docs must retain self-contained readability (no broken wikilinks, no assumed external context).
- **Frontmatter preservation.** Write tool loses frontmatter silently — use Edit for in-place updates on all existing files (see memory `vault-discipline.md`).
- **Authority model preserved.** No changes to the three-tier hierarchy (design spec → architecture → version history).
- **No redraft unless needed.** Prefer surgical edits over full rewrites. Full rewrite only if >40% of a doc is stale.

### Levers

- The orientation map has the highest ratio of machine-relevance to update cost — a single refresh corrects every future session's token budget calibration.
- `02-building-blocks.md` carries the most stale inventory signal — skill/subagent/overlay/script tables propagate into operator reference docs. Fix it first after 01.
- Cross-cutting concepts (05) may not need changes at all; check first before editing.

### Second-order Effects

- Updated architecture docs will trigger NotebookLM re-sync. Operator needs to push updated notebooks after ACT completes.
- `claude-ai-context.md` (stale — flagged at session start) should be updated as part of the session-end protocol after this refresh; it's a downstream consumer of architecture state.
- If the refresh uncovers design-spec drift, flag as a follow-on project (do not expand scope here).

## Domain Classification and Workflow Depth

- **Domain:** software
- **Type:** knowledge-work
- **Workflow:** SPECIFY → PLAN → ACT (three-phase)
- **Rationale:** No code produced. Inputs are existing docs + system state; outputs are updated docs. Same workflow depth as the archived overhaul project.

## Scope Boundaries (explicit)

**In scope:**
- Content refresh of all 6 architecture docs
- Content refresh of all 24 operator docs
- Content refresh of the orientation map
- Updated `updated:` frontmatter on every touched file
- Gap analysis entries for subsystems that should be documented but aren't (report only; fill is out of scope)

**Out of scope:**
- Creating new architecture sections or operator doc files
- Restructuring Diátaxis quadrants
- Updating the Crumb design spec (`crumb-design-spec-v2-4.md`)
- Updating NotebookLM notebooks themselves (operator action post-ACT)
- Updating `CLAUDE.md`, skill definitions, or overlays
- Updating `claude-ai-context.md` (handled by session-end protocol)

## Task Decomposition

35 tasks was overkill for a content refresh. Targeting ~12 tasks across 4 milestones, mapped to the archived project's milestone structure but much thinner.

### M1: Staleness Survey Closeout (1 task, ~0 sessions)

Survey is mostly complete from this spec's Facts section. Only item remaining before PLAN is validation of the Unknowns list.

- **DOC-001** (#research, low) — Validate unknowns: run `launchctl list | grep -E 'openclaw|crumb|tess'` for current service inventory, read tess-v2 `project-state.yaml` for phase stability, confirm bridge-watcher current state. Acceptance: unknowns resolved or demoted to explicit constraints.

### M2: Architecture Refresh (6 tasks, ~3 sessions)

Sequential per dependency order. Each task is a single doc edit.

- **DOC-002** (#writing, low) — Refresh `01-context-and-scope.md` model routing (Tess Voice: Kimi K2.5 / Qwen 3.6 failover; Tess Mechanic: Nemotron), add `lifestyle` domain, update any actor text. Acceptance: context diagram and actor text match current system; `updated:` bumped.
- **DOC-003** (#writing, medium) — Refresh `02-building-blocks.md` skill table (20 skills: −excalidraw, −lucidchart, −meme-creator, −obsidian-cli, +critic, +deliberation), subagent table (+deliberation-dispatch), overlay table (verify 8), script count. Acceptance: tables match filesystem `ls` output; mermaid block-beta counts updated.
- **DOC-004** (#writing, medium) — Refresh `04-deployment.md` process model diagram (remove email-triage from both domains; update ollama model name Nemotron; verify all other services against `launchctl list`). Add Quartz v4 static site if it runs as a service. Acceptance: process model matches live `launchctl list`; ollama model name correct.
- **DOC-005** (#writing, medium) — Refresh `03-runtime-views.md` — verify Tess dispatch diagram against current Amendment Z interactive-dispatch architecture; update feed pipeline if M3.1 Mission Control redesign affects it. Acceptance: sequence diagrams consistent with tess-v2 current state as of 2026-04-11.
- **DOC-006** (#writing, low) — Refresh `05-cross-cutting-concepts.md` — scan for stale conventions; add compound engineering enhancements (track schema, conditional review routing, cluster analysis); verify vault-check rule count. Acceptance: cross-cutting conventions match current CLAUDE.md and vault-check.sh.
- **DOC-007** (#writing, low) — Refresh `00-architecture-overview.md` terminology index — verify all defined terms still in use; update skill count (20); update overlay count if changed. Acceptance: overview and terminology index consistent with the five refreshed sections.

### M3: Operator Refresh (3 tasks, ~2 sessions)

Mostly content-refresh in place; high-trust staleness scan rather than full rewrite.

- **DOC-008** (#writing, low) — Refresh operator reference docs (8 files): `skills-reference` (verify Apr 5 version matches current 20-skill list), `overlays-reference`, `vault-structure-reference` (add Quartz/mobile-access + lifestyle domain), `sqlite-schema-reference`, `infrastructure-reference`, `tag-taxonomy-reference` (verify Apr 7 version), `git-commands`, `tmux-commands`. Surgical edits only. Acceptance: reference docs match current filesystem state; `updated:` bumped on touched files.
- **DOC-009** (#writing, medium) — Refresh operator how-to docs (9 files): key focus on `crumb-deployment-runbook` (email triage removal), `rotate-credentials` (OAuth secret redaction practice from public mirror prep), `run-feed-pipeline`, `triage-feed-content`, `update-a-skill`. Acceptance: runbooks reflect current services and credential practices.
- **DOC-010** (#writing, low) — Refresh operator tutorials and explanation docs (7 files): verify tutorials still work end-to-end (first-crumb-session, first-tess-interaction, mission-control-orientation); scan explanation docs for stale model references (Haiku → Kimi). Acceptance: tutorials would succeed for a new operator on 2026-04-11; explanations don't cite superseded models.

### M4: Orientation Map Refresh (1 task, ~0.5 session)

- **DOC-011** (#writing, low) — Refresh `orientation-map.md`: recount tokens for all 20 skills (drop removed, add critic + deliberation), add deliberation-dispatch subagent row, recount totals, update gap analysis if covered gaps have been filled since Mar 14. Acceptance: every table row maps to an existing file; totals arithmetic-correct.

### M5: Close-Out (1 task, ~0 sessions)

- **DOC-012** (#research, low) — Final consistency check: architecture, operator, and orientation map all cite same numbers (skill count, domain count, model routing). Update progress-log. Flag any discovered design-spec drift as follow-on work. Acceptance: cross-reference check passes; session-end protocol hands off cleanly to claude-ai-context update.

## Risk Profile

- **1 task medium risk:** DOC-003 (building blocks inventory — if wrong, propagates into DOC-008, DOC-011)
- **3 tasks medium risk:** DOC-004, DOC-005, DOC-009 (live-state-dependent; need to verify against `launchctl`, tess-v2 state, current credential practice)
- **8 tasks low risk**
- **Primary quality gate:** operator pass/fail review per doc (same as overhaul project), plus cross-reference arithmetic on DOC-012.

## Acceptance Criteria (project-level)

1. Every file in the three tracks has `updated: 2026-04-11` (or later) if content was changed, or explicit "verified still current" note in run-log if unchanged.
2. Skill/subagent/overlay/script counts in `02-building-blocks.md`, `skills-reference.md`, and `orientation-map.md` agree with filesystem state.
3. No doc cites Haiku 4.5 as Tess Voice or qwen3-coder as Tess Mechanic model.
4. `04-deployment.md` process model matches live `launchctl list` output.
5. No new architecture sections or operator files created (constraint honored).
6. Run-log entry per milestone transition; progress-log updated at ACT completion.

## Peer Review Classification

**MINOR.** Content refresh within existing structure, following an already peer-reviewed template. Skipping peer review is appropriate. If the refresh uncovers structural issues beyond content (e.g., a missing subsystem that needs a new section), that would be escalated to a fresh SPECIFY cycle rather than handled via peer review here.
