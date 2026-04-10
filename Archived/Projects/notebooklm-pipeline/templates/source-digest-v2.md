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

# Template: source-digest-v2

**Purpose:** Deep general-purpose digest for articles, papers, podcasts, videos, courses.
Paragraph-level depth with procedural content preservation.
**note_type:** digest
**source_type:** article | paper | podcast | video | course | other
**scope:** whole

## NLM Prompt

Copy and paste the following into NotebookLM as a chat query:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content. Do not skip them, even for long or complex sources.

Please provide a deep, comprehensive digest of this source. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=source-digest-v2 note_type=digest -->
crumb:nlm-export v=1 template=source-digest-v2 note_type=digest
```

Then structure your response with these exact headings:

## Core Thesis
Summarize the source's central argument or main point in a full paragraph. What problem or question does it address? Why does it matter? What is the author's approach?

## Key Arguments
Present each major argument or claim as a separate paragraph. For each: state the claim, describe the evidence or reasoning presented, and explain how it connects to the central thesis.

## Key Concepts & Frameworks
Define the most important concepts. Format each as:
- **Concept Name** — What it means, how it's used in this source, what it enables or explains, and a concrete example from the text.

## Notable Quotes
Include 5-8 significant quotes or key passages. For written sources, include page references where available. For audio/video sources, include timestamps (e.g., [12:34]). Prioritize passages that crystallize key arguments or capture the author's/speaker's voice. Format as blockquotes with attribution.

## Checklists & Procedures
If the source contains step-by-step procedures, checklists, decision frameworks, or how-to sequences, reproduce them faithfully using markdown checkbox syntax (- [ ]) for checklists and numbered lists for procedures. Preserve the original structure and ordering. If none present, write "Not applicable — this source does not contain procedural content."

## Tables & Structured Data
If the source contains comparison tables, matrices, taxonomies, or other tabular content, reproduce them as markdown tables. Preserve column structure and data. If none present, write "Not applicable — this source does not contain tabular content."

## Takeaways & Applications
What are the concrete, practical applications? For each: who would benefit, in what situation, and what would they do differently?

## Uncertain / Needs Verification
Flag any claims that seem unsupported or where the evidence is weak. If none, write "None identified."

## Connections
Suggest connections to other sources, ideas, or fields.

**Important:** If this response ends mid-section because the output was truncated, stop where you are. The user will re-run with: "Continue from [last complete heading]" and concatenate the outputs.

---

## Expected Output Structure

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
- Title extracted from the first `# ` heading or inferred from source metadata
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
