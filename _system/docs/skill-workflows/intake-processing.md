---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Intake & Processing Pipeline

Covers the four skills that move raw content into the vault: a general inbox processor, a visual content extractor, a presentation intelligence extractor, and a feed intel promoter.

## Skills in This Workflow

### /inbox-processor
**Invoke:** "process inbox", "check inbox", "orphan sweep", or at session startup when `_inbox/` has files
**Inputs:** Files in `_inbox/` (markdown, PDF, DOCX, PPTX, XLSX, images); requires `markitdown` + `exiftool`
**Outputs:** Classified markdown with frontmatter → destination vault path; companion notes for binaries; knowledge-notes + source-index notes for NLM exports
**What happens:**
- Scans and classifies all inbox files; prompts for domain, tags, project affiliation
- Creates companion notes (with extracted content) for binaries before moving them
- NLM exports get full knowledge-note treatment: sentinel detection, dedup check, kb/ tagging, MOC Core placement

### /diagram-capture
**Invoke:** "capture this diagram", "extract images from", "interpret this image"
**Inputs:** PPTX, PDF, or image file (JPEG, PNG, etc.); optionally requires PyMuPDF and LibreOffice for full extraction
**Outputs:** Standalone `[source-stem]-visual-capture.md` alongside the source (standalone mode), or structured content returned inline (composable mode)
**What happens:**
- Extracts embedded images from PPTX/PDF; renders full slides via LibreOffice when available
- Classifies each image (diagram, table, chart, screenshot, decorative) and skips decorative/tiny images
- Produces Mermaid code for diagrams, markdown tables for tabular content, structured descriptions for others

### /deck-intel
**Invoke:** "process this deck", "extract intel from", "what's useful in this presentation"
**Inputs:** PPTX or PDF files (sales enablement, vendor materials, analyst reports); requires `markitdown`
**Outputs:** Knowledge-note in `Sources/other/[source_id]-digest.md` + source-index note; MOC one-liner
**What happens:**
- Extracts text + speaker notes via markitdown; classifies source type (sales enablement, competitive intel, etc.)
- Applies aggressive noise filtering — reduces a 40-slide deck to 1-2 pages of actionable content
- Produces structured sections: Key Intelligence, Actionable Items, Shelf Life, Source Notes

### /feed-pipeline
**Invoke:** "process feed items", "feed pipeline", "promote inbox items", "clear feed backlog"
**Inputs:** `_openclaw/inbox/feed-intel-*.md` files from FIF; optionally FIF SQLite DB for dashboard-queued promotions
**Outputs:** Signal-notes in `Sources/signals/`; action items appended to project run-logs; review-queue file for borderline items
**What happens:**
- Checks dashboard_actions table for operator-flagged promotions first (Step 0), then scans inbox
- Tiers items: Tier 1 (high priority + high confidence + capture) → auto-promote or review queue; Tier 2 → extract action to run-log; Tier 3 → TTL expiry
- Auto-promoted items get full signal-note frontmatter, MOC Core placement, and cross-posting to relevant project run-logs

## How They Compose

**inbox-processor** is the general entry point for anything dropped in `_inbox/`. It handles the full file lifecycle — classification, frontmatter, routing, and companion notes for binaries.

**diagram-capture** is a composable sub-skill called by inbox-processor (for image files and image-heavy binaries) and by deck-intel (for image-heavy slide content). It can also be invoked directly when the user points at a specific file for visual extraction.

**deck-intel** specializes inbox-processor's binary handling path for presentations and reports. Use deck-intel when the goal is intelligence extraction (structured analysis, shelf life, actionable items); use inbox-processor when the goal is cataloguing (companion note, searchability, routing to the right project).

**feed-pipeline** operates on a separate inbox (`_openclaw/inbox/`) fed by the FIF automation pipeline. It is not triggered by manual file drops — it processes pre-triaged feed items and bridges them into the vault KB.
