---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: _plans/giggly-sauteeing-nova.md
artifact_type: spec
artifact_hash: 02e8c6b3
prompt_hash: 48f5e19e
base_ref: null
project: tess-v2
domain: software
skill_origin: peer-review
created: 2026-04-12
updated: 2026-04-12
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
    - "Soft: /Users/tess/ file paths on lines 74-76 (local file references, expected)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 71658
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-12-paperclip-spike-plan-openai.json
  google:
    http_status: 200
    latency_ms: 52933
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-12-paperclip-spike-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 62060
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-12-paperclip-spike-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 21112
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-12-paperclip-spike-plan-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: TV2-045 Paperclip Integration Spike Plan

**Artifact:** TV2-045 Paperclip Integration Spike plan
**Mode:** full
**Reviewed:** 2026-04-12
**Reviewers:** OpenAI GPT-5.4, Google Gemini 3.1 Pro Preview, DeepSeek Reasoner (V3.2), Grok 4.1 Fast Reasoning
**Review prompt:** Structured review of research spike plan evaluating Paperclip as coordination layer for tess-v2. Focus areas: staged approach design, HTTP adapter probe validity, evaluation criteria completeness, time budget realism, and defer-outcome efficiency.

---

## OpenAI (gpt-5.4)

Below is a structured review of the spike plan.

## Overall assessment

This is a **well-structured, decision-oriented spike plan** with a strong bias toward learning quickly and bailing out early if the integration looks unstable or low-value. It is internally coherent with the stated goal: produce a recommendation among **adopt / build thin sub-orchestrator / defer**. The staged approach is mostly sound, especially the explicit checkpoints and the focus on testing a real contract instead of staying purely theoretical.

That said, there are several **significant gaps**:

- The current plan does **not fully test the most important integration boundary**: whether Paperclip can coordinate tess-v2 **without becoming a conflicting scheduler/dispatcher**.
- The **HTTP adapter probe may be too narrow** if the purpose is to evaluate Paperclip as a coordination layer rather than just as a task ingress.
- The plan’s **time budget is optimistic**, especially if any schema churn or setup friction occurs.
- The evaluation criteria are good but **incomplete**; there should be explicit criteria for **state ownership / source-of-truth**, **failure recovery semantics**, and **operational burden**.
- The decision path for **“build thin sub-orchestrator”** is underdeveloped compared with adopt/defer.

I would rate the plan as **promising but needing refinement before execution**.

---

## Findings

- [F1]
  - [Severity]: STRENGTH
  - [Finding]: The plan has a clear decision objective and avoids open-ended exploration.
  - [Why]: Research spikes often drift into tool tourism. This plan stays anchored on a concrete decision document and three explicit outcomes: adopt, build thin sub-orchestrator, or defer.
  - [Fix]: None.

- [F2]
  - [Severity]: STRENGTH
  - [Finding]: The staged approach with bail-out checkpoints is well-designed overall.
  - [Why]: Given that a prior memo already leaned toward defer, the checkpoints help ensure the spike remains time-efficient and prevent over-investing if install friction, schema churn, or ownership conflicts appear early.
  - [Fix]: Keep the checkpoints, but tighten the pass/fail conditions for each stage.

- [F3]
  - [Severity]: SIGNIFICANT
  - [Finding]: Stage 2 is doing too much work conceptually while still not testing the most important architectural question.
  - [Why]: It claims to test all four criteria through a single minimal adapter and one simple contract, but that setup mostly validates “can Paperclip hand off a task over HTTP?” It does **not sufficiently test whether Paperclip can act as a safe coordination layer alongside Ralph, dispatch claims, LaunchAgents, and staging/promotion without conflicting authority.**
  - [Fix]: Split Stage 2 into:
    1. **Adapter contract probe** — verify request/response, result mapping, dashboard visibility.
    2. **Authority/scheduler probe** — explicitly test ownership boundaries: who schedules, who retries, who claims work, who marks completion, who owns status truth.

- [F4]
  - [Severity]: SIGNIFICANT
  - [Finding]: The HTTP adapter probe is a reasonable first integration test, but it is not sufficient as the primary test for coordinator fit.
  - [Why]: HTTP proves connectivity and API shape, but the central decision is not “can Paperclip call tess-v2?” It is “should Paperclip become a coordination layer?” The risk is concluding too much from a thin ingress adapter that bypasses the hard parts.
  - [Fix]: Keep the HTTP adapter as the first probe, but add one of these immediately after:
    - A **scheduler ownership test** where Paperclip triggers work while LaunchAgent remains active, to observe dual-scheduler hazards.
    - A **queue/claim semantics test** where Paperclip dispatches multiple tasks and tess-v2’s claims system remains the source of execution truth.
    - A **status reconciliation test** comparing Paperclip dashboard state vs. `tess history` / internal run state.

- [F5]
  - [Severity]: SIGNIFICANT
  - [Finding]: The four evaluation criteria are relevant but incomplete.
  - [Why]: The selected criteria cover important surfaces, especially vault authority and dashboard visibility. However, missing criteria include:
    - **State ownership / source of truth**
    - **Retry/failure semantics compatibility**
    - **Approval/budget semantics overlap**
    - **Operational complexity / maintenance burden**
    - **Multi-task concurrency and claims interaction**
  - [Fix]: Add at least three explicit criteria:
    1. **State ownership:** Which system is authoritative for task lifecycle, retries, and completion?
    2. **Failure semantics:** Do Paperclip task states preserve Ralph failure classification and amendment behavior?
    3. **Operational burden:** What new processes, runtime dependencies, and upgrade tracking are introduced?

- [F6]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan under-specifies how “contract verification” should be evaluated.
  - [Why]: “Does Paperclip’s task checkout conflict with contract immutability?” is directionally right, but vague. Contract verification in tess-v2 likely includes more than immutability: executor selection, input constraints, amendment rules, promotion preconditions, and result lineage.
  - [Fix]: Define explicit checks, e.g.:
    - Contract payload remains unchanged after checkout translation
    - Executor selection remains contract-derived, not adapter-derived
    - Ralph failure classification persists unchanged
    - Promotion only occurs through existing tess-v2 mechanisms
    - Amendment Z queue/claims semantics are unaffected

- [F7]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan does not adequately test the “thin sub-orchestrator” recommendation path.
  - [Why]: The decision options include “build thin sub-orchestrator,” but the spike mostly evaluates Paperclip as-is versus defer. There is little planned evidence gathering for identifying which Paperclip ideas are worth reproducing natively.
  - [Fix]: In Stage 3 or the decision doc, include a required section:
    - “Which Paperclip capabilities are valuable enough to copy locally?”
    - Examples: hierarchy visualization, dashboarding, approval gates, budget envelopes, adapter heartbeat patterns.

- [F8]
  - [Severity]: STRENGTH
  - [Finding]: Testing with `heartbeat-health-ping` is a sensible low-risk first contract.
  - [Why]: It minimizes variables and isolates orchestration concerns from LLM/tooling complexity. For an initial probe, that is appropriate.
  - [Fix]: None, but pair it with one additional nontrivial contract if time permits.

- [F9]
  - [Severity]: SIGNIFICANT
  - [Finding]: A single simple shell contract is likely insufficient to evaluate the hierarchy and coordination claims Paperclip is supposed to add.
  - [Why]: Paperclip’s value proposition includes hierarchical delegation, approval gates, role-based structure, and ongoing heartbeat-managed operations. A trivial heartbeat contract may only prove transport and dashboard rendering, not meaningful orchestration fit.
  - [Fix]: Add one follow-up probe using a **claude-code or multi-step contract** that exercises:
    - retry classification,
    - richer status progression,
    - approval/budget interactions if possible.

- [F10]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan does not explicitly address dual-scheduler risk strongly enough.
  - [Why]: The text asks whether Paperclip’s heartbeat interval can match LaunchAgent cadences, but the deeper issue is not cadence matching. It is whether introducing Paperclip creates **two independent systems deciding when work should run**, which can cause duplicate execution, stale state, race conditions, and incoherent monitoring.
  - [Fix]: Reframe criterion (c) as:
    - “Can Paperclip operate strictly as observer/dispatcher without becoming a conflicting scheduler?”
    - Test three modes explicitly:
      1. LaunchAgent-only scheduling + Paperclip visibility
      2. Paperclip-driven scheduling + LaunchAgent disabled
      3. Both enabled, to confirm this is invalid and document why

- [F11]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan’s success criteria are too output-based and not decision-quality-based.
  - [Why]: “Dashboard running,” “one contract executed,” and “decision doc exists” are completion checks, but they do not ensure the spike actually resolved the architectural question well enough.
  - [Fix]: Add decision-quality verification such as:
    - A documented source-of-truth map for each lifecycle state
    - A documented scheduler ownership decision
    - A recommendation justified against all three outcome options, not just adopt/defer

- [F12]
  - [Severity]: SIGNIFICANT
  - [Finding]: The time budget of ~3 hours is likely unrealistic for the described scope.
  - [Why]: Installing and understanding a new Node/TypeScript framework, auditing adapter schemas, defining hierarchy, standing up dashboard, writing a Python HTTP adapter, integrating `run_ralph_loop()`, executing a contract, analyzing four criteria, and writing a decision document is more likely **4.5–7 hours** unless the environment is already warm and the framework is very stable.
  - [Fix]: Either:
    - expand the budget to a half day or full day, or
    - narrow the scope to “install + schema audit + dashboard + adapter stub + one execution path,” with the decision doc allowed to recommend defer based on partial evidence.

- [F13]
  - [Severity]: STRENGTH
  - [Finding]: The plan explicitly acknowledges the possibility that the right outcome is still “defer.”
  - [Why]: This is excellent spike hygiene. It reduces sunk-cost bias and keeps the work aligned with the prior memo’s recommendation.
  - [Fix]: None.

- [F14]
  - [Severity]: STRENGTH
  - [Finding]: The plan is mostly internally consistent with the stated architecture of tess-v2.
  - [Why]: It correctly identifies the likely conflict surfaces: Ralph loop, dispatch queue, staging/promotion, and scheduling.
  - [Fix]: None.

- [F15]
  - [Severity]: SIGNIFICANT
  - [Finding]: Stage ordering could be improved slightly.
  - [Why]: Stage 1 “Toy Hierarchy Setup” before fully understanding adapter/event/state interfaces may lead to effort on presentation before proving integration feasibility. Since the dashboard/hierarchy value is secondary to authority compatibility, the order is somewhat suboptimal.
  - [Fix]: Consider:
    - Stage 0: install + schema/interface audit
    - Stage 1: minimal dashboard/hierarchy only if it is near-zero effort
    - Stage 2A: adapter contract probe
    - Stage 2B: ownership/scheduler probe
    - Stage 3: cost/benefit + thin-sub-orchestrator extraction
    In practice, Stage 1 and part of Stage 2 could be combined.

- [F16]
  - [Severity]: MINOR
  - [Finding]: The phrase “adapter interface is unrecognizable from 6 days ago” is too subjective for a bail criterion.
  - [Why]: Subjective checkpoints can create inconsistent decisions under time pressure.
  - [Fix]: Replace with measurable criteria, e.g.:
    - install broken on current platform,
    - HTTP adapter docs/schema materially changed from memo assumptions,
    - cannot identify required request/response fields within 15 minutes.

- [F17]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan does not specify how Paperclip budget enforcement and approval gates intersect with tess-v2’s existing budget enforcement.
  - [Why]: This is a likely overlap/conflict area, and one of the few claimed Paperclip advantages. If both systems can gate or deny work, authority ambiguity follows.
  - [Fix]: Add an explicit evaluation item:
    - “Can Paperclip budget/approval be layered as advisory only, or does it duplicate/conflict with tess budget enforcement?”
    - Decide whether one system must remain authoritative.

- [F18]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan’s dashboard visibility criterion is underspecified on what “useful operational data” means.
  - [Why]: Without concrete expectations, the dashboard could appear impressive but provide little additive value over existing CLI/history/session reports.
  - [Fix]: Define required observability fields such as:
    - task/contract ID mapping,
    - start/end time,
    - current state,
    - failure class,
    - retry count,
    - executor used,
    - links or pointers to logs/artifacts,
    - human-readable hierarchy context.

- [F19]
  - [Severity]: MINOR
  - [Finding]: “Stand up in local Paperclip instance” lacks reproducibility detail.
  - [Why]: For a spike that may support a decision memo, a minimal reproducible setup matters.
  - [Fix]: Note environment assumptions:
    - Node version,
    - package manager,
    - whether this is run via `npx` only or cloned source,
    - local ports used by dashboard and adapter.

- [F20]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan should explicitly define what counts as an “irreconcilable state ownership conflict.”
  - [Why]: This is the most important bail condition, but it is left implicit.
  - [Fix]: Add examples:
    - both systems independently retry the same work,
    - Paperclip requires mutating contract state that tess treats as immutable,
    - Paperclip task completion semantics do not map to Ralph outcomes,
    - dashboard status diverges from tess authoritative run state with no clean reconciliation path.

- [F21]
  - [Severity]: STRENGTH
  - [Finding]: The critical files list is focused and points to the right integration surfaces.
  - [Why]: It will help keep the spike grounded in actual code paths rather than abstract design speculation.
  - [Fix]: None.

- [F22]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan may overcommit to calling `run_ralph_loop()` directly without first deciding whether the adapter should invoke a higher-level stable boundary.
  - [Why]: Directly calling the loop function may couple the spike to an internal implementation detail rather than the true integration seam. If `runner.py` is the intended integration surface, bypassing it could produce misleading compatibility results.
  - [Fix]: Clarify the adapter call boundary:
    - Prefer the most stable public/internal orchestration entrypoint actually used by tess-v2 runs.
    - If `run_ralph_loop()` is intentionally chosen, explain why it is the correct seam.

- [F23]
  - [Severity]: MINOR
  - [Finding]: The plan would benefit from a concise test matrix.
  - [Why]: Right now the criteria are scattered through stages. A matrix would make execution and later review easier.
  - [Fix]: Add a small table with rows = criteria and columns = test method / expected pass condition / observed result.

- [F24]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan is good on time-efficiency for a possible “defer” outcome, but only if the spike is narrowed aggressively after first evidence.
  - [Why]: As written, there is some risk of continuing through setup and adapter coding even after enough evidence exists to reaffirm defer. That would undermine the stated purpose of running a lightweight hands-on validation.
  - [Fix]: Add an explicit rule:
    - If Stage 0 + Stage 2A already show high overlap, weak dashboard advantage, or scheduler conflict, stop and write defer.
    - Only continue into deeper setup if there is credible upside beyond dashboard novelty.

---

## Additional focus-area review

### 1. Staged approach and bail-out checkpoints

**Verdict:** Good foundation, but Stage 1 and Stage 2 should be slightly reorganized.

What works:
- Early install/schema audit is correct.
- Bail-out on volatility is sensible.
- Decision document is appropriately last.

What to change:
- Move from “toy hierarchy” to “minimal viability of authority boundary” earlier.
- Combine Stage 1 with dashboard verification only if setup is trivial.
- Split Stage 2 into:
  - **2A: Transport/interface probe**
  - **2B: Ownership/scheduler/retry semantics probe**

Suggested order:
1. Install + interface audit
2. Minimal dashboard proof
3. Adapter stub + one task roundtrip
4. Ownership/scheduler conflict test
5. Cost/benefit and thin-sub-orchestrator extraction
6. Decision doc

### 2. Is the HTTP adapter probe the right integration test?

**Answer:** Yes as a first probe, no as the main proof.

Why it is right:
- Lowest-friction path
- Uses Paperclip the way prior memo suggested
- Helps validate dashboard, task dispatch shape, and adapter compatibility

Why it is insufficient alone:
- It mostly tests “can Paperclip hand off work?”
- It does not prove whether Paperclip should become the coordinator
- It may bypass the hardest problem: source-of-truth and scheduler authority conflicts

Best adjustment:
- Keep HTTP adapter probe
- Add one explicit **authority boundary test** immediately after

### 3. Are the four evaluation criteria right? What is missing?

**The chosen four are good but not complete.**

Good:
- Vault authority
- Contract verification
- Heartbeat scheduling
- Dashboard visibility

Missing:
- **State ownership / source of truth**
- **Failure/retry semantics compatibility**
- **Budget/approval overlap**
- **Operational/maintenance burden**
- **Concurrency / claims interaction**

If only one missing item can be added, add:
- **Source-of-truth ownership**

### 4. Is the time budget realistic?

**No, not as written.** It is optimistic.

Likely realistic ranges:
- Best case, warm environment: **3.5–4.5 hours**
- Typical case: **5–7 hours**
- If install/docs/schema churn appears: longer

How to make 3 hours plausible:
- Don’t write a full adapter; stub the minimal endpoint
- Don’t do a deep hierarchy setup
- Limit to one real execution plus one ownership analysis
- Allow the decision doc to be brief and evidence-first

### 5. Does the plan adequately account for a likely “defer” outcome?

**Mostly yes, but it should be even more ruthless.**

Strengths:
- Prior memo is acknowledged
- Bail-out checkpoints exist
- The purpose is framed as producing evidence, not proving adoption

Risk:
- The plan could still spend too much time building adapter glue before re-confirming defer

Improvement:
- Add an explicit “stop if the only additive value is dashboard visibility” rule
- Add a threshold like:
  - If no unique operational leverage appears by end of Stage 2A, recommend defer or thin native dashboard work instead

---

## Unverifiable claims

The artifact includes several factual claims I cannot independently verify from the text alone.

- [F25]
  - [Severity]: SIGNIFICANT
  - [Finding]: UNVERIFIABLE CLAIM: “Compare current release version to Apr 6 memo's `v2026.403.0` — assess schema churn.”
  - [Why]: The specific version reference may be correct, but it is not independently verifiable from the artifact alone.
  - [Fix]: Cite the release source explicitly in the plan or decision doc, e.g. repository release page or commit/tag link.

- [F26]
  - [Severity]: SIGNIFICANT
  - [Finding]: UNVERIFIABLE CLAIM: “weekly calver releases, bus-factor-1, adapter tracking burden.”
  - [Why]: These are factual assertions about release cadence and project maintainership that require external evidence.
  - [Fix]: Add references in Stage 3: release history snapshot, maintainer count/commit activity, issue response pattern.

- [F27]
  - [Severity]: SIGNIFICANT
  - [Finding]: UNVERIFIABLE CLAIM: The command `npx paperclipai onboard --yes` is assumed to be the correct installation/onboarding path.
  - [Why]: This may be valid, but the plan presents it as executable fact without an attributed source.
  - [Fix]: Add the source URL or repo instruction reference.

---

## Bottom line

**Recommendation on the plan itself:** proceed, but revise before execution.

### Most important fixes
1. Add an explicit **source-of-truth / ownership** criterion.
2. Split Stage 2 into **transport** and **authority** probes.
3. Reframe heartbeat scheduling around **dual-scheduler risk**, not cadence matching.
4. Clarify how to evaluate **budget/approval overlap**.
5. Increase the time budget or narrow the scope.
6. Make the “thin sub-orchestrator” path an explicit analysis target, not just a fallback label.

If you want, I can also convert this into:
- a **redlined revision of the spike plan**, or
- a **shortened reviewer summary** suitable for dropping into the project notes.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of the TV2-045 research spike plan. 

### Focus Areas Summary
1. **Staged approach:** The staged structure is excellent for minimizing sunk cost, but Stage 1's "bail-out" is functionally a continuation, which defeats its purpose.
2. **HTTP adapter probe:** This is the wrong integration test. It forces a paradigm mismatch by requiring a pull-based CLI tool (tess-v2) to act as a listening HTTP server. 
3. **Evaluation criteria:** The 4 criteria correctly target the highest-risk architectural collisions (state, authority, scheduling). However, the plan misses evaluating the overlap between Paperclip's adapters and tess-v2's executors.
4. **Time budget:** The budget is unrealistic. Building a custom Python HTTP adapter, mapping schemas, and running tests will take significantly longer than 1 hour.
5. **Defer risk:** The plan handles the likely "defer" outcome exceptionally well through its early bail-out checkpoints, ensuring minimal wasted effort.

---

### Structured Findings

- [F1]
- [Severity]: CRITICAL
- [Finding]: Paradigm mismatch in Stage 2 (HTTP Adapter Probe).
- [Why]: The plan states the Python adapter will "Accept Paperclip task checkout POST". Because tess-v2 is currently driven by macOS LaunchAgents (an ephemeral, pull-based/cron-like execution model), accepting an HTTP POST requires spinning up a long-running web server (e.g., Flask/FastAPI). This fundamentally alters tess-v2's architecture just to run the spike, muddying the evaluation of "Heartbeat scheduling" (Criterion C) by mixing a daemonized server model with a cron-based CLI model. 
- [Fix]: Change Stage 2 to use Paperclip's existing **Bash adapter** (mentioned in the context) to execute tess-v2's existing CLI entry points (like `dispatch.sh` or a simple Python script). This tests Paperclip's ability to orchestrate tess-v2 in its *actual* current form, without requiring an HTTP server wrapper.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: Stage 1 "Bail checkpoint" does not actually authorize bailing.
- [Why]: The checkpoint states: "If role schema requires heavy workarounds... note friction, continue." A bail checkpoint that mandates continuation is just a logging step. If the fundamental hierarchical role modeling (Paperclip's primary value proposition) is incompatible with tess-v2's contract structure, proceeding to spend 1+ hours building an adapter is wasted effort.
- [Fix]: Change the Stage 1 bail checkpoint to: "If role schema cannot logically map to tess-v2 contracts without breaking the single-assignee model -> skip to decision doc with 'defer (incompatible execution models)'."

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: Missing evaluation criterion regarding Executor/Adapter overlap.
- [Why]: The context notes tess-v2 has 3 executors (shell, local-LLM, claude-code) and Paperclip has overlapping adapters (Claude Code, Bash). The evaluation criteria (vault authority, contract verification, heartbeat scheduling, dashboard visibility) do not address who owns the LLM execution or how Paperclip's built-in adapters interact with tess-v2's native executors. 
- [Fix]: Add a 5th evaluation criterion to Stage 2: "(e) Execution Ownership: Does Paperclip duplicate tess-v2's LLM executors, and can Paperclip's orchestration treat tess-v2's LLM outputs as native activity logs?"

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Unrealistic time budget for Stage 2 (~1 hour).
- [Why]: Writing a custom HTTP adapter from scratch that integrates with `ralph.py`, translates schemas, handles errors, and correctly reports back in Paperclip's activity log format is complex. Testing this against the 4 criteria and debugging inevitable integration issues will almost certainly exceed 60 minutes.
- [Fix]: Either increase the Stage 2 time budget to ~2-2.5 hours (raising the total spike budget to ~4.5 hours), or adopt the fix from [F1] (using the existing Bash adapter) which requires significantly less custom code.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Paperclip CLI command `npx paperclipai onboard --yes` and Paperclip release version `v2026.403.0`.
- [Why]: I cannot independently verify that this NPM package exists, that this specific CLI command is valid, or that a future-dated calver version (`v2026.403.0`) is accurate to the referenced April 6 memo. If the package or CLI command has changed (or if this is a typo), Stage 0 will fail immediately.
- [Fix]: Verify the NPM package name and exact CLI syntax in the Paperclip documentation prior to starting the timer for Stage 0. Ensure the target version matches what is available in the registry.

- [F6]
- [Severity]: STRENGTH
- [Finding]: Excellent sunk-cost mitigation architecture.
- [Why]: Given the desk analysis already recommended deferring, the risk of wasting time on a "doomed" spike is high. By explicitly structuring the spike with sequential bail-out checkpoints (Stage 0: 30m, Stage 1: 30m), the plan aggressively protects the developer's time while still gathering the hard evidence required for the decision doc.

- [F7]
- [Severity]: STRENGTH
- [Finding]: Strong, highly-targeted core evaluation criteria.
- [Why]: Criteria A (Vault authority) and B (Contract verification) perfectly target the "abstraction collisions" that occur when stacking two orchestrators. Identifying that Paperclip might accidentally bypass tess-v2's staging/promotion engine or Ralph failure loop shows a deep understanding of the systemic risks of this integration.

---

## DeepSeek (deepseek-reasoner)

**Structured Review of TV2-045: Paperclip Integration Spike Plan**

**Overall Assessment:** The plan is well-structured, clear, and demonstrates a pragmatic, risk-aware approach. It correctly focuses on integration feasibility and state ownership conflicts. The staged design with bail-out checkpoints is a significant strength, maximizing learning while minimizing sunk cost. Some gaps exist in the technical scope and verification of key assumptions.

**Findings:**

- **[F1]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: UNVERIFIABLE CLAIM: The plan references Paperclip version `v2026.403.0` from an "Apr 6 memo" as a baseline for assessing "schema churn." The existence of this specific version and the contents of the prior memo cannot be independently verified.**
- **[Why]: The entire Stage 0 "Schema Audit" relies on this comparison to decide if the framework is "too volatile." Without the memo, a reviewer cannot assess the validity of this checkpoint. The version number itself (2026.403.0) appears to be a future calver date, raising questions about its accuracy.**
- **[Fix]: The plan should include a brief summary of the key schema elements noted in the Apr 6 memo, or explicitly state that this check will rely on the user's personal notes from that date.**

- **[F2]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: The "Toy Hierarchy Setup" (Stage 1) incompletely maps tess-v2's executor landscape. The plan defines a "Research Service" for claude-code contracts but only a "Heartbeat Service" for shell executor contracts, omitting explicit consideration for the third executor type (nemotron/local-LLM).**
- **[Why]: This creates a gap in evaluating how Paperclip's role model would handle all existing task types. The nemotron/local-LLM executor may have different state or configuration requirements that could cause integration friction not discovered in this spike.**
- **[Fix]: In Stage 1, explicitly note whether the "Heartbeat Service" role is intended to cover all non-claude-code executors (shell and nemotron), or add a fourth role. The evaluation in Stage 2 should then test a contract using the nemotron executor via the HTTP adapter.**

- **[F3]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: The core integration probe (Stage 2) uses an HTTP adapter, which is a suboptimal and potentially misleading integration path. Paperclip's adapters are intended for direct integration, not as proxies to another orchestration system.**
- **[Why]: Testing via HTTP adds a layer of indirection and complexity (writing a custom Python HTTP server) that may obscure fundamental architectural mismatches. The friction found may be specific to the HTTP glue code, not inherent to Paperclip's core model. It tests Paperclip's *adapter* feature, not its suitability as a *coordination layer replacement*.**
- **[Fix]: The spike should primarily investigate direct integration possibilities (e.g., could `runner.py` be wrapped as a Paperclip "Bash adapter" script?). The HTTP adapter test can remain as a fallback "worst-case" scenario, but the analysis must clearly distinguish between adapter limitations and core framework incompatibilities.**

- **[F4]**
- **[Severity]: MINOR**
- **[Finding]: The time budget (~3 hours) is optimistic, particularly for Stage 2 (HTTP Adapter Probe).**
- **[Why]: Writing, debugging, and testing a "minimal Python HTTP adapter" that correctly interfaces with two systems (`paperclipai` and `tess-v2`'s internal `run_ralph_loop()`), then comprehensively evaluating four criteria, is likely to exceed one hour. Rushing this stage risks superficial analysis.**
- **[Fix]: Buffer the time estimate for Stage 2 to 1.5-2 hours, or explicitly scope the adapter to a single, hardcoded contract execution to maintain the timebox.**

- **[F5]**
- **[Severity]: MINOR**
- **[Finding]: The evaluation criterion labeled "(b) Contract verification" is ambiguously defined. The description ("conflict with contract immutability") points to a potential state ownership issue, but "verification" more commonly implies validating signatures, syntax, or permissions before execution.**
- **[Why]: This could lead to an incomplete evaluation. The plan should clarify if it's only checking for mutability conflicts, or also checking if Paperclip's task dispatch mechanism can perform tess-v2's pre-execution validation steps.**
- **[Fix]: Rename the criterion to "Contract State & Integrity" or clarify in the Stage 2 details that "verification" here specifically means ensuring the contract artifact passed to Ralph remains immutable and that Ralph's own verification logic is not bypassed.**

- **[F6]**
- **[Severity]: STRENGTH**
- **[Finding]: The staged approach with explicit bail-out checkpoints is excellently designed for efficient learning and risk mitigation.**
- **[Why]: It allows for rapid failure and clear decision-making. Stage 0 checks for deal-breaking volatility. Stage 1 checks for fundamental modeling mismatch. Stage 2 is the core integration test. This structure ensures the spike can conclude with a defensible "defer" recommendation after minimal investment if major red flags appear early.**

- **[F7]**
- **[Severity]: STRENGTH**
- **[Finding]: The four evaluation criteria (vault authority, contract verification, heartbeat scheduling, dashboard visibility) are well-chosen and directly address the core tension: whether Paperclip adds value without breaking tess-v2's existing, robust mechanisms.**
- **[Why]: They focus on state ownership (vault, contract), operational control (scheduling), and visibility gains (dashboard)—the key architectural concerns when layering a new coordination system. They effectively test for "abstraction collisions."**

- **[F8]**
- **[Severity]: STRENGTH**
- **[Finding]: The plan adequately accounts for the risk of a "defer" outcome. The time-bound, checkpoint-driven approach is designed to extract maximum evidence with minimum time sunk.**
- **[Why]: Even if deferred, the outputs (interface mapping, compatibility report, collision inventory) provide valuable documentation of the current integration boundary and clarify the "conditions for revisiting." This makes the effort worthwhile as a learning and documentation exercise, not wasted effort.**

**Answers to Additional Focus Areas:**

1.  **Staged Approach:** The staged approach is very well-designed. The order is logical: inspect the tool, model your system with it, then test integration. The bail-out checkpoints are placed correctly. No reordering needed.
2.  **HTTP Adapter Probe:** As noted in F3, the HTTP adapter is **not** the right primary integration test. It should be a secondary option. The primary investigation should be whether tess-v2's core dispatch logic can be *replaced by* or *hosted within* a Paperclip adapter (e.g., Bash). The HTTP approach tests a hybrid architecture that adds complexity.
3.  **Evaluation Criteria:** The four criteria are correct and comprehensive for the stated goal. A potential addition could be **"Agent Budget & Approval Gate Alignment"** to explicitly test if Paperclip's budget/approval model can replicate or cleanly interface with tess-v2's existing "budget enforcement."
4.  **Time Budget:** As noted in F4, it is optimistic but potentially feasible if the scope is rigidly controlled. The 3-hour total is a tight timebox that demands strict focus.
5.  **Risk of "Defer" Outcome:** Yes, the plan is highly time-efficient. The early checkpoints (Stage 0 & 1) could lead to a justified deferral within the first hour. The structured outputs ensure tangible value is created regardless of the final recommendation.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: Paperclip installation command `npx paperclipai onboard --yes` and directory structure `packages/adapters/` (especially HTTP adapter details like task checkout shape, heartbeat contract, activity log schema).  
  [Why]: Review cannot assess correctness or feasibility without independent verification; if command or paths are incorrect, Stage 0 fails immediately, undermining the entire plan.  
  [Fix]: Add links to Paperclip GitHub/docs or note "verify command from official repo first."

- [F2]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: Paperclip release version `v2026.403.0` referenced from Apr 6 memo, with schema churn assessment over "6 days."  
  [Why]: Future-dated (2026) versioning and memo raise doubts on plan currency; if inaccurate, volatility bail checkpoint is meaningless.  
  [Fix]: Replace with current verifiable version (e.g., `npm show paperclipai version`) or cite repo commit hash.

- [F3]  
  [Severity]: CRITICAL  
  [Finding]: Stage 2 requires writing a "minimal Python HTTP adapter" that handles POST task checkout, translates to `run_ralph_loop()`, and returns activity log format — but no specs provided for Paperclip's exact JSON schemas (e.g., task fields, heartbeat payload).  
  [Why]: Without schemas (only "inspect" in Stage 0), adapter dev is guesswork, likely exceeding 1h budget and risking incorrect integration tests for all 4 criteria.  
  [Fix]: In Stage 0, mandate extracting/copying exact JSON examples from adapter code into the interface mapping table.

- [F4]  
  [Severity]: SIGNIFICANT  
  [Finding]: Time budget (~3h total) is unrealistic, especially Stage 2 (~1h for HTTP adapter coding, testing one contract, evaluating 4 criteria + collisions).  
  [Why]: Novel integration (TS orchestrator → Python runner) involves debugging schema mismatches, HTTP server setup (e.g., Flask/FastAPI), tess-v2 invocation, and criterion checks; overruns make spike inefficient even for "defer."  
  [Fix]: Double Stage 2 to ~2h; add contingency: "If adapter >45min, bail after toy POST simulation without full execution."

- [F5]  
  [Severity]: SIGNIFICANT  
  [Finding]: Only tests `heartbeat-health-ping` (simplest shell V1); ignores LLM executors (nemotron/claude-code) despite Stage 1 defining "Research Service" for V2/V3.  
  [Why]: Criteria like contract verification/heartbeat may differ for complex executors; single test incomplete for "multi-agent" evaluation, risks false positives on adopt.  
  [Fix]: Add quick Stage 2.5 (~15min): Probe one claude-code contract if shell passes, or note as out-of-scope risk.

- [F6]  
  [Severity]: SIGNIFICANT  
  [Finding]: Evaluation criteria miss key risks: (1) Error propagation (does Paperclip retry logic conflict with Ralph's?), (2) Security (HTTP exposure of vault/staging?), (3) Performance (Node.js overhead on dispatch queue?).  
  [Why]: Focus areas ask if 4 criteria are "right/missing anything"; gaps could lead to adopt recommendation overlooking tess-v2 stability, contradicting prior "defer" rationale.  
  [Fix]: Expand Stage 2 eval to 6 criteria, adding error/security/perf as bullet checks.

- [F7]  
  [Severity]: MINOR  
  [Finding]: Stage 1 bail checkpoint says "note friction, continue" even for "heavy workarounds," weakening early exit.  
  [Why]: Reduces efficiency for "defer" outcome; friction in roles likely foreshadows Stage 2 collisions.  
  [Fix]: Change to "if >15min workarounds → bail to decision with 'build own' lean."

- [F8]  
  [Severity]: MINOR  
  [Finding]: Specific file paths (e.g., `/Users/tess/crumb-apps/tess-v2/src/tess/ralph.py`) and prior memos (e.g., `paperclip-relevance-check-2026-04-06.md`) are user-specific/unverifiable.  
  [Why]: Reduces portability/clarity for review or team handoff.  
  [Fix]: Use relative paths or project-root references (e.g., `tess-v2/src/tess/ralph.py`).

- [F9]  
  [Severity]: STRENGTH  
  [Finding]: Staged approach with bail-out checkpoints (e.g., Stage 0 volatility bail, Stage 2 conflict bail) directly to decision doc.  
  [Why]: Well-designed per focus #1; ensures time-efficiency for "defer" (addresses focus #5), prevents sunk-cost escalation; stages logically progressive (audit → setup → probe → assess). No reordering needed — HTTP probe (focus #2) is ideal real integration test via existing adapters.  
  [Fix]: N/A

- [F10]  
  [Severity]: STRENGTH  
  [Finding]: 4 criteria precisely target tess-v2 invariants (vault no-bypass, contract immutability, no dual-scheduling, additive dashboard) vs. Paperclip adds.  
  [Why]: Per focus #3, spot-on for decision; Stage 2 ties them to concrete tests/output table; verification ensures completeness. "Defer" risk handled efficiently via bails/quick doc.  
  [Fix]: N/A

- [F11]  
  [Severity]: STRENGTH  
  [Finding]: Clear outputs per stage (tables, screenshots, matrices) feed directly into Stage 4 decision doc template.  
  [Why]: High clarity/feasibility; internal consistency strong (e.g., roles map to executors, collisions inventoried).  
  [Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. Time budget is unrealistic (4/4 reviewers)**
OAI-F12, GEM-F4, DS-F4, GRK-F4. All reviewers flag ~3 hours as too tight, particularly Stage 2 (~1 hour for adapter + 4-criteria evaluation). Estimates range from 4.5–7 hours typical. OpenAI suggests narrowing scope; Gemini suggests switching to Bash adapter to reduce custom code.

**2. HTTP adapter is the wrong primary integration test (3/4)**
GEM-F1 (CRITICAL), DS-F3, OAI-F3/F4. Gemini's argument is strongest: tess-v2 is a CLI/cron-driven system — making it accept HTTP POSTs as a web server fundamentally alters its architecture just to run the spike. DeepSeek and Gemini both recommend using Paperclip's existing Bash adapter to call tess-v2's actual CLI entry points. OpenAI suggests keeping HTTP as first probe but adding authority/scheduler tests.

**3. Missing evaluation criteria — state ownership is the biggest gap (3/4)**
OAI-F5, GEM-F3, GRK-F6. The plan tests vault authority and contract verification but doesn't explicitly address: who is the source of truth for task lifecycle? Who owns retry decisions? Do budget/approval gates conflict? OpenAI identifies 5 missing criteria; Grok adds error propagation and security.

**4. Stage 1 bail checkpoint is toothless (3/4)**
GEM-F2, GRK-F7, OAI-F24 (implicit). "Note friction, continue" defeats the purpose of a bail checkpoint. Gemini: if role modeling is fundamentally incompatible, proceeding to a 1+ hour adapter build is wasted effort. Grok: if >15 min workarounds needed, bail with "build own" lean.

**5. Unverifiable claims need pre-verification (4/4)**
OAI-F25/F26/F27, GEM-F5, DS-F1, GRK-F1/F2. The `npx paperclipai onboard --yes` command, version `v2026.403.0`, and "weekly calver releases" assertions are all ungrounded in the plan. Will self-verify during Stage 0, but should be acknowledged.

**6. Staged approach with bail-out checkpoints is a strength (4/4)**
OAI-F2, GEM-F6, DS-F6, GRK-F9. Universal praise. The structure prevents sunk-cost escalation and makes a "defer" outcome time-efficient.

### Unique Findings

- **GEM-F1 (CRITICAL): Paradigm mismatch — use Bash adapter.** Gemini is the only reviewer to classify this as CRITICAL and articulate the architectural argument clearly: spinning up a Flask/FastAPI server to accept Paperclip POSTs fundamentally changes tess-v2's execution model. **Genuine insight** — this is the strongest single finding across all reviews.

- **OAI-F7: "Build thin sub-orchestrator" path underdeveloped.** Only OpenAI flagged that the plan mostly evaluates adopt vs. defer but doesn't gather evidence for the middle option. Stage 3 should explicitly ask: "Which Paperclip patterns are worth copying locally?" **Genuine insight.**

- **OAI-F22: Adapter should call stable public boundary, not internal `run_ralph_loop()`.** Calling internal functions may produce misleading compatibility results. Should prefer whatever entry point `dispatch.sh` actually uses. **Genuine insight.**

- **DS-F2: Toy hierarchy omits nemotron/local-LLM executor.** Only 2 of 3 executor types are represented in the 3-role hierarchy. **Minor but valid** — won't block the spike but should be noted.

- **GRK-F6: Missing security/performance criteria.** HTTP exposure of vault paths and Node.js dispatch overhead. **Noise if we switch to Bash adapter** (no HTTP exposure). Performance concern is speculative.

### Contradictions

**HTTP adapter vs. Bash adapter:**
- GEM + DS: Use Bash adapter (tess-v2 is CLI-native)
- OAI: Keep HTTP but add authority probes
- GRK: HTTP is fine, just needs schemas

**Resolution:** Gemini's paradigm-mismatch argument is decisive. tess-v2 runs via `dispatch.sh` → `python -m tess run`. The Bash adapter tests the real integration surface. HTTP adapter tests a hypothetical architecture that doesn't exist. **Use Bash adapter.**

**Stage ordering:**
- OAI: Reorder — interface audit before hierarchy setup
- DS + GRK: Current order is fine

**Resolution:** OAI's point is valid but the impact is small. Stage 0 already does the interface audit. Stage 1 is 30 minutes and provides dashboard signal. Keep current order but make Stage 1 bail actually bail.

### Action Items

**Must-fix (blocking):**

- **A1** — Switch Stage 2 from HTTP adapter to Bash adapter. Test Paperclip calling `dispatch.sh` or `python -m tess run` directly. Eliminates paradigm mismatch, reduces custom code, tests the real integration surface. *(Source: GEM-F1, DS-F3, OAI-F3)*

- **A2** — Add "state ownership / source of truth" as 5th evaluation criterion. Who is authoritative for task lifecycle, retry decisions, and completion status? *(Source: OAI-F5, GEM-F3, GRK-F6)*

- **A3** — Strengthen Stage 1 bail checkpoint. If role schema can't map to tess-v2 contracts without breaking single-assignee model → bail to decision doc. Not "note and continue." *(Source: GEM-F2, GRK-F7)*

- **A4** — Increase time budget to ~4.5 hours, or narrow scope if keeping 3h. Bash adapter approach (A1) reduces Stage 2 effort vs. HTTP, partially offsetting. *(Source: OAI-F12, GEM-F4, DS-F4, GRK-F4)*

**Should-fix:**

- **A5** — Define concrete examples of "irreconcilable state ownership conflict" for the bail checkpoint: both systems retry same work, Paperclip mutates immutable contract state, dashboard diverges from tess-v2 run state with no reconciliation. *(Source: OAI-F20)*

- **A6** — Add "build thin sub-orchestrator" as explicit analysis target in Stage 3. Ask: which Paperclip patterns are worth copying locally? *(Source: OAI-F7)*

- **A7** — Add budget/approval overlap evaluation. Can Paperclip's budget enforcement layer as advisory-only, or does it duplicate tess-v2's? *(Source: OAI-F17)*

- **A8** — If time permits after Bash adapter probe, test one non-trivial (claude-code/V3) contract to exercise retry classification and richer status progression. *(Source: OAI-F9, GRK-F5)*

- **A9** — Reframe heartbeat scheduling criterion around dual-scheduler risk, not cadence matching. *(Source: OAI-F10)*

**Defer:**

- **A10** — Unverifiable claims (version, npx command, release cadence) self-verify during Stage 0. No plan change needed. *(Source: OAI-F25-27, GEM-F5, DS-F1, GRK-F1/F2)*

- **A11** — Add test matrix table for execution/review. Nice-to-have. *(Source: OAI-F23)*

- **A12** — Add environment reproducibility notes (Node version, ports). *(Source: OAI-F19)*

### Considered and Declined

- **GRK-F6 (security — HTTP exposure of vault):** `out-of-scope` — resolved by A1 (switch to Bash adapter eliminates HTTP surface)
- **GRK-F8 (user-specific paths):** `constraint` — this is a personal OS plan, not a team document
- **DS-F5 (rename "contract verification"):** `overkill` — meaning is clear in context, and A2 adds the missing state ownership criterion
- **GEM-F3 (executor/adapter overlap criterion):** subsumed by A2 (state ownership covers executor authority)
- **DS-F2 (nemotron executor in hierarchy):** `out-of-scope` — 3-role toy hierarchy is intentionally simplified; nemotron contracts route through same shell executor path
