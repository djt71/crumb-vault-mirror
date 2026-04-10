---
project: notebooklm-pipeline
domain: learning
type: reference
created: 2026-02-20
updated: 2026-02-20
---

# Golden Fixtures

Test exports from NotebookLM used to develop and validate the inbox-processor
NLM processing path.

## Naming Convention

`fixture-[source_type]-[template]-[YYYY-MM-DD].md`

Examples:
- `fixture-book-book-digest-v1-2026-02-20.md`
- `fixture-podcast-source-digest-v1-2026-02-21.md`

## Minimum Diversity Matrix

| Slot | source_type | Purpose |
|---|---|---|
| 1 | book | Standard long-form source |
| 2 | article | Short-form / web source |
| 3 | podcast | Audio — tests needs_review tagging, topic scope |
| 4 | video | Video — tests needs_review tagging, timestamp scope |
| 5 | any | "Messy" export — malformed tables, broken lists, extra preamble |
| 6 | any | "Short" export — <200 words total body content |

## Fixture Metadata

Each fixture should include a comment block after the sentinel documenting:

```markdown
<!-- fixture-meta
  source_type: book
  template: book-digest-v1
  export_method: extension | manual
  quirks: none | describe any formatting issues
-->
```

## How to Create Fixtures

1. Run a query template in NotebookLM
2. Export via Chrome extension OR copy output manually
3. If manual: add the sentinel marker at the top (see sentinel-contract.md)
4. Add the fixture-meta comment block
5. Name per convention above
6. Drop in this directory and commit

## Definitions

- **Messy export:** Malformed markdown tables, broken list formatting, extra
  conversational preamble before content, or inconsistent heading levels
- **Short export:** Total body content under 200 words (tests edge cases in
  section parsing and summary generation)
