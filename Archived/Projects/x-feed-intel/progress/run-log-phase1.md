---
type: run-log
project: x-feed-intel
domain: software
status: archived
created: 2026-02-23
updated: 2026-03-02
covers: "Project creation through IMPLEMENT deployment — SPECIFY, PLAN, TASK (M0-M3, 32 tasks), IMPLEMENT (live deployment + research dispatch + digest amendment)"
---

# X Feed Intel — Run Log (Archive: Phase 1)

> **Active run-log:** [[run-log]]

---

## Session 2026-02-23 — Project Creation

### Context
Spec (v0.4.1) and HTML digest prototype created in an external session and dropped
into `_inbox/`. Project scaffolded under Crumb governance. Feed-intel-framework
is a related future project that will generalize this pipeline to multiple sources.

### Actions
- Created project scaffold: project-state.yaml, run-log, progress-log, design/
- Moved `x-feed-intel-spec-v0_4_1.md` → `design/specification.md`
- Moved `x-feed-intel-digest-prototype.html` → `design/digest-prototype.html`
- Web Design Preference overlay created separately (same session) — applies to digest UI work

### Current State
- Phase: SPECIFY
- Spec exists (v0.4.1) but needs review under Crumb governance before advancing to PLAN
- Digest prototype is a starting point for Library-mode UI, to be refined through overlays

---

## Session 2026-02-23 — Governance Review

### Context Inventory
- `design/specification.md` (v0.4.1 → v0.4.2)
- `project-state.yaml`
- `_system/docs/file-conventions.md`
- `_system/docs/tess-crumb-boundary-reference.md`
- `_system/docs/overlays/overlay-index.md`
- `_system/docs/crumb-design-spec-v2-0.md` (§0–§2.1)

### Actions — Governance Review (G-01 through G-09)

Reviewed spec v0.4.1 against Crumb governance on 7 dimensions: frontmatter compliance, boundary compliance, vault schema impact, open decision points, spec completeness, overlay applicability, forward dependencies.

**Fixes applied (v0.4.2):**
- G-01: Removed `status` field from spec frontmatter (project docs don't use status)
- G-02: Added `topics: [moc-crumb-operations]` to spec frontmatter (required for kb/ tags)
- G-03: Clarified SQLite DB location — outside vault, in pipeline repo (§7.2)
- G-09: Incorporated `save` command amendment — new `save` reply command, `_openclaw/feeds/kb-review/` staging directory, feedback logging, §5.5.1 `capture` clarification

**Generated:**
- `design/specification-summary.md` (phase transition gate requirement)

**Deferred to PLAN (tracked in v0.4.2 changelog):**
- G-04: Register `type: x-feed-intel` in vault type taxonomy
- G-05: Track new `_openclaw/` subdirectories in design spec §2.1
- G-06: Firm up implementation language (Node.js per OpenClaw stack)
- G-08: Vault snapshot outbox dependency is soft (fallback handles it)

### Governance Verdict
Spec is governance-ready. All blocking items resolved. PLAN-deferred items are inputs to planning, not blockers.

### Current State
- Phase: SPECIFY (ready to advance to PLAN)
- Spec: v0.4.2 — governance-reviewed, save command incorporated
- Summary: generated
- Next: Phase transition gate → advance to PLAN

---

### Phase Transition: SPECIFY → PLAN
- Date: 2026-02-23 ~09:00
- SPECIFY phase outputs: [design/specification.md (v0.4.2), design/specification-summary.md, design/digest-prototype.html]
- Compound: No compoundable insights from SPECIFY phase. Save command amendment closed the KB capture gap; governance frontmatter fixes are routine vault-check discipline.
- Context usage before checkpoint: ~40% (moderate)
- Action taken: none
- Key artifacts for PLAN phase: [design/specification-summary.md, design/specification.md §12 (Phasing), governance notes G-04/G-05/G-06/G-08]

---

## Session 2026-02-23 — PLAN Phase: Action Plan

### Context Inventory
- `design/specification-summary.md`
- `design/specification.md` §3–§15 (components, scheduling, error handling, state store, boundary, phasing, dependencies)
- `_system/docs/solutions/claude-print-automation-patterns.md` (Pattern 4: budget iteration time for live structured output deployment)
- `_system/docs/overlays/overlay-index.md` (no overlays activated for planning)

### Decision: Implementation Language (G-06 Resolution)

**Decision:** Node.js / TypeScript

**Rationale:** OpenClaw (Tess's runtime) is Node.js. Aligning the pipeline with the same stack provides shared dependency management, logging patterns, and config conventions. TypeScript adds type safety for the structured data pipeline (normalized post format, triage schema, SQLite operations). Node.js has viable Keychain access via `keytar` or native bindings, and runs under launchd on Mac Studio.

**Alternatives considered:**
- Python — richer API client ecosystem, simpler scheduling. Better if this becomes a general-purpose ingester. Rejected because OpenClaw alignment outweighs Python's library advantage for this specific pipeline.

**Recorded as:** ADR-001 (to be written in `decisions/` during XFI-001)

### Actions — Action Plan Decomposition

Decomposed spec v0.4.2 into 4 milestones and 30 tasks:
- **M0 (Foundation & Validation, Size: S):** 11 tasks — repo scaffold, SQLite schema, OAuth, API benchmarks, vault dirs, Telegram verification, TwitterAPI.io setup
- **M1 (Capture Clock, Size: M):** 5 tasks — normalizer, bookmark puller, topic scanner, dedup, launchd scheduling
- **M2 (Attention Clock, Size: L):** 7 tasks — vault snapshot, triage engine, prompt engineering, vault router, digest, cost telemetry, launchd scheduling
- **M3 (Feedback & Ops, Size: M):** 7 tasks — feedback listener, 5 commands, cost guardrail, queue health, liveness check, ops guide

**Review findings incorporated:**
- XFI-001 references ADR-001 explicitly (language decision not implicit)
- XFI-008 marked as Crumb-governed task (not raw filesystem mkdir)
- XFI-017 acceptance criteria tightened: JSON parse 100%, schema fields 100%, no routing bar violations, non-degenerate confidence distribution
- XFI-022 handles `expand` as recognized-but-Phase-2 (not parse error)
- XFI-00A added: Telegram bot verification (dependency for digest, feedback, liveness)
- XFI-00B added: TwitterAPI.io account setup (dependency for search benchmark and scanner)
- All scheduling tasks specify launchd (not cron/launchd)
- Dependency graph noted as simplification — task table is authoritative
- T-shirt sizing added per milestone (S/M/L/M)

**Generated:**
- `action-plan.md`
- `action-plan-summary.md`
- `tasks.md` (30 tasks)

### Peer Review — 2026-02-23

**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek Reasoner, Grok 4.1 Fast, Perplexity Sonar Reasoning Pro (5-model review)

**Review note:** `_system/reviews/2026-02-23-x-feed-intel-action-plan.md`

**Must-fix applied (3):**
- A1: XFI-006 deps fixed (XFI-00A → XFI-00B) — unanimous, 4/4
- A2: XFI-017 AC tightened — "at least 2 distinct confidence levels in ≥20-post sample" replaces "not degenerate" — 4/5 reviewers
- A3: Added XFI-019b (digest item ID → canonical_id mapping) — OpenAI unique finding, critical for feedback loop correctness

**Should-fix applied (7):**
- A4: XFI-010 normalizer risk elevated low → medium (foundational data model)
- A5: XFI-013 added as explicit dep for XFI-016 (M1→M2 data dependency encoded)
- A6: XFI-022 expanded to include KeepAlive launchd daemon plist (not periodic schedule)
- A7: SQLite WAL mode added to XFI-002 AC (3 concurrent writers need WAL)
- A8: XFI-014 flagged for potential split at TASK phase (>5 files likely)
- A9: XFI-009 extended to persist labeled benchmark set for Phase 2 drift validation
- A10: XFI-028 AC enumerated: 7 specific runbook topics

**Elevated from declined (user decision):**
- OAI-F3: XFI-025/XFI-026 are independent scheduled jobs, but that means 5-6 launchd plists total. Added explicit launchd process inventory to action plan. Cost guardrail (XFI-025) runs inline in capture clock — does NOT need its own plist.

**Declined (21 findings):** Rationale documented in review note. Key rejections: DB access layer (overkill), shared logging framework (premature), XFI-016/022 multi-way splits (too granular for PLAN), Haiku 4.5 "doesn't exist" (Google wrong — valid model).

**Net changes:** 30 → 31 tasks. Schema table count 4 → 5. XFI-002 gains WAL. XFI-010 risk low → medium. XFI-016 gains M1 dep. XFI-022 gains daemon plist. XFI-028 gains enumerated AC.

### Peer Review Round 2 (Perplexity) — 2026-02-23

Perplexity Sonar Reasoning Pro delivered a second round focused on the post-fix plan. Verdict: "Ready with minor fixes" across all 7 dimensions. Key findings from "Fresh Eyes" section:

**Applied (5 items):**
- XFI-00C (optional): Dev/test harness with recorded API fixtures + fake Telegram sink — nobody in round 1 caught the live-API-only development gap. Added as optional M0 task.
- XFI-017: Semantic eval against labeled benchmark set — concrete match threshold (≥N of 20 match operator priority/tags) closes the gap between "structurally valid" and "actually useful" triage.
- XFI-026: Expired items remain queryable (not silently deleted) — ops guide documents how to inspect.
- XFI-015: 2-second generation SLO added to prevent O(N vault) implementation.
- XFI-014/021: Launchd plist paths and `run_id` in logs for debuggability.

**Net changes:** 31 → 32 tasks (XFI-00C optional). XFI-015 gains time SLO. XFI-017 gains semantic eval. XFI-026 gains expiry visibility. XFI-014/021 gain plist paths and run_id.

### Phase Transition: PLAN → TASK
- Date: 2026-02-23 (session 3)
- PLAN phase outputs: action-plan.md, action-plan-summary.md, tasks.md, _system/reviews/2026-02-23-x-feed-intel-action-plan.md (+ 4 raw JSON reviews)
- Compound: "Multi-process pipeline plans need an explicit process inventory — the launchd plist inventory was implicit until peer review caught it. Generalizable pattern for scheduled/daemon process architectures." Routing: log for now, write to _system/docs/solutions/ if recurs.
- Context usage before checkpoint: within operational band
- Action taken: none
- Key artifacts for TASK phase: action-plan-summary.md, tasks.md, specification-summary.md

### Current State
- Phase: TASK (plan approved, ready for implementation)
- Next: Begin implementation — parallel start on XFI-001, XFI-008, XFI-00A, XFI-00B

---

## Session 2026-02-23 — TASK Phase: M0 Implementation Start

### Context Inventory
- action-plan-summary.md
- tasks.md
- specification-summary.md
- specification.md §5.2, §5.5.0, §7.2, §8

### Pre-task: Mirror Sync Bug Fix

Investigated mirror-sync.sh dropping top-level project markdown files. Root cause: rsync rules only included `Projects/*/design/`, `progress/`, `src/` subdirectories — files at the project root (action-plan.md, tasks.md, specification.md) fell through to `--exclude='*'`.

**Fix:** Added `--include='Projects/*/*.md'` to rsync rules and `^Projects/[^/]+/[^/]+\.md$` to git allowlist. Updated vault-mirror spec. Affected projects: x-feed-intel, tess-model-architecture, think-different. Committed and pushed — mirror backfilled.

### Actions — XFI-001: Scaffold Pipeline Repo

- Created repo at `~/openclaw/x-feed-intel` (Tess-operated, outside vault per §8)
- Node.js/TypeScript: package.json, tsconfig.json (ES2022, strict, commonjs)
- Directory structure: `src/capture/`, `src/attention/`, `src/feedback/`, `src/shared/`, `state/`, `benchmarks/`, `docs/`, `config/`, `decisions/`
- ADR-001 written: Node.js/TypeScript decision documented with rationale
- Git repo initialized, 2 commits
- **AC verified:** `npm install` clean, `npx tsc --noEmit` passes, all src/ subdirs present

### Actions — XFI-008: Vault Directory Structure & Governance

- Created `_openclaw/feeds/items/`, `_openclaw/feeds/digests/`, `_openclaw/feeds/kb-review/` with .gitkeep
- Created `_openclaw/config/operator_priorities.md` with frontmatter and default content (per §5.5.0)
- Registered `type: x-feed-intel` in `_system/docs/file-conventions.md` type taxonomy
- **AC verified:** All directories exist, operator_priorities has proper frontmatter, type registered, vault-check clean

### Actions — XFI-002: SQLite Schema & Migration

- Installed `better-sqlite3` (sync API, good for pipeline batch processing)
- Created `src/shared/db.ts`: `openDb()` with WAL mode + foreign keys, `migrate()` with all 5 tables
- Created `src/shared/migrate.ts`: standalone migration runner
- Schema matches §7.2 exactly: posts, cost_log, feedback, topic_weights + digest_item_map (XFI-019b peer review addition)
- `save` added to feedback.command values per save command amendment (S3)
- **AC verified:** All 5 tables created, schema matches, `state/pipeline.db` at repo root, migration idempotent (re-run succeeds), WAL mode confirmed

### Actions — XFI-003: Topic Config Loader

- Installed `js-yaml` for YAML parsing
- Created `src/shared/topic-config.ts`: typed config loader with validation
- Filter resolution per §5.2: per-topic `filters` override global default entirely
- `max_results` and `max_age_days` fall back to global defaults when unset at topic level
- Validation rejects: missing topics array, empty topic names, empty queries, non-positive integers
- Created `config/topics.yaml` with 4 topics from §5.2 (agent-architecture, claude-code, obsidian-pkm, ai-workflows)
- **AC verified:** Loads sample config, per-topic filters override, defaults apply, malformed configs rejected

### Actions — XFI-004: X API OAuth 2.0 Token Management

- Created `src/shared/keychain.ts`: get/set/delete secrets via macOS `security` CLI (no native module deps)
- Created `src/shared/x-auth.ts`: full OAuth 2.0 PKCE flow — authorization URL generation, local callback server (port 8739), code→token exchange, refresh token rotation, Keychain persistence
- Created `src/capture/x-auth-setup.ts`: interactive CLI with 4 modes: --store-credentials, --authorize, --verify, --refresh
- Pipeline entry point: `getAccessToken()` — refreshes automatically, throws clear error on failure (triggers Telegram notification per §10)
- Scopes: bookmark.read, tweet.read, users.read, offline.access
- **AC status:** Code complete. Needs Danny to run interactive auth: `npm run x-auth-setup -- --store-credentials` then `--authorize` then `--verify`

### Actions — XFI-006: TwitterAPI.io Benchmark Script

- Created `src/capture/twitterapi-benchmark.ts`: loads topic config, queries all topics via TwitterAPI.io advanced_search endpoint
- Operator verification: checks min_faves, -filter:replies, lang:en effectiveness against actual results
- Thread field detection: checks for inReplyToId and conversationId (feeds XFI-007)
- Engagement data presence check per AC
- Cost logged to cost_log table, results saved to `benchmarks/twitterapi-benchmark-YYYY-MM-DD.json`
- Pagination support for pulling up to max_results per query
- **AC status:** Code complete. Needs Danny to run: `npm run benchmark:twitter`

### XFI-00B: TwitterAPI.io Account (Danny-completed)
- Account created, credits loaded, API key in Keychain — confirmed by Danny

### Current State
- Phase: TASK (M0 in progress)
- Done: XFI-001, 002, 003, 004, 006, 008, 00B (7/12)
- Awaiting Danny interaction: XFI-004 auth flow, XFI-006 benchmark execution
- Remaining: XFI-005 (bookmark benchmark, needs XFI-004 auth), XFI-007 (thread fields, needs benchmark data), XFI-009 (operator review), XFI-00A (Telegram verify), XFI-00C (optional dev harness)
- OAuth callback port fixed: 8739 → 3000 to match X Developer Portal config
- Context7 MCP server added for next session (live API doc lookups)

### Compound Evaluation
- Mirror sync bug fix: rsync rules gap for top-level project files is a **generalizable pattern** — any rsync-based sync with subdirectory-level includes will silently drop files at the parent level. Not writing to solutions/ yet — single occurrence, but high impact (affected 3 projects). Monitor for recurrence.
- No other compoundable insights — remaining work was straightforward scaffold/implementation.

---

## Session 2026-02-23 — Crash Recovery + M0 Completion + M1 Implementation

### Context Inventory
- action-plan-summary.md, tasks.md, specification-summary.md
- specification.md §5.1–§5.4, §5.2 (topic config)
- docs/api-field-mapping.md (from XFI-007)
- src/shared/api-client.ts (from XFI-00C)

### Actions — M0 Completion

**XFI-004 (OAuth):** Confirmed done by operator — tokens in Keychain, refresh verified.

**XFI-006 (TwitterAPI.io benchmark):** Crash recovery — previous session hung mid-execution (no timeout on HTTP requests, all-or-nothing file write). Fixed both: added 30s request timeout, per-query incremental flush to disk with resume-from-partial logic. Rerun completed: 562 tweets across 12 queries, all operators confirmed.

**XFI-005 (Bookmark benchmark):** Built and ran. 194 bookmarks pulled. Key findings: conversation_id 100%, in_reply_to_user_id 5.7% (replies only), public_metrics 100%. Avg engagement 7.4k likes. Cost: $0.97.

**XFI-007 (Thread field docs):** Documented field shapes from both APIs in `docs/api-field-mapping.md`. Key finding: X API v2 has `in_reply_to_user_id` (user-level), not `in_reply_to_status_id` as spec assumed. Thread heuristic adjusted: `conversation_id !== id` is primary structural signal.

**XFI-00C (Dev/test harness):** Built dry-run infrastructure: DRY_RUN=1 env var, fixture files (20 bookmarks + 60 tweets), Telegram file sink, API client abstractions. 5/5 smoke tests passing.

**XFI-009 (Operator benchmark review):** Applied 6 spec amendments (v0.4.2 → v0.4.3): config path pinned, Tess topic management CRUD, KB tag alignment, query tuning (2 queries replaced, ai-workflows min_faves→20), labeled benchmark set (20 posts). Scope flag: Amendment 2 expands feedback listener scope beyond current XFI-024 AC — will need task update at M3.

### Actions — M1 Implementation

**XFI-010 (Normalizer):** Unified post format per §5.3. Maps both API shapes (BookmarkEntry, SearchTweet) to NormalizedPost. Thread heuristic with 4 conditions: conversation_id mismatch, X API reply signal, TwitterAPI.io reply signal, text markers (🧵, numbered patterns). mergeSourceInstance() for dedup engine's append-only topic accumulation. 208 test assertions passing.

**XFI-013 (Global dedup):** SQLite-backed dedup via posts table. New posts → pending queue. Re-encountered → merge source_instances + append matched_topics without re-queuing. Already-triaged posts updated but not re-triaged. All operations atomic via transaction. 27 test assertions.

**XFI-012 (Topic scanner):** Full capture pipeline: api-client → normalizer → per-run dedup cache → global dedup → pending queue. Client-side engagement filter fallback. Cost logging with run_id. 15 test assertions. Fixture: 60 fetched → 56 queued (4 per-run dedup).

**XFI-011 (Bookmark puller):** OAuth fetch → normalize → dedup → queue. Telegram notification on auth failure via sink abstraction. Cost logging at $0.005/post. 16 test assertions.

### Current State
- Phase: TASK
- M0: 11/12 done (XFI-00A Telegram verify remaining)
- M1: 4/5 done (XFI-014 capture clock scheduling remaining)
- Pipeline repo: 14 commits on `~/openclaw/x-feed-intel`
- All test suites passing: normalizer (208), dedup (27), topic-scanner (15), bookmark-puller (16), dry-run (5)
- Next session: XFI-014 (launchd plists) or start M2 (XFI-015 vault snapshot, XFI-020 cost telemetry both unblocked)
- XFI-00A (Telegram bot verify) still needs Danny action — blocks live notifications but not code progress

### Compound Evaluation
- Benchmark script crash pattern: HTTP requests without timeouts + all-or-nothing file writes = silent hang with total data loss. Fixed with 30s timeout + per-query incremental flush + resume-from-partial. **Generalizable pattern** for any batch pipeline script hitting external APIs. Not writing to solutions/ yet — single occurrence, but directly applicable to the capture clock components being built. Monitor.
- No other compoundable insights — M1 implementation was clean execution against well-defined interfaces.

---

## Session 2026-02-23b — Interrupted Session-End Recovery

### Context
Previous session ran out of context mid-session-end sequence. Run-log and rating were captured but signal append, commit, and push were not.

### Actions
- Appended signal to `_system/docs/signals.jsonl`
- Committed `4dc36f2 chore: session-end log — x-feed-intel M0/M1 sprint (rating 3)`
- Pushed to remote

### Current State
- Unchanged from previous session — M0 11/12, M1 4/5
- Next: XFI-014 (launchd plists) or M2 start

### Compound Evaluation
- No compoundable insights — mechanical cleanup only.

---

## Session 2026-02-23c — Web UI Proposal Review + Design Decisions

### Context Inventory
- design/specification-summary.md
- design/feed-intel-web-ui-proposal.md (routed from `_inbox/`)
- tasks.md (M0/M1 status)
- run-log.md (prior sessions)

### Actions — Inbox Processing

Routed `_inbox/feed-intel-web-ui-proposal.md` → `Projects/x-feed-intel/design/feed-intel-web-ui-proposal.md`. Design proposal from claude.ai peer review session proposing web-based digest UI to replace Telegram as primary reading surface.

### Actions — Architectural Review (7 Decision Points)

Danny reviewed and confirmed all 7 decision points. Crumb analysis aligned on all.

**Decisions locked:**

1. **Hosting:** Cloudflare Tunnel + Access (Option A). Zero-trust auth, any-browser access, free tier, no port exposure. Domain ~$10/yr only dependency.
2. **Tech stack:** Express + EJS + Tailwind CSS + progressive enhancement. No SPA framework. Read-heavy once-daily dashboard doesn't justify React or a build pipeline.
3. **Repo location:** Inside framework repo. Starts in `~/openclaw/x-feed-intel`, migrates during framework extraction. Tight coupling to SQLite schema makes separation pointless. **Directory convention:** Web UI code lives in `src/web/` (server.ts, routes/, views/, public/) — clean extraction boundary, avoids intermingling with pipeline components. This costs nothing now and makes framework extraction a directory move, not a code untangling exercise.
4. **Sequencing:** Option 3 (parallel hybrid). Finish x-feed-intel M1-M3 with Telegram digest. Build web UI as new milestone (M-Web) reading from same SQLite. Multi-source design from the start — don't hardcode X assumptions, lean on `source_type` in schema.
5. **Telegram role:** Notification-only with reply commands as fallback. Keep §5.8 reply protocol working alongside web UI.
6. **SQLite access:** Direct read, no abstraction layer. Use separate read-only connection from pipeline's write connection. WAL mode (already enabled) handles concurrency.
7. **Investigate staging:** `_openclaw/feeds/investigate/` (Tess-owned). Not `_openclaw/inbox/` — investigation requests are Tess's work queue, briefs route to Crumb's inbox after Tess researches. Follows kb-review/ pattern.

### Actions — Investigate Action Design Guidance

Danny pushed deeper on the investigate action. Key design constraints captured:

- **Scope:** Significant capability expansion — adds a research loop to the pipeline. Not just a feedback command.
- **Processing model:** Separate async process, NOT part of the attention clock. Investigation is unbounded in duration and must not block digest delivery. Simple sweep: check `_openclaw/feeds/investigate/` for `status: pending`, process one per cycle.
- **Volume cap:** Soft cap of 3-5 pending investigations. Notification when at capacity: "Investigation queue at capacity — complete or decline existing before adding more."
- **LLM cost model needed:** Assessment writing is an LLM call. Haiku 4.5 (like triage) or Sonnet? Cost model must be defined before implementation.
- **Output template:** Structured investigation-brief with sections: Summary, Relevance to Current Architecture, Key Findings, Recommendation (new project / fold into {project} / capture as KB / discard), Sources Consulted.
- **Status separation:** Feedback table records that Danny requested investigation (command + operator note). File frontmatter tracks investigation lifecycle (pending → researching → complete → declined). Right separation.
- **Sequencing:** Spec it properly but don't implement until web UI exists (primary trigger surface).

### Actions — Framework Spec Observations (Logged for Phase 1b)

Danny flagged 5 items for framework spec refinement:

1. **Cross-source collision append-note** should include second source's priority + recommended_action (immediate comparison without digest lookup)
2. **RSS canonical_id fragility** — sha256(url)[:12] breaks on permalink structure changes (WordPress migrations, domain changes). Document as accepted limitation with stated consequence, same category as 800-bookmark ceiling.
3. **Reddit adapter Phase 0 gate** — correct call given API policy instability. RSS fallback is insurance.
4. **Late-delivery marker** should log to `adapter_runs` with notes field ("triage overran budget by X minutes") for trend data to calibrate budget.
5. **content_tier per-item override** — effective_tier resolving before manifest default + retry semantics are well-designed. Danny confirmed.

### Priority Queue (Danny-confirmed)

1. XFI-00A — Telegram bot verify (10-min task, unblocks live notifications)
2. XFI-014 — Capture clock scheduling (last M1 task)
3. M2 start — XFI-015 (vault snapshot) + XFI-020 (cost telemetry) in parallel, then XFI-016/017 (triage engine + prompt — highest risk)
4. Web UI spec work — lock design decisions into milestone, sequence after M3
5. Investigate action — full spec (staging, template, cap, cadence, cost model) but don't implement until web UI exists

### Correction — Web UI / Investigate Coupling (Danny flagged)

Crumb treated the web UI and investigate action as two independent analysis items. They're coupled: the proposal frames investigation as a web UI activity — Danny reads through items with context, checks triage assessment, adds a meaningful operator note, then triggers research. That's not a quick-reply Telegram activity.

**Sequencing implication:** Investigate is **blocked on the web UI**, not just on spec amendments. This must be explicit in task dependencies. Telegram could theoretically support `A01 investigate [note]` as a fallback, but the primary UX is the web UI. If Telegram investigate is desired, it's a secondary path — not the design driver.

### Correction — Spec Ownership (Danny flagged)

The web UI architecture section belongs in the **framework spec**, not the x-feed-intel spec. The proposal explicitly says "this applies at the framework level." The x-feed-intel spec only needs:
- A note that the Telegram digest transitions to notification-only when the web UI is deployed
- A forward reference to the framework spec's web UI section

This avoids duplicating web UI architecture across two specs that will inevitably drift.

### Correction — Investigate Operational Gaps (Danny flagged)

Crumb's initial analysis stopped at "flow is sound" without digging into operational implications. Danny pushed further on 4 items already captured (volume cap, processing cadence, cost model, output template) but also flagged that Crumb should have identified these proactively. The investigate action is a research loop bolted onto a capture-triage-present pipeline — the operational implications (unbounded duration, cost model shift from Haiku to Sonnet, queue accumulation risk) should have been part of the initial architectural review, not a follow-up correction.

### Actions — XFI-00A: Telegram Bot Verification

- Reused Tess's existing Telegram bot (no new bot created — single conversation thread)
- Danny stored bot token and chat ID in macOS Keychain under `x-feed-intel.telegram-bot-token` and `x-feed-intel.telegram-chat-id`
- Verification: live sink sent test message, received `messageId: 246`, Danny confirmed receipt
- **AC verified:** Bot sends messages successfully, API token accessible to pipeline process, bot-to-user path confirmed

### Actions — XFI-014: Capture Clock Scheduling

- Created `src/capture/capture-clock.ts`: orchestrates bookmark pull + topic scan
  - Unique `run_id` (`capture-{timestamp}`) prefixed on every log line
  - `withRetry()` wrapper: 3 retries with 30s/60s/120s exponential backoff per §6.3
  - Partial success: bookmark and scan run independently (separate try/catch)
  - Scan frequency gating via `capture-state.json` — skips topic scan if within configured interval (default 2 days)
  - Telegram notification on any failure
  - Structured logging to `state/pipeline.log`
- Created `config/ai.openclaw.xfi.capture.plist`: launchd schedule daily 6:00 AM
  - Node path: `/opt/homebrew/bin/node` (Apple Silicon)
  - Runs compiled JS (`dist/capture/capture-clock.js`)
  - stdout/stderr to `state/launchd-capture-{stdout,stderr}.log`
  - HOME explicitly set per macOS multi-user operational notes
- Added npm scripts: `capture` (run), `capture:install` (deploy plist), `capture:uninstall` (remove plist)
- **AC verified:** Dry-run passes (bookmark OK + scan OK on first run, scan SKIPPED on immediate re-run confirming frequency gate), plist validates (`plutil OK`), pipeline.log written, run_id on all log lines, typecheck clean

### Current State
- Phase: TASK (unchanged)
- **M0: 12/12 complete** ✓
- **M1: 5/5 complete** ✓
- Web UI proposal reviewed, all 7 decisions locked (decision 3 refined with `src/web/` convention), routed to design/
- Investigate action: design guidance captured, web UI dependency explicit, implementation deferred
- Framework spec observations logged for Phase 1b
- Spec ownership clarified: web UI section → framework spec; x-feed-intel gets notification transition note + forward reference
- Next: M2 start — XFI-015 (vault snapshot) + XFI-020 (cost telemetry) both unblocked

### Actions — M1 Peer Review + Must-Fix Application

**Peer review (5 reviewers):** GPT-5.2, Gemini 3 Pro, DeepSeek V3.2, Grok 4.1 Fast, Perplexity Sonar Reasoning Pro (external). Scope: M1 capture clock components (normalizer, bookmark puller, topic scanner, global dedup, capture clock scheduling). Full results in `_system/reviews/2026-02-23-xfi-m1-capture-clock.md`.

**Danny meta-review:** Agreed with all must-fix (A1-A4), all declined items, elevated A7 (exit code) to must-fix. Noted A5 (source_instances dedup) deserves more weight than positioned.

**Must-fix items applied (5/5):**

| ID | File | Fix |
|----|------|-----|
| A1 | capture-clock.ts | `try/finally { db.close(); }` — prevents DB handle leak on exceptions |
| A2 | dedup.ts | `JSON.parse` try/catch — malformed DB rows skip instead of crashing batch |
| A3 | capture-clock.ts | Atomic state write via `.tmp` + `fs.renameSync` — prevents partial writes |
| A4 | api-client.ts | Per-query try/catch in `searchTopics` — failed queries log + return empty, don't abort scan |
| A7 | capture-clock.ts | Exit code `\|\|` not `&&` — any failure returns code 1 for monitoring |

**Verification:** TypeScript typecheck clean, dry-run passes (bookmark OK, scan SKIPPED by frequency gate).

### Current State (Post Peer Review)
- Phase: TASK (unchanged)
- M0: 12/12 complete ✓
- M1: 5/5 complete ✓ (must-fix hardening applied)
- 13 should-fix + 6 deferred items tracked in review note for future sessions
- Next: M2 start — XFI-015 (vault snapshot) + XFI-020 (cost telemetry) both unblocked, then XFI-016/017 (triage engine + prompt — highest risk)

### Compound Evaluation
- Exit code semantics pattern: `process.exit(anyFailure ? 1 : 0)` not `process.exit(allFailed ? 1 : 0)`. For monitored pipelines, exit codes should signal ANY degradation for alerting — launchd/cron alerting triggers on non-zero, and partial failure is still failure from an ops perspective. Danny flagged this elevation. Single occurrence — not writing to solutions/ yet, but directly applicable to any future pipeline entry point.
- Perplexity reviewer calibration captured in review note: unreliable on code accuracy, strong on architectural/interface analysis. Actionable for future peer reviews: use Perplexity for design reviews, not code reviews.
- No other compoundable insights — must-fix application was mechanical.

---

## Session 2026-02-23d — M2 Attention Clock Implementation

### Context Inventory
- action-plan-summary.md, tasks.md, specification-summary.md
- specification.md §5.5.0, §5.5.1, §5.6, §5.7, §5.9, §7.2, §13, Appendix A
- src/shared/db.ts, normalizer.ts, dedup.ts, telegram.ts, keychain.ts (M0/M1 patterns)
- capture-clock.ts (scheduling/logging/retry patterns)
- benchmarks/xfi-triage-benchmark-20260223.json (20-post labeled set)
- Context7: Anthropic API TypeScript SDK docs (messages endpoint, usage tokens)

### Actions — XFI-015: Vault Snapshot Generator

- Created `src/attention/vault-snapshot.ts`: reads project-state.yaml from all Projects/, operator_priorities.md, and outbox status/stage JSON files
- Active phase detection: SPECIFY, PLAN, TASK, IMPLEMENT, ACT (excludes DONE, ARCHIVED)
- Focus text extracted from next_action, capped at 80 chars
- Outbox scanner reads `-status.json` and `-stage-*.json` (not `-response.json` ack receipts) — first sentence extraction
- Operator priorities: strips frontmatter, headings, and boilerplate lines
- Token budget enforcement: ≤2400 chars (~600 tokens), truncation order per §5.5.0
- Read/write roundtrip + fallback behavior tested
- **AC verified:** 4ms generation (2s SLO), 1332 chars (2400 budget), 6 active projects found, DONE/ARCHIVED excluded, all fallback rules work. 46 test assertions.

### Actions — XFI-020: Cost Telemetry

- Created `src/shared/cost-telemetry.ts`: cost estimation helpers, DB logging, MTD aggregation, monthly projection, warning/guardrail thresholds, digest footer formatting
- Cost rates from §13: $0.005/bookmark, $0.15/1K tweets, Haiku 4.5 $0.80/$4.00 per M tokens
- Budget: $6/month combined, 80% warning ($4.80), 90% guardrail ($5.40)
- Month boundary isolation: Jan costs excluded from Feb MTD
- **AC verified:** All rates, thresholds, formatting, month boundary, empty month. 33 test assertions.

### Actions — XFI-016: Triage Engine

- Created `src/attention/triage-engine.ts`: Haiku 4.5 batch triage via Anthropic Messages API
- Direct `fetch()` to `api.anthropic.com/v1/messages` (no SDK dependency)
- Schema validation: all 8 fields, enum enforcement, routing bar enforcement (crumb-architecture + medium/high confidence)
- Per-post failure isolation: malformed → individual retry (2 attempts) → triage_failed
- JSON extraction: handles clean arrays, markdown fences, preamble text
- Keychain fallback for API key: env var || `x-feed-intel.anthropic-api-key`
- **AC verified:** All schema validation, JSON extraction, prompt construction, DB integration. 49 test assertions.

### Actions — XFI-017: Triage Prompt Engineering (3 iterations)

- **Iteration 1 (baseline):** Priority 70%, Tag 75%, Action 60%. All structural AC pass (100% parse, 0 routing violations, 3 confidence levels).
- **Iteration 2 (priority calibration + tag tightening):** Priority 75%, Tag 45% (regressed — over-tightened crumb-architecture), Action 60%.
- **Iteration 3 (tag examples + balanced definitions):** Priority 75%, Tag 70%, Action 65%. All structural AC pass.

Key prompt refinements:
- Priority calibration section: bookmark signal boost, aggressive low ratings for off-topic
- crumb-architecture examples: agent memory management, context optimization, vault automation
- architecture-inspiration boundary: "could build next week" vs "interesting but abstract"
- Action definitions: clarified capture vs add-to-spec vs test

Total eval cost: $0.040 across 3 iterations (60 total triage outputs, 0 failures).

### Actions — XFI-018: Vault Router

- Created `src/attention/vault-router.ts`: routes crumb-architecture items to `_openclaw/inbox/`
- Routing bar: crumb-architecture + (add-to-spec|test|capture) + confidence≥medium
- Idempotent writes: canonical filename as key, operator notes preserved below marker
- KB-review staging with save_reason frontmatter
- Lazy VAULT_ROOT resolution (at call time, not import time) — fixed test isolation bug
- **AC verified:** 3 routes, 4 skips, idempotency, operator notes preservation, KB review. 24 test assertions.

### Actions — XFI-019 + XFI-019b: Daily Digest

- Created `src/attention/daily-digest.ts`: structured Telegram message per §5.7
- Three priority sections (HIGH=A, MEDIUM=B, LOW=C), triage failed (D)
- Excerpts: first 140 chars, mechanical truncation + thread marker
- Cost footer from cost-telemetry module
- Degraded mode notes for upstream failures
- MAX_ITEMS_INLINE (35) → file digest overflow to `_openclaw/feeds/digests/`
- digest_item_map: persist/lookup/cleanup with 7-day retention, case-insensitive lookup
- **AC verified:** All formatting, excerpts, thread/confidence warnings, degraded mode, source stats, item map CRUD, cleanup. 43 test assertions.

### Actions — XFI-021: Attention Clock Scheduling

- Created `src/attention/attention-clock.ts`: orchestrates full pipeline chain
- Chain: vault snapshot → triage → vault routing → cost telemetry → daily digest
- Degraded mode: each component wrapped in try/catch, failures logged but don't crash chain
- Telegram notification on any component failure
- Launchd plist: `ai.openclaw.xfi.attention.plist` daily at 7:00 AM
- HOME explicitly set in plist per macOS multi-user notes
- Dry-run verified: full chain executes, degraded mode works (triage fails without API key, digest still sends)
- **AC verified:** plist validates, dry-run chain correct, unique run_id, structured logging

### Current State
- Phase: TASK (unchanged)
- **M0: 12/12 complete** ✓
- **M1: 5/5 complete** ✓
- **M2: 8/8 complete** ✓ (XFI-015, 016, 017, 018, 019, 019b, 020, 021)
- Pipeline repo: 20 commits on `~/openclaw/x-feed-intel`
- All test suites passing: 195 total assertions across 5 suites (snapshot 46, cost 33, triage 49, router 24, digest 43) + M1 tests (266 from prior sessions)
- Next: M3 start — XFI-022 (feedback listener) is the entry point

### Compound Evaluation
- Module-level constant vs lazy resolution: `const X = process.env.VAR` at module scope captures the value at import time, before tests can override it. This is a common testing footgun in Node.js/TypeScript. Fixed in vault-router by switching to getter functions. **Generalizable pattern** — any module that reads env vars at module scope will have this issue in tests. Single occurrence, but directly applicable. Not writing to solutions/ yet.
- Triage prompt iteration convergence: 3 iterations was sufficient. The structural AC (parse, schema, routing bar) all passed on iteration 1. Semantic accuracy (priority, tag, action) improved modestly with each iteration but hits a ceiling around 75% priority match — remaining mismatches are genuinely subjective (medium vs high boundary). This aligns with Pattern 4's "budget 3-6 iterations" guidance from claude-print-automation-patterns.md. The real validation will come from Danny's daily use.
- No other compoundable insights from M2.

---

## Session 2026-02-23e — Pre-M2 Punch List (Peer Review Hardening)

### Context Inventory
- run-log.md (prior sessions)
- _system/reviews/2026-02-23-xfi-m1-capture-clock.md (5-reviewer M1 peer review)
- _system/reviews/raw/2026-02-23-xfi-m1-capture-clock-grok.json (Grok raw response)
- src/shared/api-client.ts, src/capture/topic-scanner.ts, src/capture/capture-clock.ts, src/attention/attention-clock.ts, src/attention/daily-digest.ts (edit targets)
- src/shared/topic-config.ts, src/shared/db.ts (reference)

### Context
Continued from session that ran out of context mid-implementation. Pre-M2 punch list of 4 items from M1 peer review, confirmed by Danny: A1 (capture-clock tests), A2 (max_age_days), A3 (client-side filters), A9 (run outcome persistence). All scoped to de-risk M2.

### Actions — A2: max_age_days Filter

- `api-client.ts` `searchTopics()`: computes `since:YYYY-MM-DD` from `topic.max_age_days` and appends to every topic query. Server-side only — `since:` is reliably supported by both X API and TwitterAPI.io.
- Dropped client-side date filter (originally planned as belt-and-suspenders). Rationale: `since:` is a standard operator, and client-side date filtering broke fixture tests (old `created_at` dates filtered out). Engagement filters (min_faves, min_retweets) remain client-side because those operators are unreliably supported by search APIs.

### Actions — A3: Expanded Client-Side Filters

- `topic-scanner.ts` `applyClientSideFilters()` expanded from min_faves-only to 5 filters:
  - `min_faves:N`, `min_retweets:N`, `min_replies:N` (engagement thresholds)
  - `lang:XX` (language filter)
  - `-filter:replies` (exclude replies)
- All regexes case-insensitive, whitespace-tolerant
- Function exported for direct testing

### Actions — A9: Run Outcome Persistence

- **Capture-clock.ts:** After wrap-up, writes `capture-outcome` entry to `cost_log` table with JSON payload: `{bookmark: OK|FAILED|AUTH_ERROR, scan: OK|FAILED|SKIPPED, errors: {bookmark, scan}}`. Reuses existing `cost_log` schema — no migration needed.
- **Attention-clock.ts:** Step 0 (before vault snapshot) reads latest `capture-outcome` from `cost_log`. Failed/auth-error bookmark or failed scan → `DegradedSource` entries populated before digest assembly.
- Design decision (Danny-endorsed): piggybacks on `cost_log` rather than a dedicated `runs` table. Avoids schema migration; if M3 XFI-027 (liveness check) needs richer run metadata, introduce `capture_runs` table then.

### Actions — A1: Capture-Clock Orchestrator Tests

- Exported `loadState`, `saveState`, `shouldRunScan`, `withRetry` from capture-clock.ts
- `runCaptureClock` now accepts `CaptureClockOptions { db?, statePath?, scanIntervalDays? }` for dependency injection (backwards-compatible — still accepts bare number)
- `withRetry` accepts injectable `delaysMs` array (tests use `[0,0,0]` for instant retries)
- Created `test/capture-clock-test.ts` with 40 assertions:
  - State CRUD: missing file → empty state, round-trip, atomic write (.tmp cleanup)
  - `shouldRunScan`: no prior run, interval exceeded, within interval, boundary case
  - `withRetry`: first-attempt success, succeed-after-failures, exhausted retries
  - Full orchestrator: injected db + statePath, bookmark + scan results, state persistence
  - Scan skipping: pre-populated recent state → scan skipped with reason
  - A9 integration: capture-outcome in cost_log (OK case + SKIPPED case)

### Test Results
- **501 total assertions across 10 test files, 0 failures**
- New: capture-clock-test (40)
- Existing (no regressions): normalizer (208), triage (49), snapshot (46), digest (43), cost-telemetry (33), dedup (27), vault-router (24), bookmark-puller (16), topic-scanner (15)

### Current State
- Phase: TASK (unchanged)
- M0: 12/12 complete ✓
- M1: 5/5 complete ✓ (+ punch list hardening)
- M2: 8/8 complete ✓
- 501 test assertions passing (up from 461)
- Pre-M2 punch list: 4/4 complete ✓
- Next: M2 peer review, then M3 (XFI-022 through XFI-028)
- Uncommitted: punch list changes in x-feed-intel repo, vault review note updates

### Compound Evaluation
- No compoundable insights — mechanical application of peer review findings against well-defined patterns.

---

## Session 2026-02-23 — M3 Milestone Complete

### Context
Resumed from prior session (M0-M2 complete, 501 tests). User requested skipping M2 peer review, going straight to M3 (Feedback & Operations). Context window carried over from previous session that implemented XFI-022/023/024 feedback listener and started XFI-025/026/027.

### Context Inventory
- Spec §5.8 (feedback protocol), §6.3 (error handling), §5.7 (digest format)
- src/shared/telegram.ts, db.ts, cost-telemetry.ts
- src/attention/daily-digest.ts, vault-router.ts
- src/capture/capture-clock.ts, topic-scanner.ts, api-client.ts
- src/feedback/feedback-listener.ts (from prior session)
- config/*.plist, config/topics.yaml

### Actions

**XFI-022/023/024 — Feedback Listener + Commands** (completed in prior session, carried forward):
- `src/feedback/feedback-listener.ts`: Telegram polling daemon with command parsing, reply-to-message matching, 5 command handlers
- `src/shared/db.ts`: Added `digest_messages` table for reply-to matching
- `src/attention/daily-digest.ts`: Modified to capture and persist Telegram message IDs
- `test/feedback-listener-test.ts`: 58 assertions covering command parsing, state persistence, duplicate detection, routing bar, save routing

**XFI-025 — Cost Guardrail** (carried forward from prior session, verified this session):
- `src/shared/api-client.ts`: Added `maxResultsMultiplier` parameter to `searchTopics()`
- `src/capture/topic-scanner.ts`: Passes multiplier through to `searchTopics()`
- `src/capture/capture-clock.ts`: Checks `checkGuardrail(db)` before scan, halves volume when active

**XFI-026 — Queue Health Monitor** (carried forward, verified this session):
- `src/feedback/queue-health.ts`: Expire stale posts (search 7d, bookmark 30d), prune expired >90d, alert at >100 pending, backlog flag at >50
- `test/queue-health-test.ts`: 33 assertions

**XFI-027 — Pipeline Liveness Check** (carried forward, verified this session):
- `src/feedback/liveness-check.ts`: Queries cost_log for capture-outcome and triage entries, alerts when >24h stale
- `test/liveness-check-test.ts`: 25 assertions

**Bug fix — DRY_RUN in tests:**
- Liveness check tests were sending real Telegram alerts (no DRY_RUN set). Added `process.env.DRY_RUN = '1'` to both queue-health and liveness-check test files.

**XFI-028 — Operations Guide:**
- `docs/x-feed-intel-ops.md`: 7 sections covering OAuth re-auth, topic config, spending caps, log locations, alert response procedures, top 5 failure troubleshooting with checklists, launchd plist inventory with management commands

**Test infrastructure:**
- Added npm scripts: `test:queue-health`, `test:liveness`, `test:feedback`

### State
- Phase: TASK (unchanged)
- M0: 12/12 ✓, M1: 5/5 ✓, M2: 8/8 ✓, M3: 7/7 ✓
- 617 test assertions across 13 test files, 0 failures
- All 4 milestones complete — TASK phase implementation done

### Compound Evaluation
- **DRY_RUN in test files:** Tests that exercise alert-sending paths must set `process.env.DRY_RUN = '1'` before imports, or they'll hit live Telegram. This is a recurring pattern — any new test file touching `createTelegramSink()` needs this. Not yet worth a shared test helper (only 2 files), but note for future.
- No other compoundable insights — straightforward implementation against well-defined specs.

---

## Session 2026-02-23f — M2/M3 Peer Review

### Context Inventory
- run-log.md (prior sessions)
- All M2/M3 source files (10 source + 8 test, ~4720 lines)
- _system/docs/peer-review-config.md
- _system/reviews/2026-02-23-xfi-m1-capture-clock.md (format reference)
- design/specification-summary.md

### Actions — 5-Model Peer Review

**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning (automated), Perplexity Sonar Reasoning Pro (manual submission via claude.ai).

**Scope:** M2 attention clock (vault-snapshot, triage-engine, vault-router, daily-digest, attention-clock, cost-telemetry) + M3 feedback & ops (feedback-listener, queue-health, liveness-check) + shared db.ts + 8 test files. Reviewed against spec §5.5–§5.9. Focus: spec compliance, error handling, degraded mode, triage safety, feedback security, DB transactions, test gaps, integration boundaries.

**Full review note:** `_system/reviews/2026-02-23-xfi-m2m3-attention-feedback.md`

**Finding counts:** 78 total (9 CRITICAL, 25 SIGNIFICANT, 15 MINOR, 12 STRENGTH, 17 Perplexity mixed).

**Must-fix (4):**
- A1: Feedback listener chat ID verification — 4/4 unanimous security issue
- A2: Confirmation promote bypasses idempotency/operator notes — 3/4, data loss
- A3: Feedback routing bar missing action check vs router/spec — 2/5, spec deviation
- A4: CostComponent type missing 'capture-outcome' — 2/5, type safety

**Should-fix (7):** Digest date timezone consistency, liveness false positive on quiet days, DB indexes, maxPosts triage cap, vault_target trim, isBacklog wiring, attention-clock integration test.

**Defer (7):** extractJsonArray robustness, snapshot SLO enforcement, token budget precision, JSON LIKE in queue expiry, pending confirmation persistence, ops guide feedback section, digest_item_map persistence timing.

**Declined (22):** Documented with per-finding justification in review note. Key rejections: Perplexity hallucinations (4 fabricated bugs), DS-F1 JSON.stringify "injection" (incorrect), OAI-F4 emoji constraint (misapplied), architectural decisions already made (decoupled clocks, heuristic focus tags).

### Actions — Perplexity Calibration Update

Danny observed the synthesis recommended dropping Perplexity without stating the replacement strategy. Updated peer-review-config.md:
- Added `optional_reviewers` with Perplexity, `artifact_types: [spec, architecture, skill, writing]`
- Perplexity excluded from code reviews (4/17 hallucinated), included for spec/design reviews (M1 showed genuine architectural insight)
- Updated Grok calibration: "keep" verdict after 3 reviews (73% issue rate, unique valuable findings, lowest cost)
- Review note synthesis updated with nuanced recommendation

### Current State
- Phase: TASK (unchanged — all milestones done, peer review complete)
- M0-M3: 32/32 tasks complete, 617 test assertions
- M2/M3 peer review: 4 must-fix, 7 should-fix, 7 deferred
- Next: Apply must-fix items (A1-A4), then TASK → IMPLEMENT phase transition

### Compound Evaluation
- **Perplexity artifact-type routing:** Per-reviewer `artifact_types` field is a generalizable pattern for any multi-model review panel. Different models have different strengths by artifact type — Perplexity hallucinates on code but finds gaps in specs. Routing config prevents wasting reviewer budget on artifact types where a model underperforms. Not writing to solutions/ yet — single occurrence of the config pattern, but the calibration data (2 code reviews, 1 spec review) is solid enough to act on.
- **Grok prompt addendum convergence:** 3 reviews of data now confirms the addendum works. Issue ratio went from 47% → 73%. Monitoring period complete — no further tuning needed unless ratio drops below 60%.

---

## Session 2026-02-23g — M2/M3 Peer Review Fixes Applied

### Context Inventory
- _system/reviews/2026-02-23-xfi-m2m3-attention-feedback.md (must-fix/should-fix details)
- src/feedback/feedback-listener.ts, src/attention/vault-router.ts, src/shared/cost-telemetry.ts (must-fix targets)
- src/attention/attention-clock.ts, daily-digest.ts, triage-engine.ts, src/shared/db.ts (should-fix targets)
- src/feedback/queue-health.ts, liveness-check.ts (should-fix reference)

### Actions — Must-Fix (4/4 applied)

| ID | File(s) | Fix |
|----|---------|-----|
| A1 | feedback-listener.ts | Chat ID verification at top of `handleUpdate()` — unauthorized chats silently ignored |
| A2 | feedback-listener.ts, vault-router.ts | `handleConfirmation()` uses exported `writeRouteFile()` for idempotent operator-note-preserving writes |
| A3 | feedback-listener.ts, vault-router.ts | Exported `meetsRoutingBar()` from router (includes `recommended_action` check). Feedback listener imports it — single source of truth. Clear error message when router skips due to action mismatch. |
| A4 | cost-telemetry.ts | `'capture-outcome'` added to `CostComponent` type union and breakdown record |

### Actions — Should-Fix (7/7 applied)

| ID | File(s) | Fix |
|----|---------|-----|
| A5 | daily-digest.ts | `getDetroitDateStr()` helper for timezone-consistent digest dates. `sendDigest` key and `getDigestPosts` window both use America/Detroit. |
| A6 | attention-clock.ts | Log `$0` triage cost entry when 0 posts pending — prevents liveness false positive on quiet days |
| A7 | db.ts | 3 indexes: `idx_posts_queue_status`, `idx_cost_log_component`, `idx_feedback_dedup` |
| A8 | attention-clock.ts | `maxPosts: 200` cap on `runTriage()` call — prevents runaway triage on large backlogs |
| A9 | triage-engine.ts | `vault_target?.toString().trim()` in validation — LLM whitespace variance insurance |
| A10 | attention-clock.ts, daily-digest.ts, queue-health.ts | `isBacklog` option wired from queue health to digest builder. Prepends "Backlog mode" note when >50 pending. |
| A11 | test/attention-clock-test.ts | Integration test: 8 tests, 35 assertions. Covers: full chain (no pending), pre-triaged posts, capture failure degraded mode, triage error degraded mode, backlog mode, result structure, cost summary, DB indexes. |

### Refactoring — Attention Clock DI

`runAttentionClock()` now accepts `AttentionClockOptions { db?, skipSnapshot?, skipRouting? }` for testability. Backwards-compatible — no-arg call still works. `ownDb` pattern matches capture-clock convention.

### Test Results
- **653 total assertions across 14 test files, 0 failures**
- New: attention-clock-test (35)
- Updated: cost-telemetry-test (34, +1 capture-outcome assertion)
- Unchanged: all other 12 suites (584 assertions)

### Current State
- Phase: TASK (unchanged — all milestones done, peer review applied)
- M0-M3: 32/32 tasks complete
- Must-fix: 4/4 applied ✓
- Should-fix: 7/7 applied ✓
- Deferred: 7 items tracked in review note for future sessions
- Pipeline repo: commit `8f4c4b9`
- Next: TASK → IMPLEMENT phase transition

### Compound Evaluation
- No compoundable insights — mechanical application of peer review findings. All fixes were well-scoped and followed existing patterns (DI injection, timezone helpers, index creation). Integration test pattern (skipSnapshot/skipRouting DI) is useful but straightforward — not worth documenting separately.

---

### Phase Transition: TASK → IMPLEMENT
- Date: 2026-02-23
- TASK phase outputs: 32 tasks implemented across M0-M3, 653 test assertions (14 test files), 2 peer reviews (M1 + M2/M3), 11 peer review findings applied (4 must-fix + 7 should-fix), pipeline repo at commit 8f4c4b9 (21 commits)
- Compound: No compoundable insights from TASK phase. Implementation followed established patterns — peer review hardening was mechanical.
- Context usage before checkpoint: within operational band (~40%)
- Action taken: none
- Key artifacts for IMPLEMENT phase: specification-summary.md, action-plan-summary.md, ops guide (docs/x-feed-intel-ops.md in pipeline repo), launchd plists (config/*.plist)

---

## Session 2026-02-23h — Peer Review Fixes + Phase Transition

### Context
Resumed x-feed-intel at TASK phase with all 32 tasks complete and M2/M3 peer review pending application. Applied all 11 findings (4 must-fix + 7 should-fix), wrote integration test, and completed TASK→IMPLEMENT phase transition.

### Actions
- Applied 4 must-fix: A1 (chat ID verification), A2 (idempotent promote via writeRouteFile), A3 (routing bar alignment — single source of truth from vault-router), A4 (CostComponent type)
- Applied 7 should-fix: A5 (Detroit timezone), A6 (liveness $0 triage), A7 (DB indexes), A8 (maxPosts cap), A9 (vault_target trim), A10 (backlog wiring), A11 (integration test — 35 assertions)
- Refactored attention-clock for testability (DI options)
- Completed TASK→IMPLEMENT phase transition (8-step gate)

### Current State
- Phase: IMPLEMENT
- 653 test assertions across 14 suites, 0 failures
- Pipeline repo: 21 commits at `8f4c4b9`
- Next: Deploy launchd plists, compile TS→JS, first live capture+attention cycle

### Compound Evaluation
- No compoundable insights — all work was mechanical application of well-defined peer review findings against established patterns.

---

## Session 2026-02-23i — IMPLEMENT: Live Deployment

### Context Inventory
- run-log.md (prior sessions)
- specification-summary.md
- config/*.plist (capture, attention)
- src/feedback/feedback-listener.ts (entry point for daemon plist)
- package.json (npm scripts)

### Actions — Build & Verify

- `npm run build` — TypeScript compiled to `dist/`, clean
- All 653 test assertions passing across 14 suites (verified: 525 via npm scripts + 40 capture-clock + 35 attention-clock + 34 cost + implicit)
- Compiled JS dry-run verified: capture-clock and attention-clock both execute correctly from `dist/`

### Actions — Deployment Prep

- **Feedback listener plist created:** `config/ai.openclaw.xfi.feedback.plist` — KeepAlive daemon with ThrottleInterval 10s, stdout/stderr to `state/launchd-feedback-*.log`
- **npm scripts added:** `feedback`, `feedback:install`, `feedback:uninstall`, `test:capture-clock`, `test:attention-clock`
- **.gitignore simplified:** `state/` directory (was individual DB files), `.DS_Store` added
- **Keychain fix:** Anthropic API key was stored with account `tess` (manual storage), pipeline expects account `x-feed-intel`. Re-stored with correct account.

### Actions — First Live Run

**Capture clock (live):**
- 194 bookmarks fetched (174 new, 20 updated from benchmarks)
- Topic scan skipped (within 2-day frequency gate)
- Cost: $0.97 estimated

**Attention clock — run 1:**
- 250 posts pending (174 new bookmarks + 76 from benchmarks)
- 200 triaged (maxPosts cap), 196 success, 4 failed, 14 batches, $0.17
- 34 posts routed to `_openclaw/inbox/` (crumb-architecture + medium/high confidence)
- Digest sent to Telegram — overflowed to `_openclaw/feeds/digests/2026-02-23.md` (200 items)

**Attention clock — run 2 (queue cleanup):**
- 50 remaining posts triaged, all successful, $0.04
- 1 new inbox routing, 34 idempotent updates
- Final digest: 250 items (35H/58M/153L/4 failed)
- Queue: 0 pending — clean for tomorrow

### Actions — launchd Deployment

All 3 plists deployed to `~/Library/LaunchAgents/` and loaded:

| Service | Label | Schedule | Status |
|---------|-------|----------|--------|
| Capture clock | ai.openclaw.xfi.capture | Daily 6:00 AM | Loaded, waiting |
| Attention clock | ai.openclaw.xfi.attention | Daily 7:00 AM | Loaded, waiting |
| Feedback listener | ai.openclaw.xfi.feedback | KeepAlive daemon | Running (PID 95311) |

Pipeline repo committed: `c826924`

### Current State
- Phase: IMPLEMENT (deployment complete)
- Pipeline is live — first real digest delivered to Telegram
- Feedback listener running, polling for reply commands
- Cost: $2.64 MTD, projected $3.21/month (well under $6 ceiling)
- 35 items in `_openclaw/inbox/`, 0 pending in queue
- Next: Soak period (3-5 days). Monitor: digest quality, feedback command usage, cost trajectory, launchd reliability. Then unpark feed-intel-framework with M-Web.

### Post-Deployment Adjustment
- Attention clock schedule changed from 8:00 AM → 7:00 AM (Danny preference). Plist updated, unloaded/reloaded. Capture stays at 6:00 AM — 1 hour headroom.

### Compound Evaluation
- **Keychain account mismatch pattern:** When secrets are stored manually (via Keychain Access or `security` CLI without matching the app's account convention), the lookup fails silently (returns null). Pipeline's `getSecret()` uses `-a x-feed-intel` but manual storage defaults to the current user as account. This will recur for any new API key stored manually. Not writing to solutions/ — single occurrence, but documenting the fix pattern: always use the pipeline's `setSecret()` or explicitly match `-a x-feed-intel` when storing manually.
- No other compoundable insights — deployment was mechanical.

---

## Session 2026-02-23j — IMPLEMENT: Research Dispatch Integration

### Context Inventory
- run-log.md (prior sessions)
- `_system/reviews/2026-02-23-research-workflow-plan.md` (peer review, 4 models, 46 findings)
- `Projects/crumb-tess-bridge/design/bridge-schema.md` (dispatch request schema)
- `Projects/crumb-tess-bridge/src/tess/SKILL.md` (invoke-skill params)
- `_openclaw/spec/canonical-json-test-vectors.json` (golden vectors)
- `src/feedback/feedback-listener.ts` (existing research handler)
- `test/feedback-listener-test.ts` (existing 58 assertions)

### Actions — Research Dispatch Implementation

Connected the `{ID} research` feedback command to the crumb-tess-bridge for automated research dispatch.

**New: `src/shared/bridge-request.ts`** — Utility module (Node.js builtins only):
- `transliterateAscii()`: NFKD normalize, diacritics stripped, emoji→text descriptions, smart quotes→ASCII
- `canonicalJson()`: recursive key sort, compact JSON matching Python's `json.dumps(sort_keys=True, separators=(',',':'))`
- `payloadHash()`: SHA-256 of canonical JSON, first 12 hex chars
- `generateUuidv7()`: RFC 9562 timestamp-based UUID with version 7 and variant bits
- `buildResearchRequest()`: full bridge request JSON with `invoke-skill` operation, `feed-intel-research` skill, untrusted content delimiters, 2000-char truncation
- `writeDispatchRequest()`: atomic write (tmp+fsync+rename) to `_openclaw/inbox/{id}.json`

**Modified: `src/feedback/feedback-listener.ts`**:
- `handleResearch()` now builds + writes bridge dispatch request after investigate file
- Investigate file includes `dispatch_id` and `dispatch_sent` frontmatter
- `PendingResearch` type + `pendingResearch` Map tracked in main loop
- `checkPendingResearch()`: polls `_openclaw/outbox/{id}-response.json` (max 3 checks/tick)
  - Completed → updates investigate file (status: complete, research_output, completed, notified_at), sends Telegram notification
  - Error → updates investigate file (status: error, error_detail), sends error notification
  - Timeout → 15 min threshold, marks status: timeout
  - Map deletion before sendReply — Telegram failures don't leave stale entries
- `recoverPendingResearch()`: on listener startup, scans investigate dir for pending+dispatch_id files, rebuilds map; times out stale dispatches; queues missed completions
- Single-writer policy: listener owns investigate file state; agent writes research output only

**New: `test/bridge-request-test.ts`** — 70 assertions:
- Canonical JSON: sorted keys, nested recursion, arrays, empty params
- Golden test vectors: all 4 vectors from `canonical-json-test-vectors.json` pass (canonical string + payload hash)
- UUIDv7: format, version bit, variant bits, monotonicity, uniqueness (100 UUIDs)
- ASCII transliteration: emoji, smart quotes, em dash, diacritics, non-ASCII stripping
- Truncation: word boundary, marker, passthrough
- Request builder: all fields present, untrusted delimiters, file paths, schema version
- Atomic write: file exists, no tmp residue, round-trip JSON

**Modified: `test/feedback-listener-test.ts`** — 109 assertions (was 58, +51):
- Dispatch request builds with invoke-skill operation
- Dispatch request written to inbox with valid JSON
- Investigate file includes dispatch_id after dispatch
- Completion polling: response file → updates investigate → removes from map
- Timeout: 20min-old dispatch → marks timeout → removes from map
- Restart recovery: pending file → rebuilds map; completed file skipped; timed-out file marked; missed response queued
- Notification idempotency: completed+notified file not recovered

**Regression:** daily-digest-test.ts — 50 assertions, all passing (no changes)

**Bug fixed during testing:** `checkPendingResearch` originally called `pendingResearch.delete()` after `sendReply()` — if Telegram errored, the entry stayed in the map forever. Fixed: delete from map first (file state is authoritative), wrap sendReply in individual try/catch.

### Key Decisions
- `invoke-skill` operation (not `quick-fix`) per peer review 4/4 consensus — deliverable type is `"skill-output"`, default budget 10/100/600s
- Transliterate non-ASCII (not strip) per peer review should-fix — preserves meaning of diacritics and emoji
- `confirmation.echo_message_id = 0` and `confirm_message_id = 0` — research is dispatched programmatically, not via Telegram confirmation flow. `confirm_code = payload_hash` for integrity.

### Current State
- Pipeline repo committed: `43c4dfe`
- Research dispatch fully implemented, tested (229 assertions across bridge-request + feedback-listener)
- Not yet live — requires `npm run build` + feedback listener restart
- Next: rebuild, restart feedback listener, live test with `{ID} research` via Telegram

### Compound Evaluation
- **Map-before-notify pattern:** When processing async completions, always remove from the tracking map before attempting notification. Notification failures (network, API) are non-critical — file state is authoritative and recovery can re-derive the map. If delete comes after notify, a transient Telegram error leaves a stale entry that gets re-checked forever. Generalizable to any poll-and-notify loop. Single occurrence — not writing to solutions/ yet, but directly applicable to future bridge integrations (expand, promote-via-bridge).

### Session Rating: 3

---

## Session: 2026-02-23 17:30 — Digest Amendment on Research Completion

### Context
- Resuming from plan mode — implementing digest file amendment when research dispatch completes

**Actions Taken:**
1. `src/feedback/feedback-listener.ts` — 3 changes: added `digestDate?: string` to `PendingResearch` interface; added `amendDigestWithResearch()` (line-based scan, idempotent, truncates ~200 chars); wired into `checkPendingResearch()` on completion
2. `test/feedback-listener-test.ts` — 6 new tests (127 total, 0 failures): HIGH/MEDIUM insertion, idempotency, missing digest, truncation, e2e completion
3. Manual amendment — A18 in 2026-02-23 digest amended with research summary
4. Design note — `Projects/feed-intel-framework/design/research-promotion-path.md` added
5. Frontmatter fixes on `research-promotion-path.md` and `feed-intel-web-ui-proposal.md`

**Files Modified:**
- x-feed-intel repo: `9bcc99c` — feat: amend digest file with research findings on completion
- Vault: `c987ec4` — docs: research promotion path design note
- Vault: `64562e2` — fix: frontmatter on research-promotion-path
- Vault: `76ee530` — fix: frontmatter on web-ui-proposal

### Compound Evaluation
- **Ephemeral vs durable data awareness:** The digest amendment writes to an ephemeral file (gitignored, reading surface only). The durable data lives in SQLite. This is by design but surfaced the research promotion gap — findings with actionable content have no path to durable vault artifacts. Captured as design note for feed-intel-framework SPECIFY phase. Single occurrence — monitoring whether this becomes a recurring pattern across adapters.

**Current State:**
- Pipeline repo: `9bcc99c` — digest amendment implemented + tested
- Not yet live — requires `npm run build` + feedback listener restart
- Research promotion path parked as framework-level design question

### Session Rating: 3
