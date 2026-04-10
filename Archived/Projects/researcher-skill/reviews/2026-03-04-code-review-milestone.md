---
type: review
review_type: code
review_mode: diff
scope: milestone
milestone: M5
project: researcher-skill
domain: software
language: markdown
framework: prompt-templates
diff_stats:
  files_changed: 3
  insertions: 749
  deletions: 10
skill_origin: code-review
created: 2026-03-04
updated: 2026-03-04
status: active
reviewers:
  - anthropic/claude-opus-4-6
  - codex/gpt-5.3-codex
config_snapshot:
  curl_timeout: 120
  codex_timeout: 300
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  anthropic:
    http_status: 200
    latency_ms: 105020
    attempts: 1
    token_usage:
      input_tokens: 10767
      output_tokens: 4692
    raw_json: reviews/raw/2026-03-04-code-review-milestone-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 147401
    tools_run:
      - "rg --files (project tooling search)"
    token_usage:
      input_tokens: unknown
      output_tokens: unknown
    raw_text: reviews/raw/2026-03-04-code-review-milestone-codex.txt
tags:
  - review
  - code-review
  - milestone
---

# Code Review: M5 — Synthesis, Writing, and Vault Delivery

**Scope:** Milestone M5 (Output Pipeline: Synthesis + Writing + Vault Output)
**Diff:** 3 files, +749/-10 lines
**Reviewers:** 2 dispatched, 2 succeeded, 0 failed

## Anthropic (Claude Opus 4.6)

### ANT-F1 — CRITICAL: Duplicate "within 0.1" threshold logic
- **File:** `stages/04-synthesis.md` (Contradiction Clusters + Conflict Escalation)
- **Finding:** The "within 0.1" tie-breaking threshold appears twice with subtly different semantics — once in dominant stance determination (section 3.4) and again in escalation criteria. A claim could be marked as having a dominant stance (diff > 0.1) yet still trigger an escalation (if both sides have Tier A/B sources and totals are "within 0.1" — but those are the same totals). The two checks are redundant but written as independent conditions.
- **Fix:** Unify: escalation should reference the `dominant_stance` field from section 3. If `dominant_stance == "unresolved"` AND both sides have Tier A/B sources, trigger escalation. Remove duplicate threshold logic.

### ANT-F2 — CRITICAL: Non-deterministic citation coverage check (LLM-aspirational)
- **File:** `stages/06-writing.md` (Check 1: Citation Coverage)
- **Finding:** "Scan every paragraph for factual claims" is non-deterministic — no mechanical definition of what constitutes a "factual claim." An LLM could flag different claims on each pass, causing infinite retry loops or spurious `blocked` status. Same pattern flagged in M4 review.
- **Fix:** Add calibration note: on retry, validate ONLY specific claims from previous failure. Or define factual claims structurally (sentences with numbers/statistics, named entity attributions, causal assertions).

### ANT-F3 — SIGNIFICANT: Confidence formula ignores zero-entry sub-questions
- **File:** `stages/04-synthesis.md` (Overall Confidence)
- **Finding:** Weight per sub-question = entries_for_sq / total_active_entries. Sub-questions with zero entries get weight 0, making their quality ceilings, contradictions, and evidence gaps invisible to the overall score.
- **Fix:** Define minimum weight per sub-question: `max(actual_weight, 1/N)`, or apply evidence gap penalties as absolute deductions.

### ANT-F4 — SIGNIFICANT: Knowledge-note vault routing is ambiguous
- **File:** `SKILL.md` (Step 5.1, knowledge-note routing)
- **Finding:** "Dominant source tier" is undefined — majority count, highest-tier present, or weighted? Missing coverage for Tier A non-academic sources and edge cases.
- **Fix:** Define "dominant" explicitly. Add fallback: if no clear dominant tier, default to `articles/`.

### ANT-F5 — SIGNIFICANT: No source index for research-note format
- **File:** `SKILL.md` (Step 5.1)
- **Finding:** Source index creation is specified only for `knowledge-note`, not `research-note`. Creates an undocumented asymmetry.
- **Fix:** Either create source index for both formats or explicitly document the asymmetry.

### ANT-F6 — SIGNIFICANT: Multi-citation format breaks Markdown footnotes
- **File:** `stages/06-writing.md` (citation placement)
- **Finding:** `[^FL-007],[^FL-012]` — the comma breaks standard Markdown footnote rendering in Obsidian. Second footnote may render as literal text.
- **Fix:** Use `[^FL-007][^FL-012]` (no comma) or test in Obsidian and document the result.

### ANT-F7 — SIGNIFICANT: `writing-retry` stage_id has no template
- **File:** `stages/06-writing.md` (validation failure handling)
- **Finding:** `next_stage.stage_id: "writing-retry"` doesn't map to any file. Orchestrator would fail to find the template.
- **Fix:** Use `stage_id: "writing"` for retries, differentiate via non-null `retry_context`.

### ANT-F8 — SIGNIFICANT: "Closest matching sub-question" is LLM-aspirational
- **File:** `stages/04-synthesis.md` (coverage validation)
- **Finding:** Assigning orphan entries to the "closest matching sub-question based on claim_key" requires semantic understanding with no mechanical rule.
- **Fix:** Deterministic fallback: assign to synthetic `sq-unassigned` excluded from per-sub-question confidence.

### ANT-F9 — SIGNIFICANT: Telemetry `wall_time_seconds` has no source timestamp
- **File:** `SKILL.md` (Step 5.2, telemetry)
- **Finding:** No prior stage captures or carries `dispatch_start_time`. The LLM executing Step 5 cannot compute `wall_time_seconds`.
- **Fix:** Add `dispatch_start_time` to initial handoff, or document that the orchestrator populates this field.

### ANT-F10 — SIGNIFICANT: Literal `0.0` in output template may anchor LLM
- **File:** `stages/04-synthesis.md` (output JSON template)
- **Finding:** `"score": 0.0` is the only field with a literal value instead of `"..."` placeholder. Could anchor LLM output.
- **Fix:** Replace with `"score": "{{computed_score}}"`.

### ANT-F11 — MINOR: Confidence field label ambiguity
- **File:** `stages/06-writing.md` (Sources section format)
- **Finding:** "Confidence" in source entries refers to the label (`verified`, `supported`) but could be confused with numeric `overall_confidence.score`.
- **Fix:** Clarify: "the entry's `confidence` field label (e.g., `verified`, `supported`, `contested`)."

### ANT-F12 — MINOR: Frontmatter numeric field quoting inconsistency
- **File:** `SKILL.md` (research-note frontmatter template)

### ANT-F13 — MINOR: Neutral/null stance entries silently excluded from contradiction analysis
- **File:** `stages/04-synthesis.md` (stance enumeration)
- **Fix:** Explicitly state that non-{supports, refutes, mixed} stances are excluded from contradiction analysis.

### ANT-F14 — MINOR: `"failed"` status not in Writing output enum
- **File:** `stages/06-writing.md` (error path for empty ledger)
- **Finding:** Error path outputs `status: "failed"` but the enum lists `"done | next | blocked"`. Fourth status for orchestrator to handle.
- **Fix:** Add `"failed"` to enum or use `"blocked"` with error description.

### ANT-F15 — MINOR: Entry ID range note documentation
- **File:** `stages/06-writing.md` (entry ID range)

### ANT-F16 — STRENGTH: Check 2/4 merge reduces validation complexity
### ANT-F17 — STRENGTH: Orphan check with Tier C default is graceful degradation
### ANT-F18 — STRENGTH: Retry cap + escalation prevents infinite validation loops

## Codex (GPT-5.3-Codex)

### Tool Execution

Codex attempted to locate project tooling by searching for `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Makefile`, `tsconfig.json` via `rg --files`. Found none (expected for markdown-only project). Proceeded with schema cross-referencing and file verification.

### CDX-F1 — CRITICAL: Stage 4 handoff drops `convergence_thresholds`
- **File:** `stages/04-synthesis.md`, `stages/05-citation-verification.md`
- **Finding:** Stage 4 output handoff omits `convergence_thresholds` that Stage 5 expects to carry forward. Handoff contract break between adjacent stages.
- **Fix:** Add `"convergence_thresholds": "...carried from Research Loop"` to Stage 4 handoff output.

### CDX-F2 — SIGNIFICANT: Validation check field names drift between Writing and writing-validation-rules.md
- **File:** `stages/06-writing.md`, `stages/writing-validation-rules.md`
- **Finding:** Writing template uses `resolution_and_orphans` + `ad_hoc_detection`, but validation rules schema still defines `resolution` + `orphan_detection`.
- **Fix:** Update `writing-validation-rules.md` schema to match new keys.

### CDX-F3 — SIGNIFICANT: Telemetry field names incompatible with Writing output
- **File:** `SKILL.md`, `schemas/telemetry-template.yaml`, `stages/06-writing.md`
- **Finding:** Telemetry expects `writing.orphan_entries` and `writing.validation_passes`, but Writing provides `resolution_and_orphans.orphan_count` and `retry_count`.
- **Fix:** Define explicit mapping in Step 5.2 or rename fields.

### CDX-F4 — SIGNIFICANT: Empty ledger handling inconsistent across Stage 5/6
- **File:** `stages/05-citation-verification.md`, `stages/06-writing.md`
- **Finding:** Stage 5 allows empty ledger and advances to Writing; Stage 6 treats empty ledger as `status: "failed"` which is not in the output enum.
- **Fix:** Align policy: either block in Stage 5 or use contract-consistent status in Stage 6.

### CDX-F5 — SIGNIFICANT: Zero-denominator guard missing in confidence formula
- **File:** `stages/04-synthesis.md`
- **Finding:** `entries_for_sq / total_active_entries` has no guard for zero total entries.
- **Fix:** Add explicit guard: if `total_active_entries == 0`, set score `0.0`.

### CDX-F6 — SIGNIFICANT: Stage 4 has no malformed-input error path
- **File:** `stages/04-synthesis.md`
- **Finding:** No error handling for unreadable ledger, missing `research_plan`, or malformed handoff. Stages 5/6 have error paths but Stage 4 does not.
- **Fix:** Add `status: "error"` branch with code `SYNTHESIS_INPUT_ERROR`.

### CDX-F7 — SIGNIFICANT: Stage 5 `next_stage.context_files` omits synthesis document
- **File:** `stages/06-writing.md`, `stages/05-citation-verification.md`
- **Finding:** Writing requires `{{synthesis_path}}` but Citation Verification only forwards `{{ledger_path}}` in `next_stage.context_files`.
- **Fix:** Include synthesis file in Stage 5 `next_stage.context_files`.

### CDX-F8 — SIGNIFICANT: `handoff-schema.json` is out of date
- **File:** `schemas/handoff-schema.json`, `stages/04-synthesis.md`, `stages/06-writing.md`
- **Finding:** Schema does not define `overall_confidence`, `iteration_count`, `verification_summary`, `writing_validation`, `convergence_thresholds`.
- **Fix:** Update `handoff-schema.json` to include all current fields.

### CDX-F9 — MINOR: Escalation example contradicts threshold criteria
- **File:** `stages/04-synthesis.md`
- **Finding:** Criteria says "within 0.1" but example shows 1.4 vs 1.0 (difference 0.4).
- **Fix:** Correct example to <=0.1 delta.

### CDX-F10 — MINOR: LLM-aspirational procedures underspecified
- **File:** `stages/04-synthesis.md`, `SKILL.md`
- **Finding:** "Assign to closest sub-question based on claim_key" and `iterations_to_converge` from final handoff (lacks per-iteration history).
- **Fix:** Deterministic fallback for sub-question assignment; derive iterations from history files.

### CDX-S1 — STRENGTH: Tier weights consistent across pipeline
- **Finding:** A=1.0, B=0.7, C=0.4 verified consistent across Research Loop, Synthesis, and schema.

## Cross-Reviewer Convergence

Findings that both reviewers independently identified (high confidence):

| Theme | ANT | CDX | Severity |
|-------|-----|-----|----------|
| Zero-denominator in confidence formula | ANT-F3 | CDX-F5 | SIGNIFICANT |
| LLM-aspirational sub-question assignment | ANT-F8 | CDX-F10 | SIGNIFICANT |
| `"failed"` status / empty ledger handling | ANT-F14 | CDX-F4 | SIGNIFICANT |
| Tier weight consistency (strength) | ANT-F17 | CDX-S1 | STRENGTH |

Unique findings by reviewer:

| Reviewer | Count | Notable Unique Findings |
|----------|-------|------------------------|
| Anthropic | 12 | Duplicate 0.1 threshold (F1), citation coverage non-determinism (F2), footnote rendering (F6), template anchoring (F10) |
| Codex | 7 | `convergence_thresholds` handoff drop (F1), validation field name drift (F2), telemetry field mismatch (F3), Stage 5 missing synthesis in context_files (F7), handoff-schema.json drift (F8) |

## Finding Summary

| Severity | Anthropic | Codex | Combined Unique |
|----------|-----------|-------|-----------------|
| CRITICAL | 2 | 1 | 3 |
| SIGNIFICANT | 8 | 7 | 12 |
| MINOR | 5 | 2 | 6 |
| STRENGTH | 3 | 1 | 3 |
| **Total** | **18** | **11** | **24** |
