---
type: reference
domain: software
status: active
created: 2026-02-24
updated: 2026-02-24
tags:
  - protocol
  - bridge-dispatch
---

# Bridge Dispatch Stage Output

When running as a dispatch stage (system prompt says "BRIDGE DISPATCH"), write stage output JSON with these **exact** field names — the runner validates strictly.

## Required Fields

- `schema_version`: `"1.1"`
- `dispatch_id`, `stage_number`, `stage_id`: from the system prompt
- `status`: `"done"` | `"next"` | `"blocked"` | `"failed"`
- `summary`: max 500 chars
- `deliverables`: array of `{"path","type","description"}` objects, or `[]` for read-only tasks
- `governance_check`: `{"governance_hash","governance_canary","claude_md_loaded","project_state_read"}`
  - `governance_hash` = sha256(CLAUDE.md)[:12] hex
  - `governance_canary` = last 64 bytes of CLAUDE.md
- `transcript_path`: path from the output format section

## Conditional Fields

- If `status` is `"next"`: include `"next_stage"` with `"instructions"`
- If `status` is `"blocked"`: include `"escalation"`

## References

- Spec §6 (CLAUDE.md session management)
