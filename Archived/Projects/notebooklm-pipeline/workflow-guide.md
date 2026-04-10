---
project: notebooklm-pipeline
domain: learning
type: reference
created: 2026-02-20
updated: 2026-02-24
tags:
  - notebooklm
  - pipeline
  - workflow
---

# NotebookLM Pipeline — Workflow Guide

Turn NotebookLM queries into indexed knowledge notes in the Crumb vault.

## Setup

1. **Chrome extension:** Install "NotebookLM to LaTeX & MD" from the Chrome Web Store.
   This is the preferred export path — produces markdown with metadata.
2. **Templates:** Available at `_system/docs/templates/notebooklm/`. Each template
   contains a prompt to copy into NLM and expected output structure.
3. **Sentinel:** Templates instruct NLM to emit a machine-readable sentinel marker.
   The inbox-processor detects this automatically.

## Workflow

### 1. Choose a Template

| Goal | Template | Depth |
|---|---|---|
| Quick book summary | `book-digest-v1` | light |
| Thorough book summary | `book-digest-v2` | deep |
| Quick article/paper/podcast/video digest | `source-digest-v1` | light |
| Thorough source digest | `source-digest-v2` | deep |
| Chapter-by-chapter book breakdown | `chapter-digest-v1` | deep |
| Fiction — themes, ideas, language | `fiction-digest-v1` | deep |
| Extract concepts on a specific topic | `concept-extract-v1` | — |
| Map argument structure | `argument-map-v1` | — |
| Compare multiple sources | `comparison-v1` | — |

**v1 vs v2:** Use v1 for quick captures (the gist). Use v2 when you want enough detail
to reconstruct the author's argument months later. v2 templates may hit NLM output
limits for dense sources — truncation recovery instructions are included in each template.

### 2. Run in NotebookLM

1. Open (or create) a NotebookLM notebook with your source material
2. **Clear chat history** if you've previously run a different template in this notebook.
   NLM carries prior output patterns into subsequent queries — running book-digest-v2
   then chapter-digest-v1 without clearing will contaminate the chapter output with
   book-digest headings.
3. Open the template file and copy the **NLM Prompt** section
4. Replace any `[TOPIC]` or `[N]`/`[TITLE]` placeholders with your specifics
5. Paste into the NLM chat and send

### 3. Export

**Preferred — Chrome extension:**
1. Click the extension icon after NLM generates a response
2. Export as Markdown
3. The extension adds its own frontmatter and metadata — the inbox-processor strips these

**Fallback — copy-paste:**
1. Copy NLM's response (use the copy button if available)
2. Create a new `.md` file
3. The sentinel should be in the first few lines — verify it's present
4. If missing, add it manually at the top (copy from the template)

### 4. Drop in Inbox

Save/move the `.md` file to `_inbox/` in the vault.

### 5. Process

Tell Claude to process inbox. The inbox-processor will:
- Detect the sentinel marker
- Parse template, note_type, source_type
- Prompt you for: author, title, source_id confirmation, `#kb/` tags, domain
- Generate knowledge-note frontmatter
- Route to `Sources/[type]/` (e.g., `Sources/books/`)
- Run dedup check and quality gate

## Batch Strategy

- **Start with digests** — one query per source, highest information density
- **Add extracts by priority** — concept extracts for topics you're actively working on
- **NLM limit awareness** — approximately 50 queries/day is practical; pace accordingly
- **Batch processing** — drop multiple exports in `_inbox/` and process them all at once

## Directory Structure

```
Sources/
├── books/          # book digests and extracts
├── articles/       # article digests and extracts
├── podcasts/       # podcast digests and extracts
├── videos/         # video digests and extracts
├── courses/        # course digests and extracts
├── papers/         # academic paper digests and extracts
└── other/          # anything that doesn't fit above
```

## Troubleshooting

**Sentinel not detected:**
- Check that the sentinel appears in the first 20 lines (parser scans this window)
- NLM sometimes wraps it in code fences (`` ``` ``) — the parser handles this
- Chrome extension adds frontmatter above the sentinel — the parser handles this
- For very long sources (390k+ words), NLM may drop the sentinel entirely despite
  the reinforced instruction. The parser has a heading-pattern fallback that infers
  the template from section headings — these are auto-tagged `needs_review`
- If both sentinel and heading patterns fail, the processor will prompt you manually

**Context contamination:**
- When switching templates in the same NLM notebook (e.g., book-digest then chapter-digest),
  NLM may produce headings from the previous template. Clear chat history between template switches.

**Wrong source_type routing:**
- The sentinel's `source_type` field drives routing
- If NLM didn't include it, the processor infers from the template name
- Override during the prompting step if needed

**Duplicate source:**
- The dedup check searches `Sources/` for matching `source_id` + `note_type` + `scope`
- Options: update in-place, create a new version, or skip

**Quality gate tag:**
- Podcast and video sources auto-get `needs_review` — these are lower-citation sources
- Remove the tag after you've reviewed the note's accuracy

**Chrome extension not working:**
- Fall back to copy-paste (the pipeline supports both paths)
- Extension artifacts (frontmatter, Chinese timestamps, citation sections) are all stripped
  by the parser — don't try to clean them manually
