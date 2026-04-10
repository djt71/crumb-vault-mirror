---
project: opportunity-scout
domain: software
type: design-artifact
status: draft
created: 2026-03-18
updated: 2026-03-18
tags:
  - architecture
  - multi-agent
  - opportunity-detection
topics:
  - moc-crumb-architecture
---

# Design Sketch: Multi-Agent Opportunity Evaluation ("Gossip Loop")

**Purpose:** Input document for a future SPECIFY phase. Not a specification — a structured concept sketch with enough detail for systems-analyst to interrogate, estimate, and decompose. This capability would extend Opportunity Scout beyond single-pass digest ranking into multi-perspective deliberative evaluation with cross-candidate synthesis.

**Gating prerequisite:** M2 behavioral validation must PASS before this work is justified. If Danny isn't engaging with the current single-pass digests (bookmark/research rate <20% after 30 days), adding evaluation depth won't fix the problem. This sketch should be revisited only after the M2 gate decision on 2026-04-15.

**Origin:** Conversation evaluating Hyperspace/Prometheus (github.com/hyperspaceai/agi) architecture — Research DAGs, biological memory, persistent cognitive engines. The multi-agent "gossip" concept was identified as a natural evolution of Scout's existing architecture, using patterns Danny has already built (overlay system, A2A compound insight routing, multi-model peer review).

---

## 1. Problem Statement

Scout's current pipeline produces a single-pass evaluation: Haiku triage scores three gates (Conflict, Automation, Fit), then Sonnet ranks qualifying candidates and generates a digest with per-item insights and a synthesis header. This produces a usable daily signal, but the evaluation is shallow — one model's perspective, one pass, no structured disagreement or cross-candidate pattern recognition.

The missed opportunity: Danny has four overlay personas (Business Advisor, Career Coach, Financial Advisor, Design Advisor) that encode distinct evaluative lenses. These overlays currently activate only during interactive Crumb sessions. They don't participate in Scout's automated evaluation, which means the digest lacks the multi-perspective deliberation that Danny would naturally perform if he were evaluating opportunities manually — weighing PIIA risk against market opportunity, creative alignment against financial return, time investment against career trajectory.

Additionally, Scout evaluates each candidate independently. Cross-candidate patterns ("three separate candidates this week all involve AI-assisted educational content — is that a market signal or a bubble?") are invisible to the per-item pipeline. The synthesis header attempts this but operates on a single day's candidates with no memory of prior digests.

## 2. Proposed Capability: Multi-Agent Evaluation Round

### 2.1 Concept

After Haiku triage and before Sonnet digest assembly, qualifying candidates enter a multi-agent evaluation round. Each evaluator agent operates from a distinct overlay perspective, writes a structured assessment to the candidate record, and can read prior assessments from other evaluators. A synthesis agent then reads across all assessments on all active candidates to produce cross-candidate insights.

This is NOT a swarm optimization (Hyperspace model). It is structured deliberation — agents with rich context about Danny's specific situation, engaging in written critique and response on a shared artifact (the candidate record). The goal is intellectual rigor, not evolutionary fitness.

### 2.2 Evaluator Agents

Four evaluator roles, each mapped to an existing overlay:

| Role | Overlay Source | Evaluates | Key Questions |
|------|---------------|-----------|---------------|
| Business Advisor | `_system/docs/overlays/business-advisor.md` | Market viability, revenue model, competitive landscape, scaling trajectory | Is this a real market? What's the revenue model? Who's the competition? What does $10K/mo look like here? |
| Career Coach | `_system/docs/overlays/career-coach.md` | PIIA risk, career trajectory alignment, opportunity cost, skill development | Does this conflict with Infoblox? Does it build durable career capital? What's the opportunity cost against current priorities? |
| Financial Advisor | `_system/docs/overlays/financial-advisor.md` | Startup cost, time-to-revenue, risk-adjusted expected value, cash flow profile | What does it cost to start? When does it pay back? What's the downside scenario? |
| Design Advisor | `_system/docs/overlays/design-advisor.md` | Aesthetic alignment, creative satisfaction, brand coherence with Hearthlight identity | Would Danny be proud to put his name on this? Does it fit the scholarly warmth aesthetic? Is it "vibe coded slop" or craftsmanship? |

Each evaluator produces a structured assessment:

```yaml
evaluator: business-advisor
candidate_id: <uuid>
assessment_date: <iso8601>
model_used: <model-id>
verdict: promising | neutral | cautionary | reject
confidence: <0.0-1.0>
key_finding: <1-2 sentence summary>
reasoning: <structured analysis, 200-400 words>
dissent: <null | response to another evaluator's assessment>
flags: <list of specific concerns or opportunities>
```

### 2.3 Deliberation Protocol

The evaluation round runs in two passes:

**Pass 1 — Independent assessment.** All four evaluators score the candidate independently (can run in parallel). No evaluator sees another's output. This prevents anchoring bias.

**Pass 2 — Dissent and response.** Each evaluator reads the other three assessments. If any evaluator disagrees with another's verdict or identifies a missed consideration, it writes a dissent entry. This is where the "gossip" happens — Career Coach might read Business Advisor's "strong market" assessment and respond: "Agreed on market, but execution timeline conflicts with Q2 customer-intel commitments at Infoblox. Recommend park until Q3."

Pass 2 is optional and cost-gated. It only runs if Pass 1 produces a split verdict (e.g., 2 promising + 1 cautionary + 1 neutral). Unanimous assessments skip Pass 2.

### 2.4 Synthesis Agent

After evaluation rounds complete (across all candidates in the batch), a synthesis agent reads all assessments and produces:

**Cross-candidate patterns.** "Three candidates this week involve AI-assisted educational content. Business Advisor rated all three 'promising.' This is either a genuine market signal worth investigating or a bubble in the feed sources. Recommend: one research dispatch on the AI education market to disambiguate."

**Convergent opportunities.** "Career Coach flagged that Danny's batch-book-pipeline expertise creates an unfair advantage for educational content. Financial Advisor separately noted that digital product margins exceed 80% in education. Design Advisor confirmed the scholarly warmth aesthetic fits educational content naturally. Convergence: educational content is the intersection of all four lenses."

**Contradiction surfacing.** "Business Advisor rates the 'DNS Hygiene Toolkit' as promising (strong market, clear pain point). Career Coach rates it cautionary (PIIA proximity — DNS is employer-adjacent). This contradiction requires Danny's judgment — it can't be resolved by the agents."

The synthesis output is appended to the digest (replacing or augmenting the current Sonnet synthesis header) and persisted to the candidate registry for monthly evaluation.

### 2.5 Research DAG (Future — Not In Scope for Initial Build)

Over time, the synthesis outputs accumulate into a knowledge graph of opportunity patterns:

- **Observation nodes:** Individual evaluator assessments
- **Experiment nodes:** Candidates that Danny actively researched or pursued
- **Synthesis nodes:** Cross-candidate patterns identified by the synthesis agent
- **Lineage chains:** How one insight led to another across evaluation cycles

This is the Hyperspace Research DAG concept applied to opportunity evaluation. It is explicitly deferred — the initial build produces flat synthesis outputs. The graph structure is a future evolution if the flat synthesis proves valuable.

## 3. Integration with Existing Architecture

### 3.1 Pipeline Position

```
Current:  Sources → Haiku Triage → Sonnet Digest → Telegram/Discord
Proposed: Sources → Haiku Triage → [Multi-Agent Eval] → Sonnet Digest → Telegram/Discord
                                         ↓
                                  [Synthesis Agent]
                                         ↓
                                  Digest enrichment
```

The multi-agent evaluation round inserts between triage and digest assembly. The Sonnet digest ranking step now has richer input — not just raw gate scores, but structured assessments from four perspectives.

### 3.2 Infrastructure Reuse

| Component | Exists? | Reuse Pattern |
|-----------|---------|---------------|
| Candidate registry (SQLite) | Yes (OSC-008) | Add `assessments` JSON column or separate assessments table |
| Overlay documents | Yes (4 overlays in `_system/docs/overlays/`) | Load as evaluator system prompts |
| Multi-model dispatch | Yes (peer-review skill, A2A dispatch) | Same pattern — parallel dispatch, collect results |
| Assessment persistence | No | New: structured YAML/JSON per evaluator per candidate |
| Synthesis agent | No | New: reads across assessments, produces cross-candidate output |
| Digest integration | Partial | Extend existing digest assembly to incorporate assessment data |
| LaunchAgent scheduling | Yes (OSC-013) | Evaluation round can run as part of existing daily pipeline or on separate schedule |

### 3.3 A2A Compound Insight Routing

The synthesis agent's cross-candidate patterns are compound insights in the A2A sense. They should flow through the existing compound insight routing infrastructure (A2A M1-M2, operational). This means synthesis outputs can trigger research dispatches, update the calibration seed, or surface in the morning briefing — all via existing pathways.

## 4. Cost Model

### 4.1 Per-Candidate Cost

Assuming 5-10 qualifying candidates per evaluation batch:

| Component | Model | Calls per Candidate | Est. Cost per Call | Per-Candidate |
|-----------|-------|--------------------|--------------------|---------------|
| Pass 1 (4 evaluators) | Haiku | 4 | ~$0.005 | $0.02 |
| Pass 1 (4 evaluators) | Sonnet | 4 | ~$0.03 | $0.12 |
| Pass 2 (dissent, conditional) | Sonnet | 0-4 | ~$0.03 | $0.00-0.12 |
| Synthesis (per batch) | Sonnet | 1 | ~$0.05 | $0.005-0.01 |

**Haiku evaluators:** ~$0.02/candidate, ~$0.10-0.20/batch. Very cheap. Quality is the question.

**Sonnet evaluators:** ~$0.12-0.24/candidate, ~$0.60-2.40/batch. Reasonable, especially during 2x promo.

**Opus evaluators (ceiling):** ~$0.50-1.00/candidate, ~$2.50-10.00/batch. Too expensive for daily automated runs. Reserve for monthly evaluation or on-demand deep dives.

**Recommended starting configuration:** Haiku for Pass 1, Sonnet for Pass 2 (dissent only on split verdicts), Sonnet for synthesis. Estimated daily cost: $0.15-0.50 depending on candidate volume. Well within the $10/mo ceiling even without the promo.

### 4.2 Tiered Evaluation Strategy

Not all candidates deserve four-evaluator deliberation. Tier the depth:

| Candidate Signal | Evaluation Depth | Cost |
|------------------|------------------|------|
| All three gates H | Full 4-evaluator round + synthesis | $0.12-0.24 |
| Mixed gates (H/M) | 2-evaluator spot check (Business + Career only) | $0.06-0.12 |
| Marginal (M/M/M) | Skip multi-agent eval, use existing single-pass | $0.00 |
| Danny bookmarked/researched | Full round + Opus synthesis | $0.50-1.00 |

This keeps the median daily cost under $0.30 while concentrating evaluation depth on the candidates most likely to matter.

## 5. Model Diversity for Disagreement Quality

A known risk: four evaluator agents running on the same underlying model (Claude) will tend toward consensus. The deliberation value comes from genuine disagreement — a Business Advisor that's bullish on a market while a Career Coach flags PIIA risk.

### 5.1 Prompt-Level Differentiation (Minimum Viable)

Each evaluator's system prompt loads the full overlay document, which already encodes a distinct evaluative lens. The overlays were designed to ask different questions, weight different dimensions, and apply different judgment criteria. This provides structural differentiation even on the same model.

Additionally, each evaluator prompt should include:

- An explicit instruction to look for reasons the OTHER evaluators might be wrong
- The evaluator's "professional skepticism" — e.g., Financial Advisor is structurally conservative, Design Advisor is structurally idealistic
- A reminder that unanimous agreement is suspicious and dissent is valuable

### 5.2 Multi-Model Differentiation (Better, Higher Cost)

For higher-stakes evaluation (Danny-bookmarked candidates, monthly deep dives), assign different models to different evaluators:

| Role | Model | Rationale |
|------|-------|-----------|
| Business Advisor | Claude Opus | Strategic depth, long-context reasoning |
| Career Coach | Claude Sonnet | Good judgment, cost-effective for the most frequently relevant evaluator |
| Financial Advisor | Gemini | Different reasoning patterns, tends toward quantitative framing |
| Design Advisor | Claude Sonnet | Aesthetic judgment maps well to Claude's strengths |

This mirrors the existing peer-review skill pattern (4 models: GPT-5.2, Gemini 3 Pro, DeepSeek Reasoner, Grok 4.1 Fast). The infrastructure for multi-model dispatch exists.

### 5.3 Critic Role (From A2A-014)

A2A-014 (critic skill) is currently unblocked and can proceed in parallel with the A2A-013 gate. The critic's job is explicitly adversarial — find weaknesses, challenge assumptions, stress-test reasoning. If A2A-014 ships before this feature, the critic can be the fifth evaluator: a model-agnostic adversarial reviewer that attacks the strongest assessment. This prevents groupthink more reliably than prompt-level differentiation alone.

## 6. Biological Memory / Calibration Feedback

### 6.1 Assessment-to-Calibration Loop

Over time, assessment data feeds back into the scoring model:

- If Business Advisor consistently rates publishing-adjacent opportunities "promising" and Danny consistently bookmarks them → strengthen publishing signals in triage prompt
- If Career Coach flags PIIA risk and Danny consistently overrides with "I've checked, it's fine" → note the override pattern, don't automatically suppress Career Coach's flags but annotate them
- If Financial Advisor's cost estimates are consistently too conservative (Danny finds cheaper execution paths) → adjust Financial Advisor's cost assumptions

This is the Hyperspace "biological memory" concept applied at the evaluator level: strengthen patterns that predict Danny's behavior, decay patterns that don't. The mechanism is simple — a rolling log of (assessment, verdict, Danny's actual action, outcome) tuples that the synthesis agent reads monthly to propose calibration updates.

### 6.2 Graveyard Enrichment

When all four evaluators agree a candidate should be rejected AND Danny confirms (via !reject feedback), the rejection pattern should flow into the graveyard as a structured entry with multi-evaluator reasoning. This produces richer graveyard entries than the current single-reason format.

## 7. Open Questions (For SPECIFY Phase)

1. **Evaluation frequency.** Daily (every pipeline run)? Every few days? On-demand only? Daily is simplest but may produce evaluations for candidates Danny never looks at. A trigger-based model (evaluate when a new candidate scores all-H gates, or when Danny bookmarks something) might be more ceremony-budget-appropriate.

2. **Assessment storage.** New SQLite table (normalized, queryable) vs. JSON column on candidates table (simpler, less queryable) vs. vault markdown files (human-readable, less structured)? The monthly synthesis needs to query across assessments efficiently.

3. **Digest format impact.** How do multi-agent assessments change what Danny sees in Telegram? Full assessments are too long. Options: (a) verdict-only summary line per evaluator, (b) synthesis paragraph only, (c) flag only when evaluators disagree, (d) full assessments available on-demand via feedback command (e.g., `!detail 3`).

4. **Pass 2 trigger threshold.** "Split verdict" is the proposed trigger for the dissent pass. But what counts as a split? Any non-unanimous result? Or only when verdicts span promising-to-cautionary (ignoring neutral)? The threshold affects cost and signal quality.

5. **Synthesis persistence and retrieval.** Where do cross-candidate synthesis outputs live? Vault markdown files (human-readable, searchable)? SQLite (queryable for monthly evaluation)? Both? If both, what's the source of truth?

6. **Interaction with M3 monthly evaluation.** OSC-019 (monthly evaluation memo) is already specced. Multi-agent evaluation data would make the monthly memo dramatically richer. But OSC-019 is currently designed for single-pass data. Does the monthly memo need a redesign, or can it consume multi-agent data through the existing aggregation queries?

7. **Relationship to the Hearthlight Editions Execute Mode (OSC-020).** OSC-020 defines a four-metric schema for active stream monitoring. Multi-agent evaluation is the analysis layer; Execute Mode is the execution layer. How do they connect? Does a "promising" verdict from all four evaluators trigger an automatic transition to Execute Mode research, or does Danny always make that call?

## 8. Milestone Placement

This capability fits as **M4 or M5** in the Opportunity Scout project, depending on how the SPECIFY phase scopes it:

- **Minimum viable (M4):** 4 evaluators (Haiku), Pass 1 only (no dissent), flat synthesis output appended to digest. Reuses overlay documents as-is. No new SQLite tables — assessments stored as JSON on candidate record. ~3-5 implementation tasks.

- **Full capability (M5):** 4 evaluators (Sonnet) + critic, Pass 1 + Pass 2 (dissent on split), structured assessment table, synthesis with cross-candidate patterns, calibration feedback loop, integration with monthly evaluation. ~8-12 implementation tasks.

- **Research DAG (M6+):** Graph-structured synthesis with lineage chains, persistent cross-cycle memory, automated calibration updates. Deferred until flat synthesis proves its value.

**Dependencies:**
- M2 PASS (hard gate — do not build if Danny isn't engaging with digests)
- A2A-014 (critic skill) — soft dependency, enhances but not required
- OSC-019 (monthly evaluation) — should inform digest format decisions

---

## 9. References

- Hyperspace/Prometheus architecture: signal note `varun-mathur-hyperspace-prometheus-cognitive-engine.md`
- Opportunity Scout spec: `Projects/opportunity-scout/design/specification.md`
- Calibration seed: `Projects/opportunity-scout/design/calibration-seed.md`
- A2A spec: `Projects/agent-to-agent-communication/design/specification.md`
- Overlay documents: `_system/docs/overlays/{business-advisor,career-coach,financial-advisor,design-advisor}.md`
- Peer-review skill (multi-model dispatch pattern): `.claude/skills/peer-review/SKILL.md`
