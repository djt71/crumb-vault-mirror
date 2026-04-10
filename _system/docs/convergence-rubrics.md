---
type: reference
domain: null
skill_origin: null
status: active
created: 2026-02-15
updated: 2026-02-15
tags:
  - convergence
  - quality-rubrics
---

# Convergence Rubrics

Pre-built dimension sets for non-code quality assessment. Use these rather than inventing new rubrics each time.

## How to Use

1. Identify the output type (specification, writing, action plan, etc.)
2. Apply the relevant rubric dimensions below
3. Score each dimension: adequate | needs improvement
4. If any dimension "needs improvement" AND iteration count < 2: revise and re-score
5. Stop when all adequate OR 2 iterations reached OR human says "good enough"

## When to Add a Rubric

- After 3+ iterations on the same output type reveal common failure modes
- When compound step identifies reusable quality dimensions
- NOT preemptively for every possible output type

---

## Specification Quality

**Use for:** `specification.md`, requirements docs, problem analyses

1. **Completeness** — All key sections present (problem statement, facts/assumptions/unknowns, system map, task decomposition)
2. **Clarity** — Unambiguous language, clear definitions, no conflicting statements
3. **Actionability** — Downstream work can proceed without additional clarification; success criteria are measurable

## Writing Quality (General)

**Use for:** Emails, essays, blog posts, reports, documentation

1. **Audience fit** — Appropriate tone, terminology, and depth for intended reader
2. **Structure** — Logical flow, clear sections, good signposting
3. **Brevity** — No unnecessary words, sentences, or paragraphs; gets to the point

## Action Plan Quality

**Use for:** `action-plan.md`, project plans, task lists

1. **Coverage** — All major work represented; no critical gaps
2. **Dependency correctness** — Tasks properly sequenced; dependencies accurately mapped
3. **Risk calibration** — Risk levels (low/medium/high) match actual stakes and reversibility

## Personal Goal Quality

**Use for:** routines, habit plans, creative projects, relationship goals, spiritual practices

1. **Specificity** — Clear, measurable success criteria (not vague aspirations)
2. **Sustainability** — Realistic given known constraints (time, energy, dependencies)
3. **Feedback loop** — Built-in check-in mechanism to know if it's working

---

## Custom Rubrics

Add rubrics below as you discover recurring quality patterns through compound engineering.

<!-- Future rubrics added here -->
