---
type: design-revision
project: tess-model-architecture
domain: software
status: active
created: 2026-02-22
updated: 2026-02-22
source: claude-ai-session
supersedes: tess-model-architecture-design-revision.md
tags:
  - local-llm
  - tess
  - openclaw
  - model-selection
  - tiering
  - cost-analysis
---

# Design Revision 2: Restore Cloud-Primary Architecture

**Date:** 2026-02-22
**Source:** claude.ai session — cost analysis + architecture review
**Supersedes:** Design Revision 1 (Revert Tiering Inversion)
**Affects:** Same sections as Revision 1, but restores the research thread's original direction

## Decision

Restore the personality-first tiered architecture from the research thread (§4). Cloud model is primary for all user-facing and judgment-requiring interactions. Local model handles mechanical execution. Local also serves as a resilience fallback during API outages.

Design Revision 1 (local-first revert) is withdrawn.

## Rationale

Three findings from the follow-up analysis:

### 1. The cost argument for local-first doesn't hold

Haiku 4.5 with prompt caching costs ~$8.70/month for Tess's full projected workload (135+ daily requests including heartbeats). Sonnet 4.5 would be ~$22.50/month. Local inference on the Mac Studio costs ~$6.50–10.40/month in electricity alone, before hardware depreciation. The delta is negligible. Cost does not justify accepting permanent persona degradation.

See: `tess-haiku-cost-analysis.md` for full breakdown.

### 2. The independence concern is mitigated by fallback, not by going local-first

The original concern was Anthropic API dependency for every interaction — if the API goes down, Tess goes mute. This is real but solvable: local model as an automatic fallback during outages. The Limited Mode protocol from the research thread (§7 risk register) already describes this: 3 retries on 503/timeout → switch to local with degradation banner → scope reduction → automatic revert on API recovery.

With local fallback in place, the dependency is on API *quality* (cloud produces better output), not API *availability* (Tess still functions without it). That's an acceptable dependency.

### 3. Alternative architectures collapsed back to the original

During the session, three framings were explored:
- **Audience-based split** (research thread §4): cloud for user-facing, local for mechanical
- **Function-based split** (session exploration): cloud for thinking/deciding, local for executing
- **Orchestrator/executor** (session exploration): cloud as brain, local as hands

On examination, these produce the same runtime behavior. The split point is always "what needs persona/judgment" vs "what's purely mechanical," and routing is always keyed on the same signal (human-initiated vs system-initiated, or equivalently, GPT's "two clocks" framing from R1). Reframing didn't produce a genuinely different architecture.

## What This Restores

The research thread's Status & Decisions section (§Status) is back in effect:

| Aspect | Revision 1 (withdrawn) | Revision 2 (current) |
|--------|----------------------|---------------------|
| User-facing traffic | Local model | Cloud (Haiku 4.5, provisional) |
| Mechanical/plumbing | Local model | Local (qwen3-coder:30b, conditional) |
| Research/synthesis | Cloud escalation | Cloud (Sonnet 4.5) |
| API outage behavior | N/A (local-first) | Limited Mode: local fallback + degradation banner |
| Routing requirement | Minimal (escalation only) | Route by audience / clock source — CRITICAL blocker restored |
| Model selection criterion | Balanced IF + NL quality | IF-score-first for local (mechanical only); persona fidelity for cloud |
| Small-specialists pattern | Under evaluation | Deferred (evaluate single generalist first, per Crumb's recommendation) |

## What Changes From the Original Research Thread

Despite restoring the cloud-primary architecture, this revision incorporates insights from the exploration:

### 1. Local fallback is a first-class design element, not an afterthought

The research thread treated Limited Mode as a risk mitigation in the risk register. It should be elevated to a design requirement with its own specification: trigger conditions, fallback behavior, scope reduction rules, user notification, automatic recovery. This is what makes the cloud dependency acceptable.

### 2. Cost validation is now part of the evidence base

The research thread made the tiering decision on persona quality grounds alone. The cost analysis confirms it's also economically sound — cloud-primary is not meaningfully more expensive than local-first when electricity costs are included. This strengthens the decision and should be referenced in the specification.

### 3. Haiku vs Sonnet remains an open question

The operator is comfortable with Sonnet-tier costs (~$22.50/month). The persona evaluation rubric from R2 should test both. If Sonnet carries the SOUL.md second register significantly better than Haiku, the cost difference is justified. Perplexity's R2 suggestion of a mixed Haiku/Sonnet cloud tier (routine persona on Haiku, second-register on Sonnet) remains viable.

### 4. Crumb's sequencing recommendation stands

Evaluate single generalist (qwen3-coder:30b) for the local/mechanical role first. Only explore small-specialists if it fails the mechanical contract. Don't evaluate two architectures simultaneously.

## Updated Risk Register

| Risk | Severity | Change from research thread |
|------|----------|---------------------------|
| OpenClaw can't route by task type / agent | CRITICAL | **Unchanged.** Still the blocking prerequisite. |
| Anthropic API down → Tess goes mute | HIGH → MEDIUM | **Reduced.** Local fallback with Limited Mode protocol mitigates. Severity drops because Tess degrades rather than going silent. |
| Memory contention on shared 96GB | MEDIUM | **Unchanged.** Local model (mechanical only) still needs empirical validation. |
| Haiku 4.5 can't carry SOUL.md second register | MEDIUM | **Unchanged.** Test before committing. Sonnet is the fallback cloud tier. |
| Local model persona degradation | — | **Removed.** Local model no longer needs to carry persona (mechanical only). Persona degradation only applies during Limited Mode, which is transient. |
| Thermal throttling | MEDIUM | **Unchanged.** |
| API cost exceeds budget | LOW | **New.** ~$8.70/month (Haiku) or ~$22.50/month (Sonnet) with caching. Monitor but not concerning at current projections. |

## Updated Next Steps

Priority order unchanged from research thread. Routing PoC remains step 1.

1. **Routing specification + PoC** — CRITICAL blocker. Define and test audience-based routing (human clock vs machine clock). Acceptance criteria per GPT's R2 contribution.
2. **Codify design contracts** — Mechanical (local) and Persona (cloud) as a vault reference doc.
3. **Memory budget table** — Empirical measurements for local model under defined load shape.
4. **Persona fidelity test** — Haiku vs Sonnet using existing 10+ interaction sample against R2 rubric. Include mixed-tier evaluation (Haiku routine + Sonnet second-register).
5. **Local model benchmark harness** — Mechanical contract conformance only. IF scores, tool JSON validity, latency, memory.
6. **Limited Mode specification** — Elevate from risk register entry to formal degradation spec.
7. **Draft openclaw.json config** — Tiered model architecture with local fallback.

## Revision History

| Date | Revision | Decision |
|------|----------|----------|
| 2026-02-21 | Research thread | Cloud-primary, personality-first tiering (5-model peer review, 2 rounds) |
| 2026-02-22 | Revision 1 | Revert to local-first (independence concern) |
| 2026-02-22 | Revision 2 | **Restore cloud-primary** (cost analysis shows negligible delta; independence mitigated by local fallback; alternative framings collapsed to same architecture) |

## Note on Peer Review Consensus

Revision 1 overrode the unanimous 5-reviewer consensus from R1 and R2 that personality-first tiering was the right call. Revision 2 re-aligns with that consensus. The exploration was valuable — it stress-tested the decision from a different angle and produced the cost analysis and Limited Mode elevation as durable contributions — but the original architecture was sound.
