---
type: how-to
status: active
domain: software
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# How to Add Knowledge to the Vault

**Problem:** You have content (a book, article, podcast, or other source) that should become part of the vault's knowledge base. You need to get it in with proper tagging, MOC registration, and vault-check compliance.

**Architecture source:** [[vault-structure-reference]] §Sources, [[05-cross-cutting-concepts]] §Tag Taxonomy

---

## Method 1: NotebookLM Pipeline (Recommended for Books and Long Sources)

### Step 1: Generate a Digest in NotebookLM

Open a NotebookLM Project Notebook with the source material loaded. Use one of the query templates from `_system/docs/templates/notebooklm/`:

- `book-digest` — full book synthesis
- `chapter-digest` — chapter-level extraction
- `fiction-digest` — fiction-specific (themes, characters, craft)

The templates embed a sentinel marker (`<!-- crumb:nlm-export v1 template:book-digest -->`) that the inbox-processor detects automatically.

### Step 2: Export the Output

Two options:
- **Copy-paste** the NotebookLM output into a markdown file
- **Chrome extension** export (if available)

Both formats are handled by the parser.

### Step 3: Drop into `_inbox/`

Save the file to the vault's `_inbox/` directory.

### Step 4: Run the Inbox Processor

In a Crumb session:

```
process inbox
```

The inbox-processor skill:
1. Detects the sentinel marker
2. Parses the template format
3. Generates frontmatter: `source_id`, `domain`, `type: knowledge-note`, `#kb/` tags
4. Routes to `Sources/<type>/` (books, articles, etc.)
5. Strips the sentinel
6. Applies quality gate logic (e.g., `needs_review` for podcasts/videos)
7. Checks for dedup collisions (by `source_id`)
8. Runs vault-check

### Step 5: Verify

- Knowledge-note exists in `Sources/<type>/` with correct frontmatter
- `#kb/` tag is canonical (Level 2 from the 18 approved tags, or Level 3 subtag)
- `topics` field links to the correct MOC(s)
- MOC entry placed in the Core section
- vault-check passes

---

## Method 2: Manual Knowledge Note Creation

For sources where NotebookLM isn't available or practical.

### Step 1: Create the Note

Create a markdown file in `Sources/<type>/` (books, articles, podcasts, etc.):

```yaml
---
type: knowledge-note
status: active
domain: <domain>
created: 2026-03-14
updated: 2026-03-14
source:
  source_id: <author-surname-short-title>
  title: <full title>
  author: <author name>
  source_type: <book|article|podcast|video|paper|other>
  canonical_url: <URL if available>
  date_ingested: 2026-03-14
tags:
  - kb/<canonical-L2-tag>
topics:
  - <moc-slug>
---
```

**source_id algorithm:** `kebab(author-surname + short-title)`, max 60 chars, `[a-z0-9-]` only.

### Step 2: Write the Content

Structure with clear sections. For NotebookLM-style digests:
- Key concepts / core ideas
- Actionable insights
- Connections to existing vault knowledge
- Source evaluation (reliability, bias, limitations)

### Step 3: Register in MOC

Add a one-liner to the relevant MOC's Core section (between `<!-- CORE:START -->` and `<!-- CORE:END -->` anchors):

```markdown
- [[source-id]] — Brief description (one line)
```

### Step 4: Validate and Commit

Run vault-check (via pre-commit hook). Fix any errors:
- Missing `#kb/` tag → add one
- `topics` field missing → add MOC slug(s)
- `source_id` collision → adjust the slug

---

## Method 3: Feed Pipeline Promotion

For content captured by the feed-intel pipeline (X, RSS, YouTube, HN, arXiv):

1. Items arrive in `_openclaw/inbox/feed-intel-*.md`
2. Run the feed-pipeline skill: `process feed items`
3. High-confidence items auto-promote to `Sources/signals/` as signal-notes
4. Borderline items go to the review queue for manual decision

See [[run-feed-pipeline]] for full details.

---

## Tagging Rules

- Every knowledge note MUST have at least one `#kb/` tag
- Use the 18 canonical Level 2 tags (see [[tag-taxonomy-reference]])
- Level 3 subtags are open: `kb/networking/dns`, `kb/business/pricing`, etc.
- If no canonical tag fits, flag it — don't invent a new Level 2
- Cross-domain content uses dual tagging (e.g., `kb/networking/dns` + `kb/security`)
- Every `#kb/`-tagged note MUST have a `topics` field linking to parent MOC(s)

---

**Done criteria:** Knowledge note in `Sources/` with valid frontmatter, canonical `#kb/` tag, topics field, MOC registration. vault-check passes.
