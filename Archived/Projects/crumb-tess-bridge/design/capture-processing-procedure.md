---
type: reference
project: crumb-tess-bridge
domain: software
created: 2026-02-25
updated: 2026-02-25
tags:
  - openclaw
  - quick-capture
---

# Capture Processing Procedure

Crumb-side procedure for processing quick-capture files detected at session startup.
Uses utilities from `src/crumb/scripts/lib/capture-processor.js`.

## When This Runs

Session startup detects `capture-*.md` files in `_openclaw/inbox/` and reports them.
User decides: **process now** or **defer** (items remain in inbox for next session).

## Procedure (per capture)

### 1. Parse

Read the capture file using `parseCapture(filepath)`. Returns:
- `frontmatter` — type, source, captured_by, captured_at, suggested_domain, suggested_tags, processing_hint
- `body` — free-form markdown content
- `urls` — extracted URLs from body

### 2. Route by Processing Hint

| Hint | Action | Function |
|------|--------|----------|
| `research` | Fetch URL(s), synthesize findings, write result to vault. Use `prepareResearchBrief(capture)` to get structured brief (URLs, instructions, domain, tags). Execute research interactively — WebFetch for URLs, synthesize, write to appropriate vault location. | `prepareResearchBrief()` |
| `review` | Same as `research` until researcher-skill differentiates. | `prepareResearchBrief()` |
| `file` | Route to `_inbox/` for inbox-processor to classify and file. Call `routeFile(capture, vaultRoot)`. Tell user the file is queued for inbox processing. | `routeFile()` |
| `read-later` | Append to reading list. Call `appendReadingList(capture, vaultRoot)`. | `appendReadingList()` |

**For research/review:** The brief from `prepareResearchBrief()` contains `urls`, `instructions`, `suggested_domain`, and `suggested_tags`. Use these to guide the research. Write the result as a vault note with appropriate frontmatter (type, domain, tags). If `suggested_domain` or `suggested_tags` seem wrong, override them.

### 3. Move to Processed

After successful processing, call `moveToProcessed(filepath)`. This moves the capture to `_openclaw/inbox/.processed/`.

If processing fails or the user defers a specific capture, leave it in inbox.

### 4. Purge (periodic)

Call `purgeOldProcessed(processedDir, 30)` to remove processed captures older than 30 days. Run this opportunistically — doesn't need to happen every session.

## Example Session Flow

```
Startup: "Captures: 2 pending from Tess"
User: "Process now"

Capture 1: capture-20260225-143045.md
  hint: research, URL: https://example.com/article
  → WebFetch URL, synthesize, write to Domains/software/dns-security-findings.md
  → moveToProcessed()

Capture 2: capture-20260225-160000.md
  hint: read-later, URL: https://example.com/long-read
  → appendReadingList() → entry added to _system/reading-list.md
  → moveToProcessed()

"Both captures processed."
```

## Module Location

`Projects/crumb-tess-bridge/src/crumb/scripts/lib/capture-processor.js`

Functions: `parseCapture`, `routeFile`, `appendReadingList`, `prepareResearchBrief`, `moveToProcessed`, `purgeOldProcessed`
