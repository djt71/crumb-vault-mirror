---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Tess Operations

Skills Tess (OpenClaw agent) uses to interact with the Crumb vault over Telegram — one for structured protocol operations requiring confirmation, one for lightweight fire-and-forget capture.

## Skills

### crumb-bridge
**Invoke:** Tess uses automatically on phrases like "ask crumb", "tell crumb", "@crumb", or any vault query/gate approval
**Inputs:** Natural language mapped to one of 9 allowlisted operations (query-status, list-projects, query-vault, approve-gate, reject-gate, start-task, invoke-skill, quick-fix, escalation-response/cancel)
**Outputs:** Writes a validated request JSON to `_openclaw/inbox/`; relays Crumb's response back via Telegram
**What happens:**
- Validates and hashes the payload via bridge-cli.js; sends confirmation echo for write/dispatch ops
- For Phase 1 ops (queries, gate approvals): polls for response within 30s and relays immediately
- For Phase 2 ops (start-task, invoke-skill, quick-fix): acknowledges dispatch, polls for status updates and escalation questions, relays final result when complete

### quick-capture
**Invoke:** Tess uses automatically on phrases like "save this", "capture this", "read later", "look into this", "check out", "send to crumb"
**Inputs:** URL(s) and/or freeform instructions; optional domain and tags inferred from context
**Outputs:** Writes a `capture-YYYYMMDD-HHMMSS.md` file to `_openclaw/inbox/` with processing hint frontmatter
**What happens:**
- Extracts URL and intent from user message; infers processing hint (research/review/file/read-later)
- Writes capture file via bridge-cli.js `write-capture` subcommand — no confirmation step
- Confirms filename and hint to user; Crumb picks it up at next session startup

## How They Differ

**crumb-bridge** = heavyweight protocol with hash-bound confirmation — used when Crumb needs to execute, approve, or respond. Has a full request/response cycle and supports long-running dispatches.

**quick-capture** = lightweight fire-and-forget — used when Tess is saving something for Crumb to handle later. No confirmation, no response polling, non-destructive.
