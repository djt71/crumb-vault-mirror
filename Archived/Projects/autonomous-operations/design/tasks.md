---
type: tasks
status: active
created: 2026-03-12
updated: 2026-03-20
skill_origin: action-architect
domain: software
project: autonomous-operations
---

# Autonomous Operations — Phase 1 Tasks

## Task Table

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|----|------------|-------|------------|------|--------|-------------------|
| AO-001 | Replay log SQLite schema + bash helper library | DONE | — | low | `#code` | (1) `attention-replay.db` initializes cleanly on first run. (2) `attention-lib.sh` functions insert and query all four tables (cycles, items, actions, aliases). (3) Schema version tracked via `PRAGMA user_version = 1`. (4) Re-running init does not destroy existing data. (5) UNIQUE constraints enforced: `(cycle_id, object_id)` on items, `(item_id, action_source)` on actions. |
| AO-002 | Attention item schema: action_class + domain + sidecar JSON | DONE | — | medium | `#code` | (1) Every Focus item in daily artifact has `action_class` from canonical taxonomy (`do\|decide\|plan\|track\|review\|wait`). (2) Sidecar JSON passes `jq -e` validation with required keys: `object_id`, `source_path`, `domain`, `title`, `action_class`, `urgency`. (3) Parse failures quarantined to `_openclaw/data/quarantine/`. (4) 5+ live runs with stable parse success before declaring stable. (5) API response ≤4000 output tokens. |
| AO-003 | Object identity + dedup pre/post processing | DONE | AO-002, M1 integration | medium | `#code` | (1) Zero duplicate `object_id` values in same cycle (UNIQUE constraint + post-processing). (2) `attention-lib.sh add_alias` works for manual rename tracking. (3) Dedup context injection ≤1000 additional input tokens. (4) Recurring items tracked: `is_recurrence = true`, `recurrence_count` incremented, `urgency` non-decreasing. |
| AO-004 | Vault-change correlation engine | DONE | AO-001, AO-002 | medium | `#code` | (1) `attention-correlate.sh` processes items with closed windows in <30 seconds. (2) Spot-check of 20 items: ≥80% agreement with manual review. (3) Domain-aware windows applied (48h software/career, 7d others). (4) Results written to `actions` table. (5) Idempotent: reruns produce identical results. (6) Invoked from daily-attention.sh; standalone script preserved for manual reruns. |
| AO-005 | Proxy scoring + exit criteria evaluation | DONE | AO-004 | low | `#code` | (1) All five exit metrics computable via `attention-score.sh`. (2) Script runs in <10 seconds. (3) Output includes JSON with raw counts alongside rates + `N_window_closed`. (4) Operational definitions match action plan metric definitions. |

## File Change Map

| Task | Files Created | Files Modified |
|------|--------------|----------------|
| AO-001 | `_openclaw/scripts/attention-lib.sh`, `_openclaw/data/attention-schema.sql` | — |
| AO-002 | — | `_openclaw/scripts/daily-attention.sh` (prompt + post-processing) |
| AO-003 | — | `_openclaw/scripts/daily-attention.sh` (pre-processing), `_openclaw/scripts/attention-lib.sh` (dedup functions) |
| AO-004 | `_openclaw/scripts/attention-correlate.sh` | `_openclaw/scripts/daily-attention.sh` (pre-processing invocation) |
| AO-005 | `_openclaw/scripts/attention-score.sh` | — |

## Notes

- **AO-001 + AO-002 are parallel.** Start both in the same session if context permits, or split across two sessions. AO-001 is smaller (~1 session); AO-002 requires prompt iteration (~1-2 sessions with dry-run testing).
- **Integration step after M1:** Wire AO-001 logging into AO-002 post-processing. AO-003 cannot begin meaningful testing until this is complete (dedup queries need populated item history).
- **AO-002 is the critical path.** Its sidecar JSON format defines the structured data that AO-003, AO-004, and AO-005 all consume. Get the extraction pattern right here and everything downstream is mechanical.
- **AO-003 modifies daily-attention.sh** (same file as AO-002). Sequencing enforced — AO-003 after AO-002 to avoid merge conflicts in the same script.
- **AO-004 has no API cost.** Pure bash + git + SQLite. Invoked from daily-attention.sh as pre-processing; standalone script for manual reruns and backfills.
- **Integration test after AO-003:** Run `daily-attention.sh --dry-run` to verify the combined prompt (original + action_class + domain + dedup context) fits the input token budget. If >MAX_INPUT_ESTIMATE, reduce dedup lookback window.
