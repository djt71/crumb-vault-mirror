---
project: notebooklm-pipeline
domain: learning
type: specification
skill_origin: systems-analyst
created: 2026-02-18
updated: 2026-02-18
topics:
  - moc-crumb-architecture
tags:
  - knowledge-management
  - notebooklm
  - pipeline
  - kb/software-dev
---

# NotebookLM-to-Crumb Knowledge Pipeline

## Problem Statement

Heavy use of Google NotebookLM for ingesting books, articles, podcasts, videos, and other media generates valuable synthesized knowledge — summaries, concept extracts, argument maps, structured tables — that currently lives trapped inside NotebookLM with no systematic way to bring it into Crumb's knowledge base. This knowledge needs to flow into the vault as connected, searchable, actionable notes that feed into projects and decisions across all domains.

## Facts vs Assumptions

### Facts
- NotebookLM has **no official API** for querying content or extracting generated notes (Enterprise API handles only notebook/source lifecycle)
- Chrome extensions exist for markdown export: "NotebookLM Ultra Exporter" (batch export, 10+ formats, free, local processing) and "NotebookLM to LaTeX & MD" (simple markdown export)
- NotebookLM's Data Tables feature can generate structured tables exportable to Google Sheets
- User has Google AI Pro subscription (consumer NLM, not Enterprise)
- User ingests everything: books, articles, podcasts, videos, PDFs, slides
- Usage is heavy and frequent — multiple notebooks, weekly or more
- Goal is connected knowledge that feeds into projects and decisions (second brain)
- Crumb already has: `#kb/` tag hierarchy, inbox-processor skill, YAML frontmatter conventions, domain routing

### Assumptions
- Chrome extension markdown export will produce clean enough output to parse programmatically (VALIDATE: test with actual exports — this is the pipeline's single biggest fragility point; see D4 fallback path)
- NotebookLM's output quality is high enough that summaries don't need heavy post-processing (VALIDATE: review sample outputs; see D4 quality gate for low-citation sources)
- A new `knowledge-note` document type will integrate cleanly with the existing type taxonomy (VALIDATE: test with vault-check)
- Structured query templates run inside NLM will reliably produce consistent output formats (VALIDATE: test template stability across sessions)
- Chrome extensions work with consumer-tier NLM + AI Pro (VALIDATE: test before building parser — extensions may rely on undocumented UI scraping)

### Unknowns
- Exact markdown structure produced by the Chrome extensions — need sample exports to design parser (blocking for NLM-004; resolved in NLM-003)
- Whether NLM's Data Tables export (→ Sheets → CSV → markdown) is a useful parallel path (deferred to v2)
- Optimal balance between digest depth and processing overhead for heavy usage
- Whether the user prefers one Chrome extension over another (or has already tried one)

## System Map

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Google NotebookLM                         │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌───────────┐ │
│  │ Books    │  │ Articles │  │ Podcasts  │  │ Videos    │  │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘  └─────┬─────┘ │
│       └──────────────┴──────────────┴──────────────┘       │
│                         │                                   │
│              ┌──────────▼──────────┐                        │
│              │  Query Templates    │  ← Crumb provides      │
│              │  (structured prompts│    these templates      │
│              │   run by user)      │                         │
│              └──────────┬──────────┘                        │
│                         │                                   │
│              ┌──────────▼──────────┐                        │
│              │  Generated Output   │                        │
│              │  (notes, tables,    │                        │
│              │   summaries)        │                        │
│              └──────────┬──────────┘                        │
└─────────────────────────┼───────────────────────────────────┘
                          │
               ┌──────────▼──────────┐
               │  Chrome Extension   │  Export to markdown
               │  (Ultra Exporter    │
               │   or LaTeX/MD)      │
               └──────────┬──────────┘
                          │  .md files
               ┌──────────▼──────────┐
               │    _inbox/          │  Standard Crumb intake
               └──────────┬──────────┘
                          │
               ┌──────────▼──────────┐
               │  NLM Processor      │  Classify, add frontmatter,
               │  (inbox-processor   │  tag, route, link
               │   extension or      │
               │   new skill)        │
               └──────────┬──────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
   ┌──────────┐    ┌──────────┐    ┌──────────┐
   │ Sources/ │    │ #kb/tags │    │ Domain   │
   │ [type]/  │    │ cross-   │    │ summary  │
   │ notes    │    │ linking  │    │ updates  │
   └──────────┘    └──────────┘    └──────────┘
```

### Dependencies
- **Upstream:** NotebookLM (Google), Chrome extension ecosystem
- **Downstream:** Vault search, domain summaries, project context, kb/ tag graph
- **Internal:** inbox-processor skill (extend or compose), file-conventions.md (extend type taxonomy), vault-check.sh (validate new type)

### Constraints
- No programmatic API access to NLM — human-in-the-loop for query and export steps
- Chrome extension must work with consumer NLM + AI Pro
- Output must conform to Crumb vault conventions (frontmatter, naming, type taxonomy)
- Must not break existing inbox-processor workflow — extend, don't replace
- NLM AI Pro tier has a daily chat query limit (~50 queries/day) — template-heavy workflows should batch queries per session, not per-note

### Levers (high-impact intervention points)
1. **Query templates** — the single highest-leverage piece. Well-designed templates that produce Crumb-structured output minimize post-processing and maximize knowledge quality
2. **Document schema** — getting the knowledge-note schema right enables everything downstream (search, linking, MOC generation, project feeding)
3. **Processing automation** — how much the inbox processor can infer vs. ask reduces friction for heavy usage

### Second-Order Effects
- Growing kb/ tag graph will need MOC (Map of Content) support sooner (already planned per learning-overview.md)
- Heavy knowledge note volume may warrant a dedicated Sources/ directory rather than scattering across Domains/
- Cross-domain knowledge notes will test the single-domain frontmatter convention — may need `domains: [list]` or rely purely on kb/ tags for cross-domain discovery
- Query templates become a sharable artifact — could benefit other NLM users

## Domain Classification & Workflow Depth

- **Domain:** Learning
- **Workflow:** Full four-phase (SPECIFY → PLAN → TASK → IMPLEMENT) — this involves new vault conventions, document types, query templates, processing logic, and potentially a new skill
- **Rationale:** Multiple new artifacts (schema, templates, processing logic), extends core vault conventions, touches inbox-processor and vault-check — warrants full rigor

## Design Decisions

### D1: Vault Location for Knowledge Notes

**Decision:** Dedicated `Sources/` top-level directory, organized by source type.

```
Sources/
  books/
    thinking-fast-and-slow.md
    wolf-hall.md
  articles/
    ...
  podcasts/
    ...
  videos/
    ...
  courses/
    ...
```

**Rationale:**
- Knowledge notes are about **external sources**, not vault-internal work — they don't belong under `Domains/` or `Projects/`
- Heavy usage means they'll quickly outnumber other domain content in any single Domain folder
- Source-type browsing is natural ("show me all my book notes")
- Cross-domain discovery happens through `#kb/` tags, not physical location
- Clean separation between source knowledge and working documents

**Trade-off:** Adds a new top-level directory. Acceptable because it serves a distinct purpose and keeps Domains/ focused.

### D2: Document Type and Schema

**Decision:** New type `knowledge-note` with a `source` metadata block in frontmatter.

```yaml
---
project: null                          # or project name if source feeds a specific project
domain: learning                       # primary domain (see Cross-Domain rule below)
type: knowledge-note
skill_origin: inbox-processor          # or nlm-processor if we build a dedicated skill
status: active
created: 2026-02-18
updated: 2026-02-18
tags:
  - kb/history                         # kb/ tags are MANDATORY for cross-domain discovery
  - kb/business
  # - needs_review                     # added for low-citation sources (podcasts, videos)
source:
  source_id: kahneman-thinking-fast    # stable slug: kebab(author-surname + short-title)
  title: "Thinking, Fast and Slow"
  author: "Daniel Kahneman"
  source_type: book                    # book | article | podcast | video | course | paper | other
  canonical_url: null                  # optional — URL, ISBN, DOI for provenance and collision disambiguation
  notebooklm_notebook: "Kahneman"     # NLM notebook name for traceability
  date_ingested: 2026-02-18           # when exported from NLM
  queried_at: 2026-02-18              # when the NLM query was run
  query_template: book-digest-v1       # versioned template name
note_type: digest                      # v1: digest | extract (concept-map, argument-map, data-table planned for v2)
schema_version: 1                      # schema version for forward-compatible evolution
scope: whole                           # whole | chapter:<name> | section:<id> | timestamp:<range> | topic:<name>
---
```

**Source identity and deduplication:** The `source_id` field is a stable slug derived from `kebab(author-surname + short-title)` (e.g., `kahneman-thinking-fast`). When a generated slug already exists in the vault but maps to a different source (different `canonical_url`, `title`, or `author`), append the publication year or a 4-char title hash for disambiguation (e.g., `smith-thinking-2019`). The inbox-processor checks for collisions during intake. All knowledge-notes referencing the same source share the same `source_id`. This enables:
- Linking multiple notes per source (a digest, extracts, and a data table from the same book)
- Deduplication detection during intake (inbox-processor checks for existing notes with the same `source_id` + `note_type` + `scope`)
- Future source-index-note aggregation (v2)

**Dedup behavior:** When a duplicate identity (`source_id` + `note_type` + `scope`) is detected, the inbox-processor prompts the user with three options: (1) **update in-place** — overwrite the existing note with the new content, preserving the original `created` date; (2) **create versioned copy** — save as `[filename]--rev2.md` alongside the original; (3) **skip** — discard the new export. Default: prompt. No silent overwrites.

**Cross-domain rule:** The `domain:` field records the **primary** domain — the single best fit. Cross-domain discovery is handled exclusively through `#kb/` tags, which are **mandatory** on all knowledge-notes (at least one `#kb/` tag required). This avoids the complexity of `domains: [list]` while preserving full cross-domain searchability. Vault-check enforces the tag requirement.

**Scope rule:** One query = one note. Each knowledge-note has a defined `scope` indicating what portion of the source it covers. For multi-chapter or multi-section needs, the user runs the template once per scope unit and exports individually. The `scope` field combined with `source_id` and `note_type` forms the unique identity of a knowledge-note. For non-linear media (podcasts, interviews), use `topic:<name>` when conceptual boundaries are more meaningful than timestamps.

**Quality gate:** Notes from low-citation source types (podcasts, videos, audio) receive a `needs_review` tag by default during intake. Templates for these source types include a "Uncertain / Needs Verification" section to flag claims that lack direct evidence. The `needs_review` tag is removed when the user has reviewed the note.

**Source type ↔ folder mapping** (canonical — used by inbox-processor for routing):

| `source_type` | Folder | Notes |
|---|---|---|
| `book` | `Sources/books/` | |
| `article` | `Sources/articles/` | Blog posts, news articles, essays |
| `podcast` | `Sources/podcasts/` | |
| `video` | `Sources/videos/` | YouTube, lectures, talks |
| `course` | `Sources/courses/` | Structured learning |
| `paper` | `Sources/papers/` | Academic/research papers |
| `other` | `Sources/other/` | Anything not fitting above |

**Body structure** (varies by note_type):

**Digest:**
```markdown
# [Source Title]

## Core Thesis
[1-3 sentences]

## Key Arguments
- [Argument 1]
- [Argument 2]
- ...

## Key Concepts
- **[Concept]** — [definition/explanation]

## Notable Quotes
> [Quote] (p. XX)

## Takeaways & Applications
- [How this connects to my work/life/domains]

## Uncertain / Needs Verification
- [Claims without direct evidence — included for podcasts/video sources]

## Connections
- [[related-note-1]]
- [[related-note-2]]
```

**Extract:**
```markdown
# [Topic] — from [Source Title]

## Concepts
- **[Concept]** — [explanation]

## Arguments
1. [Argument with evidence]

## Evidence & Quotes
> [Quote] (p. XX)

## Connections
- [[related-note-1]]
```

### D3: Query Templates

**Decision:** A library of versioned, structured prompts stored in `Projects/notebooklm-pipeline/templates/` that the user copies into NLM. Templates produce markdown output with section headers that match the vault schema, minimizing post-processing.

**Dual sentinel marker:** Every template instructs NLM to include **two** machine-readable markers in the first 5 lines of output — an HTML comment and a plain-text line:
```
<!-- crumb:nlm-export v1 template:book-digest-v1 -->
crumb:nlm-export v1 template:book-digest-v1
```
The dual approach is insurance: Chrome extensions may strip HTML comments during export. The inbox-processor accepts **either** marker for detection. Both encode the pipeline version and the template name + version.

**Template versioning:** Template names include a version suffix: `book-digest-v1`, `source-digest-v1`. When a template is revised, the version increments. The sentinel marker in output always reflects the template version used. The inbox-processor parser maintains compatibility with all known template versions.

**v1 templates** (digest and extract only — concept-map, argument-map, data-table planned for v2):
1. **book-digest-v1** — full book summary (thesis, arguments, concepts, quotes, takeaways)
2. **source-digest-v1** — generic version for articles, papers, etc.
3. **concept-extract-v1** — pull specific concepts/ideas from a source
4. **argument-map-v1** — map the logical structure of arguments in a source
5. **comparison-v1** — compare/contrast multiple sources on a topic

Templates 3-5 all produce `extract` note_type output. Additional note_types (concept-map, argument-map, data-table) are planned for v2 with dedicated body templates.

Each template includes:
- The NLM prompt text (including sentinel marker instruction)
- Expected output structure
- Post-processing notes (what the processor will add/transform)
- Version history (what changed from prior versions)

**Template lifecycle:** Templates live in `Projects/notebooklm-pipeline/templates/` during development and validation. Once validated through end-to-end testing (NLM-005), they are **promoted** to a durable location outside the project — `_system/docs/templates/notebooklm/` — since they are the primary reusable artifact and must survive project archival. Promotion is a direct move (not symlinks — per vault-wide symlink prohibition). Post-promotion, template updates happen at the durable path. The project directory retains only a reference note pointing to the promoted location.

### D4: Processing Pipeline

**Decision:** Extend `inbox-processor` with NLM-aware classification rather than building a separate skill.

**Detection:** The inbox-processor identifies NLM exports by the **dual sentinel marker** — either the HTML comment (`<!-- crumb:nlm-export ... -->`) or the plain-text line (`crumb:nlm-export v1 template:...`) in the first 5 lines. This is a deterministic signal — no heuristic guessing. Files without a sentinel are processed through the standard inbox-processor path and never auto-classified as NLM exports. If the user brings in NLM content that wasn't generated with a template (e.g., manual copy-paste), they can add the sentinel manually or the processor falls back to asking "Is this a NotebookLM export?" during intake.

**Processing steps** (when sentinel detected):
1. Parse template version from sentinel marker
2. Parse content using version-appropriate rules (template-aware section headers)
3. Generate `knowledge-note` frontmatter — infer `source_id`, `source_type`, `note_type`, and `#kb/` tags from content
4. Check for existing notes with same `source_id` + `note_type` + `scope` (deduplication)
5. Prompt user to confirm/adjust: source metadata, domain, `#kb/` tags, connections
6. Apply quality gate: auto-tag `needs_review` for podcast/video/audio source types
7. Route to `Sources/[source_type]/` with kebab-case filename
8. Suggest Obsidian links to related existing notes (via `#kb/` tag overlap and title similarity)

**Fallback path:** If the Chrome extension breaks, is unavailable, or produces unparseable output, the user can manually copy-paste NLM output into a markdown file, add the sentinel marker at the top, and drop it in `_inbox/`. The pipeline handles it identically. This ensures the pipeline degrades gracefully to copy-paste rather than becoming unusable.

**Filename convention:** `[source-id].md` for whole-source digests, `[source-id]--[note-type]--[scope-slug].md` for scoped extracts (e.g., `kahneman-thinking-fast--extract--ch-03.md`).

### D5: Cross-Domain Discovery

**Decision:** Physical storage is always `Sources/[source_type]/` — the `domain:` field does **not** drive physical routing. Cross-domain discovery relies on:
1. `#kb/` tags — **mandatory** on all knowledge-notes (at least one required; multiple encouraged for cross-domain sources). This is the primary cross-domain discovery mechanism.
2. `domain:` frontmatter field — records the single primary domain. Used for future MOC generation, domain-summary backlinks, and vault-check validation. Does **not** affect where the file is stored.
3. `## Connections` section with `[[wikilinks]]` to related notes — populated during intake (user confirms suggestions)
4. Future MOC (Map of Content) notes per `#kb/` topic that aggregate all knowledge-notes for that topic

## Task Decomposition

### NLM-001: Define knowledge-note schema and extend type taxonomy
- Add `knowledge-note` to `docs/file-conventions.md` type taxonomy table
- Define the full frontmatter schema (source block, note_type enum)
- Define body templates for each note_type
- Update `vault-check.sh` if needed to validate new type
- **Risk:** Low
- **Tags:** `#writing`, `#decision`
- **Acceptance criteria:** Schema documented, vault-check passes with new type, file-conventions.md updated
- **Depends on:** None

### NLM-002: Create Sources/ directory structure
- Create `Sources/` top-level with subdirectories: `books/`, `articles/`, `podcasts/`, `videos/`, `courses/`, `papers/`
- Add a `Sources/sources-overview.md` domain summary
- **Risk:** Low
- **Tags:** `#writing`
- **Acceptance criteria:** Directory exists, overview file has valid frontmatter, gitignore/vault-check don't flag it
- **Depends on:** NLM-001

### NLM-003: Build query template library and verify export path
- **Phase 1 — Export verification (blocking for NLM-004):** Install and test Chrome extension(s) with real NLM notebooks. Export golden fixtures covering the minimum diversity matrix: at least 1 book, 1 article, 1 podcast/video, 1 "messy" export (tables/mixed formatting), 1 very short output. Commit fixtures to `Projects/notebooklm-pipeline/fixtures/`. Document exact markdown structure produced by the extension. If extensions are broken/unavailable, validate the manual copy-paste fallback path with the same fixture diversity.
- **Phase 2 — Template authoring:** Write 4-5 versioned NLM query templates that produce Crumb-structured output with sentinel markers. Store in `Projects/notebooklm-pipeline/templates/`. Include usage instructions for each.
- **Phase 3 — Template validation:** Run each template against at least 2 real NLM notebooks. Export results and compare against expected output structure. Commit validated exports as additional fixtures.
- **Risk:** Medium (template effectiveness depends on NLM behavior; extension availability unverified)
- **Tags:** `#writing`, `#research`
- **Acceptance criteria:** (1) Chrome extension tested and golden fixtures committed OR fallback path validated; (2) Templates produce output with sentinel markers and section headers matching schema; (3) Validated exports committed as fixtures; (4) Export markdown structure documented
- **Depends on:** NLM-001 (needs schema to target)

### NLM-004: Extend inbox-processor for NLM exports
- Add sentinel-marker-based NLM detection to inbox-processor (no heuristic guessing)
- Implement version-aware template parsing for each note_type
- Add `source_id` generation and deduplication check
- Add `Sources/` routing logic using source_type → folder mapping
- Add `needs_review` auto-tagging for low-citation source types
- Add `#kb/` tag suggestion based on content analysis
- Add connection suggestion (search existing notes for related content via tag overlap)
- **Risk:** Medium
- **Tags:** `#code`
- **Acceptance criteria:** Given the golden fixture exports from NLM-003: (1) sentinel marker detected and parsed correctly; (2) frontmatter generated with valid `source_id`, `source_type`, `note_type`, `scope`; (3) routed to correct `Sources/[type]/` folder; (4) `needs_review` tagged for podcast/video sources; (5) vault-check passes on all generated notes; (6) deduplication check fires when re-processing an existing source
- **Depends on:** NLM-001, NLM-002, NLM-003 (specifically: NLM-003 Phase 1 golden fixtures must exist before parser design begins)

### NLM-005: End-to-end pipeline test
- Process 3-5 real NLM exports through the full pipeline (mix of source types including at least one podcast/video)
- Validate: sentinel detection, frontmatter correctness, `source_id` generation, deduplication behavior, routing to correct `Sources/` subfolder, `#kb/` tag accuracy, `needs_review` tagging, connection suggestions
- Test the copy-paste fallback path (no Chrome extension) with at least one export
- Iterate on templates and processing based on results
- **Risk:** Low
- **Tags:** `#research`
- **Acceptance criteria:** (1) All test exports process correctly with valid frontmatter; (2) vault-check passes on all generated notes; (3) Duplicate detection works when re-processing same source; (4) Fallback path produces same quality output; (5) User satisfied with output quality and friction level
- **Depends on:** NLM-004

### NLM-006: Documentation and workflow guide
- Write a user-facing workflow guide: how to use templates in NLM, export, process in Crumb
- Update `Domains/Learning/learning-overview.md` to reference Sources/ and the pipeline
- **Risk:** Low
- **Tags:** `#writing`
- **Acceptance criteria:** Guide is clear enough to follow without Crumb assistance; learning overview updated
- **Depends on:** NLM-005

### NLM-007: Promote templates to durable location
- Move validated templates from `Projects/notebooklm-pipeline/templates/` to `_system/docs/templates/notebooklm/`
- Leave a reference note in the project pointing to the promoted location (no symlinks)
- Update any references (workflow guide, inbox-processor) to point to the durable path
- **Risk:** Low
- **Tags:** `#writing`
- **Acceptance criteria:** Templates live at `_system/docs/templates/notebooklm/`, reference note in project, no broken references
- **Depends on:** NLM-005, NLM-006
