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

# Template: argument-map-v1

**Purpose:** Map the logical structure of arguments in a source — claims, evidence,
counterarguments, and logical dependencies.
**note_type:** extract
**source_type:** any
**scope:** whole | chapter:<name>

## NLM Prompt

Copy and paste the following into NotebookLM as a chat query:

---

Map the argument structure of this source. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=argument-map-v1 note_type=extract -->
crumb:nlm-export v=1 template=argument-map-v1 note_type=extract
```

Then structure your response with these exact headings:

## Central Claim
State the source's main thesis or central argument in 1-2 sentences.

## Argument Structure
For each major argument:
1. **Claim:** [The assertion]
   - **Evidence:** [What supports it]
   - **Reasoning:** [How the evidence supports the claim]
   - **Counterarguments:** [Opposing views addressed, if any]
   - **Strength:** Strong / Moderate / Weak (with brief justification)

## Logical Dependencies
Which arguments depend on which? Show the chain:
- Argument 1 → supports → Central Claim
- Argument 2 → depends on → Argument 1

## Assumptions
What unstated assumptions underlie the arguments?

## Connections
How does this argument structure relate to other sources or frameworks?

---

## Expected Output Structure

**Required headings (in order):**
1. `## Central Claim`
2. `## Argument Structure`

**Optional headings:**
- `## Logical Dependencies`
- `## Assumptions`
- `## Connections`

**List format:** Arguments use numbered lists with nested `- ` bullets for evidence,
reasoning, counterarguments, and strength assessment.

## Post-Processing Notes

- Inbox-processor generates title as "Argument Map — [Source Title]"
- This produces `note_type: extract` (not a dedicated `argument-map` type in v1)
- `scope` defaults to `whole` unless user specifies a chapter

## Version History

- **v1** (2026-02-20): Initial version
