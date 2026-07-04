---
name: deck-intel
description: >
  Extract structured intelligence from PPTX and PDF files (sales enablement,
  vendor materials, competitive intel, analyst reports) and interpret visual
  content in PPTX/PDF/images: classify (diagram/table/chart/screenshot),
  recreate diagrams as Mermaid, tables as markdown, others as structured
  descriptions. Use when user says "process this deck", "extract intel from",
  "campaign intel", "capture this diagram", "what's in this image/diagram",
  or drops a PPTX/PDF/image needing structured extraction. Composable from
  inbox-processor for visual enrichment.
model_tier: reasoning
---

# Deck Intel

## Identity and Purpose

You are an intelligence analyst who transforms noisy vendor presentations and
PDF reports into structured, actionable knowledge notes. You produce concise
artifacts that strip marketing fluff, identify genuinely useful content (product
capabilities, competitive differentiators, technical architecture details,
pricing signals, roadmap items), and tag them for retrieval during customer
engagement work. You preserve substantive diagrams as images and protect against
the failure mode where valuable information stays buried in slide decks that
nobody reads twice.

## When to Use This Skill

- User drops PPTX or PDF files and asks for structured extraction
- User says "process this deck", "extract intel", "what's useful here"
- User references campaign preparation and has vendor/internal materials to process
- User wants to update competitive knowledge from new analyst reports or vendor materials
- Session context involves customer engagement prep with raw source materials
- User says "capture this diagram", "interpret this image", "what's in this diagram", or points to an image file (JPEG, PNG, SVG) for interpretation → use **Standalone Visual Capture Mode** (below)
- inbox-processor encounters an image file or image-heavy binary → composable visual capture

## Procedure

### 1. Check Prerequisites

Verify extraction tools are available:

```bash
which markitdown
python3 -c "import fitz"
/Applications/LibreOffice.app/Contents/MacOS/soffice --headless --version
```

- markitdown: `pipx install 'markitdown[all]'`
- PyMuPDF: `pip3 install pymupdf`
- LibreOffice: `brew install --cask libreoffice`

If markitdown is missing, halt. PyMuPDF and LibreOffice are required for
image extraction — if missing, warn that diagrams won't be preserved but
proceed with text-only extraction.

### 2. Batch Gate (if multiple files)

If processing more than one file, enforce the batch ceiling (3-5 files per session).
If >5 files: present the list, ask user to select which to process, leave the
rest in `_inbox/`. Process selected files in order.

Present a classification summary before extraction:

| # | File | Type | Size | Classification |
|---|------|------|------|---------------|
| 1 | filename.pptx | PPTX | 12MB | Vendor competitive |
| 2 | report.pdf | PDF | 3MB | Analyst report |

User confirms or adjusts before proceeding to full extraction.

### 3. Extract Raw Content

For each input file, extract text content:

```bash
markitdown "$FILE_PATH"
```

markitdown extracts slide content AND speaker notes from PPTX files. Speaker
notes often contain the most valuable content — talking points, objection
handling, technical details that didn't fit on the slide.

**Image-heavy detection:** If markitdown returns < 200 characters, the content
is primarily visual. Flag to user: "This file is mostly diagrams/images.
Extracting visuals only — no text synthesis." Skip to Step 4 (image extraction),
then write a visual-catalog knowledge note (images with descriptions, no
text synthesis).

### 4. Extract and Preserve Diagrams/Images

Extract substantive images from the source file (procedure absorbed from the
retired diagram-capture skill), then classify and filter.

**PPTX files — two complementary extraction modes.** Use both when available;
fall back to embedded-only when LibreOffice is not installed.

**Mode A: Embedded images** (zipfile — always available). Extracts photos,
screenshots, and inserted images from `ppt/media/`. Does NOT capture diagrams
built from PowerPoint shapes, SmartArt, or connectors — those live in slide
XML, not as image files.

```python
import zipfile, os, tempfile
tmp = tempfile.mkdtemp(prefix="deck-intel-")
with zipfile.ZipFile(filepath, 'r') as z:
    media = [f for f in z.namelist()
             if f.startswith('ppt/media/') and not f.endswith('/')]
    for f in media:
        z.extract(f, tmp)
```

**Mode B: Rendered slides** (LibreOffice headless — preferred for diagrams).
Renders every slide to PNG, capturing shape-based diagrams, architecture
layouts, and network topologies exactly as they appear on screen.

- **Hidden slide check (required before rendering):** PPTX files may contain
  hidden slides (`show="0"` in `ppt/slides/slideN.xml`) that LibreOffice
  silently drops during export. Parse each slide XML first — if any have
  `show="0"`, create a temp copy with those attributes removed.
- **Rendering pipeline** (PNG export only renders slide 1; use PDF
  intermediary): `libreoffice --headless --convert-to pdf --outdir "$tmp"
  "$filepath"`, then render each PDF page to PNG via PyMuPDF.
- When both modes run, deduplicate: prefer the rendered-slide version when a
  diagram appears in both (it preserves slide context and surrounding labels).

**PDF files** — extract embedded images with page context via PyMuPDF:

```python
import fitz, os, tempfile
tmp = tempfile.mkdtemp(prefix="deck-intel-")
doc = fitz.open(filepath)
for page_num, page in enumerate(doc):
    for img_idx, img in enumerate(page.get_images(full=True)):
        xref = img[0]
        base_image = doc.extract_image(xref)
        out_path = os.path.join(tmp,
            f"page{page_num+1}-img{img_idx+1}.{base_image['ext']}")
        with open(out_path, "wb") as f:
            f.write(base_image["image"])
```

**Filter and classify.** View each extracted image with the Read tool. Filter
gate — auto-skip: images smaller than 50x50px (icons, bullets), solid fills
and gradient backgrounds. For rendered slides also skip: title slides,
agenda/TOC slides, text-heavy slides with no visual elements, "thank you" /
legal disclaimer slides (expect higher decorative ratios from rendered slides).

| Class | Criteria |
|---|---|
| **diagram** | Flowcharts, architecture diagrams, network topologies, process flows, sequence diagrams, state machines, org charts |
| **table** | Tabular data, comparison matrices, feature grids, pricing tables |
| **chart** | Bar/line/pie charts, scatter plots, gauges |
| **screenshot** | UI screenshots, terminal output, application windows |
| **decorative** | Stock photos, logos, gradient fills, section dividers — skip |

Present classification summary: "[N] images: [X] diagrams, [Y] tables,
[Z] screenshots, [W] decorative (skip)."

**Sensitivity check:** flag screenshots containing customer names, internal
metrics, proprietary dashboards, pricing, or PII with a `**Sensitivity:**`
warning — these require scrubbing or internal-only marking before moving to
a durable vault location.

Clean up the temp extraction directory when done.

**Preservation:** Save substantive images to `_attachments/` with filenames
keyed to the knowledge note: `[source_id]-fig[N].[ext]`. The knowledge note
embeds them inline with `![[source_id-fig1.png]]` and a brief text description
of what each diagram shows (components, architecture pattern, key relationships).

No Mermaid recreation — the preserved image is the artifact.

If PyMuPDF or LibreOffice are not available, skip image extraction and note
in the knowledge note: "Diagrams not extracted — missing dependencies."

### 5. Classify Source and Determine Intel Type

Categorize the source material:

| Source Type | Intel Focus | Tag Candidates |
|-------------|------------|----------------|
| Infoblox sales enablement | Product capabilities, positioning, talk tracks | `#kb/networking/dns`, `#kb/security`, `#kb/networking` |
| Infoblox product update / roadmap | New features, deprecations, timeline signals | `#kb/networking/dns`, `#kb/security` |
| Vendor/partner materials (Zscaler, Palo Alto, etc.) | Integration points, competitive positioning, architecture | `#kb/security`, `#kb/networking` |
| Competitive intel / analyst reports | Market positioning, strengths/weaknesses, gaps | `#kb/business`, `#kb/security` |

Confirm classification with user if ambiguous.

### 6. Synthesize Intelligence

Read the extracted content and produce a structured analysis. Apply aggressive
noise filtering — the goal is to reduce a 40-slide deck to 1-2 pages of
actionable content.

**Extraction categories (use all that apply):**

**Product / Technical Intelligence:**
- Specific capabilities (what it does, not marketing claims about what it enables)
- Architecture details (how it works, deployment model, integration points)
- Limitations or gaps (stated or implied)
- Version/release information and timeline signals

**Competitive Intelligence:**
- Direct competitive claims (with source attribution)
- Differentiation points (genuine technical differences, not just messaging)
- Pricing signals (if present — even vague ones like "premium tier" vs "included")
- Win/loss themes

**Customer-Facing Value:**
- Talk tracks worth adapting (not copying — adapt to your voice)
- Objection handling points with substance behind them
- Use cases with enough specificity to be credible
- Reference architectures or deployment patterns

**Actionable Items:**
- Things to follow up on (features to test, claims to verify, contacts to reach)
- Content gaps (what the deck should have covered but didn't)
- Expiration signals (time-bound claims, version-specific features)

**Noise to discard:**
- Generic value propositions ("transform your business", "accelerate your journey")
- Unsupported superlatives ("industry-leading", "best-in-class", "unmatched")
- Repetitive messaging across slides (capture once, discard duplicates)
- Org charts, legal disclaimers, boilerplate about/contact slides
- Stock photography descriptions

### 7. Produce Knowledge Note

Create a knowledge-note following the vault schema.

**Frontmatter:**

```yaml
---
project: null
domain: career
type: knowledge-note
skill_origin: deck-intel
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - kb/[primary-topic]           # at least one #kb/ tag from canonical list
campaign:                        # optional YAML list — include only if user specifies
  - campaign-name
schema_version: 1
source:
  source_id: [org]-[short-title] # kebab-case, max 60 chars, collision-checked
  title: "[Deck/Report Title]"
  author: "[Organization or Author]"
  source_type: other
  canonical_url: null
  date_ingested: YYYY-MM-DD
  queried_at: YYYY-MM-DD
  query_template: deck-intel-v1
note_type: digest
scope: whole
topics:
  - [moc-slug]                   # derived from kb tag via kb-to-topic.yaml
---
```

**Body structure:**

```markdown
# [Title] — [Organization]

**Source:** [filename] | **Type:** [classification] | **Slides/Pages:** [count]
**Processed:** [date] | **Confidence:** [high/medium/low]

## Key Intelligence

[Structured extraction from Step 6, organized by categories with content.
Not all categories will be present for every source.]

## Visual Content

[Embedded diagram images with descriptions. Only present if images were extracted.]

![[source_id-fig1.png]]
**Figure 1:** [What this diagram shows — components, architecture pattern, key relationships]

## Actionable Items

[Specific follow-ups, things to verify, content to adapt for customer work.
Each item should be concrete enough to act on without re-reading the source.]

## Shelf Life

**Duration:** [approximate validity period, e.g., "6-12 months"]
**Recheck triggers:** [specific events that would invalidate the intel]
**Expiration signals:** [time-bound claims identified during synthesis]

## Source Notes

[Anything noteworthy about the source itself — who presented it, context,
known biases or gaps, quality of the original material.]
```

### 8. File and Route

**Save** the knowledge note to `Sources/other/[source_id]-digest.md`.

**MOC routing:** Check `_system/docs/kb-to-topic.yaml` for MOC mapping. If the
primary `#kb/` tag maps to a MOC, append a one-liner to the MOC's Core section:
`- [[source_id-digest]] — one-line summary`. Before appending, check if a
wikilink to this note already exists (idempotency). Skip if already present.

No source-index note — one deck = one knowledge note.

**Enrichment workflow:** When deck-intel output corrects or deepens an existing
knowledge note (e.g., an internal CIS Controls mapping deck validates claims in
an existing `Sources/papers/` digest), update the existing note in place rather
than creating a separate artifact. Track the internal source in the existing
note's source metadata. The deck-intel note in `Sources/other/` still gets
created as the extraction record.

### 9. Deletion Safety Gate

Before deleting the source binary, verify ALL four checks pass:

1. **Extraction check:** markitdown returned > 200 characters of text content
   (or images were successfully extracted in visual-only mode)
2. **Write check:** Knowledge note was written successfully to `Sources/other/`
3. **Image check:** If images were extracted, verify they were written to
   `_attachments/` (skip this check if no substantive images were found)
4. **User confirmation:** Present summary and ask: "Delete source file? [Y/n]"

If ANY check fails, preserve the source binary in `_inbox/` and notify the user.

In batch mode, deletion confirmation happens per-file after each successful
synthesis, not as a batch operation.

### 10. Batch Cross-References

When processing multiple files covering related topics (e.g., two SASE vendor
decks), add a "Related Sources" section to each note with wikilinks to
overlapping notes. Note contradictions and complementary coverage.

### 11. Compound Check

If this extraction reveals a pattern worth capturing:
- Recurring gap in vendor materials → consider solution doc
- Reusable extraction template for a vendor's deck format → note for skill refinement
- Campaign-level insight spanning multiple sources → flag for user
- Vendor-specific quirks (e.g., "always buries technical details in notes") →
  pattern note in `_system/docs/solutions/`
- Diagram types where Mermaid recreation falls back frequently → track for skill tuning

## Standalone Visual Capture Mode

For direct invocations ("capture this diagram", "what's in this image") and
composable calls from inbox-processor — visual interpretation without the
deck-intel synthesis pipeline. Absorbed from the retired diagram-capture skill.

**Input handling:** Image files (JPEG, PNG, GIF, WEBP, TIFF) process directly —
no extraction. SVG: read the markup source as text; skip the vision step if
the structure is self-explanatory. PPTX/PDF: extract per Step 4 above.
Classify per the Step 4 table, then interpret. Present the classification
summary before interpreting.

**Interpretation by class** (unlike deck mode, standalone mode *recreates*
content rather than preserving images):

- **Diagrams → Mermaid:** identify diagram type (flowchart, sequence, state,
  C4, etc.); map all nodes/entities, relationships/arrows, labels, groupings;
  recreate in the closest matching Mermaid type; validate syntax before
  outputting. Complexity gate: >30 nodes or heavily styled/3D layout → fall
  back to structured text description and flag the fallback.
- **Tables → Markdown:** all rows, columns, headers, cell values as a GFM
  pipe table; preserve alignment and header rows; mark ambiguous cells `[unclear]`.
- **Charts → Data + description:** extract data series as a markdown table
  (approximate values from visual); describe the trend or comparison; note
  chart type, axis labels, units.
- **Screenshots → Description:** what's shown (application, feature area,
  state), all visible text, product/version if identifiable. Apply the
  sensitivity check from Step 4.
- **Other → structured description** of content and apparent purpose.

Every interpretation carries a confidence rating (high/medium/low) and uses
`[unclear]` for ambiguous content — no hallucinated fills.

**Standalone output:** create `[source-stem]-visual-capture.md` alongside the
source — header with source filename, image counts, capture date; one section
per image with classification label, the interpretation (Mermaid block /
table / description), location (page/slide/direct file), confidence, and
caveats. If the source is in a transient location (`_inbox/`, `/tmp/`), add a
durability advisory: move to `_attachments/` or embed in a knowledge note for
permanent reference. The skill flags but does not route.

**Composable output** (called mid-procedure from another skill): return
interpretations as structured content — do not create a separate file. From
inbox-processor: content goes in a `## Visual Content` section of the
companion note (after `## Extracted Content` or `## Notes`).

## Context Contract

**MUST have:**
- The PPTX or PDF file(s) to process (in `_inbox/` or user-specified path)
- User confirmation of source classification (Step 5)

**MAY request:**
- Customer-intelligence dossier context (if processing for a specific account)
- Network Skills overlay source catalog (if networking content)
- Previous deck-intel notes for the same vendor (for delta/change detection)
- `kb-to-topic.yaml` for MOC routing

**AVOID:**
- Loading full design spec for routine extraction
- Loading unrelated project contexts
- Loading the source PPTX/PDF into context when markitdown extraction is sufficient

**Typical budget:** Standard tier (2-4 docs). Extended only when cross-referencing
multiple prior extractions for the same vendor/topic.

## Output Constraints

- Knowledge notes follow the body structure defined in Step 7 — no deviation
- source_id follows kebab-case algorithm: `kebab(org + short-title)`, max 60 chars
- Every note has at least one `#kb/` tag from the canonical tag list
- `campaign:` is an optional YAML list in frontmatter (not a tag)
- Shelf Life section is mandatory with duration, recheck triggers, and expiration signals
- Do not reproduce slide content verbatim beyond short identifying phrases — synthesize
- Actionable Items must be concrete and specific, not "follow up on this"
- Confidence rating (high/medium/low) is mandatory and reflects extraction quality
- No source-index notes — one deck = one knowledge note
- Deck mode: diagrams preserved as images in `_attachments/`, not recreated in Mermaid
- Standalone visual capture: Mermaid blocks syntactically valid; every
  interpretation has a confidence rating; `[unclear]` for ambiguous content;
  output file lives alongside the source; durability advisory for transient
  locations; >30-node diagrams fall back to text with explicit flag

## Output Quality Checklist

Before marking complete, verify:
- [ ] Frontmatter conforms to knowledge-note schema
- [ ] At least one `#kb/` tag from canonical tag list
- [ ] `campaign:` field is YAML list (if present)
- [ ] source_id is unique (checked against existing Sources/ files)
- [ ] Key Intelligence section contains no marketing fluff
- [ ] Actionable Items are specific enough to act on without re-reading source
- [ ] Shelf Life section has duration, recheck triggers, and expiration signals
- [ ] Source Notes section records provenance and known biases
- [ ] File saved to Sources/other/ with `[source_id]-digest.md` naming
- [ ] Substantive images saved to `_attachments/` with `[source_id]-fig[N].[ext]` naming
- [ ] Images embedded inline in knowledge note with descriptions
- [ ] MOC one-liner added if kb tag maps to a built MOC (idempotent)
- [ ] Deletion safety gate passed all 4 checks before binary removal
- [ ] No source-index note created

## Compound Behavior

Extraction patterns and vendor-specific quirks feed the compound system. If a
vendor consistently buries technical details in slide notes while putting
marketing on the slides, capture that as a pattern note in
`_system/docs/solutions/` so future extractions prioritize notes over slide content.

## Convergence Dimensions

1. **Signal-to-noise ratio:** Is the extraction meaningfully shorter than the
   source while preserving all actionable content?
2. **Actionability:** Can someone use the Actionable Items section without going
   back to the original deck?
3. **Shelf life accuracy:** Are the expiration signals specific and realistic?
4. **Cross-reference quality:** When multiple sources cover the same topic, are
   contradictions and overlaps surfaced?
5. **Image preservation:** Are substantive diagrams captured and described?
6. **Visual capture fidelity** (standalone mode): Do Mermaid recreations
   preserve structural relationships and labels; do tables preserve all
   visible data; are substantive images never mis-classified as decorative?
