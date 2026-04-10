---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/openclaw-colocation/design/action-plan.md
artifact_type: architecture
artifact_hash: ebf6accb
prompt_hash: 0480678b
base_ref: null
project: openclaw-colocation
domain: software
skill_origin: peer-review
created: 2026-02-18
updated: 2026-02-18
reviewers:
  - openai/gpt-5.2
  - google/gemini-2.5-pro
  - perplexity/sonar-reasoning-pro
config_snapshot:
  curl_timeout: 120
  max_tokens_openai: 8192
  max_tokens_google: 8192
  max_tokens_perplexity: 65536
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 42208
    attempts: 1
    raw_json: Projects/openclaw-colocation/reviews/raw/2026-02-18-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 42876
    attempts: 2
    note: "gemini-3-pro-preview returned 503; fell back to gemini-2.5-pro"
    raw_json: Projects/openclaw-colocation/reviews/raw/2026-02-18-action-plan-google.json
  perplexity:
    http_status: 200
    latency_ms: 36285
    attempts: 1
    raw_json: Projects/openclaw-colocation/reviews/raw/2026-02-18-action-plan-perplexity.json
tags:
  - review
  - peer-review
---

# Peer Review: OpenClaw Colocation Action Plan

**Artifact:** `Projects/openclaw-colocation/design/action-plan.md`
**Mode:** Full
**Reviewed:** 2026-02-18
**Reviewers:** GPT-5.2, Gemini 2.5 Pro (3 Pro Preview unavailable), Sonar Reasoning Pro
**Review prompt:** Evaluate action plan for milestone decomposition correctness, dependency graph accuracy, risk calibration, feasibility, and gaps.

---

## OpenAI (GPT-5.2)

- [OAI-F1]
- [Severity]: SIGNIFICANT
- [Finding]: Milestone/task count and numbering are inconsistent (plan claims "4 milestones and 12 tasks," but lists OC-001..OC-012 with OC-007 done; also "Phase 3.5" skips 3.4).
- [Why]: Inconsistencies make execution tracking, dependency validation, and peer review harder; they also increase the chance of "phantom" work (unowned steps) during the migration.
- [Fix]: Normalize structure: either (a) explicitly list all OC-001..OC-012 (12 total) with OC-007 marked complete and clarify "11 remaining," or (b) renumber to the actual planned task count. Fix Phase numbering in Milestone 3 (add Phase 3.4 or renumber 3.5 → 3.4).

- [OAI-F2]
- [Severity]: SIGNIFICANT
- [Finding]: OC-005 (Node.js compatibility testing) is not clearly positioned as a hard prerequisite to OC-008 (installation), even though the dependency graph implies it feeds into install.
- [Why]: If Node/nvm coexistence has edge cases (PATH issues, shell init, LaunchAgent environment), discovering them after installation/hardening can cause rework and invalidate test results.
- [Fix]: Make OC-005 an explicit dependency of OC-008 in text (not just the diagram) and add acceptance criteria that specifically tests LaunchAgent environment (non-interactive shell) for the `openclaw` user.

- [OAI-F3]
- [Severity]: SIGNIFICANT
- [Finding]: The dependency between OC-003 (vault scaffold) and OC-010 (vault permissions) is not explicit.
- [Why]: Permissions work depends on `_openclaw/` existing (and on the intended subdirs like `outbox/.pending/`). Missing the explicit dependency increases the chance of misapplied ACLs/ownership or later corrections.
- [Fix]: Add "Depends on: OC-003" to OC-010, and add acceptance checks that verify permissions specifically on `_openclaw/`, `inbox/`, `outbox/`, and `outbox/.pending/`.

- [OAI-F4]
- [Severity]: SIGNIFICANT
- [Finding]: Acceptance criteria for several tasks are implicit rather than testable (notably OC-001, OC-008, OC-009, OC-010).
- [Why]: For a security-sensitive colocation, "done" needs objective verification to prevent drift between runbook, actual system state, and the isolation suite gate.
- [Fix]: Add explicit acceptance criteria per task, e.g.:
  - OC-008: LaunchAgent starts on login; `openclaw` runs under the `openclaw` UID; wrapper script path recorded; plist label recorded; logs location defined.
  - OC-009: `openclaw config show` (or equivalent) demonstrates loopback binding, workspaceOnly, pairing mode; browser disabled; stable channel set.
  - OC-010: `openclaw` can read vault, cannot write outside `_openclaw/`, and primary user cannot inadvertently write as `openclaw` (no shared credential files).

- [OAI-F5]
- [Severity]: CRITICAL
- [Finding]: LaunchAgent vs LaunchDaemon is flagged as a risk, but the plan doesn't include an explicit decision task with criteria (and it affects environment variables, startup behavior, and security posture).
- [Why]: This choice can change runtime privileges, headless operation, auto-start semantics, and where secrets live. Getting it wrong can break reliability or weaken isolation.
- [Fix]: Add a discrete task (e.g., OC-013 or fold into OC-008 with a named subtask) with decision criteria:
  - If interactive session required → LaunchAgent.
  - If must run without login → LaunchDaemon with tighter sandboxing and explicit environment management.
  Include a validation step: reboot test + verify process owner, ports, and log collection.

- [OAI-F6]
- [Severity]: SIGNIFICANT
- [Finding]: Isolation test suite (OC-011) is described but not clearly "productized" (where it lives, how it's run, and how results are recorded).
- [Why]: A go/no-go gate is only as strong as its repeatability. Manual, ad-hoc tests are easy to mis-run or incompletely record, reducing confidence.
- [Fix]: Define the test harness form: a script in a repo path (or a runbook section with exact commands) that outputs a timestamped report saved to a known location in the vault (outside `_openclaw/` if you don't want OpenClaw to write it). Add acceptance: "Test report artifact created and reviewed."

- [OAI-F7]
- [Severity]: SIGNIFICANT
- [Finding]: Vault permission model ("recursive group read on vault; write only to `_openclaw/`") is high-impact but lacks specifics about macOS permission mechanisms (POSIX perms vs ACLs) and edge cases (new files, inheritance, external drives, iCloud/Dropbox sync, Time Machine restores).
- [Why]: On macOS, achieving "read everywhere, write only here" for a secondary user often requires ACLs and careful inheritance; mistakes can silently grant broader write access or break Crumb workflows.
- [Fix]: In OC-010, specify the mechanism (recommended: ACLs with inheritance on `_openclaw/` and read-only elsewhere) and include edge-case checks.

- [OAI-F8]
- [Severity]: MINOR
- [Finding]: Milestone 2 success criteria mention "spec §9 is current" and "reference doc exists," but not that docs align (runbook/spec/reference must not contradict each other).
- [Why]: Divergent documentation is a common source of operational mistakes during migration and later maintenance.
- [Fix]: Add a lightweight doc-consistency check to OC-006 or OC-001.

- [OAI-F9]
- [Severity]: SIGNIFICANT
- [Finding]: Risk calibration likely understates Milestone 2 and over-simplifies Milestone 4 risks. M2 is "Low," but it produces the runbook that drives security-critical setup; M4 includes messaging + prompt-injection exposure which can be high-impact.
- [Why]: Mis-calibrated risk can lead to insufficient review rigor where it matters most.
- [Fix]: Adjust M2 to "Medium" and split M4 risks into "auth/operational complexity" and "external input threat."

- [OAI-F10]
- [Severity]: CRITICAL
- [Finding]: No explicit logging/monitoring/retention plan for OpenClaw on the Studio (where logs go, permissions, rotation, and whether logs could leak sensitive vault content).
- [Why]: Always-on agents can accumulate sensitive data in logs; without rotation/permissions, you risk disk bloat or inadvertent disclosure across users/processes.
- [Fix]: Add a task (or extend OC-008/OC-009) to define log locations, permissions, rotation, redaction guidance, and incident inspection procedures.

- [OAI-F11]
- [Severity]: SIGNIFICANT
- [Finding]: Backup and restore implications for the dedicated `openclaw` user are mentioned only generally; no concrete backup/restore test is included.
- [Why]: Recoverability is key for always-on services and security configs.
- [Fix]: Add a restore verification step to OC-001 and/or Milestone 3.

- [OAI-F12]
- [Severity]: MINOR
- [Finding]: Tier 2 hardening is "deferred — post-go-live," but acceptance criteria for M4 include "Tier 2 hardening items applied," which conflicts with the deferral note.
- [Why]: Conflicting acceptance criteria causes confusion about what "go-live" requires.
- [Fix]: Remove Tier 2 from M4 success criteria, or split into minimum subset vs. later.

- [OAI-F13]
- [Severity]: STRENGTH
- [Finding]: Clear security architecture: dedicated macOS user + defense-in-depth via workspace restrictions, plus an explicit go/no-go isolation gate.
- [Why]: OS-level isolation is robust and aligns well with a "colocated but separated" threat model.

- [OAI-F14]
- [Severity]: STRENGTH
- [Finding]: OC-009 and OC-010 correctly identified as parallelizable with a note about doctor checks potentially failing without permissions.
- [Why]: Anticipates a common integration pitfall and should reduce churn during Milestone 3.

---

## Google (Gemini 2.5 Pro)

- [GEM-F1]
- [Severity]: STRENGTH
- [Finding]: The plan pragmatically separates work that can be done on existing hardware (M1, M2) from work requiring the new Mac Studio (M3, M4).
- [Why]: Allows roughly half of the project work to be completed in parallel with hardware procurement, reducing overall timeline.

- [GEM-F2]
- [Severity]: MINOR
- [Finding]: Tier 2 Hardening lists "Gitignore review for `_openclaw/`" as a post-go-live activity, but OC-003 already establishes the .gitignore entry.
- [Why]: Contradicts the initial setup; deferring review implies the initial setup might be incomplete.
- [Fix]: Remove from Tier 2 list. Add verification to OC-003: `git status --ignored` confirms exclusion.

- [GEM-F3]
- [Severity]: MINOR
- [Finding]: The dependency graph shows OC-004 (spec §9) → OC-001 (runbook), but OC-001 integrates from the already-approved colocation spec, not from spec §9. They are parallel tasks drawing from the same source.
- [Why]: False dependency could block OC-001 unnecessarily if OC-004 is delayed.
- [Fix]: Remove the arrow from OC-004 to OC-001 in the dependency graph. Show OC-004 and OC-006 as a separate documentation track.

- [GEM-F4]
- [Severity]: STRENGTH
- [Finding]: The plan correctly identifies the parallel nature of OC-009 and OC-010 and explicitly notes a potential interaction where `openclaw doctor` depends on permissions being configured.
- [Why]: Shows high operational awareness and saves debugging time.

- [GEM-F5]
- [Severity]: SIGNIFICANT
- [Finding]: No explicit rollback or remediation procedure if OC-011 isolation tests fail.
- [Why]: A failure at the go/no-go gate could leave the system in an unknown, partially configured, potentially insecure state.
- [Fix]: Define and document a rollback procedure in OC-001: steps to safely remove the `openclaw` user, uninstall software, and revert vault permissions.

- [GEM-F6]
- [Severity]: MINOR
- [Finding]: OC-011 success criteria describe tests by category ("4 tests that MUST fail") but not by specific content.
- [Why]: Reduces self-containment; implementer must cross-reference the spec.
- [Fix]: Add brief one-line summary for each test in OC-011 description.

- [GEM-F7]
- [Severity]: SIGNIFICANT
- [Finding]: No system backup step before the significant changes in Milestone 3.
- [Why]: M3 involves creating users, installing system services, modifying permissions — non-trivial system modifications that should have a recovery point.
- [Fix]: Add mandatory step at beginning of M3: "Create a full, verified system backup/snapshot."

---

## Perplexity (Sonar Reasoning Pro)

- [PPLX-F1]
- [Severity]: CRITICAL
- [Finding]: `openclaw doctor` and `openclaw security audit --deep` are presented as go/no-go gates but do not appear in any current OpenClaw documentation.
- [Why]: If these tools don't exist or behave differently than specified, the isolation test protocol and hardening verification fail.
- [Fix]: Confirm with OpenClaw maintainers that these commands exist. If unavailable, substitute with manual verification steps.

- [PPLX-F2]
- [Severity]: SIGNIFICANT
- [Finding]: nvm compatibility with macOS user isolation is not documented or tested in the plan's scope.
- [Why]: PATH pollution, shell init order, and user-level nvm installations can cause subtle failures.
- [Fix]: Scope OC-005 to include documented nvm versions, isolated shell init, and fallback plan.

- [PPLX-F3]
- [Severity]: SIGNIFICANT
- [Finding]: M3 risk rated "Medium" but does not address known OpenClaw security vulnerabilities from enterprise sources (Jamf advisory on insider threat, persistence risks, API key exposure).
- [Why]: Understating risk may lead to insufficient security review depth.
- [Fix]: Upgrade M3 to "Medium-High" and explicitly note skill execution and API credential exposure as accepted residual risk.

- [PPLX-F4]
- [Severity]: SIGNIFICANT
- [Finding]: OC-009/OC-010 parallel creates potential race condition where `openclaw doctor` fails before permissions are set.
- [Why]: False go/no-go failure blocks M4 and creates confusing troubleshooting overhead.
- [Fix]: Make OC-010 a hard prerequisite of OC-009, or defer `openclaw doctor` until OC-010 is confirmed complete.

- [PPLX-F5]
- [Severity]: SIGNIFICANT
- [Finding]: Kill-switch dry-run acceptance criterion in OC-012 is vague ("executed successfully").
- [Why]: Without explicit criteria, the procedure may not work under actual emergency conditions.
- [Fix]: Define success as: stops gateway, revokes messaging credentials, restores baseline filesystem state within 5 minutes.

- [PPLX-F6]
- [Severity]: SIGNIFICANT
- [Finding]: No rollback procedures for any milestone. If OC-008 or OC-009 fails, no defined recovery path.
- [Why]: Failed go/no-go gate with no rollback creates ambiguity.
- [Fix]: Add "Failure Mode & Rollback" section to each milestone.

- [PPLX-F7]
- [Severity]: MINOR
- [Finding]: OC-002 is "optional" but positioned as a hard dependency of OC-001.
- [Why]: Soft dependencies create false impression of sequencing rigor.
- [Fix]: Clarify dependency as soft/optional.

- [PPLX-F8]
- [Severity]: MINOR
- [Finding]: OC-005 hardware requirement ambiguity — plan says M3-M4 need Studio but OC-005 can partially run on MacBook.
- [Why]: Misalignment between hardware availability and task scheduling could delay critical path.
- [Fix]: Add note that OC-005 can begin on MacBook, findings inform OC-008 on Studio.

- [PPLX-F9]
- [Severity]: MINOR
- [Finding]: References to "spec §9" and "spec §Vault Integration Architecture" lack inline citations.
- [Why]: Critical architectural decisions should be traceable to their source.
- [Fix]: Add footnote or links to relevant spec sections.

- [PPLX-F10]
- [Severity]: STRENGTH
- [Finding]: Phased Tier 1 (mandatory, install-time) and Tier 2 (post-launch) hardening is realistic and reduces deployment friction.
- [Why]: Tier 1 addresses critical attack vectors before go-live without blocking unplanned legitimate connections.

- [PPLX-F11]
- [Severity]: STRENGTH
- [Finding]: Isolation test suite as hard go/no-go gate with binary pass/fail criterion prevents ambiguous "mostly working" states.
- [Why]: Objective, repeatable acceptance criteria reduce post-deployment surprises.

### Dependency Verification (Perplexity)

| Named Dependency | Status |
|---|---|
| OpenClaw | Verified — exists, current as of Jan 2026, supports macOS |
| Node.js ≥22 | Verified — required by OpenClaw, installable via nvm |
| Telegram integration | Verified — supported |
| `openclaw doctor` / `openclaw security audit --deep` | UNVERIFIED |
| Claude Code integration | UNVERIFIED |

---

## Synthesis

### Consensus Findings

**1. No rollback/remediation procedures** (GEM-F5, PPLX-F6)
Both Gemini and Perplexity flag the absence of defined rollback steps if the go/no-go isolation gate (OC-011) fails or if M3 goes wrong. Without this, a failed installation leaves the system in an undefined state.

**2. System backup before M3** (GEM-F7, PPLX-F6)
Both note that M3 modifies system-level state (user creation, launchd, filesystem permissions) and should have a recovery checkpoint.

**3. OC-005 scoping and positioning** (OAI-F2, PPLX-F2, PPLX-F8)
Three reviewers note OC-005 needs clearer scoping: what can be tested on MacBook vs. what requires Studio, and its explicit dependency relationship to OC-008.

**4. Isolation test suite productization** (OAI-F6, GEM-F6, PPLX-F11)
Multiple reviewers say OC-011 should be a defined, repeatable script with a known location and timestamped output — not ad-hoc manual execution.

**5. M4 success criteria / Tier 2 conflict** (OAI-F12, GEM-F2)
M4 success criteria include "Tier 2 hardening items applied" but Tier 2 is explicitly deferred to post-go-live. Contradictory.

**6. Acceptance criteria specificity for on-Studio tasks** (OAI-F4, PPLX-F5)
Multiple reviewers note that on-Studio tasks (OC-008, OC-009, OC-010, OC-012) have implicit rather than binary-testable acceptance criteria. Kill-switch dry-run (OC-012) is particularly vague.

### Unique Findings

**OAI-F3: Missing OC-003 → OC-010 dependency** — Genuine insight. The vault scaffold must exist before permissions can be set on `_openclaw/`, `inbox/`, `outbox/`, `outbox/.pending/`. Not in the dependency graph or tasks table.

**OAI-F1: Phase numbering skip (3.5 after 3.3)** — Genuine. The Phase 3.4 heading was removed when OC-009/OC-010 were merged into Phase 3.3, but Phase 3.5 wasn't renumbered.

**GEM-F3: False OC-004 → OC-001 dependency in graph** — Genuine. The ASCII dependency graph visually implies OC-004 feeds into OC-001, but OC-001 draws from the colocation spec directly. OC-004 should only feed OC-006.

**OAI-F10: No logging/monitoring plan** — Partially valid. The spec covers this in Tier 2 (T10 mitigation, log permissions under dedicated user). This is deferred by design, not overlooked.

**PPLX-F1: `openclaw doctor` and `openclaw security audit --deep` unverified** — Research finding from Perplexity. These commands originated in the spec (which was fact-checked across 3 review rounds). If they don't exist at execution time, OC-009 will naturally adapt. Low risk to the plan.

### Contradictions

**OC-009/OC-010 ordering:** GPT-5.2 and Gemini 2.5 Pro praise the parallel design (OAI-F14, GEM-F4). Perplexity wants OC-010 as a hard prerequisite of OC-009 (PPLX-F4). The plan already says "set up before or alongside" which gives implementer flexibility. The user already reviewed and approved this parallel design with the operational note about ordering.

### Action Items

**Must-fix:**

- **A1** (OAI-F1): Renumber Phase 3.5 → Phase 3.4. Trivial but creates execution confusion.
- **A2** (OAI-F12, GEM-F2): Remove "Tier 2 hardening items applied" from M4 success criteria. Tier 2 is deferred post-go-live; M4 acceptance should only cover messaging + kill-switch.
- **A3** (OAI-F3): Add OC-003 as explicit dependency of OC-010 in both the dependency graph and tasks table. Scaffold must exist before permissions are set.
- **A4** (GEM-F3): Fix dependency graph — separate OC-004/OC-006 track from OC-003/OC-001 track. Currently implies false OC-004 → OC-001 dependency.

**Should-fix:**

- **A5** (GEM-F5, PPLX-F6): Add rollback note to M3 — what to do if OC-011 fails. At minimum: revert permissions, optionally remove `openclaw` user, document re-application steps.
- **A6** (GEM-F7): Add system backup/snapshot as M3 prerequisite before any system-level changes.
- **A7** (OAI-F2, PPLX-F2, PPLX-F8): Clarify OC-005 scoping — note that Claude Code Node requirements can be verified on MacBook, but nvm-under-separate-user test requires Studio. Explicitly state OC-005 is a dependency of OC-008 in task text.
- **A8** (OAI-F6, GEM-F6): Define isolation test suite as a script (`scripts/openclaw-isolation-test.sh` or equivalent) with timestamped output, not ad-hoc commands. Update OC-011 acceptance criteria to include "test report artifact created."

**Defer:**

- **A9** (OAI-F10): Logging/monitoring/retention plan — the spec addresses this in Tier 2 hardening and T10 threat mitigation. The dedicated user boundary already isolates logs. Appropriate for post-go-live, not plan-level.
- **A10** (OAI-F7): Vault permission POSIX vs ACL specifics and edge cases — implementation detail for OC-010 execution, not plan-level. The spec's `chgrp -R` / `chmod -R` approach uses standard POSIX permissions which are simpler and more maintainable than ACLs for this use case.
- **A11** (OAI-F8): Doc consistency check across runbook/spec/reference — valid but lightweight enough to execute during OC-006.

### Considered and Declined

- **OAI-F5** (LaunchAgent decision as separate task) — `constraint`. The spec explicitly says "test-first on Studio" and the action plan captures this in OC-008's acceptance criteria ("plist label recorded" implies the choice was made and documented). Adding OC-013 for a decision that's already embedded in OC-008 would be over-structured.
- **PPLX-F4** (Make OC-010 hard prereq of OC-009) — `constraint`. The user already reviewed and approved the parallel design. The plan says "before or alongside" which gives the implementer appropriate flexibility. Hard sequential is unnecessary.
- **PPLX-F1** (`openclaw doctor` unverified) — `out-of-scope`. These commands come from the spec, which was researched and peer-reviewed 3 times. This is a spec-level concern, not an action plan concern. If the commands don't exist at execution time, OC-009 acceptance criteria will naturally adapt.
- **PPLX-F3** (Upgrade M3 to Medium-High) — `overkill`. M3 is already marked Medium and the risk table explicitly names LaunchAgent, nvm, and permission risks. The Jamf enterprise advisory Perplexity references addresses corporate fleet management, not single-user colocation. Current calibration is accurate for the actual deployment context.
- **OAI-F9** (Upgrade M2 to Medium) — `overkill`. M2 produces documentation artifacts. The spec driving it has 3 peer review rounds. Low risk is appropriate for documentation tasks that compile from an already-reviewed source.
- **PPLX-F7** (OC-002 dependency is soft) — `incorrect`. OC-002 adds OpenClaw validation to setup-crumb.sh; it depends on OC-001 to know what to validate. The dependency is genuinely hard even though the health check itself is optional for Crumb-only installations.
- **OAI-F11** (Backup/restore test) — `overkill`. Time Machine handles backup of `/Users/openclaw`. A simulated restore test adds process overhead disproportionate to the risk for a single-user system.
