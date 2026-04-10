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

# Template: drama-digest-v1

**Purpose:** Capture Greek (and other classical) drama for second-brain purposes. Preserves
dramatic structure, choral function, and performance context that generic fiction templates
miss. Works for tragedy and comedy alike.
**note_type:** digest
**source_type:** book
**scope:** whole

## Prompt

Copy and paste the following into NotebookLM with your play selected as the active source:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content.

Please provide a digest of this play focused on its dramatic structure, themes, and ideas. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=drama-digest-v1 note_type=digest source_type=book -->
crumb:nlm-export v=1 template=drama-digest-v1 note_type=digest source_type=book
```

Then begin with a top-level heading:

# [Play Title] by [Playwright]

Then structure your response with these exact headings:

## Context

When and where the play was first performed (festival, competition, year if known). Position within a trilogy or sequence if applicable. The mythological or historical source material the audience would have known. Keep this brief — just what's needed to understand what the playwright is working with and against.

## Dramatic Structure

Walk through the play's movement using its actual structural units — prologue, parodos (chorus entry), episodes, stasima (choral odes), exodus. For each major unit:
- What happens dramatically
- What shifts in the conflict or understanding
- How it connects to what comes before and after

Do not simply summarize the plot. Trace the dramatic logic — why this scene follows that one, where the turning points fall, where tension builds or releases.

## The Chorus

What role does the chorus play in this drama? Are they participants, witnesses, commentators, the voice of the community? How does their perspective differ from the main characters? Do their odes reinforce or undercut the action? Identify 1-2 choral passages that are essential to the play's meaning.

## Agon & Central Conflict

Identify the play's central conflict and any formal agon (debate scene). Who argues what position? What values or principles collide? Is there a resolution, or does the play leave the tension standing? For comedy: identify the fantastical premise and how it refracts the real conflict.

## Themes & Ideas

The major themes the playwright explores. For each: what it is, how it manifests in the action, and what perspective emerges. Give each theme its own paragraph. This is the core of the note.

## Character Study

Major characters and what they illuminate. Focus on what drives each character, how they embody or resist the play's themes, and where they stand at the end versus the beginning. For comedy: how characters function as types or satirical targets.

## Craft & Stagecraft

What is distinctive about how this play works as theater? Notable dramatic techniques — irony, recognition scenes (anagnorisis), reversals (peripeteia), messenger speeches, deus ex machina, use of masks or stage machinery. Verse forms if notable (stichomythia, lyric meters in odes). If the craft is conventional for its genre, say so briefly.

## Notable Quotes

8-12 significant passages with line references where available. Prioritize lines that crystallize a theme, capture a character's essence, or represent the playwright's voice at its most concentrated. Include at least one choral passage. Format as blockquotes with brief context notes.

## Resonance & Connections

What questions does the play raise that outlast its performance? Connections to other plays (especially within the same playwright's work or the same myth cycle), philosophical ideas, or later works it influenced. How does it sit within the broader tradition?

**Important:** If this response ends mid-section due to truncation, stop where you are. The user will re-run with: "Continue from [last complete heading]" and concatenate.

---

## Expected Output Structure

**Top-level heading:**
- `# [Play Title] by [Playwright]`

**Required headings (in order):**
1. `## Context`
2. `## Dramatic Structure`
3. `## The Chorus`
4. `## Agon & Central Conflict`
5. `## Themes & Ideas`

**Optional headings (parser handles gracefully):**
- `## Character Study`
- `## Craft & Stagecraft`
- `## Notable Quotes`
- `## Resonance & Connections`

**Content formats:**
- Dramatic Structure: narrative paragraphs per structural unit
- Themes: full paragraphs per theme
- Characters: paragraphs focused on dramatic function, not plot biography
- Quotes: `>` blockquote syntax with line references and context notes

## Post-Processing Notes

- Inbox-processor adds YAML frontmatter (source block, tags, schema_version)
- `## Resonance & Connections` entries matched against vault notes for wikilink suggestions
- Tag with `#kb/` tags reflecting themes (e.g., `kb/philosophy` for justice plays, `kb/politics` for Aristophanes)
- For collections (e.g., Oresteia trilogy), process each play separately, then note trilogy arc in Connections

## Truncation Recovery

If NLM truncates the response:
1. Note the last complete heading
2. Re-run: "Continue from [heading]. Begin with `## [heading]` and continue."
3. Concatenate after the truncation point
4. Sentinel appears only once (at the top)

## Version History

- **v1** (2026-04-05): Initial version — structural drama capture for Greek tragedy and comedy
