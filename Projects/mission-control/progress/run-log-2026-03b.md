---
type: run-log
project: mission-control
status: archived
created: 2026-03-07
updated: 2026-03-13
covers: "2026-03-09 down to 2026-03-07 — MC-028 adapter tests + parity gate start, through Project creation/SPECIFY/PLAN phase, through MC-055 (State patterns + mobile viewport). Sessions run newest-first except the 2026-03-07 tail (Project creation through MC-055), which is chronological."
---

# Mission Control — Run Log Archive (03b)

> **Archive 2 of 3.** Covers 2026-03-09 (MC-028 adapter tests + parity gate start) back through 2026-03-07: project creation, SPECIFY, PLAN phase decomposition, TASK phase M0a/M0b design system, MC-006 through MC-055 (mockups, Attention/Ops/Intelligence pages, state patterns). Precedes [[run-log-2026-03a]] (2026-03-09–03-13, MC-065 onward). Continues in [[run-log-2026-03c]] (2026-03-07 MC-010 Design gate review onward). Active log: [[run-log]].

## 2026-03-09 — MC-065 feed-pipeline dashboard entry path

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `Projects/mission-control/tasks.md` — MC-065 acceptance criteria
- `Projects/mission-control/design/specification.md` — §8.6 feed triage actions
- `.claude/skills/feed-pipeline/SKILL.md` — existing skill procedure
- FIF SQLite adapter (`~/openclaw/crumb-dashboard/packages/api/src/adapters/fif-sqlite.ts`) — DB path, posts schema, dashboard_actions JOIN pattern

### Work Done

Updated feed-pipeline SKILL.md with new Step 0: "Dashboard-Queued Promotions."

**Changes:**
1. **Frontmatter:** Updated description to mention dashboard entry path. Added `feed.promotion.dashboard` capability with cost profile. Added `Bash` to required_tools (for sqlite3 CLI).
2. **Identity:** Documented two entry paths (inbox + dashboard).
3. **Routing diagram:** Added dashboard promote queue flow above the existing three-tier routing.
4. **Step 0 (new):** Queries `dashboard_actions WHERE action='promote' AND consumed_at IS NULL` joined with `posts`. Extracts item data from JSON fields. Resolves kb/ tag from metadata override or auto-mapped triage tags. Runs Q4 (project applicability). Promotes via Step 5 sub-steps with `dashboard_promote: true` provenance. Cleans up inbox file if present. Sets `consumed_at` on success.
5. **Step 1:** Dashboard-queued count now reported in summary line.
6. **Step 7:** Calibration log format extended with `dashboard_promoted` field.
7. **Context Contract:** Added FIF SQLite DB as MUST-have dependency.
8. **Convergence:** Added dimension 6 — dashboard queue processing completeness.

**Design decisions:**
- Step 0 is self-contained — references Step 5 sub-steps but doesn't modify the inbox workflow. Both paths coexist cleanly.
- DB path uses `$HOME` expansion (not hardcoded `/Users/danny`) for portability.
- Failed `consumed_at` writes are tolerable — dedup in Step 5.1 collision check makes re-processing idempotent.

### Acceptance Criteria Check
- [x] Step 0 queries `dashboard_actions WHERE action='promote' AND consumed_at IS NULL` joined with `posts`
- [x] Flagged items skip Q1-Q3, run full promotion workflow
- [x] kb_tag from metadata override or auto-mapped from triage tags
- [x] Signal-note write, MOC registration, knowledge retrieval, project cross-posting
- [x] Sets `consumed_at` on success
- [x] Dashboard-queued count reported separately in Step 1 summary
- [x] Existing inbox workflow unchanged

MC-065 → **done**. M3b (Intel Pipeline Triage Actions) milestone complete. MC-028 parity gate unblocked.

## 2026-03-09 — Peer review fixes (MC-064 S1, S6)

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Work Done

Operator peer review of MC-064 surfaced 6 findings. Fixed 2, accepted 3, rejected 1:

1. **S1 (bug fix):** `new URL(u)` in SignalDetail throws on malformed URLs from external FIF sources. Added `displayHost()` helper with try/catch fallback. (`3018d37`)
2. **S6 (fix):** Level 3 default kb/ tag from `findDefaultKbTag()` wasn't in the `<select>` dropdown options — browsers render inconsistently when value isn't in option list. Now injected as extra option when default is Level 3. (`3018d37`)
3. **S3 accepted:** CANONICAL_KB_TAGS 5-way sync surface — sync-point comments in place, GET endpoint is a future option.
4. **S4 rejected (false finding):** `transition: opacity 0.4s ease` already exists on `.signal-card-wrapper`.
5. **S5 accepted:** First-match in `findDefaultKbTag` is reasonable; operator can override in selector.
6. **S2 self-resolved by reviewer:** skip/delete race is handled by server-side filtering.

### Code Review Entry
- **Scope:** MC-064
- **Reviewer:** Operator (Danny)
- **Findings:** 6 (1 significant, 1 medium, 4 minor)
- **Fixes committed:** `3018d37` (crumb-dashboard)

## 2026-03-09 — MC-064 triage UI + pre-existing TS/test fixes

**Phase:** TASK (IMPLEMENT)
**Operator:** Danny

### Context Inventory
- `Projects/mission-control/tasks.md` — MC-064 acceptance criteria
- `Projects/mission-control/design/specification.md` — §8.6 feed triage actions
- `packages/web/src/components/intel/SignalDigest.tsx` — existing signal card component
- `packages/web/src/pages/IntelPage.tsx` — intel page layout
- `packages/web/src/types/intel.ts` — frontend type definitions
- `packages/api/src/routes/intel.ts` — triage API endpoints (MC-062/063)
- `packages/web/src/index.css` — dark observatory theme styles

### Work Done

1. **MC-064: Intel page triage UI** (`1068e53`)
   - Signal cards show 3 action buttons: skip (X), delete (trash), promote (up-arrow)
   - Skip/delete: card fades to 30% opacity, 5s undo bar with API-backed undo
   - Promote: inline kb/ tag selector pre-populated from signal's triage_tags mapped through canonical lookup, confirm button queues promotion
   - Queued signals show "QUEUED" badge + accent left border with cancel button
   - Promote queue count indicator in Pipeline section header
   - Per-card error display, busy state, mobile tappable sizing
   - Forward reference: consumed promotion "promoted" status requires MC-065 (adapter filters consumed_at IS NULL)

2. **Pre-existing TS errors fixed** (`81eb694`)
   - `intel.ts`: Express 5 types `req.params` as `string | string[]` — coerced with `String()`
   - `dashboard-actions.test.ts`: union type `DashboardAction | 'conflict'` needed narrowing before property access

3. **SafeMarkdown test fix** (`bcaf861`)
   - Missing `// @vitest-environment jsdom` directive caused all 6 tests to fail with "document is not defined"
   - Test suite now 210/210 (was 204/210)

### Decisions
- Consumed promotion display deferred to MC-065 — adapter's `consumed_at IS NULL` filter means frontend can't distinguish queued vs. consumed promotions without adapter changes
- Undo is 5s window for skip/delete only; promote has persistent cancel button (until feed-pipeline consumes)

### Code Review Entry
- **Scope:** MC-064
- **Reviewer:** Self (implementation session, no external review)
- **Status:** Builds clean (API + web), 210/210 tests pass
- **Note:** Operator code review recommended at M3b completion (MC-065 remaining)

### Compound Evaluation
- **Pattern confirmed: CANONICAL_KB_TAGS sync surface** — now 5 sync points (added frontend `SignalDigest.tsx`). The S4 finding from operator review is compounding — every new consumer adds drift risk. Read-from-vault-at-startup remains the long-term fix.

### Model Routing
- All work in main session (Opus) — frontend implementation with design decisions, not delegable to Sonnet

## 2026-03-09 — Peer review fixes (S1-S6)

**Phase:** TASK
**Operator:** Danny

### Work Done

Operator code review surfaced 7 findings against MC-061/062/063 implementation. Fixed 5, accepted 2:

1. **S1 (bug fix):** `deleteInboxFile` used `includes()` for canonical_id matching — substring collision risk (e.g., `x:10` matching `x:100`). Fixed with regex line-anchored match.
2. **S2 (robustness):** Writable DB connections had no `busy_timeout` — SQLITE_BUSY from concurrent FIF writes would produce unhandled 500s. Added `busy_timeout = 5000` on all connections.
3. **S3 (correctness):** `getPendingActions` and `getPendingPromoteCount` opened writable connections unnecessarily. Switched to new `openDbReadonly()` function.
4. **S4 (maintainability):** Hardcoded `CANONICAL_KB_TAGS` list now has comment pointing to 4 sync sources.
5. **S6 (test gap):** Added test verifying `removeAction` returns false when `consumed_at` is set (feed-pipeline skill already processed the item).
6. **S5 accepted:** Permissive Level 3 subtag validation — no registry to validate against, acceptable for single-user.
7. **S7 accepted:** YAML escaping in canonical_id — S1 regex fix covers this implicitly.

### Code Review Entry
- **Scope:** MC-061, MC-062, MC-063
- **Reviewer:** Operator (Danny)
- **Findings:** 7 (3 significant, 4 minor)
- **Fixes committed:** `5aa67f6` (crumb-dashboard)
- **Residual:** S4 drift risk noted — read-from-vault at startup is the long-term fix

## 2026-03-09 — Feed triage actions design + spec amendment

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `Projects/mission-control/design/specification.md` — §6.3, §8.3, new §8.6
- `Projects/mission-control/design/specification-summary.md` — build order, C4, key decisions
- `Projects/mission-control/tasks.md` — M3b tasks, MC-028 reframe
- `.claude/skills/feed-pipeline/SKILL.md` — existing promotion workflow analysis
- FIF SQLite adapter analysis (crumb-dashboard `packages/api/src/adapters/`)

### Work Done

1. **Feed triage gap identified** — MC-028 parity gate cannot pass without action capability. Operator needs promote/skip/delete on feed signals from the dashboard, not just viewing.

2. **Design analysis: where does triage belong?**
   - Phase 4 (A2A facade writes) is wrong scope — feed triage is direct data operations, not approval/feedback/delivery infrastructure
   - Full promotion in Express is wrong approach — feed-pipeline skill does LLM-grade reasoning (permanence evaluation, context generation, project cross-posting) that can't be reduced to a REST endpoint
   - Decision: **skip/delete are immediate dashboard actions; promote is queued for feed-pipeline skill**

3. **Schema ownership decision (Option B):**
   - New `dashboard_actions` table in FIF SQLite, owned by dashboard
   - FIF core tables (`posts`, `adapter_runs`, `cost_log`) remain read-only from dashboard
   - Feed-pipeline skill JOINs `dashboard_actions` to pick up queued promotions
   - Rejected: Option A (new `queue_status` value in `posts` — muddies FIF schema ownership), Option C (JSON sidecar — reinvents CTB at lower fidelity)

4. **Spec amended:**
   - §6.3: triage actions added to Pipeline section layout
   - §8.3: write endpoints description updated (Phase 1 now includes feed triage)
   - New §8.6: full feed triage actions design (schema, action semantics, data flow, design rationale, endpoints)
   - §8.6→§8.7: A2A delivery adapter renumbered

5. **Tasks created (M3b: Intel Pipeline Triage Actions):**
   - MC-061: `dashboard_actions` table + adapter update
   - MC-062: Skip + delete endpoints
   - MC-063: Promote-queue endpoint
   - MC-064: Intel page triage UI
   - MC-065: Feed-pipeline skill dashboard-flagged entry path

6. **MC-028 reframed:** parity gate now requires triage actions (depends on MC-064). 3-day usage criterion measures signal triage from dashboard, not just digest viewing.

### Decisions
- Feed triage is a Phase 1 addition, not Phase 4 — it's data operations, not A2A infrastructure
- Promotion logic stays exclusively in feed-pipeline skill (no duplication)
- `dashboard_actions` table provides clean ownership boundary
- MC-028 parity gate blocked until M3b complete

### Compound Evaluation
- **Pattern: LLM-layer vs mechanical-layer decomposition** — when moving a skill's functionality to a different surface (web UI), decompose into "what needs reasoning" (stays in skill) and "what's deterministic" (can be a direct operation). The human decision at the UI replaces the LLM evaluation, so only the mechanical execution needs to cross the boundary.
- **Pattern: queue-for-skill over replicate-in-endpoint** — when a dashboard action requires the same quality as a Crumb skill, queue the intent and let the skill process it rather than reimplementing. Trades immediacy for quality and single-owner maintenance.

## 2026-03-07 — Project creation + SPECIFY completion

**Phase:** SPECIFY (complete)
**Operator:** Danny

### Context Inventory
- `_inbox/crumb-mission-control-spec-v2.md` — specification from claude.ai session
- `_inbox/crumb-mission-control-review-synthesis.md` — round 1 peer review (4 models, 20 amendments)
- `_inbox/crumb-mission-control-round2-addendum.md` — round 2 deep research review (12 amendments)
- `_inbox/crumb-mission-control-session-context.md` — session context + routing instructions

### Work Done
1. **Cross-project status synthesis** — pulled live state from all 6 related projects:
   - FIF: TASK phase, M4 YouTube soak in progress, M-Web 12 tasks 0 started (clean to absorb)
   - A2A: IMPLEMENT phase with M1/M2 live (corrected from session context which showed PLAN). Delivery abstraction operational. A2A-015.x superseded by this project.
   - tess-operations: TASK phase, M1 gate evaluation day 3
   - AKM: DONE, akm-feedback.jsonl ready for consumption
   - customer-intelligence: ACT phase, 3/25 dossiers populated
   - crumb-tess-bridge: DONE, dispatch state files documented and operational

2. **Project scaffold created** — `Projects/mission-control/` with design/, progress/, reviews/

3. **Spec v2 placed + R2 amendments applied** (12 amendments):
   - R2-1: Dark mode as genuine design exploration (U4, F5, §9.2, §13 rewritten)
   - R2-2: HTML/CSS mockups as primary Phase 0 approach (A7, U2 resolved, §9.1)
   - R2-3: Data source naming precision (§6.2, §6.3)
   - R2-4: Write atomicity for vault file operations (§7.1)
   - R2-5: Markdown rendering sanitization (§8.3)
   - R2-6: Approval surface idempotency contract (§8.6)
   - R2-7: Attention-item staleness mechanism (§7.1 schema + §7.3)
   - R2-8: Resolve OQ9 vault-native as decision (§7.3 + §14)
   - R2-9: Empty/error/stale state design as Phase 0 deliverable (§9.1 + gate checklist)
   - R2-10: Attention-item schema versioning (§7.1 + §7.3)
   - R2-11: Two new future pages — Finance + Home (§6.7)
   - R2-12: Phase 0 estimate adjustment to 4-8 sessions (§12)

4. **F3 corrected** — A2A status updated from "spec defines" to "IMPLEMENT phase with M1/M2 live"

5. **Review files placed:**
   - `reviews/2026-03-07-peer-review-synthesis.md`
   - `reviews/2026-03-07-round2-addendum.md`

### Key Decisions
- SPECIFY phase work from claude.ai session accepted as-is (no systems-analyst pass)
- A2A being in IMPLEMENT (not PLAN) strengthens Phase 4 feasibility — delivery layer already exists
- M-Web and A2A-015.x absorption confirmed clean (zero existing code)
- Three "missing" data sources (system-stats.sh, service-status.sh, attention-item primitive) are this project's deliverables, not upstream blockers

### Blockers
- None for PLAN phase entry

### Next
- Run action-architect for PLAN phase decomposition

---

### Phase Transition: SPECIFY → PLAN
- Date: 2026-03-07
- SPECIFY phase outputs: `design/specification.md`, `design/specification-summary.md`, `reviews/2026-03-07-peer-review-synthesis.md`, `reviews/2026-03-07-round2-addendum.md`
- Goal progress: All met — spec produced, peer reviewed (2 rounds, 32 amendments), cross-project state verified, F3 A2A status corrected
- Compound: No compoundable insights from SPECIFY phase — heavy thinking done in external claude.ai session; Crumb session was mechanical placement + amendment application
- Context usage before checkpoint: ~35% (fresh session, spec read via persisted output)
- Action taken: none
- Key artifacts for PLAN phase: `design/specification-summary.md`, `reviews/2026-03-07-round2-addendum.md` (PLAN-phase notes section)

---

## 2026-03-07 — PLAN phase: action-architect decomposition

**Phase:** PLAN
**Operator:** Danny

### Context Inventory
- `design/specification-summary.md` — primary input (1)
- `design/specification.md` — full spec via persisted output for constraint sections §6-10 (2)
- `reviews/2026-03-07-round2-addendum.md` — PLAN-phase notes (9 constraints) (3)
- `_system/docs/overlays/overlay-index.md` — checked, Design Advisor + Web Design Preference match Phase 0 (4)
- `_system/docs/solutions/write-read-path-verification.md` — informed adapter pipeline design (5)
- `_system/docs/solutions/html-rendering-bookmark.md` — Chart.js reference noted (6)
- No estimation calibration history exists

### Work Done
1. **Specification summary created** — `design/specification-summary.md` for downstream phase context
2. **9 R2 PLAN-phase constraints resolved** (PC-1 through PC-9):
   - PC-1: Aggregator risk → single-source first, progressive addition
   - PC-2: Nav badges → `/api/nav-summary` at 60s independent of page refresh
   - PC-3: Time semantics → UTC storage, local display, per-page sort keys
   - PC-4: Health header → auto-refresh via nav-summary on manual-pull pages
   - PC-5: Analog readout → max 4 custom SVG gauges
   - PC-6: Widget inventory → Phase 0 gate deliverable
   - PC-7: Testing → adapter unit tests required; React component tests deferred to retro
   - PC-8: Notifications → future Phase 3+
   - PC-9: SSE → polling-first, upgrade path if retro reveals need
3. **Action plan produced** — `design/action-plan.md` with 10 milestones (M0a-M10), dependency graph, cross-cutting conventions
4. **Tasks produced** — `design/tasks.md` with 52 atomic tasks (MC-001 through MC-052) covering Phases 0-3
5. **Action plan summary** — `design/action-plan-summary.md`

### Key Decisions
- Polling-first architecture (no SSE at launch) — simplicity wins at 30-60s refresh intervals
- Nav-summary as shared data source for both nav badges and manual-pull page health strips
- Single `writeVaultFile()` utility + single `SafeMarkdown` component as cross-cutting concerns
- Phases 4-5 (M11-M16) left at milestone-level — not decomposed into atomic tasks due to dependency distance
- Design gate (MC-010) is the highest-risk single task — blocks all implementation

6. **Peer review: Claude.ai** — 3 must-fix, 5 should-fix, all accepted and applied. Task count 52 → 54. Review at `reviews/2026-03-07-action-plan-claude-ai.md`.
7. **Peer review: multi-model synthesis** — 18 amendments (4 high-confidence, 4 medium, 10 single-reviewer), 2 declined. Key changes:
   - AP-1: attention_id → UUID v4 (collision safety across independent writers)
   - AP-2: M-Web parity gate concrete pass criteria (3 days usage, 400ms load)
   - AP-4: Aggregator reads `_inbox/attention/` in Phase 1 (quick-add visibility)
   - AP-8: PATCH 409 Conflict + .tmp zombie cleanup
   - AP-9: CSS variable palette toggle (Phase 0 efficiency)
   - AP-13: Knowledge "review stale sources" wired to POST /attention
   - AP-17: MC-009 split into MC-009 + MC-055
   - 3 new tasks: MC-055 (stale/error/mobile), MC-056 (Tess health monitoring), MC-057 (Playwright smoke)
   - Panel availability matrix added to MC-010 gate
   - Task count 54 → 57. Synthesis at `reviews/2026-03-07-action-plan-synthesis.md`.

### Housekeeping Notes
- `_inbox/` still has 4 raw upload files from the SPECIFY session — clean up during next inbox processing
- `design/session-context.md` has stale A2A status (shows PLAN, should be IMPLEMENT) — one-time handoff artifact, not a living document. Noted but not corrected since it won't be re-consumed.

8. **Dispatch review synthesis** — background 4-model dispatch (GPT-5.2, Gemini 3, DeepSeek, Grok) returned. Most findings overlapped with the synthesis already applied. 6 net-new findings applied:
   - DR-A1: CF Access verification middleware (MC-058) — auth at route layer, not adapter
   - DR-A2: Production build + Express static serve (MC-059)
   - DR-A3: M4 aggregator depends on MC-023 (adapter pattern proven)
   - DR-A4: Single-source integration test gate in MC-029 before multi-source
   - DR-A5: Nav-summary controller wired per milestone (MC-022, 026, 033, 042, 051)
   - DR-A6: Health strip on manual-pull pages (MC-026)
   - MC-050 updated: header check moved to middleware, adapter doesn't handle auth
   - Task count 57 → 59. Synthesis at `reviews/2026-03-07-action-plan-tasks.md`.

### Key Decisions
- SPECIFY phase work from claude.ai session accepted as-is (no systems-analyst pass)
- A2A being in IMPLEMENT (not PLAN) strengthens Phase 4 feasibility — delivery layer already exists
- M-Web and A2A-015.x absorption confirmed clean (zero existing code)
- Three "missing" data sources (system-stats.sh, service-status.sh, attention-item primitive) are this project's deliverables, not upstream blockers

### Housekeeping Notes
- `_inbox/` still has 4 raw upload files from the SPECIFY session — clean up during next inbox processing
- `design/session-context.md` has stale A2A status (shows PLAN, should be IMPLEMENT) — one-time handoff artifact, not a living document. Noted but not corrected since it won't be re-consumed.

### Compound
- **Peer review velocity:** Two-round review (claude.ai + multi-model synthesis) plus background dispatch produced 24 applied amendments and 59 tasks from an initial 52. The dispatch added 6 net-new findings the synthesis missed — confirms dispatch value even when operator provides manual synthesis.
- **Architecture pattern:** Auth middleware at route layer (not adapter) is a recurring Express best practice. 3/4 reviewers flagged the coupling independently. Worth noting for future Express projects.
- **Production serving gap:** A "build + static serve" task is easy to forget when developing locally with Vite dev server. Add to future M1 checklists for any Express + Vite monorepo.

### Next
- PLAN phase complete — transition to TASK phase when operator confirms
- Begin Phase 0 execution (M0a: aesthetic exploration)

---

### Phase Transition: PLAN → TASK
- Date: 2026-03-07
- PLAN phase outputs: `design/action-plan.md`, `design/action-plan-summary.md`, `design/tasks.md`, `reviews/2026-03-07-action-plan-claude-ai.md`, `reviews/2026-03-07-action-plan-synthesis.md`, `reviews/2026-03-07-action-plan-tasks.md`
- Goal progress: All met — 59 tasks across 10 milestones, dependency graph, 3 review rounds (24 amendments applied), cross-cutting conventions defined
- Compound: Captured in prior session (peer review velocity, auth middleware pattern, production serving gap)
- Context usage before checkpoint: <30% (fresh session, vault reconstruction)
- Action taken: none
- Key artifacts for TASK phase: `design/tasks.md`, `design/action-plan-summary.md`, `design/specification-summary.md`

---

## 2026-03-07 — TASK phase: M0a aesthetic exploration

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/action-plan-summary.md` — milestone/task overview (1)
- `design/tasks.md` — full task definitions, MC-001 through MC-003 for M0a (2)
- `design/specification-summary.md` — spec context (3)
- `design/specification.md` §6.2, §9.1-9.3 — Observatory principles, design phase requirements (4)
- `_system/docs/overlays/design-advisor.md` + `design-advisor-dataviz.md` — design + dataviz lenses (5)
- `_system/docs/overlays/web-design-preference.md` — personal aesthetic lens (6)
- `_system/docs/www-design-taste-profile.md` — full taste profile, Mode 2 Observatory (7)

### Work Done
1. **MC-001 complete** — Design workspace created at `design/mockups/`. Aesthetic brief produced at `design/aesthetic-brief.md` covering:
   - Observatory mode principles (from taste profile + spec §9.2)
   - Library vs Observatory tension analysis (warm light vs dark backgrounds)
   - Three exploration directions defined: Warm (antique barometer), Dark (observatory at night), Hybrid (wooden instrument cabinet)
   - Design Advisor, DataViz, and Web Design Preference lenses applied
   - MC-002 evaluation criteria established

2. **MC-002 in progress** — Ops page mockup built at `design/mockups/ops-mockup.html` + `ops-mockup.css`:
   - Single HTML file with CSS custom property palette toggle (Warm/Dark/Hybrid)
   - Real data density: 9 KPI cards, 4 SVG gauge instruments, 9 service cards, 24h timeline with 18 event dots, cost burn panel with 6 bar rows
   - Typography: Source Serif 4 headers, JetBrains Mono data values, Inter sans-serif chrome
   - SVG arc gauges with needles (analog instrument aesthetic)
   - Theme switcher widget for instant comparison
   - Mobile-responsive at 375px viewport

### Status
- MC-001: done — workspace + aesthetic brief
- MC-002: done — Ops mockup with 3 palette variants, 6 sections, theme switcher
- MC-003: done — Dark Observatory selected

### Design Decisions Recorded
- D1: Dark mode selected (Direction B)
- D2: 13px minimum text floor (all contexts)
- D3: 14px data-tier minimum (service values, LLM stats)
- D4: LLM Status section added to Ops page (new scope — not in original spec)
- D5: Section order: Status → Gauges → Services → Timeline → LLM Status → Cost Burn
- D6: Aesthetic direction documented in `design/aesthetic-brief.md`

### Milestone M0a: Complete
All 3 tasks done. Dark Observatory aesthetic confirmed. Ready for M0b.

### Compound
- **Dark mode for Observatory:** Despite the taste profile's "no dark mode as default" anti-pattern, operator chose dark for the dashboard. The key insight: the anti-pattern applies to reading-centric Library mode, not operational Observatory mode. Status color visibility on dark backgrounds is a genuine functional advantage, not aesthetic preference. This nuance should inform future mode-specific design decisions.
- **LLM Status as first-class Ops section:** Not in the original spec — emerged during mockup review. "Is my model working?" is an operational question at the same tier as "is my service running?" Future Ops page specs for LLM-dependent systems should include provider health as a default section.
- **13px minimum text floor:** Dark backgrounds require slightly larger text for equivalent readability. The 13px chrome / 14px data two-tier minimum is a design system constraint worth carrying forward to any dark-mode dashboard project.

### Code Review
- Code Review — Skipped (MC-001, MC-002, MC-003): Phase 0 design tasks — HTML/CSS mockups, not implementation code. No repo_path exists yet. Code review applies from Phase 1 (MC-011+) when repo is created.

### Next
- M0b continues: MC-006 (widget inventory + analog readout budget)

---

## 2026-03-07 — M0b design system + widget vocabulary (MC-004, MC-005)

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/action-plan-summary.md` — milestone/task overview (1)
- `design/tasks.md` — MC-004/MC-005 acceptance criteria (2)
- `design/aesthetic-brief.md` — D1-D6 design decisions (3)
- `design/mockups/ops-mockup.css` — established dark palette and type scale (4)
- `design/specification.md` §6.2, §6.6, §9.1-9.3 — Ops, Knowledge, design system requirements (5)
- `reviews/2026-03-07-action-plan-synthesis.md` — AP-19/20/21 amendments (6)

### Work Done
1. **AP-19/20/21 applied to spec and tasks:**
   - §6.2: LLM Status section (per-model cards, empirical health, above Cost Burn)
   - §6.6: Vault Gardening section (dead knowledge, orphans, stale sources, tag hygiene, QMD health)
   - §9.2: 13px/14px text floor constraint
   - tasks.md: MC-020 expanded to 4 adapters, MC-021/023/040/042 updated for new scope

2. **MC-004 complete** — Design system document (`design/design-system.md`):
   - Color system: 8 token groups, 30+ tokens with explicit values
   - Typography scale: 3 families, 8 size tiers, typography rules
   - Panel component: 4 variants (KPI card, service card, standard panel, gauge container)
   - Focus/keyboard: `--focus-ring` token, `:focus-visible` convention
   - Transition conventions: system-wide defaults and exceptions
   - Panel component HTML reference page (`design/mockups/panel-component.html`)
   - Review round: 6 findings from operator review, all addressed

3. **MC-005 complete** — Widget vocabulary (`design/mockups/widget-vocabulary.html` + `widget-vocabulary.css`):
   - 14 archetypes rendered with real data patterns
   - New widgets: attention cards (×3 kinds), signal card, agent status card, search result card, approval card, progress bar, badge variants (7 groups), data table
   - All with `:focus-visible` keyboard treatment and responsive behavior

4. **Text floor enforcement:**
   - `.cost-bar-value` bumped from 13px to 14px (data tier, not chrome)
   - Memory/disk KPI inline spans bumped from 12.8px to 13px (floor violation)
   - CSS palette comment markers added for stable cross-references

### Key Decisions
- Disabled/loading state tokens deferred to MC-055 (empty/error/stale state patterns) — not MC-004 scope
- `--accent-selected` (0.22 alpha) added alongside `--accent-muted` (0.12 alpha) for stronger tint on selected cards/filters
- Skeleton shimmer timing deferred to MC-055

### Code Review
- Code Review — Skipped (MC-004, MC-005): Phase 0 design tasks — HTML/CSS mockups and design system documentation, not implementation code. No repo_path exists yet. Code review applies from Phase 1 (MC-011+).

### Next
- MC-006: widget inventory + analog readout budget

---

## 2026-03-07 — MC-006 widget inventory + analog readout budget

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-006 acceptance criteria (1)
- `design/specification.md` §6.0-6.6 — per-page layouts and data sources (2)
- `design/design-system.md` — panel variants and archetypes (3)
- `design/mockups/widget-vocabulary.html` — 14 widget archetypes (4)
- `design/mockups/ops-mockup.html` — Ops page widget instances (5)
- `progress/run-log.md` — prior session context, design decisions D1-D6 (6)

### Work Done
1. **MC-006 complete** — Widget inventory produced at `design/widget-inventory.md`:
   - 97 total widget instances (structural count) across 6 pages + nav shell
   - All 14 vocabulary archetypes + 4 panel variants used — no new custom archetypes needed
   - 4/4 custom SVG gauge budget allocated to Ops Resource Gauges (CPU, Memory, Disk, GPU)
   - 5 analog readout candidates evaluated and rejected for gauge treatment (progress bar or KPI instead)
   - 9 blocked panels identified across 5 pages (placeholder treatment per §6.0)
   - Per-page instance tables with section, widget name, type, data source, custom/standard columns
   - Archetype usage matrix showing cross-page coverage

### Key Decisions
- All 4 SVG gauges on Ops page (resource metrics) — no gauges on other pages
- FIF cost, YT quota, dossier completeness, budget vs actual, MOC coverage all use progress bar or KPI card instead of gauge — rationale documented per candidate
- Blocked panels counted in total (9 of 97) since they need empty-state treatment (MC-055)
- GPU gauge kept (in ops-mockup since MC-002) — flagged spec §6.2 / MC-016 gap: `system-stats.sh` AC needs GPU utilization added
- Batch book pipeline widget folded into Project Health section (Knowledge page) rather than standalone section — it's one project's data, same pattern as other project cards but with enriched progress bar

### Scope Addition
- **Workbench decision:** Customer intelligence working surface (dossier review, pre-meeting prep, account management) deferred as W1-W3 milestones in mission-control action plan. Separate read-write site within monorepo, spec'd after Phase 1 retro. See action plan deferred section.

### Next
- MC-007: Attention page mockup at real data density
- MC-008: Ops page mockup at real data density (evolve from MC-002)

---

## 2026-03-07 — MC-007 + MC-008: Attention + Ops mockups

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-007/MC-008 acceptance criteria (1)
- `design/widget-inventory.md` — widget-to-page mapping (2)
- `design/design-system.md` — color/typography/panel spec (3)
- `design/mockups/widget-vocabulary.html` + `widget-vocabulary.css` — 14 archetypes (4)
- `design/mockups/ops-mockup.html` + `ops-mockup.css` — existing Ops mockup to evolve (5)
- `progress/run-log.md` — prior session context (6)

### Work Done
1. **MC-007 complete** — Attention page mockup (`design/mockups/attention-mockup.html` + `attention-mockup.css`):
   - Urgency strip: 4 KPI cards (Now: 2, Soon: 3, Ongoing: 4, Awareness: 3), colored left borders on Now/Soon
   - Quick-add form: title input + domain/urgency/kind dropdowns, sensible defaults (career/soon/personal)
   - Filter bar: Urgency, Kind, Domain, Source filter groups with active state + Triage/Domain/Source view switcher
   - 12 attention cards: 4 system, 3 relational, 5 personal across all 4 urgency levels
   - 1 approval card embedded at correct urgency position (Soon)
   - Completed/dismissed feed: collapsible section with 2 muted cards (distinct opacity for done vs dismissed)
   - Nav cross-link to ops-mockup.html for browser navigation
   - All real data patterns from Crumb ecosystem

2. **MC-008 complete** — Ops page evolved (`design/mockups/ops-mockup.html` updated):
   - 3 blocked placeholder panels added under "Operational Intelligence" section
   - Operational Efficiency (requires self-optimization loop)
   - Operational Tempo (requires tempo adaptation)
   - Degradation Awareness (requires degradation-aware routing)
   - Dashed border + 50% opacity + stale dots + italic dependency labels
   - All prior content unchanged — existing mockup already met all AC from MC-002

3. **Review round — 3 fixes applied:**
   - `--accent-selected` token added to all 3 palette blocks in ops-mockup.css (same class of bug as focus-ring from MC-005 review)
   - Nav badge updated from 12 to 13 (includes pending approval)
   - Urgency filter group added to filter bar (was missing per MC-033 AC)

### Key Decisions
- Nav badge counts all items needing attention including pending approvals (13 = 12 attention + 1 approval)
- Domain filter shows only domains with active items (4 of 8) — intentional UX decision, not a bug
- Placeholder panel inline styles are a mockup convenience — MC-055 will extract to `.placeholder-panel` class
- Approval card positioned inline at its urgency level rather than in a separate section

### Code Review
- Code Review — Skipped (MC-007, MC-008): Phase 0 design tasks — HTML/CSS mockups, not implementation code. No repo_path exists yet.

### Next
- MC-009: Intelligence page mockup + nav shell
- MC-055: Empty/error/stale state patterns + mobile viewport testing

---

## 2026-03-07 — MC-009: Intelligence page + nav shell

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-009 acceptance criteria (1)
- `design/widget-inventory.md` — Intelligence page widgets, nav shell widgets (2)
- `design/specification.md` §6.3 — Intelligence page layout (Pipeline + Production) (3)
- `design/mockups/widget-vocabulary.html` + CSS — signal cards, search cards, badges (4)
- `design/mockups/ops-mockup.css` — shared tokens and nav rail (5)
- `design/design-system.md` — color/typography reference (6)

### Work Done
1. **MC-009 complete** — Intelligence page mockup (`design/mockups/intelligence-mockup.html` + `intelligence-mockup.css`):
   - **Pipeline section:** 5 KPI cards (signals today + sparkline, this week, sources breakdown, triage distribution, cost + progress bar), signal digest panel with 5 cards in contained layout (T1/T2/T3 tier filter), pipeline health with 3 circuit breaker indicators + data table, tuning blocked panel
   - **Production section:** research briefs queue (1 pending, 2 completed), weekly intelligence brief (rendered markdown), connections brainstorm featured card (accent-tinted), ecosystem radar (2 items)
   - **Nav shell:** full nav rail with status dots on all 6 pages (badge on Attn, ok/warn dots on others), search bar in page header with magnifying glass icon, search overlay dropdown with 3 result cards (collection badges, relevance scores, highlighted snippets)
   - Cross-links to attention-mockup.html and ops-mockup.html

2. **New CSS patterns extracted:**
   - `.blocked-panel` class — reusable for MC-055 (replaces inline styles from MC-008)
   - `.digest-panel` / `.digest-body` — cards-within-panel containment (no individual borders)
   - `.page-section-header` — section dividers with accent underline
   - `.brainstorm-card` — featured card with accent tint background
   - `.kpi-progress` — inline progress bar within KPI card (cost vs ceiling)

3. **Review round — no fixes needed:**
   - `--accent-selected` already present in all 3 palette blocks (fixed in MC-007 round)
   - Nav badge already consistent at 13 across all mockups (fixed in MC-007 round)
   - Negative margin on pipeline health table noted as Phase 1 implementation concern

### Key Decisions
- Pipeline and Production sections visually separated by page-section-header dividers with accent underline
- Signal digest uses contained panel layout (cards lose individual borders, panel provides containment) — cleaner than grid of bordered cards for feed-style content
- Brainstorm card gets accent tint background to distinguish "new" featured content from standard panels
- Search overlay positioned right-aligned under header search bar with shadow for depth

### Code Review
- Code Review — Skipped (MC-009): Phase 0 design task — HTML/CSS mockup, not implementation code. No repo_path exists yet.

### Next
- MC-055: Empty/error/stale state patterns + mobile viewport testing
- MC-010: Design gate review (depends on MC-009 + MC-055)

---

## 2026-03-07 — Spec updates: M9 enrichment + vault-check primitive registry

**Phase:** TASK
**Operator:** Danny

### Work Done
1. **M9 enrichment note** appended to `design/action-plan.md`:
   - Skill Utilization, Overlay Utilization, Agent Routing Distribution, Agent Activity Patterns sections
   - Depends on `skill-telemetry.jsonl` (separate Crumb spec amendment)
   - Agent Activity Patterns uses telemetry + existing M9 adapters (dispatch-state, tess-context, cost-aggregation)
   - Primitive registry detection via vault-check → dashboard picks up through MC-020 adapter

2. **vault-check primitive registry rule** added to `_system/scripts/vault-check.sh`:
   - REGISTERED_SKILLS (21 skills) and REGISTERED_OVERLAYS (8 overlays) lists
   - Scans `.claude/skills/` and `_system/docs/overlays/` against registry
   - Warns on unregistered primitives (non-blocking)
   - Tested: full vault-check passes clean, detection confirmed with synthetic unregistered skill

### Compound
- **Design system token propagation pattern:** `--accent-selected` was defined in design-system.md (MC-004) but not added to ops-mockup.css palette blocks — same bug class as `--focus-ring` from last round. Any token defined in the design system doc must be added to all 3 CSS palette blocks at definition time, not when first consumed. This is a recurring pattern worth a pre-flight checklist for future design system tokens.
- **Cards-within-panel containment:** The Intelligence digest panel demonstrates a reusable pattern — signal cards inside a container panel lose their individual borders/shadows and use subtle separators instead. This is more scannable for feed-style content than a grid of individually bordered cards. Worth carrying forward to any list-within-panel layout.
- **Blocked panel extraction:** Moving from inline styles (MC-008 Ops page) to a `.blocked-panel` class (MC-009 Intelligence page) confirms the pattern. 9 blocked panels across 5 pages all need this treatment — MC-055 should formalize it in the design system.

### Model Routing
- All work executed on Opus (session default). No delegation — Phase 0 design work requires contextual judgment across spec, mockups, and design system.

### Next
- MC-055: Empty/error/stale state patterns + mobile viewport testing
- MC-010: Design gate review

---

## 2026-03-07 — MC-055: State patterns + mobile viewport

**Phase:** TASK
**Operator:** Danny

### Context Inventory
- `design/tasks.md` — MC-055 acceptance criteria (1)
- `design/design-system.md` — token system, deferred `--bg-skeleton`/`--text-disabled` (2)
- `design/mockups/ops-mockup.css` — shared tokens + 3 palette blocks (3)
- `design/mockups/widget-vocabulary.css` — cross-page widget archetypes (4)
- `design/mockups/intelligence-mockup.css` — `.blocked-panel` source (5)
- `design/mockups/ops-mockup.html` — blocked panels with inline styles (6)
- `design/mockups/attention-mockup.html` + CSS — mobile viewport target (7)

### Work Done
1. **Deliverable 1 — Four state patterns formalized in CSS:**
   - **Blocked/placeholder:** `.blocked-panel` moved from intelligence-mockup.css to widget-vocabulary.css (cross-page pattern). Dashed border, 50% opacity, stale dot, italic description.
   - **Empty state:** `.state-empty`, `.state-empty-icon`, `.state-empty-text`. Centered layout with muted icon (32px, `--text-disabled`). KPI card variant: value + sub in disabled color.
   - **Error state:** `.state-error-banner` with error icon + message + retry metadata. KPI card variant: error-colored border + value. Card-within-list variant: error border + tinted background.
   - **Stale state:** `.state-stale-banner` with clock icon + age/threshold text. KPI card variant: warn-colored 3px left border. Card-within-list variant: 2px amber top stripe via `::before`.

2. **Design tokens added:**
   - `--bg-skeleton` and `--text-disabled` added to all 3 palette blocks (warm/dark/hybrid)
   - Design system doc §1.5a added with dark values, §3.8 added with full state pattern reference

3. **Ops blocked panels migrated:**
   - 3 "Operational Intelligence" cards converted from inline styles (`style="border: 1px dashed...; opacity: 0.5;"`) to `.blocked-panel` class
   - `widget-vocabulary.css` import added to ops-mockup.html

4. **State pattern demos added to widget-vocabulary.html:**
   - 4 widget groups (blocked, empty, error, stale) with examples at all 3 levels (full panel, KPI card, card-within-list)
   - Real data patterns: FIF database error, stale gateway, empty signals, blocked relationship heat map

5. **Deliverable 2 — Mobile viewport review (375px):**
   - CSS review of all responsive rules for Attention + Ops pages
   - **Fix applied:** `flex-wrap: wrap` + `gap: 4px` added to `.page-header` at ≤480px — prevents title + refresh-ts from overflowing at 375px ("Operations" + timestamp exceeds 295px usable width without wrapping)
   - Verified: nav rail compresses to 48px ✓, KPI strip stacks to 2 columns ✓, service grid single column ✓, gauge row 2 columns ✓, filters stack vertically ✓, cost bar labels shrink to 80px ✓, text floors (13px/14px) maintained ✓, data tables get `overflow-x: auto` ✓, quick-add form stacks vertically ✓
   - **Note:** Visual browser test at 375px deferred to operator — CSS analysis confirms no horizontal overflow sources, but screenshot verification recommended

### Key Decisions
- State pattern CSS lives in widget-vocabulary.css (cross-page concern), not in page-specific CSS files
- Blocked panel uses `.blocked-panel` class at all three levels; KPI card blocked variant uses inline styles since the existing `.kpi-card` base handles most of the styling
- Error and stale card-within-list treatments are additive (classes compose with existing card classes)

### Compound
- **State patterns as cross-page concern:** Blocked panel started in intelligence-mockup.css (page-specific) but was needed on 5 pages. Moving to widget-vocabulary.css (shared) early prevents the same class from being duplicated per-page. Future cross-page patterns should start in widget-vocabulary.css from day one.
- **Inline style → class extraction timing:** The MC-008 → MC-055 gap (blocked panels in inline styles for one session, then extracted to a class) is acceptable for mockup velocity but would be a problem in production CSS. In Phase 1, establish a rule: if a visual pattern appears on more than one page, extract to shared CSS before the PR merges.

### Code Review
- Code Review — Skipped (MC-055): Phase 0 design task — HTML/CSS mockups, not implementation code. No repo_path exists yet.

### Scope Addition
- **Workbench expansion:** W1-W3 scope expanded with per-account detail pages (Contacts/Personas, Active Opportunities, Comms & Product Strategies) and master→detail navigation pattern. Key architectural distinction from Mission Control's single-page observatory model. Action plan updated.

### Next
- MC-010: Design gate review (all M0b prerequisites now complete — 7/7 tasks done)

---

