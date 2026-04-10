---
project: batch-book-pipeline
domain: learning
type: summary
skill_origin: systems-analyst
source_updated: 2026-02-28
created: 2026-02-28
updated: 2026-02-28
tags:
  - knowledge-management
  - batch-processing
  - gemini
  - pipeline
---

# Specification Summary — Batch Book Pipeline

## Core Content

A batch processing pipeline to convert ~100 books (PDFs) into structured knowledge notes, bypassing NotebookLM's manual one-at-a-time bottleneck. Each book is processed through **three templates** — book-digest-v2 (nonfiction whole-book digest), fiction-digest-v1 (fiction whole-book digest), and chapter-digest-v1 (chapter-by-chapter breakdown) — run as **separate batch processes** for independent review. Genre classification is manual — the user sorts PDFs into `nonfiction/` and `fiction/` subdirectories. The pipeline sends PDFs directly to the Gemini API, generates proper knowledge-note frontmatter (source_id, `#kb/` tags, schema_version), and writes output to `Sources/books/`. Each book produces two output files: `[source_id]-digest.md` and `[source_id]-chapter-digest.md`, using the same `source_id`-based naming as the inbox-processor.

The pipeline has two execution modes: **standard** (sequential, immediate results for validation batches) and **batch** (`--batch-api submit`/`collect`, fire-and-forget for full runs via Gemini Batch API at 50% cost discount). A Python script in `_system/scripts/batch-book-pipeline/` handles: PDF pre-flight check (text extractability via pypdf), input dedup (PDF file hash manifest), Gemini File API upload, prompt dispatch, structured metadata parsing (title/author/tags from YAML block), output dedup (source_id against existing notes), tag validation against canonical `#kb/` list, knowledge-note frontmatter generation (`skill_origin: batch-book-pipeline`, `scope: whole`, `query_template` per adapted prompt — `notebooklm_notebook` omitted), file writing with source_id-based naming, per-book JSONL telemetry, and rate limiting with resume capability.

Model choice is **Gemini 3.1 Pro** (`gemini-3.1-pro-preview`) — the exact model NLM currently runs, quality validated in BBP-001. Native PDF upload, 1M token context. PDFs tokenize at **560 tokens/page** (validated). Batch API cost estimate: ~$40-50 for 300pp avg books.

## Key Decisions

- **Model:** Gemini 3.1 Pro — exact match to NLM, quality validated across all 3 templates in BBP-001
- **Batch API primary:** Fire-and-forget overnight processing for full runs (BBP-006). 50% cost discount. Standard API for validation batches only.
- **No NLM in the loop** — direct API calls eliminate the manual interaction bottleneck entirely
- **No sentinels** — output written directly to Sources/ with proper frontmatter, bypassing inbox-processor
- **Structured metadata extraction** — model outputs YAML metadata block (title, author, tags) for reliable parsing; regex + PDF filename fallback
- **Dual-layer dedup** — PDF file hash (input-side, before API call) + source_id (output-side, before file write)
- **Canonical tag enforcement** — model picks from embedded `#kb/` tag list; non-canonical → `needs_review`
- **Consistent file naming** — `[source_id]-[note_type].md`, matching inbox-processor convention
- **Three templates, separate passes** — nonfiction digest, fiction digest, chapter-digest. `--template` flag selects which. `--resume` skips completed files.
- **Vault tooling** — script lives in `_system/scripts/`, no external repo

## Interfaces/Dependencies

- **Upstream:** Local PDF files, Gemini API (`google-genai` SDK), API key
- **Internal:** knowledge-note schema, canonical `#kb/` tag list, three NLM templates (adapted), Sources/ directory
- **Downstream:** vault knowledge graph, `#kb/` tag network, domain MOCs, vault-check

## Current State

- **Phase:** ACT
- **BBP-001:** DONE — all 3 templates validated, 560 tok/page confirmed, quality meets/exceeds NLM baseline
- **Next:** BBP-002 (template adaptation) → BBP-003 (pipeline script) → BBP-005 (validation) → BBP-006 (full batch)
