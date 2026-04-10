---
type: action-plan
domain: software
status: active
project: mcp-workspace-integration
skill_origin: action-architect
created: 2026-03-16
updated: 2026-03-16
---

# MCP Workspace Integration — Action Plan

## Milestone 1: Spike — Validate MCP Server (Crumb Only)

**Goal:** Prove the community MCP server works in our environment with Danny's Google account. Resolve unknowns U1–U4 from the spec. Gate: proceed only if core functionality validates.

**Success criteria:** Crumb can search Gmail, read messages, manage labels, read calendar events, search Drive, and look up contacts — all through MCP tools in a Claude Code session.

### Phase 1a: Install and Configure

- Install community MCP server (`pip install workspace-mcp` or `uvx`)
- Create Google Cloud OAuth Desktop credentials
- Enable required APIs (Gmail, Calendar, Drive, People, Docs, Sheets)
- Configure environment variables (OAuth client ID/secret, user email)
- Add MCP server to `.claude/settings.json` with extended tier (`--tools gmail drive calendar contacts docs sheets`)
- Test: start a Crumb session and verify MCP tools appear

### Phase 1b: Validate Core Tools

- Test each service systematically in a Crumb session:
  - Gmail: `search_gmail_messages`, `get_gmail_message_content`, label operations (U1 — critical unknown)
  - Calendar: `list_calendars`, `get_events`, `manage_event`
  - Drive: `search_drive_files`, `get_drive_file_content`, `list_drive_items`
  - Contacts: `search_contacts`, `get_contact`, `list_contacts`
  - Docs: `get_doc_as_markdown`, `search_docs`
  - Sheets: `read_sheet_values`, `list_spreadsheets`
- Document: which tools work, which don't, any gaps, latency observations
- Special attention to Gmail label operations — if not supported, email triage migration path changes

### Phase 1c: Decision Gate

- Review spike findings
- Decide email triage migration architecture: Option 1 (bash+MCP-HTTP) vs Option 2 (agent-native)
- Document decision with rationale in run-log
- Go/no-go for Milestone 2

## Milestone 2: Tess Integration

**Goal:** Connect Tess (OpenClaw) to the same MCP server. Validate both agents can coexist on shared infrastructure.

**Success criteria:** Tess can access Gmail and Calendar via MCP tools. Both Crumb and Tess can query GWS simultaneously without auth conflicts.

### Phase 2a: OpenClaw MCP Configuration

- Configure MCP server in `openclaw.json` for Tess (core tier: Gmail, Calendar, Drive, Contacts)
- Determine transport: stdio (child process) vs HTTP (shared server). Resolve U2.
- If separate instances needed: document operational config for both
- Test: interactive Telegram query that exercises Gmail and Calendar via MCP

### Phase 2b: Concurrent Access Validation

- Run Crumb session and Tess triage simultaneously
- Verify: no auth token conflicts, no rate limit issues, both get correct results
- If concurrent access fails: test separate server instances with shared OAuth credentials
- Document transport architecture decision (U5 resolved)

## Milestone 3: Email Triage Migration

**Goal:** Replace gws CLI calls in email-triage.sh and daily-attention.sh with MCP-based access. Retire bespoke GWS integration code.

**Success criteria:** Email triage and daily attention run on MCP with equivalent functionality and cost. gws CLI dependency removed from operational scripts.

### Phase 3a: Migrate Email Triage

- Implement per decision gate outcome (Option 1 or Option 2)
- Option 1 path: replace `gws gmail users messages list/get/modify` calls with `curl` to MCP HTTP endpoint. Keep bash orchestration, Haiku classification, Telegram alerts intact.
- Option 2 path: redesign as OpenClaw agent-native workflow using MCP tools directly.
- Test with `--dry-run` first, then live on a small batch

### Phase 3b: Parallel Validation

- Run old (gws CLI) and new (MCP) triage in parallel for 48 hours
- Compare: classification parity, label accuracy, cost delta, latency
- If parity achieved: cut over to MCP-based script
- If discrepancies: debug and iterate before cutover

### Phase 3c: Migrate Supporting Scripts

- Migrate daily-attention.sh calendar reads from bespoke to MCP
- Remove gws CLI calls from all operational scripts
- Preserve old scripts in git history (no deletion, just replacement)

## Milestone 4: Documentation & Stabilization

**Goal:** Confirm operational stability, update docs, close out project.

**Success criteria:** 7-day soak with zero auth failures and no missed triage runs. All docs updated. ADR §2.2 resolved.

### Phase 4a: Documentation

- Update tess-operations docs to reflect MCP-based GWS access
- Update pydantic-ai-adoption ADR §2.2 with feasibility findings
- Update LaunchAgent configs if transport or startup changed

### Phase 4b: Soak

- 7-day monitoring period: token refresh, error rates, triage run success
- Monitor via existing healthchecks.io + Mission Control
- If any auth failures: diagnose and fix before declaring done

## Critical Path

```
MWI-001 → MWI-002 → MWI-003 (spike — sequential, ~1-2 sessions)
    ↓ (gate: proceed if spike validates)
MWI-004 → MWI-005 → MWI-006 (Tess — sequential, ~1 session)
    ↓ (transport decision informs migration)
MWI-007 → MWI-008 → MWI-010 (migration — sequential, ~2 sessions)
MWI-009 ─────────────────────┘ (parallel with MWI-007)
MWI-010 → MWI-011 (docs after retire)
MWI-008 → MWI-013 (soak after validation)
MWI-012 anytime after MWI-002
```

**Estimated total:** 5-7 sessions across 2-3 weeks, including 48-hour parallel validation and 7-day soak.
