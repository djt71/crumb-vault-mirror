---
project: book-scout
domain: software
type: reference
status: active
created: 2026-02-28
updated: 2026-02-28
tags:
  - openclaw
  - automation
---

# Catalog Handoff — Operator Guide

## Overview

After Tess downloads books via Book Scout, catalog JSON files appear in `_openclaw/tess_scratch/catalog/inbox/`. Crumb processes these into source-index notes in the vault.

## Processing Catalog Entries

Run the catalog processor:

```bash
bash _system/scripts/book-scout/catalog-processor.sh
```

Or with dry-run to preview:

```bash
bash _system/scripts/book-scout/catalog-processor.sh --dry-run
```

**What it does:**
1. Reads `.json` files from `inbox/` (ignores `.tmp-*` partial writes)
2. Validates each against the catalog schema (9 required fields)
3. Creates a source-index note in `Sources/books/{source_id}-index.md`
4. Moves processed JSON to `processed/`, failed JSON to `failed/`

## When to Run

- **On demand:** "Process book catalog" or "check for new books"
- **Session start:** Check `inbox/` during startup if book-scout is active
- Not automated via cron — volume doesn't justify it

## Troubleshooting

**Failed entries:** Check `_openclaw/tess_scratch/catalog/failed/` — JSON files here failed validation. Read the file to see what field is missing, fix if possible, move back to `inbox/`, re-run.

**Duplicate detection:** If a source-index note already exists for a source_id, the JSON is moved to `processed/` and skipped (not overwritten).

**Unsorted books:** Books with `subjects: ["unsorted"]` get a source-index note with empty tags and topics. Manually classify: add `#kb/` tags and `topics` to the frontmatter, move the PDF to the correct subject directory, update the body metadata.

## Directory Layout

```
_openclaw/tess_scratch/catalog/
  inbox/        ← Tess writes new catalog JSONs here
  processed/    ← Crumb moves successfully processed JSONs here
  failed/       ← Crumb moves JSONs that fail validation here
```

## Subject → Tag → Topic Mapping

| Subject | Tag | Topic |
|---------|-----|-------|
| philosophy | kb/philosophy | moc-philosophy |
| history | kb/history | moc-history |
| fiction | kb/writing | moc-writing |
| biography | kb/history | moc-history |
| spirituality | kb/religion | moc-religion |
| science | kb/philosophy | moc-philosophy |
| unsorted | (none) | (none) |
