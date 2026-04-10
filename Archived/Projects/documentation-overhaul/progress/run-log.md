---
type: run-log
project: documentation-overhaul
status: active
created: 2026-03-14
updated: 2026-03-14
tags:
  - run-log
---

# Run Log — documentation-overhaul

## 2026-03-14 — Project creation + spec review

**Phase:** SPECIFY
**Session type:** Spec review and project scaffold

### Context inventory
- `_inbox/crumb-tess-documentation-overhaul.md` — draft spec from operator
- `_system/docs/system-architecture-diagram.md` — existing architecture diagram
- `_system/docs/tess-crumb-comparison.md` — existing Tess/Crumb role comparison
- `_system/docs/tess-crumb-boundary-reference.md` — existing agent boundary reference
- `_system/docs/crumb-deployment-runbook.md` — existing deployment runbook
- `_system/docs/vault-gardening.md` — existing vault gardening doc
- `_system/docs/Ops/` — 5 existing informal operator docs
- `_system/docs/attachments/tess-crumb-architecture.md` — architecture diagram companion

### Work done
- Reviewed draft spec (3 tracks: Arc42 architecture, Diátaxis operator docs, LLM orientation map)
- Identified 8 concerns; operator provided decisions on all 8
- Applied 6 spec changes:
  1. **Consolidation Plan** — disposition table for 12 overlapping docs (absorb-and-redirect pattern)
  2. **Section 05 rescoped** — observable conventions, not restated design principles
  3. **Stability requirement** — operator docs only for stable interfaces
  4. **Tag taxonomy** — acknowledged file-conventions.md + vault-check updates needed
  5. **Orientation map automation** — Phase 3 follow-on candidate
  6. **NotebookLM consumption constraint** — added as design constraint (self-contained docs)
- Additional updates: 1M context window noted, IDENTITY.md location fixed, 5 new decision record entries (#11-15)
- Created project scaffold, moved spec from inbox to `design/specification.md`

### Decisions
- Domain: software (documents the software system); workflow: knowledge work (SPECIFY → PLAN → ACT)
- Spec promoted directly from operator draft — not rewritten through systems-analyst
- All 8 analysis concerns resolved with operator decisions

### Compound evaluation
- **Consolidation as a first-class concern:** Documentation projects that create new canonical docs must explicitly plan for existing doc disposition. This is analogous to database migration planning — you can't just add new tables without addressing the old ones. Potential solution pattern for `_system/docs/solutions/`.
- **NotebookLM as consumption constraint:** When the operator's primary consumption mechanism is external to the vault (NotebookLM, not Obsidian), doc structure must be self-contained. This is a new design constraint that didn't exist when the vault was primarily Obsidian-consumed. Worth tracking as the system evolves.

### Peer review
- 4-model panel: GPT-5.4, Gemini 3 Pro Preview, DeepSeek Reasoner, Grok 4.1 Fast
- 2 must-fix, 7 should-fix, 5 deferred, 7 declined
- All 9 actionable items applied to spec
- Review note: `Projects/documentation-overhaul/reviews/2026-03-14-specification.md`
- GPT-5.4 first use after model upgrade from 5.2 — performed well, 32 findings including strong unverifiable claim flagging
- Gemini had 2 factual errors (M3 Ultra existence, Claude context window) — declined with `incorrect` justification

### Phase Transition: SPECIFY → PLAN
- Date: 2026-03-14
- SPECIFY phase outputs: `design/specification.md`, `design/specification-summary.md`, `reviews/2026-03-14-specification.md`
- Goal progress: spec complete (met), peer reviewed with fixes applied (met)
- Compound: consolidation planning pattern, NotebookLM consumption constraint, pre-requisite ordering for infrastructure changes
- Context usage before checkpoint: moderate (~50-60%)
- Action taken: none (proceeding)
- Key artifacts for PLAN phase: `design/specification-summary.md`

## 2026-03-14 — PLAN phase: action plan + tasks

**Phase:** PLAN
**Session type:** Action planning

### Context inventory
- `design/specification-summary.md` — approved spec summary
- No overlays loaded
- No estimation calibration or relevant solution patterns

### Work done
- Created `design/action-plan.md` — 4 milestones, dependency graph, risk assessment, session estimates
- Created `design/tasks.md` — 33 atomic tasks with IDs DOH-001 through DOH-033
- Created `design/action-plan-summary.md`
- No cross-project dependencies identified
- Peer review offer: LOW impact (documentation-only), not prompted

### Key decisions
- Session-per-architecture-doc scoping: each doc gets its own session for focused source synthesis
- Migration batch runs first in M3 to prevent duplication conflicts
- 13-14 session estimate (upper range of spec) to account for consolidation work
- M3 and M4 can run in parallel after M2

### Peer review (action plan)
- 4-model panel: GPT-5.4, Gemini 3.1 Pro Preview, DeepSeek Reasoner, Grok 4.1 Fast
- 3 must-fix, 5 should-fix applied
- Key fixes: M2 absorb chain deps, M3 migration dep on DOH-001, DOH-013 split, DOH-009 all 6 flows, discovery reconciliation sources, parallelism clarification
- DeepSeek needed 3 attempts (2 timeouts) — may need curl_timeout bump
- Gemini 3.1 Pro Preview first successful use after model upgrade
- Review note: `Projects/documentation-overhaul/reviews/2026-03-14-action-plan.md`

### Compound evaluation
- **Dependency chain through absorb tasks:** When a workflow has paired create/cleanup steps (draft + absorb), the dependency graph must chain through both — not just the creation step. Otherwise the next session starts before the prior cleanup is done. General pattern for any multi-step consolidation workflow. Potential solution pattern.
- No other compoundable insights — decomposition was mechanical against a well-defined spec.

### Phase Transition: PLAN → ACT
- Date: 2026-03-14
- PLAN phase outputs: `design/action-plan.md`, `design/tasks.md`, `design/action-plan-summary.md`, `reviews/2026-03-14-action-plan.md`
- Goal progress: action plan complete (met), peer reviewed with fixes applied (met), 35 tasks decomposed (met)
- Compound: absorb-chain dependency pattern (see above)
- Context usage before checkpoint: ~19%
- Action taken: none (proceeding)
- Key artifacts for ACT phase: `design/tasks.md`, `design/specification-summary.md`

## 2026-03-14 — ACT phase: M1 complete

**Phase:** ACT
**Session type:** Execution

### Work done
- DOH-001: Updated `file-conventions.md` with System Documentation Tags section. vault-check.sh unchanged — only validates `#kb/` tags, new `system/*` tags pass through.
- DOH-002: Created directory structure for all three tracks.
- Verified new tags pass vault-check (test file created, validated, removed).
- M1 milestone complete. M2 ready to begin.

### Session-end notes
- Peer review config updated: OpenAI gpt-5.2 → gpt-5.4, Gemini 3 Pro Preview → 3.1 Pro Preview (old model dead since March 9)
- DeepSeek and Grok confirmed current
- DeepSeek needed 3 attempts on action plan review (2 timeouts at 120s) — consider bumping curl_timeout to 240
- Gemini 3.1 Pro Preview first successful use confirmed
- GPT-5.4 first use confirmed — performed well

### Model routing
- All work on Opus (session default) — no Sonnet delegation. Knowledge-work project with no mechanical skill invocations suitable for delegation.

### Compound evaluation
- **vault-check tag scope:** vault-check only validates `#kb/` tags. Non-kb hierarchical tags (`system/architecture`, etc.) pass through without validation. This means the Phase 0 prerequisite was lighter than expected — only file-conventions.md needed updating, not vault-check.sh. Future tag hierarchies outside `#kb/` will have the same characteristic unless explicit validation is added.

## 2026-03-14 — ACT phase: M2.1 (DOH-003, DOH-004, DOH-005)

**Phase:** ACT
**Session type:** Execution — architecture docs session 1

### Context inventory
- `design/specification-summary.md` — project spec summary
- `design/tasks.md` — task list with acceptance criteria
- `progress/run-log.md` — prior session history
- `_system/docs/crumb-design-spec-v2-4.md` §0–§2, §7, §9 — system purpose, architecture, operations, external interfaces
- `_system/docs/system-architecture-diagram.md` — existing Mermaid diagram (absorb target)
- `_system/docs/attachments/tess-crumb-architecture.md` — companion note (absorb target)
- `_system/docs/tess-crumb-comparison.md` — actor definitions (partial absorb target)
- `_system/docs/tess-crumb-boundary-reference.md` — routing rules reference
- `_system/docs/separate-version-history.md` — chronology context
- `CLAUDE.md` — governance rules and constraints

### Work done
- **DOH-003:** Created `_system/docs/architecture/00-architecture-overview.md` stub — frontmatter with `system/architecture` tag, placeholder links to 01–05, related documents section, draft terminology index (AKM, QMD, FIF, MOC, HITL, OpenClaw). Stub will be completed as DOH-012 after all sections exist.
- **DOH-004:** Drafted `_system/docs/architecture/01-context-and-scope.md` — full section covering:
  - System purpose (4 bullets: persist context, enforce governance, compound over time, full-day coverage)
  - C4 context diagram (Mermaid) with prose fallback summary for NotebookLM
  - 4 actor definitions (Danny, Crumb, Tess Voice, Tess Mechanic) with ownership tables, identity models, vault access
  - System boundary (inside/outside tables with all components and external interfaces)
  - Handoff model (Tess→Crumb, Crumb→Tess, bridge protocol)
  - Constraints (architectural, operational, technical, security)
  - Design decisions relevant to scope
  - Source attribution to all consumed docs
- **DOH-005:** Absorb-and-redirect for two docs:
  - `system-architecture-diagram.md` → wikilink stub (`status: archived`), content absorbed into 01's context diagram and system boundary
  - `attachments/tess-crumb-architecture.md` → wikilink stub (`status: archived`), companion note retained for binary reference, content absorbed into 01
  - `tess-crumb-comparison.md` — partial absorb: actor definitions (identity, function, voice sections) absorbed into 01's Actors section. Ownership/routing content reserved for DOH-007 (→ 02). Personality model reserved for DOH-024 (→ why-two-agents). **Original not retired** — awaits completion of all three absorbs.
- All files pass vault-check clean (0 errors, 0 warnings after fixing missing `domain` field on diagram stub).

### Decisions
- Used C4 Context diagram style (not plain flowchart) for the Mermaid — gives better semantic clarity for system boundary visualization
- Kept the companion note for tess-crumb-architecture.md (binary still exists) — marked archived with redirect, not deleted
- Constraints organized into 4 categories (architectural, operational, technical, security) rather than flat list — mirrors how they're actually enforced

### Model routing
- All work on Opus (session default) — no Sonnet delegation. Synthesis from 10 source documents required judgment for what to include vs. defer to later sections.

## 2026-03-14 — ACT phase: M2.2 (DOH-006, DOH-007)

**Phase:** ACT
**Session type:** Execution — architecture docs session 2

### Context inventory
- Carried from M2.1: spec summary, tasks, 01-context-and-scope.md
- Additional: `_system/docs/crumb-design-spec-v2-4.md` §1 (components), §3 (skills, subagents, overlays), §4.1 (workflows), §5 (knowledge base)
- `_system/docs/tess-crumb-boundary-reference.md` — absorb target (ownership routing)
- `_system/docs/tess-crumb-comparison.md` — partial absorb target (function/capability tables)
- Live directory scans: `.claude/skills/`, `.claude/agents/`, `_system/docs/overlays/`, `_system/docs/protocols/`, `_system/scripts/`, `_openclaw/`

### Work done
- **DOH-006:** Drafted `_system/docs/architecture/02-building-blocks.md` covering:
  - L1 decomposition: 9 building blocks in 3 tiers (Agents, Lenses & Patterns, Data & Communication)
  - L2 decomposition for all 9 blocks with tables showing components, locations, and purposes
  - Full skill roster (22 skills) with phase and purpose
  - Subagent roster (3 agents) with consumers
  - Overlay roster (8 overlays) with primary signals
  - Protocol inventory (6 files + inline CLAUDE.md protocols)
  - Vault Store directory map with purpose and owner per directory
  - Knowledge Base layer: MOCs, AKM, tags, source indexes, kb-to-topic.yaml
  - Script inventory (11 key scripts with triggers and purposes)
  - Bridge directory structure (12 subdirectories with direction and purpose)
  - Block-beta Mermaid diagram + prose fallback for L1 decomposition
  - Flowchart Mermaid dependency diagram + prose fallback with critical path noted
  - Write Authority matrix (15 rows × 5 agents/roles)
  - Capability Ownership table (16 capabilities mapped to owner + assists)
  - Code Mapping table (file counts per block)
- **DOH-007:** Absorb-and-redirect:
  - `tess-crumb-boundary-reference.md` → archived stub with wikilinks to 01 and 02
  - `tess-crumb-comparison.md` — second partial absorb: function/capability tables absorbed into 02's Ownership Map (write authority + capability ownership). Personality model still reserved for DOH-024. **Original not yet retired** — awaits DOH-024.
- All files pass vault-check clean (0 errors, 0 warnings).

### Decisions
- Organized L1 into 3 tiers (Agents / Lenses & Patterns / Data & Communication) rather than flat list — reflects natural grouping by function
- Used block-beta diagram for L1 (structural overview) and flowchart for dependencies (relational) — different diagram types for different purposes
- Included live directory scan counts (22 skills, 8 overlays, 27 scripts, etc.) for current-state accuracy — these will need updating as the system evolves
- Bridge section is detailed (12 subdirectories) because `_openclaw/` is the least-documented part of the system

### Model routing
- All work on Opus — no delegation. Building blocks doc required cross-referencing live filesystem state against spec descriptions, judgment calls on grouping and ownership attribution.

## 2026-03-14 — ACT phase: M2.3 (DOH-008)

**Phase:** ACT
**Session type:** Execution — architecture docs session 3

### Context inventory
- Carried from M2.2: spec summary, tasks, 01 and 02 docs
- `_system/docs/crumb-design-spec-v2-4.md` §7 (operational concerns), §9 (deferred items)
- `_system/docs/crumb-deployment-runbook.md` — Crumb-only deployment (8 phases)
- `_system/docs/crumb-studio-migration.md` — full system migration (14 phases)
- `_system/docs/openclaw-colocation-spec.md` — security architecture (referenced, not loaded in full)
- `_openclaw/staging/m1/*.plist`, `_openclaw/staging/m2/*.plist` — 8 LaunchAgent plists
- `_system/scripts/com.crumb.bridge-watcher.plist` — bridge watcher plist
- Live system state via Explore subagent (infrastructure scan)

### Work done
- **DOH-008:** Drafted `_system/docs/architecture/04-deployment.md` covering:
  - Host: Mac Studio M3 Ultra, 3 macOS users (tess, openclaw, danny) with role descriptions
  - Process model: 3 launchd domains with 10 services (1 daemon + 9 agents), process model Mermaid diagram + prose fallback
  - Service inventory table: all 10 services with labels, types, users, schedules, purposes
  - Network topology: Mermaid diagram showing loopback services, Tailscale mesh, outbound APIs + prose fallback
  - Storage layout: on-host directory tree with absolute paths, git tracking strategy, backup mechanisms table
  - Credential management: 11-row credential map (storage, user, consumer, rotation) + two-tier security model
  - DNS: Tailscale MagicDNS, no self-hosted DNS
  - Deployment procedures: two runbook references with scope and time estimates
  - Platform-specific constraints: 7 macOS gotchas with mitigations (TCC, provenance xattr, octal dates, openrsync, etc.)
- Vault-check clean (0 errors, 0 warnings).

### Decisions
- Used Explore subagent for comprehensive infrastructure scan rather than manual file-by-file reads — yielded complete service inventory, plist locations, credential map, and storage layout in one pass
- Included known macOS constraints table — these are operational landmines that have bitten multiple times (documented in MEMORY.md) and belong in the architecture docs
- Credential rotation column included even though most are "Manual" — makes the gap visible for future automation

### Model routing
- Opus for main session. Explore subagent (Opus) for infrastructure discovery. Total: 2 Opus contexts.

## 2026-03-14 — ACT phase: M2.4 (DOH-009, DOH-010)

**Phase:** ACT
**Session type:** Execution — architecture docs session 4

### Context inventory
- Carried from M2.3: spec summary, tasks, 01-04 docs
- `_system/docs/feed-intel-processing-chain.md` — absorb target (3-stage pipeline)
- `_system/docs/feed-intel-processing-chain-diagram.md` — absorb target (pipeline diagram)
- `_system/docs/skill-workflows/fif-triage-and-signals.md` — current FIF operational reference
- `_system/docs/context-checkpoint-protocol.md` — session lifecycle reference
- `_system/docs/protocols/session-end-protocol.md` — session-end 9-step sequence
- `_system/docs/protocols/bridge-dispatch-protocol.md` — bridge JSON schema
- Design spec §4.1 (workflow phases), §7.1 (session management)

### Work done
- **DOH-009:** Drafted `_system/docs/architecture/03-runtime-views.md` — 6 sequence diagrams with prose summaries and failure handling:
  1. **Session lifecycle** — startup (hook, git pull, vault-check, AKM brief) → resume (state reconstruction) → work loop → phase transition (Context Checkpoint Protocol) → session-end (9 autonomous steps)
  2. **Tess dispatch** — Telegram → OpenClaw webhook → tess-voice → vault read or bridge handoff. Includes limited mode fallback.
  3. **Feed pipeline** — 3 stages (capture clock → attention clock/triage → Crumb processing). Tier 1/2/3 routing, circuit breaker, feedback loop via Telegram commands.
  4. **Mission Control** — dashboard triage (skip/delete/promote) → dashboard_actions table → feed-pipeline Step 0 consumption. Dashboard-promoted items skip permanence eval.
  5. **Bridge handoff** — confirmation echo → _openclaw/inbox write → kqueue detection → claude --print with governance → outbox → Tess delivery. 4-layer security, kill switch.
  6. **AKM surfacing** — 3 trigger modes (session-start 5 items, skill-activation 3 items, new-content 5 items). Decay scoring, dedup, compound detection. Feedback loop via hit-rate measurement.
- **DOH-010:** Absorb-and-redirect:
  - `feed-intel-processing-chain.md` → archived stub with wikilinks to 03 and fif-triage-and-signals
  - `feed-intel-processing-chain-diagram.md` → archived stub with wikilink to 03
- Vault-check clean (0 errors, 0 warnings).

### Decisions
- Used sequenceDiagram (not flowchart) for all 6 flows — sequence diagrams show temporal ordering and participant handoffs more clearly than flowcharts for runtime views
- Included failure handling section under each flow rather than a consolidated failure section — each flow has different failure modes and recovery paths
- Mission Control treated as a separate flow (not folded into feed pipeline) because it has a distinct entry point (web dashboard) and different processing path (dashboard_actions table, skip permanence eval)
- Fed-intel chain docs redirected to both 03 (architecture) and fif-triage-and-signals (current operational reference) — two different audiences

### Model routing
- All work on Opus — no delegation. 6 sequence diagrams required understanding of multiple subsystem interactions and judgment on what to include vs. defer.

## 2026-03-14 — ACT phase: M2.5 (DOH-011, DOH-012) — M2 COMPLETE

**Phase:** ACT
**Session type:** Execution — architecture docs session 5 (final M2)

### Context inventory
- Carried from M2.4: spec summary, tasks, 00–04 docs
- `_system/docs/file-conventions.md` — file naming, frontmatter schemas, tag taxonomy, type taxonomy, companion notes, MOC conventions
- `_system/docs/crumb-design-spec-v2-4.md` §4.2–§4.5 (convergence, approval gates, compound, task state machine), §7.2–§7.8 (git, hooks, vault-check)
- `vault-check.sh` — 30 check descriptions from spec §7.8

### Work done
- **DOH-011:** Drafted `_system/docs/architecture/05-cross-cutting-concepts.md` — 12 convention sections:
  - Frontmatter schema (project vs non-project required fields)
  - File naming (kebab-case, binary companions)
  - Tag taxonomy (#kb/ 3-level hierarchy, 18 canonical L2, 4 sync points; system/ tags)
  - Type taxonomy (31 types, key types table)
  - vault-check (30 validations, 3 exit tiers, checks-by-category table)
  - Context budget (standard/extended/ceiling tiers, autonomous management)
  - Summary document pattern (source_updated staleness detection)
  - MOC system (placement pass, synthesis pass, debt scoring)
  - Compound engineering (phase transition enforcement, insight routing, read-back)
  - Risk-tiered approval (low/medium/high with examples)
  - Git patterns (conventional commits, binary exclusion, conditional commit)
  - Code review tiers (Tier 1 Sonnet inline, Tier 2 cloud panel)
  - Task state machine (5 states, transition invariants, acceptance criteria rules)
  - Wikilink convention (shortest-path, bare vs path-prefixed)
- **DOH-012:** Completed `_system/docs/architecture/00-architecture-overview.md`:
  - Status changed from `draft` to `active`
  - Sections list expanded with content summaries for each
  - Document hierarchy table (spec → architecture → version history with authority domains)
  - Related documents expanded (added file-conventions, CLAUDE.md)
  - Terminology index expanded: 12 terms (AKM, QMD, FIF, MOC, HITL, OpenClaw, Bridge, Skill, Overlay, vault-check, Compound, Signal-note) with definitions and cross-references to specific sections
- **M2 milestone complete.** All 10 tasks (DOH-003 through DOH-012) done. 6 architecture docs written, 4 absorb-and-redirect stubs created.
- All files pass vault-check clean (0 errors, 0 warnings).

### M2 Milestone Summary
- **Files created:** 6 architecture docs (00–05) totaling ~1800 lines
- **Files archived:** 4 existing docs redirected (system-architecture-diagram, tess-crumb-architecture companion, feed-intel-processing-chain, feed-intel-processing-chain-diagram)
- **Partial absorbs in progress:** `tess-crumb-comparison.md` — actors (→01, DOH-005), ownership (→02, DOH-007). Personality model awaits DOH-024 (→ why-two-agents.md). `tess-crumb-boundary-reference.md` fully absorbed and archived.
- **Mermaid diagrams:** 11 total (1 C4 context, 1 block-beta decomposition, 1 dependency flowchart, 2 deployment flowcharts, 1 network topology, 6 sequence diagrams)
- **Sessions:** 5 sub-sessions within a single conversation (M2.1–M2.5)

### Decisions
- Cross-cutting concepts focused strictly on observable conventions and enforcement, not design philosophy — avoids duplicating design spec content
- Terminology index in 00 kept to 12 high-frequency terms — comprehensive enough for orientation, not an exhaustive glossary
- vault-check section uses a by-category summary table rather than listing all 30 checks — the full list is in the design spec §7.8

### Compound evaluation
- **Architecture docs as NotebookLM source:** These 6 docs (~1800 lines) are designed as self-contained NotebookLM notebook sources. Each has prose fallback summaries for every Mermaid diagram, explicit cross-references rather than assumed navigation, and clear section boundaries. This is the first set of docs built against the NotebookLM consumption constraint. Worth monitoring whether the format actually works well in notebook ingestion.
- **Absorb-and-redirect pattern validated:** The stub-and-archive approach for absorbed docs (wikilink redirect + `status: archived`) worked cleanly across 4 docs. vault-check had no issues. The pattern is reusable for M3's migration batch. The key lesson: always include `domain` field even on archived stubs — vault-check requires it for non-project docs regardless of status.

### Model routing
- All work on Opus (session default). One Explore subagent (Opus) for M2.3 infrastructure discovery. No Sonnet delegation — all tasks required synthesis judgment across multiple source documents.

## 2026-03-14 — ACT phase: M3.1 (DOH-013, DOH-013b) — Migration batch

**Phase:** ACT
**Session type:** Execution — operator docs migration batch

### Context inventory
- `design/specification-summary.md` — project spec summary
- `design/tasks.md` — task list with acceptance criteria
- `design/specification.md` §Phase 2 migration batch — consolidation plan, target locations
- 6 source files: `crumb-deployment-runbook.md`, `vault-gardening.md`, `Ops/git-commands.md`, `Ops/tailscale-setup.md`, `Ops/tmux-commands.md`, `Ops/updates-to-an-archived-project.md`
- `_system/docs/crumb-studio-migration.md` (OpenClaw setup steps for DOH-013b)
- `_system/docs/architecture/04-deployment.md` (service inventory for DOH-013b impact analysis)
- MEMORY.md OpenClaw operational notes (gateway health check, launchd domain mismatch, DM pairings, provenance xattr)

### Work done
- **DOH-013:** Migrated 6 "keep as-is" docs via `git mv`:
  - `crumb-deployment-runbook.md` → `operator/how-to/` (Diátaxis: how-to ✓)
  - `vault-gardening.md` → `operator/how-to/` (Diátaxis: how-to ✓)
  - `Ops/git-commands.md` → `operator/reference/` (Diátaxis: reference ✓)
  - `Ops/tailscale-setup.md` → `operator/how-to/` (Diátaxis: how-to ✓)
  - `Ops/tmux-commands.md` → `operator/reference/` (Diátaxis: reference ✓)
  - `Ops/updates-to-an-archived-project.md` → `operator/how-to/` (Diátaxis: how-to ✓)
  - All 6: added `system/operator` tag, fixed missing `domain` fields, updated dates
  - Cleaned conversational leftover from `updates-to-an-archived-project.md`
  - Updated hardcoded path in `04-deployment.md` (runbook reference table)
  - Ops/ retains only `notebooklm-digest-import-process.md` (awaits DOH-029)
- **DOH-013b:** Expanded deployment runbook with OpenClaw upgrade section (~130 lines):
  - Problem statement, impact analysis table (6 services), pre-upgrade checklist, 7-step upgrade procedure, rollback, credential rotation, done criteria
  - Incorporated operational gotchas from MEMORY.md: provenance xattr, launchd domain mismatch, HOME not reset by sudo, DM pairings lost on restart, lsof false negatives without sudo
  - Updated scope line from "Crumb only" to "Crumb deployment and OpenClaw upgrade procedures"
- vault-check: 0 new errors (12 pre-existing in unrelated Sources/research/ files)

### Decisions
- All 6 docs passed Diátaxis compliance check — moved verbatim (no splitting needed)
- `crumb-deployment-runbook.md` type changed from `reference` to `runbook` (more accurate for a step-by-step procedure)
- OpenClaw upgrade section placed between Phase 8 (Optional Enhancements) and Migration section — separate operational concern from initial deployment

### Model routing
- All work on Opus (session default). One Explore subagent (Opus) for file location discovery. No Sonnet delegation.

## 2026-03-14 — ACT phase: M3.2 + M4 + Cleanup — PROJECT COMPLETE

**Phase:** ACT
**Session type:** Execution — bulk drafting (remaining M3 + M4 + cleanup)

### Context inventory
- `design/specification-summary.md` — project spec summary
- `design/tasks.md` — task list with acceptance criteria
- Architecture docs 00–05 (cross-referenced for all drafts)
- MEMORY.md — operational notes for infrastructure reference
- 4 Explore subagents: skills scan, vault structure scan, FIF SQLite schema, feed pipeline operations, overlays scan, LLM orientation scan

### Work done — M3 Drafting (DOH-014 through DOH-031)

**Reference docs (6):**
- DOH-014: `skills-reference.md` — 22 skills indexed with model routing, workflow alignment, overlay integration, composability, dispatch capabilities, required context
- DOH-015: `vault-structure-reference.md` — full directory tree, ownership map, path conventions, frontmatter requirements, tag taxonomy, type taxonomy, 30-rule vault-check summary
- DOH-016: `infrastructure-reference.md` — 10-service inventory, 3 ports, 11-credential map, health checks, 9 log locations, 9 macOS platform constraints
- DOH-019: `sqlite-schema-reference.md` — 2 databases, 13 tables total, ownership boundaries, join contracts, retention policy, concurrency model
- DOH-030: `tag-taxonomy-reference.md` — 18 canonical L2 tags, L3 rules, subordination rule, enforcement, 4 sync points
- DOH-031: `overlays-reference.md` — 8 overlays with activation signals, all lens questions, 3 companion files, skill integration

**How-to docs (5):**
- DOH-017: `run-feed-pipeline.md` — trigger, 4-step processing, 7 health signals, 6 failure scenarios
- DOH-018: `triage-feed-content.md` — dashboard access, signal cards, 3 triage actions, batch ops, 5 problems
- DOH-027: `update-a-skill.md` — 5-step procedure, peer review guidance
- DOH-028: `rotate-credentials.md` — 11 credentials, per-type procedures, validation checklist
- DOH-029: `add-knowledge-to-vault.md` — 3 methods (NLM, manual, feed pipeline), tagging rules. Absorbed `notebooklm-digest-import-process.md` (stub-and-archived)

**Tutorials (3):**
- DOH-020: `mission-control-orientation.md` — 6 sequential steps with expected outcomes
- DOH-021: `first-crumb-session.md` — 8 steps (SSH → session end)
- DOH-022: `first-tess-interaction.md` — 6 steps (Telegram → escalation)

**Explanations (4):**
- DOH-023: `how-crumb-thinks.md` — spec-first, phase gates, compound engineering, ceremony budget, mechanical enforcement, vault as truth
- DOH-024: `why-two-agents.md` — Tess/Crumb split rationale, personality model absorbed from `tess-crumb-comparison.md` (final absorb — original stub-and-archived)
- DOH-025: `the-vault-as-memory.md` — why Obsidian, knowledge persistence, AKM, compound amplifier, 5 limitations
- DOH-026: `feed-pipeline-philosophy.md` — promote/skip/delete model, tier system, permanence, circuit breaker, attention connection

### Work done — M4 (DOH-032, DOH-033)
- DOH-032: `orientation-map.md` — 53 LLM-consumed documents mapped across 7 categories, token budgets, load triggers, update triggers, architecture source links
- DOH-033: Gap analysis integrated into orientation map — 10 covered subsystems, 6 gaps (4 deferred, 2 fill candidates)

### Work done — Cleanup (DOH-034)
- DOH-034: Retired `_system/docs/Ops/` directory — `git rm -f` archived stub, `rmdir`. All 5 original files accounted for.

### Project Completion Summary
- **35 tasks** across 4 milestones + cleanup, all done
- **Files created:** 6 architecture docs, 18 operator docs (6 reference, 7 how-to, 3 tutorials, 4 explanations), 1 orientation map = **25 new docs**
- **Files archived/redirected:** 6 docs stub-and-archived (system-architecture-diagram, tess-crumb-architecture companion, feed-intel-processing-chain, feed-intel-processing-chain-diagram, tess-crumb-comparison, notebooklm-digest-import-process)
- **Files migrated:** 6 docs moved from _system/docs/ and Ops/ to operator directories
- **Directories created:** architecture/, operator/{tutorials,how-to,reference,explanation}/, llm-orientation/
- **Directory retired:** Ops/
- **Sessions:** 8 sub-sessions across 2 conversation contexts (SPECIFY/PLAN/M1/M2 in first; M3/M4/cleanup in second)

### Decisions
- All operator docs written in Diátaxis-compliant format (how-to: problem statement + done criteria; reference: structured tables; tutorials: sequential steps + expected outcomes; explanations: narrative prose)
- Orientation map gap analysis deferred 4 of 6 gaps (human-operated subsystems) and identified 2 fill candidates for future work
- Explanations written in first-person system perspective ("Crumb thinks...") rather than external description — matches the consumption context (operator understanding the system's behavior)

### Compound evaluation
- **Batch drafting efficiency:** This session completed 22 docs in a single context by frontloading all research into Explore subagents, then writing docs in sequence. The pattern: parallel research → serial writing → batch task updates. This is significantly faster than one-doc-per-session and viable when the doc quality bar is "AI draft, human review" (not "convergence-tested final"). Worth noting as a calibration data point for future documentation projects.
- **Diátaxis as constraint, not framework:** Diátaxis proved most useful as a *classification constraint* ("this doc must fit exactly one quadrant") rather than a drafting framework. The actual writing benefited more from architecture docs as source material. Diátaxis prevented mixing procedural and explanatory content in the same doc — that was its primary value.
- **Absorb-and-redirect at scale:** 6 docs absorbed across the project, all using the same wikilink stub pattern. No breakage detected. The pattern is mechanically sound but requires tracking partial absorbs carefully (tess-crumb-comparison needed 3 separate absorbs across DOH-005, DOH-007, DOH-024). Future consolidation projects should track partial absorb state explicitly in task descriptions.

### Post-completion additions
- **rclone Google Drive sync:** Installed rclone, wrote `drive-sync.sh`, created LaunchAgent plist (`com.crumb.drive-sync`, danny user, 5 AM daily). OAuth configured interactively. NotebookLM requires `.txt` not `.md` — script stages to `/tmp/drive-sync-staging/` with extension rename before `rclone sync`. 31 docs confirmed synced.
- **Audit skill updated:** Added weekly check §14 — operator/architecture doc drift detection (count comparisons against live system state). Lightweight, flags mismatches for operator decision.
- Operator docs and architecture docs updated to reflect new service.

### Model routing
- All work on Opus (session default). 5 Explore subagents (Opus) for research-heavy scanning (skills, vault structure, FIF SQLite, feed operations, overlays, LLM orientation). No Sonnet delegation — all docs required synthesis across multiple source documents and judgment on what to include vs. defer.
