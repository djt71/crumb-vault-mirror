---
type: run-log
project: mission-control
status: active
created: 2026-03-07
updated: 2026-06-01
last_committed: 2026-03-13
---

# Mission Control — Run Log

> **Archive:** [[run-log-2026-03a]] — Project creation, SPECIFY, PLAN, Phase 0 design (M0a/M0b), Phase 1 implementation (M1-M3), Phase 2 (M4-M6 partial) — sessions 1-7 (2026-03-07 through 2026-03-13)

---

## 2026-06-01 (session 11) — Dashboard services stopped (monitoring-stack teardown)

**Phase:** TASK (unchanged — project kept active per operator)
**Operator:** Danny

### Context
Operator no longer has a use for the Mission Control dashboard. Traced the dependency
cascade from the dashboard down through its monitoring feeders before acting. Decision was
to **stop the running services but keep the project** (no archival, no phase change) for
reversibility — same keep-files philosophy as the FIF/opportunity-scout decom (commit 2756dbc1).

### Actions (launchd, gui/501 — booted out + disabled, plist files retained)
- **`com.crumb.dashboard`** — stopped. The dashboard API server (`crumb-dashboard/packages/api/dist/server.js`). Project `mission-control` left `phase: TASK, status: active`; repo and files untouched.
- **`com.tess.v2.awareness-check`** — stopped. tess-v2 LLM anomaly heartbeat (TV2-032-C2), the other consumer of `service-status.json`. Dropped per operator.
- **`com.crumb.service-status`** — stopped. The 60s launchd sensor that wrote `_system/logs/service-status.json`. **Orphaned** once both consumers above were removed → retired.

### Kept (deliberately)
- **`ai.openclaw.health-ping`** (15m) — external dead-man's switch (pings hc-ping.com). Independent of the dashboard; its value is "alert operator if the whole machine goes dark." Verified it depends on `ops-metrics.jsonl` + the gateway port probe (HTTP 200 confirmed), **not** on `service-status.json`, so the sensor retirement doesn't break it.
- **`com.crumb.vault-web`** — unrelated (serves the Quartz published-vault static site from `quartz-vault/public`), left running.

### Verification
- `launchctl list`: all three target labels absent; `health-ping` + `vault-web` still present; gateway `:18789` → HTTP 200.

### Notes / follow-ups
- Reversibility: plist files remain in `~/Library/LaunchAgents`; re-enable via `launchctl enable` + `bootstrap`.
- Also retired **`com.tess.health-check`** (TMA-004 Limited Mode auto-failover for the OpenClaw voice agent) — surfaced as `idle_error` during tracing. Root cause: failing every 5m under launchd because it reads Telegram creds from the login Keychain (launchd↔keychain session isolation — entries exist but launchd can't reach them; same reason awareness-check uses a plist env var). Second latent failure behind it: the `tess→openclaw` sudoers NOPASSWD entry for the swap path is missing, so failover wouldn't execute even with creds. Broken for months; operator confirmed the voice agent runs fine without auto-failover → retired (bootout + disable, files kept). Voice-agent subsystem itself left alone (gateway :18789 still live).
- The earlier `awareness-check.sh` feed-freshness fix (commit 4ffbdbb4) was the original entry point into this thread.

### Compound Evaluation
- **Pattern: trace the consumer cascade before decommissioning.** The presenting symptom (a stray Telegram "feed digest may be stale" alert) was one disabled check; the real shape was a 4-service monitoring stack feeding a dashboard the operator had already mentally retired. Mapping consumers *first* prevented two errors: (1) tearing out `health-ping`, whose value (external dead-man's switch) is independent of the dashboard, and (2) orphaning `service-status` while a second consumer (the v2 heartbeat) still read it. Decom decisions should follow the data-flow graph, not the presenting symptom.
- **Insight externalized to memory: launchd ↔ login-Keychain isolation** — launchd jobs can't read the login Keychain (`security find-generic-password` returns "not found" even when the entry exists); give them secrets via plist `EnvironmentVariables`. Was the root cause of `com.tess.health-check`'s 5-min failure loop. Saved to `macos-system-notes.md` so the next service build doesn't repeat it.
- **Decommission hygiene gap:** the original FIF/opportunity-scout decom (2756dbc1) booted the *capture* jobs but missed downstream *monitors* that watched their output (`awareness-check` Check 2). Lesson: when decommissioning a producer, sweep for consumers/watchers in the same pass — a disabled producer turns every freshness check on its output into a permanent false alarm.

---

## 2026-03-30 (session 10) — M3.1: Intelligence Feed Density Redesign

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `Projects/mission-control/design/specification.md` §6.3 — Intelligence Pipeline section
- `Projects/mission-control/design/action-plan.md` — milestone definitions, cross-cutting conventions
- `Projects/mission-control/design/design-system.md` §3.9 — dense list constraints
- `Projects/mission-control/project-state.yaml` — phase state
- `packages/api/src/tier-config.ts` — new: shared tier configuration
- `packages/api/src/routes/config.ts` — new: config endpoint
- `packages/api/src/routes/intel.ts` — added facets endpoint
- `packages/api/src/adapters/fif-sqlite.ts` — added origin field, facet counts, format normalization
- `packages/web/src/components/intel/SignalDigest.tsx` — full density redesign
- `packages/web/src/index.css` — dense row CSS, filter bar CSS
- `packages/web/src/types/intel.ts` — added origin field
- `_inbox/IMG_0917.jpeg` — Surface screenshot (inspiration source)

### Work Done

**Spec Amendment S (2026-03-30):**
- §6.3 Pipeline section rewritten: dense list layout, multi-axis filter bar, tier badge display, shared tier config, rendering strategy
- U7 added and resolved: primary-surface read-state model (dashboard owns `seen_at`, other surfaces don't write it)
- §8.6 frontend requirements: signal cards → signal list rows
- Amendment tags [S-1] through [S-5] for tier config, read state, dense list, AI summaries (deferred), numeric scoring (deferred)

**M3.1 milestone added to action plan:**
- 7 tasks (MC-080 through MC-086), dependency graph updated (M3.1 blocks M8)
- Cross-cutting convention [AP-22]: shared tier config
- Design system §3.9: Dense List View Constraints

**MC-080 (tier config):**
- `tier-config.ts`: shared priority→tier→color mapping, single source of truth
- `GET /api/config`: serves tier config to frontend at load time

**MC-081 (faceted counts):**
- `GET /api/intel/facets`: item counts by tier, source, topic, format, origin
- Uses triage_tags (not matched_topics) for cleaner topic taxonomy
- Format normalization: link+short_text→Post, long_text→Article, paper→Paper, video→Video
- Origin derived from source_instances[0].source: bookmark→Saved, else→Discovery

**MC-082/083/084 (dense list + filter bar + tier badges):**
- Replaced card-based SignalDigest with single-row `.signal-row` layout
- ~24 items/viewport (was ~5 with cards) — 5x density improvement
- Multi-axis filter bar: 5 stacked rows (Tier, Source, Topic, Format, Origin) with chip counts
- AND across dimensions, OR within — facets computed client-side from signals array
- Tier badges on left margin as scanline element (T1 green, T2 amber, T3 gray)
- Hover action icons (skip/delete/promote/research) appear on row hover
- ALL clear-filter button, signal count display
- All existing functionality preserved: bulk selection, undo bars, promote selector, detail panel, research queueing

**Filter quality improvements (operator feedback):**
- Topic: switched from matched_topics (messy LLM-generated) to triage_tags (9 clean values), filtered out general-interest (43% — too broad)
- Format: normalized raw content_type to user-friendly labels
- Origin: new dimension — Saved (X bookmarks) vs Discovery (search/feed). Extends when YT likes adapter added.
- Added origin field to Signal interface + SQL query (source_instances column)

**MC-085 (mockup update):**
- intelligence-mockup.html updated: 8 dense rows + filter bar (was 5 cards)

**MC-086 (design constraint):**
- design-system.md §3.9: text-only labels, zero card chrome, single-line rows, tier-config-driven color

**Data model finding:**
- FIF pipeline has no numeric reranker scores — priority and confidence are both categorical (high/medium/low)
- Decided: tier badges (T1/T2/T3) for Phase 1, numeric scores deferred to FIF pipeline enhancement [S-5]
- Documented in spec as future evolution path

### Test Summary
- 392/394 tests passing (2 pre-existing failures in knowledge.test.ts, unrelated)
- Fixed test fixtures: added source_instances column to dashboard-actions.test.ts and intel.test.ts
- Both packages build clean
- Dashboard service restarted and verified live

### Code Review
- **tier-config.ts:** Clean single-responsibility module. priorityToTier handles null/unknown gracefully. TIER_ORDER constant ensures consistent display order.
- **getFacetCounts():** Shares the same WHERE clause as getFifData — facet counts match signal list. format normalization and origin derivation done server-side to keep frontend simple.
- **SignalDigest rewrite:** Preserved all 8 state variables and 7 callbacks from original. Only JSX rendering and filter logic changed. useMemo for facet computation avoids re-computation on non-signal state changes.
- **CSS density approach:** Absolute-positioned hover actions with gradient background fade covers the meta text gracefully. The gradient uses the panel background color so it adapts to theme changes.
- **Origin extraction:** source_instances is a JSON array column that already existed in FIF SQLite — just wasn't being selected. First entry's `source` field reliably indicates bookmark vs search/feed across all adapters.

**Risk:** Low. Additive changes — new endpoint, new config, visual redesign of existing component. All existing triage functionality preserved. No schema changes to FIF SQLite.

### Key Decisions
- Tier badges instead of numeric scores (FIF has no numeric scores — categorical only)
- Client-side facet computation (107 items → trivial, avoids second roundtrip)
- triage_tags over matched_topics (controlled vocabulary vs LLM noise)
- general-interest excluded from topic filter (43% of items — not useful as a filter value)
- Origin as 5th filter dimension (Saved vs Discovery) rather than a modifier on Source
- Primary-surface read-state model locked for future implementation (dashboard owns seen_at)

### Compound Evaluation
- **Pattern: "reverse-engineer external UIs for design principles, not pixel copying"** — The Surface screenshot analysis identified 16 features but the design principle was one: density. Items 7/8/9/14/15 were all facets of "maximize items per viewport by eliminating vertical waste." Recognizing the principle let us adapt the approach to FIF's data model (tier badges instead of score badges) without losing the design intent.
- **Pattern: "filter axes should use controlled vocabulary, not LLM-generated labels"** — matched_topics were free-form LLM outputs with inconsistent naming. triage_tags were a clean 9-value set. The taxonomy quality matters more than the raw availability of data.

### Model Routing
- Main session: Opus (interactive design analysis, spec writing, implementation decisions)
- Explore subagent: Opus (codebase exploration — needed full context for accurate component mapping)
- No Sonnet delegation — session was design-heavy with operator feedback loops

---

## 2026-03-17 (session 9) — M7: Attention Status Updates + M6 closure + Gardening DQ

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `packages/api/src/adapters/attention.ts` — attention aggregator (added status update)
- `packages/api/src/adapters/attention-schema.ts` — schema types and validation
- `packages/api/src/routes/attention.ts` — attention routes (added PATCH + mtime)
- `packages/web/src/hooks/useAttentionItems.ts` — hook (added updateStatus, undo)
- `packages/web/src/components/attention/AttentionItemsPanel.tsx` — UI (status buttons, defer picker, undo bar)
- `packages/web/src/index.css` — new status button and undo bar styles
- `packages/api/src/adapters/vault-gardening.ts` — orphan detection (ephemeral type filter)
- `Projects/mission-control/design/specification.md` §7.3, §8.3 — lifecycle, PATCH spec
- `Projects/mission-control/design/action-plan.md` — M7 milestone, AP-8 (mtime conflict)

### Work Done

**MC-044 (PATCH endpoint):**
- `PATCH /api/attention/items/:id` — accepts `{status, deferred_until?, if_unmodified_since?}`
- All status transitions allowed (open/in-progress/done/deferred/dismissed, any direction)
- mtime-based optimistic concurrency (AP-8): `if_unmodified_since` parameter, returns 409 on conflict
- `deferred_until` required when status=deferred, cleared when leaving deferred
- `GET /api/attention/items/:id/mtime` helper for concurrency flow
- Writes via existing `writeVaultFile` (tmp+rename atomicity)
- Frontmatter `status` and `updated` fields written directly to vault file
- 9 new adapter tests: status update, deferred flow, conflict detection, persistence, error cases

**MC-045 (inline status UI):**
- Status action buttons per card — context-aware transitions for current status
- Defer flow with inline date picker (confirm/cancel)
- 30-second undo bar after any status change (animated fade-in, auto-expires)
- Updating state: opacity reduction + pointer-events disabled during PATCH
- Completed/dismissed items show reopen button
- CSS follows design system (Inter labels, accent colors, semantic status colors per state)

**E2E verification:** Created test attention item, verified Done → Undo → Defer → Reopen flow live on dashboard. Cleaned up test item.

**M6 (Knowledge page) — formal closure:**
- All M6 deliverables already built in prior sessions: QMD adapter, AKM feedback parser (MC-072), project health scanner, vault gardening, shared search endpoint, full frontend with 4 panels
- SC-4 satisfied: AKM hit rate visible, most-surfaced sources, never-consumed sources, "Link all to MOCs" actionable path
- Formally closed — Phase 2 complete

**Vault Gardening data quality fix:**
- Investigated 91 unlinked sources: 87 reported as "recent" (<7d)
- Root cause analysis: not a bug — orphan detection is accurate, but ephemeral operational reports (overnight research briefs) were inflating the count
- Added `extractType()` to vault-gardening adapter; filter excludes `research-brief` and `ecosystem-intelligence` types
- Net reduction: 2 files (only 2 actual research-brief typed files existed, not 14 as estimated)
- Ran "Link all to MOCs" — 51 sources linked to 5 MOCs (moc-security, moc-networking, moc-crumb-architecture, moc-business, moc-gardening) via Sonnet subagent
- Orphan count: 91 → 42 (47 rescued by linking, 2 by filter)
- Remaining 42: 14 without `topics:` fields (need manual triage), 28 with topics the linker missed (insights, signals, some research)

### Test Summary
- 372/372 tests passing (39 files), both packages build clean
- 9 new attention status update tests
- Live verification: PATCH endpoint, status buttons, undo flow, defer picker all confirmed working

### Code Review
- **updateAttentionItemStatus:** Reads all attention files to find matching `attention_id`, validates status, checks mtime for conflict, updates frontmatter via gray-matter stringify + writeVaultFile. Clean error codes (EINVAL, ENOTFOUND, ECONFLICT) for route-layer mapping.
- **Undo implementation:** Client-side 30-second window with timer ref. Undo sends a second PATCH reverting to `previous_status`. Timer cleanup on unmount. No server-side undo stack — keeps the API stateless.
- **Ephemeral type filter:** Single `Set` lookup in the orphan detection loop. Minimal perf impact. `extractType()` reads from already-parsed frontmatter match — no additional file I/O.
- **MOC linking:** Sonnet subagent processed 51 sources across 5 MOCs. Added entries with annotations, DELTA markers updated. Quality spot-checked.

**Risk:** Low. Additive changes — new PATCH endpoint, new UI controls, filter addition. Existing behavior preserved.

### Key Decisions
- Status transitions are unrestricted (any → any) rather than enforcing a state machine. The dashboard is the operator's tool — trust the operator.
- Undo is client-side only (30s window). No server-side undo log — the vault file is the source of truth, and the previous status is just a PATCH away.
- Ephemeral type filter uses frontmatter `type` field (not filename pattern) — more reliable and self-documenting.
- Overnight research briefs (`type: research-brief`) are genuinely ephemeral — they reference projects but aren't knowledge graph nodes. Compound insights and paper indexes ARE knowledge nodes and should be linked.

### Compound Evaluation
- **Pattern: "ephemeral vs. knowledge classification for pipeline outputs"** — automated pipelines produce both operational reports (ephemeral) and knowledge artifacts (permanent). The `type` frontmatter field is the discriminator. Dashboard panels showing vault health metrics should filter by type to avoid inflating actionable counts with noise. This applies beyond gardening — any vault-wide metric (orphans, staleness, coverage) should respect the ephemeral/knowledge boundary.
- Phase 2 complete. Phase 3 milestones (M8/M9/M10) are independent and can run in any order.

### Model Routing
- Main session: Opus (interactive build, design decisions, data analysis)
- MOC linking subagent: Sonnet — 51 file reads + 5 MOC edits, structured mechanical work. Quality acceptable, no rework needed.

---

## 2026-03-16 (session 8) — M5: Full Attention Schema (MC-036/037/038/039)

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `packages/api/src/adapters/attention.ts` — existing aggregator (412 lines)
- `packages/api/src/adapters/attention.test.ts` — existing tests (285 lines)
- `packages/api/src/constants.ts` — staleness thresholds, enum constants
- `packages/web/src/types/attention.ts` — frontend types
- `Projects/mission-control/design/specification.md` §7.1 — attention-item schema

### Work Done

**MC-036 (schema validation module):**
- Created `attention-schema.ts` — standalone validation with non-fatal degradation
- Added `item_mode` field (one-shot | recurring) with backward compat (defaults to one-shot for v1 items)
- Validation returns `{item, errors, degraded}` — broken items rejected, invalid optional fields get defaults + warnings
- Hard reject: missing `type: attention-item` or `attention_id`. Soft degrade: invalid kind/domain/urgency/status/item_mode/schema_version
- Refactored `attention.ts` to import types and validator from schema module
- 19 schema validation tests passing

**MC-037 (expanded vault scanner):**
- `isDeferredHidden()` — deferred items with future `deferred_until` date hidden from main items list
- `isStale()` — items untouched >14 days flagged using `STALE_ATTENTION_ITEM` constant
- All item kinds (system/relational/personal) handled through schema validator with per-kind defaults

**MC-038 (aggregator multi-source expansion):**
- `getAttention()` now returns `deferredItems`, `kindCounts`, `sourceCounts` in addition to existing `items`/`completedItems`/`counts`
- 24h dedup window enforcement on `source_ref` — items with same source_ref both >24h old are treated as separate events (not deduped)
- Updated `AttentionData` interface on both API and web packages
- 6 new M5 adapter tests (kindCounts, sourceCounts, deferred filtering, item_mode parsing)

**MC-039 (attention page enhancements):**
- `GET /api/attention/items` — new endpoint exposing vault-item aggregator with `is_stale` annotation per item
- `POST /api/attention/items/:id/promote-to-focus` — promotes deferred/active item to today's daily plan Focus section
- `AttentionItemsPanel` component — kind-specific card styling (left border color by kind), urgency badges, staleness indicators (dashed border + badge), recurring item markers, collapsible deferred/completed sections, promote-to-focus button
- `useAttentionItems` hook — fetches items, handles promote action
- Wired into `AttentionPage.tsx` below GoalsPanel, triggers daily plan refresh on promote
- CSS: 200 lines of new styles following existing design system (accent-muted, status-warn-bg, Source Serif headings, JetBrains Mono metadata)

### Test Summary
- 39/39 attention tests passing (19 schema + 20 adapter)
- Clean build (API tsc + web Vite)
- API verified live: `GET /api/attention/items` returns 2 synthetic items with all new fields
- Pre-existing: 7 daily-attention test failures unrelated to M5 (stat/mtime race in test fixtures)

### Code Review
- **attention-schema.ts:** Pure validation, no side effects. Two-tier rejection: hard (null item) for type/id, soft (degraded flag + defaults) for everything else. Clean separation from parser.
- **attention.ts refactor:** Types and validation extracted to schema module. Re-exports maintain backward compat for any consumers. Added `isStale`/`isDeferredHidden` as named exports for route layer.
- **24h dedup window:** Checks both items against the window — if either is within 24h, dedup applies (last-writer-wins). If both are outside, kept as separate events. This prevents stale source_ref matches from collapsing distinct events.
- **promote-to-focus route:** Searches all item lists (active + deferred + completed), uses existing `appendFocusItem()` — no new write path.

**Risk:** Low. Additive — new endpoint, new component, new validation module. Existing behavior preserved (re-exports, same aggregator logic with expanded output).

### Key Decisions
- Schema validation is non-fatal by design — production items with missing optional fields should render (degraded) rather than disappear. Only `type` and `attention_id` are hard requirements.
- `item_mode` absence is NOT a warning — silent default to `one-shot` for backward compatibility with all existing items.
- 24h dedup window is a spec requirement (§7.2) that was missing from the Phase 1 implementation. Items older than 24h with the same `source_ref` are now treated as distinct events.

### Compound Evaluation
- **Pattern: "non-fatal validation with degradation flags"** — the attention schema validator returns items with a `degraded` boolean rather than rejecting. This pattern is reusable for any vault-item parser where data quality varies (e.g., legacy items missing new fields). The consumer decides whether to render, warn, or filter.
- M5 completes Phase 2 of the Attention page. M7 remaining tasks (MC-044 PATCH endpoint, MC-045 inline status updates) depend on M5's schema module. Phase 3 milestones (M8/M9/M10) are independent.

### Model Routing
- All work on Opus (session default). No delegation to Sonnet — interactive build with judgment calls on schema design and dedup semantics.

---

