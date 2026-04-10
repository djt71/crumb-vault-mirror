---
type: pattern
domain: software
status: active
track: pattern
created: 2026-03-08
updated: 2026-04-04
tags:
  - system-design
  - quality-evaluation
  - compound-insight
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Gate Evaluation Pattern

## Pattern

Define success criteria before an autonomous period begins. Run the autonomous period. Evaluate against the criteria. Make a gate decision (proceed, iterate, or stop). The criteria are fixed at gate definition time — they don't shift during execution.

```
Define criteria → Run autonomous period → Evaluate against criteria → Gate decision
```

This is the reusable mechanism underneath milestone gates, soak tests, and any workflow where measurable acceptance criteria govern a go/no-go decision.

## Evidence

**tess-operations M1 gate (2026-02-27):**

Five success criteria defined before the 3-day evaluation period:
- Briefing utility ≥ 3/5
- Alert false-positive rate < 25%
- Cost ≤ $3/day
- System stability (no unplanned restarts)
- Prompt tuning convergence (SOUL.md changes decreasing)

The criteria were set at gate definition time (PLAN phase), not retroactively. The 3-day autonomous period ran without modifying criteria. Evaluation was structured: each criterion assessed independently, overall gate decision derived from the set.

**Autoresearch keep/discard (Karpathy, 2026-03):**

Simplest instance of the pattern:
- Criterion: val_bpb improves (single metric, binary)
- Autonomous period: 5-minute training run
- Evaluation: compare metric
- Gate decision: keep change or discard

Works because the metric is computable, objective, and independent per experiment. Breaks down when quality is multi-dimensional or requires judgment.

**Symphony CI gate (OpenAI, 2026-03):**

- Criterion: CI passes
- Autonomous period: agent coding session (up to 20 turns)
- Evaluation: check CI status + ticket state
- Gate decision: deliver PR or retry with backoff

Same limitation as autoresearch: binary pass/fail. No evaluation of whether the PR is good — only whether it compiles and tests pass.

**Context Checkpoint Protocol phase gates (Crumb):**

- Criteria: phase-specific (spec completeness, design coverage, task decomposition quality)
- Autonomous period: phase execution
- Evaluation: structured gate evaluation with compound reflection
- Gate decision: advance, iterate, or escalate

Multi-criteria, judgment-dependent. More expensive than computable gates but catches quality dimensions that binary metrics miss.

## The Spectrum

Gate evaluation instances differ along two axes:

| | Single metric | Multi-criteria |
|---|---|---|
| **Computable** | Autoresearch (val_bpb), test pass rate, vault-check | Cost thresholds, uptime %, false-positive rate |
| **Judgment-dependent** | Approval contracts (AID-*) | Milestone gates, convergence rubrics, phase transitions |

The pattern is the same in all quadrants. What changes is the evaluation cost and the confidence in the decision.

## Where This Applies in Crumb

| Instance | Criteria source | Autonomous period | Evaluation method |
|---|---|---|---|
| Milestone gates (tess-operations) | Spec-defined per milestone | Multi-day soak | Structured multi-criteria assessment |
| Phase transitions (any project) | Context Checkpoint Protocol | Phase duration | Compound reflection + gate eval |
| vault-check pre-commit | Rule definitions in vault-check.sh | Development session | Automated pass/fail |
| Convergence rubrics (researcher) | Per-deliverable dimensions | Research loop iterations | Weighted score threshold |
| FIF adapter soak tests | Adapter-specific acceptance criteria | Soak period (e.g., 20 runs) | Metric collection + threshold check |
| Post-call format override rate | "< 20% override after 20 calls" | 20-call window | Count-based threshold |

## Design Heuristic

1. **Criteria before execution.** Define what "good" means before running, not after. Retroactive criteria invite confirmation bias.
2. **Separate the evaluator from the executor.** The agent doing the work should not be the sole judge of whether the work is good. Crumb's governance separation (Tess operates, Crumb governs) is an instance of this.
3. **Match evaluation cost to decision stakes.** Computable gates for routine decisions (vault-check, test suites). Judgment-dependent gates for consequential transitions (milestone advancement, production deployment).
4. **Fixed criteria, flexible execution.** The autonomous period can adapt freely — the criteria don't move. If criteria need updating mid-execution, that's a scope change, not a gate evaluation.
5. **Binary gates compound into multi-criteria gates.** A milestone gate with 5 criteria is five binary gates evaluated together. Each criterion should be independently assessable.

## Relationship to Other Patterns

- **Behavioral vs. automated triggers:** Gate evaluation criteria can be enforced behaviorally (operator reviews) or automated (vault-check rules, metric thresholds). The behavioral-to-automated trajectory applies here — start behavioral, promote to automated as the criterion becomes computable.
- **Validation is convention source of truth:** Gate criteria, once defined, are authoritative. Don't weaken criteria to accommodate drift — update criteria explicitly or fix the execution.
- **Ceremony Budget Principle:** Gate evaluations add ceremony. Justify each criterion against the cost of evaluating it. A gate with 12 criteria is probably 8 criteria and 4 that aren't worth measuring.

## Scope

Applies anywhere there is: (1) a defined success state, (2) an autonomous execution period, and (3) a decision point. Not limited to software — the pattern applies to learning plans (skill acquisition gates), career milestones, and any domain where "did this work?" needs a structured answer beyond intuition.
