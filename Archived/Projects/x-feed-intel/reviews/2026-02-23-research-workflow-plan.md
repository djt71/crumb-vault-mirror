---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: ~/.claude/plans/composed-growing-allen.md
artifact_type: plan
artifact_lines: 152
project: x-feed-intel
domain: software
skill_origin: peer-review
created: 2026-02-23
updated: 2026-02-23
status: active
reviewers:
  - provider: openai
    model: gpt-5.2-2025-12-11
  - provider: google
    model: gemini-3-pro-preview
  - provider: deepseek
    model: deepseek-reasoner
  - provider: grok
    model: grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
  retry_on: [429, 500, 502, 503]
  backoff_seconds: [2, 5]
safety_gate:
  result: clean
  hard_denylist_hits: 0
  soft_warnings: 0
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 49700
    attempts: 1
    model_resolved: gpt-5.2-2025-12-11
    system_fingerprint: null
    usage:
      prompt_tokens: 2369
      completion_tokens: 2882
      total_tokens: 5251
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-research-workflow-plan-openai.json
  google:
    http_status: 200
    latency_ms: 37000
    attempts: 1
    model_resolved: gemini-3-pro-preview
    system_fingerprint: n/a
    usage:
      prompt_tokens: 2575
      completion_tokens: 1446
      thought_tokens: 2111
      total_tokens: 6132
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-research-workflow-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 53100
    attempts: 1
    model_resolved: deepseek-reasoner
    system_fingerprint: fp_eaab8d114b_prod0820_fp8_kvcache
    usage:
      prompt_tokens: 2460
      completion_tokens: 2676
      reasoning_tokens: 1477
      total_tokens: 5136
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-research-workflow-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 25300
    attempts: 1
    model_resolved: grok-4-1-fast-reasoning
    system_fingerprint: fp_7b535da9e1
    usage:
      prompt_tokens: 2569
      completion_tokens: 1212
      reasoning_tokens: 885
      total_tokens: 4666
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-research-workflow-plan-grok.json
    notes: "Initial urllib dispatch hit Cloudflare 403 (error 1010); retried with curl - succeeded."
tags: [review, peer-review]
---

# Peer Review: Research Workflow — Dispatch Integration Plan

**Artifact:** Research Workflow: Dispatch Integration Plan (bridge dispatch for `{ID} research` command)
**Review mode:** full | **Round:** 1 | **Reviewers:** 4/4 succeeded

**Finding counts:**
| Reviewer | CRITICAL | SIGNIFICANT | MINOR | STRENGTH | Total |
|----------|----------|-------------|-------|----------|-------|
| OpenAI (gpt-5.2) | 2 | 13 | 3 | 2 | 20 |
| Google (gemini-3-pro) | 0 | 3 | 1 | 2 | 6 |
| DeepSeek (reasoner) | 1 | 3 | 3 | 3 | 10 |
| Grok (4-1-fast) | 1 | 5 | 3 | 1 | 10 |

---

## OpenAI — gpt-5.2

- **[OAI-F1]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Using `quick-fix` for "research" is a semantic mismatch — agent assumes code-change workflow**
  - **[Why]:** The bridge's operation name and downstream agent prompts shape behavior. "quick-fix" implies modifying a repo; "research" is a skill/job that produces an artifact and summary. Mismatch increases brittleness and makes future policy/guardrails harder.
  - **[Fix]:** Prefer `invoke-skill` with a `research` (or `feed-intel-research`) skill. If shipping now with no bridge changes, tighten `description` to explicitly forbid code changes.

- **[OAI-F2]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Plan effectively encodes a "skill" in prompt text without versioning or reuse**
  - **[Why]:** Prompt-encoded workflows drift over time, are hard to test deterministically, and have a larger prompt injection surface compared to a named skill with a stable interface.
  - **[Fix]:** Move the research procedure into an `invoke-skill` target as soon as feasible.

- **[OAI-F3]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Self-signing confirmation provides integrity-of-payload but not authenticity**
  - **[Why]:** Any process that can write to the inbox can compute the same hash. If confirmation is only write-intent checksum, that's fine; if it's a security boundary, it isn't.
  - **[Fix]:** Clarify threat model. For authenticity, use HMAC with shared secret. For checksum-only, document explicitly as non-security.

- **[OAI-F4]**
  - **[Severity]: CRITICAL**
  - **[Finding]: `payloadHash` truncation to first 12 hex chars may be incompatible with bridge SHA-256 expectations**
  - **[Why]:** If bridge validator expects full 64-char hex digest, truncation fails validation. 48-bit hashes increase collision risk.
  - **[Fix]:** Use full SHA-256 hex (64 chars) unless schema explicitly specifies truncation length.

- **[OAI-F5]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: "Canonical JSON" rules underspecified — recursive key sorting, number formatting, escaping**
  - **[Why]:** If bridge-side canonicalization differs, confirmations will fail intermittently.
  - **[Fix]:** Align exactly with bridge's documented algorithm. Add golden test vector from bridge docs.

- **[OAI-F6]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: ASCII sanitization by "strip non-ASCII" destroys meaning for X/Twitter content**
  - **[Why]:** Research quality depends on preserving key entities (product names, non-English terms). Can also mangle URLs with Unicode.
  - **[Fix]:** Prefer transliteration (NFKD + remove diacritics). Store full text in investigate file; reference by path so agent reads from disk.

- **[OAI-F7]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: `context` max 2000 chars + silent truncation risks cutting critical parts (URLs, code, claims)**
  - **[Why]:** Silent truncation can lead to wrong research direction and poor reproducibility.
  - **[Fix]:** Add truncation markers. Prioritize: canonical link, author, timestamp, core text. Put full text in investigate file.

- **[OAI-F8]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Polling for outbox response file assumes fixed naming convention and atomicity**
  - **[Why]:** If bridge writes partial files or uses different filenames, existence checks misfire.
  - **[Fix]:** Confirm exact outbox contract. Implement glob by dispatch_id prefix + JSON-parse with retry on parse failure.

- **[OAI-F9]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Completion polling inside main Telegram loop can cause head-of-line blocking**
  - **[Why]:** Scanning many pending items each tick degrades Telegram responsiveness.
  - **[Fix]:** Move polling to separate interval/task with bounded work per tick, or add backoff per dispatch_id and cap checks per cycle.

- **[OAI-F10]**
  - **[Severity]: CRITICAL**
  - **[Finding]: Race conditions around investigate frontmatter + dispatch writing not addressed**
  - **[Why]:** Double-dispatch on duplicate commands, partial writes on restart, concurrent edits from bridge/agent + listener on same investigate file.
  - **[Fix]:** Atomic writes (temp+rename). File lock per investigate ID. Define single-writer policy — either listener or agent updates frontmatter, not both.

- **[OAI-F11]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: No idempotency if response arrives but Telegram notification fails**
  - **[Why]:** Users may never get notified, or may get duplicate notifications on restart.
  - **[Fix]:** Record `notified_at` in frontmatter. On restart, send notification only if completed and not notified.

- **[OAI-F12]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Error handling underspecified — what constitutes "error" in response, safe detail level for Telegram**
  - **[Why]:** Need consistent user messaging and diagnostics without leaking internal paths/prompts.
  - **[Fix]:** Define minimal error schema mapping. Store full details in local log; send short Telegram message with dispatch_id.

- **[OAI-F13]**
  - **[Severity]: MINOR**
  - **[Finding]: Budget parameters (5 stages, 50 tool calls, 300s) may be tight for web research tasks**
  - **[Why]:** Timeouts look like flaky behavior to users.
  - **[Fix]:** Start with 600s or make budget configurable. Keep 300s but instruct agent to fail fast with partial results.

- **[OAI-F14]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Dispatch `description` instructs agent to "Update investigate file status to complete" — conflicts with listener also updating**
  - **[Why]:** Two actors editing same state leads to lost updates and inconsistent status.
  - **[Fix]:** Choose one: (a) agent writes only research output + response summary, listener updates investigate status (preferred for trust boundaries), or (b) agent updates investigate, listener only notifies.

- **[OAI-F15]**
  - **[Severity]: MINOR**
  - **[Finding]: `source.sender_id` as integer — Telegram chat IDs can exceed 32-bit and be negative**
  - **[Why]:** Incorrect typing can break schema validation.
  - **[Fix]:** Ensure schema allows 64-bit integer or string. Validate safe range.

- **[OAI-F16]**
  - **[Severity]: STRENGTH**
  - **[Finding]: Good attention to operational constraints (ASCII-only, confirmation, max context, UUIDv7, schema version)**
  - **[Why]:** These are typical integration failure points; calling them out early reduces churn.

- **[OAI-F17]**
  - **[Severity]: STRENGTH**
  - **[Finding]: Restart recovery via scanning investigate files with `status: pending` + `dispatch_id` is pragmatic**
  - **[Why]:** For a file-based workflow, simpler and more robust than introducing a DB prematurely.

- **[OAI-F18]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Frontmatter-as-state lacks schema/versioning and migration strategy**
  - **[Why]:** As fields evolve, older files may break parsing or recovery logic.
  - **[Fix]:** Define minimal frontmatter schema with defaults. Make parsing tolerant.

- **[OAI-F19]**
  - **[Severity]: MINOR**
  - **[Finding]: Node.js lacks native UUIDv7 — rolling your own is easy to get wrong**
  - **[Why]:** Incorrect UUIDv7 could fail schema validation or sorting assumptions.
  - **[Fix]:** Copy a well-reviewed implementation and add property-based tests (monotonicity, variant/version bits).

- **[OAI-F20]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Security/prompt-injection — X post text is untrusted input embedded into agent instructions**
  - **[Why]:** Malicious post could instruct agent to exfiltrate secrets, modify unrelated files, or spam Telegram.
  - **[Fix]:** Strongly delimit untrusted content (UNTRUSTED QUOTE START/END), instruct agent to treat as data, restrict writable paths to two feed files.

---

## Google — gemini-3-pro-preview

- **[GEM-F1]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Including non-existent output file in `quick-fix` "files" array may cause bridge ENOENT error**
  - **[Why]:** The research output path doesn't exist yet (agent creates it). Bridge file-reading logic may throw before agent spawns.
  - **[Fix]:** Only include the existing investigate file in `files`. Specify output path in `description` text.

- **[GEM-F2]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Aggressive ASCII sanitization causes semantic data loss (emojis, foreign scripts, symbols)**
  - **[Why]:** X posts rely on emojis/symbols for meaning. Stripping turns "I heart this tool" into "I this tool".
  - **[Fix]:** Implement transliteration (emojis to text descriptions). Rely on investigate file for full UTF-8 content that agent reads from disk.

- **[GEM-F3]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: No timeout or "zombie" dispatch handling in polling loop**
  - **[Why]:** If bridge crashes or agent fails to write response, listener polls that ID forever — memory leak in `pendingResearch` Map and stuck `status: pending`.
  - **[Fix]:** Implement timeout (e.g., 15 minutes). Mark as `status: timeout`, send failure notification, remove from map.

- **[GEM-F4]**
  - **[Severity]: MINOR**
  - **[Finding]: Potential integer precision issues with Telegram Chat IDs in JSON**
  - **[Why]:** Chat IDs can exceed 2^31. Some parsers may treat integers strictly.
  - **[Fix]:** Verify bridge schema accepts 64-bit integers or strings for IDs.

- **[GEM-F5]**
  - **[Severity]: STRENGTH**
  - **[Finding]: Robust restart recovery strategy**
  - **[Why]:** Explicit handling of daemon restarts by scanning investigate files with `status: pending` + `dispatch_id`.

- **[GEM-F6]**
  - **[Severity]: STRENGTH**
  - **[Finding]: Zero-dependency implementation of `bridge-request.ts`**
  - **[Why]:** Using only Node.js built-ins prevents tight coupling between feedback listener and bridge logic.

---

## DeepSeek — deepseek-reasoner

- **[DS-F1]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Repurposing `quick-fix` for research violates semantic clarity and may confuse bridge routing/logging**
  - **[Why]:** Using operation outside intended purpose can cause unexpected behavior if future changes assume quick-fix is code-only.
  - **[Fix]:** Create new operation (e.g., `conduct-research`) or use `invoke-skill` with dedicated skill. Document deviation if repurposing.

- **[DS-F2]**
  - **[Severity]: STRENGTH**
  - **[Finding]: Self-signing confirmation is architecturally sound for machine-initiated requests**
  - **[Why]:** Satisfies bridge confirmation requirement without human intervention, maintains integrity via hash.

- **[DS-F3]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: ASCII sanitization may discard meaningful content (emojis, non-Latin scripts)**
  - **[Why]:** Research context loses nuance, reducing agent effectiveness.
  - **[Fix]:** Implement transliteration or substitution for common Unicode. Consider fallback summary for long posts.

- **[DS-F4]**
  - **[Severity]: MINOR**
  - **[Finding]: Polling in main loop acceptable but may introduce latency at scale**
  - **[Why]:** For low-volume personal system, polling is simple. Could block Telegram updates during filesystem scans.
  - **[Fix]:** Move to separate async worker or use filesystem events if performance becomes issue.

- **[DS-F5]**
  - **[Severity]: MINOR**
  - **[Finding]: Budget parameters reasonable for initial tasks but may be too restrictive for complex inquiries**
  - **[Why]:** Overly tight budgets prematurely cut off research.
  - **[Fix]:** Start with these values, implement monitoring, adjust based on usage patterns.

- **[DS-F6]**
  - **[Severity]: CRITICAL**
  - **[Finding]: Race conditions and failure modes inadequately addressed — missing completions, no timeout, concurrent file corruption**
  - **[Why]:** Bridge may write response before `pendingResearch` populated. No timeout for failed requests. Concurrent file updates risk corruption.
  - **[Fix]:** Atomic filesystem operations. Add timeout (1 hour). Populate `pendingResearch` before writing dispatch request.

- **[DS-F7]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Investigate file frontmatter tracking lacks transactional safety**
  - **[Why]:** No locking mechanism for concurrent frontmatter updates.
  - **[Fix]:** Introduce lock file or atomic write procedure. Consider SQLite if complexity grows.

- **[DS-F8]**
  - **[Severity]: STRENGTH**
  - **[Finding]: Comprehensive verification plan covering unit, integration, and live tests**
  - **[Why]:** Reduces deployment risk and ensures schema compliance.

- **[DS-F9]**
  - **[Severity]: STRENGTH**
  - **[Finding]: Design leverages existing infrastructure without modifying core systems**
  - **[Why]:** Changes isolated to feedback listener, promoting stability.

- **[DS-F10]**
  - **[Severity]: MINOR**
  - **[Finding]: `context` truncation strategy unspecified (word vs char boundary)**
  - **[Why]:** Arbitrary truncation could cut mid-sentence.
  - **[Fix]:** Truncate at word boundaries, append ellipsis, log warnings.

---

## Grok — grok-4-1-fast-reasoning

- **[GRK-F1]**
  - **[Severity]: CRITICAL**
  - **[Finding]: Repurposing `quick-fix` for research mismatches operation purpose — Crumb quick-fix logic likely assumes code editing context**
  - **[Why]:** Agent may misinterpret instructions (parsing project files for diffs) leading to incomplete outputs or errors. `invoke-skill` exists for custom tasks.
  - **[Fix]:** Switch to `invoke-skill` with `skill: "research"` or propose a new `research` operation. Validate against bridge schema docs.

- **[GRK-F2]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Self-signing bypasses intended human-confirmation flow without justifying bridge trust in machine writes**
  - **[Why]:** Security risk if bridge inbox writable by untrusted processes. Bridge expects confirmation codes from Telegram echoes.
  - **[Fix]:** Add machine-specific `source: "internal"` flag or implement HMAC with shared secret.

- **[GRK-F3]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: ASCII sanitization loses critical content from X/Twitter posts**
  - **[Why]:** Emojis signal sentiment, unicode for brands/terms. Data loss distorts research analysis.
  - **[Fix]:** Base64-encode full post text, or extend sanitizer to preserve via \u escapes. Test with real Twitter posts.

- **[GRK-F4]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Completion polling in main loop mixes responsibilities and risks performance degradation**
  - **[Why]:** Telegram polling has rate limits/timing sensitivity. Added research checks could delay updates.
  - **[Fix]:** Spawn separate watcher process (e.g., chokidar on outbox) or keep listener focused on Telegram I/O.

- **[GRK-F5]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Multiple race conditions unaddressed — concurrent commands, dispatch write failures, partial outbox writes**
  - **[Why]:** Duplicate dispatches waste resources. No atomicity guarantee on frontmatter updates. Premature response notification if JSON write incomplete.
  - **[Fix]:** File locks for investigate/dispatch writes. Idempotency via dispatch_id uniqueness check. Full JSON parse + status validation before acting.

- **[GRK-F6]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: No timeout or failure recovery for stalled dispatches**
  - **[Why]:** Orphaned pendingResearch entries block loop. Users get no feedback on hung tasks.
  - **[Fix]:** Add dispatch_sent age check (>1hr -> error notify + status:error). Exponential backoff poll interval.

- **[GRK-F7]**
  - **[Severity]: MINOR**
  - **[Finding]: Budget params lack justification or tuning for web research variability**
  - **[Why]:** Fixed values risk truncation or overspend.
  - **[Fix]:** Make dynamic based on post length/priority. Test empirically. Document rationale.

- **[GRK-F8]**
  - **[Severity]: MINOR**
  - **[Finding]: Investigate file frontmatter is file-system coupled, brittle for scale**
  - **[Why]:** No transactions across files. Manual YAML parsing risks format errors.
  - **[Fix]:** Acceptable short-term. Add schema validation. Migrate path to SQLite if complexity grows.

- **[GRK-F9]**
  - **[Severity]: MINOR**
  - **[Finding]: Dispatch request includes undocumented fields (`original_message`, `source`) not in listed schema constraints**
  - **[Why]:** Bridge schema validator may reject extras.
  - **[Fix]:** Confirm schema allows extensions or remove. Add to verification step.

- **[GRK-F10]**
  - **[Severity]: STRENGTH**
  - **[Finding]: Comprehensive verification plan covers key paths including restart recovery and duplicates**
  - **[Why]:** Reduces deployment risk. Idempotency and atomic write patterns prevent common pitfalls.

---

## Synthesis

### Consensus Findings

**1. Operation choice: quick-fix is a semantic mismatch (4/4)**
OAI-F1, OAI-F2, DS-F1, GRK-F1. All four reviewers flag `quick-fix` as the wrong operation for research tasks. The operation name shapes downstream agent behavior — "quick-fix" implies code changes, not web research + summary writing. Three reviewers recommend `invoke-skill`; one suggests a new operation.

**2. ASCII sanitization destroys meaning (4/4)**
OAI-F6, GEM-F2, DS-F3, GRK-F3. Unanimous that stripping non-ASCII characters from X/Twitter posts loses critical semantic content (emojis, non-Latin scripts, brand symbols). All recommend transliteration or storing full text in the investigate file for agent to read from disk rather than embedding in the ASCII-constrained `context` field.

**3. Race conditions and failure modes inadequately addressed (3/4)**
OAI-F10, DS-F6, GRK-F5. Missing: duplicate dispatch prevention, atomic writes, concurrent frontmatter edits (both agent and listener update investigate file), partial outbox write detection.

**4. No timeout for stalled dispatches (3/4)**
OAI-F9 (head-of-line blocking), GEM-F3 (zombie dispatches), GRK-F6 (no failure recovery). If bridge crashes or agent fails, `pendingResearch` grows unbounded and investigate files stay `status: pending` forever. All recommend a timeout mechanism (15 min to 1 hour) with cleanup and error notification.

**5. Dual-writer conflict on investigate file (2/4)**
OAI-F14 plus implied by OAI-F10 and DS-F6. The `description` instructs the agent to "Update investigate file status to complete," but the listener also updates status on completion detection. Two writers on the same file = lost updates.

**6. Self-signing confirmation: mixed assessment (split)**
OAI-F3 (significant — not authenticity), GRK-F2 (significant — bypasses human confirmation), DS-F2 (strength — architecturally sound). The assessment depends on threat model. For a personal OS with trusted components, self-signing is adequate as an integrity check. Not a security boundary.

### Unique Findings

**OAI-F4 (CRITICAL): Payload hash truncation to 12 hex chars.** Only OpenAI flagged this. If bridge expects full 64-char SHA-256, truncation breaks validation. Must verify against bridge schema.

**OAI-F20: Prompt injection from untrusted X post text.** Only OpenAI raised the security concern of embedding untrusted social media content directly into agent instructions. Recommends explicit UNTRUSTED delimiters and restricting writable paths.

**OAI-F18: Frontmatter-as-state lacks versioning.** As fields evolve, parsing/recovery logic may break on older files without defaults.

**OAI-F11: Notification idempotency.** If response arrives but Telegram notification fails, need `notified_at` field to prevent missed or duplicate notifications on restart.

**GEM-F1: Non-existent output file in `files` array.** The research output path doesn't exist when dispatch is written — bridge may ENOENT trying to read it before spawning agent.

**GEM-F6: Zero-dependency implementation.** Only Gemini praised the decision to use Node.js builtins only, preventing tight coupling with bridge source.

**GRK-F9: Undocumented fields in dispatch request.** `original_message` and `source` not mentioned in the listed schema constraints. Bridge validator may reject.

### Contradictions

**Self-signing confirmation:** DeepSeek rates it as a STRENGTH (architecturally sound for machine-initiated requests). OpenAI and Grok rate it as SIGNIFICANT issues (no authenticity / bypasses human confirmation). Resolution: depends on threat model. For a personal OS where the feedback listener is a trusted component, self-signing is adequate integrity verification, not a security boundary. Document this explicitly.

**Polling approach:** DeepSeek and Gemini accept polling in the main loop for a low-volume personal system. OpenAI and Grok flag head-of-line blocking and recommend separation. Resolution: polling is acceptable for Phase 1 given single-user low-volume operation, but add bounded work per tick and timeout to prevent unbounded growth.

### Action Items

**Must-fix (blocking for implementation):**

| ID | Finding sources | Action |
|----|----------------|--------|
| A1 | OAI-F4 | **Verify payload hash length against bridge schema.** If bridge expects full 64-char SHA-256 hex, do not truncate to 12. Check bridge-schema.md `payload_hash` specification. |
| A2 | OAI-F10, DS-F6, GRK-F5 | **Define single-writer policy for investigate file.** Either listener or agent updates investigate frontmatter, not both. Recommended: agent writes only research output file; listener manages all investigate file state transitions. Remove "Update investigate file status to complete" from dispatch description. |
| A3 | OAI-F14 | **Remove duplicate state update from dispatch description.** The `description` field should instruct the agent to write research summary only. Listener handles investigate file status on completion detection. |
| A4 | GEM-F3, GRK-F6 | **Add timeout for stalled dispatches.** Check `dispatch_sent` age in poll loop. After timeout (e.g., 15 min), mark `status: timeout`, send error notification, remove from `pendingResearch`. |

**Should-fix (improve correctness before production):**

| ID | Finding sources | Action |
|----|----------------|--------|
| A5 | OAI-F1, OAI-F2, DS-F1, GRK-F1 | **Consider invoke-skill instead of quick-fix.** If quick-fix semantics are used, tighten description to explicitly forbid code changes. Plan migration to invoke-skill with a dedicated research skill. |
| A6 | OAI-F6, GEM-F2, DS-F3, GRK-F3 | **Improve ASCII sanitization.** Implement transliteration for common Unicode (emojis to text, smart quotes to ASCII). Store full UTF-8 text in investigate file and reference by path for agent to read. |
| A7 | GEM-F1 | **Remove non-existent output file from `files` array.** Only include the existing investigate file path. Specify output path in `description` text. |
| A8 | OAI-F11 | **Add notification idempotency.** Record `notified_at` in investigate frontmatter. On restart recovery, only send notification if completed and not yet notified. |
| A9 | OAI-F5 | **Align canonical JSON with bridge implementation.** Add golden test vector from bridge docs. Ensure recursive key sorting and consistent escaping. |
| A10 | OAI-F20 | **Delimit untrusted content in dispatch description.** Wrap post text in explicit UNTRUSTED markers. Instruct agent to treat as data. Consider restricting writable paths in budget/context. |
| A11 | OAI-F8 | **Verify outbox contract.** Confirm exact response filename pattern, atomic rename behavior, and terminal status field. Implement JSON-parse with retry on parse failure. |
| A12 | GRK-F9 | **Verify bridge schema allows `original_message` and `source` fields.** If schema rejects extensions, remove or move to metadata field. |

**Defer (acceptable for Phase 1):**

| ID | Finding sources | Action |
|----|----------------|--------|
| A13 | OAI-F13, DS-F5, GRK-F7 | **Budget tuning.** Start with plan values (5/50/300s), adjust based on actual research task telemetry. Consider raising wall_time to 600s if timeouts appear. |
| A14 | OAI-F3, GRK-F2 | **Self-signing threat model documentation.** Document that confirm_code = payload_hash is integrity verification, not authentication. Acceptable for trusted-component architecture. |
| A15 | OAI-F18 | **Frontmatter schema versioning.** Add tolerant parsing with defaults for missing fields. Add `frontmatter_version` when fields expand. |
| A16 | OAI-F15, GEM-F4 | **Telegram chat ID integer precision.** Verify bridge schema accepts 64-bit integers. Low urgency — personal bot uses positive chat ID within safe range. |
| A17 | OAI-F19 | **UUIDv7 implementation validation.** Use well-reviewed implementation. Add property-based tests for monotonicity and version bits. |
| A18 | OAI-F7, DS-F10 | **Truncation strategy.** Truncate at word boundaries, add ellipsis marker, log warnings when truncation occurs. |
| A19 | DS-F7, GRK-F8 | **Frontmatter file locking.** Acceptable without locks for Phase 1 (single-writer policy from A2 eliminates concurrent access). Add if multi-writer scenario emerges. |

### Considered and Declined

| Finding | Reason | Category |
|---------|--------|----------|
| DS-F4 (polling latency at scale) | Personal single-user system. Polling is simpler than fs.watch for Phase 1 | constraint |
| DS-F2 (self-signing is a STRENGTH) | Split assessment — treated as a threat model documentation item (A14), not dismissed | noted |
| OAI-F9 (head-of-line blocking) | Addressed by A4 (timeout + bounded work). Full separation deferred to scale needs | addressed |

### Reviewer Calibration Notes

- **OpenAI (GPT-5.2):** Most thorough (20 findings). Strong on security concerns (prompt injection, authenticity, hash truncation). Only reviewer to flag payload hash truncation as CRITICAL. F4 may be the most impactful finding if bridge rejects truncated hashes. Low noise.
- **Google (Gemini 3 Pro):** Fewest findings (6) but high signal density. GEM-F1 (non-existent file in files array) is a unique practical insight that could cause immediate failure. Clean reviewer, concise answers to each review question.
- **DeepSeek (V3.2-Thinking):** Balanced review (10 findings). Race condition finding (DS-F6) is well-structured with clear ordering concern (populate pendingResearch before writing dispatch). Self-signing rated as STRENGTH — useful counterpoint to OAI/GRK assessment. 1477 reasoning tokens used.
- **Grok (4-1 Fast):** 10 findings, 90% issues (9/10) — prompt addendum continuing to work well. GRK-F1 goes further than other reviewers by claiming Crumb's quick-fix logic "likely assumes code editing context" — UNVERIFIABLE CLAIM without seeing bridge handler code. GRK-F9 (undocumented fields) is a unique practical insight. Cheapest reviewer at ~$0.02.
