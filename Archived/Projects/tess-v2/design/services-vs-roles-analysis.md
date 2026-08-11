---
project: tess-v2
type: design-input
domain: software
status: active
created: 2026-04-01
updated: 2026-04-01
source: claude.ai conversation 2026-03-31 (Paperclip / agents-as-roles thread)
tags:
  - architecture
  - scaling
---

# Design Input: Services vs. Roles — Architectural Framing

Analysis of a claude.ai conversation thread exploring the distinction between agents-as-services and agents-as-roles, with implications for tess-v2 scaling.

## Source Context

Conversation thread explored Paperclip (open-source multi-agent orchestration platform, github.com/paperclipai/paperclip) and how its "agents as roles in an org chart" model relates to Tess's "agents as services" model. Paperclip runs 19 agents at $2/month using heartbeat scheduling — agents sleep and wake on timers.

## Key Distinction

- **Agents as services** (current tess-v2): Defined by *what they do*. FIF scans feeds. Scout evaluates opportunities. Stateless-ish, composable, testable. Services don't need org charts.
- **Agents as roles** (Paperclip model): Defined by *who they are* in a hierarchy. CEO delegates to specialists. Each role gets different permissions, scope, authority. Work flows through reporting lines.

These are not opposed — they're different abstraction layers solving different problems:
- Services answer: **what needs to happen?**
- Roles answer: **who is responsible for deciding what needs to happen?**

## Validation of tess-v2 Architecture

The conversation independently converged on the same split tess-v2 implements:

| Thread Framing | tess-v2 Equivalent |
|---|---|
| Tess = role layer (coordinator) | Kimi K2.5 orchestrator (Tier 3, V2/V3) |
| FIF, Scout = services layer | Nemotron executor (Tier 1, V1) |
| Contract between role and services | Contract schema §8, dispatch envelope §10 |
| Routing-by-verifiability | AD-010 |

Tess is already converging on role behavior: Mentat-Bard personality, morning briefing synthesis, Cardinal Rules. The tess-v2 contract architecture formalizes the boundary between role (orchestration/judgment) and services (execution/verification).

## Scaling Trigger: When to Add Sub-Orchestrators

The conversation identifies three triggers for needing a second role (sub-orchestrator):

1. **Domain depth exceeds summarization.** When "check on project X" becomes a 30-minute context load before the orchestrator can say anything useful. The domain needs its own role that holds deep context and reports to Tess in compressed form.

2. **Concurrent workstreams need independent judgment.** When multiple opportunities require parallel research/evaluation and serializing through Tess is a bottleneck. Temporary parallel roles, not permanent.

3. **Context window becomes the bottleneck.** TV2-023's token budgets (16K local, 32K cloud) are the concrete constraint. When a domain's operational context exceeds a single dispatch envelope, that domain earns its own orchestrator.

## Firekeeper Books as First Candidate

At production scale, Firekeeper Books maps to six functional areas (editorial, design/production, metadata, distribution, marketing, finance) — each requiring different expertise, cadence, and judgment criteria. Architecture at that point:

```
Danny (human)
  └── Tess (orchestrator)
        ├── Firekeeper GM (sub-orchestrator)
        │     ├── Editorial Agent (service)
        │     ├── Design Agent (service)
        │     ├── Metadata Agent (service)
        │     └── ...
        ├── FIF (service)
        ├── Scout (service)
        └── [future ventures...]
```

The Firekeeper GM is the key addition — a sub-orchestrator with domain-specific routing table and deep context, reporting to Tess in compressed executive summaries.

## Architectural Implications

**No current design changes needed.** The state machine already supports hierarchical dispatch — a sub-orchestrator is an executor that can itself dispatch contracts. The escalation gates, contract schema, and routing table all work recursively.

**When to revisit:** When Danny reports spending more time coordinating between service outputs than making strategic decisions. That's the "coordination cost exceeds bandwidth" signal.

**Paperclip patterns worth tracking:**
- Heartbeat scheduling (validates tess-v2 scheduled pipelines over daemon mode)
- Task checkout atomicity (maps to contract immutability + staging)
- Goal ancestry (maps to Liberation Directive → spec → contract derivation chain)
- Budget enforcement per agent (maps to token/cost budgets per dispatch)

## Related Design Inputs

- **Amendment Z** (`design/spec-amendment-Z-interactive-dispatch.md`): Formalizes the hierarchy this analysis describes. The Danny → Tess → executors chain becomes mechanical via dispatch queue + session reports. Z establishes orchestrator authority over interactive sessions — the prerequisite for sub-orchestrators, which extend the same pattern one level down.
- **External systems evaluation** (`design/external-systems-evaluation-2026-04-04.md`): 10 additional systems evaluated, all converge on the same "separate strategy from execution" pattern. Pedro's Autopilot is the closest analog to the role layer described here.
- **Pedro autopilot extraction** (`design/pedro-autopilot-extraction-2026-04-04.md`): Pedro's "People + Programs" declarative filters map to the role layer's context scoping. His virtual employee pattern (Pattern 5) is the sub-orchestrator endpoint.

## Application Sequence

- **Now:** Amendment Z (dispatch queue, session reports, startup hook) formalizes the orchestrator authority this analysis assumes. Z is the prerequisite.
- **Phase 4 (migration):** Monitor coordination overhead as services migrate. TV2-045 (Paperclip integration spike) evaluates sub-orchestrator pattern when triggered.
- **Post-migration:** If Firekeeper Books reaches production, evaluate sub-orchestrator pattern per the three triggers identified above.
