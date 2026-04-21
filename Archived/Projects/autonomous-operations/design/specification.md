---
type: specification
status: active
created: 2026-03-12
updated: 2026-03-12
skill_origin: systems-analyst
domain: software
project: autonomous-operations
phase_scope: "Phase 1"
---

# Autonomous Operations — Phase 1 Specification

## Problem Statement

The attention-manager skill produces daily artifacts that rank attention items, but those items lack structured metadata (action classification, object identity, freshness), are not logged for replay, and cannot be scored for quality. Without structured logging and a proxy scoring signal, the system cannot measure whether it surfaces the right things — making any future optimization speculative rather than evidence-based.

Phase 1 extends the existing daily-attention infrastructure to produce structured, replay-logged attention items with deduplication and a computable quality signal. It does not replace what works — it instruments it.

## Facts

- F1: daily-attention.sh runs at 6:30 AM via LaunchAgent, direct Anthropic API, ~$0.19/run, in soak since Mar 8
- F2: Daily artifacts use the schema in SKILL.md (Focus items with Why now, Domain, Source, Goal fields)
- F3: dashboard_actions SQLite table exists in mission-control as an implementation template
- F4: Vault has ~1,400 files; file renames are infrequent
- F5: MC-067 (daily attention dashboard panel) is a registered downstream consumer of the daily artifact
- F6: The attention-manager skill (AM-001 through AM-006) is complete and in 30-day soak through ~Apr 8
- F7: cron-lib.sh provides shared infrastructure for cron scripts (init, cost tracking, alerting)

## Assumptions

- A1: Bash pre/post processing around the existing API call can handle dedup context injection, item parsing, and SQLite logging without needing Claude Code tool access
- A2: The daily-attention.sh prompt can be extended to produce action_class on each item without degrading output quality or exceeding 4000 max_tokens
- A3: Git diff correlation is a reliable-enough proxy for "operator acted on this item" at current vault activity levels
- A4: Path-based object identity is sufficient at current vault scale; rename frequency is low enough for manual alias maintenance
- A5: SQLite schema additive changes (ALTER TABLE) will accommodate Phase 2 task registry needs without migration

**Validation plan:** A1 validated by AO-002 soak (prompt produces parseable structured output). A2 validated by comparing artifact quality pre/post change. A3 validated by AO-004 output review (operator spot-checks correlation accuracy over 2 weeks). A4 monitored via alias table growth rate. A5 is a design constraint, not empirically testable in Phase 1.

## Unknowns

- U1: False-positive rate of vault-change correlation (will be learned during operation)
- U2: Whether daily cadence surfaces high-priority events fast enough, or sub-daily cycles needed earlier than expected
- U3: Optimal dedup window size (how many days of history to check before declaring an item "new")
- U4: Whether structured JSON extraction from markdown API output is reliable enough or requires a separate structured output pass

## System Map

### Components

```
┌─────────────────────────────────────────────────────────┐
│  daily-attention.sh (MODIFIED)                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │ Pre-proc │→ │ API call │→ │ Post-proc            │  │
│  │ (dedup,  │  │ (Opus,   │  │ (parse items, write  │  │
│  │  context)│  │  prompt+) │  │  artifact + log)     │  │
│  └──────────┘  └──────────┘  └──────────────────────┘  │
└──────────────┬──────────────────────────┬───────────────┘
               │                          │
               ▼                          ▼
┌──────────────────────┐   ┌──────────────────────────┐
│ _system/daily/       │   │ attention-replay.db       │
│ YYYY-MM-DD.md        │   │ (SQLite)                  │
│ (daily artifact)     │   │ cycles, items,            │
└──────────────────────┘   │ operator_actions, aliases  │
                           └─────────────┬────────────┘
                                         │
                           ┌─────────────▼────────────┐
                           │ attention-correlate.sh    │
                           │ (NEW — separate cron)     │
                           │ git diff ↔ surfaced items │
                           │ writes operator_actions   │
                           └─────────────┬────────────┘
                                         │
                           ┌─────────────▼────────────┐
                           │ attention-score.sh        │
                           │ (NEW — manual/on-demand)  │
                           │ computes proxy metrics    │
                           │ evaluates exit criteria   │
                           └──────────────────────────┘
```

### Dependencies

- **Upstream:** Anthropic API (model availability), vault files (goal-tracker, SE inventory, project states), git history (for correlation)
- **Downstream:** MC-067 dashboard panel (reads daily artifact — additive schema change, non-breaking), Tess morning briefing (reads daily artifact)
- **Sibling:** attention-manager soak (G1, ~Apr 8) — Phase 1 build proceeds in parallel; the cron script is the shared artifact

### Constraints

- C1: Bash + direct API architecture — no migration to Claude Code skill-based approach in Phase 1
- C2: Path-based object identity with explicit rename alias tracking
- C3: Zero-ceremony operator action tracking (vault-change correlation only)
- C4: Daily artifact in Obsidian remains the sole review surface
- C5: Phase 1 budget: 5-8 items per daily cycle, top-5 get context metadata
- C6: No safe-action execution, no dispatch — only `surface_only` and `prepare_only` action classes active

### Levers

- **Prompt engineering:** action_class accuracy depends on prompt quality; this is the highest-leverage tuning surface
- **Dedup window:** controls false-positive vs. missed-signal tradeoff
- **Correlation window:** 48h (operational) / 7d (developmental) determines scoring sensitivity
- **SQLite schema:** Phase 2 extensibility depends on getting the identity model right now

### Second-Order Effects

- Structured items enable Phase 2 task registry to consume attention output as input
- Replay log becomes the foundation for Phase 7 autotune
- Path-based identity means Phase 2+ may need UUID migration (known, accepted)
- Vault-change correlation creates a soft dependency on regular git commits — if the operator doesn't commit for days, correlation goes blind
- action_class in the artifact changes what MC-067 can display (routing indicators, prep status)

### Architectural Boundary

Crumb/Tess is the **meta-layer** — attention allocation across domains and (future) products, cross-context knowledge, strategic brain. Future products get their own dead-simple throughput loops (repo, task registry, error pipeline, "ship faster" objective). The meta-layer does not try to be the product's operating system. It decides which product deserves attention today and hands the operator a context pack. This spec builds the meta-layer's instrumentation, not a product-level system.

## Domain Classification & Workflow

- **Domain:** software (system — vault-only, no external repo)
- **Workflow:** SPECIFY → PLAN → TASK → IMPLEMENT (full four-phase)
- **Rationale:** Multiple interacting components (prompt changes, SQLite schema, correlation engine, scoring), exit criteria requiring operational validation, and foundational schema decisions that affect future phases

## Task Decomposition

### AO-001: Replay Log Schema + Infrastructure
`#code` | Risk: **low** | Depends on: nothing

Create the SQLite database and helper functions for attention cycle logging.

**Deliverables:**
- `_openclaw/data/attention-replay.db` schema (via init script)
- SQLite tables: `cycles` (cycle_id, timestamp, sources_scanned, item_count), `items` (item_id, cycle_id, object_id, title, domain, action_class, priority_rank, context_fields JSON), `operator_actions` (action_id, item_id, action_type, detected_at, detection_method, notes), `aliases` (old_path, new_path, created_at)
- Bash helper functions in `_openclaw/scripts/attention-lib.sh` (init_db, log_cycle, log_item, log_action, add_alias, resolve_id)
- Schema versioning via `PRAGMA user_version`

**Acceptance criteria:**
- [ ] Database initializes cleanly on first run
- [ ] Helper functions can insert and query all four tables
- [ ] Schema version tracked; future ALTER TABLE changes increment version
- [ ] Idempotent init (re-running doesn't destroy existing data)

**File changes:** ≤3 (init script, attention-lib.sh, schema SQL reference)

---

### AO-002: Attention Item Schema + action_class
`#code` | Risk: **medium** | Depends on: nothing (can parallel with AO-001)

Extend daily-attention.sh prompt to produce attention items with action_class and structured metadata. Add post-processing to parse items into a machine-readable format alongside the markdown artifact.

**Deliverables:**
- Updated prompt in daily-attention.sh requesting action_class per item (`surface_only` or `prepare_only` for Phase 1)
- Post-processing block that extracts structured item data from the API response (regex or structured markers in prompt output)
- Sidecar JSON file (`_system/daily/YYYY-MM-DD.json`) with parsed items for downstream consumption
- Updated artifact format: each Focus item includes `Action: surface_only|prepare_only` field

**Acceptance criteria:**
- [ ] Every Focus item in the daily artifact has an action_class field
- [ ] Sidecar JSON contains all items with: object_id (path-based), title, domain, action_class, priority_rank, source_path, source_mtime
- [ ] Artifact quality does not degrade (spot-check: compare 3 days pre/post)
- [ ] API response stays within 4000 max_tokens

**File changes:** ≤3 (daily-attention.sh prompt + post-processing, validation notes)

---

### AO-003: Object Identity + Deduplication
`#code` | Risk: **medium** | Depends on: AO-002 (needs structured items with identity)

Implement path-based object identity and dedup pre-processing.

**Deliverables:**
- Identity derivation: `object_id = lowercase(source_path)` — normalized, deterministic
- Alias table in SQLite (via AO-001 schema): maps old_path → new_path for renames
- `resolve_id()` function: given a path, check alias table, return canonical path
- Dedup pre-processing in daily-attention.sh: query last N cycles (default: 3) for surfaced object_ids, inject as "recently surfaced" context in the API prompt so the model can aggregate rather than duplicate
- Dedup validation in post-processing: flag if any two items in the same cycle share an object_id after alias resolution

**Acceptance criteria:**
- [ ] Zero duplicate items for the same object in the same cycle (post-processing catches any model-side duplicates)
- [ ] Alias table can be updated manually (`attention-lib.sh add_alias old new`)
- [ ] Dedup context injection does not exceed prompt token budget (monitor input_tokens)
- [ ] Items surfaced on consecutive days for the same object show rising urgency, not duplication

**File changes:** ≤4 (daily-attention.sh pre-processing, attention-lib.sh dedup functions, prompt additions, alias management)

---

### AO-004: Vault-Change Correlation Engine
`#code` | Risk: **medium** | Depends on: AO-001 (SQLite), AO-002 (structured items logged)

Build a correlation script that infers operator actions from vault changes.

**Deliverables:**
- `_openclaw/scripts/attention-correlate.sh` — runs on demand or via cron (suggested: daily at 11 PM, after the day's work)
- For each surfaced item in the scoring window:
  - Extract object_id (source path)
  - Check `git log --since=<cycle_time> --until=<window_end> -- <source_path>` for changes
  - If changed: record `acted_on` with detection_method=`vault_change_correlation`
  - If not changed and window expired: record `not_acted_on`
  - Domain-aware windows: 48h for operational domains (software, career-tactical), 7d for developmental domains (health, relationships, creative, spiritual, career-strategic)
- Domain classification derived from the item's `domain` field in SQLite

**Acceptance criteria:**
- [ ] Correlation script processes all items from the last 7 days in under 30 seconds
- [ ] Correctly identifies acted-on items (spot-check against 1 week of manual review)
- [ ] Domain-aware windows applied (operational items scored at 48h, developmental at 7d)
- [ ] Results written to operator_actions table with timestamps and method

**File changes:** ≤2 (attention-correlate.sh, optional LaunchAgent plist)

---

### AO-005: Proxy Scoring + Exit Criteria Evaluation
`#code` `#research` | Risk: **low** | Depends on: AO-004 (needs correlation data)

Define operational metrics and build evaluation queries.

**Deliverables:**
- `_openclaw/scripts/attention-score.sh` — computes Phase 1 exit metrics from SQLite
- Metrics computed:
  - **Acted-on rate:** % of surfaced items with `acted_on` action within window (quality proxy)
  - **False-positive rate:** % of surfaced items with `not_acted_on` (target: <40%)
  - **Dedup compliance:** % of cycles with zero same-object duplicates (target: 100%)
  - **Context coverage:** % of top-5 items with non-null context fields in sidecar JSON (target: ≥80%)
  - **Replay completeness:** % of cycles with complete log entries (target: 100%)
- Output: structured summary to stdout + optional append to `_system/logs/attention-metrics.jsonl`
- Operational definitions documented in script comments (what counts as "action," measurement method, aggregation window)

**Acceptance criteria:**
- [ ] All five Phase 1 exit metrics computable from SQLite data
- [ ] Scoring script runs in under 10 seconds
- [ ] Output format suitable for inclusion in monthly review artifact
- [ ] Operational definitions match vision doc §10 exit criteria (formal alignment check)

**File changes:** ≤2 (attention-score.sh, metrics log)

---

### Dependency Graph

```
AO-001 (schema)  ──┐
                    ├──→ AO-004 (correlation) ──→ AO-005 (scoring)
AO-002 (items)  ───┤
       │            │
       └──→ AO-003 (dedup)
```

AO-001 and AO-002 can proceed in parallel. AO-003 follows AO-002. AO-004 follows both AO-001 and AO-002. AO-005 follows AO-004.

## Exit Criteria (Phase 1)

Per vision doc §10, with operational definitions:

| Criterion | Target | Measurement | Aggregation |
|-----------|--------|-------------|-------------|
| Top-5 items have context metadata | ≥80% | Non-null context fields in sidecar JSON | Rolling 7-day average |
| False-positive rate | <40% | Items surfaced → not_acted_on within window | Rolling 14-day average |
| Replay log completeness | 100% | Cycles with complete SQLite entries | Cumulative since AO-001 deploy |
| Zero same-object duplicates | 0 per cycle | Post-processing dedup check | Every cycle |
| Decisions logged in replay-ready format | 100% | MVL scope: inputs, outputs, operator_actions | Cumulative since AO-004 deploy |

**Evaluation window:** Minimum 14 days of operation with all five tasks deployed before Phase 1 exit evaluation. Phase 1 exit is a gate evaluation (see `_system/docs/solutions/gate-evaluation-pattern.md`): criteria defined now, autonomous period runs, structured evaluation at the end.

**Note:** "Median time from event to prepared item ≤ 4 hours" (vision doc) is not measurable in Phase 1's daily cadence — events are processed once per day at 6:30 AM. This criterion defers to Phase 2+ when sub-daily cycles become feasible.

## What Phase 1 Does NOT Build

Explicitly out of scope (documented for clarity, not ambiguity):

- **Task registry** — Phase 2
- **Safe-action execution** — Phase 3
- **Dispatch envelopes** — Phase 4
- **Sub-daily attention cycles** — future, gated on daily cadence proving insufficient
- **Context-pack versioning** — Phase 2 (when task registry exists to consume versioned packs)
- **Typed failure codes / missing-context markers** — Phase 2 learning loop
- **Explicit operator input for action tracking** — Phase 2 "done_no_task" affordance
- **UUID-based object identity** — future migration if path-based proves insufficient
- **New review surfaces** — MC-067 dashboard panel reads the artifact; no new UI
