---
type: specification-summary
domain: software
status: active
project: mcp-workspace-integration
skill_origin: systems-analyst
created: 2026-03-16
updated: 2026-03-16
source_updated: 2026-03-16
---

# MCP Workspace Integration — Specification Summary

## Problem

Crumb and Tess access Google Workspace through bespoke, divergent integrations (gws CLI, direct API calls, manual OAuth). This creates maintenance drag and capability asymmetry — Crumb has no direct GWS access; Tess has partial access through scripts.

## Solution

Unified Google Workspace access for both agents via a community MCP server (taylorwilsdon/google_workspace_mcp). One server, one OAuth credential, both agents connected. Crumb gets extended tier (Gmail, Calendar, Drive, Contacts, Docs, Sheets). Tess gets core tier (Gmail, Calendar, Drive, Contacts).

## Key Decisions

- **Spike-first:** Validate MCP server on Crumb before committing to full migration
- **Decision gate (MWI-003):** Email triage migration — bash+MCP-HTTP (Option 1, leaning) vs. agent-native MCP (Option 2). Decided after spike.
- **Migration sequencing:** Crumb first (additive), Tess second (replacement), retire gws CLI last

## Scope

- 13 tasks across 4 milestones: Spike → Tess Integration → Email Triage Migration → Stabilization
- Replaces: gws CLI, manual OAuth rotation, direct API calls in email-triage.sh and daily-attention.sh
- Does not replace: Telegram delivery (stays on OpenClaw), Apple ecosystem integrations
- 7-day soak gate before declaring complete

## Risks

- Gmail label operations may not be supported by MCP tools (validates in spike)
- OAuth handling for personal Google accounts (validates in spike)
- Community server maintenance continuity (mitigated by version pinning + de-adoption path)

## Related

- pydantic-ai-adoption ADR §2.2 (this project resolves the MCP feasibility question)
- tess-operations (email triage migration downstream)
- tess-model-architecture (Tess agent config changes)
