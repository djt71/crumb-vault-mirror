---
type: review
review_type: code
review_mode: diff
scope: manual
project: tess-v2
domain: software
language: mixed
framework: bash-wrappers-yaml-contracts
diff_stats:
  files_changed: 16
  insertions: 118
  deletions: 23
skill_origin: code-review
created: 2026-04-15
updated: 2026-04-15
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
    - "9 occurrences of /Users/tess/... absolute paths — intentional (vault root + hardcoded wrapper targets), not sanitized"
reviewer_meta:
  anthropic:
    http_status: 200
    latency_ms: 78965
    attempts: 1
    token_usage:
      input_tokens: 8036
      output_tokens: 3380
    raw_json: Projects/tess-v2/reviews/raw/2026-04-15-code-review-manual-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 71709
    tools_run:
      - "ls -la"
      - "rg --files | head -n 200"
      - "cat pyproject.toml"
      - "git status --short"
      - ". .venv/bin/activate && python -m mypy src tests (failed: No module named mypy)"
      - ". .venv/bin/activate && python -m pytest (failed: No usable temporary directory found)"
      - "nl -ba scripts/run-vault-check.sh"
      - "nl -ba scripts/fif-attention.sh"
      - "nl -ba scripts/fif-capture.sh"
      - "nl -ba src/tess/executors/shell.py"
      - "rg -n 'service:' scripts/*.sh contracts/*.yaml"
      - "nl -ba src/tess/validator.py"
      - "nl -ba src/tess/contract.py"
      - "rg -n 'content_not_contains|line_count_range|...' src/tess"
      - "nl -ba src/tess/runner.py"
      - "nl -ba contracts/vault-health.yaml"
    token_usage:
      input_tokens: 290038
      cached_input_tokens: 234112
      output_tokens: 4231
    jsonl_log: Projects/tess-v2/reviews/raw/2026-04-15-code-review-manual-codex.jsonl
    raw_text: Projects/tess-v2/reviews/raw/2026-04-15-code-review-manual-codex.txt
tags:
  - review
  - code-review
---

# Code Review — TV2-056 Stale-Artifact Propagation (manual)

**Scope:** propagation of the TV2-043 scout-remediation tee-to-staging pattern to 8 additional wrappers and their contracts.
**Diff:** 16 files, +118/-23 lines (8 `*.sh` wrappers, 8 `*.yaml` contracts).
**Reviewers:** Claude Opus 4.6 (API, architectural reasoning) + Codex GPT-5.3 (CLI, tool-grounded).
**Both reviewers succeeded.** Safety gate: clean (soft warning only on absolute paths, no action needed).

---

## Claude Opus (ANT)

# Code Review: TV2-056 — Propagate tee-to-staging pattern to 8 wrappers

## Findings

---

### F1 (ANT-F1)
- **Severity**: CRITICAL
- **File**: `scripts/run-vault-check.sh`, line ~12 (final line)
- **Finding**: `|| true` guards the entire pipeline, not just `vault-check.sh`. If `tee` fails (e.g., `$STAGING_PATH` is unwritable), the `|| true` silently swallows that failure too. But more importantly: `set -u` is set but **not** `set -e` or `set -o pipefail` in this script. The other 7 wrappers use `set -eu`. This script only uses `set -u`. That's deliberate (the comment says "always exits 0") — but it means the `|| true` is the **sole** protection against vault-check's exit 1. With the new pipeline `bash ... 2>&1 | tee "$LOG_FILE" || true`, under **no pipefail** (which is the case here), the pipeline exit code is already that of `tee` (the last command), not `bash`. So if vault-check exits 1 but tee succeeds, the pipeline exits 0 even *without* `|| true`. The `|| true` only fires if `tee` itself fails. This is correct behavior but **accidentally so** — if someone later adds `set -o pipefail` (to match the other wrappers), vault-check's exit 1 would propagate through the pipeline, `|| true` would catch it, but the logged `$?` / `PIPESTATUS` debugging story gets confusing. This is not a bug today but is fragile.
- **Why**: The other 7 wrappers use `set -eu`; a future maintainer normalizing to `set -euo pipefail` across all wrappers would silently change behavior here unless they notice the deliberate omission.
- **Fix**: Add a comment explaining the intentional `set -u` (no `-e`, no `pipefail`):
  ```bash
  # Note: intentionally set -u only (not -e or -o pipefail).
  # vault-check.sh exits 1 on warnings; we must always exit 0.
  set -u
  ```

---

### F2 (ANT-F2)
- **Severity**: SIGNIFICANT
- **File**: `scripts/fif-capture.sh`, lines ~57–85 (the `{ cat <<YAML ... ; if ...; fi; } | tee` block)
- **Finding**: Under `set -eu` (line 11 of the original), the `while IFS= read -r line` subshell inside the brace group runs in the **left side of a pipe**. With bash's default (no `pipefail`), if the brace-group's `grep` inside the while fails or the subshell has an error, it's masked — `tee`'s exit code wins. This is actually *fine* for this use case. However, if `set -o pipefail` is ever added, a `grep` finding zero matches inside the `while` (impossible here since ERRORS > 0 guards it, but the `grep` pattern could drift) would kill the script. More concretely: the `{ ... } | tee` pattern means `set -e` does **not** apply inside the left side of the pipe (bash disables `errexit` in pipeline components). So if `cat <<YAML` somehow fails, the script continues and tee gets partial output. This is acceptable for a personal project but worth documenting.
- **Why**: The brace-group-pipe pattern is subtly different from the simple `cat <<YAML | tee` used in the other 7 wrappers. `set -e` is disabled in pipeline subshells in bash, so errors inside `{}` won't halt execution.
- **Fix**: No code change required, but add a brief comment:
  ```bash
  # Brace group needed so the optional errors section shares the same tee.
  # Note: set -e is inactive inside the left side of a pipe in bash.
  {
  ```

---

### F3 (ANT-F3)
- **Severity**: SIGNIFICANT
- **File**: `contracts/fif-feedback-health.yaml`, lines ~30–35; `scripts/fif-feedback-health.sh`, line ~50
- **Finding**: The contract tests for `substring: "service: fif-feedback"` but the wrapper emits `service: fif-feedback` (bare, no quotes around value). This **matches correctly** — the substring check will find it. However, note the service name is `fif-feedback` (not `fif-feedback-health`). This is consistent with what the wrapper actually emits, so it's correct. Flagging only to confirm: the contract name `fif-feedback-health` intentionally differs from the service line `fif-feedback`. This asymmetry is the only one across all 8 contracts and could confuse a future maintainer.
- **Why**: All other contracts have `service:` values matching the contract name. This one doesn't.
- **Fix**: Either rename to `service: fif-feedback-health` in the wrapper (and update the contract), or add a comment in the contract explaining the intentional mismatch. Low urgency.

---

### F4 (ANT-F4)
- **Severity**: SIGNIFICANT
- **File**: `contracts/vault-gc.yaml`, lines ~20–30; `scripts/vault-gc.sh`, line ~48
- **Finding**: The contract adds `test_deleted_count_field` checking for `substring: "deleted_count:"` but does **not** add a `test_status_not_failed` check like every other contract in this diff. The vault-gc wrapper also doesn't emit a `status:` field at all — it emits `service`, `timestamp`, `dry_run`, `scanned_count`, `deleted_count`, `paths_removed`. This is internally consistent (no status field → no status check), but it means vault-gc is the only wrapper that has no failure-detection contract test. If vault-gc silently breaks, the contract would still pass as long as the heredoc is reached.
- **Why**: The bug being fixed is about stale artifacts going undetected. Adding `file_exists` + `content_contains: "service: vault-gc"` catches staleness, but there's no `status` field to catch runtime failures of the GC logic itself.
- **Fix**: Consider adding a `status:` field to `vault-gc.sh`'s output and a corresponding `content_not_contains: 'status: "failed"'` test, matching the pattern of the other 7 wrappers. Low urgency — GC failures are less critical than capture/scoring failures.

---

### F5 (ANT-F5)
- **Severity**: SIGNIFICANT
- **File**: `scripts/fif-attention.sh`, line ~25; `scripts/fif-capture.sh`, line ~25
- **Finding**: The FIF-paused early-exit heredoc now tees to `$LOG_FILE`. It emits `status: skipped` (bare, not quoted). The contract checks `content_not_contains: 'status: "failed"'`. The string `skipped` doesn't contain `"failed"`, so this passes correctly. However, the early-exit heredoc also emits fields like `items_scored: 0` (fif-attention) / `items_captured: 0` (fif-capture) and `tier_distribution:` / `adapters_run:` are **absent**. The contracts have `test_tier_distribution` / `test_items_captured` content_contains checks. If FIF is paused, the `items_captured: 0` line IS present in fif-capture's paused output, so `content_contains: "items_captured:"` passes. But `content_contains: "tier_distribution:"` in fif-attention's contract — the paused output doesn't include `tier_distribution:`. **This means the fif-attention contract will fail when FIF is paused.**
- **Why**: The paused early-exit path writes a minimal YAML that lacks `tier_distribution:`, which is a required content_contains check.
- **Fix**: Add `tier_distribution: {}` (or `tier_distribution: "n/a"`) to the FIF-paused early-exit heredoc in `fif-attention.sh`, or gate the `test_tier_distribution` contract test to tolerate `status: skipped`. Easiest fix:
  ```yaml
  # in the paused heredoc in fif-attention.sh, add:
  tier_distribution: {}
  ```

---

### F6 (ANT-F6)
- **Severity**: MINOR
- **File**: `scripts/vault-gc.sh`, line ~48
- **Finding**: The `timestamp:` value is not quoted: `timestamp: $(date -u ...)`. All other wrappers quote it: `timestamp: "$(date ...)"`. While YAML technically allows bare timestamps, the `yaml_parseable` contract test might interpret unquoted ISO-8601 as a date object vs. string. This inconsistency could cause subtle differences in downstream parsing.
- **Why**: Inconsistency with the 7 other wrappers and potential YAML type coercion.
- **Fix**: Quote the timestamp: `timestamp: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"`

---

### F7 (ANT-F7)
- **Severity**: MINOR
- **File**: All 8 wrapper scripts, `LOG_FILE="${STAGING_PATH:-.}/..."`
- **Finding**: The `${STAGING_PATH:-.}` fallback to `.` means if `STAGING_PATH` is unset (e.g., manual testing outside the contract runner), the artifact is written to the current working directory. This is a reasonable default for debugging but could leave stale artifacts in unexpected places.
- **Why**: Low risk — the contract runner always sets `STAGING_PATH`. But manual invocations could litter artifacts.
- **Fix**: Acceptable as-is for a personal project. For robustness, could add `mkdir -p "$(dirname "$LOG_FILE")"` before tee, though the staging dir should already exist.

---

### F8 (ANT-F8)
- **Severity**: MINOR
- **File**: `scripts/overnight-research.sh`, lines ~39–42
- **Finding**: The `grep -qi` change for case-insensitive matching and the added `not a scheduled day` pattern is a good orthogonal fix. However, the pattern `not a.*night` was presumably matching "not a research night" — with case-insensitive matching, this still works. The new `not a scheduled day` pattern is additive and correct. One edge case: if the upstream script ever emits a line containing "skipping" in an unrelated context (e.g., "skipping duplicate feed"), the no-op flag would be incorrectly set to true.
- **Why**: The `skipping` pattern is very broad.
- **Fix**: Consider tightening to `skipping.*research\|skipping overnight` if the upstream script's format is known. Low priority.

---

### F9 (ANT-F9)
- **Severity**: MINOR
- **File**: `contracts/vault-health.yaml`, lines ~24–33
- **Finding**: The contract checks for `substring: "Vault Check Summary"` and `substring: "RESULT:"`. These rely on the exact output format of `vault-check.sh`, which is a legacy script not in this diff. If that script changes its output format, these tests break silently (well, they fail, which is actually the *correct* behavior — it detects the regression). This is fine.
- **Why**: N/A — this is actually a strength. Noting for completeness.
- **Fix**: None needed.

---

### F10 (ANT-F10)
- **Severity**: STRENGTH
- **File**: All 8 contracts, `test_service_line` additions
- **Finding**: Adding `content_contains: "service: <name>"` to every contract is an excellent regression guard against the stale-artifact bug. If a wrapper's tee fails or `STAGING_PATH` is wrong, the artifact file won't contain the expected `service:` line with the right name. This directly addresses the root cause (Apr 2-5 stubs wouldn't contain these lines).
- **Why**: This is the core value of the fix — the contracts now validate *freshness* by checking for content that only a live run produces.
- **Fix**: None — well-designed.

---

### F11 (ANT-F11)
- **Severity**: STRENGTH
- **File**: `scripts/fif-capture.sh`, lines ~57–85
- **Finding**: The `{ cat <<YAML ...; if ...; fi; } | tee "$LOG_FILE"` refactoring correctly solves the problem of needing a single tee for both the heredoc and the conditional errors section. The previous code had `cat <<YAML` followed by a separate `if/echo/grep` block — piping only the heredoc through tee would have lost the errors. The brace-group approach is the right solution.
- **Why**: Shows careful handling of the special case.
- **Fix**: None.

---

### F12 (ANT-F12)
- **Severity**: STRENGTH
- **File**: Entire diff, pattern consistency
- **Finding**: The diff faithfully propagates the scout-remediation pattern (TV2-043) to all 8 remaining wrappers. Variable naming (`LOG_FILE`), fallback syntax (`${STAGING_PATH:-.}`), comment style, and tee placement are consistent across all files.
- **Why**: Maintainability — a future reader can understand any wrapper by reading any other.
- **Fix**: None.

---

## Summary (Opus)

| Severity | Count |
|---|---|
| CRITICAL | 0 (F1 downgraded — correct today, fragile) |
| SIGNIFICANT | 4 (F1, F2, F4, F5) |
| MINOR | 4 (F3, F6, F7, F8) |
| STRENGTH | 3 (F10, F11, F12) |

**F5 is the most actionable finding**: fif-attention's contract will fail when FIF is paused because the early-exit heredoc lacks `tier_distribution:`. The rest are hardening/consistency items. The overall pattern propagation is faithful and well-executed.

---

## Codex (CDX)

### Tool Execution

Codex attempted to run the project's type checker and test suite but both failed for environmental reasons (not code issues):
- `mypy`: `No module named mypy` — not installed in the project's `.venv`
- `pytest`: `FileNotFoundError: No usable temporary directory found` — Codex sandbox `/tmp` visibility limitation

Codex then verified test-type support statically by reading `src/tess/contract.py` (schema) and `src/tess/runner.py` (runtime dispatch), confirming all test types used in the diff (`content_not_contains`, `content_contains`, `line_count_range`, `yaml_parseable`, `file_exists`) are implemented. It also ran `rg -n 'service:' ...` across all new contracts + wrappers to cross-check that service-line substrings match what each wrapper emits.

### Findings

**Tooling pre-checks**
- `pytest` could not run in this environment: `FileNotFoundError: No usable temporary directory found ... ['/tmp', ...]`.
- Type checker could not run: `.venv/bin/python: No module named mypy`.
- Still verified test-type support statically in code (`src/tess/contract.py`, `src/tess/runner.py`).

**Bash wrappers (.sh)**

- [CDX-F1]
- [Severity]: SIGNIFICANT
- [File]: `scripts/run-vault-check.sh` (diff lines 459-463)
- [Finding]: `bash ... | tee "$LOG_FILE" || true` masks *both* vault-check warnings (intended) and `tee` write failures (unintended).
- [Why]: If `$STAGING_PATH` is unwritable, `tee` fails but wrapper still exits 0. With persistent staging dirs, an old `vault-check-output.txt` can remain and still satisfy `file_exists`/content checks, reintroducing stale-artifact risk for this one contract.
- [Fix]: Preserve "ignore vault-check nonzero" without ignoring `tee` failure. Example pattern:
  - `tmp_rc=0; bash ... 2>&1 | tee "$LOG_FILE" || tmp_rc=$?`
  - then explicitly treat `tee` failure as fatal (or preflight `: > "$LOG_FILE"` and fail if not writable), while still returning 0 only for vault-check warning semantics.

- [CDX-F2]
- [Severity]: STRENGTH
- [File]: `scripts/connections-brainstorm.sh`, `scripts/daily-attention.sh`, `scripts/fif-attention.sh`, `scripts/fif-capture.sh`, `scripts/fif-feedback-health.sh`, `scripts/overnight-research.sh`, `scripts/vault-gc.sh`
- [Finding]: Propagation is faithful to the scout remediation pattern: each wrapper now writes named artifacts via `tee "$LOG_FILE"` with `${STAGING_PATH:-.}` fallback.
- [Why]: This directly addresses the original stale-artifact failure mode (stdout-only output not updating per-service artifact files).
- [Fix]: No change needed.

- [CDX-F3]
- [Severity]: STRENGTH
- [File]: `scripts/fif-capture.sh`
- [Finding]: The brace-group piping is correctly structured so both the main YAML block and optional `errors:` section go through a single `tee`.
- [Why]: Prevents split-write behavior and keeps artifact + stdout capture consistent.
- [Fix]: No change needed.

**YAML contracts (.yaml)**

- [CDX-F4]
- [Severity]: STRENGTH
- [File]: All 8 contracts in the diff
- [Finding]: New `content_contains` / `content_not_contains` checks are internally consistent with wrapper output strings, including exact unquoted service lines (e.g., `service: fif-feedback`, `service: vault-gc`).
- [Why]: Improves regression detection for wrong/missing artifact content and aligns with the stated "named artifact freshness" design.
- [Fix]: No change needed.

- [CDX-F5]
- [Severity]: STRENGTH
- [File]: `src/tess/contract.py` (37-40), `src/tess/runner.py` (333-400, 521-566, 571-580)
- [Finding]: All newly used test types (`content_not_contains`, `content_contains`, `line_count_range`, `yaml_parseable`, `file_exists`) are supported by schema and runtime dispatch.
- [Why]: Confirms the contract changes are executable by the current runner, not just syntactically valid YAML.
- [Fix]: No change needed.

### Summary (Codex)

CRITICAL 0 | SIGNIFICANT 1 | MINOR 0 | STRENGTH 4

---

## Raw responses

- Opus JSON: `Projects/tess-v2/reviews/raw/2026-04-15-code-review-manual-anthropic.json`
- Codex final message: `Projects/tess-v2/reviews/raw/2026-04-15-code-review-manual-codex.txt`
- Codex JSONL transcript: `Projects/tess-v2/reviews/raw/2026-04-15-code-review-manual-codex.jsonl`
