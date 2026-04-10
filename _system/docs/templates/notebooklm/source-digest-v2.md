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

# Template: source-digest-v2

**Purpose:** Deep general-purpose digest for articles, papers, podcasts, videos, courses.
Paragraph-level depth with procedural content preservation.
**note_type:** digest
**source_type:** article | paper | podcast | video | course | other
**scope:** whole

## Prompt

Copy and paste the following into NotebookLM with your source selected as the active source:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content.

Please provide a deep, comprehensive digest of this source. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=source-digest-v2 note_type=digest -->
crumb:nlm-export v=1 template=source-digest-v2 note_type=digest
```

Then begin with a top-level heading:

# [Title] by [Author/Creator]

Then structure your response with these exact headings:

## Core Thesis
The source's central argument in a full paragraph. What problem or question does it address, why does it matter, and what is the author's approach?

## Key Arguments
Each major argument or claim as a separate paragraph. State the claim, the evidence, and how it connects to the thesis.

## Key Concepts & Frameworks
The most important concepts. Format each as:
- **Concept Name** — What it means, how it's used in this source, and a concrete example from the text.

## Notable Quotes
5-8 significant quotes or key passages. For written sources, include page references. For audio/video, include timestamps (e.g., [12:34]). Format as blockquotes.

## Checklists & Procedures
If the source contains procedures, checklists, or decision frameworks, reproduce using checkbox syntax (- [ ]) and numbered lists. If none, write "Not applicable."

## Tables & Structured Data
If the source contains tables, matrices, or taxonomies, reproduce as markdown tables. If none, write "Not applicable."

## Takeaways & Applications
Concrete applications: who benefits, in what situation, what would they do differently?

## Uncertain / Needs Verification
Flag unsupported or weakly evidenced claims. If none, write "None identified."

## Connections
Connections to other sources, ideas, or fields.

**Important:** If this response ends mid-section due to truncation, stop where you are. The user will re-run with: "Continue from [last complete heading]" and concatenate.

---

## Expected Output Structure

**Top-level heading:**
- `# [Title] by [Author/Creator]`

**Required headings (in order):**
1. `## Core Thesis`
2. `## Key Arguments`
3. `## Key Concepts & Frameworks`

**Optional headings:**
- `## Notable Quotes`
- `## Checklists & Procedures`
- `## Tables & Structured Data`
- `## Takeaways & Applications`
- `## Uncertain / Needs Verification`
- `## Connections`

**Content formats:**
- Arguments: full paragraphs (not bullets)
- Concepts: bullet points with `**bold**` for terms
- Quotes: `>` blockquote syntax; timestamps `[HH:MM]` for audio/video
- Checklists: `- [ ]` checkbox syntax
- Tables: standard markdown table syntax

**Note:** `source_type` is NOT embedded in the sentinel for this generic template.
The inbox-processor infers it from context or prompts the user.

## Post-Processing Notes

- Inbox-processor prompts user for `source_type` since this template is generic
- For podcast/video sources, `needs_review` tag is auto-applied
- Checklists, tables, and blockquotes are preserved as-is (no reformatting)

## Truncation Recovery

If NLM truncates the response:
1. Note the last complete heading
2. Re-run: "Continue from [heading]. Begin with `## [heading]` and continue."
3. Concatenate after the truncation point
4. Sentinel appears only once (at the top)

## Version History

- **v1** (2026-02-20): Initial version — bullet-level depth, 2-3 quotes
- **v2** (2026-02-24): Paragraph-level arguments, expanded concepts with examples, 5-8 quotes with timestamps for audio/video, new Checklists & Procedures and Tables & Structured Data sections, truncation recovery instructions
