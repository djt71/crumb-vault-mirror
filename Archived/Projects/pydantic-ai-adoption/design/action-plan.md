---
type: action-plan
domain: software
status: active
project: pydantic-ai-adoption
skill_origin: action-architect
created: 2026-03-16
updated: 2026-03-16
---

# Action Plan — pydantic-ai-adoption

**Source:** `design/specification.md` §8
**Estimated effort:** 2–3 days total (spec estimate). Spike is the cost-discovery phase — dataset build effort depends on extraction findings.

---

## M1: Empirical Spike

Prove the approach works before committing. This milestone is the primary risk-reduction gate — if it fails, the project stops cleanly with minimal sunk cost.

### Phase 1: V2 Decision + Environment

Check Pydantic AI V2 release status. Set up the eval directory, venv, and dependencies per spec §3.1–§3.2.

### Phase 2: Extraction Test

Extract the AO idempotency predicate as a Python callable. This is the highest-risk task — if AO logic is too tightly coupled to Crumb's session context, it surfaces here. Write one test case and verify end-to-end.

### Phase 3: Spike Assessment

Record findings: setup time, LOC, blockers, extraction difficulty. This feeds directly into the adoption checkpoint.

**Success criteria:**
- Venv created, pydantic-evals installed, pip audit clean
- One AO decision path extracted as Python callable
- One test case runs and produces structured pass/fail output
- Spike completed within 1-day stop condition

---

## M2: Adoption Checkpoint

Go/no-go gate. 30-minute structured comparison: pydantic-evals vs pytest + custom assertions for the AO test cases. Follows the gate evaluation pattern — criteria are fixed (spec §5.2), evaluation is structured.

**Success criteria:**
- LOC comparison documented
- Capability comparison documented (dataset management, evaluator composition, result reporting)
- Explicit go/no-go decision with rationale in run-log
- If no-go: project pivots to pytest, remaining tasks adapted or closed

---

## M3: Dataset & Evaluator Build

Build the full eval suite. Only entered if M2 passes (go decision).

### Phase 1: Datasets

Create both eval datasets per spec §3.5 schema. Idempotency covers full confusion matrix (TP, TN, FP, FN) plus edge cases. Signal assembly covers tier behavior under budget variations.

### Phase 2: Evaluators + Integration

Custom evaluators for domain-specific assertions. Single-command runner producing JSONL results per spec §3.7.

### Phase 3: Validation + Retrospective

All deterministic tests pass. At least one deliberate failure on known-bad input. Run-log retrospective with actual costs and effort vs estimates.

**Success criteria:**
- 2 datasets (idempotency 8–10 cases, signal assembly 5+)
- Custom evaluators written and working
- All deterministic tests pass at pinned commit
- One deliberate failure documented
- Single-command execution from activated venv
- JSONL results written to `progress/eval-results/`
- Retrospective entry in run-log

---

## Dependency Graph

```
M1 (Empirical Spike) → M2 (Adoption Checkpoint) → M3 (Dataset Build)
                                                     ↗ only if M2 = GO
```

M2 is a hard gate. If M2 = no-go, M3 is replaced with a pytest pivot (out of scope for this plan — would require re-planning).
