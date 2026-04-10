---
project: attention-manager
domain: software
type: specification
skill_origin: systems-analyst
created: 2026-03-06
updated: 2026-03-06
tags:
  - attention-management
  - system-design
---

# Attention Manager — Specification

## 1. Problem Statement

Danny's attention is fragmented across competing demand streams — customer engagements, SE management obligations, Crumb development, learning, family, spiritual practice — with no unified mechanism for deciding what gets focus on any given day. There is no existing morning ritual, no goal-setting practice, and no consolidated view of obligations. SE management tasks live in a mix of calendar, memory, and ad-hoc notes. The result is reactive days where urgency wins over importance and slow-burn priorities get crowded out.

This system makes the governing principle operational: "I run the 24 hours. The 24 hours doesn't run me."

## 2. Facts, Assumptions, and Unknowns

### Facts

- F1. No existing morning planning ritual — this creates a new habit, not digitizes an existing one.
- F2. No existing goal-setting practice — the goal-tracking artifact builds a practice from scratch.
- F3. SE management tasks are scattered across calendar, memory, and informal notes — the vault becomes the consolidated source of truth.
- F4. ~25 active Infoblox accounts with varying engagement levels, tracked by the customer-intelligence project.
- F5. Active Crumb projects have structured next-actions in run-logs and project-state.yaml.
- F6. The Life Coach overlay and personal-philosophy.md provide the philosophical grounding for prioritization decisions.
- F7. Delivery will be via a planned web UI (FIF/tess-operations workstream), not Telegram morning briefing. Tess delivery is a separate, independent workstream.
- F8. The Ceremony Budget Principle is the primary design constraint — if maintaining this system feels like overhead, it will be abandoned.

### Assumptions

- A1. A curated daily list of 5-8 items is more useful than a comprehensive task dump. (Validate: first week of use.)
- A2. Monthly goal check-ins are sufficient cadence for goal alignment — weekly review is deferrable. (Validate: after first month.)
- A3. Customer-intelligence dossiers will contain machine-readable action items by the time this system is operational. (Validate: check current dossier structure.)
- A4. The operator will engage with the daily artifact at least 4 days per week for the system to provide value. (Validate: usage tracking in first month.)
- A5. A single vault-resident goal-tracking file with lightweight YAML structure is sufficient — no need for a goal management tool or database. (Validate: ceremony budget assessment after first month.)

### Unknowns

- U1. What is the right number of items on a daily list? The input spec suggests "curated short list" — need to calibrate through use.
- U2. How granular should SE management tasks be? Run inspects have a different cadence than NPI trainings than admin tasks. Need to find the right level of structure that's maintainable.
- U3. How will carry-forward items interact with goal-tracking? If an item rolls for 5+ days, does that signal a goal misalignment or just a bad week?

## 3. System Map

### Components

```
┌─────────────────────────────────────────────────────────┐
│                    INPUT SOURCES                         │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ goal-tracker │  │ se-management│  │ project-state│  │
│  │   (new)      │  │  inventory   │  │  + run-logs  │  │
│  │              │  │   (new)      │  │  (existing)  │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │           │
│  ┌──────┴───────┐  ┌──────┴───────┐                    │
│  │ personal-    │  │ customer-    │                    │
│  │ context.md   │  │ intelligence │                    │
│  │ (existing)   │  │ dossiers     │                    │
│  └──────┬───────┘  └──────┬───────┘                    │
└─────────┼─────────────────┼─────────────────────────────┘
          │                 │
          ▼                 ▼
┌─────────────────────────────────────────────────────────┐
│              ATTENTION-MANAGER SKILL                     │
│                                                         │
│  1. Read input sources                                  │
│  2. Read yesterday's artifact (carry-forward)           │
│  3. Apply prioritization (Life Coach + Career Coach)    │
│  4. Curate daily list                                   │
│  5. Write daily attention artifact                      │
│                                                         │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   OUTPUT ARTIFACTS                       │
│                                                         │
│  ┌──────────────────┐  ┌──────────────────┐            │
│  │ daily attention  │  │ monthly review   │            │
│  │ _system/daily/   │  │ _system/daily/   │            │
│  │ YYYY-MM-DD.md    │  │ review-YYYY-MM.md│            │
│  └──────────────────┘  └──────────────────┘            │
│                                                         │
│  Consumed by: operator (vault), web UI (future)        │
└─────────────────────────────────────────────────────────┘
```

### Dependencies

**This depends on:**
- customer-intelligence project — dossier structure and action item format
- personal-context.md — strategic priorities
- Life Coach + Career Coach overlays — prioritization lens
- Active project run-logs — next-action items

**What depends on this:**
- Future web UI (tess-operations/FIF) — reads the daily artifact for display
- Tess morning briefing (future, independent) — reads same artifact

### Constraints

- C1. **Ceremony budget:** Total daily overhead for the operator must be under 5 minutes. Curation is Crumb's job; the operator reviews, adjusts, and goes.
- C2. **No new infrastructure:** Vault notes, Crumb skill, existing scripts. No databases, no external services, no new tooling.
- C3. **Vault-resident:** All artifacts must be readable by Tess and the planned web UI — standard markdown with YAML frontmatter.
- C4. **Graceful degradation:** If a source is unavailable (no dossiers yet, empty run-logs), the skill produces a useful artifact from whatever IS available. No hard dependencies on perfect input data. Specifically: if customer-intelligence dossiers lack structured action items, the skill proceeds without career-engagement items and notes the gap in the Domain Balance section.
- C5. **Human override:** The daily artifact is a proposal, not a contract. Operator edits are authoritative and must not break carry-forward mechanics.
- C6. **Write-read path awareness:** The current verified read path is operator-in-vault only. Two stated consumers (web UI, Tess briefing) are future and independent. The daily artifact schema should be treated as provisional until a second consumer validates it — avoid over-specifying fields that only the operator reads today.
- C7. **Calendar out of scope:** The operator's calendar is not an input source. Calendar integration would require new tooling (violates C2). The operator's calendar review is part of the <5 min artifact review time — the daily artifact complements the calendar, it doesn't replace it. If AM-004 reveals that calendar conflicts make the artifact regularly unhelpful, calendar integration should be revisited as a future enhancement.

### Levers

- L1. **Goal-tracking ceremony level:** The less structure required, the more likely it gets maintained. A flat list of 3-5 monthly goals with status markers may be enough.
- L2. **Curation aggressiveness:** How many items make the daily list determines usefulness. Too few = misses things. Too many = becomes a task dump.
- L3. **Carry-forward escalation:** How many days an item rolls before the system flags it changes the signal-to-noise ratio of the daily view.

### Second-Order Effects

- Building a goal-tracking practice may surface goal conflicts that are currently invisible (e.g., Crumb development vs. customer engagement time).
- Consolidating SE management tasks into the vault creates a single source of truth but also creates a maintenance obligation — the inventory must stay current.
- The daily artifact becomes a behavioral record over time — monthly reviews can analyze patterns in what gets done vs. deferred.

## 4. Prerequisite Artifacts

These must exist before the attention-manager skill can function. They are part of this project's deliverables, not external dependencies.

### 4.1 Goal Tracker

**Location:** `_system/docs/goal-tracker.yaml`

**Rationale:** YAML, not markdown, because this is machine-read by the skill and human-edited directly. YAML is the lightest structured format that's both. A markdown note with YAML frontmatter adds ceremony (heading structure, prose sections) that serves no purpose for a file that's fundamentally a structured data store.

**Schema:**

```yaml
# Goal Tracker — updated by operator, read by attention-manager skill.
# Review cadence: monthly (first of month).
# Keep this short. 3-5 active goals max. If you have more, you don't have priorities.

updated: 2026-03-06

goals:
  - id: G1
    domain: software
    description: "Ship attention-manager and use it daily for 30 days"
    horizon: monthly        # monthly | quarterly
    target_date: 2026-04-06
    status: active          # active | paused | done
    progress: ""            # free-text, updated by operator

  - id: G2
    domain: career
    description: "Complete Q1 customer engagement plans for top 10 accounts"
    horizon: quarterly
    target_date: 2026-03-31
    status: active
    progress: ""
```

**Design decisions:**
- No nested milestones — that's action-architect territory. Goals here are directional, not decomposed.
- `horizon` distinguishes monthly focus items from quarterly commitments. No annual goals — too abstract to drive daily attention.
- `progress` is free-text, not a percentage. Percentages create false precision and ceremony.
- Hard cap: 3-5 active goals. The file header says it. The skill should warn if more than 5 are active.

### 4.2 SE Management Inventory

**Location:** `Domains/Career/se-management-inventory.md`

**Rationale:** Markdown note in the Career domain — this is a standing reference document, not a data store. It's manually maintained and read by both the operator and the skill.

**Schema:**

```yaml
---
project: null
domain: career
type: reference
skill_origin: null
status: active
created: 2026-03-06
updated: 2026-03-06
tags:
  - se-management
  - career
---
```

**Body structure:**

```markdown
# SE Management Inventory

Standing list of SE obligations. This is a static reference doc — only update when responsibilities change. The attention-manager skill infers what's "due" by checking cadence annotations against when each item last appeared as completed in daily attention artifacts.

## Recurring

- Run inspects — [cadence: weekly/biweekly, day: TBD by operator]
- Expense reports — [cadence: monthly, deadline: last business day]
- Time tracking — [cadence: weekly, deadline: Friday]

## Periodic

- NPI trainings — [cadence: as announced, typical lead time: 2 weeks]
- Certification renewals — [next: TBD]

## Ad-hoc

Items added and removed as they arise. These are manager-requested deliverables, one-off admin tasks, etc.

- (empty — add as needed)
```

**Design decisions:**
- No checkboxes, no state fields. The inventory is a static reference doc listing obligations with cadence annotations. State lives in the daily artifacts (completed Focus items), not in the inventory.
- Three categories (recurring, periodic, ad-hoc) match the natural rhythm without over-structuring.
- Cadence annotations are inline, not in a separate metadata block — readable by humans, parseable by the skill.
- The skill determines "is this due?" by: (1) reading the cadence annotation, (2) scanning recent daily artifacts for when this item last appeared as a completed Focus item, (3) computing whether enough time has elapsed since last completion. This eliminates all checkbox reset ceremony.
- Cadence-based surfacing is best-effort for non-standard cadences (e.g., "as announced"). The skill can reliably compute due dates for standard cadences (weekly, biweekly, monthly) but treats ad-hoc and event-driven items as always-eligible for surfacing. This is by design — the skill is an LLM reading structured text, not a scheduler.

## 5. Daily Attention Artifact

### 5.1 Location and Naming

**Directory:** `_system/daily/`
**Filename:** `YYYY-MM-DD.md` (e.g., `2026-03-06.md`)
**Retention:** 90 days. Files older than 90 days can be pruned (not archived — the monthly review captures the durable signal).

### 5.2 Type Registration

Two new types added to the type taxonomy:

| Type | Used For |
|---|---|
| `daily-attention` | Daily curated attention plan, produced by attention-manager skill |
| `attention-review` | Monthly attention review/synthesis, produced by attention-manager skill |

### 5.3 Schema

```yaml
---
type: daily-attention
status: active
created: 2026-03-06
updated: 2026-03-06
skill_origin: attention-manager
---
```

Note: Per-item carry-forward counts appear in the body (Carry-Forward section), not in frontmatter. A per-artifact count would be lower fidelity than per-item tracking and redundant.

### 5.4 Body Structure

```markdown
# Daily Attention — YYYY-MM-DD

## Focus (5-8 items)

Curated list. Each item is a checkbox for clear done/not-done signaling (carry-forward reads checkbox state).

- [ ] **[Item description]**
  - Why now: [reasoning]
  - Domain: career | software | learning | ...
  - Source: [[link to source artifact]]
  - Goal: G1 *(optional — links to goal-tracker entry)*

- [ ] **[Item 2]**
  - ...

## Domain Balance

Brief assessment using the 8-domain taxonomy (software, career, learning, health, financial, relationships, creative, spiritual). "Work" = `{career, software}`. Balance check: flag if work items are >60% of Focus items today AND yesterday. Domains without input sources (health, relationships, creative, spiritual) can only surface through goal-tracker entries — the balance check should distinguish "no input source exists" from "input exists but was deprioritized."

## Carry-Forward

Items rolled from yesterday. Each shows days carried.

- [Item] — carried N days (originally [date])

## Deferred

Items considered and explicitly not included today, with reasoning.

- [Item] — deferred because [reason]

## Goal Alignment

Which active goals (from goal-tracker.yaml) does today's list advance? Which goals have no representation today? This is informational, not prescriptive — not every goal needs daily representation.
```

### 5.5 Carry-Forward Mechanics

1. At curation time, the skill finds the most recent daily artifact within the last 3 days.
2. Items in that artifact's Focus section that are NOT checked off (`- [ ]`) are carried forward.
3. Carried items increment their carry counter (days since originally added, not days since last artifact).
4. Items carried 5+ days are flagged with an escalation note: "This has been deferred for N days. Is it still a priority, or should it be dropped/rescheduled?"
5. The operator can mark items done by checking the checkbox (`- [x]`) or deleting the item. Both are recognized.
6. If no artifact exists within the last 3 days, the skill produces a fresh list. This is expected after vacations or extended gaps — the skill re-reads all input sources and curates from scratch.

## 6. Monthly Review Artifact

**Location:** `_system/daily/review-YYYY-MM.md`
**Type:** `attention-review` (distinct from `daily-attention` — different document shape requires separate type for validation and consumer routing)
**Cadence:** First session of each month, or on-demand ("monthly review").

**Content:**
- Attention allocation summary: which domains got focus, which were neglected
- Carry-forward patterns: items that kept rolling — what does that signal?
- Goal progress check: update goal-tracker.yaml status/progress fields
- Pattern observations: any recurring theme (e.g., "SE admin consistently crowds out learning")
- Adjustments: proposed changes to goal-tracker or SE inventory based on the month's data

This is a synthesis artifact produced by the skill, not a raw aggregation. The skill reads the month's daily artifacts and applies Life Coach + Career Coach lens questions to produce an opinionated assessment.

## 7. Attention-Manager Skill

### 7.1 Skill Identity

**Location:** `.claude/skills/attention-manager/SKILL.md`
**Trigger:** "plan my day", "daily attention", "what should I focus on", "monthly review"
**Model tier:** reasoning (requires cross-domain judgment, overlay application, philosophical grounding)

### 7.2 Context Contract

**MUST load:**
- `_system/docs/goal-tracker.yaml` — active goals
- `Domains/Career/se-management-inventory.md` — SE obligations
- `_system/docs/personal-context.md` — strategic priorities
- Yesterday's daily artifact (if exists) — carry-forward source

**MUST load (overlays):**
- `_system/docs/overlays/life-coach.md` + `Domains/Spiritual/personal-philosophy.md`
- `_system/docs/overlays/career-coach.md`

**MAY load (conditional):**
- Customer-intelligence dossiers — when career domain items need specificity

**Mechanical scan (not counted against context budget):**
- Active project `project-state.yaml` files — lightweight scan to extract `next_action` fields only. These are small YAML files (~10 lines each); the skill reads them for data extraction, not reasoning. Scoped to `Projects/*/` only (excludes `Archived/`).

**Budget:** Standard tier (5 docs) for daily curation — MUST-load items are: goal-tracker, SE inventory, personal-context, most recent daily artifact (carry-forward). Overlays are exempt per vault conventions. Extended tier (7-8 docs) for monthly review — requires a pre-processing step: aggregate daily artifacts into a structured summary digest before the skill loads it, since loading 15-20 individual daily artifacts exceeds any reasonable budget.

### 7.3 Procedure (Daily)

1. Load context contract (goal-tracker, SE inventory, personal-context, most recent daily artifact within 3 days).
2. Scan active projects: read `Projects/*/project-state.yaml` files (excluding `Archived/`), extract `next_action` where not null. This is a mechanical data scan, not a context-loading step.
3. Scan SE inventory: identify items approaching cadence deadlines by checking cadence annotations against when each item last appeared as a completed Focus item in recent daily artifacts.
4. Scan goal-tracker: identify active goals and assess which have had recent representation in daily artifacts. If `updated` field is >45 days old, flag staleness in the daily artifact.
5. Process carry-forward from most recent daily artifact (if found within 3 days). If no recent artifact exists, produce a fresh list and note the gap.
6. Apply prioritization through Life Coach lens (values alignment, whole-person impact, sustainability, "enough" test) and Career Coach lens (skill leverage, reputation signal, opportunity cost). Priority resolution heuristic: non-negotiable commitments (family, health, hard deadlines) always make the list. Among discretionary items, bias toward items with external visibility or time decay over items with only internal accountability.
7. Curate the daily list: select 5-8 items that represent the best use of today's attention. Apply domain balance check. Add optional `Goal: GN` references to items that advance active goals.
8. Write the daily artifact to `_system/daily/YYYY-MM-DD.md`.
9. Present the artifact to the operator for review and adjustment.

### 7.4 Procedure (Monthly Review)

1. Pre-process: aggregate all daily artifacts for the month (`_system/daily/YYYY-MM-*.md`) into a structured summary — domain counts, carry-forward patterns, goal references, completion rates. This avoids loading 15-20 individual files into context.
2. Load the monthly digest, goal-tracker.yaml, and SE inventory.
3. Analyze: domain distribution, carry-forward patterns, goal representation frequency, SE obligation coverage.
4. Apply Life Coach lens: is the month's pattern aligned with stated values? What's the whole-person cost of the observed allocation?
5. Apply Career Coach lens: is professional development getting appropriate attention? Are relationship investments happening?
6. Write the monthly review artifact to `_system/daily/review-YYYY-MM.md` with `type: attention-review`.
7. Propose goal-tracker updates (status changes, new goals, retirements). If goal-tracker is sparsely populated, propose initial goals derived from observed attention patterns.
8. Present to operator.

### 7.5 Interaction Model

- **"Plan my day"** — triggers daily procedure. Produces artifact and presents it inline.
- **"Monthly review"** — triggers monthly procedure. Produces review artifact.
- **No auto-generation at session start.** This is an on-demand skill, not a startup hook. Rationale: tying it to Claude Code sessions creates a dependency on session frequency. The web UI delivery (future) will likely trigger it on a schedule — but that's the web UI project's concern, not this one.
- **Editing:** Operator edits the artifact directly in the vault. No special edit commands needed. The skill reads the artifact state at next invocation.

## 8. Domain Classification and Workflow

- **Domain:** software
- **Project class:** system
- **Workflow:** four-phase (SPECIFY → PLAN → TASK → IMPLEMENT)
- **Rationale:** Deliverables are system infrastructure (skill, artifact types, vault conventions). IMPLEMENT phase covers building the skill, creating prerequisite artifacts, wiring validation, and a soak period of actual daily use to validate the design.

## 9. Task Decomposition

### AM-001: Create prerequisite artifacts
- Crumb creates template files with example structure:
  - `_system/docs/goal-tracker.yaml` with schema and placeholder examples
  - `Domains/Career/se-management-inventory.md` with category structure and example items
- **Operator action (not a Crumb task):** populate both with real data
- Risk: low
- Tags: `#writing`
- Acceptance criteria: Both files exist and pass vault-check. Skill (AM-003) must produce useful output even with minimal/placeholder data in prerequisites (graceful degradation).

### AM-002: Register daily-attention and attention-review types
- Add `daily-attention` and `attention-review` to type taxonomy in `file-conventions.md`
- Add vault-check rules for both types: schema validation (location, frontmatter fields)
- Verify vault-check handles `.yaml` files in `_system/docs/` (goal-tracker is the first non-markdown file there)
- Create `_system/daily/` directory
- Risk: low
- Tags: `#code`
- Acceptance criteria: vault-check validates sample daily-attention and attention-review notes without errors

### AM-003: Build attention-manager skill
- Write `.claude/skills/attention-manager/SKILL.md`
- Daily procedure: context loading, project scan, SE scan, goal scan, carry-forward, prioritization, curation, write
- Monthly procedure: pre-processing aggregation step + analysis + goal-tracker update proposal
- Monthly digest helper: script or inline procedure that aggregates a month's daily artifacts into a structured summary (domain counts, carry-forward patterns, goal references, completion rates) so the skill loads one digest instead of 15-20 individual files
- Context contract with overlay co-firing (Life Coach + Career Coach)
- Risk: medium — the prioritization logic is the hard part; everything else is mechanical
- Tags: `#code`, `#writing`
- Acceptance criteria: Skill triggers on "plan my day", produces a daily artifact that passes vault-check, carry-forward works across consecutive days. Monthly procedure produces a review from aggregated data without exceeding extended-tier context budget.
- Dependencies: AM-001, AM-002

### AM-004: Dry-run validation
- Run the skill for 5 consecutive days with real data
- Assess: artifact quality, curation usefulness, ceremony burden, carry-forward accuracy
- Collect operator feedback after each day
- Adjust skill procedure based on findings
- Risk: medium — this is where design meets reality
- Tags: `#decision`
- Acceptance criteria: Operator rates 4/5 daily artifacts as "useful" (subjective but honest)
- Dependencies: AM-003

### AM-005: Monthly review validation
- Run the monthly review procedure on the dry-run data
- Assess: synthesis quality, goal alignment signal, actionable adjustments
- Risk: low — depends on AM-004 producing enough data
- Tags: `#decision`
- Acceptance criteria: Monthly review produces at least 2 actionable observations and 1 goal-tracker update proposal
- Dependencies: AM-004

### AM-006: Documentation and cleanup
- Update CLAUDE.md if attention-manager conventions warrant it
- Clean up any scratch artifacts from dry-run
- Write progress-log summary
- Risk: low
- Tags: `#writing`
- Dependencies: AM-005

## 10. Open Questions (Resolved)

**OQ-1: Where does the daily artifact live?**
→ `_system/daily/YYYY-MM-DD.md`. System directory, not domain-scoped, because the artifact is cross-domain. Monthly reviews in the same directory. 90-day retention.

**OQ-2: How does goal-tracking work?**
→ `_system/docs/goal-tracker.yaml`. Pure YAML, 3-5 active goals max, monthly/quarterly horizons, free-text progress field. No nested milestones. Reviewed monthly.

**OQ-3: SE management inventory structure?**
→ `Domains/Career/se-management-inventory.md`. Static reference doc — three categories (recurring, periodic, ad-hoc). No checkboxes, no state. Inline cadence annotations. Skill infers "due" from cadence + daily artifact completion history. Only updated when responsibilities change.

**OQ-4: Carry-forward mechanics?**
→ Skill finds most recent artifact within 3 days, rolls unchecked Focus items (`- [ ]`) with incrementing counter. 5-day escalation threshold. Operator marks done via checkbox (`- [x]`) or deletion. Gaps >3 days produce fresh lists.

**OQ-5: Interaction model?**
→ On-demand skill ("plan my day"). No auto-generation at session start. Operator edits the artifact directly. Future web UI may add scheduled triggers — that's a separate project concern.

**OQ-6: How heavy is this?**
→ Target: <5 minutes operator time per day. Crumb does the reading, reasoning, and writing. Operator reviews the output, adjusts if needed, and goes. Goal-tracker updated monthly. SE inventory updated when responsibilities change.

## 11. Overlay Integration Notes

### Life Coach Lens (applied during curation)
- **Values alignment:** Does today's list reflect the personal philosophy? Is "do the work in front of you" honored, or is the list aspirational?
- **Whole-person impact:** Is any domain consistently absent? Flag when work crowds out family/spiritual/creative for 3+ consecutive days.
- **The "enough" test:** Is the list trying to do too much? 5-8 items, not 12.
- **Library grounding:** When relevant, surface a vault insight that speaks to the day's prioritization tension.

### Career Coach Lens (applied during curation)
- **Skill leverage:** Are SE management tasks crowding out skill-building work?
- **Relationship capital:** Are customer engagement items getting appropriate attention, or are they all deferred?
- **Opportunity cost:** Every hour on admin is an hour not on architecture or customer value. Flag when admin dominates.
