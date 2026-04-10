---
type: action-plan
domain: software
project: researcher-skill
status: active
created: 2026-02-27
updated: 2026-02-27
skill_origin: action-architect
---

# Researcher Skill — Action Plan

## Implementation Overview

The researcher skill is a stage-separated research pipeline operating within the Crumb dispatch framework (CTB-016). Implementation builds from data infrastructure outward through pipeline stages, with each milestone representing a meaningful integration checkpoint. 18 tasks across 7 milestones (6 active + 1 deferred).

**Architecture reminder:** Each pipeline stage runs as a separate `claude --print` invocation. "Implementing a stage" means designing its prompt template, defining its output schema, and specifying its handoff contract — not writing traditional application code. The dispatch runner (bridge infrastructure) handles orchestration.

**Live deployment iteration budget:** Per `_system/docs/solutions/claude-print-automation-patterns.md` Pattern 4, budget 3-6 iterations for the first live test of each milestone. Each iteration calibrates the prompt-model contract. This is expected, not a failure.

**Runner vs model computation boundary (Pattern 1):** The dispatch runner handles deterministic computations: `content_hash` (SHA-256), handoff byte measurement, 8KB overflow detection, `dispatch_id`/`stage_number` injection. The model handles judgment-dependent work: source classification, evidence extraction, convergence assessment. Token overlap for quote verification (RS-007) uses a defined algorithm (see RS-007 acceptance criteria), executed by the model with normalized input.

## Milestone 1: Skill Definition + Data Infrastructure

**Goal:** Skill loads correctly, fact ledger and handoff I/O work, file structure defined.

**Success criteria:**
- SKILL.md loads and matches activation signals
- Fact ledger YAML can be created, appended, read, and superseded
- Handoff serialization round-trips correctly within 8KB limit
- Overflow fallback triggers at 7KB soft threshold

**Tasks:** RS-001, RS-005

**Risk:** Low — foundational work with no external dependencies beyond CTB-016 (already built).

### Phase 1.1: Skill Definition
RS-001 creates the skill's identity, context contract, and procedure skeleton.

### Phase 1.2: Data Layer
RS-005 builds the fact ledger and handoff schema I/O that every subsequent stage depends on.

## Milestone 2: Input Stages + Vault Input

**Goal:** Research briefs are validated, enriched with vault knowledge, and decomposed into actionable research plans.

**Success criteria:**
- Scoping stage validates a brief, produces refined scope with ≥1 inclusion and ≥1 exclusion
- Vault knowledge queried during scoping — scope output includes `vault_coverage` with note/source counts
- Planning stage decomposes into ≥2 sub-questions with convergence criteria
- Scoping → Planning handoff chain validates: Planning accepts Scoping's handoff without repair
- Handoff with ≥3 sub-questions + vault coverage remains under 8KB or triggers overflow correctly
- All stages write handoff snapshots and research status file

**Tasks:** RS-002, RS-012, RS-003

**Dependencies:** Milestone 1 complete.

**Risk:** Medium — Planning stage's convergence criteria design determines Research Loop behavior. Poor decomposition = wasted search iterations (Lever 3 from spec).

### Phase 2.1: Scoping Stage
RS-002 builds the first pipeline stage: brief validation, scope refinement, initial vault awareness.

### Phase 2.2: Vault Input
RS-012 enhances Scoping to query vault knowledge notes and source indices for baseline coverage. Integrated early so M3 Research Loop testing benefits from vault-aware scoping.

### Phase 2.3: Planning Stage
RS-003 builds sub-question decomposition, search strategy, and convergence threshold configuration from rigor profiles.

## Milestone 3a: Research Loop + Failure Handling

**Goal:** Research Loop populates a fact ledger from web sources and handles ingestion failures gracefully.

**Success criteria:**
- Research Loop searches web, scores sources by tier, stores FullText content
- Fact ledger populated with entries having all required fields (claim_key, stance, confidence)
- Garbage results skipped, paywalled sources classified, timeout cascades degraded gracefully
- Research status file updated with degradation notes when failures occur
- Stage N output validates against handoff schema; stage N+1 accepts without repair

**Tasks:** RS-004, RS-009

**Dependencies:** Milestone 2 complete, plus RS-005 (ledger I/O).

**Risk:** Medium-High — first live validation of web search → ledger population. Source quality variance and tool limitations (WebSearch/WebFetch only) are first-time risks. RS-009 is included here (moved from Evidence Verification) because the Research Loop encounters timeouts, paywalls, and garbage results during live testing — without failure handling, M3a testing is brittle.

### Phase 3a.1: Research Loop Stage
RS-004 implements the main research execution: web search, source scoring, content storage, ledger population.

### Phase 3a.2: Failure Handling
RS-009 handles garbage results, rate limiting, timeout cascades, and paywall classification. Writes partial telemetry snapshots for dispatches that fail before reaching the output pipeline.

## Milestone 3b: Convergence + Loop Control + Escalation

**Goal:** Research Loop terminates on convergence or budget, and handles escalation conditions when they arise.

**Success criteria:**
- Convergence scoring formula produces per-sub-question scores
- Loop terminates at convergence threshold, diminishing returns, or max_research_iterations
- All 4 escalation gate types trigger correctly during research
- End-to-end: Scoping → Planning → Research Loop(s) → converged ledger (with escalation + failure handling)
- All stage handoff snapshots and research status updates generated and inspectable

**Tasks:** RS-006, RS-010, RS-011

**Dependencies:** Milestone 3a complete. RS-011 depends only on RS-001 and can be built in parallel with RS-006.

**Risk:** Medium — convergence weight calibration is first-time validation but builds on a working Research Loop from M3a. Pattern 4 (live iteration budget) applies. Escalation is included here so paywall/scope issues encountered during convergence testing have a handler.

### Phase 3b.1: Convergence Scoring
RS-006 implements the two-tier convergence check (minimum bar + weighted formula) with rigor profile support.

### Phase 3b.2: Loop Control
RS-010 implements runaway loop detection via diminishing returns and max_research_iterations enforcement.

### Phase 3b.3: Escalation Gates
RS-011 implements the 4 researcher-specific escalation types (scope, access, conflict, risk) consuming CTB-016's gate framework. Writes partial telemetry snapshots for dispatches that escalate before reaching the output pipeline.

## Milestone 4: Evidence Integrity

**Goal:** Fact ledger entries are verified against stored source content; writing validation rules defined.

**Success criteria:**
- Citation Verification stage checks quote_snippet against stored content using defined algorithm
- Over-confidence (verified + non-FullText) detected and corrected via supersede
- Writing Validation defines [^FL-NNN] citation format and 4 mechanical checks
- RS-007 and RS-008 run as parallel tracks (no sequential dependency between them)
- Stage output validates against handoff schema

**Tasks:** RS-007, RS-008

**Dependencies:** RS-007 depends on RS-004 + RS-005. RS-008 depends on RS-005. Both dependencies satisfied after M3a, so RS-007 and RS-008 are parallel within M4. RS-008's dependency is on the ledger schema (RS-005), not on verification (RS-007) — the validation rules are defined against the schema, not against verified data.

**Risk:** Medium — Citation Verification's normalized matching logic (whitespace collapse, ≥80% token overlap) needs live calibration against real WebFetch extraction artifacts.

### Phase 4.1: Citation Verification Stage (RS-007)
Quote verification, confidence audit, supersede corrections. Parallel with Phase 4.2.

### Phase 4.2: Writing Validation Rules (RS-008)
[^FL-NNN] citation format and 4 enforcement checks (coverage, resolution, source chain, orphan detection). Depends on ledger schema (RS-005), not on verification. Parallel with Phase 4.1.

## Milestone 5: Output Pipeline + Vault Output

**Goal:** Evidence is cross-referenced into structured findings, a cited deliverable is produced, and results are routed to vault with telemetry captured.

**Success criteria:**
- Synthesis maps all claims to ledger entries
- Contradiction clusters surfaced per claim_key with stance-weighted analysis
- Writing produces deliverable using only [^FL-NNN] citations from verified ledger
- Writing Validation passes all 4 checks (coverage, resolution, source chain, orphan detection)
- Deliverables written to vault with valid frontmatter; vault-check passes
- Dispatch telemetry captured (sources per tier, iterations, quality ceiling frequency)
- Full end-to-end: Scoping → ... → Writing → vault output produces a research note

**Tasks:** RS-013, RS-014, RS-015

**Dependencies:** Milestone 3b complete (RS-010 — converged ledger for synthesis), Milestone 4 complete (RS-007 — verified ledger for writing, RS-008 — writing validation rules).

**Risk:** Medium — Synthesis is where evidence quality becomes visible. Writing is where the write-only-from-ledger discipline is tested mechanically. The Writing Validation checks are the primary hallucination prevention gate (Lever 5 from spec). Vault output must comply with file conventions.

### Phase 5.1: Synthesis Stage
RS-013 builds cross-referencing, contradiction clustering, and confidence rollup. Depends on converged ledger (RS-006 + RS-010), not on verification (Synthesis runs before Citation Verification in the pipeline).

### Phase 5.2: Writing Stage
RS-014 builds deliverable production with citation enforcement and Writing Validation. Depends on Synthesis (RS-013), verified ledger (RS-007), and writing validation rules (RS-008).

### Phase 5.3: Vault Output + Telemetry
RS-015 routes deliverables to vault locations, creates source indices, and captures dispatch telemetry.

## Milestone 6: MCP Source Tools (Deferred)

**Goal:** Replace WebSearch/WebFetch with structured MCP tools for higher-quality source access.

**Deferred until:** V1 pipeline validated with built-in tools. MCP tool availability determines timeline.

**Activation criteria:** Consider starting after 5+ live dispatches with >20% ToolLimited source classification rate, indicating built-in tools are a meaningful quality bottleneck.

**Tasks:** RS-016, RS-017, RS-018

**Dependencies:** Milestone 3a complete (RS-004 — Research Loop exists to integrate with).

## Cross-Cutting Concerns

### Observability (all stage tasks)
Every stage implementation must write:
- Handoff snapshot to `research/handoff-snapshots/[dispatch]/stage-[N]-[name].yaml`
- Research status update to `research/research-status-[dispatch].md`

### Prompt Template Design (§3.9)
Each stage task includes designing its prompt template — the system/user prompt content that the dispatch runner sends to `claude --print`. This was deferred from SPECIFY to PLAN/IMPLEMENT.

### Runner Integration
All stages consume CTB-016's dispatch runner. Stage output must conform to the runner's expected schema (§4.3 of dispatch-protocol.md). Per automation patterns (Pattern 1), the runner injects deterministic fields post-output.

## Dependency Graph

```
RS-001 ──┬──▶ RS-005 ──────────────────────────┐
         │                    │                 │
         │                    ├──▶ RS-008 (M4) ─┤
         │                    │                 │
         ├──▶ RS-002 ──▶ RS-012 ──▶ RS-003 ──▶ RS-004 ──┬──▶ RS-006 ──▶ RS-010 ──▶ RS-013 ──┐
         │                                      ↗   │     │                                    │
         │                          (RS-005 merges)  │     │                                    │
         │                                           │     │              RS-013 + RS-007 + RS-008
         ├──▶ RS-011 (parallel, merges at M3b)       │     │                        │
         │                                           │     │                        ▼
         │                                     RS-009│     ├──▶ RS-007 (M4) ──▶ RS-014 ──▶ RS-015
         │                                     (M3a) │     │                    ↗
         │                                           └─────┘         RS-008 ──┘
```

**Milestones:**
- M1: RS-001, RS-005
- M2: RS-002, RS-012, RS-003
- M3a: RS-004, RS-009
- M3b: RS-006, RS-010, RS-011
- M4: RS-007 ∥ RS-008 (parallel — no dependency between them)
- M5: RS-013, RS-014, RS-015

**Critical path:** RS-001 → RS-002 → RS-012 → RS-003 → RS-004 → RS-006 → RS-010 → RS-013 → RS-014 → RS-015
(10 tasks. RS-005 parallel with M2, merges at RS-004. RS-009 parallel with RS-004 in M3a. RS-011 parallel from M1. RS-007 ∥ RS-008 parallel in M4, both merge at RS-014.)
