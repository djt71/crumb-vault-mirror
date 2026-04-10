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

# Template: book-digest-v2

**Purpose:** Deep book summary — paragraph-level arguments, expanded concepts with examples,
generous quotes, procedural content preservation. Designed for second-brain recall of books
read months or years ago.
**note_type:** digest
**source_type:** book
**scope:** whole

## Prompt

Copy and paste the following into NotebookLM with your book selected as the active source:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content.

Please provide a deep, comprehensive digest of this book. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=book-digest-v2 note_type=digest source_type=book -->
crumb:nlm-export v=1 template=book-digest-v2 note_type=digest source_type=book
```

Then begin with a top-level heading:

# [Book Title] by [Author]

Then structure your response with these exact headings:

## Core Thesis
The book's central argument in a full paragraph. What problem is the author addressing, why does it matter, and what is their framework?

## Key Arguments
Each major argument as a separate paragraph. State the claim, the evidence, and how it connects to the thesis.

## Key Concepts & Frameworks
The most important concepts. Format each as:
- **Concept Name** — What it means, how the author uses it, and a concrete example from the text.

## Notable Quotes
8-12 significant quotes with page/location references. Prioritize quotes that capture the author's voice or crystallize key arguments. Format as blockquotes.

## Checklists & Procedures
If the book contains procedures, checklists, or decision frameworks, reproduce using checkbox syntax (- [ ]) and numbered lists. If none, write "Not applicable."

## Tables & Structured Data
If the book contains tables, matrices, or taxonomies, reproduce as markdown tables. If none, write "Not applicable."

## Takeaways & Applications
Concrete applications: who benefits, in what situation, what would they do differently?

## Uncertain / Needs Verification
Flag unsupported or weakly evidenced claims. If none, write "None identified."

## Connections
Connections to other books, ideas, or fields.

**Important:** If this response ends mid-section due to truncation, stop where you are. The user will re-run with: "Continue from [last complete heading]" and concatenate.

---

## Expected Output Structure

**Top-level heading:**
- `# [Book Title] by [Author]`

**Required headings (in order):**
1. `## Core Thesis`
2. `## Key Arguments`
3. `## Key Concepts & Frameworks`

**Optional headings (parser handles gracefully):**
- `## Notable Quotes`
- `## Checklists & Procedures`
- `## Tables & Structured Data`
- `## Takeaways & Applications`
- `## Uncertain / Needs Verification`
- `## Connections`

**Content formats:**
- Arguments: full paragraphs (not bullets)
- Concepts: bullet points with `**bold**` for terms, followed by usage + example
- Quotes: `>` blockquote syntax with page/location attribution
- Checklists: `- [ ]` checkbox syntax
- Procedures: numbered lists
- Tables: standard markdown table syntax

## Post-Processing Notes

- Inbox-processor adds YAML frontmatter (source block, tags, schema_version)
- `## Connections` entries matched against vault notes for wikilink suggestions
- Checklists, tables, and blockquotes are preserved as-is (no reformatting)

## Truncation Recovery

If NLM truncates the response:
1. Note the last complete heading
2. Re-run: "Continue from [heading]. Begin with `## [heading]` and continue."
3. Concatenate after the truncation point
4. Sentinel appears only once (at the top)

## Version History

- **v1** (2026-02-20): Initial version — bullet-level depth, 3-5 quotes
- **v2** (2026-02-24): Paragraph-level arguments, expanded concepts with examples, 8-12 quotes, new Checklists & Procedures and Tables & Structured Data sections, truncation recovery instructions
