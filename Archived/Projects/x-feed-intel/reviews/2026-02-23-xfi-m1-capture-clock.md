---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: ~/openclaw/x-feed-intel/src/{shared/normalizer.ts,capture/bookmark-puller.ts,capture/topic-scanner.ts,shared/dedup.ts,capture/capture-clock.ts}
artifact_type: spec
artifact_hash: a3913eaf
prompt_hash: 3631f05d
base_ref: null
project: x-feed-intel
domain: software
skill_origin: peer-review
created: 2026-02-23
updated: 2026-02-23
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
  - perplexity/sonar-reasoning-pro
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
    latency_ms: 57353
    attempts: 1
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-xfi-m1-capture-clock-openai.json
  google:
    http_status: 200
    latency_ms: 57505
    attempts: 1
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-xfi-m1-capture-clock-google.json
  deepseek:
    http_status: 200
    latency_ms: 86764
    attempts: 1
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-xfi-m1-capture-clock-deepseek.json
  grok:
    http_status: 200
    latency_ms: 33710
    attempts: 1
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-xfi-m1-capture-clock-grok.json
  perplexity:
    http_status: 200
    latency_ms: manual
    attempts: 1
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-xfi-m1-capture-clock-perplexity.md
tags:
  - review
  - peer-review
---

# Peer Review: x-feed-intel M1 Capture Clock

**Artifact:** normalizer.ts, bookmark-puller.ts, topic-scanner.ts, dedup.ts, capture-clock.ts (+ 4 test files)
**Mode:** full
**Reviewed:** 2026-02-23
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning
**Review prompt:** Structured review of M1 capture clock components against spec §5.2–5.4, §7.2. Focus: spec compliance, error handling, dedup correctness, thread heuristic, test coverage, API contract safety, cost tracking accuracy.

---

## OpenAI (GPT-5.2)

- [F1]
  - [Severity]: **STRENGTH**
  - [Finding]: Topic config loader implements §5.2 filter resolution correctly (per-topic `filters` overrides global defaults; defaults applied when absent).
  - [Why]: Prevents surprising behavior when global defaults exist and topics need tighter/looser constraints.
  - [Fix]: None.

- [F2]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Topic scanner does **not** implement server-side query construction per spec intent ("operators" in filter string) in a safe/consistent way: `searchTopics()` builds `fullQuery = topic.filters ? \`${query} ${topic.filters}\` : query`, and then `runTopicScan()` *also* applies client-side fallback only for `min_faves`. There's no handling for other common operators (e.g., min_retweets/min_replies/min_views, lang filters, excluding replies/retweets), and `max_age_days` is unused.
  - [Why]: Spec §5.2 calls out both server filtering and client-side fallback "when server operators don't filter." If only `min_faves` is enforced client-side and other filters are ignored, results will diverge from configuration and increase noise/cost. `max_age_days` omission can greatly expand result set and reduce relevance.
  - [Fix]:
    1) Expand `applyClientSideFilters()` to parse and enforce at least the configured filter vocabulary you expect (min_retweets, min_replies, min_views, lang, -filter:replies, etc.).
    2) Use `max_age_days` by either adding a server-side operator if supported by TwitterAPI.io, or filtering client-side via `created_at`.
    3) Add unit tests that confirm each filter is enforced.

- [F3]
  - [Severity]: **MINOR**
  - [Finding]: `runTopicScan()` loads topic config (`loadTopicConfig`) but only uses it to obtain `topicConfig?.filters` for fallback filtering. Most config semantics are delegated to `searchTopics()`.
  - [Why]: It's easy to accidentally introduce inconsistencies (e.g., `searchTopics()` uses per-topic `max_results` but `runTopicScan()` uses config only partially).
  - [Fix]: Consider returning richer metadata from `searchTopics()` (topic config resolved) or have `runTopicScan()` drive the querying loop itself so config interpretation is centralized.

- [F4]
  - [Severity]: **STRENGTH**
  - [Finding]: Capture clock provides partial success isolation: bookmark failure doesn't block topic scan, and vice versa; errors are logged and (for orchestrator-level failures) Telegram-notified.
  - [Why]: Matches the "partial success handled" requirement and improves operational resilience.
  - [Fix]: None.

- [F5]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Bookmark puller error handling labels *all* `pullBookmarks()` failures as "auth failure" behavior (Telegram notification text is OAuth-themed when message contains "re-authorization"), but `pullBookmarks()` can fail for many non-auth transient reasons (timeouts, 429s, network). The code retries at capture-clock level, but the bookmark puller itself returns early on first thrown error and sets `authError`.
  - [Why]: Misclassification affects operator response and alert quality. Also, "authError" being populated for non-auth errors can cause downstream logic to treat it as needing manual reauth.
  - [Fix]: Distinguish error types:
    - If HTTP 401/403 from X API or token refresh failure → `authError`.
    - Else → return `error` (separate field) or throw to let capture-clock retry and classify as transient.
    - Update Telegram text to reflect "auth vs transient" clearly.

- [F6]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Capture clock retry policy exists (3 retries with 30/60/120s backoff) but is applied at the component-call level without discriminating transient vs permanent errors. Also, topic scan failures inside `searchTopics()` are swallowed per query (it returns empty tweets per failed query), so `runTopicScan()` will "succeed" even if many queries failed.
  - [Why]: You can end up with silent partial data loss while the orchestrator reports "OK". Spec calls out retries "on transient failure" and partial success handling; currently partial query failures are not surfaced to orchestrator status.
  - [Fix]:
    - Have `searchTopics()` return per-query error info (or a boolean `hadFailures`).
    - In `runTopicScan()`, propagate an error/warning count into `ScanSummary` and log WARN/ERROR if failures occurred.
    - Consider retry only on recognized transient classes (timeouts, 429, 5xx).

- [F7]
  - [Severity]: **MINOR**
  - [Finding]: Logging: capture-clock logs to `state/pipeline.log` and console, but bookmark-puller/topic-scanner log mostly via console or DB cost log; not all errors are guaranteed to land in `pipeline.log` unless thrown to capture-clock.
  - [Why]: Operational debugging is harder if component-level errors aren't centralized.
  - [Fix]: Consider a shared logger used by all components (or pass a log function down) so all notable events land in `pipeline.log`.

- [F8]
  - [Severity]: **CRITICAL**
  - [Finding]: Dedup behavior does not fully match §5.4: "Re-encountered posts update source_instances and matched_topics without re-queuing. If still pending, multi-source signal preserved for triage." Current implementation **always appends** new source instances (no dedup within `source_instances`), and it updates `last_seen_at` to the incoming post's `last_seen_at` (which is "now" at normalization time), not necessarily max(existing,last). It also does not treat triaged posts specially beyond not changing status; it will still update `source_instances/metadata` even if triaged (tests expect that). The spec excerpt says "already triaged, no update needed" only via your `DedupResult.skipped` comment—but implementation contradicts that comment.
  - [Why]:
    - Source inflation: repeated encounters can bloat JSON quickly.
    - `last_seen_at` should be monotonic; current code can move it backwards if clock skew or fixtures inject older timestamps.
    - Spec ambiguity: your `skipped` semantics and test "Already-triaged posts are not re-triaged" imply updates should occur; but your `DedupResult.skipped` comment says "already triaged, no update needed." This mismatch will cause incorrect expectations in downstream triage logic.
  - [Fix]:
    1) Decide policy explicitly:
       - Option A: For triaged posts, still update source/topic signals (likely useful for analytics) but keep queue_status unchanged. Then update the `skipped` comment + name (e.g., `unchangedCount`).
       - Option B: For triaged posts, skip all updates; then adjust tests accordingly.
    2) Deduplicate `source_instances` by a stable key (e.g., `{source, search_query, fetched_at}`) or at least avoid exact duplicates.
    3) Set `last_seen_at = max(existing.last_seen_at, new.fetched_at)` by reading existing `last_seen_at` and comparing.

- [F9]
  - [Severity]: **STRENGTH**
  - [Finding]: Dedup batch is wrapped in a `better-sqlite3` transaction, giving atomic all-or-nothing semantics for the batch under normal operation.
  - [Why]: Matches the spec's "dedup is atomic" goal and prevents partial queue writes.
  - [Fix]: None.

- [F10]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Dedup update statement updates only `source_instances`, `last_seen_at`, and `metadata_json`; it does not update `author_json` or `content_json` even if the new source provides better/more complete data (e.g., bookmarks may have richer metrics than search or vice versa).
  - [Why]: You may retain "unknown/empty author" forever if the first encounter had missing author, and lose improvements from later encounters. This impacts triage quality.
  - [Fix]: Implement a merge policy for author/content/engagement fields (e.g., fill missing author fields, take max engagement counters, update text if empty/shorter, etc.). Add tests for "first source missing author; second source fills it."

- [F11]
  - [Severity]: **STRENGTH**
  - [Finding]: Thread heuristic aligns with §5.3 excerpt: uses conversation_id mismatch + reply fields + text patterns, and sets `needs_context` only on structural/reply signals (not text-only patterns).
  - [Why]: Matches the "needs_context true for structural/reply signals only" requirement and avoids over-triggering context fetch.
  - [Fix]: None.

- [F12]
  - [Severity]: **MINOR**
  - [Finding]: Thread detection does not infer `thread_position` at all (always null), and text patterns are fairly limited.
  - [Why]: Not deriving `thread_position` may be acceptable for M1, but it's part of the normalized schema and may be expected downstream.
  - [Fix]: If downstream expects it, add lightweight parsing for `thread_position` from patterns like `^(\d+)\s*/` or `^(\d+)\s+of\s+\d+`.

- [F13]
  - [Severity]: **MINOR**
  - [Finding]: `NUMBERED_SLASH_RE = /^\d+\//m` will match any line starting with `1/` etc, including contexts unrelated to threads (e.g., "2026/02/…" at line start).
  - [Why]: Potential false positives for `is_thread`.
  - [Fix]: Tighten regex to common thread formats, e.g. `/^(?:\s*)(\d{1,2})\s*\/\s*(\d{1,2})?\b/m` or require small leading number.

- [F14]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Test coverage is decent for normalizer/dedup/pullers/scanner, but missing several important behavioral tests beyond missing `capture-clock-test.ts`:
    1) No tests for filter resolution precedence (global vs per-topic) and `max_age_days`.
    2) No tests asserting topic-scanner's "partial query failures are surfaced" (currently not surfaced).
    3) No tests for dedup behavior when DB row has malformed JSON (you increment `skipped` but don't verify atomicity/rollback in such scenario).
    4) No tests for `last_seen_at` monotonicity and timestamp merge.
    5) No tests for "don't append duplicate source instances" (currently it will).
    6) No tests for DB file path (`state/pipeline.db`) or WAL actually enabled in production openDb (you do set pragma, but not tested).
  - [Why]: These are the areas most likely to drift from spec and cause operational issues.
  - [Fix]: Add targeted unit tests for each bullet above.

- [F15]
  - [Severity]: **MINOR**
  - [Finding]: topic-scanner-test asserts `summary.results.length === 12` which hardcodes fixture/config coupling and will be brittle as topics evolve.
  - [Why]: Tests will fail on legitimate config changes unrelated to code correctness.
  - [Fix]: Assert `results.length > 0` and optionally equals `sum(topics[].queries.length)` derived from `loadTopicConfig()` in the test.

- [F16]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: API contract safety: Normalizer handles many nullable fields with `??` defaults, but it also sets `author.id` to `''` when missing. That may violate downstream expectations of non-empty IDs. Additionally, `SearchTweet.created_at` is typed as `string` (non-null) in api-client, but normalizer treats it as optional (`tweet.created_at ?? null`), masking type inconsistency.
  - [Why]: Silent coercions can produce subtly invalid canonical records (empty author IDs) and hide upstream contract changes.
  - [Fix]:
    - Prefer `author: null` or a dedicated "unknown author" object with explicit sentinel semantics instead of empty string IDs.
    - Align types: either make `SearchTweet.created_at?: string` if truly optional, or treat it as required.

- [F17]
  - [Severity]: **MINOR**
  - [Finding]: `applyClientSideFilters()` only parses `min_faves:(\d+)` and ignores whitespace/uppercase variants.
  - [Why]: Config ergonomics and correctness.
  - [Fix]: Make regex more flexible: `/\bmin_faves\s*:\s*(\d+)\b/i`.

- [F18]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Cost tracking is internally consistent but unclear if rates match provider billing model (per-tweet vs per-request). "fetched" for scan is pre-dedup, so cost includes duplicates.
  - [Why]: Misestimated costs can mislead budget monitoring.
  - [Fix]: Rename logged `item_count` to reflect billing unit. Add notes fields for post-dedup counts.

---

## Google (Gemini 3 Pro Preview)

- [F1]
  - [Severity]: **CRITICAL**
  - [Finding]: Missing Orchestrator Tests. `capture-clock.ts` contains critical logic for retries, state persistence, and fault tolerance with zero test coverage.
  - [Why]: If retry logic is flawed or state saving fails, pipeline could spam APIs or fail indefinitely.
  - [Fix]: Implement `test/capture-clock-test.ts` mocking components. Verify: 1) State file CRUD. 2) Retry 3x on failure. 3) Scan skipped within interval. 4) Partial success.

- [F2]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Cost calculated as `(totalFetched / 1000) * 0.15` implies linear pro-rated cost. Many providers charge per request.
  - [Why]: Inaccurate cost logging defeats budget monitoring.
  - [Fix]: Verify billing unit. Move price constants to config.

- [F3]
  - [Severity]: **MINOR**
  - [Finding]: `loadState()` catches all errors and returns `{}`. Corrupted state file silently resets scan schedule.
  - [Why]: Schedule reset without operator awareness.
  - [Fix]: Log WARNING on JSON parse errors (distinct from ENOENT).

- [F4]
  - [Severity]: **MINOR**
  - [Finding]: Hardcoded DB path in `src/shared/db.ts`.
  - [Why]: Limits integration test flexibility.
  - [Fix]: Accept env var override.

- [F5]
  - [Severity]: **STRENGTH**
  - [Finding]: Thread/context heuristic correctly distinguishes visual/content signals from structural necessity.
  - [Why]: Prevents over-triggering of context fetch.

---

## DeepSeek (V3.2-Thinking)

- [F1]
  - [Severity]: **STRENGTH**
  - [Finding]: Normalizer fully implements §5.3: canonical_id, source_instances, append-only matched_topics, thread heuristics.
  - [Why]: Core unification works correctly across both API sources.

- [F2]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Client-side filter only handles `min_faves`, ignoring other operators from §5.2.
  - [Why]: Missing fallback for other filter types reduces result quality.
  - [Fix]: Expand `applyClientSideFilters` for all operators.

- [F3]
  - [Severity]: **MINOR**
  - [Finding]: No special handling for multi-source pending posts.
  - [Why]: Multi-source posts might need priority signaling for triage.
  - [Fix]: Consider multi_source_count field.

- [F4]
  - [Severity]: **STRENGTH**
  - [Finding]: Excellent partial success handling in capture-clock.ts.
  - [Why]: Pipeline resilience when one API source is unavailable.

- [F5]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: DB connection management inconsistent. Potential for double-closing.
  - [Why]: WAL mode connections need consistent management.
  - [Fix]: Standardize on connection-per-run or pass db explicitly.

- [F6]
  - [Severity]: **MINOR**
  - [Finding]: Malformed JSON rows silently skipped without logging canonical_id.
  - [Why]: Silent skips lead to undiagnosable data inconsistency.
  - [Fix]: Log canonical_id at ERROR level.

- [F7]
  - [Severity]: **STRENGTH**
  - [Finding]: Dedup engine uses SQLite transactions for atomic batch operations.
  - [Why]: Prevents duplicate queuing.

- [F8]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: `skipped` counter conflates unchanged posts and malformed JSON rows.
  - [Why]: Debugging difficulty.
  - [Fix]: Separate counters.

- [F9]
  - [Severity]: **MINOR**
  - [Finding]: No index on `queue_status` column.
  - [Why]: Performance at scale.
  - [Fix]: `CREATE INDEX idx_queue_status ON posts(queue_status, first_seen_at)`.

- [F10]
  - [Severity]: **STRENGTH**
  - [Finding]: Thread detection correctly implements spec.

- [F11]
  - [Severity]: **MINOR**
  - [Finding]: `thread_position` always null.
  - [Why]: May be needed later.
  - [Fix]: Heuristic from numbered patterns.

- [F12]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Missing capture-clock orchestrator tests.
  - [Why]: Critical path untested.
  - [Fix]: Create `capture-clock-test.ts` with mocked components.

- [F13]
  - [Severity]: **MINOR**
  - [Finding]: Scanner tests don't verify filter fallback behavior.
  - [Why]: Untested spec requirement.
  - [Fix]: Add filter test cases.

- [F14]
  - [Severity]: **STRENGTH**
  - [Finding]: Excellent normalizer/dedup test coverage with fixtures.

- [F15]
  - [Severity]: **STRENGTH**
  - [Finding]: Robust null handling in normalizer with `??` defaults.

- [F16]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: `userName` vs `username` type naming confusion between APIs.
  - [Why]: Reduced type safety.
  - [Fix]: Document mapping or align types.

- [F17]
  - [Severity]: **STRENGTH**
  - [Finding]: Cost logging implements spec rates with run_id correlation.

- [F18]
  - [Severity]: **MINOR**
  - [Finding]: Pagination cost not accounted for.
  - [Fix]: Adjust formula.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
  - [Severity]: **CRITICAL**
  - [Finding]: Capture clock uses global `DEFAULT_SCAN_INTERVAL_DAYS=2` instead of per-topic frequency. All topics run together or none.
  - [Why]: Violates AC "topic scanner runs per-topic frequency". Over-scans low-freq or under-scans high-freq topics.
  - [Fix]: Parse `scan_frequency_days` per topic; track `lastScanRun` per-topic.

- [F2]
  - [Severity]: **CRITICAL**
  - [Finding]: `max_age_days` from topic config never applied. No `since:` date filter in queries.
  - [Why]: Fetches stale posts, bloating results and costs.
  - [Fix]: Compute `since` clause from `max_age_days` and append to query.

- [F3]
  - [Severity]: **CRITICAL**
  - [Finding]: Dedup updates overwrite `metadata_json` discarding fresh engagement data from re-encounters.
  - [Why]: Loses live metrics. Breaks engagement freshness.
  - [Fix]: Deep-merge `post.metadata` into `existingMeta`.

- [F4]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Cost rates hardcoded without verification. UNVERIFIABLE CLAIM: X API v2 bookmarks cost ($0.005/post); TwitterAPI.io pricing ($0.15/1000).
  - [Why]: Inaccurate logging misleads budgeting.
  - [Fix]: Comment sources; make configurable.

- [F5]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Client-side fallback only parses `min_faves`; ignores other operators.
  - [Why]: Partial §5.2 compliance.
  - [Fix]: Parse full filter string.

- [F6]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Capture state tracks only global timestamps, not per-topic. No cleanup logic.
  - [Why]: Global state blocks all topics; no partial resume on crash.
  - [Fix]: Store per-topic scan timestamps.

- [F7]
  - [Severity]: **MINOR**
  - [Finding]: `NUMBERED_SLASH_RE` matches false positives ("Score: 123/456").
  - [Why]: Unnecessary `is_thread` triggers.
  - [Fix]: Refine regex.

- [F8]
  - [Severity]: **MINOR**
  - [Finding]: No `thread_position` computation despite detecting numbered patterns.
  - [Why]: Missed triage context.
  - [Fix]: Extract position from matches.

- [F9]
  - [Severity]: **MINOR**
  - [Finding]: Missing edge case tests; capture-clock-test.ts absent.
  - [Why]: Reduced edge case confidence.
  - [Fix]: Add orchestrator and edge case tests.

- [F10]
  - [Severity]: **MINOR**
  - [Finding]: `db.close()` in `finally` risk double-close with component `ownDb` logic.
  - [Why]: Crash risk.
  - [Fix]: Pass db always; components never close if provided.

- [F11]
  - [Severity]: **STRENGTH**
  - [Finding]: Dedup atomicity verified via `db.transaction()`.

- [F12]
  - [Severity]: **STRENGTH**
  - [Finding]: Error isolation excellent: partial success, correct backoff, targeted Telegram alerts.

- [F13]
  - [Severity]: **STRENGTH**
  - [Finding]: Thread heuristic precisely matches §5.3.

---

## Perplexity (Sonar Reasoning Pro)

*Obtained via Perplexity web interface (separate from API dispatch). Reviewed spec + source files with 6-area focus prompt. Raw file: `Projects/x-feed-intel/reviews/raw/2026-02-23-xfi-m1-capture-clock-perplexity.md`*

- [F1]
  - [Severity]: **CRITICAL** *(downgraded to INCORRECT — see note)*
  - [Finding]: Claims `NormalizedPost` has `matched_topics` at top level, not inside `metadata`, creating a type mismatch with dedup.
  - [Why]: Would cause silent topic aggregation failures if true.
  - **NOTE: FACTUALLY INCORRECT.** Verified against source: `matched_topics` IS inside `metadata` in `NormalizedPost` (normalizer.ts:42), and dedup reads `post.metadata.matched_topics` (dedup.ts:77). No mismatch exists. Perplexity likely misread the spec's example format vs the implementation.

- [F2]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: No persistent degraded-mode signal. Capture clock results are in-memory only (`ClockResult`). The attention clock (M2) cannot determine if the prior capture run was degraded (bookmark failure, API down) because no persistent record exists.
  - [Why]: Digest degraded-mode notes ("X API failed this run; bookmarks not included") require knowing capture outcomes. Without persistence, digest must infer from absence of new items — ambiguous with a legitimately quiet day.
  - [Fix]: Persist capture run outcomes in `cost_log.notes` or a dedicated `runs` table. Include component status (`ok | degraded | failed`) and failure reason. Attention clock reads last capture outcome before generating digest.

- [F3]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Token refresh failure has no dedicated error type. Bookmark puller catches all errors uniformly, with no structured classification of auth vs transient failures.
  - [Why]: Overlaps with OAI-F5. Auth failures need different operator response than transient API failures.
  - [Fix]: Introduce `TokenRefreshError` class; catch specifically in bookmark puller.

- [F4]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Transient vs permanent error classification missing in retry logic. All exceptions treated identically.
  - [Why]: Overlaps with OAI-F6. Retrying permanent errors (4xx, invalid config) wastes time.
  - [Fix]: Classify errors before retry; only retry on transient classes.

- [F5]
  - [Severity]: **SIGNIFICANT**
  - [Finding]: Proposes a `runs` table for liveness checks: `(run_id, started_at, completed_at, component, status, notes)`. Would make XFI-027 (liveness check) trivial and provide the degraded-mode signal.
  - [Why]: Forward-looking design that solves both degraded-mode persistence and liveness check needs.
  - [Fix]: Add `runs` table to schema. Capture clock writes an entry per run. Liveness check queries latest run per component.

- [F6]
  - [Severity]: **MINOR**
  - [Finding]: `getPostsByStatus` return type doesn't include `triage_json`, `queue_status`, `queued_at`, `triaged_at`. M2 will need to duplicate parsing logic or extend the type.
  - [Why]: Forward-looking M2 readiness concern.
  - [Fix]: Extend return type or create separate `DbPost` type. (Already handled in M2 implementation.)

- [F7]
  - [Severity]: **MINOR**
  - [Finding]: No defensive validation in normalizer for missing required fields (`entry.id`, `tweet.id`). Missing fields will throw and crash the batch.
  - [Why]: One malformed API response entry could crash the entire normalization batch.
  - [Fix]: Validate required fields before normalization; log and skip malformed entries.

- [F8]
  - [Severity]: **MINOR**
  - [Finding]: `run_id` written to `cost_log.notes` but not to `posts` table. Cannot reconstruct which run produced which posts.
  - [Why]: Operational auditability concern.
  - [Fix]: Add `run_id` column to `posts` table or include in `metadata_json`.

- [F9]
  - [Severity]: **STRENGTH**
  - [Finding]: Schema in `db.ts` matches spec §7.2 exactly. All 5 tables present and correctly defined. WAL mode and foreign keys enabled.
  - [Why]: Clean spec-schema alignment.

- [F10]
  - [Severity]: **STRENGTH**
  - [Finding]: Dedup correctly uses transactions, never changes `queue_status` for existing rows, and preserves append-only semantics for `matched_topics`.
  - [Why]: M2 queue contract is safe.

---

## Synthesis

### Consensus Findings

Issues flagged by 2+ reviewers — highest signal.

1. **Client-side filters only handle `min_faves`** (OAI-F2, DS-F2, GRK-F5) — 3/5 reviewers. `applyClientSideFilters()` parses only one operator; other configured filters (min_retweets, lang, -filter:replies) are ignored when server-side operators don't work.

2. **`max_age_days` not applied** (OAI-F2, GRK-F2) — 2/5 reviewers. Config field exists but is never used to filter stale posts. GRK rates CRITICAL; stale content inflates costs and noise.

3. **Missing capture-clock-test.ts** (GEM-F1, DS-F12, GRK-F9) — 3/5 reviewers. Orchestrator has retry logic, state persistence, and scheduling gates with zero test coverage.

4. **Dedup doesn't merge engagement/author data on re-encounter** (OAI-F10, GRK-F3) — 2/5 reviewers. Update only touches source_instances and matched_topics. Fresh engagement metrics, better author data from later encounters are discarded.

5. **Cost billing unit ambiguity** (OAI-F18, GEM-F2, GRK-F4) — 3/5 reviewers. Rates are hardcoded magic numbers; unclear if pricing is per-tweet or per-request.

6. **`thread_position` never computed** (OAI-F12, DS-F11, GRK-F8) — 3/5 reviewers. All MINOR. Schema field exists but is always null.

7. **`NUMBERED_SLASH_RE` false positives** (OAI-F13, GRK-F7) — 2/5 reviewers. Both MINOR. Pattern `/^\d+\//m` can match dates and scores.

8. **DB connection management inconsistency** (DS-F5, GRK-F10) — 2/5 reviewers. Double-close risk when capture-clock passes its db to components that have `ownDb` fallback logic.

9. **Auth error misclassification / no error type distinction** (OAI-F5, PPLX-F3, PPLX-F4) — 2/5 reviewers (OAI + PPLX both). Bookmark puller treats all failures as auth errors; no transient vs permanent classification in retry logic.

### Unique Findings

- **OAI-F8**: Dedup `source_instances` inflation + `last_seen_at` non-monotonic + `skipped` semantics mismatch. **Genuine insight** — comprehensive analysis of dedup edge cases.
- **OAI-F16**: Empty `author.id = ''` sentinel and `SearchTweet.created_at` type inconsistency. **Genuine insight** — empty strings are worse than explicit null for downstream consumers.
- **GRK-F1**: Per-topic scan frequency not implemented — global interval only. **Genuine insight** — AC says "per-topic frequency" but implementation is global. However, topic config YAML doesn't define a frequency field per topic, so this is a gap between AC intent and config schema.
- **GRK-F6**: Capture state is global, not per-topic. **Related to GRK-F1** — same root cause.
- **DS-F8**: `skipped` counter conflates unchanged posts and malformed JSON rows. **Genuine insight** — makes debugging harder.
- **DS-F9**: No index on `queue_status` column. **Genuine insight** — will matter at scale; trivial to add.
- **DS-F16**: `userName` vs `username` type definition mismatch between APIs. **Noise** — this is intentional; `SearchTweet` uses `userName` because that's what TwitterAPI.io returns; normalizer maps correctly.
- **PPLX-F2**: No persistent degraded-mode signal. **Genuine insight and highest-value unique finding from Perplexity.** Capture clock results are in-memory only (`ClockResult`). The attention clock digest needs to show "bookmarks failed this run" but has no way to know — no persistent record of capture outcomes exists. The only signal would be absence of new items, which is ambiguous with a quiet day.
- **PPLX-F5**: Propose `runs` table for liveness checks and degraded-mode signal persistence. **Genuine insight** — solves two problems (XFI-027 liveness + degraded digest notes) with one table. Forward-looking but clean design.
- **PPLX-F7**: No defensive validation for missing required fields in normalizer. **Minor but genuine** — one malformed API entry could crash the batch. Low likelihood given dry-run validation, but worth a guard.
- **PPLX-F1**: `matched_topics` type mismatch claim. **INCORRECT** — verified against source code. `matched_topics` is inside `metadata` in `NormalizedPost` and dedup reads it correctly. Perplexity appears to have misread the spec example format.

### Contradictions

- **Dedup update completeness**: OAI-F8 rates the dedup merge logic as CRITICAL (source inflation, non-monotonic timestamps), while DS-F7 and GRK-F11 rate dedup atomicity as STRENGTH. **Not actually contradictory** — they're evaluating different aspects. The transaction wrapper is correct (STRENGTH); the merge logic within the transaction has gaps (SIGNIFICANT).

- **Cost tracking accuracy**: DS-F17 rates cost logging as STRENGTH ("accurately implements spec rates"), while OAI-F18 and GRK-F4 flag billing unit ambiguity as SIGNIFICANT. **Genuine disagreement** — DS takes the rates at face value; OAI and GRK question whether the rates match reality.

### Action Items

#### Must-fix — blocking stability

**A1** — Write capture-clock-test.ts
- Source: GEM-F1, DS-F12, GRK-F9 (3/4 reviewers)
- What: Create orchestrator tests covering retry logic (3x backoff), state persistence, scan frequency gating, and partial failure (bookmark fails, scan continues).

**A2** — Apply `max_age_days` to topic queries
- Source: OAI-F2, GRK-F2 (2/4 reviewers)
- What: Compute `since:YYYY-MM-DD` from `max_age_days` config and append to query string. Also apply client-side date filter as fallback.

**A3** — Expand client-side filter fallback
- Source: OAI-F2, DS-F2, GRK-F5 (3/4 reviewers)
- What: Extend `applyClientSideFilters()` to parse and enforce `min_retweets`, `min_replies`, `lang`, and `-filter:replies` from the filter string. Add unit tests for each operator.

#### Should-fix — significant but not blocking

**A4** — Separate `skipped` from `malformed` in dedup result
- Source: DS-F8, OAI-F8
- What: Add `malformed` counter to `DedupResult`. Log canonical_id of malformed rows at ERROR level.

**A5** — Externalize cost rate constants
- Source: OAI-F18, GEM-F2, GRK-F4
- What: Move cost rates to a config section or constants file. Add comments documenting the billing source. Clarify whether rates are per-tweet or per-request.

**A6** — Fix auth error misclassification in bookmark puller
- Source: OAI-F5
- What: Return separate `error` field for non-auth failures. Only set `authError` on HTTP 401/403 or explicit token refresh failure. Update Telegram notification text.

**A7** — Standardize DB connection management
- Source: DS-F5, GRK-F10
- What: Ensure capture-clock always passes its db to components. Verify components never close a passed-in db. Add guard in `runBookmarkPull`/`runTopicScan`.

**A8** — Make `last_seen_at` monotonic in dedup
- Source: OAI-F8
- What: Compare `existing.last_seen_at` with `new.fetched_at`; use max of the two.

**A9** — Persist capture run outcomes for degraded-mode digest
- Source: PPLX-F2, PPLX-F5
- What: Write capture clock run status (`ok | degraded | failed` per component, with failure reason) to `cost_log.notes` or a new `runs` table. Attention clock reads last capture outcome before generating digest's degraded-mode notes. Without this, the digest can't distinguish "API failed" from "quiet day."

#### Defer — minor, revisit later

**A10** — Tighten `NUMBERED_SLASH_RE` regex
- Source: OAI-F13, GRK-F7
- What: Restrict to small leading numbers (1-99) and require thread-like context.

**A11** — Compute `thread_position` from numbered patterns
- Source: OAI-F12, DS-F11, GRK-F8
- What: Extract position integer when numbered regex matches. Not needed for M1 triage.

**A12** — Add `queue_status` index
- Source: DS-F9
- What: `CREATE INDEX idx_queue_status ON posts(queue_status, first_seen_at)`. Trivial but not urgent at current scale.

**A13** — Improve `min_faves` regex flexibility
- Source: OAI-F17
- What: Use `/\bmin_faves\s*:\s*(\d+)\b/i`. Very minor.

**A14** — Add defensive validation in normalizer for required fields
- Source: PPLX-F7
- What: Validate `entry.id` / `tweet.id` exist before normalization; log and skip malformed entries.

### Considered and Declined

- **GRK-F1** (per-topic scan frequency): `incorrect` — The topic config YAML schema doesn't define a `scan_frequency_days` field per topic, and the spec §5.2 says "configurable -- default every 2-3 days" without mandating per-topic granularity. The XFI-014 AC says "per-topic frequency" but the config schema was designed without this field. This is a spec-config alignment gap, not an implementation bug. Adding per-topic frequency would require config schema changes and is better addressed as a Phase 2 enhancement.

- **DS-F3** (multi-source priority signal): `overkill` — The spec says multi-source signal is "preserved" and "available to triage" via the source_instances array. Adding a separate `multi_source_count` field is unnecessary when triage can inspect `source_instances.length`.

- **DS-F16** (`userName` vs `username`): `incorrect` — This is intentional API shape mapping. TwitterAPI.io returns `userName` (camelCase); X API v2 returns `username` (lowercase). The normalizer maps both to `handle`. Type definitions reflect their respective API shapes.

- **OAI-F10** (merge author/content on re-encounter): `constraint` — Spec §5.4 scopes dedup updates to "source_instances and matched_topics". Merging author/content goes beyond spec scope and introduces merge policy complexity. If engagement freshness is needed, it should be a spec amendment.

- **GRK-F3** (deep-merge metadata on re-encounter): `constraint` — Same reasoning as OAI-F10. The metadata merge intentionally matches spec's explicit update scope. Engagement refresh is a Phase 2 concern.

- **GEM-F4** (hardcoded DB path): `overkill` — Production DB path is fixed by spec §7.2. Tests use in-memory DBs. No practical scenario requires a configurable path.

- **DS-F18** (pagination cost accounting): `overkill` — Cost estimates are rough approximations for monitoring, not precise accounting. Pagination awareness adds complexity for marginal benefit.

- **OAI-F3** (centralize config interpretation): `overkill` — Current split between `searchTopics()` and `runTopicScan()` is clean separation of concerns (fetch vs. post-process).

- **PPLX-F1** (`matched_topics` type mismatch): `incorrect` — Verified against source code. `matched_topics` is inside `metadata` in `NormalizedPost` (normalizer.ts:42) and dedup reads `post.metadata.matched_topics` (dedup.ts:77). No mismatch. Perplexity's headline CRITICAL finding is factually wrong.

- **PPLX-F6** (`getPostsByStatus` return type for M2): `out-of-scope` — Forward-looking M2 readiness concern. M2 was already implemented with its own query patterns and doesn't use `getPostsByStatus` for triage reads.

- **PPLX-F8** (`run_id` in posts table): `overkill` — `run_id` is already in `cost_log.notes`. Adding it to the posts table adds a column to every row for an audit need that can be reconstructed from timestamps + cost_log correlation. Not worth the schema change.

- **PPLX-§3** (DB layer helpers): `overkill` — Adding `insertPendingPost`, `updatePostFromReencounter`, `markTriaged` helpers pre-emptively creates an abstraction layer for a single consumer. The current raw SQL in dedup is clear and type-safe within its transaction boundary.

### Grok Calibration Note

Grok STRENGTH ratio: 3/13 findings (23% STRENGTH). Within target range after prompt addendum calibration. Grok produced the strongest critical findings in this review (per-topic frequency gap, max_age_days miss, metadata overwrite) — all high-signal unique catches. Continuing to track.

### Perplexity Calibration Note

Perplexity (Sonar Reasoning Pro) was obtained separately via web interface, not through the API dispatch pipeline. Used a different prompt format (6 focused areas vs the 7-dimension structured prompt sent to the other 4 reviewers). 10 findings total: 2 STRENGTH, 1 incorrect CRITICAL, 4 SIGNIFICANT, 3 MINOR.

**Accuracy concern:** Perplexity's headline CRITICAL finding (`matched_topics` type mismatch) was factually incorrect — the code is consistent and the mismatch doesn't exist. This is a notable miss for a review's most important finding. The reviewer appears to have confused the spec's JSON example format with the TypeScript implementation.

**Unique value:** The degraded-mode signal persistence gap (PPLX-F2) was the highest-value unique finding — not caught by any of the 4 API-dispatched reviewers. The `runs` table proposal (PPLX-F5) elegantly solves both degraded-mode persistence and the upcoming XFI-027 liveness check need.

**Signal-to-noise:** Lower than the API-dispatched reviewers. Several findings were forward-looking M2 concerns that were already addressed in the M2 implementation. The different prompt format (focus areas vs structured output) produced less structured output, making synthesis harder.
