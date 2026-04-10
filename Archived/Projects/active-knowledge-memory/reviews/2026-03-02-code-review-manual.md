---
type: review
review_type: code
review_mode: diff
scope: manual
project: active-knowledge-memory
domain: software
language: shell
framework: bash-python
diff_stats:
  files_changed: 2
  insertions: 969
  deletions: 4
skill_origin: code-review
created: 2026-03-02
updated: 2026-03-02
status: active
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
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "Hardcoded path /Users/tess/crumb-vault in line 73 (expected for personal vault script)"
reviewer_meta:
  anthropic:
    http_status: 200
    latency_ms: ~60000
    attempts: 1
    token_usage:
      input_tokens: 12586
      output_tokens: 5042
    raw_json: reviews/raw/2026-03-02-code-review-manual-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 124146
    tools_run:
      - "bash -n _system/scripts/knowledge-retrieve.sh"
      - "python3 -m pytest -q"
      - "command -v shellcheck"
      - "command -v mypy"
      - "rg function definitions and call sites"
      - "nl -ba (full file read, 4 passes)"
    token_usage:
      input_tokens: 614486
      output_tokens: 5946
    jsonl_log: reviews/raw/2026-03-02-code-review-manual-codex.jsonl
    raw_text: reviews/raw/2026-03-02-code-review-manual-codex.txt
tags:
  - review
  - code-review
---

# Code Review: AKM-004 Retrieval Engine

**Scope:** Manual code review of `knowledge-retrieve.sh` (new 959-line file) and `session-end-protocol.md` (minor update).

## Anthropic (Claude Opus 4.6) — ANT

### ANT-F1 [CRITICAL] — Fragile newline handling in term deduplication
**File:** `knowledge-retrieve.sh`, lines 165-168, 195-197, 224-226
**Finding:** `tr ' ' '\n'` relies on a literal newline inside quotes. If the file is re-saved by an editor that strips trailing whitespace or normalizes line endings, these commands silently break — `sort -u` gets the entire string as one line and `head -8` has no effect. This is the core deduplication and cap logic for query terms.
**Fix:** Use `$'\n'` syntax which is explicit and editor-safe. Apply to all three `build_*_signal` functions.

### ANT-F2 [CRITICAL] — Broken dedup file scoping
**File:** `knowledge-retrieve.sh`, line 19
**Finding:** `DEDUP_FILE="/tmp/akm-surfaced-$$.txt"` uses PID-scoped filename, but the script reads from it expecting prior session data. Every invocation gets a new PID, so `DEDUP_FILE` is always empty/nonexistent on read. The dedup mechanism never works.
**Fix:** Use a session-scoped identifier (daily scope or explicit session ID parameter).

### ANT-F3 [SIGNIFICANT] — Shell-to-Python injection risk
**File:** `knowledge-retrieve.sh`, lines 617-903
**Finding:** Shell variables interpolated directly into Python code via `'$VARIABLE'`. If any variable contains a single quote (e.g., `Sources/Books/don't-look-back.md`), it breaks the Python syntax, crashing the post-filter step.
**Fix:** Pass data via environment variables and read with `os.environ` in Python.

### ANT-F4 [SIGNIFICANT] — Full vault grep on every invocation
**File:** `knowledge-retrieve.sh`, line 487
**Finding:** `check_personal_writing_boost()` runs `grep -rl` across the entire vault on every invocation. O(n) scan of potentially thousands of files.
**Fix:** Cache the result with a TTL, or move the check into the Python section.

### ANT-F5 [SIGNIFICANT] — Unquoted glob expansion in query terms
**File:** `knowledge-retrieve.sh`, lines 269-281
**Finding:** `local terms_array=($query_terms)` performs word splitting and glob expansion. If a term matches a filename pattern, it expands.
**Fix:** Use `read -ra terms_array <<< "$query_terms"` or disable globbing with `set -f`.

### ANT-F6 [SIGNIFICANT] — Stderr capture conflates errors with data
**File:** `knowledge-retrieve.sh`, lines 920-930
**Finding:** Python stderr capture (`2>"$DEDUP_FILE.tmp"`) captures ALL stderr including tracebacks. If Python crashes before printing the `---SURFACED_PATHS---` marker, error text gets appended to dedup/feedback files.
**Fix:** Validate the marker exists before processing; log Python errors separately.

### ANT-F7 [SIGNIFICANT] — Fragile `set -e` in complex script
**File:** `knowledge-retrieve.sh`, line 14
**Finding:** `set -e` with complex command substitutions and pipelines is fragile in Bash 3.2. Transient filesystem errors could crash the entire retrieval with no useful error message.
**Fix:** Remove `set -e` and handle errors explicitly, or wrap the main flow in a function with explicit error handling.

### ANT-F17 [SIGNIFICANT] — Embedded Python should be extracted
**File:** `knowledge-retrieve.sh`, lines 617-918
**Finding:** ~300 lines of Python embedded in a bash heredoc, duplicating shell functions. Cannot be unit-tested, linted, or debugged independently.
**Fix:** Extract to a standalone `_system/scripts/akm_postfilter.py` that reads JSON from stdin and config from environment variables.

### ANT-F8 [MINOR] — Subprocess-heavy stop word detection
**File:** `knowledge-retrieve.sh`, line 104
**Finding:** `is_stop_word` spawns 5 `echo | grep` subprocesses per word. Use `case` pattern matching instead.

### ANT-F9 [MINOR] — DRY violation in path resolution
**File:** `knowledge-retrieve.sh`, lines 325-365
**Finding:** `qmd_to_real_path` resolution logic duplicated across 5+ functions. Extract to single `resolve_real_path()` function.

### ANT-F10 [MINOR] — Tag extraction may read past frontmatter
**File:** `knowledge-retrieve.sh`, lines 378-380
**Finding:** `sed` pattern doesn't constrain to frontmatter boundary. Limit to frontmatter first.

### ANT-F11 [MINOR] — Fragile JSON construction for feedback log
**File:** `knowledge-retrieve.sh`, line 928
**Finding:** `sed`-based quote wrapping breaks on paths with quotes or special characters. Use `python3` for JSON serialization.

### ANT-F12 [MINOR] — No validation on result_count parameter
**File:** `knowledge-retrieve.sh`, lines 240-258
**Finding:** `$result_count` interpolated into Python slice with no integer validation.

### ANT-F13 [MINOR] — Fail-open on date parsing defaults to maximum freshness
**File:** `knowledge-retrieve.sh`, lines 696-700
**Finding:** Failed date parsing returns 0 days age (maximum freshness) instead of penalizing. Default to high age (365) when date parsing fails.

### ANT-F14 [MINOR] — Bare `except:` clauses catch everything
**File:** `knowledge-retrieve.sh`, Python sections
**Finding:** Use `except Exception:` at minimum for file operations.

### ANT-F18 [MINOR] — Hardcoded vault path
**File:** `knowledge-retrieve.sh`, line 16
**Finding:** `VAULT_ROOT="/Users/tess/crumb-vault"` not portable. Use env var with fallback.

### ANT-F19 [MINOR] — Missing argument validation for flags
**File:** `knowledge-retrieve.sh`, lines 55-62
**Finding:** `shift 2` errors with `set -e` if a flag has no value. Validate before shifting.

### ANT-F20 [STRENGTH] — Graceful QMD degradation
**File:** `knowledge-retrieve.sh`, lines 73-84
**Finding:** Clean empty brief and exit 0 when QMD unavailable. Never blocks the operator's workflow.

### ANT-F21 [STRENGTH] — Domain-to-concept mapping
**File:** `knowledge-retrieve.sh`, lines 123-167
**Finding:** Clever bridge between operational project names and KB-relevant concept terms, working around BM25's lexical matching limitations.

### ANT-F22 [STRENGTH] — Three-tier decay model
**File:** `knowledge-retrieve.sh`, lines 430-460
**Finding:** Well-thought-out timeless/slow/fast decay with "most generous" decay when multiple tags match.

---

## Codex (GPT-5.3-Codex) — CDX

### Tool Execution

Codex ran 42 commands in read-only sandbox mode:
- `bash -n knowledge-retrieve.sh` -- PASS (syntax valid)
- `python3 -m pytest -q` -- failed: `FileNotFoundError: No usable temporary directory` (sandbox restriction, not a test failure)
- `command -v shellcheck` -- not installed
- `command -v mypy` -- not installed
- `rg` function definition/call-site verification -- confirmed all functions exist and are called
- `nl -ba` full file read in 4 passes (lines 1-260, 261-520, 521-780, 781-980)

### CDX-F1 [STRENGTH] — Session-end protocol update is internally consistent
**File:** `session-end-protocol.md`, lines 41-62
**Finding:** Step renumbering after adding QMD update is consistent, and failure behavior is explicitly non-blocking.

### CDX-F2 [SIGNIFICANT] — Dedup is process-scoped, not session-scoped
**File:** `knowledge-retrieve.sh`, lines 18, 626-630, 943-946
**Finding:** PID-scoped `DEDUP_FILE` resets every invocation. Same as ANT-F2.
**Fix:** Use stable session key instead of `$$`.

### CDX-F3 [SIGNIFICANT] — JSONL feedback entry not JSON-escaped
**File:** `knowledge-retrieve.sh`, line 954
**Finding:** Paths not JSON-escaped in feedback log. Same root cause as ANT-F11 but Codex specifically called out backslash and comma risks.
**Fix:** Build JSON with `python3 -c 'json.dumps(...)'` or `jq`.

### CDX-F4 [MINOR] — Dead bash functions
**File:** `knowledge-retrieve.sh`, lines 301-573
**Finding:** `QUERY_TAGS` and several bash helpers (`extract_note_tags`, `get_note_age_days`, `compute_decay_weight`, `is_personal_writing`) are defined but unused in the bash flow -- the Python section reimplements them.
**Fix:** Remove dead bash functions or route scoring through them consistently.

### CDX-F5 [MINOR] — Temp file assumes writable /tmp
**File:** `knowledge-retrieve.sh`, lines 18, 252-253, 940-956
**Finding:** No fallback if `/tmp` is not writable (as Codex sandbox demonstrated).
**Fix:** Use `mktemp` with fallback to a vault-local writable directory.

### CDX-F6 [SIGNIFICANT] — Shell-to-Python injection via string interpolation
**File:** `knowledge-retrieve.sh`, lines 633-650
**Finding:** Shell variables interpolated directly into `python3 -c` source. Same as ANT-F3.
**Fix:** Pass dynamic data via stdin/env.

### CDX-F7 [SIGNIFICANT] — No path traversal guard on qmd:// resolution
**File:** `knowledge-retrieve.sh`, lines 654-665, 833-838
**Finding:** `qmd://` path resolution does not normalize or constrain `..` traversal before `os.path.join(VAULT_ROOT, vault_path)`. A malicious indexed path could read files outside the vault root.
**Fix:** `real = os.path.realpath(...)` then enforce `real.startswith(os.path.realpath(VAULT_ROOT) + os.sep)`.

### CDX-F8 [MINOR] — Redundant per-file I/O in Python scoring
**File:** `knowledge-retrieve.sh`, lines 675-779, 844-867
**Finding:** Each result opens the note file multiple times for tags, date, type, and summary extraction.
**Fix:** Parse frontmatter/content once per file and reuse.

### CDX-F9 [MINOR] — No automated tests for retrieval engine
**File:** `knowledge-retrieve.sh` (overall)
**Finding:** No test suite for the core retrieval/scoring logic. pytest was blocked by sandbox but no test files were found for this script.
**Fix:** Add focused tests for argument parsing, dedup persistence, path normalization, JSON escaping, and ranking/diversity behavior.

---

## Cross-Reviewer Convergence

| Finding | ANT | CDX | Agreement |
|---|---|---|---|
| Broken dedup (PID-scoped) | F2 (CRITICAL) | F2 (SIGNIFICANT) | **Converge** -- both identified |
| Shell-to-Python injection | F3 (SIGNIFICANT) | F6 (SIGNIFICANT) | **Converge** -- identical finding |
| Fragile JSON in feedback log | F11 (MINOR) | F3 (SIGNIFICANT) | **Converge** -- CDX elevated severity |
| Path traversal risk | -- | F7 (SIGNIFICANT) | **CDX unique** -- Opus missed this |
| Fragile newline in tr | F1 (CRITICAL) | -- | **ANT unique** -- Codex missed this |
| Full vault grep perf | F4 (SIGNIFICANT) | -- | **ANT unique** |
| Dead bash functions | -- | F4 (MINOR) | **CDX unique** |
| set -e fragility | F7 (SIGNIFICANT) | -- | **ANT unique** |
| Extract Python block | F17 (SIGNIFICANT) | -- | **ANT unique** (CDX implied via dead-function finding) |

**Convergence rate:** 3 of 9 unique findings found by both reviewers (33%). Each reviewer contributed unique value.

---

## Summary

| Severity | ANT | CDX | Combined Unique |
|---|---|---|---|
| CRITICAL | 2 | 0 | 1 (1 declined) |
| SIGNIFICANT | 6 | 4 | 8 |
| MINOR | 9 | 4 | 11 |
| STRENGTH | 3 | 1 | 4 |
| **Total** | **20** | **9** | **24** |

---

## Coordinator Synthesis

### Consensus Findings (both reviewers)

1. **Broken dedup file scoping** (ANT-F2 + CDX-F2) — PID-scoped `/tmp/akm-surfaced-$$.txt` resets every invocation. Dedup mechanism never works across triggers within a session. Core design intent violated.
2. **Shell-to-Python injection** (ANT-F3 + CDX-F6) — Shell variables interpolated into `python3 -c` source. Single quotes in paths (e.g., `don't-look-back.md`) would break Python syntax and crash the post-filter step.
3. **Fragile JSON in feedback log** (ANT-F11 + CDX-F3) — `sed`-based quote wrapping in JSONL output breaks on paths with quotes, backslashes, or commas. Data integrity risk.

### Unique Findings — Confirmed

4. **ANT-F4: Full vault grep per invocation** — `grep -rl '^type: personal-writing'` scans ~1800 files every call. Not catastrophic (<2.3s total) but wasteful — result changes only when files are added.
5. **ANT-F5: Glob expansion in terms_array** — `local terms_array=($query_terms)` expands globs. Low probability but correctness risk.
6. **ANT-F6: Stderr conflation** — Python stderr (including tracebacks) captured into dedup/feedback data via `2>"$DEDUP_FILE.tmp"`.
7. **CDX-F4: Dead bash functions** — 6 bash functions (lines 301-573) defined but never called — Python section reimplements them. ~270 lines of dead code.
8. **CDX-F7: Path traversal on qmd:// resolution** — No guard against `..` traversal in path resolution. Low risk (QMD controls the index) but poor defensive coding.
9. **ANT-F17: Embedded Python block** — 300 lines of Python in a bash heredoc. Cannot be linted, tested, or debugged independently. Maintainability concern.

### Unique Findings — Lower Priority

10. **ANT-F7: `set -e` fragility** — Script uses `|| true` liberally, mitigating most `set -e` hazards. Current approach works.
11. **ANT-F8: Subprocess-heavy stop words** — 5 `echo | grep` per word. `case` statement would be faster but marginal impact.
12. **ANT-F13: Fail-open date parsing** — Returns 0 age (max freshness) on parse failure. Arguably correct — show content rather than hide it.
13. **CDX-F8: Redundant per-file I/O in Python** — Each result opens the note file multiple times. Consolidation would improve performance.

### Contradictions

None — where reviewers overlapped, they agreed on the nature of the issue. Severity ratings differed slightly (ANT rated dedup as CRITICAL, CDX as SIGNIFICANT) but both agreed it's broken.

### Considered and Declined

| Finding | Reason |
|---|---|
| **ANT-F1** (CRITICAL: fragile `tr ' ' '\n'`) | **Incorrect.** `tr` interprets `\n` as newline in its arguments on both GNU and BSD implementations. This is standard, portable, and not editor-dependent. The concern about editors stripping whitespace or normalizing line endings doesn't apply — there's no literal newline in the source code. Downgraded from CRITICAL to DECLINED. |
| **ANT-F18** (hardcoded vault path) | **Constraint.** Personal vault script on a single machine. Making it configurable is over-engineering. Safety gate already flagged as expected. |
| **ANT-F19** (missing shift 2 validation) | **Constraint.** `set -e` exits on missing value — correct behavior for a flag with no argument. Error message is poor but data integrity is fine. |
| **ANT-F14** (bare `except:` clauses) | **Defer.** Good Python hygiene but non-critical in embedded script context. Bundle with Python extraction (D1). |
| **ANT-F12** (no result_count validation) | **Constraint.** Only called internally with hardcoded integer 20. |
| **CDX-F5** (writable /tmp assumption) | **Constraint.** `/tmp` is always writable on macOS. Codex sandbox limitation, not a real-world risk. |
| **ANT-F10** (tag extraction past frontmatter) | **Low risk.** Vault notes follow consistent frontmatter conventions. The `sed` range terminates at non-indented lines. |

### Action Items

**Must-fix:**

| ID | Source | Fix | Location |
|---|---|---|---|
| A1 | ANT-F2, CDX-F2 | Change dedup file from `$$` (PID) to date-based key: `/tmp/akm-surfaced-$(date +%Y%m%d).txt` | Line 19 |
| A2 | ANT-F11, CDX-F3 | Replace `sed`-based JSON construction with `python3 -c 'import json; ...'` for proper escaping | Line 954 |

**Should-fix:**

| ID | Source | Fix | Location |
|---|---|---|---|
| A3 | ANT-F3, CDX-F6 | Pass shell variables to Python via env vars (`export` + `os.environ`) instead of string interpolation | Lines 636-650 |
| A4 | CDX-F4 | Remove dead bash functions (lines 301-573, ~270 lines) — Python section handles all post-filtering | Lines 301-573 |
| A5 | ANT-F5 | Use `read -ra terms_array <<< "$query_terms"` or prefix with `set -f` to prevent glob expansion | Lines 256, 269 |
| A6 | ANT-F4 | Cache personal writing count in a temp file with 1-day TTL instead of scanning vault every invocation | Line 516-521 |
| A7 | CDX-F7 | Add `os.path.realpath()` guard with `startswith(VAULT_ROOT)` check in Python path resolution | Lines 664-665 |
| A8 | ANT-F6 | Validate `---SURFACED_PATHS---` marker exists in stderr capture before processing; redirect Python errors to `/dev/null` or separate log | Lines 940-946 |

**Defer:**

| ID | Source | Reason |
|---|---|---|
| D1 | ANT-F17 | Extract Python to standalone `akm_postfilter.py` — significant refactor, do when script needs major changes or AKM-010 (testing) begins |
| D2 | ANT-F8 | Replace subprocess stop words with `case` — marginal perf improvement |
| D3 | ANT-F9 | DRY path resolution — coupled to D1 extraction |
| D4 | ANT-F7 | Replace `set -e` with explicit error handling — working fine with `|| true` patterns |
| D5 | CDX-F9 | Add test suite — covered by AKM-010 in spec |
| D6 | CDX-F8 | Consolidate per-file I/O — perf improvement, bundle with D1 |
| D7 | ANT-F13 | Change fail-open date parsing default — arguable either way, not a bug |
