---
type: review
review_type: code
review_mode: diff
scope: manual
project: feed-intel-framework
domain: software
language: typescript
framework: node-ts
diff_stats:
  files_changed: 6
  insertions: 797
  deletions: 12
skill_origin: code-review
created: 2026-02-27
updated: 2026-02-27
reviewers:
  - anthropic/claude-opus-4-6
  - codex/gpt-5.3-codex
config_snapshot:
  curl_timeout: 120
  codex_timeout: 180
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  anthropic:
    http_status: 200
    latency_ms: 61210
    attempts: 1
    token_usage:
      input_tokens: 12131
      output_tokens: 2814
    raw_json: reviews/raw/2026-02-27-code-review-manual-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 102999
    tools_run:
      - "npm run typecheck"
      - "npm test"
      - "nl -ba src/adapters/rss/normalizer.ts"
      - "nl -ba test/rss-adapter-test.ts"
      - "nl -ba src/adapters/rss/index.ts"
      - "nl -ba src/cli/capture-clock.ts"
      - "nl -ba src/capture/index.ts"
      - "nl -ba adapters/rss.yaml"
      - "nl -ba src/shared/types.ts"
      - "rg -n patterns across src/capture src/shared src/adapters"
      - "nl -ba src/adapters/x/index.ts"
      - "nl -ba src/adapters/x/normalizer.ts"
      - "nl -ba src/shared/canonicalize-url.ts"
      - "rg -n platform_url in validate.ts"
      - "nl -ba src/shared/validate.ts"
      - "nl -ba src/shared/dedup.ts"
      - "nl -ba src/manifest/index.ts"
      - "rg -n runGuardrailCycle in src/cost"
      - "rg -n validateUnifiedContent across src"
      - "nl -ba src/cost/index.ts"
      - "rg -n validateUnifiedContent across src test"
      - "rg -n platform_url|created_at in src"
    token_usage:
      input_tokens: 446937
      cached_input_tokens: 390528
      output_tokens: 4980
    jsonl_log: reviews/raw/2026-02-27-code-review-manual-codex.jsonl
    raw_text: reviews/raw/2026-02-27-code-review-manual-codex.txt
tags:
  - review
  - code-review
  - fif-031
---

# Code Review: FIF-031 RSS Adapter (Manual)

**Scope:** RSS/Atom feed adapter addition (6 files, +797/-12 lines)
**Task:** FIF-031 — add RSS/Atom feed support as second adapter alongside X adapter

## Reviewer: Anthropic (Claude Opus 4.6)

### ANT-F1
- **Severity**: SIGNIFICANT
- **File**: `src/adapters/rss/normalizer.ts`, lines 170-172
- **Finding**: Fallback `canonical_id` when no permalink uses `new Date().toISOString()` + optional title, making it non-deterministic. If the same item (with no link) is fetched twice in different runs, it produces different canonical IDs, defeating dedup entirely.
- **Why**: Items without a `link` field will be re-ingested every run, creating duplicates in the database. RSS items without links are uncommon but do exist (e.g., status-type feeds, podcast feeds with only enclosures).
- **Fix**: Use a deterministic fallback: hash the `guid` field first (even non-URL guids are stable identifiers), then fall back to `title + pubDate`. Only use a timestamp as absolute last resort.
```typescript
const fallbackKey = item.guid || `${item.title || ''}|${item.isoDate || item.pubDate || ''}`;
const canonicalId = permalink
  ? `rss:${computeUrlHash(permalink)}`
  : `rss:${crypto.createHash('sha256').update(fallbackKey).digest('hex').slice(0, 16)}`;
```

### ANT-F2
- **Severity**: SIGNIFICANT
- **File**: `src/adapters/rss/index.ts`, lines 60-63
- **Finding**: The curated state (`lastFetchRun`) is recorded but never used to filter items. Every run fetches and returns all items from every feed, regardless of whether they were seen before.
- **Why**: Without date-based filtering, the adapter relies entirely on downstream dedup. The `lastFetchRun` field is misleading since it suggests time-based filtering that doesn't exist.
- **Fix**: Either filter `parsed.items` to those with `isoDate`/`pubDate` after `curatedState.lastFetchRun`, or document explicitly that dedup is external-only and consider removing `lastFetchRun` if it won't be used.

### ANT-F3
- **Severity**: MINOR
- **File**: `src/adapters/rss/normalizer.ts`, lines 80-82
- **Finding**: `extractExcerpt` uses basic regex `/<[^>]+>/g` for HTML stripping, which doesn't handle HTML entities (`&amp;`, `&lt;`, etc.).
- **Fix**: Add entity decode step after tag stripping.

### ANT-F4
- **Severity**: MINOR
- **File**: `src/adapters/rss/normalizer.ts`, lines 54-57
- **Finding**: `computeUrlHash` calls `canonicalizeUrl(url)` without validation. A malformed URL could throw and crash normalization for that item.
- **Fix**: Wrap per-item normalization in try/catch in the adapter loop.

### ANT-F5
- **Severity**: MINOR
- **File**: `src/adapters/rss/index.ts`, lines 70-78
- **Finding**: `feedItemCount` only increments for non-duplicate items, so `max_items_per_feed` means "max unique new items" rather than "max items consumed from feed."
- **Fix**: Document this behavior or increment unconditionally if strict per-feed caps are desired.

### ANT-F6
- **Severity**: MINOR
- **File**: `src/cli/capture-clock.ts`, line 25
- **Finding**: Unconditional `import Parser from 'rss-parser'` couples CLI entry point to RSS dependency. Missing npm package crashes entire capture-clock.
- **Fix**: Consider dynamic import inside try/catch, or verify `rss-parser` is in dependencies.

### ANT-F7
- **Severity**: MINOR
- **File**: `src/adapters/rss/normalizer.ts`, lines 62-65
- **Finding**: `extractFullText` applies the 500-char threshold to raw HTML length, not stripped text length. Heavy HTML markup could misclassify short articles as "full text."
- **Fix**: Low priority; consider stripping HTML before length check or increasing threshold for HTML content.

### ANT-F8
- **Severity**: STRENGTH
- **File**: `src/adapters/rss/index.ts`, lines 64-72
- **Finding**: Excellent error isolation — one feed failure doesn't crash the entire pull.

### ANT-F9
- **Severity**: STRENGTH
- **File**: `src/cli/capture-clock.ts`, lines 69-84
- **Finding**: Good graceful degradation — RSS config load failure is caught and logged, capture continues with X adapter only.

### ANT-F10
- **Severity**: STRENGTH
- **File**: `test/rss-adapter-test.ts`
- **Finding**: Comprehensive test coverage with clean mock injection pattern via `RssAdapterDeps`.

### ANT-F11
- **Severity**: MINOR
- **File**: `test/rss-adapter-test.ts`, line 89
- **Finding**: Test asserts exact `canonical_id.length === 20`, coupling to implementation detail of 16-hex-char hash.
- **Fix**: Test `length > 4` instead; keep regex as primary format assertion.

### ANT-F12
- **Severity**: MINOR
- **File**: `test/rss-adapter-test.ts`
- **Finding**: Missing test coverage for: enclosure URL as permalink fallback, pubDate fallback when isoDate missing, passing null/undefined as state to pullCurated.
- **Fix**: Add test cases for these code paths.

### ANT-F13
- **Severity**: MINOR
- **File**: `src/adapters/rss/index.ts`, line 88
- **Finding**: `lastFetchRun` captures end-of-run time, not start. If time-based filtering is added later, items published during the fetch window would be missed.
- **Fix**: Capture `runStartTime` at top of `pullCurated`.

**Anthropic summary: 0 CRITICAL, 2 SIGNIFICANT, 8 MINOR, 3 STRENGTH**

---

## Reviewer: Codex (GPT-5.3-Codex)

### Tool Execution

Codex ran 22 commands in read-only sandbox mode:

| Tool | Result |
|------|--------|
| `npm run typecheck` (`tsc --noEmit`) | PASS (exit 0) |
| `npm test` | Partial — failed at `manifest-test.ts:87` (EPERM: sandbox write restriction on `mkdtemp`). Schema/types/adapter-state/dedup suites passed before failure. |
| File reads | Read all 6 diff files + related framework files (types, validate, dedup, manifest, cost, X adapter) |
| Pattern searches | Searched for CaptureAdapter interface, validateUnifiedContent, platform_url, created_at patterns across codebase |

### CDX-F1
- **Severity**: SIGNIFICANT
- **File**: `src/adapters/rss/normalizer.ts`, line 164
- **Finding**: `metadata.created_at` falls back to `item.pubDate`, which is often RFC-822 (e.g., `Wed, 26 Feb 2026 10:00:00 GMT`) rather than ISO-8601. Project validation requires ISO-8601 (`validateUnifiedContent`).
- **Why**: Cross-component contract drift and future validation failures.
- **Fix**: Parse and normalize `pubDate` to ISO: `new Date(item.pubDate).toISOString()` when valid, else fallback to `now`.

### CDX-F2
- **Severity**: SIGNIFICANT
- **File**: `src/adapters/rss/normalizer.ts`, lines 110, 167
- **Finding**: Items without `link/guid/enclosure` produce `platform_url: ''`. The framework's validator expects `metadata.platform_url` to be non-empty.
- **Why**: Empty links degrade digest/router output quality.
- **Fix**: Either filter such items during normalization (`return null` + filter in adapter) or set `platform_url` to a guaranteed stable fallback.

### CDX-F3
- **Severity**: MINOR
- **File**: `src/cli/capture-clock.ts`, line 70; `src/adapters/rss/index.ts`, line 58
- **Finding**: RSS config loaded with unchecked cast (`as RssFeedsConfig`). Malformed YAML survives construction and fails later during capture.
- **Fix**: Add runtime guard at load time (check `defaults.max_items_per_feed` is number and `feeds` is array).

### CDX-F4
- **Severity**: MINOR
- **File**: `src/adapters/rss/index.ts`, line 60
- **Finding**: Feed fetches are strictly sequential (`await` inside loop). With many feeds, wall-clock duration scales linearly.
- **Fix**: Fetch in bounded parallelism (3-5 concurrent) while preserving per-feed error isolation.

### CDX-F5
- **Severity**: MINOR
- **File**: `test/rss-adapter-test.ts`, lines 69, 220
- **Finding**: Tests don't assert framework-contract validity (`validateUnifiedContent`) for RSS outputs, especially missing permalink and `pubDate`-only cases.
- **Fix**: Add tests that run `validateUnifiedContent(normalizeRssItem(...))` for edge cases.

### CDX-F6
- **Severity**: STRENGTH
- **File**: `src/adapters/rss/index.ts`, line 64; `test/rss-adapter-test.ts`, line 378
- **Finding**: Per-feed error isolation is implemented and tested — correct resilience model for multi-feed ingestion.

**Codex summary: 0 CRITICAL, 2 SIGNIFICANT, 3 MINOR, 1 STRENGTH**

---

## Combined Summary

| Severity | Anthropic | Codex | Total Unique |
|----------|-----------|-------|------|
| CRITICAL | 0 | 0 | 0 |
| SIGNIFICANT | 2 | 2 | 4 |
| MINOR | 8 | 3 | ~9 |
| STRENGTH | 3 | 1 | 3 |

### Cross-Reviewer Convergence

- **Both found**: Non-deterministic/problematic canonical_id for link-less items (ANT-F1 overlaps with CDX-F2)
- **Both found**: Error isolation as a strength (ANT-F8/F9, CDX-F6)
- **Codex unique**: pubDate RFC-822 vs ISO-8601 contract drift (CDX-F1) — grounded in `validateUnifiedContent` source code
- **Codex unique**: Empty `platform_url` violates validator (CDX-F2) — grounded in `validate.ts` search
- **Anthropic unique**: Unused `lastFetchRun` state (ANT-F2), HTML entity stripping (ANT-F3), full text threshold on raw HTML (ANT-F7)
