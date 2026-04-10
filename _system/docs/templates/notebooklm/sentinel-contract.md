---
project: notebooklm-pipeline
domain: learning
type: reference
status: active
created: 2026-02-20
updated: 2026-02-20
tags:
  - notebooklm
  - pipeline
---

# Sentinel Contract (v1)

Machine-readable marker that identifies NotebookLM exports for automated processing
by the inbox-processor skill.

## Format

Two forms — the parser accepts **either** one:

**HTML comment (preferred):**
```
<!-- crumb:nlm-export v=1 template=book-digest-v1 note_type=digest source_type=book -->
```

**Plain-text fallback:**
```
crumb:nlm-export v=1 template=book-digest-v1 note_type=digest source_type=book
```

## Placement

Within the **first 5 lines** of the exported markdown file. The parser uses a
tolerant regex that ignores leading markdown formatting characters (`#`, `>`, `*`, spaces).

## Fields

| Field | Required | Description |
|---|---|---|
| `v` | Yes | Sentinel version (currently `1`) |
| `template` | Yes | Template name with version suffix (e.g., `book-digest-v1`) |
| `note_type` | No | `digest` or `extract` — can be inferred from template |
| `source_type` | No | `book`, `article`, `podcast`, etc. — can be inferred from template |

## Detection Regex

```
^[#\s>*]*<!--\s*crumb:nlm-export\s+v=(\d+)\s+template=([a-z0-9-]+)
^[#\s>*]*crumb:nlm-export\s+v=(\d+)\s+template=([a-z0-9-]+)
```

Optional fields parsed with: `note_type=([a-z-]+)` and `source_type=([a-z]+)`.

## Invariants

- The sentinel must survive NLM export unchanged. Templates instruct NLM to emit it
  as-is. If the Chrome extension strips the HTML comment, the plain-text fallback
  is detected instead.
- For the copy-paste fallback path, the user adds the sentinel manually at the top
  of the file before dropping in `_inbox/`.
- There is no end sentinel — the marker appears only at the top.

## Versioning

When the sentinel format changes, increment `v`. The inbox-processor maintains
backward compatibility with all known sentinel versions.
