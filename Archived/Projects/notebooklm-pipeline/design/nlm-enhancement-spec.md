---
project: notebooklm-pipeline
domain: learning
type: design
status: active
created: 2026-02-24
updated: 2026-02-24
tags:
  - notebooklm
  - pipeline
  - enhancement
---

# NLM Pipeline Enhancement Spec

Maintenance reopening of the archived notebooklm-pipeline project. Scope: template
revisions for deeper non-fiction capture, new templates (fiction, chapter-digest),
parser hardening for structured content. No architectural changes — same sentinel
contract, same inbox-processor routing, same Sources/ directory.

## Motivation

The v1 templates produce useful but shallow digests. For second-brain utility, the
captured knowledge needs to be detailed enough to reconstruct the author's argument
structure, preserve actionable content (checklists, procedures, tables), and surface
quotations worth revisiting. Fiction sources need a fundamentally different template
that captures what matters about a novel — not plot summary.

## E1: Revise book-digest-v1 → book-digest-v2

**Problem:** Current template produces 1-3 sentence thesis + bullet-point arguments.
Not enough depth for a book you read 2 years ago and need to recall in detail.

**Changes:**

Revise the NLM prompt to request:

- **Core Thesis** — expand from 1-3 sentences to a full paragraph. The author's central
  argument, what problem they're addressing, why it matters, and the overall approach.
- **Key Arguments** — each argument gets a paragraph, not a bullet. Include the claim,
  the evidence the author presents, and how it connects to the thesis. Aim for the level
  of detail where you could explain the argument to someone without having read the book.
- **Key Concepts & Frameworks** — retain bold-term format but add: how the author uses
  the concept, what it enables or explains, and a concrete example from the text.
- **Notable Quotes** — increase from 3-5 to 8-12. Include page/location references.
  Prioritize quotes that capture the author's voice, crystallize key arguments, or are
  independently memorable. Format as blockquotes with attribution.
- **Checklists & Procedures** — NEW SECTION. If the book contains step-by-step
  procedures, checklists, decision frameworks, or how-to sequences, reproduce them
  using markdown checkbox syntax (`- [ ]`) and numbered lists. Preserve the author's
  structure. If none present, write "Not applicable — this source does not contain
  procedural content."
- **Tables & Structured Data** — NEW SECTION. If the book contains comparison tables,
  matrices, taxonomies, or other tabular content, reproduce them as markdown tables.
  Preserve column structure and data. If none present, write "Not applicable."
- **Takeaways & Applications** — retain but expand. Concrete applications, not generic
  "this could be useful." Who would benefit, in what situation, what would they do
  differently?
- **Uncertain / Needs Verification** — retain as-is.
- **Connections** — retain as-is.

**Sentinel:** `template=book-digest-v2`
**Expected output structure:** Update heading map. Checklists & Procedures and Tables
& Structured Data become optional headings. Parser must handle checkbox syntax and
markdown tables as passthrough (no reformatting).

**Backward compatibility:** book-digest-v1 remains functional. Parser retains v1
heading map. Users can still use v1 for quick/lightweight captures.

**Truncation handling:** If NLM truncates the response mid-section (likely for dense
books at v2 depth), the template includes recovery instructions: "If this response ends
mid-section, the output was truncated. Re-run with: 'Continue from [last complete
heading]' and concatenate."

## E2: Revise source-digest-v1 → source-digest-v2

**Problem:** Same shallowness issue as book-digest. Additionally, source-digest serves
articles, papers, podcasts, and videos — a wide range that benefits from deeper capture.

**Changes:** Mirror the book-digest-v2 depth improvements:

- Expanded Core Thesis (full paragraph)
- Expanded Key Arguments (paragraph per argument with evidence)
- Expanded Key Concepts (usage + example)
- More Notable Quotes (5-8, with timestamps for audio/video)
- NEW: Checklists & Procedures section (same as E1)
- NEW: Tables & Structured Data section (same as E1)
- Expanded Takeaways

**Sentinel:** `template=source-digest-v2`
**Backward compatibility:** source-digest-v1 remains.

**Truncation handling:** Same recovery instructions as E1 — included in template.

## E3: New template — chapter-digest-v1

**Purpose:** Chapter-by-chapter breakdown of a non-fiction book. Preserves the
structure of the author's argument as it develops across the book. Companion to
book-digest-v2 (which gives the whole-book view).

**note_type:** digest
**source_type:** book
**scope:** `chapter:all` (for the full chapter breakdown) or `chapter:<name>` for
individual chapters

**Prompt instructs NLM to produce:**

For each chapter:
- **Chapter N: [Title]** — H3 heading
- **Summary** — 2-3 paragraph summary of the chapter's argument, what it builds on
  from prior chapters, and what it sets up for subsequent chapters
- **Key Points** — the chapter's main claims with evidence
- **Notable Quotes** — 2-3 per chapter, with page references
- **Checklists & Procedures** — if present in this chapter
- **Tables & Structured Data** — if present in this chapter

After all chapters:
- **Argument Arc** — how the book's argument develops across chapters, which chapters
  are foundational vs. which apply or extend, any structural patterns
- **Cross-Chapter Connections** — themes or concepts that recur across chapters

**NLM feasibility note:** A full chapter-by-chapter breakdown for a long book will
likely exceed NLM's response limits in a single query. Two strategies:

1. **PRIMARY — Individual chapter queries:** Run separate chapter-digest queries with
   `scope: chapter:<n>` — produces one note per chapter. Fits the existing "one query =
   one note" contract cleanly. Each note is independently valid and dedupable.
2. **FALLBACK — Batch for short books:** "Summarize chapters 1-5..." then "Summarize
   chapters 6-10..." User concatenates outputs, adds single sentinel at top. Use only
   when the book is short enough that you're confident a batch will fit.

Template should document both approaches with the individual-query path as the default.

**Truncation handling:** Same recovery instructions as E1 — included in template.
Particularly important here since chapter breakdowns are the most likely to hit limits.

## E4: New template — fiction-digest-v1

**Purpose:** Capture what matters about fiction for second-brain purposes. Not a plot
summary — the note should answer "what did this book make me think about?" and "what
would I want to revisit?"

**note_type:** digest
**source_type:** book
**scope:** whole

**Prompt instructs NLM to produce:**

- **Premise** — what the book is about in 2-3 sentences. Setting, situation, central
  tension. Just enough to orient someone who hasn't read it.
- **Themes & Ideas** — the major themes the author explores. For each: what the theme
  is, how it manifests in the story, and what perspective or argument (implicit or
  explicit) the author presents through it. This is the core of the note — these are
  the ideas worth thinking about.
- **Character Study** — major characters and what they represent or illuminate. For
  complex works: a relationship map showing key dynamics. Not a character list — focus
  on what's interesting or meaningful about each character's arc.
- **Craft & Style** — what's distinctive about how the book is written. Narrative
  structure, prose style, techniques the author uses. Only if notable — skip for
  workmanlike prose.
- **Notable Quotes** — 8-12 memorable passages. Prioritize lines that crystallize a
  theme, capture the author's voice, or are worth reading again on their own. Include
  page/location references. This section should be generous — fiction lives in its
  language.
- **Resonance & Connections** — what stayed with you (written as prompts for the
  reader's own reflection). Connections to other works, ideas, or personal experience.
  This section acknowledges that fiction's value is subjective.
- **Context** — OPTIONAL. When the book was written, relevant biographical or
  historical context that changes how you read it. Only if it materially affects
  interpretation.

**What this template explicitly does NOT include:**
- Chapter-by-chapter plot summary
- Comprehensive character lists
- Plot spoiler warnings (the note assumes you've read the book)

**Sentinel:** `template=fiction-digest-v1`

## E5: Parser hardening — structured content preservation

**Problem:** The inbox-processor may reformat or break markdown tables, checkbox
syntax, and blockquotes during frontmatter injection and file routing.

**Changes to inbox-processor SKILL.md:**

- **Markdown tables:** Treated as passthrough blocks. Parser identifies table blocks
  (lines matching `|...|` pattern) and preserves them byte-for-byte. No column
  realignment, no reformatting.
- **Checkbox syntax:** `- [ ]` and `- [x]` lines preserved exactly. Parser must not
  convert to regular list items.
- **Blockquotes:** `>` prefixed lines preserved. Nested blockquotes (`>>`) preserved.
  No unwrapping or reflowing.
- **Implementation approach:** Frontmatter injection is prepend-only (add YAML block
  at top of file). Body content should never be modified by the routing step. If the
  current implementation does any body transformation, identify and remove it.

**Testing:** Each fixture set (E1-E4) should include at least one export containing
tables, checklists, and blockquotes to verify passthrough behavior.

## E6: Update template index and README

Update `_system/docs/templates/notebooklm/README.md` template table to include:
- book-digest-v2
- source-digest-v2
- chapter-digest-v1
- fiction-digest-v1

Add guidance on when to use v1 vs v2 (v1 for quick capture, v2 for thorough second-brain notes).

## E7: V1 fixture gap closure

**Problem:** V1 archived with only 2 of 6 fixture slots filled (both books via different
export methods). Article, podcast/video, messy export, and short output remain untested.
The new templates (E1-E4) already require new fixtures, making this the natural moment
to close the v1 coverage gap.

**Fixtures needed (all using existing v1 templates):**
- **Article** (source-digest-v1) — tests generic `source_type` inference prompting
- **Podcast or video** (source-digest-v1) — tests `needs_review` auto-tag, timestamp
  handling in Notable Quotes section
- **Messy export** (any v1 template) — tests sentinel detection resilience with
  formatting artifacts, partial content, or garbled markdown
- **Short output** (any v1 template) — tests minimum-viable content handling when NLM
  produces a terse response

**User dependency:** User must run v1 templates in NLM against appropriate sources and
export results to `_inbox/`. Claude validates parser behavior against each fixture.

**Success criteria:** All 4 fixtures processed through inbox-processor without manual
intervention. Sentinel detected, metadata extracted, routed correctly, frontmatter valid.

## Execution Notes

**For Crumb (Claude Code):**
- Reopen notebooklm-pipeline from archive. Add run-log entry documenting maintenance
  scope: "Enhancement pass — deeper templates, fiction support, parser hardening."
- E1-E4 are template authoring — Claude-executable, no user dependency.
- E5 is parser work — Claude-executable, test against fixtures.
- E6 is documentation — Claude-executable after E1-E4.
- User validation needed after: run revised/new templates in NLM, export, drop fixtures,
  verify parser handles them correctly.

**Fixture requirements for new templates:**
- book-digest-v2: 1 how-to book with checklists + tables, 1 argument-heavy non-fiction
- chapter-digest-v1: 1 book with clear chapter structure
- fiction-digest-v1: 1 literary fiction, 1 genre fiction (to test template across styles)
- Each fixture must include at least one table, one checklist, and several blockquotes

**Not in scope (parked):**
- Chrome automation of NLM interaction via Claude in Chrome (feasibility probe TBD)
- Direct DOM extraction as alternative to Chrome extension export
- Manual intake adapter for feed-intel-framework (separate decision record exists)
