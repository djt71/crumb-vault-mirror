---
project: tess-v2
domain: software
type: note
skill_origin: inbox-processor
created: 2026-04-20
updated: 2026-04-20
tags:
  - codex
  - coding-lane
  - architecture
  - orchestration
  - subagent
---

# Tess-v2: Codex Integration Note for the Coding Lane

## Purpose

Define how **Codex** should enter the tess-v2 stack without confusing its role with Tess’s main orchestrator role.

This note assumes the revised evaluation doctrine now in play:
- main orchestrator selection is based on **productivity, judgment, orchestration quality, and accuracy**
- voice/style is secondary
- Codex is desired **for coding specifically**, as a **tool or sub-agent that can be called**

## Executive Summary

**Recommendation:** Introduce Codex as a **specialized coding executor lane**, not as the default Tess voice/orchestrator model.

That means:
- **Tess stays the top-level operator-facing orchestrator**
- **Codex handles bounded coding work**
- **Crumb provides authoritative context and project state**
- **Hermes provides the dispatch/runtime shell**
- **Nemotron remains a local execution option where it is still useful**

In short:

- Tess decides
- Codex builds/reviews code
- Crumb grounds the task
- Hermes routes the work

## Why Codex Belongs in the System

The vault already contains enough evidence to justify Codex as a coding lane.

### 1. Prior tess-v2 review flow already used Codex successfully

Examples in project artifacts:
- `reviews/2026-04-06-code-review-manual-amendment-z.md`
- multiple `reviews/raw/*codex*` artifacts
- code-review panels already include Codex as a reviewer alongside Anthropic/Opus

So Codex is not hypothetical in this project. It is already a demonstrated participant in the code-review path.

### 2. Prior “Codex is deprecated” objection was explicitly resolved

In `reviews/2026-03-28-tess-v2-specification.md`, a reviewer objected that Codex was deprecated.
The synthesis explicitly marks that objection **incorrect**, because it confused:
- the old deprecated Codex API
with
- the newer **Codex CLI / agentic coding tool**

So the project already has precedent for treating Codex as a viable modern coding tool.

## Architectural Position

Codex should not be treated as:
- the main Tess voice
- the primary system orchestrator
- the durable world-model owner
- the replacement for Crumb

Codex should be treated as:
- a **coding specialist**
- a **repository-scoped executor**
- a **tool-using implementation sub-agent**
- a **review / refactor / patch / feature-building lane**

## Role Separation

### Tess (top-level orchestrator)
Owns:
- operator interaction
- project interpretation
- prioritization
- deciding whether work is coding-heavy enough to dispatch
- deciding whether to use Codex vs another executor
- integrating results back into the larger task
- checking Crumb before acting

### Codex (coding executor)
Owns:
- bounded implementation tasks
- code edits
- refactors
- repository-local analysis
- PR / diff review
- test-driven execution when the task is concrete enough

### Crumb (cognitive harness)
Owns:
- authoritative design docs
- run logs
- project-state.yaml
- specs
- decision history
- architecture constraints
- task meaning beyond the repository

### Hermes (operational harness)
Owns:
- launching Codex
- subagent dispatch
- PTY/process handling
- handing repo/task context into Codex
- collecting outputs
- escalation and fallbacks

## Recommended Integration Modes

### Mode 1: Codex as delegated coding sub-agent

**Recommended default mode.**

Use when:
- the task is clearly code-centric
- the work can be bounded
- the repo is available
- Tess still needs to retain top-level control

Pattern:
1. Tess reads Crumb for project/design/run-log context
2. Tess frames the implementation task precisely
3. Hermes launches Codex in the repo as a specialized coding worker
4. Codex edits/tests/reviews as instructed
5. Tess evaluates the result against broader architecture/state

This keeps the separation clean:
- Codex handles code
- Tess handles system judgment

### Mode 2: Codex as explicit tool lane for code review and patching

Use when:
- a PR/diff needs review
- a refactor is mechanically clear
- a coding task is narrow and tactical

Pattern:
- Tess invokes Codex intentionally for one bounded task
- result returns to Tess for synthesis or escalation

This is especially good for:
- code review
- static analysis
- repository-scoped change proposals
- patch generation
- repetitive refactors

### Mode 3: Codex as pair-review lane, not primary implementer

Use when:
- another model/executor performs initial implementation
- Codex is used as adversarial or tool-grounded review

The project already shows signs of this pattern in review artifacts.

This is lower-risk and often high-value.

## Decision Rule: When Tess Should Call Codex

Tess should prefer Codex when the task is primarily about:
- code changes
- repository-local reasoning
- refactoring
- implementation mechanics
- tests
- diffs and review

Tess should **not** prefer Codex when the task is primarily about:
- cross-project architecture
- ambiguous product/strategy judgment
- prioritization across domains
- vault-first operational synthesis
- project-state interpretation
- operator-facing executive reasoning

That is the line.

## Dispatch Heuristics

### Send to Codex if:
- the repo is the main source of truth for the task
- the output should be code, tests, or a patch
- success can be verified by build/test/review steps
- the task can be bounded in one repo/worktree/session

### Keep with Tess if:
- the task requires reconciling spec vs run-log vs project-state
- the task is architectural before it is code
- the task needs operator tradeoff judgment
- the task spans multiple projects or domains
- the task is really about deciding *what* should be built, not building it

### Tess + Codex hybrid if:
- the task needs a spec-aware framing first
- implementation is concrete after framing
- integration back into system architecture matters

This hybrid will probably be the most common useful pattern.

## Failure Modes to Avoid

### 1. Letting Codex masquerade as the orchestrator

Bad pattern:
- Codex gets vague top-level instructions and starts making cross-system architectural calls

Why bad:
- repository competence is not the same as system orchestration competence

### 2. Dispatching before Crumb context is loaded

Bad pattern:
- launch Codex on a task before Tess reads the relevant spec / run-log / project-state

Why bad:
- Codex then optimizes against the repo only, not the actual project truth

### 3. Over-dispatching to Codex for non-coding tasks

Bad pattern:
- using Codex because the task *mentions* code

Why bad:
- many such tasks are actually architecture/routing/state questions first

### 4. Using Codex without bounded success criteria

Bad pattern:
- “Improve this area”

Better:
- “Implement X in files A/B, add tests C, verify with command D, do not change E”

Codex should be given sharp edges.

## Proposed Coding Lane Architecture

### Conceptual stack

1. **Danny** — human operator
2. **Tess** — top-level orchestrator / voice / prioritizer
3. **Hermes** — operational shell for launching tools/subagents
4. **Codex** — coding specialist lane
5. **Repository + tests** — immediate execution environment
6. **Crumb** — authoritative cross-session/project context grounding the whole flow

This is not a simple vertical ladder. It is a coordinated stack:
- Crumb grounds Tess
- Tess decides when Codex is appropriate
- Hermes runs Codex
- Codex works in the repo
- Tess synthesizes the result back into the system

## Near-Term Implementation Recommendation

### Phase 1: Formalize Codex as an allowed coding executor

Add explicit project doctrine:
- Codex is approved as a coding specialist tool/sub-agent
- not as the primary Tess orchestrator runtime

### Phase 2: Start with one narrow use case

Recommended first-class use case:
- **code review / patch review / repo-scoped implementation task**

This is the safest lane because:
- it is bounded
- success criteria are clearer
- the project already has precedent using Codex in reviews

### Phase 3: Add dispatch template

Tess should hand Codex tasks in a consistent form:
- project/repo path
- task objective
- exact constraints
- relevant Crumb files already read
- verification commands
- forbidden scope expansions

This reduces waste and keeps Codex from freewheeling.

## Recommended Codex Task Envelope

Every Codex dispatch should include:

- **Objective** — one sentence
- **Repo path** — exact
- **Relevant vault context already consulted** — spec/run-log/project-state docs
- **Files likely involved** — if known
- **Success criteria** — exact
- **Verification commands** — exact
- **Scope guardrails** — what not to touch

This keeps Codex in executor mode instead of amateur architect mode.

## Bottom Line

Codex belongs in tess-v2.
But it belongs there as a **coding specialist lane**, not as a replacement for Tess’s main orchestrator function.

The correct relation is:

- **Tess = deciding brain**
- **Codex = coding hands**
- **Crumb = world model**
- **Hermes = dispatch shell**

That is the clean architecture.

## Suggested Crumb Follow-Up

If this note is accepted, promote its substance into a canonical tess-v2 design document covering:
- approved executor lanes
- Codex’s role boundary
- dispatch criteria for coding tasks
- coding-lane success metrics
