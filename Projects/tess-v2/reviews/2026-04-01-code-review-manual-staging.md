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
  files_changed: 6
  insertions: 2040
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
    latency_ms: 89125
    attempts: 1
    token_usage:
      input_tokens: 23361
      output_tokens: 4319
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-code-review-manual-staging-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 89143
    tools_run:
      - "ls -la"
      - "rg --files | head -n 200"
      - "cat pyproject.toml"
      - "ls .venv/bin | rg 'mypy|pyright|basedpyright|pyre|ruff|pytest|python'"
      - ". .venv/bin/activate && pytest -q"
      - ". .venv/bin/activate && (python -m mypy --version || true) && (pyright --version || true) && (ruff --version || true)"
      - "nl -ba src/tess/locks.py"
      - "nl -ba src/tess/promotion.py"
      - "nl -ba src/tess/staging.py"
      - "nl -ba tests/test_locks.py"
      - "nl -ba tests/test_staging.py"
      - "nl -ba tests/test_promotion.py"
    token_usage:
      input_tokens: 228844
      output_tokens: 5083
    jsonl_log: Projects/tess-v2/reviews/raw/2026-04-01-code-review-manual-staging-codex.jsonl
    raw_text: Projects/tess-v2/reviews/raw/2026-04-01-code-review-manual-staging-codex.txt
tags:
  - review
  - code-review
status: active
---

# Code Review: Staging/Promotion Engine (Manual)

**Scope:** `locks.py`, `promotion.py`, `staging.py` + test suites (6 new files, +2040 lines)

## Reviewer: Anthropic (Claude Opus 4.6)

### ANT-F1
- **Severity**: CRITICAL
- **File**: `src/tess/locks.py`, lines 140-157
- **Finding**: GLOB-based ancestor/descendant overlap detection has a SQL injection-like pattern vulnerability through path content containing GLOB metacharacters (`*`, `?`, `[`, `]`).
- **Why**: If a vault path contains GLOB special characters (e.g., `Projects/[draft]/spec.md`), the GLOB query will misinterpret them as pattern syntax, causing false positives or false negatives in overlap detection. This breaks the lock safety guarantee.
- **Fix**: Escape GLOB metacharacters in `norm_path` before using it in GLOB expressions. Create a helper:
```python
def _escape_glob(s: str) -> str:
    """Escape GLOB metacharacters in a string."""
    for ch in ('[', ']', '*', '?'):
        s = s.replace(ch, f'[{ch}]')
    return s
```
Then use `_escape_glob(norm_path)` in the GLOB queries at lines 143 and 153.

### ANT-F2
- **Severity**: CRITICAL
- **File**: `src/tess/promotion.py`, lines 291-293
- **Finding**: The manifest file is named `.promotion-manifest.yaml` but is written as JSON with `json.dump`. The file extension is misleading and, more importantly, `_read_manifest` uses `json.load` -- if anything ever tries to parse this as YAML, it will break.
- **Why**: Ticking time bomb. A future maintainer or recovery tool parsing `.yaml` files will get confused. The test at `test_promotion.py` line 595 also uses a `.json` extension for the round-trip test, creating inconsistency.
- **Fix**: Rename to `.promotion-manifest.json` throughout, or actually use YAML serialization.

### ANT-F3
- **Severity**: SIGNIFICANT
- **File**: `src/tess/locks.py`, lines 99-100
- **Finding**: `_connect()` sets `PRAGMA journal_mode=WAL` on every connection but `_ensure_db()` creates a connection without WAL mode. Schema creation runs under the default `DELETE` journal mode.
- **Why**: Minor performance waste and inconsistent journal mode during initialization.
- **Fix**: Have `_ensure_db` use `_connect` instead of creating a separate connection.

### ANT-F4
- **Severity**: SIGNIFICANT
- **File**: `src/tess/promotion.py`, lines 304-329
- **Finding**: `lock_timeout` is declared as a parameter but `fcntl.flock` uses blocking `LOCK_EX` with no timeout mechanism. The flock is held during hash verification and file I/O.
- **Why**: A stuck lock blocks promotion indefinitely. `lock_timeout` parameter is unused.
- **Fix**: Implement timeout via non-blocking retry loop with `LOCK_EX | LOCK_NB`, or remove the parameter.

### ANT-F5
- **Severity**: SIGNIFICANT
- **File**: `src/tess/promotion.py`, lines 239-256
- **Finding**: `verify_hashes` mutates `PromotionOperation` objects (setting `hash_at_promotion`) as a side effect. Duplicate assignment at line 248.
- **Why**: Side-effecting a "verify" method is surprising and error-prone.
- **Fix**: Rename to `verify_and_record_hashes` or separate mutation from verification. Remove duplicate assignment.

### ANT-F6
- **Severity**: SIGNIFICANT
- **File**: `src/tess/promotion.py`, lines 378-406
- **Finding**: `recover_promotion` calls `promote()` which re-verifies lock-time hashes. For already-promoted files, canonical content now matches staged content, not lock-time hash -- causing false conflicts and recovery failure.
- **Why**: A crash during `copying` phase makes recovery non-resumable.
- **Fix**: Skip hash verification for operations already marked `promoted=True`:
```python
def verify_hashes(self, manifest, skip_promoted=False):
    for op in manifest.operations:
        if skip_promoted and op.promoted:
            continue
        # ... existing logic
```

### ANT-F7
- **Severity**: SIGNIFICANT
- **File**: `src/tess/locks.py`, lines 58-64
- **Finding**: `_normalize_path` doesn't handle absolute paths or paths starting with `/`. Could allow path traversal outside the vault.
- **Why**: If a caller passes `/etc/shadow`, it normalizes but is still treated as vault-relative.
- **Fix**: Strip leading `/` and reject absolute paths with `ValueError`.

### ANT-F8
- **Severity**: SIGNIFICANT
- **File**: `src/tess/promotion.py`, lines 336-339
- **Finding**: `os.rename` used instead of `os.replace` for atomic file replacement.
- **Why**: `os.replace` is the explicit cross-platform atomic replace and signals intent more clearly.
- **Fix**: Change `os.rename(tmp_name, str(dest_full))` to `os.replace(tmp_name, str(dest_full))`.

### ANT-F9
- **Severity**: SIGNIFICANT
- **File**: `src/tess/staging.py`, lines 39-40
- **Finding**: `_sealed` state is in-memory only -- lost on process restart.
- **Why**: Sealed staging directories can be written to after restart. Gap in crash-recovery engine.
- **Fix**: Persist seal state with a `.sealed` marker file in the staging directory.

### ANT-F10
- **Severity**: SIGNIFICANT
- **File**: `src/tess/promotion.py`, lines 416-433
- **Finding**: `rollback()` uses non-atomic `shutil.copy2` to restore files, contradicting the atomicity goals.
- **Why**: A crash during rollback leaves the vault in an inconsistent state.
- **Fix**: Use the same `mkstemp` + `os.replace` + `fsync` pattern used in `promote()`.

### ANT-F11
- **Severity**: MINOR
- **File**: `src/tess/locks.py`, line 106
- **Finding**: `acquire_locks` doesn't deduplicate `target_paths`.
- **Fix**: `normalized = list(dict.fromkeys(_normalize_path(p) for p in target_paths))`.

### ANT-F12
- **Severity**: MINOR
- **File**: `src/tess/promotion.py` + `src/tess/locks.py`
- **Finding**: `_hash_file` is duplicated identically in both modules.
- **Fix**: Define once and import.

### ANT-F13
- **Severity**: MINOR
- **File**: `src/tess/locks.py`, lines 246-248
- **Finding**: `get_lock_holder` returns at most one contract_id but schema allows multiple via composite PK.
- **Fix**: Document the invariant or add UNIQUE constraint on path alone.

### ANT-F14
- **Severity**: MINOR
- **File**: `tests/test_locks.py`, lines 284-286
- **Finding**: `test_default_path` monkeypatches `Path.home` fragily.
- **Fix**: Use `monkeypatch.setenv("HOME", str(tmp_path))`.

### ANT-F15
- **Severity**: MINOR
- **File**: Tests (all)
- **Finding**: No tests for concurrent access patterns, flock behavior, or mid-copy crash rollback verification.
- **Fix**: Add multiprocessing/threading lock serialization tests, mock-crash rollback tests, and ANT-F6 scenario tests.

### ANT-F16
- **Severity**: MINOR
- **File**: `src/tess/promotion.py`, line 84
- **Finding**: `_hash_bytes` is defined but never used. Dead code.
- **Fix**: Remove it.

### ANT-F17
- **Severity**: MINOR
- **File**: `src/tess/staging.py`, line 17
- **Finding**: `StagingState` dataclass is defined but never used.
- **Fix**: Remove it or integrate it.

### ANT-F18
- **Severity**: STRENGTH
- **File**: `src/tess/promotion.py`, lines 320-348
- **Finding**: The atomic copy pattern (`mkstemp` -> write -> fsync -> rename -> fsync dir) is textbook correct for crash-safe POSIX file replacement. Per-operation manifest persistence enables exact resumption.

### ANT-F19
- **Severity**: STRENGTH
- **File**: `src/tess/locks.py`, lines 115-175
- **Finding**: All-or-nothing lock acquisition with `BEGIN IMMEDIATE` and explicit `ROLLBACK` on conflict is well-implemented.

### ANT-F20
- **Severity**: STRENGTH
- **File**: `tests/test_locks.py`, lines 183-195
- **Finding**: `test_no_false_positive_prefix` catches the classic prefix-matching bug (`foo` vs `foo2`).

**Anthropic Summary:** CRITICAL 2, SIGNIFICANT 7, MINOR 7, STRENGTH 3

---

## Reviewer: Codex (GPT-5.3-Codex)

### Tool Execution

Codex ran 12 shell commands in the project repo before reviewing:

| Command | Result |
|---|---|
| `ls -la` | Explored project structure |
| `rg --files \| head -n 200` | File inventory |
| `cat pyproject.toml` | Read project config |
| `ls .venv/bin \| rg 'mypy\|pyright\|...'` | Tool discovery |
| `.venv/bin/activate && pytest -q` | **Failed** -- no usable temp directory in sandbox |
| `.venv/bin/activate && mypy/pyright/ruff` | **Not installed** in project env |
| `nl -ba src/tess/locks.py` | Read source with line numbers |
| `nl -ba src/tess/promotion.py` | Read source with line numbers |
| `nl -ba src/tess/staging.py` | Read source with line numbers |
| `nl -ba tests/test_locks.py` | Read test file |
| `nl -ba tests/test_promotion.py` | Read test file |
| `nl -ba tests/test_staging.py` | Read test file |

**Note:** pytest and type-checker runs were blocked by read-only sandbox constraints (no writable temp directory). Codex proceeded with manual code review.

### CDX-F1
- **Severity**: CRITICAL
- **File**: `src/tess/staging.py:42-45, 46-58, 77-85, 113-115`
- **Finding**: `contract_id` is used directly in path joins with no validation/normalization.
- **Why**: Absolute paths or `..` segments can escape the staging root; `cleanup_staging()` can delete arbitrary directories (`shutil.rmtree`) outside `_staging`.
- **Fix**: Validate `contract_id` (reject absolute paths, `..`, separators outside allowed charset), resolve and enforce `resolved_path.is_relative_to(self._root.resolve())` before any filesystem operation.

### CDX-F2
- **Severity**: CRITICAL
- **File**: `src/tess/promotion.py:245-260, 389-391, 426-427, 520-525`
- **Finding**: `source`/`destination` paths are not normalized or confined to `staging_root`/`vault_root`.
- **Why**: A malicious manifest/`target_path_map` can write/read/delete outside the vault or staging roots.
- **Fix**: Normalize with `PurePosixPath`, reject absolute/traversal, enforce resolved paths stay under configured roots.

### CDX-F3
- **Severity**: CRITICAL
- **File**: `src/tess/promotion.py:245-250`
- **Finding**: `build_manifest()` silently allows destinations with no corresponding write lock (`lock is None` -> treated as `NEW_FILE`).
- **Why**: Bypasses the "write-lock gates promotion" invariant; promotion can proceed without lock ownership.
- **Fix**: Require every `canonical_path` in `target_path_map` to exist in `lock_by_path`; raise a hard error otherwise.

### CDX-F4
- **Severity**: SIGNIFICANT
- **File**: `src/tess/promotion.py:348-350, 487-500`
- **Finding**: Crash recovery re-runs `verify_hashes()` against lock-time hashes even for already promoted ops.
- **Why**: Promoted files legitimately differ from lock-time hash; recovery falsely fails.
- **Fix**: Skip hash-conflict checks for `op.promoted=True` in recovery path.

### CDX-F5
- **Severity**: SIGNIFICANT
- **File**: `src/tess/locks.py:149-167`
- **Finding**: GLOB overlap checks use lock paths as GLOB patterns without escaping wildcard chars.
- **Why**: Paths containing `*`, `?`, `[]` cause false matches/misses in overlap detection.
- **Fix**: Escape metacharacters or replace with deterministic prefix logic.

### CDX-F6
- **Severity**: SIGNIFICANT
- **File**: `src/tess/promotion.py:205, 346, 514`
- **Finding**: `lock_timeout` is documented/configured but never used; flock is fully blocking.
- **Fix**: Implement timeout loop with `LOCK_EX | LOCK_NB` + retry/sleep, or remove parameter.

### CDX-F7
- **Severity**: SIGNIFICANT
- **File**: `src/tess/promotion.py:522-527`
- **Finding**: Rollback restore does not ensure destination parent directories exist.
- **Why**: If parent dirs were removed/changed, rollback fails even with valid backups.
- **Fix**: `dest_full.parent.mkdir(parents=True, exist_ok=True)` before `copy2`.

### CDX-F8
- **Severity**: MINOR
- **File**: `src/tess/promotion.py:114-122, 336-340`
- **Finding**: Manifest file named `.promotion-manifest.yaml` but serialized as JSON.
- **Fix**: Rename to `.json` or emit YAML consistently.

### CDX-F9
- **Severity**: MINOR
- **File**: `src/tess/promotion.py:394, 402`
- **Finding**: Promotion reads full staged files into memory (`read_bytes`) before writing.
- **Why**: Large artifacts can spike memory.
- **Fix**: Stream copy in chunks or use `shutil.copyfileobj`.

### CDX-F10
- **Severity**: MINOR
- **File**: Tests (all)
- **Finding**: Missing tests for traversal/absolute-path rejection, manifest build without lock, GLOB metacharacter behavior, true partial-crash recovery, lock timeout behavior.
- **Fix**: Add targeted negative/concurrency/recovery tests.

### CDX-F11
- **Severity**: STRENGTH
- **File**: `src/tess/locks.py:129-195`
- **Finding**: Lock acquisition uses `BEGIN IMMEDIATE` and performs conflict checks + inserts in a single transaction. Strong all-or-nothing behavior.

**Codex Summary:** CRITICAL 3, SIGNIFICANT 4, MINOR 3, STRENGTH 1
