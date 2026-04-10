---
type: run-log
project: feed-intel-framework
domain: software
status: archived
created: 2026-02-23
updated: 2026-02-24
phase_coverage: SPECIFY + PLAN + TASK/M1
archived_from: run-log.md
archived_date: 2026-02-27
---

# Feed Intel Framework — Run Log (SPECIFY + PLAN + M1)

> Archived 2026-02-27. Covers project creation through M1 completion (18/18 tasks). Continued in [run-log.md](run-log.md).

## Session 2026-02-23 — Project Creation (Parked)

### Context
Framework spec (v0.3) created in an external session, generalizing x-feed-intel's
architecture to multiple content sources (YouTube, Reddit, HN, RSS, arxiv). Scaffolded
under Crumb governance but intentionally parked — the framework spec itself says
"don't abstract until the second adapter is ready."

### Actions
- Created project scaffold: project-state.yaml, run-log, progress-log, design/
- Moved `feed-intel-framework-project.md` → `design/specification.md`

### Current State
- Phase: SPECIFY (parked)
- Blocked on x-feed-intel reaching stable implementation
- The X adapter is the first implementation; shared infrastructure extraction happens
  when the second adapter (likely RSS) is ready
- No active work until x-feed-intel proves the architecture

## Session 2026-02-23 — Governance Review (v0.3 → v0.3.1)

### Context
x-feed-intel is now live (32 tasks complete, soak period passing). Unparking framework
project from SPECIFY (parked) to active SPECIFY. Governance review checks spec against
Crumb conventions and implementation reality before peer review and PLAN advancement.

### Context Inventory
- `Projects/feed-intel-framework/design/specification.md` (spec v0.3)
- `Projects/feed-intel-framework/project-state.yaml`
- `Projects/feed-intel-framework/design/research-promotion-path.md` (noted, not in scope for governance fixes)

### Governance Review Findings (8 items)
Applied (5 should-fix):
- **G-01:** Removed `status: SPECIFY` from spec frontmatter — project docs don't carry status field
- **G-02:** Added `digest_messages` table to §8 schema — needed by feedback listener for reply-to matching
- **G-03:** Added cursor state migration sub-steps to §8.1 step 7 — explicit `capture-state.json`/`feedback-state.json` → `adapter_state` migration
- **G-04:** Enumerated columns/indexes in §8.1 step 8 — `routed_at`, `source_type`, `subcomponent`, plus 4 named indexes
- **G-05:** Bumped `updated` date

Verified (3 notes, no action):
- **G-06:** Vault path references valid on disk
- **G-07:** Cross-references to x-feed-intel spec valid
- **G-08:** Implementation drift already covered in §8.1 and §13

### Spec Version
v0.3 → v0.3.1 with changelog entry documenting all findings.

### Remaining Before SPECIFY → PLAN
- Peer review of spec v0.3.1 (next step)
- Integrate research-promotion-path.md design note into spec (or resolve its 4 open questions)
- Generate specification-summary.md (phase transition gate requirement)

## Session 2026-02-23 — Peer Review + Synthesis (v0.3.1 → v0.3.2)

### Context
Full 5-model peer review of spec v0.3.1 before PLAN advancement. x-feed-intel is
live, research-promotion-path raises unaddressed cross-adapter questions, and
multi-source abstractions are untested — strong review target.

### Context Inventory
- `Projects/feed-intel-framework/design/specification.md` (spec v0.3.1)
- `Projects/feed-intel-framework/design/research-promotion-path.md`
- `_system/docs/peer-review-config.md`
- `.claude/skills/peer-review/peer-review.md`
- `.claude/agents/peer-review-dispatch.md`

### Peer Review (5 models, 77 findings)
Dispatched to OpenAI (23), Google (9), DeepSeek (12), Grok (15), Perplexity (18).
Perplexity review arrived via inbox (manual submission); others via automated dispatch.

**Synthesis triage (20 action items):**
- 6 must-fix: adapter_state enum, research promotion path (new §5.11), migration plan
  rewrite, triage_attempts column, collision handling (routed_at ordering), digest_messages
  part_index/part_count
- 8 should-fix: effective_tier invariant, RSS hash truncation, cost guardrail timing,
  attention clock failure isolation, digest delivery clarification, Phase 1b split
  (1b.1/1b.2), collision merge frontmatter, adapter health/degraded state
- 6 defer: aggregate daily ceiling (later promoted to should-fix), per-feed caps, FK
  consistency stance, id_aliases window, environment config, manifest_version upgrade path

**7 findings declined** with reasoning (incorrect assumptions, overkill, out-of-scope).

Operator reviewed synthesis and approved with adjustments:
- A2: Dedicated §5.11 instead of extending §5.7
- A3: Migration as own PLAN task
- A5: Skip vault_path column — document derivation rule
- A6: part_index/part_count only — defer digest_runs
- A12: Phase 1b split clearly better than extraction map
- A15: Promoted from defer to should-fix (aggregate daily ceiling)
- New: "last verified" annotations on §7 API assumptions

All 21 items applied and self-verified via Explore subagent.

### Review Artifacts
- `_system/reviews/2026-02-23-feed-intel-framework-specification.md` — full review note with synthesis
- `_system/reviews/raw/2026-02-23-feed-intel-framework-specification-{openai,google,deepseek,grok}.json`
- `_system/reviews/raw/2026-02-23-feed-intel-framework-specification-perplexity.md`

### Spec Version
v0.3.1 → v0.3.2 with changelog entry.

## Session 2026-02-23 — Scoped §8.1 Migration Review (v0.3.2 → v0.3.3)

### Context
Operator requested scoped 2-3 model review of the rewritten §8.1 migration plan —
the highest-risk section. 3 reviewers (OpenAI, DeepSeek, Grok) focused on feasibility
and rollback completeness.

### Scoped Review (3 models, all returned "needs rework")
6 consensus themes (flagged by 2+ reviewers):
1. Wikilink grep/replace underspecified (3/3) — regex didn't cover heading refs, embeds, display text
2. Restartability/idempotency not substantiated (3/3) — no concrete guards
3. Cursor state migration divergence risk (3/3) — globally monotonic semantics unclear
4. Stage 4 verification gaps (3/3) — insufficient checks
5. Launchd quiesce imprecise (3/3) — no pgrep verification or lockfile
6. Backup scope too narrow (2/3) — missing cursor JSON files

Unique critical: OAI-F2 — alias population must happen BEFORE canonical_id rewrite
(order dependency the v0.3.2 plan got wrong).

### Fixes Applied (complete §8.1 rewrite)
- Pre-migration prerequisites: quiesce with pgrep + lockfile, full backup including cursor JSONs, pre-migration audit
- Stage 1 (DB): id_aliases populated first, then canonical_id rewrite; column-exists idempotency guards; IF NOT EXISTS on all new tables/indexes
- Stage 2 (cursors): JSON format validation before migration; documented globally monotonic cursor semantics
- Stage 3 (vault files): manifest-logged file renames; comprehensive wikilink regex (standard, display text, heading/block refs, transclusions, embeds, .md extensions)
- Stage 4 (verification): expanded from 3 to 8 checks including wikilink regex scan, alias coverage, cursor validation, spot-check
- Stage 5 (re-enable): config update, lockfile removal, launchctl bootstrap, monitoring window
- Rollback: includes cursor JSON restoration and lockfile cleanup

### Review Artifacts
- `_system/reviews/2026-02-23-feed-intel-framework-migration.md` — scoped review note with synthesis
- `_system/reviews/raw/2026-02-23-feed-intel-framework-migration-{openai,deepseek,grok}.json`

### Spec Version
v0.3.2 → v0.3.3 with changelog entry.

### Remaining Before SPECIFY → PLAN
- ~~Generate specification-summary.md~~ — done
- ~~Update project-state.yaml to reflect v0.3.3~~ — done
- research-promotion-path.md 4 open questions now resolved by §5.11 — update design note status (deferred, non-blocking)

### Phase Transition: SPECIFY → PLAN
- Date: 2026-02-23
- SPECIFY phase outputs:
  - `design/specification.md` (v0.3.3, governance + 5-model peer review + scoped migration review)
  - `design/specification-summary.md`
  - `design/research-promotion-path.md` (design input, 4 open questions resolved by spec §5.11)
  - `_system/reviews/2026-02-23-feed-intel-framework-specification.md` (full 5-model review)
  - `_system/reviews/2026-02-23-feed-intel-framework-migration.md` (scoped 3-model review)
- Compound: Scoped peer review (subset of reviewers on highest-risk section) proved effective — 3 reviewers on §8.1 caught 6 consensus issues including a critical ordering bug (alias before rewrite). Pattern candidate: "scoped review for high-risk sections after full review" — monitor for second instance before promoting to `_system/docs/solutions/`. Routed: run-log note only (single instance).
- Context usage before checkpoint: moderate (post-compaction session, manageable)
- Action taken: none
- Key artifacts for PLAN phase: `design/specification-summary.md`, `design/specification.md` §13 (phasing), §8.1 (migration plan)

## Session 2026-02-23 — Action Plan Decomposition + Peer Review

### Context
PLAN phase work: decompose spec v0.3.3 into milestones and atomic tasks using
action-architect skill. Followed by 5-model peer review (4 automated + 1 manual
Perplexity) and finding application.

### Context Inventory (5 docs, standard tier)
- `design/specification-summary.md` (primary context)
- `design/specification.md` §4-6, §8-8.1, §9, §11, §13-15 (targeted reads)
- `_system/docs/overlays/overlay-index.md` (no matches)
- `_system/docs/solutions/*.md` (scanned, none relevant)
- `Projects/x-feed-intel/project-state.yaml` (predecessor status: IMPLEMENT, soak passing)

### Action Plan Created (v1)
- `design/action-plan.md` — 7 milestones (M1-M7, M6-M7 deferred)
- `design/tasks.md` — 40 tasks (FIF-001–FIF-040) across 5 implementation milestones
- `design/action-plan-summary.md` — condensed summary

### Peer Review (5 models, 63 findings)
Dispatched to OpenAI GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking,
Grok 4.1 Fast Reasoning (automated) + Perplexity Sonar Reasoning Pro (manual).

- 5 CRITICAL, 32 SIGNIFICANT, 18 MINOR, 10 STRENGTH
- 10 consensus findings, 8 unique insights, 2 contradictions
- 16 action items: 2 must-fix, 11 should-fix, 3 defer
- 19 findings declined with reasoning

Strongest consensus (5/5): FIF-023 over-scoped — bundled verification, orchestrator,
and rollback into one task.

Perplexity calibration note: "Needs rework" verdict appeared for 3rd consecutive
review without findings supporting that severity. Logged to peer-review-config.md:
treat Perplexity's summary verdict as zero signal.

### Findings Applied (v1 → v2, 43 tasks)
**Must-fix:**
- A1: Split FIF-023 into 3 tasks (verification suite, orchestrator, rollback) — renumbered FIF-024+ to FIF-043
- A2: Sharpened non-binary ACs (FIF-029 parity ≥90%/50 items, FIF-033 signal quality formula, FIF-038 circuit breaker thresholds)

**Should-fix (11):**
- A3: Schema init in FIF-001 | A4: Staging migration env (new FIF-020) | A5: FIF-008 risk → high | A6: FIF-007 risk → medium + hot-reconfig test | A7: Rollback backup-first | A8: RSS URL precedence | A9: FIF-030 dep relaxed to FIF-005 | A10: Shared alert + health_check() | A11: Transitive deps explicit | A12: Extraction risks in M1 table | A13: Weekly aggregate in FIF-015

**Deferred (3):** Gantt lanes, Phase 2/3 metrics, 3-way collision test (A16 applied anyway to FIF-011)

**Net change:** 40 → 43 tasks, 5 → 7 high-risk tasks, M2 expanded 8 → 11 tasks

### Review Artifacts
- `_system/reviews/2026-02-23-feed-intel-framework-action-plan.md` — full review note with synthesis
- `_system/reviews/raw/2026-02-23-feed-intel-framework-action-plan-{openai,google,deepseek,grok}.json`
- `_system/reviews/raw/2026-02-23-feed-intel-framework-action-plan-perplexity.md`

### Current State
- Action plan v2 ready for approval
- Next: operator approval → PLAN → TASK phase transition

## Session 2026-02-24 — PLAN → TASK Phase Transition

### Phase Transition: PLAN → TASK
- Date: 2026-02-24
- PLAN phase outputs:
  - `design/action-plan.md` (v2, 43 tasks across 5 milestones, peer-reviewed)
  - `design/tasks.md` (FIF-001–FIF-043)
  - `design/action-plan-summary.md`
  - `_system/reviews/2026-02-23-feed-intel-framework-action-plan.md` (5-model review)
- Compound: PLAN phase involved 5-model peer review producing 16 applied findings. Key non-obvious decisions: RSS Phase 0 parallelizable with M2, heavy-tier triage deferred to M4, FIF-023 split into 3 migration tasks (critical 5/5 consensus). Perplexity verdict calibration logged to peer-review-config. No new artifacts or patterns — run-log note only.
- Context usage before checkpoint: <50% (fresh session, light load)
- Action taken: none
- Key artifacts for TASK phase: `design/tasks.md`, `design/action-plan-summary.md`, `design/specification.md` (targeted reads as needed)

### FIF-001: Framework project structure and module layout — DONE

**Deliverables:**
- Project scaffold at `/Users/tess/openclaw/feed-intel-framework/`
- 8 placeholder modules: manifest, capture, triage, digest, router, feedback, cost, health
- Schema initialization (`src/shared/schema.ts`) — all 8 tables from §8 with indexes, IF NOT EXISTS idempotency
- DB connection (`src/shared/db.ts`) — configurable path, WAL mode, foreign keys
- Migration runner (`src/shared/migrate.ts`)
- README with layout diagram and module responsibility table
- 46 unit tests (10 groups) covering table creation, column verification, composite PKs, indexes, idempotency
- TypeScript build clean, all tests passing

**AC verification:** all 4 criteria met (directory structure, README, schema init, tests)

### FIF-002: Unified content types, validation, URL canonicalization — DONE

**Deliverables:**
- `src/shared/types.ts` — UnifiedContent interface + all supporting types (SourceType, ContentType, TriageTier, QueueStatus, SourceInstance, Author, Content, Engagement, Metadata)
- `src/shared/validate.ts` — validates all required fields, enums, canonical_id prefix invariant, ISO 8601 timestamps, nested content/metadata structure
- `src/shared/canonicalize-url.ts` — 6-step URL canonicalization (lowercase, port strip, 20+ tracking params, fragments, query sort)
- 50 unit tests (25 groups) covering validation positive/negative cases + all 6 canonicalization steps + edge cases
- TypeScript build clean, all tests passing

**AC verification:** all 4 criteria met (types match §5.1, validation works, canonicalize_url 6 steps, tests pass)

### FIF-003: Adapter state persistence layer — DONE

**Deliverables:**
- `src/shared/adapter-state.ts` — full CRUD (get, getCheckpoint, list, upsert, saveCheckpoint, delete), stale cursor detection (isCursorStale), atomic pipeline checkpoint (withAtomicCheckpoint wraps step+save in transaction)
- 32 unit tests (16 groups) covering CRUD round-trips, stream_id independence, JSON parsing, stale detection with time thresholds, atomic save-on-success / rollback-on-failure
- TypeScript build clean, all tests passing

**AC verification:** all 4 criteria met (CRUD by key, JSON round-trip, atomic update, stale detection)

### FIF-004: Dedup store with within-source merge — DONE

**Deliverables:**
- `src/shared/dedup.ts` — dedupBatch (insert-or-merge in transaction), isKnown, getPostsByStatus; merge appends source_instances, refreshes engagement (newer wins, null falls back to existing), appends matched_topics (deduplicated), backfills url_hash
- 35 unit tests (14 groups) covering insert, merge, source_instance append, last_seen_at update, engagement refresh + null fallback, topic append-only, atomicity rollback, cross-source coexistence, url_hash backfill
- TypeScript build clean, all tests passing

**AC verification:** all 5 criteria met (insert-or-merge, source_instances append, engagement refresh, topics append-only, tests pass)

### Spec Amendment: Web UI (v0.3.3 → v0.3.4)

Applied web UI spec amendment from inbox. Originally drafted in claude.ai session, decisions resolved in x-feed-intel Session 2026-02-23c but never landed in framework spec.

**Changes applied:**
- Spec: §5.12 (Web Presentation Layer — Cloudflare Tunnel + Access, Express/EJS/Tailwind, direct SQLite read, digest rendering, feedback HTTP API, Telegram notification transition)
- Spec: §5.13 (Investigate Action — 6th feedback command, async Tess sweep, volume cap, investigation brief template)
- Spec: §5.6 web UI transition note, §5.7 HTTP feedback path note, §8 feedback command enum update
- Spec: M-Web phase in §13 (parallel with M3/M4 after M2), §14.8 success criterion, §15 Cloudflare dependencies
- Action plan: M-Web milestone with dependency graph and work packages
- Tasks: FIF-W01–FIF-W08 (8 tasks) in new M-Web section
- Action plan summary and spec summary updated

**Operator decisions on flagged items:**
1. Scope growth (43→51): acknowledged, not creep — documenting always-intended work
2. Parallel framing: renamed from "Phase 1b.3" to "M-Web (parallel with M3/M4)" — not a sequential gate
3. FIF-W08 cost model: split — skeleton task with decision gate annotation ("Tess sweep goes live only after LLM model + cost estimate resolved")
4. Prototype: stays in x-feed-intel, referenced not moved
5. Peer review: skipped — decisions are pre-resolved, Crumb + operator reviewed amendment

### Session End — 2026-02-24

**Session scope:** PLAN → TASK transition + first 4 M1 tasks + web UI spec amendment

**Work completed:**
- Phase transition: PLAN → TASK (action plan v2 approved)
- FIF-001: Project scaffold, schema init (8 tables, 9 indexes), README — 46 tests
- FIF-002: Unified content types, validation, URL canonicalization — 50 tests
- FIF-003: Adapter state persistence (CRUD, atomic checkpoint, stale detection) — 32 tests
- FIF-004: Dedup store with within-source merge (engagement refresh, topics append-only) — 35 tests
- FIF-025/FIF-026 AC amendments: pre-migration prerequisites added to orchestrator, rollback references orchestrator's backup
- Spec amendment v0.3.3 → v0.3.4: web UI (§5.12-§5.13), M-Web milestone (8 tasks, parallel with M3/M4)
- Fixed 4 Perplexity raw review frontmatter warnings

**Compound:** Session established a productive implementation cadence — 4 tasks in one session with clean test suites (163 tests total). The pattern of reading x-feed-intel source for reference before implementing framework equivalents worked well for maintaining consistency while generalizing. The web UI amendment application mid-session (between implementation tasks) was a natural break point — spec amendments don't need their own session. No new patterns or system gaps identified. Routed: run-log note only.

**Next session:** FIF-005 (adapter manifest loader) — critical path, unlocks 6 downstream tasks.

## Session 2026-02-24 — Manual Intake Decision Filing

### Actions
- Routed `_inbox/manual-intake-adapter-draft.md` → `design/manual-intake-adapter-decision.md`
- Added M-Manual milestone placeholder to action plan Deferred Work section
- Updated action-plan-summary.md with M-Manual entry
- No task decomposition — deferred until M2 proves adapter contract and open questions are resolved

### Decision Recorded
Manual intake (Tess → framework via Telegram) scoped as a framework source adapter, not a standalone project. Lightweight adapter: skips/minimizes triage, uses standard vault router. Activates after M2 + one non-X adapter proves the contract.

## Session 2026-02-24 — FIF-005 through FIF-008 Implementation

### Context
Continuing M1 framework core infrastructure build. FIF-005 (manifest loader) was
completed in a prior session. This session implements FIF-006 (capture clock),
FIF-007 (lifecycle management), and FIF-008 (triage engine) — completing WP-2
(adapter management) and WP-3's first task (triage pipeline).

### Context Inventory
- `src/shared/adapter-state.ts` — cursor persistence (FIF-003)
- `src/shared/dedup.ts` — dedup store (FIF-004)
- `src/shared/schema.ts` — DB schema (FIF-001)
- `src/shared/types.ts` — unified content types (FIF-002)
- `src/manifest/index.ts` — manifest loader (FIF-005)
- `design/specification.md` — spec v0.3.4 (§4.1, §5.3, §6.2, §9)
- x-feed-intel `src/attention/triage-engine.ts` — reference implementation

### FIF-006: Capture Clock Orchestrator — DONE
- `src/capture/index.ts`: 7 exported functions, 8 type exports
- `validateCronExpression` wraps cron-parser v5 for semantic validation
- `shouldRunNow` computes prev scheduled time vs last run
- `withRetry` with injectable delay for testing
- `runAdapterCapture` with transaction-wrapped pipeline + checkpoint
- `runCaptureCycle` top-level orchestrator with error isolation
- Added `cron-parser` ^5.5.0 dependency (types bundled, no @types needed)
- 53 tests

### FIF-007: Adapter Lifecycle Management — DONE
- `src/lifecycle/index.ts`: 4 exported functions, 2 type exports
- `checkStaleCursor` / `handleStaleCursor` for cursor age detection + cold start
- `checkAdapterLifecycle` pre-run lifecycle check (disabled/no_adapter/stale/enabled)
- `diffManifestChanges` compares hot-reconfigurable fields only
- Integration tests verify disable-at-boundary, re-enable-preserves-cursor, stale-triggers-fresh-start, mid-run-change-next-cycle
- Implemented via worktree-isolated subagent
- 52 tests

### FIF-008: Triage Engine — DONE
- `src/triage/index.ts`: 10 exported functions, 10 type exports
- LLM call injected as `TriageFn` callback — engine handles batching, validation, persistence, cost
- `validateTriageResult` enforces x-feed-intel §5.5.1 schema + routing bar logic
- `prepareTriageItem` applies tier-based full_text inclusion + token limit truncation
- `resolveEffectiveTier` for per-item override vs manifest default
- `buildTriageSystemPrompt` constructs shared prompt + vault snapshot + source preamble
- `writeTriageResults` / `deferItems` for DB state transitions
- `runTriage` full pipeline: query pending → prepare → defer oversized → batch → call → validate → write → log cost
- Per-item 12K token cap with deferral, error isolation per batch
- 90 tests

### Test Suite
- schema-test: 46 | types-test: 50 | adapter-state-test: 32 | dedup-test: 35
- manifest-test: 69 | capture-test: 53 | lifecycle-test: 52 | triage-test: 90
- **Total: 427 tests, 0 failures**

### Design Decisions
1. **cron-parser v5 API:** `CronExpressionParser.parse()` not v4's `parseExpression()`. Types bundled.
2. **Triage LLM injection:** Engine doesn't call LLMs directly — `TriageFn` callback makes it fully testable without HTTP mocks.
3. **Routing bar enforcement in validator:** Bidirectional — rejects both false-positive and false-negative vault_target.
4. **Validation ID tracking fix:** When a batch result has an invalid schema, remove from `expectedIds` before missing-check to avoid double-counting failures.

### M1 Progress
- WP-1 (FIF-001–004): DONE (4/4)
- WP-2 (FIF-005–007): DONE (3/3)
- WP-3 (FIF-008–010): 1/3 (FIF-008 done, FIF-009 + FIF-010 pending)
- WP-4 (FIF-011–014): 0/4
- WP-5 (FIF-015–017): 0/3
- WP-6 (FIF-018): 0/1
- **Overall M1: 8/18 tasks complete**

**Next:** FIF-009 (triage deferred retry) or FIF-010 (vault snapshot generator) — both unblocked.

## Session 2026-02-24 — FIF-009 and FIF-010 Implementation

### Context
Continuing M1 framework core build. Completing WP-3 (triage pipeline): FIF-009
(deferred retry logic) and FIF-010 (vault snapshot generator).

### Context Inventory
- `src/triage/index.ts` — triage engine (FIF-008)
- `src/shared/schema.ts` — DB schema (FIF-001)
- `src/shared/types.ts` — unified content types (FIF-002)
- `src/capture/index.ts` — capture clock (FIF-006)
- `test/triage-test.ts` — existing triage test patterns
- x-feed-intel `src/attention/vault-snapshot.ts` — reference implementation
- `design/tasks.md` — task ACs

### FIF-009: Triage Deferred Retry Logic — DONE
- Added to `src/triage/index.ts`: `getDeferredPosts`, `markTriageFailed`, `runDeferredRetry`
- New types: `DeferredRetryOptions`, `DeferredRetryResult`
- Retry flow: deferred items picked up next cycle, counted against `maxItemsPerCycle` budget
- Items with `triage_attempts < 3`: re-prepare at manifest tier, re-defer if still over cap
- Items with `triage_attempts >= 3`: force to lightweight tier (strip full_text)
- Force-triage failure (token cap or LLM error) → `triage_failed`
- Configurable `maxAttempts` (default 3)
- Excerpt preserved across retries (no re-summarize)
- 75 tests covering: getDeferredPosts (ordering, limits, source isolation), markTriageFailed,
  basic retry, force-lightweight, LLM failures, budget limits, mixed retry types,
  excerpt preservation, cost tracking, batching, source isolation, full lifecycle

**AC verification:** all 7 criteria met (retry next run, attempts incremented, counts against
max_items_per_cycle, skips re-summarize, force-lightweight after 3, triage_failed on force failure, tests pass)

### FIF-010: Vault Snapshot Generator — DONE
- `src/snapshot/index.ts`: 8 exported functions, 3 type exports
- Identical to x-feed-intel §5.5.0 with injectable `SnapshotConfig` for testability
- `scanProjects`: reads project-state.yaml, filters to active phases (SPECIFY/PLAN/TASK/IMPLEMENT/ACT)
- `readOperatorPriorities`: strips frontmatter + boilerplate, fallback "No priorities set."
- `scanOutbox`: recent 7-day status/stage JSONs + markdown headings, dedup, cap 10
- `deriveFocusTags`: project_class + well-known name patterns (crumb, skill, feed-intel)
- `enforceTokenBudget`: 600 token / 2400 char budget, trims topics first then focus descriptions
- `generateVaultSnapshot`: full pipeline with timing
- `writeVaultSnapshot` / `readVaultSnapshot`: atomic write + YAML round-trip
- `formatSnapshotForTriage`: human-readable string for triage system prompt
- 76 tests covering: project scanning (active/done/archived, ACT, truncation, malformed, fallbacks),
  operator priorities (extraction, boilerplate, missing), outbox scanning (JSON, markdown, dedup, caps),
  focus tags (project_class, well-known patterns, caps), token budget enforcement,
  integration (full generation, empty vault, multi-project), write/read roundtrip,
  triage formatting, SLO (2ms < 2000ms limit), token budget integration

**AC verification:** all 5 criteria met (identical to §5.5.0, generated once at clock start,
shared across runs, same budget/cadence/fallbacks, tests pass)

### Test Suite
- schema-test: 46 | types-test: 50 | adapter-state-test: 32 | dedup-test: 35
- manifest-test: 69 | capture-test: 53 | lifecycle-test: 52 | triage-test: 90
- deferred-retry-test: 75 | snapshot-test: 76
- **Total: 578 tests, 0 failures**

### M1 Progress
- WP-1 (FIF-001–004): DONE (4/4)
- WP-2 (FIF-005–007): DONE (3/3)
- WP-3 (FIF-008–010): DONE (3/3)
- WP-4 (FIF-011–014): 0/4
- WP-5 (FIF-015–017): 0/3
- WP-6 (FIF-018): 0/1
- **Overall M1: 10/18 tasks complete**

**Next:** FIF-011 (vault router with collision detection) or FIF-012 (per-source digest renderer) — WP-4 output pipeline.

## Session 2026-02-24 — FIF-011 and FIF-012 Implementation

### Context
Continuing M1 framework core build. WP-4 output pipeline: FIF-011
(vault router with collision detection) and FIF-012 (per-source digest renderer).

### Context Inventory
- `src/router/index.ts` — vault router (creating)
- `src/triage/index.ts` — triage engine (FIF-008) + deferred retry (FIF-009)
- `src/shared/schema.ts` — DB schema (FIF-001)
- `src/shared/types.ts` — unified content types (FIF-002)
- `src/shared/dedup.ts` — dedup store (FIF-004)
- x-feed-intel `src/attention/vault-router.ts` — reference implementation
- x-feed-intel `src/attention/daily-digest.ts` — reference implementation
- `design/specification.md` §5.5, §5.6 — router and digest specs

### FIF-011: Vault Router with Collision Detection — DONE
- `src/router/index.ts`: 11 exported functions, 5 type exports
- Routing bar: 3-way AND gate (crumb-architecture + action + confidence)
- `parseCanonicalId` / `buildFilename`: canonical_id → vault file path
- `checkUrlHashCollision`: first-to-route wins via `ORDER BY routed_at ASC LIMIT 1`
- `generateFileContent`: full markdown with YAML frontmatter + triage assessment + operator marker
- `generateCollisionAppendSection`: "Also discovered via {source_type}" note
- `addAdditionalSource`: frontmatter additional_sources list manipulation (create/append/dedup)
- `appendCollisionNote`: insert before operator marker or append to end
- `setRoutedAt` / `getRoutablePosts`: DB write-through for current-run tracking
- `routeTriagedPosts`: main pipeline — routing bar → collision check → create/append → set routed_at
- 102 tests covering: routing bar combinations, filename helpers, collision detection (including
  3-way X→RSS→YouTube chain), file content generation, frontmatter manipulation,
  basic routing, collision integration, no-url_hash handling, getRoutablePosts, operator notes preservation

**AC verification:** all criteria met (routing bar, collision via url_hash first-to-route wins,
3-way collision test, file creation + append, routed_at write-through, tests pass)

### FIF-012: Per-Source Digest Renderer — DONE
- `src/digest/index.ts`: 14 exported functions, 5 type exports
- Source name in header: `formatSourceName` maps source_type → display name (📡 YouTube Intel — Feb 21, 2026)
- Priority sections: HIGH/MEDIUM/LOW + TRIAGE FAILED with item IDs (A01/B01/C01/D01)
- `buildDigest`: main text builder with per-priority formatting, excerpts (140-char truncation),
  thread context markers, low-confidence warnings, stats line, command hint
- `splitDigestMessage`: auto-splits at 4096 chars on newline boundaries with "... continued (N/M)" headers
- `deliverDigestParts`: injectable sendFn callback, synchronous delivery with configurable delay (500ms default)
- `shouldSendDigest`: cadence (daily/weekly), min_items threshold, send_empty suppression
- `getLastDigestCutoff` / `setLastDigestCutoff`: weekly accumulation via adapter_state cursor
- `getDigestPosts`: per-source query with optional cutoff, triage_failed items get default triage
- `writeFileDigest`: max_items_inline overflow to vault markdown file with frontmatter
- `persistDigestMessageIds` / `lookupDigestByMessageId`: digest_messages table for feedback reply matching
- `renderDigest`: full pipeline — query posts → check cadence → build text → split/overflow → update cursor
- 173 tests covering: source names, item IDs, excerpt truncation, header formatting, empty digest,
  priority sections, item map, triage failed, high/medium/low/failed formatting, thread context,
  no-author handling, footer, message splitting (1-part, 2-part, 5-part, real content), cadence logic
  (daily, weekly, send_empty, min_items), cutoff cursor, getDigestPosts (filtering, triage_failed, cutoff,
  needs_context), file digest overflow, multi-part delivery (single, multi with delay verification,
  partial failure, ok:false), message persistence, renderDigest integration (basic daily, suppressed,
  min_items, weekly cadence, overflow, multi-source isolation, mixed priorities, weekly accumulation)

**AC verification:** all 8 criteria met:
1. Source name in header ✓ (formatSourceName per source_type)
2. Auto-splits at 4096 chars with "continued (N/M)" ✓ (splitDigestMessage)
3. Synchronous multi-part delivery with 500ms delay ✓ (deliverDigestParts)
4. Respects cadence (daily/weekly) and min_items ✓ (shouldSendDigest)
5. Weekly accumulation uses last_digest_cutoff_at ✓ (adapter_state cursor)
6. send_empty: false suppresses empty-day messages ✓
7. max_items_inline overflow to vault file ✓ (writeFileDigest)
8. Unit tests pass ✓ (173/173)

### Test Suite
- schema-test: 46 | types-test: 50 | adapter-state-test: 32 | dedup-test: 35
- manifest-test: 69 | capture-test: 53 | lifecycle-test: 52 | triage-test: 90
- deferred-retry-test: 75 | snapshot-test: 76 | router-test: 102 | digest-test: 173
- **Total: 853 tests, 0 failures**

### M1 Progress
- WP-1 (FIF-001–004): DONE (4/4)
- WP-2 (FIF-005–007): DONE (3/3)
- WP-3 (FIF-008–010): DONE (3/3)
- WP-4 (FIF-011–014): 2/4 (FIF-011, FIF-012 done; FIF-013, FIF-014 pending)
- WP-5 (FIF-015–017): 0/3
- WP-6 (FIF-018): 0/1
- **Overall M1: 12/18 tasks complete**

**Next:** FIF-013 (delivery scheduler) or FIF-014 (reply-based feedback protocol) — remaining WP-4.

### Session End — 2026-02-24

**Session scope:** WP-4 output pipeline — FIF-011 vault router + FIF-012 digest renderer

**Work completed:**
- FIF-011: Vault router with cross-source collision detection (routing bar, url_hash first-to-route wins, 3-way collision chain, write-through tracking) — 102 tests
- FIF-012: Per-source digest renderer (source-specific headers, priority sections, 4096-char auto-splitting, multi-part delivery, daily/weekly cadence, min_items/send_empty suppression, weekly accumulation cursor, max_items_inline overflow) — 173 tests
- Full suite: 853 tests, 0 failures across 12 suites

**Compound:** Session continued the productive implementation cadence from prior sessions — 2 tasks, 275 new tests, clean suite. The digest renderer required adapting x-feed-intel's X-specific daily-digest to a source-agnostic framework version with cadence/threshold/splitting logic that the single-source version didn't need. The injectable `sendFn` callback pattern (matching triage's `TriageFn`) keeps delivery testable without Telegram coupling. No new patterns or system gaps identified. Routed: run-log note only.

## Session 2026-02-24 — FIF-013 and FIF-014 Implementation

### Context
Completing WP-4 output pipeline: FIF-013 (delivery scheduler) and FIF-014
(reply-based feedback protocol). These are the last two WP-4 tasks.

### Context Inventory
- `src/digest/index.ts` — digest renderer (FIF-012)
- `src/shared/schema.ts` — DB schema (FIF-001)
- `src/shared/types.ts` — unified content types (FIF-002)
- `src/manifest/index.ts` — manifest loader (FIF-005)
- x-feed-intel `src/feedback/feedback-listener.ts` — reference implementation
- x-feed-intel `src/attention/daily-digest.ts` — reference delivery flow
- `design/specification.md` §4.1, §5.6, §5.7

### FIF-013: Delivery Scheduler — DONE
- `src/delivery/index.ts`: 10 exported functions, 6 type exports
- Two-phase model per §4.1: Phase 1 stages rendered digests, Phase 2 delivers at configured time
- `stageDigestForDelivery` / `getStagedDigest`: persist rendered digest parts in adapter_state (component='delivery', stream_id=digestDate)
- `getStagedDigestsSorted`: retrieves all staged digests for a date, sorted by digest.time (primary) then adapter.id (secondary)
- `isDigestReady`: compares current Detroit time against adapter's configured digest.time
- `isLateMode`: detects when triage completion exceeded earliest digest.time
- `appendLateFooter`: appends "⏱ Late — triage overran budget" to last part (immutable)
- `runDeliverySchedule`: main orchestrator — get staged → detect late → filter ready → send → persist message IDs → clear staged
- `getCurrentTimeMinutes` / `parseTimeToMinutes`: Detroit-timezone time comparison helpers
- 124 tests covering: time parsing, Detroit TZ conversion, digest readiness, late mode detection (single/multi-source, disabled), late footer (single/multi-part, immutability), staging CRUD (round-trip, suppression, overwrite, multi-source, multi-part, overflow), sorted retrieval (time primary, id secondary, disabled exclusion, 3-source), clearing (isolation), delivery orchestration (basic, not-yet-ready, staggered, all-ready, late mode immediate, late ordering, multi-part, multi-part late footer, message persistence, no-op, failure, exception, secondary sort, triageEndTime)

**AC verification:** all criteria met:
1. Separate from triage ✓ (Phase 1 stages, Phase 2 delivers)
2. Sends at configured digest.time ✓ (isDigestReady + Detroit TZ)
3. Late-mode ordering: digest.time primary, adapter.id secondary ✓
4. "Late — triage overran budget" footer ✓ (appendLateFooter)
5. Unit tests pass ✓ (124/124)

### FIF-014: Reply-Based Feedback Protocol — DONE
- `src/feedback/index.ts`: 18 exported functions, 7 type exports
- `parseCommand`: regex-based parser for `{ID} {command} [argument]` format, case-insensitive, validates item ID (A-D prefix + 2 digits) and 5 commands
- `persistDigestItemMap` / `lookupDigestItem`: item map persistence via adapter_state (component='digest_items'), enables digest item ID → canonical_id resolution
- `resolveAlias`: id_aliases table lookup with 45-day expiry enforcement
- `resolveCanonicalId`: direct posts lookup with alias fallback
- `resolveItemFromReply`: full resolution chain (telegram message → source+date → item map → canonical_id with alias fallback)
- `isDuplicateFeedback` / `logFeedback` / `getFeedbackHistory`: feedback table CRUD with source_type tagging
- `adjustTopicWeights`: per-source per-topic weight adjustment on promote/ignore; weight_modifier = 1.0 + (promote - ignore) * 0.1, bounded [0.5, 2.0]
- `getPostTriage` / `meetsRoutingBar`: routing bar check (crumb-architecture + medium/high confidence)
- 5 command handlers: `handlePromote` (routing bar check, within/outside bar paths), `handleIgnore` (noise signal + weight), `handleSave` (KB review queue), `handleAddTopic` (allows multiple topics per item), `handleExpand` (Phase 2 stub)
- `processFeedback`: main pipeline (parse → resolve → dispatch → log)
- 175 tests covering: command parsing (all 5 commands, case insensitivity, D-prefix, argument handling, invalid formats, whitespace), item map (CRUD, case insensitive, multi-source isolation, multi-date, overwrite), cleanup (retention), alias resolution (valid, expired, missing, boundary), canonical ID resolution (direct, alias fallback, missing, precedence), full resolution chain (success, alias, unknown message, no map), dedup (positive/negative per command/date/item), logging (round-trip, source tagging, multiple entries), topic weights (promote, ignore, accumulation, mixed, cap 2.0, floor 0.5, per-source isolation, non-weight commands, empty tags), routing bar (all combinations), all 5 handlers (success, duplicates, outside-bar promote), full pipeline (all commands, parse failure, resolution failure, multi-source RSS, alias pipeline, pipeline dedup), VALID_COMMANDS set, weight listing

**AC verification:** all criteria met:
1. All 5 feedback commands work ✓ (promote, ignore, save, add-topic, expand)
2. Feedback tagged with source_type ✓ (logFeedback includes sourceType)
3. id_aliases consulted on lookup failure with 45-day grace ✓ (resolveCanonicalId → resolveAlias)
4. Weight adjustments per-source per-topic ✓ (adjustTopicWeights with [0.5, 2.0] bounds)
5. Digest item map for reply resolution ✓ (persistDigestItemMap + lookupDigestItem)
6. part_index/part_count for multi-part digests ✓ (FIF-012 digest_messages schema)
7. Unit tests pass ✓ (175/175)

### Test Suite
- schema-test: 46 | types-test: 50 | adapter-state-test: 32 | dedup-test: 35
- manifest-test: 69 | capture-test: 53 | lifecycle-test: 52 | triage-test: 90
- deferred-retry-test: 75 | snapshot-test: 76 | router-test: 102 | digest-test: 173
- delivery-test: 124 | feedback-test: 175
- **Total: 1,152 tests, 0 failures**

### Design Decisions
1. **Delivery staging via adapter_state:** Rendered digests stored in `adapter_state` with `component='delivery'` and `stream_id=digestDate`. Avoids schema changes while leveraging existing key-value infrastructure.
2. **Item map via adapter_state:** Digest item maps stored with `component='digest_items'`. Same rationale — no schema change, natural source+date scoping.
3. **Weight modifier formula:** `1.0 + (promote_count - ignore_count) * 0.1`, bounded [0.5, 2.0]. Simple linear adjustment that can be refined in later phases. Matches x-feed-intel's Phase 1 pattern (counting only) with the addition of actual modifier calculation.
4. **Immutable late footer:** `appendLateFooter` returns new parts array rather than mutating input — consistent with the immutable pattern used elsewhere.

### M1 Progress
- WP-1 (FIF-001–004): DONE (4/4)
- WP-2 (FIF-005–007): DONE (3/3)
- WP-3 (FIF-008–010): DONE (3/3)
- WP-4 (FIF-011–014): DONE (4/4)
- WP-5 (FIF-015–017): 0/3
- WP-6 (FIF-018): 0/1
- **Overall M1: 14/18 tasks complete**

**Next:** FIF-015 (per-source cost telemetry) — WP-5 observability/cost stack.

## Session 2026-02-24 — FIF-015 through FIF-018 (M1 Complete)

### Context
Completing M1 framework core infrastructure. WP-5 (observability/cost): FIF-015
(cost telemetry), FIF-016 (guardrails). WP-5 continued: FIF-017 (queue health).
WP-6: FIF-018 (research promotion). These are the final 4 M1 tasks.

### Context Inventory
- `src/cost/index.ts` — cost module (creating, FIF-015/016)
- `src/health/index.ts` — health module (creating, FIF-017)
- `src/research/index.ts` — research module (creating, FIF-018)
- `src/shared/schema.ts` — DB schema (FIF-001)
- `src/shared/types.ts` — unified content types (FIF-002)
- `src/manifest/index.ts` — manifest loader (FIF-005)
- `src/feedback/index.ts` — feedback protocol (FIF-014)
- `src/router/index.ts` — vault router (FIF-011)

### FIF-015: Per-Source Cost Telemetry — DONE
- `src/cost/index.ts`: 18 exported functions, 7 type exports
- Cost estimation: `estimateCaptureCost` ($0.005/item), `estimateDiscoveryCost` ($0.15/1K), `estimateTriageCost` (Haiku 4.5 pricing: $0.80/M input, $4.00/M output, default 4300/1200 tokens)
- Cost logging: `logCost` / `getCostEntries` with source_type + component + subcomponent
- MTD summaries: `getAdapterCostSummary` / `getAggregateCostSummary` with projection
- Spending cap: `checkSpendingCap` / `wouldExceedCap` / `formatCapBreachAlert`
- Daily cost: `getTodayCost` / `getTodayAdapterCost`
- Signal quality: `getSignalQualityScore` (promotes/total_routed trailing 30 days)
- Weekly summary: `generateWeeklySummary` with per-adapter cost + signal quality
- 118 tests

### FIF-016: Framework-Wide Cost Guardrails — DONE
- Extended `src/cost/index.ts`: 8 additional exported functions, 5 type exports
- Guardrail evaluation with hysteresis: activate at 90% projected, deactivate at 80%
- `computeGuardrailAdjustments`: discovery max_results -50%, heavy/standard max_items_per_cycle -50%, curated-only exempt
- `isDailyCeilingExceeded`: $1/day default aggregate ceiling
- State persistence: `saveGuardrailState` / `loadGuardrailState` via adapter_state (source_type='_framework')
- `runGuardrailCycle`: full evaluation + state transition at cycle boundary
- 55 additional tests (173 total in cost-test.ts)

### FIF-017: Queue Health Monitoring + Adapter Degraded State — DONE
- `src/health/index.ts`: 20 exported functions, 9 type exports
- `logAdapterRun`: writes to adapter_runs table
- Pending check: `getPendingCount` / `checkMaxPending` against manifest max_pending
- Liveness: `getLastSuccessfulRun` / `checkLiveness` using manifest liveness_max_gap_minutes
- Consecutive failures: `getConsecutiveFailures` (most recent first, 24h window, stops at first non-failed)
- Degraded state: `loadDegradedState` / `saveDegradedState` / `enterDegradedState` / `clearDegradedState` / `markAlertSent` via adapter_state (component='health')
- Auto-recovery: consecutive failures = 0 → clear degraded
- One-time alert: `formatDegradedAlert` / `formatLivenessAlert`, alert sent flag prevents duplicates
- Shared alert sender: `createAlertSender` / `sendAlert` — factory pattern for all components
- Health check hook: `runHealthCheck` with injectable `HealthCheckFn`, catches exceptions
- Full orchestrator: `evaluateAdapterHealth` — pending + liveness + failures + health check → state transitions + alerts
- `shouldSkipTriage` / `getDegradedDigestLine` for downstream integration
- 139 tests

**AC verification (FIF-017):**
1. Per-source pending count vs max_pending ✓
2. Liveness check uses manifest liveness_max_gap_minutes ✓
3. >3 consecutive failures in 24h → degraded ✓ (CONSECUTIVE_FAILURE_THRESHOLD = 3, trigger at >3)
4. Degraded: triage skipped, digest status line, one-time alert ✓
5. Auto-recovery on successful run ✓
6. Shared send_alert function ✓ (createAlertSender factory)
7. Health check hook ✓ (injectable HealthCheckFn, mock unhealthy → degraded)
8. Unit tests pass ✓ (139/139)

### FIF-018: Research Promotion Path — DONE
- `src/research/index.ts`: 13 exported functions, 6 type exports
- Frontmatter parsing: `parseFrontmatter` / `isPromotionCandidate`
- Research doc contract: `validateResearchDoc` — validates canonical_id, source_type, promotion_candidate, research_date, filename pattern, cross-validates source_type
- Digest annotation: `getPromotionHint` / `checkPromotionFromDb` / `annotateDigestItem` — save hint when promotion_candidate: true
- Save routing: `getSaveReason` (research-promoted vs user-requested), `buildKbReviewPath`, `generateKbReviewContent`, `routeToKbReview`
- Research process: `setPromotionCandidate` — adds/updates promotion_candidate + research_date in vault file frontmatter
- 91 tests

**AC verification (FIF-018):**
1. promotion_candidate: true in frontmatter ✓ (setPromotionCandidate)
2. Digest annotation includes save hint ✓ (annotateDigestItem with SAVE_HINT_TEXT)
3. Save routes to kb-review with save_reason: research-promoted ✓ (routeToKbReview)
4. Research doc contract ✓ (validateResearchDoc with all required fields)
5. Filename follows feed-intel-{source_type}-{native_id}.md ✓
6. Unit tests pass ✓ (91/91)

### Test Suite
- schema-test: 46 | types-test: 50 | adapter-state-test: 32 | dedup-test: 35
- manifest-test: 69 | capture-test: 53 | lifecycle-test: 52 | triage-test: 90
- deferred-retry-test: 75 | snapshot-test: 76 | router-test: 102 | digest-test: 173
- delivery-test: 124 | feedback-test: 175 | cost-test: 173 | health-test: 139
- research-test: 91
- **Total: 1,555 tests, 0 failures across 17 suites**

### Design Decisions
1. **Guardrail hysteresis:** 90% activate / 80% deactivate prevents flapping. Evaluated at cycle boundary per §4.1 configuration snapshot rule.
2. **Degraded threshold >3 (not ≥3):** At exactly 3 failures, transient errors may resolve. 4+ consecutive failures in 24h is a stronger signal of persistent degradation.
3. **Health check hook pattern:** Injectable `HealthCheckFn` returns `{healthy, message}`. Exceptions caught and converted to unhealthy result — defensive against adapter bugs.
4. **Research doc validation cross-checks:** Filename source_type must match frontmatter source_type — catches misrouted files early.
5. **KB review routing:** Copies vault file with `save_reason` added to frontmatter rather than moving — original routed file stays in place for reference.

### M1 Progress — COMPLETE
- WP-1 (FIF-001–004): DONE (4/4)
- WP-2 (FIF-005–007): DONE (3/3)
- WP-3 (FIF-008–010): DONE (3/3)
- WP-4 (FIF-011–014): DONE (4/4)
- WP-5 (FIF-015–017): DONE (3/3)
- WP-6 (FIF-018): DONE (1/1)
- **Overall M1: 18/18 tasks complete**

**Next:** M2 (X Adapter Migration) — FIF-019 (migration lockfile guard) is the entry point.
