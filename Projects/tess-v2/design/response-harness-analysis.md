---
project: tess-v2
type: design-input
domain: software
status: active
scope: general
created: 2026-03-30
updated: 2026-03-30
source: https://autobe.dev/blog/function-calling-harness-qwen-meetup-korea/
tags:
  - validation
  - contract-execution
  - response-parsing
  - escalation
---

# Response Validation Harness — Design Input for Phase 3

> **Scope:** Generally applicable beyond tess-v2. The lenient-parsing and verify-to-converge patterns here apply to any LLM integration with bounded retry budgets. See `_system/docs/tess-v2-durable-patterns.md` and the distilled pattern at `_system/docs/solutions/lenient-parsing-before-evaluation.md`.

## Source

AutoBE blog post: "Function Calling Harness: From 6.75% to 100%" (autobe.dev, presented at Qwen Meetup Korea). AutoBE is an open-source AI agent that generates production-grade backends from natural language, achieving 99.8%+ compilation success across five Qwen models (3B–17B active parameters) despite first-try success rates as low as 6.75%.

## Core Insight

> "If you can verify, you converge."

A deterministic validation loop — schema constraining outputs, validators checking results, structured feedback correcting errors — converts probabilistically unreliable model output into guaranteed convergence. Demonstrated across a 10x parameter range with near-identical final success rates.

## Three-Layer Pattern

AutoBE's harness is three layers, not one. Each layer contributes independently:

### Layer 1: Schema Constraint (structural impossibility over prohibition)

Instead of prompting "don't create utility functions," the type schema makes utility functions structurally impossible to express. The output format has no slot for them.

**Tess v2 application:** Contract output schemas should constrain what executors *can* produce, not instruct them on what to avoid. C6 (no behavioral triggers for critical operations) already points this direction — this extends it from process to output structure. When designing contract schemas (§9, high-leverage intervention point #1), prefer closed schemas (enumerated fields, typed unions) over open ones (freeform text blocks with instructions).

**Concrete example:** If a contract expects a list of vault file paths to modify, the schema should accept `path: string & Format<"vault-path">` — not a freeform string with a prompt saying "only use real vault paths." The validator catches invalid paths mechanically.

### Layer 2: Deterministic Validation with Precise Feedback

AutoBE's validators produce field-level error messages: exact path, expected type, actual value, constraint violation. The model receives targeted corrections, not "try again."

**Tess v2 application:** The contract evaluation step (Tess evaluating executor output, AD-007) should produce structured diagnostics, not pass/fail. When a Ralph loop iteration fails (§9.4), the failure context injected into iteration N+1 should include:
- Which specific quality_checks failed
- What the expected output was (from contract)
- What was actually produced
- The minimal delta between actual and expected

This is the difference between "contract not satisfied, try again" and "quality_check 3 failed: expected vault path under Projects/tess-v2/, got absolute filesystem path /Users/tess/crumb-vault/Projects/tess-v2/." The latter converges in fewer iterations.

### Layer 3: Lenient Input Recovery

AutoBE documents 7 common LLM output failures that their parser recovers from silently: markdown code block wrapping, unclosed brackets, trailing commas, unquoted keys, incomplete keywords, type mismatches, double-stringification of union types.

**Tess v2 application:** The response parsing layer between executor output and contract evaluation should handle common malformations without burning a retry iteration. Particularly relevant given:
- F4 (Ollama tool-calling pipeline mismatch for Qwen3.5)
- Local models produce more formatting errors than frontier models
- Each unnecessary retry burns context and latency

**Design recommendation:** Implement a lenient parsing layer *before* the contract evaluator. Recoverable formatting errors are fixed silently (logged but not retried). Only semantic/content failures trigger Ralph loop iterations. This preserves the retry budget for real failures.

## Implications for Open Unknowns

### U3: Confidence-Aware Escalation — Retry Count as Signal

The article demonstrates that strong models converge in 1-2 attempts, weak models in 3-4. **Retry count is itself a confidence/capability signal.**

This suggests a fourth gate for §7 (or an enhancement to Gate 2):

- **Gate 4: Convergence rate monitor.** Track per-action-class convergence rates. If a known task class that normally converges in 1-2 iterations starts requiring 3+ → the task instance is harder than typical, or the model is struggling. This is a mechanical signal, not self-reported confidence.

This also provides a feedback loop for routing decisions: if action class X consistently exhausts retry budgets on the local model but converges in 1 attempt on frontier → reclassify X from Tier 1/2 to Tier 3 in the routing table. The routing table becomes self-tuning based on observed convergence data.

### U2: Dual-Model Justification — Weakened

The article's "small models as superior QA" finding argues: build the validation harness against the weaker model's actual failure modes. If the harness works for 27B (or Nemotron), it works for everything above it. Large models that "correctly guess" ambiguous parts *hide harness weaknesses* that only surface expensively in production edge cases.

This strengthens the existing default (single-model architecture, §6.4) and weakens the case for GLM dual-stack. Better to invest in harness robustness than in routing complexity.

### Bad-Spec Infinite Loop (§2.4 Failure Mode)

The validation harness directly addresses this. If contract evaluation produces structured diagnostics (Layer 2), and convergence rate is monitored (U3 extension), then a contradictory spec manifests as: structured errors that don't decrease across iterations + convergence rate anomaly. This triggers dead-letter routing with diagnostic evidence, not blind retry exhaustion.

## Model-Specific Parsing Notes

The article documents that Qwen 3.5 has 100% consistency in double-stringifying `anyOf` (union type) fields. This is a *model-specific* parsing quirk, not a general LLM failure. The current evaluation model is Nemotron, not Qwen — so this specific quirk may not apply. However:

1. The *category* of model-specific parsing quirks is universal
2. Phase 3 design should include a parsing quirk discovery step during executor onboarding
3. Each executor model's quirks feed into the lenient parsing layer configuration

## What Doesn't Transfer

AutoBE operates in code generation — their validators are compilers with decades of deterministic precision. Tess v2 operates across:

- **Software tasks:** Strong transfer. Executor output can be compiled, tested, linted. Convergence is mechanical.
- **Knowledge work:** Partial transfer. Schema constraints apply (output format, required sections, citation structure). But quality evaluation of content (research briefs, career recommendations) is not deterministically verifiable — convergence is probabilistic, not guaranteed.
- **Operational tasks:** Moderate transfer. File operations, vault writes, service management — outcomes are verifiable. But "appropriate response to an escalation" is a judgment call.

Phase 3 design should classify contract types by verifiability tier and apply the harness pattern proportionally — full mechanical validation for software contracts, schema + heuristic validation for knowledge work, schema-only for soft-judgment tasks.

## Recommendations Summary

| Recommendation | Affects | Priority |
|---|---|---|
| Structured diagnostics in failure context (not just pass/fail) | §9.4, Ralph loop iterations | High — directly improves convergence rate |
| Lenient parsing layer before contract evaluation | New component, Phase 3 design | High — preserves retry budget |
| Closed contract output schemas over open + instructions | §9 contract schema design | High — extends C6 to output structure |
| Convergence rate tracking as escalation signal | §7 (U3), routing table | Medium — self-tuning routing |
| Per-executor parsing quirk profiles | Executor onboarding, Phase 3 | Medium — model-specific recovery |
| Verifiability tier classification for contracts | Phase 3 contract taxonomy | Medium — right-sizes validation effort |
| Strengthen single-model default (weaken U2 dual-stack case) | §6.4 | Low — already the default, this is evidence |
