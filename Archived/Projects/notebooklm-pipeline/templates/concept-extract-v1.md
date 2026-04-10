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

# Template: concept-extract-v1

**Purpose:** Pull specific concepts, ideas, or frameworks from a source.
**note_type:** extract
**source_type:** any
**scope:** whole | chapter:<name> | topic:<name>

## NLM Prompt

Copy and paste the following into NotebookLM as a chat query. Replace `[TOPIC]`
with the specific concept or area of interest:

---

Extract the key concepts related to [TOPIC] from this source. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=concept-extract-v1 note_type=extract -->
crumb:nlm-export v=1 template=concept-extract-v1 note_type=extract
```

Then structure your response with these exact headings:

## Concepts
For each concept, provide:
- **Concept Name** — clear definition/explanation
- How it relates to [TOPIC]
- Where it appears in the source (page, chapter, or timestamp if available)

## Arguments
List any arguments the source makes about these concepts:
1. Claim + supporting evidence

## Evidence & Quotes
Key passages that define or illustrate these concepts. Format as blockquotes with source location.

## Connections
How do these concepts relate to other ideas, frameworks, or sources?

---

## Expected Output Structure

**Required headings (in order):**
1. `## Concepts`

**Optional headings:**
- `## Arguments`
- `## Evidence & Quotes`
- `## Connections`

**List format:** Concepts use `**bold**` for terms with `- ` bullet prefix.
Arguments use numbered lists. Quotes use `>` blockquote syntax.

## Post-Processing Notes

- Inbox-processor generates title as "[Topic] — from [Source Title]"
- `scope` is set based on user input (whole, chapter, or topic)
- For scoped extracts, the user should specify scope when dropping in inbox

## Version History

- **v1** (2026-02-20): Initial version
