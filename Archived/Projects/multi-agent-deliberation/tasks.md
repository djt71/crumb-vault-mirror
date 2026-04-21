---
project: multi-agent-deliberation
domain: software
type: tasks
skill_origin: action-architect
status: draft
created: 2026-03-18
updated: 2026-03-18
tags:
  - architecture
  - multi-agent
  - experimental
topics:
  - moc-crumb-architecture
---

# Multi-Agent Deliberation — Tasks

## Prerequisite: Spec Amendment Verification

Before any tasks begin, verify that all peer review synthesis findings (CF-1 through CF-5, HF-1 through HF-11) have been applied to the specification. The amended spec is the implementation reference for all tasks below.

**Verification checklist:**
- [ ] §5.9 (Rating Procedure) exists with extract→blind→rate→gut-check→unblind→deduplicate workflow
- [ ] §5.10 (Calibration Anchor) exists with drift detection protocol
- [ ] F5 reclassified as A6 in §2 (model-specific tendencies are hypotheses, not facts)
- [ ] §5.7 gate semantics updated (override requires documented anomaly rationale)
- [ ] H2 claim narrowed to "Initial Panel Configuration" in §5
- [ ] §8.4 clarifies Phase 1 as Pass-1-only
- [ ] `findings` array added to assessment schema in §6
- [ ] H3 terminology aligned to rubric ("rated ≥1" not "useful"/"important")
- [ ] Version tracking fields added to deliberation record format in §10
- [ ] Deliberation outcome generation method specified (lightweight Opus call)
- [ ] §3 second-order effects language softened (no longer says "needs to be designed now")
- [ ] §6.1 verdict scale variants exist
- [ ] `dissent_targets` (array) replaces `dissent_target` (string) in §6
- [ ] §8.5 Failure Semantics exists (min panel 3/4)
- [ ] §8.6 Prompt Size Limits exists (30K cap, summarization fallback)
- [ ] Appendix A evidence citations exist

## Milestone 0: Baseline & Rating Procedure

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| MAD-000 | Develop and test rating procedure (§5.9) on 2-3 warm artifacts from Scout calibration seed. Run single-Opus combined-prompt baseline. Practice full extract→blind→rate→gut-check→unblind→deduplicate workflow. Establish calibration anchor set (5 findings). | todo | — | Low | #research | Rating procedure tested on ≥2 artifacts. ≥3 friction points documented with before/after procedure adjustments. Calibration anchor set of 5 findings with ratings stored in a dedicated file. |
| MAD-001a | Run single-Opus baseline on 3-5 warm artifacts with all 4 overlays in one prompt. Rate findings per refined §5.9 procedure (using §5.6 rubric). Write baseline quality assessment. | todo | MAD-000 | Low | #research | 3-5 baseline assessments completed. Per-finding ratings recorded. Baseline quality summary includes: artifact list, finding counts, rating distribution (R0/R1/R2 counts), top 3 strengths, top 3 gaps, and explicit proceed/reassess recommendation with rationale. |

## Milestone 1: Infrastructure + H1/H2

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| MAD-001 | Create `_system/docs/deliberation-config.md` with evaluator registry, model mappings, per-model `max_context_tokens`, panel defaults, verdict scale variants, and retry config. | todo | MAD-001a (gate pass) | Low | #code | Config file exists. All 4 providers configured with model, endpoint, env_key, max_tokens, max_context_tokens. Evaluator registry maps 4 roles to providers + overlays. Default panel and depth set. |
| MAD-002 | Create `_system/schemas/deliberation/assessment-schema.yaml` with all §6 fields including `findings` array, verdict scale variants (§6.1), and `dissent_targets` (array). | todo | MAD-001a (gate pass) | Low | #code | Schema file exists. Valid YAML. All fields from §6 present including findings array with claim+domain structure. |
| MAD-003 | Build deliberation dispatch agent (`.claude/agents/deliberation-dispatch.md`). Adapt peer-review-dispatch: new prompt assembly (overlay + persona_bias + assessment schema + sensitivity classification), concurrent 4-model dispatch with 0-2s random stagger, response collection, version tracking (overlay/config/model hashes), `model_string_returned` capture from API response. | todo | MAD-001, MAD-002 | Medium | #code | Agent dispatches to 4 models concurrently. Responses collected with per-evaluator metadata (http_status, latency, attempts, raw_json). Sensitivity check runs before dispatch. Random stagger present. Version tracking fields populated. Handles ≥1 provider failure gracefully (min panel 3/4). Simulated provider failure test passes (mock one provider timeout, skill completes with 3 assessments). |
| MAD-004 | Build deliberation skill (`.claude/skills/deliberation/SKILL.md`). Accepts brief, runs sensitivity check, orchestrates Pass 1 dispatch, writes deliberation record with version_tracking and ratings capture format, generates deliberation outcome via lightweight Opus call. Phase 1 = Pass-1-only (no split check). | todo | MAD-003 | Medium | #code | Skill accepts a deliberation brief. Sensitivity classification runs. Dispatch executes. Deliberation record written to `Projects/multi-agent-deliberation/data/deliberations/`. Record includes all frontmatter fields (§10) and Deliberation Outcome section. Rating capture YAML block present (empty, ready for Danny's ratings). Per-evaluator cost fields populated (prompt_tokens, completion_tokens, estimated_cost_usd). |
| MAD-004a | Develop and document primary baseline prompt for H2 condition (a): 4 GPT-5.4 calls with separate overlays. Ensure prompt parity with full panel (same structure, comparable word count, schema-compliant output). Build from config (overlay paths, model params) to ensure parity. Test on 1-2 warm-up artifacts. | todo | MAD-001a (gate pass), MAD-001, MAD-002 | Low | #research | Primary baseline prompt documented. Tested on ≥1 artifact. Output follows assessment schema. Prompt structure matches panel prompt (separate overlay per call, same instructions). |
| MAD-005 | Run H1 test: same overlay (Business Advisor), 4 models, 5 warm artifacts. Measure verdict distribution and reasoning divergence. Rate findings per §5.9 (blinded). Write H1 qualitative annotations per artifact. | todo | MAD-004 | Low | #research | 5 deliberation records exist. Verdict distributions documented. Per-finding ratings recorded (blinded). Qualitative annotation for each artifact where verdict variance ≥2. |
| MAD-006 | Run H2 test: 3-condition comparison on 5 warm artifacts. Condition (a): 4 GPT-5.4 with different overlays. Condition (b): 4 models with Business Advisor overlay. Condition (c): full panel. Include primary baseline comparison. Rate all findings blinded. | todo | MAD-004, MAD-004a | Medium | #research | 15 deliberation records (3 conditions × 5 artifacts). Condition (c) produces more unique findings than condition (a) alone AND condition (b) alone. ≥50% of unique-to-(c) findings rated ≥1 per §5.6 rubric. Per-finding ratings recorded (blinded). Comparison against Phase 0 baseline data documented. |
| MAD-007 | H1/H2 gate evaluation. Re-rate calibration anchor set. Write gate evaluation document with: threshold results, qualitative annotations, baseline comparison, proceed/pivot/stop decision with rationale. | todo | MAD-005, MAD-006 | Low | #decision | Written gate evaluation exists. Calibration anchor re-rated (drift check). Gate evaluation includes threshold results table with pass/fail per criterion. H1: verdict variance ≥2 points for ≥40% of artifacts. H2: condition (c) produces more unique findings than (a) alone AND (b) alone; ≥50% of unique-to-(c) findings rated ≥1 (≥1 is intentional — H2 tests non-trivial value, not breakthrough novelty; that's H5's job). Decision documented with evidence. If override, anomaly rationale recorded per §5.7. |

## Milestone 2: Dissent + H3

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| MAD-008 | Implement split-check logic in deliberation skill. Map verdicts to 0-4 scale. Split = max-min ≥ 2. Handle partial panels (3/4 evaluators). Add `experimental_force_pass_2` config flag. | todo | MAD-007 (gate pass) | Low | #code | Split check correctly identifies verdict distance ≥2. Partial panel (3/4) handled. Force-Pass-2 flag overrides split check when set. |
| MAD-009 | Implement Pass 2 dispatch. Assemble Pass 2 prompts: prior Pass 1 assessments wrapped with inter-agent injection resistance + overlay + dissent_instruction. Respect per-model max_context_tokens. Implement §8.6 prompt size limits (30K cap, summarization fallback). Tag `pass_2_truncated` in record. | todo | MAD-008 | Medium | #code | Pass 2 prompts include all Pass 1 assessments with injection wrapper. Prompt size respects per-model limits. Truncation fallback works. `pass_2_truncated` flag set correctly. Dissent assessments follow schema with `dissent_targets` array. |
| MAD-010 | Run H3 test: 5-7 deliberations with `experimental_force_pass_2: true`. Mix of warm and cold artifacts. Rate Pass 2 findings separately. Classify each Pass 2 finding as: new claim, strengthened claim, corrected claim, or non-novel response. Measure incremental value of Pass 2 over Pass 1. | todo | MAD-009 | Low | #research | 5-7 deliberation records with Pass 2 data. Pass 2 findings rated separately with novelty classification (new/strengthened/corrected/non-novel). Novel Pass 2 finding count documented per deliberation. |
| MAD-011 | H3 gate evaluation. Re-rate calibration anchor set. Write gate evaluation with H3 threshold assessment, proceed/simplify/stop decision. | todo | MAD-010 | Low | #decision | Written gate evaluation exists. Calibration anchor re-rated. Gate evaluation includes threshold results table (H3: ≥30% novel Pass 2, ≥50% of novel findings rated ≥1). Decision documented with evidence. |
| MAD-012a | Source and validate ≥10 cold artifact candidates from Scout/FIF/active projects. Confirm novelty (not used in M0/M1/M2). Write `batch-manifest-candidates.md` with artifact paths, types, and provenance. *(Runs concurrently with M2 dissent work; gate dependency is M1, not M2.)* | todo | MAD-007 (gate pass) | Medium | #research | `batch-manifest-candidates.md` exists with ≥10 candidate artifacts. Each candidate has path, type, source pipeline, and novelty confirmation. |

## Milestone 3: Synthesis + H4

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| MAD-012 | Implement synthesis engine in deliberation skill. Structured extraction (verdicts, flags, findings, evaluator IDs) from batch records into dataset. Opus analysis prompt for pattern detection. Evaluator diagnostics (mechanical computation). Batch manifest with planned artifact list and completion tracking. | todo | MAD-011 (gate pass) | Medium | #code | Synthesis reads all records in a batch. Structured data extracted correctly. Opus analysis produces synthesis output schema (§9.2). Evaluator diagnostics computed. Batch manifest enforced (all planned artifacts must complete before synthesis). |
| MAD-013 | Run H4 test: define batch manifest with 5-10 cold artifacts from MAD-012a candidate pool. Run deliberations on all. Run synthesis. Danny evaluates synthesis patterns. | todo | MAD-012, MAD-012a | Low | #research | Batch manifest defined from MAD-012a candidates. All batch deliberations complete. Synthesis output exists with ≥1 pattern identified. Danny's evaluation includes novelty/actionability/non-obviousness rating per synthesis pattern. |
| MAD-014 | H4 gate evaluation. Write gate evaluation with H4 threshold assessment, framework validation decision. | todo | MAD-013 | Low | #decision | Written gate evaluation exists. Gate evaluation includes threshold results table (H4: ≥2 actionable patterns, ≥1 leading to action). Decision documented: framework validated / per-artifact only / archive. |

## Milestone 4: Meta-Evaluation

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| MAD-015 | H5 meta-evaluation. Compile all experimental data: deliberation records, ratings, costs, novel insight counts, actions triggered. Re-rate calibration anchor set (final drift check). Answer "Would I use this weekly?" checkpoint. | todo | MAD-014 | Low | #decision | Written assessment against H5 criteria. R2 finding count across all phases. Action count. Calibration anchor final re-rating. "Weekly practice" qualitative answer documented. |
| MAD-016 | Write experimental results summary and integration recommendation. If integrate: scope the integration project and `related_projects` links. If iterate: what to change and re-test. If archive: document learnings. | todo | MAD-015 | Low | #writing | Clear recommendation document exists: integrate (with scope), iterate (with direction), or archive (with learnings). |

## Task Summary

| Milestone | Tasks | Code | Research | Decision | Writing |
|---|---|---|---|---|---|
| M0: Baseline | 2 | 0 | 2 | 0 | 0 |
| M1: Infrastructure + H1/H2 | 8 | 4 | 3 | 1 | 0 |
| M2: Dissent + H3 + Cold Prep | 5 | 2 | 2 | 1 | 0 |
| M3: Synthesis + H4 | 3 | 1 | 1 | 1 | 0 |
| M4: Meta-Evaluation | 2 | 0 | 0 | 1 | 1 |
| **Total** | **20** | **7** | **8** | **4** | **1** |

## Dependency Graph

```
M0: MAD-000 ──▶ MAD-001a ══gate══╗
                                  ║
M1: MAD-001 ◀══════════════════════╣
    MAD-002 ◀══════════════════════╝
    MAD-001 + MAD-002 ──▶ MAD-003 ──▶ MAD-004 ──▶ MAD-005
    MAD-001 + MAD-002 ──▶ MAD-004a (parallel with MAD-003/004)
    MAD-004 + MAD-004a ──▶ MAD-006
    MAD-005 + MAD-006 ──▶ MAD-007 ══gate══╗
                                          ║
M2: MAD-008 ◀═════════════════════════════╣
    MAD-012a ◀════════════════════════════╝ (cold artifact sourcing, concurrent with M2)
    MAD-008 ──▶ MAD-009 ──▶ MAD-010 ──▶ MAD-011 ══gate══╗
                                                         ║
M3: MAD-012 ◀════════════════════════════════════════════╝
    MAD-012 + MAD-012a ──▶ MAD-013 ──▶ MAD-014 ══gate══╗
                                                        ║
M4: MAD-015 ◀═══════════════════════════════════════════╝
    MAD-015 ──▶ MAD-016
```

Notes:
- MAD-004a runs in parallel with MAD-003/MAD-004 (depends on gate + config + schema, not on the skill)
- MAD-006 needs both the dispatch infrastructure (MAD-004) and the baseline prompt (MAD-004a)
- MAD-012a runs concurrently with M2 dissent tasks (gate dependency is M1, not M2)

## Risk Register

| Risk | Level | Mitigation |
|---|---|---|
| Baseline is already strong enough (M0 gate kills project) | Low | This is a valid outcome — $1-3 to learn is excellent ROI |
| Dispatch agent adaptation takes longer than expected (MAD-003) | Medium | Peer-review-dispatch is a proven pattern; adaptation not greenfield |
| Provider API failures during test runs | Medium | Min panel 3/4; retry policy; incomplete deliberation handling |
| Insufficient cold artifacts for Phase 3 | Medium | Start collecting candidates from live pipelines early; can supplement with architectural questions from active projects |
| Rating drift across phases | Low | Calibration anchor set re-rated at every gate boundary |
| Pass 2 prompt growth degrades model output quality | Medium | §8.6 prompt size limits with summarization fallback; per-model max_context_tokens |
| Cost exceeds budget | Low | Per-deliberation tracking + $2.00 abort criterion; Phase 0 and Phase 1 gates kill before major spend |
| Baseline prompt mismatch makes panel appear better unfairly | Medium | MAD-004a prompt parity checks; schema parity; comparable token budgets; pilot test before H2 |
