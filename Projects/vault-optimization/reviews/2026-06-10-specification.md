---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/vault-optimization/specification.md
artifact_type: specification
artifact_hash: e3cc07b6
prompt_hash: 5cf991c3
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
    - "9 high-entropy string flags — all assessed as vault file paths / slash-joined slugs (entropy detector false positives, e.g. _system/docs/cross-project-deps)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 118039
    attempts: 1
    raw_json: Projects/vault-optimization/reviews/raw/2026-06-10-specification-openai.json
  google:
    http_status: 200
    latency_ms: 40050
    attempts: 1
    raw_json: Projects/vault-optimization/reviews/raw/2026-06-10-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 109251
    attempts: 1
    raw_json: Projects/vault-optimization/reviews/raw/2026-06-10-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 12907
    attempts: 1
    raw_json: Projects/vault-optimization/reviews/raw/2026-06-10-specification-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: vault-optimization specification

**Artifact:** Projects/vault-optimization/specification.md
**Mode:** full
**Reviewed:** 2026-06-10
**Reviewers:** OpenAI gpt-5.4 · Google gemini-3.1-pro-preview · DeepSeek deepseek-v4-pro · xAI grok-4.3
**Review prompt:** Structured spec review (correctness, completeness, internal consistency, feasibility, clarity) with severity classification (CRITICAL/SIGNIFICANT/MINOR/STRENGTH), UNVERIFIABLE CLAIM flagging, and four focus questions: (1) sequencing soundness given the in-flight agentic-sunset boundary (XD-027), (2) acceptance-criteria sufficiency for the aggressive-deletion pass with git-history-only recovery, (3) credibility of the reconstructed usage-evidence plan, (4) missing essentials for a project defining the system's own core functionality. Grok received the standard problem-prioritization addendum. Finding ID namespaces: OAI-F*, GEM-F*, DS-F*, GRK-F*.

---

## OpenAI (gpt-5.4)

Below is a structured review of the specification.

## Overall assessment

This is a strong, unusually disciplined spec. It has clear scope, explicit operator decisions, good provenance, and a credible decomposition from identity decision → inventory/manifest → consumer analysis → deletion execution. It also does a good job acknowledging the active dependency on `agentic-sunset` and not trying to seize ownership of shared surfaces prematurely.

The main weaknesses are not conceptual but operational:

- the cross-project boundary with `agentic-sunset` is still underdefined at the task level,
- the aggressive-deletion safeguards are good but not yet sufficient for a truly irreversible working-tree pass,
- the evidence model for keep/delete decisions is plausible but could still produce false negatives,
- and the “core functionality” outcome lacks a final explicit canonical artifact beyond accepting the ADR.

---

## Findings

### F1
- [Severity]: STRENGTH
- [Finding]: The problem statement, baseline decisions, and scope are internally coherent and tightly aligned.
- [Why]: The spec avoids a common failure mode in cleanup projects: trying to optimize before first deciding what the system is. Here, VO-001 explicitly establishes identity before all downstream dispositions, and the operator decisions lock key ambiguities early (v3 ADR baseline, four optimization axes in scope, aggressive deletion policy).
- [Fix]: None.

### F2
- [Severity]: STRENGTH
- [Finding]: The sequencing logic is mostly sound: decision first, then full inventory manifest, then consumer-graph survey, then storage policy, then implementation.
- [Why]: This sequence matches the risk profile of the work. It is especially strong that deletion decisions do not precede consumer-graph analysis, and that execution is held until after both policy and dependency mapping are complete.
- [Fix]: None.

### F3
- [Severity]: SIGNIFICANT
- [Finding]: The boundary with `agentic-sunset` is acknowledged but still leaks in several places, especially around skills, memory references, CLAUDE.md-adjacent workflow changes, and “post-sunset reality” evaluation in VO-001.
- [Why]: Shared-surface cleanup projects often conflict not because ownership is unknown, but because timing and task-level exclusions are not explicit enough. Here, VO-005 depends on “AS-028/029 boundary settled,” but there is no defined mechanism, artifact, or approval gate for settling that boundary. VO-007 depends on AS-025 completion, but ceremony changes may still indirectly alter CLAUDE.md assumptions before AS closure.
- [Fix]: Add an explicit boundary-settlement deliverable before VO-005/VO-007, e.g. “VO-000 / joint surface contract” or a required appendix to VO-002 listing per-surface ownership:
  - owned by AS,
  - owned by VO,
  - jointly reviewed,
  - blocked until AS close.
  Also add an acceptance criterion that no VO task may modify paths or concepts owned by AS unless the ownership matrix is updated and sign-off recorded.

### F4
- [Severity]: SIGNIFICANT
- [Finding]: VO-001 risks becoming under-scoped because “refresh + accept v3 identity ADR” is defined as review-and-answer rather than as production of a definitive operational core model.
- [Why]: Accepting the ADR may formally settle identity, but this project’s stated outcome is to optimize the vault down to “core functionality.” That requires not just accepted identity, but an operational definition of what must remain. Right now, that translation is deferred to VO-002, which is useful but can drift into ad hoc inventory disposition rather than principled core definition.
- [Fix]: Expand VO-001 or add a companion deliverable requiring an explicit “core functionality definition” section or artifact. It should state:
  - core functions,
  - non-core but allowed support functions,
  - retired functions,
  - and decision tests for future additions.
  This would make VO-002 a constrained execution of policy, not a de facto policy-making task.

### F5
- [Severity]: SIGNIFICANT
- [Finding]: The aggressive-deletion safeguards are good but insufficiently specified for preventing partial-pass failure states.
- [Why]: The spec says “Never break vault-check green / clean-tree discipline mid-pass,” but deletion work often cannot maintain green state after each individual file removal because link structures and references may be repaired in batches. Also, “backup integrity verified before deletion” is necessary but not enough if the deletion pass is interrupted midway or if a restoration drill has never been tested.
- [Fix]: Strengthen VO-008 with an explicit execution model:
  - batch plan with atomic commit checkpoints,
  - reversible local checkpoint before each batch,
  - restoration drill on a temp clone or alternate worktree,
  - explicit stop conditions if vault-check turns red unexpectedly,
  - and a rule for handling partial completion (e.g. finish batch or revert batch before stopping).
  Also define what “clean-tree discipline” means during active batch execution.

### F6
- [Severity]: SIGNIFICANT
- [Finding]: Backup integrity is named as a dependency but not operationalized enough for a repo where git history is the sole archive after deletion.
- [Why]: “Verify backup integrity” is ambiguous. A backup can exist yet be unusable, stale, incomplete, filtered incorrectly, or not include dotfiles / ignored files / external memory surfaces that matter. Since the policy removes reversible in-tree archival, backup validation must be stronger than presence-checking.
- [Fix]: Add explicit acceptance criteria to VO-008 or VO-004:
  - identify the authoritative backup set,
  - confirm timestamp freshness,
  - test restoration of a sample deleted directory/file set,
  - verify ignored-path coverage or explicitly document exclusions,
  - verify backup of harness memory if it remains in scope,
  - and record restoration procedure in run-log.

### F7
- [Severity]: SIGNIFICANT
- [Finding]: The evidence plan for keep/delete dispositions is credible but vulnerable to false negatives because it relies on reconstructed usage without telemetry.
- [Why]: Session logs, run-logs, and git history can show explicit use, but absence of evidence is not strong evidence of non-use. Some components exist as contingency tools, low-frequency emergency aids, implicit dependencies, or operator mental models that leave little trace. This is especially risky for scripts, protocols, and overlays.
- [Fix]: Strengthen VO-002 with a decision rubric that separates:
  - proven active use,
  - inferred structural necessity,
  - low-use but high-consequence fallback,
  - superseded/duplicative,
  - no evidence and no dependency.
  Also require operator review of all “delete due to no evidence” items, not just manifest completion. Consider adding one short operator survey/checklist for edge cases that won’t show up in logs.

### F8
- [Severity]: SIGNIFICANT
- [Finding]: The spec does not define minimum evidence standards for each primitive type.
- [Why]: “Usage evidence” means different things for skills, overlays, scripts, protocols, docs, and project records. Without type-specific standards, the manifest risks inconsistency and debates during implementation.
- [Fix]: Add evidence criteria by class, for example:
  - skills: invocation traces, session references, or repeated task contexts they served;
  - scripts: actual executions from run logs/shell history or references from hooks/plists;
  - overlays/protocols: direct inclusion in workflows or mandatory constitutional/document references;
  - docs: backlinks, MOC presence, recent edits, or explicit canonical designation;
  - project records: open dependency, active reference, or required historical/legal record.
  Define what counts as sufficient evidence to keep, optimize, or delete.

### F9
- [Severity]: SIGNIFICANT
- [Finding]: Consumer-graph scope is strong, but it may still miss non-wikilink semantic dependencies and external references.
- [Why]: Mechanical search across hooks, plists, wikilinks, MOCs, memory refs, and backup filters is excellent, but some breakages arise from plain-text path references, naming conventions, transclusion patterns, dashboards, shell aliases, or Obsidian config/plugin expectations. Given the system recently had launchd/runtime complexity, residual references may exist outside the listed graph.
- [Fix]: Broaden VO-003 to explicitly include:
  - plain-text grep for path/name references,
  - Obsidian config/plugin/workspace references,
  - dashboard or web-serving config references,
  - shell alias/env/config consumers if any are in-vault documented,
  - and naming-convention dependencies (e.g. directory pattern assumptions).
  Add “mechanical search protocol” as a named method.

### F10
- [Severity]: SIGNIFICANT
- [Finding]: The spec assumes vault-check + Obsidian indexing are sufficient to detect deletion fallout, but this is not fully justified.
- [Why]: Broken links and tags are only one class of failure. Consumer breakage can also include stale process docs, changed skill-routing behavior, silent omission from MOCs, backup exclusion drift, malformed frontmatter assumptions, or dashboard breakage. The current verification criteria do not clearly cover these.
- [Fix]: Expand VO-008 verification to include:
  - vault-check,
  - Obsidian broken links/unresolved references,
  - MOC spot checks on designated core maps,
  - kept-skill routeability review,
  - script/hook/config smoke test for retained surfaces,
  - and backup-filter audit after deletions.

### F11
- [Severity]: SIGNIFICANT
- [Finding]: “Storage & weight” mixes working-tree cleanup and repo-size reduction, but the decision structure does not fully separate them.
- [Why]: A2 notes that history rewrite is out of scope unless separately decided, which is sensible. But the storage problem statement and directory-weight statistics may create implicit expectations of repo shrinkage that working-tree deletion alone will not satisfy. This can lead to confusion when `Archived/` disappears from HEAD but clone size remains large.
- [Fix]: In VO-004, explicitly distinguish:
  - working-tree weight reduction,
  - active-vault navigation reduction,
  - and repository/history size reduction.
  Require the storage policy to state expected outcomes for each, and what will not improve without history rewrite.

### F12
- [Severity]: SIGNIFICANT
- [Finding]: The acceptance criteria for VO-006 are not fully aligned with the aggressive deletion policy.
- [Why]: The criterion says “solutions library has no superseded-era entries without dormant-marking,” but the operator decision says aggressive deletion with no Archived/-style reversibility requirement. “Dormant-marking” sounds like retention/soft-deprecation, which may contradict the deletion-first stance unless there is a principled reason to keep some superseded documents.
- [Fix]: Clarify the retention policy for superseded docs. For example:
  - either delete superseded-era entries unless they remain canonical background/reference,
  - or define explicit keep reasons for dormant-marked docs.
  Update VO-006 acceptance criteria to reflect that policy consistently.

### F13
- [Severity]: SIGNIFICANT
- [Finding]: The spec lacks an explicit rollback/escalation policy if ADR acceptance reveals the core identity is not actually stable enough for optimization.
- [Why]: A1 says Tier assignments are probably still approximately correct and only need refresh, but if VO-001 discovers substantial mismatch, downstream tasks should not proceed by inertia. Right now the workflow implies only “validate in VO-001,” but not what happens if validation fails.
- [Fix]: Add a decision gate after VO-001:
  - if ADR changes are minor, proceed;
  - if Tier model or core identity materially changes, re-plan before VO-002.
  This should be a formal branch in the project flow, not just an implied possibility.

### F14
- [Severity]: MINOR
- [Finding]: Some acceptance criteria use subjective phrases that would benefit from operational definitions, such as “short soak,” “optimize, don't just shrink,” and “approximately correct.”
- [Why]: These phrases communicate intent well but can weaken completion judgment if left undefined.
- [Fix]: Add measurable definitions:
  - soak window duration and end condition,
  - optimization heuristics or target outcomes for ceremony reduction,
  - threshold for what counts as “approximately correct” in ADR review.

### F15
- [Severity]: MINOR
- [Finding]: The spec could be clearer about whether `Archived/` is in scope for deletion only as content, or also as an information model/category to be removed from navigation/taxonomy.
- [Why]: If the directory is deleted aggressively, surviving docs, MOCs, and habits may still refer to “Archived/” as a conceptual bucket. That could leave semantic clutter even after filesystem cleanup.
- [Fix]: Add a line in VO-004/VO-006 to remove or rewrite taxonomy, docs, and MOCs that assume Archived/ remains a valid destination/category.

### F16
- [Severity]: MINOR
- [Finding]: The “Liberation directive: revenue prompts take priority claim; this is infra and yields, runs in parallel” is contextually useful but not integrated into planning implications.
- [Why]: It signals priority but does not translate into batch size, pacing, interruption handling, or deadlines. For a high-risk cleanup project, interruption tolerance matters.
- [Fix]: Either remove the line from the spec body or convert it into an execution constraint, e.g. “tasks must be interruptible at commit-level checkpoints and planned as small batches.”

### F17
- [Severity]: STRENGTH
- [Finding]: The spec explicitly recognizes second-order effects, especially broken links, script/plist references, memory-path coupling, and skill-routing changes after pruning.
- [Why]: This is one of the strongest parts of the document. Many cleanup specs focus only on direct deletions, but this one anticipates behavioral changes in the system after simplification.
- [Fix]: None.

### F18
- [Severity]: STRENGTH
- [Finding]: The use of a keep-set manifest with 100% coverage and “no unknown” rows is a strong control mechanism.
- [Why]: It prevents hand-wavy cleanup and forces comprehensive decisions. Combined with consumer-graph analysis, it creates a rigorous basis for deletion.
- [Fix]: None.

### F19
- [Severity]: STRENGTH
- [Finding]: The spec properly treats CLAUDE.md as constitution-adjacent and preserves stop-and-ask discipline while sequencing behind AS-025.
- [Why]: That restraint reduces the chance of constitutional drift during infrastructure cleanup and respects ownership boundaries.
- [Fix]: None.

### F20
- [Severity]: SIGNIFICANT
- [Finding]: The project does not explicitly specify the final canonical outputs that should exist after completion.
- [Why]: A project redefining “core functionality” should likely end with a small stable set of canonical artifacts, not only a set of deletions and accepted ADR. Without naming those outputs, the vault could become smaller yet still lack a clear operational center.
- [Fix]: Add a “Deliverables / end state” section, for example:
  - accepted v3 ADR,
  - core functionality definition or operating model note,
  - keep-set manifest,
  - storage policy,
  - reduced primitive surface,
  - curated docs index/MOC for the retained system.
  Also identify which artifact is the canonical entrypoint for future maintenance.

### F21
- [Severity]: SIGNIFICANT
- [Finding]: The spec does not explicitly address ownership and disposition of non-markdown/non-note assets beyond `_attachments/` and `Archived/`.
- [Why]: Large or stale weight can hide in binaries, exported artifacts, generated files, or hidden config in other directories. Since the inventory count centers on markdown, there is some risk the storage optimization misses significant non-markdown residue.
- [Fix]: Add a file-type/size audit to VO-004 or VO-002 covering large non-markdown objects, generated artifacts, and top-N size offenders across the repo.

### F22
- [Severity]: MINOR
- [Finding]: “No external repo (vault-only project)” is helpful, but the system map includes harness memory in `~/.claude/.../memory/`, which is not vault-local.
- [Why]: This creates a mild terminology mismatch: the project is vault-only in repo scope, but some dependency analysis and cleanup coordination involve out-of-repo memory surfaces.
- [Fix]: Clarify that implementation changes are vault-only, while dependency analysis includes adjacent non-repo memory surfaces that must be coordinated but are not modified by this project unless separately authorized.

### F23
- [Severity]: SIGNIFICANT
- [Finding]: The plan does not explicitly include a post-optimization observability period beyond a “short soak,” despite changing the primitive surface that affects future routing and workflow behavior.
- [Why]: Pruning skills/overlays/protocols can create latent regressions that only appear in normal use. A very short soak may be insufficient to confirm the new reduced surface is actually adequate.
- [Fix]: Define the soak window and include success criteria such as:
  - no urgent restores from git,
  - no repeated workarounds for removed primitives,
  - no newly discovered critical missing references,
  - operator sign-off after real-session use across representative tasks.

### F24
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “Live inventory (2026-06-10): 2,504 markdown files; 20 skills, 4 agents, 8 overlays, 20 `_system/scripts/`, 6 protocols, 25 solution docs, 12 project directories, 9 domains. Directory weight: `Archived/` 147 MB, `Projects/` 41 MB, `Sources/` 12 MB, `_system/` 5 MB, `_attachments/` 4.7 MB.”
- [Why]: These are concrete inventory and size statistics that cannot be independently verified from the artifact alone. They are central to scope sizing and should be grounded by reproducible collection method.
- [Fix]: Add the command/query method and timestamp/source note used to produce these counts, or link the generated inventory artifact.

### F25
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “`Archived/` 147 MB ≈ 70% of vault weight in one directory.”
- [Why]: This derived percentage materially motivates deletion strategy but cannot be independently confirmed from the supplied artifact.
- [Fix]: Show the denominator and measurement method in VO-004 or the inventory appendix.

### F26
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “Signals (operator-selected): `trq212-anthropic-skill-design-lessons` ... `skillsbench-agent-skills-mixed-results` ...”
- [Why]: These appear to reference named materials or studies whose contents, provenance, and conclusions cannot be independently confirmed here. They influence design choices around skills and ceremony.
- [Fix]: Add full citations or local document references for each signal, plus a one-line summary of what was actually adopted from each.

### F27
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “Anthropic-flagged HIGH value / LOW effort” in the skill-description lever.
- [Why]: This is an attributed evaluation claim without verifiable source in the artifact.
- [Fix]: Cite the exact source note/document where this characterization appears, or restate it as an internal judgment rather than attributed external guidance.

### F28
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “health assessment says this beats capability work; SkillsBench says focused beats exhaustive.”
- [Why]: These are attributed conclusions that may be true internally, but cannot be independently verified without cited passages.
- [Fix]: Add pinpoint references to the relevant sections in the health assessment and SkillsBench source.

---

## Responses to the additional focus questions

## 1. Sequencing: is the task decomposition and dependency structure sound, and where could the boundary leak?

### Assessment
Mostly yes. The decomposition is structurally sound:

1. settle identity,
2. build exhaustive manifest,
3. map consumers,
4. decide storage policy,
5. prune primitives,
6. curate docs,
7. reduce ceremony,
8. execute and verify.

That is a strong order for this kind of internal-system refactor.

### Likely boundary leaks
The main leak points are:

- **VO-001 vs AS reality changes**  
  VO-001 reviews “post-sunset reality,” but AS is still in flight through M6/M7. If VO-001 evaluates the system before AS-owned surfaces are stable, the accepted ADR could be based on a transitional state.

- **VO-002 manifesting surfaces still being modified by AS**  
  If AS continues to clean up skills/memory/directory structure while VO-002 builds a complete manifest, the inventory can drift and create stale dispositions.

- **VO-005 primitive optimization vs AS-028/029**  
  This is the largest leak. Skills and memory are shared conceptual surfaces even if AS owns cleanup. Without a strict ownership matrix, both projects can independently “simplify” the same primitives.

- **VO-007 ceremony changes vs AS-025 CLAUDE.md diff**  
  Even if CLAUDE.md itself is not edited, changing phase-gate/process docs may effectively redefine constitutional behavior before the constitution diff lands.

### Best fix
Add a formal joint-surface contract and a sequencing gate that says:
- VO-001/002 may proceed on read-only analysis before AS closure,
- VO-005/007 cannot start until a frozen ownership matrix exists,
- any ADR acceptance that depends on AS outcomes must be reconfirmed after AS milestone closure.

---

## 2. Irreversibility: are the acceptance criteria sufficient, and what failure modes are unaddressed?

### Assessment
Not yet sufficient for an aggressive-deletion pass.

The current criteria are good for governance but not strong enough for operational safety.

### Addressed well
- backup verification is required before deletion,
- consumer-graph discipline is explicit,
- vault-check/Obsidian verification is planned,
- git history is explicitly recognized as sole archive,
- soak window is required.

### Unaddressed or under-addressed failure modes
- **partial-pass interruption**  
  What happens if work stops after deleting files but before repairing consumers?

- **batch-size control**  
  No atomic deletion batches or checkpoint rules.

- **restoration drill absence**  
  Backups may exist but be practically unusable.

- **false-negative consumer analysis**  
  Mechanical searches limited to named surfaces may miss plain-text or config references.

- **non-link semantic breakage**  
  Workflows can degrade without broken links.

- **unexpected operator regret**  
  Since there is no Archived/-style reversibility, there should be stronger sign-off on borderline deletions.

- **repo-size expectations mismatch**  
  Working-tree deletion may not produce the storage result the operator expects.

### Best fix
Add:
- staged deletion batches with commit checkpoints,
- restore test on temp clone/worktree,
- explicit stop/revert criteria,
- post-batch verification at each checkpoint,
- stronger operator sign-off for “delete due to no evidence” items,
- and a documented distinction between active-tree cleanup and actual repo shrinkage.

---

## 3. Evidence: is the reconstructed usage evidence plan credible, and what would strengthen it?

### Assessment
Credible, but incomplete.

It is a reasonable plan given no telemetry exists. Session logs, run-logs, and git history are probably the best available evidence. But reconstructed evidence should not be treated as exhaustive truth.

### Risks
- low-frequency/high-importance tools disappear,
- hidden dependencies are mistaken for disuse,
- protocol/docs are retained or deleted based on edit activity rather than actual necessity,
- “no evidence” becomes over-weighted.

### What would strengthen it
1. **Type-specific evidence standards**  
   Different standards for skills, scripts, overlays, protocols, docs, and project records.

2. **Decision categories beyond keep/delete**  
   Include “keep as contingency,” “structurally required,” and “operator-mandated.”

3. **Operator review of all no-evidence deletions**  
   Especially for scripts and protocols.

4. **Structural evidence count as first-class evidence**  
   A script referenced by a hook is in use even if no recent direct invocation exists.

5. **One-pass live operator sanity review**  
   A brief review of borderline deletions can catch the things telemetry never would.

---

## 4. Is anything essential missing for a project whose output is the system’s own definition of “core functionality”?

### Yes — two main things.

#### A. A canonical end-state artifact
The spec should explicitly require a final artifact that answers:
- What is Crumb now?
- What must exist for it to remain itself?
- What is deliberately not part of it anymore?
- How should future additions be judged?

Accepting the ADR helps, but a concise operational “core functionality” note or section would make the project’s outcome much more durable.

#### B. Future-change decision rules
If this project is defining the core, it should leave behind criteria for future maintenance. Otherwise the primitive surface can regrow. The spec should require at least a short rubric like:
- Does this support durable knowledge storage or reasoning substrate directly?
- Is it constitutional/core, support, or retired-domain residue?
- Does it add net maintenance burden beyond demonstrated value?
- Can an existing retained primitive satisfy the need?

Without that, the optimization may succeed once but not remain stable.

---

## Summary judgment

### Correctness
Strong overall, with no major internal contradiction except some tension between aggressive deletion and dormant-marking language.

### Completeness
Good, but missing:
- an explicit core-functionality end-state artifact,
- stronger irreversibility controls,
- a task-level cross-project ownership contract,
- and type-specific evidence standards.

### Internal consistency
Mostly consistent. Main weak points:
- shared-surface sequencing with `agentic-sunset`,
- working-tree deletion vs true storage reduction,
- aggressive deletion vs retained dormant docs.

### Feasibility
Feasible if boundary management is tightened and execution safeguards are strengthened. Without those, the project risks either coordination conflict or over-aggressive deletion based on incomplete evidence.

### Clarity
Generally very clear and well-structured. A few subjective terms and underdefined verification concepts should be operationalized.

If helpful, I can also turn this review into:
1. a concise “must-fix before PLAN” list, or  
2. an annotated redline of the spec sections with proposed wording.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of the `vault-optimization` specification.

### Structured Findings

- **[F1]**
- **Severity**: CRITICAL
- **Finding**: Direct scope collision on skill/primitive cleanup between `vault-optimization` (VO) and `agentic-sunset` (AS).
- **Why**: The System Map states AS owns "skills/memory cleanup (AS-owned)", and U2 mentions AS-028/029 is a cleanup scope. However, VO-005 explicitly tasks "Primitive surface optimization: prune per manifest; kept skills get trigger-condition descriptions". If both projects are executing deletions or archivals on the same primitive surface concurrently or sequentially without a hard interface, race conditions and git conflicts are guaranteed.
- **Fix**: Redefine the boundary. Either AS-028/029 limits itself strictly to *runtime deactivation*, leaving all file deletion/pruning to VO-005, or AS-028/029 executes the deletion and VO-005 is rescoped purely to updating descriptions for the *surviving* skills.

- **[F2]**
- **Severity**: CRITICAL
- **Finding**: Missing task to *remediate* the consumer graph (broken links/hooks).
- **Why**: VO-003 surveys deletion candidates and generates a list of impacted consumers (wikilinks, MOCs, memory refs). VO-008 executes the deletions. However, no task explicitly owns *updating or removing* the references inside the consumer files. Deleting a target without updating the files that point to it will immediately break the "vault-check green / clean-tree discipline mid-pass" constraint.
- **Fix**: Insert a remediation task between VO-003 and VO-008, or update VO-005/VO-006 to explicitly include "execute consumer graph updates for pruned items."

- **[F3]**
- **Severity**: SIGNIFICANT
- **Finding**: UNVERIFIABLE CLAIM: External references to Anthropic and SkillsBench signals.
- **Why**: The specification cites `trq212-anthropic-skill-design-lessons` (trigger-condition descriptions, gotchas) and `skillsbench-agent-skills-mixed-results` (2–3 focused skills > exhaustive). These appear to be highly specific external papers, Anthropic documentation, or localized vault studies. Without verifiable external sources or embedded data, the baseline justification for VO-005's design constraints cannot be independently validated.
- **Fix**: Provide direct URLs to external Anthropic/SkillsBench documentation, or explicitly label these as internal, local-vault empirical studies.

- **[F4]**
- **Severity**: SIGNIFICANT
- **Finding**: UNVERIFIABLE CLAIM: Vault inventory and telemetry statistics.
- **Why**: The spec claims exact metrics: "2,504 markdown files; 20 skills, 4 agents, 8 overlays... Archived/ 147 MB, Projects/ 41 MB", etc. As external reviewers, we cannot independently verify the live state of this local filesystem or the exact size of these directories.
- **Fix**: Attach a point-in-time tree dump or terminal output script (e.g., `tree` or `du -sh`) in the project appendices to serve as a verifiable baseline for these figures.

- **[F5]**
- **Severity**: SIGNIFICANT
- **Finding**: Unrealistic burden of proof for the "usage evidence" requirement in VO-002.
- **Why**: The spec demands "usage evidence (session logs, git log, run-logs)" for every skill, agent, overlay, script, etc., while acknowledging "No skill-usage telemetry exists". Manually reconstructing tool-call histories from unstructured Claude session logs across months of usage is highly tedious, error-prone, and likely to stall the project in the research phase.
- **Fix**: Define a timebox for log analysis (e.g., "scan logs from the last 30 days only") or establish a heuristic (e.g., "if usage cannot be found within 15 minutes of regex searching, assume unused").

- **[F6]**
- **Severity**: SIGNIFICANT
- **Finding**: Insufficient backup protocol for potential git-history rewrites (VO-004).
- **Why**: The spec notes aggressive deletion makes git history the archive, but VO-004 includes an "explicit git-history-rewrite decision". If history is rewritten (e.g., `git filter-repo`), standard drive syncs or incremental backups may be corrupted or fail to capture the erased commits. 
- **Fix**: Add a strict conditional acceptance criterion to VO-004/VO-008: "If git-history-rewrite is approved, a full, isolated clone of the `.git` directory must be stored out-of-band before execution."

- **[F7]**
- **Severity**: MINOR
- **Finding**: Assumption 1 (A1) lacks a failure branch.
- **Why**: A1 assumes the ADR only needs a "refresh, not redesign". VO-001 sets acceptance of this ADR as the gate for the whole project. If the 4 unanswered operator questions reveal a fundamental flaw requiring redesign, the spec lacks a contingency plan.
- **Fix**: Add a minor caveat to VO-001: "If ADR requires redesign exceeding 1 hour, spawn a sub-task and pause VO-002."

- **[F8]**
- **Severity**: STRENGTH
- **Finding**: Excellent discipline regarding system constraints and phase gating.
- **Why**: The rigorous tracking of the "consumer graph" before deletion, the explicitly defined boundaries (even if slightly overlapping) with `agentic-sunset`, and the upfront commitment to "vault-check green" ensure this optimization project treats the personal OS with production-grade care.

***

### Answers to Additional Focus Questions

**1. Sequencing: is the task decomposition and dependency structure sound given that a separate in-flight teardown project owns some shared surfaces? Where could the boundary leak?**
The boundary is currently leaking heavily at the "Skills & Memory" layer (Task VO-005 vs. AS-028/029). The system map states AS owns "skills+memory cleanup", but VO owns "pruning primitives" and editing kept skills. Because there is no hard dependency gate forcing VO-005 to wait for AS-028/029 to finish (it only says "boundary settled"), there is high risk of merge conflicts or redundant work. VO needs a strict sequencer: AS must finish *its* state changes to skills/memory before VO reads that surface to determine what remains to be optimized.

**2. Irreversibility: are the acceptance criteria sufficient to gate an aggressive-deletion pass where git history is the only recovery path? What failure modes are unaddressed?**
The criteria are partially insufficient. While pre-pass backups are mandated, three critical failure modes are unaddressed:
*   *Broken-link cascades*: The plan surveys consumers (VO-003) but forgets to *update* them before or during deletion (VO-008). Obsidian will instantly flood with broken links.
*   *Git Rewrite Catastrophe*: If VO-004 decides to rewrite git history to save the 147MB, standard backups might be overwritten by continuous syncs. An isolated, off-site tarball of the `.git` folder must be explicitly required.
*   *Partial Pass States*: If VO-008 fails mid-way (e.g., a script deletion breaks a pre-commit hook, halting the git pass), there is no rollback script defined.

**3. Evidence: the keep/delete dispositions depend on reconstructed usage evidence. Is the evidence plan credible, and what would strengthen it?**
The plan is currently not credible. Extracting empirical usage data from unstructured markdown session logs and `git log` text without existing telemetry is a massive, manual data-mining task. To strengthen it, the operator should build a quick regex script (e.g., `grep -r "Tool Used: \[skill_name\]" ~/.claude/logs`) to automate the extraction, or define a strict "statute of limitations" (e.g., "if I don't explicitly remember using it in May, it is deleted").

**4. Is anything essential missing for a project whose output is the system's own definition of "core functionality"?**
Yes. The project treats the "Crumb v3 identity ADR" as a mere rubber-stamp (VO-001: "Refresh + accept"). Because this ADR actually defines the OS's core capabilities going forward, there is no validation step to ensure the *resulting* vault actually meets the defined criteria of a "reasoning substrate". The spec measures success by *what is removed* (reduced files, zero broken links, green checks), but lacks a post-execution validation task to verify that the *core reasoning workflows* still function end-to-end after the surgical deletions.

---

## DeepSeek (deepseek-v4-pro)

## Structured Review: vault-optimization Specification

### Overview
The specification is well-scoped, grounded in operator decisions, and follows a rigorous systems‑analysis structure. It clearly defines the problem, inputs, assumptions, dependencies, and a phased task decomposition. The aggressive‑deletion posture is explicitly stated, and the reliance on git history as the recovery path is acknowledged. The system map and second‑order effects sections demonstrate strong attention to downstream breakage.

The primary weaknesses lie in sequencing gaps between ceremony reduction and primitive‑surface pruning, insufficient definition of backup verification, a thin evidence‑gathering plan for usage reconstruction, and the absence of a functional validation step for the core reasoning substrate after pruning. Several factual claims (inventory numbers and internal signal references) cannot be verified independently.

### Findings

- **F1**  
  **Severity:** SIGNIFICANT  
  **Finding:** The dependency structure for **VO‑007** (ceremony reduction on kept workflows) does not include VO‑005 (primitive surface optimization) or even VO‑002 (keep‑set manifest). The task currently depends only on VO‑001 and AS‑025, but the set of “kept workflows” is not known until the primitive surface is pruned. This could lead to ceremony redesign on workflows that are later deleted, or to missed optimisations on workflows that change shape.  
  **Why it matters:** Redundant work, risk of keeping ceremony for removed primitives, or failing to optimise the final set of active workflows.  
  **Fix:** Add VO‑002 or VO‑005 as a dependency for VO‑007, or explicitly sequence the ceremony work after the keep‑set is stabilised during the PLAN/TASK phase.

- **F2**  
  **Severity:** SIGNIFICANT  
  **Finding:** The acceptance criteria for **VO‑008** require “backup verified before first deletion”, but the specification does not define what constitutes verification of backup integrity. A mere statement of intent leaves open the possibility of assuming integrity without actual checks (e.g., listing files vs. testing restore).  
  **Why it matters:** In an aggressive‑deletion scheme where git history is the only recovery path, a backup that is corrupt or incomplete would be catastrophic. The gate is only as strong as the verification method.  
  **Fix:** Specify a concrete backup‑verification procedure in the PLAN phase—for example, running a dry‑run restore, comparing file counts and checksums, or confirming a recent mirror‑sync succeeded.

- **F3**  
  **Severity:** SIGNIFICANT  
  **Finding:** The keep/delete/disposition plan (VO‑002) depends on reconstructed usage evidence from session logs, run‑logs, and git history, with no systematic method described. The specification acknowledges the lack of telemetry (U1), but the evidence plan remains vague.  
  **Why it matters:** Subjective or incomplete evidence weakens the credibility of the keep‑set and may lead to removal of rarely‑used but critical primitives, or retention of unused weight.  
  **Fix:** Strengthen the evidence‑gathering approach by defining a concrete protocol (e.g., automated extraction of skill invocations from session logs, analysis of recent git‑patch activity per directory, operator interview criteria) during the PLAN phase. This should produce a reproducible evidence weight for each disposition.

- **F4**  
  **Severity:** SIGNIFICANT  
  **Finding:** The acceptance criteria for the “core functionality” outcome lack a functional validation that the pruned vault still functions as a reasoning substrate. The checks (vault‑check green, zero dead wikilinks) guarantee structural integrity but do not confirm that the remaining skills, agents, and memory files actually perform Tier‑1 reasoning tasks.  
  **Why it matters:** A project whose output is the system’s own definition of core functionality must demonstrate that the core works after large‑scale deletion. Structural tools cannot catch subtle breakage (e.g., trigger‑condition mismatches, missing overlay dependencies).  
  **Fix:** Add an acceptance criterion to VO‑008 (or a new VO‑009) that a representative set of core reasoning prompts (aligned with the accepted ADR’s Tier‑1/2 workflows) is executed and verified during the soak window, with any failures blocking completion.

- **F5**  
  **Severity:** SIGNIFICANT  
  **Finding:** **UNVERIFIABLE CLAIM:** The specification cites “trq212-anthropic-skill-design-lessons” and “skillsbench-agent-skills-mixed-results” as signals without providing their content or confirmable external references. The document treats them as authoritative inputs (e.g., “Anthropic‑flagged HIGH value / LOW effort”), but a reviewer cannot assess their validity or relevance.  
  **Why it matters:** Decisions informed by opaque, unverifiable sources introduce risk that the plan is built on misunderstood or misapplied lessons.  
  **Fix:** Either incorporate a concise summary of the relevant takeaways from those signals directly into the spec, or replace the references with inline reasoning and examples that do not require external confirmation.

- **F6**  
  **Severity:** SIGNIFICANT  
  **Finding:** **UNVERIFIABLE CLAIM:** The live inventory numbers (2,504 markdown files, 20 skills, 4 agents, 8 overlays, specific directory sizes) are presented as factual claims without a verifiable data source. While they are likely internal measurements, an external reviewer cannot confirm them.  
  **Why it matters:** The manifest scope and deletion targets depend on these exact counts; inaccuracies could lead to missed items or incorrect planning.  
  **Fix:** Document a re‑validation step (e.g., running a file‑count script at PLAN start) and note that these numbers are a snapshot for initial planning only. The review finding flags them for grounded verification before execution.

- **F7**  
  **Severity:** SIGNIFICANT  
  **Finding:** The cross‑project dependency with **agentic‑sunset** regarding AS‑028/029 (skills and memory cleanup) is acknowledged as a boundary risk, but no concrete coordination mechanism is described beyond “settled at task level before IMPLEMENT.” The dependency line in VO‑005 is soft and could lead to conflicting edits or duplicated effort.  
  **Why it matters:** Without an explicit joint review, two concurrent projects might both decide to delete the same skill, or one might rely on a skill the other removes.  
  **Fix:** Add a clear cross‑project boundary resolution step in the PLAN phase—for example, a shared “skills disposition register” that both projects must ratify, or a joint task‑approval gate before any IMPLEMENT work begins on those surfaces.

- **F8**  
  **Severity:** MINOR  
  **Finding:** The task decomposition mixes planning‑phase work (VO‑001–004) with implementation tasks (VO‑005–008). The spec states that the action‑architect will refine at TASK, but as written it blurs the separation between specification and implementation.  
  **Why it matters:** Potential confusion about which phase gate a task belongs to, though it is not blocking.  
  **Fix:** Group tasks under the appropriate phases (SPECIFY, PLAN, TASK, IMPLEMENT) when the plan is finalised, or leave the current decomposition but add a note that VO‑001–004 are “planning tasks to be completed before IMPLEMENT.”

- **F9**  
  **Severity:** STRENGTH  
  **Finding:** The **system map** and explicit **second‑order effects** analysis are excellent. The consumer‑graph survey (hooks, plists, wikilinks, MOCs, memory files, backup filter lists) as applied from the infrastructure‑teardown‑discipline provides a robust method for preventing broken‑link cascades.

- **F10**  
  **Severity:** STRENGTH  
  **Finding:** The acceptance criteria are specific, measurable, and include zero‑tolerance for dead links and unknown dispositions. This aligns well with the aggressive‑deletion posture and creates clear pass/fail gates.

### Focus Questions Summary

1. **Sequencing:** The task decomposition is generally sound, but the boundary between VO‑007 (ceremony reduction) and VO‑005 (primitive surface) is underspecified (F1). The cross‑project dependency with agentic‑sunset’s AS‑028/029 is at risk of leaking unless a concrete joint‑resolution mechanism is added (F7).  
2. **Irreversibility:** The acceptance criteria for VO‑008 address backup verification and structural checks, but the absence of a precise verification standard (F2) and the lack of functional validation (F4) leave two significant failure modes unaddressed: an incomplete/incorrect backup leading to unrecoverable deletions, and a “green” vault that no longer functions as a reasoning substrate.  
3. **Evidence:** The keep/delete dispositions rely on reconstructed usage evidence with no described methodology (F3). The evidence plan would be strengthened by specifying how logs will be mined, which metrics (invocation count, recency) will be used, and how evidence gaps will be filled.  
4. **Core functionality definition:** The specification stakes the core definition on the ADR (VO‑001) and subsequent pruning, but it misses a demonstration step that the pruned system actually delivers that core (F4). Adding a functional verification task would close this gap and answer “does the optimized vault still work as defined?”

### Overall Assessment
The specification is structurally sound and reflects careful system thinking. With the identified gaps closed—especially around backup verification, functional testing, evidence methodology, and the ceremony‑reduction sequencing—the plan would be sufficiently robust for an aggressive vault optimization. The flagged unverifiable claims should be resolved or substituted to ensure grounded decision‑making.

---

## Grok (grok-4.3)

F1
[Severity]: SIGNIFICANT
[Finding]: Sequencing dependency on agentic-sunset (AS-025–032) for shared surfaces (CLAUDE.md, skills, directories) is stated as a hard gate, but the boundary is described only at milestone level rather than task-interface level.
[Why]: VO-005 and VO-007 explicitly require the AS boundary to be “settled” before execution; without a concrete hand-off artifact (e.g., signed checklist or diff), work could begin on stale state or create concurrent edits.
[Fix]: Add an explicit pre-VO-005 entry criterion: “AS M7 closure sign-off recorded in run-log + joint boundary review of any overlapping primitive paths completed.”

F2
[Severity]: SIGNIFICANT
[Finding]: UNVERIFIABLE CLAIM: “Live inventory (2026-06-10): 2,504 markdown files; 20 skills, 4 agents, 8 overlays, 20 `_system/scripts/`, …” (and all subdirectory weights) are presented as authoritative counts with only a date attribution.
[Why]: These exact figures drive every downstream keep/delete decision and acceptance criterion; unverifiable numbers undermine the credibility of the entire manifest (VO-002).
[Fix]: Require the TASK phase to regenerate the inventory via mechanical commands (e.g., `find`, `git ls-files`) and record the new baseline in the run-log before any disposition work.

F3
[Severity]: CRITICAL
[Finding]: Acceptance criteria for VO-008 require only “backup verified before first deletion” and “vault-check green after,” but supply no definition of verification method, no partial-pass recovery procedure, and no check for broken-link cascades that deletions are acknowledged to trigger.
[Why]: The policy is “aggressive deletion” with git history as sole archive; any undetected failure (corrupt backup, incomplete consumer-graph sweep, Obsidian index lag) produces permanent loss with no documented remediation path.
[Fix]: Mandate concrete pre-deletion steps: (1) cryptographic backup hash + restore test on a throwaway vault, (2) automated link-graph diff before/after, (3) explicit “abort and restore” trigger condition if vault-check fails mid-pass.

F4
[Severity]: SIGNIFICANT
[Finding]: The evidence plan for keep/delete decisions (VO-002) relies solely on “reconstructed usage evidence (session logs, run-logs, git history)” with the explicit admission that “no skill-usage telemetry exists.”
[Why]: Subjective reconstruction is prone to recency and confirmation bias; the spec itself cites SkillsBench results that “self-generated skills fail,” yet offers no mitigation for the same risk in its own evidence process.
[Fix]: Add a mandatory cross-check: at least one operator review pass over the proposed manifest with a “dispute window” before IMPLEMENT, plus a lightweight post-pruning usage log for the first 30 days.

F5
[Severity]: MINOR
[Finding]: The four optimization axes are listed repeatedly, but “ceremony reduction” (VO-007) is not given an explicit success metric beyond “diff … with ceremony rationale.”
[Why]: Without a measurable target (e.g., “reduce protocol length by ≥30 % while preserving all hook-enforced behaviors”), the task risks either cosmetic edits or unintended loss of guardrails.
[Fix]: Define a numeric or checklist-based acceptance criterion for ceremony reduction before TASK refinement.

F6
[Severity]: STRENGTH
[Finding]: The explicit “stop-and-ask” constraint on CLAUDE.md edits and the clear sequencing note that vault-optimization follows agentic-sunset together prevent accidental concurrent modification of the constitution.
[Why]: This directly addresses the shared-surface risk highlighted in the cross-project dependencies section and reduces a major source of merge or semantic conflicts.

F7
[Severity]: SIGNIFICANT
[Finding]: Assumption A2 states that git history rewrite is out of scope “unless separately decided,” yet U4 later flags operator appetite for exactly that rewrite as an open unknown; no decision gate is placed in the task list.
[Why]: If the operator later elects a rewrite after `Archived/` deletion has begun, the working-tree deletions already performed cannot be recovered from history that no longer exists.
[Fix]: Insert a new lightweight task (VO-004a) immediately after VO-004 that forces an explicit yes/no decision on history rewrite before any mass deletion begins.

F8
[Severity]: MINOR
[Finding]: The domain classification states “vault-only — no external repo,” yet the levers section references external signals (trq212, skillsbench) and cross-project dependency tracking in `_system/docs/cross-project-deps.md` without confirming those files survive the aggressive deletion pass.
[Why]: Minor documentation inconsistency that could confuse future readers if the referenced files are among the pruned set.

*(Response ended here — F8 has no [Fix]; finish_reason was `stop`, so this is the model's full output, not truncation.)*

---

## Synthesis (Claude, 2026-06-10)

**Grok calibration watch (review 1 of 2–3):** All GRK findings verified against the artifact before synthesis. GRK-F1–F6: accurate. **GRK-F7: misread** — it claims no git-history decision gate exists in the task list, but VO-004 explicitly contains "explicit git-history-rewrite decision (default: out of scope)" and VO-008 depends on VO-004, so the decision sequences before any deletion. GRK-F8: noise (cross-project-deps.md is trivially in the keep-set). **Tally: 0 fabrications, 1 misread, 1 noise out of 8 findings.** Acceptable first showing; watch continues.

### Consensus Findings

1. **AS boundary underdefined at task level — scope collision risk on skills/memory** (OAI-F3, GEM-F1 [CRITICAL], DS-F7, GRK-F1 — 4/4 reviewers). "Boundary settled at task level" names no mechanism, artifact, or gate. Strongest single finding of the review.
2. **VO-008 irreversibility controls insufficient** (OAI-F5, OAI-F6, GEM-F6, DS-F2, GRK-F3 [CRITICAL] — 4/4). "Backup verified" has no defined verification method; no restore drill, no batch/checkpoint model, no partial-pass abort/revert procedure.
3. **Usage-evidence methodology too thin** (OAI-F7, OAI-F8, GEM-F5, DS-F3, GRK-F4 — 4/4). No type-specific evidence standards; "no evidence" over-weighted (absence of evidence ≠ non-use, especially for contingency tools); no extraction protocol or timebox.
4. **UNVERIFIABLE CLAIM cluster: inventory numbers + signal citations** (OAI-F24–28, GEM-F3/F4, DS-F5/F6, GRK-F2 — 4/4). Expected for external reviewers without filesystem access, but the fix is cheap and right: reproducible inventory commands + pinpoint citations.
5. **Missing consumer-graph *remediation* step** (GEM-F2 [CRITICAL]; echoed by OAI-F10 and OAI focus-answer 2). VO-003 surveys consumers, VO-008 deletes — no task owns *updating* the referencing files. As written, deletion would instantly violate the vault-check-green constraint.
6. **No functional validation that the pruned core still works** (DS-F4, GEM focus-answer 4, OAI-F23). Structural checks (links, vault-check) can pass while reasoning workflows silently degrade. Success is currently measured only by what is removed.
7. **VO-001 lacks a failure branch** (OAI-F13, GEM-F7). If ADR review reveals material identity drift, nothing stops downstream tasks proceeding by inertia.
8. **Canonical end-state artifact missing** (OAI-F4, OAI-F20; reinforced by GEM focus-answer 4). Accepting the ADR settles identity but doesn't produce the operational "what must remain + how to judge future additions" artifact this project exists to create.

### Unique Findings

- **OAI-F11 / working-tree vs repo-size expectations** — genuine insight. Deleting `Archived/` from HEAD does not shrink clone size; the spec's weight statistics create an implicit expectation A2 quietly defeats. Worth making explicit in VO-004.
- **OAI-F12 / dormant-marking contradicts aggressive deletion** — genuine. VO-006's AC predates the disposition decision in spirit; retention policy for superseded docs needs one consistent rule.
- **OAI-F21 / non-markdown weight audit** — genuine and cheap (top-N size offenders across the repo).
- **OAI-F16 / liberation-directive line → interruptibility constraint** — genuine; converts a context note into an execution property (commit-level interruptibility), which also serves consensus finding 2.
- **OAI-F22 / "vault-only" vs harness-memory surfaces** — genuine, wording-level.
- **DS-F1 / VO-007 missing dependency on VO-002** — genuine; ceremony reduction can't target "kept workflows" before the keep-set exists.
- **GEM "statute of limitations" delete heuristic** — noise (see Declined).
- **GRK-F5 / ceremony reduction needs a success metric** — genuine but premature at spec level; defer to TASK.

### Contradictions

- **Evidence stance:** GEM-F5 proposes "if usage cannot be found within 15 minutes, assume unused" — OAI-F7 argues the opposite (no-evidence items get *mandatory operator review*, never auto-delete). These are irreconcilable; flagged for operator. Synthesis recommendation: adopt OAI's stance (conservative on no-evidence), adopt GEM's *timeboxing* for the search effort only.
- **Boundary fix shape:** GEM-F1 proposes *rescoping* ownership (AS does all deletion, or VO does); OAI-F3 proposes an *ownership matrix* within current scope. The operator decision (AS keeps M6) rules out rescoping — ownership-matrix fix adopted.

### Action Items

**Must-fix (spec amendment before PLAN):**
- **A1** (OAI-F3, GEM-F1, DS-F7, GRK-F1): Add a **joint-surface contract** deliverable — per-surface ownership matrix (AS-owned / VO-owned / jointly-reviewed / blocked-until-AS-close), produced as a VO-002 appendix; entry criterion for VO-005/VO-007: matrix frozen + AS M6 closure sign-off in run-log.
- **A2** (OAI-F5/F6, GEM-F2/F6, DS-F2, GRK-F3): Rewrite VO-008 acceptance criteria as an **execution model**: defined backup-verification procedure (freshness check + restore drill of a sample set on a throwaway clone + ignored-path coverage), batched deletions with atomic commit checkpoints, consumer-remediation inside each batch (survey→fix→delete→verify), explicit abort/revert condition if vault-check turns red, partial-pass rule (finish or revert batch before stopping), commit-level interruptibility (absorbs OAI-F16).
- **A3** (OAI-F7/F8, GEM-F5, DS-F3, GRK-F4): Add an **evidence methodology** to VO-002: type-specific evidence standards per primitive class; five-category disposition rubric (proven use / structural necessity / contingency keep / superseded / no-evidence-no-dependency); mechanical extraction protocol with timebox; mandatory operator review of every no-evidence deletion.
- **A4** (OAI-F4/F20, DS-F4, GEM focus-4): Add **Deliverables / end-state** section: accepted ADR, core-functionality operating note (with future-addition decision rubric), keep-set manifest, storage policy, reduced primitive surface — plus a **VO-009 functional validation** task: representative core workflows executed during soak; failures block completion.

**Should-fix:**
- **A5** (OAI-F13, GEM-F7): VO-001 gets a decision gate: minor ADR drift → proceed; material identity change → re-plan before VO-002.
- **A6** (DS-F1): VO-007 dependencies gain VO-002.
- **A7** (OAI-F11, OAI-F21): VO-004 distinguishes working-tree weight vs navigation weight vs repo/history size (state what will *not* shrink without rewrite); add non-markdown top-N size audit.
- **A8** (OAI-F12): One retention rule for superseded docs consistent with aggressive deletion (delete unless canonical-reference or compound-provenance; no vague dormant-marking).
- **A9** (OAI-F24–28, GEM-F3/F4, DS-F5/F6, GRK-F2): Ground the spec: inventory reproduction commands recorded + regenerate baseline at TASK start; pinpoint citations (vault paths) for the two signals and the health-assessment claim.

**Defer:**
- **A10** (GRK-F5, OAI-F14): operational definitions for "short soak" / ceremony metrics — define at TASK refinement.
- **A11** (OAI-F15): Archived/-as-category taxonomy cleanup — fold into VO-006 execution detail.
- **A12** (OAI-F22): wording fix on vault-only vs harness-memory coordination — fold into A1's matrix.

### Considered and Declined

- **GRK-F7** — `incorrect`: VO-004 already contains the explicit git-history-rewrite decision, sequenced before VO-008 via the dependency chain.
- **GEM-F5 (auto-delete heuristic part)** — `incorrect`: "if not found in 15 minutes, assume unused" inverts the burden of proof for irreversible deletions; contradicted by OAI-F7 and by the contingency-tool false-negative risk. The timebox survives in A3; the auto-delete default does not.
- **GEM-F1 (rescoping fix alternative)** — `constraint`: operator decision 2026-06-10 locks AS ownership of M6; ownership matrix (A1) resolves the collision without rescoping.
- **GRK-F8** — `out-of-scope`: `cross-project-deps.md` is core `_system` tracking, trivially in the keep-set; noise.
- **OAI-F16 (remove-the-line option)** — `constraint`: liberation-directive reference is CLAUDE.md-mandated context; adopted instead as interruptibility constraint in A2.

### Verdict

Spec is structurally sound (sequencing, consumer-graph discipline, and manifest controls drew STRENGTH ratings from all four reviewers) but **not ready for PLAN until the four must-fix amendments land**: joint-surface contract, VO-008 execution model, evidence methodology, and end-state deliverables + functional validation.
