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

# Template: source-digest-v1

**Purpose:** General-purpose digest for articles, papers, podcasts, videos, courses.
**note_type:** digest
**source_type:** article | paper | podcast | video | course | other
**scope:** whole

## NLM Prompt

Copy and paste the following into NotebookLM as a chat query:

---

Please provide a comprehensive digest of this source. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=source-digest-v1 note_type=digest -->
crumb:nlm-export v=1 template=source-digest-v1 note_type=digest
```

Then structure your response with these exact headings:

## Core Thesis
Summarize the source's central argument or main point in 1-3 sentences.

## Key Arguments
List the major arguments or claims, each as a bullet point with a brief explanation.

## Key Concepts
Define the most important concepts. Format as:
- **Concept Name** — definition/explanation

## Notable Quotes
Include 2-3 significant quotes or key passages. Format as blockquotes.

## Takeaways & Applications
What are the practical implications? How might these ideas be useful?

## Uncertain / Needs Verification
Flag any claims that seem unsupported or where the evidence is weak. If none, write "None identified."

## Connections
Suggest connections to other sources, ideas, or fields.

---

## Expected Output Structure

**Required headings (in order):**
1. `## Core Thesis`
2. `## Key Arguments`
3. `## Key Concepts`

**Optional headings:**
- `## Notable Quotes`
- `## Takeaways & Applications`
- `## Uncertain / Needs Verification`
- `## Connections`

**Note:** `source_type` is NOT embedded in the sentinel for this generic template.
The inbox-processor infers it from context or prompts the user.

## Post-Processing Notes

- Inbox-processor prompts user for `source_type` since this template is generic
- For podcast/video sources, `needs_review` tag is auto-applied
- Title extracted from the first `# ` heading or inferred from source metadata

## Version History

- **v1** (2026-02-20): Initial version
