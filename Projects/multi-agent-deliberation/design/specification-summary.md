---
project: multi-agent-deliberation
type: summary
domain: software
skill_origin: systems-analyst
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

# Multi-Agent Deliberation — Specification Summary

## Problem

Single-model evaluation produces blind spots. Overlays add domain lenses but the underlying reasoning is one model's. Multi-agent deliberation uses structurally different LLMs evaluating the same artifact through domain-specific lenses, with a protocol for surfacing disagreement and extracting cross-artifact patterns. The value proposition: novel insights Danny wouldn't find on his own or by asking a single LLM.

## Key Design Decisions

- **AD-1:** Multi-model, not same-model — each evaluator runs on a different LLM (GPT-5.4, Gemini 3.1 Pro, DeepSeek V3.2, Grok 4.1 Fast) for reasoning diversity
- **AD-2:** Standalone experimental project — no integration into Scout, FIF, or any Crumb system until hypotheses validated
- **AD-3:** Reuses peer-review-dispatch pattern (safety gate, concurrent dispatch, response collection) with deliberation-specific prompt assembly
- **AD-4:** Standard depth during experiments; Phase 2 forces Pass 2 on all deliberations regardless of split (for H3 data collection)
- **AD-5:** Synthesis runs in main Opus session (cross-artifact reasoning requires judgment, not mechanical dispatch)
- **AD-6:** Four evaluator roles for initial panel: Business Advisor (GPT), Career Coach (Gemini), Financial Advisor (DeepSeek), Life Coach (Grok)
- **AD-7:** (peer review) Two-tier baseline: primary = 4 GPT-5.4 calls with separate overlays (fair null for H5); secondary = single-Opus combined prompt
- **AD-8:** (peer review) Inter-agent injection resistance for Pass 2 — wraps Pass 1 outputs as data before feeding to dissent evaluators
- **AD-9:** (peer review) Structured evaluation rubric (0-2 per-finding scale) + finding extraction protocol + blinding protocol (evaluator IDs stripped during rating) + "10-minute think" gut check for reproducible gate decisions
- **AD-10:** (peer review) Minimum viable panel = 3/4 evaluators; incomplete deliberations excluded from hypothesis data
- **AD-11:** (peer review) Verdict scale variants per artifact type (opportunity, signal-note, architectural-decision) with invariant 0-4 numeric mapping
- **AD-12:** (external synthesis) Automated finding extraction via structured `findings` array in schema — eliminates manual extraction labor
- **AD-13:** (external synthesis) F5 reclassified as A6 — model-specific tendencies are hypotheses to stress-test, not architectural constraints
- **AD-14:** (external synthesis) Gate override requires documented anomaly rationale — "felt close enough" is not valid
- **AD-15:** (external synthesis) Post-validation injection principle: Pass 2 receives only schema-extracted structured fields, not free-form reasoning
- **AD-16:** (external synthesis) Phase 1 is Pass-1-only; split-check activates in Phase 2 (MAD-008)
- **AD-17:** (external synthesis) Rating procedure with calibration anchor set for drift detection across phases

## Hypotheses (Experimental Gates)

| # | Hypothesis | Phase | Success Criteria |
|---|---|---|---|
| H1 | Model diversity produces meaningful verdict variance | 1 | Verdicts span ≥2 points for ≥40% of artifacts |
| H2 | Initial panel config richer than single-axis diversity | 1 | Full panel produces more unique findings than single-axis diversity; ≥50% of unique findings rated ≥1 |
| H3 | Structured dissent adds information | 2 | ≥30% of deliberations produce novel Pass 2 findings |
| H4 | Cross-artifact synthesis reveals non-obvious patterns | 3 | ≥2 actionable patterns per batch Danny confirms as novel |
| H5 | Framework produces genuinely novel insights | 4 | ≥5 novel insights total, ≥2 leading to actions |

Each phase gates on its hypotheses — failure redirects or stops the project.

## Cost

Experimental budget: $18-40 total across 33-50 deliberation runs. Per-deliberation: ~$0.50-0.90 at standard depth. Phase 0 (single-Opus baseline) runs first to establish the bar before building infrastructure.

## Task Count

20 tasks (MAD-000 through MAD-016 plus MAD-001a, MAD-004a, MAD-012a) across 5 milestones. M0 (baseline): 2. M1 (infrastructure + H1/H2): 8. M2 (dissent + H3 + cold artifact prep): 5. M3 (synthesis + H4): 3. M4 (meta-evaluation): 2.

## Abort Criteria

- Cost >$2.00/deliberation at standard depth
- <20% of assessments rated "useful" after 10 deliberations
- >80% of findings duplicate single-Opus-session output
- Cumulative rating time >3 hours per phase (attention budget)

## Agent Communication Architecture

The deliberation framework is a testbed for agent-to-agent communication. The dissent protocol is agents reading and responding to each other's work — the simplest form of direct A2A communication. The spec defines a communication pattern spectrum (relay → shared artifact → message bus → direct peer-to-peer) with the experiment using relay and the architecture designed to evolve toward more direct patterns post-validation.

Key principles: stable assessment schema as message contract (transport-independent), governance embedded in protocol (round caps, cost envelopes, audit trail), and execution environment open to cloud providers for batch/unattended deliberations. Multi-round deliberation (>2 passes) is a future direction enabled by the schema design but not in experimental scope.

If validated, deliberation becomes an A2A capability (`evaluation.deliberation.standard`) that any workflow can invoke.

## Open Questions

All open questions resolved. OQ-1: separate agents. OQ-2: GPT-5.4 as baseline. OQ-3: structured YAML in deliberation record. OQ-4: deferred to post-validation.

## Review Status

- **Round 1:** Peer reviewed by 4 models (2026-03-18). 14 action items applied: 6 must-fix, 8 should-fix, 6 deferred, 10 considered and declined.
- **Round 2:** External feedback (10 items) applied: baseline-first reordering, blinding protocol, section ordering fix, model version policy, budget corrections, prompt size limits, injection resistance limitation note, OQ-1 closure, sensitivity gate in execution flow, H2 rubric mapping.
- **Round 3:** External synthesis (5 reviewers, 5 consensus + 11 high-confidence findings) applied: automated finding extraction (CF-1), two-tier baseline fairness (CF-2), F5→A6 reclassification (CF-3), gate override semantics (CF-4), structured-fields-only injection principle (CF-5), rating procedure with calibration anchor (HF-1/HF-6/HF-7), version tracking in records (HF-2), deliberation outcome generation (HF-3), narrowed H2 claim (HF-4), Phase 1 Pass-1-only clarification (HF-5), H1 qualitative annotation (HF-8), truncation tagging (HF-9), per-model context limits (HF-10), "would I use this weekly?" H5 checkpoint (HF-11).
