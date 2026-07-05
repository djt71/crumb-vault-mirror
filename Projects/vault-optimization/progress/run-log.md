---
type: run-log
project: vault-optimization
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - run-log
---

# vault-optimization — Run Log

## 2026-06-10 — Project creation

**Trigger:** Operator directive following agentic-sunset M1+M2 execution: run an optimization and clean-up pass over the vault, starting by defining the core functionality to be kept and optimized.

**Operator decisions (project creation gate):**
1. Name/domain: `vault-optimization`, domain software, type system, vault-only (no external repo — repo gate skipped)
2. Scope boundary vs agentic-sunset: **agentic-sunset keeps M6/M7** (AS-025–032: _openclaw/_tess/_staging archival, CLAUDE.md diff, skills+memory cleanup). vault-optimization defines core functionality now and acts on everything beyond AS scope. Cleanest provenance.

**Next:** Enter SPECIFY (systems-analyst) — define core functionality to keep/optimize.

## 2026-06-10 — SPECIFY: context inventory

**Context inventory (systems-analyst, standard tier — 4 docs + budget-exempt items):**
1. `_system/docs/adr-crumb-v3-knowledge-store-identity.md` (2026-05-15, **status: proposed — never accepted**) — pre-existing draft of exactly this project's question: v3 identity statement + Tier 1/2/3 keep/dormant/remove categorization + boundary cases + open operator questions. Governing seed artifact.
2. `_system/docs/crumb-v2-system-health-assessment.md` — ceremony-budget provenance; maintenance gravity, shadow workflows, "correct but not used" failure mode
3. `_system/docs/solutions/infrastructure-teardown-discipline.md` — prior art (high confidence): end-conditions, consumer-graph sweeps, creation/removal asymmetry
4. `Projects/agentic-sunset/action-plan-summary.md` — scope boundary (AS keeps M6/M7: AS-025–032)
- Budget-exempt: skill-preflight knowledge brief; signal `systematicls-agentic-engineering-patterns.md` ("less is more", CLAUDE.md-as-directory, periodic consolidation/"spa day")
- Live inventory (Bash): 2,504 md files; 20 skills, 4 agents, 20 scripts, 6 protocols, 8 overlays, 25 solution docs, 12 project dirs, 9 domains; dir weights — Archived 147M, Projects 41M, Sources 12M, _system 5M, _attachments 4.7M
- Overlay index checked: **no overlay loaded** (Crumb-internal infra; Network Skills anti-signals it; no business/financial dimension)
- Signal scan (ceremony/consolidation/simplification keywords): candidates beyond systematicls — `trq212-anthropic-skill-design-lessons`, `code-rams-context-bloat-debugging`, `konik-claude-obsidian-workflow`, `skillsbench-agent-skills-mixed-results` — presented to operator, none read yet

**Key finding:** The "define core functionality" deliverable should build on the proposed v3 ADR rather than start fresh — its acceptance criteria (operator confirms identity, boundary cases, VAL disposition) were never checked off.

## 2026-06-10 — SPECIFY: operator decisions + spec written

**Operator decisions (4-question gate):**
1. v3 identity ADR: **adopt as baseline** — spec refreshes tiers post-sunset, resolves its open questions; acceptance becomes VO-001
2. Scope axes: **all four** — primitive surface, docs & staleness, ceremony reduction, storage & weight
3. Disposition: **aggressive deletion** — git history is the archive (departure from agentic-sunset archive-everything style; history rewrite itself remains a separate default-out decision, A2/U4)
4. Signal inputs: read `trq212-anthropic-skill-design-lessons` + `skillsbench-agent-skills-mixed-results` (both folded into spec evidence base)

**Artifacts written:** `specification.md`, `specification-summary.md` (8 tasks VO-001–008, full four-phase workflow). Cross-project dep **XD-027** added (VO-005/007 blocked on agentic-sunset AS-025–029).

**Spec scope class: MAJOR** (system-wide architecture decision + irreversible deletions) → peer review recommended before PLAN.

## 2026-06-10 — Peer review panel audit + dispatch

**Operator flagged panel staleness before review dispatch — confirmed.** Live /models audit (all 4 providers): `deepseek-reasoner` and `grok-4-1-fast-reasoning` removed from their APIs (dispatch would have failed); GPT-5.4 and Gemini 3.1 Pro Preview still current. Operator decisions: DeepSeek slot → `deepseek-v4-pro`; Grok slot → `grok-4.3` **with calibration watch** (Grok-family fabrication record per TV2-Cloud eval of 4.20; first 2–3 reviews get Perplexity-style finding verification). `peer-review-config.md` updated (models, pricing, audit note).

**Dispatching:** peer review of `specification.md` to 4-model panel.

**Review round 1 complete (2026-06-10):** 4/4 reviewers responded first-attempt. Review note + synthesis: `reviews/2026-06-10-specification.md`. Grok calibration watch review 1: 0 fabrications, 1 misread, 1 noise — acceptable, watch continues (tally in peer-review-config.md).

**Synthesis verdict:** spec structurally sound (consumer-graph discipline + manifest controls drew cross-panel STRENGTHs) but **4 must-fix amendments required before PLAN**:
- A1: joint-surface contract with agentic-sunset (ownership matrix; entry gate for VO-005/007) — 4/4 consensus, incl. one CRITICAL
- A2: VO-008 execution model (backup restore-drill verification, batched atomic deletions with consumer remediation per batch, abort/revert + partial-pass rules) — 4/4 consensus, incl. one CRITICAL
- A3: evidence methodology for VO-002 (type-specific standards, 5-category rubric, operator review of all no-evidence deletions) — 4/4 consensus
- A4: end-state deliverables section + VO-009 functional validation task — 3/4
Plus 5 should-fix (A5–A9), 3 defer (A10–A12). Notable contradiction resolved in synthesis: GEM's "assume unused after 15-min search" heuristic declined in favor of OAI's mandatory operator review for no-evidence deletions; timeboxing kept.

**Awaiting operator:** apply must-fix (+should-fix) amendments to spec, then round-2 diff re-review or proceed to PLAN.

**Operator decision:** Claude to assess recommendations on merits; if good, apply and skip re-review (option 2). Assessment: all 4 must-fix + 5 should-fix adopted (A4 notably mirrors our own creation/removal-asymmetry pattern back at us; A8 fixed a genuine internal contradiction — dormant-marking vs aggressive deletion). Amendments applied to `specification.md` + summary refreshed: 9 tasks now (VO-009 functional validation added), evidence methodology + VO-008 execution model + Deliverables/End State sections added, entry gates tightened (Appendix A ownership matrix + AS M6 sign-off before VO-005/007). Deferred to TASK: soak/ceremony metrics (A10–A12 noted in review synthesis).

### Phase Transition: SPECIFY → PLAN
- Date: 2026-06-10
- SPECIFY phase outputs: `specification.md` (peer-reviewed, amended), `specification-summary.md`, `reviews/2026-06-10-specification.md` (+4 raw JSONs), XD-027 in cross-project-deps, peer-review-config.md roster refresh
- Goal progress: all SPECIFY acceptance criteria met — problem statement, facts/assumptions/unknowns separated, system map with levers, domain + workflow depth classified, 9 tasks with risk levels + ACs + dependencies, summary written, MAJOR-scope peer review completed with amendments applied
- Compound: one candidate flagged for operator approval (not auto-written, per Ask First): **external-model roster rot** — third documented instance of review-panel config drifting against provider APIs (GPT-5.2→5.4 upgrade 2026-03-14; Gemini forced migration 2026-03-14 after 5-day-old deprecation; DeepSeek+Grok models removed from APIs, caught 2026-06-10 only because operator prompted a check). Proposed pattern: verify roster against live `/models` endpoints before high-stakes dispatch or on a staleness clock; candidate for `_system/docs/solutions/`. Secondary observation (no action): Grok 4.3 calibration watch opened — review 1: 0 fabrications, 1 misread, 1 noise
- Context usage before checkpoint: high (long session: SPECIFY + panel audit + review cycle) — PLAN should start from a fresh session via vault reconstruction
- Action taken: commit + recommend fresh session for PLAN
- Key artifacts for PLAN phase: `specification-summary.md` (primary), `reviews/2026-06-10-specification.md` synthesis section (A10–A12 deferred items), `_system/docs/adr-crumb-v3-knowledge-store-identity.md` (VO-001 target)

## 2026-06-10 — Session end

Session-end protocol run: report written to session_reports.db (`20260610T190927f103764`); inbox `.processed/` empty; qmd index updated (20 hashes pending `qmd embed` — non-blocking); no failure-log entry (session clean); no code-review sweep (no repo_path).

**Cost observation (model routing):** systems-analyst + peer-review synthesis kept on session model (reasoning tier) — appropriate, both were judgment-heavy. Mechanical dispatch delegated to peer-review-dispatch subagent (~55k subagent tokens, 12 tool uses, clean single-pass). External review cost ≈$0.30 (4 reviewers, new pricing). No Sonnet delegation this session — no execution-tier skills invoked.

**Protocol zombie flag (for AS-025/029 or VO-007):** session-end step 2 writes session reports to `~/.tess/state/session_reports.db` — its consumer (Tess) is decommissioned, so this is now an orphaned producer per infrastructure-teardown-discipline #2. Wrote the report this session for protocol compliance; the step should be retired or re-pointed when the session-end protocol is next revised.

## 2026-06-10 — PLAN: context inventory

Fresh session, vault-based state reconstruction (project-state.yaml + run-log).

**Context inventory (PLAN, standard tier — 4 docs):**
1. `specification-summary.md` — entry point
2. `specification.md` (full) — design must cover all 9 tasks' methodology, evidence rubric, VO-008 execution model
3. `_system/docs/adr-crumb-v3-knowledge-store-identity.md` — Tier 1/2/3 model, boundary cases, open questions (VO-001 target)
4. `reviews/2026-06-10-specification.md` — synthesis excerpts only: deferred items A10 (soak/ceremony metrics → TASK), A11 (Archived/-as-category cleanup → VO-006), A12 (vault-only wording → Appendix A)
- Overlay check: none loaded (unchanged from SPECIFY assessment — Crumb-internal infra)
- Conventions check (design-spec v2-4, grep-scoped): PLAN produces design docs in `design/`; gate is risk-tiered

**PLAN deliverable:** `design/optimization-design.md` + summary — evidence/manifest schema, consumer-graph protocol, ownership matrix structure, batch execution design, soak design, AS sequencing.

## 2026-06-10 — PLAN: design written

**Artifacts:** `design/optimization-design.md` + `design/optimization-design-summary.md`.

**Design decisions (D1–D6):**
- D1: manifest schema (item/rubric/evidence/disposition/owner/operator-review), type-specific evidence commands, Appendix A ownership-matrix schema with per-surface gates. Manifest scope = primitives + `_system/` docs + project records; KB content excluded (operator to confirm). Orphaned `session_reports.db` readable as supplementary evidence — not kept alive for it.
- D2: nine-surface consumer-graph protocol with recorded commands → `design/consumer-graph-survey.md` at VO-003.
- D3: storage policy structure on the three-outcome distinction; Archived/ exception-extraction before deletion; dead-log producer-alive check; history rewrite default-out (U4 decision recorded either way).
- D4: batch design — B0 backup restore-drill gate, B1 Archived → B2 attachments/logs → B3 docs → B4 scripts/protocols/overlays → B5 skills/agents → B6 ceremony. Primitives last so VO-009 description re-tests run against the final surface. Grounded against live plist inventory (10 active, incl. operator-kept dashboard stack per A3).
- D5: ceremony steps classified load-bearing / zombie / mergeable; trigger-condition descriptions on all kept skills; gotchas only where a failure is on record.
- D6: six representative Tier-1 soak workflows; metrics deferred to TASK per A10.

**Gap found:** end-state deliverable #2 (core-functionality operating note) has no producing task in the spec's decomposition — proposed VO-002 draft / VO-009 finalize split; fix at TASK refinement.

**PLAN gate (risk-tiered):** design contains high-risk decisions (VO-008 batch model, Archived/ deletion order, backup authority) → operator approval required before TASK. Open decisions: (1) KB-content exclusion from manifest scope, (2) authoritative restore source for B0 drill, (3) batch order, (4) operating-note split.

## 2026-06-10 — PLAN gate: operator decisions

All four gate decisions resolved (operator, 4-question gate — all recommended options accepted):
1. Manifest scope: **KB content excluded** (Sources/, Domains/ are Tier-1 data, not surface; weight via VO-004 only)
2. B0 authoritative restore source: **git remote** (matches "git history is the archive"); Drive/mirror = secondary freshness checks
3. Batch order: **as designed** — B1 Archived/ → B2 attachments/logs → B3 docs → B4 scripts/protocols/overlays → B5 skills/agents → B6 ceremony
4. Operating note: **split** — VO-002 draft, VO-009 finalize; action-architect encodes at TASK

Design doc + summary updated to record decisions inline. PLAN gate passed.

### Phase Transition: PLAN → TASK
- Date: 2026-06-10
- PLAN phase outputs: `design/optimization-design.md` (D1–D6), `design/optimization-design-summary.md`, 4 gate decisions recorded
- Goal progress: PLAN deliverable met — design covers all 9 tasks' execution mechanics (evidence schema, consumer-graph protocol, ownership-matrix schema, batch model, soak shape); high-risk decisions operator-approved; A10 metrics and the operating-note task fix explicitly routed to TASK
- Compound: one candidate flagged for operator approval (not auto-written, per Ask First): **deliverables-contract cross-check** — spec's end-state deliverable #2 had no producing task; proposed routing is a one-line check in action-architect's procedure ("every end-state deliverable maps to a producing task"), not a new solutions doc. Single observed instance → medium confidence
- Context usage before checkpoint: low (fresh session; 4 docs + design writes — well under 50%)
- Action taken: none (proceed in-session)
- Key artifacts for TASK phase: `specification-summary.md`, `design/optimization-design-summary.md` (both in context), spec Task Decomposition table + acceptance criteria

## 2026-06-10 — TASK: action-architect

**Context inventory (action-architect, standard tier):** spec + spec-summary, design + design-summary already in session context (written/read this session — no re-load). New loads: `_system/docs/estimation-calibration.md` (tail), XD-027 row, baseline regeneration via Bash (budget-exempt mechanical), skill-preflight knowledge brief (ambient — DNS/visualization, not relevant, discarded). Signal scan (step 1b): keyword sweep over Sources/signals+insights surfaced no new how-to-build signals beyond those folded into the spec at SPECIFY (systematicls, trq212, skillsbench) — no operator re-prompt (ceremony budget). Overlay check: no match (unchanged).

**Inventory baseline regenerated (per D1):** 2,511 md files (+7 since spec snapshot); other counts unchanged (20 skills / 4 agents / 8 overlays / 20 scripts / 6 protocols / 25 solutions / 12 projects / 10 plists; Archived/ 147M). Snapshot recorded in action-plan.md header.

**Artifacts:** `action-plan.md` (5 milestones M1–M5), `tasks.md` (27 atomic tasks VO-010–036), `action-plan-summary.md`.

**Decomposition decisions:**
- 9 spec lines → 27 atomic (3.0x) — agentic-sunset teardown calibration (2.6x, "2–3 atomic per scrap-N-things line") applied predictively; calibration row added to estimation-calibration.md.
- Spec tension resolved: VO-005/006/007 become *changeset-definition* tasks (M3, no mutations); all deletions/edits execute under M4 batch discipline (B0 backup gate first); spec ACs for those groups verified at batch checkpoints B3–B6.
- A10 closed (no longer deferred): ceremony metrics defined at VO-025 — per-ceremony mandatory-step counts before/after, zombie count → 0, named consumer/enforcer per kept step, checklist diff proves no gate semantics lost. Soak end-condition defined at VO-034: 14 calendar days AND ≥8 sessions from B6 commit, whichever later.
- Operating-note split encoded: VO-018 draft / VO-036 finalize (PLAN gate decision).
- XD-027 row updated: gates now task-precise (VO-031/032 ← Appendix A frozen + AS M6 sign-off; VO-026/033 ← AS-025). VO-031/032 created in `blocked` state.
- Bulk-deletion footprint rule: ≤5 *edited* files per batch commit; deleted files enumerated in run-log, not counted against task footprint.

**Peer review offer (step 6): HIGH impact** — irreversible structural deletions + multi-skill modification → recommend peer review of action-plan.md before IMPLEMENT. Awaiting operator: 'peer review' or 'proceed'.

## 2026-06-10 — TASK: operator decisions + peer review dispatch

**Operator decisions:** (1) peer review of action-plan.md approved — dispatching; (2) compound candidate approved — deliverables-contract cross-check added as one line to action-architect Output Quality Checklist (`.claude/skills/action-architect/SKILL.md`). Compound insight executed (routed: primitive update, not solutions doc).

## 2026-06-10 — Action plan peer review: round 1 + amendments

**Dispatch:** 4/4 reviewers first-attempt (GPT-5.4 62.5s, Gemini 3.1 Pro 55.3s, DeepSeek V4 Pro 110.2s, Grok 4.3 12.8s; ≈$0.10 estimated). Safety gate: 2 soft entropy flags, both false positives (topic tag, path phrase). Review note + synthesis: `reviews/2026-06-10-action-plan.md` (+4 raw JSONs).

**Grok calibration watch review 2:** 9 findings — 0 fabrications, 1 misread (GRK-F3), 1 noise (GRK-F4); tally in peer-review-config.md. One more review to close the watch.

**Synthesis verdict:** no CRITICALs; structure + changeset/execution split + A10 closure drew 4/4 STRENGTHs. **2 must-fix + 9 should-fix, all applied same day** (assess-on-merits precedent from spec round):
- A1 (must): cross-batch integrity — batch-open changeset-staleness check; forward-fix-from-git rule; halt-M4 + restore + re-enter-M3 fallback (OAI-F13, GEM-F2, DS-F4 consensus)
- A2 (must): drift control — inventory re-diff at M3 close + every batch open; new items dispositioned pre-batch; evidence-status changes return to operator (OAI-F26/F30)
- A3–A11 (should): soak failure protocol + working-session/"needed" definitions + max() end-condition; per-batch named changeset packs + spec-AC→checkpoint traceability map; VO-026 frozen pending-AS-025-release + VO-033 AS-025 verification AC; sub-batch rule + VO-029 3-way split by risk profile; functional fast-pass at batch commits; citation pass (baseline→run-log, calibration→estimation-calibration.md, gates→cross-project-deps.md, vault-check→script); definitional tightening; A12 disposition stated; tasks.md cross-reference + embed-both-artifacts rule for future plan reviews.
- Declined (recorded with categories in synthesis): OAI-F8, DS-F2, OAI-F12, OAI-F16 (incorrect premise — per-task ACs/edges live in tasks.md, which reviewers didn't receive), GRK-F3 (misread), GRK-F4 (noise), GEM-F2 sequential-drafting option (overkill vs refresh-at-execution).

**Meta-lesson (captured as A11, no new solutions doc):** reviewing action-plan.md without tasks.md generated 4 incorrect-premise findings — plan reviews must embed the AC source artifact.

Amendments applied to action-plan.md + tasks.md; action-plan-summary.md refreshed. Re-review skipped (amendments follow panel consensus; same operator precedent as spec round).

## 2026-06-10 — Pre-VO-010: ADR-vs-goals analysis

Operator requested analysis of the v3 ADR against project goals before IMPLEMENT entry. Delivered in-conversation; conclusion: **minor drift → proceed**, with a four-point refresh agenda for VO-010:
1. Tier 3 re-stated as executed/AS-owned (sunset M1/M2 already tore most of it down; remainder is AS M6/M7 per XD-027)
2. Tier 2 narrowed to a canonical-reference/compound-provenance exception list — "keep dormant" predates the aggressive-deletion decision and contradicts it (spec amendment A8 killed dormant-marking)
3. Mission Control disposition ("shed") must be reconciled with the later operator decision to keep the dashboard stack (spec assumption A3) — the one live boundary-case decision
4. Tier 1 skill enumeration (17/20 skills) demoted to presumptive-keep — tiers govern categories; the VO-002 manifest owns item-level dispositions (SkillsBench evidence)
Open questions status: Q1 answered by events (pollers gone, intake stays open); Q2 = point 3 above; Q3 recommend outside-Crumb read-only runtime; Q4 settled by AS-029 ownership + model-behavior memories demonstrably earning keep. Also: liberation-directive refs in CLAUDE.md are NOT Tess-specific — survive the rewrite. **Operator endorsed the analysis ("great, pls proceed").**

### Phase Transition: TASK → IMPLEMENT
- Date: 2026-06-10
- TASK phase outputs: `action-plan.md` (M1–M5, peer-reviewed round 1, 11 amendments applied), `tasks.md` (27 atomic tasks VO-010–036), `action-plan-summary.md`, `reviews/2026-06-10-action-plan.md` (+4 raw JSONs), XD-027 task-precise update, estimation-calibration row, action-architect deliverables cross-check (compound, operator-approved)
- Goal progress: all TASK acceptance criteria met — decomposition complete with binary ACs and dependency edges, risk levels assigned, calibration consistent (3.0x vs 2.6x precedent), HIGH-impact peer review completed with must-fix amendments applied
- Compound: TASK-phase insight already routed — embed-the-AC-source-artifact rule for plan reviews captured as amendment A11 in the plan + review note (first instance; no solutions doc). Prior pending candidate (external-model roster rot) remains awaiting operator decision — not re-raised this phase
- Context usage before checkpoint: moderate (~50-60% — long session: PLAN + TASK + review cycle). Proceed band; VO-010 is a light ADR-edit task. If IMPLEMENT continues past VO-010, prefer fresh session for M2 evidence passes
- Action taken: none (proceed in-session for VO-010 only)
- Key artifacts for IMPLEMENT phase: `tasks.md` (AC source), `_system/docs/adr-crumb-v3-knowledge-store-identity.md` (VO-010 target, in context), refresh agenda above

## 2026-06-10 — VO-010 complete: v3 ADR accepted

**Decision gate outcome: PROCEED** (minor drift — identity statement and tier model unchanged; snapshot content refreshed). **Operator sign-off: 2026-06-10** — analysis endorsed in-conversation ("great, pls proceed") + explicit MC boundary-case decision via question gate.

**ADR edits** (`_system/docs/adr-crumb-v3-knowledge-store-identity.md`):
- Frontmatter `status: proposed → accepted`, updated 2026-06-10, related_projects += agentic-sunset, vault-optimization
- New **Acceptance Refresh (2026-06-10)** section (prevails over 2026-05-15 snapshot where they differ; original retained as provenance): (1) Tier 3 executed/AS-owned, (2) Tier 2 narrowed to canonical-reference/compound-provenance (aggressive-deletion supersedes "keep dormant"), (3) **MC: runtime shed, stripped dashboard kept** (operator decision — dashboard/vault-web/cloudflared survive as knowledge-work viewing surface; panels face VO-002 rubric), (4) Tier 1 skill enumeration demoted to presumptive — manifest owns item dispositions
- All 4 open questions answered in the ADR (pollers-by-events / MC above / reactivation = outside-Crumb read-only runtime, no in-vault automation without new ADR / Tess memories = AS-029 ownership, model-behavior memories confirmed keeps)
- All 5 acceptance boxes checked (external-review box satisfied indirectly — ADR-as-baseline panel-reviewed twice today; noted inline)
- Inline annotations at Tier 2, Tier 3, and MC boundary case pointing to the refresh section

**VAL disposition handoff:** VAL-001/002/003 closed as superseded by this acceptance; the `tess-harness-plan-tracking.yaml` file update rides with AS-030 (tess-v2 closures are AS-owned) — flagged here for the AS run-log.

**VO-010 ACs:** all four pass (status accepted ✓, 5 boxes ✓, open questions answered ✓, gate outcome + sign-off this entry ✓). tasks.md updated to done. **Next: VO-011+ (M2 evidence passes) in a fresh session** — context moderate-high after PLAN+TASK+review+VO-010.

## 2026-06-10 — Session end

Single session carried PLAN (design D1–D6 + 4 operator gate decisions) → TASK (action-plan + 27 tasks + panel review + 11 amendments + compound fix to action-architect) → IMPLEMENT M1 (VO-010: ADR accepted, MC boundary decision). Two phase-transition checkpoints ran in-session; context bands held (never exceeded proceed band before VO-010, which was deliberately light).

**Compound evaluation:** primary insight already routed mid-session (A11 embed-the-AC-source rule → action plan + review note + memory). Secondary observation, no doc: the **dated Acceptance Refresh pattern** for accepting a stale ADR — refresh section prevails over the original snapshot, original retained as provenance, inline annotations pointing forward — worked cleanly; if it recurs (second stale-ADR acceptance), capture as a solutions entry. Pending compound candidate from SPECIFY session (external-model roster rot) still awaits operator decision.

**Cost observation (model routing):** all reasoning-tier work (PLAN design, action-architect, review synthesis, ADR analysis/acceptance) on session model — appropriate, judgment-heavy throughout. Mechanical dispatch delegated to peer-review-dispatch subagent (~60k subagent tokens, 16 tool uses, clean single-pass). External review ≈$0.10 (4 reviewers; Grok 12.8s/$0.01-class). No execution-tier skills invoked → no Sonnet delegation. No routing adjustments indicated.

**Session-end protocol notes:** session report written to session_reports.db (zombie-producer flag from previous session stands — retire/re-point at VO-025/B6); no failure-log entry (clean session); code-review sweep + build verification skipped (no repo_path).

## 2026-06-10 — M2: VO-011–015 complete (manifest + all four evidence passes)

**Session start (fresh, vault-based state reconstruction):** project-state + run-log tail + tasks.md + action-plan-summary + design doc (D1 schema). Context inventory: 5 project docs loaded; no overlays (unchanged — Crumb-internal infra); skill-preflight not fired (no skill invocations — direct task execution under IMPLEMENT).

**VO-011 — manifest skeleton.** Baseline regenerated per D1: 2,515 md files (+4 vs TASK regen; counts drift only in md total — all structured counts identical: 20/4/8/20/6/25/12 projects/10 plists; Archived/ 147M). `keep-set-manifest.md` created: 199 item rows across 13 sections, every row typed + owner placeholder from Appendix A draft; scope-boundary note (KB content + logs + harness memory excluded); Appendix A schema embedded with status=draft (freeze at VO-016). Doc clusters defined per-subdir, with explosion rule recorded (split-disposition cluster → per-file rows).

**VO-012 — skills + agents.** Commands: log greps (session-log*.md, all run-log*.md), `git log --grep` per name, session_reports.db (16 sessions 2026-04-06→06-10, supplementary per D1), structural refs (CLAUDE.md, settings hooks, skill-preflight-map). Key evidence finds: (1) prior consolidation round on record (session-log.md:148,157) — obsidian-cli→vault-query, excalidraw→mermaid already merged; **deferred-merge list** critic→peer-review, learning-plan→systems-analyst, writing-coach→peer-review, checkpoint→audit — adopted as prop: dispositions; (2) attention-manager proven-active via today's daily note frontmatter (skill_origin); (3) feed-pipeline + vault-query flagged sunset-tied → AS-028 coordination; (4) CLAUDE.md still cites "obsidian-cli skill" — stale ref → B6 fix list. 24/24 rows categorized, zero unknown.

**VO-013 — scripts + plists.** Commands: per-script grep over LaunchAgents plists + settings*.json + sibling scripts; `git log -1` per file; `launchctl list` (all 10 loaded; cloudflared PID 684, vault-web PID 689). Dashboard stack (cloudflared/dashboard/vault-web) marked **operator-kept (A3)** ✓. Superseded: bridge-watcher.py(+parked plist), openclaw-isolation-test.sh, tess-health-check.sh, vault-search.sh (tess-v2 Phase 4a artifact; 2026-06-09 touches were tess-danny-migration mechanical path-rewrites, not usage). No-evidence: batch-moc-placement.py, clear-claude-cache.sh, dns-recon.sh (operator work utility — decision flagged). qmd-index + vault-rebuild = viewing-stack adjacency, A3-extension question recorded for VO-016/017.

**VO-014 — overlays + protocols.** Hyphenated grep under-matches — re-swept with prose names ("Life Coach" etc.). All 8 overlays evidenced (activation logs and/or named in kept-skill procedures: attention-manager/learning-plan/mermaid/deck-intel) — index presence not counted per D1 ✓. Protocols: session-end + inline-attachment structural (CLAUDE.md); bridge-dispatch, dispatch-triage, research-brief-review **superseded** (referenced only by decommissioned dispatch surfaces) ✓; hallucination-detection contingency (CLAUDE.md cites spec §4.8, not the file — merge question to VO-024).

**VO-015 — docs/solutions/projects.** Bulk sweep: per-file basename refs + last-commit across 25 solutions, 62 root docs, 15 skill-workflows, 8 doc clusters, 6 _system clusters, 12 projects. Headline finds: (1) **skill-workflows/ layer is a zero-consumer orphan** — nothing references it (CLAUDE.md, skills, operator docs, orientation-map, dashboard all swept); 12 no-evidence + 3 superseded; (2) openclaw-*/tess-crumb-* doc families superseded (AS concurrence; openclaw-crumb-reference flagged as possible AS-029 input first); (3) executed specs (compound-enhancements, peer-review-skill-spec, change-spec-model-routing) → prop: delete, provenance in git; (4) _system/schemas split: a2a/briefs/capabilities superseded, deliberation/assessment-schema structural (cluster exploded per rule); (5) solutions corpus healthy — 21/25 keep with refs, 1 superseded (lucidchart), 3 to VO-024; (6) file-conventions refs=89 and goal-tracker refs=81 = top structural anchors. Project records: all keep (provenance; archival is operator-initiated); feed-intel-framework archival + tess-danny-migration status question flagged for operator/AS. Zero unknown rows manifest-wide ✓.

**No-evidence delete candidates queued for VO-017 operator review (19 rows):** batch-moc-placement.py, clear-claude-cache.sh, dns-recon.sh, adr-cli-native-agent-architecture, code-setup-prerequisites, proposal-pattern-enforcement-schema, vault-intake-overview-diagram (.md + .excalidraw), vault-startup-detection-diagram, + 12 skill-workflows layer files (superseded rows need no per-item sign-off per D1 rule, but sunset-tied ones carry AS-concurrence flags into VO-023/024 packs).

**M2 remaining:** VO-016 (Appendix A freeze — time with AS session boundary), VO-017 (operator sign-offs), VO-018 (post-017), VO-019/020 (post-017), VO-021/022 (unblocked — next mechanical work).

## 2026-06-10 — VO-017 complete: operator sign-off on no-evidence deletes

**Operator decision (in-conversation, 2026-06-10): "approve all"** — wholesale sign-off on all 21 no-evidence delete rows (3 scripts incl. dns-recon work-utility call, 6 root-doc rows incl. the diagram .md/.excalidraw pair, 12 skill-workflows layer files). Manifest operator-review cells updated to `approved+signed 2026-06-10 (operator, wholesale)`; dns-recon disposition resolved to prop: delete.

**feed-intel-framework:** operator said "keep feed-intel-framework in archive for now" — recorded as: record stays in place (phase DONE, Projects/), no deletion, **formal archival deferred**. Interpretation note: not moved to Archived/ — that would put it inside B1 deletion scope; if operator intended a formal archival, it should wait until after B1 executes (flagged here for visibility).

**VO-017 AC:** zero no-evidence delete rows without operator sign-off ✓ (21/21 signed).

**Unblocked:** VO-018 (operating note draft), VO-019/020 (consumer-graph surveys over all delete rows). VO-021/022 remain unblocked. VO-016 still waits on AS session boundary. Recommend fresh session for VO-019–022 (grep-heavy surveys + Archived/ enumeration; current session context high after manifest build).

## 2026-06-10 — Session end (M2 evidence session)

Fresh session carried M2 from VO-011 through VO-017: keep-set manifest built (199 rows, 13 sections), all four evidence passes completed with recorded commands, zero unknown rows, and operator wholesale sign-off on all 21 no-evidence delete rows (+ FIF archival deferred, dns-recon delete approved). Two commits pushed (aa74ae72 manifest, 5808df55 sign-off). M2 remainder: VO-018–022 (fresh session), VO-016 (AS session-boundary timing).

**Compound evaluation:** no new solutions doc. (1) skill-workflows orphan layer is a clean confirming instance of the existing Ceremony Budget Principle (capability added without consumer wiring → zero adoption) — evidence recorded in manifest + run-log, principle already constitutional. (2) Methodological note already recorded in VO-014 entry: prose-name grep over hyphenated-slug grep for activation evidence (slug grep under-matches by ~6x on overlays). (3) Cluster-row-with-explosion-rule worked on first use (schemas cluster split a2a/deliberation) — pattern stays manifest-local unless it recurs elsewhere.

**Cost observation (model routing):** all judgment work (rubric assignment, supersession calls, evidence synthesis) on session model — appropriate throughout. All evidence gathering via direct Bash greps (mechanical, budget-exempt) — no skill invocations, no subagent dispatch, no external review spend. No routing adjustments indicated.

**Session-report step:** attempted per protocol §2 (tess CLI) — see note below this entry for outcome; zombie-producer flag on session_reports.db write stands (retire/re-point decision lives at VO-025/B6 ceremony classification).

*Session-report outcome: written successfully (tess CLI alive — session_id 20260610T214515f609183, row 18, sequence 3 for 2026-06-10). qmd update ran; inbox .processed empty; failure-log not warranted (clean session); code-review sweep + build verification skipped (no repo_path).*

## 2026-06-10 — M2 continuation: VO-018–022 session

**Session start (fresh, vault-based state reconstruction):** project-state + run-log tail + tasks.md (VO-016–022 rows) + action-plan-summary + design D2/D3 sections + spec deliverable #2 + manifest (header, schema, all 58 delete/merge rows). Context inventory: 6 project docs (standard tier, 5+1 justified: manifest is the work surface for all five tasks); no overlays (unchanged — Crumb-internal infra); no skill invocations planned (direct task execution under IMPLEMENT). Mechanical grep surveys delegated to read-only Explore subagents (mechanical work, parallel; provenance spot-check on return per CLAUDE.md Subagent Validation).

**Plan:** VO-019 (vault-internal survey, 2 agent chunks) + VO-020 (system surfaces, 1 agent) in background; VO-018 (operating note draft) + VO-021 (Archived/ enumeration) in main session meanwhile; VO-022 (storage policy) after VO-021; synthesis + survey doc + sign-offs at end.

## 2026-06-10 — VO-018–022 complete (M2 closes except VO-016)

**VO-018 — operating note draft.** `_system/docs/crumb-operating-note.md` created (medium-risk new file — flagged): 4 sections (identity from accepted v3 ADR; must-exist set keyed to manifest categories; deliberately-excluded list incl. skill-workflows orphan layer + dormant-marking; future-addition rubric = the four spec-deliverable-#2 questions verbatim + ceremony-budget cross-ref). Marked DRAFT-pending-VO-036 in header. ACs ✓.

**VO-019/020 — consumer-graph surveys.** Mechanical sweeps delegated to 3 read-only Explore subagents (Sonnet; ~209k subagent tokens, 228 tool uses total, single-pass each); main-session provenance spot-checks on all load-bearing claims — 2 agent misclassifications corrected (compound-insight tag ≠ schema dependency; liberation-directive hit = instance filename false positive), 1 line-number misreport (content verified). Output: `design/consumer-graph-survey.md` — 58/58 rows with consumer lists, 7 system surfaces swept, remediation-consumer index for B-pack assembly. ACs ✓.

**⚠️ Evidence-status changes (amendment A2 — returned to operator):**
1. **dns-recon.sh** no-evidence → proven-active: `customer-intelligence/import-workflow.md` (phase ACT) invokes it + requires its output (4 ref points). Manifest row reclassified, prop flipped to keep, wholesale sign-off VOIDED for this row. **Operator decision needed: keep (recommended) or delete + remediate import-workflow.**
2. **feed-pipeline-calibration.jsonl** superseded → sunset-tied: kept feed-pipeline skill still appends (SKILL.md:450). Deletion now gated on AS-028; manifest annotated.
3. **briefs/ schemas** supersession stands, but kept-skill `brief_schema:` frontmatter lines (researcher/critic/vault-query/feed-pipeline) require B4/B5 coordination in the VO-023 pack — recorded in survey doc.

**AS-029 memory handoff (per VO-020 AC):** `~/.claude/.../memory/canonical-taxonomy-sync-points.md:31` names `_system/perplexity/crumb-vault-context.md` (delete-listed) as a taxonomy sync point — memory rewrite required when the perplexity cluster deletes. Flagged here for the AS run-log pickup.

**VO-021 — Archived/ enumeration.** `design/archived-enumeration.md`: 24 projects + KB enumerated with commands; headline — 147 MB is ~133 MB *untracked* .venv trees (batch-book-pipeline 97M incl. accidental recursive `scripts/_system/` copy; pydantic-ai-adoption 36M); tracked content = 880 files / 14 MB. Exceptions: E1 notebooklm workflow-guide (2 live consumers), E2 vault-mirror spec (live MOC + documents live mirror-sync), E3 multi-agent-deliberation data/ (32 deliberation records + ratings; **live defect found: kept deliberation skill writes to `Projects/multi-agent-deliberation/data/` which doesn't exist — actual store is in Archived/; re-point at B5**). Decisions flagged: D1 solutions-linkage-proposal (delete + link remediation, operator confirm at B1), D2 capture-tiers git-citation remediation, D3 A11 list → VO-024, D4 audit/attention-manager skill refs → B5. ACs ✓.

**VO-022 — storage policy.** `design/storage-policy.md`: three outcomes (a)/(b)/(c) stated separately; _attachments orphan plan (scope = 9 files, expected yield ≈0); non-md top-N audit (think-different jpg keep, tess-v2 venv → AS-030 flag, wyner pdf keep); dead-logs producer-alive table (health-check*.log + launchd pair → B2-iii; akm-feedback.jsonl has live producer knowledge-retrieve.sh → keep + 1MB rotation watch); log rotation steady-state rules; **git-history-rewrite decision: NO rewrite, recorded explicitly** (rationale: 47MB .git healthy, venvs never tracked, rewrite would break the git-history-is-the-archive premise; revisit conditions stated) — operator confirmation of this default rides with the decision batch below. ACs ✓.

**M2 status:** VO-011–015, 017–022 done. Remaining: VO-016 (Appendix A freeze — AS session-boundary timing). M3 (VO-023–026) unblocked except VO-026 (AS-025 gate).

**Operator decision batch (pending):** (1) dns-recon.sh keep vs delete+remediate; (2) storage-policy no-rewrite default confirm; (3) D1 solutions-linkage-proposal delete confirm (can also ride to B1 exception review).

## 2026-06-10 — Operator decision batch resolved (question gate)

All three pending decisions answered in-conversation, 2026-06-10:
1. **dns-recon.sh: KEEP** (A2 re-review complete) — manifest row updated to keep; prior wholesale delete sign-off superseded for this row. No remediation of import-workflow.md needed.
2. **Git-history rewrite: NO REWRITE confirmed** — storage-policy.md caveat removed; decision final (revisit conditions stand).
3. **D1 solutions-linkage-proposal: delete + remediate link confirmed** — recorded in archived-enumeration.md; no further review at B1 for this item.

M2 fully unblocked except VO-016 (AS session-boundary timing). No open operator items for VO until B-pack approvals (M3).

## 2026-06-10 — Session end (M2 completion session)

Fresh session carried VO-018–022 plus the operator decision batch: operating note drafted, consumer-graph surveys completed via 3 parallel read-only subagents with main-session provenance checks, Archived/ enumerated (venv weight finding), storage policy written (no-rewrite final), and three operator decisions resolved at a question gate (dns-recon keep / no-rewrite / D1 delete+remediate). Three commits pushed (af14d46a M2 artifacts, 99932b75 decisions, + sync commits). M2 closes except VO-016 (AS session-boundary timing).

**Compound evaluation:** one insight worth flagging, routed as run-log + survey-doc record (first instance, no solutions doc): **bulk evidence passes that grep only constitutional/structural surfaces miss project-doc consumers** — VO-012/013 swept CLAUDE.md/settings/preflight/logs but not `Projects/*/`(non-log), which is exactly where dns-recon.sh's live consumer sat; the A2 amendment (evidence-status changes return to operator) caught it as designed, which also counts as a confirming instance for the peer-review panel's A2 must-fix. If a second missed-surface instance appears, promote to `_system/docs/solutions/` as an evidence-pass coverage checklist. Secondary: subagent fan-out for mechanical surveys worked cleanly with spot-check validation (2 misclassifications caught — both interpretive overreach, the known failure mode; mechanical hits were 100% accurate on checks).

**Cost observation (model routing):** judgment work (classification corrections, exception extraction, operating note, storage policy decisions) on session model — appropriate. Mechanical surveys delegated to 3 Sonnet Explore subagents (~209k subagent tokens total, single-pass each, quality: pass with minor corrections) — right call vs. burning main context on 58×9 greps; would repeat. No external review spend. No routing adjustments indicated.

**Protocol steps:** project-state refreshed (step 3 ✓, next_action current); failure-log not warranted (clean session); code-review sweep + build verification skipped (no repo_path); session report → tess CLI below; qmd update + inbox sweep below.

## 2026-06-10 — M3: VO-023/024 — changeset packs drafted

**Session start (fresh, vault-based state reconstruction):** project-state + run-log tail + tasks.md M3 rows + action-plan-summary + action-plan M3 § + design D4/D5 + manifest (full) + consumer-graph-survey (full) + archived-enumeration + storage-policy. Context inventory: 8 project docs (extended tier, justified: manifest + survey + enumeration + storage-policy are the four direct inputs to pack assembly; all four are this project's own analysis corpus). No overlays (unchanged). Pending-doc skims delegated to 1 read-only Explore subagent (13 docs + 6 overlap comparisons); judgment calls retained in main session.

**VO-024 — B3 docs pack** (`design/changeset-b3-docs.md`): cluster map (all _system/docs + solutions rows mapped to constitutional/skill-referenced/solutions/orphan + two transitional groupings), 16 pending-row resolutions (R1–R16), disposition list (~50 delete files + 2 merges + cluster refresh lists), A11 taxonomy cleanup list with concrete file:line edits. Key resolutions: hallucination-detection-protocol KEEP (authoritative §4.8 expansion, not a copy — agent comparison verified unique operative depth); security/network-kb-plans DELETE (executed plans — batches all DONE inside); liberation-surfaces-snapshot DELETE (frozen snapshot of decommissioned surface architecture); vault-intake-map DELETE over refresh (5 of 8 paths dead, no named consumer for a refresh — flagged #F2); system-architecture-diagram DELETE (16-line redirect stub, already status:archived); vault-restructure-analysis/discussion DELETE (predecessor provenance → git); egpu-evaluation DELETE (expired WATCH, dead decision context — flagged #F1); anthropic-consolidation-hypothesis KEEP (compound-provenance for the sunset decision chain); haiku-soul KEEP (pattern generalizes); separate-version-history-archive KEEP (functional partition); signals-archive-2026.jsonl DELETE (dead-producer rule). Cluster explosions: operator/explanation (why-two-agents → delete), operator/tutorials (first-tess-interaction → delete; MC-orientation → refresh).

**A11 scoping decision (flagged #F3 for operator):** B1 deletes the Archived/ directory; the operator-initiated archival *procedure* survives (CLAUDE.md §Project Archival + spec §4.6 untouched — directory recreated on next archival; consistent with the deferred FIF archival). A11 cleans taxonomy/navigation mentions only (AGENTS.md:35, architecture/02:157+04:230+05:25-27, vault-structure-reference:41,157, file-conventions:433). Exception: the Archived/KB **KB-archival flow is rewritten to aggressive-deletion semantics** — vault-gardening.md archive→delete-with-git-provenance (B3), audit skill purge-review steps re-scoped to delete review (B5, per D4).

**VO-023 — B4 pack** (`design/changeset-b4-scripts-protocols-overlays.md`): 10 deletes (6 scripts + parked plist + 3 protocols) with per-item remediation; order gates recorded (CLAUDE.md:219 AS-025-first for bridge-dispatch-protocol; AS-029 memory rewrite before perplexity/openclaw-crumb-reference deletions); setup-crumb.sh VO-023 verification PASSED (zero refs to delete-listed scripts); glean-prompt-engineer overlay re-check → keep confirmed; qmd-index + vault-rebuild plists resolved keep as **A3 extensions** (flagged #F5 — extends prior operator decision). Cross-batch verify list: B3 architecture-cluster edits cover several B4 consumers; vault-intake-map deletion at B3 obsoletes its B4 edit (forward-fix rule covers out-of-order execution).

**VO-023 — B5 pack** (`design/changeset-b5-skills-agents.md`): 5 merges (checkpoint→audit, critic→peer-review, learning-plan→systems-analyst, writing-coach→peer-review, diagram-capture→deck-intel — fork resolved via VO-019 composition evidence, flagged #F6) with full consumer remediation; 2 conditional rows proposed (feed-pipeline keep-with-strip, vault-query keep-with-rewrite — pend AS-028 concurrence, flagged #F7); test-runner agent keep (mission-control repo active); **15/15 kept-skill trigger-condition descriptions drafted**; 2 gotchas, both with linked records per AC (researcher ← failure-log 2026-04-21 wikilink fabrication; peer-review ← Grok calibration watch run-log + config tally); E3 deliberation re-point + D4 audit/attention-manager edits + brief_schema strips packaged. **schemas/briefs/ reassigned B3→B5** (A2 #3 single-changeset coordination); manifest cluster row exploded. End state: 20 skills → 15.

**Manifest:** all `pending — VO-023/024` rows resolved (no pending rows remain outside VO-016's Appendix A); resolutions annotated with R#/flag IDs. **No evidence-status changes** this pass (all resolutions used existing M2 evidence + doc-content reads — A2 not triggered).

**Tasks:** VO-023, VO-024 → done (packs drafted; approval records pending operator — pack approval is the M3-close/M4-entry gate, not a task AC). Remaining M3: VO-025 (ceremony classification, unblocked — fresh session recommended), VO-026 (B6 pack — AS-025 gated). Operator approval batch presented in-conversation (outcome logged in follow-up entry).

## 2026-06-10 — Pack approval batch resolved (question gate)

Operator answered in-conversation, 2026-06-10:
1. **B3 docs pack: APPROVED as drafted** — incl. #F1 (egpu-evaluation delete), #F2 (vault-intake-map delete over refresh), #F3 (A11 scoping: archival procedure survives; taxonomy mentions cleaned; Archived/KB flow rewritten to delete-with-git-provenance).
2. **B4 scripts/protocols/overlays pack: APPROVED as drafted** — incl. #F5 (qmd-index + vault-rebuild plists kept as A3 extensions; manifest rows prop→keep confirmed).
3. **B5 skills/agents pack: APPROVED with exception** — **critic→peer-review and writing-coach→peer-review merges REJECTED; both skills stay standalone (keep).** #F6 (diagram-capture→deck-intel) and #F7 (feed-pipeline keep-with-strip, vault-query keep-with-rewrite, pending AS-028) approved. Pack amended same day: merges 5→3, end state 20 skills → **17**, critic's brief_schema lines moved to the strip list, writing-coach remediations dropped, descriptions updated (peer-review reverted to review-only scope; critic + writing-coach descriptions added → 17/17 kept-skill rewrites). Manifest rows updated; the 2026-03 deferred-merge list (session-log.md:157) is now fully dispositioned: #11/#13 execute, #8/#12 operator-declined.

**M3 status:** every batch B3–B5 has an approved changeset pack with its own approval record. Remaining for M3 close: VO-025 (ceremony classification + A10 metrics, unblocked), VO-026 (B6 pack, AS-025 gate), M3-close drift diff. VO-016 (Appendix A freeze) still on AS session-boundary timing.

## 2026-06-10 — Session end (M3 changeset session)

Fresh session carried VO-023 + VO-024 end-to-end: 13 pending-doc skims via one read-only Explore subagent (judgment retained in main session), 16 VO-024 pending-row resolutions, three named changeset packs drafted (B3 docs / B4 scripts-protocols-overlays / B5 skills-agents), manifest fully resolved (zero pending rows outside Appendix A), and the pack-approval question gate run — all three packs approved same session, B5 with one exception (critic/writing-coach merges declined → keep standalone; 20 skills → 17). M3 remainder: VO-025, VO-026 (AS-025 gate), drift diff; VO-016 on AS session boundary.

**Compound evaluation:** no new solutions doc. (1) A11 scoping distinction — *deleting a directory's contents ≠ retiring the mechanism that writes to it* (archival procedure survives B1; only the KB-archival flow changes semantics by explicit decision) — first instance, recorded in B3 pack + run-log; promote if a second contents-vs-mechanism confusion appears. (2) The operator question gate caught real preference divergence on 2 of 4 deferred merges that 2026-03 session logs presented as settled — confirming instance for mandatory operator review on primitive removals (A2/gate design working as intended). (3) Single-Explore-agent doc-skim + main-session judgment split repeated cleanly from the M2 pattern — established, no doc.

**Cost observation (model routing):** judgment work (16 disposition resolutions, pack assembly, A11 scoping, description rewrites) on session model — appropriate. One Explore subagent for the 13-doc skim + 6 overlap comparisons (session-default model, single pass, quality: pass — no misclassifications found on spot-check; overlap verdicts load-bearing for R5/R7/R8/R13 and verified against quoted line numbers). No external review spend. No routing adjustments indicated.

**Protocol steps:** project-state refreshed (step 3 ✓); failure-log not warranted (clean session); code-review sweep + build verification skipped (no repo_path); substantial delta flagged + descriptive commit (3 new pack files + manifest/tasks/state edits); session report + qmd + inbox sweep below.

## 2026-06-10 — VO-025 complete: ceremony step classification + A10 metrics

**Session start (fresh, vault-based state reconstruction):** project-state + run-log tail + tasks.md VO-025/026 rows + action-plan M3 § + design D5 (VO-007 axis) + spec VO-007 row. Context inventory: 5 project docs + 3 ceremony source docs (context-checkpoint-protocol, session-end-protocol, inbox-processor SKILL.md §Procedure — the classification subjects, not analysis corpus). No overlays (unchanged); no skill invocations (direct task execution under IMPLEMENT); evidence via direct greps (mechanical, main session — small surface, no subagent fan-out warranted).

**Deliverable:** `design/ceremony-classification.md` — all 4 ceremonies classified per step with named consumer/enforcer per kept step; A10 metrics table; zombie list; B6/B5/AS-028 routing.

**Headline classifications:**
- **Phase gates:** 11 steps → 6 (merges: goal-progress+progress-log→transition-log; /context-check→band-evaluation; verify-outputs→verify-summaries; "Proceed" step cut as zero-content). Compound reflection kept as named step (constitutional anchor).
- **Context-checkpoint (mid-session):** 2 → 1 (check+act per band). Degradation guide/positioning guidance kept (consumed reference, not steps).
- **Session-end:** 10 → 7. **Zombie confirmed: step 2 session report → session_reports.db** (producer alive, consumer decommissioned — Tess layer dark 2026-06-10; mission-control dashboard src has zero session_reports reads; dispatch claim doubly dead). Recommend retire over re-point. Step 8 (.processed sweep) cut as redundant — vault-gc.sh (kept, plist loaded) purges same dir on 1-day TTL. "6b" AKM residue text = textual zombie. Steps 9+10 merge (commit&push).
- **Intake (inbox-processor):** 8 → 7 (compound-check folds into verify/report close-out; B5-coordinated edit since skill files are B5 territory). Feed intake excluded — disposition lives at B5 #F7/AS-028. Batch-prompting escape valve already addresses the health-assessment heavy-intake concern.

**A10 metrics recorded:** 31 mandatory steps → 21 proposed; zombies 1 hard + 2 textual → 0 at B6; kept-step consumer coverage 21/21. VO-026 checklist diff is the no-semantics-lost instrument.

**Adjacent findings (routed):** (1) startup-hook `feed_intel_inbox` counter reads decommissioned FIF SQLite → permanently 0 while `_openclaw/inbox/` holds a **34-item backlog** (2026-05-26→28, pre-FIF-decommission) — counter fix → B6 candidate w/ AS-028 coordination; (2) backlog itself → **operator decision pending** (process via feed-pipeline or discard); (3) vault-gc.sh comment role-inversion → one-line B6 fix. Stale refs for B6: Frontend/Backend Designer trigger names (agents don't exist), frontend/backend-design-summary examples.

**VO-025 ACs:** all four pass (4 ceremonies classified ✓, every kept step names consumer/enforcer ✓, zombie list includes session_reports.db write ✓, metrics table ✓). tasks.md → done.

**M3 status:** VO-023/024/025 done. Remaining for M3 close: VO-026 (B6 pack — **gated on AS-025**, classification input now ready) + M3-close drift diff (run at actual close, after VO-026). VO-016 (Appendix A freeze) still on AS session-boundary timing. No VO work unblocked beyond this point — project waits on AS gates.

## 2026-06-11 — Adjacent item closed: feed backlog operator decision (discard)

**Operator decision (logged from non-VO session for traceability):** The `_openclaw/inbox/` backlog flagged at VO-025 ("operator decision pending — process via feed-pipeline or discard") resolved: **discard**, per Danny during the liberation-directive v3 session. Executed 2026-06-11 — 22 `feed-intel-*` items deleted (flag counted 34 on 2026-06-10; 22 present at execution), inbox now empty. The startup-hook `feed_intel_inbox` counter fix (reads decommissioned FIF SQLite, permanently 0) remains a B6 candidate w/ AS-028 coordination — unchanged by this decision.

## 2026-06-12 — VO-026 complete: B6 changeset pack drafted + approved (question gate)

**Context inventory:** project-state + run-log tail + tasks.md VO-026/033 rows + design D5/B6 row + ceremony-classification.md (full — the pack's input) + the two target protocol docs (full — diff subjects) + inbox-processor SKILL.md §7-8 + session-startup.sh counter blocks (targeted reads). CLAUDE.md already in session context (post-AS-025 text). 5 project docs + 4 edit-target sources; no overlays; direct task execution under IMPLEMENT.

**Correction at session start:** operator prompt said "proceed with VO-025" — tasks.md shows VO-025 done 2026-06-10 (stale memory pointer, fixed). Actual unblocked task: VO-026 (AS-025 gate cleared earlier today). Proceeded with operator intent.

**Deliverable:** `design/changeset-b6-ceremony.md` — five items: B6-1 phase-gate procedure rewrite 11→6 (full replacement §Procedure + 11-row field-by-field checklist diff — the no-semantics-lost instrument; stale Frontend/Backend-Designer + design-summary-example refs fixed), B6-2 session-end rewrite 10→7 (zombie session report CUT-retire-not-repoint; 6b AKM residue deleted; .processed sweep cut; commit+push merged; 6a/6b numbering drift fixed), B6-3 inbox-processor §7+8 fold (B5-coordinated single edit), B6-4 CLAUDE.md second pass (one line: conditional commit & push), B6-5 session-startup.sh dead-counter sweep.

**Ground-truth deltas incorporated (classification was 06-10; three AS events since):** AS-026 archived `_openclaw/` → step-8 cut rationale upgrades to "target dir gone", vault-gc comment fix mooted; AS-028 retired feed-pipeline outright → counter "re-point" option dead, remove is the only disposition; AS-025 applied → CLAUDE.md diff drafted against current text, freeze tag reduces to frozen-pending-operator-apply.

**Scope expansion found at drafting (flagged in pack, put to operator):** classification named 1 zombie startup counter; verification grep found **6** counter blocks reading dead sources (`_openclaw/feeds/research`, `~/.tess/state/dispatch`, `_openclaw/research/output`, `_openclaw/inbox/brainstorm-*`, FIF pipeline.db, `~/.tess/state/z4-candidates`) — all emitting permanently-zero keys into every startup context.

**Question gate (operator, in-conversation, 2026-06-12):** (1) B6-1..B6-4 **APPROVED as drafted**; (2) B6-5 **APPROVED at full six-counter sweep scope**. Approval recorded in pack header. Apply remains stop-and-ask per edit at VO-033 (VO-008 B6 batch).

**VO-026 ACs:** all three pass (diff per protocol doc w/ rationale ✓; checklist diff field-by-field ✓; CLAUDE.md diff frozen, tagged, not applied ✓). tasks.md → done.

**M3 status:** VO-023/024/025/026 done, all four packs (B3-B6) drafted AND approved. M3 close remaining: drift diff (run at actual close). VO-016 still on AS session-boundary timing. Apply batches (VO-031/032/033) follow M4 order.

## 2026-06-12 — Early partial B3 apply (operator manual sweep) + reconciliation

**Event:** At 16:29, during session-end, operator manually trashed 16 `_system/docs` + `_system/perplexity/` files via Obsidian — detected as unstaged deletions at the session-end commit's status check; deletion source identified via Trash forensics (all 16 present in ~/.Trash; `_system/docs` mtime 16:29:11). Operator confirmed deliberate cleanup at question gate.

**Reconciliation against the approved B3 pack:**
- **12 of 16 = approved B3 delete rows** → kept deleted, committed this entry: claude-ai-session-prompt (R2), code-setup-prerequisites, openclaw-colocation-spec (+summary), openclaw-crumb-reference, openclaw-memory-research, openclaw-skill-integration, vault-intake-overview-diagram (+.excalidraw), perplexity/ ×3.
- **4 of 16 = B3 Constitutional KEEPS, restored** via `git restore`: crumb-v2-system-health-assessment (CLAUDE.md-cited), capture-tiers (R9 dependency), claude-code-ssh-setup, crumb-studio-migration (remediation target of the colocation deletion). Operator sweep used the B3 *filename pattern* memory, not the disposition list — keeps were collateral.
- **Operator also deleted 89 `_system/daily/` daily-attention artifacts** (Mar–Jun) — not pack-scoped; Class 1 operational consumables, operator-owned, git history preserves; confirmed intentional at question gate, committed.

**Remediations executed (per approved pack, early):** architecture/04-deployment ×2 + crumb-studio-migration ×3 colocation-spec refs → git-provenance citations; crumb-design-spec-v2-4 §integration-reference → git citation (order gate AS-029 verified done); claude-ai-session-prompt body folded into claude-ai-context.md as Appendix (R2 merge-into); canonical-taxonomy-sync-points memory: perplexity sync-point removed + dead `_openclaw/scripts/daily-attention.sh` sync-point removed (AS-026 archival).

**B3 status:** PARTIALLY APPLIED EARLY (12 rows of the delete list + their remediations). Remainder of B3 (root-doc deletes incl. feed-intel-processing-chain, tess-crumb-*, R5/R6/R8/R9/R10 rows, solutions deletes, skill-workflows orphans, etc.) still applies at VO-031 batch open — **batch-open checks must treat these 12 rows as done** (changeset-staleness check will surface them; this entry is the provenance).

**Compound candidate (first instance):** operator-manual applies happen out-of-band when delete lists live in operator memory — batch discipline assumed Claude executes; vault detected the divergence only via session-end status check + Trash forensics. If a second out-of-band apply occurs, propose: approved-pack summary view for operator (one page, keep/delete columns) so manual sweeps work from the disposition list, not recall.

## 2026-06-14 — VO-016 complete: Appendix A ownership matrix frozen (M2 closes)

**Session start (fresh, vault-based state reconstruction):** project-state + run-log (full) + tasks.md + action-plan-summary + cross-project-deps.md (XD-027) + agentic-sunset project-state + AS run-log tail + manifest Appendix A. Context inventory: 6 project/system docs (standard tier); no overlays (unchanged — Crumb-internal infra); no skill invocations (direct task execution under IMPLEMENT).

**Gate cleared:** XD-027 confirms AS-side fully satisfied — **AS M6 (AS-025–029) complete 2026-06-12 + AS-021 reboot passed 2026-06-14**. VO-016 was the only remaining gate on VO-031/032 (B4/B5 primitive batches); it was parked solely on AS session-boundary timing, now cleared.

**VO-016 executed:**
- **Appendix A frozen** (`keep-set-manifest.md`): header `NOT YET FROZEN` → `FROZEN 2026-06-14`; all 8 joint-surface rows owner + gate verified per D1 schema; added `Gate status` column recording per-gate met/pending/N-A (ownership frozen regardless of gate passage). Gate states: CLAUDE.md MET, skills/agents MET (AS M6), harness-memory N/A (AS-029 owns, VO never writes), `_openclaw/_tess/_staging` N/A (AS archived), scripts/protocols/overlays MET (this freeze), docs+solutions no-gate, `Archived/_attachments` PENDING (opens at VO-027 B0 restore-drill), live plists dashboard-locked + rest-per-manifest.
- **AS concurrence recorded in both run-logs** (per AC): VO run-log = this entry; AS run-log = cross-project concurrence entry 2026-06-14 (explicitly tagged not-AS-work, soak tracker untouched).

**VO-016 ACs:** all three pass — every joint surface has owner + gate per D1 schema ✓; AS run-log concurrence note exists ✓; matrix marked frozen ✓. tasks.md → done.

**Milestone status: M2 COMPLETE** (VO-011–022 all done). **M3 already complete** (VO-023–026 all drafted + approved; B3 partially applied early via operator manual sweep 2026-06-12). **Project now poised at M4 entry** — the destructive batch sequence. Next task **VO-027 (B0 git-remote restore-drill gate)** is HIGH-risk and stop-and-ask; it is the gate before any deletion batch and folds in the M3-close/M4-entry inventory drift diff (batch-open check per peer-review amendment A2). No further VO work is unblocked without operator go-ahead on entering M4.

**Compound:** no new solutions doc — VO-016 was a clean timing-gated freeze with no surprises; AS-side gates resolved exactly as XD-027 predicted. Confirming instance only.

## 2026-07-03 — M4 ENTRY + VO-027 complete: B0 restore-drill gate PASSED + drift diff clean

**M4 entry approved (operator, in-conversation, 2026-07-03)** — "Yes, run VO-027 now"; deletion batches VO-028+ still stop at their own gates.

**Session start (fresh, vault-based state reconstruction):** project-state + run-log tail + tasks.md + action-plan (B0/M4 sections + baseline block) + design D1 (regen command set) + storage-policy (freshness targets) + .gitignore. Context inventory: 5 project docs + 2 system surfaces (standard tier); no overlays; no skill invocations (direct task execution under IMPLEMENT). Stale memory pointer fixed at session start (memory said "next VO-025" — done 06-10; second instance of the 06-12 pattern, memory files updated).

### M3-close / M4-entry inventory drift diff (batch-open check per A2)

Regenerated per D1 command set vs 2026-06-10 baseline (2,511→2,515 md · 20/4/8/20/6/25/12/10):

| Surface | Baseline | Now | Verdict |
|---|---|---|---|
| md files (find, on-disk) | 2,515 | 2,412 | **Explained** — 103 tracked deletions = exactly the 06-12 operator sweep (12 B3 rows + 89 `_system/daily/` + perplexity ×3, run-log reconciliation entry); +76 adds = project artifacts + AS-027's 191-file formerly-ignored archive intake (md subset); untracked-churn remainder = 06-11 backlog discard + inbox processing |
| skills | 20 | 19 | **Explained** — feed-pipeline retired to `_system/archive/skills-retired/` by AS-028 (`afe2d7a8`); B5 pack row F7 (keep-with-strip) superseded → **B5 batch-open treats as done** |
| agents | 4 | 4 | unchanged |
| overlays | 8 | 8 | unchanged (raw `grep -c '^|'` reads 15 — index now carries a 2nd companion-doc table; 8 overlay files verified by ls) |
| scripts | 20 | 22 | **Explained** — +`vault-health.sh` + `lib/cron-lib.sh`, both AS-019 keep-set members (`d5759325`); post-baseline, not in manifest → **B4 batch-open note: AS-owned keeps, out of B4 scope** |
| protocols | 6 | 5 | **Explained** — `bridge-dispatch-protocol.md` archived by AS-028; was already "superseded" at VO-014 → **B4 batch-open treats its row as done** |
| solutions | 25 | 25 | unchanged |
| projects | 12 | 12 | unchanged |
| plists (on disk) | 10 | 11 | **Explained** — +`com.crumb.vault-health.plist` (AS-019, keep-set); dashboard plist retained-disabled as before |
| Archived/ | 147M | 149M | **REAL SCOPE DRIFT** — see below |

**B1 scope drift (carries to VO-028 batch-open):** `Archived/_openclaw`, `Archived/_tess`, `Archived/_staging` were created by AS-026/027 (2026-06-12) *after* the VO-021 enumeration — three top-level dirs now inside B1's delete-unless-canonical scope with no enumeration rows and no exception decisions. These are the sunset's provenance/rollback archives (rollback window formally closed 06-14 per AS-022/021, so deletion is *permissible* — but it is an operator disposition call, not pack-covered). **VO-028 batch-open MUST: re-enumerate Archived/, present AS-archive disposition to operator.** Live-dependency check done now: the GWS OAuth token store used by the live workspace-mcp is at `~/.google_workspace_mcp/credentials/` (outside vault); `Archived/_openclaw/lib/gws-token.sh` is a dead archived reader — no live consumer reads from Archived/. ✓

**Drift verdict: no unexplained drift; no changeset stale in a blocking way.** Three notes carried forward: B1 re-enumeration + AS-archive disposition (VO-028); B4 bridge-dispatch row done + 2 new AS-owned scripts out of scope (VO-031); B5 F7 done (VO-032). B3's 12 pre-applied rows already on record (06-12 entry).

### B0 restore-drill (git remote, authoritative source)

**Freshness (secondary checks first):** `backup-status.json` status ok, tarball `crumb-vault-2026-07-03_0300.tar.gz` (120.8 MB) ageHours 10; drive-sync 05:00 run DONE clean; mirror-sync last SYNC 07-02 15:53 = last commit (post-commit trigger, current). All fresh ✓. (Same-session AS-031 Day-3 soak check corroborates.)

**Procedure + results:**
1. `git ls-remote origin main` = local HEAD = `49143a99` (remote current, tree clean) ✓
2. Fresh clone of `https://github.com/djt71/crumb-vault.git` → throwaway dir in session scratchpad (`vo027-restore-drill/`); clone HEAD `49143a99`, 3,227 tracked files ✓
3. **Sample restore verification — 11 files, ≥1 per top-level dir, sha256 clone-vs-vault: 11/11 MATCH.** CLAUDE.md (root) · .claude/skills/systems-analyst/SKILL.md · _system/scripts/vault-check.sh · **Archived/_openclaw/lib/gws-token.sh (new B1-scope content restores)** · Domains/Career/accounts/auto-club-group/meeting-prep-2026-03-19.md · Projects/vault-optimization/tasks.md · Sources/articles/chrlschn-mcp-dead-long-live-mcp-index.md · _attachments/career/SEC2-security-ecosystem-visual-capture.md · _scratch/akm-test-prompt.md · Sources/articles/.gitkeep · **Projects/think-different/attachments/albert-einstein.jpg (tracked binary restores byte-identical)** ✓
4. **vault-check on restored clone (`--full .`): 0 errors, 76 warnings, exit 1 (non-blocking).** Warnings are pre-existing content debt, not restore artifacts — dominated by broken wikilinks inside `Archived/` research briefs pointing at decommissioned paths (B1 deletion scope; consistent with the 07-01 audit's known post-teardown link debt). Blocking-gate semantics: pre-commit blocks exit 2 only → **restored set passes** ✓
5. Throwaway clone deleted after drill.

**Ignored-path coverage (documented per AC):** clone correctly **lacks** `_inbox/`, `.mcp.json`, `.trash/`, `_system/logs/` churn set (backup-status.json, vault-backup-last.json, …), `_system/state/last-run/`, non-whitelisted binaries (e.g. `_attachments/learning/wyner-fluent-forever.pdf`) — all confirmed absent-in-clone/present-locally. **Coverage for these:** `vault-backup.sh` tars the *entire* vault dir with **zero exclusions** → every gitignored path is in the nightly iCloud tarball (fresh today, gzip-tested 07-01); runtime logs/state additionally regenerate from live jobs; `.mcp.json` secrets deliberately out of git (tarball-only — correct). One hygiene note: `.obsidian/` is gitignored but 3 files are tracked-before-ignore (app.json, appearance.json, core-plugins.json) — they restore fine (present in clone); rest of `.obsidian/` is tarball-covered. Not a gap; noted for B6-adjacent cleanup if ever wanted.

**VO-027 ACs:** drill passed + procedure/results in run-log BEFORE any deletion ✓ · ignored-path coverage documented ✓ · restored sample passes vault-check (0 errors; non-blocking warnings are pre-existing, enumerated) ✓. tasks.md → done.

**Gate state: B0 GREEN — M4 batch sequence is open.** Next: VO-028 (B1 Archived/) — batch-open = changeset-staleness check + fresh drift diff + **Archived/ re-enumeration + operator disposition on `_openclaw`/`_tess`/`_staging` AS archives** + exception-extraction (E1/E2/E3) before any deletion. HIGH risk, stop-and-ask.

## 2026-07-03 — VO-028 complete: B1 Archived/ batch EXECUTED (same session as B0)

**Batch-open checks (logged before execution):** drift diff = fresh this session (VO-027 entry above). Changeset staleness on VO-021 enumeration: E1/E2/E3 sources + all cited consumers re-verified unchanged; D1/D2 targets live; tracked count 880 → 1,070 (+190 = AS-027 formerly-ignored intake, tracked size 14M → 17M) — explained, no stale dispositions. Fresh consumer sweep: `[[Archived/` wikilinks from kept docs = only the two known E1/E2 consumers; path-mentions of the new AS dirs = AS project records + regenerating logs only.

**AS-archive disposition (operator, in-conversation, 2026-07-03):** `_openclaw`/`_tess`/`_staging` → **E4-extract config, delete rest.** New exception E4 = `Archived/_openclaw/config/` 4-pack (`google-calendars.json`, `gmail-label-ids.json`, `email-domain-denylist.txt`, `operator_priorities.md`) → `Projects/agentic-sunset/design/external-artifacts/` — justification: live consumer = pending AS-032 external-artifact sweep (Calendar/Drive/Discord). Sweep-input notes: `google-drive-folders.json` was already git-history-only pre-archival (removed at `44248ac4`); richer source specs (tess-google-services/comms-channel/apple-services) deleted with tess-operations — git pointers recorded in AS run-log for AS-032.

**Execution (batch cycle per plan):**
1. **Extraction commit `f3ee74ad`** (BEFORE deletion, per AC): 213 renames + 5 consumer edits + 2 frontmatter patches. E1 → `_system/docs/notebooklm-workflow-guide.md` (learning-overview + templates README wikilinks updated); E2 → `_system/docs/vault-mirror-specification.md` (moc-crumb-architecture wikilink updated); E3 → `_system/data/deliberations/` — records + `raw/` (164 files) at store root, matching the approved B5 re-point target; `baseline/` + gate-evals + experimental-results alongside; E4 as above. D1: write-read-path-verification link → past-proposal note + git provenance. D2: capture-tiers citation → git-history pointer. Frontmatter schema gate (2026-06-11 fm_issue fix) correctly blocked first attempt — `status`/`project` fields patched on 2 moved files. ✓
2. **Deletion:** `git rm -r Archived/` + `rm -rf Archived/` — **857 tracked deletions** (enumeration-by-reference per convention: full list reproducible via `git show f3ee74ad --name-only` state or `git ls-tree -r f3ee74ad --name-only -- Archived`), plus ~133M untracked venv trees (batch-book-pipeline ×2 + pydantic-ai-adoption). Disk recovered ≈149M.
3. **SKILL.md re-point (same batch, per B5 pack's cross-batch note):** deliberation/SKILL.md:241-242 → `_system/data/deliberations/` + `raw/` — closes the E3 stale-path defect (B5 batch-open verify will find it done).
4. **Functional fast-pass:** E1/E2/E3/E4 targets exist ✓; zero `[[Archived/` wikilinks vault-wide ✓; residual `Archived/` path-mentions = D3 taxonomy class (file-conventions, archive-conventions, spec v2-4, architecture 02/04/05, vault-gardening — all already routed to B3/B5 packs) + this batch's own git-provenance pointers + claude-ai-context.md (regenerates at session end) ✓.

**Adjacent finding (→ B3):** `moc-crumb-architecture.md:38` links `[[Projects/crumb-tess-bridge/design/specification]]` — pre-existing broken path (project lived under Archived/, link never updated); untouched by this batch, added to B3 remediation awareness.

**VO-028 ACs:** batch-open checks logged ✓ · exception list finalized + committed BEFORE deletion ✓ (`f3ee74ad`) · Archived/ deleted ✓ · consumers remediated same batch ✓ · vault-check green + fast-pass at commit ✓ (deletion commit below) · deletions enumerated in run-log ✓ (857 by-reference + venv trees). tasks.md → done.

**Next: VO-029 (B2 attachments/logs, 3 sub-batches by risk profile)** — batch-open checks per sub-batch; VO-030 (B3 docs remainder) also unblocked. B1 exception note: E4 was operator-added at batch open (not in VO-021) — enumeration doc left as-was (historical); this entry is E4's provenance.

## 2026-07-03 — Session-end (compound evaluation)

**Session summary:** Triple-scope session: (1) AS-031 soak v2 days 2–3 ticked green (day 2 backfilled from tarball + drive-sync evidence + PID continuity); (2) VO-027 B0 restore-drill gate PASSED + M4-entry drift diff clean → M4 entered on operator go-ahead; (3) VO-028 B1 executed full cycle — E1–E4 extraction commit `f3ee74ad`, Archived/ deletion commit `f00b43ca` (857 tracked + ~133M untracked venvs), same-batch remediations, fast-pass green. All pushed. claude-ai-context.md refreshed (was 14d stale; now reflects soak v1 failure/v2, M4, Archived/ deletion).

**Compound evaluation:**
1. **Stale project-memory pointer, second instance** (memory said "next VO-025"; actual next was VO-027 — same class as 2026-06-12's stale pointer). Confirming instance of the project-pitfalls trust hierarchy (vault state > memory); handled by updating memory at state-reconstruction time. New micro-rule adopted: refresh the project memory pointer at session end whenever project state advanced (done this session). No new solutions doc.
2. **The A2 batch-open discipline caught real scope drift on first live use** — the drift diff surfaced three post-enumeration dirs (AS archives) inside B1's delete scope, forcing an explicit operator disposition (E4) instead of a silent wholesale delete. Confirming instance of the amendment's design intent; validates keeping batch-open checks mandatory for B2–B6. No new doc.
3. **Frontmatter commit-gate first live catch** — the 2026-06-11 fm_issue fix blocked the extraction commit on 2 moved files missing schema fields for their new locations. Gate works as designed; lesson folded into practice: `git mv` across schema boundaries (Archived→_system/docs, →Projects/) needs a frontmatter pass before commit. Noted here; B2–B6 have no cross-boundary moves of this class remaining except B3 merges (aware).
4. **Git-hook output noise nearly misread as a wrong commit** (post-commit mirror hook echoes rename/create lines + a "sync:"-prefixed mirror commit id). Verified ground truth via `git show --stat` before reacting — recurring-patterns prompt-env/verify-before-alarm reflex, confirming instance.

**Code review sweep:** N/A — no `repo_path` (vault-only). **Build verification:** N/A. **Amendment Z + inbox sweep:** skipped (dead infra, decommissioned). **Failure log:** not warranted — session executed cleanly.

**Model routing:** all main-session (Fable 5, first session on it); no Sonnet delegation — session was judgment-dense end to end (M4 gate, disposition calls, destructive batch execution). No skill invocations (direct task execution under IMPLEMENT); no token-heavy anomalies (full vault-check on clone ran ~4 min in background, backgrounding kept it off the critical path).

**State for next session:** VO at M4 with B1 done — next VO-029 (B2) or VO-030 (B3), both unblocked, batch-open checks required. AS-031 soak day 4 check due 2026-07-04 (session-opener mechanism).

## 2026-07-03 — VO-029 complete: B2 attachments/logs batch EXECUTED (3 sub-batches)

**Session start (fresh, vault-based state reconstruction):** project-state + run-log tail + tasks.md VO-029 row + storage-policy.md (full — the batch's governing pack). Context inventory: 4 project docs + targeted evidence greps (producers, consumers, .gitignore); no overlays; no skill invocations (direct task execution under IMPLEMENT). Medium risk — proceed + flag per tier.

**Batch-open checks (logged per sub-batch, before execution):** changeset staleness on storage-policy (VO-022, 2026-06-10) verified via fresh re-audits below — one disposition superseded by events (tess-v2 venv, sub-batch ii) and one disposition pointer found dangling (vault-audit-status.json, sub-batch iii); both resolved and recorded in-line. Drift diff: fresh this session's morning entries (VO-027, same day) — not re-run.

### Sub-batch (i) — `_attachments/` orphan sweep (low risk)

**Orphan check (fresh audit 2026-07-03):** 9 files, 4.7 MB (7 tracked + 2 gitignored binaries). Per-file companion/inbound-embed evidence: 3× `infoblox-universal-ddi-customer-fig*.png` ← embedded by `Sources/other/infoblox-universal-ddi-customer-pres-digest.md` ✓ · `wyner-fluent-forever.pdf` ← companion note beside it ✓ · `friday-fuel-*-companion.md` + `inbound-infoblox-*-companion.md` ← linked from `Domains/Career/career-overview.md` ✓ · `SEC2-security-ecosystem-visual-capture.md` = md capture content, not a binary orphan (kept). **Yield: 0 orphans — matches policy prediction (≈0). Recorded either way per policy.** Only action: untracked `.DS_Store` junk removed from disk (regenerating macOS noise, not a policy item).

### Sub-batch (ii) — non-md heavyweights (medium risk)

**Size audit re-run per drift rule (top-20 >1M, excludes .git/.obsidian; Archived/ no longer exists):** 3 hits — `james-watson.jpg` 9.1M (keep — active think-different embed, unchanged) · `tess-v2/scripts/.venv/**/_pydantic_core*.so` 4.0M (see below) · `wyner-fluent-forever.pdf` 3.9M (keep — live companion, gitignored by design, unchanged).

**Disposition change, flagged (policy said "rides with AS-030, not VO scope"):** AS-030 closed tess-v2 → DONE on 2026-06-14 *without* deleting the vault-side venv — the ride never happened; the drift-rule re-audit caught it still present. Present-state evidence: project DONE, execution layer decommissioned + reboot-verified absent, external repo retained separately at `~/crumb-apps/tess-v2`, venv untracked (0 git impact), regenerable by definition, and the source of vault-health.sh's nightly frontmatter-warning noise ("venv .md junk under tess-v2"). **Deleted `Projects/tess-v2/scripts/.venv/` — 23 MB, 1,953 untracked files.** Tess-v2 dir now 3.7 MB. Vault-wide venv scan confirms zero remaining venv trees. Cross-note written to AS run-log (the policy's original flag target). vault-health-notes.md warnings self-clear at tonight's run.

### Sub-batch (iii) — dead logs (producer-alive rule, low risk)

**Producer-alive evidence (fresh, per log):**
- `health-check.log` + `health-check-launchd.err` + `health-check-launchd.log` — producer `tess-health-check.sh` dead since 2026-06-01: no matching plist in `~/Library/LaunchAgents/` (only `com.crumb.vault-health.plist` matches health*), script itself B4 delete-listed (dies at VO-031). **Deleted — 3 tracked files, `git rm`.**
- `llm-health.json` + `ops-metrics.json` (both last written 2026-06-10 — the day the Tess/dashboard layer went dark) — **no producer anywhere**: zero references in `_system/scripts/`, hooks, or any loaded plist. Dead under the standing rule. **Deleted — 2 untracked files; their 2 dead `.gitignore` lines removed same batch.**
- Keeps verified live: `akm-feedback.jsonl` (skill-preflight hook; 103K, under the 1 MB rotation watch) · `session-log.md`/`-2026-02` (session-end protocol) · `mirror-sync.log`/`vault-gc.log`/`vault-check-output.log` (live plists/hooks) · `system-stats.json` (system-stats.sh + live plist, current today) · `backup-status.json`/`vault-backup-last.json` (backup jobs, current) · `ops-metrics.jsonl` + `vault-health.log` + `vault-health-notes.md` (cron-lib.sh + vault-health.sh, AS-019 keep-set — post-policy additions, producers verified).
- `vault-audit-status.json` — **kept; disposition pointer was dangling.** Storage policy deferred to "VO-025 ceremony classification" but the classification doc never mentions it (VO-025's scope was the 4 ceremonies; audit skill step 17 wasn't in it, and the B5 pack's audit-skill rows cover D4 Archived/-purge steps only). Producer alive (audit skill step 17, last write 07-01 = last full audit); consumer MC dashboard paused-not-deleted (AS-030). Producer-alive rule → keep; deleting would just regenerate at next audit. **Routed: B5 batch-open addendum (VO-032) — operator decides audit SKILL.md step 17 retire-vs-keep given dashboard pause.**

**Consumer remediation (same batch, D4 discipline):** `infrastructure-reference.md` Log Locations table — 2 dead rows (llm-health.json, ops-metrics.json) removed; ops-metrics row re-pointed to live `.jsonl` + vault-health rows added (B3 pack does not own this doc — verified, so remediation lands here). `.gitignore` ×2 dead lines removed.

**Functional fast-pass:** residual-reference sweep on all deletions — remaining hits are: `tess-health-check.sh:27` (the B4-delete-listed producer itself, never runs — plist gone), AS/tess-v2 design docs (historical project records, untouched by convention), vault-health-notes.md (regenerates clean tonight), VO project docs (this batch's own provenance). Zero live consumers of deleted content ✓. All keeps present ✓.

**Adjacent findings (routed):** (1) `infrastructure-reference.md:205` "Bridge watcher | `_openclaw/logs/watcher.log`" — pre-existing dead row (openclaw layer deleted), not this batch's deletion → **B3 awareness** (doc not currently in B3 pack; candidate addendum). (2) vault-audit-status/step-17 → **B5 addendum** (above).

**Deletions enumerated:** 3 tracked (`_system/logs/health-check.log`, `health-check-launchd.err`, `health-check-launchd.log`) + untracked: `llm-health.json`, `ops-metrics.json`, `_attachments/.DS_Store`, `Projects/tess-v2/scripts/.venv/` (1,953 files, 23 MB). Disk recovered ≈23 MB.

**Commit note:** sub-batches (i) and (ii) produced zero tracked deltas (i = zero-yield, ii = untracked venv), so the per-sub-batch commits collapse into one batch commit carrying sub-batch (iii)'s tracked deletions + remediations + this record. Green + fast-pass verified before it (above; vault-check runs at pre-commit).

**VO-029 ACs:** batch-open checks logged per sub-batch ✓ · orphan check (i), size audit (ii), producer-alive evidence (iii) recorded per respective sub-batch ✓ · all deletions match policy (venv disposition-change flagged with rationale; standing dead-producer rule applied to the 2 stale JSONs) ✓ · green + fast-pass at the (collapsed) batch commit ✓. tasks.md → done.

**Next: VO-030 (B3 docs remainder)** — 12 rows pre-applied 06-12; carried notes: moc-crumb-architecture:38 broken crumb-tess-bridge link + infrastructure-reference Bridge-watcher dead row (this batch). Then VO-031 (B4), VO-032 (B5, + step-17 addendum), VO-033 (B6).

## 2026-07-03 — VO-030 complete: B3 docs batch EXECUTED (same session as VO-029)

**Context inventory (continuing session):** changeset-b3-docs.md (full — governing pack) + 06-12 reconciliation entry (pre-applied rows) + targeted reads of every edit target; no overlays; no skill invocations (direct task execution under IMPLEMENT). Medium risk — proceed + flag per tier.

### Batch-open checks (logged before execution)

**Pre-applied rows honored:** all 12 rows of the 2026-06-12 operator manual sweep confirmed absent from disk (openclaw-* ×4, code-setup-prerequisites, claude-ai-session-prompt [R2 merge — done as claude-ai-context appendix], vault-intake-overview-diagram ×2, perplexity/ ×3), their 06-12 remediations verified in place (arch/04:17,340 colocation → git citations ✓). AS-029 order gates verified done (openclaw-crumb-reference consumed; perplexity memory sync-point removed).

**Changeset staleness — every remaining disposition re-validated:** all delete/merge targets present on disk; ref-counts re-swept fresh. Deltas vs pack (all favorable, none blocking): security-kb-plan/network-kb-plan external refs now 0 (were self/sibling); egpu refs = tess-v2 run-log only (historical record); vault-intake-map refs collapsed to 1 same-batch referrer (the pack's expected bridge-watcher-row remediations died in B1/AS — pack's "note cross-batch: B4" is moot); why-two-agents/first-tess-interaction refs all same-batch; system-architecture-diagram refs collapsed 6 → 1 (arch/01:17 attribution). New refs found and remediated: signals-archive in spec v2-4 ×3 lines; peer-review-skill-spec in spec ×2 + git-commands.md:11-12 (frozen illustrative example — left, non-structural); liberation-surfaces-snapshot in work-surfaces.md (post-pack doc).

**Scope drift on `_system/docs/`:** 6 post-pack additions, all explained live keeps — notebooklm-workflow-guide (E1 home), vault-mirror-specification (E2 home), crumb-operating-note (VO-011), adr-vault-write-boundary + work-surfaces + cowork-global-instructions (liberation-v3/work-surfaces session 06-11). Not B3 scope.

**Staleness flag → B5 batch-open addendum (A2, evidence-status change):** `feed-pipeline-philosophy.md` (B3 keep, explanation cluster) explains the feed-pipeline skill AS-028 later retired outright; same class as the pack's already-deferred run-feed-pipeline.md (deferral outcome now known = delete) and `triage-feed-content.md` (how-to keep, dead FIF triage subject). All three routed to VO-032 B5 batch-open as one operator question: keep-as-history vs delete for feed-docs trio.

### Execution

**Merges (extraction commit discipline — content folded before source deletion, same commit):**
- agent-skills-best-practices → skill-authoring-conventions §"External Best Practices (Gechev synthesis)": four adopted principles (200-line JiT trigger, third-person imperative, four-phase validation loop, script promotion rule) + not-adopted list; See-Also wikilink replaced by the internal section; file-conventions:97 example re-pointed to a live example (notebooklm-workflow-guide/learning-overview).
- claude-print-cwd-sensitivity → claude-print-automation-patterns as Pattern 5 (CWD sensitivity, full problem/solution/counterexample + OSC-016 evidence line).

**Deletions — 44 tracked (`git rm`) + 1 untracked:** root docs ×19 (adr-cli-native-agent-architecture, change-spec-skill-model-routing, compound-enhancements-spec + -summary, feed-intel-processing-chain + -diagram, peer-review-skill-spec, proposal-pattern-enforcement-schema, tess-crumb-boundary-reference, tess-crumb-comparison, vault-startup-detection-diagram, security-kb-plan, network-kb-plan [R5], liberation-surfaces-snapshot [R6], system-architecture-diagram [R8], vault-intake-map [R9, #F2], vault-restructure-analysis-20260220 + -discussion [R10], agent-skills-best-practices [merge source]) · solutions ×3 (claude-print-cwd-sensitivity [merge source], lucidchart-policy-compliance, egpu-local-compute-evaluation [R11, #F1]) · skill-workflows/ ×15 (whole orphan layer) · schemas/a2a/ ×2 + schemas/capabilities/manifest.yaml · docs/attachments/tess-crumb-architecture.md (+untracked .png, dir removed) · signals-archive-2026.jsonl [R16] · why-two-agents.md · first-tess-interaction.md. Full list reproducible: `git show <this commit> --name-only`. schemas/briefs/ untouched (B5-reassigned per pack).

**Consumer remediation (same batch, D4):**
- moc-crumb-architecture: 6 Core rows dropped (:38 crumb-tess-bridge broken link [carried finding] + :39-41 tess-crumb trio + :42-43 restructure pair).
- Architecture cluster: 01/02/03 source-attribution lines de-linked (formerly-X + git-history phrasing; arch/03 also covers archived bridge-dispatch-protocol); arch/02 Bridge-Dispatch + Dispatch-Triage protocol rows dropped, bridge-watcher + feed-inbox-ttl script rows dropped (latter = adjacent dead row, script gone), Plus-line cleaned (batch-book-pipeline gone; bridge-watcher/tess-health-check marked awaiting-B4), Archived/ row → A11 reword; arch/03 historical banners added to flows 2/3/5 + partial banner on 4 (pack targeted flow 5; 2-4 same sunset-era class — within cluster instruction "strip/annotate", flagged here); arch/04 top banner (largely-historical framing resolves the :88/94/147 bridge-watcher targets without erasing history) + tess-health-check "preserved for repair" → delete-listed-at-B4 + tree Archived/ node reword; arch/05 frontmatter-rules existence assumption reworded.
- A11 taxonomy: AGENTS.md Archived/ row reworded + dead `_openclaw/` row dropped (adjacent, dir deleted); vault-structure-reference tree (Archived/KB/ line removed — delete-over-park is permanent, unlike Archived/Projects which recreates) + project-docs header reword; file-conventions :433 KB-flow rewrite (delete with git provenance) + Archived/KB removed from non-project location list (consequence of the approved KB-flow rewrite; pack said keep :41 but the location class is retired with the flow — flagged); vault-gardening full KB-flow rewrite (archive→delete with git provenance; Purge Review stage removed, reference checks moved to pre-deletion; design decisions updated with delete-over-park rationale); archive-conventions:146 wording verified fine as-is (reopening procedure survives).
- Pointer re-points: liberation-directive :21,26 snapshot links → git-provenance phrasing (constitution edit, minimal); work-surfaces :22 → git citation (:9 `supersedes:` field left — provenance metadata); peer-review-config :89 → retired + git history; spec v2-4 ×5 lines (2 tree lines removed, signals-archive table row + §4.9-retired note + task-25g citation → git-history phrasing).
- mission-control-orientation rewritten as truthful stub: dashboard paused-stripped state, FIF walkthrough retired to git history, re-author-on-resume note (pack: "strip dead panels; dashboard kept per A3" — stripping left no live panels to describe).
- Carried finding closed: infrastructure-reference :205 Bridge-watcher dead row removed.
- `updated:` frontmatter bumped on all 15 substantively edited docs; no summaries exist for any edited doc (freshness gate clear).

**Functional fast-pass:** zero wikilinks to any deleted basename outside historical records (run-logs/reviews/session-logs) ✓; zero schemas/a2a|capabilities path refs ✓; skill-workflows mentioned only in crumb-operating-note (accurate historical decision prose) ✓; orientation-map has no rows for deleted docs ✓; Archived/KB residuals = audit SKILL.md steps (B5 pack's known D4 edits — already routed) + git-provenance pointers (correct usage) ✓; all keep-cluster targets present (R1/R4/R7/R12-R15 spot-verified) ✓.

**Adjacent findings (routed):** (1) moc-crumb-architecture Synthesis paragraph still describes the decommissioned architecture (OpenClaw/Telegram/FIF) as current — synthesis rewrite is a judgment edit → flagged for audit/M5 pass, not B3 mechanical scope. (2) arch/02 §9 "Bridge" and arch/04 migration-state prose remain as-of-writing snapshots under the new banners — acceptable per approved pack scope; full architecture-doc refresh is VO-009-adjacent post-B5 work. (3) feed-docs trio → B5 (batch-open flag above). (4) git-commands.md frozen example with dead filenames — left, illustrative only.

**VO-030 ACs:** batch-open checks logged ✓ · pack fully applied (12 rows pre-applied + all remaining rows executed; every remediation in the same batch) ✓ · zero dead wikilinks to deleted/AS-archived paths in kept docs ✓ (fast-pass above) · green + fast-pass at commit ✓ (vault-check at pre-commit, this commit). tasks.md → done.

**Next: VO-031 (B4 scripts/protocols/overlays)** — carried notes: bridge-dispatch row done; vault-health.sh + lib/cron-lib.sh AS-owned out of scope; tess-health-check.sh delete confirmed (logs died at B2, arch/02+04 now say awaiting-B4); dispatch-triage-protocol.md still on disk (rows stripped here, file is B4's). Then VO-032 (B5 — addenda: step-17 retire-vs-keep + feed-docs trio), VO-033 (B6).

## 2026-07-03 — VO-031 complete: B4 scripts/protocols/overlays batch EXECUTED (same session)

**Context inventory (continuing session):** changeset-b4-scripts-protocols-overlays.md (full — governing pack) + targeted reads of every remediation target; no overlays; no skill invocations. HIGH risk per tasks.md — stop-and-ask satisfied by explicit operator go-ahead in-conversation ("pls proceed", 2026-07-03, immediately after B3 close-out named VO-031 as next).

**Batch-open checks (logged before execution):**
- **Preconditions:** B0 green (VO-027) ✓ · Appendix A frozen (VO-016) ✓ · AS M6 sign-off in AS run-log (verified at VO-016) ✓.
- **Order gate (bridge-dispatch-protocol):** CLAUDE.md carries zero bridge mentions (AS-025 applied 2026-06-12) ✓. The protocol file itself was already archived by AS-028 → **row treated as done per drift-diff carry-note**; only its orientation-map remediation remained (executed below).
- **Cross-batch verification (forward-fix rule):** all B3 edits this pack depends on confirmed landed this session — vault-intake-map deleted (R9) ✓, arch/02:143/146 protocol rows stripped ✓, arch/02 scripts-table bridge-watcher row stripped ✓, arch/03 flow-5 banner ✓, arch/04 banner + tess-health-check line ✓.
- **Fresh consumer sweep (all 9 remaining delete targets):** openclaw-isolation-test, dispatch-triage-protocol, research-brief-review-protocol = zero external refs ✓; vault-search = tess-v2 design/review/eval records only (historical, per pack) ✓; tess-health-check = arch docs (edited) + historical project/analysis records ✓; bridge-watcher = arch docs (banner-framed) + AS plist archive (provenance) + runbook (remediated below) ✓; batch-moc-placement = arch/02 Plus-line + spec tree (both remediated below; pack expected B3 to cover the Plus-line — it survived because the script still existed at B3 time, forward-fixed here) ✓; clear-claude-cache = runbook:901 only ✓.
- **Live-system check:** no matching LaunchAgents loaded; hooks/settings reference only keep-set scripts (mirror-sync, session-startup, skill-preflight) ✓. Confirmed parked-only for the bridge-watcher plist ✓.
- **Drift notes honored:** vault-health.sh + lib/cron-lib.sh (AS-019 keep-set, post-baseline) untouched — out of B4 scope per VO-027 drift diff.

**Deletions — 9 tracked (`git rm`):** scripts ×6 (batch-moc-placement.py, bridge-watcher.py, clear-claude-cache.sh, openclaw-isolation-test.sh, tess-health-check.sh, vault-search.sh) + parked plist ×1 (com.crumb.bridge-watcher.plist) + protocols ×2 (dispatch-triage-protocol.md, research-brief-review-protocol.md). bridge-dispatch-protocol.md = already archived (AS-028), no file action. `_system/scripts/` now exactly the keep set: 12 manifest keeps + drive-sync filter + AS-owned vault-health.sh/lib. `_system/docs/protocols/` = 3 keeps (hallucination-detection [R13], inline-attachment, session-end).

**Keeps recorded per pack:** dns-recon.sh (operator 06-10), setup-crumb.sh (disaster-recovery, zero delete-listed refs — VO-023 verification stands), all 8 overlays incl. glean-prompt-engineer re-check, qmd-index + vault-rebuild plists (#F5 A3-extensions). Overlay-index untouched ✓. schemas/briefs still rides B5 ✓.

**Consumer remediation (same batch, D4):** crumb-deployment-runbook — §8.4 Bridge Watcher (install/wrapper/kill-switch/env-vars, ~95 lines) replaced with RETIRED stub + git-history pointer, architecture tree line dropped, :901 clear-claude-cache note → prune-manually + git pointer; arch/02 Plus-line → retired-scripts-deleted phrasing (batch-moc removed from live list); arch/04 tess-health-check line delete-listed→deleted + Plist-locations line → historical (parked plist + staging dirs gone, archive pointer); orientation-map ×2 bridge-dispatch-protocol rows dropped (:95 inventory row, :151 coverage row); spec v2-4 ×2 tree lines removed (batch-moc-placement.py, bridge-dispatch-protocol.md — latter claimed "referenced in CLAUDE.md", false since AS-025). `updated:` bumped on runbook + orientation-map (others bumped earlier today).

**Functional fast-pass:** residual mentions of all 9 deleted items = historical records only (reboot-survivability analysis, ADR open-question text, version-history changelog, banner-framed arch/03 flow, AS plist archive, this batch's own stubs/pointers) ✓; zero live-surface operational claims about deleted files ✓; hooks/settings reference only live scripts ✓; keep-set scripts all present ✓.

**VO-031 ACs:** batch-open checks logged ✓ · order gate verified before protocol deletion ✓ · pack fully applied with same-batch remediation ✓ · green + fast-pass at commit ✓ (vault-check at pre-commit, this commit). tasks.md → done.

**Next: VO-032 (B5 skills/agents)** — batch-open must verify: F7 done (feed-pipeline retired AS-028), E3 re-point done (B1), checkpoint→audit / learning-plan→systems-analyst / diagram-capture→deck-intel merges per pack, brief_schema strips ×4 + schemas/briefs/ deletion same commit. **Three operator addenda queued: (1) audit SKILL.md step-17 retire-vs-keep (vault-audit-status.json), (2) feed-docs trio keep-vs-delete, (3) audit SKILL.md Archived/KB purge steps → delete-review rewrite (D4, pack row).** Then VO-033 (B6).

## 2026-07-03 — Session-end (compound evaluation)

**Session summary:** Triple-batch M4 session — VO-029 (B2 attachments/logs, `98acd2cf`), VO-030 (B3 docs, `fbc1e0c8`, 65 files / −4,984 lines), VO-031 (B4 scripts/protocols/overlays, `b1a16598`, 21 files / −2,732 lines). All batch-open checks logged per batch, all consumer remediations same-commit, all fast-passes green, all pushed. M4 now B0–B4 complete; only B5 (VO-032) + B6 (VO-033) remain before M5 soak. B5 is HIGH stop-and-ask with three operator addenda queued (audit step-17 retire-vs-keep · feed-docs trio keep-vs-delete · in-pack Archived/KB delete-review rewrite). Cumulative session recovery: ~23 MB disk (venv) + 74 tracked doc/script/protocol deletions beyond B2's 3.

**Compound evaluation:**
1. **Dangling deferred-disposition pointer (new pattern candidate, first instance):** storage-policy deferred vault-audit-status.json's disposition to "VO-025 ceremony classification" — but VO-025 never covered it (its scope was the 4 ceremonies; the pointer was written on an assumption, not a check). Surfaced only because B2's batch-open verified the referenced decision actually existed. Rule candidate: *when a pack defers a decision to another artifact, batch-open verifies the decision landed there — a deferral pointer is a claim to verify, not a fact.* Same trust-hierarchy family as the stale-memory-pointer lesson (vault state > pointers). Logged as candidate — watch for a second instance before proposing a solutions doc (medium confidence, Ask-First class).
2. **Cross-batch forward-fix rule: first live use worked.** batch-moc-placement survived B3's arch/02 Plus-line edit (script legitimately still existed at B3 time); B4's batch-open consumer sweep caught it and forward-fixed. Confirms the pack's cross-batch note design ("verify B3 edits landed; else edits move into this batch").
3. **Banner-over-strip for historical architecture docs:** arch/03 flow sections and arch/04's deployment narrative describe decommissioned runtime at section/document scale — line-strips would have gutted them into incoherence. One-line historical banners + targeted fixes of present-tense factual claims ("preserved for repair") satisfied the pack's "strip/annotate" latitude, killed the nav lies, and kept the history readable. Reusable craft rule for B5's skill-file edits where applicable.
4. **Commit-gate caught the AC class it was designed for:** vault-check §31 surfaced two pre-existing broken wikilinks (IDENTITY.md/SOUL.md) in arch/01 on its first-ever staging — exactly B3's zero-dead-wikilinks AC scope. Fixed and amended pre-push. Confirms the staged-files-only check still converges on full coverage as batches progressively touch everything.
5. **Multi-line content anchors over line numbers:** every pack line-number reference had drifted by execution time (earlier edits, 06-12 partial apply); executing edits as assert-then-replace on exact content blocks caught every mismatch loudly (0 silent misses across ~30 scripted edits in 3 batches). Confirming instance of existing careful-edit practice; no new doc.

**Protocol steps:** (2) Amendment Z session report — SKIPPED, dead infra (`~/.tess/state/` decommissioned; step is cut in the approved B6-2 rewrite awaiting VO-033). (3) project-state verified current — next_action reflects B0–B4 done + B5 addenda, updated 2026-07-03 ✓. (4) failure log — not warranted, session executed cleanly end to end. (5) code review sweep — N/A, no repo_path (vault-only). (6) build verification — N/A. (7) qmd update — run at close (result in commit). (8) .processed sweep — SKIPPED, `_openclaw/` no longer exists (step cut in approved B6-2 rewrite). claude-ai-context.md — refreshed this morning, same-day; next refresh after B5/B6 when skill counts change (19→17).

**Model routing:** all main-session (Fable 5); no Sonnet delegation — batch execution is judgment-dense (disposition calls, staleness classification, remediation phrasing) even when mechanically shaped; no skill invocations (direct task execution under IMPLEMENT). No token-heavy anomalies.

**State for next session:** VO-032 (B5, HIGH stop-and-ask) is the only unblocked VO task; open with the three queued operator addenda before executing the pack. AS-031 soak day 4 check due 2026-07-04.

## 2026-07-04 — VO-032 complete: B5 skills/agents batch EXECUTED

**Session start:** soak-opener session (AS-031 day 4 ✅ GREEN, logged in AS run-log) → operator: "now VO-032". Context inventory: project-state + run-log tail + tasks.md VO-032 row + changeset-b5-skills-agents.md (full — governing pack) + targeted reads of all 6 merge-pair SKILL.md files + every remediation target; no overlays; no skill invocations (direct task execution under IMPLEMENT). HIGH risk per tasks.md — stop-and-ask satisfied via AskUserQuestion gate (three decisions, below) before any execution.

### Batch-open checks (logged before execution)

**Preconditions:** B4 complete (VO-031) ✓ · AS M6 sign-off (verified at VO-016) ✓ · AS-028 concurrence on #F7 resolved by events (below) ✓.

**Staleness re-validation — favorable drift, all verified fresh:**
- **feed-pipeline retired outright at AS-028** → #F7 row 1 moot; skill absent from disk; end count = **19→16, not the pack's 20→17** (pack's 17 counted a kept feed-pipeline). Its `feed-pipeline-calibration.jsonl` decision (pack: "rides the calibration-step decision") resolves to delete; file found at `_system/docs/` (tracked), deleted this batch.
- **vault-query already rewritten** (AS-028 era): Tess-dispatch/brief surface gone, no brief_schema, 108 clean lines → #F7 row 2 done by events; only the trigger-description rewrite applied here.
- **critic brief_schema lines already gone** (pack listed critic:14,67); only researcher:13 still carried one. inbox-processor description no longer mentions diagram-capture (row moot).
- **E3 re-point verified done at B1**: deliberation/SKILL.md → `_system/data/deliberations/` ✓.
- **Consumer-doc paths drifted:** orientation-map → `_system/docs/llm-orientation/`, skills-reference → `_system/docs/operator/reference/`; both still carried dead feed-pipeline rows AS-028 never remediated → folded into this batch (B5's named consumers).
- **Adjacent strips found:** attention-manager carried 2 stray `brief_schema: null` lines (not in pack — added to strip set).

**Operator decisions (AskUserQuestion, 2026-07-04):** (1) **audit step-17 KEEP** — vault-audit-status.json writer stays; dashboard paused-not-deleted, keeps resume path warm, re-check when MC dashboard's fate is decided. Dashboard-contract JSON fields (`tessHarnessIssues`, `archivedKbCount`) left in the schema for the same reason — they'll report 0. (2) **feed-docs trio DELETE ×3** (feed-pipeline-philosophy, run-feed-pipeline, triage-feed-content) — delete with git provenance, D4 ethos, B3 precedent. (3) **Full-scope go-ahead** — pack + adjacent feed-pipeline-row cleanup + calibration jsonl, single batch commit.

### Execution

**Merges (fold-then-delete, same commit):**
- **checkpoint → audit:** 5-step checkpoint procedure folded as audit Procedure §4 "State Checkpoint" (+ When-to-Use triggers, durability convergence dimension, checklist line); description per pack #3. Also applied in the same audit edit: **in-pack D4 rewrite** — Archived/KB purge steps (weekly 10, monthly 8, action lists, context contract, checklist) → stale-KB **delete review** with git provenance matching the B3 vault-gardening rewrite; **adjacent dead-infra fixes** — step 15 "Tess harness audit" removed entirely (all 4 sub-checks read `/Users/danny/.hermes/*` + tess-v2 tracking, decommissioned/DONE — this was the known AS-028 "audit §15" body-text residual), step 14 service-count check re-pointed `_openclaw/staging/` → `~/Library/LaunchAgents` com.crumb.* plists. Note: checkpoint was `model_tier: execution`, audit is `reasoning` — absorbed procedure inherits reasoning; acceptable (checkpoint's Sonnet delegation was Phase-1 rollout; cost delta negligible for a small procedure).
- **diagram-capture → deck-intel:** Step 4 composable call internalized (extraction modes A/B with hidden-slide check + PDF PyMuPDF + filter gate + classification table + sensitivity check); new "Standalone Visual Capture Mode" section carries the Mermaid/table/description recreation capability, standalone output file format, durability advisory, and composable-from-inbox-processor contract; description per pack #5; output constraints + convergence dim added.
- **learning-plan → systems-analyst:** "Learning Plan Variant" section (V1–V5): skill-type classification table, ≤5 assessment questions, phase design (spaced repetition, feedback loops, plateau markers, cognitive scaffolding, motivation design), phase-mapped resources, plan document format with `skill_origin: systems-analyst`; description per pack #14. **Dropped in the fold: §7 "Build Tess Integration"** (OpenClaw cron, dead infra — the known "learning-plan §7" residual dies with the merge, not migrated).

**Description rewrites: 16/16 kept skills** per pack drafts (pack #7 feed-pipeline moot). Gotchas ×2 added: researcher (wikilink fabrication, failure-log 2026-04-21) + peer-review (Grok calibration watch, VO run-log 2026-06-10). brief_schema strips: researcher:13 + attention-manager ×2 (adjacent). attention-manager:140 "Skip Archived/Projects/" dropped (D4).

**Deletions — 11 tracked (`git rm`):** `.claude/skills/checkpoint/` + `diagram-capture/` + `learning-plan/` (3 SKILL.md) · `_system/schemas/briefs/` ×4 (feed-pipeline/research/review/vault-query briefs — same commit as the strips per A2 #3) · feed-docs trio ×3 (operator decision) · `_system/docs/feed-pipeline-calibration.jsonl`. Skills on disk = **16**, agents = 4 (all kept per pack).

**Consumer remediation (same batch, D4):** skill-preflight.sh:44 fast-path (checkpoint/diagram-capture out) · skill-preflight-map.yaml (learning-plan + feed-pipeline keys dropped) · AGENTS.md (checkpoint row folded into audit row) · orientation-map (4 skill rows dropped, merge-target rows updated, totals 20→16 recounted, coverage rows fixed, dead "Tess personality | SOUL/IDENTITY" row dropped [adjacent nav-lie, same class as B3's]) · skills-reference (4 index rows dropped, 3 merge-target rows updated, tier counts 5→4/15→12, phase-alignment + overlay + composable + dispatch-capability + required-context tables fixed, tree 20→16, dispatch intro reworded historical) · vault-check.sh REGISTERED_SKILLS 20→16 (line 2014 run-log skill_pattern left — matches historical log entries legitimately) · arch/02 skill-table rows ×4 + signals/ wording · spec v2-4 (feed-pipeline + checkpoint tree lines removed; §3.1.6 file pointer → audit §State Checkpoint with absorption note) · kb-to-topic.yaml comment · the-vault-as-memory entry-point row → historical · add-knowledge-to-vault "Method 3" → RETIRED block (killed dead [[run-feed-pipeline]] wikilink) · behavioral-vs-automated-triggers (learning-plan→systems-analyst; feed-pipeline row Open→Closed-by-retirement) · behavior-vs-meaning (learning-plan variant phrasing; stale Tess-integration clause dropped) · overlays-reference (learning-plan row dropped, variant noted on systems-analyst) · crumb-operating-note (pending-merge prose → done; also corrected stale "peer-review (absorbing critic, writing-coach)" — those merges were declined 2026-06-10) · wyner-fluent-forever-companion:36 re-pointed. `updated:` bumped on all substantively edited docs (no summaries exist for any — freshness gate clear). **CLAUDE.md:106** Phase-1 list still names checkpoint — B6-owned per pack, transient staleness accepted.

**Functional fast-pass:** zero wikilinks to any deleted basename ✓ · zero schemas/briefs live refs (remaining: VO provenance docs + opportunity-scout historical evidence line + retired-skill archive copy) ✓ · residual merged-skill mentions = historical records only (run-logs, AS/MC project docs, signal-note provenance frontmatter, ADR as-of-writing prose, banner-framed arch sections) ✓ · skill-routing spot-checks against live registry: "checkpoint"→audit ✓, "capture this diagram"→deck-intel ✓, "training plan"→systems-analyst ✓, "process feed items"→no match (intended) ✓, declined-merge skills critic/writing-coach still route standalone ✓.

**Adjacent findings (routed, not executed):** (1) `_system/archive/` holds AS-era parked copies (skills-retired/feed-pipeline, launchagents-retired ×10, protocols-retired) that B1's Archived/ deletion didn't cover — delete-over-park candidate but AS-owned artifacts → **operator call, flagged at session close**. (2) preflight-map `excalidraw:`/`lucidchart:` keys have no matching skills (never fire — harmless config residue) → audit/M5. (3) spec v2-4 tree still lists excalidraw/lucidchart/meme-creator SKILL.md lines (pre-existing, long-retired, not B5's deletions) → audit/M5, same nav-lie class. (4) arch/02 §9 Bridge + `_openclaw/` tables remain as-of-writing under B3 banners — unchanged, VO-009-adjacent.

**VO-032 ACs:** batch-open checks logged ✓ · pruned counts reported (11 tracked deletions enumerated; 19→16 skills) ✓ · every kept skill description states trigger conditions (16/16 applied) ✓ · green + skill-routing fast-pass at commit ✓ (vault-check at pre-commit, this commit). tasks.md → done.

**Next: VO-033 (B6 ceremony)** — apply frozen VO-026 pack; verify AS-025 sign-off in AS run-log at batch open; CLAUDE.md edits individually stop-and-ask (incl. the :106 checkpoint cleanup). Then M5 soak (VO-034–036). claude-ai-context refresh due now that skill counts changed (19→16) — fold into next session or B6.

## 2026-07-04 — Adjacent execution (same session as VO-032): `_system/archive/` deleted

B5's adjacent finding #1 resolved same-session by operator decision ("we can clear that stuff out"). `_system/archive/` (47 tracked files, 208K: `skills-retired/feed-pipeline/`, `launchagents-retired/` incl. tess-user/openclaw-user subdirs, `protocols-retired/`) deleted via `git rm` — all files verified tracked pre-deletion (git provenance: `git show 8f1cdbfd:_system/archive/<path>`). Rationale: rollback window formally closed 2026-06-14 (AS-021/022); delete-over-park ethos (B1 precedent); parked plists were redacted copies loaded nowhere. This supersedes AS's "disable+archive, never delete" standing decision for these artifacts — operator-approved, cross-noted in AS run-log. Live pointers re-pointed to git history in the same commit: arch/04:149, deployment-runbook:452, claude-ai-context ×2 (its full refresh remains queued post-B6). Historical references in AS design docs / VO manifest left per convention.

## 2026-07-04 — Session-end (compound evaluation)

**Session summary:** Opener = AS-031 soak day 4 → ✅ GREEN (logged in AS run-log; 71 MB tarball size-drop explained as first post-VO-028/029 backup, annotated in tracker). Then VO-032 B5 executed end-to-end (commit `8f1cdbfd`, 56 files / −1,518 lines: 3 merges, 19→16 skills, 16/16 descriptions, 2 gotchas, 11 deletions, full consumer sweep), followed by same-session resolution of the `_system/archive/` adjacent finding (commit `177333bf`, 47 parked files deleted, delete-over-park, live pointers → git history). Both pushed. M4 now B0–B5 complete; VO-033 (B6) is the sole remaining batch before M5 soak.

**Compound evaluation:**
1. **Batch-open staleness check earned its keep again — the pack's headline number was wrong by execution time.** "20→17 skills" was drafted 06-10; AS-028 retired feed-pipeline outright in between, making the true end state 19→16, and #F7's two conditional rows were already resolved by events (one moot, one done). A three-week-old approved pack executed with ~a third of its rows already satisfied or mooted — the A1/A2 re-validation step is what kept the batch from re-deleting, double-remediating, or reporting a false count. Confirming instance of the M4 batch-model design; no new doc.
2. **Skill-merge craft rule (new, reusable):** fold the absorbed skill as a *named variant/mode section* in the target (audit §State Checkpoint, deck-intel §Standalone Visual Capture Mode, systems-analyst §Learning Plan Variant) and union the triggers in the description — rather than interleaving procedures. Keeps the target's core procedure readable, gives the absorbed capability an addressable name for routing/reference re-points, and makes future un-merge or audit trivial. Extends B3's banner-over-strip family (structure-preserving edits). Watch for reuse at any future merge before promoting to skill-authoring-conventions.
3. **Merges are where dead infra goes to die quietly — check the folded body, not just the roster.** All three merge sources carried dead-infra residuals (learning-plan §7 Tess integration, audit §15 .hermes harness audit, audit §14 _openclaw staging path) that roster-level batch rows would never have caught; the fold forced a body-text read that killed them. Same class as AS-028's "stale skill body-text residuals" open item — which this batch closes for audit §15/learning-plan §7 (researcher's was the gotcha, also landed).
4. **Flag-then-resolve-same-session beat flag-and-queue for the archive call.** The B5 close-out flagged `_system/archive/` as an operator call; operator chose to decide immediately ("so I don't forget") and the disposition executed in minutes because full context (tracked-status verification, reference sweep) was still loaded. For small single-decision adjacents, offering immediate resolution alongside the flag is cheaper than queueing to a future session that must rebuild context. Behavioral note, not a doc.
5. **AskUserQuestion as the stop-and-ask gate for batch-open addenda worked cleanly:** three queued decisions + scope go-ahead collected in one structured prompt with recommendations, zero re-prompting mid-batch. Confirming instance of the existing question-gate pattern.

**Protocol steps:** (2) Amendment Z — SKIPPED, dead infra (cut in approved B6-2 rewrite). (3) project-state verified current (updated 2026-07-04, next_action = VO-033) ✓; tasks.md VO-032 done ✓. (4) failure-log — not warranted, session executed cleanly end to end. (5) code review sweep — N/A, no repo_path (vault-only; changes are markdown/YAML/one shell-script list edit, vault-check green at both commits). (6) build verification — N/A. (7) qmd update — run at close. (8) `.processed` sweep — SKIPPED, dead infra. Memories updated: VO + AS project memories, MEMORY.md index (B5 done, soak day 4, archive resolved).

**Model routing:** all main-session Fable 5; no Sonnet delegation — merges, D4 rewrites, and remediation phrasing are judgment-dense throughout; no skill invocations (direct task execution under IMPLEMENT). Token-heavy ops: full reads of 6 merge-pair SKILL.md files + 2 reference docs, vault-wide residual greps — appropriate for the precision required.

**State for next session:** VO-033 (B6 ceremony) is the only unblocked VO task — apply frozen VO-026 pack; batch-open verifies AS-025 sign-off; every CLAUDE.md edit individually stop-and-ask (incl. :106 checkpoint cleanup); claude-ai-context refresh due (16-skill count) — fold in. AS-031 soak day 5 check due 2026-07-05.

## 2026-07-04 — VO-033 complete: B6 ceremony batch EXECUTED

**Session start:** operator: "let's work on VO-033 (B6 ceremony)". Context inventory: project-state + run-log tail + tasks.md VO-033 row + changeset-b6-ceremony.md (full — governing frozen pack) + full reads of both protocol docs + targeted reads of inbox-processor/startup SKILL.md + session-startup.sh + CLAUDE.md touch points; no overlays; no skill invocations (direct task execution under IMPLEMENT). Stop-and-ask satisfied via AskUserQuestion gate (4 decisions, below) before any execution.

### Batch-open checks (logged before execution)

**Preconditions:** B5 complete (VO-032) ✓ · **AS-025 sign-off verified in AS run-log** (line 280: DONE, high-risk diff-approved, applied 2026-06-12; M6 sign-off same date) ✓ · pack frozen+approved 2026-06-12 (B6-1..B6-4 as drafted, B6-5 at FULL six-counter scope) ✓.

**Staleness re-validation (pack drafted 06-12; B3/B4/B5 landed since):**
- **B6-1/B6-2:** both protocol docs matched pack before-state exactly (checkpoint 11 steps with stale Frontend/Backend Designer names; session-end 10 steps with Amendment Z, 6a/6b drift, dead `.processed` sweep). Zero drift.
- **B6-3:** inbox-processor steps 7/8 content identical to pack basis; line refs drifted 531→529 (B5 description rewrite above) — content-anchored edit unaffected.
- **B6-4:** CLAUDE.md:213 exact before-text present. Adjacent queued item CLAUDE.md:106 (Phase-1 list) found carrying THREE dead names: checkpoint (B5 merge) + obsidian-cli + meme-creator (long-retired, pre-existing).
- **B6-5:** all six counter blocks live, emitting zeros every session. **Drift finding — pack's "no consumers" claim broke:** startup SKILL.md:20–28 (skill postdates pack consumer check) carried three bullets keyed to compound_insights_pending/stale + brainstorm_pending_review; sources archived AS-026 → dead branches → same-commit consumer remediation proposed.

**Operator decisions (AskUserQuestion, 2026-07-04):** (1) **apply B6-1/2/3/5 as frozen** (single batch); (2) **B6-4 CLAUDE.md:213 apply** (individually approved); (3) **CLAUDE.md:106 full-line correction → "sync, startup"** (individually approved — fixes queued checkpoint staleness + both pre-existing dead names); (4) **startup SKILL.md strip all three dead-key bullets** (same-commit consumer remediation, D4 pattern).

### Execution

- **B6-1** context-checkpoint-protocol.md: §Procedure 11→6 per pack full text (verify-outputs+summaries merged; compound+goal-progress unified as step 2 with structural-guarantee language retained; context check+act with mid-session single-step note; log step carries full run-log/project-state templates + progress-log line; commit; load-next-context with neutralized `*-design-summary.md` examples). Stale-text fixes: Proactive Triggers subagent names → "dispatch agents, research pipelines". Checklist diff (11 rows) in pack proves no semantics lost. `updated:` → 2026-07-04.
- **B6-2** session-end-protocol.md: 10→7 per pack (step 2 Amendment Z session report CUT — hard zombie, `session_reports.db` zero live readers, run-log is the surviving record; 6b AKM residue paragraph deleted; step 8 `.processed` sweep cut — target dir gone at AS-026; 9+10 merged as "Commit & Push" with skip-push-if-no-commit preserved; QMD step renumbered clean with consumer named inline). §Non-Project Format + §References unchanged. `updated:` → 2026-07-04.
- **B6-3** inbox-processor SKILL.md: steps 7+8 folded → "7. Verify, Report & Compound Check" per pack diff; Re-routing section untouched; no renumbering needed.
- **B6-4** CLAUDE.md ×2 (each individually operator-approved): :213 "(4) conditional commit, (5) git push" → "(4) conditional commit & push"; :106 Phase-1 list → "sync, startup".
- **B6-5** session-startup.sh: all six zombie counter blocks removed (compound-insights scan `_openclaw/feeds/research` · dispatch queue+orphans `_tess/dispatch` · research_pending_review `_openclaw/research/output` · brainstorm `_openclaw/inbox/brainstorm-*` · feed_intel FIF pipeline.db read · z4 lock-deny `~/.tess/state/`) + COMPOUND_LINE builder + all six formatted-summary conditionals. `pipeline.db` itself untouched (stays frozen read-only for dashboard). **Verified:** `bash -n` clean + full run — startup context emits no dead keys, Startup Summary block intact.
- **Consumer remediation (drift finding):** startup SKILL.md bullets for the three removed keys stripped (steps 4 now ends at stale_summaries recommendation).
- **Folded in (queued):** claude-ai-context.md refresh — headline updated to B0–B6 complete + ceremony numbers, skill count 19→16 (verified 2026-07-04), VO section → M4 complete/M5 next, AS soak day 4/7, "stale skill body-text residuals" open item → RESOLVED at B5. `updated:` → 2026-07-04.

**A10 after-state (per pack):** phase gates 11→6 · mid-session checkpoint 2→1 · session-end 10→7 · intake 8→7 · **total 31→21, zombies 0** · plus 6 zombie startup counters → 0.

**Functional fast-pass:** zero live references to removed counter keys (md/sh sweep; remaining hits = historical run-logs/failure-log only) ✓ · zero old-step-number references to either protocol ✓ · Amendment Z mentions surviving = historical narrative only (live-soak-beats-benchmark history section, banner-framed arch/03, claude-ai-context decommission narrative) ✓ · startup script executes clean with intact display contract ✓ · CLAUDE.md step list consistent with rewritten protocol ✓. Session-end for THIS session executes against the new 7-step protocol = soak dry-run #5 first pass; dry-run #1 (phase transition) lands at M4→M5 gate.

**VO-033 ACs:** AS-025 sign-off verified in AS run-log ✓ · batch-open checks logged ✓ · only the frozen VO-026 diff applied, plus operator-approved adjacents (CLAUDE.md:106 full-line, startup-skill strip — both gated individually) ✓ · each CLAUDE.md edit operator-approved individually ✓ · green + ceremony dry-run fast-pass at commit ✓ (vault-check at pre-commit, this commit). tasks.md → done.

**Next: M5 soak** — VO-034 (instantiate soak: end = max(B6+14 calendar days, B6+8 working sessions) from B6 commit date 2026-07-04; log window, pass criteria, failure protocol, "working session" definition) → VO-035/036.

## 2026-07-04 — Session-end (compound evaluation) — first live pass of the B6 session-end protocol

**Session summary:** Single-purpose session: VO-033 (B6 ceremony) executed end-to-end (commit `89b748d3`, 10 files, +119/−341). Batch-open verified AS-025 sign-off + re-validated all five frozen targets (zero drift on B6-1..B6-4 content; one drift finding on B6-5's consumer claim — startup SKILL.md dead-key bullets, remediated same commit after operator approval). Four-decision AskUserQuestion gate satisfied per-edit stop-and-ask including both CLAUDE.md edits individually. M4 is now COMPLETE (B0–B6); M5 soak (VO-034) is the sole next step. **This session-end runs against the new 7-step protocol — soak dry-run #5 first pass.**

**Compound evaluation:**
1. **Second instance of the consumer-claim-goes-stale pattern — this time the consumer was born after the check.** B5's lesson was "a deferral pointer is a claim to verify"; B6 adds the complement: *a pack's negative claim ("no consumers read X") expires the moment a new primitive can be created — batch-open must re-run the consumer grep, not trust the pack's.* The startup skill postdates the VO-026 consumer check, so the pack was right when written and wrong at apply. Combined with B5's instance this is now two occurrences of "batch-open re-verification catches what the frozen pack can't know" — the re-validation step is load-bearing, not ceremony. Candidate solutions doc if a third instance appears (medium confidence, Ask-First class — flagged, not written).
2. **Question-gate scope bundling worked again:** frozen-pack apply + two individually-gated CLAUDE.md edits + one drift remediation = one AskUserQuestion, four decisions, zero mid-batch re-prompting. Confirming instance (B5 precedent).
3. **Ceremony reduction self-demonstrates:** the session-end sequence below is visibly shorter — two SKIPPED-dead-infra steps that every session since 06-10 logged as skip-with-reason are simply gone. The A10 metric (31→21) shows up as less protocol text to *not* execute.

**Protocol steps (new numbering):** (1) log — this entry. (2) project-state refresh — verified current: next_action = VO-034 soak instantiation, updated 2026-07-04, tasks.md VO-033 done ✓. (3) failure-log — not warranted, clean end-to-end execution. (4) code review sweep — N/A, no repo_path (vault-only; script edit verified by bash -n + live run). (5) build verification — N/A. (6) qmd update — run at close (result in commit). (7) commit & push — log-only delta, lightweight commit, push.

**Model routing:** all main-session Fable 5; no Sonnet delegation (batch execution judgment-dense: drift adjudication, protocol rewrite fidelity, remediation phrasing); no skill invocations (direct task execution under IMPLEMENT). No token-heavy anomalies — targeted reads throughout; largest single read was the startup script (426 lines, required for surgical block removal).

**State for next session:** VO-034 — instantiate M5 soak (window = max(2026-07-18, B6+8 working sessions); log pass criteria + failure protocol + working-session definition; start date = B6 commit date 2026-07-04). Dry-run #5 first pass logged this session; #1 (phase transition) due at M4→M5 gate. AS-031 soak day 5 check due 2026-07-05. Known accepted residue: vault-check §31 warning on B5's historical run-log line mentioning the killed [[run-feed-pipeline]] wikilink (immutable log text).

## 2026-07-04 — VO-034 complete: M5 soak INSTANTIATED

**Context inventory:** project-state + tasks.md VO-034 row + action-plan.md M5 section (soak window, pass criteria, failure protocol) + design D6 (Tier-1 workflow list). Low risk — direct instantiation, no operator gate needed (all parameters operator-approved at TASK; this task binds them to dates).

### Soak window (A10, instantiated)

- **Start date:** 2026-07-04 (= B6 commit date, `89b748d3`). Today counts as working session 1.
- **End condition:** soak ends at **max(2026-07-18, date of the 8th working session)** — i.e., no earlier than 2026-07-18, and not before 8 working sessions have occurred.
- **Working session (definition, per action plan):** a calendar day with at least one logged vault work session — a session-log entry or any project run-log entry dated that day. Multiple sessions on one day = one working session.

### Pass criteria (all three required)

1. **Zero urgent git restores** of deleted/pruned artifacts.
2. **No repeated workaround:** the same removed primitive *needed* twice = FAIL, where "needed" means restored, manually recreated, or worked around in a documented way that compensates for its removal.
3. **All six Tier-1 representative workflows (design D6) pass at least once** during the window (tracker below; execution + recording = VO-035).

### Failure protocol (A3, verbatim from action plan)

- **Single primitive restore → fix-forward:** restore from git history, flip the manifest row to keep, run-log entry. Restarts the soak clock **for the affected surface only**.
- **Repeated-workaround failure or Tier-1 blocker → revert** the offending batch commit(s) and re-enter M3 with the corrected changeset. Also restarts the clock for the affected surface.
- **Second failure of any kind → restarts the FULL soak window.**

### Tier-1 validation tracker (VO-035 records outcomes here)

| # | Workflow (D6) | Status | Evidence |
|---|---|---|---|
| 1 | Full phase transition with checkpoint protocol (rewritten 6-step) | pending | natural occurrence expected: any project phase gate during window (VO's own M5→close at VO-036 qualifies) |
| 2 | inbox-processor run (7-step post-fold) | pending | next `_inbox/` batch |
| 3 | peer-review or deliberation dispatch | pending | next review-worthy artifact (also closes Grok watch 3/3) |
| 4 | KB query + signal scan | pending | next #kb/ lookup or tagged-note creation |
| 5 | Session-end sequence (rewritten 7-step) | **pass ×4** | 2026-07-04 B6 session close (first live pass, clean) + 2026-07-04 VO-034 session close (second pass, clean; one transient push timeout, single retry succeeded per exception chain) + 2026-07-05 mission-layer session close (third pass, clean; non-project route, incl. first-ever archival in step scope) + 2026-07-05 FIF-archival segment close (fourth pass, clean; second archival) |
| 6 | Skill-routing spot-checks on rewritten descriptions | **pass ×1** | 2026-07-04 VO-032 fast-pass (5 spot-checks incl. merge-target routing); re-check during soak for a within-window pass |

Note on #6: the B5 fast-pass predates the soak start by hours; counting it is defensible but a second within-window spot-check set will be run anyway to make the pass unambiguous. #1 will NOT be simulated — it must occur naturally on a real phase gate (soak measures reality, not rehearsal).

**Working-session tracker:** WS1 = 2026-07-04 ✓ (this entry) · WS2 = 2026-07-05 ✓ (audit + mission-layer sessions; counted once). Count advances via the session-end log check; earliest possible end = 2026-07-18.

**VO-034 ACs:** window + end-condition + pass criteria + failure protocol (fix-forward vs revert per action plan) in run-log ✓ · "working session" definition logged ✓ · start date = B6 commit date ✓. tasks.md → done.

**Next: VO-035** — execute + record the six Tier-1 workflows as they occur (opportunistic, not simulated where reality provides them); VO-036 close-out at soak end with pass criteria green + operator sign-off.

## 2026-07-04 — Session-end (compound evaluation) — VO-034 segment

**Session summary:** Continuation of the B6 session: VO-034 executed (commit `42239768`) — M5 soak instantiated and live (start 2026-07-04, end = max(2026-07-18, 8th WS), pass criteria + A3 failure protocol logged verbatim from action plan, Tier-1 tracker seeded). Push required one retry after a transient 2-minute hang (commit was already safe locally; no state damage; exception chain step 1 resolved it).

**Compound evaluation:** No compoundable insights — mechanical instantiation of operator-approved parameters; the push hang was transient and the existing retry protocol handled it.

**Protocol steps (7-step):** (1) log — this entry. (2) project-state refresh — current (next_action = VO-035 opportunistic recording) ✓. (3) failure-log — not warranted. (4) code review sweep — N/A (no repo_path). (5) build verification — N/A. (6) qmd update — run at close. (7) commit & push — log-only delta, lightweight commit.

**Soak bookkeeping:** WS count unchanged (WS1 = 2026-07-04; same-day sessions count once). Tracker #5 advanced to pass ×2 (this close is the second clean run of the rewritten sequence).

**Model routing:** all main-session Fable 5; no delegation; no skill invocations. No token-heavy operations.

**State for next session:** VO-035 — record Tier-1 workflow outcomes as real work exercises them (#1–#4 pending natural occurrence; #6 re-check due within window); advance WS count at each session end. AS-031 soak day 5 check due 2026-07-05. Earliest possible VO soak end: 2026-07-18.

## 2026-07-05 — VO-037 added (operator): CLAUDE.md minimalism pass, post-soak backlog

**Context:** Non-project mission-layer session. Operator raised the "minimal CLAUDE.md" guidance circulating externally; assessment (logged in session-log) concluded the right metric for this vault is attention cost + sync liability, not line count — CLAUDE.md's audit history shows duplication-drift (sonnet version pin, excalidraw/lucidchart) as the real failure class, and rare-fire sections (Project Archival — fired for the first time ever today; Model Routing rollout detail) pay per-session rent for quarterly use.

**Task:** VO-037 appended to tasks.md — section-by-section fire-rate review with keep-inline test; pointerize rare-fire sections; single-source duplicated facts; per-section pointer-mechanism choice (textual load-on-demand saves context; `@import` inlines at session start and saves nothing — reserve for always-needed content). Estimate ~220 → ~140–160 lines, zero behavior loss.

**Sequencing:** depends_on VO-036 — deliberately deferred past M5 soak close (do not add a second variable to the running B6 validation). CLAUDE.md edits remain individually Ask-First at apply time.

## 2026-07-05 — Operator keep-set delta (mid-soak): attention-manager retired to Cowork

**Context:** Mission-layer session (non-project origin), same day as VO-037 addition. Operator declared attention-manager "a good idea that had poor execution — as with opportunity-scout, this should move to Cowork." Skill deleted (16 → 15), `goal-tracker.yaml` retired with it (attention-manager was its only consumer), vault-check §27 (daily-attention/attention-review schema) removed. Durable extract: `_system/docs/cowork-attention-handoff.md`. §26 attention-item deliberately KEPT — file-conventions attributes that intake to mission-control's dashboard aggregator, not attention-manager.

**Soak impact assessment:** executed mid-window by operator decision. Attention-manager appears in none of the six Tier-1 validation workflows and had zero invocations in months — no confound to soak pass criteria. If any session in the window needs the skill (would count as urgent restore), git history has it; assessed as near-zero risk.

**Keep-set reconciliation (input to VO-036):** attention-manager was a B5 keep (evidence: soak-validated skill) and goal-tracker was Tier-1 data (refs=81) in the keep-set manifest — both now operator-delta'd out post-freeze. `crumb-operating-note.md` annotated inline at both mentions. Third instance of "classifications stale fast" class (AS deltas at VO-026 drafting; B6-5 startup drift; now operator ground-truth change mid-soak) — but distinct cause (operator decision vs parallel teardown), so not counted toward that pattern's promotion.

**Remediation sweep (same commit):** skills-reference (15 skills, 6 table edits), overlays-reference ×2, orientation-map row, skill-preflight-map block, file-conventions (daily-attention/attention-review rows → RETIRED), crumb-operating-note ×2, claude-ai-context (count, AS narrative note, ai-art inventory line + 3 stale "primary revenue bet" claims corrected to Gate-4 hobby), infrastructure-reference daily-attention paragraph, first-crumb-session example swap, arch/02 row, arch/05 vault-check table, vault-check.sh §27 block removed (bash -n clean), behavior-vs-meaning-in-routine-design → `linkage: discovery-only` (lost its last skill linkage; same treatment as haiku-soul 07-05 AM). Grep-verified zero live references post-sweep.
