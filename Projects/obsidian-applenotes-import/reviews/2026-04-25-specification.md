---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/obsidian-applenotes-import/design/specification.md
artifact_type: specification
artifact_hash: 006a9fc7
prompt_hash: e6fcb540
base_ref: null
project: obsidian-applenotes-import
domain: software
skill_origin: peer-review
created: 2026-04-25
updated: 2026-04-25
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
    latency_ms: 106133
    attempts: 1
    raw_json: Projects/obsidian-applenotes-import/reviews/raw/2026-04-25-specification-openai.json
  google:
    http_status: 200
    latency_ms: 44966
    attempts: 1
    raw_json: Projects/obsidian-applenotes-import/reviews/raw/2026-04-25-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 63226
    attempts: 1
    raw_json: Projects/obsidian-applenotes-import/reviews/raw/2026-04-25-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 26793
    attempts: 1
    raw_json: Projects/obsidian-applenotes-import/reviews/raw/2026-04-25-specification-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: obsidian-applenotes-import specification

**Artifact:** Projects/obsidian-applenotes-import/design/specification.md
**Mode:** full
**Reviewed:** 2026-04-25
**Reviewers:** OpenAI gpt-5.4, Google gemini-3.1-pro-preview, DeepSeek deepseek-reasoner (V3.2-Thinking), Grok grok-4-1-fast-reasoning
**Review prompt:** Structured spec review with 5 focus areas — data-safety contract, AppleScript assumptions A1–A7, Obsidian submission compliance, task decomposition (esp. OAI-016/017/008/019), HTML→MD fidelity strategy.

---

## OpenAI (gpt-5.4)

Below is a structured review of the spec, focused on correctness, completeness, internal consistency, feasibility, clarity, and the requested focus areas.

---

## Overall Assessment

This is a strong SPECIFY-phase artifact: clear problem framing, explicit locked decisions, good decomposition, and unusually strong attention to safety and submission constraints. The biggest weakness is that a few assumptions are not merely implementation unknowns but **go/no-go product viability assumptions**, especially around Apple Notes deletion semantics, identity stability, and attachment extraction. Those should be pulled forward from “PLAN spike” into **pre-PLAN gating validation**.

The current verify-before-delete design is directionally good but not yet sufficient as a true data-safety contract. As written, it verifies only the markdown file content, not the full import outcome the user actually cares about.

---

# Findings

### F1
- **Severity:** CRITICAL
- **Finding:** The highest-risk assumption, **A4 (“AppleScript `delete` lands in Recently Deleted, not hard-delete”)**, is deferred to PLAN, but it is actually a **precondition for the entire product concept**.
- **Why:** If `delete` on a Notes note hard-deletes, behaves inconsistently by account/note state, or bypasses Recently Deleted in some cases, the core workflow becomes unsafe and the spec must materially change. This is not an implementation detail; it is a go/no-go product premise.
- **Fix:** Move A4 out of “Assumptions to validate during PLAN” into a **SPECIFY exit gate / pre-PLAN validation requirement**. Add a statement like: “Do not proceed to PLAN until deletion semantics are probe-confirmed on the target macOS/Notes versions.” Also validate edge cases: iCloud account note, On My Mac note, note with attachment, note in custom folder.

---

### F2
- **Severity:** CRITICAL
- **Finding:** The current **verify-before-delete contract is incomplete** because it verifies only the just-written markdown file hash, not the **full import state**, especially attachments and index persistence.
- **Why:** A note can be “verified” and then deleted even if:
  - attachments failed to write or only partially wrote,
  - markdown references attachment paths that don’t exist,
  - the import index failed to persist,
  - the receipt failed,
  - the markdown omitted unsupported content without surfacing a warning,
  - the attachment rewrite step produced broken links.
  
  If the plugin then soft-deletes the source note, the user may lose content fidelity despite the gate “passing.” That makes the verification partly theater.
- **Fix:** Redefine OAI-017 as a **composite import verification contract**:
  1. verify markdown file exists,
  2. verify markdown content hash matches expected rendered content,
  3. verify all expected attachment files exist and sizes are non-zero,
  4. verify all rewritten markdown attachment references point to existing files,
  5. verify import index save succeeded,
  6. only then permit delete.
  
  Update AC5 accordingly.

---

### F3
- **Severity:** CRITICAL
- **Finding:** The ordering in M6 says: “fetch → convert → write → verify → **index** → soft-delete,” but the system map says the import index drives idempotency and is a major safety lever. Deleting before ensuring durable index persistence creates a safety and UX hole.
- **Why:** If delete succeeds but index persistence fails, the note is gone from its original folder and may later appear re-importable or untracked. That weakens auditability and re-import gating. In destructive workflows, metadata durability is part of the transaction.
- **Fix:** Change the required order to: **fetch → convert → write attachments → write markdown → verify full import → persist index → verify index save/readback → soft-delete**. Consider including receipt append after delete, but not as a delete gate.

---

### F4
- **Severity:** CRITICAL
- **Finding:** The import index corruption strategy in OAI-012—“recover empty on parse error, surface Notice”—is unsafe for a destructive importer.
- **Why:** Recovering empty causes all prior imports to appear unimported, enabling accidental re-imports and duplicate creation. That may not be data loss by itself, but in conjunction with selective delete behavior and user trust, it is a serious safety regression.
- **Fix:** On index parse failure:
  - switch plugin into **safe degraded mode**,
  - disable delete-capable imports until index is repaired/rebuilt or user explicitly chooses a re-index action,
  - provide a recovery path by scanning frontmatter `apple_notes_id` in the vault to reconstruct index entries.
  
  At minimum, do **not** silently treat corruption as an empty index.

---

### F5
- **Severity:** SIGNIFICANT
- **Finding:** The spec treats “verified vault write” largely as protection against write failure, but not against **semantic conversion loss**.
- **Why:** For rich Apple Notes content, the highest user-perceived loss may not be file write failure; it may be dropped structures: scans, sketches, embedded files, inline layout, checklists, tables, captions, callouts, links, or mixed content. A byte-perfect saved markdown file can still be an unacceptable migration.
- **Fix:** Define a **conversion warning threshold**. For example: if unsupported element count > 0, import may continue but receipt and note frontmatter/log must record warnings. For certain classes (e.g., attachments referenced in HTML but not extracted), mark note as **errored / not deletable** rather than “best-effort imported.”

---

### F6
- **Severity:** SIGNIFICANT
- **Finding:** **A2 (stable identity via `id of note`)** is also close to a go/no-go assumption and should be validated before PLAN or at least before task lock.
- **Why:** The import index, re-import gating, provenance, and skip logic all rely on stable Apple Notes IDs. If IDs are not stable across restarts, account changes, or note duplication, the idempotency model fails.
- **Fix:** Elevate A2 to pre-PLAN validation alongside A4. Probe at least:
  - app restart,
  - note edit after restart,
  - note move between folders,
  - note in iCloud vs local account if available.

---

### F7
- **Severity:** SIGNIFICANT
- **Finding:** **A7 (attachment extraction path)** is underspecified for a v1 that promises attachments as a core goal and AC3.
- **Why:** Attachment handling is central, and the two candidate approaches have very different risk profiles:
  - AppleScript export may be limited or lossy by type.
  - Reading Notes cache/group container may be brittle, unsupported, privacy-sensitive, or App Store/macOS-version dependent.
  
  If neither works reliably for common attachment types, the product promise needs revision.
- **Fix:** Make A7 a **pre-PLAN spike requirement** or split v1 into explicit support tiers by attachment type. Add a support matrix to the spec: image, PDF, audio, document, scan, sketch/drawing, pasted file, link preview. Define which are import-blocking vs warning-only when unsupported.

---

### F8
- **Severity:** SIGNIFICANT
- **Finding:** OAI-008 includes a “decision-doc archived under `_system/docs/solutions/`,” which appears outside the plugin repo structure and may be inconsistent with the stated external repo and task scoping.
- **Why:** This creates ambiguity about where canonical technical decisions live. It may also conflict with a community plugin repo’s normal layout if interpreted literally.
- **Fix:** Specify the exact repo-local path for decision docs, e.g. `docs/decisions/` or `design/decisions/`. Keep implementation artifacts inside the plugin repo unless there is an explicit multi-repo document strategy.

---

### F9
- **Severity:** SIGNIFICANT
- **Finding:** OAI-017 says “compare to expected content hash captured pre-write,” but the system map says “compares its hash to the one captured immediately after `vault.create` returned.” These are **different contracts**.
- **Why:** Pre-write expected hash verifies deterministic render output. Post-write captured hash only proves read-your-write consistency and can mask transformation bugs if the wrong content was written consistently. This is an internal inconsistency in the spec’s safety model.
- **Fix:** Standardize on: **hash the expected markdown string before write**, write file, re-read file, compare re-read hash to expected hash. Do the same for each attachment using expected byte hashes when possible.

---

### F10
- **Severity:** SIGNIFICANT
- **Finding:** The acceptance criteria for listing notes (AC1: “lists ≥95% of the user’s Apple Notes within 5 seconds for a 1k-note library”) may be infeasible or too brittle for AppleScript and user-machine variability.
- **Why:** Community plugin acceptance should avoid hard performance promises that depend heavily on local Apple Notes state, indexing, iCloud status, machine speed, and AppleScript behavior. Also “95%” is vague without a denominator definition given known exceptions.
- **Fix:** Reframe AC1 into:
  - responsive UI requirement,
  - bounded initial feedback time,
  - progressive loading if needed,
  - explicit exclusion categories.
  
  Example: “Shows first visible results or loading progress within 2s; complete listing for 1k-note library in typical conditions within 5–10s; locked/shared/unreadable notes are explicitly counted and labeled.”

---

### F11
- **Severity:** SIGNIFICANT
- **Finding:** The spec lacks explicit handling for **partial-batch failure semantics**.
- **Why:** In a multi-select import, some notes may import and soft-delete successfully while others fail conversion, attachment extraction, or delete. Without a clearly specified batch policy, users may misunderstand what happened and retry dangerously.
- **Fix:** Add a batch transaction model:
  - note-level independence,
  - no all-or-nothing across batch,
  - per-note receipts with final statuses: imported+deleted, imported-not-deleted, skipped, failed,
  - final summary dialog after batch.
  
  Clarify whether execution continues after one note fails.

---

### F12
- **Severity:** SIGNIFICANT
- **Finding:** The TCC strategy is internally inconsistent: system map says “on plugin load, run a no-op probe,” but OAI-019 acceptance says “on first command invocation.”
- **Why:** Triggering TCC on load is poor UX and may prompt unexpectedly. Triggering on first command is more defensible. The inconsistency needs resolution.
- **Fix:** Lock one behavior. Recommended: **do not probe on plugin load**; probe on first user-initiated command only. Update system map and acceptance criteria to match.

---

### F13
- **Severity:** SIGNIFICANT
- **Finding:** The current TCC handling may not account for **non-deterministic Apple Events permission states** or differences in how denial surfaces from `osascript`.
- **Why:** On macOS, Automation permission behavior can vary by app identity, prior grants, and whether the parent app is Obsidian/Electron. Error matching may be fragile. If denial detection is wrong, users get a broken plugin with poor guidance.
- **Fix:** In OAI-019, require:
  - structured parsing of stderr/stdout/exit code combinations,
  - tested recognition of common Apple event denial strings/codes,
  - fallback message when denial cannot be distinguished from generic AppleScript failure,
  - README troubleshooting section.

---

### F14
- **Severity:** SIGNIFICANT
- **Finding:** Community submission compliance coverage is good, but the spec does not explicitly mention **repository hygiene items reviewers often notice**: no bundled secrets, no generated artifacts except release assets, clear install/build instructions, and a clean manifest/style/release triad.
- **Why:** These may not be strict platform API rules, but they matter for first-pass review. Since v1 is community-directory-bound, they are worth codifying.
- **Fix:** Add a distribution checklist item under M8:
  - `.gitignore` excludes `main.js` and dev artifacts,
  - release assets include only required files,
  - README has manual install steps,
  - screenshots reflect current UI,
  - manifest fields match release tag/version.

---

### F15
- **Severity:** SIGNIFICANT
- **Finding:** The spec does not explicitly handle **filename/path collisions across notes with same title and same target folder**, especially over time and re-import override.
- **Why:** Collision handling is mentioned generically in OAI-010, but destructive importers need deterministic provenance between Apple note ID and vault path. Otherwise repeated imports may create confusing `-2`, `-3` files without user understanding.
- **Fix:** Define path policy more concretely:
  - default filename from title,
  - collision suffixing,
  - index stores canonical chosen path,
  - re-import override behavior: new file, overwrite denied, or prompt.
  
  Recommend defaulting to **new unique file** on override, never overwrite silently.

---

### F16
- **Severity:** SIGNIFICANT
- **Finding:** The current frontmatter privacy warning is good, but the spec doesn’t decide whether `apple_notes_id` should be stored **verbatim** or **hashed/redacted** while still preserving idempotency.
- **Why:** Exposing CoreData URIs in synced/shared vaults may be undesirable. Since the ID is only needed locally for re-import gating, raw storage may not be strictly necessary.
- **Fix:** Consider dual representation:
  - local index stores raw Apple Notes ID,
  - frontmatter stores either raw ID with explicit warning (current plan) or a stable hash plus optional raw ID toggle in settings.
  
  If LD-09 locks exact field presence, note this as a future privacy enhancement but add README warning prominently.

---

### F17
- **Severity:** SIGNIFICANT
- **Finding:** HTML→markdown conversion via `turndown` may be insufficient for Apple Notes-specific HTML, especially **checklists, tables, attachment wrappers, scanned docs, sketches, and nested rich spans**.
- **Why:** Turndown is fine for general HTML, but Apple Notes often emits app-specific structures and attachment placeholders that require pre-processing. Without that, users may perceive imports as broken, not “best effort.”
- **Fix:** Keep `turndown`, but specify a **pre-normalization layer** before turndown:
  - map checklist HTML to markdown task lists,
  - rewrite image/file nodes to markdown links,
  - unwrap Apple Notes-specific spans/divs,
  - preserve unsupported blocks as fenced HTML blocks or warnings.
  
  Add fixture-based tests using **actual captured Apple Notes HTML** from probes, not synthetic examples only.

---

### F18
- **Severity:** SIGNIFICANT
- **Finding:** The “`> [!warning]` callout with collapsed source HTML” strategy may be problematic because collapsed callout behavior is theme/render dependent and raw embedded HTML can clutter notes.
- **Why:** What is intended as transparency may degrade readability, especially on many warnings. It also risks storing ugly implementation detail in user notes.
- **Fix:** Consider a tiered warning strategy:
  - compact frontmatter or receipt-level warning summary by default,
  - optional inline warning blocks only for severe omissions,
  - raw source HTML included only in receipt/debug mode, not in imported note by default.

---

### F19
- **Severity:** SIGNIFICANT
- **Finding:** OAI-016 and OAI-017 are under-scoped for their stated criticality.
- **Why:** A two-file orchestrator plus one-file verify task is unlikely to cover the number of failure cases involved: attachment extraction, folder creation, markdown write, binary writes, readback, hash, index persistence, delete, receipt, cancellation, and per-note rollback/continuation semantics.
- **Fix:** Split M6 into more granular tasks, e.g.:
  - import transaction model,
  - verify contract,
  - delete gate implementation,
  - batch execution/reporting,
  - cancellation/progress state.
  
  Re-rate OAI-016 as high and size it more realistically.

---

### F20
- **Severity:** SIGNIFICANT
- **Finding:** There is no explicit rollback or cleanup policy for **partially written vault artifacts when delete does not occur**.
- **Why:** If markdown writes but attachment extraction fails, or index save fails, the note remains in Apple Notes but the vault contains partial content. That may be acceptable, but it should be intentional and communicated.
- **Fix:** Define post-failure behavior:
  - either leave partial artifacts and mark as errored in receipt,
  - or delete incomplete outputs if safe.
  
  Recommended: leave artifacts only when markdown is complete and clearly mark “not source-deleted”; delete temp/incomplete attachment directories automatically.

---

### F21
- **Severity:** SIGNIFICANT
- **Finding:** The modal and UI specs do not mention **progress, cancellation, or long-running operation feedback**.
- **Why:** AppleScript operations and attachment extraction may take long enough that users perceive hangs. For destructive workflows, visible progress is also a trust feature.
- **Fix:** Add UI requirements for:
  - progress indicator per batch,
  - current note title/status,
  - cancel/stop-after-current behavior,
  - disabled controls while delete-capable import is running.

---

### F22
- **Severity:** MINOR
- **Finding:** The phrase “locked notes flagged not skipped” in OAI-005 acceptance is slightly ambiguous.
- **Why:** Elsewhere locked notes are expected to be skipped with reason if body fetch fails. Listing and importing behaviors should be distinguished.
- **Fix:** Reword to: “List includes locked notes when visible; marks `isLocked: true`; import pipeline skips them with explicit reason unless body fetch succeeds.”

---

### F23
- **Severity:** MINOR
- **Finding:** The plugin skeleton acceptance says “ribbon icon visible,” which may not be necessary for all users and can be noisy if the plugin is macOS-only and niche.
- **Why:** Community plugins often provide commands without requiring ribbon affordances. This is not wrong, just potentially unnecessary UI commitment.
- **Fix:** Consider making ribbon icon optional or deprioritized. Keep command palette entry mandatory.

---

### F24
- **Severity:** MINOR
- **Finding:** The receipt log is well-motivated, but “links to vault paths” should specify relative vault links vs plain text paths.
- **Why:** Clickable links make receipts materially more useful.
- **Fix:** Specify wikilinks or markdown links to imported note paths where possible, plus plain-text reasons for skipped/errored items.

---

### F25
- **Severity:** MINOR
- **Finding:** The settings model omits whether target, attachments, and receipts folders are validated on save or only on first use.
- **Why:** Early validation avoids runtime surprises and path bugs.
- **Fix:** Add settings validation behavior: normalize paths on save, reject empty/invalid folder names, and optionally auto-create on first import.

---

### F26
- **Severity:** MINOR
- **Finding:** AC4 says source note is in Recently Deleted “verified via probe,” but it does not specify whether this verification is automated, manual test protocol, or inferred behavior.
- **Why:** Acceptance criteria should distinguish product behavior from test method.
- **Fix:** Rephrase as: “Automated/manual integration test confirms deleted note is no longer in original folder and appears in Recently Deleted under supported test conditions.”

---

### F27
- **Severity:** STRENGTH
- **Finding:** The spec correctly identifies **verify-before-delete** as the single highest-leverage safety control and treats it as first-class design, not an implementation detail.
- **Why:** For a destructive workflow, making the delete gate explicit at spec level is exactly right.
- **Fix:** No change; strengthen as noted in F2/F3/F9.

---

### F28
- **Severity:** STRENGTH
- **Finding:** The locked decisions are clear, traceable, and reduce churn in later phases.
- **Why:** This is especially useful for avoiding re-litigation of core tradeoffs like AppleScript, soft-delete only, macOS-only, and best-effort conversion.
- **Fix:** No change.

---

### F29
- **Severity:** STRENGTH
- **Finding:** Submission compliance is unusually well integrated into the spec rather than treated as afterthought.
- **Why:** Calling out `isDesktopOnly`, `normalizePath`, no unsafe `innerHTML`, cleanup registration, adapter checks, and `main.js` handling materially reduces release risk.
- **Fix:** No change; just add a few repo hygiene items per F14.

---

### F30
- **Severity:** STRENGTH
- **Finding:** The task decomposition is generally coherent and dependency-aware, with sensible milestone grouping.
- **Why:** It shows good architecture separation: bridge, conversion, writer, index, UI, orchestrator, permissions, distribution.
- **Fix:** No change overall; refine safety-critical tasks per F19.

---

### F31
- **Severity:** STRENGTH
- **Finding:** The spec acknowledges privacy leakage from frontmatter `apple_notes_id`.
- **Why:** Many specs miss this kind of second-order effect. Calling it out early improves README and user trust.
- **Fix:** No change, though consider hash/redaction options per F16.

---

### F32
- **Severity:** UNVERIFIABLE CLAIM: SIGNIFICANT
- **Finding:** “`research-brief-plugin-platform.md` captured verified Obsidian platform context … pulled live from `obsidianmd/obsidian-developer-docs` and `obsidianmd/obsidian-sample-plugin` HEAD on 2026-04-25 — assume those facts are authoritative.”
- **Why:** I cannot independently verify the referenced file contents, repo HEAD state, or that the extracted facts are current/accurate without access to those sources.
- **Fix:** Before implementation, re-check the referenced upstream docs/repos and freeze exact links/commit SHAs in the design docs.

---

### F33
- **Severity:** UNVERIFIABLE CLAIM: SIGNIFICANT
- **Finding:** “Plugin id in `manifest.json` cannot contain the substring ‘obsidian’.”
- **Why:** I cannot independently verify this submission rule from the cited upstream docs in this review context.
- **Fix:** Ground this with an exact upstream citation or quote in the research brief.

---

### F34
- **Severity:** UNVERIFIABLE CLAIM: SIGNIFICANT
- **Finding:** “`eslint-plugin-obsidianmd` (0.1.9) is the official lint plugin and is already in the current sample template.”
- **Why:** I cannot independently verify the version number, official status wording, or current template inclusion.
- **Fix:** Pin this to a source URL/commit in the research brief and revalidate at implementation start.

---

### F35
- **Severity:** UNVERIFIABLE CLAIM: SIGNIFICANT
- **Finding:** “AppleScript `delete` against an Apple Notes note moves it to Recently Deleted (per Notes app behavior).”
- **Why:** This is exactly the kind of product-critical claim that cannot be accepted on authority here and needs empirical validation.
- **Fix:** Treat as unverified until probe-confirmed, per F1.

---

### F36
- **Severity:** UNVERIFIABLE CLAIM: SIGNIFICANT
- **Finding:** “Recently Deleted … 30-day retention.”
- **Why:** I cannot independently verify that retention duration is universally accurate across target Notes/macOS contexts.
- **Fix:** Verify empirically or cite Apple documentation; otherwise phrase as “Apple Notes’ normal Recently Deleted retention behavior” unless exact duration is sourced.

---

### F37
- **Severity:** UNVERIFIABLE CLAIM: SIGNIFICANT
- **Finding:** “`tell application "Notes" to get every note` returns within a few seconds for a vault of ~1,000 notes” as an assumed validation threshold.
- **Why:** This is a local performance claim, not a verified platform fact, and may vary widely.
- **Fix:** Keep it as a benchmark target, not an expectation. Validate with actual probes before cementing UX/performance ACs.

---

## Focus Area Responses

## 1) Data-safety contract

### Is the current safety design sufficient?
Not yet. It is good in intent but insufficient in scope.

### Main remaining failure modes
- markdown write succeeds, attachments fail or are incomplete,
- markdown references nonexistent attachment files,
- index save fails after delete,
- body conversion drops key content but still passes hash verification,
- note deleted after partial import due to weak gate,
- batch continues after a severe class of failure without clear reporting,
- index corruption causes unsafe re-import behavior.

### Is the verification meaningful?
**Partly meaningful, partly theater.**
It is meaningful as protection against:
- write failure,
- silent file truncation/corruption,
- mismatch between rendered markdown string and persisted markdown file.

It is theater if used as the sole delete gate while:
- attachments are not verified,
- link rewrites are not verified,
- index durability is not verified,
- semantic conversion omissions are not classified.

### Recommended delete gate
Delete only when all are true:
1. note body fetched successfully,
2. conversion completed with no delete-blocking omissions,
3. attachments extracted successfully for all referenced required attachments,
4. markdown written,
5. attachments written,
6. readback hashes match expected,
7. attachment references resolve,
8. import index persisted and readback succeeds.

---

## 2) AppleScript assumptions A1–A7: what should be validated before PLAN?

### Should anything move before PLAN?
Yes.

### Must validate before PLAN
- **A4** soft-delete semantics — absolutely pre-PLAN.
- **A2** stable note identity — strongly recommended pre-PLAN.
- **A7** attachment extraction viability — strongly recommended pre-PLAN if attachments remain in v1 goals.

### Should preferably validate before or at PLAN kickoff
- **A6** locked note behavior, because skip semantics affect listing/import model.
- **A5** TCC denial signatures, because UX/error handling depends on exact behavior.

### Can remain PLAN-stage
- **A1** raw performance ceiling,
- **A3** exact `body` HTML structure details, though collecting sample HTML now would help conversion planning.

### Bottom line
Deferring A4 is **not acceptable risk**. Deferring A2/A7 is risky enough that task decomposition may be invalid if they fail.

---

## 3) Community plugin submission compliance

### Adequately covered?
Mostly yes. This is one of the stronger parts of the spec.

### Potential gaps
- explicit release asset/version consistency process,
- `.gitignore`/artifact hygiene,
- clear README install/troubleshooting guidance,
- ensuring `styles.css` is included in release assets and tracked correctly,
- avoiding startup prompts/unexpected side effects on unsupported platforms,
- possibly ensuring command descriptions and manifest wording are polished for review.

### Likely rejection risks not yet explicit
- any unsafe DOM handling in modal implementation,
- poor README around macOS-only/TCC behavior,
- generated `main.js` committed accidentally,
- user-facing claims in README stronger than actual fidelity.

---

## 4) Task decomposition

### What’s good
- sensible architecture split,
- bridge before UI,
- index before modal gating,
- distribution last.

### Concerns
- **OAI-016/OAI-017** too large/underspecified for safety-critical behavior.
- **OAI-008** should likely happen earlier as a go/no-go spike before downstream tasks depend on it.
- **OAI-019** should be aligned with actual probe timing and include fallback detection logic.
- OAI-012 parse-error recovery policy is unsafe.
- Some tasks may exceed realistic complexity even if nominal file count is small; “≤5 file changes” is being used as a sizing proxy, but risk here is logic complexity, not file count.

### Dependency adjustments
- Make A4/A2/A7 validation prerequisites before locking M3/M5/M6 planning.
- Consider making OAI-008 a direct dependency for OAI-009 if attachment placeholder HTML affects conversion design.
- Make OAI-019 depend on actual behavior learned from OAI-004 plus dedicated probes.

---

## 5) HTML→markdown fidelity strategy

### Is `turndown` the right choice?
Reasonable default, but not sufficient by itself for Apple Notes.

### Risks
- Apple Notes-specific HTML wrappers,
- checklists may not map cleanly,
- drawings/sketches may not have meaningful HTML representations,
- scans/PDFs are attachment-like, not body-like,
- image grids/layout will likely flatten poorly,
- unsupported spans/styles may collapse.

### Better framing
Use `turndown` as the **core conversion engine**, with:
- pre-processing of Apple Notes HTML,
- attachment extraction/rewrite layer,
- explicit unsupported-content classification,
- real captured HTML fixtures.

### Is inline warning UX acceptable?
Potentially, if used sparingly. If every imported note contains noisy warning blocks, users will perceive the plugin as broken. Better:
- severe omissions block delete,
- moderate omissions log to receipt and maybe frontmatter,
- optional debug mode emits inline warning details/raw HTML.

---

# Recommended Spec Changes Before PLAN

1. Promote **A4** to pre-PLAN gate.
2. Promote **A2** and likely **A7** to pre-PLAN validation.
3. Redefine **verify-before-delete** as full import verification, not markdown-only.
4. Require **index persistence/readback success before delete**.
5. Replace “recover empty on parse error” with **safe degraded mode + rebuild path**.
6. Clarify **batch semantics**, partial failures, and cleanup policy.
7. Resolve TCC inconsistency: **probe on first user action, not plugin load**.
8. Add **progress/cancellation UX**.
9. Add a more explicit **attachment support matrix**.
10. Split or sharpen **OAI-016/OAI-017**.

If you want, I can also produce a **redlined revision list** of the exact spec sections to edit, or a **priority-ranked pre-PLAN validation checklist**.


---

## Google (gemini-3.1-pro-preview)

Here is a structured review of the specification for `obsidian-applenotes-import`.

### Unverifiable Claims
- **[F1]**
- **Severity**: SIGNIFICANT
- **Finding**: UNVERIFIABLE CLAIM: "`eslint-plugin-obsidianmd` (0.1.9) is the official lint plugin and is already in the current sample template."
- **Why**: I cannot independently verify third-party package versions, current sample repository states, or community rule changes as of 2026-04-25. If the template has moved to a newer linting standard (e.g., standard ESLint 9+ flat configs without this specific plugin), the submission could be flagged.
- **Fix**: Ground this claim by verifying `obsidianmd/obsidian-sample-plugin` package.json immediately prior to PLAN phase.

---

### Focus Area 1: Data-Safety Contract
- **[F2]**
- **Severity**: SIGNIFICANT
- **Finding**: The verify-before-delete contract (OAI-017) using a post-write read-and-hash is likely "cache theater" in the context of Obsidian's `FileSystemAdapter`.
- **Why**: Calling `app.vault.read()` immediately after `app.vault.create()` resolves will almost certainly read the file contents directly from Obsidian's internal cache or the OS filesystem buffer, rather than proving the file is durably synced to disk. If Obsidian crashes a millisecond later or iCloud evicts the file, the data could still be lost despite passing the verification gate.
- **Fix**: Accept that Obsidian's `vault.create` promise resolution is the highest verifiable guarantee available to plugins. Instead of hashing a cached string, verify the file's presence via `app.vault.getAbstractFileByPath` and confirm its size > 0. Additionally, implement a rollback mechanism in OAI-016: if attachment writing fails *after* markdown writing, clean up the orphaned markdown file.

### Focus Area 2: AppleScript Surface Assumptions
- **[F3]**
- **Severity**: CRITICAL
- **Finding**: Contradictory status of Assumption A4 (Soft Delete) and dangerous deferment of validation.
- **Why**: The "Facts" section states: *"AppleScript delete... moves it to Recently Deleted... user has confirmed this."* However, "Assumptions" lists **A4** (*"Validate: delete a throwaway test note via probe"*) and flags it as a core PLAN spike. If A4 proves false (e.g., if triggered via `osascript` it bypasses the 30-day bin), the entire plugin's value proposition and data-safety contract is destroyed. Deferring a fatal, spec-breaking assumption to the PLAN phase when it takes a 1-minute Terminal probe to test is an unnecessary project risk.
- **Fix**: Move the A4 probe to the SPECIFY phase (now) before authorizing PLAN. Resolve the contradiction in the text regarding whether the user has *already* verified this or if it is an unknown.

- **[F4]**
- **Severity**: SIGNIFICANT
- **Finding**: AppleScript attachment extraction (A7 / OAI-008) is notoriously brittle, and Apple Notes uses internal `obj` IDs rather than standard HTML references for embedded media.
- **Why**: `body of note` usually returns HTML with custom Apple XML objects. Extracting attachments and mapping them back to the specific location in the text requires parsing these internal IDs. Neither AppleScript export nor reading the `Group Containers` cache provides a simple mapping back to the note body.
- **Fix**: Add a dedicated spike task in M2 specifically to validate the mapping between inline HTML `<object>` tags and the extracted binary files.

### Focus Area 3: Submission Compliance
- **[F5]**
- **Severity**: STRENGTH
- **Finding**: High compliance awareness in the specification.
- **Why**: The spec correctly captures critical and often-missed submission gates: avoiding "obsidian" in the plugin ID, enforcing `isDesktopOnly: true` (crucial for `child_process`), using DOM creation instead of `innerHTML`, and explicitly tracking cleanup via `registerEvent`/`registerInterval`.

- **[F6]**
- **Severity**: MINOR
- **Finding**: Missing explicit mention of disabling commands on non-macOS platforms.
- **Why**: OAI-020 states the plugin loads inertly and shows a notice on first command invocation. However, Obsidian's best practice is to conditionally register commands, or not register them at all, if the platform is completely unsupported.
- **Fix**: Update OAI-020 to wrap command registration (OAI-015) in the `Platform.isMacOS` check, preventing the commands from appearing in the palette entirely on Windows/Linux.

### Focus Area 4: Task Decomposition
- **[F7]**
- **Severity**: CRITICAL
- **Finding**: Broken dependency graph for the safety-critical orchestrator (OAI-016).
- **Why**: OAI-016 lists its dependencies as `OAI-006, OAI-008, OAI-011, OAI-012`. It is missing **OAI-007** (Soft-delete script + wrapper). The orchestrator cannot execute the final soft-delete step without the module built in OAI-007.
- **Fix**: Add OAI-007 to the `Depends` column of OAI-016.

- **[F8]**
- **Severity**: MINOR
- **Finding**: M8 (Distribution) tasks depend on M6, but bypass M7 (Permission UX).
- **Why**: OAI-021 (README documentation) must include guidance on TCC permission denial, which is built in M7 (OAI-019). If OAI-021 executes before M7 is fully designed, the documentation will be incomplete.
- **Fix**: Change OAI-021 dependencies from `M6 complete` to `M6 and M7 complete`.

### Focus Area 5: HTML → Markdown Fidelity
- **[F9]**
- **Severity**: SIGNIFICANT
- **Finding**: The strategy of emitting `> [!warning]` callouts for unsupported elements requires custom Turndown rules, as Turndown silently drops unknown elements by default.
- **Why**: Turndown is not a DOM validator; if it encounters an unconfigured tag (like Apple's custom attachment objects or proprietary table wrappers), it extracts the text content and discards the tags without throwing errors or warnings. The converter built in OAI-009 will not natively know what it dropped.
- **Fix**: Update OAI-009 to explicitly include a pre-processing step (e.g., using `DOMParser` in the browser environment) to identify non-standard tags, or specify that custom Turndown node-filters must be written to catch and replace unrecognized tags with the warning blockquotes.


---

## DeepSeek (deepseek-reasoner)

# Structured Review of `obsidian-applenotes-import` Specification

## Overview
This is a well-structured, thorough specification for a high-risk macOS-only plugin. The four-phase workflow is appropriate, the risk register is honest, and the task decomposition is thoughtful. However, several areas need tightening before PLAN proceeds.

---

## CRITICAL Findings

### [F1] Verify-before-delete: hash comparison may be theater for Vault API reliability
- **Severity**: Critical
- **Finding**: OAI-017 specifies re-reading the written file and comparing its hash to a "content hash captured pre-write". If the Obsidian Vault API (`app.vault.create`) returns success, does it guarantee the file is both fully written *and* identical to the provided content? The hash comparison will only detect post-write corruption (e.g., disk errors, concurrent modifications). It cannot detect cases where `create` silently alters content (e.g., encoding normalization, extra whitespace). Moreover, if `create` fails, the call throws and the orchestrator aborts — making the re-read gate redundant for that path.
- **Why**: The gate as described creates a false sense of security. The only failure mode it catches is *post-write tampering* (an edge case) or a bug where `create` claims success but doesn't write the bytes exactly. In practice, the Obsidian vault API is reliable, so this gate adds complexity without meaningfully reducing the highest impact failure mode: the AppleScript `delete` firing on a note that was *not* verifiably stored.
- **Fix**: Strengthen the gate by:
  1. Compute hash of the *intended content* (pre-write). After `create` returns, re-read the file and compare hashes. This is what the spec describes — but make it explicit that the pre-write hash is from the final markdown string, not from the data written to disk (which could be transformed).
  2. Add a *second* gate: after writing and verifying, *flush* the vault (using `app.vault.modify` equivalent? Not available). Alternatively, accept that the gate is theater for the Vault API case, but retain it as a guard against AppleScript errors that could cause the note to be deleted but the markdown not to be written at all (which the orchestrator already prevents by only calling delete after successful write). The highest-leverage safety is **never calling delete unless the parallel write-verify succeeded**. That is already in the orchestrator. Clarify that the hash compare is a best-effort integrity check, not a safety-critical gate.
  3. Document in the spec that the hash compare is a secondary check, and the primary safety control is the *sequential ordering* (write → verify → index → delete). This is already implicit but should be explicit.

### [F2] Assumption A4 (soft-delete semantics) should be validated *before* PLAN, not during it
- **Severity**: Critical
- **Finding**: The spec defers validation of "AppleScript `delete` lands in Recently Deleted, not hard-delete" to the PLAN spike (OAI-007). If this assumption is wrong, the entire architecture (soft-delete 30-day window) collapses. The risk register lists this as Critical with mitigation "Probe in M2 (OAI-007); abort spec if confirmed". However, M2 is after M1; if the probe fails, all M1 scaffolding (build, skeleton, settings) is wasted. Moreover, the user confirmed the behavior, but the spec does not state that the user *tested* it. "User has confirmed this is the desired soft-delete semantics" refers to *desirability*, not empirical verification.
- **Why**: This is the highest-stakes assumption. A hard-delete would make the plugin unacceptable. The cheapest validation (`osascript` probe) takes <5 minutes. Delaying it to PLAN introduces schedule risk and potential rework.
- **Fix**: Move A4 validation to **immediately after SPECIFY, before PLAN begins** (i.e., now). Run the probe documented in the spec: delete a throwaway note via AppleScript, verify it appears in Recently Deleted. If it works, proceed. If not, pause and redesign (e.g., move to manual Archive workflow). The spec should be updated to flag this as a pre-PLAN gate, not a PLAN spike task.

---

## SIGNIFICANT Findings

### [F3] AppleScript id stability (A2) — needs stronger handling for iCloud account-switching
- **Severity**: Significant
- **Finding**: Assumption A2 states that `id of note` is stable across Notes app restarts. The spec flags "Behavior of the Notes id under iCloud account-switching (rare; flagged for future)" as a Known Unknown. However, the import index (OAI-012) keys solely on the Apple Notes `id`. If a user switches iCloud accounts (or logs in/out), the same note might get a new id, leading to duplicates. Conversely, if a note is deleted from Recently Deleted and then somehow recreated, it could get the same id? Unlikely, but not addressed.
- **Why**: The import index is the single point of truth for idempotency. If ids are not globally stable across account changes, users may see "already imported" for notes they never imported, or be allowed to re-import notes that were already migrated under a different id.
- **Fix**: 
  - Add a *hash of note content and folder* as a secondary key, or at least log a warning when an id appears that is unknown but has a duplicate content hash.
  - Document in the README that switching iCloud accounts may cause re-imports.
  - In the spec, add a note that the import index should tolerate id collisions (detect via content hash and reject re-import).

### [F4] Attachment extraction strategy decision (OAI-008) — too much deferred to PLAN without enough guidance
- **Severity**: Significant
- **Finding**: OAI-008 is rated high risk and will decide between two approaches (AppleScript export vs. filesystem cache). The spec does not provide evaluation criteria (speed, reliability, permission impact, error handling). The decision will be documented in an archived note, but the spec lacks guardrails. For example, if the filesystem cache approach is chosen, the plugin would need to read `~/Library/Group Containers/group.com.apple.notes/Media/` which may require user permissions beyond TCC (full disk access). The spec does not mention this.
- **Why**: A bad decision here could either be unreliable (AppleScript export of attachments may not work for all types like sketches) or introduce new permission hurdles (FS cache requires sandbox escape). Both could block v1 release.
- **Fix**: 
  - Add explicit evaluation criteria to the spec: e.g., "Must extract images, PDFs, audio, and sketches with ≥95% reliability on a representative test set. Must not require additional permission prompts beyond the Automation grant already needed. Must not leave stale temp files. Must not take >2s per attachment."
  - Assign a preliminary assessment in the spec: "AppleScript export is likely simpler but may fail for non-image attachments; filesystem cache is more reliable but requires full disk access. PLAN's spike will test both with 5 notes of each type and pick the approach with fewer total downsides."
  - Move OAI-008 to earlier in M2 (before OAI-005/006) to unblock the rest.

### [F5] TCC permission flow (OAI-019) — denial detection may be fragile
- **Severity**: Significant
- **Finding**: The spec says denial will be "captured by error code" from the AppleScript runner. However, TCC denial on macOS can manifest in multiple ways: the `osascript` process may hang (waiting for user to approve), return a specific error (like `-128` or `-600`), or crash. The exact behavior depends on macOS version and whether the user clicks "Deny" or "Don't Allow". The spec does not specify how to distinguish a TCC denial from other AppleScript errors (e.g., syntax error from a corrupt note).
- **Why**: If the plugin misidentifies a transient AppleScript error as TCC denial, it may disable itself unnecessarily. Conversely, a silent denial (no error, no output) would leave commands functional but failing, confusing the user.
- **Fix**: 
  - Add a dedicated TCC probe script that is known to work on a granted system. On denial, the script should produce a predictable error (e.g., "osascript: execution error: Not authorized to send Apple events (errOSScriptError -10000)"). Document that format in the spec.
  - After the probe, if the error matches the TCC pattern, surface the guidance. If it matches another pattern, surface a generic "AppleScript error (code X) — see console for details". If no error but no output (hang), use a timeout and treat as probable denial.
  - Add a "Reset TCC" button in settings that re-runs the probe and re-evaluates.

### [F6] minAppVersion not yet determined — could cause submission rejection
- **Severity**: Significant
- **Finding**: The manifest has `"minAppVersion": "TBD-in-plan"`. This must be a specific version of Obsidian. If set too low, the plugin may use APIs that don't exist. If set too high, it excludes users. The spec does not reference any method to determine the correct version.
- **Why**: The community plugin directory review process checks that `minAppVersion` matches the APIs used. A gap here could cause rejection.
- **Fix**: 
  - During PLAN, determine the minimum version that supports: `Platform.isMacOS`, `app.vault.createBinary`, `normalizePath`, `FileSystemAdapter`, and `containerEl.createEl`. Likely ≥0.15.0 or later. Add a task to OAI-002 to set minAppVersion after researching API introduction versions.
  - Cross-reference the research brief for any stated minimum.

---

## MINOR Findings

### [F7] OAI-008 risk rating "high" but no explicit test for attachment extraction success
- **Severity**: Minor
- **Finding**: The acceptance criteria for OAI-008 say "chosen approach extracts ≥95% of attachments by type". This is vague. No specific types are enumerated (image, PDF, audio, sketch, map, etc.). The spec lacks a definition of "extraction" — does it mean the file is written to the attachment folder and the markdown link is correct, or just that the file appears?
- **Why**: Ambiguity may lead to incomplete acceptance testing.
- **Fix**: Enumerate expected attachment types from Apple Notes: image (JPEG, PNG, HEIC), PDF, audio (m4a), sketched drawing (PNG?), scanned document (PDF), web link (bookmark). Define extraction as: binary file written to vault attachments folder with correct extension, and markdown reference uses relative path and works when rendered.

### [F8] Task OAI-013 NotesModal — missing pagination consideration given performance risk
- **Severity**: Minor
- **Finding**: The spec acknowledges that AppleScript performance may degrade above ~1k notes, and the risk register lists it as medium. However, the modal task (OAI-013) does not include any pagination or virtual-scrolling design. If the probe in PLAN confirms slowness, the modal will need to be redesigned, potentially requiring a new task.
- **Why**: If deferred, the modal implementation may need rework.
- **Fix**: Add a note in OAI-013 acceptance criteria: "If A1 validation shows list retrieval >5s for 1000 notes, the modal MUST use paginated loading (e.g., fetch first 50, load more on scroll)". Or better, make OAI-013 depend on a spike task that validates list timing.

### [F9] Receipt log (OAI-018) location potentially collides with vault files
- **Severity**: Minor
- **Finding**: The receipt log is written to a "receipts folder" configurable in settings. If the user chooses a path inside the vault that already contains .md files (e.g., a journal directory), the receipt could overwrite or be confused with user notes. The spec does not mention collision handling for receipts.
- **Why**: User error could cause data loss (though receipts are low value).
- **Fix**: In the orchestrator or receipt writer, check if the receipt filename (e.g., `apple-notes-import-2026-04-25.md`) already exists; if so, append a timestamped suffix. Alternatively, recommend a dedicated `_meta/` folder. Document in README.

---

## STRENGTHS

### [S1] Explicit risk register with mitigation per assumption
The spec's risk register (page 9–10) directly ties high-severity risks to specific tasks (e.g., hard-delete → OAI-007, TCC denial → OAI-019). This makes the safety contract auditable.

### [S2] Task decomposition granularity and dependency mapping
Each task is ≤5 files, risk-rated, and placed in a clear dependency graph. The M1–M8 structure mirrors a sensible implementation order: scaffold first, then bridge, then conversion, then index, then UI, then orchestrator, then permission/UX, then distribution. The high-risk tasks (OAI-007, OAI-016, OAI-017) are isolated with test-heavy acceptance criteria.

### [S3] Balanced approach to HTML→Markdown fidelity
Acknowledging "best-effort with warnings" is honest and appropriate for v1. The plan to pin `turndown` and write golden tests reduces regression risk. The inclusion of `> [!warning]` callouts for unsupported elements is a user-friendly design choice.

### [S4] Thorough coverage of Obsidian submission requirements
The spec explicitly references: no `obsidian` in plugin id, no `innerHTML`, `instanceof FileSystemAdapter`, `registerEvent`, `normalizePath`, `isDesktopOnly: true`, no committed `main.js`, `eslint-plugin-obsidianmd`. This suggests the author has studied the research brief carefully.

### [S5] Well-structured assumptions validation plan
Each assumption is paired with a cheap validation probe and a clear fallback (e.g., if A1 fails, design async streaming). This reduces the risk of building on false premises.

---

## Unverifiable Claims

### [U1] `design/research-brief-plugin-platform.md` content
- **Finding**: The spec cites facts from a companion file pulled from `obsidianmd/obsidian-developer-docs` and `obsidianmd/obsidian-sample-plugin` HEAD on 2026-04-25. Since this file was not provided for review, I cannot independently verify those facts (e.g., the exact submission rules, the `eslint-plugin-obsidianmd` version 0.1.9, the `app.vault.createBinary` API signature).
- **Classification**: Unverifiable claim — SIGNIFICANT
- **Recommendation**: Ensure that the research brief is attached to the project documentation or that the key facts are re-verified during PLAN against live docs. This is a standard risk for separated specs but should be flagged for the reviewer's awareness. The spec already states "assume those facts are authoritative" — for the purpose of this review I accept that, but note it as an external dependency.

### [U2] `eslint-plugin-obsidianmd` version 0.1.9
- **Finding**: The spec claims version 0.1.9 is "the official lint plugin and is already in the current sample template." I cannot verify the exact version without checking the sample plugin repository.
- **Classification**: Unverifiable claim — MINOR
- **Recommendation**: In PLAN, run `npm show eslint-plugin-obsidianmd version` and adjust if newer. The version is likely correct, but pinning it in `package.json` is wise.

---

## Summary

| Finding ID | Severity | Area | Action Required |
|------------|----------|------|----------------|
| F1 | Critical | Data safety | Strengthen verify-before-delete description; clarify primary safety is sequencing, not hash compare |
| F2 | Critical | Assumptions | Validate A4 (soft-delete) immediately, before PLAN begins |
| F3 | Significant | Import index | Add secondary key / collision handling for Apple Notes id stability |
| F4 | Significant | Attachment extraction | Add evaluation criteria and move decision earlier |
| F5 | Significant | TCC UX | Define specific error patterns for denial; add timeout handling |
| F6 | Significant | Submission | Determine minAppVersion in PLAN and embed in manifest task |
| F7 | Minor | Attachment extraction | Enumerate attachment types and define extraction success |
| F8 | Minor | Modal UI | Add pagination condition to acceptance |
| F9 | Minor | Receipt log | Add collision handling |
| U1 | Significant | External claims | Ensure research brief is accessible for PLAN verification |
| U2 | Minor | External claims | Verify eslint-plugin version in PLAN |

**Overall**: The spec is robust and well-considered. The two critical items (F1, F2) should be addressed before PLAN proceeds. The significant items (F3–F6) will improve safety and reduce rework. The minor items are nice-to-have polish. The strengths (S1–S5) indicate a disciplined, user-conscious design process.


---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: CRITICAL
- [Finding]: Verify-before-delete (OAI-017) captures hash "immediately after `vault.create` returned" then re-reads and compares, but this does not verify against a pre-computed *expected* hash of the content to be written; it only confirms the vault.write API call succeeded and the file is immediately readable by Obsidian (e.g., no immediate I/O error), missing corruption, truncation, or partial-write scenarios where `vault.create` returns success but the file is malformed.
- [Why]: This is theater, not safety — contrived failures like disk full mid-write, concurrent vault edits, or Obsidian's internal file-watching bugs could leave a bad file in vault while deleting source. Data loss occurs without detection.
- [Fix]: Capture *expected* hash of assembled Markdown+frontmatter *before* vault.write; compare re-read hash to expected (not to post-write hash). Add adversarial tests simulating partial writes (e.g., mock vault.write to write truncated content).

- [F2]
- [Severity]: CRITICAL
- [Finding]: No explicit handling for mid-batch failures in OAI-016 orchestrator: if note N succeeds (write+verify+index+delete) but note N+1 fails verify, prior deletes are already done — no rollback of soft-deletes, leaving partial source loss.
- [Why]: Batch workflow invites multi-note imports; partial success + partial delete = data loss without recovery path (Recently Deleted is per-note, no batch undo).
- [Fix]: All-or-nothing batch: collect all verified writes first (dry-run phase 2), index without delete, show confirm with "soft-delete all or none", then delete only after batch confirm. Or per-note confirm (slower UX).

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: Import index (OAI-012) uses plugin `data.json` keyed by Apple Notes ID, but lacks backup/sync strategy; Obsidian reload, plugin disable/re-enable, or vault move corrupts/gaps idempotency ("already imported" falsely triggers or misses).
- [Why]: Users expect vault-local persistence; data.json loss means re-import risk or false blocks. No corruption recovery beyond "recover empty".
- [Fix]: Duplicate index as YAML frontmatter in each imported file (`imported_from_index: true`) for vault-portable idempotency; fallback to file-scan if data.json invalid.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Assumption A4 ("AppleScript `delete` lands in Recently Deleted") deferred to PLAN spike (OAI-007), despite being marked highest-stakes (Risk Register: Critical) and directly enabling destructive op.
- [Why]: If wrong, all downstream tasks build on false premise → full spec rewrite post-PLAN waste. Pre-SPECIFY locked LD-02 on soft-delete; validating *now* (quick Terminal probe: create test note, osascript delete, check Notes app) costs <5min, derisks before PLAN.
- [Fix]: Escalate A4 to pre-PLAN validation: append "VALIDATED: YES/NO" status to spec; if NO, halt and revise to non-delete workflow.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: No explicit mid-import crash recovery in OAI-016: Obsidian crash/force-quit after write+verify but before delete/index leaves source intact but unindexed (re-shows as importable).
- [Why]: Electron/Obsidian unstable on macOS; unindexed successes waste UX (user re-imports blindly) or risk duplicates if override toggled.
- [Fix]: Write index *immediately after verify success, before delete*; on modal reopen, scan vault files matching frontmatter `apple_notes_id` as index-fallback.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "Repo already initialized at `~/code/obsidian-applenotes-import/` (commit `4bd59d9`)" and "verified against `obsidianmd/obsidian-developer-docs` and `obsidianmd/obsidian-sample-plugin` HEAD on 2026-04-25".
- [Why]: Future dates (2026); specific commit/SHA uncheckable without access; assumes authoritative but risks obsolescence if Obsidian APIs change.
- [Fix]: Flag for reviewer verification; add "as-of [date]" to all platform facts; PLAN task to re-verify HEAD.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Obsidian submission compliance misses `styles.css` bundling rules (must be committed, referenced in manifest); task OAI-013 mentions `styles.css` but no manifest authorClass or bundling spec.
- [Why]: Sample plugin requires `styles.css` committed + `cssclasses`? manifest field optional; rejection risk if DOM styles not submission-clean.
- [Fix]: Update manifest proposal with `"cssclasses": false` or handle; add OAI-002 acceptance: lint+build produces valid release.zip.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: Task OAI-008 (attachments) sized at 3 files but includes "spike picks ... decision-doc archived"; decision doc + dual-probe (AppleScript vs filesystem) likely >5 changes + testing.
- [Why]: Oversized task risks incomplete spike; attachment fidelity core to AC3, high risk mis-rated.
- [Fix]: Split: OAI-008a probe+decision (2 files/docs), OAI-008b implement winner (3 files).

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: HTML→MD (OAI-009) via turndown assumes GFM output fidelity for Apple Notes specifics (sketches as SVGs?, scanned PDFs as images?, handwriting recognition); no mention of Notes' proprietary `<canvas>` or media enclosures.
- [Why]: Apple Notes rich media (drawings, scans) poorly turndown-supported → "best-effort" fails AC3 ("attachments inline where Apple Notes did"); users perceive broken if sketches rasterize lossily or drop.
- [Fix]: PLAN spike sample 5+ real Notes HTML; consider `marked`+`DOMParser` alt or `html-to-md`; doc "sketches export as PNG fallback, interactive ink lost".

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Modal UI (OAI-013) deps only OAI-005+OAI-012, but needs OAI-006 (fetch body) for preview snippets and OAI-019 (TCC) for load-time probe.
- [Why]: Wrong deps → build order fail (modal lists but can't preview/fetch); TCC block unobserved.
- [Fix]: Add deps OAI-006, OAI-019 to OAI-013.

- [F11]
- [Severity]: MINOR
- [Finding]: Task risks: OAI-016/017 correctly **high**, but OAI-005/006 (list/fetch scripts) medium despite A1-A3 perf/locked-note risks.
- [Why]: AppleScript flakiness common; under-rated delays M2.
- [Fix]: Bump to high; add perf metrics to acceptances.

- [F12]
- [Severity]: MINOR
- [Finding]: AC1 "lists ≥95% ... within 5 seconds for 1k-note" arbitrary threshold; no fallback if A1 fails (e.g., pagination).
- [Why]: Unmet if >1k common; blocks acceptance.
- [Fix]: Add "or streamed/paginated UX if probe >5s".

- [F13]
- [Severity]: MINOR
- [Finding]: No mobile-simulator test (Obsidian iPad syncs vault); AC7 covers desktop non-macOS but not inert on mobile.
- [Why]: Community review flags mobile breakage.
- [Fix]: Add AC7.1 "On mobile, commands inert, no errors".

- [F14]
- [Severity]: STRENGTH
- [Finding]: Locked Decisions LD-01..09 table crisp; ties user inputs to spec elements without ambiguity.
- [Why]: Prevents re-litigation; traceable.
- [Fix]: N/A

- [F15]
- [Severity]: STRENGTH
- [Finding]: Risk Register covers top failure modes (data loss, perf, submission) with task mitigations.
- [Why]: Proactive; aligns to levers/second-order effects.
- [Fix]: N/A

---

## Synthesis (Claude)

**Headline.** All four reviewers converged on the same core failure: the spec's data-safety design is directionally right but operationally thin, and the highest-stakes assumption (A4 — soft-delete semantics) is deferred to PLAN when it's a 5-minute probe that should gate PLAN entry. Both findings are CRITICAL and consensus across all four reviewers. Beyond those, there's strong convergence on (a) verify-before-delete needing to be a *composite* contract rather than markdown-only, (b) the import index corruption strategy being unsafe, (c) attachment extraction needing earlier+sharper specification, and (d) several concrete dependency-graph bugs.

The structural shape of the spec is sound — locked decisions table, task decomposition, risk register, and submission compliance integration drew uniform praise. The required revisions are about *depth and precision in the safety-critical sections*, not architecture rewrite.

### Consensus Findings (2+ reviewers)

| # | Severity | Finding | Reviewers |
|---|---|---|---|
| C1 | CRITICAL | Verify-before-delete is incomplete / theater. Needs composite contract: hash expected content pre-write; verify md + all attachments + index, not just md. The current "post-write captured hash compared to itself" wording is internally inconsistent and provides no guarantee. | OAI-F2, OAI-F9, GEM-F2, DS-F1, GRK-F1 (4/4) |
| C2 | CRITICAL | A4 (AppleScript `delete` → Recently Deleted) must move from PLAN spike to **pre-PLAN gate**. It's product-viability, not implementation. The Facts section also misstates "user has confirmed" — user confirmed *desired* semantics, not empirical behavior. | OAI-F1, GEM-F3, DS-F2, GRK-F4 (4/4) |
| C3 | SIGNIFICANT | Import index corruption strategy ("recover empty on parse error") is unsafe for a destructive importer. Need safe-degraded-mode + frontmatter-scan rebuild path. | OAI-F4, DS-F3, GRK-F3, GRK-F5 (3/4) |
| C4 | SIGNIFICANT | OAI-008 attachment extraction underspecified: needs evaluation criteria, attachment type matrix, earlier sequencing, and split into probe/decide vs implement. AppleScript export vs filesystem cache decision has very different permission/reliability profiles. | OAI-F7, GEM-F4, DS-F4, DS-F7, GRK-F8 (4/4) |
| C5 | SIGNIFICANT | turndown alone insufficient for Apple Notes HTML. Drops unknown tags silently — the "[!warning] callout" UX won't materialize without custom Turndown node-filters + Apple-specific pre-processing layer. Need fixture tests on real captured HTML. | OAI-F17, GEM-F9, GRK-F9 (3/4) |
| C6 | SIGNIFICANT | TCC strategy has internal inconsistency (system map: probe on load; OAI-019: probe on first command) AND fragile denial detection (multiple error codes, may hang). | OAI-F12, OAI-F13, DS-F5 (2/4 — OAI raises twice) |
| C7 | SIGNIFICANT/CRITICAL | No batch transaction model, no progress/cancellation UX. Mid-batch failure semantics undefined → prior soft-deletes can fire while later notes fail. | OAI-F11, OAI-F21, GRK-F2 (CRITICAL per Grok) (2/4) |
| C8 | SIGNIFICANT | AC1 "5s for 1k notes" too brittle; modal lacks pagination contingency if A1 probe fails. | OAI-F10, DS-F8, GRK-F12 (3/4) |
| C9 | CRITICAL | Dependency-graph bugs: OAI-016 missing OAI-007 dep; OAI-013 missing OAI-006 + OAI-019 deps; OAI-021 should depend on M7 not just M6. | GEM-F7, GEM-F8, GRK-F10 (mechanical bug — 2 reviewers caught it) |
| C10 | SIGNIFICANT | Upstream citations not pinned (eslint-plugin-obsidianmd 0.1.9, "no-obsidian-in-id" rule). Need URLs/commit SHAs in research brief. | OAI-F33/F34, GEM-F1, DS-U1/U2, GRK-F6 (4/4) |

### Unique Findings (single reviewer — kept where signal is genuine)

| # | Severity | Finding | Source | Verdict |
|---|---|---|---|---|
| U1 | SIGNIFICANT | Semantic conversion loss isn't just a write-failure problem — a byte-perfect markdown can still be an unacceptable migration. Needs warning thresholds tied to delete-blocking. | OAI-F5 | Genuine — fold into C1 composite contract |
| U2 | SIGNIFICANT | Decision-doc location: OAI-008's archive in `_system/docs/solutions/` belongs in repo-local `docs/decisions/` or `design/decisions/` for community visibility. | OAI-F8 | Genuine fix |
| U3 | SIGNIFICANT | Distribution checklist for M8 (gitignore, release-asset hygiene, README install/troubleshooting, screenshots, manifest/tag consistency). | OAI-F14 | Genuine — adds rigor to M8 |
| U4 | SIGNIFICANT | Filename collision policy is hand-wavy. Default policy: title→filename, suffix on collision, index stores canonical path, re-import override creates new unique file (never overwrite silently). | OAI-F15 | Genuine fix |
| U5 | SIGNIFICANT | Warning UX may degrade readability — collapsed callouts are theme-dependent, raw HTML in user notes is ugly. Need tiered: severe→delete-blocking, moderate→receipt+frontmatter, debug-only→inline. | OAI-F18 | Genuine refinement |
| U6 | SIGNIFICANT | Post-failure cleanup policy missing: if md writes but attachments fail, leave md + mark errored, clean up incomplete attachment temp dirs. | OAI-F20 | Genuine fix |
| U7 | SIGNIFICANT | minAppVersion still TBD — needs to be researched against API surface (Platform, createBinary, normalizePath, FileSystemAdapter, createEl). | DS-F6 | Genuine, operationally important |
| U8 | SIGNIFICANT | styles.css bundling rules for community submission not addressed. | GRK-F7 | Genuine M8 addition |
| U9 | SIGNIFICANT | Skip command registration entirely on non-macOS rather than inert+Notice (cleaner). Add mobile inert AC. | GEM-F6, GRK-F13 | Genuine refinement |
| U10 | MINOR | Locked-notes wording in OAI-005 ambiguous (list vs import behavior). | OAI-F22 | Genuine wording fix |
| U11 | MINOR | AC4 verification protocol unclear (automated vs manual integration test). | OAI-F26 | Genuine sharpening |
| U12 | MINOR | Receipts should use wikilinks/markdown links, not plain text paths. | OAI-F24 | Genuine polish |
| U13 | MINOR | Settings path validation on save (normalize, reject empty, auto-create on first import). | OAI-F25 | Genuine polish |
| U14 | MINOR | Receipt filename collision handling. | DS-F9 | Genuine but low-impact |
| U15 | SIGNIFICANT | apple_notes_id privacy: dual representation (raw locally, hashed in frontmatter) suggested. | OAI-F16 | DECLINED — see below |

### Contradictions

None substantive. The verify-before-delete cluster has a useful nuance worth surfacing rather than resolving:

- **DS-F1** argues the hash-compare is *secondary*; primary safety is **sequencing** (write→verify→index→delete).
- **OAI-F2/F9/GRK-F1** argue the gate must be *expanded* to cover all import artifacts (md + attachments + index).

These are complementary, not contradictory: keep sequencing as the primary safety control, *and* expand the verification gate to cover every artifact. The synthesis below treats them together.

### Action Items

#### Must-fix (block PLAN entry)

| ID | What to do | Source findings |
|---|---|---|
| **A1** | Run AppleScript soft-delete probe **NOW**, before PLAN. Append "VALIDATED: yes/no" to spec; if no, halt and revise to non-delete workflow. | C2 |
| **A2** | Fix Facts-section wording: "user has confirmed *desired* soft-delete semantics; empirical behavior probe required pre-PLAN (A4)." Resolve the contradiction GEM-F3 caught. | C2, GEM-F3 |
| **A3** | Redefine OAI-017 as composite verify-before-delete contract: (a) hash expected pre-write content; (b) verify md exists + content matches expected hash; (c) verify all expected attachment files exist + non-zero; (d) verify rewritten attachment refs resolve; (e) verify index persisted + readback succeeds. Update AC5. Add adversarial tests simulating partial writes. | C1, U1 |
| **A4** | Reorder M6 pipeline in spec: fetch → convert → write attachments → write markdown → composite verify → persist index → verify index readback → soft-delete → append receipt (receipt is *not* a delete gate). | OAI-F3 |
| **A5** | OAI-012: replace "recover empty on parse error" with safe-degraded-mode + vault-frontmatter-scan rebuild. Disable delete-capable imports until repaired or user explicitly chooses re-index. | C3 |
| **A6** | Add explicit batch transaction model: per-note independent (no all-or-nothing across batch); abort-and-surface stops *current note's* delete only, not the batch; final summary dialog after batch with imported/skipped/errored breakdown. Add cancel-after-current to UI. | C7 |
| **A7** | Promote A2 (note id stability) to pre-PLAN validation alongside A4. Add content hash as secondary key to import index; tolerate id collisions (detect by content hash; reject re-import). | OAI-F6, DS-F3 |
| **A8** | Promote A7 (attachment extraction) decision earlier. Split OAI-008 into OAI-008a (probe + decision + criteria, runs before OAI-009/OAI-013 dependencies are locked) and OAI-008b (implement winner). Add attachment type matrix: image (JPEG/PNG/HEIC), PDF, audio (m4a), drawing/sketch, scanned doc, web link/bookmark. Define "extraction" = binary written + relative md link resolves. Note that filesystem-cache approach may require Full Disk Access — flag as additional permission cost. | C4 |
| **A9** | Fix dependency graph: OAI-016 add OAI-007; OAI-013 add OAI-006 + OAI-019; OAI-021 depend on M7 not just M6. | C9 |
| **A10** | Lock TCC behavior: probe on **first user-initiated command**, NOT plugin load. Specify denial-detection contract: parse stderr for known patterns (`Not authorized to send Apple events`, error codes -1743/-10000), timeout fallback for hangs, generic-error fallback for unmatched. README troubleshooting section. | C6 |

#### Should-fix (before PLAN if cheap, otherwise during PLAN)

| ID | What to do | Source findings |
|---|---|---|
| A11 | OAI-009: add HTML pre-processing layer (Apple Notes-specific span/div unwrap, checklist mapping, attachment-object rewrite, custom turndown node-filters that *catch* unknown tags rather than silently drop). Add fixture-based tests using real captured Apple Notes HTML, not synthetic. | C5 |
| A12 | Reframe AC1: "responsive UI within 2s; complete listing for 1k notes within 5–10s under typical conditions; locked/shared notes counted and labeled." Add pagination contingency to OAI-013 acceptance: "if A1 probe shows >5s for 1k notes, modal MUST use paginated/streamed loading." | C8 |
| A13 | OAI-002: add subtask to research minAppVersion against API surface (Platform, vault.createBinary, normalizePath, FileSystemAdapter, createEl). Replace "TBD-in-plan" with concrete value. | U7 |
| A14 | Split M6 into 4–5 finer tasks: import transaction model, composite verify contract, delete gate, batch execution/reporting, cancellation/progress. Re-rate task complexity; ≤5 file-changes is a poor proxy for safety-critical logic complexity. | OAI-F19 |
| A15 | Move OAI-008 decision-doc destination from `_system/docs/solutions/` to repo-local `design/decisions/` or `docs/decisions/`. Keep implementation artifacts inside the plugin repo. | U2 |
| A16 | Define filename collision policy concretely: title→sanitized filename; suffix `-2`, `-3`, … on collision; index stores canonical chosen path; re-import override creates new unique file; never overwrite silently. | U4 |
| A17 | Tier conversion warning UX: severe omissions (missing required attachments) block delete; moderate omissions logged to receipt + frontmatter `import_warnings: [...]`; raw source HTML inline only in debug mode (off by default). | U5, OAI-F5 |
| A18 | Refine Platform gate: skip command registration entirely when `Platform.isMacOS === false` (cleaner than inert+Notice). Add mobile-inert AC. | U9 |
| A19 | Add M8 distribution hygiene checklist: `.gitignore` excludes `main.js`, release assets contain only `main.js + manifest.json + styles.css`, README documents manual install + TCC troubleshooting + macOS-only banner, manifest fields match release tag, screenshots reflect current UI. | U3 |
| A20 | Add `styles.css` bundling spec to OAI-013/OAI-022 (committed in repo, included in release zip, referenced in manifest as needed). | U8 |
| A21 | Define post-failure cleanup policy: md writes but attachments fail → leave md, mark errored in receipt, clean up incomplete attachment temp dirs. | U6 |
| A22 | Sharpen AC4 to specify verification protocol: "Manual or scripted integration test confirms deleted note no longer in original folder and appears in Recently Deleted under supported test conditions." | U11 |
| A23 | Reword OAI-005 locked-notes acceptance: "Lists locked notes when visible with `isLocked: true` flag; import pipeline skips locked notes with explicit reason unless body fetch succeeds." | U10 |
| A24 | Pin upstream citations in research-brief: source URLs + commit SHAs for "no-obsidian-in-id rule" and "eslint-plugin-obsidianmd 0.1.9 in current sample template." Re-verify both at PLAN start. | C10 |
| A25 | Reword "Recently Deleted (30-day retention)" to "Apple Notes' standard Recently Deleted retention behavior" unless 30-day is explicitly source-cited. Document Apple's published behavior in research brief if available. | OAI-F36 |
| A26 | OAI-018: receipts use wikilinks/markdown links to imported notes; plain-text reasons for skipped/errored items. | U12 |
| A27 | OAI-003: add settings validation on save — normalize paths, reject empty/invalid folder names, auto-create on first import. | U13 |
| A28 | OAI-018: handle receipt filename collisions (timestamp suffix or dedicated `_meta/` folder). | U14 |

#### Defer

| ID | What to do | Source findings |
|---|---|---|
| A29 | apple_notes_id hashed-in-frontmatter privacy enhancement → v1.1. Document privacy footnote prominently in v1 README. | U15 |

### Considered and Declined

| Finding | Verdict | Reason category |
|---|---|---|
| **GRK-F6** ("future dates 2026, uncheckable commits") | The "future dates" premise is incorrect — current date is 2026-04-25 (system environment). The legitimate underlying concern (pin upstream citations) is already covered by C10/A24. | incorrect |
| **GRK-F11** (bump OAI-005/006 to high risk) | Failure mode for list/fetch scripts is "doesn't work" / wrong data, not data loss. Medium risk is calibrated; bumping to high inflates the risk register without corresponding mitigation cost. | overkill |
| **OAI-F16/U15** (hash apple_notes_id) | LD-09 (locked decision) fixes the field set as raw IDs. Re-litigation would invalidate operator approval. Documented as v1.1 deferred enhancement. | constraint |
| **OAI-F23** (ribbon icon optional) | Cosmetic; can be revisited in IMPLEMENT without spec impact. Spec keeps "ribbon icon visible" as a default; opt-out via setting is trivial to add later. | out-of-scope |

### Strengths (consensus reinforcement)

All four reviewers independently flagged these as working well — useful evidence the spec's structural shape is sound:

- Verify-before-delete identified as first-class lever (OAI-F27, GRK-F15)
- Locked-decisions table reduces re-litigation (OAI-F28, DS-S5, GRK-F14)
- Submission compliance integrated, not bolted-on (OAI-F29, GEM-F5, DS-S4)
- Task decomposition is dependency-aware and architecturally clean (OAI-F30, DS-S2)
- Risk register ties critical risks to specific tasks (DS-S1, GRK-F15)
- Privacy callout on `apple_notes_id` is a good second-order catch (OAI-F31)
- Best-effort conversion with golden tests is honest framing (DS-S3)

### Recommendation

The 10 must-fix items are not a teardown — they're depth additions to sections the spec already correctly identifies as critical. Estimated revision effort: 1–2 hours of spec edits + the A1 osascript probe (5 min). After revision, recommend a single round-2 diff-mode peer review focused only on the must-fix changes before declaring SPECIFY done and entering PLAN.

