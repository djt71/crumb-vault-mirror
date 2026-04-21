---
project: tess-v2
domain: software
type: note
skill_origin: inbox-processor
created: 2026-04-20
updated: 2026-04-20
tags:
  - architecture
  - reconciliation
  - hierarchy
  - runtime-drift
---

# Tess-v2: Current Live Hierarchy vs Documented Hierarchy

## Purpose

Reconcile the **documented architecture** in `Projects/tess-v2/design/` with the **current live runtime description** stated by Danny on 2026-04-20.

This note exists because the project docs still primarily describe a **Kimi-centered cloud orchestrator** architecture, while the current live runtime appears to have shifted to **GPT-5.4 as the active Tess/orchestrator model**.

## Executive Summary

The **shape** of the hierarchy is still valid, but the **documented model assignment** is stale.

Current practical hierarchy appears to be:

1. **Danny** — human operator / final authority
2. **Tess** — main agent voice + orchestrator role
3. **GPT-5.4** — current orchestration/runtime model in Hermes
4. **Nemotron (local)** — local execution layer
5. **Services / contracts / tools** — operational substrate beneath the local model and Hermes tool plane

The **design docs**, however, still mostly encode:

1. Danny
2. Tess / orchestrator role
3. **Kimi K2.5** — cloud orchestration model
4. **Nemotron** — local executor

So the hierarchy is broadly consistent, but the **current live model assignment has drifted from the written architecture**.

## Evidence: Documented Hierarchy

### 1. `design/hermes-go-decision.md`

Key statements:
- **AD-005** — "Two-tier architecture: cloud orchestrator + local executor"
- **AD-008** — "Kimi K2.5 is the cloud orchestration model"
- **AD-012** — "Nemotron Cascade 2 approved as local executor"

Implication:
- The documented model stack is still **Kimi → Nemotron**.

### 2. `design/external-systems-evaluation-2026-04-04.md`

Feature mapping table states:
- "Kimi K2.5 (orchestrator) + Nemotron (executor)"

Implication:
- Confirms the same role split: cloud judgment/orchestration above local execution.

### 3. `design/services-vs-roles-analysis.md`

Key statements:
- Danny (human)
- Tess (orchestrator)
- services layer beneath
- explicit mapping: "Kimi K2.5 orchestrator" and "Nemotron executor"

Implication:
- The human → orchestrator → executor hierarchy is clearly present.
- But the orchestrator model assignment is still the older Kimi-centered version.

## Evidence: Current Live Runtime

### 1. Danny’s direct runtime description (2026-04-20)

Danny described the current active stack as:
- Danny at top as operator
- Tess as agent voice and orchestrator
- GPT-5.4 now serving that role
- Nemotron local beneath that

### 2. Hermes live status observed in session

Observed runtime status:
- **Model:** gpt-5.4
- **Provider:** OpenAI Codex

Implication:
- The live Hermes orchestration runtime appears to be **GPT-5.4**, not Kimi.

## Reconciled Model

To avoid confusion, the architecture should probably be expressed as **two overlapping views**:

### A. Role hierarchy (stable)

1. Danny — operator
2. Tess — orchestrator / agent persona / decision layer
3. Execution substrate — local model + tools + contracts + services

This remains valid.

### B. Runtime model hierarchy (current live)

1. Danny — human operator
2. Tess — orchestrator role
3. **GPT-5.4 (Hermes / Codex)** — active orchestration model
4. **Nemotron** — local executor model
5. Services/contracts/tools — execution substrate

This is the currently described live stack.

## Why This Matters

This is not cosmetic drift.

The distinction affects:
- evaluation interpretation
- model-selection discussions
- architecture docs that still assume Kimi is live
- future routing design (especially if Sonnet/Codex/GPT-5.4/Nemotron are all considered separately)
- whether the project is still best described as a simple "cloud orchestrator + local executor" pair or a more explicit multi-level hierarchy

## Suggested Documentation Update

### Option 1: Minimal correction

Update existing docs to say:
- the **role architecture** remains cloud orchestrator + local executor
- the **currently active orchestration model** is GPT-5.4
- Kimi remains an evaluated/documented cloud candidate rather than the active live runtime

### Option 2: Better correction

Add a short architecture note defining **two separate layers**:

- **Role layer:** Danny → Tess → executors/services
- **Model/runtime layer:** GPT-5.4 → Nemotron → contracts/tools/services

This is cleaner and better matches how the system is now being reasoned about.

## Recommended Next Step

Update the canonical tess-v2 architecture docs so they distinguish:

1. **Who decides** (Danny / Tess)
2. **What model currently powers Tess** (GPT-5.4, if that is indeed the intended live default)
3. **What model executes locally** (Nemotron)
4. **What remains merely evaluated vs. what is operationally canonical**

Without that separation, future conversations will keep mixing:
- documented architecture
- evaluated candidates
- current live runtime

And those are not the same thing.

## Proposed Crumb Action

If accepted, promote the substance of this note into one of:
- `Projects/tess-v2/design/hermes-go-decision.md` (postscript / drift note)
- a new architecture note under `Projects/tess-v2/design/`
- `project-state.yaml` next_action/state clarification

## Honest caveat

This note reflects **live session evidence + current docs**, not an implementation audit of every running service and path. It reconciles the **stated live hierarchy** against the **written design hierarchy**. If there are hidden provider-routing rules or runtime overrides that still put Kimi in a critical decision lane, that needs a separate operational verification pass.
