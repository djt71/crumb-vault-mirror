---
type: review
review_type: code
review_mode: diff
scope: manual
project: tess-v2
domain: software
language: python
framework: pytest, SQLite, PyYAML
diff_stats:
  files_changed: 5
  insertions: 1567
  deletions: 0
skill_origin: code-review
created: 2026-04-06
updated: 2026-04-06
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
    - "Hardcoded path /Users/tess/crumb-vault in dispatch.py DEFAULT_VAULT_ROOT"
reviewer_meta:
  anthropic:
    http_status: 200
    latency_ms: 71799
    attempts: 1
    token_usage:
      input_tokens: 19591
      output_tokens: 3539
    raw_json: reviews/raw/2026-04-06-code-review-manual-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 92089
    tools_run:
      - "pwd; ls -la"
      - "rg --files | rg pyproject.toml|setup.cfg|..."
      - "rg --files src/tess | rg history.py|cli.py|..."
      - "cat pyproject.toml"
      - "ls -la scripts"
      - "rg -n mypy|pyright|ruff|typecheck|typing -S ."
      - ".venv/bin/python -m mypy src tests"
      - ".venv/bin/pytest -q"
      - "nl -ba src/tess/session_report.py"
      - "nl -ba src/tess/dispatch.py"
      - "nl -ba src/tess/cli.py (2 reads)"
      - "nl -ba src/tess/history.py"
      - "nl -ba tests/test_session_report.py"
      - "nl -ba tests/test_dispatch.py"
    token_usage:
      input_tokens: 295978
      output_tokens: 5058
    jsonl_log: reviews/raw/2026-04-06-code-review-manual-codex.jsonl
    raw_text: reviews/raw/2026-04-06-code-review-manual-codex.txt
tags:
  - review
  - code-review
  - amendment-z
---

# Code Review: Amendment Z Phase A — Core Loop

**Scope:** 5 files changed, +1567/-0 (all new code)
**Files:** `cli.py` (modified), `dispatch.py` (new), `session_report.py` (new), `test_dispatch.py` (new), `test_session_report.py` (new)

## Reviewer 1: Claude Opus (anthropic/claude-opus-4-6)

### ANT-F1 — CRITICAL
**File:** `src/tess/dispatch.py`, lines 1-7
**Finding:** Possible diff rendering artifact — verify file starts with valid Python.
**Fix:** Verify actual file on disk. Likely a diff display issue, not a real bug.

### ANT-F2 — SIGNIFICANT
**File:** `src/tess/dispatch.py`, `append_claim()` (~lines 220-260)
**Finding:** Read-modify-write on `claims.yaml` is not atomic. Process crash during write truncates file to zero (opened with `"w"` mode).
**Fix:** Write to temp file, then `os.replace()` for atomic rename.

### ANT-F3 — SIGNIFICANT
**File:** `src/tess/dispatch.py`, `get_ready_items()` and `get_blocked_items()` (~lines 140-200)
**Finding:** Both functions call `datetime.now(timezone.utc).date()` independently — midnight UTC race. Also `dispatch_type` filter asymmetry: only applied in `get_ready_items`, not `get_blocked_items`.
**Fix:** Accept `today` as parameter; add `dispatch_type` filtering to `get_blocked_items` or document asymmetry.

### ANT-F4 — SIGNIFICANT
**File:** `src/tess/session_report.py`, `_SCHEMA` (~lines 50-65)
**Finding:** No schema version tracking or migration path. UNIQUE constraint on `session_id` is a future commitment.
**Fix:** Add `schema_version` table for future migration hooks.

### ANT-F5 — SIGNIFICANT
**File:** `src/tess/session_report.py`, `SessionReportDB` methods
**Finding:** Each method creates/closes a new connection. `record_session` lacks transaction safety — no rollback on commit failure.
**Fix:** Use `with conn:` context manager for auto-commit/rollback.

### ANT-F6 — SIGNIFICANT
**File:** `src/tess/cli.py`, `_cmd_sr_query()` (~lines 480-510)
**Finding:** `json.loads(r.dispatch_json)` has no try/except — corrupt JSON crashes entire query display.
**Fix:** Wrap in try/except with fallback.

### ANT-F7 — MINOR
**File:** `src/tess/dispatch.py`, `get_stale_claims()` (~line 268)
**Finding:** `has_session_fn` typed as `callable` (builtin) not `Callable[[str], bool]`.
**Fix:** Use `typing.Callable[[str], bool]`.

### ANT-F8 — MINOR
**File:** `src/tess/dispatch.py`, `load_claims()` (~lines 210-225)
**Finding:** Missing field in a claim entry produces raw `KeyError` instead of descriptive `ValueError`.
**Fix:** Add field validation loop like `_parse_queue_item`.

### ANT-F9 — MINOR
**File:** `src/tess/cli.py`, `_cmd_sr_write()` (~lines 425-460)
**Finding:** `session.date` not validated — YAML auto-parsing footgun (date object vs integer).
**Fix:** Validate date format with `datetime.fromisoformat()`.

### ANT-F10 — MINOR
**File:** `src/tess/dispatch.py`, lines 25-27
**Finding:** `DEFAULT_VAULT_ROOT` hardcoded to `/Users/tess/crumb-vault`.
**Fix:** Use `Path.home() / "crumb-vault"` or make parameter required.

### ANT-F11 — MINOR
**File:** `src/tess/cli.py`, `_cmd_dispatch_show()` (~line 565)
**Finding:** O(n^2) list membership check for `--all` flag filtering.
**Fix:** Use set of IDs instead.

### ANT-F12 — MINOR
**File:** `tests/test_session_report.py`, `TestQuery.test_limit`
**Finding:** Limit test verifies count but not ordering correctness.
**Fix:** Verify returned records are the most recent.

### ANT-F13 — MINOR
**File:** `tests/test_dispatch.py`
**Finding:** Missing CLI integration tests, stdin input test, malformed claim entry test.
**Fix:** Add CLI integration tests via `main()` with argv.

### ANT-F14 — STRENGTH
Clean separation: YAML for human-editable queue, SQLite for machine-written reports. Frozen dataclasses prevent mutation. Dependency injection in `get_stale_claims` is well-designed.

### ANT-F15 — STRENGTH
Thorough test coverage with readable helper functions (`_report`, `_item`, `_minimal_queue`).

### ANT-F16 — STRENGTH
Index coverage matches query patterns. UNIQUE constraint serves as both integrity check and lookup index.

**Opus summary: 1 CRITICAL, 5 SIGNIFICANT, 7 MINOR, 3 STRENGTH**

---

## Reviewer 2: Codex (codex/gpt-5.3-codex)

### Tool Execution

Codex executed 15 shell commands in the repo:
1. **Project discovery:** `pwd`, `ls`, `rg --files` to map project structure
2. **Config inspection:** `cat pyproject.toml`, `rg` for type checker/linter config
3. **Type checker:** `.venv/bin/python -m mypy src tests` — **FAILED** (mypy not installed)
4. **Test suite:** `.venv/bin/pytest -q` — **FAILED** (FileNotFoundError on temp directory in sandbox)
5. **Source inspection:** Read all 5 changed files plus `history.py` for pattern comparison

Both tool failures were sandbox environment issues, not code bugs. Findings are based on static analysis and source inspection.

### CDX-F1 — SIGNIFICANT
**File:** `src/tess/dispatch.py`, lines 303/313/315
**Finding:** `get_stale_claims` resolves by `session_id` only, not `(session_id, item_id)`. One resolved item in a session incorrectly marks other claimed items as resolved.
**Fix:** Track resolution keys as `(session_id, item_id)` tuples.

### CDX-F2 — SIGNIFICANT
**File:** `dispatch.py` lines 86/220, `cli.py` line 530
**Finding:** `load_queue`/`load_claims` don't normalize `yaml.YAMLError` to `ValueError`. CLI only catches `ValueError`, so malformed YAML produces raw traceback.
**Fix:** Catch `yaml.YAMLError` in loaders and re-raise as `ValueError`.

### CDX-F3 — SIGNIFICANT
**File:** `src/tess/dispatch.py`, lines 257/281
**Finding:** `append_claim` non-atomic write (same as ANT-F2).
**Fix:** Temp file + `os.replace()`.

### CDX-F4 — SIGNIFICANT
**File:** `session_report.py` line 154, `cli.py` line 149
**Finding:** `--limit` accepts negative values. SQLite `LIMIT -1` removes bound entirely.
**Fix:** Enforce `limit >= 1` in CLI and DB method.

### CDX-F5 — SIGNIFICANT
**File:** `session_report.py` lines 225/41
**Finding:** `generate_session_id()` has second-level precision while `session_id` is UNIQUE. Two writes in the same second collide.
**Fix:** Add microsecond precision or monotonic counter.

### CDX-F6 — MINOR
**File:** `dispatch.py` line 19, `cli.py` line 207
**Finding:** Hardcoded default vault path vs CLI env resolution (same as ANT-F10).
**Fix:** Centralize vault-root resolution.

### CDX-F7 — MINOR
**File:** `dispatch.py` line 287
**Finding:** `callable` type annotation (same as ANT-F7).
**Fix:** `Callable[[str], bool]`.

### CDX-F8 — MINOR
**File:** `session_report.py` lines 55/176/210
**Finding:** Single-column indexes may not cover composite query pattern `(orphaned, date, created_at)`.
**Fix:** Add composite index for primary query shape.

### CDX-F9 — STRENGTH
Parameterized SQL queries throughout — no injection risk.

### CDX-F10 — STRENGTH
`yaml.safe_load` used consistently — no unsafe loader.

**Codex summary: 0 CRITICAL, 5 SIGNIFICANT, 3 MINOR, 2 STRENGTH**

---

## Cross-Reviewer Convergence

| Finding | Opus | Codex | Agreement |
|---------|------|-------|-----------|
| Non-atomic claims write | ANT-F2 | CDX-F3 | Full convergence |
| Hardcoded vault path | ANT-F10 | CDX-F6 | Full convergence |
| `callable` type annotation | ANT-F7 | CDX-F7 | Full convergence |
| Parameterized SQL / safe_load | ANT-F16 | CDX-F9/F10 | Full convergence |

**Unique to Opus:** Diff rendering artifact (F1), midnight date race (F3), schema versioning (F4), connection lifecycle (F5), JSON parse safety (F6), claim field validation (F8), date format validation (F9), O(n^2) filtering (F11), test ordering (F12), CLI integration gaps (F13)

**Unique to Codex:** Stale claims resolution granularity (F1), YAML error normalization (F2), negative limit (F4), session ID collision (F5), composite index (F8)
