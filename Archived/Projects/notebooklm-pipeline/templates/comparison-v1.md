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

# Template: comparison-v1

**Purpose:** Compare and contrast multiple sources on a shared topic. Requires a
multi-source NLM notebook.
**note_type:** extract
**source_type:** any (multi-source)
**scope:** topic:<name>

## NLM Prompt

Copy and paste the following into NotebookLM as a chat query. Replace `[TOPIC]`
with the shared topic. This template works best in a notebook with 2+ sources:

---

Compare and contrast how the sources in this notebook address [TOPIC]. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=comparison-v1 note_type=extract -->
crumb:nlm-export v=1 template=comparison-v1 note_type=extract
```

Then structure your response with these exact headings:

## Sources Compared
List each source with author and a one-line description of its perspective on [TOPIC].

## Points of Agreement
Where do the sources agree? List shared claims, frameworks, or conclusions.

## Points of Disagreement
Where do they diverge? For each point of disagreement:
- **Source A says:** [position]
- **Source B says:** [position]
- **Key difference:** [what makes this disagreement meaningful]

## Unique Contributions
What does each source uniquely bring to the topic that others don't address?

## Synthesis
What picture emerges when you combine insights from all sources? What's the most
useful takeaway for someone trying to understand [TOPIC]?

## Connections
How does this comparison relate to other ideas, frameworks, or domains?

---

## Expected Output Structure

**Required headings (in order):**
1. `## Sources Compared`
2. `## Points of Agreement`
3. `## Points of Disagreement`

**Optional headings:**
- `## Unique Contributions`
- `## Synthesis`
- `## Connections`

**List format:** Bullet points with `- ` prefix. Disagreements use nested structure
with **bold** source labels.

## Post-Processing Notes

- Inbox-processor generates title as "[Topic] — Comparison"
- `source_id` is derived from the topic, not a single source: `compare-[topic-slug]`
- `scope` is set to `topic:[topic-name]`
- Multiple `#kb/` tags likely needed (one per source's domain)

## Version History

- **v1** (2026-02-20): Initial version
