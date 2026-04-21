---
project: multi-agent-deliberation
domain: software
type: design-artifact
status: draft
created: 2026-03-18
updated: 2026-03-18
tags:
  - architecture
  - multi-agent
  - system-capability
topics:
  - moc-crumb-architecture
---

# Design Sketch: Multi-Lens Deliberation Framework

**Purpose:** Input document for a future standalone project SPECIFY phase. Defines a reusable system capability — multi-perspective evaluation with structured dissent and cross-artifact synthesis — that multiple Crumb projects can consume. This is infrastructure, not a feature of any single project.

**Architectural precedent:** The research-brief schema (`_system/schemas/briefs/research-brief.yaml`) defines a shared contract consumed by multiple capabilities. This framework follows the same pattern: define the deliberation protocol, assessment schema, and evaluator registry once; let Opportunity Scout, FIF, customer-intelligence, and future consumers plug in.

**Origin:** Evaluation of Hyperspace/Prometheus Research DAG architecture + conversation about extending Opportunity Scout's evaluation pipeline. The insight: the multi-agent evaluation concept is general, not Scout-specific. Factoring it as a framework avoids rebuilding the pattern for each consumer.

---

## 1. Core Concept

A deliberation is a structured multi-perspective evaluation of an artifact. The framework provides:

1. **Evaluator registry** — available evaluative lenses, each backed by an overlay document
2. **Assessment schema** — a shared contract for what every evaluator produces
3. **Deliberation protocol** — the rules for how evaluators interact (independent assessment → conditional dissent → synthesis)
4. **Synthesis engine** — cross-artifact pattern extraction from accumulated assessments
5. **Calibration loop** — feedback-driven refinement of evaluator accuracy over time

The framework does NOT make decisions. It produces structured, multi-perspective analysis that a human (Danny) or an orchestrator (Tess) uses to make decisions. The framework's job is to ensure that decisions are informed by every relevant lens, that disagreements are surfaced rather than smoothed over, and that patterns across decisions become visible over time.

## 2. Key Definitions

**Artifact:** The thing being evaluated. Could be: an opportunity candidate (Scout), a signal note (FIF), an account dossier (customer-intel), an architectural decision (Crumb system), a career choice, a research finding, a design direction. The framework is artifact-agnostic — it evaluates whatever the consumer hands it.

**Evaluator:** An agent role defined by an overlay document, a model assignment, and an assessment schema. Evaluators produce structured assessments. They do not make decisions or take actions.

**Panel:** The set of evaluators assigned to a specific deliberation. Panels are configured per consumer — Scout uses {Business Advisor, Career Coach, Financial Advisor, Design Advisor}, while customer-intel might use {Career Coach, Network Skills, Business Advisor}. Panel composition is a consumer decision, not a framework decision.

**Deliberation:** A complete evaluation cycle: panel assignment → independent assessment → conditional dissent → synthesis. Each deliberation produces a deliberation record that persists.

**Synthesis:** A cross-artifact analysis produced by reading across all assessments in a batch (or a time window). Synthesis identifies patterns, convergences, contradictions, and emergent insights that no single evaluator or single artifact reveals.

## 3. Assessment Schema

Every evaluator produces the same structure regardless of artifact type. This is the deliberation equivalent of FIF's NormalizedItem schema — standardize the interface, let the evaluative content vary.

```yaml
# Assessment Schema v1
# Shared contract: every evaluator produces this for every artifact.

assessment:
  # Identity
  deliberation_id:
    type: string
    required: true
    description: "UUID linking this assessment to its deliberation."
  evaluator_id:
    type: string
    required: true
    description: "Registry ID of the evaluator role (e.g., 'business-advisor')."
  artifact_ref:
    type: string
    required: true
    description: >
      Reference to the artifact being evaluated. Format depends on consumer:
      Scout candidate_id, FIF signal note path, customer-intel account slug, etc.
  pass_number:
    type: integer
    required: true
    enum: [1, 2]
    description: "1 = independent assessment, 2 = dissent/response."
  timestamp:
    type: string
    format: iso8601
    required: true

  # Model provenance
  model_used:
    type: string
    required: true
    description: "Model ID used for this assessment."

  # Evaluation
  verdict:
    type: string
    required: true
    enum: [strong, promising, neutral, cautionary, reject]
    description: >
      Five-point scale. 'strong' and 'reject' are high-conviction.
      'promising' and 'cautionary' are directional.
      'neutral' means the evaluator's lens doesn't have a clear signal.
  confidence:
    type: number
    required: true
    minimum: 0.0
    maximum: 1.0
    description: "Evaluator's confidence in its own verdict."
  key_finding:
    type: string
    required: true
    description: "1-2 sentence summary. Must be specific enough to be useful without reading full reasoning."
  reasoning:
    type: string
    required: true
    description: "Structured analysis, 150-400 words. Must reference specific attributes of the artifact."
  flags:
    type: array
    items:
      type: string
    required: false
    description: "Specific concerns or opportunities that deserve attention. Each flag is actionable."

  # Dissent (Pass 2 only)
  dissent_target:
    type: string
    required: false
    description: "evaluator_id of the assessment being responded to. Null for Pass 1."
  dissent_type:
    type: string
    required: false
    enum: [disagree, augment, condition]
    description: >
      'disagree': verdict conflict — this evaluator reaches a different conclusion.
      'augment': no verdict conflict, but a material consideration was missed.
      'condition': verdict is correct only under specific conditions the original didn't state.
```

## 4. Evaluator Registry

The evaluator registry maps evaluator IDs to overlay documents, default model assignments, and behavioral parameters. It lives in `_system/schemas/deliberation/evaluator-registry.yaml`.

```yaml
# Evaluator Registry v1
# Maps evaluator roles to overlay sources, model defaults, and behavioral config.

evaluators:
  business-advisor:
    overlay_path: "_system/docs/overlays/business-advisor.md"
    companion_path: null
    default_model: claude-sonnet-4-6
    persona_bias: "structurally optimistic about markets, skeptical about execution timelines"
    dissent_instruction: "Look for market assumptions other evaluators take for granted."

  career-coach:
    overlay_path: "_system/docs/overlays/career-coach.md"
    companion_path: null
    default_model: claude-sonnet-4-6
    persona_bias: "structurally protective of career capital, alert to employer conflicts"
    dissent_instruction: "Look for PIIA risk or opportunity cost that other evaluators underweight."

  financial-advisor:
    overlay_path: "_system/docs/overlays/financial-advisor.md"
    companion_path: null
    default_model: claude-sonnet-4-6
    persona_bias: "structurally conservative about costs, skeptical of revenue projections"
    dissent_instruction: "Look for hidden costs, optimistic revenue assumptions, or missing risk scenarios."

  design-advisor:
    overlay_path: "_system/docs/overlays/design-advisor.md"
    companion_path: "_system/docs/design-advisor-dataviz.md"
    default_model: claude-sonnet-4-6
    persona_bias: "structurally idealistic about craft, resistant to shortcuts that sacrifice quality"
    dissent_instruction: "Look for compromises other evaluators accept that would erode brand or creative integrity."

  life-coach:
    overlay_path: "_system/docs/overlays/life-coach.md"
    companion_path: "Domains/Spiritual/personal-philosophy.md"
    default_model: claude-sonnet-4-6
    persona_bias: "structurally attentive to sustainability, values alignment, and whole-person impact"
    dissent_instruction: "Look for decisions that optimize one domain at the expense of others."

  network-skills:
    overlay_path: "_system/docs/overlays/network-skills.md"
    companion_path: "_system/docs/network-skills-sources.md"
    default_model: claude-sonnet-4-6
    persona_bias: "structurally precise about technical claims, skeptical of hand-waving"
    dissent_instruction: "Look for technical claims that don't withstand scrutiny."

  # Future: critic (from A2A-014)
  # critic:
  #   overlay_path: TBD (critic skill, not an overlay — needs adapter)
  #   default_model: claude-opus-4-6
  #   persona_bias: "structurally adversarial — finds the weakest point and attacks it"
  #   dissent_instruction: "Find the strongest assessment and argue against it."
```

**Key design decision: `persona_bias` and `dissent_instruction`.** These fields exist specifically to counteract consensus drift on same-model evaluators. Each evaluator is told what to be skeptical about and where to focus dissent. This is prompt-level differentiation — cheaper than multi-model dispatch, sufficient for most evaluations, and stackable with multi-model for high-stakes deliberations.

## 5. Deliberation Protocol

### 5.1 Invocation

A consumer requests a deliberation by submitting a **deliberation brief**:

```yaml
# Deliberation Brief Schema v1
deliberation:
  artifact_ref:
    type: string
    required: true
    description: "Reference to the artifact being evaluated."
  artifact_content:
    type: string
    required: true
    description: "The artifact content itself, or a path to read it from."
  artifact_type:
    type: string
    required: true
    description: "Consumer-defined type hint (e.g., 'opportunity-candidate', 'signal-note', 'account-dossier')."
  panel:
    type: array
    items:
      type: string
    required: true
    description: "List of evaluator_ids from the registry. Order doesn't matter."
  depth:
    type: string
    required: false
    default: standard
    enum: [quick, standard, deep]
    description: >
      quick: Pass 1 only, Haiku, no synthesis. Cheapest.
      standard: Pass 1 + conditional Pass 2, Sonnet, batch synthesis.
      deep: Pass 1 + always Pass 2, multi-model, per-artifact synthesis + batch synthesis. Opus for synthesis.
  context:
    type: string
    required: false
    description: "Additional context the consumer wants evaluators to have."
  batch_id:
    type: string
    required: false
    description: "Groups deliberations for cross-artifact synthesis. All deliberations with the same batch_id are synthesized together."
```

### 5.2 Execution Flow

```
Consumer submits deliberation brief
         │
         ▼
┌─────────────────────────┐
│  PASS 1: Independent    │  All panel evaluators run in parallel.
│  Assessment             │  Each loads its overlay + companion.
│                         │  No evaluator sees another's output.
│  Output: N assessments  │  Model tier per depth setting.
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  SPLIT CHECK            │  Are all verdicts within 1 step of each other?
│                         │  (e.g., all promising/neutral = no split)
│  Split = verdicts span  │  (strong+cautionary = split, promising+neutral = no split)
│  2+ steps on the scale  │
└─────┬──────────┬────────┘
      │          │
  no split    split (or depth=deep)
      │          │
      │          ▼
      │  ┌─────────────────────────┐
      │  │  PASS 2: Dissent        │  Each evaluator reads all Pass 1 assessments.
      │  │                         │  Writes dissent only if it has something to say.
      │  │  Output: 0-N dissents   │  dissent_type: disagree / augment / condition
      │  └────────────┬────────────┘
      │               │
      └───────┬───────┘
              │
              ▼
┌─────────────────────────┐
│  DELIBERATION RECORD    │  All assessments + dissents persisted.
│  WRITTEN                │  Record linked to artifact_ref + batch_id.
└────────────┬────────────┘
             │
             ▼
   ┌─────────────────────┐
   │  SYNTHESIS           │  Runs per batch_id, not per artifact.
   │  (if batch_id set)   │  Reads all deliberation records in batch.
   │                      │  Produces cross-artifact patterns.
   └──────────────────────┘
```

### 5.3 Split Check Logic

The five-point verdict scale has a natural distance metric:

```
reject(0) — cautionary(1) — neutral(2) — promising(3) — strong(4)
```

A split exists when `max(verdicts) - min(verdicts) >= 2`. This means:
- promising + neutral = no split (distance 1)
- promising + cautionary = split (distance 2)
- strong + neutral = split (distance 2)
- strong + reject = definite split (distance 4)

This is deliberately conservative — it triggers Pass 2 only when there's genuine disagreement, not just shade differences. If depth=deep, Pass 2 always runs regardless of split.

### 5.4 Model Routing by Depth

| Depth | Pass 1 Model | Pass 2 Model | Synthesis Model |
|-------|-------------|-------------|-----------------|
| quick | Haiku | (skipped) | (skipped) |
| standard | Sonnet | Sonnet | Sonnet |
| deep | Per-evaluator registry override or Opus | Opus | Opus |

At `deep` depth, consumers can override individual evaluator models in the brief:

```yaml
panel_overrides:
  business-advisor: { model: claude-opus-4-6 }
  financial-advisor: { model: gemini-3-pro }
```

This enables the multi-model diversity pattern from the peer-review skill without requiring it for every deliberation.

## 6. Synthesis Engine

### 6.1 Per-Batch Synthesis

The synthesis agent reads all deliberation records in a batch and produces:

**Pattern detection.** "3 of 5 artifacts in this batch involve AI-assisted educational content. Business Advisor rated all three 'promising.' Cross-referencing with the calibration seed, Pattern 2 (Expert Research Newsletter) and Pattern 7 (Knowledge-Transformed Products) both score H/H/H on the three gates. This is a convergent market signal."

**Convergence identification.** "Career Coach and Design Advisor independently flagged the same artifact (candidate X) as strongly aligned with Danny's identity and trajectory. Financial Advisor confirmed low startup cost. This convergence across three lenses suggests candidate X deserves a research dispatch."

**Contradiction surfacing.** "Business Advisor rates candidate Y 'strong' (large market, clear demand). Career Coach rates it 'cautionary' (PIIA proximity to employer domain). This contradiction cannot be resolved by the framework — it requires Danny's judgment on risk tolerance."

**Trend tracking.** "Over the last 4 batches, Financial Advisor has rated every SaaS opportunity 'cautionary' due to infrastructure cost estimates. Business Advisor has rated 3 of 4 'promising.' This persistent divergence suggests either Financial Advisor's cost model is too conservative or Business Advisor is underweighting operational cost. Recommend calibration review."

### 6.2 Synthesis Output Schema

```yaml
synthesis:
  batch_id: string
  synthesis_date: iso8601
  model_used: string
  artifact_count: integer
  deliberation_count: integer

  patterns:
    type: array
    items:
      pattern_type: enum [convergence, contradiction, trend, emergence]
      description: string
      evidence: array[string]  # deliberation_id references
      confidence: number
      actionable: boolean
      suggested_action: string | null

  evaluator_diagnostics:
    type: array
    items:
      evaluator_id: string
      verdict_distribution: object  # {strong: N, promising: N, ...}
      avg_confidence: number
      dissent_rate: number  # fraction of Pass 2 where this evaluator dissented
      persistent_themes: array[string]  # recurring flags or concerns
```

### 6.3 Synthesis as Compound Insight

Synthesis outputs with `actionable: true` are compound insights in the A2A sense. They should route through the existing compound insight infrastructure (A2A Workflow 1). This means:

- Actionable synthesis patterns can trigger research dispatches (A2A Workflow 2)
- Synthesis outputs appear in the morning briefing (via attention-manager / daily-attention)
- Synthesis outputs surface in mission control dashboard (via MC data layer)
- Feedback on synthesis outputs flows back through the A2A feedback ledger

No new routing infrastructure needed. The synthesis engine produces compound insights; A2A delivers them.

## 7. Calibration Loop

### 7.1 Feedback-Driven Learning

The deliberation framework produces assessments. Danny (or Tess, acting on Danny's behalf) produces actions — bookmark, research, reject, pursue, ignore. The gap between assessment and action is calibration signal.

```
Assessment: Business Advisor rates candidate X "strong"
Action: Danny ignores candidate X for 30 days
Signal: Business Advisor's "strong" verdict didn't predict engagement.
         Either the verdict was wrong, or Danny's inaction has a different cause.
```

The calibration loop does NOT automatically retrain evaluators. It accumulates (assessment, verdict, action, outcome) tuples and surfaces them to the synthesis engine during periodic reviews (monthly, or on-demand). The synthesis engine proposes calibration adjustments; Danny approves or rejects them.

This is deliberately human-in-the-loop. Automated calibration risks Goodhart's Law — evaluators optimizing to predict Danny's current behavior rather than producing genuinely useful analysis. Danny's behavior might be wrong (he might be ignoring a strong opportunity due to time pressure, not because the assessment was bad). The calibration loop should inform, not auto-correct.

### 7.2 Evaluator Diagnostics

Monthly (or on-demand), the synthesis engine produces per-evaluator diagnostics:

- **Verdict distribution:** Is this evaluator rating everything "promising"? A flat distribution suggests the evaluator isn't differentiating.
- **Prediction accuracy:** Of the artifacts this evaluator rated "strong," what fraction did Danny act on? Of those rated "reject," what fraction did Danny override?
- **Dissent accuracy:** When this evaluator dissented in Pass 2, was the dissent vindicated by subsequent events or Danny's actions?
- **Persistent themes:** What flags does this evaluator raise most often? Are those flags correlated with Danny's engagement?

These diagnostics are presented in the monthly evaluation memo (or a standalone deliberation health report). They're inputs to prompt refinement, not automatic prompt changes.

### 7.3 Biological Memory Pattern (Inspired by Hyperspace/Prometheus)

Over time, the calibration data enables a simplified biological memory model:

- **Strengthen:** Evaluator patterns that predict Danny's engagement get reinforced — they appear earlier in the evaluator prompt as calibration examples.
- **Decay:** Evaluator patterns that don't predict engagement fade — they're removed from calibration examples after N months of zero signal.
- **Consolidate:** Similar assessment patterns across multiple evaluators get merged into framework-level calibration insights. "All evaluators consistently rate educational content higher than SaaS for Danny" becomes a framework-level heuristic, not four independent evaluator observations.

This is deferred to a later milestone. The initial build uses static overlay prompts and accumulates calibration data. The biological memory model is an evolution once there's enough data to drive it (likely 3-6 months of operation).

## 8. Consumer Integration Pattern

Each consumer integrates with the framework by:

1. **Defining the artifact format** it submits for deliberation (candidate record, signal note, dossier, etc.)
2. **Selecting a panel** from the evaluator registry
3. **Setting depth defaults** appropriate to its volume and cost ceiling
4. **Providing batch_id** grouping logic (daily batch, weekly batch, on-demand, etc.)
5. **Consuming deliberation records and synthesis outputs** through its own delivery channel

### 8.1 Planned Consumers

| Consumer | Artifact Type | Panel | Depth | Batch Cadence | Trigger |
|----------|--------------|-------|-------|---------------|---------|
| Opportunity Scout | opportunity-candidate | business-advisor, career-coach, financial-advisor, design-advisor | standard (quick for marginal candidates) | Daily | New candidates with all-H gates, or Danny bookmarks |
| Feed-Intel Framework | signal-note (high-signal only) | business-advisor, career-coach, life-coach | quick | Per-digest | T1 items only |
| Customer Intelligence | account-dossier | career-coach, network-skills, business-advisor | standard | Per-account refresh | New or updated dossier |
| Crumb Architecture | architectural-decision | business-advisor, life-coach, design-advisor | deep | On-demand | Operator requests deliberation on a system design choice |
| Career Decisions | career-choice | career-coach, financial-advisor, life-coach, business-advisor | deep | On-demand | Danny asks "should I..." about a career-impacting decision |

### 8.2 Non-Consumers (Explicitly Out of Scope)

- **Peer review.** The peer-review skill uses external models to assess technical quality. The deliberation framework uses internal overlays to assess alignment, risk, and strategic fit. These are complementary, not overlapping. Peer review asks "is this well-built?" Deliberation asks "should we be building this?"
- **Research pipeline.** The researcher skill produces evidence-grounded deliverables. The deliberation framework evaluates whether those deliverables are useful and actionable. Research produces artifacts; deliberation evaluates them.
- **Triage.** FIF and Scout both have triage stages (Haiku gate scoring). Triage is a cheap, fast filter. Deliberation is a rich, expensive evaluation. Triage decides what enters the pipeline; deliberation decides what matters.

## 9. Cost Model

### 9.1 Per-Deliberation Cost

| Depth | Evaluators | Calls | Est. Cost |
|-------|-----------|-------|-----------|
| quick (Haiku, Pass 1 only) | 4 | 4 | ~$0.02 |
| standard (Sonnet, Pass 1 + conditional Pass 2) | 4 | 4-8 | ~$0.12-0.24 |
| standard + synthesis | 4 + synth | 5-9 | ~$0.15-0.30 |
| deep (Opus/multi-model, always Pass 2) | 4 | 8-12 | ~$0.80-1.50 |
| deep + synthesis | 4 + synth | 9-13 | ~$1.00-2.00 |

### 9.2 Monthly Cost Projections by Consumer

Assuming steady-state volumes:

| Consumer | Deliberations/Month | Typical Depth | Est. Monthly Cost |
|----------|--------------------|--------------|--------------------|
| Opportunity Scout | 30-60 (1-2/day, candidates with strong gates) | standard | $3.60-14.40 |
| FIF (T1 items only) | 15-30 | quick | $0.30-0.60 |
| Customer Intelligence | 5-10 (account refreshes) | standard | $0.60-2.40 |
| Architecture decisions | 1-3 | deep | $1.00-6.00 |
| Career decisions | 1-2 | deep | $1.00-4.00 |
| **Total** | **52-105** | — | **$6.50-27.40** |

The upper end ($27.40/mo) is reachable but uncomfortable against the existing $10/mo Scout ceiling. Cost controls:

- **Ceremony budget gate per consumer.** Each consumer declares a monthly deliberation budget. Framework enforces it. Scout might get 40 deliberations/month; FIF gets 30; architecture gets 5.
- **Depth defaults matter.** The difference between quick ($0.02) and deep ($1.50) is 75x. Most deliberations should be quick or standard. Deep is reserved for high-stakes decisions.
- **Batch synthesis amortizes.** One synthesis call per batch, not per artifact. A 10-artifact batch costs ~$0.05 for synthesis, not $0.50.

## 10. Open Questions (For SPECIFY Phase)

1. **Project or system skill?** Should this be a standalone project (like crumb-tess-bridge or feed-intel-framework) or a system skill (like researcher or peer-review)? The skill model is simpler but may not accommodate the schema definitions, evaluator registry, and calibration data store. The project model is heavier but provides better governance.

2. **Storage architecture.** Deliberation records, assessment data, synthesis outputs, and calibration tuples all need persistence. Options: (a) SQLite database in `~/openclaw/deliberation-framework/`, (b) vault markdown files in `_system/deliberation/`, (c) hybrid — structured data in SQLite, human-readable summaries in vault. The monthly synthesis needs efficient querying; Danny might want to browse deliberation records in Obsidian.

3. **Evaluator prompt assembly.** Each evaluator needs: overlay document + companion doc (if any) + persona_bias + dissent_instruction + artifact content + prior assessments (Pass 2 only) + consumer-provided context. How is this assembled? A template system in the framework? Or does each consumer build its own prompts and the framework only validates the output schema?

4. **Synthesis trigger.** When does synthesis run? Options: (a) after every batch completes (automated), (b) daily at a scheduled time (LaunchAgent), (c) on-demand only. Automated is richest but most expensive. On-demand is cheapest but loses the "patterns emerge without Danny asking" benefit.

5. **Relationship to A2A-014 (critic skill).** The critic is a natural fit as an evaluator — structurally adversarial, attacks the strongest assessment. But the critic skill is designed for code/artifact review, not opportunity/decision evaluation. Does it need an adapter, or is the critic a separate evaluator with its own overlay?

6. **Deliberation records in mission control.** Should the MC dashboard show deliberation summaries? If so, what's the data contract? A read API exposing recent deliberation records + synthesis outputs would make MC a natural consumption surface, but adds scope to both projects.

7. **Multi-artifact deliberation.** The current design evaluates one artifact per deliberation. Some decisions involve comparing artifacts ("should I pursue opportunity A or B?"). Comparative deliberation requires a different protocol — evaluators assess both artifacts and produce a comparative verdict. Is this a v1 requirement or a future extension?

8. **Evaluator lifecycle.** When a new overlay is created (or an existing one significantly updated), should the evaluator registry auto-update? Or is registry maintenance manual? Auto-update risks breaking panel configurations; manual risks staleness.

## 11. Implementation Phasing

### Phase 1: Foundation (3-5 tasks)
- Assessment schema definition (`_system/schemas/deliberation/assessment-schema.yaml`)
- Evaluator registry definition (`_system/schemas/deliberation/evaluator-registry.yaml`)
- Deliberation brief schema definition (`_system/schemas/deliberation/deliberation-brief.yaml`)
- Basic deliberation executor: takes a brief, dispatches evaluators (Pass 1 only), collects assessments, writes deliberation record
- First consumer integration: Opportunity Scout (replacing current single-pass Sonnet ranking for top candidates)

### Phase 2: Dissent + Synthesis (3-4 tasks)
- Pass 2 dissent protocol (split check, dissent dispatch, dissent collection)
- Batch synthesis engine (cross-artifact pattern detection)
- Synthesis → A2A compound insight routing
- Second consumer integration: FIF (T1 items only, quick depth)

### Phase 3: Calibration + Diagnostics (3-4 tasks)
- Calibration data accumulation (assessment, verdict, action, outcome tuples)
- Monthly evaluator diagnostics generation
- Calibration review integration with monthly evaluation workflow
- Third consumer integration: customer-intelligence or architecture decisions

### Phase 4: Biological Memory (Deferred)
- Strengthen/decay/consolidate patterns on calibration data
- Automated calibration example management in evaluator prompts
- Cross-evaluator consolidation of persistent patterns
- Research DAG structure for synthesis outputs (lineage chains, cross-cycle memory)

## 12. Ceremony Budget Gate

This framework should NOT be built unless at least one consumer has demonstrated the need through behavioral evidence:

- **Opportunity Scout:** M2 passes (bookmark/research rate ≥20% after 30 days). This proves Danny engages with opportunity evaluation and would benefit from richer analysis.
- **FIF:** Operator reports that signal notes are missing important perspectives that overlay-informed evaluation would have caught.
- **Customer Intelligence:** Account prep process shows gaps that multi-lens evaluation would fill.

If no consumer passes its behavioral gate, the framework doesn't earn its ceremony budget. The design sketch persists as a vault artifact for when the need materializes.

---

## 13. References

- Scout-specific design sketch: `Projects/opportunity-scout/design/gossip-loop-design-sketch.md`
- Hyperspace/Prometheus signal note: `Sources/signals/varun-mathur-hyperspace-prometheus-cognitive-engine.md`
- A2A specification (compound insights, Workflow 1): `Projects/agent-to-agent-communication/design/specification.md`
- Overlay index: `_system/docs/overlays/overlay-index.md`
- Research brief schema (architectural precedent): `_system/schemas/briefs/research-brief.yaml`
- Peer-review skill (multi-model dispatch pattern): `.claude/skills/peer-review/SKILL.md`
- Superpowers two-stage review (spec compliance → code quality): `Sources/research/brief-superpowers.md`
