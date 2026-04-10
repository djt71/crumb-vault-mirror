---
type: review
review_type: peer-review
review_mode: full
scope: specification
project: agent-to-agent-communication
domain: software
skill_origin: external-review
created: 2026-03-04
updated: 2026-03-04
status: active
reviewer: anthropic/claude-opus-4-6
tags:
  - review
  - agent-communication
  - architecture
---

# Agent-to-Agent Communication — Peer Review

**Reviewer:** Claude Opus 4.6 (claude.ai session, full project materials read)
**Scope:** Full specification review — input spec (796 lines), skill-plugin-architecture design note, run-log, cross-project dependency validation
**Materials reviewed:** 8 files (input spec, skill-plugin-architecture, run-log, researcher-skill run-log, tess-operations tasks, FIF run-log, CTB design directory, crumb-design-spec §3)

**Note on coverage:** The formal `specification.md` (25 tasks, produced during today's Crumb session) has not synced to the vault mirror yet. This review covers the input spec and the skill-plugin-architecture design note — the two available design artifacts. Where the run-log describes decisions made in the formal spec (delivery layer, mission control web UI, capability-based dispatch, condition-based build order), I'll review those as described. If the formal spec has materially diverged from what's described here, flag those sections for re-review.

---

## Executive Summary

This is a strong specification for an ambitious scope. The problem statement is crisp, the architectural principles are well-grounded in lived experience (not theoretical preference), the infrastructure prerequisites are correctly identified, and the build order is disciplined. The synthesis of 8 external analyses into a coherent vision — while explicitly resolving contradictions between them — is unusually rigorous for a personal project.

The spec's greatest strength is its restraint. The exclusions list (§14) is more architecturally valuable than most of the inclusions — it demonstrates genuine understanding of where complexity comes from and a disciplined refusal to import it. The "build concretely, then extract" principle (P5) and the explicit rejection of framework-first thinking (message envelopes, CRDTs, SPIFFE) are the right calls.

That said, there are real issues — some structural, some in dependency analysis, some in areas where the spec's ambition outpaces its infrastructure. None are project-threatening, but several need resolution before PLAN phase.

**Overall assessment: Ready for PLAN phase with amendments.** The critical findings below should be addressed in the formal spec; the significant findings can be tracked as open items during PLAN.

---

## 1. Architecture & Principles

### Strengths

The blackboard architecture framing (§2.1) is exactly right and the spec earns it. The vault-as-shared-substrate, Tess-as-controller, workers-as-knowledge-sources mapping isn't forced — it genuinely describes how the system already works. Naming the pattern explicitly is valuable because it provides a vocabulary for future design decisions ("is this a blackboard operation or does it need a different pattern?").

P3 (mechanical enforcement over behavioral instructions) is the most important principle in the document and it's correctly marked non-negotiable. The spec consistently applies it — HITL gates use AID-* tokens, budget enforcement is runner-level, kill-switch checks are infrastructure. This isn't aspirational; it's consistent with how CTB-016 already works.

P5 (build concretely, then extract) and P6 (protocols before parallelism) together form a strong defense against the most common multi-agent failure mode: building orchestration infrastructure before you have enough concrete workflows to know what the infrastructure needs to do. The spec walks this talk — Workflow 1 is deliberately the simplest possible end-to-end path.

The two-tier context model (§3.2) is pragmatic. Persistent context file (8K cap, refreshed daily) + situational context (loaded per-trigger) avoids both the "Tess reads the whole vault" and "Tess knows nothing" failure modes. The stale-context detection mechanism (refreshed_at timestamp + 24hr warning) is a genuine safety net, not theater.

### Weaknesses

**F1 (Critical) — Tess's orchestration capacity is under-examined for Workflow 1.** The spec acknowledges the Haiku-vs-Sonnet question in §11 but defers it to gate evaluation. However, even Workflow 1 (compound insights) requires Tess to: (a) cross-reference feed-intel items against active projects and current milestones from her context, (b) judge whether a cross-reference is "genuine" vs. spurious, (c) formulate a compound insight brief that includes the *implication* (not just the connection). This is judgment work, not pattern matching. The spec says "track actual cost during Workflow 1 gate evaluation and adjust tiers" — but if Haiku consistently produces low-quality compound insights during the gate, the gate itself produces garbage data. Consider running a small A/B comparison (5 items Haiku, 5 items Sonnet) as the *first* gate activity rather than defaulting to Haiku and measuring quality after the fact.

**F2 (Significant) — The dispatch learning log's "pattern_note" generation is a bootstrapping problem.** §3.5 says Tess generates the pattern_note by "comparing the brief, the output, and the signal." But the signal is just a verb (useful/not-useful/edited). Tess is supposed to infer *why* Danny edited from only knowing *that* Danny edited — without seeing the edits. This works when the pattern is structural ("missing implications section" is detectable by comparing the brief's expected sections against the output's actual sections). It doesn't work when the issue is qualitative ("the analysis was superficial" or "the cross-reference was wrong"). The spec should acknowledge this limitation and consider: (a) an optional free-text field on the ✏️ signal ("What was missing?" — already exists in Workflow 3's post-call feedback, §5.3, but not generalized), or (b) Tess explicitly noting when pattern_note confidence is low rather than generating a plausible-but-wrong inference.

**F3 (Significant) — The input spec says the single-dispatch constraint (CTB-016 rule 12) is the "primary infrastructure bottleneck."** I searched the dispatch protocol and CTB specification for this rule and couldn't find a constraint phrased as "rule 12" or as a single-active-dispatch restriction. The spec's global flock mechanism does enforce single-bridge-session (preventing overlap with interactive Claude Code sessions), but this is a different constraint than "only one dispatch at a time." The multi-dispatch infrastructure (§3.1) may be solving a problem that doesn't exist in the form described, or may need to solve a different problem (the flock is per-bridge, not per-dispatch). This needs clarification against the actual CTB implementation before §3.1 is designed. If the real constraint is that Claude Code can only run one session at a time (which is a runtime limitation, not a protocol choice), then dispatch groups don't help — you need sequential dispatch with Tess holding intermediate state, not parallel dispatch.

**F4 (Significant) — Confidence-based escalation override (§4.2) lacks a calibration mechanism.** Tess is supposed to assess her own confidence in scope/access escalation resolutions and escalate to Danny when confidence is low. But the spec doesn't define what "low confidence" means operationally, or how Tess calibrates this over time. Without calibration, this degrades in one of two ways: Tess always escalates (defeating the purpose) or Tess never escalates (bypassing the safety net). Suggestion: start with a simple heuristic — if the account or project has fewer than N entries in the dispatch learning log, Tess escalates regardless. Calibrate N during gate evaluation.

---

## 2. Workflows

### Strengths

The workflow ordering is correct. Workflow 1 (compound insights) is the right starting point: daily cadence, write-to-vault only (no external actions), builds on an existing pipeline, and exercises the core orchestration path (triage → context lookup → brief formulation → dispatch → deliver). Everything you learn from Workflow 1 informs the others.

The temporal dedup mechanism for compound insights (§5.1) — checking for existing insights on the same cross-reference pair within 7 days and appending deltas — is a subtle but important design choice. Without it, a slowly-developing story generates a new compound insight every day, each saying roughly the same thing.

Workflow 3 (SE Account Prep) is where the daily-work ROI is highest and the spec correctly identifies the killer feature: deadline-aware degradation. "Something useful in 5 minutes beats something perfect in 2 hours" is the right design philosophy, and the 30-minute delivery target with fallback to vault-only data is pragmatic.

The post-call feedback loop (§5.3) is well-designed. Prompting Danny *after* the calendar event ends (not before) means the feedback is about actual utility, not anticipated utility. The ✏️ → "What was missing?" follow-up captures the diagnostic signal that the bare verb doesn't provide (see F2).

### Weaknesses

**F5 (Significant) — Workflow 1's "high-signal item detection" trigger is underspecified.** The spec says items scoring ≥ threshold pass to Tess, "where threshold is a configurable parameter starting at the top quartile of historical scores." But the feed-intel-framework's triage scores are classification tiers (T1/T2/T3), not continuous scores. FIF's triage produces tier assignments, not numeric scores. Either Workflow 1 needs to define its own scoring function on top of FIF's tier assignments (e.g., "all T1 items + T2 items matching active project tags"), or the threshold language should be replaced with tier-based language. This isn't just a wording issue — it affects whether the compound insight pipeline receives 2 items/day or 20.

**F6 (Significant) — Workflow 2's quality gate (§5.2/§6.1) references researcher-skill telemetry that may not exist in the expected form.** The quality review schema checks "convergence score from researcher-skill telemetry" and "RS-007 output" and "RS-008 output." Now that researcher-skill M5 is complete, the actual output structure should be validated against these assumptions. The convergence score exists (confirmed in M3b implementation). But the check "Writing validation — All 4 checks pass" assumes RS-008 produces exactly 4 named checks — this should be verified against the actual writing validation template. If the researcher-skill's output format doesn't match these quality gate expectations, the gate silently passes everything (because checks can't bind to data) or silently fails everything (because checks can't parse the output). Verify alignment before Phase 2 begins.

**F7 (Minor) — Workflow 4 (vault gardening) entity resolution deferral is correct but the trigger is vague.** The spec says "When the vault accumulates enough entity variants to cause practical problems." This is fine philosophically but doesn't give Tess a mechanical signal. Consider: vault-check.sh could track a count of wikilinks that differ only by case or punctuation (e.g., `[[Acme]]` vs `[[Acme Corp]]` vs `[[ACME]]`). When this count exceeds a threshold, the spike is warranted. This turns a vague trigger into a measurable one.

---

## 3. Infrastructure Prerequisites

### Strengths

The correlation ID design (§3.4) is correct in its simplicity. "Not a formal event-sourced audit log — just a consistent identifier that enables `grep correlation_id`" is exactly right. The temptation with traceability is to build a structured event store; the spec correctly notes that grep is sufficient until proven otherwise.

The feedback signal infrastructure (§3.3) is appropriately minimal. Three verbs (useful/not-useful/edited), append-only YAML ledger, graceful degradation when no feedback is given. The "no feedback = no signal, not negative signal" design choice prevents the system from penalizing Danny for being busy.

### Weaknesses

**F8 (Critical) — Multi-dispatch (§3.1) has a fundamental constraint the spec doesn't address: Claude Code sessions are single-threaded.** Dispatch groups propose running 2-3 concurrent dispatches to Crumb. But Crumb *is* a Claude Code session. You can't run two Claude Code sessions simultaneously on the same machine (the lockfile prevents it, and even without the lockfile, you'd have concurrent vault writers which is unsafe). So "parallel" dispatches to Crumb must actually be sequential — Tess holds the join contract, dispatches branch A, waits for completion, dispatches branch B, then merges. This is still valuable (Tess holds the orchestration context across sequential dispatches, which is the real unlock) but it's a fundamentally different design than the spec implies. The join contract, group budgets, and merge policies still make sense — but the implementation is sequential-with-shared-context, not parallel. The spec should be explicit about this, because it affects timing estimates for Workflow 3 (SE Account Prep won't get vault + external research "in parallel" — it gets them sequentially with Tess merging afterward).

**F9 (Significant) — The tess-context.md refresh depends on TOP-009 (morning briefing), which is operational.** But the spec doesn't address what happens between the morning refresh and evening. If Danny changes project priorities mid-day (which happens — session work routinely reorders things), Tess's persistent context is stale for the rest of the day. The stale-context detection (refreshed_at > 24hr) only catches *missed* refreshes, not mid-day staleness. The spec acknowledges this in Open Question 3 ("increase to twice-daily or event-triggered refresh") but treats it as a tuning parameter rather than a design consideration. For Workflow 1 this is low-risk (compound insights are a batch operation). For Workflow 3 (SE Account Prep triggered by a meeting in 30 minutes), mid-day context staleness could produce incorrect priority assessments. Suggestion: for time-sensitive workflows (Workflow 3), Tess should do a lightweight context refresh (just project-state.yaml files, not a full briefing rebuild) before formulating the brief.

**F10 (Minor) — Dispatch learning log (§3.5) says Tess reads it "at brief formulation time (not during retrospectives — this is real-time learning)."** This means every brief formulation requires a YAML file read and pattern search. At scale (multiple dispatches/day), this is fine. But the spec should note that the learning log needs periodic pruning or archival — if every dispatch for 6 months is in a single YAML file, the read-and-search cost grows unboundedly. A simple "archive entries older than 90 days to a separate file" policy would prevent this.

---

## 4. Skill Plugin Architecture (Design Note)

### Strengths

This is the most architecturally significant addition to the spec. The core insight — workflows should depend on capabilities, not named skills — is correct and addresses a real problem (the researcher-skill M5 completion changing the build order is the concrete proof). The design is appropriately minimal: no runtime registry, no negotiation, no hot-reload. Skills declare capabilities in frontmatter; Tess reads frontmatter at dispatch time. This is the simplest possible mechanism that solves the problem.

The substitution test heuristic for capability granularity ("can you name a plausible second skill?") is a genuinely useful design tool. It prevents both over-abstraction (capabilities so broad they're meaningless) and over-specificity (capabilities so narrow that only one skill will ever match).

The brief schema registry design (§2.3) correctly defers creation to the point of need: "When a second skill needs the same brief type as an existing one, extract the schema at that point." This is P5 applied at the schema level.

The decision to resolve capability → skill *before* dispatch (Option A in §5) keeps the runner simple. The alternative (runtime resolution) would require the runner to understand capability semantics, which violates the current clean separation between Tess (decisions) and the runner (lifecycle management).

### Weaknesses

**F11 (Significant) — The capability manifest's cost_profile is "informational, not enforced," but Tess uses it for cost-aware routing decisions (§8.3).** If Tess selects a skill based on manifest cost_profile and the actual cost is 3× higher (because the manifest was written for "standard rigor" and the brief requests "deep rigor"), the budget enforcement catches it *after* the dispatch starts — but the routing decision was already wrong. The learning log superseding the manifest after ≥3 data points helps, but only for skill+rigor combinations that have been tried before. New skills or unusual rigor profiles still rely on potentially misleading manifests. Suggestion: the manifest's cost_profile should include rigor-specific ranges (light/standard/deep) rather than a single range, since rigor is the primary cost driver.

**F12 (Minor) — The quality_signals declaration (§2.1) enables adaptive quality gates but doesn't address versioning.** If a skill adds a new quality signal in an update (e.g., `factual_accuracy: true`), Tess needs to know that this signal wasn't available in earlier versions of the skill's output. Without versioning, Tess might try to check `factual_accuracy` on an artifact produced by the old skill version and fail. This is a minor concern for now (skills are updated by Danny, not hot-swapped), but worth noting as a "revisit if this breaks" item.

---

## 5. Dependency Validation

I checked the cross-project dependencies claimed in the spec against actual project states.

| Dependency | Claimed State | Actual State | Assessment |
|---|---|---|---|
| researcher-skill M5 | "M5 is complete" (run-log amendment) | Confirmed: 15/15 tasks, M6 deferred | ✓ Correct |
| FIF M2 | "FIF M2 closed" (Workflow 1 dep) | FIF-029 passed, M3 now complete (FIF-033 done) | ✓ Better than claimed — M3 is done |
| crumb-tess-bridge | "DONE" | Confirmed: 37 tasks, 897 tests, operational | ✓ Correct |
| TOP-009 (morning briefing) | "operational" | Confirmed: done in tasks.md | ✓ Correct |
| TOP-049 (Approval Contract) | "prerequisite for Tier 2" | Status: pending, depends on TOP-002 + TOP-014 | ⚠ Not yet built — Workflow 4 + Phase 3 correctly gated |
| TOP-027 (calendar integration) | "prerequisite for Workflow 3" | Status: pending, depends on TOP-016/017 | ⚠ Not yet built — correctly gated in Phase 3 |
| TOP-053 (awareness-check) | "operational" | Done, but with known issues (exec tool access unconfirmed, Telegram delivery unconfirmed) | ⚠ "Operational" is generous — deployed with caveats |
| TOP-014 (gate evaluation) | Implicit dependency | Status: pending | ⚠ M1 gate not yet passed — TOP-049 blocked on this |

**F13 (Significant) — The dependency chain to Phase 3 is deeper than the spec implies.** Workflow 3 requires TOP-027 (calendar) → TOP-016/017 (Google integration infra) → TOP-014 (M1 gate pass) → M0+M1 operational. And TOP-049 (Approval Contract) → TOP-014 → M0+M1. This means Phase 3 is gated on the entire tess-operations M1 gate passing, then M2 completing (Google integration), then M3 completing (calendar + email), then M4 starting (approval contract). That's potentially months of tess-operations work before Phase 3 can begin. The spec's effort estimates for Phase 3 ("1-2 sessions" for multi-dispatch, "2-3 sessions" for Workflow 3) are accurate for the A2A work itself, but the calendar suggests Phase 3 is a Q3 2026 target at earliest, not a "next month" target. This isn't necessarily a problem — the phased build order is correct — but the spec should be more explicit about the real timeline so expectations are calibrated.

---

## 6. Open Questions Assessment

The spec identifies 10 open questions (§13). My assessment of each:

**Q1 (Orchestration logic location):** The recommendation is sound — discrete skill invocations called by crons, not logic embedded in the crons. The "monolith awareness-check" failure mode is real and the spec correctly names it.

**Q2 (Compound insight noise ceiling):** 5/day is a reasonable starting guess. The feedback signal mechanism provides the calibration path. No issue.

**Q3 (Context refresh frequency):** See F9 above — this needs more thought for time-sensitive workflows.

**Q4 (Multi-dispatch concurrency limit):** See F8 above — the real constraint is likely sequential, not parallel. The limit of 3 per group still makes sense (it bounds the number of sequential dispatches in a chain), but the framing should change.

**Q5 (Critic skill invocation threshold):** The starting proposal (deep rigor, customer-facing, or explicit request) is reasonable. The risk is under-invocation rather than over-invocation — the threshold should err toward invoking the critic and then relaxing based on feedback data.

**Q6 (Cross-project dependency graph):** Start inferred. The current project-state.yaml files already carry enough cross-references for basic dependency detection.

**Q7 (Proactive scaffolding approval):** Tier 2 (Approval Contract) is correct. Creating project directories is a structural vault change with non-trivial implications (it shows up in project listings, affects audit scans, etc.).

**Q8 (Semantic dedup):** Deferring is correct. The exact wikilink pair matching is a solid starting mechanism.

**Q9 (Sonnet call volume):** See F1 above — I'd recommend starting with Sonnet for the judgment calls rather than defaulting to Haiku.

**Q10 (Entity resolution):** Deferring is correct. See F7 for a concrete trigger mechanism.

---

## 7. Convergent Observations

A few observations that cut across sections:

**The spec's greatest risk is Tess's judgment quality, not infrastructure.** Every workflow depends on Tess making good decisions: which items are worth compound insights, what goes in a research brief, when to escalate vs. auto-resolve, how to merge parallel dispatch results. If Tess's judgment is weak (because Haiku lacks the capacity, or because her context is stale, or because the learning log hasn't accumulated enough patterns), the entire system produces confident-looking garbage. The spec's gate evaluation mechanism is the right safety net — but the gates only catch problems if Danny is vigilant about 👎 signals during the evaluation period. Consider adding a "shadow mode" option for Workflow 1 where Tess produces compound insights but delivers them as a daily batch for Danny to review, rather than as individual Telegram notifications. This produces gate-quality data without the notification fatigue.

**The proactive awareness guardrail (§9.3) is one of the best ideas in the spec.** The 50% signal-to-noise test with mechanical measurement via feedback signals is exactly the right guard against the "helpful assistant that generates noise" failure mode. Every proactive capability proposal in the future should be measured against this bar.

**The exclusions list (§14) should be a living document.** It currently captures the correct exclusions as of today. As the system matures, the temptation to add message buses, capability negotiation, and self-evolving workflows will return. The exclusions list should be periodically reviewed — not to add items, but to confirm that the reasons for excluding them still hold.

---

## 8. Findings Summary

### Critical (address before PLAN phase)

| ID | Finding | Section | Recommendation |
|---|---|---|---|
| F1 | Tess's orchestration capacity for Workflow 1 judgment calls needs A/B validation, not just Haiku default | §11.2, §5.1 | Run Haiku vs Sonnet comparison as first gate activity |
| F8 | Multi-dispatch is sequential (Claude Code is single-threaded), not parallel — design implications | §3.1 | Reframe §3.1 as sequential-dispatch-with-shared-context; update Workflow 3 timing expectations |

### Significant (track during PLAN, resolve before implementation)

| ID | Finding | Section | Recommendation |
|---|---|---|---|
| F2 | Dispatch learning log pattern_note inference is weak on qualitative issues | §3.5 | Generalize the ✏️ → "What was missing?" pattern from Workflow 3 to all workflows |
| F3 | "Single-dispatch rule 12" may not exist as described — verify against CTB implementation | §3.1 | Audit actual CTB lockfile semantics before designing dispatch groups |
| F4 | Confidence-based escalation override lacks calibration mechanism | §4.2 | Start with N-entries heuristic; calibrate during gate |
| F5 | Workflow 1 threshold language assumes continuous scores; FIF uses tier classification | §5.1 | Replace score-based threshold with tier-based selection criteria |
| F6 | Quality gate references to researcher-skill outputs need format validation | §6.1 | Verify RS-008 writing validation output structure against gate expectations |
| F9 | Mid-day context staleness unaddressed for time-sensitive workflows | §3.2 | Add lightweight context refresh for Workflow 3 before brief formulation |
| F11 | Capability manifest cost_profile should be rigor-specific | §8.6 | Add light/standard/deep ranges to cost_profile |
| F13 | Phase 3 real timeline is much longer than effort estimates suggest | §12 | Add realistic calendar timeline alongside session-effort estimates |

### Minor (note for future reference)

| ID | Finding | Section | Recommendation |
|---|---|---|---|
| F7 | Entity resolution trigger is vague | §5.4 | Add wikilink-variant count to vault-check as mechanical trigger |
| F10 | Dispatch learning log needs pruning policy | §3.5 | Archive entries > 90 days |
| F12 | Quality signal versioning not addressed | §8.6 | Track as "revisit if this breaks" |

---

## 9. Process Observations

The project creation and SPECIFY phase followed proper workflow. The input spec synthesis (8 sources, explicit convergence/divergence analysis, Appendix A) is unusually thorough. The systems-analyst skill was applied correctly — the run-log shows a proper context inventory (7 docs, extended tier), overlay check, and key findings that changed the spec materially (researcher-skill M5 completion promoting Workflow 2).

Danny's skill-plugin-architecture design note is a good example of architectural thinking arriving at the right time — during specification, before the build order was locked. The gap resolution pattern (5 gaps identified, all resolved in one round) worked cleanly.

One process note: the input spec's frontmatter says `type: specification` and `status: draft`, but its actual role (per the run-log) is "research/synthesis material to inform the SPECIFY phase — not the specification itself." The frontmatter type should be `research` or `input-spec` to avoid confusion with the actual `specification.md`. This is a minor hygiene item but matters for vault-check consistency and for future sessions that might load this file thinking it's the authoritative spec.

---

## 10. Recommendation

**Advance to PLAN phase** after addressing:
1. F1 and F8 (critical) — these change the design of key components
2. F3 — verify the single-dispatch constraint exists as claimed before designing around it
3. F5 — align Workflow 1 trigger language with FIF's actual output format

The remaining significant findings can be tracked as open items in the action plan and resolved during task decomposition.

The specification is ambitious in the right ways and restrained in the right ways. The phased build order, gate evaluations, and feedback infrastructure provide the scaffolding to course-correct as reality diverges from the plan. Ship Workflow 1, learn from it, then decide how much of the rest to build.
