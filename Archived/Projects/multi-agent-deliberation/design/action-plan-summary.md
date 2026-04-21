---
project: multi-agent-deliberation
domain: software
type: summary
skill_origin: action-architect
status: draft
created: 2026-03-18
updated: 2026-03-18
source_updated: 2026-03-18
tags:
  - architecture
  - multi-agent
  - experimental
topics:
  - moc-crumb-architecture
---

# Multi-Agent Deliberation — Action Plan Summary

## Structure

5 milestones, 20 tasks (7 code, 8 research, 4 decision, 1 writing). Each milestone gates on hypothesis results — failure at any gate is a valid outcome that redirects or terminates the project.

## Milestones

| Milestone | Goal | Tasks | Gate |
|---|---|---|---|
| M0: Baseline | Establish the bar; validate rating procedure | 2 | Does single-Opus baseline leave room for improvement? |
| M1: Infrastructure + H1/H2 | Build dispatch pipeline; test model diversity value | 8 | H1 (verdict variance) + H2 (multi-axis vs single-axis diversity) |
| M2: Dissent + H3 | Test structured dissent value | 4 | H3 (Pass 2 adds novel information) |
| M3: Synthesis + H4 | Test cross-artifact pattern detection | 3 | H4 (synthesis reveals non-obvious patterns) |
| M4: Meta-Evaluation | Final framework assessment | 2 | H5 (genuinely novel insights + weekly practice test) |

## Critical Path

```
M0 (baseline, $1-3) → M1 (build + test, $8-18) → M2 (dissent, $4-7) → M3 (synthesis, $5-12) → M4 (eval, $0)
```

Total budget: $18-40. Each gate can terminate the project, with maximum learning at minimum cost front-loaded.

## Key Additions from Spec Tasks

The spec defined 17 tasks (MAD-000 through MAD-016). The action plan adds:
- **MAD-001a:** Baseline data collection (separated from rating procedure development)
- **MAD-004a:** Primary baseline prompt development (prerequisite to H2 testing — prompt parity, now depends on gate+schema, runs parallel with infrastructure)
- **MAD-012a:** Cold artifact sourcing (listed under M2, runs concurrent with dissent work, prerequisite to M3)

## Top Risks

1. **M0 gate kills project** — valid outcome, $1-3 cost
2. **MAD-003 (dispatch agent)** — largest code task, mitigated by peer-review-dispatch pattern
3. **Cold artifact availability (M3)** — need live pipeline output; start collecting early
4. **Rating drift** — calibration anchor re-rated at every gate boundary

## Implementation Order

Start with MAD-000 (rating procedure on warm artifacts). This is executable immediately — no code, no infrastructure, just Danny + Opus + overlays + the rating rubric. If the baseline is strong, the project pivots or stops before any code is written.
