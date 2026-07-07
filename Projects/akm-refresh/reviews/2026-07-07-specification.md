---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/akm-refresh/specification.md
artifact_type: spec
artifact_hash: bee91a9f
prompt_hash: 5ef7c1c9
base_ref: null
project: akm-refresh
domain: software
skill_origin: peer-review
created: 2026-07-07
updated: 2026-07-07
reviewers:
  - openai/gpt-5.4
  - google/gemini-3.1-pro-preview
  - grok/grok-4.3
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
    latency_ms: 37050
    attempts: 1
    raw_json: Projects/akm-refresh/reviews/raw/2026-07-07-specification-openai.json
  google:
    http_status: 200
    latency_ms: 45473
    attempts: 1
    raw_json: Projects/akm-refresh/reviews/raw/2026-07-07-specification-google.json
  deepseek:
    http_status: 0
    latency_ms: 120011
    attempts: 2
    error: curl timeout (exit 28) at configured 120s on both attempts; empty response body
    raw_json: Projects/akm-refresh/reviews/raw/2026-07-07-specification-deepseek-truncated.json
  grok:
    http_status: 200
    latency_ms: 16468
    attempts: 1
    system_fingerprint: fp_eb3c003fc66c14ed
    raw_json: Projects/akm-refresh/reviews/raw/2026-07-07-specification-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: akm-refresh specification

**Artifact:** Projects/akm-refresh/specification.md
**Mode:** full
**Reviewed:** 2026-07-07
**Reviewers:** OpenAI gpt-5.4, Google gemini-3.1-pro-preview, xAI grok-4.3 (DeepSeek deepseek-v4-pro failed: curl timeout)
**Review prompt:** Structured spec review at the SPECIFY phase gate — judge whether PLAN can proceed. Evaluate correctness, completeness, internal consistency, feasibility, clarity. Findings classified CRITICAL / SIGNIFICANT / MINOR / STRENGTH; unverifiable factual claims flagged as SIGNIFICANT with "UNVERIFIABLE CLAIM:" prefix. C1–C7 treated as settled constraints unless internally inconsistent with the spec's own evidence. Grok received the problem-prioritization addendum per config.

---

## OpenAI (gpt-5.4)

## Overall Assessment

**Recommendation: Proceed to PLAN, with a small number of pre-PLAN clarifications.**

The spec is generally strong: it is evidence-driven, scoped appropriately for SPECIFY, and does a good job separating facts, assumptions, unknowns, constraints, and tasks. The central intervention logic is coherent: fix the collapsed live mode, restore noise controls, validate transport against the 2s SLO, and mechanize the missing feedback loops.

I do **not** see a blocking internal contradiction that should stop planning. The main weaknesses are:
1. a few **unverified factual claims** that should be grounded before planning relies on them,
2. one notable **acceptance ambiguity** around latency/fallback behavior,
3. a few places where success criteria and task acceptance could be tightened to avoid interpretation drift at PLAN.

---

## Findings

- [F1]
- [Severity]: STRENGTH
- [Finding]: The spec has a clear problem statement tightly tied to measured evidence, especially around retrieval mode inversion, noise behavior, and missing feedback loops.
- [Why]: This is exactly what a SPECIFY artifact should do before planning: define the problem with enough precision that implementation choices can be evaluated against explicit evidence rather than intuition.
- [Fix]: None.

- [F2]
- [Severity]: STRENGTH
- [Finding]: The separation into **Facts / Assumptions / Unknowns** is well executed and materially improves decision quality.
- [Why]: It prevents premature commitment, especially on daemon viability, structured-query quality, score-floor behavior, and hook payload shape. This is important because several major design choices rest on assumptions A1–A4 that are appropriately marked for validation.
- [Fix]: None.

- [F3]
- [Severity]: STRENGTH
- [Finding]: The constraints are mostly coherent and appropriately treated as settled, especially C1, C2, C6, and C7.
- [Why]: The spec respects the review instruction not to relitigate prior decisions except for inconsistency. The constraints appear internally compatible with the proposed work and give PLAN a stable boundary.
- [Fix]: None.

- [F4]
- [Severity]: STRENGTH
- [Finding]: The task decomposition is strong and sequencing is mostly sensible, particularly the split between research/decision/code and the explicit approval gates for AKM-005 and AKM-007.
- [Why]: This reduces planning risk and makes it clear where uncertainty is meant to be resolved before implementation.
- [Fix]: None.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: **UNVERIFIABLE CLAIM:** Multiple quantitative claims rely on `_system/docs/akm-evaluation-2026-07.md` and `_system/data/akm/evl-rerun-2026-07-07.json`, including “BM25 43%, semantic 71%, hybrid 100%,” “344 of 347 retrievals surfaced something,” “semantic ~1.9s, hybrid ~4.8s,” and fixture baselines such as “recall@5 bm25 0.34 · vector 0.64 · hybrid 0.60 · full 0.70.”
- [Why]: These may be true, but they are not independently verifiable from the spec text alone. Because they drive both prioritization and acceptance thresholds, they should be explicitly re-grounded before planning commits to them.
- [Fix]: Add a brief “verification checklist” or appendix table in the spec quoting the exact source sections / commands / timestamps used to derive each critical metric, or require this as a PLAN entry criterion.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: **UNVERIFIABLE CLAIM:** The spec states that qmd 2.5 ships `qmd mcp --http --daemon` and implies this is available in the target environment.
- [Why]: This claim is central to A1 and AKM-001. If the capability, flags, or deployment assumptions differ, the transport strategy and even feasibility of semantic/hybrid under the SLO may change.
- [Fix]: Add an explicit pre-PLAN verification step or note under AKM-001: confirm exact qmd version/flags installed locally and capture `qmd --help` or equivalent output in the design memo.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: **UNVERIFIABLE CLAIM:** The spec references specific file paths, line numbers, and implementation details such as `knowledge-retrieve.sh:322`, `qmd_mode_for_trigger()` at line 303, wrapper length 918 lines, `skill-preflight.sh` length 251 lines, and telemetry totals of 347 events.
- [Why]: These details may drift quickly and are not independently confirmable from the artifact. Since line numbers in particular are brittle, planning based on them can create confusion.
- [Fix]: Replace brittle line-specific references with function names plus a note like “line numbers as of 2026-07-07,” or move precise references into a source audit appendix.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: The spec has an ambiguity around the latency/SLO acceptance path if the daemon is rejected. AKM-001 says fallback is “CLI vector mode if daemon rejected,” but Success Criterion 2 and AKM-003 acceptance require `≤ 2s warm p95` on the chosen transport.
- [Why]: Based on the stated numbers, CLI semantic at ~1.9s warm is near the boundary and may fail p95 depending on wrapper overhead and variability; hybrid CLI clearly exceeds it. If daemon is rejected and CLI vector is chosen, the project may pass or fail depending on exact measurement details not yet defined.
- [Fix]: Add a pre-PLAN decision rule: “If no transport/mode combination satisfies both recall floor and warm p95 ≤2s end-to-end, the project does not proceed to implementation of live mode flip and instead produces a design exception for operator decision.” Also define whether p95 excludes cold starts.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: The success criteria mix metrics from different evaluation sets without fully defining how they relate: fixture recall@5 ≥ 0.64, within-domain EVL ≥ 71%, and noise expectations on N3 / noise queries.
- [Why]: This is workable, but at PLAN the team will need an exact acceptance matrix to avoid arguments over whether one benchmark can compensate for another. For example, what if fixture recall is 0.66 but EVL within-domain drops below 71%?
- [Fix]: Add an explicit pass/fail matrix such as: “R2 passes only if all of: fixture recall threshold met, EVL within-domain threshold met, N3 empty, score-0 never surfaced, latency threshold met.”

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: The spec assumes empty briefs are acceptable and likely beneficial, but U5 is only listed as an unknown and not strongly tied to a gating decision.
- [Why]: Empty-brief tolerance is foundational to A3 and to the proposed noise-control strategy. If downstream consumers mis-handle empty output, the retrieval fix could create user-visible regressions even while improving quality.
- [Fix]: Elevate U5 into an explicit precondition in AKM-002 or AKM-003 acceptance, e.g., “demonstrate no-error/no-noise behavior for empty briefs across at least all hooked skill-preflight consumers.”

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: There is a slight scope/acceptance mismatch for AKM-004. The task is named “Fixture re-baseline + soak definition,” but Success Criterion 7 requires a completed ≥2-week soak.
- [Why]: As written, the project’s success depends on a post-implementation observation period that is not itself fully represented as a deliverable/task beyond defining the soak.
- [Fix]: Either add a separate task for “AKM-010 — Execute and close soak” or state explicitly that project completion requires a post-IMPLEMENT operational validation window outside the task list.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: The spec says R3 is a prerequisite for chronic-miss re-enable, decay retuning, and chapter-digest decisions, but it does not define the minimal linkage model needed for “linkable to prior surfacing.”
- [Why]: AKM-005/006 acceptance depends on linkage, but without specifying the identity strategy, planners may under-design schema changes and later discover they cannot reliably reconcile read events to surfaced items.
- [Fix]: Add a minimal linkage requirement now, such as surfacing-event ID + note path + session/tool context + timestamp window, even if full schema details remain for design.

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: AKM-007’s new-content hook design goal is functionally clear, but the trigger predicate is still underspecified in a way that could materially affect noise and loop behavior.
- [Why]: “Write|Edit detecting `#kb/`-tagged files under `Sources/`” leaves open whether the tag must be newly introduced, merely present, or present after save; whether moves/renames count; and how repeated edits are coalesced. These details matter because the system has already exhibited behavioral/automation brittleness.
- [Fix]: Add a few normative trigger semantics in the spec: e.g., “fire on save when file path under `Sources/` and current file contents contain `#kb/`; debounce by path for N seconds; no self-trigger on AKM-generated writes.”

- [F14]
- [Severity]: MINOR
- [Finding]: The naming around R2/R3/R4/R5 is not fully self-explanatory within this artifact.
- [Why]: A reader can infer them from context, but PLAN participants may have to repeatedly map “R2” to wrapper/mode redesign, “R3” to consumption hook, etc.
- [Fix]: Add a short “Workstreams” subsection that names each R-stream explicitly.

- [F15]
- [Severity]: MINOR
- [Finding]: “full 0.70” in F7 is not defined in the artifact.
- [Why]: It is probably obvious to authors familiar with the evaluation setup, but not to a fresh planner/reviewer. Undefined metric labels create avoidable ambiguity.
- [Fix]: Expand F7 to define “full” precisely.

- [F16]
- [Severity]: MINOR
- [Finding]: The phrase “the March known-miss class (attention-manager-style domain/subject divergence)” in Success Criterion 6 assumes historical context not summarized here.
- [Why]: This is understandable to insiders but weakens standalone readability.
- [Fix]: Add a one-line parenthetical explanation of that miss class in the spec.

- [F17]
- [Severity]: MINOR
- [Finding]: The rollback strategy in AKM-003 acceptance is probably too optimistic as written: “single-function git revert.”
- [Why]: If `knowledge-retrieve.sh`, `skill-preflight.sh`, and transport wiring all change together, rollback may not be single-function in practice.
- [Fix]: Rephrase to “rollback path documented and tested; ideally isolated to mode-routing/query-construction changes if implementation preserves that boundary.”

- [F18]
- [Severity]: MINOR
- [Finding]: Some acceptance criteria use qualitative wording where more exact phrasing would help, e.g., “all triggers still function,” “empty briefs become normal output,” and “tolerate empty briefs gracefully.”
- [Why]: These are directionally right but can lead to weak test plans.
- [Fix]: Convert them into observable conditions, such as no hook errors, no malformed brief injection, and preserved behavior on non-eligible paths.

- [F19]
- [Severity]: STRENGTH
- [Finding]: The spec appropriately treats “noise is the primary risk” as a governing design principle and connects it to concrete mitigations: accept-empty, score-0 drop, splitting removal, and soak observation.
- [Why]: This keeps the project from optimizing recall in a way that would repeat the original failure mode.
- [Fix]: None.

- [F20]
- [Severity]: STRENGTH
- [Finding]: The distinction between fixture benchmarking and live soak is well reasoned and consistent with the cited principle that “benchmarks filter, live soak decides.”
- [Why]: This is a mature framing for retrieval systems, where offline metrics alone often miss user-facing failure modes.
- [Fix]: None.

- [F21]
- [Severity]: STRENGTH
- [Finding]: The spec stays disciplined about scope by explicitly excluding trigger-role redesign, chronic-miss re-enable, decay retuning, and serendipity revival.
- [Why]: That makes planning tractable and reduces the risk of the project turning into a full AKM redesign.
- [Fix]: None.

- [F22]
- [Severity]: SIGNIFICANT
- [Finding]: The spec does not explicitly define what counts as an “operator-flagged noise regression” for Success Criterion 7.
- [Why]: Since soak is the final verdict, this criterion should be operationalized; otherwise success can become subjective or inconsistently logged.
- [Fix]: Define a flagging mechanism and threshold now, e.g., any manually logged retrieval judged false-positive/noisy in run-log, with severity and frequency criteria.

- [F23]
- [Severity]: SIGNIFICANT
- [Finding]: The hook overhead requirement for AKM-006/008 is sensible, but the measurement basis is not specified.
- [Why]: For ubiquitous PostToolUse hooks, “<50ms” needs a clear measurement point: script runtime only, end-to-end hook overhead, warm only, or p95 across realistic events.
- [Fix]: Specify acceptance as e.g. “end-to-end added hook latency p95 <50ms for eligible and non-eligible paths on a warm local system.”

- [F24]
- [Severity]: CRITICAL
- [Finding]: None identified.
- [Why]: I do not find an internal contradiction or omission severe enough to block planning outright.
- [Fix]: None.

---

## Specific factual claims not independently verifiable

Per your instruction, these are explicitly flagged rather than silently passed:

- [UVC1]
- [Severity]: SIGNIFICANT
- [Finding]: **UNVERIFIABLE CLAIM:** qmd version/capability claim: “qmd 2.5 ships `qmd mcp --http --daemon`.”
- [Why]: Central to transport feasibility and latency assumptions.
- [Fix]: Verify locally and cite command output in AKM-001.

- [UVC2]
- [Severity]: SIGNIFICANT
- [Finding]: **UNVERIFIABLE CLAIM:** Evaluation statistics in F1/F3/F5/F7/F8, including hit rates, score overlaps, telemetry counts, and fixture baselines.
- [Why]: These are decision-driving numbers but not independently confirmable from the artifact alone.
- [Fix]: Add source excerpt/table with exact provenance.

- [UVC3]
- [Severity]: SIGNIFICANT
- [Finding]: **UNVERIFIABLE CLAIM:** Timing figures in F2 and F8, including CLI warm/cold timings, in-process benchmark timings, and wrapper end-to-end 0.97s.
- [Why]: SLO feasibility depends on them.
- [Fix]: Include benchmark method and sample size summary.

- [UVC4]
- [Severity]: SIGNIFICANT
- [Finding]: **UNVERIFIABLE CLAIM:** File paths, line numbers, hook/config locations, and script sizes such as `knowledge-retrieve.sh:322`, `:303`, “918 lines,” and “251 lines.”
- [Why]: These may drift and cannot be checked from the artifact.
- [Fix]: Replace with less brittle references or append a dated code audit snapshot.

---

## Summary judgment by review dimension

### Correctness
Mostly sound. No major internal contradictions found. Main issue is that some key claims are externally grounded but not independently verifiable from the artifact.

### Completeness
Good for SPECIFY. The biggest completeness gaps are:
- explicit pass/fail matrix across benchmarks and SLO,
- explicit empty-brief compatibility gate,
- explicit soak execution/closure deliverable,
- minimal event-linkage requirements for R3.

### Internal consistency
Strong overall. Minor tension exists around fallback transport versus SLO guarantees, but it is resolvable with a clearer decision rule.

### Feasibility
Reasonably feasible if daemon viability and hook payload assumptions are validated early. The staged tasking reflects that.

### Clarity
Generally clear and readable for a technical spec. A few undefined labels and historical references could be tightened.

---

## Final Recommendation

**Proceed to PLAN**, provided the following are addressed either in a brief spec revision or as explicit PLAN entry criteria:

1. Verify the qmd daemon capability and key evaluation/timing claims.
2. Add a precise acceptance matrix tying together fixture, EVL, noise, and latency requirements.
3. Make empty-brief handling an explicit gate, not just an unknown.
4. Clarify soak completion/closure ownership.
5. Define minimal linkage semantics for consumption events.
6. Operationalize “operator-flagged noise regression.”

With those tightened, the spec is strong enough to support implementation planning.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of the `akm-refresh` specification, evaluating its readiness for the PLAN phase. 

- [F-01]
- [Severity]: CRITICAL
- [Finding]: Mathematical contradiction regarding the CLI semantic fallback and the 2s SLO (C1).
- [Why]: F2 states the semantic CLI warm latency is ~1.9s. F8 states the wrapper currently takes 0.97s end-to-end on a BM25 path (where the BM25 query itself is 0.16s, implying ~0.81s of wrapper overhead). Therefore, a CLI semantic fallback would take ~2.71s (1.9s + 0.81s), which structurally violates the 2.0s SLO constraint (C1). AKM-001 assumes the CLI semantic mode is a viable fallback if the daemon is rejected, but mathematically it will fail Success Criterion 2.
- [Fix]: In AKM-001/AKM-002, explicitly mandate that wrapper overhead must be profiled and optimized if the CLI fallback is chosen, or grant an explicit SLO exemption for the fallback path (e.g., "accept >2s latency if daemon is unviable").

- [F-02]
- [Severity]: SIGNIFICANT
- [Finding]: Mismatch between the benchmark metric (Recall@5) and the operational budget (3) for the primary trigger.
- [Why]: F8 states the budget for skill-activation is 3 docs. However, F7 and Success Criterion 1 use `recall@5` as the baseline metric. If the engine ranks a relevant document at position 4 or 5, the fixture will count it as a "hit" (boosting the recall@5 score), but the post-filter budget of 3 will drop it before it reaches the agent. This creates a false sense of security.
- [Fix]: Change the Success Criterion 1 and the AKM-004 fixture baseline to evaluate `recall@3` for skill-activation queries, matching its real-world budget constraint.

- [F-03]
- [Severity]: SIGNIFICANT
- [Finding]: No fallback plan for assumption A4 / unknown U3 (Claude Code PostToolUse payload shape).
- [Why]: AKM-005 and AKM-007 are gated on the assumption that Claude Code exposes the necessary file paths/events in its hook payloads. If the API check fails, the entirety of the consumption (R3) and cross-pollination (R4) capabilities are blocked, endangering Success Criteria 4 and 5.
- [Fix]: Add a contingency to the A4 validation step or AKM-005/007 design. Specify what happens if the payload lacks path data (e.g., fallback to tailing Claude Code JSON logs, or cleanly descoping Success Criteria 4 and 5 from this specific project).

- [F-04]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: `qmd` search engine versions, capabilities, and the `embeddinggemma-300M` model. 
- [Why]: The spec relies heavily on `qmd 2.5.3`, `qmd mcp --http --daemon`, and `embeddinggemma-300M`. These appear to be internal, unreleased, or highly customized local software tools and models. They cannot be independently verified against public documentation.
- [Fix]: Proceed with planning, provided these tools and capabilities demonstrably exist and function within the local Crumb environment as claimed.

- [F-05]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Claude Code `PostToolUse` hook specifications.
- [Why]: The existence, event timing, and exact payload schema of `PostToolUse` hooks natively inside Anthropic's Claude Code CLI cannot be independently verified in available public documentation.
- [Fix]: The A4 validation step in the spec is correctly positioned to test this, but must strictly verify the exact payload shape before proceeding with R3/R4 design.

- [F-06]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: F1, F2, F5, and F7 internal statistics and test data.
- [Why]: Metrics such as "BM25 43%, semantic 71%, hybrid 100%", latency benchmarks ("in-process 3ms/61ms/144ms/121ms"), usage stats ("347 retrievals lifetime"), and regression fixture baselines ("recall@5 bm25 0.34") are attributed to internal files (`_system/docs/akm-evaluation-2026-07.md`). I cannot independently verify them.
- [Fix]: Verify the referenced internal documents before phase gate sign-off to ensure the foundational data supporting this spec is accurate.

- [F-07]
- [Severity]: MINOR
- [Finding]: Misplaced task dependency wording in AKM-009.
- [Why]: AKM-009 states: "if AKM-003 moves skill-activation off BM25...". However, AKM-003 is the implementation task. The actual *decision* to move off BM25 occurs in AKM-002.
- [Fix]: Update AKM-009 to read "if the AKM-002 design decision moves skill-activation off BM25...".

- [F-08]
- [Severity]: MINOR
- [Finding]: Empty-brief downstream tolerance (U5) validation timing.
- [Why]: U5 is listed as an unknown (whether downstream consumers tolerate empty briefs gracefully), and AKM-002 decides on empty-brief handling. However, the system map doesn't explicitly allocate task time to test U5 before designing the handling.
- [Fix]: Make the U5 test an explicit precondition in AKM-002 before finalizing the empty-brief design approach.

- [F-09]
- [Severity]: STRENGTH
- [Finding]: Strict boundary management between mechanism and policy.
- [Why]: The specification explicitly limits scope to building the consumption instrument (R3) while explicitly deferring policy decisions (chronic-miss suppression re-enabling, decay retuning) to a future project based on real data. This is excellent systems engineering that prevents scope creep and oscillation.

- [F-10]
- [Severity]: STRENGTH
- [Finding]: Two-phase evaluation methodology.
- [Why]: "Fixture is the filter, soak is the verdict" (F9 / Success Criterion 7) ensures both empirical baseline improvement (avoiding regressions) and practical usability (verifying the noise constraints). This directly addresses the complex reality of overlapping score distributions (F3).

---

## DeepSeek (deepseek-v4-pro)

*No review — dispatch failed.* Both attempts hit the configured 120s curl timeout (curl exit 28) mid-generation; response body was empty. deepseek-v4-pro thinking-mode generation exceeds `curl_timeout: 120` for this artifact size. Truncated body stored at `raw/2026-07-07-specification-deepseek-truncated.json`.

---

## Grok (grok-4.3)

F1
[Severity]: SIGNIFICANT
[Finding]: UNVERIFIABLE CLAIM: All quantitative evidence (F1 hit rates of 71%→43%, 344/347 retrievals, score distributions 0.55 vs 0.46, latency numbers 0.16s/1.9s/4.8s, 347 lifetime events, fixture baselines 0.34/0.64/0.60/0.70, etc.) is attributed solely to `_system/docs/akm-evaluation-2026-07.md` (R1) and `_system/data/akm/evl-rerun-2026-07-07.json`.
[Why]: These specific statistics, version references (qmd 2.5.3, embeddinggemma-300M), and file-derived measurements cannot be independently verified from the supplied artifact.
[Fix]: Prefix every such claim with an explicit "Source: R1 report (unverified externally)" disclaimer or move the raw numbers into an appendix that reviewers can treat as provisional.

F2
[Severity]: CRITICAL
[Finding]: Constraint C5 ("KB-only retrieval scope is settled and correct — the Herodotus case confirmed it") directly references the same Herodotus incident described in F4 as a false-positive manufactured by the keyword-splitting hack, not by cross-domain retrieval itself.
[Why]: This creates an internal inconsistency: the spec uses one event both to justify a permanent scope restriction and to justify removing the hack that produced the event.
[Fix]: Either drop the Herodotus justification from C5 or rephrase C5 to cite only the original design rationale rather than the specific incident.

F3
[Severity]: SIGNIFICANT
[Finding]: Success criterion 1 requires the chosen mode to achieve recall@5 ≥ 0.64 on the fixture and within-domain ≥ 71% on the EVL set, yet AKM-002 still permits selecting pure vector (which meets the fixture number) while the EVL within-domain number for vector is only stated as 71% in F1 without confirming it beats the 71% semantic figure on the exact same queries.
[Why]: The two acceptance thresholds can be satisfied by different modes, leaving the final choice under-specified.
[Fix]: Add an explicit tie-breaker rule in AKM-002 (e.g., "within-domain EVL rate takes precedence over fixture recall@5").

F4
[Severity]: SIGNIFICANT
[Finding]: A4 and U3 assume PostToolUse payloads expose file paths for Read/Write/Edit, but no example payload shape or Claude Code hook documentation reference is supplied.
[Why]: Tasks AKM-005 and AKM-007 are gated on this unverified assumption; failure blocks both new primitives.
[Fix]: Insert a concrete validation step (or sample payload) before the design gates in AKM-005/007.

F5
[Severity]: MINOR
[Finding]: The "Levers" section ranks "Mode flip" first but does not quantify the expected recall lift once the splitting hack and score-0 filter are also removed (both listed as separate levers).
[Why]: Overlap between levers makes the ranking and impact ordering ambiguous for planning.
[Fix]: Provide a short combined-impact estimate or reorder the list after the AKM-002 design decision.

F6
[Severity]: MINOR
[Finding]: Success criterion 4 states that creating a `#kb/`-tagged note "fires new-content retrieval via hook — zero behavioral steps," yet the CLAUDE.md signal-scan paragraph is only scheduled for later deletion in VO-037 (XD-028).
[Why]: Until that deletion occurs, operators still see a behavioral instruction, violating the "zero behavioral steps" claim.
[Fix]: Either move the deletion into this project's scope or qualify the criterion as "after VO-037 completes."

F7
[Severity]: STRENGTH
[Finding]: The explicit separation of Facts (F1–F9), Assumptions (A1–A6, each tied to a validation task), and Unknowns (U1–U5) is cleanly maintained throughout.
[Why]: This structure prevents hidden assumptions from reaching the PLAN phase and directly supports the "SPECIFY phase gate" intent.

F8
[Severity]: MINOR
[Finding]: Task table lists AKM-004 as depending on AKM-003, but the acceptance criteria for AKM-004 (new baseline + soak checklist) can be prepared in parallel once AKM-002 decisions are frozen.
[Why]: Minor scheduling inefficiency that could shorten the overall timeline.
[Fix]: Change dependency to "AKM-002" and note that implementation can begin after wrapper changes are merged.

---

# Synthesis

**Panel:** OpenAI gpt-5.4 (28 findings), Gemini 3.1 Pro (10), Grok 4.3 (8, calibration watch review 3 — audited per config before counting). DeepSeek failed (2× curl timeout at 120s). Overall verdict across the panel: proceed to PLAN after a targeted spec revision — no reviewer found a flaw in the intervention logic itself; the substantive findings all concern acceptance-criteria precision and missing contingencies.

## Consensus Findings

1. **SLO/fallback viability gap** (GEM-F1 CRITICAL, OAI-F8 SIGNIFICANT). Gemini's arithmetic: F8 implies ~0.81s of wrapper overhead (0.97s end-to-end − 0.16s BM25 call), so the AKM-001 fallback "CLI semantic at ~1.9s" is ~2.7s end-to-end — structurally over the 2s SLO. Verified against the spec: the arithmetic holds *as an upper bound* (caveat: the 0.81s includes the multi-call splitting hack that R2 deletes, so post-fix overhead will be lower — but unmeasured). The spec's fallback is optimistic and there is no decision rule for "no transport/mode meets both recall floor and SLO."
2. **A4/U3 hook-payload contingency missing** (GEM-F3, GRK-F4; GEM-F5 adjacent). AKM-005/007 — and Success Criteria 4/5 — are gated on an unvalidated payload-shape assumption with no stated fallback or descope path.
3. **Unverifiable-claim class** (OAI-F5/F6/F7 + UVC1–4, GEM-F4/F5/F6, GRK-F1). All three reviewers flagged that the decision-driving numbers, the qmd daemon capability, and file/line references cannot be verified from the artifact alone. For an internal spec these are locally verifiable (all derive from R1, produced 2026-07-07, same day); the actionable residue is provenance annotation, date-stamping brittle line references, and confirming `qmd mcp --http --daemon` flags locally in AKM-001 (already partially in the task).
4. **U5 (empty-brief tolerance) is an unknown but not a gate** (OAI-F10, GEM-F8). Empty briefs are foundational to the noise strategy; downstream compatibility must be a tested precondition in AKM-002, not a floating unknown.
5. **Acceptance criteria need an explicit all-of matrix** (OAI-F9, GRK-F3). SC1 is written as AND but the relationship between fixture recall@5, EVL within-domain, noise, and latency gates — and the semantic≡vector terminology across the two evaluation sets — should be a single pass/fail matrix.

## Unique Findings

- **GEM-F2 — recall@5 vs budget-3 mismatch.** Genuine insight, the sharpest catch of the round: the fixture counts rank-4/5 hits that the skill-activation budget of 3 will never surface, so the fixture can pass while the brief misses. Fix: measure recall@3 for skill-activation acceptance (or add a brief-level top-3 check alongside engine-level recall@5).
- **OAI-F11 — soak execution is required by SC7 but owned by no task.** Genuine: AKM-004 only *defines* the soak. Add AKM-010 (execute + close soak).
- **OAI-F12 — R3 minimal linkage model unspecified.** Genuine: "linkable to prior surfacing" needs at least event ID + note path + session context + timestamp window stated now, or the schema may be under-designed.
- **OAI-F13 — R4 trigger predicate semantics.** Genuine: tag-present vs tag-added, renames/moves, debounce, self-trigger exclusion should be normative inputs to AKM-007.
- **GRK-F6 — overlap window.** Genuine and unique: until VO-037 deletes the CLAUDE.md paragraph, both the hook and the behavioral instruction are live — SC4's "zero behavioral steps" needs an "after VO-037" qualifier and the window noted in XD-028 (double-surfacing possible during overlap).
- **OAI-F22 — "operator-flagged noise regression" unoperationalized.** Genuine: define the flag mechanism (run-log entry) and threshold now.
- **OAI-F23 — <50ms hook-overhead measurement basis undefined.** Genuine minor: specify end-to-end added latency, warm, p95, both eligible and non-eligible paths.
- Editorial minors, all accepted: OAI-F14 (workstream key for R2–R5), OAI-F15 ("full" metric undefined — it is qmd's hybrid+rerank bench mode), OAI-F16 (March miss-class parenthetical), OAI-F17 (rollback wording too optimistic), OAI-F18 (qualitative acceptance phrasing), GEM-F7 (AKM-009 should reference the AKM-002 *decision*, not AKM-003).

## Contradictions

- **Severity of the SLO/fallback gap:** Gemini rates it CRITICAL; OpenAI explicitly finds no CRITICAL (OAI-F24) while flagging the same issue as SIGNIFICANT (OAI-F8). Substantively the same finding — disagreement is calibration only. Flagged for the record; treated as must-fix either way.

## Action Items

**Must-fix (spec revision before PLAN):**
- **A1** [GEM-F1, OAI-F8] Add SLO viability decision rule: AKM-001 must profile *end-to-end* latency including post-fix wrapper overhead (not qmd-call time alone); define p95 basis (warm, cold-start excluded); if no transport/mode meets both the recall floor and the SLO, halt at a design exception for operator decision instead of proceeding to AKM-003.
- **A2** [OAI-F9, GRK-F3, GEM-F2] Replace SC1 with an explicit all-of acceptance matrix; adopt recall@3 (or dual-level: engine recall@5 + brief-level top-3) for skill-activation; add the semantic≡vector terminology note.

**Should-fix (same revision pass, all cheap):**
- **A3** [GEM-F3, GRK-F4] A4/U3 contingency: if PostToolUse payloads lack usable path data, R3/R4 descope cleanly (SC4/5 removed or re-scoped) — state this in AKM-005/007.
- **A4** [OAI-F10, GEM-F8] Elevate U5 to a tested precondition in AKM-002 acceptance.
- **A5** [OAI-F11] Add AKM-010 — execute and close the soak; SC7 maps to it.
- **A6** [OAI-F12] State the minimal R3 linkage model (event ID + path + session + timestamp window).
- **A7** [OAI-F13, GRK-F6] Add normative R4 trigger semantics (tag-present-on-save, path debounce, self-trigger exclusion); qualify SC4 with the VO-037 overlap window and note it in XD-028.
- **A8** [OAI-F22, OAI-F23] Operationalize the soak noise flag (run-log convention + threshold) and the <50ms measurement basis.
- **A9** [OAI-F5/F6/F7, GEM-F4/F5/F6, GRK-F1 + editorial minors] Provenance pass: date-stamp line references ("as of 2026-07-07"), keep function names primary; confirm qmd daemon flags in AKM-001 acceptance; workstream key; define "full"; March miss-class parenthetical; rollback rephrase; AKM-009 → AKM-002 wording; tighten qualitative acceptance phrases.

**Defer:**
- **A10** [dispatch] DeepSeek curl_timeout: bump per-reviewer timeout (e.g., 240s) in peer-review-config.md if the panel wants deepseek-v4-pro back for large artifacts — operator call, config edit.

## Considered and Declined

- **GRK-F2** (CRITICAL: C5 internally inconsistent with F4) — `incorrect`: the Herodotus case supports both claims — KB-only scope correctly excluded the project-doc answer, and the splitting hack manufactured noise downstream of that filter; no contradiction. The kernel (spec under-explains the case) is absorbed into A9 as a one-line clarification.
- **GRK-F5** (quantify combined lever impact) — `overkill`: levers are a qualitative prioritization aid at SPECIFY; combined-impact estimates would be speculation ahead of AKM-001/002 data.
- **GRK-F8** (AKM-004 depends on AKM-002 not AKM-003) — `incorrect`: the re-baseline half of AKM-004 requires implemented wrapper changes; drafting the soak checklist early is trivial and not worth a dependency edit.
- **OAI-F5 fix-as-stated** (verification appendix quoting source sections for every metric) — `overkill` in full form: all metrics trace to one same-day evaluation doc already cited in §Evidence Base; A9's provenance pass covers the intent without duplicating R1 into the spec.

## Grok calibration watch — review 3 tally

8 findings — 0 fabrications, 1 incorrect-but-explicable (GRK-F2: severity-inflated CRITICAL from a genuinely under-explained passage), 1 noise (GRK-F8), 1 partially-confused with a real kernel (GRK-F3 terminology ambiguity). Landed: GRK-F4 (consensus), GRK-F6 (unique, genuinely useful), GRK-F1 (consensus UVC). Fast/short again (16.5s, 962 completion tokens). Pattern stable across 3 reviews: zero fabrication, ~1 misread + ~1 noise per round, thin but real unique value at lowest cost. **Watch closed — verdict: keep in default_reviewers.** Tally recorded in peer-review-config.md.
