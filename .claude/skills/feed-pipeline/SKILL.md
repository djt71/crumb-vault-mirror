---
name: feed-pipeline
description: >
  Process feed intel items from _openclaw/inbox/ and dashboard-queued promotions
  from FIF SQLite: scan, classify by tier, extract actions (Tier 2), evaluate
  permanence and auto-promote to signal-notes (Tier 1a), generate review queues
  for borderline items (Tier 1b), and process operator-flagged promotions from
  the Mission Control dashboard. Use when user says "process feed items",
  "feed pipeline", "promote inbox items", "clear feed backlog", or
  "process feed intel".
model_tier: reasoning
capabilities:
  - id: feed.triage.standard
    brief_schema: feed-pipeline-brief
    produced_artifacts:
      - "_openclaw/inbox/feed-intel-*.md"
    cost_profile:
      model: claude-opus-4-6
      estimated_tokens: 80000
      estimated_cost_usd: 1.20
      typical_wall_time_seconds: 300
    supported_rigor: [standard]
    required_tools: [Read, Write, Glob, Grep]
    quality_signals: [format, relevance]
  - id: feed.promotion.signal
    brief_schema: feed-pipeline-brief
    produced_artifacts:
      - "Sources/signals/*.md"
    cost_profile:
      model: claude-opus-4-6
      estimated_tokens: 60000
      estimated_cost_usd: 0.90
      typical_wall_time_seconds: 240
    supported_rigor: [standard]
    required_tools: [Read, Write, Glob, Grep, Bash]
    quality_signals: [format, relevance, writing]
  - id: feed.promotion.dashboard
    brief_schema: feed-pipeline-brief
    produced_artifacts:
      - "Sources/signals/*.md"
    cost_profile:
      model: claude-opus-4-6
      estimated_tokens: 40000
      estimated_cost_usd: 0.60
      typical_wall_time_seconds: 180
    supported_rigor: [standard]
    required_tools: [Read, Write, Glob, Grep, Bash]
    quality_signals: [format, relevance, writing]
required_context:
  - path: _system/docs/file-conventions.md
    condition: always
    reason: "Signal-note schema, kb/ tag taxonomy, type taxonomy"
  - path: _system/docs/kb-to-topic.yaml
    condition: always
    reason: "Tag-to-MOC mapping for topics derivation"
  - path: _system/docs/solutions/haiku-soul-behavior-injection.md
    condition: always
    reason: "Haiku confabulation patterns relevant to triage pipeline"
---

# Feed Pipeline

## Identity and Purpose

You are a feed intel processor who bridges the gap between FIF triage output
and the vault knowledge base. You handle two entry paths:

1. **Inbox path:** `_openclaw/inbox/feed-intel-*.md` files from the FIF pipeline
2. **Dashboard path:** operator-flagged promotions from the Mission Control
   dashboard (stored in `dashboard_actions` table in FIF SQLite DB)

You route high-signal content items to permanent signal-notes in `Sources/signals/`,
extract actionable items to project run-logs, and generate review queues for
borderline items. You protect the KB from noise while ensuring durable knowledge
is captured before inbox items expire.

## When to Use This Skill

- User says "process feed items", "feed pipeline", "promote inbox items",
  "clear feed backlog"
- User asks to review or triage inbox feed-intel items
- Session startup reports a large feed-intel inbox count and user wants to act

## Routing Overview

```
Dashboard promote queue (FIF SQLite dashboard_actions)
        │
        └─ Step 0: human already decided → skip Q1-Q3
            → Q4 (project applicability) → full promotion workflow → set consumed_at

_openclaw/inbox/feed-intel-*.md
        │
        ├─ Tier 2: test / add-to-spec actions
        │   → Extract action item → route to project run-log → delete source
        │
        ├─ Tier 1: high priority + high confidence + capture action
        │   → Permanence evaluation
        │     ├─ 1a Auto-promote: durable + clear kb/ mapping + no overlap
        │     │   → signal-note in Sources/signals/ → MOC registration → delete source
        │     └─ 1b Review queue: borderline (unclear tags, possible overlap, hybrid)
        │         → review-queue file → operator acts later → delete source
        │
        └─ Tier 3: everything else
            → No action. TTL cron purges after 14 days.
```

## Procedure

### Step 0 — Dashboard-Queued Promotions

Before scanning the inbox, check the FIF SQLite DB for operator-flagged promotions
from the Mission Control dashboard. These items have already passed human judgment —
skip permanence evaluation (Q1-Q3), but run the full promotion workflow.

1. **Query pending promotions:**
   ```bash
   sqlite3 -json "${FIF_DB_PATH:-$HOME/openclaw/feed-intel-framework/state/pipeline.db}" \
     "SELECT da.canonical_id, da.metadata, da.created_at,
             p.source_type, p.content_json, p.author_json,
             p.triage_json, p.metadata_json
      FROM dashboard_actions da
      JOIN posts p ON da.canonical_id = p.canonical_id
      WHERE da.action = 'promote' AND da.consumed_at IS NULL"
   ```
   If no rows returned or DB is inaccessible, skip to Step 1 (no dashboard queue).

2. **Extract item data** from each row's JSON fields:
   - `content_json` → title, summary, url
   - `author_json` → author display_name / username
   - `triage_json` → tags, why_now, priority, confidence
   - `da.metadata` → optional `kb_tag` override (JSON, e.g., `{"kb_tag":"kb/software-dev"}`)

3. **kb/ tag resolution** (replaces Q1-Q3 — human already decided to promote):
   - If `da.metadata` contains a `kb_tag` value, use it directly (operator override
     from the dashboard tag selector)
   - Otherwise, auto-map from `triage_json.tags` using the same mapping rules as
     Step 4 Q2 (FIF triage tags → canonical #kb/ Level 2 tags)
   - If no canonical tag resolves, flag the item and ask operator before promoting

4. **Q4: Active project applicability** — same evaluation as Step 4 Q4:
   - Scan active projects (`Projects/*/project-state.yaml` where phase is not
     DONE or ARCHIVED) for relevance to the signal content
   - Match by: topic overlap, tool/pattern applicability, domain alignment
   - Note matching project names for cross-posting in sub-step 5g

5. **Promote** — for each dashboard-queued item, run the Step 5 promotion
   workflow with these differences:
   - **(a) source_id generation:** Same as Step 5.1
   - **(b) source_type mapping:** Same as Step 5.2
   - **(c) frontmatter:** Same as Step 5.3, but use the resolved kb_tag from
     step 3 above, and add `dashboard_promote: true` to `source.provenance`:
     ```yaml
     provenance:
       inbox_canonical_id: "[canonical_id]"
       triage_priority: [from triage_json]
       triage_confidence: [from triage_json]
       dashboard_promote: true
     ```
   - **(d) body:** Same as Step 5.4. Signal excerpt comes from `content_json.summary`.
     "Why now" comes from `triage_json.why_now`.
   - **(e) write + MOC:** Same as Step 5.5 and 5.6
   - **(f) inbox file cleanup:** Glob for a matching
     `_openclaw/inbox/feed-intel-*.md` file by `canonical_id` in frontmatter.
     If found, delete it. If not found, skip — the item may exist only in the DB.
   - **(g) knowledge retrieval + cross-post:** Same as Step 5.8 and 5.9,
     using Q4 results from step 4 above
   - **(h) calibration:** Same as Step 5.10 — logged as `dashboard_promoted`
     in the calibration entry

6. **Mark consumed** — after successful promotion of each item:
   ```bash
   sqlite3 "${FIF_DB_PATH:-$HOME/openclaw/feed-intel-framework/state/pipeline.db}" \
     "UPDATE dashboard_actions SET consumed_at = datetime('now')
      WHERE canonical_id = '[canonical_id]'"
   ```
   If the write fails (DB locked, permissions), log the error and continue —
   the item will be re-processed on the next run (idempotent due to dedup in
   Step 5.1 collision check).

7. Dashboard-queued count is included in the Step 1 summary.

### Step 1 — Scan & Count

1. Glob `_openclaw/inbox/feed-intel-*.md`
2. For each file, read frontmatter only (first 15 lines is sufficient):
   - Extract: `priority`, `confidence`, `recommended_action`, `tags`, `canonical_id`
3. Classify into tiers:
   - **Tier 1:** `priority: high` AND `confidence: high` AND `recommended_action: capture`
   - **Tier 2:** `recommended_action` is `test` or `add-to-spec`
   - **Tier 3:** everything else (medium priority, medium confidence, or other actions)
4. **Volume circuit breaker:** If Tier 1 count > 10, flag as classifier drift:
   ```
   ⚠ Unusual volume: [n1] Tier 1 items (expected ≤10).
   Upstream triage may need recalibration. Routing to batch review
   instead of auto-promote.
   ```
   When the circuit breaker fires, ALL Tier 1 items route to review queue
   (Step 6) instead of auto-promote (Step 5). The operator reviews the batch
   and picks which items genuinely deserve promotion.
5. Report counts to operator:
   ```
   Feed intel inbox: [N] items
     Dashboard-queued: [d] promotions [processed / skipped if 0]
     Tier 1 (auto-promote candidates): [n1]
     Tier 2 (action extraction):       [n2]
     Tier 3 (no action / TTL expiry):  [n3]
   ```
   If circuit breaker fired, append: `[circuit breaker active — batch review mode]`
   If Step 0 processed items, show: `[d] dashboard promotions completed`
6. Operator picks which tiers to process. Respect the choice — don't process
   unpicked tiers.

### Step 2 — Tier 3 (Skip)

No processing. Log the count for calibration. These items wait for TTL expiry
(14 days, matching adapter queue expiry — handled by `_system/scripts/feed-inbox-ttl.sh`).

### Step 3 — Tier 2 (Action Extraction)

For each Tier 2 item:

1. Read full content (body is short — ~10 lines typically)
2. Match to active project via `tags` field + "Why now" text:
   - `crumb-architecture` → feed-intel-framework or relevant Crumb project
   - `tool-discovery` → relevant project by tool type
   - If no clear match, flag for user routing
3. Extract one-line action from the triage assessment
4. Present batch to operator:
   ```
   Tier 2 Actions:
   - [canonical_id]: "[action]" → [project]/run-log.md
   - [canonical_id]: "[action]" → [needs routing]
   ```
5. On operator approval:
   - Append action items to respective project run-logs under current session
   - Delete processed source files from inbox
   - **Sync-back:** For each processed item, write a dashboard_actions row so the
     item disappears from the Mission Control signal list:
     ```bash
     sqlite3 "${FIF_DB_PATH:-$HOME/openclaw/feed-intel-framework/state/pipeline.db}" \
       "INSERT OR IGNORE INTO dashboard_actions (canonical_id, action, created_at, consumed_at)
        VALUES ('[canonical_id]', 'skip', datetime('now'), datetime('now'))"
     ```
6. On operator rejection of specific items: skip those, keep in inbox

### Step 4 — Tier 1 (Permanence Evaluation)

Process in batches of 20. For each item in the batch:

1. Read full content
2. Evaluate three questions:

   **Q1: Durable or timely?**
   - Durable: reusable pattern, architectural principle, reference material,
     methodology, tool/technique with lasting value
   - Timely: news, announcements, pricing that will change, version-specific
     workarounds, event-driven context
   - Hybrid: durable pattern + timely specifics (e.g., pricing example of a
     lasting principle)

   **Q2: Canonical #kb/ tag mapping?**
   - Map FIF triage tags to canonical `#kb/` Level 2 tags using the tag list
     in `_system/docs/file-conventions.md`
   - FIF tags like `crumb-architecture`, `pattern-insight` → `kb/software-dev`
   - FIF tags like `tool-discovery` → `kb/software-dev` (or more specific if clear)
   - If no canonical tag fits, flag as review-queue
   - **Topics routing:** Signal-notes (type: signal-note) always get `topics: [moc-signals]`
     regardless of kb/ tag. The `kb-to-topic.yaml` mapping governs knowledge-note
     placement only — do not use it for signal-note topic derivation.

   **Q3: Vault dedup?**
   - Search `Sources/signals/` frontmatter for matching `source.canonical_url`
     or similar `source.source_id`
   - If overlap found, flag as review-queue with dedup note

   **Q4: Active project applicability?**
   - Scan active projects (`Projects/*/project-state.yaml` where phase is not
     DONE or ARCHIVED) for relevance to the signal content
   - Match by: topic overlap, tool/pattern applicability, domain alignment
   - If match found: note the project name(s) and how the signal applies
   - This drives wikilinks in the signal-note Context section and run-log
     cross-posting in Step 5

3. Route based on evaluation:
   - **1a (auto-promote):** All three pass — durable + clear kb/ mapping + no overlap
   - **1b (review-queue):** Any borderline — unclear tags, possible overlap,
     hybrid durability, or timely-only content worth a second look

4. Between batches of 20, pause for operator confirmation before continuing.

### Step 5 — Auto-Promote (Tier 1a)

For each auto-promote item:

1. **Generate source_id** using the standard algorithm:
   - `kebab(author-surname + short-title)` — max 60 chars, `[a-z0-9-]` only
   - For tweets: `kebab(handle + first-meaningful-words)` (skip "if you", "my", etc.)
   - Collision check: `grep -r "source_id:" Sources/signals/`

2. **Map source_type** from item metadata:
   - Items with `x:` canonical_id → `tweet`
   - Items with `rss:` canonical_id → `article` (or `blog` if clearly a blog)
   - Other adapters: map per adapter type

3. **Build signal-note frontmatter** per schema in `_system/docs/file-conventions.md`:
   ```yaml
   ---
   project: null
   domain: learning
   type: signal-note
   skill_origin: feed-pipeline
   status: active
   created: [today]
   updated: [today]
   tags:
     - kb/[mapped-tag]
   schema_version: 1
   source:
     source_id: [generated]
     title: "[first meaningful phrase from post/article]"
     author: "[handle or author name]"
     source_type: [tweet|article|blog|video|paper]
     canonical_url: [link from triage item]
     date_ingested: [today]
     provenance:
       inbox_canonical_id: "[canonical_id from triage item]"
       triage_priority: high
       triage_confidence: high
   topics:
     - moc-signals
   ---
   ```

4. **Build signal-note body:**
   ```markdown
   # [Short descriptive title]

   ## Signal

   [Excerpt from the triage item's Post section]

   [Triage "Why now" assessment — lightly edited for standalone clarity]

   ## Source

   [Link from triage item]

   ## Context

   [1-2 sentences connecting this to vault knowledge or active projects.
    Drawn from triage tags and "Why now" assessment.]
   ```

5. **Write** to `Sources/signals/[source_id].md`

6. **MOC Core placement** — register in `Domains/Learning/moc-signals.md`:
   - Search `<!-- CORE:START -->` / `<!-- CORE:END -->` for existing link
   - If no entry: insert one-liner per §5.6.6 format:
     ```
     - [[source_id|Author: Short Title]] — what it is | when to use
     ```
   - Present proposed one-liners to operator for batch confirmation
   - Note: all signal-notes route to moc-signals by type. The kb/ tag on the
     signal-note describes subject matter but does not drive MOC placement.

7. **Delete source** from `_openclaw/inbox/`

8. **Sync-back:** Write a dashboard_actions row so the item disappears from the
   Mission Control signal list:
   ```bash
   sqlite3 "${FIF_DB_PATH:-$HOME/openclaw/feed-intel-framework/state/pipeline.db}" \
     "INSERT OR IGNORE INTO dashboard_actions (canonical_id, action, created_at, consumed_at)
      VALUES ('[canonical_id]', 'promote', datetime('now'), datetime('now'))"
   ```
   INSERT OR IGNORE ensures idempotency — if the item was already promoted via
   the dashboard (Step 0), the existing row is preserved.

9. **Knowledge retrieval (related content):** Run `_system/scripts/knowledge-retrieve.sh --trigger new-content --note-path "Sources/signals/[source_id].md" --note-tags "[kb/tag1,kb/tag2]"`. If the brief returns results:
   - Append a "Related knowledge" section to the current run-log entry with the brief output
   - If cross-domain flag is present, note it for compound evaluation
   - Write the brief to `_openclaw/tess_scratch/kb-brief-latest.md` (lightweight Tess pre-answer path)
   If the script is not executable or returns empty, skip silently.

10. **Project run-log cross-post** — if Q4 identified active project links:
   - For each linked project, append a short entry to its `progress/run-log.md`:
     ```
     ## YYYY-MM-DD — Signal: [short title]

     **Signal:** [[source_id]] — one-line summary of the signal content.

     **Applicability:** How this signal applies to this project's current phase/work.
     ```
   - This is the primary resurfacing mechanism — run-logs are read on project
     resume, so the signal appears in context when work continues.
   - The signal-note Context section should wikilink `[[Projects/project-name/design/specification|project-name]]`
     for backlink discoverability (secondary mechanism). Use path-based links
     because no `project-name.md` file exists in the scaffold.

10. **Log** to calibration tracker

### Step 6 — Review Queue (Tier 1b)

Generate `_openclaw/inbox/review-queue-YYYY-MM-DD.md` with:

```markdown
---
type: reference
domain: software
status: draft
created: [today]
updated: [today]
skill_origin: feed-pipeline
---

# Feed Intel Review Queue — [today]

Items requiring operator judgment before promotion.

| # | Canonical ID | Author | Issue | Proposed Action |
|---|---|---|---|---|
| 1 | [id] | [author] | [unclear kb/ tag / possible overlap / hybrid] | [promote / skip / merge] |
```

For each item, include a collapsible details block:

```markdown
<details>
<summary>[#] [author]: [first 60 chars of excerpt]</summary>

**Excerpt:** [full excerpt from triage]
**Why now:** [triage assessment]
**Tags proposed:** [kb/ tags attempted]
**Issue:** [specific reason for review queue — e.g., "no canonical kb/ tag fits",
"possible overlap with [[existing-note]]", "hybrid: durable pattern but timely pricing"]
**Proposed action:** [promote with tag X / skip / merge with existing note Y]
</details>
```

**Sync-back:** For each review-queued item, write a dashboard_actions row so the
item disappears from the Mission Control signal list while awaiting review:
```bash
sqlite3 "${FIF_DB_PATH:-$HOME/openclaw/feed-intel-framework/state/pipeline.db}" \
  "INSERT OR IGNORE INTO dashboard_actions (canonical_id, action, created_at, consumed_at)
   VALUES ('[canonical_id]', 'skip', datetime('now'), datetime('now'))"
```

### Step 7 — Calibration Log

Append one JSON line to `_system/docs/feed-pipeline-calibration.jsonl`:

```json
{"date":"YYYY-MM-DD","total":N,"tier1":n1,"tier2":n2,"tier3":n3,"auto_promoted":p,"dashboard_promoted":d,"review_queued":r,"actions_extracted":a,"false_positives":0}
```

The `dashboard_promoted` field counts items processed via Step 0 (dashboard queue).
The `false_positives` field starts at 0 — updated during monthly audit when
auto-promoted items are reviewed for quality.

## Backlog vs. Steady-State

- **Backlog mode:** Operator invokes explicitly. Processes in batches of 20-30
  with confirmation between batches. For large inbox backlogs.
- **Steady-state mode:** Startup scan reports count. Operator decides when to
  invoke. Typical steady-state batch is 10-20 new items per session.

## Context Contract

**MUST have:**
- `_system/docs/file-conventions.md` — signal-note schema, kb/ tag taxonomy
- `_system/docs/kb-to-topic.yaml` — tag-to-MOC mapping
- `_openclaw/inbox/` contents (feed-intel-*.md files)
- FIF SQLite DB access via `sqlite3` CLI (for Step 0 dashboard queue)
  — default path: `~/openclaw/feed-intel-framework/state/pipeline.db`
  — override: `FIF_DB_PATH` env var

**MAY request:**
- MOC files in `Domains/*/` (for Core section placement in Step 5)
- Existing signal-notes in `Sources/signals/` (for dedup in Step 4)
- Project run-logs (for Tier 2 action routing in Step 3)
- `Projects/feed-intel-framework/design/specification.md` (FIF routing context)

**AVOID:**
- Processing items without reporting counts first (Step 1 is mandatory)
- Auto-promoting without operator seeing the batch counts
- Loading full FIF spec — use targeted reads only

**Typical budget:** Standard tier (3-5 docs).

## Convergence Dimensions

1. **Tier accuracy** — Items classified into correct tiers based on frontmatter metadata
2. **Tag mapping quality** — FIF triage tags correctly mapped to canonical #kb/ tags
3. **Dedup effectiveness** — No duplicate signal-notes created for the same source
4. **Schema compliance** — All signal-notes pass vault-check validation
5. **Calibration tracking** — Every run logged with accurate counts
6. **Dashboard queue processing** — All pending promotions consumed; `consumed_at` set on success; no orphaned queue entries
