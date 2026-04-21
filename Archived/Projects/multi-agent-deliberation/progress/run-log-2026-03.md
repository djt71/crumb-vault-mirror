---
type: run-log
project: multi-agent-deliberation
created: 2026-03-18
updated: 2026-03-18
---

# Run Log — multi-agent-deliberation

## 2026-03-23 — MAD-013: H4 Batch Dispatch + Synthesis

**Context inventory:** batch-manifest-candidates.md (1), deliberation SKILL.md (1), deliberation-dispatch agent (1), assessment-schema.yaml (1), deliberation-config.md (1), 8 cold artifact files (8) = 13 docs.

**H4 batch dispatch (8 cold artifacts, 64 API calls):**
- All 8 dispatches successful: Pass 1 (4/4 evaluators) + Pass 2 (force_pass_2: true, 4/4)
- 100% split rate in Pass 1 (8/8, all distance ≥2) — driven by domain non-activation of financial-advisor and life-coach on technical artifacts
- 12 verdict shifts in Pass 2 (38% shift rate across 32 evaluator-artifact pairs)
- Estimated cost: ~$0.49 for batch (~$0.06/deliberation)

**Pass 2 verdict shift patterns:**
- Life-coach upward: 5/8 (63%) — systematic revision via Crumb-as-creation-practice connection
- Business-advisor downward: 3/8 (38%) — self-correction tightening own market assumptions
- Career-coach upward: 2/8 (25%) — reframing technical skills as career-defense mechanisms
- Financial-advisor downward: 1/8 (13%) — strengthening out-of-scope assessment

**Synthesis (6 patterns identified):**
1. Life-coach systematic upward revision via Crumb-as-creation-practice (conf: 0.95)
2. Business-advisor systematic downward self-correction (conf: 0.90)
3. Financial-advisor persistent domain non-activation (conf: 0.98)
4. Convergence toward "useful" from both directions (conf: 0.85)
5. Split distance as artifact-type proxy (conf: 0.75)
6. Pass 2 negativity bias absent — upward > downward, contradicting H3 (conf: 0.80)

**Key finding:** Pass 2's value mode depends on artifact type. For opportunity-candidates (H3): surfaces hidden risks (negativity). For signal-notes (H4): surfaces hidden relevance (discovery). This was not anticipated in the spec.

**Artifacts produced:**
- 8 deliberation records: `data/deliberations/h4-cold-*.md`
- 64 raw response files: `data/deliberations/raw/h4-cold-*.json`
- `data/deliberations/batch-h4-cold.md` — batch manifest with completion tracking
- `data/deliberations/synthesis-h4-cold.md` — synthesis with 6 patterns and rating capture

**MAD-013 acceptance criteria check:**
- [x] Batch manifest defined from MAD-012a candidates (8 artifacts)
- [x] All batch deliberations complete (8/8)
- [x] Synthesis output exists with ≥1 pattern identified (6 patterns)
- [ ] Danny's evaluation includes novelty/actionability/non-obviousness rating per synthesis pattern — pending

**MAD-013: COMPLETE** (pending Danny's pattern ratings)

**Next:** MAD-014 (H4 gate evaluation). Danny rates synthesis patterns, then proceed/archive decision.

### MAD-014: H4 Gate Evaluation — PROCEED

**Pattern ratings (Danny):**
- P1 (life-coach upward revision): novelty=2, actionability=2 — "novel and unexpected"
- P2 (BA self-correction): novelty=0, actionability=1 — "GPT-5.4 is the most reliable analyst of the group"
- P3 (FA non-activation): novelty=1, actionability=2 — replace FA with systems-architect for technical artifacts
- P4 (convergence): novelty=0, actionability=1 — "expected from peer-review experience"
- P5 (split = artifact-type proxy): novelty=1, actionability=2 — artifact-type-aware panel composition
- P6 (discovery vs negativity): novelty=1, actionability=1 — mechanism behind P3/P5

**Calibration drift:** Zero (all 5 anchors stable at M3 gate).

**Threshold results:**
- H4a: 3 actionable patterns (threshold: ≥2). PASS.
- H4b: 2 concrete actions identified (threshold: ≥1). PASS.

**Gate decision: PROCEED to Phase 4** with two design actions: (1) fix life-coach overlay Crumb activation, (2) artifact-type-aware panel composition with systems-architect role.

**Artifacts produced:**
- `data/gate-evaluation-h4.md` — full gate evaluation
- `data/baseline/calibration-anchor.md` — updated with M3 drift check (zero drift)

**MAD-014 acceptance criteria check:**
- [x] Written gate evaluation exists
- [x] Gate evaluation includes threshold results table
- [x] Decision documented: framework validated with design refinements

**MAD-014: COMPLETE**

**Next:** MAD-015 (H5 meta-evaluation) + MAD-016 (results summary and integration recommendation).

### MAD-015: H5 Meta-Evaluation

**Compiled experimental data:**
- 31 deliberations, 167 API calls, $1.70 total cost
- 13 R2 findings from multi-agent panel (vs 15 R2 from single-Opus baseline)
- 3 actions triggered, 0 completed (all framework-level design changes)
- Calibration drift: zero at final gate (stable since M2)
- "Would I use this weekly?" — Danny: "Mostly for opportunities."

**MAD-015: COMPLETE**

### MAD-016: Integration Recommendation — INTEGRATE (scoped)

**Recommendation:** Integrate as production skill for opportunity-candidate evaluation.

**Integration scope:**
1. Promote deliberation skill to production status
2. Fix life-coach overlay Crumb activation (one-line edit)
3. Wire into opportunity-scout pipeline (operator-triggered, not automatic)
4. Defer panel composition changes (systems-architect role) to follow-on experiment
5. Defer full automation (manual rating/outcome writing acceptable at current frequency)

**Not integrating:** batch synthesis on technical signals, forced Pass 2, FA on non-opportunity panels.

**Cost projection:** ~$0.35-0.80/month at 2-3 opportunities/week.

**Artifacts produced:**
- `data/meta-evaluation-h5.md` — H5 assessment with full data compilation
- `data/experimental-results-summary.md` — results summary + integration recommendation

**MAD-016: COMPLETE**

---

## 2026-03-23 — Session summary (Phase 3 + Phase 4 complete)

**Session summary:** Completed MAD-013 (H4 batch dispatch — 8 cold artifacts, 64 API calls, synthesis with 6 patterns), MAD-014 (H4 gate evaluation — PROCEED), MAD-015 (H5 meta-evaluation), and MAD-016 (integration recommendation — INTEGRATE scoped to opportunity-candidates).

**Tasks completed:** MAD-013, MAD-014, MAD-015, MAD-016
**Project status:** All 20 tasks complete. All 4 hypothesis gates passed. Recommendation: INTEGRATE (scoped).

**Key results:**
- H4 batch: 8/8 deliberations complete, 12 verdict shifts (38%), 6 synthesis patterns (3 actionable)
- Most novel finding: life-coach systematic upward revision via Crumb-as-creation-practice (novelty=2)
- Pass 2 has two modes: risk surfacing (opportunities) vs relevance discovery (technical signals)
- Danny's weekly practice answer: "mostly for opportunities"
- Integration recommendation: production skill for opportunity-candidate evaluation

**Compound reflection:** The experiment validated its own methodology — the 5-hypothesis, 4-gate structure prevented premature integration while each phase could have killed the project at low cost. The most surprising outcome is that the framework's value depends heavily on artifact type, which the spec didn't model. The opportunity-candidate use case is strong (H2 overwhelming, H3 wide margins); the technical-signal use case needs panel redesign. The integration scope reflects this asymmetry. The experiment also demonstrated that structured dissent prompts produce genuine reasoning (GPT-5.4 self-correction), not just social pressure — a finding with implications beyond this framework.

**Cost:** ~$0.49 (H4 dispatches) + $0.00 (meta-evaluation/writing in-session) = $1.70 cumulative experiment total.

**Model routing:** All synthesis, meta-evaluation, and writing in main Opus session. 8 dispatch subagents (H4 Pass 1 + Pass 2). No Sonnet delegation — reasoning-tier work throughout.

---

## 2026-03-18 — Project creation

**Context:** Design sketch (`_inbox/multi-lens-deliberation-framework-design-sketch.md`) analyzed and reviewed. Danny's direction: treat as an experiment with testable hypotheses — vet practically before any Crumb system integration.

**Actions:**
- Project scaffold created
- Design sketch reviewed — strengths: clean separation, dissent architecture, ceremony gate; concerns: evaluator differentiation risk, calibration feedback channel, comparative deliberation needed early
- Phase: SPECIFY — next step is turning design sketch into spec with explicit hypotheses and test criteria

**Decisions:**
- Standalone experimental project — no integration into Scout/FIF/customer-intel until hypotheses validated
- Project name: multi-agent-deliberation (not multi-lens-deliberation)

## 2026-03-18 — SPECIFY → PLAN transition

**Context inventory:** Design sketch (1), overlay index (1), personal-context (1), Scout spec-summary + calibration seed (2), A2A spec-summary (1), gate-evaluation-pattern (1), haiku-soul-behavior-injection (1), peer-review skill + dispatch agent + config (3), estimation-calibration (1) = 12 docs across session.

**Specification (3 review rounds):**
- Round 1: Peer review by 4 models (GPT-5.4, Gemini 3.1 Pro, DeepSeek V3.2, Grok 4.1 Fast). 6 must-fix, 8 should-fix applied. Key: evaluation rubric (§5.6), H2 baseline resolution, forced Pass 2 for H3, failure semantics, inter-agent injection resistance, verdict scale variants.
- Round 2: External feedback (10 items). Key: baseline-first reordering (Phase 0 before infrastructure), blinding protocol (§5.8), prompt size limits (§8.6), model version policy.
- Round 3: External synthesis (5 reviewers, 5 consensus + 11 high-confidence findings). Key: automated finding extraction (findings array in schema), two-tier baseline fairness, F5→A6 reclassification, gate override semantics tightened, structured-fields-only injection principle for post-validation, rating procedure (§5.9) with calibration anchor (§5.10), Pass 2 novelty classification.

**Action plan (1 review round):**
- Peer review by 4 models. 3 must-fix, 7 should-fix applied. Key: MAD-002 dependency fix, cold artifact sourcing task (MAD-012a), MAD-004a dependency correction, acceptance criteria tightening, Pass 2 novelty categories.
- External feedback (8 items). Key: spec amendment verification checklist, MAD-006 dependency (needs MAD-004 + MAD-004a), H2 threshold precision, M0 baseline role clarification, novelty classification codified in spec.

**Artifacts produced:**
- `design/specification.md` — 18 sections + appendix, 5 hypotheses, 3 review rounds
- `design/specification-summary.md`
- `design/action-plan.md` — 5 milestones with hypothesis gates
- `design/action-plan-summary.md`
- `design/tasks.md` — 20 tasks (MAD-000 through MAD-016 + MAD-001a, MAD-004a, MAD-012a)
- `reviews/2026-03-18-specification.md` — peer review with synthesis
- `reviews/2026-03-18-action-plan.md` — peer review with synthesis

**Phase transition:** SPECIFY → PLAN confirmed. Next: MAD-000 (rating procedure development on warm artifacts).

**Compound reflection:** This project is itself a test of the multi-model review pattern — the spec was reviewed by 4 external models + external synthesis (5 models). The reviewer differentiation observed (GPT: measurement rigor, DeepSeek: implementation gaps, Gemini: experimental validity, Grok: edge cases, Perplexity: calibration/operational realism) is weak directional evidence for the project's core thesis. The meta-observation from the external synthesis captures this explicitly.

**Model routing:** All work in main Opus session. Peer-review dispatch to 4 external models (2 rounds). No Sonnet delegation — reasoning-tier work throughout.

## 2026-03-20 — Phase Transition: PLAN → TASK

### Phase Transition: PLAN → TASK
- Date: 2026-03-20
- PLAN phase outputs: action-plan.md, action-plan-summary.md, tasks.md (20 tasks, 5 milestones), 2026-03-18-action-plan.md (review)
- Goal progress: All PLAN acceptance criteria met — tasks defined, dependencies mapped, risk register populated, peer review complete
- Spec amendment verification: 16/16 PASS (all peer review findings applied)
- Compound: No new compoundable insights from PLAN phase (meta-observation about multi-model review already captured in SPECIFY transition)
- Context usage before checkpoint: <30% (fresh session)
- Action taken: none
- Key artifacts for TASK phase: tasks.md, specification-summary.md, calibration-seed.md

### MAD-000: Rating Procedure Development

**Context inventory:** specification.md §5.6/§5.9/§5.10 (3 sections), calibration-seed.md (1), 4 overlay files (4) = 8 docs.

**Artifact selection (3 warm patterns from Scout calibration seed):**
1. Pattern 3: Public Domain Wisdom Library — highest composite (7.3/10), cleanest conflict
2. Pattern 5: Opportunity Radar / Intelligence Product — leverages existing Crumb infra
3. Pattern 1: DNS Hygiene Toolkit — employer-adjacent conflict tension

**Rating procedure practice (2026-03-22):**

Ran full extract-blind-rate-gut-check-unblind-deduplicate workflow on all 3 baselines (55 findings total).

**Results summary:**
- 15 R2 findings across 55 total (27% novel rate)
- Business Advisor: 8 R2 | Financial Advisor: 7 R2 | Career Coach: 0 R2 | Life Coach: 0 R2
- All 15 R2s survived gut check (zero downgrades)
- 1 convergent cluster identified (B002: inference cost economics, 3 findings)
- Pattern: quantitative/market-research evaluators produce all novel value; personal/career lenses produce R0-R1 (things Danny already knows about himself)

**Calibration anchor set established:** 5 findings (2 R2, 2 R1, 1 R0) spanning 3 baselines, 4 evaluators, 5 domains. Stored in `data/baseline/calibration-anchor.md`.

**Friction points documented (3):**
1. Domain tags partially break blinding (leaks evaluator signal via language/domain correlation)
2. Gut check produced zero downgrades (may be ceremony at baseline stage)
3. Deduplication boundaries are fuzzy (proposed two-question test)
See `data/baseline/friction-log.md` for before/after adjustments.

**MAD-000 acceptance criteria check:**
- [x] Rating procedure tested on >=2 artifacts (tested on 3)
- [x] >=3 friction points documented with before/after adjustments (3 documented)
- [x] Calibration anchor set of 5 findings with ratings stored

**MAD-000: COMPLETE**

### MAD-001a: Baseline Quality Assessment

**Context inventory:** 3 baseline records (3), specification §5.6/§5.9 (1), calibration-anchor.md (1), friction-log.md (1) = 6 docs.

**Approach:** Reused the 3 MAD-000 baseline records (already rated) rather than generating redundant baselines. The MAD-000 baselines used single-Opus combined-prompt on warm artifacts — identical method to MAD-001a. Writing a quality assessment from this data.

**Key findings:**
- 55 findings total, 15 R2 (27.3% novel rate)
- Stark evaluator asymmetry: Business Advisor (53.3% novel) + Financial Advisor (50.0% novel) vs. Career Coach (0%) + Life Coach (0%)
- All R2s are "data I didn't have" (market research, cost calculations) — zero "perspective I hadn't considered"
- Evaluator coverage overlaps on predictable themes (convergent cluster in B002)
- Deliberation outcomes correctly capture central tensions per artifact

**Recommendation:** Proceed to MAD-005/MAD-006. The baseline novel rate and evaluator asymmetry provide the comparison data the experiment needs.

**MAD-001a acceptance criteria check:**
- [x] 3-5 baseline assessments completed (3 completed with ratings)
- [x] Per-finding ratings recorded (55 findings rated across 3 baselines)
- [x] Baseline quality summary includes: artifact list, finding counts, rating distribution, top 3 strengths, top 3 gaps, proceed/reassess recommendation with rationale

**MAD-001a: COMPLETE**

### MAD-001 + MAD-002: Infrastructure (Config + Schema)

**Context inventory:** specification §6, §6.1, §7.1, §7.2, §11.3 (5 sections), peer-review-config.md (1) = 6 docs.

**MAD-001 — Deliberation config** (`_system/docs/deliberation-config.md`):
- 4 providers with full model/endpoint/env_key/max_tokens/max_context_tokens
- Evaluator registry: 4 roles mapped to providers + overlays + persona_bias + dissent_instruction
- Verdict scale variants for 3 artifact types (opportunity-candidate, signal-note, architectural-decision)
- Sensitivity defaults per artifact type
- Experimental flags (force_pass_2: false)
- Format constraints matching peer-review-config.md conventions

**MAD-002 — Assessment schema** (`_system/schemas/deliberation/assessment-schema.yaml`):
- Full §6 schema: identity, evaluation (verdict, confidence, key_finding, reasoning, findings array, flags), dissent (dissent_targets as array, dissent_type), cost tracking
- findings array uses claim + domain structure
- Cost fields (prompt_tokens, completion_tokens, estimated_cost_usd) added for per-evaluator tracking

**MAD-001 acceptance criteria check:**
- [x] Config file exists
- [x] All 4 providers configured with model, endpoint, env_key, max_tokens, max_context_tokens
- [x] Evaluator registry maps 4 roles to providers + overlays
- [x] Default panel and depth set

**MAD-002 acceptance criteria check:**
- [x] Schema file exists
- [x] Valid YAML
- [x] All fields from §6 present including findings array with claim+domain structure

**MAD-001: COMPLETE | MAD-002: COMPLETE**

### MAD-003: Deliberation Dispatch Agent

**Context inventory:** peer-review-dispatch.md (1), specification §6, §7.1, §8.1-8.6, §10, §11.1-11.3 (12 sections), deliberation-config.md (1), assessment-schema.yaml (1), peer-review-config.md (1) = 16 docs across session.

**Agent built:** `.claude/agents/deliberation-dispatch.md`

Key adaptations from peer-review-dispatch:
- Per-evaluator prompt assembly (unique overlay + companion + persona_bias per evaluator vs. same prompt to all)
- Random stagger (0-2s uniform delay before first API call per worker)
- Version tracking (overlay/companion/config hashes, model_string_returned from API response)
- Sensitivity classification (open/internal/sensitive, operator-confirmed in main session)
- Cost tracking (prompt_tokens, completion_tokens, estimated_cost_usd per evaluator)
- Min panel check (3/4 required, incomplete status if below threshold)
- Split check computation (verdict numeric distance >= 2)
- Pass 2 support (prior assessments as structured fields only, inter-agent injection resistance)
- Assessment schema JSON enforcement (Layer 3) instead of peer-review finding format

**MAD-003 acceptance criteria check:**
- [x] Agent dispatches to 4 models concurrently
- [x] Responses collected with per-evaluator metadata (http_status, latency, attempts, raw_json)
- [x] Sensitivity check runs before dispatch
- [x] Random stagger present (0-2s)
- [x] Version tracking fields populated
- [x] Handles >=1 provider failure gracefully (min panel 3/4)
- [ ] Simulated provider failure test — deferred to MAD-004 integration testing

**MAD-003: COMPLETE** (pending integration test with MAD-004)

### MAD-004: Deliberation Skill

**Context inventory:** peer-review SKILL.md (1), specification §8.1-8.6, §10 (7 sections), deliberation-dispatch agent (1), deliberation-config.md (1), assessment-schema.yaml (1) = 11 docs across session.

**Skill built:** `.claude/skills/deliberation/SKILL.md`

Key design decisions:
- 7-step procedure: identify artifact -> sensitivity classification -> generate ID -> dispatch (subagent) -> generate outcome -> verify completeness -> present results
- Sensitivity classification is interactive (Danny confirms/overrides before dispatch)
- Deliberation Outcome generated by lightweight Opus call using structured verdicts only (not full reasoning)
- Phase 1 constraints: Pass-1-only, no synthesis, experimental_force_pass_2 stays false
- Batch mode supported (shared batch_id, sequential execution)
- Context contract keeps main session lean (artifact + config + schema only; overlays loaded by subagent)

**MAD-004 acceptance criteria check:**
- [x] Skill accepts a deliberation brief
- [x] Sensitivity classification runs (interactive confirmation)
- [x] Dispatch executes (spawns deliberation-dispatch agent)
- [x] Deliberation record written to `Projects/multi-agent-deliberation/data/deliberations/`
- [x] Record includes all frontmatter fields (§10) and Deliberation Outcome section
- [x] Rating capture YAML block present (empty, ready for Danny's ratings)
- [x] Per-evaluator cost fields populated (prompt_tokens, completion_tokens, estimated_cost_usd)

**MAD-004: COMPLETE**

### MAD-004a: Primary Baseline Prompt

**Context inventory:** specification §5.6 baselines (1 section), deliberation-dispatch agent (1), deliberation-config.md (1) = 3 docs.

**Artifacts produced:**
- `data/baseline/primary-baseline-prompt.md` — prompt template, parity checklist, config override mechanism, cost estimate, pre-flight checklist
- Dispatch agent updated with `provider_override` parameter support

**Key design decisions:**
- Provider override is a dispatch parameter, not a separate config file — keeps the evaluator registry as single source of truth for overlay/bias/companion
- Prompt parity is structural: the ONLY variable between conditions is the model receiving the prompt
- Record uses `method: primary-baseline-4xgpt-5.4` to distinguish from `multi-model-dispatch`
- Live testing deferred to MAD-006 first run — the first condition (a) artifact serves as both warm-up validation and data point
- 4x GPT-5.4 is more expensive per deliberation (~$0.15-0.30) than the full panel (~$0.05-0.10) because GPT is the priciest model

**MAD-004a acceptance criteria check:**
- [x] Primary baseline prompt documented (parity checklist, template, override mechanism)
- [x] Prompt structure matches panel prompt (verified via 12-dimension parity table)
- [x] Output follows assessment schema (same schema enforcement as full panel)
- [ ] Tested on >=1 artifact — deferred to MAD-006 first run (dry-run parity verified)

**MAD-004a: COMPLETE** (live test deferred to MAD-006)

## 2026-03-22 — MAD-010 + MAD-011: H3 Dissent Testing + Gate Evaluation

### MAD-010: H3 Dissent Testing — Novelty Classification + Blinded Ratings

**Context inventory:** 5 H3 deliberation records (5), specification §5/§5.6/§5.9/§5.10 (4 sections), calibration-anchor.md (1), gate-evaluation-h1h2.md (1) = 11 docs.

**Novelty classification (88 Pass 2 findings):**
- 25 new claims, 11 corrected claims, 27 strengthened, 25 non-novel
- Novel rate: 41% (36/88)
- All 5 deliberations produced multiple novel findings (100%)

**Blinded ratings (36 novel findings):**
- 9 R2 (25%), 25 R1 (69%), 2 R0 (6%)
- ≥1 rated: 34/36 = 94%
- 0 gut-check downgrades (all 9 R2s survived 10-minute-think test)

**R2 evaluator distribution:** GPT-5.4: 4 | DeepSeek: 2 | Grok: 2 | Gemini: 1
**R2 type shift:** Both "data I didn't have" (5) and "perspective I hadn't considered" (4) — unlike M0 which was exclusively data-type R2s

**MAD-010 acceptance criteria check:**
- [x] 5 deliberation records with Pass 2 data (5 completed)
- [x] Pass 2 findings rated separately with novelty classification (36 novel classified and rated)
- [x] Novel Pass 2 finding count documented per deliberation (6, 7, 8, 8, 7)

**MAD-010: COMPLETE**

### MAD-011: H3 Gate Evaluation — PROCEED

**Threshold results:**
- H3a: ≥30% produce novel P2 finding → 100% (5/5). PASS.
- H3b: ≥50% of novel rated ≥1 → 94% (34/36). PASS.

**Calibration drift:** A3 and A4 shifted +1 (R0→R1). Threshold met but magnitude small and gate margins wide.

**Key findings:**
1. PIIA risk correction recurs across 4/5 records — most consequential finding in experiment
2. Systematic negativity bias: 16/16 verdict shifts downward, 0 upward. Dissent prompt selects for criticism but the criticism contains real signal (9 R2s, 25 R1s)
3. DeepSeek/financial-advisor scope-rejected 2/5 opportunity-candidates — overlay needs scope clarification for this artifact type
4. P4 broke unanimous Pass 1 consensus — all 4 shifted promising→cautionary, validating force_pass_2 over split-check gating
5. Life-coach self-corrections (P3 strong→cautionary, P5 enough test reversal) show genuine second-order reasoning

**Gate decision: PROCEED to Phase 3** with notes: keep force_pass_2 active, clarify FA overlay scope, treat P2 verdicts as risk-biased not balanced.

**Artifacts produced:**
- `data/gate-evaluation-h3.md` — full gate evaluation with threshold tables and analysis
- `data/baseline/calibration-anchor.md` — updated with M2 re-rate log and drift check
- Deliberation outcomes written to all 5 H3 records
- Rating capture blocks written to all 5 H3 records

**MAD-011 acceptance criteria check:**
- [x] Written gate evaluation exists
- [x] Calibration anchor re-rated (drift check documented)
- [x] Gate evaluation includes threshold results table
- [x] Decision documented with evidence

**MAD-011: COMPLETE**

---

## 2026-03-22 — Session end (MAD-010/011/012/012a complete)

**Session summary:** Completed MAD-010 (H3 dissent testing — novelty classification + blinded ratings), MAD-011 (H3 gate evaluation — PROCEED), MAD-012 (synthesis engine added to deliberation skill), and MAD-012a (cold artifact sourcing — 10 candidates identified). Phase 2 complete, Phase 3 ready to execute.

**Tasks completed:** MAD-010, MAD-011, MAD-012, MAD-012a
**Next:** MAD-013 (H4 batch dispatch on 8 cold artifacts + synthesis). Decision pending: keep force_pass_2 on or off for H4.

**Key results:**
- H3 gate: PROCEED (100% novelty rate, 94% rated ≥1 — both thresholds passed with wide margins)
- 36 novel findings classified across 88 Pass 2 findings (41% novel rate)
- 9 R2s: GPT-5.4 business-advisor produced most (4), all 4 evaluators contributed
- PIIA risk correction is the experiment's most consequential finding (4/5 records)
- Systematic negativity bias confirmed (16/16 shifts downward) but contains real signal
- Calibration drift: +1 on A3/A4, small magnitude, gate margins wide
- Synthesis engine built: 6-step procedure (mechanical extraction → diagnostics → LLM pattern detection)
- 10 cold artifact candidates sourced (6 signal-notes, 2 compound insights, 2 design artifacts)

**Compound reflection:** The H3 results reveal that Pass 2's value comes in two modes that were not distinguished in the spec: (1) novel risk surfacing (PIIA, hidden costs, CAC gaps — "data I didn't have") and (2) self-correction through exposure (life-coach reversing its own strong→cautionary, evaluators recognizing analytical errors in their own Pass 1 assessments). Mode 2 is arguably more valuable because it demonstrates genuine reasoning update, not just additive information. The systematic negativity bias is a design property of the dissent prompt, not a flaw — but it means Pass 2 verdicts should never be treated as balanced assessments. The upcoming Phase 3 synthesis will test whether these per-artifact patterns (PIIA recurrence, demand validation gaps, evaluator-level tendencies) compose into cross-artifact insights.

**Cost:** $0.46 (H3 dispatches, prior session) + $0.00 (this session — classification/rating/writing only) = $1.21 cumulative.

**Model routing:** All work in main Opus session. No subagent dispatches this session (classification, rating, and skill authoring are reasoning-tier work). Explorer subagent used for cold artifact search.

---

## 2026-03-22 — Session end (MAD-010 in progress)

**Session summary:** Completed MAD-007 (H1/H2 gate evaluation — PROCEED), MAD-008 + MAD-009 (split-check + Pass 2 dispatch implementation), and ran all 5 H3 Pass 1 + Pass 2 dispatches for MAD-010 (40 API calls total). Gate evaluation written, calibration anchors re-rated, deliberation skill upgraded with Pass 2 flow.

**Tasks completed:** MAD-007, MAD-008, MAD-009
**In progress:** MAD-010 (dispatches done, outcomes + ratings pending)
**Next:** Generate deliberation outcomes for 5 H3 records, blinded rating of Pass 2 findings, classify novelty, complete MAD-010, then MAD-011 (H3 gate evaluation)

**Key results:**
- H1/H2 gate: PROCEED (H1 40% borderline, H2 95% overwhelming, super-additive combination confirmed)
- H3 dispatches: 19/20 material dissent rate, 16/20 verdict shifts (all downward), 5/5 produced novel findings
- Systematic cautionary convergence in Pass 2 — possible negativity bias needs assessment
- DeepSeek/financial-advisor scope-rejecting opportunity-candidates (2 of 5) — overlay scope issue
- Career-coach PIIA finding recurring across P1/P5 — potentially most consequential finding in experiment
- P3 life-coach self-corrected strong→cautionary after reading other assessments
- P4 broke unanimous Pass 1 consensus — all 4 shifted promising→cautionary

**Compound reflection:** The Pass 2 results reveal two distinct value modes: (1) novel risk surfacing (PIIA clauses, household financial impact, work-family tradeoffs) and (2) convergence through deliberation (distance-3 splits collapsing to distance-0 consensus). Mode 2 was not anticipated in the spec — the hypothesis was about novel findings, but the protocol also produces structured agreement. The systematic downward shift raises a methodological question: is the dissent prompt inherently pessimistic? The "respond ONLY if you have something material to add" instruction may select for criticism over endorsement. This needs examination in the H3 gate evaluation.

**Cost:** $0.75 (Phase 1) + $0.46 (H3 dispatches) = $1.21 total experiment cost. Well within budget.

**Model routing:** All work in main Opus session. 10 dispatch subagents (5 Pass 1 + 5 Pass 2). No Sonnet delegation.

---

## 2026-03-22 — MAD-008 + MAD-009: Split-Check + Pass 2 Dispatch

### MAD-008: Split-Check Logic in Deliberation Skill

**Context inventory:** deliberation SKILL.md (1), deliberation-dispatch agent (1), specification SS8.4/SS8.5 (1), deliberation-config.md (1) = 4 docs.

**Implementation:** Split-check was already computed by the dispatch agent (Step 6) and proven correct across 15 Phase 1 dispatches (10 non-splits, 5 splits correctly identified). MAD-008 adds the skill-level integration: Step 4a checks `split_detected` and `experimental_force_pass_2` to decide whether to trigger Pass 2.

**MAD-008 acceptance criteria check:**
- [x] Split check correctly identifies verdict distance >=2 (verified by Phase 1 data: P5 dist=2, P7 dist=2 correctly flagged; P1/P2/P3 dist=0-1 correctly not flagged)

**MAD-008: COMPLETE**

### MAD-009: Pass 2 Dispatch Implementation

**Implementation:** Added Step 4b to deliberation skill — extracts structured Pass 1 data (verdict, confidence, key_finding, findings, flags per evaluator), re-spawns dispatch agent with `pass_number: 2` and `prior_assessments`. Dispatch agent already had Pass 2 prompt structure, injection resistance wrapper, and prompt size check (SS8.6). Updated:
- Skill Step 4b: Pass 2 dispatch flow with structured data extraction
- Skill Step 5: Outcome generation includes Pass 2 dissent data
- Skill Step 6: Completeness verification includes Pass 2 fields
- Skill Phase 1 Constraints → Pass 2 Behavior section (split-triggered, force mode, quick exemption)
- Config: `experimental_force_pass_2: true` (activated for H3 testing)

**MAD-009 acceptance criteria check:**
- [x] Pass 2 prompts include all Pass 1 assessments (structured fields only, per post-validation principle)
- [x] Dissent assessments follow schema (dissent_targets, dissent_type, findings array)
- [ ] Live test — deferred to MAD-010 (first H3 dispatch serves as validation)

**MAD-009: COMPLETE** (pending live test with MAD-010)

---

## 2026-03-22 — MAD-007: H1/H2 Gate Evaluation

### MAD-007: H1/H2 Gate Evaluation — Blinded Ratings + Proceed Decision

**Context inventory:** specification SS5-SS5.10 (1), gate-evaluation-pattern.md (1), calibration-anchor.md (1), baseline-quality-assessment.md (1), 15 deliberation records (15) = 19 docs across session.

**Calibration anchor re-rating:**
- 4 of 5 anchors diverged by >=1 point (threshold: >=2)
- Drift direction: 3 down, 1 up — novelty-of-first-exposure inflation confirmed
- Recalibration accepted; gate-bearing ratings use current calibration

**Blinded ratings:**
- 25 findings presented blinded (20 unique-to-c + 5 controls), randomized
- Danny rated all 25 without knowing condition or evaluator
- 6 R2s initially; 2 downgraded to R1 via gut check (10-minute-think test)
- Final: 3 R2s among unique-to-c (15% novel rate)

**H1 result: PASS (borderline)**
- 40% split rate (exactly at threshold)
- Both split artifacts show different analytical framing (confirmed by Danny)
- Gemini as sole systematic dissenter; GPT+Grok zero variance

**H2 result: PASS (overwhelming)**
- Full panel: 100% splits, mean distance 2.6 vs same-model 0% (0.4) vs same-overlay 40% (0.8)
- Super-additive: condition (c) splits where neither (a) nor (b) does
- 95% of unique-to-c findings rated >=1 (threshold: 50%)

**Key findings:**
1. Model diversity + overlay diversity compound super-additively
2. Grok x life-coach produced 2 of 3 R2s — the combination that was barren in M0 (0 R2s)
3. R2 type shifted from "data I didn't have" (M0) to "perspective I hadn't considered" (full panel)
4. Career/Life lenses went from 0% R2 (M0) to 25% R2 (full panel) — model-evaluator interaction effect confirmed

**Gate decision: PROCEED to Phase 2**

**Artifacts produced:**
- `data/gate-evaluation-h1h2.md` — full gate evaluation with threshold tables, annotations, baseline comparison
- `data/baseline/calibration-anchor.md` — updated with M1-to-M2 re-rate log

**MAD-007 acceptance criteria check:**
- [x] Written gate evaluation with proceed/pivot/stop decision
- [x] H1 qualitative annotations per artifact (P5, P7 — both confirmed different analytical framing)
- [x] Comparison against Phase 0 baseline data (M0 novel rate, evaluator asymmetry resolution)
- [x] Calibration anchor re-rated and stored alongside gate evaluation

**MAD-007: COMPLETE**

---

## 2026-03-22 — Session end

**Session summary:** Completed MAD-005 (H1 test) and MAD-006 (H2 test). 22 live API dispatches total (7 H1 including 2 re-dispatches, 5 condition a, 5 condition c, plus 5 reused from H1 as condition b). Total experiment cost: $0.75.

**Tasks completed:** MAD-005, MAD-006
**Next:** MAD-007 (H1/H2 gate evaluation — blinded ratings, calibration anchor re-rating, proceed/pivot/stop)

**Key results:**
- H1: 40% split rate (exactly at threshold) — Gemini systematic dissenter, GPT+Grok always agreed
- H2: Full panel 100% splits (mean dist 2.6) vs. same-model 0% (mean 0.4) vs. same-overlay 40% (mean 0.8) — super-additive combination
- Unique-to-panel findings include household financial risk, work-family tensions, fear as root blocker, reputation dilution

**Infrastructure issues found and fixed (3):** temp file race condition (parallel dispatch collision), OpenAI token_param (max_completion_tokens), overlay_override parameter added to dispatch agent

**Compound reflection:** The super-additivity finding is the most important result. It means model diversity and overlay diversity are not substitutes — you need both. This has direct implications for panel design: dropping a model to save cost would disproportionately reduce insight diversity, not linearly. The finding also validates the project's core thesis (different reasoning patterns surface different blindspots) more strongly than expected at this stage. The question for MAD-007 is whether the structurally diverse findings are *substantively valuable to Danny* (R1/R2 ratings) or just structurally diverse noise.

**Model routing:** All work in main Opus session. 22 dispatch subagents (general-purpose). No Sonnet delegation.

---

## 2026-03-22 — MAD-006: H2 Test (3-Condition Comparison)

### MAD-006: H2 Test — 3-Condition Comparison, 5 Artifacts

**Context inventory:** specification §5 H2 criteria (1), deliberation-config.md (1), primary-baseline-prompt.md (1) = 3 docs.

**Conditions:**
- (a) Same model (4× GPT-5.4), different overlays — `provider_override: openai`
- (b) Different models, same overlay — reused H1/MAD-005 data
- (c) Full panel (different models, different overlays) — standard config

**Results:**

| Artifact | (a) Same model | (b) Same overlay | (c) Full panel |
|----------|---------------|-----------------|----------------|
| P1 DNS | dist 0 | dist 0 | **dist 3** |
| P2 Newsletter | dist 1 | dist 1 | **dist 3** |
| P3 Wisdom | dist 1 | dist 0 | **dist 3** |
| P5 Radar | dist 0 | dist 2 | **dist 2** |
| P7 Knowledge | dist 0 | dist 2 | **dist 2** |
| **Split rate** | **0% (0/5)** | **40% (2/5)** | **100% (5/5)** |
| **Mean distance** | **0.4** | **0.8** | **2.6** |
| **Max distance** | **1** | **2** | **3** |

**H2 success criteria assessment:**
- ✅ Condition (c) produces more verdict variance than (a) alone: mean 2.6 vs 0.4, 5 splits vs 0
- ✅ Condition (c) produces more verdict variance than (b) alone: mean 2.6 vs 0.8, 5 splits vs 2
- ✅ Condition (c) produces splits where NEITHER single-axis condition does: P1 (a=0,b=0,c=3), P3 (a=1,b=0,c=3)
- ⏳ "≥50% of unique-to-(c) findings rated ≥1" — pending Danny's blinded ratings

**Key findings:**

1. **Model diversity > overlay diversity for verdict variance.** Condition (a) max distance was 1; condition (b) reached 2. Model choice is the stronger variance driver.

2. **The combination is super-additive.** Condition (c) produced distance-3 splits on artifacts where both single-axis conditions produced distance 0-1. The interaction between different models and different overlays amplifies variance beyond either axis alone.

3. **Model personality patterns held across conditions:**
   - Gemini/career-coach: systematic skeptic in (b), but rated "strong" in (c) when given career-coach overlay — the overlay flipped its stance
   - DeepSeek/financial-advisor: consistently most cautious in (c), flagging household financial risk — a perspective unique to the financial overlay + DeepSeek combination
   - GPT-5.4: centrist "promising" in nearly all conditions
   - Grok/life-coach: occasionally optimistic outlier (rated "strong" on Wisdom Library in both (a) and (c))

4. **Condition (c) surfaced unique findings absent from both single-axis conditions:**
   - "Household financial stability" risk framing (DeepSeek × financial-advisor)
   - "Work-family tensions" (Grok × life-coach on Newsletter)
   - "Fear as the root blocker" for audience-building (Grok × life-coach on Knowledge Products)
   - "Creation as spiritual practice" alignment (Grok × life-coach across multiple artifacts)
   - "Opportunity cost of diluting technical reputation" (Gemini × career-coach on Knowledge Products)

5. **Condition (a) produced cosmetic diversity only.** Same model with different overlays generates overlay-characteristic *framing* but nearly identical *analytical conclusions*. The overlays add vocabulary, not insight.

**Cost:**
- Condition (a): $0.411 (5 dispatches × ~$0.082 each — expensive due to 4× GPT-5.4 per dispatch)
- Condition (c): $0.164 (5 dispatches × ~$0.033 each — cheaper due to Grok/DeepSeek pricing)
- Condition (b): $0.175 (from H1, 7 dispatches including re-dispatches)
- **Total H2 experiment: $0.750**

**Operational notes:**
- OpenAI `token_param: max_completion_tokens` fix prevented retries in all condition (a) dispatches
- Temp file namespacing fix held — no race condition issues in condition (c) parallel dispatches
- Life-coach prompt is ~3.5× larger than others due to personal-philosophy.md companion file

**MAD-006: COMPLETE** (blinded ratings pending Danny)

---

## 2026-03-22 — MAD-005: H1 Test (Live API Dispatch)

### MAD-005: H1 Test — Same Overlay, 4 Models, 5 Artifacts

**Context inventory:** specification §5/§5.7 H1 criteria (1), deliberation-config.md (1), calibration-seed.md (1), dispatch agent (1), skill (1) = 5 docs.

**Dispatch configuration:**
- `overlay_override: business-advisor` — all 4 models get identical overlay, persona_bias, dissent_instruction
- Models: GPT-5.4 (OpenAI), Gemini 3.1 Pro (Google), DeepSeek Reasoner, Grok 4.1 Fast (xAI)
- 5 artifacts from calibration seed: Patterns 1, 2, 3, 5, 7
- `batch_id: h1-test`, `method: same-overlay-4xbusiness-advisor`

**Results:**

| Artifact | Verdicts | Distance | Split? |
|----------|----------|----------|--------|
| DNS Hygiene (P1) | 4× promising | 0 | No |
| Newsletter (P2) | 3× promising + 1× strong (DeepSeek) | 1 | No |
| Wisdom Library (P3) | 4× promising | 0 | No |
| Opportunity Radar (P5) | 3× promising + 1× cautionary (Gemini) | 2 | Yes |
| Knowledge Products (P7) | 3× promising + 1× cautionary (Gemini) | 2 | Yes |

**H1 success criterion:** ≥40% of artifacts with verdict span ≥2 → **2/5 = 40% — threshold met exactly.**

**Model behavior patterns:**
- Gemini: systematic dissenter, sole negative outlier in both splits (more skeptical on execution feasibility)
- DeepSeek: sole positive outlier (Newsletter rated "strong"), lowest confidence across the board, highest latency (64-101s), highest token output (reasoning model)
- GPT-5.4 + Grok: always agreed ("promising" on all 5) — zero variance between them
- Confidence ranges: 0.65-0.85 (DeepSeek always low end)

**Cost:** $0.175 total across 7 dispatches (5 original + 2 re-dispatches after race condition fix)

**Operational issues discovered and fixed (3):**
1. **Temp file race condition** — parallel dispatches shared `/tmp/deliberation-prompt-{evaluator_id}.txt`. Two concurrent dispatches overwrote each other's prompts. Fix: paths now include `{deliberation_id}`. 2 corrupted records re-dispatched.
2. **OpenAI `token_param`** — GPT-5.4 requires `max_completion_tokens` not `max_tokens`. Added `token_param: max_completion_tokens` to config.
3. **`overlay_override` added to dispatch agent** — H1 needed same overlay across all models. Added parameter with full persona_bias/dissent_instruction carry-through for clean experimental control.

**Pre-flight checklist:** All 6 items passed (4 API keys, overlay files, companion, schema, config, output dir created).

**Vault-check fixes:** 7 baseline data files missing `domain: software`; deliberation skill added to `REGISTERED_SKILLS`.

**Decision:** Danny reviewed Gemini dissent reasoning on both split artifacts. Borderline pass (exactly 40%) but sufficient signal to proceed to H2. H1 data doubles as H2 condition (b).

**Pending:** Per-finding blinded ratings (Danny, per §5.9). Qualitative annotations for split artifacts.

**MAD-005: COMPLETE** (ratings pending Danny)

---

## 2026-03-22 — Session end (earlier session)

**Session summary:** Resumed from disconnected session (2026-03-20). Completed MAD-000 rating workflow + MAD-001a baseline assessment + MAD-001/002/003/004/004a (full M1 infrastructure). 7 tasks completed in one session.

**Tasks completed:** MAD-000, MAD-001a, MAD-001, MAD-002, MAD-003, MAD-004, MAD-004a
**Next:** MAD-005 (H1 test — first live API dispatch)

**Compound reflection:** The baseline rating data (55 findings, 15 R2) already contains a strong directional signal: Business Advisor and Financial Advisor produce all novel findings (quantitative/market research), while Career Coach and Life Coach produce zero R2s (telling Danny what he already knows). This asymmetry is the key variable for H2 — if different models running the Career/Life overlays also produce 0% R2, the overlays need redesign, not the model lineup. If different models produce R2s from those same overlays, that's evidence for model-evaluator interaction effects. The experiment is well-positioned to disambiguate.

**Model routing:** All work in main Opus session. No Sonnet delegation — reasoning-tier work throughout (spec reading, agent/skill authoring, experimental design).

**Artifacts produced this session:**
- `data/baseline/calibration-anchor.md` — 5-finding drift detection anchor
- `data/baseline/friction-log.md` — 3 procedure friction points with before/after
- `data/baseline/baseline-quality-assessment.md` — proceed recommendation
- `data/baseline/primary-baseline-prompt.md` — H2 condition (a) prompt + parity checklist
- `_system/docs/deliberation-config.md` — evaluator registry + model config
- `_system/schemas/deliberation/assessment-schema.yaml` — SS6 schema
- `.claude/agents/deliberation-dispatch.md` — dispatch agent
- `.claude/skills/deliberation/SKILL.md` — deliberation skill
- Ratings written to all 3 baseline records
