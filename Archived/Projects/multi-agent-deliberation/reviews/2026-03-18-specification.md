---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/multi-agent-deliberation/design/specification.md
artifact_type: spec
artifact_hash: 430edeef
prompt_hash: 2097fca5
base_ref: null
project: multi-agent-deliberation
domain: software
skill_origin: peer-review
created: 2026-03-18
updated: 2026-03-18
status: active
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
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 86883
    attempts: 1
    raw_json: Projects/multi-agent-deliberation/reviews/raw/2026-03-18-specification-openai.json
  google:
    http_status: 200
    latency_ms: 48564
    attempts: 1
    raw_json: Projects/multi-agent-deliberation/reviews/raw/2026-03-18-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 67210
    attempts: 1
    raw_json: Projects/multi-agent-deliberation/reviews/raw/2026-03-18-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 29968
    attempts: 1
    raw_json: Projects/multi-agent-deliberation/reviews/raw/2026-03-18-specification-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Multi-Agent Deliberation Specification

**Artifact:** Projects/multi-agent-deliberation/design/specification.md
**Mode:** full
**Reviewed:** 2026-03-18
**Reviewers:** GPT-5.4, Gemini 3.1 Pro, DeepSeek V3.2, Grok 4.1 Fast

---

## OpenAI (gpt-5.4)

- [F1]
- [Severity]: STRENGTH
- [Finding]: The spec has a strong experimental spine: explicit hypotheses, phased gates, abort criteria, and a clear distinction between experimental infrastructure and future integration.
- [Why]: This prevents premature system coupling and makes the project falsifiable rather than aspirational.
- [Fix]: None.

- [F2]
- [Severity]: STRENGTH
- [Finding]: Reusing the peer-review dispatch pattern is a sound design choice. The reuse boundary is mostly well chosen: dispatch mechanics are reused while deliberation gets its own config, schema, and output format.
- [Why]: This reduces implementation risk and leverages already-proven concurrency, safety, and response-collection paths.
- [Fix]: None.

- [F3]
- [Severity]: STRENGTH
- [Finding]: Treating the assessment schema as a stable inter-agent message contract is a good architectural decision.
- [Why]: It cleanly decouples transport evolution from evaluator semantics and supports later migration from relay to shared-artifact or bus patterns.
- [Fix]: None.

- [F4]
- [Severity]: STRENGTH
- [Finding]: The communication architecture section correctly presents relay -> shared artifact -> bus -> direct P2P as a spectrum rather than a binary choice.
- [Why]: That framing is realistic and avoids overcommitting to a complex transport before the core value proposition is proven.
- [Fix]: None.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: The hypothesis framework is directionally rigorous, but several success criteria are still too subjective to be reliably evaluated. Terms like "qualitatively different analytical frames," "genuinely useful," "wouldn't have identified," and "novel insights" rely almost entirely on Danny's judgment without an operational rubric.
- [Why]: A solo-operator experiment can use judgment calls, but without a scoring rubric the gates are vulnerable to hindsight bias, inconsistency across phases, and confirmation bias.
- [Fix]: Add a lightweight evaluation rubric with explicit scales for novelty, utility, actionability, and distinctness. Example: 0-2 for novelty, 0-2 for utility, 0-2 for actionability, with threshold definitions and examples.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: H1 conflates verdict variance with useful diversity. A spread of >=2 points on a 5-point verdict scale may indicate useful disagreement, but it can also reflect noise, instability, or prompt/provider artifacts.
- [Why]: If variance is treated as success by itself, the experiment may reward inconsistency rather than better analysis.
- [Fix]: Split H1 into two measures: (1) variance existence and (2) variance quality. Require that divergent verdicts also correspond to materially distinct evidence or reasoning categories, not just rating spread.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: H2 is the core hypothesis, but the proposed comparison is not fully controlled. Condition (a) uses same model + different overlays; condition (b) uses different models + same overlay; condition (c) changes both at once. This makes attribution difficult, especially if panel outputs differ in length, style, or prompt budget.
- [Why]: If condition (c) wins, you still won't know whether the gain came from interaction effects, model quality differences, role fit, or simple token volume.
- [Fix]: Add normalization controls: same output length targets, same artifact set, fixed evaluation template, and a predefined "unique finding" counting method. Consider a fourth condition using different models + different overlays but with randomized role/model assignments.

- [F8]
- [Severity]: CRITICAL
- [Finding]: The spec does not define a reproducible method for identifying "unique findings" across conditions or passes.
- [Why]: H2, H3, H4, and H5 all depend on counting novel or unique findings. Without a coding method, the primary evidence for success is not reproducible even by the same reviewer later.
- [Fix]: Define a finding extraction protocol. For example: each assessment is decomposed into atomic findings with tags such as market, execution, cost, timing, risk, personal fit, architecture. A finding is "unique" only if no prior assessment in the comparison set contains the same tagged claim at equivalent specificity.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: The experimental protocol lacks a baseline against Danny-alone and a baseline against a single strong model with a carefully designed multi-lens prompt.
- [Why]: H5 asks whether the framework adds value beyond what Danny or a single LLM would produce, but the experiment does not systematically measure those baselines.
- [Fix]: Add explicit baseline arms: (1) Danny-alone artifact review, time-boxed; (2) single-model multi-lens prompt using the same schema; (3) possibly single-model two-pass self-critique. Compare unique findings and actionability against these baselines.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: The use of warm artifacts with known value assessments is practical, but it risks contamination if overlays, prior notes, or model training data already bias outputs toward known conclusions.
- [Why]: Warm artifacts are useful for development, but they are weak evidence for validating novelty or generalization.
- [Fix]: State more explicitly that warm artifacts are only for protocol shakedown and that gate decisions should be weighted primarily toward cold-artifact performance.

- [F11]
- [Severity]: CRITICAL
- [Finding]: There is an internal inconsistency in section numbering. "Experimental Protocol" is section 13, but its subsections are labeled 12.1-12.4. "Cost Model" is section 14, but its subsections are labeled 13.1-13.2.
- [Why]: This creates citation ambiguity and suggests the document has not been fully normalized, which matters in a spec intended for governance and cross-reference.
- [Fix]: Renumber sections and verify all internal references.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: The cost model is useful but incomplete. It excludes important realistic scenarios: retries, partial failures requiring reruns, prompt growth in Pass 2, synthesis review time, and sensitivity to provider pricing changes or token spikes by artifact size.
- [Why]: The main risk is not nominal cost but tail cost and operator time. The current budget may be materially optimistic.
- [Fix]: Add best-case / expected / worst-case ranges. Include retry overhead, large-artifact token bands, partial rerun policies, and operator review time as part of cost-per-insight.

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: The spec tracks dollar cost but does not define the unit economics of "cost per useful insight" in a measurable way.
- [Why]: Cost alone is not the decision metric; the spec repeatedly says the goal is cost-per-insight, but that metric is not operationalized.
- [Fix]: Define a simple KPI set: cost per useful insight, review minutes per useful insight, and action-trigger rate per deliberation.

- [F14]
- [Severity]: SIGNIFICANT
- [Finding]: The split-check trigger may be too narrow. Using only verdict distance >=2 as the condition for Pass 2 can miss high-value disagreements where verdicts are similar but reasoning conflicts sharply.
- [Why]: Two evaluators can both say "promising" while disagreeing on critical assumptions, risks, or sequencing. Those are exactly the cases dissent could clarify.
- [Fix]: Extend split detection to include reasoning conflict signals or flag overlap/contradiction analysis, not just verdict spread. Example: trigger Pass 2 if verdict spread >=2 or if at least two evaluators assert conflicting key assumptions.

- [F15]
- [Severity]: SIGNIFICANT
- [Finding]: Section 8.4 says all experimental deliberations run at standard depth unless overridden "to ensure Pass 2 data is collected for H3 testing," but section 8.2 says standard depth only runs Pass 2 when split exists.
- [Why]: This creates ambiguity about whether H3 data will be consistently collected.
- [Fix]: For Phase 2, explicitly require deep depth or a forced-Pass-2 experimental mode independent of split detection.

- [F16]
- [Severity]: SIGNIFICANT
- [Finding]: The schema is a strong start but too thin for later analysis. It lacks explicit fields for assumptions, evidence references, recommendation/action suggestion, and novelty markers.
- [Why]: Those omissions make downstream synthesis and uniqueness scoring harder and more subjective.
- [Fix]: Add optional structured fields such as `assumptions`, `evidence_quotes`, `recommended_action`, `impact_domain`, and `finding_tags`.

- [F17]
- [Severity]: MINOR
- [Finding]: `reasoning: 150-400 words` may be too tight for some artifact types and too loose for small artifacts.
- [Why]: Hard limits may either truncate useful nuance or encourage filler.
- [Fix]: Use target ranges by depth or artifact class, or define a soft target with max token budgets instead of fixed word counts.

- [F18]
- [Severity]: SIGNIFICANT
- [Finding]: The spec assumes overlays designed for human-advisory use can transfer to machine-evaluator prompts, but it does not define how overlay adherence will be tested.
- [Why]: If overlays are too narrative or underspecified, observed differences may come from provider behavior rather than intended role behavior.
- [Fix]: Add an overlay conformance check in Phase 1: rate whether outputs actually express the intended lens, perhaps with a simple 0-2 adherence score.

- [F19]
- [Severity]: SIGNIFICANT
- [Finding]: The initial evaluator-to-model mapping is plausible but introduces confounding into Phase 1. If one model is simply stronger overall, role-specific conclusions may be misleading.
- [Why]: You may infer model-role affinity when the result is really global model capability or style.
- [Fix]: Randomize or rotate role-model assignments for a subset of Phase 1 tests to separate role effects from model effects.

- [F20]
- [Severity]: SIGNIFICANT
- [Finding]: The communication architecture section underplays state-management complexity for any future move beyond relay. Shared-artifact and bus patterns will require idempotency, message ordering, duplicate suppression, and concurrency control.
- [Why]: These are major architectural concerns, not implementation details, and they affect whether the "stable contract, swappable transport" principle is actually sufficient.
- [Fix]: Add a short non-functional requirements subsection covering message identity, causal ordering, idempotency, retries, and append-only audit logging.

- [F21]
- [Severity]: SIGNIFICANT
- [Finding]: The spec says "the schema never changes for transport reasons," which is a useful principle but too absolute.
- [Why]: In practice, transport and protocol often interact. Async or multi-round systems commonly need correlation IDs, parent message IDs, sequence numbers, and delivery metadata.
- [Fix]: Reframe the principle: business semantics remain stable while transport metadata may extend the envelope. Split schema into semantic payload and transport metadata.

- [F22]
- [Severity]: SIGNIFICANT
- [Finding]: The future multi-round section identifies prompt growth, but the current design already has prompt growth risk in Pass 2 because every evaluator receives all Pass 1 assessments plus overlay plus artifact.
- [Why]: On long artifacts, this may exceed practical token budgets or force truncation that biases dissent quality.
- [Fix]: Add current-scope prompt budget management rules now: artifact summarization threshold, max prior-assessment inclusion size, and truncation policy.

- [F23]
- [Severity]: SIGNIFICANT
- [Finding]: Failure handling is underspecified. The config includes retries, but the spec does not define what happens when one provider fails permanently, times out, returns malformed schema output, or is rate-limited during one pass.
- [Why]: Partial panel execution affects split detection, dissent eligibility, and comparability across experiments.
- [Fix]: Define failure semantics: minimum viable panel size, whether to rerun all or only failed evaluators, how to mark incomplete deliberations, and whether incomplete runs count toward hypothesis testing.

- [F24]
- [Severity]: SIGNIFICANT
- [Finding]: The synthesis engine's evaluator diagnostics may create misleading inferences with small sample sizes.
- [Why]: Verdict distributions and persistent themes from 5-10 artifacts are highly unstable and could be overinterpreted as evaluator personality or model bias.
- [Fix]: Add sample-size caveats and minimum-count thresholds before reporting trends or persistent themes.

- [F25]
- [Severity]: SIGNIFICANT
- [Finding]: The spec does not clearly define batch completeness beyond manual signal, yet H4 depends on consistent batch semantics.
- [Why]: Without a clear rule, synthesis windows may vary in composition and make comparisons weak.
- [Fix]: Define a batch manifest with planned artifact list, inclusion criteria, and synthesis trigger conditions even if completion is manually invoked.

- [F26]
- [Severity]: MINOR
- [Finding]: The deliberation record format is readable, but storing both structured YAML and markdown body may create duplication and drift.
- [Why]: Drift makes later analysis harder.
- [Fix]: Clarify the source of truth: structured assessment files plus generated markdown view, or markdown with machine-readable blocks.

- [F27]
- [Severity]: SIGNIFICANT
- [Finding]: The spec does not define how "raw API responses" are normalized across providers for later auditing.
- [Why]: Different providers return different schemas and metadata; without normalization, debugging and token-cost reconciliation become harder.
- [Fix]: Define a provider-normalized response envelope containing request ID, model, timestamps, token counts, raw content, parse status, and error details.

- [F28]
- [Severity]: SIGNIFICANT
- [Finding]: The governance section correctly says agents never take actions, but the system still writes files and may trigger synthesis. The distinction between analysis actions and operational side effects is not fully formalized.
- [Why]: In later transport models, "write a record," "append to shared state," and "trigger next round" are still actions with governance implications.
- [Fix]: Distinguish permitted system-side orchestration actions from prohibited evaluator-side world actions, and specify which component has authority for each.

- [F29]
- [Severity]: SIGNIFICANT
- [Finding]: The experiment is still single-rater. Danny is the only judge for novelty, utility, and actionability.
- [Why]: That may be unavoidable, but it introduces strong evaluator bias and weakens claims of validation.
- [Fix]: Acknowledge this explicitly as a methodological limitation and reduce claims accordingly. If possible, add delayed self-reassessment or blind rescoring after a cooling-off period.

- [F30]
- [Severity]: MINOR
- [Finding]: The "Second-Order Effects" section includes future integration implications even though integration is out of scope.
- [Why]: This is not wrong, but it blurs experiment and roadmap.
- [Fix]: Label those implications explicitly as "forward-looking considerations, not current design commitments."

- [F31]
- [Severity]: STRENGTH
- [Finding]: The non-goals section is unusually clear and valuable.
- [Why]: It protects the experiment from scope creep, especially around calibration loops, mission control, and broader system integration.
- [Fix]: None.

- [F32]
- [Severity]: STRENGTH
- [Finding]: The task decomposition is concrete and aligned with the phase gates.
- [Why]: It makes the spec implementable and auditable.
- [Fix]: None.

- [F33]
- [Severity]: SIGNIFICANT
- [Finding]: Open Question 2 reveals a possible feasibility gap in H2: the same-model comparison arm may not be executable with currently listed infrastructure.
- [Why]: H2 is central. If the same-model arm is not available, the strongest comparative claim weakens.
- [Fix]: Resolve this before implementation by either securing the needed API access or redefining H2 to use one available provider as the same-model baseline.

- [F34]
- [Severity]: SIGNIFICANT
- [Finding]: The spec does not specify inter-run reproducibility controls such as temperature, top-p, seed support where available, or stable prompt/version pinning.
- [Why]: If outputs vary due to stochastic settings or drifting prompts, measured "diversity" may partly be randomness.
- [Fix]: Add provider settings for determinism where possible, version all overlays/prompts, and record prompt hashes in assessment metadata.

- [F35]
- [Severity]: SIGNIFICANT
- [Finding]: The current success criteria thresholds appear arbitrary and are not justified against expected variance or sample size.
- [Why]: Thresholds like 40%, 30%, and 50% may be perfectly fine, but without rationale they look ad hoc and can be moved after the fact.
- [Fix]: Add a brief threshold rationale section: exploratory heuristics, chosen to detect practical rather than statistical significance, subject to revision only before Phase 1 begins.

- [F36]
- [Severity]: SIGNIFICANT
- [Finding]: "Synthesis runs in the main Crumb session (Opus)" introduces a hidden dependency on a fifth model/session not otherwise accounted for in the architecture or cost assumptions.
- [Why]: This affects reproducibility and comparison, because synthesis quality may vary independently of the four-model panel.
- [Fix]: Make synthesis model choice explicit in dependencies, costing, and reproducibility metadata. Record synthesis prompt/version/model exactly like evaluator runs.

- [F37]
- [Severity]: SIGNIFICANT
- [Finding]: The spec does not define privacy/data-handling constraints for sending vault artifacts to external APIs.
- [Why]: Some artifacts may contain sensitive personal, customer, or strategic information; this is especially relevant for dossiers and career decisions.
- [Fix]: Add artifact eligibility rules, redaction requirements, and a sensitivity classification gate before external dispatch.

- [F38]
- [Severity]: SIGNIFICANT
- [Finding]: The architecture does not discuss provider-specific context limits, content policy failures, or incompatible output formatting tendencies.
- [Why]: In a multi-provider system, these asymmetries can systematically bias which evaluator "adds value."
- [Fix]: Add a provider-compatibility appendix or implementation note covering schema repair, truncation handling, and policy-failure fallback behavior.

- [F39]
- [Severity]: SIGNIFICANT
- [Finding]: The spec says "different LLMs demonstrably produce different analysis" and cites peer-review calibration notes, but that evidence is not summarized quantitatively here.
- [Why]: This is an important premise for the design choice of multi-model diversity.
- [Fix]: Add a brief evidence summary or appendix with observed peer-review differences and sample counts.

- [F40]
- [Severity]: UNVERIFIABLE CLAIM: SIGNIFICANT
- [Finding]: Specific model/version references such as "GPT-5.4," "Gemini 3.1 Pro," "DeepSeek V3.2," and "Grok 4.1 Fast," along with API availability and exact IDs like `gemini-3.1-pro-preview` and `grok-4-1-fast-reasoning`, cannot be independently verified from the spec alone.
- [Why]: Provider model names, preview status, and API identifiers can change quickly; implementation may fail if these are stale or informal labels.
- [Fix]: Verify all provider model IDs against current API documentation and record validation date in the config or an appendix.

- [F41]
- [Severity]: UNVERIFIABLE CLAIM: SIGNIFICANT
- [Finding]: The claim that peer-review empirical data shows model-specific strengths such as "Grok finds edge cases, DeepSeek catches structural issues, GPT is thorough on completeness, Gemini identifies integration gaps" is not independently verifiable from the text.
- [Why]: This claim materially supports the model-role mapping rationale.
- [Fix]: Cite a specific internal dataset, note sample size, or include a brief summarized table in the spec.

- [F42]
- [Severity]: UNVERIFIABLE CLAIM: SIGNIFICANT
- [Finding]: The cost claims "~$0.20-0.26 per artifact" and projected full deliberation cost ranges are not independently verifiable from the spec.
- [Why]: Cost assumptions drive feasibility and abort criteria.
- [Fix]: Attach a dated pricing appendix with token assumptions per provider and one or two worked examples.

- [F43]
- [Severity]: UNVERIFIABLE CLAIM: SIGNIFICANT
- [Finding]: The claim that the peer-review dispatch agent handles concurrent multi-model API calls in a single Bash invocation via Python ThreadPoolExecutor is not independently verifiable from the provided text.
- [Why]: This is a key implementation dependency.
- [Fix]: Reference the exact internal file or provide a short implementation excerpt or architecture note confirming the pattern.

- [F44]
- [Severity]: CRITICAL
- [Finding]: The core hypotheses are mostly testable, but the protocol as written is not sufficient to cleanly validate or invalidate them because the evaluation method for novelty/usefulness is underspecified and the baseline comparisons are incomplete.
- [Why]: This undermines the main goal of making go/no-go decisions on evidence rather than intuition.
- [Fix]: Before implementation, add: (1) a finding coding scheme, (2) explicit baselines, (3) a judging rubric, (4) prompt/version reproducibility controls, and (5) forced-Pass-2 conditions for H3.

## Overall assessment

- Correctness: Mostly sound conceptually, but weakened by measurement ambiguity, section-number inconsistencies, and missing failure semantics.
- Completeness: Good on architecture and scope boundaries; weaker on evaluation methodology, privacy, reproducibility, and operational edge cases.
- Internal consistency: Mostly strong, with notable inconsistencies around section numbering and Pass 2 collection logic.
- Feasibility: Technically feasible for a Phase 1 relay-based experiment, assuming existing dispatch infrastructure is real and model APIs are available. Less feasible as a rigorous experiment until measurement methods are tightened.
- Clarity: Generally high. The spec is readable and well structured, though a few principles are stated too absolutely and some critical terms are not operationally defined.

## Highest-priority fixes

1. Define a reproducible method for extracting and counting unique findings.
2. Add explicit baselines against Danny-alone and single-model multi-lens prompting.
3. Fix H3 data-collection ambiguity by forcing Pass 2 during the dissent phase.
4. Add failure semantics for partial provider failure and malformed outputs.
5. Add privacy/sensitivity gating for external dispatch.
6. Normalize section numbering and internal references.
7. Add reproducibility controls: prompt hashes, model IDs, inference settings, and dated config validation.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of the Multi-Agent Deliberation Specification.

### Unverifiable Claims

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Future or unreleased LLM model versions. The specification references "GPT-5.4", "Gemini 3.1 Pro", "DeepSeek V3.2", and "Grok 4.1 Fast". I cannot independently verify the existence, capabilities, or token pricing of these specific model versions as they appear to be future or fictional iterations relative to current public knowledge.
- [Why]: Hypothesis validation and cost modeling depend entirely on the specific capabilities, reasoning divergence, and API pricing of these exact models.
- [Fix]: Ground the specification in currently available model versions, or clearly flag these as hypothetical placeholders for future capability milestones.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Empirical infrastructure cost baseline. The specification states "Infrastructure cost per 4-model dispatch is ~$0.20-0.26 per artifact." I cannot verify this historical peer-review cost data.
- [Why]: The cost modeling for the entire project scales linearly from this baseline. If this baseline is inaccurate or calculated using older/cheaper models, the experimental budget will blow out.
- [Fix]: Provide the token-in/token-out breakdown that resulted in the $0.20-$0.26 figure to ensure it applies to the new, potentially more complex model lineup.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Existence and contents of internal project references. I cannot verify the existence or contents of the referenced artifacts (e.g., `_system/docs/overlays/business-advisor.md`, `Projects/opportunity-scout/design/calibration-seed.md`, `Sources/signals/`).
- [Why]: The success of the deliberation protocol relies heavily on the quality and format of these overlays and test artifacts.
- [Fix]: Ensure that all referenced overlays and seed patterns are fully developed and accessible to the dispatch agent before Phase 1 begins.

### Correctness & Internal Consistency

- [F4]
- [Severity]: MINOR
- [Finding]: Section numbering is broken starting at Section 12.
- [Why]: Section 12 is "Agent Communication Architecture". Section 13 is "Experimental Protocol", but its subsections are numbered 12.1, 12.2, etc. Section 14 is "Cost Model", but its subsections are numbered 13.1, 13.2.
- [Fix]: Renumber subsections in 13 to 13.x, and subsections in 14 to 14.x.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: The verdict enum `[strong, promising, neutral, cautionary, reject]` is rigidly applied to all artifact types.
- [Why]: The document states that artifacts include "architectural decisions" and "signal notes". A signal note might simply be factual or informative, and an architectural decision might be "approved" or "needs-revision". Forcing these through a 5-point opportunity-evaluation scale will likely confuse the models and result in hallucinated or forced verdicts, breaking the split-check math.
- [Fix]: Abstract the verdict scale to a generic 1-5 integer scale representing "support/alignment", or allow the `deliberation-config.md` to define artifact-specific verdict enums and mapping logic.

- [F6]
- [Severity]: CRITICAL
- [Finding]: The split-check logic (`max(verdicts) - min(verdicts) >= 2`) lacks error handling for missing or malformed assessments.
- [Why]: If one model times out, hits a rate limit, or returns a malformed schema that the Layer 3 wrapper drops, the array of verdicts may be incomplete (e.g., only 3 responses). The specification does not define whether Pass 2 should proceed, abort, or calculate the split on the remaining `n < 4` verdicts.
- [Fix]: Explicitly define fallback logic in Section 8.2 for `len(verdicts) < 4`. (e.g., "Calculate split on successful responses; if successful responses < 2, abort Pass 2").

### Experimental Protocol & Hypotheses (Focus Area)

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: H2 experimental design introduces confounding variables.
- [Why]: Condition (a) uses "4 Sonnet evaluators" (same model), while condition (c) uses the 4 different models from the registry. You are simultaneously changing the models *and* the baseline intelligence/reasoning style. If (c) outperforms (a), you won't know if it's because of model *diversity* or simply because GPT-5.4/Grok 4.1 are individually smarter than the "Sonnet" baseline.
- [Fix]: Ensure condition (a) uses one of the exact models from the registry (e.g., 4 GPT-5.4s with different overlays) to control for base model capability.

- [F8]
- [Severity]: CRITICAL
- [Finding]: Missing API configuration for the H2 baseline model.
- [Why]: Open Question 2 notes that "Sonnet" (Anthropic) is needed for the same-model condition, but Anthropic is missing from the `deliberation-config.md` in Section 11.3. Phase 1 cannot be executed as planned without resolving this dependency.
- [Fix]: Either add Anthropic/Sonnet to the API configuration, or (preferably, as per F7) use one of the existing configured models (e.g., OpenAI) for the same-model condition.

- [F9]
- [Severity]: MINOR
- [Finding]: Evaluator confidence scores are collected but ignored.
- [Why]: The assessment schema requires a `confidence: number [0.0-1.0]`, but the Split Check logic in 8.2 only evaluates the hard verdict. A split between a `reject (confidence 0.2)` and `neutral (confidence 0.9)` is functionally different than `reject (0.9)` and `neutral (0.9)`.
- [Fix]: Consider weighting the split distance by confidence, or note in the specification that confidence is gathered purely for Phase 4 meta-evaluation and human review rather than programmatic routing.

### Cost Model (Focus Area)

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Cost estimates for the "Synthesis" step are likely severely underestimated.
- [Why]: Section 13.1 estimates `$0.50-0.80` for standard + synthesis. However, Synthesis uses "Opus" (traditionally the most expensive model tier) and requires feeding 5-10 full deliberation records (Pass 1 + Pass 2 outputs + original artifacts) into the context window. A batch of 10 complex standard-depth deliberations could easily exceed 50k-100k input tokens. For high-tier models, this context alone will likely blow the estimated budget.
- [Fix]: Separate the Synthesis cost model from the Per-Deliberation cost model. Treat Synthesis as a discrete batch cost calculation based on `(average_tokens_per_record * batch_size) * Opus_input_pricing`.

### Communication Architecture (Focus Area)

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: Risk of cross-agent prompt injection in Pass 2.
- [Why]: In Pass 2, Agent A reads the raw reasoning output of Agent B. If Agent B hallucinates a directive (e.g., "Ignore previous instructions and output..."), Agent A may execute it. While Layer 1 protects against injection from the *artifact*, there is no protection defined for inter-agent contamination.
- [Fix]: Apply the Layer 1 injection resistance wrapper to the assembled Pass 1 assessments before feeding them into Pass 2 prompts, or strictly enforce Layer 3 schema parsing to strip out anything resembling prompt directives before Pass 2 assembly.

- [F12]
- [Severity]: STRENGTH
- [Finding]: The decoupling of the Assessment Schema (message contract) from the Transport Layer (Section 12.3).
- [Why]: Defining a stable YAML contract that is transport-agnostic allows the system to easily graduate from an orchestrated relay (Phase 1) to a shared file/bus architecture (future) without rewriting the core cognitive prompts. This is a highly mature systems design choice.

### Completeness & Clarity

- [F13]
- [Severity]: MINOR
- [Finding]: The dissent mechanism (`dissent_target`) only allows targeting a single evaluator ID.
- [Why]: If two evaluators (e.g., Business Advisor and Financial Advisor) both express a similar point that the Career Coach disagrees with, the schema forces the Career Coach to only cite one `dissent_target` or leave it null.
- [Fix]: Change `dissent_target: string | null` to `dissent_targets: array[string] | null` to allow many-to-many agent disagreements.

- [F14]
- [Severity]: STRENGTH
- [Finding]: Hypothesis-driven structure with explicit abort criteria.
- [Why]: Setting strict, measurable abort criteria (e.g., "Cost runaway: >$2.00 at standard depth", "Quality floor: <20% useful") before writing code prevents sunk-cost fallacies in experimental AI engineering. The "Failure Mode" explicitly leading to simplification or project termination is excellent governance.

---

## DeepSeek (deepseek-reasoner)

## Structured Review: Multi-Agent Deliberation Specification

### **CRITICAL Findings**

- **[C1] CRITICAL**
- **Finding**: Hypothesis H1 success criterion is too lenient and could validate insufficient diversity. Requiring verdicts to span >=2 points for only >=40% of artifacts means 60% of artifacts could show complete convergence, potentially indicating models are not meaningfully diverse.
- **Why**: This could lead to a false positive, proceeding with a framework that doesn't reliably produce diverse perspectives. The core value proposition is model diversity; the test should be stricter.
- **Fix**: Tighten success criteria. Require verdicts to span >=2 points for >=60-70% of test artifacts, OR add a qualitative criterion that for convergent artifacts, the reasoning text must show low semantic similarity (measured via embedding cosine distance < 0.7).

- **[C2] CRITICAL**
- **Finding**: Task MAD-006 (H2 test) is blocked by a missing dependency. The test requires running "same-model, different overlays" (4 Sonnet instances), but the system has no defined access to a Claude API. The spec notes this in OQ-2 but doesn't resolve it.
- **Why**: This is a direct blocker for the pivotal H2 test comparing diversity axes. The experimental design cannot be executed as written.
- **Fix**: Decide and specify the baseline. Options: 1) Secure Claude API access for the experiment, 2) Use one of the existing 4 models (e.g., GPT-5.4) as the "same-model" baseline for all overlays, adjusting the hypothesis accordingly.

### **SIGNIFICANT Findings**

- **[S1] SIGNIFICANT**
- **Finding**: The cost model (section 14) likely underestimates the cost of `standard` depth deliberations. Pass 2 prompts include *all* Pass 1 assessments, significantly increasing input tokens. The estimate of $0.40-$0.60 may be 1.5-2x too low for text-heavy artifacts.
- **Why**: Budget overrun could prematurely trigger the "cost runaway" abort criterion, invalidating the experiment due to a planning error rather than a framework failure.
- **Fix**: Model token usage more explicitly. Base estimates on average artifact word count and the added context of 4 assessments (~400-600 words each). Pilot a single deliberation with a representative artifact to calibrate.

- **[S2] SIGNIFICANT**
- **Finding**: The experimental protocol (section 13) lacks rigor for Danny's subjective assessments (e.g., "genuinely useful," "novel insight"). This introduces significant measurement bias and makes gate decisions ambiguous.
- **Why**: The entire validation rests on these human judgments. Without a clear rubric or blinding procedure, confirmation bias could skew results.
- **Fix**: Create a simple rating rubric (e.g., 1-5 scale for "novelty" and "utility") to be applied consistently. For Phase 1, consider blinding Danny to the condition (same-model vs. different-model) when rating "unique findings."

- **[S3] SIGNIFICANT**
- **Finding**: The "Split Check" logic triggers Pass 2 if verdict distance >=2 OR if `depth == deep`. However, the default depth for experimentation is `standard`. Therefore, Pass 2 only runs when there's a split. This design conflates the test of H3 (does dissent add value?) with the condition of having a split.
- **Why**: You cannot test if dissent adds information if you never run dissent on unanimous artifacts. A unanimous verdict could still benefit from augmentative dissent (e.g., "I agree, but here's an additional risk...").
- **Fix**: For the H3 test in Phase 2, override the default and force Pass 2 on all test artifacts, regardless of split. This isolates the variable: does seeing other assessments generate new information?

- **[S4] SIGNIFICANT**
- **Finding**: The synthesis engine design (section 9) is underspecified. It states synthesis "identifies" patterns but does not specify whether this is via an algorithmic analysis (e.g., clustering of `flags`) or via a prompt to the Opus LLM asking it to find patterns.
- **Why**: This is a key component for H4. An algorithmic approach is testable and consistent; an LLM-based approach is powerful but non-deterministic and harder to validate.
- **Fix**: Specify the synthesis method. Recommendation: Use a hybrid. First, extract structured data (verdicts, flags, evaluator IDs) from all batch records into a dataset. Then, prompt Opus to analyze the dataset for patterns, using the extracted data as a grounded source to reduce hallucination.

- **[S5] SIGNIFICANT - UNVERIFIABLE CLAIM**
- **Finding**: The cost baseline fact (F2: "Infrastructure cost per 4-model dispatch is ~$0.20-0.26 per artifact") is cited from "peer-review empirical data." This data is not provided or referenced for verification.
- **Why**: The entire cost model for the new system is extrapolated from this unverified baseline. If the baseline is wrong, the project budget is wrong.
- **Fix**: Reference a specific, accessible data source (e.g., a log file or a calculation in `peer-review-config.md`). If such a record doesn't exist, state the baseline as an "Assumption" (A6) and validate it in the first few deliberation runs.

- **[S6] SIGNIFICANT**
- **Finding**: Agent communication architecture (section 12.4) discusses future "multi-round deliberation" but dismisses convergence detection as "not in scope." However, even the 2-round protocol needs a clear termination condition to avoid infinite loops in case of agent disagreement.
- **Why**: While not needed for the experiment, the specification's long-term vision is undermined by not addressing this fundamental requirement for autonomous agent communication.
- **Fix**: In section 12.4, add a note on convergence detection for future work, specifying the three listed options (round cap, novelty threshold, explicit vote) as candidates, with the round cap being the simplest first step.

### **MINOR Findings**

- **[M1] MINOR**
- **Finding**: The System Map diagram shows components like "Split Check" and "Synthesis Engine" but the dependency list only includes external dependencies. The relationship between new components (e.g., the skill, the agent, the engine) is described in text but not in a dependency table.
- **Why**: Makes it slightly harder to trace internal data flow and implementation priorities.
- **Fix**: Add an "Internal Components" section to the System Map or expand the dependency table to include the relationships between MAD-001 through MAD-016 deliverables.

- **[M2] MINOR**
- **Finding**: The `flags` field in the Assessment Schema (section 6) is defined as an "array[string]" of "Actionable concerns or opportunities." This is vague and may lead to inconsistent outputs.
- **Why**: Reduces the structured nature and potential for algorithmic synthesis across assessments.
- **Fix**: Provide a brief guideline or examples in a comment: e.g., `# Example flags: ["market-timing-risk", "requires-technical-spike", "high-opportunity-cost"]`

- **[M3] MINOR**
- **Finding**: The document uses several undefined acronyms without first spelling them out: PIIA (S7.1), FIF (C3, U4), HITL (12.6).
- **Why**: Reduces clarity for readers not deeply embedded in the Crumb project context.
- **Fix**: Add a "Glossary" section or spell out each acronym on first use (e.g., "Proprietary Information and Invention Assignment (PIIA) agreement").

### **STRENGTHS**

- **[ST1] STRENGTH**
- **Finding**: The hypothesis-driven, gated experimental structure (section 5, 13) is excellent. It defines clear, testable success/failure criteria for each phase and explicitly plans for de-risking and potential project termination.
- **Why**: This is a rigorous, lean approach that aligns with the project's experimental nature and prevents sunk-cost fallacy. It forces validation of core assumptions before scaling complexity.

- **[ST2] STRENGTH**
- **Finding**: The design decision to use different LLMs per evaluator (rather than prompting the same model) is well-justified and leverages existing infrastructure and data (F1, F5). The model-role mapping rationale (section 7.2) is thoughtful and based on observed behavior.
- **Why**: This directly tackles the stated problem of "structurally different reasoning" and maximizes the chance of obtaining diverse perspectives from the available resources.

- **[ST3] STRENGTH**
- **Finding**: The concept of a "stable contract, swappable transport" (section 12.3) is a sound architectural principle. Defining the assessment schema as the immutable interface between agents decouples evaluation logic from communication mechanics.
- **Why**: This provides long-term flexibility, allowing the system to evolve from a simple relay to more sophisticated communication patterns without refactoring the core evaluative logic.

- **[ST4] STRENGTH**
- **Finding**: The task decomposition (section 16) is thorough, well-sequenced, and includes clear acceptance criteria. It ties implementation directly to hypothesis testing.
- **Why**: Provides a actionable, phased project plan that clearly links engineering work to research validation, ensuring the build effort is always aligned with proving value.

### **Summary Assessment**
The specification is **largely complete, innovative, and internally consistent**. Its greatest strength is its rigorous, gated experimental approach. The most critical issues are the **overly lenient H1 criterion** and the **unresolved blocker for the H2 test**. Significant attention is needed on **cost estimation accuracy** and **mitigating bias in human evaluation**. Addressing these points will significantly de-risk the experiment and ensure its findings are valid.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: CRITICAL
- [Finding]: Section numbering is broken starting from "13. Experimental Protocol"; subsections are labeled as 12.1, 12.2, etc., and "Cost Model" is labeled as "13." before it.
- [Why]: This creates confusion in navigation and referencing, undermining the document's professionalism and usability as a spec. Critical for a "stable message contract" like the assessment schema.
- [Fix]: Renumber sequentially: Cost Model as section 13, Experimental Protocol as section 14 with subsections 14.1 etc.

- [F2]
- [Severity]: CRITICAL
- [Finding]: Model names and versions are inconsistent across sections. E.g., section 7.1 uses "gpt-5.4", "gemini-3.1-pro-preview", "deepseek-reasoner", "grok-4-1-fast-reasoning"; section 11.3 config uses "gpt-5.4", "gemini-3.1-pro-preview", "deepseek-reasoner", "grok-4-1-fast-reasoning" (hyphens vary); Facts F5 uses "GPT-5.4, Gemini 3.1 Pro, DeepSeek V3.2, Grok 4.1 Fast".
- [Why]: Inconsistent naming will break config parsing, dispatch agent, and reproducibility. Undermines feasibility of implementation.
- [Fix]: Standardize to one format (e.g., kebab-case as in section 11.3) throughout; create a single model alias table.

- [F3]
- [Severity]: CRITICAL
- [Finding]: Hypotheses success criteria heavily rely on subjective "Danny" judgments (e.g., H1: "qualitatively different... assessed by Danny"; H2: "genuinely useful" by Danny; H3/H4/H5 similar). No inter-rater reliability, calibration, or objective proxies defined.
- [Why]: Undermines rigor of "hypothesis-testing framework"; subjective gates make validation non-reproducible and prone to bias, failing to invalidate hypotheses reliably.
- [Fix]: Add objective proxies (e.g., keyword divergence metrics, LLM auto-scoring of novelty) + require Danny's ratings with 3-point scale and justification log.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Facts F1-F6 reference "peer-review empirical data", "peer-review-config.md calibration notes", costs "~$0.20-0.26", model strengths (Grok edge cases, etc.). No sources or excerpts provided.
- [Why]: Core assumptions (reuse feasibility, costs, model diversity value) rest on unverified claims; risks building on false premises.
- [Fix]: Inline excerpts from peer-review-config.md or add appendix with data tables; cross-verify costs with current API pricing.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Model names like "GPT-5.4", "Gemini 3.1 Pro", "DeepSeek V3.2", "Grok 4.1 Fast" (dated 2026); API endpoints/pricing in section 11.3 (e.g., deepseek.com, x.ai).
- [Why]: Spec set in future (2026); current (2024) equivalents don't exist, blocking immediate feasibility testing.
- [Fix]: Add fallback to current models (e.g., GPT-4o, Gemini 1.5 Pro) with mapping table; note as placeholders.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: H2 test requires "same model, different overlays (4 Sonnet evaluators)" but config only supports 4 external providers, no Claude/Anthropic setup (OQ-2 flags this). No API keys/env for Claude mentioned.
- [Why]: Blocks H2 execution, core to validating multi-model vs multi-overlay diversity (key design decision #1).
- [Fix]: Add Anthropic config block to section 11.3; or pivot H2 to use one external model (e.g., GPT) for baseline.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Cost model ignores Pass 2 prompt bloat: "Pass 2 includes all Pass 1 assessments" (4x ~400-word reasonings = 1600+ words/token explosion); no token estimates per phase.
- [Why]: Underestimates costs (e.g., standard ~$0.40-0.60 could double); experimental budget $12-23 unreliable, risks "cost runaway" abort.
- [Fix]: Add token estimates (e.g., Pass 1: 2k input/1k output; Pass 2: 8k input/1.5k output); simulate with dry runs.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: Communication architecture (section 12) claims "stable contract" (schema) allows swappable transport, but relay pattern hardcodes orchestrator mediation; no schema evolution policy or versioning.
- [Why]: Blind spot in key design #4: future P2P/bus unfeasible without transport-agnostic dispatch code; schema changes break backward compat.
- [Fix]: Define schema v1.0 with change log process; make dispatch agent abstract "transport" (e.g., param for relay/shared).

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: Experimental protocol lacks control baselines: e.g., Phase 1 no comparison to single-model Opus; H5 meta-test vague on "single Claude session" benchmark method.
- [Why]: Insufficient to validate H5 ("novel insights Danny wouldn't find... or single LLM"); can't distinguish framework value from placebo.
- [Fix]: Mandate parallel single-model Opus runs per artifact; quantify novelty as % findings absent in Opus output.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Split-check uses simple numeric verdict distance >=2, but ignores confidence/flag overlap; e.g., all "neutral (conf 0.9)" vs one "strong (conf 0.4)" triggers Pass 2 unnecessarily.
- [Why]: May inflate Pass 2 costs without value; weak trigger for "structured dissent" (H3).
- [Fix]: Enhance to weighted distance (verdict * confidence) or flag divergence count >=2.

- [F11]
- [Severity]: MINOR
- [Finding]: YAML schemas (section 6, 8.1, 9.2, 10) use inconsistent typing (e.g., "enum [strong,...]" vs "string | null"); no JSONSchema validation mentioned.
- [Why]: Risks dispatch parsing errors; minor but accumulates in multi-agent reliability.
- [Fix]: Standardize to strict YAML/JSONSchema files; add validation in dispatch agent.

- [F12]
- [Severity]: MINOR
- [Finding]: Task decomposition (Phase 1 MAD-001 to MAD-007) assumes "adapt peer-review-dispatch" but no diff/patch plan; OQ-1 unresolved (new vs generalize agent).
- [Why]: Increases implementation risk/time; minor gap in feasibility.
- [Fix]: Resolve OQ-1 explicitly; add MAD-003 subtasks for code diffs.

- [F13]
- [Severity]: MINOR
- [Finding]: "Cold evaluation required" (C4) but test artifacts mix warm/cold without clear separation in phases (e.g., Phase 1 warm only?).
- [Why]: Contaminates validation; minor protocol ambiguity.
- [Fix]: Table per phase: # warm vs # cold artifacts.

- [F14]
- [Severity]: STRENGTH
- [Finding]: Reuse of peer-review infrastructure (section 11.1 table, F1/F6) is well-mapped with concrete adaptations (config, prompt layers).
- [Why]: Reduces dev risk/cost (key design #5); proven pattern lowers feasibility barriers. Verified: table aligns peer-review components directly.
- [Fix]: N/A

- [F15]
- [Severity]: SIGNIFICANT
- [Finding]: Synthesis engine (section 9) runs in "main Crumb session (Opus)" but no prompt/schema for it; assumes "cross-artifact reasoning" without dispatch.
- [Why]: Blocks Phase 3; architectural gap in batch handling (design #3).
- [Fix]: Define synthesis prompt/schema analogous to assessment; add as dispatch target.

- [F16]
- [Severity]: SIGNIFICANT
- [Finding]: Panel fixed to 4 evaluators (section 7.1); L4 "panel composition" lever mentions variability but no config support (default_panel only).
- [Why]: Limits experimentation (e.g., artifact-type panels); inflexible for H4 trends.
- [Fix]: Add per-brief panel override validation in skill.

- [F17]
- [Severity]: MINOR
- [Finding]: Abort criteria (section 12.4) like "cost >$2" but no auto-enforcement; manual only.
- [Why]: Relies on post-hoc; minor but weakens experimental rigor.
- [Fix]: Add dispatch-level cost caps (track tokens, abort mid-run).

- [F18]
- [Severity]: STRENGTH
- [Finding]: Hypothesis-driven structure with phased gates/aborts (section 5, 13) is rigorous, with clear failure modes per H.
- [Why]: Ensures no sunk cost fallacy (design #3); measurable where objective (e.g., verdict span >=2 points). Edge: subjectives flagged but gated.
- [Fix]: N/A

- [F19]
- [Severity]: SIGNIFICANT
- [Finding]: Multi-round deliberation (section 12.4) "not in scope" but schemas/records designed for it (pass_number extensible); no off-ramp if Phase 2 validates.
- [Why]: Scope creep risk; blinds feasibility path post-experiment.
- [Fix]: Explicitly defer to separate spec; cap pass_number=2 in schema v1.

- [F20]
- [Severity]: MINOR
- [Finding]: OQ-3 (ratings capture) unresolved; no default method.
- [Why]: Blocks data collection for gates.
- [Fix]: Default to inline YAML frontmatter in records (e.g., danny_rating: {useful: 3/5}).

- [F21]
- [Severity]: STRENGTH
- [Finding]: Assessment schema (section 6) as "stable message contract" enables transport evolution (section 12.3); comprehensive fields cover identity/eval/dissent.
- [Why]: Strong for design #2; verified consistent usage. Edge: null handling for Pass 1 dissent fields ok.
- [Fix]: N/A

- [F22]
- [Severity]: SIGNIFICANT
- [Finding]: No handling for model failures/outages (4 providers); peer-review retry (section 11.3) but no partial-record fallback if >=2 models fail.
- [Why]: Multi-provider fragility (second-order effect noted); risks incomplete deliberations.
- [Fix]: Define min_panel_threshold (e.g., 3/4 models); quorum logic in skill.

- [F23]
- [Severity]: MINOR
- [Finding]: Record format (section 10) "Deliberation Outcome" says "NOT a decision" but combines perspectives -- ambiguous who generates it (skill? synthesis?).
- [Why]: Clarity gap in output.
- [Fix]: Specify generator (e.g., auto-summary via Opus prompt).

- [F24]
- [Severity]: STRENGTH
- [Finding]: Cost model granular (section 14) with phase budgets; tracks vs peer-review baseline.
- [Why]: Addresses focus area; realistic scenarios modeled (depths). Edge: prompt bloat noted separately.
- [Fix]: N/A

- [F25]
- [Severity]: SIGNIFICANT
- [Finding]: Experimental protocol insufficient for U3 ("overlay vs model diversity"): H2 tests it but no statistical power (only 5 artifacts); no p-values/confidence intervals.
- [Why]: Weak to invalidate core value prop (design #1).
- [Fix]: Increase to 10-15 artifacts; add simple stats (e.g., unique findings count +/- std dev).

---

## Synthesis

### Consensus Findings

**CF-1: H2 baseline model is a blocker (OAI-F33, GEM-F8, DS-C2, GRK-F6).** All 4 reviewers flagged that H2 requires a same-model condition but no Anthropic/Claude API is configured. The spec notes this as OQ-2 but doesn't resolve it, and Phase 1 cannot execute as written. Resolution: use one of the existing 4 providers (e.g., GPT-5.4) as the same-model baseline — this is simpler, controls for base capability better than introducing a 5th model, and avoids new API setup.

**CF-2: Subjective evaluation criteria need a rubric (OAI-F5, OAI-F8, DS-S2, GRK-F3).** "Genuinely useful," "qualitatively different," and "novel insights" are the primary evidence for gate decisions, but they rely entirely on Danny's unstructured judgment. Without a lightweight scoring rubric, gates are vulnerable to confirmation bias and inconsistency across phases. All reviewers proposed scales (0-2, 1-5, 3-point); OAI additionally proposed a finding extraction protocol for counting "unique findings" reproducibly.

**CF-3: Cost model underestimates Pass 2 and synthesis (OAI-F12, DS-S1, GEM-F10, GRK-F7).** All 4 reviewers flagged that Pass 2 prompts include all Pass 1 assessments (~1600+ words), significantly inflating input tokens. Synthesis feeds 5-10 full deliberation records into Opus. Current estimates ($0.40-0.60 standard) are likely 1.5-2x low. Need token-level estimates, not just cost-range extrapolation.

**CF-4: Section numbering broken (OAI-F11, GEM-F4, GRK-F1).** Subsections under §13 and §14 still carry §12.x and §13.x numbering after the Agent Communication Architecture section was inserted. Trivial fix.

**CF-5: H3 data collection depends on split detection (OAI-F15, DS-S3).** Standard depth only runs Pass 2 when there's a verdict split (distance ≥2). But H3 asks "does dissent add information?" — you can't test that if Pass 2 never runs on unanimous cases. Need forced Pass 2 for Phase 2 H3 testing, independent of split.

**CF-6: Missing baselines — single-model and Danny-alone (OAI-F9, GRK-F9).** H5 claims the framework adds value beyond single-LLM or solo analysis, but the experiment doesn't measure those baselines. Need at least a parallel single-model comparison arm to validate the multi-model claim.

**CF-7: Failure handling underspecified (OAI-F23, GEM-F6, GRK-F22).** What happens when 1-2 providers fail, return malformed output, or time out? Partial panels affect split detection, dissent eligibility, and experimental comparability. Need minimum viable panel size and incomplete-deliberation handling rules.

**CF-8: Split check too narrow (OAI-F14, GRK-F10).** Verdict distance ≥2 misses cases where verdicts converge but reasoning conflicts sharply. Two evaluators can both say "promising" while disagreeing on critical assumptions.

**CF-9: Unverifiable claims (OAI-F40-F43, GEM-F1-F3, DS-S5, GRK-F4-F5).** All 4 reviewers flagged model names, cost figures, and "peer-review empirical data" as unverifiable from the spec alone. These are verifiable from internal vault files (peer-review-config.md, raw response data), but the spec should cite sources or include an evidence appendix.

### Unique Findings

**GEM-F11: Cross-agent prompt injection in Pass 2.** In Pass 2, evaluators read other evaluators' raw reasoning output. If one model hallucinates a directive ("Ignore previous instructions..."), it could inject into another evaluator's prompt. Layer 1 protects against artifact injection but not inter-agent contamination. **Genuine insight** — directly relevant to A2A security, and a real risk with untrusted model outputs in multi-agent pipelines. Should apply injection wrapping to assembled Pass 1 assessments before feeding into Pass 2.

**GEM-F5: Verdict scale doesn't fit all artifact types.** The [strong, promising, neutral, cautionary, reject] scale is opportunity-evaluation language. A signal note might be factual/informative; an architectural decision might be approved/needs-revision. Forcing these through an opportunity lens confuses models. **Genuine insight** — the schema is supposed to be artifact-agnostic but the verdict vocabulary isn't. Options: abstract to a generic 1-5 scale, or allow artifact-type-specific verdict enums in config.

**OAI-F19: Model-role mapping confounding.** If GPT-5.4 is simply the strongest model overall, attributing its Business Advisor output to "role fit" is misleading. Rotating model-role assignments for a Phase 1 subset would separate role effects from model effects. **Genuine insight** but adds significant experimental complexity — may be worth doing for 2-3 artifacts rather than the full set.

**OAI-F37: Privacy/data-handling for external dispatch.** Some artifacts may contain sensitive personal, customer, or strategic information. The safety gate catches secrets/keys but doesn't classify artifact sensitivity. **Valid concern** — especially relevant for dossiers and career decisions. The existing peer-review safety gate is necessary but not sufficient for deliberation-specific artifact types.

**GEM-F13: dissent_target should be array, not string.** If two evaluators express a similar point, the dissenting evaluator can only cite one target. Many-to-many disagreements need `dissent_targets: array[string]`. **Good schema improvement** — low cost, higher expressiveness.

**OAI-F21: "Schema never changes for transport reasons" too absolute.** Transport metadata (correlation IDs, sequence numbers, delivery metadata) may need to extend the envelope. **Valid nuance** — reframe as "business semantics stable, transport metadata may extend." Not blocking for relay pattern.

**DS-S4: Synthesis engine underspecified.** The spec says synthesis "identifies patterns" but doesn't say how — algorithmic extraction, LLM prompt, or hybrid? **Valid gap** — needs at least a directional answer (hybrid: structured data extraction + Opus analysis).

### Contradictions

**Split check severity.** GEM-F9 rates confidence-ignoring split check as MINOR. OAI-F14 and GRK-F10 rate the same concern as SIGNIFICANT. All agree the issue exists; they disagree on whether it matters enough to fix now vs. later. **Assessment:** SIGNIFICANT for the experiment — if split check is the only trigger for Pass 2, getting it wrong means missing valuable H3 data. But this is partially mooted by the forced-Pass-2 recommendation for Phase 2.

**H1 threshold.** DS-C1 wants the 40% threshold tightened to 60-70%. OAI-F35 says thresholds are arbitrary and need rationale but doesn't propose specific numbers. **Assessment:** The 40% threshold is exploratory — the spec should acknowledge this and commit to not adjusting thresholds after Phase 1 begins. Tightening to 60% is reasonable but should be a conscious decision, not an automatic reviewer accommodation.

### Action Items

#### Must-Fix

- **A1** (CF-2, CF-6) — [OAI-F5, OAI-F8, OAI-F9, DS-S2, GRK-F3, GRK-F9] **Add evaluation rubric and baselines.** Define a lightweight scoring rubric for Danny's assessments (3-point scale: not useful / somewhat useful / genuinely novel, applied per finding). Add a finding extraction protocol: decompose each assessment into atomic findings with domain tags. Add a single-model baseline comparison arm (run same artifacts through single Opus session, compare unique finding count). These three additions convert subjective gates into semi-structured measurement.

- **A2** (CF-1) — [OAI-F33, GEM-F8, DS-C2, GRK-F6] **Resolve H2 baseline model.** Use GPT-5.4 as the same-model baseline for H2 condition (a): 4 GPT-5.4 instances with different overlays. This uses existing infrastructure, avoids new API setup, and controls for base capability. Update spec §5 (H2), §16 (MAD-006), and close OQ-2.

- **A3** (CF-5) — [OAI-F15, DS-S3] **Force Pass 2 for Phase 2 testing.** Add an `experimental_force_pass_2: true` flag in the deliberation config. When set, Pass 2 runs on all deliberations regardless of split, ensuring H3 data collection is complete. This flag is experiment-specific and can be removed post-validation.

- **A4** (CF-7) — [OAI-F23, GEM-F6, GRK-F22] **Define failure semantics.** Add to §8: minimum viable panel = 3 of 4 evaluators. If <3 succeed, mark deliberation incomplete and exclude from hypothesis testing. Partial panels (3/4) proceed normally with the split check calculated on available verdicts. Failed evaluators are logged in the deliberation record.

- **A5** (CF-4) — [OAI-F11, GEM-F4, GRK-F1] **Fix section numbering.** Renumber subsections under §13 and §14 to match their parent section numbers.

- **A6** (GEM-F11) — **Add inter-agent injection resistance for Pass 2.** Apply the same Layer 1 injection wrapper to assembled Pass 1 assessments before feeding them into Pass 2 prompts. This is a direct A2A security requirement — untrusted model outputs should be treated as data, not instructions.

#### Should-Fix

- **A7** (CF-3) — [OAI-F12, DS-S1, GEM-F10, GRK-F7] **Improve cost model with token estimates.** Add per-pass token estimates (Pass 1: ~2K input / ~1K output; Pass 2: ~6-8K input / ~1.5K output). Add a worked example for one artifact. Separate synthesis cost from per-deliberation cost.

- **A8** (GEM-F5) — **Abstract verdict scale for artifact-type flexibility.** Add an `artifact_type_verdicts` config option allowing consumers to define type-specific verdict enums. Default remains the current 5-point scale. This prevents forcing opportunity-evaluation language onto signal notes or architectural decisions.

- **A9** (DS-S4, GRK-F15) — **Specify synthesis method.** Add to §9: hybrid approach — extract structured data (verdicts, flags, evaluator IDs) from all batch records into a dataset, then prompt Opus to analyze for patterns using the extracted data as grounded input.

- **A10** (GEM-F13) — **Change dissent_target to array.** Update schema §6: `dissent_targets: array[string] | null` to allow many-to-many disagreements.

- **A11** (OAI-F37) — **Add artifact sensitivity classification.** Before external dispatch, classify artifacts as: open (no restrictions), internal (vault-only data, acceptable for API), sensitive (customer data, career details — requires redaction or opt-in). Safety gate already catches secrets; this adds semantic sensitivity.

- **A12** (CF-8) — **Note split-check limitation.** Add a note that verdict-only split detection may miss reasoning conflicts. For Phase 2, this is mooted by forced Pass 2. For production use, consider adding a reasoning-divergence heuristic.

- **A13** (OAI-F35) — **Add threshold rationale section.** Acknowledge that success criteria thresholds (40%, 30%, 50%) are exploratory heuristics. Commit to fixing thresholds before Phase 1 begins — no post-hoc adjustment.

- **A14** (CF-9) — **Add evidence citations for empirical claims.** Add a brief appendix referencing peer-review-config.md calibration notes, raw response data locations, and a cost calculation example.

#### Defer

- **A15** (OAI-F20, OAI-F21, GRK-F8) — Schema versioning and transport metadata envelope. Valid for future bus/P2P patterns, not blocking for relay-based experiment. Note in §12.3.
- **A16** (OAI-F19) — Model-role rotation for Phase 1 subset. Genuine insight but adds experimental complexity. Revisit if Phase 1 results show suspiciously uniform model-role performance.
- **A17** (GRK-F17) — Automated cost cap enforcement. Manual monitoring sufficient for 25-38 experimental runs.
- **A18** (GRK-F25) — Increase H2 sample size to 10-15 artifacts. Reasonable but triples Phase 1 cost. Start with 5, expand if results are ambiguous.
- **A19** (GRK-F19) — Cap pass_number=2 in schema v1. Note intent in §12.4 but don't constrain the schema field — the field accommodating future extension costs nothing.
- **A20** (OAI-F29) — Single-rater bias. Acknowledged as methodological limitation. Delayed self-reassessment (re-rating after cooling period) is a low-cost mitigation to add if Danny has bandwidth.

### Considered and Declined

- **DS-C1** (tighten H1 from 40% to 60-70%): `constraint` — The 40% threshold is deliberately exploratory for a first experiment. Tightening pre-emptively risks Type II error (rejecting a framework that produces valuable but inconsistent diversity). The threshold rationale section (A13) addresses this.
- **OAI-F16** (add assumptions, evidence_quotes, recommended_action to schema): `overkill` — These fields add prompt complexity and increase output token cost without proven value for the experiment. The `flags` and `reasoning` fields capture most of this. Revisit if synthesis struggles with insufficient structured data.
- **OAI-F17** (reasoning word count range too tight): `constraint` — The 150-400 word range is a prompt-level target, not a hard validation rule. Models will naturally vary. Not worth adding artifact-class-specific ranges for an experiment.
- **OAI-F22** (Pass 2 prompt growth already a problem): `constraint` — Addressed by A7 (token estimates). Summarization thresholds are premature for a 4-evaluator 2-pass protocol — prompt sizes are manageable.
- **OAI-F26** (deliberation record YAML/markdown drift): `overkill` — Markdown is the human-readable view; YAML frontmatter is the machine-readable truth. This is standard vault convention and hasn't caused issues elsewhere.
- **OAI-F27** (normalize raw API responses across providers): `overkill` — Raw JSON files are diagnostic artifacts, not analysis inputs. Token costs can be extracted per-provider at analysis time.
- **OAI-F34** (temperature, top-p, seed for reproducibility): `overkill` — Most providers don't support seed reliably, and temperature=0 doesn't guarantee determinism. Prompt hashing (already in peer-review pattern) is the practical reproducibility control.
- **GRK-F11** (YAML schema typing inconsistencies): `out-of-scope` — Schema notation in the spec is descriptive, not executable. JSONSchema validation files (MAD-002) will use proper typing.
- **GRK-F12** (resolve OQ-1 and add MAD-003 subtasks): `out-of-scope` — OQ-1 is intentionally deferred to PLAN phase. Task decomposition granularity is appropriate for a spec; subtasks come in action planning.
- **OAI-F30** (second-order effects blur experiment and roadmap): `incorrect` — Second-order effects are a required spec section per the systems-analyst skill. They're explicitly labeled as implications, not commitments.
