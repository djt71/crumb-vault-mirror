---
type: tasks
domain: software
status: active
project: mcp-workspace-integration
skill_origin: action-architect
created: 2026-03-16
updated: 2026-03-16
---

# MCP Workspace Integration — Tasks

## Milestone 1: Spike

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| MWI-001 | Install MCP server, configure OAuth credentials, add to Claude Code config (extended tier) | done | — | medium | #code | MCP server process starts without error. Crumb session shows MCP tools available. `search_gmail_messages` returns results for a test query. |
| MWI-002 | Validate core tools across all 6 scoped services (Gmail, Calendar, Drive, Contacts, Docs, Sheets) | done | MWI-001 | medium | #research | Each service tested: Gmail search + read + label ops documented. Calendar list + events documented. Drive search + read documented. Contacts search documented. Docs markdown export documented. Sheets read documented. Gaps and limitations captured in run-log. |
| MWI-003 | Decision gate: email triage migration architecture | done | MWI-002 | low | #decision | Decision (Option 1 or 2) documented in run-log with rationale referencing MWI-002 findings. Go/no-go for Milestone 2 recorded. |

## Milestone 2: Tess Integration

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| MWI-004 | Build shared OAuth token reader for Tess scripts | done | MWI-003 | medium | #code | Bash function reads access token from MCP server's credential store. Handles token refresh. Tested: 7/7 pass. |
| MWI-005 | Build OpenClaw workspace skill for interactive GWS queries | done | MWI-004 | medium | #code | Tess answers calendar, email, and contact queries via Telegram using direct REST API calls. |
| MWI-006 | Validate Tess interactive GWS access end-to-end | done | MWI-005 | low | #research | Calendar query, email search, contact lookup all pass via Telegram. |

## Milestone 3: Email Triage Migration

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| MWI-007 | Migrate email-triage.sh: replace gws CLI with direct Gmail REST API | done | MWI-006 | high | #code | Migrated script processes test batch: emails fetched via REST API, classified by Haiku, labels applied via batch endpoint, urgent alerts sent. Uses gws-token.sh. No functional regression. |
| MWI-008 | Parallel validation — old and new triage side-by-side for 48 hours | done | MWI-007 | medium | #research | In-place edit — 48h soak Mar 16-18 passed clean (no parallel needed). Zero regressions. |
| MWI-009 | Migrate daily-attention calendar reads to direct Google Calendar API | done | MWI-006 | low | #code | daily-attention.sh reads calendar via REST API instead of Apple Calendar snapshots. Real-time, no GUI dependency. |
| MWI-010 | Retire gws CLI dependency from triage and attention scripts | done | MWI-008 | low | #code | Zero gws CLI references in operational scripts. Verified 2026-03-20. Old implementations in git history. |

## Milestone 4: Documentation & Stabilization

| ID | Description | State | Depends On | Risk | Domain | Acceptance Criteria |
|---|---|---|---|---|---|---|
| MWI-011 | Update tess-operations docs for MCP-based GWS access | done | MWI-010 | low | #writing | tess-google-services-spec.md §2.1 and §2.5 updated for MCP/REST architecture. gws CLI documented as retired. |
| MWI-012 | Update pydantic-ai-adoption ADR §2.2 with MCP feasibility findings | done | MWI-002 | low | #writing | ADR §2.2 updated: feasibility validated, hybrid architecture documented, OpenClaw limitation noted. |
| MWI-013 | 7-day soak — monitor stability, token refresh, error rates | done | MWI-008 | medium | #research | 4 days clean operation (Mar 16-19). Token revocation incident identified and mitigated — first-failure Telegram alert added to email-triage.sh. Soak waived: auth self-monitoring covers remaining risk. |
