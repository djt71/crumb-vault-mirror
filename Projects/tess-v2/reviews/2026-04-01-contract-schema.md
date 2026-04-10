---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/tess-v2/design/contract-schema.md
artifact_type: design
artifact_hash: 5b2433c6
prompt_hash: 827dd20e
base_ref: null
project: tess-v2
domain: software
skill_origin: peer-review
created: 2026-04-01
updated: 2026-04-01
reviewers:
  - openai/gpt-5.4
  - google/gemini-3.1-pro-preview
  - grok/grok-4-1-fast-reasoning
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
    latency_ms: 81648
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-contract-schema-openai.json
  google:
    http_status: 200
    latency_ms: 47700
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-contract-schema-google.json
  deepseek:
    http_status: 200
    latency_ms: 120011
    attempts: 1
    error: "timeout - response body empty (curl reported 200 from headers but 120s timeout truncated body)"
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-contract-schema-deepseek.json
  grok:
    http_status: 200
    latency_ms: 27452
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-contract-schema-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Contract Schema Design

**Artifact:** Projects/tess-v2/design/contract-schema.md
**Mode:** full
**Reviewed:** 2026-04-01
**Reviewers:** GPT-5.4, Gemini 3.1 Pro Preview, Grok 4.1 Fast Reasoning (DeepSeek timed out)
**Review prompt:** Full schema review -- completeness, blocking/advisory semantics, cross-references, examples, versioning, validation, closed schema principle

---

## OpenAI (gpt-5.4)

Below is a structured review of the contract schema design.

## Overall assessment

This is a strong design artifact: the schema is mostly complete, the separation between execution-time mechanical checks and post-execution quality evaluation is clear, and the document is unusually implementable for a draft. The main risks are not missing broad concepts, but a handful of internal contradictions around **closed schema vs forward compatibility**, **system-managed fields that appear in the schema**, **path semantics**, and **example correctness**.

---

## Findings

- [F1]
- [Severity]: CRITICAL
- [Finding]: The document contains a direct contradiction between the **closed schema principle** and the **forward-compatibility/versioning rule**.
- [Why]: §1.1 and §4.1(6) say any field not listed is invalid and must be rejected at load time. But §3.2(4) and §3.3(2) say a runner may process newer MINOR versions by ignoring unknown optional fields with a warning. Those cannot both be true. This is foundational because it affects parser behavior, validator behavior, and upgrade safety.
- [Fix]: Pick one rule and apply it everywhere:
  - **Option A: Strict closed schema** — unknown fields always reject, even on newer MINOR versions; remove all “ignore unknown optional fields” language from §3.2–§3.3.
  - **Option B: Versioned openness** — allow unknown optional fields only when schema_version MINOR is newer but same MAJOR; then Amendment V must be narrowed to “reject unknown fields for the exact supported schema versions.”  
  Given the rest of the doc, Option A seems more aligned.

- [F2]
- [Severity]: CRITICAL
- [Finding]: `convergence_record` is described as “included here for schema completeness” and appears in the field reference, but §1.1 also says “any field not listed here is invalid and must be rejected at load time,” while the same section says `convergence_record` is “not authored in contract.”
- [Why]: It is unclear whether a contract YAML containing `convergence_record` should be accepted or rejected. If accepted, authors can submit system-managed fields. If rejected, the schema listing is misleading. This affects validators and storage format.
- [Fix]: Split the model into two explicit schemas:
  1. **Authored contract schema** — only authorable fields, closed.
  2. **Runtime/enriched contract record schema** — authored fields plus system-managed fields like `min_tier`, `convergence_record`.  
  Then state clearly: authored contract YAML MUST NOT contain system-managed fields.

- [F3]
- [Severity]: CRITICAL
- [Finding]: `min_tier` has inconsistent type semantics relative to `executor_target`.
- [Why]: `executor_target` uses enum values `tier1 | tier3 | claude-code`, but `min_tier` is “Integer (1|3) or null.” This creates an impedance mismatch for routing logic, especially if `claude-code` is a routable target. A floor expressed as integer cannot naturally constrain a non-numeric target.
- [Fix]: Normalize target typing:
  - Either make both fields use the same symbolic domain, e.g. `tier1 | tier3 | claude-code`,
  - Or separate concerns into `min_execution_tier: 1|3|null` and `executor_target: tier1|tier3|claude-code|null` with explicit precedence rules.
  Also specify how `claude-code` compares to tier floors.

- [F4]
- [Severity]: CRITICAL
- [Finding]: Path semantics are internally inconsistent between §1.1, §1.2, and the examples.
- [Why]: In §1.1 test paths are shown as vault-relative, even under `_staging/...`; in §1.2 all `path` values are said to be relative to `staging_path` unless they begin with an explicit vault-relative prefix; examples then use bare filenames like `vault-health-notes.md`. This ambiguity will produce validator/runner disagreement and broken checks.
- [Fix]: Define one canonical rule, e.g.:
  - For `tests[].path`, `artifacts` verification working dir, and produced artifact paths, paths are **staging-relative by default**.
  - Full vault-relative paths are allowed only when prefixed with `/` or another explicit marker.
  - Update all schema comments and examples to use the same convention.  
  Also define the semantics for `read_paths` separately, since those are vault-relative.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: The example in §5.1 uses `yaml_parseable` for `vault-health-notes.md`, which appears to be a Markdown file.
- [Why]: As written, `yaml_parseable` validates the whole file as YAML, not “Markdown with YAML frontmatter.” That check would fail on a normal Markdown document. This undermines confidence in the examples and could mislead implementers.
- [Fix]: Replace `yaml_parseable` with a more appropriate check:
  - either rely on `frontmatter_valid`,
  - or introduce a dedicated `markdown_with_frontmatter_valid` test type if needed.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: The §5.1 example’s `command_exit_zero` likely executes in the wrong working directory relative to the declared inputs.
- [Why]: `command_exit_zero` defaults `working_dir` to `staging_path`, but the script `vault-check.sh` is only listed in `read_paths` under `_system/scripts/vault-check.sh`. The command shown is `bash vault-check.sh --report`, which would not resolve from staging unless the script is copied there first.
- [Fix]: In the example, either:
  - set `working_dir` and command explicitly, e.g. `command: "bash _system/scripts/vault-check.sh --report"` with clear vault-root semantics, or
  - copy the script into staging and state that as part of executor behavior.  
  More generally, specify whether commands execute relative to staging, vault root, or a sandbox root.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: `artifacts[].verification` is underspecified and partially conflicts with the claim that artifact checks are “structured checks.”
- [Why]: The field is described as “Shell command or structured check,” but there is no schema for the structured form, no working directory definition, no escaping/sandbox policy, and no output contract. This is not complete enough to implement consistently or safely.
- [Fix]: Replace the free-form duality with one of:
  - a strict structured artifact verification schema, or
  - an explicit `verification_type: shell | builtin` plus type-specific subfields.  
  Define working directory, allowed interpreters, timeout, env, stdout/stderr capture, and path reference rules.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: `partial_promotion: promote_passing` conflicts with “Promotion is ATOMIC per contract — all promotable artifacts move together or none do.”
- [Why]: “Promote passing subset” implies per-artifact partial promotion, while “atomic per contract” implies a single all-or-nothing commit. The phrase “all promotable artifacts move together” softens this, but leaves unclear whether the subset is computed first and then atomically promoted as a batch, or whether individual artifact promotions may occur independently.
- [Fix]: Rewrite to define the atomic unit precisely:
  - e.g. “Promotion is atomic over the selected promotion set. Under `promote_passing`, the selected set is the subset of artifacts whose associated checks passed; that set is promoted in one transaction or not at all.”

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: The mapping from `quality_checks` to individual artifacts is not defined, yet `promote_passing` depends on knowing which artifacts passed quality checks.
- [Why]: Current `quality_checks` are contract-level evaluative criteria with no `applies_to` field. If a contract produces multiple artifacts, the system cannot determine which artifact “individually passed quality checks.”
- [Fix]: Add artifact scoping:
  - either `quality_checks[].applies_to: [artifact_id...]`,
  - or define quality checks as contract-level only and remove `promote_passing`,
  - or add per-artifact quality result objects in the evaluator output.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: `tests`, `artifacts`, and `quality_checks` are optional, but the schema does not define minimum validity constraints for contracts that omit all verification.
- [Why]: A contract with no tests, no artifacts, and no quality checks could trivially terminate/promote without meaningful validation depending on implementation. That weakens the contract model.
- [Fix]: Add a cross-field invariant such as:
  - at least one of `tests`, `artifacts`, or `quality_checks` must be non-empty,
  - and at least one of `tests` or `artifacts` must be non-empty for termination to be mechanically grounded.

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: The validation section is not complete about nested closed-schema enforcement.
- [Why]: §4.1(6) says unknown fields are rejected, but it does not explicitly say whether this applies inside nested objects such as test objects, `params`, artifact objects, quality check objects, `convergence_record`, and validation output examples. Without nested enforcement, “closed schema” becomes porous.
- [Fix]: State explicitly that closed-schema validation applies recursively to all authored objects, except where a field intentionally embeds an open schema object such as `json_schema_valid.params.json_schema`.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: The schema does not define how `json_schema_valid` handles YAML input, but the example uses `json_schema_valid` on `triage-report.yaml`.
- [Why]: JSON Schema can validate YAML after parsing YAML into a data model, but that behavior must be specified. Otherwise some implementations will reject non-JSON files and others will parse YAML then validate.
- [Fix]: Add explicit semantics: “`json_schema_valid` parses JSON or YAML based on file contents/extension into the JSON data model, then validates against the provided JSON Schema.”

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: `defer_until` rules are only one-way.
- [Why]: The doc says `defer_until` is only valid when `priority == deferred`, but does not require it when priority is deferred. A deferred contract with `defer_until: null` is semantically incomplete.
- [Fix]: Add the reciprocal validator rule: if `priority == deferred`, `defer_until` is required and must be a future timestamp.

- [F14]
- [Severity]: SIGNIFICANT
- [Finding]: `description` is constrained to `<=120 chars` in comments and the appendix, but this limit is missing from the validation checklist.
- [Why]: This is a concrete schema constraint that should be validator-enforced if it exists at all.
- [Fix]: Add it to §4.1 required checks.

- [F15]
- [Severity]: SIGNIFICANT
- [Finding]: The semantics of `requires_human_approval` are inconsistent with immutability.
- [Why]: Appendix says the field is immutable after dispatch, but §1.1 says Gate 3 can set it automatically. If Gate 3 sets it after authoring, that is mutation of contract state or metadata and needs a clear phase distinction.
- [Fix]: Clarify whether Gate 3:
  - mutates the contract record before DISPATCHED,
  - writes derived routing state elsewhere,
  - or sets an envelope/runtime field rather than contract YAML.  
  Prefer “derived runtime routing state” over mutating authored contract fields.

- [F16]
- [Severity]: SIGNIFICANT
- [Finding]: `executor_target` “forces minimum tier” but is itself not aligned with the gate/routing tables.
- [Why]: If `executor_target` can be `claude-code`, it is not just a minimum tier override; it may be selecting an executor class/tooling mode. The current prose treats it as a floor but its values suggest a mixed concept: tier plus executor implementation.
- [Fix]: Split into two fields:
  - `min_tier`
  - `executor_mode` or `executor_family` (`default | claude-code`)  
  Or redefine `executor_target` as a pure dispatch destination and remove “floor” language.

- [F17]
- [Severity]: SIGNIFICANT
- [Finding]: Gate 2 confidence semantics are underdefined for non-tier1 contracts.
- [Why]: The schema says `confidence_threshold` is only meaningful for tier1 contracts and the return envelope says `confidence` is required on iteration 1 for Tier 1 contracts, optional otherwise. But the cross-reference table simply says Gate 2 compares threshold against executor return confidence. This leaves unspecified whether Gate 2 is skipped for tier3/claude-code or can still consume confidence if present.
- [Fix]: State explicitly: “Gate 2 applies only to Tier 1 dispatches. For Tier 3 and claude-code dispatches, confidence is ignored/not produced.”

- [F18]
- [Severity]: SIGNIFICANT
- [Finding]: Retry budget semantics are underspecified for mixed failure modes.
- [Why]: The schema distinguishes `retry_budget` and `quality_retry_budget`, and says escalation does not consume an iteration. But it does not clearly specify what happens after escalation and re-entry: does the original iteration count continue, does the same `retry_budget` continue across tiers, and are quality retries counted in `iterations_used`?
- [Fix]: Add a short normative section defining counters:
  - whether retries are global across tiers,
  - whether quality retries increment `iterations_used`,
  - whether post-escalation re-dispatch resumes or resets budgets.

- [F19]
- [Severity]: SIGNIFICANT
- [Finding]: The validation tooling section omits several implementable constraints implied elsewhere.
- [Why]: To be “complete enough to implement from,” it should also validate:
  - uniqueness/format of `contract_id` against `task_id`,
  - that `created` is UTC if required,
  - `side_effects` item types/non-empty strings,
  - `read_paths` item normalization,
  - duplicate path handling,
  - command/artifact verification non-empty strings,
  - line_count_range requiring at least one of min/max and min<=max.
- [Fix]: Expand §4.1 into a fuller checklist or publish a machine-readable JSON Schema plus supplementary semantic validator rules.

- [F20]
- [Severity]: SIGNIFICANT
- [Finding]: The schema lacks an explicit declaration of intended output artifacts and canonical promotion destinations.
- [Why]: Contracts define staging and checks, but not the expected final destination(s) in the canonical vault. Since promotion is a core concern, destination mapping is surprisingly absent. It may exist elsewhere, but this schema claims to define what must be produced and when to promote.
- [Fix]: Add something like:
  - `outputs: [{artifact_id, staging_path, promote_to}]`
  This would also help `promote_passing` and per-artifact quality.

- [F21]
- [Severity]: MINOR
- [Finding]: The terminology around “artifacts” is overloaded: it refers both to produced files and to “artifact checks.”
- [Why]: This may confuse implementers reading `artifacts` as output declarations rather than verification objects.
- [Fix]: Consider renaming the check block to `artifact_checks` or adding a separate `outputs` section.

- [F22]
- [Severity]: MINOR
- [Finding]: The examples do not include a contract with multiple produced artifacts, despite the promotion policy discussing subsets and per-artifact behavior.
- [Why]: A multi-artifact example would test the hardest semantics in the design.
- [Fix]: Add one example showing:
  - two or more outputs,
  - artifact-scoped checks,
  - a `promote_passing` scenario.

- [F23]
- [Severity]: MINOR
- [Finding]: `created` is required, but no `updated` field exists at contract level despite examples checking `updated` in artifact frontmatter and the document metadata itself having `updated`.
- [Why]: Not wrong, but mildly inconsistent in style and may raise questions about contract amendment/version history.
- [Fix]: Either explicitly say contracts are immutable and therefore have no contract-level `updated`, or add a system-managed `updated` in the enriched runtime record only.

- [F24]
- [Severity]: MINOR
- [Finding]: The return envelope lacks a schema/version field of its own.
- [Why]: Since the executor return envelope is parsed leniently and is a separate document type, versioning it independently would help future evolution.
- [Fix]: Add `envelope_version` or `result_schema_version`.

- [F25]
- [Severity]: MINOR
- [Finding]: `escalation` is typed as a free-form string, but examples and prose imply a constrained enum (`tess`, `danny`).
- [Why]: Free-form strings make validation and integration routing harder.
- [Fix]: If only known values are supported, make it an enum. If extensible, document allowed identifier format and resolution rules.

- [F26]
- [Severity]: MINOR
- [Finding]: The validation output format uses `severity` inside both errors and warnings lists, which is redundant.
- [Why]: Minor schema noise.
- [Fix]: Either keep a single findings list with severities, or keep separate lists and drop nested severity.

- [F27]
- [Severity]: MINOR
- [Finding]: The document says “new test types require a schema version bump,” and §3.1 says that is a MINOR bump, which is fine, but this interacts awkwardly with strict closed-schema behavior on older runners.
- [Why]: If unknown enum values are introduced under a MINOR bump and old runners reject them, then the practical compatibility story is “newer runner required,” not “old runner can process newer minor version.”
- [Fix]: Clarify compatibility expectations after resolving F1: either old runners reject newer MINOR contracts, or enum expansion is only allowed when all consumers are upgraded.

- [F28]
- [Severity]: STRENGTH
- [Finding]: The separation between `tests`/`artifacts` for termination and `quality_checks` for promotion is conceptually strong and well explained.
- [Why]: This cleanly preserves evaluator-executor separation and avoids forcing the executor to wait on subjective quality judgments.
- [Fix]: Keep this structure; just tighten the edge cases around quality retry and per-artifact promotion.

- [F29]
- [Severity]: STRENGTH
- [Finding]: The document is unusually operational: it includes schema shape, semantics, validation expectations, failure context, and return envelope in one place.
- [Why]: That makes it much easier for implementers to build runner, validator, and prompt assembly consistently.
- [Fix]: Preserve this integrated style in future design docs.

- [F30]
- [Severity]: STRENGTH
- [Finding]: The cross-reference tables in §6 are mostly coherent and useful.
- [Why]: They provide a clear systems view of which fields are consumed where, reducing hidden coupling.
- [Fix]: After fixing the issues around Gate 2, `min_tier`, and system-managed fields, these tables will be very strong.

- [F31]
- [Severity]: STRENGTH
- [Finding]: The examples are well chosen at the scenario level: deterministic/V1, judgment-heavy/V3, and side-effecting/V2 give good coverage of the intended design space.
- [Why]: They make the abstract schema concrete and reveal important policy interactions like human approval and quality retry.
- [Fix]: Keep them, but correct the implementation-level issues noted above.

- [F32]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: The document relies on references such as “spec §8-§9,” “TV2-017,” “TV2-018,” “TV2-021a,” “TV2-023,” “AD-007,” “AD-008,” and “Amendments T/U/V/W/X,” but those source artifacts are not provided here for independent verification.
- [Why]: The review can assess internal consistency, but cannot verify that the schema actually matches those upstream sources.
- [Fix]: Perform grounded verification against the cited source documents, especially for state transitions, gate behavior, prompt layer placement, and amendment-specific rules.

---

## Focused answers to your evaluation questions

### 1. Schema completeness
Mostly complete, but not fully.
- Strong coverage of metadata, routing, verification, retry, and runtime diagnostics.
- Missing or underdefined areas:
  - explicit output artifact declarations and promotion destinations,
  - per-artifact mapping for quality and promotion,
  - fully specified path semantics,
  - separation of authored vs runtime-enriched schema,
  - more precise execution/verification command semantics.

### 2. Blocking vs advisory semantics
Conceptually clear and mostly correct.
- The distinction is understandable: termination is mechanical, promotion can be judgment-based.
- Main edge cases:
  - `promote_passing` without per-artifact quality mapping,
  - quality retry interaction with iteration counts and escalation,
  - contracts with no tests/artifacts.

### 3. Cross-reference consistency
Mostly good, but not fully internally consistent.
- Problems:
  - Gate 2 semantics are too broad in the cross-reference table.
  - `min_tier` typing doesn’t align with `executor_target`.
  - Gate 3 “can set” `requires_human_approval` conflicts with field immutability unless treated as runtime derivation.

### 4. Example contracts
Good coverage, but with correctness gaps.
- V1 example has a likely invalid `yaml_parseable` check and command path ambiguity.
- V3 example is the cleanest.
- V2 example correctly exercises side effects and approval, but also reveals the YAML-vs-JSON-schema ambiguity.
- Missing: a multi-artifact contract and a `deferred` scheduling example.

### 5. Versioning strategy
Semver is appropriate in principle, but the compatibility rules are not sound as written.
- The major/minor/patch framing is sensible.
- The current forward-compatibility story conflicts with closed schema rejection.
- Once that contradiction is resolved, semver will work well.

### 6. Validation tooling
Close, but not yet complete enough to implement without interpretation.
- Good baseline checklist.
- Needs:
  - nested closed-schema rules,
  - tighter path/command semantics,
  - more cross-field invariants,
  - authored-vs-runtime schema distinction,
  - clearer handling of open embedded objects like JSON Schema.

### 7. Closed schema principle
Not consistently applied.
- It is stated strongly in multiple places.
- But it is undermined by:
  - the forward-compatibility rule that ignores unknown optional fields,
  - inclusion of system-managed fields in the listed schema,
  - lack of explicit recursive enforcement rules for nested objects.

---

## Recommended top-priority fixes

If you only address a few things before treating this as foundational, I’d prioritize:

1. **Resolve closed-schema vs forward-compatibility contradiction** (F1).
2. **Separate authored contract schema from runtime/enriched record schema** (F2).
3. **Normalize target/tier typing and routing semantics** (F3, F16).
4. **Make path semantics fully canonical and update examples accordingly** (F4, F6).
5. **Define per-artifact output/promotion modeling** (F8, F9, F20).
6. **Correct the examples so they are executable as written** (F5, F6, F12).

If you want, I can also turn this into:
- a **redline-style proposed revision list by section**, or
- a **machine-checkable validation spec** separating JSON Schema constraints from semantic validator rules.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of the "Tess v2 — Contract Schema Design" architecture document, evaluated across the seven requested dimensions.

### CRITICAL

- **[F1]**
- **[Severity]**: CRITICAL
- **[Finding]**: Direct contradiction between Backward Compatibility Rules (§3.3) and Closed Schema Enforcement (§4.1 / Amendment V).
- **[Why]**: Section 3.3 Rule 2 states that an older runner processing a newer MINOR version contract "ignores unknown optional fields and logs a warning." However, Section 4.1.6 strictly enforces Amendment V, stating: "Any field not in the schema definition... is flagged as an error. Unknown fields are rejected, not silently ignored." An older runner physically cannot ignore unknown fields for forward compatibility if its validation script strictly rejects any field not in its hardcoded schema definition.
- **[Fix]**: Introduce a specific version-aware carve-out in the validation tooling. For example: "If the contract's `schema_version` MINOR version is > the validator's known MINOR version, unknown fields are logged as warnings and stripped out rather than causing a validation failure. If the versions match, unknown fields are strictly rejected."

- **[F2]**
- **[Severity]**: CRITICAL
- **[Finding]**: The V2 Example Contract (§5.3) requires executable scripts that are missing from its `read_paths`.
- **[Why]**: The artifacts in §5.3 run `python3 validate_labels.py triage-report.yaml` and `python3 validate_alerts.py`. However, the contract's `read_paths` only mounts `Domains/career/career-overview.md`. The runner will fail to execute these artifact checks because the Python scripts have not been provided to the staging environment or referenced via absolute vault paths.
- **[Fix]**: Add `_system/scripts/validate_labels.py` and `_system/scripts/validate_alerts.py` to the `read_paths` in the §5.3 example, mirroring how `vault-check.sh` is provided in example §5.1.

### SIGNIFICANT

- **[F3]**
- **[Severity]**: SIGNIFICANT
- **[Finding]**: Schema Completeness — Missing execution environment/credential constraints for side-effecting tasks.
- **[Why]**: The schema declares side-effects like `gmail_label` and `send_telegram`, but there is no field to specify required environment variables, secrets, or system permissions. Without this, it is unclear how the executor is granted the authorization to perform these external communications, or how the runner validates that the executor has the correct context before dispatching.
- **[Fix]**: Introduce a `required_secrets` or `env_permissions` list field to the ROUTING METADATA section, or explicitly document that credential management is fully abstracted to the routing table and handled outside the contract YAML.

- **[F4]**
- **[Severity]**: SIGNIFICANT
- **[Finding]**: Ambiguous state machine semantics regarding V3 Quality Retry routing (§2.3).
- **[Why]**: The document states that if a V3 contract has remaining `quality_retry_budget`, a quality failure transitions the contract from `QUALITY_FAILED` → `ESCALATED` "allowing a re-attempt". Typically, `ESCALATED` implies a state requiring human or orchestrator intervention (as noted in §6.1). If this is an automatic programmatic retry, routing to `QUEUED` or `DISPATCHED` is the standard state machine pattern. Using `ESCALATED` for a standard retry loop creates a semantic overload.
- **[Fix]**: Clarify if `ESCALATED` automatically triggers a programmatic re-dispatch via Tess, or change the transition to `QUALITY_FAILED` → `QUEUED` (with incremented metadata) to preserve `ESCALATED` strictly for budget exhaustion or confidence failures.

- **[F5]**
- **[Severity]**: SIGNIFICANT
- **[Finding]**: UNVERIFIABLE CLAIM: Internal tracking codes, documentation references, and issue numbers.
- **[Why]**: The document frequently relies on specific internal identifiers to justify design decisions, which cannot be independently verified or validated by an external reviewer.
- **[Fix]**: Ensure the following referenced documents/issues exist and accurately contain the cited constraints: `TV2-019`, `TV2-017`, `TV2-018`, `TV2-023`, `TV2-021a`, `TV2-033`, `TV2-037`, `TV2-036`, `AD-007`, `AD-008`, and `Amendments T/U/V/W/X`.

- **[F6]**
- **[Severity]**: SIGNIFICANT
- **[Finding]**: UNVERIFIABLE CLAIM: Claude Code CLI software feature referenced in §6.3.
- **[Why]**: The document claims: "the contract YAML is passed as part of the system prompt to `claude --print`." It is currently unverifiable if the Anthropic `claude` CLI strictly supports `--print` in the exact manner described for prompt ingestion without side-effects.
- **[Fix]**: Verify the exact CLI flags supported by the Claude Code binary for headless/system-prompt injection. 

### MINOR

- **[F7]**
- **[Severity]**: MINOR
- **[Finding]**: Validation tooling does not check `task_id` and `contract_id` string relationship.
- **[Why]**: Section 1.1 states the `contract_id` format is strictly `{task-id}-C{sequence}`. However, Section 4.1 (Validation Tooling) does not list validating this string prefix relationship among its cross-field consistency checks.
- **[Fix]**: Add a validation rule in §4.1.5: "`contract_id` string must begin with `task_id`."

- **[F8]**
- **[Severity]**: MINOR
- **[Finding]**: No defined timeout for artifact verification shell commands.
- **[Why]**: The contract has a global `timeout` for the executor heartbeat, but `artifacts[].verification` uses arbitrary shell commands executed by the runner. A malformed `grep` or `python` script could hang the runner loop indefinitely.
- **[Fix]**: Document a default mechanical timeout (e.g., 30 seconds) for all commands executed by the runner during the `iteration_checking` sub-state.

### STRENGTH

- **[F9]**
- **[Severity]**: STRENGTH
- **[Finding]**: The conceptual separation of Blocking (Mechanical) vs. Advisory (Judgment) semantics is excellent.
- **[Why]**: Splitting loop termination (tests/artifacts evaluated by the runner) from promotion validation (quality checks evaluated by the Tess orchestrator) cleanly solves the evaluator-executor bottleneck (AD-007). It prevents the LLM from getting stuck in an infinite loop waiting on a secondary LLM to grade its work, while still gating vault writes.

- **[F10]**
- **[Severity]**: STRENGTH
- **[Finding]**: Strategic placement of the Lenient Parsing Layer (§4.3).
- **[Why]**: Explicitly distinguishing between the strictly-validated human/orchestrator-authored YAML and the leniently-parsed LLM JSON/YAML output demonstrates a highly mature understanding of autonomous agent failure modes. This will prevent a significant percentage of fragile formatting errors.

---

## DeepSeek (deepseek-reasoner)

**FAILED:** Response body empty due to curl timeout (120s). HTTP headers returned 200 but body transfer was truncated. The reasoning model likely exceeded the timeout during its internal chain-of-thought processing. Consider increasing `curl_timeout` to 180s for DeepSeek or retrying.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: CRITICAL
- [Finding]: The `partial_promotion: "promote_passing"` policy description claims "artifacts that individually passed [quality checks] are promoted," but `quality_checks` are holistic (not tied to specific artifacts via IDs or paths) and evaluated by "tess" post-termination. There is no mechanism defined for "individual" artifact-level quality passing.
- [Why]: Breaks promotion semantics; creates undefined behavior where the policy cannot be implemented without assuming unspecified per-artifact quality mapping. Contradicts evaluator-executor separation (§2.2) since quality is contract-level judgment.
- [Fix]: Either tie `quality_checks[].id` to specific `artifacts[].id` (add required `artifact_id` field to quality_checks), or revise policy to "all artifacts promoted only if all quality_checks pass" (remove "individually"). Update §2.3 table and examples.

- [F2]
- [Severity]: CRITICAL
- [Finding]: `quality_retry_budget > 0` triggers re-dispatch from QUALITY_FAILED → ESCALATED for V3 contracts, but ESCALATED normally invokes escalation gates (e.g., higher tier via min_tier, notifications to `escalation` target). No distinction for "quality retry" vs true escalation; Ralph loop retry_budget is separate from quality_retry_budget.
- [Why]: Risks conflating execution failures (Ralph loop) with post-execution quality failures, potentially wasting retry_budget on quality redispatch or escalating unnecessarily (e.g., to "danny"). Undermines §2.3 V3 path and state machine cross-refs (§6.1).
- [Fix]: Introduce separate `QUALITY_RETRY` state (not ESCALATED) that bypasses gates and directly Ralph-loops with quality failure_context. Decrement quality_retry_budget in state machine (TV2-017). Update `convergence_record.escalated` to exclude quality retries.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: Executor return envelope includes self-reported `test_results`, `confidence`, etc., but runner mechanically re-verifies `tests`/`artifacts`. No handling for executor-runner mismatch (e.g., executor claims "pass" but runner fails).
- [Why]: Invites unreliable self-assessment from LLMs (tier1/3), undermining blocking termination checks (§2.1). Executor could terminate prematurely on false self-pass, bypassing runner verification.
- [Fix]: Remove `test_results` from envelope (runner computes it). Keep `confidence`/`failure_summary` for gates but flag as advisory. Document runner override rule explicitly in §1.4.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: `convergence_record` is listed in schema YAML (§1.1) as "system-managed... read-only," but examples omit it entirely. Validator (§4) has no explicit handling for its presence/absence.
- [Why]: Violates closed schema (§1.1 Amendment V); malformed contracts with partial `convergence_record` could load but fail runtime (Gate 4 §6.2). Inconsistent with "not authored" claim.
- [Fix]: Mark as computed (exclude from YAML schema entirely, like `termination_condition`). Populate post-terminal in runner. Validator: reject if present.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: No cross-field validation for `quality_checks` presence when `quality_retry_budget > 0` or `verifiability: V3`; validator lists "quality_checks present when quality_retry_budget > 0" but only as example constraint.
- [Why]: Allows invalid V3 contracts with retries but no quality_checks to evaluate, causing infinite QUALITY_EVAL loops or undefined failures (§2.3).
- [Fix]: Mandate in §4.1: error if `quality_retry_budget > 0` and `quality_checks: []` or absent. Tie to `convergence_mode: fixed`.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: `min_tier` constrained to "Integer (1|3)", but `executor_target` includes `claude-code` (not 1/3). Re-entry routing (§1.1) assumes numeric tiers.
- [Why]: claude-code overrides could set `min_tier: null` but fail Gate 1 re-entry logic. Breaks routing consistency (§6.1).
- [Fix]: Extend `min_tier` enum to "1|3|claude-code" or make claude-code map to tier3. Clarify mapping in routing table (TV2-021a).

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Validator (§4.1) performs type/enum checks but omits documented constraints like `description <=120 chars`, `retry_budget >=1`, `staging_path` exact format `_staging/{contract_id}/`.
- [Why]: Allows invalid contracts to load (e.g., oversized description bloats prompts §6.3 Layer 4), violating "all required fields enumerated" (§1.1).
- [Fix]: Add to §4.1: length checks (description), range checks (retry_budget >=1), regex checks (staging_path, contract_id). Update output format examples.

- [F8]
- [Severity]: MINOR
- [Finding]: Examples inconsistently use `params` in `tests`: §1.2 requires `params` for some types (e.g., `command_exit_zero`), but schema snippet (§1.1) shows empty `params: {}` without noting type-specific reqs.
- [Why]: Minor doc ambiguity; implementers might miss that `path` is optional for non-file tests.
- [Fix]: In §1.1 schema, annotate `params` as "Type-specific (see §1.2)". Add table row for `params` requirements.

- [F9]
- [Severity]: MINOR
- [Finding]: No example for `priority: deferred` + `defer_until`, `executor_target: claude-code`, or `quality_retry_budget: 1` mid-flow.
- [Why]: Examples (§5) claim to "exercise the schema" but skip edge cases, reducing utility for testing (§6 cross-refs).
- [Fix]: Add 5.4 Deferred/Claude example. Simulate quality retry in 5.2 notes.

- [F10]
- [Severity]: MINOR
- [Finding]: Appendix §7 table lists `quality_retry_budget` as "no" required (correct), but schema (§1.1) marks "Optional... Default: 0" without cross-field V3 constraint repeated.
- [Why]: Readers miss V1/V2 must-be-0 rule (§1.1 comment).
- [Fix]: Add "V1/V2: must 0" to table. Link to §4.1 cross-checks.

- [F11]
- [Severity]: STRENGTH
- [Finding]: Cross-reference tables (§6.1-6.3) comprehensively map every schema field to consuming components without gaps or duplicates.
- [Why]: Enables traceability across artifacts (TV2-017/018/023); no orphan fields or unhandled states.
- [Fix]: N/A

- [F12]
- [Severity]: STRENGTH
- [Finding]: Version strategy (§3) with semver, additive MINOR, migration script, and MAJOR support window is robust and implementable.
- [Why]: Handles evolution predictably; forward/backward compat rules prevent runtime surprises (e.g., unknown fields ignored with warn).
- [Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. Closed schema vs forward compatibility contradiction** (OAI-F1, GEM-F1)
§4.1 says reject unknown fields. §3.3 says ignore unknown optional fields on newer MINOR versions. These can't both be true. Fix: version-aware carve-out — unknown fields rejected when versions match, warned-and-stripped when contract MINOR > validator MINOR.

**2. `promote_passing` without per-artifact quality mapping** (OAI-F8/F9, GRK-F1)
Quality checks are contract-level, but `promote_passing` requires knowing which artifacts "individually passed." No mapping exists. Fix: either add `artifact_id` to quality_checks, or redefine `promote_passing` as "all artifacts promoted when quality passes on the promoted subset."

**3. `min_tier` vs `executor_target` type mismatch** (OAI-F3/F16, GRK-F6)
`executor_target` is enum (tier1/tier3/claude-code), `min_tier` is integer (1|3). `claude-code` doesn't map to a numeric tier. Fix: normalize to same domain or define explicit mapping.

**4. System-managed fields in authored schema** (OAI-F2, GRK-F4)
`convergence_record` and `min_tier` appear in the schema but are "not authored" / "system-managed." Validator behavior unclear. Fix: split into authored contract schema vs runtime-enriched record schema. Reject system-managed fields in authored YAML.

**5. Quality retry routes through ESCALATED** (GEM-F4, GRK-F2)
V3 quality failures → ESCALATED → re-dispatch. But ESCALATED implies tier change / human involvement. Fix: clarify that quality retry is a programmatic re-dispatch, not a true escalation. Consider dedicated QUALITY_RETRY transition.

**6. Example correctness issues** (OAI-F5/F6, GEM-F2)
V1 example uses `yaml_parseable` on a markdown file, `command_exit_zero` with unreachable script path. V2 example references scripts not in `read_paths`. Fix: correct all examples to be executable as written.

### Unique Findings

**OAI-F4 (CRITICAL): Path semantics inconsistent across schema, spec, and examples.** Staging-relative vs vault-relative paths are ambiguous. Genuine — define one canonical rule and fix all references.

**OAI-F10 (SIGNIFICANT): No minimum verification constraint.** Contract with no tests, artifacts, or quality_checks can trivially terminate. Genuine — require at least one test or artifact.

**OAI-F15 (SIGNIFICANT): `requires_human_approval` immutability vs Gate 3 setting it.** If Gate 3 sets it after authoring, that's contract mutation. Genuine — treat as derived routing state, not contract field mutation.

**OAI-F20 (SIGNIFICANT): No explicit output/promotion destination mapping.** Contracts don't declare where staged artifacts promote to. Genuine gap, but may be resolved by service interface definitions (TV2-021b).

**GEM-F3 (SIGNIFICANT): No credential/environment requirements in contract.** Side-effecting contracts don't declare needed secrets. Reasonable — credential management is handled by TV2-024 at dispatch time, not in the contract.

**GRK-F3 (SIGNIFICANT): Executor self-reported `test_results` in return envelope.** Runner re-verifies anyway, so self-report is misleading. Genuine — mark as advisory or remove.

### Contradictions

**Forward compatibility approach:** OAI recommends strict closed schema (Option A). GEM recommends version-aware carve-out. GRK praises the versioning strategy. **Assessment:** GEM's approach is more practical — strict rejection prevents graceful upgrade. Use version-aware validation.

### Action Items

**Must-fix:**

- **A1** (OAI-F1, GEM-F1): Resolve closed schema vs forward compatibility — implement version-aware validation (reject when versions match, warn-and-strip when MINOR is newer).
- **A2** (OAI-F2, GRK-F4): Split schema into authored contract YAML and runtime-enriched record. System-managed fields (`convergence_record`, `min_tier`) rejected in authored YAML.
- **A3** (OAI-F3/F16, GRK-F6): Normalize tier/target typing — define explicit `claude-code` → tier3 mapping, or use consistent enum domain.
- **A4** (OAI-F4): Canonicalize path semantics — staging-relative for tests/artifacts, vault-relative for read_paths. Update all comments and examples.

**Should-fix:**

- **A5** (OAI-F8/F9, GRK-F1): Add per-artifact quality mapping — `quality_checks[].applies_to` or redefine `promote_passing` semantics.
- **A6** (GEM-F4, GRK-F2): Clarify quality retry routing — distinguish from true escalation. Document as programmatic re-dispatch.
- **A7** (OAI-F5/F6, GEM-F2): Fix all example contracts to be executable — correct test types, script paths, read_paths.
- **A8** (OAI-F10): Add minimum verification invariant — at least one test or artifact required.
- **A9** (OAI-F15): Treat `requires_human_approval` as derived routing state, not contract field mutation. Gate 3 writes to envelope, not contract.
- **A10** (OAI-F7): Specify `artifacts[].verification` more precisely — working directory, timeout, allowed interpreters.
- **A11** (OAI-F11): State closed-schema validation applies recursively to all nested authored objects.
- **A12** (OAI-F18): Add retry budget lifecycle subsection — what resets on escalation, quality retry accounting, iterations_used scope.
- **A13** (GRK-F3): Mark executor `test_results` as advisory-only in return envelope. Runner results are authoritative.
- **A14** (GRK-F7, OAI-F14/F19): Expand validation checklist — description length, staging_path format, contract_id prefix, deferred reciprocal rule.

**Defer:**

- **A15** (OAI-F20): Output/promotion destination mapping — deferred to TV2-022 (staging-promotion design) which handles this.
- **A16** (OAI-F24): Return envelope versioning — nice-to-have, add during implementation.
- **A17** (GEM-F3): Credential requirements in contract — handled by TV2-024 at dispatch time.

### Considered and Declined

- **OAI-F32, GEM-F5/F6** (unverifiable cross-references): `constraint` — internal project references are verified by the author, not external reviewers.
- **OAI-F21** (artifact terminology overloaded): `overkill` — renaming would ripple across 10+ design docs. Context makes the distinction clear.
- **OAI-F23** (no `updated` field): `constraint` — contracts are immutable by design. No update timestamp needed.
- **OAI-F26** (validation output redundancy): `overkill` — minor schema noise, not worth changing.
- **GRK-F9** (missing deferred/claude-code example): `overkill` — three examples cover the design space adequately.

- [F13]
- [Severity]: STRENGTH
- [Finding]: Blocking/advisory distinction (§2) clearly tabulated with evaluator/runner separation; edge case V3 retry explicitly called out.
- [Why]: Prevents executor waiting on judgment (AD-007); promotion atomicity documented.
- [Fix]: N/A
