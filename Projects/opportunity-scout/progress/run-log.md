---
project: opportunity-scout
domain: software
type: run-log
skill_origin: null
created: 2026-03-14
updated: 2026-03-14
tags:
  - run-log
---

# Opportunity Scout — Run Log

## 2026-03-14 — Project creation

- Created project scaffold (software domain, full four-phase workflow)
- Input brief: `_inbox/opportunity-scout-draft-spec.md` — a pre-peer-reviewed capability spec drafted outside Crumb with contributions from Gemini, DeepSeek, ChatGPT, and Perplexity
- Crumb peer review of input brief completed — identified 10 issues (5 must-fix, 5 should-fix) that will feed into systems-analyst SPECIFY phase
- Key review findings: multi-model orchestration unspecified, "scan" has no operational definition, FIF integration hand-waved, Telegram feedback pipeline needs design, parent doc missing from vault
- Related project: book-scout (potential overlap to resolve during SPECIFY)
- **Next:** Run systems-analyst against the draft spec input

## 2026-03-14 — SPECIFY complete + peer review r1

**Context inventory:** 7 docs (extended tier) — input brief, Business Advisor + Career Coach overlays, gate-evaluation-pattern, haiku-soul-behavior-injection, FIF project-state, book-scout spec summary, cross-project-deps, personal-context.

**Specification produced:** `design/specification.md` with 12 tasks (OSC-001 through OSC-012), 10 architectural decisions, 4 data contract schemas, 6 unknowns, 7 constraints.

**Peer review (r1):** 4 reviewers (GPT-5.4, Gemini 3.1 Pro, DeepSeek V3.2, Grok 4.1 Fast). All responded, 0 failures. Unanimous agreement on all 5 directed questions (behavioral adoption is primary risk, three-gate triage is sound, direct Bot API is right, SQLite correct, M0 scope right).

**Findings applied (15 total):**
- **Must-fix (5):** Inlined normalized item schema + candidate record schema, added digest-to-candidate identity mapping table, resolved feedback path to direct Bot API for both directions (eliminated A4 open question), fixed M1 gate ("5 qualifying in 21 days" not "5 consecutive")
- **Should-fix (10):** Cost budget breakdown with Haiku/Sonnet fallback impact, weekly health heartbeat (AD-9), source registry schema, pipeline idempotency rules, removed U6/A4 from Open Questions → M0 Validation Tasks, feedback acknowledgement templates, metric denominators, SQLite WAL mode, test set composition in OSC-004 AC, two-stage triage mode (AD-10)
- **Deferred (8):** State machine transition table, dedup mechanism, Bot API security, graveyard matching, raw item purge, ops dashboard, Cohen's kappa, engagement fallback
- **Declined (8):** All UNVERIFIABLE CLAIM findings (vault-internal references verifiable at runtime)

**Key architectural evolution from peer review:**
- AD-6 expanded from delivery-only to unified Telegram path (delivery + feedback)
- AD-9 (heartbeat) and AD-10 (two-stage triage) added as new architectural decisions
- Data Contracts section added with 4 inline schemas (previously referencing absent external docs)
- M1/M2 gates reformulated to avoid threshold-based suppression conflict

**Compound:** Gate evaluation pattern (from `_system/docs/solutions/`) directly applied to milestone gates. Haiku SOUL.md injection ceiling pattern informed AD-1.

**Next:** Spec ready for PLAN phase. Invoke action-architect to decompose into milestones and atomic tasks.

### Phase Transition: SPECIFY → PLAN
- Date: 2026-03-14
- SPECIFY phase outputs: `design/specification.md`, `design/specification-summary.md`, `reviews/2026-03-14-specification.md` + 4 raw reviewer responses
- Goal progress: All SPECIFY acceptance criteria met — problem statement, facts/assumptions/unknowns, system map, domain/workflow, 12 tasks scoped with dependencies, risk levels, peer review (r1, 4 reviewers, 15 fixes applied)
- Compound: No compoundable insights — consumed existing patterns (gate-evaluation, haiku-soul-injection), none created
- Context usage before checkpoint: ~60%
- Action taken: none (context healthy)
- Key artifacts for PLAN phase: `design/specification-summary.md`

## 2026-03-14 — PLAN phase: action-architect

**Context inventory:** 3 docs — specification-summary, specification (targeted: Data Contracts, Constraints, ADs, Task Decomposition), claude-print-automation-patterns.

**Artifacts produced:**
- `design/action-plan.md` — 4 milestones, 11 phases, 18 atomic tasks
- `tasks.md` — full task table with IDs, dependencies, risk levels, binary AC
- `design/action-plan-summary.md`

**Decomposition:** Spec's 12 high-level tasks (OSC-001–012) refined into 18 atomic implementation tasks. Key refinements:
- Spec OSC-003 (adapters) split into OSC-004 (RSS) + OSC-005 (HN) — different risk profiles
- Spec OSC-004 (triage) split into OSC-006 (test set curation) + OSC-007 (prompt + validation) — separates research from implementation
- Added OSC-009 (M0 integration test) — validates end-to-end data flow before M1
- Spec OSC-006 (digest) split into OSC-010 (assembly + Telegram) + OSC-011 (Discord + heartbeat) — critical path vs. additive
- Spec OSC-007 (cron) + OSC-008 (feedback) become OSC-012 + OSC-013 — properly scoped
- Added OSC-014 (3-day soak) — reliability gate before committing Danny's attention

**Risk assessment:**
- 2 HIGH tasks: OSC-012 (pipeline orchestration — multi-component integration), OSC-015 (21-day validation — behavioral adoption)
- 3 MEDIUM tasks: OSC-005 (HN API), OSC-007 (triage validation), OSC-013 (feedback parser), OSC-014 (soak), OSC-009 (integration)
- 11 LOW tasks

**Pattern applied:** claude-print automation Pattern 4 (budget 3-6 iterations for first live deployment) — factored into OSC-012 risk and timeline.

**Impact assessment:** MODERATE scope (new project, multiple components, but no architecture changes to existing systems). Peer review available but not prompted.

**Peer review r1 (action plan):** 4 reviewers, 0 failures. 5 must-fix + 6 should-fix applied:
- Split OSC-012 into OSC-012 (pipeline script) + OSC-013 (LaunchAgent + multi-model) — all 4 reviewers
- Split OSC-013 into OSC-014 (feedback poller) + OSC-015 (commands + throttles) — 3 reviewers
- Fixed OSC-005 dependency: interface contract only, not full RSS (enables parallel adapter dev) — 4 reviewers
- Added OSC-009 → OSC-010 dependency (M0 integration gates M1 delivery) — 3 reviewers
- Resolved 21/30-day mismatch: OSC-017 is 30-day window with 21-day interim checkpoint — 2 reviewers
- Config/secrets scaffolding added to OSC-002 — 2 reviewers
- Feedback poller redesigned as persistent LaunchAgent (not cron) — Gemini flagged cron's 1-min resolution vs ≤30s AC (relaxed to ≤60s)
- Added OSC-011 → OSC-016 dependency (soak validates heartbeat/alerts)
- Tightened 4 vague ACs (source validation, agreement metric, alert false-positives, miscalibration threshold)
- Updated critical path to include feedback tasks
- Added data retention note to OSC-012
- Task count: 18 → 20. Renumbered M1 tasks (OSC-012–016), M2 (OSC-017–018), M3 (OSC-019–020)

**Soak consolidation:** Replaced 3-day M1 soak (OSC-016) with pre-launch validation checklist (hours, not days). M2 30-day behavioral clock starts immediately after checklist passes. Pipeline breaks during M2 fixed in-flight.

### Phase Transition: PLAN → TASK
- Date: 2026-03-14
- PLAN phase outputs: `design/action-plan.md`, `tasks.md` (20 tasks), `design/action-plan-summary.md`, `reviews/2026-03-14-action-plan.md` + 4 raw reviewer responses
- Goal progress: All PLAN acceptance criteria met — 20 tasks scoped ≤5 files, sequenced with dependencies, risk-tagged, binary ACs, peer review r1 applied (5 must-fix + 6 should-fix)
- Compound: No compoundable insights — soak→checklist is a ceremony budget application
- Context usage before checkpoint: ~75%
- Action taken: compact recommended after transition
- Key artifacts for TASK phase: `tasks.md`, `design/action-plan-summary.md`, `design/specification-summary.md`

## 2026-03-14 — TASK phase: M0 complete (OSC-001–009)

**Context inventory:** 5 docs — specification (Data Contracts section), action-plan-summary, calibration-seed, FIF RSS/HN adapter source (pattern reference), tasks.md.

**M0 milestone: Source + Scoring Validation — COMPLETE.**

All 9 M0 tasks implemented and verified:

| Task | Summary | Key Output |
|------|---------|------------|
| OSC-001 | Calibration extraction from v1–v7 dispatches | `design/calibration-seed.md` — 5 graveyard entries, 7 high-scoring patterns, dimension weights, conflict boundaries, three-gate mapping, U5 resolved |
| OSC-002 | Repo init + SQLite schema | `~/openclaw/opportunity-scout/` — 4 tables, WAL mode, `.env.example`, validate-env, 6/6 schema tests |
| OSC-003 | Source registry population | 12 sources (T1:4, T2:4, T3:4), all curl-verified, seed SQL |
| OSC-004 | Adapter interface + RSS adapter | `src/adapters/interface.js` (contract), `src/adapters/rss.js` with incremental polling |
| OSC-005 | HN Algolia adapter | `src/adapters/hn.js` with rate limiting, incremental polling, 5/5 tests |
| OSC-006 | 50-item triage test set | `data/test-set.json` — 20 v1–v7, 20 FIF, 10 synthetic edge cases |
| OSC-007 | Triage prompt + validation | `prompts/triage.md` v1.1. Haiku/Sonnet strict agreement: 54% (below 85%). Fallback: Haiku + Sonnet audit. Conflict gate: 92% agreement. |
| OSC-008 | Candidate registry CRUD + state machine | `src/registry/candidates.js`, `src/registry/graveyard.js` — 54/54 tests, 5 graveyard seeds |
| OSC-009 | M0 integration test | End-to-end: 80 items ingested → 30 scored → 21 candidates inserted → 0 dupes on re-run |

**Key decisions:**
- OSC-007 triage validation failed 85% strict threshold (54%). Adopted Haiku-with-Sonnet-audit fallback per AC. Conflict gate (safety-critical) is solid at 92%. All disagreements adjacent (never H↔L).
- Adapters implemented as plain Node.js (not TypeScript) — bash-orchestrated pipeline pattern per spec's operational architecture.
- OSC-008 added `db/migrations/002-add-content-hash.sql` — content_hash column on candidates table needed for dedup.
- Product Hunt RSS summaries too terse for reliable Haiku scoring — known limitation, not blocking. HN items score reliably.

**Model routing:** All subagents ran on Opus except OSC-002 (Sonnet — mechanical scaffolding, acceptable quality). No rework needed.

**Compound:** No compoundable insights. FIF adapter pattern successfully ported (architectural reuse, not code sharing) — validates the spec's F2 dependency.

**Next:** M1 — First Digest Production. Start with OSC-010 (digest assembly + Telegram delivery).

## 2026-03-16 — M1 complete (OSC-010–016)

**Context inventory:** 5 docs — specification (Data Contracts, ADs 6/8/9/10), action-plan-summary, tasks.md, existing M0 source files (adapters, registry, pipeline).

**M1 milestone: First Digest Production — COMPLETE.**

All 7 M1 tasks implemented and verified:

| Task | Summary | Key Output |
|------|---------|------------|
| OSC-010 | Digest assembly pipeline | `src/digest/assemble.js` — Sonnet ranking, Telegram HTML render, archive, mapping writes. 18/18 tests. |
| OSC-011 | Discord mirror + heartbeat + alerts | `src/delivery/discord.js`, `src/delivery/alerts.js`, `src/pipeline/heartbeat.js`. 17/17 tests. |
| OSC-012 | Bash pipeline orchestration | `scripts/run-pipeline.sh` — run IDs, idempotency, daily lock, data retention. 21/21 tests. |
| OSC-013 | LaunchAgent plists | `staging/com.scout.{daily-pipeline,weekly-heartbeat,feedback-poller}.plist` + install script. 30/30 tests. |
| OSC-014 | Feedback poller | `src/feedback/{poller,router}.js` — getUpdates long polling, offset persistence, command routing. 17/17 tests. |
| OSC-015 | Feedback command execution | `src/feedback/handlers.js` — digest mapping resolution, state transitions, throttles, /scout add. 9/9 tests. |
| OSC-016 | Pre-launch validation | Live pipeline runs, source failure sim, feedback command verified, heartbeat verified, LaunchAgents installed. |

**Live validation results (OSC-016):**
- First digest delivered to Telegram (msg_id: 1265, 7 items, 2026-03-16)
- 249 candidates ingested from 12 sources (bootstrap run)
- Source failure simulated (broken-test) — logged, pipeline continued
- `!bookmark 1` processed: "How coding agents work" → state bookmarked
- Heartbeat reports: 12 sources, 249 items, 7 qualified, 1 delivered
- LaunchAgents installed: daily-pipeline (07:00), weekly-heartbeat (Mon 08:00), feedback-poller (KeepAlive)

**Bugs found and fixed during validation:**
- `claude -p` CWD issue: running from crumb-vault loaded CLAUDE.md project context into triage/digest LLM calls. Fix: set `cwd` option in execSync to repo root.
- Sonnet returning truncated UUIDs: added prefix-match fallback in digest merge step.
- Digest query unbounded: 248 candidates overwhelmed Sonnet ranking. Fix: LIMIT 20 on candidate query.
- Poller getUpdates conflict: previous instances lingering due to 30s long-poll timeout. Fix: clean kill + reinstall.

**Model routing:** Haiku for triage (via `claude -p --model claude-haiku-4-5-20251001`), Sonnet for digest ranking (`claude -p --model claude-sonnet-4-6`), both via direct CLI from repo dir (no CLAUDE.md). No routing rework needed.

**Compound:** `claude -p` CWD sensitivity is a general pattern — any `claude -p` invocation from within a CLAUDE.md project loads full agent context. Should be documented for future automations using `claude -p` from bash scripts.

**Additional work this session:**
- Fixed startup script audit date detection (`session-startup.sh` — grep pattern now matches bare "audit" in comma-separated headings)
- Discord webhook setup: created `#opportunity-scout` forum channel in Tess Ops server, webhook configured in `.env`
- Migrated tess-ops Discord delivery from OpenClaw bots to direct webhooks: updated `morning-briefing-prompt.md` (§13) and `mechanic-HEARTBEAT.md` (check #15 + alert delivery). Created `_openclaw/config/discord-webhooks.json` as central webhook registry. OpenClaw bot config left in place (inert, cleanup deferred).
- Forum channel webhook discovery: Discord forum channels require `thread_name` parameter to create posts. Updated Scout's `discord.js` to support this.

**Synthesis header (post-M1 addition):** Added a Sonnet-generated 2-3 sentence synthesis that opens every digest. Identifies cross-item convergence, connects to Danny's specific assets, and leads with "so what." Implemented as an additional Sonnet call in digest assembly, rendered at the top of Telegram/Discord/archive. Addresses A1 (behavioral adoption) by making the digest immediately scannable — Danny reads 2 sentences and knows if today matters.

**Bot token migration (2026-03-16, post-session):** Scout feedback poller was conflicting with OpenClaw gateway — both calling `getUpdates` on the Tess bot (8526390912). Created dedicated Scout bot (@opp_scout_bot, 8726130855). All Scout delivery and polling now on the Scout bot. Tess bot stays with OpenClaw. Poller verified clean — no 409 conflicts.

**Next:** M2 — 30-day behavioral validation. Clock starts 2026-03-16. 21-day interim checkpoint: 2026-04-06. 30-day gate: 2026-04-15.

## 2026-03-17 — M2 Day 1 hotfix: pipeline environment + delivery

**Trigger:** Telegram alert — "Scout Alert — Pipeline Failure / Stage: digest / Error: Sonnet ranking failed after retries" at 07:00.

**Root cause:** LaunchAgent environment missing two critical items:
1. `claude` CLI at `~/.local/bin/` not in plist PATH (only `/opt/homebrew/bin` etc.)
2. `ANTHROPIC_API_KEY` not in plist env — LaunchAgent can't access macOS Keychain

Both Haiku triage (12/12 batches) and Sonnet ranking (2/2 attempts) failed identically — confirming systemic env issue, not model-specific.

**Secondary issue:** First successful manual run (post-env-fix) ranked and synthesized correctly but Telegram delivery failed: "message is too long" (5288 chars vs 4096 limit). Sonnet's verbose insights pushed the 7-item digest over the limit.

**Fixes applied (commit c22f183):**
1. **Plist PATH** — added `/Users/tess/.local/bin` to `com.scout.daily-pipeline.plist`
2. **ANTHROPIC_API_KEY** — added to plist EnvironmentVariables
3. **Telegram chunking** — new `sendLongMessage()` in `telegram.js` splits at `\n\n` boundaries when >4096 chars
4. **Shell safety** — replaced fragile `$(cat tmpfile)` command substitution with `$SCOUT_SYSTEM_PROMPT` env var in all three LLM call sites (triage, ranking, synthesis). Eliminates quoting bugs from prompt content containing `"`, `` ` ``, or `$`.
5. **Timeout** — Sonnet ranking bumped 120s→240s, synthesis 60s→120s (20-candidate ranking can exceed 2min)
6. **Error truncation** — expanded 100→200 chars for better diagnostics

**Verification:** Full digest delivered to Telegram (message_id: 8), 7 items with synthesis header. LaunchAgent reloaded with new plist.

**Compound:** LaunchAgent + `claude -p` pattern — three things must be true: (1) CLI binary in PATH, (2) API key in env (not Keychain), (3) system prompt passed shell-safe (env var, not command substitution). This joins the existing "prompt-to-environment mismatch" pattern in memory.

## 2026-03-17 — Broadening opportunity scanning (design gap fix)

**Trigger:** Digest review revealed a fundamental design gap — the opportunity scanner was passive-only (12 tech RSS feeds + 2 HN endpoints), while the project intent was broad, creative, cross-domain opportunity discovery. All digest items came from tech feeds; the system couldn't surface opportunities in publishing, education, ecommerce, freelance, or other domains. Danny also identified that the Fit gate was too narrow (penalizing opportunities that don't use existing assets, even if Danny could build the solution).

**Changes (3 commits: cbbf916, f03ea25, 68f83bb):**

1. **Fit gate rubric broadened** — Gate 3 now scores H for "Danny has a competitive advantage" (skills OR assets), not just "uses existing vault/Crumb." Profile text updated across all 4 prompts (triage, batch-validation, digest-rank, digest-synthesis). Calibration example 5 (digital study guides) promoted M→H.

2. **Digest cap raised** — MAX_DIGEST_ITEMS 7→15, candidate query LIMIT 20→30. Signal quality should be the constraint, not an arbitrary item count.

3. **10 new RSS sources** — Side Hustle Nation, Smart Passive Income, Flippa, Empire Flippers, Trends.vc, The Bootstrapped Founder, Tropical MBA, r/sidehustle, r/Entrepreneur, r/passive_income. Total sources: 12→22 across 8 focus domains. Migration 003 expanded focus_domain enum.

4. **Active web search adapter** — New `src/adapters/search.js` using Brave Search API (free tier, 2000 queries/month). 20 search queries derived from calibration seed patterns + broad opportunity patterns, stored in `prompts/search-queries.json`. Daily rotation: 10 queries/run, cycling through full set every 2 days. Rate limited 1 req/sec. Results normalized to standard NormalizedItem format → same Haiku triage pipeline.

5. **Vault digest copy** — `run-pipeline.sh` now copies delivered digests to `_openclaw/data/scout-digests/` for Obsidian visibility.

**Model routing:** No model changes. Search results go through existing Haiku triage → Sonnet ranking pipeline.

**Compound:** The design gap (passive-only scanning for an active-search use case) is a recurring pattern — when the first implementation works end-to-end, it's easy to ship without questioning whether the *input surface* matches the *project intent*. The pipeline architecture (adapters → triage → ranking) was sound and absorbed the new search adapter cleanly.

**Next:** Observe tomorrow's digest (first run with all changes). Evaluate: (a) gate score distribution — are we seeing more varied gates now? (b) search result quality — do Brave results produce better candidates than RSS? (c) digest length — is 15-item cap appropriate or does it need further tuning?

## 2026-03-18 — Triage quality review + scoring pipeline upgrade

**Trigger:** Reviewed 2026-03-18 digest (15 items) with Danny. Triaged all items: 5 bookmarked (#1 PKM, #2 AI agents roundup, #6 AI Agent Store, #7 tkxel service model, #11 productization guide), 10 passed (generic listicles, explainers, trend pieces). State updates applied directly to SQLite from Crumb session.

**Problem identified:** Gate scores were too flat — all 15 items scored confidence M, conflict H, source tier T2, 1 sighting. The three-gate system (conflict/automation/fit) couldn't distinguish "relevant to Danny's situation" (all 15) from "actionable enough to warrant attention" (only 5). Items we passed (#3 IBM explainer, #4 solopreneur advice) got identical H/H/H scores to items we bookmarked. The NerdWallet passive income listicle scored the same as the AI Agent Store marketplace listing.

**Root cause:** Two issues — (1) Haiku lacked judgment for nuanced scoring between similarly-relevant items, (2) no gate measured actionability/specificity.

**Changes (3 modifications to opportunity-scout repo):**

1. **Actionability gate (Gate 4)** — new dimension in `prompts/triage-batch-validation.md` (v1.1→v2.0). H = specific platform/tool/channel named with immediate first step; M = viable direction requiring research; L = generic advice applicable to anyone. Added 2 new calibration examples (#7: NerdWallet listicle → L, #8: AI Agent Store → H). Pass threshold updated: `conflict_gate != L` AND 2 of 3 remaining gates (automation, fit, actionability) pass — so generic listicles need both automation H and fit H to survive.

2. **Model upgrade: Haiku → Sonnet** — triage scoring model changed from `claude-haiku-4-5-20251001` to `claude-sonnet-4-6` in `src/pipeline/ingest-and-score.js`. Same model now used for both triage and ranking. Cost increase negligible on 15-30 items/day.

3. **Enrichment fields populated** — triage prompt now requests `demand_note` (market demand evidence) and `economics_note` (unit economics signal) alongside gate scores. Wired through `scoreBatch()` → `registryPhase()` → `candidates.insert()`. Passed to Sonnet ranking prompt for evidence-weighted ranking. Previously these were dead columns in the schema.

**Supporting changes:**
- Migration `004-add-actionability-gate.sql` — added `actionability_gate` column to candidates table
- Gate display strings updated to 4-gate format (`H/H/H/H`) across digest render, archive, synthesis, Discord delivery
- Digest ranking prompt updated (v1.0→v1.1) to weight actionability_gate and enrichment notes

**Tests:** 54/54 candidate registry tests pass, schema tests pass. Syntax check clean on all 4 modified JS files.

**Model routing:** No delegation — all work done in main Opus session. Opportunity-scout code changes are in external repo (`~/openclaw/opportunity-scout/`), not vault.

**Compound:** The actionability dimension was the missing discriminator. This is a general pattern for any AI-scored pipeline: relevance-based gates produce flat distributions when all items share the same topic domain. Adding an actionability/specificity gate creates the gradient that relevance alone can't. Applicable to feed-intel-framework if it ever gets a scoring pipeline.

**Next:** Observe tomorrow's digest (first run with v2.0 triage). Key questions: (a) does the 4-gate scoring produce meaningful variance? (b) do enrichment notes give Sonnet better ranking signal? (c) does the pass threshold filter out generic content effectively?
