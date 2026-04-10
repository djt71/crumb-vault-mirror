---
type: reference
domain: null
skill_origin: null
status: active
created: 2026-02-15
updated: 2026-03-06
tags:
  - file-conventions
  - system-config
---

# File Conventions

Conventions for all files in the Crumb vault. These enable Obsidian CLI queries (property filtering, tag-based search), knowledge base discovery via `#kb/*` tags, and consistent vault maintenance. Full specification: _system/docs/crumb-design-spec-v2-0.md §2.2.

## YAML Frontmatter

Required on all substantive documents (skip only for trivial scratch notes that won't be queried).

### Project docs (under `Projects/` or `Archived/Projects/`)

```yaml
---
project: project-name        # required — matches directory name
domain: software              # software | career | health | learning | financial | relationships | creative | spiritual | lifestyle
type: specification           # see Type Taxonomy below
skill_origin: systems-analyst # which skill created/owns this doc, or null
created: 2026-02-12
updated: 2026-02-12
topics:                       # MOC membership — required if this file has #kb/ tags (§5.6.5)
  - moc-dns-migration-patterns
tags:
  - relevant-tag
  - kb/topic-name             # knowledge base tag — marks durable knowledge (§5.5)
---
```

**No `status` field.** Project docs inherit lifecycle from directory location — `Projects/` = active, `Archived/Projects/` = archived. If `status` is present on project docs, it is ignored (not an error, just unnecessary).

### Non-project docs (`Domains/`, `_system/docs/`, `_system/reviews/`, `_attachments/`, `Archived/KB/`, vault root)

```yaml
---
project: null                 # null for global docs, or project-name if affiliated
domain: software              # software | career | health | learning | financial | relationships | creative | spiritual | lifestyle
type: specification           # see Type Taxonomy below
skill_origin: systems-analyst # which skill created/owns this doc, or null
status: active                # active | archived | draft — REQUIRED for non-project docs
created: 2026-02-12
updated: 2026-02-12
topics:                       # MOC membership — required if this file has #kb/ tags (§5.6.5)
  - moc-dns-architecture
tags:
  - relevant-tag
  - kb/topic-name             # knowledge base tag — marks durable knowledge (§5.5)
---
```

**Required fields (non-project):** project, domain, type, status, created, updated. vault-check validates these.

**Required fields (project):** project, domain, type, created, updated. vault-check validates these.

**Summary-specific field:** `source_updated: YYYY-MM-DD` — records the parent document's `updated` value when the summary was generated. Used by staleness detection.

**Optional fields:** skill_origin, tags, topics, and any domain-specific fields (e.g., `customer`, `dossier` for customer-intelligence docs).

**Solution doc fields (`_system/docs/solutions/`):** `track: bug | pattern | convention` — required. Classifies the insight type and determines body section schema. See spec §4.4 for track-specific body sections. `confidence: high | medium | low` — required. Determines publication gate.

### `topics` field (MOC membership)

Required on any note with a `#kb/` tag. Lists the MOC(s) this note belongs to.

- Format: MOC filenames without `.md` and without path (e.g., `moc-dns-migration-patterns`)
- vault-check resolves each entry to `Domains/*/[entry].md` — zero matches or multiple matches are errors
- Resolved file must have `type: moc-orientation` or `type: moc-operational`
- MOC files themselves don't need a `topics` field
- Full details: spec §5.6.5, §5.6.10

## Wikilink Convention

Obsidian is configured with **shortest-path** wikilink resolution (default `newLinkFormat` — no override in `app.json`).

- **Bare wikilinks** (`[[filename|Display Name]]`) — use for globally-unique basenames. This is the default and preferred style.
- **Path-prefixed wikilinks** (`[[Projects/foo/design/specification|Display Name]]`) — use **only** when the basename is ambiguous (multiple files share the same name, e.g., `specification.md` exists in 10+ projects). Obsidian interprets path-prefixed links as vault-relative paths.

**In MOC Core sections:** One-liners use bare wikilinks. When a target filename is known to be ambiguous, use the full vault path. Document the ambiguity reason in a code comment or the MOC's Tensions section if it's non-obvious.

**Validation:** vault-check enforces MOC filename uniqueness (Check 17). Non-MOC filename uniqueness is not currently enforced mechanically — Obsidian's graph view highlights ambiguous links visually.

## Cross-Referencing Routed Documents

When routing a document to a new vault location (from `_inbox/`, between directories, or from a project), **add a wikilink from the document that would naturally lead someone to the new content**. Without this, routed docs sit undiscovered.

Examples:
- Routing a beyond-roadmap research doc to `Projects/tess-operations/design/` → add a `[[beyond-current-roadmap-research]]` link from `frontier-ideas.md`
- Routing an agent skills best-practices doc to `_system/docs/` → add a `[[agent-skills-best-practices]]` link from `skill-authoring-conventions.md`

This is a one-edit, high-leverage convention — it creates permanent discoverability at the point of routing.

## File Naming

- **kebab-case**, always: `frontend-design.md`, `api-spec.md`, `auto-club-group.md`
- **Descriptive** — recognizable without context months later
- **Summaries** use `*-summary.md` alongside the full doc in the same directory
- **Run logs** use `run-log.md` (current) and archived variants (see Run-Log Rotation below)
- **Session logs** live in `_system/logs/`: `session-log.md` (current) and `session-log-YYYY-MM.md` (archived)
- Avoid generic names: `notes.md`, `draft.md`, `temp.md`

### Binary filename conventions

Filenames carry queryable context — since agents cannot see binary content, the filename is often the highest-value metadata. All binaries SHOULD follow these patterns:

| Category | Pattern | Example |
|---|---|---|
| Screenshots | `screenshot-[project]-[task]-[slug]-YYYYMMDD-HHMM.[ext]` | `screenshot-acme-IMPL-003-dns-config-20260217-1430.png` |
| Diagrams | `diagram-[project]-[slug]-v[NN].[ext]` | `diagram-acme-network-topology-v02.svg` |
| Inbound docs | `inbound-[source]-[slug]-YYYYMMDD.[ext]` | `inbound-acme-corp-current-dns-export-20260215.pdf` |
| Exports | `export-[project]-[slug]-YYYYMMDD.[ext]` | `export-personal-site-wireframes-20260220.png` |
| Personal | `[descriptive-slug]-YYYYMMDD.[ext]` | `garden-raised-bed-progress-20260301.jpg` |

Minimal fallback (when project/task unknown at capture): drop the project/task segments. The inbox processor proposes the full rename when context becomes available.

### File size guidance

**Soft threshold: 10MB per file.** Ingestion paths (inbox processor, inline attachment protocol) flag files exceeding 10MB for user confirmation. vault-check reports files over 10MB as warnings, not errors. The audit skill's weekly review includes total attachment storage for visibility. Full details: spec §2.2.3.

## Companion Notes (Attachment Companions)

Every binary file in the vault MUST have a colocated markdown companion note. The companion is the agent-facing interface — the only surface through which a binary participates in queries, task references, and audit.

**Naming:** `[binary-filename-without-extension]-companion.md`, same directory as the binary.

**Frontmatter:**

```yaml
---
project: project-name        # or null for global binaries
domain: software
type: attachment-companion    # fixed value
skill_origin: inbox-processor # or inline-attachment | manual
created: 2026-02-17
updated: 2026-02-17
tags:
  - needs-description         # present when description is stub; removed once populated
attachment:
  source_file: Projects/acme/attachments/screenshot-acme-IMPL-003-dns-config-20260217.png
  filetype: png               # extension without dot
  source: generated           # inbox | generated | external | manual
  size_bytes: 245760
  description_source: null    # null | filename-derived | user-provided | markitdown | vision-api
                              # ocr is reserved/future — EasyOCR was never integrated (spec §7.9)
related:
  task_ids: [IMPL-003]        # optional
  docs: [design/api-spec.md]  # optional
description: >
  Short synopsis — what this file is and why it's in the vault.
summary: >
  For text-extractable docs only. First ~500 chars of MarkItDown output.
  Empty/absent for images.
---
```

**Body structure:** Title, Purpose line, embed (`![[filename]]`), Notes section, Extracted Content section (text-extractable docs only). Full schema and examples: spec §2.2.1.

**Status field rule:** Project-scoped companions omit `status` (directory is authoritative). Global companions (under `_attachments/`) include `status`.

**Quality tags:** `needs-description` (stub description, flagged by audit) and `needs-extraction` (failed text extraction, flagged by audit).

## Knowledge Notes

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
  - kb/history                         # MANDATORY — at least one #kb/ tag
  - kb/business
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

**Sentinel contract:** See `_system/docs/templates/notebooklm/sentinel-contract.md` for the machine-readable marker spec used by the inbox-processor to detect NLM exports.

## Source Index Notes

Source index notes are per-source landing pages that aggregate all knowledge notes (digests, extracts) for a single source. They live in the same `Sources/[type]/` directory as their child knowledge notes.

**Naming:** `[source_id]-index.md` (e.g., `rawls-theory-justice-index.md`)

**Frontmatter:**

```yaml
---
project: null                          # or project name if source feeds a specific project
domain: learning                       # primary domain
type: source-index
skill_origin: inbox-processor          # or manual
status: active
created: 2026-02-24
updated: 2026-02-24
tags:
  - kb/philosophy                      # union of kb/ tags from child notes
source:
  source_id: rawls-theory-justice      # stable slug — same algorithm as knowledge notes
  title: "A Theory of Justice"
  author: "John Rawls"
  source_type: book                    # book | article | podcast | video | course | paper | other
  canonical_url: null                  # optional — URL, ISBN, DOI
topics:
  - moc-philosophy                     # required per §5.6.5 (has kb/ tags)
---
```

**Body sections:**

1. **Header** — title, author, type, ingested date
2. **Overview** — 2-4 sentences summarizing the source (drawn from digest or manual)
3. **Notes** — table of all child knowledge notes (deterministic, machine-maintained)
4. **Reading Path** — optional navigation order (valuable for multi-chapter books)
5. **Connections** — aggregated cross-references from child notes

**MOC relationship:** Source index notes get one-liners in MOC Core sections (not individual knowledge notes per source). This keeps MOC Core manageable — a single source with multiple digests/extracts gets one MOC entry via its index note.

## Signal Notes

Signal notes are lightweight knowledge captures from the feed intel pipeline. They live in `Sources/signals/` and represent high-signal content items that passed the auto-promote gate (high priority + high confidence + capture action + clear #kb/ tag mapping). A signal note is a pointer with provenance — excerpt, assessment, source link, and traceability back to the original triage.

**Promotion path:** A signal-note can later be promoted to a full `knowledge-note` when the source is processed through NotebookLM or deep reading. The `source_id` stays the same; the signal-note is replaced or kept alongside the full digest.

**Frontmatter:**

```yaml
---
project: null                          # or project name if source feeds a specific project
domain: learning                       # primary domain
type: signal-note
skill_origin: feed-pipeline
status: active
created: 2026-03-01
updated: 2026-03-01
tags:
  - kb/software-dev                    # MANDATORY — at least one #kb/ tag
schema_version: 1
source:
  source_id: author-short-title        # standard source_id algorithm
  title: "..."
  author: "..."
  source_type: tweet                   # tweet | article | blog | video | paper
  canonical_url: https://...
  date_ingested: 2026-03-01
  provenance:
    inbox_canonical_id: "x:2024816569818534335"
    triage_priority: high
    triage_confidence: high
topics:
  - moc-crumb-architecture             # derived via kb-to-topic.yaml
---
```

**source_id algorithm:** Same as knowledge notes — `kebab(author-surname + short-title)`, max 60 chars, `[a-z0-9-]` only, collision detection against `Sources/**/*.md`.

**Body structure:**

```markdown
# [Short Title]

## Signal

[Excerpt from original source + triage "Why now" assessment]

## Source

[Canonical URL / link to original]

## Context

[Why this matters to the vault — connection to existing knowledge or projects]
```

**Directory:** `Sources/signals/` (not subdivided by source_type — signal notes are thin enough that a flat directory works).

**MOC integration:** Signal notes get one-liners in MOC Core sections, same as source-index notes.

## Attention Items

Attention items represent things that need the operator's attention — system alerts, tasks, follow-ups, and awareness items. They live in `_inbox/attention/` and are consumed by the mission-control dashboard's attention aggregator.

**Filename:** `attention-{uuid}.md` (UUID v4 generated at creation time).

**Directory:** `_inbox/attention/` (active items). Completed/dismissed items stay in the same directory with updated `status` field.

```yaml
---
type: attention-item
attention_id: cbecc3ec-a66e-414b-bfe7-da25a9ba0c23   # UUID v4, unique
kind: personal                # system | relational | personal
domain: software              # one of the 8 Crumb domains
source_overlay: null           # overlay that generated the item, if any
source_system: null            # upstream system (e.g., vault-check, fif, dashboard)
source_ref: null               # dedup key for the source system
created_by: dashboard          # who/what created it (dashboard, crumb-session, manual)
status: open                   # open | in-progress | done | deferred | dismissed
urgency: soon                  # now | soon | ongoing | awareness
action_type: null              # optional — review, approve, follow-up, etc.
related_entity: null           # optional — wikilink to related vault note/entity
created: 2026-03-07
due: null                      # optional — YYYY-MM-DD
schema_version: 1
updated: 2026-03-07
tags:
  - attention
  - software                   # domain tag
---
```

**Required fields:** `type`, `attention_id`, `kind`, `domain`, `status`, `urgency`, `schema_version`, `created`, `updated`.

**Valid enum values:**
- `kind`: system, relational, personal
- `domain`: career, financial, health, creative, spiritual, relationships, software, learning
- `urgency`: now, soon, ongoing, awareness
- `status`: open, in-progress, done, deferred, dismissed

**Body structure:**

```markdown
# [Title]

[Optional description / context]
```

## Summary Documents

Every summary follows the structure in spec §5.3:
- Same frontmatter as parent doc, with `type: summary` and `source_updated` field
- Sections: Core Content (2-4 paragraphs), Key Decisions (bulleted), Interfaces/Dependencies, Next Actions
- Summaries are read-only references — update the parent first, then regenerate
- Regenerate as part of the same operation when the parent is modified
- The staleness scan compares `source_updated` against parent's `updated` at every load

## Run-Log Rotation

Run logs grow unbounded during long projects. Rotate to keep the active file small (~200 lines target) without losing history.

**When to rotate:**
- Phase boundary (preferred) — e.g., Phase 1 complete → archive, Phase 2 starts fresh
- Size threshold — when run-log exceeds ~1000 lines or ~60KB, rotate at the nearest natural boundary
- Whichever trigger comes first

**Archive naming:** `run-log-{label}.md` where label describes the content:
- Phase-based: `run-log-phase1.md`, `run-log-phase2.md`
- Date-based fallback (for projects without clear phases): `run-log-YYYY-MM.md`

**Procedure:**
1. Copy lines up to the boundary into the archive file
2. Update archive frontmatter: `status: archived`, add `covers:` field describing content span
3. Add archive header note pointing to the active file
4. Rewrite active `run-log.md` with retained sessions + header pointing to archive(s)
5. Active file keeps `status: active`

**Rules:**
- Never summarize-and-discard — full history has debugging value
- Archive is read-only after creation (no appending)
- Cross-reference headers in both directions (archive → active, active → archive)
- Session numbering continues across rotation (no restart)
- Claude should propose rotation when thresholds are crossed; user confirms

## Knowledge Base Tags

Tags with the `#kb/` prefix mark documents with durable knowledge value beyond their originating project. Three-level hierarchy, hard cap — do not nest deeper than `#kb/topic/subtopic`.

**Defined Level 2 topics** (use these; create new ones only for genuinely new categories):

`#kb/religion` · `#kb/philosophy` · `#kb/gardening` · `#kb/history` · `#kb/inspiration` · `#kb/poetry` · `#kb/writing` · `#kb/business` · `#kb/networking` · `#kb/security` · `#kb/software-dev` · `#kb/customer-engagement` · `#kb/training-delivery` · `#kb/fiction` · `#kb/biography` · `#kb/politics` · `#kb/psychology` · `#kb/lifestyle`

**Level 3 subtopics** emerge through compound engineering (e.g., `#kb/networking/dns`, `#kb/business/pricing`). Not predefined — created when a Level 2 topic accumulates enough notes that finer filtering becomes useful. When a candidate Level 2 tag is clearly subordinate to an existing Level 2 (e.g., DNS is a subtopic of networking, not a peer), use Level 3 instead. Cross-domain topics use dual tagging (e.g., `kb/networking/dns` + `kb/security` for DNS security).

**Rules:**
- Use existing tags when they fit; prefer the closest Level 2 match over creating a new one
- All `#kb/`-tagged notes MUST have a `topics` field listing their parent MOC(s)
- Audit skill checks for orphaned `#kb/*` notes, premature Level 3 fragmentation, and untagged candidates weekly
- Stale KB notes are archived to `Archived/KB/` — see `_system/docs/vault-gardening.md`
- Full convention details in spec §5.5

**Knowledge integration layers:** AKM handles runtime discovery via `#kb/` tags (automatic — notes enter the queryable pool when tagged); MOC placement via inbox-processor (semi-automatic — `topics` field drives routing); overlay/skill source catalog curation is manual (editorial judgment — Vault Source Material sections are curated references, not tag queries).

## System Documentation Tags

Tags for the documentation architecture under `_system/docs/`. Not validated by vault-check (unlike `#kb/` tags) but canonical by convention.

**Defined tags:**

- `system/architecture` — Arc42-derived architecture docs in `_system/docs/architecture/`
- `system/operator` — Diátaxis-organized operator docs in `_system/docs/operator/`
- `system/llm-orientation` — LLM orientation tracking docs in `_system/docs/llm-orientation/`
- `system/docs` — general tag for any doc under `_system/docs/` (existing convention, used alongside the specific tags above)

These tags coexist with existing flat tags (`system`, `system-config`, `system-health`, `overlay`, `protocol`, etc.) which remain valid.

## Review Files

Peer review outputs (synthesis notes + raw LLM responses) are co-located with their projects.

**Routing rule:**
- If the reviewed artifact has a `project` field and `Projects/{project}/` exists: write to `Projects/{project}/reviews/` (synthesis) and `Projects/{project}/reviews/raw/` (raw JSON)
- Otherwise: write to `_system/reviews/` (synthesis) and `_system/reviews/raw/` (raw JSON)

**Structure per project:**
```
Projects/{project}/reviews/
  {YYYY-MM-DD}-{artifact-name}.md          # synthesis note
  {YYYY-MM-DD}-{artifact-name}-r2.md       # round 2, etc.
  raw/
    {YYYY-MM-DD}-{artifact-name}-{reviewer}.json
```

**Non-project reviews** (system primitives, vault-level artifacts) remain in `_system/reviews/` and `_system/reviews/raw/`.

The peer-review skill and peer-review-dispatch agent handle this routing automatically based on the artifact's `project` frontmatter field.

## Skill Definitions

Skill files (`.claude/skills/*/SKILL.md`) use YAML frontmatter with Claude Code standard fields (`name`, `description`) plus optional Crumb extensions.

### `required_context` Field

Declares solutions docs (or other context files) that MUST be loaded when the skill activates under specified conditions. This closes the read-back loop for compound engineering — patterns captured in `_system/docs/solutions/` are mechanically loaded, not left to discretionary judgment.

```yaml
---
name: writing-coach
description: >
  Improve clarity, structure, tone, argument, and brevity of written content.
required_context:
  - path: _system/docs/solutions/writing-patterns/ai-telltale-anti-patterns.md
    condition: audience_external
    reason: "Prevents AI-telltale patterns in deliverables"
---
```

**Field semantics:**

- `path` — Vault-relative path. MUST exist; log a warning if missing (not a hard failure).
- `condition` — When to load. Evaluated by the skill's procedure against current task context.
  - Canonical conditions: `always`, `audience_external`, `audience_customer`, `software_project`
  - Skills may define additional conditions documented in their procedure.
- `reason` — Human-readable justification. Included in context inventory log entries.

**Enforcement:** Early in the skill's procedure (context gathering step). Read `required_context` entries, evaluate conditions, load matching docs. This is a MUST, not a MAY. Context inventory logged to run-log includes which entries were loaded and which were skipped (with condition evaluation result).

**Context budget interaction:** Required context docs count against the standard budget (≤5 source docs per skill invocation). If required_context entries would push the skill over budget, prioritize required_context over discretionary loads and log a warning.

**Audit validation:** The audit skill checks for orphaned solutions docs (no `required_context` entry in any skill) and stale linkage (entries pointing to nonexistent paths or skills). See audit skill weekly checks.

## Type Taxonomy

| Type | Used For |
|---|---|
| `specification` | Problem definitions, requirements, system analysis |
| `design` | Technical design documents (frontend, backend, API, data model) |
| `adr` | Architecture Decision Records |
| `task` | Action plans, task lists |
| `pattern` | Reusable patterns in `_system/docs/solutions/` |
| `log` | Run logs, progress logs, session logs, failure log |
| `summary` | Compressed versions of parent documents |
| `reference` | System config docs (convergence rubrics, overlay index, personal context, file conventions) |
| `overlay` | Expert lens files in `_system/docs/overlays/` |
| `comms-strategy` | Customer communication strategies |
| `attachment-companion` | Companion notes for binary files (§2.2.1) |
| `knowledge-note` | Synthesized knowledge from external sources (NotebookLM pipeline), stored in `Sources/` |
| `collection` | Preserved full-text source material with lightweight metadata (e.g., poetry collections), stored in `Sources/` |
| `moc-orientation` | Maps of Content — orientation/synthesis MOCs for topic-level navigation (§5.6) |
| `moc-operational` | Maps of Content — operational/procedural MOCs (§5.6) |
| `source-index` | Per-source landing pages aggregating all knowledge notes for a source, stored in `Sources/[type]/` |
| `signal-note` | Lightweight knowledge capture from feed intel pipeline, stored in `Sources/signals/` |
| `x-feed-intel` | Feed intelligence items routed to vault by the x-feed-intel pipeline |
| `quick-capture` | Lightweight captures from Tess via `_openclaw/inbox/`, pending Crumb processing |
| `personal-writing` | Operator-authored creative and reflective writing, stored in `Domains/Creative/writing/` |
| `plan` | Forward-looking action documents with phases, checkpoints, and progress tracking (e.g., learning plans) |
| `attention-item` | Operator attention items in `_inbox/attention/` — system alerts, tasks, follow-ups (§ Attention Items) |
| `daily-attention` | Daily curated attention plan produced by attention-manager skill, stored in `_system/daily/` |
| `attention-review` | Monthly attention review/synthesis produced by attention-manager skill, stored in `_system/daily/` |

**MOC location:** MOC files live in `Domains/*/` directories (e.g., `Domains/career/moc-training-delivery.md`). Filenames must be globally unique across all domain directories — vault-check enforces this.

**MOC-specific frontmatter:** MOC files require additional fields: `scope`, `last_reviewed`, `review_basis` (`delta-only` | `full` | `restructure`), `notes_at_review`. vault-check validates these. Full schema: spec §5.6.10.

Extend this taxonomy through the compound step when new document types emerge — don't predefine types speculatively.
