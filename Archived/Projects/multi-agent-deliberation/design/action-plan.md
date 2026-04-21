---
project: multi-agent-deliberation
domain: software
type: action-plan
skill_origin: action-architect
status: draft
created: 2026-03-18
updated: 2026-03-18
tags:
  - architecture
  - multi-agent
  - experimental
topics:
  - moc-crumb-architecture
---

# Multi-Agent Deliberation — Action Plan

## Overview

This is a gated experimental project. Each milestone produces a go/no-go decision. A "no-go" at any gate is a valid, valuable outcome — it means the experiment worked and the answer was "no." The action plan is designed so that maximum learning happens at minimum cost, front-loading the cheapest tests.

**Estimation note:** Per estimation-calibration.md, gated projects with early checkpoints compress timelines when gates fire early. Phase 0 baseline could terminate the project at $1-3 cost, saving $15-37 of infrastructure investment.

---

## Milestone 0: Baseline & Rating Procedure (Pre-Infrastructure)

**Goal:** Establish the bar the multi-model framework must clear, and validate that the rating procedure works before collecting gate-bearing data.

**Success criteria:**
- 3-5 warm artifacts evaluated via single-Opus multi-lens prompt
- Rating procedure (§5.9) tested on real output and refined
- Calibration anchor set (§5.10) established — 5 rated findings stored for drift detection
- Written baseline quality assessment: does the baseline leave room for multi-model improvement?
- Gate decision: proceed to infrastructure build or reassess

**Why this comes first:** If single-Opus analysis with 4 overlays already produces consistently high-quality multi-perspective insights, the multi-model framework may not add enough value to justify its cost. Learning this before writing any code is the highest-leverage test in the project.

**Relationship to M1 baseline:** This is the *accessibility baseline* — a single smart prompt as the cheapest possible test ("should I bother at all?"). The *primary experimental baseline* (4 same-model calls with separate overlays, comparable structure to the panel) is developed in M1 via MAD-004a after infrastructure exists. The M1 baseline provides the fair comparison for H2/H5; the M0 baseline provides the early kill switch.

### Phase 0a: Rating Procedure Development

Develop and test the §5.9 rating procedure on 2-3 warm artifacts before any gate-bearing data is collected. This is procedure validation, not hypothesis testing.

- Select 2-3 warm artifacts from Scout calibration seed
- Run single-Opus combined-prompt baseline on each
- Practice the full procedure: extract → blind → rate → gut-check → unblind → deduplicate
- Refine the procedure based on friction points
- Establish calibration anchor: select 5 representative findings, record ratings

### Phase 0b: Baseline Data Collection

With the validated procedure, run the full baseline on 3-5 warm artifacts.

- Run single-Opus combined-prompt on 3-5 warm artifacts (may reuse Phase 0a artifacts)
- Rate all findings per refined procedure
- Write baseline quality assessment
- Gate decision

---

## Milestone 1: Dispatch Infrastructure + H1/H2 Testing

**Goal:** Build the minimum viable deliberation pipeline and test whether model diversity produces meaningfully different analysis.

**Success criteria:**
- Deliberation config, schema, dispatch agent, and skill are functional
- H1 tested: verdict variance across 4 models on same overlay, 5 artifacts
- H2 tested: 3-condition comparison (same-model-diff-overlay vs. diff-model-same-overlay vs. full panel) on 5 artifacts, with primary baseline comparison
- Written gate evaluation with H1/H2 verdict and proceed/pivot/stop decision

**Key risk:** MAD-003 (dispatch agent) is the largest implementation task. Mitigated by adapting the proven peer-review-dispatch pattern rather than building from scratch.

### Phase 1a: Infrastructure Build

Build the four foundational artifacts. No hypothesis testing until these are functional.

- Config file (MAD-001)
- Assessment schema (MAD-002)
- Dispatch agent (MAD-003)
- Deliberation skill (MAD-004)

### Phase 1b: Baseline Prompt Development

Before running H2 comparisons, develop and document the primary baseline prompt (4 GPT-5.4 calls with separate overlays). This ensures prompt parity between baseline and panel — different only in model diversity.

### Phase 1c: H1/H2 Experimental Runs

Run the hypothesis tests and collect data.

- H1 test: same overlay, 4 models, 5 artifacts (MAD-005)
- H2 test: 3-condition comparison + baselines, 5 artifacts (MAD-006)
- Rate all findings per §5.9 procedure (blinded, conditions presented in randomized order per artifact to avoid recognition/memory effects)
- Re-rate calibration anchor set to check for drift

### Phase 1d: Gate Evaluation

- Written gate evaluation (MAD-007)
- H1 qualitative annotations per artifact
- Comparison against Phase 0 baseline data
- Proceed/pivot/stop decision

---

## Milestone 2: Dissent Protocol + H3 Testing

**Goal:** Test whether structured dissent (agents reading and responding to each other's assessments) adds information beyond independent assessment.

**Success criteria:**
- Split-check logic implemented
- Pass 2 dispatch working (inter-agent injection resistance, prior assessment inclusion)
- H3 tested: 5-7 deliberations with forced Pass 2, dissent novelty measured
- Written gate evaluation with H3 verdict

**Key risk:** Pass 2 prompt growth. Each evaluator receives all Pass 1 assessments (~3,200-4,800 tokens added). §8.6 prompt size limits mitigate, but quality degradation on long contexts is possible. Monitor per-model response quality.

### Phase 2a: Dissent Infrastructure

- Split-check logic (MAD-008)
- Pass 2 dispatch with injection resistance and forced-Pass-2 flag (MAD-009)

### Phase 2b: H3 Experimental Runs

- 5-7 deliberations with `experimental_force_pass_2: true` (MAD-010)
- Mix of warm and cold artifacts
- Rate Pass 2 findings separately from Pass 1 to measure incremental value
- Re-rate calibration anchor set

### Phase 2c: Gate Evaluation

- Written gate evaluation (MAD-011)
- Proceed to synthesis / simplify to single-pass / stop

---

## Milestone 3: Synthesis + H4 Testing

**Goal:** Test whether cross-artifact synthesis reveals patterns invisible to per-artifact evaluation.

**Success criteria:**
- Synthesis engine implemented (hybrid: structured extraction + Opus analysis)
- Batch manifest and batch-complete trigger working
- H4 tested: 1+ batch of 5-10 cold artifacts with synthesis
- Written gate evaluation with H4 verdict

**Prerequisite:** MAD-012a (cold artifact sourcing, runs concurrently with M2) must be complete before M3 experimental runs begin.

**Key risk:** Cold artifact availability. Phase 3 requires artifacts the evaluators haven't seen. These must be sourced from live pipelines (new Scout candidates, new signal notes, novel architectural questions). If insufficient cold artifacts are available, Phase 3 stalls.

### Phase 3a: Synthesis Infrastructure

- Synthesis engine (MAD-012): structured data extraction + Opus analysis prompt
- Batch manifest definition

### Phase 3b: H4 Experimental Runs

- Define batch manifest with 5-10 cold artifacts
- Run deliberations on all batch artifacts (MAD-013)
- Run synthesis
- Danny evaluates synthesis patterns

### Phase 3c: Gate Evaluation

- Written gate evaluation (MAD-014)
- Framework validated / per-artifact-only / archive

---

## Milestone 4: Meta-Evaluation

**Goal:** Final assessment of the deliberation framework's value across all experimental phases.

**Success criteria:**
- All experimental data reviewed against H5 criteria
- "Would I use this weekly?" qualitative checkpoint answered
- Written recommendation document: integrate / iterate / archive

### Phase 4a: Data Review

- Compile all deliberation records, ratings, costs (MAD-015)
- Count genuinely novel insights (R2 findings) across all phases
- Count actions triggered by insights
- Re-rate calibration anchor set (final drift check)

### Phase 4b: Recommendation

- Written results summary and integration recommendation (MAD-016)
- If integrate: scope the integration project
- If iterate: define what to change and re-test
- If archive: document learnings for future reference

---

## Dependencies Between Milestones

```
M0 (Baseline) ──gate──▶ M1 (Infrastructure + H1/H2) ──gate──▶ M2 (Dissent + H3) ──gate──▶ M3 (Synthesis + H4) ──gate──▶ M4 (Meta-Eval)
```

Each gate is a hard dependency. No milestone begins until the previous gate passes. Gate failures redirect or terminate — they don't queue.

## Cross-Project Dependencies

| This Project Needs | From Project | Status |
|---|---|---|
| Overlay documents (7 active) | System (overlays) | Available |
| API keys (4 providers) | System (peer-review infra) | Available |
| Peer-review-dispatch pattern (code reference) | Peer-review skill | Available |
| Cold artifacts (Phase 3) | Scout, FIF, active projects | Dependent on pipeline output |

| Other Projects Need | From This Project | Status |
|---|---|---|
| Deliberation capability (if validated) | A2A (Workflow integration) | Deferred pending H5 |
