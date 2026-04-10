---
project: null
domain: learning
type: reference
status: active
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
**scope:** `chapter:all`

## Prompt

Copy and paste the following into NotebookLM with your book selected as the active source:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content.

Please provide a chapter-by-chapter digest of this entire book. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=chapter-digest-v1 note_type=digest source_type=book scope=chapter:all -->
crumb:nlm-export v=1 template=chapter-digest-v1 note_type=digest source_type=book scope=chapter:all
```

Then begin with a top-level heading:

# [Book Title] by [Author]

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

**Important:** If this response ends mid-section due to truncation, stop where you are. The user will re-run with: "Continue from [last complete heading]" and concatenate.

---

## Expected Output Structure

**Top-level heading:**
- `# [Book Title] by [Author]`

**Chapter headings:**
- `### Chapter N: [Title]` (H3)
- Sub-sections use `**bold**` labels (not sub-headings)

**Synthesis headings (after all chapters):**
- `## Argument Arc`
- `## Cross-Chapter Connections`

**Content formats:**
- Key Points: bullet points
- Quotes: `>` blockquote syntax with page references
- Checklists: `- [ ]` checkbox syntax
- Tables: standard markdown table syntax

## Post-Processing Notes

- Produces a single file with `scope: chapter:all`
  (e.g., `rawls-theory-justice-digest-chapter-all.md`)
- Inbox-processor adds YAML frontmatter with `scope` from sentinel
- Checklists, tables, and blockquotes are preserved as-is

## Truncation Recovery

NLM runs on Gemini's 1M-token context window (~750k words output capacity). In practice,
truncation has not been observed even for 390k-word books with 30+ chapters. If it does
occur: note the last complete chapter, re-run with "Continue from Chapter [N+1]",
concatenate, and ensure a single sentinel at top.

## Deep Dive: Individual Chapters

If the batch output flags a chapter worth expanding, you can query a single chapter
for more depth. Use the same prompt structure but replace the sentinel scope with
`scope=chapter:[N]`, use `## Chapter N: [Title]` (H2) as the top heading, and use
`###` sub-headings instead of `**bold**` labels. This produces a separate note with
paragraph-level key points, more quotes, and fuller analysis. Filename convention:
`{source_id}-digest-chapter-{NN}.md`.

## Version History

- **v1** (2026-02-24): Initial version — batch as primary workflow. Validated against Wealth of Nations (30+ chapters, 390k words).
