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

# Template: book-digest-v2

**Purpose:** Deep book summary — paragraph-level arguments, expanded concepts with examples,
generous quotes, procedural content preservation. Designed for second-brain recall of books
read months or years ago.
**note_type:** digest
**source_type:** book
**scope:** whole

## NLM Prompt

Copy and paste the following into NotebookLM as a chat query:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content. Do not skip them, even for long or complex books.

Please provide a deep, comprehensive digest of this book. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=book-digest-v2 note_type=digest source_type=book -->
crumb:nlm-export v=1 template=book-digest-v2 note_type=digest source_type=book
```

Then structure your response with these exact headings:

## Core Thesis
Summarize the book's central argument in a full paragraph. What problem is the author addressing? Why does it matter? What is their overall approach or framework for addressing it? Aim for the level of detail where someone who hasn't read the book could understand the author's project.

## Key Arguments
Present each major argument the author makes as a separate paragraph. For each: state the claim, describe the evidence or reasoning the author presents, and explain how it connects to the central thesis. Aim for the level of detail where you could explain each argument to someone without having read the book.

## Key Concepts & Frameworks
Define the most important concepts introduced or discussed. Format each as:
- **Concept Name** — What it means, how the author uses it, what it enables or explains, and a concrete example from the text.

## Notable Quotes
Include 8-12 significant quotes with page or location references where available. Prioritize quotes that: capture the author's voice, crystallize key arguments, or are independently memorable and worth revisiting. Format as blockquotes with attribution.

## Checklists & Procedures
If the book contains step-by-step procedures, checklists, decision frameworks, or how-to sequences, reproduce them faithfully using markdown checkbox syntax (- [ ]) for checklists and numbered lists for procedures. Preserve the author's structure and ordering. If none present, write "Not applicable — this source does not contain procedural content."

## Tables & Structured Data
If the book contains comparison tables, matrices, taxonomies, classification systems, or other tabular content, reproduce them as markdown tables. Preserve column structure and data faithfully. If none present, write "Not applicable — this source does not contain tabular content."

## Takeaways & Applications
What are the concrete, practical applications of these ideas? For each takeaway: who would benefit, in what situation, and what would they do differently? Avoid generic statements like "this could be useful" — be specific about the application.

## Uncertain / Needs Verification
Flag any claims that seem unsupported, contradicted by other sources, or where the evidence is weak. If none, write "None identified."

## Connections
Suggest connections to other books, ideas, or fields that relate to this book's themes.

**Important:** If this response ends mid-section because the output was truncated, stop where you are. The user will re-run with: "Continue from [last complete heading]" and concatenate the outputs.

---

## Expected Output Structure

The parser uses these headings to extract content sections.

**Required headings (in order):**
1. `## Core Thesis`
2. `## Key Arguments`
3. `## Key Concepts & Frameworks`

**Optional headings (may appear, parser handles gracefully):**
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
- Tables: standard markdown table syntax (`| col | col |`)

## Post-Processing Notes

- Inbox-processor adds YAML frontmatter (source block, tags, schema_version)
- `## Connections` entries are matched against existing vault notes for wikilink suggestions
- Title extracted from the first `# ` heading or inferred from source metadata
- Checklists, tables, and blockquotes are preserved as-is (no reformatting)

## Truncation Recovery

If NLM truncates the response (common for dense books at v2 depth):
1. Note where the output stopped (last complete heading)
2. Re-run in NLM: "Continue from [heading]. Begin your response with `## [heading]` and continue through the remaining sections."
3. Concatenate the continuation after the truncation point
4. Ensure the sentinel appears only once (at the very top)

## Version History

- **v1** (2026-02-20): Initial version — bullet-level depth, 3-5 quotes
- **v2** (2026-02-24): Paragraph-level arguments, expanded concepts with examples, 8-12 quotes, new Checklists & Procedures and Tables & Structured Data sections, truncation recovery instructions
