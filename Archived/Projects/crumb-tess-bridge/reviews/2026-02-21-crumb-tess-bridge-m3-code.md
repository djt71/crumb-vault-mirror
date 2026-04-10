---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/crumb-tess-bridge/src/ (full M3 codebase)
artifact_type: code
artifact_hash: 258ab704
prompt_hash: 827cbead
base_ref: null
project: crumb-tess-bridge
domain: software
skill_origin: peer-review
created: 2026-02-21
updated: 2026-02-21
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - xai/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 46194
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-21-crumb-tess-bridge-m3-code-openai.json
  google:
    http_status: 200
    latency_ms: 46963
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-21-crumb-tess-bridge-m3-code-google.json
  deepseek:
    http_status: 200
    latency_ms: 115383
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-21-crumb-tess-bridge-m3-code-deepseek.json
  grok:
    http_status: 200
    latency_ms: 62531
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-21-crumb-tess-bridge-m3-code-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: crumb-tess-bridge M3 Code Implementation

**Artifact:** `src/tess/` + `src/crumb/` (23 files, 147 tests), `SKILL.md`, `bridge-schema.md` (reference)
**Mode:** full
**Reviewed:** 2026-02-21
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek Reasoner (V3.2), Grok 4.1 Fast Reasoning
**Review prompt:** Security-focused code review of Phase 1 implementation — hash verification, injection resistance, path traversal, schema compliance, test coverage gaps, cross-side consistency.

---

## OpenAI (GPT-5.2)

- [F1]
- [Severity]: CRITICAL
- [Finding]: Crumb does not verify `confirmation.confirm_code === payload_hash` for write operations, and does not require `confirmation.echo_message_id` / `confirmation.confirm_message_id` types.
- [Why]: This is the core "confirmation echo flow" binding in the spec (§3 Validation Rules #5). Without it, any actor that can write to inbox (compromised Tess / BT7 / local attacker) can set `confirmed:true` and bypass the user-verification step entirely. The hash check only detects transit tampering, not that a human confirmed.
- [Fix]: In `bridge-processor.js`, for non-read-only operations enforce:
  - `request.confirmation` object with required integer fields
  - `request.confirmation.confirm_code === request.payload_hash`
  - consider also verifying `confirm_code` is exactly `/^[0-9a-f]{12}$/`
  - reject otherwise with `INVALID_SCHEMA` (or a dedicated error code if you add one).

---

- [F2]
- [Severity]: CRITICAL
- [Finding]: Crumb does not enforce `source.sender_id` allowlist at all.
- [Why]: Spec §3 Validation Rule #8 requires Crumb to reject unauthorized senders. As implemented, anyone who can place a file in inbox can impersonate the authorized Telegram user. Given the threat model explicitly calls out Tess as untrusted transport, Crumb must be the enforcement point.
- [Fix]: Add an env/configured `ALLOWED_SENDER_ID` on Crumb side and check:
  - `request.source.platform === 'telegram'`
  - `request.source.sender_id === ALLOWED`
  - types: integers
  Reject with `INVALID_SENDER`.

---

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: Tess builds write-operation requests with `confirmed: true` even when `meta.confirmation` is missing; it will emit `confirmation: null`.
- [Why]: This creates malformed requests that will later be rejected by Crumb (it checks confirmation non-null), but more importantly it means Tess-side "confirm then write" is not structurally enforced by the request builder. This weakens the intended safety invariant and increases chances of operator error / accidental bypass in upstream code.
- [Fix]: In `buildRequest()`:
  - if operation is write op and `meta.confirmation` missing, throw / return validation error rather than producing a request.
  - also validate `confirm_code === payload_hash` before writing (even though Crumb must enforce too).

---

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: `bridge-cli.js hash` and `format-echo` do not enforce ASCII-only before hashing/echoing; they compute a hash over possibly non-ASCII params.
- [Why]: Spec requires rejecting non-ASCII **before hashing** (canonical JSON rules §5 rule #3). If some caller uses `hash`/`format-echo` without running `validate` first, Tess can show a confirmation code that Crumb will reject (since Crumb uses `validateParams` which includes ASCII enforcement). This becomes a correctness and UX failure and can be exploited for confusion.
- [Fix]: In `cmdHash` and `cmdFormatEcho`, call `validateOperation` + `validateParams` (or at least `validateAscii`) and exit with `INVALID_SCHEMA` on violation before producing hash/html.

---

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Crumb does not validate request `confirmed` / `confirmation` for read-only operations (it accepts any values).
- [Why]: Spec says read-only ops "may have confirmed:false, confirmation:null"; it doesn't say they must, but allowing arbitrary confirmation objects increases protocol ambiguity and makes it harder to reason about logs/audits. Also it's an easy place for future logic bugs if later code assumes read-only implies `confirmation:null`.
- [Fix]: Enforce for read-only ops: `confirmed === false` and `confirmation === null` (or explicitly normalize them before transcript/response).

---

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Request schema compliance gaps on Crumb: it validates operation/params/hash, but does not validate many required top-level fields/types (`timestamp`, `original_message`, `source.message_id`, `source.platform`, numeric types, UUIDv7 format).
- [Why]: This diverges from `bridge-schema.md` ("schema_version required", UUIDv7 required, timestamps required, etc.). It weakens audit quality, increases risk of odd parsing edge cases, and breaks cross-side guarantees ("Both reject independently").
- [Fix]: Add explicit request-structure validation in Crumb before governance boundary:
  - required fields present, correct types
  - UUIDv7 regex check for `id` and `source` integer checks
  - timestamp ISO8601 `...Z`

---

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Governance check is computed but never *verified against an expected value* (no pinned hash/canary comparison); failures only occur if `CLAUDE.md` is missing/unreadable.
- [Why]: Spec's `GOVERNANCE_FAILED` implies a meaningful check (hash mismatch / canary mismatch) against a known-good reference. As-is, an attacker who can modify `CLAUDE.md` (or the vault) can change governance text and still pass governance.
- [Fix]: Introduce configured expected values (e.g., env vars or a pinned file):
  - `EXPECTED_GOVERNANCE_HASH` and/or expected canary substring
  - compare computed vs expected; throw `GOVERNANCE_FAILED` on mismatch.

---

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: `.processed-ids` deduplication is race-prone and not atomic across concurrent processors.
- [Why]: Two `bridge-processor` instances can process the same request simultaneously: both read `.processed-ids`, see missing, both execute side effects, then both append. This defeats replay protection and can double-apply write operations.
- [Fix]: Use a lock (file lock via `flock` in a wrapper, or atomic "claim" file).

---

- [F9]
- [Severity]: MINOR
- [Finding]: Atomic write protocol is incomplete: you `fsync` the file, but not the directory containing it.
- [Why]: On crash/power loss, rename durability is not guaranteed without syncing the directory entry on some filesystems.
- [Fix]: After `renameSync`, open directory fd and `fs.fsyncSync(dirfd)` (where supported).

---

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Tess-side `query-vault` path validation is inconsistent with spec and weaker than Crumb's.
- [Why]: Tess is not trusted, so Crumb's realpath containment is the real control; still, protocol consistency matters and weak Tess validation increases user confusion and test drift.
- [Fix]: Keep Tess minimal and rely on Crumb, but align error codes/messages.

---

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: Response schema mismatch: error responses for unknown operation in Crumb are "pre-governance" with null governance/transcript, whereas spec example shows governance present for unknown op.
- [Why]: Drift from spec makes Tess relay formatting and future clients brittle.
- [Fix]: Decide and document: either (A) unknown-op is pre-governance (null governance/transcript) and update spec/examples, or (B) always write transcript/governance for all errors after parse.

---

- [F12]
- [Severity]: MINOR
- [Finding]: Transcript injection / formatting robustness: transcript writes parameter lines as `key: ${value}` without escaping newlines.
- [Why]: Params are ASCII-only, but can still contain `\n` and markdown-significant text.
- [Fix]: Sanitize transcript-rendered values.

---

- [F13]
- [Severity]: STRENGTH
- [Finding]: Canonical JSON + hash implementation is consistent cross-side: Tess's `sortKeysDeep` + `JSON.stringify` matches the spec; vectors are tested; Crumb recomputes using the same implementation (shared module).

---

- [F14]
- [Severity]: STRENGTH
- [Finding]: Crumb `query-vault` implements realpath-based containment and rejects symlink escapes.

---

- [F15]
- [Severity]: SIGNIFICANT
- [Finding]: No tests cover the missing critical security checks: `confirmation.confirm_code` equality and `source.sender_id` allowlist enforcement (because they're not implemented).
- [Fix]: Add processor integration tests for these paths.

---

- [F16]
- [Severity]: MINOR
- [Finding]: No tests cover concurrent processing race on `.processed-ids` / double execution.

---

- [F17]
- [Severity]: MINOR
- [Finding]: Tess tests do not ensure `hash`/`format-echo` reject non-ASCII.

---

- [F18]
- [Severity]: SIGNIFICANT
- [Finding]: Tess and Crumb share `validateParams`, but Tess CLI can still write requests with nonsensical confirmation codes. Demonstrates the protocol is not end-to-end consistent.

---

## Google (Gemini 3 Pro Preview)

**[S1] [STRENGTH] Robust Path Traversal Protection**
The implementation of `queryVault` in `operations.js` correctly uses `fs.realpathSync` to resolve both the vault root and the target path, then verifies the target is contained within the root. This effectively prevents `..` attacks and symlink escapes.

**[S2] [STRENGTH] ASCII-Only Enforcement**
The code strictly enforces the ASCII-only requirement for `params` in `canonical-json.js`. This eliminates an entire class of hashing ambiguity attacks related to Unicode normalization.

**[S3] [SIGNIFICANT] Unbounded File Read in `query-vault` (DoS Risk)**
In `operations.js`, the `queryVault` function defines a `MAX_CONTENT_LENGTH` of 4000 characters, but it executes `fs.readFileSync(realTarget, 'utf8')` *before* checking the length or truncating. If a user requests a massive file (e.g., 2GB), Node.js will attempt to load the entire file into memory, likely causing the Crumb process to crash. Fix: Use `fs.openSync` and `fs.readSync` to read only the first `MAX_CONTENT_LENGTH + 1` bytes, or check `fs.statSync(path).size` before reading.

**[S4] [MINOR] Atomic Write `fsync` Compatibility**
`atomic-write.js` uses `fs.fsyncSync(fd)`. While correct, `fsync` can throw errors on certain virtualized file systems or Docker mounts. Fix: Wrap in try/catch for `EINVAL`/`ENOTSUP` if strict durability isn't critical.

**[C1] [STRENGTH] Canonical JSON & Test Vectors**
The implementation includes `cmdVerifyVectors` and unit tests that validate against `canonical-json-test-vectors.json`.

**[C2] [MINOR] Silent Failures in `list-projects`**
`listProjects` iterates directories and calls `readProjectState` in a try/catch that swallows all errors. If a `project-state.yaml` has a syntax error, the project disappears from the list without warning. Fix: Catch specific errors (`ENOENT`) and report malformed files as "invalid."

**[C3] [MINOR] Dependency Coupling (Cross-Side)**
`bridge-processor.js` imports from `../../tess/scripts/lib/...`. Guarantees algorithm match but violates architectural boundary. Fix: Move shared libraries to `src/common` or `src/shared`.

**[T1] [GAP] Large Payload/File Tests** — No tests simulate query-vault on a very large file.

**[T2] [GAP] File Permission Errors** — Tests cover logic errors but not system errors (read-only outbox, locked inbox file).

**[Q1] [STRENGTH] Transcript Generation** — The `TranscriptBuilder` class is well-structured. The hash-with-placeholder bootstrap is clever and correctly implemented.

**[Q2] [MINOR] Sync I/O in Bridge Processor** — Synchronous I/O throughout. Assessment: For a local, single-user bridge, this is actually **preferable** to async I/O because it simplifies atomic rename logic and prevents race conditions.

---

## DeepSeek (Reasoner V3.2)

### F1 - Missing Confirmation Code Verification
**Severity**: SIGNIFICANT
Crumb-side `bridge-processor.js` does not validate that `confirmation.confirm_code` matches `payload_hash` for write operations, despite §3 requiring it. Fix: Add validation after confirmation non-null check.

### F2 - Race Condition in `.processed-ids` Update
**Severity**: SIGNIFICANT
The `bridge-processor.js` reads `.processed-ids` once at start then appends. Between read and append, another process could add the same ID. Fix: Use file locking or atomic append with pre-check.

### F3 - Incomplete Path Traversal Validation
**Severity**: SIGNIFICANT
Tess-side `schema.js` validates `query-vault` paths for `..` and absolute paths, but misses patterns like `./../`, `/../`. Fix: Enhance validation with `path.normalize()`.

### F4 - Missing ASCII Validation in Echo Formatter
**Severity**: MINOR
`echo-formatter.js` uses `escapeHtml()` but doesn't strip or reject non-ASCII characters. Fix: Apply `stripBidiOverrides` to all parameter values or add ASCII validation.

### F5 - Inconsistent Timestamp Format
**Severity**: MINOR
Tess truncates milliseconds but Crumb doesn't consistently. Fix: Ensure both sides use same format.

### F6 - Missing Test for Partial File Writes
**Severity**: MINOR
No tests simulate crashes during atomic write operations. Fix: Add tests verifying no partial files remain on failure.

### F7 - Transcript Injection Vulnerability
**Severity**: MINOR
`TranscriptBuilder` doesn't sanitize user-provided text in `resultText`, which could inject malicious markdown. Fix: Escape markdown special characters.

### F8 - Incomplete Error Recovery in Outbox Watcher
**Severity**: MINOR
`watchForResponse` catches all errors (including JSON parse) and treats them as "file not ready." Fix: Distinguish ENOENT from other errors.

### F9 - Missing Validation for Source Sender ID
**Severity**: SIGNIFICANT
Crumb doesn't validate `source.sender_id` against an allowed list. Fix: Add sender ID validation with configurable allowed IDs.

### F10 - Hardcoded Path Assumptions
**Severity**: MINOR
`VAULT_ROOT` uses brittle `path.resolve(__dirname, '..'.repeat(6))`. Fix: Require `CRUMB_VAULT_ROOT` env var.

### F11 - Missing Test for Unicode Normalization Attacks
**Severity**: MINOR
No tests verify homoglyph attacks are rejected by ASCII validation. Fix: Add test cases with similar-looking non-ASCII characters.

### F12 - Inconsistent JSON Serialization
**Severity**: MINOR
`canonicalJson` uses `JSON.stringify` on pre-sorted objects, potential differences with Python reference for edge cases. Fix: Add more comprehensive test vectors.

### F13 - Missing Cleanup of Temp Files
**Severity**: MINOR
`atomicWriteJson` leaves `.tmp-*.json` files on rename failure. Fix: Add try-catch around rename and delete temp on failure.

### F14 - No Validation for Schema Version Minor Increments
**Severity**: MINOR
Code validates major version but doesn't handle unknown minor versions per spec. Fix: Parse semver.

### F15 - Risk Tier Assignment for `reject-gate`
**Severity**: MINOR
`reject-gate` classified as "low" risk in code, but spec lists it as "Medium" for `approve-gate`. Fix: Align risk tiers.

### Strengths
1. Comprehensive test suite covering most critical paths
2. Good separation of concerns between Tess and Crumb sides
3. Atomic file operations prevent partial reads
4. Canonical JSON implementation matches specification with test vectors
5. Governance check integration ensures CLAUDE.md verification
6. Telegram character budget awareness in echo formatting

---

## Grok (4.1 Fast Reasoning)

- [SEC-1] **Severity: CRITICAL** — Crumb-side does not verify `confirmation.confirm_code === payload_hash` for write operations. Only checks `confirmed: true` and `confirmation` non-null. Enables bypass of confirmation echo flow via direct inbox writes. Fix: Add confirm_code === payload_hash check with type validation on confirmation fields.

- [SEC-2] **Severity: SIGNIFICANT** — No validation of `source.sender_id` against a hardcoded/allowed Telegram user ID anywhere (Tess or Crumb), despite spec §3.8. Allows unauthorized users to submit requests via direct inbox writes. Fix: Define `ALLOWED_SENDER_ID` env var, validate in bridge-processor.js.

- [SEC-3] **Severity: SIGNIFICANT** — No explicit checks for `source.platform === 'telegram'` or integer types for `source.sender_id/message_id/confirmation.echo_message_id`. Allows forged sources. Fix: Validate types and platform string.

- [QUAL-1] **Severity: MINOR** — All file I/O is synchronous. Blocks Node event loop on large files. Fix: Convert to async for Phase 2.

- [QUAL-2] **Severity: MINOR** — `VAULT_ROOT` uses brittle 7-level relative path resolve. Fix: Require `CRUMB_VAULT_ROOT` env var mandatory.

- [COR-1] **Severity: MINOR** — Canonical JSON recursive sort matches spec, but Python reference example lacks recursive sort. Future Phase 2 ops with nested params could mismatch. Fix: Update spec Python example, add nested test vector.

- [TEST-1] **Severity: MINOR** — No tests for confirmation mismatch, invalid sender_id, or GOVERNANCE_FAILED (missing CLAUDE.md). Core security checks untested. Fix: Add Crumb integration tests for these paths.

- [TEST-2] **Severity: MINOR** — No race condition tests for concurrent processing or .processed-ids append races. Fix: Spawn 2 processes, assert one DUPLICATE_REQUEST.

- [PERF-1] **Severity: MINOR** — Duplicate check loads/splits entire `.processed-ids` per request, grows unbounded. Fix: Implement rotation or use Set.

- [QUAL-3] **Severity: MINOR** — Crumb tightly couples to Tess libs via relative require paths. Fix: Extract shared libs to `src/shared/lib/`.

- [ST-1] **Severity: STRENGTH** — Atomic writes (tmp-uuid + fsync + rename) match spec §7, preventing partial reads.

- [ST-2] **Severity: STRENGTH** — Dual validation (Tess pre-write, Crumb re-validate/hash) with identical impl (shared libs) ensures spec compliance.

- [ST-3] **Severity: STRENGTH** — Path traversal blocked at both layers: Tess rejects `..`/`/`, Crumb realpath+startsWith (symlink-proof).

---

## Synthesis

### Consensus Findings

**1. Missing `confirm_code === payload_hash` verification on Crumb side** (OAI-F1, DS-F1, GRK-SEC-1 — 3/4 reviewers, CRITICAL)
The bridge-processor checks `confirmed: true` and `confirmation !== null` but never verifies the confirm_code matches the payload_hash. This defeats the core security model: an attacker with inbox write access can forge confirmed requests without user verification.

**2. Missing `source.sender_id` allowlist enforcement on Crumb side** (OAI-F2, DS-F9, GRK-SEC-2 — 3/4 reviewers, SIGNIFICANT)
Spec §3 rule 8 requires sender validation. Crumb is the enforcement point (Tess is untrusted). Currently anyone with inbox write access can impersonate the authorized user.

**3. `.processed-ids` race condition under concurrent processing** (OAI-F8, DS-F2, GRK-TEST-2 — 3/4 reviewers, SIGNIFICANT)
Read-then-append is not atomic. Two processors could both pass the dedup check and execute the same write operation.

**4. Cross-side import coupling** (GEM-C3, GRK-QUAL-3 — 2/4 reviewers, MINOR)
Crumb imports shared libs from `../../tess/`. Works in monorepo but breaks if sides are deployed separately.

**5. Tess-side path validation weaker than Crumb** (OAI-F10, DS-F3 — 2/4 reviewers, SIGNIFICANT)
Tess only checks for `..` and absolute paths but doesn't normalize. Crumb's realpath containment is the real control.

**6. Missing ASCII validation in `hash`/`format-echo` CLI** (OAI-F4, DS-F4 — 2/4 reviewers, SIGNIFICANT)
Spec requires ASCII rejection before hashing. These commands compute hashes without validation, creating potential hash mismatch UX failures.

**7. Missing source field type validation** (OAI-F6, GRK-SEC-3 — 2/4 reviewers, SIGNIFICANT)
Crumb doesn't validate types/structure of source fields (platform string, integer IDs).

**8. Transcript injection via unsanitized values** (OAI-F12, DS-F7 — 2/4 reviewers, MINOR)
Transcript writes param values without escaping newlines or markdown. ASCII-only prevents Unicode attacks but `\n` injection is still possible.

### Unique Findings

**GEM-S3: Unbounded file read in `query-vault` (SIGNIFICANT)** — Genuine insight. `readFileSync` loads the entire file before truncation. A multi-GB file would crash the process. Only Gemini caught this. Real DoS vector.

**OAI-F7: Governance check not verified against pinned expected value (SIGNIFICANT)** — Interesting but misunderstands the architecture. Phase 1 Crumb computes and reports governance; Phase 2 runner (CTB-012) does the comparison. The current design is intentional — Crumb can't pin its own governance hash.

**OAI-F3: Tess `buildRequest` produces `confirmed:true` with `confirmation:null` (SIGNIFICANT)** — Genuine gap. The request builder should refuse to create a write request without confirmation data.

**OAI-F11: Response schema mismatch for pre-governance errors (SIGNIFICANT)** — Valid observation. Spec examples showed governance on unknown-op errors, but the implementation correctly returns null governance for pre-governance failures. **Resolved:** spec updated to match code (§4.5 and §7 error response examples now show `null` governance).

**DS-F8: Outbox watcher masks JSON parse errors (MINOR)** — Valid. `watchForResponse` treats all errors as "not ready yet" instead of distinguishing ENOENT from corrupt JSON.

**GRK-COR-1: Python spec example lacks recursive sort (MINOR)** — Valid. The Python reference implementation in bridge-schema.md uses `sort_keys=True` which is top-level only. Should add recursive sort for consistency with Phase 2 nested params.

### Contradictions

**Sync vs Async I/O:** Grok (QUAL-1) flags sync I/O as an anti-pattern; Gemini (Q2) explicitly endorses it as preferable for single-user local bridge. **Assessment:** Gemini is correct for Phase 1. Sync simplifies the atomic write protocol. Phase 2 may need async for the watcher daemon.

**Risk tier for `reject-gate`:** DeepSeek (F15) says spec lists it as "Medium." **Assessment:** Spec §2 shows `reject-gate` as "Low" risk. `approve-gate` is "Medium." The current code is correct.

### Action Items

**Must-fix** (blocking M4 validation):

- **A1** (OAI-F1, DS-F1, GRK-SEC-1): Add `confirmation.confirm_code === payload_hash` verification in `bridge-processor.js` for write operations. Also validate `confirmation.echo_message_id` and `confirmation.confirm_message_id` are integers. Reject with `INVALID_SCHEMA`.

- **A2** (OAI-F2, DS-F9, GRK-SEC-2): Add `source.sender_id` allowlist enforcement in `bridge-processor.js`. Use `CRUMB_BRIDGE_ALLOWED_SENDER` env var. Reject with `INVALID_SENDER`.

- **A3** (OAI-F4, DS-F4): Add ASCII validation (via `validateAscii`) to `cmdHash` and `cmdFormatEcho` in `bridge-cli.js`. Reject before hashing.

- **A4** (GEM-S3): Fix unbounded file read in `queryVault` — use `fs.statSync` size check or `fs.openSync` + `fs.readSync` for bounded read before string construction.

**Should-fix** (before daily use):

- **A5** (OAI-F6, GRK-SEC-3): Add source field type validation on Crumb side — `platform === 'telegram'`, `sender_id`/`message_id` are positive integers.

- **A6** (OAI-F3): Make `buildRequest` refuse to create write-op requests without valid confirmation data. Throw if `meta.confirmation` is missing for non-read-only operations.

- **A7** (OAI-F15, GRK-TEST-1): Add integration tests for: confirm_code mismatch, invalid sender_id, missing CLAUDE.md governance failure.

- **A8** (DS-F8): Improve `watchForResponse` error handling — distinguish ENOENT (retry) from JSON parse errors (log + retry limited times, then fail).

- **A11** (OAI-F12, DS-F7): Transcript value sanitization — promoted from defer per user review. Transcripts are currently internal audit artifacts, but the dispatch protocol implies they may become inputs to future operations. **Time-bound:** must be addressed before Phase 2 dispatch (CTB-012) or any operation that consumes transcript content.

- **OAI-F11** (response schema mismatch for pre-governance errors): Spec-side cleanup — promoted from declined per user review. The code behavior (`governance_check: null` for pre-governance errors) is correct; the spec examples in §4.5 and §7 were wrong. **Fixed:** spec updated to show `null` governance on unknown-op errors.

**Defer:**

- **A9** (OAI-F8, DS-F2, GRK-TEST-2): `.processed-ids` race condition — Phase 1 is single-processor. Phase 2 bridge runner (CTB-011) implements flock. Defer to CTB-011.

- **A10** (GEM-C3, GRK-QUAL-3): Cross-side import refactoring to `src/shared/` — Phase 2 deployment concern. Monorepo path works for Phase 1.

- **A12** (GRK-COR-1): Add nested test vector and update Python spec example — Phase 2 concern when nested params exist.

### Considered and Declined

- **OAI-F7** (governance pinned hash): `declined — constraint`. Phase 1 Crumb computes and reports governance. Phase 2 runner (CTB-012) does comparison against pinned values. Crumb cannot meaningfully pin its own governance hash.

- **OAI-F5** (enforce `confirmed=false` for read-only): `declined — overkill`. Crumb handles read-only operations correctly regardless. Strict enforcement adds complexity without proportional security benefit.

- **GRK-QUAL-1** (async I/O): `declined — constraint`. Sync I/O is correct for Phase 1 single-user bridge (Gemini concurs). Phase 2 daemon may revisit.

- **DS-F12** (canonical JSON edge cases): `declined — incorrect`. Test vectors prove byte-identical output across implementations. `JSON.stringify` behavior is deterministic for the types used.

- **DS-F14** (schema version minor handling): `declined — incorrect`. Current implementation checks `major === '1'`, which correctly accepts `1.0`, `1.1`, etc. This is the specified behavior.

- **DS-F15** (reject-gate risk tier): `declined — incorrect`. Spec §2 shows `reject-gate` as "Low" risk. The code is correct.

- **OAI-F9** (directory fsync): `declined — overkill`. macOS APFS provides sufficient rename durability guarantees. Directory fsync is a Linux ext4 concern.

- **DS-F13** (temp file cleanup on rename failure): `declined — overkill`. Rename to same filesystem is guaranteed to succeed on POSIX. Temp file orphaning only occurs on disk-full or filesystem corruption.

- **OAI-F11** (response schema mismatch for pre-governance errors): Reclassified to **should-fix** per user review. See Action Items. Spec updated.

- **GRK-PERF-1** (.processed-ids performance): `declined — overkill`. Phase 1 volumes are <50 requests/day. A linear scan of 30 days of IDs (<1500 lines) is negligible. Rotation is a CTB-011 concern.

### Grok Calibration Note

Grok produced 13 findings: 3 issues (1 CRITICAL, 2 SIGNIFICANT), 7 issues (6 MINOR), 3 STRENGTHs. Ratio: 77% issues / 23% strengths — significant improvement from the first review (53% issues). The `prompt_addendum` is working. SEC-1 (confirm_code bypass) was Grok's highest-value finding, matching the consensus CRITICAL. Keeping Grok in the lineup.
