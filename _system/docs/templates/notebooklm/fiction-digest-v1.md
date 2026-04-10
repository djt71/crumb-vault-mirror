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

# Template: fiction-digest-v1

**Purpose:** Capture what matters about fiction for second-brain purposes. Not a plot
summary — the note should answer "what did this book make me think about?" and "what
would I want to revisit?" Fiction lives in its language, so the quotes section should
be generous.
**note_type:** digest
**source_type:** book
**scope:** whole

## Prompt

Copy and paste the following into NotebookLM with your book selected as the active source:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content.

Please provide a digest of this novel focused on its ideas, themes, and memorable language — not a plot summary. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=fiction-digest-v1 note_type=digest source_type=book -->
crumb:nlm-export v=1 template=fiction-digest-v1 note_type=digest source_type=book
```

Then begin with a top-level heading:

# [Book Title] by [Author]

Then structure your response with these exact headings:

## Premise
What the book is about in 2-3 sentences. Setting, situation, central tension. Just enough to orient someone who hasn't read it. Do not summarize the plot.

## Themes & Ideas
The major themes the author explores. For each: what it is, how it manifests in the story, and what perspective the author presents through it. Give each theme its own paragraph. This is the core of the note.

## Character Study
Major characters and what they represent or illuminate. Focus on what is interesting about each character's arc, what they reveal about the themes, and how they change. This is analysis, not a character list.

## Craft & Style
What is distinctive about how this book is written? Narrative structure, prose style, notable techniques. If the craft is unremarkable, write "No distinctive craft elements to note."

## Notable Quotes
8-12 memorable passages with page/location references. Prioritize lines that crystallize a theme, capture the author's voice, or are worth reading again. Format as blockquotes with brief context notes where helpful.

## Resonance & Connections
What questions does the book raise? What does it challenge? Connections to other works, ideas, or thinkers. This section is an invitation to think, not a prescription.

## Context
OPTIONAL — include only if it materially affects interpretation. When written, relevant biographical or historical context, literary context. Skip entirely if the book stands on its own.

**Important:** If this response ends mid-section due to truncation, stop where you are. The user will re-run with: "Continue from [last complete heading]" and concatenate.

---

## Expected Output Structure

**Top-level heading:**
- `# [Book Title] by [Author]`

**Required headings (in order):**
1. `## Premise`
2. `## Themes & Ideas`
3. `## Character Study`

**Optional headings (parser handles gracefully):**
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

## Truncation Recovery

If NLM truncates the response:
1. Note the last complete heading
2. Re-run: "Continue from [heading]. Begin with `## [heading]` and continue."
3. Concatenate after the truncation point
4. Sentinel appears only once (at the top)

## Version History

- **v1** (2026-02-24): Initial version — themes-and-ideas-focused fiction capture
