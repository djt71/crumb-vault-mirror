---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/tess-v2/design/staging-promotion-design.md
artifact_type: architecture
artifact_hash: a0dfe7d5
prompt_hash: afecf576
base_ref: null
project: tess-v2
domain: software
skill_origin: peer-review
created: 2026-04-01
updated: 2026-04-01
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
    latency_ms: 85386
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-staging-promotion-design-openai.json
  google:
    http_status: 200
    latency_ms: 54976
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-staging-promotion-design-google.json
  deepseek:
    http_status: 200
    latency_ms: 120004
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-staging-promotion-design-deepseek.json
  grok:
    http_status: 200
    latency_ms: 30709
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-staging-promotion-design-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Staging/Promotion Lifecycle Design

**Artifact:** Projects/tess-v2/design/staging-promotion-design.md
**Mode:** full
**Reviewed:** 2026-04-01
**Reviewers:** OpenAI GPT-5.4, Google Gemini 3.1 Pro Preview, DeepSeek Reasoner (V3.2), Grok 4.1 Fast Reasoning

**Review prompt:** Architecture review of staging/promotion lifecycle -- crash recovery completeness, write-lock vs promotion-lock distinction, hash-based conflict detection (TOCTOU), atomic promotion, rollback mechanism, scenario walkthroughs, SQLite suitability, retention/cleanup robustness.

---

## OpenAI (gpt-5.4)

## Structured Review

Overall: the design is thoughtful and much stronger than a naive “copy files and hope” approach. The biggest risks are not in the broad architecture, but in a few correctness gaps around transaction boundaries, TOCTOU during promotion, recovery ordering, and path/backup semantics. Those need tightening because this is explicitly the vault-integrity-critical path.

---

## Executive Summary

### Top concerns
1. **Promotion hash verification occurs before acquiring the global promotion lock** — this leaves a TOCTOU window where canonical files can change after verification but before copy.
2. **Write-lock acquisition is specified per-path in separate transactions while also claiming all-or-nothing semantics** — as written, it can leave partial locks behind.
3. **Promotion step ordering around lock release, cleanup, and contract-state update is inconsistent with crash recovery and zombie cleanup rules** — can cause premature lock release or duplicate recovery behavior.
4. **Ancestor/descendant overlap detection via SQL `LIKE path || '%'` is path-prefix unsafe** — false positives/negatives unless path normalization and separator-aware matching are defined.
5. **Rollback backup paths are underspecified for nested files / multiple files with same basename** — can corrupt rollback data.

### Strongest aspects
- Clear separation of **staging-first writes** from canonical promotion.
- Good acknowledgment that promotion is **not truly atomic** and that readers may observe partial state.
- Manifest-driven recovery is the right direction.
- Explicit handling of hash conflicts and external modification is valuable.
- SQLite is a good choice for the lock table.

---

## Findings

### F1
- **Severity:** CRITICAL
- **Finding:** Hash-based conflict detection is performed before acquisition of the promotion lock, creating a TOCTOU race between hash verification and file copy.
- **Why:** The design says in §4.4/§5.2 step 1 that hashes are verified in `PROMOTION_PENDING`, then step 2 acquires the promotion lock, then later copy begins. Another Tess process or external writer can modify the canonical file after hash verification but before the copy. That defeats the stated stale-read protection.
- **Fix:** Move canonical hash verification inside the promotion critical section:
  1. Acquire promotion lock
  2. Re-read current canonical state and verify against stored lock-time hash
  3. Construct/write manifest
  4. Backup
  5. Copy  
  If hash mismatch occurs after lock acquisition, abort promotion and release lock. The design should explicitly state that the hash check and copy are serialized by the promotion lock.

### F2
- **Severity:** CRITICAL
- **Finding:** The write-lock acquisition procedure contradicts its own all-or-nothing guarantee.
- **Why:** §3.4 says “FOR EACH target_path ... BEGIN TRANSACTION ... INSERT ... COMMIT” and later says “If any single path cannot be locked, no locks are acquired for this contract.” As written, if path 1 locks successfully and path 2 fails, path 1 remains locked. That can create leaked partial claims and scheduler pathologies.
- **Fix:** Acquire all target-path locks in a **single SQLite transaction**:
  - Normalize/sort all target paths first
  - Check all conflicts first
  - Compute hashes
  - Insert all rows
  - Commit once  
  If any check fails, rollback the entire transaction. State this explicitly.

### F3
- **Severity:** CRITICAL
- **Finding:** Crash-recovery and lifecycle ordering are inconsistent around lock release, cleanup, and terminal state update.
- **Why:** §5.2 says:
  - step 8 mark manifest completed
  - step 9 release write-locks
  - step 10 release promotion lock
  - step 11 clean staging
  - step 12 update contract state to COMPLETED  
  But §3.6 says write-locks are released when contract reaches terminal state. §3.7 zombie cleanup says if ledger missing/non-terminal, locks should remain. If process crashes after step 9 but before step 12, locks are released while contract is still non-terminal. Recovery logic in §8.1 for `completed` then attempts to release locks again. This is inconsistent and may allow a competing contract to dispatch before the ledger reflects completion.
- **Fix:** Define one authoritative ordering. Recommended:
  1. Finish copy and verification
  2. Mark manifest `completed`
  3. Update contract ledger state to `COMPLETED` with a promotion-completed marker/idempotency token
  4. Release write-locks
  5. Release promotion lock
  6. Cleanup staging opportunistically  
  Recovery logic must be idempotent and tolerate any step repeating. Update §3.6 to match.

### F4
- **Severity:** CRITICAL
- **Finding:** The manifest update protocol is not specified as durable per operation, so recovery may not know whether a copied file was actually promoted before a crash.
- **Why:** Step 6 says “Copy staging file → canonical path; mark operation as promoted: true in manifest; crash resumes from next unpromoted operation.” But if the file copy succeeds and the process crashes before the manifest write is fsynced, recovery may think the operation is unpromoted and copy again. That may be benign for pure overwrite of identical bytes, but it is not stated as a required invariant; and if external changes happened in the window, behavior becomes ambiguous.
- **Fix:** Specify durability semantics:
  - After writing/rewriting manifest, flush and `fsync` file and containing directory
  - Define copy as write-to-temp + atomic rename where possible
  - State recovery rule for “destination already equals staging source but manifest says promoted=false”: mark as promoted and continue.

### F5
- **Severity:** CRITICAL
- **Finding:** The recovery procedure does not fully specify how to distinguish “backup incomplete” from “copy phase interrupted,” and the manifest schema does not contain enough state to do so reliably.
- **Why:** §8.1 includes a case `in_progress (with backup incomplete)`, but the manifest schema has only global `status` and per-operation `promoted`. There is no per-operation `backup_completed` flag, no backup-phase marker, and no canonical backup hash. Recovery cannot safely know which backups are valid and which must still be taken before overwriting remaining files.
- **Fix:** Add explicit manifest fields such as:
  - `phase: pending | backup_complete | copying | verifying | completed | failed`
  - per-operation `backup_completed: bool`
  - optional `backup_hash`
  Recovery can then deterministically complete remaining backups before any further overwrite.

### F6
- **Severity:** CRITICAL
- **Finding:** Backup path naming is unsafe for nested destinations and basename collisions.
- **Why:** Examples show `.rollback/vault-health-notes.md`. If two promoted files are `foo/spec.md` and `bar/spec.md`, both map to `.rollback/spec.md` and collide. Nested directory restoration is impossible without preserving relative path structure.
- **Fix:** Store rollback files using canonical-relative paths under `.rollback/`, e.g.:
  - `.rollback/Projects/foo/spec.md`
  - `.rollback/Projects/bar/spec.md`  
  Or use a stable escaped path encoding. Specify directory creation and path normalization.

### F7
- **Severity:** CRITICAL
- **Finding:** Ancestor/descendant conflict detection using SQL `LIKE` is path-prefix incorrect.
- **Why:** `target_path LIKE path || '%'` treats `Projects/foo2` as descendant of `Projects/foo`. It also depends on path normalization, case sensitivity, separator normalization, and trailing slash rules that are not specified.
- **Fix:** Define canonical path normalization rules and perform separator-aware checks. Best options:
  - Store normalized path components and compare semantically in application code
  - Or represent directories distinctly with trailing separator conventions and compare `path = target OR target GLOB path || '/*'`.  
  Avoid raw prefix matching.

### F8
- **Severity:** CRITICAL
- **Finding:** Recovery after external modification during crash window may dead-letter after some files have already been promoted, leaving a mixed vault state without explicit operator guidance.
- **Why:** §8.2 says if a previously promoted file no longer matches staging source, mark promotion failed, release locks, and dead-letter. But in a multi-file contract, some files may already have been promoted and remain in canonical state, while others were not. This is a partially applied contract with no rollback or quarantine guidance.
- **Fix:** Define explicit policy for this case:
  - Either preserve state and mark `DEAD_LETTER(partial_promotion_applied)`
  - Or require operator-mediated rollback using rollback data
  - Record exactly which operations were already applied in the ledger/dead-letter entry.

---

### F9
- **Severity:** SIGNIFICANT
- **Finding:** The distinction between write-locks and promotion lock is conceptually clear, but some wording blurs their guarantees.
- **Why:** §3.1 says write-locks “gate dispatch, not promotion,” while §4 and §5 rely on promotion-time verification and global promotion serialization for correctness. The document is mostly clear, but because hash checking currently happens before promotion lock, readers may infer write-locks provide stronger isolation than they do.
- **Fix:** Add a short invariants section:
  - Write-locks prevent overlapping Tess contracts from being active concurrently.
  - Promotion lock serializes promotion execution.
  - Hash verification under promotion lock prevents stale overwrite.
  - External writers are only detected, not prevented.

### F10
- **Severity:** SIGNIFICANT
- **Finding:** Potential deadlock is mostly avoided, but retry behavior under all-or-nothing multi-path acquisition needs deterministic ordering.
- **Why:** Once F2 is fixed to use one transaction, classic DB deadlock risk is low in SQLite because writes serialize. But application-level livelock is still possible if contracts repeatedly retry overlapping path sets in arbitrary order amid scheduler churn.
- **Fix:** Require deterministic sorted ordering of target paths before conflict checking and acquisition, and mention exponential/backoff or queue-based retry discipline.

### F11
- **Severity:** SIGNIFICANT
- **Finding:** The design assumes write-locks are per-file, but also claims ancestor/descendant overlap checks support directory-level targets without defining when a contract can target directories.
- **Why:** If services can target directories, hash recording and rollback semantics for directories are undefined. If services cannot target directories, ancestor/descendant logic adds confusion.
- **Fix:** State explicitly:
  - Either only file paths are legal target canonical paths
  - Or define directory-target semantics, including hashing, backup, and promotion behavior.

### F12
- **Severity:** SIGNIFICANT
- **Finding:** “Executor cannot discover other staging directories” is convention-only and not a real isolation boundary.
- **Why:** §2.4/§12 says access is enforced by convention and envelope contents. That is fine for a trusted local executor, but if the executor can access the filesystem, it can still enumerate `_staging/` unless sandboxed. This is more security/integrity than concurrency, but the document phrases it strongly.
- **Fix:** Reword to “not part of contract API; not relied upon for security.” If actual isolation matters, use process sandboxing or chroot/containerization.

### F13
- **Severity:** SIGNIFICANT
- **Finding:** Manual edits to canonical files are treated as detectable conflicts, but the document relies on AD-001 “sole writer” in some recovery paths while explicitly allowing direct edits in Scenario C.
- **Why:** The system design appears to permit human editing outside Tess in normal operation. Then §8.2 calls post-crash modification an AD-001 violation requiring dead-letter. The policy boundary is unclear.
- **Fix:** Clarify allowed external-write model:
  - Are direct human edits expected and supported at any time?
  - If yes, recovery should treat them as conflicts, not architectural violations.
  - If no, Scenario C should be framed as unsupported-but-detected behavior.

### F14
- **Severity:** SIGNIFICANT
- **Finding:** There is no defined source-of-truth for promotion attempt count consistency between manifest and ledger.
- **Why:** The manifest has `promotion_attempt`, and §4.5 increments attempt counter on conflict. If a crash occurs after one store is updated but not the other, retry limits can drift.
- **Fix:** Choose one authoritative location for attempt count, preferably the ledger or manifest, and define idempotent update semantics.

### F15
- **Severity:** SIGNIFICANT
- **Finding:** Cleanup timing text is contradictory.
- **Why:** §2.3 says COMPLETED staging directory is deleted after promotion verified. §6.2 says `.rollback/` remains and staging root is deleted after rollback retention expires. §7.3 says cleanup is periodic sweep, not inline. These cannot all be true simultaneously.
- **Fix:** Pick one model and state it consistently:
  - Recommended: after promotion, immediately delete non-rollback artifacts inline; retain staging root containing only manifest/rollback until sweep removes it after retention.  
  Update lifecycle tables accordingly.

### F16
- **Severity:** SIGNIFICANT
- **Finding:** Rollback does not verify that the current canonical files still match the promoted versions before restoring backups.
- **Why:** §6.4 acknowledges rollback may overwrite later changes, but the procedure offers no guardrail. For a high-risk system, operator-initiated rollback should at least present or require confirmation of drift.
- **Fix:** Before rollback, compute current hash of each destination and compare to recorded post-promotion hash. If drift exists:
  - warn loudly
  - require `--force`
  - log per-file drift in ledger.

### F17
- **Severity:** SIGNIFICANT
- **Finding:** Rollback relies on manifest `promoted == true`, but manifest durability and cleanup policy may remove the manifest before rollback window expires.
- **Why:** If cleanup deletes the main artifacts or manifest too aggressively, operator rollback becomes impossible even if `.rollback/` exists.
- **Fix:** Explicitly retain the manifest alongside `.rollback/` for the full rollback retention window.

### F18
- **Severity:** SIGNIFICANT
- **Finding:** The copy operation itself is underspecified; without temp-file + rename, readers can observe torn writes for individual files.
- **Why:** §5.1 honestly says readers may observe intermediate state across files, but individual file writes should still ideally be atomic. Plain copy to destination can expose partially written file contents if a reader opens during write or if crash occurs mid-file.
- **Fix:** Specify per-file promotion as:
  - write source bytes to temp file in destination directory
  - fsync temp file
  - atomic rename temp file to destination
  - fsync destination directory  
  This preserves file-level atomic replacement on POSIX filesystems.

### F19
- **Severity:** SIGNIFICANT
- **Finding:** The design does not specify path normalization or symlink handling for canonical destinations.
- **Why:** Without normalization, locks can be bypassed using semantically equivalent paths (`a/../b`, duplicate slashes, case variants on case-insensitive filesystems, symlinked directories). That can break both lock conflict detection and promotion safety.
- **Fix:** Require canonical destination paths to be normalized, vault-relative, symlink-resolved/forbidden, and validated to remain within vault root before lock acquisition and promotion.

### F20
- **Severity:** SIGNIFICANT
- **Finding:** SQLite is appropriate, but its operational mode is underspecified for multi-process concurrency.
- **Why:** In multi-process use, SQLite behavior depends on journal mode, busy timeout, transaction mode, and error handling (`database is locked`). Absent these, lock acquisition may fail spuriously under scheduler/promoter contention.
- **Fix:** Specify:
  - WAL mode or explicit rationale if not
  - busy timeout
  - `BEGIN IMMEDIATE` for lock acquisition transaction
  - retry/error semantics on transient SQLite lock contention.

### F21
- **Severity:** SIGNIFICANT
- **Finding:** Startup zombie-lock cleanup rule “if contract does not exist in ledger, release locks” may be unsafe.
- **Why:** A process could acquire write-locks and crash before persisting ledger state, but another subsystem may still be reconstructing or recovering the contract. Blindly releasing locks can permit duplicate work or loss of diagnostic context.
- **Fix:** Require stronger evidence before releasing:
  - no ledger entry
  - no active worker process / no dispatch record
  - no staging dir or manifest in progress
  - age threshold or startup-only quarantine period.

### F22
- **Severity:** SIGNIFICANT
- **Finding:** Recovery of `completed` manifests says “release write-locks, release promotion lock, clean staging,” but promotion lock is `flock` and should already be gone after crash.
- **Why:** This is harmless but semantically sloppy and can mislead implementation. More importantly, if no process currently holds the lock, “release” means nothing.
- **Fix:** Reword recovery steps to “acquire promotion lock if needed for cleanup/rollback-sensitive actions” or simply omit release language for startup recovery of a stale completed manifest.

### F23
- **Severity:** SIGNIFICANT
- **Finding:** Partial promotion semantics from `QUALITY_FAILED` are not fully integrated with write-lock scope and rollback bookkeeping.
- **Why:** If only a subset of artifacts promote, are write-locks held for failed artifacts? Are target paths for failed artifacts still blocked until dead-letter? How are retries handled? The document says dead-letter entry is created, but contract convergence/terminal handling is underspecified.
- **Fix:** Define partial-promotion contract terminal semantics:
  - which locks are released when
  - whether non-promoted artifacts spawn child dead-letter records
  - rollback manifest contains only promoted subset.

### F24
- **Severity:** SIGNIFICANT
- **Finding:** The cleanup sweep’s age basis is ambiguous.
- **Why:** §7.3 uses “age > rollback_retention_hours”, “age > dead_letter_staging_retention”, etc., but does not define age as directory mtime, contract terminal timestamp, manifest completion timestamp, or ledger transition timestamp. Filesystem mtime is unreliable under partial cleanup/recovery.
- **Fix:** Define age source as ledger terminal-state timestamp or manifest completion timestamp, not directory metadata.

### F25
- **Severity:** SIGNIFICANT
- **Finding:** The document does not specify how target canonical paths are validated against actual staged outputs before promotion manifest construction.
- **Why:** If a contract is expected to produce N artifacts and only N-1 exist in staging, manifest construction may silently omit one or fail late. For a critical promotion path, completeness checks should be explicit.
- **Fix:** Add pre-promotion validation:
  - all expected staged artifacts exist
  - no unexpected promotable artifacts unless service definition allows them
  - destinations are unique and valid.

---

### F26
- **Severity:** MINOR
- **Finding:** Scenario C says the contract transitions `PROMOTING → QUALITY_EVAL` on hash conflict, but earlier text says conflict is detected before any file copy begins and before promotion lock may even be acquired.
- **Why:** State naming is slightly inconsistent and could confuse implementation around whether conflict occurs in `PROMOTION_PENDING` or `PROMOTING`.
- **Fix:** Decide one state boundary and use it consistently. Prefer: conflict detected in `PROMOTION_PENDING` before entering `PROMOTING`.

### F27
- **Severity:** MINOR
- **Finding:** `canonical_hash` column is declared `TEXT NOT NULL` but examples use sentinel `"NEW_FILE"`.
- **Why:** Functional, but semantically mixing a hash with a sentinel string is awkward.
- **Fix:** Prefer nullable hash plus `file_exists` boolean, or an enum/status field.

### F28
- **Severity:** MINOR
- **Finding:** The promotion manifest stores both `hash_at_lock_time` and `hash_at_promotion`, but the latter is redundant if recomputable and may drift in crash scenarios.
- **Why:** More fields means more recovery states to reason about.
- **Fix:** Either define a strict purpose for `hash_at_promotion` or remove it.

### F29
- **Severity:** MINOR
- **Finding:** The phrase “promotions are fast (milliseconds to low seconds)” is assumption-heavy.
- **Why:** Large artifacts, slow disks, or fsync-heavy durability may exceed that.
- **Fix:** Reword as an expectation, not a guarantee, and rely on measured observability.

### F30
- **Severity:** MINOR
- **Finding:** The timeout behavior for promotion lock contention sends the contract back to `QUALITY_EVAL`, which may be unnecessarily expensive.
- **Why:** If another promotion simply takes >60s, there may be no content change and no need to re-run quality checks immediately.
- **Fix:** Consider returning to `PROMOTION_PENDING` with backoff, and only re-run QUALITY_EVAL if hash verification later detects drift.

---

### F31
- **Severity:** STRENGTH
- **Finding:** The document explicitly distinguishes “crash-safe resumable” from “strictly atomic,” which is the correct design framing.
- **Why:** This avoids a common architectural mistake where docs overclaim filesystem atomicity that does not exist.
- **Fix:** None.

### F32
- **Severity:** STRENGTH
- **Finding:** Staging-first writes with per-contract directories and retained rollback data is a sound backbone for safe promotion.
- **Why:** It isolates executor output from canonical state and gives recovery a concrete artifact base.
- **Fix:** None.

### F33
- **Severity:** STRENGTH
- **Finding:** The use of a manifest to drive idempotent recovery is the right general pattern.
- **Why:** Without a durable per-operation record, mid-promotion crash recovery is guesswork.
- **Fix:** Keep this approach; just strengthen manifest state granularity and durability rules.

### F34
- **Severity:** STRENGTH
- **Finding:** SQLite is a strong choice over YAML for multi-process lock bookkeeping.
- **Why:** ACID transactions and queryability fit the problem well.
- **Fix:** None beyond operational tuning.

### F35
- **Severity:** STRENGTH
- **Finding:** Scenario walkthroughs are useful and reveal the intended invariants clearly.
- **Why:** For high-risk lifecycle designs, concrete traces are valuable for implementers and reviewers.
- **Fix:** Add more edge-case scenarios.

---

## Missing Scenario Coverage

### F36
- **Severity:** SIGNIFICANT
- **Finding:** Important edge cases are missing from the scenario walkthroughs.
- **Why:** The existing three scenarios are good, but they do not cover several failure-prone situations:
  - multi-file contract with one overwrite and one new file plus crash during backup
  - partial lock acquisition failure across multiple target files
  - path overlap false-positive/false-negative cases (`foo` vs `foo2`)
  - rollback after post-promotion drift
  - startup recovery where ledger says non-terminal but manifest says completed
  - external edit between hash check and copy
  - partial promotion from QUALITY_FAILED
  - duplicate basenames in rollback
- **Fix:** Add at least 5 more scenario walkthroughs for the above.

---

## Question-by-Question Evaluation

### 1. Crash recovery completeness
**Assessment:** Not yet complete enough for “high risk” sign-off.

Strong direction, but there are gaps:
- no durable per-operation manifest/fsync spec
- no explicit phase markers for backup completion
- inconsistent ordering of state update vs lock release
- no TOCTOU closure around pre-lock hash verification

If those are fixed, the recovery model becomes much more credible.

### 2. Write-lock vs promotion-lock distinction
**Assessment:** Conceptually clear, operationally needs tightening.

The distinction itself is good:
- write-locks prevent overlapping contracts from being active together
- promotion lock serializes actual promotion

Deadlock risk is low if write-lock acquisition is one SQLite transaction and promotions only ever take the single global lock. As written, partial-acquisition behavior is the bigger issue than deadlock.

### 3. Hash-based conflict detection
**Assessment:** Good idea, insufficiently protected against TOCTOU as written.

SHA-256 itself is fine. The issue is timing:
- dispatch-time hash capture is useful
- promotion-time compare is useful
- but compare must happen **under the same lock regime that protects copy start**

Without that, stale overwrite is still possible.

### 4. Atomic promotion
**Assessment:** The document’s honesty is good; implementation details need stronger guarantees.

Manifest-driven resumability is the right strategy. To be sound, define:
- per-file temp-write + rename
- manifest fsync behavior
- recovery rules when destination already matches source but manifest is stale
- explicit promotion phases

### 5. Rollback mechanism
**Assessment:** Manual-only rollback is the right default.

Automatic rollback is generally too risky because it can destroy later valid changes. However, the current manual rollback needs better safeguards:
- detect and warn on post-promotion drift
- retain manifest with rollback data
- clearly record promoted subset for partial promotion cases

### 6. Scenario walkthroughs
**Assessment:** Helpful but incomplete.

They cover:
- same-file contention
- interrupted promotion
- canonical drift since dispatch

Missing:
- multi-target locking failure
- backup-phase crash
- path normalization/symlink edge cases
- rollback after drift
- partial promotion
- post-completion/pre-ledger crash

### 7. SQLite for write-locks
**Assessment:** Yes, appropriate.

For this use case, SQLite is preferable to flat files. Concurrency concerns are manageable if the design specifies:
- transaction mode
- busy timeout
- journaling mode
- retry semantics

### 8. Retention and cleanup
**Assessment:** Reasonable intent, but policy wording is inconsistent.

Need to unify:
- what is cleaned inline vs by sweep
- whether manifest survives for rollback window
- what timestamp determines retention age
- safe orphan/zombie determination

---

## Unverifiable Claims

### F37
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** “Promotions are fast (copy a handful of files). The total promotion duration is measured in milliseconds to low seconds.”
- **Why:** This depends on workload, file sizes, storage medium, fsync policy, and future usage patterns. It cannot be independently validated from the document.
- **Fix:** Rephrase as an assumption to be validated by observability metrics, not as an asserted fact.

### F38
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** “No performance concern — files being promoted are vault artifacts, not large binaries.”
- **Why:** Future contracts may produce large artifacts; the document does not establish enforceable artifact size limits.
- **Fix:** Either define artifact size constraints or frame this as a current expectation.

### F39
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** “No filesystem-level ACLs needed for single-user Mac environment.”
- **Why:** Whether ACLs are unnecessary depends on threat model and trust assumptions not fully defined here.
- **Fix:** State this as a threat-model assumption, not a factual guarantee.

---

## Recommended Priority Fix List

If you only address a few things before implementation, make them these:

1. **Move hash verification under promotion lock**.  
2. **Make write-lock acquisition truly all-or-nothing in one SQLite transaction**.  
3. **Define a single consistent ordering for ledger completion, lock release, manifest completion, and cleanup**.  
4. **Expand manifest state to include promotion phase and backup completion; require fsync durability**.  
5. **Specify per-file temp-write + atomic rename and path normalization/symlink rules**.  
6. **Fix rollback path naming to preserve full canonical-relative paths**.  
7. **Retain manifest for the rollback window and add drift warning on rollback**.

---

## Bottom Line

This is a strong draft with the right architecture, but **not yet safe enough as written for a vault-integrity-critical implementation**. The main issues are precise state-machine/transaction boundaries, not the overall approach. Once the TOCTOU, lock acquisition, manifest durability, and ordering inconsistencies are resolved, the design will be much more robust.

---

## Google (gemini-3.1-pro-preview)

Here is a structured review of the Tess v2 Staging/Promotion Lifecycle Design, evaluating the specified architectural dimensions and classifying findings by severity.

- [F1]
- [Severity]: CRITICAL
- [Finding]: Time-of-Check to Time-of-Use (TOCTOU) race condition in the promotion sequence (Section 5.2).
- [Why]: Step 1 performs hash verification, and Step 2 acquires the global promotion lock. If the promotion lock is currently held by another contract, the current contract might wait up to 60 seconds to acquire it. During this wait, an external user could modify the canonical file. Because the hash check already passed in Step 1, the promotion will blindly overwrite the user's changes once the lock is acquired, violating the hash-based conflict detection guarantee.
- [Fix]: Swap the order of Steps 1 and 2. The promotion engine must acquire the global promotion lock *first*, and only then perform the hash verification. This ensures the canonical file cannot be modified by other Tess processes during the check, and minimizes the race window for external non-Tess edits.

- [F2]
- [Severity]: CRITICAL
- [Finding]: Direct contradiction in crash recovery logic for interrupted backups (Section 5.2 vs 8.1).
- [Why]: Section 5.2 explicitly states that during Step 4 (Back up canonical files), the manifest status is still `pending`, and only becomes `in_progress` at Step 5. However, Section 8.1 dictates that a crash during backup is recovered via the "`in_progress` (with backup incomplete)" state. If a crash happens at Step 4, the engine will see a `pending` state and, according to 8.1's rule for `pending`, will "Delete manifest... Re-verify hashes" rather than resume the backup. This contradiction will lead to undefined or faulty recovery behavior.
- [Fix]: Update the manifest schema and sequence to include a `backing_up` status, OR update Section 8.1 to define how a `pending` manifest with partially created `.rollback/` files is handled (e.g., "If `pending` and `.rollback/` exists, clear `.rollback/` and restart"). 

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: SQL wildcard vulnerability in ancestor/descendant write-lock check (Section 3.4).
- [Why]: The SQLite query uses `LIKE path || '%'` and `LIKE target_path || '%'`. The `%` and `_` characters are SQL wildcards. If a vault directory or file naturally contains these characters (e.g., `Projects/20%_growth/report.md`), the `LIKE` clause will treat them as wildcards, resulting in false-positive lock overlap detections and preventing valid contracts from dispatching.
- [Fix]: Explicitly escape SQL wildcards in the `target_path` variable before executing the `LIKE` query, using SQLite's `ESCAPE` syntax.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Unhandled file deletion in hash conflict detection (Section 4.4).
- [Why]: The pseudo-code reads: `current_hash = SHA256(read_file(operation.destination))`. If a file existed at lock time (`file_exists_at_lock_time: true`) but was deleted by a user before promotion, `read_file` will throw an unhandled `FileNotFoundError` (or equivalent system exception). This will crash the promotion engine rather than gracefully failing the quality evaluation via the conflict detection flow.
- [Fix]: Add an explicit check in 4.4: `IF NOT file_exists(operation.destination): CONFLICT DETECTED (File Deleted)`.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "The total promotion duration is measured in milliseconds to low seconds." (Section 5.4)
- [Why]: Without hard limits on the size or number of executor-produced artifacts allowed in a contract, the system cannot guarantee promotion times. A contract producing large datasets, ML models, or thousands of small generated files could hold the global promotion lock for significantly longer than "low seconds," potentially causing lock timeouts (60s) for other queued contracts.
- [Fix]: Acknowledge that promotion time scales with payload size, and consider defining maximum artifact payload sizes in the contract schema (TV2-019) to enforce this performance claim.

- [F6]
- [Severity]: MINOR
- [Finding]: Misaligned cleanup logic for interrupted promotions on COMPLETED contracts (Section 7.3).
- [Why]: Step 2 of the sweep procedure says: "IF contract is COMPLETED... IF no .rollback/ AND main artifacts still present: Delete entire staging directory (cleanup after promotion was interrupted)". If a promotion was interrupted mid-way, the contract state in the ledger would be `PROMOTING`, not `COMPLETED`. If it is `COMPLETED`, the promotion finished successfully, and the artifacts should have been cleaned synchronously in Step 11 of the promotion sequence.
- [Fix]: Move the logic for interrupted promotion cleanup to a check against the `PROMOTING` state (or rely on the startup sweep for this), and simply enforce that `COMPLETED` contracts eventually have their `_staging` directory removed entirely once `.rollback/` expires.

- [F7]
- [Severity]: MINOR
- [Finding]: Missing Scenario Walkthrough for Zombie Lock Recovery.
- [Why]: The scenarios comprehensively cover concurrent locking (A), mid-write crashes (B), and external edits (C). However, they omit a walkthrough of a process crashing *before* a terminal ledger write (e.g., crashing in `EXECUTING`), leaving a Zombie Lock. Given Phase 3's reliance on the SQLite/Ledger interplay, illustrating how the periodic sweep resolves this is highly valuable.
- [Fix]: Add "Scenario D: Unclean Executor Termination" detailing a crash during `EXECUTING`, the resulting orphaned SQLite locks, and how the subsequent sweep cross-references the ledger to release them.

- [F8]
- [Severity]: STRENGTH
- [Finding]: Strict separation of Write-Locks (dispatch phase) and Promotion-Locks (copy phase).
- [Why]: Using granular, long-held SQLite locks for dispatch prevents wasted compute and logical conflicts, while using a brief, global mutex for the actual filesystem promotion eliminates the risk of classic dining-philosophers deadlocks during the file copy phase. This is an excellent, pragmatic architectural choice.

- [F9]
- [Severity]: STRENGTH
- [Finding]: Destination verification during crash recovery (Section 8.2).
- [Why]: Checking the SHA-256 of previously promoted files against the staging source during recovery effectively detects external modifications that occurred precisely during the crash window. Booting these to `DEAD_LETTER` rather than blindly resuming the copy strictly enforces the AD-001 vault authority mandate.

- [F10]
- [Severity]: STRENGTH
- [Finding]: Manual-only rollback philosophy (Section 6.3).
- [Why]: Acknowledging that the system lacks the context to automatically reverse side-effects (like sent emails or API calls triggered during execution) is a mature design decision. Forcing operator intervention for rollbacks prevents compounded errors that often arise from automated "undo" logic in complex environments.

---

## DeepSeek (deepseek-reasoner)

**Structured Review of Tess v2 Staging/Promotion Lifecycle Design**

---

**F1**
- **Severity**: CRITICAL
- **Finding**: The hash verification for conflict detection occurs in PROMOTION_PENDING (Step 1 of §5.2), *before* acquiring the global promotion lock. This creates a TOCTOU (time-of-check-time-of-use) race window where the canonical file could be altered after the hash check but before the copy, leading to silent overwrites.
- **Why**: The promotion lock is intended to serialize promotions, but the hash check is performed outside its protection. An external edit or concurrent promotion from another process could change the file after the check, violating the hash-based conflict-detection guarantee.
- **Fix**: Move the hash verification step *inside* the promotion lock. The sequence should be: acquire promotion lock (PROMOTION_PENDING → PROMOTING), then verify all hashes, then proceed with backup and copy. Update §5.2 and §4.4 accordingly.

**F2**
- **Severity**: SIGNIFICANT
- **Finding**: The design assumes a service-interface mapping from staging artifacts to canonical paths (noted in §3.4 and §13 Open Question 1), but does not define this mapping. The promotion engine cannot function without a deterministic way to derive target paths.
- **Why**: Without a defined mapping, the promotion engine cannot know which staging files correspond to which canonical destinations, making promotion impossible.
- **Fix**: Define the mapping format as part of TV2-021b (service interfaces). The design should at least specify a placeholder (e.g., a `target_mapping` field in the contract envelope) and note it as a prerequisite.

**F3**
- **Severity**: SIGNIFICANT
- **Finding**: The global promotion lock (§5.4) serializes *all* promotions. While promotions are expected to be fast, a single slow or stuck promotion (e.g., copying large files) could block the entire promotion queue, creating a bottleneck and potential denial of service.
- **Why**: Contracts in PROMOTION_PENDING from different priority classes could be unfairly delayed by a long-running promotion. The design acknowledges this in §13 Open Question 2 but defers it.
- **Fix**: Consider a per-path promotion lock or a lock with a fairness mechanism (e.g., a queue). Alternatively, document that promotions must be fast (size/performance limits) and add monitoring to alert on long-held locks.

**F4**
- **Severity**: SIGNIFICANT
- **Finding**: UNVERIFIABLE CLAIM: The design states that the write-lock table uses SQLite for ACID transactions and is concurrency-safe under multi-process updates. However, SQLite's concurrency model (multiple readers, single writer) may not suffice if multiple processes (orchestrator, promotion engine, scheduler) frequently contend for write locks simultaneously.
- **Why**: High lock-acquisition traffic (many contracts routing concurrently) could lead to serialization bottlenecks or SQLITE_BUSY errors, potentially stalling dispatch.
- **Fix**: Either (a) add a retry-with-backoff mechanism for lock acquisition transactions, (b) use a more robust concurrency model (e.g., a dedicated lock server), or (c) document that contract dispatch rate must be limited to avoid lock contention.

**F5**
- **Severity**: SIGNIFICANT
- **Finding**: Crash recovery for the "in_progress" promotion manifest (§8.1) assumes that partially copied files can be verified by comparing destination hashes with staging source hashes. If the process crashes *during* a copy operation, the destination file may be partially written/corrupted, causing a hash mismatch and triggering an "external modification" error incorrectly.
- **Why**: A crash mid-copy leaves the destination file in an indeterminate state; the recovery procedure may misattribute the corruption to an external modification, sending the contract to DEAD_LETTER unnecessarily.
- **Fix**: During recovery, if a promoted file's hash does not match, first check if the file size matches the staging source. If not, treat it as an interrupted copy and re-copy from staging (overwriting the partial). Only if the size matches but hash differs should external modification be assumed.

**F6**
- **Severity**: SIGNIFICANT
- **Finding**: The rollback mechanism (§6.3) restores files from `.rollback/` but does not verify that the rollback copy is intact (e.g., via hash). If the rollback file was corrupted or altered, the restoration could corrupt the vault.
- **Why**: Rollback is a critical repair operation; silent corruption during rollback could compound data loss.
- **Fix**: Before copying a rollback file, compute its SHA-256 and compare it to a hash stored in the promotion manifest (add a `backup_hash` field). If mismatch, abort rollback and alert operator.

**F7**
- **Severity**: MINOR
- **Finding**: The cleanup sweep (§7.3) deletes orphaned staging directories after 7 days. However, a contract could be in a long-running state (e.g., EXECUTING for days) and have a valid staging directory that the sweep might mistakenly classify as orphaned if the ledger lookup fails transiently.
- **Why**: A false positive could delete a staging directory while a contract is still executing, causing data loss and contract failure.
- **Fix**: In the sweep, for directories where the contract is not found in the ledger, check if the directory is very recent (e.g., < 1 hour) and log a warning instead of deleting. Only delete if the directory is older than a safe threshold (e.g., 24 hours) and no corresponding process exists.

**F8**
- **Severity**: MINOR
- **Finding**: The write-lock acquisition algorithm (§3.4) checks for ancestor/descendant path overlaps (e.g., `foo/` and `foo/bar.md`). This prevents directory-level conflicts but may be overly restrictive for unrelated files in a broad directory tree.
- **Why**: Two contracts targeting different files in the same directory (e.g., `docs/a.md` and `docs/b.md`) would be allowed, but if one targets `docs/` and another targets `docs/a.md`, they conflict. This is a design choice that should be explicitly justified.
- **Fix**: Document the rationale (preventing partial directory promotions) and consider whether this is necessary for all services. If needed, keep as is; otherwise, refine overlap detection to allow sibling files.

**F9**
- **Severity**: STRENGTH
- **Finding**: The manifest-driven crash recovery (§5.2, §8.1) is well-designed, using explicit status flags and operation-level tracking to make promotion idempotent and resumable at any point.
- **Why**: This provides robust fault tolerance without requiring transactional filesystems, a pragmatic solution for a single-user system.

**F10**
- **Severity**: STRENGTH
- **Finding**: The separation of write-locks (dispatch-time) and promotion locks (copy-time) is clear and prevents both planning conflicts and runtime collisions. The use of hash-based conflict detection directly addresses the "stale reads" failure mode.
- **Why**: This two-phase locking ensures that contracts never execute on stale data and that promotions are serialized safely, fulfilling spec requirements C9 and AD-008.

**F11**
- **Severity**: STRENGTH
- **Finding**: The retention and cleanup policy (§7) is comprehensive and decouples cleanup from the hot path, using periodic sweeps to avoid performance impact. Retention periods are configurable and aligned with other policies (dead-letter queue).
- **Why**: This balances disk usage with debuggability and operator recovery needs.

**F12**
- **Severity**: MINOR
- **Finding**: The scenario walkthroughs (§10) cover key cases but omit a scenario where a contract in PROMOTION_PENDING is blocked by an escalation storm freeze (TV2-026). It's unclear how the promotion queue interacts with storm freezing.
- **Why**: Operators need to understand whether promotions proceed during storms.
- **Fix**: Add a brief scenario or note in §10 explaining that L3 storms freeze new PROMOTION_PENDING transitions but allow already-promoting contracts to complete.

---

**Summary of Critical Issues**:
1. **TOCTOU in hash check (F1)** – Must be fixed to ensure conflict detection works.
2. **Missing target path mapping definition (F2)** – Blocks implementation.
3. **SQLite concurrency concerns (F4)** – Requires mitigation for production use.
4. **Crash recovery hash mismatch false positive (F5)** – Could incorrectly dead-letter contracts.

The design is generally strong in its recovery and locking strategy, but these issues must be addressed before implementation.

---

## Grok (grok-4-1-fast-reasoning)

### Structured Review of Tess v2 Staging/Promotion Lifecycle Design

#### 1. Crash Recovery Completeness
- **F1**  
  **[Severity]: CRITICAL**  
  **[Finding]:** Recovery for partial backups during "in_progress" promotions is underspecified. The design states "recovery sees 'in_progress' with partial backups → complete backup, then restart from step 5," but the manifest schema lacks per-operation backup status flags (e.g., no "backed_up: true"). Recovery cannot reliably detect which canonical files have incomplete backups without scanning .rollback/ against operations list.  
  **[Why]:** Without precise tracking, recovery might overwrite already-backed-up files (duplicating data) or skip needed backups, leading to vault corruption during manual rollback or external modification detection. Vault integrity (Phase 3 high-risk) depends on perfect crash safety.  
  **[Fix]:** Add per-operation "backed_up: boolean" to manifest schema. In recovery, for "in_progress": FOR EACH op WHERE NOT backed_up: copy canonical → .rollback/, set backed_up=true; THEN resume copies.

- **F2**  
  **[Severity]: SIGNIFICANT**  
  **[Finding]:** No recovery specified for crash between promotion lock acquisition (step 2) and manifest write (step 3). Lock auto-releases on crash (flock), but contract state remains PROMOTION_PENDING or partially transitioned, with no manifest to guide resumption. Next attempt restarts hash verify, but repeated lock contention could loop indefinitely.  
  **[Why]:** Creates retry storms under high load; violates "crash-safe resumable promotion" from TV2-017 inputs.  
  **[Fix]:** Write manifest *before* acquiring lock, but use a staging temp file renamed atomically after lock acquire. Recovery scans for lockfile + no manifest as "lock-only crash" → delete lockfile if stale, retry.

- **F3**  
  **[Severity]: SIGNIFICANT**  
  **[Finding]:** Verification in step 7 (post-all-copies) lacks per-operation tracking in manifest. On "in_progress" recovery, it verifies only already-promoted ops but assumes unpromoted can resume without re-verifying prior ones if crash during verify.  
  **[Why]:** If external mod during crash window corrupts a promoted file, batch re-verify might miss it if not all re-hashed.  
  **[Fix]:** After all copies/verifies, update manifest with per-op "verified_hash: sha256". Recovery computes destination hash vs verified_hash.

- **F4**  
  **[Severity]: MINOR**  
  **[Finding]:** Startup sweep (§8.1) scans all manifests but no bounded time guarantee; large _staging/ could delay orchestrator startup.  
  **[Why]:** Impacts availability post-crash/restart.  
  **[Fix]:** Parallelize scan with timeout; config for max_scan_dirs.

#### 2. Write-Lock vs Promotion-Lock Distinction
- **F5**  
  **[Severity]: STRENGTH**  
  **[Finding]:** Clear separation: write-locks gate dispatch (preventing wasted execution on contended paths), promotion-lock gates copies (serializing filesystem ops). No deadlock risk due to global scope and no nested acquires.  
  **[Why]:** Matches design goals (C9: no promotion collisions); ancestor/descendant check prevents subtle overlaps. Verified against §3.1, §5.4, scenarios A/B.

- **F6**  
  **[Severity]: SIGNIFICANT**  
  **[Finding]:** No handling for promotion-lock timeout during high contention: after 60s wait, contract → QUALITY_EVAL, but write-locks remain held, blocking other contracts indefinitely if re-eval loops.  
  **[Why]:** Could starve queue (violates TV2-027 fairness); lock holder not timed out.  
  **[Fix]:** On timeout, release *write-locks* temporarily (mark as "contended_timeout" in DB), re-acquire on next attempt.

#### 3. Hash-Based Conflict Detection
- **F7**  
  **[Severity]: CRITICAL**  
  **[Finding]:** TOCTOU race in promotion sequence: hash verify in PROMOTION_PENDING, *then* acquire promotion lock. If blocked on global lock (another promotion changes file), no re-verify on lock acquire—stale hash check passes, overwriting unintended changes.  
  **[Why]:** Core failure mode (§2.4 "promotion race via stale reads") unmitigated; two pending contracts both pass hash vs their lock-time, first promotes, second overwrites without detection. Breaks vault integrity.  
  **[Fix]:** Re-verify hashes *immediately after* lock acquire, before manifest write. Update manifest.hash_at_promotion and fail if mismatch.

- **F8**  
  **[Severity]: SIGNIFICANT**  
  **[Finding]:** New-file check (file_exists_at_lock=false) only detects if file now exists at promotion, but doesn't hash it—assumes any creation is conflict. Misses if another contract created identical content.  
  **[Why]:** False conflict on convergent work; wastes re-eval cycles.  
  **[Fix]:** For new files, if exists: hash staging source vs new canonical; conflict only on mismatch.

- **F9**  
  **[Severity]: MINOR**  
  **[Finding]:** "NEW_FILE" string as hash for new files—risky if actual file hashes to that string (unlikely but possible).  
  **[Why]:** Theoretical collision.  
  **[Fix]:** Use null or special sentinel like "000000...NEW".

#### 4. Atomic Promotion
- **F10**  
  **[Severity]: SIGNIFICANT**  
  **[Finding]:** Partial promotion (§5.5) claims "atomic within passing subset," but crash recovery (§8.1) treats filtered manifest identically—no special handling for mixed passing/failing artifacts remaining in staging.  
  **[Why]:** Failing artifacts could be cleaned prematurely, losing debug data; violates retention (§7.1).  
  **[Fix]:** Add manifest.partial: true flag; recovery skips cleaning non-promoted ops in partial mode.

- **F11**  
  **[Severity]: STRENGTH**  
  **[Finding]:** Manifest-driven idempotence sound: per-op promoted flags enable resume without re-copy, verification catches external mods.  
  **[Why]:** Aligns with "honest about partial reader states" (§5.1); scenarios B/C validate.

#### 5. Rollback Mechanism
- **F12**  
  **[Severity]: SIGNIFICANT**  
  **[Finding]:** Rollback doesn't re-verify .rollback/ integrity (e.g., hash against original canonical_hash)—if .rollback/ corrupted during retention, restores wrong data.  
  **[Why]:** Defeats purpose; vault corruption possible.  
  **[Fix]:** Store per-rollback hash in manifest; verify before restore.

- **F13**  
  **[Severity]: MINOR**  
  **[Finding]:** No operator confirmation prompt in `tess rollback` command.  
  **[Why]:** Accidental invocations overwrite post-changes (§6.4).  
  **[Fix]:** Interactive: "Confirm? y/N" + reason required.

- **F14**  
  **[Severity]: STRENGTH**  
  **[Finding]:** Manual-only avoids unsafe auto-reverts; windowed retention balances safety/disk.  
  **[Why]:** Matches "operator understanding required" (§6.3).

#### 6. Scenario Walkthroughs
- **F15**  
  **[Severity]: SIGNIFICANT**  
  **[Finding]:** Missing scenario: concurrent promotions (multiple PROMOTION_PENDING racing for global lock + hash TOCTOU from F7). Also missing: partial promotion crash; zombie lock during long QUALITY_EVAL.  
  **[Why]:** High-risk edges unvalidated; TV2-017 requires "scenario walkthroughs B/C" but doc claims more coverage.  
  **[Fix]:** Add Scenario D: concurrent pending + lock wait with intervening promotion; E: partial crash.

#### 7. SQLite for Write-Locks
- **F16**  
  **[Severity]: SIGNIFICANT**  
  **[Finding]:** No WAL mode specified for write-locks.db; default rollback journal risks blocking writers during concurrent acquires (multiple contracts in ROUTING).  
  **[Why]:** Serialization under load delays dispatch queue (TV2-027). Mac single-user mitigates but not guaranteed.  
  **[Fix]:** Config: PRAGMA journal_mode=WAL; document in §3.2.

- **F17**  
  **[Severity]: MINOR**  
  **[Finding]:** No backup/vacuum schedule for write-locks.db growth (holds until terminal).  
  **[Why]:** Disk bloat over time.  
  **[Fix]:** Add to daily sweep: VACUUM if >10MB.

#### 8. Retention and Cleanup
- **F18**  
  **[Severity]: SIGNIFICANT**  
  **[Finding]:** Orphaned staging dirs cleaned only after 7 days (§7.3), but no disk quota/alerts—crash floods could fill disk before sweep.  
  **[Why]:** DoS on vault; daily sweep too infrequent for hot path.  
  **[Fix]:** Inline cleanup on promotion success/abandon; quota check in sweep.

- **F19**  
  **[Severity]: MINOR**  
  **[Finding]:** Sweep skips escalation storm (§11); L3 freeze could backlog cleanup.  
  **[Why]:** Minor availability hit.  
  **[Fix]:** Run sweep even in L3.

#### Additional Cross-Cutting Findings
- **F20**  
  **[Severity]: SIGNIFICANT**  
  **[Finding]:** UNVERIFIABLE CLAIM: Target path derivation from "service interface definition (TV2-021a/021b)"—open question (§13.1) leaves core lock acquisition ambiguous (how exactly derived from staging artifacts?).  
  **[Why]:** Blocks implementation; locks might miss paths.  
  **[Fix]:** Resolve in TV2-021b or add fallback (manifest declares targets).

**Summary:** 20 findings (17 issues: 2 CRITICAL, 9 SIGNIFICANT, 4 MINOR; 3 STRENGTH). Critical gaps in TOCTOU/race and partial backup recovery threaten vault integrity. Design strong on intent but implementation-spec incomplete. Prioritize F1/F7 fixes.

---

## Synthesis

### Consensus Findings

**1. TOCTOU race in promotion sequence** (ALL 4 — OAI-F1, GEM-F1, DS-F1, GRK-F7)
Hash verification occurs before promotion lock acquisition, leaving a window where canonical files can change. Every reviewer independently identified this as the highest-priority fix. Fix: move hash verification inside the promotion lock critical section.

**2. Manifest lacks per-operation backup tracking** (OAI-F5, GEM-F2, GRK-F1)
No `backed_up` flag per operation in the manifest. Recovery cannot distinguish which backups completed before a crash. GEM also identified a status contradiction (crash during backup sees `pending` status but recovery expects `in_progress`). Fix: add per-operation `backed_up: boolean` and explicit promotion phase markers.

**3. SQLite operational mode unspecified** (OAI-F20, GRK-F16)
No WAL mode, busy timeout, or transaction mode specified. Under multi-process access, default rollback journal mode risks blocking. Fix: specify WAL mode, busy timeout, `BEGIN IMMEDIATE` for acquisitions.

**4. Rollback integrity unverified** (DS-F6, GRK-F12)
Rollback files aren't hash-verified before restoration. Corrupted `.rollback/` would silently corrupt the vault during operator-initiated recovery. Fix: store per-rollback hash in manifest, verify before restore.

**5. Path overlap detection via SQL LIKE is unsafe** (OAI-F7, GEM-F3)
`LIKE path || '%'` has false positives (`foo` matches `foo2`) and SQL wildcard characters (`%`, `_`) in paths cause incorrect matching. Fix: use separator-aware matching (`GLOB path || '/*'`) and escape wildcards.

**6. Missing scenario coverage** (OAI-F36, GEM-F7, GRK-F15)
All reviewers noted gaps: concurrent promotions racing for lock, partial promotion crash, zombie locks, path overlap edge cases.

### Unique Findings

**OAI-F2 (CRITICAL): Write-lock acquisition not all-or-nothing.** Per-path transactions can leave partial locks on failure. Genuine issue — the fix (single SQLite transaction for all paths) is straightforward and correct.

**OAI-F6 (CRITICAL): Rollback path naming — basename collisions.** Two files `foo/spec.md` and `bar/spec.md` both map to `.rollback/spec.md`. Genuine design bug — must preserve canonical-relative paths under `.rollback/`.

**OAI-F4 (CRITICAL): Manifest durability — no fsync specification.** File copy can succeed but manifest update can be lost on crash. Genuine concern for crash-critical code. Fix: specify fsync semantics, temp+rename for copies.

**OAI-F3 (CRITICAL): State ordering inconsistency.** Lock release (step 9) before ledger update (step 12) allows competing contract to dispatch before completion is recorded. Genuine ordering bug — fix by defining authoritative sequence.

**DS-F5 (SIGNIFICANT): Crash recovery misattributes partial copy as external modification.** If crash occurs mid-file-copy, destination is partially written, hash mismatches. Recovery incorrectly treats this as external modification → DEAD_LETTER. Genuine edge case — fix with size check before hash comparison.

**GEM-F4 (SIGNIFICANT): File deletion between lock and promotion.** `read_file()` on a deleted file crashes instead of detecting conflict. Genuine — add existence check.

**GRK-F2 (SIGNIFICANT): Crash between lock acquisition and manifest write.** No recovery path defined. Genuine gap.

### Contradictions

**Global lock bottleneck:** DS-F3 suggests per-path promotion locks; OAI and GRK accept global lock as appropriate for the workload. **Assessment:** Global lock is correct for current scale (single-user, handful of files per promotion). Per-path adds complexity without proportional benefit. Defer.

**Executor isolation:** OAI-F12 says convention-only isolation is not real security. DS and GRK accept it. **Assessment:** For a trusted single-user system, convention is sufficient. Not a security system.

**External edit policy:** OAI-F13 notes ambiguity between "expected and detected" vs "AD-001 violation." **Assessment:** Clarify that human edits are expected and supported; hash conflicts are the detection mechanism, not architectural violations.

### Action Items

**Must-fix (blocking implementation):**

- **A1** (OAI-F1, GEM-F1, DS-F1, GRK-F7): Move hash verification inside promotion lock. Sequence: acquire lock → verify hashes → construct manifest → backup → copy.
- **A2** (OAI-F2): Make write-lock acquisition atomic — single SQLite transaction for all target paths, rollback on any conflict.
- **A3** (OAI-F5, GEM-F2, GRK-F1): Add per-operation `backed_up: boolean` and promotion `phase` field to manifest. Define recovery behavior per phase.
- **A4** (OAI-F3): Fix state ordering: finish copy → mark manifest completed → update ledger to COMPLETED → release write-locks → release promotion lock → cleanup staging.
- **A5** (OAI-F6): Preserve canonical-relative paths under `.rollback/` (e.g., `.rollback/Projects/foo/spec.md`).
- **A6** (OAI-F7, GEM-F3): Fix path overlap detection — use `GLOB path || '/*'` or application-level separator-aware matching. Escape SQL wildcards.
- **A7** (OAI-F4, OAI-F18): Specify per-file promotion as temp-write + atomic rename + fsync. Specify manifest fsync after each phase transition.

**Should-fix (improve robustness):**

- **A8** (OAI-F20, GRK-F16): Specify SQLite WAL mode, busy timeout (suggest 5s), `BEGIN IMMEDIATE` for lock acquisition.
- **A9** (DS-F6, GRK-F12): Store per-rollback hash in manifest. Verify before restore. Warn on drift.
- **A10** (DS-F5): In crash recovery, distinguish partial copy (size mismatch) from external modification (size matches, hash differs).
- **A11** (GEM-F4): Add file-deletion check in hash conflict detection — if file disappeared, treat as conflict, not crash.
- **A12** (OAI-F8): Define partial promotion terminal semantics — record which ops were applied in dead-letter entry, hold write-locks for non-promoted artifacts.
- **A13** (OAI-F36, GEM-F7, GRK-F15): Add 3+ additional scenario walkthroughs (concurrent promotion race, partial promotion crash, zombie lock recovery).
- **A14** (OAI-F15): Unify cleanup timing — inline delete of non-rollback artifacts after promotion; retain staging root with manifest+rollback until sweep.
- **A15** (OAI-F13): Clarify external edit policy — human edits are expected, detected via hash conflict, not treated as AD-001 violations.

**Defer:**

- **A16** (DS-F3): Per-path promotion locks — defer until scale demands it. Global lock is correct for current workload.
- **A17** (GRK-F17): SQLite VACUUM schedule — defer to operational tuning.
- **A18** (GRK-F4): Startup scan parallelization — defer, unlikely to be a bottleneck.

### Considered and Declined

- **OAI-F12** (executor isolation via convention): `out-of-scope` — trusted single-user system, convention is sufficient. Not a security boundary.
- **OAI-F37/F38/F39** (unverifiable claims about promotion speed, file sizes, ACLs): `constraint` — these are stated design assumptions for a known environment (Mac Studio, vault artifacts). Reworded from assertions to assumptions in A15.
- **GRK-F9** (NEW_FILE sentinel hash collision): `overkill` — SHA-256 collision with a string literal is computationally infeasible.
- **GRK-F13** (interactive confirmation for rollback CLI): `overkill` — rollback is already manual-only and will be implemented with `--force` flag per A9.
