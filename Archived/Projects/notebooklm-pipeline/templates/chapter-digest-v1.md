---
project: notebooklm-pipeline
domain: learning
type: reference
created: 2026-02-24
updated: 2026-02-24
tags:
  - notebooklm
  - template
---

# Template: chapter-digest-v1

**Purpose:** Chapter-by-chapter breakdown of a non-fiction book. Preserves the structure
of the author's argument as it develops across the book. Companion to book-digest-v2
(which gives the whole-book view).
**note_type:** digest
**source_type:** book
**scope:** `chapter:<n>` (individual chapter) or `chapter:all` (full breakdown — batch only)

## Recommended Approach

**Primary — Batch (all chapters in one query):**
Use the Batch Prompt below for most books. NLM handles even very long books (390k+ words,
30+ chapters) without truncation. Produces a single note with `scope: chapter:all` —
shallower per chapter (bullet-point key points, 2 quotes each) but gives you the full
arc in one document. This is what you usually want.

**Deep dive — Individual chapter queries:**
Use the Individual Chapter Prompt when you need more depth on specific chapters. Produces
one note per chapter with `scope: chapter:<n>` — paragraph-level key points, more quotes,
fuller analysis. Use selectively after reading the batch output to identify chapters worth
expanding.

## Individual Chapter Prompt (Deep Dive)

Copy and paste the following into NotebookLM, replacing `[N]` with the chapter number
and `[TITLE]` with the chapter title:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content. Do not skip them, even for long chapters.

Please provide a detailed digest of Chapter [N]: [TITLE]. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=chapter-digest-v1 note_type=digest source_type=book scope=chapter:[N] -->
crumb:nlm-export v=1 template=chapter-digest-v1 note_type=digest source_type=book scope=chapter:[N]
```

Then structure your response with these exact headings:

## Chapter [N]: [TITLE]

### Summary
Provide a 2-3 paragraph summary of this chapter's argument. What does it build on from
prior chapters? What does it set up for subsequent chapters? What is its specific
contribution to the book's overall thesis?

### Key Points
Present the chapter's main claims with supporting evidence. Each claim gets its own
paragraph with the reasoning and evidence the author provides.

### Notable Quotes
Include 2-3 significant quotes from this chapter with page references. Format as
blockquotes with attribution.

### Checklists & Procedures
If this chapter contains step-by-step procedures, checklists, or decision frameworks,
reproduce them using markdown checkbox syntax (- [ ]) and numbered lists. If none,
write "Not applicable."

### Tables & Structured Data
If this chapter contains tables, matrices, or taxonomies, reproduce as markdown tables.
If none, write "Not applicable."

**Important:** If this response ends mid-section because the output was truncated, stop where you are. The user will re-run with: "Continue from [last complete heading]" and concatenate the outputs.

---

## Batch Prompt (Primary)

Use this for most books — NLM handles even very long books (30+ chapters) without truncation:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content.

Please provide a chapter-by-chapter digest of this entire book. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=chapter-digest-v1 note_type=digest source_type=book scope=chapter:all -->
crumb:nlm-export v=1 template=chapter-digest-v1 note_type=digest source_type=book scope=chapter:all
```

For each chapter, use an H3 heading and include:

### Chapter N: [Title]

**Summary** — 2-3 paragraph summary of the chapter's argument, what it builds on from prior chapters, and what it sets up.

**Key Points** — the chapter's main claims with evidence.

**Notable Quotes** — 2-3 per chapter with page references, as blockquotes.

**Checklists & Procedures** — if present in this chapter, reproduce using checkbox syntax. If none, skip.

**Tables & Structured Data** — if present, reproduce as markdown tables. If none, skip.

After all chapters, include these two synthesis sections:

## Argument Arc
How does the book's argument develop across chapters? Which chapters are foundational vs. which apply or extend? Are there structural patterns (e.g., theory→evidence→application)?

## Cross-Chapter Connections
What themes or concepts recur across multiple chapters? How does the author build, revisit, or complicate ideas as the book progresses?

**Important:** If this response ends mid-section because the output was truncated, stop where you are. The user will re-run with: "Continue from [last complete heading]" and concatenate the outputs.

---

## Expected Output Structure

**Individual chapter query — required headings:**
1. `## Chapter N: [Title]`
2. `### Summary`
3. `### Key Points`

**Individual chapter query — optional headings:**
- `### Notable Quotes`
- `### Checklists & Procedures`
- `### Tables & Structured Data`

**Batch query — chapter headings:**
- `### Chapter N: [Title]` (H3, not H2)
- Sub-sections use `**bold**` labels (not `###` sub-headings)

**Batch query — synthesis headings (after all chapters):**
- `## Argument Arc`
- `## Cross-Chapter Connections`

**Heading structure note:** Batch and individual queries produce different heading
levels. Batch uses `###` for chapters with `**bold**` sub-sections; individual uses
`##` for chapters with `###` sub-sections. Parser must handle both patterns.

**Content formats:**
- Key Points: full paragraphs (individual) or bullet points (batch)
- Quotes: `>` blockquote syntax
- Checklists: `- [ ]` checkbox syntax
- Tables: standard markdown table syntax

## Post-Processing Notes

- Individual chapter notes: `source_id` includes scope in filename
  (e.g., `rawls-theory-justice-digest-chapter-03.md`)
- Batch notes: single file with `scope: chapter:all`
  (e.g., `rawls-theory-justice-digest-chapter-all.md`)
- Inbox-processor adds YAML frontmatter with `scope` from sentinel
- Checklists, tables, and blockquotes are preserved as-is

## Truncation Recovery

NLM runs on Gemini's 1M-token context window (~750k words output capacity). In practice,
truncation has not been observed even for 390k-word books with 30+ chapters. These
instructions are insurance for edge cases:
- **Batch approach:** Note the last complete chapter, re-run with "Continue from Chapter [N+1]",
  concatenate, ensure single sentinel at top.
- **Individual approach:** Simply re-run the truncated chapter query.

## Version History

- **v1** (2026-02-24): Initial version — batch as primary workflow, individual for deep dives. Validated against Wealth of Nations (30+ chapters, 390k words).
