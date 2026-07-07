---
type: run-log
project: akm-refresh
domain: software
status: active
created: 2026-07-07
updated: 2026-07-07
topics:
  - moc-crumb-architecture
tags:
  - run-log
---

# akm-refresh — Run Log

## 2026-07-07 — Project creation

**Trigger:** Same-day chain: qmd 2.0.1 → 2.5.3 upgrade (new embedding model, full re-embed) → operator-requested investigation of information surfacing → provenance sweep (AKM design docs recovered from git `d482332b~1`) → AKM evaluation with AKM-EVL re-run. The re-run found the March 2026 mode tuning inverted at current corpus scale. Operator approved project creation ("create akm-refresh and commit").

**Evidence base (R1 — complete before project creation):**
- `_system/docs/akm-evaluation-2026-07.md` — evaluation, findings, recommendations R1–R6
- `_system/docs/operator/explanation/information-surfacing-provenance.md` — mechanism history, decision graveyard
- `_system/data/akm/bench-fixture.json` — 12-query regression fixture, baseline 2026-07-07 (bm25 recall@5 0.34 · vector 0.64 · hybrid 0.60 · full 0.70)
- `_system/data/akm/evl-rerun-2026-07-07.json` + `evl-rerun-harness.py` — raw results + method

**Headline findings driving scope:**
1. BM25 (the live skill-activation mode) collapsed at 1,701-doc scale: within-domain 71% → 43%. Semantic/hybrid improved substantially on embeddinggemma (hybrid within-domain 100%).
2. Hybrid CLI latency 4.8s busts the 2s hook SLO, but in-process search is 3–144ms — process startup dominates; `qmd mcp --http --daemon` (new in 2.5) is the latency lever to evaluate.
3. Min-score alone cannot separate noise (distributions overlap; hybrid reranker scores noise 0.88–0.93). Noise control = accept-empty + structured queries replacing the groups-of-3 splitting hack (which manufactured the Herodotus false positive) + score-0 drop.
4. new-content trigger is behavioral and dormant (15 fires lifetime, 0 recent) — fourth behavioral-vs-automated instance.
5. Consumption measurement still unsolved; blocks chronic-miss suppression re-enable. Hook-based read-tracking is now the proposed mechanism (positive-only evidence semantics).

**Scope (from evaluation recommendations):**
- R2 — precision-trigger fix: mode flip, accept-empty floor, kill splitting hack, drop score-0, daemon latency evaluation
- R3 — consumption-tracking hook (new primitive — operator approval at design)
- R4 — new-content hook (new primitive — operator approval at design; coordinate with VO-037 CLAUDE.md slim-down)
- R5 — populate query_hints in skill-preflight-map.yaml
- Out of scope: R6 serendipity revival (original decision rule: reduce cost or drop); decay-constant retuning (blocked on R3 data); chapter-digest indexing (blocked on R3 data)

**Operator decisions at creation:**
- Project name/domain confirmed: akm-refresh / software
- Toolchain upgrades executed same-day (items 1–5 + Ollama upgrade); node major held
- Vault-only project — external repo gate skipped

**Context inventory (creation session):** knowledge-retrieve.sh (full read), skill-preflight.sh (full read), skill-preflight-map.yaml, akm-feedback.jsonl (stats), recovered qmd-mode-evaluation.md + qmd-tuning-decisions.md (git), qmd 2.5 bench source (types + scoring), live retrieval test + 15-query re-run.

**Next:** SPECIFY — systems-analyst specification. Key design questions: (a) which mode/structured-query shape for skill-activation within 2s SLO — CLI vs daemon; (b) accept-empty floor semantics per mode; (c) R3 hook event shape + feedback-log schema extension (positive-only); (d) R4 detection mechanics (Write/Edit PostToolUse, `#kb/` tag sniff) + VO-037 handoff.

## 2026-07-07 — SPECIFY: specification authored

**Context inventory (systems-analyst invocation):**
1. `_system/docs/akm-evaluation-2026-07.md` — R1 evidence base (full read)
2. `_system/docs/operator/explanation/information-surfacing-provenance.md` — decision graveyard, constraints (full read)
3. `_system/docs/solutions/behavioral-vs-automated-triggers.md` — prior art for R3/R4 hook design + enforcement mechanism map (full read)
4. `_system/docs/solutions/live-soak-beats-benchmark.md` — prior art: fixture = filter, soak = verdict; shapes acceptance criteria (full read)
5. `_system/data/akm/bench-fixture.json` — baseline numbers (header)

Budget: 5 docs (standard tier ceiling; justification: two prior-art patterns directly govern R2 acceptance and R3/R4 design). Budget-exempt: overlay index (no overlay matched — Crumb system infra), signal scan (2 of 30 `kb/software-dev` Sources/ notes read after keyword-intersection gate: `brief-mcp-feasibility.md`, `pointer-based-context-retrieval.md`), targeted greps of `knowledge-retrieve.sh` / `skill-preflight-map.yaml` for implementation grounding (mode routing at line 303, splitting at 322, empty query_hints confirmed).

**Clarifying questions:** none blocking — creation-session operator decisions + R1 evidence cover the skill's five standard unknowns (problem, audience, success, constraints, risk tolerance). Recorded in spec §Facts.

**Delivered:**
- `specification.md` — 9 facts / 6 assumptions (each with validation point) / 5 unknowns; system map with 7 constraints incl. C7 (trigger roles settled — retune modes, don't redesign roles); 7 measurable success criteria; 9 tasks AKM-001…009 with dependency spine 001→002→003→{004,009}, R3/R4 designs parallelizable, implementations after AKM-003
- `specification-summary.md`
- `cross-project-deps.md` XD-028: VO-037 must not delete the CLAUDE.md signal-scan paragraph until the R4 hook is live
- project-state `next_action` updated

**Decisions embedded in spec:** success bar = fixture recall@5 ≥ 0.64 + within-domain ≥ 71% + ≤2s warm p95 + N3 empty; live-soak-beats-benchmark applied as acceptance shape (fixture filters, 2-week soak decides); daemon adoption gated on AKM-001 spike with degrade-to-CLI fallback required.

**Compound candidates (defer to SPECIFY→PLAN checkpoint):** (a) fourth behavioral-vs-automated instance (new-content trigger) → add to solutions doc evidence once R4 fixes it; (b) "accept-empty removes the pressure that makes overlapping score distributions dangerous" — possible general pattern for retrieval noise gates.

**Overlay check:** no match (Crumb system infra — Network Skills anti-signal). Signal scan: 30 kb/software-dev Sources/ notes; keyword gate → read `brief-mcp-feasibility.md` (2026-03 research question predates qmd 2.5 daemon — context only) and `pointer-based-context-retrieval.md` (validates hook-injection architecture; no scope change).

**Spec scope assessment:** MAJOR (two new primitives + live retrieval path changes) → peer review recommended before PLAN. Operator decision pending.

## 2026-07-07 — SPECIFY: peer review round 1

**Dispatch:** full mode, 4 reviewers; 3 succeeded (gpt-5.4 37.1s, gemini-3.1-pro 45.5s, grok-4.3 16.5s), DeepSeek failed (2× curl timeout at 120s — v4-pro thinking-mode exceeds ceiling on artifacts this size; per-reviewer timeout bump flagged as A10, operator call). Safety gate clean. Review note: `reviews/2026-07-07-specification.md` (synthesis appended).

**Outcome:** unanimous proceed-to-PLAN after targeted revision — intervention logic unchallenged; findings concentrate on acceptance precision and missing contingencies. 10 action items: A1–A2 must-fix (SLO/fallback viability decision rule — Gemini's ~2.7s end-to-end arithmetic for CLI semantic fallback holds as upper bound; explicit all-of acceptance matrix + recall@3 vs budget-3 mismatch), A3–A9 should-fix (A4/U3 contingency, U5 gate, AKM-010 soak-execution task, R3 linkage model, R4 trigger semantics + VO-037 overlap-window qualifier, noise-flag operationalization, provenance pass), A10 defer (DeepSeek timeout config). 4 findings declined with reasons (GRK-F2/F5/F8, OAI-F5-fix-as-stated).

**Best unique catches:** GEM-F2 (fixture recall@5 counts rank-4/5 hits the budget-3 brief never surfaces), OAI-F11 (SC7 requires a soak no task executes), GRK-F6 (hook + behavioral paragraph both live until VO-037 deletes — double-surfacing window).

**Grok calibration watch CLOSED (review 3/3):** 0 fabrications across all three reviews; verdict keep. Tally + residual handling (distrust GRK CRITICALs, weight its unique MINORs) recorded in peer-review-config.md.

## 2026-07-07 — SPECIFY: review fixes applied (A1–A9), cycle closed

Operator: "apply the fixes, no round 2 or three." All nine action items applied to `specification.md` in one revision pass; A10 (DeepSeek timeout bump) left as operator call, not applied.

- **A1:** AKM-001 now profiles end-to-end (wrapper-entry to brief-emit, splitting disabled) and confirms daemon flags from local `--help`; A1 assumption text carries the ~0.8s wrapper-overhead arithmetic; M6 viability rule added — no passing combination → design exception, AKM-003 does not proceed.
- **A2:** Success criteria 1–3 replaced with all-of matrix M1–M6; gate metric moved to recall@3 (baselines to be measured in AKM-001) + brief-level top-3 check (M3); semantic≡vector + "full" terminology note added to F7.
- **A3:** A4 contingency (clean descope of R3/R4 by amendment) added to the assumption and both design tasks.
- **A4:** U5 empty-brief tolerance now a tested precondition in AKM-002 acceptance.
- **A5:** AKM-010 (execute + close soak) added; criterion 7 maps to it; task count 9 → 10.
- **A6:** Minimal linkage model normative in AKM-005 (note path + session + timestamp + surfacing-event ID when resolvable, bounded window).
- **A7:** Normative R4 trigger semantics in AKM-007 (tag-present-on-save, path debounce, self-trigger exclusion, no fire on renames); SC4 qualified with the VO-037 overlap window; XD-028 updated.
- **A8:** Soak noise flag operationalized (run-log convention; fail = any manufactured-fragment recurrence or ≥3 confirmed irrelevant surfacings); <50ms hook bar now end-to-end p95 warm on both paths.
- **A9:** Provenance/editorial pass — metrics date-stamp + revision note in Evidence Base, Workstreams key (R1–R6), Herodotus/C5 clarification in F4, rollback rephrase, AKM-009 → AKM-002 wording, qualitative acceptance phrases tightened.

`specification-summary.md` synced. Review cycle closed at round 1 per operator. **Next:** operator spec approval → Phase Transition Gate (context-checkpoint-protocol, incl. compound evaluation) → PLAN via action-architect.

### Phase Transition: SPECIFY → PLAN
- Date: 2026-07-07 14:10
- SPECIFY phase outputs: `specification.md` (peer-reviewed round 1, A1–A9 applied, operator-approved), `specification-summary.md`, `reviews/2026-07-07-specification.md` (+ raw/), XD-028 in `cross-project-deps.md`, Grok watch closure in `peer-review-config.md`
- Goal progress: all SPECIFY quality-checklist criteria met (problem statement; facts/assumptions/unknowns separated; system map with levers; domain/workflow depth; 10 tasks with risk levels, acceptance criteria, dependencies; summary doc). Criteria modified during phase: success criteria 1–3 restructured into the M1–M6 all-of matrix and the gate metric moved recall@5 → recall@3 (peer review A1/A2 — budget-metric mismatch + SLO-viability rule). No unmet criteria; nothing blocks PLAN.
- Compound: three candidates, none written autonomously. (a) Fourth behavioral-vs-automated instance (new-content trigger) → route: add to `behavioral-vs-automated-triggers.md` evidence when AKM-008 lands (fix not yet built; doc records fixes). (b) "Evaluation metric must match the delivery cutoff" (GEM-F2: fixture recall@5 vs surfacing budget 3 — the metric passed while the brief missed) → medium confidence, single instance; solutions/ write requires operator approval, flagged. (c) "Accept-empty removes the pressure that makes overlapping score distributions dangerous as a noise gate" → same handling.
- Context usage before checkpoint: estimated ~60% (moderate band)
- Action taken: none (below 70% threshold)
- Key artifacts for PLAN phase: `specification-summary.md` (current in context), M1–M6 matrix + task table in `specification.md`, `akm-evaluation-2026-07.md` for design-level numbers as needed

## 2026-07-07 — PLAN: action plan + tasks authored

**Context inventory (action-architect invocation):**
1. `specification-summary.md` — current in context (authored/revised this session)
2. `specification.md` — task table + M1–M6 matrix (current in context; no re-read)
3. `_system/docs/solutions/staged-spike-with-bail.md` — full read; applied to AKM-001 (Stage-0 bail on daemon availability)
4. `_system/docs/estimation-calibration.md` — full read; expansion pattern (2.6–3.0x spec→TASK on infra projects) + checkpoint-pivot lesson applied to plan risk notes

Budget: 4 docs (standard tier). Budget-exempt: preflight knowledge brief (hook-injected), signal scan reused from same-day SPECIFY invocation (no new scan — same tag space), overlay index (no match, unchanged).

**Delivered:**
- `action-plan.md` — 4 milestones: M1 transport/mode decision (AKM-001 spike staged with Stage-0 bail on daemon availability per staged-spike-with-bail + AKM-002 design w/ operator gate), M2 precision-trigger rebuild (AKM-003/004, code review at boundary), M3 hook primitives (AKM-005/007 designs parallel w/ shared A4/U3 validation + two Primitive Creation gates; AKM-006/008 after AKM-003; code review at boundary), M4 vocabulary + soak closure (AKM-009/010). Soak window doubles as M3/M4 working time.
- `tasks.md` — 10 tasks, binary acceptance criteria, dependency graph per spec; milestone-boundary enforcement notes (code review, M6/A4 amendment rule).
- `action-plan-summary.md`
- `estimation-calibration.md` — akm-refresh row registered at PLAN: 10 tasks, predicted ~1.5x mild expansion (finer cutting test vs the 2.6–3.0x infra band), gates may compress instead.

**Cross-project deps:** no new rows — XD-028 already covers the VO-037 handoff. **Compound:** calibration registration is the compound act this phase; decomposition itself followed existing patterns (no new solutions candidates).

**Plan impact assessment:** MODERATE (modifies existing production script behavior + adds two hooks; task structure transcribes an already-peer-reviewed spec). Peer review available on request, not prompted.

## 2026-07-07 — Session end (SPECIFY → PLAN in one session)

**Session arc:** vault-state resume → systems-analyst spec → peer review round 1 (3/4 reviewers; DeepSeek timeout) → A1–A9 applied, cycle closed at one round per operator → spec approved → SPECIFY→PLAN gate (committed `b9418418`) → action-architect plan (4 milestones, 10 tasks). Session ends with PLAN outputs authored, **awaiting operator plan approval** — next session: approve (or peer-review) the plan → PLAN→TASK gate → AKM-001 Stage-0 daemon check.

**Compound evaluation:** phase-transition candidates already logged (behavioral-vs-automated 4th instance → route at AKM-008; two medium-confidence pattern candidates flagged for operator approval). New this segment: **vault-check detection quirk** — pre-commit run reported "no staged run-log files" and skipped §4/5/29/30 even though `progress/run-log.md` was staged and committed; the run-log-scoped checks silently didn't run. System gap observation for vault-optimization's backlog (vault-check is VO's surface); not fixed here, not a solutions/ candidate.

**Model routing (cost observation):** all three skills this session (systems-analyst, peer-review, action-architect) are reasoning-tier — kept on session model, no Sonnet delegations; no `model_tier: execution` skills invoked. Heaviest ops: peer-review-dispatch subagent (~79k tokens, 20 tool uses — panel dispatch + note authoring, quality pass), review-note full read (~416 lines), protocol/skill doc loads. Outcomes: all pass, no rework.

**Open operator items at session end:** (1) plan approval, (2) A10 DeepSeek curl_timeout bump, (3) two compound pattern candidates (write to solutions/ y/n), (4) vault-check run-log detection quirk → VO backlog.
