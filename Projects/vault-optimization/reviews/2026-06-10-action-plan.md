---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/vault-optimization/action-plan.md
artifact_type: other
artifact_hash: c0a0b24c
prompt_hash: 3cd03fc7
base_ref: null
project: vault-optimization
domain: software
skill_origin: peer-review
created: 2026-06-10
updated: 2026-06-10
reviewers:
  - openai/gpt-5.4
  - google/gemini-3.1-pro-preview
  - deepseek/deepseek-v4-pro
  - grok/grok-4.3
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "entropy heuristic: 'moc-crumb-operations' (line 12) — assessed false positive (vault topic tag)"
    - "entropy heuristic: 'scripts/protocols/overlays' (line 114) — assessed false positive (path phrase)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 62502
    attempts: 1
    raw_json: Projects/vault-optimization/reviews/raw/2026-06-10-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 55250
    attempts: 1
    raw_json: Projects/vault-optimization/reviews/raw/2026-06-10-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 110174
    attempts: 1
    raw_json: Projects/vault-optimization/reviews/raw/2026-06-10-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 12793
    attempts: 1
    raw_json: Projects/vault-optimization/reviews/raw/2026-06-10-action-plan-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: vault-optimization action plan

**Artifact:** Projects/vault-optimization/action-plan.md
**Mode:** full
**Reviewed:** 2026-06-10
**Reviewers:** OpenAI gpt-5.4 · Google gemini-3.1-pro-preview · DeepSeek deepseek-v4-pro · Grok grok-4.3 (prompt addendum + calibration watch active)
**Review prompt:** Structured review of the action plan (27 atomic tasks VO-010–036, milestones M1–M5) decomposing spec groups VO-001–009 per design D1–D6. Standard severity rubric (CRITICAL/SIGNIFICANT/MINOR/STRENGTH) plus unverifiable-claim flagging. Focus areas: (1) dependency/gate correctness incl. XD-027 cross-project gates and B0–B6 batch order; (2) task atomicity and binary-testable ACs; (3) changeset-vs-execution split (M3 definitions / M4 mutations) and VO-005/006/007 AC verifiability at B3–B6; (4) soak and ceremony metric adequacy (A10 closure); (5) missing remediation/rollback coverage incl. cross-batch interactions. Companion context: specification summary + optimization design summary.

---

## OpenAI (gpt-5.4)

- [F1]
  - [Severity]: STRENGTH
  - [Finding]: The plan’s top-level sequencing is largely correct and aligned to the specification/design split: M1 establishes the governing ADR decision, M2 builds read-only analysis artifacts, M3 defines changesets only, M4 executes under B0–B6 discipline, and M5 validates/closes.
  - [Why]: This preserves the spec’s intended safety model: decisions first, evidence second, execution only after restore readiness and batch definitions exist.
  - [Fix]: None.

- [F2]
  - [Severity]: STRENGTH
  - [Finding]: The changeset-vs-execution tension is explicitly resolved and documented: M3 defines B3–B6 changesets; M4 performs all edits/deletions under VO-008 batch controls.
  - [Why]: This is one of the highest-risk ambiguities from the spec, and the artifact resolves it in a coherent way without collapsing planning and mutation into the same task.
  - [Fix]: None.

- [F3]
  - [Severity]: STRENGTH
  - [Finding]: Dependency handling for the major cross-project gates is mostly sound. The artifact correctly states that VO-031/032 are blocked on Appendix A freeze plus AS M6 sign-off (XD-027), and that VO-026/033 additionally depend on AS-025.
  - [Why]: This respects the sibling project’s temporary ownership of shared surfaces and prevents vault-optimization from mutating shared areas too early.
  - [Fix]: None.

- [F4]
  - [Severity]: STRENGTH
  - [Finding]: The batch execution model includes strong rollback/interruptibility controls: restore-drill gate, remediate→delete/edit→vault-check→atomic commit, partial-pass rule, and abort = revert + re-survey.
  - [Why]: These controls directly address the highest-risk area identified in the spec: irreversible deletions with incomplete consumer knowledge.
  - [Fix]: None.

- [F5]
  - [Severity]: STRENGTH
  - [Finding]: The plan closes deferred review item A10 well for ceremony metrics. VO-025 defines before/after mandatory-step counts, zombie count target = 0, and a named consumer requirement for every kept step.
  - [Why]: That makes “ceremony reduction” auditable rather than subjective.
  - [Fix]: None.

- [F6]
  - [Severity]: STRENGTH
  - [Finding]: The soak end-condition at VO-034 is concrete and testable: 14 calendar days and at least 8 working sessions from B6 commit, whichever later; pass criteria include restore behavior, repeated workaround absence, and six Tier-1 workflows.
  - [Why]: This is materially better than a vague “use it for a while” soak and creates an objective closure gate.
  - [Fix]: None.

- [F7]
  - [Severity]: SIGNIFICANT
  - [Finding]: The action plan claims decomposition into “27 atomic tasks (VO-010–036)” but the body only exposes milestone/phase groupings and not the actual 27 atomic tasks with per-task acceptance criteria.
  - [Why]: The review request is specifically about task atomicity and AC quality. Without each atomic task being individually visible in the artifact, atomicity is only partially inspectable. Several milestones appear to bundle multiple units of work under one success-criteria block.
  - [Fix]: Include an explicit task list for VO-010 through VO-036 in the action plan itself (or inline a complete summary table), each with: description, dependencies, exact output, and binary acceptance criteria.

- [F8]
  - [Severity]: SIGNIFICANT
  - [Finding]: M2 success criteria are aggregated at the phase level rather than assigned to the individual tasks VO-011–017, VO-018, and VO-019–022.
  - [Why]: This weakens testability. For example, “manifest covers 100% of baseline,” “Appendix A frozen,” “storage policy written,” and “operating-note draft exists” are all measurable, but not clearly mapped to specific task completions. A task can appear “done” while some sub-part remains open.
  - [Fix]: Split M2 criteria by task ID, e.g., one AC set for manifest skeleton, one per evidence pass, one for operator no-evidence review, one for Appendix A freeze, one for operating-note draft, one per consumer-graph split, one for Archived extraction, and one for storage policy issuance.

- [F9]
  - [Severity]: SIGNIFICANT
  - [Finding]: M3 success criteria say “every batch B3–B6 has an approved changeset,” but VO-023–026 as described do not explicitly include B4 and B5 as separate approval objects with their own acceptance thresholds.
  - [Why]: B4 and B5 are among the riskiest surface batches. If their changesets are only implied inside “primitive + docs changesets,” it becomes harder to verify completeness and approval discipline before execution.
  - [Fix]: Name the changeset outputs explicitly per batch: B3 docs pack, B4 scripts/protocols/overlays pack, B5 skills/agents pack, B6 ceremony pack; require each to have disposition list, remediation map, and approval record.

- [F10]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan says spec ACs for VO-005/006/007 are verified at “their corresponding batch checkpoints (B3–B6),” but it does not state exactly which original acceptance conditions are reified at each checkpoint.
  - [Why]: The changeset/execution split only holds if the original VO-005/006/007 outcomes remain verifiable after being deferred into batch execution. As written, that mapping is still somewhat implicit.
  - [Fix]: Add a traceability note such as: VO-006 closes at B3 on canonical-doc map + post-batch vault-check; VO-005 closes across B4/B5 on prune lists + trigger-condition descriptions + post-batch consumer remediation; VO-007 closes at B6 on protocol rewrites + ceremony metric deltas.

- [F11]
  - [Severity]: SIGNIFICANT
  - [Finding]: VO-026 is described as producing the B6 changeset and “CLAUDE.md second-pass diff proposal,” with application post-AS-025; however, VO-033 is also said to require AS-025 complete and stop-and-ask per CLAUDE.md edit. The relationship between “proposal complete” and “approved for execution” is underspecified.
  - [Why]: Shared-surface edits are a coordination hotspot. Without a distinct approval state, VO-026 may appear complete before the plan has captured the exact artifact that VO-033 is authorized to apply.
  - [Fix]: Add an intermediate state/AC: VO-026 completes only when the exact CLAUDE.md diff proposal is recorded, frozen, and tagged “pending AS-025 release approval”; VO-033 may only apply that frozen diff or explicitly re-open VO-026.

- [F12]
  - [Severity]: SIGNIFICANT
  - [Finding]: The dependency graph omits an explicit edge from VO-031/032 to the relevant consumer-graph survey outputs and approved changesets beyond the broad “M3 complete.”
  - [Why]: “M3 complete” is directionally sufficient, but for high-risk deletion batches, the stronger requirement is that the specific consumer-graph evidence and remediation maps for that batch exist and are current. A broad milestone dependency can conceal stale or incomplete local inputs.
  - [Fix]: Add per-batch inputs: e.g., VO-031 requires VO-019/020 survey records plus B4 changeset approval; VO-032 requires VO-019/020 survey records plus B5 changeset approval.

- [F13]
  - [Severity]: SIGNIFICANT
  - [Finding]: Cross-batch interaction protection is only partially covered. “Abort = revert + re-survey” protects within a failed batch, but the plan does not state what happens if a later batch reveals that an earlier batch’s consumer survey was incomplete yet the earlier batch already committed clean.
  - [Why]: This is a realistic failure mode: B3 may pass, then B5 reveals an implicit dependency from a retained primitive to a doc or artifact removed in B3. The current rollback model is batch-local, not explicitly cross-batch.
  - [Fix]: Add a cross-batch remediation rule: if a later batch invalidates an earlier deletion, either restore the deleted artifact in a forward fix commit or revert to the last safe checkpoint before the invalidating batch; require updating the consumer survey and rerunning affected validations.

- [F14]
  - [Severity]: SIGNIFICANT
  - [Finding]: The “partial-pass rule: finish or revert the batch before stopping” is good for atomicity, but it does not specify the scope of “batch” when a batch is too large for one practical work session or one commit.
  - [Why]: B1–B5 may be materially large. If a batch spans multiple commits, “atomic commit checkpoint” and “finish or revert the batch” become ambiguous. This matters because the storage/deletion workload is large, especially Archived/.
  - [Fix]: Define whether each batch may contain sub-commits. If yes, define sub-batch units and their own green criteria; if no, state an upper bound and require pre-splitting any oversized batch into numbered sub-batches before execution.

- [F15]
  - [Severity]: SIGNIFICANT
  - [Finding]: The footprint note says tasks are scoped to “≤5 edited files,” but several described tasks appear inherently larger in edit breadth: manifest completion across baseline surfaces, consumer-graph survey records, docs cluster mapping, protocol rewrites, and ceremony changes.
  - [Why]: This creates an internal consistency problem. Either the tasks are not truly atomic under that file-edit constraint, or the note is using a different notion of scope than the rest of the plan.
  - [Fix]: Clarify that the ≤5 edited files rule applies only to authored/metadata files per task, not deleted files or generated evidence logs; or relax/remove the rule for planning/analysis tasks where one canonical file can legitimately aggregate large findings.

- [F16]
  - [Severity]: SIGNIFICANT
  - [Finding]: The M4 success criterion “all batches committed green; deletions enumerated in run-log; clean tree” is necessary but not sufficient to prove the original functional outcomes of B3–B6.
  - [Why]: A batch can be mechanically green while still violating the intended semantic outcome, e.g., docs are consolidated but not canonicalized correctly, or a kept skill lacks its trigger-condition description.
  - [Fix]: Add batch-specific semantic ACs in M4, such as: B3 all surviving docs have canonical owner/location; B4/B5 all retained primitives have current descriptions and no unresolved consumers; B6 all kept ceremony steps have named consumers and metric diffs recorded.

- [F17]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan does not explicitly say that VO-027’s restore-drill must validate restoration of deleted content classes likely to be touched later (Archived/, docs, primitives, protocols), only that it occurs on a throwaway clone.
  - [Why]: A restore drill that proves only basic clone/reset mechanics may not be enough for confidence in recovering bulk deletions and shared-surface edits.
  - [Fix]: Add acceptance criteria for VO-027 requiring restore of at least one representative artifact from each high-risk class and verification that the restored vault passes the intended health check.

- [F18]
  - [Severity]: MINOR
  - [Finding]: “May run during AS M3–M5” is specified for VO-010, but the same concurrency guidance is not stated for the rest of M2 even though the milestone heading says “parallel with AS M3–M5.”
  - [Why]: The reader can infer it, but explicit concurrency boundaries help prevent accidental overlap on shared surfaces.
  - [Fix]: Add a short note at M2 level stating which tasks are safe in parallel because they are read-only and which require AS concurrence.

- [F19]
  - [Severity]: MINOR
  - [Finding]: The phrase “gotchas only where a failure is on record” in VO-023–024 is a bit ambiguous as an acceptance target.
  - [Why]: It is unclear what counts as “on record” and where the record must live. That weakens binary closure.
  - [Fix]: Define the source of truth, e.g., “gotchas documented only when supported by a linked incident/workaround note in run-log, issue tracker, or protocol history.”

- [F20]
  - [Severity]: MINOR
  - [Finding]: “Every high-risk batch starts with an explicit operator go (risk-tiered approval)” is good, but the trigger list in Risk & Gate Summary omits VO-029 and VO-033 despite their potentially disruptive nature.
  - [Why]: Attachments/log deletions and ceremony edits can still break workflows. The current high-risk classification may be too narrow relative to the execution narrative.
  - [Fix]: Either explain why VO-029/033 are lower risk or expand the stop-and-ask list to include them.

- [F21]
  - [Severity]: MINOR
  - [Finding]: The phrase “the same removed primitive needed twice = fail” is clear enough operationally, but “needed” could be interpreted subjectively.
  - [Why]: Soak failure criteria should be as objective as possible.
  - [Fix]: Define “needed” as “restored, manually recreated, or worked around in a way documented as compensating for its removal.”

- [F22]
  - [Severity]: MINOR
  - [Finding]: The plan references “all six spec end-state deliverables” without enumerating them in the close-out section.
  - [Why]: The six deliverables are known from context, but restating them at closure would make final acceptance easier to audit.
  - [Fix]: List them directly under VO-036 success criteria.

- [F23]
  - [Severity]: MINOR
  - [Finding]: The inventory baseline is useful, but it is presented as fact without attaching where the regeneration record lives.
  - [Why]: For planning review, this is acceptable, but for execution auditability the baseline should point to the evidence artifact.
  - [Fix]: Link or reference the baseline capture file/command log.

- [F24]
  - [Severity]: SIGNIFICANT
  - [Finding]: UNVERIFIABLE CLAIM: “Calibration note: agentic-sunset decomposed 9 spec tasks → 23 atomic (2.6x); this plan is 3.0x — consistent with the captured teardown pattern (~2–3 atomic tasks per ‘scrap N things’ spec line).”
  - [Why]: This references another project’s decomposition statistics and a “captured teardown pattern” that cannot be independently verified from the artifact provided.
  - [Fix]: Cite the exact AS planning artifact or remove the numeric calibration argument.

- [F25]
  - [Severity]: SIGNIFICANT
  - [Finding]: UNVERIFIABLE CLAIM: “Inventory baseline (regenerated 2026-06-10 at TASK start, per D1): 2,511 md files · 20 skills · 4 agents · 8 overlays · 20 scripts · 6 protocols · 25 solution docs · 12 project dirs · 10 live plists · Archived/ 147M, Projects/ 42M, Sources/ 12M, _system/ 5.1M, _attachments/ 4.7M, Domains/ 560K.”
  - [Why]: These are concrete filesystem statistics, but no command output, evidence link, or recorded source is included in the artifact.
  - [Fix]: Attach the command log or link to the baseline evidence file.

- [F26]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan says “manifest covers 100% of baseline with zero ‘unknown’ rows,” which is strong, but it does not explicitly account for items created/changed after baseline regeneration and before execution.
  - [Why]: In a live vault, drift between M2 and M4 can invalidate the guarantee. This is especially important because M2 is intended to run in parallel with another active project.
  - [Fix]: Add a drift-control step: re-run baseline diff before M3 sign-off or immediately before each execution batch; require dispositioning of any new in-scope items.

- [F27]
  - [Severity]: SIGNIFICANT
  - [Finding]: VO-028/B1 “Archived/ exception-extraction + deletion” does not explicitly reference the “canonical-exception extraction list” as a preserved output artifact to be validated before deletion.
  - [Why]: Since Archived/ is the biggest storage target and deletion is aggressive, preserving and validating the exception list is crucial to avoid losing canonical material.
  - [Fix]: Add a binary AC: exception list finalized, reviewed, and committed before any Archived/ deletion commit.

- [F28]
  - [Severity]: SIGNIFICANT
  - [Finding]: VO-029/B2 groups three distinct risk profiles—attachment orphans, non-md heavyweights, and dead logs—into one batch without clear sub-criteria.
  - [Why]: These are not the same kind of deletion. “Producer-alive check” applies to dead logs but not obviously to heavyweights or orphaned attachments. The task may be too compound to be safely atomic.
  - [Fix]: Split VO-029 into separate atomic tasks/sub-batches or define separate ACs and evidence requirements for each subtype.

- [F29]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan relies on “vault-check green” at each batch but does not define what “vault-check” consists of.
  - [Why]: This is a key gate in the safety model. If undefined, different operators can interpret “green” differently, undermining reproducibility.
  - [Fix]: Define the vault-check command/protocol and the exact pass conditions in the action plan or by stable reference.

- [F30]
  - [Severity]: SIGNIFICANT
  - [Finding]: The action plan does not explicitly state how operator review of “every no-evidence deletion” interacts with later drift or newly discovered consumers.
  - [Why]: A deletion approved under no-evidence conditions might become evidence-backed later, or vice versa. The operator review rule is powerful, but its maintenance semantics are not specified.
  - [Fix]: Add a rule that any row whose evidence status changes after operator review must be re-presented for approval before execution.

Overall assessment: strong structure and generally sound gating, with the biggest weaknesses being incomplete exposure of the actual 27 atomic tasks, some ambiguity in task-level acceptance criteria, and a few missing protections around drift, cross-batch invalidation, and oversized batch handling.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of the vault-optimization action plan, evaluated against the specification, design context, and specific focus areas.

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "Inventory baseline (regenerated 2026-06-10...): 2,511 md files · 20 skills · 4 agents · 8 overlays · 20 scripts · 6 protocols · 25 solution docs · 12 project dirs · 10 live plists · Archived/ 147M, Projects/ 42M, Sources/ 12M, _system/ 5.1M, _attachments/ 4.7M, Domains/ 560K." and "agentic-sunset decomposed 9 spec tasks → 23 atomic (2.6x)".
- [Why]: These are highly specific repository state metrics, byte sizes, and cross-project statistics that cannot be independently verified without access to the local git repository and the agentic-sunset issue tracker. 
- [Fix]: Validate these counts and sizes via an automated script during the actual M2 baseline task to ensure the plan's sizing assumptions are anchored in verified data.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: Cross-batch remediation collisions are unaddressed in M3/M4.
- [Why]: The batch model dictates "remediate consumers → delete/edit" per batch. Since M3 builds changesets for all batches *before* execution, a consumer evaluated in B5 (e.g., a Skill) might also be a consumer of a Doc slated for deletion in B3. Consequently, B3's execution will mutate the B5 Skill. When B5 subsequently executes, its changeset will be based on the pre-B3 state, leading to merge conflicts or overwriting B3's remediation. 
- [Fix]: In M3, mandate that changesets are drafted *sequentially* (B3 → B4 → B5 → B6) with cross-batch dependencies explicitly mapped, OR mandate a "refresh changeset" step at the start of each M4 batch to recalculate against the newly mutated working tree.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: Functional validation is entirely backloaded to M5 (Soak), missing inter-batch functional regression testing in M4.
- [Why]: The M4 batch partial-pass rule relies on "vault-check green". If this check is purely mechanical (e.g., broken wikilinks, syntax), behavioral regressions caused by early batches (like B3 Docs) won't be caught until M5 when the Tier-1 workflows are finally run. Finding the offending root cause would require bisecting the entire M4 commit history.
- [Fix]: Redefine "vault-check green" in M4 to include a dry-run or fast-pass of the six Tier-1 workflows (from D6) so functional breakage is caught at the specific atomic commit checkpoint that caused it.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Missing rollback/recovery protocol for M5 Soak failure.
- [Why]: The plan defines strict pass/fail criteria for the soak period (e.g., zero urgent git restores, workflows must pass). However, if the system *fails* the soak (e.g., a removed primitive is urgently needed, breaking the workaround rule), there is no defined protocol for recovery. Does the operator fix-forward (add the primitive back), or perform a hard `git revert` of specific M4 batch commits?
- [Fix]: Add a specific failure-handling rule to VO-034/035: define whether soak failures are resolved via fix-forward (with a strict spec amendment) or by reverting the offending B1-B6 commits and re-entering M3.

- [F5]
- [Severity]: MINOR
- [Finding]: Ambiguous task atomicity mapping in VO-023 and VO-024.
- [Why]: The plan groups "B4/B5 changeset" and "B3 changeset" under "Phase: Primitive + docs changesets (VO-023–024)". Because there are three distinct batches (B3, B4, B5) mapped to two task IDs, it is slightly unclear where the exact boundaries lie.
- [Fix]: Explicitly map the IDs in the text: e.g., "(VO-023: B4/B5 primitive changesets; VO-024: B3 docs changeset)".

- [F6]
- [Severity]: STRENGTH
- [Finding]: Resolution of the Changeset vs. Execution tension.
- [Why]: By forcing M3 to only produce changesets and pushing all actual mutations into M4's strict B0-gated batch order, the plan cleanly respects both the spec's deletion requirements (VO-005/006/007) and the batch-execution safety constraints (VO-008). 

- [F7]
- [Severity]: STRENGTH
- [Finding]: Closure of deferred review item A10 (Ceremony and Soak metrics).
- [Why]: The translation of abstract optimization goals into binary, highly testable criteria—specifically "zombie count must reach 0", "every kept step must name its consumer", and "14 calendar days AND ≥8 working sessions"—provides excellent, unambiguous completion gates for tasks VO-025 and VO-034.

- [F8]
- [Severity]: STRENGTH
- [Finding]: Interruptibility and partial-pass rules in M4 execution.
- [Why]: The "liberation directive" that yields to revenue prompts is brilliantly protected by the atomic commit checkpoints and "finish or revert before stopping" rule. This ensures the vault is never left in a half-deleted, broken state between sessions.

---

## DeepSeek (deepseek-v4-pro)

I've reviewed the vault-optimization action plan artifact. Below are structured findings, classified by severity and aligned to the focus areas you requested.

---

## Findings

### F1 — SIGNIFICANT: Missing atomic task list undermines plan completeness
- **Finding:** The action plan references a tasks.md table but does not include it; the artifact only summarises phases with ID ranges (VO-011–017, VO-019–022, etc.). Individual acceptance criteria, sequencing constraints within phases, and effort estimates for the 27 atomic tasks are not visible.
- **Why:** Without the full decomposition, reviewers cannot verify that every unit of work has binary-testable ACs, that no group hides under- or over-scoped tasks, or that inter-task dependencies are correctly wired.
- **Fix:** Include the tasks.md table in the artifact (or replicate its content in an appendix) so the plan is self-contained and verifiable.

### F2 — SIGNIFICANT: Implicit dependency within M2 risks drafting operating note before keep-set
- **Finding:** VO-018 (operating note draft) states it should run “once identity and keep-set are known,” but the action plan declares M2 runs “parallel with AS M3–M5” and lists no dependency ordering inside M2. If VO-018 starts concurrently with keep-set manifest (VO-011–017), the draft may be based on incomplete data.
- **Why:** The operating note’s quality and correctness depend on a complete keep-set; a premature draft would need rework and could miss dispositions.
- **Fix:** Add an explicit dependency edge: VO-018 must start after the keep-set manifest reaches “operator review complete” (or after VO-011–017 finishes). Alternatively, structure M2 phases sequentially or with a clear handoff.

### F3 — SIGNIFICANT: Deferred review item A12 is not addressed
- **Finding:** The specification summary states items A10–A12 were deferred to planning; A10 (ceremony metrics) and A11 (taxonomy cleanup) are explicitly addressed (VO-025 and B3 changeset). A12 is never mentioned, explained, or marked as out-of-scope.
- **Why:** If A12 carries an expected deliverable or decision, its absence leaves a gap in spec closure and may cause a missed deliverable at project completion.
- **Fix:** Either identify A12 in the plan (acknowledge it’s covered elsewhere, no longer relevant, or folded into another task) or add a clarification note. Document the disposition of all three deferred items.

### F4 — SIGNIFICANT: Cross-batch rollback beyond a single batch is not described
- **Finding:** The batch abort rule is “revert + re-survey” for the current batch only. While the plan notes that git remote is the authoritative restore source, no procedure is defined for recovering from a problem discovered after several batches are committed (e.g., a missing consumer that spans B3→B5 deletions).
- **Why:** If a late batch reveals a flaw in an earlier batch’s remediation, simply reverting the latest batch won’t fix the earlier state. The operator may need to replay from backup through corrected batches, but that workflow is not captured in the execution discipline.
- **Fix:** Add a conditional step for multi-batch remediation: if a discovered defect cannot be fixed within the current batch without altering already-committed batches, abort to a “restore-from-backup + replan” path. This can be a low-probability fallback, but the plan should acknowledge it.

### F5 — SIGNIFICANT (UNVERIFIABLE CLAIM): Inventory baseline statistics cannot be confirmed
- **Finding:** The plan states: “Inventory baseline (regenerated 2026-06-10 at TASK start, per D1): 2,511 md files · 20 skills · 4 agents · … Archived/ 147M, Projects/ 42M, …” These are specific, attributed statistics about the vault’s state.
- **Why:** As an external reviewer, I cannot verify these numbers; they rely on a snapshot that is not attached. The review must flag such claims for grounded verification after the fact.
- **Fix:** No action required in the artifact — this flag serves as a reminder for the project team to confirm the baseline before proceeding.

### F6 — MINOR: Working-session definition in soak criteria is ambiguous
- **Finding:** VO-034 requires “≥8 working sessions from the B6 commit.” “Working session” is not defined (does it mean any day the operator interacts with the vault? A minimum number of actions?).
- **Why:** A subjective count could lead to disagreements on when the soak is truly satisfied, undermining the binary end-condition.
- **Fix:** Define “working session” explicitly, e.g., “a day on which the operator performs at least one Tier‑1 workflow or equivalent vault action,” and require the operator to log those sessions.

### F7 — MINOR: Ceremony “enforcer” terminology unclear
- **Finding:** VO-025 says ceremony steps must “name its consumer/enforcer.” The term “enforcer” is not defined elsewhere in the artifact (is it a tool, a protocol rule, or a person?).
- **Why:** Without clarity, the checklist diff may become inconsistent or fail to capture real enforcement mechanisms.
- **Fix:** Replace “consumer/enforcer” with a concrete phrase like “consumer (file/skill that references the step) and optional enforcement mechanism (e.g., CLAUDE.md ritual trigger or shell wrapper).”

### F8 — STRENGTH: Clear decomposition and spec-tension resolution
- **Finding:** The plan explicitly resolves the spec’s tension between VO-005/006/007 and VO-008 by splitting definition from execution. M3 produces changesets only; M4 applies them under the batch discipline, and spec ACs for the pruning tasks are verified at B3–B6 checkpoints. This is well-reasoned and preserves traceability.

### F9 — STRENGTH: Soak and ceremony metrics are concrete and closure-worthy
- **Finding:** VO-025 defines ceremony metrics with mandatory counters (before/after, zombie→0, named consumer per step) and a checklist diff to prevent semantic loss. VO-034 defines a soak end-condition (“14 calendar days AND ≥8 working sessions, whichever later”) with hard pass criteria (zero urgent restores, no repeated workaround, all six Tier‑1 workflows pass). These directly close A10 and provide a testable completion contract.

### F10 — STRENGTH: Robust batch execution discipline
- **Finding:** The batch model (remediate → delete/edit → vault-check green → atomic commit, with partial-pass rule, explicit operator go for high-risk batches, and abort/revert) provides strong safety for irreversible deletions. The B0 backup drill gate and git‑remote-as-authoritative-source decision further reduce risk.

### F11 — MINOR: “4 open questions answered” in ADR acceptance not scoped
- **Finding:** VO-010 success criteria includes “4 open questions answered,” but these questions are not listed in the artifact. This is a local dependency that should be resolved in the ADR itself, but the plan does not verify that the ADR document currently contains exactly four open questions.
- **Why:** The ADR’s status may not match this numeric expectation; changes between drafting and acceptance could invalidate the count.
- **Fix:** Either note that the count will be confirmed against the ADR at VO-010 enaction, or replace with “all open questions recorded in the ADR” to avoid a brittle number.

---

**Summary:** The action plan is well-structured, resolves the major spec tensions, and provides strong gates and validation criteria. The most critical gaps are the missing atomic task table (incompleteness), the implicit dependency risk within M2, and the unaddressed A12 deferred item. The soak and ceremony metrics are excellent, and the batch execution model is sound. Flag the inventory claims for verification and clarify a few ambiguous terms.

---

## Grok (grok-4.3)

F1
[Severity]: SIGNIFICANT
[Finding]: The soak end-condition phrasing in VO-034 ("14 calendar days AND ≥8 working sessions ... whichever is satisfied later") creates an ambiguous logical gate that could be interpreted as requiring both conditions to be met at the later timestamp rather than taking the maximum of the two independent thresholds.
[Why]: This directly affects M5 closure criteria and the A10 metric adequacy review; an operator could mis-execute the soak window, leading to premature or delayed sign-off.
[Fix]: Rewrite explicitly as: "End of soak = max(B6 + 14 calendar days, B6 + 8 working sessions)."

F2
[Severity]: SIGNIFICANT
[Finding]: VO-026 and VO-033 list AS-025 as a hard gate, yet the plan provides no task or checkpoint that records the AS-025 completion signal or verifies its payload (protocol rewrites, CLAUDE.md diff) before M4 begins.
[Why]: Breaks the dependency-graph soundness requirement; M3 can complete while the prerequisite state remains invisible to vault-optimization.
[Fix]: Insert an explicit synchronization task (e.g., VO-026a) that polls the AS run-log for the AS-025 sign-off hash and aborts if absent.

F3
[Severity]: SIGNIFICANT
[Finding]: The 27 atomic tasks are asserted but the document only enumerates 26 distinct VO- IDs in the milestone phases (VO-010–036 inclusive yields 27 numbers, yet VO-026 is described as two distinct units: ceremony classification + B6 changeset).
[Why]: Violates task atomicity; one ID now hides multiple units of work, weakening acceptance-criteria testability.
[Fix]: Split VO-026 into VO-026 (ceremony metrics) and a new VO-037 (B6 changeset proposal).

F4
[Severity]: SIGNIFICANT
[Finding]: No task or acceptance criterion verifies that the six Tier-1 workflows used in the VO-034 soak are the same workflows whose consumer graphs were surveyed in VO-019–022.
[Why]: The changeset-vs-execution split and spec ACs for VO-005/006/007 cannot be confirmed at B3–B6 checkpoints without this traceability.
[Fix]: Add a one-line mapping in VO-019 output and require VO-034 to cite the identical workflow IDs.

F5
[Severity]: MINOR
[Finding]: The "partial-pass rule" and "abort = revert + re-survey" language in M4 is stated only at the phase level, not attached to any individual VO-028–033 task acceptance criteria.
[Why]: Reduces binary-testability of the batch model and leaves remediation/rollback coverage incomplete for cross-batch interactions.
[Fix]: Append the identical rule text to each of VO-028 through VO-033 success criteria.

F6
[Severity]: SIGNIFICANT
[Finding]: UNVERIFIABLE CLAIM: "XD-027", "AS-025", "AS M6 sign-off", and all cross-project gate references lack any external locator or run-log entry that an independent reviewer could consult.
[Why]: Prevents grounded verification of the critical dependency edges claimed in the plan.
[Fix]: Require each such reference to include a commit hash, issue URL, or dated run-log excerpt.

F7
[Severity]: MINOR
[Finding]: Inventory baseline numbers (2,511 md files, 147 MB Archived/, etc.) are presented as "regenerated 2026-06-10" yet no command or artifact path is recorded that would allow reproduction of the count.
[Why]: Weakens the evidence rubric and keep-set manifest completeness claim in M2.
[Fix]: Add the exact shell/Obsidian query used to produce each figure next to the numbers.

F8
[Severity]: STRENGTH
[Finding]: The explicit separation of changeset definition (M3) from mutation execution (M4) with per-batch atomic commits is internally consistent with the design D4 and protects against irreversible deletions.
[Why]: Directly satisfies the review focus area on the changeset-vs-execution split and the high-risk nature of VO-008.

F9
[Severity]: MINOR
[Finding]: VO-010 success criteria mention "4 open questions answered" without listing or linking to those questions.
[Why]: Minor clarity issue; the ADR acceptance gate cannot be mechanically verified from the plan alone.
[Fix]: Either enumerate the four questions or cite their location in specification.md.

---

---

## Synthesis (Claude, 2026-06-10)

**Context for all findings:** reviewers received `action-plan.md` + spec/design summaries but NOT `tasks.md`, where the 27 per-task binary ACs and dependency edges live. Several findings decline on that premise; the residual lesson is captured as action item A11.

**Grok calibration watch (review 2):** 9 findings — 0 fabrications, 1 misread (GRK-F3: claimed VO-026 bundles ceremony classification + B6 changeset; those are separate tasks VO-025/VO-026, and the ID count is 27 as stated), 1 noise (GRK-F4: asserts soak workflows must trace to the consumer survey; they derive from the ADR/D6). Valid: F1 (severity-inflated clarity nit), F2, F5, F7, F9. Tally appended to peer-review-config.md.

### Consensus Findings

1. **Cross-batch invalidation + changeset staleness** (OAI-F13, GEM-F2, DS-F4) — strongest consensus. The batch model is batch-local: M3 changesets are drafted against a pre-mutation tree and go stale as B3→B6 execute; a later batch can reveal an earlier batch's survey was incomplete after that batch committed clean; no restore-from-backup/replan fallback exists.
2. **Baseline/evidence citations missing from the artifact** (OAI-F23/F24/F25, GEM-F1, DS-F5, GRK-F7, GRK-F6) — inventory baseline, calibration statistics, and cross-project gate references carry no pointer to their evidence artifacts (run-log entry, estimation-calibration.md, cross-project-deps.md).
3. **Missing atomic task table in the reviewed artifact** (OAI-F7, OAI-F8, DS-F1) — premise incorrect (tasks.md exists with per-task binary ACs and dependency edges) but the action plan should cross-reference it explicitly, and future reviews must embed it.
4. **VO-026/033 AS-025 gate needs an explicit verification + frozen-proposal state** (OAI-F11, GRK-F2) — the dependency edge exists but no AC records the AS-025 sign-off check or freezes the CLAUDE.md diff proposal that VO-033 is authorized to apply.
5. **Definitional looseness in soak/ceremony criteria** (DS-F6 "working session", OAI-F21 "needed", DS-F7 "enforcer", GRK-F1 end-condition phrasing, DS-F11/GRK-F9 "4 open questions") — A10 closure is structurally good (4/4 STRENGTHs) but several terms are not yet mechanically checkable.

### Unique Findings

- **GEM-F3 (genuine):** vault-check is structural, not functional — regressions from early batches surface only at M5 soak, forcing bisection across the whole M4 history. A lightweight Tier-1 fast-pass at batch checkpoints localizes breakage.
- **GEM-F4 (genuine):** no soak-failure recovery protocol — fix-forward vs revert is undefined for M5.
- **OAI-F26/F30 (genuine):** live-vault drift — items created/changed between M2 baseline and M4 execution escape the "100% coverage, zero unknown" guarantee; evidence-status changes after operator review have no re-approval rule. Material because M2 deliberately runs parallel to agentic-sunset.
- **OAI-F14 (genuine):** "batch = atomic commit" is ambiguous for oversized batches; sub-batch semantics undefined.
- **OAI-F28 (genuine):** VO-029 bundles three deletion risk profiles (orphans / heavyweights / dead logs) under one AC set.
- **OAI-F9/F10 (genuine):** changeset outputs not named per batch with their own approval records; spec-AC→batch-checkpoint mapping implicit.
- **DS-F3 (genuine):** A12 disposition never stated in the plan (it was folded into the Appendix A ownership matrix at spec amendment time — the plan should say so).
- **OAI-F17 (mild):** restore-drill AC nearly covers content classes (≥1 file per top-level dir) but doesn't require the restored set to pass vault-check.
- **OAI-F20 (mild):** VO-029/VO-033 excluded from stop-and-ask without stated rationale.
- **GRK-F1 (mild, severity-inflated):** soak end-condition is correct but `max(B6+14d, B6+8 sessions)` phrasing is unambiguous.

### Contradictions

- **GEM-F2 fix options:** sequential changeset drafting (B3→B6 with cross-deps mapped) vs per-batch refresh step at M4 execution time. Not a cross-reviewer contradiction but a fork needing a decision — refresh-at-execution is chosen in A1 (changesets stay drafted from the current tree; a staleness check is mechanical and absorbs OAI-F13's re-survey rule). No reviewer-vs-reviewer contradictions found this round.

### Action Items

**Must-fix (before IMPLEMENT):**
- **A1** (OAI-F13, GEM-F2, DS-F4): add a **cross-batch integrity rule** to the M4 batch model: (a) changeset staleness check opens every batch — re-validate the batch's changeset + consumer lists against the current tree, refresh if any referenced path changed since drafting; (b) if a later batch reveals an earlier batch's deletion broke a surviving consumer → forward-fix commit restoring the artifact from git + survey update + re-run of affected checks; (c) fallback: if a defect cannot be fixed forward without altering committed batches → halt M4, restore-from-git-remote replan path, re-enter M3.
- **A2** (OAI-F26, OAI-F30): add **drift control**: baseline re-diff at M3 close and at the top of every M4 batch; any new/changed in-scope item gets a manifest row + disposition before that batch runs; any row whose evidence status changed after operator review returns to the operator before execution.

**Should-fix:**
- **A3** (GEM-F4, OAI-F21, DS-F6): soak hardening — define soak-failure protocol at VO-034 (single primitive-restore = fix-forward with run-log entry; repeated-workaround failure or Tier-1 blocker = revert offending batch commits + re-enter M3); define "working session" (a day with ≥1 logged vault work session) and "needed" (restored, recreated, or workaround documented as compensating).
- **A4** (OAI-F9, OAI-F10, GEM-F5): name per-batch changeset packs (B3/B4/B5/B6, each with disposition list + remediation map + approval record) and add the explicit spec-AC→checkpoint traceability map (VO-006→B3, VO-005→B4+B5, VO-007→B6).
- **A5** (OAI-F11, GRK-F2): VO-026 completes only when the CLAUDE.md diff proposal is frozen and tagged pending-AS-025-release; VO-033 AC adds "AS-025 sign-off verified in AS run-log" and may only apply the frozen diff or re-open VO-026.
- **A6** (OAI-F14, OAI-F28): sub-batch rule — a batch may split into numbered sub-batches, each with its own remediate→delete→green→commit cycle; partial-pass applies per sub-batch; VO-029 splits into three sub-batches (orphans / heavyweights / dead logs) with per-subtype evidence ACs.
- **A7** (GEM-F3): functional fast-pass — after each M4 batch commit, run an abbreviated Tier-1 spot-check (touched-surface workflows only) in addition to vault-check; full six-workflow run stays at VO-035.
- **A8** (OAI-F23/F24/F25, GEM-F1, DS-F5, GRK-F6/F7, OAI-F29): citation pass — baseline points to the run-log regeneration entry; calibration claim cites _system/docs/estimation-calibration.md; XD-027/AS gates cite _system/docs/cross-project-deps.md; vault-check defined by stable reference to _system/scripts/vault-check.sh.
- **A9** (GRK-F1, OAI-F18/F19/F22, DS-F7/F11, GRK-F9, OAI-F17/F20, OAI-F15): definitional tightening — soak end-condition as max(); M2 concurrency note (read-only tasks safe in parallel, VO-016 needs AS concurrence); "gotchas on record" = linked failure-log/run-log entry; enumerate the six end-state deliverables at VO-036; "consumer/enforcer" → "consumer (referencing file/skill) or enforcement mechanism (hook/vault-check)"; "4 open questions" → "all open questions recorded in the ADR"; VO-027 AC adds "restored sample passes vault-check"; one-line rationale for VO-029/033 medium risk; clarify ≤5-edited-files applies to authored files only.
- **A10** (DS-F3): state A12's disposition in the plan (folded into Appendix A ownership matrix per spec amendment round).
- **A11** (OAI-F7, DS-F1 root cause): action plan explicitly cross-references tasks.md as the per-task AC source; future peer reviews of plans embed tasks.md alongside.

**Defer:**
- None standalone — all defer-grade items absorbed into A8/A9.

### Considered and Declined

- **OAI-F8** (M2 ACs unmapped to tasks) — `incorrect`: tasks.md assigns binary ACs per task ID; reviewers lacked the file. Residual handled by A11.
- **DS-F2** (VO-018 may run before keep-set) — `incorrect`: tasks.md has VO-018 depends_on VO-010 + VO-017.
- **OAI-F12** (VO-031/032 missing survey edges) — `incorrect`: covered transitively (VO-031 ← VO-023 ← VO-019/020); the staleness concern it gestures at is handled by A1/A2.
- **OAI-F16** (M4 lacks semantic ACs) — `incorrect`: tasks.md VO-030–033 ACs carry the semantic conditions (zero dead wikilinks, trigger-condition descriptions); traceability gap handled by A4.
- **GRK-F3** (task count/bundling) — `incorrect`: misread; VO-025 and VO-026 are separate tasks, count is 27.
- **GRK-F4** (soak workflows must trace to consumer survey) — `incorrect`: Tier-1 workflows derive from the accepted ADR via design D6, not from VO-019/020.
- **GEM-F2 sequential-drafting option** — `overkill`: refresh-at-execution (A1a) achieves the same protection without serializing M3.

### Verdict

Plan structurally sound — the changeset/execution split, batch discipline, and A10 closure drew 4/4 STRENGTHs. Two must-fix amendments (cross-batch integrity, drift control) plus nine should-fix. No CRITICAL findings this round.
