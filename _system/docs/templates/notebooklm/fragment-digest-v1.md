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

# Template: fragment-digest-v1

**Purpose:** Capture fragmentary philosophical texts (Pre-Socratics, Epicurus, etc.) and
anthologies of fragments for second-brain purposes. These works survive as quotations
embedded in later authors, not as continuous texts — the template accounts for reconstruction
uncertainty, source attribution, and thematic grouping across discontinuous material.
**note_type:** digest
**source_type:** book
**scope:** whole

## Prompt

Copy and paste the following into NotebookLM with your fragment collection selected as the active source:

---

IMPORTANT: Your response MUST begin with the two sentinel lines shown below, before any other content.

Please provide a digest of this collection of philosophical fragments. Begin your response with exactly these two lines (do not modify them):

```
<!-- crumb:nlm-export v=1 template=fragment-digest-v1 note_type=digest source_type=book -->
crumb:nlm-export v=1 template=fragment-digest-v1 note_type=digest source_type=book
```

Then begin with a top-level heading:

# [Title] — [Author/Editor] ([Edition/Translation])

Then structure your response with these exact headings:

## The Source

What is this text? Is it a single thinker's surviving fragments, an anthology of multiple thinkers, or a later author's compilation? Who collected, edited, or translated this edition, and what editorial framework do they use (e.g., Diels-Kranz numbering, thematic arrangement)? What should the reader understand about how this material reached us? 1-2 paragraphs.

## Thinkers & Their Projects

For each major thinker represented in the collection, provide:
- **[Thinker Name]** (approximate dates, city/school if known) — What were they trying to explain or argue? What is their central insight or framework? How much of their work survives — fragments, paraphrases, testimonia? 1 paragraph per thinker.

For single-thinker collections (e.g., just Heraclitus or just Epicurus), use a single extended entry.

## Key Fragments

The most important individual fragments or passages. For each:
- The fragment text (quote it directly)
- Fragment number if available (DK, KRS, or edition-specific numbering)
- Who preserved it and in what context (if stated in the source)
- What it means or what it contributes to the thinker's philosophy
- Confidence level: verbatim quotation, close paraphrase, or testimonium (report about what someone thought)

Include 10-15 fragments. Prioritize those that are philosophically significant, frequently cited, or capture a thinker's voice most directly.

## Thematic Synthesis

Group the fragments by philosophical theme rather than by thinker. Likely themes include (use what fits, skip what doesn't):
- **Cosmology & Physics** — What is the world made of? How does change work?
- **Epistemology** — How do we know? What are the limits of perception and reason?
- **Ethics & the Good Life** — How should one live? What matters?
- **Language & Logos** — What is the relationship between speech, reason, and reality?
- **The Divine** — What role do gods play? Is there cosmic order or purpose?

For each theme: what positions appear across the fragments, where do thinkers agree or conflict, and what remains unresolved?

## Gaps & Uncertainties

What is missing? Where does the fragmentary nature of the evidence create real interpretive problems? Are there major disputes about what a thinker meant that the surviving evidence cannot resolve? What would change our understanding most if we had more text? Be honest about what we don't know.

## Notable Quotes

8-12 of the most memorable or frequently cited fragments, formatted as blockquotes with fragment numbers and brief context. These may overlap with Key Fragments — that's fine. This section is for passages worth returning to as quotations.

## Resonance & Connections

How do these fragments connect to later philosophy — Plato, Aristotle, Stoicism, Epicureanism, modern thought? Which fragments or ideas have had influence disproportionate to their brevity? What questions raised here remain open?

**Important:** If this response ends mid-section due to truncation, stop where you are. The user will re-run with: "Continue from [last complete heading]" and concatenate.

---

## Expected Output Structure

**Top-level heading:**
- `# [Title] — [Author/Editor] ([Edition/Translation])`

**Required headings (in order):**
1. `## The Source`
2. `## Thinkers & Their Projects`
3. `## Key Fragments`
4. `## Thematic Synthesis`

**Optional headings (parser handles gracefully):**
- `## Gaps & Uncertainties`
- `## Notable Quotes`
- `## Resonance & Connections`

**Content formats:**
- Thinkers: `**bold name**` + paragraph per thinker
- Key Fragments: quoted text + number + source + interpretation + confidence
- Thematic Synthesis: paragraphs under **bold** sub-theme labels
- Quotes: `>` blockquote syntax with fragment numbers

## Post-Processing Notes

- Inbox-processor adds YAML frontmatter (source block, tags, schema_version)
- `## Resonance & Connections` entries matched against vault notes for wikilink suggestions
- Fragment collections often warrant `kb/philosophy` + a second tag for the domain (e.g., `kb/history` for historical context, `kb/religion` for theology)
- For anthologies covering multiple thinkers, consider whether individual thinker digests are also warranted after the collection-level digest

## Truncation Recovery

If NLM truncates the response:
1. Note the last complete heading
2. Re-run: "Continue from [heading]. Begin with `## [heading]` and continue."
3. Concatenate after the truncation point
4. Sentinel appears only once (at the top)

## Version History

- **v1** (2026-04-05): Initial version — fragmentary philosophy capture for Pre-Socratics and similar collections
