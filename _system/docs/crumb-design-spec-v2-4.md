---
project: crumb
domain: software
type: specification
skill_origin: null
status: active
created: 2026-02-14
updated: 2026-03-06
tags:
  - design-spec
  - crumb
---

# crumb — Personal Multi-Agent Operating System
## Revised Design Specification (v2.4)

*This document is self-contained. It describes the complete Crumb system architecture and is intended to allow full reconstruction with no prior knowledge. For version-by-version change history, see [[separate-version-history]] (pre-v2.0: [[separate-version-history-archive]]).*

**Current version: v2.4 (2026-03-06)** — Active Knowledge Memory (QMD semantic retrieval + Knowledge Brief), researcher skill (stage-separated evidence pipeline), 3 new overlays with companion document pattern, feed-pipeline hardening, 15 MOCs.

---

## 0. Purpose & Principles

### 0.1 Goal

Design a **personal multi-agent operating system** that:

- Works across **all life domains** (software, career, health, learning, financial, relationships, creative, spiritual, lifestyle)
- Uses **specialized AI capabilities** (skills, subagents, protocols) orchestrated by Claude Code
- Enforces **spec-first, design-first, plan-first** workflows — calibrated by domain
- Continuously **self-improves** via compound engineering
- Maintains a **single source of truth** for context and memory in an Obsidian vault, accessed via CLI and file tools

### 0.2 Core Principles

1. **One system for everything** — All domains share the same architecture, memory layer, and file conventions.
2. **Plan → Design → Task → Implement → Review → Compound** — Never jump straight to output. Depth of each phase varies by domain.
3. **Specs are the source of truth, not code or chat** — Change specs first, regenerate downstream artifacts.
4. **Every unit of work compounds** — Each task should make future tasks easier.
5. **Teach the system, don't do the work** — Prefer building skills over manual effort.
6. **Risk-tiered human-in-the-loop** — Auto-approve low-risk, flag medium-risk, require approval for high-risk or irreversible actions.
7. **Grounded self-improvement** — Recursive refinement uses external checks (tests, screenshots, validations), never pure self-critique.
8. **Start simple, add complexity when empirically needed** — Resist building capabilities before you've validated the need.

---

## 0.3 Operator Quick-Start

**If you're starting a fresh session, do exactly these steps:**

1. **Start session.** Claude Code opens and runs the session startup sequence (§6): git pull, vault-check, CLI availability check, rotation checks, overlay index load, staleness scan. Review the output for any errors or recommendations.
2. **Identify active project.** The startup output reports active project(s) and current phase. If none, you're in non-project mode — work gets logged to `_system/logs/session-log.md`.
3. **Read last run-log entry.** For project work, read the most recent entry in `progress/run-log.md` (or `project-state.yaml` for phase/task state). For non-project, skim recent `_system/logs/session-log.md` entries if continuing earlier work.
4. **Choose depth.** Are you doing FULL work (new phase, new task, scope change), ITERATION (refining current work), or MINIMAL (quick fix/lookup)? Say it explicitly for the first few weeks: "treat this as MINIMAL triage."
5. **Go.** If FULL: invoke the relevant skill for the current phase. If ITERATION/MINIMAL: just do the work.

**Minimum viable Crumb (what you need before you can trust this):**
`AGENTS.md` · `CLAUDE.md` · `_system/logs/session-log.md` · one project scaffold · `systems-analyst` skill · `obsidian-cli` skill · `vault-check.sh`. Everything else is Phase 1b or later.

**If things feel broken:**
- **Stale or inconsistent state:** Run `_system/scripts/vault-check.sh` manually, then request a full audit. Fix errors before continuing work.
- **Context is high and work is incomplete:** Run the session-end sequence to save state (project-state.yaml + run-log + git commit), then start a fresh session and resume from project-state.yaml.
- **Unclear what phase you're in:** Read `project-state.yaml` first (`next_action` tells you where to pick up), then the last run-log entry for context. If they disagree, trust project-state.yaml for phase/task, trust run-log for what happened, and flag the disagreement.
- **Session crashed mid-work (files on disk but not committed):** Check `git status` for uncommitted files, compare filesystem contents against run-log entries, update run-log and project-state to reflect what's actually on disk, run vault-check to verify structural integrity, commit the reconciled state. See §7.4 Session Interruption Recovery for the full procedure.

---

## 1. High-Level Architecture

### 1.1 Components

| Component | What It Is | Implementation |
|---|---|---|
| **Orchestrator** | The main Claude Code session. Routes work, manages workflow phases, spawns subagents. | CLAUDE.md + routing rules. Claude Code IS the orchestrator — not a separate entity. |
| **Skills** | Procedural expertise packages Claude loads on-demand. | `.claude/skills/[name]/SKILL.md` with YAML frontmatter + optional scripts/references |
| **Subagents** | Independent workers with isolated context windows for heavy design/analysis work. | `.claude/agents/[name].md` with YAML frontmatter |
| **Overlays** | Expert lenses that inject domain expertise into active skills. No procedures of their own. | `_system/docs/overlays/[name].md` — loaded via overlay index routing (§3.4.2) or explicitly by user request |
| **Protocols** | Cross-cutting workflow patterns any skill or the orchestrator can invoke. | Defined in CLAUDE.md, with detailed procedures in referenced files |
| **Shared Context Layer** | Obsidian vault as external memory for all agents. Also serves as a personal knowledge base via tag and backlink discovery. | File conventions from day one; Obsidian CLI for indexed queries when Obsidian is running; native file tools as fallback |

**Key architectural insight:** Claude Code's main session is already an orchestrator. You do not need to build a separate "orchestrator agent" or "delegate mode." CLAUDE.md provides routing rules, skills provide procedures, and subagents provide isolated context for heavy work. Claude's built-in judgment handles delegation.

### 1.2 Domain Routing

Every incoming problem or goal is classified into a **domain**:

`software` · `career` · `learning` · `health` · `financial` · `relationships` · `creative` · `spiritual` · `lifestyle` · `other`

**All domains share** the common workflow phases (§4.1) but at different depths:

| Domain Type | Workflow Depth | Typical Artifacts |
|---|---|---|
| **Software** | Full four-phase (SPECIFY → PLAN → TASK → IMPLEMENT) | Specs, design docs, API contracts, tasks, code |
| **Knowledge work** (career, learning, financial) | Three-phase (SPECIFY → PLAN → ACT) | Specs, action plans, written deliverables |
| **Personal** (health, relationships, creative, spiritual, lifestyle) | Two-phase (CLARIFY → ACT) | Goal definition, routines, reflections |

The orchestrator determines workflow depth based on domain and complexity. CLAUDE.md contains the routing heuristics.

---

## 2. Filesystem & Document Structure

### 2.1 Top-Level Layout

```text
crumb-vault/
├── AGENTS.md                          # Tool-agnostic context (works with any AI)
├── CLAUDE.md                          # Claude Code specific: routing, protocols, boundaries
├── _inbox/                            # Drop zone for manually added files — processed by inbox-processor skill (§3.3)
├── _attachments/                      # Permanent storage for unaffiliated binary files after inbox processing
│   └── [domain]/                      # Organized by domain after processing
│       ├── example-file.pdf
│       └── example-file-companion.md  # Every binary has a colocated companion note (§2.2.1)
├── Sources/                              # Knowledge notes from external sources (NotebookLM pipeline)
│   ├── books/                            # source_type: book
│   ├── articles/                         # source_type: article
│   ├── podcasts/                         # source_type: podcast
│   ├── videos/                           # source_type: video
│   ├── courses/                          # source_type: course
│   ├── papers/                           # source_type: paper
│   ├── other/                            # source_type: other
│   └── signals/                          # Signal-notes from feed-pipeline (§2.2.5)
├── _system/                               # System infrastructure — sorts to top in Obsidian
│   ├── docs/
│   │   ├── estimation-calibration.md
│   │   ├── routing-heuristics.md
│   │   ├── convergence-rubrics.md     # Pre-built dimension sets for non-code convergence
│   │   ├── failure-log.md             # Track all failure types for calibration (§4.8)
│   │   ├── signals-archive-2026.jsonl  # Archived session signals (historical, no longer appended)
│   │   ├── personal-context.md        # Strategic priorities, professional context, working style (§2.4)
│   │   ├── peer-review-config.md      # Model config, retry policy, reviewer addenda
│   │   ├── peer-review-skill-spec.md  # Design spec for peer-review utility skill
│   │   ├── code-review-config.md      # Model config for code-review Tier 2 cloud panel
│   │   ├── review-safety-denylist.md  # Shared secret-scanning denylist (peer-review + code-review)
│   │   ├── kb-to-topic.yaml           # Canonical #kb/ tag → MOC slug mapping (§5.5, §5.6)
│   │   ├── overlays/
│   │   │   ├── overlay-index.md       # Overlay routing table — loaded at session start
│   │   │   ├── business-advisor.md    # Build first as template; see §3.4
│   │   │   └── [additional overlays added incrementally]
│   │   ├── protocols/
│   │   │   ├── session-end-protocol.md      # Session-end sequence (referenced in CLAUDE.md)
│   │   │   ├── bridge-dispatch-protocol.md           # Tess bridge dispatch procedure (referenced in CLAUDE.md)
│   │   │   ├── hallucination-detection-protocol.md   # Full §4.8 procedure (extracted from spec)
│   │   │   └── inline-attachment-protocol.md
│   │   ├── templates/
│   │   │   └── notebooklm/              # NLM pipeline templates and contracts
│   │   │       ├── sentinel-contract.md # Machine-readable NLM export detection spec (§2.2.4)
│   │   │       └── poetry-collection-v1.md  # Poetry collection digest prompt template
│   │   └── solutions/
│   │       ├── frontend-patterns/
│   │       ├── backend-patterns/
│   │       ├── problem-patterns/
│   │       ├── decision-patterns/
│   │       ├── process-patterns/
│   │       └── writing-patterns/
│   ├── logs/
│   │   └── session-log.md             # Non-project interaction history (§2.3.4)
│   ├── scripts/
│   │   ├── vault-check.sh             # External mechanical validation (§7.8)
│   │   ├── session-startup.sh         # SessionStart hook (includes feed-intel inbox scan)
│   │   ├── setup-crumb.sh             # New machine setup
│   │   ├── batch-moc-placement.py     # Batch MOC Core placement for source-index notes
│   │   ├── knowledge-retrieve.sh    # AKM retrieval engine — QMD semantic search + Knowledge Brief (v2.4)
│   │   ├── feed-inbox-ttl.sh        # Feed inbox TTL cleanup for aged items
│   │   └── batch-book-pipeline/       # Batch API pipeline for book digests
│   │       └── generate-source-index.py  # Source-index note generation from knowledge notes
│   └── reviews/                       # Peer-review output — synthesized review notes
│       └── raw/                       # Raw JSON responses from external models (forensic trail)
├── Domains/
│   ├── Career/
│   │   ├── career-overview.md
│   │   ├── moc-dns-architecture.md          # MOC files live in their domain directory (§5.6.4)
│   │   ├── moc-dns-migration-patterns.md
│   │   ├── moc-customer-engagement-patterns.md
│   │   └── [domain-specific notes]
│   ├── Health/
│   ├── Learning/
│   │   ├── learning-overview.md
│   │   ├── moc-crumb-architecture.md
│   │   ├── moc-agent-architecture-research.md
│   │   ├── moc-crumb-operations.md
│   │   └── [domain-specific notes]
│   ├── Financial/
│   ├── Relationships/
│   ├── Creative/
│   │   └── writing/                      # Personal-writing content (AKM v2.4)
│   └── Spiritual/
├── Projects/
│   └── [project-name]/
│       ├── project-state.yaml            # Machine-readable project state (§4.5)
│       ├── specification.md
│       ├── specification-summary.md
│       ├── action-plan.md
│       ├── tasks.md
│       ├── progress/
│       │   ├── progress-log.md
│       │   ├── run-log.md                 # Current month; rotates monthly
│       │   └── run-log-YYYY-MM.md         # Archived months (auto-generated)
│       ├── decisions/
│       │   ├── ADR-001-[slug].md
│       │   └── subagent-decisions.md    # Subagent reasoning and rationale log
│       ├── reviews/                   # Project-scoped peer and code review notes (optional)
│       │   ├── [date]-[slug].md       # Synthesized review notes
│       │   └── raw/                   # Raw JSON responses from external models
│       ├── research/                  # Researcher skill output (created on-demand, v2.4)
│       │   ├── deliverable-[dispatch].md      # research-note or knowledge-note
│       │   ├── fact-ledger-[dispatch].yaml     # Append-with-supersede evidence store
│       │   ├── telemetry-[dispatch].yaml       # Per-dispatch calibration metrics
│       │   ├── sources/                        # Fetched source content
│       │   └── handoff-snapshots/[dispatch]/   # Stage-to-stage handoff JSON
│       ├── attachments/               # Project-scoped binaries with colocated companions (§2.2.1)
│       │   ├── screenshot-[project]-[task]-[slug]-YYYYMMDD.png
│       │   └── screenshot-[project]-[task]-[slug]-YYYYMMDD-companion.md
│       └── design/                    # Software projects only
│           ├── frontend-design.md
│           ├── frontend-design-summary.md
│           ├── backend-design.md
│           ├── backend-design-summary.md
│           ├── data-model.md
│           ├── api-spec.md
│           ├── api-contract.yaml
│           ├── component-architecture.md
│           ├── design-tokens.md
│           └── user-flows.md
├── Archived/
│   └── Projects/                      # Archived projects — see §4.1.6 lifecycle and §4.6 archive/reactivate protocol
└── .claude/
    ├── skills/
    │   ├── systems-analyst/SKILL.md
    │   ├── action-architect/SKILL.md
    │   ├── writing-coach/SKILL.md
    │   ├── audit/SKILL.md
    │   ├── obsidian-cli/SKILL.md      # Vault query routing and safe CLI patterns (§3.1.5)
    │   ├── checkpoint/SKILL.md        # Session state saving and context management (§3.1.6)
    │   ├── sync/SKILL.md              # Git commit and backup operations (§3.1.7)
    │   ├── inbox-processor/SKILL.md   # Phase 2: process manually added files from _inbox/
    │   ├── peer-review/SKILL.md      # Cross-LLM review automation (§3.3, v1.7.1)
    │   ├── code-review/SKILL.md      # Two-tier code review: Sonnet inline (Tier 1) + cloud panel (Tier 2)
    │   ├── excalidraw/SKILL.md       # Freeform diagrams as .excalidraw JSON
    │   ├── mermaid/SKILL.md          # Mermaid diagrams in markdown or .mmd files
    │   ├── lucidchart/SKILL.md       # Lucidchart diagrams via REST API for external sharing
    │   ├── meme-creator/SKILL.md     # Meme images from quotes with movie stills
    │   ├── startup/SKILL.md          # Session startup hook procedures
    │   ├── feed-pipeline/SKILL.md   # Feed intel 3-tier routing to signal-notes (§3.3, v2.3)
    │   ├── researcher/              # Stage-separated evidence pipeline (§3.3, v2.4)
    │   │   ├── SKILL.md
    │   │   ├── stages/              # Stage procedures (01-scoping through 06-writing + validation rules)
    │   │   └── schemas/             # Handoff, fact-ledger, and telemetry templates
    │   └── [additional skills added incrementally]
    └── agents/
        ├── code-review-dispatch.md    # Tier 2 cloud panel dispatch (Opus, GPT-5.2, Devstral)
        ├── peer-review-dispatch.md    # Cross-LLM prose review dispatch
        ├── test-runner.md             # Test suite execution for code review
        └── [additional subagents added incrementally]
```

**Project scaffold note:** Not all files above are created at project initialization. The Project Creation Protocol (§4.1.5) creates the directory, `project-state.yaml`, `run-log.md`, and `progress-log.md`. All other files are created on-demand by the skills that produce them. The `design/` subdirectory is only created for software-domain projects. The `attachments/`, `reviews/`, and `research/` subdirectories are created on-demand — `attachments/` when a project first acquires a binary artifact, `reviews/` when the first peer or code review is written, `research/` when the researcher skill runs its first dispatch for the project.

**Attachment directories:**

Two locations for binary files, distinguished by lifecycle:

- **`_attachments/[domain]/`** — global storage for binaries not tied to a specific project. Personal media, inbound documents where project affiliation is unknown, reference materials. Organized by domain after inbox processing.
- **`Projects/[project-name]/attachments/`** — project-scoped storage for binaries whose lifecycle is coupled to that project: screenshots as convergence evidence, architecture diagrams, customer-provided artifacts used in the project, generated exports. Created on-demand.

**Routing rule:** If a binary is clearly tied to a project, it MUST be placed under that project's `attachments/` directory. Otherwise, it goes under `_attachments/[domain]/`. When a project is archived (moved to `Archived/Projects/`), its `attachments/` directory travels with it.

**Supported binary types:**

| Category | Extensions | Extractable? |
|---|---|---|
| Documents | `pdf`, `docx`, `pptx`, `xlsx` | Yes — text extraction via MarkItDown produces `summary` field |
| Images | `png`, `jpg`, `jpeg`, `gif`, `webp`, `svg` | Partial — EXIF metadata via MarkItDown (no OCR — see §7.9); visual content requires future vision enrichment (§9) |

Audio and video formats are intentionally excluded. If needed, add them with a spec amendment — they introduce storage bloat concerns that warrant deliberate design.

**Binary location constraint:** Binary files with any of the extensions listed above MUST NOT exist outside `_attachments/` or `Projects/*/attachments/` (including `Archived/Projects/*/attachments/`). The `_inbox/` directory is a transient exception — binaries there are awaiting processing. `vault-check.sh` enforces this constraint (§7.8).

### 2.2 File Conventions

**Every note** in the vault that may be queried by agents should follow these conventions from day one:

**YAML Frontmatter** (required on all substantive docs):

**Files under `Projects/` or `Archived/Projects/`** (project docs):

```yaml
---
project: project-name        # required — matches directory name
domain: software              # software | career | health | learning | etc.
type: specification           # specification | design | adr | task | pattern | log | summary | knowledge-note | signal-note | source-index | research-note
skill_origin: systems-analyst # which skill created/owns this doc
created: 2026-02-12
updated: 2026-02-12
topics:                       # MOC membership — required if this file has #kb/ tags (see §5.6.5)
  - moc-dns-migration-patterns
tags:
  - api-design
  - pagination
  - kb/api-design             # knowledge base tag — marks this as durable knowledge (see §5.5)
---
```

**All other files** (`Domains/`, `_system/docs/`, `_system/reviews/`, `_attachments/`, vault root):

```yaml
---
project: null                 # nullable — null for global docs, project-name for affiliated docs
domain: software              # software | career | health | learning | etc.
type: specification           # specification | design | adr | task | pattern | log | summary | knowledge-note | signal-note | source-index | research-note
skill_origin: systems-analyst # which skill created/owns this doc
status: active                # active | archived | draft
created: 2026-02-12
updated: 2026-02-12
topics:                       # MOC membership — required for all #kb/-tagged notes (see §5.6.5)
  - moc-dns-architecture
tags:
  - api-design
  - pagination
  - kb/api-design             # knowledge base tag — marks this as durable knowledge (see §5.5)
---
```

**Why project docs omit `status`:** Project docs inherit their active/archived state from directory location — `Projects/` means active, `Archived/Projects/` means archived (§4.1.6). The `status` field is redundant for these files and creates a consistency burden during archive/reactivate operations (§4.6). Non-project docs retain `status` because they have no container-level lifecycle signal.

**Backward compatibility:** If `status` is present on project docs, it is ignored — not treated as an error. Existing project docs with `status` fields continue to pass vault-check. The field is unnecessary, not prohibited.

**File naming**: kebab-case, descriptive. Summaries use `*-summary.md` alongside the full doc in the same folder.

**Why this matters**: These conventions enable Obsidian CLI queries (property filtering, tag-based search), knowledge base discovery via `#kb/*` tags and backlinks, and potential future MCP integration — all without requiring file restructuring. The Obsidian CLI's native property and tag queries depend on well-formed frontmatter.

#### 2.2.1 Attachment Companion Notes

Every binary file in the vault MUST have a colocated markdown companion note. The companion note is the agent-facing interface — agents cannot see binary content, so the companion note is the only surface through which a binary participates in queries, task references, knowledge base discovery, and audit.

**Companion note naming:** `[binary-filename-without-extension]-companion.md`, colocated in the same directory as the binary. Example: `screenshot-acme-IMPL-003-dns-config-20260217-companion.md` lives alongside `screenshot-acme-IMPL-003-dns-config-20260217.png`.

**Why colocation:** The companion note and its binary must never drift apart. If a project is archived, if files are moved during reorganization, or if a domain directory is renamed, colocation ensures the pair travels together. `vault-check.sh` enforces the bidirectional reference (§7.8).

**Companion note frontmatter (project-scoped example):**

```yaml
---
project: project-name        # or null for global/unaffiliated binaries
domain: software              # software | career | health | learning | etc.
type: attachment-companion    # fixed value — distinguishes from other doc types
skill_origin: inbox-processor # or inline-attachment | manual
created: 2026-02-17
updated: 2026-02-17
tags:
  - needs-description         # present when description is empty or stub; removed once populated
  - kb/networking/dns          # only if promoted to knowledge base (see §5.5)
attachment:
  source_file: Projects/acme-migration/attachments/screenshot-acme-IMPL-003-dns-config-20260217.png
  filetype: png               # file extension without dot
  source: generated           # inbox | generated | external | manual
  size_bytes: 245760
  description_source: null    # null | filename-derived | user-provided | markitdown | vision-api
                              # ocr is reserved/future — EasyOCR was never integrated (see §7.9)
related:
  task_ids:                   # optional — task IDs this binary is evidence for
    - IMPL-003
  docs:                       # optional — vault docs that reference or depend on this binary
    - design/api-spec.md
description: >
  Screenshot of Acme Corp DNS configuration page showing RPZ policy
  enabled with three custom response rules. Captured during IMPL-003
  acceptance criteria validation.
summary: >
  [For text-extractable documents only. Short extract (first ~500 chars)
  from MarkItDown output — enough for search and quick context. Full
  extraction lives in the companion note body under ## Extracted Content.
  Empty or absent for images.]
---
```

**Companion note body:**

```markdown
# [Short descriptive title]

**Purpose:** [One sentence — why this binary exists in the vault]

![[screenshot-acme-IMPL-003-dns-config-20260217.png]]

## Notes
- [Any contextual notes: when captured, what it shows, relevant observations]
- [OCR-extracted text if applicable]

## Extracted Content
[For text-extractable documents only. Full MarkItDown output goes here,
not in frontmatter. This keeps frontmatter clean for queries while making
the full extraction available for deep inspection. Absent for images.]
```

**PDF companion note example:**

```markdown
---
project: acme-migration
domain: software
type: attachment-companion
skill_origin: inbox-processor
created: 2026-02-17
updated: 2026-02-17
tags:
  - kb/networking/dns
attachment:
  source_file: Projects/acme-migration/attachments/inbound-acme-corp-current-dns-export-20260215.pdf
  filetype: pdf
  source: external
  size_bytes: 1843200
  description_source: markitdown
related:
  task_ids:
    - SPEC-001
  docs:
    - specification.md
description: >
  Acme Corp's current DNS zone export covering 3 forward zones and
  2 reverse zones. Contains 847 A records, 12 CNAME records, and
  3 RPZ policy zones.
summary: >
  # DNS Zone Export — Acme Corp (first 500 chars of MarkItDown output
  for frontmatter search; full extraction below)
---

# Acme Corp DNS Zone Export

**Purpose:** Reference document for SPEC-001 — current-state DNS configuration provided by customer.

![[inbound-acme-corp-current-dns-export-20260215.pdf]]

For non-rendering environments: [[inbound-acme-corp-current-dns-export-20260215.pdf]]

## Notes
- Received from Acme IT team on 2026-02-15
- Covers production zones only; lab/staging zones excluded

## Extracted Content
[Full MarkItDown extraction of the PDF goes here — preserving headings,
tables, and structure as markdown. This is the agent-readable version
of the document content.]
```

**Status field in companion notes:** Project-scoped companion notes (under `Projects/*/attachments/` or `Archived/Projects/*/attachments/`) omit `status` — directory location is authoritative (§4.1.6). Global companion notes (under `_attachments/`) retain `status` since they have no project container.

**`description` vs `summary` semantics:** `description` is the short human- or AI-written synopsis used in normal queries, task references, and audit — think of it as what you'd say if someone asked "what is this file?" `summary` is a longer, potentially noisy extraction dump (the full markdown output from MarkItDown) used primarily for deep search and inspection. For text-extractable documents, both fields are populated. For images, only `description` is relevant — `summary` is absent or empty. Agents should prefer `description` for user-facing references and fall back to `summary` only when searching for specific content within a document.

**Field rules:**

| Field | Required? | Text-extractable (PDF, DOCX, etc.) | Non-extractable (images) |
|---|---|---|---|
| `type: attachment-companion` | Always | Always | Always |
| `attachment.source_file` | Always | Always | Always |
| `attachment.filetype` | Always | Always | Always |
| `attachment.source` | Always | Always | Always |
| `attachment.size_bytes` | Always | Always | Always |
| `attachment.description_source` | Always | Set to extraction method | `null` until enriched |
| `description` | Always | Auto-generated from extraction | User-provided, filename-derived, or stub with `needs-description` tag |
| `summary` | Conditional | SHOULD be present; missing → warning + `needs-extraction` tag | MAY be absent |
| `related.task_ids` | Optional | When relevant | When relevant |
| `related.docs` | Optional | When relevant | When relevant |

**Null-vs-absent rule for `attachment.description_source`:** The field MUST exist in frontmatter but MAY have a `null` value. A null value means no description enrichment has occurred yet. vault-check validates field presence, not non-null value. When a description is later added (manually or via tool), update the value to reflect the source (`user-provided`, `markitdown`, `vision-api`, `filename-derived`). (`ocr` is reserved/future — EasyOCR was never integrated; see §7.9.)

**`needs-description` tag:** When a companion note is created with an empty or stub description (common for Path B inbox drops of images), add `needs-description` to the `tags` array. The audit skill flags these during weekly reviews. Remove the tag once a meaningful description is provided. This ensures no image silently persists as an opaque blob.

**`needs-extraction` tag:** When a text-extractable document fails to produce a summary or extracted content (MarkItDown failure, scanned PDF without OCR, corrupted file), add `needs-extraction` to the `tags` array. The audit skill flags these during weekly reviews for re-extraction or manual intervention. This is parallel to `needs-description` — both are quality signals, not structural errors.

**Knowledge base promotion:** Companion notes are promotable to `#kb/` like any other markdown artifact. A well-described architecture diagram or a reference document with a good summary can be durable knowledge. The companion note carries the `#kb/` tag and the backlink from the domain summary — the binary itself is just the rendered content behind the embed.

#### 2.2.2 Binary Filename Conventions

Binary filenames carry queryable context. Since agents cannot see image content, the filename is often the highest-value metadata for zero-cost searchability. All binaries SHOULD follow these naming patterns. When full context isn't available at ingestion time, use the minimal fallback — the inbox processor SHOULD propose the fully-qualified rename when project/task context becomes clear.

**Screenshots and evidence:**
Full: `screenshot-[project]-[task]-[slug]-YYYYMMDD-HHMM.[ext]`
Example: `screenshot-acme-migration-IMPL-003-dns-config-validation-20260217-1430.png`
Minimal fallback: `screenshot-[slug]-YYYYMMDD-HHMM.[ext]` (when project/task unknown at capture time)

**Diagrams and visual design artifacts:**
`diagram-[project]-[slug]-v[NN].[ext]`
Example: `diagram-acme-migration-network-topology-v02.svg`

**Inbound documents (received from external sources):**
`inbound-[source]-[slug]-YYYYMMDD.[ext]` (project/domain segment is optional — include when known)
Example: `inbound-acme-corp-acme-migration-current-dns-export-20260215.pdf`
Example (no project): `inbound-acme-corp-network-overview-20260215.pdf`

**Generated exports (produced by tools during a session):**
`export-[project]-[slug]-YYYYMMDD.[ext]`
Example: `export-personal-site-wireframes-20260220.png`

**Personal/unaffiliated media:**
`[descriptive-slug]-YYYYMMDD.[ext]`
Example: `garden-raised-bed-progress-20260301.jpg`

When the inbox processor handles a file with a non-conforming name, it SHOULD propose a rename following these conventions. The user can accept or override.

#### 2.2.3 File Size Guidance

**Soft threshold: 10MB per file.** When any ingestion path (inbox processor or inline attachment protocol) encounters a file exceeding 10MB, it flags to the user: "This file is [X]MB. Confirm you want to store it in the vault, or consider compressing or linking to external storage." This is guidance, not enforcement — vault-check does not block on file size.

**Vault-check warning:** Files exceeding 10MB in any attachment directory are reported as warnings (not errors). This provides visibility without blocking legitimate large files.

**Aggregate visibility:** The audit skill's weekly review includes total attachment storage (global + per-project breakdown). No threshold — just visibility. When aggregate size becomes a concern, that's the trigger to evaluate compression, archival, or external storage strategies.

#### 2.2.4 Knowledge Notes

Knowledge notes capture synthesized knowledge from external sources (books, articles, podcasts, videos, courses, papers) processed through the NotebookLM pipeline. They live in `Sources/[type]/` and are cross-linked via mandatory `#kb/` tags.

**Frontmatter:**

```yaml
---
project: null                          # or project name if source feeds a specific project
domain: learning                       # primary domain — cross-domain via #kb/ tags
type: knowledge-note
skill_origin: inbox-processor
status: active
created: 2026-02-20
updated: 2026-02-20
tags:
  - kb/philosophy                      # MANDATORY — at least one #kb/ tag
schema_version: 1                      # schema version for forward-compatible evolution
source:
  source_id: kahneman-thinking-fast    # stable slug — see source_id algorithm below
  title: "Thinking, Fast and Slow"
  author: "Daniel Kahneman"
  source_type: book                    # book | article | podcast | video | course | paper | other
  canonical_url: null                  # optional — URL, ISBN, DOI
  notebooklm_notebook: "Kahneman"     # NLM notebook name for traceability
  date_ingested: 2026-02-20
  queried_at: 2026-02-20
  query_template: book-digest-v1
note_type: digest                      # v1: digest | extract
scope: whole                           # see scope enum below
---
```

**source_id algorithm (v1):**
- Base: `kebab(author-surname + short-title)` — e.g., `kahneman-thinking-fast`
- Max length: 60 chars. Allowed chars: `[a-z0-9-]`
- Collision detection: search `Sources/**/*.md` frontmatter for matching `source.source_id`
- Disambiguation: (1) if different source, append `-<publication_year>`; (2) if still collides, append `-<first-4-chars-of-sha256(title)>`
- Raw fields (`title`, `author`, `canonical_url`) always stored for regeneration

**Scope enum:**
- `whole` — entire source
- `chapter:<name>` — e.g., `chapter:07`, `chapter:the-anchoring-effect`
- `section:<id>` — e.g., `section:3.2`
- `timestamp:<range>` — e.g., `timestamp:00:10:00-00:18:30`
- `topic:<name>` — e.g., `topic:attention` (for non-linear media like podcasts)
- Values are lowercase, no spaces, kebab-case within segments

**Source type → directory mapping:**

| `source_type` | Directory |
|---|---|
| `book` | `Sources/books/` |
| `article` | `Sources/articles/` |
| `podcast` | `Sources/podcasts/` |
| `video` | `Sources/videos/` |
| `course` | `Sources/courses/` |
| `paper` | `Sources/papers/` |
| `other` | `Sources/other/` |

**Quality gate:** Notes from low-citation source types (podcast, video) auto-tagged `needs_review`. Removed when user reviews the note.

**Sentinel contract:** NLM exports are detected by a machine-readable sentinel marker in the first 5 lines of the exported file. The sentinel contract (`_system/docs/templates/notebooklm/sentinel-contract.md`) specifies dual format (HTML comment + plain-text fallback), field schema, detection regex, and versioning rules. The inbox-processor skill uses this contract to automatically classify NLM exports and route them to the knowledge-note processing path.

#### 2.2.5 Signal Notes

Signal notes are lightweight, pointer-style knowledge captures from the feed intel pipeline (§3.3). They are not digests — they capture an excerpt, assessment, source link, and traceability back to the original triage item. Signal notes can later be promoted to full `knowledge-note` documents.

**Directory:** `Sources/signals/` (flat — no subdirectory by source type).

**Frontmatter:**

```yaml
---
project: null
domain: learning
type: signal-note
skill_origin: feed-pipeline
status: active
created: 2026-03-01
updated: 2026-03-01
schema_version: 1
source:
  source_id: surname-short-title       # standard source_id algorithm (§2.2.4)
  title: "Article Title"
  author: "Author Name"
  source_type: tweet                    # tweet | article | blog | video | paper
  canonical_url: https://...
  date_ingested: 2026-03-01
  provenance:
    inbox_canonical_id: feed-intel-...  # traceability to original triage item
    triage_priority: high
    triage_confidence: high
topics:
  - moc-slug                            # required — derived from kb-to-topic.yaml
tags:
  - kb/topic                            # at least one #kb/ tag required
---
```

**Body structure:** Signal, Source, Context sections.

**MOC integration:** Signal notes get one-liners in MOC Core sections, same as source-index notes.

**Promotion path:** When a signal note is later promoted to a full knowledge note, the `source_id` stays stable — the file is replaced, not duplicated.

#### 2.2.6 Source-Index Notes

Source-index notes are per-source landing pages that aggregate all knowledge notes (digests, extracts, signal notes) for a single source. They are the canonical MOC entry point — one source = one MOC one-liner, regardless of how many child notes exist.

**Directory:** Colocated with child knowledge notes (e.g., `Sources/books/`).

**Naming:** `[source_id]-index.md`

**Frontmatter:**

```yaml
---
project: null
domain: learning
type: source-index
skill_origin: inbox-processor           # or batch-book-pipeline
status: active
created: 2026-03-01
updated: 2026-03-01
schema_version: 1
source_type: book                       # book | article | podcast | video | course | paper | other
source_id: kahneman-thinking-fast
scope: full                             # full | partial | chapter | section
topics:
  - moc-psychology
tags:
  - kb/psychology
---
```

**Body structure:** Header, Overview (from Core Thesis of child digest), Notes table (links to all child knowledge notes), Reading Path, Connections.

**Production paths:** Created by inbox-processor (Step 4j) during NLM export processing, or by `generate-source-index.py` during batch pipeline runs.

### 2.3 Key Document Functions

| Document | Purpose | Phase |
|---|---|---|
| `AGENTS.md` | Tool-agnostic context for all AI tools (Cursor, Copilot, etc.) | Always |
| `CLAUDE.md` | Claude Code routing, protocols, gates, behavioral boundaries | Always |
| `_system/logs/session-log.md` | Non-project interaction history with compound step integration. See §2.3.4 for format. | Always |
| `specification.md` | Problem definition + systems analysis | SPECIFY |
| `specification-summary.md` | Compressed version for downstream skills | SPECIFY |
| Design docs (`frontend-design.md`, `api-spec.md`, etc.) | Technical design artifacts | PLAN |
| `action-plan.md` + `tasks.md` | Milestones and atomic tasks with acceptance criteria | TASK |
| `run-log.md` | Detailed session-by-session activity log for resume and debugging. See §2.3.1 for format. | Always |
| `progress-log.md` | High-level milestone tracking for weekly reviews and project overview. See §2.3.2 for format. | Always |
| `subagent-decisions.md` | Subagent reasoning log documenting options, analysis, and rationale. See §2.3.3 for format. | PLAN (when subagents used) |
| `_system/docs/solutions/*` | Reusable patterns extracted from completed work | Compound |
| `_system/docs/convergence-rubrics.md` | Pre-built dimension sets for non-code quality assessment | Always |
| `_system/docs/failure-log.md` | Track all failure types (hallucination, routing, scope, quality) for calibration. See §4.8. | Always |
| `_system/docs/signals-archive-2026.jsonl` | Archived session signals (historical data, no longer appended). See §4.9. | N/A |
| `_system/docs/personal-context.md` | Strategic priorities, professional context, and working style preferences. See §2.4. | Always |
| `_system/docs/overlays/overlay-index.md` | Overlay routing table — maps activation criteria to overlay files. Loaded at session start. See §3.4.2. | Always |

#### 2.3.1 Run Log Format

`run-log.md` tracks detailed session activity for observability and resume capability.

**Rotation Policy:**

Run logs rotate monthly to prevent unbounded growth. The current month's log is always `run-log.md`. At the start of a new month:

1. Rename current `run-log.md` to `run-log-YYYY-MM.md` (e.g., `run-log-2026-02.md`)
2. Create a fresh `run-log.md` with a rotation header:

```markdown
# Run Log

**Previous log:** run-log-YYYY-MM.md ([brief summary: N sessions, key milestones])
**Rotated:** YYYY-MM-DD
```

3. Archived run logs stay in the `progress/` directory alongside the current log

**When to rotate:** The session-start staleness scan (§3.1.4) checks whether the current month has changed since the first entry in `run-log.md`. If so, rotate before proceeding. This means rotation happens automatically at the first session of each new month.

**Reading convention:** For resume and audit purposes, only the current `run-log.md` needs to be loaded. Archived logs are reference material — load them only when investigating a specific past session or decision.

**Structure:**

```markdown
## Session: YYYY-MM-DD HH:MM - HH:MM

**Context:** [Brief description of what this session is about]

**Routing Decision:** (when entering a formal workflow)
- Domain: [domain]
- Workflow: [full four-phase | three-phase | two-phase]
- Rationale: [why this workflow and domain]
- Skill: [skill invoked]
- Overlays matched: [overlay names and triggering signals, or "none"]
- Overlays skipped: [overlay names considered but not loaded, or "none"]

**Actions Taken:**
- [Action 1 with outcome]
- [Action 2 with outcome]
- [Action 3 with outcome]

**Validation:** (when reviewing subagent/skill outputs)
- Reviewed: [subagent/skill name] output ([file names])
- Checked: [rubric dimensions used, e.g., Completeness, Clarity, Actionability]
- Result: [all dimensions adequate | issues found]
- Issues: [any issues accepted or deferred, or "none"]

**Decisions Made:**
- [Decision 1 with rationale]
- [Decision 2 with rationale]

**Current State:**
- Active task: [task ID and description]
- Blocked on: [anything blocking progress, or "none"]
- Next steps: [what should happen next]

**Files Modified:**
- [file 1]
- [file 2]

**Context Usage:** [X]%
```

**Example:**

```markdown
## Session: 2026-02-12 14:30 - 16:45

**Context:** Backend API design phase (PLAN)

**Actions Taken:**
- Spawned Backend Designer subagent for API design
- Subagent generated backend-design.md, api-spec.md, data-model.md
- Reviewed subagent outputs

**Validation:**
- Reviewed: Backend Designer output (backend-design.md, api-spec.md, data-model.md)
- Checked: Completeness, Clarity, Actionability (from convergence-rubrics.md)
- Result: All dimensions adequate
- Issues: Minor inconsistency in error response format (accepted, will standardize during implementation)

**Decisions Made:**
- Use PostgreSQL instead of MongoDB (better ACID guarantees for user data)
  [Decision from Backend Designer subagent, see decisions/subagent-decisions.md]
- API versioning via URL path (/v1/endpoint)
- Store refresh tokens in Redis with 7-day expiry

**Current State:**
- Active task: Complete backend design (95% complete)
- Blocked on: none
- Next steps: Move to TASK phase, create implementation tasks

**Files Modified:**
- design/backend-design.md
- design/api-spec.md
- design/data-model.md
- decisions/subagent-decisions.md

**Context Usage:** 68%
```

**Usage:**
- Write entry at end of each session (before ending or when switching tasks)
- Critical for resume — provides exact context for vault-based state reconstruction
- Read most recent entry when resuming to understand current state
- Only load current `run-log.md` for resume/audit; load archived logs only for specific investigations

#### 2.3.2 Progress Log Format

`progress-log.md` tracks major milestones and project progress over time.

**Structure:**

```markdown
## YYYY-MM-DD

- ✅ [Completed milestone]
- 🚧 [In progress milestone] ([X]% complete)
- ⏸️ [Blocked milestone] (blocked on: [reason])
- ❌ [Cancelled milestone] (cancelled: [reason])
```

**Example:**

```markdown
## 2026-02-12
- ✅ Completed specification phase
- ✅ Completed frontend design
- 🚧 Backend design in progress (60% complete)

## 2026-02-10
- ✅ Project kickoff
- ✅ Initial systems analysis
```

**Usage:**
- Update when major milestones complete (phase transitions, major features)
- Not every session needs an entry (only significant progress)
- Used for weekly reviews and high-level project overview

#### 2.3.3 Subagent Decisions Log Format

`subagent-decisions.md` tracks subagent reasoning for significant decisions made during design phases.

**Purpose:**
- Capture WHY decisions were made, not just WHAT was decided
- Preserve subagent reasoning for future reference and resume
- Enable main session and future agents to understand trade-offs

#### Architecture Decision Records (ADRs)

For decisions that change the system's structure — not just subagent design choices, but any decision that modifies specs, adds constraints, or changes architectural direction — create a standalone ADR in `decisions/`.

**When to write an ADR:**
- Spec changes that add, remove, or significantly modify a requirement
- Architectural decisions that constrain future work (technology choices, pattern adoptions, integration approaches)
- Decisions where multiple viable options existed and the reasoning for the chosen option should persist
- Any decision the user or Claude explicitly calls out as worth recording

**ADR format:**
```markdown
---
project: [project-name]
domain: [domain]
type: adr
status: active       # active | superseded | deprecated
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - adr
  - [topic tags]
---

# ADR-[NNN]: [Decision Title]

## Status
[Active | Superseded by ADR-NNN | Deprecated]

## Context
[What situation or problem prompted this decision?]

## Options Considered
1. [Option 1] — [brief description]
2. [Option 2] — [brief description]

## Decision
[What was decided and why]

## Consequences
[What changes as a result? What trade-offs were accepted?]
```

**Naming:** `decisions/ADR-001-[slug].md` — sequential numbering within the project.

**Spec evolution ADRs:** When a user-driven decision modifies the spec (not just downstream artifacts), the ADR should reference the spec section(s) changed and briefly capture the before/after. This fills the gap where specs accumulate implicit decisions that lose their reasoning history over time.

**Structure:**

```markdown
## [Subagent Name] - [Task Description] ([Date])

**Task:** [Brief description of what subagent was asked to do]

**Options Considered:**
1. [Option 1]
2. [Option 2]
3. [Option 3]

**Analysis:**
- [Option 1]: [Pros and cons]
- [Option 2]: [Pros and cons]
- [Option 3]: [Pros and cons]

**Decision:** [Chosen option]

**Rationale:**
- [Reason 1]
- [Reason 2]
- [Reason 3]

**Trade-offs Accepted:**
- [Trade-off 1]
- [Trade-off 2]

**Validation Notes:**
[Added by main session during validation]
- Review status: [Approved | Approved with caveats | Needs revision]
- Reviewer notes: [Any concerns or caveats]
```

**Example:**

```markdown
## Backend Designer - API Design Session (2026-02-12)

**Task:** Design REST API for user management

**Options Considered:**
1. REST with JSON
2. GraphQL
3. gRPC

**Analysis:**
- REST: Familiar to team, simple, excellent tooling, widely supported
- GraphQL: Flexible queries, reduces over-fetching, but adds complexity and requires new tooling
- gRPC: High performance, strong typing, but limited browser support and steep learning curve

**Decision:** REST with JSON

**Rationale:**
- Team familiarity: No GraphQL or gRPC experience on team
- Client needs: Browser-based application benefits from REST simplicity
- Performance adequate: Not high-volume traffic, REST latency acceptable
- Development speed: REST enables faster iteration with existing tooling

**Trade-offs Accepted:**
- Less flexible querying than GraphQL (may need multiple endpoints for complex queries)
- Potential over-fetching compared to GraphQL
- Manual API versioning required (no automatic schema evolution)

**Validation Notes:**
- Review status: Approved
- Reviewer notes: Rationale is sound given team constraints and project timeline. Revisit if traffic exceeds 10k requests/min.
```

**Usage:**
- Subagents write this WHILE making significant decisions during design work
- Main session reads this DURING validation to understand reasoning
- Include validation notes after review
- Future agents/sessions reference this to understand WHY decisions were made

#### 2.3.4 Session Log Format

`_system/logs/session-log.md` captures non-project interactions — any session where meaningful work happens outside a formal project workflow. This ensures ad-hoc work leaves a vault trace and feeds the compounding system, consistent with Principle 4 ("Every unit of work compounds").

**What gets logged here:**
- Conversational brainstorms, research, or analysis not tied to a project
- Quick deliverables (emails, one-off documents, ad-hoc tasks)
- Interactions that started informally and didn't cross the workflow entry threshold
- Sessions where project creation was offered but declined

**What does NOT get logged here:**
- Work within a formal project workflow — that goes in the project's `run-log.md`
- Trivial interactions (greetings, single-question lookups, quick clarifications) — use judgment; if there's nothing to compound and no meaningful record to keep, skip the entry

**Structure:**

```markdown
## YYYY-MM-DD HH:MM — [Brief description]

**Domain:** [software · career · learning · health · financial · relationships · creative · spiritual · lifestyle]
**Summary:** [2-3 sentences: what was discussed, what was produced, any decisions made]
**Compound:** [insight summary and routing destination, OR "No compoundable insights"]
**Promote:** [no | declined — [brief reason] | project proposed: [name]]
```

**Example (with compound insight):**

```markdown
## 2026-02-14 10:15 — Customer email strategy for Acme renewal

**Domain:** career
**Summary:** Drafted renewal outreach email for Acme Corp. Discussed timing strategy relative to their budget cycle. Produced final email copy sent to customer.
**Compound:** Email timing relative to customer budget cycles is a repeatable pattern. Routed to _system/docs/solutions/process-patterns/customer-budget-cycle-timing.md (confidence: low, single instance).
**Promote:** no
```

**Example (project creation declined):**

```markdown
## 2026-02-14 14:30 — Research on container orchestration options

**Domain:** software
**Summary:** Compared Kubernetes vs. Nomad vs. ECS for potential microservices migration. Produced comparison matrix. No decision made yet — need cost data.
**Compound:** No compoundable insights
**Promote:** declined — not ready to commit to a migration project; revisit after Q3 cost review
```

**Rotation:** Session log rotates monthly using the same mechanism as project run-logs (§2.3.1). Current month is always `session-log.md`. Archived months renamed to `session-log-YYYY-MM.md`. All session-log files live in `_system/logs/`.

**Compound integration:** Before ending any non-project session that produced meaningful work, Claude evaluates the compound step trigger criteria (§4.4) and records the result in the `Compound` field. This is behavioral — there are no phase transitions to hook into for structural enforcement — but the vault integrity script (§7.8) provides a mechanical safety net: it checks that every session-log entry with a non-empty `Summary` field also has a `Compound` field, flagging entries where the evaluation was skipped entirely.

**Resume:** The session-log does not support formal resume (the vault-based resume procedure reads project `run-log.md` per §7.1). Non-project interactions are lightweight by definition — below the workflow entry threshold. If an interaction needs resume capability (current state, next steps, context reconstruction), that's a signal it should be a project. Use the Project Creation Protocol (§4.1.5) to formalize it.

**Escalation integration:** If an interaction crosses the workflow entry threshold (§4.1) mid-conversation, Claude prompts the user to create a project via the Project Creation Protocol (§4.1.5). If declined, the `Promote` field records the decision. See §4.1.5 for the full escalation and creation flow.

### 2.4 Personal Context Document

`_system/docs/personal-context.md` provides standing context that skills load when evaluating trade-offs, making strategic recommendations, or interacting with the user. It serves a similar function to a system prompt — shaping how Crumb behaves — but lives in the vault where skills can reference it explicitly.

**Three sections, each functional:**

**Strategic Priorities** — What you're optimizing for in the current 6-12 month window. Key goals, focus areas, constraints, and what you're explicitly *not* pursuing. This is the highest-value content: it directly informs trade-off decisions in systems-analyst, overlay evaluations, and action-architect task prioritization.

**Professional Context** — Role, responsibilities, key relationships, what your work involves. Gives skills grounding without having to infer it from conversational cues every session. Distinct from AGENTS.md (which is tool-configuration for any AI) — this is richer context about the work itself.

**Working Style** — How you want the system to interact with you. Communication preferences, decision-making style, what kind of pushback you value, anti-patterns to avoid. This shapes the *experience* of using Crumb without adding personality to the system architecture.

**Structure:**

```markdown
---
type: reference
domain: null
skill_origin: null
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - personal-context
  - system-config
---

# Personal Context

## Strategic Priorities
[Current 6-12 month focus, key goals, constraints, explicit non-goals]

## Professional Context
[Role, responsibilities, key relationships, what the work involves]

## Working Style
[Communication preferences, decision-making style, valued pushback, anti-patterns]
```

**Target length:** Under 50 lines. This is reference context, not a biography. Every line should change how a skill behaves.

**Who consumes it:**
- **Systems-analyst:** Loads when evaluating trade-offs during SPECIFY. Strategic priorities inform scope decisions and problem framing.
- **Overlays:** Reference when applying lens questions — e.g., business-advisor overlay uses strategic priorities to evaluate alignment.
- **Action-architect:** MAY load when prioritizing tasks — strategic priorities inform sequencing decisions.
- **Audit skill:** References during monthly review to check whether recent work aligns with stated priorities.
- **Writing-coach:** MAY load working style section when the task involves communication tone or style decisions.

**Context budget:** Does not count against source document budget tiers (§5.4). Like overlays, this is instructional context — small, stable, and loaded for behavioral shaping rather than as source material for analysis.

**Maintenance:** Monthly audit includes the question: "Are the priorities in `personal-context.md` still current?" Strategic priorities shift more frequently than professional context or working style. Update when priorities change; don't wait for the monthly audit if a significant shift happens mid-cycle.

**Loading convention:** Skills that consume this document include it in their context contract as MAY-load, not MUST-load. Load when the task involves strategic trade-offs, recommendations, or communication style decisions. Skip for straightforward execution tasks where personal context doesn't change the output.

---

### 2.5 Binary Attachment Protocol

Binaries enter the vault through four paths. All paths converge on the same outcome: binary stored in the correct directory, companion note created, references written where appropriate.

#### Path A — Created during a governed Claude Code session (project context known)

Any skill or workflow that produces a binary artifact during a governed project session MUST follow this protocol:

1. **Save file** to `Projects/[project-name]/attachments/` using the filename convention from §2.2.2.
2. **Create companion note** colocated with the binary. Populate all fields — project, domain, task linkage, and description are all available from the active session context. Set `attachment.source: generated`.
3. **Log the attachment** in the current run-log entry under `**Files Modified:**`.
4. **Reference from task** (if applicable): If the binary is evidence for a specific acceptance criterion, note the companion note path in the task's run-log context.

This path bypasses `_inbox/` — no classification needed because the session already has full context. This is the highest-signal ingestion path.

#### Path B — Dropped in `_inbox/` with no context (async, manual)

The inbox-processor skill handles this:

1. **Detect file type** from extension.
2. **Classify domain** from filename, user input, or heuristic (prompt user if ambiguous).
3. **Determine project affiliation** using this precedence ladder (first match wins):
    1. User-provided project override (explicit parameter or conversational instruction)
    2. Filename match — project slug appears in the filename (e.g., `screenshot-acme-migration-...`)
    3. Active project context — if the inbox processor runs during a project session, the active project is the default
    4. No match → `project: null`, route to `_attachments/[domain]/`
4. **Route binary:**
    - Text-extractable (PDF, DOCX, etc.): move to appropriate attachments directory (project or global per step 3), run MarkItDown extraction, write short summary to frontmatter and full extraction to `## Extracted Content` in companion note body.
    - Images: move to appropriate attachments directory, extract EXIF metadata via MarkItDown (no OCR — see §7.9), create companion note with metadata.
5. **Propose filename rename** if the current name doesn't follow §2.2.2 conventions.
6. **Tag `needs-description`** (images without meaningful description) or **`needs-extraction`** (extractable documents where MarkItDown fails) as appropriate. Don't block on it — an imperfect companion note is better than an untracked binary.

#### Path C — External file, project-affiliated (user knows the project)

Functionally a variant of Path B where the user explicitly specifies the project (precedence ladder step 1). The inbox processor routes accordingly:

1. Route binary to `Projects/[project-name]/attachments/` instead of `_attachments/[domain]/`.
2. Companion note is created in the project's `attachments/` directory with `project` field populated.
3. If the user provides task IDs, populate `related.task_ids`.

#### Path D — Placed directly into a project's `attachments/` directory (manual)

The user drops a file directly into `Projects/[project-name]/attachments/` outside of a Claude Code session (e.g., via Finder/Explorer, or from another tool).

1. **Orphan detection:** The session-start staleness scan (or vault-check pre-commit hook) flags binary files in any `attachments/` directory that lack a companion note.
2. **Companion creation:** The user requests companion note creation, or the inbox processor's orphan sweep handles it. The companion note is created with `attachment.source: manual` and `needs-description` tag.
3. **Filename convention:** If the file doesn't follow §2.2.2, suggest a rename during companion creation.

#### Re-routing (project affiliation discovered after initial processing)

When a binary initially processed to `_attachments/[domain]/` is later identified as belonging to a project:

1. Move the binary from `_attachments/[domain]/` to `Projects/[project-name]/attachments/`.
2. Move the companion note alongside it.
3. Update the companion note's `attachment.source_file` path and `project` field.
4. Remove the `status` field (project-scoped companions omit it per §4.1.6).
5. vault-check catches broken `source_file` references, so this operation must be atomic (move both files and update the path in one step).

**Post-condition check:** verify binary + companion exist at new path, `source_file` resolves, `status` absent.

The inbox-processor skill is idempotent for partially-processed files: interrupted move recovery detects companion notes written before the binary was moved, and Path D catches binaries moved without companion notes.

---

## 3. Skills, Subagents & Protocols

### 3.0 Primitive Selection Guide

Not everything is a skill. Use the right Claude Code primitive for the job:

| Primitive | Use When | Characteristics |
|---|---|---|
| **Skill** (`.claude/skills/`) | Repeatable procedure Claude should follow. Loaded on-demand based on description match. | Instructions in SKILL.md. Runs in main session context. Progressive disclosure via reference files. |
| **Subagent** (`.claude/agents/`) | Heavy work needing isolated context. Produces verbose output you don't need in main context. | Own context window. Returns summary to main session. Can use skills. |
| **Protocol** (in CLAUDE.md or referenced file) | Cross-cutting workflow pattern used across skills. | Not a standalone entity. Invoked by skills or orchestrator. |
| **Overlay** (`_system/docs/overlays/`) | Domain expertise or contextual lens applied to another skill's work. | Loaded automatically via overlay index when activation signals match (§3.4.2), or explicitly by user request. Adds lens questions to active skill's procedure. |

### 3.1 Phase 1 Skills (Build First)

Start with these 7 core skills. `systems-analyst` and `action-architect` are built in Phase 1a (Day 1). `writing-coach` and `audit` are built in Phase 1b (Days 2-5) when their triggers fire. `obsidian-cli`, `checkpoint`, and `sync` are utility skills built as needed. All skills follow the section conventions in `_system/docs/skill-authoring-conventions.md`. The authoritative content for each skill lives in its SKILL.md file — the summaries below capture phase context, key inputs/outputs, and cross-references.

#### 3.1.1 Systems Analyst

**File:** `.claude/skills/systems-analyst/SKILL.md`

- **Phase:** SPECIFY
- **Inputs:** User's problem/goal description, relevant domain summary
- **Outputs:** `specification.md` (with frontmatter `type: specification`, `skill_origin: systems-analyst`), `specification-summary.md`
- **Key behavior:** Gathers context via Obsidian CLI, searches `_system/docs/solutions/` for prior art matching the problem domain, runs signal scan of `Sources/signals/`, `Sources/insights/`, and `Sources/research/` filtered by `#kb/` tags with noise gate (budget-exempt), checks overlay index, clarifies through ≤5 questions, conducts first-principles analysis (problem statement, facts/assumptions/unknowns, system map, domain classification, task decomposition)
- **Compound behavior:** Routes recurring problem shapes to `_system/docs/solutions/problem-patterns/`
- **Convergence dimensions:** Completeness, Clarity, Actionability
- **Context contract:** Standard tier (2-4 docs) for new projects; extended tier (6-7 docs) for iteration passes. MAY request: prior art from `_system/docs/solutions/` matching the problem domain or tech stack

#### 3.1.2 Action Architect

**File:** `.claude/skills/action-architect/SKILL.md`

- **Phase:** TASK
- **Inputs:** Approved specification (summary), approved design docs (summaries) if applicable
- **Outputs:** `action-plan.md` (H2 milestones, H3 phases), `tasks.md` (markdown table: id, description, state, depends_on, risk_level, domain, acceptance_criteria), `action-plan-summary.md`
- **Key behavior:** Checks overlay index, runs signal scan of `Sources/signals/`, `Sources/insights/`, and `Sources/research/` filtered by `#kb/` tags with noise gate (budget-exempt, focused on implementation patterns), searches `_system/docs/solutions/` for implementation patterns matching the tech stack and architecture, scopes tasks by file-change footprint and context budget (≤5 file changes per task), enforces dependency graph, assigns risk levels feeding approval gate model (§4.3)
- **MUST have (software projects):** In addition to design summaries, load **Constraints**, **Requirements**, and **Interfaces/Dependencies** sections from each full design doc (targeted partial reads). If these sections don't exist as distinct headings, load first and last sections as proxy. Targeted reads count as one doc each for budget purposes.
- **Compound behavior:** Track estimate vs actual → `_system/docs/estimation-calibration.md`
- **Convergence dimensions:** Coverage, Dependency correctness, Risk calibration
- **Context contract:** Standard tier (3-5 docs) for simple projects; extended tier (5-7 docs) for software projects with multiple design docs. MAY request: implementation patterns from `_system/docs/solutions/` matching the tech stack or architecture

#### 3.1.3 Writing Coach

**File:** `.claude/skills/writing-coach/SKILL.md`

- **Phase:** On any written output
- **Inputs:** The text to improve + intended audience/purpose
- **Outputs:** Revised text with explanation of changes
- **Key behavior:** Checks overlay index, applies tiered convergence (§4.2) with lightweight rubric, preserves author's voice while improving structure and clarity. Stops when all dimensions adequate, or 2 iterations without meaningful improvement, or human says "good enough"
- **Compound behavior:** Build personal style guide in `_system/docs/solutions/writing-patterns/`
- **Convergence dimensions:** Audience fit, Structure, Brevity
- **Context contract:** Standard tier (1-3 docs) — text plus optional style guide and rubric

#### 3.1.4 Audit

**File:** `.claude/skills/audit/SKILL.md`

- **Phase:** Maintenance (cross-cutting)
- **Inputs:** Vault state (summaries, tasks, solutions, failure log, session signals)
- **Outputs:** Audit report with findings and actions taken; updates to vault files as needed
- **Key behavior:** Operates at three tiers:

  - **Session-start staleness scan** (automatic): rotation checks, overlay index loading, summary freshness, audit cadence check
  - **Full audit — weekly** (user-initiated or recommended): summary spot-checks, solution consolidation, task pruning, signal analysis with escalation responses, knowledge base health check
  - **Full audit — monthly** (in addition to weekly): project archiving, skill activation patterns, CLAUDE.md drift check, overlay precision review, human-grounded validation
- **Action classification:** Low-risk actions (summary regen, task pruning) taken directly; medium/high-risk actions (archiving, rubric changes, skill/overlay modifications) flagged for human review
- **Compound behavior:** Track audit findings over time; escalate recurring findings as system design issues
- **Convergence dimensions:** Coverage, Accuracy, Actionability
- **Context contract:** MUST have vault structure access; MAY request specific project files, failure log, signals, solutions listing; AVOID loading all vault files simultaneously

#### 3.1.5 Obsidian CLI

**File:** `.claude/skills/obsidian-cli/SKILL.md`

- **Phase:** Cross-cutting (used by all skills that query the vault)
- **Purpose:** Provide reliable, token-efficient vault access using Obsidian's native index. Other skills call through this skill's patterns for vault queries rather than invoking CLI commands directly.
- **Key behavior:**
  - **Routing:** Use CLI for index-powered operations (search, backlinks, tags, properties, orphans); use file tools for direct read/write or when Obsidian is not running
  - **Safe patterns:** `silent` flag on create, `all` scope for vault-wide queries, `format=json matches` for search, `format=tsv` for properties, defensive output parsing
  - **Risk alignment:** Low risk (read operations), Medium risk (create/append/move), High risk (delete/eval)
- **Compound behavior:** Track CLI usage patterns; flag recurring failures for documentation updates
- **Convergence dimensions:** Correctness, Efficiency, Robustness
- **Context contract:** MUST have the query/operation; MAY request scope parameters; AVOID unbounded vault-wide queries

#### 3.1.6 Checkpoint

**File:** `.claude/skills/checkpoint/SKILL.md`

- **Phase:** Session management (cross-cutting)
- **Inputs:** Current session state, context usage level
- **Outputs:** Progress snapshot in run-log/session-log, context health report
- **Key behavior:** Logs current state, checks context usage (`/context`), manages context pressure (compact at >70%, clear+reconstruct at >85%), verifies all critical outputs are persisted to vault
- **Compound behavior:** Track context usage patterns at checkpoint time to calibrate future phase-scoping decisions
- **Convergence dimensions:** Completeness, Durability
- **Context contract:** Minimal — reads small state files only; avoids loading additional context

#### 3.1.7 Sync

**File:** `.claude/skills/sync/SKILL.md`

- **Phase:** Session management (cross-cutting)
- **Inputs:** Git repository state
- **Outputs:** Git commit, optionally push to remote and/or trigger backup
- **Key behavior:** Verifies vault state, checks git status, creates commit with conventional message (staging specific files, not `git add -A`), optionally pushes and triggers cloud backup
- **Compound behavior:** Track sync patterns to identify lost uncommitted work across sessions
- **Convergence dimensions:** Completeness, Safety
- **Context contract:** Minimal — operates on filesystem, not vault content

### 3.2 Subagents — Actual Roster

Subagents are defined in `.claude/agents/`. They provide isolated context workers for tasks that benefit from separation from the main session.

**Current agents (as of v2.4):**

#### 3.2.1 Code Review Dispatch (`code-review-dispatch.md`)

Dispatches Tier 2 cloud panel reviews. Sends diff content to 3 external models (Claude Opus, GPT-5.2, Devstral Medium) via API, collects structured findings, and writes synthesized review notes to `Projects/[project]/reviews/`. Used by the code-review skill for diffs exceeding the Tier 1 chunk threshold or when Tier 2 depth is warranted.

#### 3.2.2 Peer Review Dispatch (`peer-review-dispatch.md`)

Dispatches prose artifact reviews to the 4-model peer review panel (GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning) via API. Returns synthesized review notes to `_system/reviews/` or `Projects/[project]/reviews/`. Used by the peer-review skill.

#### 3.2.3 Test Runner (`test-runner.md`)

Executes test suites in external repos for code review scoping. Runs `npm test` (or equivalent) and returns pass/fail counts and failure summaries to the main session. Used by the code-review skill to establish test baseline before and after changes.

#### 3.2.4 Subagent Revision Protocol

When the main session's validation finds **specific, actionable issues** with subagent output — not vague quality concerns — it can spawn a single revision pass before escalating to the human gate:

1. **Write structured feedback** — main session creates `decisions/subagent-revision-{agent-name}.md` containing: which output files need changes, specific issues found (with section/line references where possible), and what "adequate" looks like for each issue.
2. **Spawn revision subagent** — a new instance of the same subagent type, with context contract:
    - MUST: the original output files, the revision feedback file, the original spec summary
    - MUST NOT: the original subagent's conversation or reasoning process — only artifacts and feedback
3. **One pass only** — if the revision output still doesn't pass validation, escalate to the human gate. No recursive revision loops.
4. **Log the revision** — append a revision entry to `decisions/subagent-decisions.md` documenting what was flagged, what changed, and the final validation outcome.

**Phase 2+ backlog agents (build when needed):**

| Candidate | Trigger |
|---|---|
| Frontend Designer | Software project requires UI/UX design, component architecture, or design systems work |
| Backend Designer | Software project requires API design, database modeling, or service architecture work |

### 3.3 Phase 2+ Skills (Add Incrementally Based on Need)

**Do not build these until you have empirical evidence they're needed.** New skill candidates discovered through compound engineering (§4.4) are added here via the Primitive Proposal Flow.

**Built skills** (details in each skill's `SKILL.md`):

| Skill | Version | Summary |
|---|---|---|
| Peer Review | v1.7.1 | Cross-LLM artifact review. 4-model panel. Config: `peer-review-config.md` |
| Inbox Processor | v1.6.3 | Process `_inbox/` files — classify, frontmatter, route. MarkItDown extraction |
| Researcher | v2.4 | 6-stage evidence pipeline via Agent tool dispatch. Write-only-from-ledger citation integrity. `stages/` + `schemas/` subdirs |
| Code Review | v2.1 | Two-tier: Sonnet inline (Tier 1) + cloud panel (Tier 2). Config: `code-review-config.md` |
| Feed Pipeline | v2.3 | 3-tier feed intel routing → signal-notes. `model_tier: reasoning` |
| Excalidraw | v1.9.1 | Freeform `.excalidraw` JSON diagrams |
| Mermaid | v1.9.1 | Default diagramming. Markdown-embedded or `.mmd` files |
| Lucidchart | v1.9.1 | Lucidchart via REST API for external sharing |
| Meme Creator | v1.9.1 | Meme images from quotes with movie stills |
| Startup | v1.9.1 | Session startup hook — git pull, vault-check, CLI, rotation, overlay index |
| Checkpoint | v1.5.4 | Session state saving + context management (§3.1.6) |
| Sync | v1.5.4 | Git commit + backup operations (§3.1.7) |

**Backlog** (unbuilt):

| Candidate Skill | Trigger to Build |
|---|---|
| Customer Contact Strategist | Customer outreach planned manually 3+ times |
| Meeting Topic Planner | Meeting agendas prepared manually 3+ times |
| Strategist | Structured option evaluation needed repeatedly |
| Ideation Engine | Structured divergent thinking needed more than once |
| Momentum Coach | Recurring stuckness patterns observed |
| Exercise Coach | AI-assisted workout planning wanted |
| Mental Health Coach (strict boundaries) | Structured emotional support protocols wanted |

**Skill proposals** (added via compound step — see §4.4):

<!-- Novel skill proposals from compound step are added here -->

### 3.4 Overlays (Not Skills or Agents)

Overlays are **expert lenses** — they inject domain expertise into whatever skill is currently active. They don't have their own procedures; they shape how other procedures think about problems by adding questions, frameworks, and evaluation criteria the active skill wouldn't otherwise consider.

**When to use an overlay vs. other primitives:**
- If it has a repeatable procedure (inputs → steps → outputs) → **Skill**
- If it needs isolated context for heavy work → **Subagent**
- If it adds a domain expert's thinking patterns to other skills' work → **Overlay**

#### 3.4.1 Standard Overlay Structure

Every overlay file follows this structure (target: under 65 lines each):

```markdown
---
type: overlay
domain: [primary domain or "cross-cutting"]
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - overlay
  - [domain tag]
---

# [Overlay Name]

## Activation Criteria
**Signals** (match any → consider loading):
[Specific, testable conditions — not vague pattern matches]

**Anti-signals** (match any → do NOT load, even if signals match):
[Conditions that look like matches but aren't — prevents false positives]

**Canonical examples** (2-3 concrete scenarios):
- ✓ [Scenario where this overlay should fire]
- ✓ [Another scenario where this overlay should fire]
- ✗ [Scenario that looks like a match but isn't — and why]

## Lens Questions
[3-5 questions this expert would ask about any task]

## Key Frameworks
[1-2 reference frameworks or mental models]

## Anti-Patterns
[What this lens is NOT for — prevents over-application]
```

#### 3.4.2 Overlay Activation

**Overlay Index File:**

All overlay routing is driven by `_system/docs/overlays/overlay-index.md`. This file is loaded at session start (§6, Session Startup) and provides Claude with the complete routing table — no directory scanning required.

**Index file structure:**

```markdown
---
type: reference
domain: null
status: active
created: 2026-02-12
updated: 2026-02-12
tags:
  - overlay
  - routing
---

# Overlay Index

Routing table for overlays. Loaded at session start. When a task matches
an overlay's activation signals, load the overlay file alongside the active skill.

## Active Overlays

| Overlay | File | Activation Signals | Anti-Signals |
|---|---|---|---|
| Business Advisor | `_system/docs/overlays/business-advisor.md` | Cost/benefit analysis, market positioning, revenue impact, pricing strategy, competitive dynamics, go-to-market, vendor evaluation, resource allocation with budget implications, strategic trade-offs, formalizing or monetizing side projects, structuring business entities, pricing your own services, partnership/contract evaluation, opportunity assessment | Purely technical decisions with no business implications; implementation-level coding tasks; personal domain goals without financial dimensions; personal/household finance (use Financial Advisor) |
| Career Coach | `_system/docs/overlays/career-coach.md` | Professional skill gap analysis, career positioning or trajectory planning, navigating organizational dynamics, stakeholder relationship strategy, professional reputation or visibility, role transition planning, performance self-assessment, mentoring, professional development prioritization, conference/community engagement strategy, negotiating role scope, salary negotiation strategy | Business strategy where you represent the company (use Business Advisor); customer engagement tactics; life direction questions spanning beyond career (use Life Coach; may co-fire); technical skill implementation vs. strategic skill investment; financial analysis of comp packages (use Financial Advisor) |
| Design Advisor | `_system/docs/overlays/design-advisor.md` | Visual design, graphic design, UI/UX layout, web or app interface work, color palette, typography, brand identity, wireframes, mockups, design system decisions, responsive design, visual hierarchy, charts, graphs, dashboards, data visualization, infographics, presenting quantitative information visually | Purely backend/logic tasks with no visual component; data modeling; infrastructure work |
| Financial Advisor | `_system/docs/overlays/financial-advisor.md` | Household budgeting, cash flow analysis, investment decisions, debt payoff strategy, tax planning, insurance evaluation, retirement planning, major purchase analysis, net worth tracking, savings goals, risk tolerance, financial product comparison | Business revenue/pricing/go-to-market (use Business Advisor); vendor evaluation for company purposes; purely informational research with no decision; expense tracking without analysis |
| Glean Prompt Engineer | `_system/docs/overlays/glean-prompt-engineer.md` | Querying Glean, enterprise knowledge search, internal data lookup at Infoblox, populating vault artifacts from enterprise sources, customer intelligence gathering via Glean, Glean-to-Crumb data pipeline | Tasks using only public/external data; work entirely within the vault with no enterprise source needed |
| Life Coach | `_system/docs/overlays/life-coach.md` | Personal goal-setting, life direction decisions, values clarification, motivation or momentum problems, prioritization across life domains, habit formation or change, work-life tension, "should I" decisions spanning multiple domains, quarterly/annual review, meaning-making, identity questions | Purely technical/implementation tasks; financial analysis (use Financial Advisor); purely strategic business/career decisions (use Business Advisor); generic motivational content disconnected from user context; mental health concerns needing professional support (flag and step back) |
| Network Skills | `_system/docs/overlays/network-skills.md` | DNS architecture or resolution design, DHCP/IPAM planning, network security architecture (RPZ, DoH/DoT, DNS filtering), SASE/SSE evaluation, CDN behavior or integration, hyperscaler networking (AWS VPC, GCP networking, Azure VNet), load balancer design, SD-WAN architecture, zero trust network access, customer network migration planning, RFC interpretation, BGP/routing design, firewall policy architecture, network protocol analysis | Application-level coding with no network dimension; Crumb system infrastructure unless network-specific; generic security not related to network infrastructure; business/pricing decisions about vendors (use Business Advisor); career development about networking skills (use Career Coach) |
| Web Design Preference | `_system/docs/overlays/web-design-preference.md` | Personal site design, Danny's web projects, digest templates, vault-facing UI, dashboard/panel design for personal systems, Enlightenment aesthetic application, site mode selection | Work for external stakeholders/client brand guidelines; purely backend tasks; functional-only UI with no aesthetic dimension |

## Companion Documents

Some overlays declare a **companion doc** — a standing reference document that auto-loads alongside the overlay. Use this pattern when an overlay's value depends on persistent, evolving context rather than lens questions alone.

| Overlay | Companion Doc | Purpose |
|---|---|---|
| Design Advisor | `_system/docs/design-advisor-dataviz.md` | Data visualization lens questions, frameworks, and anti-patterns (Tufte, Cleveland-McGill, Cairo, Ware) |
| Life Coach | `Domains/Spiritual/personal-philosophy.md` | Personal values and philosophical commitments grounding life direction advice |
| Network Skills | `_system/docs/network-skills-sources.md` | Curated vendor documentation catalog (RFC, hyperscaler, CDN, SASE, DNS) |

**When to use:** Companion docs are for overlays grounded in accumulated personal or domain knowledge. Generic advisory overlays (Business Advisor, Financial Advisor, etc.) don't need companions — their value is in the lens questions. Companion docs don't count against the source document budget (overlays are exempt).

**Feedback loop:** Overlays with companions should include a lens question that evaluates whether the companion doc needs updating based on the current session's insights.

## Retired Overlays

<!-- Overlays removed from active routing. Keep for reference. -->
```

**Maintenance:** When adding a new overlay, add its entry to this index as part of the same operation. When retiring an overlay, move its row to the Retired section. Modifying the overlay index is a medium-risk action (proceed + flag).

**Two activation paths:**

1. **Automatic (index-driven):** Skills that benefit from overlay enrichment include an explicit "Check overlay index" step in their procedure (see §3.1.1, §3.1.2). During this step, Claude compares the current task against the activation signals in the loaded index. If a match is found, Claude loads the overlay file and applies its lens questions alongside the skill's normal procedure.

2. **Explicit (user request):** User can request any overlay directly: "bring the infrastructure architect lens to this" or "think about this from a customer empathy perspective." Claude loads the requested overlay from the path in the index.

**When loaded:** The overlay's lens questions are applied *in addition to* the skill's normal procedure. The skill does its work; the overlay adds dimensions the skill wouldn't have considered on its own.

**Context budget:** Overlays are instructional context, not source documents. They do NOT count against the source document budget tiers (§5.4). Keep overlays under 65 lines to minimize context impact.

#### 3.4.3 Phase 1 Overlay (Build First)

Build one overlay as a template. Add others when you encounter a task where that domain expertise would have improved the output. When building any overlay, also add its entry to `_system/docs/overlays/overlay-index.md` as part of the same operation.

**Business Advisor** (complete example):

```markdown
---
type: overlay
domain: cross-cutting
status: active
created: 2026-02-12
updated: 2026-02-12
tags:
  - overlay
  - business
  - strategy
---

# Business Advisor

## Activation Criteria
**Signals** (match any → consider loading):
Task involves any of: cost/benefit analysis, market positioning, revenue impact,
pricing strategy, competitive dynamics, go-to-market decisions, vendor evaluation,
resource allocation with budget implications, or strategic trade-offs.

**Anti-signals** (match any → do NOT load, even if signals match):
- Purely technical architecture decisions with no business implications
- Implementation-level coding tasks (even if the project has business context)
- Personal domain goals without financial or strategic dimensions
- Post-hoc justification of already-made decisions

**Canonical examples:**
- ✓ "Should we use vendor A or vendor B for DNS hosting?" — vendor evaluation with cost/switching implications
- ✓ "How should we price the new training offering?" — pricing strategy with competitive dynamics
- ✗ "Should we use PostgreSQL or MongoDB?" — technical decision unless budget or vendor lock-in is a stated constraint (if it is, the overlay should fire)

## Lens Questions
1. **Value proposition:** What business problem does this solve, and who pays for the solution?
2. **Competitive dynamics:** How does this compare to alternatives? What's the switching cost?
3. **Economic model:** What are the cost drivers? Where is the ROI? What's the payback period?
4. **Risk/reward:** What's the downside scenario? Is the risk proportional to the potential return?
5. **Strategic alignment:** Does this advance or distract from the core strategic objective?

## Key Frameworks
- **Porter's Five Forces:** Competitive rivalry, supplier power, buyer power, threat of substitution, threat of new entry — use to evaluate market position and competitive pressure
- **Jobs-to-be-Done:** What "job" is the customer hiring this solution to do? Reframe features as outcomes the customer is paying for

## Anti-Patterns
- Do NOT apply to purely technical decisions with no business implications
- Do NOT use to justify decisions post-hoc — apply during analysis, not after
- Do NOT override technical constraints with business pressure — flag the tension instead
```

#### 3.4.4 Phase 2+ Overlays (Add Incrementally)

**Do not build these until you encounter a task where the domain expertise would have improved the output.** This list is a backlog, not a build plan.

| Overlay | Domain | Lens Focus | Build When |
|---|---|---|---|
| Persuasion Analysis | Communication | Influence, messaging, rhetorical effectiveness | You're crafting customer communications or proposals and want rhetorical rigor |
| Infrastructure Architect | Technical (design) | Dependencies, failure modes, scalability, security implications | You're designing or reviewing technical architecture and want design-level pressure testing |
| Systems Administrator | Technical (operations) | Day-to-day operations, reliability, monitoring, runbooks | You're planning deployments or operational processes and want ops-level reality checks |
| Commercial Analyst | Financial | Pricing, ROI, TCO, deal structure, business cases | You're building quotes, pricing models, or business cases and want financial rigor |
| Technical Educator | Knowledge transfer | Learning theory, cognitive load, scaffolding, instructional design | You're creating training materials or documentation and want pedagogical structure |
| Customer Empathy | Stakeholder awareness | Customer motivations, adoption readiness, organizational reality, gap between proposal and readiness | You're building customer profiles or engagement strategies and want stakeholder depth |
| Systems Thinking | Cross-cutting | Feedback loops, emergence, tight coupling, second-order effects, unintended consequences | You want systems-aware reasoning applied beyond the SPECIFY phase — in design, planning, and compound engineering |

### 3.5 Model Routing

Skills declare their compute tier via the `model_tier` frontmatter field. CLAUDE.md maps these tiers to concrete model strings. This keeps skill definitions model-agnostic — they specify *what kind of work* they do, not *which model* does it.

**Tier values:**

| `model_tier` | Work type | Maps to |
|---|---|---|
| `reasoning` | High-judgment: analysis, specification, design, evaluation | Opus (session default) |
| `execution` | Procedural: file processing, templating, mechanical utilities | Sonnet (`claude-sonnet-4-6`) |
| *(omitted)* | Inherit session model (backward compatible) | Session default |

**Delegation mechanism:** When Opus loads a skill with `model_tier: execution`, it delegates the skill's procedure to a Sonnet subagent via the Task tool (`model: "sonnet"`). Opus handles dispatch prompt assembly and result review; Sonnet handles execution. Concrete and works today — no future capability required.

**Phased rollout:**
- **Phase 1 (deployed):** Zero-context mechanical skills — sync, checkpoint, startup, obsidian-cli, meme-creator
- **Phase 2 (deployed):** Structured-input skills — mermaid, excalidraw, lucidchart
- **Phase 3 (deferred):** Interactive skills with prompting phases — inbox-processor (requires dispatch manifest design to preserve user decisions across handoff)

**Precedence:** subagent explicit `model` field > skill `model_tier` > session default.

**Config location:** Concrete model strings live in CLAUDE.md Model Routing section only. Updating the mapping is a single-line change there; skill definitions need no updates.

### 3.6 Primitive Creation Protocol

Creating new primitives (skills, subagents, overlays) is a structural change to the system — it affects routing, context budgets, and the complexity surface that future sessions must navigate. All primitive creation requires user approval (consistent with §4.7 Ask First: "Modifying CLAUDE.md or skill definitions").

#### Two Paths to Primitive Creation

**System-proposed (via compound step):** The compound step identifies a gap that existing primitives can't address. The Primitive Proposal Flow (§4.4) governs escalation from first occurrence to proposal to build. Claude proposes, user approves.

**User-initiated:** User directly requests a new primitive ("build me a skill that does X", "I want an overlay for Y", "create a subagent for Z"). Bypasses the Primitive Proposal Flow's escalation cadence — go directly to the creation flow below.

#### Creation Flow

Regardless of path, all primitive creation follows the same steps:

1. **Select the right primitive type.** Use the Primitive Selection Guide (§3.0) to confirm the right primitive for the need. If the user requests a skill but the need is better served by an overlay (or vice versa), Claude should say so with reasoning. The user decides.

2. **Propose the definition.** Claude drafts the primitive using the appropriate structural template:
    - **Skill:** SKILL.md following the conventions in `_system/docs/skill-authoring-conventions.md` — identity/purpose, trigger criteria, procedure, context contract, output constraints, quality checklist, compound behavior, convergence dimensions
    - **Subagent:** Agent definition following §3.2.1 — name, description, skills list, phase, outputs, validation procedure
    - **Overlay:** Overlay file following §3.4.1 — name, activation criteria, lens questions, key frameworks, anti-patterns (target under 65 lines)

3. **User reviews and approves.** Claude presents the draft for review. User can approve, request changes, or cancel. No files are written until approved.

4. **Create and register.** On approval, Claude:
    - **Skill:** Creates `.claude/skills/[name]/SKILL.md`. If the skill has reference files, creates those alongside.
    - **Subagent:** Creates `.claude/agents/[name].md`.
    - **Overlay:** Creates `_system/docs/overlays/[name].md` AND adds an entry to `_system/docs/overlays/overlay-index.md`. Write the index entry first, then the overlay file — if the session crashes between writes, an index entry pointing to a missing file produces a visible error on next activation, whereas an overlay file with no index entry is silently invisible to routing.
    - For all types: log the creation in `run-log.md` (project) or `_system/logs/session-log.md` (non-project) with the primitive type, name, and rationale.

5. **Verify routing.** After creation, Claude confirms the primitive is reachable (this is a behavioral check — Claude is articulating intended activation scenarios, not mechanically testing routing. The value is making activation intent explicit so future audit-time routing drift checks have a baseline to compare against):
    - **Skill:** The description field matches the intended trigger scenarios. Claude states 2-3 example prompts that should activate it.
    - **Subagent:** The agent file is in `.claude/agents/` and can be spawned.
    - **Overlay:** The index entry's activation signals are specific and testable. Claude states 2-3 example scenarios that should trigger it.

#### Naming Conventions

- **Skills:** Lowercase, hyphenated role nouns: `systems-analyst`, `writing-coach`, `researcher`
- **Subagents:** Lowercase, hyphenated role nouns: `frontend-designer`, `backend-designer`
- **Overlays:** Lowercase, hyphenated descriptive names: `business-advisor`, `infrastructure-architect`
- All names should be self-describing — recognizable without additional context

#### When NOT to Create a New Primitive

Before creating anything new, Claude should verify the need can't be met by:
- Updating an existing skill's procedure or context contract
- Adjusting CLAUDE.md routing to better match existing skills
- Adding a step to an existing overlay's lens questions
- Using a one-time instruction in the current conversation

If any of these suffice, they're preferable to adding a new primitive. Each new primitive increases routing complexity and maintenance burden (audit skill must review it, overlay index grows, CLAUDE.md may need routing updates).

---

## 4. Protocols

### 4.1 Workflow Phases

Three workflow variants based on domain:

#### Full Workflow (Software)

```text
SPECIFY → PLAN → TASK → IMPLEMENT
   │         │       │        │
   ▼         ▼       ▼        ▼
  Spec    Designs   Tasks    Code
  Gate     Gate     Gate     Gate
```

1. **SPECIFY** — Systems Analyst produces `specification.md` + summary. Use Plan Mode (§7.7) for mechanical read-only enforcement. **Gate:** Human approves spec.
2. **PLAN** — Frontend/Backend Designer subagents produce design docs. Main session validates in Plan Mode (§7.7). **Gate:** Human approves designs (after main session validates subagent output quality).
3. **TASK** — Action Architect produces `action-plan.md` + `tasks.md`. **Gate:** Risk-tiered (§4.3).
4. **IMPLEMENT** — Main session executes tasks, using convergence protocol. **Gate:** Tests pass + convergence criteria met.

**Context checkpoint between phases:** Use the Context Checkpoint Protocol (§4.1.4) before transitioning phases.

#### Knowledge Work Workflow (Career, Learning, Financial)

```text
SPECIFY → PLAN → ACT
   │        │      │
   ▼        ▼      ▼
  Spec    Plan   Execute
  Gate    Gate    Gate
```

1. **SPECIFY** — Systems Analyst produces lightweight spec. **Gate:** Human confirms direction.
2. **PLAN** — Action Architect produces action plan. **Gate:** Risk-tiered.
3. **ACT** — Execute plan (write deliverables, research, communicate). **Gate:** Convergence (rubric-based for non-code).

**Context checkpoint:** Use Context Checkpoint Protocol between PLAN and ACT if needed.

#### Personal Workflow (Health, Relationships, Creative, Spiritual)

```text
CLARIFY → ACT
   │        │
   ▼        ▼
  Goal    Execute
  Gate     Gate
```

1. **CLARIFY** — Define goal, constraints, success criteria. Often conversational. **Gate:** Human confirms.
2. **ACT** — Create routine, plan, or creative output. **Gate:** Lightweight self-check or human review.

**Example: Build a Meditation Practice**

> **CLARIFY**
> - Goal: Establish a consistent daily meditation practice (20 min/day)
> - Constraints: Mornings before work; no app dependency; Zen tradition preferred
> - Success criteria: 5+ sessions/week sustained for 4 weeks
> - Risk: Low (behavior-change, fully reversible)
> - Artifacts: `Domains/Spiritual/meditation-practice.md` with goal definition, constraints, success criteria
>
> **ACT**
> - Create structured 4-week progression plan (5→10→15→20 min)
> - Weekly check-in template in `Domains/Spiritual/meditation-practice.md`
> - Convergence: Apply Personal Goal Quality rubric (§4.2.1) — review at week 2, adjust if adherence < 60%
> - Compound: If the progression structure works, tag as `#kb/behavior-change` pattern

#### Workflow Entry Threshold

**Enter a formal workflow when the task meets EITHER condition:**
1. **File footprint** — the task will create or substantially modify 3+ vault files
2. **Domain complexity** — the task involves a decision with downstream dependencies (something that, if done wrong, would require rework in other files)

**Skip formal workflow when:**
- Single-file edits, lookups, conversational Q&A, routine log updates
- The user explicitly says "just do it" / "quick" / "no need for a full workflow"

**When uncertain, default to the lighter workflow variant for the domain** (CLARIFY → ACT for personal, SPECIFY → PLAN → ACT for knowledge work) rather than the full four-phase.

**Mid-conversation escalation:** If an interaction that started without a formal workflow crosses the threshold during the conversation (scope grows, dependencies emerge), prompt the user to create a project via the Project Creation Protocol (§4.1.5). The user can accept or decline — if declined, the session continues informally and is logged to `_system/logs/session-log.md`.

**Non-project sessions:** Interactions that don't enter a formal workflow are logged to `_system/logs/session-log.md` (§2.3.4) at session end, with compound step evaluation. This ensures ad-hoc work leaves a vault trace and can feed the compounding system.

**Rule:** Never skip phases within a workflow. If reality diverges from spec, update the spec first, then regenerate downstream.

**Phase transition exception rules:**
When reality doesn't fit the expected linear flow, these rules govern what happens:
- **Scope change discovered mid-phase:** Return to SPECIFY. Update the spec to reflect new scope, regenerate the spec summary, then re-enter the current phase with updated context.
- **Spec invalidated during IMPLEMENT:** Return to SPECIFY. Do not attempt to patch tasks or code — fix the source of truth first. The checkpoint at re-entry resets `project-state.yaml` and invalidates downstream tasks.
- **User requests phase skip:** Decline. Explain which artifacts would be missing and what risks that creates. If user insists after understanding the risks, log the skip decision as an ADR with rationale and proceed — but flag this in the run-log as a deviation.
- **Subagent output rejected at gate:** Remain in current phase. Run the Subagent Revision Protocol (§3.2.3) — one revision pass, then escalate to user if the second pass also fails. Do not advance to the next phase with unresolved gate failures.
- **Context pressure forces `/clear` mid-phase:** Reconstruct from vault and continue the current phase — do not restart the phase from scratch unless the compound reflection at the interrupted point identified a fundamental issue.

#### Worked Examples (Golden Paths)

**Golden path: New software project**
1. User: "I need to build an API for managing DNS zone templates"
2. Claude proposes: `dns-zone-templates` project, `software` domain, full four-phase workflow
3. User confirms → Project Creation Protocol creates scaffold + `project-state.yaml`
4. SPECIFY: Systems Analyst skill fires. Claude loads overlay index, checks for matching overlays (Infrastructure Architect if it exists). Produces `specification.md` and `specification-summary.md`. Gate: user reviews and approves spec.
5. Phase transition: Context Checkpoint runs (compound reflection → context check → log → update project-state.yaml → load spec summary for PLAN)
6. PLAN: Subagents produce design docs. Claude reviews summaries, runs provenance checks. Gate: risk-tiered (high-risk design decisions → user approval).
7. Phase transition: Context Checkpoint runs again.
8. TASK: Action Architect fires. Loads spec summary + design summaries + targeted partial reads of constraints sections from full design docs. Produces `action-plan.md` and `tasks.md`. Gate: user reviews task decomposition.
9. Phase transition → IMPLEMENT: Tasks executed serially, each following the task lifecycle (claimed → in_progress → complete with acceptance criteria).

**Golden path: Ad-hoc research that becomes a project**
1. User: "What are the best practices for DNS-based security in hybrid cloud environments?"
2. Claude treats as non-project interaction (single question, no workflow). Researches and responds.
3. User: "Actually, I want to build a reference architecture for this. Can you help me think through the components?"
4. Scope is growing — Claude checks threshold: this will produce 3+ vault files (reference doc, architecture notes, component analysis). Prompts: "This is growing beyond a quick task — want to create a project for it?"
5. User accepts → session-log entry written first (crash resilience) → Project Creation Protocol runs → `project-state.yaml` initialized → conversation context carries into SPECIFY phase. The research already done becomes input to the spec.

**Golden path: Personal domain goal**
1. User: "I want to get better at gardening this spring"
2. Domain: creative (or could be health, depending on framing). Workflow: two-phase CLARIFY → ACT.
3. CLARIFY: Conversational — define goal ("grow tomatoes and herbs from seed"), constraints ("small patio, zone 6, no greenhouse"), success criteria ("harvest at least one meal's worth by August").
4. ACT: Create structured plan in `Domains/Creative/spring-gardening.md`. Tag with `#kb/gardening`. Link from `Domains/Creative/creative-overview.md`.
5. No formal project unless scope grows (e.g., building a raised bed involves design decisions and materials → might escalate to project).

**When NOT to use Crumb:**
- One-off Claude Code help in a repo that isn't the vault (debugging, code generation, git help)
- Quick factual questions with no vault trace needed
- Conversations in chat LLMs (Claude.ai, ChatGPT) that don't produce vault artifacts
- Any interaction where you'd say "just do it" and the output doesn't need to persist

If you're unsure, default to non-project mode: do the work, log it to `_system/logs/session-log.md` at session end. If it turns out to be bigger than expected, escalate via the mid-conversation threshold.

**Batch commit discipline (long ACT phases):** When an ACT phase produces work in batches (e.g., writing multiple profiles, populating multiple accounts), commit to git at each batch boundary — after updating the run-log with batch progress but before starting the next batch. This prevents long sessions from accumulating many uncommitted files. The session-end sequence still commits, but batch commits provide intermediate durability so a mid-session crash doesn't lose an entire session's work.

#### Prompt Triage (Within-Project Response Depth)

The workflow entry threshold determines whether an interaction enters a formal workflow. Prompt triage determines *how deeply* to engage once inside a project. Not every within-project interaction needs the full skill invocation, context loading, and overlay check sequence.

**Three modes:**

| Mode | When | Behavior |
|---|---|---|
| **FULL** | New phase, new task, or request that changes scope | Full skill invocation, context loading, overlay check, compound evaluation at phase end |
| **ITERATION** | Refining, revising, or following up on current task | Load only what's needed for the specific change. Skip overlay check unless the iteration shifts domains. |
| **MINIMAL** | Quick fix, lookup, or clarification within current context | No skill invocation, no additional context loading. Execute directly and log if meaningful. |

**Classification is Claude's judgment call** based on the request — not a mechanical check or a separate processing step. This is routing guidance, not a protocol.

**Examples:**
- "Let's start the backend design" → FULL (new phase)
- "Change the pagination limit from 50 to 100 in the spec" → MINIMAL (quick fix)
- "Rework the error handling section based on the design feedback" → ITERATION (refining current work)
- "What did we decide about the auth approach?" → MINIMAL (lookup)
- "Add a new endpoint for bulk imports" → FULL (scope change)

#### 4.1.4 Context Checkpoint Protocol

Full procedure: `_system/docs/context-checkpoint-protocol.md`

**Summary:** Proactive context management at phase transitions and reactive management when degradation signals appear. Enforces compound engineering at every phase boundary. 8-step procedure: compound reflection → check context → evaluate capacity (thresholds: <70% proceed, 70-85% compact, >85% clear+reconstruct) → log phase transition to run-log + update project-state.yaml → commit → verify outputs → load next phase context → proceed.

**Context Pressure Degradation Guide:** Quality degrades gradually before hard limits. <50% full capability; 50-65% favor summaries; 65-75% skip optional overlays; 75-85% minimum safe checkpoint then compact; >85% clear and reconstruct. See standalone doc for full degradation table.

#### 4.1.5 Project Creation Protocol

**Three paths to project creation:**

1. **User-initiated:** User explicitly requests a new project ("start a new project for X", "let's make this a project"). Bypasses the workflow entry threshold — go directly to the creation flow below.
2. **Threshold-triggered:** During a non-project interaction, the work crosses the workflow entry threshold (§4.1: file footprint ≥ 3 vault files OR downstream dependencies emerge). Claude prompts: "This is growing beyond a quick task — want to create a project for it?" User can accept or decline.
3. **Session-log promotion:** A previous session-log entry flagged something as worth revisiting. User or audit review surfaces it and decides to formalize.

**Declining project creation:** When prompted via threshold trigger, the user can decline. The interaction continues as a non-project session and gets logged to `_system/logs/session-log.md` with `Promote: declined — [reason]`. The decline is recorded, not challenged — Claude doesn't re-prompt in the same session. If the same topic surfaces in future sessions and crosses the threshold again, Claude may prompt again.

**Creation flow:**

1. **Propose project name and domain.** Claude proposes a kebab-case project name and domain classification with brief rationale. Example: "I'd suggest `acme-dns-migration` in the `software` domain — this is a technical implementation with design and task phases."
2. **User confirms or overrides.** User provides the final project name and confirms or changes the domain. The name becomes the directory name under `Projects/` and the `project` field in all frontmatter.
3. **Create project scaffold.** Claude creates:
    - `Projects/[project-name]/` directory
    - `Projects/[project-name]/project-state.yaml` — initialized with:
      ```yaml
      # Machine-readable project state — updated at every phase transition.
      # Validated by vault-check.sh against run-log.md for consistency.
      phase: SPECIFY
      workflow: [four-phase | three-phase | two-phase]
      last_gate: project-created
      active_task: null
      next_action: "Begin SPECIFY phase — run systems-analyst skill"
      repo_path: null  # optional — absolute path to external repo (software projects with git repos)
      related_projects: []  # optional — list of related project names for cross-referencing
      updated: YYYY-MM-DD HH:MM
      last_committed: YYYY-MM-DD HH:MM
      ```
    - `Projects/[project-name]/progress/run-log.md` — initialized with a creation entry:
      ```markdown
      ## Session: YYYY-MM-DD HH:MM
      **Context:** Project created. Entering SPECIFY phase.
      **Routing Decision:**
      - Domain: [domain]
      - Workflow: [full four-phase | three-phase | two-phase]
      - Rationale: [why this workflow]
      ```
    - `Projects/[project-name]/progress/progress-log.md` — initialized with:
      ```markdown
      ## YYYY-MM-DD
      - 🚧 Project created, entering SPECIFY phase
      ```
    - For software-domain projects only: `Projects/[project-name]/design/` directory
    - All other files (`specification.md`, `tasks.md`, `action-plan.md`, `decisions/`, etc.) are created on-demand by the skills that produce them
4. **Enter SPECIFY phase.** Systems Analyst skill takes over. The conversation context that triggered project creation is already in Claude's working memory — it carries directly into the SPECIFY phase without needing to be re-gathered or re-read from the vault.

**If created from an ongoing conversation (mid-session escalation):** Write the session-log entry *before* creating the project scaffold. This ensures crash resilience: if the session dies between "user agrees to create project" and "scaffold is written," the worst case is a session-log entry with `Promote: project proposed: [name]` but no project directory yet — recoverable on the next session. The session-log entry serves as the durable record; the in-memory context serves the active SPECIFY phase.

**If created from a previous session-log entry:** Load the relevant session-log entry's content into context. Add a note to the session-log: `Promote: project created: [project-name]` with a link to the project directory.

**Context checkpoint interaction:** If context usage is high (>70%) when project creation is triggered, run the Context Checkpoint Protocol (§4.1.4) *after* writing the session-log entry and creating the project scaffold, but *before* entering the SPECIFY phase. This preserves the session-log record and scaffold even if `/compact` or `/clear` is needed.

**Naming conventions:**
- Kebab-case, descriptive, concise: `acme-dns-migration`, `personal-finance-tracker`, `q3-training-curriculum`
- Avoid generic names: `new-project`, `test`, `misc`
- The name should be recognizable months later without additional context

#### 4.1.6 Project Lifecycle

A project moves through a simple lifecycle: **creation → active work → done → (optional) archival → (optional) reactivation**.

- **Creation:** User-initiated or threshold-triggered. The Project Creation Protocol (§4.1.5) creates the scaffold, initializes project-state.yaml, and enters the SPECIFY phase.
- **Active work:** The project lives in `Projects/` and moves through workflow phases (SPECIFY → PLAN → TASK → IMPLEMENT). Session startup reports it, audit includes it, vault-check validates it.
- **Done:** All project tasks are complete. The project stays in `Projects/` with `phase: DONE`. It remains visible to session startup and vault-check but is not actively worked on. Maintenance artifacts (upgrade runbooks, hotfixes) may be added with a run-log note. New design work that relates to a completed project should create a new project with `related_projects` linking back, not expand the done project's scope.
- **Archival:** User-initiated only. The project moves to `Archived/Projects/` via the Archive Procedure (§4.6). It leaves active reporting and weekly audit scope. Structural integrity checks continue.
- **Reactivation:** User-initiated only. The project moves back to `Projects/` via the Reactivate Procedure (§4.6). Normal workflow resumes from the phase the project was in before archival, or from an earlier phase if the user wants to rethink scope.

Directory location is authoritative for active vs archived: a project in `Projects/` is active or done, a project in `Archived/Projects/` is archived. The `phase` field in `project-state.yaml` distinguishes active work (SPECIFY/PLAN/TASK/IMPLEMENT) from done (DONE) from archived (ARCHIVED).

### 4.2 Tiered Convergence Protocol

Convergence is how the system improves output quality. The approach varies by output type.

#### Code Convergence (Binary Grounding)

```text
Generate → Ground → Fix if broken → Done
```

- **Ground** with concrete, binary checks: tests pass, types check, linting clean, compilation succeeds, screenshots match (for UI)
- No self-scoring rubrics. Pass or fail.
- **Stop when:** All checks pass, or 3 iterations without progress (escalate to human).

#### Non-Code Convergence (Lightweight Rubric)

```text
Generate → Score → Ground → Revise if weak → Done
```

- **Score** on 3-5 dimensions relevant to the output type
- **Use pre-built rubrics from `_system/docs/convergence-rubrics.md`** rather than inventing dimensions each time
- **Ground** with whatever external check is available: user confirmation, checklist, comparison to examples
- **Stop when:** All dimensions adequate, or 2 iterations without meaningful improvement, or human says "good enough"
- **Important:** This is a lightweight quality check, not a perfectionism engine. Aggressive stop conditions prevent token waste.

**Pre-built rubric dimensions** are defined in `_system/docs/convergence-rubrics.md` (see §4.2.1 for bootstrap contents).

#### No Convergence

Simple, low-stakes outputs (daily log entries, quick lookups, routine updates) skip convergence entirely.

#### 4.2.1 Convergence Rubrics Bootstrap

**Create this file in Phase 1b:** `_system/docs/convergence-rubrics.md`

```markdown
---
type: reference
domain: null
skill_origin: null
status: active
created: 2026-02-12
updated: 2026-02-12
tags:
  - convergence
  - quality-rubrics
---

# Convergence Rubrics

Pre-built dimension sets for non-code quality assessment. Use these rather than inventing new rubrics each time.

## How to Use

1. Identify the output type (specification, writing, action plan, etc.)
2. Apply the relevant rubric dimensions below
3. Score each dimension: adequate | needs improvement
4. If any dimension "needs improvement" AND iteration count < 2: revise and re-score
5. Stop when all adequate OR 2 iterations reached OR human says "good enough"

## When to Add a Rubric

- After 3+ iterations on the same output type reveal common failure modes
- When compound step identifies reusable quality dimensions
- NOT preemptively for every possible output type

---

## Specification Quality

**Use for:** `specification.md`, requirements docs, problem analyses

1. **Completeness** — All key sections present (problem statement, facts/assumptions/unknowns, system map, task decomposition)
2. **Clarity** — Unambiguous language, clear definitions, no conflicting statements
3. **Actionability** — Downstream work can proceed without additional clarification; success criteria are measurable

## Writing Quality (General)

**Use for:** Emails, essays, blog posts, reports, documentation

1. **Audience fit** — Appropriate tone, terminology, and depth for intended reader
2. **Structure** — Logical flow, clear sections, good signposting
3. **Brevity** — No unnecessary words, sentences, or paragraphs; gets to the point

## Action Plan Quality

**Use for:** `action-plan.md`, project plans, task lists

1. **Coverage** — All major work represented; no critical gaps
2. **Dependency correctness** — Tasks properly sequenced; dependencies accurately mapped
3. **Risk calibration** — Risk levels (low/medium/high) match actual stakes and reversibility

## Personal Goal Quality

**Use for:** routines, habit plans, creative projects, relationship goals, spiritual practices

1. **Specificity** — Clear, measurable success criteria (not vague aspirations)
2. **Sustainability** — Realistic given known constraints (time, energy, dependencies)
3. **Feedback loop** — Built-in check-in mechanism to know if it's working

---

## Custom Rubrics

Add rubrics below as you discover recurring quality patterns through compound engineering.

<!-- Future rubrics added here -->
```

**This bootstrap file:**
- Covers the three core skills (Systems Analyst, Action Architect, Writing Coach)
- Provides concrete examples of what a rubric looks like
- Includes guidance on when to add new rubrics (empirically driven, not preemptive)
- Starts simple with 3 rubrics and grows organically
- **Note:** These same dimensions are embedded inline in the skill SKILL.md files for Phase 1a use. When this standalone rubrics file is created (Phase 1b), the inline versions remain as fallbacks but skills should prefer the standalone file when it exists.

### 4.3 Risk-Tiered Approval Gates

Not every action needs human approval. The system uses three tiers:

| Risk Level | Approval | Examples |
|---|---|---|
| **Low** | Auto-approve | Reading files, creating drafts, running tests, updating logs, searching vault |
| **Medium** | Async review (proceed, flag for later review) | Creating new files, modifying non-critical docs, routine code changes |
| **High** | Synchronous human approval required | Changing architecture, modifying schemas/migrations, external communications, irreversible actions, adding dependencies, anything touching production |

Risk levels are assigned by the Action Architect in `tasks.md` and enforced by CLAUDE.md behavioral boundaries.

### 4.4 Compound Step Protocol

#### When to Run

Compound engineering operates at three levels:

**Phase-level (required — structurally enforced):** Compound reflection runs at every phase transition as the first step of the Context Checkpoint Protocol (§4.1.4). The evaluation is guaranteed — Claude assesses whether the completing phase produced compoundable insights before context management begins. If trigger criteria are met, the full compound procedure runs. If not, an explicit skip note is recorded. Either outcome leaves an auditable trace in the run-log, validated by the vault integrity script (§7.8).

**Non-project session-end (required — behavioral with mechanical safety net):** Before ending any non-project session that produced meaningful work, Claude evaluates the trigger criteria below and records the result in the session-log's `Compound` field (§2.3.4). This is behavioral rather than structural — there are no phase transitions to hook into — but the vault integrity script (§7.8) provides a mechanical safety net: it verifies that every session-log entry with a non-empty `Summary` field has a `Compound` field, flagging entries where the evaluation was skipped entirely. Trivial interactions (greetings, single-question lookups) skip this entirely.

**Task-level (discretionary — behavioral):** Individual tasks that surface something notable mid-phase don't have to wait for the phase boundary. Run the compound step after any task where at least one of the trigger criteria below is true. This remains a behavioral instruction, not mechanically enforced.

**Trigger criteria** (apply at both levels):

- **Non-obvious decision:** The work required a decision that wasn't straightforward from the spec/plan
- **Rework or failure:** Something went wrong worth learning from
- **Reusable artifact:** The work produced a technique or artifact transferable to other projects/domains
- **System gap:** The work revealed a missing skill, bad routing, unclear process, or other structural issue

If none apply — the work was straightforward execution from a clear plan — skip the compound step (with explicit skip note at phase level).

#### Procedure

**Step 1: Reflect**
- What worked?
- What didn't?
- What's the reusable insight?
- **Falsifiability check:** Can I name a case where this insight doesn't apply?
- **Confidence level:** High (3+ instances) | Medium (reasonable inference) | Low (speculative)
- How do we make the system catch this automatically next time?

**Step 2: Route the insight**

Not every insight belongs in `_system/docs/solutions/`. Triage to the right destination:

| Insight Type | Destination | Action |
|---|---|---|
| **Convention or rule** | Update existing doc (file conventions, CLAUDE.md, skill file) | No new document — improve what exists |
| **System gap (existing primitive)** | Update skill definition, overlay, or CLAUDE.md routing | Modify the relevant primitive/config |
| **System gap (new primitive needed)** | Primitive Proposal Flow below | Log, propose, and build per escalation cadence — the Proposal Flow handles primitive type selection (skill vs. subagent vs. overlay) using the Primitive Selection Guide (§3.0) |
| **Genuine reusable pattern** | `_system/docs/solutions/` with confidence tagging | Only path that creates new documents |
| **Durable knowledge** | Tag with `#kb/[topic]` + link from relevant domain summary | Promotes deliverable to knowledge base without moving it (see §5.5) |
| **One-time fix** | `run-log.md` entry | Log for the record, no new document |

**Step 3: Execute the routing**

For **insights** routed to `_system/docs/solutions/`:
- Create or update a document with standard YAML frontmatter
- Include `confidence: high|medium|low` in frontmatter
- **Classify by track** before writing. Add `track: bug|pattern|convention` to frontmatter:
  - Something broke or went wrong → `bug`
  - Reusable decision framework or design insight → `pattern`
  - Process or policy record → `convention`
- **Document body sections by track:**

  **Track: `bug`**
  ```markdown
  ## Symptoms
  [What was observed — error messages, failing behavior, user-visible impact]

  ## Root Cause
  [Why it happened — the actual underlying issue]

  ## Resolution
  [What fixed it — the specific change or approach]

  ## Resolution Type
  [Category: config | code-fix | architecture | process | dependency | workaround]

  ## Evidence
  [Concrete instance(s) with project/task references]

  ## Counterexample
  [When this pattern does NOT apply]
  ```

  **Track: `pattern`**
  ```markdown
  ## Applies When
  [Trigger conditions — what situation activates this pattern]

  ## Guidance
  [What to do — the actionable decision rule]

  ## Why It Matters
  [Impact of ignoring — what breaks or degrades]

  ## Evidence
  [Concrete instance(s) with project/task references]

  ## Counterexample
  [When this pattern does NOT apply]
  ```

  **Track: `convention`**
  ```markdown
  ## Scope
  [Where this applies — which projects, domains, file types, or skills]

  ## Rule
  [The convention itself — stated as a directive]

  ## Rationale
  [Why this convention exists — the decision or incident that established it]

  ## Evidence
  [Concrete instance(s) with project/task references]
  ```

  Conventions don't require a Counterexample section — they're policy decisions, not inferential patterns.
- If confidence is `low`: hold the observation in `run-log.md` rather than creating a standalone document. Only promote to `_system/docs/solutions/` when the same insight surfaces in a second instance.
- If confidence is `medium`: **present the pattern to the user for review before writing to `_system/docs/solutions/`.** The compound step's self-evaluation is inherently self-referential — the same LLM that generated the insight evaluates its quality. Medium-confidence patterns are the highest-risk category: substantial enough to persist but not yet validated by repetition. Present: the pattern title, trigger context, proposed decision rule, the specific task(s) that generated it, the falsifiability check result, and **cost-of-wrong** (what breaks or degrades if this pattern is incorrect — helps the user calibrate review effort). User approves, requests changes, or rejects. If approved, write with `tentative-pattern` tag; validate across 2+ projects before promoting.
- If confidence is `high` (3+ instances): write directly — the pattern has empirical backing across multiple instances. Tag as `tentative-pattern` only if the instances are all from the same project (within-project repetition is weaker evidence than cross-project repetition).
- Only promote `tentative-pattern` to skill/rule after validation in 2+ projects

For **conventions/rules**: update the relevant existing document directly.

For **durable knowledge**: see §5.5 Knowledge Base Protocol. Tag the deliverable with `#kb/[topic]` and add a backlink from the relevant domain summary. No file copying or physical reorganization.

For **skill proposals**: follow the Primitive Proposal Flow below.

#### Primitive Proposal Flow

When a compound step identifies a system gap that can't be addressed by updating an existing primitive, adjusting routing, or using a one-time instruction:

**First occurrence (low confidence):**
- Log the gap in `run-log.md` or `_system/logs/session-log.md` with a note: "Potential [skill|subagent|overlay] gap: [description]"
- Include which primitive type seems appropriate and why (per §3.0 Primitive Selection Guide)
- Do not create a proposal yet — single data point

**Second occurrence (medium confidence):**
- Write a proposal entry in the appropriate backlog (§3.3 for skills/subagents, §3.4.4 for overlays):
  - What problem does this gap cause?
  - What would the primitive do?
  - Which primitive type is right and why? (skill vs. subagent vs. overlay — per §3.0)
  - Why can't this be handled by updating an existing primitive or adjusting routing?
  - Which tasks/projects surfaced this gap?
- **Notify the user:** Flag the proposal for human review. New primitives are structural changes — the user should decide whether and when to build.

**Third occurrence or high-impact gap (high confidence):**
- If already proposed and user-approved: build via the Primitive Creation Protocol (§3.6)
- If not yet proposed: write proposal and notify user immediately (high-impact gaps don't need to wait for a second occurrence)

**User-initiated bypass:** The user can request primitive creation at any time, bypassing the escalation cadence entirely. See §3.6 for the creation flow.

#### Sustainability

**Sustainability rule:** During weekly review (via audit skill §3.1.4), consolidate and prune `_system/docs/solutions/`:
- Merge redundant patterns
- Archive patterns not referenced in 60+ days
- Promote frequently-used patterns to skill reference files
- Review `tentative-pattern` tags: validate or discard based on new evidence
- **Consolidation review trigger:** When `_system/docs/solutions/` reaches 50 active documents, the next weekly review must include a consolidation pass. This is a review trigger, not a hard cap — the system can continue creating documents beyond 50, but reaching this threshold signals that consolidation is overdue. Perform the consolidation if you find redundancy; skip it if all 50+ documents remain valuable and distinct.

### 4.5 Task State Machine

All tasks in `tasks.md` have:

```yaml
- id: T-001
  description: "Implement user authentication endpoint"
  state: pending          # pending | ready | claimed | in_progress | complete
  depends_on: [T-000]
  risk_level: high        # low | medium | high → drives approval gate
  domain: software
  acceptance_criteria:
    - [ ] JWT token generation returns valid signed token
    - [ ] All auth tests pass
    - [ ] Response format matches API contract
```

#### Task State Transitions

Allowed transitions (all others are invalid):

```
pending → ready        # All dependencies met (depends_on tasks are complete)
ready → claimed        # Task picked up for current session
claimed → in_progress  # Active work has begun
in_progress → complete # All acceptance criteria met + evidence logged
in_progress → ready    # Work paused or deferred — returns to available pool
claimed → ready        # Unclaimed without starting work (reprioritization)
```

**Transition invariants:**
- A task cannot move to `ready` unless all tasks in its `depends_on` list are in `complete` state. No exceptions — if a dependency is blocked, the dependent task stays `pending`.
- A task cannot move to `complete` unless every acceptance criterion is checked (all `[ ]` → `[x]`). Partial completion is not a valid end state — split the task if scope is too large.
- No cycles in the dependency graph. If adding a `depends_on` would create a cycle, reject the dependency and restructure the task decomposition.
- Only one task per project should be in `claimed` or `in_progress` state at a time in a single session. Multiple tasks can be `ready` simultaneously, but serial execution prevents context fragmentation.

**Definition of done:**
A task is `complete` when ALL of:
1. Every acceptance criterion is marked `[x]` (binary — no "mostly done")
2. The session's run-log entry references the task ID and describes what was done
3. For code tasks: tests pass, types check, linting clean (per §4.2 Code Convergence)
4. For non-code tasks: lightweight convergence check passes (per §4.2 Non-Code Convergence), or user explicitly accepts output
5. `project-state.yaml` `active_task` is updated (cleared if no next task, or set to next task if continuing)

When a task completes, also update `project-state.yaml`:
```yaml
active_task: null    # or next task ID if immediately continuing
next_action: "[one sentence: next task to pick up, or 'phase complete — run transition']"
updated: YYYY-MM-DD HH:MM
last_committed: YYYY-MM-DD HH:MM  # Updated at every git commit
```

**Acceptance criteria format rules:**

Every acceptance criterion must follow three rules:

1. **State, not action.** Describe the end state, not the activity. The criterion is what's *true* when the task is done, not what you *do* to complete it.
    - ✓ "Pagination endpoint returns correct page sizes for boundary cases"
    - ✗ "Test the pagination endpoint"

2. **Binary testable.** Every criterion must be answerable YES or NO with no judgment call. If you need to think about whether it's met, it's not specific enough.
    - ✓ "API returns 401 for expired tokens"
    - ✗ "Authentication works correctly"

3. **One short sentence.** Keep each criterion under ~15 words. If it's longer, it's probably two criteria — split it.
    - ✓ "All migration tests pass" + "Rollback script restores previous schema"
    - ✗ "All migration tests pass and the rollback script can restore the previous schema version"

The orchestrator (main Claude Code session):
- Creates and updates tasks
- Assigns tasks to subagents when appropriate
- Reviews gates based on risk level
- Does not implement tasks directly when subagents are available for the work

### 4.6 Project Archive & Reactivate Protocol

Projects have three lifecycle states: active (`Projects/`, workflow phase), done (`Projects/`, `phase: DONE`), or archived (`Archived/Projects/`, `phase: ARCHIVED`). Setting a project to DONE is a lightweight alternative to full archival — the project stays in place, remains visible to vault-check and session startup, but signals that active development is complete. Use DONE when the project has knowledge-base artifacts or may receive maintenance updates; use full archival when the project is purely historical. Both archival and reactivation are user-initiated — Claude does not archive or reactivate projects autonomously. The audit skill may flag archival candidates during monthly reviews (§7.5), but the action requires explicit user approval.

#### Archive Procedure

When the user requests archival ("archive the think-different project", "move X to archive", "I'm done with X for now"):

1. **Confirm with user.** State the project name and ask for confirmation. Archival is reversible but moves files — confirm intent.

2. **Precondition: clean working tree.** Run `git status` for the project directory. If there are uncommitted changes under `Projects/[project-name]/`, commit them first. If the state looks like a crash (files on disk but no matching run-log entry), run Session Interruption Recovery (§7.4) before proceeding with archival. Do not archive with uncommitted work on disk.

3. **Write final run-log entry.** Append a session block to the project's `run-log.md`:
   ```markdown
   ## Session: YYYY-MM-DD HH:MM

   **Context:** Project archived at user request.
   **Actions Taken:** Archived project — moved to Archived/Projects/
   **Current State:** Archived. All deliverables complete as of last active session.
   **Files Modified:** All project files (moved to Archived/Projects/[project-name]/)

   **Compound:** [Evaluate as normal — was there anything worth extracting from this project's overall arc? Patterns, lessons, reusable approaches? This is the last compound opportunity before the project leaves active rotation.]
   ```

4. **Append final progress-log entry:**
   ```markdown
   ## YYYY-MM-DD
   - 📦 Project archived
   ```

5. **Update project-state.yaml:**
   ```yaml
   phase: archived
   phase_before_archive: [phase value at time of archival, e.g., IMPLEMENT]
   archived_reason: [completed | paused | abandoned]
   next_action: null
   active_task: null
   updated: YYYY-MM-DD HH:MM
   last_committed: YYYY-MM-DD HH:MM
   ```
   The `phase_before_archive` field preserves the pre-archival phase for use during reactivation. This is set once during archival and read once during reactivation. The `archived_reason` field distinguishes completed projects (knowledge-base mining candidates) from paused projects (likely to return) and abandoned projects (may signal patterns worth examining in audit). Claude asks the user for the reason during the confirmation step.

6. **Move the project directory.** `mv Projects/[project-name] Archived/Projects/[project-name]`

   **Knowledge-base exception:** If a project contains artifacts with standalone knowledge-base value (biographical profiles, reference material, curated research tagged with `#kb/` topics), it stays in `Projects/` with `phase: ARCHIVED` rather than moving to `Archived/Projects/`. The rationale: `Archived/` buries content that belongs in the active knowledge graph. Projects whose artifacts are purely project mechanics (specs, migration plans, task lists) move to `Archived/` as normal. Claude should flag knowledge-base candidates during the confirmation step and let the user decide.

7. **Update companion note paths.** Any `type: attachment-companion` notes with `attachment.source_file` paths referencing `Projects/[project-name]/...` need their paths updated to `Archived/Projects/[project-name]/...`. This maintains the vault-check bidirectional reference invariant (§7.8 checks 12-13). If the project has no attachments, skip this step.

8. **Run vault-check.** Verify structural integrity after the move — especially companion note source_file paths (checks 12-13). Archive and reactivate are exactly the operations that stress these checks. If vault-check reports errors after the move, re-run the companion path update to catch any missed files, then re-run vault-check. If errors persist, flag to user before committing.

9. **Git commit.**
   ```
   git add -A
   git commit -m "archive: [project-name] — [one-line reason]"
   ```

**Post-archival behavior:**
- Archived projects do NOT appear in session startup project reporting
- Archived projects are NOT included in audit skill weekly reviews (monthly reviews may scan archives for knowledge base candidates — see §5.5)
- vault-check still validates archived projects (frontmatter, companion notes, etc.) — structural integrity doesn't expire
- Knowledge base artifacts (`#kb/` tagged notes) remain discoverable via tag search regardless of archive location

**Operational note:** Archive should be the only operation on that project in the current session. Do not mix content edits with the archive procedure — finish substantive work in a prior session, then archive in a dedicated pass.

#### Reactivate Procedure

When the user requests reactivation ("reopen think-different", "I need to work on X again", "pull X out of the archive"):

1. **Move the project directory back.** `mv Archived/Projects/[project-name] Projects/[project-name]`

2. **Update companion note paths.** Reverse of archival — update `attachment.source_file` paths from `Archived/Projects/...` back to `Projects/...`. If the project has no attachments, skip this step.

3. **Update project-state.yaml:**
   ```yaml
   phase: [value from phase_before_archive, unless user requests a different phase]
   phase_before_archive: null    # Clear — no longer relevant
   archived_reason: null         # Clear — project is active
   next_action: "[user states what they want to do, or Claude proposes based on context]"
   active_task: null
   updated: YYYY-MM-DD HH:MM
   last_committed: YYYY-MM-DD HH:MM
   ```
   Default: restore to the phase stored in `phase_before_archive`. The user may override this — see Phase Selection below. If `phase_before_archive` is missing or null (e.g., pre-v1.6.1 archival, manual archive, or corrupted state), default to `PLAN` and note the fallback in the run-log entry: "phase_before_archive missing; defaulted to PLAN."

4. **Write reactivation run-log entry:**
   ```markdown
   ## Session: YYYY-MM-DD HH:MM

   **Context:** Project reactivated from archive at user request. [Reason for reactivation.]
   **Actions Taken:** Reactivated project — moved from Archived/Projects/ back to Projects/
   **Current State:** [Phase restored to X. User intent: Y.]
   **Files Modified:** All project files (moved back to Projects/[project-name]/)
   ```

5. **Append progress-log entry:**
   ```markdown
   ## YYYY-MM-DD
   - 🔄 Project reactivated — [reason]
   ```

6. **Run vault-check.** Confirm structural integrity after the move — especially companion note source_file paths. Same error handling as archival: re-run path updates if checks fail, flag to user if errors persist.

7. **Git commit.**
   ```
   git add -A
   git commit -m "reactivate: [project-name] — [one-line reason]"
   ```

8. **Resume normal workflow.** The project is now active. Session startup will report it. Audit will include it. The user states what they want to do and normal routing takes over.

#### Phase Selection on Reactivation

Default behavior: restore `phase` to the value stored in `phase_before_archive` from project-state.yaml. This is mechanical — no log parsing needed.

The user may override the default:

- **Minor revision** (add images to profiles, fix typos, update content): Default phase is usually fine. Skip directly to execution. No need to re-specify.
- **Significant extension** (add a new major feature, restructure deliverables): Consider re-entering SPECIFY or PLAN to properly scope the new work. Claude should suggest this if the requested change is substantial relative to the original project scope.
- **User is unsure:** Restore to default phase and let the user state their intent. Route from there.

The decision is the user's. Claude may suggest re-entering an earlier phase if the scope warrants it, but doesn't enforce it.

### 4.7 Behavioral Boundaries

**System Behaviors (Claude handles autonomously):**

Context management, session logging, frontmatter generation, and vault maintenance are autonomous system behaviors — not manual checklist items. Claude manages these proactively as part of normal processing:

- **Context management:** Follow the Context Checkpoint Protocol (§4.1.4) at phase transitions and before heavy operations. Manage `/context`, `/compact`, and `/clear` automatically based on capacity thresholds.
- **Session logging:** Write session outcomes to `run-log.md` before ending project sessions. For non-project sessions that produced meaningful work, write an entry to `_system/logs/session-log.md` (§2.3.4) with compound evaluation before ending. If a session went clearly poorly (repeated errors, dead ends, rework, user frustration), write a diagnosis entry to `_system/docs/failure-log.md` (§4.8) — this is autonomous, not gated behind a user rating. Log to `run-log.md` before using `/clear`. Log phase transitions to `progress-log.md` at major milestones.
- **Document conventions:** Write frontmatter on every new document. Read summaries before full documents.
- **Summary freshness:** When modifying any document that has a corresponding `*-summary.md`, regenerate the summary as part of the same operation, setting the summary's `source_updated` to match the parent's `updated` value. When loading any summary, compare its `source_updated` against the parent's `updated` — if mismatched, regenerate before use.
- **Vault maintenance:** Run the audit skill's session-start staleness scan at the beginning of every session (§3.1.4). Full audit runs on user request or when the staleness scan recommends it. Flag medium/high-risk maintenance actions for human review.

**Always (workflow discipline):**
- Write acceptance criteria for every task (format rules: state not action, binary testable, one short sentence — see §4.5)
- Run tests before marking code complete
- Log decisions and major changes to `run-log.md`
- Run compound reflection at every phase transition (enforced via Context Checkpoint Protocol §4.1.4); run discretionary compound steps mid-phase when trigger criteria are met
- Never skip phases within the active workflow

**Ask First (medium/high risk):**
- Changing architecture or adding dependencies
- Modifying schemas or migrations
- Sending external communications
- Creating files outside the vault structure
- Creating new primitives (skills, subagents, overlays) — see Primitive Creation Protocol §3.6
- Writing medium-confidence compound patterns to `_system/docs/solutions/` — see §4.4
- Modifying CLAUDE.md, skill definitions, or overlay index

**Never:**
- Implement without a validated spec (for substantial work)
- Merge to main/production without gate checks
- Make medical, legal, or major financial decisions autonomously
- Load more than 10 source documents into a single skill invocation (design ceiling — decompose the task or compress summaries instead; see §5.4)

### 4.8 Hallucination Detection Protocol

Full procedure: `_system/docs/protocols/hallucination-detection-protocol.md`

**Purpose:** Prevent LLM hallucinations from corrupting the knowledge base or influencing decisions. Applies to non-code outputs, compound insights, pattern extraction, context retrieval, summary generation.

**Four activation tiers:**

| Tier | Key Checks | When |
|---|---|---|
| **Always-on** | Confidence tagging, context relevance justification, falsifiability (compound only), interpretation flagging | Every relevant operation |
| **Risk-proportional** | Provenance check (subagent gap, session gap) | Consuming summaries not generated in current session |
| **Audit-time** | Calibration tracking, deep provenance, summary spot-checks | Weekly audit or on failure discovery |
| **Human-grounded** | User validates 1 pattern + 1 summary | Monthly audit |

**7 procedures:** (1) Falsifiability check, (2) Provenance check with risk-proportional depth, (3) Calibration tracking with 8-type failure taxonomy → `failure-log.md`, (4) Confidence tagging (high/medium/low with promotion rules), (5) Summary generation rules (verbatim preservation, interpretation flagging), (6) Context relevance justification, (7) Human-grounded monthly validation. See standalone doc for full details.

### 4.9 Signal Capture Protocol (Deprecated v2.2)

Retired. Interactive session rating removed (zero entropy). Session quality now assessed autonomously via failure-log. Archive: `_system/docs/signals-archive-2026.jsonl`.

**Retention policies for append-only stores:**

The following data stores grow monotonically. Retention thresholds prevent discovery degradation as the vault scales:

| Store | Growth Pattern | Retention Rule | Trigger |
|---|---|---|---|
| `_system/docs/solutions/` | Variable — compound step output | Consolidation pass when category exceeds 15 docs. Merge overlapping patterns into category summaries. | Weekly audit (existing 50-doc trigger remains; 15-per-category is finer-grained) |
| `_system/docs/failure-log.md` | ~1 entry per session that went clearly poorly | Archive entries older than 6 months to `_system/docs/failure-log-archive-YYYY.md`. Active file retains recent failures for trend analysis. | Monthly audit checks entry dates |
| `session-log*.md` | Monthly rotation (existing) | Archived logs accumulate at vault root. No further action needed — monthly rotation already bounds active file size. | Automatic via monthly rotation |

**Implementation:** The audit skill applies these during monthly checks. Archiving moves entries to dated archive files — no data is deleted.

---

## 5. Context Policy & Obsidian Usage

### 5.1 Context Types

| Type | What | Where |
|---|---|---|
| **Stable identity & config** | Values, domains, goals, skill catalog, behavioral boundaries | `AGENTS.md`, `CLAUDE.md`, `/_system/docs/` |
| **Project/domain state** | Specs, designs, plans, decisions, logs, progress | `/Projects/[name]/`, `/Domains/[domain]/` |
| **Cross-project knowledge** | Reusable patterns, decision heuristics, calibration data | `/_system/docs/solutions/` |

### 5.2 File Access Strategy

The vault is accessed through two complementary tool layers, with routing handled by the Obsidian CLI skill (§3.1.5):

| Tool | Use When | Strengths |
|---|---|---|
| **Native file tools** (Read, Write, Edit, Grep, Glob) | Always available. Primary for direct read/write, bulk text operations, and when Obsidian is not running. | No dependencies, works offline, fast for direct file manipulation |
| **Obsidian CLI** (1.12+) | Obsidian is running. Primary for discovery, navigation, and structured queries. | Indexed search, backlinks, property queries, tag hierarchy, orphan detection — minimal token cost |

**Phase 1 (Week 1):** Both tools available from day one
- Native file tools for direct read/write operations
- Obsidian CLI for indexed queries (search, tags, backlinks, properties) when Obsidian is running
- CLI skill (§3.1.5) handles routing and fallback automatically
- All files follow frontmatter conventions (§2.2) from day one — required for CLI property and tag queries

**Phase 2+ (if needed):** Evaluate MCP or semantic search
- If CLI + file tools leave significant gaps (e.g., Dataview-style computed queries, or workflows where Obsidian can't be running), evaluate adding Obsidian MCP
- If keyword-based search proves insufficient for vault discovery (e.g., can't locate knowledge artifacts when exact terms aren't recalled), evaluate qmd as a semantic search layer — see §9 (Deferred Items) for details and adoption paths
- These are contingencies if the primary tools prove insufficient, not planned milestones
- See §9 (Deferred Items) for deferral rationale

**Fallback behavior:** If the CLI is unavailable (Obsidian not running, CLI not installed), the system degrades gracefully to native file tools. The CLI skill detects availability at session start (`obsidian vault`) and routes accordingly. All core workflows function with file tools alone — the CLI adds speed and discovery capabilities, not required functionality.

**Obsidian CLI capabilities** (see §3.1.5 for safe command patterns):
- `obsidian search` — indexed full-text search with JSON output
- `obsidian backlinks` / `obsidian links` — incoming and outgoing link traversal
- `obsidian tag` / `obsidian tags` — tag queries with hierarchy and counts
- `obsidian properties` / `obsidian property:set` — native frontmatter read/write
- `obsidian tasks` — vault-wide task queries and status toggling
- `obsidian orphans` / `obsidian unresolved` — knowledge base health checks
- `obsidian read` / `obsidian append` / `obsidian prepend` / `obsidian create` — file CRUD

### 5.3 Summary Document Structure

Summaries are compressed versions of full documents designed for rapid context loading. Every summary follows this pattern:

```markdown
---
[same frontmatter as parent doc, with type: summary]
source_updated: YYYY-MM-DD    # parent doc's `updated` value when this summary was generated
---

# [Document Name] Summary

**Parent document:** [link to full doc]
**Last updated:** YYYY-MM-DD

## Core Content
[2-4 paragraphs capturing essential information]

## Key Decisions
[Bulleted list of critical choices made]

## Interfaces/Dependencies
[What this connects to; what depends on it]

## Next Actions
[What downstream work needs from this doc]
```

**Summaries are read-only references.** Always update the parent document first, then regenerate the summary.

#### Summary Freshness Protocol

Summaries are derivatives of parent documents. Stale summaries silently feed wrong context to downstream skills and subagents. Two mechanisms work together to prevent this:

**Preventive — Regenerate on modify:**
When modifying any document that has a corresponding `*-summary.md`, regenerate the summary as part of the same operation. When regenerating, set the summary's `source_updated` to match the parent's `updated` value. This is the primary defense against drift. Subagents producing design documents must generate summaries alongside the parent docs, not as a separate step.

**Safety net — Mechanical staleness detection:**
Every summary carries a `source_updated` field in its frontmatter, recording the parent document's `updated` timestamp at the time the summary was generated. When any skill or the orchestrator loads a summary:

1. Read the summary's `source_updated` value
2. Read the parent document's `updated` value
3. If they don't match: the summary is stale — regenerate it before use, updating `source_updated` to the new `updated` value
4. If they match: the summary is fresh — proceed

**Why this works:** Staleness detection is a data comparison, not a behavioral expectation. The producer doesn't need to remember to flag anything — the consumer verifies mechanically every time. This catches all drift paths: interrupted sessions, subagent failures, manual edits outside Claude Code, or any scenario where the regenerate-on-modify step was missed.

#### Summary Quality Rules (Hallucination Prevention)

To prevent hallucination in summaries, follow these rules from §4.8. These are the always-on lightweight rules — deeper provenance analysis happens during weekly audits (§4.8.2).

1. **Preserve critical content verbatim**
    - Don't paraphrase critical constraints, requirements, or decisions
    - Use quotes for exact language: `"The API must support pagination for lists >100 items"`

2. **Flag interpretations**
    - If the summary draws conclusions not explicit in source: mark as `[INTERPRETATION]`
    - Example: `[INTERPRETATION: This suggests we need real-time updates]`

3. **Source-level citation (high-stakes documents only)**
    - For specifications, architecture decisions, and API contracts: include section references (e.g., "See specification.md §3.2 for rationale")
    - For routine summaries: skip section-level citations — verbatim preservation and interpretation flagging are sufficient

4. **Drift detection** (safety net via audit skill)
    - Audit skill (§3.1.4) spot-checks summaries weekly with deep provenance analysis (§4.8.2)
    - If drift found despite preventive mechanisms: regenerate all summaries for that project, investigate whether the regenerate-on-modify step is being consistently followed
    - Log summary drift to `_system/docs/failure-log.md`

### 5.4 Context Budget Management

**Budget Tiers:**

Skills should load the minimum context needed for the current task. These tiers are **operating targets**, not real-time enforcement — Claude Code has no native mechanism for tracking document load counts. The context inventory (below) creates an auditable record, and the audit skill flags chronic overloading.

| Tier | Documents | When | Logging |
|---|---|---|---|
| **Standard** | ≤5 source documents | Default for most skill invocations | Context inventory only (see below) |
| **Extended** | 6-8 source documents | Iteration passes, multi-input skills, cross-domain tasks | Context inventory + justification: "Loading [N] docs because [specific reason]" |
| **Design ceiling** | 10 source documents | Target maximum. If you need more, decompose the task or regenerate summaries to compress inputs. | N/A — this threshold means stop and rethink approach |

**What counts as a source document:**
- Any file read from the vault: summaries, specs, pattern docs, design docs, calibration data, tasks

**What does NOT count:**
- The user's current prompt
- Always-loaded system context (CLAUDE.md, AGENTS.md)
- Overlays (instructional context, not source material — keep each under 65 lines)
- `_system/docs/personal-context.md` (instructional context — under 50 lines, loaded for behavioral shaping)

**Additional limits:**
- Subagents: No hard limit (isolated context), but still favor summaries over full docs
- Searches: Scope by project/domain + specific topic; never unbounded vault searches

#### Context Inventory (Mechanical Visibility)

After loading context and before beginning core work, every skill writes a context inventory to the run-log:

```markdown
**Context Inventory:** [skill-name] | [N] source docs
- [filename-1] — [one-line reason]
- [filename-2] — [one-line reason]
- [filename-N] — [one-line reason]
Tier: standard | extended ([justification if extended])
```

**Why this exists:** Claude Code cannot reliably self-track document loads across a fluid session. The context inventory is a snapshot — one discrete write at one moment — rather than ongoing counting. It creates an auditable record without requiring Claude to maintain a running tally. The audit skill reviews these inventories to detect chronic budget overruns.

**When to write:** After the "Gather Context" and "Check Overlay Index" steps complete, before the skill begins its core procedure. If additional documents are loaded mid-procedure (e.g., a search reveals a relevant pattern doc), append them to the inventory in the same run-log entry.

**Budget calibration:** If a skill regularly operates in the extended tier, that's a signal worth investigating during the compound step or weekly audit. Possible causes: skill context contract needs revision, summaries aren't compressing effectively, or the skill should be decomposed.

**Relevance validation (from §4.8):**
- When loading a document from vault: explicitly state why it's relevant to current task
- Format: "Loading [filename] because [specific reason tied to current task]"
- If relevance is unclear after reading: discard document, don't use it in analysis

**Examples:**
- ✓ "Loading career-transition-pattern.md because current task involves career change to tech industry"
- ✗ "Loading career-transition-pattern.md because it might be useful"

**For searches returning multiple documents:**
- Rank by relevance to current task
- Load top 3-5 only
- Explain ranking: "Prioritizing X over Y because current task emphasizes [aspect]"

**Typical query patterns:**

```bash
# Systems Analyst starting a new project (standard tier: 2-3 docs)
# Use file tools for direct reads, CLI for indexed searches
Read Domains/Career/career-overview.md
obsidian search query="tag:problem-pattern career-transition" format=json matches

# Systems Analyst iterating after design feedback (extended tier: 6-7 docs)
# Justification: Revisiting spec after frontend design revealed UX constraints
Read Projects/myapp/specification-summary.md
Read Projects/myapp/design/frontend-design-summary.md
Read Projects/myapp/design/backend-design-summary.md
Read Domains/Career/career-overview.md
obsidian search query="tag:problem-pattern api-design" format=json matches
Read _system/docs/estimation-calibration.md

# Action Architect planning tasks (standard or extended: 3-6 docs)
Read Projects/myapp/specification-summary.md
Read Projects/myapp/design/frontend-design-summary.md
Read Projects/myapp/design/backend-design-summary.md
Read _system/docs/estimation-calibration.md

# Code task execution (standard tier: 2-3 docs)
Read Projects/myapp/tasks.md  → extract current task
Read Projects/myapp/design/api-spec.md  → extract relevant endpoint
obsidian search query="tag:backend-patterns pagination" format=json matches

# Knowledge base discovery (use CLI for tag and backlink queries)
obsidian tag name=kb/api-design  → find knowledge artifacts about API design
obsidian backlinks path=Domains/Career/career-overview.md  → find all notes linked from career domain
```

### 5.5 Knowledge Base Protocol

The Obsidian vault serves as both operational infrastructure (project files, logs, system docs) and a **personal knowledge base** ("second brain"). Output deliverables with durable value beyond their originating project are promoted to the knowledge base via tags and backlinks — not by copying files or creating a separate directory structure.

**The knowledge base is a view, not a location.** Knowledge artifacts stay where they were created (in their project or domain folder). They become discoverable through `#kb/*` tags and backlinks from domain summaries. The Obsidian CLI makes these queries cheap and fast.

#### Tagging Convention

Knowledge base artifacts use a three-level `#kb/` tag hierarchy. Three levels is the hard cap — do not nest deeper.

```text
Level 1 (fixed):     #kb/
Level 2 (defined):   #kb/[topic]
Level 3 (emergent):  #kb/[topic]/[subtopic]
```

**Level 2 — Defined Topics:**

These are the canonical second-level tags. Use existing tags when they fit; create new Level 2 tags only when a topic is genuinely outside all existing categories.

| Tag | Scope |
|---|---|
| `#kb/religion` | Faith, theology, spiritual practice, religious history |
| `#kb/philosophy` | Ethics, metaphysics, epistemology, philosophical traditions, thinkers |
| `#kb/gardening` | Plants, landscaping, soil, seasonal planning |
| `#kb/history` | Historical events, figures, eras, historiography |
| `#kb/inspiration` | Motivational frameworks, quotes, exemplars, mindset |
| `#kb/poetry` | Poems, poetic form, literary analysis |
| `#kb/writing` | Craft of writing, style, editing, rhetoric |
| `#kb/business` | Strategy, market dynamics, business models, positioning |
| `#kb/networking` | Networking infrastructure, DHCP, IPAM, network design |
| `#kb/security` | Infosec, DNS-based security, threat models, hardening |
| `#kb/software-dev` | Coding, architecture, tooling, development practices |
| `#kb/customer-engagement` | Account management, relationship patterns, engagement workflows |
| `#kb/training-delivery` | Curriculum design, presentation, training materials, delivery patterns |
| `#kb/fiction` | Novels, short stories, literary fiction, genre fiction, narrative analysis |
| `#kb/biography` | Biographical profiles, memoirs, life stories, historical figures |
| `#kb/politics` | Political theory, governance, policy, political history, civic systems |
| `#kb/psychology` | Behavioral science, cognitive science, mental models, decision-making |
| `#kb/lifestyle` | Home management, domestic arts, personal systems, daily life patterns |

**Level 3 — Emergent Subtopics:**

Third-level tags are NOT predefined. They emerge through compound engineering when a second-level topic accumulates enough notes that finer-grained filtering becomes useful. Examples:

```text
#kb/networking/dns
#kb/networking/dhcp
#kb/networking/ipam
#kb/business/pricing
#kb/customer-engagement/onboarding
```

**Subordination rule:** When a candidate Level 2 tag is clearly a subtopic of an existing Level 2 (e.g., DNS is subordinate to networking, not a peer), use Level 3 instead of creating a new Level 2. Cross-domain topics use dual tagging — e.g., a DNS security note gets `kb/networking/dns` + `kb/security` rather than inventing a fourth level.

The compound step creates new Level 3 tags when it routes knowledge to a Level 2 topic and recognizes a distinct subtopic cluster forming. The audit skill's tag hygiene check (weekly) monitors for:
- Level 3 tags with only 1 note (premature fragmentation — consider removing)
- Level 2 tags with 15+ notes and no subtopics (may benefit from splitting)
- Level 3 tags that duplicate each other (consolidate)

**Tag depth enforcement:** `#kb/topic/subtopic` is the maximum. If you find yourself wanting `#kb/networking/dns/rpz`, use `#kb/networking/dns` and dual-tag with `#kb/security`. The CLI's full-text search handles finer specificity.

The `#kb/` prefix is orthogonal to existing tags (domain, project, type, status). A note can be both `#domain/career` and `#kb/customer-engagement` — the domain tag classifies *where it belongs*, the kb tag classifies *what knowledge it contains*.

**Tag granularity:** Use topic-level tags, not document-level. `#kb/networking/dns` covers DNS patterns, decisions, and lessons — not one specific spec. The CLI's `obsidian tag name=kb/networking` returns all networking notes including DNS, DHCP, etc.; `obsidian tag name=kb/networking/dns` returns only DNS notes.

#### Promotion Mechanism

Knowledge capture happens through the compound step (§4.4). When a task produces a deliverable with durable value, the compound step:

1. **Identifies the knowledge.** Ask: "Does this deliverable contain insights, frameworks, analysis, or decisions that would be useful beyond this project?" If yes, proceed.
2. **Tags the deliverable.** Add the appropriate `#kb/[topic]` tag to the document's frontmatter. Use an existing `#kb/` tag if one fits; create a new one if the topic is genuinely new.
3. **Links from domain summary.** Add a backlink from the relevant domain summary (`Domains/[domain]/[domain]-overview.md`) to the knowledge artifact. This makes the domain summary a curated entry point for domain knowledge.
4. **Place in MOC.** Run the placement pass (§5.6.6): add `topics` to frontmatter, insert one-liner in the target MOC's Core section. If no suitable MOC exists and the topic has 5+ notes, create one.

**What qualifies as durable knowledge:**
- Analysis frameworks or decision models that apply beyond one project
- Technical deep-dives that capture expertise (not just implementation details)
- Strategy documents, career plans, learning syntheses
- Reusable templates, checklists, or evaluation criteria
- Post-project retrospectives with transferable lessons

**What does NOT qualify:**
- Project-specific implementation details (task lists, individual code specs)
- Transient status documents (progress logs, session-log entries)
- System operational files (run-log, convergence rubrics, failure log)

#### Discovery Patterns

With the Obsidian CLI, knowledge retrieval is fast and cheap:

```bash
# Find all knowledge artifacts on a topic (includes all subtopics)
obsidian tag name=kb/networking/dns

# Find all networking notes (includes dns, dhcp, ipam subtopics)
obsidian tag name=kb/networking

# Find what knowledge connects to a domain
obsidian backlinks path=Domains/Career/career-overview.md

# Find orphaned knowledge (tagged but not linked from any domain summary)
# Used by audit skill for knowledge base health checks
obsidian tag name=kb  → get all kb-tagged notes
# Then check each for backlinks from a domain summary

# Browse the full knowledge base tag hierarchy
obsidian tags all counts | grep "kb/"
```

#### Audit Integration

The audit skill (§3.1.4) includes knowledge base health checks in its weekly review:
- **Orphaned knowledge:** `#kb/*` tagged notes not linked from any domain summary
- **Untagged candidates:** Completed project deliverables that might deserve `#kb/` tagging but don't have it (heuristic: check recently archived projects for analysis docs, strategy docs, and deep-dive notes)
- **Tag hygiene:** Duplicate or overly granular `#kb/` tags that should be consolidated

---

### 5.6 Maps of Content (MOC) System

#### 5.6.1 What MOCs Are

A MOC is a markdown note with `type: moc-orientation` or `type: moc-operational` in its frontmatter. Its purpose is to compress the current state of a topic into a single artifact that enables:

- **60-second re-orientation** — load one file, know what matters, what changed, and where to go next
- **Synthesis** — prose explaining how the pieces within a topic fit together, not just a list of what exists
- **Intent-based routing** — "if you're designing X, start with [[A]]; if you're debugging, jump to [[B]]"
- **Gap and tension surfacing** — what's missing, what contradicts, what's unresolved

A MOC is NOT:

- A folder or tag (it's a note that participates in the graph like any other)
- A replacement for `#kb/` tags (tags provide flat discovery; MOCs provide structured navigation with synthesis)
- A source of truth for claims (MOC prose is routing and status; atomic notes own the claims)

**MOCs participate in `#kb/` queries by design.** MOCs carry `#kb/` tags matching their topic (e.g., `moc-networking` carries `#kb/networking` and `#kb/networking/dns`). When you search `obsidian tag name=kb/networking/dns`, the MOC appears alongside atomic notes — and it should, because the MOC is the best orientation entry point for that topic. If you need only atomic notes, filter by `type` (exclude `moc-orientation` and `moc-operational`).

#### 5.6.2 Two MOC Types

| Type | Purpose | Success Criterion | Lint Focus |
|---|---|---|---|
| `moc-orientation` | Conceptual map + synthesis. "What do we know about this topic?" | Reduces time-to-reorientation; improves path selection | Delta freshness, section overload, missing tensions/open questions, synthesis present if Core is non-trivial |
| `moc-operational` | Execution playbook. "How do we do this thing?" Links to underlying rationale. | Reliably produces correct outcomes (steps, prerequisites, failure modes) | Prerequisites declared, verification steps present, failure modes listed |

The agent routes based on intent: "am I trying to understand something?" → orientation MOC. "Am I trying to execute something?" → operational MOC. Both types share the same skeleton (§5.6.3) but differ in emphasis and lint rules.

#### 5.6.3 MOC Skeleton

Every MOC file follows this structure:

**Frontmatter:**

```yaml
---
type: moc-orientation           # moc-orientation | moc-operational
domain: software                # software | career | health | learning | etc.
scope: dns-migration-patterns   # kebab-case topic identifier — what this MOC covers
status: active                  # active | archived
skill_origin: null              # or skill name if machine-generated
created: 2026-02-18
updated: 2026-02-18
last_reviewed: 2026-02-18       # date of last review transaction
review_basis: full              # delta-only | full | restructure
notes_at_review: 0              # count of notes in Core at time of last review
tags:
  - moc
  - kb/networking/dns            # MOCs carry the kb/ tag of their topic
---
```

**Body:**

```markdown
# [Topic Name]

<!-- DELTAS:START -->
## Deltas
<!-- Machine-derivable: new notes since last_reviewed, status changes,
     contradictions discovered, active threads. This section is always
     current even if synthesis lags — it is the anti-staleness mechanism. -->
<!-- DELTAS:END -->

<!-- SYNTHESIS:START -->
## Synthesis
<!-- Prose explaining how the pieces in Core fit together. Any claim-like
     sentence MUST link to the backing atomic note that owns it.
     MOC prose is routing and status, not canonical truth. -->
<!-- SYNTHESIS:END -->

<!-- CORE:START -->
## Core
<!-- 5–12 canonical nodes. Each entry as a structured one-liner:
- [[note-title]] — what it is | when to use | failure mode or tension
-->
<!-- CORE:END -->

## Paths *(orientation MOCs: optional — add once real usage patterns exist; operational MOCs: required)*
<!-- Intent → recommended first hop. Examples:
- Designing a new migration? Start with [[migration-architecture-template]]
- Debugging a failed cutover? Jump to [[cutover-failure-modes]]
- Evaluating a customer's readiness? See [[migration-readiness-checklist]]
-->

## Tensions / Open Questions
<!-- Tradeoffs, contradictions, research backlog. Examples:
- Phased vs. big-bang migration: [[phased-migration-case]] vs [[big-bang-case]] — no clear winner, depends on zone count
- Open: What's the zone count threshold where phased becomes mandatory?
-->
```

**HTML comment anchors:** The `<!-- SECTION:START -->` / `<!-- SECTION:END -->` markers around Deltas, Synthesis, and Core enable deterministic edits by the placement pass and synthesis skill. Without these, heading reorganization during synthesis would break naive "append to ## Core" logic. Non-anchored sections (Paths, Tensions) are edited less frequently and by human judgment, so anchors are optional there.

**Section requirements by type:**

| Section | Orientation MOC | Operational MOC |
|---|---|---|
| Deltas | Required | Required |
| Synthesis | Required (when Core > 3 notes) | Optional (replaced by Steps/Procedure) |
| Core | Required | Required (links to rationale notes) |
| Paths | Optional | Required (this IS the routing — prerequisites, steps, verification) |
| Tensions / Open Questions | Required | Optional (failure modes and edge cases instead) |

#### 5.6.4 MOC Location

MOCs live in the domain directory most closely associated with their topic:

```text
Domains/
├── Career/
│   ├── career-overview.md
│   ├── moc-customer-engagement-patterns.md
│   └── moc-dns-migration-patterns.md
├── Learning/
│   ├── learning-overview.md
│   └── moc-agent-architecture-research.md
├── Creative/
│   ├── creative-overview.md
│   └── moc-historical-research-methods.md
```

**Naming convention:** `moc-[topic-slug].md` — the `moc-` prefix makes MOCs instantly identifiable in file listings and grep results.

**Cross-domain MOCs:** If a topic genuinely spans multiple domains (rare), place the MOC in the domain where it's most frequently accessed and add a cross-reference link from the other domain's summary. Do not create duplicate MOCs.

**Relationship to domain summaries:** Domain summaries (`Domains/[domain]/[domain]-overview.md`) are the broad entry point to a domain. MOCs are topic-level detail within a domain. Domain summaries SHOULD link to their MOCs. This creates the navigation hierarchy: domain summary → MOC → atomic notes.

#### 5.6.5 The `topics` Field — MOC Membership

Every non-ephemeral note in the knowledge base MUST declare which MOC(s) it belongs to via a `topics` field in frontmatter:

```yaml
topics:
  - moc-dns-migration-patterns        # primary MOC (filename without .md)
  - moc-customer-engagement-patterns   # secondary MOC (if note bridges topics)
```

**Rules:**

1. The `topics` requirement applies to any note that has a `#kb/` tag in its **frontmatter `tags[]` array**. Inline hashtags in the note body do not trigger this requirement. This matches vault-check's existing tag detection model — frontmatter is the source of truth for structural metadata.
2. Every entry in `topics` MUST resolve to an existing MOC file (validated by vault-check — see §5.6.10).
3. A note without valid `topics` cannot be committed as stable knowledge. It can exist in draft/inbox state but must be placed before promotion.
4. `topics` entries are filenames without the `.md` extension and without path prefix — the MOC's `domain` field and `scope` field together with the `moc-` prefix make each MOC uniquely identifiable.
5. Primary vs. secondary distinction is optional (order implies priority — first entry is primary). Enforcing an explicit `primary_topic` field is deferred until placement patterns stabilize.
6. Internally, Crumb treats `topics` entries as `member_of` edges for routing purposes. Externally, they are simple filename references — no graph formalism is exposed to the operator.

**Simplified exemption rule:** A note requires `topics` if and only if (a) its frontmatter `tags[]` contains any entry starting with `kb/`, AND (b) its frontmatter `type` is not `moc-orientation` or `moc-operational`. MOC files carry `kb/` tags by design (they participate in kb queries — see above) but are themselves the targets of `topics`, not members. Requiring MOCs to have `topics` would create circular self-references. All other non-kb-tagged notes (project implementation docs, logs, session records, system infrastructure) are also exempt.

**Bootstrapping:** When creating notes in a new topic area where no MOC exists yet, create the MOC first (even as a skeleton with empty sections), then create the notes pointing to it. This prevents circular dependencies. The MOC can start as just frontmatter + headings with no content — the placement pass populates it.

#### 5.6.6 Placement Pass (Deterministic — No LLM Required)

When a note is created or promoted to `#kb/` status, the placement pass runs as part of the same operation:

1. **Set `topics`.** Add the target MOC filename(s) to the note's frontmatter.
2. **Add to MOC Core section.** Insert a structured one-liner inside the `<!-- CORE:START -->` / `<!-- CORE:END -->` anchors of each target MOC:
   ```markdown
   - [[note-title]] — what it is | when to use | failure mode or tension
   ```
3. **Bump the MOC's `updated` field.** Set `updated` to current date.
4. **Increment delta.** The Deltas section will reflect this addition on the next delta computation (or immediately if the placement pass includes delta refresh).

**This pass is deterministic.** It does not require LLM judgment — it's a mechanical insertion of a structured entry. The one-liner format is consistent across all entries to enable later synthesis.

**One-liner quality matters.** The one-liner is the atom from which synthesis is later built. Bad one-liners degrade synthesis quality. The format `what it is | when to use | failure mode or tension` provides three dimensions:

- **What it is** — the note's core claim or content (drawn from the note's title or description)
- **When to use** — the context in which this note is relevant (helps routing)
- **Failure mode or tension** — what goes wrong or what tradeoff this note captures (helps gap detection)

If a dimension isn't applicable, omit it rather than forcing a generic placeholder.

**Soft one-liner quality lint:** vault-check emits an informational warning (not error, not blocking) if a one-liner in Core is shorter than 10 characters after the `[[...]]` link. This catches drive-by placements where the operator adds a link without any descriptive context. The intent is nudging, not enforcement.

**Integration with existing workflows:**

- **Compound step (§4.4):** When the compound step promotes a deliverable to `#kb/` status, the placement pass runs immediately after tagging. The compound step already "Links from domain summary" (§5.5); "Place in MOC" runs as a parallel step.
- **Inbox processor (§3.3):** When the inbox processor creates a companion note with `#kb/` tags, it also runs the placement pass. If the inbox processor can't determine the appropriate MOC, it tags `needs-placement` for manual resolution.
- **Manual note creation:** Any note created with `#kb/` tags during a governed session must include `topics` and trigger the placement pass. vault-check enforces this.

#### 5.6.7 Synthesis Pass (LLM — Gated by Debt Score)

Synthesis is the expensive, judgment-heavy operation that converts a MOC from a structured index into an orientation artifact. It runs only when the MOC debt score (§5.6.8) crosses the threshold.

**When synthesis runs, it MUST:**

1. Read the MOC's linked note descriptions (one-liners in Core).
2. Rewrite the Synthesis section (inside `<!-- SYNTHESIS:START -->` / `<!-- SYNTHESIS:END -->` anchors) explaining how the pieces fit together. Every claim-like sentence must link to the backing note.
3. Reassess section groupings — propose splits if any section exceeds 20 links.
4. Update Tensions / Open Questions based on new content.
5. Update `last_reviewed` to current date.
6. Update `review_basis` to `full` or `restructure` (depending on scope of changes).
7. **Recompute `notes_at_review`** to current count of Core entries. **Invariant: any operation that updates `last_reviewed` MUST also recompute `notes_at_review` in the same write.** These two fields form a transaction — updating one without the other corrupts the debt score.
8. Preserve all deterministic placements — synthesis may reorganize headings and rewrite prose, but must NOT silently drop links added by the placement pass.

**When synthesis runs, it MAY:**

- Add or update Paths entries based on observed usage patterns.
- Propose MOC splits when a subtopic has grown large enough (>20 notes).
- Propose MOC merges when topics have converged.
- Promote recurring cross-MOC patterns to dedicated synthesis notes.
- Identify notes that should be in this MOC but aren't (candidates section).

**Review basis semantics:**

| Value | Meaning | Trust Level |
|---|---|---|
| `delta-only` | Only looked at changes since last review | Links are current; synthesis may be stale |
| `full` | Re-read all one-liners and rewrote synthesis | Links and synthesis are current |
| `restructure` | Reorganized sections, split/merged headings, major changes | Full structural refresh |

The delta-only pass is the cheap maintenance operation — it updates the Deltas section and verifies new placements are correct without rewriting synthesis. A full pass rewrites synthesis. A restructure pass changes the MOC's organization.

#### 5.6.8 MOC Debt Score

A single scalar metric that surfaces which MOCs need attention. Computed mechanically (no LLM) using three signals, weighted by review basis:

**Signals:**

| Signal | Computation | Weight |
|---|---|---|
| **Delta count** | Number of notes added to Core since `last_reviewed` (current Core count − `notes_at_review`) | 3 points per new note |
| **Staleness** | Days since `last_reviewed`, **but only accrues when delta_count > 0** | 1 point per day |
| **Section overload** | Total number of entries in Core (between `<!-- CORE:START -->` and `<!-- CORE:END -->`) exceeding 15 | 5 points per threshold breach (binary: 0 or 5) |

**Review basis multiplier:**

| Last `review_basis` | Multiplier | Rationale |
|---|---|---|
| `restructure` | 0.5x | Fresh structural review — debt accumulates slowly |
| `full` | 1.0x | Standard synthesis — normal debt accumulation |
| `delta-only` | 1.5x | Only skimmed changes — synthesis likely lagging |

**Formula (single expression):**

```
debt = (delta_count × 3 + (staleness_days × 1 if delta_count > 0 else 0) + (5 if core_entries > 15 else 0)) × review_basis_multiplier
```

Where:
- `delta_count` = current Core entry count − `notes_at_review`
- `staleness_days` = days since `last_reviewed`
- `core_entries` = total `[[...]]` links between `<!-- CORE:START -->` and `<!-- CORE:END -->`
- `review_basis_multiplier` = 0.5 | 1.0 | 1.5 based on `review_basis` field

**Staleness gating rationale:** Without the `delta_count > 0` guard, a dormant topic (no new notes) accumulates staleness forever and eventually triggers synthesis on a MOC where nothing has changed. The guard ensures that time only becomes a factor when there's actual new content to synthesize. A MOC with no new notes has zero debt regardless of age.

**Threshold:** Synthesis is triggered when debt exceeds **30 points**. This is a starting value — tune based on empirical experience. At typical creation rates (2-5 notes per domain per week), this triggers synthesis roughly every 2-3 weeks per active MOC.

**Session startup integration:** Debt scores are computed during the session-start staleness scan (§3.1.4, §7.1). The top 3 MOCs by debt are surfaced to the operator. Format:

```
MOC Debt: moc-dns-migration-patterns (47) | moc-customer-engagement (33) | moc-crumb-architecture (31)
```

If any MOC exceeds the threshold, the report includes a recommendation: "moc-dns-migration-patterns exceeds debt threshold (47 > 30) — synthesis pass recommended."

**Known limitation — bulk-update delta inflation:** If a formatting pass or mass-rewrite touches the `updated` field on many notes simultaneously (e.g., frontmatter standardization, tag restructuring), every affected note's updated timestamp changes and every referencing MOC's delta count spikes. This can falsely trigger synthesis across many MOCs. Not worth solving now — the operator can recognize a bulk-update-triggered debt spike and ignore it. Future escape hatch: a `mechanical-update` tag or commit-message convention that delta computation ignores.

#### 5.6.9 Bridge-Candidate Lint

When a note appears in ≥3 MOCs (has 3+ entries in `topics`), it is structurally important — it bridges multiple topic areas. To prevent bridge notes from becoming incoherent glue:

**Rule:** Any note with 3+ entries in `topics` SHOULD include either:

- A `## Scope` or `## Boundary` section in its body (≥2 sentences defining what this note covers and where its boundaries are), OR
- A link to a dedicated boundary/interface note in `related.docs`

**Severity:** Audit diagnostic only (reported by the audit skill, not vault-check). Bridge notes should be scoped, but this is a quality heuristic best surfaced during periodic review, not a commit-blocking gate. The audit skill reports bridge-candidate warnings alongside MOC debt scores in its weekly review.

#### 5.6.10 Vault-Check Additions

Add these checks to `_system/scripts/vault-check.sh` (§7.8):

**Check 17: MOC schema validation.** For every `.md` file with `type: moc-orientation` or `type: moc-operational` in frontmatter: verify required fields exist (`scope`, `last_reviewed`, `review_basis`, `notes_at_review`). Verify `review_basis` is one of `delta-only`, `full`, `restructure`. Report missing or invalid fields as errors.

**Check 18: Topics resolution.** For every `.md` file with a `topics` field in frontmatter: verify each entry resolves to an existing MOC file. Resolution is two-step:

1. **Resolve:** For each entry `E` in `topics`, search `Domains/*/` for a file matching `E.md`. If zero matches → error ("unresolved topic: E"). If multiple matches → error ("ambiguous topic: E resolves to multiple files").
2. **Assert MOC type:** Read the resolved file's frontmatter `type` field. If `type` is not `moc-orientation` or `moc-operational` → error ("topic entry E resolves to [path] but its type is [type], not a MOC").

This avoids hardcoding a `moc-` prefix assumption into the resolver while mechanically enforcing that `topics` entries always point to MOCs — membership in the navigational layer is enforcement, not suggestion.

**Global uniqueness invariant:** MOC filenames MUST be unique across all `Domains/*/` directories. Two MOCs with the same filename in different domain directories would cause ambiguous resolution. The `moc-` prefix + `scope` field make collisions unlikely in practice, but vault-check enforces this: if any two files matching `Domains/*/moc-*.md` share the same filename, report as error regardless of whether any `topics` entry references them.

**Check 19: Topics requirement for kb-tagged notes.** For every `.md` file whose frontmatter `tags[]` array contains any entry starting with `kb/` AND whose frontmatter `type` is not `moc-orientation` or `moc-operational`: verify that a `topics` field exists and contains ≥1 entry. Missing or empty `topics` on a kb-tagged non-MOC note → error. MOC files are exempt: they carry `kb/` tags by design but are themselves the targets of `topics` references, not members (see §5.6.5). Detection scope: frontmatter `tags[]` only — inline `#kb/` hashtags in the note body do not trigger this check. This is the mechanical enforcement that ensures the navigational layer grows in lockstep with content.

**Check 20: *(Reserved — bridge-candidate scope moved to audit diagnostic. See §5.6.9.)***

**Check 21: MOC prose guardrail — synthesis density.** **Type-aware:** For every MOC file with `type: moc-orientation`: if the Core section contains >5 entries AND the Synthesis section is empty or contains <2 sentences of prose, report as warning. For `type: moc-operational` MOCs: this check does not fire, since operational MOCs replace Synthesis with Steps/Procedure and may legitimately have no synthesis prose.

#### 5.6.11 Delta Computation

The Deltas section is machine-derivable and always current — it is the anti-staleness mechanism. Even if synthesis prose lags, the Deltas section tells the truth about what changed.

**Delta source of truth:** The `updated` field in each note's frontmatter is the canonical timestamp for delta computation. Notes whose `updated` value is more recent than the MOC's `last_reviewed` are deltas. The `updated` field is set by the agent during governed sessions; it reflects the last meaningful edit, not filesystem mtime.

**Operator rule:** Only governed, semantic edits update `updated`; mechanical rewrites (formatting passes, frontmatter standardization, tag restructuring) preserve the existing value. This is the first line of defense against bulk-update delta inflation (§5.6.8) — if `updated` stays stable during non-semantic changes, delta counts don't spike.

**Computation (deterministic, no LLM):**

1. Read `last_reviewed` and `notes_at_review` from MOC frontmatter.
2. Scan the MOC's Core section for all `[[note-title]]` entries.
3. For each linked note, check its frontmatter `updated` timestamp against the MOC's `last_reviewed`.
4. Notes with `updated` > `last_reviewed` are deltas. Classify each delta deterministically:
   - If the note's `created` > MOC's `last_reviewed` → **New** (note didn't exist at last review)
   - Else if `updated` > `last_reviewed` → **Updated** (note existed but was modified)
5. Format the Deltas section (inside `<!-- DELTAS:START -->` / `<!-- DELTAS:END -->` anchors):

```markdown
## Deltas
*Since last review (2026-02-10, full):*
- **New:** [[migration-phased-approach-v2]] — revised phased migration protocol based on Acme experience
- **New:** [[cutover-dns-sec-considerations]] — DNSSEC complications during cutover discovered at Beta Corp
- **Updated:** [[zone-transfer-best-practices]] — added TSIG authentication requirement
- **3 new notes, 1 updated since last full review**
```

**When to refresh deltas:** At session start if the MOC appears in the debt report, and before any synthesis pass. Delta refresh is cheap (file timestamp comparisons) and can run frequently.

#### 5.6.12 Initial MOC Set

Define the starter MOCs based on domains being populated. This is not exhaustive — new MOCs are created on demand when a topic area accumulates enough notes to justify one (heuristic: 5+ notes on a coherent topic).

**MOC Roster:**

Built MOCs (on disk):

| MOC | Type | Domain | Scope |
|---|---|---|---|
| `moc-crumb-architecture` | orientation | Learning | Crumb system design, architectural decisions, design rationale |
| `moc-crumb-operations` | operational | Learning | Crumb session workflows, vault maintenance, troubleshooting procedures |
| `moc-philosophy` | orientation | Learning | Ethics, metaphysics, epistemology, philosophical traditions |
| `moc-history` | orientation | Learning | Historical events, figures, eras, historiography |
| `moc-writing` | orientation | Learning | Craft of writing, style, editing, rhetoric |
| `moc-business` | orientation | Learning | Strategy, market dynamics, business models, positioning |
| `moc-biography` | orientation | Learning | Biographical profiles, life stories, historical figures |
| `moc-fiction` | orientation | Learning | Novels, short stories, literary fiction, narrative analysis |
| `moc-gardening` | orientation | Learning | Plants, landscaping, soil, seasonal planning |
| `moc-poetry` | orientation | Learning | Poems, poetic form, literary analysis |
| `moc-politics` | orientation | Learning | Political theory, governance, policy, civic systems |
| `moc-psychology` | orientation | Learning | Behavioral science, cognitive science, mental models |
| `moc-religion` | orientation | Learning | Faith, theology, spiritual practice, religious history |
| `moc-lifestyle` | orientation | Learning | Home management, domestic arts, personal systems |
| `moc-signals` | orientation | Learning | Feed-pipeline signal-notes — tech trends, tools, research signals |

Planned starters (not yet created):

| MOC | Type | Domain | Scope |
|---|---|---|---|
| `moc-dns-architecture` | orientation | Career | DNS architecture patterns, zone design, record management |
| `moc-dns-migration-patterns` | orientation | Career | Migration approaches, cutover procedures, lessons learned |
| `moc-dhcp-ipam-patterns` | orientation | Career | DHCP scoping, IPAM design, address management |
| `moc-dns-security` | orientation | Career | RPZ, DNS-based security, threat models |
| `moc-customer-engagement-patterns` | orientation | Career | Engagement workflows, relationship patterns, account management |
| `moc-training-delivery` | operational | Career | Training delivery checklists, curriculum design, presentation patterns |
| `moc-agent-architecture-research` | orientation | Learning | Agent-native software patterns, knowledge graph design, MOC theory |

Additional MOCs for personal domains (creative, spiritual, health, etc.) are created on demand as content enters those areas.

#### 5.6.13 MOC Health as System Health Metric

MOC health is the primary diagnostic for whether Crumb is compounding or just accumulating.

**Healthy system signals:**

- Debt scores stay below threshold across active MOCs
- MOCs meet the skeleton contract (deltas present, synthesis current, tensions tracked)
- New notes consistently get `topics` placement (vault-check passes)
- Bridge notes flagged in audit are reviewed and scoped within 2 weeks

**Unhealthy system signals:**

- Debt scores rising across multiple MOCs (synthesis falling behind)
- MOCs degenerating into link farms (synthesis density warning firing)
- Orphan notes appearing (kb-tagged notes without topics — vault-check errors)
- Bridge notes accumulating without scope (audit diagnostic warnings growing without resolution)

The audit skill (§3.1.4) includes MOC health in its weekly review:

- Report MOC debt scores
- Flag MOCs that have exceeded the debt threshold for >2 weeks without synthesis
- Report synthesis density warnings
- Report bridge-candidate scope warnings (3+ topics without Scope/Boundary section)
- Report topics resolution errors from vault-check

---

## 6. CLAUDE.md Design

CLAUDE.md must stay lean. Target: **< 200 lines**. Use progressive disclosure — point to detailed docs rather than inlining everything.

**Structure:**

```markdown
# Crumb — Personal Multi-Agent OS

## Project Overview
[2-3 sentences: what this system is, what vault it uses]

## Domains
software · career · learning · health · financial · relationships · creative · spiritual

## Workflow Routing
- Software projects: SPECIFY → PLAN → TASK → IMPLEMENT (full workflow)
- Knowledge work: SPECIFY → PLAN → ACT
- Personal domains: CLARIFY → ACT
- Non-project interactions: log to _system/logs/session-log.md with compound evaluation at session end
- Workflow entry threshold: ≥3 vault files OR downstream dependencies → formal workflow
- If threshold crossed mid-conversation, prompt user for project creation (§4.1.5)
- User can request project creation at any time without waiting for threshold
- Within-project prompt triage — calibrate response depth to the request:
  - FULL: new phase, new task, scope change → full skill/overlay/context loading
  - ITERATION: refining current work → load only what the change needs
  - MINIMAL: quick fix, lookup, clarification → just do it, no skill invocation
- See _system/docs/routing-heuristics.md for detailed routing rules (or §1.2 and §4.1 of spec until standalone doc is created)

## Risk-Tiered Approval
- Low risk: auto-approve (reading, drafting, testing, logging)
- Medium risk: proceed + flag (new files, routine changes)
- High risk: stop and ask (architecture, schemas, external comms, production)

## Context Rules
- Always read *-summary.md before full docs
- Target ≤5 source docs per skill invocation (standard); 6-8 with justification (extended); 10 design ceiling (see §5.4)
- Write a context inventory to run-log after loading context, before beginning core work (see §5.4)
- Scope all vault queries by project/domain + topic
- Never request unbounded vault searches
- Write frontmatter on every new document (see _system/docs/file-conventions.md)
- Use Context Checkpoint Protocol between workflow phases (see _system/docs/context-checkpoint-protocol.md)
- Context pressure degrades quality before hitting hard limits — see degradation guide in Context Checkpoint Protocol for operational adjustments at each capacity band
- _system/docs/personal-context.md and overlays are instructional context — they don't count against source doc budget tiers

## File Access
- Use Obsidian CLI for indexed queries (search, tags, backlinks, properties)
  when Obsidian is running — see Obsidian CLI skill (§3.1.5) for safe patterns
- Use native file tools (Read, Write, Edit, Grep, Glob) for direct read/write
  and as fallback when Obsidian is not running
- Check CLI availability at session start: `obsidian vault`
- Knowledge base queries: `obsidian tag name=kb/<topic>` and
  `obsidian backlinks path=Domains/<domain>/<domain>-overview.md`

## Subagent Configuration
- Default model: same as main session
- Override globally: set preferred_subagent_model here
- Override per-subagent: set model field in agent YAML frontmatter
- Only override when token cost analysis justifies it

## Plan Mode
- Use Plan Mode (Shift+Tab twice) during SPECIFY and PLAN validation phases
  for mechanical read-only enforcement — Claude cannot write files until approved
- Exit Plan Mode before phases that require file writes (TASK, IMPLEMENT)
- Consider Opus Plan Mode (Opus for planning, Sonnet for execution) when
  token cost data justifies split-model — see §7.7 for adoption criteria

## Behavioral Boundaries
[Always / Ask First / Never rules — see §4.7 of this spec]

## Project Archival
- Archive: user-initiated only. Precondition: clean working tree. Confirm → final
  run-log + compound → progress-log → update project-state (phase: archived,
  phase_before_archive: [previous phase]) → move to Archived/Projects/ → update
  companion note paths → vault-check → git commit
- Reactivate: user-initiated only. Move back → update companion note paths → update
  project-state (restore phase from phase_before_archive) → run-log entry →
  progress-log → vault-check → git commit
- Claude never archives or reactivates autonomously — only suggests and executes
  on explicit user approval
- Project docs do NOT carry a status field — directory location is authoritative
- See spec §4.6 for full procedure

## Compound Engineering
Compound reflection runs at every phase transition as part of the Context Checkpoint
Protocol (§4.1.4) — this is structurally enforced, not discretionary. Evaluate the
completing phase against trigger criteria: non-obvious decisions, rework/failure,
reusable artifacts, or system gaps. If criteria met, run full compound procedure.
If not, record explicit skip note. Either way, the run-log gets an auditable entry.
For non-project sessions: evaluate compound criteria at session end and record in
_system/logs/session-log.md (§2.3.4). Mid-phase compound steps remain discretionary for
individual tasks that surface notable insights.
Route insights to the right destination: conventions → update existing docs,
patterns → _system/docs/solutions/, primitive gaps → Primitive Proposal Flow (§4.4).
See _system/docs/compound-protocol.md for full procedure (or §4.4 of spec until standalone doc is created).

## Skills & Agents
Skills in .claude/skills/ are loaded automatically when relevant.
Subagents in .claude/agents/ are spawned for heavy isolated work.
Overlays in _system/docs/overlays/ are loaded when domain expertise is needed.
New primitives: user can request creation at any time; compound step proposes
via Primitive Proposal Flow (§4.4). All creation follows §3.5 protocol —
Claude proposes definition, user approves before files are written.

## Overlay Routing
Overlay index loaded at session start: _system/docs/overlays/overlay-index.md
Skills with overlay check steps (systems-analyst, action-architect) match tasks against
the index's activation signals and load relevant overlays automatically.
User can also request any overlay explicitly.
Overlays add lens questions to the active skill — they don't replace it.
Overlays don't count against the source document budget tiers.

## Subagent Validation
When subagent returns, review the summary it provides. Apply provenance check:
verify key constraints and decisions match the full output, check that no interpretive
claims were introduced (see §4.8.2). If quality is unclear, read full doc from vault
and apply lightweight convergence check (2-3 dimensions from _system/docs/convergence-rubrics.md)
before proceeding to approval gate.

## Convergence
- Code: binary grounding only (tests, types, linting)
- Non-code: use pre-built rubrics from _system/docs/convergence-rubrics.md
- Aggressive stop conditions to prevent token waste
- See _system/docs/convergence-protocol.md for details (or §4.2 of spec until standalone doc is created)

## Hallucination Detection
Tiered checks — not everything fires on every operation:
- Always-on: confidence tagging, context relevance justification, interpretation flagging,
  falsifiability checks (compound step only)
- Risk-proportional: provenance check when consuming summaries not generated in current session
- Audit-time: deep provenance analysis, calibration log review, summary spot-checks
- See _system/docs/protocols/hallucination-detection-protocol.md (or §4.8 of spec) for full procedure

## Session Startup
On every session start:
1. Run `git pull` to pick up external changes before any validation
2. Run `_system/scripts/vault-check.sh` (§7.8) — surface any errors to user before proceeding
3. Check CLI availability: `obsidian vault` — if available, use CLI for indexed queries; if not, fall back to file tools for the session
4. Check monthly rotation for both `_system/logs/session-log.md` and the active project's `run-log.md` if applicable (see §2.3.1, §2.3.4); rotate if needed
5. Load overlay index (_system/docs/overlays/overlay-index.md) for skill routing
6. Run audit skill's staleness scan (compare summary `source_updated` vs parent `updated` fields, check last audit date)
7. If 7+ days since last full audit, suggest running one
8. If 3+ stale summaries found, recommend full audit regardless of cadence
9. Check for orphan binaries in attachment directories (files without companion notes); flag to user if found
10. Run Knowledge Brief (`_system/scripts/knowledge-retrieve.sh --trigger session-start`) — surface 5 cross-domain vault entries with compound insight detection. Display brief in startup summary.
11. Report active project(s) and current phase from the most recent run-log entry
This is lightweight (git pull + script + CLI check + frontmatter reads + date checks + small index file + QMD query + run-log read) — not a full audit.

## Session Management
Context management is autonomous — Claude proactively manages /context, /compact,
and /clear based on the Context Checkpoint Protocol (_system/docs/context-checkpoint-protocol.md).
No manual intervention needed for capacity management.
- Project sessions: log outcomes to run-log.md before ending
- Non-project sessions: log to _system/logs/session-log.md with compound evaluation before ending (§2.3.4)
- Session end sequence (autonomous — do not wait for user prompts):
  1. Log with compound evaluation (project → run-log.md, non-project → _system/logs/session-log.md)
  2. If session went poorly (repeated errors, dead ends, rework, user frustration): add failure-log entry (§4.8) — autonomous, no user prompt
  3. Code review sweep — verify review entries for completed code tasks
  4. Conditional commit — check `git diff --stat HEAD`:
     - Log-only delta → lightweight `chore: session-end log` commit
     - Substantial delta (non-log files) → flag to user, descriptive commit
     - No changes → skip commit
  5. git push (skip if no commit in step 4)
- To resume a project, start a fresh session and tell Claude to resume — vault-based
  state reconstruction (§7.1) reads run-log.md and rebuilds context from vault files.
  This is preferred over `claude --resume` (conversation replay), which is fragile
  under context pressure and unnecessary when all state lives in the vault.

## External Tools
- MarkItDown: CLI tool for binary-to-markdown conversion. Used by inbox-processor
  skill and inline attachment protocol. CLI invocation: `markitdown <filepath>`.
  See §7.9 of spec for details.
```

**Everything else** (detailed skill procedures, convergence protocol, compound step details, file conventions, routing heuristics, context checkpoint protocol) lives in referenced files that Claude loads on-demand.

---

## 7. Operational Concerns

### 7.1 Session Management

- **Session startup:** Every session begins with `git pull` to pick up external changes, then `_system/scripts/vault-check.sh` (§7.8) for mechanical vault validation, followed by a CLI availability check (`obsidian vault`) and the audit skill's lightweight staleness scan (§3.1.4): compare summary `source_updated` fields against parent `updated` timestamps, check last full audit date, and notify user if a full audit is recommended. If CLI is available, staleness scan can use `obsidian properties` for faster frontmatter reads. The Knowledge Brief (`_system/scripts/knowledge-retrieve.sh --trigger session-start`) surfaces 5 cross-domain vault entries via QMD semantic retrieval with decay-based relevance scoring and compound insight detection. Finally, report active project(s) and current phase from the most recent run-log entry. This adds minimal overhead — the script validates structure, the scan reads timestamps, the brief runs a fast QMD query, not a full document read.
- **Context management:** Handled autonomously by Claude per the Context Checkpoint Protocol (§4.1.4). Claude proactively checks capacity, compacts, and clears as needed — no manual intervention required.
- **Phase transitions:** Context Checkpoint Protocol runs automatically between workflow phases (SPECIFY→PLAN, PLAN→TASK, TASK→IMPLEMENT).
- **Session boundaries:** One major task per session when possible. To resume a project, start a fresh session and use the vault-based resume procedure below.
- **State reconstruction:** Because all important state lives in the vault (not chat history), any new session can reconstruct context by reading the relevant project files. This makes `claude --resume` (conversation replay) unnecessary — vault reconstruction is more reliable, especially under context pressure.

#### Context Management Strategy

Claude manages context autonomously. These behaviors are system-level — they happen automatically without user intervention.

**Proactive (prevent context issues):**
1. Check `/context` at natural breakpoints: phase transitions (which include compound reflection per §4.1.4), before spawning subagents, before invoking context-heavy skills, before ending session
2. Run `/compact` when >70% to stay below saturation
3. Use `/clear` + vault reconstruction when >85%

**Reactive (recover from context issues):**
1. If skill fails to load files → `/compact` and retry
2. If output quality degrades → check `/context`, compact if needed
3. If context exhausted → `/clear`, read relevant vault files, reconstruct state

**Session end (automatic):**
1. Run `/compact` if context >60% (clean state for next session)
2. Log session outcomes to `run-log.md` or `_system/logs/session-log.md`
3. Run compound evaluation and record result (§4.4)
4. If session went poorly: write diagnosis to `_system/docs/failure-log.md` (§4.8) — autonomous assessment

#### Source of Truth Authority

Three files carry project state, each authoritative for a different question:

| Question | Authoritative Source | Why |
|---|---|---|
| **Where am I?** (phase, active task, workflow) | `project-state.yaml` | Machine-readable, updated at every transition, fast to parse |
| **What happened?** (decisions, actions, context) | `run-log.md` | Prose narrative with full context, validation results, compound reflections |
| **What remains?** (task backlog, dependencies, acceptance criteria) | `tasks.md` | Structured task list with state machine and dependency graph |

**If sources disagree during resume:** trust `project-state.yaml` for phase/task state (it's updated mechanically at transitions), trust `run-log.md` for what actually occurred (it has the narrative), trust `tasks.md` for remaining work. If the disagreement can't be reconciled, flag it to the user before proceeding — don't silently pick one.

#### Resume Procedure

When resuming work on a project (user says "resume [project]" or "continue [project]"), reconstruct state from the vault — not from conversation history:

1. **Read project-state.yaml for quick state orientation**
    - Current phase, last gate passed, active task (if any), workflow type, and `next_action`
    - `next_action` tells you exactly where to pick up — this is the single most valuable resume field
    - This is a machine-readable snapshot — faster than parsing run-log prose
    - **Check `last_committed` vs `updated`:** If `last_committed` is significantly older than `updated` (or missing), uncommitted work may exist on disk. Run `git status` to check. If uncommitted files are found, run Session Interruption Recovery (§7.4) before proceeding with normal resume.
    - If `project-state.yaml` is missing (pre-v1.5.3 project or interrupted creation), fall back to run-log-based reconstruction below

2. **Locate last session in run-log.md**
    - Find most recent session entry in current `run-log.md`
    - If `run-log.md` was just rotated (no entries yet), check the previous month's archived log (`run-log-YYYY-MM.md`) for the last session
    - Read "Current State" section to understand where work stopped

3. **Verify context reconstruction**
    - Check which files were modified in last session
    - Load relevant summaries (don't load full docs yet — start lean)
    - Verify task state in tasks.md matches run-log and project-state.yaml
    - Load full docs only when needed for active work

4. **Confirm with user**
    - "Resuming from [date/time]: [brief context from run-log]"
    - "Last action: [last action from run-log]"
    - "Next steps: [next steps from run-log]"
    - "Should I proceed with [next step from run-log]?"

5. **Load working context**
    - Based on current task, load necessary design docs
    - Load active task from tasks.md
    - Use `/context` to monitor capacity throughout
    - Continue from where we left off

**Example resume flow:**
```text
User: resume customer-intelligence

Claude:
Resuming from 2026-02-14 18:09: ACT phase — comms strategy for remaining accounts
Last action: Completed comms strategy for Acme Corp, generated value card
Next steps: Comms strategy for remaining accounts, value card template

Should I proceed with the next account's comms strategy?
```

**Why vault-based resume over `claude --resume`:** `claude --resume` replays the previous conversation, which is fragile under context pressure and redundant when all meaningful state already lives in vault files. Vault reconstruction starts lean (summaries only), scales to what the current task needs, and works identically whether the previous session ended cleanly, crashed, or happened days ago. `claude --resume` remains available as a Claude Code feature but is not part of the Crumb workflow.

### 7.2 Git Integration (Software Projects)

- Conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`)
- One logical change per commit
- Branch per feature/task
- Claude Code creates commits as work progresses; human reviews before merge
- The vault itself can be git-tracked for version history on specs and designs

### 7.3 Hooks (Enforcement & Automation)

Add hooks incrementally as you identify friction:

| Hook Type | Trigger | Action |
|---|---|---|
| Post-write | Any `.ts`/`.js`/`.py` file write | Run linter |
| Post-write | Any test file change | Run affected tests |
| Pre-commit | Git commit | Verify tests pass |
| Pre-commit | Git commit (vault repo) | Run `_system/scripts/vault-check.sh` (§7.8) — block commit on errors |
| Post-task | Task marked complete | Prompt discretionary compound step |

Configure in `.claude/settings.json`. Start with 0-1 hooks; add based on actual pain points.

**Note:** Phase-level compound enforcement is handled structurally by the Context Checkpoint Protocol (§4.1.4) from Phase 1a — it does not depend on hooks. The post-task hook above is a Phase 2 supplement for mid-phase task-level compound prompting.

### 7.4 Failure Recovery

| Failure Mode | Recovery |
|---|---|
| Context window exhausted | `/compact` or `/clear` + reconstruct from vault files |
| Obsidian CLI unavailable | Fall back to native file tools (Read, Grep, Glob) for the session; note fallback in run-log |
| Subagent fails | Main session catches error, retries once, escalates to human if still failing |
| Session crashes mid-work | Run Session Interruption Recovery (below), then resume or close out |
| Spec diverges from reality | Return to SPECIFY phase, update spec, regenerate downstream |

#### Session Interruption Recovery

When a session is interrupted (connectivity loss, crash, forced quit) and work was written to disk but not committed or logged:

1. **Check git status** for uncommitted files — untracked and modified files reveal what was written but not committed.
2. **Read project-state.yaml** for last known state — `phase`, `next_action`, and `updated` timestamp show where the system thinks it is.
3. **Compare filesystem contents against run-log entries** — read the last run-log session block and compare against what's actually on disk. Files on disk but not mentioned in the run-log are the gap to reconcile. If `last_committed` is present and older than `updated`, that's an additional signal of uncommitted work.
4. **Update run-log and project-state** to reflect reality on disk — complete the interrupted session block with Actions Taken, Current State, Files Modified. Update project-state.yaml to reflect actual progress (phase, next_action, updated).
5. **Run vault-check** to verify structural integrity — all checks should pass after reconciliation. Fix any warnings or errors before proceeding.
6. **Commit the reconciled state** — `git add` all relevant files and commit with a message noting the crash recovery.
7. **Continue or close out** — if the project has remaining work, proceed from the reconciled state. If the interrupted session completed all planned work, update project-state accordingly.

**Authority rules during reconciliation** (per §7.1): trust the filesystem for what exists, trust `project-state.yaml` for phase/task state, trust `run-log.md` for what was logged. When they disagree, the filesystem is ground truth for *what was produced*, and the logs need updating to match it — not the other way around.

### 7.5 Vault Maintenance

Vault maintenance uses a hybrid model: a lightweight staleness scan runs automatically at session start, while full audits run on user request or when the staleness scan recommends one (see §3.1.4 for trigger logic).

**Session-start (automatic, every session):**
- Scan summary `source_updated` vs parent `updated` fields; regenerate stale summaries
- Check last full audit date; notify user if overdue (7+ days)
- Recommend full audit if significant staleness detected (3+ stale summaries)

**Full audit — weekly scope (user-initiated or recommended):**
- Spot-check summaries for drift from parent docs; regenerate if drifted
- Merge redundant notes in `_system/docs/solutions/`
- Prune completed tasks from `tasks.md`
- Review `_system/logs/session-log.md` for patterns worth promoting to solution docs or interactions worth escalating to projects
- Review `tentative-pattern` tags; validate or discard based on new evidence
- Review `_system/docs/failure-log.md` for recurring failure modes
- Consolidation pass on `_system/docs/solutions/` if 50+ active documents

**Full audit — monthly scope (in addition to weekly, when 30+ days since last monthly):**
- Consolidate `_system/docs/solutions/` if weekly consolidations were missed
- Check skill activation patterns; flag unused skills
- Review failure log trends across skills/subagents
- Check convergence rubrics against calibration data; suggest updates
- Check CLAUDE.md for routing or boundary drift

**Human Review (flagged by audit skill for your judgment):**

*Weekly:*
- Approve or reject suggested pattern promotions/discards

*Monthly:*
- Approve archiving completed projects
- Review skill effectiveness recommendations
- Approve convergence rubric updates
- Approve CLAUDE.md changes

### 7.6 Shared File Write Assumptions

Several vault files are written to by multiple components across the system: `run-log.md` (main session, context inventories, phase transitions, compound step), `tasks.md` (action architect creates, orchestrator updates state), `progress-log.md` (any phase transition), and `subagent-decisions.md` (subagents write, main session adds validation notes).

The current architecture assumes **single-writer access** to these files — one agent or session writing at a time, in serial order. This holds under the current design because subagents execute sequentially and there is one human operator.

This assumption breaks under parallel execution (Agent Teams), concurrent multi-project sessions, or external edits (manual Obsidian changes during an active Claude Code session). Known risks include write conflicts, stale reads, and inconsistent state across files that should agree (e.g., `tasks.md` state vs. `run-log.md` entries).

**Current mitigation:** Serial execution makes this a non-issue for normal operation. For manual Obsidian edits during a session, the resume procedure (§7.1) reconstructs state from vault files, which self-heals most inconsistencies on the next session.

**If parallel execution is adopted:** This constraint will need to be addressed — likely through per-agent log partitioning, append-only write models with merge steps, or file-level locking. See §9 (Deferred Items) for the full deferral rationale.

### 7.7 Plan Mode Strategy

Claude Code's Plan Mode (`Shift+Tab` twice, or `/plan`) restricts Claude to read-only operations — it can read files, search, grep, and analyze, but cannot write, edit, or execute commands. Claude produces a plan as structured markdown, presents it for approval, and only begins execution after the human approves.

This provides **mechanical enforcement** of the "think before acting" discipline that Crumb's workflow phases prescribe behaviorally. Where CLAUDE.md and skill procedures *instruct* Claude to analyze before writing, Plan Mode *prevents* it from doing otherwise.

#### When to Use Plan Mode

| Phase | Plan Mode? | Rationale |
|---|---|---|
| **SPECIFY** | Yes | Almost entirely read-and-think. Claude reads vault files, searches for patterns, asks questions, and produces a spec. No files should be written until the spec is approved. |
| **PLAN** (validation) | Yes | When reviewing subagent output, the main session should be reading and evaluating, not modifying. Plan mode prevents premature edits before the human gate fires. |
| **TASK** | Optional | Action Architect reads specs and designs to produce tasks. Mostly analytical, but needs to write `action-plan.md` and `tasks.md`. Use plan mode for the analysis, exit for the writes. |
| **IMPLEMENT** | No | Requires active file writing, code execution, and test running. Plan mode would block the core work. |
| **Compound step** | No | Needs to write to `_system/docs/solutions/`, update existing files, and log to `run-log.md`. |
| **CLARIFY** (personal) | Optional | Conversational and lightweight — plan mode adds little value unless the clarification requires significant codebase research. |

#### Cost Optimization with Opus Plan Mode

Claude Code supports a split-model configuration: Opus for planning and reasoning, Sonnet for execution. This aligns naturally with Crumb's architecture:

- **High-judgment work** (SPECIFY, PLAN validation, compound step analysis): benefits from Opus's stronger reasoning
- **Execution work** (IMPLEMENT, file writes, test runs): Sonnet is sufficient and significantly cheaper

To enable: select "Use Opus in plan mode, Sonnet otherwise" via the `/model` command (option 4). This gives you Opus-quality analysis during plan mode phases and Sonnet-cost execution afterward.

**When to adopt:** This is a cost optimization. Start with a single model for simplicity during Phase 1. If token cost data from early sessions shows the planning phases consuming a disproportionate share of the budget, switch to split-model. Log the cost comparison in `_system/docs/estimation-calibration.md` to validate the savings empirically — consistent with the existing subagent model selection strategy (§3.2.1).

### 7.8 Vault Integrity Script (External Mechanical Enforcement)

A deterministic bash script (`_system/scripts/vault-check.sh`) that validates vault health outside Claude's context window. This is the system's only enforcement mechanism that cannot hallucinate, forget, or skip steps.

**Twenty-five mechanical validations:**

1. **Frontmatter schema validation** — iterate all `.md` files in `Projects/`, `Archived/Projects/`, `Domains/`, `_system/docs/`. Verify YAML parses and required fields exist. Path-conditional required fields: for files under `Projects/` or `Archived/Projects/`, require `project`, `domain`, `type`, `created`, `updated` — do NOT require `status` (if `status` is present, ignore it — no error, no warning). For files under `Domains/`, `_system/docs/`, `_attachments/`, or vault root, require `project` (nullable), `domain`, `type`, `status`, `created`, `updated`. Report files that fail.
2. **Summary freshness check** — for every `*-summary.md`, compare its `source_updated` field against the parent's `updated` field. Report mismatches. This duplicates what the audit skill does (§3.1.4) but externally and exhaustively rather than via LLM spot-checks.
3. **Summary schema completeness** — for every `*-summary.md`, verify that the `source_updated` field exists in frontmatter. A summary without `source_updated` cannot participate in staleness detection and is structurally broken regardless of content quality. Report missing fields as errors.
4. **Run-log structural integrity** — verify every `## Session` block in `run-log.md` contains the required fields (`**Actions Taken:**`, `**Current State:**`, `**Files Modified:**`). Flag incomplete entries that indicate interrupted writes.
5. **Compound step continuity** — verify every `### Phase Transition` block in `run-log.md` contains a `Compound:` field with either routed insights or an explicit skip note (e.g., "No compoundable insights from PLAN phase"). Flag transitions missing both. This ensures compound reflection cannot be silently skipped at phase boundaries — the same pattern as the other validations: a mechanical check outside Claude's context window enforcing a behavior that would otherwise depend on discipline.
6. **Session-log compound completeness** — for every entry in `_system/logs/session-log.md` that has a non-empty `**Summary:**` field, verify a `**Compound:**` field exists. Entries without a summary (trivial interactions) are skipped. This closes the enforcement gap for non-project sessions: compound evaluation at session end is behavioral, but this check catches entries where the evaluation was skipped entirely. It cannot judge evaluation quality — only that the evaluation happened.
7. **Project scaffold completeness** — for every directory in `Projects/`, verify that `project-state.yaml`, `progress/run-log.md`, and `progress/progress-log.md` exist. A project directory without run-log or progress-log files indicates an interrupted Project Creation Protocol (§4.1.5) or manual directory creation that bypassed the protocol. Missing run-log/progress-log files are errors; missing `project-state.yaml` is a warning (pre-v1.5.3 projects won't have it).
8. **Task completion evidence** — for every task in `tasks.md` with `state: complete`, verify that at least one `## Session` block in the project's `run-log.md` references that task's ID (e.g., `T-001`). A completed task with no run-log trace indicates either a skipped log write or an unvalidated state change. Report mismatches as warnings.
9. **Knowledge base tag validation** — scan all `.md` files in `Projects/` and `Domains/` for `#kb/` tags in frontmatter. Enforce two rules: (a) the Level 2 tag (first segment after `kb/`) must be in the canonical list defined in §5.5, and (b) tag depth cannot exceed three levels (`#kb/topic/subtopic` maximum). Non-canonical Level 2 tags and depth violations are errors that block the commit. Level 3 subtopics are open — any value is accepted as long as the Level 2 parent is canonical. Scope excludes `_system/docs/` because system infrastructure files should not carry `#kb/` tags.
10. **Project-state active task consistency** — if `project-state.yaml` specifies a non-null `active_task`, verify that (a) `tasks.md` exists, (b) the referenced task ID exists in `tasks.md`, and (c) the referenced task is not in `state: complete`. A stale or dangling active_task indicates a missed update after task completion or an interrupted session. Report violations as errors — this is a true invariant break, not a timing issue.
11. **Project-state last_committed field** — verify every `project-state.yaml` has a `last_committed` field. This field enables crash detection on resume: if `last_committed` is significantly older than `updated`, uncommitted work may exist on disk (see §7.4 Session Interruption Recovery). Report missing fields as warnings (backward compatible with pre-v1.5.4 projects).
12. **Attachment orphan check (binary → companion)** — for every file with a supported binary extension (`pdf`, `docx`, `pptx`, `xlsx`, `png`, `jpg`, `jpeg`, `gif`, `webp`, `svg`) under `_attachments/` or `Projects/*/attachments/` (including `Archived/Projects/*/attachments/`), assert there exists exactly one markdown file in the same directory whose frontmatter contains `type: attachment-companion` and whose `attachment.source_file` value resolves to that binary. Missing companion → error. Multiple companions pointing to the same binary → error. Files in `_inbox/` are excluded (transient — awaiting processing).
13. **Companion orphan check (companion → binary)** — for every markdown file with `type: attachment-companion` in frontmatter, assert the file at `attachment.source_file` exists on disk. Missing binary → error. This catches companion notes that survived a binary deletion or a failed move operation.
14. **Binary location constraint** — scan the entire vault for files with supported binary extensions. Any binary file found outside `_attachments/`, `Projects/*/attachments/`, `Archived/Projects/*/attachments/`, or `_inbox/` → error. This prevents binaries from accumulating in untracked locations where they lack companion notes and escape audit.
15. **Companion description and extraction completeness** — for every `type: attachment-companion` note: (a) the `description` field MUST exist (even if it's a stub) — missing `description` on any type → error; (b) for text-extractable types (`pdf`, `docx`, `pptx`, `xlsx`): if neither the `summary` frontmatter field nor an `## Extracted Content` section in the body contains content, report as **warning** (not error) and verify the `needs-extraction` tag is present. A failed extraction is a quality signal, not a structural break — MarkItDown failures, scanned PDFs without OCR, and corrupted files are legitimate reasons for missing extraction. The `needs-extraction` tag (parallel to `needs-description` for images) ensures the audit skill flags these for follow-up. A stub description (e.g., "Description pending") is acceptable for vault-check — it validates presence, not quality.
16. **Archive location consistency** — scan all project directories in both `Projects/` and `Archived/Projects/`. Two rules: (a) if a project folder is under `Archived/Projects/`, its `project-state.yaml` `phase` field MUST be `archived`; if a project folder is under `Projects/`, its `phase` field MUST NOT be `archived`. Mismatch → error, with remediation guidance: prefer directory location as authoritative (move the folder to match, or update the phase to match the folder). (b) No project name may appear in both `Projects/` and `Archived/Projects/` simultaneously. Duplicate → error. This catches interrupted archive/reactivate operations that left partial state, and prevents the only split-brain the lifecycle permits.
17. **MOC schema validation** — for every `.md` file with `type: moc-orientation` or `type: moc-operational` in frontmatter: verify required fields exist (`scope`, `last_reviewed`, `review_basis`, `notes_at_review`). Verify `review_basis` is one of `delta-only`, `full`, `restructure`. Report missing or invalid fields as errors. Additionally, enforce global MOC filename uniqueness: if any two files matching `Domains/*/moc-*.md` share the same filename, report as error. See §5.6.10.
18. **Topics resolution** — for every `.md` file with a `topics` field in frontmatter: resolve each entry `E` to `Domains/*/E.md` (zero matches → error, multiple matches → error), then assert the resolved file's `type` is `moc-orientation` or `moc-operational` (non-MOC type → error). See §5.6.10.
19. **Topics requirement for kb-tagged notes** — for every `.md` file whose frontmatter `tags[]` contains any `kb/` entry AND whose `type` is not `moc-orientation` or `moc-operational`: verify `topics` exists and contains ≥1 entry. Missing or empty → error. MOC files are exempt (they are targets of `topics`, not members). Detection scope: frontmatter `tags[]` only. See §5.6.10.
20. **Source-Index Schema Validation** — for every `.md` file with `type: source-index` in frontmatter: verify required fields exist (`source_type`, `source_id`, `scope`, `schema_version`). Verify `scope` is one of `full`, `partial`, `chapter`, `section`. Report missing or invalid fields as errors. Source-index notes are the product of the NotebookLM pipeline (§5.7) and must conform to the knowledge-note schema to participate in MOC membership and staleness detection.
21. **MOC synthesis density** — type-aware: for `moc-orientation` files only, if Core contains >5 entries and Synthesis is empty or <2 sentences → warning. `moc-operational` files are exempt. See §5.6.10.
22. **DONE project design file warning** — for every project with `phase: DONE` in `project-state.yaml`, check each file in `design/`. If a design file's `created` date is strictly after the project-state's `updated` date, warn: "file created after project marked DONE." This catches scope creep into completed projects — new design work should create a new project with `related_projects` linking. Warning level (non-blocking) — legitimate maintenance artifacts are allowed with a run-log note.
23. **Code Review Gate** — for projects with a `repo_path` field in `project-state.yaml` (code projects): for each task in `tasks.md` with `state: done` that was completed on or after 2026-02-26 (determined by the latest `## YYYY-MM-DD` session date in `run-log.md` where the task ID appears), verify that `run-log.md` contains a code review entry referencing that task ID (matches `Code Review.*[task-id]` or an explicit skip notation). Tasks completed before the enforcement date, or tasks that never appear in the run-log, are grandfathered. Warning level (non-blocking, advisory) — surfaces gaps without blocking the commit. Enforcement date: 2026-02-26.
24. **Run-Log Size Check** — for every active `run-log*.md` file under `Projects/` (excluding `Archived/`), check if the file exceeds 1000 lines. Warning level (non-blocking) — surfaces run-logs that should be rotated. Threshold: `RUNLOG_SIZE_THRESHOLD=1000`.
25. **Signal-Note Schema Validation** — for every `.md` file with `type: signal-note` in frontmatter: (a) must be located in `Sources/signals/` (error otherwise); (b) must have `schema_version` field; (c) must have all required `source` subfields: `source_id`, `title`, `author`, `source_type`, `canonical_url`, `date_ingested`; (d) must have all `provenance` subfields: `inbox_canonical_id`, `triage_priority`, `triage_confidence`; (e) must have `topics` field with ≥1 entry; (f) must have at least one `#kb/` tag.

**`--pre-commit` mode:** The `--pre-commit` flag scopes all 25 checks to staged files only, reducing runtime from ~90s (full scan) to ~0.3s. The git pre-commit hook invokes `vault-check.sh --pre-commit`; weekly audits and explicit invocations use `--full` for exhaustive scanning.

**Integration points:**

- **Git pre-commit hook** (§7.3): every commit to the vault gets mechanically validated before it's persisted. Failed validation blocks the commit.
- **Session startup** (§7.1): run as step 0 before the staleness scan. If the script reports errors, Claude surfaces them to the user before proceeding.
- The audit skill's frontmatter spot-check (§3.1.4) becomes a supplement to this script, not the primary defense.

**Exit codes:** 0 = clean, 1 = warnings (non-blocking, e.g. optional fields missing), 2 = errors (blocking, e.g. required fields missing or malformed YAML).

**Future extension — Phase 1b structural checks:** The twenty-five validations above cover Phase 1a artifacts (frontmatter, summaries, run-log, session-log, project scaffolds, task evidence, project-state consistency), Phase 2 knowledge base tags, binary attachment integrity, archive location consistency, MOC structural invariants (checks 17-19, 21), source-index schema (check 20), repo path validation (check 22), code review enforcement (check 23), run-log hygiene (check 24), and signal-note schema (check 25). Phase 1b introduces reference docs with their own structural invariants (convergence rubrics must contain four core rubric sections, failure log must preserve the canonical taxonomy, context checkpoint protocol must preserve capacity thresholds and phase transition block fields, etc.). Adding heading-level and content-level validation for these files would extend the script's coverage to catch structural drift within Phase 1b docs — not just missing frontmatter. Build when audit data shows structural drift in Phase 1b docs is a real problem, not speculatively.

**Script–spec check number alignment:** The script numbers (vault-check.sh) are authoritative. Checks 12–15 (attachment orphan checks, binary location constraint, companion completeness) are defined in the spec and will be implemented in Phase 1b when binary attachments enter the vault. Check 16 (archive location consistency) is implemented. Checks 17-25 are implemented and numbered to match this spec.

---

### 7.9 External Tool Dependencies

Crumb's core architecture depends only on Claude Code and the Obsidian CLI. External tools are adopted incrementally when they provide clear capability that can't be achieved within the core stack.

#### MarkItDown (Microsoft)

**What it is:** A Python utility (MIT licensed, `pip install 'markitdown[all]'`) that converts multiple file formats to markdown. Supports PDF, DOCX, PPTX, XLSX, HTML, CSV, JSON, XML, images (EXIF metadata via `exiftool`, LLM-based captioning via optional OpenAI client), audio (EXIF + speech transcription), ZIP, EPUB, and YouTube URLs.

**Why it's here:** The inbox-processor skill needs a unified extraction engine for binary files. MarkItDown handles the full range of supported attachment types through a single interface — text extraction for documents, EXIF metadata for images. Without it, the inbox processor would need to assemble multiple single-purpose libraries (pdfminer, python-docx, mammoth, etc.) with no consistent output format.

**Integration path:** CLI via bash (`markitdown <filepath>`). Simpler than MCP server for Crumb's single-operator serial execution model, avoids unnecessary dependencies, and was validated in the 25c implementation session. MCP server remains an option if tool-call integration proves beneficial later.

**Known limitations (validated 2026-02-17 against v0.1.4):**

- **PDF:** Text extraction is accurate but tables lose structure — cells render as flat text, not markdown tables. Headings and bullet lists are preserved. Adequate for most narrative documents; evaluate Docling (IBM, MIT licensed) if PDF table quality friction surfaces through compound engineering.
- **DOCX:** Excellent — headings, bullet lists, and tables all convert to proper markdown.
- **PPTX:** Excellent — slide numbers as HTML comments, titles as `#` headings, body text intact.
- **XLSX:** Excellent — multi-sheet support, proper markdown tables with headers.
- **Images (PNG/JPG):** Returns EXIF metadata only (ImageSize, dates, GPS, etc.) via `exiftool`. No OCR capability exists in released versions through v0.1.4 — the `ImageConverter` never integrated EasyOCR despite early documentation suggesting it. LLM-based captioning is available via the Python API (requires an OpenAI-compatible client) but is not accessible through the CLI. Visual understanding of image content requires the vision enrichment path (§9).
- The inbox processor MUST NOT fabricate image descriptions from filenames or metadata alone and present them as content descriptions. If the system cannot determine what an image shows, it says so — `needs-description` tag, not a hallucinated caption.

**Backend flexibility:** The inbox-processor skill MAY swap the extraction backend for specific file types (e.g., Docling for complex PDFs) without spec changes. The attachment-companion schema is tool-agnostic — it cares about the output (description, summary, metadata), not the tool that produced it. This is an implementation detail of the skill, not a spec-level architectural choice.

**Installation (validated):** Requires `pipx` (via Homebrew) and `exiftool` (via Homebrew). Install: `pipx install 'markitdown[all]'` and `brew install exiftool`. Add to `_system/scripts/setup-crumb.sh` as a Phase 2 dependency. The `[all]` extra pulls document conversion libraries (pdfminer, mammoth, python-pptx, openpyxl) plus audio/video support. EasyOCR is not included and is not used by any converter in the current version.

---

### 7.10 Git and Binary Files

The vault is git-tracked for version history. Binary files in git repos accumulate in `.git/` history permanently — even deleted binaries persist in the object store. This creates repo bloat over time as attachments accumulate.

**Recommended approach: `.gitignore` attachment directories.**

Add to the vault's `.gitignore`:

```
_attachments/
Projects/*/attachments/
```

**What this means:**

- **Companion notes ARE tracked by git** — they live alongside binaries but are markdown files, not matched by the ignore pattern. Wait — this doesn't work. If the companion notes are colocated in the same ignored directory, git ignores them too.

**Revised approach: track companion notes, ignore binaries by extension.**

```gitignore
# Binary attachments — tracked via companion notes, not git history
*.pdf
*.docx
*.pptx
*.xlsx
*.png
*.jpg
*.jpeg
*.gif
*.webp
*.svg
```

This ignores binary files everywhere in the vault (including `_inbox/`) while keeping all markdown files (including companion notes) tracked. The companion note IS the version-controlled record of the binary — it carries the metadata, description, and references. The binary itself is a blob that doesn't benefit from diff-based version history.

**Tradeoffs:**

- ✓ Keeps the git repo lean — only markdown is tracked
- ✓ Companion notes provide full provenance trail without needing the binary in git
- ✗ Binaries are not version-controlled — if a binary is deleted or corrupted, git can't restore it
- ✗ `git clone` on a new machine won't include binaries — need a separate sync mechanism (e.g., rsync, Syncthing, iCloud, or Obsidian Sync)

**Binary durability requirement:** Because git does not track binaries under this scheme, the vault owner MUST configure a separate file-level sync or backup mechanism (e.g., Obsidian Sync, Syncthing, iCloud Drive, Time Machine, or equivalent) to ensure binary durability. Git is responsible for markdown version history; it is NOT responsible for binary survival. This is a day-one operational requirement when binaries start entering the vault — not something to figure out after your first data loss.

**If git-based binary recovery matters:** Use Git LFS (`git lfs track "*.pdf" "*.png" ...`) instead of `.gitignore`. LFS stores binaries in a separate backend with pointer files in the repo. This preserves `git clone` completeness but adds a dependency on LFS storage (local or remote). To ease future migration, add a `.gitattributes` stub from day one:

```gitattributes
# Stub for future Git LFS migration — uncomment when switching from .gitignore to LFS
# *.pdf filter=lfs diff=lfs merge=lfs -text
# *.docx filter=lfs diff=lfs merge=lfs -text
# *.pptx filter=lfs diff=lfs merge=lfs -text
# *.xlsx filter=lfs diff=lfs merge=lfs -text
# *.png filter=lfs diff=lfs merge=lfs -text
# *.jpg filter=lfs diff=lfs merge=lfs -text
# *.jpeg filter=lfs diff=lfs merge=lfs -text
# *.gif filter=lfs diff=lfs merge=lfs -text
# *.webp filter=lfs diff=lfs merge=lfs -text
# *.svg filter=lfs diff=lfs merge=lfs -text
```

**Note:** The `.gitignore`-by-extension approach works in concert with the binary location constraint (§7.8 check 14) — even if a binary somehow ends up outside an attachment directory, vault-check will catch it as a location violation regardless of git tracking status.

**Decision guidance:** Start with `.gitignore` (simplest). If you find yourself needing binary version history or cross-machine clone completeness, switch to Git LFS. The companion note schema is identical in both cases — this is a git configuration decision, not an architectural one.

---

## 8. Implementation Plan

### Phase 1a: Minimum Viable System (Day 1)

Get to a real project as fast as possible. Build only what's structurally required for the workflow to function:

1. **Create Obsidian vault** with the directory structure from §2.1
2. **Write CLAUDE.md** (< 200 lines) following §6
3. **Write AGENTS.md** — tool-agnostic project overview
4. **Build 3 core skills:** `systems-analyst`, `action-architect`, `obsidian-cli`
    - Create complete SKILL.md files following the conventions in `_system/docs/skill-authoring-conventions.md`
    - Each skill includes all required sections: identity/purpose, procedure, context contract, quality checklist, compound behavior, convergence dimensions
    - The CLI skill (§3.1.5) provides vault query routing, safe command patterns, and fallback behavior
5. **Initialize `_system/logs/session-log.md`** — format from §2.3.4. This captures non-project interactions from the start, ensuring ad-hoc work feeds the compounding system.
6. **Initialize first project** using the Project Creation Protocol (§4.1.5):
    - User provides or confirms project name and domain
    - Create project directory with `run-log.md` and `progress-log.md`
7. **Verify CLI availability:** Run `obsidian vault` to confirm Obsidian CLI is accessible. If not, all workflows function via native file tools — the CLI adds speed and discovery, not required functionality.
8. **Create vault integrity script** (`_system/scripts/vault-check.sh`) per §7.8 — frontmatter validation, summary freshness and schema checks, run-log structural integrity, compound step continuity, session-log compound completeness, project scaffold completeness, task completion evidence, knowledge base tag validation, project-state active task consistency, project-state last_committed field, archive location consistency, MOC schema validation, topics resolution, topics requirement for kb-tagged notes, MOC synthesis density. Add as git pre-commit hook if vault is git-tracked. This is the system's only external mechanical enforcement.
9. **Run it on a real project** — full pipeline through TASK phase at minimum, noting every point of friction

**Why this ordering:** The vault structure, CLAUDE.md, three core skills, and session-log are the minimum for both project and non-project workflows to function. The session-log is included from day one because non-project interactions happen immediately — even vault setup involves ad-hoc decisions worth capturing. The CLI skill is included from day one because indexed search, tag queries, and backlink traversal are immediately valuable for context gathering and knowledge base discovery. Convergence works via inline quality checklists in the skill files. Everything else gets built when the work demands it.

### Phase 1b: First-Use Additions (Days 2-5)

Add these as the first project reveals specific needs. By end of Week 1, all Phase 1 artifacts exist — but built with real context rather than speculatively.

8. **Build `writing-coach` skill** — when you produce the first written deliverable that needs quality improvement
9. **Write file conventions doc** (`_system/docs/file-conventions.md`) — when you've created enough files to see which conventions matter. Clean up any early files missing frontmatter.
10. **Extract convergence rubrics doc** (`_system/docs/convergence-rubrics.md`) — after your first convergence check reveals which dimensions matter. Consolidate from inline checklists in skill files into the standalone rubrics doc using bootstrap content from §4.2.1
11. **Create failure log** (`_system/docs/failure-log.md`) — when you encounter the first failure of any type: false pattern, summary drift, routing error, scope miss, quality miss, or validation failure. Seed it with a real entry, not an empty file. Format defined in §4.8
12. **Write context checkpoint protocol doc** (`_system/docs/context-checkpoint-protocol.md`) — when you first hit context pressure during a phase transition. Until then, CLAUDE.md's session management section is sufficient.
12a. **Write compound protocol doc** (`_system/docs/compound-protocol.md`) — extract from §4.4 when the compound step has run at least 3 times and the full procedure is stable. Until then, CLAUDE.md's §4.4 spec reference is sufficient.
12b. **Write convergence protocol doc** (`_system/docs/convergence-protocol.md`) — extract from §4.2 when you've used non-code convergence rubrics on at least 2 different output types. Until then, CLAUDE.md's §4.2 spec reference is sufficient.
12c. **Write routing heuristics doc** (`_system/docs/routing-heuristics.md`) — extract from §1.2 and §4.1 when routing ambiguities surface that need resolution rules beyond what CLAUDE.md covers. Until then, CLAUDE.md's spec references are sufficient.
13. **Build `audit` skill** — when the vault has enough content to audit (likely end of Week 1). The audit skill (§3.1.4) provides session-start staleness scans and user-initiated full audits going forward.
14. **Build `business-advisor` overlay and overlay index** — Create `_system/docs/overlays/overlay-index.md` (see §3.4.2 for structure) and the business-advisor overlay as template for all future overlays. The index file is required for reliable overlay routing — build it alongside the first overlay. Likely needed early given customer-facing work. See §3.4.3 for complete overlay example.
15. **Begin session cost tracking** — After the first 5 sessions, add a `## Session Cost Log` section to `_system/docs/estimation-calibration.md` recording per-session token usage (date, phase, model, input tokens, output tokens, subagents spawned, notes). Collection method: at session end, record token counts from Claude Code's built-in usage reporting. This data enables every downstream cost decision: subagent model selection (§3.2.1), Opus Plan Mode adoption (§7.7), and context budget calibration.
16. **Create personal context doc** (`_system/docs/personal-context.md`) — write on Day 1 or 2 alongside the first project. Strategic priorities, professional context, and working style preferences per §2.4. This is cheap to create and immediately improves skill behavior for trade-off decisions.
17. ~~**Initialize signal capture** (`_system/docs/signals.jsonl`) — deprecated (v2.2). Signal capture has been retired. Failure detection is now autonomous via `_system/docs/failure-log.md` (see §4.9).~~
17b. **Add binary attachment validations to vault-check.sh** (checks 12-15 per §7.8) — orphan detection, location constraint, description completeness. These checks are inert until binaries exist in the vault but should be present from the start so the first binary committed is immediately governed.
17c. **Document archive/reactivate protocol in CLAUDE.md** — add a `## Project Archival` section referencing the spec procedure (§4.6). This ensures Claude knows the protocol exists without needing to load the full spec.
17d. **Remove `status` from existing project doc frontmatter** — batch operation across all files in `Projects/`. Update vault-check Check 1 to use path-conditional required fields. This is a cleanup task, not urgent — existing `status` fields are ignored, not errored.

**Triggers, not sequence:** Items 8-17 are ordered by likely need, not by requirement. Build each one when its trigger fires, skip it if the trigger hasn't fired by end of Week 1. All should exist by the start of Week 2. Exceptions: the overlay index (item 14) should be created as soon as the first overlay is built — routing depends on it. Personal context (item 16) has no trigger — start as early as practical. Item 17 (signal capture) is deprecated.

### Phase 2: Iterate (Weeks 2-4)

18. Add skills **only** when you empirically find Claude failing at something specific
19. Add Frontend/Backend Designer subagents when single-session context proves insufficient
20. Add overlays from the §3.4.4 backlog when domain expertise gaps are identified
21. Add 1-2 hooks based on actual friction (likely: post-write linting, test runner, post-task compound prompt)
22. Review compound engineering outputs — by this point, phase-level compound reflection (active since Phase 1a) should have captured initial patterns in `_system/docs/solutions/`; consolidate and validate
23. Begin knowledge base tagging — use compound step to tag deliverables with `#kb/[topic]` and link from domain summaries (§5.5)
24. Refine CLAUDE.md routing based on real usage
25. If CLI + file tools prove insufficient (e.g., need Dataview-style computed queries), evaluate Obsidian MCP — see §9 (Deferred Items)
25b. ~~**Build `inbox-processor` skill** — built (v1.6.3). Supports markdown (direct processing) and binary formats via MarkItDown extraction engine. Handles all four ingestion paths (§2.5). Inline attachment protocol (Path A) built as part of this work.~~
25c. ~~**Configure MarkItDown integration** — done (v1.6.3). Installed via `pipx install 'markitdown[all]'`. CLI validated (not MCP — see §7.9). Extraction quality verified on representative samples. Added to `_system/scripts/setup-crumb.sh`.~~
25d. ~~**Configure git binary handling** — done (v1.6.3). `.gitignore` entries for binary extensions per §7.10 added. `.gitattributes` LFS stub added. Companion notes tracked while binaries excluded.~~
25e. **Build MOC system.** Create initial MOC skeleton files per §5.6.12 (including `moc-crumb-operations`). Add `topics` field to frontmatter conventions. Add vault-check checks 17-19, 21. Implement MOC debt scoring in session-start staleness scan. Implement placement pass as part of compound step's kb promotion workflow. Defer synthesis skill to Phase 3 (build when debt score triggers indicate synthesis is needed).
25f. **Add MOC lint to vault-check.sh.** Checks 17-19, 21 per §5.6.10. Run immediately after implementation to validate existing kb-tagged notes against new topics requirement — expect initial failures that need remediation (backfill topics on existing notes).
25g. **Build `peer-review` utility skill.** Implement Option A (pure skill, no helper scripts) against `_system/docs/peer-review-skill-spec.md`. Create `_system/docs/peer-review-config.md` with model endpoints and API key env var references. Create `_system/reviews/` and `_system/reviews/raw/` directories. Start with OpenAI + Gemini; wire Perplexity once the core path is stable. Safety gate and diff-mode logic are the "must not drift" sections — if Claude mis-executes those in practice, extract to helper script (Option B transition per skill spec §10).

### Phase 3: Optimize (Month 2+)

26. Build additional skills and overlays from backlogs based on validated need
27. Consider model routing for subagents when session cost log data shows clear savings
28. Consider Agent Teams for parallel exploration (experimental — evaluate stability first)
29. Establish weekly/monthly maintenance cadence
30. Review and consolidate compound engineering artifacts
31. Update this spec based on learnings (maintain version history)

---

## 9. What This Spec Intentionally Defers

These are things the original v6 design included that this revision deliberately pushes to "build when needed":

| Deferred Item | Why | Build When |
|---|---|---|
| Strategist skill | Option evaluation can be done conversationally first | You find yourself repeatedly doing structured option analysis |
| Ideation Engine skill | Divergent thinking can be prompted ad-hoc | You need structured creative techniques more than twice |
| Momentum Coach skill | Stuckness patterns can be addressed conversationally | Block patterns doc shows recurring patterns |
| Exercise Coach skill | Can use health domain + conversational coaching | You want structured AI-managed workout programs |
| Mental Health Coach skill | Sensitive domain requiring careful design | After establishing trust in the system's judgment |
| Code Router skill | Claude Code already routes to appropriate tools natively | Never — this is what the main session does |
| Additional convergence rubrics | Start with 3 rubrics in bootstrap file | After 3+ iterations on same output type reveal common failure modes (add via compound engineering) |
| Model routing logic | Premature optimization | Token cost data shows clear savings justifying complexity |
| Agent Teams | Experimental, known limitations | Feature stabilizes + you need true parallel coordination |
| Concurrent file write safety | Single-writer assumption holds under current serial execution model; solving prematurely adds complexity with no benefit (see §7.6) | Agent Teams adopted, or concurrent multi-project sessions become routine |
| vault-check.sh auto-repair ("doctor" mode) | Current failure volume doesn't justify repair automation. vault-check.sh detects; the operator or audit skill fixes. | vault-check starts surfacing recurring fixable issues (e.g., same missing field across multiple files). Build a repair mode that emits diagnosis + suggested fixes, optionally applies safe auto-fixes, and logs repairs. |
| Constraint Harvest micro-protocol | Targeted partial reads (§3.1.2) already pull Constraints/Requirements/Interfaces sections at PLAN→TASK. A separate constraint extraction step adds a new artifact with lifecycle overhead. | failure-log shows recurring constraint omission patterns despite targeted partial reads. Then: extract MUST/SHALL/NEVER statements into a working set that tasks reference explicitly. |
| Overlay composition and precedence rules | 8 active overlays — some have overlapping activation signals (e.g., Career Coach / Business Advisor, Life Coach / Career Coach). Current practice: one overlay per skill invocation, selected by best signal match. Companion doc pattern (v2.4) adds auto-loaded reference docs but doesn't change overlay composition. Combinatorial stacking, formal precedence ordering, and multi-overlay sessions don't exist yet. | Empirical evidence of a session where 2+ overlays should have fired simultaneously and the single-overlay constraint degraded output quality. Then: define max simultaneous overlays, deterministic precedence, and "why loaded / why not loaded" trace lines in run-log. |
| Obsidian MCP | CLI + native file tools cover indexed search, backlinks, tags, properties, and file CRUD. MCP adds dependency without clear additional capability over CLI for current needs. | CLI + file tools prove insufficient for a specific workflow (e.g., Dataview-style computed queries, workflows where Obsidian can't be running) |
| ~~Web search tool integration~~ | ~~**Built (v2.4)** — researcher skill uses Claude Code's built-in WebSearch/WebFetch natively.~~ | ~~N/A~~ |
| Hallucination detection web grounding | Currently, code convergence has binary grounding (tests pass/fail) but non-code convergence relies on self-referential rubric scoring. Web search could enable fact-checking summaries against live sources, validating vault knowledge currency during audits, and grounding compound step insights against community consensus. Significant capability upgrade, but depends on stable research tooling. | Researcher skill is stable and you want to extend grounding to audit-time checks. Evaluate whether the improvement in hallucination detection justifies the added complexity and token cost of web queries during audits. |
| OpenClaw integration | **Phases 1+3 operational (v2.0).** OpenClaw runs as dedicated `openclaw` macOS user on Mac Studio (LaunchDaemon, Tier 1 hardening). Crumb-Tess bridge provides bidirectional Telegram communication via atomic file exchange in `_openclaw/inbox/` and `_openclaw/outbox/`. 5 Phase 1 operations live. kqueue file watcher (sub-ms detection) + bridge processor + post-processing governance verification. 325 tests, 15-payload injection test suite, 6 peer review rounds. Phase 2 dispatch protocol designed for multi-stage task execution. Colocation security spec peer-reviewed (3 rounds), bridge spec peer-reviewed (6 rounds). Full project: `Projects/crumb-tess-bridge/`. Integration reference: `_system/docs/openclaw-crumb-reference.md`. | **Remaining (Phases 2+4):** (2) vault skill curation layer (allowlist/denylist, size limits, redaction), cron sync. (4) CLI escalation (`claude --print` from OpenClaw for governed operations), browser automation with domain allowlist. Bridge Phase 2 deferred: Telegram governance failure alerts, `.processed-ids` optimization, production sender allowlist, dispatch protocol implementation for long-running tasks. |
| ~~Semantic search via qmd~~ | ~~**Built (v2.4)** — AKM integrates QMD with decay scoring, 3 trigger modes, daily dedup. Script: `knowledge-retrieve.sh`. Project: `active-knowledge-memory` (DONE).~~ | ~~N/A~~ |
| ClawVault structured memory | ClawVault (by Versatly, MIT licensed, 20 GitHub stars) adds typed categories, observational memory (auto-extracting decisions/lessons/preferences from transcripts), wiki-link knowledge graph, and session lifecycle management (`wake`/`sleep`/`handoff`) on top of qmd. Would automate the OpenClaw→Crumb intake funnel and provide formal cross-system session continuity. Category structure (`decisions/`, `projects/`, `lessons/`) overlaps with Crumb's vault structure — risk of parallel state. Immature project from unproven org. Detailed assessment exists as standalone document. | Running OpenClaw integration Phase 1+2 generates empirical friction data showing: (a) unstructured captures require excessive triage time in Crumb sessions, or (b) cross-system session handoffs fail without formal lifecycle protocol. If neither friction materializes, ClawVault solves a problem you don't have. |
| Vision enrichment for image attachments | Claude Code cannot natively see image content. Current image processing is limited to EXIF metadata extraction via MarkItDown + exiftool (ImageSize, dates, GPS, etc.). No OCR or content description is available through the CLI. MarkItDown supports LLM-based image descriptions via its Python API `llm_client` parameter (tested with GPT-4o, LLaVA via Ollama) — this is the planned implementation vehicle, not a custom build. The companion note schema (§2.2.1) is already designed for this: `description_source` tracks provenance (`null` → `vision-api`), `needs-description` tag identifies candidates for batch enrichment, and the `description` field accepts upgraded content without schema changes. | Two paths: (1) via OpenClaw — delegate image description to OpenClaw's vision-capable models and write results back to companion notes during intake processing, or (2) directly in Crumb — configure MarkItDown with a vision-capable LLM client (requires API key for OpenAI/Anthropic, or a local vision model like LLaVA via Ollama). Evaluate path (1) first if OpenClaw integration is active. Pursue path (2) when the `needs-description` backlog grows large enough that manual descriptions become impractical — compound engineering will surface this friction. |
| Docling as PDF extraction backend | MarkItDown's PDF conversion is adequate for narrative text but loses table structure (validated 2026-02-17): table cells render as flat text, not markdown tables. Headings and bullet lists are preserved. Docling (IBM, MIT licensed, Linux Foundation hosted) uses computer vision models for layout detection, reading order, table structure, and equation recognition — significantly higher fidelity for complex PDFs. Available as both Python API and MCP server. Heavier dependency: downloads AI models from HuggingFace, requires more disk space and processing time. | Compound engineering surfaces recurring PDF quality issues — the inbox processor's MarkItDown-generated summaries are consistently inadequate for a specific document type (e.g., dense technical proposals, contracts with complex tables, academic papers). Then: swap the PDF backend to Docling while keeping MarkItDown for office documents and images. The companion note schema is tool-agnostic — the extraction engine is an implementation detail of the inbox processor skill, not a spec-level architectural choice. |
| MOC synthesis skill | Synthesis pass (§5.6.7) requires LLM judgment for rewriting prose, restructuring sections, and proposing splits/merges. A dedicated skill ensures consistent synthesis quality with proper context contracts and convergence dimensions. | MOC debt scores regularly exceed threshold (>30 points on 3+ MOCs). Until then, synthesis can be done conversationally during sessions where the operator notices a MOC needs attention. |
| Automated delta refresh | Delta computation (§5.6.11) is deterministic and could run as a pre-commit hook or session-start script. Currently described as a session-start operation within the staleness scan. | Delta computation takes >5 seconds or the operator wants deltas to be always-fresh without manual triggering. |
| MOC split/merge protocol | Formal procedure for splitting an oversized MOC into sub-MOCs or merging converged MOCs. Currently handled ad-hoc. | Any MOC's Core section exceeds 25 notes, or two MOCs' content has converged to >60% overlap. |
| Graph metrics (betweenness, clustering) | Algorithmic computation of graph structure metrics for automated cluster detection and bridge identification. Currently, visual inspection in Obsidian's graph view is sufficient. | Vault exceeds ~500 kb-tagged notes and visual inspection no longer reveals global structure. |
| Bulk-update delta suppression | Mechanism to prevent mass-rewrite operations from inflating delta counts across all MOCs (§5.6.8 known limitation). Possible implementations: `mechanical-update` tag, commit-message convention, or a pre-delta filter that ignores notes where only frontmatter metadata changed. | Bulk-update false triggers become a recurring operational annoyance (3+ occurrences logged). |

---

*This spec gives you everything necessary to build the Crumb system: components, primitives, workflows, context policy, implementation phases, and explicit guidance on what to build now vs. later.*
