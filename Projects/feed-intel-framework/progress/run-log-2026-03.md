---
type: run-log
project: feed-intel-framework
domain: software
created: 2026-02-23
updated: 2026-03-26
---

# Feed Intel Framework — Run Log

> **Archives:**
> - [[run-log-phase1]] — SPECIFY + PLAN + M1
> - [[run-log-2026-02]] — M2 X Adapter Migration, spec amendment, DB schema, migration, CLI runner, RSS implementation (2026-02-24 through 2026-02-27)

## 2026-03-26 — FIF-043 gate evaluation: PASS → M5 complete

**Summary:** 7-day soak gate (2026-03-20 → 2026-03-26) evaluated. All criteria met. M5 milestone complete. Phase 1 scope (M1–M5) finished.

**Soak results:**
- 7 consecutive clean days, 0 errors across 56 adapter runs (8 runs/day × 7 days)
- All 5 adapters (X, RSS, YouTube, HN, arXiv) running concurrently every day
- Monthly projected cost: $7.19/mo (well under $15 ceiling)
- Daily cost range: $0.15–$0.33
- Reddit excluded per FIF-043 AC (API credentials pending Reddit developer approval)

**§14 success criteria:**
- §14.1 (adapter plugs in without infra changes): PASS — proven across 5 adapters
- §14.2 (per-source digests at cadence): PASS — all sources capturing daily
- §14.3 (per-source cost tracking): PASS — cost_log tracks per-adapter
- §14.5 (monthly cost under $15): PASS — $7.19/mo
- §14.4 (disable adapter stops activity): previously verified during M4
- §14.6 (independent source evaluation): PASS — per-source digest + dashboard
- §14.7 (cross-source URL collision): previously verified during M3
- §14.8 (web UI): deferred to M-Web (not in Phase 1 scope)

**Reddit status:** Adapter code complete (FIF-041), API app pending Reddit's Responsible Builder Policy review. Will soak separately when approved.

**Decision:** Project transitions to DONE. M6 (per-source enrichment) and M7 (research integration) remain deferred as Phase 2 scope — would be a new project if/when pursued.

**Compound:** No novel patterns. The 5-adapter soak confirms the injectable deps pattern scales cleanly — zero shared infrastructure changes across all 5 adapter implementations.

## 2026-03-20b — FIF-043 soak clock started (5 adapters)

**Summary:** Started 7-day stabilization soak for FIF-043. Reddit API app submitted to Reddit but pending approval (new developer review process via Responsible Builder Policy). Proceeding with Option A: 5-adapter soak (X, RSS, YouTube, HN, arXiv) now; Reddit joins when approved.

**Actions:** Rebuilt from latest source (clean), restarted all 3 services (capture, attention, feedback). 2886 tests passing, 0 failing.

**Reddit API status:** Form submitted. Reddit now requires Responsible Builder Policy acknowledgment + developer form for new script apps. Our use case (passive read-only subreddit monitoring) doesn't fit Devvit, so the traditional API path applies. Awaiting approval.

**Soak gate criteria (FIF-043):** 7 consecutive clean days, all active adapters. Clock: 2026-03-20 → evaluate 2026-03-27. If Reddit approved during soak, restart clock with 6 adapters.

**Compound:** Reddit's API onboarding has changed materially since the 2023 pricing controversy — script apps now require a Responsible Builder Policy form with manual review, and Devvit is the default path for new developers. FIF-040's research (which found "no pre-approval needed") was accurate for the API terms themselves but missed the app creation gate. The adapter code is ready; only the credential provisioning is blocked. No compoundable pattern — this is a one-time external dependency.

## 2026-03-20 — FIF-040 (Reddit Phase 0) PASSED + FIF-041 (Reddit adapter) implemented

**Summary:** Completed Reddit Phase 0 API terms gate and built the full Reddit adapter. 97 new tests, 2761 total passing. Clean build.

**FIF-040 Reddit Phase 0 — API terms gate (PASSED):** Researched Reddit's current API terms. Free tier for personal-use "script" app type remains available: 100 QPM (OAuth authenticated), no pre-approval needed, all endpoints accessible (`/r/{subreddit}/*`, `/user/{username}/saved`, `/search`). OAuth 2.0 password grant (no refresh token rotation — simpler than X's PKCE flow). User-agent format required: `<platform>:<app_id>:<version> (by /u/<username>)`. RSS fallback not needed — full API access available.

**FIF-041 Reddit adapter:** Standard tier (self-posts have full_text, link posts excerpt-only). Both pullCurated (saved posts via OAuth) and pullDiscovery (subreddit monitoring). `reddit:{post_id}` canonical_id (t3_ prefix stripped per spec §7.3). OAuth 2.0 password grant with 1-hour token caching. NSFW filtering, crosspost detection (needs_context), courtesy delay between subreddit fetches. 97 tests covering normalizer (link posts, self-posts, engagement, URL hashing, excerpts, domain extraction, crosspost detection) and adapter factory (discovery, curated, dedup, error isolation, NSFW skip, pagination cursor, t1 comment filtering).

**Files created:**
- `adapters/reddit.yaml` — manifest (standard tier, OAuth credentials)
- `adapters/preambles/reddit.md` — triage guidance (bimodal quality, subreddit context weighting)
- `adapters/config/reddit-subreddits.yaml` — 6 target subreddits per spec §7.3
- `src/adapters/reddit/index.ts` — factory with pullDiscovery + pullCurated
- `src/adapters/reddit/normalizer.ts` — UnifiedContent conversion
- `src/cli/deps/reddit-api.ts` — production OAuth + API wrapper
- `test/reddit-adapter-test.ts` — 97 tests

**Capture clock wiring:** Reddit adapter registered in `capture-clock.ts` with topic config loading, guardrail integration, and credential-absent graceful degradation (curated disabled when username not set). Attention clock picks it up automatically via `loadAllManifests`.

**Pre-production requirements:**
1. Create Reddit script app at reddit.com/prefs/apps
2. Add credentials to `~/.config/fif/env.sh`: `REDDIT_CLIENT_ID`, `REDDIT_CLIENT_SECRET`, `REDDIT_USERNAME`, `REDDIT_PASSWORD`
3. Build + restart services
4. First capture on next 06:00 cycle

**Remaining M5:** FIF-043 (stabilization gate — 7-day concurrent soak with all 6 adapters running).

**Compound:** Reddit adapter followed the exact same groove as HN and arXiv — the injectable deps pattern continues to pay off. The only structural difference is Reddit having both pullCurated (saved posts, like X bookmarks) and pullDiscovery (subreddit monitoring, like HN front page). OAuth password grant is simpler than X's PKCE flow — no refresh token rotation needed, just re-authenticate each run with a 1-hour cached token. The adapter pattern is now proven across 5 implementations (X, RSS, YouTube, HN, arXiv, Reddit) with zero shared infrastructure changes required for each new adapter. M5 implementation risk is fully retired — only the soak gate remains.

## 2026-03-12 — M4 closed, FIF-039 (HN) + FIF-042 (arXiv) implemented

**Summary:** Closed M4 (YouTube) soak gate, built and deployed HN and arXiv adapters. 155 new tests, 1388 total passing.

**FIF-038 YT soak evaluation:** All 5 acceptance criteria passed — 6 consecutive clean days (Mar 7–12), circuit breaker clean (0 consecutive high-error runs, 0% error rate), cost $0.217/6 days (~$1.08/mo projected, within $0.85–$1.60 estimate), no impact on X/RSS pipelines. M4 tasks (FIF-034–038) marked done.

**Calibration note:** 61 total signals today across all sources — manageable volume. Good T1/T2 diversity. X posts are almost exclusively tech; RSS is where the non-tech diversity comes in (confirming preamble recalibration from Mar 10 is working).

**FIF-039 HN adapter:** Lightweight tier, Algolia HN Search API (`front_page` tag), `hn:{objectID}` canonical_id. No auth required. Preamble weights comment quality (descendants) + linked article domain. 77 tests. Files: `adapters/hn.yaml`, `adapters/preambles/hn.md`, `src/adapters/hn/{index,normalizer}.ts`, `src/cli/deps/hn-api.ts`, `test/hn-adapter-test.ts`.

**FIF-042 arXiv adapter:** Standard tier (abstract as full_text), arXiv Search API (Atom XML), `arxiv:{id}` canonical_id (version-stripped for stability). 3-second courtesy delay between queries. Regex-based XML parser (no dependency). Preamble covers category relevance, author reputation, abstract substance. 78 tests. Files: `adapters/arxiv.yaml`, `adapters/preambles/arxiv.md`, `src/adapters/arxiv/{index,normalizer}.ts`, `src/cli/deps/arxiv-api.ts`, `test/arxiv-adapter-test.ts`.

**Capture clock wiring:** Both adapters registered in `capture-clock.ts` with topic config loading and guardrail integration. Attention clock picks them up automatically via `loadAllManifests`. `package.json` test script updated.

**Build + deploy:** Clean build, services restarted (`kickstart -k`). Both adapters will capture on next 06:00 cycle.

**Remaining M5:** FIF-040 (Reddit Phase 0 — API terms gate), FIF-041 (Reddit adapter), FIF-043 (stabilization gate — 7-day concurrent soak after all adapters enabled).

**Compound:** Adapter implementation is now a well-grooved pattern: manifest YAML → preamble → normalizer → adapter factory with injected deps → real API deps → capture-clock wiring → tests. HN and arXiv each took ~15 minutes following the RSS template. The dependency injection pattern (injectable deps for testing, real deps for production) pays off consistently — zero shared infrastructure changes needed for either adapter. The pattern is mature enough that M5 remaining work (Reddit) is primarily an API terms investigation, not an implementation risk.

## 2026-03-11 — RSS + X OAuth root cause fixes, build verification protocol

**Summary:** Diagnosed and fixed two production outages (RSS silent failure, X curated 5-day outage), added build verification to session-end protocol, eliminated LOW items from all surfaces.

**Startup hook fix:** Replaced vault inbox file scan (`_openclaw/inbox/feed-intel-*.md`) with SQLite query against `pipeline.db`. Startup counts now match dashboard — same data source, same 24h window, same tier logic.

**RSS root cause — stale build:** `9347bbc` (Mar 10) renamed `pullCurated` → `pullDiscovery` in TypeScript source, but `dist/` was compiled hours earlier. Capture cycle called `adapter.pullDiscovery`, found `undefined`, silently returned 0 items (by design — line 211-213 of `capture/index.ts` treats missing adapter functions as no-op success). Fix: `npm run build`. RSS captured 315 items on rerun.

**X OAuth root cause — hardcoded refresh token:** `847a70c` (Mar 6) added `X_REFRESH_TOKEN` to `~/.config/fif/env.sh` as static env var. Env var has precedence over Keychain. X refresh tokens are single-use — after one successful refresh, the old token is invalidated and a new one is stored in Keychain. The hardcoded env var overrode the fresh Keychain value on every launchd run. Fix: removed `X_REFRESH_TOKEN` from `env.sh`. Other stable credentials (client ID/secret, API keys) remain. Verified: reauthed, ran `getAccessToken()` with fixed env sourced — success, refresh token rotated in Keychain. X curated pulled 200 bookmarks (first success since Mar 6).

**Build verification protocol (session-end step 5):** New step between code review sweep and AKM feedback. If source files were modified in a project with `build_command` in `project-state.yaml`, run the build and restart `services`. Self-healing: detects missing `build_command`/`services` and backfills from repo state. Added `build_command` and `services` fields to FIF and Mission Control `project-state.yaml`. Updated CLAUDE.md project creation (step 3b/3c) to capture these fields at creation and deploy time.

**LOW items eliminated from all surfaces:** Filtered `json_extract(triage_json, '$.priority') IN ('high', 'medium')` in dashboard SQL query (`fif-sqlite.ts`), removed T3 from KPI component (`PipelineKpis.tsx`), filtered startup hook query. Dashboard rebuilt, service restarted. Verified: 82 signals (12 HIGH + 70 MEDIUM), zero LOW.

**Production rerun:** Capture clock: RSS 315 items + X curated 200 items. Attention clock: RSS 7H/44M, X 5H/16M. 9 items routed to vault. Digests delivered (4+2+1 parts).

**Compound:** "Static env vars for rotating credentials" is a general anti-pattern — any credential that rotates on use (OAuth refresh tokens, TOTP seeds) must come from a mutable store (Keychain), never a static file. The env var fallback pattern (`process.env.X || getSecret(X)`) is correct for stable credentials but creates a precedence trap for rotating ones. Pattern recorded in `memory/fif-operations.md`.

## 2026-03-10 — Digest volume reduction, RSS rename, dashboard fixes, X reauth

**Summary:** Multi-area session spanning FIF pipeline, dashboard, and X OAuth.

**Digest volume:** Removed LOW priority items from Telegram digest entirely (`src/digest/index.ts`). Cutoff cursor still advances past them. LOW items now triaged exclusively via Mission Control intel page. Committed `0b0a159`.

**RSS pullCurated → pullDiscovery rename:** RSS has no curated component (only X bookmarks are manually curated). Renamed across adapter (`src/adapters/rss/index.ts`), manifest (`adapters/rss.yaml`), and 7 test files. Disabled phantom YT curated schedule. Committed `9347bbc`.

**RSS triage preamble rewrite:** Recalibrated `adapters/preambles/rss.md` for non-tech diversity. RSS is the diversity engine — 50% non-tech target for MEDIUM+, news defaults to MEDIUM, expanded cross-domain tag guidance. Committed with `0b0a159`.

**Dashboard fixes (crumb-dashboard repo):**
- Sources tile scoped to 7-day window instead of all-time (`fif-sqlite.ts`). Committed `b9580fb`.
- Pipeline health backlog scoped to 7-day TTL (`pipeline-health.ts`). Uncommitted — pending next dashboard commit.

**X OAuth reauth:** Built `src/cli/x-reauth.ts` — PKCE flow with local callback server for re-authorization when the single-use refresh token chain breaks. Added `npm run x:reauth` script. Successfully reauthorized — X curated pipeline restored.

**Intel page review:** Walked through all dashboard sections: Pipeline KPIs, Pipeline Health (circuit breaker semantics, 7-day rolling window), Signal Digest, Tuning (blocked), Production Analytical Output (blocked M6).

**Compound:** Documented X OAuth reauth flow and dashboard health panel mechanics in `memory/fif-operations.md`.

## 2026-03-09 — Digest cutoff fix + noise reduction

**Summary:** Fixed two digest issues in `src/digest/index.ts`. (1) Cutoff cursor now uses max `triaged_at`/`queued_at` from included posts instead of `now()` — prevents edge cases where posts triaged after digest generation could be re-included in the next run. (2) Collapsed LOW and TRIAGE FAILED sections in Telegram digest to count-only lines (e.g., `⚪ 83 low-priority items filed`). Reduces message volume significantly — today's 8-part RSS digest would be ~2-3 parts. Tests updated (172 pass). Committed `7641aba`.

**Investigation:** Reported March 8 digest "resend" on March 9 was not an actual resend — `digest_messages` table confirmed single delivery per date. March 9 RSS had 121 genuinely new items. The noise issue (122 items across 8 Telegram parts) motivated the LOW/FAILED collapse.

**Calibration note:** Feed pipeline circuit breaker fired for first time (14 T1 items > 10 threshold). Confirmed classifier drift: 10 arXiv papers identically classified `high/high/capture`. Upstream triage model may need arXiv-specific confidence tuning.

## Session 2026-03-01 — Feed Pipeline Phase 1 Foundation

### Context
Implementing the feed-intel processing pipeline that bridges FIF triage output
in `_openclaw/inbox/` to the vault knowledge base. Phase 1 creates the
foundational artifacts: signal-note type, feed-pipeline skill, startup scan,
vault-check rules, calibration tracker.

### Context Inventory
- `_system/docs/file-conventions.md` — type taxonomy, knowledge-note schema pattern
- `_system/docs/kb-to-topic.yaml` — tag-to-MOC mapping
- `.claude/skills/inbox-processor/SKILL.md` — skill structure pattern
- `_system/scripts/session-startup.sh` — startup hook for scan integration
- `_system/scripts/vault-check.sh` — validation rule patterns (Check 20 as template)
- `_openclaw/inbox/feed-intel-*.md` — sample items (2 read for structure)
- `Projects/feed-intel-framework/project-state.yaml` — current project state

### Deliverables

**signal-note type** — Added to `_system/docs/file-conventions.md`:
- New type in taxonomy table
- Full schema section with frontmatter template, source_id algorithm, body structure
- Lightweight capture designed for thin feed-intel items (~280-char excerpts)
- Promotion path to full knowledge-note documented

**feed-pipeline skill** — Created `.claude/skills/feed-pipeline/SKILL.md`:
- Three-tier routing (Tier 1: auto-promote, Tier 2: action extraction, Tier 3: TTL skip)
- model_tier: reasoning (permanence evaluation requires vault-context judgment)
- Context contract: file-conventions.md + kb-to-topic.yaml + inbox contents
- Seven-step procedure covering scan, tier 2 actions, tier 1 evaluation, auto-promote,
  review queue, and calibration logging
- Backlog vs steady-state modes defined

**vault-check rules** — Added Check 25 (Signal-Note Schema Validation) to vault-check.sh:
- Validates: location (Sources/signals/), schema_version, source subfields (source_id,
  title, author, source_type, canonical_url, date_ingested), provenance subfields
  (inbox_canonical_id, triage_priority, triage_confidence), topics field, kb/ tag presence
- Modeled after Check 20 (source-index validation) pattern

**startup scan** — Added feed-intel inbox scan to session-startup.sh:
- Counts feed-intel items, classifies by tier via frontmatter-only reads
- Reports in structured data section and startup summary display block
- Tested: 221 items → T1:118, T2:57, T3:46 (matches plan analysis exactly)

**Sources/signals/** — Created directory with .gitkeep

**calibration tracker** — Created `_system/docs/feed-pipeline-calibration.jsonl` (empty)

### Verification
- vault-check: 0 errors, 28 warnings (all pre-existing)
- Check 25 ran cleanly (0 signal-notes to validate — correct for Phase 1)
- Startup scan produces correct tier counts matching plan analysis

### Code Review — manual Phase 1 Foundation
- Scope: 7 files, +549/-2 (commit 22d4665)
- Panel: Codex GPT-5.3-Codex (Opus skipped — billing)
- Codex tools: bash -n (pass), vault-check.sh (sandbox blocked), session-startup.sh (pass), rg, find, nl
- Findings: 0 critical, 4 significant, 3 minor, 2 strengths
- Consensus: N/A (single reviewer)
- Details:
  - [CDX-F1] SIGNIFICANT: session-startup.sh:170 — head -15 truncation risk
  - [CDX-F3] SIGNIFICANT: vault-check.sh:1462 — subfield checks not scoped to YAML blocks
  - [CDX-F4] SIGNIFICANT: vault-check.sh:1501 — signal-note scan limited to Sources/Projects
  - [CDX-F7] SIGNIFICANT: SKILL.md:79 — TTL script referenced but doesn't exist (Phase 2)
- Action: A1 fixed (head -20), A3 fixed (scan dirs expanded), A4 fixed (Phase 2 annotation). A2 deferred (systemic YAML parser limitation).
- Review note: Projects/feed-intel-framework/reviews/2026-03-01-code-review-manual.md

### Compound
- **Convention confirmed:** vault-check validation pattern (Check 20 → Check 25) is a reliable template for new document types — extract_frontmatter + type filter + subfield grep. Systemic limitation: bash YAML parsing can't scope to nested blocks. Noted in CDX-F3 deferral.
- **Pattern:** Startup scan tier classification using frontmatter-only reads is fast (~2-3s for 221 items) and accurate. Same pattern could apply to future inbox types beyond feed-intel.
- **Primitive gap:** No compoundable primitive gaps — feed-pipeline skill fills the identified gap.

## Session 2026-03-01 — Triage Failure Recovery + FIF-029 Gate Pass

### Context
FIF-029 parity soak (Feb 26–Mar 1) disrupted by 3-day Anthropic API outage (Feb 26–28). 388 items stuck in `triage_failed` with no retry path. API recovered Mar 1. This session fixes the resilience gap and closes the parity gate.

### Context Inventory
- `src/triage/index.ts` — writeTriageResults, markTriageFailed, DB operations
- `src/cli/attention-clock.ts` — per-source triage loop
- `test/triage-test.ts` — triage engine tests
- `state/pipeline.db` — production DB (388 stuck items verified)
- `state/pipeline.log` — pipeline run history

### Work Completed

**Triage failure recovery (commit 927c4fa, pushed):**
- `writeTriageResults`: failStmt now stores error JSON (`{ error, failed_at }`) in `triage_json`, increments `triage_attempts`
- `markTriageFailed`: accepts optional `reason` parameter, stores in `triage_json`
- New `resetFailedItems(db, sourceType, maxRetries)`: resets `triage_failed` items with `triage_attempts < MAX_FAILED_RETRIES` (3) back to `pending`
- Wired into attention-clock before deferred retry (step 6b) — reset items picked up same cycle
- 22 new tests (120 total triage tests), all passing

**Manual validation run (DRY_RUN):**
- Reset 185 RSS + 203 X = 388 items (all at triage_attempts=0, as expected)
- 202 successfully triaged this cycle (124 RSS + 78 X)
- 48 remaining failures at triage_attempts=1 — will retry on next 2 cycles
- Full pipeline: capture → triage → route → digest → deliver, both sources, no anomalies

### FIF-029 Gate — PASSED (2026-03-01)
Evidence:
1. **Capture frequency:** Framework capture-clock running on schedule, no gaps post-migration
2. **Triage quality:** Mar 1 runs show normal triage success rates (API recovered); failure recovery mechanism validated live
3. **Digest delivery:** Both X and RSS digests rendered and delivered (DRY_RUN mode)
4. **Feedback:** All 5 commands operational (verified during soak)
5. **Cost:** X $0.09 MTD, RSS $0.15 MTD — within estimates
6. **Vault routing:** 14 X + 13 RSS items routed this cycle, no collision anomalies
7. **Resilience:** 388 stuck items from API outage auto-recovered without manual intervention

Note: The 3-day API outage (Feb 26–28) was an external failure, not a framework regression. The framework's gap was the lack of retry path for `triage_failed` items — now fixed. Parity with legacy pipeline confirmed on all dimensions.

### Housekeeping
- tasks.md: FIF-029 → done, FIF-031 → done (was stale)
- project-state.yaml: active_task → FIF-032, next_action updated

### Compound
- **Transient failure resilience as a design requirement:** The original triage engine treated failure as terminal — reasonable for validation errors but wrong for API outages. The fix is minimal (resetFailedItems is 8 lines of SQL) but the insight is architectural: any queue system needs a retry path for transient failures, separate from permanent failure handling.
- **triage_attempts as a shared counter:** Both deferred retry and failure retry now increment the same counter. This means an item that bounces between deferred and failed states accumulates attempts from both paths — conservative, prevents infinite retry loops across failure modes.

### FIF-032: RSS Integration Test + Enable — DONE

**Validation evidence:**
- Capture: 14 RSS feeds polling on schedule via capture-clock (since FIF-031)
- Triage: 124 RSS items triaged in validation run ($0.17)
- Route: 13 RSS items routed to vault
- Digest: RSS digest rendered with correct formatting (priority sections, tags, excerpts, action/confidence, links), overflow to file at 106KB
- Delivery: Real Telegram delivery confirmed — message ID 13, sent 2026-03-01T12:47:49Z
- Cost: $0.15 MTD, projected $4.65/mo (within $3–6/mo estimate)
- No shared infrastructure changes required

**Note:** Second manual run hit Anthropic credit balance limit (all triage failed, $0.00 cost). Error captured cleanly in `triage_json` by the new error storage — validates both the delivery path and the failure recovery in one run. Credit balance is an ops issue, not framework.

**Operational state:** DRY_RUN=1 still set in launchd plist. RSS is live in the framework but daily digests go to file until DRY_RUN is flipped off. Real Telegram delivery validated via manual run.

### Code Review — Skipped (triage failure recovery, commit 927c4fa)
- Scope: 3 files, +191/-16 — SQL parameter additions, new 8-line function, test updates
- Rationale: Changes are mechanical (SQL bind params, single-query function), well-tested (22 new tests, 120 total passing), and validated live (388 items recovered). No architectural decisions or security surface changes. Risk profile doesn't warrant panel review.

## Session 2026-03-04 — Feed Pipeline Tier 1 Backlog Processing (Batches 1–3)

### Context
First operational run of the feed-pipeline skill against the 365-item inbox backlog.
Processing Tier 1 (auto-promote) items in batches of 20 with operator approval between batches.

### Context Inventory
- `_system/docs/file-conventions.md` — signal-note schema, kb/ tag taxonomy
- `_system/docs/kb-to-topic.yaml` — tag-to-MOC mapping
- `.claude/skills/feed-pipeline/SKILL.md` — skill procedure
- `_openclaw/inbox/feed-intel-*.md` — 365 inbox items (204 T1, 91 T2, 70 T3)
- `Domains/learning/moc-crumb-architecture.md` — MOC for Core placement

### Deliverables

**53 signal-notes created** in `Sources/signals/`:
- All tagged `kb/software-dev` → `moc-crumb-architecture`
- All pass signal-note schema (type, schema_version, source subfields, provenance, topics)
- Source types: all tweets (X feed intel)
- Topics covered: agent architecture, memory systems, security, MCP, skill design,
  multi-agent orchestration, context engineering, vault patterns, safety, RL

**MOC registration** — 53 one-liners added to `moc-crumb-architecture.md` Core section
with `[[source_id|Author: Short Title]] — description | when to use` format.

**Review queue** — `_openclaw/inbox/review-queue-2026-03-04.md` with 7 borderline items:
- 2 hybrid durability (version-specific fix, overlap)
- 1 timely product demo
- 1 model release announcement
- 1 thin content / aspirational
- 1 tangential (creative visualization)
- 1 same-author overlap

**53 inbox items deleted** (promoted sources removed from `_openclaw/inbox/`)

### Observations
- All 53 items mapped to a single MOC (`moc-crumb-architecture`) — the X feed is heavily
  skewed toward agent/software architecture content. Future batches may surface other domains.
- The MOC Core section is now very large (~62 entries). Consider splitting into subsections
  (e.g., Signals subsection) or creating a dedicated signal-notes MOC when the count grows further.
- Batch processing is efficient but context-heavy — 3 batches of 20 consumed significant
  context window. Steady-state (10-20 items) will be lighter.
- ~141 T1 items remain. T2 (91) and T3 (70) untouched.

### Compound
- **Convention confirmed:** feed-pipeline skill procedure works as designed for backlog mode.
  The three-question permanence evaluation (durable/timely, kb/ mapping, dedup) is effective
  for routing — 88% auto-promote rate with clear justification for review-queue items.
- **Pattern emerging:** MOC Core section may need a structural evolution for signal-notes at
  scale. Current flat list works at 62 entries but will become unwieldy at 200+. Options:
  subsection by source_type, subsection by signal topic cluster, or dedicated signals MOC.
- **No primitive gaps identified** — skill, schema, and MOC integration all worked end-to-end.

## Session 2026-03-04b — Feed Pipeline T1 Backlog Completion (Batch 8)

### Context
Continuation session to clear remaining T1 backlog. Previous session (batches 1–7) promoted
122 signal-notes from ~204 T1 items. This session processes the remaining 48 unique T1 items
after dedup cleanup.

### Context Inventory
- `_system/docs/file-conventions.md` — signal-note schema, kb/ tag taxonomy
- `_system/docs/kb-to-topic.yaml` — tag-to-MOC mapping
- `.claude/skills/feed-pipeline/SKILL.md` — skill procedure
- `_openclaw/inbox/feed-intel-*.md` — 232 inbox items at session start
- `Domains/Learning/moc-signals.md` — signals MOC (122 entries at session start)

### Deliverables

**Dedup cleanup** — 52 old-format duplicate inbox files removed:
- 22 files matching already-promoted signal-notes (old format `feed-intel-NNNN.md`
  duplicating new format `feed-intel-x:NNNN.md` already processed in batches 1–7)
- 30 files with both old and new format variants in inbox (old format deleted, new kept)

**22 signal-notes created** in `Sources/signals/`:
- Topics: safety/permissions (4), MCP patterns (4), vault-as-OS (3), multi-agent (3),
  cost/optimization (2), failure modes (2), research/analysis (2), task management (1),
  agent interfaces (1)
- All tagged `kb/software-dev` → `moc-signals`
- All pass vault-check schema validation

**26 items routed to review queue** (`review-queue-2026-03-04-batch8.md`):
- 7 MCP connector promotional cluster (Linear→Gamma→Slack pattern)
- 8 thin/promotional (testimonials, crypto tokens, aspirational, polls)
- 3 overlap with existing signals
- 2 Grok 4.20 timely product releases (best one promoted)
- 6 other borderline (GLM-5 hybrid, digital garden, generic overviews)

**MOC updated** — 22 new Core entries in `moc-signals.md` (now 144 total)

**Vault-check errors fixed** — added missing Compound fields to:
- `Projects/book-scout/progress/run-log.md` (IMPLEMENT → DONE transition)
- `Projects/active-knowledge-memory/progress/run-log.md` (TASK → DONE transition)

### Verification
- vault-check: 0 errors, warnings only (pre-existing)
- Inbox: 129 items remaining (T1:0, T2:73, T3:56)
- T1 backlog fully cleared

### Compound
- **Convention confirmed:** Dedup-before-processing is essential for multi-format inbox. The
  FIF migration left old-format (`feed-intel-NNNN.md`) and new-format (`feed-intel-x:NNNN.md`)
  files for the same tweets with different triage metadata. Future: the capture pipeline should
  clean old-format files when new-format is written.
- **Pattern:** Auto-promote rate declines as backlog is processed (88% batches 1–7 → 46% batch 8).
  The highest-signal items are processed first, leaving more borderline content. This is expected
  and healthy — the permanence evaluation is doing its job.
- **Observation:** MCP connector promotional content forms a distinct cluster (7 items, all
  nearly identical Linear→Gamma→Slack workflows). Triage confidence was high for all of them
  individually, but the cluster represents low marginal value. Triage could benefit from
  cross-item dedup awareness.

## Session 2026-03-04c — T2 Backlog Re-Triage

### Context
T2 backlog (73 items with `recommended_action: test` or `add-to-spec`) contained almost no
genuinely actionable test/spec items. The FIF triage engine over-classified — most items were
either durable signal-notes (agent architecture patterns) or noise (product ads, thin tweets,
crypto shills). Re-triaged all 73 as T1a/T1b/T3 instead of extracting actions.

### Context Inventory
- `_system/docs/file-conventions.md` — signal-note schema, kb/ tag taxonomy
- `_system/docs/kb-to-topic.yaml` — tag-to-MOC mapping
- `.claude/skills/feed-pipeline/SKILL.md` — skill procedure
- `_openclaw/inbox/feed-intel-*.md` — 73 T2 items (all read in full)
- `Domains/Learning/moc-signals.md` — MOC (144 entries at session start)
- `Sources/signals/` — existing 144 signal-notes (canonical_id dedup check)

### Deliverables

**22 signal-notes created** in `Sources/signals/`:
- Agent architecture: filesystem-as-state, memory retrieval, vault-to-agent prompting,
  Stripe blueprint engine, Openfang agent OS, Virtual Biotech multi-agent
- Context/memory: Context Mode (94% savings), MIT 10M+ context, OneContext cross-session,
  memelord RL pruning, memory-as-retrieval
- Tools: agent-papers-cli, dmux agent swarms, browser sandbox, MarkItDown MCP,
  Readout session replay, Obsidian CLI orphans
- Standards: agent auth framework (WIMSE+OAuth), Automation Model (website-as-API),
  HumanMCP benchmark (2800 tools)
- Orchestration: Claude-Codex orchestration, multi-agent Python deployment
- All tagged `kb/software-dev` (one also `kb/security`) → `moc-signals`

**MOC updated** — 22 new Core entries in `moc-signals.md` (now 166 total)

**Dedup cleanup** — 9 items deleted:
- 4 old-format/new-format duplicate inbox files
- 2 items already promoted in T1 batches (matching canonical_id)
- 3 content-redundant items (same topic as existing signals)

**20 items reclassified as skip** — thin content, product ads, crypto shills, niche tools

**20 items in review queue** (`review-queue-2026-03-04-t2.md`):
- 5 content overlaps with existing signals
- 4 timely/product news items
- 4 thin content needing repo evaluation
- 3 truncated/video content (can't assess)
- 4 borderline promote candidates (claude-subconscious, NanoClaw, AprielGuard, WebSocket)

### FIF Triage Quality Issue
The `recommended_action: test` and `add-to-spec` classifications are poorly calibrated:
- **0 of 73 T2 items** had a genuine, concrete `test` or `add-to-spec` action
- Most items were agent architecture patterns (→ signal-notes) or promotional content (→ skip)
- The triage engine appears to assign `test`/`add-to-spec` based on tag matching
  (`tool-discovery` → `test`, `pattern-insight` → `add-to-spec`) rather than content analysis
- **Recommendation:** Update Tess's triage prompt to distinguish between "this tool exists"
  (→ capture for signal-note) and "we should test this tool in our stack" (→ genuine test action).
  Similarly, "this pattern is interesting" should be `capture`, not `add-to-spec`.

### Verification
- vault-check: 0 errors, 16 warnings (pre-existing)
- Check 25: 169 signal-notes validated, 0 issues
- Inbox: 75 items remaining (T1:0, T2:20 review queue, T3:55)

### Compound
- **Convention confirmed:** Re-triage of incorrectly-classified items works well as a batch
  process. Reading all items, classifying, presenting to operator, then executing is efficient
  for corrective processing.
- **Pattern:** Triage `recommended_action` values are the least reliable field in the FIF
  output. Priority and confidence are generally accurate; action classification needs a
  separate prompt pass or clearer criteria in Tess's triage instructions.
- **Observation:** After T1 and T2 processing, the signal-note corpus (166 items) skews
  heavily toward agent architecture / software-dev content. This reflects the X feed
  composition rather than a pipeline bias — RSS feeds contribute more diverse content.
  Topic diversification will come with non-software feed sources.

### Housekeeping Note — Missed project-state.yaml Update
Sessions 2026-03-04b through 2026-03-04d completed the full inbox clearing (184 signal-notes,
0 items remaining) and triage quality fix, but `project-state.yaml` `next_action` was not
updated. It still referenced T1 backlog processing. Fixed 2026-03-04 in the next session.

## Session 2026-03-04d — T3+T2 Final Sweep + Triage Quality Issue

### Context
Continued from session 2026-03-04c. 75 items remained in inbox (20 T2, 55 T3).
Previous session processed T2 re-triage batch but left the full inbox for a second pass.
Goal: clear the inbox entirely and address the FIF triage quality issue.

### Context Inventory
- `_openclaw/inbox/feed-intel-*.md` — all 75 remaining items (read in full)
- `Sources/signals/` — 166 signal-notes (dedup cross-reference)
- `Domains/Learning/moc-signals.md` — MOC (166 entries at session start)
- `_system/docs/feed-pipeline-calibration.jsonl` — calibration tracker
- `.claude/skills/feed-pipeline/SKILL.md` — skill procedure reference

### Deliverables

**18 signal-notes created** in `Sources/signals/`:
- Context/retrieval: agentic-filesystem (rohanpaul), stateless-retrieval-critique (burkov),
  naming-precision (Huxpro), hybrid-rag-graphrag (GYWI paper)
- Memory: claude-subconscious (chiefofautism), self-maintained-memory (jonnym1ller),
  hermes-agent-architecture (WesRoth)
- Verification/security: proof-carrying-code (headinthebox), rbac-agent-tooluse (max_paperclips)
- Infrastructure: websocket-agentic (code_rams), obsidian-headless-sync (TfTHacker),
  toolkit-architecture-sprawl (avm_codes), obsidian-cli-agents (Techjunkie_Aman)
- Reference: everything-claude-code (dunik7), nanoclaw (aiwithjainam),
  agentic-coding-dataset (ZainHasan6), multiagent-code-review (rozzabuilds),
  nonengineering-claude-code (businessbarista)

**57 items deleted from inbox:**
- 44 skip: MCP connector demos (15+), product ads, thin tweets, Julia Evans blogs,
  crypto/DeFi, generic advice
- 10 borderline→skip: truncated content, thin assertions, product announcements
- 3 dup: @Dobrenkz, @fogoros, @0xSero (already in signal-notes)

**Inbox cleared** — 0 feed-intel items remaining

**MOC updated** — 18 new Core entries in moc-signals.md (now 184 registered)

### Calibration
- Calibration entry added to feed-pipeline-calibration.jsonl
- 75 items → 18 promoted (24%), 57 deleted (76%)
- MCP connector demo saturation: ~15 items were variations of the same "I connected Claude to Linear+Gamma+Slack" workflow

### Verification
- All 18 signal-notes follow schema (frontmatter, source block, provenance)
- Inbox: 0 feed-intel items remaining
- Signal-notes on disk: 187 files (184 registered in MOC + 3 unregistered legacy)

### FIF Triage Quality Fix

**Root cause:** x-feed-intel spec §5.5.1 `recommended_action` definitions were too broad:
- `test` ("a tool or technique worth trying") → Tess assigned to ANY tool mention
- `add-to-spec` ("a pattern that could change architecture") → Tess assigned to ANY architectural pattern

**Evidence:** Across two processing sessions (73 T2 items in session c, 20 T2 in session d),
**0 of 93 T2 items** had a genuinely actionable `test` or `add-to-spec` action. All were either
signal-notes (`capture`) or noise (`ignore`/`read`).

**Fix applied to `Projects/x-feed-intel/design/specification.md`:**
1. **§5.5.1 field definitions** — Tightened `test` and `add-to-spec` with explicit disambiguation:
   - `capture` is now marked as the **default** for anything interesting
   - `test` requires a **specific integration point already identified** in our stack
   - `add-to-spec` requires referencing a **concrete spec section** to modify
2. **Triage prompt skeleton** — Added "Action Selection Guide" section with:
   - 5 concrete examples showing correct action selection
   - Expected distribution guidance: ~70% capture, ~15% read, ~10% ignore, ~5% test/add-to-spec
   - Explicit warning: if >2 items per batch get test/add-to-spec, reconsider

**Expected impact:** T2 tier should shrink from ~25% of inbox to <5%. Items previously
misclassified as T2 will correctly become T1 (capture) or T3 (read/ignore), improving
signal-note promotion accuracy and eliminating the action extraction dead-end.

**Validation needed:** Next triage batch should show the new distribution. Add a calibration
check to the next feed-pipeline run to verify T2 count dropped.

### Compound
- **Pattern confirmed:** Triage `recommended_action` is the least reliable field — now fixed
  at source. The tag and priority/confidence fields were generally accurate throughout.
- **Convention:** When triage quality issues surface in pipeline processing, trace upstream to
  the prompt definitions rather than working around downstream. The fix was 2 edits to the spec,
  not a change to the feed-pipeline routing logic.
- **Observation:** MCP connector demo saturation — ~20% of the inbox was variations of the same
  "I connected Claude to Linear+Gamma+Slack" pattern. May warrant a dedup heuristic in the
  triage prompt (if similar items already appeared in recent batches, lower confidence).
- **Inbox fully cleared:** 184 signal-notes in MOC, 187 on disk. All feed-intel items processed.
  Pipeline is ready for fresh intake.

## Session 2026-03-04f — M4 YouTube Adapter Implementation + Code Review

### Context
M4 adds YouTube as the third content source — the first "heavy-tier" source requiring
summarize-then-triage pipeline. Five tasks (FIF-034 through FIF-038) covering shared
heavy-tier triage infrastructure, YouTube adapter with circuit breaker resilience,
integration testing, and code review with all findings addressed.

### Context Inventory
- M4 implementation plan (plan file)
- Existing adapter patterns: `src/adapters/rss/` (normalizer + factory)
- Shared infrastructure: `src/triage/index.ts`, `src/capture/index.ts`, `src/shared/types.ts`
- CLI entry points: `src/cli/attention-clock.ts`, `src/cli/capture-clock.ts`
- Test patterns: `test/integration-test.ts`, `test/rss-adapter-test.ts`

### Deliverables

**FIF-034 (Research)** — Skipped (decisions embedded in plan: youtube-transcript lib, API key only, no OAuth).

**FIF-035 (Heavy-Tier Triage Engine):**
- `src/triage/index.ts` — `SummarizeFn` type, summarize step between preparation and batching,
  `logSummarizeCost()` with `subcomponent: 'summarize'`, `markSummaryGenerated()` flag
- `src/cli/deps/summarize-llm.ts` — Haiku 4.5 summarize via Anthropic API,
  `truncateWithHeadings()` with heading-preserving pre-truncation
- `src/cli/attention-clock.ts` — wired `summarizeFn` for heavy-tier sources
- `test/heavy-triage-test.ts` — 24 tests

**FIF-036 (YouTube Adapter):**
- `src/adapters/yt/normalizer.ts` — video+transcript → UnifiedContent, ISO 8601 duration parser
- `src/adapters/yt/index.ts` — adapter factory with circuit breaker (shared state, bounded
  pagination, chunked video details, jittered transcript fetching)
- `src/cli/deps/yt-api.ts` — YouTube Data API v3 + youtube-transcript library
- `adapters/yt.yaml` — manifest (heavy tier, enabled)
- `adapters/config/yt-topics.yaml` — 5 topic areas, 10 queries
- `src/cli/capture-clock.ts` — registered YT adapter
- `test/yt-adapter-test.ts` — 73 tests

**FIF-037 (Preamble + Integration Test):**
- `adapters/preambles/yt.md` — YouTube triage preamble
- `test/yt-integration-test.ts` — 28 tests, full pipeline (capture→dedup→triage→route→digest→cost)

**FIF-038 (Enable + Verify):** `enabled: true` in `yt.yaml`. Full suite green.

### Code Review — M4 Milestone (FIF-035–038)
- Scope: 14 files, +2107/-12 lines (commit pre-review)
- Panel: Claude Opus 4.6 (API), GPT-5.3-Codex (CLI)
- Codex tools: tsc (pass), npm test (sandbox blocked), heavy-triage-test (pass),
  yt-adapter-test (pass), yt-integration-test (exit 1), rg (x6), nl (x12)
- Findings: 1 critical, 7 significant, 13 minor, 6 strengths
- Consensus: 3 findings + 2 strengths converged across reviewers
- Details:
  - [ANT-F2+CDX-F1] CRITICAL: Circuit breaker split state + error path bypass — **FIXED**
  - [CDX-F2] SIGNIFICANT: Missing playlist pagination — **FIXED**
  - [CDX-F3] SIGNIFICANT: Missing video ID chunking (API max 50) — **FIXED**
  - [ANT-F4] SIGNIFICANT: API key in URL unencoded, leaks in errors — **FIXED**
  - [ANT-F5] SIGNIFICANT: Duplicated pull loop bodies — **FIXED** (processVideoIds helper)
  - [ANT-F6+CDX-F6] SIGNIFICANT: truncateWithHeadings drops headings — **FIXED**
  - [ANT-F3] SIGNIFICANT: Fail-fast API key resolution — **FIXED** (lazy)
  - 13 minor findings deferred (low risk)
- Action: All must-fix (1) and should-fix (6) items resolved. 12 new test assertions added.
- Review note: Projects/feed-intel-framework/reviews/2026-03-04-code-review-milestone.md
- Tag: `code-review-2026-03-04`

### Verification
- Full suite: 2,606 assertions, 30 test files, 0 failures
- Type-check: clean (tsc --noEmit)
- Committed: `323ffea`

### Compound
- **Convention confirmed:** Code review at milestone boundary caught 1 critical and 6 significant
  issues before production. Circuit breaker unification (ANT-F2+CDX-F1) was the highest-value
  find — two independent reviewers attacked it from complementary angles (split state vs error
  path bypass). Neither alone would have covered both failure modes.
- **Pattern:** `processVideoIds()` extraction (A5) demonstrates that DRY refactoring is safest
  when driven by review findings rather than proactive cleanup — the duplication was intentional
  during initial implementation to keep the two paths independently testable, but review correctly
  identified it as a divergence risk once both paths stabilized.
- **Pattern:** Lazy credential resolution (A7) should be the default for optional pipeline stages.
  Fail-fast is appropriate for required deps (API key for triage) but not for optional deps
  (summarize only fires for heavy-tier sources). Apply this pattern to future optional deps.
- **Reviewer insight:** Codex's tool-grounded findings (pagination, chunking) were high-value
  because they came from actual API inspection, not reasoning. Opus's architectural findings
  (CB split, DRY) required design-level reasoning Codex doesn't do. Complementary pairing
  continues to validate the two-reviewer panel design.

## Session 2026-03-04e — FIF-033 Cross-Source Validation

### Context
FIF-033 closes M3 (RSS adapter milestone). Cross-source collision detection, weekly
aggregate cost summary delivery, and per-adapter signal quality scoring.

### Context Inventory
- `src/router/index.ts` — vault router with collision detection (FIF-011)
- `src/cost/index.ts` — cost telemetry, signal quality, weekly summary generation
- `src/cli/attention-clock.ts` — production entry point
- `src/shared/schema.ts` — DB schema (posts, feedback tables)
- `src/delivery/index.ts` — delivery scheduler
- `src/adapters/rss/normalizer.ts` — RSS url_hash computation
- `test/integration-test.ts` — existing integration test pattern
- `test/router-test.ts` — existing collision detection unit tests

### Deliverables

**Cross-source collision test** (`test/cross-source-test.ts`) — 54 tests, all passing:
- URL hash consistency: same URL produces identical hash regardless of source adapter
- X→RSS collision: first-to-route wins, second appends `additional_sources` frontmatter
- RSS→X collision: reverse direction works correctly
- No collision when different URLs
- Same-batch cross-source collision via write-through `routed_at`
- Weekly aggregate cost summary covers both X and RSS with per-adapter costs
- Signal quality score per-adapter (`promote_count / total_routed` trailing 30 days)
- Weekly summary cadence tracking (7-day minimum interval)

**Weekly summary delivery wiring:**
- `src/cost/weekly.ts` — cadence tracking via `adapter_state` (source_type `_framework`,
  component `weekly-summary`), 7-day minimum interval, `shouldSendWeeklySummary()` and
  `markWeeklySummarySent()` functions
- `src/cli/attention-clock.ts` — step 10 added: checks cadence, generates weekly summary
  with `generateWeeklySummary()`, sends via Telegram (or logs in DRY_RUN), marks sent

**Test integrated** into `package.json` test runner (runs before integration-test).

### Housekeeping
- project-state.yaml `next_action` was stale (still referenced T1 backlog) — updated
- tasks.md: FIF-033 → done. M3 fully complete (FIF-030 through FIF-033).
- Missed project-state update from sessions 2026-03-04b–d noted in run-log.

### Pre-Existing Test Failures Identified
Three test failures present on `main` before this session — all same root cause (hardcoded
dates that have drifted past their assumed windows):
1. `feedback-test:314` — `cleanOldDigestItemMaps` uses Feb 10 and Feb 24; cutoff is
   `now - 7d` (Feb 25), both rows deleted instead of 1
2. `cost-test:621` — logs cost with `new Date()` (March) but queries with Feb 24 month
   boundaries; entry not found in February
3. `integration-test:490` — digest staged for today (March) but delivery runs with
   `now: 2026-02-25`; no staged digest found for Feb 25, `sentMessages` empty

All are test-fixture staleness, not production bugs. Code under test is correct.

### Verification
- cross-source-test: 54 passed, 0 failed
- router-test: 102 passed, 0 failed
- cost-test: 172 passed, 1 failed (pre-existing)
- No regressions introduced

### Test Date-Drift Fixes
Three pre-existing test failures (hardcoded dates drifted past assumed windows) fixed:
1. `cleanOldDigestItemMaps` — added `now` param to production function, test passes
   fixed date (`2026-02-25`) so both fixture rows are in predictable window
2. `logCost` edge case — added `now` param to production function, test passes matching
   date to both log and query
3. `renderDigest` integration — already accepts `{ date }` option, test now passes
   `2026-02-25` to match the delivery schedule's `now`

Full suite: 27 test files, 0 failures.

### Compound
- **M3 complete.** RSS adapter fully operational: capture, triage, routing, digest, delivery,
  feedback, cost tracking, cross-source collision detection, weekly aggregate summary.
- **Convention confirmed:** `url_hash` via `canonicalizeUrl()` + SHA256 is the reliable
  cross-source dedup key. Tracking params, protocol, and trailing slashes all normalized
  before hashing — same article from different sources produces identical hash.
- **Pattern:** Date-sensitive tests are a recurring maintenance cost. Tests that use
  `new Date()` for insertion but hardcoded dates for queries break as wall clock advances.
  Fix: always inject `now` into functions that touch timestamps. Three functions gained
  `now` params this session (`cleanOldDigestItemMaps`, `logCost`, `shouldSendWeeklySummary`).
  Existing pattern (`getAdapterCostSummary`, `getSignalQualityScore`, `renderDigest`) already
  had `now` params — the three broken functions were the ones that didn't.
- **No primitive gaps identified.**

## Session 2026-03-04g — Production Go-Live (DRY_RUN Off)

### Context
YouTube API key stored in Keychain. All M4 code complete and reviewed. Time to flip
the framework from dry-run to live Telegram delivery and start the 5-day soak (FIF-038).

### Actions
1. **YouTube API key verified** — `security find-generic-password` confirms key stored
   as `x-feed-intel.youtube-api-key`. Live API test returned valid `youtube#searchListResponse`.

2. **DRY_RUN removed from all 3 FIF plists:**
   - `ai.openclaw.fif.capture` — removed `DRY_RUN=1`
   - `ai.openclaw.fif.attention` — removed `DRY_RUN=1`
   - `ai.openclaw.fif.feedback` — removed `DRY_RUN=1`, KeepAlive set to `true`

3. **Legacy feedback listener disabled** — `ai.openclaw.xfi.feedback` bootout'd to
   prevent Telegram getUpdates competition. FIF feedback listener handles both legacy
   and new digest replies via `id_aliases`.

4. **All 3 FIF services reloaded** — bootout + provenance xattr strip + bootstrap.
   Feedback listener confirmed running (PID 41229). Capture + attention scheduled
   (06:05, 07:05).

5. **Legacy capture + attention left running** — dual delivery period starts tomorrow.
   Legacy digests at 07:00, FIF digests at 07:05. Allows quality comparison before
   legacy shutdown.

### Soak Period
- **Start:** 2026-03-05 (first live FIF digest delivery)
- **End:** 2026-03-09 (5 consecutive days per FIF-038 acceptance criteria)
- **Monitoring:** YouTube transcript error rate, circuit breaker state, cost tracking,
  digest delivery confirmation, no impact on X/RSS behavior
- **Gate:** After 5 clean days, disable legacy pipeline entirely

### Housekeeping
- Noted tasks.md / project-state.yaml mismatch — tasks.md shows FIF-034–038 as pending
  while project-state says M4 complete. Added to memory (project-pitfalls.md) with trust
  hierarchy: project-state > run-log > tasks.md.

### Compound
- **Convention confirmed:** Provenance xattr strip must be the absolute last step before
  `launchctl bootstrap` — matches existing MEMORY.md note. Applied correctly this session.
- **Pattern:** Feedback listener update competition is a hard constraint when migrating
  between pipeline versions sharing a Telegram bot. The solution is clean cutover (disable
  old, enable new) rather than dual-running. FIF's `id_aliases` make this safe — no reply
  resolution gap.
- **No primitive gaps identified.**

## Session 2026-03-05 — Day 1 Soak Fix: Daily Digest Windowing Bug

### Context
First live FIF digest (soak day 1) failed to deliver usable content. Legacy X digest arrived; FIF did not (or sent an unnoticed 3-line overflow summary). Root cause: daily digest included entire post backlog (670 items) instead of windowed daily items.

### Issues Found
1. **Daily digest cutoff bug (critical):** `renderDigest` only read the cutoff cursor for `cadence === 'weekly'`. Daily cadence passed `null`, causing `getDigestPosts` to return ALL triaged posts. With 670+ items, overflow triggered — Telegram received a 3-line summary with a local file path instead of the actual digest. Fix: read cutoff for all cadences (commit 8e82e69).
2. **RSS spending cap exceeded:** Cap was $0.50/month but DRY_RUN runs accumulated $0.66 in real triage costs against the same counter. Raised to $5.00 (aligns with $4.65/mo projection from FIF-032 validation).
3. **Feedback listener timeout race (fixed):** `getUpdates` long-poll timeout (30s server-side) matched the HTTP client timeout (30s). Network latency caused every idle poll to time out, creating a ~35s error loop. Fix: pass `(pollTimeout + 5s)` as client timeout for `getUpdates` calls (commit 08fbbf8). Service restarted, confirmed stable.
4. **Max items inline too low:** `max_items_inline: 30` caused overflow on normal daily volumes (~96 X items/cycle). Raised X to 150, RSS to 200 (commit 46930e4).
5. **Backlog cleared:** Reset all digest cutoff cursors to now. Tomorrow's digest starts fresh.

### Work Completed
- `src/digest/index.ts`: Removed `cadence === 'weekly'` guard on cutoff read (8e82e69)
- `src/cli/deps/telegram.ts`: Added `timeoutMs` param to `telegramApiCall`, `getUpdates` passes `pollTimeout + 5s` (08fbbf8)
- `adapters/rss.yaml`: `spending_cap` $0.50 → $5.00, `max_items_inline` 30 → 200 (46930e4)
- `adapters/x.yaml`: `max_items_inline` 30 → 150 (46930e4)
- Cutoff cursors reset in production DB. Feedback listener restarted. All 173 tests pass.

### Also This Session
- `_system/scripts/session-startup.sh`: Fixed rotation false positives (skip archived run-logs) and audit detection path (wrong directory for session-log). Commit 1111e93.
- BBP retry jobs kicked off for book-digest and chapter-digest (background, all input dirs, --resume).

### Compound
- **Convention: DRY_RUN cost isolation.** DRY_RUN mode should not accumulate real costs against production spending caps. The RSS cap breach was caused by DRY_RUN triage runs counting against the same `cost_log` table. Future pipelines with DRY_RUN modes should either skip cost logging or use a separate cost namespace. Not routing — specific to FIF, but worth noting if the pattern recurs.
- **Pattern: client timeout > server timeout for long-poll APIs.** Any long-poll consumer (Telegram getUpdates, SSE, etc.) must set the HTTP client timeout strictly greater than the server-side hold time. Equal timeouts create a race condition that manifests as 100% failure rate on idle connections. 5s buffer is sufficient.
- **No primitive gaps identified.**

## Session 2026-03-06 — Soak Day 2 Health Check + Keychain Credential Fix

### Context
Production soak day 2 health check. YouTube adapter hadn't triaged any items across
both soak days. Investigation revealed all 8 FIF credentials were keychain-only, and
launchd can't reliably read the login keychain when the screen locks or machine sleeps.

### Context Inventory
- `Projects/feed-intel-framework/progress/run-log.md` — soak context
- `Projects/feed-intel-framework/project-state.yaml` — current state
- `src/cli/deps/*.ts` — all credential resolution paths (6 files)
- `adapters/yt.yaml` — YT manifest
- `state/pipeline.db` — production DB
- `state/launchd-*.log` — launchd service logs
- `state/pipeline.log` — structured pipeline log

### Soak Health Check
- **X:** Healthy — 146 triaged (96 day 1, 50 day 2), 21 routed, digests delivered
- **RSS:** Day 1 skipped (stale $0.50 spending cap), day 2 healthy — 138 triaged, 15 routed, 10-part digest
- **YT:** 0 triaged both days — root cause below
- **Cost:** $0.30 total soak (X $0.14, RSS $0.16)
- **Late mode:** Both days — triage overruns digest schedule by ~2-4 min

### Root Cause Analysis — YouTube Items Not Triaged
1. Day 1 capture failed: "YOUTUBE_API_KEY not set" — Keychain inaccessible from launchd
2. Day 2 capture also failed from launchd; 124 YT items came from a manual capture at 10:35 AM
3. Attention-clock ran at 07:05 — before the manual capture — so saw 0 YT pending items
4. Dry-run triage confirmed the code works: 78 triaged, 23 routed, digest delivered

**Broader vulnerability:** All 8 credentials used Keychain lookups. Only 3 (Anthropic,
YouTube) had `process.env` fallbacks. X and RSS had been surviving on luck — if Keychain
locks during their scheduled runs, they'd fail identically.

### Fix Applied — Env Var Wrapper (commit 847a70c)

**Code changes (3 files):**
- `src/cli/deps/x-api.ts` — `process.env.TWITTERAPI_IO_KEY` fallback added
- `src/cli/deps/x-auth.ts` — `process.env.X_CLIENT_ID`, `X_CLIENT_SECRET`, `X_REFRESH_TOKEN` fallbacks
- `src/cli/deps/telegram.ts` — `process.env.TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` fallbacks

**Infrastructure (not in repo):**
- `~/.config/fif/env.sh` (chmod 600) — all 8 credentials exported from Keychain
- `~/.config/fif/run.sh` (chmod 700) — sources env.sh then exec's node
- 3 plists updated: `ProgramArguments[0]` changed from `/opt/homebrew/bin/node` to wrapper

**Verification:**
- 2,633 test assertions passing, exit 0
- All 3 services reloaded (bootout → xattr strip → bootstrap)
- Wrapper smoke test: YouTube adapter loads via env vars
- Feedback listener confirmed operational post-restart
- Env var names cross-checked: all 8 match exactly between code and env.sh

### Soak Impact
- X/RSS soak continues uninterrupted (days 1-2 clean)
- YT soak clock resets — 5 clean days from Mar 7 through Mar 11
- 78 YT items triaged via dry-run are real but don't count toward scheduled soak

### Pre-existing Uncommitted Changes
X adapter tuning changes (x-topics.yaml, preambles/x.md, x.yaml) found in working tree —
not related to this fix, not committed. Review separately.

### Compound
- **Convention: launchd + Keychain is unreliable for scheduled jobs.** The login keychain
  locks when the screen locks or machine sleeps. Any LaunchAgent that reads secrets via
  `security find-generic-password` will intermittently fail. The fix is a wrapper script
  that sources a 600-permissioned env file — same security posture, deterministic behavior.
  This applies to all launchd services in the Crumb ecosystem, not just FIF.
- **Pattern: env fallback as first-class credential path.** The `process.env.X || getSecret(x)`
  pattern should be the default for all credential lookups in CLI entry points. Keychain
  becomes the interactive fallback, env vars become the automation-first path.
- **No primitive gaps identified.**

---

## 2026-03-07 — Cross-project: M-Web absorbed by mission-control (MC-053)

**Phase:** TASK (cross-project amendment)

M-Web tasks (FIF-W01 through FIF-W12) are superseded by the `mission-control` project, which builds a unified dashboard consolidating FIF web presentation alongside all other Crumb operational views. FIF data is consumed via `fif-sqlite` and `pipeline-health` adapters in mission-control (MC-024, MC-025, MC-026 complete). M-Web section in `design/tasks.md` updated with supersession note — tasks retained for reference but not independently actionable.

## Session 2026-03-08 — FIF-044: x-feed-intel Decommission + P0 Dedup Fix

### Context
Two items from prior session: (1) P0 dedup normalization for bare-ID ↔ prefixed-ID format
mismatches, (2) x-feed-intel decommission evaluation and execution.

### Context Inventory
- `src/shared/dedup.ts` — dedup engine (FIF-004)
- `src/router/index.ts` — vault router with parseCanonicalId (FIF-011)
- `src/index.ts` — public exports
- `test/dedup-test.ts` — dedup test suite
- `/Users/tess/openclaw/x-feed-intel/` — legacy pipeline (comparison target)
- `Projects/x-feed-intel/project-state.yaml` — legacy project state

### P0: Dedup Canonical ID Normalization

**Problem:** x-feed-intel stores bare tweet IDs (`1867280760454951357`), FIF stores
prefixed IDs (`x:1867280760454951357`). 804 overlapping tweets across both DBs. If
data migrated between systems, dedup would miss matches due to format mismatch.

**Fix (src/shared/dedup.ts):**
- `normalizeCanonicalId(id, sourceType)` — ensures `{source}:{id}` format on input
- `bareNativeId(id)` — strips source prefix for fallback lookups
- `dedupBatch()` — normalizes incoming items + fallback LIKE query for cross-format matches
- `isKnown()` — checks both bare and prefixed variants bidirectionally
- Both helpers exported from `src/index.ts`

**Tests:** 5 new test cases (tests 15–19), covering:
- normalizeCanonicalId unit tests (bare → prefixed, already-prefixed passthrough)
- bareNativeId unit tests (strip prefix, bare passthrough)
- Bare ID merges with existing prefixed entry (simulates migration data)
- isKnown detects bare ID when prefixed exists (and vice versa)
- Prefixed ID vs existing bare row (documents the limitation — normalize on ingest)

**Results:** 50 assertions pass. Full suite: 30 files, 2,719 assertions, 0 failures.

### FIF-044: x-feed-intel Decommission

**Feature parity evaluation:**
- FIF matches or exceeds x-feed-intel on all core capabilities
- 3 gaps accepted (low severity): `research` command, `refresh` command, enrichment module

**Execution:**
1. Legacy LaunchAgents disabled (`xfi.capture`, `xfi.attention` bootout'd; `xfi.feedback`
   already disabled since 2026-03-04g)
2. All 3 xfi plist files removed from `~/Library/LaunchAgents/`
3. Telegram bot token verified shared (FIF reuses `x-feed-intel` Keychain service prefix)
4. `ai-workflows` topic confirmed intentionally removed from FIF (redundant)
5. x-feed-intel project-state.yaml → phase: DONE
6. x-feed-intel run-log updated with decom entry
7. FIF tasks.md: FIF-044 added and marked in_progress
8. FIF project-state.yaml: next_action updated

### Compound
- **Convention confirmed:** Feature parity evaluation before decom prevents premature shutdown.
  The structured comparison (37-row matrix) made the decision objective — 3 accepted gaps
  are all low-frequency features with CLI workarounds.
- **Pattern:** When systems share credentials via Keychain service prefix, decom is simpler —
  no credential migration needed. FIF's design choice to reuse `x-feed-intel` service prefix
  (not rename to `fif`) paid off here.
- **Pattern:** Dedup normalization should be defense-in-depth, not migration-blocking.
  The runtime pipeline is clean (all IDs properly prefixed), but the normalization layer
  catches format mismatches from any entry path — migration, manual DB edits, future adapters.

## 2026-03-09 — State Reconciliation

**Issue:** project-state.yaml listed "uncommitted X adapter tuning changes pending review"
and "dedup hardened with normalizeCanonicalId (pending commit)" — but the repo working tree
is clean. All changes were already committed:
- `8749f9d` — dedup canonical ID normalization
- `9cf0cbb` — X adapter volume + quality filters
- `fca5ae4` — X thread collapsing
- `7641aba` — digest timestamp/cutoff fix

**Session-end miss:** The 2026-03-08 session committed the code but did not update
project-state.yaml to reflect the commits. The "pending commit" / "pending review" language
persisted for a day, creating stale state that required manual reconciliation.

**Corrective:** project-state.yaml updated — removed stale "uncommitted" / "pending" language.

**Compound:**
- **Process gap:** Session-end sequence should verify that project-state.yaml `next_action`
  reflects the actual repo state after commits. Code committed + state still saying "pending
  commit" is a drift vector. The session-end protocol covers run-log and conditional commit
  but doesn't explicitly require a `next_action` freshness check post-commit.
