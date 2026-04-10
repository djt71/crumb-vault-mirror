---
project: null
domain: learning
type: reference
status: active
created: 2026-04-05
updated: 2026-04-05
tags:
  - notebooklm
  - template
---

# Template: epic-poetry-digest-v1

**Purpose:** Capture epic poetry (Homer, Hesiod, Virgil, etc.) for second-brain purposes.
Preserves narrative arc, mythological framework, oral-formulaic elements, and poetic craft
that prose-oriented templates miss. Works for both narrative epic (Iliad, Odyssey) and
didactic/cosmogonic poetry (Theogony, Works and Days).
**note_type:** digest
**source_type:** book
**scope:** whole

## Prompt

Copy and paste the following into NotebookLM with your epic selected as the active source:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content.

Please provide a digest of this epic poem focused on its narrative structure, themes, and poetic craft. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=epic-poetry-digest-v1 note_type=digest source_type=book -->
crumb:nlm-export v=1 template=epic-poetry-digest-v1 note_type=digest source_type=book
```

Then begin with a top-level heading:

# [Title] by [Author] ([Translator] translation)

Then structure your response with these exact headings:

## The Poem

What is this work? When was it composed (or when is it thought to have been composed), in what tradition, and for what audience? What is its place in the literary tradition? 2-3 paragraphs maximum — orient the reader, don't lecture.

## Narrative Arc

Trace the poem's large-scale movement from beginning to end. Organize by narrative phases, not book-by-book — group books that form natural units (e.g., "Books 1-4: Telemachy" or "Books 1-9: Wrath and withdrawal"). For each phase:
- What happens and what drives the action
- How it connects to what precedes and follows
- Where the major turning points fall

For didactic/cosmogonic poetry (Hesiod): trace the organizational logic instead — what comes first and why, how sections build on each other, what framework holds the poem together.

## The Divine Apparatus

How do the gods function in this poem? Which gods act, and in whose interest? Is divine intervention fate, politics, favoritism, cosmic justice, or something else? How does the relationship between human and divine agency shape the narrative? If the poem is itself about the gods (Theogony), describe the power structure and succession pattern. If gods play no role, write "Not applicable."

## Themes & Ideas

The major themes the poem explores. For each: what it is, how it manifests in the narrative, and what perspective the poem takes (even if ambiguous or contradictory). Give each theme its own paragraph. This is the core of the note.

## Character Study

Major characters (mortal and divine) and what they embody. Focus on what defines each character, how they change or remain fixed, and what they represent within the poem's thematic framework. For didactic poetry: this section may be brief or replaced with "key figures" (mythological exempla the poet invokes).

## Poetic Craft & Oral Tradition

What is distinctive about how this poem works as poetry, even in translation? Consider:
- Epithets and formulas (what patterns recur and what work do they do?)
- Similes (are they decorative, structural, thematic?)
- Catalog passages (lists of ships, genealogies, etc.)
- Ring composition or other structural patterns
- The translation's approach — does it preserve verse structure, use prose, modernize?
If working from a prose translation, note what is visible and what is necessarily lost.

## Notable Passages

8-12 significant passages with book and line references where available. Prioritize passages that crystallize a theme, represent the poem at its most powerful, or are frequently cited in the tradition. Include at least one simile and one speech. Format as blockquotes with brief context notes.

## Resonance & Connections

What does this poem set in motion? Connections to other works in the same tradition (e.g., Odyssey responding to Iliad, Aeneid responding to both), to later literature and philosophy, and to ideas that remain live. How has this poem shaped how we think?

**Important:** If this response ends mid-section due to truncation, stop where you are. The user will re-run with: "Continue from [last complete heading]" and concatenate.

---

## Expected Output Structure

**Top-level heading:**
- `# [Title] by [Author] ([Translator] translation)`

**Required headings (in order):**
1. `## The Poem`
2. `## Narrative Arc`
3. `## Themes & Ideas`

**Optional headings (parser handles gracefully):**
- `## The Divine Apparatus`
- `## Character Study`
- `## Poetic Craft & Oral Tradition`
- `## Notable Passages`
- `## Resonance & Connections`

**Content formats:**
- Narrative Arc: paragraphs per narrative phase, with book ranges noted
- Themes: full paragraphs per theme
- Characters: paragraphs focused on function and meaning, not plot summary
- Passages: `>` blockquote syntax with book/line references and context notes

## Post-Processing Notes

- Inbox-processor adds YAML frontmatter (source block, tags, schema_version)
- `## Resonance & Connections` entries matched against vault notes for wikilink suggestions
- Include translator in title heading — different translations of the same work get separate digests
- For very long epics, consider a companion book-by-book digest using chapter-digest-v1 adapted with "Book" instead of "Chapter"

## Truncation Recovery

If NLM truncates the response:
1. Note the last complete heading
2. Re-run: "Continue from [heading]. Begin with `## [heading]` and continue."
3. Concatenate after the truncation point
4. Sentinel appears only once (at the top)

## Version History

- **v1** (2026-04-05): Initial version — epic poetry capture for Homer, Hesiod, and classical verse
