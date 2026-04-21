---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/autonomous-operations/design/action-plan.md
artifact_type: action-plan
artifact_hash: 1aefcfd3
prompt_hash: 0051eeac
base_ref: null
project: autonomous-operations
domain: software
skill_origin: peer-review
created: 2026-03-12
updated: 2026-03-12
status: active
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
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
    latency_ms: 66178
    attempts: 1
    raw_json: Projects/autonomous-operations/reviews/raw/2026-03-12-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 45132
    attempts: 1
    raw_json: Projects/autonomous-operations/reviews/raw/2026-03-12-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 61951
    attempts: 1
    raw_json: Projects/autonomous-operations/reviews/raw/2026-03-12-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 29137
    attempts: 1
    raw_json: Projects/autonomous-operations/reviews/raw/2026-03-12-action-plan-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Autonomous Operations — Phase 1 Action Plan

**Artifact:** Projects/autonomous-operations/design/action-plan.md
**Mode:** full
**Reviewed:** 2026-03-12
**Reviewers:** OpenAI gpt-5.2, Google gemini-3-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning
**Review prompt:** Full review of action plan covering correctness, completeness, internal consistency, feasibility, clarity. Focus areas: AO-002 structured extraction approach, AO-004 vault-change correlation proxy, milestone sequencing, success criteria measurability.

---

## OpenAI (gpt-5.2)

- [F1]
  - [Severity]: STRENGTH
  - [Finding]: Clear milestone structure with sensible layering: schema + structured output → dedup → instrumentation → scoring → evaluation gate.
  - [Why]: This reduces integration risk and keeps “new capabilities” auditable via SQLite and sidecar artifacts before adding more probabilistic behavior (dedup/prompt logic).
  - [Fix]: N/A

- [F2]
  - [Severity]: SIGNIFICANT
  - [Finding]: Success criteria in M1 are partially measurable but not fully specified (what constitutes “accepts inserts/queries”, what tables, what fields; what is “logs each cycle” exactly).
  - [Why]: Without concrete checks, you can “feel done” while missing critical invariants (foreign keys, uniqueness constraints, timestamps, run IDs, error handling).
  - [Fix]: Add explicit acceptance tests:
    - `init-db` creates required tables + indexes + `PRAGMA foreign_keys=ON`.
    - A test run inserts 1 cycle + N items + sidecar JSON hash, then queries them back with counts matching.
    - Define a “cycle_id” and require every item row references it; require non-null timestamp fields.

- [F3]
  - [Severity]: CRITICAL
  - [Finding]: AO-002 Option A (HTML comment markers) is not robust enough as described: naive `grep`-based extraction will fail under common model deviations (wrapped lines, multiple markers, whitespace changes, accidental Markdown code fencing, partial JSON, escaping issues).
  - [Why]: If the sidecar JSON is malformed or incomplete, downstream logging/dedup/scoring will quietly degrade or crash; Phase 1 depends on reliable parsing.
  - [Fix]: Make the extraction contract stricter and the parser more defensive:
    - Use **one single JSON blob** per response (either at end or fenced) *plus* stable delimiters, e.g.:
      - `<<<ITEMS_JSON_START>>>` newline, then JSON, then `<<<ITEMS_JSON_END>>>`
    - If you keep per-item markers, require **base64-encoded JSON** inside the marker to avoid quoting/newline issues:
      - `<!-- ITEM_B64: eyJvYmplY3RfaWQiOi... -->`
    - Implement validation: parse with `jq -e`; on failure, write raw response + error to a quarantine folder, and **skip logging** rather than logging partial garbage.
    - Add schema validation: required keys (`object_id`, `source_path`, `action_class`, etc.) and allowed enum values.

- [F4]
  - [Severity]: SIGNIFICANT
  - [Finding]: Token budget assumptions are inconsistent: AO-002 mentions “4000 max_tokens ceiling” while AO-003 discusses input token limits “~8000 input tokens”.
  - [Why]: If the chosen model/API has different limits (context window vs output limit), prompt + dedup context may intermittently fail, causing missing artifacts or partial output.
  - [Fix]: Pin explicit model constraints in the plan:
    - Define `MODEL`, `MAX_OUTPUT_TOKENS`, and `MAX_CONTEXT_TOKENS` in config.
    - Add runtime guards: estimate prompt size (rough char→token heuristic) and truncate “recent items” block deterministically (e.g., keep top K by urgency).

- [F5]
  - [Severity]: SIGNIFICANT
  - [Finding]: AO-002 structured format requirements (“Daily artifact includes action_class on every Focus item”) don’t fully specify the taxonomy or validation rules (allowed classes, defaults, what happens if missing).
  - [Why]: Inconsistent classes break scoring aggregation and dedup logic; missing classes force ad-hoc handling.
  - [Fix]: Define:
    - Allowed `action_class` enum (e.g., `do`, `decide`, `plan`, `track`, `review`, `wait`, etc.).
    - Fallback rule: if absent, set `action_class="unknown"` and mark `parse_warnings`.
    - Reject/flag items missing `object_id` or `source_path`.

- [F6]
  - [Severity]: SIGNIFICANT
  - [Finding]: AO-001 schema description references “follow dashboard_actions SQLite approach” but doesn’t enumerate required tables/indices beyond mentioning an alias table.
  - [Why]: Later tasks assume specific query patterns (lookback by cycle, unresolved items, action logging). If the schema isn’t designed for those access patterns, you’ll rewrite it midstream.
  - [Fix]: Add a minimal schema spec in the action plan:
    - `cycles(cycle_id, ts, artifact_path, sidecar_path, prompt_hash, model, input_tokens, output_tokens, status, error)`
    - `items(item_id, cycle_id, object_id, source_path, title, action_class, urgency, raw_text_span, json, created_ts)`
    - `aliases(old_id, new_id, created_ts)`
    - `actions(item_id, action_type, action_source, action_ts, details_json)`
    - Indexes on `(cycle_id)`, `(object_id)`, `(source_path)`, `(action_type)`.

- [F7]
  - [Severity]: CRITICAL
  - [Finding]: AO-003 “Zero duplicate items for the same object in a single cycle” requires a stable definition of identity, but the plan mixes “path-based identity” and “object_ids” without specifying how object_id is derived and normalized.
  - [Why]: If identity isn’t deterministic (case sensitivity, relative vs absolute paths, renamed files, aliases), dedup will either fail or over-merge unrelated items.
  - [Fix]: Define identity rules:
    - Canonical `source_path` normalization (vault-relative, normalized separators, case rules).
    - `object_id` derivation (e.g., `sha1("path:" + canonical_path)`), and when it changes.
    - Aliases apply to canonical paths; `resolve_id()` must be applied consistently both pre- and post-processing.
    - Add a UNIQUE constraint: `(cycle_id, object_id)` to enforce no duplicates at DB level (and handle conflicts via merge/replace).

- [F8]
  - [Severity]: SIGNIFICANT
  - [Finding]: AO-003 pre-processing “recently surfaced items” prompt block is underspecified: what fields are shown, how many, and how to avoid leaking too much context/noise into the model.
  - [Why]: Overlong or low-signal context will reduce model quality and increase token use; under-specified summaries reduce dedup effectiveness.
  - [Fix]: Define a compact template and deterministic cap, e.g.:
    - For last 2–3 cycles, include top 10–20 items with fields: `object_id`, `title`, `source_path`, `last_seen_ts`, `last_urgency`, `last_action_class`, `status`.
    - Summarize as JSON (not prose) to reduce ambiguity.

- [F9]
  - [Severity]: SIGNIFICANT
  - [Finding]: AO-003 post-processing “merge or flag” lacks a concrete merge policy (which title wins, how urgency combines, what gets logged).
  - [Why]: Without deterministic rules, duplicates could create unstable outputs and make the system hard to trust.
  - [Fix]: Implement deterministic resolution:
    - Prefer the item with richer fields; merge notes arrays; choose max urgency; concatenate rationale.
    - Log a `dedup_event` row with both item payloads for auditability.

- [F10]
  - [Severity]: SIGNIFICANT
  - [Finding]: AO-004 correlation pseudo-code implies querying “items where action_type IS NULL”, but action_type is typically in a separate actions table; also “window_end” calculation and timestamp comparisons are ambiguous.
  - [Why]: This can lead to never-closing windows, double-logging, or misclassifying items.
  - [Fix]: Make correlation idempotent:
    - Only process items with no existing `actions.action_type` from `vault_change_correlation`.
    - Store `correlation_checked_ts` on item or in a separate table.
    - Define time window precisely: `window_end = cycle_ts + window_duration`; run when `now >= window_end`.

- [F11]
  - [Severity]: SIGNIFICANT
  - [Finding]: AO-004 relies on `git log --since --until -- source_path` which only works if:
    1) the vault is a git repo,
    2) changes are committed within the window,
    3) the file existed at that path,
    4) rename detection is handled.
  - [Why]: Many workflows have uncommitted edits, delayed commits, or edits across multiple files; correlation would be systematically wrong.
  - [Fix]: Keep git-based correlation but add lightweight alternatives that still fit bash+SQLite:
    - Prefer **filesystem mtime** check as a secondary signal: `stat -f %m source_path` (macOS) or `stat -c %Y` (Linux) compared to window.
    - Consider `git status --porcelain` and/or scanning reflog is not reliable; but you can detect uncommitted changes by checking if the file is modified in working tree at correlation time.
    - Track “vault activity” generally: any change in same folder prefix could count as weak evidence (with lower weight).
    - Record `signal_strength` (strong=committed change to file; medium=mtime change; weak=folder activity).

- [F12]
  - [Severity]: MINOR
  - [Finding]: AO-004 “Schedule: daily at 11 PM via LaunchAgent, or manual invocation” is slightly inconsistent with earlier “daily cron job” framing.
  - [Why]: Two schedulers can cause double-runs or confusion about canonical runtime.
  - [Fix]: Specify one scheduler of record (cron vs LaunchAgent) and ensure locking (e.g., `flock` or PID file) to prevent concurrent execution.

- [F13]
  - [Severity]: SIGNIFICANT
  - [Finding]: AO-005 says “five SQL queries… operational definitions already in the spec’s exit criteria table” but the plan does not restate them or map each metric to specific fields/tables.
  - [Why]: If the schema evolves, you may discover the required fields weren’t collected (e.g., false-positive rate needs a ground-truth label).
  - [Fix]: In the action plan, add a metric-to-data dependency table:
    - Metric name → SQL sketch → required columns → where populated (AO-002 parse, AO-004 correlation, manual label?).
    - Clarify how “false-positive rate” is computed (what is “positive”, what is ground truth).

- [F14]
  - [Severity]: CRITICAL
  - [Finding]: The plan references “False-positive rate >40%” in evaluation responses, but Phase 1 as written does not define a reliable ground-truth mechanism to label false positives vs true positives.
  - [Why]: Without labeling, “false-positive rate” becomes guesswork, undermining the evaluation gate.
  - [Fix]: Add an explicit lightweight labeling pathway:
    - Manual review script to label a sample of items (`true_positive/false_positive/unclear`) stored in SQLite.
    - Or infer “false positive” only when explicitly dismissed (requires a dismiss action mechanism), otherwise treat as “unknown”.

- [F15]
  - [Severity]: SIGNIFICANT
  - [Finding]: Error handling and observability are not specified (API failures, parse failures, DB lock/corruption, partial writes).
  - [Why]: Cron systems fail silently; without robust logging you’ll get replay gaps and unreliable metrics.
  - [Fix]: Add:
    - A run-level log file per cycle, and DB `cycles.status` fields (`ok`, `api_error`, `parse_error`, `db_error`).
    - Atomic writes: write artifact/sidecar to temp then rename; DB inserts in a transaction.
    - Notifications on failure (even just writing to an “inbox” note in the vault).

- [F16]
  - [Severity]: STRENGTH
  - [Finding]: The evaluation period as an explicit gate (14 days post-deploy) is well-framed and aligns with collecting enough data for meaningful metrics.
  - [Why]: Prevents premature optimization and forces real-world validation.
  - [Fix]: N/A

- [F17]
  - [Severity]: SIGNIFICANT
  - [Finding]: Dependency assumptions are mostly right (AO-003 depends on AO-001+AO-002; AO-004/5 depend on AO-001), but AO-004 also implicitly depends on stable identity/dedup outputs to avoid misattributing actions.
  - [Why]: If item identity changes frequently (renames, inconsistent object_id), correlation and scoring will be noisy.
  - [Fix]: Treat “identity stability” as an explicit prerequisite: complete AO-003 (or at least finalize object_id rules + alias handling) before declaring AO-004 “done”.

- [F18]
  - [Severity]: MINOR
  - [Finding]: The plan mentions “2-3 live runs before declaring stable” for AO-002; given probabilistic formatting, that may be insufficient to expose edge cases.
  - [Why]: Formatting failures can be rare but catastrophic (break pipeline).
  - [Fix]: Run a small test harness: replay the prompt against stored historical inputs (or synthetic cases) and measure parse success rate over, say, 30–50 runs.

- [F19]
  - [Severity]: SIGNIFICANT
  - [Finding]: Sidecar JSON generation is described, but the contract between artifact text and sidecar is unclear (how to map Focus item text spans to JSON entries; whether sidecar is source of truth).
  - [Why]: Without a clear source of truth, later debugging and audits (“why did this item appear?”) become hard.
  - [Fix]: Define:
    - Sidecar as source of truth for structured operations.
    - Include `artifact_line_start/end` or a stable `item_anchor` ID injected into the Markdown (e.g., `^item-abc123`) and referenced in JSON.

- [F20]
  - [Severity]: SIGNIFICANT
  - [Finding]: “Zero duplicate items for the same object in a single cycle” is measurable, but “Items recurring across days show rising urgency, not fresh entries” is subjective unless operationalized.
  - [Why]: You can’t reliably pass/fail M2 without measurable criteria.
  - [Fix]: Operationalize, e.g.:
    - If an object_id appears in consecutive cycles and not acted-on, then urgency must be non-decreasing (or must include `recurrence_count`).
    - Track `first_seen_ts`, `last_seen_ts`, `times_seen`, `last_urgency`.

- [F21]
  - [Severity]: MINOR
  - [Finding]: The plan would benefit from specifying concrete file names/entrypoints for each task (scripts, library functions).
  - [Why]: Reduces implementation ambiguity and makes work chunking easier.
  - [Fix]: Add a per-AO checklist: files to touch, functions to create, CLI usage examples.

- [F22]
  - [Severity]: SIGNIFICANT
  - [Finding]: Option B (“separate JSON block at the end”) is described as token-expensive and risky, but it is often *more* robust than scattered per-item markers if you enforce strict delimiters and a JSON schema.
  - [Why]: Reliability of parsing is typically more valuable than marginal token savings, especially early.
  - [Fix]: Re-rank: make “single delimited JSON block” the preferred approach; keep markers as optional redundancy (e.g., include item anchors in Markdown, but parse only the JSON block).

### Additional focus area responses (targeted)

1) **AO-002 markers robustness / edge cases**
- Biggest risks: malformed JSON, missing markers, duplicated markers, Markdown rendering altering HTML comments, model placing markers inside code blocks, line wrapping, escaping quotes, truncation at output limit.
- Best mitigation: strict start/end delimiters + single JSON blob + `jq -e` validation + quarantine on failure.

2) **AO-004 correlation proxy quality**
- Git commits to `source_path` are a *sound but narrow* proxy; it will undercount action in common workflows.
- Better lightweight alternatives (bash+SQLite compliant): combine signals (git commit, filesystem mtime, working-tree modified, directory-level activity) and store a confidence score rather than a binary label.

3) **Sequencing soundness**
- Mostly sound. The key adjustment: finalize identity rules (AO-003 core pieces) before trusting AO-004/5 metrics.

4) **Are success criteria sufficient/measurable?**
- Partially. Many need operational definitions (dedup behavior across days, false-positive rate ground truth, correlation idempotence).

### Unverifiable claims (flagged per instruction)

- [F23]
  - [Severity]: SIGNIFICANT
  - [Finding]: UNVERIFIABLE CLAIM: References to “dashboard_actions SQLite approach” and “same cron-lib.sh infrastructure” and the file `_system/docs/solutions/gate-evaluation-pattern.md` are not independently verifiable from the provided artifact.
  - [Why]: These dependencies may not exist or may differ, affecting feasibility and implementation details.
  - [Fix]: Link or summarize the referenced patterns within the repo/action plan (or restate the minimal required behaviors they provide).

---

## Google (gemini-3-pro-preview)

Here is a structured review of the Phase 1 Action Plan for the autonomous-operations project.

### Overall Assessment
The action plan is highly pragmatic, outlining a well-scoped approach to bootstrapping an autonomous review system. The phased rollout, parallel development tracks, and dedicated 14-day evaluation gate show mature engineering planning. The intentional acceptance of false-negative biases for early quality proxies is a particularly strong architectural decision. However, the plan relies on risky Bash/regex parsing for LLM outputs and carries some blind spots regarding file tracking and database concurrency.

---

### Findings

- **[F1]**
- **Severity**: STRENGTH
- **Finding**: Acceptance of the false-negative bias in AO-004's correlation logic.
- **Why**: Recognizing that modifying a distinct file (like `project-state.yaml` instead of the spec) will result in a missed correlation is excellent engineering pragmatism. For a Phase 1 scoring metric, a proxy that undercounts success is much safer than one that overcounts it, as it prevents artificially inflating system performance during evaluation. 

- **[F2]**
- **Severity**: CRITICAL
- **Finding**: AO-002 Option A (HTML comments) extracted via Bash/grep is highly brittle for JSON payloads.
- **Why**: `grep` is fundamentally line-oriented. If the LLM generates the JSON object formatted with newlines and indentation (which is standard behavior unless heavily penalized), standard `grep` will fail to capture the entire object. Furthermore, embedded JSON inside HTML comments is prone to escaping errors by the LLM (e.g., using `-->` inside a JSON string value). 
- **Fix**: Pivot to Option B (a fenced ````json` block at the end) as the primary approach. It is vastly easier to extract reliably using `sed -n '/^```json/,/^```/p'` and pipe to `jq`. If you must use Option A, mandate strict single-line JSON formatting in the prompt and use `jq` to validate the extraction immediately before writing the sidecar.

- **[F3]**
- **Severity**: SIGNIFICANT
- **Finding**: UNVERIFIABLE CLAIM: Reliance on existing infrastructure patterns (`dashboard_actions`, `cron-lib.sh`, `attention-lib.sh`) and specific documentation (`_system/docs/solutions/gate-evaluation-pattern.md`).
- **Why**: The plan assumes these local scripts, schema patterns, and evaluation frameworks exist, are bug-free, and are compatible with the new pipeline. I cannot independently verify their contents or stability.
- **Fix**: Ensure these internal dependencies are fully audited for compatibility before beginning M1, particularly how `cron-lib.sh` handles environment variables and logging.

- **[F4]**
- **Severity**: SIGNIFICANT
- **Finding**: AO-004 `git log` correlation logic does not track file renames or handle uncommitted changes.
- **Why**: Using `git log -- source_path` will fail if the user renames or moves the file during the 48h/7d window (a common action in Obsidian vaults). Additionally, if the daily LaunchAgent runs at 11 PM but the vault hasn't auto-committed since the user made changes, those changes are invisible to `git log` and could be missed entirely if the window closes before the next run.
- **Fix**: Add the `--follow` flag to the git command (`git log --follow --since=...`). To address uncommitted changes, either force a `git add/commit` prior to the AO-004 run, or use the filesystem modification time (`mtime`) as a secondary check if `git log` returns empty.

- **[F5]**
- **Severity**: SIGNIFICANT
- **Finding**: M1 Success criteria lacks structural validation for the sidecar JSON.
- **Why**: The criteria states "Sidecar JSON file produced", but if the JSON is malformed, downstream tasks (AO-003 dedup, AO-004 correlation) will fail. Emitting a file is not enough; emitting *valid* data is required.
- **Fix**: Update the M1 success criteria to include: "Sidecar JSON successfully parses via `jq` and conforms to expected keys (object_id, action_class, etc.)."

- **[F6]**
- **Severity**: SIGNIFICANT
- **Finding**: Context poisoning risk in AO-003 deduplication.
- **Why**: Injecting the last 3 cycles of JSON items into the prompt without tool calling introduces a risk that the model will hallucinate and regurgitate old items verbatim rather than processing the current data.
- **Fix**: Use strict XML separation (e.g., `<historical_context>`) for the past 3 cycles and heavily emphasize in the prompt instructions that historical items are for *reference only* and should not be blindly copied into the new JSON output.

- **[F7]**
- **Severity**: MINOR
- **Finding**: Unaddressed concurrency risk between daily artifact generation and AO-004 LaunchAgent.
- **Why**: If the daily attention generation (`daily-attention.sh`) and the correlation script (AO-004) both run at "11 PM", they may attempt to access/write to `attention-replay.db` simultaneously. While SQLite supports concurrent reads, simultaneous writes from disparate bash processes can trigger "database is locked" errors.
- **Fix**: Explicitly stagger the cron schedules (e.g., artifact generation at 11:00 PM, correlation at 11:30 PM) or wrap SQLite calls in a bash retry-loop with random jitter.

- **[F8]**
- **Severity**: MINOR
- **Finding**: AO-005 testing is blocked by AO-004 execution, despite parallel sequencing.
- **Why**: The sequencing summary shows AO-004 and AO-005 running in parallel during Week 2. While code *authoring* can be parallel, AO-005 relies on the `action_type` column populated by AO-004 to calculate the exit metrics. 
- **Fix**: Explicitly note in the plan that a mock dataset representing AO-004's output should be generated early in Week 2 to unblock the testing of AO-005's SQL queries.

### Responses to Specific Focus Areas

1. **AO-002 structured extraction (Option A vs B):** Option A is highly risky for bash post-processing (see Finding F2). Fenced blocks (Option B) are the industry standard for LLMs operating without tool use because they cleanly delineate human-readable markdown from structured data and are trivial to extract with standard CLI tools.
2. **AO-004 vault-change correlation:** Using `git log` is a clever, zero-dependency proxy for action, but it requires refinement (see Finding F4). Using filesystem modification times (`find /vault -path "*/source_path" -mtime -2`) is a lightweight alternative that bypasses git entirely and catches uncommitted changes, though it loses git's exact timestamps.
3. **Milestone sequencing:** The dependency assumptions are generally correct, but testing dependencies between AO-004 and AO-005 are slightly misaligned (see Finding F8).
4. **Success criteria:** The criteria are measurable but lack strict validation gates for data integrity, particularly for JSON generation in M1 (see Finding F5).

---

## DeepSeek (deepseek-reasoner)

- **F1**
- **Severity**: SIGNIFICANT
- **Finding**: AO-002's structured extraction "Option A" (HTML comment markers) is potentially fragile. The LLM may produce malformed JSON, omit markers, or place them incorrectly (e.g., not after each Focus item). Edge cases include escaped characters in JSON breaking grep parsing, or the model "reasoning" about the format within the output itself.
- **Why**: This is a core data extraction mechanism. Failure leads to missing sidecar JSON, broken logging (AO-001 integration), and corrupted deduplication (AO-003).
- **Fix**: Implement a defensive post-processing script: 1) Use a robust regex or a dedicated JSON parser (e.g., `jq`) to find and extract marker content. 2) Add validation for JSON schema and mandatory fields (e.g., `object_id`). 3) Implement a fallback to "Option B" parsing if no valid markers are found, with a warning log.

- **F2**
- **Severity**: SIGNIFICANT
- **Finding**: AO-004's correlation logic (git log changes to `source_path`) is a highly specific proxy for "acted on." It will systematically miss many action types: actions on directories (not a single file), actions in external systems (email, web), document edits outside the vault, or actions that don't produce a git commit.
- **Why**: While the plan acknowledges a false-negative bias, the signal may be so weak for certain domains (e.g., "career") that the quality metric becomes noisy or meaningless. The 48h/7d window choice seems arbitrary without justification.
- **Fix**: Document the expected coverage per domain (e.g., high for `software` source code, low for `career` advice). Consider expanding the correlation to include file modifications (`find -newer`) in the same directory, not just git commits. Accept that for Phase 1, this is a prototype signal.

- **F3**
- **Severity**: MINOR
- **Finding**: Milestone M2 (AO-003) success criterion "Items recurring across days show rising urgency, not fresh entries" is not objectively measurable. "Rising urgency" is a qualitative prompt instruction, not a system output.
- **Why**: Success cannot be automatically validated. It relies on human review of artifact text.
- **Fix**: Reframe the success criterion to be mechanically verifiable: e.g., "For items with a prior `object_id`, the system logs them with an `is_recurrence` flag and the new prompt context includes prior items' metadata."

- **F4**
- **Severity**: SIGNIFICANT
- **Finding**: The sequencing shows AO-003 (Deduplication) starting before AO-002 is fully integrated ("AO-002 ═══╬══ AO-003"). However, AO-003's pre-processing requires querying the replay log populated by AO-001/AO-002 integration. This dependency is not explicitly called out.
- **Why**: Implementing AO-003 before the integration step (logging parsed items) would result in an empty "Recently surfaced items" context block, making initial dedup testing ineffective.
- **Fix**: Clarify the sequence: AO-001 and AO-002 can be parallel, but their **integration step** (logging items) must be complete **before** AO-003 implementation begins.

- **F5**
- **Severity**: STRENGTH
- **Finding**: The plan demonstrates strong pragmatic risk management. Examples: dry-run testing for token limits (AO-002), accepting safe-direction bias in correlation (AO-004), a structured 14-day evaluation gate with targeted responses for failure modes (M4).
- **Why**: This increases the likelihood of successful deployment and provides clear off-ramps for iteration.
- **Fix**: N/A

- **F6**
- **Severity**: SIGNIFICANT
- **UNVERIFIABLE CLAIM**: The plan references following the "dashboard_actions SQLite approach (same machine, same cron-lib.sh infrastructure)" and a gate evaluation pattern in `_system/docs/solutions/gate-evaluation-pattern.md`.
- **Why**: The reviewer cannot verify the existence, stability, or suitability of these referenced internal assets. If they are unstable or non-existent, the implementation foundation is at risk.
- **Fix**: Recommend the author confirm these assets are stable and document any key assumptions they embody for this new project.

- **F7**
- **Severity**: MINOR
- **Finding**: The "Success criteria" for M1 includes "Daily artifact includes action_class on every Focus item". This is an output of the AO-002 prompt, but there's no validation step mentioned to ensure 100% coverage.
- **Why**: A single missing `action_class` could break downstream filtering or scoring logic.
- **Fix**: Add a post-processing check in the AO-002 pipeline: if any parsed Focus item lacks an `action_class`, log a warning and assign a default (e.g., "review").

- **F8**
- **Severity**: SIGNIFICANT
- **Finding**: The AO-003 deduplication pre-processing injects a "Recently surfaced items" context block. The plan warns of token inflation but only suggests reducing the lookback window. It does not consider truncating or summarizing the context of each prior item.
- **Why**: Simply reducing the window may weaken deduplication. A summary strategy (e.g., just `object_id` and `title`) could preserve a longer lookback within token limits.
- **Fix**: Propose implementing a `format_dedup_context` function that creates a concise, token-efficient summary of recent items (ID + one-line context) as part of the initial implementation.

- **F9**
- **Severity**: STRENGTH
- **Finding**: The plan has high internal consistency. The exit metrics (AO-005) directly tie back to the success criteria and operational definitions mentioned earlier. The components (SQLite schema, logging, correlation) clearly interconnect.
- **Why**: This consistency reduces the risk of building disjointed features and ensures the evaluation period (M4) tests the integrated system as intended.
- **Fix**: N/A

- **F10**
- **Severity**: MINOR
- **Finding**: The scheduling for AO-004 (correlation) is noted as "daily at 11 PM via LaunchAgent, or manual invocation." This introduces a second scheduled job (besides the main daily attention cron), increasing operational complexity.
- **Why**: An extra scheduled job is a point of failure (permissions, environment, conflicts). If it fails silently, scoring data will be missing.
- **Fix**: Consider folding the correlation logic into the **post-processing stage of the main daily cron job**, running it for items whose evaluation window has just closed based on `cycle_timestamp`. This simplifies scheduling to a single daily process.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: AO-002 structured extraction (Option A) relies on grep-post-processing of HTML comments like `<!-- ITEM_JSON: {...} -->`, but lacks robustness checks for LLM non-compliance, such as malformed JSON, inconsistent placement (e.g., markers before/after wrong items, nested comments, or missing entirely), escaped characters in JSON, or prompt hallucination inserting fake markers.
- [Why]: LLMs are probabilistic and often deviate from exact formats (especially without tools), risking parsing failures that silently drop items, corrupt the sidecar JSON, or halt post-processing — breaking the core logging loop and making artifacts unreliable for evaluation.
- [Fix]: Add JSON validation (e.g., `jq --exit-status`) after grep extraction; if fails/missing, fallback to Option B or log error and skip logging. Test with 5-10 adversarial prompts simulating edge cases (e.g., "output without markers").

- [F2]
- [Severity]: CRITICAL
- [Finding]: No handling for API failures, token limit excedences (output or input), rate limits, or network errors in daily cron runs; `--dry-run` mentioned for testing but not for production.
- [Why]: Cron jobs must be resilient — a single failure (common with APIs) skips artifact generation/logging entirely, creating replay gaps and failing M1/M4 success criteria without alerting.
- [Fix]: Wrap API call in retry loop (3x with exp backoff), add error logging to SQLite/email, and produce a fallback "degraded" artifact (e.g., prior day's replay). Monitor via cron output.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: Token budgets referenced as "4000 max_tokens ceiling" (output) and "~8000 input tokens" lack context (e.g., model/version limits); adding dedup context risks unspecified input limits.
- [Why]: Unverifiable claims risk over-optimism; if using Anthropic models, input can hit 128k+ but output ~4k is plausible — still, no mitigation if exceeded post-M2.
- [Fix]: UNVERIFIABLE CLAIM: Token limits ("4000 max_tokens", "~8000 input"). Parameterize in script (e.g., env vars), compute tokens pre-call via tiktoken equiv in bash, truncate context dynamically.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: AO-004 correlation pseudocode assumes `source_path` exists/unambiguous in every item, but structured items (AO-002) may lack it or have vague paths (e.g., "review Project X" → no file path).
- [Why]: Items without `source_path` skip correlation entirely (silent false neg), undermining metrics; contradicts "infer what operator did with *all* surfaced items."
- [Fix]: Fallback heuristic: if no `source_path`, use item title/domain for broader git grep (e.g., `git log --grep="Project X"`); flag unpathable items as 'uncorrelated' in scoring.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: M2 post-processing "check for duplicate object_ids within the cycle" lacks definition of `object_ids` generation/resolution (e.g., path-based? hash?) and merge logic.
- [Why]: Without precise identity (esp. aliases), dedup safety net fails; prompt handles "most" but probabilistic, risking M2/M4 criteria (zero dups in cycle, rising urgency).
- [Fix]: Explicitly define in notes: `object_id = basename(resolve_id(path))`; merge by taking latest urgency + combined notes. Add SQL UNIQUE constraint on cycle+object_id.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: References to existing infrastructure ("dashboard_actions SQLite approach", "cron-lib.sh", `_openclaw/data/attention-replay.db`, `_system/docs/solutions/gate-evaluation-pattern.md`) assume they exist/work as described.
- [Why]: Unverifiable claims; if mismatched (e.g., different cron infra), AO-001 integration fails immediately.
- [Fix]: UNVERIFIABLE CLAIM: Internal refs (dashboard_actions, cron-lib.sh, paths, gate-eval doc). Add verification task in M1: "confirm compat via dry-run on dashboard_actions DB."

- [F7]
- [Severity]: MINOR
- [Finding]: AO-004 window hardcoded "48h if domain in (software, career) else 7d" in prose but pseudocode uses `window = ...`; no handling for items without `domain`.
- [Why]: Edge case skips correlation; minor inconsistency reduces clarity/reliability.
- [Fix]: Default to 7d; make configurable via SQLite config table.

- [F8]
- [Severity]: MINOR
- [Finding]: Success criteria like M1 "Daily artifact includes action_class on every Focus item" and M3 "correlation script correctly identifies... (spot-check validated)" are vague on measurement (e.g., how many items? what %? automated?).
- [Why]: Reduces measurability for gates; "spot-check" invites bias.
- [Fix]: Quantify: "100% of Focus items have action_class (grep check)"; "80% spot-check agreement on 20 items."

- [F9]
- [Severity]: STRENGTH
- [Finding]: Milestone sequencing diagram and deps (M1 parallel → M2 → M3 → M4 eval) correctly reflect needs: dedup (AO-003) requires schema+items; correlation/scoring (M3) queries SQLite post-logging.
- [Why]: Sound deps prevent blocking; parallel M1 feasible as noted; timeline realistic (~2w impl +14d eval).
- [Fix]: N/A

- [F10]
- [Severity]: STRENGTH
- [Finding]: M4 as "gate" with targeted failure responses (e.g., "Context coverage <80% → tune AO-002") provides clear next steps, aligning with referenced eval pattern.
- [Why]: Ensures completeness — eval not just passive; operationalizes spec's exit criteria.
- [Fix]: N/A

- [F11]
- [Severity]: MINOR
- [Finding]: AO-002 prefers Option A for token efficiency/human-readable MD, but no comparison metrics (e.g., parse success rate from tests).
- [Why]: Preferred without evidence; if Option A fails often, wastes time.
- [Fix]: Mandate "test both options on 5 runs, pick by parse success + token delta."

- [F12]
- [Severity]: STRENGTH
- [Finding]: Acknowledges AO-004 false-neg bias as "safe" (under-counts acted-on, penalizes system fairly); git log proxy is lightweight, fits bash constraint.
- [Why]: Realistic for Phase 1; better alts (e.g., Obsidian API) violate no-tools; sound signal despite limits.
- [Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. AO-002 HTML comment markers are brittle for structured extraction** (4/4 reviewers)
OAI-F3 (CRITICAL), GEM-F2 (CRITICAL), DS-F1 (SIGNIFICANT), GRK-F1 (SIGNIFICANT)

Strongest consensus finding. All reviewers flagged that grep-based extraction of JSON from HTML comments is fragile: LLMs produce multi-line JSON, misplace markers, escape characters incorrectly, or omit markers entirely. Multiple reviewers recommend switching to Option B (single fenced JSON block) or at minimum adding strict delimiters + jq validation + quarantine-on-failure.

**2. AO-004 git correlation misses uncommitted changes and renames** (4/4 reviewers)
OAI-F11 (SIGNIFICANT), GEM-F4 (SIGNIFICANT), DS-F2 (SIGNIFICANT), GRK-F4 (SIGNIFICANT)

`git log -- source_path` only sees committed changes. File renames, uncommitted edits, and actions on different files all produce false negatives. Reviewers suggest adding `--follow` for renames and filesystem mtime as a secondary signal. The plan already acknowledges false-negative bias — the question is whether the bias is too strong to produce useful metrics.

**3. Object identity (object_id) not formally defined** (2/4 reviewers)
OAI-F7 (CRITICAL), GRK-F5 (SIGNIFICANT)

Path-based identity is stated but derivation rules aren't specified: normalization, case sensitivity, canonical form, when IDs change. Without formal definition, dedup (AO-003) and correlation (AO-004) operate on unstable ground. OAI recommends UNIQUE constraint on (cycle_id, object_id).

**4. Success criteria insufficiently measurable** (4/4 reviewers, various findings)
OAI-F2 (SIGNIFICANT), OAI-F20 (SIGNIFICANT), GEM-F5 (SIGNIFICANT), DS-F3 (MINOR), GRK-F8 (MINOR)

M1 "accepts inserts/queries" needs concrete acceptance tests. M2 "rising urgency" needs operational definition. M3 "spot-check validated" needs quantification. M1 "sidecar JSON produced" needs jq validation gate.

**5. False-positive rate lacks ground truth mechanism** (1 explicit + 1 partial)
OAI-F14 (CRITICAL), DS-F2 (partial)

The plan references "False-positive rate >40%" as an evaluation criterion but Phase 1 has no labeling mechanism to distinguish true positives from false positives. Vault-change correlation classifies acted-on vs not-acted-on, but "not acted on" conflates "irrelevant item" (false positive) with "relevant but deferred" — different failure modes.

**6. Dedup context format underspecified** (3/4 reviewers)
OAI-F8 (SIGNIFICANT), DS-F8 (SIGNIFICANT), GEM-F6 (SIGNIFICANT)

The "Recently surfaced items" block injected for dedup lacks specification: what fields, how many items, what format. GEM-F6 uniquely flags context poisoning risk (model regurgitating old items). DS-F8 suggests compact ID+title format for token efficiency.

**7. Missing error handling specification for cron** (2/4 reviewers)
OAI-F15 (SIGNIFICANT), GRK-F2 (CRITICAL)

No specification for API failures, parse errors, DB lock/corruption, or partial writes. Cron jobs fail silently — without error handling spec, replay gaps are inevitable.

**8. Token budget inconsistency** (2/4 reviewers)
OAI-F4 (SIGNIFICANT), GRK-F3 (SIGNIFICANT)

"4000 max_tokens ceiling" (output) and "~8000 input tokens" (AO-003) referenced without model/version context. Need to be parameterized.

### Unique Findings

**OAI-F22 — Option B may be more robust than Option A** (SIGNIFICANT)
Argues that a single delimited JSON block is typically *more* reliable than scattered per-item markers, despite modest token overhead. Suggests re-ranking preferences. **Genuine insight** — this aligns with the consensus that Option A is brittle, and offers a concrete alternative ranking.

**GEM-F6 — Context poisoning risk in dedup** (SIGNIFICANT)
The model may hallucinate and regurgitate old items verbatim from the dedup context block rather than generating fresh analysis. Suggests XML separation (`<historical_context>`) and strong prompt guardrails. **Genuine insight** — a failure mode the other reviewers didn't consider.

**GEM-F8 — AO-005 testing blocked by AO-004 despite parallel diagram** (MINOR)
Scoring queries need `action_type` populated by correlation, so AO-005 can't fully test without AO-004 output. Suggests generating mock data. **Genuine insight** — the sequencing diagram shows parallel but testing has a dependency.

**DS-F10 — Fold correlation into main cron job** (MINOR)
Rather than a separate 11 PM LaunchAgent, run correlation as a post-processing step of the daily cron. Reduces operational surface. **Genuine insight** — simpler architecture with fewer moving parts.

**DS-F4 — AO-003 depends on integration step completion** (SIGNIFICANT)
AO-003 can't meaningfully test dedup without logged items from the AO-001/002 integration step. The sequence diagram shows parallel but there's a hidden dependency. **Genuine insight** — clarifies the real critical path.

### Contradictions

**Option A vs Option B preference:**
- OAI-F22 and GEM-F2: Switch to Option B (single JSON block) as primary
- DS-F1: Keep Option A but add Option B as automatic fallback
- GRK-F11: Test both empirically before deciding
- Plan as written: Option A preferred, Option B fallback

No reviewer defends Option A as superior. The disagreement is over whether to switch now or test first. **Flag for operator decision.**

**AO-004 correlation — sufficient signal or too weak?**
- OAI-F11: Sound but narrow; augment with mtime and folder-level signals
- DS-F2: May be meaningless for career domain; document expected coverage per domain
- GEM-F4: Add `--follow` + mtime secondary
- GRK-F12 (STRENGTH): Git log proxy is lightweight and fits constraints; sound for Phase 1

All agree it's limited. Disagree on whether to augment now or accept as Phase 1 prototype. **The plan already frames this as Phase 1 — accepting narrow but sound is consistent with the stated approach.**

### Action Items

**A1 (must-fix)** — Harden AO-002 structured extraction approach
Sources: OAI-F3, GEM-F2, DS-F1, GRK-F1, OAI-F22
Switch to single delimited JSON block (Option B) as primary extraction target, or adopt strict start/end delimiters with jq validation. Add quarantine-on-parse-failure (skip logging, preserve raw response for inspection). This is the highest-signal finding across all reviewers.

**A2 (must-fix)** — Define object identity formally
Sources: OAI-F7, GRK-F5
Specify: canonical source_path normalization (vault-relative, normalized separators), object_id derivation rule, UNIQUE constraint on (cycle_id, object_id), and when/how aliases apply. This is a prerequisite for AO-003 and AO-004 correctness.

**A3 (must-fix)** — Define false-positive rate ground truth
Sources: OAI-F14
Add lightweight labeling: either a manual review script to label a sample as TP/FP/unclear, or redefine the metric to use "acted-on rate" (which the correlation *can* measure) rather than "false-positive rate" (which requires knowing what *should* have been surfaced). Evaluation gate can't function without this.

**A4 (should-fix)** — Tighten success criteria across milestones
Sources: OAI-F2, OAI-F20, GEM-F5, DS-F3, GRK-F8
M1: add jq validation gate + concrete acceptance tests. M2: operationalize "rising urgency" (e.g., recurrence_count, is_recurrence flag). M3: quantify spot-check (N items, agreement threshold).

**A5 (should-fix)** — Specify dedup context format and injection guardrails
Sources: OAI-F8, DS-F8, GEM-F6
Define compact template (object_id + title + last_urgency + last_seen), deterministic cap (top N by recency), and XML/delimiter separation to prevent context poisoning.

**A6 (should-fix)** — Add error handling specification
Sources: OAI-F15, GRK-F2
Specify: API retry (3x exponential backoff), parse failure quarantine, DB transaction wrapping, cycle status logging (ok/api_error/parse_error), and failure notification mechanism.

**A7 (should-fix)** — Add mtime as secondary correlation signal
Sources: OAI-F11, GEM-F4
Complement git log with filesystem mtime check. If git log finds nothing but file mtime is within the window, log as "acted_on" with source "mtime_correlation". Adds coverage for uncommitted edits.

**A8 (should-fix)** — Parameterize token budgets
Sources: OAI-F4, GRK-F3
Define MODEL, MAX_OUTPUT_TOKENS, MAX_INPUT_ESTIMATE as config. Add runtime guard: estimate prompt size, truncate dedup context deterministically if over budget.

**A9 (should-fix)** — Define action_class taxonomy
Sources: OAI-F5, DS-F7
Enumerate allowed values (e.g., do, decide, plan, track, review, wait). Define fallback rule for missing values. Validate in post-processing.

**A10 (should-fix)** — Clarify AO-003 dependency on integration step
Sources: DS-F4
The AO-001/002 integration step (logging parsed items to SQLite) must complete before AO-003 can meaningfully test. Update sequencing notes to reflect this.

**A11 (defer)** — Consider folding AO-004 into main cron job
Sources: DS-F10, OAI-F12, GEM-F7
Running correlation as a post-processing step (for items whose window just closed) instead of a separate LaunchAgent reduces operational surface. Worth evaluating during implementation but not blocking.

**A12 (defer)** — Empirically test Option A vs B before committing
Sources: GRK-F11, OAI-F18
If A1 doesn't fully settle the approach, run 5-10 test prompts with each format and measure parse success rate. Defer to implementation time.

**A13 (defer)** — Generate mock AO-004 data for AO-005 testing
Sources: GEM-F8
Create synthetic correlation results so AO-005 SQL queries can be tested before AO-004 produces real data. Nice-to-have for parallel development.

### Considered and Declined

**OAI-F11 (multi-signal weighting with signal_strength)** — `overkill`
The full multi-signal scoring (strong/medium/weak per git commit, mtime, folder activity) adds significant complexity. Adding mtime as a binary secondary check is accepted (A7), but signal weighting and folder-level correlation are premature for Phase 1.

**OAI-F19 (artifact_line_start/end anchors in sidecar)** — `overkill`
Mapping JSON entries to specific Markdown line numbers adds complexity without clear Phase 1 benefit. Sidecar as source of truth for structured operations is implicit.

**OAI-F21 (per-AO file/function checklist in action plan)** — `out-of-scope`
This level of detail belongs in task definitions (tasks.md has a file change map), not the action plan.

**GRK-F4 (git grep fallback for pathless items)** — `overkill`
Using `git log --grep="Project X"` is unreliable — project names appear in many commits. Logging pathless items as "uncorrelated" with a dedicated status is the cleaner Phase 1 approach.

**OAI-F23, GEM-F3, DS-F6, GRK-F6 (unverifiable internal references)** — `incorrect`
The referenced assets (dashboard_actions SQLite, cron-lib.sh, gate-evaluation-pattern.md) all exist in the vault and are stable. Expected finding from external reviewers who can't see internal files.
