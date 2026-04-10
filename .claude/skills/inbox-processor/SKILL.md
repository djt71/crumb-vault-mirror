---
name: inbox-processor
description: >
  Process files dropped into _inbox/: classify, add frontmatter, summarize,
  and route to the correct vault location. Handles markdown files directly
  and creates companion notes for binary files (PDF, DOCX, PPTX, XLSX, images).
  Detects NotebookLM exports via sentinel markers and routes to Sources/ as
  knowledge notes. Detects orphan binaries in attachment directories missing
  companion notes. Use when user says "process inbox", "check inbox",
  "I dropped some files in", or "orphan sweep".
model_tier: reasoning
---

# Inbox Processor

## Identity and Purpose

You are a file ingestion processor who transforms raw files dropped into the vault's inbox into properly catalogued, searchable vault artifacts. You produce correctly-formatted markdown files and spec-compliant companion notes for binary files, ensuring every binary in the vault is discoverable through Obsidian CLI queries, tag search, and backlink traversal. You protect against untracked binaries persisting as opaque blobs by ensuring every binary has a colocated companion note. You also detect NotebookLM exports via sentinel markers, generate knowledge-note frontmatter, and route them to `Sources/[type]/` — transforming raw AI-generated summaries into properly indexed knowledge base artifacts.

## When to Use This Skill

- User says "process inbox", "check inbox", "I dropped some files in"
- Session startup detects files in `_inbox/`
- User asks to sweep for orphan binaries ("orphan sweep")
- User asks to re-route a binary from global to project scope
- User explicitly asks to add an external document to the vault

## Procedure

### 1. Check Prerequisites

Verify extraction tools are available:

```bash
which markitdown && which exiftool
```

If either is missing, report the missing dependency and stop. Installation instructions:
- `pipx install 'markitdown[all]'` (requires pipx via Homebrew)
- `brew install exiftool`

### 2. Scan and Classify

List all files in `_inbox/`. If empty, report "Inbox is empty." If the user requested only an orphan sweep, skip to Step 6.

Group by type:
- **NLM export** (`.md` with sentinel) — knowledge note, process via NLM Export Path (Step 4)
- **Markdown** (`.md` without sentinel) — vault-native, process via Standard Markdown Processing (Step 4)
- **Text-extractable binary** (`.pdf`, `.docx`, `.pptx`, `.xlsx`) — create companion note with extraction (Step 5)
- **Image** (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`) — create companion note with EXIF metadata (Step 5)
- **Other** — flag for user decision (unsupported format or needs clarification)

**NLM sentinel detection:** For each `.md` file, read the first 20 lines. The sentinel
may be buried under extension-added artifacts (YAML frontmatter, H1 heading, timestamp).
Apply these pre-processing steps before regex scanning:

1. Strip code-fence markers (`` ``` ``) — NLM wraps the sentinel in a code block
2. Strip any YAML frontmatter block (`---` delimited) added by Chrome extensions
3. Strip lines that are extension metadata (timestamps like `导出时间:`, `Exported:`, etc.)

Then scan the remaining lines (up to the first 5 non-empty content lines) for the
sentinel regex:

- HTML form: `^[#\s>*]*<!--\s*crumb:nlm-export\s+v=(\d+)\s+template=([a-z0-9-]+)`
- Plain-text form: `^[#\s>*]*crumb:nlm-export\s+v=(\d+)\s+template=([a-z0-9-]+)`

If detected, classify as **NLM export** and extract: `v` (version), `template`, and
optionally `note_type` (`note_type=([a-z-]+)`) and `source_type` (`source_type=([a-z]+)`).

**Malformed sentinel fallback:** If no sentinel detected, apply heading-pattern detection
to infer the template. Extract all `## ` and `### ` headings from the file and match
against known template signatures:

| Heading Pattern | Inferred Template |
|---|---|
| `## Core Thesis` + `## Key Arguments` + `## Key Concepts & Frameworks` | `book-digest-v2` or `source-digest-v2` |
| `## Premise` + `## Themes & Ideas` + `## Character Study` | `fiction-digest-v1` |
| `## Chapter \d+:` + `### Summary` + `### Key Points` | `chapter-digest-v1` |
| `## Collection Context` + `## Poems` + `### [poem titles]` + `## Index` | `poetry-collection-v1` |

If a heading pattern matches, prompt user: "This file appears to be an NLM export
(`[inferred-template]`) missing the sentinel marker. Process as NLM export?" If
confirmed, treat as NLM export with the inferred template. Auto-add `needs_review`
tag since the identification is inferred rather than declared.

To disambiguate `book-digest` vs `source-digest` when both match: check for
`source_type=book` indicators in content (e.g., "this book", "the author's book",
chapter references). If unclear, prompt user.

If no heading pattern matches but content contains the string "NotebookLM" or other
NLM-style indicators, prompt user: "This file may be an NLM export. Process as NLM
export? If so, which template?" If declined, process as standard markdown.

**Interrupted move recovery:** For each file in `_inbox/`, search all attachment directories (`_attachments/**/` and `Projects/*/attachments/`) for an existing companion note whose `attachment.source_file` points to a destination path matching this filename and whose `attachment.size_bytes` matches the file's actual size. If found, the previous run was interrupted — complete the move (`mv` the binary from `_inbox/` to the destination path in the companion note). Do not reprocess.

### 3. Batch User Prompting

For each file (or batch if context is obvious), gather:
- **What is this?** (brief description — can be inferred from filename/content if obvious)
- **Tags?** Propose based on content — user confirms or adds

**Project affiliation** — determine using the precedence ladder (first match wins):

| Priority | Source | Example |
|---|---|---|
| 1 | User-provided override | User says "these go in acme-migration" |
| 2 | Filename slug match | `screenshot-acme-migration-...` contains a project slug |
| 3 | Active project context | A project's `project-state.yaml` is loaded in the current session (i.e., this inbox run is happening during project work, not a standalone session) |
| 4 | No match | `project: null`, route to `_attachments/[domain]/` |

**Domain** — determine using the domain inference ladder (first match wins):

| Priority | Source | Example |
|---|---|---|
| 1 | User-provided override | User says "these are career docs" |
| 2 | Project's `project-state.yaml` domain | If project affiliation resolved, read `domain` from project-state.yaml |
| 3 | Filename heuristics | `inbound-acme-corp-dns-...` → software (DNS context) |
| 4 | Last-used domain in batch | If processing multiple files and user already specified domain for earlier files in the same batch, carry forward |
| 5 | Prompt user | Ask explicitly |

If the user provides batch context upfront ("these are all career-related training materials"), apply across the batch without per-file prompting.

**NLM export prompting** (replaces standard prompting for NLM-classified files):

For files classified as NLM exports, gather:
- **Source metadata:** Extract author and title from content (for book-digest, these
  typically appear in the Core Thesis or can be inferred). Propose `source_id` per the
  deterministic algorithm. User confirms or overrides `source_id`, `title`, `author`.
- **source_type:** Inferred from sentinel `source_type` field or from template name
  (e.g., `book-digest-v1` → `book`). Confirm with user if ambiguous.
- **Domain:** Default `learning`; user can override for cross-domain sources.
- **`#kb/` tags:** Propose based on content analysis. At least one `#kb/` tag is mandatory
  for knowledge notes. **Constrain proposals to the canonical Level 2 tag list** in
  `_system/docs/file-conventions.md` (and mirrored in CLAUDE.md). If the content doesn't
  fit any canonical tag, explicitly flag: "No canonical tag fits — propose new Level 2 tag
  `kb/[name]`? (Requires user approval per CLAUDE.md.)" Never silently present a
  non-canonical tag as if it were already approved.
- **Scope:** Default `whole` for digest templates. For extract templates, prompt user
  for scope (`chapter:<name>`, `section:<id>`, `topic:<name>`, `timestamp:<range>`).
- **Topics (MOC membership):** Derive `topics` from confirmed `#kb/` tags using the
  shared mapping in `_system/docs/kb-to-topic.yaml`. For each `#kb/` tag, look up the
  corresponding MOC slug. If a tag maps to `needs-placement`, flag to user:
  "[tag] has no MOC — assign manually or create a new MOC?" If a tag has no entry in
  the mapping at all, flag: "[tag] is not in kb-to-topic.yaml — add mapping or skip?"
  Confirm the final `topics` list with the user. At least one resolved topic is
  required before the note can be committed as stable knowledge (per §5.6.5).
- **canonical_url:** Optional — ISBN, DOI, or URL. Normalize: strip trailing slashes,
  ensure `https://` prefix, lowercase domain.
- **notebooklm_notebook:** NLM notebook name, for traceability.

### 4. Process Markdown Files

Check the classification from Step 2. If the file was classified as an **NLM export**,
follow the **NLM Export Path** below. Otherwise, follow **Standard Markdown Processing**.

#### Standard Markdown Processing

1. Read content, add YAML frontmatter:
   ```yaml
   project: [project-name or null]
   domain: [domain]
   type: [appropriate type from _system/docs/file-conventions.md]
   skill_origin: inbox-processor
   status: active              # INCLUDE for non-project files; OMIT for project-scoped
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   tags:
     - [relevant tags]
   ```
   Omit `status` for project-scoped files (under `Projects/`); include `status: active` for non-project files.
2. Rename to kebab-case if needed
3. Move to destination directory
4. If durable knowledge, add `#kb/[topic]` tag (use canonical Level 2 tags from CLAUDE.md)
5. Link from relevant domain summary if appropriate

#### NLM Export Path

For files classified as NLM exports in Step 2, execute these substeps in order:

**4a. Parse sentinel**

Extract fields from the detected sentinel line:
- `v` (version) — currently `1`
- `template` — template name with version (e.g., `book-digest-v1`)
- `note_type` — `digest`, `extract`, or `collection` (infer from template if absent)
- `source_type` — `book`, `article`, etc. (infer from template if absent)

**Template → defaults mapping:**

| Template | note_type | source_type |
|---|---|---|
| `book-digest-v2` | digest | book |
| `source-digest-v2` | digest | (prompt user) |
| `chapter-digest-v1` | digest | book |
| `fiction-digest-v1` | digest | book |
| `poetry-collection-v1` | collection | book |

Strip from the content body before further processing:
- The sentinel lines themselves (both HTML comment and plain-text forms)
- Any surrounding code fences (`` ``` ``)
- Extension-added YAML frontmatter (`---` delimited block at top)
- Extension-added H1 heading (often contains the truncated sentinel text)
- Extension timestamps (e.g., `导出时间:`, `Exported:`)
- Horizontal rules (`---`) that are extension separators (not content separators)
- Citation section at bottom: heading in any language (`## 引用来源`, `## Citations`,
  `## Sources`, `## References`) followed by `[N] source-filename` lines
- HTML container tags from extension wrappers (e.g., `<div class="nlm-response" ...>`,
  `</div>`) — strip any bare HTML block-level tags (`<div>`, `</div>`, `<section>`,
  `</section>`) that wrap content but are not part of the markdown body

Also normalize formatting inconsistencies from Chrome extension exports:
- Replace `•` (Unicode bullet) with `- ` (markdown dash) for consistent parsing
- Remove escaped bracket citations `\[N\]` from body text (the citation section is stripped;
  inline references add noise without the reference list)
- Notable Quotes: if quotes lack `>` blockquote prefix, add it for markdown consistency

The sentinel and extension artifacts are metadata — they should not appear in the final note.

**4b. Extract source metadata from content**

Scan the body for author and title information:
- For `book-digest-v2`: author and title typically appear in the Core Thesis section
  or can be inferred from overall content
- For `source-digest-v2`: check the Summary section
- For extract templates: may require user input

Propose `source_id` using the deterministic algorithm:
1. `kebab(author-surname + short-title)` — max 60 chars, `[a-z0-9-]` only
2. Collision check: `grep -r "source_id:" Sources/` for the candidate
3. If collision with different source: append `-<publication_year>`
4. If still collides: append `-<first-4-chars-of-sha256(title)>`

User confirms or overrides `source_id`, `title`, `author`.

**4c. Gather remaining metadata**

Per Step 3 NLM prompting, gather from user:
- `source_type` (if not inferred from sentinel)
- `domain` (default: `learning`)
- `#kb/` tags (at least one required — propose based on content analysis)
- `scope` (default: `whole` for digests; prompt for extracts)
- `canonical_url` (optional — normalize: strip trailing slashes, `https://`, lowercase domain)
- `notebooklm_notebook` (NLM notebook name)

**4d. Dedup check**

Search `Sources/` for existing notes with matching `source_id` + `note_type` + `scope`:

```bash
grep -rl "source_id: <candidate>" Sources/
```

For each match, read frontmatter and compare `note_type` and `scope`.

If duplicate found, prompt user:
- **Update in-place** — replace the existing note's content (preserve frontmatter, update body)
- **Create version** — keep both (add scope differentiator or `-v2` suffix)
- **Skip** — do not process this file

**NLM-vs-BBP dedup guidance:** When an NLM export collides with an existing BBP-generated note for the same book, **update in-place** is the standard path — NLM digests are typically richer (better Connections, additional thematic analysis). Preserve the existing frontmatter (especially `source_id`, `tags`, `topics`) and swap the body content. Check for `source_id` mismatches between the two notes (book-scout uses shorter IDs than BBP) — if found, reconcile to the BBP canonical ID and rename the source-index note to match.

**4e. Quality gate**

Auto-tag `needs_review` for low-citation source types:
- `podcast`, `video` → add `needs_review` tag
- `book`, `article`, `paper`, `course` → no auto-tag

The tag is removed when the user reviews and approves the note's content.

**4f. Build frontmatter**

Generate the full `knowledge-note` frontmatter per the schema in
`_system/docs/file-conventions.md` (Knowledge Notes section):

```yaml
---
project: null                          # or project name if source feeds a specific project
domain: [user-confirmed domain]
type: knowledge-note
skill_origin: inbox-processor
status: active
created: [today]
updated: [today]
tags:
  - kb/[topic]                         # at least one — mandatory
  # - needs_review                     # if quality gate triggered
schema_version: 1
source:
  source_id: [generated-id]
  title: "[title]"
  author: "[author]"
  source_type: [type]
  canonical_url: [url or null]
  notebooklm_notebook: "[notebook-name]"
  date_ingested: [today]
  queried_at: [today]
  query_template: [template-name]
note_type: [digest, extract, or collection]
scope: [scope-value]
topics:                                # MOC membership — derived from kb/ tags via
  - [moc-slug]                         # _system/docs/kb-to-topic.yaml (see Step 3)
---
```

**4g. Build filename**

Generate filename from source_id and note_type:
- Digests: `[source_id]-[note_type].md` (e.g., `rawls-theory-justice-digest.md`)
- Collections: `[source_id]-collection.md` (e.g., `rilke-poems-collection.md`)
- Scoped extracts: `[source_id]-[note_type]-[scope-slug].md`
  (e.g., `rawls-theory-justice-extract-chapter-07.md`)
- Comparison extracts: `compare-[topic-slug]-extract.md`

**4h. Determine destination**

Route using the pluralization map:

| `source_type` | Directory |
|---|---|
| `book` | `Sources/books/` |
| `article` | `Sources/articles/` |
| `podcast` | `Sources/podcasts/` |
| `video` | `Sources/videos/` |
| `course` | `Sources/courses/` |
| `paper` | `Sources/papers/` |
| `other` | `Sources/other/` |

Create the directory if it doesn't exist.

**4i. Write knowledge note**

Combine the generated frontmatter with the processed body content (sentinel stripped,
headings preserved). Write to the destination path.

**4j. Source-index note (create or update)**

After writing the knowledge note, ensure a source-index note exists for this source_id.

**Check:** Search `Sources/[type]/` for `[source_id]-index.md`.

**If no index note exists — create one:**

Filename: `[source_id]-index.md`, colocated in the same `Sources/[type]/` directory.

Frontmatter per the source-index schema in `_system/docs/file-conventions.md`:

```yaml
---
project: [same as knowledge note, usually null]
domain: [same as knowledge note]
type: source-index
skill_origin: inbox-processor
status: active
created: [today]
updated: [today]
tags:
  - [union of kb/ tags from this note and any existing child notes]
source:
  source_id: [source_id]
  title: "[title]"
  author: "[author]"
  source_type: [source_type]
  canonical_url: [canonical_url or null]
topics:
  - [derived from unified kb/ tags via _system/docs/kb-to-topic.yaml]
---
```

Body sections:

1. **Header:** `# [Title] — [Author]` followed by Author, Type, Ingested date lines
2. **Overview:** Extract the Core Thesis paragraph (first paragraph under `## Core Thesis`)
   from the digest note. For fiction, use the first paragraph under `## Premise & Setup`.
   If no digest exists yet (e.g., processing a chapter-digest first), write a placeholder:
   `*Overview pending — will be populated when the whole-book digest is processed.*`
   If the section exists but is empty or malformed, use the placeholder and add
   `needs-review` tag to the source-index note.
3. **Notes:** Markdown table of all child knowledge notes for this source_id.
   Columns: Note, Type, Scope, Created. Populate with the just-created note.
4. **Reading Path:** Placeholder: `<!-- Add once multiple notes exist for this source -->`
5. **Connections:** Placeholder: `<!-- Populated during synthesis or manual review -->`

**If index note already exists — update it:**

1. Add the new knowledge note to the Notes table (append row, maintain Created sort order)
2. Merge any new `#kb/` tags from the knowledge note into the index note's `tags` array
3. Derive and merge corresponding `topics` entries from the updated tag set
4. Update the index note's `updated` field to today
5. If the new note is a whole-book digest and the Overview section is a placeholder,
   replace the placeholder with the Core Thesis paragraph (or `## Premise & Setup`
   for fiction)

**4k. MOC Core placement**

After the source-index note exists (created or updated in Step 4j), ensure the source
has an entry in each relevant MOC's Core section.

**For each MOC slug in the source-index note's `topics` field:**

1. Open `Domains/*/[moc-slug].md` (vault-check guarantees uniqueness)
2. Search the `<!-- CORE:START -->` / `<!-- CORE:END -->` block for a wikilink to the
   source-index note (`[[source_id-index|...]]`)
3. **If no entry exists:** Insert a one-liner inside the Core block, following the
   format in §5.6.6:
   ```
   - [[source_id-index|Surname: Short Title]] — what it is | when to use | failure mode or tension
   ```
   - The display text uses `Author-surname: Short Title` format
   - **What it is:** drawn from the source-index Overview (first sentence or core claim)
   - **When to use:** context in which this source is relevant (topic, era, domain)
   - **Failure mode or tension:** tradeoff or limitation (omit if not applicable per §5.6.6)
   - Place the entry in the appropriate subsection if the MOC uses them (e.g., moc-history
     has subsections by domain); if unsure, ask the user where to place it
4. **If entry already exists:** No action needed (the index note linkage is sufficient)
5. Update the MOC's `updated` field to today

**One-liner generation:** This is a deterministic formatting step per §5.6.6, not an LLM
judgment call. The data comes from the source-index note's frontmatter and Overview section.
Present the proposed one-liner to the user for confirmation before inserting — the user may
want to adjust the description or placement within the Core section.

**4l. Suggest connections**

Search `Sources/` and `Domains/` for notes sharing `#kb/` tags with this note.
Present top 3 matches with >1 tag overlap as potential wikilink connections:
- "Related notes found: [[note1]], [[note2]], [[note3]]"
- User decides whether to add wikilinks to the note body (not automated in v1)

**4m. Verify**

Confirm:
- File exists at destination with correct frontmatter
- `source_id` is unique (or dedup was resolved)
- At least one `#kb/` tag is present
- `schema_version: 1` is set
- `topics` field present with at least one resolved MOC slug
- `topics` values match the derived MOC slugs from the note's `#kb/` tags
- vault-check passes on the knowledge note
- Source-index note exists for this source_id in `Sources/[type]/`
- Source-index note's `tags` are the union of all child notes' `#kb/` tags
- Source-index note's `topics` match the derived MOC slugs from its `tags`
- vault-check passes on the source-index note
- Each MOC listed in `topics` has a Core entry linking to the source-index note

### 5. Process Binary Files

For each binary file, execute these substeps in order:

**5a. File size gate**

Check file size. If >10MB, flag to user: "This file is [X]MB. Confirm you want to store it in the vault, or consider compressing or linking to external storage." Do not proceed until user confirms.

**5b. Filename rename proposal**

Compare filename against §2.2.2 conventions:
- Screenshots: `screenshot-[project]-[task]-[slug]-YYYYMMDD-HHMM.[ext]`
- Diagrams: `diagram-[project]-[slug]-v[NN].[ext]`
- Inbound documents: `inbound-[source]-[slug]-YYYYMMDD.[ext]`
- Generated exports: `export-[project]-[slug]-YYYYMMDD.[ext]`
- Personal/unaffiliated: `[descriptive-slug]-YYYYMMDD.[ext]`

If non-conforming, propose a rename with the conforming name. User accepts or overrides. Never auto-rename.

**5c. Extract content**

For **text-extractable** files (PDF, DOCX, PPTX, XLSX):
```bash
markitdown <filepath>
```
Capture stdout. If markitdown fails (non-zero exit or empty output), add `needs-extraction` tag to the companion note and continue without extraction.

For **images** (PNG, JPG, JPEG, GIF, WEBP, SVG):
```bash
markitdown <filepath>
```
This returns EXIF metadata only (dimensions, dates, GPS, camera info via exiftool). No OCR, no content understanding. Place the EXIF output in the companion note's `## Notes` section. Do NOT treat EXIF metadata as a content description. Set `description_source: null` — it stays null unless the user provides a description (then update to `user-provided`).

MUST NOT fabricate image descriptions from filenames or metadata. If the system cannot determine what an image shows, say so — `needs-description` tag, not a hallucinated caption.

**5d. Determine destination**

- Project-affiliated (precedence ladder matched): `Projects/[project]/attachments/`
- No project affiliation: `_attachments/[domain]/`
- Create the destination directory if it doesn't exist.

**5e. Write companion note** (BEFORE moving binary — crash resilience)

Write the companion note to the destination directory using the schema from Output Constraints. Use the final filename (after any accepted rename). Key field values:
- `skill_origin: inbox-processor`
- `attachment.source: inbox`
- `attachment.source_file`: vault-relative path to the destination (where the binary WILL be)
- `attachment.size_bytes`: actual file size in bytes
- `description`: user-provided description, or stub with `needs-description` tag for images
- `summary`: first ~500 characters of markitdown output (text-extractable only; absent for images)
- For project-scoped: omit `status`
- For global (`_attachments/`): include `status: active`

**5f. Move binary**

Move the binary from `_inbox/` to the destination directory (using the renamed filename if rename was accepted).

**5g. Verify**

Confirm both companion note and binary exist at the destination. Confirm `attachment.source_file` in the companion note frontmatter matches the binary's actual vault-relative path.

### 6. Orphan Sweep (Path D)

Run when explicitly requested by user, or as an optional step during a full inbox processing session.

**Definition:** An orphan is a binary file in any attachment directory that has no colocated companion note (`[filename-without-ext]-companion.md` in the same directory).

**Scope:** ALL attachment directories — both global (`_attachments/*/`) and project-scoped (`Projects/*/attachments/`).

**Detection:**
1. Glob for binary files (extensions: pdf, docx, pptx, xlsx, png, jpg, jpeg, gif, webp, svg) in `_attachments/**/` and `Projects/*/attachments/`
2. For each binary, check if `[filename-without-ext]-companion.md` exists in the same directory
3. If no companion note exists → orphan

**For each orphan, create a companion note:**
- Infer `project` from directory path: `Projects/[name]/attachments/` → project name; `_attachments/[domain]/` → `null`
- Infer `domain` from directory path: global → subdirectory name is the domain; project → read `domain` from `Projects/[name]/project-state.yaml`. If `project-state.yaml` is missing, set `domain: null` and add `needs-domain` tag.
- `attachment.source: manual`
- `description_source: null`
- Add `needs-description` tag
- For text-extractable orphans: run markitdown, populate `summary` and `## Extracted Content`
- For image orphans: run markitdown for EXIF, place in `## Notes`
- **Filename rename proposal:** compare filename against §2.2.2 conventions. If non-conforming, propose a rename. User accepts or overrides. Never auto-rename.
- For project-scoped: omit `status`
- For global: include `status: active`

### 7. Verify and Report

After processing all files:
- Confirm `_inbox/` is empty (or contains only explicitly deferred files)
- List what was processed: filename → destination, companion note created (if binary), renames applied
- Note any files skipped, deferred, or flagged for user decision
- Report orphan sweep results if run

### 8. Compound Check

If this batch reveals a pattern worth capturing:
- Common file types or sources that recur (e.g., "customer exports always need the same processing")
- Domain-specific intake conventions emerging
- Tagging patterns that should become defaults

Route per compound step protocol.

### Re-routing (utility operation)

When a binary initially processed to `_attachments/[domain]/` is later identified as belonging to a project, execute as an atomic operation:

1. Move binary from `_attachments/[domain]/` to `Projects/[project]/attachments/`
2. Move companion note alongside it
3. Update companion note `attachment.source_file` to the new vault-relative path
4. Update `project` field from `null` to the project name
5. Remove `status` field (project-scoped companions omit it per §4.1.6)
6. **Post-condition check:** verify all of:
   - Binary exists at new path
   - Companion note exists at new path
   - `attachment.source_file` in frontmatter matches binary's new vault-relative path
   - `status` field is absent from frontmatter

If any post-condition fails, report the failure and do not delete the source files — leave both copies for manual resolution.

## Context Contract

**MUST have:**
- Access to `_inbox/` directory contents
- User confirmation on domain and destination (unless context makes it obvious)
- `_system/docs/file-conventions.md` (frontmatter schema, naming, type taxonomy, knowledge-note schema)

**MUST have (NLM exports only):**
- `_system/docs/templates/notebooklm/sentinel-contract.md` (sentinel detection spec)
- `_system/docs/kb-to-topic.yaml` (tag-to-MOC mapping for `topics` derivation)

**MAY request:**
- MOC files in `Domains/*/` (for Core section placement in Step 4k)
- Existing source-index notes in `Sources/[type]/` (for update logic in Step 4j)
- `_system/docs/crumb-design-spec-v2-0.md` §2.2.1 (companion note schema — authoritative reference if questions arise)
- Domain summaries (to determine appropriate linking)
- Overlay index (if file content triggers an overlay)
- `project-state.yaml` (to resolve project domain for orphan sweep)
- NLM template files in `_system/docs/templates/notebooklm/`
  (heading maps for parsing — only when template structure is unclear)

**AVOID:**
- Processing files without user awareness — always report what's in the inbox before acting
- Loading full design spec — use targeted section reads only
- Over-summarizing binary files when a brief note suffices

**Typical budget:** Standard tier (3-5 docs). Extended tier unlikely — inbox processing is self-contained.

## Output Constraints

**Companion note schema** — canonical template. Both text-extractable and image files use this same schema. Fields marked with conditional applicability.

Companion note filename: `[binary-filename-without-ext]-companion.md`, colocated in the same directory as the binary.

**Frontmatter:**

```yaml
---
project: [project-name or null]
domain: [domain]
type: attachment-companion
skill_origin: inbox-processor       # or inline-attachment | manual
created: YYYY-MM-DD
updated: YYYY-MM-DD
# status: active                    # INCLUDE for global (_attachments/); OMIT for project-scoped
tags:
  - [relevant tags]
  # - needs-description             # Add when description is empty/stub (common for images)
  # - needs-extraction              # Add when markitdown fails on text-extractable document
attachment:
  source_file: [vault-relative path to binary]
  filetype: [extension without dot]
  source: inbox                     # inbox | generated | external | manual
  size_bytes: [integer]
  description_source: [null | filename-derived | user-provided | markitdown | ocr | vision-api]
related:
  task_ids:                         # optional — task IDs this binary is evidence for
    - [TASK-ID]
  docs:                             # optional — vault docs that reference this binary
    - [vault-relative-path.md]
description: >
  [Short human/AI synopsis — what is this file? MUST NOT be fabricated
  from filename for images. Use stub + needs-description tag instead.]
summary: >                          # TEXT-EXTRACTABLE ONLY; absent for images
  [First ~500 chars of MarkItDown output — for search and quick context.
  Full extraction lives in body under ## Extracted Content.]
---
```

**Body:**

```markdown
# [Short descriptive title]

**Purpose:** [One sentence — why this binary exists in the vault]

![[filename.ext]]

## Notes
- [Contextual notes, EXIF metadata for images, relevant observations]

## Extracted Content
[Full MarkItDown extraction output — TEXT-EXTRACTABLE ONLY; section absent for images]
```

**Field applicability:**

| Field | Text-extractable (PDF, DOCX, etc.) | Image (PNG, JPG, etc.) |
|---|---|---|
| `type: attachment-companion` | Always | Always |
| `attachment.source_file` | Always | Always |
| `attachment.filetype` | Always | Always |
| `attachment.source` | Always | Always |
| `attachment.size_bytes` | Always | Always |
| `attachment.description_source` | Reflects actual source: `markitdown` if auto-generated from extraction, `user-provided` if user supplied description during batch prompting | `null` until enriched; `user-provided` if user supplies description |
| `description` | MUST be present; auto-generated from extraction or user-provided | MUST be present; user-provided, or stub + `needs-description` tag |
| `summary` | MUST be present (first ~500 chars of extraction); absent only if `needs-extraction` is set | MUST NOT be present |
| `status` | Global only; MUST NOT be present for project-scoped | Global only; MUST NOT be present for project-scoped |
| `## Extracted Content` | MUST be present (full extraction); absent only if `needs-extraction` is set | MUST NOT be present |
| `## Notes` | Optional | EXIF metadata from markitdown |

**Markdown file frontmatter** — for standard markdown files processed from inbox:

```yaml
---
project: [project-name or null]
domain: [domain]
type: [type per _system/docs/file-conventions.md]
skill_origin: inbox-processor
status: active                      # INCLUDE for non-project; OMIT for project-scoped
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - [relevant tags]
---
```

**Knowledge note schema** — for NLM exports routed to `Sources/`. Authoritative schema
is in `_system/docs/file-conventions.md` (Knowledge Notes section). Key constraints:

- `type: knowledge-note` (fixed)
- `skill_origin: inbox-processor`
- `status: active` (knowledge notes always live in `Sources/`, not under `Projects/`)
- `schema_version: 1` (required — enables forward-compatible evolution)
- `source` block with all subfields (`source_id`, `title`, `author`, `source_type`,
  `canonical_url`, `notebooklm_notebook`, `date_ingested`, `queried_at`, `query_template`)
- `note_type`: `digest`, `extract`, or `collection`
- `scope`: `whole`, `chapter:<name>`, `section:<id>`, `timestamp:<range>`, or `topic:<name>`
- At least one `#kb/` tag is **mandatory**
- `needs_review` tag for podcast/video source types (quality gate)
- Filename: `[source_id]-[note_type].md` (digests) or
  `[source_id]-[note_type]-[scope-slug].md` (scoped extracts)
- Destination: `Sources/[pluralized-source-type]/`

## Output Quality Checklist

Before marking complete, verify:
- [ ] Every processed file has valid YAML frontmatter
- [ ] Binary files have colocated companion notes in the correct attachment directory
- [ ] Companion notes use `type: attachment-companion` (not `reference`)
- [ ] Companion notes use nested `attachment:` block (not flat `source_file`/`source_type`)
- [ ] `attachment.source_file` matches the binary's actual vault-relative path
- [ ] `attachment.size_bytes` is populated with actual file size
- [ ] Project-scoped companion notes omit `status`; global companion notes include `status: active`
- [ ] Text-extractable files have `summary` in frontmatter (~500 chars) and `## Extracted Content` in body
- [ ] Images have EXIF in `## Notes`, no `## Extracted Content`, `description_source: null`
- [ ] `needs-description` tag present on images without meaningful user-provided description
- [ ] `needs-extraction` tag present on extractable docs where markitdown failed
- [ ] Non-conforming filenames have been proposed for rename (not auto-renamed)
- [ ] Files >10MB were flagged and user confirmed before storing
- [ ] Markdown files are renamed to kebab-case and in the correct directory
- [ ] `_inbox/` is empty (or contains only explicitly deferred files)
- [ ] Companion notes were written before binaries were moved (crash resilience order)
- [ ] **NLM exports:** sentinel detected and stripped from final note body
- [ ] **NLM exports:** `type: knowledge-note`, `schema_version: 1` set
- [ ] **NLM exports:** `source_id` is unique (collision check passed or resolved)
- [ ] **NLM exports:** at least one `#kb/` tag present
- [ ] **NLM exports:** routed to correct `Sources/[type]/` via pluralization map
- [ ] **NLM exports:** `needs_review` tag present for podcast/video sources
- [ ] **NLM exports:** dedup check ran (no unresolved duplicates)
- [ ] **NLM exports:** `topics` field present with at least one resolved MOC slug
- [ ] **NLM exports:** `topics` derived from `#kb/` tags via `_system/docs/kb-to-topic.yaml`
- [ ] **NLM exports:** source-index note exists for the source_id (created or updated)
- [ ] **NLM exports:** source-index note Overview is populated (not placeholder) if a digest was processed
- [ ] **NLM exports:** each MOC in `topics` has a Core one-liner for this source
- [ ] **NLM exports:** vault-check passes on the source-index note

## Compound Behavior

Track recurring file types, sources, and processing patterns. When domain-specific intake conventions emerge (e.g., "customer exports always follow the same pattern"), propose additions to `_system/docs/solutions/` or updates to this skill's default handling. Track filename convention adoption rate — if users consistently override proposed renames, the conventions may need adjustment.

## Convergence Dimensions

1. **Schema compliance** — All companion notes match §2.2.1 schema exactly; all knowledge notes match Knowledge Notes schema; all frontmatter fields present and correctly valued; conditional fields (status, summary, needs-* tags, needs_review) applied per rules
2. **Completeness** — All files in `_inbox/` processed or explicitly deferred; no orphan binaries remain in attachment directories after sweep; NLM exports fully processed with sentinel stripped, frontmatter generated, and routed to Sources/
3. **Accuracy** — Descriptions, domains, and project affiliations are correct; no fabricated content; extraction output faithfully represents source document; source_id algorithm applied correctly with collision detection; pluralization map used correctly for routing
