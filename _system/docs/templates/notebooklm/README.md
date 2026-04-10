---
project: null
domain: learning
type: reference
status: active
created: 2026-02-20
updated: 2026-02-24
tags:
  - notebooklm
  - template
---

# NotebookLM Templates

Query templates for the NotebookLM-to-Crumb pipeline. Each template defines a structured
prompt that produces machine-parseable output with a sentinel marker for automated
inbox processing.

## Sentinel Contract

See [[sentinel-contract]] for the machine-readable marker spec used by the inbox-processor
to detect and route NLM exports.

## Templates

### Digest Templates

| Template | Source Type | Depth | Use When |
|---|---|---|---|
| [[book-digest-v2]] | book | deep | Thorough book capture — paragraph arguments, 8-12 quotes, checklists, tables |
| [[source-digest-v2]] | any | deep | Thorough capture — paragraph arguments, 5-8 quotes with timestamps, checklists, tables |
| [[chapter-digest-v1]] | book | deep | Chapter-by-chapter breakdown — argument arc across the book |
| [[fiction-digest-v1]] | book (fiction) | deep | Themes, ideas, character meaning, memorable language — not plot summary |


## Workflow

For the full step-by-step guide (setup, export paths, batch strategy, troubleshooting):
[[workflow-guide|NLM Pipeline Workflow Guide]]

Quick reference:

1. Choose a template based on what you want to extract
2. Copy the NLM Prompt section into NotebookLM as a chat query
3. Replace any `[TOPIC]` placeholders with your specific focus
4. Export the response (Chrome extension or copy-paste)
5. Drop the `.md` file in `_inbox/`
6. Run inbox processing — the sentinel triggers the NLM Export Path automatically

## Template Versioning

Templates use a `v1`, `v2` suffix. When a template's output structure changes, create a
new version (e.g., `book-digest-v2.md`) rather than modifying the existing one. The
inbox-processor parser uses hardcoded heading maps per template version — changing
headings in an existing version would break parsing of older exports.

## Adding New Templates

1. Create the template in this directory with the naming pattern `[name]-v[N].md`
2. Include: NLM Prompt (with sentinel), Expected Output Structure (heading map),
   Post-Processing Notes, Version History
3. Add a row to the template → defaults mapping in the inbox-processor SKILL.md (Step 4a)
4. Test with at least 2 real NLM exports before marking validated
