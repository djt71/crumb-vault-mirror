---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/researcher-skill/design/specification.md
artifact_type: spec
artifact_hash: 2db76405
prompt_hash: 5154c3b9
base_ref: null
project: researcher-skill
domain: software
skill_origin: peer-review
created: 2026-02-27
updated: 2026-02-27
reviewers:
  - openai/gpt-5.2
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
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 62638
    attempts: 1
    raw_json: Projects/researcher-skill/reviews/raw/2026-02-27-specification-openai.json
  google:
    http_status: 503
    latency_ms: 3547
    attempts: 3
    error: "503 UNAVAILABLE - model experiencing high demand"
    raw_json: null
  deepseek:
    http_status: 200
    latency_ms: 73710
    attempts: 1
    raw_json: Projects/researcher-skill/reviews/raw/2026-02-27-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 23006
    attempts: 1
    raw_json: Projects/researcher-skill/reviews/raw/2026-02-27-specification-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Researcher Skill Specification

**Artifact:** Projects/researcher-skill/design/specification.md
**Mode:** full
**Reviewed:** 2026-02-27
**Reviewers:** OpenAI (gpt-5.2), DeepSeek (deepseek-reasoner), Grok (grok-4-1-fast-reasoning)
**Failed:** Google (gemini-3-pro-preview) — 503 UNAVAILABLE after 3 attempts
**Review prompt:** Structured review of researcher skill specification evaluating correctness, completeness, internal consistency, feasibility, and clarity. Five targeted questions on fact ledger completeness, convergence criteria implementability, escalation gate integration, task decomposition realism, and write-only-from-ledger failure modes.

---

## OpenAI (gpt-5.2)

### Summary Assessment
The spec is strong on architectural intent (stage separation, evidence discipline, escalation) and provides enough scaffolding to implement a V1. The main weaknesses are (a) underspecified convergence scoring and thresholds, (b) missing integrity constraints in the fact ledger needed to enforce "write-only-from-ledger" mechanically, (c) unclear file storage of retrieved source content required by the citation verifier, and (d) a small internal inconsistency: the verifier stage exists in §3.3 but is not represented in the core stage table/flow in §3.1.

---

### Findings

- **[F1]**
  - **Severity:** CRITICAL
  - **Finding:** Citation Verifier stage is described as consuming a stage budget unit (§3.3) but is missing from the stage definitions table and stage flow diagram in §3.1.
  - **Why:** The dispatch protocol lifecycle depends on explicit stage sequencing; implementers will build the pipeline without the verifier or misplace it, undermining the "mechanical citation integrity" goal.
  - **Fix:** Add "Citation Verification" as an explicit stage between Synthesis and Writing in §3.1 (table + diagram), define its input/output contract (expected files read/written), and include it in convergence/checkpoint logic.

- **[F2]**
  - **Severity:** CRITICAL
  - **Finding:** The citation verifier requires "stored source content" ("semantic match against stored source content"), but the spec never defines where/how FullText content is stored, normalized, or referenced from the ledger.
  - **Why:** Without an explicit source-content artifact, the verifier can only re-fetch (disallowed) or perform a meaningless self-check. This breaks the closed-loop grounding objective.
  - **Fix:** Add an explicit artifact for each source:
    - Store fetched content to `Projects/[project]/research/sources/[source_id].md|.txt` (or `.html` + extracted text).
    - Add fields to `sources[]`: `content_path`, `content_hash` (or `sha256`), `content_extracted_at`, `extract_method`.
    - Require `quote_snippet` to be a substring of stored extracted text for `Verified`.

- **[F3]**
  - **Severity:** CRITICAL
  - **Finding:** "Write-only-from-ledger" is a rule but not enforceable as specified: the Writing stage can still generate uncited factual claims, or cite without deterministic linkage, because there is no required citation format and no machine-checkable constraint tying output claims to `entry_id`s.
  - **Why:** Mechanical integrity requires the system to detect violations automatically, not rely on model compliance.
  - **Fix:** Define an explicit citation form in output, e.g. `[^FL-012]` or `(FL-012)` and require:
    - Every factual sentence (or every paragraph with factual claims) must include ≥1 `FL-###`.
    - Add a "Writing linter" step (could be part of vault-check) that fails the stage if:
      - Any `FL-###` not found in ledger
      - Any ledger `source_id` missing in `sources[]`
      - Any "citation-needed" heuristic triggers (numbers, dates, "according to", superlatives) without `FL-###`

- **[F4]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Convergence criteria are not defined enough to implement: §3.1 references "coverage threshold met per sub-question (see §3.6)" but §3.6 doesn't define how `coverage_score` is computed nor what thresholds apply; §3.4 includes diminishing returns heuristics but those depend on the same undefined score.
  - **Why:** Research Loop termination is core control logic; ambiguity leads to either premature synthesis or runaway loops.
  - **Fix:** Specify:
    - A concrete scoring function (even simple V1):
      - Example: `coverage_score = min(1, weighted_source_support / target_support)` where `weighted_source_support = Σ tier_weight * evidence_quality_weight`
      - Evidence-quality weight could map from confidence: verified=1.0, supported=0.7, plausible=0.4, contested=0.2, unverifiable=0
    - Default thresholds:
      - `covered` if `coverage_score ≥ 0.75` and `tierA_count ≥ 1` (if feasible) and `entries ≥ 2`
    - Contradiction handling rule:
      - If contradictions exist on a key claim, require either escalation or explicit "contested" synthesis section before marking covered.

- **[F5]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The spec defines Tier A/B/C and "weighted convergence scoring," but does not define how tier targets interact with coverage, nor what happens when Tier A is unobtainable (common in V1 due to paywalls / tool limits).
  - **Why:** In practice, many software topics have sparse peer-reviewed sources; rigid Tier A expectations can deadlock the loop or cause excessive escalations.
  - **Fix:** Add explicit fallback policy:
    - If Tier A unavailable after N attempts, allow convergence using Tier B with penalty (cap max score at e.g. 0.8) and require a "quality ceiling" note in synthesis.
    - Encode this in coverage assessment fields: `quality_ceiling_reason`, `tier_a_attempts`.

- **[F6]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The "Minimum evidence before escalation" rule (§3.5) conflicts with time/budget constraints and with some access scenarios (e.g., a single critical Tier A paper that is paywalled). "Attempt at least 2 alternative sources" may be wasted work when the blocked source is uniquely authoritative.
  - **Why:** It can burn budget and still end in escalation; also creates inconsistent operator experience.
  - **Fix:** Make it conditional:
    - If the blocked source is "critical path" (e.g., only primary source referenced by multiple secondary sources), escalate immediately after one failed fetch + one alternate access attempt (e.g., alternate URL/DOI landing page).
    - Add a field in source metadata: `is_critical: bool` with criteria.

- **[F7]**
  - **Severity:** SIGNIFICANT
  - **Finding:** `quote_snippet` length limit (≤500 chars) may be insufficient to support nuanced claims (definitions, multi-part conditions) and encourages over-summarization into "Supported/Plausible."
  - **Why:** The system's evidence discipline relies on quotes; too-short quotes can reduce verification power and increase misinterpretation risk.
  - **Fix:** Allow either:
    - multiple snippets per entry (`quote_snippets: [..]`), or
    - add `quote_context_before/after` or `location` fields (heading/paragraph index) so the verifier can confirm placement in stored content.

- **[F8]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The ledger mixes two concepts: `sources[].ingestion` and `entries[].ingestion_class`. These can drift (entry says FullText, source says AbstractOnly) and the spec doesn't define which is authoritative or whether mismatch is allowed.
  - **Why:** Integrity of confidence requirements ("Verified requires FullText") depends on consistent ingestion classification.
  - **Fix:** Remove `entries[].ingestion_class` (derive from source) *or* enforce invariant:
    - `entries[].ingestion_class MUST equal sources[source_id].ingestion at time of entry creation`
    - If source ingestion is upgraded later (AbstractOnly → FullText), entries can be re-verified and updated with an audit trail.

- **[F9]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Append-only ledger conflicts with later verification corrections: verifier may need to downgrade confidence, fix quotes, or reclassify sources. The spec calls it "append-only" but also describes flags that imply mutation/repair ("over-confidence flag resolved").
  - **Why:** Without a mutation/audit model, implementations will silently edit entries (losing provenance) or ignore verifier output.
  - **Fix:** Define an explicit audit mechanism:
    - Either allow controlled edits with `revision_history` per entry, or
    - keep append-only but add `supersedes: FL-###` and create new corrected entries, marking old ones `status: deprecated`.

- **[F10]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Contradiction modeling is underpowered: `contradicts: [FL-NNN]` exists, but there's no requirement to provide a "topic/claim key" to cluster contradictions, and no rule for how synthesis should treat contested clusters.
  - **Why:** Contradictions are one of the main escalation triggers and a key output quality dimension; without structure, synthesis becomes ad hoc.
  - **Fix:** Add fields:
    - `claim_key` (stable normalized identifier for "same claim" across sources)
    - `stance: supports|refutes|mixed`
    - In synthesis output, require a section per `claim_key` with stance counts weighted by tier.

- **[F11]**
  - **Severity:** MINOR
  - **Finding:** Some stage naming/definition blur: "Research Loop stages iterate... after each loop iteration, the planning stage's convergence criteria are re-evaluated" but Planning is a separate stage; unclear whether Planning is re-run or whether Research Loop computes and updates coverage itself.
  - **Why:** Implementation clarity: do you spawn another Planning stage or keep logic inside Research Loop?
  - **Fix:** Specify one approach for V1:
    - Option A: Planning runs once; Research Loop updates handoff coverage and decides next sub-question.
    - Option B: Insert lightweight "Replan" stage (counts as stage) after each loop. Document in stage table.

- **[F12]**
  - **Severity:** MINOR
  - **Finding:** Vault integration references `obsidian tag name=kb/[topic]` as if it's a query primitive; unclear if this is an actual tool, a convention, or pseudocode.
  - **Why:** Implementers may not know how to perform the vault search within Claude Code environment.
  - **Fix:** Replace with concrete mechanism available in Crumb: file glob + grep/ripgrep for `#kb/` tags, or whatever the OS provides; document the exact method.

- **[F13]**
  - **Severity:** STRENGTH
  - **Finding:** The spec cleanly separates concerns: scoping/planning/research/synthesis/writing, with explicit handoff size constraints and vault artifacts.
  - **Why:** This matches the dispatch protocol model and materially improves resumability and debuggability.

- **[F14]**
  - **Severity:** STRENGTH
  - **Finding:** Source ingestion classification (FullText/AbstractOnly/SecondaryCitation/ToolLimited) is a practical and implementable way to prevent overclaiming under tool limitations.
  - **Why:** It operationalizes "closed-loop grounding" with realistic constraints (paywalls/JS-heavy pages).

- **[F15]**
  - **Severity:** STRENGTH
  - **Finding:** Escalation gates are well-scoped and align with real failure modes (scope ambiguity, access barriers, contradictions, high-impact claims), and the "batch escalation" discipline is a good usability constraint.
  - **Why:** It prevents escalation spam and integrates well with structured operator control.

### UNVERIFIABLE CLAIM flags

- **[F16]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** "The dispatch protocol (CTB-016) is complete — provides stage lifecycle, budget enforcement, structured escalation, and stage I/O contracts." (F1)
  - **Why:** This spec critically depends on CTB-016 semantics; if CTB-016 differs, integrations (budgets, gate types, schemas) may break.
  - **Fix:** Add an appendix summarizing the exact CTB-016 fields used (stage schema keys, budget warning signal format, escalation payload schema), or link with pinned version/hash and include minimal excerpts needed for implementation.

- **[F17]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** "Claude Code provides built-in `WebSearch` and `WebFetch` tools for source gathering." (F2)
  - **Why:** Tool availability/behavior (timeouts, JS rendering limits) is foundational to V1 feasibility.
  - **Fix:** In implementation docs, add a tool capability matrix verified in the target runtime (max content size, supported MIME types, typical failure codes).

- **[F18]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** "Vault structure supports knowledge notes (`Sources/[type]/`), source indices, and `#kb/` tagged documents per file-conventions.md." (F3)
  - **Why:** Vault paths and conventions drive all file routing and the "vault-check passes" acceptance criteria.
  - **Fix:** Quote the required frontmatter schema and canonical paths from `file-conventions.md` into this spec (or reference a pinned revision).

- **[F19]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** "No MCP source tools exist yet." (F4) and the MCP timeline assumptions (U-4).
  - **Why:** Affects whether V2 planning should be designed now or deferred; also impacts access gate frequency assumptions.
  - **Fix:** Record current MCP tool inventory in Crumb as of a date + owner, so this statement is auditable.

- **[F20]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** The cited documents: `design/citation-verification-gap-findings.md`, `design/perplexity-deep-research.md`, and CTB-016 path `Projects/crumb-tess-bridge/design/dispatch-protocol.md` exist and contain the described conclusions.
  - **Why:** The spec uses these as justifications and dependencies.
  - **Fix:** Add doc identifiers (commit hash/path hash) or embed key conclusions as "Design Inputs" section with quotes.

### Answers to the 5 Specific Reviewer Questions

**1) Is the fact ledger schema (§3.6) complete enough for the citation grounding goals in §3.3? What's missing?**
Not fully. It's close, but missing fields/constraints needed for mechanical verification. Key missing elements: stored source content reference (`content_path`, `content_hash`, extraction timestamp/method); deterministic citation linkage from writing output to `entry_id` (format + linter); entry location info (optional but valuable); audit/revision model to reconcile "append-only" with verifier-driven corrections; invariants (enforced constraints): `Verified => FullText`, entry source must exist, quote must be substring of stored content for Verified.

**2) Are the convergence criteria (§3.1) well-defined enough to implement? What ambiguities remain?**
They are directionally defined but not implementable as-is because: `coverage_score` has no formula; no default thresholds per sub-question or overall; no policy for Tier A unavailability; contradictions: unclear whether contradictions prevent convergence or simply mark "contested" and proceed.

**3) Does escalation gate design (§3.5) properly consume the dispatch protocol framework, or are there integration gaps?**
Conceptually yes (structured gate types, confirm/choice only, batching, 3-question limit), but there are likely integration gaps because CTB-016 specifics are not present here. Need exact payload schema for `gate_type`, `questions[]`, and how to represent answer choices. Need to specify how an escalation updates handoff state. Need a rule for escalation timeout behavior.

**4) Is phased task decomposition (§5) realistic? Missing tasks or mis-ordered dependencies?**
Mostly realistic. Missing/mis-ordered items: add explicit task to store and index fetched source content (required for verifier) before implementing verifier; add task to implement writing output linter/vault-check; consider "replan/update coverage" task.

**5) What failure modes could circumvent write-only-from-ledger?**
Main bypass risks: uncited factual prose in deliverable (no mechanical check); ledger entries that are themselves hallucinated (fake quote snippets); overbroad "Plausible" usage; secondary citation laundering; source/entry mismatch drift.

---

## Google (gemini-3-pro-preview)

**DISPATCH FAILED** — HTTP 503 (UNAVAILABLE) after 3 attempts. Model experiencing high demand. No review collected.

---

## DeepSeek (deepseek-reasoner)

### Overall Assessment
A comprehensive, well-structured specification that addresses critical research pipeline challenges. The architectural decisions (single-agent, fact ledger, stage separation) are sound and grounded in prior analysis. The document demonstrates strong internal consistency and clear problem-solution mapping. Several areas require refinement for implementation, particularly around convergence logic and failure mode resilience.

---

### Findings

**F1**
- **Severity**: SIGNIFICANT
- **Finding**: The fact ledger schema (§3.6) is missing fields necessary for robust citation grounding and potential duplicate detection.
- **Why**: Without a `quote_context` field (larger surrounding text) or `page_number`/`section` reference, the Citation Verifier pass cannot reliably perform "semantic match" verification. No unique constraint on `statement`+`source_id` could lead to duplicate entries.
- **Fix**: Add `quote_context: string (≤2000 chars)` and `location_in_source: string | null` fields. Add a uniqueness note: entries with identical `statement` and `source_id` should be merged or flagged as duplicates.

**F2**
- **Severity**: CRITICAL
- **Finding**: Convergence criteria for the Research Loop (§3.1, §3.6) are underspecified. Terms like "coverage threshold met per sub-question" and "coverage_score" lack operational definitions.
- **Why**: Implementation cannot proceed without a concrete formula for `coverage_score` or a decision procedure for when a sub-question is "covered." The dependency on U-2 (optimal convergence thresholds) is acknowledged but creates a circular specification.
- **Fix**: Define `coverage_score` as a weighted sum: `(source_count_tier_a * 1.0 + source_count_tier_b * 0.7 + source_count_tier_c * 0.4) / target_total_weight`. Set initial "coverage threshold" to 0.7. Provide explicit decision tree in Planning stage.

**F3**
- **Severity**: SIGNIFICANT
- **Finding**: Escalation gate design (§3.5) references dispatch protocol CTB-016 but does not specify how the researcher skill's `gate_type` values (`scope`, `access`, `conflict`, `risk`) map to the protocol's expected `gate_type` enumeration.
- **Why**: Potential integration failure if the dispatch protocol defines a different set of allowed gate types. The "batch escalation" rule (up to 3 questions) conflicts with the protocol's §6.2 limit if not carefully aligned.
- **Fix**: Explicitly map researcher gate types to protocol gate types (likely `choice` or `confirm`). Clarify that batching counts questions, not triggers, and must respect the protocol's per-escalation question limit.

**F4**
- **Severity**: SIGNIFICANT
- **Finding**: Phased task decomposition (§5) is logically sound but underestimates integration complexity and misses critical validation tasks.
- **Why**: Phase 1 (core pipeline) lacks a task for stage handoff I/O implementation. Phase 2 lacks performance validation under context limits (U-5). The Synthesis stage (RS-014) depends on a complete ledger, but its placement in Phase 3 after verification (Phase 2) creates a logical misordering.
- **Fix**: Add tasks: RS-005b "Implement handoff schema serialization/deserialization" in Phase 1. Move RS-014 (Synthesis) to Phase 2, before verification (RS-007). Add Phase 4 task: "Validate pipeline within default context window using simulated ledger growth."

**F5**
- **Severity**: SIGNIFICANT
- **Finding**: The write-only-from-ledger discipline has a critical failure mode: a malicious or compromised stage could inject false entries into the fact ledger, poisoning all downstream stages.
- **Why**: The ledger is append-only but lacks integrity verification. A single erroneous Research Loop stage could insert plausible but fabricated `quote_snippet` entries with `confidence: verified`. The Citation Verifier pass only checks internal consistency, not source authenticity.
- **Fix**: Implement a checksum or hash for each ledger entry calculated from `source_id` + `quote_snippet` + `timestamp`. The Writing stage should verify entry hashes against a read-only snapshot taken after verification pass.

**F6**
- **Severity**: MINOR
- **Finding**: Source scoring dimensions (§3.2) include "Methodology" but provide no guidance on how to determine methodology from a web source during automated ingestion.
- **Why**: This is likely unfeasible for V1 without MCP tools or NLP analysis. Expecting a `claude --print` invocation to reliably classify "Empirical study" vs. "Expert analysis" from fetched web text is optimistic.
- **Fix**: Simplify methodology to `Known` (if stated in source metadata) or `Unknown`. Remove methodology as a primary tiering factor for V1; rely on Authority + Venue only.

**F7**
- **Severity**: STRENGTH
- **Finding**: The specification's problem statement (§1) and facts/assumptions (§2) are exceptionally clear and grounded. The explicit linkage to prior art (F5, F6) and acknowledgment of unknowns builds strong credibility.
- **Why**: This establishes a solid foundation for implementation and sets realistic expectations for V1 capabilities.

**F8**
- **Severity**: STRENGTH
- **Finding**: The stage I/O contract and researcher-specific handoff schema (§3.1) are well-designed for extensibility and clarity. The separation of `handoff` (≤8KB) and `vault files` elegantly manages context budget.
- **Why**: This pattern ensures stage transitions are lightweight yet preserve necessary state.

**F9**
- **Severity**: SIGNIFICANT
- **UNVERIFIABLE CLAIM**: References to specific documents (`design/citation-verification-gap-findings.md`, `design/perplexity-deep-research.md`, `file-conventions.md`) and protocol CTB-016 cannot be independently verified.
- **Why**: The specification's validity partially depends on these artifacts existing and containing the claimed content.
- **Fix**: Ensure referenced documents are accessible to reviewers. Consider adding brief summaries or direct quotes of key conclusions in an appendix.

**F10**
- **Severity**: MINOR
- **Finding**: The "Three-tier source classification" (A/B/C) uses a default weight of 0.4 for Tier C (community/secondary). This may be too low for fast-moving domains.
- **Why**: For software frameworks, security vulnerabilities, community sources often provide more accurate and timely information than academic sources.
- **Fix**: Adjust default Tier C weight to 0.6, or make weights configurable per research brief based on domain.

### Answers to Specific Questions

**1. Fact ledger schema completeness:**
The schema is mostly complete but lacks two fields for robust grounding: `quote_context` (expanded snippet for verification) and `location_in_source`. It also needs a uniqueness constraint to prevent duplicate evidence entries.

**2. Convergence criteria implementability:**
Not well-defined enough. The core ambiguity is the `coverage_score` calculation and the threshold for "met." Without a formula and numerical threshold, the Research Loop cannot make automated termination decisions.

**3. Escalation gate integration:**
Likely proper but underspecified. The gate types appear compatible with the dispatch protocol's `choice`/`confirm` question types. The integration gap is the explicit mapping of researcher gate types to protocol gate types.

**4. Task decomposition realism:**
Mostly realistic but missing integration tasks. The critical missing tasks are handoff I/O implementation and context budget validation. The misordering of Synthesis stage (should be before verification) is a notable issue.

**5. Write-only-from-ledger failure modes:**
Ledger injection (fabricated entries); handoff manipulation (tampered ledger path); schema exploitation (ungrounded claims in `notes` field); confidence laundering (marking `ToolLimited` as `verified` before verification pass).

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: Convergence criteria for Research Loop (§3.1 table) vaguely stated as "Coverage threshold met per sub-question (see §3.6)", but §3.6 (fact ledger) defines no explicit thresholds, formulas, or metrics for "coverage threshold". Handoff schema mentions "coverage_score": "number 0-1 — evidence coverage" and "overall_score", but computation (e.g., weighted by source tiers?) is undefined.
- [Why]: Implementers cannot reproducibly terminate loops without precise, algorithmic criteria. Risks runaway loops or premature termination, undermining feasibility and consistency. Directly impacts key decision #3 (weighted convergence scoring).
- [Fix]: Define explicit formula in §3.1 or new §3.6.1, e.g., "coverage_score = (sum(source_count * tier_weight for tier A=1.0,B=0.7,C=0.4) / tier_a_target) per sub_question, threshold=0.8". Add to handoff validation.

- [F2]
- [Severity]: CRITICAL
- [Finding]: Fact ledger source schema (§3.6) lacks field for full source content or fetched text storage. Entries have only "quote_snippet" (≤500 chars). Citation Verifier (§3.3) requires "semantic match against stored source content" for re-checking "verified" entries, but no stored content exists to match against.
- [Why]: Breaks core citation grounding (key decision #2, #4, #5). Verifier cannot function, allowing ungrounded "verified" claims. Violates mechanical integrity promise.
- [Fix]: Add optional "full_content: string | null" or "content_hash: string" to sources; require storing fetched text in separate files (e.g., `fact-ledger-[id]/sources/[source_id].txt`) referenced by path. Update verifier to load and compare.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: Specific question 1: Fact ledger schema (§3.6) is incomplete for §3.3 goals. Missing: (1) uniqueness constraints (e.g., entry_id collision prevention); (2) source full-text reference (as F2); (3) multi-quote support per source/entry (one statement per entry limits granularity); (4) temporal versioning (entries lack "versioned_source_id" for updates); (5) quantitative support strength (e.g., "snippet_length" or "relevance_score 0-1").
- [Why]: Schema gaps allow duplicate/incoherent entries, unverifiable quotes, and weak confidence scoring. Undermines write-only-from-ledger and verifier.
- [Fix]: Add fields: "unique_by: [statement_hash, source_id]"; "related_entries: []"; "support_strength: 0-1"; require "source_file_path". Enforce via stage I/O validation.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Research Loop iteration logic (§3.1 flow) ambiguous: "after each loop iteration, the planning stage's convergence criteria are re-evaluated". But Planning is a one-time stage pre-loop; no mechanism described for re-invoking Planning mid-pipeline.
- [Why]: Breaks stage-separated flow (key decision #1). Pipeline cannot dynamically loop without ad-hoc re-planning, risking state loss or infinite recursion.
- [Fix]: Clarify: Post-Research Loop, dispatch injects handoff to a "Re-Planning" micro-stage (budget-aware) or embed convergence eval in Research Loop output to auto-advance/spawn next Loop.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Specific question 2: Convergence criteria (§3.1) not well-defined for implementation. No numerical thresholds (e.g., min source_count=3 Tier A), no contradiction threshold (e.g., >20% contested entries blocks), no gap severity ranking. "Diminishing returns" (§3.4: <2 entries AND <0.05 score) partial but score undefined.
- [Why]: Leads to inconsistent termination across dispatches, violating "mechanical citation integrity".
- [Fix]: Add table in §3.1: e.g., | Criterion | Threshold |; Per sub_q: tier_a >=2 OR (score>=0.7); overall: gaps.length==0.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Escalation gates (§3.5) define custom `gate_type` values ("scope", "access", "conflict", "risk") but CTB-016 §6 unspecified here — potential mismatch if dispatch only supports fixed types (e.g., generic "confirm").
- [Why]: Specific question 3: Integration gap risks escalation failures. Pipeline halts on invalid gate_type.
- [Fix]: Confirm CTB-016 supports custom types or map to standard (e.g., all as "confirm" with prefixed questions). Add validation: "gate_type inherits from CTB-016 §6 enums".

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Specific question 5: Write-only-from-ledger circumventable by: (1) Synthesis stage hallucinating ledger entries (pre-Writing); (2) LLM in Writing "recalling" non-ledger facts as "ledger-backed"; (3) handoff tampering (e.g., fake entry_ids); (4) verifier skipped on budget exhaustion; (5) vault pre-population with fake ledgers.
- [Why]: Core hallucination prevention (key decision #2) fails without enforcement beyond instructions. Models routinely ignore "only cite X".
- [Fix]: Add runtime checks: Writing stage parses ledger upfront, generates citations from entry_ids only (template-driven); fail if >0 unmapped citations.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: Vault integration (§3.8): Scoping queries use vague globs/tags (e.g., `obsidian tag name=kb/[topic]`), no deduping or relevance scoring for existing knowledge.
- [Why]: Risks redundant research or missing contradictions (contra F3 goal). Incomplete as input baseline.
- [Fix]: Define query protocol: e.g., "vector search vault via #kb/[topic] similarity>0.8"; add "vault_coverage_score" to handoff.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Facts F1-F8 reference external docs/tools (CTB-016, `design/citation-verification-gap-findings.md`, Perplexity analysis, Claude Code `WebSearch`/`WebFetch`, vault structures) without excerpts or links. E.g., F2 assumes tools exist but unconfirmed.
- [Why]: Spec built on ungrounded assumptions; risks incorrectness if deps changed/missing.
- [Fix]: Inline key excerpts or hyperlinks; mark as "PENDING VERIFICATION".

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Budget enforcement (§3.4): "Research loop cap: default 5" internal, but no enforcement mechanism (e.g., Planning sets it, but who checks?). Warning at ≤20% ignores researcher override (brief sets 15-20).
- [Why]: Feasibility risk: overruns dispatch budget (U4). Key decision #1 (single-agent) amplifies.
- [Fix]: Planning writes `max_iterations` to handoff/ledger; Research Loop stage counter injected by dispatch runner.

- [F11]
- [Severity]: MINOR
- [Finding]: Handoff schema (§3.1) uses "status": "open | covered | blocked" but no transition rules (e.g., when to set "covered").
- [Why]: Clarity gap for implementers; minor inconsistency risk.
- [Fix]: Add enum transitions table: open -> covered if score>=thresh.

- [F12]
- [Severity]: MINOR
- [Finding]: Dates "2026-02-27" throughout — futuristic, potential placeholder error.
- [Why]: Clarity; confuses real-world deployment.
- [Fix]: Use current date or "TBD".

- [F13]
- [Severity]: MINOR
- [Finding]: Task decomposition (§5): RS-014 (Synthesis) after RS-011 (escalations), but Synthesis consumes ledger from RS-004/6 — dependency inversion.
- [Why]: Specific question 4: Minor mis-order; risks phased build issues.
- [Fix]: Reorder Phase 3: Synthesis/Writing before escalations or note deps.

- [F14]
- [Severity]: STRENGTH
- [Finding]: Phased task decomposition (§5) realistic and complete for V1 (A2-A9); risks/acceptance criteria per task; defers high-risk MCP (A8).
- [Why]: Supports feasibility; clear path despite complexity (specific question 4).

- [F15]
- [Severity]: STRENGTH
- [Finding]: Source tiers (§3.2) and confidence taxonomy (§3.3) tightly integrated with weighting/verifier — implements key decisions #3/#4 crisply.
- [Why]: Strong foundation for evidence quality; tables enhance clarity.

- [F16]
- [Severity]: STRENGTH
- [Finding]: Escalation discipline (§3.5: min evidence, batching, budget awareness) maturely consumes dispatch protocol.
- [Why]: Addresses specific question 3 positively; prevents abuse (key decision #6).

---

## Synthesis

### Consensus Findings

**1. Missing source content storage** (OAI-F2, GRK-F2, DS-F1)
All three reviewers independently flagged the same critical gap: the Citation Verifier (§3.3) requires "semantic match against stored source content" but the spec never defines where or how full-text content is stored. Without an explicit source content artifact, the verifier cannot function — it would have to re-fetch (which is disallowed) or perform a meaningless self-check.

**2. Convergence criteria underspecified** (OAI-F4, DS-F2, GRK-F1, GRK-F5)
All three reviewers agreed that `coverage_score` has no formula, no default thresholds, and no fallback policy for when Tier A sources are unavailable. The Research Loop termination logic is directionally defined but not implementable as written. All three proposed similar remedies: a weighted-sum formula based on tier weights and entry counts, with a numerical threshold (suggested 0.7-0.8).

**3. Escalation gate type mapping unclear** (DS-F3, GRK-F6, OAI Q3 answer)
The spec defines researcher-specific gate types (`scope`, `access`, `conflict`, `risk`) but doesn't explicitly map them to the dispatch protocol's `gate_type` enumeration. All three reviewers flagged this as an integration risk — if CTB-016 defines a fixed set of allowed gate types, researcher-specific types could fail validation.

**4. Fact ledger schema gaps** (OAI-F7, OAI-F8, DS-F1, GRK-F3)
Multiple reviewers identified schema-level gaps: duplicate `ingestion_class` fields across sources and entries (OAI-F8), missing `quote_context`/`location_in_source` for verifier support (DS-F1, GRK-F3), no uniqueness constraints (GRK-F3), and quote snippet length limits that may be insufficient (OAI-F7).

**5. Write-only-from-ledger not mechanically enforced** (OAI-F3, GRK-F7)
Two reviewers identified that the write-only-from-ledger discipline is a stated rule but has no mechanical enforcement. There's no required citation format linking output claims to `entry_id`s, no linter to detect violations, and the rule relies on model compliance rather than structural checks.

**6. Research Loop re-planning ambiguous** (OAI-F11, GRK-F4)
Two reviewers flagged that the spec says "the planning stage's convergence criteria are re-evaluated" after each Research Loop iteration, but Planning is defined as a one-time stage. No mechanism is described for re-invoking Planning mid-pipeline. The spec needs to clarify: does the Research Loop stage evaluate convergence internally, or is there a lightweight re-plan stage?

### Unique Findings

**OAI-F1 — Citation Verifier missing from stage table** (CRITICAL)
Only OpenAI caught this, but it's a genuine structural gap: the verifier is described in §3.3 as consuming a stage budget unit but is absent from the stage definitions table and flow diagram in §3.1. This is a straightforward omission that should be fixed.

**OAI-F6 — Min evidence before escalation conflicts with critical-path sources** (SIGNIFICANT)
Genuine insight. The "attempt at least 2 alternative sources" rule wastes budget when the blocked source is uniquely authoritative (e.g., a single seminal paper behind a paywall). A conditional exception for critical-path sources is practical.

**OAI-F9 — Append-only vs. verification corrections contradiction** (SIGNIFICANT)
Genuine insight. The ledger is described as "append-only" but the verifier needs to downgrade confidence, resolve flags, and correct entries. This creates an implicit mutation requirement that conflicts with the append-only claim. Needs an explicit audit/mutation model.

**OAI-F10 — Contradiction modeling underpowered** (SIGNIFICANT)
Genuine insight. The `contradicts: [FL-NNN]` field exists but there's no `claim_key` to cluster contradictions or structured stance tracking. Without this, synthesis treats contradictions ad hoc rather than systematically.

**DS-F6 — Methodology classification unfeasible for V1** (MINOR)
Genuine insight. Expecting automated classification of "Empirical study" vs. "Expert analysis" from web-fetched text is optimistic for V1. Simplifying to Known/Unknown and relying on Authority + Venue for tiering is pragmatic.

**GRK-F10 — Budget enforcement for research loop cap** (SIGNIFICANT)
Genuine insight. The Planning stage declares `max_research_iterations` but no enforcement mechanism is described. The handoff should carry the cap, and the Research Loop stage must check it.

### Contradictions

**Task ordering:** DS-F4 proposes moving Synthesis (RS-014) to Phase 2 before verification, arguing it creates a logical misordering. GRK-F13 also flags RS-014 ordering but proposes putting Synthesis/Writing before escalations. OAI's Q4 answer suggests adding new tasks for source storage and writing linting. These agree a task ordering problem exists but disagree on the specific fix. Recommend: keep Synthesis in Phase 3 (it genuinely depends on escalation handling for scope changes) but reorder within Phase 3 to ensure Synthesis precedes Writing, and add the missing tasks per A10.

### Action Items

**Must-fix** — critical or consensus issues:

- **A1** (OAI-F2, GRK-F2, DS-F1): **Add source content storage.** Define a source content artifact (`Projects/[project]/research/sources/[source_id].md`). Add `content_path` and `content_hash` fields to source metadata. Require Research Loop stages to store fetched content. Update the Citation Verifier to match quotes against stored content.

- **A2** (OAI-F4, OAI-F5, DS-F2, GRK-F1, GRK-F5): **Define convergence scoring formula and thresholds.** Specify a concrete `coverage_score` computation (weighted sum of tier-weighted source counts). Set a default threshold (e.g., 0.7). Define a Tier A fallback policy (allow convergence with Tier B at a reduced quality ceiling). Add to §3.1 or a new §3.6.1.

- **A3** (OAI-F1): **Add Citation Verifier to stage definitions table and flow diagram in §3.1.** It's described in §3.3 but missing from the core stage architecture.

- **A4** (OAI-F3, GRK-F7): **Define mechanical write-only-from-ledger enforcement.** Specify a required citation format (e.g., `[^FL-NNN]`) in deliverables. Add a writing validation step that checks: every citation resolves to a ledger entry, every factual claim has a citation, no orphan entry IDs.

**Should-fix** — significant but not blocking:

- **A5** (DS-F3, GRK-F6): **Clarify escalation gate type mapping.** Explicitly confirm that the dispatch protocol's `gate_type` enum includes `scope`, `access`, `conflict`, `risk` — or map researcher types to the protocol's supported types.

- **A6** (OAI-F9): **Resolve append-only vs. verification corrections.** Define an explicit audit model: either allow controlled edits with `revision_history` per entry, or keep append-only with `supersedes: FL-NNN` corrective entries.

- **A7** (OAI-F11, GRK-F4): **Clarify Research Loop convergence evaluation.** Specify that the Research Loop stage evaluates convergence internally using handoff data (not by re-invoking Planning). Planning runs once; the Research Loop carries the convergence logic forward.

- **A8** (OAI-F8): **Resolve ingestion_class duplication.** Either remove `entries[].ingestion_class` (derive from source) or enforce an invariant: entry ingestion_class MUST equal source ingestion at time of creation.

- **A9** (OAI-F10): **Add contradiction modeling fields.** Add `claim_key` for clustering contradictions and `stance: supports|refutes|mixed` per entry. Require synthesis to produce a section per contested claim_key.

- **A10** (DS-F4, GRK-F13): **Add missing tasks to decomposition.** Include: source content storage task (Phase 1), writing validation/linter task (Phase 2), handoff I/O task (Phase 1). Reorder RS-014 (Synthesis) and RS-015 (Writing) to ensure Synthesis precedes Writing within Phase 3.

- **A11** (OAI-F6): **Add critical-path exception to min-evidence-before-escalation.** If the blocked source is uniquely authoritative (referenced by multiple secondary sources), allow immediate escalation after one failed fetch + one alternate access attempt.

**Defer** — minor or revisit later:

- **A12** (OAI-F7, DS-F1): **Quote snippet enhancement.** Consider multi-quote support or `quote_context` field after V1 validates the base pattern.

- **A13** (DS-F6): **Simplify methodology classification for V1.** Reduce to Known/Unknown; rely on Authority + Venue for tiering.

- **A14** (GRK-F11): **Add handoff status transition rules.** Define when sub-question status transitions (open → covered, open → blocked). Add during implementation.

- **A15** (GRK-F10): **Define budget enforcement mechanism for research loop cap.** Planning writes `max_iterations` to handoff; Research Loop checks against it. Add during implementation.

- **A16** (DS-F10): **Configurable Tier C weights.** Revisit whether 0.4 is too low based on domain-specific usage patterns.

### Considered and Declined

- **GRK-F12** (dates "futuristic" — 2026): `incorrect`. 2026-02-27 is the current date. Not a placeholder.

- **DS-F5** (ledger injection/integrity hashing): `overkill`. This is a single-operator system with governed sessions. Each stage runs under CLAUDE.md governance with fresh verification. Cryptographic entry hashing adds complexity without proportional benefit for V1. Worth revisiting only if the skill runs in adversarial or multi-tenant contexts.

- **OAI-F16-F20, DS-F9, GRK-F9** (unverifiable claims — referenced documents): `constraint`. The referenced documents (`citation-verification-gap-findings.md`, `perplexity-deep-research.md`, CTB-016, `file-conventions.md`) all exist in the vault and were read during spec authoring. External reviewers cannot access vault files — these claims are internally verifiable. Adding inline excerpts would bloat the spec without improving internal clarity.

- **GRK-F8** (vault integration queries vague — suggests "vector search"): `incorrect`. `obsidian tag name=kb/[topic]` is a real CLI command in the Crumb system (Obsidian CLI skill). The vault uses CLI-based indexed queries, not vector similarity search. The query method is correctly specified for the target system.
