---
project: mission-control
type: review
review_type: peer-review-synthesis
domain: software
status: active
created: 2026-03-07
updated: 2026-03-07
tags:
  - peer-review
  - dashboard
  - architecture
---

# Mission Control Dashboard — Peer Review Synthesis

**Panel:** Gemini 3, DeepSeek V3.2, ChatGPT (GPT-5.2), Perplexity
**Meta-reviewer:** Claude Opus 4.6 (this session)
**Scope:** Specification draft, context briefing, design taste profile

---

## Review Quality Assessment

| Reviewer | Findings | Unique Contributions | Overall |
|----------|----------|---------------------|---------|
| Gemini 3 | 3 must, 3 should, 3 obs | Write-conflict concern, density paradox | Light — missed major structural issues |
| DeepSeek V3.2 | 4 must, 6 should, 6 obs | Dashboard self-monitoring, design gate criteria, AKM adapter complexity, testing gap | Strong — thorough and well-reasoned |
| ChatGPT (GPT-5.2) | 5 must, 6 should, 5 obs | Phase ordering mismatch, phantom completeness, read-first contradiction, M-Web kill-switch, dependency blur, React justification gap | Strongest — engaged with internal logic, caught the deepest structural issues |
| Perplexity | 6 must, 6 should, 3 obs | Schema bias toward personal items, capture ownership model, customer-intelligence privacy, Ops data source gaps, AKM visualization vs action, search UX consistency | Solid — practical and specific, unique privacy angle |

---

## Amendments: Accept

Changes to apply to the spec before PLAN phase.

### A1. Bring Attention page forward to Phase 1

**Source:** ChatGPT #1 (must), DeepSeek #6 (should), Gemini implicit
**Consensus:** 3 of 4 reviewers flagged the contradiction between "what needs me?" as the core problem and Attention being deferred to Phase 2.

**Amendment:** Restructure Phase 1 to include an Attention-lite page alongside Ops and Feed Intelligence. Phase 1 Attention is limited to system-generated items that already have data sources: dispatch approvals (pending bridge files), pipeline alerts (FIF health), vault-check warnings, and Healthchecks.io stale pings. Manual quick-add is also Phase 1 — it's a single write endpoint creating a markdown file. Overlay-generated items and the full aggregation engine remain Phase 2.

**Revised Phase 1:** Scaffolding + Ops + Feed Intelligence + Attention-lite (system items + manual quick-add)

### A2. Harden the attention-item schema

**Source:** ChatGPT #3 (must), DeepSeek #1-2 (must), Perplexity #1-2 (must)
**Consensus:** 4 of 4 reviewers identified schema underspecification. ChatGPT provided the most comprehensive list of missing fields; Perplexity identified the structural bias toward personal items.

**Amendment:** Extend §7.1 schema with:

```yaml
---
type: attention-item
attention_id: att-YYYYMMDD-NNN   # stable unique ID
kind: [system | relational | personal]
domain: [career | financial | health | creative | spiritual | relationships | software | learning]
source_overlay: [life-coach | career-coach | business-advisor | financial-advisor | null]
source_system: [dispatch | fif | ops | vault-check | approval | awareness-check | null]
source_ref: [correlation_id | dispatch_id | signal_id | null]  # join back to origin
created_by: [crumb-session | dashboard | tess | manual]
status: [open | in-progress | done | deferred | dismissed]
urgency: [now | soon | ongoing | awareness]
action_type: [approve | review | respond | reflect | track | null]  # what kind of action
related_entity: [account_id | project_name | null]  # optional, for joining
created: YYYY-MM-DD
due: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - attention
  - [domain tag]
---
```

Add to §7: file naming convention (`attention-<attention_id>.md`), file location (`_inbox/attention/` for system-generated, `Domains/<domain>/attention/` for personal), dedup rules (same `source_ref` within 24h → update existing instead of creating new), and mutation precedence (source of truth is the file on disk; last writer wins; dashboard and Obsidian edits are equivalent).

### A3. Define capture ownership model

**Source:** Perplexity #2 (must), ChatGPT #3 (must), DeepSeek #1 (must)

**Amendment:** Add to §7.2:

| Item kind | Writer | Trigger |
|-----------|--------|---------|
| System (dispatch) | Tess | Dispatch enters `blocked` state or completes with review-needed flag |
| System (pipeline) | Tess | FIF health check detects anomaly requiring human judgment |
| System (ops) | Tess | Awareness-check or heartbeat finds condition requiring human decision |
| System (approval) | Tess | AID-* approval request created (future: TOP-049) |
| Relational (comms) | Tess / A2A workflow | Follow-through engine detects commitment; cadence tracker detects staleness |
| Personal (overlay) | Crumb session-end hook | Overlay was active and operator confirms action items |
| Personal (manual) | Dashboard / Obsidian | Operator creates directly |

Single writer per item kind eliminates double-capture risk. The `/attention` aggregator reads from all locations but never writes — it's read-only.

### A4. Add dashboard self-monitoring

**Source:** DeepSeek #3 (must)

**Amendment:** Add to §8 (Technical Architecture):

- Health endpoint: `GET /api/health` returns JSON with API uptime, last successful data source read per adapter, and error count. Tess's mechanic adds this to the hourly pipeline monitoring check (extends TOP-011).
- Process management: Express server runs as a launchd service with auto-restart on crash. Service definition added during Phase 1 M1 (scaffolding).
- Error logging: API errors logged to `_system/logs/dashboard-api.log`. Rotation follows existing log conventions.

Add to §13 (Exclusions → amend): "The dashboard is a monitored service. Tess alerts if the health endpoint is unreachable for 2 consecutive checks."

Add SC-7 clarification: "If the dashboard goes down, Tess's existing Telegram channels continue to function. Tess alerts that the dashboard is unreachable."

### A5. Merge Intelligence and Feed Intelligence into a single page

**Source:** Gemini (should), DeepSeek #5 (should), ChatGPT #6 (should), Perplexity #7 (should)
**Consensus:** 3 of 4 explicitly recommended the merge. The fourth (ChatGPT) recommended testing both in mockups.

**Amendment:** Default to 6 pages. Merge Intelligence into Feed Intelligence as a combined "Intelligence" page with two sections:

- **Pipeline** section: daily signals, digest view, triage distribution, source breakdown, pipeline health, circuit breaker status, cost tracking, tuning panel. (Former Feed Intelligence page.)
- **Production** section: overnight research briefs, weekly intelligence brief, connections brainstorm, builder ecosystem radar, KB gardening findings. (Former Intelligence page.)

Tabbed or sectioned within the same page. Design phase must mock this merged layout and evaluate whether it works at the combined density. If mockups show the merged page is too dense, split back to two. Decision checkpoint at end of Phase 0.

Page count: 6 (Attention, Ops, Intelligence, Customer/Career, Agent Activity, Knowledge/Vault).

### A6. Sharpen design gate acceptance criteria

**Source:** DeepSeek #13 (obs), ChatGPT #8 (should), Perplexity #10 (should)
**Consensus:** 3 of 4 flagged "operator visually approves" as too subjective.

**Amendment:** Replace the Phase 0 gate criterion with a checklist:

1. All widget archetypes from §9.1 are represented in mockups
2. Typography matches taste profile (serif body, monospace data, sans-serif chrome)
3. Color palette is chosen (background, status colors, accent)
4. At least two pages fully mocked at real data density (not placeholder text)
5. Attention page can be scanned and "what needs me?" answered in <10 seconds
6. Ops page can answer "is the house on fire?" in <5 seconds
7. Pages respect 4-6 sections / 3-7 widgets per section guidance
8. Interactions are conventional (Jakob's Law) — navigation, filtering, drill-down use familiar patterns
9. Refresh/staleness states are designed (not deferred)
10. Mobile viewport tested for Attention and Ops — critical info readable without horizontal scroll

Gate passes when operator confirms all 10 items.

### A7. Clarify "read-first" principle

**Source:** ChatGPT #2 (must)

**Amendment:** Replace C4 with: "**Read-dominant, minimal writes for operator-owned primitives.** Phases 1-3 are read-dominant. The only write operations are: attention-item creation via quick-add (Phase 1), and attention-item status updates (Phase 2). All other write capabilities (feedback, approval, dispatch initiation) are Phase 4+ and must be thin facades over A2A-defined operations (see A8). This distinction affects security posture — write endpoints require input validation and vault-write safety checks that read endpoints do not."

### A8. Constrain Phase 4+ write endpoints to A2A facades

**Source:** Perplexity #3 (must), DeepSeek #4 (must), Gemini implicit

**Amendment:** Add to §8.5 (Future: Dashboard as Delivery Adapter):

"All write endpoints in Phase 4+ must be thin facades over A2A-defined operations, not independent logic. Specifically:
- `POST /approval/:id/approve` translates to an A2A approve call on the canonical AID record
- `POST /feedback` writes through to the existing feedback-ledger.yaml using A2A correlation IDs
- `POST /dispatch` creates a bridge inbox file conforming to the dispatch protocol schema

The dashboard never maintains independent state for approvals, feedback, or dispatches. It reads from and writes to the same canonical sources that Tess uses. This prevents duplicate state machines and ensures all actions flow through A2A's learning and audit layers."

### A9. Add customer-intelligence privacy constraints

**Source:** Perplexity #4 (must)

**Amendment:** Add to §6.5 (Customer/Career page):

"**Privacy constraints:**
- The dashboard reads customer-intelligence data only when running on the Mac Studio behind Cloudflare Access with authenticated session.
- No public route ever exposes customer-intelligence data. This is a hard constraint, not a default.
- API endpoints serving customer data must verify Cloudflare Access headers before responding.
- PII fields (personal contact details, private communications) are omitted from the web UI unless explicitly surfaced per-field. Default is to show: account name, engagement status, last touch date, dossier completeness score, and comms cadence — but not raw dossier content."

Add to §13 (Exclusions): "No public routes ever expose customer-intelligence data."

### A10. Systematically categorize panel data availability

**Source:** ChatGPT #5 (must)

**Amendment:** Add a new subsection to §6 (Page Architecture):

"**Panel data availability.** Each panel described in §6.1-6.7 falls into one of three categories:

- **Available now** — data source exists today and can be read by an API adapter
- **Derivable now** — data exists but requires light parsing, aggregation, or computation by the adapter
- **Blocked on upstream** — data source does not yet exist; depends on another project's completion

Panels in the 'blocked' category are placeholders in the UI showing 'Coming soon — requires [dependency]'. They do not masquerade as functional panels.

The PLAN phase will produce a per-panel availability matrix. The design phase must mock panels using real data density for 'available' and 'derivable' panels, and show the placeholder treatment for 'blocked' panels."

### A11. Add M-Web absorption kill-switch

**Source:** ChatGPT #4 (must)

**Amendment:** Add to §11 (Relationship to M-Web):

"**Decision rule:** If the merged dashboard cannot deliver the Feed Intelligence page to M-Web's core feature parity (digest display, signal rendering, pipeline health, feedback actions) by the end of Phase 1 M3, M-Web reverts to standalone development. The dashboard retains Ops and Attention pages; Feed Intelligence is built separately and linked from the nav. This prevents the umbrella project from silently delaying the narrower FIF web UI."

### A12. Specify Ops page data sources for system metrics

**Source:** Perplexity #8 (should)

**Amendment:** Add to §6.2 data sources:

"- **Mac Studio system metrics:** A lightweight periodic script (`_system/scripts/system-stats.sh`) runs via launchd every 60 seconds, dumping CPU load, memory usage, and disk utilization to a JSON file (`_system/logs/system-stats.json`). The API reads this file — it never shells out to system utilities per request.
- **launchd service status:** A companion script (`_system/scripts/service-status.sh`) runs on the same schedule, querying `launchctl list` for the defined service set and writing structured JSON to `_system/logs/service-status.json`."

### A13. Explicitly allow in-process caching

**Source:** Perplexity #5 (must), DeepSeek #7 (should)

**Amendment:** Tighten §8.3 language. Replace "No independent cache or shadow database" with:

"**Source-of-truth persistence.** The filesystem and SQLite databases are the only persistent stores. The API maintains no separate database. However, in-process memoization with short TTLs (5-10 seconds, aligned to refresh intervals) is permitted to avoid redundant filesystem reads within a single refresh cycle. This is in-memory cache that dies with the process — not a persistent shadow store."

### A14. Add React justification

**Source:** ChatGPT #7 (should)

**Amendment:** Add one paragraph to §8.1 under the stack listing:

"**Why React over simpler alternatives.** Server-rendered HTML (Express/EJS) or HTMX would reduce initial complexity but hit a ceiling at the interaction patterns this dashboard requires: live-updating status indicators, drill-down card expansion, filtered/sorted attention item lists, tabbed page sections, and progressive write capabilities (feedback buttons, approval actions, quick-add forms). These are component-state problems that React handles natively. The alternative — bolting client-side JS onto server-rendered pages piecemeal — creates the same complexity with worse tooling. React also provides the most transferable frontend skill for the operator's ongoing software engineering education. The complexity cost is real but justified by the interaction model."

### A15. Tighten mobile posture

**Source:** ChatGPT #11 (should), DeepSeek #9 (should), Perplexity #6 (should)

**Amendment:** Replace U6 with an explicit statement: "**Desktop is the primary target for Phases 0-3.** Mobile must be usable for triage on Attention and Ops — no horizontal scrolling, critical KPIs readable, action buttons tappable. Other pages degrade gracefully (single-column stack, reduced widget density). Feature parity on mobile is not a goal. Telegram remains the mobile-optimized interaction surface for urgent items."

Add to Phase 0 design gate checklist: "Mobile viewport tested for Attention and Ops — critical info readable without horizontal scroll" (included in A6 above).

### A16. Add performance budget rule

**Source:** ChatGPT #9 (should), DeepSeek #7 (should)

**Amendment:** Add to §8.3: "**Performance budget.** Direct filesystem reads are the default. If measured latency for any page exceeds 400ms (Doherty Threshold) at normal data volumes, introduce a lightweight derived index for the offending adapter. The threshold is measured, not assumed — don't pre-optimize. Log adapter response times during Phase 1 to establish baselines."

### A17. Define attention-item cleanup policy

**Source:** DeepSeek #8 (should)

**Amendment:** Add to §7.3: "**Archival policy.** Attention items in `done` or `dismissed` status for >30 days are moved to `Archived/attention/YYYY-MM/` by a periodic cleanup job (monthly, mechanic cron). Items in `deferred` status are not auto-archived — they remain active until explicitly resolved. The cleanup job logs what it archives for audit. Archived items are not indexed by the attention aggregator."

### A18. Clarify AKM feedback loop scope

**Source:** Perplexity #9 (should)

**Amendment:** Tighten SC-4: "AKM feedback data is visible on the Knowledge page — closing the write-only gap. At minimum, the Knowledge page shows: hit rate over rolling 10 sessions, most-surfaced sources, and never-surfaced sources (dead knowledge candidates). At least one actionable path exists from these insights: a 'review stale sources' link that creates an attention item prompting the operator to evaluate low-performing sources during their next Crumb session."

### A19. Specify search UX consistency

**Source:** Perplexity #11 (should)

**Amendment:** Add to §6 (Page Architecture), new subsection:

"**Search.** Global search lives in the nav shell header. It queries QMD across all four collections and surfaces results in a unified dropdown/overlay with collection badges, relevance scores, and snippets. The Knowledge page's search panel provides the same results with additional filtering (collection-specific views, date range, tag filters). Both share the same API endpoint (`GET /api/search?q=...`) and the same result card component. There is one search implementation, not two."

### A20. Post-Phase 1 retrospective gate

**Source:** Perplexity #13 (obs), ChatGPT #15 (obs — dependency blur)

**Amendment:** Add to §10 (Build Order), between Phase 1 and Phase 2:

"**Phase 1 retrospective (mandatory).** After Phase 1 deployment, pause for a 1-week usage period and retrospective before committing to Phase 2 scope. Questions to answer: Is the dashboard being used daily? Which pages get the most attention? Is the Attention-lite page providing enough value to justify full attention-item infrastructure in Phase 2? Would stopping here and iterating on Phase 1 pages be more valuable than adding new pages? This prevents the 'seven pages forever in progress' anti-pattern."

---

## Amendments: Decline

Findings acknowledged but not applied, with reasoning.

### D1. Replace Figma with CSS prototypes for Phase 0

**Source:** Gemini #1 (must), DeepSeek #10 (should), Perplexity #12 (should)

**Declined.** The design gate exists specifically to validate an untested aesthetic (Observatory mode) before committing to code. CSS prototypes are still code — they validate implementation feasibility, not aesthetic direction. The operator explicitly wants a visual design process via a design tool, and the spec should respect that decision rather than route around it.

**Partial concession:** Perplexity's recommendation to explicitly allow high-fidelity HTML/CSS as an acceptable substitute for Figma, as long as it covers Phase 0 deliverables, is reasonable. Added to A6 as a note: the design gate deliverables can be produced in Figma, HTML/CSS, or any tool that achieves the required fidelity. The gate is about the deliverables, not the tool.

### D2. A2A circular dependency is a blocker

**Source:** Gemini #3 (must)

**Declined.** The spec already explicitly decouples read (Phases 1-3) from A2A participation (Phase 4+). The dashboard reads raw state files from day one. There is no dependency deadlock. Amendment A8 further clarifies that Phase 4+ write endpoints are A2A facades, which addresses the coordination concern without treating it as a blocker.

### D3. Vault-native attention items will cause unsustainable clutter

**Source:** DeepSeek #8 (should)

**Partially declined.** At the expected volume (dozens of items per month, not thousands), vault clutter is manageable. The archival policy (A17) handles cleanup. The suggestion to use YAML/JSONL instead of individual files would lose Obsidian editability, which is a core design principle. The dual-index suggestion (markdown + SQLite) is noted as a future optimization if volume becomes a problem — not a launch requirement.

### D4. Caching is needed at launch for performance

**Source:** DeepSeek #7 (should), Perplexity #5 (must)

**Partially declined as a must-fix.** At current vault scale (~1,400 files, single SSD Mac Studio), filesystem reads will be well under 400ms. In-process memoization is explicitly allowed (A13), and a measured performance budget is added (A16). Pre-optimizing with a SQLite index before measuring actual latency would violate the ceremony budget principle. The threshold-based rule ensures performance is addressed when — and only when — it becomes a problem.

### D5. Customer/Career page should split into two pages

**Source:** ChatGPT #10 (should)

**Declined for now.** The recommendation to keep them merged but define a split condition is already the spec's implicit approach. Adding a formal split condition ("if reviewed on different cadences, split") is useful but belongs in PLAN, not SPECIFY. The design phase will test whether the combined page is cognitively coherent. No spec change needed — this is already covered by the page count flexibility in A5.

---

## Findings Not Addressed by Any Reviewer

The meta-review identified several gaps that no reviewer caught:

1. **Session estimate realism.** No reviewer challenged whether 22-36 sessions is achievable for someone learning frontend development. This remains an unvalidated assumption.
2. **The MVP question.** No reviewer asked whether a single well-designed overview page with drill-down modals could deliver 80% of the value at 20% of the effort, versus 6 separate pages. The Phase 1 retrospective (A20) partially addresses this.
3. **Success criteria measurability.** SC-1 ("opens dashboard instead of Telegram") and SC-3 ("prefers Feed Intelligence page") are habit-adoption metrics, not system-quality metrics (ChatGPT #16 flagged this as observation only). These should be supplemented with objective measures in PLAN.
4. **Testing strategy.** DeepSeek #16 noted "per-phase test coverage" is hand-wavy. Minimum bar: unit tests for API adapters, integration tests for key endpoints. Defer to PLAN for specific coverage targets.

---

## Summary of Changes

| # | Amendment | Source | Severity |
|---|-----------|--------|----------|
| A1 | Attention-lite in Phase 1 | ChatGPT, DeepSeek, Gemini | Must-fix (build order) |
| A2 | Harden attention-item schema | All 4 reviewers | Must-fix (data contract) |
| A3 | Capture ownership model | Perplexity, ChatGPT, DeepSeek | Must-fix (data contract) |
| A4 | Dashboard self-monitoring | DeepSeek | Must-fix (operability) |
| A5 | Merge to 6 pages | 3 of 4 reviewers | Should-fix (architecture) |
| A6 | Design gate checklist | DeepSeek, ChatGPT, Perplexity | Should-fix (process) |
| A7 | Tighten read-first principle | ChatGPT | Must-fix (scoping) |
| A8 | Phase 4+ writes are A2A facades | Perplexity, DeepSeek | Must-fix (architecture) |
| A9 | Customer-intelligence privacy | Perplexity | Must-fix (security) |
| A10 | Panel data availability matrix | ChatGPT | Must-fix (honesty) |
| A11 | M-Web absorption kill-switch | ChatGPT | Must-fix (risk) |
| A12 | Ops page data source scripts | Perplexity | Should-fix (completeness) |
| A13 | Allow in-process caching | Perplexity, DeepSeek | Should-fix (clarity) |
| A14 | React justification | ChatGPT | Should-fix (clarity) |
| A15 | Tighten mobile posture | ChatGPT, DeepSeek, Perplexity | Should-fix (clarity) |
| A16 | Performance budget rule | ChatGPT, DeepSeek | Should-fix (operability) |
| A17 | Attention-item cleanup policy | DeepSeek | Should-fix (maintenance) |
| A18 | AKM feedback loop scope | Perplexity | Should-fix (clarity) |
| A19 | Search UX consistency | Perplexity | Should-fix (architecture) |
| A20 | Post-Phase 1 retrospective | Perplexity, ChatGPT | Should-fix (process) |

**Total: 20 amendments accepted (10 must-fix, 10 should-fix). 5 declined with reasoning. 4 meta-review gaps noted.**
