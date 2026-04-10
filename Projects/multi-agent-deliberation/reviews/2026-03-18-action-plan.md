---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/multi-agent-deliberation/design/action-plan.md
artifact_type: architecture
artifact_hash: 80f33da1
prompt_hash: 27264b81
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
    latency_ms: 78599
    attempts: 1
    raw_json: Projects/multi-agent-deliberation/reviews/raw/2026-03-18-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 43365
    attempts: 1
    raw_json: Projects/multi-agent-deliberation/reviews/raw/2026-03-18-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 53275
    attempts: 1
    raw_json: Projects/multi-agent-deliberation/reviews/raw/2026-03-18-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 36325
    attempts: 1
    raw_json: Projects/multi-agent-deliberation/reviews/raw/2026-03-18-action-plan-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Multi-Agent Deliberation Action Plan

**Artifact:** Projects/multi-agent-deliberation/design/action-plan.md (+ tasks.md)
**Mode:** full
**Reviewed:** 2026-03-18
**Reviewers:** OpenAI gpt-5.4, Google gemini-3.1-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning
**Review prompt:** Structured review of action plan and tasks -- correctness, completeness, internal consistency, feasibility, clarity. Severity-classified findings with unverifiable claim flagging.

---

## OpenAI (gpt-5.4)

Below is a structured review of the action plan and tasks as self-contained artifacts.

## Overall Assessment

This is a strong experimental plan with good milestone gating, sensible emphasis on early learning, and generally coherent task decomposition. The baseline-first strategy is especially well-justified for an uncertain, potentially low-ROI infrastructure project. The task list is mostly aligned with the milestone narrative, and the plan shows good discipline around go/no-go decisions.

The main weaknesses are:
- several acceptance criteria are not fully binary/testable,
- some dependencies are underspecified or slightly inconsistent,
- key experimental thresholds are referenced but not embedded, making gate evaluation hard to audit from these artifacts alone,
- a few important feasibility and methodology risks are under-modeled.

---

## Findings

### F1
- **Severity:** STRENGTH
- **Finding:** The baseline-first approach in M0 is a strong design decision and is correctly prioritized ahead of infrastructure work.
- **Why:** For an experimental system whose value proposition is "better than a strong single-model baseline," establishing that baseline before building dispatch/synthesis infrastructure is the highest-leverage sequencing choice. It reduces sunk-cost bias and preserves the integrity of later hypothesis tests.
- **Fix:** No change needed. Keep this structure.

### F2
- **Severity:** STRENGTH
- **Finding:** The milestone gating model is coherent and well matched to the experimental nature of the project.
- **Why:** Hard gates between M0-M4 prevent scope creep and force explicit decisions based on evidence rather than momentum. The plan clearly treats "stop" as a valid outcome, which is exactly right for an experiment.
- **Fix:** No change needed.

### F3
- **Severity:** STRENGTH
- **Finding:** The task decomposition is mostly atomic and implementation-oriented.
- **Why:** Most tasks map cleanly to a single artifact or decision point, making execution and tracking straightforward. This is particularly good in M1 and M2, where code and research tasks are separated.
- **Fix:** No change needed.

### F4
- **Severity:** SIGNIFICANT
- **Finding:** Gate criteria and hypothesis thresholds are referenced but not present in these artifacts, which makes multiple acceptance criteria non-auditable.
- **Why:** Many tasks say "H1 thresholds assessed," "H2 thresholds assessed," "H3 thresholds assessed," "against H5 criteria," etc., but the thresholds themselves are not included in action-plan.md or tasks.md. Since the reviewer is asked to assess the plan as self-contained, gate correctness cannot be fully validated.
- **Fix:** Add a compact "Embedded Gate Threshold Summary" section to the action plan or tasks file listing the exact pass/fail criteria for H1-H5. Even abbreviated thresholds would make the plan self-sufficient.

### F5
- **Severity:** SIGNIFICANT
- **Finding:** Several acceptance criteria are not fully binary/testable and rely on subjective existence checks rather than measurable completion.
- **Why:** Criteria like "Written baseline quality summary exists," "Danny evaluates synthesis patterns," or "clear recommendation document exists" are weak as acceptance checks because they do not specify minimum content or decision standard. This makes completion ambiguous and increases variance in execution quality.
- **Fix:** Rewrite acceptance criteria to include explicit outputs and minimum contents. Example: "Baseline quality summary includes artifact list, finding counts, rating distribution, top 3 strengths, top 3 failure modes, and explicit proceed/reassess recommendation."

### F6
- **Severity:** SIGNIFICANT
- **Finding:** MAD-002 has no dependency on the M0 gate, unlike the rest of the M1 build tasks.
- **Why:** In the dependency table, MAD-002 depends on "---", which implies schema work could start before baseline validation. That contradicts the milestone-level statement that no M1 milestone begins until the M0 gate passes. It is a small inconsistency, but it weakens the integrity of the gated design.
- **Fix:** Change MAD-002 dependency to `MAD-001a (gate pass)` or explicitly state that schema drafting is allowed pre-gate as non-committed preparatory work.

### F7
- **Severity:** SIGNIFICANT
- **Finding:** The dependency graph and milestone narrative do not explicitly show that MAD-005 should depend on MAD-004a if prompt parity is important to interpretation.
- **Why:** H1 is same-overlay / different-model variance, so technically MAD-004a may not be required to run it. But the milestone narrative says Phase 1b baseline prompt development occurs before H2 comparisons, not necessarily before H1. This is fine operationally, but if H1 and H2 results are discussed together in a single gate document, uneven prompt preparation could complicate interpretation.
- **Fix:** Either keep as-is but clarify that MAD-004a is only required for H2, or require MAD-004a before both MAD-005 and MAD-006 if prompt/procedure stabilization is desired before any M1 research runs.

### F8
- **Severity:** CRITICAL
- **Finding:** The plan does not clearly define what counts as a "finding" for deduplication, rating, novelty counting, or cross-condition comparison.
- **Why:** The core metrics across M0-M4 depend on per-finding ratings, unique finding counts, R2 counts, Pass 2 novelty, and synthesis pattern detection. Without an operational definition of finding granularity and deduplication rules, the main experiment outputs are vulnerable to inconsistency and evaluator drift.
- **Fix:** Add a short methodology section defining:
  - finding unit of analysis,
  - deduplication rules within artifact,
  - deduplication rules across conditions/phases,
  - how "novel" differs from "rephrased" or "more evidenced,"
  - whether severity/importance affects uniqueness counting.

### F9
- **Severity:** SIGNIFICANT
- **Finding:** The rating workflow is central to the experiment, but inter-rater reliability or intra-rater consistency checks are only partially addressed through calibration anchors.
- **Why:** Re-rating the same 5 anchors checks drift over time, but does not fully validate that the procedure is stable enough for gate-bearing comparisons, especially when blinded rating and deduplication involve judgment calls. Because this project hinges on subtle quality differences, measurement quality matters as much as model behavior.
- **Fix:** Add a minimal reliability check in M0 or M1, such as delayed re-rating of a small subset of findings or a documented consistency threshold for anchor ratings.

### F10
- **Severity:** SIGNIFICANT
- **Finding:** Warm artifact reuse across Phase 0a and 0b is allowed, which may bias baseline assessment.
- **Why:** The action plan says Phase 0b "may reuse Phase 0a artifacts." That is understandable for cost control, but it risks contaminating the baseline if familiarity with artifacts influences expectations or rating efficiency. Since M0 determines whether to build the whole system, baseline integrity matters.
- **Fix:** Require at least some non-overlapping artifacts in Phase 0b, e.g. "3-5 artifacts total, with at least 2 not used in Phase 0a."

### F11
- **Severity:** SIGNIFICANT
- **Finding:** The plan does not sufficiently control for order effects or evaluator exposure effects in H2 and later phases.
- **Why:** If the same evaluator reviews multiple conditions for the same artifact in sequence, recognition and memory can distort novelty, deduplication, and quality judgments. This is especially important in H2's 3-condition comparison.
- **Fix:** Add explicit review-order controls: randomized condition order, delayed scoring, or independent blind coding of condition outputs before cross-condition comparison.

### F12
- **Severity:** SIGNIFICANT
- **Finding:** "Blinded" rating is referenced repeatedly, but the artifact does not define what exactly is blinded and what information is hidden.
- **Why:** For findings generated by different models/conditions, real blindness requires stripping provider names, overlays, pass number, and possibly formatting clues. If not standardized, the blindness claim may be weaker than intended.
- **Fix:** Add a brief blinding protocol specifying which metadata is removed, how outputs are normalized, and when unblinding occurs.

### F13
- **Severity:** MINOR
- **Finding:** There is a section reference inconsistency: action-plan M0 references rating procedure SS5.9, while MAD-001a acceptance criteria references refined SS5.6 procedure.
- **Why:** This may just reflect spec cross-references, but within these artifacts it reads as a possible typo or mismatch.
- **Fix:** Normalize the section reference throughout, or remove section numbers from the tasks file if the spec is external.

### F14
- **Severity:** SIGNIFICANT
- **Finding:** The risk register underestimates the methodological risk that the chosen baseline may be either too weak or not properly matched to the panel.
- **Why:** The plan does handle prompt parity via MAD-004a, which is good. But baseline selection is one of the most important validity issues in experiments comparing "single model with overlays" versus "multi-model panel." If the baseline is under-optimized, the panel can appear better for the wrong reason.
- **Fix:** Add a risk entry for "baseline unfairness / prompt mismatch" with mitigation: prompt parity checks, schema parity, comparable token budgets, and pilot review before H2.

### F15
- **Severity:** STRENGTH
- **Finding:** MAD-004a is a strong inclusion and materially improves the fairness of H2.
- **Why:** Many experimental plans miss the need for a strong primary baseline. Explicitly requiring 4 GPT-5.4 calls with separate overlays creates a more credible control against which model diversity can be tested.
- **Fix:** No change needed.

### F16
- **Severity:** SIGNIFICANT
- **Finding:** The acceptance criterion for MAD-003 includes "Handles >=1 provider failure gracefully (min panel 3/4)" but downstream experimental tasks do not define how partial panels affect analysis validity.
- **Why:** Allowing 3/4 completion is operationally sensible, but H1/H2/H3 comparisons can become uneven if some runs have 4 evaluators and others have 3. Without explicit handling rules, analysis could mix incomparable records.
- **Fix:** Add a protocol for partial panels: whether such runs are excluded, rerun, or analyzed separately; and define minimum valid sample composition for each hypothesis.

### F17
- **Severity:** SIGNIFICANT
- **Finding:** M2's prompt-growth risk is identified, but the plan does not define a quality-monitoring mechanism beyond general observation.
- **Why:** "Monitor per-model response quality" is too loose for a known risk affecting the central H3 result. If long-context degradation occurs, H3 could incorrectly conclude that dissent adds little value.
- **Fix:** Add explicit instrumentation: prompt token count, output token count, truncation occurrence, schema compliance rate, and response completeness score per provider in Pass 2.

### F18
- **Severity:** MINOR
- **Finding:** MAD-012 is somewhat over-scoped relative to other code tasks.
- **Why:** It combines structured extraction, batch dataset construction, Opus synthesis prompting, evaluator diagnostics, and manifest enforcement. That is still manageable, but it bundles several concerns into one task.
- **Fix:** Consider splitting into two tasks: synthesis data pipeline and synthesis analysis/manifest orchestration.

### F19
- **Severity:** SIGNIFICANT
- **Finding:** M3 depends on availability of cold artifacts, but no concrete upstream preparatory task exists to secure them.
- **Why:** The risk is identified, but not operationalized. Since M3 can stall on this dependency, relying on passive availability is fragile.
- **Fix:** Add a preparatory task in M1 or M2 such as "Maintain cold artifact candidate pool with provenance and exposure status."

### F20
- **Severity:** SIGNIFICANT
- **Finding:** M4 meta-evaluation depends heavily on "actions triggered by insights," but the plan does not define attribution rules.
- **Why:** In practice, action causality is fuzzy. If an action was already likely, or triggered by a synthesis rather than an individual finding, counts can become inconsistent or inflated.
- **Fix:** Define action attribution categories, e.g. direct, assisted, or non-attributable, and count them separately.

### F21
- **Severity:** MINOR
- **Finding:** The action plan says "maximum learning happens at minimum cost," but the cost model is only lightly specified.
- **Why:** There is a mention of $1-3 and $15-37 savings plus a $2.00 abort criterion, but no cost assumptions are embedded in the tasks. This is not fatal, but it reduces auditability of the ROI framing.
- **Fix:** Add a compact cost assumptions table with expected cost per deliberation type and gate-level spend caps.

### F22
- **Severity:** STRENGTH
- **Finding:** The plan shows good awareness of implementation reuse via the peer-review-dispatch pattern.
- **Why:** Reusing an adjacent proven pattern is the right way to reduce M1 execution risk, especially for provider orchestration and metadata capture.
- **Fix:** No change needed.

### F23
- **Severity:** SIGNIFICANT
- **Finding:** The synthesis evaluation in MAD-013 is weakly specified: "Danny evaluates synthesis patterns."
- **Why:** H4 is one of the project's major claims, but its evaluation criterion is currently highly subjective and person-dependent. Without a rubric, synthesis could be judged inconsistently or favorably just for sounding insightful.
- **Fix:** Add a synthesis evaluation rubric with at least: novelty, actionability, cross-artifact support, non-obviousness, and whether the pattern was already visible in per-artifact reviews.

### F24
- **Severity:** MINOR
- **Finding:** The milestone/task naming around M0 uses both "Milestone 0" and task IDs MAD-000 / MAD-001a, which is understandable but mildly confusing.
- **Why:** MAD-001a occurring before MAD-001 could cause tracking friction.
- **Fix:** Consider renaming M0 tasks to MAD-000 and MAD-000a, or adding a brief note that MAD-001 is reserved for config and MAD-001a is still part of baseline.

### F25
- **Severity:** SIGNIFICANT
- **Finding:** The plan does not explicitly state whether the same 5 warm artifacts are used for H1 and H2, or how artifact selection is controlled across tests.
- **Why:** Shared artifacts can improve comparability but increase familiarity effects; separate sets reduce contamination but increase variance. Either is acceptable, but it should be intentional.
- **Fix:** Add an artifact sampling plan covering warm/cold split, overlap policy, and rationale per hypothesis.

### F26
- **Severity:** STRENGTH
- **Finding:** Risk handling for provider failures, prompt size, and cost ceilings is practical and implementation-aware.
- **Why:** These are common failure modes in multi-provider orchestration, and the plan addresses them early rather than assuming happy paths.
- **Fix:** No change needed.

### F27
- **Severity:** SIGNIFICANT
- **Finding:** The acceptance criterion for MAD-006 requires "comparison matrix with unique finding counts per condition," but unique count alone may be a poor proxy for quality.
- **Why:** A condition can produce more findings by being verbose or fragmented, not by being better. The plan does mention rating all findings, but the acceptance criterion should reflect quality-weighted comparison, not just counts.
- **Fix:** Expand the criterion to require both count metrics and rating-based metrics, e.g. counts of high-rated findings, mean rating, or proportion of actionable findings.

### F28
- **Severity:** SIGNIFICANT
- **Finding:** The plan does not clearly address contamination between Pass 1 and Pass 2 novelty judgments.
- **Why:** H3 asks whether dissent adds information beyond independent assessment. That requires clear rules on whether a Pass 2 finding is truly new, a refinement, or merely a response. Without this, "incremental value" is hard to measure reliably.
- **Fix:** Define Pass 2 novelty categories such as new claim, materially strengthened claim, corrected claim, reframed claim, or non-novel response.

### F29
- **Severity:** MINOR
- **Finding:** Some success criteria use "functional" or "working" language without explicit test methods.
- **Why:** Terms like "batch-complete trigger working" and "deliberation skill is functional" are understandable, but not ideal for acceptance review.
- **Fix:** Replace with demonstrable checks, e.g. "integration test run produces X artifact under Y conditions."

### F30
- **Severity:** SIGNIFICANT
- **Finding:** The plan appears to cover the major spec-derived areas mentioned in the artifacts, but coverage cannot be fully confirmed because several referenced sections (SS5.7, SS5.9, SS6, SS8.6, SS9.2, SS10) are externalized.
- **Why:** As a self-contained review, there is no way to ensure all spec requirements are represented. The plan is likely directionally complete, but not demonstrably complete.
- **Fix:** Add a traceability appendix mapping each major spec requirement to milestone/task IDs.

---

## Unverifiable Claims

### F31
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** "Per estimation-calibration.md, gated projects with early checkpoints compress timelines when gates fire early. Phase 0 baseline could terminate the project at $1-3 cost, saving $15-37 of infrastructure investment."
- **Why:** This references an external document and specific cost statistics that are not included here, so the claim cannot be verified from the provided artifacts.
- **Fix:** Add a footnote or compact cost basis summary directly in the action plan.

### F32
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** "Peer-review-dispatch pattern (code reference) | Available."
- **Why:** Availability of this code reference is asserted but cannot be confirmed from the provided artifacts.
- **Fix:** Add a repository path or artifact reference if this needs to be reviewable.

### F33
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** "Overlay documents (7 active) | Available."
- **Why:** The count and availability of overlays cannot be confirmed from these artifacts.
- **Fix:** List overlay IDs or paths if the count matters to execution.

### F34
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** "API keys (4 providers) | Available."
- **Why:** This cross-project dependency status cannot be independently verified here.
- **Fix:** If needed for planning rigor, replace "Available" with "Assumed available; verify before M1 start."

---

## Direct Answers to the Requested Evaluation Dimensions

### 1) Baseline-first approach
Strong and correct. This is one of the best aspects of the plan. The only improvement needed is tightening M0 methodology to reduce artifact reuse and strengthen rating reliability.

### 2) Task sequencing and dependency graph correctness
Mostly correct, with two notable issues:
- MAD-002 should probably depend on the M0 gate for consistency.
- Some methodology dependencies are implicit rather than explicit, especially around blinding, artifact selection, and partial panel handling.

### 3) Risk assessment accuracy
Good on implementation risks; weaker on experimental-validity risks. Missing or underweighted risks include:
- baseline unfairness / mismatch,
- rating methodology instability,
- artifact contamination / familiarity effects,
- partial-panel comparability.

### 4) Acceptance criteria quality
Mixed. Many are serviceable, but too many are "document exists" or "works" rather than binary, observable, and minimally content-specified.

### 5) Whether the plan adequately covers all spec requirements
Probably directionally yes, but not provable from these artifacts alone because too much is delegated to section references from the absent spec. A traceability appendix would fix this.

### 6) Whether any tasks are under-scoped or over-scoped
- **Under-scoped:** MAD-007, MAD-011, MAD-014, MAD-015, MAD-013 due to weakly specified evaluation outputs; MAD-010 due to unclear Pass 2 novelty methodology.
- **Over-scoped:** MAD-012 is the clearest candidate for splitting.

---

## Recommended Priority Fixes

If only a few changes are made, prioritize these:

1. **Define finding, novelty, and deduplication rules** across all phases.
2. **Embed H1-H5 gate thresholds** in the plan/tasks.
3. **Strengthen acceptance criteria** to be binary and content-specific.
4. **Fix dependency inconsistency for MAD-002** and clarify partial-panel handling.
5. **Add methodology controls** for blinding, artifact reuse, and order effects.
6. **Add a spec traceability appendix**.

---

## Google (gemini-3.1-pro-preview)

Here is a structured review of the multi-agent deliberation action plan and task definitions.

### Overall Assessment
The action plan demonstrates an excellent, highly rigorous approach to experimental engineering. The "baseline-first" and "hypothesis-gated" design decisions are **major strengths**, ensuring that infrastructure complexity is only justified by proven empirical value. The atomic task breakdowns, binary acceptance criteria, and exact alignment between the task list and summary tables reflect a high level of precision.

However, there are a few architectural contradictions regarding task dependencies and a significant underestimation of the manual human workload required for data evaluation.

### Findings

- [F1]
- STRENGTH
- **Baseline-First and Gated Progression Strategy**: The decision to place Milestone 0 (single-Opus baseline) before Milestone 1 (infrastructure build) is an exceptional architectural choice. It successfully isolates the highest-leverage variable (does multi-agent actually beat a zero-shot multi-lens prompt?) and prevents sunk-cost fallacy.
- **Why**: Many experimental projects build complex multi-agent pipelines before validating the baseline. This plan explicitly treats a "no-go" gate as a successful outcome.

- [F2]
- STRENGTH
- **Acceptance Criteria & Scope Accuracy**: The acceptance criteria across the `tasks.md` file are highly binary, observable, and testable (e.g., "5 findings stored", "Valid YAML", "pass_2_truncated flag set correctly"). Furthermore, the task summary table perfectly matches the task inventory (7 Code, 7 Research, 4 Decision, 1 Writing = 19 total tasks).
- **Why**: This ensures unambiguous definition of "done" for each phase and accurate project tracking.

- [F3]
- CRITICAL
- **Dependency Bypass on MAD-002**: In `tasks.md`, MAD-002 (Assessment Schema) lists `Depends On: ---` (meaning no dependencies). However, it is fundamentally an infrastructure task that belongs in Milestone 1.
- **Why**: If MAD-002 has no dependency on the M0 gate pass, a developer or automated agent could begin executing it concurrently with Phase 0. If the M0 baseline test fails and kills the project, the time spent building MAD-002 is wasted, violating the "Pre-Infrastructure" constraint of Milestone 0.
- **Fix**: Update the `Depends On` column for MAD-002 to require `MAD-001a (gate pass)`.

- [F4]
- SIGNIFICANT
- **UNVERIFIABLE CLAIM: Software Version References**: The plan references model versions "GPT-5.4", "Gemini 3.1 Pro", "DeepSeek V3.2", and "Grok 4.1 Fast".
- **Why**: These specific model version numbers represent future or unreleased capabilities that cannot be independently verified at this time.
- **Fix**: Verify availability of these specific API endpoints/versions, or parameterize the plan to refer to "State-of-the-Art Model A/B/C/D" until exact version numbers can be grounded.

- [F5]
- SIGNIFICANT
- **Under-scoped Human Fatigue Risk in Phase 1c**: The risk register ignores the immense manual workload required for MAD-006. The task requires a human to blindly extract, blind, rate, gut-check, unblind, and deduplicate findings for 15 deliberation records (3 conditions x 5 artifacts x 4 models).
- **Why**: If a typical deliberation yields 5-10 findings, Danny will have to manually blind and rate 300 to 600 individual findings. This creates a high risk of human evaluator fatigue, which could severely compromise rating consistency and delay the H2 gate.
- **Fix**: Add "Human evaluator fatigue during H2 testing" to the Risk Register. Mitigate by either reducing the MAD-006 artifact count from 5 to 3, or spreading the rating task over multiple days with forced breaks.

- [F6]
- SIGNIFICANT
- **Corrupted ASCII Dependency Graph**: The dependency graph in `tasks.md` contains redundant and disconnected paths that contradict the tabular dependencies. Specifically, MAD-004 has branching paths pointing to MAD-006 twice (once directly, once through MAD-004a). Additionally, the flow from MAD-011 drops into a disconnected visual layout for MAD-012 through MAD-016.
- **Why**: Visual dependency graphs are heavily relied upon by execution agents and developers. A contradictory graph causes sequencing confusion.
- **Fix**: Redraw the ASCII graph to strictly match the tabular dependencies. Remove the redundant line to MAD-006 and fix the gate flow for M3 and M4:
  `...MAD-011 --gate--> MAD-012 --> MAD-013 --> MAD-014 --gate--> MAD-015 --> MAD-016`

- [F7]
- MINOR
- **Ambiguous "Baseline" Nomenclature**: The plan references a "Phase 0 baseline" (single-Opus multi-lens) and a "Primary baseline prompt" developed in MAD-004a (4x GPT-5.4). While logically sound for isolating variables, reusing the term "baseline" for two entirely different architectural paradigms in the same experiment is confusing.
- **Why**: When discussing "baseline comparisons" in M1 and M2, it requires mental overhead to remember which baseline is being referenced.
- **Fix**: Rename the Phase 0 baseline to "Single-Model Baseline" (SMB) and the MAD-004a baseline to "Homogeneous Multi-Call Baseline" (HMCB) or similar distinct terminology.

- [F8]
- MINOR
- **Missing Task for Gathering Cold Artifacts**: MAD-013 dictates running deliberations on 5-10 "cold artifacts," and the risk register rightly flags the sourcing of these as a medium risk. However, there is no explicit task dedicated to hunting and preparing these artifacts prior to the M3 gate.
- **Why**: Waiting until MAD-013 to source 5-10 cold artifacts will likely stall Phase 3 execution.
- **Fix**: Add a minor concurrent task (e.g., MAD-009a) during Milestone 2 to begin actively capturing and formatting cold artifacts from live pipelines so the batch manifest is ready when M3 begins.

---

## DeepSeek (deepseek-reasoner)

**Structured Review of Multi-Agent Deliberation Action Plan & Tasks**

---

### **CRITICAL FINDINGS**

**F1 - CRITICAL**
**Finding:** Task dependency graph contains a logical error. In tasks.md, MAD-001 (config file) depends on MAD-001a (baseline gate), but MAD-001a is defined as a task under Milestone 0, while MAD-001 is the first task of Milestone 1. The graph shows `MAD-000 -> MAD-001a --gate--> MAD-001`, but the action plan states M0's gate decision determines whether M1 starts. The dependency is conceptually correct (gate passes), but the labeling is inconsistent: MAD-001a is listed as M0 task but referenced as a dependency for M1 tasks.
**Why:** This creates confusion about what constitutes the gate. If MAD-001a is the gate task, it should be clearly identified as such, and its acceptance criteria must include the gate decision. The current split (MAD-000, MAD-001a) obfuscates the gate mechanism.
**Fix:** Rename MAD-001a to MAD-0-GATE or similar. Update dependency graph to show MAD-000 -> MAD-0-GATE (gate) -> M1 tasks. Ensure acceptance criteria for the gate task explicitly require a documented go/no-go decision.

**F2 - CRITICAL**
**Finding:** Missing task for "baseline prompt development" (Phase 1b in action plan). The action plan describes Phase 1b: "Before running H2 comparisons, develop and document the primary baseline prompt (4 GPT-5.4 calls with separate overlays)." This is critical for experimental validity, ensuring prompt parity. However, tasks.md lists MAD-004a with a description that matches but its dependencies are wrong: it depends on MAD-004 (deliberation skill), which is unnecessary for developing a prompt.
**Why:** Developing a baseline prompt does not require a functioning deliberation skill; it's a research/design task that should happen early in M1. Making it depend on the skill implementation introduces unnecessary sequencing delay and conflates infrastructure with experimental design.
**Fix:** Move MAD-004a earlier in the sequence, making it depend only on MAD-001a (gate pass) or MAD-000. Update dependencies: MAD-004a should feed into MAD-006 (H2 test), not vice versa.

---

### **SIGNIFICANT FINDINGS**

**F3 - SIGNIFICANT**
**Finding:** Acceptance criteria are mostly binary but lack specific thresholds for "testable." Several criteria use vague measures: "Friction points documented," "Qualitative annotation for each artifact where verdict variance >=2," "Novel Pass 2 finding count documented." These are not inherently binary; they require subjective judgment of what constitutes sufficient documentation.
**Why:** Without clear thresholds, task completion is ambiguous. This risks false positives (task marked done when quality is insufficient) or unnecessary rework.
**Fix:** Specify concrete deliverables: e.g., "Friction log with >=3 entries and proposed adjustments," "Annotation >=100 words per artifact with variance," "Table with counts and examples."

**F4 - SIGNIFICANT**
**Finding:** Risk "Insufficient cold artifacts for Phase 3" is under-mitigated. The mitigation ("Start collecting candidates from live pipelines early") is not reflected as a task or owner. Phase 3 success depends on external pipeline output, which is not controllable within this project.
**Why:** This is a project-blocking external dependency with no active management. If cold artifacts are unavailable, M3 cannot proceed, wasting previous investment.
**Fix:** Add a proactive task in M1 or M2: "Identify and reserve 5-10 candidate cold artifacts from Scout/FIF backlog, confirm availability with pipeline owners." Treat this as a prerequisite for M3 gate approval.

**F5 - SIGNIFICANT**
**Finding:** Task MAD-015 (H5 meta-evaluation) acceptance criteria include "Answer 'Would I use this weekly?' checkpoint" but provide no guidance on how this qualitative answer influences the recommendation. This subjective checkpoint could override quantitative data without rationale.
**Why:** Introduces risk of decision bias. The action plan states this is a "qualitative checkpoint," but its weight relative to H5 criteria is undefined.
**Fix:** Clarify in acceptance criteria that the checkpoint must be accompanied by explicit reasoning linking back to experimental data (e.g., "Weekly use justified because R2 finding count > X and cost < Y").

**F6 - SIGNIFICANT - UNVERIFIABLE CLAIM**
**Finding:** The action plan references external documents not provided: "SS5.9 rating procedure," "SS5.10 calibration anchor," "SS6 fields," "SS8.6 prompt size limits," "SS9.2 synthesis output schema." These are presumably from the specification mentioned in context.
**Why:** Review cannot verify that the tasks correctly implement these spec sections. Missing references could hide scope gaps.
**Fix:** Reviewer note only; recommend that spec citations be accompanied by brief summaries in the task description for standalone readability.

**F7 - SIGNIFICANT**
**Finding:** Task MAD-003 (dispatch agent) acceptance criteria lack validation for "Handles >=1 provider failure gracefully (min panel 3/4)." No test scenario is defined to verify this behavior.
**Why:** Graceful degradation is a key reliability requirement. Without a test, implementation may be incomplete or buggy.
**Fix:** Add explicit validation step: "Simulated provider failure test passes (mock one provider timeout, skill completes with 3 assessments)."

---

### **MINOR FINDINGS**

**F8 - MINOR**
**Finding:** Inconsistent terminology: "Phase" vs. "Milestone." The action plan uses "Phase 0a, 0b, 1a, 1b..." while tasks.md uses "Milestone 0, 1, 2..." This is minor but could cause confusion in communication.
**Why:** Clarity and consistency improve readability.
**Fix:** Standardize on "Milestone" for major stages and "Phase" for sub-stages, or pick one term.

**F9 - MINOR**
**Finding:** Task IDs are non-sequential in places (MAD-001a appears between MAD-000 and MAD-001). This breaks intuitive ordering.
**Why:** Makes referencing and tracking slightly harder.
**Fix:** Rename MAD-001a to MAD-001 (and shift subsequent IDs) or use consistent numbering (MAD-000, MAD-001, MAD-002...).

**F10 - MINOR**
**Finding:** Dependency graph in tasks.md is visually confusing; arrows merge without clear nodes for gates.
**Why:** Reduces at-a-glance comprehensibility.
**Fix:** Use a clearer ASCII representation or supplement with a table of gate dependencies.

---

### **STRENGTHS**

**S1 - STRENGTH**
**Finding:** Baseline-first approach (M0) is exceptionally well-justified and economically rational. The plan explicitly values a "no-go" outcome as valid learning, front-loading the cheapest possible test before infrastructure investment.
**Why:** This demonstrates rigorous experimental design and cost-aware prioritization, reducing sunk-cost fallacy risk.

**S2 - STRENGTH**
**Finding:** Task acceptance criteria are largely specific and binary (e.g., "Config file exists," "Schema file exists. Valid YAML."). This enables clear completion checks and reduces ambiguity.
**Why:** Promotes accountability and reduces "almost done" ambiguity.

**S3 - STRENGTH**
**Finding:** Risk register is thoughtfully curated, with realistic levels and mitigations tied to concrete project elements (e.g., "SS8.6 prompt size limits mitigate").
**Why:** Shows proactive risk management, not boilerplate.

**S4 - STRENGTH**
**Finding:** The plan adequately covers the spec requirements inferred from context (multi-model dispatch, dissent protocol, synthesis, meta-evaluation). Each hypothesis (H1-H4) has a dedicated test phase with clear success criteria.
**Why:** Comprehensive coverage of the experimental framework's components.

**S5 - STRENGTH**
**Finding:** The dependency graph respects logical sequencing: infrastructure before experiments, dissent after baseline panel, synthesis after single-artifact deliberation. No circular dependencies.
**Why:** Ensures feasible implementation flow.

---

### **SUMMARY ASSESSMENT**

The action plan and tasks represent a sophisticated, well-structured experimental project with strong foundations in hypothesis-driven development and staged investment. Critical issues are limited to minor dependency labeling errors and one missing proactive task for artifact sourcing. Significant issues relate primarily to acceptance criteria precision and external dependency management. Strengths are numerous, particularly in economic rationality and risk awareness.

**Recommendation:** Proceed with implementation after addressing F1, F2, and F4. The plan is fundamentally sound and addresses all key design decisions positively.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
  [CRITICAL]: Section reference inconsistency between artifacts.
  [Finding]: Action-plan.md consistently references the "rating procedure (SS5.9)", but tasks.md MAD-001a specifies "refined SS5.6 procedure".
  [Why]: Creates contradiction that could lead to implementing or testing the wrong procedure, invalidating baseline calibration and all downstream ratings. Breaks internal consistency.
  [Fix]: Standardize to one section (verify spec; likely SS5.9). Update MAD-001a AC/desc to match.

- [F2]
  [SIGNIFICANT]: Dependency gap for MAD-002.
  [Finding]: tasks.md table lists MAD-002 Depends On as "---", but it logically requires M0 gate pass (per action-plan.md Phase 1a sequencing and dependency graph ASCII showing it after gate). MAD-001 correctly deps MAD-001a (gate).
  [Why]: Permits starting schema before baseline validation, violating gated progression and risking wasted effort if M0 fails. Undermines sequencing correctness.
  [Fix]: Update table: MAD-002 Depends On "MAD-001a (gate pass)". Align table with graph.

- [F3]
  [SIGNIFICANT]: Some acceptance criteria are not binary testable.
  [Finding]: Examples: MAD-000 ("Friction points documented and procedure refined"), MAD-005 ("Qualitative annotation for each artifact where verdict variance >=2" -- subjective "qualitative"), MAD-007 ("H1 and H2 thresholds assessed" without defined thresholds). Many others are binary (e.g., "file exists", ">=5 records"), but ~20% lack objectivity.
  [Why]: Weak AC reduce gate reliability; "refined" or "qualitative" invites debate, failing "binary testable" evaluation criterion.
  [Fix]: Make explicit: e.g., MAD-000 add ">=3 friction points listed with before/after procedure diffs"; define thresholds in gate evals (e.g., "variance stddev >1.0").

- [F4]
  [SIGNIFICANT]: Dependency graph ASCII in tasks.md is visually inaccurate/misleading.
  [Finding]: MAD-006 appears with duplicate arrows (from MAD-004a and a dangling MAD-006 under MAD-004 branch); MAD-005 positioned ambiguously before MAD-007 convergence. Table deps are clearer but don't match graph perfectly.
  [Why]: Confusion in sequencing could cause premature task starts (e.g., overlooking MAD-004a for MAD-006). Harms clarity and sequencing correctness.
  [Fix]: Simplify ASCII or use table deps only. Confirm: MAD-006 deps MAD-004a + MAD-005 implicitly via parallel.

- [F5]
  [SIGNIFICANT]: No explicit task or mitigation for sourcing cold artifacts despite noted risk.
  [Finding]: M3 key risk "Cold artifact availability" (Phase 3 stalls without them), cross-project dep listed as "Dependent on pipeline output", but no task like "MAD-XXX: Curate 10+ cold artifact candidates". MAD-013 assumes "define batch manifest" succeeds.
  [Why]: Under-scopes M3 prep; if pipelines dry up, gate stalls indefinitely, violating feasibility and risk assessment accuracy.
  [Fix]: Add MAD-012.5 (todo, low risk, #research): "Source and validate 10+ cold artifacts from Scout/FIF/active projects. List in batch-manifest-candidates.md with novelty confirmation."

- [F6]
  [SIGNIFICANT]: Task MAD-003 (dispatch agent) over-scoped for atomicity.
  [Finding]: Single task packs adaptation of peer-review pattern + concurrent dispatch + stagger + metadata capture + sensitivity check + failure handling + version hashes. Risk marked Medium/Largest.
  [Why]: High failure risk if any sub-feature slips; violates atomic task principle (one AC-failable unit), inflating implementation risk beyond assessment.
  [Fix]: Split to MAD-003a (prompt assembly + dispatch basics), MAD-003b (metadata/failures/stagger). Update deps/AC accordingly.

- [F7]
  [MINOR]: Confusing task ID numbering (MAD-001a precedes MAD-001).
  [Finding]: Breaks sequential ID expectation; MAD-001a is M0 but numbered as if M1 variant.
  [Why]: Minor navigation friction in 19-task list; could cause skip errors.
  [Fix]: Renumber M0 Phase 0b as MAD-000b or MAD-017 (post-M16).

- [F8]
  [MINOR]: M0 artifact count ambiguity/overlaps.
  [Finding]: Action-plan M0 success: "3-5 warm artifacts"; MAD-000 (2-3), MAD-001a (3-5, "may reuse") -- potential for <3 unique total.
  [Why]: Undercuts "calibration anchor set" robustness if reuse inflates overlap. Minor scoping gap.
  [Fix]: MAD-001a AC: ">=3 unique artifacts total across M0 (reuse ok but log uniques)."

- [F9]
  [MINOR]: H1 fixed to "Business Advisor" overlay without rationale or generalization.
  [Finding]: MAD-005 specifies "same overlay (Business Advisor)"; others undefined. Action-plan generic.
  [Why]: Limits hypothesis test representativeness; if BA low-variance, skews H1. Minor under-scope.
  [Fix]: Generalize AC: "Test on 1-2 overlays (e.g., BA + Technical)" or justify BA choice.

- [F10]
  [MINOR]: Risk register omits cost tracking implementation task.
  [Finding]: Risks mention "Per-deliberation tracking + $2.00 abort", but no task builds cost capture (MAD-004 mentions records but not costs explicitly).
  [Why]: Assumes infra handles it; gap if not. Minor feasibility risk.
  [Fix]: Add to MAD-004 AC: "Cost fields (prompt_tokens, completion_tokens, total_usd) in record per evaluator."

- [F11]
  [STRENGTH]: Baseline-first M0 approach.
  [Finding]: M0 tests single-Opus multi-lens cheaply ($1-3) before infra; reuses artifacts; sets calibration anchor early. Edge case (strong baseline) handled as valid no-go.
  [Why]: Maximizes learning/cost ratio; correctly front-loads highest-leverage test per design decision #1. Verified: Phases explicitly pre-infra.

- [F12]
  [STRENGTH]: Gated progression with explicit go/no-go at each milestone.
  [Finding]: Hard deps via gates; pivot/stop options; re-rate anchors for drift. Covers spec via hypothesis tests (H1-H4).
  [Why]: Ensures minimum cost for learning; accurate risk assessment (e.g., early kill saves $15-37). Verified against artifacts.

- [F13]
  [STRENGTH]: Risk register accuracy and mitigations.
  [Finding]: Covers top risks (dispatch, prompts, cold artifacts, drift) with targeted mitigations (proven patterns, limits, anchors, fallbacks). Levels realistic (e.g., baseline-kill "Low" as ROI-positive).
  [Why]: Matches key decision #3; enables feasibility. Verified: Mitigations traceable to tasks (e.g., SS8.6 in MAD-009).

- [F14]
  [STRENGTH]: Most acceptance criteria are binary and testable.
  [Finding]: ~80% crisp (e.g., "file exists", ">=5 records", "flag set correctly"); domains tagged (#code/#research).
  [Why]: Supports key decision #4; enables unambiguous gates. Verified: Scanned tables.

- [F15]
  [STRENGTH]: Task sequencing/dependency graph mostly correct.
  [Finding]: Linear milestone flow; parallels (e.g., MAD-001/002) logical; infra before tests. Total 19 atomic tasks well-balanced (7 code, 7 research).
  [Why]: Upholds key decision #2; feasible scoping. Verified: No cycles; gates enforce. (Minor graph issues notwithstanding.)

---

## Synthesis

### Consensus Findings

**CF-1: MAD-002 dependency gap (OAI-F6, GEM-F3, GRK-F2).** MAD-002 (schema) has no dependency on the M0 gate, which allows it to start before baseline validation. Contradicts the milestone-level constraint that M1 doesn't begin until M0 passes.

**CF-2: Acceptance criteria need tightening (OAI-F5, DS-F3, GRK-F3).** ~20% of acceptance criteria are "document exists" or "qualitative annotation" rather than binary testable. Examples: "friction points documented," "Danny evaluates synthesis patterns," "clear recommendation document exists."

**CF-3: Cold artifact sourcing needs a task (OAI-F19, DS-F4, GRK-F5, GEM-F8).** All 4 reviewers flagged that M3's cold artifact dependency has no proactive task to secure artifacts ahead of time. The risk is identified but not operationalized.

**CF-4: Dependency graph ASCII is confusing (OAI-F7 implicitly, GEM-F6, DS-F10, GRK-F4).** Duplicate arrows to MAD-006, disconnected layout for M3/M4, visual inconsistencies with the tabular dependencies.

**CF-5: Section reference inconsistency §5.6 vs §5.9 (OAI-F13, GRK-F1).** MAD-001a references "refined §5.6 procedure" while the action plan references "§5.9 rating procedure." These reference the same thing (§5.9 is the procedure, §5.6 is the rubric it uses) but the inconsistency reads as a potential error.

### Unique Findings

**OAI-F8: Finding granularity and deduplication rules undefined.** The core metrics (unique finding counts, R2 counts, novelty) depend on what constitutes a "finding" and how deduplication works, but neither the action plan nor tasks define this operationally. **Genuine insight** — this is a methodology gap. However, the spec's §5.9 Rating Procedure does define the extraction, deduplication, and rating workflow in detail. The action plan should reference this more explicitly rather than redefining it.

**OAI-F11: Order effects in H2 condition comparison.** If Danny reviews conditions sequentially for the same artifact, recognition and memory distort novelty judgments. **Genuine insight** — the blinding protocol (§5.8) strips evaluator IDs but doesn't address condition-order effects. Worth adding a note to randomize condition order during rating.

**OAI-F14: Baseline fairness risk missing from risk register.** The plan handles prompt parity via MAD-004a, but the risk register doesn't list "baseline unfairness" explicitly. **Valid** — adding this is cheap and makes the risk register more complete.

**OAI-F16: Partial panel handling for experimental validity.** If some runs have 4 evaluators and others 3, H1/H2/H3 comparisons become uneven. **Valid concern** but mitigated by the spec's §8.5 failure semantics (incomplete deliberations excluded). The action plan should reference this.

**OAI-F28: Pass 2 novelty categories undefined.** H3 requires distinguishing truly new Pass 2 findings from refinements or restated positions. **Genuine insight** — adding novelty categories (new claim, strengthened claim, corrected claim, non-novel response) would improve H3 measurement.

**DS-F2: MAD-004a dependency is wrong.** Baseline prompt development doesn't require a functioning deliberation skill — it's a research/design task. Making it depend on MAD-004 introduces unnecessary sequencing delay. **Valid** — MAD-004a should depend on MAD-001a (gate pass) only, feeding into MAD-006.

**GRK-F9: H1 overlay choice not justified.** MAD-005 fixes Business Advisor as the overlay for H1 testing without rationale. If BA happens to produce low variance, H1 could fail for artifact-specific reasons. **Minor but valid** — consider testing on 2 overlays or justifying the BA choice.

**GRK-F10: Cost tracking not explicitly in MAD-004 acceptance criteria.** The abort criterion references per-deliberation cost tracking, but no task builds cost capture. **Valid** — add cost fields to MAD-004 acceptance criteria.

### Contradictions

**MAD-003 scope:** GRK-F6 says MAD-003 is over-scoped and should be split. OAI-F3 and DS-S2 say it's "manageable" as one task. GEM doesn't flag scope. **Assessment:** The task is substantial but the peer-review-dispatch template makes it adaptation rather than greenfield. Keep as one task but add the provider failure simulation test (DS-F7) to the acceptance criteria.

**MAD-004a dependency:** DS-F2 says MAD-004a should NOT depend on MAD-004 (the skill). The current dependency makes it sequential after the skill is built. DS is right that prompt development is research, not implementation — it could start earlier. But prompt testing benefits from having the skill available (to verify schema compliance). **Assessment:** Move MAD-004a dependency to MAD-001a (gate pass) + MAD-002 (schema needed for prompt compliance). It can proceed in parallel with MAD-003/004 infrastructure.

### Action Items

#### Must-Fix

- **A1** (CF-1) — [OAI-F6, GEM-F3, GRK-F2] **Fix MAD-002 dependency.** Change `Depends On` to `MAD-001a (gate pass)` to align with milestone gating.

- **A2** (CF-3) — [OAI-F19, DS-F4, GRK-F5, GEM-F8] **Add cold artifact sourcing task.** New task in M2: "Source and validate 10+ cold artifact candidates from Scout/FIF/active projects. Confirm novelty and suitability. Write batch-manifest-candidates.md." Prerequisite to MAD-013.

- **A3** (DS-F2) — [DS-F2] **Fix MAD-004a dependency.** Change from `MAD-004` to `MAD-001a (gate pass), MAD-002`. This allows baseline prompt development to proceed in parallel with infrastructure build, removing unnecessary sequencing delay.

#### Should-Fix

- **A4** (CF-2) — [OAI-F5, DS-F3, GRK-F3] **Tighten weakest acceptance criteria.** Specific fixes: MAD-000 add "≥3 friction points with before/after diffs"; MAD-001a add "baseline quality summary includes finding counts, rating distribution, and explicit proceed/reassess recommendation"; MAD-007/011/014 add "gate evaluation includes threshold results table with pass/fail per criterion"; MAD-013 add "Danny's evaluation includes novelty/actionability/non-obviousness rating per synthesis pattern."

- **A5** (CF-4) — [GEM-F6, DS-F10, GRK-F4] **Simplify dependency graph.** Replace the confusing ASCII graph with a cleaner version that strictly matches the tabular dependencies. Remove duplicate MAD-006 arrow.

- **A6** (CF-5) — [OAI-F13, GRK-F1] **Normalize section references.** Standardize to "§5.9 rating procedure (using §5.6 rubric)" throughout.

- **A7** (OAI-F14) — **Add baseline fairness risk to risk register.** "Baseline prompt mismatch could make panel appear better for the wrong reason. Mitigation: MAD-004a prompt parity checks, schema parity, comparable token budgets."

- **A8** (OAI-F28) — **Define Pass 2 novelty categories.** Add to MAD-010 acceptance criteria: "Pass 2 findings classified as: new claim, strengthened claim, corrected claim, or non-novel response."

- **A9** (GRK-F10) — **Add cost tracking to MAD-004 acceptance criteria.** "Deliberation record includes per-evaluator cost fields (prompt_tokens, completion_tokens, estimated_cost_usd)."

- **A10** (OAI-F11) — **Add condition-order randomization note.** In Phase 1c description: "Rate conditions in randomized order per artifact to avoid recognition/memory effects."

#### Defer

- **A11** (OAI-F4, GRK-F7, DS-F9) — Task ID renumbering. MAD-001a before MAD-001 is mildly confusing but not blocking. Renumbering risks creating churn across spec and plan references. Accept the naming and add a brief note explaining the M0/M1 split.
- **A12** (OAI-F8) — Finding definition methodology section. The spec's §5.9 already defines the extraction and deduplication procedure in detail. Adding a duplicate in the action plan risks drift. Reference §5.9 explicitly instead.
- **A13** (GEM-F5) — Human fatigue risk for MAD-006. Valid concern (up to 600 findings to rate). The attention-budget abort criterion (3hr/phase) already covers this. Adding it to the risk register is reasonable but the mitigation is already in place.
- **A14** (GEM-F7) — Baseline terminology disambiguation. "Phase 0 baseline" vs. "primary baseline" is a fair naming concern but the distinction is clear from context (single-Opus-combined vs. 4-GPT-5.4-separate). Not worth renaming at this stage.
- **A15** (GRK-F6) — Split MAD-003 into MAD-003a/003b. The task is substantial but it's adaptation of proven pattern, not greenfield. Splitting adds coordination overhead. Keep as one task, add provider failure test to AC.
- **A16** (OAI-F30) — Traceability appendix mapping spec sections to tasks. Valid for governance rigor but adds maintenance burden. The spec's §16 already maps tasks to spec requirements.

### Considered and Declined

- **OAI-F9** (reliability check beyond calibration anchors): `overkill` — Adding inter-rater reliability or split-half reliability to a solo-operator experiment adds statistical ceremony without a path to improvement. The calibration anchor is the appropriate lightweight control.
- **OAI-F10** (require non-overlapping Phase 0a/0b artifacts): `constraint` — Phase 0 is procedure validation + baseline establishment. Reusing artifacts is fine for testing the procedure; the baseline quality assessment is what matters, not artifact novelty.
- **OAI-F17** (explicit instrumentation for Pass 2 quality monitoring): `overkill` — Token counts and truncation flags are already in the spec (§8.6, version tracking). Schema compliance is enforced via Layer 3. Adding a separate quality monitoring task is over-engineering for an experiment.
- **OAI-F23** (synthesis evaluation rubric): `constraint` — H4 is already defined with specific success criteria (≥2 actionable patterns confirmed as novel). Adding a separate rubric for synthesis evaluation adds ceremony without improving the gate decision.
- **GRK-F9** (test H1 on 2 overlays): `constraint` — H1 tests model diversity with a controlled overlay. Using a single overlay isolates the variable. Business Advisor is the most general overlay. Testing multiple overlays is an H2 concern, not H1.
- **DS-F1** (rename MAD-001a to MAD-0-GATE): `overkill` — The gate mechanism is clear from the milestone structure and acceptance criteria. Renaming adds churn without clarity.
