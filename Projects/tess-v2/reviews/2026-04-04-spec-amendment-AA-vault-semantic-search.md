---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/tess-v2/design/spec-amendment-AA-vault-semantic-search.md
artifact_type: design-input
artifact_hash: bff17d44
prompt_hash: 74a38885
base_ref: null
project: tess-v2
domain: software
skill_origin: peer-review
created: 2026-04-04
updated: 2026-04-04
reviewers:
  - openai/gpt-5.4
  - google/gemini-3.1-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "Contains /Users/ paths (1 occurrence) — sent to external reviewers"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 76211
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-04-spec-amendment-AA-vault-semantic-search-openai.json
  google:
    http_status: 200
    latency_ms: 37627
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-04-spec-amendment-AA-vault-semantic-search-google.json
  deepseek:
    http_status: 200
    latency_ms: 55062
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-04-spec-amendment-AA-vault-semantic-search-deepseek.json
  grok:
    http_status: 200
    latency_ms: 28280
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-04-spec-amendment-AA-vault-semantic-search-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Spec Amendment AA — Vault Semantic Search Integration

**Artifact:** Projects/tess-v2/design/spec-amendment-AA-vault-semantic-search.md
**Mode:** full
**Reviewed:** 2026-04-04
**Reviewers:** GPT-5.4, Gemini 3.1 Pro Preview, DeepSeek Reasoner, Grok 4.1 Fast Reasoning
**Review prompt:** Structured review of spec amendment for vault semantic search three-layer integration (orchestrator tool, dispatch enrichment, executor tool). Evaluated for correctness, completeness, consistency, feasibility, and clarity.

---

## OpenAI (GPT-5.4)

Below is a structured review of Amendment AA.

## Overall assessment

This is a strong amendment: the problem is real, the proposed integration points are coherent, and the sequencing mostly fits the current Tess/Hermes/QMD architecture. The separation into three layers is directionally correct and not obviously redundant: each layer serves a distinct execution locus and capability boundary.

The main weaknesses are:
- some under-specified failure behavior and fallback logic,
- an unclear boundary between “search result excerpts are enough” vs “Tess/Claude Code must also read files,”
- observability/security/governance details that become more important once search is native to the orchestrator,
- a few unverifiable operational/statistical claims that should be grounded.

---

## Direct answers to the reviewer questions

### 1. Three-layer architecture: right separation, or redundant?

**Answer:** The separation of concerns is mostly right and should not be collapsed.

- **Orchestrator tool** serves pre-dispatch reasoning, triage, routing, and direct-answer scenarios.
- **Dispatch enrichment** serves executors that cannot call tools and improves baseline context quality for every run.
- **Executor tool** serves reactive discovery during long-running or exploratory Claude Code tasks.

These are distinct moments in the lifecycle. Collapsing them would reduce capability:
- If you only had dispatch enrichment, Tess herself still couldn’t search during triage/evaluation.
- If you only had an orchestrator tool, local executors would still lack dynamic context.
- If you only had an executor tool, you’d pay unnecessary dispatch costs and lose zero-dispatch interactive handling.

That said, there is **implementation duplication risk** between the orchestrator tool and Claude Code tool, which should be handled by a shared wrapper/library and a shared result schema.

### 2. Reuse `knowledge-retrieve.sh` for dispatch enrichment but not for orchestrator/executor tools: justified?

**Answer:** Yes, broadly justified, but the rationale should be made more explicit.

This split makes sense because:
- **Dispatch enrichment** is a pipeline concern: it benefits from decay weighting, diversity constraints, dedup, and token-budget shaping.
- **Ad hoc tool use** is an interactive reasoning concern: the caller should control relevance in context, and aggressive post-processing may hide useful results.

However, the amendment should define:
- a **common lower-level retrieval primitive** shared by both paths,
- which post-processing is intentionally omitted for tools,
- and whether there are still some lightweight common guarantees for all paths, e.g. dedup, path normalization, result truncation, and consistent score semantics.

### 3. Missing failure modes?

**Answer:** Yes. The current risks table misses several important operational failure modes:
- QMD/tool failure during triage or dispatch assembly,
- stale/missing index metadata causing false confidence,
- overlapping/duplicative context between Layer 5 enrichment and executor mid-run search,
- prompt injection or unsafe content propagation from vault excerpts into prompts,
- excessive orchestrator reliance on native tools beyond the single tool-call loop risk,
- permission/scope issues if future AD-016 tools expand beyond search.

### 4. Task decomposition and sequencing: sound?

**Answer:** Mostly sound, but missing a few tasks/dependencies:
- explicit fallback/error-handling implementation tasks,
- result schema standardization,
- index freshness/status exposure,
- test coverage for overlap/token-budget behavior,
- governance/scope restrictions for orchestrator-native tools.

Also, TV2-052 is marked **Domain: research** though it reads like an implementation/configuration task; likely should be **code** or split into code + docs.

### 5. Does AD-016 introduce broader architectural risks that should be addressed now?

**Answer:** Yes. AD-016 is plausible as a design principle, but it should be constrained now before it becomes precedent.

Main risks:
- orchestrator bloat and tool-sprawl,
- policy inconsistency across tools,
- increased attack surface through prompt-mediated tool invocation,
- blurred responsibility boundaries between orchestration and execution,
- governance gaps for read/write/shell-access semantics.

The amendment should introduce **admission criteria** for native tools now, not defer them.

---

## Findings

### F1
- **Severity:** SIGNIFICANT
- **Finding:** The amendment assumes that QMD result excerpts are sufficient for Tess to “read top results” in orchestrator-handled scenarios, but it does not clearly specify whether `vault_search` returns enough content for synthesis or whether a separate file-read capability is required.
- **Why:** In the proof case for interactive queries, Tess “reads the top 3-5 results,” yet the proposed tool only returns paths, scores, and excerpts. If excerpts are short/snippet-based, synthesis quality may be poor or misleading. This also affects evaluation workflows where Tess may need to verify claims against full source content.
- **Fix:** Specify one of:
  1. `vault_search` returns sufficiently large bounded excerpts/chunk payloads for direct synthesis, or
  2. orchestrator use of `vault_search` is paired with a required `vault_read` follow-up capability, or
  3. a `--full-chunk`/`--snippet-lines` option is added with strict token limits.  
  Also update proof cases to reflect the actual read path.

### F2
- **Severity:** SIGNIFICANT
- **Finding:** Failure behavior for QMD unavailability, wrapper-script errors, or malformed tool output is under-specified for all three layers.
- **Why:** This capability is being inserted into triage, dispatch assembly, and executor runtime. A failure during any of these points has different blast radius:
  - triage failure should degrade to no-search routing,
  - dispatch enrichment failure should not break dispatch,
  - executor tool failure should return a recoverable tool error.
  Without explicit behavior, implementations may fail closed or brittlely.
- **Fix:** Add a failure-mode section specifying:
  - timeout thresholds per layer,
  - fallback path per layer,
  - whether failures are silent, warned, or contract-visible,
  - standard error payload schema,
  - observability events for tool failure, timeout, stale index, empty results.

### F3
- **Severity:** SIGNIFICANT
- **Finding:** The overlap between dispatch-time enrichment and executor tool search is acknowledged implicitly but not managed explicitly.
- **Why:** Claude Code runs may receive Layer 5 enriched context and then call `vault_search` again, returning overlapping excerpts/files. This can waste tokens, create duplicate evidence, and bias the model toward repeated documents.
- **Fix:** Add dedup/overlap handling guidance:
  - include file IDs/paths in Layer 5 enrichment metadata,
  - have executor tool results annotate “already provided in dispatch context,”
  - or provide a parameter to exclude already-injected paths/chunks.  
  At minimum, instruct the Claude Code profile to prefer searching for *new* angles not already covered by Layer 5.

### F4
- **Severity:** SIGNIFICANT
- **Finding:** The proposal lacks an explicit result schema contract for `vault_search` across orchestrator and executor usage.
- **Why:** A shared tool exposed in multiple contexts needs stable output semantics. Without a schema, prompt/tool consumers may make inconsistent assumptions about fields like score meaning, excerpt length, collection name, timestamps, path normalization, and truncation markers.
- **Fix:** Define a normative output schema, e.g.:
  - query
  - mode
  - index_timestamp
  - results[] with path, title, collection, score, score_type, excerpt, chunk_id, last_modified, already_in_context?  
  Include error schema too.

### F5
- **Severity:** SIGNIFICANT
- **Finding:** The risks table does not address prompt injection or unsafe instruction-carrying content retrieved from the vault and injected into Layer 5 or surfaced through tools.
- **Why:** Vault content may contain imperative text, code snippets, or historical notes that look like instructions. Once this content is injected into prompts, especially into executor contexts, it can influence model behavior unexpectedly. Native search increases retrieval breadth, which increases this risk.
- **Fix:** Add a safety note and mitigation:
  - retrieved vault content is reference material, not authority,
  - models must not treat retrieved content as instructions overriding system/contract policy,
  - optionally label injected search results as untrusted context,
  - strip or annotate frontmatter/instructional blocks where feasible.

### F6
- **Severity:** SIGNIFICANT
- **Finding:** AD-016 is too broad as stated and lacks admission criteria or guardrails for future orchestrator-native tools.
- **Why:** “Wherever mechanically feasible” is not enough as an architectural principle. Many things are mechanically feasible but undesirable at the orchestration layer due to safety, complexity, cost, or role-boundary concerns. This can lead to tool-sprawl and a gradual collapse of the orchestrator/executor distinction.
- **Fix:** Amend AD-016 with criteria such as:
  - low side-effect or read-only by default,
  - bounded latency,
  - bounded output size,
  - clear value at triage/evaluation time,
  - deterministic or inspectable behavior,
  - policy/governance compatibility,
  - no duplication of executor-only complex workflows.  
  Also state that write-capable or multi-step tools require a separate safety review.

### F7
- **Severity:** SIGNIFICANT
- **Finding:** The amendment does not specify index freshness/status exposure to tool consumers, despite freshness being a known operational issue.
- **Why:** If Tess uses search results for routing/evaluation, stale results can produce false confidence. The risk table notes staleness, but users/executors need a way to know whether search is recent enough to trust for a given task.
- **Fix:** Include index metadata in tool/enrichment output:
  - index updated_at,
  - freshness age,
  - collection coverage counts,
  - stale flag if above threshold.  
  Add policy guidance: if stale beyond threshold, Tess should caveat results or avoid using them for strict verification.

### F8
- **Severity:** SIGNIFICANT
- **Finding:** Dispatch-time enrichment query construction is under-specified and may produce inconsistent retrieval quality across services.
- **Why:** “Constructs QMD query from contract description + search hints” leaves open important questions:
  - concatenation order,
  - weighting of hints vs description,
  - whether service name influences ranking,
  - sanitization/escaping,
  - max length,
  - behavior if hints are noisy or overly broad.
- **Fix:** Define a deterministic query-building strategy and test matrix. Example:
  - primary query = normalized contract description,
  - hints appended with weighted separators,
  - service/domain tags optionally included,
  - character/token cap,
  - dedup and stopword cleanup,
  - fallback to description-only if hints absent or too long.

### F9
- **Severity:** SIGNIFICANT
- **Finding:** The amendment lacks explicit timeout and performance budgets per layer.
- **Why:** The risk table cites ~1.8s dispatch latency for hybrid mode, but orchestrator triage and interactive handling may have different SLOs than dispatch assembly. Tool-call limits alone do not prevent latency creep if each call is slow.
- **Fix:** Define budgets such as:
  - orchestrator tool: e.g. 2-3s soft timeout, 1 retry max,
  - dispatch enrichment: e.g. 5s timeout, fail-open,
  - executor tool: e.g. 10s timeout, tool-error return.  
  Add these to implementation tasks and observability.

### F10
- **Severity:** SIGNIFICANT
- **Finding:** There is no explicit authorization/scope statement for what vault content `vault_search` may surface to orchestrator vs executors.
- **Why:** Search broadens access from explicit `read_paths` to semantic discovery over the whole vault. Even in a personal system, this is a meaningful change in data exposure. Some services may be appropriate to read from some collections and not others.
- **Fix:** Define collection/path scope policy:
  - all collections allowed by default, or
  - per-service/per-executor allowlists,
  - optional collection filters in tool parameters,
  - documented privacy boundaries if any exist.  
  At minimum, state that this amendment intentionally broadens from path-scoped to vault-wide read discovery.

### F11
- **Severity:** SIGNIFICANT
- **Finding:** The amendment says “no decay/diversity filtering” for orchestrator/executor tools, but does not justify whether dedup is also omitted or whether omission is intended.
- **Why:** Dedup is usually beneficial even in ad hoc search. If duplicate chunks/files are returned, both Tess and Claude Code may get repetitive evidence and waste reasoning/tokens. The current text groups all post-processing together without clarifying which parts are optional vs always useful.
- **Fix:** Separate post-processing categories:
  - always-on: dedup, path normalization, truncation, schema validation,
  - optional for enrichment only: decay weighting, diversity shaping,
  - caller-controlled: result limit/mode.  
  Document the intentional differences.

### F12
- **Severity:** SIGNIFICANT
- **Finding:** TV2-052 appears misclassified and under-scoped.
- **Why:** Exposing a tool to Claude Code executor involves configuration, system prompt changes, possibly executor runtime integration, and tests. Marking it as `research` understates implementation effort and may break planning/reporting.
- **Fix:** Reclassify TV2-052 as `code` or split into:
  - code/config integration task,
  - docs/spec prompt task,
  - executor integration test task.

### F13
- **Severity:** SIGNIFICANT
- **Finding:** The amendment does not include testing for empty-result behavior and low-confidence-result behavior.
- **Why:** Search systems often fail not by throwing errors, but by returning weak results. Tess may over-trust top hits merely because something was returned.
- **Fix:** Add acceptance criteria and tests for:
  - zero results,
  - low-score results,
  - highly ambiguous queries,
  - contradictory top hits across modes.  
  Include prompt guidance for Tess/Claude Code on how to respond when search confidence is weak.

### F14
- **Severity:** SIGNIFICANT
- **Finding:** The current proof cases demonstrate benefit, but they do not prove that all three layers are necessary rather than just useful.
- **Why:** The amendment’s architecture decision is stronger than the evidence shown. The examples justify orchestrator search and dispatch enrichment well, but executor mid-run search is less concretely evidenced.
- **Fix:** Add one proof case where dispatch-time enrichment is insufficient and Claude Code genuinely needs reactive semantic search mid-execution, e.g. branching investigation based on a document discovered during runtime.

### F15
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: “QMD hybrid scored 32% on cross-domain eval.”
- **Why:** This statistic is used in the risks section to justify search quality expectations, but no source, evaluation method, dataset, or comparison baseline is provided. It should not be left ungrounded.
- **Fix:** Cite the internal eval artifact, date, methodology, and exact metric definition, or remove the numeric claim and replace with qualitative language.

### F16
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: “Binary: `/opt/homebrew/bin/qmd` (v2.0.1).”
- **Why:** Specific version references should be validated because implementation details and flags may differ by version.
- **Fix:** Verify and cite source of truth, or state “observed locally as of 2026-04-04” if this is an environment inspection rather than a controlled dependency declaration.

### F17
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: “Index: ~729 docs, ~4,949 chunks across 4 collections.”
- **Why:** These counts may drift and should not appear as stable architectural facts unless sourced to a dated measurement.
- **Fix:** Mark as an observed snapshot with timestamp, or move to a non-normative note.

### F18
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: “Broken: `com.crumb.qmd-index` LaunchAgent (exit 127, PATH issue).”
- **Why:** This is a concrete operational diagnosis. If wrong, the proposed fix may be insufficient.
- **Fix:** Reference logs or incident artifact confirming the exit code and cause, or soften to “suspected PATH issue pending verification.”

### F19
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: “session-end `qmd update` keeps index semi-fresh.”
- **Why:** This operational behavior affects the staleness risk assessment, but no source is provided.
- **Fix:** Verify via job/script reference or telemetry, or remove.

### F20
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: “A vault search that Tess handles herself avoids a Claude Code dispatch ($0.05-0.20 per session).”
- **Why:** Cost claims may inform prioritization and should be grounded.
- **Fix:** Cite internal billing observations or remove the numeric range.

### F21
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: “Latency — hybrid mode adds ~1.8s to dispatch.”
- **Why:** This figure is used to classify risk severity. Without sourcing, it may mislead implementation planning.
- **Fix:** Attach benchmark conditions or label as preliminary measurement.

### F22
- **Severity:** SIGNIFICANT
- **Finding:** The amendment does not specify whether `search_hints` are operator-authored only or may be model-generated/derived.
- **Why:** If model-generated hints are later introduced, prompt quality and drift become major factors in retrieval quality. Even if not planned now, the contract field’s semantics should be explicit.
- **Fix:** State that in AA, `search_hints` are explicit contract author inputs only, or define approved derivation behavior separately.

### F23
- **Severity:** MINOR
- **Finding:** “System prompt integration: Added to Layer 2 (Service Context) in the orchestrator profile” is slightly confusing because the orchestrator is not a “service” in the same sense as executors.
- **Why:** Terminology drift can confuse implementers working with the six-layer prompt architecture.
- **Fix:** Clarify whether Layer 2 is a shared prompt layer schema used by both orchestrator and executors, or use profile-specific wording.

### F24
- **Severity:** MINOR
- **Finding:** The amendment says “dispatch-time enrichment is skipped” when `search_hints` are absent, but this may be too restrictive.
- **Why:** A contract description alone may often be sufficient to generate useful enrichment; requiring explicit hints may leave value unrealized.
- **Fix:** Consider defaulting to description-only enrichment for opted-in services, or add a contract boolean like `auto_search_context: true` separate from `search_hints`.

### F25
- **Severity:** MINOR
- **Finding:** The compaction policy “enrichment results are compacted before static `read_paths` content” may not always preserve the highest-value evidence.
- **Why:** Some static files may be lower-value than search results in certain contracts; a fixed precedence rule may degrade answer quality.
- **Fix:** Clarify compaction should be relevance-aware, not purely source-type-aware, or define service-level policy.

### F26
- **Severity:** MINOR
- **Finding:** The term “native tool access” could be misunderstood as bypassing contract constraints.
- **Why:** In systems with executor contracts, “native” may imply unrestricted. This could create confusion about policy and auditability.
- **Fix:** Clarify that native tools remain policy-bound, logged, and budgeted.

### F27
- **Severity:** STRENGTH
- **Finding:** The amendment identifies a genuine architectural gap: static `read_paths` are insufficient for thematic discovery and interactive vault-centric requests.
- **Why:** This is the right problem to solve, and the examples are concrete and relevant to current Tess workflows.
- **Fix:** None.

### F28
- **Severity:** STRENGTH
- **Finding:** The three-layer model maps cleanly onto the actual lifecycle of work in Tess: before dispatch, at dispatch, and during execution.
- **Why:** This is a strong conceptual separation and aligns with capability boundaries between orchestrator, runner, and executor.
- **Fix:** None.

### F29
- **Severity:** STRENGTH
- **Finding:** Reusing `knowledge-retrieve.sh` for dispatch enrichment is a good design choice.
- **Why:** It leverages existing decay weighting, diversity logic, and feedback logging, reducing duplication and preserving current AKM behavior where it matters most.
- **Fix:** None, aside from clarifying the lower-level shared primitive.

### F30
- **Severity:** STRENGTH
- **Finding:** The proposal is operationally pragmatic: thin wrappers for ad hoc search, deeper pipeline reuse for curated enrichment.
- **Why:** This keeps the interactive path simple while preserving quality control in the prompt-construction path.
- **Fix:** None.

### F31
- **Severity:** STRENGTH
- **Finding:** The sequencing mostly reflects dependency reality and sensibly parallelizes work after the LaunchAgent fix.
- **Why:** The three tracks are understandable and support incremental rollout.
- **Fix:** None, except for adding missing fallback/schema/testing tasks.

### F32
- **Severity:** STRENGTH
- **Finding:** The amendment anticipates the immediate synergy with Amendment Z and makes a compelling cost/latency argument for orchestrator-native search.
- **Why:** This shows strategic fit, not just local optimization.
- **Fix:** None.

---

## Additional recommendations

### Recommended spec additions
Consider adding these short sections:

1. **Failure semantics**
   - fail-open vs fail-closed per layer
   - timeout budgets
   - stale index behavior
   - empty/low-confidence result behavior

2. **Result schema**
   - one canonical JSON/text schema for `vault_search`
   - explicit metadata fields

3. **Safety/governance**
   - retrieved content is untrusted reference material
   - collection/path scoping rules
   - logging/audit expectations

4. **AD-016 guardrails**
   - read-only first
   - bounded outputs
   - no native write tools without separate safety review
   - explicit admission checklist

### Recommended missing tasks
Add tasks roughly like:
- **TV2-056:** Define shared `vault_search` output/error schema and parser tests
- **TV2-057:** Implement fail-open/fallback behavior and timeout handling for all three layers
- **TV2-058:** Add overlap/dedup handling between Layer 5 enrichment and executor search
- **TV2-059:** Add index freshness metadata exposure and stale-result handling
- **TV2-060:** Security/prompt-safety review for retrieved vault content injection
- **TV2-061:** Acceptance tests for empty-result, low-confidence, and QMD-down scenarios

---

## Bottom line

**Recommendation: approve with revisions.**

The amendment is architecturally sound and worth pursuing. The main work before implementation should be tightening:
- failure semantics,
- schema/output contracts,
- overlap handling,
- governance/safety around native tool access,
- and grounding unverifiable operational/statistical claims.

---

## Google (Gemini 3.1 Pro Preview)

Here is the structured review of Spec Amendment AA, incorporating answers to your specific questions into the classified findings.

### Unverifiable Claims

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Software version references and specific binary paths for QMD (`v2.0.1`, `/opt/homebrew/bin/qmd`, `/opt/homebrew/lib/node_modules/@tobilu/qmd/dist/cli/qmd.js`).
- [Why]: Internal package versions and file paths cannot be independently verified.
- [Fix]: Ensure these paths and versions are cross-checked against the actual deployment environment before executing TV2-047.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Statistic stating "QMD hybrid scored 32% on cross-domain eval".
- [Why]: The metric and the associated internal evaluation framework cannot be independently verified.
- [Fix]: Validate the 32% claim against internal eval logs to ensure the risk assessment accurately reflects the current search quality baseline.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Cost statistic stating "Claude Code dispatch ($0.05-0.20 per session)".
- [Why]: API costs vary highly based on context length, output length, and specific model used (e.g., Claude 3.5 Sonnet vs. Haiku).
- [Fix]: Verify this cost estimate against recent billing data for existing Claude Code executor sessions in Tess v2.

### Critical Findings

- [F4]
- [Severity]: CRITICAL
- [Finding]: External/undefined dependencies in the Task sequence (TV2-019 and TV2-031b).
- [Why]: Task TV2-054 depends on TV2-019, and TV2-051 depends on TV2-031b. Neither TV2-019 nor TV2-031b are defined in this document. This creates a critical project management gap, as delays in these unknown tasks will silently block the implementation of dispatch-time enrichment. *(Addresses Q4)*
- [Fix]: Explicitly define TV2-019 and TV2-031b in the document or clarify the interface boundaries if they belong to a concurrent amendment. 

- [F5]
- [Severity]: CRITICAL
- [Finding]: Unhandled failure mode for QMD during dispatch-time enrichment.
- [Why]: The contract runner calls `knowledge-retrieve.sh` synchronously during Layer 5 envelope assembly. If the QMD index is corrupted, the script hangs, or it throws an error, it is unclear if the entire contract dispatch fails or if it gracefully degrades to an empty Layer 5. Blocking dispatch due to a search enrichment failure reduces system resilience. *(Addresses Q3)*
- [Fix]: Explicitly state the error handling policy in Component 3 and TV2-051: dispatch should gracefully degrade (log a warning and proceed without enrichment) if the enrichment script times out or returns a non-zero exit code.

### Significant Findings

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Potential redundancy and context bloat between Dispatch Enrichment and Executor Tool.
- [Why]: If a contract includes `search_hints` AND is routed to a Claude Code executor, the executor receives the QMD excerpts in Layer 5, but might also independently use the `vault_search` tool for the exact same concepts. This duplicates tokens and could confuse the executor with overlapping chunks. *(Addresses Q1 & Q3)*
- [Fix]: Introduce a routing rule: either skip dispatch-time enrichment for Tier 3 (Claude Code) executors relying entirely on the tool, OR explicitly document in the Claude Code executor system prompt (Layer 2) that they should read Layer 5 context *before* invoking `vault_search`.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Risk of Orchestrator role blurring and context exhaustion (AD-016).
- [Why]: Giving Tess native tool access allows her to bypass executors, but doing so heavily burdens her prompt context. QMD excerpts can be token-heavy. If Tess searches repeatedly during triage, she risks exhausting her token limits or diluting her core orchestrator instructions, effectively turning her into a slow executor. *(Addresses Q5)*
- [Fix]: Implement strict limits on the orchestrator tool (e.g., max 1-2 calls per triage) and ensure the orchestrator system prompt clearly delineates that complex synthesis should still be delegated. 

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: Proof case synthesis relies on excerpts, not full documents.
- [Why]: In the "Interactive Ad-Hoc Queries" proof case, Tess synthesizes a response about "green philosophy" by reading "top 3-5 results (file excerpts returned by QMD)". Excerpts from BM25/Semantic search are usually just a few sentences or paragraphs, which may be insufficient to summarize whole books without the proposed-but-deferred `vault_read` tool. 
- [Fix]: Clarify in the proof case that Tess will provide an *index-level* synthesis (e.g., "Here are the books we have on this...") rather than a deep thematic summary, until `vault_read` is implemented.

### Minor Findings

- [F9]
- [Severity]: MINOR
- [Finding]: Hardcoded Node paths for the LaunchAgent fix.
- [Why]: Component 1 suggests replacing the plist command with `/opt/homebrew/bin/node /opt/homebrew/lib/node_modules/...`. Hardcoding global module paths is brittle if Node versions or npm structures change.
- [Fix]: Use the standard macOS launchd `EnvironmentVariables` dictionary to inject `PATH: /opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin` into the daemon's context, allowing `qmd` to be invoked naturally.

- [F10]
- [Severity]: MINOR
- [Finding]: Maintenance divergence between wrapper scripts.
- [Why]: Using `knowledge-retrieve.sh` for enrichment but a new `vault-search.sh` for tools creates two separate bash interfaces over the same `qmd` binary. While the justification (needing decay/diversity for blind enrichment but not for active search) is sound, maintaining two wrappers introduces drift risk. *(Addresses Q2)*
- [Fix]: Consider a unified wrapper script with flags (e.g., `vault-search.sh --apply-decay`), or clearly document that `knowledge-retrieve.sh` should eventually wrap `vault-search.sh` to prevent underlying API divergence.

### Strengths

- [F11]
- [Severity]: STRENGTH
- [Finding]: The three-layer architecture elegantly matches capability to agent limitations.
- [Why]: Supplying passive context (Layer 5) to local, tool-less LLMs while giving active tools to sophisticated models (Claude Code) and the orchestrator (Tess) maximizes the utility of QMD across all operational tiers without unnecessary API costs. *(Addresses Q1)*

- [F12]
- [Severity]: STRENGTH
- [Finding]: Graceful degradation via backward compatibility.
- [Why]: Making `search_hints` an optional field in the contract schema (v1.1.0) ensures that the existing 11 migrated services will continue operating perfectly without requiring immediate refactoring.

---

## DeepSeek (DeepSeek Reasoner)

- **[F1]**
- **Severity:** CRITICAL
- **Finding:** Task TV2-051 (Integrate dispatch-time enrichment into contract runner) has a stated dependency on TV2-054 (Add `search_hints` to contract schema), but this dependency is not reflected in the sequencing diagram. This creates a risk of integration failure if the schema change isn't completed first.
- **Why:** The contract runner's integration logic will need to read the new `search_hints` field from the contract. If TV2-051 attempts to run before the schema is updated and validated, it may encounter parsing errors or silently ignore the new field.
- **Fix:** Update the sequencing diagram and task list to show a clear dependency: TV2-054 → TV2-051. The description for TV2-051 should explicitly state it depends on the schema being updated to v1.1.0.

- **[F2]**
- **Severity:** SIGNIFICANT
- **Finding:** The spec does not define a fallback or error-handling behavior for when the QMD index is unavailable or the `vault-search.sh` script fails during dispatch-time enrichment.
- **Why:** A failure in the enrichment step could block contract dispatch entirely. The system should be resilient to transient search failures, especially since enrichment is an additive, non-critical path. The contract runner needs a defined behavior (e.g., log warning, proceed with dispatch without enrichment) to maintain system availability.
- **Fix:** Add a failure mode to the risks table and specify in Component 3/Task TV2-051: "If `knowledge-retrieve.sh` returns a non-zero exit code, the dispatch engine should log a warning (`ENRICHMENT_FAILED`) and proceed with the existing static `read_paths` context only."

- **[F3]**
- **Severity:** SIGNIFICANT
- **Finding:** Potential for token budget overflow and context duplication exists between dispatch-time enrichment (Layer 5) and subsequent executor tool calls (`vault_search`).
- **Why:** An executor (Claude Code) receiving enriched context may still call `vault_search` for deeper exploration, potentially pulling in the same or similar chunks already present in Layer 5. This wastes tokens and could confuse the model with repeated content.
- **Fix:** Add a note to the system prompt for the Claude Code executor (Component 4) advising: "Before using `vault_search`, review the provided 'Vault Context' in Layer 5 to avoid redundant searches." Consider a future enhancement where the tool call can optionally filter out already-provided document IDs.

- **[F4]**
- **Severity:** SIGNIFICANT
- **Finding:** The justification for not applying decay/diversity filtering to the orchestrator and executor tools ("caller judges relevance in context") is reasonable but incomplete. It ignores the loss of feedback logging for those calls, which is valuable for the AKM system's learning loop.
- **Why:** The AKM pipeline's `akm-feedback.jsonl` logging is crucial for improving search quality. The orchestrator and *executor* tool calls are configured to log (per Component 4), but the spec should explicitly mandate this for the *orchestrator* tool as well to ensure all search traffic is observable.
- **Fix:** Clarify in Component 2 that the `vault-search.sh` wrapper used by the orchestrator must also log queries with trigger type `orchestrator-tool` to `akm-feedback.jsonl`, matching the behavior specified for the executor tool.

- **[F5]**
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: The spec states "QMD hybrid scored 32% on cross-domain eval." There is no reference to the evaluation methodology, dataset, or what metric "32%" represents (e.g., precision@k, recall).
- **Why:** This statistic is used to gauge search quality risk. Without context, its validity and relevance to the amendment's use cases cannot be assessed.
- **Fix:** The claim should either be removed from the spec or accompanied by a citation to an internal evaluation document or log. Alternatively, reframe the risk in qualitative terms based on observed performance.

- **[F6]**
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: References to existing components ("~729 docs, ~4,949 chunks", "11 services migrated", "AKM pipeline", "Layer 5") are internal system details. While logically consistent within the artifact, a reviewer cannot verify their accuracy.
- **Why:** The review's correctness assessment depends on the truth of these foundational facts.
- **Fix:** These are acceptable as grounding context for the amendment review, but should be validated by the implementing team against the actual production state before proceeding with tasks.

- **[F7]**
- **Severity:** MINOR
- **Finding:** The "Tasks" table lists domains ("code", "research") but the "Proof Case" tasks (TV2-053, TV2-055) are categorized as "research". These tasks likely involve writing integration tests or validation scripts, which is a "code" activity, even if the goal is research validation.
- **Why:** Mislabeling could lead to incorrect resource assignment or prioritization.
- **Fix:** Change the Domain for TV2-053 and TV2-055 from "research" to "code" (or "test").

- **[F8]**
- **Severity:** MINOR
- **Finding:** The spec mentions a "Ralph hard-stop" as a mitigation for orchestrator tool-call loops but does not define what this is.
- **Why:** Lack of clarity for future reviewers or implementers not familiar with the "Ralph" component.
- **Fix:** Add a brief parenthetical explanation, e.g., "the Ralph hard-stop (the global execution timeout watchdog)".

- **[F9]**
- **Severity:** STRENGTH
- **Finding:** The three-layer architecture (orchestrator/dispatch/executor) demonstrates excellent separation of concerns. It addresses distinct needs: proactive planning by Tess, universal context for all executors, and reactive discovery for powerful executors, with minimal redundancy.
- **Why:** This design maximizes leverage and cost efficiency by applying the right capability at the right stage of the orchestration lifecycle.

- **[F10]**
- **Severity:** STRENGTH
- **Finding:** The decision to reuse `knowledge-retrieve.sh` for dispatch enrichment but use a thin wrapper for tools is well-justified. It correctly distinguishes between automated, batch-oriented context priming (which benefits from AKM's decay and diversity logic) and interactive, intent-driven search where the LLM can filter relevance itself.
- **Why:** This aligns the complexity of the filtering logic with the actor's capabilities, simplifying the tool interface while maintaining smart automation for local models.

- **[F11]**
- **Severity:** STRENGTH
- **Finding:** The amendment thoroughly considers cost-impact, providing a clear rationale for the orchestrator tool by comparing a $0.10-0.20 Claude Code session to $0 local QMD operation.
- **Why:** This directly ties the technical design to a key operational metric (cost), making the value proposition of the work immediately clear to stakeholders.

**Answers to Specific Questions:**

1.  **Separation of Concerns:** The three-layer architecture is appropriate, not redundant. Each layer serves a distinct phase and actor: the orchestrator tool enables pre-dispatch intelligence, dispatch enrichment provides baseline context for all (especially tool-less executors), and the executor tool enables agile mid-task exploration. They complement each other.
2.  **Reuse of knowledge-retrieve.sh:** The justification is sound. Dispatch-time enrichment benefits from the AKM pipeline's opinionated post-processing (decay, diversity) which is designed for automated use. The orchestrator and executor tools are interactive; the LLM can manage relevance, so thinner wrappers are sufficient and more flexible.
3.  **Uncovered Failure Modes:** See F2 (QMD failure mid-dispatch) and F3 (context duplication). Additionally, the spec does not address what happens if `vault-search.sh` is called with an empty result set—should it return a clear "no results" message or an empty list? This should be defined.
4.  **Task Decomposition & Sequencing:** Mostly sound. The critical missing dependency is TV2-054 → TV2-051 (see F1). Also, tasks TV2-053 and TV2-055 ("Proof case") likely require the creation of test scripts or scenarios; ensure this deliverable is clearly defined.
5.  **AD-016 Risks:** The principle introduces a scaling risk: proliferating native tools could increase the orchestrator's prompt complexity and cognitive load. A lightweight governance process (e.g., a checklist for "native tool suitability") should be considered now, perhaps as a note in AD-016. It also increases the attack surface for prompt injection to invoke local shell commands, though this is inherent to Hermes's design.

---

## Grok (Grok 4.1 Fast Reasoning)

- [F1]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: QMD binary at `/opt/homebrew/bin/qmd` (v2.0.1), index with ~729 docs/~4,949 chunks across 4 collections, AKM wrapper at `_system/scripts/knowledge-retrieve.sh`, LaunchAgent `com.crumb.qmd-index` fails with exit 127 due to PATH issue.  
  [Why]: Core prerequisite (Component 1) relies on these specifics; if incorrect (e.g., different version/path/index state), the entire amendment fails feasibility. Cannot confirm without system access.  
  [Fix]: Operator to verify via `qmd --version`, `ls /opt/homebrew/bin/qmd`, LaunchAgent logs (`log show --predicate 'subsystem == "com.crumb.qmd-index"'`), and index stats (`qmd stats` or equivalent).

- [F2]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: QMD hybrid mode scored 32% on "cross-domain eval"; latency ~1.8s for hybrid mode; Claude Code session costs $0.05-0.20.  
  [Why]: Justifies search quality, performance SLOs, and cost savings; 32% is presented as "better than 0%" but lacks eval methodology/context (e.g., what metric? dataset?). Inflated claims undermine credibility. Costs fluctuate with usage/models.  
  [Fix]: Provide eval details (dataset, metric like NDCG@10, repro steps) or link to results. Cite Anthropic pricing page for costs with date. Measure latency empirically (e.g., `time qmd search ...` avg over 10 runs).

- [F3]  
  [Severity]: SIGNIFICANT  
  [Finding]: TV2-051 depends on undefined TV2-031b (likely contract runner baseline) and TV2-054; sequencing shows TV2-054 before TV2-051, but table has TV2-051 depending on TV2-031b/TV2-054. TV2-019 in TV2-054 deps also undefined.  
  [Why]: Breaks task decomposition soundness (Q4); missing cross-refs to prior tasks risk execution gaps or ordering errors in IMPLEMENT phase.  
  [Fix]: Define/hyperlink TV2-031b/TV2-019 or confirm in main spec. Add explicit dep note: "TV2-051 assumes TV2-031b contract runner envelope assembly exists."

- [F4]  
  [Severity]: SIGNIFICANT  
  [Finding]: Risks table omits QMD downtime/failure modes (e.g., index corruption, OOM on large queries, binary crash mid-dispatch), dispatch enrichment blocking entire envelope assembly on QMD error, or overlapping/duplicate results between Layer 5 enrichment and executor tool calls wasting tokens/relevance.  
  [Why]: Answers Q3; dispatch-time enrichment is synchronous (called in runner), so QMD failure halts dispatches. Overlaps degrade quality (executor re-searches same content). Undercuts feasibility/observability claims.  
  [Fix]: Add risks: "QMD failure (high, fallback to no-enrichment + log/alert)"; "Result overlap (med, dedup by path in enrichment output)"; mitigations like timeout wrapper (`timeout 10s qmd ... || echo 'QMD failed'`), executor prompt "Avoid vault_search if Layer 5 already covers topic."

- [F5]  
  [Severity]: SIGNIFICANT  
  [Finding]: Three-layer architecture has redundancy: orchestrator tool (Tess searches pre-dispatch) overlaps dispatch enrichment (auto-searches at dispatch using contract hints); both use similar queries but different post-processing.  
  [Why]: Answers Q1; violates DRY, confuses when to use hints vs Tess manual search. Tess could always enrich proactively, collapsing layers. Weak separation of concerns.  
  [Fix]: Justify or merge: e.g., make dispatch enrichment always-on (query from contract desc only, no hints needed), let Tess tool override/add. Or clarify: "Orchestrator for ad-hoc; dispatch for anticipated via hints."

- [F6]  
  [Severity]: SIGNIFICANT  
  [Finding]: Reuse of `knowledge-retrieve.sh` only for dispatch (with decay/diversity) but thin `vault-search.sh` for orchestrator/executor lacks full justification beyond "ad-hoc judges relevance"; ignores that dispatch queries are also "ad-hoc" from contract desc.  
  [Why]: Answers Q2; inconsistent filtering policy risks quality variance (dispatch gets "better" results, ad-hoc gets raw). Decay/diversity useful everywhere for vault scale (~729 docs).  
  [Fix]: Option: Parametrize `vault-search.sh` with `--decay --diversity` flags, default off for ad-hoc/on for dispatch. Or document eval showing raw > filtered for interactive.

- [F7]  
  [Severity]: SIGNIFICANT  
  [Finding]: AD-016 (native tools) risks prompt bloat (Layer 2 grows with vault_read/grep/etc.), tool-call explosion in orchestrator (beyond triage loops), and security (shell wrappers like `cat`/`rg` expose full FS if misconfigured). Not addressed now.  
  [Why]: Answers Q5; Tess v2 in IMPLEMENT phase (11/?? services); tool proliferation breaks token budgets, increases latency/complexity. Defers systemic risks.  
  [Fix]: Add risk/mitigation to table: "Prompt/tool bloat (med, cap Layer 2 tools at 5; dynamic loading via profiles)"; "Security (low, sandbox wrappers with vault-only paths)"; cap principle to read-only tools.

- [F8]  
  [Severity]: MINOR  
  [Finding]: Contract schema addition `search_hints: string[]` lacks type/validation details (e.g., max length, min items, sanitization).  
  [Why]: §9.3 change; runner may choke on malformed hints (e.g., empty array, 10KB strings), breaking backward compat.  
  [Fix]: Spec: `search_hints: array of strings, max 5 items, each <=200 chars. Default: [] (skip enrichment).`

- [F9]  
  [Severity]: MINOR  
  [Finding]: Proof cases assume specific contract changes (e.g., connections-brainstorm hints) but §14 says "update contracts"; no before/after output comparison metrics.  
  [Why]: Weak validation; "validate quality" vague without rubrics (e.g., relevance score, token savings).  
  [Fix]: Add to TV2-053/TV2-055: "Rubric: 80%+ relevant chunks (manual score), <10% overlap with static paths."

- [F10]  
  [Severity]: MINOR  
  [Finding]: Sequencing diagram uses ASCII art but deps table has inconsistencies (e.g., TV2-051 deps include TV2-054, diagram shows after); parallel tracks good but no timeline estimates.  
  [Why]: Answers Q4 partially; minor confusion in execution.  
  [Fix]: Align table/diagram; add est: "Track 1: 1d, Track 2: 2d, Track 3: 0.5d post-048."

- [F11]  
  [Severity]: STRENGTH  
  [Finding]: Risks table is comprehensive for stated risks (e.g., token pressure, loops), with severity/mitigations; covers 7 key areas including eval-based quality.  
  [Why]: Strong observability foundation (feedback logging expansion); directly addresses Q3 partially. Edge: Assumes logging works, but verifiable via existing AKM.  
  [Fix]: N/A

- [F12]  
  [Severity]: STRENGTH  
  [Finding]: Task decomposition clear (9 tasks, deps, domains, risks); sequencing enables parallelism post-TV2-047, validates via proof cases (TV2-053/055).  
  [Why]: Answers Q4; sound for IMPLEMENT phase, proof cases tie to real contracts/use cases. Edge: Handles schema bump safely (optional field).  
  [Fix]: N/A

- [F13]  
  [Severity]: STRENGTH  
  [Finding]: Internal consistency high: AD-015/016 rationale ties to evidence (e.g., book scan); spec sections modified table precise; proof cases demonstrate value concretely.  
  [Why]: Logical flow from problem → decision → components → risks/tasks. Feasibility strong given existing QMD/AKM/Hermes.
  [Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. Failure semantics / fail-open behavior unspecified (4/4 reviewers)**
OAI-F2, GEM-F5, DS-F2, GRK-F4

All four reviewers flagged that the amendment does not define what happens when QMD is unavailable, the wrapper script errors, or the index is corrupt — across any of the three layers. Dispatch-time enrichment is synchronous in the runner pipeline; a QMD hang could block all contract dispatches. Each layer needs explicit fail-open/fail-closed behavior, timeouts, and observability events.

**2. Context overlap between dispatch enrichment and executor tool (4/4 reviewers)**
OAI-F3, GEM-F6, DS-F3, GRK-F4

Claude Code executors receiving enriched Layer 5 context may call `vault_search` and pull the same documents again, wasting tokens and biasing toward repeated content. The amendment acknowledges the three layers but doesn't manage their interaction. Needs dedup guidance or prompt instructions.

**3. Unverifiable claims — 32% eval score, costs, latency (4/4 reviewers)**
OAI-F15/F20/F21, GEM-F2/F3, DS-F5, GRK-F2

The "32% on cross-domain eval" statistic, the "$0.05-0.20 per Claude Code session" cost range, and the "~1.8s hybrid latency" are used to justify risk assessments but have no source citations. All four reviewers flagged these.

**4. AD-016 needs guardrails (3/4 reviewers)**
OAI-F6, GEM-F7, GRK-F7

"Wherever mechanically feasible" is too broad. Risks: orchestrator prompt bloat, tool-call explosion, security exposure from shell wrappers, blurred orchestrator/executor boundary. Needs admission criteria — at minimum, read-only, bounded latency, bounded output, clear triage/evaluation value.

**5. Task dependencies on TV2-019/TV2-031b undefined in this document (3/4 reviewers)**
GEM-F4, DS-F1, GRK-F3

These tasks exist in the main `tasks.md` (TV2-019 = contract schema, TV2-031b = contract runner) but aren't cross-referenced in the amendment. The TV2-054→TV2-051 dependency is in the task table but missing from the sequencing diagram.

### Unique Findings

**OAI-F1: Excerpt sufficiency for synthesis** — SIGNIFICANT, genuine insight.
The proof case has Tess "reading top 3-5 results" but vault_search returns excerpts/chunks, not full documents. For the book scan case, excerpts may be enough for an index-level response ("here are the books we have"), but for deeper synthesis Tess would need `vault_read`. The amendment should clarify what level of synthesis is expected from excerpts alone.

**OAI-F4: No shared result schema** — SIGNIFICANT, genuine insight.
A tool exposed in multiple contexts (orchestrator, executor) needs stable output semantics: fields, score meaning, excerpt length, truncation markers, error format. Without this, consumers make inconsistent assumptions.

**OAI-F5: Prompt injection from vault content** — SIGNIFICANT, genuine insight.
Vault content injected into prompts could contain imperative text that influences model behavior. The amendment broadens retrieval surface, increasing this risk. Worth a safety note: retrieved content is reference material, not authority.

**OAI-F7: Index freshness not exposed to consumers** — SIGNIFICANT, genuine insight.
If Tess uses search results for routing decisions, stale results can produce false confidence. Tool output should include index `updated_at` so consumers can caveat results.

**OAI-F13: Empty/low-confidence result behavior untested** — SIGNIFICANT, genuine insight.
Search systems fail by returning weak results, not just errors. Tess may over-trust top hits merely because something was returned. Needs acceptance criteria for zero-result and low-score scenarios.

**GEM-F9: Hardcoded Node paths brittle** — MINOR, practical.
Using launchd `EnvironmentVariables` to inject PATH is cleaner than hardcoding the full node module path in the plist.

**GEM-F10: Two wrapper scripts create drift risk** — MINOR, valid.
`knowledge-retrieve.sh` and `vault-search.sh` both wrap QMD. A unified script with flags (`--apply-decay --diversity`) could prevent divergence. Implementation decision, not spec-blocking.

### Contradictions

**Orchestrator tool vs dispatch enrichment: redundant or complementary?**
- GRK-F5 argues they overlap ("violates DRY, confuses when to use hints vs Tess manual search") and suggests collapsing them.
- OAI-F28, GEM-F11, DS-F9 all call the three-layer separation a strength with clean lifecycle mapping.

**Resolution (for human judgment):** The overlap is real but intentional. Orchestrator tool = ad-hoc, operator-driven or evaluation-driven. Dispatch enrichment = anticipated, contract-declared. They fire at different moments for different reasons. GRK's concern is valid about clarity — the amendment should explicitly state when each layer fires and why both are needed.

**Decay/diversity filtering for ad-hoc tools: omit or parametrize?**
- GRK-F6 argues filtering is useful everywhere and should be parametrized.
- DS-F10, OAI say the split is justified but needs clearer documentation of what's omitted and why.

**Resolution (for human judgment):** The current split is reasonable. Decay weighting on interactive queries could hide the most relevant result if it's from an older source. But dedup should probably remain always-on (per OAI-F11).

### Action Items

**Must-fix (blocking stability):**

- **A1** — Add failure semantics section: fail-open behavior, timeout per layer (orchestrator: 3s, dispatch: 5s, executor: 10s), fallback path, error payload schema, observability events for failure/timeout/stale-index/empty-results.
  Source: OAI-F2, GEM-F5, DS-F2, GRK-F4

- **A2** — Add context overlap handling: include file paths in Layer 5 enrichment metadata; instruct Claude Code executor prompt to check Layer 5 before searching; consider `--exclude-paths` parameter for future.
  Source: OAI-F3, GEM-F6, DS-F3, GRK-F4

**Should-fix (significant but not blocking):**

- **A3** — Constrain AD-016 with admission criteria: read-only by default, bounded latency (<5s), bounded output, clear triage/evaluation value, no duplication of executor workflows. Write-capable tools require separate safety review.
  Source: OAI-F6, GEM-F7, GRK-F7

- **A4** — Define vault_search output schema: query, mode, index_timestamp, results[] with path/title/collection/score/excerpt/chunk_id, error schema.
  Source: OAI-F4

- **A5** — Ground unverifiable claims: cite `qmd-mode-evaluation.md` for the 32% stat, `bursty-cost-model.md` for costs, QMD tuning decisions for latency. Mark index stats as "observed 2026-04-04."
  Source: OAI-F15/F20/F21, GEM-F2/F3, DS-F5, GRK-F2

- **A6** — Clarify excerpt sufficiency: vault_search returns chunk-level excerpts suitable for index-level responses. Deep synthesis requires `vault_read` (deferred). Update proof cases to reflect this.
  Source: OAI-F1, GEM-F8

- **A7** — Add safety note: retrieved vault content is reference material, not authority. Models must not treat search results as instructions overriding contract/system policy.
  Source: OAI-F5

- **A8** — Add empty/low-confidence result handling: define behavior for zero results, low-score results, and ambiguous queries. Include in acceptance criteria for proof case tasks.
  Source: OAI-F13

- **A9** — Fix sequencing diagram: add TV2-054→TV2-051 dependency. Cross-reference TV2-019 and TV2-031b as existing tasks in the main task list.
  Source: GEM-F4, DS-F1, GRK-F3

- **A10** — Include index freshness metadata in tool output: `index_updated_at` field in result schema. If stale beyond threshold, tool includes warning.
  Source: OAI-F7

- **A11** — Add search_hints validation constraints: max 5 items, each ≤200 chars, operator-authored only (not model-generated in this amendment).
  Source: OAI-F22, GRK-F8

**Defer (minor or speculative):**

- **A12** — Reclassify TV2-052/TV2-053 domain from "research" to "code" — valid but low-impact for planning.
  Source: OAI-F12, DS-F7

- **A13** — Consider unified wrapper script with flags — implementation decision during TV2-048/TV2-050.
  Source: GEM-F10, GRK-F6

- **A14** — Add acceptance rubrics to proof cases (relevance %, overlap %) — can be defined at task execution time.
  Source: GRK-F9

- **A15** — Add brief Ralph loop explanation parenthetical.
  Source: DS-F8

### Considered and Declined

- **GRK-F5** (collapse orchestrator tool and dispatch enrichment): These serve distinct lifecycle stages — ad-hoc pre-dispatch vs anticipated at-dispatch. The "redundancy" is intentional capability separation. **Reason: `incorrect`** — based on false equivalence between ad-hoc and anticipated queries.

- **OAI-F10** (collection scope / authorization policy): This is a personal system where all vault content is the operator's own data. Per-service collection allowlists add configuration complexity without proportional benefit at current scale. **Reason: `overkill`**

- **OAI-F8** (deterministic query construction strategy): Query construction from description + hints is an implementation detail for the script author, not a spec-level concern. **Reason: `out-of-scope`** — belongs in TV2-050 implementation, not amendment.

- **OAI-F25** (relevance-aware compaction): Adding relevance scoring to the compaction engine is significant complexity. The current "enrichment compacts first" rule is clear and implementable. **Reason: `overkill`**

- **GRK-F10** (timeline estimates in sequencing): Spec amendments define scope and dependencies, not duration estimates. **Reason: `out-of-scope`**

- **OAI-F24** (auto-enrichment without search_hints): Interesting idea but changes the opt-in semantics. A contract with no hints explicitly opts out. If description-only enrichment is valuable, it can be added as a follow-up once the pipeline is validated. **Reason: `overkill`** — adds scope to v1.
