---
type: enhancement
domain: software
status: resolved
created: 2026-02-22
updated: 2026-02-22
source: claude-ai-session
project: crumb-tess-bridge
relates: CTB-030
tags:
  - bridge-watcher
  - cleanup
  - processed-ids
resolution_notes: |
  Already implemented. compact_processed_ids() in bridge-watcher.py:267
  provides 30-day UUIDv7-based rotation, called on watcher startup.
  5 unit tests in test_watcher.py. No code changes needed.
---

# Enhancement: .processed-ids File Rotation (30-Day Retention)

## Problem

`_openclaw/.processed-ids` is append-only with no rotation or cleanup.
Every processed request appends an ID. The file grows linearly with no
ceiling. At current usage (~13 requests, 888 bytes) it's not urgent, but
there's no mechanism to prevent unbounded growth.

CTB-030 addresses the read performance side (in-memory set for O(1) lookup)
but does not address file growth.

## Recommendation

Add 30-day retention to `.processed-ids`, consistent with the existing
cleanup patterns:

- `cleanup_terminal_states()` — 30-day retention for dispatch state files
- `cleanup_stage_outputs()` — 30-day retention for stage output and status files

### Implementation

On watcher startup (or on each cleanup cycle):

1. Read `.processed-ids` into memory
2. For each ID, check whether the corresponding request file exists in
   `inbox/.processed/` — if the file has been deleted (past 30-day retention
   or manual cleanup), the ID is stale
3. Write back only the non-stale IDs
4. Load the pruned set into memory for O(1) lookup (combines with CTB-030)

Alternative (simpler, no file cross-reference): each line in `.processed-ids`
gets a timestamp prefix. On rotation, drop lines older than 30 days. This
avoids scanning `.processed/` but adds a format change to the file.

### Scope

This can fold into CTB-030 naturally — the task already touches `.processed-ids`
loading and lookup. Adding rotation to the same task keeps the changes
co-located.

## Priority

Low. The file is 888 bytes after several days of usage. At current volume
it would take years to become a real problem. But unbounded growth with no
cleanup mechanism is a design smell worth fixing while CTB-030 is open.
