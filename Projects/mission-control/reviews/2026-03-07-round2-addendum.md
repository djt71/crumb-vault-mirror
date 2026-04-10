---
project: mission-control
type: review
review_type: round-2-addendum
domain: software
status: active
created: 2026-03-07
updated: 2026-03-07
tags:
  - peer-review
  - dashboard
  - amendments
---

# Mission Control Dashboard — Round 2 Review Addendum

**Context:** After the v2 spec was produced (20 amendments from round 1), a second
review round was conducted with deep research enabled (Gemini 3, ChatGPT GPT-5.2,
Perplexity). Gemini's review was discarded — it hallucinated a Deno/Next.js
architecture that doesn't exist in the spec and reviewed that instead. ChatGPT
and Perplexity produced substantive reviews grounded in the actual spec.

This addendum lists items to apply to v2 during the first Crumb session, plus
two new page directions from the operator.

---

## Amendments to Apply

### R2-1. Resolve dark mode as a genuine design exploration, not an exclusion

**Source:** ChatGPT round 2 (must-fix), operator direction

The spec contradicts itself: U4 lists dark mode as an open question, §13
excludes it at launch, and the M-Web table maps dark mode work into Phase 1.
Additionally, the operator clarified that the "warm light background"
preference applies to *reading-centric content* (blogs, articles, long-form
digests), not necessarily dashboards. Dark mode is the established convention
for operational dashboards because status colors are more distinct against
dark backgrounds and operators experience less eye strain during extended use.

**Amendment:**
- U4 rewritten: "Aesthetic mode selection. The taste profile defines Library
  (warm/light, reading-centric) and Observatory (dashboard/metrics) as
  separate modes. The design phase must explore whether the dashboard uses
  dark mode for operational pages (Ops, Agent Activity, Finance), light mode
  for reading-heavy content (Intelligence Production, digest detail views),
  a hybrid approach (dark chrome + light content panels), or a unified
  aesthetic. This is the primary aesthetic question for Phase 0."
- §13 exclusion removed. Replace with: "Aesthetic direction is resolved in
  Phase 0. The design phase explores dark, light, and hybrid approaches. No
  predetermined commitment to either."
- §11 M-Web table: FIF-W09-W10 row changes to "Theming infrastructure
  deferred to Phase 0 aesthetic decision."
- Phase 0 gate checklist item added: "Aesthetic direction decided and
  documented (dark / light / hybrid / toggle)."

### R2-2. HTML/CSS mockups as the primary Phase 0 approach

**Source:** Perplexity round 2 (O-5), ChatGPT round 2 (should-fix), operator direction

The operator confirmed that HTML/CSS mockups should be the primary design
approach, not Figma. This eliminates the design tool learning curve and
produces artifacts directly reusable in Phase 1.

**Amendment:**
- A7 rewritten: "HTML/CSS is the primary design approach for Phase 0.
  Static HTML pages with real typography (ET Book / Source Serif), real color
  palettes, and representative data test the aesthetic at true browser
  rendering fidelity. These artifacts are directly reusable in Phase 1
  implementation. Figma or equivalent available as optional complement for
  exploratory layout iteration, not required."
- U2 resolved: design tool question answered. Remove from Unknowns. Add a
  note: "Figma remains available for future design exploration but is not a
  Phase 0 prerequisite."
- Phase 0 session estimate stays at 4-8 (tool learning removed, but
  deliverable list is substantial and aesthetic exploration scope increased
  per R2-1).

### R2-3. Data source naming precision

**Source:** ChatGPT round 2 (must-fix)

The spec references `tess-health-check.sh` as a "state file" — it's a
script. The state file is at `/tmp/tess-health-check.state`. And
`signals.jsonl` is mentioned as a Feed Intelligence data source without
confirming it exists as a stable artifact.

**Amendment:**
- §6.2 data sources: change `tess-health-check.sh state file` to
  `/tmp/tess-health-check.state` (health check state) and
  `_system/logs/health-check.log` (health check log).
- §6.3 Pipeline section: mark `signals.jsonl` as "assumed — validate exists
  and is stable before building adapter. If absent, derive time-series from
  FIF SQLite state DB."
- Add to PLAN requirement: each adapter's data contract must specify exact
  file path, expected schema/format, and failure mode if missing.

### R2-4. Write atomicity for vault file operations

**Source:** ChatGPT round 2 (must-fix)

V2 defines mutation precedence as "last writer wins" but doesn't address
partial writes or Obsidian autosave race conditions. The Express API writing
markdown files to a vault that Obsidian is watching can create corrupt files
if a write is interrupted.

**Amendment:**
- Add to §7.1 after mutation precedence: "Write atomicity: all vault writes
  use the temp-file-then-atomic-rename pattern (write to
  `<filename>.tmp`, then `rename()` to final path). This prevents partial
  writes from being visible to Obsidian's file watcher or other readers.
  PLAN must document how Obsidian's file-watching behavior interacts with
  atomic renames on macOS (HFS+/APFS)."

### R2-5. Markdown rendering sanitization

**Source:** ChatGPT round 2 (must-fix)

The dashboard renders vault notes and intelligence outputs — much of which
is markdown produced by agents. Unsanitized markdown containing unexpected
HTML or links is an injection surface, even for a single-user tool.

**Amendment:**
- Add to §8.3 (API Design Principles): "Rendering safety: all markdown
  content rendered in the frontend must be sanitized (e.g., DOMPurify) to
  strip unexpected HTML, scripts, and event handlers. File path access is
  constrained to vault directories — the API never serves arbitrary
  filesystem paths. Agent-produced content is treated as untrusted input
  for rendering purposes."

### R2-6. Approval surface idempotency contract

**Source:** ChatGPT round 2 (must-fix)

Two surfaces (Telegram + dashboard) for the same AID-* approvals create
a race condition risk. Approving in Telegram while the dashboard shows
the same item as pending leads to duplicate actions without idempotency.

**Amendment:**
- Add to §8.6 under the approval endpoint: "Idempotency: the canonical
  approval state lives in the AID-* record file. Both Telegram and
  dashboard read from and write to this record. The dashboard must check
  current status before executing an action — if already approved/denied/
  expired, the dashboard shows the resolved state and does not re-execute.
  PLAN must define idempotency keys and replay safety rules for the
  approval surface, even though Phase 4 is distant — the contract must be
  compatible across both projects."

### R2-7. Attention-item staleness mechanism for open items

**Source:** Perplexity round 2 (MF-3)

V2 has an archival policy for done/dismissed items (A17) but no mechanism
for open items to age or escalate. Items in "awareness" urgency with no
due date accumulate indefinitely.

**Amendment:**
- Add to §7.1 schema: `deferred_until: YYYY-MM-DD  # optional, for
  deferred items`
- Add to §7.3 after archival policy: "Staleness nudge: open items
  untouched (no `updated` change) for >14 days trigger a Tess nudge via
  the awareness-check mechanism. The nudge creates no new items — it
  surfaces the stale item in the next morning briefing with a prompt:
  'This attention item has been open 14+ days. Still relevant?' Operator
  can then act, defer with a new `deferred_until` date, or dismiss.
  Deferred items resurface when `deferred_until` arrives."

### R2-8. Resolve OQ9 (vault-native vs API-native) as a decision

**Source:** Perplexity round 2 (MF-5)

The spec already makes the case for vault-native in the question text.
This should be stated as a decision, not left open.

**Amendment:**
- Remove OQ9 from §14 (Open Questions).
- Add to §7 (after §7.3): "Persistence decision: vault-native markdown
  is the source of truth (preserves Obsidian editability, compound
  engineering principle, existing vault patterns). The API layer may
  maintain a lightweight SQLite index that rebuilds from vault scans if
  the performance budget (§8.3) is exceeded. The index is a cache, not a
  second source of truth. Until performance measurement indicates
  otherwise, direct filesystem reads are sufficient."

### R2-9. Empty/error/stale state design as Phase 0 deliverable

**Source:** Perplexity round 2 (SF-1)

Every page will show empty panels on first deploy. These states need
visual treatment.

**Amendment:**
- Add to §9.1 deliverables (as item 7): "Empty / error / stale state
  patterns — visual treatment for four states: empty (first use or no
  data), stale (data older than expected refresh interval), error
  (adapter failure or unreachable source), partial (some adapters
  responding, others not). Each state needs a distinct, recognizable
  visual treatment."
- Update gate checklist: add item 11: "Empty, stale, and error states
  have defined visual treatments."

### R2-10. Attention-item schema versioning

**Source:** Perplexity round 2 (SF-7)

Vault-native markdown notes don't have migration tooling. If the schema
evolves, existing items need a compatibility path.

**Amendment:**
- Add `schema_version: 1` to the attention-item schema in §7.1.
- Add to §7.3: "Schema evolution: the API adapter handles backward
  compatibility by defaulting missing fields for older schema versions.
  Tess's mechanic can include a schema-version check in the monthly
  archival job, flagging items with outdated versions."

### R2-11. Two new future pages: Personal Finance and Home

**Source:** Operator direction

The dashboard should extend beyond Crumb operational tooling into personal
life management. Two additional pages are planned for future phases:

**Personal Finance page** (future — Phase 3+):
- Portfolio overview (401k, brokerage positions, performance)
- Property value tracking (Zillow/Redfin estimates, neighborhood trends)
- Finance news / market signals (potentially a new FIF adapter source)
- Budget/cash flow indicators
- Financial attention items (tax deadlines, rebalancing triggers, insurance)
- Maps to Financial Advisor overlay outputs
- **Architectural note:** This page requires external API data sources
  (broker APIs, property value APIs, finance RSS) that don't exist in the
  vault today. This is a different class of adapter than local file reads.
  The FIF adapter pattern can potentially handle finance news feeds.

**Home Dashboard page** (future — Phase 3+):
- Home maintenance schedule (HVAC, seasonal tasks, recurring items)
- Car maintenance (oil changes, tire rotation, inspection, mileage)
- Active home projects (renovation, contractor follow-ups, purchases)
- Chore cadence tracking
- Household inventory / warranty tracking
- Depends on Apple Reminders integration (tess-ops) for structured task data
- Starts as attention items via manual quick-add, evolves into dedicated
  schema if patterns emerge (compound engineering principle)

**Amendment:**
- Add §6.8 (Future Pages) describing both pages with the above content
  and noting dependencies, data source challenges, and phasing.
- Note in page architecture intro: "Six pages in Phases 1-3. Two additional
  pages (Personal Finance, Home) planned for future phases, potentially
  reaching 8. The nav rail and design system must accommodate future page
  growth."
- These pages strengthen the case for content-aware aesthetic treatment
  (R2-1): a finance page with portfolio charts is pure dashboard territory
  (dark-friendly), while reading finance news articles is Library mode
  (light-friendly).

### R2-12. Phase 0 estimate adjustment

**Source:** Perplexity round 2 (MF-2)

2-4 sessions was optimistic even before R2-1 expanded the aesthetic
exploration scope. With HTML/CSS mockups (R2-2) and dark/light/hybrid
exploration (R2-1), the deliverable list is substantial.

**Amendment:**
- Phase 0 estimate: 4-8 sessions (up from 2-4). Split into two
  sub-milestones: (0a) aesthetic exploration — produce 2-3 competing
  directions (dark, light, hybrid) for the same page, (0b) formal
  deliverables — widget vocabulary, color system, typography, panel
  components, page mockups per the gate checklist.

---

## PLAN-Phase Notes (not spec amendments, but flagged for action-architect)

These items from the round 2 reviews are valid but belong in PLAN, not
SPECIFY:

- **Attention aggregator is the riskiest milestone** (Perplexity SF-3).
  PLAN should explicitly flag M4/M5 difficulty asymmetry and consider
  building the aggregator with a single source first, then progressively
  adding sources.
- **Nav badge refresh strategy** (ChatGPT should-fix). PLAN should define
  a lightweight summary endpoint for shell-level badges, independent of
  per-page refresh.
- **Time semantics policy** (ChatGPT should-fix). PLAN should define:
  store UTC, display local, canonical sort key per page.
- **Manual-pull pages with health indicators** (ChatGPT should-fix). PLAN
  should decide whether health headers auto-refresh independently of the
  full page content on manual-pull pages.
- **Analog readout implementation budget** (Perplexity SF-4). Phase 0
  should categorize which readouts are custom SVG vs standard widgets.
  Budget: 3-4 custom gauge components max. The taste profile supports
  restraint: "analog-feeling readouts where data warrants, but not as
  skeuomorphic decoration."
- **Widget inventory** (Perplexity SF-8). Phase 0 should produce an
  explicit count of every widget instance across all pages.
- **Testing strategy** (Perplexity SF-9). PLAN should define: adapter
  unit tests (highest value), aggregator integration tests, and a note
  on whether React component testing earns its ceremony cost.
- **Notifications story** (Perplexity O-8). Browser notifications should
  be listed as a future consideration for making the dashboard viable as
  a primary surface for time-sensitive items.
- **SSE as likely winner for data refresh** (Perplexity O-6). PLAN should
  resolve U5 in favor of SSE or polling-first-then-SSE.

---

## Review Quality: Round 2

| Reviewer | Verdict |
|----------|---------|
| Gemini 3 (deep research) | **Discarded.** Hallucinated a Deno/Next.js architecture. Reviewed a system that doesn't exist. Zero usable findings. |
| ChatGPT GPT-5.2 (deep research) | **Excellent.** 8 must-fixes (4 already addressed in v2, 4 genuinely new), 5 should-fixes all grounded in the actual spec with precise cross-references. Strongest contributions: write atomicity, markdown sanitization, approval idempotency, dark mode inconsistency. |
| Perplexity (deep research) | **Strong.** 5 must-fixes (2 already addressed, 3 new), 9 should-fixes, 9 observations. Strongest contributions: attention-item staleness, Phase 0 estimate realism, schema versioning, empty state design, aggregator risk flagging. Best observation: compound engineering tension with the attention-item primitive. |
