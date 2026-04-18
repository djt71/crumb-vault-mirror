---
type: review
review_type: code
review_mode: diff
scope: milestone
project: tess-v2
domain: software
language: python
framework: pytest
diff_stats:
  files_changed: 12
  insertions: 1341
  deletions: 58
skill_origin: code-review
created: 2026-04-18
updated: 2026-04-18
reviewers:
  - anthropic/claude-opus-4-6
  - codex/gpt-5.3-codex
config_snapshot:
  curl_timeout: 120
  codex_timeout: 600
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "3 /Users/tess/ paths in scripts/scout-feedback-poller-wrapper.sh (incidental shell script in diff range, not TV2-057b/c scope)"
reviewer_meta:
  anthropic:
    http_status: 200
    latency_ms: 108949
    attempts: 1
    token_usage:
      input_tokens: 25553
      output_tokens: 4564
    raw_json: Projects/tess-v2/reviews/raw/2026-04-18-code-review-milestone-tv2-057bc-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 85124
    tools_run:
      - "exploratory rg/find/ls (24 commands)"
      - "no pytest run — Codex did not reach the actual repo at /Users/tess/crumb-apps/tess-v2 (its shell tools landed in /Users/tess/crumb-vault); review grounded in inlined diff only"
    token_usage:
      input_tokens: 493152
      output_tokens: 4755
    jsonl_log: Projects/tess-v2/reviews/raw/2026-04-18-code-review-milestone-tv2-057bc-codex.jsonl
    raw_text: Projects/tess-v2/reviews/raw/2026-04-18-code-review-milestone-tv2-057bc-codex.txt
tags:
  - review
  - code-review
---

# Code Review — TV2-057b + TV2-057c Foundation Work

**Scope:** Milestone review covering the combined TV2-057b (Class A / Class C state-machine split + canonical_outputs schema field) and TV2-057c (write-lock acquisition wired into `_cmd_run` for Class A contracts) foundation work.

**Diff:** 12 files changed, +1341 / −58. Primary surfaces: `src/tess/contract.py`, `src/tess/classifier.py`, `src/tess/cli.py`, `src/tess/lock_deny.py`, `tests/test_contract.py`, `tests/test_classifier.py`, `tests/test_cli.py`, `tests/test_lock_deny.py`, `contracts/daily-attention.yaml` (schema bump), plus an incidental `scripts/scout-feedback-poller-wrapper.sh` (IDQ-004 backfill, out of scope but flagged where issues surfaced).

**Reviewer dispatch note:** Codex's shell-tool execution did not honor the `-C /Users/tess/crumb-apps/tess-v2` cd root — its tools landed in the vault working directory instead. As a result, Codex could not run `pytest` or a type checker against the actual code. Its findings are grounded only in the inlined diff text. File path prefixes Codex cites (`/Users/tess/crumb-vault/src/tess/...`) should be read as `src/tess/...` relative to the tess-v2 repo. This is a tooling-glue issue with the dispatch, not a Codex limitation; investigate before next code-review run.

---

## Reviewer 1 — Claude Opus 4.6 (anthropic)

**17 findings: 0 CRITICAL · 6 SIGNIFICANT · 5 MINOR · 6 STRENGTH** (Opus's own tally said 4 STRENGTH; F8 includes a STRENGTH-adjacent compatibility-confirmed finding.)

### F1 — SIGNIFICANT (originally CRITICAL but downgraded by Opus's own analysis)
- **File:** `src/tess/classifier.py`, lines 55–63
- **Finding:** Classifier docstring says `canonical_outputs` is empty → Class C, but the validator rejects `canonical_outputs: []` at load time. The runtime logic is correct (absent field → falsy → falls to allowlist → returns Class C if listed), but the coupling between validator-rejects-empty and classifier-treats-empty-as-Class-C is implicit. A maintainer reading classifier.py alone will be confused.
- **Why:** Implicit cross-module invariant. Logic is correct but fragile to programmatic Contract construction.
- **Fix:** Add comment in `is_side_effect_contract`: `# Note: empty list canonical_outputs=[] is rejected at load time; at runtime, an empty list here means the field was absent from YAML (default factory).`

### F2 — SIGNIFICANT
- **File:** `src/tess/contract.py`, lines 120–131 (`CanonicalOutput.resolve`)
- **Finding:** `.replace()` chain is vulnerable to double substitution if a resolved value contains another placeholder pattern. Not exploitable with current ISO date/week/timestamp values (they never contain `{` or `}`), but latent fragility if a new placeholder is added whose value could contain braces.
- **Fix:** Add comment `# Safe because ISO date/week/timestamp values never contain '{' or '}'`. Or use a single-pass `re.sub` with callback for robustness.

### F3 — SIGNIFICANT
- **File:** `src/tess/contract.py`, lines 120–131
- **Finding:** **Path traversal gap between load-time validation and resolve-time output.** Validator (lines 438–444) checks `..` and absolute paths in the *template*, but `resolve()` substitutes placeholders with arbitrary formatted values and never re-validates the result. With current placeholders the resolved path is safe, but a future placeholder producing `..` or `/` characters would bypass the vault-escape check.
- **Why:** Defense-in-depth — security boundary should hold at runtime, not just load time.
- **Fix:** Add post-resolution assertion in `resolve()`:
  ```python
  assert not resolved.startswith("/"), "resolved path must be vault-relative"
  assert ".." not in resolved.split("/"), "resolved path must not traverse"
  ```
  Or validate in `cli.py` before passing resolved paths to `acquire_locks`.

### F4 — SIGNIFICANT
- **File:** `src/tess/cli.py`, lines 689–741
- **Finding:** `lock_table` initialized to `None`; `finally` checks `if lock_table is not None`. But if `WriteLockTable()` constructor succeeds and `acquire_locks()` raises (rather than returning `acquired=False`), execution jumps to `finally` with `lock_table` set but no locks actually held. `release_locks` then attempts to release locks that were never acquired. Safe only if `release_locks` is a no-op for non-held locks — not verifiable from this diff.
- **Why:** Could mask the original exception or corrupt other contracts' lock state.
- **Fix:** Track acquisition success explicitly:
  ```python
  locks_acquired = False
  ...
  if lock_result.acquired:
      locks_acquired = True
      reset_lock_deny_count(contract.service)
  ...
  finally:
      if lock_table is not None and locks_acquired:
          try:
              lock_table.release_locks(contract.contract_id)
  ```

### F5 — SIGNIFICANT
- **File:** `src/tess/lock_deny.py`, lines 85–90
- **Finding:** `_read_counter` silently returns `{}` on JSON corruption with no warning. If a service had 4 consecutive denials (one away from Z4 threshold) and the counter file gets corrupted, the next deny resets to 1 and the Z4 alert fires 4 cadences late. Operator has no way to know self-heal happened.
- **Fix:**
  ```python
  except (json.JSONDecodeError, OSError) as e:
      print(f"WARNING: lock-denies.json corrupt, resetting counters: {e}", file=sys.stderr)
      return {}
  ```

### F6 — SIGNIFICANT
- **File:** `src/tess/lock_deny.py`, lines 65–76
- **Finding:** `_atomic_write_json` window: between `os.fdopen(fd, "w")` close and `os.replace(...)`, a SIGKILL or power loss leaves the temp file orphaned. The except block unlinks tmp on Python exceptions but not on hard-kill. Test `test_lock_deny.py` line 134 only checks no-stale-tmp after success, not after crash mid-write.
- **Fix:** Acceptable for personal-project scale. If desired, add cleanup of stale `.tmp` files older than N minutes in `_read_counter`.

### F7 — SIGNIFICANT
- **File:** `tests/test_cli.py`, lines 601–652 (`TestConcurrentContention`)
- **Finding:** Test patches `tess.cli.datetime` (replacing the entire module reference). `mock_dt.now(timezone.utc)` returns `mock_dt.now.return_value` regardless of the `timezone.utc` argument — works by accident of import style. If `cli.py` is ever refactored to call `datetime.datetime.now(...)` instead of `datetime.now(...)`, the mock breaks silently (no test failure, but the time is no longer pinned).
- **Fix:** Use `freezegun`, explicitly patch `tess.cli.datetime.now` as a method, or refactor to inject a clock function. At minimum add a comment explaining the mock strategy.

### F8 — MINOR (compatibility check, confirms expected behavior)
- **File:** `src/tess/contract.py`, lines 95–97
- **Finding:** `SUPPORTED_MINOR` bumped 1 → 2. Version check accepts `(major=1, minor<=2)`, so contracts with `schema_version: "1.0.0"` and `"1.1.0"` still pass. Confirmed by mixed test fixtures using `"1.0.0"` and `"1.2.0"`. Backward compatibility preserved.
- **Fix:** None needed.

### F9 — MINOR
- **File:** `scripts/tv2_057a_backfill.py`, lines 30–33
- **Finding:** Comment "corrected 2026-04-17 from original 18:00Z unit-error" is jargon. Future readers won't know whether the "unit-error" was hours/minutes confusion, timezone offset, or something else.
- **Fix:** Clarify: `corrected to 23:00Z — original 18:00Z was based on incorrect UTC offset for the Phase 5 gate`.

### F10 — MINOR
- **File:** `src/tess/lock_deny.py`, lines 91–93
- **Finding:** `_read_counter` accepts `int | float` and coerces via `int(v)`. A stored `3.7` silently truncates to `3`. Counters should always be ints; accepting floats silently could mask a writer bug.
- **Fix:** Restrict to `isinstance(v, int)` and drop floats, or warn on float values.

### F11 — MINOR
- **File:** `tests/test_lock_deny.py`, lines 139–151
- **Finding:** `test_known_acceptable_race_undercount_documented` only asserts `CONSECUTIVE_DENY_THRESHOLD >= 1` — tautological. Sets a precedent of tests passing without testing anything.
- **Fix:** Rename with a `test_doc_*` prefix to signal non-functional, or move documentation to `DESIGN.md` and remove the test.

### F12 — MINOR
- **File:** `tests/test_contract.py`, lines 543–547
- **Finding:** `import os` and `_ = os` (linter suppression) are unnecessary dead code in `test_daily_attention_contract_loads`.
- **Fix:** Remove both lines.

### F13 — MINOR
- **File:** `scripts/scout-feedback-poller-wrapper.sh`, lines 30–32
- **Finding:** Script `source`s the credential file directly (`set -a; source "$CRED_FILE"; set +a`). If the file ever contains backticks, `$(...)`, or non-assignment lines, those execute as bash. Comment says "simple key=value format" but no enforcement.
- **Fix:** Use `while IFS='=' read -r key val; do export "$key=$val"; done < "$CRED_FILE"` or pre-validate with `grep -E '^[A-Z_]+=.*$'`.

### F14 — STRENGTH
- **File:** `src/tess/cli.py`, lines 698–741
- **Finding:** try/finally pattern for lock release is well-structured. Every terminal path (STAGED, COMPLETED, ESCALATED, DEAD_LETTER, exceptions) goes through `finally`. `_record_to_history` is inside `try`, so locks release even if it raises. `EXIT_LOCK_DENIED` returns before the try block, correctly skipping release on failed acquisition.

### F15 — STRENGTH
- **File:** `src/tess/contract.py`, lines 390–469
- **Finding:** `canonical_outputs` validation is thorough and defense-in-depth: bare filename check, vault-relative check, `..` traversal check, unknown placeholder check, duplicate detection (staging_name + destination), unknown nested key rejection, explicit `[]` rejection with clear remediation message.

### F16 — STRENGTH
- **File:** `tests/test_contract.py`, `tests/test_classifier.py`, `tests/test_cli.py`
- **Finding:** Test coverage is comprehensive. Classifier tests cover the three-way logic (canonical_outputs present → Class A; absent + allowlist → Class C; absent + unknown → Class A default). Contract tests cover all validation error paths. CLI tests cover lock-acquire, lock-release on every terminal state including exceptions, lock-denied exit code, no-history-row on deny, counter increment/reset, and release-failure logging. `test_explicit_now_not_datetime_now` is a clever anti-regression test.

### F17 — STRENGTH
- **File:** `src/tess/lock_deny.py` (overall design)
- **Finding:** `state_dir` parameter injection throughout the module makes it fully testable without monkeypatching `Path.home()`. `_default_state_dir()` is only called as a default argument, allowing tests to pass `tmp_path` directly. Clean DI pattern.

**Opus summary:** CRITICAL: 0 | SIGNIFICANT: 6 | MINOR: 5 | STRENGTH: 4 (Opus's count; this note shows 4 STRENGTH explicitly — F14, F15, F16, F17). Most actionable: F4 (track `locks_acquired` explicitly), F3 (post-resolution path validation), F5 (warn on counter self-heal).

---

## Reviewer 2 — Codex (gpt-5.3-codex, CLI)

**9 findings: 0 CRITICAL · 4 SIGNIFICANT · 3 MINOR · 2 STRENGTH**

### Tool Execution
Codex ran 24 exploratory shell commands (rg, find, ls) trying to locate the project source tree. Its working directory was `/Users/tess/crumb-vault` (the dispatching shell's cwd) rather than `/Users/tess/crumb-apps/tess-v2` (the `-C` flag target). It never found `pyproject.toml`, `pytest.ini`, or the `src/tess/` tree, and explicitly noted: *"I could not run `pytest` or a type checker in this workspace because the Python project files are not present here. Review below is grounded in the diff text only."* No tests or type-checker output was collected. **Action item for next dispatch:** investigate why `codex -C <path> exec` doesn't propagate cwd to the shell-tool subprocesses; consider wrapping the dispatch in `subprocess.run(cwd=REPO_PATH, ...)` so Codex's exploratory tools land in the right place.

### CDX-F1 — SIGNIFICANT
- **File:** `src/tess/cli.py` (hunk `@@ -679,38 +689,86 @@`, lines ~706–731)
- **Finding:** Lock acquisition and `reset_lock_deny_count(contract.service)` happen *before* the `try/finally`. If `reset_lock_deny_count` raises (disk full, permission), acquired locks are never released → zombie locks → repeated lock-denied on future runs.
- **Fix:** Move `try/finally` to start immediately after successful `acquire_locks`, or track `locks_acquired=True` and ensure release in `finally` regardless of later failures.
- **Convergence with Opus F4:** Same lock-leak window from a different angle. Opus focused on `acquire_locks` raising; Codex focused on `reset_lock_deny_count` raising. Both fix proposals (track `locks_acquired` explicitly) are consistent.

### CDX-F2 — SIGNIFICANT
- **File:** `src/tess/cli.py` (~716–724) and `src/tess/lock_deny.py` (write paths)
- **Finding:** On lock denial, `record_lock_deny(...)` is unguarded. If counter/marker write fails, `_cmd_run` throws instead of returning exit 75 — violates intended R2 "quiet retry" semantics for contention.
- **Fix:** Wrap `record_lock_deny` in `try/except`, continue returning `EXIT_LOCK_DENIED`, log counter-write failure to stderr.
- **Note:** This is the question raised explicitly in review prompt §5 — Codex answered "no, it doesn't propagate correctly."

### CDX-F3 — SIGNIFICANT
- **File:** `src/tess/contract.py` (~`SUPPORTED_MINOR = 2`, `AUTHORED_FIELDS`, `_validate_raw` block at hunk `@@ -337,20 +390,97 @@`)
- **Finding:** `canonical_outputs` is accepted without gating on `schema_version >= 1.2.0`. Tests use `schema_version: "1.0.0"` *with* `canonical_outputs` — weakens versioned-schema guarantees and rollback clarity (new field accepted in old schema versions).
- **Fix:** If `canonical_outputs` is present, require minor >= 2; or document/rename policy as "forward-compatible additive fields allowed on 1.0/1.1."
- **Divergence from Opus F8:** Opus said backward-compat is preserved (older contracts still load). Codex flags the *opposite* concern: newer fields accepted on older `schema_version` declarations. Both observations are correct; the policy question (strict version gating vs. additive-forward-compat) is a design call.

### CDX-F4 — SIGNIFICANT
- **File:** `scripts/scout-feedback-poller-wrapper.sh` (lines 30–34)
- **Finding:** Credentials file is `source`d directly. Any non-assignment content executes as shell.
- **Fix:** Parse strict `KEY=VALUE` lines instead of `source`, or pre-validate with strict regex and reject unsafe lines.
- **Convergence with Opus F13:** Identical finding, identical fix. Both reviewers caught this in the out-of-scope shell script.

### CDX-F5 — MINOR
- **File:** `src/tess/lock_deny.py` (lines 82–90)
- **Finding:** Corrupt `lock-denies.json` silently self-heals to `{}` — masks near-threshold contention, delays Z4 signaling without operator visibility.
- **Fix:** Emit warning to stderr when parse/read fails before resetting in-memory state.
- **Convergence with Opus F5:** Same finding; Opus rated SIGNIFICANT, Codex rated MINOR. Recommend treating as SIGNIFICANT (matches Opus framing).

### CDX-F6 — MINOR
- **File:** `src/tess/lock_deny.py` (lines 91–93)
- **Finding:** `_read_counter` coerces `float` (and `bool`, since `bool` is `int`) via `int(v)`. Silent truncation/coercion can hide malformed data.
- **Fix:** Accept only `int`, optionally warn/drop non-int values.
- **Convergence with Opus F10:** Identical finding. Codex adds the bool-is-int wrinkle, which Opus didn't mention — `True` would be silently coerced to `1`, `False` to `0`. Worth noting.

### CDX-F7 — MINOR
- **File:** `tests/test_lock_deny.py` (lines 139–151)
- **Finding:** "Known acceptable race" test is effectively a no-op sentinel.
- **Fix:** Keep as docs-only but rename clearly (e.g., `test_doc_*`) or add a real concurrency test with deterministic hooks.
- **Convergence with Opus F11:** Identical finding, identical fix proposal.

### CDX-F8 — STRENGTH
- **File:** `src/tess/contract.py` (`CanonicalOutput.resolve` hunk) and `src/tess/cli.py` (lock acquire hunk)
- **Finding:** Explicit `now` injection into `resolve(now)` and pinned `now` at lock acquisition is architecturally sound; ISO week formatting (`YYYY-Www` via `isocalendar`) is correct.
- **Why:** Avoids midnight drift between placeholder resolutions; keeps lock target deterministic.

### CDX-F9 — STRENGTH
- **File:** `src/tess/lock_deny.py` (lines 62–76)
- **Finding:** Atomic write uses temp file + `os.replace`, so readers see old-or-new, not partial JSON. Correct durability pattern for this scale.

**Codex closing note:** "No additional correctness issues found in `.replace()` placeholder matching itself; with fixed tokens (`{date}`, `{week}`, `{timestamp}`), partial-match risk is low."

**Codex summary:** SIGNIFICANT 4 | MINOR 3 | STRENGTH 2 | CRITICAL 0.

---

## Cross-Reviewer Convergence

**Both reviewers agreed on:**
- **Lock-leak window** (Opus F4 / CDX-F1) — different trigger points, same root cause; fix is to track `locks_acquired` explicitly.
- **Credential file `source`** (Opus F13 / CDX-F4) — same fix.
- **Corrupt counter silent self-heal** (Opus F5 / CDX-F5) — Codex MINOR, Opus SIGNIFICANT; recommend SIGNIFICANT.
- **`int(v)` coercion in `_read_counter`** (Opus F10 / CDX-F6) — Codex adds the `bool` edge case.
- **No-op sentinel test** (Opus F11 / CDX-F7) — same fix proposal.
- **Atomic-write pattern is correct** (Opus implicit / CDX-F9 STRENGTH).
- **Explicit `now` injection is the right design** (Opus F16 / CDX-F8 STRENGTH).

**Unique to Opus:**
- F2 (`.replace()` chain double-substitution latent fragility)
- F3 (path-traversal gap between load-time and resolve-time validation) — most security-relevant unique finding
- F7 (datetime mock works by import-style accident, brittle to refactor)
- F12 (dead `import os` in test)
- F14, F15, F17 (additional STRENGTH callouts)

**Unique to Codex:**
- CDX-F2 (unguarded `record_lock_deny` violates R2 quiet-retry semantics) — answers a specific prompt question Opus didn't address as crisply
- CDX-F3 (schema_version gating policy on new field — flips Opus's "backward-compat preserved" framing to ask the dual question about forward compat)

**Verdict:** No CRITICAL findings. Several SIGNIFICANT items worth addressing before this lands long-term, especially F3/F4 (Opus) and CDX-F1/F2/F3. The work is well-structured overall — both reviewers explicitly called out the architecture (state_dir DI, explicit-now injection, comprehensive test coverage, defense-in-depth validation).

---

## Cluster Analysis (Step 7b)

**Cluster detected: `_cmd_run` lock-lifecycle error handling.**

Three SIGNIFICANT findings (F4, CDX-F1, CDX-F2) all share the same file (`src/tess/cli.py`), same issue type (error handling), and the same root cause: **operations between `WriteLockTable()` construction and the `try/finally` boundary are not protected against exceptions, creating lock-leak windows and R2-semantics violations**.

- F4: `acquire_locks()` raises → `finally` attempts to release non-held locks
- CDX-F1: `reset_lock_deny_count()` raises after successful acquire → lock leaked
- CDX-F2: `record_lock_deny()` raises on deny path → `_cmd_run` throws instead of returning 75

Single systemic action (A-S1) resolves all three. Individual findings preserved below for traceability.

No other 3+-finding clusters. Counter self-heal and int-coercion form a 2-finding pattern ("silent corruption recovery without operator visibility") but below the 3-finding threshold — handled as individual items.

---

## Action Items (Step 7)

### Must-fix

#### A-S1 — SYSTEMIC. Restructure `_cmd_run` lock-lifecycle error handling
Consolidates F4 + CDX-F1 + CDX-F2.

**File:** `src/tess/cli.py` `_cmd_run` (lines 689–741)

**Changes:**
1. Add `locks_acquired: bool = False` before the lock block.
2. Set `locks_acquired = True` immediately after `lock_result.acquired` check returns True.
3. Wrap `record_lock_deny()` (deny path) in a narrow `try/except` — log counter-write failure to stderr, still return `EXIT_LOCK_DENIED`.
4. Wrap `reset_lock_deny_count()` (success path) in a narrow `try/except` — log counter-file write failure, but DO NOT abort (locks are acquired, Ralph loop should proceed).
5. In the outer `finally`, gate release on `lock_table is not None and locks_acquired` (not just the `is not None` check).

#### A1 — Path-traversal gap between load-time and resolve-time validation (F3)

**File:** `src/tess/contract.py` `CanonicalOutput.resolve()` (lines 120–131)

Add post-resolution assertion:
```python
assert not resolved.startswith("/"), "resolved path must be vault-relative"
assert ".." not in resolved.split("/"), "resolved path must not traverse"
```

Defense-in-depth. No live exploit with current `{date}/{week}/{timestamp}` placeholders (ISO values never produce `..` or `/`), but closes the boundary at runtime so future placeholder additions can't bypass the load-time check.

#### A2 — Emit warning on JSON-corruption self-heal (F5 + CDX-F5)

**File:** `src/tess/lock_deny.py` `_read_counter` (lines 82–90)

Replace silent `return {}` with:
```python
except (json.JSONDecodeError, OSError) as e:
    print(f"WARNING: lock-denies.json unreadable, resetting counters: {e}", file=sys.stderr)
    return {}
```

**Severity resolution:** Opus rated SIGNIFICANT, Codex rated MINOR. Adopting SIGNIFICANT — the near-threshold case (4 denies → corruption → reset → 5th deny as "1") hides Z4 signal for 4 additional cadences. Operator visibility is worth the cost of a stderr line.

### Should-fix

#### A3 — Classifier invariant comment (F1)
**File:** `src/tess/classifier.py` `is_side_effect_contract` (lines 55–63)
Add: `# At runtime canonical_outputs=[] means the field was absent from YAML (validator rejects literal []).`

#### A4 — Schema-version-gating policy decision (CDX-F3)
**File:** `src/tess/contract.py` (`_validate_raw` + `SUPPORTED_MINOR`)
**Operator judgment required.** Opus F8 and CDX-F3 are both correct — the code accepts `canonical_outputs` on `schema_version: "1.0.0"`. Two policies available:
- **Additive-forward-compat** (current behavior): new optional fields may appear on any 1.x version. Document explicitly.
- **Strict minor-version gating**: require `schema_version >= 1.2.0` when `canonical_outputs` is present. Churns any 1.0.0 contract adopting the field.
- **Recommendation:** additive-forward-compat matches the de-facto behavior and avoids contract-file churn; document in `contract-schema.md` and add a comment in `contract.py`.

#### A5 — `.replace()` chain safety comment (F2)
**File:** `src/tess/contract.py:120-131`
Add: `# Safe because ISO date/week/timestamp values never contain '{' or '}' — new placeholders must maintain this property.`

#### A6 — Datetime mock brittleness (F7)
**File:** `tests/test_cli.py:~640` (`test_second_contract_denied_on_same_path`)
Add comment explaining the `patch("tess.cli.datetime")` strategy, or refactor to `patch("tess.cli.datetime.now", side_effect=...)`. Not urgent — test works as-is — but flagged for 057d session where the test surface expands.

#### A7 — Type-narrow `_read_counter` values (F10 + CDX-F6)
**File:** `src/tess/lock_deny.py:91-93`
Change `isinstance(v, (int, float))` → `isinstance(v, int) and not isinstance(v, bool)`. Codex's bool-is-int catch is worth including (True→1, False→0 would silently corrupt counters).

### Defer

- **A8** — Rename or remove no-op sentinel test `test_known_acceptable_race_undercount_documented` (F11 + CDX-F7). Move to module docstring as pure documentation; trivial cleanup.
- **A9** — Remove dead `import os` in `tests/test_contract.py:543-547` (F12). Trivial.
- **A10** — Clarify `scripts/tv2_057a_backfill.py:30-33` "unit-error" comment (F9). Post-facto; backfill already executed.

### Considered and Declined

- **F6 (atomic-write crash-mid-write)** — Constraint: personal-project scale. Reviewer explicitly acknowledged "Acceptable for personal-project scale." No action. If desired later, add stale-tmp cleanup in `_read_counter`.

### Out-of-Scope (tracked separately)

- **A12** — Harden `scripts/scout-feedback-poller-wrapper.sh` credential sourcing (F13 + CDX-F4). Replace `source "$CRED_FILE"` with `while IFS='=' read -r key val; do export "$key=$val"; done < "$CRED_FILE"` or pre-validate with regex. This is IDQ-004 chore territory, not TV2-057b/c. Log as separate item for operator to address when convenient.

---

## Contradictions

**F8 vs CDX-F3 — schema version gating policy.**

- Opus F8 (MINOR): "backward compat preserved" — old `1.0.0` contracts still load. **Correct.**
- CDX-F3 (SIGNIFICANT): "new field accepted on old schema_version" — `1.0.0` contracts with `canonical_outputs` pass validation. **Also correct.**

Both observations factual. The disagreement is whether this is a feature (additive-forward-compat, standard semver-additive-optional policy) or a bug (strict version gating expected when a new field lands). **Not resolved in the review — flagged to A4 for operator judgment.**

---

## Dispatch Tooling Issue (for next run)

Codex's shell-tool execution did not honor `-C /Users/tess/crumb-apps/tess-v2`. Its `rg`/`find`/`ls` calls landed in the dispatching shell's cwd (`/Users/tess/crumb-vault`) so Codex never reached `pyproject.toml`, `pytest.ini`, or `src/tess/`. Outcome: **no pytest run, no type-checker run, review grounded in inlined diff only.**

Convergence with Opus remained strong (5 directly matching findings) despite the tooling gap, so the review still produced useful signal. But next dispatch should investigate the fix — likely pass `cwd=repo_path` to the Codex `subprocess.run(...)` call in the dispatch agent so exploratory shell tools inherit the correct root.

Log this as a **dispatch-agent improvement** (separate from TV2 scope). Not urgent, but worth fixing before the next code-review cycle to restore Codex's tool-grounding advantage.
