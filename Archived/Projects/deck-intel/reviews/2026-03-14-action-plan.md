---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/deck-intel/design/action-plan.md
artifact_type: action-plan
artifact_hash: 2e4f40b1
prompt_hash: 3b1b391c
base_ref: null
project: deck-intel
domain: software
skill_origin: peer-review
created: 2026-03-14
updated: 2026-03-14
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "soft: 'customer' appears in spec summary context (business domain term, not PII)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 47925
    attempts: 1
    raw_json: Projects/deck-intel/reviews/raw/2026-03-14-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 36768
    attempts: 1
    raw_json: Projects/deck-intel/reviews/raw/2026-03-14-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 154140
    attempts: 2
    raw_json: Projects/deck-intel/reviews/raw/2026-03-14-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 31407
    attempts: 1
    raw_json: Projects/deck-intel/reviews/raw/2026-03-14-action-plan-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Deck Intel Action Plan

**Artifact:** Projects/deck-intel/design/action-plan.md (+ tasks.md)
**Mode:** full
**Reviewed:** 2026-03-14
**Reviewers:** OpenAI gpt-5.2, Google gemini-3-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning
**Review prompt:** Action plan and task breakdown review evaluating coverage, sequencing, task sizing, risk calibration, acceptance criteria quality, and feasibility.

---

## OpenAI (gpt-5.2)

- [F1]
  - [Severity]: CRITICAL
  - [Finding]: Spec decisions D1–D10 are referenced, but the plan/tasks don’t enumerate them anywhere, so “covers D1–D10” is not auditable.
  - [Why]: This makes DI-003 acceptance criteria non-testable and risks silent omission of an approved requirement.
  - [Fix]: Add a short “D1–D10 checklist” section to the action plan (or as an appendix in SKILL.md) mapping each decision to the exact procedure step/output location; update DI-003 acceptance criteria to require that checklist is present and complete.

- [F2]
  - [Severity]: SIGNIFICANT
  - [Finding]: The “Specification Summary” document is marked `status: draft` while the prompt context says the spec has been approved and peer-reviewed.
  - [Why]: This is a governance mismatch; implementers may treat requirements as unstable or miss that the plan is meant to implement an approved spec.
  - [Fix]: Update the summary metadata to reflect approval (or add an “approved in …” line). If the summary is intentionally draft, add a task to reconcile/confirm the authoritative source (specification.md) before coding.
  - [Fix qualifier]: **UNVERIFIABLE CLAIM:** spec “has been approved and peer-reviewed” vs summary `status: draft`.

- [F3]
  - [Severity]: SIGNIFICANT
  - [Finding]: MOC one-liner placement depends on `kb-to-topic.yaml` behavior, but no task verifies that routing works end-to-end (read/update/idempotency) in the actual vault environment.
  - [Why]: MOC integration failures are common “last mile” issues; the skill could generate notes correctly but fail retrieval/navigation, undermining the whole purpose.
  - [Fix]: Add a dedicated task (e.g., DI-00X) to validate MOC insertion against `kb-to-topic.yaml` in a sandbox vault: verify correct target MOC, idempotent update, and vault-check passes after insertion.

- [F4]
  - [Severity]: SIGNIFICANT
  - [Finding]: “Overlay index verified (no changes expected)” is treated as low risk and depends on DI-003, but overlay needs are often discovered during real-file validation (M2/M3) rather than from SKILL.md alone.
  - [Why]: You can “verify” early and still end up needing an overlay adjustment once you see actual competitive/networking classification patterns and note structure.
  - [Fix]: Keep DI-004 but add a second checkpoint after DI-006/DI-007 (or fold into DI-008 polish) that reconfirms overlays based on observed failures/friction.

- [F5]
  - [Severity]: SIGNIFICANT
  - [Finding]: Dependency verification is underspecified for diagram/image extraction: PyMuPDF + LibreOffice are listed, but there’s no explicit task to verify diagram-capture works in “composable mode” for both PPTX (rendered slides) and PDF (embedded images/pages) with the chosen toolchain.
  - [Why]: The core value includes “diagram preservation.” If diagram-capture integration breaks, the skill may still pass text-only tests but violate a key spec decision.
  - [Fix]: Add a test task between DI-002 and DI-003 (or expand DI-002) to run diagram-capture on a sample PPTX and PDF and confirm images land in `_attachments/` with expected naming and count.

- [F6]
  - [Severity]: MINOR
  - [Finding]: DI-001 acceptance criteria “LibreOffice headless converts PPTX to PDF” is good, but it doesn’t specify the exact command invocation/flags expected by diagram-capture (e.g., headless mode, output path).
  - [Why]: Slight mismatch between how you test LO and how the pipeline uses it can cause later failures.
  - [Fix]: Amend DI-001 acceptance criteria to include the exact conversion command and confirm output is deterministic (same number of pages/slides) and stored where diagram-capture expects.

- [F7]
  - [Severity]: SIGNIFICANT
  - [Finding]: The deletion safety gate is described, but there’s no explicit negative test case: ensure binaries are *not* deleted when any of the 4 checks fail (especially image extraction failure and vault-check failure).
  - [Why]: Deletion is irreversible and high-stakes; you need explicit fail-closed behavior validated, not only “fires all 4 checks.”
  - [Fix]: Add acceptance criteria to DI-005/DI-006 (and batch) to intentionally induce each failure mode (or at least 1–2 representative ones) and verify the binary remains.

- [F8]
  - [Severity]: SIGNIFICANT
  - [Finding]: “All knowledge notes pass vault-check” is required, but there’s no task to ensure vault-check is installed/available and to lock down what “pass” means (command, config, failure output handling).
  - [Why]: If vault-check isn’t present or behaves differently across environments, validations become non-reproducible.
  - [Fix]: Add a setup/verification step (could be part of DI-001 or a new DI-00X) that runs vault-check on a known-good note and documents the command used; update DI-003 error-handling section to specify vault-check invocation and remediation messaging.

- [F9]
  - [Severity]: MINOR
  - [Finding]: DI-002 uses “output > 200 chars for both” as acceptance criteria, but the spec’s 200-char threshold is specifically for image-heavy PDF detection; it’s not necessarily appropriate for PPTX (e.g., a diagram-heavy deck with minimal text).
  - [Why]: This could cause false failures during setup even though behavior is acceptable (and might need visual-first mode for PPTX too, depending on reality).
  - [Fix]: Change DI-002 criteria to: (a) markitdown successfully extracts *some* text + speaker notes from PPTX; (b) for PDF, verify both a normal text PDF (>200 chars) and an image-heavy PDF (<200 chars) to exercise the threshold logic.

- [F10]
  - [Severity]: SIGNIFICANT
  - [Finding]: Batch ceiling (3–5 files) is mentioned in spec and DI-003 requires “batch ceiling documented,” but DI-007 only tests 2–3 files and doesn’t validate behavior near the ceiling.
  - [Why]: The ceiling is a key operational constraint for context pressure; you want confidence that the skill guards or at least warns at the upper bound.
  - [Fix]: Update DI-007 to test at least 3 files (minimum) and optionally 5 (max) or add a check that the skill warns/refuses beyond the documented ceiling.

- [F11]
  - [Severity]: MINOR
  - [Finding]: Task sizing is mostly OK (few files touched), but DI-003 “Write SKILL.md” bundles a lot: procedure, context contract, error handling, deletion gate, batch behavior, diagram-capture integration details.
  - [Why]: This is likely still one file change, but cognitively it’s large and a common source of churn.
  - [Fix]: Keep DI-003 as one task if it truly is one file, but add an intermediate review checklist (structure, safety gate, batch mode, outputs) to reduce rework; or split into DI-003a (skeleton + frontmatter/output spec) and DI-003b (error handling + deletion gate + batch).

- [F12]
  - [Severity]: CRITICAL
  - [Finding]: No explicit task validates the “source binaries are deleted after synthesis” behavior in a way that is safe in dev/test (e.g., using copies, test inbox folder, or a dry-run flag).
  - [Why]: Implementing and testing deletion without a safe harness risks accidental data loss during development/validation.
  - [Fix]: Add a task (or expand DI-005/DI-006) to define a test harness: copy files into a dedicated `_inbox/test-deck-intel/` or use duplicates; verify deletion only occurs in that sandbox; document safe testing procedure in SKILL.md.

- [F13]
  - [Severity]: SIGNIFICANT
  - [Finding]: Cross-references are only mentioned in DI-007 (“Cross-references noted between overlapping sources”), but the spec explicitly says “Manual CI linkage via shared #kb/ tags — no automatic cross-referencing.” This can be interpreted as conflicting.
  - [Why]: Ambiguity could lead to building unintended automatic linking behavior or, conversely, missing a desired “mention overlap” section that’s still manual.
  - [Fix]: Clarify in DI-007 acceptance criteria: cross-reference means “human-readable note section ‘Overlaps/Related sources’ with suggested tags,” not automatic links into dossiers or automatic graph edges.

- [F14]
  - [Severity]: MINOR
  - [Finding]: Risk levels for deletion-related items are understated: DI-005/DI-006 are “medium” but include irreversible deletion and safety gates.
  - [Why]: Risk levels should reflect potential impact, not just implementation complexity.
  - [Fix]: Raise DI-005 and DI-006 risk to “high” (or introduce “high” if your taxonomy supports it), and treat deletion-gate negative tests as mandatory.

- [F15]
  - [Severity]: STRENGTH
  - [Finding]: Milestones map cleanly to build → single-file validation → batch/polish; tasks align well with that progression.
  - [Why]: This sequencing reduces compounding variables and makes failures easier to localize.
  - [Fix]: None.

- [F16]
  - [Severity]: STRENGTH
  - [Finding]: Acceptance criteria frequently include concrete, observable outputs (attachments naming, inline embeds, vault-check pass, idempotent MOC line, skip-on-failure).
  - [Why]: This supports binary verification and reduces “done-ness” ambiguity.
  - [Fix]: None.

- [F17]
  - [Severity]: SIGNIFICANT
  - [Finding]: The plan assumes availability of “a real vendor PPTX (Infoblox competitive deck or similar)” and “a real PDF” without addressing confidentiality/sanitization or availability.
  - [Why]: If real decks can’t be used in dev, validation blocks; if they can, you need a safe handling approach given deletion behavior and attachment extraction.
  - [Fix]: Add an explicit assumption + fallback: maintain a small sanitized test corpus (one PPTX with speaker notes + diagrams; one text PDF; one image-heavy PDF) stored in a safe internal repo or fixtures folder.

- [F18]
  - [Severity]: SIGNIFICANT
  - [Finding]: DI-004 claims “Existing overlay signals cover deck-intel use cases (Business Advisor for competitive, Network Skills for networking)” which may be true but isn’t verifiable from the artifact alone.
  - [Why]: Overlay mismatches can change tone, taxonomy, or output structure; asserting coverage without evidence risks subtle quality issues.
  - [Fix]: Require DI-004 to cite specific overlay IDs/signals from the overlay index and include a short before/after test prompt showing activation.
  - [Fix qualifier]: **UNVERIFIABLE CLAIM:** specific overlay coverage (“Business Advisor… Network Skills…”) without the overlay index content.

Summary of key recommended changes:
- Add an auditable D1–D10 checklist (F1).
- Add explicit diagram-capture composable verification and deletion fail-closed negative tests (F5, F7, F12).
- Tighten governance/assumptions (spec status, test corpus availability) and clarify cross-reference intent (F2, F13, F17).

---

## Google (gemini-3-pro-preview)

Here is the structured review of the action plan and task breakdown for the `deck-intel` skill:

- **[F1]**
- **Severity:** CRITICAL
- **Finding:** Validation tasks (DI-005, DI-006) do not mandate using *copies* of real files for testing. 
- **Why:** The core feature of this skill involves permanently deleting the source binary after a safety gate. Testing a newly written deletion script on real, non-replicated files poses an unacceptable risk of permanent data loss if the safety gate logic fails or contains a bug during initial validation.
- **Fix:** Update the descriptions and acceptance criteria for DI-005, DI-006, and DI-007 to explicitly state: "Use disposable *copies* of real vendor PPTX/PDFs to prevent accidental data loss during deletion gate testing." Elevate risk levels on these tasks to HIGH due to the data destruction element.

- **[F2]**
- **Severity:** SIGNIFICANT
- **Finding:** Missing acceptance criteria for key output and configuration constraints (`campaign:` frontmatter, filename format, and `model_tier`).
- **Why:** The spec explicitly requires campaign tracking via a `campaign:` frontmatter list, specific file naming (`[source_id]-digest.md`), and the use of `model_tier: reasoning`. None of these are verified in the tasks. Without explicit ACs, these critical details might be overlooked during implementation.
- **Fix:** 
  - Add to DI-003 AC: "Specifies `model_tier: reasoning`, filename format `[source_id]-digest.md`, and includes `campaign:` list in frontmatter template."
  - Add to DI-005/DI-006 AC: "Knowledge note filename is correctly formatted as `[source_id]-digest.md`; frontmatter includes valid `campaign:` field."

- **[F3]**
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: "Existing overlay signals cover deck-intel use cases (Business Advisor for competitive, Network Skills for networking)."
- **Why:** I cannot independently verify the current state of your Crumb overlay index or whether "Business Advisor" and "Network Skills" actually exist and map correctly to `deck-intel` signals. 
- **Fix:** Proceed with DI-004 as planned, but treat this assumption as a hypothesis to be validated rather than a known fact.

- **[F4]**
- **Severity:** MINOR
- **Finding:** Ambiguous reference to spec decisions "D1-D10" in DI-003.
- **Why:** The acceptance criteria for DI-003 states "procedure covers all spec decisions D1-D10", but the provided specification summary uses bullet points without explicit alphanumeric D-tags. This could cause confusion on whether all items have been met.
- **Fix:** Update DI-003 AC to simply read "procedure covers all Key Decisions outlined in the specification summary."

- **[F5]**
- **Severity:** MINOR
- **Finding:** Metadata contradiction regarding approval status.
- **Why:** The system prompt context states "The spec has been approved and peer-reviewed," but the specification summary artifact metadata lists `status: draft`.
- **Fix:** Update the specification summary frontmatter to `status: active` or `status: approved` to align with project reality.

- **[F6]**
- **Severity:** STRENGTH
- **Finding:** The 4-check deletion safety gate is exceptionally well-designed.
- **Why:** Requiring extraction confirmation, write confirmation, image preservation confirmation, and manual user confirmation before deleting binaries represents excellent defensive engineering. Mapping this gate directly into the test plans (DI-005) ensures the safety constraints are proven before routine use.

- **[F7]**
- **Severity:** STRENGTH
- **Finding:** Granular handling of PDF edge cases.
- **Why:** DI-006 properly isolates the image-heavy (< 200 chars) PDF scenario. Explicitly testing the visual-only fallback ensures the skill won't silently fail or drop data when handed scanned or heavily graphic analyst reports. Sequencing dependency testing (DI-002) before logic writing (DI-003) also ensures the technical feasibility of this constraint is proven early.

---

## DeepSeek (deepseek-reasoner)

**Structured Review**

**F1**  
**Severity:** STRENGTH  
**Finding:** Comprehensive requirement mapping between spec, action plan, and tasks.  
**Why:** The task breakdown (DI-001 through DI-008) directly implements all key decisions from the spec summary (campaign tracking, deletion safety gate, diagram-capture integration, batch ceiling, etc.). No major spec element is omitted.

**F2**  
**Severity:** STRENGTH  
**Finding:** Logical and safe task sequencing with clear dependencies.  
**Why:** Tasks are ordered to validate foundational dependencies (DI-001, DI-002) before skill authoring (DI-003), then validation (DI-005, DI-006), then batch and polish (DI-007, DI-008). Parallelization of DI-001 and DI-002 is implied and appropriate.

**F3**  
**Severity:** MINOR  
**Finding:** Inconsistent numbering in spec summary's "Acceptance Status" list.  
**Why:** The spec summary's checklist references DI-001 through DI-005, but the full task list goes up to DI-008. This creates a minor documentation mismatch.  
**Fix:** Update the spec summary's "Acceptance Status" to reflect the complete task list (DI-001 through DI-008) or replace with a generic placeholder.

**F4**  
**Severity:** SIGNIFICANT  
**Finding:** Acceptance criteria for DI-003 ("Write SKILL.md") are broad and partially subjective.  
**Why:** Criteria like "procedure covers all spec decisions D1-D10" and "follows authoring conventions" are not binary-testable without a detailed checklist. This could lead to ambiguity during sign-off.  
**Fix:** Supplement the criteria with a concrete checklist (e.g., "Skill file includes: a. `model_tier: reasoning` in context contract, b. 4-check deletion gate with user confirmation prompt, c. Batch ceiling of 5 documented, etc.").

**F5**  
**Severity:** SIGNIFICANT  
**Finding:** Acceptance criteria for DI-004 ("Verify overlay index coverage") are vague.  
**Why:** "Existing overlay signals cover deck-intel use cases" is not a binary test. The outcome could be subjective, and the task's low-risk rating assumes no changes are needed.  
**Fix:** Define a testable criterion: e.g., "Running the skill with a sample PPTX tagged with `#competitive` triggers the 'Business Advisor' overlay, as confirmed in logs or output."

**F6**  
**Severity:** MINOR  
**Finding:** Task DI-008 ("Polish and refinement") is vague and could be a catch-all.  
**Why:** While post-validation polish is necessary, the task's description ("Friction points... addressed") is open-ended and could expand beyond the intended ≤5 file changes scope.  
**Fix:** Scope the task to "Adjust SKILL.md based on validation findings; limit changes to noise-filtering rules, body structure templating, or shelf-life format."

**F7**  
**Severity:** SIGNIFICANT  
**UNVERIFIABLE CLAIM:** The action plan states "Overlay index verified (no changes expected)."  
**Why:** This is a prediction about the state of an external system (the overlay index). If the overlay index does *not* already cover the required contexts (e.g., "Business Advisor"), the skill may function incorrectly. The low-risk rating for DI-004 depends on this assumption.  
**Fix:** Re-task DI-004 to "Verify and, if necessary, update overlay index to ensure deck-intel contexts are covered." Adjust risk to *medium*.

**F8**  
**Severity:** MINOR  
**Finding:** The dependency of DI-004 on DI-003 may be unnecessarily strict.  
**Why:** Overlay index verification could theoretically begin as soon as the skill's intended contexts are known (from the spec), before the full SKILL.md is written.  
**Fix:** Consider making DI-004 dependent only on the spec approval, not on DI-003, to allow parallel work. However, the current sequence is safe and acceptable.

**F9**  
**Severity:** STRENGTH  
**Finding:** Excellent risk calibration across tasks.  
**Why:** High-risk tasks are correctly identified as those involving core logic and first validations (DI-003, DI-005, DI-006). Setup and later-stage tasks are appropriately rated low-risk.

**F10**  
**Severity:** SIGNIFICANT  
**Finding:** A critical external dependency is implied but not explicitly called out as a task.  
**Why:** The skill depends on `diagram-capture` being available in a "composable mode." If this mode doesn't exist or requires configuration, it could block M1 and M2.  
**Fix:** Add an early task (or subtask within DI-001/DI-002): "Verify diagram-capture composable interface and its expected inputs/outputs for image extraction."

**F11**  
**Severity:** MINOR  
**Finding:** The task breakdown doesn't specify the location for test files used in validation tasks (DI-005, DI-006, DI-007).  
**Why:** This could lead to inconsistency during testing (e.g., using files in `_inbox/` vs. a separate test directory).  
**Fix:** Add a note to the task description: "Use representative PPTX/PDF files placed in `_inbox/` (or a designated test subdirectory) for validation."

**Summary:** The action plan and task breakdown are well-structured and comprehensive. The primary concerns are the need to clarify acceptance criteria (F4, F5), verify a key external dependency (F10), and re-evaluate an assumption about the overlay index (F7). With these adjustments, the plan appears highly feasible.

---

## Grok (grok-4-1-fast-reasoning)

[F1]  
[Severity]: SIGNIFICANT  
[Finding]: Coverage gap for "campaign: frontmatter list field" from spec key decisions.  
[Why]: Spec explicitly calls this out as a key decision for multi-campaign tagging, but no task or acceptance criterion (e.g., in DI-003) explicitly verifies its inclusion in SKILL.md or knowledge note output. Risks incomplete spec implementation.  
[Fix]: Add to DI-003 acceptance criteria: "campaign: frontmatter field included as optional list for multi-campaign tagging."

[F2]  
[Severity]: SIGNIFICANT  
[Finding]: Coverage gap for knowledge note filename algorithm (§2.2.4).  
[Why]: Spec requires "[source_id]-digest.md per §2.2.4 algorithm," but no task tests or verifies this naming convention in outputs during validation (DI-005, DI-006). §2.2.4 undefined here, leading to potential inconsistency.  
[Fix]: Add to DI-005/DI-006 AC: "Knowledge note filename follows [source_id]-digest.md per spec §2.2.4"; define or link §2.2.4 in action plan.

[F3]  
[Severity]: SIGNIFICANT  
[Finding]: UNVERIFIABLE CLAIM: "vault-check" referenced repeatedly (e.g., DI-005 AC "passes vault-check") without definition.  
[Why]: Cannot confirm if vault-check exists, what it tests (e.g., note structure, tags?), or if it's implemented. Breaks testability of core success criteria for knowledge notes.  
[Fix]: Define vault-check in action plan or DI-003 AC (e.g., "passes vault-check: valid YAML frontmatter, #kb/ tags, no syntax errors"); add task to verify/define it if missing.

[F4]  
[Severity]: SIGNIFICANT  
[Finding]: Assumption spec is finalized/approved unaddressed, despite spec status "draft" and "Next Actions" including "finalize knowledge note body structure (Q1)" and "Approve specification."  
[Why]: Action plan proceeds to implementation (M1: "incorporates all spec decisions"), but spec summary contradicts (draft, pending finalization). Risks building on incomplete spec (e.g., body structure).  
[Fix]: Add DI-000 setup task: "Confirm spec approval and finalize body structure"; update spec status before M1.

[F5]  
[Severity]: CRITICAL  
[Finding]: Spec acceptance status lists mismatched/wrong task IDs (e.g., "Skill file created (DI-001)" but actual DI-003; only 5 items vs. 8 tasks).  
[Why]: Creates confusion between spec summary and tasks; spec checkboxes don't align with plan, risking oversight of DI-004,007,008. Logical disconnect in artifacts.  
[Fix]: Correct spec summary task IDs to match (DI-003 for skill, etc.) or remove mismatched acceptance status section.

[F6]  
[Severity]: SIGNIFICANT  
[Finding]: Sequencing misses parallelization opportunities: DI-001 || DI-002; DI-004 independent of validations; DI-005 || DI-006 (both only dep DI-003).  
[Why]: Forces unnecessary sequential execution (e.g., DI-007 waits for both DI-005/006), inflating timeline without benefit. Action plan phases imply sequence but tasks allow parallel.  
[Fix]: Update depends_on: remove artificial chains (e.g., DI-004 none); note parallels in action plan (e.g., Phase 2a/2b concurrent).

[F7]  
[Severity]: MINOR  
[Finding]: Risk calibration low for DI-007 (batch validation).  
[Why]: Batch involves context management, cross-refs, error paths—higher stakes for degradation than single-file (medium); low understates potential for cascading failures.  
[Fix]: Raise to medium risk.

[F8]  
[Severity]: SIGNIFICANT  
[Finding]: Acceptance criteria not fully binary/testable: DI-005 "noise filtering produces shorter output"; DI-005 "MOC one-liner placed with idempotency."  
[Why]: "Shorter" subjective (vs. what baseline?); "idempotency" assumes existing pattern works but untested edge (e.g., re-run duplicates MOC?). Risks ambiguous pass/fail.  
[Fix]: Refine: "noise filtering output <50% raw markitdown length"; "MOC idempotency: re-run skill appends no duplicate."

[F9]  
[Severity]: SIGNIFICANT  
[Finding]: UNVERIFIABLE CLAIM: "Existing overlay signals cover deck-intel use cases (Business Advisor for competitive, Network Skills for networking)" (DI-004 AC, M1c).  
[Why]: Cannot verify overlays exist or match (e.g., does "Business Advisor" trigger correctly for vendor decks?). Risks skill misrouted post-implementation.  
[Fix]: Add testable AC: "Test overlay activation on sample input: confirm routes to expected MOCs (list them)."

[F10]  
[Severity]: MINOR  
[Finding]: Task sizing for DI-003 (Write SKILL.md) potentially oversized: incorporates 9+ procedure elements + error handling + batch.  
[Why]: Lists exceed "≤5 file changes" implicitly (one file, but complex logic risks bloat/iterations); could fragment for reviewability.  
[Fix]: Split into DI-003a (core procedure), DI-003b (safety gates/error handling).

[F11]  
[Severity]: SIGNIFICANT  
[Finding]: Feasibility blocker: Platform assumptions for LibreOffice/PyMuPDF (headless PPTX conversion, import fitz).  
[Why]: No mention of OS (e.g., macOS brew vs. Linux apt); failures common (e.g., LibreOffice headless on WSL). Risks DI-001 stall.  
[Fix]: Add to DI-001 AC: "Verified on target platform (specify: e.g., Ubuntu 22.04)"; include install commands.

[F12]  
[Severity]: MINOR  
[Finding]: Batch ceiling inconsistency: spec "3-5 files," but M3/DI-007 tests "2-3 files."  
[Why]: Under-tests upper limit/context pressure; edge case (4-5 files) unvalidated.  
[Fix]: Update DI-007 to "3-5 files including ceiling test."

[F13]  
[Severity]: STRENGTH  
[Finding]: Dependencies correctly mapped overall (e.g., validations after SKILL.md; batch after singles).  
[Why]: Logical flow prevents early testing of unbuilt skill; aligns with milestones. Edge: Handles skips well via per-file gating.  

[F14]  
[Severity]: STRENGTH
[Finding]: Acceptance criteria generally detailed and sufficient (e.g., DI-005 lists 10+ specifics covering spec elements like shelf life, diagrams, deletion).
[Why]: Enables binary end-to-end validation; covers deletions, images, errors. Edge: Multi-check gate robust.

---

## Synthesis

### Consensus Findings

**1. Test with copies, not originals** (OAI-F12, GEM-F1 — 2 reviewers)
Deletion is irreversible. Validation tasks should use disposable copies of real files, not originals. Both reviewers flag this as the highest operational risk during development.

**2. Diagram-capture composable mode unverified** (OAI-F5, DS-F10 — 2 reviewers)
The plan depends on diagram-capture running in composable mode but no task explicitly verifies this integration before the SKILL.md is written.

**3. Spec summary stale metadata** (OAI-F2, GEM-F5, GRK-F4, DS-F3 — 4 reviewers)
Spec summary still says `status: draft` and its acceptance status task IDs don't match the plan. Governance hygiene.

**4. Acceptance criteria gaps for campaign field and filename convention** (GEM-F2, GRK-F1, GRK-F2 — 3 reviewers)
Spec decisions D1 (campaign list) and D9 (source_id filename) aren't explicitly tested in validation tasks.

**5. Batch ceiling undertested** (OAI-F10, GRK-F12 — 2 reviewers)
DI-007 tests 2-3 files but the spec ceiling is 3-5. Upper bound untested.

**6. DI-003 acceptance criteria too broad** (OAI-F1, GEM-F4, DS-F4 — 3 reviewers)
"Covers all spec decisions D1-D10" isn't binary testable without an explicit checklist.

### Unique Findings

**OAI-F7: Deletion negative tests.** No task validates that binaries are *not* deleted when a safety gate check fails. Genuine insight — you need fail-closed verification, not just happy-path testing.

**GRK-F6: Parallelization opportunities.** DI-001 and DI-002 can run in parallel, DI-005 and DI-006 can run in parallel. Action plan phases imply this but task dependencies don't make it explicit.

**OAI-F3: MOC end-to-end validation.** MOC one-liner placement depends on `kb-to-topic.yaml` routing, but no task validates the full read → insert → idempotency chain. Valid concern — MOC integration is a common last-mile failure.

### Contradictions

None. Reviewers broadly agree on the same issues from different angles.

### Action Items

**Must-fix:**

- **A1** (OAI-F12, GEM-F1): **Use copies for deletion testing.** Add to DI-005, DI-006, DI-007: "Use disposable copies of test files. Verify deletion occurs on the copy, not originals."

- **A2** (OAI-F5, DS-F10): **Verify diagram-capture composable mode.** Expand DI-002 to include: run diagram-capture on a sample PPTX and PDF, confirm images extracted to `_attachments/` with expected naming.

- **A3** (OAI-F2, GEM-F5, GRK-F4, DS-F3): **Fix spec summary metadata.** Update `status: draft` → `status: active`. Align acceptance status task IDs with actual plan, or remove the stale section.

**Should-fix:**

- **A4** (GEM-F2, GRK-F1, GRK-F2): **Add campaign and filename to validation ACs.** DI-005/DI-006: "Knowledge note filename follows `[source_id]-digest.md`; frontmatter includes `campaign:` as optional list field."

- **A5** (OAI-F10, GRK-F12): **Batch ceiling test.** Update DI-007 to test 3-5 files (matching spec ceiling), not 2-3.

- **A6** (OAI-F7): **Deletion negative test.** Add to DI-005 or DI-006: "Intentionally trigger a safety gate failure (e.g., vault-check rejection); verify binary is preserved."

- **A7** (OAI-F1, GEM-F4, DS-F4): **D1-D10 checklist in DI-003 ACs.** Replace "covers all spec decisions D1-D10" with an enumerated checklist.

**Defer:**

- **D1** (OAI-F11, GRK-F10): DI-003 splitting — it's one file. Complexity is manageable.
- **D2** (OAI-F4): Overlay re-check after validation — DI-008 polish already covers this.
- **D3** (GRK-F11): Platform-specific install commands — we're on macOS, known environment.
- **D4** (GRK-F8): Noise filtering metric — calibrate after first extractions, not in advance.
- **D5** (DS-F8, GRK-F6): Parallelization — action plan phases already imply it. Formal dependency restructuring adds ceremony without value.

### Considered and Declined

- **GRK-F3** (vault-check undefined) — `incorrect`. vault-check is an established pre-commit hook in this project with 30 validation checks. Well-known to implementers.
- **GRK-F4** (spec needs finalization before M1) — `incorrect`. Q1 was resolved in this session during PLAN. Spec is approved.
- **OAI-F18, GEM-F3, DS-F7, GRK-F9** (overlay coverage unverifiable) — `incorrect`. Overlay index was read and verified in this session. Business Advisor and Network Skills exist and their activation signals cover competitive and networking content.
- **DS-F6** (scope DI-008 tightly) — `overkill`. Polish tasks are inherently scoped by M2/M3 findings. Pre-constraining defeats the purpose.
- **OAI-F8** (vault-check setup task) — `incorrect`. vault-check runs as pre-commit hook. Already installed and operational.
- **OAI-F14** (raise DI-005/006 risk to high) — `overkill`. Medium is correct with the copy-based testing approach (A1). The deletion risk is mitigated by the test harness, not elevated by the task.
