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

# Template: fiction-digest-v1

**Purpose:** Capture what matters about fiction for second-brain purposes. Not a plot
summary — the note should answer "what did this book make me think about?" and "what
would I want to revisit?" Fiction lives in its language, so the quotes section should
be generous.
**note_type:** digest
**source_type:** book
**scope:** whole

## NLM Prompt

Copy and paste the following into NotebookLM as a chat query:

---

Please provide a digest of this novel focused on its ideas, themes, and memorable language — not a plot summary. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=fiction-digest-v1 note_type=digest source_type=book -->
crumb:nlm-export v=1 template=fiction-digest-v1 note_type=digest source_type=book
```

Then structure your response with these exact headings:

## Premise
What the book is about in 2-3 sentences. Setting, situation, central tension. Just enough to orient someone who hasn't read it. Do not summarize the plot.

## Themes & Ideas
The major themes the author explores. For each theme: what it is, how it manifests in the story (characters, events, structure), and what perspective or argument — implicit or explicit — the author presents through it. This is the core of the note. These are the ideas worth thinking about. Give each theme its own paragraph.

## Character Study
Major characters and what they represent or illuminate. For complex works, describe key relationship dynamics. Do not list every character — focus on what is interesting or meaningful about each major character's arc, what they reveal about the themes, and how they change. This is not a character list; it's an analysis of what the characters mean.

## Craft & Style
What is distinctive about how this book is written? Narrative structure (timeline, POV, framing), prose style, techniques the author uses to particular effect. Only include this section if the craft is notable — if the prose is workmanlike and the structure conventional, write "No distinctive craft elements to note."

## Notable Quotes
8-12 memorable passages. Prioritize lines that: crystallize a theme, capture the author's distinctive voice, reveal character, or are worth reading again on their own merits. Include page or location references where available. This section should be generous — fiction lives in its language. Format as blockquotes with brief context notes where helpful (e.g., who is speaking, the situation).

## Resonance & Connections
What stayed with you after reading? Write this section as prompts for the reader's own reflection — what questions does the book raise, what does it challenge, what might it change about how you see something? Include connections to other works, ideas, thinkers, or personal experience. Acknowledge that fiction's value is subjective — this section is an invitation to think, not a prescription.

## Context
OPTIONAL — include only if it materially affects interpretation. When the book was written, relevant biographical context about the author, historical circumstances that shaped the work, or literary context (movement, genre conventions being subverted). Skip entirely if the book stands on its own without this background.

---

## What This Template Explicitly Does NOT Include

- Chapter-by-chapter plot summary
- Comprehensive character lists
- Plot spoiler warnings (the note assumes you've read the book)
- Rating or recommendation language

## Expected Output Structure

**Required headings (in order):**
1. `## Premise`
2. `## Themes & Ideas`
3. `## Character Study`

**Optional headings (may appear, parser handles gracefully):**
- `## Craft & Style`
- `## Notable Quotes`
- `## Resonance & Connections`
- `## Context`

**Content formats:**
- Themes: full paragraphs per theme
- Characters: paragraphs focused on meaning and arc, not biography
- Quotes: `>` blockquote syntax with page/location attribution and context notes
- Resonance: reflective prompts and connections

## Post-Processing Notes

- Inbox-processor adds YAML frontmatter (source block, tags, schema_version)
- `## Resonance & Connections` entries matched against vault notes for wikilink suggestions
- Fiction notes benefit from `#kb/` tags that reflect the themes, not just "fiction"
  (e.g., a novel exploring justice might get `kb/philosophy`, a historical novel `kb/history`)

## Version History

- **v1** (2026-02-24): Initial version — themes-and-ideas-focused fiction capture
