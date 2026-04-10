---
project: mission-control
type: review
review_type: action-plan-review-synthesis
domain: software
status: active
created: 2026-03-07
updated: 2026-03-07
tags:
  - peer-review
  - dashboard
  - action-plan
---

# Mission Control — Action Plan Review Synthesis

**Reviewers:** Claude Opus 4.6 (meta-reviewer), DeepSeek V3.2, Gemini 3, ChatGPT GPT-5.2, Perplexity
**Scope:** Action plan, tasks (52 tasks across Phases 0-3), 9 PLAN-phase constraint resolutions

**Overall verdict:** Conditional go. The plan is sound — milestones are coherent, dependencies are clean, the PC resolutions make concrete decisions instead of deferring, and the progressive aggregator build (PC-1) correctly mitigates the riskiest component. The findings below are refinements, not structural problems.

**All 18 amendments applied.** 2 declined (D1, D2). Task count 52 → 57.

**Additional dispatch review** (GPT-5.2, Gemini 3, DeepSeek, Grok): 6 net-new findings applied (DR-A1 through DR-A6). Task count 57 → 59. See `reviews/2026-03-07-action-plan-tasks.md` for full synthesis.

## Applied Amendments

| # | Amendment | Source | Applied To |
|---|-----------|--------|------------|
| AP-1 | UUID v4 for attention_id | DeepSeek, Gemini, Claude | spec §7.1, MC-031, action-plan conventions |
| AP-2 | Parity gate: concrete pass criteria (3 days, 400ms) | Claude, DeepSeek, Perplexity | MC-028, M3 description |
| AP-3 | 6 missing tasks added | ChatGPT, Claude | MC-053–057, MC-010 (panel matrix) |
| AP-4 | Aggregator reads _inbox/attention/ | DeepSeek, Claude | MC-030 |
| AP-5 | Centralize stale thresholds | Perplexity, ChatGPT | MC-018, action-plan conventions |
| AP-6 | Adapter error roll-up rule | Perplexity, Claude | MC-017, MC-018, action-plan conventions |
| AP-7 | Inbox-processor coordination | Perplexity, Claude | MC-030 (test), action-plan conventions |
| AP-8 | PATCH 409 Conflict + .tmp cleanup | ChatGPT, Gemini | MC-044, MC-018, action-plan conventions |
| AP-9 | CSS variable palette toggle | Gemini | MC-002, M0a description |
| AP-10 | Build order honesty | ChatGPT | Dependency graph note |
| AP-11 | Gate requires 3 named pages | ChatGPT | MC-010, gate checklist |
| AP-12 | Quick-add domain defaults | Perplexity | MC-032 |
| AP-13 | Stale sources → POST /attention | DeepSeek, ChatGPT, Perplexity | MC-042 |
| AP-14 | Retro includes "pause" option | Perplexity, ChatGPT | MC-035 |
| AP-15 | Agent Activity scope narrowed | ChatGPT | M9 description |
| AP-16 | System-stats JSON schema | Perplexity | MC-016 |
| AP-17 | Split MC-009 | Claude | MC-009 + MC-055 |
| AP-18 | E2E test budget guardrail | Perplexity | PC-7 |

## Declined

| # | Proposal | Reason |
|---|----------|--------|
| D1 | Move M4 ahead of M3 | Technical progression correct (adapter pattern → FIF → aggregator). AP-10 addresses product ordering honesty. |
| D2 | Resolve whether monorepo adds value | Already in spec. Revisit if M1 proves burdensome, not preemptively. |

## Late-Session Operator Additions

These emerged from the design mockup review and operator discussion after the formal peer review round.

### AP-19. LLM health status section on Ops page

**Source:** Operator direction

The system depends on API availability from multiple providers (Anthropic, Mistral, local qwen3-coder). An LLM outage is operationally equivalent to a service going down, but currently only discoverable via Twitter or by noticing degraded agent behavior.

**Amendment:** Add an "LLM Status" section to the Ops page. One card per provider/model showing: success rate (rolling 1h), p95 latency, call count today, and degradation timestamp when applicable. Data source: ops metrics harness + dispatch telemetry (already exist). Green/amber/red derived from empirical health, not provider status pages. Future enrichment: show provider status page state alongside empirical health.

**Task impact:** Add `llm-health.ts` adapter to M2 scope. One additional section on Ops page frontend (MC-021/MC-022). Small scope increase — the data sources already exist.

### AP-20. Vault Gardening section on Knowledge page

**Source:** Operator direction

The current Knowledge page spec shows vault health KPIs and AKM surfacing stats, but doesn't provide proactive quality management tooling. The operator wants to see *what to prune* and *why*, not just aggregate health numbers.

**Amendment:** Add a "Vault Gardening" section to §6.6 (Knowledge page) with these panels:

- **Dead knowledge** — sources in QMD that have never been surfaced across N sessions. Shows the actual list with titles, not just a count. Each item has an "archive" action link that creates an attention item.
- **Orphan detection** — notes with no inbound wikilinks, no MOC reference, and no tags. Structurally disconnected from the vault graph.
- **Stale source candidates** — time-sensitive content (articles, market analysis, product comparisons) not referenced in 6+ months. These degrade QMD search quality by returning confidently outdated information.
- **Tag hygiene** — tags on only 1-2 notes (likely typos), tags with no MOC parent, tag distribution skew.
- **QMD collection health** — distribution stats beyond doc/chunk counts: collection growth rates, average chunk density per source, sources with abnormally large/small chunks (parsing issues).

Each finding produces either an attention item or a direct action link — the "review stale sources" pattern generalized to all gardening findings.

**Phasing:** Dead knowledge and orphan detection are Phase 2 scope (Knowledge page adapters). Stale source detection and tag hygiene are derivable from existing data (vault-check, filesystem scan). Semantic duplicate detection (high cosine similarity across chunks from different sources) is Phase 3+ enrichment — computationally heavier, runs as periodic batch job.

**Task impact:** Expand MC-040 (Knowledge adapters) to include gardening analysis. Add panels to MC-042 (Knowledge page frontend). The data sources are the same — QMD, vault-check, AKM feedback, filesystem — so no new adapters, just richer analysis on top of existing data.

### AP-21. Minimum text size floor: 13px

**Source:** Operator direction after mobile viewport review

Small monospace data values and metadata labels (service card fields, timestamps) lose contrast on dark backgrounds. The operator confirmed readability improves with a bump.

**Amendment:** Add to design system conventions: "Minimum text size across all contexts is 13px. No text in the dashboard renders smaller than this, regardless of viewport." Add to CONVENTIONS.md. Enforce during Phase 0 mockup finalization.

---

| AP-19 | LLM health status on Ops page | Operator | New section |
| AP-20 | Vault Gardening section on Knowledge page | Operator | Feature expansion |
| AP-21 | 13px minimum text size | Operator | Design constraint |

**Total: 21 amendments (4 high-confidence, 4 medium-confidence, 10 single-reviewer worth adopting, 3 operator additions, 2 declined).**
