---
type: review
review_type: code
review_mode: diff
review_tier: 2
scope: task
project: crumb-tess-bridge
domain: software
language: python
framework: custom stage runner / unittest
diff_stats:
  files_changed: 2
  insertions: 97
  deletions: 10
skill_origin: code-review
status: complete
created: 2026-02-24
updated: 2026-02-24
reviewers:
  - openai/gpt-5.2
  - mistral/devstral-medium-latest
  - anthropic/claude-opus-4-6
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 34211
    attempts: 1
    model_resolved: gpt-5.2-2025-12-11
    token_usage:
      input_tokens: 2522
      output_tokens: 1867
    raw_json: reviews/raw/2026-02-24-code-review-task-openai.json
  mistral:
    http_status: 200
    latency_ms: 14539
    attempts: 1
    model_resolved: devstral-medium-latest
    token_usage:
      input_tokens: 2690
      output_tokens: 1165
    raw_json: reviews/raw/2026-02-24-code-review-task-mistral.json
  anthropic:
    http_status: 200
    latency_ms: ~30000
    attempts: 1
    model_resolved: claude-opus-4-6
    token_usage:
      input_tokens: 3203
      output_tokens: 3124
    raw_json: reviews/raw/2026-02-24-code-review-task-anthropic.json
tags:
  - review
  - code-review
---

# Code Review — crumb-tess-bridge task (2026-02-24)

**Tier 2 cloud panel review** of stage runner hardening: brief builder template expansion, deliverables coercion, runner-default injection, and governance hash-only verification with authoritative stamping.

**Files reviewed:** `brief_builder.py`, `stage_runner.py` (+97/-10, 2 files)

**Note:** Anthropic reviewer dispatched separately after API key was configured. All 3 reviewers now represented.

---

## OpenAI (gpt-5.2)

**Model resolved:** `gpt-5.2-2025-12-11` | **Latency:** 34.2s | **Tokens:** 2,522 in / 1,867 out

### Findings

**OAI-F1 (SIGNIFICANT)** — `stage_runner.py` lines ~203-217
`validate_schema()` silently coerces invalid `deliverables` types (non-list) to `[]` and preserves original under `_raw_deliverables`, rather than reporting a schema violation. This weakens the "strict schema" contract and can mask real model/runner mismatches. Downstream code (or governance/policy) may assume deliverables were intentionally empty, and tests that expect a failure on invalid schema will stop catching regressions.
**Fix:** Prefer: (a) keep strict validation (append `"deliverables must be a list"`), or (b) gate coercion behind an explicit "lenient mode" flag (e.g., `validate_schema(output, coerce=False)`), defaulting to strict in production; if you keep coercion, also add a violation/warning list entry like `"deliverables coerced from <type> to []"` and ensure it is surfaced in logs/alerts.

**OAI-F2 (SIGNIFICANT)** — `stage_runner.py` lines ~445-478
Runner injects defaults with `setdefault` for required identity fields (`dispatch_id`, `stage_number`, `stage_id`, `transcript_path`, `schema_version`) but does not check for conflicts when the model provides *wrong* values. If the model outputs an incorrect `dispatch_id`/`stage_number`/`stage_id`, validation may still pass (because fields exist), and later stages might treat the output as belonging to the wrong dispatch/stage, causing cross-dispatch contamination.
**Fix:** After parsing, assert equality for runner-known fields. If key is missing, inject. If key is present and not equal to expected, raise `StageOutputError` (or overwrite and record `_field_conflicts` + alert).

**OAI-F3 (CRITICAL)** — `stage_runner.py` lines ~478-515
Governance verification is reduced to "hash-only check"; on hash match, the runner overwrites `governance_check` and does **not** validate `claude_md_loaded` at all, and effectively ignores model-provided `governance_canary`. It also copies only `project_state_read` from the model, defaulting it to `False`. A model can claim `claude_md_loaded: false` (or omit it), and the runner will still accept the output if the hash matches — potentially undermining the "must have loaded project state" requirement.
**Fix:** Decide explicitly what governance guarantees are required. If canary is required, verify both hash and canary. If tolerating canary reproduction issues, require boolean attestations (`claude_md_loaded`, `project_state_read`) to be `true` and fail otherwise, while stamping hash/canary authoritatively. Add a policy rule: fail if `project_state_read` is missing/false (if required). Add explicit logging/alerting when stamping/overriding governance fields.

**OAI-F4 (SIGNIFICANT)** — `stage_runner.py` lines ~478-515
If `governance_check` is missing or non-dict, `model_hash` becomes `""`, which triggers `verify_governance(...)` (good), but **after** that call the code continues and still stamps `governance_check` with authoritative values unless `verify_governance` raises. This assumes `verify_governance` always raises on failure.
**Fix:** Make the control flow explicit — capture the result of verification (boolean) or wrap with `try/except` and re-raise. Document that `verify_governance` must raise on any mismatch, and add a unit test ensuring it raises on missing governance fields/hash mismatch.

**OAI-F5 (MINOR)** — `brief_builder.py` lines ~373-430
The output template says `"deliverables": {}` (object) but the schema validator expects `deliverables` to be a list (and now coerces non-list to `[]`). This is internally inconsistent documentation and will encourage the model to emit the wrong type.
**Fix:** Update the template to match the expected schema type, e.g. `"deliverables": []` and show an example element shape (dict with required keys) if applicable.

**OAI-F6 (MINOR)** — `brief_builder.py` lines ~397-430
The template marks "These 8 fields are REQUIRED" but includes `deliverables` in the example and describes optional sections (`next_stage`, `escalation`, `error`) without clearly stating whether `deliverables` is required or optional and what its element schema is.
**Fix:** Align the text exactly with the JSON schema: explicitly list required vs optional fields, and specify `deliverables` type and element requirements (or remove it from template if optional).

**OAI-F7 (SIGNIFICANT)** — `stage_runner.py` lines ~203-217, ~445-478, ~478-515
Missing test coverage for the new behavior paths: (1) `deliverables` coercion storing `_raw_deliverables`, (2) default injection via `setdefault`, (3) governance "hash-only then stamp" behavior including mismatch path and non-dict governance.
**Fix:** Add unittest cases covering: `validate_schema` with `deliverables={...}`; stage output missing identity fields; stage output with conflicting identity fields; governance cases (missing, hash mismatch, `claude_md_loaded: false`, non-dict `governance_check`).

**OAI-F8 (STRENGTH)** — `stage_runner.py` lines ~445-478
Injecting deterministic runner-known fields reduces prompt brittleness and makes the pipeline more reliable for fields that the runner can authoritatively know. This matches the "runner validates JSON output" design and lowers failure rate due to model omissions. Pair with conflict detection (OAI-F2) to avoid accepting inconsistent identity fields.

**OpenAI summary:** CRITICAL: 1, SIGNIFICANT: 5, MINOR: 2, STRENGTH: 1

---

## Mistral (devstral-medium-latest)

**Latency:** 14.5s | **Tokens:** 2,690 in / 1,165 out

### Findings

**MST-F1 (SIGNIFICANT)** — `brief_builder.py`, lines 376-420
The template in `_format_output_section` hardcodes `"status": "done"` in the JSON example, but the subsequent text describes other valid statuses (`"next"`, `"blocked"`, `"failed"`). This could mislead the model into always using `"done"`.
**Fix:** Update the template to show a placeholder (e.g., `"status": "done|next|blocked|failed"`) or omit it entirely since it is context-dependent.

**MST-F2 (MINOR)** — `brief_builder.py`, line 390
The placeholder `"YOUR_SUMMARY_HERE"` is inconsistent with the project's style preference (noted in Tier 1 findings as F2).
**Fix:** Replace with a more descriptive placeholder (e.g., `"SUMMARY_OF_STAGE_OUTPUT"`).

**MST-F3 (SIGNIFICANT)** — `stage_runner.py`, lines 448-477
The governance verification logic (Step 7) overwrites `governance_check` with runner-authoritative values, but the `project_state_read` field is preserved from the model's output (line 475). This creates an inconsistency: other fields (`governance_hash`, `governance_canary`, `claude_md_loaded`) are overwritten, but `project_state_read` is not.
**Fix:** Either: (1) Overwrite `project_state_read` with `expected_governance["project_state_read"]` (if the runner knows the correct value), or (2) Document why this field is treated differently (e.g., model-specific context).

**MST-F4 (MINOR)** — `stage_runner.py`, lines 451-461
The `runner_defaults` injection (Step 4b) assumes `transcripts_path` is a `Path` object, but the code uses `str(Path(...))` to convert it. This is redundant if `transcripts_path` is already a string.
**Fix:** Use `Path(transcripts_path) / ...` directly or ensure `transcripts_path` is consistently typed.

**MST-F5 (STRENGTH)** — `stage_runner.py`, lines 464-477
The governance verification now separates hash validation (security-critical) from canary stamping (model-error-prone). This is a robust improvement over the prior Tier 1 F1 issue. Reduces false positives by tolerating model formatting errors while still detecting tampering.

**MST-F6 (MINOR)** — `stage_runner.py`, line 475
The `project_state_read` fallback defaults to `False` if missing, but the comment implies this is model-generated. This could mask errors where the model fails to set the field.
**Fix:** Log a warning if `project_state_read` is missing or explicitly require it in the schema.

**MST-F7 (SIGNIFICANT)** — `stage_runner.py`, lines 206-213
The `deliverables` coercion logic (lines 206-213) preserves the original value under `_raw_deliverables` but does not validate its structure. A malicious or malformed `_raw_deliverables` could cause issues downstream.
**Fix:** Add a schema check for `_raw_deliverables` (e.g., ensure it is a dict or list) or document that it is untrusted.

**MST-F8 (MINOR)** — `brief_builder.py`, lines 380-382
The `stage_id` and paths are constructed redundantly in both `_format_output_section` and `stage_runner.py` (lines 451-455). This violates DRY.
**Fix:** Extract path construction into a shared helper function.

**Mistral summary:** CRITICAL: 0, SIGNIFICANT: 3, MINOR: 4, STRENGTH: 1

---

## Anthropic (claude-opus-4-6)

**Latency:** ~30s | **Tokens:** 3,203 in / 3,124 out

### Findings

**ANT-F1 (SIGNIFICANT)** — `stage_runner.py:467-478`
If `expected_governance` itself is malformed (missing `governance_hash` key), a KeyError at the hash comparison would produce an opaque traceback rather than a meaningful governance error. Additionally, if `expected_governance["governance_hash"]` were somehow an empty string (config bug), the hash comparison against an empty `model_hash` would pass, skipping `verify_governance` entirely.
**Fix:** Validate `expected_governance` contains required keys at the top of Step 7. Treat empty/missing `model_hash` as automatic governance failure.

**ANT-F2 (SIGNIFICANT)** — `stage_runner.py:205-211`
`validate_schema()` now mutates its input dict in-place (replaces `deliverables`, adds `_raw_deliverables`). This is a contract violation — callers expect validation to be a pure read-only operation. Issues: (1) double-call sees coerced data, (2) mutation occurs before violation check, (3) `_raw_deliverables` could collide with future schema fields.
**Fix:** Extract coercion into a separate `normalize_output()` step called before validation, similar to how runner defaults are injected in Step 4b. Keep `validate_schema` pure.

**ANT-F3 (SIGNIFICANT)** — `stage_runner.py:467-493`
Governance canary verification is completely bypassed. The authoritative stamp means the output always contains the correct canary even if the model never read CLAUDE.md — it just needs to parrot the hash from the prompt template. This weakens governance to a single trivially-copyable factor.
**Fix:** At minimum, log when model's canary doesn't match expected. Ideally record `_canary_matched: false` in output metadata so downstream consumers know the model may not have loaded CLAUDE.md.

**ANT-F4 (MINOR)** — `stage_runner.py:487-490`
`project_state_read` is the only model-sourced governance field. If `governance_check` was missing entirely, the stamped output shows `project_state_read: false` but `claude_md_loaded: true` — contradictory.
**Fix:** If governance_check was missing/non-dict, also default `claude_md_loaded` to `false` for internal consistency.

**ANT-F5 (MINOR)** — `brief_builder.py:378-428`
Governance hash placeholder in prompt template (`FIRST_12_HEX_OF_SHA256_OF_CLAUDE_MD`) combined with hash-only verification means a model that has seen previous prompts could replay the hash without re-reading CLAUDE.md.
**Fix:** Design consideration — if governance integrity matters, don't include the expected hash pattern in the prompt.

**ANT-F6 (MINOR)** — `stage_runner.py:451-462`
`setdefault` won't correct wrong values, only missing ones. If the model outputs `"stage_number": 99`, `setdefault` preserves the incorrect value. For runner-authoritative fields, direct assignment is clearer.
**Fix:** Use direct assignment for deterministic fields; optionally log when overwriting a model-provided value that differs.

**ANT-F7 (MINOR)** — `brief_builder.py:395-425`
45-line concatenated string template with embedded JSON, f-strings, and escaped quotes is hard to maintain. A missing `\n` or misplaced quote would silently produce malformed output.
**Fix:** Consider `textwrap.dedent` with triple-quoted string.

**ANT-F8 (MINOR)** — `stage_runner.py`
Six new behavior paths need test coverage: deliverables coercion, runner defaults (missing + present), governance hash-only + canary mismatch, non-dict governance_check, `_model_governance_check` preservation.

**ANT-F9 (STYLE)** — `brief_builder.py:401`
Template says "8 fields REQUIRED" but also includes `deliverables` in the JSON example. Ambiguous whether deliverables is required or optional.

**Tier 1 validation:** All 3 Tier 1 findings confirmed. F1 (isinstance guard) verified fixed. F2 (placeholder) and F3 (missing log line) confirmed still present.

**Anthropic summary:** CRITICAL: 0, SIGNIFICANT: 3, MINOR: 5, STYLE: 1

---

## Cross-Reviewer Convergence

| Theme | OAI | MST | ANT | Convergence |
|-------|-----|-----|-----|-------------|
| Governance hash-only weakens guarantees | F3 (CRITICAL) | F3 (SIGNIFICANT) | F3 (SIGNIFICANT) | **3/3 converged** — strongest consensus finding |
| `deliverables` coercion weakens schema | F1 (SIGNIFICANT) | F7 (SIGNIFICANT) | F2 (SIGNIFICANT) | **3/3 converged** — ANT adds mutation-in-validator angle |
| `setdefault` won't correct wrong values | F2 (SIGNIFICANT) | — | F6 (MINOR) | **2/3 converged** — OAI and ANT both flag |
| `project_state_read` inconsistency | — | F3+F6 | F4 (MINOR) | **2/3 converged** — MST and ANT flag contradictory defaults |
| Missing test coverage for new paths | F7 (SIGNIFICANT) | — | F8 (MINOR) | **2/3 converged** |
| Template `deliverables: {}` vs schema `list` | F5 (MINOR) | — | F9 (STYLE) | **2/3 converged** |
| Template `status: "done"` misleading | — | F1 (SIGNIFICANT) | — | Mistral only |
| `verify_governance` must-raise assumption | F4 (SIGNIFICANT) | — | — | OpenAI only |
| `validate_schema` mutates input (contract violation) | — | — | F2 (SIGNIFICANT) | **Anthropic only** — unique architectural insight |
| Hash placeholder enables prompt replay | — | — | F5 (MINOR) | **Anthropic only** — security design concern |
| Template readability (45 lines concatenated) | — | — | F7 (MINOR) | **Anthropic only** |
| `expected_governance` KeyError if malformed | — | — | F1 (SIGNIFICANT) | **Anthropic only** — upstream input validation |
| DRY violation (path construction) | — | F8 (MINOR) | — | Mistral only |
| Runner-default injection is a strength | F8 (STRENGTH) | F5 (STRENGTH) | — | **2/3 converged** |

**Aggregate (all 3 reviewers, before dedup):** CRITICAL 1, SIGNIFICANT 11, MINOR 11, STYLE 1, STRENGTH 2

---

## Synthesis (Claude — decision authority)

### Consensus Findings

**C1 — Governance relaxation weakens guarantees (3/3)**
OAI-F3 (CRITICAL) + MST-F3 (SIGNIFICANT) + ANT-F3 (SIGNIFICANT)
All three reviewers independently flag that hash-only governance check with authoritative canary stamping weakens the verification model to a single trivially-copyable factor. ANT adds that the hash is explicitly provided in the prompt template, making it even easier to parrot without reading CLAUDE.md.
**Assessment:** Strongest consensus. This is a real design tension — the canary was unreliable in practice (off-by-one, whitespace issues), so the pragmatic fix was to verify hash only. But the reviewers are right that this reduces governance to a single factor. The mitigation is that the hash is computed from the *actual* CLAUDE.md loaded by the model, not copied from the template placeholder — the template says "FIRST_12_HEX_OF_SHA256_OF_CLAUDE_MD" which is not the real hash. ANT-F5 (replay risk) is a design consideration for a more adversarial context.

**C2 — Deliverables coercion silently swallows schema violations (3/3)**
OAI-F1 (SIGNIFICANT) + MST-F7 (SIGNIFICANT) + ANT-F2 (SIGNIFICANT)
All three flag silent coercion without logging. ANT uniquely adds that the mutation happens *inside* `validate_schema`, which is a contract violation — validation functions should be pure.
**Assessment:** Real issue. The coercion was a pragmatic live-deployment fix (Session 31, attempt 4). ANT's point about validate_schema purity is the strongest formulation — the fix should both add logging AND extract coercion into a separate normalization step.

**C3 — `setdefault` doesn't detect conflicting identity fields (2/3)**
OAI-F2 (SIGNIFICANT) + ANT-F6 (MINOR)
Both flag that `setdefault` preserves wrong model-provided values for runner-authoritative fields. ANT recommends direct assignment instead.
**Assessment:** Genuine insight. For truly deterministic fields, direct assignment with optional mismatch logging is cleaner than `setdefault`.

**C4 — `project_state_read` inconsistency (2/3)**
MST-F3+F6 + ANT-F4 (MINOR)
Both flag that `project_state_read` defaults to `false` while `claude_md_loaded` is stamped `true` — contradictory when governance_check was missing. ANT suggests deriving `claude_md_loaded` from whether the hash matched, for internal consistency.
**Assessment:** Valid. The current stamping produces contradictory governance metadata.

**C5 — Missing test coverage (2/3)**
OAI-F7 (SIGNIFICANT) + ANT-F8 (MINOR)
Both enumerate the same ~6 untested behavior paths. ANT provides specific test function names.
**Assessment:** Deferred but tracked — these are the tests to write when the next test cycle runs.

**C6 — Template `deliverables: {}` vs schema `list` (2/3)**
OAI-F5 (MINOR) + ANT-F9 (STYLE)
Both note the template shows `{}` but the schema expects a list.
**Assessment:** This is the root cause of C2's coercion path. Fix the template.

**C7 — Runner-default injection is a strength (2/3)**
OAI-F8 (STRENGTH) + MST-F5 (STRENGTH)

### Unique Findings

**ANT-F2 — `validate_schema` mutates its input (contract violation)**
The strongest unique finding. `validate_schema` is named and documented as a validator but now mutates the dict in-place. This breaks the validation contract and creates double-call hazards.
**Assessment:** Architecturally sound. The fix (extract to `normalize_output()`) is clean and aligns with the runner-defaults injection pattern already in Step 4b.

**ANT-F1 — `expected_governance` KeyError if malformed**
If upstream code passes malformed `expected_governance` (missing `governance_hash`), the code raises KeyError instead of a meaningful governance error.
**Assessment:** Valid defensive concern. Low probability (expected_governance comes from `compute_governance()` which is well-tested), but the guard is cheap.

**ANT-F5 — Hash placeholder enables prompt replay**
The template reveals the hash computation method. In a more adversarial context, a model that has seen prior prompts could replay the hash.
**Assessment:** Interesting security insight. Not actionable for current context (personal project, trusted model provider) but worth noting for the governance design doc.

**OAI-F4 — `verify_governance` must-raise assumption**
Code relies on implicit raise behavior.
**Assessment:** Valid defensive concern. `verify_governance` does raise — tested — but an explicit comment improves clarity.

**MST-F1 — Template `"status": "done"` could mislead model**
**Assessment:** Low risk. Status is semantically obvious to models.

**ANT-F7 — Template readability (45-line concatenated string)**
**Assessment:** Real maintainability concern, but a refactor task, not a bug.

### Contradictions

**Governance severity:** OAI rates CRITICAL; MST and ANT rate SIGNIFICANT. OAI evaluates the security contract holistically (governance reduced to a single copyable factor); MST/ANT focus on specific field inconsistencies. The appropriate severity depends on whether this is a security boundary (CRITICAL) or an operational heuristic (SIGNIFICANT). User decision required.

**Deliverables coercion framing:** OAI and MST frame as "silent coercion without logging." ANT frames as "mutation inside a validation function" — a deeper architectural concern. ANT's framing leads to a better fix (extract coercion) vs OAI/MST's framing (add logging). Both fixes should be applied.

### Action Items

**Must-fix:**
- **A1** (C6 + C2): Fix template `"deliverables": {}` → `"deliverables": []` in brief_builder.py. Root cause of coercion path. [OAI-F5, ANT-F9]
- **A2** (C2): Add log line when deliverables are coerced. [OAI-F1, MST-F7, ANT-F2]
- **A3** (C2 — ANT): Extract deliverables coercion out of `validate_schema()` into a `normalize_output()` step before validation. Restore validation purity. [ANT-F2]

**Should-fix:**
- **A4** (C3): Replace `setdefault` with direct assignment for runner-authoritative identity fields. Log on mismatch. `stage_runner.py:451-462`. [OAI-F2, ANT-F6]
- **A5** (C4): Fix `claude_md_loaded` stamping — derive from hash match, not from `expected_governance`, when `governance_check` was missing/non-dict. [MST-F3, ANT-F4]
- **A6** (C1): Add `_canary_matched: bool` to stamped governance output. Log canary mismatch as warning. Preserves audit signal without failing on canary reproduction issues. [OAI-F3, MST-F3, ANT-F3]

**Defer:**
- **A7** (C5): Test coverage for 6 new behavior paths. Separate test task. [OAI-F7, ANT-F8]
- **A8** (OAI-F4): Explicit comment that `verify_governance` must raise. Clarity, not a bug. [OAI-F4]
- **A9** (ANT-F1): Guard `expected_governance` for required keys. Low probability, cheap fix. [ANT-F1]
- **A10** (MST-F1): Template status placeholder. Low risk. [MST-F1]
- **A11** (ANT-F7): Template readability refactor. Maintainability, not urgency. [ANT-F7]

### Considered and Declined

- **MST-F8** (DRY — shared path helper): `incorrect` — duplication is intentional across ownership boundaries.
- **MST-F2** (placeholder naming): `out-of-scope` — style preference, already noted in Tier 1.
- **MST-F4** (`str(Path(...))` redundancy): `constraint` — defensive conversion, not redundant.
- **ANT-F5** (hash replay risk): `constraint` — not actionable in current trust context. Noted for governance design doc.
- **OAI-F6** (required vs optional field documentation): `overkill` — template is already explicit.
