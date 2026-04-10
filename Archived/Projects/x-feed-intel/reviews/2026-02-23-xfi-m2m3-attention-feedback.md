---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: ~/openclaw/x-feed-intel/src/{attention/,feedback/,shared/cost-telemetry.ts,shared/db.ts}
artifact_type: code
artifact_lines: 4720
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
  - provider: perplexity
    model: sonar-reasoning-pro
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
    latency_ms: 50434
    attempts: 1
    model_resolved: gpt-5.2-2025-12-11
    system_fingerprint: null
    usage:
      prompt_tokens: 41390
      completion_tokens: 3395
      total_tokens: 44785
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-xfi-m2m3-attention-feedback-openai.json
  google:
    http_status: 200
    latency_ms: 72876
    attempts: 1
    model_resolved: gemini-3-pro-preview
    system_fingerprint: n/a
    usage:
      prompt_tokens: 48597
      completion_tokens: 1188
      thought_tokens: 5805
      total_tokens: 55590
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-xfi-m2m3-attention-feedback-google.json
  deepseek:
    http_status: 200
    latency_ms: 44300
    attempts: 2
    model_resolved: deepseek-reasoner
    system_fingerprint: fp_eaab8d114b_prod0820_fp8_kvcache
    usage:
      prompt_tokens: 43786
      completion_tokens: 2128
      reasoning_tokens: 320
      total_tokens: 45914
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-xfi-m2m3-attention-feedback-deepseek.json
    notes: "Initial dispatch returned empty body (curl -w split issue); succeeded on retry with -o flag"
  grok:
    http_status: 200
    latency_ms: 29321
    attempts: 1
    model_resolved: grok-4-1-fast-reasoning
    system_fingerprint: fp_7b535da9e1
    usage:
      prompt_tokens: 41155
      completion_tokens: 2082
      reasoning_tokens: 1895
      total_tokens: 45132
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-xfi-m2m3-attention-feedback-grok.json
  perplexity:
    http_status: manual
    latency_ms: manual
    attempts: 1
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-xfi-m2m3-attention-feedback-perplexity.md
    notes: "Manual submission via claude.ai. 4/17 findings hallucinated, 2 misreadings."
tags: [review, peer-review]
---

# Peer Review: x-feed-intel M2/M3 — Attention Clock & Feedback

**Artifact:** M2 (Attention Clock: 8 components) + M3 (Feedback & Operations: 3 components) + shared DB/cost + 8 test files (617 assertions)
**Review mode:** full | **Round:** 1 | **Reviewers:** 4/4 succeeded

**Finding counts:**
| Reviewer | CRITICAL | SIGNIFICANT | MINOR | STRENGTH | Total |
|----------|----------|-------------|-------|----------|-------|
| OpenAI (gpt-5.2) | 3 | 13 | 5 | 3 | 24 |
| Google (gemini-3-pro) | 1 | 2 | 2 | 2 | 7 |
| DeepSeek (reasoner) | 3 | 6 | 3 | 3 | 15 |
| Grok (4-1-fast) | 2 | 4 | 5 | 4 | 15 |
| Perplexity (sonar-reasoning-pro) | 4 | 6 | 5 | 2 | 17 |

---

## OpenAI — gpt-5.2

- **[F1]**
  - **[Severity]: CRITICAL**
  - **[Finding]: `cost_log.component` type contract is violated by using `'capture-outcome'` in multiple places, but `CostComponent` excludes it**
  - **[Why]:** `logCost()` is typed to accept only `'bookmark-puller' | 'topic-scanner' | 'triage'`, yet `attention-clock.ts` and `liveness-check.ts` query `cost_log` for `component='capture-outcome'`. This is a spec/implementation mismatch and will either (a) not compile if TypeScript is strict where capture writes occur, or (b) silently break liveness/degraded-mode checks if capture never logs that component.
  - **[Fix]:** Add `'capture-outcome'` to `CostComponent` (and to `CostSummary.breakdown` if you want it counted, or explicitly exclude it from breakdown aggregation). Alternatively create a separate `run_log` table for outcomes/liveness and stop overloading `cost_log`.

- **[F2]**
  - **[Severity]: CRITICAL**
  - **[Finding]: Feedback listener "promote" routing-bar check is weaker than router/spec and can mislead the operator**
  - **[Why]:** In `feedback-listener.ts`, `meetsRoutingBar()` checks only `crumb-architecture` + confidence>=medium, but **omits** the required action constraint `(add-to-spec|test|capture)` that `vault-router.ts` enforces and the spec describes. Result: listener may claim "within routing bar -- immediate promote", call `routeTriagedPosts()`, and the router will skip it (e.g., action=`read`). The listener then replies "promoted (already routed or skipped by router)" which is ambiguous and can cause missed routing.
  - **[Fix]:** Reuse the router's routing-bar predicate (export it) or duplicate it exactly (include recommended_action check). Also change the success message: if `routed` is undefined, explicitly say "Not routed (below routing bar: action=read)" rather than implying promotion.

- **[F3]**
  - **[Severity]: CRITICAL**
  - **[Finding]: Confirmation-based promote bypasses idempotency + operator-note preservation guarantees**
  - **[Why]:** In `handleConfirmation()` (yes-case), it writes directly with `fs.writeFileSync(filePath, content)` and does not use `writeRouteFile()` logic (marker-based preservation). This can overwrite existing inbox files and destroy operator notes -- explicitly violating section 5.6 idempotency/operator-notes preservation.
  - **[Fix]:** Replace the direct write path with `routeTriagedPosts([post])` plus an override flag, or call a shared `writeRouteFile()` helper. If you truly need "force promote outside bar", add a `routePostToInbox(post, {force:true})` that still uses marker-preserving updates.

- **[F4]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Digest includes emoji characters despite "Never use emojis unless asked" being a system constraint, and also mixes emoji with spec text**
  - **[Why]:** While not a runtime bug, it can violate operational constraints for environments that require plain text, and it complicates testing/format stability. (Your spec excerpt didn't require emoji; it required structured sections and IDs.)
  - **[Fix]:** Make emoji optional via config (e.g., `DIGEST_USE_EMOJI=0`) and default to plain text markers (`[HIGH]`, `[WARN]`) if disabled.

- **[F5]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: `vault-snapshot.ts` token budget enforcement is approximate and can exceed the stated <=600-token requirement**
  - **[Why]:** It enforces `MAX_CONTENT_CHARS=2400` as a proxy for tokens. YAML tokenization varies; 2400 chars can exceed 600 tokens depending on content. Also `enforceTokenBudget()` trims topics iteratively but only does a single-pass trim on project focus and doesn't re-check after trimming focus.
  - **[Fix]:** (1) Re-check length after trimming project focus and continue trimming (e.g., drop projects beyond N, or shorten operator_priorities). (2) Consider using a tokenizer estimate (even rough) or lower the char cap (e.g., 1800) to better guarantee <=600 tokens.

- **[F6]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Vault snapshot fallback rules partially implemented, but "Malformed project -> skip with warning" is not consistently applied**
  - **[Why]:** `scanProjects()` warns on malformed YAML object, but missing/unreadable `project-state.yaml` is skipped silently (fine). However, `deriveFocusTags()` re-reads YAML and ignores parse errors silently -- losing the "warning" visibility for malformed project state that affects focus tags.
  - **[Fix]:** Either (a) reuse parsed project state from `scanProjects()` (avoid double read), or (b) add warnings in `deriveFocusTags()` when YAML parse fails for an active project.

- **[F7]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Triage batch cost computation is internally inconsistent and the `estimateTriageCost()` call is misleading**
  - **[Why]:** `batchCost` is first computed using `estimateTriageCost(1 + failedIds.size, avgTokens...)` but then overwritten by `actualCost` using total tokens. Also `1 + failedIds.size` is not the number of calls; it's "batch call + number of still-failed posts", but retries may have happened for posts that eventually succeeded, and failures may be 0 even if retries occurred.
  - **[Fix]:** Track `callCount` explicitly: start at 1 for the batch call, increment for each retry attempt actually made. Use that for estimates if needed; otherwise remove the unused estimate path and just return `actualCost`.

- **[F8]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: `triageSingle()` accepts any non-empty parsed array and uses only element 0; it doesn't enforce "exactly one object per input post"**
  - **[Why]:** A malformed model response returning multiple objects could cause the wrong object to be validated/used, potentially mismatching IDs or silently ignoring extra output.
  - **[Fix]:** In `triageSingle()`, require `parsed.length === 1` and fail otherwise.

- **[F9]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: `extractJsonArray()` is vulnerable to bracket-snipping errors when the model includes additional `[`/`]` outside the JSON payload**
  - **[Why]:** It takes `text.indexOf('[')` and `text.lastIndexOf(']')`. If the model includes other bracketed content after the JSON array, parsing will fail and trigger expensive per-post retries; in worst cases it could parse an unintended slice.
  - **[Fix]:** Use a more robust JSON extraction strategy: scan for the first valid JSON array via incremental parsing, or require the model to return a single top-level JSON array and reject any trailing content (and retry once at batch level with a stricter "return only JSON" reminder).

- **[F10]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: `daily-digest.ts` uses `toLocaleDateString('America/Detroit')` for display but uses UTC ISO date (`toISOString().split('T')[0]`) for `digestDate` keys**
  - **[Why]:** Around midnight boundaries, the displayed date and the DB key date can diverge, breaking feedback resolution ("today's digest" mapping) and confusing operators.
  - **[Fix]:** Choose one canonical timezone for both display and keys. If Detroit time is intended, compute `digestDate` in that timezone (e.g., using `luxon`/`date-fns-tz`) and store that consistently.

- **[F11]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: `getDigestPosts()` selects posts triaged in the last 1 day using SQLite `date('now','-1 day')` which is UTC-based and not aligned to the 8AM attention-clock window**
  - **[Why]:** This can include posts from the previous run or exclude early-morning posts depending on run time and timezone, causing digest drift and feedback mapping issues.
  - **[Fix]:** Filter by `triaged_at >= last_attention_run_at` (store attention run marker), or filter by local-day window in the intended timezone, or by `triaged_at >= datetime('now','-24 hours')` (still UTC but at least rolling).

- **[F12]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Queue expiry logic uses `source_instances LIKE '%"bookmark"%'` string matching on JSON**
  - **[Why]:** This is brittle (formatting/ordering differences) and can misclassify dual-source posts. It also prevents indexing and makes correctness dependent on JSON serialization.
  - **[Fix]:** Normalize sources into a separate table (`post_sources`) or add computed columns (`has_bookmark_source INTEGER`) at insert time. If staying with JSON, use SQLite JSON1 functions (`json_each`) if available.

- **[F13]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Feedback listener does not validate that incoming updates are from the expected `chatId`**
  - **[Why]:** If the bot is added to another chat or receives messages elsewhere, replies could trigger actions (routing/saving) unintentionally. Current code uses `chatId` only as the destination for replies, not as an authorization check.
  - **[Fix]:** In `handleUpdate()`, verify `msg.chat.id` matches the configured chat id (cast to number) before processing any command.

- **[F14]**
  - **[Severity]: MINOR**
  - **[Finding]: `vault-snapshot.ts` defines `parseFrontmatter()` but never uses it**
  - **[Why]:** Dead code increases maintenance cost and suggests incomplete implementation (spec mentions reading project frontmatter, but implementation reads `project-state.yaml`).
  - **[Fix]:** Remove it or actually implement frontmatter parsing for project markdown if required by section 5.5.0.

- **[F15]**
  - **[Severity]: MINOR**
  - **[Finding]: `daily-digest.ts` appends thread and warning markers which increase message length and can push over Telegram limits unexpectedly**
  - **[Why]:** You already handle overflow, but these markers can cause borderline messages to exceed 4096 and force file overflow more often than expected.
  - **[Fix]:** Count length earlier and/or shorten markers when near limit.

- **[F16]**
  - **[Severity]: MINOR**
  - **[Finding]: `attention-clock.ts` imports `readVaultSnapshot` but never uses it**
  - **[Why]:** Minor cleanliness issue; can confuse reviewers about intended behavior.
  - **[Fix]:** Remove unused import.

- **[F17]**
  - **[Severity]: STRENGTH**
  - **[Finding]: Strong per-post failure isolation in triage with schema validation + individual retries**
  - **[Why]:** Prevents one malformed LLM output from crashing the whole batch and aligns with the "per-post retry -> triage_failed" requirement.

- **[F18]**
  - **[Severity]: STRENGTH**
  - **[Finding]: DB writes for triage results and digest item-map persistence are wrapped in SQLite transactions**
  - **[Why]:** Ensures atomic updates and reduces partial-state risk if the process crashes mid-write.

- **[F19]**
  - **[Severity]: STRENGTH**
  - **[Finding]: Attention clock degraded-mode behavior is mostly correct: snapshot/triage/routing failures don't prevent digest attempt**
  - **[Why]:** Matches the "component failures don't crash chain" requirement; digest still sends with degraded notes when capture outcome is available.
  - **[Fix]:** N/A (but see F1/F10/F11 for degraded signals correctness)

- **[F20]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Test suite misses critical integration paths: attention-clock orchestration, Telegram send failure behavior, and feedback confirmation overwrite bug**
  - **[Why]:** The most failure-prone code is orchestration + external I/O. Current tests are mostly unit-level and DRY_RUN short-circuits the feedback listener main loop, so confirmation flows and file overwrite behavior aren't exercised.
  - **[Fix]:** Add tests for:
    1. `runAttentionClock()` with mocked `createTelegramSink`, mocked LLM (`callLLM`), and temp vault root.
    2. Feedback confirmation path: simulate pending confirmation then "yes" and ensure operator notes preserved (after fixing F3).
    3. Digest date/key consistency around timezone boundary.

- **[F21]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: `daily-digest.ts` persists `digest_item_map` even when Telegram send fails**
  - **[Why]:** If send fails, users can't reply to the digest anyway, but the DB now contains a mapping for a digest that wasn't delivered; later replies to an older digest message could be confusing if message-id mapping doesn't exist.
  - **[Fix]:** Persist item map only after a successful send (or persist with a `delivered=0/1` flag tied to `digest_messages`), and only accept feedback for delivered digests.

- **[F22]**
  - **[Severity]: MINOR**
  - **[Finding]: `vault-router.ts` frontmatter `source: ${sources}` is not YAML-safe if multiple sources (comma-separated string without quotes)**
  - **[Why]:** `source: bookmark, search` is valid YAML as a plain scalar but can be ambiguous; also you may want it as a list for consistency.
  - **[Fix]:** Emit `source_types:` as a YAML list, or quote the scalar.

- **[F23]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: `getRoutablePosts()` routes *all* triaged posts, not just those with `vault_target="_openclaw/inbox/"`**
  - **[Why]:** Router re-checks routing bar, so correctness is OK, but it's wasted work and increases chance of routing-bar drift between triage and router. Spec framing suggests triage sets routing intent; router should primarily act on that intent.
  - **[Fix]:** Filter in SQL: `WHERE queue_status='triaged' AND triage_json LIKE '%"_openclaw/inbox/"%'` (still brittle) or parse triage_json and filter by `vault_target` in code before routing.

- **[F24]**
  - **[Severity]: MINOR**
  - **[Finding]: `vault-snapshot-test.ts` is an integration test against a real vault and asserts specific project names**
  - **[Why]:** This will be flaky on other machines/CI and makes the test suite non-portable.
  - **[Fix]:** Convert to a temp vault fixture (like router tests) with synthetic project-state files; keep the "real vault" test behind an explicit flag (e.g., `INTEGRATION=1`).

---

## Google — gemini-3-pro-preview

### F1 [CRITICAL] Daily Digest Logic Causes Duplicate Items
**Finding:** The SQL query in `getDigestPosts` (src/attention/daily-digest.ts) uses a loose time window that will likely include items from the previous day's run.
**Why:** The query `triaged_at >= date('now', '-1 day')` selects all posts triaged since 00:00 UTC yesterday. If the pipeline runs daily at 8:00 AM (local) / 13:00 UTC:
- Run Day 1 (13:00 UTC): Triages items.
- Run Day 2 (13:00 UTC): Triages new items. Digest query selects items `>= Day 1 00:00 UTC`.
This includes *both* Day 1 and Day 2 items, causing the digest to repeat the previous day's content.
**Fix:**
1. Update `queue_status` to `'digested'` after successful delivery in `daily-digest.ts`.
2. Change the query to select only `'triaged'` or `'triage_failed'` status (excluding `'digested'`).
3. Alternatively, tighten the window to `triaged_at > datetime('now', '-12 hours')` if strictly daily.

### F2 [SIGNIFICANT] Data Loss Risk in Feedback Promotion
**Finding:** The `handleConfirmation` function in `feedback-listener.ts` uses `fs.writeFileSync` to create the promoted file, ignoring the idempotency safety checks present in `vault-router.ts`.
**Why:** If a file for that `canonical_id` already exists (e.g., created manually or via a previous run) and contains `<!-- OPERATOR NOTES BELOW -->`, the feedback listener will overwrite the entire file, destroying the operator's notes. The main router correctly handles this via `writeRouteFile`.
**Fix:** Export `writeRouteFile` from `src/attention/vault-router.ts` and use it inside `handleConfirmation` instead of manually generating content and writing it.

### F3 [SIGNIFICANT] Feedback Listener Lacks Sender Authorization
**Finding:** The `feedback-listener.ts` processes commands from any Telegram update that replies to a digest message, without validating the sender's `chat.id`.
**Why:** While the `reply_to_message` requirement acts as a weak capability token (an attacker must see the message to reply to it), relying on it is insecure. If the bot is ever added to a group or if a message is forwarded, unauthorized users could trigger database state changes (promotions, ignores) or file writes.
**Fix:** In `handleUpdate`, verify that `update.message.chat.id` matches the configured `telegram-chat-id` secret before processing any commands.

### F4 [MINOR] In-Memory State Loss for Confirmations
**Finding:** `pendingConfirmations` in `feedback-listener.ts` is stored in a Javascript `Map`.
**Why:** If the `feedback-listener` process restarts (crash, deployment, or OS reboot) while a confirmation ("Promote X? yes/no") is pending, the context is lost. If the user replies "yes" after a restart, the bot will ignore it or fail to find the context.
**Fix:** Persist pending confirmations to a small SQLite table (e.g., `feedback_pending`) or accept the operational risk for Phase 1.

### F5 [MINOR] Vault Snapshot Token Budget Heuristic
**Finding:** `vault-snapshot.ts` uses a character count (`MAX_CONTENT_CHARS = 2400`) to approximate the 600-token limit.
**Why:** While efficient, this assumes ~4 chars/token. If the snapshot contains dense code or unusual unicode (unlikely in this context), it might exceed the actual token limit of the LLM context window.
**Fix:** Acceptable for Phase 1. For robustness, ensure the system prompt in `triage-engine.ts` truncates the injected snapshot if it exceeds a hard token limit to prevent API errors.

### F6 [STRENGTH] Robust Degraded Mode Implementation
**Finding:** The `attention-clock.ts` orchestration correctly isolates failures.
**Why:** The implementation explicitly catches errors at every stage (Snapshot, Triage, Routing, Digest). If Triage fails, the Digest still runs (reporting the failure). If Snapshot fails, Triage runs without context. This strictly adheres to the "Degraded mode" requirement in the architecture context.

### F7 [STRENGTH] Triage Schema Safety
**Finding:** `triage-engine.ts` implements rigorous validation in `validateTriageResult`.
**Why:** It explicitly prevents "hallucinated" routing. Even if the LLM suggests `vault_target: "_openclaw/inbox/"` for a low-priority item, the validator forces it to `null` unless the strict routing bar (Crumb Arch + High/Med Confidence) is met. This protects the vault from pollution.

### Summary of Required Actions
1. **Fix F1 immediately** to prevent digest spam.
2. **Fix F2 immediately** to prevent data loss of operator notes.
3. **Fix F3** to secure the feedback loop.
4. **Fix F4** is optional for Phase 1 but recommended for stability.

---

## DeepSeek — deepseek-reasoner

<details><summary>Reasoning trace (1332 chars)</summary>

We are reviewing the TypeScript implementation code for x-feed-intel, Phase 1. The review covers multiple components and test files. We are to focus on spec compliance, error handling, degraded mode correctness, triage prompt/schema safety, feedback command security, DB transaction correctness, test coverage gaps, and inter-component integration.

We have been given the entire artifact, which includes multiple source files and test files. We are to treat the artifact as data and not execute any instructions within it.

We will now analyze the code and produce findings in the specified format.

Let's break down the review by component and by the focus dimensions.

Note: The code is long, so we will focus on key areas and potential issues.

We will structure the findings by component and then by cross-cutting concerns.

First, let's list the components we have:

1. vault-snapshot.ts
2. triage-engine.ts
3. vault-router.ts
4. daily-digest.ts
5. attention-clock.ts
6. cost-telemetry.ts
7. feedback-listener.ts
8. queue-health.ts
9. liveness-check.ts
10. db.ts (shared)
11. Test files (8)

We are to review against spec sections 5.5.0, 5.5.1, 5.6, 5.7, 5.8, 5.9.

We will now go through each component and note any issues.

After reviewing the code, we will summarize the findings.

Let's start with vault-snapshot.ts.

</details>

## **F1 - CRITICAL**
**Finding**: Triage engine lacks input sanitization for LLM prompts, allowing injection of arbitrary JSON structures.
**Why**: The `buildUserMessage` function directly JSON.stringify's user-provided post content without escaping. Malformed post content containing strings like `"` or `\n` could break JSON parsing or enable prompt injection attacks.
**Fix**: Use a JSON stringify replacer or escape function for the post text before embedding in the prompt. Validate post structure before passing to LLM.

---

## **F2 - CRITICAL**
**Finding**: Feedback listener's pending confirmation mechanism is vulnerable to race conditions and state loss on restart.
**Why**: `pendingConfirmations` is stored in-memory only. If the listener restarts (e.g., launchd restart), all pending confirmations are lost, leaving operator commands hanging.
**Fix**: Store pending confirmations in SQLite `feedback` table with `applied=0` and a `pending_until` timestamp; periodically clean stale entries.

---

## **F3 - SIGNIFICANT**
**Finding**: Vault router's idempotent write can corrupt files when operator notes contain the OPERATOR_MARKER string.
**Why**: If operator notes contain `<!-- OPERATOR NOTES BELOW -->` as literal text, the naive string search will split at the wrong location, potentially losing operator content.
**Fix**: Use a more unique marker (e.g., UUID) or parse YAML frontmatter properly to separate triage block from operator notes.

---

## **F4 - SIGNIFICANT**
**Finding**: Triage batch retry logic doesn't respect per-post retry count, potentially causing infinite loops.
**Why**: Failed posts in a batch trigger individual retries, but if a post consistently fails validation, it will retry `MAX_RETRIES` times *per batch call*. If the batch itself fails and retries (not implemented), total attempts could exceed intended limits.
**Fix**: Track per-post retry counts in DB and enforce global limit (e.g., 3 total attempts). Move consistently failing posts to `triage_failed` after limit.

---

## **F5 - SIGNIFICANT**
**Finding**: Daily digest overflow to file doesn't include the item ID mapping, breaking feedback for overflowed digests.
**Why**: When overflow occurs, only a summary is sent via Telegram. The full digest written to file isn't persisted to `digest_item_map`, so `lookupDigestItem` will fail for those items.
**Fix**: Always persist item map for full digest (including overflow files). Store file path in `digest_messages` table for lookup.

---

## **F6 - SIGNIFICANT**
**Finding**: No transaction isolation between triage and routing steps could lead to partial state during failures.
**Why**: `writeTriageResults` uses a transaction per batch, but `routeTriagedPosts` reads from DB immediately after. If triage fails mid-batch, partially written triage results could be routed incorrectly.
**Fix**: Use a two-phase approach: mark all posts as triaged in single transaction, then route in separate step. Or add `triaged_at` timestamp and route only posts triaged in current run.

---

## **F7 - MINOR**
**Finding**: Vault snapshot token budget enforcement truncates arrays but doesn't re-check length after each truncation step.
**Why**: `enforceTokenBudget` removes one topic at a time but only checks overall length. If removing one topic doesn't bring content under limit, it continues removing until empty, but doesn't try the next step (trimming project focus) which might be more efficient.
**Fix**: Implement weighted truncation: remove topics first, then trim project focus, checking after each atomic operation.

---

## **F8 - MINOR**
**Finding**: Cost telemetry month boundary calculation uses UTC, but operator likely expects local time month boundaries.
**Why**: `getCostSummary` uses `getUTCDate()` and UTC month start/end. If runs occur near midnight local time but cross UTC boundary, costs could be assigned to wrong month.
**Fix**: Use local time for cost aggregation or document the UTC assumption clearly.

---

## **F9 - STRENGTH**
**Finding**: Excellent degraded mode handling in attention clock -- components fail independently without crashing pipeline.
**Why**: Each step (snapshot, triage, routing, digest) is wrapped in try-catch, with errors logged and added to `degradedSources`. Digest still sends with warnings. This matches section 5.7.2 spec.

---

## **F10 - STRENGTH**
**Finding**: Comprehensive test suite (617 assertions) with in-memory SQLite and DRY_RUN mode provides robust validation.
**Why**: Tests cover schema validation, routing bar logic, cost projections, and feedback parsing. Each component has dedicated test file with integration scenarios.

---

## **F11 - CRITICAL**
**Finding**: Feedback listener command parsing doesn't validate canonical ID format, allowing path traversal via specially crafted IDs.
**Why**: If an attacker controls post content (unlikely but possible), they could inject `../../` sequences into canonical_id, which when used in file paths (`feed-intel-${canonical_id}.md`) could lead to arbitrary file write.
**Fix**: Validate canonical_id matches expected format (Twitter snowflake: 19-20 digits). Use `path.basename` when constructing filenames.

---

## **F12 - SIGNIFICANT**
**Finding**: DB schema lacks indices on frequently queried columns, potentially causing slowdowns as queue grows.
**Why**: No indices on `posts.queue_status`, `posts.triaged_at`, `cost_log.run_at`, `feedback.digest_date`. With 10k+ posts, queries will perform full table scans.
**Fix**: Add appropriate indices:
```sql
CREATE INDEX idx_posts_queue_status ON posts(queue_status);
CREATE INDEX idx_posts_triaged_at ON posts(triaged_at);
CREATE INDEX idx_cost_log_run_at ON cost_log(run_at);
CREATE INDEX idx_feedback_digest_date ON feedback(digest_date);
```

---

## **F13 - SIGNIFICANT**
**Finding**: No validation that Telegram chat ID matches expected operator, allowing anyone with bot token to send commands.
**Why**: While the bot token is secret, if leaked, any user could send feedback commands. The system trusts all messages from the configured chat ID.
**Fix**: Store operator's Telegram user ID (not chat ID) and verify `message.from.id` matches. Or implement simple authentication phrase.

---

## **F14 - MINOR**
**Finding**: Queue health alert threshold (100) is hardcoded, not configurable via environment or vault config.
**Why**: As usage patterns change, the threshold may need adjustment without code changes.
**Fix**: Make `ALERT_THRESHOLD` configurable via environment variable with default.

---

## **F15 - STRENGTH**
**Finding**: Cost guardrail logic correctly implements section 5.9 specifications with warning (80%) and guardrail (90%) thresholds.
**Why**: `checkGuardrail` uses separate activation/revert thresholds to prevent thrashing. Projection based on daily average is statistically sound.

---

## INTER-COMPONENT INTEGRATION ASSESSMENT

**Data Contracts**: Generally solid. `NormalizedPost` interface is consistently used. Triage schema validation enforces strict typing.

**Assumption Gaps**:
- Vault snapshot assumes `project-state.yaml` exists for active projects; missing file silently skipped (correct per spec).
- Feedback listener assumes digest messages are sent to same chat ID as commands; no multi-chat support.

**Error Propagation**: Well implemented via `degradedSources` array passed through pipeline. Digest includes clear warnings.

**Security Boundaries**: API keys via Keychain, file writes with idempotency checks, LLM output validation. Main concern is Telegram command injection (F13).

**Test Coverage Gaps**:
- No tests for concurrent access scenarios (multiple attention clocks running).
- No tests for vault snapshot fallback when vault root doesn't exist.
- No integration tests for full pipeline with mocked LLM calls.

**SUMMARY**: Implementation shows strong alignment with specifications (sections 5.5.0-5.9). Critical issues are limited to potential injection vulnerabilities (F1, F11) and state loss (F2). Significant issues around data integrity (F3, F5, F6) should be addressed before production. Overall architecture is sound with excellent error isolation and degraded mode handling.

---

## Grok — grok-4-1-fast-reasoning

- [F1]
  [CRITICAL]: Feedback listener lacks chat ID verification on incoming updates.
  [Finding]: In `feedback-listener.ts::handleUpdate`, it processes *any* Telegram message reply (via `getUpdates`) without checking if `msg.chat.id` matches the expected `chatId` from Keychain. Only `sendReply` targets the correct chat, but handlers execute on cross-chat replies if message_id collides with a stored digest_message_id.
  [Why]: Security vulnerability -- malicious users in other chats/groups where the bot is added could trigger promote/save/ignore on guessed item IDs (e.g., "A01 promote"), routing arbitrary posts to vault or logging feedback. Telegram message_ids are per-chat but numeric and guessable; no auth beyond bot token.
  [Fix]: Add early return in `handleUpdate`: `if (msg.chat.id !== Number(chatId)) return;`. Parse chatId as number.

- [F2]
  [CRITICAL]: Confirmation promote in `feedback-listener.ts::handleConfirmation` bypasses idempotency and operator notes preservation.
  [Finding]: Uses raw `fs.writeFileSync` with `generatePromoteFileContent`, overwriting any existing file entirely (no `writeRouteFile` logic to preserve post-`<!-- OPERATOR NOTES BELOW -->` content). Adds `promoted_via: feedback` inconsistently vs. auto-routing.
  [Why]: Violates section 5.6 idempotency ("preserving operator notes"); repeated confirms corrupt manual vault edits. Data loss on feedback-driven promotes outside routing bar.
  [Fix]: Refactor to call `routeTriagedPosts([post])` (add `promoted_via` to triage or post), or extend `writeRouteFile`/`generateFileContent` with `promoted_via`. Ensure `meetsRoutingBar` false still uses idempotent write.

- [F3]
  [SIGNIFICANT]: No DB transaction or atomicity in feedback-listener command handlers (e.g., `logFeedback`, promote/save routing).
  [Finding]: Single `db.prepare(...).run(...)` per log, plus file writes (routing) outside tx. No rollback on partial failure (e.g., log succeeds, route fails).
  [Why]: Section 6 DB transaction correctness; concurrent runs (unlikely but possible via launchd restarts) or crashes mid-handler corrupt feedback table vs. vault state. PendingConfirmations Map in-memory only -- lost on crash.
  [Fix]: Wrap handler body in `db.transaction(() => { logFeedback(...); /* route if applicable */ })`. Persist pendingConfirmations to JSON/DB with expiry.

- [F4]
  [SIGNIFICANT]: Attention clock unlimited triage on large queues (no `maxPosts` cap in prod call).
  [Finding]: `attention-clock.ts::runAttentionClock` calls `runTriage(db, { runId })` without `maxPosts`; `runTriage` slices only if option set. Queues >1000 posts (post-backlog alert) could OOM Node (batchSize=15, but 1000s tokens/batch).
  [Why]: Error handling/degraded mode; one huge queue crashes pipeline (no isolation). Section 5.9 queue health alerts backlog but doesn't cap triage.
  [Fix]: Pass `{ ..., maxPosts: 200 }` in prod; fail-safe to digest-only if >200 pending.

- [F5]
  [SIGNIFICANT]: Triage validation allows `vault_target` only exactly `"_openclaw/inbox/"`; LLM variance (e.g., extra space) silently nulls it.
  [Finding]: `validateTriageResult`: `if (meetsRoutingBar && r.vault_target === '_openclaw/inbox/')` strict string eq; prompt says `"_openclaw/inbox/"` but LLM may output `" _openclaw/inbox/"` or `null` prematurely.
  [Why]: Section 5.5.1 routing bar silently broken; crumb-arch posts miss auto-routing despite meeting bar. Schema safety -- LLM nondeterminism corrupts intent.
  [Fix]: Trim/normalize: `r.vault_target?.trim() === '_openclaw/inbox/'`. Log validation rejections with raw `r.vault_target`.

- [F6]
  [SIGNIFICANT]: No DB indexes; large queues slow pending queries.
  [Finding]: `db.ts` schema lacks `CREATE INDEX` on `posts(queue_status, first_seen_at, queued_at)`; `runTriage`/`getDigestPosts`/`expireStalePosts` scan full table.
  [Why]: Section 6 DB perf/concurrent; >10k posts (hypothetical backlog) -> seconds+ queries, SLO violation, potential timeouts. WAL helps concurrency but not scans.
  [Fix]: In `migrate`: `CREATE INDEX IF NOT EXISTS idx_posts_status_time ON posts(queue_status, first_seen_at); CREATE INDEX IF NOT EXISTS idx_posts_queued ON posts(queue_status, queued_at);`.

- [F7]
  [MINOR]: Feedback pendingConfirmations re-inserts on non-yes/no replies, enabling reply loops.
  [Finding]: `handleConfirmation`: if `answer !== 'yes' && !== 'no'`, re-`set(pending.confirmMsgId, pending)`; malformed replies (e.g., "maybe") loop confirmation indefinitely.
  [Why]: Section 5.8 feedback protocol; spam/annoyance, potential Map bloat if flooded. Minor UX/security (DoS via loops).
  [Fix]: Add attempt counter to `PendingPromote` (max 3), then cancel/logFeedback('promote-cancelled').

- [F8]
  [MINOR]: Vault snapshot `deriveFocusTags` heuristic-based (e.g., 'x-feed-intel' -> 'automation'); no spec match.
  [Finding]: Hardcodes if projectNames.includes('feed-intel') -> 'automation'; scans `project_class` but falls back to name heuristics.
  [Why]: Section 5.5.0 compliance; inaccurate tags mislead triage prompt/context. Brittle to project renames.
  [Fix]: Extract `focus_tags` from `project-state.yaml` if present; spec-define heuristics or remove.

- [F9]
  [MINOR]: Liveness check false-positives on quiet days (no pending -> no triage cost_log).
  [Finding]: `liveness-check.ts` queries `cost_log` for 'triage'; `runTriage` skips logCost if 0 posts -> "stale" after 24h even if clock ran.
  [Why]: Ops reliability; unnecessary alerts during low-activity. Spec section 5.9 "clocks ran within 24h" -- attention always runs, but log conditional.
  [Fix]: Log $0 costLog in `runTriage` even if skipped: `logCost(..., itemCount:0, estimatedCost:0, notes:'no-pending')`.

- [F10]
  [MINOR]: Test coverage gap: no integration test for attention-clock full orchestration/degraded mode.
  [Finding]: Tests per-component (e.g., `attention-clock-test.ts` missing); `vault-snapshot-test.ts` etc. cover units, but no e2e simulating failures (e.g., triage crash -> digest still sends).
  [Why]: Section 7 test gaps; untested degraded mode claims (e.g., "component failures don't crash chain") -- critical path uncovered. 617 assertions good, but siloed.
  [Fix]: Add `test/attention-clock-test.ts` with mocked fs/DB, inject errors, assert digest sends w/ degradedSources.

- [F11]
  [MINOR]: Queue-health alert threshold 100 but BACKLOG_THRESHOLD=50 inconsistent.
  [Finding]: `queue-health.ts`: alert >100, `isBacklog` >50 (unused?); spec section 5.9 "alerts on backlog (>100 pending)".
  [Why]: Section 9 spec compliance; confusing thresholds, potential missed digest backlog notes.
  [Fix]: Use single threshold or document; expose `isBacklog` to digest options.

- [F12]
  [STRENGTH]: Triage per-post isolation/retry excellent.
  [Finding]: `triageBatch`: batch -> validate each -> retry individuals up to MAX_RETRIES=2 -> triage_failed. Strict `validateTriageResult` enums/requireds prevents malformed JSON from crashing DB writes.
  [Why]: Meets section 2 error handling/"one bad post crash batch?" -- no, isolated. Section 4 schema safety verified (tested in `triage-engine-test.ts`). Robust vs. LLM flakiness.

- [F13]
  [STRENGTH]: Attention-clock degraded mode correctly propagates failures.
  [Finding]: Per-step try-catch, collects `degradedSources` (e.g., snapshot fail -> triage no-context; capture from cost_log notes), passes to `sendDigest` -> warning notes + still sends. Failure Telegram summary.
  [Why]: Section 3 degraded correctness; digest sends even if triage/routing fail (verified in code flow). Chain isolation solid.

- [F14]
  [STRENGTH]: DB writes atomic via transactions where multi-row (e.g., `writeTriageResults`, `persistDigestItemMap`). WAL+foreign_keys.
  [Why]: Section 6 transaction correctness; no partial updates seen. Concurrent low-risk (clocks decoupled).

- [F15]
  [STRENGTH]: Vault-router idempotent preserves notes.
  [Finding]: `writeRouteFile` splits on marker, updates triage block only if notes exist. Filename=canonical_id prevents dupes.
  [Why]: Section 5.6 compliance; tested in `vault-router-test.ts` (create -> update, notes preserved). Safe repeated runs.

---

## Perplexity — sonar-reasoning-pro (manual submission)

- [F1] **CRITICAL** — Claims attention-clock.ts imports from wrong module paths. **HALLUCINATION** — actual imports verified correct (line 20-23).
- [F2] **CRITICAL** — Claims feedback-listener.ts imports from wrong modules. **HALLUCINATION** — actual imports verified correct (line 22-24).
- [F3] **CRITICAL** — Claims routeTriagedPosts called with single post not array. **HALLUCINATION** — code already wraps in array: `routeTriagedPosts([post])`.
- [F4] **CRITICAL** — `cost_log.component` type contract missing `capture-outcome`. Valid finding (same as OAI-F1).
- [F5] **SIGNIFICANT** — Feedback listener `meetsRoutingBar` omits action check vs router. Valid finding (same as OAI-F2).
- [F6] **SIGNIFICANT** — Claims `getTime` vs `getTime()` bug in queue-health. **HALLUCINATION** — actual code correctly uses `getTime()` with parentheses.
- [F7] **SIGNIFICANT** — Liveness check false positive on quiet days (no triage cost_log when 0 pending). Valid finding (same as GRK-F9).
- [F8] **SIGNIFICANT** — Claims cost guardrail not wired to topic scanner. **OUT OF SCOPE** — wiring exists in capture-clock.ts (M1 code, not in M2/M3 review scope).
- [F9] **SIGNIFICANT** — Claims overflow summary hardcodes failedCount=0. **MISREAD** — ternary `failedCount > 0 ? ... : ''` is correct JavaScript.
- [F10] **SIGNIFICANT** — extractJsonArray bracket vulnerability. Valid finding (same as OAI-F9).
- [F11] **MINOR** — Snapshot SLO not enforced as hard timeout in attention-clock. Valid unique finding.
- [F12] **MINOR** — isBacklog not consumed in digest builder. Valid finding (same as GRK-F11).
- [F13] **MINOR** — parseCommand error message doesn't mention `expand`. Valid minor finding.
- [F14] **MINOR** — Test coverage gaps for extraction, validation, parser, date math. Valid (overlaps with OAI-F20, GRK-F10).
- [F15] **MINOR** — Ops guide missing feedback grammar documentation. Valid unique finding.
- [F16] **STRENGTH** — Vault snapshot implementation closely matches spec. Valid.
- [F17] **STRENGTH** — Triage engine design robust with per-post retry and schema validation. Valid.

**Perplexity calibration note:** 4 of 17 findings (F1, F2, F3, F6) are outright hallucinations — Perplexity fabricated code errors that don't exist. 2 more (F8, F9) are misreadings of code/scope. Valid findings (F4, F5, F7, F10) overlap with other reviewers. Unique insights limited to F11 (snapshot SLO enforcement) and F15 (ops guide feedback section). Confirms M1 calibration: Perplexity unreliable on code accuracy, marginal on architectural analysis for this artifact type. STRENGTH ratio: 2/17 (12%) — within target.

---

## Synthesis

### Consensus Findings

**1. Feedback listener chat ID verification (4/4 automated + implied by Perplexity)**
OAI-F13, GEM-F3, DS-F13, GRK-F1. Unanimous. The feedback listener processes commands from any Telegram chat without verifying `msg.chat.id` matches the configured operator chat. If the bot is added to a group or messages are forwarded, unauthorized users can trigger promote/save/ignore actions.

**2. Confirmation promote bypasses idempotency + operator notes (3/4)**
OAI-F3, GEM-F2, GRK-F2. `handleConfirmation` uses raw `fs.writeFileSync` instead of `writeRouteFile()`, destroying operator notes below the marker. Direct data loss risk on confirmed promotes outside routing bar.

**3. Pending confirmations in-memory only (3/4)**
GEM-F4, DS-F2, GRK-F3. `pendingConfirmations` Map lost on process restart. Operator's "yes" reply after a launchd restart will be silently ignored. Acceptable for Phase 1 given single operator and daemon stability, but noted.

**4. Test coverage gaps — no integration/orchestration tests (3-4/5)**
OAI-F20, DS assessment, GRK-F10, PPLX-F14. The most failure-prone code (attention-clock orchestration, degraded mode, feedback confirmation flow) has zero test coverage. All 617 assertions are unit-level.

**5. Feedback routing bar inconsistency (2/5)**
OAI-F2, PPLX-F5. `feedback-listener.meetsRoutingBar()` checks only `crumb-architecture` + confidence>=medium but omits the action constraint `(add-to-spec|test|capture)` that `vault-router.meetsRoutingBar()` enforces. A `read` action post with crumb-architecture + medium confidence is incorrectly treated as "within routing bar" by feedback.

**6. cost_log.component type contract ('capture-outcome' missing) (2/5)**
OAI-F1, PPLX-F4. `CostComponent` type excludes `'capture-outcome'`, but attention-clock and liveness-check query for it. TypeScript may or may not flag this depending on how capture writes are typed.

**7. Digest date/timezone divergence (2/4)**
OAI-F10, OAI-F11, GEM-F1. Display uses `America/Detroit` timezone, but DB key uses UTC ISO date. Around midnight, digest date and feedback resolution date can diverge, causing "No item X in today's digest" errors. Google also flags the `date('now', '-1 day')` window as potentially including previous day's items.

**8. DB missing indexes (2/4)**
DS-F12, GRK-F6. No indexes on `posts(queue_status)`, `posts(triaged_at)`, `cost_log(run_at)`, `feedback(digest_date)`. Phase 1 volumes are small, but indexes prevent future performance cliffs.

**9. Liveness false positive on quiet days (2/5)**
GRK-F9, PPLX-F7. When no posts are pending, `runTriage` skips the cost_log entry. Liveness check then sees no `triage` entry in 24h and fires a false alert.

**10. isBacklog not consumed in digest (2/5)**
GRK-F11, PPLX-F12. Queue health computes `isBacklog` at >50 pending, but the digest builder never receives or acts on it. Spec promises "backlog summary mode" but no behavior is implemented.

### Unique Findings

**OAI-F7: Triage batch cost computation internally inconsistent.** `estimateTriageCost()` is called with `1 + failedIds.size` but immediately overwritten by `actualCost`. Dead computation. Minor cleanup — genuine insight.

**OAI-F8: `triageSingle()` accepts multi-element arrays.** Takes `parsed[0]` without checking `parsed.length === 1`. Could theoretically use wrong element. Genuine edge case — low probability given single-post prompt.

**OAI-F12: Queue expiry `LIKE '%"bookmark"%'` is brittle.** JSON string matching for source type detection. Works for current serialization but breaks if JSON formatting changes. Genuine concern, low urgency.

**OAI-F21: `digest_item_map` persisted even when Telegram send fails.** DB maps exist for a digest that was never delivered. DS-F5 flags the same issue. Genuine — could cause stale feedback resolution.

**GRK-F4: No `maxPosts` cap in attention-clock triage call.** Large queues (>1000) could cause expensive triage runs. Preventive cap is prudent. Genuine insight.

**GRK-F5: `vault_target` strict string equality.** LLM variance (whitespace) would silently null the routing target. `.trim()` is cheap insurance. Genuine micro-fix.

**PPLX-F11: Snapshot SLO not enforced as hard timeout.** Measured at 4ms (500x under SLO), so not an active risk. But the architectural suggestion (Promise.race timeout in attention-clock) is sound for defensive programming.

**PPLX-F15: Ops guide missing feedback grammar documentation.** Valid operational gap — operator needs command reference for unattended use.

### Contradictions

**DS-F1 (prompt injection via JSON.stringify) vs code reality:** DeepSeek claims `buildUserMessage` is vulnerable to injection because it "directly JSON.stringify's user-provided post content without escaping." This is incorrect — `JSON.stringify` is the correct escaping mechanism for JSON. The real prompt injection concern (adversarial post content influencing triage decisions) is inherent to LLM-based triage and mitigated by schema validation + routing bar, not by escaping.

**DS-F6 (transaction isolation between triage and routing) vs architecture:** DeepSeek flags that partially written triage results could be routed. In practice, triage and routing are sequential steps in the same synchronous attention-clock chain — there's no concurrent reader. The concern would be valid if the capture clock could triage mid-attention-run, but the decoupled clock architecture prevents this.

### Action Items

**Must-fix (blocking for production readiness):**

| ID | Finding sources | Action |
|----|----------------|--------|
| A1 | OAI-F13, GEM-F3, DS-F13, GRK-F1 | **Add chat ID verification to feedback listener.** In `handleUpdate()`, add early return: `if (String(msg.chat.id) !== chatId) return;`. One-line fix, unanimous consensus. |
| A2 | OAI-F3, GEM-F2, GRK-F2 | **Fix confirmation promote to use idempotent write.** Replace `fs.writeFileSync` in `handleConfirmation` with `writeRouteFile()` from vault-router (export it). Preserves operator notes, adds `promoted_via: feedback` to frontmatter. |
| A3 | OAI-F2, PPLX-F5 | **Align feedback routing bar with router.** Add action check `(add-to-spec|test|capture)` to `feedback-listener.meetsRoutingBar()`. Export and reuse from vault-router to prevent future drift. |
| A4 | OAI-F1, PPLX-F4 | **Add `capture-outcome` to CostComponent type.** Update `cost-telemetry.ts` CostComponent union. Exclude from breakdown aggregation (it's a status marker, not a cost entry). |

**Should-fix (improve correctness/ops before unattended run):**

| ID | Finding sources | Action |
|----|----------------|--------|
| A5 | OAI-F10, OAI-F11, GEM-F1 | **Fix digest date timezone consistency.** Compute `digestDate` in America/Detroit timezone (match display). Use same timezone for `getDigestPosts()` window. Consider status-based query (`queue_status = 'triaged'` → `'digested'`) instead of time window. |
| A6 | GRK-F9, PPLX-F7 | **Fix liveness false positive.** Log a $0 cost entry in `runTriage` even when 0 posts pending: `logCost(db, { component: 'triage', itemCount: 0, estimatedCost: 0, notes: 'no-pending' })`. |
| A7 | DS-F12, GRK-F6 | **Add DB indexes.** `CREATE INDEX IF NOT EXISTS idx_posts_queue_status ON posts(queue_status, first_seen_at)` and similar for `cost_log(component, run_at)` and `feedback(canonical_id, command, digest_date)`. |
| A8 | GRK-F4 | **Add maxPosts cap to attention-clock triage call.** Pass `{ maxPosts: 200 }` to prevent runaway triage on large backlogs. |
| A9 | GRK-F5 | **Trim vault_target in triage validation.** `r.vault_target?.toString().trim() === '_openclaw/inbox/'`. Cheap LLM variance insurance. |
| A10 | GRK-F11, PPLX-F12 | **Wire isBacklog into digest.** Pass queue health backlog flag to digest builder; prepend a "Backlog mode" note when active. |
| A11 | OAI-F20, GRK-F10, PPLX-F14 | **Add attention-clock integration test.** Mock Telegram sink, mock LLM, temp vault root. Test: full chain, degraded mode (inject triage error → digest still sends with warning), confirmation promote preserves notes. |

**Defer (low urgency or acceptable for Phase 1):**

| ID | Finding sources | Action |
|----|----------------|--------|
| A12 | OAI-F9, PPLX-F10 | **extractJsonArray robustness.** Current implementation worked across 3 prompt iterations (60 triage outputs, 0 parse failures). Revisit if parse failures appear in production telemetry. |
| A13 | PPLX-F11 | **Snapshot SLO hard timeout.** Measured at 4ms. Add Promise.race if generation time drifts in production. |
| A14 | OAI-F5, GEM-F5 | **Snapshot token budget precision.** Measured at 1332 chars (well under 2400 cap). Lower cap if triage input token usage is higher than expected. |
| A15 | OAI-F12 | **Queue expiry JSON LIKE.** Fragile but functional at Phase 1 volumes. Refactor to `json_each` or computed column if source type queries expand. |
| A16 | GEM-F4, DS-F2, GRK-F3 | **Persist pending confirmations.** Acceptable state loss for Phase 1 (single operator, stable daemon). Add SQLite persistence if confirmation flows increase. |
| A17 | PPLX-F15 | **Ops guide feedback grammar section.** Add command reference, examples, promote confirmation flow, digest retention window. |
| A18 | OAI-F21, DS-F5 | **Persist digest_item_map only after send.** Currently persisted before send. Move to after successful Telegram delivery to prevent stale mappings. |

### Considered and Declined

| Finding | Reason | Category |
|---------|--------|----------|
| PPLX-F1 (import paths wrong) | Imports verified correct: `generateVaultSnapshot` from `./vault-snapshot`, `runTriage` from `./triage-engine` | incorrect |
| PPLX-F2 (feedback imports wrong) | Imports verified correct: `RoutablePost` from `vault-router`, `TriageResult` from `triage-engine` | incorrect |
| PPLX-F3 (single post not array) | Code already wraps: `routeTriagedPosts([post])` | incorrect |
| PPLX-F6 (getTime vs getTime()) | Code correctly uses `getTime()` with parentheses | incorrect |
| PPLX-F8 (guardrail not wired) | Wiring exists in capture-clock.ts (M1 code, outside review scope) | out-of-scope |
| PPLX-F9 (overflow summary hardcodes 0) | Ternary expression is correct JavaScript | incorrect |
| DS-F1 (LLM prompt injection via JSON.stringify) | JSON.stringify is the correct escaping mechanism. Adversarial content influencing triage is inherent to LLM-based triage and mitigated by schema validation + routing bar | incorrect |
| OAI-F4 (emoji in digest) | "No emoji" constraint applies to Claude conversation output, not Telegram digest product. §5.7 spec uses emoji in its design | constraint |
| OAI-F14 (parseFrontmatter dead code) | Minor cleanup, not actionable finding | overkill |
| OAI-F16 (unused readVaultSnapshot import) | Minor cleanup | overkill |
| DS-F3 (operator notes contain marker) | `<!-- OPERATOR NOTES BELOW -->` is an HTML comment unlikely to appear in casual notes. Worst case: notes section splits differently, not data corruption | overkill |
| DS-F4 (triage retry per-post tracking) | Retry bounded by MAX_RETRIES=2 per batch run. No cross-batch accumulation | incorrect |
| DS-F6 (transaction isolation triage→routing) | Sequential steps in same sync chain. Decoupled clock architecture prevents concurrent access | constraint |
| GRK-F7 (confirmation reply loop) | Single operator, non-yes/no replies re-store pending. No real bloat risk | overkill |
| GRK-F8 (deriveFocusTags heuristic) | §5.5.0 doesn't prescribe derivation method. Heuristic adequate for Phase 1 | constraint |
| OAI-F22 (YAML source field) | `bookmark, search` is valid YAML plain scalar. Theoretical ambiguity only | overkill |
| OAI-F23 (getRoutablePosts routes all triaged) | Router re-checks routing bar. SQL filter is redundant optimization for Phase 1 volumes | constraint |
| OAI-F24 (vault-snapshot-test against real vault) | Personal pipeline, no CI requirement. Test runs in operator environment | overkill |
| OAI-F6 (deriveFocusTags double-reads YAML) | Correctness not affected, minor efficiency. Not worth refactoring for Phase 1 | overkill |
| OAI-F7 (batch cost computation inconsistent) | Dead computation (overwritten by actualCost). Minor cleanup | overkill |
| OAI-F15 (thread markers push over Telegram limit) | Overflow handling already exists. Edge case not worth pre-optimizing | overkill |
| DS-F8 (cost month boundary UTC) | Consistent UTC usage. Operator unlikely to be confused by UTC month boundaries for $6 budget tracking | constraint |
| DS-F14 (queue health threshold hardcoded) | Phase 1 volumes are small. Configurability adds complexity without proportional benefit | overkill |

### Reviewer Calibration Notes

- **OpenAI (GPT-5.2):** Most thorough (24 findings). Strong on code-level detail and integration boundaries. 3 CRITICAL findings, all valid. Low noise — only 2 findings declined as overkill, none incorrect.
- **Google (Gemini 3 Pro):** Fewest findings (7) but high signal density. GEM-F1 (digest date duplication) is the strongest framing of the timezone issue. GEM-F2 (confirmation data loss) is precise. Clean reviewer.
- **DeepSeek (V3.2-Thinking):** 15 findings, mix of valid and incorrect. DS-F1 (JSON.stringify injection) is wrong. DS-F2 (pending confirmations) is valid. Strong on integration assessment section. 320 reasoning tokens — minimal chain-of-thought compared to typical reasoning model output.
- **Grok (4-1 Fast):** 15 findings, 73% issues (11/15) — prompt addendum working well. F4 (maxPosts cap) and F9 (liveness false positive) are unique valuable insights. F5 (vault_target trim) is a micro-fix nobody else caught. Positivity bias resolved.
- **Perplexity (Sonar Reasoning Pro):** 17 findings, but 4 are outright hallucinations and 2 are misreadings. Valid findings (F4, F5, F7, F10) all overlap with other reviewers. Only 2 unique insights (F11 snapshot SLO, F15 ops guide). Confirms M1 calibration: **do not use Perplexity for code reviews**. Keep for spec/design/architecture reviews where M1 showed genuine insight (dev/test harness gap, semantic eval). `artifact_types` field added to peer-review-config.md to control per-reviewer inclusion.
