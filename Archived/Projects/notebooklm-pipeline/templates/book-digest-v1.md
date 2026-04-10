---
project: notebooklm-pipeline
domain: learning
type: reference
created: 2026-02-20
updated: 2026-02-20
tags:
  - notebooklm
  - template
---

# Template: book-digest-v1

**Purpose:** Full book summary — thesis, arguments, concepts, quotes, takeaways.
**note_type:** digest
**source_type:** book
**scope:** whole

## NLM Prompt

Copy and paste the following into NotebookLM as a chat query:

---

Please provide a comprehensive digest of this book. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=book-digest-v1 note_type=digest source_type=book -->
crumb:nlm-export v=1 template=book-digest-v1 note_type=digest source_type=book
```

Then structure your response with these exact headings:

## Core Thesis
Summarize the book's central argument or thesis in 1-3 sentences.

## Key Arguments
List the major arguments or claims the author makes, each as a bullet point with a brief explanation.

## Key Concepts
Define the most important concepts introduced or discussed. Format as:
- **Concept Name** — definition/explanation

## Notable Quotes
Include 3-5 significant quotes with page references where available. Format as blockquotes.

## Takeaways & Applications
What are the practical implications? How might these ideas apply to work, decisions, or other domains?

## Uncertain / Needs Verification
Flag any claims that seem unsupported, contradicted by other sources, or where the evidence is weak. If none, write "None identified."

## Connections
Suggest connections to other books, ideas, or fields that relate to this book's themes.

---

## Expected Output Structure

The parser uses these headings to extract content sections.

**Required headings (in order):**
1. `## Core Thesis`
2. `## Key Arguments`
3. `## Key Concepts`

**Optional headings (may appear, parser handles gracefully):**
- `## Notable Quotes`
- `## Takeaways & Applications`
- `## Uncertain / Needs Verification`
- `## Connections`

**List format:** Bullet points with `- ` prefix. Concepts use `**bold**` for terms.
Quotes use `>` blockquote syntax.

## Post-Processing Notes

- Inbox-processor adds YAML frontmatter (source block, tags, schema_version)
- `## Connections` entries are matched against existing vault notes for wikilink suggestions
- Title extracted from the first `# ` heading or inferred from source metadata

## Version History

- **v1** (2026-02-20): Initial version
