---
project: agent-to-agent-communication
type: run-log
created: 2026-03-01
updated: 2026-03-20
period: 2026-03-01 to 2026-03-14
---

# agent-to-agent-communication — Run Log

## 2026-03-13 — Session end: recovery + feedback processing

**Session type:** Recovery from power outage mid-session.

**Work completed:**
1. Recovered interrupted S1 dispatch state — logged to delivery log, feedback ledger, gate file, research status, run-log
2. Recorded Danny feedback on both dispatches:
   - S1 (Perplexity APIs): useful — "good information for low-rigor research, accurate to practitioner knowledge"
   - DNS research: useful — "good doc, low source diversity expected for newly-released product"
3. Created first 2 dispatch learning log entries (cold-start period ending)
4. Updated claude-ai-context.md with current A2A project state

**Compound evaluation:**
- Both dispatches received `useful` feedback — light rigor calibration is appropriate for these topics
- 403 errors on vendor blogs handled well via official docs + corroborating sources (pattern: emerging topics often have limited direct-fetch coverage)
- Learning log now populated — future brief formulation can consult prior outcomes
- Gate criterion #4 (feedback signal) at 100% (2/2 within 24h)

**Model routing:** Session on Opus. No delegation — recovery + logging work only.

## 2026-03-13 — Session recovery: S1 dispatch logging (power outage)

**Action:** Recovered from mid-session power outage. S1 dispatch (Perplexity APIs) had completed all 6 pipeline stages and written deliverables, but session was cut before logging to delivery log, feedback ledger, gate file, and run-log.

**Recovery completed:**
- Research status file updated (was stuck at "Stage 0/6")
- Delivery log entry appended
- Feedback ledger entry created (awaiting_feedback)
- Gate Day 1 (cont.) log entry with full S1 dispatch data
- This run-log entry

**S1 dispatch summary:**
- Dispatch ID: `019ce956`, 7 sources (4A, 3B), 16 ledger entries, confidence 0.75
- Deliverable: `Sources/research/perplexity-developer-apis-agentic-workflows.md`
- Quality gate passed first attempt. 0 escalations, 0 re-dispatches.
- Notable: 2 blog posts returned 403 — grounded through official docs instead.

## 2026-03-13 — A2A-013 gate observation started

**Action:** Kicked off 3-day observation gate for Workflow 2 (research pipeline).

**Context:** A2A-012.2 e2e integration completed earlier today — first research dispatch through full 6-stage pipeline (DNS AI threat countermeasures, 880s, all validation passed). That dispatch counts as Day 1 data.

**Gate tracking:** `_openclaw/state/gates/a2a-013-gate-2026-03-13.md`
**Window:** Mar 13–16.

**6 criteria defined:**
1. Research quality — deliverables pass quality gate on first/second attempt
2. Escalation accuracy — no false escalations
3. Re-dispatch rate — <50% re-dispatch
4. Feedback signal — Danny provides feedback on ≥50% within 24h
5. SOUL.md drift — deterministic operations consistent
6. Capability resolution — correct skill resolved, cold-start guard fires appropriately

**Data generation strategy:** Research dispatches are demand-driven (unlike compound insight cron). Seeding 2-3 research requests tied to active project needs:
- S1: Perplexity new developer APIs (Embeddings, Agent, Sandbox) — workflow possibilities for agentic orchestration — Day 2
- S2: Agent-to-agent communication and autonomous work — what's real today vs. future — Day 3
- S3: Agent orchestration dashboard UX patterns (MC-067 / A2A-015 input) — spare

**Day 1 observations:**
- A2A-012.2 dispatch logged as first data point. Quality gate passed first attempt. 0 escalations, 0 re-dispatches. SOUL.md drift: none. Capability resolution: correct.
- Feedback on DNS research deliverable still awaiting Danny review (24h timeout ~Mar 14 17:13Z).
- Learning log empty (blocked on feedback — mechanical coupling rule).

## 2026-03-13 — A2A-012.2 e2e integration COMPLETE

**Action:** First research dispatch through full pipeline — end-to-end integration test passed.

**Pipeline execution:**
- Dispatch ID: `77c8cbb2`, Correlation ID: `019ce903-76f1-7612-ad57-5d2f041c8605`
- Question: "What DNS-layer security capabilities are emerging to counter AI-generated phishing and AI-enhanced DGAs in 2025-2026?"
- Rigor: light, Deliverable format: knowledge-note (brief)

**Pipeline stages completed (all 6):**
1. **Scoping:** Vault search found 32 existing DNS security notes, identified AI-specific gap. 6 skip_queries for existing coverage.
2. **Planning:** 2 sub-questions (attack techniques sq-1, defense capabilities sq-2), 4 hypotheses. Light convergence: 0.5 threshold.
3. **Research Loop (1 iteration):** 6 sources (1 Tier A abstract-only, 3 Tier B, 2 Tier C), 11 ledger entries. Both sub-questions covered in single iteration (sq-1: 0.79, sq-2: 0.88).
4. **Synthesis:** Overall confidence 0.74. H1/sq-1 confirmed (AI-enhanced DGAs real). H2/sq-1 disconfirmed (not theoretical — 45% of financial attacks). H1/sq-2 confirmed (vendors deploying DL). H2/sq-2 confirmed (incremental, not paradigm shift). Zero contradictions.
5. **Citation Verification:** 11 entries checked, 7 passed, 4 flagged (near-miss), 0 failed. 2 entries downgraded (FL-002, FL-005 — statistics not traceable in captured content).
6. **Writing:** Deliverable produced with 22 citations across all 11 entries from 6 sources. All 4 validation checks passed on first attempt.

**Pipeline metrics:**
- Wall time: 880 seconds (~15 minutes)
- Sources: 6 total (1A, 3B, 2C) — 5 FullText, 1 AbstractOnly
- Entries: 11 active, 0 deprecated
- Escalations: 0
- Re-dispatches: 0

**Deliverables written:**
- `Sources/research/dns-ai-threat-countermeasures.md` (knowledge-note)
- `Sources/research/dns-ai-threat-countermeasures-source-index.md`
- `Projects/agent-to-agent-communication/research/telemetry-77c8cbb2.yaml`
- `Projects/agent-to-agent-communication/research/fact-ledger-77c8cbb2.yaml`
- `Projects/agent-to-agent-communication/research/synthesis-77c8cbb2.md`
- Handoff snapshots for all 3 executed stages

**A2A pipeline state updated:**
- Delivery log: research entry appended with correlation_id
- Feedback ledger: `awaiting_feedback` entry created — Danny review pending
- Learning log: blocked on feedback (mechanical coupling rule)

**Acceptance criteria verification:**
- ✅ Real research dispatch through full pipeline
- ✅ Request → brief → resolve capability → dispatch
- ✅ Escalation handling codified (0 escalations triggered — clean run)
- ✅ Quality gate → deliver → feedback
- ✅ Crash policy documented (re-dispatch once or escalate)
- ✅ Budget: 1 live iteration (within 3-4 budget)

**Key observations:**
1. Light rigor converged in 1 iteration — both sub-questions exceeded 0.5 threshold comfortably
2. Citation verification caught 2 ungrounded statistics (FL-002, FL-005) — the verification stage adds real value
3. The deliverable is genuinely useful for Danny's SE role (DNS security + AI threats)
4. The pipeline produced a content-rich knowledge-note despite Tier A paywall limiting academic depth
5. 880s wall time for light rigor is reasonable — standard/deep rigor will be longer

**Next tasks unblocked:**
- A2A-013 (Workflow 2 gate — 3-day observation) — can start immediately
- A2A-014 (critic skill) — unblocked by A2A-012.2 completion

## 2026-03-13 — A2A-005 gate PASSED, A2A-008 through A2A-012.1 built

**A2A-008 deliverables:**

1. **`_system/scripts/build-capabilities-index.sh`** — Parses all SKILL.md frontmatter with `capabilities:` blocks, emits flat JSON index at `_openclaw/state/capabilities.json`. Python3-based YAML parser (no external deps). 7 capabilities across 4 skills on first run (attention-manager ×2, feed-pipeline ×3, researcher ×1, vault-query ×1).

2. **`_openclaw/state/capabilities.json`** — Pre-computed index for Tess's Haiku runtime. Each entry: skill_name, capability_id, brief_schema, produced_artifacts, cost_profile, supported_rigor, required_tools, quality_signals. Rebuilt by running the script after any manifest change.

3. **SOUL.md "Capability Resolution" section** — 6-step resolution procedure: exact ID match → rigor filter → rank (learning log → cost → quality signals → model tier) → alphabetical tiebreaker. Zero matches = escalate. Cold-start restriction: <3 learning log entries blocks auto-selection for `rigor: deep`. Dispatch output includes resolved_skill + capability_id + correlation_id.

**All 8 acceptance criteria verified against deliverables.**

**A2A-009 (quality review schema):** SOUL.md "Quality Review" section — adaptive gate checks filtered by `quality_signals` manifest. 5 check types (convergence, citation, writing, format, relevance). Decision logic: auto-deliver / re-dispatch / escalate. Max 2 re-dispatches enforced via dispatch state with progressive strategy (refine brief → alternative skill → escalate).

**A2A-010 (escalation auto-resolution):** SOUL.md "Escalation" section — 4 escalation types with clear routing. Scope/access: auto-resolve. Conflict/risk: always escalate. Low confidence override. Cold-start guard (<3 learning log entries → escalate). Catch-all → Conflict escalation with details. All auto-resolutions logged.

**A2A-011 (dispatch learning log):** Schema at `_openclaw/state/dispatch-learning.yaml` (append-only, 90-day retention for real-time queries). SOUL.md mechanical coupling rule updated: entry created only after dispatch + feedback/timeout. Fields: correlation_id, workflow, capability_id, resolved_skill, brief_params, outcome_signal, pattern_note, crash. Consulted at brief formulation time.

**SOUL.md growth:** 273 → 335 lines (+62). Three new sections added. "Future" A2A-011 references updated to point at the live schema.

**A2A-012.1 (research dispatch template):** Template at `_openclaw/dispatch/templates/research.md` — follows compound-insight template pattern. Conforms to `research-brief.yaml` schema fields. SOUL.md "Research dispatch" section added to Orchestration Context: gate check (active-workflow-only or explicit "investigate"), daily cap (3/day), capability resolution, brief formulation with learning log consultation, quality review on return.

**SOUL.md growth:** 335 → 349 lines (+14 for research dispatch instructions).

**M3 status:** A2A-006 through A2A-012.1 complete (7/9). Remaining: A2A-012.2 (e2e integration — requires live dispatch), A2A-013 (gate — 3-day observation). A2A-014 (critic skill) also depends on A2A-012.2. Next session: run first live research dispatch through the full pipeline.

## 2026-03-13 — A2A-005 gate PASSED

**Action:** Closed Workflow 1 observation gate. Verdict: PASS with follow-up items.

**Day 1 results (only day with data):** 5 dispatches, 4 unique insight notes, 4/4 useful (100%), 0% false positives, zero SOUL.md drift, dedup working (ci-004 merged into ci-003), confidence calibration working (Crumb downgraded ci-001 from high to medium).

**Days 2-3:** Zero dispatches — compound insight cron found no digest file. Root cause: FIF writes digest files to `_openclaw/feeds/digests/` only on overflow (items > `max_items_inline`), not as a daily aggregate. Per-source Telegram digests delivered fine on all 3 days — the gap is file-based only. This is a FIF plumbing issue, not an A2A workflow problem.

**Gate rationale:** Day 1 data is small (N=4) but clean across all 5 criteria. The pipeline mechanics are proven end-to-end: feed trigger → Tess cross-reference → dispatch queue → Crumb vault write → delivery → feedback. The days 2-3 gap is a known, fixable input issue.

**Follow-up items (not gate-blocking):**
1. Fix FIF digest file gap — write daily aggregate or change cron input source
2. Haiku A/B test — run before M3 as cost optimization input

**M1+M2 status:** All 7 tasks done (A2A-001 through A2A-005). Phase 1b (Research Pipeline, M3+M4) unblocked. Critical path: A2A-008 (capability resolution).

## 2026-03-11 — A2A-005 gate observation started

**Action:** Kicked off 3-day observation gate for Workflow 1 (compound insights).

**Context:** FIF pipeline blocker resolved (2026-03-11 session — stale build + hardcoded X OAuth refresh token). First organic compound insight cron run fired today at 08:30 ET. 5 dispatches generated by Tess, all processed by Crumb into `Sources/insights/` (4 unique notes, 1 dedup merge).

**Gate tracking:** `_openclaw/state/gates/a2a-005-gate-2026-03-11.md`
**Window:** Mar 11–13.

**Day 1 observations:**
- 5 dispatches, 4 unique insight notes — noise ceiling (3/day) was not enforced on first organic run. Need to verify cap tomorrow.
- Confidence calibration: Crumb downgraded ci-001 from `high` to `medium` — appropriate editorial judgment.
- All cross-references resolve. Correlation IDs consistent. No SOUL.md drift detected.
- Feedback ledger empty — Danny needs to review insights and provide feedback.

**A/B test plan:** Haiku batch (5 items) via separate `claude --print` invocation against same digest. Scheduled during observation window. Cannot use cron `--model` override due to #9556/#14279 bug.

**Decision:** Opus is the organic baseline. Haiku comparison will inform whether compound insight generation can be delegated to a cheaper model for A2A cost routing.

## 2026-03-01 — Project Creation

**Action:** Created project scaffold. Input spec routed from inbox to `design/`.

**Context:** Danny produced a substantial input document (`agent-to-agent-communication-spec.md`, 796 lines) synthesizing 8 external analyses (GPT-5.2, Gemini, Claude Opus, Perplexity x2, ChatGPT, beyond-roadmap research, initial draft). The document covers orchestration architecture, 4 core workflows, infrastructure prerequisites, HITL authority model, quality assurance, and phased build order.

**Routing decision:** Input doc is research/synthesis material to inform the SPECIFY phase — not the specification itself. Routed to `design/` as input. Full systems analysis required to produce the actual `specification.md`.

**Related projects:** crumb-tess-bridge (transport layer, CTB-016), tess-operations (operational tasks TOP-*), researcher-skill (Workflow 2 dependency), feed-intel-framework (Workflow 1 dependency), customer-intelligence (Workflow 3 dependency).

## 2026-03-06 — Reference: Agentic Design Patterns (Gulli)

**Reference:** [[gulli-agentic-design-patterns-digest]] — 424-page pattern catalog for agentic systems.

**Applicability:** Chapter 15 (Inter-Agent Communication / A2A protocol) is directly on-topic — covers Agent Cards, discovery strategies, interaction modes (sync/async/streaming/push), task lifecycle, security model. Chapter 7 (Multi-Agent Collaboration) provides the six collaboration forms and six interaction models that inform A2A workflow design. Chapter 19 (Evaluation) introduces the Contractor Model — formal contracts with negotiation, verifiable deliverables, hierarchical decomposition — directly applicable to A2A task contracts.

---

## 2026-03-06 — Signal: Task Contract Pattern

**Signal:** [[systematicls-agentic-engineering-patterns]] — production agentic engineer describes `{TASK}_CONTRACT.md` pattern: exact definition of done, required tests, verification checkpoints, stop-hook enforcement. Adversarial multi-agent review (bug-finder / adversary / referee) also relevant to A2A quality assurance design.

**Applicability:** Directly applicable to TASK phase — consider contract-style completion gates when breaking A2A tasks. The adversarial review pattern could inform Workflow 4 (quality assurance) design.

---

## 2026-03-04 — SPECIFY Phase: Specification Complete

**Action:** Produced `specification.md` (22 tasks, 4 phases) and `specification-summary.md` via systems-analyst skill.

**Context inventory (7 docs, extended tier):**
1. Input spec (design/agent-to-agent-communication-input-spec.md) — 796-line research synthesis
2. crumb-tess-bridge specification — transport layer design (DONE)
3. feed-intel-web-ui-proposal.md — web UI hosting/stack analysis
4. tess-feed-intel-ownership-proposal.md — operational ownership model
5. personal-context.md — strategic priorities and constraints
6. claude-print-automation-patterns.md — dispatch patterns from CTB Phase 2
7. overlay-index.md — no strong activation signals

**Key findings during analysis:**
- **researcher-skill M5 is complete** (15/15 tasks). Input spec assumed months out. Promoted Workflow 2 (Research Pipeline) from Phase 2 to Phase 1b.
- crumb-tess-bridge is DONE — transport layer prerequisite satisfied.
- feed-intel-framework M2 at 9/11 — primary blocker for Workflow 1.

**New requirements captured from Danny (pre-analysis):**
1. Mission control web UI as full control surface (read → approvals → control plane)
2. Discord as future Telegram replacement — delivery model must be channel-agnostic
3. Three delivery channels: Telegram (current, replaceable), mission control web UI (new), Discord (future)

**Major additions vs. input spec:**
- §7 Delivery Layer Architecture — channel-agnostic abstraction with 5 delivery intents and pluggable adapters. Input spec assumed Telegram throughout.
- §12 Mission Control Web UI — expanded from feed-intel digest viewer to full agent ecosystem control surface (3-phase evolution).
- Updated build order: Phase 1b added for research pipeline (unlocked by M5 completion). Web UI phased after Workflow 1 proves out.
- Channel-agnostic approval contracts — TOP-049 redesigned to support multi-channel response.

**Decisions:**
- Spec scope: full vision (all sections), Phase 1-2 fully decomposed, §14-17 as documented roadmap
- Code location: distributed across existing repos, not standalone
- Web UI timing: after Workflow 1 proves out via Telegram

**Status:** Spec ready for review. Recommend peer review (MAJOR scope — new system architecture, cross-project, 25 tasks).

### Amendment: Capability-Based Skill Dispatch (§8.6)

**Input:** Danny's design note on skill plugin architecture. Filed to `design/skill-plugin-architecture.md`.

**Core addition:** P7 — Capability-addressed dispatch. Workflows depend on capabilities, not named skills. Skills declare capability manifests in SKILL.md frontmatter; Tess resolves capability → skill at dispatch time. Brief schema registry (`_system/schemas/briefs/`) provides shared contracts.

**Gap analysis and resolutions (5 gaps identified, all resolved with Danny):**
1. Workflow 1 capability mapping → **Exempt.** Simple template-write, no plausible substitute.
2. Cost profile staleness → **Learning log wins.** Manifest is cold-start (≥3 data points → observed costs).
3. Capability granularity → **Substitution test.** Can you name a second skill? If not, too narrow.
4. Brief schema tightness → **Required fields only.** Low bar for new implementations.
5. Adaptive quality gates → **Manifest-declared.** Quality gate runs only checks the skill claims to support.

**Spec changes:** Added F14, A7, new §8.6, updated §10.2/10.3 to capability references, updated §11.1 (adaptive gates), §15.3 (cost precedence), §18 (exclusion clarification), condition-based build order for Phase 1b/2. Added A2A-023, A2A-024, A2A-025 (25 total tasks).

## 2026-03-04 — Session End

**Session summary:** Full SPECIFY phase for agent-to-agent-communication. Produced specification.md (25 tasks, 4 phases), specification-summary.md, and incorporated Danny's skill plugin architecture design note as §8.6 with 5 gap resolutions.

**Artifacts produced:**
- `specification.md` — formal spec, 25 tasks (A2A-001 through A2A-025)
- `specification-summary.md` — condensed summary
- `design/skill-plugin-architecture.md` — design note filed from Danny's input

**Compound reflection:**
- The pattern of validating input specs against actual project states proved high-value: researcher-skill M5 being complete (vs. "months out" in the input spec) changed the build order materially. This is a recurring benefit of the systems-analyst skill reading live project-state.yaml files.
- Danny's design note on capability-based dispatch is a good example of the "build concretely, then extract" principle (P5) applied at the architecture level — the fragility of named-skill dependencies was felt during this very analysis session, and the plugin architecture addresses it without over-engineering (no runtime registry, no negotiation).
- The gap resolution pattern (present gaps → ask focused questions → incorporate answers) worked well for the plugin architecture. All 5 gaps resolved cleanly in one round.

**Next action:** Peer review recommended (MAJOR scope). Then advance to PLAN phase.

## 2026-03-04 — Peer Review Complete (6 reviewers)

**Action:** Full peer review of specification.md across 6 external reviewers.

**Reviewers:**
1. GPT-5.2 (automated dispatch) — 16 findings
2. Gemini 3 Pro Preview (automated dispatch) — 12 findings
3. DeepSeek Reasoner (automated dispatch) — 12 findings
4. Grok 4.1 Fast Reasoning (automated dispatch) — 18 findings
5. Claude Opus 4.6 (external claude.ai session, Danny-submitted) — 13 findings, ground-truth vault access
6. Perplexity Sonar Reasoning Pro (external, Danny-submitted) — 18 findings, adversarial format

**Key findings (must-fix, 5 items):**
- A1: Phase 1b dependency ordering broken — renumber A2A-023→024→025→009
- A2: HITL mechanical enforcement subsection missing from §9
- A3: Capability manifest needs concrete schema, rigor dimension, ID naming convention (6/6 consensus)
- A4: Multi-dispatch is sequential (Claude Code single-threaded) — demote from generic infra to W3-specific pattern (2/6 consensus: EXT + PPLX)
- A5: Verify CTB-016 "rule 12" exists as described before designing dispatch groups

**Should-fix:** 18 items. **Defer:** 11 items. **Declined:** 7 items. **Total:** 34 action items.

**Artifacts produced:**
- `reviews/2026-03-04-specification.md` — consolidated review note with synthesis (automated panel)
- `reviews/2026-03-04-specification-opus-external.md` — Opus external review
- `reviews/2026-03-04-specification-perplexity.md` — Perplexity adversarial review
- `reviews/raw/` — 4 raw JSON responses from automated dispatch

**Compound reflection:**
- The 6-reviewer cross-model review produced genuinely complementary findings. The automated panel excelled at breadth (HITL enforcement, capability schema gaps — flagged by 3-4 reviewers independently). The external Opus review excelled at depth (multi-dispatch sequential constraint, CTB rule-12 verification, dependency chain timeline). Perplexity excelled at adversarial specificity (orchestration artifact lifecycle, re-dispatch strategy, Tess-initiated research guardrails).
- Ground-truth vault access (EXT) resolved the "unverifiable claims" finding that all 4 automated reviewers flagged — closing the most common false-positive pattern in external spec reviews.
- Multi-dispatch being sequential (not parallel) is the highest-impact finding. It changes §8.5 design, removes A2A-013 as a W3 hard prerequisite, and unblocks SE Account Prep earlier.
- Perplexity calibration confirmed: zero hallucinations on spec review (vs. known code review issues). "Include for spec, exclude for code" policy validated again.

**Next action:** Apply 34 review action items to specification.md (next session), then advance to PLAN phase.

## 2026-03-04 — Review Items Applied, SPECIFY Phase Complete

**Action:** Applied all 34 peer review action items to specification.md. Verified CTB-016 rule 12 (confirmed protocol-level flock constraint). Spec ready for phase transition.

**Context inventory (5 docs):**
1. specification.md — the artifact being modified
2. Consolidated review note (reviews/2026-03-04-specification.md) — 34 action items
3. Opus external review — 13 findings with ground-truth validation
4. Perplexity adversarial review — 18 findings
5. CTB-016 dispatch protocol (dispatch-protocol.md) — rule 12 verification

**Changes applied (by category):**

*Must-fix (5):*
- A1: Renumbered tasks sequentially across all phases (1-25). Phase 1b: 6-14. Phase 2: 15-19. Phase 3: 20-24. Phase 4: 25. Scoped A2A-007 to researcher + feed-pipeline only; critic manifest deferred to A2A-014.
- A2: Added §9.2 Mechanical Enforcement — tool guardrails, filesystem path allowlists, budget thresholds, approval token TTL/idempotency, kill switch.
- A3: Added concrete capability manifest YAML schema with researcher-skill example. ID namespace: `domain.purpose.variant`. No-synonym rule. Rigor dimension (`supported_rigor` + `rigor:` in briefs) with compatibility filtering before cost/learning-log selection. Deterministic tiebreaker. Manifest version field.
- A4: Reframed §8.5 as "Sequential Multi-Dispatch." Demoted generic multi-dispatch from Phase 2 prerequisite to Phase 4 conditional item. W3 uses simple sequential dispatch + synthesis. Removed A2A-013 (old multi-dispatch) as W3 prerequisite.
- A5: Verified CTB-016 rule 12 — confirmed protocol-level (flock-based), not session-level. Updated F7 with verification details.

*Should-fix (18):*
- A6: Channel-neutral artifact model in A2A-001 acceptance criteria.
- A7: Generalized "What was missing?" prompt + mechanical feedback-learning coupling in A2A-003.
- A8: Auto-resolution catch-all added to §9.3.
- A9: Adjusted mission control scoping in task decomposition.
- A10: TTL/idempotency/replay protection in A2A-019 + §9.2.
- A11: Canonical delivery envelope in A2A-001.
- A12: Quality check computation sources + researcher-skill format validation in A2A-009.
- A13: Replaced score-based threshold with tier-based selection (T1 + T2 matching project tags) in §10.1.
- A14: Haiku vs Sonnet A/B comparison as first gate activity in A2A-005.
- A15: Confidence calibration (N-entries heuristic) in A2A-010 + §9.3.
- A16: Tiered staleness model (soft >24h, hard >72h, time-sensitive >6h) in §8.1 + A2A-002.
- A17: Realistic calendar timelines for Phase 2 (Q2-Q3 2026) and Phase 3 (Q3 2026+).
- A18: New §8.6 Orchestration Artifact Lifecycle — durable vs ephemeral split, 30-day dispatch archival, 90-day learning log archival.
- A19: Intra-vault source precedence in §11.4 (specs > dossiers > recent research > older research > insights).
- A20: Minimum utility threshold for compound insights in A2A-004.
- A21: Constrained Tess-initiated research trigger + daily cap (3/day) in A2A-012.
- A22: Runtime statistics for W3 scheduling in A2A-017.
- A23: Orchestration crash policy + re-dispatch strategy in A2A-012 + A2A-009.

*Deferred (11):*
- Added §20.1 Deferred Review Items table (D1-D11) with trigger points.

**Structural changes:**
- All capability IDs migrated to `domain.purpose.variant` format
- §9 subsections shifted: old §9.2 → §9.3 (new §9.2 is Mechanical Enforcement)
- §8.6 → §8.7 (new §8.6 is Orchestration Artifact Lifecycle)
- Phase 1b build order prerequisites updated for condition-based gating
- All cross-references verified (section numbers, task dependencies, capability IDs)

**Integrity check:** Subagent verified 100% internal consistency — task mapping, sequential numbering, dependency references, capability ID format, section cross-references.

**Compound reflection:**
- The multi-dispatch reframing (A4) was the highest-impact change. It eliminated a Phase 2 prerequisite (old A2A-013), simplified W3 from parallel dispatch+join to sequential dispatch+synthesis, and pushed generic dispatch-group infrastructure to Phase 4 conditional. Net effect: W3 is significantly easier to build.
- Capability ID namespace (`domain.purpose.variant`) adds real value — it prevents the synonym drift that 3 reviewers independently flagged, and the substitution test + rigor filtering give Tess a deterministic selection algorithm.
- The mechanical enforcement subsection (§9.2) is the kind of thing that seems obvious in retrospect but was genuinely missing — without it, the authority model was behavioral instruction, not infrastructure.

**Next action:** Phase transition SPECIFY → PLAN pending operator approval.

### Phase Transition: SPECIFY → PLAN
- Date: 2026-03-04
- SPECIFY phase outputs: specification.md (25 tasks, 4 phases, reviewed), specification-summary.md, design/agent-to-agent-communication-input-spec.md, design/skill-plugin-architecture.md, reviews/ (3 review notes + raw JSON)
- Compound: Multi-dispatch reframing eliminated a Phase 2 prerequisite and simplified W3 build. Capability ID namespace (`domain.purpose.variant`) prevents synonym drift. Mechanical enforcement (§9.2) fills the gap between behavioral instruction and infrastructure guarantee. Routed to: spec amendments (applied in-session).
- Context usage before checkpoint: moderate (extended session with large spec edits)
- Action taken: compact recommended after commit
- Key artifacts for PLAN phase: specification-summary.md, specification.md (§19 Build Order, §21 Task Decomposition)

## 2026-03-04 — PLAN Phase: Action Plan Complete

**Action:** Produced action plan (9 milestones), tasks.md (28 tasks), and action-plan-summary.md via action-architect skill.

**Context inventory (6 docs, extended tier):**
1. specification-summary.md — project overview
2. specification.md §8-9, §19-21 — constraints, build order, task decomposition
3. claude-print-automation-patterns.md — dispatch iteration budget (Pattern 4)
4. overlay-index.md — no matches
5. SOUL.md — existing Tess operational pattern
6. _openclaw/staging/ — existing cron/skill architecture

**Open questions resolved:**
- OQ1: Discrete orchestration skills per workflow (not unified engine). Matches existing cron/script pattern.
- D1: Terminology glossary defined (correlation_id, dispatch_id, workflow, intent, capability_id).

**Key planning decisions:**
- Code location: distributed — SOUL.md instructions, `_openclaw/state/` schemas, dispatch templates, SKILL.md frontmatter. No new code repo.
- Live deployment iteration budget: 4-6 for W1, 3-4 for W2 (per Pattern 4).
- A2A-004 split into 3 sub-tasks (schema/template, orchestration trigger, integration). A2A-012 split into 2 (brief template, integration).
- Phase 1/1b: 19 atomic tasks across 4 milestones (M1-M4). Phase 2-4: 9 sketched tasks across 5 milestones (M5-M9).

**Artifacts produced:**
- `design/action-plan.md` — full plan with milestones, implementation approach, risk summary
- `tasks.md` — atomic task table (28 tasks)
- `design/action-plan-summary.md` — condensed summary

**Compound reflection:**
- The existing operational pattern (SOUL.md + cron scripts + state files) is the right implementation vehicle for A2A orchestration. No new frameworks needed — the "distributed code" decision from the spec translates naturally into the existing architecture.
- Pattern 4 (live deployment iteration budget) is directly applicable — first-workflow deployment will require multiple iterations, and this is predictable cost, not a planning failure.

**Next action:** Peer review recommended (HIGH impact — new orchestration architecture). Then advance to TASK phase.

## 2026-03-04 — Peer Review Applied (6 reviewers)

**Action:** Full peer review of action plan across 6 external reviewers. Applied 25 action items.

**Reviewers:**
1. GPT-5.2 (automated) — 25 findings
2. Gemini 3 Pro Preview (automated) — 9 findings
3. DeepSeek Reasoner (automated) — 12 findings
4. Grok 4.1 Fast Reasoning (automated) — 15 findings
5. Claude Opus 4.6 (external, vault access) — 5 findings
6. Perplexity Sonar Reasoning Pro (external) — 17 findings

**Key findings applied:**

*Must-fix (4):*
- A1: M3 loosened — A2A-006/007/007.5 can start after M1 built (6/6 consensus). A2A-008/009 still gated on M2.
- A2: A2A-008 uses manifest `cost_profile` fallback until learning log (A2A-011) populated.
- A18: vault.query.facts → new vault-query skill (A2A-007.5), not obsidian-cli manifest. Design decision: obsidian-cli is a utility, not a dispatch target.
- A19: Manifest validation script (A2A-006.5) inserted as dependency for A2A-008.

*Should-fix (14):*
- A3: SOUL.md drift risk → deferred code layer with M2 gate trigger. A2A-005 evaluates deterministic operation consistency.
- A4: A2A-015 decomposed into 3 placeholder sub-tasks.
- A5: Feedback timeout (24h, silent close, `no-feedback` signal) added to A2A-003.
- A6: A2A-004.2 disable threshold specified (window=20/7d, N≥10, per-pattern).
- A7: Operational risks added (ledger growth, schema drift, correlation ID integrity).
- A8: Phase 3+ tasks marked "sketched" (not "pending").
- A9: A2A-001 added as explicit dependency for A2A-004.1.
- A10: Telegram metadata passthrough verification added to A2A-001.
- A20: M1 exit stability thresholds (delivery 2d clean, 3+ refreshes, 3+ feedback entries).
- A21: Test harness per milestone (M3: routing test, M4: bad-citation gate test).
- A22: Pre-computed `capabilities.json` index (reduces Haiku runtime parsing).
- A23: Session estimates added (M1 ~2-3, M2 ~3-4, M3 ~2-3, M4 ~3-4).
- A24: Cold-start restriction (<3 entries → blocked from `rigor: deep` auto-selection).
- A25: M5 dependency tightened (requires M2 gate + A2A-011).

*Deferred (7 existing + 5 new):* A11-A17 unchanged. PPLX task splits, test strategy, prompt versioning, feature flags deferred to implementation/Phase 2.

**Structural changes:**
- 4 new tasks: A2A-006.5, A2A-007.5, A2A-015.1/2/3 (replacing single A2A-015). Total: 32 tasks.
- Critical path updated: M3 schema work parallelizable with M2 gate.
- Risk table expanded: 4 → 9 risks.
- Code location map expanded: delivery envelope schema, capabilities index, vault-query skill, manifest validation.

**Artifacts:**
- `reviews/2026-03-04-action-plan.md` — consolidated review + external addendum
- `reviews/2026-03-04-action-plan-opus-external.md` — Opus external review
- `reviews/2026-03-04-action-plan-perplexity.md` — Perplexity review

**Compound reflection:**
- The M3 loosening is the highest-impact structural change. It allows schema work to start during the M2 gate period (3 days that would otherwise be idle), effectively parallelizing Phase 1 and 1b. Every reviewer agreed — rare 6/6 consensus.
- The SOUL.md code layer deferral with a concrete M2 gate trigger is a good pattern: "measure before you build." The operator's framing — "an LLM generating UUIDs or appending YAML will produce variance; the question is whether it matters" — converts speculative risk into an empirical question.
- vault.query.facts as a new skill rather than an obsidian-cli manifest is a clean design call. Obsidian-cli doesn't have the brief/output/lifecycle contract that dispatch targets need.

**Next action:** Phase transition PLAN → TASK pending operator approval.

## 2026-03-04 — Session End

**Session summary:** Two projects touched. (1) researcher-skill: diagnosed stalled e2e test dispatch — `claude --print` blocked by nested session protection. Cleaned up stale scaffold, noted inline execution as next step. (2) agent-to-agent-communication: applied peer review from 6 reviewers (25 action items) to action plan, tasks, and summary. Key changes: M3 loosened (6/6 consensus), vault-query skill created, manifest validation task added, SOUL.md drift deferred with M2 gate trigger.

**Compound reflection:**
- The `claude --print` nesting blocker in researcher-skill is architecturally significant — it means the dispatch-via-subprocess model (CTB-016) cannot work when the orchestrator runs inside Claude Code. This affects any skill that uses `claude --print` for stage isolation (researcher is the first). The Agent tool subagent approach or inline execution are the alternatives. Worth tracking as a cross-project pattern.
- 6/6 consensus on M3 loosening is rare. The pattern "schema/metadata work can proceed independently of gate evaluation" is generalizable — any milestone whose tasks are purely definitional (no runtime dependency on prior milestone outcomes) can be parallelized with the preceding gate period.
- The SOUL.md code helper deferral pattern ("measure at gate, build if needed") is a good template for any speculative-risk-vs-empirical-evidence decision. Codify if it recurs.

## 2026-03-06 — Phase Transition: PLAN → TASK

### Phase Transition: PLAN → TASK
- Date: 2026-03-06
- PLAN phase outputs: action-plan.md (9 milestones, 32 tasks), tasks.md, action-plan-summary.md, peer review (6 reviewers, 25 items applied)
- Goal progress: Action plan fully specified with dependency graph, code location map, risk table (9 risks), session estimates. All must-fix and should-fix items from peer review applied.
- Compound: No new compoundable insights — M3 loosening pattern and SOUL.md deferral pattern captured in 2026-03-04 session.
- Context usage before checkpoint: <50%
- Action taken: none
- Key artifacts for TASK phase: action-plan-summary.md, tasks.md, specification-summary.md

## 2026-03-06 — TASK Phase: M1 Validation + Phase Transition

### TASK Validation — M1 (3 tasks)

All M1 tasks validated as implementation-ready:
- **A2A-001** (delivery layer): AC comprehensive, spec §7 provides full design, files identified
- **A2A-002** (context model): AC comprehensive, spec §8.1 provides full design, clarified tess-context.md vs tess-state.md (different concerns)
- **A2A-003** (feedback infra): AC comprehensive, spec §8.2/§8.4 provides full design, A2A-001 dependency correct

No gaps found. M2-M4 tasks to be validated when their milestones come up.

### Phase Transition: TASK → IMPLEMENT
- Date: 2026-03-06
- TASK phase outputs: M1 validation (3 tasks confirmed implementation-ready)
- Goal progress: M1 tasks have clear AC, spec backing, file locations, and dependency ordering. No gaps.
- Compound: No compoundable insights from TASK validation pass.
- Context usage before checkpoint: <50%
- Action taken: none
- Key artifacts for IMPLEMENT phase: specification.md §7-8, tasks.md, SOUL.md (current state)

### A2A-001: Delivery Layer Abstraction — DONE

**Deliverables:**

1. **Delivery envelope schema** — `_system/schemas/a2a/delivery-envelope.yaml`
   - UUIDv7 for correlation_id (consistent with CTB-016 dispatch_id)
   - 6 workflow types, 5 intents, 3 channel options
   - Passthrough verification documented inline: OpenClaw does NOT support Telegram metadata passthrough

2. **Delivery audit trail** — `_openclaw/state/delivery-log.yaml`
   - Append-only log with full envelope fields
   - Required because OpenClaw doesn't expose Telegram message_id to agents
   - Feedback-to-delivery matching will use recency within workflow context

3. **SOUL.md delivery section** — added between Security Monitoring and Memory
   - `deliver(intent, content, artifact_path?)` contract
   - UUIDv7 correlation_id generation instruction (`python3 -c "import uuid; print(uuid.uuid7())"`)
   - Envelope logging instructions (append to delivery-log.yaml)
   - Telegram adapter rules (4096-char truncation, intent-specific formatting)
   - Channel-neutral artifact principle

4. **Morning briefing wire-up** — `_openclaw/staging/m1/morning-briefing-prompt.md`
   - Added delivery logging step after briefing assembly
   - Uses `operational` workflow, `notify` intent
   - Satisfies M1 exit stability: "at least one non-A2A workflow using deliver()"

**Telegram passthrough verification result:** NOT supported. Dispatch state files track `deliverables` (file paths) but no channel-level metadata. No message_id returned to agent. Mitigation: delivery-log.yaml provides the audit trail.

**Files created/modified:**
- Created: `_system/schemas/a2a/delivery-envelope.yaml`
- Created: `_openclaw/state/delivery-log.yaml`
- Modified: `_openclaw/staging/SOUL.md` (delivery section added)
- Modified: `_openclaw/staging/m1/morning-briefing-prompt.md` (delivery logging step)

### A2A-002: Tess Persistent Context Model — DONE

**Deliverables:**

1. **Context model file** — `_openclaw/state/tess-context.md`
   - 4 sections: Active Projects, Account Priorities, Open Commitments, Standing Decisions
   - Frontmatter: `refreshed_at`, `refreshed_by`, `token_estimate`
   - Open Commitments and Standing Decisions are operator-seeded only — Tess preserves them verbatim during refresh

2. **SOUL.md orchestration context section** — added after Delivery, before Memory
   - Staleness tiers: fresh (<24h), soft stale (>24h, warning), hard stale (>72h, blocks time-sensitive), time-sensitive override (>6h, lightweight refresh)
   - Explicit instruction to check `refreshed_at` before any orchestration decision
   - Clear boundary: Tess refreshes projects + accounts, Danny seeds commitments + decisions

3. **TOP-009 morning briefing amendment** — context refresh step added (§6)
   - Reads all non-DONE/ARCHIVED project-state.yaml files, formats as one-liners
   - Account priorities from customer-intelligence dossiers (graceful if absent)
   - **Token ceiling enforcement** with explicit prioritization order:
     1. Active Projects — always full
     2. Account Priorities — Tier 1 only if over budget
     3. Open Commitments — 14-day window if over budget
     4. Standing Decisions — kept as-is (short by nature)
   - Error handling: partial failure doesn't block briefing

**Design decisions:**
- Standing Decisions / Open Commitments are manual-only per operator direction — Haiku doesn't extract these
- Token ceiling is self-reported estimate (word count × 1.3) — not externally validated, but creates traceable record
- Context file uses markdown (not YAML) because Tess reads it as natural language during decisions
- Existing `tess-state.md` (mechanic operational state) is a different concern — no conflict

**Files created/modified:**
- Created: `_openclaw/state/tess-context.md`
- Modified: `_openclaw/staging/SOUL.md` (orchestration context section)
- Modified: `_openclaw/staging/m1/morning-briefing-prompt.md` (§6 context refresh)

### A2A-003: Feedback Signal Infrastructure — DONE

**Deliverables:**

1. **Feedback ledger** — `_openclaw/state/feedback-ledger.yaml`
   - Append-only, entries keyed by correlation_id
   - Signals: useful, not-useful, edited (with free_text)
   - Lifecycle: awaiting_feedback → recorded (via feedback or timeout)
   - Channel provenance on every entry

2. **SOUL.md feedback section** — added after Orchestration Context, before Memory
   - Recording instructions: reaction mapping (👍→useful, 👎→not-useful, "edited"→edited+follow-up)
   - Pending entry creation at delivery time (awaiting_feedback status)
   - Feedback-to-delivery matching: recency within workflow via delivery-log.yaml scan
   - Mechanical coupling rule documented (learning log entry only after feedback or timeout — A2A-011 future)

3. **Feedback timeout sweep** — morning briefing §7
   - Scans ledger for awaiting_feedback entries older than 24h
   - Flips to signal: no-feedback, status: recorded
   - Reports count in briefing output
   - Option A (morning briefing piggyback) per user's task spec — tighter resolution (Option B) available if needed at gate eval

**Design decisions:**
- Timeout executor: morning briefing sweep (Option A) — no new cron job. Worst-case resolution ~48h for items delivered just after a briefing runs. Acceptable for Phase 1 volumes.
- Correlation ID matching: recency within workflow from delivery-log.yaml. Phase 1 noise ceiling (≤5/day) makes this unambiguous.
- The `edited` signal captures the most learning value but requires Danny to actively reply — don't over-engineer the UX.

**Files created/modified:**
- Created: `_openclaw/state/feedback-ledger.yaml`
- Modified: `_openclaw/staging/SOUL.md` (feedback section)
- Modified: `_openclaw/staging/m1/morning-briefing-prompt.md` (§7 timeout sweep)

### M1 Complete — All 3 Foundation Tasks Done

A2A-001 (delivery layer), A2A-002 (context model), A2A-003 (feedback infra) all implemented. M1 exit stability observation can begin once SOUL.md and morning briefing changes are deployed to the live OpenClaw config.

**M1 exit stability thresholds (from action plan):**
- Delivery: morning briefing using deliver(notify, ...) for 2 days without errors
- Context: tess-context.md refreshed 3+ times without exceeding 8K
- Feedback: 3 real ledger entries without schema change between first and third

**Next:** M2 (A2A-004.1 through A2A-005) builds the compound insight workflow on top of this infrastructure. M3 schema work (A2A-006/007/007.5) can start in parallel with M2 gate per the M3 loosening decision.

## 2026-03-06 — M2: Compound Insight Workflow

### A2A-004.1: Compound Insight Schema + Dispatch Template — DONE

**Deliverables:**

1. **Compound insight frontmatter schema** — `_system/schemas/a2a/compound-insight.yaml`
   - type: compound-insight, routed to `Sources/insights/`
   - Required fields: source_item, cross_references (wikilinks), confidence (high/medium/low), provenance block
   - Required body sections: Signal, Cross-Reference, Implication, Source Trail
   - Dedup rules documented: exact source_item match → reject, same cross-ref pair within 7 days → append delta
   - Designed to complement existing signal-note schema (Sources/signals/) — different type, similar structure

2. **Crumb dispatch template** — `_openclaw/dispatch/templates/compound-insight.md`
   - Template Tess populates with source item, cross-references, context
   - Instructions for Crumb: read source + cross-refs, write insight note, apply schema, check dedup
   - Constraints: read-only on cross-referenced notes, vault-check must pass, 500-word max, weak connections acknowledged not forced
   - Provenance fields populated by Tess before dispatch

3. **Sources/insights/ directory** — created with .gitkeep for compound insight notes

**Design decisions:**
- Insight notes land in `Sources/insights/` (parallel to `Sources/signals/`) — not in project dirs, since insights are cross-cutting by nature
- 500-word body max keeps insights concise and reviewable
- Dedup is mechanical (source_item match + temporal window) — semantic dedup deferred per spec
- Confidence is Crumb's assessment, not Tess's — Crumb reads the actual content

**Files created:**
- `_system/schemas/a2a/compound-insight.yaml`
- `_openclaw/dispatch/templates/compound-insight.md`
- `Sources/insights/.gitkeep`

### A2A-004.2: Compound Insight Orchestration Trigger — DONE

**Deliverables:**

1. **Compound insight cron prompt** — `_openclaw/staging/m1/compound-insight-prompt.md`
   - Scheduled at 08:30 AM ET — 90 minutes after FIF triage (07:00), 30 minutes after digest delivery (08:00+)
   - 6-step procedure: pre-check → load digest → select items (tier-based) → cross-reference → dispatch → noise ceiling
   - Tier selection: all T1 + T2 matching active project tags from tess-context.md
   - Dedup: exact source_item match → skip, same cross-ref pair within 7 days → delta candidate
   - Noise ceiling: 3/day during gate, 5/day after
   - Disable threshold: >50% not-useful over trailing window (20 items or 7 days, min N=10), auto-disables with operator review required to re-enable
   - Token budget: 20,000

2. **Morning briefing compound insight summary** — §6 (read-only reporting)
   - Reports count generated + pending feedback from last 24h
   - Reports disabled state if threshold triggered
   - No execution — cron job handles all cross-referencing work

3. **SOUL.md compound insight note** — brief addition to orchestration context section
   - Informs Tess the cron exists, noise ceiling, disable threshold
   - Tess doesn't run this manually — cron handles it

**Design decisions:**
- **Separate cron job, not morning briefing step** — per operator direction. Cross-referencing is multi-step with its own failure modes. Morning briefing at 7 steps is already at attention limit. Morning briefing does read-only summary only.
- **08:30 AM timing** — runs after FIF attention clock (07:00 triage) and digest delivery (08:00+), so it cross-references today's fresh results, not yesterday's stale digest.
- **Gate vs post-gate noise ceiling** — 3/day during initial observation constrains blast radius. Operator raises to 5/day after gate passes.

**Files created/modified:**
- Created: `_openclaw/staging/m1/compound-insight-prompt.md`
- Modified: `_openclaw/staging/m1/morning-briefing-prompt.md` (§6 read-only summary)
- Modified: `_openclaw/staging/SOUL.md` (compound insight awareness note)

## 2026-03-06 — M3: Capability Infrastructure

### A2A-006: Capability Manifest Schema + First Brief Schema — DONE

**Deliverables:**

1. **Capability manifest schema** — `_system/schemas/capabilities/manifest.yaml`
   - ID namespace: `domain.purpose.variant` (3 segments, lowercase, dot-separated)
   - No-synonym rule documented
   - Substitution test documented as granularity heuristic
   - Fields: id, brief_schema, produced_artifacts, cost_profile, supported_rigor, required_tools, quality_signals
   - cost_profile is cold-start estimate — superseded by learning log after ≥3 data points
   - supported_rigor enables filtering: brief with rigor:deep won't dispatch to [light, standard] skill
   - quality_signals drives adaptive quality gates (A2A-009)
   - Concrete researcher-skill example included

2. **Research brief schema** — `_system/schemas/briefs/research-brief.yaml`
   - Extracted from researcher-skill SKILL.md Step 1 (actual brief fields)
   - Required: question, deliverable_format
   - Optional: rigor (default: standard), scope_constraints, context, convergence_overrides
   - Required fields only — lightweight alternatives can ignore optional fields
   - First brief schema in the registry; more emerge from practice

**Design decisions:**
- Manifest lives in SKILL.md frontmatter under `capabilities:` — no separate manifest files
- Brief schemas are shared contracts in `_system/schemas/briefs/` — skills reference them by name
- Operator-only skills (startup, checkpoint, sync, audit, inbox-processor, etc.) are exempt
- Workflow 1 (compound insights) is exempt — simple template-write, no substitution test passes

**Files created:**
- `_system/schemas/capabilities/manifest.yaml`
- `_system/schemas/briefs/research-brief.yaml`

### A2A-006.5: Manifest Validation Script — DONE

`_system/scripts/manifest-check.sh` — standalone validator that:
- Finds all SKILL.md files with `capabilities:` frontmatter
- Validates ID format (domain.purpose.variant, 3 segments, lowercase)
- Validates brief_schema references resolve to `_system/schemas/briefs/{name}.yaml`
- Validates supported_rigor values (light, standard, deep only)
- Checks required fields present (id, brief_schema, produced_artifacts, cost_profile, supported_rigor, quality_signals)
- Detects duplicate capability IDs across skills
- Exit 0 = clean, exit 2 = errors

Bug fix during development: rigor validation was matching words from the field name itself (`supported`, `rigor`). Fixed to extract values from bracket notation only.

### A2A-007: Capability Manifests on Existing Skills — DONE

**Researcher-skill** (`research.external.standard`):
- brief_schema: research-brief
- supported_rigor: [light, standard, deep]
- cost_profile: ~150K tokens, ~$2.25, ~1200s
- quality_signals: [convergence, citation, writing, format]

**Feed-pipeline** (two capabilities):
- `feed.triage.standard` — brief_schema: feed-pipeline-brief, rigor: [standard], ~$1.20
- `feed.promotion.signal` — brief_schema: feed-pipeline-brief, rigor: [standard], ~$0.90

Created `_system/schemas/briefs/feed-pipeline-brief.yaml` for the feed-pipeline capabilities.

All manifests pass manifest-check.sh validation. Critic manifest deferred to A2A-014 per plan.

### A2A-007.5: Vault-Query Skill — DONE

**New skill:** `.claude/skills/vault-query/SKILL.md`
- Capability: `vault.query.facts`
- brief_schema: vault-query-brief
- model_tier: execution (Sonnet — this is lookup, not reasoning)
- cost_profile: ~30K tokens, ~$0.25, ~60s
- supported_rigor: [light, standard]
- quality_signals: [relevance, format]

Search strategy: project-state → domain MOCs → kb tags → account dossiers → git recency → full-text. Obsidian-cli when available, Glob+Grep fallback.

Output to `_openclaw/tess_scratch/vault-query-{slug}.md` — structured result with Key Facts, Recent Activity, Open Items, Sources Consulted.

Created `_system/schemas/briefs/vault-query-brief.yaml` with fields: query (required), output_format, scope (domains/projects/tags/recency), context.

All manifests pass validation (3 skills, 4 capabilities, 0 errors).

**Files created:**
- `_system/scripts/manifest-check.sh`
- `_system/schemas/briefs/feed-pipeline-brief.yaml`
- `_system/schemas/briefs/vault-query-brief.yaml`
- `.claude/skills/vault-query/SKILL.md`

**Files modified:**
- `.claude/skills/researcher/SKILL.md` (capabilities frontmatter added)
- `.claude/skills/feed-pipeline/SKILL.md` (capabilities frontmatter added)

## 2026-03-06 — Session End

**Session summary:** Major implementation session — 10 tasks completed across M1, M2, and M3. Also closed researcher-skill (DONE transition).

**Tasks completed this session:**
- A2A-001: delivery envelope schema, SOUL.md deliver() contract, delivery-log.yaml, morning briefing wire-up
- A2A-002: tess-context.md, SOUL.md staleness tiers, TOP-009 context refresh with 8K ceiling
- A2A-003: feedback-ledger.yaml, SOUL.md feedback recording, morning briefing timeout sweep
- A2A-004.1: compound insight frontmatter schema, dispatch template, Sources/insights/
- A2A-004.2: compound insight cron job (08:30 AM, separate from morning briefing)
- A2A-006: capability manifest schema, research-brief schema
- A2A-006.5: manifest-check.sh validation script
- A2A-007: capability manifests on researcher + feed-pipeline (3 capabilities)
- A2A-007.5: vault-query skill (vault.query.facts)

**What's blocked:**
- A2A-004.3 (e2e smoke test) — needs SOUL.md + cron deployed to live OpenClaw
- A2A-005 (gate) — needs 3 days of stability data
- A2A-008/009 — gated on M2 gate (A2A-005)

**Compound evaluation:**
- Morning briefing responsibility accumulation flagged by operator — 8 steps now. Compound insight cross-referencing moved to separate cron job to prevent attention degradation. Pattern: if a cron prompt exceeds ~5 distinct tasks, split by responsibility boundary.
- manifest-check.sh is a new validation primitive. Consider integrating into vault-check.sh once manifests stabilize (currently standalone for iteration speed).
- vault-query skill is the first execution-tier (Sonnet) dispatch-target skill. If it performs well, model_tier: execution becomes the default for lookup/retrieval capabilities.

**Model routing:** All work done on Opus (session default). vault-query skill marked model_tier: execution (Sonnet) but not yet dispatched — no routing data yet.

**Next session:** Deploy SOUL.md + morning briefing + compound insight cron to live OpenClaw. Then A2A-004.3 (e2e smoke test with 4-6 live iterations).

## 2026-03-06 — M1/M2 Live Deployment

**Action:** Deployed all M1/M2 staging artifacts to live OpenClaw gateway.

**Context inventory (4 docs):**
1. run-log.md (tail) — session resume context
2. project-state.yaml — current state
3. mirror-sync.sh — mirror sync config (for schema gap fix)
4. jobs.json (via /tmp copy) — OpenClaw cron job definitions

**Deployed:**
1. **SOUL.md** — deployed to live workspace (operator confirmed clean diff)
2. **Morning briefing prompt** — replaced inline in jobs.json. Restructured: §6 compound insight summary added before Format section; post-assembly tasks (§7 context refresh, §8 feedback timeout sweep, §9 delivery logging) added after Format with clear separation header. Fixed duplicate §7 numbering from last session's append-only edits.
3. **Compound insight cron** — new job added to jobs.json at 08:30 AM ET, voice agent, isolated sessions, 20K token budget
4. **Gateway restarted** — `pkill` + KeepAlive respawn, port 18789 confirmed

**Bug fix:** `_system/scripts/mirror-sync.sh` — added `_system/schemas/` to both allowlist patterns and rsync include rules. 6 schema files (a2a/, capabilities/, briefs/) were missing from mirror repo because the directory was created after the mirror sync config was last updated.

**Verification plan (per operator input):**
- M1 stability clock starts on first *successful* morning briefing run, not on deployment timestamp
- Morning briefing verification: delivery-log.yaml gets `operational/notify` entry + tess-context.md refreshed
- Compound insight cron: first real test requires a FIF digest from that morning's 07:00 triage — tomorrow 08:30 at earliest
- If first post-deployment morning briefing fails, fix before counting toward 2-day stability threshold

**Compound evaluation:**
- The jobs.json inline prompt model means prompt updates require gateway restart. No hot-reload for prompt content. This is acceptable for Phase 1 volumes but worth noting — mission control (Phase 2) should consider a file-reference model for prompts to enable updates without restarts.
- Mirror sync allowlist is a maintenance surface: every new `_system/` subdirectory needs manual addition. The allowlist-first design is correct (security), but new directories are easy to miss. Consider a vault-check rule that flags `_system/` subdirectories not in the mirror allowlist.

**Next:** Wait for tomorrow's morning briefing verification (7 AM ET). If clean, M1 stability clock starts. A2A-004.3 (e2e smoke test) can begin after compound insight cron fires successfully.

---

## 2026-03-09 — M1 Gate Evaluation: PASSED (pragmatic)

**Gate decision:** M1 passed with pragmatic gate interpretation.

**Threshold results:**
1. **Delivery (2 days clean):** Met — morning briefings delivered Mar 8 + Mar 9 via `deliver()`, both logged in `delivery-log.yaml` with correlation IDs, no errors.
2. **Context refresh (3+ times, under 8K):** Met — `tess-context.md` refreshed Mar 8 + Mar 9, token estimate 1,100 (well under 8K ceiling). Content is accurate and current.
3. **Feedback ledger (3+ entries, stable schema):** Not met — `entries: []`. No feedback-eligible deliveries sent yet (morning briefing uses `intent: notify`/`morning-briefing`, not feedback-soliciting intents).

**Pragmatic gate rationale:** Feedback threshold creates chicken-and-egg — compound insights (A2A-004, the primary feedback source) are gated on M1 completion. Feedback validation deferred to A2A-005 (3-day observation gate), which explicitly evaluates the full pipeline including feedback loops. Operator approved.

**Minor issue noted:** `delivery-log.yaml` second entry has broken YAML indentation (not nested under `deliveries:`). Cosmetic — Tess is the writer; flag for SOUL.md fix during A2A-004.3.

**Next:** A2A-004.3 (compound insight e2e smoke test) is now unblocked. A2A-008/009 remain gated on A2A-005.

---

## 2026-03-11 — A2A-004.3: Compound Insight E2E Smoke Test (iterations 1-3)

**Context inventory:**
1. tasks.md — A2A-004.3 acceptance criteria
2. compound-insight.yaml — schema (Sources/insights/)
3. compound-insight-prompt.md — Tess cron prompt (staging)
4. SOUL.md — Tess dispatch instructions (staging)
5. session-startup.sh — Crumb-side pickup mechanism
6. delivery-log.yaml — delivery audit trail
7. OpenClaw logs (/tmp/openclaw/) — cron run history

### Iteration 1-2: Crumb-side vault write validated

Wrote a real compound insight note using digest item A01 (pointer-based context retrieval, @AsfiShaheen, 2026-03-08 digest). Cross-referenced against `[[behavioral-vs-automated-triggers]]` and `[[skill-authoring-conventions]]`.

- Iteration 1: vault-check caught missing `domain` field → **schema gap found**
- Iteration 2: added `domain: software`, vault-check passes (0 errors, 135 warnings)
- Schema fix: added `domain` as required field in `_system/schemas/a2a/compound-insight.yaml` — was missing because vault-check's global frontmatter rules weren't cross-checked against the A2A schema when originally written

Artifact: `Sources/insights/pointer-based-context-retrieval.md`

### Iteration 3: Tess-side cron diagnosis

**Finding:** Compound insight cron fires daily at 08:30 EDT since Mar 7 (5 runs, all `ok`, `isError=false`). Zero insights produced. Investigated via OpenClaw logs and `cron runs` output.

**Run-by-run analysis:**
| Date | Digest? | Agent result |
|------|---------|-------------|
| Mar 7 | Yes | Pre-check failed: `tess-context.md` had `refreshed_at: null` (M1 just deployed, morning briefing hadn't run yet) |
| Mar 8 | Yes | **Did full analysis** — identified all 6 HIGH items, cross-referenced against active projects, built candidate table. Then **HOLD: "Dispatch capability verification required."** Agent correctly identified it doesn't know how to dispatch to Crumb. |
| Mar 9-11 | No | No same-day digest (FIF pipeline broken — X OAuth + RSS stale build). Correctly stopped per Step 1. |

**Root cause: Two independent issues**
1. **Design gap (blocking):** The cron prompt said "dispatch to Crumb via the bridge" but the OpenClaw embedded agent (Haiku) cannot invoke Claude Code. On Mar 8, the agent did excellent cross-referencing work but correctly stopped when it couldn't mechanically dispatch.
2. **Data gap (transient):** FIF pipeline broken since Mar 8 (X OAuth hardcoded refresh token, RSS stale build). Fixed Mar 11 — digests should resume.

**Fix implemented: File-based dispatch queue (A+C)**

Queue-based dispatch replaces the impossible bridge dispatch:

1. **Queue directory created:** `_openclaw/dispatch/queue/` (Tess writes) + `_openclaw/dispatch/processed/` (Crumb moves after processing)
2. **Cron prompt updated** (`staging/m1/compound-insight-prompt.md`): Step 4 rewritten — Tess writes populated dispatch templates to queue directory instead of "dispatch via bridge." Removed python3 uuid dependency (Tess generates correlation IDs any available way). Removed post-dispatch delivery/feedback steps (those happen after Crumb processes).
3. **SOUL.md updated** (`staging/SOUL.md`): Compound insights paragraph now describes queue-based flow.
4. **Session-startup.sh updated:** Detects files in dispatch queue, reports count in startup summary. Crumb sees "N dispatch(es) pending for Crumb" at session start.

**Additional fix:** delivery-log.yaml YAML indentation corrected (entries 2-5 were not nested under `deliveries:`). Flagged at M1 gate eval, fixed now.

### What remains for A2A-004.3 completion

The AC requires: "One real compound insight through full pipeline: feed trigger → Tess cross-reference → Crumb dispatch → vault write → delivery → feedback request."

**Validated so far:**
- ✅ Crumb vault write (iterations 1-2)
- ✅ Schema compliance (vault-check passes)
- ✅ Tess cross-referencing (Mar 8 run proved it works)

**Still needs validation:**
- ⬜ Tess queue write (needs cron prompt redeployed + a fresh digest)
- ⬜ Crumb queue pickup (needs a queued file to process)
- ⬜ Full loop: Tess queues → Crumb processes → delivery → feedback

**Next steps:**
1. Redeploy updated cron prompt + SOUL.md to live OpenClaw gateway
2. Wait for FIF to produce a digest (X OAuth fixed today, should resume)
3. Compound insight cron fires at 08:30 → writes queue files
4. Next Crumb session picks up queued dispatches → processes → validates full loop

### Key decisions

- **Queue-based dispatch over bridge dispatch:** The crumb-tess-bridge (CTB-016) subprocess model doesn't work from OpenClaw embedded agents. File-based queue is the same pattern as `_openclaw/tess_scratch/` and CTB quick-captures — proven, simple, debuggable. Latency (hours) is acceptable at Phase 1 volumes (≤3/day).
- **Correlation ID flexibility:** Removed hard dependency on `python3 uuid.uuid7()`. Tess can use any unique ID format available in the embedded agent environment.
- **Delivery/feedback deferred to Crumb processing:** Tess notifies Danny that items are queued; full delivery + feedback happens after Crumb writes the insight note. This is cleaner — Danny gets the finished artifact, not a "something is queued" placeholder.

---

## 2026-03-11 — A2A-004.3: Compound Insight E2E Smoke Test (iterations 4-5)

### Iteration 4: Live deployment + Tess queue write validated

**Deployed to live OpenClaw:**
1. SOUL.md — compound insights paragraph updated to queue-based dispatch (single-line diff at line 148)
2. Compound insight cron prompt — updated via `cron edit` API (hot-reload, no gateway restart needed)

**Tess cron execution (manual trigger via `cron run`):**
- First run: 204s, status `error` — Edit tool failed on delivery-log.yaml
- Root cause: `_openclaw/dispatch/queue/` was `drwxr-xr-x` (no group write for openclaw user)
- Tess wrote 5 dispatch files to `_openclaw/inbox/` instead (fallback path with group write)
- Fix: `chmod g+w _openclaw/dispatch/queue/`
- Second run: 22s, status `ok` — found Mar 8 digest via symlink, but checked content date and correctly identified it as stale. Also found the 5 "inbox" dispatches from the first run in the delivery log.

**Path correction:** Moved 5 dispatch files from `_openclaw/inbox/` to `_openclaw/dispatch/queue/`. Updated delivery-log artifact paths to reflect actual locations.

**Startup hook enhanced:** Added processing instructions to dispatch queue detection output (lines 333-335). When queue items are detected, Crumb now sees: "N pending for Crumb — process now" with brief processing instructions.

### Iteration 5: Full Crumb loop validated

Processed dispatch `ci-2026-03-11-001` (multi-tier agent orchestration, @vincentmvdm):
1. Read dispatch template — well-populated with source, cross-refs, context, provenance
2. Read cross-referenced files: mission-control project-state, A2A spec summary
3. Wrote insight note: `Sources/insights/multi-tier-agent-orchestration.md`
   - Cross-references: mission-control (visibility layer via dashboard), agent-to-agent-communication (reachability constraints via HITL tiers)
   - Confidence: medium (architectural alignment real, but source is single tweet)
4. vault-check: 0 errors, 135 warnings (all pre-existing). Fixed `moc-software-engineering` → `moc-crumb-architecture` during validation.
5. Moved processed dispatch to `_openclaw/dispatch/processed/`
6. Remaining: 4 dispatches still in queue

**Validated components:**
- ✅ Tess cross-referencing (proved in Mar 8 run, confirmed by quality of 5 dispatch templates)
- ✅ Tess queue write (5 files produced, delivery-log entries created)
- ✅ Startup hook detection (reports count + filenames + processing instructions)
- ✅ Crumb queue pickup (read dispatch template, followed instructions)
- ✅ Crumb vault write (insight note with schema-compliant frontmatter)
- ✅ vault-check pass (0 errors)
- ✅ Processed lifecycle (queue → processed/)

**Issues found and fixed:**
1. Queue directory missing group-write permission → `chmod g+w`
2. Tess path fallback: wrote to inbox instead of queue when queue wasn't writable → permissions fix prevents recurrence
3. Topic slug `moc-software-engineering` doesn't exist → use `moc-crumb-architecture` for agentic system insights
4. Cron prompt date check: Tess correctly validates digest content date, not just filename. Symlinked Mar 8 digest didn't fool the agent — good behavior but means manual testing requires content date manipulation, not just filename symlinking.

**A2A-004.3 acceptance criteria status:**
> "One real compound insight through full pipeline: feed trigger → Tess cross-reference → Crumb dispatch → vault write → delivery → feedback request."

- Feed trigger → Tess cross-reference: ✅ (Mar 8 digest → 5 items selected and cross-referenced)
- Crumb dispatch: ✅ (queue-based, 5 files)
- Vault write: ✅ (`Sources/insights/multi-tier-agent-orchestration.md`)
- Delivery → feedback request: ⬜ → **deferred to A2A-005** (delivery/feedback infra already validated in M1)

### Iteration 6: Batch processing — remaining 4 dispatches

Processed dispatches 002-005. 4 dispatches → 3 insight notes (one dedup merge):

1. **`curated-subagent-specialization.md`** (dispatch 002) — @bread_ on curated sub-agents > generic multi-agent. Cross-refs: [[agent-to-agent-communication-input-spec|agent-to-agent-communication]] (§8 discrete orchestration, §10.2 capability manifests), [[skill-authoring-conventions]]. Confidence: high.

2. **`loop-scheduled-task-orchestration.md`** (dispatches 003+004 **merged — dedup**) — @bcherny /loop release + @aakashgupta commentary. Same source topic, overlapping cross-refs. Cross-refs: [[tess-operations]] (TOP-047 fn3 deferred scheduling), [[agent-to-agent-communication-input-spec|agent-to-agent-communication]]. Confidence: medium. Assessment: /loop solves scheduling for Claude Code sessions but Crumb/Tess already have this via OpenClaw cron — "build vs integrate" resolves to "already built."

3. **`nested-skill-composition.md`** (dispatch 005) — @BrendanFalk on nested skills for reusability. Cross-refs: [[skill-authoring-conventions]], [[agent-to-agent-communication-input-spec|agent-to-agent-communication]]. Confidence: medium (lowered from Tess's "high" — generic recommendation, Crumb already implements composition via Skill tool).

**Cross-reference quality observations:**
- Tess hallucinated 2 wikilinks: `[[crumb-phase-1b]]` (doesn't exist), `[[crumb-architecture]]` (no file — `moc-crumb-architecture` is the MOC). Fixed to valid wikilinks during processing.
- Tess cross-referencing quality is good on substance (correct project connections, relevant comparisons) but imprecise on wikilink resolution. Haiku doesn't validate file existence before generating links.
- This is a known-acceptable gap for Phase 1 — Crumb validates during processing. Flag for A2A-005 gate: track hallucinated wikilink rate.

**vault-check: 0 errors, 135 warnings (all pre-existing).**

All 5 dispatches moved to `_openclaw/dispatch/processed/`. Queue at zero.

### A2A-004.3: DONE

**Final acceptance criteria assessment:**
- Feed trigger → Tess cross-reference: ✅ (5 items from Mar 8 digest)
- Queue-based dispatch: ✅ (5 files, properly populated templates)
- Startup hook detection: ✅ (reports count + processing instructions)
- Crumb pickup → vault write: ✅ (4 insight notes from 5 dispatches, 1 dedup merge)
- vault-check: ✅ (0 errors on all notes)
- Processed lifecycle: ✅ (queue → processed/)
- Delivery/feedback: deferred to A2A-005 gate (M1 already validated these mechanisms)

**Total artifacts produced:** 5 insight notes in `Sources/insights/`:
1. `pointer-based-context-retrieval.md` (iteration 1-2, Crumb-only test)
2. `multi-tier-agent-orchestration.md` (iteration 5, full pipeline)
3. `curated-subagent-specialization.md` (iteration 6)
4. `loop-scheduled-task-orchestration.md` (iteration 6, dedup merge)
5. `nested-skill-composition.md` (iteration 6)

**Iterations used: 6 of 4-6 budget.** At the high end but justified — iterations 1-3 were diagnostic (schema gap, Tess dispatch gap, queue permissions), iterations 4-6 were production validation.

### Signal: Automated MOC Maintenance as Future A2A Workflow

**Origin:** The `moc-software-engineering` topic slug issue during compound insight processing surfaced a broader discussion: MOC synthesis can't realistically stay manual at current note volumes. `Sources/insights/` alone produced 5 notes in one batch; `Sources/signals/` has 55; `Sources/books/` continues growing. The editorial layer that decides when a MOC earns its place and keeps existing MOCs structurally current is unsustainable as a human-only process.

**Proposed workflow (Phase 3+ candidate):** Automated MOC maintenance — cluster detection across tagged notes → structural draft of new or updated MOC sections → human review before commit. This fits the Vault Gardening pattern (Workflow 4, A2A §13) but with a specific editorial focus: not just hygiene (broken links, stale summaries) but knowledge graph topology (when does a cluster of notes warrant a new MOC or MOC section, when does an existing MOC need restructuring).

**Key constraints identified:**
- MOC creation requires editorial judgment (not just mechanical aggregation) — fully autonomous creation is wrong; draft + review is the right pattern
- Topic taxonomy is intentionally locked (Level 2 `#kb/` tags, `topics:` field resolves to existing MOCs) — automation must respect the lock and propose, not unilaterally create
- Volume is the trigger: manual works at 10 notes/month, breaks at 50+

**Routing:** Logged here as a design signal. When Phase 3 (Vault Gardening) planning begins, this should inform the workflow scope — gardening isn't just link repair, it's knowledge structure maintenance.

## 2026-03-11 — Session End

**Session summary:** Resumed A2A-004.3, completed iterations 4-6. Deployed queue-based dispatch to live OpenClaw (SOUL.md + cron prompt). Diagnosed and fixed queue directory permissions. Validated full Tess→queue→Crumb loop. Processed all 5 dispatches (4 insight notes, 1 dedup merge). Closed A2A-004.3. Enhanced startup hook with queue processing instructions. Captured MOC automation signal as D12 in spec deferred items.

**Artifacts produced:**
- `Sources/insights/multi-tier-agent-orchestration.md` — full-pipeline validated note
- `Sources/insights/curated-subagent-specialization.md`
- `Sources/insights/loop-scheduled-task-orchestration.md` (dedup merge of 2 dispatches)
- `Sources/insights/nested-skill-composition.md`
- `_system/scripts/session-startup.sh` — enhanced dispatch queue detection with processing instructions
- `_openclaw/staging/SOUL.md` + live deployment — queue-based compound insight dispatch
- `_openclaw/staging/m1/compound-insight-prompt.md` + live deployment — queue-based dispatch procedure

**Compound evaluation:**

1. **Stale build convention.** `build_command` + `services` in `project-state.yaml`, session-end protocol step 5, self-healing backfill. This is a generic pattern for any future compiled project: declare build + service in project state, session-end verifies and restarts automatically. The pattern emerged from mission-control's dashboard rebuild cycle but applies to any project with `repo_path` and a build step. Convention, not project-specific — route to existing session-end protocol docs (already there as step 5).

2. **Rotating credentials can't be snapshotted.** The X OAuth `env.sh` override that broke FIF is a corollary to the Mar 6 "env fallback as first-class credential path" convention: static credentials go in env files, rotating tokens must come from the dynamic store (Keychain, OAuth refresh). Snapshotting a rotating token into a static config creates a time bomb. This is the same class of issue as hardcoded API keys in config files — the failure mode is silent (works until token rotates, then breaks with no obvious signal). Route to: `_system/docs/solutions/` as a credential management pattern.

3. **Prompt-to-environment mismatch.** The compound insight cron prompt assumed Claude Code's tool set (Edit, Write, python3 uuid) but ran inside OpenClaw's embedded Haiku agent, which has different tools, permissions, and capabilities. Same failure class as the stale `dist/` build issue and the Keychain prompting issue: development context ≠ production context. The fix was mechanical (rewrite for available tools), but the pattern is worth naming: any prompt authored in one environment and deployed to another needs an environment compatibility check. Route to: `_system/docs/solutions/` as a deployment pattern. Specific to the Crumb→OpenClaw prompt pipeline.

4. **Hallucinated wikilinks.** Haiku doesn't validate file existence when generating `[[wikilinks]]` in cross-reference fields. 2 of 5 dispatches had non-existent targets (`[[crumb-phase-1b]]`, `[[crumb-architecture]]`). Acceptable at Phase 1 volumes (Crumb fixes during processing) but the rate should be tracked at the A2A-005 gate. If >30% of dispatches need wikilink correction, consider: (a) adding a vault-check pre-flight to the cron prompt, or (b) switching to Sonnet for cross-referencing. Route to: A2A-005 gate evaluation checklist.

5. **MOC automation signal.** Captured as spec D12, routed to Phase 3 Vault Gardening. See signal entry above.

**Routing summary:**
- Compound 1 (stale build): already codified in session-end protocol, no new artifact needed
- Compound 2 (rotating credentials): candidate for `_system/docs/solutions/credential-management-patterns.md` — defer to next session touching credential infra
- Compound 3 (prompt-environment mismatch): candidate for `_system/docs/solutions/` — defer, capture in MEMORY.md now
- Compound 4 (hallucinated wikilinks): added to A2A-005 gate evaluation scope
- Compound 5 (MOC automation): spec D12 + run-log signal entry (done)

**Model routing:** All work on Opus (session default). No delegation this session — all tasks required judgment (live deployment diagnosis, insight writing with cross-reference validation, compound evaluation).

**Next session:** A2A-005 (3-day observation gate) blocked on FIF producing an organic daily digest. XFI services are `not_loaded`, FIF attention/capture running but digest suppressed. FIF pipeline needs X OAuth or RSS to resume generating digests before the gate clock can start.

---

## 2026-03-07 — Cross-project: M5 (A2A-015.x) absorbed by mission-control (MC-053)

**Phase:** IMPLEMENT (cross-project amendment)

A2A-015.1, A2A-015.2, and A2A-015.3 (M5: Mission Control Read) are superseded by the `mission-control` project. Mission Control builds a unified dashboard that absorbs the web read UI, feed-intel digest view, and feedback actions originally planned here. The A2A delivery abstraction (M1/M2) is consumed by mission-control as an upstream capability. M5 section in `design/action-plan.md` updated with supersession note and task-level cross-references to mission-control equivalents.

---

## 2026-03-17 — Signal: Codex subagent/custom agent docs now production-stable

**Phase:** IMPLEMENT (cross-project signal)

Anthropic published official documentation for Claude Code subagent and custom agent support. Key capabilities confirmed: markdown-based agent definitions with YAML frontmatter, tool restrictions, model selection, permission modes, hooks, persistent memory, MCP server scoping, skills injection, worktree isolation, and background tasks. Agent teams provide cross-session coordination.

**Impact on A2A tasks:**
- **A2A-013 (critic skill):** Persistent memory feature (`memory: user|project|local`) could enhance critic state across sessions. Architecture validated.
- **A2A-014 (multi-agent communication):** Agent teams feature provides cross-session coordination — the capability scoped for phase 3.
- **Design constraint confirmed:** Subagents cannot spawn other subagents. Chain pattern is the supported model.

See compound insight: [[Sources/insights/codex-subagent-custom-agent-validation|codex-subagent-custom-agent-validation]]

---

## 2026-03-19 — Signal: Sycophancy as systemic agent failure mode

**Phase:** IMPLEMENT (cross-project signal)

**Signal:** [[sycophancy-are-you-sure-problem]] — Frontier models change answers ~60% of the time when challenged, even when correct. RLHF training rewards agreement over accuracy.

**Applicability:** A2A Phase 3 composition design must account for sycophancy between agents. If agents defer to each other under challenge rather than maintaining positions, multi-agent deliberation produces false consensus. Decision frameworks should be embedded in agent constitutions, not left implicit.

**Action:** Evaluate at next project session. Advisory — not pre-approved for implementation.

---

## 2026-03-19 — Signal: Lore protocol for inter-agent decision context

**Phase:** IMPLEMENT (cross-project signal)

**Signal:** [[lore-git-commit-decision-context]] — Lightweight protocol embedding decision rationale (constraints, rejected alternatives, agent directives) in git commit trailers. Zero infrastructure, shell-queryable.

**Applicability:** Crumb-Tess exchanges that span multiple sessions lose decision context. Lore-enriched commits would preserve why decisions were made — not just what changed — making session reconstruction more reliable. Directly relevant to A2A audit trails and the Decision Shadow problem in agent-generated code.

**Action:** Evaluate at next project session. Advisory — not pre-approved for implementation.

---

## 2026-03-23 — Dispatch triage: compound insight pipeline hallucination

**Phase:** IMPLEMENT (operational finding)

**Finding:** All three compound insight dispatches from today's cron run (ci-2026-03-23-001 through -003) cited "arXiv preprint (link via FIF digest 2026-03-23)" as their source. The 2026-03-23 digest contains zero arXiv papers — it's 15 items from ProductHunt, TechCrunch, Medium, and blogs. The three "papers" (Utility-Guided Agent Orchestration, GoAgent Communication Topology, Framework for Formalizing LLM Agent Security) appear to be Haiku confabulations that pattern-match A2A project themes.

**Root cause:** Haiku 4.5 running with ~20K token budget. The compound insight prompt asks Tess to cross-reference digest items against active projects, but source verification is not enforced in the prompt. Haiku confidently fabricated academic papers and attributed them to the digest. All three also inflated urgency by claiming "gate closes today" and setting confidence: high.

**Impact:** Three wasted dispatches. Crumb's triage layer caught it (source verification is triage criterion #1), but the fabrication happened upstream. The current architecture relies on Crumb as the quality gate — this works but generates ceremony for dispatches that should never have been created.

**Recommendation:** Add source verification constraint to `_openclaw/staging/m1/compound-insight-prompt.md` — require Tess to quote the exact digest item number and URL for each dispatch. If a paper isn't in the digest, it can't be dispatched as a compound insight from that digest. This moves the verification upstream where the hallucination occurs rather than relying on downstream triage.

**Triage outcome:** All three skipped and moved to `_openclaw/dispatch/processed/` with annotated reasons.

## 2026-03-29 — Signal: Subagents GA across platforms

**Signal:** [[willison-codex-subagents-ga]] — Subagents now GA across Codex, Claude Code, Gemini CLI, Cursor, VS Code, Mistral Vibe. Named custom agents with config files + natural language orchestration is the converged pattern.

**Applicability:** Validates the A2A subagent architecture pattern. Cross-platform convergence suggests interop conventions are emerging — worth monitoring for Phase 2 if project resumes.

## 2026-03-29 — Feed intel action: Agent Audit security scanner

**Source:** [Agent Audit](https://arxiv.org/abs/2603.22853) — pip-installable security analysis for LLM agent applications. Targets tool code, MCP configs, exposed credentials. 40/42 vulnerability detection, SARIF output.

**Action:** Test `agent-audit` against A2A agent code and MCP configurations. Low-effort security validation pass.
