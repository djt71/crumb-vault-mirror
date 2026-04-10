---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/crumb-tess-bridge (full implementation — 41 files)
artifact_type: architecture
artifact_hash: b119ad66
prompt_hash: 8af8e456
base_ref: null
project: crumb-tess-bridge
domain: software
skill_origin: peer-review
created: 2026-02-21
updated: 2026-02-21
status: active
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
    latency_ms: 45197
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-21-crumb-tess-bridge-impl-openai.json
  google:
    http_status: 200
    latency_ms: 59920
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-21-crumb-tess-bridge-impl-google.json
  deepseek:
    http_status: 200
    latency_ms: 142942
    attempts: 2
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-21-crumb-tess-bridge-impl-deepseek.json
  grok:
    http_status: 200
    latency_ms: 29331
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-21-crumb-tess-bridge-impl-grok.json
tags:
  - review
  - peer-review
  - crumb-tess-bridge
---

# Peer Review: crumb-tess-bridge Full Implementation (CTB-014)

**Artifact:** Full bridge implementation — 41 files across src/tess/, src/crumb/, src/e2e/, src/watcher/, plus design docs and infrastructure
**Mode:** full
**Reviewed:** 2026-02-21
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking (via `deepseek-reasoner`), Grok 4.1 Fast Reasoning
**Review prompt:** Security-focused codebase review of 308-test bridge implementation. Focus areas: security end-to-end (governance pipeline, injection resistance), cross-component consistency (Tess/Crumb/watcher schema compliance), spec-implementation gaps, test coverage gaps, code quality. Included all production code, test code, design docs (bridge-schema.md, dispatch-protocol.md), injection test results, and infrastructure config.

---

## OpenAI (GPT-5.2)

### Executive summary
The Phase 1 bridge is generally well-designed: strict allowlists, deterministic canonical hashing shared across Tess+Crumb, confirm-code binding enforced on Crumb, symlink escape protection for `query-vault`, atomic writes, duplicate detection, and an independent governance verifier invoked by the watcher.

The largest correctness/security gap is **a race condition in duplicate detection** (can process the same request twice under concurrency/crash scenarios). The largest architectural risk is that the **governance verification is not cryptographic/authenticated** (it's an integrity "tripwire" for CLAUDE.md changes, not an attacker-proof signature), and the watcher's verification can be bypassed if an attacker can influence the watcher environment or run a different verifier binary.

### Findings

- **[OAI-F1] CRITICAL** — Duplicate processing race in `bridge-processor.js processRequest()` can allow the same request ID to be executed twice under concurrent processing. Duplicate detection (read .processed-ids → check → execute → append → move) is not protected by a lock on the Crumb side. Watcher uses flock, but processor can be invoked directly, and crash between execute and append/move leads to re-processing on restart. Fix: atomic claiming via O_CREAT|O_EXCL lock files or rename-to-inflight pattern.

- **[OAI-F2] SIGNIFICANT** — `outbox-watcher.watchForResponse()` swallows non-ENOENT errors, treating them as "partial write, retry". Permissions errors, I/O errors, or persistent JSON corruption mask real issues and lead to confusing timeouts. Fix: match `checkResponse()` logic — ENOENT → retry, SyntaxError → retry, else reject.

- **[OAI-F3] SIGNIFICANT** — Governance verification is "integrity tripwire", not authenticity boundary. Not keyed/signed; attacker who modifies CLAUDE.md makes both processor and verifier agree. Watcher runs verifier from configurable env path. Fix: clarify threat model; pin verifier paths in plist; consider HMAC with external secret.

- **[OAI-F4] SIGNIFICANT** — Sender allowlist check is optional (CRUMB_BRIDGE_ALLOWED_SENDER absent → anyone with inbox write access can drive operations). confirm_code is not authentication. Fix: require allowlist in production config.

- **[OAI-F5] SIGNIFICANT** — sender_id/message_id checks use `typeof x === 'number'` but don't use `Number.isInteger()`. NaN passes `typeof` check. Fix: `Number.isInteger(x) && x >= 0`.

- **[OAI-F6] SIGNIFICANT** — Tess doesn't validate response schema_version. If schema evolves to 1.1+, Tess relay might misinterpret fields. Fix: add major-version check on Tess response handling.

- **[OAI-F7] MINOR** — `stripBidiOverrides()` exists but is unused. Dead code or missing defense-in-depth. Fix: wire in before validation or delete.

- **[OAI-F8] MINOR** — query-vault path validation doesn't block backslashes. Real enforcement is Crumb's realpathSync. Fix: tighten to allowlist characters.

- **[OAI-F9] STRENGTH** — Confirm-code binding correctly enforced: Tess prevents building write requests without confirmation; Crumb verifies confirm_code === payload_hash.

- **[OAI-F10] STRENGTH** — query-vault symlink escape prevention is correct: realpathSync + containment + regular-file + 1MB cap.

- **[OAI-F11] STRENGTH** — Watcher pipeline includes outbox pre-existence check and post-processing governance verification with alert on failure.

---

## Google (Gemini 3 Pro Preview)

### Executive Summary
The bridge implements a robust file-based message passing architecture with strong defensive depth. The independent governance verification (L5) is a crucial backstop. However, a significant gap exists in transcript integrity verification, and there is tight coupling between Tess and Crumb source trees.

### Findings

- **[GEM-F1] SIGNIFICANT** — Governance verifier (`verify-governance.js`) checks CLAUDE.md hash but fails to verify `transcript_hash`. If processor is compromised, it could write a "clean" transcript hash that doesn't match the actual transcript file. Fix: read transcript file from disk, recompute SHA-256, verify against response.

- **[GEM-F2] MINOR** — ASCII validation permits control characters (0x00–0x1F). `validateAscii` only checks `code > 127`. Allows NUL, backspace, escape chars. JSON.stringify escapes them (preserving hash), but could cause log spoofing or display issues. Fix: reject `< 32` except `\n`, `\r`, `\t`.

- **[GEM-F3] STRENGTH** — Watcher's response verification pipeline provides excellent failure recovery: verify → fail → discard → alert. Fails closed safely.

- **[GEM-F4] MINOR** — Tight source coupling between Tess (untrusted) and Crumb (trusted). `bridge-processor.js` imports from `../../tess/scripts/lib/`. Modification to Tess source automatically changes Crumb processor logic. Fix: duplicate shared modules into Crumb.

- **[GEM-F5] STRENGTH** — Identical hash implementation confirmed by test vectors and cross-language verification. ASCII-only upstream prevents Unicode normalization issues.

- **[GEM-F6] MINOR** — `stripBidiOverrides` implemented but unused. SKILL.md says "Strip bidi overrides" but current implementation rejects (errors out) rather than strips. Fix: update SKILL.md or wire in stripping.

- **[GEM-F7] MINOR** — Missing transcript_hash verification in design docs. bridge-schema.md defines transcript_hash but doesn't mandate verifier check it. Contributes to F1.

- **[GEM-F8] MINOR** — No concurrency tests for `.processed-ids` file. `appendFileSync` usually atomic for small POSIX writes, but no verification under concurrent load.

- **[GEM-F9] MINOR** — Lack of "Pre-Governance" forgery tests. Need test verifying status=completed with governance_check=null is rejected.

- **[GEM-F10] STRENGTH** — Excellent atomic filesystem operations (tmp+fsync+rename) throughout.

- **[GEM-F11] MINOR** — `checkResponse` swallows SyntaxError as "file not ready". But with atomic writes, SyntaxError indicates corruption, not partial write. Fix: log or throw after retries.

- **[GEM-F12] STRENGTH** — Conservative kill-switch implementation: watcher checks before every dispatch, processor checks again, Python daemon can halt even if Node is broken.

---

## DeepSeek (V3.2-Thinking via `deepseek-reasoner`)

### Findings

- **[DS-F1] SIGNIFICANT** — Inconsistent ASCII validation scope between Tess and Crumb. Tess validates only params; Crumb validates entire request object. Non-ASCII in `original_message` passes Tess but rejected by Crumb, causing hash mismatch instead of clear ASCII error. Fix: align scope — recommend Tess validate all string fields.

- **[DS-F2] MINOR** — `stripBidiOverrides()` defined but not called in echo pipeline. Defense-in-depth gap if ASCII validation relaxed. Fix: integrate into `formatEchoHtml()`.

- **[DS-F3] MINOR** — UUIDv7 timestamp parsing in rate limiter assumes monotonic clock. Rejects timestamps before 2020 or after 2100. Clock drift could cause rate-limit bypass. Fix: widen bounds or remove check.

- **[DS-F4] SIGNIFICANT** — Missing Telegram alert delivery. Watcher writes alert JSONs to `_openclaw/alerts/` but nothing reads/relays them. Governance failures go unnoticed. Fix: add alert watcher or extend Tess outbox watcher.

- **[DS-F5] MINOR** — Transcript hash placeholder `{pending}` is predictable. Attacker injecting `{pending}` in reason field could interfere with hash computation. Fix: use random placeholder per transcript.

- **[DS-F6] MINOR** — Missing required params and unknown params both produce `INVALID_SCHEMA`. Makes debugging harder. Fix: add MISSING_PARAMETER code or document.

- **[DS-F7] MINOR** — noTraversal check doesn't decode percent-encoded sequences (`%2e%2e/`). Filesystem won't interpret them, but inconsistent. Fix: reject `%` in paths.

- **[DS-F8] MINOR** — Rate limiter seeds from .processed-ids at millisecond precision but limits at second precision. <1 request difference. Fix: floor-divide timestamps.

- **[DS-F9] MINOR** — Governance canary assumes CLAUDE.md is valid UTF-8. Non-UTF-8 tail bytes could break string slicing. Fix: compare as raw bytes.

- **[DS-F10] MINOR** — First request ever encounters missing .processed-ids. ENOENT → empty handled, but two simultaneous first requests could race. Fix: initialize empty file during setup.

- **[DS-F11] MINOR** — Tests don't cover malformed JSON with valid UUIDv7 filename. rejectRequest filename fallback could conflict with real request. Fix: append `-malformed` to response ID.

- **[DS-F12] STRENGTH** — Comprehensive multi-layer security model with independent verification at each stage.

- **[DS-F13] STRENGTH** — Atomic operations and crash recovery throughout.

- **[DS-F14] STRENGTH** — 15-payload injection test suite with documented residual risks.

- **[DS-F15] STRENGTH** — Cross-component consistency via shared modules.

---

## Grok (4.1 Fast Reasoning)

### Findings

- **[GRK-F1] CRITICAL** — Custom YAML parser in `project-state.js` is incomplete. Doesn't handle escaped quotes, multi-line values, anchors, or lists. `next_action: "say \"hello\""` parses incorrectly. No tests for escaped quotes. Fix: replace with `js-yaml` library.

- **[GRK-F2] CRITICAL** — Watcher doesn't append to `.processed-ids` when skipping via outbox pre-existence (A2 crash recovery). File moved to `.processed/` but ID not recorded. Rate limiter seeds from .processed-ids — skips don't count, allowing burst after restart. Fix: append ID on all terminal paths.

- **[GRK-F3] SIGNIFICANT** — `query-vault` ignores `scope` param. Schema validators allow `scope` enum (`summary`/`full`), but operations.js always reads full content. Violates bridge-schema.md. Fix: implement summary scope.

- **[GRK-F4] SIGNIFICANT** — VAULT_ROOT fallback in constants.js: comment says "4 levels up" but code uses 6 `..` levels. Breaks if directory structure changes. Fix: require `CRUMB_VAULT_ROOT` env var strictly.

- **[GRK-F5] SIGNIFICANT** — No race protection in watcher `_process_inbox()`. Scan → list → serial dispatch can miss files arriving between scan and dispatch. Fix: re-scan after processing.

- **[GRK-F6] SIGNIFICANT** — `verify-governance.js` continues partial verification on missing governance fields instead of early return. May produce misleading output. Fix: early return on missing fields.

- **[GRK-F7] MINOR** — `.processed-ids` duplicate check is O(n) scan via `split('\n').includes()`. Fix: use Set.

- **[GRK-F8] MINOR** — `outbox-watcher.js` treats JSON parse errors as "partial write" with no alert. Corrupted responses silently ignored. Fix: distinguish corruption from pending.

- **[GRK-F9] MINOR** — No tests for `CRUMB_BRIDGE_ALLOWED_SENDER` on Crumb side.

- **[GRK-F10] MINOR** — `countRenderedChars` doesn't handle `&#xHHHH;` numeric HTML entities. Fix: regex replace entities.

- **[GRK-F11] STRENGTH** — E2E confirmation binding correctly enforced. No bypass paths.

- **[GRK-F12] STRENGTH** — Independent governance verifier recomputes from scratch.

- **[GRK-F13] STRENGTH** — Watcher implements full dispatch pipeline with all safety checks.

- **[GRK-F14] STRENGTH** — Atomic writes everywhere, injection test suite comprehensive.

- **[GRK-F15] STRENGTH** — Cross-side consistency via shared modules.

---

## Synthesis

### Consensus Findings

**1. `.processed-ids` integrity gaps (4/4 reviewers)**
All four reviewers identified issues with the `.processed-ids` file:
- OAI-F1: No lock on Crumb-side duplicate check; crash between execute and append → re-processing
- GEM-F8: No concurrency tests
- DS-F10: Race on first-ever request
- GRK-F2: **Watcher outbox-skip path doesn't append to .processed-ids** — rate limiter undercounts

Verified against code: GRK-F2 confirmed. Lines 424-435 of bridge-watcher.py show the outbox pre-existence path moves the file but never appends the ID. This is the highest-signal consensus finding.

**2. outbox-watcher error handling (3/4 reviewers)**
- OAI-F2: `watchForResponse()` swallows non-ENOENT errors
- GEM-F11: `checkResponse()` swallows SyntaxError (which with atomic writes = corruption)
- GRK-F8: Corrupted responses silently ignored

All three agree: the error handling is too permissive. Should distinguish expected (ENOENT, partial write) from unexpected (permissions, corruption) errors.

**3. stripBidiOverrides dead code (3/4 reviewers)**
- OAI-F7, GEM-F6, DS-F2: function exists but is never called

Unanimous recommendation: wire it in as defense-in-depth or delete it. SKILL.md says "strip" but code rejects. Resolution needed for consistency.

**4. Confirm-code binding correctly enforced (4/4 reviewers — STRENGTH)**
- OAI-F9, GRK-F11, DS-F12, GEM (implicit in exec summary)

All reviewers confirmed the core human-in-the-loop mechanism works correctly.

**5. Atomic filesystem operations (4/4 reviewers — STRENGTH)**
- OAI-F10, GEM-F10, DS-F13, GRK-F14

Universal praise for the tmp+fsync+rename pattern and crash recovery design.

### Unique Findings

**GEM-F1: Governance verifier doesn't check transcript_hash** — Genuine insight. Verified: `verify-governance.js` has zero references to `transcript_hash`. The verifier checks CLAUDE.md hash and canary but not the transcript. If the processor is compromised, it could write a fabricated transcript hash in the response. The transcript is an audit trail — its integrity matters for post-incident analysis. This is a real defense-in-depth gap in L5.

**GRK-F1: Custom YAML parser fragility** — Partially valid. The parser IS simple and doesn't handle escaped quotes. But it only parses `project-state.yaml`, which is machine-generated by Claude with a known simple schema. Current data doesn't trigger the bug. Adding a dependency (js-yaml) breaks the zero-dependency design. Better fix: document limitations and add escaped-quote handling inline if needed. Downgraded from CRITICAL to SIGNIFICANT.

**GRK-F3: query-vault ignores scope param** — Genuine insight. Verified: `constants.js` defines `scope: {enum: ['summary', 'full']}` for query-vault, but `operations.js` queryVault handler doesn't use it. Always reads full content. This is a spec-implementation gap.

**DS-F1: Inconsistent ASCII validation scope** — Genuine insight. Tess validates ASCII only on params; Crumb validates the entire request. Non-ASCII in `original_message` would pass Tess but fail Crumb, producing a confusing HASH_MISMATCH instead of a clear ASCII error. Aligning scope would improve error reporting.

**DS-F4: Missing alert delivery mechanism** — Valid observation, but known gap. Alert files are written (Phase 1 deliverable); alert consumption is Phase 2 work. Not a bug — a planned future component.

### Contradictions

**Tess/Crumb code sharing — strength or weakness?**
- GEM-F4: Tight coupling is a security risk — Crumb imports from Tess source tree, so Tess modification changes trusted behavior. Recommends duplicating shared modules.
- DS-F15 + GRK-F15: Cross-component consistency via shared modules is a STRENGTH.

Both positions have merit. In practice: the filesystem permission model (Tess writes as `openclaw` user, Crumb runs as `tess` user) means Tess can't modify its own source tree in a way that affects Crumb without filesystem-level compromise. Duplication would introduce drift risk. **Status quo is correct for Phase 1; revisit for Phase 2 if the trust boundary tightens.**

**Governance verification adequacy:**
- OAI-F3: Governance is merely an integrity tripwire, not authenticity. Recommends HMAC.
- GEM-F3 + GRK-F12 + DS-F12: Independent governance verifier is a STRENGTH.

The spec explicitly declined HMAC in R2 (circularity under BT7 — compromised Tess has signing key). The governance model is designed as integrity detection, not prevention. OpenAI's framing is accurate but the recommendation conflicts with an explicit design decision.

### Action Items

**Must-fix** — blocking Phase 1 stability:

- **A1** (OAI-F1, GRK-F2, GEM-F8, DS-F10): **Append .processed-ids on ALL terminal paths in watcher.** The outbox-skip path (A2 crash recovery) moves the file but doesn't record the ID. This breaks rate limiter seeding and creates an audit gap. Also: add the ID before (not after) processing starts, so crash between execute and append doesn't leave the ID unrecorded.

- **A2** (OAI-F2, GEM-F11, GRK-F8): **Fix outbox-watcher error handling.** Distinguish expected errors (ENOENT → retry, SyntaxError → retry with limit) from unexpected errors (permissions, I/O → fail immediately with descriptive error). Apply to both `watchForResponse()` and `checkResponse()`.

- **A3** (GEM-F1, GEM-F7): **Add transcript_hash verification to verify-governance.js.** Read the transcript file from disk, recompute SHA-256, verify against `response.transcript_hash`. Containment check: ensure transcript path stays within `_openclaw/transcripts/`. This completes L5's verification scope.

**Should-fix** — important but not blocking:

- **A4** (OAI-F7, GEM-F6, DS-F2): **Resolve stripBidiOverrides dead code.** Wire it into `formatEchoHtml()` before HTML escaping as defense-in-depth, OR delete the function and update SKILL.md to say "rejects" instead of "strips." Recommendation: wire in (costs nothing, adds a layer).

- **A5** (OAI-F5): **Use `Number.isInteger()` for numeric field validation.** Replace `typeof x === 'number' && x >= 0` with `Number.isInteger(x) && x >= 0` for `sender_id`, `message_id`, `echo_message_id`, `confirm_message_id`.

- **A6** (GEM-F2, DS-F1): **Tighten ASCII validation.** Reject control characters 0x00–0x1F except `\n` (0x0A), `\r` (0x0D), `\t` (0x09). Also align validation scope: Tess should validate all string fields, not just params, for consistent error messaging.

- **A7** (GRK-F3): **Implement query-vault `scope` parameter.** Schema defines `scope: ['summary', 'full']` but operations.js ignores it. Implement: `summary` → return file stats + first 500 chars; `full` → current behavior. Or remove `scope` from the schema if unneeded.

- **A8** (GRK-F1): **Document YAML parser limitations.** Add a comment in `project-state.js` stating the parser handles flat key-value YAML only (no nested structures, no escaped quotes, no multi-line). If escaped quotes are ever needed in project-state.yaml, add inline handling. Do NOT add js-yaml dependency (breaks zero-dep design). Downgraded from Grok's CRITICAL — parser is fit for its current data.

- **A9** (OAI-F6): **Add Tess-side response schema_version check.** Verify major version matches when reading outbox responses. Prevents silent misinterpretation if schema evolves.

- **A10** (GRK-F6): **Early return in verify-governance.js on missing fields.** If required governance fields are missing, return `{passed: false}` immediately instead of continuing partial checks. Cleaner error output, no behavior change (exit code already 1).

**Defer:**

- **A11** (DS-F4): **Telegram alert delivery mechanism.** Phase 2 scope — alert files are written, consumption component is planned. Not a Phase 1 gap.

- **A12** (GRK-F7): **`.processed-ids` O(n) → Set.** Performance optimization. Current volume is low; watcher compaction keeps file small. Revisit if latency becomes measurable.

- **A13** (OAI-F4): **Production sender allowlist enforcement.** Make `CRUMB_BRIDGE_ALLOWED_SENDER` required in production plist config. Defer to deployment — development needs it optional.

### Considered and Declined

| Finding | Justification | Category |
|---------|--------------|----------|
| OAI-F3: Governance needs HMAC/signing | Spec R2 explicitly declined HMAC (circular under BT7 — compromised Tess has signing key). Governance is designed as integrity detection, not prevention. | constraint |
| OAI-F8: Backslash in query-vault path | macOS only; backslash is valid filename char. realpathSync is the real containment layer. | constraint |
| GEM-F4: Duplicate shared modules into Crumb | Shared code is a design decision for consistency. Duplication introduces drift risk. Filesystem permissions prevent cross-user source modification. | constraint |
| GEM-F9: Pre-governance forgery test needed | Test already exists: verify-governance.test.js includes "success-without-governance detection" (governance_check=null on completed status → fail). | incorrect |
| DS-F3: UUIDv7 monotonic clock assumption | 2020–2100 bounds are reasonable. System clock outside this range indicates misconfiguration, not an attack. | overkill |
| DS-F5: Transcript `{pending}` placeholder | Requires exact string match in a specific hash computation line. Attacker would need to know the placeholder AND inject it at the exact position. Extremely unlikely. | overkill |
| DS-F6: Separate MISSING_PARAMETER error code | INVALID_SCHEMA covers all schema violations. New error codes increase spec complexity for minimal debugging benefit. Error message already specifies which field. | overkill |
| DS-F7: Percent encoding in path traversal | macOS filesystem doesn't interpret percent-encoding. `%2e%2e` is a literal filename. realpathSync is the real containment. | incorrect |
| DS-F8: Rate limiter ms/s precision | <1 request difference. No security impact. | overkill |
| DS-F9: Governance canary non-UTF-8 | CLAUDE.md is always valid UTF-8 markdown by definition. | constraint |
| DS-F11: Malformed JSON filename collision | Direct CLI invocation is an operator action; collision requires knowing a real request's UUIDv7 ID. | overkill |
| GRK-F4: VAULT_ROOT fallback path count | The comment says "4 levels up" but describes 6 hops and the code correctly uses 6 `..` levels. Comment number is wrong; code is correct. This is a documentation nit — the fallback path is actually right. Fix the comment from "4" to "6" as a drive-by. | incorrect |
| GRK-F5: Watcher burst race in _process_inbox | kqueue fires per-file events; each triggers a re-scan. 60s fallback catches anything missed. Phase 1 volume is low (~5-20 req/day). | overkill |
| GRK-F10: countRenderedChars entity handling | Only standard HTML entities (`&amp;`, `&lt;`, `&gt;`) appear in echo output. Numeric entities never generated. | overkill |

### Grok Calibration Note

STRENGTH ratio: 5/15 findings = 33%. Previous review (diagramming skills): 53% STRENGTHs. The prompt addendum is producing better calibration. The CRITICAL rating on GRK-F1 (YAML parser) was overstated (the parser works for current data), but GRK-F2 (.processed-ids outbox-skip gap) was a genuine critical find that 3 other reviewers also touched on from different angles. Grok was the most specific about the exact code path. Keeping in reviewer lineup.
