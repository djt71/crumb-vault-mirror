---
type: review
review_type: code
review_mode: diff
scope: milestone
project: mission-control
domain: software
language: TypeScript
framework: express
diff_stats:
  files_changed: 30
  insertions: 1169
  deletions: 12
skill_origin: code-review
created: 2026-03-07
updated: 2026-03-07
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
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "/Users/tess/ paths in code (launchd plist, VAULT_ROOT defaults) — expected for personal project"
reviewer_meta:
  anthropic:
    http_status: 200
    latency_ms: 72973
    attempts: 1
    token_usage:
      input_tokens: 19282
      output_tokens: 3362
    raw_json: Projects/mission-control/reviews/raw/2026-03-07-code-review-m1m2-api-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 81154
    tools_run:
      - "rg --files packages/api"
      - "npx tsc --noEmit (root — printed help, no tsconfig)"
      - "npx vitest run (root — collected dist/*.test.js, EPERM on sandbox)"
      - "npx tsc --noEmit (packages/api — clean, exit 0)"
      - "npx vitest run (packages/api — EPERM writing Vite temp files)"
      - "cat package.json, packages/api/package.json, tsconfig"
      - "nl -ba (nav-summary, ops, vault-check, healthchecks)"
      - "nl -ba (all remaining adapters, write-vault-file, server)"
    token_usage:
      input_tokens: unknown
      output_tokens: unknown
    jsonl_log: Projects/mission-control/reviews/raw/2026-03-07-code-review-m1m2-api-codex.jsonl
    raw_text: Projects/mission-control/reviews/raw/2026-03-07-code-review-m1m2-api-codex.txt
tags:
  - review
  - code-review
  - mission-control
---

# Code Review: M1+M2 API Segment

**Scope:** Milestone (M1 + M2) — Express API adapters, routes, utilities, deployment plist
**Diff:** 30 files, +1169/-12

## Reviewer: Claude Opus 4.6 (ANT)

### ANT-F1 — CRITICAL
**File:** `packages/api/src/adapters/system-stats.ts` (line 33-34) and all file-based adapters
**Finding:** `VAULT_ROOT` and file paths are computed at module load time using `process.env.VAULT_ROOT`. Tests use `vi.stubEnv()` and dynamic `import()`, but because of ESM module caching, the second test in each file that calls `import('./system-stats.js')` will get the same cached module with the original `VAULT_ROOT` value.
**Why:** Tests will pass individually but produce flaky/incorrect results when run together. The `vi.stubEnv` call in `beforeEach` has no effect on already-cached modules. Affects `system-stats.ts`, `service-status.ts`, `health-check-log.ts`, `vault-check.ts`, `ops-metrics.ts`, `llm-health.ts`.
**Fix:** Either (a) make adapters accept a vault root parameter / read `process.env` at call time inside the function body, or (b) use `vi.resetModules()` in `beforeEach` so each test gets a fresh module. Option (a) is more robust:
```ts
function getVaultRoot() {
  return process.env.VAULT_ROOT ?? '/Users/tess/crumb-vault';
}
```

### ANT-F2 — SIGNIFICANT
**File:** `packages/api/src/adapters/vault-check.ts` (line 35)
**Finding:** The `passed` logic is `errors.length === 0 || lines.some(l => PASS_RE.test(l))`. A file with `ERROR: missing frontmatter` followed by `vault-check passed` will be reported as passed despite errors. The `||` should be `&&` or simply rely on `errors.length === 0`.
**Why:** Masks real failures. A vault-check that emits both errors and a summary "passed" line would be incorrectly treated as healthy.
**Fix:** `const passed = errors.length === 0;`

### ANT-F3 — SIGNIFICANT
**File:** `packages/api/src/adapters/healthchecks.ts` (lines 31-35)
**Finding:** The `AbortController` timeout uses `setTimeout` but if `fetch` rejects before the timeout fires, the timer is never cleared on the error path. `clearTimeout` is only called on the success path.
**Why:** Timer leak per failed request. In a long-running server with network issues, this accumulates timers.
**Fix:** Use `try/finally` and call `clearTimeout(timeout)` in `finally`.

### ANT-F4 — SIGNIFICANT
**File:** `packages/api/src/adapters/health-check-log.ts` (line 29)
**Finding:** The `stale` field is always `false` for the health-check-log adapter -- there is no staleness detection at all, unlike every other file-based adapter.
**Why:** Inconsistency with the adapter contract. CONVENTIONS.md lists stale thresholds but this adapter does not check `stat()` mtime.
**Fix:** Add `stat()` + stale check like the other file-based adapters.

### ANT-F5 — SIGNIFICANT
**File:** `packages/api/src/server.ts` (lines 24-37)
**Finding:** Express 4 does not catch errors from `async` route handlers. If any adapter throws despite the try/catch design, or if `res.json()` throws, the error handler is never reached -- it becomes an unhandled promise rejection.
**Why:** The ops route and nav-summary route are both async. Express 4 does not natively handle promise rejections from async middleware.
**Fix:** Wrap async routes with a helper or upgrade to Express 5:
```ts
const asyncHandler = (fn) => (req, res, next) => fn(req, res, next).catch(next);
```

### ANT-F6 — SIGNIFICANT
**File:** `packages/api/src/adapters/healthchecks.ts` (lines 57-60)
**Finding:** Staleness is computed by checking if any check's `last_ping` exceeds `STALE_HEALTHCHECKS` (300s). But a cron job that runs hourly will always appear "stale" under a 300s threshold.
**Why:** Will cause persistent `warn` status on Ops nav-summary for any check with schedule >5 minutes, creating alert fatigue.
**Fix:** Use the check's own `next_ping`/`period`/`grace` fields, or use `fetchedAt` vs. a cache TTL for adapter-level staleness only.

### ANT-F7 — MINOR
**File:** `packages/api/src/constants.ts` (line 6)
**Finding:** `STALE_ATTENTION_ITEM_DAYS = 14` is named differently (days vs seconds) from all other constants.
**Fix:** Rename to `STALE_ATTENTION_ITEM = 14 * 86400` (seconds) or add explicit doc comment.

### ANT-F8 — MINOR
**File:** `packages/api/src/write-vault-file.ts` (lines 15-17)
**Finding:** The `rename` is not atomic across filesystems. Currently safe (same directory), but worth a comment.
**Fix:** Add comment: `// tmp file is in same dir as target, ensuring rename is atomic on same filesystem`

### ANT-F9 — MINOR
**File:** `packages/api/src/adapters/system-stats.ts` (lines 26-30)
**Finding:** `AdapterResult<T>` is defined in `system-stats.ts` and imported from there by all other adapters. Odd dependency.
**Fix:** Move `AdapterResult<T>` to `packages/api/src/types.ts` or alongside `constants.ts`.

### ANT-F10 — MINOR
**File:** `packages/api/src/adapters/healthchecks.test.ts` (lines 5-6, 14)
**Finding:** The test stubs `fetch` globally without cleanup of the global stub. Only `vi.restoreAllMocks()` is called, which may not clean up `vi.stubGlobal`.
**Fix:** Add `vi.unstubAllGlobals()` in `afterEach`.

### ANT-F11 — MINOR
**File:** `deployment/com.crumb.dashboard.plist` (lines 7-10)
**Finding:** The plist hardcodes the Homebrew node path (`/opt/homebrew/bin/node`). If node is updated or managed via nvm/fnm, this path may break silently.
**Fix:** Consider using a wrapper shell script that sources the correct node version.

### ANT-F12 — MINOR
**File:** `packages/api/src/adapters/health-check-log.test.ts` (line 56)
**Finding:** The MAX_EVENTS test generates timestamps like `T00:60:00`, `T00:99:00` for i>=60 -- invalid ISO 8601.
**Fix:** Generate valid timestamps with proper hour/minute calculation.

### ANT-F13 — MINOR
**File:** Test files generally
**Finding:** No integration test for `/api/ops` or `/api/nav-summary` routes. The `rollUpStatus` function has zero test coverage.
**Fix:** Add a test for `rollUpStatus` (extract as named export) and supertest-based route tests.

### ANT-F14 — STRENGTH
**File:** All adapter files
**Finding:** The adapter-never-throws pattern is consistently applied across all 7 adapters. Solid defensive pattern.

### ANT-F15 — STRENGTH
**File:** `packages/api/src/write-vault-file.ts`
**Finding:** Atomic write + zombie cleanup is well-designed. 30s threshold is sensible, fire-and-forget cleanup prevents breaking writes.

### ANT-F16 — STRENGTH
**File:** `CONVENTIONS.md`
**Finding:** Documenting the adapter contract, stale thresholds, required vs. optional adapters, and sort keys upfront is excellent practice.

**Opus Summary: CRITICAL: 1 | SIGNIFICANT: 5 | MINOR: 7 | STRENGTH: 3**

---

## Reviewer: Codex (GPT-5.3-Codex) (CDX)

### Tool Execution

Codex ran 9 commands in read-only sandbox mode:
1. `rg --files packages/api` — file listing (exit 0)
2. `pwd; ls -la; rg --files` — project structure (exit 0)
3. `npx tsc --noEmit` at repo root — printed TypeScript help (no tsconfig at root, exit 1)
4. `npx vitest run` at repo root — collected dist/*.test.js, EPERM on Vite temp files (exit 1)
5. `npx tsc --noEmit` in packages/api — **clean, no errors** (exit 0)
6. `npx vitest run` in packages/api — EPERM writing Vite temp files in read-only sandbox (exit 1)
7. `cat` package.json files and tsconfig (exit 0)
8. `nl -ba` nav-summary, ops, vault-check, healthchecks sources (exit 0)
9. `nl -ba` all remaining adapter sources + write-vault-file + server (exit 0)

**Type-checker result:** Clean (0 errors) in packages/api.
**Test suite result:** Could not execute in read-only sandbox (EPERM writing Vite temp files).

### CDX-F1 — SIGNIFICANT
**File:** `packages/api/src/adapters/vault-check.ts` (line 35)
**Finding:** `passed` is computed as `errors.length === 0 || lines.some(PASS_RE)`, so a log containing both explicit errors and a later "passed" line is treated as success.
**Fix:** Make success require no errors.
*[Converges with ANT-F2]*

### CDX-F2 — SIGNIFICANT
**File:** `packages/api/src/write-vault-file.ts` (line 15)
**Finding:** Temp path is deterministic (`${filePath}.tmp`), so concurrent writes to the same target can collide.
**Fix:** Use unique temp names per write (`${filePath}.${process.pid}.${Date.now()}.${rand}.tmp`).
*[Unique finding -- not raised by Opus]*

### CDX-F3 — SIGNIFICANT
**File:** `packages/api/src/routes/nav-summary.ts` (line 45)
**Finding:** Ops roll-up only includes `system-stats`, `service-status`, `healthchecks`, `llm-health`; it omits `health-check-log`, `vault-check`, and `ops-metrics` listed in conventions for ops optional adapters.
**Fix:** Include all ops adapters in `Promise.all` and in `rollUpStatus` optional set.
*[Unique finding -- not raised by Opus]*

### CDX-F4 — MINOR
**File:** `packages/api/src/adapters/healthchecks.ts` (line 33)
**Finding:** Timeout is cleared only on successful `await fetch`; if `fetch` throws, timer is not cleared.
**Fix:** Wrap in `try/finally`.
*[Converges with ANT-F3]*

### CDX-F5 — MINOR
**File:** `packages/api/src/adapters/healthchecks.ts` (line 49)
**Finding:** Response is cast without shape validation; malformed `last_ping` becomes `Invalid Date`, making stale check silently false.
**Fix:** Validate `json.checks` is an array and treat invalid timestamps as adapter error or stale.
*[Unique finding -- not raised by Opus]*

### CDX-F6 — MINOR
**File:** `packages/api/vitest.config.ts` (line 5)
**Finding:** Root `npx vitest run` discovered `packages/api/dist/*.test.js` causing duplicate suite collection.
**Fix:** Add root Vitest workspace config or enforce running tests via workspace scripts.
*[Unique finding, grounded in tool output]*

### CDX-F7 — STRENGTH
**File:** `packages/api/src/routes/ops.ts` (line 21)
**Finding:** Adapters composed with `Promise.all` following consistent `{ data, error, stale }` shape aligns with non-throwing adapter contract.

**Codex Summary: CRITICAL: 0 | SIGNIFICANT: 3 | MINOR: 3 | STRENGTH: 1**

---

## Cross-Reviewer Convergence

| Finding | Opus | Codex | Status |
|---------|------|-------|--------|
| vault-check passed logic inversion | ANT-F2 | CDX-F1 | **Converged** |
| healthchecks timer leak | ANT-F3 | CDX-F4 | **Converged** |
| ESM module caching breaks tests | ANT-F1 | -- | Opus only |
| async Express error handling | ANT-F5 | -- | Opus only |
| healthchecks staleness semantics | ANT-F6 | -- | Opus only |
| concurrent write collision | -- | CDX-F2 | Codex only |
| nav-summary missing ops adapters | -- | CDX-F3 | Codex only |
| healthchecks response validation | -- | CDX-F5 | Codex only |
| dist test collection noise | -- | CDX-F6 | Codex only (grounded in tool output) |

**Convergence rate:** 2 findings independently confirmed by both reviewers.
**Unique contributions:** Opus: 5 unique (including the CRITICAL), Codex: 4 unique.
