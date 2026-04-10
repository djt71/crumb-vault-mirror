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

# Template: dialogue-digest-v1

**Purpose:** Capture Platonic and other philosophical dialogues for second-brain purposes.
Preserves the dialectical movement, interlocutor dynamics, and dramatic setting that
treatise-oriented templates flatten. Handles both aporetic dialogues (no conclusion) and
dogmatic ones (positive doctrine).
**note_type:** digest
**source_type:** book
**scope:** whole

## Prompt

Copy and paste the following into NotebookLM with your dialogue selected as the active source:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content.

Please provide a digest of this philosophical dialogue focused on its arguments, dramatic form, and ideas. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=dialogue-digest-v1 note_type=digest source_type=book -->
crumb:nlm-export v=1 template=dialogue-digest-v1 note_type=digest source_type=book
```

Then begin with a top-level heading:

# [Dialogue Title] by [Author]

Then structure your response with these exact headings:

## Dramatic Setting

Where does the conversation take place, when, and on what occasion? Who is present and why? Plato chose these settings deliberately — note what the setting contributes to the dialogue's meaning. Keep this to 1-2 paragraphs.

## Interlocutors

Who are the speakers and what positions do they represent? For each significant interlocutor: their identity (historical or dramatic), what they bring to the conversation (expertise, social position, temperament), and how they engage — are they cooperative, resistant, overmatched, ironic? Focus on their argumentative role, not biography.

## Dialectical Movement

Trace the argument's progression through the dialogue. This is the core section. For each major phase of the argument:
- What question or claim drives it
- How the argument proceeds (analogy, definition, refutation, myth, thought experiment)
- What conclusion is reached — or why the argument breaks down
- How it transitions to the next phase

Do not simply list "topics discussed." Show how each move follows from the last — why does Socrates shift from X to Y? Where does the argument turn, double back, or escalate?

## Key Arguments

The most important individual arguments, stated clearly. For each:
- The claim
- The reasoning (premises and inference)
- Whether it succeeds, fails, or is left open within the dialogue
- Its significance for the dialogue's larger question

## Myths, Analogies & Images

If the dialogue contains myths (e.g., Allegory of the Cave, Allegory of the Chariot, Allegory of the allegory), extended analogies, or vivid images that carry philosophical weight, describe each one: what it depicts, what philosophical point it advances, and where it appears. If none, write "None — the dialogue proceeds through argument alone."

## Outcome

Does the dialogue reach a conclusion? If yes: what is it, and how firmly does the text commit to it? If aporetic (no resolution): what has been ruled out, what tensions remain, and is the aporia itself the point? This section should be honest about what the dialogue actually accomplishes versus what readers often attribute to it.

## Themes & Ideas

The major philosophical themes explored. For each: what it is, how the dialogue approaches it, and what perspective emerges (even if tentative or contested). Give each theme its own paragraph.

## Notable Quotes

8-12 significant passages with Stephanus numbers (e.g., 509b) or section references where available. Prioritize lines that crystallize an argument, capture Socratic irony, or are frequently cited. Format as blockquotes with brief context notes.

## Resonance & Connections

Connections to other dialogues by the same author (especially where characters or arguments recur), to other philosophical traditions, and to later thinkers who engage with the dialogue's questions. What remains live in this dialogue?

**Important:** If this response ends mid-section due to truncation, stop where you are. The user will re-run with: "Continue from [last complete heading]" and concatenate.

---

## Expected Output Structure

**Top-level heading:**
- `# [Dialogue Title] by [Author]`

**Required headings (in order):**
1. `## Dramatic Setting`
2. `## Interlocutors`
3. `## Dialectical Movement`
4. `## Key Arguments`

**Optional headings (parser handles gracefully):**
- `## Myths, Analogies & Images`
- `## Outcome`
- `## Themes & Ideas`
- `## Notable Quotes`
- `## Resonance & Connections`

**Content formats:**
- Dialectical Movement: narrative paragraphs tracing argument progression
- Key Arguments: structured per argument (claim, reasoning, status, significance)
- Myths: paragraph per myth/analogy with description and philosophical function
- Quotes: `>` blockquote syntax with Stephanus numbers and context notes

## Post-Processing Notes

- Inbox-processor adds YAML frontmatter (source block, tags, schema_version)
- `## Resonance & Connections` entries matched against vault notes for wikilink suggestions
- For collected dialogues (e.g., Apology + Crito + Phaedo), process each separately, then cross-reference in Connections
- Stephanus numbers are the universal citation standard for Plato — flag if NLM output uses page numbers instead

## Truncation Recovery

If NLM truncates the response:
1. Note the last complete heading
2. Re-run: "Continue from [heading]. Begin with `## [heading]` and continue."
3. Concatenate after the truncation point
4. Sentinel appears only once (at the top)

## Version History

- **v1** (2026-04-05): Initial version — dialectical capture for Platonic and other philosophical dialogues
