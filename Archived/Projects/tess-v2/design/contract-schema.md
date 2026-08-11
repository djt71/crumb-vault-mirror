---
type: design
domain: software
status: draft
scope: general
created: 2026-04-01
updated: 2026-04-01
project: tess-v2
skill_origin: null
task: TV2-019
---

# Tess v2 — Contract Schema Design

> **Scope:** Generally applicable beyond tess-v2. The contract schema (tests/artifacts/quality_checks with blocking-vs-advisory semantics, closed schemas, V1/V2/V3 verifiability tiers) is a reusable pattern for any "LLM produces work + deterministic check gates completion" system. See `_system/docs/tess-v2-durable-patterns.md`.

Complete YAML schema for contract-based execution. Defines all fields, check type semantics, version strategy, validation tooling, and example contracts. Derived from spec §8-§9, state machine (TV2-017), escalation design (TV2-018), system prompt architecture (TV2-023), service interfaces (TV2-021a), and amendments T/U/V/W/X.

## 1. Schema Definition

### 1.1 Complete Schema (Annotated)

Every field in a valid contract is enumerated below. Per Amendment V (closed schema principle), any field not listed here is invalid and must be rejected at load time.

```yaml
# ──────────────────────────────────────────────────
# CONTRACT METADATA — identifies and versions the contract
# ──────────────────────────────────────────────────
schema_version: "1.0.0"          # Required. Semver. Validated at load time.
contract_id: "TV2-033-C1"        # Required. String. Globally unique. Format: {task-id}-C{sequence}.
task_id: "TV2-033"               # Required. String. Source task from action plan.
description: "..."               # Required. String. Human-readable, <=120 chars.
service: "vault-health"          # Required. String. Service name from service interfaces (TV2-021a).
created: "2026-04-01T08:00:00Z"  # Required. ISO 8601 UTC timestamp.

# ──────────────────────────────────────────────────
# ROUTING METADATA — consumed by Gates 1, 2, 3
# ──────────────────────────────────────────────────
action_class: "vault-write"      # Required. String. Must match a key in the routing table.
verifiability: "V1"              # Required. Enum: V1 | V2 | V3. From Amendment X.
                                 #   V1 = deterministic (mechanical verification)
                                 #   V2 = heuristic (schema + pattern checks)
                                 #   V3 = judgment (requires evaluator model)
executor_target: "tier1"         # Optional. Enum: tier1 | tier3 | claude-code.
                                 #   Default: determined by Gate 1 from action_class.
                                 #   Override: forces minimum tier (Gate 1 respects as floor).
                                 #   Tier mapping: tier1=1, tier3=3, claude-code=3
                                 #   (claude-code is a Tier 3 executor implementation,
                                 #   not a separate tier — treated as tier3 for routing).
priority: "normal"               # Optional. Enum: critical | normal | low | deferred.
                                 #   Default: "normal". See state-machine-design.md §11.
defer_until: null                # Optional. ISO 8601 timestamp or null.
                                 #   Only valid when priority == "deferred".

# ──────────────────────────────────────────────────
# GATE-CONSUMED FIELDS — read by escalation gates
# ──────────────────────────────────────────────────
requires_human_approval: false   # Optional. Boolean. Default: false.
                                 #   Set automatically by Gate 3 for destructive ops,
                                 #   external comms, system modifications, first-instance
                                 #   classes. Can also be set manually at contract creation.
                                 #   When true: ROUTING → PENDING_APPROVAL (not DISPATCHED).
side_effects:                    # Optional. List of strings. Declares irreversible operations.
  - "send_telegram"              #   Consumed by Gate 3 risk policy matching.
  - "gmail_label"                #   Empty list or omitted = no side effects declared.
confidence_threshold: "medium"   # Optional. Enum: high | medium | low. Default: "medium".
                                 #   Gate 2 escalates when executor confidence < this value.
                                 #   Only meaningful for tier1 contracts (Gate 2 fires there).

# ──────────────────────────────────────────────────
# STAGING — where executor writes artifacts
# ──────────────────────────────────────────────────
staging_path: "_staging/TV2-033-C1/"  # Required. String. Format: _staging/{contract_id}/.
                                      #   Executor writes here exclusively (AD-008).
                                      #   Path is contract-scoped — no sharing.

# ──────────────────────────────────────────────────
# VAULT CONTEXT — what the executor can read
# ──────────────────────────────────────────────────
read_paths:                      # Optional. List of strings. Vault-relative paths.
  - "Projects/tess-v2/design/specification.md"
  - "Domains/software/moc-software.md"
                                 #   Excluded paths per state-machine-design.md §12:
                                 #   _staging/*, ~/.tess/*, _system/logs/*, _openclaw/state/*
                                 #   Contracts targeting excluded paths must list them
                                 #   explicitly here (not auto-discovered).

# ──────────────────────────────────────────────────
# TERMINATION CHECKS — BLOCKING for executor termination
# ──────────────────────────────────────────────────

# Tests: deterministic, mechanically verified by runner. BLOCKING.
# PATH RULE: All `path` values in `tests` and `artifacts` are relative
# to `staging_path` by default. Vault-relative paths (for reading
# canonical files during checks) must be prefixed with `vault:`
# (e.g., `vault:_system/scripts/validate.py`).
tests:                           # Optional. List of test objects.
  - id: "test_file_exists"       #   Required per item. String. Unique within contract.
    type: "file_exists"          #   Required. Enum: file_exists | frontmatter_valid |
                                 #     command_exit_zero | file_matches_pattern |
                                 #     content_contains | content_not_contains |
                                 #     json_schema_valid | yaml_parseable | line_count_range
    path: "_staging/TV2-033-C1/vault-health-notes.md"
                                 #   Required for file-based types. Vault-relative path.
    params: {}                   #   Optional. Type-specific parameters (see §1.2).

# Artifacts: structured checks run by runner. BLOCKING.
artifacts:                       # Optional. List of artifact objects.
  - id: "artifact_section_count" #   Required per item. String. Unique within contract.
    description: "Report has >=3 sections"
                                 #   Required. String. Human-readable description.
    verification: "grep -c '^## ' vault-health-notes.md >= 3"
                                 #   Required. String. Shell command or structured check.
    executor: "runner"           #   Required. Enum: runner. All artifact checks are
                                 #   mechanical — runner executes them.

# ──────────────────────────────────────────────────
# QUALITY CHECKS — BLOCKING for promotion, ADVISORY for termination
# ──────────────────────────────────────────────────
quality_checks:                  # Optional. List of quality check objects.
  - id: "qc_completeness"       #   Required per item. String. Unique within contract.
    description: "No critical vault issues missed"
                                 #   Required. String. Evaluation criterion.
    evaluator: "tess"            #   Required. Enum: tess. Quality checks require
                                 #   judgment — evaluator-executor separation (AD-007).

# ──────────────────────────────────────────────────
# PROMOTION POLICY
# ──────────────────────────────────────────────────
partial_promotion: "hold_for_review"
                                 # Required. Enum: discard | hold_for_review | promote_passing.
                                 #   discard: staging abandoned on contract failure.
                                 #   hold_for_review: Danny reviews during dead-letter
                                 #     processing, can promote passing artifacts.
                                 #   promote_passing: artifacts that individually passed
                                 #     promote; failing artifacts stay in staging.
                                 # Promotion is ATOMIC per contract — all promotable
                                 # artifacts move together or none do.

# ──────────────────────────────────────────────────
# EXECUTION PARAMETERS
# ──────────────────────────────────────────────────
retry_budget: 3                  # Required. Integer >= 1. Max Ralph loop iterations
                                 #   before escalation. Per-contract, not per-executor.
                                 #   Escalation does NOT consume an iteration.
                                 #   Default: 3.
quality_retry_budget: 0          # Optional. Integer >= 0. Default: 0.
                                 #   Additional re-dispatch budget after QUALITY_EVAL
                                 #   failure. Only meaningful for V3 contracts.
                                 #   V1/V2: must be 0 (quality failures → partial_promotion).
                                 #   V3: default 1 (one re-attempt after quality feedback).
max_queue_age: "PT4H"            # Optional. ISO 8601 duration. Default: PT4H (4 hours).
                                 #   Max time in QUEUED before → DEAD_LETTER.
timeout: "PT5M"                  # Optional. ISO 8601 duration. Default: PT5M (5 minutes).
                                 #   Heartbeat timeout within EXECUTING. If no progress
                                 #   signal within this window → ESCALATED.
escalation: "tess"               # Optional. String. Default: "tess".
                                 #   Who receives escalation notifications.
                                 #   "tess" = orchestrator handles. "danny" = human alert.
convergence_mode: "adaptive"     # Optional. Enum: adaptive | fixed. Default: "adaptive".
                                 #   adaptive: retry budget is a convergence limit —
                                 #     iteration count signals quality (V1/V2 contracts).
                                 #   fixed: retry budget is a fixed allocation —
                                 #     iteration count does not signal quality (V3 contracts).
                                 #   Must be "fixed" when verifiability == V3.

# ══════════════════════════════════════════════════
# SYSTEM-MANAGED FIELDS (below this line)
# ══════════════════════════════════════════════════
# System-managed fields are populated by the runner at runtime.
# They MUST NOT appear in authored contract YAML.
# The validator rejects contracts containing system-managed fields.

# ──────────────────────────────────────────────────
# ESCALATION STATE
# ──────────────────────────────────────────────────
min_tier: null                   # System-managed. Integer (1|3) or null.
                                 #   Set by escalation logic — never authored manually.
                                 #   Floor for Gate 1 routing on re-entry from ESCALATED.
                                 #   claude-code dispatches are treated as tier3 for
                                 #   floor comparison (see executor_target mapping).

# ──────────────────────────────────────────────────
# CONVERGENCE TRACKING (Amendment W)
# ──────────────────────────────────────────────────
# Populated by the runner at terminal state. Read-only at contract level.
convergence_record:              # System-managed. Object or null.
  iterations_used: null          #   Integer. Filled at terminal state.
  initial_tier: null             #   Integer. Tier assigned at first ROUTING.
  final_tier: null               #   Integer. Tier that completed execution.
  escalated: null                #   Boolean. Whether escalation occurred.
  escalation_chain: []           #   List of {from_tier, to_tier, reason} objects.
  outcome: null                  #   Enum: completed | dead_letter | abandoned.

# ──────────────────────────────────────────────────
# TERMINATION AND PROMOTION CONDITIONS (computed, not authored)
# ──────────────────────────────────────────────────
# These are not fields in the YAML — they are semantic rules enforced by the runner.
# Documented here for completeness:
#
# termination_condition: ALL tests pass AND ALL artifacts verified
# promotion_condition:   termination_condition AND ALL quality_checks pass
# partial_promotion routes via partial_promotion policy when promotion_condition fails.
```

### 1.2 Test Type Parameters

Each `tests[].type` accepts type-specific `params`:

| Type | Required params | Optional params | Semantics |
|------|----------------|-----------------|-----------|
| `file_exists` | `path` (on test object) | — | File exists at staging path. |
| `frontmatter_valid` | `path` | `required_fields: [list]` | YAML frontmatter present and parseable. Optional: specific fields exist. |
| `command_exit_zero` | `command: string` | `working_dir: string` | Shell command exits 0. Working dir defaults to staging_path. |
| `file_matches_pattern` | `path`, `pattern: regex` | `match_count: int` | File content matches regex. Optional minimum match count. |
| `content_contains` | `path`, `substring: string` | — | File contains exact substring. |
| `content_not_contains` | `path`, `substring: string` | — | File does NOT contain substring. |
| `json_schema_valid` | `path`, `json_schema: object` | — | File content validates against JSON Schema. |
| `yaml_parseable` | `path` | — | File is valid YAML. |
| `line_count_range` | `path` | `min: int`, `max: int` | File line count within range. At least one of min/max required. |

All `path` values follow the PATH RULE defined in §1.1: relative to `staging_path` by default, prefixed with `vault:` for vault-relative paths. This is a closed enum — new test types require a schema version bump.

### 1.3 Failure Context Schema (Amendment T)

When a Ralph loop iteration fails contract evaluation, the runner produces structured diagnostics injected into the next iteration:

```yaml
failure_context:
  iteration: 1                          # Which iteration failed.
  failed_checks:                        # List — one entry per failed check.
    - check_id: "test_frontmatter_valid"
      check_type: "test"                # test | artifact | quality_check
      expected: "status field present"
      actual: "status field missing"
      delta: "frontmatter missing required 'status' field"
  failure_class: "deterministic"        # Enum: deterministic | reasoning | tool | semantic
  retry_strategy: "fix input, same executor"
                                        # Runner-recommended strategy from §9.4.
  budget_remaining: 2                   # Iterations left after this failure.
```

The `failure_context` is not part of the contract YAML itself. It is a separate document produced by the runner and injected into the dispatch envelope (Layer 6) on iteration 2+. It is documented here because it consumes contract field identifiers (`check_id` values) and must be structurally compatible.

### 1.4 Executor Return Envelope

The executor returns a structured result that the runner parses (from spec §10.3):

```yaml
execution_result:
  contract_id: "TV2-033-C1"
  status: "completed"                   # Enum: completed | failed | escalated
  iterations: 2
  staging_path: "_staging/TV2-033-C1/"
  artifacts_produced:
    - path: "_staging/TV2-033-C1/vault-health-notes.md"
      sha256: "a1b2c3..."
  test_results:
    - test: "test_file_exists"
      result: "pass"                    # Enum: pass | fail
    - test: "test_frontmatter_valid"
      result: "pass"
  confidence: "high"                    # Gate 2 field. Enum: high | medium | low.
                                        # Required on iteration 1 for Tier 1 contracts.
                                        # Optional otherwise.
  confidence_signals: []                # List of strings. Evidence for confidence level.
  uncertainty_flags: []                 # List of strings. Populated when confidence < high.
  failure_summary: null                 # String or null. Populated on failure/escalation.
  failure_class: null                   # Enum or null: deterministic | reasoning | tool | semantic
  token_usage:
    input: 12400
    output: 3200
```

## 2. Blocking vs Advisory Semantics

### 2.1 Check Type Behavior Table

| Check Type | Blocks Termination | Blocks Promotion | Evaluated By | Timing |
|------------|-------------------|------------------|-------------|--------|
| `tests` | **YES** | YES (implied) | Runner (mechanical) | During `iteration_checking` sub-state |
| `artifacts` | **YES** | YES (implied) | Runner (mechanical) | During `iteration_checking` sub-state |
| `quality_checks` | **NO** (advisory) | **YES** | Tess orchestrator (judgment) | During QUALITY_EVAL state, after STAGED |

### 2.2 How the Contract Runner Uses Each Type

**Tests and artifacts (blocking termination):**
The runner evaluates all tests and artifacts at the end of each Ralph loop iteration (sub-state `iteration_checking`). If ANY test or artifact fails, the iteration fails. The runner produces structured failure context (Amendment T) and either retries (if budget remains) or escalates. The executor cannot terminate successfully until every test and artifact passes.

**Quality checks (advisory for termination, blocking for promotion):**
Quality checks are never evaluated during the Ralph loop. The executor terminates when tests + artifacts pass, regardless of quality. After the executor terminates and artifacts reach the STAGED state, Tess evaluates quality checks during the QUALITY_EVAL state. If quality checks fail, the contract enters QUALITY_FAILED and routes via the `partial_promotion` policy.

This separation preserves evaluator-executor separation (AD-007): the executor does not wait for or receive Tess's quality judgment during its execution loop.

### 2.3 Interaction with partial_promotion Policy

When quality checks fail, the `partial_promotion` field determines the next state:

| Policy | Quality Failure Behavior | State Transition |
|--------|------------------------|------------------|
| `discard` | All staged artifacts abandoned. | QUALITY_FAILED → ABANDONED |
| `hold_for_review` | Staging preserved. Dead-letter entry created for Danny to review. | QUALITY_FAILED → DEAD_LETTER |
| `promote_passing` | Artifacts that individually passed quality checks are promoted. Failing artifacts stay in staging with dead-letter entry. | QUALITY_FAILED → PROMOTION_PENDING (passing subset) |

**V3 quality retry path:** Before applying `partial_promotion`, the runner checks whether `verifiability == V3 AND quality_retry_budget > 0`. If so, the contract transitions QUALITY_FAILED → ESCALATED with quality failure context (per Amendment T), allowing a re-attempt. The quality retry budget is decremented. After the quality retry budget is exhausted, the `partial_promotion` policy applies normally.

## 3. Version Strategy

### 3.1 Schema Version Format

The `schema_version` field uses semantic versioning (semver):

```
MAJOR.MINOR.PATCH
```

| Component | When to increment | Example |
|-----------|------------------|---------|
| MAJOR | Breaking change: removed field, changed field type, changed field semantics | `1.0.0` → `2.0.0` |
| MINOR | Additive change: new optional field, new enum value, new test type | `1.0.0` → `1.1.0` |
| PATCH | Fix: documentation correction, default value adjustment (non-breaking) | `1.0.0` → `1.0.1` |

The initial schema version is `1.0.0`.

### 3.2 Version Validation at Load Time

The contract runner validates `schema_version` before dispatching:

1. Parse `schema_version` as semver.
2. Compare against the runner's supported version range: `>=1.0.0 <2.0.0` (for v1 runner).
3. If MAJOR differs from the runner's supported MAJOR: **reject** — contract is incompatible.
4. If MINOR exceeds the runner's known MINOR: **warn** — contract may contain unknown optional fields (which are ignored per the forward-compatibility rule below).
5. If MINOR is within range: **accept** — all fields are known.

### 3.3 Backward Compatibility Rules

1. **MAJOR version changes are breaking.** Old contracts require migration or rejection. The runner only supports one MAJOR version at a time.
2. **MINOR version changes are additive.** A v1.2.0 runner can process v1.0.0 contracts (missing optional fields get defaults). A v1.0.0 runner processing a v1.2.0 contract applies **version-aware validation**: unknown optional fields are stripped with a warning (not rejected), and validation proceeds on the remaining known fields. This reconciles forward compatibility with the closed schema principle (Amendment V) — see §4.1 item 6 for the version-aware exception.
3. **No field removal within a MAJOR version.** Fields can be deprecated (documented as "deprecated, ignored") but not removed until the next MAJOR bump.
4. **Enum values are append-only within a MAJOR version.** New values can be added (MINOR bump); existing values cannot be removed or renamed.

### 3.4 Migration Path

When a MAJOR version bump occurs:

1. Publish a migration script: `migrate-contracts-v{old}-to-v{new}.sh`
2. Migration script reads old contracts, transforms fields, writes new contracts with updated `schema_version`.
3. Both versions are supported during a transition period (one release cycle).
4. After transition, old-version contracts in QUEUED are rejected with a migration instruction in the dead-letter entry.

## 4. Validation Tooling

### 4.1 Validation Script Design

The validation script (`validate-contract.sh`) checks a contract YAML file against the schema. It is a mechanical check — no LLM involved.

**What it checks:**

1. **YAML parseability.** The file must be valid YAML.

2. **Required field presence.** All required fields must be present:
   - `schema_version`, `contract_id`, `task_id`, `description`, `service`, `created`
   - `action_class`, `verifiability`, `staging_path`
   - `partial_promotion`, `retry_budget`

3. **Type checking.** Each field matches its declared type:
   - Strings where strings are expected
   - Integers where integers are expected
   - Booleans where booleans are expected
   - Enums contain only valid values
   - ISO 8601 timestamps/durations parse correctly

4. **Enum validation.**
   - `verifiability` in `{V1, V2, V3}`
   - `priority` in `{critical, normal, low, deferred}`
   - `partial_promotion` in `{discard, hold_for_review, promote_passing}`
   - `convergence_mode` in `{adaptive, fixed}`
   - `confidence_threshold` in `{high, medium, low}`
   - `tests[].type` in the closed enum from §1.2
   - `artifacts[].executor` in `{runner}`
   - `quality_checks[].evaluator` in `{tess}`

5. **Cross-field consistency.**
   - `quality_retry_budget > 0` only valid when `verifiability == V3`
   - `quality_retry_budget == 0` when `verifiability` in `{V1, V2}`
   - `convergence_mode == fixed` when `verifiability == V3`
   - `convergence_mode == adaptive` when `verifiability` in `{V1, V2}`
   - `defer_until` present only when `priority == deferred`
   - `quality_checks` present when `quality_retry_budget > 0`
   - All `tests[].id`, `artifacts[].id`, `quality_checks[].id` are unique within the contract
   - `staging_path` matches format `_staging/{contract_id}/`

6. **Closed schema enforcement (Amendment V).** Any field not in the schema definition (§1.1) is flagged as an error. **Version-aware exception:** When the contract's `schema_version` MINOR exceeds the validator's known MINOR (same MAJOR), unknown fields are stripped with a warning and validation proceeds on the remaining known fields. When the contract's MINOR matches or is below the validator's known MINOR, unknown fields are rejected as errors.

   > **Reconciliation (Amendment V vs §3.3 forward compatibility):** Strict closed-schema rejection applies only when the validator fully understands the contract's schema version. For forward-compatible contracts (higher MINOR), the validator cannot distinguish "unknown new optional field" from "typo," so it warns, strips, and proceeds. This preserves Amendment V's intent (no silently ignored fields) while allowing additive schema evolution without breaking older runners.

7. **System-managed field rejection.** System-managed fields (`min_tier`, `convergence_record`) present in authored contract YAML are rejected. These fields are populated by the runner at runtime and must not appear in the authored contract.

8. **Schema version compatibility.** `schema_version` parses as valid semver and falls within the validator's supported range.

### 4.2 Validation Output Format

```yaml
validation_result:
  contract_id: "TV2-033-C1"
  schema_version: "1.0.0"
  valid: true                    # or false
  errors: []                     # list of {field, message, severity: error}
  warnings: []                   # list of {field, message, severity: warning}
  # Example error:
  # - field: "quality_retry_budget"
  #   message: "quality_retry_budget must be 0 for V1 contracts (got 2)"
  #   severity: "error"
  # Example warning:
  # - field: "schema_version"
  #   message: "Contract schema_version 1.3.0 exceeds validator known version 1.2.0; unknown optional fields may be present"
  #   severity: "warning"
```

### 4.3 Lenient Parsing Layer Placement (Amendment U, state-machine-design.md §17 Q4)

The lenient parsing layer sits between executor output and contract evaluation — between `iteration_working` and `iteration_checking` sub-states. It applies to the executor return envelope, not to the contract YAML itself.

Contract YAML is validated strictly (Amendment V — closed schema). Executor output is parsed leniently (Amendment U — recover from formatting errors). These are different documents with different tolerance rules:

| Document | Parsing Mode | Rationale |
|----------|-------------|-----------|
| Contract YAML | Strict (Amendment V) | Authored by Tess/action-architect. Must be correct. |
| Executor return envelope | Lenient (Amendment U) | Produced by LLM. Formatting quirks are common. |
| Failure context | Strict | Produced by runner (mechanical). Must be correct. |

## 5. Example Contracts

### 5.1 Simple Deterministic Executor — Vault Health (V1)

```yaml
schema_version: "1.0.0"
contract_id: "TV2-033-C1"
task_id: "TV2-033"
description: "Run vault health check and produce findings report"
service: "vault-health"
created: "2026-04-01T02:00:00Z"

action_class: "shell-execute"
verifiability: "V1"
priority: "normal"

staging_path: "_staging/TV2-033-C1/"

read_paths:
  - "_system/scripts/vault-check.sh"

tests:
  - id: "test_report_exists"
    type: "file_exists"
    path: "vault-health-notes.md"
  - id: "test_report_parseable"
    type: "yaml_parseable"
    path: "vault-health-notes.md"
  - id: "test_frontmatter"
    type: "frontmatter_valid"
    path: "vault-health-notes.md"
    params:
      required_fields: [type, status, created, updated]
  - id: "test_exit_code"
    type: "command_exit_zero"
    params:
      command: "bash vault:_system/scripts/vault-check.sh --report"

artifacts:
  - id: "artifact_finding_count"
    description: "Report contains at least one finding section"
    verification: "grep -c '^## ' vault-health-notes.md >= 1"
    executor: "runner"

quality_checks: []

partial_promotion: "discard"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT4H"
timeout: "PT5M"
escalation: "tess"
convergence_mode: "adaptive"
```

**Why this works:** V1 contract with all-mechanical checks. No quality_checks — there is nothing judgment-dependent about vault health output. `partial_promotion: discard` because partial vault health reports are not useful. `quality_retry_budget: 0` because V1 contracts route quality failures directly to the partial_promotion policy.

### 5.2 Judgment-Dependent Quality — Morning Briefing (V3)

```yaml
schema_version: "1.0.0"
contract_id: "TV2-037-C1"
task_id: "TV2-037"
description: "Generate morning briefing with calendar, research, and feed intel"
service: "morning-briefing"
created: "2026-04-01T07:00:00Z"

action_class: "structured-report"
verifiability: "V3"
executor_target: "tier3"
priority: "normal"

staging_path: "_staging/TV2-037-C1/"

read_paths:
  - "_openclaw/state/apple-calendar.txt"
  - "_openclaw/state/apple-reminders.json"
  - "_openclaw/research/output/"
  - "Domains/career/goal-tracker.md"

tests:
  - id: "test_briefing_exists"
    type: "file_exists"
    path: "morning-briefing.md"
  - id: "test_frontmatter"
    type: "frontmatter_valid"
    path: "morning-briefing.md"
    params:
      required_fields: [type, status, created]
  - id: "test_min_length"
    type: "line_count_range"
    path: "morning-briefing.md"
    params:
      min: 20

artifacts:
  - id: "artifact_sections"
    description: "Briefing contains calendar, research, and intel sections"
    verification: "grep -cE '^## (Calendar|Research|Feed Intel)' morning-briefing.md >= 3"
    executor: "runner"

quality_checks:
  - id: "qc_relevance"
    description: "Briefing content is relevant to today's calendar and active goals"
    evaluator: "tess"
  - id: "qc_actionability"
    description: "Briefing includes actionable items, not just summaries"
    evaluator: "tess"
  - id: "qc_no_stale_data"
    description: "No references to events or data older than 48 hours presented as current"
    evaluator: "tess"

partial_promotion: "hold_for_review"
retry_budget: 3
quality_retry_budget: 1
max_queue_age: "PT2H"
timeout: "PT5M"
escalation: "tess"
convergence_mode: "fixed"
```

**Why this works:** V3 contract because briefing quality is judgment-dependent. Tests and artifacts provide structural scaffolding (file exists, has sections, minimum length). Quality checks require Tess to evaluate relevance, actionability, and data freshness — things that cannot be mechanically verified. `quality_retry_budget: 1` gives one re-attempt after quality feedback. `convergence_mode: fixed` because iteration count does not signal convergence for V3 tasks. `hold_for_review` because a partial briefing is better than none — Danny can review and promote manually.

### 5.3 Side-Effecting with Human Approval — Email Triage (V2)

```yaml
schema_version: "1.0.0"
contract_id: "TV2-036-C1"
task_id: "TV2-036"
description: "Triage unread Gmail, apply labels, alert on urgent items"
service: "email-triage"
created: "2026-04-01T08:00:00Z"

action_class: "external-communication"
verifiability: "V2"
priority: "normal"

requires_human_approval: true
side_effects:
  - "gmail_label"
  - "send_telegram"
confidence_threshold: "high"

staging_path: "_staging/TV2-036-C1/"

read_paths:
  - "Domains/career/career-overview.md"

tests:
  - id: "test_triage_report"
    type: "file_exists"
    path: "triage-report.yaml"
  - id: "test_report_schema"
    type: "json_schema_valid"
    path: "triage-report.yaml"
    params:
      json_schema:
        type: "object"
        required: ["messages_processed", "labels_applied", "urgent_alerts"]
        properties:
          messages_processed:
            type: "integer"
          labels_applied:
            type: "array"
          urgent_alerts:
            type: "array"

artifacts:
  - id: "artifact_no_unknown_labels"
    description: "All applied labels are from the approved label set"
    verification: "python3 vault:_system/scripts/validate_labels.py triage-report.yaml"
    executor: "runner"
  - id: "artifact_alert_format"
    description: "Urgent alerts follow the notification template"
    verification: "python3 vault:_system/scripts/validate_alerts.py triage-report.yaml"
    executor: "runner"

quality_checks:
  - id: "qc_classification_accuracy"
    description: "Label assignments match message content (spot-check 3 messages)"
    evaluator: "tess"
  - id: "qc_no_false_urgents"
    description: "Urgent alerts are genuinely urgent, not routine"
    evaluator: "tess"

partial_promotion: "hold_for_review"
retry_budget: 3
quality_retry_budget: 0
max_queue_age: "PT2H"
timeout: "PT5M"
escalation: "danny"
convergence_mode: "adaptive"
```

**Why this works:** Side-effecting contract — `requires_human_approval: true` ensures Gate 3 routes to PENDING_APPROVAL before any execution begins. `side_effects` declares the irreversible operations so Gate 3 can match against its policy table. `escalation: "danny"` because email triage failures should alert Danny directly, not just Tess. `quality_retry_budget: 0` because V2 contracts use heuristic verification, and quality failures go to the partial_promotion policy. `confidence_threshold: "high"` raises the bar for Gate 2 — if the executor is anything less than high confidence on a side-effecting task, escalate immediately.

## 6. Cross-References

### 6.1 Schema ↔ State Machine States (TV2-017)

| Contract Field | State Machine Consumption Point |
|----------------|-------------------------------|
| `priority`, `defer_until`, `max_queue_age` | QUEUED: scheduler ordering, deferred pause, stale detection |
| `action_class`, `verifiability`, `executor_target` | ROUTING: Gate 1 classification, tier assignment |
| `requires_human_approval`, `side_effects` | ROUTING: Gate 3 policy match → PENDING_APPROVAL |
| `min_tier` | ROUTING (re-entry from ESCALATED): floor for Gate 1 |
| `tests`, `artifacts` | EXECUTING → `iteration_checking`: termination evaluation |
| `confidence_threshold` | EXECUTING → `iteration_checking` (i1): Gate 2 escalation |
| `retry_budget` | EXECUTING → `retry_preparing`: budget check → ESCALATED or loop |
| `staging_path` | STAGED: artifact location for quality evaluation |
| `quality_checks` | QUALITY_EVAL: promotion evaluation |
| `quality_retry_budget`, `verifiability` | QUALITY_FAILED: V3 re-dispatch eligibility check |
| `partial_promotion` | QUALITY_FAILED: route to discard/hold/promote_passing |
| `convergence_mode` | COMPLETED/DEAD_LETTER/ABANDONED: Gate 4 convergence tracker input |
| `convergence_record` | Terminal states: written by runner for Gate 4 consumption |

### 6.2 Schema ↔ Escalation Gates (TV2-018)

| Gate | Fields Consumed | How |
|------|----------------|-----|
| Gate 1 (boundary) | `action_class` | Lookup in routing table → candidate tier |
| Gate 1 (re-entry) | `min_tier` | Floor constraint — cannot route below this tier |
| Gate 2 (confidence) | `confidence_threshold`, executor return `confidence` | Compare executor confidence against threshold. Low → ESCALATED. |
| Gate 3 (risk) | `side_effects`, `action_class`, `requires_human_approval` | Match against risk policy table. Side-effect declarations trigger rule matching. |
| Gate 4 (convergence) | `convergence_record`, `action_class`, `verifiability` | Terminal-state data feeds rolling window statistics per action class |

### 6.3 Schema ↔ System Prompt Architecture (TV2-023)

The contract YAML occupies Layer 4 of the prompt envelope:

| Prompt Layer | Contract Schema Relationship |
|-------------|------------------------------|
| Layer 1 (stable header) | References `retry_budget` remaining, `escalation` policy, `staging_path` as hard constraints |
| Layer 2 (service context) | Uses `action_class` to select relevant routing table entries and executor profile |
| Layer 3 (overlays) | Selected based on `service` and `action_class` from service interface definitions |
| Layer 4 (contract) | The contract YAML itself, verbatim. Budget: 1-3K tokens. Contracts exceeding 3K should be decomposed. |
| Layer 5 (vault context) | Populated from `read_paths` field. Subject to compaction. |
| Layer 6 (failure context) | Consumes `tests[].id`, `artifacts[].id`, `quality_checks[].id` for structured diagnostics |

For Claude Code dispatch (§3.3 of TV2-023), the contract YAML is passed as part of the system prompt to `claude --print`. Read paths are passed as file paths, not file contents — Claude Code reads them with its own tools.

## 7. Appendix: Field Reference (Quick Lookup)

| Field | Type | Required | Default | Authored | Mutable After Dispatch |
|-------|------|----------|---------|----------|----------------------|
| `schema_version` | semver string | yes | — | yes | no |
| `contract_id` | string | yes | — | yes | no |
| `task_id` | string | yes | — | yes | no |
| `description` | string (<=120 chars) | yes | — | yes | no |
| `service` | string | yes | — | yes | no |
| `created` | ISO 8601 | yes | — | yes | no |
| `action_class` | string | yes | — | yes | no |
| `verifiability` | enum (V1/V2/V3) | yes | — | yes | no |
| `executor_target` | enum (tier1/tier3/claude-code) | no | from Gate 1 | yes | no |
| `priority` | enum | no | "normal" | yes | no |
| `defer_until` | ISO 8601 or null | no | null | yes | no |
| `requires_human_approval` | boolean | no | false | yes | no (but Gate 3 can set) |
| `side_effects` | list of strings | no | [] | yes | no |
| `confidence_threshold` | enum (high/medium/low) | no | "medium" | yes | no |
| `staging_path` | string | yes | — | yes | no |
| `read_paths` | list of strings | no | [] | yes | no |
| `tests` | list of test objects | no | [] | yes | no |
| `artifacts` | list of artifact objects | no | [] | yes | no |
| `quality_checks` | list of qc objects | no | [] | yes | no |
| `partial_promotion` | enum | yes | — | yes | no |
| `retry_budget` | integer >= 1 | yes | — | yes | no |
| `quality_retry_budget` | integer >= 0 | no | 0 | yes | no |
| `max_queue_age` | ISO 8601 duration | no | PT4H | yes | no |
| `timeout` | ISO 8601 duration | no | PT5M | yes | no |
| `escalation` | string | no | "tess" | yes | no |
| `convergence_mode` | enum (adaptive/fixed) | no | "adaptive" | yes | no |
| `min_tier` | integer or null | no | null | **no** | system-managed |
| `convergence_record` | object or null | no | null | **no** | system-managed (written at terminal) |

All non-system-managed fields are immutable after the contract enters DISPATCHED state (state-machine-design.md §8). Amendment = new contract.
