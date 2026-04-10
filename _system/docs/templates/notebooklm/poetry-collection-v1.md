---
project: null
domain: learning
type: reference
status: active
created: 2026-03-03
updated: 2026-03-03
tags:
  - notebooklm
  - template
---

# Template: poetry-collection-v1

**Purpose:** Preserve the full text of poems from a poetry collection, with lightweight
per-poem metadata and collection-level context. This is a *preservation* template, not
a summarization template. The poem is the content — the system's job is to get it into
the vault intact, searchable, and lightly annotated.
**note_type:** collection
**source_type:** book
**scope:** whole

## Design Rationale

Poetry cannot be processed through digest templates. Summarizing a poem destroys the
thing that makes it valuable. The existing templates (book-digest, fiction-digest,
chapter-digest) all extract *about* the source — arguments, themes, concepts. Poetry
requires a fundamentally different approach: extract *the source itself* with enough
metadata to make it useful for search, connection, and retrieval.

This template produces a single vault note per collection containing all poems. Individual
poem extraction (one note per poem) was considered and rejected for most collections —
a Keats complete works would generate hundreds of files. The single-file approach keeps
the vault manageable while making every poem searchable via heading anchors and Obsidian's
outline view.

## Prompt

Copy and paste the following into NotebookLM with your poetry collection selected as the active source:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content.

Please extract every poem from this collection with full text preserved. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=poetry-collection-v1 note_type=collection source_type=book -->
crumb:nlm-export v=1 template=poetry-collection-v1 note_type=collection source_type=book
```

Then provide a metadata block:

```yaml
---
metadata:
  title: "[Collection Title]"
  author: "[Author Name]"
  translator: "[Translator Name, if applicable, else null]"
  year: [publication year]
  tags:
    - kb/poetry
    - [additional kb/ tags based on thematic content]
---
```

Then provide:

# [Collection Title] by [Author]

## Collection Context

2-4 paragraphs: Who is this poet? What period/movement? What is this collection's place
in their body of work? If translated, note the translator and translation approach. If
the collection has an organizing structure (thematic sections, chronological arc, etc.),
describe it briefly. This is orientation, not literary criticism — keep it factual and
concise.

## Poems

Then for EVERY poem in the collection, in the order they appear in the source:

### [Poem Title]

**Page:** [page number or range]
**Form:** [sonnet, free verse, haiku, ode, elegy, etc. — only if identifiable; skip if indeterminate]
**Section:** [collection section/grouping title, if the collection is divided into parts; skip if none]

[Full text of the poem, preserving line breaks, stanza breaks, indentation, and any
typographical features. Use a blank line between stanzas. Preserve the poet's
punctuation, capitalization, and spacing exactly.]

---

Repeat for every poem in the collection. Do NOT skip, summarize, or truncate any poem.
Every poem in the source must appear in the output.

After all poems, include:

## Index

A compact index listing all poems by title:
- [Poem Title 1](#poem-title-1)
- [Poem Title 2](#poem-title-2)
- ...

CRITICAL: This is EXTRACTION, not synthesis. Preserve every poem's exact text —
line breaks, stanza breaks, indentation, punctuation, capitalization.

---

## Expected Output Structure

**Top-level heading:**
- `# [Collection Title] by [Author]`

**Required sections:**
1. `## Collection Context` — orientation paragraph(s)
2. `## Poems` — container heading
3. `### [Poem Title]` — one per poem (H3)
4. `## Index` — navigational list at the end

**Per-poem structure:**
- `**Page:**` — page reference
- `**Form:**` — optional, only if identifiable
- `**Section:**` — optional, only if collection is subdivided
- Full poem text with preserved formatting

## Post-Processing Notes

- Inbox-processor adds YAML frontmatter (source block, tags, schema_version)
- `note_type: collection` (distinct from `digest`)
- `type: collection` in frontmatter (distinct from `knowledge-note`)
- Tags should include `#kb/poetry` plus thematic cross-tags the model identifies
- The `## Collection Context` section may reference other poets or works — match
  against vault notes for wikilink suggestions
- Unlike digest templates, the bulk of this note is preserved source text, not
  model-generated synthesis

## Truncation Recovery

Poetry collections can be very large. If the response ends mid-collection:

1. Note the last complete poem title
2. Re-run: "Continue from [poem title]. Begin with `### [Next Poem Title]` and continue extracting all remaining poems."
3. Concatenate after the last complete poem in the first output
4. Metadata block and sentinel appear only once (at the top)
5. Add the `## Index` section manually after concatenation (or re-request it in the final continuation pass)

## Template → Defaults

| Field | Value |
|---|---|
| note_type | collection |
| source_type | book |
| scope | whole |
| skill_origin | inbox-processor |
| default tag | kb/poetry |

## Version History

- **v1** (2026-03-03): Initial version — full-text preservation for poetry collections
