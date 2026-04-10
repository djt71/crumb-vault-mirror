---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/opportunity-scout/design/action-plan.md
artifact_type: action-plan
artifact_hash: 673f4ea3
prompt_hash: c3764975
base_ref: null
project: opportunity-scout
domain: software
skill_origin: peer-review
created: 2026-03-14
updated: 2026-03-14
reviewers:
  - openai/gpt-5.4
  - google/gemini-3.1-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 46198
    attempts: 1
    raw_json: Projects/opportunity-scout/reviews/raw/2026-03-14-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 44869
    attempts: 1
    raw_json: Projects/opportunity-scout/reviews/raw/2026-03-14-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 177995
    attempts: 1
    raw_json: Projects/opportunity-scout/reviews/raw/2026-03-14-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 28320
    attempts: 1
    raw_json: Projects/opportunity-scout/reviews/raw/2026-03-14-action-plan-grok.json
tags:
  - review
  - peer-review
status: complete
---

# Peer Review: Opportunity Scout Action Plan

**Artifact:** Projects/opportunity-scout/design/action-plan.md + Projects/opportunity-scout/tasks.md
**Mode:** full
**Reviewed:** 2026-03-14
**Reviewers:** OpenAI gpt-5.4, Google gemini-3.1-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning
**Review prompt:** Structured review of action plan and task decomposition — evaluating task scoping, dependency correctness, risk calibration, acceptance criteria quality, coverage, and sequencing.

---

## OpenAI (gpt-5.4)

Below is a structured review of the action plan and task decomposition.

## Overall assessment

This is a strong plan: milestones are coherent, the implementation path generally matches the stated system constraints, and the action plan is notably risk-aware around behavioral adoption and first-live cron iteration. The decomposition is mostly good, but there are a few significant dependency and scoping issues, plus several acceptance criteria that are not fully binary/testable as written.

---

## Findings

### F1
- **Severity**: SIGNIFICANT
- **Finding**: **OSC-010 is under-scoped and likely exceeds the intended atomicity / “<=5 file changes” constraint.** It combines batch ranking, insight generation, template rendering, Telegram delivery, SQLite digest mapping writes, and vault archival/suppression handling.
- **Why**: That is multiple separable concerns across likely many files/modules: ranking prompt, digest renderer, Telegram API client, persistence layer, archival path, and suppression logic. This makes the task hard to implement, test, and iterate independently.
- **Fix**: Split OSC-010 into at least 3 tasks:
  1. digest assembly + ranking,
  2. Telegram delivery + digest mapping persistence,
  3. archival/suppression behavior.

### F2
- **Severity**: SIGNIFICANT
- **Finding**: **OSC-012 is also too broad for an atomic task.** It includes orchestration, idempotency, run IDs, daily digest locking, LaunchAgent setup, multi-model invocation, and fault isolation.
- **Why**: This is one of the highest-risk tasks and is explicitly expected to need 3–6 iteration rounds. Bundling all orchestration concerns into one task makes acceptance harder and obscures which part failed.
- **Fix**: Split OSC-012 into:
  1. pipeline script with run IDs + stage ordering,
  2. idempotency + digest lock,
  3. LaunchAgent/plist setup,
  4. fault isolation and logging validation.

### F3
- **Severity**: SIGNIFICANT
- **Finding**: **OSC-013 is oversized.** It includes transport choice, parsing, command handling, digest mapping, reply resolution, throttles, acknowledgements, and URL ingestion via `scout-add`.
- **Why**: This is effectively a mini product surface by itself. It likely spans parser code, Telegram integration, state transition logic, throttling logic, and candidate creation. Too much is hidden behind one task.
- **Fix**: Split into:
  1. inbound Telegram polling/webhook + parsing,
  2. digest/reply resolution + state update commands,
  3. throttles + `scout-add` + acknowledgement behaviors.

### F4
- **Severity**: SIGNIFICANT
- **Finding**: **OSC-003 acceptance criteria are not fully binary because “working ingestion path” is loosely defined.**
- **Why**: A source can have a URL and parser config yet still fail in live ingest. “Working ingestion path” needs a concrete test outcome.
- **Fix**: Amend AC to require a recorded validation result per source, e.g. “each source successfully returns at least one normalized item in a dry-run adapter test or is explicitly marked inactive.”

### F5
- **Severity**: SIGNIFICANT
- **Finding**: **OSC-007 AC uses “deterministic rubric” and agreement ≥85%, but does not define the agreement calculation method.**
- **Why**: Agreement could mean exact match across all 3 gates, per-gate average agreement, Cohen’s kappa, etc. Without a defined metric, pass/fail is disputable.
- **Fix**: Specify the metric, e.g. “agreement = exact match on all 3 gate labels per item across 50 items; pass if ≥43/50 items match exactly.”

### F6
- **Severity**: SIGNIFICANT
- **Finding**: **OSC-010 depends on OSC-007 and OSC-008, but appears to also need OSC-009 completion.**
- **Why**: M0’s stated exit gate is that the end-to-end ingest→score→store pipeline is validated before building delivery on top. Delivering digests before confirming M0 integration contradicts the milestone logic and introduces avoidable debugging ambiguity.
- **Fix**: Add **OSC-009** as a dependency of **OSC-010**.

### F7
- **Severity**: SIGNIFICANT
- **Finding**: **OSC-012 should likely depend on OSC-011 if weekly heartbeat and failure alerts are considered part of the orchestration soak gate.**
- **Why**: The M1 success criteria and OSC-014 soak explicitly validate heartbeat delivery and alerts, but OSC-014 currently depends only on OSC-012 and OSC-013. That implies soak could begin without OSC-011 complete.
- **Fix**: Add **OSC-011** as a dependency of **OSC-014**. Optionally also clarify whether OSC-012 itself depends on OSC-011 or whether heartbeat/alerts are additive validation only.

### F8
- **Severity**: SIGNIFICANT
- **Finding**: **There is a milestone/task inconsistency around M1’s “working feedback commands.”** The M1 goal says delivery with working feedback commands, but OSC-013 is not on the critical path shown in the overview.
- **Why**: If feedback commands are part of M1 exit criteria, they are part of the practical critical path to M1 completion.
- **Fix**: Update the critical path statement to include **OSC-013** before **OSC-014**, or explicitly state that the listed path is for delivery readiness only and not full M1 completion.

### F9
- **Severity**: SIGNIFICANT
- **Finding**: **OSC-005 unnecessarily depends on OSC-004 implementation, not just the adapter interface contract.**
- **Why**: HN adapter work should depend on a shared adapter contract, but not necessarily on completing the RSS adapter implementation. Current dependency reduces possible parallelism.
- **Fix**: Split OSC-004 into:
  - interface contract definition,
  - RSS adapter implementation.
  Then let OSC-005 depend only on the interface contract (+ OSC-003 if source registry details are needed).

### F10
- **Severity**: SIGNIFICANT
- **Finding**: **OSC-010 may be missing a dependency on OSC-009 or on live adapter outputs for realistic digest assembly testing.**
- **Why**: Ranking and rendering should operate on actual triage-passing candidate records, not only mocked candidates, if the task is to validate first digest production.
- **Fix**: Same as F6: add **OSC-009** dependency, or explicitly state mock-fixture-based testing is acceptable for OSC-010 and reserve live validation for OSC-012/014.

### F11
- **Severity**: SIGNIFICANT
- **Finding**: **OSC-013 acceptance criteria include latency ≤30s, but there is no defined measurement method or test condition.**
- **Why**: Latency claims need a measurable start and end point: message receipt to acknowledgement? under what transport mode? averaged over how many trials?
- **Fix**: Specify, e.g. “For polling mode, median time from Telegram update receipt to acknowledgement send is ≤30s over 10 test commands.”

### F12
- **Severity**: SIGNIFICANT
- **Finding**: **OSC-014 AC contains “no error alerts fired (or all were legitimate + handled),” which is not binary as written.**
- **Why**: This is subjective and collapses two different outcomes into one vague condition.
- **Fix**: Rewrite as:
  - “No false-positive alerts fired,” and
  - “Any true-positive alerts generated during the test were acknowledged and resolved per run log.”

### F13
- **Severity**: SIGNIFICANT
- **Finding**: **OSC-015 mixes a 21-day validation window with a 30-day abort criterion in one task, which weakens the task boundary.**
- **Why**: A 21-day gate cannot conclusively evaluate a 30-day abort threshold unless the task remains open beyond the stated window. This creates ambiguity about when OSC-015 is complete.
- **Fix**: Split into:
  1. 21-day behavioral validation task,
  2. 30-day abort check / decision task,
  or redefine OSC-015 as a 30-day evaluation task.

### F14
- **Severity**: SIGNIFICANT
- **Finding**: **Coverage gap: no explicit task for configuration/secrets management despite direct Telegram Bot API and likely model/API credentials.**
- **Why**: Real implementation will require bot token, model credentials, and probably environment/config loading. Without explicit handling, setup becomes ad hoc and brittle.
- **Fix**: Add a task or subtask for env/config scaffolding: token storage, required env vars, `.env.example` or equivalent, and startup validation.

### F15
- **Severity**: SIGNIFICANT
- **Finding**: **Coverage gap: no explicit observability/logging artifact beyond ad hoc references in orchestration and alerts.**
- **Why**: Given the emphasis on unattended cron/LaunchAgent operation and iteration during first deployment, structured logs and run records are essential to debug duplicates, source failures, and parser issues.
- **Fix**: Add explicit acceptance criteria in OSC-012 for per-stage logs and persisted run metadata, or create a dedicated logging/run-history task.

### F16
- **Severity**: MINOR
- **Finding**: **OSC-002 AC says “npm test or equivalent passes schema validation,” but the stack does not appear inherently Node-specific.**
- **Why**: This introduces avoidable ambiguity about tooling in what seems to be a mixed bash/SQLite/CLI architecture.
- **Fix**: Replace with stack-neutral language such as “schema validation test command passes.”

### F17
- **Severity**: MINOR
- **Finding**: **OSC-003 depends on OSC-002, but source research itself could begin before DB initialization.**
- **Why**: This is not wrong, but it is a slight sequencing inefficiency if the team wants more parallelism.
- **Fix**: If desired, split “research sources” from “populate registry” so source discovery can start immediately and DB insertion waits on OSC-002.

### F18
- **Severity**: MINOR
- **Finding**: **OSC-011 bundles Discord mirror, weekly heartbeat, and failure alerting; these are adjacent but separable concerns.**
- **Why**: It is not as oversized as OSC-010/012/013, but still combines multiple delivery channels and notification modes.
- **Fix**: Consider splitting failure alerting from weekly heartbeat/mirror if keeping strict atomicity.

### F19
- **Severity**: MINOR
- **Finding**: **The action plan references “all 4 data contracts,” but the contracts are not named in the overview section.**
- **Why**: This slightly reduces readability for reviewers skimming the plan without the task table.
- **Fix**: In M0 Phase 1, list the four contracts explicitly: source registry, candidate records, digest mapping, graveyard.

### F20
- **Severity**: MINOR
- **Finding**: **OSC-018 has no dependency, though practically its design quality may benefit from waiting for OSC-015/016 feedback data.**
- **Why**: It is valid as independent design work, but if the interface is meant to reflect real feedback loop needs, early design may be premature.
- **Fix**: Either keep as-is and note it is speculative design, or add optional dependency on OSC-016 for data-informed design.

### F21
- **Severity**: STRENGTH
- **Finding**: **The milestone structure is coherent and maps well to actual operational risk: M0 data validity, M1 reliability, M2 behavior, M3 reporting.**
- **Why**: This is a good decomposition of technical readiness versus user adoption risk, and prevents premature optimization.
- **Fix**: None.

### F22
- **Severity**: STRENGTH
- **Finding**: **The plan correctly centers behavioral adoption as the existential risk and places an explicit abort gate in M2.**
- **Why**: This prevents overbuilding a system that may not be used, which is exactly the right risk framing for personal automation products.
- **Fix**: None.

### F23
- **Severity**: STRENGTH
- **Finding**: **The use of end-to-end integration at M0 before delivery work is a strong sequencing choice.**
- **Why**: It forces validation of ingestion/scoring/storage before adding channels and feedback complexity.
- **Fix**: Reinforce this by making OSC-009 a formal dependency of OSC-010.

### F24
- **Severity**: STRENGTH
- **Finding**: **Acceptance criteria are generally much stronger than average: many include exact counts, state transitions, and explicit edge cases.**
- **Why**: This makes implementation reviewable and reduces hand-wavy completion claims.
- **Fix**: None; just tighten the few remaining vague metrics.

### F25
- **Severity**: STRENGTH
- **Finding**: **The plan respects the stated architectural constraints: cron/LaunchAgent orchestration, direct Telegram Bot API, and SQLite registry.**
- **Why**: This indicates good fidelity to the approved specification and avoids drift into alternate implementation styles.
- **Fix**: None.

### F26
- **Severity**: SIGNIFICANT
- **Finding**: **UNVERIFIABLE CLAIM: “Estimated 3–6 iteration rounds on first live deployment of the cron pipeline (per claude-print automation Pattern 4).”**
- **Why**: This references an internal or external pattern/framework that cannot be independently verified from the provided artifact.
- **Fix**: Add a citation, internal reference, or note that this is a heuristic estimate from prior project experience.

### F27
- **Severity**: SIGNIFICANT
- **Finding**: **UNVERIFIABLE CLAIM: “Multi-model invocation confirmed working (AD-5 validation).”**
- **Why**: “AD-5” is a reference to an external artifact not included here.
- **Fix**: Link or cite the underlying decision/spec item, or replace with plain-language validation criteria.

### F28
- **Severity**: SIGNIFICANT
- **Finding**: **UNVERIFIABLE CLAIM: “weekly health heartbeat via Telegram Bot API (AD-9).”**
- **Why**: “AD-9” cannot be checked from the provided text.
- **Fix**: Provide a citation or inline summary of the referenced requirement.

### F29
- **Severity**: SIGNIFICANT
- **Finding**: **UNVERIFIABLE CLAIM: “Validate multi-model invocation (Haiku triage via OpenClaw, Sonnet digest via claude --print).”**
- **Why**: The toolchain specifics and invocation contracts are external assumptions not independently verifiable from this artifact.
- **Fix**: Add implementation notes or references to the validated command contracts.

### F30
- **Severity**: SIGNIFICANT
- **Finding**: **UNVERIFIABLE CLAIM: “per claude-print automation Pattern 4” and “consistently needs prompt-model contract calibration that tests can't catch.”**
- **Why**: This is a generalized empirical claim with no source in the artifact.
- **Fix**: Mark as team heuristic or cite prior internal runs/projects.

---

## Answers by requested review dimension

## 1. Task scoping
- **Mostly good in M0 and M2–M3.**
- **Too broad**: OSC-010, OSC-012, OSC-013.
- **Slightly broad**: OSC-011.
- **Potentially too narrow**: none seriously; OSC-018 is intentionally design-only and acceptable.

## 2. Dependency correctness
Key issues:
- **Missing dependency**: OSC-010 should depend on **OSC-009**.
- **Missing dependency**: OSC-014 should depend on **OSC-011** if heartbeat/failure alerts are part of soak validation.
- **Over-constrained dependency**: OSC-005 should not need full OSC-004 implementation if only the adapter contract is required.
- No obvious circular dependencies.

## 3. Risk calibration
- **Under-rated**:
  - OSC-010 should likely be **medium**, not low.
  - OSC-011 could be **medium** if failure alerts are relied upon operationally.
- **Correctly high**:
  - OSC-012 high is appropriate.
  - OSC-015 high is appropriate.
- **Reasonable**:
  - M0 implementation tasks mostly low/medium is fair.

## 4. Acceptance criteria quality
Strong overall, but these need tightening:
- OSC-003 “working ingestion path”
- OSC-007 agreement definition
- OSC-010 “key insights are specific”
- OSC-013 latency measurement
- OSC-014 “no error alerts fired (or all were legitimate + handled)”
- OSC-015 mixes 21-day and 30-day criteria

## 5. Coverage
Mostly complete for the described spec. Main likely gaps:
- configuration/secrets management
- logging/run observability
- perhaps explicit migration/versioning strategy for SQLite schema if ongoing evolution is expected

## 6. Sequencing
Generally strong. Best improvements:
- Make OSC-009 gate OSC-010.
- Add OSC-011 before OSC-014 if soak includes heartbeat/alert validation.
- Increase parallelism by separating adapter contract from RSS implementation so HN work can start earlier.
- Optionally let source research begin before DB population.

---

## Recommended top fixes before execution

1. **Split OSC-010 / 012 / 013** into smaller atomic tasks.
2. **Add OSC-009 as dependency of OSC-010.**
3. **Add OSC-011 as dependency of OSC-014.**
4. **Refine ACs for OSC-003, 007, 013, 014, 015** to be strictly binary.
5. **Add explicit config/secrets and logging/run-history coverage.**
6. **Clarify the critical path to include OSC-013** if M1 requires working feedback commands.

If you want, I can also convert this review into a concise redline version of the task list with exact dependency/AC edits.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of the Opportunity Scout action plan, evaluating scoping, dependencies, risk, and criteria against your specified constraints.

- [F1]
- [SIGNIFICANT]
- UNVERIFIABLE CLAIM: Reference to "claude-print automation Pattern 4".
- [Why]: The overview cites this specific automation pattern to justify budgeting 3-6 iteration rounds. Without independent verification of this pattern's definitions or guidelines, the iteration budget cannot be validated against external best practices.
- [Fix]: Provide a direct link/reference to the "claude-print automation Pattern 4" documentation or explicitly summarize its iteration principles within the action plan.

- [F2]
- [SIGNIFICANT]
- UNVERIFIABLE CLAIM: References to internal/historical artifacts and acronyms: "U5 (research brief v0.5)", "AD-5", "AD-9", "FIF adapter pattern", and "v1–v7 research dispatches". 
- [Why]: These look like specific issue tracker IDs, architecture decision records, or private repository files. Reviewers cannot independently verify their existence, state, or contents to ensure they satisfy task prerequisites.
- [Fix]: Provide brief inline definitions for these acronyms/IDs or verify they are strictly locally available context that the implementing agent will have access to. 

- [F3]
- [CRITICAL]
- Conflict between OSC-013 Acceptance Criteria ("Latency ≤30s") and the strict constraint to use "dedicated cron jobs".
- [Why]: Standard `cron` has a minimum execution resolution of 1 minute. A polling script (`getUpdates`) running via cron cannot guarantee ≤30s latency without utilizing a long-running persistent daemon or a 60-second sleep loop inside the script. A persistent daemon violates the core cron constraint.
- [Fix]: Relax the AC in OSC-013 to "Latency ≤60s" (aligning with standard cron execution limits), or explicitly design/document the cron job to run a bounded sleep loop (`watch` or `sleep 30`) that exits cleanly before the next minute's cron fires.

- [F4]
- [SIGNIFICANT]
- Task scoping for OSC-012 and OSC-013 is too broad and likely violates the "≤5 file changes" atomic task guideline.
- [Why]: OSC-013 requires implementing API polling, parsing 5 different commands, mapping resolution, reply resolution, throttle enforcement, and state management. OSC-012 requires building an idempotent bash orchestrator, handling run IDs, locks, error isolation, and LaunchAgent configuration. Both are massive subsystems bundled into single tasks.
- [Fix]: Split OSC-013 into `OSC-013a` (Polling core, mapping resolution, reply resolution) and `OSC-013b` (Command execution, throttle enforcement, state updates). Split OSC-012 into `OSC-012a` (Core pipeline script + LaunchAgent) and `OSC-012b` (Idempotency, run IDs, and error isolation).

- [F5]
- [SIGNIFICANT]
- Risk level for OSC-013 is underrated (marked `medium`, should be `high`).
- [Why]: Implementing a stateless Telegram `getUpdates` polling mechanism via cron is notoriously fragile. It requires perfect offset management (`update_id`) to avoid processing the same commands repeatedly or dropping them if the script crashes. Furthermore, the overview explicitly notes OSC-013 will require "3-6 iteration rounds," which naturally implies a high-risk implementation.
- [Fix]: Elevate OSC-013 risk to `high`.

- [F6]
- [MINOR]
- OSC-005 (HN Adapter) unnecessarily depends on OSC-004 (RSS Adapter).
- [Why]: Both are independent adapters pulling from different sources but writing to the same normalized interface. They do not have a technical dependency on each other and blocking OSC-005 creates an unnecessary sequential bottleneck in Phase 2.
- [Fix]: Change OSC-005 dependencies to `OSC-002, OSC-003` (the same as OSC-004) and note in the Phase 2 description that adapter implementations can be parallelized.

- [F7]
- [MINOR]
- OSC-010 (Digest assembly) depends on M0 sub-tasks (OSC-007, OSC-008) rather than the M0 Exit Gate (OSC-009).
- [Why]: The M0 Phase 4 integration test (OSC-009) is explicitly defined in Risk Note 1 as the first real validation point: *"Don't move to M1 until this passes."* Having OSC-010 depend on earlier tasks theoretically allows M1 development to start before the data pipeline is proven.
- [Fix]: Update the dependency for OSC-010 to strictly require `OSC-009`.

- [F8]
- [STRENGTH]
- Excellent risk calibration regarding behavioral adoption in OSC-015.
- [Why]: Recognizing that the primary risk is the user failing to adopt the scanning habit (and not a technical failure) is highly pragmatic. Hardcoding an absolute "ABORT" criterion (kill the project if <20% bookmark rate or <5 digests reviewed) prevents sunk-cost fallacy and perfectly addresses the project constraints.

- [F9]
- [STRENGTH]
- Strong structural use of gating and soak tests.
- [Why]: Isolating ingestion/scoring (M0) from delivery/formatting (M1) via OSC-009, and enforcing a 3-day unattended soak test (OSC-014) before commanding user attention, demonstrates exceptionally mature system architecture and protects the behavioral experiment from being ruined by technical flakiness.

---

## DeepSeek (deepseek-reasoner)

## Review of Opportunity Scout Action Plan & Task List

### Summary
The action plan is exceptionally well-structured, demonstrating clear systems thinking. Tasks are logically decomposed, dependencies are accurately mapped, and acceptance criteria are largely concrete and testable. The risk-informed sequencing shows mature project planning with appropriate behavioral guardrails. A few areas require clarification.

---

### Findings

**F1**
- **Severity**: MINOR
- **Finding**: Task OSC-012 ("Build bash pipeline orchestration script") appears overly broad for "≤5 file changes" scoping. It encompasses pipeline logic, run ID management, idempotency, LaunchAgent integration, error handling, and multi-model validation.
- **Why**: This task is the highest-risk implementation item (correctly noted) and its complexity could make estimation and review difficult. It's a potential single point of failure.
- **Fix**: Consider splitting into two tasks: OSC-012a (core pipeline script, idempotency, run IDs) and OSC-012b (LaunchAgent integration, error isolation, validation suite). Or, if kept as one, explicitly acknowledge it as the largest implementation chunk.

**F2**
- **Severity**: SIGNIFICANT
- **Finding**: Dependency OSC-005 (HN Adapter) → OSC-004 (RSS Adapter) may be overly restrictive. The dependency is described as porting an "FIF adapter pattern." If the interface contract (output schema) is defined in OSC-004, OSC-005 could theoretically start once that contract is defined, even before the RSS adapter is fully implemented.
- **Why**: This could delay the HN adapter workstream unnecessarily. Parallel development of adapters after interface definition is common.
- **Fix**: Modify OSC-005 dependency to `OSC-002, OSC-003` (needs schema and source config). Add a note: "Requires adapter interface contract defined in OSC-004 design phase, but can proceed with mock interface once defined."

**F3**
- **Severity**: MINOR
- **Finding**: Task OSC-011 ("Add Discord mirror...") has AC: "Pipeline failure triggers immediate alert to Telegram." This creates a hidden dependency on the alerting mechanism, which isn't mentioned in the task description or in preceding tasks (OSC-010, OSC-012).
- **Why**: Alerting is a distinct sub-feature. Its implementation details and failure modes should be considered.
- **Fix**: Clarify the AC or add a brief note in the OSC-011 description about implementing a simple alert (e.g., `curl` to Telegram API on pipeline error exit code).

**F4**
- **Severity**: SIGNIFICANT
- **Finding**: UNVERIFIABLE CLAIM: Multiple references to external/internal artifacts cannot be verified: "v1–v7 research dispatches", "U5 (research brief v0.5)", "FIF adapter pattern", "FIF inbox", "AD-5 validation", "AD-9", "claude-print automation Pattern 4", "Wisdom Library".
- **Why**: While these are likely internal project references, a reviewer outside the immediate context cannot assess their validity or existence. This is typical for project-specific plans but worth flagging.
- **Fix**: (For future external reviews) Provide a brief glossary linking these terms to known repositories, documents, or established patterns within the organization.

**F5**
- **Severity**: STRENGTH
- **Finding**: The acceptance criteria (AC) are overwhelmingly binary, specific, and measurable. Examples: "≥85% on test set", "PRAGMA journal_mode returns wal", "Latency ≤30s". This eliminates ambiguity for completion sign-off.
- **Why**: Excellent practice for reducing scope creep and ensuring objective task completion.

**F6**
- **Severity**: STRENGTH
- **Finding**: The plan incorporates critical behavioral and operational guardrails as explicit tasks/gates (M1 Soak Test, M2 21-day validation with ABORT criterion, M4 Steady State criteria). This aligns development success with user adoption, the project's primary risk.
- **Why**: It forces confrontation with the core value hypothesis early and prevents building a system nobody uses.

**F7**
- **Severity**: MINOR
- **Finding**: Task OSC-016 ("Implement source yield scoring...") has AC: "Scoring prompt updated if systematic miscalibration detected." This AC is less binary than others; "systematic miscalibration" is subjective.
- **Why**: Could lead to debate on whether the AC is met.
- **Fix**: Make it objective: "Scoring prompt updated if miscalibration is evidenced by [specific metric, e.g., feedback disagreement rate >X%] OR by explicit user directive."

**F8**
- **Severity**: SIGNIFICANT
- **Finding**: A potential coverage gap exists in data retention/archiving policy. Tasks cover archival of digests (OSC-010) but not the cleanup/rotation of raw ingested items, candidate records, or feedback logs. This could lead to database bloat over the 30-day+ operational period.
- **Why**: An operational system needs a data lifecycle plan.
- **Fix**: Add a note or subtask to OSC-012 (orchestration) or OSC-017 (monthly memo) defining/scheduling archival or cleanup of data older than N days.

**F9**
- **Severity**: STRENGTH
- **Finding**: Risk calibration is accurate and well-justified. High risk is assigned to the behavioral validation (OSC-015) and the complex orchestration (OSC-012), which are the project's technical and adoption pivots. Medium risks on integration points (OSC-009, OSC-013) are appropriate.
- **Why**: Shows realistic assessment of where the project can fail.

**F10**
- **Severity**: MINOR
- **Finding**: Sequencing is generally optimal. One minor parallelization opportunity: Task OSC-018 (Execute Mode interface *design*) has no dependencies and is slated for M3. This design work could be done in parallel with any phase after project kickoff, even during M0.
- **Why**: Early design work can inform implementation subtly and utilizes idle cycles.
- **Fix**: Note that OSC-018 can be started at any time after project inception, with finalization in M3.

---

### Overall Assessment
This is a **high-quality action plan**. It is thorough, logically sound, and exhibits strong project management discipline. The focus on measurable outcomes, behavioral gates, and risk-aware sequencing is exemplary. The findings above are primarily refinements, not fundamental flaws. The plan is ready for execution with the minor adjustments suggested.

---

## Grok (grok-4-1-fast-reasoning)

- **F1**
- **CRITICAL**
- **Finding**: Overview critical path states "OSC-004/005/008 (parallel)", but task table and Phase 2 description enforce sequential dependencies (OSC-004 dep OSC-003; OSC-005 dep OSC-004), blocking parallelism.
- **Why**: Creates contradictory sequencing guidance; implementers may follow table (delaying M0) or overview (causing build failures). Undermines the "partially parallel" claims in phases.
- **Fix**: Update table to make OSC-005 depend only on OSC-003 (not OSC-004, as HN adapter doesn't reuse RSS code). Revise Phase 2 to "parallel after OSC-003". Align overview.

- **F2**
- **CRITICAL**
- **Finding**: M2 success criteria and OSC-015 AC specify abort on "<20% bookmark/research rate after 30 days OR <5 digests in any 30-day period", but Phase 9/OSC-015 describe a "21-day validation window/soak".
- **Why**: Time periods mismatch (21 vs 30 days), risking premature pass/fail or extended wait; highest-risk gate (behavioral adoption) has unclear timing, could lead to incorrect project halt.
- **Fix**: Standardize to 30-day window everywhere. Rephrase OSC-015 to "30-day soak" with interim 21-day checkpoint metrics.

- **F3**
- **SIGNIFICANT**
- **Finding**: OSC-012 scoped too broadly: defines interface, implements full bash orchestration (scan/score/digest/deliver/archive), idempotency, run IDs, LaunchAgent plist, error isolation, multi-model validation — likely >5 file changes (script, plist, tests, prompts, models).
- **Why**: Violates atomic task principle (<=5 changes); high-risk task will overrun iterations (already budgeted 3-6 for it), delaying M1 soak and Danny's attention commitment.
- **Fix**: Split into OSC-012a (bash orchestration + idempotency), OSC-012b (LaunchAgent + error isolation/multi-model), with deps. Add sub-task table.

- **F4**
- **SIGNIFICANT**
- **Finding**: OSC-013 too broad: Telegram polling/webhook, command parsing (5 commands), mapping resolution, reply-to-message, state updates, throttles, ACKs — involves API setup, parser logic, DB queries, multiple handlers (>5 files).
- **Why**: Medium-risk but complex; pattern notes flag it for 3-6 iterations, but oversized task hides sub-risks like Bot API token handling or webhook reliability.
- **Fix**: Split to OSC-013a (polling + basic parsing/ACKs), OSC-013b (commands + mapping/throttles). Dep OSC-013b on 013a.

- **F5**
- **SIGNIFICANT**
- **Finding**: UNVERIFIABLE CLAIM: "Extract calibration data from v1–v7 research dispatches" (OSC-001), "20 items from FIF inbox" (OSC-006), "U5 (research brief v0.5)", "AD-5 validation", "AD-9", "claude-print automation Pattern 4".
- **Why**: No sources/links provided; cannot confirm existence/content of v1-v7, FIF, U5/AD refs, or Pattern 4 details. Blocks validation of calibration quality or iteration budget.
- **Fix**: Add links/paths (e.g., vault refs) or appendices with excerpts. Peer-review to confirm.

- **F6**
- **SIGNIFICANT**
- **Finding**: Coverage gap: No task for multi-model invocation setup (Haiku triage via OpenClaw, Sonnet via claude --print), despite M0 criteria requiring "Multi-model invocation confirmed working (AD-5 validation)" and OSC-012 validating it.
- **Why**: Critical path assumes it works; failure (e.g., API keys, OpenClaw config) halts M0 integration without explicit task, wasting iterations.
- **Fix**: Add OSC-002.5 (post-002): "Configure multi-model env (OpenClaw Haiku, claude Sonnet). Test invocation contracts (AD-5)."

- **F7**
- **SIGNIFICANT**
- **Finding**: OSC-010 AC "Key insights are specific to each item (not generic)" is subjective, not binary testable.
- **Why**: No objective metric (e.g., keyword overlap with item title/desc); reviewer judgment varies, fails "YES/NO answerable" standard.
- **Fix**: Change to "Each insight ≥50 chars, contains ≥1 unique entity from item title/desc (NER check). Manual review of 3 insights passes specificity."

- **F8**
- **SIGNIFICANT**
- **Finding**: Missing dep for OSC-010: Should depend on OSC-009 (M0 integration) to ensure registry has triage-passing items for digest testing.
- **Why**: AC assumes items exist; empty registry → untestable digest, false negative on delivery.
- **Fix**: Add OSC-009 to OSC-010 deps.

- **F9**
- **MINOR**
- **Finding**: Risk for OSC-009 (M0 integration test) rated "medium", but it's the "first real validation point" per notes, blocking all downstream.
- **Why**: Under-rated; integration failures (e.g., schema mismatches) are high-impact/ high-likelihood early on.
- **Fix**: Escalate to "high". Add AC: "Log coverage ≥90% of pipeline code exercised."

- **F10**
- **MINOR**
- **Finding**: OSC-003 AC ">=9 sources (>=3 per tier)", but M0 goal ">=3 RSS sources + HN API"; tiers undefined in artifact.
- **Why**: Ambiguous (what are tiers?); risks over-scoping research if tiers >3.
- **Fix**: Define tiers explicitly (e.g., "high-signal: AI/LLM; med: builder; low: creator") or reduce to ">=3 RSS + HN".

- **F11**
- **MINOR**
- **Finding**: Sequencing suboptimal: OSC-011 (Discord/heartbeat) seq after OSC-010, but could parallel as non-critical.
- **Why**: Delays M1 delivery validation; additive features shouldn't block Telegram core.
- **Fix**: Make OSC-011 dep only OSC-010 for delivery, parallel in Phase 5.

- **F12**
- **MINOR**
- **Finding**: OSC-017 AC "Evaluation took ≤30 minutes" — testable but attributes to Danny; not system-controlled.
- **Why**: External variance (Danny's speed); weakens binary AC.
- **Fix**: "System generates raw memo data in ≤5 min; full eval (with Danny input) ≤30 min logged."

- **F13**
- **STRENGTH**
- **Finding**: Dependencies mostly accurate and explicit (e.g., OSC-009 deps cover all upstream components).
- **Why**: Enables true parallelism (e.g., OSC-001/002); critical path traceable without cycles. Edge case: OSC-010 assumes populated DB (fixable dep).
- **Fix**: N/A

- **F14**
- **STRENGTH**
- **Finding**: Risk levels generally well-calibrated (high on orchestration/validate gates like OSC-012/015; low on research/infra).
- **Why**: Matches notes (e.g., Pattern 4 budgets iterations on high-risk); behavioral A1 risk elevated appropriately.
- **Fix**: N/A

- **F15**
- **STRENGTH**
- **Finding**: ACs mostly binary/measurable (e.g., ">=85% agreement", "WAL mode verified", ">=1 adjustment").
- **Why**: Quantified thresholds enable automated tests; distribution specs (e.g., OSC-006) prevent gaming.
- **Fix**: N/A

- **F16**
- **STRENGTH**
- **Finding**: Coverage comprehensive: 18 tasks map spec (4 data contracts, adapters, triage, delivery, feedback, calibration, monthly); M4 operational closes loop.
- **Why**: No obvious gaps post-F6; phases/milestones align tasks to goals/exits.
- **Fix**: N/A

- **F17**
- **MINOR**
- **Finding**: Task states all "todo" uniform; no progression tracking.
- **Why**: Static; hinders status at-a-glance in living doc.
- **Fix**: Add column for "Est Hours" or use GitHub issues for state.

- **F18**
- **SIGNIFICANT**
- **Finding**: No task/AC for Telegram Bot API setup (token, permissions, polling interval), despite direct API constraint.
- **Why**: Prerequisite for OSC-013/010/011; failures (e.g., bot not admin) block M1 without explicit coverage.
- **Fix**: Add OSC-009.5 (post-009): "Provision Telegram bot (token vaulted), verify getUpdates/Discord webhook."

- **F19**
- **MINOR**
- **Finding**: Overview estimates "3–6 iteration rounds on first live deployment" tied to "claude-print Pattern 4", but no task budgets effort.
- **Why**: Risks underestimating; pattern unverifiable (F5).
- **Fix**: Add per-task "Est Iterations" column (e.g., OSC-012: 3-4).

- **F20**
- **STRENGTH**
- **Finding**: Phasing/parallelism well-documented (e.g., M0 Phase 1 explicit parallel; notes flag risks like M0 integration gate).
- **Why**: Optimizes critical path; soak tests (M1-14, M2-15) validate reliability pre-Danny load.
- **Fix**: N/A

---

## Synthesis

### Consensus Findings

**1. OSC-012 (pipeline orchestration) is too broad** (OAI-F2, GEM-F4, DS-F1, GRK-F3)
All four reviewers independently flag this. It bundles pipeline logic, idempotency, run IDs, LaunchAgent setup, error isolation, and multi-model validation into one task that's already rated HIGH risk and expected to need 3-6 iterations. Split into 2 tasks.

**2. OSC-013 (feedback parser) is too broad** (OAI-F3, GEM-F4, GRK-F4)
Three reviewers flag this. It combines polling, 5 command types, digest mapping resolution, reply-to resolution, throttles, acknowledgements, and `/scout add` into one task. Split into 2 tasks.

**3. OSC-005 (HN adapter) dependency on OSC-004 (RSS adapter) is over-constrained** (OAI-F9, GEM-F6, DS-F2, GRK-F1)
All four reviewers flag this. HN adapter needs the adapter interface contract, not the completed RSS implementation. Current dependency blocks parallelism unnecessarily. Fix: OSC-005 depends on OSC-002 + OSC-003 + the interface contract from OSC-004's design phase.

**4. OSC-010 missing dependency on OSC-009** (OAI-F6, GEM-F7, GRK-F8)
Three reviewers flag this. The action plan explicitly states "Don't move to M1 until [OSC-009] passes" but OSC-010 doesn't depend on it. Fix: add OSC-009 as dependency.

**5. 21-day vs 30-day mismatch in OSC-015** (OAI-F13, GRK-F2)
OSC-015 describes a "21-day soak" but M2 abort criterion uses "30 days." Grok rates this CRITICAL. Fix: standardize to 30-day window with a 21-day interim checkpoint.

**6. Config/secrets management gap** (OAI-F14, GRK-F18)
No task covers Telegram bot provisioning, token storage, or API credential setup. Fix: add a task or fold into OSC-002.

### Unique Findings

**GEM-F3 (CRITICAL): Cron latency vs ≤30s AC** — *Genuine insight.* Standard cron has 1-minute resolution. The ≤30s feedback latency AC in OSC-013 is impossible with a cron-fired polling job unless using a persistent daemon or internal sleep loop. The feedback poller needs to be a long-running process (LaunchAgent with KeepAlive) or the AC needs to be relaxed to ≤60s. This is an architectural implication, not just an AC fix.

**OAI-F7: OSC-014 should depend on OSC-011** — *Valid.* The 3-day soak validates heartbeat and failure alerts, so OSC-011 must be complete first.

**OAI-F1: OSC-010 is too broad** — *Partially valid.* It combines digest assembly, Telegram delivery, mapping persistence, and suppression. However, these are tightly coupled (delivery writes the mapping rows, suppression gates delivery). If file count is ≤5, keeping it as one task is defensible. Worth monitoring during implementation but not splitting preemptively.

**DS-F8: Data retention/cleanup gap** — *Valid for operational sustainability.* No cleanup policy for raw ingested items or old digest mappings. Can be addressed as an AC note on OSC-012 rather than a separate task.

### Contradictions

No contradictions across reviewers. All agree on the three tasks that need splitting (OSC-012, OSC-013) and the dependency fixes (OSC-005→004, OSC-010→009). Minor disagreement on whether OSC-010 also needs splitting — only OpenAI flags it; others are silent or implicit.

### Action Items

#### Must-fix

| ID | Action | Source Findings |
|----|--------|----------------|
| A1 | **Split OSC-012** into OSC-012a (pipeline script + idempotency + run IDs) and OSC-012b (LaunchAgent + error isolation + multi-model validation) | OAI-F2, GEM-F4, DS-F1, GRK-F3 |
| A2 | **Split OSC-013** into OSC-013a (Telegram polling + basic command parsing + ACKs) and OSC-013b (digest mapping resolution + throttles + /scout add + state updates) | OAI-F3, GEM-F4, GRK-F4 |
| A3 | **Add OSC-009 as dependency of OSC-010** — M1 delivery must not start before M0 integration is validated | OAI-F6, GEM-F7, GRK-F8 |
| A4 | **Fix OSC-005 dependency** — depend on adapter interface contract (defined in OSC-004 design phase) + OSC-002/003, not full RSS implementation. Enable parallel adapter development | OAI-F9, GEM-F6, DS-F2, GRK-F1 |
| A5 | **Resolve 21/30-day mismatch in OSC-015** — standardize to 30-day validation window with 21-day interim checkpoint. Update M2 gate, OSC-015 description and AC | OAI-F13, GRK-F2 |

#### Should-fix

| ID | Action | Source Findings |
|----|--------|----------------|
| A6 | **Add config/secrets provisioning** to OSC-002 AC — Telegram bot token, API credentials, .env scaffolding, startup validation | OAI-F14, GRK-F18 |
| A7 | **Fix feedback latency architecture** — feedback poller must be a persistent process (LaunchAgent with KeepAlive), not a cron-fired script. Update OSC-013a description and AC accordingly. Relax AC to "≤60s" or design a long-running poller | GEM-F3 |
| A8 | **Add OSC-011 as dependency of OSC-014** — soak test validates heartbeat/alerts, which must be built first | OAI-F7 |
| A9 | **Tighten vague ACs**: OSC-003 "working ingestion path" → "each source returns ≥1 normalized item in dry-run test"; OSC-007 agreement → "exact match on all 3 gates, ≥43/50 items"; OSC-014 "no error alerts" → "no false-positive alerts; true-positives acknowledged in run log" | OAI-F4, OAI-F5, OAI-F12 |
| A10 | **Update critical path** in action plan overview to include OSC-013 before OSC-014 (feedback commands are M1 exit criteria) | OAI-F8 |
| A11 | **Add data retention note** to OSC-012 or OSC-017 — cleanup of raw ingested items and old digest mappings after N days | DS-F8 |

#### Defer

| ID | Action | Source Findings | Reason |
|----|--------|----------------|--------|
| A12 | Per-task effort/iteration estimates | GRK-F19, OAI-F16 | Premature; Pattern 4 budget covers the high-risk tasks |
| A13 | Separate logging/observability task | OAI-F15 | Address in OSC-012 AC instead of separate task |
| A14 | Multi-model env setup as separate task | GRK-F6 | Fold into OSC-012b (LaunchAgent + multi-model validation) |
| A15 | OSC-018 start-anytime note | DS-F10 | Cosmetic; doesn't affect execution |
| A16 | OSC-010 split | OAI-F1 | Monitor during implementation; file count is likely ≤5 |

### Considered and Declined

| Finding | Justification | Reason Category |
|---------|--------------|-----------------|
| All UNVERIFIABLE CLAIMs (OAI-F26–30, GEM-F1–2, DS-F4, GRK-F5) | Vault-internal references verifiable at runtime by the implementation agent | `constraint` |
| GRK-F9 (OSC-009 risk → high) | Medium is appropriate for integration test; doesn't have the iteration uncertainty of pipeline orchestration | `overkill` |
| GRK-F17 (states all "todo") | tasks.md is a living document; states update during implementation | `constraint` |
| GEM-F5 (OSC-013 risk → high) | Splitting into 013a/013b reduces per-task complexity; medium is appropriate for each half | `constraint` |
| GRK-F12 (OSC-017 "≤30 min" not system-controlled) | The AC measures the evaluation session, not just system generation; Danny's time is the constraint being validated | `incorrect` |
| OAI-F20 (OSC-018 dependency on OSC-016) | OSC-018 is design work that benefits from being unconstrained by implementation data; it's speculative by nature | `out-of-scope` |
