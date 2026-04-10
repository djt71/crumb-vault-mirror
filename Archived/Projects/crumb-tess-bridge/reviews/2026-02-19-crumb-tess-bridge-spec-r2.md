---
type: review
review_mode: full
review_round: 2
prior_review: Projects/crumb-tess-bridge/reviews/2026-02-19-crumb-tess-bridge-spec.md
artifact: Projects/crumb-tess-bridge/design/specification.md
artifact_type: spec
artifact_hash: 4cac2c9e
prompt_hash: 60cbdbfe
base_ref: null
project: crumb-tess-bridge
domain: software
skill_origin: peer-review
created: 2026-02-19
updated: 2026-02-19
status: active
reviewers:
  - openai/gpt-5.2
  - google/gemini-2.5-pro
config_snapshot:
  curl_timeout: 120
  max_tokens: "8192 (OpenAI, Google)"
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 62490
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-19-crumb-tess-bridge-spec-r2-openai.json
  google:
    http_status: 200
    latency_ms: 42277
    attempts: 1
    model_note: "gemini-2.5-pro (fallback from gemini-3-pro-preview, which returned 503 on all 3 attempts)"
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-19-crumb-tess-bridge-spec-r2-google.json
  perplexity:
    http_status: 200
    latency_ms: 15423
    attempts: 1
    error: "Sonar Reasoning Pro performed web search instead of reviewing artifact. 15-line non-review response. Skipped from synthesis."
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-19-crumb-tess-bridge-spec-r2-perplexity.json
tags:
  - review
  - peer-review
---

# Peer Review R2: Crumb-Tess Bridge Specification

**Artifact:** Projects/crumb-tess-bridge/design/specification.md
**Mode:** Full (with diff-aware prompt — reviewers directed to focus on R1 changes)
**Reviewed:** 2026-02-19
**Reviewers:** GPT-5.2, Gemini 2.5 Pro (fallback from Gemini 3 Pro Preview, 503)
**Perplexity:** Failed — Sonar Reasoning Pro performed web search instead of artifact review. Excluded from synthesis.
**Review prompt:** Full spec with R1 change summary (A1-A5, A8), 7 review focus questions targeting consistency, threat gaps, governance verification, hash flow, concurrency, schema compat, and author notes.

---

## OpenAI GPT-5.2

- **[F1]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Hash confirmation is well-specified for Telegram->Tess->inbox integrity, but *not* fully end-to-end without clarifying who computes/validates `payload_hash` and what canonicalization is (bytes, encoding, escaping, Unicode policy).**
  - **[Why]:** BT2/BT6 rely on "same payload => same hash" across (a) Tess echo, (b) Tess inbox write, (c) Crumb recomputation. If Tess and Crumb implement canonical JSON differently (Unicode normalization, escaping, key ordering, float/int rendering, newline handling), you can get false rejections (availability) or worse: user confirms one visual JSON but different byte-level JSON hashes to same displayed code in edge cases (confusables/normalization).
  - **[Fix]:** Define canonicalization normatively:
    - Canonical input is an object `{ "operation": <string>, "params": <object> }` only (exclude other fields).
    - UTF-8 bytes; Unicode normalized to NFC (or explicitly "no normalization, reject non-ASCII in all string values").
    - JSON serialization: RFC 8785 (JCS) or adopt an explicit library and version.
    - Forbid any non-ASCII characters in *all* values included in the hash (you already hint "ASCII-only values" -- make it a validation rule with rejection behavior).
    - Specify that the *same canonical bytes* are what Tess shows (e.g., echo prints exactly the canonical JSON string it hashed).

- **[F2]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: BT6 "strict field validation" and "Tess NEVER interprets intent" are in tension with the current design (Tess must map free-form user text/voice into `operation` + `params`).**
  - **[Why]:** The Governance Model section claims Tess doesn't interpret intent, but BT6 explicitly assumes NLU extraction. This inconsistency can cause implementers to underinvest in the "NLU as code" risk and skip deterministic validation/clarification flows.
  - **[Fix]:** Rephrase the principle to something implementable, e.g.:
    - "Tess may *classify* messages into an allowlisted operation and fill parameters, but must treat any ambiguity as a hard stop and ask clarifying questions; Tess must never expand scope or invent tasks."
    - Add a small "NLU policy" subsection: allowed mappings, required disambiguation questions, and examples for voice/STT.

- **[F3]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: The new BT3 two-tier governance verification is directionally strong, but the "runner injects expected_governance_hash into the prompt and checks response includes governance_hash" can be satisfied even if CLAUDE.md wasn't actually loaded -- because the model can simply echo the injected value.**
  - **[Why]:** This is the core weakness R1 was trying to eliminate (LLM-asserted checks). Right now, the "external verification" is partly circular: you verify that the response contains a value you provided. The canary helps, but the canary is also model-reported unless you can independently validate it.
  - **[Fix]:** Make the external verification *non-echoable*:
    - Runner should *also* compute a `claude_md_sha256` and then require the session to return a derived value that depends on reading CLAUDE.md content not present in the prompt. Example: require Crumb to output `governance_canary_line` (exact last N chars of CLAUDE.md) and runner verifies it matches what's on disk. Or require a second hash: `sha256(CLAUDE.md || "\n" || fixed_salt)` where the salt is provided by runner, but the file content must be read to compute it.
    - Better: have the runner itself read CLAUDE.md and embed **only** a nonce; require the session to read CLAUDE.md and return `HMAC-like` construct isn't possible without a secret, but you can require returning the *last 64 bytes* of CLAUDE.md (or a specific "canary block") and verify byte-for-byte runner-side.
    - Clarify that `governance_check.governance_hash` must equal the runner-computed hash of on-disk CLAUDE.md *and* the response must include `governance_canary` that the runner verifies against the actual file.

- **[F4]**
  - **[Severity]: MINOR**
  - **[Finding]: Canary-string placement "near end" detects truncation at the end, but does not detect "middle-section missing/ignored" and doesn't address partial loading due to tool-mode differences (e.g., `--print` loading different policy paths).**
  - **[Why]:** You already acknowledge "middle sections" as residual risk; the spec should either (a) accept explicitly, or (b) add a stronger deterministic check.
  - **[Fix]:** Add a second canary located in the middle (two canaries at 60% and 95% positions), and have runner verify both exact strings. Or define a single "canary block" containing multiple lines and require exact match of the whole block (harder to accidentally reproduce).

- **[F5]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: U7 session concurrency mitigation via `pgrep -f claude` is underspecified and likely insufficient alone; it can false-positive/false-negative and doesn't prevent races between check and spawn.**
  - **[Why]:** This is a Phase 2 blocker. `pgrep` can match unrelated processes, miss short-lived sessions, and has TOCTOU races. Concurrency issues are often about file locks/SQLite locks; you want a deterministic single-writer policy.
  - **[Fix]:** Use a lockfile + `flock` (or `lockf`) as the primary mechanism, with `pgrep` as advisory:
    - Runner acquires `~/.crumb/bridge_runner.lock` (owned by primary user). If lock held, queue/fail-fast.
    - Interactive sessions should also attempt to acquire a shared "claude session lock" if you can instrument them; if not, still keep `pgrep` to detect interactive sessions and avoid starting.
    - Additionally, consider locking on the actual SQLite DB file with a non-invasive probe, or define: "bridge runner uses `--continue` only when no other sessions exist; otherwise always start a fresh isolated run directory/profile if supported."

- **[F6]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Phase 1<->Phase 2 protocol reuse promise now conflicts with BT3's "runner injects expected_governance_hash" requirement -- Phase 1 has no runner, and Phase 1 currently implies interactive processing.**
  - **[Why]:** You've made governance verification "Phase 2 requirement, not deferred," but the mechanism described is runner-centric. Without a consistent approach, implementers may fork schemas or skip checks in Phase 1, undermining the reuse goal.
  - **[Fix]:** Specify two modes within the *same* schema:
    - `governance_expected: { mode: "runner" | "interactive", expected_hash: ... }`
    - In Phase 1, Crumb itself computes and records the expected hash (still runner-side, but "runner" is the human-invoked processing script), and verifies post-run. Or explicitly scope: "Two-tier verification is mandatory for any automated invocation; Phase 1 interactive runs must still emit governance_hash + canary, but no pre-injected expected hash is required."

- **[F7]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: BT7 mitigations are good additions (kill-switch, runner rate limit), but they don't address the biggest consequence of Tess compromise: attacker can enqueue allowlisted but still high-impact operations (e.g., `start-task`, `invoke-skill`) repeatedly within limits, potentially causing harmful vault writes under valid governance.**
  - **[Why]:** Governance will faithfully execute allowed operations; compromise turns the bridge into an automation channel for adversarial-but-allowed actions. The current backstops are mostly "bounded blast radius" and "detectable afterward," not "prevent."
  - **[Fix]:** Add at least one of:
    - **Runner-side "requires-confirmation token"**: requests must include a `user_confirmation_token` generated only after Telegram CONFIRM, but Tess compromise can still generate it -- so instead generate it from a secret Tess doesn't have.
    - Practical variant: **primary-user signing**: a lightweight signer running as primary user generates a per-request signature/nonce that Tess cannot forge.
    - Most pragmatic: keep Phase 2 allowlist extremely narrow until you have a stronger auth boundary; explicitly mark `invoke-skill` as "deferred until Tess compromise mitigation v2".

- **[F8]**
  - **[Severity]: MINOR**
  - **[Finding]: `.processed-ids` idempotency log is mentioned, but retention/rotation and atomicity aren't specified; UUIDv7 collisions are negligible, but log corruption or concurrent writes could break idempotency.**
  - **[Why]:** In Phase 2 with automation, concurrent runner instances (e.g., file-watch firing twice) can race writing `.processed-ids`.
  - **[Fix]:** Specify atomic append with file lock, and rotation policy (e.g., keep last 10k IDs, or one file per month). Alternatively store processed IDs as filenames in `_openclaw/inbox/.processed/` and treat presence as the idempotency marker.

- **[F9]**
  - **[Severity]: MINOR**
  - **[Finding]: Transcript integrity: response includes `transcript_hash` and `transcript_path`, but there's no explicit verifier role (Tess? runner?) and no statement that Tess checks the hash against file contents before relaying.**
  - **[Why]:** BT4/BT7 discuss transcript poisoning; hashes help only if someone verifies.
  - **[Fix]:** Require: Tess (or runner) recomputes `sha256` of transcript file and compares to `transcript_hash` before sending "Transcript: ..." link/notice; if mismatch, raise alert.

- **[F10]**
  - **[Severity]: STRENGTH**
  - **[Finding]: BT6 package (JSON-in-echo hard requirement + hash-bound confirm + deterministic field filling + raw message preservation) is a solid improvement and addresses the R1 consensus concern without bloating the protocol.**
  - **[Why]:** It directly targets the real operational failure mode: "rubber-stamp on phone," especially with STT ambiguity, and it makes the confirmation step mechanically bound to the actual payload.
  - **[Fix]:** None required; tighten canonicalization (see F1) and add a UX note: for voice/STT, Tess should highlight `original_message` and any low-confidence fields before asking for confirmation.

- **[F11]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: The schema adds `schema_version: "1.0"` and new required fields, but no versioning/compat policy for Phase 1->Phase 2 reuse.**
  - **[Why]:** Without a policy, future changes can silently break Phase 1 tooling or Phase 2 runner expectations.
  - **[Fix]:** Add: "Strict version match required; unknown schema_version rejected," or "Semver-like: 1.x backward-compatible, 2.0 breaking," plus migration plan. Clarify which fields are mandatory vs optional by version.

- **[F12]**
  - **[Severity]: STRENGTH**
  - **[Finding]: Author Notes AN4/AN5 are asking the right questions; especially AN4 (pgrep vs lockfile) and AN5 (shared secret / extra auth boundary) point at the true remaining hard problems after R1.**

---

## Google Gemini 2.5 Pro

### F1
- **Severity**: SIGNIFICANT
- **Finding**: The proposed check for session concurrency (U7) using `pgrep` is vulnerable to a race condition (Time-of-Check-to-Time-of-Use, or TOCTOU).
- **Why**: The bridge runner script would check for an active process and then, finding none, start its own. In the small window between the check (`pgrep`) and the new session starting, the human user could start an interactive session. Both sessions would then run concurrently, leading to the exact database corruption or deadlock scenario U7 was created to prevent. `pgrep` is also fragile, as it depends on a specific process name that might change.
- **Fix**: Replace the `pgrep`-based check with a mandatory, system-wide lockfile mechanism.
    1.  Define a lockfile path (e.g., `~/.claude/session.lock`).
    2.  Both the interactive `claude` CLI and the bridge runner script **must** attempt to acquire an exclusive file lock (e.g., using `flock`) before starting a session.
    3.  If the lock cannot be acquired, the process must either queue the request (for the bridge runner) or exit with a "session in progress" message (for the interactive CLI), but not proceed. This provides a robust, race-free guarantee of single-session execution.

### F2
- **Severity**: SIGNIFICANT
- **Finding**: The mitigation for a compromised Tess (BT7) does not fully prevent a sophisticated attacker from bypassing the user confirmation loop. The author's question in AN5 correctly anticipates this gap.
- **Why**: If an attacker compromises the `openclaw` user context, they have direct write access to `_openclaw/inbox/`. They can craft a malicious-but-schema-valid request file and write it directly, completely bypassing the Telegram echo/confirm flow. The current schema allows them to forge the `confirmation` block by simply making `confirm_code` match the `payload_hash` they just calculated. Crumb would see a valid, "confirmed" request and process it without any user interaction. The kill-switch is a response mechanism, not a preventative one.
- **Fix**: Implement the shared secret authentication suggested in AN5.
    1.  Add a `signature` field to the Bridge Request schema.
    2.  Generate a strong shared secret, accessible to both the Tess skill and the bridge runner, but not world-readable.
    3.  Tess must compute an HMAC-SHA256 signature of the canonical JSON payload using the shared secret and include it in the `signature` field.
    4.  The bridge runner **must** re-compute the signature and verify it before processing any request from the inbox. A request with a missing or invalid signature is immediately rejected and logged as a potential compromise attempt.

### F3
- **Severity**: MINOR
- **Finding**: The canary string approach for detecting partial loading of `CLAUDE.md` is only effective for detecting terminal truncation.
- **Why**: Single canary at end doesn't detect middle-section drops during context loading.
- **Fix**: Use multiple strategically placed canaries (beginning, middle, end) with unique UUIDs. Runner verifies all three are present in the response.

### F4
- **Severity**: MINOR
- **Finding**: The specification relies on "canonical JSON" for hashing but doesn't define a test vector.
- **Why**: Tess (Node.js) and the Crumb runner (Python/Shell) might have different default JSON serialization behaviors. If their "canonical" representations differ, payload_hash will never match.
- **Fix**: Add a non-normative test vector section: example operation+params, exact canonical string, and resulting SHA256 hash.

### F5
- **Severity**: STRENGTH
- **Finding**: The R1 changes are highly consistent and well-integrated across different parts of the specification.
- **Why**: Introduction of `payload_hash` is correctly reflected in threat model, protocol schema, and confirmation flow. Two-tier governance verification is tied to response schema and BT3. Systematic application of review feedback.

### F6
- **Severity**: STRENGTH
- **Finding**: Author Notes AN4/AN5 demonstrate a mature security mindset by asking precisely the right follow-up questions.
- **Why**: Author correctly identified pgrep weakness and Tess compromise bypass vector. Self-critique shows spec owner understands limitations and is actively seeking to harden.

---

## Perplexity Sonar Reasoning Pro

**FAILED:** Sonar Reasoning Pro performed a web search instead of reviewing the artifact content. Returned a 15-line response explaining it could not review the specification because its search results (circuit simulators, food processing equipment, privacy policies) were irrelevant. This is a known failure mode where Sonar prioritizes web search over in-context analysis.

---

## Synthesis

### Consensus Findings

**1. U7 Session Concurrency: `pgrep` is insufficient, needs lockfile (OAI-F5 + GEM-F1)**
Both reviewers independently identified the TOCTOU race condition in the `pgrep`-based session detection. Both recommend `flock`-based lockfile as the primary mechanism with `pgrep` as advisory. This is the strongest consensus finding in R2.

**2. BT7 Bypass: Compromised Tess can forge confirmation and inject directly to inbox (OAI-F7 + GEM-F2)**
Both reviewers flagged that a compromised `openclaw` user can write schema-valid requests directly to inbox, forge the `confirmation` block (since `confirm_code` is just `payload_hash` which is computable from the payload), and bypass the echo/confirm flow entirely. Both recommend some form of shared-secret authentication between Tess and the runner.

**3. Canonical JSON needs normative specification (OAI-F1 + GEM-F4)**
Both reviewers noted that "canonical JSON" is underspecified for cross-implementation hashing. Node.js (Tess) and Python/Shell (runner/Crumb) may serialize differently. OAI recommends RFC 8785 (JCS) or explicit rules; GEM recommends test vectors.

**4. Multiple canaries for partial-load detection (OAI-F4 + GEM-F3)**
Both reviewers noted the single end-of-file canary misses middle-section drops. Both recommend multiple strategically placed canaries.

**5. AN4/AN5 are well-targeted (OAI-F12 + GEM-F6)**
Both reviewers praised the author notes as asking exactly the right questions.

### Unique Findings

**OAI-F2: "Tess NEVER interprets intent" vs NLU extraction tension** — Genuine insight. The governance model says Tess never interprets intent, but BT6 assumes NLU extraction. These need reconciling. The suggested "classify + hard-stop on ambiguity" reframing is practical.

**OAI-F3: BT3 governance hash circularity** — Genuine insight. The runner injects a hash and checks the response contains it, but the model can just echo the injected value without actually reading CLAUDE.md. The canary is the real check, but it's also model-reported. This is a real weakness in the two-tier model — the "external" tier is partially circular.

**OAI-F6: Phase 1/Phase 2 protocol reuse vs runner-centric BT3** — Genuine insight. BT3's governance verification is runner-centric, but Phase 1 has no runner. The spec should clarify that two-tier verification is mandatory for automated invocations only, and Phase 1 interactive runs emit governance_hash but don't require pre-injected expected hash.

**OAI-F8: .processed-ids retention/atomicity** — Genuine but minor. Good to specify but not blocking.

**OAI-F9: Transcript hash verifier role** — Genuine. Hashes without a verifier are security theater. Should specify who verifies.

**OAI-F11: Schema versioning policy** — Genuine. `schema_version` without a compat policy creates ambiguity.

### Contradictions

None. Both reviewers are largely aligned on findings. Where they overlap, they propose compatible solutions (lockfile, shared secret, canonical JSON spec, multiple canaries).

### Action Items

#### Must-Fix

**A1. Specify lockfile-based session concurrency control (U7)**
*Sources: OAI-F5, GEM-F1*
Replace `pgrep`-based detection with `flock`-based lockfile (`~/.crumb/bridge_runner.lock`) as primary mechanism. Keep `pgrep` as advisory for detecting interactive sessions that don't use the lockfile. Update U7 text.

**~~A2. Add shared-secret authentication between Tess and runner (BT7 bypass prevention)~~**
*Sources: OAI-F7, GEM-F2*
~~Add HMAC-SHA256 `signature` field to bridge request schema.~~
**DECLINED by user.** Reasoning: HMAC requires a shared secret accessible to both Tess and the runner. If Tess is compromised (the BT7 scenario), the attacker has the signing key — so HMAC doesn't solve the stated threat. The HMAC would protect against a third party writing to inbox, but filesystem permissions already prevent that (`_openclaw/inbox/` is writable only by the `openclaw` user). The real BT7 mitigations are: operation allowlist + Crumb's governance verification + rate limiting + kill-switch. Adding HMAC is complexity without additive security.

**A3. Define canonical JSON normatively with test vector**
*Sources: OAI-F1, GEM-F4*
Specify: canonical input is `{ "operation": ..., "params": ... }` only. Sorted keys, ASCII-only values (reject non-ASCII with validation error), no insignificant whitespace, UTF-8 encoding. Reference RFC 8785 or provide explicit rules. Add a test vector section.

#### Should-Fix

**A4. Reconcile "Tess NEVER interprets intent" with NLU extraction** → DEFERRED
*Source: OAI-F2*
Rephrase governance principle to: "Tess may classify messages into allowlisted operations and fill parameters, but must treat any ambiguity as a hard stop." Add NLU policy subsection with disambiguation requirements.
*User decision: Deferred to implementation — wording polish, address during CTB-004 skill design.*

**A5. Clarify BT3 governance verification circularity** → APPLIED
*Source: OAI-F3*
The runner-injected hash check was partially circular. Fixed: runner now injects only a nonce; session must return `governance_canary` (last 64 bytes of CLAUDE.md) — non-echoable. Runner verifies byte-for-byte.

**A6. Clarify Phase 1/Phase 2 governance verification scoping** → APPLIED
*Source: OAI-F6*
Added: two-tier verification mandatory for automated invocations (Phase 2+). Phase 1 interactive runs emit `governance_hash` and `governance_canary` for protocol consistency but no automated runner enforces them.

**A7. Add multiple canaries for partial-load detection** → DEFERRED
*Sources: OAI-F4, GEM-F3*
Place canary strings at ~33%, ~66%, and ~100% of CLAUDE.md. Runner verifies all three in session response.
*User decision: Deferred — over-engineering at this stage. Single canary (last 64 bytes) is sufficient given CLAUDE.md's current size.*

**A8. Add schema versioning/compatibility policy** → DEFERRED
*Source: OAI-F11*
Specify: strict version match required; unknown `schema_version` rejected. Or semver: `1.x` backward-compatible, `2.0` breaking.
*User decision: Deferred — matters more when there are multiple schema consumers. Address during Phase 2 implementation.*

#### Defer

**A9. Specify .processed-ids retention and atomicity**
*Source: OAI-F8*
Implementation detail. Specify during CTB-005 implementation: atomic append with file lock, monthly rotation or treat `.processed/` directory filenames as idempotency markers.

**A10. Specify transcript hash verifier role**
*Source: OAI-F9*
Implementation detail for Phase 2. Runner should verify `transcript_hash` before Tess relays. Specify during CTB-011.

**A11. Add voice/STT UX note to BT6**
*Source: OAI-F10 (strength finding with UX suggestion)*
For voice input, Tess should highlight `original_message` and any low-confidence fields in the echo. Specify during CTB-004 skill design.

### Considered and Declined

**A2: HMAC-SHA256 shared-secret authentication (OAI-F7 + GEM-F2)**
*Reason: constraint.* User declined. The shared secret must be readable by the `openclaw` user (for Tess to sign), so a compromised Tess has the signing key — HMAC is circular under the BT7 threat model. Third-party inbox writes are already prevented by filesystem permissions. The real BT7 mitigations are operation allowlist + governance verification + rate limiting + kill-switch.

**OAI-F7 (partial): Primary-user signing / per-request nonce from watcher**
*Reason: overkill.* Same circularity problem as A2 — if the signing mechanism is accessible to any component that could be compromised, it doesn't add a layer.

**OAI-F7 (partial): Defer `invoke-skill` until "Tess compromise mitigation v2"**
*Reason: constraint.* The phased approach already limits Phase 1 to approvals + status queries. Phase 2's `invoke-skill` is gated behind Phase 1 validation + multiple unknowns. The operation allowlist + governance is the boundary, not message-level auth.
