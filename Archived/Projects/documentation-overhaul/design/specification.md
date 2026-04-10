---
type: specification
project: documentation-overhaul
domain: software
status: active
created: 2026-03-14
updated: 2026-03-14
skill_origin: systems-analyst
tags:
  - system/docs
  - system/architecture
topics:
  - moc-crumb-architecture
---

# Crumb/Tess Documentation Overhaul — Implementation Plan

## Context and Scope

This plan defines the documentation architecture for the Crumb/Tess system. It replaces the current ad-hoc documentation state with a structured, maintainable system built on established frameworks.

### What this overhaul covers

Three documentation tracks, serving three audiences, from one authoritative source:

| Track | Audience | Framework | Purpose |
|---|---|---|---|
| System Architecture | Rebuilder (human) | Arc42 (cherry-picked) | "Another competent dev could rebuild this" |
| Operator Docs | Operator (human) | Diátaxis | "Someone could run this system without the builder" |
| LLM Orientation | Claude (session start) | Existing conventions | "Claude can orient and act within one context load" |

**Relationship model (Option B):** The system architecture doc is the authoritative source of truth. Operator docs reference it but are organized by task, not by structure. LLM orientation docs (CLAUDE.md, SKILL.md, overlays, SOUL.md) remain independent artifacts with their own conventions and token budgets, but are *informed by* the architecture and operator docs when updated.

### What this overhaul does not cover

- ADRs — can be adopted incrementally later; the architecture doc captures current state
- Workflow three-view docs (normal/degraded/recovery) — valuable but deferred until the architecture doc exists
- Retroactive capture from run-logs — too labor-intensive at current validation bandwidth
- Changes to existing LLM orientation formats (CLAUDE.md line budget, SKILL.md nine-section structure, overlay 50-line budget) — these conventions are stable and working

### Design constraints

- Everything lives inside the existing Obsidian vault structure
- Must respect: tag taxonomy, MOC system, vault-check enforcement, wikilink cross-referencing, QMD/AKM surfacing
- AI does the drafting; Danny reviews final artifacts only
- Ceremony Budget Principle applies — no structure that doesn't earn its maintenance cost
- **NotebookLM is the primary consumption mechanism.** Danny consumes documentation through NotebookLM Project Notebooks, not by reading vault files directly. Architecture and operator docs will be synced to Google Drive and ingested into notebooks for interactive re-ramping. This means docs should be self-contained enough to be useful when loaded into a notebook context (clear section boundaries, explicit cross-references rather than assumed vault navigation, no reliance on Obsidian-specific rendering). The exact notebook organization is a separate project concern, but doc structure should not fight this consumption model.

---

## Documentation Architecture

### Vault Placement

All new documentation lives under `_system/docs/`, extending the existing convention where the design spec already resides.

```
_system/docs/
├── crumb-design-spec-v2-4.md          # existing — remains authoritative for design intent
├── separate-version-history.md         # existing
├── architecture/                       # NEW — arc42-derived system docs
│   ├── 00-architecture-overview.md     # master entry point, links to all sections
│   ├── 01-context-and-scope.md         # system boundary, external interfaces, actors
│   ├── 02-building-blocks.md           # vault primitives, their relationships, hierarchy
│   ├── 03-runtime-views.md             # session flows, dispatch cycles, pipeline execution
│   ├── 04-deployment.md                # infrastructure, tunnels, daemons, hosting
│   └── 05-cross-cutting-concepts.md    # design principles, conventions, patterns
├── operator/                           # NEW — Diátaxis-organized operator docs
│   ├── tutorials/                      # onboarding: first-run orientation
│   ├── how-to/                         # recurring tasks and procedures
│   ├── reference/                      # tools, inputs, outputs, status meanings
│   └── explanation/                    # why the system behaves the way it does
└── llm-orientation/                    # NEW — index/tracking for LLM doc layer
    └── orientation-map.md              # maps which LLM docs exist, their budgets, update triggers
```

**Notes on placement:**

- `architecture/` is the authoritative source. Operator docs and LLM docs reference it, not the other way around.
- `operator/` uses Diátaxis subdirectories. Each subdirectory contains flat markdown files, not further nesting.
- `llm-orientation/` is *not* where CLAUDE.md, SKILL.md, or overlays live — those stay in their current locations. This folder contains only the orientation map that tracks them.
- The design spec and version history remain in their current locations alongside the new `architecture/` directory. See the document hierarchy below for how they relate.

### The Three-Document Hierarchy

Three pre-existing and new artifacts describe the system at different levels. Their relationship must be unambiguous to prevent drift and duplication.

| Document | Describes | Changes when | Analogy |
|---|---|---|---|
| Design spec (`crumb-design-spec-v2-4.md`) | **Why and what** — design intent, philosophy, governing principles, system model | The system's fundamental model changes | Constitution |
| Architecture docs (`architecture/`) | **How and where** — current-state description of what exists, how it's built, how it behaves | The system changes structurally | Engineering drawings |
| Version history (`separate-version-history.md`) | **When and what changed** — changelog of significant changes over time | Any notable change is made | Changelog / proto-ADR |

**Authority domains:** Each document is authoritative for a different domain:
- **Design spec** — authority for *intent and principles*: why the system exists, what it should be
- **Architecture docs** — authority for *current implementation state*: how it's built, what exists today
- **Version history** — authority for *chronology*: when changes happened and in what order; it is an evidentiary input and audit trail, not a governing document

Architecture docs must be *consistent with* the design spec; if they diverge, either the spec needs updating (the intent changed) or the implementation is wrong.

**For AI drafting:** When Crumb drafts any architecture section, it must read both the design spec and the version history as primary sources. The design spec tells it what the system is supposed to do. The version history tells it what's actually been built and in what order. The architecture doc synthesizes both into a current-state description.

**For maintenance:** When a structural change is made, the update sequence is: (1) version history gets a new entry, (2) affected architecture section(s) are updated, (3) linked operator and LLM docs are checked for staleness. The design spec is only updated if the change reflects a shift in fundamental intent, not routine evolution.

### Tagging

New docs follow the existing tag taxonomy:

- Architecture docs: `system/docs`, `system/architecture`
- Operator docs: `system/docs`, `system/operator`
- LLM orientation map: `system/docs`, `system/llm-orientation`

Level 3 subtags can be added as the doc set grows (e.g., `system/operator/how-to`), following the established "tag broadly, home narrowly" principle.

---

## Track 1: System Architecture (Arc42-Derived)

### Section definitions

Five sections, cherry-picked from arc42's twelve, plus an overview entry point. Each maps to one markdown file.

#### 00 — Architecture Overview

**What it answers:** Where do I start? What does this documentation set contain?

**Contents:**
- One-paragraph system identity statement (e.g., "Crumb/Tess is a single-operator personal multi-agent OS built on Claude Code with an Obsidian vault as shared memory")
- Linked table of contents for sections 01-05 with one-sentence descriptions
- Lightweight terminology index: first-use expansions for system-specific acronyms (AKM, QMD, FIF, MOC, HITL, OpenClaw)
- Pointer to the design spec for design intent and to the version history for change chronology

**What it should NOT contain:** Duplicated content from sections 01-05. This is a navigation aid, not a summary.

**Written last** (after all five sections are complete), but a stub is created first for cross-linking.

**Source material:** The five completed architecture sections.

#### 01 — Context and Scope

**What it answers:** What is Crumb/Tess? What are its boundaries? What external systems does it touch? Who are the actors?

**Contents:**
- System purpose (one paragraph)
- Context diagram (Mermaid): Crumb/Tess as a black box, showing external interfaces — Obsidian vault, GitHub repos, Anthropic API, Ollama, Telegram, Cloudflare, Healthchecks.io, NotebookLM, etc.
- Actor definitions: Danny (builder/operator), Claude interactive (Crumb sessions), Tess-voice (Haiku, Telegram), Tess-mechanic (Qwen, background tasks)
- System boundary: what is inside Crumb/Tess vs. what is external tooling
- Key constraints: single-operator, evening/weekend build cadence, Mac Studio host, vault as shared memory

**Source material for AI drafting:** Design spec (`crumb-design-spec-v2-4.md`), version history, CLAUDE.md, SOUL.md, userMemories context, OpenClaw infrastructure notes.

#### 02 — Building Blocks

**What it answers:** What are the parts? How do they relate? What does each one own?

**Contents:**
- Level 1 decomposition: Crumb (deep work engine), Tess (operational delivery), Bridge (coordination), Mission Control (dashboard), FIF (content pipeline), AKM (knowledge surfacing)
- Level 2 decomposition per major subsystem: vault primitives (skills, overlays, protocols, run-logs, MOCs), infrastructure components (OpenClaw, LaunchDaemon, Cloudflare Tunnel), data stores (vault files, SQLite tables, GitHub repos)
- Ownership map: which subsystem owns which data, which tables, which vault paths
- Dependency diagram (Mermaid): how subsystems depend on each other
- Mapping to code: which repos contain which subsystems, directory structure significance

**Source material:** Design spec, version history, SKILL.md files, vault structure, dashboard repo, bridge architecture notes.

#### 03 — Runtime Views

**What it answers:** How does the system actually behave at runtime? What are the key flows?

**Contents:**
- Crumb interactive session lifecycle: session start → AKM surfacing → skill activation → work → session-end logging
- Tess dispatch cycle: Telegram input → tess-voice processing → bridge handoff → Crumb execution → response delivery
- Feed pipeline execution: source ingestion → post processing → triage queue → dashboard display → promote/skip/delete actions
- Mission Control request flow: browser → Cloudflare Tunnel → Express server → EJS render / API action → SQLite
- Bridge handoff: file-based async write → atomic commit → HITL enforcement → execution → feedback
- AKM surfacing: QMD query → semantic search → hit/miss → feedback logging

Each flow documented as a sequence diagram (Mermaid) with accompanying narrative describing the happy path and noting where failures are handled.

**Source material:** Design spec, version history, run-logs, session transcripts (for flow patterns), SKILL.md files, bridge architecture docs, dashboard source code.

#### 04 — Deployment

**What it answers:** How is this system physically deployed? What runs where? How do you set it up from scratch?

**Contents:**
- Host: Mac Studio M3 Ultra, 96GB RAM
- Process model: OpenClaw LaunchDaemon (system domain), two-agent split (tess-voice on Haiku, tess-mechanic on Qwen via Ollama)
- Network topology: Cloudflare Tunnel → Express server (Mission Control), Telegram Bot API → tess-voice, Healthchecks.io dead man's switch
- Storage: Obsidian vault (local filesystem, synced), SQLite databases (dashboard_actions, posts), GitHub repos (crumb-dashboard, crumb-vault-mirror)
- Secrets and credentials: where they live, rotation cadence, SecretRef migration status
- DNS: crumbos.dev via Cloudflare Registrar
- Deployment diagram (Mermaid): physical topology showing host, processes, network paths, external services

**Source material:** Design spec, version history, OpenClaw infrastructure notes, health-check configuration, Cloudflare setup, upgrade impact analyses.

#### 05 — Cross-Cutting Concepts

**What it answers:** What conventions and patterns are actually in effect across the system today?

**Scope distinction:** The design spec describes *intent* — why principles exist. This section describes *current practice* — what's enforced, what's configured, what naming and structural patterns are observable in the vault right now. If the design spec says "ceremony budget is a principle," this section says "here's what vault-check actually enforces, here's the CLAUDE.md line budget, here are the naming patterns in practice."

**Contents:**
- Vault-check enforcement rules: what it validates, what it blocks on commit, what it warns about
- Tag taxonomy as practiced: Level 2 canonical list, Level 3 open creation, four sync points, vault-check enforcement scope
- "Tag broadly, home narrowly" — how MOCs, topics, and directory placement interact in practice
- Token budget conventions: CLAUDE.md 200 lines, overlays 50 lines, SKILL.md nine-section structure — where these are enforced vs. advisory
- File naming and frontmatter conventions: required fields, type vocabulary, status vocabulary
- Code review tiers in practice: Tier 1 inline Sonnet, Tier 2 cloud panel — when each fires
- Run-log rotation: monthly archival, naming convention
- Git patterns: PAT-embedded URLs, vault-mirror allowlist scope, pre-commit hook chain
- Permission patterns: Bash allow/deny colon format, settings.json vs. settings.local.json

**Source material:** `file-conventions.md`, `vault-check.sh` validation rules, CLAUDE.md, `skill-authoring-conventions.md`, `code-review-config.md`.

### Arc42 sections explicitly excluded

| Section | Reason for exclusion |
|---|---|
| Introduction & Goals | Covered by the design spec |
| Solution Strategy | Implicit in build choices; would duplicate cross-cutting concepts |
| Quality Requirements | Premature formalization for a single-operator system |
| Technical Risks | Better tracked ad-hoc in run-logs; a formal risk register would be ceremony debt |
| Glossary | Tag taxonomy and MOC system already serve this function |
| Quality Scenarios | No test harness to validate against |
| Stakeholder Requirements | Single stakeholder (Danny); requirements live in the design spec |

---

## Track 2: Operator Docs (Diátaxis)

### Organizing principle

Every document in `operator/` belongs to exactly one Diátaxis quadrant. The quadrant determines the document's structure, voice, and maintenance trigger.

| Quadrant | Directory | Voice | Structure | Maintenance trigger |
|---|---|---|---|---|
| Tutorials | `tutorials/` | "Follow along with me" | Sequential steps, expected outcomes at each stage | Workflow changes |
| How-To | `how-to/` | "Do this to achieve that" | Problem → steps → done | Procedure changes |
| Reference | `reference/` | "Here is the fact" | Tables, lists, structured entries | Capability changes |
| Explanation | `explanation/` | "Here is why" | Narrative prose | Mental model changes |

### Minimum operator doc set

The initial set covers the subsystems that are in production or active development. Each subsystem gets coverage proportional to its operational complexity.

#### Tutorials (onboarding)

| Document | Covers |
|---|---|
| `first-crumb-session.md` | How to start an interactive Crumb session from scratch: vault state, CLAUDE.md load, AKM orientation, skill activation, run-log expectations |
| `first-tess-interaction.md` | How Tess works from the operator's perspective: Telegram interface, voice vs. mechanic split, what Tess can and cannot do, escalation |
| `mission-control-orientation.md` | Dashboard walkthrough: how to access via tunnel, what the views show, how triage works, what promote/skip/delete actually do |

#### How-To (recurring tasks)

| Document | Covers |
|---|---|
| `run-feed-pipeline.md` | Triggering a feed pipeline run, monitoring progress, handling failures |
| `triage-feed-content.md` | Using the Mission Control triage interface, understanding post states, batch operations |
| `update-a-skill.md` | Editing a SKILL.md, running vault-check, committing, verifying AKM pickup |
| `rotate-credentials.md` | SecretRef locations, rotation procedure, validation steps |
| `vault-gardening.md` | Archive/KB pattern, MOC debt scoring, when to archive vs. purge, vault-check pre-commit |
| `deploy-openclaw-update.md` | Upgrade procedure, impact analysis, credential rotation, health-check verification |
| `add-knowledge-to-vault.md` | NLM pipeline (prompt templates, inbox processor routing), manual note creation, tagging conventions |

#### Reference

| Document | Covers |
|---|---|
| `skills-reference.md` | Index of all skills: name, purpose, activation trigger, key inputs/outputs, current status |
| `overlays-reference.md` | Index of all overlays: name, activation signals, lens questions, token budget |
| `vault-structure-reference.md` | Directory tree, path conventions, what lives where, vault-check rules |
| `sqlite-schema-reference.md` | All SQLite tables: schema, ownership (FIF vs. dashboard), join patterns |
| `infrastructure-reference.md` | Hostnames, ports, tunnel config, daemon names, health-check URLs, DNS records |
| `tag-taxonomy-reference.md` | Complete tag hierarchy: Level 2 canonical tags, Level 3 subtags, tagging rules |

#### Explanation

| Document | Covers |
|---|---|
| `how-crumb-thinks.md` | The Crumb mental model: spec-first, compound engineering, ceremony budget, why the system is built the way it is |
| `why-two-agents.md` | The Tess/Crumb split: why separate voice and mechanic, why Haiku vs. Qwen, what each is optimized for |
| `the-vault-as-memory.md` | Why Obsidian, why vault-as-shared-memory works, how AKM/QMD turns files into context, limitations |
| `feed-pipeline-philosophy.md` | Why content intelligence matters, the promote/skip/delete model, how triage feeds attention management |

---

## Track 3: LLM Orientation (Tracking Layer)

### Purpose

The LLM orientation docs (CLAUDE.md, SKILL.md files, overlays, SOUL.md, IDENTITY.md) already exist and work. This track does not redesign them. It adds a single tracking artifact that makes the LLM doc layer governable.

### The orientation map

`llm-orientation/orientation-map.md` is a reference document that lists every LLM-consumed doc, its location, token budget, update trigger, and relationship to the architecture docs.

Structure:

```markdown
# LLM Orientation Map

## Session Entry Points
| Document | Location | Budget | Update Trigger | Architecture Source |
|---|---|---|---|---|
| CLAUDE.md | root | 200 lines | System capability changes | 02-building-blocks, 05-cross-cutting |
| SOUL.md | ~/.openclaw/soul.md | — | Persona/identity changes | — (independent) |
| IDENTITY.md | ~/.openclaw/identity.md | — | Persona/identity changes | — (independent) |

## Skills
| Skill | SKILL.md Location | Budget | Update Trigger | Architecture Source |
|---|---|---|---|---|
| feed-pipeline | [path] | 9 sections | Pipeline changes | 03-runtime-views |
| deck-intel | [path] | 9 sections | Capability changes | 02-building-blocks |
| ... | ... | ... | ... | ... |

## Overlays
| Overlay | Location | Budget | Activation Signal | Architecture Source |
|---|---|---|---|---|
| Life Coach | [path] | 50 lines | [signal] | — |
| ... | ... | ... | ... | ... |
```

This map serves two purposes:
1. **Gap detection:** If a subsystem appears in the architecture docs but has no corresponding LLM orientation entry, it's a gap.
2. **Staleness detection:** If an architecture section is updated but its linked LLM docs aren't, they may be stale.

---

## Implementation Plan

### Phasing

The work is divided into three phases, preceded by a prerequisite step. Each phase produces usable artifacts; no phase depends on the completion of a later phase.

#### Phase 0: Prerequisites

**Goal:** Unblock Phase 1 by updating vault infrastructure for new tag taxonomy.

**Tasks:**
1. Update `_system/docs/file-conventions.md` to add `system/architecture`, `system/operator`, and `system/llm-orientation` as canonical tags
2. Update `_system/scripts/vault-check.sh` validation rules to accept the new tags
3. Commit these changes before any Phase 1 docs are created

**Estimated effort:** 1 Crumb session (can be combined with the first Phase 1 session).

**Why this is separate:** New architecture docs use these tags in their frontmatter. Without this step, the first commit of any new doc will fail vault-check's pre-commit hook.

#### Phase 1: Architecture Foundation

**Goal:** Produce the five architecture documents. This is the authoritative source that everything else references.

**Sequence:**
1. `00-architecture-overview.md` — write last, but create a stub first for cross-linking
2. `01-context-and-scope.md` — start here; it's the broadest view and anchors everything
3. `02-building-blocks.md` — decomposition of the system into parts
4. `04-deployment.md` — physical topology (do this before runtime views; it grounds the infrastructure)
5. `03-runtime-views.md` — behavioral flows across the deployed infrastructure
6. `05-cross-cutting-concepts.md` — extract from design spec and existing conventions
7. `00-architecture-overview.md` — now fill in the overview with links to all sections

**AI workflow per document:**
1. Crumb session reads the design spec, version history, relevant SKILL.md files, and any existing vault notes on the topic
2. AI drafts the document following the section definition above, synthesizing design intent (from spec) and build history (from version history) into a current-state description
3. AI generates Mermaid diagrams inline
4. Danny reviews the final artifact (not intermediate drafts)
5. Vault-check runs on commit

**Estimated effort:** 3-5 Crumb sessions for all five documents, depending on how much source material needs cross-referencing. The 1M context window means the design spec (~2,600 lines) and version history can be loaded together without context pressure, but each doc will still benefit from a focused session to avoid scope creep.

#### Phase 2: Operator Docs

**Goal:** Produce the Diátaxis-organized operator documentation.

**Sequence — prioritized by operational criticality:**

**First batch (core operations):**
- `reference/skills-reference.md` — highest value; this is the index AI and humans both need
- `reference/vault-structure-reference.md` — foundational for everything else
- `reference/infrastructure-reference.md` — needed for deployment and troubleshooting
- `how-to/vault-gardening.md` — most frequent recurring task

**Second batch (subsystem operations):**
- `how-to/run-feed-pipeline.md`
- `how-to/triage-feed-content.md`
- `reference/sqlite-schema-reference.md`
- `tutorials/mission-control-orientation.md`

**Third batch (onboarding and explanation):**
- `tutorials/first-crumb-session.md`
- `tutorials/first-tess-interaction.md`
- `explanation/how-crumb-thinks.md`
- `explanation/why-two-agents.md`
- `explanation/the-vault-as-memory.md`
- `explanation/feed-pipeline-philosophy.md`

**Fourth batch (remaining reference and how-to):**
- Everything else in the minimum doc set

**Migration batch (run first, before AI drafting):**
Reclassify "keep as-is" docs from the consolidation plan. These are moved and retagged, not redrafted:
- `crumb-deployment-runbook.md` → `operator/how-to/` (satisfies `deploy-openclaw-update.md` scope — see reconciliation note below)
- `vault-gardening.md` → `operator/how-to/` (satisfies `vault-gardening.md` in minimum doc set)
- `Ops/git-commands.md` → `operator/reference/`
- `Ops/tailscale-setup.md` → `operator/how-to/`
- `Ops/tmux-commands.md` → `operator/reference/`
- `Ops/updates-to-an-archived-project.md` → `operator/how-to/`

Each migrated doc must be checked against its Diátaxis quadrant: if it mixes procedure and explanation, split or trim to one quadrant. Docs that pass the check move verbatim; docs that fail are flagged for normalization in a later batch.

**Reconciliation note:** `deploy-openclaw-update.md` (proposed as new) and `crumb-deployment-runbook.md` (reclassified) overlap significantly. Resolution: reclassify the deployment runbook into `operator/how-to/` and expand it to cover OpenClaw-specific upgrade procedures rather than creating a separate doc. Remove `deploy-openclaw-update.md` from the minimum doc set.

**AI workflow per document:**
1. AI reads the relevant architecture section(s) as source
2. AI drafts the document in the appropriate Diátaxis voice (skip for migrated docs — those are already written)
3. For reference docs: AI generates structured entries by scanning vault/code
4. Danny reviews final artifacts in batches, not individually

**Estimated effort:** 5-8 Crumb sessions across all batches (migration batch is lightweight — 1 session).

#### Phase 3: Orientation Map

**Goal:** Produce the LLM orientation tracking layer.

**Sequence:**
1. AI scans the vault for all SKILL.md files, overlays, CLAUDE.md, SOUL.md, IDENTITY.md
2. AI builds the orientation map, linking each to its architecture source section
3. AI identifies gaps (subsystems with no LLM orientation doc)
4. Danny reviews the map and decides which gaps to fill

**Estimated effort:** 1 Crumb session.

**Automation candidate:** The orientation map is the most maintenance-prone artifact in this overhaul. A script that scans `.claude/skills/`, `_system/docs/overlays/`, CLAUDE.md, SOUL.md, and IDENTITY.md to auto-generate the map would reduce ongoing maintenance to near-zero. This is a natural Phase 3 follow-on — build the map manually first, then automate once the format is validated.

### Total estimated effort

9-14 Crumb sessions. At evening/weekend cadence, roughly 2-4 weeks of calendar time.

---

## AI Roles and Constraints

### What AI does

| Role | Description | Quality gate |
|---|---|---|
| First-draft generation | AI writes initial doc from source material | Must follow section templates defined in this plan |
| Diagram generation | AI produces Mermaid diagrams inline | Must render correctly in Obsidian |
| Cross-reference linking | AI adds wikilinks to related vault notes | Must use existing note names, not invent new ones |
| Gap detection | AI identifies missing docs via the orientation map | Flags gaps; doesn't auto-generate filler |
| Staleness detection | AI compares architecture doc timestamps vs. linked operator/LLM docs | Reports staleness; doesn't auto-update |

### What AI does not do

- AI does not decide what to document — the section definitions in this plan are prescriptive
- AI does not create new vault conventions — it follows existing tag taxonomy, MOC patterns, and naming conventions
- AI does not modify existing LLM orientation docs without explicit instruction
- AI does not auto-fill gaps — it reports them for Danny to triage

### Validation model

Danny reviews **final artifacts only**. This means:

- AI must produce complete, publication-ready documents, not outlines or drafts marked "TODO"
- AI must self-check against the section definitions before presenting for review
- If AI is uncertain about a fact (e.g., which port a service runs on, which table a skill writes to), it must flag the uncertainty explicitly in the document rather than guess
- Danny's review is pass/fail per document, not line-by-line editing

---

## Quality Standards

### Every document must have

- YAML frontmatter with tags (per vault convention)
- A single clear purpose statement in the first paragraph
- Wikilinks to related vault notes where they exist
- No orphan links (vault-check enforces this)

### Stability requirement (operator docs)

Operator docs are only written for subsystems whose **interface is stable**, even if internals are still evolving. A stable interface means: the commands, inputs, outputs, and user-facing behavior are unlikely to change in the near term. Subsystems under active interface redesign get a stub entry in the relevant reference doc (noting "interface in flux — doc deferred") rather than a full operator doc that will need rewriting within weeks.

### Architecture docs must additionally have

- At least one Mermaid diagram per section (except cross-cutting concepts, which is prose-primary)
- A short prose summary immediately below each Mermaid diagram describing the key relationships shown, so the document remains usable when Mermaid is not rendered (e.g., in NotebookLM)
- Explicit scope statement: what this section covers and what it doesn't
- Source attribution: which existing vault artifacts informed this section

### Operator docs must additionally have

- Diátaxis quadrant clearly identified (in frontmatter or header)
- For tutorials: expected outcomes at each step
- For how-to: problem statement at the top, "done" criteria at the bottom
- For reference: structured entries (tables or definition lists), not prose paragraphs
- For explanation: no procedural steps — if you're writing steps, it's a how-to

### LLM orientation docs

- Existing conventions apply (CLAUDE.md 200-line budget, SKILL.md nine-section structure, overlays 50-line budget)
- No changes to format; this overhaul only adds the tracking map

---

## Maintenance Model

### When to update

| Trigger | Action |
|---|---|
| New subsystem added | Add architecture section, add to building blocks, add operator how-to, add to orientation map |
| Existing subsystem changed | Update relevant architecture section, check linked operator docs for staleness |
| New skill created | Add to skills-reference.md, add to orientation map |
| Workflow changed | Update relevant how-to, check tutorials for staleness |
| Infrastructure changed | Update deployment section, update infrastructure-reference.md |
| Design principle added/changed | If the change alters enforced conventions or observable patterns, update 05-cross-cutting-concepts; otherwise update only the design spec |
| Architecture or project docs updated | Refresh corresponding Google Drive copies for Project Notebook ingestion (via Tess sync skill on demand) |

### Staleness detection

The orientation map enables a simple staleness heuristic: compare the `updated:` frontmatter field of an architecture section against its linked operator and LLM docs. If the architecture section's `updated` date is newer, the linked docs are candidates for review. Use the YAML frontmatter field, not filesystem mtime — git operations and syncs overwrite mtime, making it unreliable.

This is a heuristic, not a rule: editorial changes to an architecture doc don't necessarily make downstream docs stale, and a matching timestamp doesn't guarantee freshness if the underlying system changed without a doc update.

This can be run as a Crumb session task: "Check the orientation map for stale docs."

### Ownership

Danny owns all documentation. There is no organizational ambiguity to resolve. The "owner" metadata field recommended in the source review is dropped as ceremony debt.

---

## Relationship to Existing Artifacts

| Existing Artifact | Relationship to New Docs |
|---|---|
| Design spec (`crumb-design-spec-v2-4.md`) | Highest-authority document. Describes *design intent* — why the system exists and what it's supposed to be. Architecture docs must be consistent with it. Primary source input for all Phase 1 drafting. Only updated when fundamental intent changes. See "The Three-Document Hierarchy" above. |
| Version history | Proto-ADR and changelog. Describes *when and what changed*. Primary source input for all Phase 1 drafting — tells AI what's been built and in what order. Should reference architecture doc sections when future changes affect system structure. See "The Three-Document Hierarchy" above. |
| CLAUDE.md | Stays in place, stays independent. Orientation map tracks it. |
| SKILL.md files | Stay in place, stay independent. Skills-reference.md indexes them. Orientation map links them to architecture sections. |
| Overlays | Stay in place. Overlays-reference.md indexes them. Orientation map links them. |
| SOUL.md / IDENTITY.md | Stay in place (both at `~/.openclaw/`). Orientation map tracks them. |
| Run-logs | Not promoted into docs (deferred). Remain valuable as session history. |
| MOCs | Continue to function as topic-based navigation. Architecture docs do not replace MOCs; they may be *linked from* MOCs. |
| Vault-check | All new docs must pass vault-check. New tag hierarchy entries (`system/architecture`, `system/operator`, `system/llm-orientation`) will require updates to `file-conventions.md` and vault-check validation rules. |
| Project Notebooks (NotebookLM) | External consumption layer, not a vault artifact. Notebooks source architecture docs, project specs, status artifacts, and session summaries from the vault via Google Drive sync. The vault remains the canonical source; notebooks are downstream consumers and never sources of truth. A Tess skill handles on-demand sync of vault artifacts to Drive for notebook ingestion. Project manifests (curated lists of relevant artifacts per project) are maintained manually in the vault. See the separate Project Notebooks project spec for details. |

### Consolidation Plan

When a new architecture or operator doc absorbs content from an existing doc, the existing doc is handled via the absorb-and-redirect pattern:

1. Content is absorbed into the new canonical doc during drafting
2. The original doc is replaced with a wikilink stub pointing to the new location (e.g., "This content has moved to [[02-building-blocks]]")
3. The original doc's `status` is set to `archived`
4. The stub is moved to `Archived/KB/` per vault-gardening conventions

This consolidation happens during the phase that produces the absorbing doc, not as a separate pass.

| Existing Doc | Disposition | Absorbing Doc |
|---|---|---|
| `system-architecture-diagram.md` | Absorb diagram + key principles table | `01-context-and-scope.md` |
| `tess-crumb-comparison.md` | Absorb: actor definitions → `01-context-and-scope.md`; ownership/routing → `02-building-blocks.md`; personality/voice model → `explanation/why-two-agents.md` | Split across three docs |
| `tess-crumb-boundary-reference.md` | Absorb routing rules and ownership map | `02-building-blocks.md` (ownership map) |
| `attachments/tess-crumb-architecture.md` | Absorb; PNG referenced from new context diagram | `01-context-and-scope.md` |
| `crumb-deployment-runbook.md` | Keep as-is — already a complete operator doc | Reclassify into `operator/how-to/` (it's a how-to, not architecture) |
| `vault-gardening.md` | Keep as-is — already a complete operator doc | Reclassify into `operator/how-to/` |
| `feed-intel-processing-chain.md` + diagram | Absorb pipeline flow description | `03-runtime-views.md` |
| `Ops/git-commands.md` | Keep as-is | Reclassify into `operator/reference/` |
| `Ops/tailscale-setup.md` | Keep as-is | Reclassify into `operator/how-to/` |
| `Ops/tmux-commands.md` | Keep as-is | Reclassify into `operator/reference/` |
| `Ops/notebooklm-digest-import-process.md` | Absorb into broader knowledge-addition doc | `operator/how-to/add-knowledge-to-vault.md` |
| `Ops/updates-to-an-archived-project.md` | Keep as-is | Reclassify into `operator/how-to/` |

**Notes:**
- "Keep as-is" docs are moved (not copied) to their new directory and retagged. No content duplication.
- "Absorb" docs get the full stub-and-archive treatment after their content is incorporated.
- The `Ops/` directory is retired once all contents are reclassified. No new files should be placed there.

---

## Decision Record

Key decisions made during this plan's development, for future reference:

1. **Arc42 cherry-pick:** 5 of 12 sections selected. Excluded sections documented with rationale.
2. **Option B (authoritative source + audience views):** Architecture is the source of truth; operator and LLM docs reference it but are organized for their audiences.
3. **LLM docs stay independent:** Not auto-generated from architecture docs. The orientation map creates traceability without coupling.
4. **Vault placement:** All new docs under `_system/docs/`, extending existing convention.
5. **No ADRs in initial scope:** Can be adopted incrementally later. Architecture docs capture current state; ADRs would capture *decision history*, which is a different (deferred) concern.
6. **No three-view workflow docs in initial scope:** Deferred until architecture docs exist and can anchor them.
7. **Minimal validation bandwidth:** AI produces publication-ready drafts; Danny reviews pass/fail. This puts maximum weight on template precision.
8. **Diátaxis strictly enforced:** Every operator doc belongs to exactly one quadrant. No hybrid docs.
9. **Three-document hierarchy:** Design spec (intent/constitution) → architecture docs (current state) → version history (changelog). Authoritativeness flows downward. Both design spec and version history are primary source inputs for architecture doc drafting.
10. **Project Notebooks are a separate project, not a fourth track:** Notebooks (NotebookLM via Google Drive) are a downstream consumption and presentation layer. They depend on vault artifacts produced by this overhaul but are not part of the documentation architecture itself. The doc overhaul produces canonical sources; notebooks assemble and present them for interactive re-ramping. Architecture docs from Phase 1 serve as the shared foundation layer across all project notebooks.
11. **Section 05 scoped to observable conventions, not restated principles:** The design spec is authoritative for design intent and principles. Section 05 documents what's *currently practiced and enforced* — vault-check rules, naming patterns, token budgets, permission formats. This makes the distinction concrete: spec = intent, 05 = current practice.
12. **Consolidation via absorb-and-redirect:** Existing docs that overlap with new canonical docs are absorbed during drafting, replaced with wikilink stubs, and archived per vault-gardening conventions. The `Ops/` directory is retired.
13. **Stability gate for operator docs:** Operator docs only written for subsystems with stable interfaces. Moving targets get stub entries, not full docs.
14. **Tag taxonomy updates required:** New tags (`system/architecture`, `system/operator`, `system/llm-orientation`) require updates to `file-conventions.md` and vault-check validation.
15. **Orientation map automation as Phase 3 follow-on:** Manual map first, then automate via script once the format is validated.
16. **Phase 0 prerequisite (peer review A1):** Tag taxonomy updates (`file-conventions.md`, `vault-check.sh`) must be committed before any Phase 1 docs, or vault-check will block the first commit.
17. **Consolidation/Phase 2 reconciliation (peer review A2):** "Keep as-is" docs are migrated (not redrafted) in a separate migration batch. Each checked against Diátaxis quadrant rules. `deploy-openclaw-update.md` merged into the reclassified deployment runbook.
18. **Mermaid prose fallbacks (peer review A3):** Every Mermaid diagram gets a prose summary below it for NotebookLM readability.
19. **Authority domains clarified (peer review A4):** Design spec = intent authority, architecture = current-state authority, version history = chronology only.
20. **Staleness detection is a heuristic (peer review A7):** Uses `updated:` frontmatter, not filesystem mtime. Not a rule — editorial changes don't automatically trigger downstream updates.
