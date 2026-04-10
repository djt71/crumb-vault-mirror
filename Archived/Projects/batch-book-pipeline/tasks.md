---
type: task
project: batch-book-pipeline
domain: learning
skill_origin: action-architect
created: 2026-02-28
updated: 2026-03-03
status: active
tags:
  - tasks
---

# Batch Book Pipeline — Tasks

## Milestone 1: Validate & Build

id: BBP-001
state: done
description: API validation — 3 test books (2 nonfiction, 1 fiction), 5 generation calls through Gemini 3.1 Pro. All three templates validated. 560 tok/page confirmed. Quality meets/exceeds NLM baseline. ~$4.15 actual cost.
depends: —
risk: medium
acceptance: 3 PDFs uploaded and processed; token counts recorded (560 tok/page, not 258); output has all template sections per template type; analytical depth is paragraph-level (nonfiction) or theme/character-focused (fiction); sample outputs saved to `design/samples/`

id: BBP-002
state: done
description: Template adaptation — strip NLM artifacts from all three prompts (book-digest, fiction-digest, chapter-digest), add YAML metadata block instruction, embed canonical tag list, version as v1.
depends: BBP-001
risk: low
acceptance: 3 prompt files in pipeline dir; NLM-specific language removed; metadata block reliably parseable from test output; suggested tags drawn from canonical list only

id: BBP-003
state: done
description: Pipeline script — `pipeline.py` with standard (sequential) and batch API (submit/collect) modes. All 16 spec steps implemented. Tested end-to-end on all 3 templates (7 generation calls, ~$7 API cost). vault-check passes on all outputs. Bug found and fixed: source_id collision detection was too aggressive on same-book multi-template outputs — fixed with normalized title comparison.
depends: BBP-002, BBP-004
risk: medium
acceptance: `pipeline.py` runs end-to-end on 1 book per template (standard mode); `--batch-api submit` creates batch job; `--batch-api collect` downloads and processes results; `--dry-run` reports cost estimate at 560 tok/page; `--resume` skips completed books; manifest and telemetry JSONL written; vault-check passes on output notes

id: BBP-004
state: done
description: Tag strategy — already resolved in spec. Implemented across BBP-002 (canonical list in prompt) and BBP-003 (validation logic).
depends: —
risk: low
acceptance: Canonical tag list embedded in prompts; non-canonical tags replaced with `needs_review` in pipeline validation

## Milestone 2: Validate & Scale

id: BBP-005
state: done
description: Validation batch — 10 books (6 nonfiction, 4 fiction) through all applicable templates = 20 notes. 17 new API calls ($4.69), 3 prior from BBP-001/003. vault-check 0 errors. Tag accuracy 100% canonical (0 `needs_review`). Quality reviewed on 3 samples (Frankl, Kafka, Meadows). Resume bug found and fixed (manifest last-entry-wins overwriting success with skip).
depends: BBP-003
risk: medium
acceptance: ~20 knowledge notes in `Sources/books/`; vault-check passes on all; user reviews structural completeness, depth, tags for each template type; tag accuracy target met; systematic issues addressed before proceeding

id: BBP-006
state: done
description: Full batch — 358 knowledge notes generated across book-digest (181), chapter-digest (138), fiction-digest (39). 10 books failed repeatedly (content filters, oversized, persistent 503s) — accepted as known failures. Batch API + standard API retries across sessions 7-10.
depends: BBP-005
risk: low
acceptance: ~180 knowledge notes in `Sources/books/`; vault-check passes; telemetry JSONL complete; total cost within ~$40-50 (batch pricing, 300pp avg); `needs_review` tags identified for manual cleanup

## Milestone 3: Poetry Collection Support

id: BBP-007
state: done
description: Poetry collection template — validated and deployed. 5 poetry collections processed (per manifest). Template, pipeline, inbox-processor, and file-conventions changes all committed.
depends: BBP-003
risk: low
acceptance: Rilke poems PDF processed through `--template poetry-collection`; output contains all poems with full text preserved; vault-check passes on output; `note_type: collection` and `type: collection` in frontmatter; telemetry recorded
