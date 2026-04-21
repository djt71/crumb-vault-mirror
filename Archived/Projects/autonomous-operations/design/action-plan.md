---
type: action-plan
status: active
created: 2026-03-12
updated: 2026-03-12
skill_origin: action-architect
domain: software
project: autonomous-operations
---

# Autonomous Operations — Phase 1 Action Plan

## M1: Foundation (AO-001 + AO-002)

**Goal:** Establish the replay log infrastructure and structured attention item format. These are independent and can proceed in parallel.

**Success criteria:**
- SQLite database initializes with all required tables, indexes, and UNIQUE constraints; `init-db` test inserts 1 cycle + N items + sidecar hash and queries them back with matching counts
- Daily artifact includes `action_class` on every Focus item (validated: 100% of parsed items have a non-null `action_class`)
- Sidecar JSON file produced alongside each artifact and passes `jq -e` validation against required schema keys (`object_id`, `source_path`, `domain`, `title`, `action_class`, `urgency`)
- Daily-attention.sh logs each cycle to SQLite after artifact generation, with `cycles.status` reflecting outcome (`ok`, `api_error`, `parse_error`)

**Implementation notes:**

AO-001 (schema) — create a schema init script, write helper functions in attention-lib.sh, test CRUD operations. Pattern: follow dashboard_actions SQLite approach (same machine, same cron-lib.sh infrastructure). Database location: `_openclaw/data/attention-replay.db`. Schema versioning: `PRAGMA user_version = 1` set on init; checked on open to detect migrations.

**Schema tables:**

| Table | Key columns | Notes |
|-------|------------|-------|
| `cycles` | `cycle_id`, `ts`, `artifact_path`, `sidecar_path`, `prompt_hash`, `model`, `input_tokens`, `output_tokens`, `status`, `error`, `parse_warnings` | One row per daily run. `parse_warnings` is a JSON array of warning strings (taxonomy fallbacks, dedup merges, validation issues). |
| `items` | `item_id`, `cycle_id`, `object_id`, `source_path`, `domain`, `title`, `action_class`, `urgency`, `is_recurrence`, `recurrence_count`, `first_seen_ts`, `last_seen_ts`, `raw_json` | UNIQUE(`cycle_id`, `object_id`) |
| `aliases` | `old_id`, `new_id`, `created_ts` | Manual rename tracking |
| `actions` | `item_id`, `action_type`, `action_source`, `action_ts`, `details_json` | Populated by AO-004. UNIQUE(`item_id`, `action_source`) prevents double-classification on reruns. |

Indexes on: `items(cycle_id)`, `items(object_id)`, `items(source_path)`, `actions(action_type)`.

**Object identity rules:**
- `source_path` is vault-relative, forward-slash separators, no trailing slash, no leading `./`. Normalization function: `normalize_path()` in attention-lib.sh.
- `object_id` = `source_path` after normalization (plain string, not hashed). Items without a file path use a synthetic ID: `synthetic:<domain>/<title-slug>`.
- Aliases map old normalized paths to new ones. `resolve_id()` checks aliases before any identity comparison — applied consistently in both pre-processing (dedup context) and post-processing (duplicate detection).
- The UNIQUE constraint on `(cycle_id, object_id)` enforces no duplicates at the DB level. On conflict: reject and log to `parse_warnings`.

**`domain` field:**

Canonical values: `software`, `career`, `learning`, `health`, `financial`, `relationships`, `creative`, `spiritual`. Fallback: if the model omits `domain` or returns an unrecognized value, post-processing sets `domain = 'software'` and appends a warning to `parse_warnings`. The model receives domain context from input sources (project frontmatter, goal tracker entries) and is instructed to include it per item.

**`action_class` taxonomy:**

Allowed values: `do`, `decide`, `plan`, `track`, `review`, `wait`. Fallback: if the model omits `action_class` or returns an unrecognized value, post-processing sets `action_class = 'review'` and appends a warning to `parse_warnings`.

---

AO-002 (items) — prompt engineering for structured output from a direct API call with no tool access.

**Structured extraction approach:**

Primary method: **single delimited JSON block** at the end of the response. The prompt instructs the model to produce the human-readable Markdown artifact first, then emit a fenced JSON block containing all structured items:

```
After the daily artifact content, emit a fenced JSON block:

\`\`\`json
[
  {"object_id": "...", "source_path": "...", "domain": "...", "title": "...", "action_class": "...", "urgency": "..."},
  ...
]
\`\`\`
```

Post-processing extracts the JSON block using `sed -n '/^```json$/,/^```$/p' | sed '1d;$d' | jq -e '.'`. This is more robust than per-item HTML comment markers because:
- Fenced blocks are a standard LLM output format (models comply reliably)
- Single extraction point eliminates scattered-marker failure modes
- `jq -e` validates both syntax and non-empty output in one step

**Quarantine on parse failure:** If jq validation fails, write the raw API response to `_openclaw/data/quarantine/{date}-raw.txt`, log `cycles.status = 'parse_error'`, and skip item logging for that cycle. The Markdown artifact is still written (human-readable output is not gated on parse success).

**Schema validation:** After jq parse, validate each item has required keys (`object_id`, `source_path`, `domain`, `title`, `action_class`, `urgency`). Items missing required keys are logged to `parse_warnings` and excluded from SQLite insert.

**Token budget configuration:**

| Parameter | Value | Source |
|-----------|-------|--------|
| `MODEL` | (set in config) | attention-lib.sh |
| `MAX_OUTPUT_TOKENS` | 4000 | API `max_tokens` param |
| `MAX_INPUT_ESTIMATE` | 6000 | Pre-call heuristic check |

Runtime guard: before the API call, estimate prompt token count (chars / 3.5 heuristic). If estimate exceeds `MAX_INPUT_ESTIMATE`, truncate the lowest-priority input section (source inventory summaries first, then reduce lookback window). Log truncation events to `cycles`.

**Error handling:**
- API call wrapped in retry (3 attempts, exponential backoff: 2s, 5s)
- On retry exhaustion: log `cycles.status = 'api_error'`, write error details to `cycles.error`, skip artifact generation for this cycle
- Parse failure: quarantine (above)
- DB write failure: log to stderr, ensure cycle row records the error
- All writes use atomic pattern: write to temp file, then `mv` to final path

Test AO-002 with `--dry-run` first to verify prompt fits token budget, then 5+ live runs before declaring stable (probabilistic formatting needs more than 2-3 runs to expose edge cases).

**Integration step (after both complete):** Wire AO-001 logging into AO-002's post-processing — after writing the artifact and sidecar JSON, call `log_cycle` and `log_item` for each parsed item. This closes the loop: every daily run produces an artifact + sidecar + SQLite log entry. **AO-003 cannot begin meaningful testing until this integration step is complete** (dedup context queries require populated item history).

---

## M2: Deduplication (AO-003)

**Goal:** Prevent the same object from appearing as multiple independent items across consecutive cycles. Establish path-based identity with alias tracking.

**Prerequisite:** M1 integration step complete (items logged to SQLite from at least 2-3 daily cycles).

**Success criteria:**
- Zero duplicate `object_id` values within a single cycle (enforced by UNIQUE constraint + post-processing check)
- Recurring items tracked with `is_recurrence = true`, `recurrence_count` incremented, and `urgency` non-decreasing across consecutive appearances of the same `object_id`
- Alias table operational: `resolve_id("old/path")` returns `"new/path"` after alias registration

**Implementation notes:**

AO-003 has two parts:
1. **Pre-processing (before API call):** Query SQLite for items surfaced in the last 3 cycles. Format as a structured context block injected into the user message, delimited with XML tags to prevent context poisoning:

```xml
<historical_context purpose="dedup reference only — do not copy these items into your output">
[
  {"object_id": "Projects/foo/spec.md", "title": "Review foo spec", "urgency": "medium", "last_seen": "2026-03-11", "times_seen": 3},
  ...
]
</historical_context>
```

**Context format:** Compact JSON array with fields: `object_id`, `title`, `urgency`, `last_seen`, `times_seen`. Cap: top 20 items by recency. This keeps the block token-efficient (~500-800 tokens for 20 items) while preserving enough signal for dedup.

The prompt instruction: "The historical_context block shows items from recent cycles — use it ONLY to detect recurrences. If an item matches a historical object_id and its situation hasn't changed, mark it as recurring with increased urgency rather than creating a fresh entry. If it HAS changed (new information, status shift), keep the same object_id with refreshed rationale and mark `is_recurrence: true`. Do NOT copy historical items verbatim into your output."

2. **Post-processing validation (after API call):** After parsing sidecar JSON, apply `resolve_id()` to all `object_id` values, then check for duplicates within the cycle. On duplicate: keep the item with richer fields (more non-null values), merge urgency (take max), log a `dedup_event` to `parse_warnings` with both item payloads for auditability.

For recurring items (same `object_id` as a prior cycle): set `is_recurrence = true`, set `recurrence_count = prior_count + 1`, copy `first_seen_ts` from earliest appearance. Verify `urgency` is non-decreasing; if model returned lower urgency, escalate to prior level and log warning.

The alias table is a SQLite table (in AO-001 schema). The `resolve_id()` function checks aliases before identity comparison. Manual maintenance: `bash attention-lib.sh add_alias "old/path" "new/path"`.

**Token budget guard:** After assembling the full prompt (base + dedup context), check estimated token count against `MAX_INPUT_ESTIMATE`. If over budget: reduce lookback from 3 cycles to 2, then reduce item cap from 20 to 10. Log truncation.

---

## M3: Instrumentation (AO-004 + AO-005)

**Goal:** Close the feedback loop. Infer what the operator did with surfaced items and compute quality metrics.

**Success criteria:**
- Correlation script correctly classifies acted-on vs. not-acted-on items: spot-check validation of 20 randomly sampled items with ≥80% agreement between automated classification and manual review
- All five Phase 1 exit metrics computable from SQLite
- Scoring output suitable for monthly review consumption
- Correlation is idempotent: re-running produces identical results

**Implementation notes:**

AO-004 (correlation) is the most novel piece. Core logic:

```
for each item in items
    WHERE NOT EXISTS (SELECT 1 FROM actions WHERE actions.item_id = items.item_id
                      AND action_source IN ('git_commit_correlation',
                          'mtime_correlation', 'vault_change_correlation',
                          'no_source_path')):
    window = 48h if items.domain in (software, career) else 7d
    window_end = cycle_ts + window_duration
    if now < window_end:
        skip (window not yet closed)

    # Primary signal: git commits to source_path
    git_changes = git log --follow --since=cycle_ts --until=window_end -- source_path

    # Secondary signal: filesystem mtime (catches uncommitted edits)
    if not git_changes and source_path exists:
        mtime = stat -f %m source_path
        if cycle_ts <= mtime <= window_end:
            mtime_match = true

    if git_changes:
        log_action(item_id, 'acted_on', 'git_commit_correlation')
    elif mtime_match:
        log_action(item_id, 'acted_on', 'mtime_correlation')
    else:
        log_action(item_id, 'not_acted_on', 'vault_change_correlation')
```

Items with synthetic object_ids (`synthetic:*`) or missing `source_path` are logged as `action_type = 'uncorrelated'`, `action_source = 'no_source_path'`. These are excluded from acted-on rate calculations but tracked for coverage reporting.

**Default window:** Items without a recognized domain default to 7d.

**Known limitation:** Correlation detects file-level changes to the surfaced item's source path (or its rename via `--follow`). If the operator acts on the item by modifying a *different* file, the correlation misses it. Accept this for Phase 1 — it biases toward false negatives (under-counting acted-on), which is the safe direction for a quality proxy.

**Idempotency:** The `NOT EXISTS` subquery covers all four `action_source` values: the three correlation outcomes (`git_commit_correlation`, `mtime_correlation`, `vault_change_correlation`) plus `no_source_path` (pathless items classified as `uncorrelated`). Including `no_source_path` ensures pathless items aren't re-processed on reruns — they'd get the same `uncorrelated` result, but skipping them keeps the script truly idempotent. The UNIQUE(`item_id`, `action_source`) constraint on the `actions` table provides a DB-level safety net against double-classification.

**Scheduling:** Invoked from `daily-attention.sh` as a pre-processing step (before context gathering, correlation runs for items whose windows closed since last cycle). The standalone `attention-correlate.sh` script is preserved for manual reruns and backfills. No separate LaunchAgent — script-level isolation without scheduler-level complexity.

**Runtime threshold:** Correlation should complete in <30 seconds for a week of items. Log elapsed time; flag if exceeded.

---

AO-005 (scoring) computes Phase 1 exit metrics from the replay database.

**Metric definitions:**

| Metric | Definition | SQL sketch | Required data |
|--------|-----------|------------|---------------|
| Context coverage | % of items with non-null `source_path`, valid `action_class`, and valid `domain` | `COUNT(valid) / COUNT(*)` on items | AO-002 parse output |
| Acted-on rate | % of correlated items classified as `acted_on` | `COUNT(acted_on) / COUNT(acted_on + not_acted_on)` on actions (excludes `uncorrelated`) | AO-004 correlation |
| Dedup accuracy | % of cycles with zero duplicate `object_id` | `COUNT(clean_cycles) / COUNT(cycles)` | AO-003 post-processing |
| Replay completeness | % of calendar days with a logged cycle | `COUNT(DISTINCT date(ts)) / days_in_window` on cycles | AO-001 logging |
| Scoring coverage | % of window-closed items with a correlation result | `COUNT(correlated) / COUNT(window_closed)` | AO-004 correlation |

**Note on false-positive rate:** The original spec referenced "false-positive rate >40%." Phase 1 correlation cannot distinguish between "irrelevant item surfaced" (true false positive) and "relevant item the operator deferred" — both appear as `not_acted_on`. The metric is therefore redefined as **acted-on rate** (the inverse signal): a low acted-on rate *suggests* either poor item selection or deferred action, but doesn't distinguish. For Phase 1, acted-on rate is the honest metric. True false-positive measurement requires a lightweight labeling mechanism (deferred to Phase 2: operator can flag items as "irrelevant" via a dismiss action, providing ground truth).

**Operational guardrails:**
- Runtime threshold: scoring should complete in <10 seconds. Log elapsed time.
- Output format: JSON object with raw counts alongside rates (e.g., `{"context_coverage": {"rate": 0.87, "valid": 52, "total": 60}, ...}`). Human-readable summary to stdout; JSON to `_openclaw/data/attention-scores.json` for monthly review consumption.
- Print `N_window_closed` (items eligible for acted-on rate) alongside the rate to make sample size explicit.

---

## M4: Evaluation Period (14 days post-deploy)

**Goal:** Validate Phase 1 exit criteria with production data.

**Success criteria:** All five exit criteria met per the revised metric definitions above, computed over window-closed items only.

**Evaluation window caveat:** Items with 7-day correlation windows surfaced in the second half of the 14-day period won't have closed windows at evaluation time. The effective sample for acted-on rate is ~7-10 days of items, not 14. This is acceptable for a directional Phase 1 gate — the question is "are the pipes working?" not "do we have statistical power?" The `attention-score.sh` output prints `N_window_closed` alongside all rates to make sample size explicit.

**This is not a task — it's a gate.** After AO-005 deploys, the system runs autonomously for 14+ days. At the end, run `attention-score.sh` and evaluate against the exit criteria table. The gate evaluation follows the pattern in `_system/docs/solutions/gate-evaluation-pattern.md`: criteria defined now, autonomous period runs, structured evaluation at the end.

If any criterion is not met, the response is targeted:
- Context coverage <80% → tune prompt or schema validation (AO-002 iteration)
- Acted-on rate anomalous (very low or very high) → review item selection quality, check correlation accuracy with manual spot-check
- Dedup failures → tighten post-processing validation, review identity normalization, or reduce lookback window
- Replay gaps → debug error handling chain (API retry, parse quarantine, DB logging)
- Scoring coverage gaps → debug correlation script, check for items stuck in uncorrelated state

---

## Sequencing Summary

```
Week 1:  AO-001 ═══╗
         AO-002 ═══╬══ integration ══ AO-003 ════╗
                   ║                               ║
Week 2:            ╚════════════════ AO-004 ══════╬══ AO-005
                                                  ║
Week 3+: ═════════════ 14-day evaluation period ══════════
```

**Dependency notes:**
- AO-001 and AO-002 can proceed in parallel
- The integration step (logging parsed items to SQLite) is a hard prerequisite for AO-003 — dedup needs populated item history
- AO-004 depends on AO-001 (schema) and benefits from stable identity rules (AO-003), but can begin development in parallel using synthetic test data
- AO-005 depends on AO-004 output for acted-on rate queries; can develop SQL and test with mock data, but full validation requires real correlation results

Estimated implementation: ~2 weeks for AO-001 through AO-005 (sessions, not continuous days). Evaluation period: 14 days minimum after full deployment. Phase 1 total: ~4-5 weeks from first task to exit evaluation.

---

## Appendix: Peer Review Response

This plan was updated to address findings from the 2026-03-12 peer review (`Projects/autonomous-operations/reviews/2026-03-12-action-plan.md`). Changes applied:

| Action | Finding sources | Change |
|--------|----------------|--------|
| A1 (must-fix) | OAI-F3, GEM-F2, DS-F1, GRK-F1 | Switched to single delimited JSON block; added jq validation + quarantine |
| A2 (must-fix) | OAI-F7, GRK-F5 | Added formal object identity rules, schema tables, UNIQUE constraint |
| A3 (must-fix) | OAI-F14 | Redefined false-positive rate → acted-on rate; deferred labeling to Phase 2 |
| A4 (should-fix) | OAI-F2, OAI-F20, GEM-F5, DS-F3, GRK-F8 | Tightened success criteria with concrete validation gates |
| A5 (should-fix) | OAI-F8, DS-F8, GEM-F6 | Specified dedup context format, cap, XML guardrails |
| A6 (should-fix) | OAI-F15, GRK-F2 | Added error handling spec (retry, quarantine, status logging) |
| A7 (should-fix) | OAI-F11, GEM-F4 | Added mtime as secondary correlation signal |
| A8 (should-fix) | OAI-F4, GRK-F3 | Parameterized token budgets with runtime guard |
| A9 (should-fix) | OAI-F5, DS-F7 | Defined action_class taxonomy with fallback |
| A10 (should-fix) | DS-F4 | Clarified AO-003 depends on M1 integration step; updated sequencing |

### Round 2 (5-model manual review: `reviews/2026-03-12-action-plan-r2.md`)

| Action | Finding sources | Change |
|--------|----------------|--------|
| B1 (must-fix) | GPT-F1 | Fixed AO-004 idempotency bug: broadened NOT EXISTS to cover all action_source values; added UNIQUE(item_id, action_source) |
| B2 (must-fix) | GEM2-F2, DS2-F2, GPT-F3, PPX-F2 | Added `domain` to items table, sidecar schema, validation, prompt instruction; 8 canonical values + fallback |
| B3 (must-fix) | GPT-F5 | Formalized `parse_warnings` as TEXT column (JSON array) on cycles table |
| B4 (must-fix) | All 5 reviewers | Resynced tasks.md to action plan (taxonomy, table names, sidecar schema) |
| B5 (should-fix) | All 5 reviewers | Added evaluation window caveat to M4; print N_window_closed in score output |
| B6 (should-fix) | Claude, GEM2-F4, GPT-F9 | Folded AO-004 into daily-attention.sh; kept standalone script for manual reruns |
| B7 (should-fix) | All 5 reviewers | Updated spec summary exit criteria (acted-on rate, context coverage + domain) |
| B8 (should-fix) | GPT-F10 | Added operational guardrails: PRAGMA user_version, runtime thresholds, JSON output |
| B9 (should-fix) | GPT-F7 | Fixed AO-003 prompt: same object_id + refreshed rationale + is_recurrence, not "treat as new" |
| B10 (should-fix) | GPT-F8, B2 | Added `urgency` and `domain` to schema validation required keys |
