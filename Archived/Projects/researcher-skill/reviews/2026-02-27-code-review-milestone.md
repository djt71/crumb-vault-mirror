---
type: review
review_type: code
review_mode: diff
scope: milestone
project: researcher-skill
domain: software
language: markdown
diff_stats:
  files_changed: 6
  insertions: 479
  deletions: 5
skill_origin: code-review
created: 2026-02-27
updated: 2026-02-27
reviewers:
  - anthropic/claude-opus-4-6
  - codex/gpt-5.3-codex
config_snapshot:
  curl_timeout: 120
  codex_timeout: 180
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
    latency_ms: 59881
    attempts: 1
    token_usage:
      input_tokens: 6002
      output_tokens: 2465
    raw_json: reviews/raw/2026-02-27-code-review-milestone-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 56529
    tools_run: ["pytest -q (not found)", "mypy . (not found)"]
    token_usage:
      input_tokens: unknown
      output_tokens: unknown
    jsonl_log: reviews/raw/2026-02-27-code-review-milestone-codex.jsonl
    raw_text: reviews/raw/2026-02-27-code-review-milestone-codex.txt
tags:
  - review
  - code-review
status: active
---

# Code Review: researcher-skill M4 (Citation Verification + Writing Validation)

**Scope:** Milestone review — M4 implements Stage 5 (Citation Verification) and Writing Validation rules.
**Diff:** 6 files changed, +479/-5 lines.
**Reviewers:** 2 dispatched, 2 succeeded, 0 failed.


## Reviewer 1: Anthropic (Claude Opus 4.6) — ANT



## Code Review: M4 — Citation Verification & Writing Validation Rules

### Findings

---

**[F1]**
**Severity:** SIGNIFICANT
**File:** `stages/05-citation-verification.md`, Matching Algorithm (Step 2, substep 4)
**Finding:** The sliding window overlap uses set intersection, which loses duplicate token sensitivity. If a quote_snippet contains repeated meaningful tokens (e.g., "the model outperforms the model"), converting to sets collapses duplicates, inflating the overlap score. A snippet like "rate rate rate rate" would get a 100% match against any window containing the word "rate" once.
**Why:** For research quotes, repeated terms (especially technical terms or numbers appearing multiple times) are meaningful. Set-based comparison could pass a snippet that doesn't actually appear in the source, undermining the entire verification purpose.
**Fix:** Use multiset (bag) intersection instead of set intersection:
```
overlap = sum(min(snippet_count[t], window_count[t]) for t in snippet_count) / len(snippet_tokens)
```
where counts are token frequency maps. This preserves duplicate sensitivity while keeping the fuzzy matching character.

---

**[F2]**
**Severity:** SIGNIFICANT
**File:** `stages/05-citation-verification.md`, Step 2 — Matching Algorithm, substep 3–4
**Finding:** The sliding window algorithm has O(N × M × W) complexity where N = source tokens, M = snippet tokens, W = window size range. For a 50,000-character source (~8,000 tokens) and a 50-token snippet with ±20% tolerance (windows 40–60), this is ~8,000 × 21 × 50 ≈ 8.4 million operations per entry. With >50 entries (the "large ledger" edge case), this compounds to hundreds of millions of conceptual operations — all being simulated by an LLM that cannot actually execute algorithms.
**Why:** This is a prompt template executed by an AI model, not compiled code. The model will approximate or hallucinate the sliding window results rather than mechanically compute them. The precision implied by the algorithm specification creates false confidence in the output.
**Fix:** Acknowledge the algorithmic nature is aspirational guidance. Add a note: "You are performing approximate matching — report your best honest assessment of whether the snippet appears in the source content, using the scoring thresholds as calibration anchors. Do not fabricate specific overlap scores." Alternatively, simplify to: "Search the source content for the quoted passage. Rate the match quality as pass/flagged/fail using the threshold definitions."

---

**[F3]**
**Severity:** SIGNIFICANT
**File:** `stages/05-citation-verification.md`, Step 3 — Over-Confidence table
**Finding:** The over-confidence rules can trigger conflicting or cascading corrections. Consider: an entry has `confidence: verified`, source is `AbstractOnly`, AND snippet match score is 0.60 (flagged). Row 1 says supersede to `supported`. Row 2 says supersede to `supported` with a note about the score. These produce two supersede operations for the same original entry, violating the "exactly one active entry that supersedes it" invariant.
**Why:** Two supersede entries for the same original creates ambiguity about which is canonical and breaks the 1:1 deprecated→active mapping.
**Fix:** Add a precedence rule: "If multiple conditions apply to the same entry, apply the **most conservative** correction (lowest confidence level) and combine all reasons in the `notes` field. Create only ONE supersede entry per original." For the example above, that would be `supported` with notes mentioning both AbstractOnly source and below-threshold score.

---

**[F4]**
**Severity:** SIGNIFICANT
**File:** `stages/05-citation-verification.md`, Step 2 — "Entries without FullText sources" note
**Finding:** Entries linked to FullText sources where the content file is missing are treated as "verification failure" (Step 1.2), but the Match Classification table only defines actions for score ranges ≥0, not for "file missing" failures. There's no explicit match score or flag_type assigned to this case. It falls through the classification.
**Why:** A missing source file is a more serious issue than a low match score — it could indicate data corruption or a pipeline failure. Without a defined flag_type and classification, these entries may be silently skipped.
**Fix:** Add an explicit classification row or paragraph:
```
| Source file missing/empty | **Verification failure** | Add flag with `flag_type: source-missing`; treat as match score 0 for over-confidence checks |
```

---

**[F5]**
**Severity:** MINOR
**File:** `stages/writing-validation-rules.md`, Check 4 — Orphan Detection regex
**Finding:** The regex `\[\^FL-\d{3}\]` only matches exactly 3-digit entry IDs. If the ledger grows beyond 999 entries (FL-1000+), the regex won't catch those references, and valid citations to higher-numbered entries would be invisible to orphan detection.
**Why:** While unlikely for most research tasks, the format definition section also only specifies "zero-padded 3-digit" IDs. If the pipeline ever exceeds 999 entries, the entire citation format breaks silently.
**Fix:** Either document a hard cap ("Ledger entries are limited to FL-001 through FL-999") or extend the format to `\[\^FL-\d{3,}\]` and update the padding description to "at least 3 digits."

---

**[F6]**
**Severity:** MINOR
**File:** `stages/writing-validation-rules.md`, Check 1 — Citation Coverage
**Finding:** The procedure asks the model to "identify all factual claims" in the deliverable, which is inherently subjective. The exclusion list (transitional phrases, synthesis, headings, scope statements) helps but leaves significant gray area. Two invocations of the Writing stage could disagree on what constitutes a "factual claim," leading to non-deterministic pass/fail results.
**Why:** In a retry loop (max 2 retries per enforcement rules), non-deterministic claim identification could cause oscillation — one invocation flags claims the next doesn't, creating a fix-break cycle.
**Fix:** Add a heuristic anchor: "When in doubt about whether a statement is a factual claim, err on the side of requiring a citation. A claim is factual if removing it would leave the reader less informed about the research question's answer." This biases toward over-citation (safe) rather than under-citation (unsafe).

---

**[F7]**
**Severity:** MINOR
**File:** `stages/05-citation-verification.md`, Step 7 — Output JSON
**Finding:** The `status` field is hardcoded to `"next"` in the template. There's no condition under which this stage outputs `"done"` or `"error"`. This is correct for the normal flow (verification always advances to writing), but the edge case section doesn't address what happens if the ledger file itself is unreadable or the handoff is malformed.
**Why:** Without an error status path, a corrupted ledger or missing handoff would force the model to produce a `"next"` output with potentially fabricated verification data rather than escalating.
**Fix:** Add an error condition: "If the ledger file cannot be read or the handoff is missing required fields (research_plan, coverage_assessment), output `status: 'error'` with a descriptive error message and `escalation: 'operator'`."

---

**[F8]**
**Severity:** MINOR
**File:** `stages/writing-validation-rules.md`, Check 2 vs Check 4
**Finding:** Check 2 (Citation Resolution) and Check 4 (Orphan Detection) overlap significantly. Check 2 verifies every `[^FL-NNN]` resolves to an active entry (catching non-existent AND deprecated). Check 4 catches `[^FL-NNN]` references to non-existent entries. The only distinction is Check 2 also catches deprecated references — but Check 4's stated purpose ("distinct from Check 2's deprecated-entry detection") acknowledges the overlap while not adding unique value.
**Why:** Redundant checks increase prompt complexity without improving coverage. A model might produce inconsistent results between the two checks for the same reference.
**Fix:** Merge Check 4 into Check 2, or redefine Check 4 to catch something genuinely distinct (e.g., entries that exist in the ledger but are never cited in the deliverable — "unused evidence" detection, which would be a useful completeness signal).

---

**[F9]**
**Severity:** STRENGTH
**File:** `stages/05-citation-verification.md`, Step 4
**Finding:** The supersede-not-mutate pattern (creating new entries that supersede originals rather than editing them) is excellent. It preserves full audit trail, maintains referential integrity for any downstream references to original IDs, and makes the verification stage's work fully reversible/inspectable.

---

**[F10]**
**Severity:** STRENGTH
**File:** `stages/writing-validation-rules.md`, overall design
**Finding:** The "write-only-from-ledger" discipline with mechanical validation checks is a strong architectural choice. The source chain concept (claim → citation → entry → source → tier) creates genuine traceability. The blocking enforcement (no `done` without passing validation) prevents integrity violations from reaching the final output.

---

**[F11]**
**Severity:** STRENGTH
**File:** `SKILL.md` changes
**Finding:** Replacing placeholder references like `[RS-007]` and `[RS-008]` with actual file paths (`stages/05-citation-verification.md`, `stages/writing-validation-rules.md`) and listing available tools improves the SKILL.md from spec-document to actionable stage registry. Good evolution.

---

### Summary

**CRITICAL: 0 | SIGNIFICANT: 4 | MINOR: 4 | STRENGTH: 3**

The most impactful findings are F2 (algorithm designed for compiled code but executed by LLM), F3 (cascading supersede operations can violate the 1:1 invariant), F1 (set-based overlap loses duplicate sensitivity), and F4 (missing source file falls through classification). The overall architecture is sound — the supersede pattern and write-only-from-ledger discipline are genuinely well-designed.

---

## Reviewer 2: Codex (GPT-5.3-Codex) — CDX

### Tool Execution

Codex attempted to run `pytest -q` and `mypy .` before reviewing but both were unavailable in the sandbox environment (markdown/YAML project with no executable code). Review proceeded without tooling evidence.

### Findings

Tooling status before review: attempted `pytest -q` and `mypy .`; both failed with `command not found` in this environment, so no executable test/typecheck evidence was available.

- [F1]
- [Severity]: SIGNIFICANT
- [File]: `.claude/skills/researcher/stages/05-citation-verification.md` (lines 39, 54-63)
- [Finding]: The overlap formula can divide by zero when `quote_snippet` is non-null but normalizes to zero tokens (e.g., punctuation-only snippet), because denominator is `|set(snippet_tokens)|`.
- [Why]: This creates undefined behavior in the verification stage and can silently break/falsify match classification.
- [Fix]: Add a guard before overlap computation: if normalized snippet token set is empty, emit a deterministic flag (e.g., `flag_type: invalid-snippet`), classify as verification failure, and apply a defined confidence downgrade path.

- [F2]
- [Severity]: SIGNIFICANT
- [File]: `.claude/skills/researcher/stages/05-citation-verification.md` (lines 33-35, 69-76, 143-160)
- [Finding]: Missing/empty FullText content is declared a “verification failure,” but no downstream classification/resolution path is specified in match classes, supersede rules, or summary counters.
- [Why]: The stage contract is incomplete; operators can’t tell whether these cases are counted as `fail`, `skipped`, or separate errors, and confidence correction behavior becomes non-deterministic.
- [Fix]: Define an explicit failure class (e.g., `missing-source-content`), specify whether it increments `snippet_checks.fail`, and add mandatory correction behavior for affected confidence levels.

- [F3]
- [Severity]: SIGNIFICANT
- [File]: `.claude/skills/researcher/stages/writing-validation-rules.md` (lines 51-53, 60-159)
- [Finding]: Rule “No ad-hoc citations” is mandatory, but none of the 4 validation checks actually detect forbidden citation styles (inline URLs, `[1]`, Harvard style).
- [Why]: A deliverable can violate citation format policy and still pass validation, undermining the “mechanically enforced” integrity claim.
- [Fix]: Add an explicit validation check for disallowed citation patterns (or extend Check 2) with concrete regexes and failure output schema.

- [F4]
- [Severity]: MINOR
- [File]: `.claude/skills/researcher/stages/writing-validation-rules.md` (lines 87-96, 142-150)
- [Finding]: Check 2 (“entry not found”) and Check 4 (“non-existent ledger entries”) overlap heavily and can produce redundant failures for the same citation.
- [Why]: Redundant diagnostics increase retry noise and make fix instructions less clear.
- [Fix]: Differentiate scopes clearly (e.g., Check 2 = active/deprecated resolution; Check 4 = malformed/invalid citation IDs only) or merge into one check.

Findings summary: **0 CRITICAL, 3 SIGNIFICANT, 1 MINOR, 0 STRENGTH**.