---
project: tess-v2
domain: software
type: note
skill_origin: inbox-processor
created: 2026-04-20
updated: 2026-04-20
tags:
  - evaluation
  - architecture
  - harness
  - orchestration
  - codex
---

# Tess-v2 Evaluation Frame: Model × Hermes × Crumb

## Purpose

Replace the vague idea of evaluating an "LLM + harness" with a sharper system model:

- **Model** = reasoning engine
- **Hermes** = operational harness / runtime shell
- **Crumb (vault)** = cognitive harness / durable world model

This note is meant to support future tess-v2 model selection for the **main voice + orchestrator role**, where Danny has clarified the actual priorities:

1. productivity
2. reasoning / judgment
3. task breakdown / delegation / orchestration
4. accuracy
5. voice consistency only after the above

It also incorporates an architectural follow-up: **Codex should be available in the system as a coding tool or sub-agent**, rather than being forced into the main orchestrator role.

---

## Core Thesis

The useful unit of evaluation is **not**:
- raw LLM quality
- benchmark score alone
- generic "agent harness" performance

The useful unit is:

**How well does a given model perform inside the actual tess-v2 stack?**

That means measuring three interacting layers:

1. **Model-native capability**
2. **Hermes interaction quality**
3. **Crumb interaction quality**

A model can be good in isolation and still fail inside this stack.
A model can also look mediocre in a generic benchmark and perform well once the stack shapes its work correctly.

---

## Layer 1: Model-Native Evaluation

This is the irreducible part — what the model itself must supply.

### What the model must do natively

- reason under ambiguity
- prioritize correctly
- decide what matters
- decompose work sensibly
- choose when to escalate vs continue
- refuse fabrication
- synthesize across partial evidence
- maintain judgment quality under pressure
- recover cleanly from partial failure

### Primary questions

- Does the model make good decisions when context is messy rather than synthetic?
- Does it decompose tasks naturally without over-fragmenting or freezing?
- Does it ask for the right missing information instead of inventing it?
- Does it preserve operator trust after repeated real tasks?

### Anti-patterns to flag

- benchmark-winning but live-useless
- structured but inert
- articulate but strategically weak
- compliant but low-initiative
- safe but non-productive
- "good student" behavior instead of operator behavior

---

## Layer 2: Hermes Evaluation

Hermes is the **operational harness**.

### Hermes should own mechanically

- tool invocation
- retries
- provider routing
- background execution
- cron / scheduling
- approvals
- process supervision
- formatting discipline
- subagent dispatch
- context packaging boundaries

### What to evaluate here

#### 2.1 Tool use quality
- Does the model choose tools at the right times?
- Does it avoid tool overuse when direct reasoning would suffice?
- Does it know when a tool result is incomplete vs authoritative?

#### 2.2 Decomposition through runtime
- Does the model translate goals into executable Hermes actions cleanly?
- Does it use `delegate_task` appropriately for bounded subproblems?
- Does it keep the decomposition coherent across turns?

#### 2.3 Escalation discipline
- Does it know when to invoke a stronger model or specialized subagent?
- Does it keep expensive routes for genuinely expensive problems?
- Does it avoid both over-escalation and under-escalation?

#### 2.4 Error recovery in live tool loops
- When tools fail, does it debug or does it theorize?
- Does it preserve truthfulness under repeated empty/partial results?
- Does it route around failure without thrashing?

#### 2.5 Productivity impact
- Does Hermes + model actually shorten time-to-useful-output?
- Or does the pair create overhead, ceremony, or brittle planning theater?

### Hermes-specific failure classes

- bad tool choice
- over-tooling
- under-tooling
- weak retry strategy
- failure to delegate
- delegating the wrong things
- expensive model invoked for routine work
- getting trapped in local loops instead of escalating

---

## Layer 3: Crumb Evaluation

Crumb is the **cognitive harness**.

### Crumb should own cognitively

- authoritative project state
- design docs
- run logs
- decisions / ADs
- next actions
- evaluation history
- role definitions
- failure patterns
- vault conventions
- durable context across sessions

### What to evaluate here

#### 3.1 Source selection quality
- Does the model read the right artifact for the question?
- Design question → design docs
- operational gap / current-state question → run log + project-state
- Does it stop pattern-matching and actually use the source hierarchy?

#### 3.2 State awareness
- Does the model use `project-state.yaml` correctly?
- Does it honor current task, phase, and next_action?
- Does it detect when docs and reality have drifted?

#### 3.3 Historical grounding
- Does it use the vault’s prior evaluations and decisions?
- Does it avoid relitigating already-settled questions?
- Does it pull the right precedent instead of generic knowledge?

#### 3.4 Context compression quality
- Does the model make use of Crumb context as a world model?
- Or does it drown in it, ignore it, or cherry-pick it badly?

#### 3.5 Operational usefulness
- After reading the vault, does the model produce better action?
- Or just more literary summaries of things Danny already knows?

### Crumb-specific failure classes

- reading the wrong source type
- ignoring run-log authority
- ignoring project state
- inventing facts despite nearby documentation
- using stale architecture instead of current state
- overvaluing design prose over operational evidence

---

## Combined Evaluation Matrix

Score models in the actual stack across these dimensions.

| Dimension | Weight | Question |
|---|---:|---|
| Live-task usefulness | 5 | After real use, does Danny want this model back tomorrow? |
| Judgment under ambiguity | 5 | Does it make good calls when the path is not obvious? |
| Task decomposition / orchestration | 5 | Does it break work down into useful, executable chunks? |
| Accuracy / fabrication discipline | 5 | Does it stay grounded under pressure? |
| Hermes tool-use quality | 4 | Does it exploit Hermes well instead of clumsily? |
| Crumb source-selection quality | 4 | Does it read the right things from the vault? |
| Error recovery in live loops | 4 | Does it recover truthfully and productively? |
| Escalation / delegation quality | 4 | Does it know when to call stronger tools/models/agents? |
| Productivity per unit cost | 4 | Is the output worth the spend and operator time? |
| Voice / style fit | 2 | Is it tonally right for Tess? |

### Why this weighting

This weighting explicitly downgrades voice and upgrades operator reality.
That reflects Danny’s clarified priorities.

---

## Evaluation Methods

### A. Synthetic battery (keep, but demote)

Still useful for:
- catching fabrication disasters
- structured output reliability
- baseline latency
- repeatable comparison

But it should no longer be treated as the final word.

### B. Live operator soak (upgrade to first-class gate)

This should now be a primary decision gate.

#### Suggested soak questions
At the end of each day or session:
- Was it useful?
- Did it save time or cost time?
- Did it make good decisions without babysitting?
- Did it decompose work well?
- Did it read/use Crumb intelligently?
- Did it know when to call tools/subagents?
- Did it annoy the operator by being rigid, inert, or over-structured?
- Would Danny choose it again tomorrow?

### C. Transcript audit

Review a sample of live transcripts and classify failures as:
- model-native
- Hermes interaction
- Crumb interaction

This is crucial. Otherwise every bad session turns into a vague indictment of the model.

---

## Revised Model Selection Doctrine

The selection target is not:
- highest benchmark score
- best voice
- cheapest model

The selection target is:

**The cheapest model whose failure modes the Hermes × Crumb stack can reliably manage for the main orchestrator role.**

For the highest-value judgment role, this still assumes a floor of real reasoning quality. A harness can constrain, route, and recover. It cannot manufacture taste or judgment from nothing.

---

## Implication for Current Candidates

### Kimi on OpenRouter
Per Danny’s live experience: ruled out for the main orchestrator role.
That is a stronger signal than the existing battery ranking.

### GPT-5.4
Should be reconsidered under the revised criteria.
Its major prior fault in the vault was stylistic shape. If style weight drops and real orchestration/productivity matter more, it deserves a cleaner reassessment.

### Sonnet 4.6
Still the most plausible quality benchmark for the orchestrator role.
But cost likely prevents using it as the default always-on model.
That suggests Sonnet should be treated as:
- benchmark / gold standard
- escalation target
- selective high-value lane
rather than the default runtime

---

## Coding Lane Addition: Codex as Tool or Sub-Agent

Danny has explicitly stated that **for coding specifically, Codex should be available in the mix**.

This is architecturally different from making Codex the main orchestrator.

### Recommended role for Codex
Codex should be introduced as a **specialized coding executor**, not as the default Tess voice/orchestration model.

### Preferred integration modes

#### Option 1: Codex as delegated coding subagent
Use when:
- implementation work is clearly bounded
- code changes are the core task
- a repo context exists
- independent code-focused reasoning is useful

Pattern:
- Tess handles top-level framing and decomposition
- Codex executes bounded coding tasks
- Tess reviews / integrates results into broader context

#### Option 2: Codex as an on-demand coding tool lane
Use when:
- direct code generation / review / refactor work is needed
- the task is concrete and repository-scoped
- operator wants a coding specialist, not a general orchestrator

Pattern:
- Tess decides whether the problem is coding-heavy enough to hand off
- Codex is called intentionally for implementation, refactor, review, or patch generation

### Why this is better than making Codex the main orchestrator

Because the orchestrator role and coding executor role are different jobs.

Main orchestrator needs:
- judgment
- context synthesis
- prioritization
- interaction with Crumb as world model
- role continuity

Codex needs:
- repository-local competence
- implementation speed
- code editing/review strength

That separation is healthy.

---

## Proposed Near-Term Actions

1. **Adopt this evaluation frame** as the working doctrine for main-orchestrator selection
2. **Reclassify the existing synthetic battery** as baseline screening, not final selection
3. **Create a live operator soak rubric** based on the weighted matrix above
4. **Re-test GPT-5.4 under the new rubric** (productivity/orchestration first, style second)
5. **Treat Sonnet 4.6 as quality benchmark / escalation lane**, not default runtime unless cost changes
6. **Add Codex as a coding specialist lane** — tool or delegated subagent, not main orchestrator

---

## Bottom Line

The useful evaluation object is no longer:
- model alone
or
- model + generic harness

It is:

**Model × Hermes × Crumb**

That is the real system.
And that is what should be optimized.
