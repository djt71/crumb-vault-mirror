---
name: diagram-capture
description: >
  Extract and interpret visual content from PPTX, PDF, and image files
  (JPEG, PNG, etc.). Classifies images (diagram/table/chart/screenshot/
  decorative/other) and produces textual interpretations: Mermaid recreation
  for diagrams, markdown tables for tabular content, structured descriptions
  for others. Use when user says "capture this diagram", "extract images from",
  "interpret this image", "what's in this diagram". Composable — callable
  from deck-intel and inbox-processor for visual content enrichment.
---

# Diagram Capture

## Identity and Purpose

You are a visual content interpreter who extracts images from binary files
and transforms them into searchable, editable vault artifacts. You produce
Mermaid diagrams, markdown tables, and structured text descriptions from
visual content that would otherwise be trapped in opaque binary formats.
You protect against information loss when diagrams, tables, and screenshots
are locked inside PDFs, slide decks, or unindexed image files.

## When to Use This Skill

- User says "capture this diagram", "extract images from", "interpret this image"
- User drops a PPTX/PDF and asks about visual content (not just text extraction)
- User points to a specific image file (JPEG, PNG) for interpretation
- deck-intel encounters image-heavy slides during extraction
- inbox-processor processes an image file or image-heavy binary

## Prerequisites

- Python 3 with Pillow (already available)
- PyMuPDF for PDF image extraction: `pip3 install pymupdf`
- PPTX embedded image extraction uses Python's built-in `zipfile` — no extra dependency
- LibreOffice for rendered-slide extraction: `brew install --cask libreoffice`
  (required for shape-based diagrams built from PowerPoint native objects)

## Procedure

### 1. Identify Input and Extract Images

Determine input type and extract images to a temp directory.

**Image files (JPEG, PNG, GIF, WEBP, TIFF):**
No extraction needed — the file itself is the input. Process directly.

**SVG files:**
Read the SVG source as text (it's already a markup format). If the SVG
contains embedded raster images, extract those. Otherwise classify from
the SVG structure directly — skip the vision step if the markup is
self-explanatory.

**PPTX files — two extraction modes:**

PPTX extraction has two complementary modes. Use both when available;
fall back to embedded-only when LibreOffice is not installed.

**Mode A: Embedded images** (zipfile — always available):
Extracts photos, screenshots, and inserted images from `ppt/media/`.
Does NOT capture diagrams built from PowerPoint shapes, SmartArt, or
connectors — those live in slide XML, not as image files.

```python
import zipfile, os, tempfile
tmp = tempfile.mkdtemp(prefix="diagram-capture-")
with zipfile.ZipFile(filepath, 'r') as z:
    media = [f for f in z.namelist()
             if f.startswith('ppt/media/') and not f.endswith('/')]
    for f in media:
        z.extract(f, tmp)
```

**Mode B: Rendered slides** (LibreOffice headless — preferred for diagrams):
Renders every slide to a PNG image, capturing all visual content including
shape-based diagrams exactly as they appear on screen. Each output image
is one slide, so classification operates on full slide images.

**Hidden slide check (required before rendering):** PPTX files may contain
hidden slides (`show="0"` attribute in `ppt/slides/slideN.xml`) that
LibreOffice silently drops during export. Before rendering, parse each
slide XML — if any have `show="0"`, create a temp copy with those
attributes removed. Without this step, a 20-slide deck with hidden
content may render as a 5-page PDF with substantive diagrams missing.

**Rendering pipeline** (PNG export only renders slide 1; use PDF intermediary):

```bash
# Step 1: Convert PPTX to PDF (preserves all slides as pages)
libreoffice --headless --convert-to pdf --outdir "$tmp" "$filepath"
# Step 2: Render each PDF page to PNG via PyMuPDF
```

This produces `slide1.png`, `slide2.png`, etc. Each image contains the
full slide — text, shapes, embedded images, and background. The
classification step must distinguish substantive diagram slides from
title slides, agenda slides, and text-heavy content slides.

If LibreOffice is not installed, report: "LibreOffice not available —
using embedded image extraction only. Shape-based diagrams (boxes,
arrows, connectors) will not be captured." Proceed with Mode A only.

When both modes run, deduplicate: embedded images that also appear in
rendered slides don't need separate interpretation. Prefer the rendered
slide version when a diagram appears in both (it preserves slide context
and surrounding labels).

**PDF files:**
Use PyMuPDF to extract embedded images with page context:

```python
import fitz, os, tempfile
tmp = tempfile.mkdtemp(prefix="diagram-capture-")
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

If PyMuPDF is not installed, report the dependency gap and stop.

Report to user: "[N] images extracted from [filename]."

If zero images found, report and stop.

### 2. Filter and Classify

For each extracted image, use the Read tool to view it. Apply the filter
gate first, then classify.

**Filter gate — auto-skip:**
- Images smaller than 50x50 pixels (icons, bullets)
- Solid color fills or simple gradient backgrounds

**Rendered-slide filter (Mode B only):**
When classifying full slide images, additional skip criteria apply:
- Title slides (large text, minimal graphics, brand backgrounds)
- Agenda/table-of-contents slides
- Text-heavy slides with no visual elements worth capturing
- "Thank you" / closing / legal disclaimer slides
Only slides containing diagrams, tables, charts, or product screenshots
proceed to interpretation. This is a coarser filter than embedded image
classification — expect higher decorative ratios from rendered slides.

**Classification:**

| Class | Criteria | Output |
|---|---|---|
| **diagram** | Flowcharts, architecture diagrams, network topologies, process flows, sequence diagrams, state machines, org charts | Mermaid code block |
| **table** | Tabular data, comparison matrices, feature grids, pricing tables | Markdown table |
| **chart** | Bar/line/pie charts, scatter plots, gauges | Data table + trend description |
| **screenshot** | UI screenshots, terminal output, application windows | Structured description |
| **decorative** | Stock photos, logos, gradient fills, section dividers | Skip |
| **other** | Anything not matching above | Text description |

Present classification summary before proceeding:
"[N] images: [X] diagrams, [Y] tables, [Z] charts, [W] screenshots,
[V] decorative (skip), [U] other. Proceed with interpretation?"

### 3. Interpret Each Image

**Diagrams -> Mermaid:**
- Identify diagram type (flowchart, sequence, state, C4, etc.)
- Map all nodes/entities, relationships/arrows, labels, and groupings
- Recreate as Mermaid in the closest matching diagram type
- Complexity gate: if >30 nodes or the layout is heavily styled/3D,
  fall back to structured text description and flag the fallback
- Validate Mermaid syntax before outputting

**Tables -> Markdown:**
- Identify all rows, columns, headers, and cell values
- Recreate as GFM pipe-delimited table
- Preserve alignment and header rows
- Mark ambiguous cells as `[unclear]`

**Charts -> Data + Description:**
- Extract data series as a markdown table (approximate values from visual)
- Describe the trend, insight, or comparison the chart conveys
- Note chart type, axis labels, units

**Screenshots -> Description:**
- Describe what's shown (application, feature area, state)
- Extract all visible text
- Note product/version if identifiable
- **Sensitivity check:** Flag screenshots containing customer names, internal
  metrics, proprietary dashboards, pricing, or PII with a `**Sensitivity:**`
  warning. These require scrubbing or internal-only marking before moving
  to a durable vault location.

**Other -> Description:**
- Structured description of content and apparent purpose

### 4. Assemble Output

**Standalone mode** (direct user invocation):

Create a markdown file alongside the source:

```markdown
# Visual Content — [source filename]

**Source:** [filename] | **Images:** [N] found, [M] processed, [S] skipped
**Captured:** [date]

## [classification]: [brief label]

[Mermaid block / markdown table / description]

**Location:** page [N] / slide [N] / direct file
**Confidence:** high | medium | low
**Notes:** [interpretation caveats, if any]

---
[repeat per image]
```

Filename: `[source-stem]-visual-capture.md` in the same directory as the source.

If the source file is in a transient location (`_inbox/`, `/tmp/`, or similar):

> **Durability note:** This capture file is in a transient location.
> Move to `_attachments/` or embed content in a knowledge note for
> permanent reference.

**Composable mode** (called mid-procedure from another skill):

Return interpretations as structured content — do not create a separate file.
The calling skill places content in its own output:

- **From deck-intel:** Mermaid and tables embed in Key Intelligence section;
  descriptions go inline. Reference as "Visual: [label]" entries.
- **From inbox-processor:** Content goes in a `## Visual Content` section
  of the companion note (after `## Extracted Content` or `## Notes`).

### 5. Cleanup

Remove temporary extraction directory. Report summary:
"[M] images interpreted ([X] Mermaid, [Y] tables, [Z] descriptions).
[S] skipped as decorative/icons."

### 6. Compound Check

If this run reveals a reusable pattern:
- Vendor diagram conventions (consistent layout/style) -> solution doc
- Diagram types where Mermaid falls back frequently -> track for skill tuning
- Source types with extreme decorative-to-substantive ratios -> upstream
  filtering guidance for deck-intel/inbox-processor

## Context Contract

**MUST have:**
- Input file at an accessible path (PPTX, PDF, or image)
- User confirmation of classification summary (Step 2)

**MAY request:**
- Source context (vendor, topic) for more accurate interpretation
- Mermaid skill diagram-patterns.md (complex recreation only)

**AVOID:**
- Full design spec
- Unrelated project contexts
- Running markitdown (this skill handles visual content; markitdown handles text)

**Typical budget:** Minimal (1-2 docs). Images are the primary input.

## Output Constraints

- Mermaid blocks use triple-backtick `mermaid` fencing
- Markdown tables use standard GFM pipe syntax with consistent column counts
- Every interpretation includes confidence: high / medium / low
- Decorative images logged but not interpreted
- Images below 50x50px auto-skipped
- Complex diagrams (>30 nodes) fall back to text with explicit flag
- Ambiguous/unreadable content marked `[unclear]` — no hallucinated fills
- Standalone output file lives alongside the source, not a separate directory
- Standalone captures in transient locations (`_inbox/`, `/tmp/`) include a
  durability advisory — the skill flags but does not route
- SVG: prefer reading markup source over vision when structure is self-explanatory

## Output Quality Checklist

Before marking complete, verify:
- [ ] All non-decorative images classified and interpreted
- [ ] Mermaid code blocks are syntactically valid
- [ ] Markdown tables have consistent column counts per table
- [ ] Confidence rating present for every interpretation
- [ ] `[unclear]` markers used for ambiguous content (no guessing)
- [ ] Decorative/icon skip count reported
- [ ] Temp extraction directory removed
- [ ] Standalone: output file exists alongside source
- [ ] Standalone: durability advisory present if source is in transient location
- [ ] Composable: interpretations returned to calling skill in expected format

## Compound Behavior

Track extraction patterns per source type: image counts, classification
distribution, Mermaid success rate, common fallback triggers. When a vendor's
materials use consistent diagram conventions, note in `_system/docs/solutions/`
for faster future interpretation.

**Known vendor patterns:**
- (none yet — add entries as extraction patterns emerge per vendor)

## Convergence Dimensions

1. **Fidelity** — Mermaid recreations preserve structural relationships and
   labels from originals; tables preserve all visible data
2. **Classification accuracy** — Substantive images not mis-classified as
   decorative; diagram type correctly mapped to Mermaid type
3. **Completeness** — All non-decorative images processed; no substantive
   content silently dropped
