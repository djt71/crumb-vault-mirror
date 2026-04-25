---
type: review
review_mode: full
review_round: 2
prior_review: Projects/obsidian-applenotes-import/reviews/2026-04-25-specification.md
artifact: Projects/obsidian-applenotes-import/design/specification.md
artifact_type: specification
artifact_hash: 34fb6553
prompt_hash: 42d1fc63
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
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - 'Token "proprietary" present in artifact (benign technical reference: "Apple Notes proprietary canvas")'
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 79048
    attempts: 1
    system_fingerprint: gpt-5.4-2026-03-05
    raw_json: Projects/obsidian-applenotes-import/reviews/raw/2026-04-25-specification-r2-openai.json
  google:
    http_status: 200
    latency_ms: 43486
    attempts: 1
    system_fingerprint: gemini-3.1-pro-preview
    raw_json: Projects/obsidian-applenotes-import/reviews/raw/2026-04-25-specification-r2-google.json
  deepseek:
    http_status: 200
    latency_ms: 49896
    attempts: 1
    system_fingerprint: fp_058df29938_prod0820_fp8_kvcache_20260402
    raw_json: Projects/obsidian-applenotes-import/reviews/raw/2026-04-25-specification-r2-deepseek.json
  grok:
    http_status: 200
    latency_ms: 37868
    attempts: 1
    system_fingerprint: fp_abdb4463eb
    raw_json: Projects/obsidian-applenotes-import/reviews/raw/2026-04-25-specification-r2-grok.json
tags:
  - review
  - peer-review
---

# Peer Review (Round 2): Obsidian Apple Notes Import — Specification (revision 2)

**Artifact:** `Projects/obsidian-applenotes-import/design/specification.md` (revision 2)
**Mode:** full
**Round:** 2 (prior round: `Projects/obsidian-applenotes-import/reviews/2026-04-25-specification.md`)
**Reviewed:** 2026-04-25
**Reviewers:** OpenAI gpt-5.4, Google gemini-3.1-pro-preview, DeepSeek deepseek-reasoner, xAI grok-4-1-fast-reasoning
**Review prompt:** Round-2 diff-aware review of revision 2 — assess whether the 28 round-1 actions were applied without regression; verify Pre-PLAN gate, composite verify-before-delete, M6 split, batch transaction model, conversion warning tiers, dependency-graph fixes; flag remaining gaps.

---

## OpenAI (gpt-5.4)

Below is a round-2 peer review focused on whether revision 2 addresses the round-1 issues without introducing regressions.

## Overall assessment

Revision 2 is substantially improved. The major safety and sequencing concerns from round 1 were clearly taken seriously: the new Pre-PLAN gate, the strengthened verify-before-delete contract, corruption-safe import-index behavior, and per-note batch isolation materially improve the spec.

I do **not** think this needs major rework. However, I also do **not** think it is fully ready for PLAN yet, because a few specification seams remain under-defined in exactly the new high-risk areas: index repair behavior vs delete gating, G2/G3 probe acceptance criteria, and some coordination boundaries introduced by the M6 split.

---

## Findings

- **[F1]**
- **[Severity]: STRENGTH**
- **[Finding]: The round-1 must-fix on the composite verify-before-delete contract appears adequately addressed.**
- **[Why]:** The spec now explicitly defines a composite gate in multiple places:
  - System Map: markdown exists, markdown hash matches expected pre-write hash, attachments exist and are non-zero, rewritten references resolve, index persisted and read-back succeeds.
  - AC5 mirrors this.
  - OAI-016b is dedicated to adversarial testing.
  This closes the prior safety gap where “write happened” could have been interpreted too loosely.
- **[Fix]:** None required.

---

- **[F2]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: There is still a sequencing inconsistency around where “index persisted + read-back succeeds” lives: the verify gate claims to include it, but OAI-016a’s pipeline says “composite verify → persist index → verify index readback → soft-delete.”**
- **[Why]:** These two statements cannot both be true as written. If verify includes index persistence/readback, index persistence must occur before or within verify. But OAI-016a places persistence after verify. This is exactly the kind of ambiguity that can lead to an unsafe implementation or circular task ownership between 016a and 016b.
- **[Fix]:** Choose one model and make all sections match:
  1. **Preferred:** redefine pipeline as `fetch → convert → write attachments → write markdown → persist index → composite verify (including index readback) → soft-delete → append receipt`; or
  2. split checks explicitly into `filesystem verify` and `index verify`, then define delete gate as requiring both.
  Update System Map, AC5, OAI-016a, and OAI-016b to the same sequence.

---

- **[F3]**
- **[Severity]: STRENGTH**
- **[Finding]: The new Pre-PLAN Validation Gate is a strong correction and correctly prevents PLAN from proceeding before unresolved viability assumptions are addressed.**
- **[Why]:** This was a major structural improvement. G2/G3/G4 are framed as product-viability gates rather than mere implementation details, and the spec explicitly says PLAN does not begin until they resolve. That is the right workflow discipline for this plugin.
- **[Fix]:** None required.

---

- **[F4]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: G2 (note ID stability) is still under-specified for a pass/fail decision, even though it is correctly gated.**
- **[Why]:** The spec says the probe “must cover” restart, edit-after-restart, folder move, and iCloud↔On-My-Mac where available. But it does not define what counts as success:
  - Must ID remain byte-for-byte identical across all cases?
  - Is one failure enough to fail G2?
  - If iCloud↔On-My-Mac changes ID but folder-local moves do not, does that force spec revision or permit a reduced guarantee?
  Since G2 blocks PLAN, its acceptance criteria need to be operational, not just exploratory.
- **[Fix]:** Add explicit acceptance criteria to G2 / A2, e.g.:
  - “Pass only if `id of note` remains identical across restart, edit-after-restart, and folder move within same account.”
  - “If cross-account move changes ID, spec must be revised to treat IDs as account-scoped and downgrade dedupe guarantees.”
  - “If any same-account scenario changes ID, return to SPECIFY.”

---

- **[F5]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: G3 (attachment extraction approach decision) is much improved but still lacks enough concrete decision thresholds for mixed results across attachment classes.**
- **[Why]:** The decision criteria are better than in rev 1, but “≥95% reliability across image/PDF/audio/drawing/scan/bookmark types” leaves ambiguity:
  - Is 95% aggregate across all attachments acceptable if sketches are 40% reliable?
  - Are required types weighted more heavily than best-effort types?
  - Does “drawing/sketch” belong in the 95% target if support matrix already says best-effort PNG fallback?
  This matters because G3 is pre-PLAN gating and may force scope revision.
- **[Fix]:** Define criteria by support class:
  - Required types (image/PDF/audio/scanned doc): ≥95% extraction success each.
  - Best-effort types (drawing/sketch, web bookmark): probe determines warning semantics and whether type stays in v1 matrix.
  - If required types fail or require Full Disk Access without acceptable UX, return to SPECIFY.

---

- **[F6]**
- **[Severity]: STRENGTH**
- **[Finding]: The index corruption handling is a strong, safety-oriented revision and addresses the round-1 concern well.**
- **[Why]:** “Never silently treat corruption as empty” is the right invariant. Safe-degraded mode plus frontmatter-driven rebuild is a solid product behavior for a destructive workflow.
- **[Fix]:** None required.

---

- **[F7]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: The index repair flow is still underspecified at the boundary where frontmatter and index disagree, especially because delete-capable imports are disabled during degradation.**
- **[Why]:** The spec says repair scans vault frontmatter for `apple_notes_id` and reconstructs the index, but does not say what happens when:
  - multiple notes share the same `apple_notes_id`,
  - frontmatter note path no longer exists,
  - frontmatter was manually edited,
  - content hash disagrees with current file content,
  - one machine imported notes and another machine modified them later.
  Without conflict rules, repair may produce a misleading index and incorrectly gate or ungate deletes.
- **[Fix]:** Add repair conflict policy, e.g.:
  - duplicate `apple_notes_id` → mark ambiguous, keep delete disabled for those notes until user resolves;
  - missing file path → drop entry and log warning;
  - frontmatter/hash mismatch → rebuild with current path but mark “untrusted/review-needed”;
  - repair report written to receipt/log.

---

- **[F8]**
- **[Severity]: STRENGTH**
- **[Finding]: The batch transaction model is now appropriately explicit and addresses the prior all-or-nothing ambiguity.**
- **[Why]:** Per-note independence, cancel-after-current, and final summary counts are all specified at system, acceptance, and task levels. This is materially better and safer for a selective import workflow.
- **[Fix]:** None required.

---

- **[F9]**
- **[Severity]: MINOR**
- **[Finding]: “Cancel-after-current” is specified, but not whether a note already in “soft-delete in progress” is allowed to complete fully before cancellation is honored.**
- **[Why]:** The likely answer is yes, but this should be explicit in a destructive workflow.
- **[Fix]:** State: “Cancellation is only observed between note transactions; once a note enters verify/delete phase, its pipeline runs to completion for consistency.”

---

- **[F10]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: The M6 split into OAI-016a..e is directionally good, but responsibilities are not yet fully cleanly separated because sequencing and gate ownership overlap.**
- **[Why]:**
  - 016a owns transaction sequencing.
  - 016b owns verify contract including index readback.
  - 016c owns delete gate execution.
  But 016a’s acceptance text already embeds verify and index-readback sequencing logic, which partially duplicates 016b/016c concerns. This creates a coordination hazard where each task assumes another one owns a critical check.
- **[Fix]:** Tighten task boundaries:
  - 016a: orchestration order only, no internal verification rules.
  - 016b: pure verification implementation and return schema.
  - 016c: only “invoke delete iff verification result is success.”
  Also define the function contract between them in one sentence.

---

- **[F11]**
- **[Severity]: STRENGTH**
- **[Finding]: The OAI-008 split into probe/decision then implementation is a strong fix and properly unlocks downstream work.**
- **[Why]:** This was one of the best structural changes in the revision. It recognizes that attachment extraction is not just implementation detail but a viability decision.
- **[Fix]:** None required.

---

- **[F12]**
- **[Severity]: MINOR**
- **[Finding]: One dependency note is slightly imprecise: OAI-009 depends on OAI-008a for “HTML object shape,” but conversion of body HTML and attachment placeholders may also depend on OAI-006/A3 results, not just attachment extraction decision.**
- **[Why]:** Not a blocker, because OAI-006 is already upstream in the broad flow, but the dependency rationale could be more exact.
- **[Fix]:** Consider updating OAI-009 dependencies to mention OAI-006 or A3 validation explicitly if converter assumptions rely on body HTML structure.

---

- **[F13]**
- **[Severity]: STRENGTH**
- **[Finding]: The dependency-graph corrections are mostly sound, especially OAI-016 depending on OAI-007, OAI-013 depending on OAI-019, and OAI-021 depending on M6+M7.**
- **[Why]:** These repairs improve implementation order and avoid prior hidden prerequisites.
- **[Fix]:** None required.

---

- **[F14]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: OAI-013 depending on OAI-019 may be too strong if interpreted literally, because the modal itself need not depend on permission-probe implementation to exist.**
- **[Why]:** If TCC handling is incomplete, the UI can still be built and tested with mock data. The current dependency may artificially serialize work. This is not a correctness error, but it reduces planning flexibility.
- **[Fix]:** If the intent is only that command entrypoints consult TCC before invoking real AppleScript, make OAI-015 depend on OAI-019, and let OAI-013 depend only on notes data contracts or mock source.

---

- **[F15]**
- **[Severity]: STRENGTH**
- **[Finding]: Moving the TCC probe to first user-initiated command invocation is a cleaner UX decision than probing on plugin load.**
- **[Why]:** It avoids surprise prompts and aligns permission requests with user intent.
- **[Fix]:** None required.

---

- **[F16]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: There is an unresolved edge case in the TCC UX: if the user opens settings first, they may expect “Re-check permission” or diagnostics to work even before any command invocation.**
- **[Why]:** The spec says the probe runs on first user-initiated command, not on plugin load. That is good. But settings now include guidance and a manual re-check button. It should be clear whether clicking “Re-check permission” itself counts as a user-initiated probe. Otherwise the settings experience is oddly passive.
- **[Fix]:** Explicitly state: “The settings-tab ‘Re-check permission’ action is also a user-initiated probe and may trigger the same TCC check flow.”

---

- **[F17]**
- **[Severity]: STRENGTH**
- **[Finding]: The HTML pre-processing layer plus custom turndown node-filters is now adequately directed at a specification level.**
- **[Why]:** The revision correctly moves from generic “use turndown” to a concrete strategy: preprocess Apple-specific HTML, catch unknown tags instead of silently dropping them, use real captured fixtures, and tie warning tiers to delete behavior.
- **[Fix]:** None required.

---

- **[F18]**
- **[Severity]: MINOR**
- **[Finding]: The warning-tier system is good, but “unsupported HTML element” as a moderate warning may still be too broad without examples of what escalates to severe besides attachment failure.**
- **[Why]:** The current matrix makes severe mostly attachment-centric. But there may be non-attachment structural content loss cases that should block delete, e.g. a checklist or table collapsing into near-empty output.
- **[Fix]:** Add one sentence: “Severe also includes any conversion outcome where substantive body content cannot be represented and output would omit user-visible content rather than merely degrade formatting.”

---

- **[F19]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: The new conversion-warning tiers introduce a subtle regression risk: debug-only inline raw source HTML in note body, even behind a setting, can leak sensitive source content more broadly than intended.**
- **[Why]:** Since imported notes live in the vault and may sync/share, embedding raw HTML telemetry into the note body changes the artifact itself, not just logs. The spec notes privacy concerns elsewhere, so this deserves stronger guardrails.
- **[Fix]:** Change debug-only telemetry from “inline in note body” to either:
  - receipt/debug log only, or
  - fenced block in note body only when the user explicitly opts into “embed diagnostics in imported notes.”
  At minimum, add a warning in settings/README.

---

- **[F20]**
- **[Severity]: MINOR**
- **[Finding]: Platform-gate behavior is cleaner, but “a single Notice emits at load” could become annoying on every startup for users syncing the plugin to non-macOS devices.**
- **[Why]:** The functional choice is good; the UX could be noisy.
- **[Fix]:** Consider “emit once per install/version” or only in settings/plugin load diagnostics rather than every load.

---

- **[F21]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: AC1’s responsiveness target and A1’s fallback logic are slightly misaligned.**
- **[Why]:** AC1 says first results/loading indicator within 2s and complete listing for ~1k notes within 5–10s; if A1 spike shows >5s for 1k, modal uses paginated/streamed loading. But A1 only validates `get every note` within ≤10s. A result of 8s would pass A1 but still force pagination by AC1/OAI-013 logic. That is workable, but the decision rule should be unified.
- **[Fix]:** Make the threshold consistent:
  - A1 records both “acceptable viability” (≤10s) and “UI mode switch threshold” (>5s).
  - State that >10s is product-risk, >5s triggers pagination/streaming requirement.

---

- **[F22]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Submission readiness is much improved, but the spec is still a little thin on release/package verification details for first-pass community review.**
- **[Why]:** You now mention `styles.css`, release assets, linting, `main.js` hygiene, and command naming. Good. But there is no explicit acceptance criterion that the packaged release archive contains exactly the required assets and no dev-only cruft, which is a common review snag.
- **[Fix]:** Add a small acceptance check under OAI-022 or AC9: “Release asset inspection confirms zip includes `manifest.json`, `main.js`, `styles.css` and excludes source maps/tests/dev files unless intentionally shipped.”

---

- **[F23]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: UNVERIFIABLE CLAIM: “verified against `obsidianmd/obsidian-developer-docs` and `obsidianmd/obsidian-sample-plugin` template on 2026-04-25; citations pending pin per G4.”**
- **[Why]:** The spec itself says citations are pending. Per review instructions, this cannot be silently accepted. These platform facts may well be right, but they remain unpinned and therefore not independently verifiable from this artifact.
- **[Fix]:** Resolve G4 before PLAN by pinning exact URLs/commit SHAs in the research brief and referencing them here.

---

- **[F24]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: UNVERIFIABLE CLAIM: “Plugin id in `manifest.json` cannot contain the substring ‘obsidian’.”**
- **[Why]:** This may be true per community submission guidance, but the citation is not provided in this artifact.
- **[Fix]:** Pin source in G4 and optionally quote the exact rule text in the research brief.

---

- **[F25]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: UNVERIFIABLE CLAIM: “`eslint-plugin-obsidianmd` is the official lint plugin and is in the current sample template.”**
- **[Why]:** Plausible, but unpinned in the artifact.
- **[Fix]:** Add exact source URL and version/commit under G4.

---

- **[F26]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: UNVERIFIABLE CLAIM: “AppleScript `delete` against an Apple Notes note moves it to Apple Notes’ Recently Deleted folder — empirically validated G1 on 2026-04-25” and “baseline: 26.3.1.”**
- **[Why]:** The artifact references probe files, which is better than a bare assertion, but the reviewer cannot inspect those files here. Also “macOS 26.3.1” is an unusual version string relative to public naming conventions and cannot be independently confirmed from this document alone.
- **[Fix]:** Keep as gated empirical evidence, but ensure probe output is included and machine/Notes version metadata are captured in the probe result file.

---

- **[F27]**
- **[Severity]: MINOR**
- **[Finding]: The spec still assumes `body of note` returns HTML reliably, but OAI-006 acceptance only says it returns `bodyHtml`; it does not say what happens if Notes returns rich text fragments, missing wrappers, or malformed HTML.**
- **[Why]:** This is partly covered by A3, but some implementation guidance could prevent avoidable parser brittleness.
- **[Fix]:** Add one line under OAI-006 or OAI-009: parser must tolerate fragment HTML and wrap as needed before preprocessing/turndown.

---

- **[F28]**
- **[Severity]: STRENGTH**
- **[Finding]: The spec is internally much clearer than rev 1 about safety invariants and where product viability must be proven before planning.**
- **[Why]:** The distinction between “spec revision required” assumptions and “PLAN spike” assumptions is one of the strongest improvements in this revision.
- **[Fix]:** None required.

---

## Focus-area summary

### 1. Round-1 must-fix coverage
Mostly yes.
- Composite verify-before-delete: **yes**, but sequencing needs one consistency fix.
- Pre-PLAN gate: **yes**, structurally strong.
- G1 evidence trail: **adequate in principle**, though still uninspectable from the artifact.
- Index corruption handling: **yes**, but repair conflict policy needs more detail.
- Batch transaction model: **yes**, good fix.
- M6 split: **mostly yes**, but ownership boundaries need cleanup.
- OAI-008a/008b split: **yes**, strong fix.
- Dependency graph fixes: **mostly yes**, one possible over-serialization around OAI-013 ← OAI-019.
- TCC first-command probe: **yes**, with one settings-edge-case to clarify.
- HTML preprocessing + node filters: **yes**, adequate for spec level.

### 2. Regressions introduced by revision
No major regressions, but a few new risks:
- sequencing contradiction around index verification,
- debug-mode inline raw HTML may create privacy leakage,
- startup Notice on off-platform may be noisy.

### 3. Remaining gaps
Main remaining gaps are:
- G2 pass/fail criteria,
- G3 type-specific decision thresholds,
- index rebuild conflict policy,
- explicit cancellation boundary,
- stronger release-package acceptance check.

### 4. Pre-PLAN gate adequacy
- **G2:** not yet concrete enough.
- **G3:** much improved, but still needs required-vs-best-effort thresholds.
- **G4:** correctly recognized as blocking, but still unresolved.

### 5. Submission readiness
Close, but not fully there.
The spec is now likely sufficient to drive an implementation that could pass community review, **provided** G4 is resolved and release packaging checks are made explicit. `styles.css` is now covered enough at the spec level; I do not think that specific point needs more detail.

---

## Verdict

**ONE MORE ROUND**

The revision is substantially better and has addressed most round-1 must-fix items well, but a final tightening pass is warranted before PLAN because the remaining issues are concentrated in the new safety-critical sections: unify verify/index sequencing, harden G2/G3 acceptance criteria, and specify index-repair conflict handling.

---

## Google (gemini-3.1-pro-preview)

This is a highly mature, defensively engineered specification. The author has done an exceptional job absorbing the round-1 feedback, particularly around data-safety. The decomposition of the import orchestrator (M6) into specific pipeline, verification, and execution stages represents a best-in-class approach for an Obsidian plugin performing destructive operations. 

Below is the round-2 review, assessing the revisions, remaining gaps, and submission readiness.

### UNVERIFIABLE CLAIMS (SIGNIFICANT)
Per the system instructions, the following factual claims could not be independently verified and must be flagged:
*   **UNVERIFIABLE CLAIM:** `macOS 26.3.1` (referenced in G1). As of early 2024, the current macOS versions are 14 (Sonoma) / 15 (Sequoia). macOS 26 is either a typo or a projected future version that cannot be validated today. 
*   **UNVERIFIABLE CLAIM:** `~/Library/Group Containers/group.com.apple.notes/Media/` (referenced in OAI-008a). While Apple Notes does use the Group Containers and Containers directories, the exact path and structure for reliable binary extraction across all OS versions requires specific empirical validation.
*   **UNVERIFIABLE CLAIM:** `eslint-plugin-obsidianmd` (referenced in Facts). There is no widely recognized official ESLint plugin by this exact name in the standard Obsidian ecosystem (developers typically use standard `@typescript-eslint` rules or the community `eslint-plugin-obsidian`).

### FINDINGS

- **[F1]**
- **Severity:** STRENGTH
- **Finding:** The Composite Verify (OAI-016b) and Index Corruption (OAI-012) handling are exceptionally well-designed.
- **Why:** In round 1, data safety was a major concern. By explicitly hashing the expected markdown string in memory, writing to disk, and reading it back to compare hashes—coupled with a safe-degraded rebuild mode for the index—you have created a virtually bulletproof gate against data loss from partial writes or sync conflicts.

- **[F2]**
- **Severity:** SIGNIFICANT
- **Finding:** The import index (`data.json`) will become silently stale if the user natively moves or renames imported notes inside Obsidian.
- **Why:** OAI-012 persists `{appleNotesId → {vaultPath, contentHash, importedAt}}`. If a user moves an imported file to a different vault folder, the `vaultPath` in the index breaks. Future re-imports or UI badge logic might fail, or it might result in duplicate imports because the plugin can't find the file at the old path.
- **Fix:** Add a task in M4 (or modify OAI-012) to register `app.vault.on('rename')` and `app.vault.on('delete')` event listeners. When an imported file is moved or deleted natively in Obsidian, the plugin should update or remove the corresponding index entry in `data.json`.

- **[F3]**
- **Severity:** SIGNIFICANT
- **Finding:** Platform gate (OAI-020) explicitly prevents command registration on non-macOS, but misses the Ribbon Icon.
- **Why:** OAI-015 specifies that the ribbon icon launches the modal. If OAI-020 only skips *command* registration, non-macOS users will still see the ribbon icon. Clicking it will likely throw an error or open a broken modal.
- **Fix:** Update OAI-020 to explicitly block *all* UI element registration (commands, ribbon icons, and settings tab) when `Platform.isMacOS === false`. 

- **[F4]**
- **Severity:** MINOR
- **Finding:** The UI interaction for overriding the "already imported" gate is under-specified.
- **Why:** AC6 and OAI-013 state that imported notes are "disabled by default with badge" and mention a "show already-imported" toggle. It is unclear if toggling "show" also *enables* the checkboxes so they can be re-selected, or if there is a separate "allow re-import" override interaction. 
- **Fix:** Clarify in OAI-013: "Checking the 'show already-imported' toggle makes these notes visible AND enables their checkboxes for selection. Re-importing forces a new unique filename per OAI-010."

- **[F5]**
- **Severity:** MINOR
- **Finding:** Batch execution concurrency is not explicitly defined in OAI-016d.
- **Why:** Spawning 50 simultaneous `child_process.execFile osascript` calls for a 50-note batch selection will likely cause macOS to drop Apple Events or trigger an AppleScript execution bottleneck.
- **Fix:** Explicitly note in OAI-016d that the per-note batch execution loop must run **sequentially** (awaiting the completion of one note's pipeline before starting the next) to respect AppleScript/TCC concurrency limits.

### Review against specific focus areas:
1.  **Must-fix coverage:** All round-1 must-fix items were addressed masterfully. The separation of M6 completely resolves the risk of muddy task boundaries. The sequencing of the TCC probe avoids spamming the user on vault load. The Pre-PLAN gate accurately isolates existential risks from implementation details.
2.  **Regressions:** No regressions introduced. The M6 split creates a slightly longer critical path, but it is a necessary tradeoff for data safety.
3.  **Pre-PLAN gate adequacy:** G2 and G3 are sufficiently defined to execute. G3's criteria (≥95% reliability, <2s latency) are clear enough to form an objective pass/fail threshold.
4.  **Submission readiness:** The spec tightly adheres to Obsidian's documented plugin guidelines. Once the minor UI platform-gate fix (F3) is applied, it will be perfectly positioned to pass community review.

### VERDICT
**READY FOR PLAN**

This specification is highly rigorous. The data-loss protections are particularly commendable. Address the minor UI state logic (F3, F4) and the vault event listeners for the index (F2) as quick patches during the transition into the PLAN phase. You are clear to proceed.

---

## DeepSeek (deepseek-reasoner)

## Peer Review – Round 2: obsidian-applenotes-import (rev 2)

**Verdict:** `READY FOR PLAN`

The specification is thorough, internally consistent, and shows a mature response to all 28 round‑1 findings. The Pre‑PLAN validation gates, composite verify contract, index corruption recovery, batch transaction model, and M6 reorganisation are all addressed with the necessary depth. No regressions were introduced. The remaining gaps are minor and can be safely resolved during PLAN or IMPLEMENT.

---

### Findings

#### F1 – Pre‑PLAN gate G2 (note id stability) probe specification
**Severity:** SIGNIFICANT  
**Finding:** The probe criteria are listed as “restart, post‑restart edit, move between folders, iCloud↔On‑My‑Mac account where available”. This is a good high‑level scope but does not define a pass/fail threshold (e.g., “id remains identical across at least 3 restarts and after an edit”).  
**Why:** Without a clear pass criterion the probe result may be ambiguous, delaying PLAN entry.  
**Fix:** Add an explicit acceptance statement such as: “The probe is considered VALIDATED if the id of a given note remains unchanged after (i) three restarts of the Notes app, (ii) one edit to the note’s title and one edit to its body, and (iii) a move into a different folder and back. If the id changes under any of these conditions, return to SPECIFY.”

#### F2 – TCC probe timing vs. settings‑only first contact
**Severity:** MINOR  
**Finding:** The spec now correctly triggers the TCC probe on the first user‑initiated command invocation (not plugin load). However, a user might open the Settings tab (which is available even on non‑macOS, though commands are disabled) before ever running a command. In that case they would not see any permission‑related guidance until they attempt an import.  
**Why:** This could create a brief “why can’t I use this?” moment.  
**Fix:** Consider also running the probe when the Settings tab is first opened, but only if the user has never run a command (or simply run it once on every Settings open). The current “Re‑check” button in settings already provides a manual escape, so this is a minor UX polish, not a blocker.

#### F3 – Composite verify: index read‑back success check
**Severity:** MINOR  
**Finding:** The verify gate (OAI‑016b) checks that the index “persisted + readback succeeds”. The spec does not detail *how* readback proves integrity – e.g., is a simple deserialisation enough, or should a checksum of the stored data be verified?  
**Why:** A parity or checksum check would be more robust against silent storage corruption.  
**Fix:** Add a note that the index should be written with a trailing SHA‑256 of the JSON content (or a simple validation that `JSON.parse(written)` round‑trips losslessly). This can be refined in PLAN.

#### F4 – Drawing/sketch attachment handling
**Severity:** MINOR  
**Finding:** The attachment support matrix lists “Drawing/sketch: Best‑effort PNG fallback”. The spec does not describe how the PNG is obtained – whether from AppleScript’s export, the filesystem cache, or a rendering workaround.  
**Why:** The approach chosen in OAI‑008a will directly affect whether PNG extraction is feasible (e.g., the Group Container may hold a proprietary `.textinput` or `.drawing` file that needs conversion).  
**Fix:** No change needed now; this falls under OAI‑008a/b. The spec appropriately defers to the dual probe.

#### F5 – Index corruption recovery: frontmatter scan performance
**Severity:** MINOR  
**Finding:** The index repair mechanism scans the entire vault for `apple_notes_id` frontmatter. In a large vault (e.g., 10 000 notes) this could be slow.  
**Why:** The spec currently does not mention any performance consideration or fallback (e.g., limiting scan to configured vault folder).  
**Fix:** Add a note that the scan should be limited to the plugin’s configured import folder (or a reasonable default), and that a progress indicator should be shown if the scan takes more than 2 seconds.

#### F6 – Conversion warning tiers: debug‑only raw HTML
**Severity:** MINOR  
**Finding:** The “Debug‑only” tier inserts raw source HTML into the note body. This could inadvertently expose sensitive information (e.g., embedded scripts, private data) even in debug mode.  
**Why:** While the debug mode is off by default and user‑enabled, the spec should caution about this and recommend stripping of potentially sensitive attributes (e.g., `data‑*` or Apple‑internal identifiers) before inclusion.  
**Fix:** Add a brief note: “Debug‑only HTML insertions should be sanitised to remove Apple‑internal IDs and any attributes that could contain personally identifiable information.”

#### F7 – Unverifiable claims
**Severity:** None – the spec does not contain external references that cannot be verified internally (the research brief is local; AppleScript behaviour is validated; all other claims are design decisions). No “UNVERIFIABLE CLAIM” flag needed.

---

### Strengths

- **Pre‑PLAN gate structure:** The explicit gating of G2/G3/G4 before PLAN entry is a clear improvement and reduces risk of late‑stage surprises.
- **Composite verify contract:** The five‑point check (file existence, hash, attachment existence, reference resolution, index integrity) is robust and directly addresses the critical data‑loss risk.
- **Index corruption recovery:** Safe‑degraded mode plus frontmatter rebuild is a solid, transparent fallback.
- **Batch transaction model:** Per‑note independence, cancel‑after‑current, and final summary dialog are well‑specified.
- **M6 task decomposition:** The split into 016a..e cleanly separates concerns (sequencing, verification, delete gate, batch execution, receipts). The dependency graph is consistent.
- **OAI‑008 dual probe:** Splitting into probe + decision avoids premature commitment to a potentially infeasible attachment method.
- **Submission checklist:** The spec explicitly covers `isDesktopOnly`, `no innerHTML`, `instanceof` checks, `registerEvent`, `styles.css` as first‑class asset, etc.

---

### Conclusion

The spec is ready to move into PLAN. The few minor gaps (G2 probe acceptance criteria, TCC edge case, index read‑back details) can be resolved during the Pre‑PLAN spike or PLAN startup without requiring another full review round. No CRITICAL or SIGNIFICANT blockers remain.

**Recommendation:** Proceed to PLAN, with the author addressing F2, F3, F5, F6 as part of the first PLAN work session.

---

## xAI Grok (grok-4-1-fast-reasoning)

[F1]  
[Severity]: STRENGTH  
[Finding]: Round-1 must-fix on composite verify-before-delete contract addressed comprehensively in OAI-016b, now explicitly covering md existence + pre-write hash match + attachment files (existence/non-zero size) + md ref resolution + index persist/readback; integrated into AC5 with adversarial tests specified.  
[Why]: This is the highest-risk failure mode (source data loss); the revision strengthens safety without overcomplicating sequencing.  
[Fix]: N/A  

[F2]  
[Severity]: SIGNIFICANT  
[Finding]: Pre-PLAN Validation Gate (G1) cites specific probe files (`design/probes/a4-soft-delete.applescript` and `a4-probe-result.md`), but no excerpt or summary of results is in-spec; reader must assume external files exist and confirm soft-delete.  
[Why]: SPECIFY-phase specs should be self-contained for peer review; external dependencies reduce review efficiency and introduce verification gaps.  
[Fix]: Inline a 1-2 sentence summary of probe results (e.g., "Probe created note X, deleted via script, confirmed in Recently Deleted folder Y with timestamp Z") or screenshot snippet.  

[F3]  
[Severity]: SIGNIFICANT  
[Finding]: UNVERIFIABLE CLAIM: AppleScript `delete` empirically validated on "macOS 26.3.1" (multiple mentions, e.g., G1, Facts, LD-02); no public macOS versioning confirms this exists (current real-world is ~14.x in 2024).  
[Why]: Factual baseline for re-validation trigger ("if macOS major version changes"); unverifiable dates/versions undermine assumptions like A4 stability.  
[Fix]: Flag as fictional/future or cite real macOS version used (e.g., "macOS Sonoma 14.4"); generalize re-validation to "any macOS update post-probe".  

[F4]  
[Severity]: STRENGTH  
[Finding]: Index corruption handling upgraded to safe-degraded mode + frontmatter-scan rebuild (OAI-012, AC6); explicitly avoids silent reset, with Notice + "Repair" action.  
[Why]: Addresses round-1 must-fix directly; sound resilience for data.json volatility in Obsidian plugins.  
[Fix]: N/A  

[F5]  
[Severity]: CRITICAL  
[Finding]: Batch transaction model (AC11, OAI-016d) specifies "per-note independence" and "md left in vault if attachments fail", but no cleanup spec for partial attachment temp dirs beyond "incomplete attachment temp directories are cleaned up" (OAI-011); orphaned temps could accumulate disk usage indefinitely.  
[Why]: Regresses data hygiene; in batch failures, repeated runs create temp bloat, eroding trust in "safe" deletes.  
[Fix]: Add to OAI-016d AC: "All temp dirs/files cleaned post-note regardless of outcome (success via move, failure via delete)"; specify temp pattern (e.g., vault-adjacent `.tmp-apple-import-<id>`).  

[F6]  
[Severity]: SIGNIFICANT  
[Finding]: M6 split into OAI-016a..e cleanly separates concerns (transaction model, verify, delete-gate, batch, receipt), with logical deps (016a → b → c → d → e); no coordination issues evident.  
[Why]: Round-1 must-fix on monolithic M6 resolved; improves TASK parallelism without fragmentation. Wait—challenge: OAI-016e (receipt) appends *after* delete but is "NOT a delete gate"—but if receipt write fails post-delete, no log of success? Minor sequencing gap.  
[Fix]: Clarify receipt as post-delete non-critical (already noted), but add "receipt failure logs to console/Notice only".  

[F7]  
[Severity]: MINOR  
[Finding]: OAI-008a/b split (probe → implement) correctly sequences G3 decision before M3/M6; decision doc repo-local as specified.  
[Why]: Addresses round-1 dep fix; frees downstream without blocking.  
[Fix]: N/A (but see F8 for probe detail gap).  

[F8]  
[Severity]: SIGNIFICANT  
[Finding]: Pre-PLAN G3 (A7 attachment probe) criteria (≥95% reliability, <2s/att, no extra perms) good, but acceptance lacks concrete test matrix (e.g., #samples per type, pass/fail thresholds); G2 (id stability) lists scenarios but no "stable if unchanged across N trials".  
[Why]: Probes under-specified for execution; risks inconclusive results forcing mid-PROBE spec changes. Round-1 gap in gating rigor persists.  
[Fix]: Add to G2/G3 tables: "Run N=5 trials per scenario; id matches exactly (byte-for-byte)"; for G3, "Test 10 notes/type from real library".  

[F9]  
[Severity]: SIGNIFICANT  
[Finding]: Dependency graph fixes (e.g., OAI-013 now deps OAI-006/019, OAI-016 on 007/008b/011/012) correct, but summary diagram has M7-OAI-019 before M6 while table places M7 after M5; visual/text mismatch.  
[Why]: Confuses TASK sequencing; risks premature UI wiring without TCC handler.  
[Fix]: Reorder diagram: insert M7 parallel to M5 (OAI-019 deps only OAI-004/015, early).  

[F10]  
[Severity]: STRENGTH  
[Finding]: TCC probe on first-command (OAI-019, AC8) cleaner than load-time; covers patterns (-1743, text), timeout/generic fallbacks; settings guidance explicit. Edge: settings-open-first ok (probe lazy).  
[Why]: Improves UX over round-1; no regressions.  
[Fix]: N/A  

[F11]  
[Severity]: MINOR  
[Finding]: HTML pre-processing + turndown node-filters (OAI-009) directs impl well ("catch unknown tags → [!warning]", golden tests on real HTML); tiers integrated into verify.  
[Why]: Round-1 must-fix adequate; fidelity risks mitigated.  
[Fix]: N/A  

[F12]  
[Severity]: SIGNIFICANT  
[Finding]: No regressions from revision 2: platform gate stronger (no cmds on non-macOS), warning tiers enhance safety, M6 split improves; but new conversion tiers table lacks "how severe/moderate decided" (e.g., attachment fail=severe hardcoded?).  
[Why]: Tiers under-specified; risks inconsistent delete-blocking (e.g., sketch=moderate always?).  
[Fix]: Add to tiers: "Severe: any required-matrix type fails (per OAI-008b); Moderate: non-required or partial fidelity (logged)".  

[F13]  
[Severity]: SIGNIFICANT  
[Finding]: Remaining gap: manifest minAppVersion still "TBD" despite OAI-002 AC requiring "concrete version"; OAI-002 deps research but no output spec (e.g., ≥1.4.0?).  
[Why]: Blocks PLAN; submission reject risk (AC9).  
[Fix]: Pre-populate from research-brief or note "OAI-002 resolves to X.Y.Z".  

[F14]  
[Severity]: MINOR  
[Finding]: styles.css mentioned repeatedly (AC9, OAI-013, manifest notes) but zero content spec (e.g., table styles, modal dims); assumes impl infers.  
[Why]: Submission ok (just commit empty?), but UI polish gap; low risk.  
[Fix]: Add 2-3 bullet styles (e.g., ".note-row { display: grid; }").  

[F15]  
[Severity]: CRITICAL  
[Finding]: Submission readiness gap: AC9 lists rules but omits `fundingUrl` omission rationale (now in manifest note, good); however, eslint-plugin version unpinned (G4 pending), no "authorClass" if needed; critically, no mobile handling spec beyond "no cmds" (Obsidian mobile loads plugins?).  
[Why]: Real Obsidian plugins must handle mobile load (even desktopOnly); `isDesktopOnly: true` hides from mobile search but loads if installed—risk console spam or leaks. Round-1 compliance incomplete.  
[Fix]: Add AC7 extension: "On mobile, early return in load() + Notice"; pin eslint in OAI-001.  

[F16]  
[Severity]: SIGNIFICANT  
[Finding]: UNVERIFIABLE CLAIM: Obsidian facts (e.g., "no-obsidian-in-id", eslint-plugin, sample template) sourced from research-brief with "citations pending G4"; no inline links/SHAs.  
[Why]: G4 pending blocks PLAN; unverifiable without externals.  
[Fix]: Resolve G4 in this round or gate review signoff.  

**Verdict: ONE MORE ROUND**  
All 28 round-1 actions applied without major regressions, strengthening safety (verify gate, index, batch) and gating (Pre-PLAN), but critical gaps in temp cleanup (F5), submission mobile handling (F15), probe specs (F8), and pending G4 (F16) require fixes; significant deps/visual mismatches (F9) and TBDs (F13) risk PLAN stalls. Address CRITICAL/SIGNIFICANT, re-probe G2/G3/G4, then ready.

---

## Synthesis (Claude)

**Headline.** Verdict is split 2/2 — Google and DeepSeek say **READY FOR PLAN**, OpenAI and Grok say **ONE MORE ROUND**. The disagreement is about depth, not direction: no reviewer flagged an architecture concern, and all four reinforced the round-1 must-fix areas (composite verify, Pre-PLAN gate, index corruption, batch model, M6 split, OAI-008 split, TCC first-command, HTML preprocessing) as adequately addressed. The "one more round" verdicts converge on concrete depth additions — probe acceptance thresholds, sequencing consistency, repair conflict policy, mobile handling, temp cleanup. None of these requires structural change.

There is, however, **one real spec bug** caught by OpenAI: the verify gate claims to include "index persisted + readback" but the pipeline in OAI-016a places `persist index` AFTER `composite verify`. These cannot both be true. This is a 1-line fix but must be resolved.

### Consensus Findings (2+ reviewers)

| # | Severity | Finding | Reviewers |
|---|---|---|---|
| C1 | SIGNIFICANT | G2 (note id stability) probe still lacks a concrete pass/fail threshold (e.g., "id matches across N restarts + edit + folder move within account"). | OAI-F4, DS-F1, GRK-F8 (3/4) |
| C2 | SIGNIFICANT | G3 (attachment extraction) probe criteria need per-class thresholds — "≥95% across all types" is too aggregate. Required types (image/PDF/audio/scan) need ≥95% each; best-effort types (drawing, bookmark) probe-determined. | OAI-F5, GRK-F8 (2/4) |
| C3 | SIGNIFICANT | G4 unresolved — upstream citations (eslint-plugin-obsidianmd version, "no-obsidian-in-id" rule, sample template HEAD) still pending pin. | OAI-F23/24/25, GEM (unverifiable cluster), GRK-F16 (4/4) |
| C4 | SIGNIFICANT | Conversion tier escalation rules under-specified — severe tier currently mostly attachment-centric; should also cover substantive content loss (e.g., checklist/table collapsing into near-empty output). | OAI-F18, GRK-F12 (2/4) |
| C5 | SIGNIFICANT | Debug-mode inline raw HTML in note body is a privacy regression — vault sync would propagate raw source. Should move to receipt-only or explicit per-import opt-in with sanitization. | OAI-F19, DS-F6 (2/4) |
| C6 | MINOR | TCC settings edge cases — does the "Re-check permission" button count as a user-initiated probe? Specify yes. | OAI-F16, DS-F2 (2/4) |
| C7 | NOISE | "macOS 26.3.1" flagged as anachronism — knowledge-cutoff false positive (system IS 2026-04-25; sw_vers confirms 26.3.1). Real but recordable concern: probe metadata should be self-evidenced inline. | GEM (unverifiable cluster), GRK-F3 (2/4) — DECLINED, see below |

### Unique Findings (single reviewer)

| # | Severity | Finding | Source | Verdict |
|---|---|---|---|---|
| U1 | **CRITICAL** | **Sequencing contradiction:** verify gate claims to include "index persisted+readback" but OAI-016a pipeline places persist AFTER verify. Real spec bug. | OAI-F2 | Real bug, must fix |
| U2 | SIGNIFICANT | Index repair conflict policy missing: duplicate ids, missing paths, frontmatter/hash mismatch, manual edits — all undefined. | OAI-F7 | Genuine gap |
| U3 | CRITICAL | Platform gate misses ribbon icon: OAI-020 only blocks commands; OAI-015 ribbon will still register on non-macOS, then error on click. | GEM-F3 | Real bug |
| U4 | SIGNIFICANT | Index becomes silently stale on native vault rename/delete of imported files. Need `vault.on('rename')` + `vault.on('delete')` listeners. | GEM-F2 | Genuine gap |
| U5 | MINOR | Batch concurrency must be **sequential** (not parallel) — concurrent osascript→Notes calls overwhelm Apple Events. Specify in OAI-016d. | GEM-F5 | Genuine, easy spec add |
| U6 | CRITICAL | Temp file cleanup gap: orphaned attachment temp dirs could accumulate across runs. | GRK-F5 | Genuine gap |
| U7 | CRITICAL | Mobile handling beyond "no commands": `isDesktopOnly: true` hides from mobile plugin search but plugin still loads if synced. Need early-return in `onload()` before side effects. | GRK-F15 | Genuine gap |
| U8 | SIGNIFICANT | M6 task boundaries overlap: OAI-016a embeds verification logic that 016b should own. Tighten to: 016a=orchestration only, 016b=pure verify, 016c=only "invoke delete iff verify=success". | OAI-F10 | Genuine refinement |
| U9 | SIGNIFICANT | Dependency-graph diagram vs table mismatch (M7-OAI-019 placement). | GRK-F9 | Real visual bug |
| U10 | SIGNIFICANT | OAI-013 over-serialization on OAI-019 — modal can be built with mocks; only OAI-015 (command wiring) needs TCC dep. | OAI-F14 | Genuine planning flexibility gain |
| U11 | SIGNIFICANT | minAppVersion still "TBD" — OAI-002 has the research subtask but no committed value. | GRK-F13 | Procedural, must resolve |
| U12 | SIGNIFICANT | Probe results not inlined in spec — must consult external file. Spec should be self-contained for review. | GRK-F2 | Genuine self-containment fix |
| U13 | SIGNIFICANT | AC1 vs A1 threshold misalignment: A1 records ≤10s viability but AC1 says >5s triggers pagination. Unify into one decision rule with two thresholds. | OAI-F21 | Genuine clarity fix |
| U14 | SIGNIFICANT | No release-asset inspection AC — common community-review snag (extra files in zip, missing styles.css, etc.). | OAI-F22 | Genuine M8 add |
| U15 | MINOR | Body HTML parser must tolerate fragments / malformed input from `body of note`. | OAI-F27 | Sensible note |
| U16 | MINOR | "Show already-imported" UI interaction — does toggle re-enable checkboxes for re-import? Specify. | GEM-F4 | Genuine clarification |
| U17 | MINOR | Index repair scan should limit to configured import folder + progress indicator if >2s on large vaults. | DS-F5 | Reasonable |
| U18 | MINOR | Cancel-after-current: mid-pipeline note completes; cancellation observed between transactions. State explicitly. | OAI-F9 | Reasonable |
| U19 | MINOR | Off-platform Notice frequency — once per install/version, not every load. | OAI-F20 | Reasonable UX |
| U20 | MINOR | Receipt-write failure post-delete: log to console; do not roll back delete. | GRK-F6 | Sensible note |
| U21 | MINOR | Index readback integrity check method — JSON roundtrip or SHA-256. | DS-F3 | PLAN-stage detail |
| U22 | MINOR | styles.css content stub — at least minimal selectors to avoid empty file. | GRK-F14 | Polish |
| U23 | MINOR | G1 probe metadata — record `sw_vers` output inline in probe-result file for self-evidence. | (Claude consequence of C7 noise) | Genuine improvement |

### Contradictions

None substantive. The verdict split (READY vs ONE MORE ROUND) reflects different bars for "ready," not technical disagreement. All four reviewers identify the same set of remaining gaps — they disagree only on whether those gaps are PLAN-blocking or PLAN-startup polish. Claude's read: U1 (sequencing bug), U3 (ribbon platform-gate bug), and U9 (diagram/table mismatch) are real bugs that warrant fixing now; the rest is polish that scales with how much rigor we want before PLAN.

### Action Items

#### Must-fix (real bugs or critical clarity)

| ID | What to do | Source |
|---|---|---|
| **B1** | Fix sequencing: choose pipeline `… write md → persist index → composite verify (incl. index readback) → soft-delete → append receipt`; align System Map, AC5, OAI-016a, OAI-016b to that single sequence. | U1 |
| **B2** | Define G2 acceptance: "Pass only if `id of note` remains byte-identical across (i) 3 Notes app restarts, (ii) post-restart edit to title and body, (iii) folder move within same account. If cross-account move changes id, downgrade dedupe to account-scoped (document, do not block). If any same-account scenario changes id, return to SPECIFY." | C1 |
| **B3** | Define G3 acceptance per support class: required types (image, PDF, audio, scanned doc) ≥95% extraction success each; best-effort types (drawing/sketch, web bookmark) probe determines warning semantics; failure on any required type or unacceptable Full-Disk-Access UX → return to SPECIFY. Sample size ≥10 notes per type. | C2 |
| **B4** | Resolve G4: pin source URLs and commit SHAs in `design/research-brief-plugin-platform.md` for: (a) "no-obsidian-in-id" submission rule, (b) `eslint-plugin-obsidianmd` package + version, (c) sample-plugin template HEAD. | C3 |
| **B5** | Update OAI-020 acceptance: `Platform.isMacOS === false` → skip ALL UI registration (commands, ribbon icon, settings tab modal). | U3 |
| **B6** | Add OAI-012 vault listeners: register `app.vault.on('rename')` and `app.vault.on('delete')` to keep index in sync when imported files are moved/renamed/deleted natively. | U4 |
| **B7** | Add to OAI-016d acceptance: "Batch executes notes **sequentially** (await each note's pipeline completion before starting the next) to respect Apple Events concurrency limits." | U5 |
| **B8** | Add temp file cleanup contract: temp pattern (e.g., `.tmp-applenotes-import-<id>` adjacent to attachments folder); cleaned post-note regardless of outcome. Specify in OAI-011 and OAI-016d. | U6 |
| **B9** | Add explicit mobile handling: in OAI-002/OAI-020 acceptance, `onload()` does early-return on `Platform.isMobile === true` (or `!Platform.isMacOS`) before any side effects. Add AC7 extension: "On mobile, `onload` is a no-op except for the one-time platform Notice." | U7 |
| **B10** | Tighten M6 task boundaries: OAI-016a pure orchestration (sequencing only, no verify rules embedded); OAI-016b pure verify (returns success/failure schema); OAI-016c pure delete-gate (only "invoke delete iff verify=success"). State the function contract in one sentence. | U8 |
| **B11** | Fix dependency-graph diagram to match the table (M7-OAI-019 placement; M7 sequencing relative to M5/M6). | U9 |
| **B12** | Loosen OAI-013 deps: modal can be developed with mock data; move TCC dep from OAI-013 to OAI-015 (command wiring is where TCC matters). | U10 |
| **B13** | Resolve minAppVersion: either (a) commit a concrete version in OAI-002 acceptance based on the API surface reasoning in the research-brief, OR (b) state "must resolve to a concrete `X.Y.Z` value before PLAN→TASK transition." | U11 |
| **B14** | Inline a 1–2 sentence G1 probe summary in spec §Pre-PLAN Validation Gate so the spec is self-contained for review. | U12 |
| **B15** | Inline `sw_vers -productVersion` output in `design/probes/a4-probe-result.md` for self-evidence (addresses C7 noise + future audit). | U23 |

#### Should-fix

| ID | What to do | Source |
|---|---|---|
| B16 | Specify conversion tier escalation: severe = required-matrix attachment fail OR substantive body content cannot be represented (e.g., checklist/table collapsing to near-empty output); moderate = formatting degradation only; debug = telemetry. | C4 |
| B17 | Move debug-mode raw HTML from "inline in note body" to receipts/log only. If kept inline, gate behind a separate "embed diagnostics in imported notes" setting (off by default) AND sanitize to remove Apple-internal IDs / data-* attributes. | C5 |
| B18 | OAI-019 settings tab: explicitly state that "Re-check permission" button counts as a user-initiated probe. | C6 |
| B19 | Add to AC9 / OAI-022: "Release asset inspection — zip contains exactly `manifest.json`, `main.js`, `styles.css`; no source maps, tests, or dev files unless intentionally shipped." | U14 |
| B20 | Unify AC1 ↔ A1 thresholds: A1 records BOTH viability (≤10s for 1k) AND UI-mode-switch trigger (>5s → pagination required). State as one rule in spec. | U13 |
| B21 | Add to OAI-006 / OAI-009: "HTML parser tolerates fragment HTML and malformed input — wraps as needed before preprocessing/turndown." | U15 |
| B22 | Clarify OAI-013 acceptance: "Toggling 'show already-imported' makes those notes visible AND enables their checkboxes for re-selection. Re-import forces a new unique filename per OAI-010 (never overwrites)." | U16 |
| B23 | OAI-012 repair: scan limited to configured import folder by default (configurable to whole-vault). Show progress indicator if scan exceeds 2s. | U17 |
| B24 | OAI-016d acceptance addendum: "Cancel-after-current is observed only between note transactions; once a note enters the verify→delete phase, its pipeline runs to completion for consistency." | U18 |
| B25 | OAI-020 acceptance addendum: "Platform-Notice on off-platform load shown once per install/version (de-dup via stored marker), not every reload." | U19 |
| B26 | OAI-016e addendum: "Receipt-write failure logs to console + Notice; does NOT roll back the soft-delete. The delete already occurred; the receipt is post-hoc record-keeping." | U20 |
| B27 | OAI-012 readback contract: index readback succeeds iff `JSON.parse(written)` round-trips losslessly AND structural shape matches expected schema (no checksum required for v1; revisit if storage corruption observed). | U21 |
| B28 | Add minimal `styles.css` content spec to OAI-013: at least 3-4 selectors covering the modal table, row-disabled state, and badge. | U22 |
| B29 | Add OAI-012 index repair conflict policy: duplicate `apple_notes_id` → mark ambiguous, keep delete disabled until user resolves; missing path → drop entry + log; frontmatter/hash mismatch → rebuild with current path but mark `untrusted: true` in index entry; repair report appended to receipt. | U2 |

### Considered and Declined

| Finding | Verdict | Reason category |
|---|---|---|
| **GEM/GRK** macOS 26.3.1 flagged as unverifiable / anachronism | INCORRECT — knowledge-cutoff false positive. Today's date is 2026-04-25 per system context; `sw_vers` confirms macOS 26.3.1. The reviewers' training data predates this version. The legitimate underlying concern (probe metadata self-evidence) is captured by B15. | incorrect |
| **GEM** `eslint-plugin-obsidianmd` not recognized | INCORRECT — confirmed in current `obsidianmd/obsidian-sample-plugin` package.json devDependencies. Reviewer's training data may not reflect this addition. The legitimate concern (citation pin) is captured by B4. | incorrect |
| **GRK-F8** "Run N=5 trials per scenario" specifically | OVERKILL for v1 — B2/B3 specify pass criteria more economically (3 restarts + 1 edit + 1 move + 10 samples per attachment type). N=5 across all dimensions multiplies test surface without proportional confidence. | overkill |

### Verdict Synthesis

The 2/2 split reflects calibration differences, not technical disagreement. All four reviewers independently confirmed the round-1 must-fixes were addressed correctly and that the spec's safety architecture is sound. The remaining items are concentrated in the **new** safety-critical sections (Pre-PLAN gate criteria, repair conflict policy, sequencing detail) and in **product polish** (mobile handling, temp cleanup, UI flow precision). None require architecture change.

**Recommendation:** Apply B1–B29 as revision 3, **then declare SPECIFY done without dispatching round 3.** Reasoning: (a) round-2 already exhausted the high-leverage critique surface; round-3 would target the same areas with diminishing returns; (b) 2/4 reviewers already say READY; (c) the remaining items are best validated by the actual probes during pre-PLAN G2/G3 execution, not by another LLM critique pass; (d) the round cap is 3 — using it on cosmetic confirmation wastes the safety-budget for a real future revision if needed.

If you want belt-and-suspenders confidence, dispatch round 3 in diff mode against revision 3, focused only on B1 (sequencing fix), B5 (ribbon platform gate), B9 (mobile handling), B10 (M6 task boundaries) — the items where mistakes would be expensive.
