---
project: deck-intel
domain: software
type: specification
skill_origin: systems-analyst
status: draft
created: 2026-03-03
updated: 2026-03-14
tags:
  - specification
  - skill-build
  - customer-engagement
---

# Deck Intel — Specification

## Problem Statement

Vendor presentations and PDF reports contain valuable intelligence (product capabilities, competitive differentiators, architecture details, pricing signals, roadmap items) buried in 30-60 slides of marketing noise. This material is consumed once — in a meeting or email — and never structured for retrieval. When campaign prep or customer engagement requires that intelligence weeks later, it's effectively lost. The vault has a knowledge-note system designed exactly for this, but no ingestion path exists for slide decks and reports.

## Why This Matters

Danny processes vendor materials, internal enablement decks, and analyst reports regularly as part of presales SE work across ~25 accounts. The customer-intelligence project (active, ACT phase) provides the dossier structure but has no automated way to ingest raw vendor/product materials into the knowledge graph. The current workflow is: read deck → remember what mattered → forget the specifics. A skill that bridges raw deck → structured knowledge note closes this gap.

## Facts

- **markitdown** is available and extracts text + speaker notes from PPTX and text from PDF. Already used by inbox-processor.
- **Knowledge-note schema** (spec §2.2.4) is the target output format. Well-defined, vault-check validated.
- **`Sources/other/`** is the correct directory for presentations and reports (`source_type: other`).
- **`kb-to-topic.yaml`** provides MOC routing from `#kb/` tags to domain MOCs.
- **Inbox-processor** handles generic binary intake (companion notes, file routing). Deck-intel is a different tool — it synthesizes, it doesn't just catalog.
- **Customer-intelligence dossiers** are the primary downstream consumer, connected via shared `#kb/` tags (manual linkage).
- **exiftool** is available but not needed — deck-intel processes text content, not metadata.

## Assumptions

- **A1:** markitdown extraction quality is sufficient for most PPTX/PDF files. Image-heavy PDFs may need fallback handling (flag to user). *Validation: test with 3-5 real decks in first session.*
- **A2:** Speaker notes in PPTX files contain higher-value content than slide body text in most vendor enablement materials. *Validation: compare extraction output across sample files.*
- **A3:** One knowledge note per source deck is the right granularity. Multi-chapter digests (as used for books) are unnecessary for presentations. *Validation: review after 10+ extractions — if notes are too long, consider splitting.*
- **A4:** Deleting source binaries after synthesis is acceptable — the knowledge note captures all recoverable value, and the original deck is available from the source (email, portal, SharePoint). *Validation: user decision — confirmed.*

## Unknowns

- **U1:** How well does markitdown handle Infoblox-specific deck templates? Some internal decks use complex SmartArt and embedded charts that may not extract cleanly.
- **U2:** What's the realistic throughput? A 40-slide deck probably takes 5-10 minutes of model time for quality synthesis. Batch processing needs a practical ceiling.
- **U3:** Will `Sources/other/` become crowded? Currently empty. After 50+ extractions it may need subdirectory organization (by vendor, by topic).

## System Map

### Components

```
[PPTX/PDF in _inbox/]
        │
        ▼
  ┌─────────────┐     ┌──────────────────┐
  │  markitdown  │────▶│  deck-intel skill │
  │  (extraction)│     │  (synthesis)      │
  └─────────────┘     └────────┬─────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
     ┌────────────┐   ┌──────────────┐   ┌──────────┐
     │ Knowledge   │   │ MOC one-liner│   │ Source    │
     │ note in     │   │ (if kb tag   │   │ binary   │
     │ Sources/    │   │  has MOC)    │   │ deleted  │
     │ other/      │   └──────────────┘   └──────────┘
     └────────────┘
```

### Dependencies

- **Upstream:** markitdown CLI (extraction), user provides source files in `_inbox/`
- **Downstream:** Customer-intelligence dossiers consume intel via `#kb/` tag queries; MOCs link via one-liners
- **Parallel:** Inbox-processor handles the same file types but for different purpose (cataloging vs. synthesis). No conflict — deck-intel is invoked explicitly by the user on specific files (by path or "process this deck"). It does not scan `_inbox/` automatically. Inbox-processor is invoked separately ("process inbox"). Neither auto-triggers; both require explicit user invocation.

### Constraints

- **Context window:** Each deck extraction + synthesis consumes significant context. Batch processing needs a ceiling (recommend 3-5 files per session).
- **No binary storage:** Source PPTX/PDF is deleted from `_inbox/` after successful synthesis. The knowledge note is the durable artifact.
- **No companion notes:** Unlike inbox-processor, deck-intel does not create companion notes or route binaries to attachment directories.
- **No source-index notes:** Source-index notes aggregate multiple child knowledge notes for a single source (e.g., book chapters). A single deck = a single knowledge note. Source-index creation is unnecessary and would add ceremony for no value.
- **Schema compliance:** Output must pass vault-check for `type: knowledge-note` frontmatter validation.

### Levers

- **Noise filtering quality** is the highest-impact lever. The difference between a useful knowledge note and a useless one is how aggressively marketing fluff is stripped while retaining genuine technical/competitive substance.
- **Shelf Life section** is the second lever. Intel without expiration signals becomes stale without warning.

### Second-Order Effects

- Accumulated deck-intel notes create a searchable competitive intelligence corpus across vendors — value compounds over time.
- If extraction quality is high, this could replace or supplement some Glean AI report content currently feeding CI dossiers.
- Vendor-specific extraction patterns (e.g., "Infoblox always buries the technical details in notes") become reusable compound patterns.

## Key Design Decisions

### D1: Campaign Tracking via Frontmatter Field

Campaign context is tracked as an **optional frontmatter list field** (`campaign:`), not a tag namespace. This avoids creating a new tag taxonomy, keeps vault-check simple, and is Dataview-queryable. Campaign names are freeform strings. A list supports multi-campaign tagging (a deck may be relevant to more than one campaign).

```yaml
campaign:
  - sase-competitive-q2-2026
  - zscaler-displacement
```

### D2: Synthesis Only — No Binary Management

The skill extracts text via markitdown, synthesizes a knowledge note, and **deletes the source binary** from `_inbox/` after passing a safety gate. No companion note, no binary routing. The knowledge note is the sole durable text artifact. The original file is recoverable from its source (email, vendor portal, internal system). Substantive diagrams and images are preserved separately (see D6).

**Deletion safety gate (required before binary removal):**
1. markitdown extraction returned non-trivial content (> 200 characters)
2. Knowledge note was written successfully to `Sources/other/`
3. User confirms deletion ("Delete source file? [Y/n]")

If any check fails, the source binary stays in `_inbox/`. In batch mode, deletion confirmation happens per-file after each successful synthesis, not as a batch operation.

### D3: Manual CI Linkage

Deck-intel notes connect to customer-intelligence dossiers through shared `#kb/` tags, not automatic cross-referencing. The user applies intel to specific accounts during campaign prep. This keeps the skill focused and avoids noisy automatic linking.

### D4: No Source-Index Notes

Source-index notes exist for multi-note sources (books with chapter digests). A single presentation = a single knowledge note. No index layer needed.

### D5: model_tier: reasoning

The synthesis step requires judgment — distinguishing genuine technical detail from marketing claims, identifying competitive signals, assessing shelf life. This is reasoning-tier work, not mechanical execution.

### D6: Diagram and Image Preservation

Technical decks contain diagrams (architecture diagrams, network topologies, deployment layouts, data flows) whose visual structure carries meaning that text extraction cannot capture. These are preserved as image files alongside the knowledge note.

**Extraction:** The diagram-capture skill runs in composable mode to extract images from the source file (PPTX embedded images + rendered slides via LibreOffice, or PDF embedded images via PyMuPDF). Images are classified (diagram/table/chart/screenshot/decorative) and filtered (decorative and icons skipped).

**Preservation:** Substantive images (diagrams, charts, screenshots with product detail) are saved to `_attachments/` with filenames keyed to the knowledge note: `[source_id]-fig[N].[ext]`. The knowledge note embeds them inline with `![[source_id-fig1.png]]` and a brief text description of what each diagram shows (components, architecture pattern, key relationships). No Mermaid recreation — the preserved image is the artifact.

**Image-heavy fallback:** When markitdown returns < 200 characters, the content is primarily visual. Flag to user: "This file is mostly diagrams/images. Extracting visuals only — no text synthesis." Run diagram-capture, preserve images with descriptions, skip the text synthesis step. The knowledge note becomes a visual catalog with descriptions rather than a text digest.

**Deletion gate update:** The binary deletion safety gate (D2) includes an additional check: if images were extracted, verify they were written to `_attachments/` before confirming deletion.

### D7: Extraction Error Handling

If markitdown exits non-zero, returns empty output, or returns < 200 characters of content: halt processing for that file, notify user with the error details, and do not delete the source binary. In batch mode: skip the failed file, continue processing remaining files, and report all failures in the batch summary. The source binary is preserved for retry or manual inspection.

### D8: MOC One-Liner Placement

When the knowledge note's primary `#kb/` tag maps to a MOC via `kb-to-topic.yaml`, append a one-liner to the MOC's Core section: `- [[source-id-digest]] — one-line summary of the intel`. Before appending, check if a wikilink to this note already exists in the MOC (idempotency). Skip if already present. This matches the existing MOC placement behavior used by source-index notes and the batch book pipeline.

### D9: Knowledge Note Filename Convention

The output filename follows the `source_id` algorithm from §2.2.4: `[source_id]-digest.md` in `Sources/other/`. Example: `zscaler-sase-architecture-2026-digest.md`. The `source_id` is derived from `kebab(org-or-author + short-title)`, max 60 chars, with collision detection against existing `Sources/` files.

### D10: Shelf Life Format

The Shelf Life section is a free-text body section (not a frontmatter field) containing:
- **Duration estimate:** approximate validity period (e.g., "6-12 months")
- **Recheck triggers:** specific events that would invalidate the intel (e.g., "next product release", "vendor FY26 pricing update", "competitor GA announcement")
- **Expiration signals:** time-bound claims identified during synthesis (e.g., "roadmap item targets Q3 2026", "preview feature — may change before GA")

Structured frontmatter representation deferred until patterns emerge from initial extractions.

## Domain Classification & Workflow Depth

- **Domain:** software (building a Crumb skill)
- **Workflow:** SPECIFY → PLAN → TASK → IMPLEMENT (full four-phase)
- **Rationale:** This is a new skill with schema integration, extraction pipeline, and knowledge-graph routing. It touches spec-governed artifacts (knowledge notes, MOC integration) and needs acceptance testing against real files.

## Task Decomposition

### DI-001: Write SKILL.md
- **Type:** `#code`
- **Risk:** low
- **Scope:** Create `.claude/skills/deck-intel/SKILL.md` based on the draft input, incorporating specification decisions (D1-D10) and schema compliance requirements.
- **Acceptance criteria:**
  - Skill file follows skill authoring conventions
  - Procedure steps are clear and sequential
  - Context contract specifies budget tiers
  - Output constraints reference spec §2.2.4 schema
  - `campaign` field documented as optional frontmatter list
  - Deletion safety gate (D2) implemented as explicit step
  - Extraction error handling (D7) covers failure paths
  - MOC one-liner placement (D8) with idempotency check
  - Filename follows source_id convention (D9)
  - Shelf Life format (D10) specified in output template
  - Batch processing ceiling documented (3-5 files)
- **Files changed:** 1 (new file)

### DI-002: Update Overlay Index
- **Type:** `#code`
- **Risk:** low
- **Scope:** No new overlay needed. Verify existing overlay activation signals cover deck-intel's use cases (Business Advisor for competitive intel, Network Skills for networking content). No changes expected — deck-intel routes via `#kb/` tags to overlays, not via custom activation.
- **Acceptance criteria:**
  - Confirm no overlay index changes needed (or make minimal additions if gaps found)
- **Files changed:** 0-1

### DI-003: Validate with Real PPTX
- **Type:** `#test`
- **Risk:** medium
- **Scope:** Process a real PPTX file through the skill. Validate: markitdown extraction quality, speaker note capture, knowledge note schema compliance, MOC routing, source binary deletion.
- **Acceptance criteria:**
  - Knowledge note passes vault-check
  - Speaker notes captured in extraction
  - Noise filtering produces meaningfully shorter output than input
  - Shelf Life section includes duration, recheck triggers, and expiration signals
  - Deletion safety gate fires: extraction check + write check + user confirmation
  - Source binary deleted from `_inbox/` only after gate passes
  - Extraction failure path tested (if applicable): binary preserved, user notified
- **Dependencies:** DI-001
- **Files changed:** 1-2 (knowledge note + possible MOC update)

### DI-004: Validate with Real PDF
- **Type:** `#test`
- **Risk:** medium
- **Scope:** Process a real PDF file. Validate same criteria as DI-003, plus: diagram/image preservation and image-heavy fallback if applicable.
- **Acceptance criteria:**
  - Same as DI-003
  - Substantive diagrams extracted and saved to `_attachments/` with correct naming
  - Knowledge note embeds preserved images inline with text descriptions
  - Image-heavy PDF detection (< 200 chars from markitdown) triggers visual-only mode
  - Error handling: if markitdown fails, binary preserved and user notified
- **Dependencies:** DI-001
- **Files changed:** 1-2

### DI-005: Batch Processing Test
- **Type:** `#test`
- **Risk:** low
- **Scope:** Process 2-3 files in a single session. Validate: classification summary table before extraction, cross-reference notes between related sources, batch ceiling respected.
- **Acceptance criteria:**
  - Classification summary presented before full extraction
  - Cross-references noted when sources overlap
  - Context remains manageable (no degradation)
- **Dependencies:** DI-003, DI-004
- **Files changed:** 2-4

## Relationship to Existing Systems

### vs. Inbox-Processor
Inbox-processor is a generic file intake tool — it creates companion notes and routes binaries. Deck-intel is a synthesis tool — it produces structured intelligence and discards the source. They serve different purposes and never conflict. A user who wants to *keep* the binary and just catalog it uses inbox-processor. A user who wants to *extract the value* and discard the noise uses deck-intel.

### vs. Customer-Intelligence Dossiers
CI dossiers are the downstream consumer. Deck-intel feeds the knowledge graph with vendor/product/competitive intel tagged with `#kb/` topics. When a user prepares for a customer meeting, they query by `#kb/` tag and find both CI dossier content and deck-intel knowledge notes. The connection is through the shared taxonomy, not direct links.

### vs. Feed Pipeline
Feed pipeline processes social/news items into signal notes. Deck-intel processes presentation files into knowledge notes. Different input types, different output schemas, no overlap.

## Open Questions for PLAN Phase

- **Q1:** Should the knowledge note body structure be identical to the draft's proposal (Key Intelligence → Actionable Items → Shelf Life → Source Notes), or should it align more closely with the standard knowledge-note body structure from the NLM pipeline?
- **Q2:** After 50+ notes accumulate in `Sources/other/`, should we introduce subdirectories (by vendor, by year) or rely on tags/search for navigation?
