---
type: solution
track: pattern
domain: software
status: active
created: 2026-04-21
updated: 2026-04-21
confidence: high
tags:
  - compound
  - llm-evaluation
  - doctrine
  - model-selection
source_projects:
  - tess-v2
source_artifacts:
  - Projects/tess-v2/design/model-hermes-crumb-evaluation-frame-2026-04-20.md
  - Projects/tess-v2/design/spec-amendment-AC-execution-surfaces.md
  - Projects/tess-v2/design/live-vs-documented-hierarchy-reconciliation-2026-04-20.md
  - Projects/tess-v2/eval-results/cloud-eval-results-kimi-2026-03-30.md
---

# Live Soak Beats Benchmark for Role-Fit Judgment

## Claim

Synthetic benchmark scores — even well-designed ones — do not predict whether
an LLM will be acceptable in a production role. **Live soak under operator use
is the governing signal.** Promote a model to a production role only after
real-workload exposure with operator-in-the-loop review, regardless of how it
scored on synthetic evaluation.

## Evidence

- **Kimi K2.5 as Tess orchestrator (2026-03-30 onward):** Scored 76/95 on the
  TV2-Cloud evaluation battery. A later synthetic battery (2026-04) scored it
  87/100. Both evaluations passed the "GO" threshold. Live operator use over
  ~3 weeks revealed persistent latency and reasoning-quality issues that made
  Kimi unacceptable in the role. The synthetic scores did not surface these
  failure modes.
- **GPT-5.4 runtime swap (2026-04-20):** After Kimi was replaced with GPT-5.4,
  the orchestration role *itself* was judged inadequate by the operator —
  regardless of which frontier model powered it. A second model choice that
  would have passed any benchmark still failed the acceptability bar. This
  argued the issue was role-shape, not model-shape.
- **Amendment AC (2026-04-21):** Retracted Tess's orchestrator role on live-
  evidence grounds. The architectural decision preceded by Amendment Z had
  been peer-reviewed twice; synthetic evaluation was extensive. Only live
  soak surfaced the mismatch.

## Pattern

Evaluation of an LLM for a role should have three gates, not one:

1. **Benchmark / synthetic battery** — necessary but not sufficient. Use to
   exclude obviously inadequate candidates, not to certify adequacy.
2. **Integration smoke test** — does the model work end-to-end with the actual
   runtime, tools, and context? Catches integration issues that synthetic
   evaluation misses.
3. **Live soak with operator review** — minimum 1–2 weeks of real-workload
   exposure. Operator reviews outputs, latency, failure modes as they occur.
   *This* is the gate that determines acceptability.

Do not ship a model into a production role on benchmark score alone. Scope the
benchmark as a filter, not a verdict.

## When to Apply

- Selecting or swapping LLMs for any operator-facing role (orchestration,
  dispatch, interactive assistance, content generation).
- When a model passes evaluation but operator intuition says something is off
  — trust the live-soak signal over the benchmark.
- When deciding whether to automate a task class — live observation of the
  task across varied inputs is the admission criterion, not scored examples.

## When Not to Apply

- Selecting a model for a **mechanical, fully-specified task** with deterministic
  output (e.g., classification with a closed schema). Benchmarks are more
  predictive here because the role shape is narrow.
- Early-stage candidate filtering where the goal is to cut an obviously inadequate
  model from the pool — benchmarks are appropriate as a first-pass filter.

## Corollary

Benchmarks optimize models against benchmark-shaped tasks. If your production
workload differs from benchmark shape (and it almost always does for open-ended
orchestration or interactive roles), benchmark performance is a lower bound on
failure modes, not an upper bound on capability.

## Related

- `_system/docs/solutions/vendor-comparison-feature-inventory.md` — adjacent
  pattern on framing-risk in vendor comparisons
- Memory: `model-kimi-recovery-fabrication.md`, `model-grok-fabrications.md` —
  specific live-observation findings
