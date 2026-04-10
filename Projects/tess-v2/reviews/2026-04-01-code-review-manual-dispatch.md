---
type: review
review_type: code
review_mode: diff
scope: manual
project: tess-v2
domain: software
language: python
framework: pytest
diff_stats:
  files_changed: 9
  insertions: 1552
  deletions: 0
skill_origin: code-review
created: 2026-04-01
updated: 2026-04-01
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
    latency_ms: 72812
    attempts: 1
    token_usage:
      input_tokens: 17938
      output_tokens: 3395
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-code-review-manual-dispatch-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 83218
    tools_run:
      - "pytest -q -s"
      - "rg (symbol search)"
      - "mypy --version (not installed)"
      - "pyright --version (not installed)"
      - "pip show mypy pyright basedpyright"
      - "sed -n (source inspection x5)"
      - "pwd && ls -la"
    token_usage:
      input_tokens: unknown
      output_tokens: unknown
    jsonl_log: Projects/tess-v2/reviews/raw/2026-04-01-code-review-manual-dispatch-codex.jsonl
    raw_text: Projects/tess-v2/reviews/raw/2026-04-01-code-review-manual-dispatch-codex.txt
tags:
  - review
  - code-review
---

# Code Review: Tess v2 Dispatch Envelope Validator and Composition Engine

Manual code review of 9 new files (1,552 insertions): dispatch envelope composition engine, validation gates, Claude Code dispatch assembler, token counting, and test suites.

## Reviewer: Anthropic (Claude Opus 4.6)

### Findings

**ANT-F1** [CRITICAL] `src/tess/envelope.py` lines 112-131
`_compact_envelope` mutates the `vault_contents` iteration state incorrectly and uses stale references. After Priority 1 removes paths from the `paths` list, Priority 2 re-reads `vault_contents.keys()` (the original full dict), not the surviving paths. The `surviving` dict check `if p in vault_contents` is always true since `paths` was rebuilt from `vault_contents.keys()`. Priority 2 truncation will re-add files that Priority 1 already removed, undoing the compaction and potentially keeping the envelope over budget.
**Fix:** Track surviving paths across priorities: start with `surviving_paths = list(vault_contents.keys())`, pop from that list in Priority 1, and use it in Priority 2.

**ANT-F2** [CRITICAL] `src/tess/envelope.py` lines 100-108
`_compact_envelope` receives `layers` as a mutable dict and mutates it in place, despite the docstring claiming "Mutates nothing outside; returns new copies." The caller in `compose_envelope` passes its own `layers` dict, which gets silently mutated.
**Fix:** Copy at function entry: `layers = {k: v for k, v in layers.items()}`

**ANT-F3** [SIGNIFICANT] `src/tess/envelope.py` lines 105-108
`_current_tokens()` is called repeatedly inside while-loops during compaction. Each call re-counts tokens for the entire envelope. Performance degrades quadratically with vault file count during compaction.
**Fix:** Cache the token count and subtract the removed portion's estimated tokens rather than re-counting the whole thing each iteration.

**ANT-F4** [SIGNIFICANT] `src/tess/tokens.py` lines 17-22
`_try_tiktoken` calls `tiktoken.get_encoding("cl100k_base")` on every invocation. The encoding object should be cached.
**Fix:** Module-level `_ENCODING_CACHE` dict.

**ANT-F5** [SIGNIFICANT] `src/tess/validator.py` lines 103-113
Gate 4 (overlay count) relies on `contract.get("_overlay_count", 0)` -- a private key never set by `compose_envelope`. Gate 4 is effectively dead validation.
**Fix:** Accept overlay count as a validator parameter, or enforce at composition time.

**ANT-F6** [SIGNIFICANT] `src/tess/envelope.py` lines 182-188
`compose_envelope` doesn't enforce the 3-overlay maximum. Combined with F5, the overlay limit is unenforced anywhere in the pipeline.
**Fix:** Add `if len(overlays) > 3: raise ValueError(...)` at top of `compose_envelope`.

**ANT-F7** [SIGNIFICANT] `src/tess/claude_dispatch.py` lines 62-63, `envelope.py` lines 39, 84
Uses `yaml.dump` (not `yaml.safe_dump`), which can serialize arbitrary Python objects.
**Fix:** Use `yaml.safe_dump` in all three locations.

**ANT-F8** [SIGNIFICANT] `src/tess/validator.py` lines 143-165
`_gate3_check` parses ALL yaml blocks in the prompt looking for one matching the contract_id. Vault context or failure context YAML blocks could satisfy Gate 3 even if L4 was corrupted.
**Fix:** Extract L4 by position using `LAYER_SEPARATOR` or tag the contract block.

**ANT-F9** [MINOR] `src/tess/envelope.py` lines 70-92
`_truncate_to_frontmatter_and_first_section` edge cases: horizontal rules vs frontmatter, `#!` shebangs matching heading detection.

**ANT-F10** [MINOR] `src/tess/envelope.py` line 23
`"claude-code": 0` sentinel for unbounded. Use `None` for clarity.

**ANT-F11** [MINOR] `src/tess/envelope.py` line 217
`executor` parameter is accepted but never used. Dead parameter.

**ANT-F12** [MINOR] `src/tess/validator.py` lines 172-175
`_has_failure_context` uses fragile string matching for "Failure Context".

**ANT-F13** [MINOR] `tests/test_envelope.py` lines 292-325
Compaction tests depend on tiktoken availability for deterministic token counts.

**ANT-F14** [MINOR] Missing `src/tess/__init__.py` for package importability.

**ANT-F15** [STRENGTH] Clean Claude Code dispatch separation (D5 design decision).

**ANT-F16** [STRENGTH] Graceful tiktoken-to-heuristic degradation.

**ANT-F17** [STRENGTH] Test organization: each gate has its own class, clear naming.

**ANT-F18** [MINOR] Missing test coverage for Gate 3 parse failure, Gate 4 boundary, contract_id mismatch.

**Anthropic Summary: CRITICAL 2, SIGNIFICANT 5, MINOR 7, STRENGTH 3**

---

## Reviewer: Codex (GPT-5.3-Codex)

### Tool Execution

Codex ran 13 commands in the repo with read-only sandbox:
- `pytest -q -s`: 29 failed, 102 passed, 98 errors (sandbox environment issues with tempfile/tiktoken cache)
- `mypy --version` / `pyright --version`: not installed in .venv
- `pip show mypy pyright basedpyright`: confirmed not installed
- `rg` symbol search: verified all referenced function signatures exist
- `sed -n` source inspection (5 commands): examined specific source line ranges

### Findings

**CDX-F1** [CRITICAL] `validator.py:160-173`
Gate 3 can pass even when no contract YAML block in the prompt matches/parses correctly. The "trust render" fallback undermines AD-006 gate guarantees.
**Fix:** If no parsed YAML block matches required contract identity, append a gate-3 failure unconditionally.

**CDX-F2** [SIGNIFICANT] `envelope.py:141-146`
Priority-2 compaction rebuilds `surviving` from all original `vault_contents`, effectively reintroducing files removed in priority 1.
**Fix:** Track the post-priority-1 surviving path set and truncate only that subset.

**CDX-F3** [SIGNIFICANT] `envelope.py:153-157`
Overlay compaction loop pops `current_overlays`, but `_over_budget()` checks `layers["L3"]` (unchanged until after loop), so it removes all overlays whenever triggered. Violates "least-specific first" intent.
**Fix:** Update `layers["L3"]` inside the loop or recompute budget with tentative overlays each iteration.

**CDX-F4** [SIGNIFICANT] `envelope.py:232`
Unknown `context` defaults to budget `0` (unbounded). A typo or bad input silently disables budget enforcement (token-budget bypass).
**Fix:** Reject unknown contexts with `ValueError`.

**CDX-F5** [SIGNIFICANT] `tokens.py:17-21`
`_try_tiktoken` only catches `ImportError`; runtime failures from tiktoken are not handled. Confirmed by test output: `FileNotFoundError` in tiktoken cache path causes test failures instead of fallback.
**Fix:** Catch broader `Exception` around `get_encoding`/`encode` and return `None`.

**CDX-F6** [MINOR] `validator.py:190-194`
Gate 6 checks failure context via substring -- false positives possible.
**Fix:** Parse layers structurally via separator.

**CDX-F7** [MINOR] `claude_dispatch.py:72-78`
Raw vault_paths/staging_path interpolated into prompt without normalization/escaping. Newline/control characters could inject extra instructions.
**Fix:** Validate paths, render as YAML blocks.

**CDX-F8** [MINOR] `envelope.py:208`
`executor` parameter is unused.

**CDX-F9** [MINOR] `test_envelope.py:334`, `test_validator.py:138`
Missing regression test coverage for unknown context handling, gate-3 "wrong YAML block" failure, compaction state carry-over, tiktoken runtime failure.

**CDX-S1** [STRENGTH] Hard-floor rejection (L1 + L4 must fit) is a good fail-fast invariant.

**CDX-S2** [STRENGTH] Tests well-structured by behavior area.

**Codex Summary: CRITICAL 1, SIGNIFICANT 4, MINOR 5, STRENGTH 2**

---

## Cross-Reviewer Convergence

| Theme | ANT | CDX | Converged? |
|-------|-----|-----|------------|
| Compaction priority 1->2 state leak | F1 (CRITICAL) | F2 (SIGNIFICANT) | Yes |
| Gate 3 validation bypass | F8 (SIGNIFICANT) | F1 (CRITICAL) | Yes |
| Unused `executor` param | F11 (MINOR) | F8 (MINOR) | Yes |
| Fragile failure context detection | F12 (MINOR) | F6 (MINOR) | Yes |
| Test coverage gaps | F13, F18 (MINOR) | F9 (MINOR) | Yes |
| `yaml.dump` vs `yaml.safe_dump` | F7 (SIGNIFICANT) | -- | Opus unique |
| tiktoken encoding cache | F4 (SIGNIFICANT) | -- | Opus unique |
| Overlay limit unenforced | F5+F6 (SIGNIFICANT) | -- | Opus unique |
| `_compact_envelope` mutation | F2 (CRITICAL) | -- | Opus unique |
| Overlay compaction over-removes | -- | F3 (SIGNIFICANT) | Codex unique |
| Unknown context = unbounded | -- | F4 (SIGNIFICANT) | Codex unique |
| tiktoken runtime error handling | -- | F5 (SIGNIFICANT) | Codex unique (tool-grounded) |
| Prompt injection via paths | -- | F7 (MINOR) | Codex unique |
| Missing `__init__.py` | F14 (MINOR) | -- | Opus unique |
