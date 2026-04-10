---
type: review
review_type: code
review_mode: diff
scope: milestone
project: mission-control
domain: software
language: TypeScript/React/CSS
framework: react+vite
diff_stats:
  files_changed: 22
  insertions: 1494
  deletions: 6
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
    - "localhost:3100 in Vite proxy config (expected dev server URL)"
reviewer_meta:
  anthropic:
    http_status: 200
    latency_ms: 65671
    attempts: 1
    token_usage:
      input_tokens: 17986
      output_tokens: 3192
    raw_json: Projects/mission-control/reviews/raw/2026-03-07-code-review-m1m2-web-anthropic.json
  codex:
    exit_code: 0
    latency_ms: 102930
    tools_run:
      - "npx tsc -p packages/web/tsconfig.json --noEmit (PASS)"
      - "npx tsc -p packages/api/tsconfig.json --noEmit (PASS)"
      - "npm run test (EPERM — sandbox write restriction)"
      - "rg --files (repo inventory)"
      - "nl -ba (16 source files read for signature verification)"
    token_usage:
      input_tokens: 282813
      output_tokens: 5228
    jsonl_log: Projects/mission-control/reviews/raw/2026-03-07-code-review-m1m2-web-codex.jsonl
    raw_text: Projects/mission-control/reviews/raw/2026-03-07-code-review-m1m2-web-codex.txt
tags:
  - review
  - code-review
status: active
---

# Code Review: Mission Control Web — M1 + M2 Milestone

**Scope:** 22 files, +1494/-6 lines. Shell layout (NavRail, HealthStrip), Ops page (KPI strip, gauges, service grid, timeline, LLM status, cost burn), polling hooks, SafeMarkdown, CSS theme, tests.

## Reviewer: Claude Opus 4.6 (ANT)

**Findings: 0 CRITICAL | 3 SIGNIFICANT | 7 MINOR | 4 STRENGTH**

### ANT-F1 [SIGNIFICANT] — Stale data hidden on polling error
**File:** usePolling.ts:23-37, OpsPage.tsx:35
When HTTP errors occur after a successful first fetch, stale data persists with no visible error indicator. The `if (error && !data)` guard in OpsPage means errors with stale data are invisible.
**Fix:** Show error banner whenever `error` is truthy, not only when `!data`.

### ANT-F2 [SIGNIFICANT] — SafeMarkdown URI scheme not explicitly restricted
**File:** SafeMarkdown.tsx:14-23
DOMPurify config allows `href`/`src` without explicit URI scheme restriction. Defense-in-depth concern — DOMPurify defaults likely block `javascript:` but explicit allowlist overrides may weaken defaults.
**Fix:** Add `javascript:` URI test case. Verify behavior with current DOMPurify version.

### ANT-F3 [SIGNIFICANT] — Race condition in usePolling on URL change
**File:** usePolling.ts:42-68
No AbortController — if URL changes, in-flight fetch from old URL can resolve and overwrite state.
**Fix:** Add AbortController per request, abort in cleanup.

### ANT-F4 [MINOR] — formatRefreshAge shows stale "Xs ago" between polls
**File:** OpsPage.tsx:11-15

### ANT-F5 [MINOR] — Missing stub files for OpsPage component imports
**File:** OpsPage.tsx:1-7

### ANT-F6 [MINOR] — Concurrent fetch possible on visibility resume
**File:** usePolling.ts:49-52

### ANT-F7 [MINOR] — Badge/status dot overlap on NavRail items
**File:** NavRail.tsx:98-112

### ANT-F8 [MINOR] — SafeMarkdown tests missing img onerror vector
**File:** SafeMarkdown.test.tsx

### ANT-F9 [SIGNIFICANT — Accessibility] — NavRail missing ARIA landmarks
**File:** NavRail.tsx, index.css
No `aria-label` on `<nav>`, no `aria-current="page"`, SVG icons lack accessible text.
**Fix:** Add `aria-label="Main navigation"`, `aria-current` via NavLink, `aria-hidden="true"` on decorative SVGs.

### ANT-F10 [MINOR] — Google Fonts render-blocking
**File:** index.html:7-12

### ANT-F15 [MINOR] — jest-dom matchers not configured for vitest
**File:** vitest.config.ts
`@testing-library/jest-dom` in devDependencies but no setup file.
**Fix:** Add `setupFiles: ['./src/test-setup.ts']` to vitest config.

### Strengths
- **ANT-F11:** Clean usePolling hook with visibility API pause
- **ANT-F12:** NavSummary context avoids prop-drilling and duplicate polling
- **ANT-F13:** Explicit DOMPurify allowlist with solid test suite
- **ANT-F14:** Well-organized CSS custom property system under `.theme-dark`

---

## Reviewer: Codex (GPT-5.3-Codex) (CDX)

**Findings: 4 SIGNIFICANT | 3 MINOR | 2 STRENGTH**

### Tool Execution

Codex executed 26 commands in read-only sandbox:
1. **Type checking:** `tsc --noEmit` on both `packages/web` and `packages/api` — both passed clean (exit 0)
2. **Test suite:** `npm run test` failed with `EPERM` — Vitest attempted to write `.vite-temp/` files, blocked by read-only sandbox
3. **Source verification:** Read 16 source files with `nl -ba` to verify function signatures and component interfaces
4. **Repo inventory:** `rg --files` for file discovery
5. **CSS inspection:** Searched for theme variable definitions, verified CSS class usage

### CDX-F1 [SIGNIFICANT] — ServiceGrid cards not keyboard-accessible
**File:** ServiceGrid.tsx:97
Expand/collapse uses clickable `<div>` with no keyboard semantics.
**Fix:** Use `<button>` or add `role="button"`, `tabIndex={0}`, `onKeyDown`, and `aria-expanded`.

### CDX-F2 [SIGNIFICANT] — Polling race condition (AbortController missing)
**File:** usePolling.ts:22
Converges with ANT-F3. Requests not cancelled, older responses can overwrite newer state.

### CDX-F3 [SIGNIFICANT] — Silent error swallowing with stale data
**File:** OpsPage.tsx:30
Converges with ANT-F1. Errors only shown when `!data`.

### CDX-F4 [SIGNIFICANT] — SafeMarkdown allows arbitrary img src URLs
**File:** SafeMarkdown.tsx:23
Untrusted content can include third-party tracking beacons or requests to internal endpoints.
**Fix:** Restrict image sources or disallow `img` entirely. Add URI-policy tests.

### CDX-F5 [MINOR] — No catch-all route in App.tsx
**File:** App.tsx:19
Unknown paths render empty main area.
**Fix:** Add `<Route path="*" element={<Navigate to="/attention" replace />} />`.

### CDX-F6 [MINOR] — Undefined CSS vars for timeline dot glow
**File:** Timeline.tsx:118
`--timeline-dot-${dotType}` vars referenced but not defined in theme.

### CDX-F7 [MINOR] — Test coverage gaps
**File:** SafeMarkdown.test.tsx
Missing: `javascript:`/`data:` URI tests, polling lifecycle tests, keyboard/ARIA tests.

### Strengths
- **CDX-F8:** All referenced functions/components exist with compatible signatures (tsc clean)
- **CDX-F9:** DOMPurify allowlist approach is solid baseline XSS defense

---

## Cross-Reviewer Convergence

| Finding | ANT | CDX | Convergence |
|---------|-----|-----|-------------|
| Stale data on polling error | ANT-F1 | CDX-F3 | Full convergence |
| AbortController missing | ANT-F3 | CDX-F2 | Full convergence |
| SafeMarkdown URI concerns | ANT-F2 | CDX-F4 | Partial (ANT: scheme, CDX: img src) |
| Accessibility gaps | ANT-F9 | CDX-F1 | Complementary (ANT: nav ARIA, CDX: keyboard on cards) |
| Test coverage gaps | ANT-F8 | CDX-F7 | Complementary |
| DOMPurify allowlist strength | ANT-F13 | CDX-F9 | Full convergence |

**Unique to Anthropic:** NavRail badge/dot overlap (ANT-F7), formatRefreshAge staleness (ANT-F4), concurrent fetch guard (ANT-F6), Google Fonts render-blocking (ANT-F10), vitest jest-dom setup (ANT-F15), CSS custom property strength (ANT-F14), NavSummary context strength (ANT-F12)

**Unique to Codex:** ServiceGrid keyboard accessibility (CDX-F1), catch-all route missing (CDX-F5), timeline CSS var undefined (CDX-F6), tsc verification of all referenced interfaces (CDX-F8)
